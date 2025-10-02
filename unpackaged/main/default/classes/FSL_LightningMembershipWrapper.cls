public class FSL_LightningMembershipWrapper {

        @AuraEnabled
        public String membershipType {get;set;} 
        @AuraEnabled
        public String sponsor {get;set;} 
        @AuraEnabled
        public String program {get;set;} 
        @AuraEnabled
        public String authorizationCode {get;set;} 
        @AuraEnabled
        public String authorizationLevel {get;set;} 
        @AuraEnabled
        public Boolean isLocalClub {get;set;} 
        //public SystemOrganziation org {get;set;} 
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String originalMemberId {get;set;} 
        @AuraEnabled
        public String expirationDate {get;set;}
        @AuraEnabled
        public String memberLevel {get;set;} 
        @AuraEnabled
        public String memberBirthday {get;set;} 
        @AuraEnabled
        public String memberSince {get;set;} 
        @AuraEnabled
        public String memberStatus {get;set;} 
        @AuraEnabled
        public List<FSL_LightningEntitlementWrapper> entitlements {get;set;}
        @AuraEnabled
        public String goodwill{get;set;}
        @AuraEnabled
        public String programName{get;set;}
        @AuraEnabled
        public String programPhone{get;set;}
        @AuraEnabled
        public String programMaxMileage{get;set;} 
        @AuraEnabled
        public FSL_LightningSystemOrganizationWrapper org{get;set;} 
        @AuraEnabled
        public String cdxMessage{get;set;}
        @AuraEnabled
        public String ersAbuser{get;set;}  
        @AuraEnabled
        public String badCheck{get;set;} 
        @AuraEnabled
        public String motorcycleIndicator{get;set;}     
        
        @AuraEnabled
        public String primaryValid{get;set;}    
        @AuraEnabled
        public String primaryPaid{get;set;}      
        @AuraEnabled
        public String cancelCode{get;set;}     
        @AuraEnabled
        public String cancelType{get;set;}     
        public String inArrears{get;set;}     
        @AuraEnabled
        public String inRenewal{get;set;}     
        @AuraEnabled
        public String totalPastDue{get;set;}    
        @AuraEnabled
        public String totalAmountApplied{get;set;}      
        @AuraEnabled
        public String totalAmountDue{get;set;}     
        @AuraEnabled
        public String renewalExpirationDate{get;set;}     
        public String membershipPaidThroughDate{get;set;}     
        @AuraEnabled
        public String billPlan{get;set;}
        @AuraEnabled
        public String startDate{get;set;} 
        @AuraEnabled
        public String primaryMemberExpirationDate{get;set;}
        @AuraEnabled
        public String primaryMemberStartDate{get;set;}    
        @AuraEnabled
        public String cancellationDate{get;set;}  
        @AuraEnabled
        public String memberSinceDate{get;set;}
    
}