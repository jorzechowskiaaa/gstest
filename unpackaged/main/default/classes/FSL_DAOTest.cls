@IsTest
public with sharing class FSL_DAOTest {

    // *********************************************
    // * DmlBase
    // *********************************************
    private class DmlStub extends FSL_DAO.DmlBase {}
	static TestMethod void insertRecords_givenAccount_shouldGetId() {
		DmlStub stub = new DmlStub();
        Account acc = new Account( Name = 'Test Account' );
        
		Test.startTest();
		stub.insertRecords( new List<Account> { acc } );
		Test.stopTest();

		System.assertNotEquals( null, acc.Id );
	}

	static TestMethod void updateRecords_givenAccount_shouldGetUpdatedAccount() {
		DmlStub stub = new DmlStub();
        String oldAccoountNumber = '123';
		String newAccountNumber = '456';
		Account acc = new Account(  Name = 'Test Account',
			                        AccountNumber = oldAccoountNumber );
		insert acc;
		acc.AccountNumber = newAccountNumber;
		
        Test.startTest();
		stub.updateRecords( new List<Account> { acc } );
		Test.stopTest();

		System.assertNotEquals( null, acc.Id );
        Account updatedAccount = [SELECT AccountNumber 
                                    FROM Account 
                                    WHERE Id = :acc.Id];
		System.assertNotEquals( oldAccoountNumber, updatedAccount.AccountNumber );
		System.assertEquals( newAccountNumber, updatedAccount.AccountNumber );
	}

	static TestMethod void upsertRecords_givenNewAccount_shouldGetId() {
		DmlStub stub = new DmlStub();
		Account acc = new Account( Name = 'Test Account' );

		Test.startTest();
		stub.upsertRecords( new List<Account> { acc } );
		Test.stopTest();

		System.assertNotEquals( null, acc.Id );
	}

	static TestMethod void deleteRecords_givenOldAccount_shouldGetNullID() {
		DmlStub stub = new DmlStub();
		Account acc = new Account( Name = 'Test Account' );
		insert acc;

		Test.startTest();
		stub.deleteRecords( new List<Account> { acc } );
		Test.stopTest();

        List<Account> accounts = [SELECT Id 
                                    FROM Account];
		System.assert( accounts.isEmpty() );
    }
    
    // *********************************************
    // * MockIdGenerator
    // *********************************************
    private static Map<String, Integer> counts;
    static {
        counts = new Map<String, Integer>();
    }

    public with sharing class MockIdGenerator {
        public SObjectType mockType {get; private set;}
    
        public MockIdGenerator( SObjectType type ) {
            String objectName = String.valueOf( type );
            if( !counts.containsKey( objectName ) ) counts.put( objectName, 0 );
            this.mockType = type;
        }
    
        public MockIdGenerator( SObject obj ) {
            this( obj.getSObjectType() );
        }
    
        // Return type of ID converts length 15 string id to length 18 id.
        public Id getMockId() {
            return getMockId( this.mockType );
        }
    
        public Id getMockId( SObject obj ) {
            return getMockId( obj.getSObjectType() );
        }
    
        public Id getMockId( SObjectType type ) {
            String objectName = String.valueOf( type );
            if( !counts.containsKey( objectName ) ) counts.put( objectName, 0 );
    
            Integer currentCount = counts.get( objectName );
            counts.put( objectName, ++currentCount );
            String nextIdStub = String.valueOf( currentCount );
    
            return type.getDescribe().getKeyPrefix() + fillId( nextIdStub ) + nextIdStub;
        }
    
        private String fillId( String currentId ) {
            return '0'.repeat( 12 - currentId.length() );
        }
    }

    static TestMethod void getMockId_givenAccount_shouldGetAccountPrefixId() {
		Account acc = new Account();
		MockIdGenerator idGen = new MockIdGenerator( acc );
		String accountIdPrefix = Account.getSObjectType().getDescribe().getKeyPrefix();

		Test.startTest();
		String accountId = idGen.getMockId();
		Test.stopTest();

		System.assertEquals( accountIdPrefix, accountId.substring( 0, 3 ) );
		System.assertEquals( 18, accountId.length(), accountId );
	}

	static TestMethod void statelessMockId_givenContact_shouldGetContactId() {
        Contact con = new Contact();
        MockIdGenerator idGen = new MockIdGenerator( con );
		String contactIdPrefix = Contact.getSObjectType().getDescribe().getKeyPrefix();

		Test.startTest();
		String contactId = idGen.getMockId( con );
		Test.stopTest();

		System.assertEquals( contactIdPrefix, contactId.substring( 0, 3 ) );
		System.assertEquals( 18, contactId.length(), contactId );
	}

	static TestMethod void getMockId_givenTwoObjectStates_shouldGetUniqueObjectCounts() {
		MockIdGenerator accGen = new MockIdGenerator( new Account() );
		MockIdGenerator conGen = new MockIdGenerator( new Contact() );

		Test.startTest();
		String accountId = accGen.getMockId();
		String contactId = conGen.getMockId();
		Test.stopTest();

		String accountWithoutPrefix = accountId.substring( 3, 18 );
		String contactWithoutPrefix = contactId.substring( 3, 18 );

		System.assertEquals( accountWithoutPrefix, contactWithoutPrefix );
	}


    static TestMethod void testInsertRecordsUsingDatabase_MixedListInserted_PartialSuccess() {
	
        DmlStub stub = new DmlStub();
        String firstAccountNumber = '123';
		String secondAccountNumber = '456';

		Account acc1 = new Account(  Name = 'Test Account 1',
			                        AccountNumber = firstAccountNumber );
        Account acc2 = new Account(  Name = '',
			                        AccountNumber = firstAccountNumber );

        List <Account> accounts = new List<Account>();
        accounts.add(acc1);
        accounts.add(acc2);

        Test.startTest();
        Database.SaveResult[] saveResults = stub.insertRecords(accounts, false);
        List <Account> retrievedAccounts = [SELECT Id, Name, AccountNumber 
                        FROM Account
                        WHERE AccountNumber = :firstAccountNumber ];
		Test.stopTest();

		System.assertEquals( retrievedAccounts.size(), 1 );
        System.assertEquals( saveResults.size(), 2);
		System.assertEquals( saveResults[0].isSuccess(), true );
        System.assertEquals( saveResults[1].isSuccess(), false);

	}

    static TestMethod void testInsertRecordsUsingDatabase_DuplicatesBlocked_MixedListInserted_PartialSuccess() {
	
        DmlStub stub = new DmlStub();
        FSL_DAO.IDatabaseResultsProcessor resultsProcessor = new FSL_DAO.DatabaseResultsProcessor();

        // Get a WorkOrder created
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
            workOrders[i].Call_Id__c = '3333' + i;
            workOrders[i].Call_Date__c = '4444' + i;
            workOrders[i].Status = 'Spotted';
        }

        Test.startTest();
        insert workOrders;

        // Now create a FSLClearQueuedCall__c object and its duplicate;


        List<FSLClearQueuedCall__c> clearedCalls = new  List<FSLClearQueuedCall__c>();

        Id woId = workOrders[0].Id;

        clearedCalls.add(new FSLClearQueuedCall__c(Name = woId, Work_Order__c = woId));
        Database.SaveResult[] saveResults = stub.insertRecords(clearedCalls, false);

        woId = workOrders[1].Id;

        clearedCalls = new  List<FSLClearQueuedCall__c>();
        woId = workOrders[0].Id;
        clearedCalls.add(new FSLClearQueuedCall__c(Name = woId, Work_Order__c = woId));
        woId = workOrders[1].Id;
        clearedCalls.add(new FSLClearQueuedCall__c(Name = woId, Work_Order__c = woId));

        saveResults = stub.insertRecords(clearedCalls, false);
        List <FSLClearQueuedCall__c> queuedCalls = [SELECT Id, Name
                        FROM FSLClearQueuedCall__c ];
	

		System.assertEquals(2,          queuedCalls.size() );
        System.assertEquals(2,          saveResults.size());
		System.assertEquals( false,     saveResults[0].isSuccess() );

        System.assertEquals(false, saveResults[0].isSuccess());
        System.assertEquals(true, resultsProcessor.checkForSpecificError(saveResults[0], StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, null)); 
        System.assertEquals(true, resultsProcessor.checkForSpecificError(saveResults[0], null, FSL_ClearQueuedCall.WORKORDER_ALREADY_QUEUED_ERROR_MSG)); 
        System.assertEquals(true, saveResults[1].isSuccess());


        Test.stopTest();
	}

    static TestMethod void testUpdateRecordsUsingDatabase_MixedListUpdated_PartialSuccess() {
	
        DmlStub stub = new DmlStub();
        String firstAccountNumber = '123';
		String secondAccountNumber = '456';

		Account acc1 = new Account(  Name = 'Test Account 1',
			                        AccountNumber = firstAccountNumber );
        Account acc2 = new Account(  Name = 'Test Account 2',
			                        AccountNumber = secondAccountNumber );

        List <Account> accounts = new List<Account>();
        accounts.add(acc1);
        accounts.add(acc2);
        Database.SaveResult[] saveResults = stub.insertRecords(accounts, false);
        Test.startTest();

        // Now update the accounts but introduce an error in one of the records

        List <Account> retrievedAccounts = [SELECT Id, Name, AccountNumber 
            FROM Account
            WHERE AccountNumber = :firstAccountNumber ];

        System.assertEquals( retrievedAccounts.size(), 1);

        acc1.AccountNumber = secondAccountNumber;
        acc1.Id = null;
        acc2.AccountNumber = firstAccountNumber;
        saveResults = stub.updateRecords(accounts, false);
     
        retrievedAccounts = [SELECT Id, Name, AccountNumber 
                        FROM Account
                        WHERE AccountNumber = :firstAccountNumber ];
		Test.stopTest();
        
		System.assertEquals( 2,     retrievedAccounts.size());
        System.assertEquals( 2,     saveResults.size());
		System.assertEquals( false, saveResults[0].isSuccess());
        System.assertEquals( true, saveResults[1].isSuccess());

	}

    static TestMethod void testUpsertRecordsUsingDatabase_MixedListUpserted_PartialSuccess() {

        DmlStub stub = new DmlStub();
        String firstAccountNumber = '123';
		String secondAccountNumber = '456';

		Account acc1 = new Account(  Name = 'Test Account 1',
			                        AccountNumber = firstAccountNumber );
        Account acc2 = new Account(  Name = 'Test Account 2',
			                        AccountNumber = secondAccountNumber );

        List <Account> accounts = new List<Account>();
        accounts.add(acc1);
        accounts.add(acc2);
        Database.SaveResult[] saveResults = stub.insertRecords(accounts, false);
        Test.startTest();

        // Now update the accounts but introduce an error in one of the records

        List <Account> retrievedAccounts = [SELECT Id, Name, AccountNumber 
            FROM Account
            WHERE AccountNumber = :firstAccountNumber ];

        System.assertEquals( retrievedAccounts.size(), 1);
        Account acc3 = new Account(  Name = '', AccountNumber = firstAccountNumber );

        accounts.add(acc3);
        acc1.AccountNumber = secondAccountNumber;
        acc2.AccountNumber = firstAccountNumber;


        Database.UpsertResult[] upsertResults = stub.upsertRecords(accounts, false);
     
        retrievedAccounts = [SELECT Id, Name, AccountNumber 
                            FROM Account
                            WHERE AccountNumber = :secondAccountNumber ];
		Test.stopTest();

		System.assertEquals( 1, retrievedAccounts.size());
        System.assertEquals( 3,  upsertResults.size());
		System.assertEquals( true, upsertResults[0].isSuccess());
        System.assertEquals( true, upsertResults[1].isSuccess());
        System.assertEquals( false, upsertResults[2].isSuccess());

    }
	
    static TestMethod void testDeleteRecordsUsingDatabase_MixedListDeleted_PartialSuccess() {
        DmlStub stub = new DmlStub();
        String firstAccountNumber = '123';
		String secondAccountNumber = '456';

		Account acc1 = new Account(  Name = 'Test Account 1',
			                        AccountNumber = firstAccountNumber );
        Account acc2 = new Account(  Name = 'Test Account 2',
			                        AccountNumber = secondAccountNumber );

        List <Account> accounts = new List<Account>();
        accounts.add(acc1);
        accounts.add(acc2);

        Test.startTest();
        Database.SaveResult[] saveResults = stub.insertRecords(accounts, false);
        List <Account> savedAccounts = [SELECT Id, Name, AccountNumber 
                        FROM Account];


        MockIdGenerator accGen = new MockIdGenerator( new Account() );
        acc1.Id  = accGen.getMockId();
        Database.DeleteResult[]  deleteResults = stub.deleteRecords(accounts, false);   
        List <Account> retrievedAccounts = [SELECT Id, Name, AccountNumber FROM Account];
                      
		Test.stopTest();

		System.assertEquals( savedAccounts.size(), 2);
        System.assertEquals( retrievedAccounts.size(), 1);
        System.assertEquals( deleteResults.size(), 2);
		System.assertEquals( deleteResults[0].isSuccess(), false );
        System.assertEquals( deleteResults[1].isSuccess(), true);

    }

   
    static TestMethod void testCheckForSpecificErrorInSaveResult_VariousMatchCriteria_ErrorParsed() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        MockIdGenerator accGen = new MockIdGenerator( new Account() );
        Id id1 = accGen.getMockId();

        String errorCode = 'CUSTOM_VALIDATION_ERROR';
        String errorMsg = 'Custom Validation Error';
        Database.SaveResult errorResult = daoMock.createMockSaveResult(id1, false, errorCode, errorMsg);
        List<Database.Error> errors = errorResult.getErrors();
        StatusCode scode = errors[0].getStatusCode();

        
        String altErrorCode = 'UNABLE_TO_LOCK_ROW';
        String altErrorMsg = 'Unable To Lock Row';
        Database.SaveResult altErrorResult = daoMock.createMockSaveResult(id1, false, altErrorCode, altErrorMsg);
        errors = altErrorResult.getErrors();
        StatusCode altScode = errors[0].getStatusCode();

        Database.SaveResult successResult = daoMock.createMockSaveResult(id1, true,  errorCode, errorMsg);


        Test.startTest();

        Boolean check = daoMock.resultsProcessor.CheckForSpecificError(successResult, scode, errorMsg);
        System.assertEquals(check, false, 'The check should be false because the Result is successful');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null, null);
        System.assertEquals(check, false, 'The check should be false because a specific error is not matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, scode, null);
        System.assertEquals(check, true, 'The check should be true because the StatusCode of the result is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null,  errorMsg);
        System.assertEquals(check, true, 'The check should be true because the error message is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, altScode,  altErrorMsg);
        System.assertEquals(check, false, 'The check should be false because niether StatusCode or Error Message is matched'); 

        Test.stopTest();

    }

    static TestMethod void testCheckForSpecificErrorInUpsertResult_VariousMatchCriteria_ErrorParsed() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        MockIdGenerator accGen = new MockIdGenerator( new Account() );
        Id id1 = accGen.getMockId();

        String errorCode = 'CUSTOM_VALIDATION_ERROR';
        String errorMsg = 'Custom Validation Error';
        Database.UpsertResult errorResult = daoMock.createMockUpsertResult(id1, false, errorCode, errorMsg);
        List<Database.Error> errors = errorResult.getErrors();
        StatusCode scode = errors[0].getStatusCode();

        
        String altErrorCode = 'UNABLE_TO_LOCK_ROW';
        String altErrorMsg = 'Unable To Lock Row';
        Database.UpsertResult altErrorResult = daoMock.createMockUpsertResult(id1, false, altErrorCode, altErrorMsg);
        errors = altErrorResult.getErrors();
        StatusCode altScode = errors[0].getStatusCode();

        Database.UpsertResult successResult = daoMock.createMockUpsertResult(id1, true,  errorCode, errorMsg);


        Test.startTest();

        Boolean check = daoMock.resultsProcessor.checkForSpecificError(successResult, scode, errorMsg);
        System.assertEquals(check, false, 'The check should be false because the Result is successful');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null, null);
        System.assertEquals(check, false, 'The check should be false because a specific error is not matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, scode, null);
        System.assertEquals(check, true, 'The check should be true because the StatusCode of the result is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null,  errorMsg);
        System.assertEquals(check, true, 'The check should be true because the error message is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, altScode,  altErrorMsg);
        System.assertEquals(check, false, 'The check should be false because niether StatusCode or Error Message is matched'); 

        Test.stopTest();

    }

    static TestMethod void testCheckForSpecificErrorInDeleteResult_VariousMatchCriteria_ErrorParsed() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        MockIdGenerator accGen = new MockIdGenerator( new Account() );
        Id id1 = accGen.getMockId();

        String errorCode = 'CUSTOM_VALIDATION_ERROR';
        String errorMsg = 'Custom Validation Error';
        Database.DeleteResult errorResult = daoMock.createMockDeleteResult(id1, false, errorCode, errorMsg);
        List<Database.Error> errors = errorResult.getErrors();
        StatusCode scode = errors[0].getStatusCode();

        
        String altErrorCode = 'UNABLE_TO_LOCK_ROW';
        String altErrorMsg = 'Unable To Lock Row';
        Database.DeleteResult altErrorResult = daoMock.createMockDeleteResult(id1, false, altErrorCode, altErrorMsg);
        errors = altErrorResult.getErrors();
        StatusCode altScode = errors[0].getStatusCode();

        Database.DeleteResult successResult = daoMock.createMockDeleteResult(id1, true,  errorCode, errorMsg);


        Test.startTest();

        Boolean check = daoMock.resultsProcessor.checkForSpecificError(successResult, scode, errorMsg);
        System.assertEquals(check, false, 'The check should be false because the Result is successful');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null, null);
        System.assertEquals(check, false, 'The check should be false because a specific error is not matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, scode, null);
        System.assertEquals(check, true, 'The check should be true because the StatusCode of the result is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, null,  errorMsg);
        System.assertEquals(check, true, 'The check should be true because the error message is matched');

        check = daoMock.resultsProcessor.checkForSpecificError(errorResult, altScode,  altErrorMsg);
        System.assertEquals(check, false, 'The check should be false because niether StatusCode or Error Message is matched'); 

        Test.stopTest();

    }

   
    // *********************************************
    // * DmlBaseMock
    // *********************************************
    private static final String ID_FIELD = 'Id';
    public abstract class DmlBaseMock implements FSL_DAO.DmlInterface {
        protected Map<Id, SObject> Records;
        public MockIdGenerator Builder;
    
        public DmlBaseMock( Map<Id, SObject> records, Schema.SObjectType objectType ) {
            this.Records = records;
            this.Builder = new MockIdGenerator( objectType );
        }
    
        public List<SObject> getRecords() {
            return this.Records.values();
        }
    
        public void insertRecords( List<SObject> newRecords ) {
            for( SObject record : newRecords ) {
                if( record.get( ID_FIELD ) != null ) {
                    throw new DmlException( 'Cannot insert a record with an ID.' );
                }
                Id recordId = Builder.getMockId();
                record.put( ID_FIELD, recordId );
                this.Records.put( (Id)recordId, record );
            }
        }
    
        public virtual void updateRecords( List<SObject> records ) {
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    throw new DmlException( 'Records to update must have a record Id.' );
                }
                this.Records.put( (Id)record.get( ID_FIELD ), record );
            }
        }
    
        public virtual void upsertRecords( List<SObject> records ) {
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    Id recordId = Builder.getMockId();
                    record.put( ID_FIELD, recordId );
                }
                this.Records.put( (Id)record.get( ID_FIELD ), record );
            }
        }
    
        public virtual void deleteRecords( List<SObject> records ) {
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    throw new DmlException( 'Records to delete must have a record Id.' );
                }
                this.Records.remove( (Id)record.get( ID_FIELD ) );
            }
        }

        public virtual Database.SaveResult[] insertRecords( List<SObject> newRecords, Boolean allOrNone  ) {
            List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
            for( SObject record : newRecords ) {
                if( record.get( ID_FIELD ) != null ) {
                    saveResults.add(createMockSaveResult((Id)record.get(ID_FIELD), false, 'UNEXPECTED ID', 'Cannot insert a record with an ID.'));
                }
                else {
                    
                    Id recordId = Builder.getMockId();
                    saveResults.add(createMockSaveResult(recordId, true, '', ''));
                    record.put( ID_FIELD, recordId );
                    this.Records.put( (Id)recordId, record );
                }
            }
            return saveResults;
        }

        public virtual Database.SaveResult[] updateRecords( List<SObject> records, Boolean allOrNone ) {
            List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    saveResults.add(createMockSaveResult(null, false, 'Null ID', 'Records to update must have a record Id.'));
                }
                else {
                    this.Records.put( (Id)record.get( ID_FIELD ), record );
                    saveResults.add(createMockSaveResult((Id)record.get( ID_FIELD ), true, '', ''));
                }
            }
            return saveResults;
        }

        public virtual Database.UpsertResult[] upsertRecords( List<SObject> records, Boolean allOrNone ) {
            List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    Id recordId = Builder.getMockId();
                    record.put( ID_FIELD, recordId );
                }
                this.Records.put( (Id)record.get( ID_FIELD ), record );
                upsertResults.add(createMockUpsertResult( (Id)record.get( ID_FIELD ), true, '', ''));
            }
            return upsertResults;
        }

        public virtual Database.DeleteResult[] deleteRecords(List<SObject> records, Boolean allOrNone )  {
            List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
            for( SObject record : records ) {
                if( record.get( ID_FIELD ) == null ) {
                    deleteResults.add(createMockDeleteResult(null, false, 'Null ID', 'Records to delete must have a record Id.'));
                }
                this.Records.remove( (Id)record.get( ID_FIELD ) );
                deleteResults.add(createMockDeleteResult((Id)record.get( ID_FIELD ), true, '', ''));
            }
            return deleteResults;
        }

        public Database.SaveResult createMockSaveResult(Id id, Boolean isSuccess, String errorCode, String errorMsg) {
            String jsonText = getResultJSON(id, isSuccess, errorCode, errorMsg) ;
            Database.SaveResult result = (Database.SaveResult) JSON.deserialize(jsonText, Database.SaveResult.class);
            return result;
        }

        public Database.UpsertResult createMockUpsertResult(Id id, Boolean isSuccess, String errorCode, String errorMsg) {
            String jsonText = getResultJSON(id, isSuccess, errorCode, errorMsg) ;
            Database.UpsertResult result = (Database.UpsertResult) JSON.deserialize(jsonText, Database.UpsertResult.class);
            return result;
        }

        public Database.DeleteResult createMockDeleteResult(Id id, Boolean isSuccess, String errorCode, String errorMsg) {
            String jsonText = getResultJSON(id, isSuccess, errorCode, errorMsg) ;
            Database.DeleteResult result = (Database.DeleteResult) JSON.deserialize(jsonText, Database.DeleteResult.class);
            return result;
        }

        public string getResultJSON(Id id, Boolean isSuccess, String errorCode, String errorMsg) {
            String jsonText = '{"success":';
            if ( isSuccess ) {
                jsonText += 'true,"id": "' + id + '"}';
            }
            else {
                jsonText += ('false,"errors":[{"message":"' + errorMsg + '","statusCode":"' + errorCode + '"}]}');
            }
            return jsonText;
        }

    }

    
    // *********************************************
    // * Tests for DmlBaseMock
    // * Test using a concrete implementation of the abstract class injected with a Results Processor
    // *********************************************

    
    // *********************************************
    // * DAOMockFactory
    // *********************************************
    public class DAOMockFactory {
        public DAOMock createDAOMock() {
            FSL_DAO.IDatabaseResultsProcessor resultsProcessor = new FSL_DAO.DatabaseResultsProcessor();
            return new DAOMock(resultsProcessor);
        }
    }

    // *********************************************
    // * DAOMock  - Concrete class to test DmlBaseMock funtions
    // *********************************************
    
    public class DAOMock extends DmlBaseMock {
        public FSL_DAO.IDatabaseResultsProcessor resultsProcessor;
        public DAOMock(FSL_DAO.IDatabaseResultsProcessor resultsProcessor) {
            super( new Map<Id, Account>(), Account.getSObjectType() );
            this.resultsProcessor = resultsProcessor;
        }
    }
  

    public static List<Account> createMockAccounts() {

        String firstAccountNumber = '123';
		String secondAccountNumber = '456';

        Account acc1 = new Account(  Name = 'Test Account 1', AccountNumber = firstAccountNumber );
        Account acc2 = new Account(  Name = 'Test Account 2', AccountNumber = secondAccountNumber );

        List <Account> accounts = new List<Account>();
        accounts.add(acc1);
        accounts.add(acc2);

        return accounts;
    }


    static TestMethod void testDmlBaseMock_insertRecords_DML_SuccessAndFailure() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        Test.startTest();
        dAOMock.insertRecords(accounts);
        List <Account> retrievedAccounts = daoMock.getRecords();

        System.assertEquals(retrievedAccounts[0].Id, accounts[0].Id);
        System.assertEquals(retrievedAccounts[1].Id, accounts[1].Id);


        accounts[0].id = null;
        Exception caughtException = null;
        try {
            daoMock.insertRecords(accounts);
        }
        catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();
        

        System.assertNotEquals(caughtException, null);
    }


    static TestMethod void testDmlBaseMock_insertRecords_Database_PartialSuccess() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        Test.startTest();
        daoMock.insertRecords(accounts, false);
        List <Account> retrievedAccounts = daoMock.getRecords();
       
        System.assertEquals(retrievedAccounts[0].Id, accounts[0].Id);
        System.assertEquals(retrievedAccounts[1].Id, accounts[1].Id);

        accounts[0].id = null;     
        Database.SaveResult[] saveResults = daoMock.insertRecords(accounts, false);

        Test.stopTest();

		System.assertEquals( true,  saveResults[0].isSuccess() );
        System.assertEquals( false,  saveResults[1].isSuccess() );

    }

    static TestMethod void testDmlBaseMock_updateRecords_DML_SuccessAndFailure() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();
    
        Test.startTest();

        daoMock.insertRecords(accounts);
        List <Account> retrievedAccounts = daoMock.getRecords();

        List<Account> updateAccounts = new List<Account>();
        updateAccounts.add(accounts[0]);
        updateAccounts[0].AccountNumber = '567';

        daoMock.updateRecords(updateAccounts);
        retrievedAccounts = daoMock.getRecords();

        System.assertEquals(retrievedAccounts[0].AccountNumber, updateAccounts[0].AccountNumber);
       
        updateAccounts[0].Id = null;
        Exception caughtException = null;
        try {
            daoMock.updateRecords(accounts);
        }
        catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();
        
        System.assertNotEquals(caughtException, null);
        System.assertEquals( caughtException.getMessage(), 'Records to update must have a record Id.');
    }



    static TestMethod void testDmlBaseMock_updateRecords_Database_PartialSuccess() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        Test.startTest();
        daoMock.insertRecords(accounts, false);
        List <Account> retrievedAccounts = daoMock.getRecords();
       
        System.assertEquals(retrievedAccounts[0].Id, accounts[0].Id);
        System.assertEquals(retrievedAccounts[1].Id, accounts[1].Id);

        List<Account> updateAccounts = new List<Account>();
        updateAccounts.add(accounts[0]);
        updateAccounts[0].AccountNumber = '567';
        updateAccounts.add(accounts[1]);
        updateAccounts[1].id = null;

        Database.SaveResult[] updateResults = daoMock.updateRecords(updateAccounts, false);
        retrievedAccounts = daoMock.getRecords();

        Test.stopTest();

		System.assertEquals( true,  updateResults[0].isSuccess() );
        System.assertEquals( false,  updateResults[1].isSuccess() );

        Boolean check = daoMock.resultsProcessor.checkForSpecificError(updateResults[1], null, 'Records to update must have a record Id.');
        System.assertEquals( true, check);

    }


    static TestMethod void testDmlBaseMock_upsertRecords_DML_SuccessAndFailure() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        String updatedAccountNumber = '567';
    
        Test.startTest();

        daoMock.insertRecords(accounts);
        List <Account> retrievedAccounts = daoMock.getRecords();

        Integer initialRecordCount = retrievedAccounts.size();

        List<Account> upsertAccounts = new List<Account>();
        upsertAccounts.add(accounts[0]);
        upsertAccounts[0].AccountNumber = updatedAccountNumber;
        upsertAccounts.add(accounts[1]);
        upsertAccounts[1].Id = null;

        daoMock.upsertRecords(upsertAccounts);
        retrievedAccounts = daoMock.getRecords();

        Test.stopTest();

        Integer newRecordCount = retrievedAccounts.size();

        System.assertEquals(newRecordCount, initialRecordCount + 1);
        System.assertEquals(retrievedAccounts[0].AccountNumber, updatedAccountNumber);
    
    }

    static TestMethod void testDmlBaseMock_upsertRecords_Database_PartialSuccess() {

        String updatedAccountNumber = '567';

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        Test.startTest();
        daoMock.insertRecords(accounts, false);
        List <Account> retrievedAccounts = daoMock.getRecords();
        Integer initialRecordCount = retrievedAccounts.size();
       
        System.assertEquals(retrievedAccounts[0].Id, accounts[0].Id);
        System.assertEquals(retrievedAccounts[1].Id, accounts[1].Id);

        List<Account> upsertAccounts = new List<Account>();
        upsertAccounts.add(accounts[0]);
        upsertAccounts[0].AccountNumber = updatedAccountNumber;
        upsertAccounts.add(accounts[1]);
        upsertAccounts[1].Id = null;

        Database.UpsertResult[] upsertResults = daoMock.upsertRecords(upsertAccounts, false);
        retrievedAccounts = daoMock.getRecords();
        Integer newRecordCount = retrievedAccounts.size();

        Test.stopTest();

		System.assertEquals( true,  upsertResults[0].isSuccess() );
        System.assertEquals( true,  upsertResults[1].isSuccess() );
        System.assertEquals(newRecordCount, initialRecordCount + 1);
        System.assertEquals(retrievedAccounts[0].AccountNumber, updatedAccountNumber);


        Boolean check = daoMock.resultsProcessor.checkForSpecificError(upsertResults[1], null, 'Records to update must have a record Id.');
        System.assertEquals(false, check);

    }

    static TestMethod void testDmlBaseMock_deleteRecords_DML_SuccessAndFailure() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();
    
        Test.startTest();

        daoMock.insertRecords(accounts);
        List <Account> retrievedAccounts = daoMock.getRecords();
        Integer initialRecordCount = retrievedAccounts.size();

        List<Account> deleteAccounts = new List<Account>();
        deleteAccounts.add(accounts[0]);

        daoMock.deleteRecords(deleteAccounts);

        retrievedAccounts = daoMock.getRecords();
        Integer newRecordCount = retrievedAccounts.size();

        System.assertEquals(newRecordCount, initialRecordCount - 1);
       
        deleteAccounts[0].Id = null;
        Exception caughtException = null;
        try {
            daoMock.deleteRecords(accounts);
        }
        catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();
        
        System.assertNotEquals(caughtException, null);
        System.assertEquals( caughtException.getMessage(), 'Records to delete must have a record Id.');
    
    }

    static TestMethod void testDmlBaseMock_DeleteRecords_Database_PartialSuccess() {

        DAOMock daoMock = new DAOMockFactory().createDAOMock();
        List <Account> accounts = createMockAccounts();

        Test.startTest();
        daoMock.insertRecords(accounts, false);
        List <Account> retrievedAccounts = daoMock.getRecords();

        Integer initialRecordCount = retrievedAccounts.size();

        List<Account> deleteAccounts = new List<Account>();
        deleteAccounts.add(accounts[0]);
        deleteAccounts.add(accounts[1]);
        deleteAccounts[1].id = null;

        Database.DeleteResult[] deleteResults = daoMock.deleteRecords(deleteAccounts, false);

        retrievedAccounts = daoMock.getRecords();
        Integer newRecordCount = retrievedAccounts.size();

        Test.stopTest();

		System.assertEquals( true,  deleteResults[0].isSuccess() );
        System.assertEquals( false,  deleteResults[1].isSuccess() );
        System.assertEquals(newRecordCount, initialRecordCount - 1);

        Boolean check = daoMock.resultsProcessor.checkForSpecificError(deleteResults[1], null, 'Records to delete must have a record Id.');
        System.assertEquals( true, check);

    }



    static TestMethod void testGetResultJSON() {

        // Needed this test to make sure mock DataBase.SaveResult, etc. 
        // are constructed properly for use in other tests

        MockIdGenerator accGen = new MockIdGenerator( new Account() );
        Id id  = accGen.getMockId();

        Boolean isSuccess = true;
        String errorCode = 'CUSTOM_VALIDATION_ERROR';
        String errorMsg = 'Duplicate Entries Found';

       DAOMock daoMock = new DAOMockFactory().createDAOMock();

        Test.startTest();
        String jsonText1 = daoMock.getResultJSON(id, isSuccess, errorCode, errorMsg) ;
        System.assertEquals(jsonText1, '{"success":true,"id": "' + id + '"}');

        isSuccess = false;
        String jsonText2 = daoMock.getResultJSON(id, isSuccess, errorCode, errorMsg) ;
        System.assertEquals(jsonText2, '{"success":false,"errors":[{"message":"' + errorMsg + '","statusCode":"' + errorCode +'"}]}');

        Test.stopTest();
    }
}