/**
 * @File Name          : FSL_OverrideResourcePreferenceTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:56:00 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_OverrideResourcePreferenceTrigger on Override_Resource_Preference__c (before insert, after insert, before update, after update) {
    FSL_TriggerDispatcher.run(new FSL_OverrideResourcePrefTriggerHandler());
}