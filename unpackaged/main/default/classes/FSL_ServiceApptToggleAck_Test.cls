/**
 * @File Name          : FSL_ServiceApptToggleAck_Test.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/6/2020, 3:02:21 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/6/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_ServiceApptToggleAck_Test {
 
    static testmethod void actionTestPositive(){
        delete [select id from Technology_Preference__c];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');   
		Test.startTest();        
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        FSL_ServiceAppointmentToggleAcknowledge serviceApptToggAck = new FSL_ServiceAppointmentToggleAcknowledge();
        List<Id> serviceAppointmentsIds = new List<id>();
        for(ServiceAppointment a : [Select Id from ServiceAppointment]){
            serviceAppointmentsIds.add(a.id);
        } 
        serviceApptToggAck.action(serviceAppointmentsIds, System.now(), System.now(), null);
        Test.stopTest();
    }
    static testmethod void actionTestNegative(){
  
		Test.startTest();        
        FSL_ServiceAppointmentToggleAcknowledge serviceApptToggAck = new FSL_ServiceAppointmentToggleAcknowledge();
        List<Id> serviceAppointmentsIds = new List<id>();
        for(ServiceAppointment a : [Select Id from ServiceAppointment]){
            serviceAppointmentsIds.add(a.id);
        } 
        serviceApptToggAck.action(serviceAppointmentsIds, System.now(), System.now(), null);
        Test.stopTest();
    }    
    
      @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }   

}