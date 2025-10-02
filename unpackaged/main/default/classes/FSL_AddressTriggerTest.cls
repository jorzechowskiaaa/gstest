/**
 * @File Name          : FSL_AddressTriggerTest.cls
 * @Description        : 
 * @Author             : Sandeep Thumu
 * @Group              : 
 * @Last Modified By   : Sandeep Thumu
 * @Last Modified On   : 4/10/2020, 2:55:21 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/10/2020   Sandeep Thumu     Initial Version
**/
@isTest
public class FSL_AddressTriggerTest {
    public static testMethod void AddressTest(){
        
         List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias='C_Admin'];
     System.runAs(userList[0]){   
         ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
           FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1]; 

            System.Test.startTest();
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
   
            list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                          (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                                 Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                                 FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                                  SchedEndTime, actualstarttime,PostalCode,Country,FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                           from ServiceAppointments
                                           order by recordtype.name asc) 
                                          from Workorder];  
            
            workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
            workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
            workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
            workOrders[0].ServiceAppointments[0].PTA__c = System.now();
            update workOrders[0].ServiceAppointments[0];                      
            
          
            
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
            sa2.FSL__Pinned__c = true;
            
            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            sa2.SchedStartTime = System.now();
            sa2.SchedEndTime = System.now().addMinutes(30);
            sa2.actualstarttime = System.now();
            sa2.PTA__c = System.now();
            sa2.subject = 'Breakdown';
            sa2.FSL_IsLight_Service__c =true;
            sa2.Is_Cleared__c = false;
            //update sa2;
            pending_saList.add(sa2);    
       
        
         List<Schema.Location> location = [select id from Location];
       /* List<Schema.Address> addr = [select id from address];
        addr[0].city = 'Test City';
        addr[0].latitude = 82.7;
        addr[0] .longitude = 102.6;
        addr[0].Service_Appointment__c = pending_saList[0].Id; 
        update addr ;*/
        
        
        Schema.Address address = new Schema.Address();
        address.parentId = location[0].Id;        
        insert address;
        
        address .city = 'Test City';
        address .latitude = 82.7;
        address .longitude = 102.6;
        address .Service_Appointment__c = pending_saList[0].Id; 
        update address ;
        
        FSL_AddressTriggerHandler.SAsWithNewAddress(pending_saList);
       } 
    }
    
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }

}