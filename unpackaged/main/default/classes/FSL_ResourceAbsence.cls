/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 * * *      07/14/2021   Dylan Truong         ERS-224559 - Map missing Type and Approved to the ResourceAbsence for PlatformEvent Retry
 *          07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log
 */
public with sharing class FSL_ResourceAbsence {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IResourceAbsenceService createService();
    }

    public class Factory implements IFactory {
        public IResourceAbsenceService createService() {
            IResourceAbsenceDAO dao = createDAO();
            return new ResourceAbsenceService( dao );
        }

        private IResourceAbsenceDAO createDAO() {
            return new ResourceAbsenceDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IResourceAbsenceDAO extends FSL_DAO.DmlInterface {
    }

    public class ResourceAbsenceDAO extends FSL_DAO.DmlBase implements IResourceAbsenceDAO {
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IResourceAbsenceService {
        void deleteOldResourceAbsences( Integer daysToRetain, Integer maxRecords );
        void upsertResourceAbsencesByEventMessage (List<sObject> eventMessages);
    }

    public class ResourceAbsenceService implements IResourceAbsenceService {
        private IResourceAbsenceDAO dao;

        public ResourceAbsenceService( IResourceAbsenceDAO dao ) {
            this.dao = dao;
        }

        public void deleteOldResourceAbsences( Integer daysToRetain, Integer maxRecords ) {
            FSL_QueryLocatorBatchable delegate = new FSL_QueryLocatorBatchable( new PurgeOldRecordBatchable( daysToRetain, maxRecords ) );
            Database.executeBatch( delegate );
        }

        public void upsertResourceAbsencesByEventMessage(List<sObject> eventMessages) {
            List<ResourceAbsence> resourceAbsences = createResourceAbsencesForEventMessage(eventMessages);
            Boolean isTestDao = dao instanceOf FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock; // detect if instance is Mock for testable purpose
            if (!resourceAbsences.isEmpty()) {
                if (!isTestDao) {
                    upsert resourceAbsences ResourceAbsence.FSL_Resource_ID__c;  
                    createSuccessfulUpsertAbsenceEventLog(eventMessages);
                } else { 
                    dao.upsertRecords(resourceAbsences); //temporarily test method
                }
            }
        }

        private void createSuccessfulUpsertAbsenceEventLog(List<SObject> eventMessages) {
            List<UpsertResourceAbsenceEventApplicationLog> appLogs = new List<UpsertResourceAbsenceEventApplicationLog>();
            UpsertResourceAbsenceEventApplicationLog appLog = new UpsertResourceAbsenceEventApplicationLog();
            appLog.logSuccessfulUpsertResourceAbsenceFromPlatformEvent(eventMessages);
            appLogs.add(appLog);
            FSL_ApplicationLog.IApplicationLogService appLogService = (new FSL_ApplicationLog.Factory()).createService();
            appLogService.saveApplicationLogs(appLogs);
        }

        private List<ResourceAbsence> createResourceAbsencesForEventMessage(List<sObject> eventMessages) {
            List<ResourceAbsence> resourceAbsences = new  List<ResourceAbsence> ();
            for(Resource_Absence_Event__e eventMessage : (List<Resource_Absence_Event__e>)eventMessages) {
                resourceAbsences.add(new ResourceAbsence(FSL__GanttLabel__c = eventMessage.Gantt_Label__c, ResourceId = eventMessage.Resource_Absense_Id__c, 
                                                            FSL_Resource_ID__c = eventMessage.Resource_Absense_Id__c, Longitude = eventMessage.Longtitude__c, 
                                                            Latitude = eventMessage.Latitude__c, RecordTypeId = eventMessage.Record_Type_Id__c, 
                                                            Start = eventMessage.Start_Time__c, End=eventMessage.End_Time__c, Type= eventMessage.Type__c,FSL__Approved__c = eventMessage.Approved__c));
            }
            return resourceAbsences;
        }
    }
  
    // *********************************************
    // * Batchable Implementation
    // *********************************************
    private class PurgeOldRecordBatchable implements FSL_QueryLocatorBatchable.IBatchable {
        private Integer daysToRetain;
        private Integer maxRecords;

        public PurgeOldRecordBatchable( Integer daysToRetain, Integer maxRecords ) {
            this.daysToRetain = daysToRetain;
            this.maxRecords = maxRecords;
        }

        public Database.QueryLocator start( Database.BatchableContext context ) {
            Date createdDate = System.now().dateGMT().addDays( -daysToRetain );
            return Database.getQueryLocator(
                [SELECT Id, CreatedDate, FSL__GanttLabel__c
                FROM ResourceAbsence
                WHERE FSL__GanttLabel__c = 'LKL'
                AND CreatedDate < :createdDate
                ORDER BY CreatedDate 
                LIMIT :maxRecords] );
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            if( items.size() > 0 ) {
                delete items;
            }
        }
    
        public void finish( Database.BatchableContext context ) {
        }
    }

    public class UpsertResourceAbsenceEventApplicationLog extends FSL_ResourceAbsenceEvent.LKLUpsertResourceAbsencePlatformEventLog {
        public UpsertResourceAbsenceEventApplicationLog () {
            super();
        }

        public void logSuccessfulUpsertResourceAbsenceFromPlatformEvent(List<SObject> eventMessages) {
            String message = 'Resource Absenses successfully upserted from platform event !'  + '\r\n';
            message +=  eventMessages.toString();
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message  + '\r\n';
            appLog.Success_Record_Count__c = eventMessages.size();
            appLog.Total_Record_Count__c = eventMessages.size();
        }

    }

}