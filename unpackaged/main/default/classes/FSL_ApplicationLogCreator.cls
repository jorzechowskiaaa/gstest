/**
 * @File Name          : FSL_ApplicationLogCreator.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 10-18-2022
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/7/2020   Rajesh Kemisetti     Initial Version
 *      12/03/2020   Clement Shiu         ERS-220518 - Introduce RAP GAP changes into ACE Org
 *      04/22/2021   Clement Shiu         ERS-222543 - Routing Change to log it only if the Feature Flag is enabled in MDT
 * 2.0  5/14/2020    Dylan Truong         ERS-221083 MembershipValidation Phrase 2: Partial Search : Modify insertMemberValidationAppLog
 *      5/18/28020   Khanh Tran           ERS-223145 Enhance Service Scheduler to add logging instrumentation
**/
public class FSL_ApplicationLogCreator {
    
    public static DateTime inputProcessStartTime;
    public static DateTime inputProcessEndTime;
    
    public static DateTime serviceStartTime;
    public static DateTime serviceEndTime;
    
    public static DateTime outputProcessStartTime;
    public static DateTime outputProcessEndTime;
    
    public static string maskPIIData(string input){    	
        string reg_Ex ;
        string pii_Variables;
        try{
            for(FSL_PII_Setting__mdt PIISetting : [select DeveloperName, value__c from FSL_PII_Setting__mdt]){
                if('REGEX'.equalsignorecase(PIISetting.DeveloperName)){
                    reg_Ex = PIISetting.Value__c;
                }else if('PII_Variables'.equalsignorecase(PIISetting.DeveloperName)){
                    pii_Variables = PIISetting.Value__c;
                }
            }
            if(input != null && !string.isEmpty(reg_Ex) && !string.isEmpty(pii_Variables)){    		
                list<string> piiVariables = pii_Variables.split(',');				
                for(string variable : piiVariables){
                    String rg = reg_Ex.replace('Variable', variable);
                    String rg1 = reg_Ex.replace('Variable', variable);
                    string replace = '\"' + variable + '\" : \"' + '*****\"';
                    input = input.replaceAll(rg, replace);				
                }
            }  
        }catch(exception ex){
            system.debug('Exception:'+ex.GetMessage()+ ' '+ex.getStackTraceString());
        }  	
    	system.debug('Data after masking PII:' + input);    	
    	return input;
    }

    public static long getProcessTime(DateTime startTime, DateTime endTime){
        long processTime;
        if(startTime != null && endTime != null){
            processTime = endTime.getTime() - startTime.getTime();
        }
        return processTime;
    }
    
    /**
    *This method is to create application log when callout happend.
    */
    public static void insertAplicationLog(RestRequest req, FSL_WorkOrderResponse res, String message,String operation,Boolean isError,String callId,String version,WorkOrder wo) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        Integer reqLength = req.requestBody.toString().length() < 32000 ?  req.requestBody.toString().length() : 32000;
        Integer resLength = res.toString().length() < 32000 ? res.toString().length() : 32000;
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = req.requestBody.toString();
        if( requestBody.length() > 0 ) apLog.Request_Body__c = maskPIIData(requestBody.substring(0,reqLength - 1));
        apLog.Response_Body__c = JSON.serialize(res);//.substring(0, resLength - 1);
        apLog.Call_Id__c = callId;
        apLog.API_Name__c = 'Create Workorder API';
        apLog.Call_Version__c = version;
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        apLog.Error_Caught__c = isError;
        apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        if(wo != null) {
            apLog.Work_Order__c = wo.Id;
        }
        insert apLog;
    }
    
    /**
    *   Overloaded method for accepting strings for request and FSL.ScheduleResult for response
    */
    public static FSL_Application_Log__c createScheduleServiceLog(String req, FSL.ScheduleResult res, String message,String operation,Boolean isError,String callId,String version, ID saID) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        apLog.DateTime__c = System.now();
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.Operation__c = operation;
        if (req != null || String.isNotBlank(req)) {
            Integer reqLength = req.length() < 32000 ? req.length() : 32000;
            if( reqLength > 0 ) apLog.Request_Body__c = maskPIIData(req.substring(0, reqLength - 1));
        }
        if(res != null){
            Integer resLength = res.toString().length() < 32000 ? res.toString().length() : 32000;
            apLog.Response_Body__c = res.toString().substring(0, resLength - 1);
            apLog.Error_Caught__c = false;
        }else{
            apLog.Response_Body__c = 'Error scheduling';
            apLog.Error_Caught__c = true;
        }
        apLog.Call_Id__c = callId;
        apLog.Call_Version__c = version;
        apLog.API_Name__c = 'Schedule API Call';
        apLog.Service_Appointment__c = saID;
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        
        apLog.InputProcessingTime__c = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        return apLog;
    }
    
