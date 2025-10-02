/**
 * @File Name          : FSL_OptimizationRequestTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:45:34 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_OptimizationRequestTrigger on FSL__Optimization_Request__c (after update, after delete) {
    FSL_TriggerDispatcher.run(new FSL_OptimizationRequestTriggerHandler());
}