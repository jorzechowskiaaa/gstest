@isTest
public class FSL_PurgeEntitySubscriptionBatchTest {
    
    @isTest
    public static void testPurgeBatch() {
        delete [select id from Technology_Preference__c];
		
        Test.starttest();  
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.stopTest();
        
        WorkOrder wo = [select id,status, serviceterritoryid,(select id, service_resource__c from serviceappointments) from WorkOrder limit 1];
        //system.assertEquals('Dispatched', wo.status);   
        system.assert(wo.ServiceAppointments[0] != NULL);
        
        FeedItem post = new FeedItem(ParentId = wo.ServiceAppointments[0].Id, body = 'Test message', Visibility = 'AllUsers');
        insert post;
        
        EntitySubscription entitySubscription = new EntitySubscription(SubscriberId = Userinfo.getUserID(),
                                                                       ParentId = wo.ServiceAppointments[0].Id,
                                                                       NetworkId = Network.getNetworkId());
        insert entitySubscription; 
        system.assertequals(entitySubscription.parentId,wo.ServiceAppointments[0].Id);
         
        Test.setCreatedDate(wo.ServiceAppointments[0].Id,System.now().addDays(-100));
        
        FSL_PurgeESBatchSchedule batch = new FSL_PurgeESBatchSchedule();        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, batch); 
         
	 	FSL_PurgeEntitySubscriptionBatch entitySubBatch = new FSL_PurgeEntitySubscriptionBatch(Label.FSL_Service_Appointment_API_Name, Integer.valueOf(Label.FSL_Purge_Subscription_Batch_Size));
      	Database.executeBatch(entitySubBatch);  
        list<entitySubscription> ESs = [select id from entitySubscription];
        entitySubBatch.execute(null, ESs);
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
}