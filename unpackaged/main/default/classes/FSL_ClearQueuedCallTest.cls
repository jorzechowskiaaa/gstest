@IsTest
public class FSL_ClearQueuedCallTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_ClearQueuedCall.IFactory factory = new FSL_ClearQueuedCall.Factory();

        Test.startTest();
        FSL_ClearQueuedCall.IClearQueuedCallService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactory_CreateClearQueueProcessingBatch_NotNull() {
        FSL_ClearQueuedCall.IFactory factory = new FSL_ClearQueuedCall.Factory();

        Test.startTest();
        FSL_ClearQueuedCall.IClearQueueProcessingBatch batch = factory.createClearQueueProcessingBatch();
        Test.stopTest();

        System.assertNotEquals( null, batch );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
        Integer recordCount = 7;
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

        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id,  State__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id,  State__c = 'In Progress', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id,  State__c = 'Cleared With Mileage', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id,  State__c = 'Cleared Without Mileage', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[4].Id,  State__c = 'Case Created', Work_Order__c = workOrders[4].Id, Retry_Count__c = 4 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[5].Id,  State__c = 'Pending', Work_Order__c = workOrders[5].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[6].Id,  State__c = 'Pending', Work_Order__c = workOrders[6].Id, Retry_Count__c = 1 ) );
        insert calls;
    }

    @IsTest
    public static void testClearQueuedCallDAO_FetchPendingCalls_FewerRecordsThanMaxWorkOrders_CorrectNumberOfRecordsReturned() {
        Integer recordCount = 9;
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

        // Clear Queued Call data created
        // 1. Pending call but Created Date after earliest --> not queried
        // 2. In Progress --> not queried
        // 3. Cleared With Mileage --> not queried
        // 4. Cleared Without Mileage --> not queried
        // 5. Case Created --> not queried
        // 6. Pending, Mileage Pending, Created Date equals earliest --> queried
        // 7. Pending, Mileage Pending, Created Date before earliest --> queried
        // 8. Pending, Mileage Received, Created Date after earliest --> queried
        // 9. Pending, Mileage Partial, Created Date before earliest --> not queried
        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id, State__c  = 'In Progress', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id, State__c  = 'Cleared With Mileage', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id, State__c  = 'Cleared Without Mileage', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[4].Id, State__c  = 'Case Created', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[4].Id, Retry_Count__c = 4 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[5].Id, State__c  = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[5].Id, Retry_Count__c = 1 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[6].Id, State__c  = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[6].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[7].Id, State__c  = 'Pending', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[7].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[8].Id, State__c  = 'Pending', Mileage_Received__c = 'Partial', Work_Order__c = workOrders[8].Id, Retry_Count__c = 0 ) );
        insert calls;

        Datetime createdDateIfNoMileage = Datetime.now().addMinutes( -15 );
        Test.setCreatedDate( calls[0].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[5].Id, createdDateIfNoMileage );
        Test.setCreatedDate( calls[6].Id, createdDateIfNoMileage.addSeconds( -1 ) );
        Test.setCreatedDate( calls[7].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[8].Id, createdDateIfNoMileage.addSeconds( 1 ) );

        Integer maxWorkOrders = 10;
        Integer expectedNumberOfRecords = 3;
        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();
        calls = dao.fetchPendingCalls( createdDateIfNoMileage, maxWorkOrders );
        Test.stopTest();

        System.assertEquals( expectedNumberOfRecords, calls.size(), 'The number of calls returned is not as expected' );
        System.assertEquals( 'Pending', calls[0].State__c, 'The first call is not in the Pending state' );
        System.assertEquals( 'Pending', calls[1].State__c, 'The second call is not in the Pending state' );
        System.assertEquals( 'Pending', calls[2].State__c, 'The third call is not in the Pending state' );
        System.assert( calls[0].Mileage_Received__c == 'Complete' || calls[0].CreatedDate <= createdDateIfNoMileage, 'The first call did not receive mileage or has not exceeded the wait time' );
        System.assert( calls[1].Mileage_Received__c == 'Complete' || calls[1].CreatedDate <= createdDateIfNoMileage, 'The second call did not receive mileage or has not exceeded the wait time' );
        System.assert( calls[2].Mileage_Received__c == 'Complete' || calls[2].CreatedDate <= createdDateIfNoMileage, 'The third call did not receive mileage or has not exceeded the wait time' );
    }

    @IsTest
    public static void testClearQueuedCallDAO_FetchPendingCalls_MoreRecordsThanMaxWorkOrders_CorrectNumberOfRecordsReturned() {
        Integer recordCount = 9;
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

        // Clear Queued Call data created
        // 1. Pending call but Created Date after earliest --> not queried
        // 2. In Progress --> not queried
        // 3. Cleared With Mileage --> not queried
        // 4. Cleared Without Mileage --> not queried
        // 5. Case Created --> not queried
        // 6. Pending, Mileage Pending, Created Date equals earliest --> queried
        // 7. Pending, Mileage Pending, Created Date before earliest --> queried
        // 8. Pending, Mileage Received, Created Date after earliest --> queried
        // 9. Pending, Mileage Partial, Created Date before earliest --> not queried
        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id, State__c = 'In Progress', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id, State__c = 'Cleared With Mileage', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id, State__c = 'Cleared Without Mileage', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[4].Id, State__c = 'Case Created', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[4].Id, Retry_Count__c = 4 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[5].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[5].Id, Retry_Count__c = 1 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[6].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[6].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[7].Id, State__c = 'Pending', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[7].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[8].Id, State__c = 'Pending', Mileage_Received__c = 'Partial', Work_Order__c = workOrders[8].Id, Retry_Count__c = 0 ) );
        insert calls;

        Datetime createdDateIfNoMileage = Datetime.now().addMinutes( -15 );
        Test.setCreatedDate( calls[0].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[5].Id, createdDateIfNoMileage );
        Test.setCreatedDate( calls[6].Id, createdDateIfNoMileage.addSeconds( -1 ) );
        Test.setCreatedDate( calls[7].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[8].Id, createdDateIfNoMileage.addSeconds( 1 ) );

        Integer maxWorkOrders = 1;
        Integer expectedNumberOfRecords = maxWorkOrders;
        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();
        calls = dao.fetchPendingCalls( createdDateIfNoMileage, maxWorkOrders );
        Test.stopTest();

        System.assertEquals( expectedNumberOfRecords, calls.size(), 'The number of calls returned is not as expected' );
        System.assertEquals( 'Pending', calls[0].State__c, 'The first call is not in the Pending state' );
        System.assert( calls[0].Mileage_Received__c == 'Complete' || calls[0].CreatedDate <= createdDateIfNoMileage, 'The first call did not receive mileage or has not exceeded the wait time' );
    }

    @IsTest
    public static void testClearQueuedCallDAO_FetchCallForWorkOrderId_CorrectRecordReturned() {
        
        Integer recordCount = 4;
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

        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id, State__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id, State__c = 'In Progress', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id, State__c = 'Cleared With Mileage', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id, State__c = 'Cleared Without Mileage', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        insert calls;

        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);
        Set<Id> workOrderIds = new Set<Id>{ workOrders[1].Id, workOrders[2].Id };

        Test.startTest();
        calls = dao.fetchCallsForWorkOrderId( workOrderIds );
        Test.stopTest();

        System.assertEquals( 2, calls.size(), 'The number of calls returned is not as expected' );
        System.assertEquals( workOrders[1].Id, calls[0].Work_Order__c, 'The first call\'s WorkOrder Id does not match' );
        System.assertEquals( workOrders[2].Id, calls[1].Work_Order__c, 'The second call\'s WorkOrder Id does not match' );
    }

    // Note that it's not possible to create test data with a defined LastModifiedDate. Therefore, it's not possible to test the case where there are fewer records than count
    @IsTest
    public static void testClearQueuedCallDAO_FetchLatestProcessedCalls_CorrectRecordReturned() {
        createDaoData();
        List<FSLClearQueuedCall__c> allCalls = [SELECT Id, LastModifiedDate FROM FSLClearQueuedCall__C];

        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);
        Integer count = 4;
        Datetime earliestModifiedTime = Datetime.now().addMinutes( -15 );

        Test.startTest();
        List<FSLClearQueuedCall__c> latestCalls = dao.fetchLatestProcessedCalls( count, earliestModifiedTime );
        Test.stopTest();

        System.assertEquals( 4, latestCalls.size() );
    }

    // Since the configuration is in Custom Metadata, it cannot be inserted by a test (requires deployment)
    // This test is thus for coverage only
    @IsTest
    public static void testClearQueuedCallDAO_GetClearQueueConfiguration_CoverageOnly() {
        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();
        dao.fetchClearQueueConfiguration();
        Test.stopTest();
    }

    @IsTest
    public static void testInsertRecords_DuplicateWorkOrders_InsertBlocked() {
        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();

        Integer recordCount = 2;
        List <WorkOrder> workOrders = createAndSaveSimpleWorkOrders(recordCount);

        // Now create a FSLClearQueuedCall__c object and save it.
        List<FSLClearQueuedCall__c> clearedCalls = new  List<FSLClearQueuedCall__c>();
        clearedCalls.add(new FSLClearQueuedCall__c(Name = workOrders[0].Id, Work_Order__c = workOrders[0].Id));
        Database.SaveResult[] saveResults = dao.insertRecords(clearedCalls, false);

        // Now try to add the same workorder along with a differemt WorkOrder
        clearedCalls = new  List<FSLClearQueuedCall__c>();
        clearedCalls.add(new FSLClearQueuedCall__c(Name =  workOrders[0].Id, Work_Order__c = workOrders[0].Id));
        clearedCalls.add(new FSLClearQueuedCall__c(Name =  workOrders[1].Id, Work_Order__c = workOrders[1].Id));
        saveResults = dao.insertRecords(clearedCalls, false);

        List <FSLClearQueuedCall__c> queuedCalls = [SELECT Id, Name FROM FSLClearQueuedCall__c ];
        Test.stopTest();

		System.assertEquals(2, queuedCalls.size(), 'there should only be two distinct WorkOrders in the Clear Queue');
        System.assertEquals(clearedCalls.size(),    saveResults.size(), 'there should be two saveResult records returned');
		System.assertEquals(false,  saveResults[0].isSuccess(), 'The insert of the first record should fail');
        System.assertEquals(true,   resultProcessor.checkForSpecificError(saveResults[0], StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, null), 'Check using StatusCode should confirm error'); 
        System.assertEquals(true,   resultProcessor.checkForSpecificError(saveResults[0], null, FSL_ClearQueuedCall.WORKORDER_ALREADY_QUEUED_ERROR_MSG), 'Check using errorMessage should confirm error');  
        System.assertEquals(true,   saveResults[1].isSuccess(), 'The insert of the second record should pass, since the WoID is unique');
    }

    @IsTest
    public static void testInsertClearQueuedCalls_DuplicateWorkOrders_SaveResultsCorrectlyGenerated() {

        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();

        Integer recordCount = 2;
        List <WorkOrder> workOrders = createAndSaveSimpleWorkOrders(recordCount);

        // Now create a FSLClearQueuedCall__c object and save it.
        List<FSLClearQueuedCall__c> clearedCalls = new  List<FSLClearQueuedCall__c>();
        clearedCalls.add(new FSLClearQueuedCall__c(Name = workOrders[0].Id, Work_Order__c = workOrders[0].Id));
        Database.SaveResult[] saveResults = dao.insertRecords(clearedCalls, false);

        // Now try to add the same workorder along with a differemt WorkOrder
        clearedCalls = new  List<FSLClearQueuedCall__c>();
        clearedCalls.add(new FSLClearQueuedCall__c(Name =  workOrders[0].Id, Work_Order__c = workOrders[0].Id));
        clearedCalls.add(new FSLClearQueuedCall__c(Name =  workOrders[1].Id, Work_Order__c = workOrders[1].Id));


        List<Boolean> results = dao.insertClearQueuedCalls(clearedCalls);

        List <FSLClearQueuedCall__c> queuedCalls = [SELECT Id, Name FROM FSLClearQueuedCall__c ];
        Test.stopTest();

		System.assertEquals(2, queuedCalls.size(), 'there should only be two distinct WorkOrders in the Clear Queue');
        System.assertEquals(clearedCalls.size(),    results.size(), 'there should be two Results records returned');
		System.assertEquals(true,  results[0], 'The insert of the first record should return success since the record is present in the Clear Queue');
        System.assertEquals(true,   results[1], 'The insert of the second record should pass, since the WoID is unique');

    }


    @IsTest
    public static void testUpdateRecords_UpdateClearQueuedCall_ValidationRuleSkipped() {

        FSL_DAO.IDatabaseResultsProcessor resultProcessor = new FSL_DAO.DatabaseResultsProcessor();
        FSL_ClearQueuedCall.ClearQueuedCallDAO dao = new FSL_ClearQueuedCall.ClearQueuedCallDAO(resultProcessor);

        Test.startTest();
        List<WorkOrder> workOrders = createAndSaveSimpleWorkOrders(1);

        List<FSLClearQueuedCall__c> clearedCalls = new  List<FSLClearQueuedCall__c>();
        clearedCalls.add(new FSLClearQueuedCall__c(Name = workOrders[0].Id, Work_Order__c = workOrders[0].Id, State__c = 'Pending'));
        dao.insertRecords(clearedCalls);

        clearedCalls[0].State__c = 'In Progress';
        dao.updateRecords(clearedCalls);
        List <FSLClearQueuedCall__c> queuedCalls = [SELECT Id, Name, State__c FROM FSLClearQueuedCall__c ];
        System.assertEquals(clearedCalls[0].State__c, queuedCalls[0].State__c, 'State field should match to indicate success of DML Update operation');

        clearedCalls[0].State__c = 'Pending';
        dao.updateRecords(clearedCalls, false);
        queuedCalls = [SELECT Id, Name, State__c FROM FSLClearQueuedCall__c ];
        System.assertEquals(clearedCalls[0].State__c, queuedCalls[0].State__c, 'State field should match to indicate success of Database Update operation');

        clearedCalls[0].State__c = 'In Progress';
        dao.upsertRecords(clearedCalls);
        queuedCalls = [SELECT Id, Name, State__c FROM FSLClearQueuedCall__c ];
        System.assertEquals(clearedCalls[0].State__c, queuedCalls[0].State__c, 'State field should match to indicate success of DML Upsert operation');

        clearedCalls[0].State__c = 'Pending';
        dao.upsertRecords(clearedCalls, false);
        queuedCalls = [SELECT Id, Name, State__c FROM FSLClearQueuedCall__c ];
        System.assertEquals(clearedCalls[0].State__c, queuedCalls[0].State__c, 'State field should match to indicate success of DML Upsert operation');

        Test.stopTest();

    }

    private static List<WorkOrder> createAndSaveSimpleWorkOrders(Integer recordCount)  {
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
        }
        insert workOrders;

        return workOrders;
    }


    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testClearQueuedCallService_GetClearQueueConfiguration_DaoReturnsConfig_Returned() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_Clearing_Queue__mdt expected = new FSL_Clearing_Queue__mdt( Enabled__c = true, 
                                                                        Max_consecutive_fails__c = 12, 
                                                                        Max_Retries__c = 13, 
                                                                        Max_Threads__c = 14, 
                                                                        Max_Wait_Time_secs__c = 15, 
                                                                        Max_WorkOrders__c = 16, 
                                                                        Outage_detection_window_minutes__c = 17 );
        dao.clearQueueConfiguration = expected;

        Test.startTest();
        FSL_Clearing_Queue__mdt actual = service.getClearQueueConfiguration();
        Test.stopTest();

        System.assertEquals( expected, actual );
    }

    @IsTest
    public static void testClearQueuedCallService_GetClearQueueConfiguration_DaoReturnsNull_DefaultReturned() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        dao.clearQueueConfiguration = null;

        Test.startTest();
        FSL_Clearing_Queue__mdt config = service.getClearQueueConfiguration();
        Test.stopTest();

        System.assertEquals( true, config.Enabled__c, 'The default Enabled value is not true' );
        System.assertEquals( service.DEFAULT_MAX_CONSECUTIVE_FAILS, config.Max_consecutive_fails__c, 'The default Max Consecutive Fails value is not correct' );
        System.assertEquals( service.DEFAULT_MAX_RETRIES, config.Max_Retries__c, 'The default Max Retries value is not correct' );
        System.assertEquals( service.DEFAULT_MAX_THREADS, config.Max_Threads__c, 'The default Max Threads value is not correct' );
        System.assertEquals( service.DEFAULT_MAX_WAIT_TIME_SECS, config.Max_Wait_Time_secs__c, 'The default Max Wait Time value is not correct' );
        System.assertEquals( service.DEFAULT_MAX_WORKORDERS, config.Max_WorkOrders__c, 'The default Max WorkOrders value is not correct' );
        System.assertEquals( service.DEFAULT_OUTAGE_DETECTION_WINDOW_MINUTES, config.Outage_detection_window_minutes__c, 'The default Outage Detection Window value is not correct' );
    }

    @IsTest
    public static void testClearQueuedCallService_IsEnabled_ConfigReturnedAndEnabled_True() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt();
        Boolean expected = true;
        config.Enabled__c = expected;
        dao.clearQueueConfiguration = config;

        Test.startTest();
        Boolean actual = service.isEnabled();
        Test.stopTest();

        System.assertEquals( expected, actual );
    }
    
    @IsTest
    public static void testClearQueuedCallService_IsEnabled_ConfigReturnedAndNotEnabled_False() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt();
        Boolean expected = false;
        config.Enabled__c = expected;
        dao.clearQueueConfiguration = config;

        Test.startTest();
        Boolean actual = service.isEnabled();
        Test.stopTest();

        System.assertEquals( expected, actual );
    }
    
    @IsTest
    public static void testClearQueuedCallService_IsEnabled_NoConfigReturned_True() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        dao.clearQueueConfiguration = null;
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        Boolean expected = true;

        Test.startTest();
        Boolean actual = service.isEnabled();
        Test.stopTest();

        System.assertEquals( expected, actual );
    }
    
    @IsTest
    public static void testClearQueuedCallService_AddWorkOrdersToQueue_DAOInsertRecordsCalled() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        
        List<WorkOrder> workOrders = new List<WorkOrder>();


        workOrders.add( new WorkOrder(Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType())));
        workOrders.add( new WorkOrder(Id = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType())));

        System.assertEquals( 0, dao.calls.size() );

        Test.startTest();
        service.addWorkOrdersToQueue( workOrders );
        Test.stopTest();

        System.assertEquals( workOrders.size(), dao.calls.size() );
        System.assertEquals( dao.databaseInsertInvoked, true,  'The Datbase version of insert should have been invoked');
    }


    @IsTest
    public static void testClearQueuedCallService_AddWorkOrdersToQueue_PartialSuccessProcessed() {

        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        List<WorkOrder> workorders = new List<WorkOrder>();

        // Create some WorkOrder Ids;
        Id id1 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id id2 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        Id id3 = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );

        workOrders.add(new WorkOrder(Id = id1));
        workOrders.add(new WorkOrder(Id = id2));
        workOrders.add(new WorkOrder(Id = id3));

        FSL_DAOTest.DAOMock daoBaseMock = new FSL_DAOTest.DAOMockFactory().createDAOMock();
    
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        saveResults.add(daoBaseMock.createMockSaveResult(id1, true,  null, null));

        String altErrorCode = 'UNABLE_TO_LOCK_ROW';
        String altErrorMsg = 'Unable To Lock Row';
        saveResults.add(daoBaseMock.createMockSaveResult(id2, false, altErrorCode, altErrorMsg));

        String errorCode = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
        String errorMsg =  FSL_ClearQueuedCall.WORKORDER_ALREADY_QUEUED_ERROR_MSG;
        saveResults.add(daoBaseMock.createMockSaveResult(id3, false, errorCode, errorMsg));

    

        dao.partialSuccessResultsForDatabaseInsertRecords = saveResults;
        dao.isPartialSuccess = true;

        Test.startTest();
        List<WorkOrder>  lockableWOs = service.addWorkOrdersToQueue( workorders );
        
        Test.stopTest();


        System.assertEquals( dao.databaseInsertInvoked, true,  'The Datbase version of insert should have been invoked');
        System.assertEquals( lockableWOs.size(), 2,  'Only two workorders should be marked as lockable');
        System.assertEquals(lockableWOs[0].Id, id1, 'The First WorkOrder should be in the lockable list because of a successful insert');
        System.assertEquals(lockableWOs[1].Id, id3, 'The Third WorkOrder should be in the lockable list because it already exists in the Queue');
    }


    @isTest
    public static void testClearQueuedCallService_ProcessQueue_ExceptionThrown_CallsRevertedToPending() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLogTest.ApplicationLogServiceMock applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        FSLClearQueuedCall__c call1 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        FSLClearQueuedCall__c call2 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        FSLClearQueuedCall__c call3 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        dao.calls.put( call1.Id, call1 );
        dao.calls.put( call2.Id, call2 );
        dao.calls.put( call3.Id, call3 );

        dao.clearQueueConfiguration = new FSL_Clearing_Queue__mdt( Enabled__c = true, 
            Max_consecutive_fails__c = 20, 
            Max_Retries__c = 3, 
            Max_Threads__c = 1, 
            Max_Wait_Time_secs__c = 180, 
            Max_WorkOrders__c = 10, 
            Outage_detection_window_minutes__c = 5 );

        ClearQueueProcessingBatchMock clearQueueProcessingBatch = new ClearQueueProcessingBatchMock();
        clearQueueProcessingBatch.doesSetCallsThrowException = true;
        
        Test.startTest();
        service.processQueue( clearQueueProcessingBatch );
        Test.stopTest();

        System.assertEquals( 'Pending', dao.calls.get( call1.Id ).State__c, 'The first call is not in Pending state' );
        System.assertEquals( 'Pending', dao.calls.get( call2.Id ).State__c, 'The second call is not in Pending state' );
        System.assertEquals( 'Pending', dao.calls.get( call3.Id ).State__c, 'The third call is not in Pending state' );
        System.assertEquals( 1, clearQueueProcessingBatch.setCallsCallCount, 'The batch\'s setCalls method was not called the expected amount of times' );
        System.assertEquals( 1, applicationLogService.saveApplicationLogsCallCount, 'The application log service\'s saveApplicationLogs method was not called the expected amount of times' );
    }

    @isTest
    public static void testClearQueuedCallService_ProcessQueue_NoExceptionThrown_CallsBatched() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3Clear.IToD3Clear toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLogTest.ApplicationLogServiceMock applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        FSLClearQueuedCall__c call1 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        FSLClearQueuedCall__c call2 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        FSLClearQueuedCall__c call3 = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ), State__c = 'Pending', Mileage_Received__c = 'Complete' );
        dao.calls.put( call1.Id, call1 );
        dao.calls.put( call2.Id, call2 );
        dao.calls.put( call3.Id, call3 );

        dao.clearQueueConfiguration = new FSL_Clearing_Queue__mdt( Enabled__c = true, 
            Max_consecutive_fails__c = 20, 
            Max_Retries__c = 3, 
            Max_Threads__c = 1, 
            Max_Wait_Time_secs__c = 180, 
            Max_WorkOrders__c = 10, 
            Outage_detection_window_minutes__c = 5 );

        ClearQueueProcessingBatchMock clearQueueProcessingBatch = new ClearQueueProcessingBatchMock();
        
        Test.startTest();
        service.processQueue( clearQueueProcessingBatch );
        Test.stopTest();

        System.assertEquals( 'In Progress', dao.calls.get( call1.Id ).State__c, 'The first call is not in Progress state' );
        System.assertEquals( 'In Progress', dao.calls.get( call2.Id ).State__c, 'The second call is not in Progress state' );
        System.assertEquals( 'In Progress', dao.calls.get( call3.Id ).State__c, 'The third call is not in In Progress state' );
        System.assertEquals( 1, clearQueueProcessingBatch.setCallsCallCount, 'The batch\'s setCalls method was not called the expected amount of times' );
        System.assertEquals( 0, applicationLogService.saveApplicationLogsCallCount, 'The application log service\'s saveApplicationLogs method was called' );
    }
    
    // TODO: Ran out of time to complete these tests. Going for coverage only, but need to come back to this and figure out the way to spin up the necessary objects to run the test
    // The reason this is necessary, is because of the batch job, this test becomes an end-to-end test.
    @IsTest
    public static void testClearQueuedCallService_ProcessQueue_CallSuccessfullyCleared_CallCorrectlyProcessed() {
        FSL_ClearQueuedCall.IFactory factory = new FSL_ClearQueuedCall.Factory();
        FSL_ClearQueuedCall.IClearQueuedCallService service = factory.createService();

        // Test.loadData( FSL_ServiceSettings__c.sObjectType, 'FSL_ServiceSetting' );
        // FSL_DataFactory.createWorkTypes();
        // FSL_DataFactory.createOperatingHours();

        // List<WorkType> workTypes = [SELECT Id FROM WorkType];
        // List<OperatingHours> operatingHours = [SELECT Id FROM OperatingHours];

        Integer recordCount = 1;
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

        // List<FSL_Member_Vehicle__c> vehicles = new List<FSL_Member_Vehicle__c>();
        // vehicles.add( new FSL_Member_Vehicle__c( Work_Order__c = workOrders[0].Id ) );
        // insert vehicles;

        // ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = operatingHours[0].Id, IsActive = true );
        // ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = operatingHours[0].Id, IsActive = true );
        // List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        // insert sts;

        // ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = workOrders[0].Id, ParentRecordId = workOrders[0].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
        // sa1.SchedStartTime = System.now();
        // sa1.SchedEndTime = System.now() + 1800;
        // sa1.actualstarttime = System.now();
        // sa1.PTA__c = System.now();
        // ServiceAppointment sa2 = new ServiceAppointment( Work_Order__c = workOrders[0].Id, ParentRecordId = workOrders[0].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st2.Id );
        // List<ServiceAppointment> sas = new List<ServiceAppointment> { sa1, sa2 };
        // insert sas;

        // FSL_TroubleCode__c t1 = new FSL_TroubleCode__c( Work_Order__c = workOrders[0].Id, Code__c = 'Code 1', Description__c = 'Description 1', Type__c = 'Type 1' );
        // FSL_TroubleCode__c t2 = new FSL_TroubleCode__c( Work_Order__c = workOrders[0].Id, Code__c = 'Code 2', Description__c = 'Description 2', Type__c = 'Type 2' );
        // List<FSL_TroubleCode__c> ts = new List<FSL_TroubleCode__c>{ t1, t2 };
        // insert ts;

        // FSL_Policy__c p1 = new FSL_Policy__c( Work_Order__c = workOrders[0].Id );
        // FSL_Policy__c p2 = new FSL_Policy__c( Work_Order__c = workOrders[0].Id );
        // List<FSL_Policy__c> ps = new List<FSL_Policy__c>{ p1, p2 };
        // insert ps;

        // FSL_Call_Comments__c comment1 = new FSL_Call_Comments__c( FSL_Work_Order__c = workOrders[0].Id, FSL_Comment__c = 'Comment 1' );
        // FSL_Call_Comments__c comment2 = new FSL_Call_Comments__c( FSL_Work_Order__c = workOrders[0].Id, FSL_Comment__c = 'Comment 2' );
        // List<FSL_Call_Comments__c> comments = new List<FSL_Call_Comments__c>{ comment1, comment2 };
        // insert comments;

        // Product2 product1 = new Product2( Name = 'Product1' );
        // Product2 product2 = new Product2( Name = 'Product2' );
        // List<Product2> products = new List<Product2>{ product1, product2 };
        // insert products;

        // FSL_Service_Line_Item__c sli1 = new FSL_Service_Line_Item__c( Work_Order__c = workOrders[0].Id, Product__c = product1.Id );
        // FSL_Service_Line_Item__c sli2 = new FSL_Service_Line_Item__c( Work_Order__c = workOrders[0].Id, Product__c = product2.Id );
        // List<FSL_Service_Line_Item__c> slis = new List<FSL_Service_Line_Item__c>{ sli1, sli2 };
        // insert slis;

        // Schema.Location l = new Schema.Location( Name = 'Location', IsInventoryLocation = true, IsMobile = true );
        // Schema.Location veh = new Schema.Location( Name = 'Vehicle', IsInventoryLocation = true, IsMobile = true );
        // List<Schema.Location> locs = new List<Schema.Location>{ l, veh };
        // insert locs;

        // //List<Schema.Location> locations = FSL_DataFactory.createLocation();

        // List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        // System.assertEquals( 1, profiles.size() );

        // List<User> users = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profiles[0].Id LIMIT 1];
        // System.assertEquals( 1, users.size() );

        // List<ServiceResource> ServiceResources = new List<ServiceResource>();
        // ServiceResources.add( FSL_DataFactory.createServiceResource( users[0].Id, l.Id ) );
        // serviceResources[0].Primary_Service_Territory__c = st1.Id;
        // insert ServiceResources;
        
        // AssignedResource ar = new AssignedResource( ServiceAppointmentId = sa1.Id, ServiceResourceId = serviceResources[0].Id, FSL__UpdatedByOptimization__c = false);
        // insert ar;

        // FeedItem feed1 = new FeedItem( Type = 'TextPost', Body = 'Body 1', ParentId = workOrders[0].Id );
        // FeedItem feed2 = new FeedItem( Type = 'TextPost', Body = 'Body 2', ParentId = workOrders[0].Id );
        // List<FeedItem> feeds = new List<FeedItem>{ feed1, feed2 };
        // insert feeds;

        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id,State__c = 'Pending', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[0].Id, Retry_Count__c = 0 ) );
        insert calls;

        Datetime createdDateIfNoMileage = Datetime.now().addMinutes( -15 );
        Test.setCreatedDate( calls[0].Id, createdDateIfNoMileage.addSeconds( 1 ) );

        Map<String, String> responseHeaders = new Map<String, String>{ 'Content-Type' => 'application/json;charset=UTF-8' };
        String body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
        Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 200, 'OK', body, responseHeaders ) );

        Test.startTest();
        service.processQueue( null );
        Test.stopTest();

        // calls = [SELECT Id, State__c, Mileage_Received__c, Work_Order__c, Retry_Count__c, CreatedDate FROM FSLClearQueuedCall__c];
        // System.assertEquals( 'Cleared With Mileage', calls[0].State__c );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_SuccessWithMileage() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'In Progress', Mileage_Received__c = 'Complete' );
        dao.calls.put( call.Id, call );
        Boolean isSuccessfullyCleared = true;

        service.workOrders.put( call, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 'Cleared With Mileage', dao.calls.get( call.Id ).State__c );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_SuccessWithoutMileage() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'In Progress', Mileage_Received__c = 'Pending' );
        dao.calls.put( call.Id, call );
        Boolean isSuccessfullyCleared = true;

        service.workOrders.put( call, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 'Cleared Without Mileage', dao.calls.get( call.Id ).State__c );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_FailureAndLessThanMaxRetries_Pending() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Integer retryCount = 0;
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'In Progress', Mileage_Received__c = 'Pending', Retry_Count__c = retryCount );
        dao.calls.put( call.Id, call );
        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt( MasterLabel = 'Clearing Queue', Max_Retries__c = 3, Max_consecutive_fails__c = 3, Outage_detection_window_minutes__c = 15 );
        dao.clearQueueConfiguration = config;
        Boolean isSuccessfullyCleared = false;

        service.workOrders.put( call, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 'Pending', dao.calls.get( call.Id ).State__c );
        System.assertEquals( retryCount + 1, dao.calls.get( call.Id ).Retry_Count__c );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_FailureAndRetryCountIsMaxRetries_ErrorAndCaseCreated() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Integer retryCount = 3;
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'In Progress', Mileage_Received__c = 'Pending', Retry_Count__c = retryCount );
        dao.calls.put( call.Id, call );
        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt( MasterLabel = 'Clearing Queue', Max_Retries__c = 3, Max_consecutive_fails__c = 3, Outage_detection_window_minutes__c = 15 );
        dao.clearQueueConfiguration = config;
        Boolean isSuccessfullyCleared = false;

        service.workOrders.put( call, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 'Case Created', dao.calls.get( call.Id ).State__c );
        System.assertEquals( retryCount + 1, dao.calls.get( call.Id ).Retry_Count__c );
        System.assertEquals( 1, caseService.openClearQueueFailureCaseCallCount );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_FailureAndLessThanMaxConsecutiveFailures_ClearQueueProcessingNotHalted() {
        // TODO: Complete
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String processCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', workOrderId ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'In Progress' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -1 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c processCall = (FSLClearQueuedCall__c)JSON.deserialize( processCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( processCall.Id, processCall );

        String otherCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c otherCall = (FSLClearQueuedCall__c)JSON.deserialize( otherCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( otherCall.Id, otherCall );

        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt( MasterLabel = 'Clearing Queue', Max_Retries__c = 3, Max_consecutive_fails__c = 3, Outage_detection_window_minutes__c = 15 );
        dao.clearQueueConfiguration = config;
        Boolean isSuccessfullyCleared = false;

        service.workOrders.put( processCall, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 0, minuteScheduleService.haltClearQueueProcessingDueToPotentialOutageCallCount );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_FailureAndSuccessesInLatestCalls_ClearQueueProcessingNotHalted() {
        // TODO: Complete
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String processCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', workOrderId ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'In Progress' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -1 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c processCall = (FSLClearQueuedCall__c)JSON.deserialize( processCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( processCall.Id, processCall );

        String successCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Cleared With Mileage' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c successCall = (FSLClearQueuedCall__c)JSON.deserialize( successCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( successCall.Id, successCall );

        String failedCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c failedCall = (FSLClearQueuedCall__c)JSON.deserialize( failedCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( failedCall.Id, failedCall );

        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt( MasterLabel = 'Clearing Queue', Max_Retries__c = 3, Max_consecutive_fails__c = 3, Outage_detection_window_minutes__c = 15 );
        dao.clearQueueConfiguration = config;
        Boolean isSuccessfullyCleared = false;

        service.workOrders.put( processCall, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 0, minuteScheduleService.haltClearQueueProcessingDueToPotentialOutageCallCount );
    }

    @IsTest
    public static void testClearQueuedCallService_ProcessClearResult_FailureAndMaxConsecutiveFailures_ClearQueueProcessingHalted() {
        // TODO: Complete
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_Case.ICaseService caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();
        
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String processCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', workOrderId ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'In Progress' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -1 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c processCall = (FSLClearQueuedCall__c)JSON.deserialize( processCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( processCall.Id, processCall );

        String failedCallJson1 = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '4' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -10 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c failedCall1 = (FSLClearQueuedCall__c)JSON.deserialize( failedCallJson1, FSLClearQueuedCall__c.class );
        dao.calls.put( failedCall1.Id, failedCall1 );

        String failedCallJson2 = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '4' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -25 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -5 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c failedCall2 = (FSLClearQueuedCall__c)JSON.deserialize( failedCallJson2, FSLClearQueuedCall__c.class );
        dao.calls.put( failedCall2.Id, failedCall2 );

        FSL_Clearing_Queue__mdt config = new FSL_Clearing_Queue__mdt( MasterLabel = 'Clearing Queue', Max_Retries__c = 3, Max_consecutive_fails__c = 3, Outage_detection_window_minutes__c = 15 );
        dao.clearQueueConfiguration = config;
        Boolean isSuccessfullyCleared = false;

        service.workOrders.put( processCall, new WorkOrder( Id = workOrderId ) );

        Test.startTest();
        service.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
        Test.stopTest();

        System.assertEquals( 0, minuteScheduleService.haltClearQueueProcessingDueToPotentialOutageCallCount );
    }

    @IsTest
    public static void testClearQueuedCallService_CompleteUpdateMileageReceived_CallUpdated() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        Integer retryCount = 3;
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'Pending', Mileage_Received__c = 'Pending', Mileage_Received_Timestamp__c = null, Retry_Count__c = retryCount );
        dao.calls.put( call.Id, call );
        FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus mileageStatus = FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.COMPLETE;

        Test.startTest();
        service.updateMileageReceived( workOrderId, mileageStatus );
        Test.stopTest();

        System.assertEquals( 'Complete', dao.calls.get( call.Id ).Mileage_Received__c );
        System.assertNotEquals( null, dao.calls.get( call.Id ).Mileage_Received_Timestamp__c );
    }

    @IsTest
    public static void testClearQueuedCallService_CompleteUpdateMileageReceived_CallStateNotPending_CallUpdatedWithReceivedTimestampOnly() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        Integer retryCount = 3;
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'In Progress', Mileage_Received__c = 'Pending', Mileage_Received_Timestamp__c = null, Retry_Count__c = retryCount );
        dao.calls.put( call.Id, call );
        FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus mileageStatus = FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.COMPLETE;

        Test.startTest();
        service.updateMileageReceived( workOrderId, mileageStatus );
        Test.stopTest();

        System.assertEquals( 'Pending', dao.calls.get( call.Id ).Mileage_Received__c );
        System.assertNotEquals( null, dao.calls.get( call.Id ).Mileage_Received_Timestamp__c );
    }

    @IsTest
    public static void testClearQueuedCallService_PartialUpdateMileageReceived_CallUpdated() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSL_ToD3ClearTest.ToD3ClearMock toD3Clear = new FSL_ToD3ClearTest.ToD3ClearMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_ClearQueuedCall.ClearQueuedCallService service = new FSL_ClearQueuedCall.ClearQueuedCallService( dao, toD3Clear, assignedResourceService, caseService, feedItemService, workOrderService, applicationLogService );
        
        Integer retryCount = 3;
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        FSLClearQueuedCall__c call = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), Work_Order__c = workOrderId, State__c = 'Pending', Mileage_Received__c = 'Pending', Mileage_Received_Timestamp__c = null, Retry_Count__c = retryCount );
        dao.calls.put( call.Id, call );
        FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus mileageStatus = FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.PARTIAL;

        Test.startTest();
        service.updateMileageReceived( workOrderId, mileageStatus );
        Test.stopTest();

        System.assertEquals( 'Partial', dao.calls.get( call.Id ).Mileage_Received__c );
        System.assertNotEquals( null, dao.calls.get( call.Id ).Mileage_Received_Timestamp__c );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ClearQueuedCall.IFactory {
        public FSL_ClearQueuedCall.IClearQueuedCallService createServiceReturnValue = new ClearQueuedCallServiceMock();
        public Integer createServiceCallCount = 0;
        public FSL_ClearQueuedCall.IClearQueuedCallService createService() {
            createServiceCallCount++;
            return createServiceReturnValue;
        }

        public FSL_ClearQueuedCall.IClearQueueProcessingBatch createClearQueueProcessingBatchReturnValue;
        public Integer createClearQueueProcessingBatchCallCount = 0;
        public FSL_ClearQueuedCall.IClearQueueProcessingBatch createClearQueueProcessingBatch() {
            createClearQueueProcessingBatchCallCount++;
            return createClearQueueProcessingBatchReturnValue;
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_CorrectValueReturnedAndCallCountIncremented() {
        FactoryMock factory = new FactoryMock();

        System.assertEquals( 0, factory.createServiceCallCount );

        Test.startTest();
        FSL_ClearQueuedCall.IClearQueuedCallService service = factory.createService();
        Test.stopTest();

        System.assertEquals( factory.createServiceReturnValue, service );
        System.assertEquals( 1, factory.createServiceCallCount );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType FSL_CLEARQUEUEDCALL_TYPE = FSLClearQueuedCall__c.getSObjectType();
    public class ClearQueuedCallDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ClearQueuedCall.IClearQueuedCallDAO {
        public Map<Id, FSLClearQueuedCall__c> calls;
        public Boolean isSuccess = true;
        public Boolean isPartialSuccess = false;
        public Boolean databaseInsertInvoked = false;
        public FSL_Clearing_Queue__mdt clearQueueConfiguration = new FSL_Clearing_Queue__mdt();

        List<Database.SaveResult> partialSuccessResultsForDatabaseInsertRecords = new List<Database.SaveResult>();

        public ClearQueuedCallDAOMock() {
            super( new Map<Id, FSLClearQueuedCall__c>(), FSL_CLEARQUEUEDCALL_TYPE );
            this.calls = (Map<Id, FSLClearQueuedCall__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ClearQueuedCallDAOMock' );
            }
        }

        public List<FSLClearQueuedCall__c> fetchPendingCalls( Datetime earliestModifiedTime, Integer maxWorkOrders )
        {
            isQueryException();
            List<FSLClearQueuedCall__c> result = new List<FSLClearQueuedCall__c>();
            Integer i = 0;
            while( result.size() < maxWorkOrders && i < calls.size() ) {
                if( calls.values()[i].State__c == 'Pending'
                    && ( calls.values()[i].Mileage_Received__c == 'Complete'
                        || calls.values()[i].CreatedDate <= earliestModifiedTime ) 
                    ) {
                    result.add( calls.values()[i] );
                }
                i++;
            }
            return result;
        }

        public List<FSLClearQueuedCall__c> fetchCallsForWorkOrderId( Set<Id> workOrderIds ) {
            isQueryException();
            List<FSLClearQueuedCall__c> result = new List<FSLClearQueuedCall__c>();
            for( FSLClearQueuedCall__c call : calls.values() ) {
                if( workOrderIds.contains( call.Work_Order__c ) ) {
                    result.add( call );
                }
            }
            return result;
        }

        public List<FSLCLearQueuedCall__c> fetchLatestProcessedCalls( Integer count, Datetime earliestModifiedTime ) {
            isQueryException();
            List<FSLClearQueuedCall__c> result = new List<FSLClearQueuedCall__c>();
            Integer i = calls.values().size() - 1;
            while( i > 0 && result.size() < count ) {
                FSLClearQueuedCall__c call = calls.values()[i];
                if( call.LastModifiedDate > earliestModifiedTime 
                    && call.State__c != 'In Progress'
                    && ( call.State__c != 'Pending' || call.Retry_Count__c > 0 ) ) {
                    result.add( call );
                }
                i--;
            }
            return result;
        }

        public List<FSL_Clearing_Queue__mdt> fetchClearQueueConfiguration() {
            List<FSL_Clearing_Queue__mdt> result = new List<FSL_Clearing_Queue__mdt>();
            if( clearQueueConfiguration != null ) result.add( clearQueueConfiguration );
            return result;
        }

        public override DataBase.SaveResult[] insertRecords(List<SObject> records, Boolean allOrNone) {
                databaseInsertInvoked = true;
                if ( isPartialSuccess ) {
                    return partialSuccessResultsForDatabaseInsertRecords;
                }
                else {
                    return super.insertRecords(records, allOrNone);
                }
        }

        public List<Boolean> insertClearQueuedCalls( List<FSLClearQueuedCall__c> calls ) {

            FSL_DAO.IDatabaseResultsProcessor resultsProcessor = new FSL_DAO.DatabaseResultsProcessor();
            List<Boolean> results = new List<Boolean>();
            Database.SaveResult[] saveResults = this.insertRecords( calls, false );
            for ( Database.SaveResult saveResult : saveResults) {
                results.add( saveResult.isSuccess() || resultsProcessor.checkForSpecificError(saveResult, null, FSL_ClearQueuedCall.WORKORDER_ALREADY_QUEUED_ERROR_MSG  ) );
            }
            return results;
        }

    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchPendingCalls_FewerMatchingRecordsThanMax_CorrectNumberOfRecordsReturned() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();

        Integer recordCount = 9;
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

   
        // Clear Queued Call data created
        // 1. Pending call but Created Date after earliest --> not queried
        // 2. In Progress --> not queried
        // 3. Cleared With Mileage --> not queried
        // 4. Cleared Without Mileage --> not queried
        // 5. Case Created --> not queried
        // 6. Pending, Mileage Pending, Created Date equals earliest --> queried
        // 7. Pending, Mileage Pending, Created Date before earliest --> queried
        // 8. Pending, Mileage Received, Created Date after earliest --> queried
        // 9. Pending, Mileage Partial, Created Date before earliest --> not queried
        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id, State__c = 'In Progress', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id, State__c = 'Cleared With Mileage', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id, State__c = 'Cleared Without Mileage', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[4].Id, State__c = 'Case Created', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[4].Id, Retry_Count__c = 4 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[5].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[5].Id, Retry_Count__c = 1 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[6].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[6].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[7].Id, State__c = 'Pending', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[7].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[8].Id, State__c = 'Pending', Mileage_Received__c = 'Partial', Work_Order__c = workOrders[8].Id, Retry_Count__c = 0 ) );
        insert calls;

        Datetime createdDateIfNoMileage = Datetime.now().addMinutes( -15 );
        Test.setCreatedDate( calls[0].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[5].Id, createdDateIfNoMileage );
        Test.setCreatedDate( calls[6].Id, createdDateIfNoMileage.addSeconds( -1 ) );
        Test.setCreatedDate( calls[7].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[8].Id, createdDateIfNoMileage.addSeconds( 1 ) );

        Test.startTest();
        calls = [SELECT Id, State__c, Mileage_Received__c, CreatedDate FROM FSLClearQueuedCall__c];
        for( FSLClearQueuedCall__c call : calls ) {
            dao.calls.put( call.Id, call );
        }

        Integer maxWorkOrders = 10;
        Integer expectedNumberOfRecords = 3;


        calls = dao.fetchPendingCalls( createdDateIfNoMileage, maxWorkOrders );
        Test.stopTest();

        System.assertEquals( expectedNumberOfRecords, calls.size(), 'The number of calls returned is not as expected' );
        System.assertEquals( 'Pending', calls[0].State__c, 'The first call is not in the Pending state' );
        System.assertEquals( 'Pending', calls[1].State__c, 'The second call is not in the Pending state' );
        System.assertEquals( 'Pending', calls[2].State__c, 'The third call is not in the Pending state' );
        System.assert( calls[0].Mileage_Received__c == 'Complete' || calls[0].CreatedDate <= createdDateIfNoMileage, 'The first call did not receive mileage or has not exceeded the wait time' );
        System.assert( calls[1].Mileage_Received__c == 'Complete' || calls[1].CreatedDate <= createdDateIfNoMileage, 'The second call did not receive mileage or has not exceeded the wait time' );
        System.assert( calls[2].Mileage_Received__c == 'Complete' || calls[2].CreatedDate <= createdDateIfNoMileage, 'The third call did not receive mileage or has not exceeded the wait time' );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchPendingCalls_MoreRecordsThanMax_CorrectNumberOfRecordsReturned() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();

        Integer recordCount = 9;
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

        // Clear Queued Call data created
        // 1. Pending call but Created Date after earliest --> not queried
        // 2. In Progress --> not queried
        // 3. Cleared With Mileage --> not queried
        // 4. Cleared Without Mileage --> not queried
        // 5. Case Created --> not queried
        // 6. Pending, Mileage Pending, Created Date equals earliest --> queried
        // 7. Pending, Mileage Pending, Created Date before earliest --> queried
        // 8. Pending, Mileage Received, Created Date after earliest --> queried
        // 9. Pending, Mileage Partial, Created Date before earliest --> not queried
        List<FSLClearQueuedCall__c> calls = new List<FSLClearQueuedCall__c>();
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[0].Id, State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[0].Id, Retry_Count__c = 2 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[1].Id,State__c = 'In Progress', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[1].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[2].Id,State__c = 'Cleared With Mileage', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[2].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[3].Id,State__c = 'Cleared Without Mileage', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[3].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[4].Id, State__c = 'Case Created', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[4].Id, Retry_Count__c = 4 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[5].Id,State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[5].Id, Retry_Count__c = 1 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[6].Id,State__c = 'Pending', Mileage_Received__c = 'Pending', Work_Order__c = workOrders[6].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[7].Id,State__c = 'Pending', Mileage_Received__c = 'Complete', Work_Order__c = workOrders[7].Id, Retry_Count__c = 0 ) );
        calls.add( new FSLClearQueuedCall__c( Name = workOrders[8].Id,State__c = 'Pending', Mileage_Received__c = 'Partial', Work_Order__c = workOrders[8].Id, Retry_Count__c = 0 ) );
        insert calls;

        Datetime createdDateIfNoMileage = Datetime.now().addMinutes( -15 );
        Test.setCreatedDate( calls[0].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[5].Id, createdDateIfNoMileage );
        Test.setCreatedDate( calls[6].Id, createdDateIfNoMileage.addSeconds( -1 ) );
        Test.setCreatedDate( calls[7].Id, createdDateIfNoMileage.addSeconds( 1 ) );
        Test.setCreatedDate( calls[8].Id, createdDateIfNoMileage.addSeconds( 1 ) );

        calls = [SELECT Id, State__c, Mileage_Received__c, CreatedDate FROM FSLClearQueuedCall__c];
        for( FSLClearQueuedCall__c call : calls ) {
            dao.calls.put( call.Id, call );
        }

        Integer maxWorkOrders = 2;
        Integer expectedNumberOfRecords = 2;

        Test.startTest();
        calls = dao.fetchPendingCalls( createdDateIfNoMileage, maxWorkOrders );
        Test.stopTest();

        System.assertEquals( expectedNumberOfRecords, calls.size(), 'The number of calls returned is not as expected' );
        System.assertEquals( 'Pending', calls[0].State__c, 'The first call is not in the Pending state' );
        System.assertEquals( 'Pending', calls[1].State__c, 'The second call is not in the Pending state' );
        System.assert( calls[0].Mileage_Received__c == 'Complete' || calls[0].CreatedDate <= createdDateIfNoMileage, 'The first call did not receive mileage or has not exceeded the wait time' );
        System.assert( calls[1].Mileage_Received__c == 'Complete' || calls[1].CreatedDate <= createdDateIfNoMileage, 'The second call did not receive mileage or has not exceeded the wait time' );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchPendingCalls_IsException_ExceptionThrown() {
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSLClearQueuedCall__c pendingCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Pending' );
        dao.calls.put( pendingCall.Id, pendingCall );
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<FSLClearQueuedCall__c> calls = dao.fetchPendingCalls( Datetime.now(), 10 );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchCallForWorkOrderId_CorrectRecordReturned() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSLClearQueuedCall__c pendingCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Pending', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c inProgressCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'In Progress', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c clearedWithMileageCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Cleared With Mileage', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c clearedWithoutMileageCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Cleared Without Mileage', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c caseCreatedCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Case Created', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        dao.calls.put( pendingCall.Id, pendingCall );
        dao.calls.put( inProgressCall.Id, inProgressCall );
        dao.calls.put( clearedWithMileageCall.Id, clearedWithMileageCall );
        dao.calls.put( clearedWithoutMileageCall.Id, clearedWithoutMileageCall );
        dao.calls.put( caseCreatedCall.Id, caseCreatedCall );

        Set<Id> workOrderIds = new Set<Id>{ inProgressCall.Work_Order__c };
        
        Test.startTest();
        List<FSLClearQueuedCall__c> calls = dao.fetchCallsForWorkOrderId( workOrderIds );
        Test.stopTest();

        System.assertEquals( 1, calls.size() );
        System.assertEquals( inProgressCall, calls[0] );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchCallForWorkOrderId_NoCallsExist_EmptyList() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSLClearQueuedCall__c pendingCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Pending', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c inProgressCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'In Progress', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c clearedWithMileageCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Cleared With Mileage', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c clearedWithoutMileageCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Cleared Without Mileage', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        FSLClearQueuedCall__c caseCreatedCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'Case Created', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        dao.calls.put( pendingCall.Id, pendingCall );
        dao.calls.put( inProgressCall.Id, inProgressCall );
        dao.calls.put( clearedWithMileageCall.Id, clearedWithMileageCall );
        dao.calls.put( clearedWithoutMileageCall.Id, clearedWithoutMileageCall );
        dao.calls.put( caseCreatedCall.Id, caseCreatedCall );

        Set<Id> workOrderIds = new Set<Id>{ dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) };
        
        Test.startTest();
        List<FSLClearQueuedCall__c> calls = dao.fetchCallsForWorkOrderId( workOrderIds );
        Test.stopTest();

        System.assertEquals( 0, calls.size() );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchCallForWorkOrderId_IsException_ExceptionThrown() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        FSLClearQueuedCall__c inProgressCall = new FSLClearQueuedCall__c( Id = dao.Builder.getMockId(), State__c = 'In Progress', Work_Order__c = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) );
        dao.calls.put( inProgressCall.Id, inProgressCall );
        Set<Id> workOrderId = new Set<Id>{ inProgressCall.Work_Order__c };
        
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<FSLClearQueuedCall__c> calls = dao.fetchCallsForWorkOrderId( workOrderId );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchLatestProcessedCalls_NoExceptionAndFewerRecordsThanCount_CorrectRecordsReturned() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String oldCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -25 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c oldCall = (FSLClearQueuedCall__c)JSON.deserialize( oldCallJson, FSLClearQueuedCall__c.class );
        String pendingCallWithoutRetriesJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Pending' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -15 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -5 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c pendingCallWithoutRetries = (FSLClearQueuedCall__c)JSON.deserialize( pendingCallWithoutRetriesJson, FSLClearQueuedCall__c.class );
        String pendingCallWithRetriesJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '1' ).replace( '%State__c%', 'Pending' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -14 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -4 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c pendingCallWithRetries = (FSLClearQueuedCall__c)JSON.deserialize( pendingCallWithRetriesJson, FSLClearQueuedCall__c.class );
        String inProgressCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'In Progress' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -13 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -3 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c inProgressCall = (FSLClearQueuedCall__c)JSON.deserialize( inProgressCallJson, FSLClearQueuedCall__c.class );
        String clearedWithMileageCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Cleared With Mileage' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -12 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -2 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c clearedWithMileageCall = (FSLClearQueuedCall__c)JSON.deserialize( clearedWithMileageCallJson, FSLClearQueuedCall__c.class );
        String clearedWithoutMileageCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Cleared Without Mileage' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -11 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -1 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c clearedWithoutMileageCall = (FSLClearQueuedCall__c)JSON.deserialize( clearedWithoutMileageCallJson, FSLClearQueuedCall__c.class );
        String caseCreatedCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '4' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -11 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -0 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c caseCreatedCall = (FSLClearQueuedCall__c)JSON.deserialize( caseCreatedCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( pendingCallWithoutRetries.Id, pendingCallWithoutRetries );
        dao.calls.put( pendingCallWithRetries.Id, pendingCallWithRetries );
        dao.calls.put( inProgressCall.Id, inProgressCall );
        dao.calls.put( clearedWithMileageCall.Id, clearedWithMileageCall );
        dao.calls.put( clearedWithoutMileageCall.Id, clearedWithoutMileageCall );
        dao.calls.put( caseCreatedCall.Id, caseCreatedCall );

        Datetime earliestModifiedTime = Datetime.now().addMinutes( -20 );
        
        Test.startTest();
        List<FSLClearQueuedCall__c> calls = dao.fetchLatestProcessedCalls( 5, earliestModifiedTime );
        Test.stopTest();

        System.assertEquals( 4, calls.size() );
        System.assertEquals( caseCreatedCall, calls[0] );
        System.assertEquals( clearedWithoutMileageCall, calls[1] );
        System.assertEquals( clearedWithMileageCall, calls[2] );
        System.assertEquals( pendingCallWithRetries, calls[3] );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchLatestProcessedCalls_NoExceptionAndMoreRecordsThanCount_CorrectRecordsReturned() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String oldCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -30 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -25 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c oldCall = (FSLClearQueuedCall__c)JSON.deserialize( oldCallJson, FSLClearQueuedCall__c.class );
        String pendingCallWithoutRetriesJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Pending' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -15 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -5 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c pendingCallWithoutRetries = (FSLClearQueuedCall__c)JSON.deserialize( pendingCallWithoutRetriesJson, FSLClearQueuedCall__c.class );
        String pendingCallWithRetriesJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '1' ).replace( '%State__c%', 'Pending' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -14 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -4 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c pendingCallWithRetries = (FSLClearQueuedCall__c)JSON.deserialize( pendingCallWithRetriesJson, FSLClearQueuedCall__c.class );
        String inProgressCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'In Progress' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -13 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -3 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c inProgressCall = (FSLClearQueuedCall__c)JSON.deserialize( inProgressCallJson, FSLClearQueuedCall__c.class );
        String clearedWithMileageCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Cleared With Mileage' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -12 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -2 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c clearedWithMileageCall = (FSLClearQueuedCall__c)JSON.deserialize( clearedWithMileageCallJson, FSLClearQueuedCall__c.class );
        String clearedWithoutMileageCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '0' ).replace( '%State__c%', 'Cleared Without Mileage' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -11 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -1 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c clearedWithoutMileageCall = (FSLClearQueuedCall__c)JSON.deserialize( clearedWithoutMileageCallJson, FSLClearQueuedCall__c.class );
        String caseCreatedCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '4' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -11 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -0 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c caseCreatedCall = (FSLClearQueuedCall__c)JSON.deserialize( caseCreatedCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( pendingCallWithoutRetries.Id, pendingCallWithoutRetries );
        dao.calls.put( pendingCallWithRetries.Id, pendingCallWithRetries );
        dao.calls.put( inProgressCall.Id, inProgressCall );
        dao.calls.put( clearedWithMileageCall.Id, clearedWithMileageCall );
        dao.calls.put( clearedWithoutMileageCall.Id, clearedWithoutMileageCall );
        dao.calls.put( caseCreatedCall.Id, caseCreatedCall );

        Datetime earliestModifiedTime = Datetime.now().addMinutes( -20 );
        
        Test.startTest();
        List<FSLClearQueuedCall__c> calls = dao.fetchLatestProcessedCalls( 3, earliestModifiedTime );
        Test.stopTest();

        System.assertEquals( 3, calls.size() );
        System.assertEquals( caseCreatedCall, calls[0] );
        System.assertEquals( clearedWithoutMileageCall, calls[1] );
        System.assertEquals( clearedWithMileageCall, calls[2] );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchLatestProcessedCalls_IsException_ExceptionThrown() {
        FSL_DAOTest.MockIdGenerator workOrderIdGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        String callJson = '{"attributes":{"type":"FSLClearQueuedCall__c","url":"/services/data/v51.0/sobjects/FSLClearQueuedCall__c/%Id%"},"Id":"%Id%","Work_Order__c":"%Work_Order__c%", "Retry_Count__c":"%Retry_Count__c%","State__c":"%State__c%","CreatedDate":"%CreatedDate%","LastModifiedDate":"%LastModifiedDate%"}';
        String caseCreatedCallJson = callJson.replace( '%Id%', dao.Builder.getMockId() ).replace( '%Work_Order__c%', dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() ) ).replace( '%Retry_Count__c%', '4' ).replace( '%State__c%', 'Case Created' ).replace( '%CreatedDate%', Datetime.now().addMinutes( -11 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) ).replace( '%LastModifiedDate%', Datetime.now().addMinutes( -0 ).formatGMT( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'' ) );
        FSLClearQueuedCall__c caseCreatedCall = (FSLClearQueuedCall__c)JSON.deserialize( caseCreatedCallJson, FSLClearQueuedCall__c.class );
        dao.calls.put( caseCreatedCall.Id, caseCreatedCall );

        dao.isSuccess = false;
        Exception ex = null;

        Datetime earliestModifiedTime = Datetime.now().addMinutes( -20 );
        
        Test.startTest();
        try {
            dao.fetchLatestProcessedCalls( 3, earliestModifiedTime );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testClearQueuedCallDAOMock_FetchClearQueueConfiguration_ConfigReturned() {
        FSL_Clearing_Queue__mdt expected = new FSL_Clearing_Queue__mdt( Enabled__c = true );
        ClearQueuedCallDAOMock dao = new ClearQueuedCallDAOMock();
        dao.clearQueueConfiguration = expected;
        
        Test.startTest();
        List<FSL_Clearing_Queue__mdt> actual = dao.fetchClearQueueConfiguration();
        Test.stopTest();

        System.assertEquals( 1, actual.size() );
        System.assertEquals( expected, actual[0] );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ClearQueuedCallServiceMock implements FSL_ClearQueuedCall.IClearQueuedCallService {
        public Boolean enabled = true;
        
        public Boolean partialSuccessOnAddToQueue = false;

        public Integer isEnabledCallCount = 0;
        public Boolean isEnabled() {
            ++isEnabledCallCount;
            return enabled;
        }

        public Integer addWorkOrdersToQueueCallCount = 0;
        public List<WorkOrder> addWorkOrdersToQueue( List<WorkOrder> workOrders ) {
            ++addWorkOrdersToQueueCallCount;
            List<WorkOrder> queuedWorkOrders = new  List<WorkOrder>();

            // Skip every other record to emulate partial success
            Boolean skip = false;
            for( WorkOrder wo : workOrders ) {  
                if (partialSuccessOnAddToQueue && !skip) {
                    queuedWorkOrders.add( wo );
                }
                skip = !skip;
            }
            return queuedWorkOrders;
        }

        public Integer processQueueCallCount = 0;
        public void processQueue( FSL_ClearQueuedCall.IClearQueueProcessingBatch clearQueueProcessingBatch ) {
            ++processQueueCallCount;
        }

        public Integer processClearResultCallCount = 0;
        public void processClearResult( Id workOrderId, Boolean isSuccessfullyCleared, FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            ++processClearResultCallCount;
        }

        public Integer updateMileageReceivedCallCount = 0;
        public void updateMileageReceived( Id workOrderId, FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus status ) {
            ++updateMileageReceivedCallCount;
        }

        public Integer sendClearRequestsCallCount = 0;
        public void sendClearRequests( List<FSLClearQueuedCall__c> calls, FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            sendClearRequestsCallCount++;
        }
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_IsEnabled_CorrectValueReturnedAndCallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.isEnabledCallCount;

        service.enabled = false;
        Boolean isEnabled1 = service.isEnabled();
        Integer callCount1 = service.isEnabledCallCount;

        service.enabled = true;
        Boolean isEnabled2 = service.isEnabled();
        Integer callCount2 = service.isEnabledCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( false, isEnabled1 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( true, isEnabled2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_AddWorkOrdersToQueue_CallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.addWorkOrdersToQueueCallCount;

        service.addWorkOrdersToQueue( new List<WorkOrder>() );
        Integer callCount1 = service.addWorkOrdersToQueueCallCount;

        service.addWorkOrdersToQueue( new List<WorkOrder>() );
        Integer callCount2 = service.addWorkOrdersToQueueCallCount;

        Test.stopTest();
        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_ProcessQueue_CallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.processQueueCallCount;

        service.processQueue( null );
        Integer callCount1 = service.processQueueCallCount;

        service.processQueue( null );
        Integer callCount2 = service.processQueueCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_ProcessClearResult_CallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.processClearResultCallCount;

        service.processClearResult( null, true, null );
        Integer callCount1 = service.processClearResultCallCount;

        service.processClearResult( null, false, null );
        Integer callCount2 = service.processClearResultCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_UpdateMileageReceivedCallCount_CallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.updateMileageReceivedCallCount;

        service.updateMileageReceived( null, FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.COMPLETE );
        Integer callCount1 = service.updateMileageReceivedCallCount;

        service.updateMileageReceived( null, FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.COMPLETE );
        Integer callCount2 = service.updateMileageReceivedCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testClearQueuedCallServiceMock_SendClearRequests_CallCountIncremented() {
        ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.sendClearRequestsCallCount;

        service.sendClearRequests(null, null);
        Integer callCount1 = service.sendClearRequestsCallCount;

        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 1, callCount1 );

    }

    // *********************************************
    // * ClearQueueProcessingBatchMock
    // *********************************************
    public class ClearQueueProcessingBatchMock implements FSL_ClearQueuedCall.IClearQueueProcessingBatch, Database.Stateful {
        private List<FSLClearQueuedCall__c> calls;

        public ClearQueueProcessingBatchMock() {
            this.calls = new List<FSLClearQueuedCall__c>();
        }

        public Integer setCallsCallCount = 0;
        public Boolean doesSetCallsThrowException = false;
        public void setCalls( List<FSLClearQueuedCall__c> calls ) {
            setCallsCallCount++;
            if( doesSetCallsThrowException ) throw new DmlException( 'Forced Exception in ClearQueueProcessingBatchMock.setCalls' );
            this.calls = calls;
        }

        public Integer startCallCount = 0;
        public Boolean doesStartThrowException = false;
        public Iterable<SObject> start( Database.BatchableContext context ) {
            startCallCount++;
            if( doesStartThrowException ) throw new DmlException( 'Forced Exception in ClearQueueProcessingBatchMock.start' );
            return calls;
        }
    
        public Integer executeCallCount = 0;
        public Boolean doesExecuteThrowException = false;
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            executeCallCount++;
            if( doesExecuteThrowException ) throw new DmlException( 'Forced Exception in ClearQueueProcessingBatchMock.execute' );
            ClearQueuedCallServiceMock service = new ClearQueuedCallServiceMock();
            FSL_ScheduleTest.MinuteScheduleServiceMock minuteScheduleService = new FSL_ScheduleTest.MinuteScheduleServiceMock();

            service.sendClearRequests( (List<FSLClearQueuedCall__c>)items, minuteScheduleService );
        }
    
        public Integer finishCallCount = 0;
        public Boolean doesFinishThrowException = false;
        public void finish( Database.BatchableContext context ) {
            finishCallCount++;
            if( doesFinishThrowException ) throw new DmlException( 'Forced Exception in ClearQueueProcessingBatchMock.finish' );
        }
    }
}