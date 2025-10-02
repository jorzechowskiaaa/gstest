@IsTest
public with sharing class FSL_AsyncApexJobTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_AsyncApexJob.IFactory factory = new FSL_AsyncApexJob.Factory();

        Test.startTest();
        FSL_AsyncApexJob.IAsyncApexJobService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testAsyncApexJobDAO_FetchJobs_CorrectNumberOfRecordsReturned() {
        // DML Insert is not allowed on AsyncApexJob and selecting jobs returns no items. Test with an empty set.
        FSL_AsyncApexJob.IAsyncApexJobDAO dao = new FSL_AsyncApexJob.AsyncApexJobDAO();
        Set<Id> ids = new Set<Id>();

        Test.startTest();
        List<AsyncApexJob> result = dao.fetchJobs( ids );
        Test.stopTest();

        System.assertEquals( 0, result.size() );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testAsyncApexJobService_GetJob_DaoReturnsSingleRecord_Returned() {
        AsyncApexJobDAOMock dao = new AsyncApexJobDAOMock();
        Id jobId = dao.Builder.getMockId();
        AsyncApexJob expected = new AsyncApexJob( Id = jobId );
        dao.jobs.put( jobId, expected );
        
        FSL_AsyncApexJob.IAsyncApexJobService service = new FSL_AsyncApexJob.AsyncApexJobService( dao );

        Test.startTest();
        AsyncApexJob actual = service.getJob( jobId );
        Test.stopTest();

        System.assertEquals( expected, actual );
    }
    
    @IsTest
    public static void testAsyncApexJobService_GetJob_DaoReturnsNoRecord_Null() {
        AsyncApexJobDAOMock dao = new AsyncApexJobDAOMock();
        Id jobId = dao.Builder.getMockId();
        
        FSL_AsyncApexJob.IAsyncApexJobService service = new FSL_AsyncApexJob.AsyncApexJobService( dao );

        Test.startTest();
        AsyncApexJob job = service.getJob( jobId );
        Test.stopTest();

        System.assertEquals( null, job );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_AsyncApexJob.IFactory {
        public FSL_AsyncApexJob.IAsyncApexJobService createService() {
            return new AsyncApexJobServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_AsyncApexJob.IAsyncApexJobService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType ASYNCAPEXJOB_TYPE = Schema.AsyncApexJob.getSObjectType();
    public class AsyncApexJobDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_AsyncApexJob.IAsyncApexJobDAO {
        public Map<Id, AsyncApexJob> jobs;
        public Boolean isSuccess = true;
        
        public AsyncApexJobDAOMock() {
            super( new Map<Id, AsyncApexJob>(), ASYNCAPEXJOB_TYPE );
            this.jobs = (Map<Id, AsyncApexJob>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from AsyncApexJobDAOMock' );
            }
        }

        public List<AsyncApexJob> fetchJobs( Set<Id> ids ) {
            isQueryException();
            List<AsyncApexJob> result = new List<AsyncApexJob>();
            for( Id jobId : ids ) {
                if( jobs.containsKey( jobId ) ) result.add( jobs.get( jobId ) );
            }
            return result;
        }
    }

    @IsTest
    public static void testAsyncApexJobDAOMock_FetchJobs_Success_CorrectNumberOfRecordsReturned() {
        AsyncApexJobDAOMock dao = new AsyncApexJobDAOMock();

        AsyncApexJob job1 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        AsyncApexJob job2 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        AsyncApexJob job3 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        dao.jobs.put( job1.Id, job1 );
        dao.jobs.put( job2.Id, job2 );
        dao.jobs.put( job3.Id, job3 );

        Set<Id> jobIds = new Set<Id>{ job1.Id, job3.Id, dao.Builder.getMockId() };

        Test.startTest();
        List<AsyncApexJob> jobs = dao.fetchJobs( jobIds );
        Test.stopTest();

        System.assertEquals( 2, jobs.size() );
        System.assert( jobIds.contains( jobs[0].Id ) );
        System.assert( jobIds.contains( jobs[1].Id ) );
    }

    @IsTest
    public static void testAsyncApexJobDAOMock_FetchJobs_NotSuccess_ExceptionThrown() {
        AsyncApexJobDAOMock dao = new AsyncApexJobDAOMock();

        AsyncApexJob job1 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        AsyncApexJob job2 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        AsyncApexJob job3 = new AsyncApexJob( Id = dao.Builder.getMockId() );
        dao.jobs.put( job1.Id, job1 );
        dao.jobs.put( job2.Id, job2 );
        dao.jobs.put( job3.Id, job3 );

        Set<Id> jobIds = new Set<Id>{ job1.Id, job3.Id, dao.Builder.getMockId() };

        dao.isSuccess = false;
        Exception ex = null;

        Test.startTest();
        try {
            dao.fetchJobs( jobIds );
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
    public class AsyncApexJobServiceMock implements FSL_AsyncApexJob.IAsyncApexJobService {
        public Boolean throwsException = false;
        
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in AsyncApexJobServiceMock' );
            }
        }
        
        public Integer getJobCallCount = 0;
        public AsyncApexJob getJobReturnValue = null;
        public AsyncApexJob getJob( Id jobId ) {
            getJobCallCount++;
            throwExceptionIfConfigured();
            return getJobReturnValue;
        }
    }

    @IsTest
    public static void testAsyncApexJobServiceMock_GetJob_NoException_CorrectValueReturnedAndCallCountIncremented() {
        AsyncApexJobServiceMock service = new AsyncApexJobServiceMock();
        AsyncApexJob expectedDefaultValue = null;
        AsyncApexJob expectedUpdatedValue = new AsyncApexJob();

        System.assertEquals( 0, service.getJobCallCount );

        Test.startTest();        
        AsyncApexJob actualDefaultValue = service.getJob( null );
        Integer callCount1 = service.getJobCallCount;

        service.getJobReturnValue = expectedUpdatedValue;
        AsyncApexJob actualUpdatedValue = service.getJob( null );
        Integer callCount2 = service.getJobCallCount;
        Test.stopTest();

        System.assertEquals( expectedDefaultValue, actualDefaultValue );
        System.assertEquals( expectedUpdatedValue, actualUpdatedValue );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testAsyncApexJobServiceMock_GetJob_Exception_CallCountIncrementedAndExceptionThrown() {
        AsyncApexJobServiceMock service = new AsyncApexJobServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.getJobCallCount );

        Test.startTest();
        try {
            service.getJob( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.getJobCallCount );
        System.assertNotEquals( null, ex );
    }
}