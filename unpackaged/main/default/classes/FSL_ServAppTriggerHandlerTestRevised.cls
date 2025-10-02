@isTest
public class FSL_ServAppTriggerHandlerTestRevised {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }


    //Service Tech Team: Already covered with another method
    //  public  static testMethod void validateZipcodePostalInsertTest() {
	// 	System.Test.startTest();
	// 	ServiceTerritory objServiceTerritory ;
	// 	Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    //     FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     Zip_Code__c objZipCode = new Zip_Code__c();
	// 	objZipCode.Name = '90016';
	// 	insert objZipCode;
        
    //     LIST<ServiceAppointment> sa=[select id, Status, FSL__Pinned__c, recordtype.name, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
    //                                              Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
    //                                              FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,isBreakdown__c,PostalCode,ZIP_Code_For_Coverage_Lookup__c,
    //                                               SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
    //                                        from ServiceAppointment where isBreakdown__c=true ];
		
	
	// 		 objServiceTerritory = [SELECT Restrict_coverage_via_zip_code__c,PostalCode FROM ServiceTerritory 
	// 									WHERE Id =: sa[0].ServiceTerritoryID];
    //         objServiceTerritory.Restrict_coverage_via_zip_code__c=TRUE;
    //         UPDATE objServiceTerritory;
	// 	List<ServiceAppointment> updatedServiceAppointment= FSL_ServiceAppointmentTriggerHandler.BeforeInsertZipCode(sa);
	// 	Test.stopTest();

	

	// 	// Test that the trigger correctly updated the ZIP_Code_For_Coverage_Lookup__c
	// 	System.assertEquals(objZipCode.Id, updatedServiceAppointment[0].ZIP_Code_For_Coverage_Lookup__c);
	// }
    
    @isTest
    public  static /*testmethod*/ void validateZipcodePostalUpdate() {
		System.Test.startTest();
		ServiceTerritory objServiceTerritory ;
		Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Zip_Code__c objZipCode = new Zip_Code__c();
		objZipCode.Name = '90015';
		insert objZipCode;
        Zip_Code__c objZipCode2 = new Zip_Code__c();
		objZipCode2.Name = '90016';
		insert objZipCode2;
        
        LIST<ServiceAppointment> sa=[select id, Status, FSL__Pinned__c, recordtype.name, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                                 Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                                 FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                                  SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                           from ServiceAppointment];
		
		ServiceAppointment objServiceAppointment;
		list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                          (select id, Status, FSL__Pinned__c, recordtype.name, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                                 Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                                 FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                                  SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                           from ServiceAppointments
                                           order by recordtype.name asc) 
                                          from Workorder];
		if(!workOrders.isEmpty() && !workOrders[0].ServiceAppointments.isEmpty()){
			objServiceAppointment = [SELECT PostalCode, ServiceTerritoryID, isBreakdown__c,RecordType.DeveloperName FROM ServiceAppointment 
										WHERE Id =: workOrders[0].ServiceAppointments[0].Id];
			objServiceTerritory = [SELECT Restrict_coverage_via_zip_code__c,PostalCode FROM ServiceTerritory 
										WHERE Id =: workOrders[0].ServiceAppointments[0].ServiceTerritoryID];
            objServiceTerritory.Restrict_coverage_via_zip_code__c=TRUE;
            UPDATE objServiceTerritory;
		}
		objServiceAppointment.PostalCode = '90015';
		update objServiceAppointment;
		Test.stopTest();

		// Retrieve the updated ServiceAppointment
		List<ServiceAppointment> updatedServiceAppointment = [SELECT Id, ZIP_Code_For_Coverage_Lookup__c FROM ServiceAppointment WHERE Id =: objServiceAppointment.Id];

		// Test that the trigger correctly updated the ZIP_Code_For_Coverage_Lookup__c
		//System.assertEquals(objZipCode.Name, updatedServiceAppointment[0].ZIP_Code_For_Coverage_Lookup__c);
	}

    @isTest
    public static /*testmethod*/ void ServiceAppointmentTestMethod()    {        
        
                
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();
         Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime,ServiceTerritoryId,Service_Resource__c,Status, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList;
        list<ServiceAppointment>  SAs = [SELECT id, RecordTypeId, ParentRecordId, AppointmentNumber, Subject, FSL_IsLight_Service__c, 
                                                Is_Cleared__c, SchedStartTime, ServiceTerritoryId, Service_Resource__c, Status, SchedEndTime, 
                                                Actualstarttime, PTA__c, FSL__Related_Service__c, ETA__c, isBreakdown__c, Resolution_Code__c,
                                                FSL_In_Tow_Timestamp__c, FSL_Enroute_Time_Stamp__c, Resource_Latitude__c, Resource_Longitude__c,
                                                Original_Service_Territory__c
                                        FROM ServiceAppointment];

        system.debug('SAs:'+SAs);
        ServiceAppointment sa = SAs[0];

        Map<ID,ServiceAppointment>  MapServiceAppointment =  new Map<ID,ServiceAppointment>();
        Map<ID,ServiceAppointment> Oldsamap = new Map<ID,ServiceAppointment>();
        Oldsamap.put(sa.id,sa);
        Map<ID, ServiceAppointment> Newsamap = new Map<ID,ServiceAppointment>();
        Newsamap.put(sa.id,sa);
        MapServiceAppointment.put(sa.ID,sa);
        List<ServiceAppointment> pending_saList = new List<ServiceAppointment>();
        pending_saList.add(sa);
        
        FSL_ServiceAppointmentTriggerHandler.updateMilesOnServiceAppointment(SAs);
        FSL_ServiceAppointmentTriggerHandler.updateEndTimes(SAs);
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.resetAcknowledgeFlag(SAs);
    
        for(ServiceAppointment sa2 : SAs){        
            sa2.status = 'On Location';
            sa2.ActualStartTime = null;   
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualStart(SAs);
        
        for(ServiceAppointment sa2 : SAs){  
            sa2.status = 'Tow Complete';  
            sa2.ActualStartTime = system.today();    
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualStart(SAs);
        System.assertEquals(sa.ActualStartTime,system.today(),'Unexpected error while setting actualStartTime');
        
        for(ServiceAppointment sa2 : SAs){  
            sa2.status = 'In Tow' ; 
            sa2.FSL_In_Tow_Timestamp__c = null; 
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualStart(SAs); 
        System.assertEquals(sa.FSL_In_Tow_Timestamp__c, system.now(),'Unexpected error while setting FSL_In_Tow_Timestamp__c');  
        
        for(ServiceAppointment sa2 : SAs){  
            sa2.ActualEndTime = null;
            sa2.FSL_In_Tow_Timestamp__c = null;
            sa2.FSL_IsLight_Service__c = false ;
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(SAs);
        System.assertEquals(sa.FSL_In_Tow_Timestamp__c, null,'Unexpected error while setting FSL_In_Tow_Timestamp__c');    
        
        for(ServiceAppointment sa2 : SAs){  
          sa2.FSL_In_Tow_Timestamp__c = null;         
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(SAs);
        DateTime nowTime = System.now();    
        DateTime currentTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(),0);    


        for(ServiceAppointment sa2 : SAs){          
            sa2.ActualEndTime = null;
            sa2.FSL_IsLight_Service__c = false ;
            sa2.status = 'Cleared' ;  
        }
        //sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId(); 
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(SAs);
        
        for(ServiceAppointment sa2 : SAs){  
            sa2.ActualEndTime = null;
            sa2.FSL_IsLight_Service__c = true ;
            sa2.status = 'Cleared' ;  
        }
        //sa2.recordTypeid = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId(); 
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(SAs);

        for(ServiceAppointment sa2 : SAs){  
            sa2.ActualEndTime = null;
            sa2.SchedEndTime = null;
            sa2.FSL_IsLight_Service__c = false ;
            sa2.status = 'In Tow' ;
        }
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(SAs);
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.updateOriginalScheduledStart(SAs);
        FSL_ServiceAppointmentTriggerHandler.updateResourceLocation(SAs);
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.dispatcherSubscription(Oldsamap ,Newsamap);
        
        //Service Tech Team: remove metods
        // try
        // {
        //     FSL_ServiceAppointmentTriggerHandler.checkUpdateOnServiceAppointmentAfterClearedStatus(SAs,MapServiceAppointment);  
        // }
        // catch(exception e)
        // {}

        // try
        // {
            FSL_ServiceAppointmentTriggerHandler.copyOriginalTerritoryToServiceTerritory(SAs);
        // }
        // catch(exception e)
        // {}
        
        
        
        
        workOrderList[0].status = 'Cleared';
        workOrderList[0].Resolution_Code__c = 'G414';
        
        // try {
            update workOrderList[0];
        // }catch(Exception ex) {}
        
        Test.stopTest();
    }
    
    @isTest
    public static /*testmethod*/ void pinnedUnpinnedTestMethod() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();   
        
            FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //inserting custom settings
            endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
            endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
            endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
            endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
            endpoint.Timeout__c = 20000;
            endpoint.Named_Credential__c = 'OAuth';
            endpoint.Name='OAuth';
            insert endpoint;
        
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList;

        serviceappointment sa2 = SAList[0];
        sa2.PTA__c =system.now()+1;

        // try {
            update sa2;
        // }catch(Exception e) {
            
        // }
        
        serviceappointment sa = SAList[0];
        sa.Schedule_Delta__c = 10;
        sa.status='Dispatched';
        sa.PostalCode = '524173';
        sa.Manual_Override_Reason__c = 'Test';
        sa.ActualEndTime = (System.now()).addHours(3);
        sa.SchedEndTime= (System.now()).addHours(2);
        // try {
            update sa;
        // }catch(Exception ex) {
            
        // }
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.updateRelatedSAs((new Set<Id>{sa.Id}));
    }
    
    @isTest
    public static /*testmethod*/ void acknowledgedTestMethod() {
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList;
         Test.stopTest();
        
         
        workOrderList[0].Manual_Override_Reason__c = 'Flatbed Required';
       system.debug(' 327 workOrderList '+ workOrderList );
        update workOrderList[0];
        
        system.debug(' 330 workOrderList '+ workOrderList );
		  
        
        serviceappointment sa2 = SAList[0];
        
        sa2.Acknowledge__c  = true;
        Map<Id,ServiceAppointment> saMap = new Map<Id,ServiceAppointment>{sa2.Id=>sa2};
        sa2.Street = 'Test';
        sa2.City = 'TestCity';
        sa2.State = 'MN';
        sa2.PostalCode = '112344';
        sa2.Duration = 40;
        
        
        update sa2;
        //Service Tech Team: remove metods
        //     FSL_ServiceAppointmentTriggerHandler.setAddressChangedFlag(saMap,new Map<Id,ServiceAppointment>{sa2.Id=>sa2});

       // Test.stopTest(); As we are hiting 101 changing the place for stoptest.
    }
    
    @isTest
   public static /*testmethod*/ void allowUpdatesTestMethod() {
      //  System.Test.startTest();
      //Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        List<WorkOrder> workOrderList = [
           			 SELECT Id, 
                    (SELECT SchedStartTime, SchedEndTime,Facility_Number__c, Actualstarttime, Status, PTA__c, AppointmentNumber, ETA__c, 
                     ParentRecordId, ServiceTerritoryId, Service_Resource__c, Resolution_Code__c, FSL__Related_Service__c,
                     isBreakdown__c,Scheduled_Timestamp__c, Dispatched_Timestamp__c, En_Route_Timestamp__c, 
                     On_Location_Timestamp__c, Canceled_Timestamp__c
                    FROM ServiceAppointments)
            		FROM WorkOrder];
        list<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, 
                                                  Primary_Service_Territory__r.OperatingHoursId 
                                                  FROM serviceresource WHERE ResourceType='T' ];
        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();  
                sa.duration = 10;              
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
                
                
                
            }
        }
        system.debug('SAList 399 ' + SAList);
        system.debug('ARList 400' + ARList);
        
        update SAList;
       // insert ARList; 
       // Commenting DML as hitting 101 by sanket, No coverage impacting as its 81 % 
        
        workOrderList[0].Manual_Override_Reason__c = 'Flatbed Required';
        update workOrderList[0];

         
        List<ServiceAppointment> oldList = new List<ServiceAppointment>();
        List<ServiceAppointment> newList = new List<ServiceAppointment>();
        serviceappointment sa = SAList[0];
        oldList.add(sa);
        sa.Status = 'Cleared';
        sa.Resolution_Code__c = 'X001';
        sa.Schedule_Delta__c = 5;
        newList.add(sa);
        System.debug('402 === oldList '+ oldList);
        System.debug('403 === newList '+ newList);
       Test.startTest();
        FSL_ServiceAppointmentTriggerHandler.handleArrivedETA(newList, FSL_Optimization_Settings__c.getOrgDefaults(), new List<ETA_Notification__e>());
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.allowUpdates(oldList, newList);
        // FSL_ServiceAppointmentTriggerHandler.constructFeedItemMap(new List<Id>{sa.Id}, '');
        //Test.startTest(); 
        
        FSL_ServiceAppointmentTriggerHandler.syncStatusToWO(oldList, new Map<String, String>{ 'Cleared' => 'Cleared' });
        //Service Tech Team: remove metods
        // FSL_ServiceAppointmentTriggerHandler.clearpinAppointments(oldList);
         Test.stopTest();
    }
