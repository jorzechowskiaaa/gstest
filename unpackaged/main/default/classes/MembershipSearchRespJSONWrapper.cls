/**** Apex Class Name    :    MembershipSearchRespJSONWrapper
    * Description        :    This  is wrapper class for  for Membership Search API  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Aug 12 2021             Created
*********************************************************************************/
public class MembershipSearchRespJSONWrapper {
    public class MembershipSearchResponse {
        @AuraEnabled
        public List<Members> members;

    }
    public ResponseHeaders responseHeaders;
    public MembershipSearchResponse MembershipSearchResponse;
    
    public class ResponseHeaders {
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
    
    public class Members {
        
        @AuraEnabled
        public String membershipNumber; 
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String adressLine1;
        @AuraEnabled
        public string addressLine2;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String membershipStatus;
        @AuraEnabled
        public String birthDate;
        @AuraEnabled
        public String expirationDate;
        @AuraEnabled
        public String membershipType;
        @AuraEnabled
        public String phoneNumber;
        @AuraEnabled
        public String emailAddress;
    }

    
    public static MembershipSearchRespJSONWrapper parse(String json) {
        return (MembershipSearchRespJSONWrapper) System.JSON.deserialize(json, MembershipSearchRespJSONWrapper.class);
    }
}