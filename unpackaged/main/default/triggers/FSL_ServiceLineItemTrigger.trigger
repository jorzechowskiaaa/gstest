/**
 * @File Name          : FSL_ServiceLineItemTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:12:13 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ServiceLineItemTrigger on FSL_Service_Line_Item__c (before insert, after insert, before update) {
    FSL_TriggerDispatcher.run(new FSL_ServiceLineItemTriggerHandler());   
}