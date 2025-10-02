/**
 * @File Name          : FSL_CaseTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:29:50 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_CaseTrigger on Case (before insert, after insert, before update, after update) {
    FSL_TriggerDispatcher.run(new FSL_CaseTriggerHandler());
}