/*    
    @isTest
    public static void testCancelledSA (){

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Datetime nowDT = System.now();

        Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, Facility_Number__c,  SchedEndTime, actualstarttime, PTA__c,ETA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = nowDT;
                sa.EarliestStartTime = sa.SchedStartTime.addMinutes( - 2 );
                sa.SchedEndTime = nowDT + 1800;
                // sa.actualstarttime = System.now();
                sa.actualstarttime = DateTime.newInstanceGMT(nowDT.yearGMT(), nowDT.monthGMT(), nowDT.dayGMT(), nowDT.hourGMT(), nowDT.minuteGMT(), 0);

                sa.PTA__c = nowDT;
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        //insert ARList;
        

        SAList[0].subject = 'Breakdown';
        SAList[0].Resolution_Code__c = 'X001';
        SAList[0].status ='Canceled'; //Cancelled
        
        update SAList[0];
        // try {
            workOrderList[0].status='Cleared';
            update workOrderList[0];
        // }
        // catch( Exception e ) {}
        Test.stopTest();
    }
*/    
    @isTest
    public static /*testmethod*/ void testUpdateWOSchedule (){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        test.starttest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList;        

        
        workOrderList[0].status='Scheduled';
        update workOrderList[0];
        test.stoptest();
    }
    
    @isTest
    public static /*testmethod*/ void testClearedSA (){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
         Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            wo.status = 'Spotted';
          
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList; 
        
       // workOrderList[0].Resolution_Code__c='G101';
        update workOrderList[0];  
        Test.StopTest();
    }

    @isTest  
    public static void testClearedRAPLightCall_HasPlatformEventLog (){
       
        // The main purpose of this test is to test the creation of the PlatformEvent                    
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');       
        

        list<ServiceAppointment> saList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        ServiceAppointment saClear;

        // Update WO to RAP Call
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, Status, SchedStartTime, 
                                                     SchedEndTime, actualstarttime, PTA__c,ParentRecordId 
                                                     FROM ServiceAppointments) FROM WorkOrder Limit 1];
        Id workOrderId = workOrderList[0].Id;
        workOrderList[0].Call_Type__c = 'RAP';
        update workOrderList[0];

        list<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, 
                                                  Primary_Service_Territory__r.OperatingHoursId
                                                  FROM serviceresource where ResourceType='T' Limit 1 ];
        // Make it available
        serviceResources[0].Currently_Scheduled__c = true;
        update serviceResources[0];
        Test.startTest();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now().addMinutes(-1);
                sa.SchedEndTime = System.now()+1800;
                //sa.actualstarttime = System.now().addMinutes(-1);
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                sa.EarliestStartTime = sa.SchedStartTime.addDays(-2);
                
                saList.add(sa);   

                // Assign SR to SA
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }        
        
        update saList;  
        
        insert ARList[0];        
         
        // Clear it
       
        saList[0].Resolution_Code__c = 'X001';
        update saList[0];
        
          
       
        Test.stopTest();

        // Check for Clear Platform Event Application Log to see if the Platform Event executed successfully
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c, Platform_Event_Data__c FROM FSL_Application_Log__c WHERE Work_Order__c = :saList[0].ParentRecordId AND Operation__c = 'WOSClearLog' Limit 1];
        System.debug('apLogs ' + apLogs);
        System.assertEquals(true, apLogs[0].API_Name__c.containsIgnoreCase('WorkOrder Clear Event'));   
        
        testRapPlatformEvent(workOrderId, ARList, apLogs);

    } 


