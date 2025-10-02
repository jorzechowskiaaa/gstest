@isTest
public inherited sharing class FSL_OptimizationDataTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_OptimizationData.IFactory factory = new FSL_OptimizationData.Factory();

        Test.startTest();
        FSL_OptimizationData.IOptimizationDataService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @isTest
    public static void testOptimizationDataDAO_GetOptimizationDataForOwnerId_CorrectNumberOfItemsReturned() {
        List<FSL__Optimization_Data__c> datas = new List<FSL__Optimization_Data__c>();
        datas.add( new FSL__Optimization_Data__c() );
        datas.add( new FSL__Optimization_Data__c() );
        datas.add( new FSL__Optimization_Data__c() );
        insert datas;
        
        FSL_OptimizationData.IOptimizationDataDAO dao = new FSL_OptimizationData.OptimizationDataDAO();

        Set<Id> ids = new Set<Id>{ datas[1].Id };

        Test.startTest();
        List<FSL__Optimization_Data__c> result = dao.getOptimizationDataForId( ids );
        Test.stopTest();

        System.assertEquals( 1, result.size() );
        System.assertEquals( datas[1].Id, result[0].Id );
    }
    
    // *********************************************
    // * Service
    // *********************************************
    @isTest
    public static void testOptimizationDataService_DeleteOptimizationData_GetOptimizationDataByIdReturnsRecords_DeleteRecordsCalled() {
        OptimizationDataDAOMock dao = new OptimizationDataDAOMock();
        FSL_OptimizationData.IOptimizationDataService service = new FSL_OptimizationData.OptimizationDataService( dao );

        FSL__Optimization_Data__c data1 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data2 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        dao.optimizationDatas.put( data1.Id, data1 );
        dao.optimizationDatas.put( data2.Id, data2 );

        Set<Id> ids = new Set<Id>{ data1.Id, data2.Id };

        Test.startTest();
        service.deleteOptimizationData( ids );
        Test.stopTest();

        System.assertEquals( 0, dao.optimizationDatas.size() );
    }

    @isTest
    public static void testOptimizationDataService_DeleteOptimizationData_GetOptimizationDataByIdReturnsNoRecords_DeleteRecordsNotCalled() {
        OptimizationDataDAOMock dao = new OptimizationDataDAOMock();
        FSL_OptimizationData.IOptimizationDataService service = new FSL_OptimizationData.OptimizationDataService( dao );

        FSL__Optimization_Data__c data1 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data2 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        dao.optimizationDatas.put( data1.Id, data1 );
        dao.optimizationDatas.put( data2.Id, data2 );

        Set<Id> ids = new Set<Id>{ dao.Builder.getMockId(), dao.Builder.getMockId() };

        Test.startTest();
        service.deleteOptimizationData( ids );
        Test.stopTest();

        System.assertEquals( 2, dao.optimizationDatas.size() );
    }

    // End-to-End test
    @isTest
    public static void testOptimizationDataService_DeleteOptimizationData_GetOptimizationDataByIdReturnsRecords_RecordsDeleted_EndToEnd() {
        List<FSL__Optimization_Data__c> datas = new List<FSL__Optimization_Data__c>();
        datas.add( new FSL__Optimization_Data__c() );
        datas.add( new FSL__Optimization_Data__c() );
        datas.add( new FSL__Optimization_Data__c() );
        insert datas;

        FSL_OptimizationData.IOptimizationDataDAO dao = new FSL_OptimizationData.OptimizationDataDAO();
        FSL_OptimizationData.IOptimizationDataService service = new FSL_OptimizationData.OptimizationDataService( dao );

        Set<Id> ids = new Set<Id>{ datas[1].Id };

        datas = dao.getOptimizationDataForId( ids );
        System.assertEquals( 1, datas.size() );

        Test.startTest();
        service.deleteOptimizationData( ids );
        Test.stopTest();

        datas = dao.getOptimizationDataForId( ids );
        System.assertEquals( 0, datas.size() );
    }
    
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_OptimizationData.IFactory {
        public FSL_OptimizationData.IOptimizationDataService createService() {
            return new OptimizationDataServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_OptimizationData.IOptimizationDataService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType OPTIMIZATIONDATA_TYPE = FSL__Optimization_Data__c.getSObjectType();
    public class OptimizationDataDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_OptimizationData.IOptimizationDataDAO {
        public Map<Id, FSL__Optimization_Data__c> optimizationDatas;
        public Boolean isSuccess = true;

        public OptimizationDataDAOMock() {
            super( new Map<Id, FSL__Optimization_Data__c>(), OPTIMIZATIONDATA_TYPE );
            this.optimizationDatas = (Map<Id, FSL__Optimization_Data__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from OptimizationDataDAOMock' );
            }
        }

        public List<FSL__Optimization_Data__c> getOptimizationDataForId( Set<Id> ids ) {
            isQueryException();
            List<FSL__Optimization_Data__c> result = new List<FSL__Optimization_Data__c>();
            for( FSL__Optimization_Data__c data : optimizationDatas.values() ) {
                if( ids.contains( data.Id ) ) {
                    result.add( data );
                }
            }
            return result;
        }
    }

    @isTest
    public static void testOptimizationDataDAO_getOptimizationDataForId_Success_CorrectNumberOfItemsReturned() {
        OptimizationDataDAOMock dao = new OptimizationDataDAOMock();

        FSL__Optimization_Data__c data1 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data2 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data3 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data4 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );

        dao.optimizationDatas.put( data1.Id, data1 );
        dao.optimizationDatas.put( data2.Id, data2 );
        dao.optimizationDatas.put( data3.Id, data3 );
        dao.optimizationDatas.put( data4.Id, data4 );

        Test.startTest();
        List<FSL__Optimization_Data__c> datas = dao.getOptimizationDataForId( new Set<Id>{ data2.Id, data3.Id } );
        Test.stopTest();

        System.assertEquals( 2, datas.size() );
        System.assertEquals( data2.Id, datas[0].Id );
        System.assertEquals( data3.Id, datas[1].Id );
    }

    @isTest
    public static void testOptimizationDataDAO_getOptimizationDataForOwnerId_NotSuccess_ExceptionThrown() {
        OptimizationDataDAOMock dao = new OptimizationDataDAOMock();

        FSL__Optimization_Data__c data1 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data2 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data3 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );
        FSL__Optimization_Data__c data4 = new FSL__Optimization_Data__c( Id = dao.Builder.getMockId() );

        dao.optimizationDatas.put( data1.Id, data1 );
        dao.optimizationDatas.put( data2.Id, data2 );
        dao.optimizationDatas.put( data3.Id, data3 );
        dao.optimizationDatas.put( data4.Id, data4 );
        dao.isSuccess = false;
        Exception ex = null;

        Test.startTest();
        try {
            List<FSL__Optimization_Data__c> datas = dao.getOptimizationDataForId( new Set<Id>{ data2.Id, data3.Id } );
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
    public class OptimizationDataServiceMock implements FSL_OptimizationData.IOptimizationDataService {
        public Integer deleteOptimizationDataCallCount = 0;
        public Boolean throwsException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in OptimizationDataServiceMock' );
            }
        }

        public void deleteOptimizationData( Set<Id> ids ) {
            deleteOptimizationDataCallCount++;
            throwExceptionIfConfigured();
        }
    }

    @isTest
    public static void testOptimizationDataServiceMock_DeleteOptimizationData_NoException_CallCountIncremented() {
        OptimizationDataServiceMock service = new OptimizationDataServiceMock();

        System.assertEquals( 0, service.deleteOptimizationDataCallCount );

        Test.startTest();
        service.deleteOptimizationData( new Set<Id>() );
        Test.stopTest();

        System.assertEquals( 1, service.deleteOptimizationDataCallCount );
    }

    @isTest
    public static void testOptimizationDataServiceMock_DeleteOptimizationData_Exception_CallCountIncrementedAndExceptionThrown() {
        OptimizationDataServiceMock service = new OptimizationDataServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.deleteOptimizationDataCallCount );

        Test.startTest();
        try {
            service.deleteOptimizationData( new Set<Id>() );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.deleteOptimizationDataCallCount );
        System.assertNotEquals( null, ex );
    }
}