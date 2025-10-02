/**** Apex Class Name    :    INTUpsertCustomerInPOCAPI
    * Description        :    This class is used to upsert customers in POC system   
    * Modification Log   :
    * Test Class Name    :    INTUpsertCustomerInPOCAPI_Test
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla           Oct 04 2021             Created
*********************************************************************************/

public without sharing class INTUpsertCustomerInPOCAPI {
    
    
    /*
     * Method name            : upsertCustomer
     * Description            : This method is used to upsert a customer in POC system
     * @return Object         : returns the upserted customer response wrapper 
    */
    @AuraEnabled
    public static INTUpsertCustomerInPOCResponse_Wrapper upsertCustomer(INTUpsertCustomerInPOCRequest_Wrapper cusreq){

        // Get Configuration
    Map<String,Integration_Settings__c> mapIntSettings = 
                                                         IntegrationUtil.getIntegrationSettings();
        
        INTUpsertCustomerInPOCResponse_Wrapper objWrapper=new INTUpsertCustomerInPOCResponse_Wrapper();
        HttpRequest request=new HttpRequest();
        Httpresponse response=new Httpresponse();
        
        try{
            
            Integration_Settings__c objSetting=mapIntSettings.get(ACG_ConstantsClass.POST_UPSERT_CUSTOMER_POC_API);
            request = IntegrationUtil.preparerequest(objSetting,cusreq,true);
            request.setHeader(ACG_ConstantsClass.TRAN_ID,IntegrationUtil.generateuniqueId());
            response = IntegrationUtil.makecallout(request);
            if(response.getStatusCode()== ACG_ConstantsClass.STATUS_CODE_SUCCESS) {
                
                objWrapper = INTUpsertCustomerInPOCResponse_Wrapper.parse(response.getBody());
                objWrapper.statusCode = response.getStatusCode();
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.UPSERTCUSTOMERAPI,ACG_ConstantsClass.UPSERTCUSTOMER,false,response.getStatus(),null);
            }
            else{
                
                objWrapper = INTUpsertCustomerInPOCResponse_Wrapper.parse(response.getBody());
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); 
                objWrapper.statusCode = response.getStatusCode();
                objWrapper.errorMessage = res.containsKey(ACG_ConstantsClass.RESPONSE_HEADERS) ? String.ValueOf(((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(res.get(ACG_ConstantsClass.RESPONSE_HEADERS)))).get(ACG_ConstantsClass.TRAN_STATUS_DESCRIPTION)) : String.ValueOf(res.get(ACG_ConstantsClass.ERROR));
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.UPSERTCUSTOMERAPI,ACG_ConstantsClass.UPSERTCUSTOMER,true,Label.ACG_APIErrorMessage +' : '+response.getStatusCode()+' '+response.getStatus(),null);
            }
        }catch(Exception e){
            
            String message = e.getStackTraceString();
            objWrapper.statusCode = ACG_ConstantsClass.ERROR_CODE500;
            objWrapper.errorMessage = message;
            FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                      ACG_ConstantsClass.UPSERTCUSTOMERAPI,ACG_ConstantsClass.UPSERTCUSTOMER,true,message,null);    
        }
        return objWrapper;
    }
            
}