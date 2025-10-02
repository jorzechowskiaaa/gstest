/**
 * Name : FSL_ToD3Update
 * Description : Making a Post callout to D3 with the updated values from WorkOrder record.
 * Methods :
 *   1. HTTPResponse : makePostCallout
 *   2. None : loadWorkOrder
 *   3. CalloutWrapperD3 : wrapperBuilder
 */

global class FSL_ToD3Update {

    public static List<AssignedResource> AssignedResources = null;
    private static Map<String, FSL_API_Exception_Codes__c> APIExceptions = FSL_API_Exception_Codes__c.getAll();
    private static Map<String, FSL_ServiceSettings__c> serviceSettings = FSL_ServiceSettings__c.getAll();

    // ERS-226724 For D3 purpose it is more of an SA to D3 Mapping
    private static Map<String, FSL_Work_Order_Status_Code_Mapping__c> SAStatusCodes = FSL_Work_Order_Status_Code_Mapping__c.getAll();
    
    public FSL_ToD3Update() {
    }

    /**********
     * @Method Name:loadWorkOrders
     * @Parameters:Set<Id>
     * @Return: None
     * @Description: Method takes WorkOrder ids and cues the callout to D3 in the future method after populating Callout wrapper 
                    for each WorkOrder record.
       @Author: 
     ***********/
    public static void loadWorkOrders (Set<Id> WOIds){
        List<WorkOrder> WorkOrders = null;
        List<ServiceAppointment> AllServiceAppointments = new List<ServiceAppointment>();
        Map<WorkOrder, List<ServiceAppointment>> WOtoSAMap = new Map<WorkOrder, List<ServiceAppointment>>();
        Map<ServiceAppointment, List<AssignedResource>> SAToARMap = new Map<ServiceAppointment, List<AssignedResource>>();
        List<String> callIds = new List<String>();
        try {
            // Shankar - Modified this SOQL to also pull Tow SAs into consideration since for the "In Tow" case, the TowSA is the one triggering the update
            WorkOrders = ([SELECT Id, External_Id__c,Call_Date__c, CreatedDate,  Call_Id__c,
                                        Account.Facility_ID__c, Account.Facility_Type__c, Contact.API_Type__c, 
                                        (SELECT Id, SchedStartTime, ServiceTerritory.Facility_Number__c , Status, Spotted_Timestamp__c, Scheduled_Timestamp__c, Dispatched_Timestamp__c, LastModifiedBy.Name, LastModifiedDate
                                         FROM ServiceAppointments WHERE ParentRecordId IN: WOIds
                                         ORDER BY RecordType.DeveloperName ) 
                                    FROM WorkOrder WHERE Id IN: WOIds]);
            for (WorkOrder wo : WorkOrders) {
                WOtoSAMap.put(wo, wo.ServiceAppointments);
                AllServiceAppointments.addAll(wo.ServiceAppointments);
            }            
            AssignedResources = ([SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.Driver_Id__c, 
                                    ServiceResource.LocationId, ServiceAppointment.SchedStartTime,
                                    ServiceResource.Location.VIN__c, ServiceResource.Vehicle__r.Truck_Id__c
                                    FROM AssignedResource WHERE ServiceAppointmentId IN: AllServiceAppointments]);
            for (ServiceAppointment sa : AllServiceAppointments) {
                SAToARMap.put(sa, getAssignedResources(sa));
            }
        } catch (Exception e) {
            if (WorkOrders == null) {
                String message = System.Label.FSL_API_Callout_No_WorkOrders;
                FSL_ApplicationLogCreator.calloutLogger('', '', message, 'Update', true, '', '', 'D3Callout');
            }
            else{
                String message = System.Label.FSL_API_Callout_No_SAsOrARs;
                FSL_ApplicationLogCreator.calloutLogger(String.valueOf(WOIds).subString(0, 99), '', message, 'Update', true, String.valueOf(callIds).subString(0, 99), '', 'D3Callout');
            }
            return;
        }

        for (WorkOrder WO : WorkOrders) {
            List<ServiceAppointment> woSAs = WOtoSAMap.get(WO);
            ServiceAppointment sa = woSAs[0];

            // for the In Tow case, use the Tow SA for status if that is the one triggering the change
            if ( woSAs.size() > 1 )  {  // Tow WOs
                if ( woSAs[1].status  == 'In Tow') {
                    sa = woSAs[1];
                }
            }

            System.debug('Inside ToD3Update'+sa);
            String servicingFacility = sa.ServiceTerritory.Facility_Number__c;
            system.debug('====SAToARMap=='+SAToARMap);
            if(SAToARMap.get(sa) != null && !SAToARMap.get(sa).isEmpty()) {
                AssignedResource ar = SAToARMap.get(sa)[0];
                if (ar == null) {
                    FSL_ApplicationLogCreator.calloutLogger(WO.Id, '', 'MissingAssignedResource', 'Update', true, '', '', 'D3Callout');
                    return;
                }
                
                Set<Id> woIdSyncSet = new Set<Id>();
                woIdSyncSet.add(WO.Id);
                system.debug('****SA.Status***'+sa.Status);
                CalloutWrapperD3 wrapper = wrapperBuilder(WO, sa, ar, servicingFacility);
                
                // make ETA Call Or Send D3 Call
                /*if(WO.Status == 'En Route'){
                    FSL_ToGlympseCallout.getEta(String.valueOf(sa.id), JSON.serializePretty(wrapper), WO.Call_Id__c);
                }else{*/
                    system.debug('****JSON.serializePretty(wrapper)***'+JSON.serializePretty(wrapper));
                    makePostCallout(JSON.serializePretty(wrapper), WO.Call_Id__c,woIdSyncSet);
                //}
            }
        }
    }

    /**********
     * @Method Name:mapOperatorForChatterFollow
     * @Parameters:ServiceAppointment sa
     * @Return: List<AssignedResource>
     * @Description: Method takes ServiceAppointment record and returns its related AssignedResources children
       @Author: 
     * **********/

    public static List<AssignedResource> getAssignedResources(ServiceAppointment sa) {
        List<AssignedResource> arList = new List<AssignedResource>();
        for(AssignedResource ar : AssignedResources) {
            if (ar.ServiceAppointmentId == sa.Id) {
                arList.add(ar);
            }
        }
        return arList;
    }

    @TestVisible
    public static CalloutWrapperD3 wrapperBuilder (WorkOrder workOrder, ServiceAppointment woSA, AssignedResource ar, String servicingFacility) {
        //Populate values and assign to wrapper variables for each WorkOrder
        SystemOrganization sysOrg = new SystemOrganization(serviceSettings.get('D3').Source_System_Org_Name__c, 
                                                        serviceSettings.get('D3').Source_System_Org_Name__c);
        SourceOrTarget source     = new SourceOrTarget(serviceSettings.get('D3').Source_System_Org_Name__c, sysOrg);
        SourceOrTarget target     = new SourceOrTarget('D3', sysOrg);
        DateTime nowTime = System.now();
        DateTime eventTime = Datetime.newInstanceGmt(nowTime.yearGMT(), nowTime.monthGMT(),nowTime.dayGMT(),nowTime.hourGMT(),nowTime.minuteGMT(),nowTime.secondGMT());
                
        //CallEvent callEvent       = new CallEvent(workOrder.External_Id__c, System.todayGMT(), workOrder.call_Id__c, eventTime);
        System.debug('Call Event------------'+ workOrder);
        
        CallEvent callEvent       = new CallEvent(workOrder.External_Id__c, Date.Valueof(workOrder.Call_Date__c), workOrder.call_Id__c, eventTime);
        List<CallEvent> events    = new List<CallEvent>();
        
        String driverID;
        if(String.isNotBlank(ar.ServiceResource.Driver_Id__c)){
            driverID = ar.ServiceResource.Driver_Id__c;
        }else{
            driverID = '';
        } 
        //Driver driver             = new Driver(String.valueOf(ar.ServiceResource.Driver_Id__c));
        Driver driver             = new Driver(driverID);
        Truck truck               = new Truck(driver, ar.ServiceResource.Vehicle__r.Truck_Id__c);
        Schema.Location location  = null;
        Facility facility         = new Facility('ADDRESS', location, servicingFacility);
        UpdatedBy updatedBy       = new UpdatedBy('SYSTEM');
        Datetime dt               = ar.ServiceAppointment.SchedStartTime;
        Datetime eta              = Datetime.newInstanceGmt(dt.yearGMT(), dt.monthGMT(),dt.dayGMT(),dt.hourGMT(),dt.minuteGMT(),dt.secondGMT());
        system.debug(SAStatusCodes+' **MAPPING** '+ woSA.Status);
        StatusDetail stDetail     = new StatusDetail(SAStatusCodes.get(woSA.Status).Work_Order_Status_Code__c, 
                                        '', updatedBy, facility, truck, eta, String.valueOf(woSA.LastModifiedDate));        
        
        // Assigned and Dispatched Call Events must be sent with the initial ER call
        if('ER'.equals(SAStatusCodes.get(woSA.Status).Work_Order_Status_Code__c)){
            
            // create spotted events
            DateTime spottedTime;
            if(woSA.Spotted_Timestamp__c != null){
                spottedTime = DateTime.newInstanceGmt(woSA.Spotted_Timestamp__c.yearGMT(), woSA.Spotted_Timestamp__c.monthGMT(), woSA.Spotted_Timestamp__c.dayGMT(), woSA.Spotted_Timestamp__c.hourGMT(), woSA.Spotted_Timestamp__c.minuteGMT(), woSA.Spotted_Timestamp__c.secondGMT());
            }else{
                spottedTime = eventTime;
            }
            //CallEvent spCallEvent    = new CallEvent(workOrder.External_Id__c, System.todayGMT(), workOrder.call_Id__c, eventTime);
            CallEvent spCallEvent    = new CallEvent(workOrder.External_Id__c, Date.Valueof(workOrder.Call_Date__c), workOrder.call_Id__c, spottedTime);
            
            // created assigned event
            DateTime scheduledTime;
            if(woSA.Scheduled_Timestamp__c != null){
                scheduledTime = DateTime.newInstanceGmt(woSA.Scheduled_Timestamp__c.yearGMT(), woSA.Scheduled_Timestamp__c.monthGMT(), woSA.Scheduled_Timestamp__c.dayGMT(), woSA.Scheduled_Timestamp__c.hourGMT(), woSA.Scheduled_Timestamp__c.minuteGMT(), woSA.Scheduled_Timestamp__c.secondGMT());
            }else{
                scheduledTime = eventTime;
            }
            //CallEvent asCallEvent    = new CallEvent(workOrder.External_Id__c, System.today(), workOrder.call_Id__c, scheduledTime);
            CallEvent asCallEvent    = new CallEvent(workOrder.External_Id__c, Date.Valueof(workOrder.Call_Date__c), workOrder.call_Id__c, scheduledTime);
            
            // create dispatched event
            DateTime dispatchedTime;
            if(woSA.Dispatched_Timestamp__c != null){
                dispatchedTime = DateTime.newInstanceGmt(woSA.Dispatched_Timestamp__c.yearGMT(), woSA.Dispatched_Timestamp__c.monthGMT(), woSA.Dispatched_Timestamp__c.dayGMT(), woSA.Dispatched_Timestamp__c.hourGMT(), woSA.Dispatched_Timestamp__c.minuteGMT(), woSA.Dispatched_Timestamp__c.secondGMT());
            }else{
                dispatchedTime = eventTime;
            }
            //CallEvent diCallEvent    = new CallEvent(workOrder.External_Id__c, System.today(), workOrder.call_Id__c, dispatchedTime);
            CallEvent diCallEvent    = new CallEvent(workOrder.External_Id__c, Date.Valueof(workOrder.Call_Date__c), workOrder.call_Id__c, dispatchedTime);
            
            StatusDetail asDetail    = new StatusDetail('AS', '', updatedBy, facility, truck, eta, String.valueOf(woSA.Scheduled_Timestamp__c));
            asCallEvent.statusDetail = asDetail;
            
            StatusDetail diDetail    = new StatusDetail('DI', '', updatedBy, facility, truck, eta, String.valueOf(System.now()));
            diCallEvent.statusDetail =  diDetail;                                   
            
            StatusDetail spDetail    = new StatusDetail('SP', 'FS', updatedBy, facility, truck, eta, String.valueOf(System.now()));
            spCallEvent.statusDetail =  spDetail;             
                                                 
            events.add(spCallEvent);
            events.add(asCallEvent);
            events.add(diCallEvent);
        }
        events.add(callEvent);
        
        CalloutWrapperD3 wrapper  = new CalloutWrapperD3();
        //wrapper.id                = FSL_DataFactory.generateGUID();
        wrapper.id                = generateGUID();
        wrapper.requestEventType  = serviceSettings.get('D3').RequestEventType__c;
        wrapper.subType           = serviceSettings.get('D3').RequestSubtype__c;
        wrapper.status            = woSA.Status;
        //wrapper.version           = String.valueOf(serviceSettings.get('D3').Version__c);
        wrapper.version           = '';
        wrapper.sourceSystem      = source;
        wrapper.targetSystem      = target;
        callEvent.statusDetail    = stDetail;
        wrapper.callEvents        = events;
        wrapper.createDate       = woSA.LastModifiedDate.getTime();
        return wrapper;
    }


    public static void makePostCallout (String requestWrapper, String callId,Set<Id> woIdSyncSet) {
        //directing the callout to be perfomed from both Batch updates(Async) as well as trigger updates(Sync)
        //Taking the path of least risk to avoid new potential errors
        system.debug('@@@@ Future @@@'+System.isFuture());
        system.debug('@@@@ Batch @@@'+System.isBatch());
        if(!System.isFuture() || !System.isBatch()){
            // your future method call here
            makePostCalloutFuture (requestWrapper, callId, woIdSyncSet);
        }
        else {
            // your normal method call here as this gets called from existing batch process
            makePostCalloutNotFuture(requestWrapper, callId, woIdSyncSet);
        }
    }

    /**********
    * @Method Name:makePostCalloutFuture
    * @Parameters:String requestWrapper, String callId,Set<Id> woIdSyncSet
    * @Return: None
    * @Description: Method takes wrapper of wo and related records and make callout to D3. this has Future Annotation
       @Author: 
    * **********/
    @future(callout=true)
    public static void makePostCalloutFuture (String requestWrapper, String callId,Set<Id> woIdSyncSet) {
        DateTime serviceStartTime = system.now();
        Http http = new Http();
        HttpRequest oauthrequest = new HttpRequest();
        FSL_Service_Endpoints__c oauthEndpoint = FSL_Service_Endpoints__c.getValues('OAuth');
       
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
     
            string testingstring =  oauthresponse.getBody();
        System.debug('244 === '+ oauthresponse.getBody());
            
        Map<String, Object> oauthresults = (Map<String, Object>)JSON.deserializeUntyped(oauthresponse.getBody());
        
        String token = '';
        if (oauthresponse.getStatusCode() == 200) {
            token = String.valueOf(oauthresults.get('access_token'));
        } else {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper,'','The status code returned was not expected: ' + oauthresponse.getStatusCode() + ' ' + oauthresponse.getStatus(),'Update-OAuth', true, callId, '', 'D3Callout');
            }

        FSL_Service_Endpoints__c updateEndpoint = FSL_Service_Endpoints__c.getValues('Update');
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setHeader('Content-Type','application/json;charset=UTF-8');
        if(updateEndpoint.Timeout__c != null){
            request.setTimeout(integer.ValueOf(updateEndpoint.Timeout__c));
        }
        if(!string.isEmpty(updateEndpoint.Endpoint_URL__c)){
            request.setEndpoint(updateEndpoint.Endpoint_URL__c);
        }
        request.setHeader('Authorization','Bearer '+token);
        request.setBody(requestWrapper);
        ResponseWrapper responseWrapper;
        HttpResponse response;
           
        try {
            response = http.send(request);
           
            responseWrapper = (ResponseWrapper) JSON.deserialize((response.getBody()), ResponseWrapper.class);
            
        }        
        catch (JSONException e) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, String.valueOf(response.getBody()),
                                                    APIExceptions.get('JSONException').Exception_Message__c,
                                                    'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
            return;
        }
        catch (Exception e) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, e.getTypeName(), e.getMessage(), 'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
            return;
        }

        if (responseWrapper == null) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, '', APIExceptions.get('NoResponseException').Exception_Message__c, 'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
        }
        else if (response.getStatusCode() != 200) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, JSON.serializePretty(response.getBody()),
                                                    'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus(),
                                                    'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
        } else {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String serviceResponse = String.valueOf(body.get('statusCode'));
            if(serviceResponse == '200'){
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, response.getBody(),'SUCCESS', 'Update', false, callId, '', 'D3Callout');
                // FSL_D3SyncLogger.resetSyncIssueLogger(woIdSyncSet);
                
            }else{
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, response.getBody(),
                                                    'The status code returned was not expected: ' + serviceResponse + ' ' + response.getStatus(),
                                                    'Update', true, callId, '', 'D3Callout');              
                FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);  
            }
        }
        //return response;
    }
    /**********
    * @Method Name:makePostCalloutFuture
    * @Parameters:String requestWrapper, String callId,Set<Id> woIdSyncSet
    * @Return: None
    * @Description: Method takes wrapper of wo and related records and make callout to D3. This does not have Future Annotation
    * **********/
    public static void makePostCalloutNotFuture (String requestWrapper, String callId,Set<Id> woIdSyncSet) {
        DateTime serviceStartTime = system.now();
        Http http = new Http();
        HttpRequest oauthrequest = new HttpRequest();
        FSL_Service_Endpoints__c oauthEndpoint = FSL_Service_Endpoints__c.getValues('OAuth');
       
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
     
            string testingstring =  oauthresponse.getBody();
        System.debug('244 === '+ oauthresponse.getBody());
            
        Map<String, Object> oauthresults = (Map<String, Object>)JSON.deserializeUntyped(oauthresponse.getBody());
        
        
        
        String token = '';
        if (oauthresponse.getStatusCode() == 200) {
            token = String.valueOf(oauthresults.get('access_token'));
        } else {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper,'','The status code returned was not expected: ' + oauthresponse.getStatusCode() + ' ' + oauthresponse.getStatus(),'Update-OAuth', true, callId, '', 'D3Callout');
            }

        FSL_Service_Endpoints__c updateEndpoint = FSL_Service_Endpoints__c.getValues('Update');
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setHeader('Content-Type','application/json;charset=UTF-8');
        if(updateEndpoint.Timeout__c != null){
            request.setTimeout(integer.ValueOf(updateEndpoint.Timeout__c));
        }
        if(!string.isEmpty(updateEndpoint.Endpoint_URL__c)){
            request.setEndpoint(updateEndpoint.Endpoint_URL__c);
        }
        request.setHeader('Authorization','Bearer '+token);
        //System.debug('Complete Request '+ request);
        //System.debug('Authorization ' + request.getHeader('Authorization'));
        //System.debug('Body '+ requestWrapper);
        
