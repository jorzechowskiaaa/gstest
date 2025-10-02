/**
 * @File Name          : FSL_UpdateArrivalWindowActionTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 11-09-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/6/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_UpdateArrivalWindowActionTest {
    
    Static User user;
    static testmethod void UpdateArrivalWindowActionTest(){
        List<String> serviceAppointmentsIds = new List<String>();
        List<Id>woids = new list<id>();
        set<String> aptnumber = new set<String>();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        list<ServiceAppointment > salist = [select id, Work_Order__r.WorkType.FSL__Due_Date_Offset__c from ServiceAppointment where subject ='Breakdown'];
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
       for(ServiceAppointment a : [Select Id,AppointmentNumber from ServiceAppointment where RecordType.Name ='Breakdown']){
            serviceAppointmentsIds.add(a.id);
       }
        
       aptnumber.add('AppointmentNumber'); 
       FSL_UpdateArrivalWindowAction windowAction = new FSL_UpdateArrivalWindowAction();
       Test.starttest();
        windowAction.action(serviceAppointmentsIds, System.now(), System.now(),null);
       Test.stoptest(); 
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }   
    
}