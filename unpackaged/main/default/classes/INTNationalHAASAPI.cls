public without sharing class INTNationalHAASAPI {
public static Map<String,Integration_Settings__c> mapIntSettings; 
    
    public void prepareHAASalert(List<ServiceAppointment> serviceAppoinments) {
    List<Id> serviceAppoinmentids = new  List<Id>();
         for (ServiceAppointment newSA : serviceAppoinments) {
          if(newSA.isBreakdown__c && (newSA.isCritical__c || newSA.Work_Order_Priority__c == 'Critical'))
             {
                 serviceAppoinmentids.add(newSA.Id);
             }
         }
        if(serviceAppoinmentids.size() > 0)
        {
            createHAASalert(serviceAppoinmentids);
        }
    
    }
    
    public void preapareToDeleteHAASalert(List<ServiceAppointment> serviceAppoinments) {
    List<Id> serviceAppoinmentids = new  List<Id>();
         for (ServiceAppointment newSA : serviceAppoinments) {
        //  if(newSA.isBreakdown__c && newSA.isCritical__c && (newSA.Status == 'In Tow' || newSA.Status == 'Cleared' || newSA.Status == 'Canceled'))
             if(newSA.isBreakdown__c && (newSA.Status == 'In Tow' || newSA.Status == 'Cleared' || newSA.Status == 'Canceled'))
             {
                 serviceAppoinmentids.add(newSA.Id);
             }
         }
        if(serviceAppoinmentids.size() > 0)
        {
           deleteHAASalert(serviceAppoinmentids);
        }
    
    }
    
     @future(callout = true)
    public static void deleteHAASalert(List<Id> serviceAppoinmentids) {
    mapIntSettings = IntegrationUtil.getIntegrationSettings();
        String  accessToken = getAccessTokenFromNational();
         if(accessToken != null){
             for (Id serviceAppId : serviceAppoinmentids)
               {
                  deleteAlert(serviceAppId,accessToken);
               }
    
         }
    }
    
    public static void deleteAlert(Id serviceAptId, String accessToken){
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        if(mapIntSettings.get('DELETEHaas_DeleteAlert_API') != null)
        {
        objRequest = IntegrationUtil.prepareRequest(mapIntSettings.get('DELETEHaas_DeleteAlert_API'));
        objRequest.setHeader('Authorization','Bearer '+ accessToken);
        String endPoint = objRequest.getEndPoint() + '/' + serviceAptId + '?clubCode=240&sourceId=SF';
        objRequest.setEndPoint(endPoint);
        objResponse = IntegrationUtil.makeCallout(objRequest);
         if(objResponse.getStatusCode()==ACG_ConstantsClass.SUCCESS_CODE204){
              // Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
              // Map<string,object> responepayload = (Map<String, Object>)results.get('responsePayload');
               FSL_ApplicationLogCreator.integrationLog('Service Appointment Id:' + serviceAptId ,'Haas Alerts Deleted Successfully','National Call HAAS Delete Alert API','National Delete HAAS Alert',false,'',null);
            } else {
               Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               FSL_ApplicationLogCreator.integrationLog('Service Appointment Id:' + serviceAptId ,objResponse.getBody(),'National Call HAAS Delete Alert API','National Delete HAAS Alert',true,Label.ACG_APIErrorMessage +' : '+objResponse.getStatusCode()+' '+objResponse.getStatus(),null);
            }
      }
    }
    

    @future(callout = true)
    public static void createHAASalert(List<Id> serviceAppoinmentids) {
        mapIntSettings = IntegrationUtil.getIntegrationSettings();
        String  accessToken = getAccessTokenFromNational();
         if(accessToken != null){
          List<ServiceAppointment>  serviceAppoinmentLst =  [Select Id,Address from ServiceAppointment where ID in : serviceAppoinmentids];
             for (ServiceAppointment serviceApp : serviceAppoinmentLst)
                 {
                     NationalCreateHaasJsonRequest jsonWrapper = new NationalCreateHaasJsonRequest();
                     jsonWrapper.type = 'disabled_vehicle';
                     jsonWrapper.clubCode = '240';
                     jsonWrapper.sourceId = 'SF';
                     jsonWrapper.external_id = String.valueof(serviceApp.Id);
                     List<NationalCreateHaasJsonRequest.cls_features> featuresLst = new List<NationalCreateHaasJsonRequest.cls_features>();
                     NationalCreateHaasJsonRequest.cls_features feature = new NationalCreateHaasJsonRequest.cls_features();
                     feature.type = 'point';
                     List<NationalCreateHaasJsonRequest.cls_geometry> geometryLst = new List<NationalCreateHaasJsonRequest.cls_geometry>();
                     NationalCreateHaasJsonRequest.cls_geometry geometry = new NationalCreateHaasJsonRequest.cls_geometry();
                     if(serviceApp != null && serviceApp.Address !=null){ //Vishnu Popuru #07/07/2025 
                        geometry.lat = serviceApp.Address.getLatitude();
                        geometry.lon = serviceApp.Address.getLongitude();
                        geometryLst.add(geometry);
                        jsonWrapper.street_name = serviceApp.Address.getStreet();
                     }
                     
                     feature.geometry = geometryLst;
                     featuresLst.add(feature);
                     jsonWrapper.features = featuresLst; 
                    // jsonWrapper.alert_message = 'Disabled Vehicle Ahead';
                     jsonWrapper.alert_message = 'Disabled Vehicle Ahead';
                     jsonWrapper.accuracy = '3';
                     createAlert(jsonWrapper,accessToken);
                 }
         }
    }
    
    public static void createAlert(NationalCreateHaasJsonRequest jsonWrapper , String accessToken){
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        if(mapIntSettings.get('POSTHaas_CreateAlert_API') != null)
        {
        objRequest = IntegrationUtil.prepareRequest(mapIntSettings.get('POSTHaas_CreateAlert_API'),jsonWrapper,true);
            objRequest.setHeader('Authorization','Bearer '+ accessToken);
            objResponse = IntegrationUtil.makeCallout(objRequest);
            system.debug('HAAS response **' + objResponse.getBody());
            if(objResponse.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_201_SUCCESS){
               Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               Map<string,object> responepayload = (Map<String, Object>)results.get('responsePayload');
               FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Call HAAS Create Alert API','National Create HAAS Alert',false,'',null);
            } else {
               Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Call HAAS Create Alert API','National Create HAAS Alert',true,Label.ACG_APIErrorMessage +' : '+objResponse.getStatusCode()+' '+objResponse.getStatus(),null);
            }
        }
    }
    
     private static String getAccessTokenFromNational(){
       if (Test.isRunningTest()) {
            return '1234';
        }
       HttpRequest  oauthobjRequest = new HttpRequest();
        HttpResponse oauthobjResponse = new HttpResponse();        
        Integration_Settings__c oAuthobjSetting = mapIntSettings.get('POSTNational_OAuth_API');
            String body = oAuthobjSetting.Extra_Header_Value__c;

            oAuthobjSetting.Extra_Header_Value__c = null;
            oauthobjRequest = IntegrationUtil.prepareRequest(oAuthobjSetting);
            oauthobjRequest.setbody(body);
            oauthobjResponse = IntegrationUtil.makeCallout(oauthobjRequest);
    
            if (oauthobjResponse.getStatusCode() == 200) {
                Map<String, Object> mapofObjects = (Map<String, Object>) JSON.deserializeUntyped(oauthobjResponse.getBody());
                
                 return (String) mapofObjects.get('access_token');
                
            }
         else{
            return null;
        }
     
     }
}