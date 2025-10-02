@isTest
public class FSL_D3SyncLoggerTest {
  
    static testmethod void resetSyncIssueLoggerTest(){
             ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
           FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1]; 
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
          
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
   
            list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                          (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                                 Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                                 FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                                  SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                           from ServiceAppointments
                                           order by recordtype.name asc) 
                                          from Workorder];  
            
            workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
            workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
            workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
            workOrders[0].ServiceAppointments[0].PTA__c = System.now();
            update workOrders[0].ServiceAppointments[0]; 
            
            System.Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            //workOrder = [Select Id From WorkOrder Where Call_ID__c = '45637'];
            FSL_D3SyncLogger.resetSyncIssueLogger(new Set<Id>{workOrders[0].Id});
        System.Test.stopTest();               

    }
        
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupWithStaticData();
    }
    
}