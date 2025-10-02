/**
 *  Queueable class for automatically scheduling calls that originate from an external service
 */
public class FSL_AppointmentScheduleQueueable implements Queueable, Database.AllowsCallouts {

    private FSL_ServiceScheduler scheduler;
    
    public FSL_AppointmentScheduleQueueable(FSL_ServiceScheduler.DTO dto) {
        scheduler = new FSL_ServiceScheduler(dto);
    }
    
    public FSL_AppointmentScheduleQueueable(FSL_ServiceScheduler sched) {
        scheduler = sched;
    }

    public void execute(QueueableContext context) {
        if(test.isRunningTest() == false) {
            if(scheduler.scheduleCall() != FSL_ServiceScheduler.FinalStatus.STAT_DONE)
                System.enqueueJob(this);
        }
        else {
            do {
            } while (scheduler.scheduleCall() != FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        }
    }
                    
                       
}