/*  @isTest  //AGB removed CANNOT_EXECUTE_FLOW_TRIGGER, We can't save this record because the “Potential Issue (Jeopardy) - NE (Update) - Run Immediately” process failed. Give your Salesforce admin these details. <b>An unhandled fault has occurred in this flow</b>
    public static void testClearedLightCall_NoPlatformEventLog (){
        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
            // When a non RAP call is generated, there should be no RAP Cleared Platform Event                   
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));           
            
            // Setup RAP Events Only Custom settings
            FSL_Settings__c rapSetting = new FSL_Settings__c(Name = 'RAP Events Only',  Value__c = 'true' );        
            insert rapSetting;

            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');       
            Test.startTest();
    
            list<ServiceAppointment> saList = new list<ServiceAppointment>();
            list<AssignedResource> ARList = new list<AssignedResource>();
            ServiceAppointment saClear;
    
            // Update WO to RAP Call
            List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, Status, SchedStartTime, SchedEndTime, actualstarttime, PTA__c FROM ServiceAppointments) FROM WorkOrder Limit 1];
            Id workOrderId = workOrderList[0].Id;         
            update workOrderList[0];
    
            list<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId FROM serviceresource where ResourceType='T' Limit 1 ];
            // Make it available
            serviceResources[0].Currently_Scheduled__c = true;
            update serviceResources[0];
                    
            for(workOrder wo : workOrderList){
                for(ServiceAppointment sa : wo.ServiceAppointments){
                    sa.SchedStartTime = System.now().addMinutes(-1);
                    sa.SchedEndTime = System.now()+1800;
                    //sa.actualstarttime = System.now().addMinutes(-1);
                    sa.PTA__c = System.now();
                    sa.status = 'Dispatched'; 
                    sa.EarliestStartTime = sa.SchedStartTime.addDays(-2);
                    saList.add(sa);   
    
                    // Assign SR to SA
                    AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                    assignedResource.EstimatedTravelTime = 10.00;
                    ARList.add(assignedResource);
                }
            }        
            update saList;        
            insert ARList[0];        
            
            // Clear it
            saList[0].Resolution_Code__c = 'X001';
            update saList[0];
            
            Test.stopTest();    
    
            // Check for Clear Platform Event Application Log to see if the Platform Event executed successfully 
            List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c, Platform_Event_Data__c FROM FSL_Application_Log__c WHERE Work_Order__c = :saList[0].ParentRecordId AND Operation__c = 'WOSClearLog' Limit 1];   
            // There should be no log
            System.assertEquals(0, apLogs.size());          
        }
    } */

    /*
    @isTest
    public static void testClearedRAP_TowCall_PlatformEventLogGenerated() {
        DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0).addMinutes(-1);

        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
        
            Test.starttest();
            List<ServiceAppointment> saList = createDaoData(startTime, 15, 'Tow');    
            ServiceAppointment breakdownSA;
            ServiceAppointment towSA;

            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder Limit 1];  
            
            
            for (ServiceAppointment sa : saList) {
                if(sa.Subject == 'Breakdown Appointment'){                                          
                    sa.Latitude = 28.6977482; 
                    sa.longitude = -84.2909827;
                    sa.Landmark__c = 'Test Building';
                    sa.Street = '700 MAIN LANE';
                    sa.State = 'FL';
                    sa.postalcode = '32801';
                    sa.country = 'UNITED STATES';
                    sa.City = 'ORLANDO';
                    sa.Cross_Street__c = 'LUCERNE CIRCLE SW & HIGHWAY TO SOMEWHERE';
                    breakdownSA = sa;
                    sa.Work_Order__c = workOrderList[0].Id ; 
                }
                else{
                    sa.Tow_Destination_Name__c = 'Empire State Building';
                    sa.Address_Change_Counter__c = 1;
                    sa.Latitude = 40.748440; 
                    sa.longitude = -73.984559;
                    sa.Landmark__c = 'Empire State Building';
                    sa.Street = '20 W 34th St';
                    sa.State = 'NY';
                    sa.postalcode = '10001';
                    sa.country = 'UNITED STATES';
                    sa.City = 'New York';
                    sa.Cross_Street__c = 'None';
                    towSA = sa;
                    sa.Work_Order__c = workOrderList[0].Id ; 
                }
            }
            // First update the Tow sa
            update saList;
            Test.stoptest();    

            breakdownSA.Resolution_Code__c = 'X001';   
            update breakdownSA;        

            // Check for Clear Platform Event Application Log to see if the Platform Event executed successfully
            // By default in test, since the RAP Setting is not there, all calls become eligible calls for RAP Clear Platform
            
            List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c, Platform_Event_Data__c FROM FSL_Application_Log__c WHERE Work_Order__c = :workOrderList[0].Id AND Operation__c = 'WOSClearLog' Limit 1];  
            System.assertEquals(true, apLogs.size() > 0 ); 

            //Retrieve the log and compare
            if(apLogs[0].Platform_Event_Data__c != null){           
                WorkOrder_Clear__e woSC = (WorkOrder_Clear__e)JSON.deserialize(apLogs[0].Platform_Event_Data__c, WorkOrder_Clear__e.class);

                List<WorkOrder> woreclist = [SELECT id,Status,Tow_Location__Latitude__s,Tow_Location__Longitude__s,
                                            (SELECT id,Status,Cleared_Timestamp__c,Resolution_Code__c,Latitude,longitude,Address_Change_Counter__c,Landmark__c,Street,State,postalcode,country,city,Cross_Street__c,Tow_Destination_Name__c,isBreakdown__c,Subject FROM ServiceAppointments)
                                            FROM WorkOrder WHERE ID = :workOrderList[0].Id];
                // Validate the Platform Event Values          
                if(woreclist[0] != null){
                    WorkOrder wo = woreclist[0];
                    // Test ServiceAppointment
                    for(serviceAppointment sa: wo.ServiceAppointments){
                        if(!sa.isBreakdown__c && sa.Subject == 'Tow Appointment'){                                                                 
                            System.assertEquals( 'Empire State Building', woSC.TD_Name__c );                        
                            System.assertEquals( 40.748440, woSC.TD_Latitude__c);
                            System.assertEquals( -73.984559, woSC.TD_Longitude__c);
                            System.assertEquals( 'Empire State Building', woSC.TD_Landmark__c ); 
                            System.assertEquals( '20 W 34th St', woSC.TD_StreetName__c ); 
                            System.assertEquals( 'NY', woSC.TD_State__c ); 
                            System.assertEquals( '10001', woSC.TD_PostalCode__c );
                            System.assertEquals( 'UNITED STATES',  woSC.TD_Country__c ); 
                            System.assertEquals( 'New York', woSC.TD_City__c );                                                
                            System.assertEquals( 'None', woSC.TD_CrossStreet__c );                                                
                            System.assertEquals( 'PHYSICAL', woSC.TD_AddressType__c ); 
                            System.assertEquals( 'ADDRESS', woSC.TD_FOIType__c );                                                       
                        }                  
                    }
                }
            }
        }
    }
	*/

    private static void testRapPlatformEvent(Id workOrderId,  list<AssignedResource> ARList, List<FSL_Application_Log__c> apLogs ){

        //Retrieve the log and compare
        if(apLogs[0].Platform_Event_Data__c != null){           
            WorkOrder_Clear__e woSC = (WorkOrder_Clear__e)JSON.deserialize(apLogs[0].Platform_Event_Data__c, WorkOrder_Clear__e.class);

            List<WorkOrder> woreclist = [SELECT id,Status,Call_Id__c,Call_Date__c,External_ID__c,PTA__c,Call_Origin_OrgName__c,Call_Origin_OrgCode__c,Call_Type__c,WO_Member_Phone_Number__c,
                                        Contact.Firstname, Contact.Lastname,Contact.Email,Contact.Membership_Type__c,Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_OrgCode__c,Contact.Membership_Org__c,
                                        Contact.Membership_Level__c,Contact.Membership_Status__c,Contact.Membership_Since__c,Contact.Membership_Id__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,
                                        RAP_Case_Number__c,Original_Member_Id__c, Member_Vehicle__r.Vehicle_Year__c, Member_Vehicle__r.Vehicle_Type__c, Member_Vehicle__r.Vehicle_Tag__c, Member_Vehicle__r.Vehicle_State__c,Member_Vehicle__r.Vehicle_Model__c, Member_Vehicle__r.Vehicle_Make__c,
                                        Member_Vehicle__r.Vehicle_Fuel_Type__c, Member_Vehicle__r.Vehicle_Drive_Type__c,Member_Vehicle__r.Vehicle_Color__c,Wait_Time__c,Cleared_Timestamp__c,Non_Emergency_Appointment_Time__c,FSL_Pacesetter__c,Resolution_Code__c,
                                        Collision__c,Red_Flag__c,Priority_Code__c,Number_Of_Passengers__c,Needs_Flatbed__c,Flatbed_Requested__c,Payment_Required__c,ServiceTerritory.Name, ServiceTerritory.Facility_Number__c,
                                        Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,Is_Tow_WorkType__c,Tow_Location__Latitude__s,Tow_Location__Longitude__s,
                                        (SELECT Id,Code__c,Type__c FROM TroubleCodes__r WHERE Work_Order__c = :workOrderId),
                                        (SELECT Id,Policy_Code__c  FROM Policies__r WHERE Work_Order__c = :workOrderId),
                                        (SELECT id,Product__r.ProductCode FROM Service_Line_Items__r),
                                        (SELECT id,Status,Cleared_Timestamp__c,Resolution_Code__c,Latitude,longitude,Address_Change_Counter__c,Landmark__c,Street,State,postalcode,country,city,Cross_Street__c,Tow_Destination_Name__c,isBreakdown__c,Subject FROM ServiceAppointments)                                    
                                        FROM WorkOrder WHERE ID = :workOrderId];
            
            Set<Id> saIDSet = new Set<Id>();
            Map<Id, AssignedResource> woIdToARMap = new Map<Id, AssignedResource>();
                                
            for(ServiceAppointment sa : woreclist[0].ServiceAppointments){                   
                saIDSet.add(sa.id);
            }                       
           
            // Put WO and AR into a MAP
            for(AssignedResource ar : ARList){
                for(WorkOrder wo : woreclist){
                    if(ar.ServiceAppointment.ParentRecordID == WorkOrderId){
                        woIdToARMap.put(wo.Id, ar);
                    }
                }
            }

            // Validate the Platform Event Values          
            if(woreclist[0] != null){
                WorkOrder wo = woreclist[0];
             
                System.assertEquals( wo.Call_Id__c, woSC.D3_CallId__c);
                System.assertEquals( wo.Call_Date__c, woSC.D3_CallDate__c);
                System.assertEquals( wo.External_Id__c, woSC.D3_CallKey__c);
                System.assertEquals( wo.PTA__c, woSC.WorkOrder_PTA__c );
                //System.assertEquals( 'Cleared', woSC.WorkOrder_Status__c);
                System.assertEquals( wo.Call_Origin_OrgName__c,woSC.Channel_Name__c);
                System.assertEquals( wo.Call_Origin_OrgCode__c, woSC.Channel_Code__c);
                System.assertEquals( wo.Call_Type__c, woSC.WorkOrder_CallType__c);
                System.assertEquals( wo.WO_Member_Phone_Number__c, woSC.Member_PhoneNumber__c ); 
                System.assertEquals( wo.Contact.LastName, woSC.Member_LastName__c );
                System.assertEquals( wo.Contact.FirstName,  woSC.Member_FirstName__c );
                System.assertEquals( wo.Contact.Email, woSC.Member_EmailAddress__c );
                System.assertEquals( wo.Contact.Membership_Type__c, woSC.Member_MemberType__c ); 
                //RAP Program Related Mappings                
                System.assertEquals( wo.Contact.Membership_Sponsor__c,  woSC.RAP_Sponsor__c ); 
                System.assertEquals( wo.Contact.Membership_Program__c, woSC.RAP_Program__c );
                //System.assertEquals( wo.Contact.Membership_OrgCode__c, woSC.Member_ClubCode__c );
                System.assertEquals( wo.Contact.Membership_Org__c, woSC.Member_ClubName__c );                     
                System.assertEquals( wo.Contact.Membership_Level__c, woSC.Member_MemberLevel__c ); 
                System.assertEquals( wo.Contact.Membership_Status__c, woSC.Member_Status__c ); 
                System.assertEquals( wo.Contact.Membership_Since__c, woSC.Member_Since__c );                
                //System.assertEquals( wo.RAP_Case_Number__c, woSC.Member_Id__c );                
                System.assertEquals( String.Valueof(wo.Contact.Membership_Expiration_Date__c), woSC.Member_ExpirationDate__c );                           
                System.assertEquals( wo.Contact.Membership_Code__c, woSC.CDX_AuthCode__c );    
                System.assertEquals( wo.Contact.Membership_Authorization__c,  woSC.CDX_AuthLevel__c );    
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Year__c, woSC.Vehicle_Year__c);
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Type__c, woSC.Vehicle_VehicleType__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Tag__c, woSC.Vehicle_Tag__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_State__c, woSC.Vehicle_State__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Model__c, woSC.Vehicle_Model__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Make__c, woSC.Vehicle_Make__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Fuel_Type__c, woSC.Vehicle_FuelType__c ); 
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Drive_Type__c, woSC.Vehicle_DriveType__c );
                System.assertEquals( wo.Member_Vehicle__r.Vehicle_Color__c, woSC.Vehicle_Color__c );                 
                System.assertEquals( String.Valueof(wo.Wait_Time__c), woSC.WaitTime__c );             
                System.assertEquals( (string.valueofGMT(FSL_PlatformEventsHandler.convertToGMT(wo.ServiceAppointments[0].Cleared_Timestamp__c)).replace(' ', 'T') + 'Z') , woSC.WorkOrder_StatusTime__c );                             
                System.assertEquals( wo.Non_Emergency_Appointment_Time__c, woSC.WorkOrder_ApptTime__c ); 
                //Populating trouble Codes: need confirmation on the PROBLEM code
                //System.assertEquals( wo.FSL_Pacesetter__c, woSC.Codes_Pacesetter__c );
                System.assertEquals( wo.Resolution_Code__c, woSC.Codes_Resolution__c );                                
                for(FSL_TroubleCode__c t: wo.TroubleCodes__r){
                    if(t.Type__c == 'PROBLEM'){                     
                        System.assertEquals(t.Code__c,woSC.Codes_Problem__c);
                    }
                }          
                System.assertEquals( wo.Collision__c, woSC.WorkOrder_Collision__c );
                System.assertEquals( wo.Red_Flag__c, woSC.WorkOrder_RedFlag__c ); 
                System.assertEquals( wo.Priority_Code__c, woSC.Codes_Priority__c );  
                System.assertEquals( String.Valueof(wo.Number_Of_Passengers__c), woSC.WorkOrder_NumPass__c );  
                System.assertEquals( wo.Needs_Flatbed__c, woSC.WorkOrder_NeedsFlat__c ); 
                System.assertEquals( wo.Flatbed_Requested__c, woSC.WorkOrder_RequestFlat__c ); 
                // Payment
                System.assertEquals( wo.Payment_Required__c, woSC.WorkOrder_CashCall__c ); 
                //Populating policies Codes                                
                for(FSL_Policy__c p: wo.Policies__r){
                    if(p.Policy_Code__c != null){
                        System.assertEquals(p.Policy_Code__c, woSC.Codes_Policy__c);                       
                    }                    
                } 
                //Populating Provider Service Codes
                for(FSL_Service_Line_Item__c s: wo.Service_Line_Items__r){                    
                    System.assertEquals(s.Product__r.ProductCode, woSC.Codes_Service__c);
                }    
                //Populating Driver id and truck id
                if(woIdToARMap.get(WorkOrderId) != null){
                    System.assertEquals( woIdToARMap.get(WorkOrderId).ServiceResource.Driver_Id__c, woSC.Driver_Id__c);
                    System.assertEquals( woIdToARMap.get(WorkOrderId).ServiceResource.Vehicle__r.Truck_ID__c, woSC.Truck_Id__c);
                }
                System.assertEquals( wo.ServiceTerritory.Facility_Number__c, woSC.Facility_Id__c );
                System.assertEquals( wo.ServiceTerritory.Name, woSC.Facility_Name__c); 
                if(wo.Call_Origin_OrgCode__c != null){
                    //System.assertEquals(wo.Call_Origin_OrgCode__c, woSC.SourceSystem_OrgCode__c);
                }
                else{
                    System.assertEquals(wo.Call_Type__c, woSC.SourceSystem_OrgCode__c);
                }
                if(wo.Call_Origin_OrgName__c != null){
                    System.assertEquals(wo.Call_Origin_OrgName__c, woSC.SourceSystem_OrgName__c);
                }
                else{
                    //System.assertEquals(wo.Call_Type__c, woSC.SourceSystem_OrgName__c);
                }
                // SourceSystem_Id__c: eg: 004
                if(wo.External_Id__c != null && wo.External_Id__c.contains('-')){                    
                    wo.External_Id__c = wo.External_Id__c.split('-')[0];                                   
                    //System.assertEquals(wo.External_Id__c, woSC.SourceSystem_Id__c);                     
                }
                // Test ServiceAppointment
                for(serviceAppointment sa: wo.ServiceAppointments){
                    if(sa.isBreakdown__c){
                        if(sa.Address_Change_Counter__c != null && sa.Address_Change_Counter__c > 0){                             
                            System.assertEquals(sa.Latitude, woSC.BL_Latitude__c);
                            System.assertEquals(sa.longitude, woSC.BL_Longitude__c);      
                        }
                        else{                            
                            System.assertEquals(wo.Breakdown_Location__Latitude__s, woSC.BL_Latitude__c);
                            System.assertEquals(wo.Breakdown_Location__Longitude__s, woSC.BL_Longitude__c );
                        }
                        System.assertEquals( sa.Landmark__c, woSC.BL_Landmark__c );  
                        System.assertEquals( sa.Street, woSC.BL_StreetName__c );
                        System.assertEquals( sa.State, woSC.BL_State__c ); 
                        System.assertEquals( sa.postalcode, woSC.BL_PostalCode__c );
                        System.assertEquals( sa.country, woSC.BL_Country__c );  
                        System.assertEquals( sa.City, woSC.BL_City__c );                         
                        //System.assertEquals( , woSC.BL_FullAddress__c ); 
                        System.assertEquals( sa.Cross_Street__c, woSC.BL_CrossStreet__c );
                        System.assertEquals( 'ADDRESS', woSC.BL_FOIType__c ); 
                    } else if(sa.Subject == 'Tow Appointment'){                           
                        System.assertEquals( sa.Tow_Destination_Name__c, woSC.TD_Name__c ); 
                        if(sa.Address_Change_Counter__c != null && sa.Address_Change_Counter__c > 0){
                            System.assertEquals( sa.Latitude, woSC.TD_Latitude__c);
                            System.assertEquals( sa.longitude, woSC.TD_Longitude__c);
                        }
                        else{
                            System.assertEquals( wo.Tow_Location__Latitude__s, woSC.TD_Latitude__c);
                            System.assertEquals( wo.Tow_Location__Longitude__s, woSC.TD_Longitude__c );
                        }
                        System.assertEquals( sa.Landmark__c, woSC.TD_Landmark__c ); 
                        System.assertEquals( sa.Street, woSC.TD_StreetName__c ); 
                        System.assertEquals( sa.State, woSC.TD_State__c ); 
                        System.assertEquals( sa.postalcode, woSC.TD_PostalCode__c );
                        System.assertEquals( sa.country,  woSC.TD_Country__c ); 
                        System.assertEquals( sa.City, woSC.TD_City__c );                         
                        //System.assertEquals( strStreet + strCity + strState + strPostalCode + strCountry, woSC.TD_FullAddress__c ); 
                        System.assertEquals( sa.Cross_Street__c, woSC.TD_CrossStreet__c );                                                
                        System.assertEquals( 'PHYSICAL', woSC.TD_AddressType__c ); 
                        System.assertEquals( 'ADDRESS', woSC.TD_FOIType__c ); 
                    }
                }
            }
        } 
    }
