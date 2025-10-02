public class AAAFacilityAdjustmentInvoicingBatch implements Database.Batchable<sObject> {
    
    public String query;
    public Database.QueryLocator start(Database.BatchableContext BC){
         query = 'SELECT Id,Service_Territory__c,ACG_Adjustment_Category__c, ACG_Adjustment_Type__c,ACG_Payment_Amount__c FROM ACG_Facility_Adjustment__c WHERE ACG_Status__c = \'Active\' AND ACG_Adjustments_Remaining__c > 0';
         
        return Database.getQueryLocator(query);  
    }
        
    public void execute(Database.BatchableContext BC, List<ACG_Facility_Adjustment__c> scope){
        
        //Get RecordType Ids
        Id invoiceRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
        Id invoiceLIRecId = Schema.SObjectType.Invoice_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
        
        //Map<Id,List<ACG_Facility_Adjustment__c>> mapFacilityToFacAdj = new Map<Id,List<ACG_Facility_Adjustment__c>>();
        List<ACG_Facility_Adjustment_Payment__c> lstNewFacAdjPay = new List<ACG_Facility_Adjustment_Payment__c>();
        List<Invoice__c> lstnewInvoice = new List<Invoice__c>();
        Set<Id> setFacilityId = new Set<Id>();
        
        for(ACG_Facility_Adjustment__c facAdj:scope){
            
            //New Facility Adjustment Payment
            ACG_Facility_Adjustment_Payment__c facAdjPay = new ACG_Facility_Adjustment_Payment__c();
            facAdjPay.ACG_Adjustment_ID__c = facAdj.id;
            facAdjPay.ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c;
            lstNewFacAdjPay.add(facAdjPay);
            
            //New Invoice
            Invoice__c inv = new Invoice__c();
            inv.Facility_Adjustment__c = facAdj.id;
            inv.Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c;
            inv.Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c;
            inv.Service_Territory__c = facAdj.Service_Territory__c;
            inv.Status__c = 'Ready for Processing';
            inv.Type__c = 'Facility Adjustments';
            inv.RecordTypeId = invoiceRecId;
            lstnewInvoice.add(inv);            
            
            //Set of Facility Ids in the Facility Adjustment records in scope 
            setFacilityId.add(facAdj.Service_Territory__c);
            
            //Map of Facility to Facility Adjustments
            /*if(mapFacilityToFacAdj.get(facAdj.Service_Territory__c)!=null && mapFacilityToFacAdj.get(facAdj.Service_Territory__c).size()>0){
                List<ACG_Facility_Adjustment__c> updateList = mapFacilityToFacAdj.get(facAdj.Service_Territory__c);
                updateList.add(facAdj);
                mapFacilityToFacAdj.put(facAdj.Service_Territory__c, updateList);
            }else{
                List<ACG_Facility_Adjustment__c> newList = new List<ACG_Facility_Adjustment__c>();
                newList.add(facAdj);
                mapFacilityToFacAdj.put(facAdj.Service_Territory__c, newList);
            }*/
            
            
        }
        
        //Insert Facility Adjustment Payment records
        if(lstNewFacAdjPay!=null && lstNewFacAdjPay.size()>0)
            Database.insert(lstNewFacAdjPay,false);
        
        //Map of Facility Adjustment to Facility Adjustment Payment
        Map<Id, ACG_Facility_Adjustment_Payment__c> mapFacAdjToFacAdjPay = new Map<Id, ACG_Facility_Adjustment_Payment__c>();
        
        for(ACG_Facility_Adjustment_Payment__c facAdjPay:lstNewFacAdjPay){
            mapFacAdjToFacAdjPay.put(facAdjPay.ACG_Adjustment_ID__c, facAdjPay);
        }
       
        //Create a map of Facility to Statement for this payment period
        Map<Id,Statement__c> mapFacilityToStatement = new Map<Id,Statement__c>();
        List<Statement__c> lstStatements = [SELECT Id,Service_Territory__c,Start_Date__c FROM Statement__c WHERE Service_Territory__c IN: setFacilityId AND Start_Date__c =: Date.Today()];
        for(Statement__c st:lstStatements){
            mapFacilityToStatement.put(st.Service_Territory__c, st);
        }
        
        //Assign remaining Statement values on Invoice
        for(Invoice__c inv:lstnewInvoice){
            Statement__c st = mapFacilityToStatement.get(inv.Service_Territory__c);
            inv.Statement__c = st.Id;
            inv.Statement_Date__c = st.Start_Date__c;
        }
        
        //Insert Invoice records
        if(lstnewInvoice!=null && lstnewInvoice.size()>0)
            Database.insert(lstnewInvoice,false);
        
        //Insert Invoice Line Item records
        List<Invoice_Line_Item__c> lstNewInvLI = new List<Invoice_Line_Item__c>();
        for(Invoice__c inv:lstnewInvoice){
            Invoice_Line_Item__c invLI = new Invoice_Line_Item__c();
            invLI.Invoice__c = inv.Id;
            if(mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c)!=null){
                if(mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c).Id!=null)
                    invLI.Facility_Adjustment_Payment__c = mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c).Id;
                if(mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c).ACG_Payment_Amount__c!=null)    
                    invLI.Cost__c = mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c).ACG_Payment_Amount__c;
            }
            invLI.RecordTypeId = invoiceLIRecId;
            lstNewInvLI.add(invLI);
        }
        
        if(lstNewInvLI!=null && lstNewInvLI.size()>0)
            Database.insert(lstNewInvLI,false);
        
    }
    
    public void finish(Database.BatchableContext BC){
        
        // Chain batch job for Closing Facility Adjustments if all Facility Adjustment Payments have been now created here.
        AAACloseProcessedFacilityAdjustments batch = new AAACloseProcessedFacilityAdjustments();
        Database.executebatch(batch, 200);
    }

}