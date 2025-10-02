@isTest
public with sharing class AutoscheduleRetryHandlerTest {
    @isTest
    private static void execute_success() {
        AutoscheduleRetryHandler handler = new AutoscheduleRetryHandler();
        Test.startTest();
        handler.execute(null);
        Test.stopTest();
    }
    
}