/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 *  *       07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log
 */

public with sharing class FSL_ResourceAbsenceEvent {
    public Enum ExceptionType {
        ROW_LOCK_EXCEPTION_TYPE, EMPTY
    }
    public Enum LogType {
        RETRY_LOG, PROCESS_LOG, EXCEPTION_LOG, RETRY_EXCEED_LIMIT
    }

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IResourceAbsenceEventService createService();
    }

    public class Factory implements IFactory {

        public IResourceAbsenceEventService createService() {
            IResourceAbsenceEventDAO dao = createDAO();
            return new ResourceAbsenceEventService( dao );
        }

        private IResourceAbsenceEventDAO createDAO() {
            return new ResourceAbsenceEventDAO();
        }
    }

     // *********************************************
    // * DAO
    // *********************************************
    public interface IResourceAbsenceEventDAO extends FSL_DAO.DmlInterface {

    }

    public class ResourceAbsenceEventDAO  extends FSL_DAO.DmlBase implements IResourceAbsenceEventDAO {

    }

    // *********************************************
    // * Service
    // *********************************************

    public interface IResourceAbsenceEventService {
        List<Resource_Absence_Event__e> createResourceAbsenceEventMessages(List<SObject> resourceAbsences);
        void processEventMessages(List<SObject> eventMessages,FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService);
    }

    public class ResourceAbsenceEventService implements IResourceAbsenceEventService {

        private final String ROW_LOCK_EXCEPTION_MESSAGE = 'UNABLE_TO_LOCK_ROW';
       
        private integer retryLimit = 0;
        private integer retryCount = 0;
        private Boolean isExtendedLoggingEnabled = false;
        private IResourceAbsenceEventDAO dao;
        private List<LKLUpsertResourceAbsencePlatformEventLog> applicationLogs; 

        public ResourceAbsenceEventService ( IResourceAbsenceEventDAO dao) {
            this.dao = dao;
            initializeData();            
        }

        public void initializeData() {
            setNumberOfRetries();
            setExtendedLoggingFeatureFlag();
        }
        
        
        private void setExtendedLoggingFeatureFlag() {
            FSL_FeatureFlag.IFeatureFlagService featureFlagService = (new FSL_FeatureFlag.Factory()).createService();
            List<FSL_Feature_Flag__mdt> featureFlagMdts = featureFlagService.getFeatureFlagByName('Extended Logging Feature');
            for(FSL_Feature_Flag__mdt featureFlagMdt :featureFlagMdts) {
                isExtendedLoggingEnabled = featureFlagMdt.Enabled__c;
            }
        }

        private void setNumberOfRetries() {

            FSL_ConfigurationSetting.IConfigurationSettingService configSettingService = (new FSL_ConfigurationSetting.Factory()).createService();
            List<FSL_Configuration_Setting__mdt> configSettings = configSettingService.getConfigurationSettingByName('Resource Absence Platform Event');
            if (!configSettings.isEmpty() && configSettings[0].Enabled__c && configSettings[0].No_of_Retries__c != null) {
                retryLimit = Integer.ValueOf(configSettings[0].No_of_Retries__c) ;
            }  
        }

        public void processEventMessages(List<SObject> eventMessages, FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService) {     
            applicationLogs = new List<LKLUpsertResourceAbsencePlatformEventLog>();
            if(isExtendedLoggingEnabled) {
                applicationLogs.add(createAppLogForProcessPlatformEvent(eventMessages));
            }
       
            try {
                resourceAbsenceService.upsertResourceAbsencesByEventMessage(eventMessages);
                saveApplicationLogs();
            }catch (Exception e ) {
                System.debug('Process Event Exception has been occur ==> ' + e);
                handleExceptionByExceptionType(e, eventMessages);
            }
        }

        private void handleExceptionByExceptionType(Exception e, List<SObject> eventMessages) {
            FSL_ResourceAbsenceEvent.ExceptionType exceptionType = getException(e);
            retryCount = Eventbus.TriggerContext.currentContext().retries;
            if(isExtendedLoggingEnabled) {
                applicationLogs.add(createApplicationForExceptionWhenUpsert(FSL_ResourceAbsenceEvent.LogType.EXCEPTION_LOG,e,retryCount,retryLimit,EventMessages));
            }
            switch on exceptionType {
                when ROW_LOCK_EXCEPTION_TYPE {
                    if (retryCount < retryLimit) {
                        if(isExtendedLoggingEnabled) { 
                           applicationLogs.add(createAppLogForRetryException(FSL_ResourceAbsenceEvent.LogType.RETRY_LOG,e, retryCount, retryLimit, eventMessages));
                           saveApplicationLogsWithPlateformEvent(new ApplicationLogPlatformEvent());
                        }
  
                        throw new Eventbus.RetryableException();
                    }
                    applicationLogs.add(createAppLogForRetryableExceedLimit(FSL_ResourceAbsenceEvent.LogType.RETRY_EXCEED_LIMIT,e, retryCount, retryLimit, eventMessages));
                } when else {
                    if(!isExtendedLoggingEnabled) {
                        applicationLogs.add(createApplicationForExceptionWhenUpsert(FSL_ResourceAbsenceEvent.LogType.EXCEPTION_LOG,e,retryCount,retryLimit,EventMessages));
                    }
                }
            }
            saveApplicationLogs();
        }

        private void saveApplicationLogsWithPlateformEvent(FSL_UpsertResourceAbsenceBatch.EventSubscriber eventSubcriber) {
            List<Application_Log_Event__e> eventMessages = new List<Application_Log_Event__e>();
            for (LKLUpsertResourceAbsencePlatformEventLog appLog : this.applicationLogs ) {
                eventMessages.add(createApplicationLogEventMessage(appLog));
            }
            eventSubcriber.publishEvents(eventMessages);
        }

        private Application_Log_Event__e createApplicationLogEventMessage(LKLUpsertResourceAbsencePlatformEventLog appLog) {
            FSL_Application_Log__c log = appLog.getApplicationLog();
            Application_Log_Event__e appLogEvent = new Application_Log_Event__e();
            appLogEvent.Operation__c = log.Operation__c;
            appLogEvent.Error_Caught__c = log.Error_Caught__c;
            appLogEvent.Message__c = log.Error_Message__c;
            appLogEvent.RecordTypeId__c = log.RecordTypeId;
            appLogEvent.Total_Record_Count__c = log.Total_Record_Count__c;
            return appLogEvent;
        }

        private LKLUpsertResourceAbsencePlatformEventLog createAppLogForRetryableExceedLimit(FSL_ResourceAbsenceEvent.LogType logType, Exception e, Integer retryCount, Integer retryLimit, List<SObject> eventMessages) {
            LKLUpsertResourceAbsencePlatformEventLog platformEventLog = createApplicationForException(logType,  e, retryCount, retryLimit, eventMessages);
            return platformEventLog;
        }
        
        private LKLUpsertResourceAbsencePlatformEventLog createAppLogForRetryException(FSL_ResourceAbsenceEvent.LogType logType, Exception e, Integer retryCount, Integer retryLimit, List<SObject> eventMessages) {
            LKLUpsertResourceAbsencePlatformEventLog platformEventLog = createApplicationForException(logType,  e, retryCount, retryLimit, eventMessages);
            return platformEventLog;
        }

        private LKLUpsertResourceAbsencePlatformEventLog createAppLogForProcessPlatformEvent(List<SObject> eventMessages) {
            LKLUpsertResourceAbsencePlatformEventLog platformEventLog = new LKLUpsertResourceAbsencePlatformEventLog();
            platformEventLog.createAppLog(FSL_ResourceAbsenceEvent.LogType.PROCESS_LOG, eventMessages);
            return platformEventLog;
        }

        private LKLUpsertResourceAbsencePlatformEventLog createApplicationForExceptionWhenUpsert(FSL_ResourceAbsenceEvent.LogType logType, Exception e, Integer retryCount, Integer retryLimit, List<SObject> eventMessages) {
            LKLUpsertResourceAbsencePlatformEventLog platformEventLog = createApplicationForException(logType,  e, retryCount, retryLimit, eventMessages);
            return platformEventLog;
        }

        private LKLUpsertResourceAbsencePlatformEventLog createApplicationForException(FSL_ResourceAbsenceEvent.LogType logType, Exception e, Integer retryCount, Integer retryLimit, List<SObject> eventMessages) {
            LKLUpsertResourceAbsencePlatformEventLog platformEventLog = new LKLUpsertResourceAbsencePlatformEventLog();
            String additionalInfo = 'Current Retry Count : ' + retryCount + '\r\n';
            additionalInfo += 'Current Retry Limit : ' + retryLimit + '\r\n';
            platformEventLog.createAppLog(logType, additionalInfo, e, eventMessages);
            return platformEventLog;
        }

        private void saveApplicationLogs() {
            FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.Factory().createService();
            service.saveApplicationLogs( this.applicationLogs );
        }

        private ExceptionType getException(Exception e) {
            ExceptionType type = FSL_ResourceAbsenceEvent.ExceptionType.EMPTY;
            if(e.getMessage().toUpperCase().contains(ROW_LOCK_EXCEPTION_MESSAGE)) {
                type = FSL_ResourceAbsenceEvent.ExceptionType.ROW_LOCK_EXCEPTION_TYPE;
            }
            return type;
        } 

        public List<Resource_Absence_Event__e> createResourceAbsenceEventMessages(List<SObject> resourceAbsences) {
            List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
            for(ResourceAbsence resourceAbsenceRecord: (List<ResourceAbsence>) resourceAbsences ) {
                Resource_Absence_Event__e eventMessage = new Resource_Absence_Event__e();
                eventMessage.Gantt_Label__c = resourceAbsenceRecord.FSL__GanttLabel__c;
                eventMessage.Resource_Absense_Id__c = resourceAbsenceRecord.ResourceId;
                eventMessage.Record_Type_Id__c =  resourceAbsenceRecord.RecordTypeId;
                eventMessage.Latitude__c = resourceAbsenceRecord.Latitude;
                eventMessage.Longtitude__c = resourceAbsenceRecord.Longitude;
                eventMessage.Start_Time__c = resourceAbsenceRecord.Start;
                eventMessage.End_Time__c = resourceAbsenceRecord.End; 
                eventMessage.Type__c = resourceAbsenceRecord.Type;
                eventMessage.Approved__c = resourceAbsenceRecord.FSL__Approved__c ;
                eventMessages.add(eventMessage);           
            } 
            return eventMessages;            
        }

        @testVisible
        private Integer getNumberOfRetries() {
            return this.retryLimit;
        }

     
    }

    public virtual class LKLUpsertResourceAbsencePlatformEventLog extends FSL_ApplicationLog.ApplicationLog {
        public LKLUpsertResourceAbsencePlatformEventLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'UpsertResourceAbsencePlatformEvent';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = platformEventRecordTypeId;
        }

        public void createAppLog( FSL_ResourceAbsenceEvent.LogType logType, List<SObject> records ) {
            createAppLog(logType, null, null, records);
        }

        public void createAppLog( FSL_ResourceAbsenceEvent.LogType logType, String additionalInfo, Exception e, List<SObject> records ) {
            String message = '';
            switch on logType {
                when RETRY_LOG {
                    message = 'Retry Upsert ResourceAbsence From Platform Event Messages  ' + '\r\n'; 
                    message += additionalInfo + '\r\n';
                    message += e?.getMessage() +  '\r\n' +  e?.getStackTraceString() + '\r\n';
                    message += records.toString() + '\r\n';
                    appLog.Error_Caught__c = true;
                }
                when RETRY_EXCEED_LIMIT {
                    message = 'Retry Exceed Limit from Platform Event Messages  ' + '\r\n'; 
                    message += additionalInfo + '\r\n';
                    message += e?.getMessage() +  '\r\n' +  e?.getStackTraceString() + '\r\n';
                    message += records.toString() + '\r\n';
                    appLog.Error_Caught__c = true;
                }
                when PROCESS_LOG {
                    message = 'Process ResourceAbsences From Platform Event Messages  ' + '\r\n'; 
                    message +=  records.toString() + '\r\n';
                    appLog.Error_Caught__c = false;
                }
                when EXCEPTION_LOG {
                    message = 'Failed Upsert For ResourceAbsences From Platform Event Messages  ' + '\r\n'; 
                    message += additionalInfo + '\r\n';
                    message +=  e?.getMessage() +  '\r\n' +  e?.getStackTraceString() + '\r\n';
                    message +=  records + '\r\n';
                    appLog.Error_Caught__c = true;
                   
                }
            }
            appLog.Error_Message__c = message;
            appLog.Total_Record_Count__c = records.size();
        }

    }
    
    public class ApplicationLogPlatformEvent extends FSL_UpsertResourceAbsenceBatch.EventSubscriber {
        public ApplicationLogPlatformEvent () {
            super();
        }
    }
}