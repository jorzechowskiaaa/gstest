public class WorkOrderFeedController {
 @auraEnabled
    public static List<WorkOrder> getWorkOrderDetails(Id recordId){        
         System.debug('caseId'+recordId);
        Id woIds;
       List<Case> c = [Select Id,FSL_Work_Order__c from case where Id =: recordId 
                 limit 1]; 
        for(case cid:c){
            woIds = cid.FSL_Work_Order__c;
        }
        List<WorkOrder> wo = [SELECT Id,RecordTypeId,CaseId FROM WorkOrder WHERE Id =: woIds];
        System.debug('wo'+woIds);
       return wo; 
    }
}