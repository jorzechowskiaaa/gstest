@IsTest
public with sharing class FSL_ClearQueueProcessingBatchTest {

    @IsTest
    static void testxecute_clearQueueProcessingBatch_clearRequestsSent(){
        List<FSLClearQueuedCall__c> calls = new  List<FSLClearQueuedCall__c>();
        calls.add(new FSLClearQueuedCall__c());

        Test.startTest();
        FSL_ClearQueueProcessingBatch batch = new FSL_ClearQueueProcessingBatch( calls );
        Database.executeBatch( batch );
        Test.stopTest();
    }
}