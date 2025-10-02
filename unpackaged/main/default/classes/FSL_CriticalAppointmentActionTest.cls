/**
 * @File Name          : FSL_CriticalAppointmentActionTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/6/2020, 2:56:26 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/6/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_CriticalAppointmentActionTest{

    static testmethod void actionTest(){
        delete [select id from Technology_Preference__c];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');         
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        FSL_CriticalAppointmentAction criticaction= new FSL_CriticalAppointmentAction();
        List<Id> serviceAppointmentsIds = new List<id>();
        for(ServiceAppointment a : [Select Id,AppointmentNumber from ServiceAppointment]){
            serviceAppointmentsIds.add(a.id);
        }

        system.debug('OUTPUT:'+criticaction.action(serviceAppointmentsIds, System.now(), System.now(), null));
        Test.stopTest();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

}