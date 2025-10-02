public class ScheduleBatchRAPReadyWorkOrders implements Schedulable {
     
    public void execute(SchedulableContext sc){
        ERS_GrabRAPReadyWorkOrdersBatch batchClass = new ERS_GrabRAPReadyWorkOrdersBatch();
        Database.executeBatch(batchClass, 40);
    }
}