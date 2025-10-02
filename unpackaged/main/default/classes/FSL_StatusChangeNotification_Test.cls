@isTest
private class FSL_StatusChangeNotification_Test {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    static testMethod void testStatusChangeEvent() {
        Test.startTest(); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        list<ServiceAppointment> SAs = [select id from ServiceAppointment];
        Status_Change_Notification__e st1 = new Status_Change_Notification__e(Service_Appointment_Id__c = SAs[0].id, Status__c = 'Dispatched', Address_Changed__c=true);
        
        Database.SaveResult result = EventBus.publish(st1);
        Test.stopTest();
        
    }
    
}