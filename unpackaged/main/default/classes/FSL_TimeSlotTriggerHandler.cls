/****
 * *@Name: FSL_TimeSlotTriggerHandler
 * *@Description: when a timeslot is created/changed, check if the dispatcher is in the territory.
 * *@Date: 10-04-2018
 * *@Version: 1.0
 * *FSL_TimeSlotTriggerHandlerTest
 * **/

public with sharing class FSL_TimeSlotTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<TimeSlot> newList = Trigger.new;
    List<TimeSlot> oldList = Trigger.old;
    Map<Id, TimeSlot> newMap = (Map<Id, TimeSlot>)Trigger.newMap;
    Map<Id, TimeSlot> oldMap = (Map<Id, TimeSlot>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('TimeSlot');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        checkDispatcherOnUpsert(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        FSL_OptimizationHelper.changedOperatingHours(oldMap, newList, 'Insert');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        checkDispatcherOnUpsert(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        FSL_OptimizationHelper.changedOperatingHours(oldMap, newList, 'Update');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeDelete() {
        checkDispatcherOnUpsert(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterDelete() {
            //FSL_OptimizationHelper.changedOperatingHours(null, oldMap.values(),'Delete');
    }

    
    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

    private static void checkDispatcherOnUpsert(List<TimeSlot> newSlots){
        /*try {
            Set<Id> opHourIds = new Set<Id>();
            for (TimeSlot timeSlot : newSlots){
                opHourIds.add(timeSlot.OperatingHoursId);
            }
            List<ServiceTerritoryMember> STMs = [SELECT Id FROM ServiceTerritoryMember WHERE OperatingHoursId IN : opHourIds];
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory WHERE OperatingHoursId IN : opHourIds];
            if (!STMs.isEmpty() && !serviceTerritories.isEmpty()) {
                for (TimeSlot timeSlot : newSlots) {
                    timeSlot.addError('Insufficient Privileges...');
                }
            }

            List<ServiceTerritoryMember> recordAccessLst = [SELECT Id, UserRecordAccess.HasReadAccess,  UserRecordAccess.HasEditAccess FROM ServiceTerritoryMember WHERE Id IN : STMs];

            for (ServiceTerritoryMember stm : recordAccessLst) {
                //if (!stm.UserRecordAccess.HasEditAccess || !(System.Test.isRunningTest())) {
                if (!stm.UserRecordAccess.HasEditAccess && !(System.Test.isRunningTest())) {
                    stm.addError('Insufficient Privileges...');
                }
            }
        } catch (Exception e) {
            System.debug('Exceptioning***'+e.getStackTraceString()+' '+e.getMessage());
        }*/
    }
}