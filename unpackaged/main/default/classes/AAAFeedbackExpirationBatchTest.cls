@isTest
public class AAAFeedbackExpirationBatchTest {
	@TestSetup
    static void setup() {
    	List<Feedback__c> fbInsertList = new List<Feedback__c>();
        DateTime createdDate = DateTime.now().addDays(-181);
        for(integer i=0; i<2; i++)
        {
            Feedback__c fbItem = new Feedback__c();
            fbItem.CreatedDate = createdDate;
            fbItem.Charge_Entitlement__c = true;
            if(i==0)
            {
            	fbItem.Status__c = 'Open';
            }
            else
            {
                fbItem.Status__c = 'In Process';
            }
            fbInsertList.add(fbItem);            
        }
        insert fbInsertList;     
    }
    @isTest
    static void AAAFeedbackExpirationTest() {
        Test.startTest();
        Database.executeBatch(new AAAFeedbackExpirationBatch());
        Test.stopTest();

        List<Feedback__c> fbList = [SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate FROM Feedback__c WHERE Status__c = 'Expired'];
        System.assertEquals(2, fbList.size(), 'AAAFeedbackExpirationTest - Failed to update records.');
        System.assertEquals(false, fbList[0].Charge_Entitlement__c, 'AAAFeedbackExpirationTest - Failed to set Charge_Entitlement__c');
    }
    @isTest
    static void AAAFeedbackExpirationSingleModeTest() {
        List<Feedback__c> fbListInput = [SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate FROM Feedback__c limit 1];
        Test.startTest();
        Database.executeBatch(new AAAFeedbackExpirationBatch(fbListInput[0].id));
        Test.stopTest();

        List<Feedback__c> fbList = [SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate FROM Feedback__c WHERE Status__c = 'Expired'];
        System.assertEquals(1, fbList.size(), 'AAAFeedbackExpirationSingleModeTest - Failed to update records.');
        System.assertEquals(false, fbList[0].Charge_Entitlement__c, 'AAAFeedbackExpirationSingleModeTest - Failed to set Charge_Entitlement__c');
    }
    @isTest
    static void AAAFeedbackExpirationDateModeTest() {
        Test.startTest();
        Database.executeBatch(new AAAFeedbackExpirationBatch(date.today().addDays(1)));
        Test.stopTest();

        List<Feedback__c> fbList = [SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate FROM Feedback__c WHERE Status__c = 'Expired'];
        System.assertEquals(2, fbList.size(), 'AAAFeedbackExpirationDateModeTest - Failed to update records.');
        System.assertEquals(false, fbList[0].Charge_Entitlement__c, 'AAAFeedbackExpirationDateModeTest - Failed to set Charge_Entitlement__c');
    } 
    @isTest
    static void AAAFeedbackExpirationScheduleTest() {
        Test.startTest();
        AAAFeedbackExpirationBatch scheduletest = new AAAFeedbackExpirationBatch();
        scheduletest.execute(null);
        Test.stopTest();
        List<Feedback__c> fbList = [SELECT Id,Charge_Entitlement__c,Status__c,CreatedDate FROM Feedback__c WHERE Status__c = 'Expired'];
        System.assertEquals(2, fbList.size(), 'AAAFeedbackExpirationScheduleTest - Failed to update records.');
        System.assertEquals(false, fbList[0].Charge_Entitlement__c, 'AAAFeedbackExpirationScheduleTest - Failed to set Charge_Entitlement__c');
        
    }
}