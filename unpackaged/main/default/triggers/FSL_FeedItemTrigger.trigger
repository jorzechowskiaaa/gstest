/**
 * @File Name          : FSL_FeedItemTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/29/2020, 1:35:40 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/3/2020   Rajesh Kemisetti     Initial Version
**/
trigger FSL_FeedItemTrigger on FeedItem (after insert, before delete) {
    FSL_TriggerDispatcher.run(new FSL_FeedItemTriggerHandler());
}