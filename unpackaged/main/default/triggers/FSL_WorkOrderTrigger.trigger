/**
 * @File Name          : FSL_WorkOrderTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 11-16-2023
 * @Modification Log   : 
 * Ver    Date            Author                        Modification
 * 1.0    4/3/2020        Rajesh Kemisetti              Initial Version
 * 1.1    11/16/2023      Josh Tupas                    Populated 'Parsed_Created_Time__c' field on creation of WO
 *                                                      to help generate TOD codes
**/
trigger FSL_WorkOrderTrigger on WorkOrder (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
   if (Trigger.isInsert && Trigger.isBefore) {
       for(WorkOrder wo : Trigger.new) {
           DateTime timeNow = DateTime.now();
           wo.Parsed_Created_Time__c = String.valueOf(timeNow.time());
           if(wo.isClone()){
               wo.ClonedParent__c = wo.getCloneSourceId();
           }
       }    
    }
    FSL_TriggerDispatcher.run(new FSL_WorkOrderTriggerHandler());
}