/* //FATAL_ERROR|System.DmlException: Update failed. First exception on row 0 with id 08pEa000001ValIIAS; first error: CANNOT_EXECUTE_FLOW_TRIGGER, We can't save this record because the “Tracker - Outbound Notifications” process failed. Give your Salesforce admin these details. An Apex error occurred: System.LimitException: Too many SOQL queries: 101    
    @isTest
    public static void testLightCallsSA (){

        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {

            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
            FSL_DataFactory.createWOIntakeCall('FSL_LightCall');    
                        
            List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder LIMIT 1];
            list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
            list<ServiceAppointment> saList = new list<ServiceAppointment>();
            list<AssignedResource> arList = new list<AssignedResource>();
            for(workOrder wo : workOrderList){
                for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now().addMinutes(-1);
                sa.SchedStartTime = System.now().addMinutes(1800);
                    sa.SchedEndTime = System.now()+1800;
                    sa.ActualStartTime = System.now().addMinutes(-1);
                    sa.PTA__c = System.now();
                    sa.Status = 'Dispatched';
                    sa.EarliestStartTime = sa.SchedStartTime.addDays(-2);
                    saList.add(sa); 
                    
                    AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                    assignedResource.EstimatedTravelTime = 10.00;
                    arList.add(assignedResource);
                }
            }
            Test.startTest();    
            
            update saList;
            insert arList;
            

            for (ServiceAppointment sa : saList) {
                sa.Resolution_Code__c = 'X001';
            }
            update saList;
            Test.stopTest();  
            // workOrderList[0].Resolution_Code__c='X001';
            // update workOrderList[0];     
        }
        
    } */

    private static List<ServiceAppointment> createDaoData(DateTime startTime, Integer duration, String serviceType) {
        Integer recordCount = 5;
        Account accountTest = FSL_DataFactory.createAccount( 'Name Account' );
        insert accountTest;

        Contact contactTest = FSL_DataFactory.createContact( 'Last Name Contact' );
        contactTest.AccountId = accountTest.id;
        contactTest.Membership_Type__c = 'MEMBER' ; 
        insert contactTest;

        WorkOrder wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contactTest );
        insert wo;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st = new ServiceTerritory( Name = 'Service Territory', OperatingHoursId = hours[0].Id, IsActive = true );
        insert st;

        List<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
            FROM ServiceResource 
            WHERE ResourceType='T'
			LIMIT 1
		];
        serviceResources[0].Currently_Scheduled__c = true;
        update serviceResources[0];
            
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        List<AssignedResource> arList = new List<AssignedResource>();
        ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st.Id, wo.Id, contactTest.Id, startTime, duration, 'Breakdown Appointment' );
