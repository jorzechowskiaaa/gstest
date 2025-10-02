/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 *          07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log
 * 
 */
public class FSL_UpsertResourceAbsenceBatch implements Database.Batchable<SObject>, Database.Stateful {
    private List<ResourceAbsence> resourceAbsences;
    private Integer totalUpsertCount = 0;
    private Integer failedUpsertCount = 0;
    private Boolean isPlatformEventFeatureEnabled, isExtendedLoggingEnabled = false;
    private FSL_ApplicationLog.IApplicationLogService appLogService; 
    
    public FSL_UpsertResourceAbsenceBatch( List<ResourceAbsence> resourceAbsences ) {
        this.resourceAbsences = resourceAbsences;
        totalUpsertCount = this.resourceAbsences.size();
        initializeData();
    }
    
    private void initializeData() {
        setPlatformEventFeatureFlag();
        appLogService = new FSL_ApplicationLog.Factory().createService();
    }
    
    public Iterable<SObject> start( Database.BatchableContext bc ) {
        return resourceAbsences;
    }
    
    public void execute( Database.BatchableContext bc, List<SObject> scope ) {
        FSL_Instrumentation instrumentation = FSL_Instrumentation.createInstance(FSL_UpsertResourceAbsenceBatch.class.getName());
        instrumentation.startInstrumenting();

        doExecute( (List<ResourceAbsence>)scope);
        
        instrumentation.stopInstrumenting();
        
        instrumentation.logResult();

    }

    private void doExecute(List<ResourceAbsence> scope ) {
        List<Database.upsertResult> results = Database.upsert( scope, ResourceAbsence.FSL_Resource_ID__c, false );
        processResults( results, scope );
    }

    private void processResults( List<Database.UpsertResult> upsertResults, List<SObject> scope ) {
        if( !upsertResults.isEmpty() ) {
            List<LklUpsertResultApplicationLog> logs = createUpsertResourceAbsenceLogs( upsertResults );
            appLogService.saveApplicationLogs( logs );

            List<SObject>  recordsToBeReprocessed = new List<SObject>();
            Integer index = 0;
            for( Database.UpsertResult upsertResult : upsertResults ) {
                if( !upsertResult.isSuccess() ) {
                    failedUpsertCount++;
                    recordsToBeReprocessed.add(scope[index]);
                }
                index++;
            }
            if (isPlatformEventFeatureEnabled && !recordsToBeReprocessed.isEmpty()) {
                publishEventMessagesForFailedUpsert(recordsToBeReprocessed, new EventSubscriberService() );
            }
        }
    }

    @TestVisible
    private void publishEventMessagesForFailedUpsert( List<SObject> resourceAbsences, EventSubscriber eventService ) {
        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = (new FSL_ResourceAbsenceEvent.Factory()).createService();
        List<Resource_Absence_Event__e> eventMessages = resourceAbsenceEventService.createResourceAbsenceEventMessages(resourceAbsences);
        try {
            if (!eventMessages.isEmpty()) {
                eventService.publishEvents(eventMessages);
                if(isExtendedLoggingEnabled) {
                    logPublishingEventSuccess(eventMessages);
                }
            }
        }catch( Exception e ) {
            logPublishingEventError(e, resourceAbsences);
        }
    }

    private void logPublishingEventSuccess(List<SObject> eventMessages) {
        List<LklPublishEventApplicationLog> logs = new List<LklPublishEventApplicationLog>();
        LklPublishEventApplicationLog appLog = new LklPublishEventApplicationLog();
        appLog.logSuccessfulPublishingEvent(eventMessages);
        logs.add(appLog);
        appLogService.saveApplicationLogs( logs );
    }

    @TestVisible
    private void logPublishingEventError(Exception e, List<SObject> resourceAbsences) {
        List<LklPublishEventApplicationLog> logs = new List<LklPublishEventApplicationLog>();
        LklPublishEventApplicationLog appLog = new LklPublishEventApplicationLog();
        appLog.logEventPlatformPublishError(e, resourceAbsences);
        logs.add(appLog);
        appLogService.saveApplicationLogs( logs );
    }

    private List<LklUpsertResultApplicationLog> createUpsertResourceAbsenceLogs( List<Database.upsertResult> upsertResults ) {
        List<LklUpsertResultApplicationLog> logs = new List<LklUpsertResultApplicationLog>();
        for( Database.UpsertResult upsertResult : upsertResults ) {
            if( !upsertResult.isSuccess() ) {
                LklUpsertResultApplicationLog appLog = new LklUpsertResultApplicationLog();
                appLog.logUpsertResult( upsertResult );
                logs.add( appLog );
            }
        }
        return logs;
    }

