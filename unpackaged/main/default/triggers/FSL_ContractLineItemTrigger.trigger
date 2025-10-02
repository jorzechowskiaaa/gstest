/**
 * @File Name          : FSL_ContractLineItemTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 10:37:23 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ContractLineItemTrigger on ContractLineItem (after insert, after update, after delete) {
    FSL_TriggerDispatcher.run(new FSL_ContractLineItemTriggerHandler());
}