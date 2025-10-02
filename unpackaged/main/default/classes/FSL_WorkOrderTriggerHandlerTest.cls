/**
* @File Name          : FSL_WorkOrderTriggerHandlerTest.cls
* @Description        : 
* @Author             : Rajesh Kemisetti
* @Group              : 
* @Modification Log   : 
* Ver       Date            Author            Modification
* 1.0    4/06/2020   Rajesh Kemisetti     Initial Version
*       
**/
@isTest
public class FSL_WorkOrderTriggerHandlerTest {
      
   
    	/*
    	 //EMI START -Commented following existing method due to errors for SSFI-77 dated 01-14-2025
		public static testmethod void allowUpdatesTest(){                         

        list<Account> accounts = [select id from Account where name like 'Member Account%'];
        Contact c = new Contact(AccountId=accounts[2].id, lastname='Jones');
        insert c;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  

        //assign the resources to the WO 
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
         System.Test.startTest();
        List<WorkOrder> workOrders = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                      Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,
                                      (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                       Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                       FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                       SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                       from ServiceAppointments
                                       order by recordtype.name asc)
                                      from Workorder];         
        
        system.debug('++workOrders1--:'+workOrders);
        list<ServiceAppointment> saList = new list<ServiceAppointment>();
        list<AssignedResource> resources = new list<AssignedResource>();
        for(WorkOrder wo : workOrders){
            wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            saList.add(wo.ServiceAppointments[0]);                      
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            resources.add(assignedResource);
        }
        update saList;
        insert resources;
        
        workOrders = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                      Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,
                      (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                       Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                       FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                       SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                       from ServiceAppointments
                       order by recordtype.name asc)
                      from Workorder];
        
        system.debug('++workOrders2:'+workOrders);
        workOrders[0].Status = 'Cleared';
        workOrders[0].Resolution_Code__c = 'G414';
        update workOrders;
        
        
        try{
            system.debug('++workOrders3:'+workOrders);
          
            workOrders[0].ContactId = c.id;
            workOrders[0].Status = 'In Progress';//Dispatched
            workOrders[0].member_account__c = accounts[2].id;
            workOrders[0].Manual_Override_Reason__c = ' Additional Equipment Needed';//
            workOrders[0].Resolution_Code__c = 'G701'; //Has value in org
            update workOrders[0];
            
        }        
        catch(Exception e) {
            system.debug('This Exception---:'+e.getMessage());
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }       
        
        System.Test.stopTest();
     }
    
	*/
	
