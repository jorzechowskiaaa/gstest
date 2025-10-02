/***********
*@Name: MultiObjectRecordsCleaningBatch
*@Date: 26-03-2020
*@Description: Class is to cleanup old records data based on the query sending through the constructor.
***********/
global class FSL_PurgeRecordsBatch implements Database.Batchable<sObject>,Schedulable{
    
    global final String Query;
    global final Integer batchSize;

   global FSL_PurgeRecordsBatch(String q,Integer sizeOfBatch){
        this.Query=q;
        this.batchSize = sizeOfBatch;
   }
   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }
   
   global void execute (Database.Batchablecontext BC, list<sObject> scope){
       Database.delete(scope);
   }
    
   global void finish(Database.Batchablecontext BC){
   }
   
   global void execute(SchedulableContext SC) {
       FSL_PurgeRecordsBatch pBatch = new FSL_PurgeRecordsBatch(query,batchSize);
       database.executebatch(pBatch,batchSize);
   }
}