@isTest
public class INTRSPQueuableTest {
    @isTest
    private static void testQueuable(){
        Test.startTest();
        System.enqueueJob(new INTRSPQueuable('',''));
        Test.stopTest();
    }
}