/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-14-2022
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-10-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
Public class FSL_ServiceAppointmentEvaluatorTest{
   
    public static testmethod void ServiceEvaluatorTest(){

     	User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
		PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

      	insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                  PermissionSetId=pset.Id); 

		System.runAs( admin ) {
            List<User> userList = [SELECT id, firstName, lastName 
            FROM USER WHERE alias = 'C_Admin'];
    
            ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
            FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1]; 
    
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    
            
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
            list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                            (SELECT id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                    Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                    FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                    SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                            FROM    ServiceAppointments
                            ORDER BY recordtype.name asc) 
                            FROM Workorder];  
    
            workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
            workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
            workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
            workOrders[0].ServiceAppointments[0].PTA__c = System.now();
            workOrders[0].ServiceAppointments[0].recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            update workOrders[0].ServiceAppointments[0];                      
            Test.startTest();
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
    
            Map<id,ServiceAppointment> mapSA = new Map<id,ServiceAppointment>();
            mapSA.put(sa2.Id,sa2);
            //mapSA.put(breakDownSA.Id,breakDownSA);
    
            FSL_ServiceAppointmentEvaluator.getAppointmentsWithUpdatedValue(mapSA,pending_saList,'FSL__Scheduling_Policy_Used__c');
            //FSL_ServiceAppointmentEvaluator.appointmentsWithNewTerritory(mapSA,pending_saList);
    
            Test.stopTest();
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            sa2.subject = 'Breakdown';
            update sa2;
            try {
              workOrders[0].status='Cleared';
              update workOrders;
            }
            catch(Exception e) {}
            
          }
    
      
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupWithStaticData();
    }    
    
}