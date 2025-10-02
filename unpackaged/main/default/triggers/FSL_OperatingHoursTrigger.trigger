/**
 * @File Name          : FSL_OperatingHoursTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:38:20 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
Trigger FSL_OperatingHoursTrigger on OperatingHours (before update, before delete, after update, after delete, after undelete) {
  FSL_TriggerDispatcher.run(new FSL_OperatingHoursTriggerHandler());
}