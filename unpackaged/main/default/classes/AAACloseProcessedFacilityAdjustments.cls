public class AAACloseProcessedFacilityAdjustments implements Database.Batchable<sObject>, Schedulable {
    public String query;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        query = 
            'SELECT '+
                'Id,'+
                'Facility_Adjustment__c,'+
                'Facility_Adjustment__r.ACG_Status__c,'+
                'Facility_Adjustment__r.ACG_End_Date__c'+
            ' FROM Invoice__c'+
            ' WHERE Statement_Status__c = \'Reconciled\''+
            ' AND Status__c = \'Submitted for Payment\''+
            ' AND Facility_Adjustment__r.ACG_Status__c NOT IN (\'Closed\', \'Deferred\', \'Cancelled\')'+
            ' AND Facility_Adjustment__r.ACG_Adjustments_Remaining__c = 0';
        
        return Database.getQueryLocator(query);         
    }
    
    public void execute(Database.BatchableContext BC, List<Invoice__c> scope) {
        Set<String> faIdSet = new Set<String>();
        List<ACG_Facility_Adjustment__c> faUpdateList = new List<ACG_Facility_Adjustment__c>();

        for (Invoice__c invc : scope) {
            String faId = invc.Facility_Adjustment__c;
            
            if (!faIdSet.contains(faId)) {
                ACG_Facility_Adjustment__c fa = invc.Facility_Adjustment__r;
                fa.ACG_Status__c = 'Closed';
                fa.ACG_End_Date__c = Date.Today();

                faUpdateList.add(fa);
                faIdSet.add(faId);
            }
        }
        
        if (faUpdateList != null && faUpdateList.size() > 0) {
            update faUpdateList;
        }
    }

    public void finish(Database.BatchableContext BC){
        // Finish Logic Here
    }

    public void execute(SchedulableContext ctx){
        AAACloseProcessedFacilityAdjustments batch = new AAACloseProcessedFacilityAdjustments();
        Database.executebatch(batch, 1000);
    }
}