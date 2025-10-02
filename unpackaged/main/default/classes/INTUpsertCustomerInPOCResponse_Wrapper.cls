/**** Apex Class Name:    INTUpsertCustomerInPOCResponse_Wrapper
* Description        :    This class is used to prepare response for upserting a customer in POC   
* Modification Log   :
* Test Class Name    :    INTUpsertCustomerInPOCAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Oct 04 2021             Created
*********************************************************************************/

public without sharing class INTUpsertCustomerInPOCResponse_Wrapper {
    
    @AuraEnabled
    public Integer statusCode;
    
    @AuraEnabled
    public String errorMessage;
    
    @AuraEnabled
    public ResponseHeaders responseHeaders;
    
    @AuraEnabled
    public Customer customer;
    
    public without sharing class ResponseHeaders{
        
        @AuraEnabled
        public String tranId;
        
        @AuraEnabled
        public String tranCode;
        
        @AuraEnabled
        public String tranStatus;
        
        @AuraEnabled
        public String timeStamp;
        
        @AuraEnabled
        public String tranStatusDescription;
    }
    public without sharing class Customer{
        
        @AuraEnabled
        public String ui;
        
        @AuraEnabled
        public String proxyUi;
        
        @AuraEnabled
        public String hui;
    }
    
    public static INTUpsertCustomerInPOCResponse_Wrapper parse(String json) {
		return (INTUpsertCustomerInPOCResponse_Wrapper) System.JSON.deserialize(json, INTUpsertCustomerInPOCResponse_Wrapper.class);
	}
}