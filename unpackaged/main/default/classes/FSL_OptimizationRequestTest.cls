@isTest
public inherited sharing class FSL_OptimizationRequestTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_OptimizationRequest.IFactory factory = new FSL_OptimizationRequest.Factory();

        Test.startTest();
        FSL_OptimizationRequest.IOptimizationRequestService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @isTest
    public static void testOptimizationRequestDAO_GetOptimizationRequestsOlderThanProvidedDate_CorrectNumberOfRecordsReturned() {
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

        FSL_OptimizationRequest.IOptimizationRequestDAO dao = new FSL_OptimizationRequest.OptimizationRequestDAO();

        Test.startTest();
        List<FSL__Optimization_Request__c> result = dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
        Test.stopTest();

        System.assertEquals( 1, result.size() );
        System.assert( result[0].CreatedDate < createdDate );
    }
    
    // *********************************************
    // * Service
    // *********************************************
    @isTest
    public static void testOptimizationRequestService_OnDelete_RelatedOptimizationData_OptimizationDataServiceCalled() {
        OptimizationRequestDAOMock dao = new OptimizationRequestDAOMock();
        FSL_OptimizationDataTest.OptimizationDataServiceMock optimizationDataService = new FSL_OptimizationDataTest.OptimizationDataServiceMock();
        FSL_OptimizationRequest.IOptimizationRequestService service = new FSL_OptimizationRequest.OptimizationRequestService( dao, optimizationDataService );

        FSL__Optimization_Request__c req = new FSL__Optimization_Request__c( Id = dao.Builder.getMockId(), FSL__Optimization_Data__c = dao.Builder.getMockId( FSL__Optimization_Data__c.getSObjectType() ) );

        System.assertEquals( 0, optimizationDataService.deleteOptimizationDataCallCount );

        Test.startTest();
        service.onDelete( new List<FSL__Optimization_Request__c>{ req } );
        Test.stopTest();

        System.assertEquals( 1, optimizationDataService.deleteOptimizationDataCallCount );
    }

    @isTest
    public static void testOptimizationRequestService_OnDelete_NoRelatedOptimizationData_OptimizationDataServiceNotCalled() {
        OptimizationRequestDAOMock dao = new OptimizationRequestDAOMock();
        FSL_OptimizationDataTest.OptimizationDataServiceMock optimizationDataService = new FSL_OptimizationDataTest.OptimizationDataServiceMock();
        FSL_OptimizationRequest.IOptimizationRequestService service = new FSL_OptimizationRequest.OptimizationRequestService( dao, optimizationDataService );

        FSL__Optimization_Request__c req = new FSL__Optimization_Request__c( Id = dao.Builder.getMockId(), FSL__Optimization_Data__c = null );

        System.assertEquals( 0, optimizationDataService.deleteOptimizationDataCallCount );

        Test.startTest();
        service.onDelete( new List<FSL__Optimization_Request__c>{ req } );
        Test.stopTest();

        System.assertEquals( 0, optimizationDataService.deleteOptimizationDataCallCount );
    }

    @isTest
    public static void testOptimizationRequestService_PurgeOldRecords_DaoReturnsRecords_RecordsDeleted() {
        // Since the query is based on CreatedDate, and it's not a writeable field, a 'real' DAO is used instead of a mock
        FSL_OptimizationRequest.IOptimizationRequestDAO dao = new FSL_OptimizationRequest.OptimizationRequestDAO();
        FSL_OptimizationDataTest.OptimizationDataServiceMock optimizationDataService = new FSL_OptimizationDataTest.OptimizationDataServiceMock();
        FSL_OptimizationRequest.IOptimizationRequestService service = new FSL_OptimizationRequest.OptimizationRequestService( dao, optimizationDataService );

        FSL__Optimization_Request__c request1 = new FSL__Optimization_Request__c();
        FSL__Optimization_Request__c request2 = new FSL__Optimization_Request__c();
        FSL__Optimization_Request__c request3 = new FSL__Optimization_Request__c();
        List<FSL__Optimization_Request__c> requests = new List<FSL__Optimization_Request__c>{ request1, request2, request3 };
        insert requests;

        Integer daysToRetain = 12;
        Integer maxRecords = 23;
        Date createdDate = Date.today().addDays( -daysToRetain );
        Datetime createdDatetime = Datetime.newInstance( createdDate.year(), createdDate.month(), createdDate.day(), 13, 14, 15 );
        Test.setCreatedDate( request1.Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( request2.Id, createdDatetime );
        Test.setCreatedDate( request3.Id, createdDatetime.addDays( 1 ) );
        
        requests = dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
        System.assertEquals( 1, requests.size() );

        Test.startTest();
        service.purgeOldRecords( daysToRetain, maxRecords );
        Test.stopTest();

        requests = dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
        System.assertEquals( 0, requests.size() );
    }
    
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_OptimizationRequest.IFactory {
        public FSL_OptimizationRequest.IOptimizationRequestService createService() {
            return new OptimizationRequestServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_OptimizationRequest.IOptimizationRequestService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType OPTIMIZATIONREQUEST_TYPE = FSL__Optimization_Request__c.getSObjectType();
    public class OptimizationRequestDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_OptimizationRequest.IOptimizationRequestDAO {
        public Map<Id, FSL__Optimization_Request__c> optimizationRequests;
        public Boolean isSuccess = true;

        public OptimizationRequestDAOMock() {
            super( new Map<Id, FSL__Optimization_Request__c>(), OPTIMIZATIONREQUEST_TYPE );
            this.optimizationRequests = (Map<Id, FSL__Optimization_Request__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from OptimizationRequestDAOMock' );
            }
        }

        public List<FSL__Optimization_Request__c> getOptimizationRequestsOlderThanProvidedDate( Date createdDate ) {
            isQueryException();
            List<FSL__Optimization_Request__c> result = new List<FSL__Optimization_Request__c>();
            for( FSL__Optimization_Request__c request : optimizationRequests.values() ) {
                if( request.CreatedDate < createdDate ) {
                    result.add( request );
                }
            }
            return result;
        }
    }

    @isTest
    public static void testOptimizationRequestDAOMock_GetOptimizationRequestsOlderThanProvidedDate_Success_CorrectNumberOfRecordsReturned() {
        OptimizationRequestDAOMock dao = new OptimizationRequestDAOMock();

        // Since the query is based on CreatedDate, and it's not a writeable field, it's necessary to insert the records in the database before storing them in the DAOMock memory
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
        requests = [SELECT Id, CreatedDate FROM FSL__Optimization_Request__c];

        dao.optimizationRequests.put( requests[0].Id, requests[0] );
        dao.optimizationRequests.put( requests[1].Id, requests[1] );
        dao.optimizationRequests.put( requests[2].Id, requests[2] );

        Test.startTest();
        requests = dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
        Test.stopTest();

        System.assertEquals( 1, requests.size() );
        System.assert( requests[0].CreatedDate < createdDate );
    }

    @isTest
    public static void testOptimizationRequestDAOMock_GetOptimizationRequestsOlderThanProvidedDate_NotSuccess_ExceptionThrown() {
        OptimizationRequestDAOMock dao = new OptimizationRequestDAOMock();

        Datetime createdDatetime = Datetime.newInstance( 2020, 1, 20, 13, 14, 15 );
        FSL__Optimization_Request__c request1 = new FSL__Optimization_Request__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Request__c request2 = new FSL__Optimization_Request__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Request__c request3 = new FSL__Optimization_Request__c( Id = dao.Builder.getMockId() );
        dao.optimizationRequests.put( request1.Id, request1 );
        dao.optimizationRequests.put( request2.Id, request2 );
        dao.optimizationRequests.put( request3.Id, request3 );
        Date createdDate = createdDatetime.date();

        dao.isSuccess = false;
        Exception ex = null;

        Test.startTest();
        try {
            dao.getOptimizationRequestsOlderThanProvidedDate( createdDate );
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
    public class OptimizationRequestServiceMock implements FSL_OptimizationRequest.IOptimizationRequestService {
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in OptimizationRequestServiceMock' );
            }
        }
        
        public Integer onDeleteCallCount = 0;
        public void onDelete( List<FSL__Optimization_Request__c> deletedRecords ) {
            onDeleteCallCount++;
            throwExceptionIfConfigured();
        }

        public Integer purgeOldRecordsCallCount = 0;
        public void purgeOldRecords( Integer daysToRetain, Integer maxRecords ) {
            purgeOldRecordsCallCount++;
            throwExceptionIfConfigured();
        }
    }

    @isTest
    public static void testOptimizationRequestServiceMock_OnDelete_NoException_CallCountIncremented() {
        OptimizationRequestServiceMock service = new OptimizationRequestServiceMock();

        System.assertEquals( 0, service.onDeleteCallCount );

        Test.startTest();
        service.onDelete( new List<FSL__Optimization_Request__c>() );
        Test.stopTest();

        System.assertEquals( 1, service.onDeleteCallCount );
    }

    @isTest
    public static void testOptimizationRequestServiceMock_OnDelete_Exception_CallCountIncrementedAndExceptionThrown() {
        OptimizationRequestServiceMock service = new OptimizationRequestServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.onDeleteCallCount );

        Test.startTest();
        try {
            service.onDelete( new List<FSL__Optimization_Request__c>() );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.onDeleteCallCount );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testOptimizationRequestServiceMock_PurgeOldRecords_NoException_CallCountIncremented() {
        OptimizationRequestServiceMock service = new OptimizationRequestServiceMock();

        System.assertEquals( 0, service.purgeOldRecordsCallCount );

        Test.startTest();
        service.purgeOldRecords( 123, 456 );
        Test.stopTest();

        System.assertEquals( 1, service.purgeOldRecordsCallCount );
    }

    @isTest
    public static void testOptimizationRequestServiceMock_PurgeOldRecords_Exception_CallCountIncrementedAndExceptionThrown() {
        OptimizationRequestServiceMock service = new OptimizationRequestServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.purgeOldRecordsCallCount );

        Test.startTest();
        try {
            service.purgeOldRecords( 123, 456 );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.purgeOldRecordsCallCount );
        System.assertNotEquals( null, ex );
    }
}