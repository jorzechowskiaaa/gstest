@isTest
Public class FSL_OverrideResPrefTriggerHandlerTest{

    static testmethod void OverrideRprefTestScenario1(){
       List<ServiceResource> srlist =[select id,name,Primary_Service_Territory__c from ServiceResource];
      List<Override_Resource_Preference__c> OPref = [select id from Override_Resource_Preference__c];
      //List<Service_Territory_Scheduling_Override__c> STS = [select id from Service_Territory_Scheduling_Override__c];
      opref[0].Service_Territory__c  = srlist[0].Primary_Service_Territory__c;
      opref[0].Service_Resource__c  = null;
      update Opref[0];
        FSL_OverrideResourcePrefTriggerHandler.validatePreferenceEntries(Opref);
    
    }

    static testmethod void OverrideRprefScenario2(){
      List<ServiceResource> srlist =[select id,name,Primary_Service_Territory__c from ServiceResource LIMIT 1];
      List<Override_Resource_Preference__c> OPref = [select id from Override_Resource_Preference__c LIMIT 2];
      List<Override_Resource_Preference__c> exPref = [select id from Override_Resource_Preference__c LIMIT 2];
      List<Service_Territory_Scheduling_Override__c> STS = [select id from Service_Territory_Scheduling_Override__c];
          opref[0].Service_Territory__c  = srlist[0].Primary_Service_Territory__c;
          exPref[0].Service_Territory__c  = null;
          OPref[0].id =  exPref[1].id;
          //update OPref[0];
          FSL_OverrideResourcePrefTriggerHandler.validatePreferenceEntries(Opref);
        
    
    }
    
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   


}