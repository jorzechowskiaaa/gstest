trigger FSL_StatusChangeNotificationTrigger on Status_Change_Notification__e (after insert) {

    FSL_TriggerDispatcher.run(new FSL_StatusChangeNotificationTriggerHandler());

    //======================================================================================================================================
    private class FSL_StatusChangeNotificationTriggerHandler  extends FSL_TriggerDispatcher.TriggerHandlerBase {
        
        List<Status_Change_Notification__e> newList = Trigger.new;
        List<Status_Change_Notification__e> oldList = Trigger.old;
        Map<Id, Status_Change_Notification__e> newMap = (Map<Id, Status_Change_Notification__e>)Trigger.newMap;
        Map<Id, Status_Change_Notification__e> oldMap = (Map<Id, Status_Change_Notification__e>)Trigger.oldMap;

        //========================================================================================================================
        //========================================================================================================================
        public override Boolean isDisabled() {
            return FSL_TriggerUtility.isDisabled('Status_Change_Notification__e');
        }

        //========================================================================================================================
        //========================================================================================================================
        public override void afterInsert() {
            Map<Id,String>constructMapToFeed = new Map<Id,String>();
            
            map<string, FSL_User_Message__c> referenceMsgIdMap = new map<string, FSL_User_Message__c>();
            for(FSL_User_Message__c usermessage : [SELECT id, Message_Id__c, Message_Text__c, Reference__c 
                                                        FROM FSL_User_Message__c ])
            {
                if(!string.isEmpty(usermessage.reference__c)){
                    referenceMsgIdMap.put(usermessage.reference__c, usermessage);
                }
            }
                
            for(Status_Change_Notification__e event : newList) {
                try
                {
                    if(referenceMsgIdMap.containsKey(event.Status__c)){                
                        constructMapToFeed.put(Id.valueOf(event.Service_Appointment_Id__c), referenceMsgIdMap.get(event.Status__c).Message_Id__c);
                    }             

                
                    if(event.Address_Changed__c) {
                        if(event.Breakdown_Appointment__c) {
                            constructMapToFeed.put(Id.valueOf(event.Service_Appointment_Id__c), 'SM-017');
                        } else if (!event.Breakdown_Appointment__c) {
                            constructMapToFeed.put(Id.valueOf(event.Service_Appointment_Id__c), 'SM-018');               
                        }
                    }

                    if(!constructMapToFeed.isEmpty()) {
                        FSL_ChatterUtilities.postThis(constructMapToFeed);
                    }
            
                }
                catch(Exception e){
                    system.debug(e);
                }
            }
        }


        //========================================================================================================================
        //========================================================================================================================
        //========================================================================================================================
    }
}