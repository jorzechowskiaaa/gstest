/**
 * @File Name          : FSL_ETANotificationTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:48:36 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ETANotificationTrigger on ETA_Notification__e (after insert) {
    FSL_TriggerDispatcher.run(new FSL_ETANotificationTriggerHandler());
}