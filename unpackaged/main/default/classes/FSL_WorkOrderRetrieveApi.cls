@RestResource(UrlMapping = '/workorders/retrieve/*')
global with sharing class FSL_WorkOrderRetrieveApi {
    @TestVisible private static FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLog.Factory().createService();
    @TestVisible private static FSL_AssignedResource.IAssignedResourceService assignedResourceService = new FSL_AssignedResource.Factory().createService();
    @TestVisible private static FSL_Contact.IContactService contactService = new FSL_Contact.Factory().createService();
    @TestVisible private static FSL_FeedItem.IFeedItemService feedItemService = new FSL_FeedItem.Factory().createService();
    @TestVisible private static FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
    @TestVisible private static FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper wrapper = new FSL_WorkOrderJsonWrapper.WrapperFactory().createWrapper();
    @TestVisible private static Map<String, FSL_ServiceSettings__c> serviceSettings = FSL_ServiceSettings__c.getAll();
    
    @HttpPost
    global static FSL_WorkOrderJsonWrapper.WorkOrderJson retrieveWorkOrders() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        RetrieveWorkOrdersApplicationLog log = new RetrieveWorkOrdersApplicationLog();
        FSL_WorkOrderJsonWrapper.WorkOrderJson workOrderJson = new FSL_WorkOrderJsonWrapper.WorkOrderJson();
        DateTime serviceStartTime = system.now();
        try {
            RetrieveWorkordersRequest retrieveRequest = parseRequest( request );
            List<FSL_WorkOrder.WorkOrder> workOrders = retrieveWorkOrders( retrieveRequest );
            workOrderJson = parseResponse( workOrders );
            workOrderJson.statusCode = 200;
            workOrderJson.statusDescription = 'OK';
            log.logResponse( request.requestBody.toString(), workOrderJson );
            response.statusCode = 200;
            
        } 
        catch( InvalidRequestException ex ) {
            log.logParseRequestFailure( ex, request.requestBody.toString() );
            workOrderJson.statusCode = 500;
            workOrderJson.statusDescription = 'Invalid Request';
            response.statusCode = 500;
        }
        catch( InvalidSearchMethodException ex ) {
            log.logInvalidSearchMethod( ex, request.requestBody.toString() );
            workOrderJson.statusCode = 500;
            workOrderJson.statusDescription = 'Invalid Search Method';
            response.statusCode = 500;
        }
        catch( ParseException ex ) {
            log.logParseException( ex, request.requestBody.toString() );
            workOrderJson.statusCode = 500;
            workOrderJson.statusDescription = 'Internal Server Error';
            response.statusCode = 500;
        }
        catch( Exception ex ) {
            log.logGenericException( ex, request.requestBody.toString() );
            workOrderJson.statusCode = 500;
            workOrderJson.statusDescription = 'Internal Server Error';
            response.statusCode = 500;
        }
        finally {
            log.logServiceTime(serviceStartTime, system.now());
            applicationLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ log } );
        }
        return workOrderJson;
    }

    private static RetrieveWorkOrdersRequest parseRequest( RestRequest request ) {
        RetrieveWorkordersRequest retrieveRequest = null;
        try {
            retrieveRequest = (RetrieveWorkordersRequest)JSON.deserialize( request.requestBody.toString(), FSL_WorkOrderRetrieveApi.RetrieveWorkOrdersRequest.class );
        } 
        catch( Exception ex ) {
            throw new InvalidRequestException( ex.getMessage() );
        }
        return retrieveRequest;
    }

    private static List<FSL_WorkOrder.WorkOrder> retrieveWorkOrders( RetrieveWorkordersRequest retrieveRequest ) {
        List<FSL_WorkOrder.WorkOrder> workOrders = null;
        switch on retrieveRequest.searchMethod {
            when 'CallIdAndDate' {
                workOrders = retrieveWorkOrdersByCallIdAndCallDate( retrieveRequest );
            }
            when 'ActiveAndMembershipNumber' {
                workOrders = retrieveActiveWorkOrdersByMembershipNumber( retrieveRequest );
            }
            when 'ActiveAndAni' {
                workOrders = retrieveActiveWorkOrdersByPhoneNumber( retrieveRequest );
            }
            when else {
                throw new InvalidSearchMethodException( 'Invalid Search Method: [' + retrieveRequest.SearchMethod + ']' );
            }
        }
        return workOrders;
    }

    private static List<FSL_WorkOrder.WorkOrder> retrieveWorkOrdersByCallIdAndCallDate( RetrieveWorkordersRequest retrieveRequest ) {
        List<FSL_WorkOrder.CallIdAndCallDatePair> criteria = new List<FSL_WorkOrder.CallIdAndCallDatePair>();
        for( RetrieveWorkOrdersSearchCriteria searchCriteria : retrieveRequest.searchCriteria ) {
            FSL_WorkOrder.CallIdAndCallDatePair callIdAndCallDatePair = new FSL_WorkOrder.CallIdAndCallDatePair();
            callIdAndCallDatePair.callId = searchCriteria.callId;
            callIdAndCallDatePair.callDate = searchCriteria.callDate;
            criteria.add( callIdAndCallDatePair );
        }
        return workOrderService.getWorkOrdersByCallIdAndCallDate( criteria, assignedResourceService, feedItemService );
    }

    private static List<FSL_WorkOrder.WorkOrder> retrieveActiveWorkOrdersByMembershipNumber( RetrieveWorkordersRequest retrieveRequest ) {
        Set<String> membershipNumbers = new Set<String>();
        for( RetrieveWorkOrdersSearchCriteria searchCriteria : retrieveRequest.searchCriteria ) {
            membershipNumbers.add( searchCriteria.membershipNumber );
        }
        List<Contact> contacts = contactService.getContactsByMembershipNumber( membershipNumbers );
        Set<Id> contactIds = new Set<Id>();
        for( Contact c : contacts ) {
            contactIds.add( c.Id );
        }
        return workOrderService.getActiveWorkOrdersByContactId( contactIds, assignedResourceService, feedItemService );
    }

    private static List<FSL_WorkOrder.WorkOrder> retrieveActiveWorkOrdersByPhoneNumber( RetrieveWorkordersRequest retrieveRequest ) {
        Set<String> phoneNumbers = new Set<String>();
        for( RetrieveWorkOrdersSearchCriteria searchCriteria : retrieveRequest.searchCriteria ) {
            phoneNumbers.add( searchCriteria.ani );
        }
        List<Contact> contacts = contactService.getContactsByPhoneNumber( phoneNumbers );
        Set<Id> contactIds = new Set<Id>();
        for( Contact c : contacts ) {
            contactIds.add( c.Id );
        }
        return workOrderService.getActiveWorkOrdersByContactId( contactIds, assignedResourceService, feedItemService );
    }

    public static FSL_WorkOrderJsonWrapper.WorkOrderJson parseResponse( List<FSL_WorkOrder.WorkOrder> workOrders ) {
        FSL_WorkOrderJsonWrapper.WorkOrderJson response = new FSL_WorkOrderJsonWrapper.WorkOrderJson();
        try {
            FSL_ServiceSettings__c serviceSetting = serviceSettings.get( 'Retrieve' );
            response = wrapper.wrap( serviceSetting, workOrders );
        } 
        catch( Exception ex ) {
            throw new ParseException( ex );
        }
        return response;
    }

    public class RetrieveWorkOrdersRequest {
        public String transactionID {get;set;}
        public String searchMethod {get;set;}
        public List<RetrieveWorkOrdersSearchCriteria> searchCriteria {get;set;}
    }

    public class RetrieveWorkOrdersSearchCriteria {
        public String callDate;
        public String callId;
        public String membershipNumber;
        public String ani;
    }

    // *********************************************
    // * ApplicationLog
    // *********************************************
    public class RetrieveWorkOrdersApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public RetrieveWorkOrdersApplicationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'RetrieveWorkOrders';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void logParseRequestFailure( InvalidRequestException ex, String requestBody ) {
            appLog.Error_Message__c = 'Failed to parse the request' + '\r\n';
            logException( ex, requestBody );
        }

        public void logInvalidSearchMethod( InvalidSearchMethodException ex, String requestBody ) {
            appLog.Error_Message__c = 'Invalid Search method';
            logException( ex, requestBody );
        }

        public void logParseException( ParseException ex, String requestBody ) {
            appLog.Error_Message__c = 'Exception while parsing' + '\r\n';
            logException( ex, requestBody );
        }

        public void logGenericException( Exception ex, String requestBody ) {
            appLog.Error_Message__c = 'Generic exception' + '\r\n';
            logException( ex, requestBody );
        }

        private void logException( Exception ex, String requestBody ) {
            appLog.Request_Body__c = requestBody;
            appLog.Error_Caught__c = true;
            appendFormattedExceptionToErrorMessage( ex );
        }
        
        public void logServiceTime(DateTime serviceStartTime, DateTime serviceEndTime) {
            appLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        }

        public void logResponse( String requestBody, FSL_WorkOrderJsonWrapper.WorkOrderJson workOrderJson ) {
            appLog.Request_Body__c = requestBody;
            appLog.Response_Body__c = limitLength(JSON.serializePretty( workOrderJson ));
            appLog.Success_Message__c = 'Retrieve successfully completed';
            appLog.Error_Caught__c = false;
        }
    }

    // *********************************************
    // * Exceptions
    // *********************************************
    public class InvalidRequestException extends Exception {
    }

    public class InvalidSearchMethodException extends Exception {
    }

    public class ParseException extends Exception {
    }
}