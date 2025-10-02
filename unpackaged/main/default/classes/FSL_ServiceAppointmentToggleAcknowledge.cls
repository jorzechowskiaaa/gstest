global class FSL_ServiceAppointmentToggleAcknowledge implements FSL.CustomGanttServiceAppointmentAction {

    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        Boolean status;
        List<ServiceAppointment> saList = [SELECT Id, Acknowledge__c, AppointmentNumber FROM ServiceAppointment WHERE Id in : serviceAppointmentsIds];
        String reply = '';
        List<String> saNames = new List<String>();
        for (ServiceAppointment s : saList) {
            s.Acknowledge__c = !s.Acknowledge__c;
            saNames.add(s.AppointmentNumber);
            Status = s.Acknowledge__c;
        }
        upsert saList;
        reply = String.join(saNames, ', ');
        If (Status == True){
            return 'The following Service Appointments (and Related Service, if applicable) have been acknowledged: ' + reply;
        } else {
            return 'The following Service Appintments (and Related Service, if applicable) have been removed from the acknowledged list: ' + reply;
        }
    }
}