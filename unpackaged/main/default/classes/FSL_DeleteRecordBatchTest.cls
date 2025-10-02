@isTest 
public with sharing class  FSL_DeleteRecordBatchTest {
    
    static testmethod void testMethodOne() {
        
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        
        apLog.CreatedDate = system.now().addDays(-95);
        apLog.DateTime__c = System.now();
        apLog.Operation__c = 'CaseCreation';
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.API_Name__c = 'Create Workorder API';
        
        insert apLog;
        
        
        Test.startTest();
        FSL_DeleteRecordBatchScheduler s8 = new FSL_DeleteRecordBatchScheduler();
        string sch = '0 0 * * 1-12 ? *';
        system.schedule('Process Trans 1', sch, s8);
        Test.stopTest();      
        
    }
}