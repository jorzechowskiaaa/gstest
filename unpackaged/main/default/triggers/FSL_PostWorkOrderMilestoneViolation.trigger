/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-16-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-16-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger FSL_PostWorkOrderMilestoneViolation on WorkOrder (after update) {


    FSL_TriggerDispatcher.run(new FSL_PostWorkOrderMilestoneViolationTriggerHandler());

    //======================================================================================================================================
    private class FSL_PostWorkOrderMilestoneViolationTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
        
        List<WorkOrder> newList = Trigger.new;
        List<WorkOrder> oldList = Trigger.old;
        Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>)Trigger.newMap;
        Map<Id, WorkOrder> oldMap = (Map<Id, WorkOrder>)Trigger.oldMap;

        //========================================================================================================================
        //========================================================================================================================
        public override Boolean isDisabled() {
            return true; //NOTE: disable since FSL_SLA_Violation.setSAInJeopardy is commented off below
        }


        //========================================================================================================================
        //========================================================================================================================
        public override void afterUpdate() {
            List<Id> woInJeopardyIdList = new  List<Id>();
            for(WorkOrder woNew : newList) {
                for(WorkOrder woOld : oldList) {
                    if(woNew.Id == woOld.Id) {
                        if((woNew.FSL_In_Jeopardy__c != woOld.FSL_In_Jeopardy__c) && woNew.FSL_In_Jeopardy__c == true) {
                            woInJeopardyIdList.add(woNew.Id);
                        }
                    }
                }
            }
            if(!woInJeopardyIdList.isEmpty()){
                //NOTE: if uncommenting the line below make sure to modify isDisabled function appropriately
                //FSL_SLA_Violation.setSAInJeopardy(woInJeopardyIdList);
            }
        
        }


        //========================================================================================================================
        //========================================================================================================================
        //========================================================================================================================

    }
}