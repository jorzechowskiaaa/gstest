public with sharing class FSL_PurgeSchedule implements Schedulable {
    @testVisible private IFactory scheduleFactory = new Factory();
    @testVisible private Integer configCount = 0;
    @testVisible private Boolean executed = false;

    public void execute( System.SchedulableContext schedulableContext ) {
        executed = true;
        IPurgeScheduleTaskDAO dao = scheduleFactory.createPurgeScheduleDAO();
        List<FSL_Purge_Scheduled_Task__mdt> configs = dao.getActiveScheduledPurgeTasks();
        for( FSL_Purge_Scheduled_Task__mdt config : configs ) {
            configCount++;
            Integer daysToRetain = config.Days_to_retain__c.intValue();
            Integer maxRecords = config.Max_Records__c.intValue();
            switch on config.MasterLabel {
                when 'Application Log Purge' {
                    FSL_PurgeSchedule.purgeApplicationLogs( daysToRetain, maxRecords );
                }
                when 'Optimization Data Purge' {
                    FSL_PurgeSchedule.purgeOptimizationData( daysToRetain, maxRecords );
                }
                when 'Orphan Member Contact Purge' {
                    // Orphan Member Contacts are purged through an iterable, which has a limit of 10000 records.
                    FSL_PurgeSchedule.purgeOrphanMemberContacts( daysToRetain );
                }
                when 'Resource Absence Purge' {
                    FSL_PurgeSchedule.purgeResourceAbsences( daysToRetain, maxRecords );
                }
                when 'Task Purge' {
                    FSL_PurgeSchedule.purgeTasks( daysToRetain, maxRecords );
                }
                when 'Resource Preference Purge' {
                    FSL_PurgeSchedule.purgeResourcePreferences( daysToRetain, maxRecords );
                }
            }
        }
    }

    // Removed the future decorators from the methods below, since these jobs don't need to run in parallel and 
    // the limits of concurrent jobs are being reached by other processes
    private static void purgeApplicationLogs( Integer daysToRetain, Integer maxRecords ) {
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.Factory().createService();
        service.purgeOldRecords( daysToRetain, maxRecords );
    }

    private static void purgeOptimizationData( Integer daysToRetain, Integer maxRecords ) {
        FSL_OptimizationRequest.IOptimizationRequestService service = new FSL_OptimizationRequest.Factory().createService();
        service.purgeOldRecords( daysToRetain, maxRecords );
    }

    private static void purgeOrphanMemberContacts( Integer daysToRetain ) {
        FSL_Contact.IContactService service = new FSL_Contact.Factory().createService();
        service.deleteOrphanMemberContacts( daysToRetain );
    }

    private static void purgeResourceAbsences( Integer daysToRetain, Integer maxRecords ) {
        FSL_ResourceAbsence.IResourceAbsenceService service = new FSL_ResourceAbsence.Factory().createService();
        service.deleteOldResourceAbsences( daysToRetain, maxRecords );
    }

    private static void purgeTasks( Integer daysToRetain, Integer maxRecords ) {
        FSL_Task.ITaskService service = new FSL_Task.Factory().createService();
        service.deleteOldTasks( daysToRetain, maxRecords );
    }

    private static void purgeResourcePreferences( Integer daysToRetain, Integer maxRecords ) {
        FSL_ResourcePreference.IResourcePreferenceService service = new FSL_ResourcePreference.Factory().createService();
        service.deleteOldResourcePreferences( daysToRetain, maxRecords );
    }

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IPurgeScheduleTaskDAO createPurgeScheduleDAO();
    }

    public class Factory implements IFactory {
        public IPurgeScheduleTaskDAO createPurgeScheduleDAO() {
            return new PurgeScheduleTaskDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IPurgeScheduleTaskDAO {
        List<FSL_Purge_Scheduled_Task__mdt> getActiveScheduledPurgeTasks();
    }

    public class PurgeScheduleTaskDAO implements IPurgeScheduleTaskDAO {
        public PurgeScheduleTaskDAO() {
        }

        public List<FSL_Purge_Scheduled_Task__mdt> getActiveScheduledPurgeTasks() {
            Datetime now = Datetime.now();
            return [SELECT Days_to_retain__c, End_Date_Time__c, MasterLabel, Max_Records__c, Start_Date_Time__c 
                    FROM FSL_Purge_Scheduled_Task__mdt 
                    WHERE Start_Date_Time__c <= :now 
                    AND End_Date_Time__c >= :now];
        }
    }
}