global with sharing class AutoscheduleRetryHandler implements schedulable {
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AutoscheduleBatch(), 1);
    }
}