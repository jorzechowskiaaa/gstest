/**
 * Created by divnaidu on 9/10/2019.
 */

public class FSL_MobileNotificationTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
     
    List<Mobile_Notification_Event__e> newList = Trigger.new;
    List<Mobile_Notification_Event__e> oldList = Trigger.old;
    Map<Id, Mobile_Notification_Event__e> newMap = (Map<Id, Mobile_Notification_Event__e>)Trigger.newMap;
    Map<Id, Mobile_Notification_Event__e> oldMap = (Map<Id, Mobile_Notification_Event__e>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Mobile_Notification_Event__e');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        evaluateNotificationAction();
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    private void evaluateNotificationAction() {
        System.debug('!@#$%Entering FSL_MobileNotificationTrigger........' + newList);

        List<Mobile_Notification_Event__e> statusChangePostList = new List<Mobile_Notification_Event__e>();
        List<Mobile_Notification_Event__e> addressChangedEventList = new List<Mobile_Notification_Event__e>();
        List<Mobile_Notification_Event__e> violationEventList = new List<Mobile_Notification_Event__e>(); 
        for(Mobile_Notification_Event__e evt : newList) {
            if(evt.Status_Updated__c) {
                statusChangePostList.add(evt);
            }            
            if(evt.Address_Changed__c) {
                addressChangedEventList.add(evt);
            }
            if(!string.isEmpty(evt.Work_Order_Id__c)){
                violationEventList.add(evt);
            }
        }

        if(!violationEventList.isEmpty()){
            FSL_NotificationFramework.violationsPost(violationEventList);
        }
        if(!statusChangePostList.isEmpty()) {
            FSL_NotificationFramework.statusChangePosts(statusChangePostList);
        }
        if(!addressChangedEventList.isEmpty()) {
            FSL_NotificationFramework.addressChangedPost(addressChangedEventList);
        }

    }

}