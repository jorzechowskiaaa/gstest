public with sharing class FSL_OverrideResourcePrefTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<Override_Resource_Preference__c> newList = Trigger.new;
    List<Override_Resource_Preference__c> oldList = Trigger.old;
    Map<Id, Override_Resource_Preference__c> newMap = (Map<Id, Override_Resource_Preference__c>)Trigger.newMap;
    Map<Id, Override_Resource_Preference__c> oldMap = (Map<Id, Override_Resource_Preference__c>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Override_Resource_Preference__c');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        validatePreferenceEntries(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        validatePreferenceEntries(newList);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    public static void validatePreferenceEntries(List<Override_Resource_Preference__c> newOrps) {
        System.debug('Entering Validate Preference Entries');
        try{
            Map<String, String> errorMessages = FSL_OverrideResourcePrefTriggerHandler.getErrorMessages();
            List<Id> overrideIds = new List<Id>();
            List<Id> resourceIds = new List<Id>();
            for(Override_Resource_Preference__c orp : newOrps){
                overrideIds.add(orp.Scheduling_Override__c);
                resourceIds.add(orp.Service_Resource__c);
            }
            Map<Id, ServiceResource> newOrpResourceMap = new Map<Id, ServiceResource>([SELECT Id, Primary_Service_Territory__c FROM ServiceResource WHERE Id IN :resourceIds]);
            Map<Id, Service_Territory_Scheduling_Override__c> overrideMap = new Map<Id, Service_Territory_Scheduling_Override__c>([SELECT Id, (SELECT Name, Type__c, Service_Territory__c, Service_Resource__c, Service_Resource__r.Primary_Service_Territory__c FROM Override_Resource_Preferences__r) FROM Service_Territory_Scheduling_Override__c WHERE Id IN :overrideIds]);
            for(Override_Resource_Preference__c newOrp : newOrps){
                for(Override_Resource_Preference__c existingOrp : overrideMap.get(newOrp.Scheduling_Override__c).Override_Resource_Preferences__r){
                    if(newOrp.Service_Territory__c != null && existingOrp.Service_Territory__c != null){
                        if(newOrp.Service_Territory__c == existingOrp.Service_Territory__c && newOrp.Id != existingOrp.Id){
                            newOrp.addError(errorMessages.get('Territory-Territory Match'));
                            System.debug('Adding error on ' + newOrp.Name);
                        }
                    } else if(newOrp.Service_Territory__c != null && existingOrp.Service_Territory__c == null && newOrp.Id != existingOrp.Id){
                        if(newOrp.Service_Territory__c == existingOrp.Service_Resource__r.Primary_Service_Territory__c){
                            newOrp.addError(errorMessages.get('Territory-Resource Primary Match'));
                            System.debug('Adding error on ' + newOrp.Name);
                        }
                    } else if(newOrp.Service_Resource__c != null && existingOrp.Service_Resource__c != null && newOrp.Id != existingOrp.Id){
                        if(newOrp.Service_Resource__c == existingOrp.Service_Resource__c){
                            newOrp.addError(errorMessages.get('Resource-Resource Match'));
                            System.debug('Adding error on ' + newOrp.Name);
                        }
                    } else if(newOrp.Service_Resource__c != null && existingOrp.Service_Resource__c == null){
                        if(newOrpResourceMap.get(newOrp.Service_Resource__c).Primary_Service_Territory__c == existingOrp.Service_Territory__c && newOrp.Id != existingOrp.Id){
                            newOrp.addError(errorMessages.get('Resource Primary-Territory Match'));
                            System.debug('Adding error on ' + newOrp.Name);
                        }
                    }
                }
            }
        }catch (Exception e){
            System.debug('Error Caught Validating Override Resource Preferences: ' + e);
            System.debug(e.getStackTraceString());
        }
    }

    public static Map<String, String> getErrorMessages(){
        Map<String, String> errorMessageMap = new Map<String, String>();
        Map<String, String> defaultMessages = new Map<String, String>();
        for(FSL_User_Message__c um : [SELECT Id, Message_Id__c, Message_Text__c FROM FSL_User_Message__c WHERE Reference__c = 'Override Resource Preference']){
            errorMessageMap.put(um.Message_Id__c, um.Message_Text__c);
        }
        defaultMessages.put('Territory-Territory Match', 'The Service Territory matches an existing Territory Preference on the override');
        defaultMessages.put('Territory-Resource Primary Match', 'The Service Territory matches an existing Resource Preference\'s Primary Service Territory on the override');
        defaultMessages.put('Resource-Resource Match', 'The Service Resource matches an existing Resource Preference on the override');
        defaultMessages.put('Resource Primary-Territory Match', 'The Service Resource\'s Primary Service Territory matches an existing Territory Preference on the override');
        
        if(errorMessageMap.size() != 4){
            return defaultMessages;
        } else {
            return errorMessageMap;
        }
    }
}