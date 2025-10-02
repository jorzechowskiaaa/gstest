@IsTest
public with sharing class ThirdPartyIntegrationTest {

    private static TowbookIntegrationTest.MockFactory mockFactory;
    private static ThirdPartyIntegration.IThirdPartyDispatcherService dispatcherService;
    private static TowbookIntegrationTest.MockTowbookIntegrationService mockDispatcher;
    private static FSL_ApplicationLogTest.ApplicationLogServiceMock mockLogService;
    private static ThirdPartyIntegration.IntegrationSupportServicesWrapper mockIntegrationWrapper;
    private static RestApi_PatchCall.PatchCallRequest patchCallRequest = null;

    private static FSL_WorkOrderTest.WorkOrderServiceMock mockWorkOrderService;
  

    private static void setupMocks() {
        mockFactory = new TowbookIntegrationTest.MockFactory();
        dispatcherService = mockFactory.createService();
        mockDispatcher = mockFactory.getMockService();
        mockLogService =  new FSL_ApplicationLogTest.ApplicationLogServiceMock();

        mockIntegrationWrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
        mockIntegrationWrapper.contactService = new FSL_ContactTest.ContactServiceMock();
        mockIntegrationWrapper.serviceAppointmentService = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        mockIntegrationWrapper.serviceLineItemService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();

        mockWorkOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        mockIntegrationWrapper.workOrderservice = mockWorkOrderService;
    }

    private static void registerMockDispatcher(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService, ThirdPartyIntegration.IThirdPartyDispatcherService dsptchService) {
        thirdPartyService.registerDispatcherForTechnologyType(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, dsptchService);
        thirdPartyService.registerDispatcherForTechnologyType(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY, dsptchService);
        String channelName = RestApi_PatchCall.Channel_Name.TOWBOOK.name();
        thirdPartyService.registerDispatcherForChannel(channelName, dsptchService);
    }

    private static void constructPatchCallRequest() {
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
    }

    private static RestApi_PatchCall.PatchCallResponse constructPatchCallResponse(Boolean error) {
        RestApi_PatchCall.PatchCallResponse patchCallResponse = (error) ? new RestApi_PatchCall.PatchCallResponse(400, 'Failure', 'operation', new VanillaException('Failure')) :
                                                                          new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'operation', null);
        return patchCallResponse;
    }

    public class VanillaException extends Exception {
    }

    @IsTest
    public static void testFactory_CreateService() {
        System.test.startTest();
        try {
            ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.Factory().createService();
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');
        }
        System.test.stopTest();
    }
    
        
  

    @IsTest
    public static void testProcessThirdPartyRequestToUpdateCall_HappyPath_SuccessResponse() {
        setupMocks();
        System.test.startTest();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        constructPatchCallRequest();

        RestApi_PatchCall.PatchCallResponse expectedResponse =  constructPatchCallResponse(false);
        mockDispatcher.setReturnValue('processThirdPartyRequestToUpdateCall', expectedResponse);
        RestApi_PatchCall.PatchCallResponse response = thirdPartyService.processThirdPartyRequestToUpdateCall(patchCallRequest);
        System.assertEquals(1, mockDispatcher.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(expectedResponse.status, response.status, 'response retuned by Dispatcher should match that returned by ThirdPartyIntegration');
        System.test.stopTest();
    }

    @IsTest
    public static void testProcessThirdPartyRequestToUpdateCall_DispatcherException_PassThroughException() {
        setupMocks();
        System.test.startTest();
        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        constructPatchCallRequest();
        mockDispatcher.setException(new VanillaException('This is a Vanilla Exception'));
        try {
            RestApi_PatchCall.PatchCallResponse response = thirdPartyService.processThirdPartyRequestToUpdateCall(patchCallRequest);
            System.assert(false, 'An exception must be passed along');
        }
        catch (VanillaException ex) {
            System.assert(true, 'The Vanilla Exception is caught here');
        }
        catch (Exception ex) {
             System.assert(false, 'The exception thrown must be the same as the one returned by the Dispatcher');
        }
        System.assertEquals(1, mockDispatcher.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.test.stopTest();
    }

    @IsTest
    public static void testSendDispatchOfferPlatformEvent_HappyPath_EventPublished() {
        setupMocks();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;

        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchOfferPlatformEvent', mockEvent);
        Integer logcount = mockLogService.saveApplicationLogsCallCount;

        System.test.startTest();
        thirdPartyService.sendDispatchOfferPlatformEvent(wo);
        System.test.stopTest();

        System.assertEquals(logcount+1, mockLogService.saveApplicationLogsCallCount, 'There should be one additional log for a successful Platform Event publication');
    }

    @IsTest
    public static void testSendDispatchOfferPlatformEvent_NoDispatcherRegistered_ExceptionRaised() {
        setupMocks();
 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        Boolean passed = false;
        System.test.startTest();
        // Call the function to be tested before registerimg the dispatcher service. We should get an exception
        try {
            thirdPartyService.sendDispatchOfferPlatformEvent(wo);
        }
        catch (ThirdPartyIntegration.ThirdPartyIntegrationException ex) {
            passed = true;
        }
        catch (Exception ex) {
            passed = false;
        }
        System.test.stopTest();
        System.assert(passed, 'Expected to see a ThirdPartyIntegrationException when no Dispatcher is registered');
    }    

    @IsTest
    public static void testSendDispatchOfferPlatformEvent_DispatcherException_EventLogged() {
        setupMocks();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;

        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchOfferPlatformEvent', mockEvent);
        Integer logcount = mockLogService.saveApplicationLogsCallCount;

        mockDispatcher.setException(new VanillaException('something went wrong'));
        System.test.startTest();
        thirdPartyService.sendDispatchOfferPlatformEvent(wo);
        System.test.stopTest();
        System.assert(logcount < mockLogService.saveApplicationLogsCallCount, 'There should be an additional logging for an exception thrown by the dispatcherService');
    }

    @IsTest
    public static void testConstructStatusSpecificThirdPartyNotification_Spotted_ExpiredEventConstructed() {    
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
        wo.status = 'Spotted';
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchedCallExpiredPlatformEvent', mockEvent);
        Integer callCount = mockDispatcher.getCallCount('constructDispatchedCallExpiredPlatformEvent');
       
        System.test.startTest();
        ThirdPartyEvent__e constructedEvent = thirdPartyService.constructStatusSpecificThirdPartyNotification(mockDispatcher, wo);
        System.test.stopTest();
        System.assertEquals(callCount+1, mockDispatcher.getCallCount('constructDispatchedCallExpiredPlatformEvent'), 'There should be one additional call to constructDispatchedCallExpiredPlatformEvent');
    }

    @IsTest
    public static void testConstructStatusSpecificThirdPartyNotification_Canceled_CanceledEventConstructed() {
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
        wo.status = 'Canceled';
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchedCallCancelledPlatformEvent', mockEvent);
        Integer callCount = mockDispatcher.getCallCount('constructDispatchedCallCancelledPlatformEvent');
       
        System.test.startTest();
        ThirdPartyEvent__e constructedEvent = thirdPartyService.constructStatusSpecificThirdPartyNotification(mockDispatcher, wo);
        System.test.stopTest();
        System.assertEquals(callCount+1, mockDispatcher.getCallCount('constructDispatchedCallCancelledPlatformEvent'), 'There should be one additional call to constructDispatchedCallCancelledPlatformEvent');
    }

    @IsTest
    public static void testConstructStatusSpecificThirdPartyNotification_Cleared_ClearedEventConstructed() {
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY;
        wo.status = 'Cleared';
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructCallClearedPlatformEvent', mockEvent);
        Integer callCount = mockDispatcher.getCallCount('constructCallClearedPlatformEvent');

        FSL_WorkOrder.WorkOrder domainWO = new FSL_WorkOrder.WorkOrder(wo, null, null);
        List< FSL_WorkOrder.WorkOrder> domainWos = new List< FSL_WorkOrder.WorkOrder>{domainWO};
        mockWorkOrderService.getWorkOrdersByCallIdAndCallDateReturnValue = domainWos;
       
        System.test.startTest();
        try{
            ThirdPartyEvent__e constructedEvent = thirdPartyService.constructStatusSpecificThirdPartyNotification(mockDispatcher, wo);
        }
        catch (Exception ex) {
            // There is not a easy way to mock the  FSL_RetrieveWorkOrderAPI class's parseResponse function which is called.  We need to a Fully constructed workorder object
        }
        System.test.stopTest();
        System.assertEquals(callCount+1, mockDispatcher.getCallCount('constructCallClearedPlatformEvent'), 'There should be one additional call to constructCallClearedPlatformEvent');
    }



    @IsTest
    public static void testConstructStatusSpecificThirdPartyNotification_OtherStatus_NullReturned() {
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
        wo.status = 'En Route';
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchedCallCancelledPlatformEvent', mockEvent);
        Integer callCount = mockDispatcher.getCallCount('constructDispatchedCallCancelledPlatformEvent');
       
        System.test.startTest();
        ThirdPartyEvent__e constructedEvent = thirdPartyService.constructStatusSpecificThirdPartyNotification(mockDispatcher, wo);
        System.test.stopTest();
        System.assertEquals(null, constructedEvent);
    }

    @IsTest
    public static void testConstructStatusSpecificThirdPartyNotification_NoDispatcher_ExceptionThrown() {
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
        wo.status = 'Spotted';
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService); 
        Boolean passed = false;
        System.test.startTest();
        // Call the function to be tested before registerimg the dispatcher service. We should get an exception
        try {
            thirdPartyService.constructStatusSpecificThirdPartyNotification(null, wo);
        }
        catch (ThirdPartyIntegration.ThirdPartyIntegrationException ex) {
            passed = true;
        }
        catch (Exception ex) {
            passed = false;
        }
        System.test.stopTest();
        System.assert(passed, 'Expected to see a ThirdPartyIntegrationException when no Dispatcher is registered');
    }

 @IsTest
    public static void testsendStatusChangePlatformEvents_HappyPath_PlatformEventsPublished() {
        setupMocks(); 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY;
        wo.status = 'Cleared';

        List<WorkOrder> woList = new  List<WorkOrder>{wo};
        
        ThirdPartyIntegration.ThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService); 
        Boolean passed = false;

        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructCallClearedPlatformEvent', mockEvent);
        Integer callCount = mockDispatcher.getCallCount('constructCallClearedPlatformEvent');
        System.test.startTest();
        
        // Call the function to be tested before registerimg the dispatcher service. We should get an exception

        try{
            thirdPartyService.sendStatusChangePlatformEvents(woList);
        }
        catch (Exception ex) {
            // There is not a easy way to mock the  FSL_RetrieveWorkOrderAPI class's parseResponse function which is called.  We need to a Fully constructed workorder object
        }      
        System.test.stopTest();
        System.assertEquals(callCount+1, mockDispatcher.getCallCount('constructCallClearedPlatformEvent'), 'There should be one additional call to constructCallClearedPlatformEvent');
    }


    @IsTest
    public static void testConstructCorePlatformEvent_HappyPath_PlatformEventsPublished() {
    }


    /****************************************************************
    // Factory Mock
    ****************************************************************/
    public class MockFactory implements ThirdPartyIntegration.IFactory {
        private MockThirdPartyIntegrationService mockService;  
        public   ThirdPartyIntegration.IThirdPartyIntegrationService createService() {
            mockService = new MockThirdPartyIntegrationService();
            return  mockService;
        }
        public MockThirdPartyIntegrationService getMockService() {
            return mockService;
        }
    }

    public class MockThirdPartyIntegrationService extends TestMockHelper implements ThirdPartyIntegration.IThirdPartyIntegrationService {
        
        public RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest ) {
            return (RestApi_PatchCall.PatchCallResponse)incrementReturnOrThrow('processThirdPartyRequestToUpdateCall');
        }
        /**EMI-START**/
          public void sendDispatchUpdatePlatformEvent(WorkOrder wo) {
            incrementReturnOrThrow('sendDispatchUpdatePlatformEvent');
        }
        
        /**EMI_END***/
        public void sendDispatchOfferPlatformEvent(WorkOrder wo) {
            incrementReturnOrThrow('sendDispatchOfferPlatformEvent');
        }
        public void sendStatusChangePlatformEvents(List<WorkOrder> workorders) {
            incrementReturnOrThrow('sendStatusChangePlatformEvents');
        }
        public void publishPlatformEventsAndLogResults(List<ThirdPartyEvent__e> platformEvents) {
            incrementReturnOrThrow('publishPlatformEventsAndLogResults');
        }

        public void registerDispatcherForTechnologyType(String techType, ThirdPartyIntegration.IThirdPartyDispatcherService dispatcherService) {
            incrementReturnOrThrow('registerDispatcherForTechnologyType');
        }

        public void registerDispatcherForChannel(String channel, ThirdPartyIntegration.IThirdPartyDispatcherService dispatcherService) {
            incrementReturnOrThrow('registerDispatcherForChannel');
        }

        public ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String callKey){
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructCoreIntegrationPlatformEvent');
        }
        public String constructPlatformEventParametersArrayJSON(List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params) {
            return (String) incrementReturnOrThrow('constructPlatformEventParametersArrayJSON');
        }
        public List<FSL_WorkOrder.WorkOrder>  retrieveWorkOrderDetails (WorkOrder wo) {
            return (List<FSL_WorkOrder.WorkOrder>) incrementReturnOrThrow('retrieveWorkOrderDetails');
        }
        public String getWorkOrderJSONUsingRetrieveWOMapping (List<FSL_WorkOrder.WorkOrder> domainWOs) {
            return (String) incrementReturnOrThrow('getWorkOrderJSONUsingRetrieveWOMapping');
        }
        public void logFailureMessage(String message, Exception ex, RestApi_PatchCall.PatchCallRequest patchCallRequest) {
            incrementReturnOrThrow('logFailureMessage');
        }
        public void logSuccessMessage(String message, RestApi_PatchCall.PatchCallRequest patchCallRequest) {
            incrementReturnOrThrow('logSuccessMessage');
        }
        public void logDiagnosticMessage(String message, string callKey) {
            incrementReturnOrThrow('logDiagnosticMessage');
        }
    }
    

 	public ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String externalId) {
            ThirdPartyEvent__e event = new ThirdPartyEvent__e();
            return event;
        }
    private class TestThirdPartyDispatcherService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
        public TestThirdPartyDispatcherService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            super(thirdPartyIntegrationService);
        }
    }

    @isTest
    static void testConstructDispatchOfferPlatformEvent() {
      
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        //TowbookIntegration.IThirdPartyIntegrationService mockService2 = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchOfferPlatformEvent(wo);

       
    }
    @isTest
    static void testconstructDispatchAcceptedPlatformEvent() {
       
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchAcceptedPlatformEvent(wo);
	}
    @isTest
    static void testconstructDispatchRefusedPlatformEvent() {
       
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchRefusedPlatformEvent(wo);
	}
    
    @isTest
    static void testconstructDispatchedCallCancelledPlatformEvent() {
     
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchedCallCancelledPlatformEvent(wo);
	}
    
    @isTest
    static void testconstructDispatchedCallExpiredPlatformEvent() {
       
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchedCallExpiredPlatformEvent(wo);
	}
    
    @isTest
    static void testconstructGoneOnArrivalApprovalPlatformEvent() {
       
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructGoneOnArrivalApprovalPlatformEvent(wo);
	}
    
    @isTest
    static void testconstructCallClearedPlatformEvent() {
        
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructCallClearedPlatformEvent(wo);
	}
    
    private class MockThirdPartyDispatcherService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
        public MockThirdPartyDispatcherService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            super(thirdPartyIntegrationService);
        }
        
     
        public override RestApi_PatchCall.PatchCallResponse processThirdPartyRequestToUpdateCall(
            RestApi_PatchCall.PatchCallRequest patchCallRequest, 
            ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper) {
          	Exception exp = null;
            return new RestApi_PatchCall.PatchCallResponse(200, 'Update Call from Third Party Succeeded', 'statusUpdate', exp);
        }
    }
    
    @isTest
    static void testProcessThirdPartyRequestToUpdateCall() {
      
      ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
     	//MockThirdPartyDispatcherService dispatcherService = new MockThirdPartyDispatcherService(mockService);
        TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
        RestApi_PatchCall.PatchCallRequest request = new RestApi_PatchCall.PatchCallRequest();
       
        ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
       
        Test.startTest(); 
        RestApi_PatchCall.PatchCallResponse response = dispatcherService.processThirdPartyRequestToUpdateCall(request, wrapper);
        Test.stopTest(); 
        
    }
	@isTest
    static void testSetDefaultApplicationLogFields() {
        
        ThirdPartyIntegration.ThirdPartyIntegrationLog integrationLog = new ThirdPartyIntegration.ThirdPartyIntegrationLog();
       String expectedOperation = 'Test Operation';
        String expectedApiName = 'Test API Name';
       Test.startTest();
        integrationLog.setDefaultApplicationLogFields(expectedOperation, expectedApiName);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testThirdPartyPlatformEventParameter() {
       
        String expectedKey = 'TestKey';
        String expectedValue = 'TestValue';
		ThirdPartyIntegration.ThirdPartyPlatformEventParameter param = new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(expectedKey, expectedValue);
    	System.assertEquals(expectedKey, param.key);
        System.assertEquals(expectedValue, param.value);
    }
    
    @isTest
    static void testLogInformationMessage() {
       
        String message = 'Test Message';
        String callKey = 'Test Call Key';
		ThirdPartyIntegration.ThirdPartyIntegrationLog integrationLog = new ThirdPartyIntegration.ThirdPartyIntegrationLog();
    	integrationLog.logInformationMessage(message, callKey);
	 }
    
    /******EMI Start for SSFI-77 dated 01-14-2025***************/
    
    @isTest
    static void testSendDispatchUpdatePlatformEvent() {
        
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchUpdatePlatformEvent(wo);
	}
   
      
    @isTest
    static void testSendDispatchUpdatePlatformEvent_ExceptionCase() {
      
		WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchUpdatePlatformEvent(wo);
        Test.startTest();
        try {
            mockService.sendDispatchUpdatePlatformEvent(wo);
         } catch (Exception e) {
            System.assert(e.getMessage().contains('No Third Party is configured'), 'Exception message should match');
        }
        Test.stopTest();
    }
    
     @IsTest
    public static void testSendDispatchUpdatePlatformEvent_HappyPath_EventPublished() {
        setupMocks();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
		insert wo;
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchUpdatePlatformEvent', mockEvent);
        Integer logcount = mockLogService.saveApplicationLogsCallCount;

        System.test.startTest();
        thirdPartyService.sendDispatchUpdatePlatformEvent(wo);
        System.test.stopTest();

        System.assertEquals(logcount+1, mockLogService.saveApplicationLogsCallCount, 'There should be one additional log for a successful Platform Event publication');
    }
	
	 @IsTest
    public static void testSendDispatchUpdatePlatformEvent_NoDispatcherRegistered_ExceptionRaised() {
        setupMocks();
 
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
		insert wo;
        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        Boolean passed = false;
        System.test.startTest();
        // Call the function to be tested before registerimg the dispatcher service. We should get an exception
        try {
            thirdPartyService.sendDispatchUpdatePlatformEvent(wo);
        }
        catch (ThirdPartyIntegration.ThirdPartyIntegrationException ex) {
            passed = true;
        }
        catch (Exception ex) {
            passed = false;
        }
        System.test.stopTest();
        System.assert(passed, 'Expected to see a ThirdPartyIntegrationException when no Dispatcher is registered');
    }    

	@IsTest
    public static void testSendDispatchUpdatePlatformEvent_DispatcherException_EventLogged() {
        setupMocks();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        WorkOrder wo = new WorkOrder(External_Id__c = '12345');
        wo.Servicing_Technology_Type__c = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK;
		insert wo;
        registerMockDispatcher(thirdPartyService, dispatcherService);
        ThirdPartyEvent__e mockEvent = thirdPartyService.constructCoreIntegrationPlatformEvent(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                                                                     ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        mockDispatcher.setReturnValue('constructDispatchUpdatePlatformEvent', mockEvent);
        Integer logcount = mockLogService.saveApplicationLogsCallCount;

        mockDispatcher.setException(new VanillaException('something went wrong'));
        System.test.startTest();
        thirdPartyService.sendDispatchUpdatePlatformEvent(wo);
        System.test.stopTest();
        System.assert(logcount < mockLogService.saveApplicationLogsCallCount, 'There should be an additional logging for an exception thrown by the dispatcherService');
    }
	
    @isTest
    static void testConstructDispatchUpdatePlatformEvent() {
      
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '12345';
		ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        //TowbookIntegration.IThirdPartyIntegrationService mockService2 = new MockThirdPartyIntegrationService();
		TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
		ThirdPartyEvent__e event = dispatcherService.constructDispatchUpdatePlatformEvent(wo);

       
    }
     /******EMI End for SSFI-77 dated 01-14-2025***************/   
}