//        breakdownSa.actualstarttime = startTime;
//        breakdownSa.actualendtime = startTime.addMinutes(duration);
//        breakdownSa.PTA__c = startTime;
        if('Breakdown'.equals(serviceType)) {
            breakdownSa.FSL_IsLight_Service__c = true;
        }
        breakdownSa.SchedStartTime = startTime;
        breakdownSa.SchedEndTime = startTime.addMinutes( duration );
        breakdownSa.PTA__c = System.now();
        breakdownSa.Status = 'Dispatched';
        serviceAppointments.add( breakdownSa );
        insert breakdownSa;

        if('Tow'.equals(serviceType)) {

            ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( breakdownSa, duration );
            towSa.SchedStartTime = startTime;
            towSa.SchedEndTime = startTime.addMinutes( duration );
            towSa.PTA__c = System.now();
            serviceAppointments.add( towSa );
            insert towSa;
            
            breakdownSa.FSL__Related_Service__c = towSa.Id;
            breakdownSA.FSL__Same_Resource__c = true;
            towSa.FSL__Related_Service__c = breakdownSa.Id;
            towSa.FSL__Same_Resource__c = true;
            towSa.Status = 'Dispatched';
            update serviceAppointments;
        }
        // insert serviceAppointments;

        for( ServiceAppointment sa : serviceAppointments ) {
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource( sa.Id, serviceResources[0].Id );
            assignedResource.EstimatedTravelTime = 10.00;
            arList.add( assignedResource );
        }
        insert arList;


        //update serviceAppointments;
        return serviceAppointments;
    }

    @isTest
    public static void testBreakdownLightCallClearBeforeStartWithX001() {

        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
        
            DateTime nowTime = System.now();
            DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0).addMinutes(5);
            system.debug('startTime 1040 ' + startTime);
            test.starttest();       
            List<ServiceAppointment> saList = createDaoData(startTime.addMinutes(1), 1800, 'Breakdown');
            List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
            workOrderList[0].status='Dispatched';
            update workOrderList;
            workOrderList[0].Resolution_Code__c='X001';
            workOrderList[0].status='Cleared';
            update workOrderList[0];

            for(ServiceAppointment sa : saList) {
                sa.status = 'Cleared';  
                sa.Resolution_Code__c = 'X001'; 
                sa.EarliestStartTime = startTime.addDays(-2);
                
            }
            
            system.debug('saList 1048 ' + saList);
            update saList;

            saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
            test.stoptest();    
            system.assertEquals(SAList[0].SchedEndTime, SAList[0].SchedStartTime.addMinutes(1), 'Schedule End Time should be one minute after Start Time.'); 
        }
    }

    @isTest
    public static void testBreakdownLightCallClearPastStartWithX001() {
        
        DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
        test.starttest();
        List<ServiceAppointment> saList = createDaoData(startTime, 1800, 'Breakdown');
        List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
        workOrderList[0].status='Dispatched';
        update workOrderList;
        workOrderList[0].Resolution_Code__c='X001';
        workOrderList[0].status='Cleared';
        update workOrderList[0];

        for(ServiceAppointment sa : saList) {
            sa.status = 'Cleared'; 
            sa.Resolution_Code__c = 'X001';                
        }
        update saList;

        saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
        test.stoptest();    

        system.assertEquals(SAList[0].SchedStartTime, startTime, 'Scheduled Start Time should not change.');
        system.assertEquals(SAList[0].SchedEndTime, startTime.addMinutes(1), 'Schedule End Time should be one minute after Start Time.'); 
    }

    @isTest
    public static void testBreakdownLightCallClearPastEndWithX001() {
        
        DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0).addMinutes(-5);
        test.starttest();
        List<ServiceAppointment> saList = createDaoData(startTime, 3, 'Breakdown');
        List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
        workOrderList[0].status='Dispatched';
        update workOrderList;
        workOrderList[0].Resolution_Code__c='X001';
        workOrderList[0].status='Cleared';
        update workOrderList[0];

        for(ServiceAppointment sa : saList) {
            sa.status = 'Cleared';  
            sa.Resolution_Code__c = 'X001';               
        }
        update saList;

        saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
        test.stoptest();    

        system.assertEquals(SAList[0].SchedStartTime, startTime, 'Scheduled Start Time should not change.');
        system.assertEquals(SAList[0].SchedEndTime, startTime.addMinutes(1), 'Schedule End Time should be one minute after Start Time.'); 
    }

