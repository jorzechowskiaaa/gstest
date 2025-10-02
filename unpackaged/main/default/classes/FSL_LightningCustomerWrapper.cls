/**
 * @File Name          : FSL_LightningCustomerWrapper.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/14/2020, 1:11:49 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/12/2020   Rajesh Kemisetti     Initial Version
**/
public class FSL_LightningCustomerWrapper { //ERS-229202
    
    //API has defined it as an array
    public list<FSL_LightningMembershipWrapper> memberships {get;set;} 

    //UI needs only single membership data
    @AuraEnabled
    public FSL_LightningMembershipWrapper membership {get;set;}     
    @AuraEnabled
    public FSL_LightningContactWrapper contact {get;set;}
    @AuraEnabled
    public String languagePreference {get;set;} 
    @AuraEnabled
    public List<FSL_CustomPropertiesWrapper> customProperties{get;set;}    
    @AuraEnabled
    public List<FSL_MembershipImpairmentWrapper> impairments{get;set;}    
    @AuraEnabled
    public String statusDescription;
    @AuraEnabled
    public String statusCode;
    //@AuraEnabled
    //public String tranId;
    @AuraEnabled
    public String transactionId;
    @AuraEnabled
    public Foi foi {get;set;}


    public class Foi {
        public string foiType{get;set;}
        public Location location {get;set;}
    }

    public class Location {
        public string latitude {get;set;} 
        public string longitude {get;set;} 
        public Address address {get;set;} 
    }

    public class Address {
        public String addressType {get;set;} 
        public String full {get;set;} 
        public String streetNumber {get;set;} 
        public String street {get;set;}
        public String streetDirection {get;set;} 
        public String line2 {get;set;} 
        public String streetName {get;set;} 
        public String crossStreet {get;set;}
        public String city {get;set;} 
        public String state {get;set;} 
        public String postalCode {get;set;} 
        public String country {get;set;} 
    }
    
}