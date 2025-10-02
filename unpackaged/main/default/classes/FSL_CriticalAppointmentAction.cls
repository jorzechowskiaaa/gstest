global class FSL_CriticalAppointmentAction implements FSL.CustomGanttServiceAppointmentAction {

    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        try{
            String reply = '';
            List<String> appointmentNumbers = new List<String>();
            List<ServiceAppointment> saList = [SELECT Id, AppointmentNumber, RecordType.Name, Work_Order__c, Work_Order__r.WorkOrderNumber, Work_Order__r.Priority, FSL__Schedule_over_lower_priority_appointment__c FROM ServiceAppointment WHERE id in :serviceAppointmentsIds OR FSL__Related_Service__c in :serviceAppointmentsIds];
            List<Id> woIds = new List<Id>();
            for(ServiceAppointment sa : saList){
                if(sa.RecordType.Name == 'Breakdown'){
                    woIds.add(sa.Work_Order__c);
                }
            }
            Map<Id, WorkOrder> woMap = new Map<Id,WorkOrder>([SELECT Id, WorkOrderNumber, Priority FROM WorkOrder WHERE Id in :woIds]);
            for(ServiceAppointment sa : saList){
                sa.FSL__Schedule_over_lower_priority_appointment__c = true;
                woMap.get(sa.Work_Order__c).Priority = 'Critical';
                appointmentNumbers.add(sa.AppointmentNumber);
                system.debug('Updating ' + sa.AppointmentNumber + ': Schedule Over Lower Priority - ' + sa.FSL__Schedule_over_lower_priority_appointment__c + ' ; WO' + sa.Work_Order__r.WorkOrderNumber + 'Priority - ' + sa.Work_Order__r.Priority);
            }
            upsert saList;
            upsert woMap.values();
            appointmentNumbers.sort();
            reply = String.join(appointmentNumbers, ', ');
            return 'The following Service Appointments have been escalated to Critical priority and can now be scheduled over lower priority appointments: ' + reply;
        } catch(Exception e){
            system.debug('Exception Caught: ' + e);
            return 'Error processing request: ' + e;
        }
    }
}