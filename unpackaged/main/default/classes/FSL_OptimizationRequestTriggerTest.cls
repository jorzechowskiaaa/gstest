@isTest
public inherited sharing class FSL_OptimizationRequestTriggerTest {
    
    @isTest
    public static void testOnAfterDelete_RelatedRecordsDeleted() {

        FSL__Optimization_Data__c data1 = new FSL__Optimization_Data__c();
        FSL__Optimization_Data__c data2 = new FSL__Optimization_Data__c();
        List<FSL__Optimization_Data__c> datas = new List<FSL__Optimization_Data__c>{ data1, data2 };
        insert datas;

        Id dataExpectedToBeDeleted = data1.Id;
        Id dataNotExpectedToBeDeleted = data2.Id;

        FSL__Optimization_Request__c req = new FSL__Optimization_Request__c( FSL__Optimization_Data__c = dataExpectedToBeDeleted );
        insert req;

        datas = [SELECT Id FROM FSL__Optimization_Data__c WHERE Id = :dataExpectedToBeDeleted];
        System.assertEquals( 1, datas.size() );

        datas = [SELECT Id FROM FSL__Optimization_Data__c WHERE Id = :dataNotExpectedToBeDeleted];
        System.assertEquals( 1, datas.size() );

        Test.startTest();
        delete req;
        Test.stopTest();

        datas = [SELECT Id FROM FSL__Optimization_Data__c WHERE Id = :dataExpectedToBeDeleted];
        System.assertEquals( 0, datas.size() );

        datas = [SELECT Id FROM FSL__Optimization_Data__c WHERE Id = :dataNotExpectedToBeDeleted];
        System.assertEquals( 1, datas.size() );
    }
}