/**
 * @File Name          : FSL_ToGlympseCalloutTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 12-01-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/28/2020   Rajesh Kemisetti     Initial Version
 * 2.0   12-01-2022   Clement Shiu         Remove Glympse
**/
@isTest
public class FSL_ToGlympseCalloutTest{

    //ERS-230874 Glympse Removal - Part I
    /* ----------------

    static Map<String, String> responseHeaders = new Map<String, String>{'Content-Type' => 'application/json;charset=UTF-8'};
    static String body = '';

      static testMethod void getBearerTokenTest(){
         System.Test.StartTest(); 
         body = '{\"body\": {\"access_token\": \"lGVtg2D43wGwoFLEavZ9Rwt\",\"token_type\": \"Bearer\",\"expires_in\": 15552000},\"meta\": {\"time\": 1548061709658},\"result\": \"ok\"}';  
         System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
         FSL_ToGlympseCallout.getBearerToken();
         System.Test.StopTest();
     }    
    
    static testMethod void getEtaTest(){        
        string wrapper = '{\"id\" : \"123456789098765\", \"callEvents\":[{\"callKey\":\"1234\",\"statusDetail\":{\"eta\":\"2018-09-15T10:05:41Z\"}}]}';

        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            SAList.add(wo.ServiceAppointments[0]); 
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            ARList.add(assignedResource);
        }
        
        update SAList;
        insert ARList;
        body = '{"result":"ok","body":{"tasks":[{"properties":[{"n":"appt_from","v":1589851440000},{"n":"appt_to","v":1589852040000},{"n":"invite_code","v":"0N2A-KEBK"},{"n":"name","v":"DAVID MC NEES"},{"n":"phase","v":"live"}]}]},"meta":{"time":1589881949054}';  
        Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
        
        FSL_ToGlympseCallout.getEta(workOrderList[0].ServiceAppointments[0].Id, wrapper, UserInfo.getUserId()); 
        if(SAList.size() > 1)  {
            FSL_ToGlympseCallout.getEta(workOrderList[1].ServiceAppointments[0].id, wrapper, UserInfo.getUserId());    
        }
        
        Test.StopTest();
    }
   
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }    
     */
}