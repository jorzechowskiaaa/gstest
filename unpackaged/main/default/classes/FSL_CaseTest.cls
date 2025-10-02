@istest
public with sharing class FSL_CaseTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_Case.IFactory factory = new FSL_Case.Factory();

        Test.startTest();
        FSL_Case.ICaseService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
        Integer recordCount = 2;
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
        }
        insert workOrders;

        List<Case> cases = new List<Case>();
        for( WorkOrder workOrder : workOrders ) {
            Case c1 = FSL_DataFactory.createCase( 'Clear Queue Failure' );
            c1.FSL_Work_Order__c = workOrder.Id;
            cases.add( c1 );

            Case c2 = FSL_DataFactory.createCase( 'Manual Service Order' );
            c2.FSL_Work_Order__c = workOrder.Id;
            cases.add( c2 );
        }
        insert cases;

    }

    @IsTest
    public static void testCaseDAO_FetchCasesForWorkOrders_CorrectRecordsReturned() {
        createDaoData();
        FSL_Case.ICaseDAO dao = new FSL_Case.CaseDAO();
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        String recordType = 'Clear Queue Failure';
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( recordType ).getRecordTypeId();

        System.assertEquals( 2, workOrders.size() );

        Test.startTest();
        List<Case> cases = dao.fetchCasesForWorkOrders( new Set<Id>{ workOrders[0].Id }, recordType );
        Test.stopTest();

        System.assertEquals( 1, cases.size() );
        System.assertEquals( recordTypeId, cases[0].RecordTypeId );
        System.assertEquals( workOrders[0].Id, cases[0].FSL_Work_Order__c );
    }
    
    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testCaseService_OpenClearQueueFailureCase_ClearQueueFailureCaseExists_ManualServiceOrderCaseCreated() {
        CaseDAOMock dao = new CaseDAOMock();
        FSL_GroupTest.GroupServiceMock groupService = new FSL_GroupTest.GroupServiceMock();
        FSL_Case.ICaseService service = new FSL_Case.CaseService( dao, groupService );

        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        WorkOrder w = new WorkOrder( Id = workOrderId, ServiceTerritoryId = dao.Builder.getMockId( Schema.ServiceTerritory.getSObjectType() ) );

        Id clearQueueFailureRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( 'Clear Queue Failure' ).getRecordTypeId();
        dao.recordTypes.put( 'Clear Queue Failure', clearQueueFailureRecordTypeId );
        Case c = new Case( Id = dao.Builder.getMockId(), RecordTypeId = clearQueueFailureRecordTypeId, FSL_Work_Order__c = workOrderId );
        dao.cases.put( c.Id, c );

        Group g = new Group( Id = dao.Builder.getMockId( Schema.Group.getSObjectType() ) );
        groupService.getGroupForClearQueueCaseOwnershipReturnValue = g;

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersForClearingReturnValue = new List<WorkOrder>{ w };

        Id manualServiceOrderRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( 'Manual Service Order' ).getRecordTypeId();

        System.assertEquals( 1, dao.cases.size() );
        
        Test.startTest();
        service.openClearQueueFailureCase( workOrderId, workOrderService );
        Test.stopTest();

        System.assertEquals( 1, workOrderService.getWorkOrdersForClearingCallCount );
        System.assertEquals( 1, groupService.getGroupForClearQueueCaseOwnershipCallCount );
        System.assertEquals( 2, dao.cases.size() );
        System.assertEquals( manualServiceOrderRecordTypeId, dao.cases.values()[dao.cases.size() - 1].RecordTypeId );
        System.assertEquals( w.ServiceTerritoryId, dao.cases.values()[dao.cases.size() - 1].FSL_Primary_Service_Territory__c );
        System.assertEquals( w.Id, dao.cases.values()[dao.cases.size() - 1].FSL_Work_Order__c );
    }
    
    @IsTest
    public static void testCaseService_OpenClearQueueFailureCase_NoClearQueueFailureCaseExists_ClearQueueFailureCaseCreated() {
        CaseDAOMock dao = new CaseDAOMock();
        FSL_GroupTest.GroupServiceMock groupService = new FSL_GroupTest.GroupServiceMock();
        FSL_Case.ICaseService service = new FSL_Case.CaseService( dao, groupService );

        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        WorkOrder w = new WorkOrder( Id = workOrderId, ServiceTerritoryId = dao.Builder.getMockId( Schema.ServiceTerritory.getSObjectType() ) );

        Group g = new Group( Id = dao.Builder.getMockId( Schema.Group.getSObjectType() ) );
        groupService.getGroupForClearQueueCaseOwnershipReturnValue = g;

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersForClearingReturnValue = new List<WorkOrder>{ w };

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( 'Clear Queue Failure' ).getRecordTypeId();

        System.assertEquals( 0, dao.cases.size() );

        Test.startTest();
        service.openClearQueueFailureCase( workOrderId, workOrderService );
        Test.stopTest();

        System.assertEquals( 1, workOrderService.getWorkOrdersForClearingCallCount );
        System.assertEquals( 1, groupService.getGroupForClearQueueCaseOwnershipCallCount );
        System.assertEquals( 1, dao.cases.size() );
        System.assertEquals( recordTypeId, dao.cases.values()[dao.cases.size() - 1].RecordTypeId );
        System.assertEquals( w.ServiceTerritoryId, dao.cases.values()[dao.cases.size() - 1].FSL_Primary_Service_Territory__c );
        System.assertEquals( w.Id, dao.cases.values()[dao.cases.size() - 1].FSL_Work_Order__c );
    }
    
    @IsTest
    public static void testCaseService_OpenClearQueueFailureCase_NoWorkOrdersFound_ExceptionLogged() {
        CaseDAOMock dao = new CaseDAOMock();
        FSL_GroupTest.GroupServiceMock groupService = new FSL_GroupTest.GroupServiceMock();
        FSL_Case.ICaseService service = new FSL_Case.CaseService( dao, groupService );

        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        WorkOrder w = new WorkOrder( Id = workOrderId, ServiceTerritoryId = dao.Builder.getMockId( Schema.ServiceTerritory.getSObjectType() ) );

        Group g = new Group( Id = dao.Builder.getMockId( Schema.Group.getSObjectType() ) );
        groupService.getGroupForClearQueueCaseOwnershipReturnValue = g;

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersForClearingReturnValue = new List<WorkOrder>();

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Clear Queue Failure').getRecordTypeId();

        Test.startTest();
        service.openClearQueueFailureCase( workOrderId, workOrderService );
        Test.stopTest();

        System.assertEquals( 1, workOrderService.getWorkOrdersForClearingCallCount );
        System.assertEquals( 0, groupService.getGroupForClearQueueCaseOwnershipCallCount );
        System.assertEquals( 0, dao.cases.size() );
    }

    @IsTest
    public static void testCaseService_OpenClearQueueProcessingHaltedCase_CaseCreated() {
        CaseDAOMock dao = new CaseDAOMock();
        FSL_GroupTest.GroupServiceMock groupService = new FSL_GroupTest.GroupServiceMock();
        FSL_Case.ICaseService service = new FSL_Case.CaseService( dao, groupService );

        Group g = new Group( Id = dao.Builder.getMockId( Schema.Group.getSObjectType() ) );
        groupService.getGroupForClearQueueCaseOwnershipReturnValue = g;

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( 'Clear Queue Processing Halted' ).getRecordTypeId();

        System.assertEquals( 0, dao.cases.size() );

        Test.startTest();
        service.openClearQueueProcessingHaltedCase();
        Test.stopTest();

        System.assertEquals( 1, groupService.getGroupForClearQueueCaseOwnershipCallCount );
        System.assertEquals( 1, dao.cases.size() );
        System.assertEquals( recordTypeId, dao.cases.values()[0].RecordTypeId );
    } 


    private static void createLandLineCallData() {

    }

    @IsTest
    public static void testCaseService_thirdPartyDeclineCase_Nominal_DeclineCaseCreated() {
        CaseDAOMock dao = new CaseDAOMock();
        FSL_Group.IGroupService groupService= new FSL_Group.Factory().createService();
        FSL_Case.ICaseService caseService = new FSL_Case.CaseService(dao,groupService);

        string caseSubject ='Towbook Decline';
        workorder wo = new workorder(Id = dao.Builder.getMockId(Schema.WorkOrder.getSObjectType()) );
        ServiceTerritory st = new ServiceTerritory(Id = dao.Builder.getMockId(Schema.ServiceTerritory.getSObjectType()) );
        
        ServiceAppointment sa = new ServiceAppointment(Id = dao.Builder.getMockId(Schema.ServiceAppointment.getSObjectType()), ParentRecordId = wo.Id ,ServiceTerritoryId = st.id);
        Test.startTest();
        caseService.thirdPartyDeclineCase(wo, sa, null, caseSubject);
        Test.stopTest();
        //Case declineCase=[Select Id,Subject From Case Where FSL_Work_Order__c=:wo.Id Limit 1];
       // System.debug('cases='+dao.cases.values());
        System.assertEquals(1,dao.cases.size());
        //fetchCasesForWorkOrders( Set<Id> workOrders,  'Declined_Work' );
    }

    

    
    // @IsTest
    // public static void testCaseService_OpenLandLineCallCanceledCase_CaseCreated() {

    //     CaseDAOMock dao = new CaseDAOMock();
    //     FSL_GroupTest.GroupServiceMock groupService = new FSL_GroupTest.GroupServiceMock();
    //     FSL_Case.ICaseService service = new FSL_Case.CaseService( dao, groupService );

    //     Group g = new Group( Id = dao.Builder.getMockId( Schema.Group.getSObjectType() ) );
    //     groupService.getGroupForLandLineCallCanceledReturnValue = g;

    //     Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( 'Landline Call Cancellation' ).getRecordTypeId();

    //     System.assertEquals( 0, dao.cases.size() );


    //     Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
    //     WorkOrder workOrder = new WorkOrder( Id = workOrderId, ServiceTerritoryId = dao.Builder.getMockId( Schema.ServiceTerritory.getSObjectType() ) );
    //     List<WorkOrder> workOrders = new List<WorkOrder>();

    //     Id accountId = dao.Builder.getMockId( Schema.Account.getSObjectType() );
    //     Account acc = new  Account( Name = 'LandLine-Inc' );

    //     Id contactId = dao.Builder.getMockId( Schema.Contact.getSObjectType() );
    //     Contact c = new Contact( Id = contactId, LastName = 'LandLine-Inc-POC' ); 

    //     Id svcApptId = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() );
    //     ServiceAppointment svcAppt = new ServiceAppointment(Id = svcApptId, ParentRecordID = workOrderId, contactID = contactId);
    //     Map<Id, ServiceAppointment> serviceAppointmentsMap = new Map<Id, ServiceAppointment>();

    //     workOrder.accountId = accountId;
    //     workOrder.contactId = contactId;

    //     workOrders.add(workOrder);
    //     serviceAppointmentsMap.put(workOrderId, svcAppt);

    //     Test.startTest();
    //     service.openLandLineCallCanceledCase(workOrders, serviceAppointmentsMap);
    //     Test.stopTest();

    //     System.assertEquals( 1, groupService.getGroupForLandLineCallCanceledCallCount );
    //     System.assertEquals( 1, dao.cases.size() );

    //     Case cancelCase = dao.cases.values()[0];
    //     System.assertEquals( recordTypeId, cancelCase.RecordTypeId );
    //     System.assertEquals( svcApptId, cancelCase.FSL_Service_Appointment__c );
    //     System.assertEquals( workOrderId, cancelCase.FSL_Work_Order__c );
    //     System.assertEquals( contactId, cancelCase.contactId );
    //     System.assertEquals( 'The member has cancelled the call.', cancelCase.Description );
        
    //     System.assertEquals(true, cancelCase.subject.contains('Landline Service Order Canceled'));


    // } 
    
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_Case.IFactory {
        public FSL_Case.ICaseService createService() {
            return new CaseServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_Case.ICaseService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType CASE_TYPE = Schema.Case.getSObjectType();
    public class CaseDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Case.ICaseDAO {
        public Map<Id, Case> cases;
        public Map<String, Id> recordTypes;
        public Boolean isSuccess = true;

        public CaseDAOMock() {
            super( new Map<Id, Case>(), CASE_TYPE );
            this.cases = (Map<Id, Case>)super.Records;
            this.recordTypes = new Map<String, Id>();
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from CaseDAOMock' );
            }
        }

        public List<Case> fetchCasesForWorkOrders( Set<Id> workOrderIds, String recordType ) {
            isQueryException();
            List<Case> result = new List<Case>();

            Id recordTypeId = recordTypes.get( recordType );
            for( Case c : cases.values() ) {
                if( workOrderIds.contains( c.FSL_Work_Order__c ) && c.RecordTypeId == recordTypeId ) {
                    result.add( c );
                }
            }
            
            return result;
        }
        public List<Case> fetchCasesForCallMover(Set<Id> CaseIDs){
            return null ;
        }
    }

    @IsTest
    public static void testCaseDAOMock_FetchCasesForWorkOrder_CorrectRecordsReturned() {
        CaseDAOMock dao = new CaseDAOMock();

        Id recordTypeId1 = dao.Builder.getMockId( Schema.RecordType.getSObjectType() );
        String recordType1 = 'Record Type 1';
        Id recordTypeId2 = dao.Builder.getMockId( Schema.RecordType.getSObjectType() );
        String recordType2 = 'Record Type 2';
        Id recordTypeId3 = dao.Builder.getMockId( Schema.RecordType.getSObjectType() );
        String recordType3 = 'Record Type 3';
        dao.recordTypes.put( recordType1, recordTypeId1 );
        dao.recordTypes.put( recordType2, recordTypeId2 );
        dao.recordTypes.put( recordType3, recordTypeId3 );

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id workOrderId2 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        
        Case c1 = new Case( Id = dao.Builder.getMockId(), RecordTypeId = recordTypeId1, FSL_Work_Order__c = workOrderId1 );
        Case c2 = new Case( Id = dao.Builder.getMockId(), RecordTypeId = recordTypeId2, FSL_Work_Order__c = workOrderId1 );
        Case c3 = new Case( Id = dao.Builder.getMockId(), RecordTypeId = recordTypeId3, FSL_Work_Order__c = workOrderId1 );
        Case c4 = new Case( Id = dao.Builder.getMockId(), RecordTypeId = recordTypeId2, FSL_Work_Order__c = workOrderId2 );
        dao.cases.put( c1.Id, c1 );
        dao.cases.put( c2.Id, c2 );
        dao.cases.put( c3.Id, c3 );
        dao.cases.put( c4.Id, c4 );

        Test.startTest();
        List<Case> cases = dao.fetchCasesForWorkOrders( new Set<Id>{ workOrderId1 }, recordType2 );
        Test.stopTest();

        System.assertEquals( 1, cases.size() );
        System.assertEquals( c2.Id, cases[0].Id );
        System.assertEquals( recordTypeId2, cases[0].RecordTypeId );
        System.assertEquals( workOrderId1, cases[0].FSL_Work_Order__c );
    }

    @IsTest
    public static void testCaseDAOMock_FetchCasesForWorkOrder_IsException_ExceptionThrown() {
        CaseDAOMock dao = new CaseDAOMock();

        Id recordTypeId1 = dao.Builder.getMockId( Schema.RecordType.getSObjectType() );
        String recordType1 = 'Record Type 1';
        dao.recordTypes.put( recordType1, recordTypeId1 );

        Id workOrderId1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        
        Case c1 = new Case( Id = dao.Builder.getMockId(), RecordTypeId = recordTypeId1, FSL_Work_Order__c = workOrderId1 );
        dao.cases.put( c1.Id, c1 );
        dao.isSuccess = false;

        Exception ex = null;

        Test.startTest();
        try {
            List<Case> cases = dao.fetchCasesForWorkOrders( new Set<Id>{ workOrderId1 }, recordType1 );
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
    public class CaseServiceMock implements FSL_Case.ICaseService {
        public Integer openClearQueueFailureCaseCallCount = 0;
        public Integer openClearQueueProcessingHaltedCaseCallCount = 0;
        public Integer openLandLineCallCanceledCaseCallCount = 0;
        public Integer thirdPartDeclineCaseCallCount = 0;
        public Boolean throwsException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in CaseServiceMock' );
            }
        }

        public void openClearQueueFailureCase( Id workOrderId, FSL_WorkOrder.IWorkOrderService workOrderService ) {
            ++openClearQueueFailureCaseCallCount;
            throwExceptionIfConfigured();
        }

        public void openClearQueueProcessingHaltedCase() {
            ++openClearQueueProcessingHaltedCaseCallCount;
            throwExceptionIfConfigured();
        }

        public void thirdPartyDeclineCase(WorkOrder wo, ServiceAppointment brkDnSA, ServiceAppointment towSA,  String caseSubject) {
            ++thirdPartDeclineCaseCallCount;
            throwExceptionIfConfigured();
        }
        public Id getrectypeIdbyDeveloperName(String rectypeDeveloperName){
            return null;
        }

        //public void openLandLineCallCanceledCase(List<WorkOrder> workOrders, Map<Id, ServiceAppointment> svcAppt) {
        //    ++openLandLineCallCanceledCaseCallCount;
        //    throwExceptionIfConfigured();
        //}
        public Case getCallMoverCase(Id caseId){
            return null ;
        }
    }

    @IsTest
    public static void testCaseServiceMock_OpenClearQueueFailureCase_CallCountIncremented() {
        CaseServiceMock service = new CaseServiceMock();
        
        System.assertEquals( 0, service.openClearQueueFailureCaseCallCount );

        Test.startTest();
        service.openClearQueueFailureCase( null, null );
        Integer callCount1 = service.openClearQueueFailureCaseCallCount;

        service.openClearQueueFailureCase( null, null );
        Integer callCount2 = service.openClearQueueFailureCaseCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testCaseServiceMock_OpenClearQueueFailureCase_ThrowsException_ExceptionThrown() {
        CaseServiceMock service = new CaseServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.openClearQueueFailureCaseCallCount );

        Test.startTest();
        try {
            service.openClearQueueFailureCase( null, null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.openClearQueueFailureCaseCallCount );
    }

    @IsTest
    public static void testCaseServiceMock_OpenClearQueueProcessingHaltedCase_NoException_CallCountIncremented() {
        CaseServiceMock service = new CaseServiceMock();
        
        System.assertEquals( 0, service.openClearQueueProcessingHaltedCaseCallCount );

        Test.startTest();
        service.openClearQueueProcessingHaltedCase();
        Integer callCount1 = service.openClearQueueProcessingHaltedCaseCallCount;

        service.openClearQueueProcessingHaltedCase();
        Integer callCount2 = service.openClearQueueProcessingHaltedCaseCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testCaseServiceMock_OpenClearQueueProcessingHaltedCase_Exception_ExceptionThrownAndCallCountIncremented() {
        CaseServiceMock service = new CaseServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.openClearQueueProcessingHaltedCaseCallCount );

        Test.startTest();
        try {
            service.openClearQueueProcessingHaltedCase();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.openClearQueueProcessingHaltedCaseCallCount );
    }

    // @IsTest
    // public static void testCaseServiceMock_OpenLandLineCallCanceledCase_NoException_CallCountIncremented() {
    //     CaseServiceMock service = new CaseServiceMock();
        
    //     System.assertEquals( 0, service.openLandLineCallCanceledCaseCallCount );

    //     Test.startTest();
    //     service.openLandLineCallCanceledCase(null, null);
    //     Integer callCount1 = service.openLandLineCallCanceledCaseCallCount;

    //     service.openLandLineCallCanceledCase(null, null);
    //     Integer callCount2 = service.openLandLineCallCanceledCaseCallCount;
    //     Test.stopTest();

    //     System.assertEquals( 1, callCount1 );
    //     System.assertEquals( 2, callCount2 );
    // }

    // @IsTest
    // public static void testCaseServiceMock_OpenLandLineCallCanceledCase_Exception_ExceptionThrownAndCallCountIncremented() {
    //     CaseServiceMock service = new CaseServiceMock();
    //     service.throwsException = true;
    //     Exception ex = null;

    //     System.assertEquals( 0, service.openLandLineCallCanceledCaseCallCount );

    //     Test.startTest();
    //     try {
    //         service.openLandLineCallCanceledCase(null, null);
    //     }
    //     catch( Exception e ) {
    //         ex = e;
    //     }
    //     Test.stopTest();

    //     System.assertNotEquals( null, ex );
    //     System.assertEquals( 1, service.openLandLineCallCanceledCaseCallCount );
    // }
    @IsTest
    private static void test_getPTAFromCaseAppointmentAsOrgTime(){
        createDaoData(); 
        Case testCase = [SELECT ID FROM Case Limit 1][0];
        
        testCase.ACG_Requested_Appointment_Date__c = Date.today() - 1 ; 
        testCase.ACG_Requested_Appointment_Time__c = '07:00 PM' ; 
        testCase.Member_Location_TZ_Offset__c = 'UTC+06:00' ; 

        update testCase ; 

        Test.startTest(); 
        Datetime dt = FSL_Case.getPTAFromCaseAppointmentAsOrgTime(testCase); 
        Test.stopTest() ; 
        System.assertEquals(Datetime.now().date() -1 , dt.date() );
    }
}