/**
    *   Overloaded method for creating logs without inserting them
    */
    public static FSL_Application_Log__c createLogReferenceWithoutInsert(String req, HttpResponse res, String message,String operation,Boolean isError,String callId,String version, ID saID, String apiName) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        Integer reqLength = req.length() < 32000 ? req.length() : 32000;
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;
        if( reqLength > 0 ) apLog.Request_Body__c = maskPIIData(req.substring(0, reqLength - 1) );
        if(res != null && res.getStatusCode() == 200){
            Integer resLength = res.getBody().length() < 32000 ? res.getBody().length() : 32000;
            apLog.Response_Body__c = res.getBody().substring(0, resLength - 1);
            apLog.Error_Caught__c = false;
        }else{
            apLog.Response_Body__c = 'Error';
            apLog.Error_Caught__c = true;
        }
        apLog.Call_Id__c = callId;
        apLog.Call_Version__c = version;
        apLog.API_Name__c = apiName;
        apLog.Service_Appointment__c = saID;
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        
        //apLog.InputProcessingTime__c = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        //apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        //apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        return apLog;
    }      

    public class CalloutLoggerData {
        public String apiName;
        public String operation;
        public String version;
        public Boolean isError;
        public String message;
        public String callId;
        public String calloutRequest;
        public String calloutResponse;
        public Double outputProcessingTime;
        public Double serviceTime;
        public ID serviceAppointmentId;
        public ID workOrderId;
    }

    public static void calloutLogger(CalloutLoggerData data) {
        calloutLogger(data.calloutRequest, data.calloutResponse, data.message, data.operation, data.isError, data.callId, data.version, data.apiName, data.outputProcessingTime, data.serviceTime, data.serviceAppointmentId, data.workOrderId);
    }

    public static void calloutLogger(String calloutRequest, String calloutResponse, String message, String operation, Boolean isError, String callId, String version, String APIName) {
        calloutLogger(calloutRequest, calloutResponse, message, operation, isError, callId, version, APIName, null, null, null, null);
    }

    public static void calloutLogger(String calloutRequest, String calloutResponse, String message, String operation, Boolean isError, String callId, String version, String APIName, Double outputProcessingTime, Double serviceTime, Id serviceAppointmentId, Id workOrderId) {
        insert calloutLoggerValue(calloutRequest, calloutResponse, message, operation, isError, callId, version, APIName, outputProcessingTime, serviceTime, serviceAppointmentId, workOrderId);
    }

    private static FSL_Application_Log__c calloutLoggerValue(String calloutRequest, String calloutResponse, String message, String operation, Boolean isError, String callId, String version, String APIName, Double outputProcessingTime, Double serviceTime, Id serviceAppointmentId, Id workOrderId) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        if (String.isNotBlank(calloutRequest)) {
            Integer reqLength = calloutRequest.length() < 32000 ? calloutRequest.length() : 32000;
            if( reqLength > 0 ) apLog.Request_Body__c = maskPIIData(calloutRequest.substring(0,reqLength));
        }
        if (String.isNotBlank(calloutResponse)) {
            Integer resLength = calloutResponse.length() < 32000 ? calloutResponse.length() : 32000;
            apLog.Response_Body__c = calloutResponse.substring(0,resLength);
        }
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;

        if (callId !=null ) { 
            if(callId.contains(',')){
                apLog.Call_Id__c = callId.split(',')[0];
                apLog.Transaction_ID__c = callId.split(',')[1];
            }

            else if (callId !=null && callId.startsWith('08p') && (callId.length() <= 18 || callId.length() >= 15 ) ){
                apLog.Service_Appointment__c = Id.valueOf(callId);
            }
	    }

        if(apLog.Service_Appointment__c == null)
            apLog.Service_Appointment__c = serviceAppointmentId;

        apLog.Work_Order__c = workOrderId;

        apLog.Call_Id__c = callId;
        apLog.Call_Version__c = version;
        apLog.API_Name__c = APIName;
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        apLog.Error_Caught__c = isError;
        
        apLog.InputProcessingTime__c = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c = serviceTime != null ? serviceTime : getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c = outputProcessingTime != null ? outputProcessingTime : getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        return apLog;
    }
    
    public static void callInLogger(String callinRequest, String callinResponse, String message, String operation, Boolean isError, String callId, String version, String APIName) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        if (callinRequest != null || String.isNotBlank(callinRequest)) {
            Integer reqLength = callinRequest.length() < 32000 ? callinRequest.length() : 32000;
            if( reqLength > 0 ) apLog.Request_Body__c = maskPIIData(callinRequest.substring(0,reqLength - 1));
        }
        if (callinResponse != null || String.isNotBlank(callinResponse)) {
            Integer resLength = callinResponse.length() < 32000 ? callinResponse.length() : 32000;
            apLog.Response_Body__c = callinResponse.substring(0,resLength - 1);
        }
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;
        if(callId.contains(',')){
            apLog.Call_Id__c = callId.split(',')[0];
            apLog.Transaction_ID__c = callId.split(',')[1];
        }
        if (callId !=null && callId.startsWith('08p') && (callId.length() <= 18 || callId.length() >= 15 ) ){
             apLog.Service_Appointment__c = Id.valueOf(callId);
        }    
        apLog.Call_Id__c      = callId;
        apLog.Call_Version__c = version;
        apLog.API_Name__c     = APIName;
        if(isError){
            apLog.Error_Message__c      = message;
        }
        else{
            apLog.Success_Message__c    = message;
        }
        apLog.Error_Caught__c           = isError;
        
        apLog.InputProcessingTime__c    = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c            = getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c   = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        insert apLog;
    }
 
    public static void callInGlympseLogger(String callinRequest, String response, String message, Boolean isError, String callId, String taskId, string apiName, string serviceApptId) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        if (callinRequest != null || String.isNotBlank(callinRequest)) {
            Integer reqLength = callinRequest.length() < 32000 ? callinRequest.length() : 32000;
            if( reqLength > 0 ) apLog.Request_Body__c = maskPIIData(callinRequest.substring(0,reqLength - 1));
        }
        if (response != null || String.isNotBlank(response)) {
            Integer resLength = response.length() < 32000 ? response.length() : 32000;
            if( resLength > 0 ) apLog.Response_Body__c = response.substring(0,resLength - 1);
        }
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.DateTime__c = System.now();
        apLog.Operation__c = 'GlympseIn';
        if(callId.contains(',')){
            apLog.Call_Id__c            = callId.split(',')[0];
            apLog.Transaction_ID__c     = callId.split(',')[1];
        }
        apLog.Call_Id__c                = callId;
        apLog.Task_id__c           = taskId;
        apLog.API_Name__c               = apiName;//'GlympseStatus';
        apLog.Service_Appointment__c = serviceApptId;
        if(isError){
            apLog.Error_Message__c      = message;
        }
        else{
            apLog.Success_Message__c    = message;
        }
        apLog.Error_Caught__c           = isError;
        
        apLog.InputProcessingTime__c    = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c            = getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c   = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        insert apLog;
    }

    public static void schedulingLogger(String operation, String message, Boolean isError) {
        FSL_Application_Log__c apLog    = new FSL_Application_Log__c();
        apLog.DateTime__c               = System.now();
        apLog.Operation__c              = operation;
        if(isError){
            apLog.Error_Message__c      = message;
        }
        else{
            apLog.Success_Message__c    = message;
        }
        apLog.Error_Caught__c           = isError;
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.InputProcessingTime__c    = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c            = getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c   = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        
        insert apLog;
    }
       
    public static void routingLogger(List<AssignedResource> insertedARs) {
        List<FSL_Application_Log__c> apLogs = new List<FSL_Application_Log__c>();
        id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        for (AssignedResource ar : insertedARs) {

            FSL_Application_Log__c apLog  = new FSL_Application_Log__c(Call_Id__c = ar.ServiceAppointment.D3_Call_ID__c,
                                                           Service_Appointment__c = ar.ServiceAppointmentId);
            apLog.DateTime__c             = System.now();
            apLog.Operation__c            = 'RoutingChange';
            apLog.API_Name__c             = 'Starting '+ar.FSL__Estimated_Travel_Time_To_Source__c;
            apLog.Success_Message__c      = 'InitialRouting:'+'FromSource:'+ar.FSL__Estimated_Travel_Time_From_Source__c+
                                                            'ToSource:'+ar.FSL__Estimated_Travel_Time_To_Source__c;

            apLog.InputProcessingTime__c  = getProcessTime(inputProcessStartTime, inputProcessEndTime);
            apLog.ServiceTime__c          = getProcessTime(serviceStartTime, serviceEndTime);
            apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
            apLog.RecordTypeId = generalRecordTypeId;
            apLogs.add(apLog);
        }
        try{
            System.debug('apLogs-------'+apLogs);
            insert apLogs;
        }
        catch (DmlException e) {
            System.debug('routingLogger::'+e.getMessage());
        }
    }

    // ERS-222543 - Routing Change to log it only if the Feature Flag is enabled in MDT
    public static void routingLogger(List<AssignedResource> updatedOldARs, Map<Id, AssignedResource> updatedARNewMap, FSL_ApplicationLog.IApplicationLogService service) {
        
        List<FSL_Application_Log__c> apLogs = new List<FSL_Application_Log__c>();       
        Boolean isRoutingChangeLoggingEnabled = service.isRoutingChangeLoggingEnabled();

        if(isRoutingChangeLoggingEnabled) {
            id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
            for (AssignedResource ar : updatedOldARs) {
                String updatedValue = 'Changed '+ Schema.getGlobalDescribe().get('AssignedResource').getDescribe().fields.getMap().get('EstimatedTravelTime').getDescribe().getLabel() +
                                      ' from ' + ar.EstimatedTravelTime+' To '+ updatedARNewMap.get(ar.Id).EstimatedTravelTime+
                                      ' and '+Schema.getGlobalDescribe().get('AssignedResource').getDescribe().fields.getMap().get('FSL__Estimated_Travel_Time_To_Source__c').getDescribe().getLabel()+' from '+ar.FSL__Estimated_Travel_Time_To_Source__c+
                                      ' to '+ updatedARNewMap.get(ar.Id).FSL__Estimated_Travel_Time_To_Source__c;
    
                FSL_Application_Log__c apLog  = new FSL_Application_Log__c(Call_Id__c = ar.ServiceAppointment.D3_Call_ID__c,
                                                               Service_Appointment__c = ar.ServiceAppointmentId);
                apLog.DateTime__c             = System.now();
                apLog.Operation__c            = 'RoutingChange';
                apLog.API_Name__c             = updatedARNewMap.get(ar.Id).FSL__Estimated_Travel_Time_To_Source__c;
                if(!updatedARNewMap.get(ar.Id).FSL__Estimated_Travel_Time_To_Source__c.containsIgnoreCase('SLR')){
                    apLog.Error_Caught__c     = true;
                    apLog.Error_Message__c    = updatedValue;
                }
                else{
                    apLog.Error_Caught__c     = false;
                    apLog.Success_Message__c  = updatedValue;
                }
                apLog.InputProcessingTime__c  = getProcessTime(inputProcessStartTime, inputProcessEndTime);
                apLog.ServiceTime__c          = getProcessTime(serviceStartTime, serviceEndTime);
                apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
                apLog.RecordTypeId = generalRecordTypeId;
                apLogs.add(apLog);
            }
            try{
                insert apLogs;
            }
            catch (Exception e) {
                System.debug('routingLogger::MissingPicklistValue');
            }
        }        
    }

    public static void addressLogger(List<ServiceAppointment> updatedOldSAs, Map<Id, ServiceAppointment> updatedSANewMap) {
        List<FSL_Application_Log__c> apLogs = new List<FSL_Application_Log__c>();
        id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        for (ServiceAppointment sa : updatedOldSAs) {
            String updatedValue = 'OldAddress:' + String.valueOf(sa.Address) + '\n'+
                                  'NewAddress:' + String.valueOf(updatedSANewMap.get(sa.Id).Address);

            FSL_Application_Log__c apLog  = new FSL_Application_Log__c(Call_Id__c = sa.D3_Call_ID__c, Service_Appointment__c = sa.Id);
            apLog.DateTime__c             = System.now();
            apLog.Operation__c            = 'AddressChange';
            apLog.Success_Message__c      = updatedValue;
            apLog.InputProcessingTime__c  = getProcessTime(inputProcessStartTime, inputProcessEndTime);
            apLog.ServiceTime__c          = getProcessTime(serviceStartTime, serviceEndTime);
            apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
            apLog.RecordTypeId = generalRecordTypeId;
            apLogs.add(apLog);
        }
        try{
            insert apLogs;
        }
        catch (Exception e) {
            System.debug('addressLogger::MissingPicklistValue');
        }
    }

    public static map<ETA_Notification__e, Id> createPlatFormEventLogger(List<ETA_Notification__e> notificationList, Map<ETA_Notification__e, ServiceAppointment> platformEventToSAMap, map<ETA_Notification__e, List<String>> mapEventToterritoryIdList, map<ETA_Notification__e,ID> mapEventToRSOResourceIDs, map<ETA_Notification__e, FSL_ETANotificationTriggerHandler.Wrapper> mapEventToChange) {
        List<FSL_Application_Log__c> appLogList = new List<FSL_Application_Log__c>();
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        map<ETA_Notification__e, Id> mapEventToLogId = new map<ETA_Notification__e, Id>();
        try{
            list<string> listTerrIds = new list<string>();            
            for(ETA_Notification__e etaRec : notificationList) {
                if(mapEventToterritoryIdList!=null && !mapEventToterritoryIdList.isEmpty() && mapEventToterritoryIdList.containsKey(etaRec)) {
                    listTerrIds.addAll(mapEventToterritoryIdList.get(etaRec));
                }
            }
            map<id, ServiceTerritory> mapSTs ;
            if(!listTerrIds.isEmpty()){
                mapSTs = new map<id, ServiceTerritory>([select name from ServiceTerritory where id in :listTerrIds]);
            }
            //createPELogs(appLogList, notificationList);
            list<ETA_Notification__e> eventsInContext = new list<ETA_Notification__e>();
            //The input will either have value for mapEventToterritoryIdList or mapEventToRSOResourceIDs and not both
            If(mapEventToRSOResourceIDs==null && mapEventToterritoryIdList!=null){
                eventsInContext.addAll(mapEventToterritoryIdList.keyset());
            }else if(mapEventToterritoryIdList == null && mapEventToRSOResourceIDs !=null){
                eventsInContext.addAll(mapEventToRSOResourceIDs.keyset());
            }else if(mapEventToterritoryIdList == null && mapEventToRSOResourceIDs ==null){
                eventsInContext.addAll(notificationList);
            }
            for(ETA_Notification__e etaRec : eventsInContext) {
                FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'ETALog');
                id PlatformEventId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('Platform Event').getRecordTypeId();
                if(platformEventToSAMap.containsKey(etaRec)){
                    appLog.Service_Appointment__c = platformEventToSAMap.get(etaRec).Id;
                    appLog.Service_Resource__c = platformEventToSAMap.get(etaRec).Service_Resource__c;
                }else{
                    appLog.Service_Resource__c = etaRec.Service_Resource_Id__c;
                }
                appLog.RecordTypeId           = PlatformEventId;
                appLog.Api_Name__c            = etaRec.Type__c;
                
                ETAWrapper etawrap = new ETAWrapper();
                etawrap.etanotification=etaRec;
                etawrap.ServiceResourceStackedCalls = mapEventToChange.containsKey(etaRec) ? mapEventToChange.get(etaRec).StackedCalls : null; 
                
                appLog.Platform_Event_Data__c = JSON.serializePretty(etawrap);
                appLog.Optimization_Setting__c= JSON.serializePretty(oSettings);
                appLog.DateTime__c            = System.now();
                if(mapEventToterritoryIdList!=null && !mapEventToterritoryIdList.isEmpty() && mapEventToterritoryIdList.containsKey(etaRec)) {
                    list<string> terrNames = new list<string>();
                    for(string terrId : mapEventToterritoryIdList.get(etaRec)){
                        terrNames.add(mapSTs.get(terrId).name);
                    }
                    appLog.Service_Territory__c = JSON.serializepretty(terrNames);
                }
    
                appLogList.add(appLog);
            }
            insert appLogList;

            
            for(Integer i=0; i<appLogList.size(); i++){
                mapEventToLogId.put(eventsInContext[i], appLogList[i].id);
            }
        }catch(exception ex){
            system.debug('exception:'+ex.getMessage()+' '+ex.getStackTraceString());
        }
        return mapEventToLogId;
    }

    public static void IVRLookupLogger(String request, String response, Boolean isError, String bulkCallIds, String APIName, String successMsg, String errorMsg) {
        List<FSL_Application_Log__c> apLogs = new List<FSL_Application_Log__c>();
        FSL_Application_Log__c apLog  = new FSL_Application_Log__c(Call_Id__c = bulkCallIds, Operation__c = 'IVRLookup',
                                                                    API_Name__c = APIName, Error_Caught__c = isError,
                                                                    Success_Message__c = successMsg, Error_Message__c = errorMsg,
                                                                    Request_Body__c = maskPIIData(request), Response_Body__c = response);
        apLog.DateTime__c             = System.now();
        apLog.InputProcessingTime__c  = getProcessTime(inputProcessStartTime, inputProcessEndTime);
        apLog.ServiceTime__c          = getProcessTime(serviceStartTime, serviceEndTime);
        apLog.OutputProcessingTime__c = getProcessTime(outputProcessStartTime, outputProcessEndTime);
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLogs.add(apLog);
        try{
            insert apLogs;
        }
        catch (Exception e) {
            System.debug('IVRLookupLogger::MissingPicklistValue');
        }
    }

    public class ETAWrapper{
        public ETA_Notification__e etanotification {get;set;} 
        public integer ServiceResourceStackedCalls {get;set;} 
     }
     
     public static void insertMemberValidationAppLog(HttpRequest req, HttpResponse res, String apiName,Boolean isError,String message,String woId) {
        
        try{
            FSL_Application_Log__c apLog = new FSL_Application_Log__c();
            apLog.DateTime__c = System.now();
            apLog.Operation__c = 'ValidateMembership';
            apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
            apLog.Request_Body__c = req != null ? maskPIIData(req.getBody()): 'Exception Occured';
            apLog.Response_Body__c = res != null ? maskPIIData(res.getBody()): 'Exception Occured';
            apLog.API_Name__c = apiName;
            if(isError){
                apLog.Error_Message__c = message;
            }
            else{
                apLog.Success_Message__c = message;
            }
            apLog.Error_Caught__c = isError;            
            apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
            if(woId != null) {
                apLog.Work_Order__c = woId;
            }
            insert apLog;
        }catch(exception ex){
            system.debug('Error while creating log: '+ex.getMessage()+ ' '+ex.getStackTraceString());
        }
    }

    public static void SaveMemberDataAppLog(String apiName,Boolean isError,String message,String woId) {
        
        try{
            FSL_Application_Log__c apLog = new FSL_Application_Log__c();
            apLog.DateTime__c = System.now();
            apLog.Operation__c = 'ValidateMembership';
            apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
            apLog.API_Name__c = apiName;
            if(isError){
                apLog.Error_Message__c = message;
            }
            else{
                apLog.Success_Message__c = message;
            }
            apLog.Error_Caught__c = isError;
            
            if(woId != null) {
                apLog.Work_Order__c = woId;
            }
            insert apLog;
        }catch(exception ex){
            system.debug('Error while creating log: '+ex.getMessage()+ ' '+ex.getStackTraceString());
        }
    }

    
    /*** ERS-229371
    * Method name            : insertWorkOrderClearPlatformEventLog
    * Description            : Workorder clear Log Method 
    * Return Type            : null
    */
    public static void insertWorkOrderClearPlatformEventLog(Map<Id, WorkOrder_Clear__e> woIdToClearEventMap, Boolean isError, String message){

        List<FSL_Application_Log__c> ListApplicationLog = new List<FSL_Application_Log__c>();
        
        for(Id WOId : woIdToClearEventMap.keyset() ){        
            WorkOrder_Clear__e WoClear = woIdToClearEventMap.get(WOId);
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'WOSClearLog');
            Id PlatformEventId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('Platform Event').getRecordTypeId();
            //system.debug('Platform Event WO Clear Map during App Log Insert = ' + woIdToClearEventMap);
            appLog.Work_Order__c = WOId;   
            appLog.Api_Name__c= 'WorkOrder Clear Event' ;
            appLog.Platform_Event_Data__c = JSON.serialize(WoClear);
            appLog.RecordTypeId   = PlatformEventId;
            appLog.Error_Caught__c = isError;
            if(isError){                
                appLog.Error_Message__c = message;
            }
            else{
                appLog.Success_Message__c = message;
            }
            ListApplicationLog.add(appLog);
        }
            
        if(ListApplicationLog.size() > 0){
            insert ListApplicationLog;
        }                
    }

    public static void insertWorkOrderStatusUpdatePlatformEventLog(Map<Id, WorkOrder_StatusUpdate__e> platformEventToWOMap){
        List<FSL_Application_Log__c> LstApplicationLog = new List<FSL_Application_Log__c>();
        for(Id WOId: platformEventToWOMap.keySet()){        
            WorkOrder_StatusUpdate__e WoStatus = platformEventToWOMap.get(WOId);
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'WOStatusUpdateLog');
             id PlatformEventId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByDeveloperName().get('Platform_Event').getRecordTypeId();
                //appLog.Service_Appointment__c = SaId;
                system.debug('Platform Event Map during App Log Insert = ' + platformEventToWOMap);
                // if(platformEventToWOMap.get(WoStatus) != null){ 
                     //appLog.Service_Appointment__c = platformEventToSAMap.get(WoStatus).Id;   
                     //appLog.Service_Resource__c = platformEventToSAMap.get(WoStatus).Service_Resource__c;
                     appLog.Work_Order__c = WOId;
                //  }
                 appLog.Api_Name__c= 'WorkOrder StatusUpdate Event' ;
                 appLog.Platform_Event_Data__c = JSON.serialize(WoStatus);
                 appLog.RecordTypeId   = PlatformEventId;
                 LstApplicationLog.add(appLog);
            }
            
        if(!LstApplicationLog.isEmpty()){
            insert LstApplicationLog;
        }                
    }

    public static void insertWorkOrderCreationEventLog(Map<Id, WorkOrder_Creation_Event__e> workOrderToEventMap){
        List<FSL_Application_Log__c> listApplicationLog = new List<FSL_Application_Log__c>();
        
        for(Id WOId : workOrderToEventMap.keySet()){   
            WorkOrder_Creation_Event__e creationEvent = workOrderToEventMap.get(WOId);
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'WOCreateEventLog');
             id PlatformEventId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByDeveloperName().get('Platform_Event').getRecordTypeId();
           
            appLog.Api_Name__c= 'WorkOrder_Creation_Event';
            appLog.Platform_Event_Data__c = JSON.serialize(creationEvent); 
            appLog.RecordTypeId           = PlatformEventId;
            appLog.Work_Order__c = WOId;
            //appLog.Work_Order__c = WoId;            
            listApplicationLog.add(appLog);
        }

        if(!listApplicationLog.isEmpty()){
            insert listApplicationLog;                    
        }
    }
    
    
    public static void insertStatusTrackingEventLog(Map<Id, ServiceAppointment> saIdToSaMap, Map<Id, Service_Tracking__e> SaIdToEventMap){
        List<FSL_Application_Log__c> listApplicationLog = new List<FSL_Application_Log__c>();
        for(Id SaId : SaIdToEventMap.keySet()){        
            Service_Tracking__e SerTrack = SaIdToEventMap.get(SaId);
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'ServiceTrackingLog');
             id PlatformEventId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByDeveloperName().get('Platform_Event').getRecordTypeId();
            //  if(SaToEventMap.containsKey(SerTrack)){ 
              appLog.Service_Appointment__c = SaId; 
              appLog.Service_Resource__c = saIdToSaMap.get(SaId).Service_Resource__c;
            //   }
              
              appLog.Api_Name__c= 'Service Tracking Event';
              appLog.Platform_Event_Data__c = JSON.serialize(SerTrack); 
              appLog.RecordTypeId           = PlatformEventId;
                   
             listApplicationLog.add(appLog);
        }

        if(!listApplicationLog.isEmpty()){
            insert listApplicationLog;                    
        }
    
    }    
    /***
    * Method name            : integrationLog
    * Description            : Generic Integration Log Method 
    * Return Type            : null
    * @Param request         : Request body or param
    * @Param response        : Response body or param
    * @Param apiName         : Api name of integration
    * @Param operation       : Method name in the api
    * @Param isError         : mark true if it's error
    * @Param message         : success or error message with class and method name
    * @Param woId            : workorder id in case of workorder integration or null
    */
    public static void integrationLog(String request, String response, String apiName,String operation,Boolean isError,String message,String woId) {
        
        try{
            FSL_Application_Log__c apLog = new FSL_Application_Log__c();
            apLog.DateTime__c = System.now();
            apLog.Operation__c = operation;
            apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
            apLog.Request_Body__c = maskPIIData(request);
            apLog.Response_Body__c = maskPIIData(response);
            apLog.API_Name__c = apiName;
            if(isError){
                apLog.Error_Message__c = message;
            }
            else{
                apLog.Success_Message__c = message;
            }
            apLog.Error_Caught__c = isError;            
            apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
            if(woId != null) {
                apLog.Work_Order__c = woId;
            }
            insert apLog;
        }catch(exception ex){
            system.debug('Error while creating log: '+ex.getMessage()+ ' '+ex.getStackTraceString());
        }
    }

    /*This method has been added as part of DialX component*/
    public static void insertAplicationLogGeneric(String calloutRequest, String calloutResponse, String message,String operation,Boolean isError,
                                                  String callId, Id wo, String apiName, Id saID) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        if (String.isNotBlank(calloutRequest)) {
            Integer reqLength = calloutRequest.length() < 32000 ? calloutRequest.length() : 32000;
            apLog.Request_Body__c = maskPIIData(calloutRequest.substring(0,reqLength - 1));
        }
        if (String.isNotBlank(calloutResponse)) {
            Integer resLength = calloutResponse.length() < 32000 ? calloutResponse.length() : 32000;
            apLog.Response_Body__c = calloutResponse.substring(0,resLength - 1);
        }
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        apLog.Call_Id__c = callId;
        apLog.API_Name__c = apiName;
        if(saID != null) {
            apLog.Service_Appointment__c = saID;
        }
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        apLog.Error_Caught__c = isError;
        //apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        if(wo != null) {
            apLog.Work_Order__c = wo;
        }
        insert apLog;
    }

    public static void insertApplicationLogEvent(HttpRequest req, HttpResponse res, String apiName, Boolean isError, String message) {
        insertApplicationLogEvent(req?.getBody(), res?.getBody(), apiName, isError, message);
    }

    public static void insertApplicationLogEvent(string reqBody, string responseBody, String apiName, Boolean isError, String message) {

        Application_Log_Event__e appLogEvent = new Application_Log_Event__e();
        appLogEvent.API_Name__c = apiName;
        appLogEvent.Error_Caught__c = isError;
        appLogEvent.Message__c = message;
        appLogEvent.Request_Body__c = maskPIIData(reqBody);
        appLogEvent.Response_Body__c = maskPIIData(responseBody);

        List<Application_Log_Event__e> eventMessages = new List<Application_Log_Event__e>();
        eventMessages.add(appLogEvent);
        EventBus.publish(eventMessages);
    }

    
    /**
    *This method is to create application log when callout happend.
    */
    public static void insertAppLogForUpdate(RestRequest req, FSL_WorkOrderResponse res, String message,String operation,Boolean isError,String callId,String version,WorkOrder wo) {
        FSL_Application_Log__c apLog = new FSL_Application_Log__c();
        Integer reqLength = req.requestBody.toString().length() < 32000 ?  req.requestBody.toString().length() : 32000;
        Integer resLength = res.toString().length() < 32000 ? res.toString().length() : 32000;
        apLog.DateTime__c = System.now();
        apLog.Operation__c = operation;
        apLog.RecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        String requestBody = req.requestBody.toString();
        if( requestBody.length() > 0 ) apLog.Request_Body__c = maskPIIData(requestBody.substring(0,reqLength - 1));
        apLog.Response_Body__c = JSON.serialize(res);//.substring(0, resLength - 1);
        apLog.Call_Id__c = callId;
        apLog.API_Name__c = 'D3Request';
        apLog.Call_Version__c = version;
        if(isError){
            apLog.Error_Message__c = message;
        }
        else{
            apLog.Success_Message__c = message;
        }
        apLog.Error_Caught__c = isError;
        apLog.ServiceTime__c = getProcessTime(serviceStartTime, serviceEndTime);
        if(wo != null) {
            apLog.Work_Order__c = wo.Id;
        }
        insert apLog;
    }
}