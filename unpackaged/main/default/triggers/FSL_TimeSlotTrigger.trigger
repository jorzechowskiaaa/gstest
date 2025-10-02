/**
 * @File Name          : FSL_TimeSlotTrigger.trigger
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 10/30/2019, 12:10:55 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    10/30/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
trigger FSL_TimeSlotTrigger on TimeSlot (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FSL_TriggerDispatcher.run(new FSL_TimeSlotTriggerHandler());
}