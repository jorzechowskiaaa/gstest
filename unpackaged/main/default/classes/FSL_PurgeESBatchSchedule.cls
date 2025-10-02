/****
 * *@Name: FSL_PurgeESBatchSchedule.cls
 * *@Description: Class is to Schedule Deleted entity subscription that are past than a week.
 * *@Date: 06/19/2019
 * *@Version: 1.0
 * *@Author: Balaram Naidu.
 * **/
 global class FSL_PurgeESBatchSchedule implements Schedulable {
   global void execute(SchedulableContext SC) {
      FSL_PurgeEntitySubscriptionBatch entitySubBatch = new FSL_PurgeEntitySubscriptionBatch(Label.FSL_Service_Appointment_API_Name,Integer.valueOf(Label.FSL_Purge_Subscription_Batch_Size));
      Database.executeBatch(entitySubBatch);
   }
}