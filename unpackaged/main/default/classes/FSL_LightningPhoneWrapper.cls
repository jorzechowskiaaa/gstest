public class FSL_LightningPhoneWrapper {
        @AuraEnabled
        public String phoneType {get;set;} 
        @AuraEnabled
        public String phoneNumber {get;set;} // in json: number
        @AuraEnabled
        public String phoneExtension {get;set;} 
        @AuraEnabled
        public Boolean preferred {get;set;} 
        @AuraEnabled
        public Boolean smsOptIn {get;set;} 
}