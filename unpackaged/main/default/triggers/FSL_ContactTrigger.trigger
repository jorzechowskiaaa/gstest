/**
 * @File Name          : FSL_ContactTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/3/2020, 9:50:14 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
 * 1.2    3/6/2021   Dylan Truong         ERS-221208 - Subtask: ERS-221216  Update Contact trigger to update/create account when membership number updated
**/
trigger FSL_ContactTrigger on Contact (before insert, before update) {
    FSL_TriggerDispatcher.run(new FSL_ContactTriggerHandler());
}