/**
 * @File Name          : FSL_LocationTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:59:36 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_LocationTrigger on Location (after insert, after update) {
    FSL_TriggerDispatcher.run(new FSL_LocationTriggerHandler());
}