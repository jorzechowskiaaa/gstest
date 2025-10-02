/**
 * @File Name          : FSL_ResourceAbsenceTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:04:12 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ResourceAbsenceTrigger on ResourceAbsence (after delete, after insert,before insert,before update,after update) {
    FSL_TriggerDispatcher.run(new FSL_ResourceAbsenceTriggerHandler());
}