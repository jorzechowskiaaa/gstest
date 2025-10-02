/* Apex Class Name       :    IntegrationUtil
    * Description        :    This class is used to fetch the metadata required for the callouts 
    * Modification Log   :
    * Test Class Name    :    IntegrationUtil
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Aug 2 2021             Created
*********************************************************************************/
public without sharing class IntegrationUtil {

    
    /*
     * Method name            : getAllIntegrationSettings
     * Description            : This method is used to get all integration setting metadata records
     * @return List reference : Returns map of methodname+label, setting records
     * @Param                 : None
    */
     public static Map<String,Integration_Settings__c> getIntegrationSettings(){
    Map<String,Integration_Settings__c> mapIntSettings = new Map<String,Integration_Settings__c>();
    Integer limitRows = Limits.getLimitQueryRows() - Limits.getQueryRows(); 
     
       
    for(Integration_Settings__c objSetting :[SELECT ID, Name,Enpoint_URL__c,Method__c,
                                                  Header_Value__c,Extra_Header_Value__c,Named_Credential__c,Request_Timeout__c, 
                                                  Path__c,API_Key__c,locationbias__c
                                                  FROM Integration_Settings__c LIMIT :limitRows]){  //AGB 4.19.2024 was missing API_Key__c causing issues with INSTSADAGeoMapAPI_Test 
        mapIntSettings.put(objSetting.Method__c+objSetting.Name, objSetting);
    }
    return mapIntSettings;
  }
  
  /*
     * Method name            : getHeaderValue
     * Description            : This method is used to return header values in map
     * @return List reference : Returns map of key,string header values
     * @Param  headerJson     : header in JSON string format
    */
     public static Map<String,String> getHeaderValue(String headerJson){
       Map<String,String> mapHeaderKeyToHeaderValue = new Map<String,String>();
       if(headerJson != null && headerJson != ''){
          List<Object> headerValueResult = (List<Object>)JSON.deserializeUntyped(headerJson); 
          for(Object obj : headerValueResult) { 
              Map<String,Object> mapHeaderKeyToHeaderValueTemp = (Map<String,Object>)obj; 
              mapHeaderKeyToHeaderValue.put((String)mapHeaderKeyToHeaderValueTemp.get('key'),
                                            (String)mapHeaderKeyToHeaderValueTemp.get('value'));
          }
       }
       return mapHeaderKeyToHeaderValue;
    }
    
    /*
     * Method name            : makeCallout
     * Description            : This method is used to make a callout to external systems
     * @return Httpresponse   : Returns the response object
     * @Param request         : sends the Request Object
    */
    public static Httpresponse makeCallout(HttpRequest objRequest){
        Http httpservice = new Http();
        HttpResponse objResponse = new HttpResponse();
        system.debug('FROM IntegrationUtil > objRequest = ' + objRequest);
        try{
            objResponse = httpservice.send(objRequest);
        } catch(Exception e){
            system.debug('ERRORRR >> ' + e.getMessage());
            objResponse.setBody(JSON.serialize(new Map<String, Object>{
                'message' => e.getMessage()
            }));
        }
        system.debug('FROM IntegrationUtil objResponse = ' + objResponse);
        return objResponse;
    }
    
    
    /*
     * Method name            : prepareRequest
     * Description            : This method is used to prepare Http request
     * @return Http request   : Returns request object
     * @Param objSetting      : Integration setting custom metadata records
    */
    public static HttpRequest prepareRequest(Integration_Settings__c objSetting){
        HttpRequest objRequest = new HttpRequest();
        //get header information into a map
        system.debug('obj settings in request ** ' + objSetting);
       system.debug('header value ** ' + objSetting.Header_Value__c);
        Map<String,String> mapHeaderKeyToValue = getHeaderValue(objSetting.Header_Value__c);
        system.debug('Header Value'+mapHeaderKeyToValue);
        objrequest.setMethod(objSetting.Method__c);
        if(objSetting.Enpoint_URL__c!=null){
            objRequest.setEndpoint(objSetting.Enpoint_URL__c);
        }
        if(objSetting.Named_Credential__c!=null){
            objRequest.setEndpoint(objSetting.Named_Credential__c+objSetting.Path__c);
        }
        System.debug('map ****' +mapHeaderKeyToValue);
        for(String key : mapHeaderKeyToValue.keySet()){
            objRequest.setHeader(key,mapHeaderKeyToValue.get(key));
        }
        // if additional header exist
        if(objSetting.Extra_Header_Value__c!=null){
             mapHeaderKeyToValue = getHeaderValue(objSetting.Extra_Header_Value__c);
            for(String key : mapHeaderKeyToValue.keySet()){
                objRequest.setHeader(key,mapHeaderKeyToValue.get(key));
            }
        }
       
        objrequest.setTimeout(Integer.valueof(objSetting.Request_Timeout__c));
        return objRequest;
    }
    
    
     
    /*
     * Method name            : prepareRequest
     * Description            : This method is used to prepare Http request
     * @return List reference : Returns request object
     * @Param objSetting      : Integration setting custom metadata records
     * requestBody            : To set the request body
     * suppressApexObjectNulls: set to true to supress null value
    */
    public static HttpRequest prepareRequest(Integration_Settings__c objSetting,Object requestBody,Boolean suppressApexObjectNulls){
        HttpRequest objRequest = new HttpRequest();
        //get header information into a map
        Map<String,String> mapHeaderKeyToValue = getHeaderValue(objSetting.Header_Value__c);
        objRequest.setMethod(objSetting.Method__c);
        
        for(String key : mapHeaderKeyToValue.keySet()){
            objRequest.setHeader(key,mapHeaderKeyToValue.get(key));
        }
        // if additional header exist
        if(objSetting.Extra_Header_Value__c!=null){
             mapHeaderKeyToValue = getHeaderValue(objSetting.Extra_Header_Value__c);
            for(String key : mapHeaderKeyToValue.keySet()){
                objRequest.setHeader(key,mapHeaderKeyToValue.get(key));
            }
        }
        // set request body if not null
        if(requestBody!=null){
            objRequest.setBody(JSON.serialize(requestBody,suppressApexObjectNulls));
            system.debug('objRequest.setBody ' + objRequest.getBody());
        }
        
        if(objSetting.Enpoint_URL__c!=null){
            objRequest.setEndpoint(objSetting.Enpoint_URL__c);
        }
         // set name credential if exist
        if(objSetting.Named_Credential__c!=null){
             objRequest.setEndpoint(objSetting.Named_Credential__c+objSetting.Path__c);
        }
        objRequest.setTimeout(Integer.valueof(objSetting.Request_Timeout__c));   
        system.debug('IntegrationUtil.prepareRequest Request = ' + objRequest);
        return objRequest;
    }
    /*
     * Method name            : prepareRequest
     * Description            : This method is used to prepare Http request
     * @return List reference : Returns request object
     * @Param objSetting      : Integration setting custom metadata records
     * requestBody            : To set the request body
    */
    public static HttpRequest prepareRequest(Integration_Settings__c objSetting,Object requestBody){
        return preparerequest(objSetting,requestBody,false);
    }
    
    /*
     * Method name            : generateUniqueId
     * Description            : This method is used to generate uniqueID
     * @return String         : Returns UniqueID
     * @Param                 : None
    */
    public static string generateUniqueId(){
        String strRawId = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
        String struuid = strRawId.SubString(0,8)+ '-' + strRawId.SubString(8,12) + 
                         '-' + strRawId.SubString(12,16) + '-' + strRawId.SubString(16,20) + '-' 
                         + strRawId.substring(20); 
        return struuid;
    }
    
    /*
     * Method name            : sendEmail
     * Description            : This method is used to send an email with email template
     * @return String         : None
     * @Param                 : SendEmailRequest_Wrapper
    */
    
    public static void sendEmail(INTSendEmailRequest_Wrapper request){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setToAddresses(request.toAddresses);
        mail.setTemplateID([SELECT Id from EmailTemplate where developername = :request.templateName].Id); 
        mail.setWhatId(request.whatId);
        mail.setTargetObjectId(request.targetObjectId); 
        mail.setTreatTargetObjectAsRecipient(request.treatTargetObjectAsRecipient);
        mail.setSaveAsActivity(request.saveAsActivity);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        
    }
}