/*
*********************************************************************************************************
Class         :  FSL_DeletepriorResourceAbsenceList_Batch.cls
Developer     :  Sunil Chandani
Created      :  May , 2018
Objective    :  This batch is to delete ResourceAbsence where FSL__GanttLabel__c ='LKL'
b.descending by Renewal Opportunity Product
*********************************************************************************************************
*/

/********************* Method to execute Batch Manually
Option 1 - With Matched
String querySt='select id,type,FSL__GanttLabel__c from ResourceAbsence where FSL__GanttLabel__c =\'LKL\'';
FSL_DeletepriorResourceAbsenceList_Batch b = new FSL_DeletepriorResourceAbsenceList_Batch(querySt);
Database.executeBatch(b, 100);

Option 2 - As it is

Database.executeBatch(new FSL_DeletepriorResourceAbsenceList_Batch(),100);
*********************/

global class FSL_DeletepriorResourceAbsenceList_Batch implements Database.Batchable<sObject> , Database.Stateful, Schedulable {    
    
    global final String queryString;
    global List<String> errorList;
    global Integer totalProcessed;
    global Integer saveCounter;

    global FSL_DeletepriorResourceAbsenceList_Batch()
    {    
       errorList = new List<String>();   
    }
    
    global FSL_DeletepriorResourceAbsenceList_Batch(String q)
    {
        errorList = new List<String>();
        queryString = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        saveCounter = 0;
        totalProcessed = 0;
        System.debug('##########WELCOME To Start ResourceAbsence ########');
        
        //[Step 1 - Get All the Line Tier Records]
        if(queryString == NULL){
            // addHours(-23) so that it doesn't keep picking all records which were touched in last run
            return Database.getQueryLocator([select id,type,FSL__GanttLabel__c from ResourceAbsence where FSL__GanttLabel__c ='LKL' AND CreatedDate < :DateTime.now().addHours(-48) order by CreatedDate]); 
        
        }else{
            return Database.getQueryLocator(queryString);
           
        }
    }
    
    global void execute(Database.BatchableContext BC, List<ResourceAbsence> scope){
        
        try{
            
                Database.DeleteResult[] SRList = Database.Delete(scope,false);
                totalProcessed += scope.size() ;
                // Iterate through each returned result
                for (Database.DeleteResult sr : SRList) {
                    if (sr.isSuccess()) {
                        saveCounter++;
                    }
                    else{
                        system.debug('Save result failed :'+sr);
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.'+err.getMessage()+' and StatusCode :'+err.getStatusCode());                    
                            errorList.add(err.getStatusCode() + ': ' + err.getMessage());
                        }    
                    }
                }
           
        } 
        catch (DmlException e) {
            // Process exception here
            system.debug(e.getMessage()+' '+ e.getLineNumber());
        } 
        catch(Exception e)
        {
            errorList.add(e.getMessage()  + '\n' + string.valueof(e.getLineNumber()) + '\n' + e.getStackTraceString());
        }
    }  
    
    global void finish(Database.BatchableContext BC){       
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        //String body;
        InsertLogData();
       
        //UtilityClasses.sendEmailFrmBatchJob('E2E Cumulative % Calculation Job', body);
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new FSL_DeletepriorResourceAbsenceList_Batch(),200);
    }
    
    public  void InsertLogData()
    {
         string body =  'Total Records Processed : '+ totalProcessed + '\r\n Successes : ' + saveCounter + '\r\n Errors : ' + errorList.size() ;
        if(!errorList.isEmpty())
        {
            body = body +'\r\n\nBelow are errors occurred:-';
            for(String err : errorList)
            {
                body = body +'\r\n'+err;
            }
        }
        
        FSL_Application_Log__c AppLog =  new FSL_Application_Log__c();
        AppLog.Response_Body__c = body;
        
        insert AppLog;
        
    }
}