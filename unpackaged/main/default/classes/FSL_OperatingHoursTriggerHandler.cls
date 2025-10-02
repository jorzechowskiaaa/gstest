/****
 * *@Name: FSL_OperatingHoursTriggerHandler 
 * *@Description: when an operatingHours is created/changed, check if the dispatcher is in the territory.
 * *@Date: 10-04-2018
 * *@Version: 1.0
 * *FSL_TimeSlotTriggerHandlerTest
 * **/
public with sharing class FSL_OperatingHoursTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<OperatingHours> newList = Trigger.new;
    List<OperatingHours> oldList = Trigger.old;
    Map<Id, OperatingHours> newMap = (Map<Id, OperatingHours>)Trigger.newMap;
    Map<Id, OperatingHours> oldMap = (Map<Id, OperatingHours>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('OperatingHours');
    }


    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        checkDispatcherOnUpsert(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        checkDispatcherOnUpsert(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeDelete() {
        checkDispatcherOnUpsert(newList);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

    private static void checkDispatcherOnUpsert(List<OperatingHours> newOHList) {
        try {
            List<ServiceTerritoryMember> stMembersList = [SELECT Id FROM ServiceTerritoryMember WHERE OperatingHoursId IN :newOHList];
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory WHERE OperatingHoursId IN :newOHList];

            if (stMembersList.isEmpty() && serviceTerritories.isEmpty()) {
                for (OperatingHours oHour : newOHList) {
                    oHour.addError('Insufficient Privileges....');
                }
            }
        } catch (Exception e) {
            System.debug('Insufficient Privileges....' + e.getMessage());
        }
    }
}