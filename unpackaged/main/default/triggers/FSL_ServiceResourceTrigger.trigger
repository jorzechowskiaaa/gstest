/**
 * @File Name          : FSL_ServiceResourceTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:05:45 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ServiceResourceTrigger on ServiceResource (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    FSL_TriggerDispatcher.run(new FSL_ServiceResourceTriggerHandler());
 }