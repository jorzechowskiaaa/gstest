/**** Apex Class Name:    INTAddressValidationRequest_Wrapper
* Description        :    This class is used to prepare request for address validation api call   
* Modification Log   :
* Test Class Name    :    INTAddressValidationAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Saumya Gaur               Sept 28 2021             Created
*********************************************************************************/
public without sharing class INTAddressValidationRequest_Wrapper {
    
        @AuraEnabled
        public String addressLine1 = '';
        @AuraEnabled
        public String addressLine2 = '';
        @AuraEnabled
        public String city = '';
        @AuraEnabled
        public String state = '';
        @AuraEnabled
        public String zip5 = '';
}