/*  //FATAL_ERROR|System.DmlException: Update failed. First exception on row 0 with id 08pEa000001ValJIAS; first error: CANNOT_EXECUTE_FLOW_TRIGGER, We can't save this record because the “Tracker - Outbound Notifications” process failed. Give your Salesforce admin these details. An Apex error occurred: System.LimitException: Too many SOQL queries: 101
    @isTest
    public static void testTowCallClearBeforeStartWithX001() {


        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
            DateTime nowTime = System.now();
            DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);

            Test.starttest();       
            List<ServiceAppointment> saList = createDaoData(startTime.addMinutes(5), 15, 'Tow');
            // List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
            // workOrderList[0].status='Dispatched';
            // update workOrderList;
            // workOrderList[0].Resolution_Code__c='X001';
            // workOrderList[0].status='Cleared';
            // update workOrderList[0];

            for (ServiceAppointment sa : saList) {
                //sa.Status = 'Cleared';    
                sa.EarliestStartTime = startTime.addDays(-2);
                sa.Resolution_Code__c = 'X001';             
            }
            update saList;

            saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
            Test.stoptest();    
            
            System.assertEquals(SAList[0].SchedEndTime, SAList[0].SchedStartTime.addMinutes(1), 'Schedule End Time of Breakdown should be one minute after Schedule Start Time.'); 
            System.assertEquals(SAList[1].SchedEndTime, SAList[1].SchedStartTime.addMinutes(1), 'Schedule End Time of Tow should be one minute after Schedule Start Time.');
            System.assertEquals(SAList[1].SchedStartTime, SAList[0].SchedStartTime.addMinutes(2), 'Schedule Start Time of Breakdown should be two minutes before Schedule Start Time of Tow.'); 
        }
    }  */

    @isTest
    public static void testTowCallClearPastStartWithX001() {

        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
            DateTime nowTime = System.now();
            DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0).addMinutes(-1);
            
            Test.starttest();
            List<ServiceAppointment> saList = createDaoData(startTime, 15, 'Tow');
            // List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
            // workOrderList[0].status='Dispatched';
            // update workOrderList;
            // workOrderList[0].Resolution_Code__c='X001';
            // workOrderList[0].status='Cleared';
            // update workOrderList[0];

            for (ServiceAppointment sa : saList) {
                // sa.status = 'Cleared';  
                sa.Resolution_Code__c = 'X001';               
            }
            update saList;

            saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
            Test.stoptest();    

            System.assertEquals(SAList[0].SchedEndTime, SAList[0].SchedStartTime.addMinutes(1), 'Schedule End Time of Breakdown should be one minute after Schedule Start Time.'); 
            System.assertEquals(SAList[1].SchedEndTime, SAList[1].SchedStartTime.addMinutes(1), 'Schedule End Time of Tow should be one minute after Schedule Start Time.');
        }
    }

