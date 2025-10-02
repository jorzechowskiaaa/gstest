/**
 * @File Name          : FSL_MobileNotificationTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:01:01 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_MobileNotificationTrigger on Mobile_Notification_Event__e (after insert) {
    FSL_TriggerDispatcher.run(new FSL_MobileNotificationTriggerHandler());

}