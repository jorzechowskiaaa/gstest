/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 07-18-2022
 * @last modified by  : Clement Shiu
**/
@isTest
Public class FSL_UpdateSRPrimaryTerritoryTest{    

    public static testMethod void FSL_UpdateSRPrimaryTerritory(){
        List<User> userList = [SELECT id, firstName, lastName 
        FROM USER WHERE alias = 'C_Admin'];

        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=userList[0].Id,
                                   PermissionSetId=pset.Id);      

        List<ServiceAppointment> saList = new List<ServiceAppointment>();

        System.runAs(userList[0]){
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
            AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(workOrders[0].ServiceAppointments[0].Id, serviceResource.Id);
            insert assignedResourceBreakdown;
            

            List<ServiceAppointment> pending_saList = new List<ServiceAppointment>();
            ServiceAppointment sa2 = workOrders[0].ServiceAppointments[0];
            sa2.Street = workOrders[0].Street;
            sa2.City = workOrders[0].City;
            sa2.State = workOrders[0].State;
            sa2.Service_Resource__c = serviceResource.id;
            sa2.FSL__InternalSLRGeolocation__Latitude__s = workOrders[0].Latitude;
            sa2.FSL__InternalSLRGeolocation__Longitude__s = workOrders[0].Longitude;
            sa2.FSL__Emergency__c = True;
            sa2.FSL__Scheduling_Policy_Used__c = schedulingPolicy.Id;
            sa2.FSL__Schedule_over_lower_priority_appointment__c = True;
            sa2.Status = 'Scheduled';

            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            sa2.SchedStartTime = System.now();
            sa2.SchedEndTime = System.now().addMinutes(30);
            sa2.actualstarttime = System.now();
            sa2.PTA__c = System.now();
            sa2.subject = 'Breakdown';
            sa2.FSL_IsLight_Service__c =true;
            sa2.Is_Cleared__c = false;
            update sa2;
            pending_saList.add(sa2);  
            workOrders[0].status = 'On Location';   
        }
   } 
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupWithStaticData();
        
    }
}