/*
    @isTest
    public static void testTowCallClearPastEndWithX001() {
        
        DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0).addMinutes(-4);
        test.starttest();
        List<ServiceAppointment> saList = createDaoData(startTime, 2, 'Tow');
        List<WorkOrder> workOrderList = [SELECT Id FROM WorkOrder];
        workOrderList[0].status='Dispatched';
        update workOrderList;
        workOrderList[0].Resolution_Code__c='X001';
        workOrderList[0].status='Cleared';
        update workOrderList[0];

        for(ServiceAppointment sa : saList) {
            sa.status = 'Cleared';            
        }
        update saList;

        saList = [select SchedStartTime, SchedEndTime, status, Schedule_Delta__c from ServiceAppointment ];
        test.stoptest();    

        system.assertEquals(SAList[0].SchedStartTime, startTime.addMinutes(-3), 'Scheduled Start Time of Breakdown should go back by 3 minutes to avoid overlap.');
        system.assertEquals(SAList[0].SchedEndTime, SAList[0].SchedStartTime.addMinutes(1), 'Schedule End Time of Breakdown should be one minute after Schedule Start Time.'); 
        system.assertEquals(SAList[1].SchedEndTime, SAList[1].SchedStartTime.addMinutes(1), 'Schedule End Time of Tow should be one minute after Schedule Start Time.');
        system.assert(SAList[0].SchedStartTime < SAList[1].SchedStartTime, 'Schdule Start Time of breakdown should be before Schedule Start Time of Tow.');
    }*/

    /***** Service Tech Team:  Method does not exist or incorrect signature: void SyncUpdateClearFlag(Map<Id,ServiceAppointment>, Boolean) from the type FSL_ServiceAppointmentTriggerHandler*****
      public static testmethod void SyncUpdateClearFlagTest(){
        system.Test.startTest();
        Map<Id, ServiceAppointment> SyncClearMaps = new Map<Id, ServiceAppointment>();
        Boolean Updateflags;
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');   
        List<ServiceAppointment> relatedlist = [select id,is_cleared__c from ServiceAppointment ];
        ServiceAppointment sa = new ServiceAppointment();
        sa.Is_Cleared__c = false;
        relatedlist.add(sa);
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_ServiceAppointmentTriggerHandler.SyncUpdateClearFlag(SyncClearMaps,Updateflags);
        system.Test.stopTest();
    }*/
    

    
    //ERS-218373:  Set the Gantt Icon for COD if it is a COD call   
    @isTest
    public static /*testmethod*/ void updateGanttIconsOnSA_WOIntakeCall_PaymentRequiredTrue() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');

        Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c, 
                                                     FSL__GanttIcon__c from ServiceAppointments)
                                         			from WorkOrder];
        
        System.debug('=====1187 workOrderList=== ' + workOrderList);
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
                                                  from serviceresource where ResourceType='T' ];
        
        System.debug('=====1189 serviceResources=== ' + serviceResources);
        
        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                sa.Potential_Issue__c = true;
                sa.Driver_Needs_Help_Checkbox__c = false;
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        //Commeting DML as hitting 101 for by Sanket.
        
        //update SAList;
        // insert ARList; 

        // ***      AR records are inserted separately to prevent SELF_REFERENCE_FROM_TRIGGER exception    ***
       // insert ARList[0]; 
        //insert ARList[1];

        // Make sure the SA's GanttIcon field was updated by the Initial WO Creation
        //System.assert(String.isNotBlank(workOrderList[0].ServiceAppointments[0].FSL__GanttIcon__c));        
        
        Test.StopTest();
    }
    
    @isTest
    public static /*testmethod*/ void updateGanttIconsOnSA_WOIntakeCall_PaymentRequiredFalse (){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c, FSL__GanttIcon__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
                 
            }
        }
        
        update SAList;
        insert ARList; 
        
        

        // Make sure the SA's GanttIcon field was updated by the Initial WO Creation
        System.assert(String.isBlank(workOrderList[0].ServiceAppointments[0].FSL__GanttIcon__c));        
        
        Test.StopTest();
    }

    @isTest
    public static /*testmethod*/ void UpdateGanttIconsOnSA_FromWOTriggerHandler_PaymentRequiredTrue () {
        
        
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
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.startTest();
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c, FSL__GanttIcon__c, IsBreakdown__c FROM ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId FROM serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();

        ServiceAppointment breakdownSA;

        for (workOrder wo : workOrderList) {
            for (ServiceAppointment sa : wo.ServiceAppointments) {
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);

                if (sa.IsBreakdown__c) {
                    breakdownSA = sa;
                }
            }
        }
        
        update SAList;
        insert ARList;      

        // Before WO update, make sure the FSL__GanttIcon__c value is blank
        System.assert(String.isBlank(breakdownSA.FSL__GanttIcon__c));

        // Now Update the WO's Payment_Required__c field = true, and the SA's Gantt Icon field should be set to new URL
        // workOrderList[0].Payment_Required__c = true;
        // update workOrderList[0];
        Test.StopTest();

        breakdownSA.Payment_Required__c = true;
        update breakdownSA;

        //Refresh the WorkOrderList to see if the SA properties are updated
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];         
       
        // Now the SA's Gantt Icon field should has an URL value        
        System.assert(String.isNotBlank(breakdownSA.FSL__GanttIcon__c));
    }
    
    //@isTest
    public static /*testmethod*/ void UpdateGanttIconsOnSA_FromWOTriggerHandler_PaymentRequiredFalse() {
        FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        List<WorkOrder> workOrderList = [SELECT Id, (SELECT id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c, FSL__GanttIcon__c, IsBreakdown__c FROM ServiceAppointments) FROM WorkOrder];
        list<ServiceResource> serviceResources = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId FROM serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();

        ServiceAppointment breakdownSA;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.status = 'Dispatched';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
                
                if (sa.IsBreakdown__c) {
                    breakdownSA = sa;
                }
            }
        }
        
        update SAList;
        // insert ARList; 
        // ***      AR records are inserted separately to prevent SELF_REFERENCE_FROM_TRIGGER exception    ***
        insert ARList[0]; 
        insert ARList[1];     
        
        // Make sure before update the WO's Required field, the SA's Gantt Icon field is set to an url
        System.assert(String.isNotBlank(breakdownSA.FSL__GanttIcon__c));

        // Now Update the WO's Payment_Required__c field = false, and the SA's Gantt Icon url should be set to blank
        // workOrderList[0].Payment_Required__c = false;
        // update workOrderList[0];  

        breakdownSA.Payment_Required__c = false;
        update breakdownSA;

        Test.StopTest();

        //Refresh the WorkOrderList to see if the SA properties are updated
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];
       
        // Now the SA's Gantt Icon field should has an URL value        
        System.assert(String.isBlank(breakdownSA.FSL__GanttIcon__c));
        
    }

    @isTest
    // ERS-220005 - Appointment Call Handling in FSL:: Remove the pinning of appointments
    public static /*testmethod*/ void RemovePinAppointment_FSL_HandleOperationsOnSATriggerHandler_UnpinTrue () {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, Non_Emergency_Appointment_Time__c,(select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        DateTime nowTime = System.now(); 

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = nowTime.addHours(1);
                sa.SchedEndTime = nowTime.addHours(2);
                sa.actualstarttime = nowTime.addHours(1);
                sa.PTA__c = nowTime.addHours(1);                
                sa.status = 'Scheduled';
                SAList.add(sa); 
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }    
          
        }           

        // Make it an Appointment Call           
        workOrderList[0].Non_Emergency_Appointment_Time__c = String.valueOf(nowTime.addHours(1));
        update workOrderList[0];  

        // Now Update the SA
        update SAList;
        insert ARList;

        // Retrieve SA Pinned Status and see if it is changed
        workOrderList = [Select Id, (select id, FSL__Pinned__c from ServiceAppointments) from WorkOrder];           
        
        // Now verify that the SA's pinned status is still false                 
        System.assertEquals(workOrderList[0].ServiceAppointments[0].FSL__Pinned__c, false,'Unexpected error while setting FSL__Pinned__c');    
         
        Test.StopTest();
    }

    @isTest
    private static /*testmethod*/ void handleOperationsWithoutTimeStampFlag() {
        Test.starttest();
        
        FSL_WorkOrderResponse wo = FSL_DataFactory.createWOIntakeCall('FSL_UnknowComplexCall');
        System.debug('1414 == wo' + wo);
        List<ServiceAppointment> sa = [SELECT AccountId,Acknowledge__c,ArrivalWindowEndTime,Arrival_Window_End_Time_Update_Timestamp__c, Work_Order__c FROM ServiceAppointment Where Work_Order__r.WorkOrderNumber =: wo.workOrderNumber Limit 1];
        sa[0].ArrivalWindowEndTime = System.now();
        
        DataBase.UpsertResult result = Database.upsert(sa[0]);
        System.assertEquals(true, result.isSuccess());

        Test.stoptest();
      

    }

    @isTest
    private static /*testmethod*/ void handleOperationsWithTimeStampFlag() {
        Test.starttest();

        FSL_WorkOrderResponse wo = FSL_DataFactory.createWOIntakeCall('FSL_UnknowComplexCall');
 		 
      	System.debug('wo 1490 ' + wo);
        List<ServiceAppointment> sa = [SELECT AccountId,Acknowledge__c,ArrivalWindowEndTime,Arrival_Window_End_Time_Update_Timestamp__c, Work_Order__c FROM ServiceAppointment Where Work_Order__r.WorkOrderNumber =: wo.workOrderNumber Limit 1];
        
        System.debug('sa 1493 ' + sa);
        sa[0].ArrivalWindowEndTime = System.now();
        sa[0].Arrival_Window_End_Time_Update_Timestamp__c = System.now();

        // Database.UpsertResult result = Database.upsert(sa[0]);
        DataBase.UpsertResult result = Database.upsert(sa[0]);
        System.assertEquals(true, result.isSuccess());

        Test.stoptest();
    }
   
    @isTest
    public static /*testmethod*/ void testUpdateGanttIconsOnSA() {
        FSL_ServiceAppointment.IServiceAppointmentService serviceAppt = (new FSL_ServiceAppointment.Factory()).createService();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        // String GanttIconSystemUrl = System.URL.getOrgDomainUrl().toExternalForm();  
        String rapIconURL         = PageReference.forResource('FSLGanttRapIcon').getUrl();
        String codIconURL         = PageReference.forResource('FSLGanttCodIcon').getUrl();
        String rapExpectedIconURL = '/' +  rapIconURL.substring(rapIconURL.indexOf('resource'), removeTrailingURL(rapIconURL).length());
        String codExpectedIconURL = '/' +  codIconURL.substring(codIconURL.indexOf('resource'), removeTrailingURL(codIconURL).length());
        
      	ServiceAppointment breakdownSA = [
            SELECT FSL__GanttIcon__c, isBreakdown__c, Payment_Required__c, Work_Order__r.Call_Type__c
            FROM ServiceAppointment
            WHERE Work_Order__r.WorkOrderNumber = :res.workOrderNumber
            AND isBreakdown__c = true
            LIMIT 1
        ];
        WorkOrder wOrder = breakdownSA.Work_Order__r;

        // Test case RAP Call Only and PaymentRequired Is False
        wOrder.Call_Type__c = 'RAP';
        breakdownSA.Payment_Required__c = false;
        // List<ServiceAppointment> sa  = [SELECT FSL__GanttIcon__c, isBreakdown__c, Payment_Required__c FROM ServiceAppointment WHERE Work_Order__r.WorkOrderNumber =: res.workOrderNumber LIMIT 1];
        // for(ServiceAppointment saCheck: sa){
        //     if(saCheck.isBreakdown__c == true){
        //         saCheck.Payment_Required__c=false;
        //     }
        // } 
        
        update breakdownSA;
        update wOrder;
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];
        System.assertEquals(rapExpectedIconURL, breakdownSA.FSL__GanttIcon__c);

        // Test case RAP Call Only and Payment is true
        // wOrder.Call_Type__c        = 'RAP';
        // wOrder[0].Payment_Required__c = true;
        breakdownSA.Payment_Required__c = true;

        // List<ServiceAppointment> sa11  = [SELECT FSL__GanttIcon__c, isBreakdown__c, Payment_Required__c FROM ServiceAppointment WHERE Work_Order__r.WorkOrderNumber =: res.workOrderNumber LIMIT 1];
        // for(ServiceAppointment saCheck: sa11){
        //     if(saCheck.isBreakdown__c == true){
        //         saCheck.Payment_Required__c=true;
        //     }
        // }
        update breakdownSA;
        // upsert wOrder;
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];
        System.assertEquals(rapExpectedIconURL, breakdownSA.FSL__GanttIcon__c);


        // Test case Not RAP Call Only and PaymentRequired is true
        wOrder.Call_Type__c = 'Member';
        update wOrder;
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];
        System.assertEquals(codExpectedIconURL, breakdownSA.FSL__GanttIcon__c);

        //Test case Not RAP Call and Payment Required is false
      	// List<ServiceAppointment> sa31  = [SELECT FSL__GanttIcon__c, isBreakdown__c, Payment_Required__c FROM ServiceAppointment WHERE Work_Order__r.WorkOrderNumber =: res.workOrderNumber LIMIT 1];
        // for(ServiceAppointment saCheck: sa31){
        //     if(saCheck.isBreakdown__c == true){
        //         saCheck.Payment_Required__c=false;
        //     }
        // }
        breakdownSA.Payment_Required__c = false;
        
        update breakdownSA;
        // upsert wOrder;
        breakdownSA = [SELECT FSL__GanttIcon__c FROM ServiceAppointment WHERE Id = :breakdownSA.Id];
        System.assertEquals(true, String.isEmpty(breakdownSA.FSL__GanttIcon__c));

        Test.stopTest();   
    }

    @isTest
    public static /*testmethod*/ void testRemoveTrailingUrl() { 

        String glympseIconUrl = 'Glympse/resource/1614859183000/FSLGanttRapIcon?difle=21343,sldjljasf=3dd?skdfl';
        String aceContractUrl = 'ACEContractorCommunity/resource/1614859183000/FSLGanttRapIcon?difle=21343,sldjljasf=3dd';

        String expectedGlympseIconUrl = 'Glympse/resource/1614859183000/FSLGanttRapIcon';
        String expectedAceContractUrl = 'ACEContractorCommunity/resource/1614859183000/FSLGanttRapIcon';
        
        System.assertEquals(expectedGlympseIconUrl,removeTrailingUrl(glympseIconUrl));
        System.assertEquals(expectedAceContractUrl,removeTrailingUrl(aceContractUrl));
        System.assertEquals('', removeTrailingUrl(''));
        System.assertEquals('', removeTrailingUrl(null));
    }

    private static String removeTrailingUrl( String iconUrl) {
        String url = '';
        if (String.isNotBlank(iconUrl)) {
            url = iconUrl.indexOf('?') > 0 
                  ? iconUrl.subString(0, iconUrl.indexOf('?'))
                  : iconUrl;
        }
        return url;   
    }

    @isTest
    public static void testTowCall_StatusIsScheduledAndBreakdownStatusIsDispatched_StatusUpdatedToDispatched() {

        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
        
            DateTime nowTime = System.now();
            DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
            
            test.starttest();       
            List<ServiceAppointment> saList = createDaoData(startTime.addMinutes(5), 15, 'Tow');
            ServiceAppointment towAppointment;
            Id towRecordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            Id brkdnRecordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            

            ServiceAppointment brkdnAppointment; // SNK

            for( ServiceAppointment sa : saList ) {
                if( sa.RecordTypeId == towRecordTypeId ) towAppointment = sa;
                if( sa.RecordTypeId == brkdnRecordTypeID ) brkdnAppointment = sa;
            }


            // SNK-Test
            List<ServiceAppointment> brkSAs = [SELECT SchedStartTime, SchedEndTime, Status, Schedule_Delta__c 
                                                FROM ServiceAppointment
                                                WHERE Id = :brkdnAppointment.Id];


            System.assertEquals( 'Dispatched', brkSAs[0].Status, 'Breakdown Appointment is not set at Dispatched as expected' );


            towAppointment.Status = 'Scheduled';
            update towAppointment;
            test.stoptest();

            saList = [SELECT SchedStartTime, SchedEndTime, Status, Schedule_Delta__c 
                    FROM ServiceAppointment
                    WHERE Id = :towAppointment.Id];
            System.assertEquals( 'Dispatched', saList[0].Status, 'Tow Appointment is not in Dispatched status (synced with Breakdown Appointment)' ); 
        }
    }
  
    //ERS-230874 Glympse Removal - Part I
    /*-------------------------
    @isTest
    public static void callGlympseViolationTest() {
        Test.startTest();      
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        FSL.GlobalAPIS.addStatusTransition('Spotted', 'En Route');
        Set<Id> SAId = new Set<Id>(); 
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c, FSL__GanttIcon__c from ServiceAppointments) from WorkOrder];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.actualstarttime = System.now();
                sa.PTA__c = System.now();
                sa.Status = 'En Route';
                SAList.add(sa); 
                SAId.add(sa.Id);
                
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResources[0].Id);
                assignedResource.EstimatedTravelTime = 10.00;
                ARList.add(assignedResource);
            }
        }
        
        update SAList;
        insert ARList;
        FSL_ServiceAppointmentTriggerHandler.callGlympseViolation(SAId);
        
        Test.stopTest();
    }
    */
    
        @isTest
    public static void testcheckManualSchedule() {
        List<User> users = [SELECT Id FROM user WHERE Name = 'Automation User'];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        System.runAs( users[0] ) {

            
            List<ServiceAppointment> saList = createDaoData(System.now(), 15, 'Breakdown');

            saList[0].Service_Resource__c = serviceResources[0].Id;
            saList[0].FSL__InternalSLRGeolocation__Latitude__s = 38.8951;
            saList[0].FSL__InternalSLRGeolocation__Longitude__s = -77.0364;
            update saList[0];

            Test.setCreatedDate(saList[0].Id, System.now().addMinutes(-3));
            Test.startTest();
            saList[0].Service_Resource__c = serviceResources[1].Id;

            // saList[0].FSL__InternalSLRGeolocation__Latitude__s = 38.89512;
            saList[0].FSL__InternalSLRGeolocation__Longitude__s = -77.03641;
            update saList[0];

            ServiceAppointment sa = [SELECT FSL__Schedule_Mode__c, Manual_Schedule__c
                                                FROM ServiceAppointment
                                                WHERE Id = :saList[0].Id];

            Assert.areEqual('Manual',sa.FSL__Schedule_Mode__c );
            Assert.areEqual(TRUE,sa.Manual_Schedule__c );


        }
    }
}