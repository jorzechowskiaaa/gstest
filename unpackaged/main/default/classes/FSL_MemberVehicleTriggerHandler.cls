public without sharing class FSL_MemberVehicleTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<FSL_Member_Vehicle__c> newList = Trigger.new;
    List<FSL_Member_Vehicle__c> oldList = Trigger.old;
    Map<Id, FSL_Member_Vehicle__c> newMap = (Map<Id, FSL_Member_Vehicle__c>)Trigger.newMap;
    Map<Id, FSL_Member_Vehicle__c> oldMap = (Map<Id, FSL_Member_Vehicle__c>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FSL_Member_Vehicle__c');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        handleMemberVehicleUpdate();
    }
    

    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    private void handleMemberVehicleUpdate () {
        Boolean colorChanged;
        Boolean modelChanged;
        Boolean makeChanged;
        Boolean yearChanged;
        List<FSL_Member_Vehicle__c> vehiclesWithUpdatedProfiles = new List<FSL_Member_Vehicle__c>();

        for(ID vehID: newMap.keySet()){
            colorChanged = oldMap.get(vehID).Vehicle_Color__c!= newMap.get(vehID).Vehicle_Color__c;
            modelChanged = oldMap.get(vehID).Vehicle_Model__c!= newMap.get(vehID).Vehicle_Model__c;
            yearChanged  = oldMap.get(vehID).Vehicle_Year__c!= newMap.get(vehID).Vehicle_Year__c;
            makeChanged  = oldMap.get(vehID).Vehicle_Make__c!= newMap.get(vehID).Vehicle_Make__c;

            if(colorChanged || modelChanged || makeChanged || yearChanged){
                vehiclesWithUpdatedProfiles.add(newMap.get(vehID));
            }
        }
        if(!vehiclesWithUpdatedProfiles.isEmpty()){
            //FSL_MemberVehicleTriggerHandler.updateWOVehicleProfile(vehiclesWithUpdatedProfiles);
        }
    }
}