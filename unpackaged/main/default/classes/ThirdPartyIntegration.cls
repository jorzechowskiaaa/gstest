public with sharing class ThirdPartyIntegration {
 
    public static final String TPE_PARAM_KEY_X_DEBUG = 'x-debug';

    public static final String TPE_PARAM_X_DEBUG_TRUE        = 'true';                       // True Value
    public static final String TPE_PARAM_X_DEBUG_FALSE       = 'false';                      // False Value    

    // *********************************************
    // * FactorylogSuccessMessage
    // *********************************************
    public interface IFactory {
        IThirdPartyIntegrationService createService();
    }

    public class Factory implements IFactory {
        public IThirdPartyIntegrationService createService() {

            ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
            wrapper.workOrderservice = new FSL_WorkOrder.Factory().createService();
            wrapper.serviceAppointmentService = new FSL_ServiceAppointment.Factory().createService();
            wrapper.serviceLineItemService = new FSL_ServiceLineItem.Factory().createService();
            wrapper.contactService = new FSL_Contact.Factory().createService();

            FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
            ThirdPartyIntegrationService service = new ThirdPartyIntegrationService(wrapper, appLogService);

            // By Default register the known dispatcher types

            IThirdPartyDispatcherService dispatcherService = new TowbookIntegration.Factory().createService(service);
            service.registerDispatcherForTechnologyType(THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK, dispatcherService);
            service.registerDispatcherForTechnologyType(THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY, dispatcherService);
			service.registerDispatcherForTechnologyType('Full FSL Technology', dispatcherService);//EMI
            String channelName = RestApi_PatchCall.Channel_Name.TOWBOOK.name();
            service.registerDispatcherForChannel(channelName, dispatcherService);

            return service;
        }
    }

    /*************************************************************************
     * IThirdPartyIntegrationService Interface
     ************************************************************************/
    public interface IThirdPartyIntegrationService {
        // FSL Calls
        RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest );
        void sendDispatchOfferPlatformEvent(WorkOrder wo);
        void sendDispatchUpdatePlatformEvent(WorkOrder wo);//EMI
        void sendStatusChangePlatformEvents(List<WorkOrder> workorders);
        void publishPlatformEventsAndLogResults(List<ThirdPartyEvent__e> platformEvents);

        // Additional interface functions called by Third Party Dispatcher Services
        void registerDispatcherForTechnologyType(String techType, IThirdPartyDispatcherService dispatcherService);
        void registerDispatcherForChannel(String channel, IThirdPartyDispatcherService dispatcherService);
        ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String callKey);
        String constructPlatformEventParametersArrayJSON(List<ThirdPartyPlatformEventParameter> params);

        List<FSL_WorkOrder.WorkOrder>  retrieveWorkOrderDetails (WorkOrder wo);
        String getWorkOrderJSONUsingRetrieveWOMapping (List<FSL_WorkOrder.WorkOrder> domainWOs);

        void logFailureMessage(String message, Exception ex, RestApi_PatchCall.PatchCallRequest patchCallRequest);
        void logSuccessMessage(String message, RestApi_PatchCall.PatchCallRequest patchCallRequest);
        void logDiagnosticMessage(String message, string callKey);
    }

    /*************************************************************************
     * IThirdPartyDispatcherService Interface
     ************************************************************************/
    public interface IThirdPartyDispatcherService {
        RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest,  
                                                                                  IntegrationSupportServicesWrapper servicesWrapper );
        ThirdPartyEvent__e constructDispatchUpdatePlatformEvent(WorkOrder wo);//EMI
        ThirdPartyEvent__e constructDispatchOfferPlatformEvent(WorkOrder wo);
        ThirdPartyEvent__e constructDispatchAcceptedPlatformEvent(WorkOrder wo);
        ThirdPartyEvent__e constructDispatchRefusedPlatformEvent(WorkOrder wo);
        ThirdPartyEvent__e constructDispatchedCallCancelledPlatformEvent(WorkOrder wo);  
        ThirdPartyEvent__e constructDispatchedCallExpiredPlatformEvent(WorkOrder wo);
        ThirdPartyEvent__e constructGoneOnArrivalApprovalPlatformEvent(WorkOrder wo);
        ThirdPartyEvent__e constructCallClearedPlatformEvent(WorkOrder wo);
    }

    public static final string THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK = 'TowBook';  
    public static final string THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY = 'TowBook Notify';  
 
   /*****************************************
    * ThirdPartyIntegrationService Implementation
    *********************************************/
    public class ThirdPartyIntegrationService implements IThirdPartyIntegrationService {

        private Map<String, IThirdPartyDispatcherService> technologyTypeToDispatcher = new Map<String, IThirdPartyDispatcherService>();
        private Map<String, IThirdPartyDispatcherService> channelToDispatcher = new Map<String, IThirdPartyDispatcherService>();


        IntegrationSupportServicesWrapper  integrationWrapper = new IntegrationSupportServicesWrapper();
        FSL_ApplicationLog.IApplicationLogService appLogService;

        
        public ThirdPartyIntegrationService(
            IntegrationSupportServicesWrapper  integrationWrapper,
            FSL_ApplicationLog.IApplicationLogService appLogService)  {
            this.integrationWrapper = integrationWrapper;
            this.appLogService = appLogService;
        }


        public void registerDispatcherForTechnologyType(String techType, IThirdPartyDispatcherService dispatcherService) {
            technologyTypeToDispatcher.put(techType, dispatcherService);
        }
 
        public void registerDispatcherForChannel(String channelName, IThirdPartyDispatcherService dispatcherService) {
            channelToDispatcher.put(channelName, dispatcherService);
        }

        /*  Inbound Message from ThirdParty  */
        public RestApi_PatchCall.PatchCallResponse processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest ) {
            String errMessage = 'No Third Party Implementation available for update requests from this channel';
            RestApi_PatchCall.PatchCallResponse patchCallResponse = new RestApi_PatchCall.PatchCallResponse(400, errMessage, THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC,
                                                   new ThirdPartyIntegration.ThirdPartyIntegrationException (errMessage)) ;
            RestApi_PatchCall.Channel channel = patchCallRequest.requestHeader.channel;
            IThirdPartyDispatcherService dispatcherService = getThirdPartyDispatcherServiceFromChannelName(channel.name.name());
            if ( dispatcherService != null ) {
                patchCallResponse =  dispatcherService.processThirdPartyRequestToUpdateCall(patchCallRequest, integrationWrapper);  
            }
            return patchCallResponse;
        }       
    
        public void  sendDispatchOfferPlatformEvent(WorkOrder wo) {
            system.debug('wo======lineno:124'+wo);
            IThirdPartyDispatcherService dispatcherService = getThirdPartyDispatcherService(wo.Servicing_Technology_Type__c);
            if (  dispatcherService == null ) {
                throw new ThirdPartyIntegration.ThirdPartyIntegrationException ('No Third Party is configured to dispatch calls of this technology_type ' + wo.Servicing_Technology_Type__c);
            }
            // Need to do a WO query to do get additional required fields
            try {
                ThirdPartyEvent__e pltfrmEvent = dispatcherService.constructDispatchOfferPlatformEvent(wo);   
                system.debug('pltfrmEvent======lineno:132'+pltfrmEvent);
                List <ThirdPartyEvent__e> platformEvents =  new List <ThirdPartyEvent__e>();
                platformEvents.add(pltfrmEvent);
                publishPlatformEventsAndLogResults(platformEvents);
            }
            catch (Exception ex) {
                List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
                ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
                tpiLog.logNotificationFailure('Could not construct Dispatch platformEvent', ex, wo.External_ID__c);
                tpiLogs.add(tpiLog);
                appLogService.saveApplicationLogs(tpiLogs);
            }
        }

    /****EMI-START**********/
        
        
         public void sendDispatchUpdatePlatformEvent(WorkOrder wo) {
        // Query to get additional required fields for the WorkOrder
         system.debug('wo======lineno:151'+wo);
        WorkOrder fetchedWO = [SELECT Id, Servicing_Technology_Type__c, External_ID__c, Breakdown_Address__c,Tow_Address__c,Landmark__c,Tow_Landmark__c,Call_Id__c,Call_Date__c,Call_Type__c,
                               LocationId,Location.City__c, Location.Country__c, Location.County__c, Location.State__c, Location.Street_Address__c, Location.Cross_Street_1__c, 
                               Location.Zip__c, Location.GeoLocation__Latitude__s, Location.GeoLocation__Longitude__s, Location.Landmark__c, Location.Mile_Marker__c, Service_Type__c,			
							   Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s,Tow_Location__Latitude__s, Tow_Street__c, Tow_City__c ,Tow_State__c,Tow_Country__c ,Tow_Postal_Code__c
                               FROM WorkOrder
                               WHERE Id = :wo.Id
                               LIMIT 1];
	
        IThirdPartyDispatcherService dispatcherService = getThirdPartyDispatcherService(fetchedWO.Servicing_Technology_Type__c);
        if (dispatcherService == null) {
            throw new ThirdPartyIntegration.ThirdPartyIntegrationException('No Third Party is configured to dispatch calls of this technology_type ' + fetchedWO.Servicing_Technology_Type__c);
        }

        try {
                ThirdPartyEvent__e pltfrmEvent = dispatcherService.constructDispatchUpdatePlatformEvent(fetchedWO); 
                system.debug('pltfrmEvent======lineno:170'+pltfrmEvent);
           		List<ThirdPartyEvent__e> platformEvents = new List<ThirdPartyEvent__e>();
                platformEvents.add(pltfrmEvent);
                publishPlatformEventsAndLogResults(platformEvents);
            } catch (Exception ex) {
                List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
                ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
                tpiLog.logNotificationFailure('Could not construct Dispatch-Update platformEvent', ex, fetchedWO.External_ID__c);
                tpiLogs.add(tpiLog);
                appLogService.saveApplicationLogs(tpiLogs);
                }
         }
                
       
     /****EMI-END**********/
        public void sendStatusChangePlatformEvents(List<WorkOrder> workorders) {
            IThirdPartyDispatcherService dispatcherService = null;
            List <ThirdPartyEvent__e> platformEvents =  new List <ThirdPartyEvent__e>();
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            ThirdPartyEvent__e pltfrmEvent = null;
            for (WorkOrder wo : workOrders) {
                dispatcherService = getThirdPartyDispatcherService(wo.Servicing_Technology_Type__c);
                pltfrmEvent = null;
                try {
                    pltfrmEvent = constructStatusSpecificThirdPartyNotification(dispatcherService, wo);
                    if (pltfrmEvent != null) {
                        platformEvents.add(pltfrmEvent);
                    }
                }
                catch (Exception ex) {
                    ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
                    tpiLog.logPlatformEventFailure(pltfrmEvent,  ex.getMessage());
                    tpiLogs.add(tpiLog);
                }
            }
            publishPlatformEventsAndLogResults(platformEvents);

            if ( tpiLogs.size() > 0 ) {
                appLogService.saveApplicationLogs(tpiLogs);
            }
        }

        @TestVisible
        private ThirdPartyEvent__e constructStatusSpecificThirdPartyNotification( IThirdPartyDispatcherService dispatcherService, WorkOrder workOrder) {
            if (  dispatcherService == null ) {
                throw new ThirdPartyIntegration.ThirdPartyIntegrationException (
                    'No Third Party is configured to dispatch calls of this technology_type '
                    + workOrder.Servicing_Technology_Type__c );
            }
            ThirdPartyEvent__e pltfrmEvent = null;
            switch on workOrder.status {
                when 'Spotted' {
                    pltfrmEvent = dispatcherService.constructDispatchedCallExpiredPlatformEvent(workOrder);
                    pltfrmEvent.Comments__c =  'Call has expired because it was not accepted within the required time ';
                }
                when 'Canceled' {
                    pltfrmEvent = dispatcherService.constructDispatchedCallCancelledPlatformEvent(workOrder);
                    pltfrmEvent.Comments__c =  'Member has cancelled the call. Service is no longer needed';
                }
                when 'Cleared' {
                    pltfrmEvent = dispatcherService.constructCallClearedPlatformEvent(workOrder);
                    pltfrmEvent.Comments__c =  'This call has been completed at + ' + workOrder.Cleared_Timestamp__c;
                    pltfrmEvent.Details__c = getWorkOrderJSONUsingRetrieveWOMapping(retrieveWorkOrderDetails(workOrder));
                }
            }
            /*if(workOrder.Resolution_Code__c != null) {
                if(workOrder.Resolution_Code__c.startsWith('X00')) { //Tyler Antony start
                    pltfrmEvent = dispatcherService.constructDispatchedCallCancelledPlatformEvent(workOrder); 
                    pltfrmEvent.Comments__c =  'Member has cancelled the call. Service is no longer needed';
                } //Tyler Antony end 
            } */
            return pltfrmEvent;
        }

        public void publishPlatformEventsAndLogResults(List<ThirdPartyEvent__e> platformEvents) {
            if ( platformEvents == null || platformEvents.size() < 1 ) {
                return;
            }
			system.debug('platformEvents===>240'+platformEvents);
            List<Database.SaveResult> results = EventBus.publish(platformEvents);
            system.debug('results===>242'+results);
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            Integer ndx = 0;
            ThirdPartyIntegrationLog tpiLog;
            for( Database.SaveResult sr : results) {
                tpiLog = new ThirdPartyIntegrationLog();
                if ( sr.isSuccess() ) {
                    tpiLog.logPlatformEventSuccess(platformEvents[ndx], 'Published Platform Event of Type: ');
                }
                else {
                    tpiLog.logPlatformEventFailure(platformEvents[ndx], 'Failed to publish Platform Event of Type: ');
                }
                ndx++;
                system.debug('Third party Int::::::::::::::::'+tpiLog);
                tpiLogs.add(tpiLog);
            }
            if(!tpiLogs.isEmpty()){
                appLogService.saveApplicationLogs(tpiLogs);
            }
        }

        public String getWorkOrderJSONUsingRetrieveWOMapping (List<FSL_WorkOrder.WorkOrder> domainWOs) {
            string woJson = '';
            FSL_WorkOrderJsonWrapper.WorkOrderJson woJsonObj = FSL_WorkOrderRetrieveApi.parseResponse(domainWOs);
            woJson =  JSON.serialize(woJsonObj);
            return woJson;
        }

        public List<FSL_WorkOrder.WorkOrder>  retrieveWorkOrderDetails (WorkOrder wo) {
            //TBD: This may be a more efficient way to map this
            //List<workOrder> woList = workOrderservice.retrieveSchemaWorkOrderDetailsByCallIdAndDate(searchCriteria);

            FSL_WorkOrder.CallIdAndCallDatePair  callIdDate = new FSL_WorkOrder.CallIdAndCallDatePair();
            callIdDate.callId = wo.Call_Id__c;
            callIdDate.callDate = wo.Call_Date__c;
            List<FSL_WorkOrder.CallIdAndCallDatePair> searchCriteria = new List<FSL_WorkOrder.CallIdAndCallDatePair>();
            searchCriteria.add(callIdDate);

            FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResource.Factory().createService();
            FSL_FeedItem.IFeedItemService feedItemService  = new FSL_FeedItem.Factory().createService();
            return integrationWrapper.workOrderservice.getWorkOrdersByCallIdAndCallDate( searchCriteria, assignedResourceService, feedItemService );
        }


        public ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String callKey)  {
            //system.debug('tpiccipe:'+technologyType+eventType+callKey);
            ThirdPartyEvent__e intgPltfrmEvent = new ThirdPartyEvent__e();
            intgPltfrmEvent.EventType__c = eventType;
            intgPltfrmEvent.Technology_Type__c = technologyType;
            intgPltfrmEvent.CallKey__c = callKey;
             system.debug('tpiccipe:'+intgPltfrmEvent);
            return intgPltfrmEvent;
        }

        public String constructPlatformEventParametersArrayJSON(List<ThirdPartyPlatformEventParameter> params)  {
            return JSON.serialize(params);
        }
    
        public void logSuccessMessage(String message, RestApi_PatchCall.PatchCallRequest patchCallRequest ) {
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
            tpiLog.logOperationSuccess(message, patchCallRequest);
            tpiLogs.add(tpiLog);
            appLogService.saveApplicationLogs(tpiLogs);
        }
   
        public void logDiagnosticMessage(String message, String callKey) {
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
            tpiLog.logInformationMessage(message, callKey);
            tpiLogs.add(tpiLog);
            appLogService.saveApplicationLogs(tpiLogs);
        }

        public void logNotificationFailureMessage(String message, Exception ex, String dispatchId) {
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
            tpiLog.logNotificationFailure(message, ex, dispatchId);
            tpiLogs.add(tpiLog);
            appLogService.saveApplicationLogs(tpiLogs);
        }

        public void logFailureMessage(String message, Exception ex, RestApi_PatchCall.PatchCallRequest patchCallRequest ) {
            List<ThirdPartyIntegrationLog> tpiLogs = new List<ThirdPartyIntegrationLog>();
            ThirdPartyIntegrationLog tpiLog = new ThirdPartyIntegrationLog();
            tpiLog.logOperationFailure(message, ex, patchCallRequest);
            tpiLogs.add(tpiLog);
            appLogService.saveApplicationLogs(tpiLogs);
        }

        @TestVisible
        private IThirdPartyDispatcherService  getThirdPartyDispatcherService(String technologyType) {
            return technologyTypeToDispatcher.get(technologyType);
        }
        
        @TestVisible
        private IThirdPartyDispatcherService  getThirdPartyDispatcherServiceFromChannelName(String channelName) {
            return channelToDispatcher.get(channelName);
        }
    }

    public class ThirdPartyIntegrationException extends Exception {
    }

    public class ThirdPartyPlatformEventParameter {
        public String key;
        public String value;

        public ThirdPartyPlatformEventParameter(String key, String value) {
            this.key = key;
            this.value = value;
        }
    }


    public class IntegrationSupportServicesWrapper {
        public FSL_WorkOrder.IWorkOrderService workOrderservice;
        public FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService;
        public FSL_ServiceLineItem.IServiceLineItemService serviceLineItemService;
        public FSL_Contact.IContactService contactService;
    }
 
    public static final String THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC       = 'generic';
    public static final String THIRD_PARTY_DISPATCHER_PLTFM_EVNT_CREATED       = 'created';
    public static final String THIRD_PARTY_DISPATCHER_PLTFM_EVNT_CANCELED      = 'canceled';
    public static final String THIRD_PARTY_DISPATCHER_PLTFM_EVNT_CLEARED       = 'cleared';
    public static final String THIRD_PARTY_DISPATCHER_PLTFM_EVNT_EXPIRED      = 'expired';
    
    public abstract class ThirdPartyDispatcherServiceBase  implements IThirdPartyDispatcherService { 
        public ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService;
        public ThirdPartyDispatcherServiceBase(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService)  {
            this.thirdPartyIntegrationService = thirdPartyIntegrationService;
        }
        /*******EMI*/
        public virtual ThirdPartyEvent__e constructDispatchUpdatePlatformEvent(WorkOrder wo) {
            system.debug('wo===line374'+wo);
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        }
        /*******EMI*/
        public virtual ThirdPartyEvent__e constructDispatchOfferPlatformEvent(WorkOrder wo) {
            system.debug('wo====>lineno366'+wo);
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        }
        public virtual ThirdPartyEvent__e constructDispatchAcceptedPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        }

        public virtual ThirdPartyEvent__e constructDispatchRefusedPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        }

        public virtual ThirdPartyEvent__e constructDispatchedCallCancelledPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_CANCELED, wo.External_Id__c);
        }  

        public virtual ThirdPartyEvent__e constructDispatchedCallExpiredPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_EXPIRED, wo.External_Id__c);
        }

        public virtual ThirdPartyEvent__e constructGoneOnArrivalApprovalPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_GENERIC, wo.External_Id__c);
        }
        public virtual ThirdPartyEvent__e constructCallClearedPlatformEvent(WorkOrder wo) {
            return thirdPartyIntegrationService.constructCoreIntegrationPlatformEvent(wo.Servicing_Technology_Type__c, 
            ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_PLTFM_EVNT_CLEARED, wo.External_Id__c);
        }
        public virtual RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest, 
                                                                   ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper ) {
            Exception exp = null;
            return new RestApi_PatchCall.PatchCallResponse(200, 'Update Call from Third Party Succeeded', 'statusUpdate', exp);
        }
    }

    // *********************************************
    // * Application Log
    // *********************************************

    public class ThirdPartyIntegrationLog extends FSL_ApplicationLog.ApplicationLog {
        public ThirdPartyIntegrationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'ThirdPartyIntegration';
            appLog.DateTime__c = System.now();
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void setDefaultApplicationLogFields(String operation, String apiName) {
            appLog.Operation__c = operation;
            appLog.Api_Name__c = apiName;            
        }

        public void logOperationFailure(String message, Exception ex, RestApi_PatchCall.PatchCallRequest cdmUpdateCallRequest ) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = 'ThirdPartyIntegration';
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message + ' ' + ex.getMessage();
            applog.call_Id__c = cdmUpdateCallRequest.callInfo.callKey;
            appLog.Request_Body__c = limitLength(JSON.serialize(cdmUpdateCallRequest)); 
            appendFormattedExceptionToErrorMessage(ex);
        }

        public void logNotificationFailure(String message, Exception ex, String dispatchId) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = 'ThirdPartyIntegration';
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message + ' ' + ex.getMessage();
            applog.call_Id__c = dispatchId;
            appendFormattedExceptionToErrorMessage(ex);
        }
        public void logOperationSuccess(String message, RestApi_PatchCall.PatchCallRequest cdmUpdateCallRequest ) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = 'ThirdPartyIntegration';
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message;
            applog.call_Id__c = cdmUpdateCallRequest.callInfo.callKey;
            appLog.Request_Body__c = limitLength(JSON.serialize(cdmUpdateCallRequest)); 
        }

        public void logPlatformEventFailure(ThirdPartyEvent__e platformEvent, String message) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = platformEvent.EventType__c;
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message + ' ' + platformEvent.EventType__c;
            applog.call_Id__c = platformEvent.CallKey__c;
            appLog.Request_Body__c = limitLength(JSON.serialize(platformEvent)); 
        }

        public void logPlatformEventSuccess(ThirdPartyEvent__e platformEvent, String message) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = platformEvent.EventType__c;
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c =  message + ' ' + platformEvent.EventType__c;
            applog.call_Id__c = platformEvent.CallKey__c;
            appLog.Request_Body__c = limitLength(JSON.serialize(platformEvent)); 
            appLog.RecordTypeId = platformEventRecordTypeId;//EMI

        }
        public void logInformationMessage(String message, String callKey) {
            appLog.Api_Name__c = 'ThirdPartyIntegration';
            appLog.Operation__c = 'ThirdPartyIntegration';
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c =  message + ' ' + message;
            applog.call_Id__c = callKey;
        }
    }
}