//        FSL_Service_Endpoints__c updateEndpoint = FSL_Service_Endpoints__c.getValues('Update');
//        Http http = new Http();
//        HttpRequest request = new HttpRequest();
//        request.setMethod('POST');
//        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
            
//        if(updateEndpoint.client_id__c != null){
//            request.setHeader('client_id', updateEndpoint.client_id__c);
//        }
//        if (updateEndpoint.client_secret__c != null) {
//            request.setHeader('client_secret', updateEndpoint.client_secret__c);
//        }
//        if(String.isNotBlank(updateEndpoint.Client_Cert_Name__c)){
//            request.setClientCertificateName(updateEndpoint.Client_Cert_Name__c);
//        }  
//        if(updateEndpoint.Timeout__c != null){
//            request.setTimeout(integer.ValueOf(updateEndpoint.Timeout__c));
//        }    
              
//        if(!string.isEmpty(updateEndpoint.Endpoint_URL__c)){
//            request.setEndpoint(updateEndpoint.Endpoint_URL__c);
//        }else if(!string.isEmpty(updateEndpoint.Named_Credential__c)){
//            request.setEndpoint(updateEndpoint.Named_Credential__c);
//       }

        //request.setBody(JSON.serialize(requestWrapper));
        request.setBody(requestWrapper);
        ResponseWrapper responseWrapper;
        HttpResponse response;
           
        try {
            response = http.send(request);
           
            responseWrapper = (ResponseWrapper) JSON.deserialize((response.getBody()), ResponseWrapper.class);
            
        }        
        catch (JSONException e) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, String.valueOf(response.getBody()),
                                                    APIExceptions.get('JSONException').Exception_Message__c,
                                                    'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
            return;
        }
        catch (Exception e) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, e.getTypeName(), e.getMessage(), 'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
            return;
        }

        if (responseWrapper == null) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, '', APIExceptions.get('NoResponseException').Exception_Message__c, 'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
        }
        else if (response.getStatusCode() != 200) {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, JSON.serializePretty(response.getBody()),
                                                    'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus(),
                                                    'Update', true, callId, '', 'D3Callout');
            FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
        } else {
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String serviceResponse = String.valueOf(body.get('statusCode'));
            if(serviceResponse == '200'){
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, response.getBody(),'SUCCESS', 'Update', false, callId, '', 'D3Callout');
                // FSL_D3SyncLogger.resetSyncIssueLogger(woIdSyncSet);
                
            }else{
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, response.getBody(),
                                                    'The status code returned was not expected: ' + serviceResponse + ' ' + response.getStatus(),
                                                    'Update', true, callId, '', 'D3Callout');              
                FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);  
            }
                
            
        }
        //return response;
    }
    
    public static String generateGUID () {
        Blob b = Crypto.GenerateAESKey(256);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20, 32);
        return guid;
    }

    /***********D3 Callout details***********/
    public class CalloutWrapperD3 {
        public String id {get;set;}
        public String requestEventType {get;set;}
        public String subType {get;set;}
        public String status {get;set;}
        public String version {get;set;}
        public SourceOrTarget sourceSystem {get;set;}
        public SourceOrTarget targetSystem {get;set;}
        public Long createDate {get;set;}
        public List<CallEvent> callEvents {get;set;}
    }

    public class ResponseWrapper {
        public String statusDescription {get;set;}
        public Integer statusCode {get;set;}
        public HeaderWrapper header {get; set;}
    }

    public class HeaderWrapper {
        public String id {get;set;}
        public String subType {get;set;}
        public String status {get;set;}
        public String version {get;set;}
    }

    public class SourceOrTarget {
        public String systemId {get;set;}
        public SystemOrganization systemOrganization {get;set;}
        public SourceOrTarget(String systemId, SystemOrganization systemOrganization) {
            this.systemId  = systemId;
            this.systemOrganization = systemOrganization;
        }
    }

    public class StatusDetail {
        public String status {get;set;}
        public String reasonCode {get;set;}
        public UpdatedBy updatedBy {get;set;}
        public Datetime eta {get;set;}
        //public String version {get;set;}
        public Facility facility {get;set;}
        public Truck truck {get;set;}
        public StatusDetail (){}
        public StatusDetail (String status, String reasonCode, UpdatedBy updatedBy, Facility facility, Truck truck, Datetime eta, String version) {
            this.status     = status;
            this.reasonCode = reasonCode;
            this.updatedBy  = updatedBy;
            this.eta        = eta;
            //this.version    = version;
            this.facility   = facility;
            this.truck      = truck;
        }
    }

    public class SystemOrganization {
        public String name {get;set;}
        public String code {get;set;}
        public SystemOrganization (String name, String code) {
            this.name = name;
            this.code = code;
        }
    }

    public class CallEvent {
        public String callKey {get;set;}
        public Date callDate {get;set;}
        public String callId {get;set;}
        public Datetime eventTime {get;set;}
        public StatusDetail statusDetail {get;set;}
        public CallEvent(){}
        public CallEvent(String callKey, Date callDate, String callId, Datetime eventTime) {
            this.callKey = callKey;
            this.callDate = callDate;
            this.callId = callId;
            this.eventTime = eventTime;
        }
    }

    public class UpdatedBy {
        public String contactType {get;set;}
        public UpdatedBy(String contactType) {
            this.contactType = contactType;
        }
    }

    public class Facility {
        public String foiType {get;set;}
        public Location_Wrapper location {get;set;}
        public String id {get;set;}
        public Facility(String foiType, Schema.Location location, String id) {
            this.foiType = foiType;
            this.id = id;
            this.location = new Location_Wrapper();
        }
    }
    
    public class Location_Wrapper{
        
    }

    public class Truck {
        public Driver driver {get;set;}
        public String id {get;set;}

        public Truck(Driver driver, String id) {
            this.driver = driver;
            this.id = id;
        }
    }

    public class Driver{
        public String id {get;set;}

        public Driver(String id) {
            this.id = id;
        }
    }
    /***********D3 Callout details***********/
    
}