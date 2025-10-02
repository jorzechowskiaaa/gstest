/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 08-02-2021
 * @last modified by  : Clement Shiu
**/
public class FSL_ServiceAppointmentQueueable {
              
    public class DispatchAppointmentCalls implements Queueable {
        public void execute(QueueableContext context) {       
            // ERS-220594: Added code to Auto Dispatch Ideling Scheduled Appointment Calls in the next 45 min (Appt Dispatch Window)
            FSL_DispatchUtility.dispatchCurrentApptCalls();
        }    
    }
}