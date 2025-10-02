/**
 * @File Name          : FSL_LightningEntitlementWrapper.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/20/2020, 1:04:43 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/5/2020   Rajesh Kemisetti     Initial Version
**/
public class FSL_LightningEntitlementWrapper {
    @AuraEnabled
    public Boolean serviceChargeIndicator {get;set;} 
    @AuraEnabled
    public Integer associates{get;set;}
    @AuraEnabled
    public Integer chargeableCalls{get;set;}
    @AuraEnabled
    public Integer currentCalls{get;set;} 
    @AuraEnabled
    public Integer callsAllowed{get;set;} 
    @AuraEnabled
    public Integer callsRemaining{get;set;}  
    @AuraEnabled
    public Integer callsUsed{get;set;}
    @AuraEnabled
    public Boolean onlineGarageMember{get;set;}
    @AuraEnabled
    public Boolean longTowAllowed{get;set;}
    @AuraEnabled
    public Integer longTowKilometers{get;set;}
    @AuraEnabled
    public Integer longTowMiles{get;set;}                                    
    @AuraEnabled
    public Integer rentalDays{get;set;}     
    @AuraEnabled
    public Integer specialMemberType{get;set;}      
    @AuraEnabled
    public Boolean homeLockoutEntitled{get;set;}      
    @AuraEnabled
    public Boolean carRentalEntitled{get;set;}      
    @AuraEnabled
    public Boolean sameDayService{get;set;}      
    @AuraEnabled
    public Boolean CAPREeligible{get;set;}      
    @AuraEnabled
    public Boolean RVUsage{get;set;}  
    @AuraEnabled
    public Boolean premierBatteryEntitled{get;set;}     

    
}