/****
 * *@Name: ServiceAppointment
 * *@Description: when the workorder is created Update the ServiceAppointment Address,lat,lag etc.. from WorkOrder. *  * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0                 Vincent               Initial Version
 *  *     03/18/2021   Dylan Truong         ERS-221797 - Fix Gantt Icon issue when status change by user who are not part of club dispatcher
 *  *     05/11/2021   Dylan Truong         ERS-220396 - Make Appointment Calls More Visible to FSL Users 
 ***/

@IsTest
public with sharing class FSL_ServiceAppointmentTest {

    public static final String TECHNOLOGY_TYPE_FULL = 'Full FSL Technology';
    public static final String TECHNOLOGY_TYPE_LANDLINE = FSL_ServiceAppointment.LANDLINE_TECHNOLOGY_TYPE;
    public static final String TECHNOLOGY_TYPE_TOWBOOK = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
    public static final String TECHNOLOGY_TYPE_TOWBOOK_NOTIFY = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY;

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_ServiceAppointment.IFactory factory = new FSL_ServiceAppointment.Factory();

        Test.startTest();
        FSL_ServiceAppointment.IServiceAppointmentService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactory_CreateServiceAppointments_BreakdownAppointment_TypeIsBreakdownServiceAppointment() {
        FSL_ServiceAppointment.IFactory factory = new FSL_ServiceAppointment.Factory();
        RecordTypeInfo breakdownRT = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown');
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>{ new ServiceAppointment(RecordTypeId = breakdownRT.getRecordTypeId(), Subject = 'Breakdown Appointment') };
           
        //Formula.recalculateFormulas(serviceAppointments); 
         
         Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();

        Test.startTest();
        List<FSL_ServiceAppointment.ServiceAppointment> domainServiceAppointments = factory.createServiceAppointments( serviceAppointments, serviceAppointmentIdToAssignedResourceMap );
        Test.stopTest();

        System.assertEquals( 1, domainServiceAppointments.size(), 'The number of Service Appointments created is incorrect' );
        //System.assert( domainServiceAppointments[0] instanceof FSL_ServiceAppointment.BreakdownServiceAppointment, 'The created Service Appointment is not the correct type' );
    }

    @IsTest
    public static void testFactory_CreateServiceAppointments_TowAppointment_TypeIsTowServiceAppointment() {
        FSL_ServiceAppointment.IFactory factory = new FSL_ServiceAppointment.Factory();
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>{ new ServiceAppointment( Subject = 'Tow Appointment' ) };
        Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();

        Test.startTest();
        List<FSL_ServiceAppointment.ServiceAppointment> domainServiceAppointments = factory.createServiceAppointments( serviceAppointments, serviceAppointmentIdToAssignedResourceMap );
        Test.stopTest();

        System.assertEquals( 1, domainServiceAppointments.size(), 'The number of Service Appointments created is incorrect' );
        System.assert( domainServiceAppointments[0] instanceof FSL_ServiceAppointment.TowServiceAppointment, 'The created Service Appointment is not the correct type' );
    }

    // *********************************************
    // * DAO
    // *********************************************


    public class DaoDataHolder {
        List <ServiceAppointment> breakDownSAs;
        List <ServiceAppointment> towSAs;

        public DaoDataHolder() {
            breakDownSAs = new List <ServiceAppointment>();
            towSAs = new List <ServiceAppointment>();
        }

    }

    private static DaoDataHolder  createDaoData(String techType) {

        DaoDataHolder daoDataHolder = new DaoDataHolder();

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
            workOrders[i].Servicing_Technology_Type__c = techType;
        }
  
        insert workOrders;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        insert sts;

        Set<Id> woIds = new Set<Id>();

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for( Integer i = 0; i < recordCount; ++i ) {
            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
            breakdownSa.ParentRecordId = workOrders[i].Id;
            breakdownSa.Work_Order__c = workOrders[i].Id;
            woIds.add(breakdownSa.ParentRecordId);
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
            serviceAppointments.add( breakdownSa );
         
            ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
            towSa.ParentRecordId = workOrders[i].Id;
            towSa.Work_Order__c = workOrders[i].Id;
            woIds.add(breakdownSa.ParentRecordId);
            //ERS-230874 Glympse Removal - Part I
            //towSA.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 2;
            serviceAppointments.add( towSa);
           

        }
        insert serviceAppointments;

        List<ServiceAppointment> brkDnSAs = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c,  Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE (ParentRecordId IN :woIds AND isBreakdown__c=True)];
        List<ServiceAppointment> towSAs = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c,  Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE (ParentRecordId IN :woIds AND isBreakdown__c=False)];

        daoDataHolder.breakDownSAs.addAll(brkDnSAs);
        daoDataHolder.towSAs.addAll(towSAs);

        return daoDataHolder;

    }

    @IsTest
    public static void testServiceAppointmentDAO_FetchBreakDownServiceAppointmentsForWorkOrders_CorrectNumberOfRecordsReturned() {
       
        Test.startTest();
        createDaoData(TECHNOLOGY_TYPE_FULL);
        FSL_ServiceAppointment.IServiceAppointmentDAO dao = new FSL_ServiceAppointment.ServiceAppointmentDAO();
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        List<ServiceAppointment> serviceAppointments = dao.fetchBreakDownServiceAppointmentsForWorkOrders( new Set<Id>{ workOrders[1].Id, workOrders[3].Id } );
        Test.stopTest();

        System.assertEquals( 2, serviceAppointments.size() );
        System.assertEquals( 'Breakdown', serviceAppointments[0].RecordType.Name );
        System.assertEquals( 'Breakdown', serviceAppointments[1].RecordType.Name );
        System.assertEquals( workOrders[1].Id, serviceAppointments[0].ParentRecordId );
        System.assertEquals( workOrders[3].Id, serviceAppointments[1].ParentRecordId );
    }

    //ERS-230874 Glympse Removal
    //@IsTest
    //public static void testServiceAppointmentDAO_FetchServiceAppointmentByGlympseTaskId_CorrectNumberOfRecordsReturned() {
    //   
    //    Test.startTest();
    //     createDaoData(TECHNOLOGY_TYPE_FULL);
    //    FSL_ServiceAppointment.IServiceAppointmentDAO dao = new FSL_ServiceAppointment.ServiceAppointmentDAO();
    //
    //    List<ServiceAppointment> serviceAppointments = [SELECT Id, Glympse_EnRoute__Glympse_EnRoute_Task_ID__c FROM ServiceAppointment];
    //    Integer glympseTaskId = serviceAppointments[2].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c.intValue();
    //
    //    System.assertNotEquals( 0, glympseTaskId );
    //    List<ServiceAppointment> glympseServiceAppointment = dao.fetchServiceAppointmentByGlympseTaskId( glympseTaskId );
    //    Test.stopTest();
    //    System.assertEquals( 1, glympseServiceAppointment.size() );
    //    System.assertEquals( glympseTaskId, glympseServiceAppointment[0].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c );
    //}

    @IsTest
    public static void testServiceAppointmentDAO_FetchServiceAppointmentsForWorkOrders_CorrectNumberOfRecordsReturned() {
    
        FSL_ServiceAppointment.IServiceAppointmentDAO dao = new FSL_ServiceAppointment.ServiceAppointmentDAO();

    

        Test.startTest();
        createDaoData(TECHNOLOGY_TYPE_FULL);
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];

        Set<Id> woSingle = new Set<Id> {workOrders[1].Id };
        Set<Id> woMultiple = new Set<Id> {workOrders[1].Id, workOrders[3].Id};
        List<ServiceAppointment> SAsForSingleWO = dao.fetchServiceAppointmentsForWorkOrders(woSingle);
        List<ServiceAppointment> SAsForMultipleWO= dao.fetchServiceAppointmentsForWorkOrders(woMultiple);

        Test.stopTest();

        System.assertEquals( 2, SAsForSingleWO.size() );
        System.assertEquals( workOrders[1].Id, SAsForSingleWO[0].ParentRecordId );
        System.assertEquals( workOrders[1].Id, SAsForSingleWO[1].ParentRecordId );

        System.assertEquals( 4, SAsForMultipleWO.size() );
        System.assertEquals( workOrders[3].Id, SAsForMultipleWO[2].ParentRecordId );
        System.assertEquals( workOrders[3].Id, SAsForMultipleWO[3].ParentRecordId );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testServiceAppointmentService_GetBreakDownServiceAppointmentsForWorkOrders_DAOCalledAndResultReturned() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );

        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
        // Need this SOQL to get the formula field correctly set in the input
        Set <Id> saIds = new Set<Id>();
        saIds.add(daoDataHolder.breakDownSAs[0].Id);
        saIds.add(daoDataHolder.breakDownSAs[1].Id);
        saIds.add(daoDataHolder.towSAs[0].Id);
        saIds.add(daoDataHolder.towSAs[1].Id);

        List<ServiceAppointment> svcAppts = [SELECT Id, Status, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id in :saIds ];


        dao.serviceAppointments.put( svcAppts[0].Id, svcAppts[0] );
        dao.serviceAppointments.put( svcAppts[1].Id, svcAppts[1] );
        dao.serviceAppointments.put( svcAppts[2].Id, svcAppts[2] );
        dao.serviceAppointments.put( svcAppts[3].Id, svcAppts[3] );

        Id workOrderId1 = svcAppts[0].ParentRecordId;

        Test.startTest();
        List<ServiceAppointment> serviceAppointments = service.getBreakDownServiceAppointmentsForWorkOrders( new Set<Id>{ workOrderId1 } );
        Test.stopTest();

        System.assertEquals( 1, serviceAppointments.size() );
        System.assertEquals( svcAppts[0].Id, serviceAppointments[0].Id );
        System.assertEquals( true, serviceAppointments[0].isBreakdown__c);
        System.assertEquals( workOrderId1, serviceAppointments[0].ParentRecordId );
    }

    @IsTest
    public static void testServiceAppointmentService_UpdateActualMilesDriven_RecordUpdatedAndClearQueueServiceCalled() {

        //ERS-230874 Glympse Removal - Part I
        /*--
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );
        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallService = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();

        Integer glympseTaskId1 = 123;
        Integer glympseTaskId2 = 456;
        Integer glympseTaskId3 = 789;

        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId1 );
        ServiceAppointment sa2 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId2 );
        ServiceAppointment sa3 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId3 );

        dao.serviceAppointments.put( sa1.Id, sa1 );
        dao.serviceAppointments.put( sa2.Id, sa2 );
        dao.serviceAppointments.put( sa3.Id, sa3 );
        Decimal actualMilesDriven = 147.25;

        Test.startTest();
        ServiceAppointment updatedSa = service.updateActualMilesDriven( glympseTaskId2, actualMilesDriven, clearQueuedCallService );
        Test.stopTest();

        System.assertEquals( sa2, updatedSa );
        System.assertEquals( actualMilesDriven, dao.serviceAppointments.get( sa2.Id ).FSL_Actual_Miles_Driven__c );
        System.assertEquals( 1, clearQueuedCallService.updateMileageReceivedCallCount );
        --*/
    }

    @IsTest
    public static void testServiceAppointmentService_UpdateActualMilesDriven_AllServiceAppointmentsForWorkOrderHaveMileage_RecordUpdatedAndClearQueueServiceCalled() {

        //ERS-230874 Glympse Removal - Part I
        /* ----------------

        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );
        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallService = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id workOrderId2 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );

        Integer glympseTaskId1 = 123;
        Integer glympseTaskId2 = 456;
        Integer glympseTaskId3 = 789;
        
        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId1, ParentRecordId = workOrderId1, FSL_Actual_Miles_Driven__c = 321.12 );
        ServiceAppointment sa2 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId2, ParentRecordId = workOrderId1 );
        ServiceAppointment sa3 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId3, ParentRecordId = workOrderId2 );

        dao.serviceAppointments.put( sa1.Id, sa1 );
        dao.serviceAppointments.put( sa2.Id, sa2 );
        dao.serviceAppointments.put( sa3.Id, sa3 );
        Decimal actualMilesDriven = 147.25;

        Test.startTest();
        ServiceAppointment updatedSa = service.updateActualMilesDriven( glympseTaskId2, actualMilesDriven, clearQueuedCallService );
        Test.stopTest();

        System.assertEquals( sa2, updatedSa );
        System.assertEquals( actualMilesDriven, dao.serviceAppointments.get( sa2.Id ).FSL_Actual_Miles_Driven__c );
        System.assertEquals( 1, clearQueuedCallService.updateMileageReceivedCallCount );

        --------------------------*/
    }

    @IsTest
    public static void testServiceAppointmentService_UpdateActualMilesDriven_NoServiceAppointmentsWithGlympseTaskIdReturned_LogCreatedAndNoFurtherUpdates() {

        //ERS-230874 Glympse Removal - Part I
        /*--
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );
        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallService = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();

        Integer glympseTaskId1 = 123;
        Integer glympseTaskId2 = 456;
        
        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId1 );

        dao.serviceAppointments.put( sa1.Id, sa1 );
        Decimal actualMilesDriven = 147.25;

        Test.startTest();
        ServiceAppointment updatedSa = service.updateActualMilesDriven( glympseTaskId2, actualMilesDriven, clearQueuedCallService );
        Test.stopTest();

        System.assertEquals( null, updatedSa );
        System.assertEquals( 0, clearQueuedCallService.updateMileageReceivedCallCount );

        --*/
    }

    @IsTest
    public static void testServiceAppointmentService_SaveD3SyncStatusOfServiceAppointmentChildren_CorrectNumberOfRecordsUpdated() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id workOrderId2 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );

        Set <Id> workOrderIds = new Set<Id>();
        workOrderIds.add(workOrderId1);
     
        Id workOrderId3 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Set <Id> noSAsWoSet = new Set<Id>();
        noSAsWoSet.add(workOrderId3);

        List<ServiceAppointment>  saList = new List<ServiceAppointment>();

        saList.add(new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1, D3_Sync_Issue__c = false ));
        saList.add(new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1, D3_Sync_Issue__c = false ));
        saList.add(new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId2, D3_Sync_Issue__c = false ));
        dao.serviceAppointments.put(saList[0].Id, saList[0]);
        dao.serviceAppointments.put(saList[1].Id, saList[1]);
        dao.serviceAppointments.put(saList[2].Id, saList[2]);

        service.saveD3SyncStatusOfServiceAppointmentChildren(workOrderIds);

        System.assertEquals( 3, dao.serviceAppointments.size() );
        System.assertEquals( true, dao.serviceAppointments.get(saList[0].Id).D3_Sync_Issue__c);
        System.assertEquals( true, dao.serviceAppointments.get(saList[1].Id).D3_Sync_Issue__c);
        System.assertEquals( false, dao.serviceAppointments.get(saList[2].Id).D3_Sync_Issue__c);
    }
    
    @isTest
    public static void testsetGanttIconUrlByType() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        Boolean expectedRequired = true;

        List<OperatingHours> operatingHours = Test.loadData( OperatingHours.SObjectType, 'FSL_OperatingHour' );

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        insert contact;

        List<WorkOrder> wo = new List<WorkOrder>();
        WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo1.Call_Type__c = 'RAP';
        wo.add(wo1);
        WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.add(wo2);
        WorkOrder wo3 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo3.Call_Type__c = 'RAP';
        wo.add(wo3);
        WorkOrder wo4 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo4.Call_Type__c = 'Member';
        wo.add(wo4);
        WorkOrder wo5 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo5.Call_Type__c = 'RAP';
        wo5.Non_Emergency_Appointment_Time__c = 'Test';
        wo.add(wo5);
        WorkOrder wo6 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo6.Non_Emergency_Appointment_Time__c = 'Test';
        wo.add(wo6);
        WorkOrder wo7 = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo7.Call_Type__c = 'RAP';
        wo7.Non_Emergency_Appointment_Time__c = 'Test';
        wo.add(wo7);
        insert wo;

        Id breakdownRecordType = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();
        Id towRecordType = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId();
        
        List<ServiceAppointment> sa = new List<ServiceAppointment>();
        ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = wo1.Id, ParentRecordId = wo1.Id, RecordTypeId = breakdownRecordType);
        sa.add(sa1);
        ServiceAppointment sa2 = new ServiceAppointment( Work_Order__c = wo1.Id, ParentRecordId = wo1.Id, RecordTypeId = towRecordType);
        sa.add(sa2);
        ServiceAppointment sa3 = new ServiceAppointment( Work_Order__c = wo2.Id, ParentRecordId = wo2.Id,  RecordTypeId = breakdownRecordType);
        sa3.Payment_Required__c = expectedRequired;
        sa.add(sa3);
        ServiceAppointment sa4 = new ServiceAppointment( Work_Order__c = wo2.Id, ParentRecordId = wo2.Id, RecordTypeId = towRecordType);
        sa.add(sa4);
        ServiceAppointment sa5 = new ServiceAppointment( Work_Order__c = wo3.Id, ParentRecordId = wo3.Id, RecordTypeId = breakdownRecordType);
        sa5.Payment_Required__c = expectedRequired;
        sa.add(sa5);
        ServiceAppointment sa6 = new ServiceAppointment( Work_Order__c = wo3.Id, ParentRecordId = wo3.Id, RecordTypeId = towRecordType);
        sa.add(sa6);
        ServiceAppointment sa7 = new ServiceAppointment( Work_Order__c = wo4.Id, ParentRecordId = wo4.Id, RecordTypeId = breakdownRecordType);
        sa.add(sa7);
        ServiceAppointment sa8 = new ServiceAppointment( Work_Order__c = wo4.Id, ParentRecordId = wo4.Id, RecordTypeId = towRecordType);
        sa.add(sa8);
        ServiceAppointment sa9 = new ServiceAppointment( Work_Order__c = wo5.Id, ParentRecordId = wo5.Id, RecordTypeId = breakdownRecordType);
        sa.add(sa9);
        ServiceAppointment sa10 = new ServiceAppointment( Work_Order__c = wo5.Id, ParentRecordId = wo5.Id, RecordTypeId = towRecordType);
        sa.add(sa10);
        ServiceAppointment sa11 = new ServiceAppointment( Work_Order__c = wo6.Id, ParentRecordId = wo6.Id, RecordTypeId = breakdownRecordType);
        sa11.Payment_Required__c = expectedRequired;
        sa.add(sa11);
        ServiceAppointment sa12 = new ServiceAppointment( Work_Order__c = wo6.Id, ParentRecordId = wo6.Id, RecordTypeId = towRecordType);
        sa.add(sa12);
        ServiceAppointment sa13 = new ServiceAppointment( Work_Order__c = wo7.Id, ParentRecordId = wo7.Id, RecordTypeId = breakdownRecordType);
        sa13.Payment_Required__c = expectedRequired;
        sa.add(sa13);
        ServiceAppointment sa14 = new ServiceAppointment( Work_Order__c = wo7.Id, ParentRecordId = wo7.Id, RecordTypeId = towRecordType);
        sa.add(sa14);
        insert sa; 
    
        Map<Id,WorkOrder> woCollection = new Map<Id, WorkOrder>();
        woCollection.put(wo1.Id, wo1);
        woCollection.put(wo2.Id, wo2);
        woCollection.put(wo3.Id, wo3);
        woCollection.put(wo4.Id, wo4);
        woCollection.put(wo5.Id, wo5);
        woCollection.put(wo6.Id, wo6);
        woCollection.put(wo7.Id, wo7);

        List<ServiceAppointment> saCollection = new List<ServiceAppointment>([SELECT Id, FSL__GanttIcon__c, Status, ParentRecordId, isBreakdown__c, Payment_Type__c, Payment_Required__c
        FROM ServiceAppointment 
        WHERE parentRecordId =: woCollection.keySet()]);

        FSL_ServiceAppointment.IServiceAppointmentService serviceAppt = (new FSL_ServiceAppointment.Factory()).createService();

        serviceAppt.setGanttIconUrlByType(saCollection, woCollection);

        for(Schema.ServiceAppointment saCheck : saCollection) {  
            if(saCheck.ParentRecordId == wo1.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.toUpperCase().contains('RAP'));
            }
            if(saCheck.ParentRecordId == wo2.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.toUpperCase().contains('COD'));
            }
            if(saCheck.ParentRecordId == wo3.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.toUpperCase().contains('RAP'));
            }
            if(saCheck.ParentRecordId == wo4.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, String.isBlank(saCheck.FSL__GanttIcon__c));
            }
            if(saCheck.ParentRecordId == wo5.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.contains('FSLGanttAppointmentRAP'));
            }
            if(saCheck.ParentRecordId == wo6.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.contains('FSLGanttAppointmentCOD'));
            }
            if(saCheck.ParentRecordId == wo7.Id && saCheck.isBreakdown__c){
                System.assertEquals(true, saCheck.FSL__GanttIcon__c.contains('FSLGanttAppointmentRAP'));
            }
        }
    }
    
    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_RegularSpotted_AutoCleared() {

        Boolean isLandLineCall = false;
        String previousStatus = 'Spotted';
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }
 
    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_RegularScheduled_AutoCleared() {
        Boolean isLandLineCall = false;
        String previousStatus = 'Scheduled';
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }
 
    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_RegularDispatched_AutoCleared() {
        Boolean isLandLineCall = false;
        String previousStatus = 'Dispatched';
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }
 
    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_RegularEnRoute_NotAutoCleared() {
        Boolean isLandLineCall = false;
        String previousStatus = 'En Route';
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }
 
    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_LandLineSpotted_AutoCleared() {
        Boolean isLandLineCall = true;
        String previousStatus = 'Spotted';
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_LandLineScheduled_AutoCleared() {
        Boolean isLandLineCall = true;
        String previousStatus = 'Scheduled';
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_LandLineDispatched_NotAutoCleared() {
        Boolean isLandLineCall = true;
        String previousStatus = 'Dispatched';
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_LandLineEnRoute_NotAutoCleared() {
        Boolean isLandLineCall = true;
        String previousStatus = 'En Route';
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, isLandLineCall, shouldAutoClear);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_TowSA_NotAutoCleared() {
        String previousStatus = 'Spotted';
        Boolean isBrkDnSA = false;
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, TECHNOLOGY_TYPE_FULL, shouldAutoClear, isBrkDnSA);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_LandLineTowSA_NotAutoCleared() {
        String previousStatus = 'Spotted';
        Boolean isBrkDnSA = false;
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, TECHNOLOGY_TYPE_LANDLINE, shouldAutoClear, isBrkDnSA);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_TowBook_Spotted_AutoCleared() {
        String previousStatus = 'Spotted';
        Boolean isBrkDnSA = true;
        Boolean shouldAutoClear = true;
        verifyAutoClearDecision(previousStatus, TECHNOLOGY_TYPE_TOWBOOK, shouldAutoClear, isBrkDnSA);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_TowBook_Scheduled_NotAutoCleared() {
        String previousStatus = 'Scheduled';
        Boolean isBrkDnSA = true;
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, TECHNOLOGY_TYPE_TOWBOOK, shouldAutoClear, isBrkDnSA);
    }

    @IsTest
    public static void testServiceAppoinmentService_ShouldAutoClearCall_TowBook_Spotted_TowSA_NotAutoCleared() {
        String previousStatus = 'Spotted';
        Boolean isBrkDnSA = false;
        Boolean shouldAutoClear = false;
        verifyAutoClearDecision(previousStatus, TECHNOLOGY_TYPE_TOWBOOK, shouldAutoClear, isBrkDnSA);
    }



    // for backward compatibility for SAs that are breakdown SAs
    private static void verifyAutoClearDecision( String originalSAstatus, Boolean isLandLine, Boolean expectedToBeAutoCleared) {
        if ( isLandLine ) {
            verifyAutoClearDecision(originalSAstatus, FSL_ServiceAppointment.LANDLINE_TECHNOLOGY_TYPE, expectedToBeAutoCleared, true);
        }
        else {
            verifyAutoClearDecision(originalSAstatus, TECHNOLOGY_TYPE_FULL, expectedToBeAutoCleared, true);
        }
    }

    private static void verifyAutoClearDecision( String originalSAstatus, String techType, Boolean expectedToBeAutoCleared, Boolean isBrkDnSA) {
        Test.startTest();
        DaoDataHolder daoDataHolder = createDaoData(techType);
        FSL_ServiceAppointment.IServiceAppointmentDAO dao = new FSL_ServiceAppointment.ServiceAppointmentDAO();
        FSL_ServiceAppointment.ServiceAppointmentService serviceApptService = new FSL_ServiceAppointment.ServiceAppointmentService(dao);

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder];

        ServiceAppointment sa ;
        workOrders[0].Servicing_Technology_Type__c = techType;
        
       Id saId;
       if ( isBrkDnSA)  {
            saId = daoDataHolder.breakDownSAs[0].Id;
       }
       else {
            saId = daoDataHolder.towSAs[0].Id;
       }
       for(ServiceAppointment eachSa : [SELECT Id, Status, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c,Work_Order__r.Servicing_Technology_Type__c
             FROM ServiceAppointment ]){
            System.debug('stat is '+ eachSa.Servicing_Technology_Type__c); 
            System.debug('stat is ' +  eachSa.Work_Order__r.Servicing_Technology_Type__c); 
            System.debug('wo is' + eachSa.Work_Order__c);

       }

       List<ServiceAppointment> svcAppts = [SELECT Id, Status, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c FROM ServiceAppointment WHERE Id =:saId ];
       sa = svcAppts[0];
       sa.Status = originalSAstatus;
      

       System.assertEquals(originalSAstatus, sa.Status, 'Input svc status is not correctly set up'); 
       System.assertEquals(isBrkDnSA, sa.isBreakdown__c, 'Input SA type is not correctly set up');
       Boolean autoClearCheck = serviceApptService.isAutoClearableOnCancel(sa);

       System.assertEquals(expectedToBeAutoCleared, autoClearCheck, 'Did not match expected AutoClear criteria based on call technology type and SA original status');
       Test.StopTest();
    }

    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinments_CancelOnTowCall_Success() {
        ServiceAppointmentDAOMock daoMock = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( daoMock );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();
        // Need to create some realData to get the Is_BreakDownSA flag set correctly.
        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
        // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        
        List<ServiceAppointment>
        svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];
        ServiceAppointment breakdownSa;
        breakdownSa = svcAppts[0];
        breakdownSa.status = 'Scheduled';
        Id towSaId = daoDataHolder.towSAs[0].Id;
        
        svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id =:towSaId ];
        ServiceAppointment towSa;
        towSa = svcAppts[0];
        towSa.status = 'Scheduled';
        towSa.Canceled_Timestamp__c = null;
        Id parentId = breakdownSa.ParentRecordId;
        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];
        
        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
 
        List<String> comments = new List<String>();
        comments.add('This call needs to be cancelled');
        Map<Id, List<String>> callComments = new Map<Id, List<String>>();
        callComments.put(wo1.Id, comments);
        daoMock.serviceAppointments.put(breakdownSa.Id, breakdownSa);
        daoMock.serviceAppointments.put(towSa.Id, towSa);
        
        Test.startTest();
       
        service.processCancelServiceAppoinments(idToWorkOrder, callComments, callCommentsServiceMock);
        Test.stopTest();
        System.assertEquals( FSL_ServiceAppointment.RESOLUTION_CODE_CANCELED_BEFORE_ENROUTE, breakdownSa.Resolution_Code__c, 'Expect the resolution code to be set');
        System.assertEquals( 1, callCommentsServiceMock.saveWorkOrderCommentsCallCount, 'Expect to reach all the way to saving the comments');
        System.assertEquals( 'Scheduled', towSa.status, 'Expect the towSA status to be unchanged' );
        System.assertEquals( null, towSa.Canceled_Timestamp__c, 'Expect timestamp to be unchanged' );
    }

    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinments_CancelOnScheduledCall_Success() {

        ServiceAppointmentDAOMock daoMock = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( daoMock );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        // Need to create some realData to get the Is_BreakDownSA flag set correctly.
        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
        // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        List<ServiceAppointment> svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];

        ServiceAppointment sa ;
        sa = svcAppts[0];
        sa.status = 'Scheduled';

        Id parentId = sa.ParentRecordId;

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];
        
        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
 
        List<String> comments = new List<String>();
        comments.add('This call needs to be cancelled');

        Map<Id, List<String>> callComments = new Map<Id, List<String>>();
        callComments.put(wo1.Id, comments);

        daoMock.serviceAppointments.put(sa.Id, sa);


        Test.startTest();
       
        service.processCancelServiceAppoinments(idToWorkOrder, callComments, callCommentsServiceMock);
        Test.stopTest();

        System.assertEquals(sa.Resolution_Code__c, FSL_ServiceAppointment.RESOLUTION_CODE_CANCELED_BEFORE_ENROUTE, 'Expect the resolution code to be set');
        System.assertEquals(callCommentsServiceMock.saveWorkOrderCommentsCallCount, 1, 'Expect to reach all the way to saving the comments');
    }

    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinments_CancelOnEnrouteCall_Success() {

 
        ServiceAppointmentDAOMock daoMock = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( daoMock );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        // Need to create some realData to get the Is_BreakDownSA flag set correctly.
        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
         // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        List<ServiceAppointment> svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];

        ServiceAppointment sa ;
        sa = svcAppts[0];
        sa.status = 'En Route';

        Id parentId = sa.ParentRecordId;

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];
        
        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
 
        List<String> comments = new List<String>();
        comments.add('This call needs to be cancelled');

        Map<Id, List<String>> callComments = new Map<Id, List<String>>();
        callComments.put(wo1.Id, comments);

        daoMock.serviceAppointments.put(sa.Id, sa);

        Test.startTest();
       
        service.processCancelServiceAppoinments(idToWorkOrder, callComments, callCommentsServiceMock);
        Test.stopTest();

        System.assertEquals(sa.status, FSL_ServiceAppointment.CANCELED_STATUS, 'Expect status to be set Canceled');
        System.assertEquals(callCommentsServiceMock.saveWorkOrderCommentsCallCount, 1, 'Expect to reach all the way to saving the comments');
    }
       
    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinments_CancelOnLandlineDispatch_Success() {

 
        ServiceAppointmentDAOMock daoMock = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( daoMock );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        // Need to create some realData to get the Is_BreakDownSA flag set correctly.
        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_LANDLINE);
    
         // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        List<ServiceAppointment> svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c,  Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];

        ServiceAppointment sa ;
        sa = svcAppts[0];
        sa.status = 'Dispatched';
        sa.Resolution_Code__c = '';

        Id parentId = sa.ParentRecordId;

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];
        
        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
 
        List<String> comments = new List<String>();
        comments.add('This call needs to be cancelled');

        Map<Id, List<String>> callComments = new Map<Id, List<String>>();
        callComments.put(wo1.Id, comments);

        daoMock.serviceAppointments.put(sa.Id, sa);

        Test.startTest();
       
        service.processCancelServiceAppoinments(idToWorkOrder, callComments, callCommentsServiceMock);
        Test.stopTest();

        System.assertEquals(sa.status, FSL_ServiceAppointment.CANCELED_STATUS, 'Expect status to be set Canceled and not auto Cleared');
        System.assertEquals(sa.Resolution_Code__c, '', 'Expect Resolution Code to be not set');
        System.assertEquals(callCommentsServiceMock.saveWorkOrderCommentsCallCount, 1, 'Expect to reach all the way to saving the comments');
    }


    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinment_NoMatchingSAs_NoAction() {
 
        ServiceAppointmentDAOMock daoMock = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( daoMock );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        // Need to create some realData to get the Is_BreakDownSA flag set correctly.
        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
         // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        List<ServiceAppointment> svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Servicing_Technology_Type__c,ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];

        ServiceAppointment sa ;
        sa = svcAppts[0];
        sa.status = 'En Route';

        Id parentId = sa.ParentRecordId;

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];
        
        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
 
        List<String> comments = new List<String>();
        comments.add('This call needs to be cancelled');

        Map<Id, List<String>> callComments = new Map<Id, List<String>>();
        callComments.put(wo1.Id, comments);

        //daoMock.serviceAppointments.put(sa.Id, sa);

        Test.startTest();
        service.processCancelServiceAppoinments(idToWorkOrder, callComments, callCommentsServiceMock);
        Test.stopTest();

        System.assertNotEquals(sa.status, FSL_ServiceAppointment.CANCELED_STATUS, 'Expect status to be Unchanged');
        System.assertEquals(daoMock.updateRecordsCount, 0, 'Expect No calls made to Update Records ');
        System.assertEquals(callCommentsServiceMock.saveWorkOrderCommentsCallCount, 0, 'Expect No call to the CalCommentsService');
    }


    @IsTest
    public static void testServiceAppointmentService_ProcessCancelServiceAppoinments_InvalidCallStateToCancel_UpdateWorkOrderDMLExceptionThrown() {

        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
        FSL_ServiceAppointment.IServiceAppointmentService service = new FSL_ServiceAppointment.ServiceAppointmentService( dao );
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);

        // Need this SOQL to get the formula field correctly set in the input
        Id saId = daoDataHolder.breakDownSAs[0].Id;
        List<ServiceAppointment> svcAppts = [SELECT Id, Status, Resolution_Code__c, isBreakdown__c, Servicing_Technology_Type__c,ParentRecordId FROM ServiceAppointment WHERE Id =:saId ];

        ServiceAppointment sa ;
        sa = svcAppts[0];
        sa.status = 'Tow Loaded';

        Id parentId = sa.ParentRecordId;

        List<WorkOrder> workOrders = [SELECT Id, Servicing_Technology_Type__c FROM WorkOrder WHERE Id = :parentId];
        WorkOrder wo1 = workOrders[0];

        Map <Id, WorkOrder> idToWorkOrder = new Map<Id, WorkOrder>();
        idToWorkOrder.put(wo1.Id, wo1);
        dao.serviceAppointments.put(sa.Id, sa);

        dao.throwDMLExceptionOnWrite = true;
        Test.startTest();
        try 
        {
            service.processCancelServiceAppoinments(idToWorkOrder, null, null);
            System.assert(false);
        }
        catch (DmlException ex)
        {
        
        }
        system.assert(true,  'Should reach here after having caught the DML Exception');
        Test.stopTest();
    }






    // *********************************************
    // * Domain: BreakdownServiceAppointment
    // *********************************************
    @IsTest
    public static void testBreakdownServiceAppointment_GetServiceAppointment_InjectedInConstructor_SameValue() {
        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointment.BreakdownServiceAppointment breakdownServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment( sa, null );

        System.assertEquals( sa, breakdownServiceAppointment.getServiceAppointment() );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_GetServiceAppointmentType_BREAKDOWN() {
        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointment.BreakdownServiceAppointment breakdownServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment( sa, null );

        System.assertEquals( FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN, breakdownServiceAppointment.getServiceAppointmentType() );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_HasAddressChanged_AddressChangeCounterNull_False() {
        testBreakdownServiceAppointment_HasAddressChanged( null, false );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_HasAddressChanged_AddressChangeCounterZero_False() {
        testBreakdownServiceAppointment_HasAddressChanged( 0, false );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_HasAddressChanged_AddressChangeCounterOne_True() {
        testBreakdownServiceAppointment_HasAddressChanged( 1, true );
    }

    private static void testBreakdownServiceAppointment_HasAddressChanged( Double addressChangeCounter, Boolean expected ) {
        ServiceAppointment sa = new ServiceAppointment( Address_Change_Counter__c = addressChangeCounter );
        FSL_ServiceAppointment.BreakdownServiceAppointment breakdownServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment( sa, null );

        System.assertEquals( expected, breakdownServiceAppointment.hasAddressChanged() );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_GetFullAddress_FieldsPopulated_Concatenated() {
        String street = 'Street';
        String city = 'City';
        String state = 'State';
        String postalCode = 'PostalCode';
        String country = 'Country';
        
        String expected = street + ' ' + city + ', ' + state + ' ' + postalCode + ' ' + country;

        testBreakdownServiceAppointment_GetFullAddress( street, city, state, postalCode, country, expected );
    }

    @IsTest
    public static void testBreakdownServiceAppointment_GetFullAddress_FieldsNull_Emtpy() {
        String street = null;
        String city = null;
        String state = null;
        String postalCode = null;
        String country = null;
        
        String expected = '';

        testBreakdownServiceAppointment_GetFullAddress( street, city, state, postalCode, country, expected );
    }

    private static void testBreakdownServiceAppointment_GetFullAddress( String street, String city, String state, String postalCode, String country, String expected ) {
        ServiceAppointment sa = new ServiceAppointment();
        sa.Street = street;
        sa.City = city;
        sa.State = state;
        sa.PostalCode = postalCode;
        sa.Country = country;
        FSL_ServiceAppointment.BreakdownServiceAppointment breakdownServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment( sa, null );

        System.assertEquals( expected, breakdownServiceAppointment.getFullAddress() );
    }

    // *********************************************
    // * Domain: TowServiceAppointment
    // *********************************************
    @IsTest
    public static void testTowServiceAppointment_GetServiceAppointment_InjectedInConstructor_SameValue() {
        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointment.TowServiceAppointment towServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment( sa, null );

        System.assertEquals( sa, towServiceAppointment.getServiceAppointment() );
    }

    @IsTest
    public static void testTowServiceAppointment_GetServiceAppointmentType_TOW() {
        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointment.TowServiceAppointment towServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment( sa, null );

        System.assertEquals( FSL_ServiceAppointment.ServiceAppointmentType.TOW, towServiceAppointment.getServiceAppointmentType() );
    }

    @IsTest
    public static void testTowServiceAppointment_HasAddressChanged_AddressChangeCounterNull_False() {
        testTowServiceAppointment_HasAddressChanged( null, false );
    }

    @IsTest
    public static void testTowServiceAppointment_HasAddressChanged_AddressChangeCounterZero_False() {
        testTowServiceAppointment_HasAddressChanged( 0, false );
    }

    @IsTest
    public static void testTowServiceAppointment_HasAddressChanged_AddressChangeCounterOne_True() {
        testTowServiceAppointment_HasAddressChanged( 1, true );
    }

    private static void testTowServiceAppointment_HasAddressChanged( Double addressChangeCounter, Boolean expected ) {
        ServiceAppointment sa = new ServiceAppointment( Address_Change_Counter__c = addressChangeCounter );
        FSL_ServiceAppointment.TowServiceAppointment towServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment( sa, null );

        System.assertEquals( expected, towServiceAppointment.hasAddressChanged() );
    }

    @IsTest
    public static void testTowServiceAppointment_GetFullAddress_FieldsPopulated_Concatenated() {
        String street = 'Street';
        String city = 'City';
        String state = 'State';
        String postalCode = 'PostalCode';
        String country = 'Country';
        
        String expected = street + ' ' + city + ', ' + state + ' ' + postalCode + ' ' + country;

        testTowServiceAppointment_GetFullAddress( street, city, state, postalCode, country, expected );
    }

    @IsTest
    public static void testTowServiceAppointment_GetFullAddress_FieldsNull_Emtpy() {
        String street = null;
        String city = null;
        String state = null;
        String postalCode = null;
        String country = null;
        
        String expected = '';

        testTowServiceAppointment_GetFullAddress( street, city, state, postalCode, country, expected );
    }

    private static void testTowServiceAppointment_GetFullAddress( String street, String city, String state, String postalCode, String country, String expected ) {
        ServiceAppointment sa = new ServiceAppointment();
        sa.Street = street;
        sa.City = city;
        sa.State = state;
        sa.PostalCode = postalCode;
        sa.Country = country;
        FSL_ServiceAppointment.TowServiceAppointment towServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment( sa, null );

        System.assertEquals( expected, towServiceAppointment.getFullAddress() );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ServiceAppointment.IFactory {
        public FSL_ServiceAppointment.IServiceAppointmentService createService() {
            return new ServiceAppointmentServiceMock();
        }

        public List<FSL_ServiceAppointment.ServiceAppointment> createServiceAppointments( List<Schema.ServiceAppointment> serviceAppointments, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap ) {
            return new List<FSL_ServiceAppointment.ServiceAppointment>();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_ServiceAppointment.IServiceAppointmentService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactoryMock_CreateServiceAppointments_EmptyList() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = factory.createServiceAppointments( null, null );
        Test.stopTest();

        System.assertNotEquals( null, serviceAppointments, 'The Factory returned null' );
        System.assert( serviceAppointments.isEmpty(), 'The Service Appointment List is not empty' );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType SERVICEAPPOINTMENT_TYPE = Schema.ServiceAppointment.getSObjectType();
    public class ServiceAppointmentDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ServiceAppointment.IServiceAppointmentDAO {
        public Map<Id, ServiceAppointment> serviceAppointments;
        public Boolean isSuccess = true;
        public Boolean throwDMLExceptionOnWrite = false;
        public Integer updateRecordsCount = 0;

        public ServiceAppointmentDAOMock() {
            super( new Map<Id, ServiceAppointment>(), SERVICEAPPOINTMENT_TYPE );
            this.serviceAppointments = (Map<Id, ServiceAppointment>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ServiceAppointmentDAOMock' );
            }
        }

        public List<ServiceAppointment> fetchBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds ) {
            isQueryException();
            List<ServiceAppointment> result = new List<ServiceAppointment>();
            for( ServiceAppointment sa : serviceAppointments.values() ) {
                if( workOrderIds.contains( sa.ParentRecordId ) && sa.isBreakdown__c) {
                    result.add( sa );
                }
            }
            return result;
        }

        //ERS-230874 Glympse Removal - Part I
        //public List<ServiceAppointment> fetchServiceAppointmentByGlympseTaskId( Integer glympseTaskId ) {
        //    isQueryException();
        //    List<ServiceAppointment> result = new List<ServiceAppointment>();
        //    for( ServiceAppointment sa : serviceAppointments.values() ) {
        //        if( sa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c == glympseTaskId ) {
        //            result.add( sa );
        //            break; // LIMIT 1
        //        }
        //    }
        //    return result;
        //}

        public List<ServiceAppointment> fetchServiceAppointmentsForWorkOrders(Set<id> woIds ) {
            isQueryException();
            List<ServiceAppointment> result = new List<ServiceAppointment>();
            for( ServiceAppointment sa : serviceAppointments.values() ) {
                if( woIds.contains(sa.ParentRecordId)) {
                    result.add( sa );
                }
            }
            return result;
        }

        public List<Schema.ServiceAppointment> fetchServiceAppointmentsForWorkOrders( Set<Id> workOrderIds, Set<Id> excludedServiceAppointmentIds ) {
            isQueryException();
            List<ServiceAppointment> result = new List<ServiceAppointment>();
            for( ServiceAppointment sa : serviceAppointments.values() ) {
                if( workOrderIds.contains(sa.ParentRecordId) && !excludedServiceAppointmentIds.contains( sa.Id ) ) {
                    result.add( sa );
                }
            }
            return result;
        }

        public List<FSL_Gantt_Icon__mdt> fetchGanttIcons() {
            isQueryException();
            List<FSL_Gantt_Icon__mdt> ganttIcons = new List<FSL_Gantt_Icon__mdt>();
            ganttIcons.add(new FSL_Gantt_Icon__mdt(Icon_Type__c = 'RAP', Image_Name__c = 'FSLGanttRapIcon'));
            ganttIcons.add(new FSL_Gantt_Icon__mdt(Icon_Type__c = 'COD', Image_Name__c = 'FSLGanttCodIcon'));
            return ganttIcons;
        }

        public override void updateRecords(List<SObject> saList) {
            if ( throwDMLExceptionOnWrite) {
                throw new DmlException ('Unable to update WorkOrder Records');
            }
            else {
                super.updateRecords(saList);
                updateRecordsCount++;
            }
        }
        
    }

    @IsTest
    public static void testServiceAppointmentDAOMock_FetchBreakDownServiceAppointmentsForWorkOrders_CorrectRecordsReturned() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();

        DaoDataHolder daoDataHolder = createDaoData(TECHNOLOGY_TYPE_FULL);
    
        // Need this SOQL to get the formula field correctly set in the input
        Set <Id> saIds = new Set<Id>();
        saIds.add(daoDataHolder.breakDownSAs[0].Id);
        saIds.add(daoDataHolder.breakDownSAs[1].Id);
        saIds.add(daoDataHolder.towSAs[0].Id);
        saIds.add(daoDataHolder.towSAs[1].Id);

        List<ServiceAppointment> svcAppts = [SELECT Id, Status, isBreakdown__c, Is_Landline__c, Servicing_Technology_Type__c, ParentRecordId FROM ServiceAppointment WHERE Id in :saIds ];


        dao.serviceAppointments.put( svcAppts[0].Id, svcAppts[0] );
        dao.serviceAppointments.put( svcAppts[1].Id, svcAppts[1] );
        dao.serviceAppointments.put( svcAppts[2].Id, svcAppts[2] );
        dao.serviceAppointments.put( svcAppts[3].Id, svcAppts[3] );

        Id workOrderId1 = svcAppts[0].ParentRecordId;

        Test.startTest();
        List<ServiceAppointment> serviceAppointments = dao.fetchBreakDownServiceAppointmentsForWorkOrders( new Set<Id>{ workOrderId1 } );
        Test.stopTest();

        System.assertEquals( 1, serviceAppointments.size() );
        System.assertEquals( svcAppts[0].Id, serviceAppointments[0].Id );
        System.assertEquals( true, serviceAppointments[0].isBreakdown__c );
        System.assertEquals( workOrderId1, serviceAppointments[0].ParentRecordId );
    }

    @IsTest
    public static void testServiceAppointmentDAOMock_FetchBreakDownServiceAppointmentsForWorkOrders_IsSuccessFalse_ExceptionThrown() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        RecordType breakdownRecordType = new RecordType( Id = dao.Builder.getMockId( Schema.RecordType.getSObjectType() ), Name = 'Breakdown' );
        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1, RecordType = breakdownRecordType );
        dao.serviceAppointments.put( sa1.Id, sa1 );
        dao.isSuccess = false;
        Exception ex = null;

        Test.startTest();
        try {
            List<ServiceAppointment> serviceAppointments = dao.fetchBreakDownServiceAppointmentsForWorkOrders( new Set<Id>{ workOrderId1 } );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }
    //ERS-230874 Glympse Removal - Part I
    //@IsTest
    //public static void testServiceAppointmentDAOMock_FetchServiceAppointmentByGlympseTaskId_CorrectRecordsReturned() {
    //    ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
    //    Integer glympseTaskId1 = 123;
    //    Integer glympseTaskId2 = 456;
    //    Integer glympseTaskId3 = 789;
    //    ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId1 );
    //    ServiceAppointment sa2 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId2 );
    //    ServiceAppointment sa3 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId3 );
    //    dao.serviceAppointments.put( sa1.Id, sa1 );
    //    dao.serviceAppointments.put( sa2.Id, sa2 );
    //    dao.serviceAppointments.put( sa3.Id, sa3 );
    //    Test.startTest();
    //    List<ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentByGlympseTaskId( glympseTaskId2 );
    //    Test.stopTest();
    //    System.assertEquals( 1, serviceAppointments.size() );
    //    System.assertEquals( sa2.Id, serviceAppointments[0].Id );
    //    System.assertEquals( glympseTaskId2, serviceAppointments[0].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c );
    //}

    //@IsTest
    //public static void testServiceAppointmentDAOMock_FetchServiceAppointmentByGlympseTaskId_IsSuccessFalse_ExceptionThrown() {
    //    ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();
    //    Integer glympseTaskId1 = 123;
    //    ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = glympseTaskId1 );
    //    dao.serviceAppointments.put( sa1.Id, sa1 );
    //    dao.isSuccess = false;
    //    Exception ex = null;
    //    Test.startTest();
    //    try {
    //        List<ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentByGlympseTaskId( glympseTaskId1 );
    //    }
    //    catch( Exception e ) {
    //        ex = e;
    //    }
    //    Test.stopTest();
    //    System.assertNotEquals( null, ex );
    //}

    @IsTest
    public static void testServiceAppointmentDAOMock_FetchServiceAppointmentsForWorkOrders_CorrectRecordsReturned() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id workOrderId2 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id workOrderId3 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );

        RecordType breakdownRecordType = new RecordType( Id = dao.Builder.getMockId( Schema.RecordType.getSObjectType() ), Name = 'Breakdown' );
        RecordType towRecordType = new RecordType( Id = dao.Builder.getMockId( Schema.RecordType.getSObjectType() ), Name = 'Tow' );

        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1, RecordType = breakdownRecordType );
        ServiceAppointment sa2 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1, RecordType = towRecordType );
        ServiceAppointment sa3 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId2, RecordType = breakdownRecordType );
        ServiceAppointment sa4 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId2, RecordType = towRecordType );
        ServiceAppointment sa5 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId3, RecordType = breakdownRecordType );
        ServiceAppointment sa6 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId3, RecordType = towRecordType );

        dao.serviceAppointments.put( sa1.Id, sa1 );
        dao.serviceAppointments.put( sa2.Id, sa2 );
        dao.serviceAppointments.put( sa3.Id, sa3 );
        dao.serviceAppointments.put( sa4.Id, sa4 );
        dao.serviceAppointments.put( sa5.Id, sa5 );
        dao.serviceAppointments.put( sa6.Id, sa6 );

        Set<Id> woSetMultiple = new Set<Id> {workOrderId2, workOrderId3 };

        Test.startTest();
        List<ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentsForWorkOrders( woSetMultiple);
        Test.stopTest();

        System.assertEquals( 4, serviceAppointments.size() );
        System.assertEquals( sa3.Id, serviceAppointments[0].Id );
        System.assertEquals( sa4.Id, serviceAppointments[1].Id );
        System.assertEquals( sa5.Id, serviceAppointments[2].Id );
        System.assertEquals( sa6.Id, serviceAppointments[3].Id );
        System.assertEquals( workOrderId2, serviceAppointments[0].ParentRecordId );
        System.assertEquals( workOrderId2, serviceAppointments[1].ParentRecordId );
        System.assertEquals( workOrderId3, serviceAppointments[2].ParentRecordId );
        System.assertEquals( workOrderId3, serviceAppointments[3].ParentRecordId );
    }

    @IsTest
    public static void testServiceAppointmentDAOMock_FetchServiceAppointmentsForWorkOrders_IsSuccessFalse_ExceptionThrown() {
        ServiceAppointmentDAOMock dao = new ServiceAppointmentDAOMock();

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId(), ParentRecordId = workOrderId1 );
        dao.serviceAppointments.put( sa1.Id, sa1 );
        dao.isSuccess = false;
        Exception ex = null;

        Set<Id> woSet = new Set<Id> {workOrderId1 };
        Test.startTest();
        try {
            List<ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentsForWorkOrders( woSet );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ServiceAppointmentServiceMock implements FSL_ServiceAppointment.IServiceAppointmentService {
        //public List<ServiceAppointment> fetchServiceAppointmentsLinkedToWorkOrdersReturnValue = null;
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ServiceAppointmentServiceMock' );
            }
        }

        public Integer getBreakDownServiceAppointmentsForWorkOrdersCallCount = 0;
        public List<ServiceAppointment> getBreakDownServiceAppointmentsForWorkOrdersReturnValue = new List<ServiceAppointment>();
        public List<ServiceAppointment> getBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds ) {
            ++getBreakDownServiceAppointmentsForWorkOrdersCallCount;
            throwExceptionIfConfigured();
            return getBreakDownServiceAppointmentsForWorkOrdersReturnValue;
        }

        public Integer updateActualMilesDrivenCallCount = 0;
        public ServiceAppointment updateActualMilesDrivenReturnValue = null;
        public ServiceAppointment updateActualMilesDriven( Integer glympseTaskId, Decimal actualMilesDriven, FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService ) {
            ++updateActualMilesDrivenCallCount;
            throwExceptionIfConfigured();
            return updateActualMilesDrivenReturnValue;
        }

        public void setGanttIconUrlByType(List<ServiceAppointment> saCollection, Map<Id,WorkOrder> woCollection) {
            throwExceptionIfConfigured();
        }

        public Integer saveD3SyncStatusOfServiceAppointmentChildrenCallCount = 0;
        public void saveD3SyncStatusOfServiceAppointmentChildren(Set<Id> workOrderIds) {
            ++saveD3SyncStatusOfServiceAppointmentChildrenCallCount;
            throwExceptionIfConfigured();
        }

        public Integer syncStatusBetweenRelatedServiceAppointmentsCallCount = 0;
        public void syncStatusBetweenRelatedServiceAppointments( List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments, List<FSL_WO_To_SA_Status_Mapping__mdt> woToSaStatusMapping ) {
            ++syncStatusBetweenRelatedServiceAppointmentsCallCount;
            throwExceptionIfConfigured();
        }

        public Integer processCancelServiceAppoinmentsCallCount = 0;
        public void processCancelServiceAppoinments( Map<Id, WorkOrder> idToWorkOrder, Map<Id, List<String>> cancelComments, FSL_CallComments.ICalLCommentsService callCommentsService) {
            ++processCancelServiceAppoinmentsCallCount;
            throwExceptionIfConfigured();
        }

        public Boolean autoClearable = true;
        public Boolean isAutoClearableOnCancel(ServiceAppointment sa) { 
            return autoClearable;
        }
   
        public Integer updateServiceAppoinmentsCallCount = 0;
        public void updateServiceAppointments(List<ServiceAppointment> toBeUpdatedSAs){
            throwExceptionIfConfigured();
            ++updateServiceAppoinmentsCallCount;
        }

        public Integer handleThirdPartyCallDeclineCallCount = 0;
        public void handleThirdPartyCallDecline(WorkOrder wo, ServiceAppointment brkDnSA, ServiceAppointment towSA, String caseSubject) {
            throwExceptionIfConfigured();
            ++handleThirdPartyCallDeclineCallCount;
        }
    }

    @IsTest
    public static void testServiceAppointmentServiceMock_GetBreakdownServiceAppointmentsForWorkOrders_CallCountIncrementedAndReturnValueReturned() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.getBreakDownServiceAppointmentsForWorkOrdersCallCount;

        List<ServiceAppointment> sa1 = service.getBreakDownServiceAppointmentsForWorkOrders( null );
        Integer callCount1 = service.getBreakDownServiceAppointmentsForWorkOrdersCallCount;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>{ new ServiceAppointment() };
        service.getBreakDownServiceAppointmentsForWorkOrdersReturnValue = serviceAppointments;
        List<ServiceAppointment> sa2 = service.getBreakDownServiceAppointmentsForWorkOrders( null );
        Integer callCount2 = service.getBreakDownServiceAppointmentsForWorkOrdersCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 0, sa1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 1, sa2.size() );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testServiceAppointmentServiceMock_GetBreakdownServiceAppointmentsForWorkOrders_ThrowsException_ExceptionThrown() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.getBreakDownServiceAppointmentsForWorkOrders( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testServiceAppointmentServiceMock_UpdateActualMilesDriven_CallCountIncrementedAndReturnValueReturned() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.updateActualMilesDrivenCallCount;

        ServiceAppointment sa1 = service.updateActualMilesDriven( null, null, null );
        Integer callCount1 = service.updateActualMilesDrivenCallCount;

        ServiceAppointment returnValue = new ServiceAppointment();
        service.updateActualMilesDrivenReturnValue = returnValue;
        ServiceAppointment sa2 = service.updateActualMilesDriven( null, null, null );
        Integer callCount2 = service.updateActualMilesDrivenCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( null, sa1 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( returnValue, sa2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testServiceAppointmentServiceMock_UpdateActualMilesDriven_ThrowsException_ExceptionThrown() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.updateActualMilesDriven( null, null, null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testServiceAppointmentServiceMock_saveD3SyncStatusOfServiceAppointmentChildren_CallCountIncremented() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        Test.startTest();
        Integer callCount0 = service.saveD3SyncStatusOfServiceAppointmentChildrenCallCount;

        service.saveD3SyncStatusOfServiceAppointmentChildren(null);
        Integer callCount1 = service.saveD3SyncStatusOfServiceAppointmentChildrenCallCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );

    }

    @IsTest
    public static void testServiceAppointmentServiceMock_saveD3SyncStatusOfServiceAppointmentChildren_ThrowsException_ExceptionThrown() {
        ServiceAppointmentServiceMock service = new ServiceAppointmentServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.saveD3SyncStatusOfServiceAppointmentChildren(null);
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * DomainMock
    // *********************************************
    public class ServiceAppointmentMock extends FSL_ServiceAppointment.ServiceAppointment {
        public ServiceAppointmentMock() {
            super( null, null );
        }

        public Integer getServiceAppointmentCallCount = 0;
        public Schema.ServiceAppointment getServiceAppointmentReturnValue;
        public override Schema.ServiceAppointment getServiceAppointment() {
            getServiceAppointmentCallCount++;
            return getServiceAppointmentReturnValue;
        }

        public Integer getAssignedResourceCallCount = 0;
        public FSL_AssignedResource.AssignedResource getAssignedResourceReturnValue;
        public override FSL_AssignedResource.AssignedResource getAssignedResource() {
            getAssignedResourceCallCount++;
            return getAssignedResourceReturnValue;
        }

        public Integer getServiceAppointmentTypeCallCount = 0;
        public FSL_ServiceAppointment.ServiceAppointmentType getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN;
        public override FSL_ServiceAppointment.ServiceAppointmentType getServiceAppointmentType() {
            getServiceAppointmentTypeCallCount++;
            return getServiceAppointmentTypeReturnValue;
        }

        public Integer getFullAddressCallCount = 0;
        public String getFullAddressReturnValue = '';
        public override String getFullAddress() {
            getFullAddressCallCount++;
            return getFullAddressReturnValue;
        }

        public Integer hasAddressChangedCallCount = 0;
        public Boolean hasAddressChangedReturnValue = false;
        public override Boolean hasAddressChanged() {
            hasAddressChangedCallCount++;
            return hasAddressChangedReturnValue;
        }

        public Integer syncStatusCallCount = 0;
        public override void syncStatus( FSL_ServiceAppointment.ServiceAppointment relatedAppointment, Map<String, String> breakdownStatusToTowStatusMap ) {
            syncStatusCallCount++;
        }
    }
}