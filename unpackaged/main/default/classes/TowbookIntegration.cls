public with sharing class TowbookIntegration  {

    public TowbookIntegration() {
    }

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ThirdPartyIntegration.IThirdPartyDispatcherService createService();
    }

    public class Factory implements IFactory {
        public ThirdPartyIntegration.IThirdPartyDispatcherService createService() {
            ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService = new ThirdPartyIntegration.Factory().createService();
            return new TowbookService(thirdPartyIntegrationService);
        }
        //Call this from the ThirdPartyDispatcher object;
        public ThirdPartyIntegration.IThirdPartyDispatcherService createService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            return new TowbookService(thirdPartyIntegrationService);
        }
    }

    // The following Sybolic constants are parameter indices in the
    // Channel Parameters list in the update request
    public static final Integer TBK_CHANNEL_REQUEST_TYPE_PARAM_INDEX = 0;
    public static final Integer TBK_CHANNEL_LOCATION_ID_PARAM_INDEX = 1;
    public static final Integer TBK_CHANNEL_IMAGE_URL_PARAM_INDEX = 2;
    public static final Integer TBK_CHANNEL_DRIVER_ETA_PARAM_INDEX = 3;

    public static final String TBK_PLTFM_EVNT_UPDATE        = 'update';//EMI
    public static final String TBK_PLTFM_EVNT_CREATE        = 'dispatch';
    public static final String TBK_PLTFM_EVNT_CANCEL        = 'cancelled';
    public static final String TBK_PLTFM_EVNT_CLEAR         =  'cleared';
    public static final String TBK_PLTFM_EVNT_ACCEPTED      = 'accepted';
    public static final String TBK_PLTFM_EVNT_REFUSED       =  'refused';
    public static final String TBK_PLTFM_EVNT_EXPIRED       = 'expired';
    public static final String TBK_PLTFM_EVNT_GOA           = 'goa';

    public static final String TPE_PARAM_KEY_MAX_WAIT_TIME         = 'requiredAcknowledgeTimeInSeconds';   
    public static final String TPE_PARAM_KEY_CONTRACTOR_ID         = 'contractorId';               // Value set to Service Territory Id
    public static final String TPE_PARAM_KEY_JOB_ID                = 'jobId';                      // Value Mapped to SA
    public static final String TPE_PARAM_KEY_PO_NUMBER             = 'purchaseOrderNumber';        // Value Mapped to WO Number
    public static final String TPE_PARAM_KEY_SERVICE_TYPE          = 'serviceType';                // Value set as 'light' or 'tow'
    public static final String TPE_PARAM_KEY_GOA_APPROVAL          = 'goaApproved';
    public static final String TPE_PARAM_KEY_LOCATION_ID           = 'locationId';

    public static final String TPE_PARAM_DEFAULT_MAX_WAIT_TIME     = '600';                         // Default Value
    public static final String TPE_PARAM_GOA_APPROVAL_TRUE        = 'true';                       // True Value
    public static final String TPE_PARAM_GOA_APPROVAL_FALSE       = 'false';                      // False Value

    public static final String TPE_PARAM_SERVICE_TYPE_LIGHT       = 'light';                      // Fals Value
    public static final String TPE_PARAM_SERVICE_TYPE_TOW         = 'tow';                        // Fals Value
 
   /*****************************************
    * TowbookService Implementation
    * It impements the ThirdPartyIntegration.IThirdPartyDispatcherService Interface
    *********************************************/

    public class TowbookService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
    public TowbookService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService)  {
            super(thirdPartyIntegrationService);
        }

        /*  Inbound Message from ThirdParty  */
        public override RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                                                                        ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper ) {
            RestApi_PatchCall.PatchCallResponse response = new RestApi_PatchCall.PatchCallResponse
                                                (200, 'Update Call from Towbook Succeeded', ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, null);
            
            TowbookInboundRequest tbkInboundRequest = extractTowBookRequest(patchCallRequest);
		
            response.thirdPartyCallUpdateType = tbkInboundRequest.type.name();
		
            switch on tbkInboundRequest.type {
                when accept {		
                    handleAcceptRequest(tbkInboundRequest, patchCallRequest, servicesWrapper);
                    response.callStatus = FSL_ServiceAppointment.SCHEDULED_STATUS;
                }	
                when refuse {
                    handleRefusedRequest(patchCallRequest, servicesWrapper);
                    response.callStatus = FSL_ServiceAppointment.SPOTTED_STATUS;
                }
                when goa {         	// when block 2
                    handleGOARequest(tbkInboundRequest, patchCallRequest, servicesWrapper);
                    response.callStatus = FSL_ServiceAppointment.CLEARED_STATUS;
                }
                when statusUpdate {		  
                    handleStatusUpdateRequest(patchCallRequest, servicesWrapper);
                    response.callStatus = patchCallRequest.callInfo.status;
                    response.thirdPartyCallUpdateType +=  (':' + response.callStatus);
                }
                when complete {
                    handleCallCompleted(patchCallRequest, servicesWrapper);
                    response.callStatus = FSL_ServiceAppointment.CLEARED_STATUS;
                }
                when cancel {
                    handleCallCancelled(patchCallRequest, servicesWrapper);
                    response.callStatus = FSL_ServiceAppointment.CLEARED_STATUS;
                }
                when breadcrumb {
                    handleCallBreadCrumbs(tbkInboundRequest, patchCallRequest, servicesWrapper);
                    response.callStatus = '';
                }
                when photo {
                    handleCallPhotoUpload(tbkInboundRequest, patchCallRequest, servicesWrapper);
                    response.callStatus = '';
                }
                /**EMI-START***/
               /* when update {		  
                   handleUpdateRequest(patchCallRequest, servicesWrapper);
                    response.callStatus = patchCallRequest.callInfo.status;
                    response.thirdPartyCallUpdateType +=  (':' + response.callStatus);
                }
				*/
               /**EMI-END***/
            }
            response.status =  'Update Call from Towbook Succeeded for request type: ' + response.thirdPartyCallUpdateType;
            return response;
        }

        // Handle Towbook Accept
        @TestVisible
        private void handleAcceptRequest(TowbookInboundRequest tbkInboundRequest, RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                         ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper ) {
            // Put some logic for refusing the call.  For MVP Phase, we will always accept
            
            Boolean acceptOffer = true;
          
            try {
                if ( acceptOffer ) {
                    patchCallRequest.callInfo.status = 'Scheduled';
                    System.debug('patchCallRequest-test====>'+patchCallRequest);
                    System.debug('servicesWrapper-test====>'+servicesWrapper);
                    List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
                   	  System.debug('servicesWrapper-test====>'+wosToBeUpdated);

                    WorkOrder workOrder = wosToBeUpdated.get(0);
                    ThirdPartyEvent__e acceptedEvent = constructDispatchAcceptedPlatformEvent(workOrder);

                    // The following parameters are available from the accept  event itself
                    String facilityId = tbkInboundRequest.contractorId;
                    String poNumber = workOrder.call_Id__c; 
                    List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
                    params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,   facilityId));
                    params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,     facilityId));
                    params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_PO_NUMBER,       poNumber)); 
                    acceptedEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);

                    thirdPartyIntegrationService.publishPlatformEventsAndLogResults(new List<ThirdPartyEvent__e>{acceptedEvent});
                    thirdPartyIntegrationService.logSuccessMessage('Towbook Call Accepted', patchCallRequest);
                }
                else {
                    String comments = 'This dispatch offer is refused by AAA because the expected time of arrival is past the promised time';
                    sendRefusedPlatformEvent(tbkInboundRequest, patchCallRequest, comments);
                }
            }
            catch (FSL_WorkOrder.WorkOrderAlreadyInProgressException ex) {
                    thirdPartyIntegrationService.logFailureMessage('Duplicate Accept request Call is already Accepted.', ex, patchCallRequest);
            }

        }
		
       
        @TestVisible
        private void  sendRefusedPlatformEvent(TowbookInboundRequest tbkInboundRequest, RestApi_PatchCall.PatchCallRequest patchCallRequest, String comments) {
          
            //Create Core TBK Platform Event
            ThirdPartyEvent__e refuseEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                               (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, TBK_PLTFM_EVNT_REFUSED, tbkInboundRequest.dispatchId);
            //Add Comments
            refuseEvent.Comments__c = comments;
           
            // Add parameters
            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,   tbkInboundRequest.contractorId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,     tbkInboundRequest.locationId));
            refuseEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);

           // publish event
            thirdPartyIntegrationService.publishPlatformEventsAndLogResults(new List<ThirdPartyEvent__e>{refuseEvent});
            thirdPartyIntegrationService.logSuccessMessage('Towbook Call Accepted', patchCallRequest);
        }

        @TestVisible
        private void handleRefusedRequest(RestApi_PatchCall.PatchCallRequest patchCallRequest,  ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper  ) {
            try {
                List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
                thirdPartyIntegrationService.logSuccessMessage('Call is declined by Third Party. This call will now be handled like a regular call', patchCallRequest);
            }
            catch (Exception ex) {
                thirdPartyIntegrationService.logFailureMessage('Error in processing Third Party Call Declined event', ex, patchCallRequest);
            }   
        }

       // Handle Towbook goa
       @TestVisible
        private void handleGOARequest(TowbookInboundRequest tbkInboundRequest, RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                      ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper  ) {

            // Put some logic for examining the GOA reason and approve conditionally call.  For MVP Phase, we will always approve
            // Populate notes field for disapproval
            Boolean goaAccept = true;
            String notes = '';
            sendGoaPlatformEvent(tbkInboundRequest, patchCallRequest,  goaAccept, notes);
            
            // Clear the call
            patchCallRequest.callInfo.status = FSL_ServiceAppointment.CLEARED_STATUS;
            if ( String.IsBlank(patchCallRequest.roadsideAssistanceDetail[0].resolutionCode)) {
                patchCallRequest.roadsideAssistanceDetail[0].resolutionCode = 'R001'; // For now until they start passing the resolution code
            }
            List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
        }

        @TestVisible
        private void sendGoaPlatformEvent(TowbookInboundRequest tbkInboundRequest, 
                                             RestApi_PatchCall.PatchCallRequest patchCallRequest, Boolean goaApproval, String comments) {

           ThirdPartyEvent__e goaEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                            (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                            TBK_PLTFM_EVNT_GOA, tbkInboundRequest.dispatchId);      
           goaEvent.Comments__c = comments;
           String goaApprovalValue = (goaApproval) ? TPE_PARAM_GOA_APPROVAL_TRUE : TPE_PARAM_GOA_APPROVAL_FALSE;
          
           // Add parameters
           List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
           params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,   tbkInboundRequest.contractorId));
           params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,     tbkInboundRequest.locationId));
           params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_GOA_APPROVAL,     goaApprovalValue));
           goaEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);

           thirdPartyIntegrationService.publishPlatformEventsAndLogResults(new List<ThirdPartyEvent__e>{goaEvent});
           thirdPartyIntegrationService.logSuccessMessage('Towbook GOA message Accepted', patchCallRequest);
        }

        @TestVisible
        private void handleStatusUpdateRequest(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                               ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) { 
                List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
    
        }

        /*EMI**/
       /* @TestVisible
        private void handleUpdateRequest(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                               ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) { 
                List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
    
        }*/
        /**EMI***/
        @TestVisible
        private void handleCallCompleted(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                          ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) { 
                List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
                thirdPartyIntegrationService.logSuccessMessage('Towbook Call Successfully Completed', patchCallRequest);
        }

        @TestVisible
        private void handleCallCancelled(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                         ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) { 
                patchCallRequest.callInfo.status = FSL_ServiceAppointment.CLEARED_STATUS;
                if ( String.IsBlank(patchCallRequest.roadsideAssistanceDetail[0].resolutionCode)) {
                    patchCallRequest.roadsideAssistanceDetail[0].resolutionCode = 'X001'; // For now until they start passing the resolution code
                }
                List<WorkOrder> wosToBeUpdated = servicesWrapper.workOrderservice.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, servicesWrapper);
                thirdPartyIntegrationService.logSuccessMessage('Towbook Call Successfully Cancelled and Cleared', patchCallRequest);
        }

        @TestVisible
        private void handleCallBreadCrumbs(TowbookInboundRequest tbkInboundRequest, RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                           ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper  ) {

            String logMessage = 'Received Driver Location Breadcrumbs Received: Latitude = (' + 
                                tbkInboundRequest.latitude + ') Longitude = (' + tbkInboundRequest.longitude + ')';                
            thirdPartyIntegrationService.logSuccessMessage(logMessage, patchCallRequest);
        }

        @TestVisible
        private void handleCallPhotoUpload(TowbookInboundRequest tbkInboundRequest, RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                           ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper  ) {

            String logMessage = 'Received Photo for Towbook Call. URL = (' + tbkInboundRequest.url  + ')';
             
            thirdPartyIntegrationService.logSuccessMessage(logMessage, patchCallRequest);

        }
        
        /***EMI****/
      	
        @TestVisible
        public override ThirdPartyEvent__e constructDispatchUpdatePlatformEvent(WorkOrder workOrder) {
            List<WorkOrder> wo = [select External_Id__c from WorkOrder where id =: workOrder.Id]; 
            ThirdPartyEvent__e dispatchEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent (
                                                ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK,
                                                TBK_PLTFM_EVNT_UPDATE, wo[0].External_Id__c);

            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();

            List<FSL_WorkOrder.WorkOrder>  domainWOs = thirdPartyIntegrationService.retrieveWorkOrderDetails(workOrder);
            
            dispatchEvent.Details__c =  thirdPartyIntegrationService.getWorkOrderJSONUsingRetrieveWOMapping(domainWOs);
            WorkOrder woToPublish = domainWOs.get(0).getWorkOrder();
                                            
            String serviceType = ( woToPublish.Is_Tow_WorkType__c) ? TPE_PARAM_SERVICE_TYPE_TOW : TPE_PARAM_SERVICE_TYPE_LIGHT;
            String facilityId = woToPublish.ServiceAppointments[0].ServiceTerritory.Facility_Number__c;
            String svcApptNumber = woToPublish.ServiceAppointments[0].AppointmentNumber;

            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,       facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_MAX_WAIT_TIME,       TPE_PARAM_DEFAULT_MAX_WAIT_TIME));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,         facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_JOB_ID,              svcApptNumber));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_SERVICE_TYPE,        serviceType));

            dispatchEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);
    

            return dispatchEvent;
        }
        
        /****EMI***/
        @TestVisible
        public override ThirdPartyEvent__e constructDispatchOfferPlatformEvent(WorkOrder workOrder) {
            List<WorkOrder> wo = [select External_Id__c from WorkOrder where id =: workOrder.Id]; 
            ThirdPartyEvent__e dispatchEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent (
                                                ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK,
                                                TBK_PLTFM_EVNT_CREATE, wo[0].External_Id__c);

            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();

            List<FSL_WorkOrder.WorkOrder>  domainWOs = thirdPartyIntegrationService.retrieveWorkOrderDetails(workOrder);
            
            dispatchEvent.Details__c =  thirdPartyIntegrationService.getWorkOrderJSONUsingRetrieveWOMapping(domainWOs);
            WorkOrder woToPublish = domainWOs.get(0).getWorkOrder();
                                            
            String serviceType = ( woToPublish.Is_Tow_WorkType__c) ? TPE_PARAM_SERVICE_TYPE_TOW : TPE_PARAM_SERVICE_TYPE_LIGHT;
            String facilityId = woToPublish.ServiceAppointments[0].ServiceTerritory.Facility_Number__c;
            String svcApptNumber = woToPublish.ServiceAppointments[0].AppointmentNumber;

            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,       facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_MAX_WAIT_TIME,       TPE_PARAM_DEFAULT_MAX_WAIT_TIME));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,         facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_JOB_ID,              svcApptNumber));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_SERVICE_TYPE,        serviceType));

            dispatchEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);
    

            return dispatchEvent;
        }
		
         @TestVisible
        public override ThirdPartyEvent__e constructDispatchedCallExpiredPlatformEvent(WorkOrder workOrder) {
           
            ThirdPartyEvent__e expiredEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                              (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                              TBK_PLTFM_EVNT_EXPIRED, workOrder.External_Id__c);
            
            String facilityId = workOrder.ServiceAppointments.get(0).ServiceTerritory.Facility_Number__c;
           
            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
        
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,       facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,       facilityId));
         
            expiredEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);
            return expiredEvent;
        }
		
        @TestVisible 
        public override ThirdPartyEvent__e constructDispatchedCallCancelledPlatformEvent(WorkOrder workOrder) {
            ThirdPartyEvent__e canceledEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                              (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                              TBK_PLTFM_EVNT_CANCEL, workOrder.External_Id__c);
			system.debug(thirdPartyIntegrationService+'###########################'+workOrder);
            List<FSL_WorkOrder.WorkOrder>  domainWOs = thirdPartyIntegrationService.retrieveWorkOrderDetails(workOrder);
           system.debug('###########################'+domainWOs);
            system.debug('###########################'+thirdPartyIntegrationService.retrieveWorkOrderDetails(workOrder));
            WorkOrder woToPublish = domainWOs.get(0).getWorkOrder();

            String facilityId = woToPublish.ServiceAppointments[0].ServiceTerritory.Facility_Number__c;
            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,       facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,       facilityId));
         
            canceledEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);
            return canceledEvent;
        }
 		@TestVisible
        public override ThirdPartyEvent__e constructCallClearedPlatformEvent(WorkOrder workOrder) {
            ThirdPartyEvent__e clearedEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                              (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK,  
                                              TBK_PLTFM_EVNT_CLEAR, workOrder.External_Id__c);

            List<FSL_WorkOrder.WorkOrder>  domainWOs = thirdPartyIntegrationService.retrieveWorkOrderDetails(workOrder);
            clearedEvent.Details__c =  thirdPartyIntegrationService.getWorkOrderJSONUsingRetrieveWOMapping(domainWOs);
            WorkOrder woToPublish = domainWOs.get(0).getWorkOrder();

            String facilityId = woToPublish.ServiceAppointments[0].ServiceTerritory.Facility_Number__c;     
            String serviceType = ( woToPublish.Is_Tow_WorkType__c) ? TPE_PARAM_SERVICE_TYPE_TOW : TPE_PARAM_SERVICE_TYPE_LIGHT;
            String poNumber = woToPublish.call_Id__c;
           
            List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params = new List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter>();
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_CONTRACTOR_ID,   facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_LOCATION_ID,     facilityId));
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_SERVICE_TYPE,    serviceType));      
            params.add(new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(TPE_PARAM_KEY_PO_NUMBER,       poNumber));
         
            clearedEvent.Params__c = thirdPartyIntegrationService.constructPlatformEventParametersArrayJSON(params);
            return clearedEvent;
        }

        public override ThirdPartyEvent__e constructDispatchAcceptedPlatformEvent(WorkOrder workOrder) {
            ThirdPartyEvent__e acceptedEvent = thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent
                                              (ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, 
                                              TBK_PLTFM_EVNT_ACCEPTED, workOrder.External_Id__c);
            return acceptedEvent;
        }

        @TestVisible
        // Extracts a TowBook specific payload from the input request
        private TowbookInboundRequest extractTowBookRequest(RestApi_PatchCall.PatchCallRequest patchCallRequest) {

            TowbookInboundRequest tbkInRequest = new TowbookInboundRequest();
            tbkInRequest.id = patchCallRequest.requestHeader.id;
            try {
                tbkInRequest.type = TBK_REQUEST_TYPE.valueOf(patchCallRequest.requestHeader.channel.parameters[TBK_CHANNEL_REQUEST_TYPE_PARAM_INDEX].value); 
                
            }
            catch (Exception ex) {
                throw new Invalid_TowbookRequestPayload_Exception('Could not find the Towbook request type in the common update call payload'); 
            }

            
            tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
            tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
          
            tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[TBK_CHANNEL_LOCATION_ID_PARAM_INDEX].value;
            tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[TBK_CHANNEL_IMAGE_URL_PARAM_INDEX].value;

            //
            // Set the ETA on the patchRequest Object iteself
            patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
            patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[TBK_CHANNEL_DRIVER_ETA_PARAM_INDEX].value;

            tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;


            if ( patchCallRequest.roadsideAssistanceDetail == null ) {
                patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
                patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
            }

            if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
                patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
            }

     
            if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
                patchCallRequest.CallInfo.status = 'Spotted';
            }
            else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
                patchCallRequest.CallInfo.status = 'Cleared';
            }
            tbkInRequest.status = patchCallRequest.callInfo.status;

            

            try {
                tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
            }
            catch (Exception ex) {
                tbkInRequest.reasonId = 0;
            }
            tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
            try {
                tbkInRequest.eta = Integer.valueOf(patchCallRequest.requestHeader.channel.parameters[TBK_CHANNEL_DRIVER_ETA_PARAM_INDEX].value);
            }
            catch (Exception ex) {
                tbkInRequest.eta = 0;
            }

            tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
            tbkInRequest.driver = new TowbookDriver();
            tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
            tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
            tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
            tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
            tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
            tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;

            tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
            tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
            return tbkInRequest;
        }

    }

    public class Invalid_TowbookRequestPayload_Exception extends Exception {
    }

    public Enum TBK_REQUEST_TYPE {accept, refuse, statusUpdate, photo, complete, goa, cancel, breadcrumb}

    public class TowbookInboundRequest {
        public String id;
        public TBK_REQUEST_TYPE type;
        public String dispatchId;
        public String contractorId;
        public String locationId;
        public String poNumber;
        public String url;
        public String timestamp;
        public String status;
        public Integer reasonId;
        public String comments;
        public Integer eta;
        public Decimal latitude;
        public Decimal longitude;
        public TowbookDriver driver;
        public String resolutionCode;
        public List<RestApi_PatchCall.ServiceLineItem> serviceLineItems;
    }

    public class TowbookDriver {
        public String id;
        public String firstName;
        public String lastName;
        public Decimal latitude;
        public Decimal longitude;
    }

     
}