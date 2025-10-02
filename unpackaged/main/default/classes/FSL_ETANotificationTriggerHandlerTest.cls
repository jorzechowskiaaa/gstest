/**
 * @File Name          : FSL_ETANotificationTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 11-09-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_ETANotificationTriggerHandlerTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    static testMethod void ETATriggerTest() {                 

        ServiceResource serviceResource = [SELECT Id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
                                          FROM ServiceResource 
                                          WHERE ResourceType = 'T' 
                                          LIMIT 1];
        FSL__Scheduling_Policy__c schedulingPolicy = [SELECT Id 
                                                      FROM FSL__Scheduling_Policy__c 
                                                      LIMIT 1];

        Test.setMock( HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator( false ) );
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );
       
        System.Test.startTest();

        List<WorkOrder> workOrders = [SELECT Recordtype.Name, Street, City, State, Latitude, longitude, Status, Resolution_Code__c, 
                                        (SELECT Id, Status, FSL__Pinned__c, ParentRecordid, FSL__InternalSLRGeolocation__Latitude__s, 
                                                Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c, 
                                                FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,ETA__c,
                                                SchedEndTime, ActualStartTime, FSL_IsLight_Service__c, ServiceTerritoryId, AppointmentNumber 
                                        FROM ServiceAppointments
                                        ORDER BY RecordType.Name ASC) 
                                    FROM WorkOrder];
            
        workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
        workOrders[0].ServiceAppointments[0].SchedEndTime = System.now() + 1800;
        workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
        workOrders[0].ServiceAppointments[0].PTA__c = System.now();
        update workOrders[0].ServiceAppointments[0];
        
        AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource( workOrders[0].ServiceAppointments[0].Id, serviceResource.Id );
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
        
        sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get( 'Breakdown' ).getRecordTypeId();
        sa2.SchedStartTime = System.now();
        sa2.SchedEndTime = System.now().addMinutes( 30 );
        sa2.actualstarttime = System.now();
        sa2.PTA__c = System.now();
        sa2.ETA__c = System.now();
        sa2.subject = 'Breakdown';
        sa2.FSL_IsLight_Service__c = true;
        sa2.Is_Cleared__c = false;        
        pending_saList.add( sa2 );
        
        try {
            List<ETA_Notification__e> notificationList = new List<ETA_Notification__e>();
            notificationList.add( FSL_OptimizationHelper.createETAPlatformEvent( null, 0, 'Resource Absence', serviceResource.Id, false, false, true, false ) );
           	notificationList.add( FSL_OptimizationHelper.createETAPlatformEvent( pending_saList[0], 10, 'Address Change', null, true, true, false, true ) );
            FSL_OptimizationHelper.publishPlatformEvents(notificationList);
            //Set<ID> resourceIDs = new set<ID>();
            //resourceIDs.add(serviceResource.id);
            // List<ResourceAbsence> resabslist = FSL_DataFactory.CreateResourceAbsences('LKL');
    
            //Map<Id,id >ResAbsmap = new Map<Id,id>();
            //ResAbsmap.put(resabslist[0].ResourceId,resabslist[0].id);
            
            FSL_ETANotificationTriggerHandler.handlePlatformETANotifications( notificationList );
        }
        catch( Exception e ) {}
        //FSL_ETANotificationTriggerHandler.createSRtoRelatedWoMap(resourceIDs,ResAbsmap);
        System.Test.stopTest();
    }
}