/*
*********************************************************************************************************
Class         :  FSL_DeletepriorResourceAbsenceList_Batch.cls
Objective    :  This batch is to delete Application Logs based on the time period given by Running user 
*********************************************************************************************************

//Script for Running Batch Manually 

/*FSL_DeleteApplicationLogs  delApplogs= new FSL_DeleteApplicationLogs('FSL_Application_Log__c',30);
      Database.executeBatch(delApplogs);*/

public class FSL_DeleteApplicationLogs /*implements Database.Batchable<sObject>,Schedulable*/ {
    // public final Integer NoOfDaysCreatedAgo;
    // public final String Operation;
    // public final string APIName;
    
    // public FSL_DeleteApplicationLogs (Integer noOfDaysCreatedAgo,String Operation, string APIName) {
        
    //     this.NoOfDaysCreatedAgo= NoOfDaysCreatedAgo;
    //     this.Operation = Operation;
    //     this.APIName = APIName;
    // }
    
    // public Database.QueryLocator start(Database.BatchableContext bc){
    //     String queryString = 'SELECT ID, Operation__c' + ' FROM FSL_Application_Log__c ' +
    //         ' WHERE Operation__c=\'' +Operation+ '\' AND API_Name__c=\'' +APIName+ '\' AND createdDate < LAST_N_DAYS:'+NoOfDaysCreatedAgo;

    //     system.debug('---------------'+queryString);
    //     return Database.getQueryLocator(queryString);
    // }        
    
    // public void execute(Database.BatchableContext bc, List<sObject> scope){       
    //     List<FSL_Application_Log__c> aplist= (List<FSL_Application_Log__c>)scope;
    //     System.debug('======>'+scope);
    //     delete aplist;
    // }
    
    // public void finish(Database.BatchableContext bc){
    //   AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email    from AsyncApexJob where Id =:BC.getJobId()];
    //     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //     String[] toAddresses = new String[] {a.CreatedBy.Email};
    //     mail.setToAddresses(toAddresses);
    //     mail.setSubject('Delete Application Logs ' + a.Status);
    //     mail.setPlainTextBody('records processed ' + a.TotalJobItems +   ' with '+ a.NumberOfErrors + ' failures.');
    //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    // }
        
    // public void execute(SchedulableContext sc) {
    //     Database.executeBatch(new FSL_DeleteApplicationLogs(10,'Update',''));
    // }
}