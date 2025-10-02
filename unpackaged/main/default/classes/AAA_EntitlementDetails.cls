public with sharing class AAA_EntitlementDetails {
    public class CombinedRecord {
        @AuraEnabled public Id recordId;
        @AuraEnabled public string recType;
        @AuraEnabled public boolean entitlement;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public string name;
    }
    
    public class responseWrapper {
        @AuraEnabled public Boolean hasServiceContracts;
        @AuraEnabled public List<CombinedRecord> records;
    }
    
	@AuraEnabled(cacheable=true)
    public static responseWrapper getWorkOrderbyAccount(Id accountId) {
        responseWrapper response = new  responseWrapper();
        response.hasServiceContracts = false;
        response.records = new List<CombinedRecord>();
        if (accountId == null) return response;
        
        List<ServiceContract> contracts = [select id,status,CreatedDate from ServiceContract where AccountId = :accountId and status = 'Active' order by CreatedDate desc limit 1 ];
        
        if(contracts.isEmpty()){
            response.hasServiceContracts = false;
            return response;
        }
        else {response.hasServiceContracts = true;}
        
        Set<Id> contractIds = new Set<Id>();
        for(ServiceContract sc : contracts){
            contractIds.add(sc.Id);
        }
        
        //work order
        for (WorkOrder wo: [
            select id,CreatedDate,WorkOrderNumber,AAA_Charge_Entitlement__c,status 
            from WorkOrder where ServiceContractId in :contractIds 
            and status = 'Cleared' 
            Order By CreatedDate DESC 
            limit 100
        ]){
        	CombinedRecord rec = new CombinedRecord();
            rec.recordId = wo.id;
            rec.recType = 'Work Order';
            rec.entitlement = wo.AAA_Charge_Entitlement__c;
            rec.createdDate = wo.CreatedDate;
            rec.name = wo.WorkOrderNumber;
            response.records.add(rec);
        }
        
        //Reciprocal
        for (Reciprocal__c rc: [
            select id,CreatedDate,Name,Service_Contract__c,Charge_Entitlements__c 
            from Reciprocal__c where Service_Contract__c in :contractIds 
            Order By CreatedDate DESC 
            limit 100
        ]){
        	CombinedRecord rec = new CombinedRecord();
            rec.recordId = rc.id;
            rec.recType = 'Reciprocal';
            rec.entitlement = rc.Charge_Entitlements__c;
            rec.createdDate = rc.CreatedDate;
            rec.name = rc.Name;
            response.records.add(rec);
        } 
        
        //Reimbursement
        for (ACG_Reimbursement__c re: [
            select id,CreatedDate,Name,ACG_Charge_Entitlement__c,Service_Contract__c
            from ACG_Reimbursement__c where Service_Contract__c in :contractIds 
            Order By CreatedDate DESC 
            limit 100
        ]){
        	CombinedRecord rec = new CombinedRecord();
            rec.recordId = re.id;
            rec.recType = 'Reimbursement';
            rec.entitlement = re.ACG_Charge_Entitlement__c;
            rec.createdDate = re.CreatedDate;
            rec.name = re.Name;
            response.records.add(rec);
        }      
        
        //Feedback
        for (Feedback__c fb: [
            select id,CreatedDate,Service_Contract__c,Charge_Entitlement__c,Name,Source_Club__c
            from Feedback__c where Service_Contract__c in :contractIds 
            and Source_Club__c != '240'
            and Charge_Entitlement__c = true
            Order By CreatedDate DESC 
            limit 100
        ]){
        	CombinedRecord rec = new CombinedRecord();
            rec.recordId = fb.id;
            rec.recType = 'Feedback';
            rec.entitlement = fb.Charge_Entitlement__c;
            rec.createdDate = fb.CreatedDate;
            rec.name = fb.Name;
            response.records.add(rec);
        }

        response.records.sort(new RecordComparator());
        
        return response;      
    }
    
    public class RecordComparator implements System.Comparator<AAA_EntitlementDetails.CombinedRecord> {
        public Integer compare(AAA_EntitlementDetails.CombinedRecord a, AAA_EntitlementDetails.CombinedRecord b){
            if (a.createdDate == null && b.createdDate == null) return 0;
            if (a.createdDate == null) return 1;
            if (b.createdDate == null) return -1;
            if (a.createdDate == b.createdDate) return 0;
            return (a.createdDate > b.createdDate) ? -1 : 1;
        }
    }
}