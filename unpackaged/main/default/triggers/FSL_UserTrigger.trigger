/**
 * @File Name          : FSL_UserTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:03:16 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_UserTrigger on User (after update, before update, after Insert, before Insert) {
    FSL_TriggerDispatcher.run(new FSL_UserTriggerHandler());
}