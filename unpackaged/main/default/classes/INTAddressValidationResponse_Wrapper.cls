/**** Apex Class Name:    INTAddressValidationResponse_Wrapper
* Description        :    This class is used to prepare response for address validation api call  
* Modification Log   :
* Test Class Name    :    INTAddressValidationAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Saumya Gaur               Sept 28 2021             Created
*********************************************************************************/
public without sharing class INTAddressValidationResponse_Wrapper {
    
    @AuraEnabled
    public Integer statusCode;
    @AuraEnabled
    public String errorMessage; 
    @AuraEnabled
    public ResponseHeaders responseHeaders;
    
    @AuraEnabled
    public MembershipAddress membershipAddress;

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

    public without sharing class MembershipAddress{
        @AuraEnabled
        public String addressLine1;
        @AuraEnabled
        public String addressLine2;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String zip5;
        @AuraEnabled
        public String zip4;
       
        @AuraEnabled
        public String latitude;
        
        @AuraEnabled
        public String longitude;
        
        @AuraEnabled
        public String censusBlock;
        
        @AuraEnabled
        public String deliveryPointBarcode;
        
        @AuraEnabled
        public String deliveryPoint;
        
        @AuraEnabled
        public String carrierRoute;
        
        @AuraEnabled
        public String stateFIPS;
        @AuraEnabled
        public String countryFIPS;
        @AuraEnabled
        public String censusTract;
    }
    
    
    
    public static INTAddressValidationResponse_Wrapper parse(String json) {
        return (INTAddressValidationResponse_Wrapper) System.JSON.deserialize(json, INTAddressValidationResponse_Wrapper.class);
    }
}