public class AutoscheduleBatch implements Database.Batchable<sObject>,Database.Stateful
{
    private List<ServiceAppointment> sasToUpdate = new List<ServiceAppointment>();

    public AutoscheduleBatch() {
    }
    
    public Iterable<SObject> start(Database.BatchableContext BC)
    {
        Set<String> validStatuses = new Set<String>{'Spotted'};
        Datetime nowMinusOneHour = System.now().addHours(-1);
        Map<Id, ServiceAppointment> saList = new Map<Id, ServiceAppointment>([SELECT Id, Status, CreatedDate, Subject, ServiceTerritory.Apply_Autoschedule_Retry_Batch__c FROM ServiceAppointment WHERE Status = :validStatuses AND CreatedDate >= :nowMinusOneHour AND Subject = 'Breakdown Appointment' AND ServiceTerritory.Apply_Autoschedule_Retry_Batch__c = TRUE]);
        system.debug('QUERY >> ' + saList.values());
        return saList.values();
    }
    
    public void execute(Database.BatchableContext BC, List<ServiceAppointment> scope) {
        for (ServiceAppointment sa : scope) {
            AutoscheduleUtility.autoschedule(sa.Id, true); //AGB added for SSFI-560 11/19/24
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
}