/**
* Name : FSL_ToD3Clear
* Description : Making a Post callout to D3 with the updated values.
* Methods :
*   1. HTTPResponse : makePostCallout
* @Modification Log   : 
* Ver       Date       Author                    Modification
*       12/22/2020   Clement Shiu        ERS-220799: RAP calls cleared in FSL are going back to IRAS/D3 without a facility id and without RAP id
*/

global class FSL_ToD3Clear {

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IToD3Clear createToD3Clear();
    }

    public class Factory implements IFactory {
        public IToD3Clear createToD3Clear() {
            FSL_WorkOrderD3JsonWrapper jsonWrapper = new FSL_WorkOrderD3JsonWrapper();
            FSL_AssignedResource.IFactory assignedResourceFactory = new FSL_AssignedResource.Factory();
            FSL_FeedItem.IFactory feedItemFactory = new FSL_FeedItem.Factory();
            FSL_WorkOrder.IFactory workOrderFactory = new FSL_WorkOrder.Factory();
            return new ToD3Clear( jsonWrapper, 
                                    assignedResourceFactory.createService(),
                                    feedItemFactory.createService(),
                                    workOrderFactory.createService() );
        }
    }

    // *********************************************
    // * ToD3Clear
    // *********************************************
    public interface IToD3Clear {
        Map<Id, Boolean> clearWorkOrders( Set<Id> workOrderIds );
        Map<Id, Boolean> clearWorkOrders( List<WorkOrder> workOrders, 
                                        Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                        Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap );
        ClearResult clearWorkOrder( WorkOrder workOrder, 
                                    Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                    Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap,
                                    Map<String, String> zipCodeToClubCode);
    }

    public class ToD3Clear implements IToD3Clear {
        private final String SERVICE_NAME_CLEAR = 'Clear';
        private FSL_WorkOrderD3JsonWrapper jsonWrapper = new FSL_WorkOrderD3JsonWrapper();
        private FSL_AssignedResource.IAssignedResourceService assignedResourceService;
        private FSL_FeedItem.IFeedItemService feedItemService;
        private FSL_WorkOrder.IWorkOrderService workOrderService;
        private Map<string ,string > zipCodeToClubCode;
        
        public ToD3Clear( FSL_WorkOrderD3JsonWrapper jsonWrapper, 
                            FSL_AssignedResource.IAssignedResourceService assignedResourceService,
                            FSL_FeedItem.IFeedItemService feedItemService,
                            FSL_WorkOrder.IWorkOrderService workOrderService ) {
            this.jsonWrapper = jsonWrapper;
            this.assignedResourceService = assignedResourceService;
            this.feedItemService = feedItemService;
            this.workOrderService = workOrderService;
            this.zipCodeToClubCode = new Map<string ,string >();
        }

        public Map<Id, Boolean> clearWorkOrders( Set<Id> workOrderIds ) {
            List<WorkOrder> workOrders = workOrderService.getWorkOrdersForClearing( workOrderIds );
            Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = assignedResourceService.getServiceAppointmentIdToAssignedResourceMap( workOrders );
            Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap = feedItemService.getWorkOrderIdToFeedItemsMap( workOrderIds );
            return clearWorkOrders( workOrders, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap );
        }

        public Map<Id, Boolean> clearWorkOrders( List<WorkOrder> workOrders, 
                                                Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                                Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap ) {
            Map<Id, Boolean> clearResults = new Map<Id, Boolean>();
            List<ClearResult> results = new List<ClearResult>();
            
            Set <string> zipcodes = new Set<string>();
            for( WorkOrder workOrder : workOrders ) {
                zipcodes.add(workOrder.PostalCode);
            }
            List<Zip_Code__c> zipcodeLst = [select Name, Club_Code__c from Zip_Code__c where name in :zipcodes];
            for(Zip_Code__c zipcode : zipcodeLst){
                this.zipCodeToClubCode.put(zipcode.Name, zipcode.Club_Code__c);
            }
            
            for( WorkOrder workOrder : workOrders ) {
                    ClearResult result = clearWorkOrder( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, zipCodeToClubCode );
                
                Boolean isSuccessfullyCleared = !result.isError;
                clearResults.put( workOrder.Id, isSuccessfullyCleared );
                results.add( result );
            }
            if( !results.isEmpty() ) {
                logClearCalloutResults( results );

                Set<Id> failedWorkOrderIds = new Set<Id>();
                for( ClearResult result : results ) {
                    if( result.isError ) {
                        failedWorkOrderIds.add( result.workOrderId );
                    }
                }
                if( !failedWorkOrderIds.isEmpty() ) {
                    FSL_D3SyncLogger.syncIssueLogger( failedWorkOrderIds );
                }
            }
            return clearResults;
        }

        public ClearResult clearWorkOrder( WorkOrder workOrder, 
                                        Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                        Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap, Map<String, String> zipCodeToClubCode ) {
            Boolean isSuccessfullyCleared = false;
            String jsonWorkOrder;
            ClearResult result = new ClearResult( jsonWorkOrder, workOrder.Service_Order_Number__c, System.now(), workOrder.Id );
            try {
                System.debug( 'FSL_ToD3Clear.ToD3Clear.clearWorkOrder: Starting Clear for WorkOrder - Id = [' + WorkOrder.Id + '] - CallId = [' + WorkOrder.Service_Order_Number__c + ']' );
                FSL_ClearJsonWorkOrder wrappedWorkOrder = jsonWrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, SERVICE_NAME_CLEAR , zipCodeToClubCode);
                jsonWorkOrder = JSON.serializePretty( wrappedWorkOrder, true );
                jsonWorkOrder = jsonWorkOrder.replace( 'system_Z', 'system' );
                result.requestBody = jsonWorkOrder;
                system.debug('@@@@jsonWorkOrder@@@@'+jsonWorkOrder);
                result = fslToD3Callout( jsonWorkOrder, workOrder.Service_Order_Number__c, workOrder.Id, SERVICE_NAME_CLEAR, workOrder.call_Source__c);
                System.debug( 'FSL_ToD3Clear.ToD3Clear.clearWorkOrder: Clear Callout queued for WorkOrder - Id = [' + WorkOrder.Id + '] - CallId = [' + WorkOrder.Service_Order_Number__c + ']' );
            }
            catch( Exception ex ) {
                result.finalize( ex.getStackTraceString(), 'Exception: ' + ex.getMessage(), true, System.now() );
            }
            return result;
        }
    }
 
    // *********************************************
    // * D3 CALLOUT
    // *********************************************
    @testVisible private static FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService = new FSL_ClearQueuedCall.Factory().createService();

    @future( callout = true )
    public static void fslToD3CalloutAsync( String jsonwrapper, String callId, Set<Id> woIdSyncSet, String serviceName, string source ) {
        System.debug('Clear-WO : Inside fslToD3CalloutAsynchronous');
        Id workOrderId = new List<Id>( woIdSyncSet )[0];
        ClearResult result = fslToD3Callout( jsonwrapper, callId, workOrderId, serviceName, source );
        Boolean isError = result.isError;
        if( isError ) FSL_D3SyncLogger.syncIssueLogger( woIdSyncSet );
        logClearCalloutResults( new List<ClearResult>{ result } );
        processClearWorkOrderResult( new List<Id>( woIdSyncSet )[0], !isError );
    }

    public static ClearResult fslToD3Callout( String jsonwrapper, String callId, Id workOrderId, String serviceName, string source ) {
        System.debug( 'Clear-WO : Inside fslToD3CalloutSynchronous' );
        ClearResult result = new ClearResult( jsonWrapper, callId, System.now(), workOrderId );

        Boolean isError = true;
        String calloutResponse = 'No response returned';
        String message = 'Clear';
        
        system.debug( 'Clear-WO : Before sending HttpRequest' );
        try {
            Http http = new Http();
            HttpRequest request = createHttpRequest( jsonwrapper, serviceName, callId, source );
            HttpResponse response = http.send( request );

            if( response == null ) {
                calloutResponse = 'No response returned';
                message = 'Clear';
                System.debug( 'Clear-WO : Response is Null' );
            }
            else {
                calloutResponse = JSON.serializePretty( response.getBody() );
                
                Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped( response.getBody() );
                String serviceResponse = String.valueOf( body.get( 'statusCode' ) );
                    
                if( response.getStatusCode() != 200 ) {
                    message = 'The HTTP response\'s status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus();
                    System.debug( 'Clear-WO : Response is not 200' );
                } 
                else if( serviceResponse == '200' ) {
                    message = 'SUCCESS';
                    isError = false;
                    System.debug( 'Clear-WO : Response is 200' );
                } 
                else {
                    String statusDescription = String.valueOf( body.get( 'statusDescription' ) );
                    message = 'The response body\'s status code returned was not expected: ' + serviceResponse + ': ' + statusDescription;
                    System.debug( 'Clear-WO : statusCode in response body is not 200' );
                }
            }
        }
        catch( CalloutException ex ) {
            calloutResponse = ex.getStackTraceString();
            message = 'Callout Exception: ' + ex.getMessage();
            System.debug( 'Clear-WO : Http request to Clear threw a callout exception' );
        }
        catch( Exception ex ) {
            calloutResponse = ex.getStackTraceString();
            message = 'Exception: ' + ex.getMessage();
            System.debug( 'Clear-WO : Http request to Clear threw an exception' );
        }
        result.finalize( calloutResponse, message, isError, System.now() );
        return result;
    }

    private static HttpRequest createHttpRequest( String json1, String serviceName, String callId, string source ) {
        DateTime serviceStartTime = system.now();
        FSL_Service_Endpoints__c oauthEndpoint = FSL_Service_Endpoints__c.getValues('OAuth');
        Http http = new Http();
        HttpRequest oauthrequest = new HttpRequest();
        oauthrequest.setMethod('POST');
        oauthrequest.setHeader('Content-Type','application/x-www-form-urlencoded;charset=UTF-8');
        if(oauthEndpoint.Timeout__c != null){
            oauthrequest.setTimeout(integer.ValueOf(oauthEndpoint.Timeout__c));
        }
        String oauthbody = '';
        if(!string.isEmpty(oauthEndpoint.Endpoint_URL__c)){
            oauthrequest.setEndpoint(oauthEndpoint.Endpoint_URL__c);
            oauthbody = 'grant_type=client_credentials'+'&client_id='+EncodingUtil.urlEncode(oauthEndpoint.client_id__c,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(oauthEndpoint.client_secret__c,'UTF-8');
        }
        oauthrequest.setBody(oauthbody);
        httpResponse oauthresponse = http.send(oauthrequest);
        Map<String, Object> oauthresults = (Map<String, Object>)JSON.deserializeUntyped(oauthresponse.getBody());
        String token = '';
        if (oauthresponse.getStatusCode() == 200) {
            token = String.valueOf(oauthresults.get('access_token'));
        } else {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(json1,'','The status code returned was not expected: ' + oauthresponse.getStatusCode() + ' ' + oauthresponse.getStatus(),'Update-OAuth', true, callId, '', 'D3Callout');
            }
        
        System.debug('DEBUG SERVICENAME ' +serviceName);
        FSL_Service_Endpoints__c clearEndpoint = FSL_Service_Endpoints__c.getValues('Clear');
        FSL_Service_Endpoints__c historyEndpoint = FSL_Service_Endpoints__c.getValues('Call_History');
        HttpRequest request = new HttpRequest();
        request.setHeader( 'Content-Type', 'application/json;charset=UTF-8' );
        request.setMethod( 'POST' );
//        if( clearEndpoint.client_id__c != null ) {
//            request.setHeader( 'client_id', clearEndpoint.client_id__c );
//        }
//        if( clearEndpoint.client_secret__c != null ) {
//            request.setHeader( 'client_secret', clearEndpoint.client_secret__c );
//        }
//        if( String.isNotBlank( clearEndpoint.Client_Cert_Name__c ) ) {
//            request.setClientCertificateName( clearEndpoint.Client_Cert_Name__c );
//        }
        if( clearEndpoint.Timeout__c != null)  {
            request.setTimeout( Integer.valueOf( clearEndpoint.Timeout__c ) );
        }
        if( source == 'D3' && !String.isEmpty( clearEndpoint.Endpoint_URL__c ) ) {
            request.setEndpoint( clearEndpoint.Endpoint_URL__c );
        }
        else if ( historyEndpoint != null && !String.isEmpty( historyEndpoint.Endpoint_URL__c )){
            request.setEndpoint(historyEndpoint.Endpoint_URL__c );
        }
        request.setHeader('Authorization','Bearer '+token);
//        if( !String.isEmpty( clearEndpoint.Endpoint_URL__c ) ) {
//            request.setEndpoint( clearEndpoint.Endpoint_URL__c );
//        } else if( !String.isEmpty( clearEndpoint.Named_Credential__c ) ) {
//            request.setEndpoint( clearEndpoint.Named_Credential__c );
//        }
        request.setBody( json1 );
        return request;
    }

    private static void logClearCalloutResults( List<ClearResult> clearResults ) {
        FSL_ApplicationLog.IApplicationLogService applicationLogService = new FSL_ApplicationLog.Factory().createService();
        List<FSL_PII_Setting__mdt> piiSettings = applicationLogService.getPiiSettings();
        List<FSL_ApplicationLog.ApplicationLog> applicationLogs = new List<FSL_ApplicationLog.ApplicationLog>();
        for( ClearResult clearResult : clearResults ) {
            ClearCalloutApplicationLog applicationLog = new ClearCalloutApplicationLog( piiSettings );
            applicationLog.logClearResult( clearResult );
            applicationLogs.add( applicationLog );
        }
        applicationLogService.saveApplicationLogs( applicationLogs );
    }

    private static void processClearWorkOrderResult( Id workOrderId, Boolean isSuccessfullyCleared ) {
        FSL_Schedule.IMinuteScheduleService minuteScheduleService = new FSL_Schedule.Factory().createService();
        clearQueuedCallService.processClearResult( workOrderId, isSuccessfullyCleared, minuteScheduleService );
    }

    public class ClearResult {
        public String requestBody;
        public String calloutResponse;
        public String message;
        public Boolean isError;
        public String callId;
        public Datetime serviceStart;
        public Datetime serviceEnd;
        public Id workOrderId;

        public ClearResult( String requestBody, String callId, Datetime serviceStart, Id workOrderId ) {
            this.requestBody = requestBody;
            this.callId = callId;
            this.serviceStart = serviceStart;
            this.workOrderId = workOrderId;
        }

        public void finalize( String calloutResponse, String message, Boolean isError, Datetime serviceEnd ) {
            this.calloutResponse = calloutResponse;
            this.message = message;
            this.isError = isError;
            this.serviceEnd = serviceEnd;
        }
    }

    // *********************************************
    // * Application Log
    // *********************************************
    public class ClearCalloutApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        private List<FSL_PII_Setting__mdt> piiSettings;

        public ClearCalloutApplicationLog( List<FSL_PII_Setting__mdt> piiSettings ) {
            super();
            this.piiSettings = piiSettings;
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'Clear';
            appLog.API_Name__c = 'D3Callout';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void logClearResult( ClearResult clearResult ) {
            if( String.isNotBlank( clearResult.requestBody ) ) {
                appLog.Request_Body__c = limitLength( maskPiiDataInJson( clearResult.requestBody, piiSettings ) );
            }
            if( String.isNotBlank( clearResult.calloutResponse ) ) {
                appLog.Response_Body__c = limitLength( clearResult.calloutResponse );
            }
            appLog.Call_Id__c = clearResult.callId;
            appLog.ServiceTime__c = getProcessTime( clearResult.serviceStart, clearResult.serviceEnd );
            appLog.Error_Caught__c = clearResult.isError;
            if( clearResult.isError ) {
                appLog.Error_Message__c = clearResult.message;
            }
            else {
                appLog.Success_Message__c = clearResult.message;
            }
        }
    }

    // *********************************************
    // * LEGACY CODE - TODO: Refactor callers to use class above
    // *********************************************
    public static List<FSL_ClearJsonWorkOrder> clearedWorkOrders(Set<Id> WOIds, String serviceName) {
        return clearedWorkOrders(WOIds, true, serviceName);
    }

    public static List<WorkOrder> getWorkOrderDataForClearProcessing( Set<Id> woIds ) {
        List<WorkOrder> workOrders = new List<WorkOrder>();

        System.debug('Clear-WO: Inside getWorkOrderDataForClearProcessing');
        // Perform the query and extract the WorkOrder fields
        // The code below including the exception handling is refactored out of the 
        // clearedWorkOrders(Set<Id> WOIds, Boolean makeCallout, String serviceName) method below 
        Integer callCount;
        Integer dayCount;
       DateTime DateLimiter;
        List<FSL_IVR_Response_Call_Count_Control__mdt> recordCountList=[SELECT Id,Call_Count__c,Day_Count__c FROM FSL_IVR_Response_Call_Count_Control__mdt
                                                                    WHERE Label='Call Count' LIMIT 1];
        if(!recordCountList.isEmpty() && recordCountList[0].Call_Count__c !=null && (Integer)recordCountList[0].Call_Count__c!=0){
                callCount=(Integer)recordCountList[0].Call_Count__c;
            }else{
                callCount=10;
            }
        if(!recordCountList.isEmpty() && recordCountList[0].Day_Count__c !=null && (Integer)recordCountList[0].Day_Count__c !=0){
                dayCount=(Integer)recordCountList[0].Day_Count__c;
                DateLimiter=DateTime.now().addDays(-dayCount);
            }else{
                DateLimiter=DateTime.now().addDays(-10);
            }
       /* if(!recordCountList.isEmpty()){
            if(recordCountList[0].Call_Count__c !=null && (Integer)recordCountList[0].Call_Count__c!=0){
                callCount=(Integer)recordCountList[0].Call_Count__c;
            }else{
                callCount=10;
            }
          
        }
        else{
            callCount=10;
        }*/
        if(Test.isRunningTest()){callCount=2;}

        try {
            workOrders = ( [SELECT Id,Resolution_Code__c,Clearing_Code__c,Drop_Box_Info__c,Tow_Destination_Name__c,Tow_Contact_Phone_Number__c,Tow_Contact_First_Name__c,Tow_Contact_Last_Name__c,State,City,
                            postalcode,country,Street,CreatedDate,WorkOrderNumber,Status, External_Id__c, Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,            
                            LastModifiedBy.Name,LastModifiedDate,Tow_Location__Latitude__s,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s, Service_Order_Number__c, Call_Id__c,RAP_Case_Number__c,
                            Dispatched_Timestamp__c,Cleared_Timestamp__c,Call_Type__c,Timezone_Id__c,Timezone_Offset__c,Non_Emergency_Appointment_Time__c,Collision__c,Red_Flag__c,Number_Of_Passengers__c,
                            Is_Tow_WorkType__c,In_Tow_Timestamp__c,Needs_Flatbed__c,Scheduled_Timestamp__c ,Legacy_Priority_Code__c, Priority_Code__c,Flatbed_Requested__c,Call_Date__c,Latitude,longitude,
                            Landmark__c,Highway__c,Mile_Marker__c,Original_Member_Id__c,Cross_Street__c,Cross_Street_2__c,Location_Code__c,Tow_Latitude__c,Tow_Longitude__c,Tow_Landmark__c,Tow_Street__c,
                            Tow_City__c,Tow_State__c,Spotted_Timestamp__c,Wait_Time__c,Tow_Postal_Code__c,Enroute_Timestamp__c,Tow_Country__c,Account.Name,Account.Facility_ID__c,InitialETA_Legacy__c,
                            Pta__c,Payment_Codes__c,On_Location_Timestamp__c,Account.Facility_Type__c,Contact.Original_Member_Id__c,Contact.Membership_Type__c,
                            Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,Contact.Membership_Islocalclub__c,
                            Contact.Member_Card_Num__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Level__c,Contact.Membership_Birthday__c,Contact.Membership_Since__c,
                            Contact.Membership_Status__c,Contact.Membership_Org__c,Contact.Membership_OrgCode__c,Contact.External_ID__c,Contact.Type__c,Contact.Title,Contact.FirstName,
                            Contact.LastName,Contact.Phone_Type__c,Contact.Phone,Contact.Phone_Extension__c,Contact.Sms_Optin__c,Contact.Email_Type__c,Contact.Email,Contact.Language_Preference__c, WO_Member_Phone_Number__c, Call_Source__c , 
                                (SELECT Id,address,Drop_Box_Info__c,SLR_En_Route_Miles__c,SLR_Tow_Miles__c,Landmark__c,Highway__c,Mile_Marker__c,Location_Code__c,Street,State,City,Country, Call_Source__c, 
                                    postalcode,Cross_Street__c,Cross_Street_2__c,Tow_Destination_Name__c,Subject,ParentRecordId,SchedStartTime, ServiceTerritory.Facility_Number__c,ServiceTerritory.Name,
                                    Latitude,Longitude,Service_Resource__c,ETA__c, Address_Change_Counter__c, FSL_Actual_Miles_Driven__c, Payment_Type__c, Payment_Required__c, isBreakdown__c
                                    ,D3_AAR_Id__c
                                FROM ServiceAppointments 
                                WHERE ParentRecordId IN: woIds),
                                (SELECT Id,Name,Code__c,Description__c,Type__c 
                                FROM TroubleCodes__r 
                                WHERE Work_Order__c IN:woIds), 
                                (SELECT Id,Name,RV_Class__c,RV_Length__c,Trailer_Hitchtype__c,Trailer_Length__c,Vehicle_Color__c,Vehicle_Drive_Type__c,Vehicle_Fuel_Type__c,Vehicle_Make__c,Vehicle_Model__c,
                                    Vehicle_Odometer__c,Vehicle_Special_Equipment_Needs__c,Vehicle_State__c,Vehicle_Tag__c,Vehicle_Trim__c,Vehicle_Type__c,Vehicle_VIN__c,Vehicle_Year__c,Work_Order__c 
                                FROM Member_Vehicles__r 
                                WHERE Work_Order__c IN: woIds),
                                (SELECT Id,Name,Policy_Code__c,Policy_Description__c 
                                FROM Policies__r 
                                WHERE Work_Order__c IN: woIds),
                                (SELECT Id,Name,CreatedBy.EmployeeNumber,FSL_Comment__c,FSL_Work_Order__c,createdDate  //kht: modified
                                FROM Call_Comments__r),
                                (SELECT Id,Cost__c,Unit__c, Product__c, Product__r.ProductCode 
                                FROM Service_Line_Items__r 
                                WHERE Work_Order__c IN: woIds),
                                D3_AAR_Id__c
                            FROM WorkOrder 
                            WHERE Id IN: woIds and status NOT IN ('Cleared','Cancelled') and CreatedDate >=:DateLimiter ORDER BY Lastmodifieddate desc LIMIT :callCount]);
            system.debug('#######'+workOrders.size());
        }
        catch( Exception e ) {
            if( workOrders == null ) {
                String message = System.Label.FSL_API_Callout_No_WorkOrders;
                FSL_ApplicationLogCreator.calloutLogger( '', '', message, 'Clear', true, '', '', 'D3Callout' );
            }
            else {
                List<String> callIds = new List<String>();
                Set<Id> v1 = woIds;
                String strWoIds = String.valueOf(v1);
                String strCallIds = String.valueOf(callIds);
            
                String message = 'No FeedItems for ' +  strWoIds;    //System.Label.FSL_API_Callout_No_SAsOrARs;
                FSL_ApplicationLogCreator.calloutLogger( strWoIds.subString( 0, strWoIds.length() ), '', message, 'Clear', true, strCallIds.subString( 0, strCallIds.length() ), '', 'D3Callout' );
            }
            workOrders = null;
        }
        return workOrders;
    }

    public static Map<Id,AssignedResource> getServiceAppointmentIdToAssignedResourceMap( List<WorkOrder> workOrders ) {
        Map<Id,AssignedResource> saIdArMap = new Map<Id,AssignedResource>();

        List<ServiceAppointment> allServiceAppointments = new List<ServiceAppointment>();
        for(WorkOrder wo : workOrders) {
            allServiceAppointments.addAll( wo.ServiceAppointments );
        }

        List<AssignedResource> assignedResources = ( [SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.Name,ServiceResource.LocationId, 
                                                        ServiceResource.Vehicle__r.Truck_ID__c, ServiceResource.Location.Longitude, ServiceResource.Location.Latitude,
                                                        ServiceResource.Location.VIN__c, ServiceResource.Driver_Id__c
                                                    FROM AssignedResource 
                                                    WHERE ServiceAppointmentId IN: allServiceAppointments] );
        for( ServiceAppointment sa : allServiceAppointments ) {
            saIdARMap.put( sa.Id, getAssignedResources( sa, assignedResources ) );
        }

        return saIdArMap;
    }

    public static AssignedResource getAssignedResources( ServiceAppointment sa, List<AssignedResource> assignedResources ) {
        AssignedResource assignedResource = new AssignedResource();
        for( AssignedResource ar : assignedResources ) {
            if( ar.ServiceAppointmentId == sa.Id ) {
                assignedResource = ar;
                break;
            }
        }
        return assignedResource;
    }

    public static Map<Id,List<FeedItem>> getWorkOrderIdToFeedItemsListMap( Set<Id> woIdSet ) {
        Map<Id,List<FeedItem>> woIdFeedItemsMap = new Map<Id,List<FeedItem>>();

        System.debug('Clear-WO: Inside getWorkOrderIdToFeedItemsListMap');

        for( FeedItem f : [SELECT Id,InsertedBy.Name,LastModifiedDate,ParentId,Type,Body FROM FeedItem WHERE ParentId IN:woIdSet AND TYPE = 'TextPost'] ) {
            if( woIdFeedItemsMap.containsKey( f.parentId ) ) {
                woIdFeedItemsMap.get( f.parentId ).add( f );
            } else {
                woIdFeedItemsMap.put( f.parentId, new List<FeedItem>{ f } );
            }
        }

        return woIdFeedItemsMap;
    }

    public static List<FSL_ClearJsonWorkOrder> clearedWorkOrders( Set<Id> woIds, Boolean makeCallout, String serviceName ) {
        FSL_ClearJsonWorkOrder wrapper;
        system.debug( 'WOIds====' + woIds);
    List<FSL_ClearJsonWorkOrder> wrappers= new List<FSL_ClearJsonWorkOrder>();
        List<WorkOrder> workOrders = getWorkOrderDataForClearProcessing( woIds );
        if ( workOrders != null && workOrders.size() > 0 ) {
            Map<Id,AssignedResource> saIdARMap = getServiceAppointmentIdToAssignedResourceMap( workOrders );
            Map<Id,List<FeedItem>> woIdFeedItemsMap = getWorkOrderIdToFeedItemsListMap( woIds );

            // SNK ERS-218921 this code is left as is
         wrappers = populateWrapperValues( workOrders, saIdARMap, woIdFeedItemsMap, serviceName );
            wrapper = wrappers[wrappers.size() - 1];
            if( makeCallout ) {
                String wrapperJson = JSON.serializePretty( wrapper,true );
                system.debug( '==wrapperJson=======' + wrapperJson );
                wrapperJson = wrapperJson.replace( 'system_Z', 'system' );
                Set<Id> woIdSyncSet = new Set<Id>();
                woIdSyncSet.add( workOrders[0].Id );
                fslToD3CalloutAsync( wrapperJson, workOrders[0].Call_Id__c, woIdSyncSet, serviceName,workOrders[0].Call_Source__c);
            }
        }
        return wrappers;
    }

    private static List<FSL_ClearJsonWorkOrder> populateWrapperValues( List<WorkOrder> workOrders, Map<Id,AssignedResource> saIdARMap, Map<Id,List<FeedItem>> woIdFeedItemsMap, String serviceName ) {
        List<FSL_ClearJsonWorkOrder> clearJsonWorkOrders = new List<FSL_ClearJsonWorkOrder>();

        for( WorkOrder workOrder : workOrders ) {
            clearJsonWorkOrders.add( populateWrapperValues( workOrder, saIdARMap, woIdFeedItemsMap, serviceName ) );
        }

        return clearJsonWorkOrders;
    }

    private static FSL_ClearJsonWorkOrder populateWrapperValues( WorkOrder workOrder, Map<Id,AssignedResource> saIdARMap, Map<Id,List<FeedItem>> woIdFeedItemsMap, String serviceName ) {
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = new FSL_ClearJsonWorkOrder();
            
        FSL_WorkOrderD3JsonWrapper wrapper = new FSL_WorkOrderD3JsonWrapper();
        clearJsonWorkOrder = wrapper.Wrap( workOrder, saIdARMap, woIdFeedItemsMap, serviceName, null );

        return clearJsonWorkOrder;
    }
}