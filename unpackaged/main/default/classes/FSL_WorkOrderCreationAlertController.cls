public with sharing class  FSL_WorkOrderCreationAlertController {
    
    @AuraEnabled
    public static Map<String,Integer> checkForAudioEnablement(Integer intervalInSec, Integer previousTotalCount, Integer previousCancelledCount) {
        Map<String,Integer> responseMap = new Map<String,Integer>();        
        Boolean swapTerritory = false;
        List<Id> territoryIdSet = new List<Id>();
        Map<Id,Integer> territoryIdCountMap = new Map<Id,Integer>();
        Map<Id,Integer> cancelledCountMap = new Map<Id,Integer>();
       /*List<FSL_Facility_Calls_Count__c> fccToBeInsertList = new List<FSL_Facility_Calls_Count__c>();
        List<FSL_Facility_Calls_Count__c> fccToBeUpdateList = new List<FSL_Facility_Calls_Count__c>();
        Map<Id,FSL_Facility_Calls_Count__c> territoryIdFaCountMap = new Map<Id,FSL_Facility_Calls_Count__c>();*/
        /*List<FSL__User_Territory__c> userTerrList = [Select Id,FSL__ServiceTerritory__c,FSL__User__c from FSL__User_Territory__c where FSL__User__c =: UserInfo.getUserId() ];
        for(FSL__User_Territory__c ut : userTerrList) {
            territoryIdSet.add(ut.FSL__ServiceTerritory__c);
        }*/
        System.debug('territoryIdSet====>'+territoryIdSet);
        DateTime currentTime = System.now();
        DateTime prevInterval = currentTime.addSeconds((intervalInSec*(-1)));
        List<WorkOrder> woList = [Select Id from WorkOrder where (NOT status IN ('Canceled','Cleared') )];
        List<WorkOrder> canceledWoList = [Select Id from WorkOrder where status='Canceled' And LastModifiedById !=: UserInfo.getUserId() ];
        
        if(woList.size() != previousTotalCount && woList.size() > previousTotalCount) {
            responseMap.put('totalCallCount', woList.size());
            responseMap.put('isTotalCountChanged', 1);
        }else {
            responseMap.put('totalCallCount', woList.size());
            responseMap.put('isTotalCountChanged', 0);
        }
        if(canceledWoList.size() != previousCancelledCount) {
            responseMap.put('cancelledCallCount', canceledWoList.size());
            responseMap.put('isCancelCountChanged', 1);
        }else {
            responseMap.put('cancelledCallCount', canceledWoList.size());
            responseMap.put('isCancelCountChanged', 0);
        }
        return responseMap;
    }
    
    @AuraEnabled
    public static Map<String,String> checkUserPreferences() {
      // query preferences object based on logged-in user
        Map<String,String> userPreferenceMap = new Map<String,String>();
        List<FSL_Audio_Preferences__c> usList = [Select Id,Notification_on_Cancellation__c,Notifications_on_New_Call__c,Time_Interval_In_Seconds__c from FSL_Audio_Preferences__c where User__c =: UserInfo.getUserId()];
        if(usList.isEmpty() || (!usList[0].Notification_on_Cancellation__c && !usList[0].Notifications_on_New_Call__c)){
            userPreferenceMap.put('enableAudioAlerts',String.valueOf(false));
        }else{
            /*List<Id> territoryIdSet = new List<Id>();
            List<FSL__User_Territory__c> userTerrList = [Select Id,FSL__ServiceTerritory__c,FSL__User__c from FSL__User_Territory__c where FSL__User__c =: UserInfo.getUserId() ];
            for(FSL__User_Territory__c ut : userTerrList) {
                territoryIdSet.add(ut.FSL__ServiceTerritory__c);
            }*/
            userPreferenceMap.put('enableAudioAlerts',String.valueOf(true));
            userPreferenceMap.put('enableCancellationAlerts',String.valueOf(usList[0].Notification_on_Cancellation__c));
            userPreferenceMap.put('enableNewCallAlerts',String.valueOf(usList[0].Notifications_on_New_Call__c));
            userPreferenceMap.put('pollInterval',String.valueOf(usList[0].Time_Interval_In_Seconds__c));
            //userPreferenceMap.put('',);
            // ERS-228437 -TK
            //List<WorkOrder> woList = [Select Id from WorkOrder where (NOT status IN ('Canceled','Cleared') AND  CreatedDate = LAST_N_DAYS:5)];
            List<WorkOrder> woList = fetchAllReadOnlyWorkOrdersNotCanceledOrCleared(5);
            List<WorkOrder> canceledWoList = [Select Id from WorkOrder where status='Canceled' ];
            userPreferenceMap.put('activeCallCount',String.valueOf(woList.size()));
            userPreferenceMap.put('cancelledCallCount',String.valueOf(canceledWoList.size()));
        }
      // return map that assigns if preferences enabled true/false 
      // along with notifications for new calls and cancellations
      return userPreferenceMap;      
    }

    @AuraEnabled
    public static  List<WorkOrder> fetchAllReadOnlyWorkOrdersNotCanceledOrCleared(Integer days) {    
               
        Date startDate = Date.today().addDays(-Integer.valueOf(days));     

        List<WorkOrder> woList = [Select Id from WorkOrder where ((NOT status IN ('Canceled','Cleared')) AND  (CreatedDate >= :startDate))];         
        
        return  woList;
    }

    
}