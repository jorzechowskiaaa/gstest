/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-07-2022
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-05-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
 *       01-05-2021   Clement Shiu         ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
 *       04/28/2021   Clement Shiu         ERS-222668: When a WorkOrder in Active Status other than Scheduled moved from one resource to another, it can not be auto Dispatched
 *       05/26/2021   Clement Shiu         ERS-223296: When a Call in 'En Route' or 'On Location' status was dragged to another Service Resource as a Stacked Call, the status was not automatically changed back to Scheduled.
**/
@isTest
public class FSL_DispatchUtilityTest {

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
        
        
    }

    //ERS-220594: Test case to auto Dispatch an assigned call if a Service Resource has already started his workday
    @isTest
    public static /*testmethod*/ void autoDispatchResourceStartedTest() {
      
        // Added for testing
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
          //  endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
           // endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        //
        
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
                
        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 
        WorkOrder woTest = [SELECT Id, Service_Resource__c FROM WorkOrder Limit 1 ]; 
        woTest.Service_Resource__c = serviceResources[2].Id;
        update woTest;

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();        
        Id SAId;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){  
                SAId = sa.Id;      
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.ActualStartTime = System.now();
                sa.PTA__c = System.now();        
                SAList.add(sa); 
                
                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(SAId, serviceResources[2].Id);
                // assignedResource.EstimatedTravelTime = 120.00;
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 3 to be Active, deactivate all other resources    
        serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];            
        list<ServiceResource> srUpdate = new List<ServiceResource>();        
        
        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        srUpdate.add(serviceResources[2]);
        
        update srUpdate;                

        // Verify that it Dispatched     
        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }

        Test.StopTest();    
    }

    //ERS-220594: Test case to hold an assigned call in Scheduled Status Before a Service Resource starts his workday
    @isTest
    public static /*testmethod*/ void autoDispatchResourceStartedTest_False(){                                        
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
                
        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 
        list<ServiceResource> srUpdate = new List<ServiceResource>();         
        // For ServiceResourceId=3, set On Schedule = false
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = false;
        srUpdate.add(serviceResources[2]);        
        update srUpdate;                

        // Assign WorkOrder Service Resource
        WorkOrder woTest = [SELECT Id, Service_Resource__c FROM WorkOrder Limit 1 ]; 
        woTest.Service_Resource__c = serviceResources[2].Id;
        update woTest;        

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();        
        Id SAId;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){  
                SAId = sa.Id;      
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.ActualStartTime = System.now();
                sa.PTA__c = System.now();        
                SAList.add(sa); 
                
                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(SAId, serviceResources[2].Id);
                // assignedResource.EstimatedTravelTime = 120.00;
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      
        
        // Verify that it remains in Scheduled Status     
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Scheduled', workOrderList[0].Status);
        
        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Scheduled', sa.Status);
        }

        Test.StopTest();    
    }

    //ERS-220594: Test case to auto Dispatch next assigned qualified Appointment call if a Service Resource has already started his workday
    @isTest
    public static /*testmethod*/ void autoDispatchApptCallResourceStartedTest(){ 
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
       
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 
        //WorkOrder woTest = [SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c FROM WorkOrder Limit 1 ]; 
        DateTime appointmentTime = System.now().addMinutes(30);
        //woTest.Service_Resource__c = serviceResources[2].Id;
        //woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime);        

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (select id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();        
        Id SAId;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){                
                sa.SchedStartTime = appointmentTime;
                sa.SchedEndTime = System.now().addMinutes(120);                
                sa.PTA__c = System.now().addMinutes(30);
                sa.Member_Scheduled__c = true;               
                SAList.add(sa); 

                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[2].Id);
                // assignedResource.EstimatedTravelTime = 120.00;
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 3 to be Active, deactivate all other resources    
        serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];            
        list<ServiceResource> srUpdate = new List<ServiceResource>();        
        
        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        srUpdate.add(serviceResources[2]);
        
        update srUpdate;                

        // Verify that it Dispatched     
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Dispatched', workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }

        Test.StopTest();                  
    }
    //ERS-220594: Test case to Hold the next Scheduled Appointment call if the current time is outside the Appt Dispatch window
    @isTest
    public static /*testmethod*/ void autoDispatchApptCallResourceStartedTest_False(){ 
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 
        WorkOrder woTest = [SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c FROM WorkOrder Limit 1 ]; 
        
        system.debug('woTest' + woTest);
        
        DateTime appointmentTime = System.now().addMinutes(60);
        woTest.Service_Resource__c = serviceResources[2].Id;
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime);

        update woTest;

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (select id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();        
        Id SAId;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){                
                sa.SchedStartTime = appointmentTime;
                sa.SchedEndTime = System.now().addMinutes(120);                
                sa.PTA__c = System.now().addMinutes(60);
                sa.Member_Scheduled__c = true;               
                SAList.add(sa); 

                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[2].Id);
                // assignedResource.EstimatedTravelTime = 120.00;
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 3 to be Active, deactivate all other resources    
        serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];            
        list<ServiceResource> srUpdate = new List<ServiceResource>();        
        
        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        srUpdate.add(serviceResources[2]);
        
        update srUpdate;                

        // Verify that it Dispatched     
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Scheduled', workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Scheduled', sa.Status);
        }

        Test.StopTest();           
    }

    @IsTest
    //ERS-220594: Test case to Dispatch the next scheduled call for the ServiceResource When the Current Call is Cleared
    public static /*testmethod*/ void dispatchNextCallTest(){               
		system.debug('In dispatchNextCallTest');
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();  
        
            Test.startTest();
            // Set timed appt time to be 60 min from now
            DateTime appTime = Datetime.now();        
            List<WorkOrder> woToBeClearedList = dispatchNextCallTest_DataSetup(appTime, false);
            system.debug('woToBeClearedList 352'+woToBeClearedList);
            
            Test.stopTest();    

            // Verify that before the call, WO2 is in Scheduled Status
            // List<WorkOrder> woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];
            // system.assertEquals('Scheduled', woList[1].Status, 'woList = ' + woList);

            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Status, (SELECT EarliestStartTime,Status,SchedStartTime FROM ServiceAppointments) FROM WorkOrder]);
            system.debug('woMap 361'+woMap);
            system.debug('woMap 361'+woMap.values()[0]);
            ServiceAppointment saToClear;
            for (WorkOrder wo : woMap.values()) {
                System.assertEquals('In Progress', wo.Status, 'wo = ' + wo);
                Boolean isWODispatched = (wo.Id == woToBeClearedList[0].Id);
                for (ServiceAppointment sa : wo.ServiceAppointments) {                
                    System.assertEquals((isWODispatched ? 'Dispatched' : 'Scheduled'), sa.Status, 'sa = ' + sa);
                    sa.SchedStartTime = Datetime.now().addMinutes(40);    //Added as it was failing during deployment	
            
                        sa.SchedEndTime = Datetime.now().addMinutes(70);      //Added as it was failing during deployment	
            
                        sa.EarliestStartTime = sa.SchedStartTime.addDays(-2);     //Added as it was failing during deployment
                }
                if (isWODispatched) {
                    saToClear =  wo.ServiceAppointments[0];
                }
            }

            // Map<Id, WorkOrder> oldWoMap = new Map<Id,WorkOrder>();
            // oldWoMap.put(woList[0].Id, woList[0]);        
            
            // Now update WO1 = 'Cleared'
            // woToBeClearedList[0].Status = 'Cleared';        
            // woToBeClearedList[0].Resolution_Code__c='R199';
            // update woToBeClearedList;

            saToClear.Resolution_Code__c = 'R199';
            saToClear.EarliestStartTime=saToClear.SchedStartTime.addDays(-15);   //Added as it was failing during deployment
            update saToClear;
            // Test our routine
            // FSL_DispatchUtility.dispatchNextCall(woToBeClearedList, oldWoMap);
            
            // Verifty the Results that the next call is changed from Scheduled to Dispatched
            // woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];
            // system.assertEquals('Dispatched', woList[1].Status, 'woList = ' + woList);
            
            List<ServiceAppointment> saList = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId != :woToBeClearedList[0].Id];
            for (ServiceAppointment sa : saList) {
                System.assertEquals('Dispatched', sa.Status, 'sa = ' + sa);
            } 
        }
    }
    
    @IsTest
    //ERS-220594: Test case to Dispatch the next scheduled Timed call for the ServiceResource When the Current Call is Cleared
    public static /*testmethod*/ void dispatchNextCallWithApptTest(){  
        
        
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 
        System.runAs( admin ) {
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();    

            Test.startTest();
            // Set timed appt time to be 60 min from now
            DateTime appTime = Datetime.now().addMinutes(30);

            List<WorkOrder> woToBeClearedList = dispatchNextCallTest_DataSetup(appTime, true);

            Test.stopTest();    

            // Verify that before the call, WO2 is in Scheduled Status
            // List<WorkOrder> woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];
            // system.assertEquals('Scheduled', woList[1].Status, 'woList = ' + woList);    

            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Status, (SELECT  Status, SchedStartTime, EarliestStartTime FROM ServiceAppointments) FROM WorkOrder]);
            List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
            ServiceAppointment saToClear;
            for (WorkOrder wo : woMap.values()) {
                System.assertEquals('In Progress', wo.Status, 'wo = ' + wo);
                Boolean isWODispatched = (wo.Id == woToBeClearedList[0].Id);
                for (ServiceAppointment sa : wo.ServiceAppointments) {                
                    System.assertEquals((isWODispatched ? 'Dispatched' : 'Scheduled'), sa.Status, 'sa = ' + sa);
                    if (!isWODispatched) {
                        sa.SchedStartTime = Datetime.now().addMinutes(40);
                        sa.SchedEndTime = Datetime.now().addMinutes(70);
                        sa.EarliestStartTime = sa.SchedStartTime.addDays(-2); //Added as it was failing during deployment
                        saToUpdateList.add(sa);
                    }
                }
                if (isWODispatched) {
                    saToClear =  wo.ServiceAppointments[0];
                }
            }

            update saToUpdateList;

            // Get the WO Map before Cleared
            // Map<Id, WorkOrder> oldWoMap = new Map<Id,WorkOrder>();
            // oldWoMap.put(woList[0].Id, woList[0]);        
            
            // Now update WO1 = 'Cleared'
            // woToBeClearedList[0].Status = 'Cleared';        
            // woToBeClearedList[0].Resolution_Code__c='R199';
            // update woToBeClearedList;

            saToClear.Resolution_Code__c = 'R199';
            saToClear.SchedStartTime = Datetime.now().addMinutes(40);	
            saToClear.EarliestStartTime=saToClear.SchedStartTime.addDays(-2);    //Added as it was failing during deployment
            update saToClear;

            // Test our routine
            // FSL_DispatchUtility.dispatchNextCall(woToBeClearedList, oldWoMap);
            
            // Verifty the Results that the next call is changed from Scheduled to Dispatched
            // woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];

            // system.assertEquals('Dispatched', woList[1].Status, 'woList = ' + woList);

            List<ServiceAppointment> saList = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId != :woToBeClearedList[0].Id];
            for (ServiceAppointment sa : saList) {
                System.assertEquals('Dispatched', sa.Status, 'sa = ' + sa);
            }
        }
    }
    
    @IsTest
    public static /*testmethod*/ void dispatchNextCallWithApptTest_False(){  

        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
        
			system.debug('IN dispatchNextCallWithApptTest_False 477');        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            Test.startTest();
            // Set timed appt time to be 60 min from now
            DateTime appTime = Datetime.now().addMinutes(60);
            List<WorkOrder> woToBeClearedList = dispatchNextCallTest_DataSetup(appTime, true);
            Test.stopTest();    

            // Verify that before the call, WO2 is in Scheduled Status
            // List<WorkOrder> woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];
            // system.assertEquals('Scheduled', woList[1].Status, 'woList = ' + woList);    

            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Status, (SELECT Status, SchedStartTime, EarliestStartTime FROM ServiceAppointments) FROM WorkOrder]);
            ServiceAppointment saToClear;
            for (WorkOrder wo : woMap.values()) {
                System.assertEquals('In Progress', wo.Status, 'wo = ' + wo);
                Boolean isWODispatched = (wo.Id == woToBeClearedList[0].Id);
                for (ServiceAppointment sa : wo.ServiceAppointments) {                
                    System.assertEquals((isWODispatched ? 'Dispatched' : 'Scheduled'), sa.Status, 'sa = ' + sa);
                    sa.SchedStartTime = Datetime.now().addMinutes(40);    //Added as it was failing during deployment	
            
                        sa.SchedEndTime = Datetime.now().addMinutes(70);      //Added as it was failing during deployment	
            
                        sa.EarliestStartTime = sa.SchedStartTime.addDays(-2);     //Added as it was failing during deployment
                }
                if (isWODispatched) {
                    saToClear =  wo.ServiceAppointments[0];
                }
            }

            // Get the WO Map before Cleared
            // Map<Id, WorkOrder> oldWoMap = new Map<Id,WorkOrder>();
            // oldWoMap.put(woList[0].Id, woList[0]);        
            
            // Now update WO1 = 'Cleared'
            // woToBeClearedList[0].Status = 'Cleared';        
            // woToBeClearedList[0].Resolution_Code__c='R199';
            // update woToBeClearedList;

            saToClear.Resolution_Code__c = 'R199';
            saToClear.EarliestStartTime=saToClear.SchedStartTime.addDays(-15);   //Added as it was failing during deployment
            system.debug('@@@saToClear@@@525' + saToClear);
            update saToClear;

            // Test our routine
            // FSL_DispatchUtility.dispatchNextCall(woToBeClearedList, oldWoMap);
            
            // Verifty the Results that the next call is changed from Scheduled to Dispatched
            // woList = [SELECT ID, Call_Id__c, Status FROM WorkOrder];
            // system.assertEquals('Scheduled', woList[1].Status, 'woList = ' + woList);
            
            List<ServiceAppointment> saList = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId != :woToBeClearedList[0].Id];
            for (ServiceAppointment sa : saList) {
                System.assertEquals('Scheduled', sa.Status, 'sa = ' + sa);
            }
        }
    }

    //ERS-220594: Test data setup routine for Dispatch the next scheduled call for the ServiceResource When the Current Call is Cleared
    public static List<WorkOrder> dispatchNextCallTest_DataSetup(DateTime apptTime, Boolean isApptCall){   
        system.debug(' in dispatchNextCallTest_DataSetup');
        
        List<Contact> contacts = [SELECT id,accountid FROM Contact];
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
        List<ServiceResource> serviceResources = [SELECT id,IsActive, Currently_Scheduled__c FROM ServiceResource];                        

        // For ServiceResourceId=1, set On Schedule = true
        serviceResources[0].IsActive = true;
        serviceResources[0].Currently_Scheduled__c = true;
        update serviceResources;        
        
        // create shell objects for WO1
        List<WorkOrder> woList = new List<WorkOrder>();
        List<WorkOrder> woToBeClearedList = new List<WorkOrder>();
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        
        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
        wo1.Service_Resource__c = serviceResources[0].Id; 
        wo1.External_ID__c = '004-20210123-315651';
        wo1.Call_Date__c = '2021-01-23';       
        //wo1.Status = 'Cleared';     
        //wo1.Resolution_Code__c='R199';
        woList.add(wo1);
        woToBeClearedList.add(wo1);

        // Create WO2
        WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
        wo2.Call_Id__c = '20002';
        wo2.Service_Resource__c = serviceResources[0].Id;
        wo2.External_ID__c = '004-20210123-315652';
        wo2.Call_Date__c = '2021-01-23';           
        if(isApptCall){
            wo2.Non_Emergency_Appointment_Time__c = String.valueOfGmt(apptTime);   // Assign the Timed future Appointment time to the WO here
        }          
        woList.add(wo2);

        insert woList;
            
        // create shell objects for SA
        DateTime nowTime = apptTime;
        DateTime nextTime = nowTime.addMinutes(60);                        
        ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
        saList.add(sa);
        ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');   
        if(isApptCall){
            sa2.Member_Scheduled__c = true;
        }
        saList.add(sa2);
        insert saList;            
              
        // create assigned resources for first SA, so that WO1 will auto Dispatch    
        // At this point, there is only one WO and after AR, the WO is auto dispatched.     
        AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa.id, ServiceResources[0].id);
        insert ar1;                   
        
        // Now insert the 2nd AssignedResource which should Trigger the WO/SA Status Update
        // Since WO1 = Dispatched, WO2 will remain in Scheduled Status        
        AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);    
        insert ar2;
        
        return woToBeClearedList;
                                                                    
    }

    //ERS-220594: Test case to Dispatch the next scheduled appointment call for the ServiceResource
    @isTest
    public static /*testmethod*/ void dispatchCurrentApptCallsTest(){
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();        

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T'];
        WorkOrder woTest = [SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c, (SELECT Id FROM ServiceAppointments) FROM WorkOrder LIMIT 1];
        // Set a future appt 60 min away
        DateTime appointmentTime = System.now().addMinutes(60);
        woTest.Service_Resource__c = serviceResources[2].Id;        
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime).replace(' ', 'T');
        update woTest;

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (select id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();                

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){                
                sa.SchedStartTime = appointmentTime;
                sa.SchedEndTime = appointmentTime.addMinutes(60);                
                sa.PTA__c = appointmentTime;
                sa.Member_Scheduled__c = true;               
                SAList.add(sa); 

                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[2].Id);               
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 3 to be Active, deactivate all other resources    
        serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];                                
        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        list<ServiceResource> srUpdate = new List<ServiceResource>();    
        srUpdate.add(serviceResources[2]);
        
        update srUpdate;                        

        // Now update the WO Appointment time to be 30 min away
        // woTest = [SELECT Id, Non_Emergency_Appointment_Time__c FROM WorkOrder Limit 1 ];         
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(System.now().addMinutes(30));        
        update woTest;
        for (ServiceAppointment sa : woTest.ServiceAppointments) {                
            sa.SchedStartTime = System.now().addMinutes(30);
            sa.SchedEndTime = System.now().addMinutes(60);
        }
        update woTest.ServiceAppointments;

        // Assume LKL interval and wake up and call the routine to dispatch next order
        FSL_DispatchUtility.dispatchCurrentApptCalls();

        // Verify that it is in Scheduled Status     
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Dispatched', workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }

        Test.StopTest();    
        
    }

    //ERS-220594: Test case to NOT Dispatch the next scheduled appointment call for the ServiceResource since it is outside appt dispatch window
    @isTest
    public static /*testmethod*/ void dispatchCurrentApptCallsTest_False(){
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();        

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 
        WorkOrder woTest = [SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c FROM WorkOrder Limit 1 ]; 
        // Set a future appt 60 min away
        DateTime appointmentTime = System.now().addMinutes(120);
        woTest.Service_Resource__c = serviceResources[2].Id;
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime).replace(' ', 'T');        
        update woTest;

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (select id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();                

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){                
                sa.SchedStartTime = appointmentTime;
                sa.SchedEndTime = appointmentTime.addMinutes(60);                
                sa.PTA__c = appointmentTime;
                sa.Member_Scheduled__c = true;               
                SAList.add(sa); 

                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[2].Id);               
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 3 to be Active, deactivate all other resources    
        serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];                                
        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        list<ServiceResource> srUpdate = new List<ServiceResource>();    
        srUpdate.add(serviceResources[2]);
        
        update srUpdate;                                

        // Assume LKL interval and wake up and call the routine to dispatch next order
        FSL_DispatchUtility.dispatchCurrentApptCalls();

        // Verify that it is in Scheduled Status     
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Scheduled', workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Scheduled', sa.Status);
        }

        Test.StopTest();    
        
    }

    // ERS-220594: Test case to change the SA status to the correct order after ROS run
    // Regular non timed call
    @isTest
    public static /*testmethod*/ void reDispatchServiceResourceTest(){    
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            //List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id,accountid FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT id,IsActive, Currently_Scheduled__c FROM ServiceResource];                        

            // For ServiceResourceId=1, set On Schedule = true
            serviceResources[0].IsActive = true;
            serviceResources[0].Currently_Scheduled__c = true;
            update serviceResources;        
            
            // create shell objects for WO1
            List<WorkOrder> woList = new List<WorkOrder>();
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
            wo1.Service_Resource__c = serviceResources[0].Id; 
            wo1.External_ID__c = '004-20210123-315651';
            wo1.Call_Date__c = '2021-01-23';                   
            woList.add(wo1);

            // Create WO2
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
            wo2.Call_Id__c = '20002';
            wo2.Service_Resource__c = serviceResources[0].Id; 
            wo2.External_ID__c = '004-20210123-315652';
            wo2.Call_Date__c = '2021-01-23';           
            woList.add(wo2);
            insert woList;
                
            // create shell objects for SA
            DateTime nowTime = Datetime.now();
            DateTime nextTime = nowTime.addMinutes(60);                        
            ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
            saList.add(sa);
            ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');   
            saList.add(sa2);
            insert saList;            

            Test.startTest();
            // create assigned resources for first SA, so that WO1 will auto Dispatch    
            // At this point, there is only one WO and after AR, the WO is auto dispatched.     
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa.id, ServiceResources[0].id);
            insert ar1;                   

            // Now insert the 2nd AssignedResource which should Trigger the WO/SA Status Update
            // Since WO1 = Dispatched, WO2 will remain in Dispatched Status        
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);            
            insert ar2;                      
        
            // Test our routine
            SAList = FSL_DispatchUtility.reDispatchServiceResource(serviceResources[0].Id);
            update SAList;

            SAList = [SELECT id, Status FROM ServiceAppointment];
            System.assertEquals('Dispatched', SAList[0].Status);
            System.assertEquals('Scheduled', SAList[1].Status);

            Test.stopTest();   
        }
    }

    // ERS-220594: Test case to change the SA status to the correct order after ROS run
    // Timed Appointment Call - Dispatch window within 45 min, Appointment Call set to current + 20 Min
    @isTest
    public static /*testmethod*/ void reDispatchServiceResourceApptCallTest(){   
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {   
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            //List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT Id, AccountId FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT Id, IsActive, Currently_Scheduled__c FROM ServiceResource];                        

            // For ServiceResourceId=1, set On Schedule = true
            serviceResources[0].IsActive = true;
            serviceResources[0].Currently_Scheduled__c = true;
            update serviceResources;        
            
            // create shell objects for WO1
            List<WorkOrder> woList = new List<WorkOrder>();
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
                    
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
            DateTime appointmentTime = System.now().addMinutes(20);
            wo1.Service_Resource__c = serviceResources[0].Id; 
            wo1.External_ID__c = '004-20210123-315651';
            wo1.Call_Date__c = '2021-01-23';                 
            wo1.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime); 
            woList.add(wo1);

            // Create WO2
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
            wo2.Call_Id__c = '20002';
            wo2.Service_Resource__c = serviceResources[0].Id; 
            wo2.External_ID__c = '004-20210123-315652';
            wo2.Call_Date__c = '2021-01-23';           
            woList.add(wo2);
            insert woList;
                
            // create shell objects for SA
            DateTime nonApptCallStartTime = appointmentTime;
            DateTime apptCallStartTime = nonApptCallStartTime.addMinutes(20);                        
            // First create the Appointment Call SA
            ServiceAppointment sa1 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, apptCallStartTime, 30, 'Breakdown Appointment');
            saList.add(sa1);
            // The following SA2 is a regular non-appointment call
            ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nonApptCallStartTime, 30, 'Breakdown Appointment');   
            saList.add(sa2);
            insert saList;         


            Test.startTest();
            // create assigned resources for first SA, so that WO1 will auto Dispatch    
            // At this point, there is only one WO and after AR, the WO is auto dispatched.     
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa1.id, ServiceResources[0].id);
            insert ar1;

            SAList = [SELECT id, Status FROM ServiceAppointment Limit 1];
            // SA1 is an appointment call that is 20min away, so should be auto Dispatched Status
            System.assertEquals('Dispatched', SAList[0].Status);

            // Now insert the 2nd AssignedResource which should Trigger the WO/SA Status Update
            // Since SA1 = Dispatched, SA2 will remain in Scheduled Status        
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);            
            insert ar2;
            
            List<ServiceAppointment> saList1 = [SELECT Status FROM ServiceAppointment];
            for (ServiceAppointment servApp : saList1) {
                System.debug('sa = ' + servApp.Status);
            }
        
            // Test our routine, at this time, since SA1 == Dispatched (But 20 min away), SA2 = Scheduled but is right now.
            // So the following routine should swap the two SAs and make:  SA2 == Dispatched, SA1 == Scheduled
            SAList = FSL_DispatchUtility.reDispatchServiceResource(serviceResources[0].Id);
            for (ServiceAppointment servApp : SAList) {
                System.debug('sa after reDispatchServiceResource = ' + servApp.Status);
                System.debug('sa == sa.id = ' + (servApp.Id == sa1.Id));
            }
            update SAList;

            // SAList = [SELECT id, Status FROM ServiceAppointment];
            // System.assertEquals('Dispatched', SAList[0].Status);
            // System.assertEquals('Scheduled', SAList[1].Status);

            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([SELECT Status FROM ServiceAppointment]);
            // SA1 is an appointment call that is 20min away, so it has an initial Dispatched Status, 
            // but was rearranged by the testing routine to Scheduled since the new coming SA2 has a current time
            System.assertEquals('Scheduled', saMap.get(sa1.Id).Status);
            // SA2 is a regular call that has current start time, so it took priority and has Dispatched Status
            System.assertEquals('Dispatched', saMap.get(sa2.Id).Status);

            Test.stopTest();   
        }
    }

    // ERS-220594: Test case to change the SA status to the correct order after ROS run
    // Timed Appointment Call - Dispatch window outside 45 min (60 min)
    @isTest
    public static /*testmethod*/ void reDispatchServiceResourceApptCallTest_False(){   
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) { 
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            //List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id,accountid FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT id,IsActive, Currently_Scheduled__c FROM ServiceResource];                        

            // For ServiceResourceId=1, set On Schedule = true
            serviceResources[0].IsActive = true;
            serviceResources[0].Currently_Scheduled__c = true;
            update serviceResources;        
            
            // create shell objects for WO1
            List<WorkOrder> woList = new List<WorkOrder>();
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
                    
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
            DateTime appointmentTime = System.now().addMinutes(60);
            wo1.Service_Resource__c = serviceResources[0].Id; 
            wo1.External_ID__c = '004-20210123-315651';
            wo1.Call_Date__c = '2021-01-23';                  
            wo1.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime); 
            woList.add(wo1);

            // Create WO2
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
            wo2.Call_Id__c = '20002';
            wo2.Service_Resource__c = serviceResources[0].Id; 
            wo2.External_ID__c = '004-20210123-315652';
            wo2.Call_Date__c = '2021-01-23';           
            woList.add(wo2);
            insert woList;
                
            // create shell objects for SA
            DateTime nonApptCallStartTime = appointmentTime;
            DateTime apptCallStartTime = nonApptCallStartTime.addMinutes(60); 
            // First create the Appointment Call SA
            ServiceAppointment sa1 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, apptCallStartTime, 30, 'Breakdown Appointment');
            sa1.Member_Scheduled__c = true;
            saList.add(sa1);
            // The following SA2 is a regular non-appointment call
            ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nonApptCallStartTime, 30, 'Breakdown Appointment');        
            saList.add(sa2);
            insert saList;     
      

            Test.startTest();
            // create assigned resources for first SA, so that WO1 will auto Dispatch  if qualifies  
            // At this point, there is only one WO and after AR, the WO will try to auto dispatch, 
            // but in this case, since it is an appointment call 60 min away, it does not qualify
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa1.id, ServiceResources[0].id);
            insert ar1;                   

            SAList = [SELECT id, Status FROM ServiceAppointment Limit 1];
            // SA1 is an appointment call that is 60min away, so should remain in Scheduled Status
            System.assertEquals('Scheduled', SAList[0].Status);

            // Now insert the 2nd AssignedResource which should Trigger the SA Status Update
            // SA1 = Scheduled, SA2 will be auto Dispatched since it has a most current start time than SA2
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);            
            insert ar2;

            List<ServiceAppointment> saList1 = [SELECT Status FROM ServiceAppointment];
            for (ServiceAppointment servApp : saList1) {
                System.debug('sa1 = ' + servApp.Status);
            }
        
            // Test our routine
            SAList = FSL_DispatchUtility.reDispatchServiceResource(serviceResources[0].Id);
            for (ServiceAppointment servApp : SAList) {
                System.debug('sa1 after reDispatchServiceResource = ' + servApp.Status);
                System.debug('sa1 == sa1.id = ' + (servApp.Id == sa1.Id));
            }
            update SAList;

            SAList = [SELECT id, Status FROM ServiceAppointment];
            // SA1 is an appointment call that is 60min away, so should remain in Scheduled Status
            System.assertEquals('Scheduled', SAList[0].Status);
            // SA2 is a current new call and should remain in Dispatched Status.
            System.assertEquals('Dispatched', SAList[1].Status);

            Test.stopTest();   
        }
    }

    @isTest
    public static void testDispatchUtility_IsEligibleForDispatch_NonApptCall_EnRouteToDispatched(){
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

        // Create a WO/SA
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));     
        
        // Call setup routine
        IsEligibleForDispatch_NonApptCall_Setup('En Route');

        // Test to see if it is auto Dispatched
        // At this point, the SA should be assigned to AR2 and auto dispatched.
        List<ServiceAppointment> saList = [SELECT Id, Status FROM ServiceAppointment];
        System.assertEquals('Dispatched', saList[0].Status);
              
    }
    @isTest
    public static void testDispatchUtility_IsEligibleForDispatch_NonApptCall_OnLocationToDispatched(){
		
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        // Create a WO/SA
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));     
        
        // Call setup routine
        IsEligibleForDispatch_NonApptCall_Setup('On Location');
                
        // Test to see if it is auto Dispatched
        // At this point, the SA should be assigned to AR2 and auto dispatched.
        List<ServiceAppointment> saList = [SELECT Id, Status FROM ServiceAppointment];
        System.assertEquals('Dispatched', saList[0].Status);
                     
    }
    
    public static void IsEligibleForDispatch_NonApptCall_Setup(String InitialStatus){
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      
                
        List<Contact> contacts = [SELECT id,accountid FROM Contact];
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
        List<ServiceResource> serviceResources = [SELECT id,IsActive, Currently_Scheduled__c FROM ServiceResource];                        

        // For ServiceResourceId=1, set On Schedule = true
        serviceResources[0].IsActive = true;
        serviceResources[0].Currently_Scheduled__c = true;
        serviceResources[1].IsActive = true;
        serviceResources[1].Currently_Scheduled__c = true;
        update serviceResources;        

        // create shell objects for WO1
        List<WorkOrder> woList = new List<WorkOrder>();
        List<ServiceAppointment> saList = new List<ServiceAppointment>();

        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
        wo1.Service_Resource__c = serviceResources[0].Id; 
        wo1.External_ID__c = '004-' + Datetime.now().format('yyyyMMdd') + '-315651';
        wo1.Call_Date__c = Datetime.now().format('yyyy-MM-dd');
        woList.add(wo1);        
        insert woList;
            
        // create shell objects for SA
        DateTime nowTime = Datetime.now();
        DateTime nextTime = nowTime.addMinutes(60);                        
        ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');        
        saList.add(sa);
        insert saList; 

        Test.startTest();

        // create assigned resources for the SA, so that WO1 will auto Dispatch    
        // At this point, there is only one WO and after AR, the WO is auto dispatched.     
        AssignedResource ar1 = FSL_DataFactory.createAssignedResource(saList[0].id, ServiceResources[0].id);
        insert ar1;                                             

        // Retrieve the saved SA and update it to 'En Route'/'On Location'
        saList = [SELECT Id, Status FROM ServiceAppointment];
        if(InitialStatus == 'On Location'){
            // You can not directly change from Dispatched to 'On Location'
            saList[0].Status = 'En Route';
            update saList;                
            saList = [SELECT Id, Status FROM ServiceAppointment];
        }
        saList[0].Status = InitialStatus;
        update saList;                

        // Reassign it to another Resource
        ar1.ServiceResourceId = serviceResources[1].ID;
        update ar1;
        
        Test.stopTest(); 
    }

    // The following unit test, tests what happen when a WO was reassgined from one SR to Another, and
    // when the inital Status is En Route.
 /*   @isTest
    public static void testDispatchUtility_IsEligibleForDispatch_ApptCall_EnRouteToDispatched(){
        
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();        

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Setup other data for testing
        IsEligibleForDispatch_ApptCall_Setup('En Route');

        // Now after AR reassigned to another SR, the WO should be auto reversed back to Dispatched
        // List<WorkOrder> workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Dispatched', workOrderList[0].Status);

        List<WorkOrder> workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];
        // System.debug('workOrderList.size  --> ' + workOrderList.size());

        System.assertEquals('In Progress', workOrderList[0].Status);
        // for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
        //     System.debug('sa.Status  --> ' + sa.Status);
        // }
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }
        
    }

    // The following unit test, tests what happen when a WO was reassgined from one SR to Another, and
    // when the inital Status is On Location.
    @isTest
    public static void testDispatchUtility_IsEligibleForDispatch_ApptCall_OnLocationToDispatched(){
        
        
        
           
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();        

        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     

        Test.startTest();   

        // Setup other data for testing
        IsEligibleForDispatch_ApptCall_Setup('On Location');
        
        // Now after AR reassigned to another SR, the WO should be auto reversed back to Dispatched
        // List<WorkOrder> workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Dispatched', workOrderList[0].Status);

        List<WorkOrder> workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }
    }

    public static void IsEligibleForDispatch_ApptCall_Setup(String InitialStatus){

        // Assign ServiceResource 3 to WorkOrder
        list<ServiceResource> serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T'];
        WorkOrder woTest = [SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c, (SELECT Id FROM ServiceAppointments) FROM WorkOrder LIMIT 1]; 
        // Set a future appt 60 min away
        DateTime appointmentTime = System.now().addMinutes(60);
        woTest.Service_Resource__c = serviceResources[2].Id;        
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime).replace(' ', 'T');
        update woTest;

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();                

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){                
                sa.SchedStartTime = appointmentTime;
                sa.SchedEndTime = appointmentTime.addMinutes(60);                
                sa.PTA__c = appointmentTime;
                sa.Member_Scheduled__c = true;               
                SAList.add(sa); 

                // Assign it to the 3rd SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[2].Id);               
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      

        // Now activate ServiceResource 2,3 to be Active   
        // serviceResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ];

        // For ServiceResourceId=3, set On Schedule = true
        serviceResources[1].IsActive = true;
        serviceResources[1].Currently_Scheduled__c = true;
        serviceResources[2].IsActive = true;
        serviceResources[2].Currently_Scheduled__c = true;
        list<ServiceResource> srUpdate = new List<ServiceResource>();    
        srUpdate.add(serviceResources[1]);
        srUpdate.add(serviceResources[2]);

        update srUpdate;                        

        // Now update the WO Appointment time to be 30 min away
        // woTest = [SELECT Id, Non_Emergency_Appointment_Time__c, () FROM WorkOrder LIMIT 1 ];         
        woTest.Non_Emergency_Appointment_Time__c = String.valueOfGmt(System.now().addMinutes(30));        
        update woTest;
        for (ServiceAppointment sa : woTest.ServiceAppointments) {                
            sa.SchedStartTime = System.now().addMinutes(30);
            sa.SchedEndTime = System.now().addMinutes(60);
        }
        update woTest.ServiceAppointments;

        // Assume LKL interval and wake up and call the routine to dispatch next order
        FSL_DispatchUtility.dispatchCurrentApptCalls();

        // Verify that it is in Disptached Status - to SR3
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals('Dispatched', workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals('Dispatched', sa.Status);
        }

        // Retrieve the saved SA and update it to Initial Status:  eg: En Route
        SAList = [SELECT Id, Status FROM ServiceAppointment];
        // For 'On Location', need to change status to 'En Route' first
        if(InitialStatus == 'On Location'){
            SAList[0].Status = 'En Route';
            update SAList;
            SAList = [SELECT Id, Status FROM ServiceAppointment];      
        }
        if (SAList[0].Status != InitialStatus) {
            SAList[0].Status = InitialStatus;
            update SAList;           
        }
        
        // workOrderList = [SELECT Id, Status FROM WorkOrder];    
        // System.assertEquals(InitialStatus, workOrderList[0].Status);

        workOrderList = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder];    
        System.assertEquals('In Progress', workOrderList[0].Status);
        for (ServiceAppointment sa : workOrderList[0].ServiceAppointments) {
            System.assertEquals(InitialStatus, sa.Status);
        }

        Test.StopTest();

        //Now Reassign the WO to Another SR 2
        ARList = [SELECT ID, ServiceResourceId FROM AssignedResource];
        ARList[0].ServiceResourceId = serviceResources[1].ID;
        update ARList;  
    }*/

    // ERS-220594: Test case to change all the SA's related to the SR List: All regular calls (Not Timed)
    @isTest
    public static /*testmethod*/ void getSortServiceAppointmentsTest(){   
        
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {       
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;



            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            // Call the Data Setup routine   
            Test.startTest();
            Map<ID, List<ServiceAppointment>> srIDToSAListMap =  new Map<ID, List<ServiceAppointment>>();
            Map<ID, List<WorkOrder>> srIDToWOListMap = new  Map<ID, List<WorkOrder>>();
            // Setup an timed appt call 60min away for WO1, SA1
            DateTime apptTime = Datetime.now();
            getSortServiceAppointments_DataSetup(srIDToSAListMap, srIDToWOListMap, apptTime, false);
            
            List<ServiceAppointment> saListUpdated = FSL_DispatchUtility.getSortServiceAppointments(srIDToSAListMap,srIDToWOListMap);
            
               
            System.assertEquals('Dispatched', saListUpdated[0].Status);
            System.assertEquals('Scheduled', saListUpdated[1].Status);
            System.assertEquals('Dispatched', saListUpdated[2].Status);
            System.assertEquals('Scheduled', saListUpdated[3].Status);
            

            Test.stopTest();   
        }
    }

    // ERS-220594: Test case to change all the SA's related to the SR List: Timed Call within 45 min   
    @isTest
    public static /*testmethod*/ void getSortServiceAppointments_TimedCallTest(){                        
		
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            // Call the Data Setup routine   
            Test.startTest();
            Map<ID, List<ServiceAppointment>> srIDToSAListMap =  new Map<ID, List<ServiceAppointment>>();
            Map<ID, List<WorkOrder>> srIDToWOListMap = new  Map<ID, List<WorkOrder>>();
            // Setup an timed appt call 60min away for WO1, SA1
            DateTime apptTime = System.now().addMinutes(30);
            getSortServiceAppointments_DataSetup(srIDToSAListMap, srIDToWOListMap, apptTime, true);

            List<ServiceAppointment> saListUpdated = FSL_DispatchUtility.getSortServiceAppointments(srIDToSAListMap,srIDToWOListMap);
                
            System.assertEquals('Dispatched', saListUpdated[0].Status,'SA1 Failed');
            System.assertEquals('Scheduled',  saListUpdated[1].Status,'SA2 Failed');
            System.assertEquals('Dispatched', saListUpdated[2].Status,'SA3 Failed');
            System.assertEquals('Scheduled',  saListUpdated[3].Status,'SA4 Failed');
            
            Test.stopTest();   
        }
    }

    // ERS-220594: Test case to change all the SA's related to the SR List: Timed Call Outside 45 min   
    @isTest
    public static /*testmethod*/ void getSortServiceAppointments_TimedCallTest_False(){                
		
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
            FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

            // Call the Data Setup routine   
            Test.startTest();
            Map<ID, List<ServiceAppointment>> srIDToSAListMap =  new Map<ID, List<ServiceAppointment>>();
            Map<ID, List<WorkOrder>> srIDToWOListMap = new  Map<ID, List<WorkOrder>>();
            // Setup an timed appt call 60min away for WO1, SA1
            DateTime apptTime = System.now().addMinutes(60);
            getSortServiceAppointments_DataSetup(srIDToSAListMap, srIDToWOListMap, apptTime, true);

            List<ServiceAppointment> saListUpdated = FSL_DispatchUtility.getSortServiceAppointments(srIDToSAListMap,srIDToWOListMap);
                
            // The 1st SA is outside Appt Time call dispatch window ,so not in the updated list
            System.assertEquals('Scheduled',  saListUpdated[0].Status,'SA2 Failed');
            System.assertEquals('Dispatched', saListUpdated[1].Status,'SA3 Failed');
            System.assertEquals('Scheduled',  saListUpdated[2].Status,'SA4 Failed');
            
            Test.stopTest();   
        }
    }    

    // ERS-220594: Test Data Setup for  getSortServiceAppointments
    public static void getSortServiceAppointments_DataSetup(Map<ID, List<ServiceAppointment>> srIDToSAListMap, Map<ID, List<WorkOrder>> srIDToWOListMap, DateTime apptTime, Boolean isApptCall){                
       
        //List<Account> accounts = [SELECT id FROM Account];
        List<Contact> contacts = [SELECT id,accountid FROM Contact];
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];

        // Set ServiceResource 1, 2 to be active and on schedule
        List<ServiceResource> serviceResources = [SELECT id, Currently_Scheduled__c FROM ServiceResource];                        
        serviceResources[0].Currently_Scheduled__c = true;
        serviceResources[1].Currently_Scheduled__c = true;
        update serviceResources;        
        
        // create shell objects for WO1
        List<WorkOrder> woList = new List<WorkOrder>();
        List<WorkOrder> woList12 = new List<WorkOrder>();
        List<WorkOrder> woList34 = new List<WorkOrder>();
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        
        // W1 - Make this an Timed Appointment Call with a dispatch window less than 45 min
        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);                     
        wo1.Service_Resource__c = serviceResources[0].Id; 
        wo1.External_ID__c = '004-20210123-315651';
        wo1.Call_Date__c = '2021-01-23';    
        if(isApptCall){
            wo1.Non_Emergency_Appointment_Time__c = String.valueOfGmt(apptTime);   // Assign the Appointment time to the WO here
        }                     
        woList.add(wo1);
        woList12.add(wo1);

        // WO2
        WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
        wo2.Call_Id__c = '20002';
        wo2.Service_Resource__c = serviceResources[0].Id; 
        wo2.External_ID__c = '004-20210123-315652';
        wo2.Call_Date__c = '2021-01-23';           
        woList.add(wo2);
        woList12.add(wo2);

        // W3
        WorkOrder wo3 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
        wo3.Call_Id__c = '20003';
        wo3.Service_Resource__c = serviceResources[1].Id; 
        wo3.External_ID__c = '004-20210123-315653';
        wo3.Call_Date__c = '2021-01-23';                       
        woList.add(wo3);
        woList34.add(wo3);

        // WO4
        WorkOrder WO4 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
        WO4.Call_Id__c = '20004';
        WO4.Service_Resource__c = serviceResources[1].Id; 
        WO4.External_ID__c = '004-20210123-315654';
        WO4.Call_Date__c = '2021-01-23';           
        woList.add(WO4);
        woList34.add(wo4);

        insert woList;
            
        // create shell objects for SA       
        List<ServiceAppointment> saList12 = new List<ServiceAppointment>();
        List<ServiceAppointment> saList34 = new List<ServiceAppointment>();
        DateTime nowTime = apptTime;
        DateTime nextTime = nowTime.addMinutes(60);                        
        ServiceAppointment sa1 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
        sa1.Status = 'Scheduled';
        if (isApptCall) {
            sa1.Member_Scheduled__c = true;
            sa1.SchedStartTime = apptTime;
        }
        saList.add(sa1);                
        // saList12.add(sa);
        ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');
        sa2.Status = 'Dispatched';
        saList.add(sa2);
        // saList12.add(sa2);
    
        nowTime = Datetime.now();
        nextTime = nowTime.addMinutes(60);   
        ServiceAppointment sa3 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo3.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
        sa3.Status = 'Scheduled';
        saList.add(sa3);
        // saList34.add(sa3);
        ServiceAppointment sa4 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo4.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');   
        sa4.Status = 'Dispatched';
        saList.add(sa4);
        // saList34.add(sa4);

        insert saList;            
       
        // create assigned resources for first SA, so that WO1 will auto Dispatch    
        // At this point, there is only one WO and after AR, the WO is auto dispatched.     
        List<AssignedResource> ARList = new List<AssignedResource>();
        AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa1.id, ServiceResources[0].id);
        ARList.add(ar1);
        AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa3.id, ServiceResources[1].id);
        ARList.add(ar2);
        insert ARList;        
        
        ARList.clear();
        AssignedResource ar3 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);
        ARList.add(ar3);
        AssignedResource ar4 = FSL_DataFactory.createAssignedResource(sa4.id, ServiceResources[1].id);
        ARList.add(ar4);
        insert ARList;               

        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([
            SELECT Id, ParentRecordId, Status, Service_Resource__r.Currently_Scheduled__c,
                    Work_Order__r.Service_Resource__c, Work_Order__r.Non_Emergency_Appointment_Time__c,
                    SchedStartTime, SchedEndTime, IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c
            FROM ServiceAppointment
            WHERE Id IN :saList
        ]);
        for (ServiceAppointment sa : saList) {
            ServiceAppointment queriedSA = saMap.get(sa.Id);
            queriedSA.Status = sa.Status;
        }

        saList12.add(saMap.get(sa1.Id));
        saList12.add(saMap.get(sa2.Id));

        saList34.add(saMap.get(sa3.Id));
        saList34.add(saMap.get(sa4.Id));
       
        // Test our routine        
        srIDToSAListMap.put(serviceResources[0].Id, saList12);     
        srIDToWOListMap.put(serviceResources[0].Id, woList12); 
        srIDToSAListMap.put(serviceResources[1].Id, saList34);            
        srIDToWOListMap.put(serviceResources[1].Id, woList34);                  
    }

    // ERS-223296: When a Call in 'En Route' or 'On Location' status was dragged to another Service Resource as a Stacked Call, the status was not automatically changed back to Scheduled.  
    @isTest
    public static /*testmethod*/ void rescheduleStackedCallsOnNewAssignment_EnRoute(){  
        
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        

            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
       
            rescheduleStackedCallsOnNewAssignment('En Route');
        }

    }
    @isTest
    public static /*testmethod*/ void rescheduleStackedCallsOnNewAssignment_OnLocation(){        

        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
       
        rescheduleStackedCallsOnNewAssignment('On Location');
    }

    }

    public static void rescheduleStackedCallsOnNewAssignment(String saStatus){
        //Insert Appointment Dispatch Window FSLSettings_AppointmentDispatchWindow
        FSL_DataFactory.FSLSettings_AppointmentDispatchWindow();      

        //List<Account> accounts = [SELECT id FROM Account];
        List<Contact> contacts = [SELECT id,accountid FROM Contact];
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
        List<ServiceResource> serviceResources = [SELECT id,IsActive, Currently_Scheduled__c FROM ServiceResource];                        

        // For SR1,2 set On Schedule = true
        serviceResources[0].IsActive = true;
        serviceResources[0].Currently_Scheduled__c = true;
        serviceResources[1].IsActive = true;
        serviceResources[1].Currently_Scheduled__c = true;
        update serviceResources;        
        
        // create shell objects for WO1 => SR1
        List<WorkOrder> woList = new List<WorkOrder>();
        List<ServiceAppointment> saList = new List<ServiceAppointment>();                       

        // Assign SA1 call to SR1
        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
        wo1.Service_Resource__c = serviceResources[0].Id; 
        wo1.External_ID__c = '004-20210527-315651';
        wo1.Call_Date__c = Datetime.now().format('yyyy-MM-dd');                   
        woList.add(wo1);

        // Create WO2 => SR2
        WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]); 
        wo2.Call_Id__c = '20002';
        wo2.Service_Resource__c = serviceResources[1].Id; 
        wo2.External_ID__c = '004-20210527-315652';
        wo2.Call_Date__c = Datetime.now().format('yyyy-MM-dd');          
        woList.add(wo2);
        insert woList;
            
        // create shell objects for SA
        DateTime sa2Time = Datetime.now();
        DateTime sa1Time = sa2Time.addMinutes(30);                        
        ServiceAppointment sa1 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, sa1Time, 30, 'Breakdown Appointment');
        saList.add(sa1);
        ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, sa2Time, 30, 'Breakdown Appointment');   
        saList.add(sa2);
        insert saList;            

        //Test.startTest();
        // create assigned resources for first SA, so that WO1 will auto Dispatch    
        // Change SA1 = Dispatched      
        List<AssignedResource> arList = new List<AssignedResource>();
        AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa1.id, ServiceResources[0].id);
        arList.add(ar1);
        
        // Assign SA2 call to SR2, SA2 = Dispatched
        AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[1].id);
        arList.add(ar2);     
        insert arList;                      
        
        // Retrieve the saved SA and update it to 'En Route'/'On Location'
        saList = [SELECT Id, Status FROM ServiceAppointment];         
		Test.startTest();
        // Change SA1 = En Route        
        saList[0].Status = 'En Route';        
        saList[1].Status = 'Dispatched';
        update saList;                

        // For On Location test case, we have to do a two step update, To 'En Route' Then to 'On Location'
        if(saStatus == 'On Location'){            
            saList = [SELECT Id, Status FROM ServiceAppointment Where Id =: saList[0].Id ];
            saList[0].Status = 'On Location';
            update saList;
        }
                 
        // Change SA1 (En Route) to SR2        
        ar1.ServiceResourceId = serviceResources[1].id;
        update ar1;

        // Check to see if SA1 status = Scheduled
        saList = [SELECT id, Status FROM ServiceAppointment];
        System.assertEquals('Scheduled', saList[0].Status);
        System.assertEquals('Dispatched', saList[1].Status);

        Test.stopTest();   

    }

    //==================================

    @isTest
    public static /*testmethod*/ void testConflictServiceResourceDispatchBothNormalPriority(){                                        

        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {      
            WorkOrder wrkOrder1 = createWorkOrder(null);
            WorkOrder wrkOrder2 = createWorkOrder('R0');
            
            ServiceResource srvResource = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ][2];

            Test.startTest();   
        
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;

		    Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); // macking mock callout for test purpose only

            
            assignWorkOrder(wrkOrder1, srvResource);
            scheduleServiceResource(srvResource);

            assignWorkOrder(wrkOrder2, srvResource);
            scheduleServiceResource(srvResource);
       

            Test.StopTest();

            verifyWorkOrderStatus(wrkOrder1, 'Dispatched');
            verifyWorkOrderStatus(wrkOrder2, 'Scheduled');
        }
    }

    // TODO: Uncomment this test once the reason why it fails with 101 SOQL queries in UAT (but passes in Dev orgs)
    // public static testmethod void testConflictServiceResourceDispatchCriticalAgainstNormalPriority(){                                        
      
    //     WorkOrder wrkOrder1 = createWorkOrder(null);
    //     WorkOrder wrkOrder2 = createWorkOrder('P1');
        
    //     ServiceResource srvResource = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ][2]; 
        
    //     Test.startTest();   

    //     assignWorkOrder(wrkOrder1, srvResource);
    //     scheduleServiceResource(srvResource);

    //     assignWorkOrder(wrkOrder2, srvResource);
    //     scheduleServiceResource(srvResource);

    //     Test.StopTest();

    //     verifyWorkOrderStatus(wrkOrder1, 'Dispatched');
    //     verifyWorkOrderStatus(wrkOrder2, 'Dispatched');
    // }

    @isTest
    public static /*testmethod*/ void testConflictServiceResourceDispatchCriticalAgainstCriticalPriority(){                                        
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {      
            WorkOrder wrkOrder1 = createWorkOrder('P1');
            WorkOrder wrkOrder2 = createWorkOrder('P1');
            
            ServiceResource srvResource = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ][2]; 

            Test.startTest();   
            
            
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
            
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));// macking mock callout for test purpose only

            assignWorkOrder(wrkOrder1, srvResource);
            scheduleServiceResource(srvResource);

            assignWorkOrder(wrkOrder2, srvResource);
            scheduleServiceResource(srvResource);

            Test.StopTest();
        

            verifyWorkOrderStatus(wrkOrder1, 'Dispatched');
            verifyWorkOrderStatus(wrkOrder2, 'Scheduled');
        }

    }

    @isTest
    public static /*testmethod*/ void testConflictServiceResourceDispatchP1LightServiceAgainstEnrouteStatus() {

        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
            ServiceResource srvResource = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ][2]; 

            WorkOrder wrkOrder1 = createWorkOrder(null);
            ServiceAppointment srvcAppointment = assignWorkOrder(wrkOrder1, srvResource);

        
            Test.startTest();
            
            
            
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
            
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));// macking mock callout for test purpose only
            

            //NOTE: need to change status inside Test.startTest to avoid 'Too many SOQL error'
            srvcAppointment.Status = 'En Route';
            update srvcAppointment;   
            WorkOrder wrkOrder2 = createWorkOrder('P1');
            assignWorkOrder(wrkOrder2, srvResource); 
            scheduleServiceResource(srvResource);

            Test.stopTest();
        

            verifyWorkOrderStatus(wrkOrder1, 'En Route');
            verifyWorkOrderStatus(wrkOrder2, 'Scheduled');
        }

    }

    private static void verifyWorkOrderStatus(WorkOrder wo, String expectedStatus) {

        // wo = [SELECT Id, Status FROM WorkOrder WHERE id =:wo.Id];
        // System.assertEquals(expectedStatus, wo.Status);

        wo = [SELECT Id, Status, (SELECT Status FROM ServiceAppointments) FROM WorkOrder WHERE Id = :wo.Id];    
        //System.assertEquals('In Progress', wo.Status);
        for (ServiceAppointment sa : wo.ServiceAppointments) {
            System.assertEquals(expectedStatus, sa.Status);
        }

    }

    private static WorkOrder createWorkOrder(String priorityCode) {
                
        List<Contact> contacts = [SELECT id,accountid FROM Contact];

        WorkOrder wrkOrder = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);              
        wrkOrder.External_ID__c = '004-' + Datetime.now().format('yyyyMMdd') + '-315651';
        wrkOrder.Call_Date__c = Datetime.now().format('yyyy-MM-dd');
        wrkOrder.Priority_Code__c = priorityCode;
        //wrkOrder.Non_Emergency_Appointment_Time__c = String.valueOfGmt(appointmentTime);

        insert wrkOrder;

        return wrkOrder;

    }

    private static ServiceAppointment assignWorkOrder(WorkOrder wrkOrder, ServiceResource srvResource) {
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];

        DateTime nowTime = Datetime.now();
        DateTime nextTime = nowTime.addMinutes(60);                        
        ServiceAppointment srvcAppointment = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wrkOrder.id, wrkOrder.ContactId, nowTime, 30, 'Breakdown Appointment');        
        insert srvcAppointment;

        AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(srvcAppointment.Id, srvResource.Id);
        insert assignedResource;

        return srvcAppointment;

    }

    private static void scheduleServiceResource(ServiceResource srvResource) {
        srvResource.IsActive = true;
        srvResource.Currently_Scheduled__c = true;
        update srvResource;                

    }

    @isTest
    public static void testDispatchCurrentCallFlowUpdate() {

        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {

            // Create WorkOrder1, SR1, SA1
            List<ServiceResource> srvResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' ]; 

            WorkOrder wrkOrder1 = createWorkOrder(null);
            ServiceAppointment sa1 = assignWorkOrder(wrkOrder1, srvResources[0]);
            scheduleServiceResource(srvResources[0]);
            
            Test.startTest();
            
            
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom setting
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
            
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));// macking mock callout for test purpose only

            WorkOrder wrkOrder2 = createWorkOrder(null);
            ServiceAppointment sa2 = assignWorkOrder(wrkOrder2, srvResources[1]);
            scheduleServiceResource(srvResources[1]);
        
            // Now construct the input test data
            List<ServiceAppointment> saList1 =  new List<ServiceAppointment>{sa1};
            List<ServiceAppointment> saList2 =  new List<ServiceAppointment>{sa2};
        
            List<List<ServiceAppointment>> newSAToDispatchList = new List<List<ServiceAppointment>>();
            newSAToDispatchList.add(saList1);
            newSAToDispatchList.add(saList2);

            FSL_DispatchUtility.dispatchCurrentCallFlowUpdate(newSAToDispatchList);
            
            verifyWorkOrderStatus(wrkOrder1, 'Dispatched');
            verifyWorkOrderStatus(wrkOrder2, 'Dispatched');        

            Test.stopTest();

        }
        



    }
    
    
    @isTest
    public static void reDispatchOptimizedAppointmentsTest() {
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {        
            // Create WorkOrder1, SR1, SA1
            FSL__Optimization_Request__c request1 = new FSL__Optimization_Request__c();
            FSL__Optimization_Request__c request2 = new FSL__Optimization_Request__c();
            FSL__Optimization_Request__c request3 = new FSL__Optimization_Request__c();
            List<FSL__Optimization_Request__c> requests = new List<FSL__Optimization_Request__c>{ request1, request2, request3 };
                insert requests;
            
            Datetime createdDatetime = Datetime.newInstance( 2020, 1, 20, 13, 14, 15 );
            Date createdDate = createdDatetime.date();
            Test.setCreatedDate( request1.Id, createdDatetime.addDays( -1 ) );
            Test.setCreatedDate( request2.Id, createdDatetime );
            Test.setCreatedDate( request3.Id, createdDatetime.addDays( 1 ) );
            
            // FSL_OptimizationRequest.IOptimizationRequestDAO dao = new FSL_OptimizationRequest.OptimizationRequestDAO();
            Test.startTest();
            //  List<FSL__Optimization_Request__c> result = dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
            FSL_DispatchUtility.reDispatchOptimizedAppointments(requests);
            Test.stopTest();
        }
        
    }
    
    
    @isTest
    public static void dispatchResourceNextCallTest() {
        
        // Create WorkOrder1, SR1, SA1
        ServiceResource srvResources = [SELECT id, IsActive, Currently_Scheduled__c FROM serviceresource WHERE ResourceType='T' LIMIT 1 ]; 
        User admin = [SELECT ID FROM USER WHERE Alias = 'C_Admin'][0];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=admin.Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( admin ) {
            WorkOrder wrkOrder1 = createWorkOrder(null);
            ServiceAppointment sa1 = assignWorkOrder(wrkOrder1, srvResources);
            scheduleServiceResource(srvResources);
            
            Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));// macking mock callout for test purpose only
            
            WorkOrder wrkOrder2 = createWorkOrder(null);
            Set<Id> serResId = new Set<Id>();
            
            serResId.add(srvResources.id);
            FSL_DispatchUtility.dispatchResourceNextCall(serResId);
            Test.stopTest();
        }
        
    }

}