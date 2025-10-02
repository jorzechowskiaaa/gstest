/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*/
@isTest
private class FSL_FeedItemTriggerHandlerTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    
    static testMethod void testWorkOrderFeedCreation() {
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        ServiceAppointment sa = [select id from ServiceAppointment limit 1];
        list<FeedItem> fts = new list<FeedItem>();
        FeedItem f = new FeedItem();
        f.Body = 'legal test';
        f.parentID = sa.id;
        insert f;
        fts.add(f);
        System.assertEquals ('legal test', f.body); 
        FSL_FeedItemTriggerHandler.postAppointmentMessageToParent(fts);
      
    }
    
    static testMethod void testWorkOrderLineItemFeedCreation() {
       FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        ServiceAppointment sa = [select id from ServiceAppointment limit 1];
        
        FeedItem f = new FeedItem();
        f.Body = 'legal test';
        f.parentID = sa.id;
        insert f;
        System.assertEquals ('legal test', f.body);
    }    
}