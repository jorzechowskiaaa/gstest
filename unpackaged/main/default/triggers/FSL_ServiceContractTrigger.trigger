/**
 * @File Name          : FSL_ServiceContractTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 07-23-2022
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_ServiceContractTrigger on ServiceContract (before insert, after insert, after update) {
  FSL_TriggerDispatcher.run(new FSL_ServiceContractTriggerHandler());
}