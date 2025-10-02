/**
* @File Name          : FSL_OptimizationHelperTest.cls 
* @Description        : 
* @Author             : Rajesh Kemisetti
* @Group              : 
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 06-17-2021
* @Modification Log   : 
* Ver       Date            Author                 Modification
* 1.0    2/24/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_OptimizationHelperTest{
    
    static testmethod void TestShiftOpHours(){  
        List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=userList[0].Id,
                                   PermissionSetId=pset.Id);      
        
        
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        
        System.runAs(userList[0]){
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
            System.Test.startTest();
           ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
           FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1]; 

            
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            //Dylan ERS-221256 Add FSL__Related_Service__c field to satify testing.
            list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                          (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                           		  Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                           		  FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                                  SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber,
                                                  FSL__Related_Service__c,ETA__c, isBreakdown__c, FSL_In_Tow_Timestamp__c, Resource_Latitude__c,
                                                  Resource_Longitude__c, FSL_Enroute_Time_Stamp__c
                                           from ServiceAppointments
                                           order by recordtype.name asc) 
                                          from Workorder];  
            
            workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
            workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
            workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
            workOrders[0].ServiceAppointments[0].PTA__c = System.now();
            update workOrders[0].ServiceAppointments[0];                      
            
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
            
            map<Id, INteger> resourcetoDelta = new map<Id, INteger>();
            resourcetoDelta.put(serviceResource.id, 20);
            //FSL_OptimizationHelper.optimizeResourcesWhoBecameAvailable(resourcetoDelta);
            
            Map<ID,ServiceAppointment>  MapServiceAppointment =  new Map<ID,ServiceAppointment>();
            Map<ServiceAppointment,ID>  MapServiceAppointmentVSID =  new Map<ServiceAppointment,ID>();
            Map<ServiceAppointment,integer>  MapServiceAppointmentInteger =  new Map<ServiceAppointment,integer>();
            Map<ID,ServiceAppointment> Oldsamap = new Map<ID,ServiceAppointment>();
            Oldsamap.put(workOrders[0].ServiceAppointments[0].id,workOrders[0].ServiceAppointments[0]);
            Map<ID, ServiceAppointment> Newsamap = new Map<ID,ServiceAppointment>();
            Newsamap.put(sa2.id,sa2);
            MapServiceAppointment.put(sa2.ID,sa2);
            MapServiceAppointmentVSID.put(sa2,sa2.Id);
            MapServiceAppointmentInteger.put(sa2,2);
            //}
            
            AssignedResource assignedResourceBreakdown2 = FSL_DataFactory.createAssignedResource(sa2.Id, serviceResource.Id);
            //insert assignedResourceBreakdown2;        

            FSL_ServiceAppointmentTriggerHandler.updateMilesOnServiceAppointment((new List<ServiceAppointment>{sa2}));
            FSL_ServiceAppointmentTriggerHandler.updateEndTimes(pending_saList);

            
            Formula.recalculateFormulas(pending_saList);
            sa2.status = 'On Location';
            sa2.ActualStartTime = system.now().addHours(3);    
            FSL_ServiceAppointmentTriggerHandler.updateActualStart((new List<ServiceAppointment>{sa2}));
            
            sa2.status = 'On Location';
            sa2.ActualStartTime = null;    
            FSL_ServiceAppointmentTriggerHandler.updateActualStart((new List<ServiceAppointment>{sa2}));
            //System.assertEquals(sa2.ActualStartTime, system.now(),'Unexpected error while setting actualStartTime');    
            
            sa2.status = 'Tow Complete';  
            sa2.ActualStartTime = null;    
            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            Formula.recalculateFormulas(pending_saList);

            FSL_ServiceAppointmentTriggerHandler.updateActualStart((new List<ServiceAppointment>{sa2}));
            System.assertEquals(sa2.ActualStartTime, system.now(),'Unexpected error while setting actualStartTime');
            
            sa2.status = 'In Tow' ; 
            sa2.FSL_In_Tow_Timestamp__c = null;     
            FSL_ServiceAppointmentTriggerHandler.updateActualStart((new List<ServiceAppointment>{sa2})); 
            System.assertEquals(sa2.FSL_In_Tow_Timestamp__c, system.now(),'Unexpected error while setting FSL_In_Tow_Timestamp__c');  
            
            sa2.ActualEndTime = null;
            sa2.FSL_In_Tow_Timestamp__c = null;
            sa2.FSL_IsLight_Service__c = false ;    
            FSL_ServiceAppointmentTriggerHandler.updateActualEnd((new List<ServiceAppointment>{sa2}));
            System.assertEquals(sa2.FSL_In_Tow_Timestamp__c, system.now(),'Unexpected error while setting FSL_In_Tow_Timestamp__c');    
            
            sa2.FSL_In_Tow_Timestamp__c = null;         
            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId(); 
            Formula.recalculateFormulas(pending_saList);

            System.debug('test sa'+(new List<ServiceAppointment>{sa2}));
            FSL_ServiceAppointmentTriggerHandler.updateActualEnd((new List<ServiceAppointment>{sa2}));
            System.debug('test sa'+sa2.ActualEndTime);
            DateTime nowTime = System.now();    
            DateTime currentTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(),0);    
            System.assertEquals(sa2.ActualEndTime, currentTime,'Unexpected error while setting actualEndTime');
            
            sa2.ActualEndTime = null;
            sa2.FSL_IsLight_Service__c = false ;
            sa2.status = 'Cleared' ;  
            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId(); 
            Formula.recalculateFormulas(pending_saList);
            FSL_ServiceAppointmentTriggerHandler.updateActualEnd((new List<ServiceAppointment>{sa2}));
            System.assertEquals(sa2.ActualEndTime, currentTime,'Unexpected error while setting actualEndTime');
            
            sa2.ActualEndTime = null;
            sa2.FSL_IsLight_Service__c = true ;
            sa2.status = 'Cleared' ;  
            sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId(); 
            Formula.recalculateFormulas(pending_saList);
            FSL_ServiceAppointmentTriggerHandler.updateActualEnd((new List<ServiceAppointment>{sa2}));
            System.assertEquals(sa2.ActualEndTime, currentTime,'Unexpected error while setting actualEndTime');

           // FSL_ServiceAppointmentTriggerHandler.updateOriginalScheduledStart((new List<ServiceAppointment>{sa2}));
            FSL_ServiceAppointmentTriggerHandler.updateResourceLocation((new List<ServiceAppointment>{sa2}));
            //FSL_ServiceAppointmentTriggerHandler.dispatcherSubscription(Oldsamap ,Newsamap);
            
            //try{
             //   FSL_ServiceAppointmentTriggerHandler.checkUpdateOnServiceAppointmentAfterClearedStatus((new List<ServiceAppointment>{sa2}),MapServiceAppointment);  
            //}
            //catch(exception e){
              //  system.debug('exception caught: ' + e);
            //}
           // try{
             //   FSL_ServiceAppointmentTriggerHandler.copyOriginalTerritoryToServiceTerritory((new List<ServiceAppointment>{sa2}),MapServiceAppointment);
           // }
           // catch(exception e){
            //    system.debug('exception caught: ' + e);
            //}
            
            
            
            workOrders[0].status = 'Cleared';
            workOrders[0].Resolution_Code__c = 'G414';
            System.debug('----------WO---------'+workOrders[0]);    
            try {
                update workOrders[0];
            }catch(Exception e) {
                system.debug('exception caught: ' + e);
            }
            
            System.Test.stopTest();
        }
    }
    
    Public Static testmethod void optimizeResourceAbsencesTest(){
	System.Test.startTest();        
        List<ResourceAbsence> Ralist = FSL_DataFactory.CreateResourceAbsences('LKL');
        Map<Id,ResourceAbsence> oldRAMap = new Map<Id,ResourceAbsence>();
        FSL_OptimizationHelper.optimizeResourceAbsences(Ralist, null);
        for(ResourceAbsence ra : Ralist){
            ra.end.addminutes(10);
            oldRAMap.put(ra.id, ra);
        }
        FSL_OptimizationHelper.optimizeResourceAbsences(Ralist, oldRAMap); 

        for(ResourceAbsence ra : Ralist){
            ra.end.addminutes(-11);
            oldRAMap.put(ra.id, ra);
        }
        FSL_OptimizationHelper.optimizeResourceAbsences(Ralist, oldRAMap); 
    System.Test.stopTest();    
    }
    
    Public Static testmethod void ChangeOperatingHours(){    

          List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=userList[0].Id,
                                   PermissionSetId=pset.Id);      
        
        System.runAs(userList[0]){
        
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
            list<Account> accounts = [select id, (select id from Contacts) from Account];
            ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Vehicle__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
            WorkType woType = [select id from WorkType limit 1];
            FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1];        
            
            list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                        (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                        Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                        FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                        SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                        from ServiceAppointments
                                        order by recordtype.name asc) 
                                        from Workorder]; 
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  

            workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
            workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
            workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
            workOrders[0].ServiceAppointments[0].PTA__c = System.now();
            update workOrders[0].ServiceAppointments[0];  
            Test.startTest();
            AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(workOrders[0].ServiceAppointments[0].Id, serviceResource.Id);
            insert assignedResourceBreakdown;
            
            try{
                
                OperatingHours OPHR = [select id from OperatingHours where name = 'Technician Shift'];
                
                ServiceTerritoryMember stm = [select OperatingHoursId from ServiceTerritoryMember where ServiceResourceid = :serviceResource.id and territorytype='P' and FSL_Expired_Resource_Territory__c = false];
                stm.OperatingHoursId = OPHR.id;
                update stm;
                system.debug('**serviceResource**:'+serviceResource);
                Map<Id,TimeSlot> tsmap = new Map<id,TimeSlot>(); 
                list<TimeSlot> tslist = new list<TimeSlot>();     
                TimeSlot timeSlot = new TimeSlot();
                timeSlot.StartTime = Time.newInstance(13, 0, 0, 0);
                timeSlot.DayOfWeek = System.Now().format('EEEE');
                timeSlot.EndTime = Time.newInstance(14, 0, 0, 0); 
                timeSlot.OperatingHoursId = OPHR.id;            
                insert timeslot;
                tslist.add(timeslot);
                
                tsmap.put(timeSlot.id,timeslot); 
                FSL_OptimizationHelper.changedOperatingHours(tsmap,tslist,'Insert');
                
                timeslot.EndTime = timeslot.EndTime.addMinutes(50);
                update timeslot;
                tslist.add(timeslot);
                tsmap.put(timeSlot.id,timeslot); 
                FSL_OptimizationHelper.changedOperatingHours(tsmap,tslist,'Update');

                timeslot.EndTime = timeslot.EndTime.addMinutes(-50);
                update timeslot;
                tslist.add(timeslot);
                tsmap.put(timeSlot.id,timeslot); 
                FSL_OptimizationHelper.changedOperatingHours(tsmap,tslist,'Update');

                timeslot.startTime = timeslot.startTime.addMinutes(150);
                update timeslot;
                tslist.add(timeslot);
                tsmap.put(timeSlot.id,timeslot); 
                FSL_OptimizationHelper.changedOperatingHours(tsmap,tslist,'Update');

            Test.stopTest();
                
            }catch(exception ex){
                system.debug('exception occurred');
            }
        }
        
        
        
    }

    public static testMethod void test_optimizeResourcesWhoBecameAvailable(){
        Test.startTest();
            List<User> userList = [SELECT id, firstName, lastName 
            FROM USER WHERE alias = 'C_Admin'];

            System.runAs(userList[0]){

                Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
                
                // create light service call
                FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
                List<WorkOrder> woList = [SELECT id, ServiceTerritoryId FROM WorkOrder];
                WorkOrder lightServiceCall = woList.get(0);

                ServiceResource serviceResource = [select id, Name, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
                    FROM serviceresource 
                    WHERE ResourceType = 'T' limit 1];
                // AND Primary_Service_Territory__c = :lightServiceCall.ServiceTerritoryId

                List<ServiceAppointment> saList = [SELECT id, SchedStartTime, SchedEndTime, Service_Resource__c, Status, ParentRecordID
                    FROM ServiceAppointment
                    WHERE ParentRecordID = :lightServiceCall.id];


                system.debug('sa list returned: ' + saList);

                ServiceAppointment lightServiceSA = saList.get(0);
                lightServiceSA.SchedStartTime = System.now().addMinutes(120);
                lightServiceSA.SchedEndTime = System.now().addMinutes(145);
                //lightServiceSA.Service_Resource__c = serviceResource.id;
                lightServiceSA.Status = 'Scheduled';  

                /* 
                
                update lightServiceSA;            
                
                AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(lightServiceSA.Id, serviceResource.Id);
                insert assignedResourceBreakdown;



                // add resource absence before SA
                DateTime beginTime = System.now().addMinutes(60);
                DateTime endTime = System.now().addMinutes(90);
                ResourceAbsence ra = FSL_DataFactory.createResourceAbsence(serviceResource.Id, beginTime, endTime);
                insert ra;

                // shorten absence by threshold
                FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
                Integer rsoLimit = Integer.valueOf(oSettings.RSO_Threshold__c);
                Integer adjustment = (rsoLimit + 1) * -1;

                ra = [Select ResourceId, Start, End 
                    FROM ResourceAbsence
                    ORDER BY CreatedDate DESC LIMIT 1];

                ra.End = ra.End.addMinutes(adjustment);
                update ra;

                // observe RSO Request

                */
            }

        Test.stopTest();
    }
    
    @IsTest
    public static void  testGetPendingIDOFilter(){
        
        Test.startTest();

        Integer pendingIDOFilter = FSL_OptimizationHelper.getPendingIDOFilter('Pending_IDO_Filter');

        System.assert(pendingIDOFilter > 0);
        
        Test.stopTest();
        
    }

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupWithStaticData();
    }
    
}