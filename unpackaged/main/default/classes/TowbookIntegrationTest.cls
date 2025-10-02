@IsTest 
public with sharing class TowbookIntegrationTest {
    public class VanillaException extends Exception {
    }
    
     static ThirdPartyIntegration.IntegrationSupportServicesWrapper serviceWrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
    @isTest
    public static void TestProcessThirdPartyRequestToUpdateCall() {
        TowbookIntegration.Factory TBIF = new TowbookIntegration.Factory();
        TowbookIntegration.TowbookService TBService = (TowbookIntegration.TowbookService)TBIF.createService();
        //RestApi_PatchCall.PatchCallResponse  response =TBService.processThirdPartyRequestToUpdateCall(GetPatchCall(), serviceWrapper);
                
    }
    
     
    private static RestApi_PatchCall.PatchCallResponse constructPatchCallResponse(Boolean error) {
        RestApi_PatchCall.PatchCallResponse patchCallResponse = (error) ? new RestApi_PatchCall.PatchCallResponse(400, 'Failure', 'operation', new VanillaException('Failure')) :
                                                                          new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'operation', null);
        return patchCallResponse;
    }

    public static RestApi_PatchCall.PatchCallRequest GetPatchCall() {
        RestApi_PatchCall.PatchCallRequest patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        //body = JSON.serialize(patchCallRequest); 
        return patchCallRequest;
    } 
	
    /************************************************
    // Factory Mock
    ************************************************/
    public class MockFactory implements TowbookIntegration.IFactory {

        private MockTowBookIntegrationService mockService;  
        public   ThirdPartyIntegration.IThirdPartyDispatcherService createService() {

            mockService = new MockTowbookIntegrationService();
            return  mockService;
        }

        public ThirdPartyIntegration.IThirdPartyDispatcherService createService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            mockService = new MockTowbookIntegrationService();
            return  mockService;
        }

        public MockTowbookIntegrationService getMockService() {
            return mockService;
        }
    }
    
     
   
    /************************************************
    // Service Mock
    ************************************************/
    public class MockTowbookIntegrationService extends TestMockHelper implements ThirdPartyIntegration.IThirdPartyDispatcherService {
        public Exception exceptionToThrow = null;
		/**EMI-START**/
         public ThirdPartyEvent__e constructDispatchUpdatePlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e)incrementReturnOrThrow('constructDispatchUpdatePlatformEvent');
        }
        /**EMI-END**/
        public ThirdPartyEvent__e constructDispatchOfferPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e)incrementReturnOrThrow('constructDispatchOfferPlatformEvent');
        }
        public ThirdPartyEvent__e constructDispatchAcceptedPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructDispatchAcceptedPlatformEvent');
        }
        public ThirdPartyEvent__e constructDispatchRefusedPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructDispatchRefusedPlatformEvent');
        }
        public ThirdPartyEvent__e constructDispatchedCallCancelledPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructDispatchedCallCancelledPlatformEvent');
        }  
        public ThirdPartyEvent__e constructDispatchedCallExpiredPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructDispatchedCallExpiredPlatformEvent');
        }

        public ThirdPartyEvent__e constructGoneOnArrivalApprovalPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructGoneOnArrivalApprovalPlatformEvent');
        }
        public ThirdPartyEvent__e constructCallClearedPlatformEvent(WorkOrder wo) {
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructCallClearedPlatformEvent');
        }
   
        public RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                                                   ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper ) {                                                        
            return (RestApi_PatchCall.PatchCallResponse) incrementReturnOrThrow('processThirdPartyRequestToUpdateCall');
        }
    }
     

}