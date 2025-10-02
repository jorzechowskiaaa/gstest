public without sharing class WeatherAdvisoryController {
    @AuraEnabled
    public static String getAdvisoryMessageByService(String service) {
           System.debug('Fetching advisory for service: ' + service);
          if(service != null && service != '') {
            try {
            Winter_Advisory__c[] advisoryByService = [
                    SELECT Advisory_Message_Display__c 
                    FROM Winter_Advisory__c
                    WHERE Service_Type__c =:service
                    AND Active__c = true
                    LIMIT 1
                ];
                if (advisoryByService.size() > 0)
                {
                return advisoryByService[0].Advisory_Message_Display__c ;
                }
            } catch (Exception ex) {
                System.debug('Error fetching advisory message: ' + ex.getMessage());
            }
          }
        return null;
    }

    @AuraEnabled
    public static String getAdvisoryMessage(String state , String city) {
           System.debug('Fetching advisory for state: ' + state);
           System.debug('Fetching advisory for state: ' + city);
        try {
           Winter_Advisory__c[] advisoryByCity = [
                SELECT Advisory_Message_Display__c 
                FROM Winter_Advisory__c
                WHERE State__c  = :state
                AND City__c =:city
                AND Active__c = true
                LIMIT 1
            ];
            if (advisoryByCity.size() > 0)
            {
             return advisoryByCity[0].Advisory_Message_Display__c ;
            }

           else
           {
                // Query Winter_Advisory__c object for active advisories based on state
                Winter_Advisory__c[] advisory = [
                    SELECT Advisory_Message_Display__c 
                    FROM Winter_Advisory__c
                    WHERE State__c  = :state
                    AND City__c = ''
                    AND Active__c = true
                    LIMIT 1
                ];
                
                // Return the advisory message if found
                if (advisory.size() > 0) {
                    return advisory[0].Advisory_Message_Display__c ;
                }
            }
        } catch (Exception ex) {
            System.debug('Error fetching advisory message: ' + ex.getMessage());
        }
        
        // Return null or empty string if no advisory is found or an error occurs
        return null;
    }
}