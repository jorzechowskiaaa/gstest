@isTest
public class INTGetMemberTimeZoneQueuableTest {
    @isTest
    private static void testQueuable(){
        Test.startTest();
        List<String> cases = new List<String>();
        System.enqueueJob(new INTGetMemberTimeZoneQueuable(cases));
        Test.stopTest();
    }
}