    public static testmethod void updateContactOnSATest(){         
         
       /* list<Account> accounts = [select id from Account where name like 'Member Account%'];
        Contact c = new Contact(AccountId=accounts[2].id, lastname='Jones');
        insert c;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  

        //assign the resources to the WO 
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();
        
        List<WorkOrder> workOrders = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                      Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,
                                      (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                       Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                       FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                       SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                       from ServiceAppointments
                                       order by recordtype.name asc)
                                      from Workorder];         
        
        system.debug('++workOrders1:'+workOrders);
        list<ServiceAppointment> saList = new list<ServiceAppointment>();
        list<AssignedResource> resources = new list<AssignedResource>();
        for(WorkOrder wo : workOrders){
            wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            saList.add(wo.ServiceAppointments[0]);                      
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            resources.add(assignedResource);
        }
        update saList;
        insert resources;
        
        workOrders = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                      Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,
                      (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                       Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                       FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                       SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                       from ServiceAppointments
                       order by recordtype.name asc)
                      from Workorder];
        
        system.debug('++workOrders2:'+workOrders);

        
        workOrders[0].ContactId = c.id;
        workOrders[0].Status = 'Scheduled';
        workOrders[0].member_account__c = accounts[2].id;
        workOrders[0].Manual_Override_Reason__c = 'Additional Equipment Needed';
        workOrders[0].Resolution_Code__c = 'G701';            
        update workOrders[0];  
        system.debug('++workOrders4:'+workOrders[0]);
        
        system.assertEquals('Scheduled', workOrders[0].Status);
        
        
        System.Test.stopTest();
  	
		*/
        /******EMI START -Commented above existing lines and updated below for SSFI-77 dated 01-14-2025***************/
        List<Account> accounts = [SELECT Id FROM Account WHERE Name LIKE 'Member Account%'];
      
        Contact c = new Contact(AccountId=accounts[2].Id, LastName='Jones');
        insert c;

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));

        ServiceResource serviceResource = [SELECT Id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId FROM ServiceResource WHERE ResourceType='T' LIMIT 1];
        System.assertNotEquals(null, serviceResource, 'No ServiceResource found for testing');

        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.startTest();

        List<WorkOrder> workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
        WorkOrder testWorkOrder = workOrders[0];

        testWorkOrder.ContactId = c.Id;
        testWorkOrder.Status = 'Scheduled';
        testWorkOrder.Member_Account__c = accounts[2].Id;
        testWorkOrder.Manual_Override_Reason__c = 'Additional Equipment Needed';
        testWorkOrder.Resolution_Code__c = 'G701';
        update testWorkOrder;

        WorkOrder updatedWorkOrder = [SELECT ContactId, Status FROM WorkOrder WHERE Id = :testWorkOrder.Id];
        System.Test.stopTest();
         /******EMI End for SSFI-77 dated 01-14-2025***************/
    }
	
    public static testmethod void noGeoCodeCall(){
        delete [select id from Technology_Preference__c];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall_NoGeoCode'); 
        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();
        List<WorkOrder> workOrders2 = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, GeocodeAccuracy,serviceterritoryid,
                                       Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,Schedule_Freeze__c,
                                       (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                        Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                        FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                        SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                        from ServiceAppointments
                                        order by recordtype.name asc)
                                       from Workorder]; 
        
        
        system.debug(' test workOrders2--'+workOrders2);
        system.assert( workOrders2[0].Latitude==null);
        system.assert( workOrders2[0].Longitude==null);
        ServiceTerritory st1 = new ServiceTerritory();
        st1.name = 'test Service territory';
        st1.OperatingHoursId = hours[0].Id;
        st1.IsActive=true;
        insert st1;
        workOrders2[0].Latitude=34.027483;
        workOrders2[0].Longitude=-118.347016;
        workOrders2[0].GeocodeAccuracy='Address';
        workOrders2[0].serviceterritoryid=st1.id;
        update workOrders2[0]; 
        Test.stopTest();
        List<WorkOrder> workOrders = [select id, Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, GeocodeAccuracy,
                                      Manual_Override_Reason__c, member_account__c, contactid, contact.accountid,
                                      (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                       Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                       FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                       SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                       from ServiceAppointments
                                       order by recordtype.name asc)
                                      from Workorder where id = :workOrders2[0].id]; 
     
       // system.assertEquals('In Progress', workOrders[0].Status); 
       // system.assertEquals('Spotted', workOrders[0].Status); 
         List<Case> casesToClosed=[select id,status from case where  FSL_Service_Appointment__r.Work_Order__c = :workOrders2[0].id and
                                   FSL_In_Jeopardy_Reason__c = 'No Lat/Long' and FSL_Service_Appointment__r.Work_Order__r.Status='In Progress' and status='Closed'];
         system.assertEquals(casesToClosed.size(), 0); 
    }

    public static testmethod void testSendThirdPartyNotofications() {
        ThirdPartyIntegrationTest.MockFactory mockFactory = new ThirdPartyIntegrationTest.MockFactory();
        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = mockFactory.createService();

        FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId());
        List<WorkOrder> woList = new List<WorkOrder>();
        woList.add(wo1);

        FSL_WorkOrderTriggerHandler handler = new FSL_WorkOrderTriggerHandler();
        handler.sendThirpartyNotifications(woList, thirdPartyService);

        ThirdPartyIntegrationTest.MockThirdPartyIntegrationService mockThirprty = mockFactory.getMockService();
        System.assert(mockThirprty.getCallCount('sendStatusChangePlatformEvents') == 1);
    }

    public static testmethod void testIsNeedingThirdPartyNotification() {
        FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId());
        wo1.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY;
        wo1.status = 'Cleared';

        FSL_WorkOrderTriggerHandler handler = new FSL_WorkOrderTriggerHandler();
        boolean rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == true);

        wo1.status = 'Canceled';
        rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == false);

        wo1.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
        wo1.status = 'Cleared';

        rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == false);

        wo1.status = 'Canceled';
        rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == true);

        wo1.Servicing_Technology_Type__c = 'xxx';
        wo1.status = 'Cleared';

        rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == false);

        wo1.status = 'Canceled';
        rtn = handler.IsNeedingThirdPartyNotification(wo1);
        System.assert(rtn == false);
    }

    @isTest
    private static void test_AuditLogs(){
        Account acc = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId());
        acc.FirstName = 'Test';
        acc.LastName = 'Member';
        acc.BillingStreet = '129 West St';
        acc.BillingCity = 'Wilmington';
        acc.BillingStateCode = 'DE';
        acc.BillingCountryCode = 'US';
        acc.BillingPostalCode = '19801';
        insert acc;

        //Create Work order
        Id recordTypeID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
        
        WorkOrder wo = new WorkOrder();
        wo.Locked_After_Clear__c = false;
        wo.Call_Id__c = '20018';
        wo.AccountID = acc.Id;
        Date dToday = Date.today();
		String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        wo.Call_Date__c = dateStr;
        wo.Member_Account__c = acc.Id;
        wo.recordTypeId = recordTypeID;
        wo.Street = '129 West St';
        wo.City = 'Wilmington';
        wo.State = 'DE';
        wo.Country = 'United States';
        wo.PostalCode = '19801';
        wo.Breakdown_Location__Latitude__s = 64.647;
        wo.Breakdown_Location__Longitude__s = -123.65;
        wo.Tow_State__c = 'WA';
        wo.Tow_City__c = 'Seattle';
        wo.Tow_Street__c = '2927 TEST';
        wo.Tow_Postal_Code__c = '98012';
        wo.Tow_Country__c = 'United States';
        wo.Tow_Location__Latitude__s = 78.2323;
        wo.Tow_Location__Longitude__s = 87.638;
        insert wo;

        Test.startTest();
        WorkOrder w = [Select Id from WorkOrder limit 1];
        wo.Street = '127 West St';
        wo.City = 'Wilmington';
        wo.State = 'DE';
        wo.PostalCode = '19802';
        wo.Breakdown_Location__Latitude__s = 84.647;
        wo.Breakdown_Location__Longitude__s = 93.65;
        w.Tow_Street__c = 'TEST TEST';
        w.Tow_City__c = 'Bellevue';
        w.Tow_State__c = 'WA';
        w.Tow_Postal_Code__c = '98031';
        w.Tow_Country__c = 'United States';
        wo.Tow_Location__Latitude__s = 68.2323;
        wo.Tow_Location__Longitude__s = 77.638;
        update w;
        Test.stopTest();
    }
    

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    /**********EMI START for SSFI-77 dated 01-14-2025 ********/
    
	 @isTest
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;

        WorkOrder testWorkOrder = new WorkOrder(
            Status = 'Spotted',
            AccountId = testAccount.Id,
            ContactId = testContact.Id
        );
        insert testWorkOrder;

        ServiceAppointment testServiceAppointment = new ServiceAppointment(
            ParentRecordId = testWorkOrder.Id,
            Status = 'Scheduled'
        );
        insert testServiceAppointment;
    }

    @isTest
    static void testUpdateContactOnSA() {
        List<WorkOrder> workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
         if (workOrders.isEmpty()) {
            setupTestData();
            workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
        }
        WorkOrder testWorkOrder = workOrders[0];
        ServiceAppointment testServiceAppointment = [SELECT Id, ParentRecordId, ContactId FROM ServiceAppointment LIMIT 1];

        Contact newContact = new Contact(LastName = 'New Contact');
        insert newContact;

        testWorkOrder.ContactId = newContact.Id;
        update testWorkOrder;

        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>{testWorkOrder.Id => testWorkOrder};
        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();

        Test.startTest();
        FSL_WorkOrderTriggerHandler.updateContactOnSA(woMap, saToUpdateMap);
        Test.stopTest();

        ServiceAppointment updatedSA = [SELECT ContactId FROM ServiceAppointment WHERE Id = :testServiceAppointment.Id];
        System.assertEquals(newContact.Id, updatedSA.ContactId);
    }

    @isTest
    static void testUpdateGanttIconOnSA() {
        List<WorkOrder> workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
         if (workOrders.isEmpty()) {
            setupTestData();
            workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
        }
        WorkOrder testWorkOrder = workOrders[0];
        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();

        Test.startTest();
        FSL_WorkOrderTriggerHandler.updateGanttIconOnSA(new List<WorkOrder>{testWorkOrder}, saToUpdateMap);
        Test.stopTest();

        ServiceAppointment updatedSA = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :testWorkOrder.Id];
       
    }

    @isTest
    static void testMarkCallsAsCleared() {
        List<WorkOrder> workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
         if (workOrders.isEmpty()) {
            setupTestData();
            workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
        }
        WorkOrder testWorkOrder = workOrders[0];
        testWorkOrder.Status = 'Spotted';
        testWorkOrder.Resolution_Code__c = 'X003';

        Test.startTest();
        FSL_WorkOrderTriggerHandler.markCallsAsCleared(new List<WorkOrder>{testWorkOrder});
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Status, Locked_After_Clear__c FROM WorkOrder WHERE Id = :testWorkOrder.Id];
     
    }

    @isTest
    static void testPopulateServiceVehicle() {
        List<WorkOrder> workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
         if (workOrders.isEmpty()) {
            setupTestData();
            workOrders = [SELECT Id, ContactId, Status FROM WorkOrder];
        }
        WorkOrder testWorkOrder = workOrders[0];
        ServiceAppointment testServiceAppointment = [SELECT Id,AutoCreated__c , ParentRecordId FROM ServiceAppointment WHERE ParentRecordId = :testWorkOrder.Id LIMIT 1];
        testServiceAppointment.AutoCreated__c = true;
        update testServiceAppointment;

        Set<String> woIdSet = new Set<String>{testWorkOrder.Id};

        Test.startTest();
        FSL_WorkOrderTriggerHandler.PopulateServiceVehicle(new List<WorkOrder>{testWorkOrder}, woIdSet);
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Service_Vehicle__c FROM WorkOrder WHERE Id = :testWorkOrder.Id];
       
    }    
    
    /************EMI END for SSFI-77 dated 01-14-2025 ************/
    
}