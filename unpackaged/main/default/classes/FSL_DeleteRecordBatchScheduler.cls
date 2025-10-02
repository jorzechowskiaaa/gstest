global class FSL_DeleteRecordBatchScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        list<Record_Removal_Support__mdt> rrsList = [Select DeveloperName from Record_Removal_Support__mdt];
        if(rrsList.isEmpty()==false){
            for(Record_Removal_Support__mdt rrs : rrsList){
                FSL_DeleteRecordBatch b = new FSL_DeleteRecordBatch(rrs.DeveloperName);
                database.executebatch(b);
            }
        }
    }    
    
}