public class FSL_LightningContactWrapper {

        @AuraEnabled
        public String contactType {get;set;} 
        @AuraEnabled
        public String title {get;set;} 
        @AuraEnabled
        public String firstName {get;set;} 
        @AuraEnabled
        public String lastName {get;set;} 
        @AuraEnabled
        public List<FSL_LightningPhoneWrapper> phones {get;set;} 
        @AuraEnabled
        public List<FSL_LightningEmailWrapper> emails {get;set;}     
    
}