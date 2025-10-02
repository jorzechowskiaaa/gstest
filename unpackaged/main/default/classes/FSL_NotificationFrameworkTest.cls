/**
 * @File Name          : FSL_NotificationFrameworkTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 6/4/2020, 9:17:07 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/4/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
Public class FSL_NotificationFrameworkTest{
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    static testmethod void dispatcherFollowLogicTest(){ 
        Test.startTest();
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent = new Mobile_Notification_Event__e ();
        mobileEvent.Address_Changed__c = true;
        mobileEvent.Rescheduled__c= true;
        mobileEvent.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        evtList.add(mobileEvent);
        //insert evtList;

        Test.stopTest();
        
    }
    static testmethod void dispatcherFollowLogicTest1(){
        
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent = new Mobile_Notification_Event__e ();
        mobileEvent.Current_Status__c = 'En Route';
        mobileEvent.Rescheduled__c= true;
        mobileEvent.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        evtList.add(mobileEvent);
        Test.startTest();
        EventBus.publish(evtList);
        Test.stopTest();
    }
    
    static testmethod void dispatcherFollowLogicTest2(){
        
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent1 = new Mobile_Notification_Event__e ();
        mobileEvent1.Address_Changed__c = true;
        mobileEvent1.Unscheduled__c= true;
        mobileEvent1.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        evtList.add(mobileEvent1); 
        
        Test.startTest();
        EventBus.publish(evtList);
        Test.stopTest();
    }
    
    static testmethod void unassignmentNotificationLogicTest(){
        Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        FSL_User_Message__c userMessage= new FSL_User_Message__c();
        userMessage.Message_Text__c='Breakdown location changed';
        userMessage.message_id__c='SM-017';
        insert userMessage;
        
        FSL_User_Message__c userMessage2= new FSL_User_Message__c();
        userMessage2.Message_Text__c='Tow address changed';
        userMessage2.message_id__c='SM-018';
        insert userMessage2;
        ServiceAppointment serviceAppointment= [SELECT Id from ServiceAppointment limit 1];
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent = new Mobile_Notification_Event__e ();
        mobileEvent.Address_Changed__c = true;
        mobileEvent.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        mobileEvent.Service_Appointment_Id__c = serviceAppointment.Id;
        evtList.add(mobileEvent);
        
        // Publish test event
        List<Database.SaveResult> sr = EventBus.publish(evtList);        

        FSL_NotificationFramework.statusChangePosts(evtList);
  
        Test.stopTest();
        
        integer  feedcount = [select count() from feeditem where parentid  =:serviceAppointment.Id];
        system.assertEquals(1, feedcount); 
    }
    
    static testmethod void technicianFollowLogicTest(){
        Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        User user = [select id from User where alias = 'T_Fleet'];
        list<ServiceAppointment> appointments = [select id from ServiceAppointment];
        
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent = new Mobile_Notification_Event__e ();
        mobileEvent.Address_Changed__c = true;
        mobileEvent.Service_Appointment_Id__c = appointments[0].Id;
        mobileEvent.Current_SR_User_Id__c = user.Id;
        mobileEvent.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        evtList.add(mobileEvent);

        Test.stopTest();
    }
    
    static testmethod void technicianFollowLogicTest1(){
        Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        User user = [select id from User where alias = 'T_Fleet'];
        list<ServiceAppointment> appointments = [select id from ServiceAppointment];
        
        List<Mobile_Notification_Event__e> evtList = new List<Mobile_Notification_Event__e>();
        Mobile_Notification_Event__e mobileEvent = new Mobile_Notification_Event__e ();
        mobileEvent.Address_Changed__c = true;
        mobileEvent.Service_Appointment_Id__c = appointments[0].Id;
        mobileEvent.Current_SR_User_Id__c = user.Id;
        mobileEvent.Previous_SR_User_Id__c = UserInfo.getUserId(); 
        evtList.add(mobileEvent);
        
        FSL_NotificationFramework.insertEvent(evtList);
        Test.stopTest();
    }
    
}