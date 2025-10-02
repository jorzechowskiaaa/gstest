/**
 * Name : FSL_ToGlympseCallout
 * Description : Making a Get callout to Glympse to get the accesstoken and eta. 
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    1/28/2020   Rajesh Kemisetti     Initial Version
 *       12/02/2020   Clement Shiu       ERS-220415 - Optimization helper refractoring
**/ 
 
 global without sharing class FSL_ToGlympseCallout {
    
  public static FSL_Glympse_Token__c GlympseToken= FSL_Glympse_Token__c.getValues('GlympseToken');
  private static Map<String, FSL_API_Exception_Codes__c> APIExceptions = FSL_API_Exception_Codes__c.getAll();
  private static List<FSL_Application_Log__c> appLogList = new List<FSL_Application_Log__c>();
  
    //ERS-230874 Glympse Removal - Part I
    /* -----------------------------------------------

    public static String getBearerToken(){            
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        String endpoint;
        Double expireTime;
        
       // endpoint='https://aaa-api.enterprise.glympse.com/api/v1/account/login';
        endpoint=GlympseToken.Bearer_Token_Endpoint__c;
        request.setEndPoint(endpoint);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setMethod('POST');
        
        GlympseRequest wrapper = new GlympseRequest();
        
        wrapper.type = GlympseToken.Type__c;
        wrapper.username = GlympseToken.Username__c;
        wrapper.password = GlympseToken.Password__c;
        
        String wrapperJson = JSON.serializePretty(wrapper,true);
        
        system.debug('wrapperJson' + wrapperJson);
        
        request.setBody(wrapperJson);
        try{
            response = httpProtocol.send(request);
        
           Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            
            Object body= (Object)m.get('body');
            Map<String, Object> customerAttributes = (Map<String, Object>)body;
            system.debug('response: ' + response.getBody());
            return (String)customerAttributes.get('access_token');
        }catch(Exception e){
            String message = 'Exception in FSL_ToGlympseCallout.getBearerToken: ' + e.getMessage() + '\r\n' + e.getStackTraceString();
            FSL_Application_Log__c bearerTokenLog = FSL_ApplicationLogCreator.createLogReferenceWithoutInsert('', null, message, 'Update', true, null, null, null, 'getBearerToken');
            appLogList.add(bearerTokenLog);
            return null;
        }
       
    }
   
    //@future(callout=true)
    public static void getEta(String appointmentID, String wrapper, String callId){  
        
        ServiceAppointment saRec = [Select AppointmentNumber, id, ParentRecordId, Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c from ServiceAppointment where id = :appointmentID];
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        
        String accessToken;
        if(!system.Test.isRunningTest()){ 
            accessToken = FSL_ToGlympseCallout.getBearerToken();
        }
        system.debug('accessToken received = ' + accessToken);
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        String endpoint;
        
        FSL_ToD3Update.CalloutWrapperD3 callWrapper = (FSL_ToD3Update.CalloutWrapperD3) JSON.deserialize(wrapper, FSL_ToD3Update.CalloutWrapperD3.class);
        endpoint=GlympseToken.ETA_Endpoint__c +saRec.AppointmentNumber;                
        system.debug('==endpoint=='+endpoint);
        request.setEndPoint(endpoint);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String authorizationHeader = 'Bearer '+accessToken;
        request.setMethod('GET');
        request.setHeader('Authorization', authorizationHeader);
        
        try{
            response = httpProtocol.send(request);
            
            Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            Object getBody = (Object)body.get('body');
    
            Map<String, Object> tasks = (Map<String, Object>)getBody;
            if(tasks.get('tasks') != null) {
                List<Object> getTasks = (List<Object>)tasks.get('tasks');
                Integer ETA = 0;
                DateTime newETA;
                Boolean etaFound = false;
                if(getTasks != null && !getTasks.isEmpty()){
                    ETA = 0;
                    for(Integer i= 0; i < getTasks.size(); i++ ) {
                        Map<String, Object> properties = (Map<String, Object>)getTasks[i];
                        List<Object> getproperties = (List<Object>)properties.get('properties');
                        for(Object p:getproperties){
                            Map<String,Object> mp_ETA=(Map<String,Object>)p;
                            string getETA=(string)mp_ETA.get('n');
                            
                            if(getETA == 'eta'){
                                object geteta1=(object)mp_ETA.get('v');
                                system.debug(geteta+'======='+mp_ETA);
                                Map<String,Object> mp_getETA=(Map<String,Object>)geteta1;
                                 if(mp_getETA != null && mp_getETA.get('eta') != null){
                                    ETA=(Integer)mp_getETA.get('eta');
                                 }
                               
                                for(FSL_ToD3Update.CallEvent evt : callWrapper.callEvents){
                                    newETA = System.now().addSeconds(ETA / 1000);
                                    evt.statusDetail.eta = newETA;
                                    system.debug('New ETA from Glympse = ' + newETA);
                                }
                                etaFound = true;
                                break;
                            }
                            if(getETA == 'phase' && ETA != 0) {
                                String getPhaseVal =(String)mp_ETA.get('v');
                                if(getPhaseVal != 'live') {
                                    ETA = 0;
                                }
                            }
                        }
                        if(etaFound) break;
                        
                    }
                } 
                system.debug('New ETA =======' + ETA);
               
                ServiceAppointment sa=[Select Id,SchedStartTime,AppointmentNumber,ETA__c,FSL__Related_Service__c,Technician_Schedule_Override_Counter__c,SchedEndTime,WorkTypeId from ServiceAppointment WHERE Id=:appointmentID];
                sa.ETA__c=newETA;
                System.debug('sa===>'+sa);
                AssignedResource ar=[SELECT Id,ServiceAppointmentId,ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId=:appointmentID]; 
                 
                if(ETA != 0) {
                    ar.EstimatedTravelTime = ETA/(60*1000);                    
                }
                 
                Set<Id> assignedserviceAppointmentIds = new Set<Id>();
                List<ServiceAppointment> ScheduleTimeSAs=new List<ServiceAppointment>();
                Set<String> wOStatuses = new Set<String>{'Scheduled', 'Dispatched'};
                List<Serviceappointment> saListUpdate = new List<Serviceappointment>();
                 
                 if(ETA != 0){
                 
                    DateTime newScheduledStart = System.now().addSeconds(ETA / 1000);
                    DateTime previousScheduledStart = DateTime.newInstance(sa.SchedStartTime.year(),sa.SchedStartTime.month(),sa.SchedStartTime.day(), sa.SchedStartTime.hour(), sa.SchedStartTime.minute(), sa.SchedStartTime.second());
                    Long appointmentDelta = ((newScheduledStart.getTime() - previousScheduledStart.getTime()) /60000);
                    boolean runRSO = false;
                    boolean runInday = false;
                    if(math.abs(appointmentDelta) >= oSettings.In_Day_Gap_Threshold__c){
                        runInday = true;
                    }
                    else if(math.abs(appointmentDelta) >= oSettings.RSO_Threshold__c){
                        runRSO = true;
                    }

                    List<ETA_Notification__e> notificationList = new List<ETA_Notification__e>();

                    ETA_Notification__e newNotification = FSL_OptimizationHelper.createETAPlatformEvent(sa, Integer.valueOf(appointmentDelta), 'Updated Travel Time', null, true, true, runRSO, runInday);
                    notificationList.add(newNotification);
                         
                    if(!notificationList.isEmpty()){
                        List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(notificationList);
                    }
                  }
                  
                  insert appLogList;
            }
        }
        catch(Exception e){
            System.debug('====>'+e.getMessage());
            FSL_Application_Log__c etaLog = FSL_ApplicationLogCreator.createLogReferenceWithoutInsert(request.toString(),response,'Failure','Update',true,null,null, null, 'getEta');
            appLogList.add(etaLog);         
        }
       
   } 
----------------------------------------*/  

   public class GlympseRequest {
   
    public String type {get;set;} 
    public String username {get;set;}
    public String password {get;set;}

  }
    //Commented out as not used
    /*public static void makePostCallout (String requestWrapper, String callId, ServiceAppointment saRec, Integer glympseETA) {
        try {
            FSL_Service_Endpoints__c updateEndpoint = FSL_Service_Endpoints__c.getValues('Update');
            
            String appointmentID = saRec.id;
            Set<Id> woIdSyncSet = new Set<Id>();
            woIdSyncSet.add(saRec.ParentRecordId);


            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');

            if (updateEndpoint.client_id__c != null || updateEndpoint.client_secret__c != null) {
                request.setEndpoint(updateEndpoint.Endpoint_URL__c);
                request.setHeader('client_id', updateEndpoint.client_id__c);
                request.setHeader('client_secret', updateEndpoint.client_secret__c);
                if(String.isNotBlank(updateEndpoint.Client_Cert_Name__c)){
                    request.setClientCertificateName(updateEndpoint.Client_Cert_Name__c);
                }                 
            }
            else{
                request.setEndpoint('callout:Call_Update');
            }
            if(updateEndpoint.Timeout__c != null){
                request.setTimeout(integer.ValueOf(updateEndpoint.Timeout__c));
            }
            request.setBody(requestWrapper);            

            FSL_ToD3Update.ResponseWrapper responseWrapper;
            HttpResponse response;
            response = http.send(request);
            responseWrapper = (FSL_ToD3Update.ResponseWrapper) JSON.deserialize((response.getBody()), FSL_ToD3Update.ResponseWrapper.class);
            
            // insert previous logs from this transaction (to preserve order)
            if(!appLogList.isEmpty()){
                insert appLogList;
            }
            
            
            if (responseWrapper == null) {
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, '', APIExceptions.get('NoResponseException').Exception_Message__c,
                                                    'Update', true, callId, '', 'D3EnRoute');
                FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);
            }
            else if (response.getStatusCode() != 200) {
                FSL_ApplicationLogCreator.calloutLogger(requestWrapper, JSON.serializePretty(response.getBody()), 
                        'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus(), 
                        'Update', true, callId, '', 'D3EnRoute');
                FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);  
            }else {
                Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String serviceResponse = String.valueOf(body.get('statusCode'));
                if(serviceResponse == '200'){                
                    FSL_ApplicationLogCreator.calloutLogger(requestWrapper, response.getBody(), 'SUCCESS', 'Update', false, callId, '', 'D3EnRoute');
                    // FSL_D3SyncLogger.resetSyncIssueLogger(woIdSyncSet);
                    // TODO: Add SA update logic here, only to be called when D3 callout is successful
                    
                    
                }else{
                    FSL_ApplicationLogCreator.calloutLogger(requestWrapper, JSON.serializePretty(response.getBody()), 
                        'The status code returned was not expected: ' + serviceResponse + ' ' + response.getStatus(), 
                        'Update', true, callId, '', 'D3EnRoute');
                    FSL_D3SyncLogger.syncIssueLogger(woIdSyncSet);                  
                }                 
            }
            
            
        }
        catch (DmlException e){
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, e.getMessage(), 'DMLFailure', 'GlympseOut', false, callId, '', 'GlympseCallout');
        }
        catch (Exception e) {
            FSL_ApplicationLogCreator.calloutLogger(requestWrapper, e.getMessage(), 'CalloutFailure', 'GlympseOut', false, callId, '', 'GlympseCallout');
        }
    }*/  
}