/**
 * @File Name          : FSL_MemberVehicleTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:34:23 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_MemberVehicleTrigger on FSL_Member_Vehicle__c (after update) {
    FSL_TriggerDispatcher.run(new FSL_MemberVehicleTriggerHandler());
}