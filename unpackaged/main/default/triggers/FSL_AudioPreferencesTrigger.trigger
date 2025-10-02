/**
 * @File Name          : FSL_AudioPreferencesTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/24/2020, 9:42:41 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/24/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_AudioPreferencesTrigger on FSL_Audio_Preferences__c (before insert,after insert,after update) {
    FSL_TriggerDispatcher.run(new FSL_AudioPreferencesTriggerHandler());
}