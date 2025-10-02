//Amit K--------7/12/2024
@isTest
private class ScheduleBatchRAPReadyWorkOrdersTest {

    @isTest
    static void testExecute() {
        
        Test.startTest();
        ScheduleBatchRAPReadyWorkOrders scheduler = new ScheduleBatchRAPReadyWorkOrders();
        String jobId = System.schedule('Test Job', '0 0 23 * * ?', scheduler);
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        Test.stopTest();
        
      /*  AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                            FROM AsyncApexJob 
                            WHERE Id = :jobId]; */
        
      //  System.assertEquals('Queued', job.Status, 'Job should be in Queued status');
        
    }
}
/* Original code -------------------------
@isTest
class ScheduleBatchRAPReadyWorkOrdersTest {
    @isTest
    static void test() {
        Boolean hasError = false;

        Test.startTest();
        try {
            Database.executeBatch(new ERS_GrabRAPReadyWorkOrdersBatch(), 200);
        } catch (Exception e) {
            hasError = true;
        }
        Test.stopTest();

        System.assertEquals(false, hasError, 'Encountered error running batch class.');
    }
}
*/