/****
 * *@Name: FSL_PurgeEntitySubscriptionBatch.cls
 * *@Description: Class is to delete past Subscriptions on Entity that we are passing.
 * *@Date: 06/19/2019
 * *@Version: 1.0
 * *@Author: Balaram Naidu.
 * **/
global class FSL_PurgeEntitySubscriptionBatch implements Database.Batchable<sObject> {

   global final String objectAPIName;
   global final Integer noOfDaysPast;
   
   global FSL_PurgeEntitySubscriptionBatch(String objectAPIName, Integer noOfDaysPast) {
       this.objectAPIName = objectAPIName;
       this.noOfDaysPast = noOfDaysPast;
   }
   
   global Database.QueryLocator start(Database.BatchableContext BC){
       String queryString  = 'Select parentId,subscriberId from EntitySubscription where parentId IN (Select Id from '+ objectAPIName+' where createdDate < LAST_N_DAYS:'+noOfDaysPast+' AND Status=\'Cleared\' )';
       return Database.getQueryLocator(queryString);
   }
   
   global void execute(Database.BatchableContext BC, List<sObject> scope){
       List<EntitySubscription> esList = (List<EntitySubscription>)scope;
       delete esList;
   }
   
   global void finish(Database.BatchableContext BC){
   }
}