public class FSL_AudioPreferencesTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<FSL_Audio_Preferences__c> newList = Trigger.new;
    List<FSL_Audio_Preferences__c> oldList = Trigger.old;
    Map<Id, FSL_Audio_Preferences__c> newMap = (Map<Id, FSL_Audio_Preferences__c>)Trigger.newMap;
    Map<Id, FSL_Audio_Preferences__c> oldMap = (Map<Id, FSL_Audio_Preferences__c>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FSL_Audio_Preferences__c');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        checkForDuplicateRecords(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        createUserShareRecords(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        createAndDeleteUserShareRecords(newList, newMap, oldMap);
    }

    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================
  
    public static void checkForDuplicateRecords(List<FSL_Audio_Preferences__c> newAudioPerList) {
        Set<Id> userIdSet = new Set<Id>();
        Map<Id,FSL_Audio_Preferences__c> userIdAudPrefRecMap = new Map<Id,FSL_Audio_Preferences__c>();
        for(FSL_Audio_Preferences__c audPref : newAudioPerList) {
            userIdSet.add(audPref.User__c);
        }
        if(!userIdSet.isEmpty()) {
            for(FSL_Audio_Preferences__c audPref : [Select id,User__c from FSL_Audio_Preferences__c where User__c IN : userIdSet]) {
                userIdAudPrefRecMap.put(audPref.User__c,audPref);
            }
            for(FSL_Audio_Preferences__c audPref : newAudioPerList) {
                if(userIdAudPrefRecMap.get(audPref.User__c) != null) {
                    audPref.addError('Duplicate Record found with the same user :'+userIdAudPrefRecMap.get(audPref.User__c).Id);
                }
            }
        }
    }

    public static void createAndDeleteUserShareRecords(List<FSL_Audio_Preferences__c> newAudioPerList,Map<Id,FSL_Audio_Preferences__c> newMap,Map<Id,FSL_Audio_Preferences__c> oldMap) {
        Set<Id> oldUserIdSet = new Set<Id>();
        Set<Id> audPrefIdSet = new Set<Id>();
        List<FSL_Audio_Preferences__Share> audShareList = new List<FSL_Audio_Preferences__Share>();
        for(FSL_Audio_Preferences__c audPref : newAudioPerList) {
            if(audPref.User__c != oldMap.get(audPref.Id).User__c && audPref.User__c != UserInfo.getUserId()) {
                audPrefIdSet.add(audPref.Id);
                oldUserIdSet.add(oldMap.get(audPref.Id).User__c);
                FSL_Audio_Preferences__Share audShare = new FSL_Audio_Preferences__Share();
                audShare.UserOrGroupId = audPref.User__c;
                audShare.ParentId = audPref.Id;
                audShare.AccessLevel = 'edit';
                audShareList.add(audShare);
            }
        }
        if(!oldUserIdSet.isEmpty()) {
            delete [Select Id from FSL_Audio_Preferences__Share where UserOrGroupId IN :oldUserIdSet AND parentId IN : audPrefIdSet AND UserOrGroupId !=: UserInfo.getUserId()];
        }
        if(!audShareList.isEmpty()) {
            insert audShareList;
        }
    }
    public static void createUserShareRecords(List<FSL_Audio_Preferences__c> newAudioPerList) {
        List<FSL_Audio_Preferences__Share> audShareList = new List<FSL_Audio_Preferences__Share>();
        for(FSL_Audio_Preferences__c audPref : newAudioPerList) {
            if(audPref.User__c != UserInfo.getUserId()) {
                FSL_Audio_Preferences__Share audShare = new FSL_Audio_Preferences__Share();
                audShare.UserOrGroupId = audPref.User__c;
                audShare.ParentId = audPref.Id;
                audShare.AccessLevel = 'edit';
                audShareList.add(audShare);
            }
        }
        if(!audShareList.isEmpty()) {
            insert audShareList;
        }
    }
}