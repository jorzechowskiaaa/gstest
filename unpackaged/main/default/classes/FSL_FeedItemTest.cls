@IsTest
public with sharing class FSL_FeedItemTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_FeedItem.IFactory factory = new FSL_FeedItem.Factory();

        Test.startTest();
        FSL_FeedItem.IFeedItemService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
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
        }
        insert workOrders;

        List<FeedItem> feedItems = new List<FeedItem>();
        for( Integer i = 0; i < recordCount; ++i ) {
            feedItems.add( new FeedItem( ParentId = workOrders[i].Id, Type = 'TextPost', Body = 'Body' ) );
            feedItems.add( new FeedItem( ParentId = workOrders[i].Id, Type = 'TextPost', Body = 'Body' ) );
            feedItems.add( new FeedItem( ParentId = workOrders[i].Id, Type = 'AdvancedTextPost', Body = 'Body' ) );
        }
        insert feedItems;
    }

    @IsTest
    public static void testFeedItemDAO_FetchFeedItemsForWorkOrders_CorrectNumberOfRecordsReturned() {
        createDaoData();
        FSL_FeedItem.IFeedItemDAO dao = new FSL_FeedItem.FeedItemDAO();
        List<WorkOrder> insertedWorkOrders = [SELECT Id FROM WorkOrder];

        System.assertEquals( 5, insertedWorkOrders.size() );
        Set<Id> workOrderIds = new Set<Id>{ insertedWorkOrders[2].Id, insertedWorkOrders[3].Id };
        
        Test.startTest();
        List<FeedItem> feedItems = dao.fetchFeedItemsForWorkOrders( workOrderIds );
        Test.stopTest();

        System.assertEquals( 4, feedItems.size() );
        System.assertEquals( insertedWorkOrders[2].Id, feedItems[0].ParentId );
        System.assertEquals( 'TextPost', feedItems[0].Type );
        System.assertEquals( insertedWorkOrders[2].Id, feedItems[1].ParentId );
        System.assertEquals( 'TextPost', feedItems[1].Type );
        System.assertEquals( insertedWorkOrders[3].Id, feedItems[2].ParentId );
        System.assertEquals( 'TextPost', feedItems[2].Type );
        System.assertEquals( insertedWorkOrders[3].Id, feedItems[3].ParentId );
        System.assertEquals( 'TextPost', feedItems[3].Type );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testFeedItemService_GetWorkOrdersForClearing_DAOCalled() {
        FeedItemDAOMock dao = new FeedItemDAOMock();
        FSL_FeedItem.IFeedItemService service = new FSL_FeedItem.FeedItemService( dao );
        
        WorkOrder w1 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder w2 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder w3 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder w4 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder w5 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        
        FeedItem f1 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = w1.Id );
        FeedItem f2 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w1.Id );
        FeedItem f3 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w1.Id );
        FeedItem f4 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w2.Id );
        FeedItem f5 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = w2.Id );
        FeedItem f6 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w2.Id );
        FeedItem f7 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w3.Id );
        FeedItem f8 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = w3.Id );
        FeedItem f9 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = w3.Id );
        dao.feedItems.put( f1.Id, f1 );
        dao.feedItems.put( f2.Id, f2 );
        dao.feedItems.put( f3.Id, f3 );
        dao.feedItems.put( f4.Id, f4 );
        dao.feedItems.put( f5.Id, f5 );
        dao.feedItems.put( f6.Id, f6 );
        dao.feedItems.put( f7.Id, f7 );
        dao.feedItems.put( f8.Id, f8 );
        dao.feedItems.put( f9.Id, f9 );
        
        Set<Id> workOrderIds = new Set<Id>{ w2.Id, w3.Id };        

        Test.startTest();
        Map<Id, List<FeedItem>> feedItems = service.getWorkOrderIdToFeedItemsMap( workOrderIds );
        Test.stopTest();

        System.assertEquals( 2, feedItems.size() );
        System.assertEquals( 2, feedItems.get( w2.Id ).size() );
        System.assertEquals( f4.Id, feedItems.get( w2.Id )[0].Id );
        System.assertEquals( f6.Id, feedItems.get( w2.Id )[1].Id );
        System.assertEquals( 2, feedItems.get( w3.Id ).size() );
        System.assertEquals( f7.Id, feedItems.get( w3.Id )[0].Id );
        System.assertEquals( f8.Id, feedItems.get( w3.Id )[1].Id );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_FeedItem.IFactory {
        public FSL_FeedItem.IFeedItemService createService() {
            return new FeedItemServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FSL_FeedItem.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_FeedItem.IFeedItemService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType FEEDITEM_TYPE = Schema.FeedItem.getSObjectType();
    public class FeedItemDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_FeedItem.IFeedItemDAO {
        public Map<Id, FeedItem> feedItems;
        public Boolean isSuccess = true;

        public FeedItemDAOMock() {
            super( new Map<Id, FeedItem>(), FEEDITEM_TYPE );
            this.feedItems = (Map<Id, FeedItem>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from FeedItemDAOMock' );
            }
        }

        public List<FeedItem> fetchFeedItemsForWorkOrders( Set<Id> workOrderIds ) {
            isQueryException();
            List<FeedItem> result = new List<FeedItem>();
            for( FeedItem f : feedItems.values() ) {
                if( workOrderIds.contains( f.ParentId ) && f.Type == 'TextPost' ) {
                    result.add( f );
                }
            }
            return result;
        }
    }

    @IsTest
    public static void testFeedItemDAOMock_FetchFeedItemsForWorkOrders_CorrectNumberOfRecordsReturned() {
        FeedItemDAOMock dao = new FeedItemDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );

        FeedItem f1 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = workOrder1.Id );
        FeedItem f2 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder1.Id );
        FeedItem f3 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder1.Id );
        FeedItem f4 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder2.Id );
        FeedItem f5 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = workOrder2.Id );
        FeedItem f6 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder2.Id );
        FeedItem f7 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder3.Id );
        FeedItem f8 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder3.Id );
        FeedItem f9 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'Not TextPost', ParentId = workOrder3.Id );
        dao.feedItems.put( f1.Id, f1 );
        dao.feedItems.put( f2.Id, f2 );
        dao.feedItems.put( f3.Id, f3 );
        dao.feedItems.put( f4.Id, f4 );
        dao.feedItems.put( f5.Id, f5 );
        dao.feedItems.put( f6.Id, f6 );
        dao.feedItems.put( f7.Id, f7 );
        dao.feedItems.put( f8.Id, f8 );
        dao.feedItems.put( f9.Id, f9 );
        Set<Id> workOrderIds = new Set<Id>{ workOrder1.Id, workOrder2.Id };

        Test.startTest();
        List<FeedItem> feedItems = dao.fetchFeedItemsForWorkOrders( workOrderIds );
        Test.stopTest();

        System.assertEquals( 4, feedItems.size() );
        System.assertEquals( f2, feedItems[0] );
        System.assertEquals( f3, feedItems[1] );
        System.assertEquals( f4, feedItems[2] );
        System.assertEquals( f6, feedItems[3] );
    }

    @IsTest
    public static void testFeedItemDAOMock_FetchFeedItemsForWorkOrders_IsException_ExceptionThrown() {
        FeedItemDAOMock dao = new FeedItemDAOMock();
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FeedItem f1 = new FeedItem( Id = dao.Builder.getMockId(), Type = 'TextPost', ParentId = workOrder1.Id );
        dao.feedItems.put( f1.Id, f1 );
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<FeedItem> workOrders = dao.fetchFeedItemsForWorkOrders( new Set<Id> { workOrder1.Id } );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class FeedItemServiceMock implements FSL_FeedItem.IFeedItemService {
        public Integer getWorkOrderIdToFeedItemsMapCallCount = 0;
        public Map<Id, List<FeedItem>> getWorkOrderIdToFeedItemsMapReturnValue = new Map<Id, List<FeedItem>>();

        public Map<Id, List<FeedItem>> getWorkOrderIdToFeedItemsMap( Set<Id> workOrderIds ) {
            ++getWorkOrderIdToFeedItemsMapCallCount;
            return getWorkOrderIdToFeedItemsMapReturnValue;
        }
    }

    @IsTest
    public static void testFeedItemServiceMock_GetWorkOrderIdToFeedItemsMap_CorrectValueReturnedAndCallCountIncremented() {
        FeedItemServiceMock service = new FeedItemServiceMock();
        FSL_DAOTest.MockIdGenerator idGen = new FSL_DAOTest.MockIdGenerator( FEEDITEM_TYPE );
        
        Test.startTest();
        Integer callCount0 = service.getWorkOrderIdToFeedItemsMapCallCount;

        Map<Id, List<FeedItem>> feedItems1 = service.getWorkOrderIdToFeedItemsMap( new Set<Id>() );
        Integer callCount1 = service.getWorkOrderIdToFeedItemsMapCallCount;

        Map<Id, List<FeedItem>> expected = new Map<Id, List<FeedItem>>();
        Id workOrderId = idGen.getMockId( Schema.WorkOrder.getSObjectType() );
        expected.put( workOrderId, new List<FeedItem>() );
        service.getWorkOrderIdToFeedItemsMapReturnValue = expected;
        Map<Id, List<FeedItem>> feedItems2 = service.getWorkOrderIdToFeedItemsMap( new Set<Id>{ workOrderId } );
        Integer callCount2 = service.getWorkOrderIdToFeedItemsMapCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 0, feedItems1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, feedItems2 );
        System.assertEquals( 2, callCount2 );
    }
}