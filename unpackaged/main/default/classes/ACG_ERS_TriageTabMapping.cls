/************************************************************************************
Apex Class Name     : ACG_ERS_TriageTabMapping
Created Date        : 31st Aug 2021
Function            : Class to fetch the metadata mapping. 
Author              : Deloitte Consulting 
*************************************************************************************/

public class ACG_ERS_TriageTabMapping {
   
    @AuraEnabled( cacheable=true )  
    public static List < ERS_Triage_Tab_Mapping__mdt > fetchTriageTabMapping() {
        
        return [ SELECT Id, Triage_Tab__c, Service_Type__c,Triage_Tab_Mapping_Status__c,Vehicle_Location_Type__c,Vehicle_Type__c, MasterLabel FROM ERS_Triage_Tab_Mapping__mdt WHERE Triage_Tab_Mapping_Status__c = 'Active' ];
        
    }


}