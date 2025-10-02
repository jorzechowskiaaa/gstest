@istest
public with sharing class FSL_CallCommentsTest {
    public FSL_CallCommentsTest() {
    }

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_CallComments.IFactory factory = new FSL_CallComments.Factory();

        Test.startTest();
        FSL_CallComments.ICallCommentsService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }


   
    // *********************************************
    // * DAO
    // *********************************************

    private static void createDaoData() {
        integer recordCount = 1;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        contacts[0].AccountId = accounts[0].Id;
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        WorkOrder wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[0] );
        wo.status = 'Cleared';
        wo.Cleared_Timestamp__c =  System.today() - 5;
        workOrders.add( wo );
        insert workOrders;

        List<FSL_Call_Comments__c > allComments = FSL_DataFactory.CreatecallComments(WorkOrders[0].id);
        insert allComments;
    }

    @IsTest
    public static void testCallCommentsMergeSubFlow_Success() {

        createDaoData();

        List<FSL_Call_Comments__c> allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];

        System.assertEquals(2, allComments.size(), 'There should be 2 Call Comments before running the SubFlow.');
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('varWorkOrderId', allComments[0].FSL_Work_Order__c);

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Call_Comments_Merge_SubFlow', inputs);
        mySubFlow.start();
        String msg = (String)mySubFlow.getVariableValue('varOutputMessage');

        allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];
        Test.stopTest();
        System.assertEquals(1, allComments.size(), 'There should be 1 Call Comment after running the SubFlow.');
    }

    @IsTest
    public static void testCallCommentsByDateRangeSubFlow_WithinDateRange() {

        createDaoData();

        List<FSL_Call_Comments__c> allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];

        System.assertEquals(2, allComments.size(), 'There should be 2 Call Comments before running the SubFlow within Date Range.');
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('varDateFrom', System.Today() - 6);
        inputs.put('varDateTo', System.Today() - 4);

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Call_Comments_By_Date_Range_SubFlow', inputs);
        mySubFlow.start();
        String msg = (String)mySubFlow.getVariableValue('varFinalMessage');

        allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];
        Test.stopTest();
        System.assertEquals(1, allComments.size(), 'There should be 1 Call Comment after running the SubFlow within Date Range.');
    }    

    @IsTest
    public static void testCallCommentsByDateRangeSubFlow_OutsideDateRange() {

        createDaoData();

        List<FSL_Call_Comments__c> allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];

        System.assertEquals(2, allComments.size(), 'There should be 2 Call Comments before running the SubFlow outside Date Range.');
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('varDateFrom', System.Today() - 3);
        inputs.put('varDateTo', System.Today() - 2);

        Flow.Interview mySubFlow = Flow.Interview.CreateInterview('Call_Comments_By_Date_Range_SubFlow', inputs);
        mySubFlow.start();
        String msg = (String)mySubFlow.getVariableValue('varFinalMessage');

        allComments = [SELECT Id, FSL_Work_Order__c FROM FSL_Call_Comments__c];
        Test.stopTest();
        System.assertEquals(2, allComments.size(), 'There should be 1 Call Comment after running the SubFlow outside Date Range.');
    }    

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testCallCommentsService_SaveWorkOrderComments_CommentMapProvided_CommentsInserted() {
        CallCommentsDAOMock dao = new CallCommentsDAOMock();
        FSL_CallComments.ICallCommentsService service = new FSL_CallComments.CallCommentsService( dao );
       
        Id workOrderId = dao.Builder.getMockId( Schema.WorkOrder.getSObjectType() );
        WorkOrder wo = new WorkOrder( Id = workOrderId, ServiceTerritoryId = dao.Builder.getMockId( Schema.ServiceTerritory.getSObjectType() ) );

        String testComment = 'Some Comment';
        List <String> comments = new List<String>();
        comments.add(testComment);
        Map<Id, List<String>> allComments = new Map<Id, List<String>>();
        allComments.put(workOrderId, comments);
    
        Test.startTest();
        service.saveWorkOrderComments(allComments);
        Test.stopTest();

        System.assertEquals(1, dao.comments.size());
        System.assertEquals( testComment, dao.comments.values()[dao.comments.size() - 1].FSL_Comment__c);
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_CallComments.IFactory {
        public FSL_CallComments.ICallCommentsService createService() {
            return new CallCommentsServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_CallComments.ICallCommentsService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType CALL_COMMENT_TYPE = Schema.FSL_Call_Comments__c.getSObjectType();
    public class CallCommentsDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_CallComments.ICallCommentsDAO {

        public Map<Id, FSL_Call_Comments__c> comments;
        public Boolean isSuccess = true;

        public CallCommentsDAOMock()  {
            super( new Map<Id, FSL_Call_Comments__c>(), CALL_COMMENT_TYPE);
            this.comments = (Map<Id, FSL_Call_Comments__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from CallCommentsDAOMock' );
            }
        }
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class CallCommentsServiceMock implements FSL_CallComments.ICallCommentsService {
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in CallCommentsServiceMock' );
            }
        }

        public Integer saveWorkOrderCommentsCallCount = 0;
        public void saveWorkOrderComments(Map<Id, List<String>> comments) {
            ++saveWorkOrderCommentsCallCount;
            throwExceptionIfConfigured();
        }
    }

    
    @IsTest
    public static void testCallCommentsServiceMock_SaveWorkOrderComments_CallCountIncremented() {
        CallCommentsServiceMock service = new CallCommentsServiceMock();
        
        System.assertEquals( 0, service.saveWorkOrderCommentsCallCount );

        Test.startTest();
        service.saveWorkOrderComments( new Map<Id, List<String>>());
        Integer callCount1 = service.saveWorkOrderCommentsCallCount;

        service.saveWorkOrderComments( null );
        Integer callCount2 = service.saveWorkOrderCommentsCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testCallCommentsServiceMock_SaveWorkOrderComments_ConfigureException_ExceptionThrown() {
        CallCommentsServiceMock service = new CallCommentsServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.saveWorkOrderCommentsCallCount );

        Test.startTest();
        try {
            service.saveWorkOrderComments(null);
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.saveWorkOrderCommentsCallCount );
    }

}