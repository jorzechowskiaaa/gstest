// batchable class to delete records 
// based on Record Removal Support custom metadata records
// from ACA

global class FSL_DeleteRecordBatch  implements Database.Batchable<sObject> {
    private String strParameter;
    
    public FSL_DeleteRecordBatch(String strParam) {
        //parameter being passed in from the scheduler job to tell the process which record to use from the custom metadata for the batch process
        strParameter = strParam;
    }
    
    global database.querylocator start(Database.BatchableContext BC){
        system.debug(strParameter);
        //grabbing information from the custom metadata type to process 
        Record_Removal_Support__mdt custRec = [Select Id, Duration__c, Duration_Type__c, Object_API_Name__c, Filter_Field_API_Name__c from Record_Removal_Support__mdt 
                                               Where DeveloperName =:strParameter];  
        //define filter criteria
        string whereClause;
        if(custRec.Duration_Type__c == 'Day'){
            whereClause = 'Last_N_DAYS:' + Integer.valueOf(custRec.Duration__c);
        }else if(custRec.Duration_Type__c == 'Month'){
            whereClause = 'LAST_N_MONTHS:' + Integer.valueOf(custRec.Duration__c);
        }else{
            whereClause = 'Last_N_YEARS:' + Integer.valueOf(custRec.Duration__c);
        }
        
        String query = 'select id from ' + custRec.Object_API_Name__c + ' WHERE ' + custRec.Filter_Field_API_Name__c + ' < ' + whereClause  ;
        return Database.getQueryLocator(query);  
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        //grabbing Ids to delete
        Set<Id> resultIds = (new Map<Id,SObject>(scope)).keySet();        
        List<Id> toDeleteIds = new List<Id>();
        //putting the ids into a list to delete
        for(string sIds : resultIds){
            toDeleteIds.add(sIds);
        }
        //deleting the ids from Salesforce
        Database.DeleteResult[] deleteResults = Database.delete(toDeleteIds, true);
        
        
    }
    global void finish(Database.BatchableContext BC){
        
    }    

}