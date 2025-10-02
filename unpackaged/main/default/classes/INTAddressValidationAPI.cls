/**** Apex Class Name    :    INTAddressValidationAPI
    * Description        :    This class is used for Address Validation API Callout   
    * Modification Log   :
    * Test Class Name    :    INTAddressValidationAPI_Test
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Saumya Gaur               Sept 28 2021             Created
*********************************************************************************/
public without sharing class INTAddressValidationAPI {
   
    
    /***
    * Method name        : postAddress
    * Description        : POST Address to api
    * Return Type        : INTAddressValidationResponse_Wrapper
    * @Param requestBody : INTAddressValidationRequest_Wrapper 
    */
    @AuraEnabled
    public static INTAddressValidationResponse_Wrapper validateAddress(INTAddressValidationRequest_Wrapper requestbody){
        
         // Get Configuration
    Map<String,Integration_Settings__c> mapIntSettings = 
                                                         IntegrationUtil.getIntegrationSettings();
        
        INTAddressValidationResponse_Wrapper objWrapper=new INTAddressValidationResponse_Wrapper();
        HttpRequest request=new HttpRequest();
        Httpresponse response=new Httpresponse();
        
        try{
            // Get Metadata Configuration
            Integration_Settings__c objSetting = mapIntSettings.get(ACG_ConstantsClass.POST_ADDRESS_VALIDATION_API);
            request = IntegrationUtil.preparerequest(objSetting,requestbody,false);
            request.setHeader(ACG_ConstantsClass.TRAN_ID,IntegrationUtil.generateuniqueId());
            response = IntegrationUtil.makecallout(request);
            if(response.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS) {
                    
                objWrapper = INTAddressValidationResponse_Wrapper.parse(response.getBody());
                objWrapper.statusCode = response.getStatusCode();
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.ADDRESSVALIDATIONAPI,ACG_ConstantsClass.VALIDATEADDRESS,false,response.getStatus(),null);
                }
            else{
                
                objWrapper = INTAddressValidationResponse_Wrapper.parse(response.getBody());
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); 
                objWrapper.statusCode = response.getStatusCode();
                objWrapper.errorMessage = res.containsKey(ACG_ConstantsClass.RESPONSE_HEADERS) ? String.ValueOf(((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(res.get(ACG_ConstantsClass.RESPONSE_HEADERS)))).get(ACG_ConstantsClass.TRAN_STATUS_DESCRIPTION)) : String.ValueOf(res.get(ACG_ConstantsClass.ERROR));
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.ADDRESSVALIDATIONAPI,ACG_ConstantsClass.VALIDATEADDRESS,true,Label.ACG_APIErrorMessage +' : '+response.getStatusCode()+' '+response.getStatus(),null);
            }
        }catch(Exception e){
            String message = e.getStackTraceString();
            objWrapper.statusCode = ACG_ConstantsClass.ERROR_CODE500;
            objWrapper.errorMessage = message;
            FSL_ApplicationLogCreator.integrationLog (request.getEndpoint(),response.getBody(),ACG_ConstantsClass.ADDRESSVALIDATIONAPI,ACG_ConstantsClass.VALIDATEADDRESS,true,message,null);
            
        }
        return objWrapper;
    }
    
}