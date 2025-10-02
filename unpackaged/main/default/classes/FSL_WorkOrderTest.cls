/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 12-01-2022
 * @last modified by  : Clement Shiu
**/
@IsTest
public with sharing class FSL_WorkOrderTest {
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_WorkOrder.IFactory factory = new FSL_WorkOrder.Factory();

        Test.startTest();
        FSL_WorkOrder.IWorkOrderService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
 
    @IsTest
    public static void testFactory_CreateWorkOrders_MultipleWorkOrdersAndAssignedResourcesAndFeedItems_Created() {
        createDaoData(); // Necessary to create ServiceAppointments

        List<WorkOrder> workOrders = [SELECT Id, (SELECT Id, isBreakdown__c, Subject FROM ServiceAppointments) FROM WorkOrder];
        System.assert( !workOrders.isEmpty(), 'No WorkOrder objects were returned from the query' );
        
        Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();
        Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap = new Map<Id, List<FeedItem>>();
        for( WorkOrder wo : workOrders ) {
            workOrderIdToFeedItemsMap.put( wo.Id, new List<FeedItem>() );
        }

        FSL_WorkOrder.IFactory factory = new FSL_WorkOrder.Factory();

        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> domainWorkOrders = factory.createWorkOrders( workOrders, workOrderIdToFeedItemsMap, serviceAppointmentIdToAssignedResourceMap );
        Test.stopTest();

        System.assertEquals( workOrders.size(), domainWorkOrders.size(), 'Not all WorkOrders were created' );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData(String srvcTechType) {
        Integer recordCount = 5;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
            workOrders[i].Call_Id__c = '3333' + i;
            workOrders[i].Call_Date__c = '4444' + i;
            workOrders[i].Status = 'Spotted';
            workOrders[i].Servicing_Technology_Type__c = srvcTechType;
            workOrders[i].Vehicle_Profile__c = 'My Vehicle # ' + i;
        }
        insert workOrders;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        insert sts;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for( Integer i = 0; i < recordCount; ++i ) {
            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
            breakdownSa.ParentRecordId = workOrders[i].Id;
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
            serviceAppointments.add( breakdownSa );
            ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
            towSa.ParentRecordId = workOrders[i].Id;
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 2;
            serviceAppointments.add( towSa );
        }
        insert serviceAppointments;
    }

    private static void createDaoData() {
        createDaoData('Landline');
    }

    @IsTest
    public static void testWorkOrderDAO_FetchWorkOrdersForClearing_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_WorkOrder.IWorkOrderDAO dao = new FSL_WorkOrder.WorkOrderDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];

        System.assertEquals( 5, insertedWorkOrders.size() );
        Set<Id> workOrderIds = new Set<Id>{ insertedWorkOrders[2].Id, insertedWorkOrders[3].Id };
        
        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchWorkOrdersForClearing( workOrderIds );
        Test.stopTest();

        System.assertEquals( 2, workOrders.size() );
        System.assertEquals( insertedWorkOrders[2].Id, workOrders[0].Id );
        System.assertEquals( insertedWorkOrders[3].Id, workOrders[1].Id );
    }

    @IsTest
    public static void testWorkOrderDAO_FetchDetailedWorkOrdersByCallIdAndDate_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_WorkOrder.IWorkOrderDAO dao = new FSL_WorkOrder.WorkOrderDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id, Call_Id__c, Call_Date__c FROM WorkOrder];

        System.assertEquals( 5, insertedWorkOrders.size() );
        Set<String> callIds = new Set<String>{ insertedWorkOrders[2].Call_Id__c, insertedWorkOrders[3].Call_Id__c };
        Set<String> callDates = new Set<String>{ insertedWorkOrders[2].Call_Date__c, insertedWorkOrders[3].Call_Date__c };
        
        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchDetailedWorkOrdersByCallIdAndDate( callIds, callDates );
        Test.stopTest();

        System.assertEquals( 2, workOrders.size(), 'The amount of WorkOrders returned was not as expected' );
        System.assert( callIds.contains( workOrders[0].Call_Id__c ) && callDates.contains( workOrders[0].Call_Date__c ), 'The 1st WorkOrder does not match the criteria' );
        System.assert( callIds.contains( workOrders[1].Call_Id__c ) && callDates.contains( workOrders[1].Call_Date__c ), 'The 2nd WorkOrder does not match the criteria' );
    }

    @IsTest
    public static void testWorkOrderDAO_FetchDetailedActiveWorkOrdersByContactId_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_WorkOrder.IWorkOrderDAO dao = new FSL_WorkOrder.WorkOrderDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id, ContactId, Contact.Id, Contact.AccountId FROM WorkOrder];

        System.assertEquals( 5, insertedWorkOrders.size() );
        Set<Id> contactIds = new Set<Id>{ insertedWorkOrders[2].ContactId, insertedWorkOrders[3].ContactId };

        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell( 'Light Service', insertedWorkOrders[2].Contact );
        wo1.Status = 'Canceled';
        WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell( 'Light Service', insertedWorkOrders[3].Contact );
        wo2.Status = 'Cleared';
        insert new List<WorkOrder>{ wo1, wo2 };
        
        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchDetailedActiveWorkOrdersByContactId( contactIds );
        Test.stopTest();

        System.assertEquals( 2, workOrders.size(), 'The amount of WorkOrders returned was not as expected' );
        System.assert( contactIds.contains( workOrders[0].ContactId ) && workOrders[0].Status != 'Canceled' && workOrders[0].Status != 'Cleared', 'The 1st WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[1].ContactId ) && workOrders[1].Status != 'Canceled' && workOrders[1].Status != 'Cleared', 'The 2nd WorkOrder does not match the criteria' );
    }

    @IsTest
    public static void testWorkOrderDAO_FetchWorkOrdersForExternalIDs_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_WorkOrder.IWorkOrderDAO dao = new FSL_WorkOrder.WorkOrderDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];

        System.assertEquals( 5, insertedWorkOrders.size() );
        Set<String> extIDs = new Set<String>{ 'ERS-3' };
        
        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchWorkOrdersForExternalIDs( extIDs, true );
        Test.stopTest();

        System.assertEquals( 1, workOrders.size() );
        System.assertEquals( workOrders[0].External_Id__c, 'ERS-3' );
        System.assertEquals( workOrders[0].Vehicle_Profile__c,'My Vehicle # 3' );
        System.assertEquals( workOrders[0].Servicing_Technology_Type__c, 'Landline' );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testWorkOrderService_GetWorkOrdersForClearing_DAOCalled() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        WorkOrder w1 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder w2 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder w3 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder w4 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder w5 = new WorkOrder( Id = dao.Builder.getMockId() );
        dao.workOrders.put( w1.Id, w1 );
        dao.workOrders.put( w2.Id, w2 );
        dao.workOrders.put( w3.Id, w3 );
        dao.workOrders.put( w4.Id, w4 );
        dao.workOrders.put( w5.Id, w5 );
        Set<Id> workOrderIds = new Set<Id>{ w2.Id, w3.Id };

        Test.startTest();
        List<WorkOrder> workOrders = service.getWorkOrdersForClearing( workOrderIds );
        Test.stopTest();

        System.assertEquals( 2, workOrders.size() );
        System.assertEquals( w2, workOrders[0] );
        System.assertEquals( w3, workOrders[1] );
    }

    @IsTest
    public static void testWorkOrderService_GetWorkOrdersByCallIdAndCallDate_MultipleCallIdAndCallDatePairs_DomainWorkOrdersCreated() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 3' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        Set<String> callIds = new Set<String>{ 'Call Id 1', 'Call Id 3' };
        Set<String> callDates = new Set<String>{ 'Call Date 1', 'Call Date 3' };
        List<FSL_WorkOrder.CallIdAndCallDatePair> criteria = new List<FSL_WorkOrder.CallIdAndCallDatePair>{ new FSL_WorkOrder.CallIdAndCallDatePair(), new FSL_WorkOrder.CallIdAndCallDatePair() };
        criteria[0].callId = 'Call Id 1';
        criteria[0].callDate = 'Call Date 1';
        criteria[1].callId = 'Call Id 3';
        criteria[1].callDate = 'Call Date 3';

        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();

        System.assertEquals( 0, feedItemService.getWorkOrderIdToFeedItemsMapCallCount, 'FeedItemService.getWorkOrderIdToFeedItemsMap has been called' );
        System.assertEquals( 0, assignedResourceService.getServiceAppointmentIdToAssignedResourceMapCallCount, 'AssignedResourceService.getServiceAppointmentIdToAssignedResourceMap has been called' );

        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> domainWorkOrders = service.getWorkOrdersByCallIdAndCallDate( criteria, assignedResourceService, feedItemService );
        Test.stopTest();

        System.assertNotEquals( null, domainWorkOrders, 'Null was returned' );
        System.assertEquals( 2, domainWorkOrders.size(), 'The amount of domain work orders was not as expected' );
        System.assertEquals( 1, feedItemService.getWorkOrderIdToFeedItemsMapCallCount, 'FeedItemService.getWorkOrderIdToFeedItemsMap has not been called' );
        System.assertEquals( 1, assignedResourceService.getServiceAppointmentIdToAssignedResourceMapCallCount, 'AssignedResourceService.getServiceAppointmentIdToAssignedResourceMap has not been called' );
    }

    @IsTest
    public static void testWorkOrderService_GetActiveWorkOrdersByContactId_MultipleContactIds_DomainWorkOrdersCreated() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        Id contactId1 = dao.Builder.getMockId( Contact.getSObjectType() );
        Id contactId2 = dao.Builder.getMockId( Contact.getSObjectType() );
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Dispatched' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId2, Status = 'Dispatched' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId2 };

        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();

        System.assertEquals( 0, feedItemService.getWorkOrderIdToFeedItemsMapCallCount, 'FeedItemService.getWorkOrderIdToFeedItemsMap has been called' );
        System.assertEquals( 0, assignedResourceService.getServiceAppointmentIdToAssignedResourceMapCallCount, 'AssignedResourceService.getServiceAppointmentIdToAssignedResourceMap has been called' );

        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> domainWorkOrders = service.getActiveWorkOrdersByContactId( contactIds, assignedResourceService, feedItemService );
        Test.stopTest();

        System.assertNotEquals( null, domainWorkOrders, 'Null was returned' );
        System.assertEquals( 2, domainWorkOrders.size(), 'The amount of domain work orders was not as expected' );
        System.assertEquals( 1, feedItemService.getWorkOrderIdToFeedItemsMapCallCount, 'FeedItemService.getWorkOrderIdToFeedItemsMap has not been called' );
        System.assertEquals( 1, assignedResourceService.getServiceAppointmentIdToAssignedResourceMapCallCount, 'AssignedResourceService.getServiceAppointmentIdToAssignedResourceMap has not been called' );
    }

    @IsTest
    public static void testWorkOrderService_OnBeforeUpdate_ContactIdChanged_MemberAccountUpdatedWithRelatedId() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        
        Contact oldContact1 = new Contact( Id = dao.Builder.getMockId( Schema.Contact.getSObjectType() ), AccountId = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        Contact newContact1 = new Contact( Id = dao.Builder.getMockId( Schema.Contact.getSObjectType() ), AccountId = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        Contact oldContact2 = new Contact( Id = dao.Builder.getMockId( Schema.Contact.getSObjectType() ), AccountId = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        Contact newContact2 = new Contact( Id = dao.Builder.getMockId( Schema.Contact.getSObjectType() ), AccountId = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );

        WorkOrder oldWorkOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = oldContact1.Id, Member_Account__c = oldContact1.AccountId, Status = 'Cleared' );
        WorkOrder newWorkOrder1 = new WorkOrder( Id = oldWorkOrder1.Id, ContactId = newContact1.Id, Member_Account__c = oldContact1.AccountId );
        WorkOrder oldWorkOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = oldContact2.Id, Member_Account__c = oldContact2.AccountId );
        WorkOrder newWorkOrder2 = new WorkOrder( Id = oldWorkOrder2.Id, ContactId = newContact2.Id, Member_Account__c = oldContact2.AccountId );
        
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{ oldWorkOrder1.Id => oldWorkOrder1, oldWorkOrder2.Id => oldWorkOrder2 };
        Map<Id, WorkOrder> newMap = new Map<Id, WorkOrder>{ newWorkOrder1.Id => newWorkOrder1, newWorkOrder2.Id => newWorkOrder2 };
        FSL_ContactTest.ContactServiceMock contactService = new FSL_ContactTest.ContactServiceMock();
        contactService.getContactsByIdReturnValue = new List<Contact>{ newContact1, newContact2 };

        Test.startTest();
        service.onBeforeUpdate( oldMap, newMap, contactService );
        Test.stopTest();

        System.assertEquals( newContact1.AccountId, newWorkOrder1.Member_Account__c );
        System.assertEquals( newContact2.AccountId, newWorkOrder2.Member_Account__c );
    }

    @IsTest
    public static void testWorkOrderService_ResetLockedAfterClearFlag_WONotCleared_LockAfterClearUnchanged() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder oldWorkOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Status = 'Scheduled', Locked_After_Clear__c = true);
        WorkOrder newWorkOrder1 = new WorkOrder( Id = oldWorkOrder1.Id,  Status = 'Dispatched', Locked_After_Clear__c = true);
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{ oldWorkOrder1.Id => oldWorkOrder1};
        Map<Id, WorkOrder> newMap = new Map<Id, WorkOrder>{ newWorkOrder1.Id => newWorkOrder1};


        FSL_ApplicationLogTest.ApplicationLogServiceMock logServiceMock = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.WorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao, logServiceMock );      
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, true);
        Test.startTest();
        service.resetLockedAfterClearFlag(oldMap, newMap);
        Test.stopTest();
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, true);
    }

    @IsTest
    public static void testWorkOrderService_ResetLockedAfterClearFlag_WOAlreadyCleared_LockAfterClearUnchanged() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder oldWorkOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Status = 'Cleared', Locked_After_Clear__c = false);
        WorkOrder newWorkOrder1 = new WorkOrder( Id = oldWorkOrder1.Id,  Status = 'Cleared', Locked_After_Clear__c = false);
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{ oldWorkOrder1.Id => oldWorkOrder1};
        Map<Id, WorkOrder> newMap = new Map<Id, WorkOrder>{ newWorkOrder1.Id => newWorkOrder1};


        FSL_ApplicationLogTest.ApplicationLogServiceMock logServiceMock = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.WorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao, logServiceMock );      
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, false);
        Test.startTest();
        service.resetLockedAfterClearFlag(oldMap, newMap);
        Test.stopTest();
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, false);
    }

    @IsTest
    public static void testWorkOrderService_ResetLockedAfterClearFlag_WOCleared_LockAfterClearFalse() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder oldWorkOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Status = 'Dispatched', Locked_After_Clear__c = true);
        WorkOrder newWorkOrder1 = new WorkOrder( Id = oldWorkOrder1.Id, Status = 'Cleared', Locked_After_Clear__c = true);
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{ oldWorkOrder1.Id => oldWorkOrder1};
        Map<Id, WorkOrder> newMap = new Map<Id, WorkOrder>{ newWorkOrder1.Id => newWorkOrder1};

        FSL_ApplicationLogTest.ApplicationLogServiceMock logServiceMock = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.WorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao, logServiceMock );      
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, true);
        Test.startTest();
        service.resetLockedAfterClearFlag(oldMap, newMap);
        Test.stopTest();
        System.assertEquals(newWorkOrder1.Locked_After_Clear__c, false);
    }


    @IsTest
    public static void testWorkOrderService_ProcessUpdateWorkOrderRequest_WorkOrderFound_WorkOrderUpdated() {
   
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

        ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        saList.add(sa1);
        serviceAppointmentServiceMock.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = saList;

        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  updateReq = constructWorkOrderUpdateRequest('Update', wo1.External_Id__c);
        Set <String> updatedWONumbers = workOrderService.processWorkOrderUpdateRequest(updateReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
       
        System.assertEquals(1, callCommentsServiceMock.saveWorkOrderCommentsCallCount);
        System.assertEquals(1, serviceAppointmentServiceMock.saveD3SyncStatusOfServiceAppointmentChildrenCalLCount);
        System.assertEquals(1, updatedWONumbers.size());
    
        Test.stopTest();
    }
    
    @IsTest
    public static void testWorkOrderService_ProcessUpdateWorkOrderRequest_ForcedFailure_UpdateWorkOrderExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );
     
        ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        saList.add(sa1);
        serviceAppointmentServiceMock.throwsException = true;

        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  updateReq = constructWorkOrderUpdateRequest('Update', wo1.External_Id__c);
        try 
        {
            Set <String> cancelledWONumbers = workOrderService.processWorkOrderUpdateRequest(updateReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
            System.assert(false);
        }
        catch (FSL_WorkOrder.UpdateWorkOrderException ex)
        {
        }
        Test.stopTest();
    }

    @IsTest
    public static void testWorkOrderService_ProcessCancelWorkOrderRequest_RegularCall_WorkOrderCancelled() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

        ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        saList.add(sa1);
        serviceAppointmentServiceMock.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = saList;


        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', wo1.External_Id__c);

        Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
        
        // Modified the test to just make sure that the FSL_WorkOrder service calls the method on the IServiceAppointment interface
        System.assertEquals(1, dao.updateRecordsCallCount, 'Expect One call to WorkOrderDao to update Records');
        System.assertEquals(1, serviceAppointmentServiceMock.processCancelServiceAppoinmentsCallCount, 'One call to saService.processCancelServiceAppoinments');
 
        Test.stopTest();
    }

    @IsTest
    public static void testWorkOrderService_ProcessCancelWorkOrderRequest_NoMatchingWorkOrders_ExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', '000-0000000-000000');
        try 
        {
            Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
            System.assert(false);
        }
        catch (FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException ex)
        {
        }
        Test.stopTest();
    }

    @IsTest
    public static void testWorkOrderService_ProcessCancelWorkOrderRequest_SetupDMLException_DMLExceptionCaught() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        // Set up the DML Exception
        dao.throwDMLExceptionOnWrite = true;

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

        ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        saList.add(sa1);
        serviceAppointmentServiceMock.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = saList;


        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', wo1.External_Id__c);

        try
        {
           Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
           System.assert(false);
        }
        catch (FSL_WorkOrder.UpdateWorkOrderDMLException ex){
        }
        Test.stopTest();
    }

    @IsTest
    public static void testWorkOrderService_ProcessCancelWorkOrderRequest_GeneralFailure_UpdateWorkOrderExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
        dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );
        ServiceAppointmentServiceMock.throwsException = true;

        Test.startTest();
        FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', wo1.External_Id__c);
        try 
        {
            Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock);
            System.assert(false);
        }
        catch (FSL_WorkOrder.UpdateWorkOrderException ex)
        {
        }
        Test.stopTest();
    }

    // @IsTest
    // public static void testWorkOrderService_ProcessCancelWorkOrderRequest_DispatchedLandLineCall_WorkOrderCancelledAndCaseCreated() {
    //     WorkOrderDAOMock dao = new WorkOrderDAOMock();
    //     FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
    //     FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
    //     FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();
    //     FSL_CaseTest.CaseServiceMock caseServiceMock = new FSL_CaseTest.CaseServiceMock();

    //     WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '013-0210621-111111' );
    //     wo1.Servicing_Technology_Type__c = 'Landline';
    //     wo1.Status = 'Dispatched';
    //     dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

    //     ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
    //     List<ServiceAppointment> saList = new List<ServiceAppointment>();
    //     saList.add(sa1);
    //     serviceAppointmentServiceMock.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = saList;

    //     Test.startTest();
    //     FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', wo1.External_Id__c);
      
    //     Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock, caseServiceMock);
    //     System.assertEquals(1, caseServiceMock.openLandLineCallCanceledCaseCallCount);
    //     System.assertEquals(1, callCommentsServiceMock.saveWorkOrderCommentsCallCount);           

    //     Test.stopTest();

    // }

    // @IsTest
    // public static void testWorkOrderService_ProcessCancelWorkOrderRequest_SpottedLandLineCall_WorkOrderCancelledButCaseNotCreated() {
    //     WorkOrderDAOMock dao = new WorkOrderDAOMock();
    //     FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService( dao );
    //     FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
    //     FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();
    //     FSL_CaseTest.CaseServiceMock caseServiceMock = new FSL_CaseTest.CaseServiceMock();

    //     WorkOrder wo1 =  new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = '016-20210621-222222' );
    //     wo1.Servicing_Technology_Type__c = 'Landline';
    //     wo1.Status = 'Spotted';
    //     dao.extIDtoWorkOrder.put( wo1.External_Id__c, wo1 );

    //     ServiceAppointment sa1 = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo1.Id );
    //     List<ServiceAppointment> saList = new List<ServiceAppointment>();
    //     saList.add(sa1);
    //     serviceAppointmentServiceMock.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = saList;

    //     Test.startTest();
    //     FSL_WorkOrder.UpdateRequestWrapper  cancelReq = constructWorkOrderUpdateRequest('Cancel', wo1.External_Id__c);
  
    //     Set <String> cancelledWONumbers = workOrderService.processWorkOrderCancelRequest(cancelReq, serviceAppointmentServiceMock, calLCommentsServiceMock, caseServiceMock);
    //     System.assertEquals(0, caseServiceMock.openLandLineCallCanceledCaseCallCount);
    //     System.assertEquals(1, callCommentsServiceMock.saveWorkOrderCommentsCallCount);           
  
    //     Test.stopTest();

    // }

    private static FSL_WorkOrder.UpdateRequestWrapper constructWorkOrderUpdateRequest(String subType, String extId) {

        FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest  woUpdRequest = new  FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest();

        woUpdRequest.id = '12345';
        woUpdRequest.subType = subType;
        woUpdRequest.version = '1.0';

        FSL_D3ToFSLRequest.FSL_WOReq_CallEvent callEvent = new FSL_D3ToFSLRequest.FSL_WOReq_CallEvent();
        woUpdRequest.callEvents = new List<FSL_D3ToFSLRequest.FSL_WOReq_CallEvent>();
        woUpdRequest.callEvents.add(callEvent);

        callEvent.callId = '123456';
        callEvent.callKey = extId;

        FSL_D3ToFSLRequest.FSL_WOReq_Comment callComment = new FSL_D3ToFSLRequest.FSL_WOReq_Comment();
        callEvent.comments = new List<FSL_D3ToFSLRequest.FSL_WOReq_Comment>();
        callEvent.comments.add(callComment);

        callComment.text = 'This is the comment from a WorkOrder ' + subType + ' request';

        FSL_WorkOrder.UpdateRequestWrapper   updateRequestWrapper = new  FSL_WorkOrder.UpdateRequestWrapper();
            
        updateRequestWrapper.externalIDs = woUpdRequest.extractWorkOrderExternalIDsInRequest();
        updateRequestWrapper.workOrderComments = woUpdRequest.extractComments();

        return updateRequestWrapper;
    }


    @IsTest
    public static void testWorkOrderService_LockWorkOrdersAndPrepareToClear_NoCallsToClear_NoException() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();

        dao.returnValueForFetchWorkOrderConfiguration = new List <FSL_WorkOrder_Configuration__mdt>();
        FSL_WorkOrder_Configuration__mdt config = new FSL_WorkOrder_Configuration__mdt();
        config.Editable_Window_After_Clear_Minutes__c = 2;
        dao.returnValueForFetchWorkOrderConfiguration.add(config);

        dao.returnValueForFetchWorkOrdersNotYetCleared = new List<WorkOrder>();
        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLogTest.FactoryMock().createService();

        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock  clearQueueService= new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ServiceLineItemTest.ServiceLineItemServiceMock slIService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        workOrderService.lockWorkOrdersAndPrepareToClear(clearQueueService, sliService);

        System.assertEquals(clearQueueService.addWorkOrdersToQueueCallCount, 0);
        System.assertEquals(slIService.deleteTowServiceLineItemsForWorkOrdersCallCount, 0);

    }

    @IsTest
    public static void testWorkOrderService_LockWorkOrdersAndPrepareToClear_SomeCallsToClear_NoException() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();

        dao.returnValueForFetchWorkOrdersNotYetCleared = new List<WorkOrder>();
        dao.returnValueForFetchWorkOrderConfiguration = new List <FSL_WorkOrder_Configuration__mdt>();
        FSL_WorkOrder_Configuration__mdt config = new FSL_WorkOrder_Configuration__mdt();
        config.Editable_Window_After_Clear_Minutes__c = 2;
        dao.returnValueForFetchWorkOrderConfiguration.add(config);

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId());
        wo1.Resolution_Code__c = 'X001';
        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo1);

        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLogTest.FactoryMock().createService();

        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock  clearQueueService= new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ServiceLineItemTest.ServiceLineItemServiceMock slIService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        workOrderService.lockWorkOrdersAndPrepareToClear(clearQueueService, sliService);

        System.assertEquals(clearQueueService.addWorkOrdersToQueueCallCount, 1);
        System.assertEquals(slIService.deleteTowServiceLineItemsForWorkOrdersCallCount, 1);
    }

    @IsTest
    public static void testWorkOrderService_LockWorkOrdersAndPrepareToClear_PartialSuccess_NoException() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();

        dao.returnValueForFetchWorkOrdersNotYetCleared = new List<WorkOrder>();
        dao.returnValueForFetchWorkOrderConfiguration = new List <FSL_WorkOrder_Configuration__mdt>();
        FSL_WorkOrder_Configuration__mdt config = new FSL_WorkOrder_Configuration__mdt();
        config.Editable_Window_After_Clear_Minutes__c = 2;
        dao.returnValueForFetchWorkOrderConfiguration.add(config);

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId());
        wo1.Resolution_Code__c = 'X001';
        WorkOrder wo2 = new WorkOrder( Id = dao.Builder.getMockId());
        wo2.Resolution_Code__c = 'X001';
        WorkOrder wo3 = new WorkOrder( Id = dao.Builder.getMockId());
        wo2.Resolution_Code__c = 'X001';

        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo1);
        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo2);
        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo3);

        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLogTest.FactoryMock().createService();

        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock  clearQueueService= new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ServiceLineItemTest.ServiceLineItemServiceMock slIService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

       
        clearQueueService.partialSuccessOnAddToQueue = true;
        workOrderService.lockWorkOrdersAndPrepareToClear(clearQueueService, sliService);

        System.assertEquals(clearQueueService.addWorkOrdersToQueueCallCount, 1);
        System.assertEquals(slIService.deleteTowServiceLineItemsForWorkOrdersCallCount, 1);

    }

    @IsTest
    public static void testWorkOrderService_LockWorkOrdersAndPrepareToClear_BlankResolutionCode_NoException() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();

        dao.returnValueForFetchWorkOrdersNotYetCleared = new List<WorkOrder>();
        dao.returnValueForFetchWorkOrderConfiguration = new List <FSL_WorkOrder_Configuration__mdt>();
        FSL_WorkOrder_Configuration__mdt config = new FSL_WorkOrder_Configuration__mdt();
        config.Editable_Window_After_Clear_Minutes__c = 2;
        dao.returnValueForFetchWorkOrderConfiguration.add(config);

        WorkOrder wo1 = new WorkOrder( Id = dao.Builder.getMockId());
        wo1.Resolution_Code__c = null;

        WorkOrder wo2 = new WorkOrder( Id = dao.Builder.getMockId());
        wo2.Resolution_Code__c = '';
        
        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo1);
        dao.returnValueForFetchWorkOrdersNotYetCleared.add(wo2);

        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLogTest.FactoryMock().createService();

        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock  clearQueueService= new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ServiceLineItemTest.ServiceLineItemServiceMock slIService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        Exception caughtEx = null;

        try {
            workOrderService.lockWorkOrdersAndPrepareToClear(clearQueueService, sliService);
        }
        catch (Exception ex) {
            caughtEx = ex;
        }

        System.assertEquals(clearQueueService.addWorkOrdersToQueueCallCount, 1);
        System.assertEquals(caughtEx, null);
    }



    @IsTest
    public static void testWorkOrderService_LockWorkOrdersAndPrepareToClear_ExceptionSet_ExceptionHandled() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        dao.returnValueForFetchWorkOrderConfiguration = null;

        FSL_ApplicationLogTest.ApplicationLogServiceMock logService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock  clearQueueService= new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ServiceLineItemTest.ServiceLineItemServiceMock slIService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        try {
            workOrderService.lockWorkOrdersAndPrepareToClear(clearQueueService, sliService);
        }
        catch (Exception ex) {
            System.assertEquals(null, ex);
        }
        System.assertEquals(logService.saveApplicationLogsCallCount, 1);
    }

    private static RestApi_PatchCall.PatchCallRequest constructPatchCallRequest(String callKey) {
        RestApi_PatchCall.PatchCallRequest patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = callKey;
        patchCallRequest.roadsideAssistanceDetail.add(new RestApi_PatchCall.RoadsideAssistanceDetail());
        RestApi_PatchCall.RoadsideAssistanceDetail rsDetail = patchCallRequest.roadsideAssistanceDetail.get(0);
        rsDetail.resolutionCode = 'G105';
        rsDetail.reasonCode = '123';
        rsDetail.driverData = new RestApi_PatchCall.DriverData();
        rsDetail.driverData.servicingStationEmployeeName = 'JohnDoe';
        rsDetail.driverData.servicingStationEmployeeId = '124';
        rsDetail.driverData.truckId = '124';
        rsDetail.driverData.dispatchTime = '30';
        rsDetail.driverData.latitude = 80.5;
        rsDetail.driverData.longitude = -81.5;

        patchCallRequest.serviceStatus =  new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = '30';

        return patchCallRequest;
    }

    private static ThirdPartyIntegration.IntegrationSupportServicesWrapper  constructMockIntegrationWrapper() {
       
        ThirdPartyIntegration.IntegrationSupportServicesWrapper mockIntegrationWrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
        mockIntegrationWrapper.contactService = new FSL_ContactTest.ContactServiceMock();
        mockIntegrationWrapper.serviceAppointmentService = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        mockIntegrationWrapper.serviceLineItemService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        return mockIntegrationWrapper;
    }

    @IsTest
    public static void testWorkOrderService_ProcessThirdPartyUpdateRequest_AllStatus_Success() {

        Test.startTest();
        createDaoData(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK);

      
        ThirdPartyIntegration.IntegrationSupportServicesWrapper mockIntegrationWrapper = constructMockIntegrationWrapper();
        List<WorkOrder> workOrders = [SELECT Id, External_Id__c, (SELECT Id, isBreakdown__c, Subject FROM ServiceAppointments) FROM WorkOrder];
        RestApi_PatchCall.PatchCallRequest patchCallRequest = constructPatchCallRequest(workOrders.get(0)?.External_Id__c);
        patchCallRequest.callInfo.status = 'Spotted';

        FSL_ApplicationLogTest.ApplicationLogServiceMock mockLogService =  new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
        List<WorkOrder> listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, mockIntegrationWrapper);

        patchCallRequest.callInfo.status = 'Scheduled';
        listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, mockIntegrationWrapper);
        
        patchCallRequest.callInfo.status = 'Dispatched';
        listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, mockIntegrationWrapper);

        Test.stopTest();
    }

    // *********************************************
    // * Domain
    // *********************************************
    @IsTest
    public static void testWorkOrder_GetWorkOrder_InjectedInConstructor_SameValue() {
        WorkOrder wo = new WorkOrder();
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, null );

        System.assertEquals( wo, workOrder.getWorkOrder() );
    }

    @IsTest
    public static void testWorkOrder_GetFeedItems_InjectedInConstructor_SameValue() {
        WorkOrder wo = new WorkOrder();
        List<FeedItem> feedItems = new List<FeedItem>{ new FeedItem() };
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, feedItems, null );

        System.assertEquals( feedItems, workOrder.getFeedItems() );
    }

    @IsTest
    public static void testWorkOrder_GetServiceAppointments_InjectedInConstructor_SameValue() {
        WorkOrder wo = new WorkOrder();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>{ new FSL_ServiceAppointmentTest.ServiceAppointmentMock() };
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, serviceAppointments );

        System.assertEquals( serviceAppointments, workOrder.getServiceAppointments() );
    }

    @IsTest
    public static void testWorkOrder_GetBreakdownServiceAppointment_BreakdownAndTowInjectedInConstructor_Breakdown() {
        WorkOrder wo = new WorkOrder();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>();
        serviceAppointments.add( new FSL_ServiceAppointment.BreakdownServiceAppointment( null, null ) );
        serviceAppointments.add( new FSL_ServiceAppointment.TowServiceAppointment( null, null ) );
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, serviceAppointments );

        System.assertEquals( serviceAppointments[0], workOrder.getBreakdownServiceAppointment() );
    }

    @IsTest
    public static void testWorkOrder_GetBreakdownServiceAppointment_NoServiceAppointmentsInjectedInConstructor_null() {
        WorkOrder wo = new WorkOrder();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>();
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, serviceAppointments );

        System.assertEquals( null, workOrder.getBreakdownServiceAppointment() );
    }
    
    @IsTest
    public static void testWorkOrder_GetTowServiceAppointment_BreakdownAndTowInjectedInConstructor_Tow() {
        WorkOrder wo = new WorkOrder();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>();
        serviceAppointments.add( new FSL_ServiceAppointment.BreakdownServiceAppointment( null, null ) );
        serviceAppointments.add( new FSL_ServiceAppointment.TowServiceAppointment( null, null ) );
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, serviceAppointments );

        System.assertEquals( serviceAppointments[1], workOrder.getTowServiceAppointment() );
    }  

    public static void testWorkOrder_GetTowServiceAppointment_BreakdownInjectedInConstructor_Null() {
        WorkOrder wo = new WorkOrder();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>();
        serviceAppointments.add( new FSL_ServiceAppointment.BreakdownServiceAppointment( null, null ) );
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, serviceAppointments );
        System.assertEquals( null, workOrder.getTowServiceAppointment() );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsSpotted_SpottedTimeStamp() {
        String status = 'Spotted';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = spottedTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsScheduled_ScheduledTimeStamp() {
        String status = 'Scheduled';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = scheduledTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsDispatched_DispatchedTimeStamp() {
        String status = 'Dispatched';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = dispatchedTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsEnRoute_EnRouteTimeStamp() {
        String status = 'En Route';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = enrouteTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsOnLocation_OnLocationTimeStamp() {
        String status = 'On Location';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = onLocationTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsInTow_InTowTimeStamp() {
        String status = 'In Tow';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = inTowTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsCleared_ClearedTimeStamp() {
        String status = 'Cleared';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = clearedTimestamp;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }
    
    @IsTest
    public static void testWorkOrder_GetStatusTimestamp_StatusIsCanceled_Null() {
        String status = 'Canceled';
        Datetime spottedTimestamp = Datetime.now().addMinutes( -10 );
        Datetime scheduledTimestamp = Datetime.now().addMinutes( -9 );
        Datetime dispatchedTimestamp = Datetime.now().addMinutes( -8 );
        Datetime enrouteTimestamp = Datetime.now().addMinutes( -7 );
        Datetime onLocationTimestamp = Datetime.now().addMinutes( -6 );
        Datetime inTowTimestamp = Datetime.now().addMinutes( -5 );
        Datetime clearedTimestamp = Datetime.now().addMinutes( -4 );

        Datetime expected = null;

        testWorkOrder_GetStatusTimestamp( status, spottedTimestamp, scheduledTimestamp, dispatchedTimestamp, enrouteTimestamp, onLocationTimestamp, inTowTimestamp, clearedTimestamp, expected );
    }

    private static void testWorkOrder_GetStatusTimestamp( String status, Datetime spottedTimestamp, Datetime scheduledTimestamp, Datetime dispatchedTimestamp, Datetime enrouteTimestamp, Datetime onLocationTimestamp, Datetime inTowTimestamp, Datetime clearedTimestamp, Datetime expected ) {
        WorkOrder wo = new WorkOrder();
        wo.Status = status;
        wo.Spotted_Timestamp__c = spottedTimestamp;
        wo.Scheduled_Timestamp__c = scheduledTimestamp;
        wo.Dispatched_Timestamp__c = dispatchedTimestamp;
        wo.Enroute_Timestamp__c = enrouteTimestamp;
        wo.On_Location_Timestamp__c = onLocationTimestamp;
        wo.In_Tow_Timestamp__c = inTowTimestamp;
        wo.Cleared_Timestamp__c = clearedTimestamp;
        FSL_WorkOrder.WorkOrder workOrder = new FSL_WorkOrder.WorkOrder( wo, null, null );

        System.assertEquals( expected, workOrder.getStatusTimestamp() );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_WorkOrder.IFactory {
        public FSL_WorkOrder.IWorkOrderService createService() {
            return new WorkOrderServiceMock();
        }

        public List<FSL_WorkOrder.WorkOrder> createWorkOrders( List<Schema.WorkOrder> workOrders, Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap ) {
            return new List<FSL_WorkOrder.WorkOrder>();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FSL_WorkOrder.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_WorkOrder.IWorkOrderService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactoryMock_CreateWorkOrders_EmptyList() {
        FSL_WorkOrder.IFactory factory = new FactoryMock();

        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> workOrders = factory.createWorkOrders( null, null, null );
        Test.stopTest();

        System.assertNotEquals( null, workOrders, 'WorkOrders is null' );
        System.assert( workOrders.isEmpty(), 'WorkOrders is not empty' );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType WORKORDER_TYPE = Schema.WorkOrder.getSObjectType();
    public class WorkOrderDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_WorkOrder.IWorkOrderDAO {
        public Map<Id, WorkOrder> workOrders;
        public Map<String, WorkOrder> extIDtoWorkOrder;
        public Boolean isSuccess = true;
        public Boolean throwDMLExceptionOnWrite = false;
        public List<WorkOrder> returnValueForFetchWorkOrdersNotYetCleared;
        public List <FSL_WorkOrder_Configuration__mdt> returnValueForFetchWorkOrderConfiguration;


        public WorkOrderDAOMock() {
            super( new Map<Id, WorkOrder>(), WORKORDER_TYPE );
            this.workOrders = (Map<Id, WorkOrder>)super.Records;

            this.extIDtoWorkOrder = new Map<String, WorkOrder>();
        }

        public Integer updateRecordsCallCount = 0;
        public override void updateRecords(List<SObject> woList) {
            if ( throwDMLExceptionOnWrite) {
                throw new DmlException ('Unable to update WorkOrder Records');
            }
            else {
                updateRecordsCallCount++;
                super.updateRecords(woList);
            }
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from WorkOrderDAOMock' );
            }
        }

        public List<WorkOrder> fetchDetailedWorkOrdersByCallIdAndDate( Set<String> callIds, Set<String> callDates ) {
            isQueryException();
            List<WorkOrder> result = new List<WorkOrder>();
            for( WorkOrder workOrder : workOrders.values() ) {
                if( callIds.contains( workOrder.Call_Id__c ) && callDates.contains( workOrder.Call_Date__c ) ) {
                    result.add( workOrder );
                }
            }
            return result;
        }

        public List<Schema.WorkOrder> fetchDetailedActiveWorkOrdersByContactId( Set<Id> contactIds ) {
            isQueryException();
            List<WorkOrder> result = new List<WorkOrder>();
            for( WorkOrder workOrder : workOrders.values() ) {
                if( contactIds.contains( workOrder.ContactId ) && workOrder.Status != 'Canceled' && workOrder.Status != 'Cleared' ) {
                    result.add( workOrder );
                }
            }
            return result;
        }

        public List<WorkOrder> fetchWorkOrdersForClearing( Set<Id> workOrderIds ) {
            isQueryException();
            List<WorkOrder> result = new List<WorkOrder>();
            for( Id workOrderId : workOrderIds ) {
                result.add( workOrders.get( workOrderId ) );
            }
            return result;
        }

        public List<WorkOrder> fetchWorkOrdersForExternalIds ( Set<String> extIDs, Boolean lockOption) {
            isQueryException();
            List<WorkOrder> returnValue = new List<WorkOrder>();
            
            WorkOrder wo;
            for( String extId: extIDs ) {
                wo = extIDtoWorkOrder.get( extId );
                if ( wo != null) {
                    returnValue.add(wo);
                }
            }
            return returnValue;
        }

        public List<WorkOrder> fetchWorkOrdersByIds (Set<Id> workOrderIds) {
            isQueryException();
            List<WorkOrder> result = new List<WorkOrder>();
            for( Id workOrderId : workOrderIds ) {
                result.add( workOrders.get( workOrderId ) );
            }
            return result;
        }

        public List<WorkOrder> fetchAllReadOnlyWorkOrdersNotYetCleared (DateTime cutOff,Integer lmt) {
            isQueryException();
            
            for( WorkOrder workOrder : workOrders.values() ) {
            returnValueForFetchWorkOrdersNotYetCleared.add(workOrder);
            }
   
           return returnValueForFetchWorkOrdersNotYetCleared;
        }
        
        public FSL_WorkOrder.EODBean getWorkOrdersToSentToBackOfficeEOD() {
            isQueryException();
           return null;
        }

        public List <FSL_WorkOrder_Configuration__mdt>  fetchWorkOrderConfiguration() {
            isQueryException();
   
            return returnValueForFetchWorkOrderConfiguration;           
        }

        public FSL_WorkOrder.EODBean fetchAllWorkOrdersNotYetSentToBackOfficeEOD(DateTime cutOff){
            return null ; 
        }
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchWorkOrdersForClearing_CorrectNumberOfRecordsReturned() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId() );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId() );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        Set<Id> workOrderIds = new Set<Id>{ workOrder1.Id, workOrder2.Id };

        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchWorkOrdersForClearing( workOrderIds );
        Test.stopTest();

        System.assertEquals( 2, workOrders.size() );
        System.assertEquals( workOrder1, workOrders[0] );
        System.assertEquals( workOrder2, workOrders[1] );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchWorkOrdersForClearing_IsException_ExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        Id workOrderId = dao.Builder.getMockId();
        WorkOrder workOrder = new WorkOrder( Id = workOrderId );
        dao.workOrders.put( workOrder.Id, workOrder );
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<WorkOrder> workOrders = dao.fetchWorkOrdersForClearing( new Set<Id> { workOrderId } );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchDetailedWorkOrdersByCallIdAndDate_CorrectNumberOfRecordsReturned() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 3' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        Set<String> callIds = new Set<String>{ 'Call Id 1', 'Call Id 3' };
        Set<String> callDates = new Set<String>{ 'Call Date 1', 'Call Date 3' };

        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchDetailedWorkOrdersByCallIdAndDate( callIds, callDates );
        Test.stopTest();

        System.assertEquals( 4, workOrders.size(), 'The amount of WorkOrders returned is not as expected' );
        System.assert( callIds.contains( workOrders[0].Call_Id__c ) && callDates.contains( workOrders[0].Call_Date__c ), 'The 1st WorkOrder does not match the criteria' );
        System.assert( callIds.contains( workOrders[1].Call_Id__c ) && callDates.contains( workOrders[1].Call_Date__c ), 'The 2nd WorkOrder does not match the criteria' );
        System.assert( callIds.contains( workOrders[2].Call_Id__c ) && callDates.contains( workOrders[2].Call_Date__c ), 'The 3rd WorkOrder does not match the criteria' );
        System.assert( callIds.contains( workOrders[3].Call_Id__c ) && callDates.contains( workOrders[3].Call_Date__c ), 'The 4th WorkOrder does not match the criteria' );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchDetailedWorkOrdersByCallIdAndDate_IsException_ExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 3' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        Set<String> callIds = new Set<String>{ 'Call Id 1', 'Call Id 3' };
        Set<String> callDates = new Set<String>{ 'Call Date 1', 'Call Date 3' };
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<WorkOrder> workOrders = dao.fetchDetailedWorkOrdersByCallIdAndDate( callIds, callDates );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchDetailedActiveWorkOrdersByContactId_CorrectNumberOfRecordsReturned() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        Id contactId1 = dao.Builder.getMockId( Contact.getSObjectType() );
        Id contactId2 = dao.Builder.getMockId( Contact.getSObjectType() );
        Id contactId3 = dao.Builder.getMockId( Contact.getSObjectType() );
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Scheduled' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Dispatched' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Spotted' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'En Route' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'On Location' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'In Tow' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Cleared' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Canceled' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId2, Status = 'Dispatched' );
        WorkOrder workOrder10 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId3, Status = 'Dispatched' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        dao.workOrders.put( workOrder10.Id, workOrder10 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId3 };

        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchDetailedActiveWorkOrdersByContactId( contactIds );
        Test.stopTest();

        System.assertEquals( 7, workOrders.size(), 'The amount of WorkOrders returned is not as expected' );
        System.assert( contactIds.contains( workOrders[0].ContactId ) && workOrders[0].Status != 'Canceled' && workOrders[0].Status != 'Cleared', 'The 1st WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[1].ContactId ) && workOrders[1].Status != 'Canceled' && workOrders[1].Status != 'Cleared', 'The 2nd WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[2].ContactId ) && workOrders[2].Status != 'Canceled' && workOrders[2].Status != 'Cleared', 'The 3rd WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[3].ContactId ) && workOrders[3].Status != 'Canceled' && workOrders[3].Status != 'Cleared', 'The 4th WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[4].ContactId ) && workOrders[4].Status != 'Canceled' && workOrders[4].Status != 'Cleared', 'The 5th WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[5].ContactId ) && workOrders[5].Status != 'Canceled' && workOrders[5].Status != 'Cleared', 'The 6th WorkOrder does not match the criteria' );
        System.assert( contactIds.contains( workOrders[6].ContactId ) && workOrders[6].Status != 'Canceled' && workOrders[6].Status != 'Cleared', 'The 7th WorkOrder does not match the criteria' );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchDetailedActiveWorkOrdersByContactId_IsException_ExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        Id contactId1 = dao.Builder.getMockId( Contact.getSObjectType() );
        Id contactId2 = dao.Builder.getMockId( Contact.getSObjectType() );
        Id contactId3 = dao.Builder.getMockId( Contact.getSObjectType() );
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Scheduled' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Dispatched' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Spotted' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'En Route' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'On Location' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'In Tow' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Cleared' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId1, Status = 'Canceled' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId2, Status = 'Dispatched' );
        WorkOrder workOrder10 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contactId3, Status = 'Dispatched' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        dao.workOrders.put( workOrder10.Id, workOrder10 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId3 };
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<WorkOrder> workOrders = dao.fetchDetailedActiveWorkOrdersByContactId( contactIds );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchWorkOrdersForExternalIds_CorrectNumberOfRecordsReturned() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = 'ExtID-1-22' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = 'ExtID-2-25' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), External_Id__c = 'ExtID-3-26' );
        dao.extIDtoWorkOrder.put( workOrder1.External_Id__c, workOrder1 );
        dao.extIDtoWorkOrder.put( workOrder2.External_Id__c, workOrder2 );
        dao.extIDtoWorkOrder.put( workOrder3.External_Id__c, workOrder3 );
        Set<String> extIDs = new Set<String>{'ExtID-2-25'};

        Test.startTest();
        List<WorkOrder> workOrders = dao.fetchWorkOrdersForExternalIds( extIDs, true );
        Test.stopTest();

        System.assertEquals( 1, workOrders.size() );
        System.assertEquals( workOrders[0].External_Id__c,  'ExtID-2-25');
    }

    @IsTest
    public static void testWorkOrderDAOMock_FetchWorkOrdersForExternalIds_ExceptionSet_ExceptionThrown() {
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        Id workOrderId = dao.Builder.getMockId();
        WorkOrder workOrder = new WorkOrder( Id = workOrderId );
        dao.workOrders.put( workOrder.Id, workOrder );
        dao.isSuccess = false;
        QueryException ex = null;
        Set<String> extIDs = new Set<String>{'ExtID-2-25'};

        Test.startTest();
        try {
            List<WorkOrder> workOrders = dao.fetchWorkOrdersForExternalIds( extIDs, true );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }


    @IsTest
    public static void testWorkOrderDAOMock_FetchAllReadOnlyWorkOrdersNotYetCleared_Success_ListReturned() {
       // WorkOrderDAOMock dao = new WorkOrderDAOMock();
       // dao.returnValueForFetchWorkOrdersNotYetCleared = new List<WorkOrder>();

       // Id workOrderId = dao.Builder.getMockId();
       // WorkOrder workOrder = new WorkOrder( Id = workOrderId );
       // dao.returnValueForFetchWorkOrdersNotYetCleared.add(workOrder);
       // QueryException ex = null;
       // List<WorkOrder> workOrders = new List<WorkOrder>();

       // Test.startTest();
         createDaoData();
        FSL_WorkOrder.IWorkOrderDAO dao = new FSL_WorkOrder.WorkOrderDAO();
        FSL_WorkOrder.IWorkOrderService workSerive = new FSL_WorkOrder.WorkOrderService (dao);
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];

        //System.assertEquals( 5, insertedWorkOrders.size() );
        //Set<Id> workOrderIds = new Set<Id>{ insertedWorkOrders[2].Id, insertedWorkOrders[3].Id };
        
        Test.startTest();
     //   List<WorkOrder> workOrders = dao.fetchWorkOrdersForClearing( workOrderIds );
       // Test.stopTest();

      //  System.assertEquals( 2, workOrders.size() );
       // System.assertEquals( insertedWorkOrders[2].Id, workOrders[0].Id );
       // System.assertEquals( insertedWorkOrders[3].Id, workOrders[1].Id );
        try {
           List<WorkOrder>  workOrders = dao.fetchAllReadOnlyWorkOrdersNotYetCleared(System.now(),1);  
            FSL_WorkOrder.EODBean returnWorkOrder =  workSerive.getWorkOrdersToSentToBackOfficeEOD();
        }
        catch( QueryException e ) {
          //  ex = e;
        }
        Test.stopTest();

      
       // System.assertEquals( null, ex );
       // System.assertEquals( workOrders[0].Id, workOrderId );
    }




    // *********************************************
    // * ServiceMock
    // *********************************************
    public class WorkOrderServiceMock implements FSL_WorkOrder.IWorkOrderService {
        public Integer onBeforeUpdateCallCount = 0;
        public Integer getWorkOrdersForClearingCallCount = 0;
        public Integer fetchWorkOrdersForUpdateUsingExternalIDCallCount = 0;
        public Integer updateWorkOrdersCallCount = 0;

        public Integer processWorkOrderCancelRequestCallCount = 0;
        public Set<String> processWorkOrderCancelRequestReturnValue = null;
        public Integer processWorkOrderUpdateRequestCallCount = 0;
        public Set<String> processWorkOrderUpdateRequestReturnValue = null;
        public Integer handleBeforeUpdateTriggerForCancelledCallCallCount = 0;

        public List<WorkOrder> getWorkOrdersForClearingReturnValue = new List<WorkOrder>();
        public List<WorkOrder> fetchWorkOrdersForUpdateUsingExternalIDReturnValue = null;

        public Integer lockWorkOrdersAndPrepareToClearCount = 0;
        public Integer getValidatedWaitTimeOnIntakeCount = 0;
        public Integer getValidatedWaitTimeOnIntakeReturnValue = 0;

        public Boolean throwsException = false;
        public Exception exceptionToThrow = null;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                if ( exceptionToThrow != null ) {
                   throw exceptionToThrow;
                }
                else {
                    throw new QueryException( 'Forced exception in FSL_WorkOrderTest.WorkOrderServiceMock' );
                }
            }
        }

        public void onBeforeUpdate( Map<Id, WorkOrder> oldMap, Map<Id, WorkOrder> newMap, FSL_Contact.IContactService contactService ) {
            ++onBeforeUpdateCallCount;
            throwExceptionIfConfigured();
        }

        public List<WorkOrder> getWorkOrdersForClearing( Set<Id> workOrderIds ) {
            ++getWorkOrdersForClearingCallCount;
            throwExceptionIfConfigured();
            return getWorkOrdersForClearingReturnValue;
        }

        public Integer getWorkOrdersByCallIdAndCallDateCallCount = 0;
        public List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDateReturnValue = new List<FSL_WorkOrder.WorkOrder>();
        public List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDate( List<FSL_WorkOrder.CallIdAndCallDatePair> criteria, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService ) {
            getWorkOrdersByCallIdAndCallDateCallCount++;
            throwExceptionIfConfigured();
            return getWorkOrdersByCallIdAndCallDateReturnValue;
        }

        public Integer getActiveWorkOrdersByContactIdCallCount = 0;
        public List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactIdReturnValue = new List<FSL_WorkOrder.WorkOrder>();
        public List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactId( Set<Id> contactIds, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService ) {
            getActiveWorkOrdersByContactIdCallCount++;
            throwExceptionIfConfigured();
            return getActiveWorkOrdersByContactIdReturnValue;
        }

        public void updateWorkOrders(List<WorkOrder> woList) {
            updateWorkOrdersCallCount++;        
            throwExceptionIfConfigured();
        }

        public void updateContactAndRemoveCODFromWorkOrder(String woId,Contact contact) {
            throwExceptionIfConfigured();
        }

        public Set<String> processWorkOrderUpdateRequest(FSL_WorkOrder.UpdateRequestWrapper requestWrapper, 
                            FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                            FSL_CallComments.ICalLCommentsService callCommentsService) {

            ++processWorkOrderUpdateRequestCallCount;
            throwExceptionIfConfigured();
            return processWorkOrderUpdateRequestReturnValue;
        }

        public Set<String>  processWorkOrderCancelRequest(FSL_WorkOrder.UpdateRequestWrapper requestWrapper, FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                            FSL_CallComments.ICalLCommentsService callCommentsService) {
            ++processWorkOrderCancelRequestCallCount;
            throwExceptionIfConfigured();
            return processWorkOrderCancelRequestReturnValue;
        }

        public void lockWorkOrdersAndPrepareToClear(FSL_ClearQueuedCall.IClearQueuedCallService clrQueueService,
                                                    FSL_ServiceLineItem.IServiceLineItemService sliService) {
            ++lockWorkOrdersAndPrepareToClearCount;
            throwExceptionIfConfigured();

        }

        public Integer getValidatedWaitTimeOnIntake(Long waitTime) {
            ++getValidatedWaitTimeOnIntakeCount;
            throwExceptionIfConfigured();
            return getValidatedWaitTimeOnIntakeReturnValue;
        }

        public Integer retrieveSchemaWorkOrderDetailsByCallIdAndDateCallCount = 0;
        public List<WorkOrder> retrieveSchemaWorkOrderDetailsByCallIdAndDateReturnValue = new List<WorkOrder>();
        public List<WorkOrder> retrieveSchemaWorkOrderDetailsByCallIdAndDate(List<FSL_WorkOrder.CallIdAndCallDatePair> searchCriteria) {
            retrieveSchemaWorkOrderDetailsByCallIdAndDateCallCount++;
            throwExceptionIfConfigured();
            return retrieveSchemaWorkOrderDetailsByCallIdAndDateReturnValue;
        }

        public Integer processThirdPartyWorkOrderUpdateRequestCallCount = 0;
        public List<WorkOrder> processThirdPartyWorkOrderUpdateRequestReturnValue = new List<WorkOrder>();
        public List <Schema.WorkOrder>  processThirdPartyWorkOrderUpdateRequest(RestApi_PatchCall.PatchCallRequest patchRequest, 
            ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) {
            processThirdPartyWorkOrderUpdateRequestCallCount++;
            throwExceptionIfConfigured();
            return processThirdPartyWorkOrderUpdateRequestReturnValue;           
        }

        public FSL_WorkOrder.EODBean getWorkOrdersToSentToBackOfficeEOD(){ return null ;
        }
        public void updateWorkOrdersSentToBackOfficeEOD(List<Id> idList){}

    }

    @isTest
    public static void testWorkOrderServiceMock_OnBeforeUpdate_NoException_CallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();

        Test.startTest();
        Integer callCount0 = service.onBeforeUpdateCallCount;

        service.onBeforeUpdate( null, null, null );
        Integer callCount1 = service.onBeforeUpdateCallCount;

        service.onBeforeUpdate( null, null, null );
        Integer callCount2 = service.onBeforeUpdateCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @isTest
    public static void testWorkOrderServiceMock_OnBeforeUpdate_Exception_CallCountIncrementedAndExceptionThrown() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        service.throwsException = true;

        Exception ex = null;

        Test.startTest();
        Integer callCount0 = service.onBeforeUpdateCallCount;
        try {
            service.onBeforeUpdate( null, null, null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Integer callCount1 = service.onBeforeUpdateCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testWorkOrderServiceMock_GetWorkOrdersForClearing_CorrectValueReturnedAndCallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.getWorkOrdersForClearingCallCount;

        List<WorkOrder> workOrders1 = service.getWorkOrdersForClearing( new Set<Id>() );
        Integer callCount1 = service.getWorkOrdersForClearingCallCount;

        List<WorkOrder> expected = new List<WorkOrder>{ new WorkOrder() };
        service.getWorkOrdersForClearingReturnValue = expected;
        List<WorkOrder> workOrders2 = service.getWorkOrdersForClearing( new Set<Id>() );
        Integer callCount2 = service.getWorkOrdersForClearingCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 0, workOrders1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, workOrders2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testWorkOrderServiceMock_GetWorkOrdersByCallIdAndCallDate_CorrectValueReturnedAndCallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        
        System.assertEquals( 0, service.getWorkOrdersByCallIdAndCallDateCallCount, 'service.getWorkOrdersByCallIdAndCallDate() has been called' );
        
        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> workOrders1 = service.getWorkOrdersByCallIdAndCallDate( new List<FSL_WorkOrder.CallIdAndCallDatePair>(), null, null );
        Integer callCount1 = service.getWorkOrdersByCallIdAndCallDateCallCount;

        List<FSL_WorkOrder.WorkOrder> expected = new List<FSL_WorkOrder.WorkOrder>{ new WorkOrderMock() };
        service.getWorkOrdersByCallIdAndCallDateReturnValue = expected;
        List<FSL_WorkOrder.WorkOrder> workOrders2 = service.getWorkOrdersByCallIdAndCallDate( new List<FSL_WorkOrder.CallIdAndCallDatePair>(), null, null );
        Integer callCount2 = service.getWorkOrdersByCallIdAndCallDateCallCount;
        Test.stopTest();

        System.assertEquals( 0, workOrders1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, workOrders2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testWorkOrderServiceMock_GetActiveWorkOrdersByContactId_CorrectValueReturnedAndCallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        
        System.assertEquals( 0, service.getActiveWorkOrdersByContactIdCallCount, 'service.getActiveWorkOrdersByContactId() has been called' );
        
        Test.startTest();
        List<FSL_WorkOrder.WorkOrder> workOrders1 = service.getActiveWorkOrdersByContactId( new Set<Id>(), null, null );
        Integer callCount1 = service.getActiveWorkOrdersByContactIdCallCount;

        List<FSL_WorkOrder.WorkOrder> expected = new List<FSL_WorkOrder.WorkOrder>{ new WorkOrderMock() };
        service.getActiveWorkOrdersByContactIdReturnValue = expected;
        List<FSL_WorkOrder.WorkOrder> workOrders2 = service.getActiveWorkOrdersByContactId( new Set<Id>(), null, null );
        Integer callCount2 = service.getActiveWorkOrdersByContactIdCallCount;
        Test.stopTest();

        System.assertEquals( 0, workOrders1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, workOrders2 );
        System.assertEquals( 2, callCount2 );
    }

    // @IsTest
    // static void testUpdateContactAndRemoveCODFromWorkOrder(){

    //     WorkOrderDAOMock dao = new WorkOrderDAOMock();
    //     FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
    //     Contact contact1 = new Contact( Id = dao.Builder.getMockId( Schema.Contact.getSObjectType() ), AccountId = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
    //     WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), ContactId = contact1.Id, Member_Account__c = contact1.AccountId, Payment_Required__c = true );
    //     dao.workOrders.put( workOrder1.Id, workOrder1 );
    //     Test.startTest();
    //     service.updateContactAndRemoveCODFromWorkOrder(workOrder1.Id, contact1);
    //     Test.stopTest();
    //     System.assertEquals(false, workOrder1.Payment_Required__c);   
    // }

    @IsTest
    static void testGetWorkOrdersByIds(){
        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        FSL_WorkOrder.WorkOrderService woService = new FSL_WorkOrder.WorkOrderService(dao);
        WorkOrder workOrder1 =new WorkOrder( Id = dao.Builder.getMockId());
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        Set<Id> ids = new Set<Id> ();
        ids.add(workOrder1.Id);
        FSL_WorkOrder.IWorkOrderDAO dao2 = new FSL_WorkOrder.WorkOrderDAO();
        FSL_WorkOrder.WorkOrderService woService2 = new FSL_WorkOrder.WorkOrderService(dao2);
        Test.startTest();
        woService2.getWorkOrdersByIds(ids);//private method for coverage only;
        System.assertEquals(workOrder1.Id, woService.getWorkOrdersByIds(ids)[0].Id);
        Test.stopTest();
    }

    @isTest
    public static void testWorkOrderServiceMock_ProcessWorkOrderCancelRequest_CallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();

        Test.startTest();
        Integer callCount0 = service.processWorkOrderCancelRequestCallCount;

        Set<String>  expectedReturnValue = null;
        Set<String>  returnValue1 = service.processWorkOrderCancelRequest( null, null, null);
        Integer callCount1 = service.processWorkOrderCancelRequestCallCount;

        expectedReturnValue = new Set<String>();
        service.processWorkOrderCancelRequestReturnValue = expectedReturnValue;
        Set<String>  returnValue2 = service.processWorkOrderCancelRequest( null, null, null);
        Integer callCount2 = service.processWorkOrderCancelRequestCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
        System.assertEquals( null, returnValue1);
        System.assertEquals( expectedReturnValue, returnValue2);
    }

    @isTest
    public static void testWorkOrderServiceMock_ProcessWorkOrderCancelRequest_Exception_CallCountIncrementedAndExceptionThrown() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        service.throwsException = true;

        Exception ex = null;

        Test.startTest();
        Integer callCount0 = service.processWorkOrderCancelRequestCallCount;
        try {
            service.processWorkOrderCancelRequest( null, null, null);
        }
        catch( Exception e ) {
            ex = e;
        }
        Integer callCount1 = service.processWorkOrderCancelRequestCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testWorkOrderServiceMock_ProcessWorkOrderUpdateRequest_CallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();

        Test.startTest();
        Integer callCount0 = service.processWorkOrderUpdateRequestCallCount;

        Set<String> expectedReturnValue = null;
        Set<String>  returnValue1 = service.processWorkOrderUpdateRequest( null, null, null);
        Integer callCount1 = service.processWorkOrderUpdateRequestCallCount;

        expectedReturnValue = new  Set<String> ();
        service.processWorkOrderUpdateRequestReturnValue = expectedReturnValue;
        Set<String> returnValue2 = service.processWorkOrderUpdateRequest( null, null, null);
        Integer callCount2 = service.processWorkOrderUpdateRequestCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
        System.assertEquals( null, returnValue1);
        System.assertEquals( expectedReturnValue, returnValue2);
    }

    @isTest
    public static void testWorkOrderServiceMock_ProcessWorkOrderUpdateRequest_Exception_CallCountIncrementedAndExceptionThrown() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        service.throwsException = true;

        Exception ex = null;

        Test.startTest();
        Integer callCount0 = service.processWorkOrderUpdateRequestCallCount;
        try {
            service.processWorkOrderUpdateRequest( null, null, null);
        }
        catch( Exception e ) {
            ex = e;
        }
        Integer callCount1 = service.processWorkOrderUpdateRequestCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testWorkOrderServiceMock_ProcessWorkOrderCancel_ExceptionToThrowSpecified_SpecifiedExceptionThrown() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();
        service.throwsException = true;

        Set <Exception> testExceptions = new Set<Exception> { 
                         new FSL_WorkOrder.UpdateWorkOrderException('Test UpdateWorkOrderException Exception'),
                         new FSL_WorkOrder.UpdateWorkOrderDMLException('Test UpdateWorkOrderDMLException Exception'),
                         new FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException('Test NoMatchingWorkOrdersToUpdateException Exception') };                                           
                                                             
        for ( Exception testEx : testExceptions) {
            try {  
                service.exceptionToThrow = testEx;
                service.processWorkOrderCancelRequest( null, null, null); 
            }
            catch (Exception ex) {
                System.assertEquals(ex.getMessage(), testEx.getMessage());
            }
        }
    }

    @isTest
    public static void testWorkOrderServiceMock_lockWorkOrdersAndPrepareToClear_NoException_CallCountIncremented() {
        WorkOrderServiceMock service = new WorkOrderServiceMock();

        Test.startTest();
        Integer callCount0 = service.lockWorkOrdersAndPrepareToClearCount;

        service.lockWorkOrdersAndPrepareToClear(null, null);
        Integer callCount1 = service.lockWorkOrdersAndPrepareToClearCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
    }

    @IsTest
    public static void testWorkOrderServiceWaitTimeGreaterThanMaxWaitTime() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();

        dao.returnValueForFetchWorkOrderConfiguration = new List <FSL_WorkOrder_Configuration__mdt>();
        FSL_WorkOrder_Configuration__mdt config = new FSL_WorkOrder_Configuration__mdt();
        config.Maximum_Wait_Time_Allowed__c = 99;
        config.Default_Wait_Time__c = 2;
        dao.returnValueForFetchWorkOrderConfiguration.add(config);

        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLogTest.FactoryMock().createService();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        Integer waitTime = workOrderService.getValidatedWaitTimeOnIntake(1000L);
        Integer waitTimeNegative = workOrderService.getValidatedWaitTimeOnIntake(-10L);

        System.assertEquals(waitTime, 2, 'Returned Wait Time of value greater than Maximum Wait Time should be equal to default Wait Time of 2');
        System.assertEquals(waitTime, 2, 'Returned Wait Time of value less than zero should be equal to default Wait Time of 2');
    }

    @IsTest
    public static void testWorkOrderServiceWaitTimeGreaterThanMaxWaitTimeThrowsException() {

        WorkOrderDAOMock dao = new WorkOrderDAOMock();
        dao.returnValueForFetchWorkOrderConfiguration = null;

        FSL_ApplicationLogTest.ApplicationLogServiceMock logService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.WorkOrderService(dao, logService);

        Integer waitTime = workOrderService.getValidatedWaitTimeOnIntake(1000L);
        System.assertEquals(logService.saveApplicationLogsCallCount, 1, 'An Application log should be inserted when Work Order configuration is missing');
    }

    // *********************************************
    // * DomainMock
    // *********************************************
    public class WorkOrderMock extends FSL_WorkOrder.WorkOrder {
        public WorkOrderMock() {
            super( null, null, null );
        }

        public Integer getWorkOrderCallCount = 0;
        public Schema.WorkOrder getWorkOrderReturnValue = null;
        public override Schema.WorkOrder getWorkOrder() {
            getWorkOrderCallCount++;
            return getWorkOrderReturnValue;
        }

        public Integer getFeedItemsCallCount = 0;
        public List<FeedItem> getFeedItemsReturnValue = null;
        public override List<FeedItem> getFeedItems() {
            getFeedItemsCallCount++;
            return getFeedItemsReturnValue;
        }

        public Integer getServiceAppointmentsCallCount = 0;
        public List<FSL_ServiceAppointment.ServiceAppointment> getServiceAppointmentsReturnValue = null;
        public override List<FSL_ServiceAppointment.ServiceAppointment> getServiceAppointments() {
            getServiceAppointmentsCallCount++;
            return getServiceAppointmentsReturnValue;
        }

        public Integer getBreakDownServiceAppointmentCallCount = 0;
        public FSL_ServiceAppointment.ServiceAppointment getBreakDownServiceAppointmentReturnValue = null;
        public override FSL_ServiceAppointment.ServiceAppointment getBreakDownServiceAppointment() {
            getBreakDownServiceAppointmentCallCount++;
            return getBreakDownServiceAppointmentReturnValue;
        }

        public Integer getTowServiceAppointmentCallCount = 0;
        public FSL_ServiceAppointment.ServiceAppointment getTowServiceAppointmentReturnValue = null;
        public override FSL_ServiceAppointment.ServiceAppointment getTowServiceAppointment() {
            getTowServiceAppointmentCallCount++;
            return getTowServiceAppointmentReturnValue;
        }

        public Integer getStatusTimestampCallCount = 0;
        public Datetime getStatusTimestampReturnValue = null;
        public override Datetime getStatusTimestamp() {
            getStatusTimestampCallCount++;
            return getStatusTimestampReturnValue;
        }
    }
}