    private void setPlatformEventFeatureFlag() {
        FSL_FeatureFlag.IFeatureFlagService featureFlagService = (new FSL_FeatureFlag.Factory()).createService();
        List<FSL_Feature_Flag__mdt> featureFlagMdts = featureFlagService.getFeatureFlags();
        for (FSL_Feature_Flag__mdt featureFlag : featureFlagMdts) {
            switch on featureFlag.Label {
                when 'Resource Absence Platform Feature' {
                    isPlatformEventFeatureEnabled = featureFlag.Enabled__c ;
                }
                when 'Extended Logging Feature' {
                    isExtendedLoggingEnabled = featureFlag.Enabled__c;
                }
            }
        }
    }
    public void finish( Database.BatchableContext bc ) {
        FSL_AsyncApexJob.IAsyncApexJobService asyncApexJobService = new FSL_AsyncApexJob.Factory().createService();
        AsyncApexJob job = asyncApexJobService.getJob( bc.getJobId() );

        LklUpsertResultApplicationLog appLog = new LklUpsertResultApplicationLog();
        appLog.logUpsertTotals( job, totalUpsertCount, failedUpsertCount );

        appLogService.saveApplicationLogs( new List<LklUpsertResultApplicationLog>{ appLog } );
    }

    // *********************************************
    // * ApplicationLog
    // *********************************************
    public class LklUpsertResultApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public LklUpsertResultApplicationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'UpsertResourceAbsence';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void logUpsertTotals( AsyncApexJob job, Integer totalCount, Integer failCount ) {
            appLog.Success_Message__c = 'Total upserts: ' + totalCount + '\r\n';
            appLog.Success_Message__c += 'Failed upserts: ' + failCount + '\r\n';
            appLog.Success_Message__c += 'Successful upserts: ' + ( totalCount - failCount ) + '\r\n';
            appLog.Success_Message__c += '\r\n';
            if( job != null ) {
                appLog.Success_Message__c += 'Job Info:' + '\r\n';
                appLog.Success_Message__c += 'Id: ' + job.Id + '\r\n';
                appLog.Success_Message__c += 'Created Date: ' + job.CreatedDate + '\r\n';
                appLog.Success_Message__c += 'Completed Date: ' + job.CompletedDate + '\r\n';
                appLog.Success_Message__c += 'Total Job Items: ' + job.TotalJobItems + '\r\n';
                appLog.Success_Message__c += 'Number of Errors: ' + job.NumberOfErrors + '\r\n';
                appLog.Success_Message__c += 'Status: ' + job.Status + '\r\n';
                appLog.Success_Message__c += 'Extended Status: ' + job.ExtendedStatus + '\r\n';
            }
            applog.Failed_Record_Count__c = failCount;
            appLog.Success_Record_Count__c = totalCount - failCount;
            appLog.Total_Record_Count__c = totalCount;
            applog.Error_Caught__c = failcount > 0 ? true: false;
        }
    }

    public class LklPublishEventApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public LklPublishEventApplicationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'UpsertResourceAbsencePublishEvent';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void logSuccessfulPublishingEvent (List<SObject> eventMessages) {
            String message = 'Event Message successfully published to Platform Event. \r\n';
            message +=  eventMessages.toString() + '\r\n';
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message;
            appLog.Success_Record_Count__c = eventMessages.size();
            appLog.Total_Record_Count__c = eventMessages.size();
        }

        public void logEventPlatformPublishError(Exception e, List<SObject> resourceAbsences) {
            appLog.Error_Message__c = 'Failed to publish failed records to platform event \r\n';
            appLog.Error_Message__c += e.getMessage() + '\r\n';
            appLog.Error_Message__c += e.getStackTraceString() + '\r\n';
            appLog.Error_Message__c += resourceAbsences;
            appLog.Error_Caught__c = true;
            appLog.Failed_Record_Count__c = resourceAbsences.size();
        }
    }

    public abstract class EventSubscriber {
        public virtual void publishEvents(List<sObject> eventMessages) {
               EventBus.publish(eventMessages); 
        }
    }

    public class EventSubscriberService extends EventSubscriber {
        public EventSubscriberService () {
            super();
        }
    }
}