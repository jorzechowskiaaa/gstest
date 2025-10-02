public with sharing class ServiceResourceOnlineOfflineController {

    @AuraEnabled(cacheable=true)
    public static /*ServiceResource*/Map<String,String> getServiceResource(String userId)
    {
        System.debug('getServiceResource');
        ServiceResource sr = [SELECT Id,Vehicle__c,Primary_Service_Territory__c,Driver_can_go_Online_Offline__c,Primary_Service_Territory__r.Driver_can_go_Online_Offline__c 
            FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];
        String stId = sr.Primary_Service_Territory__c;

        System.debug(sr.getSobject('Primary_Service_Territory__r'));

        //probably not really needed to break this down like this but did it for debugging an issue
        Map<String,String> result = new Map<String,String>();
        result.put('Id',sr.Id);
        result.put('Vehicle__c',sr.Vehicle__c);
        result.put('Primary_Service_Territory__c',sr.Primary_Service_Territory__c);
        result.put('Driver_can_go_Online_Offline__c',(sr.Driver_can_go_Online_Offline__c == true) ? 'true':'false');

        return result;
    }
    
    @AuraEnabled
    public static String goOnline(String resourceId)
    {
        try {
            //what if no last used vehicle??
            ServiceResource sr = [SELECT Id,Vehicle__c,Vehicle__r.Vehicle_Name__c,FSL__GanttLabel__c,Last_Used_Vehicle__c 
                FROM ServiceResource 
                WHERE Id = :resourceId LIMIT 1];
            sr.Vehicle__c = sr.Last_Used_Vehicle__c;
            update sr;
            return sr.Vehicle__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void goOffline(String resourceId)
    {
        try {
            ServiceResource sr = [SELECT Id,Vehicle__c,FSL__GanttLabel__c,Last_Used_Vehicle__c 
                FROM ServiceResource 
                WHERE Id = :resourceId LIMIT 1];

            sr.FSL__GanttLabel__c = 'DRIVER OFFLINE';
            sr.Last_Used_Vehicle__c = sr.Vehicle__c;
            sr.Vehicle__c = NULL;
            //System.debug(sr);
            update sr;

            List<ServiceResourceSkill> skills = [SELECT Id FROM ServiceResourceSkill 
                WHERE ServiceResourceId = :resourceId AND Skill_DeveloperName__c LIKE 'VEH%'];
            //System.debug(skills);
            delete skills;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}