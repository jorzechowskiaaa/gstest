@IsTest
public with sharing class FSL_WorkOrderRetrieveApiTest {
    @IsTest
    public static void testWorkOrderRetrieveApi_RetrieveWorkOrders_CallIdAndDate_RetrievedAndParsed() {
        FSL_WorkOrderJsonWrapper.WorkOrderJson expectedWorkOrderJson = new FSL_WorkOrderJsonWrapper.WorkOrderJson();

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest request = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest();
        request.transactionID = 'Transaction Id';
        request.searchMethod = 'CallIdAndDate';
        request.searchCriteria = new List<FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria>();
        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria criterion = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria();
        criterion.callDate = 'Call Date';
        criterion.callId = 'Call Id';
        request.searchCriteria.add( criterion );

        List<FSL_WorkOrder.WorkOrder> workOrders = new List<FSL_WorkOrder.WorkOrder>();

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersByCallIdAndCallDateReturnValue = workOrders;
        FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock wrapper = new FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock();
        wrapper.wrapReturnValue = expectedWorkOrderJson;

        FSL_WorkOrderRetrieveApi.workOrderService = workOrderService;
        FSL_WorkOrderRetrieveApi.wrapper = wrapper;

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrders/retrieve/retrieveWorkOrders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize( request ) );

        RestContext.request = req;
        RestContext.response= res;

        System.assertEquals( 0, workOrderService.getWorkOrdersByCallIdAndCallDateCallCount, 'WorkOrderService.getWorkOrdersByCallIdAndCallDate has been called' );
        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson actualWorkOrderJson = FSL_WorkOrderRetrieveApi.retrieveWorkOrders();
        Test.stopTest();

        System.assertEquals( 200, res.statusCode, 'Response status code is not 200' );
        System.assertEquals( expectedWorkOrderJson, actualWorkOrderJson, 'Json response is not as expected' );
        System.assertEquals( 1, workOrderService.getWorkOrdersByCallIdAndCallDateCallCount, 'WorkOrderService.getWorkOrdersByCallIdAndCallDate has not been called' );
        System.assertEquals( 1, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has not been called' );
    }

    @IsTest
    public static void testWorkOrderRetrieveApi_RetrieveWorkOrders_ActiveAndMembershipNumber_RetrievedAndParsed() {
        FSL_WorkOrderJsonWrapper.WorkOrderJson expectedWorkOrderJson = new FSL_WorkOrderJsonWrapper.WorkOrderJson();

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest request = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest();
        request.transactionID = 'Transaction Id';
        request.searchMethod = 'ActiveAndMembershipNumber';
        request.searchCriteria = new List<FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria>();
        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria criterion = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria();
        criterion.membershipNumber = 'Membership Number';
        request.searchCriteria.add( criterion );

        List<FSL_WorkOrder.WorkOrder> workOrders = new List<FSL_WorkOrder.WorkOrder>();
        List<Contact> contacts = new List<Contact>{ new Contact() };

        FSL_ContactTest.ContactServiceMock contactService = new FSL_ContactTest.ContactServiceMock();
        contactService.getContactsByMembershipNumberReturnValue = contacts;
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersByCallIdAndCallDateReturnValue = workOrders;
        FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock wrapper = new FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock();
        wrapper.wrapReturnValue = expectedWorkOrderJson;

        FSL_WorkOrderRetrieveApi.contactService = contactService;
        FSL_WorkOrderRetrieveApi.workOrderService = workOrderService;
        FSL_WorkOrderRetrieveApi.wrapper = wrapper;

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrders/retrieve/retrieveWorkOrders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize( request ) );

        RestContext.request = req;
        RestContext.response= res;

        System.assertEquals( 0, contactService.getContactsByMembershipNumberCallCount, 'ContactService.getContactsByMembershipNumber has been called' );
        System.assertEquals( 0, workOrderService.getActiveWorkOrdersByContactIdCallCount, 'WorkOrderService.getActiveWorkOrdersByContactId has been called' );
        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson actualWorkOrderJson = FSL_WorkOrderRetrieveApi.retrieveWorkOrders();
        Test.stopTest();

        System.assertEquals( 200, res.statusCode, 'Response status code is not 200' );
        System.assertEquals( expectedWorkOrderJson, actualWorkOrderJson, 'Json response is not as expected' );
        System.assertEquals( 1, contactService.getContactsByMembershipNumberCallCount, 'ContactService.getContactsByMembershipNumber has not been called' );
        System.assertEquals( 1, workOrderService.getActiveWorkOrdersByContactIdCallCount, 'WorkOrderService.getActiveWorkOrdersByContactId has not been called' );
        System.assertEquals( 1, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has not been called' );
    }

    @IsTest
    public static void testWorkOrderRetrieveApi_RetrieveWorkOrders_ActiveAndAni_RetrievedAndParsed() {
        FSL_WorkOrderJsonWrapper.WorkOrderJson expectedWorkOrderJson = new FSL_WorkOrderJsonWrapper.WorkOrderJson();

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest request = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest();
        request.transactionID = 'Transaction Id';
        request.searchMethod = 'ActiveAndAni';
        request.searchCriteria = new List<FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria>();
        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria criterion = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria();
        criterion.ani = 'ANI';
        request.searchCriteria.add( criterion );

        List<FSL_WorkOrder.WorkOrder> workOrders = new List<FSL_WorkOrder.WorkOrder>();
        List<Contact> contacts = new List<Contact>{ new Contact() };

        FSL_ContactTest.ContactServiceMock contactService = new FSL_ContactTest.ContactServiceMock();
        contactService.getContactsByPhoneNumberReturnValue = contacts;
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        workOrderService.getWorkOrdersByCallIdAndCallDateReturnValue = workOrders;
        FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock wrapper = new FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock();
        wrapper.wrapReturnValue = expectedWorkOrderJson;

        FSL_WorkOrderRetrieveApi.contactService = contactService;
        FSL_WorkOrderRetrieveApi.workOrderService = workOrderService;
        FSL_WorkOrderRetrieveApi.wrapper = wrapper;

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrders/retrieve/retrieveWorkOrders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize( request ) );

        RestContext.request = req;
        RestContext.response= res;

        System.assertEquals( 0, contactService.getContactsByPhoneNumberCallCount, 'ContactService.getContactsByPhoneNumber has been called' );
        System.assertEquals( 0, workOrderService.getActiveWorkOrdersByContactIdCallCount, 'WorkOrderService.getActiveWorkOrdersByContactId has been called' );
        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson actualWorkOrderJson = FSL_WorkOrderRetrieveApi.retrieveWorkOrders();
        Test.stopTest();

        System.assertEquals( 200, res.statusCode, 'Response status code is not 200' );
        System.assertEquals( expectedWorkOrderJson, actualWorkOrderJson, 'Json response is not as expected' );
        System.assertEquals( 1, contactService.getContactsByPhoneNumberCallCount, 'ContactService.getContactsByPhoneNumber has not been called' );
        System.assertEquals( 1, workOrderService.getActiveWorkOrdersByContactIdCallCount, 'WorkOrderService.getActiveWorkOrdersByContactId has not been called' );
        System.assertEquals( 1, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has not been called' );
    }

    @IsTest
    public static void testWorkOrderRetrieveApi_RetrieveWorkOrders_InvalidSearchMethod_StatusCode500() {
        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest request = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest();
        request.transactionID = 'Transaction Id';
        request.searchMethod = 'Something invalid';
        request.searchCriteria = new List<FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersSearchCriteria>();

        FSL_ContactTest.ContactServiceMock contactService = new FSL_ContactTest.ContactServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock wrapper = new FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock();
        
        FSL_WorkOrderRetrieveApi.contactService = contactService;
        FSL_WorkOrderRetrieveApi.workOrderService = workOrderService;
        FSL_WorkOrderRetrieveApi.wrapper = wrapper;

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrders/retrieve/retrieveWorkOrders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize( request ) );

        RestContext.request = req;
        RestContext.response= res;

        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson actualWorkOrderJson = FSL_WorkOrderRetrieveApi.retrieveWorkOrders();
        Test.stopTest();

        System.assertEquals( 500, res.statusCode, 'Response status code is not 500' );
        System.assertNotEquals( null, actualWorkOrderJson, 'Json response is null' );
        System.assertEquals( 500, actualWorkOrderJson.statusCode, 'Json status code is not 500' );
        System.assertEquals( 'Invalid Search Method', actualWorkOrderJson.statusDescription, 'Json status description is not as expected' );
        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );
    }

    @IsTest
    public static void testWorkOrderRetrieveApi_RetrieveWorkOrders_InvalidRequest_StatusCode500() {
        FSL_ContactTest.ContactServiceMock contactService = new FSL_ContactTest.ContactServiceMock();
        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock wrapper = new FSL_WorkOrderJsonWrapperTest.WorkOrderJsonWrapperMock();
        
        FSL_WorkOrderRetrieveApi.contactService = contactService;
        FSL_WorkOrderRetrieveApi.workOrderService = workOrderService;
        FSL_WorkOrderRetrieveApi.wrapper = wrapper;

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/WorkOrders/retrieve/retrieveWorkOrders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( '' );

        RestContext.request = req;
        RestContext.response= res;

        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson actualWorkOrderJson = FSL_WorkOrderRetrieveApi.retrieveWorkOrders();
        Test.stopTest();

        System.assertEquals( 500, res.statusCode, 'Response status code is not 500' );
        System.assertNotEquals( null, actualWorkOrderJson, 'Json response is null' );
        System.assertEquals( 500, actualWorkOrderJson.statusCode, 'Json status code is not 500' );
        System.assertEquals( 'Invalid Request', actualWorkOrderJson.statusDescription, 'Json status description is not as expected' );
        System.assertEquals( 0, wrapper.wrapCallCount, 'WorkOrderJsonWrapper.wrap has been called' );
    }
    
    // *********************************************
    // * ApplicationLog
    // *********************************************
    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_Constructor_DefaultFieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( 'RetrieveWorkOrders', appLog.Operation__c );
        System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
        System.assertNotEquals( null, appLog.DateTime__c );
    }

    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_LogParseRequestFailure_FieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = 'Request Body';

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        log.logParseRequestFailure( new FSL_WorkOrderRetrieveApi.InvalidRequestException(), requestBody );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( requestBody, appLog.Request_Body__c );
        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Failed to parse the request' ) );
    }

    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_LogInvalidSearchMethod_FieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = 'Request Body';

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        log.logInvalidSearchMethod( new FSL_WorkOrderRetrieveApi.InvalidSearchMethodException(), requestBody );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( requestBody, appLog.Request_Body__c );
        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Invalid Search method' ) );
    }

    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_LogParseException_FieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = 'Request Body';

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        log.logParseException( new FSL_WorkOrderRetrieveApi.ParseException(), requestBody );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( requestBody, appLog.Request_Body__c );
        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Exception while parsing' ) );
    }

    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_LogGenericException_FieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = 'Request Body';

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        log.logGenericException( new DmlException(), requestBody );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( requestBody, appLog.Request_Body__c );
        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Generic exception' ) );
    }

    @IsTest
    public static void testRetrieveWorkOrdersApplicationLog_LogResponse_FieldsSet() {
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = 'Request Body';
        FSL_WorkOrderJsonWrapper.WorkOrderJson workOrderJson = new FSL_WorkOrderJsonWrapper.WorkOrderJson();
        String expectedResponseBody = JSON.serializePretty( workOrderJson );

        FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog log = new FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersApplicationLog();
        log.logResponse( requestBody, workOrderJson );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( requestBody, appLog.Request_Body__c );
        System.assertEquals( expectedResponseBody, appLog.Response_Body__c );
        System.assertEquals( false, appLog.Error_Caught__c );
        System.assertEquals( 'Retrieve successfully completed', appLog.Success_Message__c );
    }
}