public with sharing class FSL_ClearQueuedCall {

  // ************************
    //  static definitions
    // ***********************
    // Match this to the Validation Error Message for the FSLClearQueuedCall__C Object in Salesforce Object Manager
    public static final String WORKORDER_ALREADY_QUEUED_ERROR_MSG = 'Cannot save the record -either the Work Order reference is missing or the Work Order is already in the clear queue';

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IClearQueuedCallService createService();
        IClearQueueProcessingBatch createClearQueueProcessingBatch();
    }

    public class Factory implements IFactory {
        public IClearQueuedCallService createService() {
            IClearQueuedCallDAO dao = createDao();
            FSL_ToD3Clear.IFactory toD3ClearFactory = new FSL_ToD3Clear.Factory();
            FSL_AssignedResource.IFactory assignedResourceFactory = new FSL_AssignedResource.Factory();
            FSL_Case.IFactory caseFactory = new FSL_Case.Factory();
            FSL_FeedItem.IFactory feedItemFactory = new FSL_FeedItem.Factory();
            FSL_WorkOrder.IFactory workOrderFactory = new FSL_WorkOrder.Factory();
            FSL_ApplicationLog.IFactory applicationLogFactory = new FSL_ApplicationLog.Factory();
            IClearQueuedCallService service = new ClearQueuedCallService( dao, 
                                                toD3ClearFactory.createToD3Clear(),
                                                assignedResourceFactory.createService(), 
                                                caseFactory.createService(), 
                                                feedItemFactory.createService(), 
                                                workOrderFactory.createService(), 
                                                applicationLogFactory.createService() );
            return service;
        }

        private IClearQueuedCallDAO createDao() {
            return new ClearQueuedCallDAO( new FSL_Dao.DatabaseResultsProcessor() );
        }

        public IClearQueueProcessingBatch createClearQueueProcessingBatch() {
            return new ClearQueueProcessingBatch();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IClearQueuedCallDAO extends FSL_DAO.DmlInterface {
        List<FSLClearQueuedCall__c> fetchPendingCalls( Datetime createdDateIfNoMileage, Integer maxWorkOrders );
        List<FSLClearQueuedCall__c> fetchCallsForWorkOrderId( Set<Id> workOrderIds );
        List<FSLCLearQueuedCall__c> fetchLatestProcessedCalls( Integer count, Datetime earliestModifiedTime );
        List<FSL_Clearing_Queue__mdt> fetchClearQueueConfiguration();
        List<Boolean> insertClearQueuedCalls( List<FSLClearQueuedCall__c> calls );
    }

    public inherited sharing class ClearQueuedCallDAO extends FSL_DAO.DmlBase implements IClearQueuedCallDAO {
        private FSL_DAO.IDatabaseResultsProcessor resultsProcessor;

        public ClearQueuedCallDAO( FSL_DAO.IDatabaseResultsProcessor resultsProcessor ) {
            this.resultsProcessor = resultsProcessor;
        }

        public List<FSLClearQueuedCall__c> fetchPendingCalls( Datetime createdDateIfNoMileage, Integer maxWorkOrders ) {
            return [SELECT Id, CreatedDate, Mileage_Received__c, Retry_Count__c, State__c, Work_Order__c 
                    FROM FSLClearQueuedCall__c 
                    WHERE State__c = 'Pending'
                    AND ( Mileage_Received__c = 'Complete'
                        OR CreatedDate <= :createdDateIfNoMileage )
                    ORDER BY CreatedDate ASC
                    LIMIT :maxWorkOrders];
        }

        public List<FSLClearQueuedCall__c> fetchCallsForWorkOrderId( Set<Id> workOrderIds ) {
            return [SELECT Id, CreatedDate, Mileage_Received__c, Retry_Count__c, State__c, Work_Order__c 
                    FROM FSLClearQueuedCall__c 
                    WHERE Work_Order__c IN :workOrderIds];
        }

        public List<FSLCLearQueuedCall__c> fetchLatestProcessedCalls( Integer count, Datetime earliestModifiedTime ) {
            return [SELECT Id, State__c 
                    FROM FSLClearQueuedCall__c 
                    WHERE LastModifiedDate > :earliestModifiedTime
                    AND State__c != 'In Progress'
                    AND 
                        ( State__c != 'Pending' 
                        OR Retry_Count__c > 0 ) 
                    ORDER BY LastModifiedDate DESC
                    LIMIT :count];
        }

        public List<FSL_Clearing_Queue__mdt> fetchClearQueueConfiguration() {
            return [SELECT Enabled__c, Max_consecutive_fails__c, Max_Retries__c, Max_Threads__c, 
                        Max_Wait_Time_Secs__c, Max_WorkOrders__c, Outage_detection_window_minutes__c 
                    FROM FSL_Clearing_Queue__mdt
                    WHERE MasterLabel = 'Clearing Queue'
                    LIMIT 1];
        }
        public List<Boolean> insertClearQueuedCalls( List<FSLClearQueuedCall__c> calls ) {
            List<Boolean> results = new List<Boolean>();
            Database.SaveResult[] saveResults = this.insertRecords( calls, false );
            for ( Database.SaveResult saveResult : saveResults) {
                results.add( saveResult.isSuccess() || resultsProcessor.checkForSpecificError(saveResult, null, FSL_ClearQueuedCall.WORKORDER_ALREADY_QUEUED_ERROR_MSG ) );
            }
            return results;
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IClearQueuedCallService {
        Boolean isEnabled();
        List<WorkOrder> addWorkOrdersToQueue(List<WorkOrder> workOrders );
        void processQueue( IClearQueueProcessingBatch clearQueueProcessingBatch );
        void processClearResult( Id workOrderId, Boolean isSuccessfullyCleared, FSL_Schedule.IMinuteScheduleService minuteScheduleService );
        void updateMileageReceived( Id workOrderId, ClearQueuedCallMileageReceivedStatus status );
        void sendClearRequests( List<FSLClearQueuedCall__c> calls, FSL_Schedule.IMinuteScheduleService minuteScheduleService );
    }

    public class ClearQueuedCallService implements IClearQueuedCallService {
        @testVisible private final Integer DEFAULT_MAX_CONSECUTIVE_FAILS = 5;
        @testVisible private final Decimal DEFAULT_MAX_RETRIES = 3;
        @testVisible private final Integer DEFAULT_MAX_THREADS = 10;
        @testVisible private final Integer DEFAULT_MAX_WAIT_TIME_SECS = 180;
        @testVisible private final Integer DEFAULT_MAX_WORKORDERS = 25;
        @testVisible private final Integer DEFAULT_OUTAGE_DETECTION_WINDOW_MINUTES = 15;
        
        private IClearQueuedCallDAO dao;
        @testVisible private Map<FSLClearQueuedCall__c, WorkOrder> workOrders = new Map<FSLClearQueuedCall__c, WorkOrder>();
        private Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();
        private Map<Id, List<FeedItem>> workOrderIdToFeedItemsListMap = new Map<Id, List<FeedItem>>();
        private FSL_ToD3Clear.IToD3Clear toD3Clear;
        private FSL_AssignedResource.IAssignedResourceService assignedResourceService;
        private FSL_Case.ICaseService caseService;
        private FSL_FeedItem.IFeedItemService feedItemService;
        private FSL_WorkOrder.IWorkOrderService workOrderService;
        private FSL_ApplicationLog.IApplicationLogService applicationLogService;
        
        public ClearQueuedCallService( IClearQueuedCallDAO dao, 
                                        FSL_ToD3Clear.IToD3Clear toD3Clear, 
                                        FSL_AssignedResource.IAssignedResourceService assignedResourceService,
                                        FSL_Case.ICaseService caseService, 
                                        FSL_FeedItem.IFeedItemService feedItemService,
                                        FSL_WorkOrder.IWorkOrderService workOrderService, 
                                        FSL_ApplicationLog.IApplicationLogService applicationLogService ) {
            this.dao = dao;
            this.toD3Clear = toD3Clear;
            this.assignedResourceService = assignedResourceService;
            this.caseService = caseService;
            this.feedItemService = feedItemService;
            this.workOrderService = workOrderService;
            this.applicationLogService = applicationLogService;
        }

        public Boolean isEnabled() {
            Boolean isEnabled = false;
            FSL_Clearing_Queue__mdt configuration = getClearQueueConfiguration();
            if( null == configuration ) {
                System.debug( LoggingLevel.ERROR, 'FSL_ClearQueuedCall.ClearQueuedCallService.isEnabled: No Clear Queue configuration found' );
            }
            else {
                isEnabled = configuration.Enabled__c;
            }
            return isEnabled;
        }

        @testVisible
        private FSL_Clearing_Queue__mdt getClearQueueConfiguration() {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.getClearQueueConfiguration: Enter' );
            FSL_Clearing_Queue__mdt config = null;
            List<FSL_Clearing_Queue__mdt> configs = dao.fetchClearQueueConfiguration();
            if( configs.size() == 1 ) {
                config = configs[0];
            }
            else if( configs.size() == 0 ) {
                System.debug( LoggingLevel.WARN, 'FSL_ClearQueuedCall.ClearQueuedCallService.getClearQueueConfiguration: No Clear Queue config found! Using default values.' );
                config = new FSL_Clearing_Queue__mdt( Enabled__c = true, 
                                                        Max_consecutive_fails__c = DEFAULT_MAX_CONSECUTIVE_FAILS, 
                                                        Max_Retries__c = DEFAULT_MAX_RETRIES, 
                                                        Max_Threads__c = DEFAULT_MAX_THREADS, 
                                                        Max_Wait_Time_secs__c = DEFAULT_MAX_WAIT_TIME_SECS, 
                                                        Max_WorkOrders__c = DEFAULT_MAX_WORKORDERS, 
                                                        Outage_detection_window_minutes__c = DEFAULT_OUTAGE_DETECTION_WINDOW_MINUTES );
            }
            return config;
        }

        public List<WorkOrder> addWorkOrdersToQueue( List<WorkOrder> workOrdersToBeCleared ) {
            List<FSLClearQueuedCall__C> callsToBeCleared = new List<FSLClearQueuedCall__C>();
            List<WorkOrder> workOrdersToBeLocked = new List<WorkOrder>();
            for( WorkOrder wo : workOrdersToBeCleared ) {
                callsToBeCleared.add( FSL_DataFactory.createClearQueuedCall( wo.Id ) );
            }

            List<Boolean> saveResults = dao.insertClearQueuedCalls( callsToBeCleared );
            for( Integer i = 0; i < workOrdersToBeCleared.size(); i++ ) {
                if( saveResults[i] ) {
                    workOrdersToBeLocked.add( workOrdersToBeCleared[i] );
                }
            }
            return workOrdersToBeLocked;
        }

        public void processQueue( IClearQueueProcessingBatch clearQueueProcessingBatch ) {
            List<FSLClearQueuedCall__C> calls = new List<FSLClearQueuedCall__c>();
            try {
                System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.processQueue: Enter' );
                FSL_Clearing_Queue__mdt config = getClearQueueConfiguration();
                Datetime createdDateIfNoMileage = Datetime.now().addSeconds( -config.Max_Wait_Time_secs__c.intValue() );
                Integer count = config.Max_WorkOrders__c.intValue() * config.Max_Threads__c.intValue();
                calls = dao.fetchPendingCalls( createdDateIfNoMileage, count );
                updateStatus( calls, ClearQueueCallStatus.IN_PROGRESS );
                dao.updateRecords( calls );
                startBatch( clearQueueProcessingBatch, config, calls );
            }
            catch( Exception ex ) {
                logException( 'Clear Queue Exception', ex );
                revertToPendingStatusAfterException( calls );
                System.debug( LoggingLevel.ERROR, 'FSL_ClearQueuedCall.ClearQueuedCallService.processQueue: Exception=[' + ex.getMessage() + ']' );
            }
        }

        // Service Tech Team: Moved the logic to processQueue()
        // private List<FSLClearQueuedCall__C> getPendingCalls( FSL_Clearing_Queue__mdt config ) {
        //     System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.getPendingCalls: Enter' );
        //     Datetime createdDateIfNoMileage = Datetime.now().addSeconds( -config.Max_Wait_Time_secs__c.intValue() );
        //     Integer count = config.Max_WorkOrders__c.intValue() * config.Max_Threads__c.intValue();
        //     return dao.fetchPendingCalls( createdDateIfNoMileage, count );
        // }

        // Service Tech Team: Moved the logic to processQueue()
        // private void markCallsInProgress( List<FSLClearQueuedCall__c> calls ) {
        //     System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.markCallsInProgress: Enter - Number of calls = [' + calls.size() + ']' );
        //     updateStatus( calls, ClearQueueCallStatus.IN_PROGRESS );
        //     dao.updateRecords( calls );
        // }

        private void updateStatus( List<FSLClearQueuedCall__c> calls, ClearQueueCallStatus status ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.updateStatus: Enter' );
            for( FSLClearQueuedCall__c call : calls ) {
                switch on status {
                    when PENDING {
                        call.State__c = 'Pending';
                    }
                    when IN_PROGRESS {
                        call.State__c = 'In Progress';
                    }
                    when CLEARED_WITH_MILEAGE {
                        call.State__c = 'Cleared With Mileage';
                    }
                    when CLEARED_WITHOUT_MILEAGE {
                        call.State__c = 'Cleared Without Mileage';
                    }
                    when CASE_CREATED {
                        call.State__c = 'Case Created';
                    }
                }
            }
        }

        private void startBatch( IClearQueueProcessingBatch clearQueueProcessingBatch, FSL_Clearing_Queue__mdt config, List<FSLClearQueuedCall__c> calls ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.startBatch: Enter' );
            clearQueueProcessingBatch.SetCalls( calls );
            FSL_IterableBatchable batch = new FSL_IterableBatchable( clearQueueProcessingBatch );
            String batchJobId = Database.executeBatch( batch, config.Max_WorkOrders__c.intValue() );
            if( !batchJobId.startsWith( '707' ) ) { //707xxxxxxxxxxxx should be returned when Batch job starts properly.
                throw new DmlException( 'FSL_ClearQueuedCall.ClearQueuedCallService.startBatch: Failed to acquire a flex queue lock' );
            }
        }

        private void revertToPendingStatusAfterException( List<FSLClearQueuedCall__c> calls ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.revertToPendingStatusAfterException: Enter' );
            try {
                List<FSLClearQueuedCall__c> callsToRevertToPending = new List<FSLClearQueuedCall__c>();
                for( FSLClearQueuedCall__c call : calls ) {
                    if( call.State__c == 'In Progress' ) {
                        callsToRevertToPending.add( call );
                    }
                }
                if( !callsToRevertToPending.isEmpty() ) {
                    updateStatus( callsToRevertToPending, ClearQueueCallStatus.PENDING );
                    dao.updateRecords( callsToRevertToPending );
                }
            }
            catch( Exception ex ) {
                logException( 'Clear Queue Exception: Failure to revert calls back to pending after previous exception', ex );
            }
        }

        public void sendClearRequests( List<FSLClearQueuedCall__c> calls, FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            try {
                Set<Id> workOrderIds = new Set<Id>();
                for( FSLClearQueuedCall__c call : calls ) {
                    workOrderIds.add( call.Work_Order__c );
                }
                List<WorkOrder> woList = workOrderService.getWorkOrdersForClearing( workOrderIds );
                Map<Id, WorkOrder> workOrdersMap = new Map<Id, WorkOrder>(woList);
                for( FSLClearQueuedCall__c call : calls ) {
                    WorkOrder workOrder = workOrdersMap.get(call.Work_Order__c);
                    if(WorkOrder != null){
                        workOrders.put( call, workOrder );
                    }       
                }
                serviceAppointmentIdToAssignedResourceMap = assignedResourceService.getServiceAppointmentIdToAssignedResourceMap( workOrders.values() );
                workOrderIdToFeedItemsListMap = feedItemService.getWorkOrderIdToFeedItemsMap( workOrderIds );
                Map<Id, Boolean> clearResultsByWorkOrderId = toD3Clear.clearWorkOrders( workOrders.values(), serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsListMap );
                processClearResults( clearResultsByWorkOrderId, minuteScheduleService );
            }
            catch( Exception ex ) {
                logException( 'Clear Queue Exception when sending clear requests', ex );
                revertToPendingStatusAfterException( calls );
            }
        }

        private void logException( String message, Exception ex ) {
            ClearQueueApplicationLog appLog = new ClearQueueApplicationLog();
            appLog.logClearQueueException( message, ex );
            applicationLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }

        // Service Tech Team: Moved the logic to sendClearRequests()
        // private void loadWorkOrderData( List<FSLClearQueuedCall__c> calls ) {
        //     System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.loadWorkOrderData: Enter' );
        //     Set<Id> workOrderIds = getWorkOrderIds( calls );
        //     List<WorkOrder> woList = workOrderService.getWorkOrdersForClearing( workOrderIds );
        //     // Service Tech Team: Adding a map to avoid nested loops
        //     Map<Id, WorkOrder> workOrdersMap = new Map<Id, WorkOrder>(woList);
        //     // Place returned List in a map with the ClearQueuedCall Id as the key
        //     // This is done to allow the status to be updated easily in case of an exception
        //     for( FSLClearQueuedCall__c call : calls ) {
        //         WorkOrder workOrder = workOrdersMap.get(call.Work_Order__c);
        //         if(WorkOrder != null){
        //             workOrders.put( call, workOrder );
        //         }       
        //     }
        //     // TODO: See if it's really necessary to query all this additional information (perhaps make it part of the WorkOrder query)
        //     serviceAppointmentIdToAssignedResourceMap = assignedResourceService.getServiceAppointmentIdToAssignedResourceMap( workOrders.values() );
        //     workOrderIdToFeedItemsListMap = feedItemService.getWorkOrderIdToFeedItemsMap( workOrderIds );
        // }

        // Service Tech Team: Moved the logic to sendClearRequests()
        // private Set<Id> getWorkOrderIds( List<FSLClearQueuedCall__c> calls ) {
        //     System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.getWorkOrderIds: Enter' );
        //     Set<Id> workOrderIds = new Set<Id>();
        //     for( FSLClearQueuedCall__c call : calls ) {
        //         workOrderIds.add( call.Work_Order__c );
        //     }
        //     return workOrderIds;
        // }
        
        // Service Tech Team: Moved the logic to sendClearRequests()
        // private void sendClearRequests( FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
        //     Map<Id, Boolean> clearResultsByWorkOrderId = toD3Clear.clearWorkOrders( workOrders.values(), serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsListMap );
        //     processClearResults( clearResultsByWorkOrderId, minuteScheduleService );
        // }

        public void processClearResult( Id workOrderId, Boolean isSuccessfullyCleared, FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.processClearResult: Enter - WorkOrderId = [' + workOrderId + '] - Is Successfully Cleared = [' + isSuccessfullyCleared + ']' );
            Map<Id, Boolean> clearResultsByWorkOrderId = new Map<Id, Boolean>{ workOrderId => isSuccessfullyCleared };
            processClearResults( clearResultsByWorkOrderId, minuteScheduleService );
        }

        public void processClearResults( Map<Id, Boolean> clearResultsByWorkOrderId, FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.processClearResults.processClearResult: Enter' );
            Set<FSLClearQueuedCall__c> calls = workOrders.keySet();
            Boolean haveAllFailed = true;
            for( FSLClearQueuedCall__c call : calls ) {
                //Boolean isSuccess = clearResultsByWorkOrderId.get( call.Work_Order__c );
                //processClearResult( call, isSuccess );
                if( call != null ) {
                	Boolean isSuccess = clearResultsByWorkOrderId.get( call.Work_Order__c );
                    if( isSuccess ) {
                        processSuccessfullClearResult( call );
                        haveAllFailed = false;
                    }
                    else {
                        processUnsuccessfullClearResult( call );
                    }
                }
                //if( isSuccess ) haveAllFailed = false;
            }
            dao.updateRecords( new List<FSLClearQueuedCall__c>( calls ) );
            if( haveAllFailed ) {
                detectOutage( minuteScheduleService );
            }
        }
        
		// Service Tech Team: Moved the logic to processClearResults() above
        //private void processClearResult( FSLClearQueuedCall__c call, Boolean isSuccessfullyCleared ) {
        //    System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.processClearResult.processClearResult: Enter' );
        //    if( call != null ) {
        //        if( isSuccessfullyCleared ) {
        //            processSuccessfullClearResult( call );
        //        }
        //        else {
        //            processUnsuccessfullClearResult( call );
        //        }
        //    }
        //}

        private FSLClearQueuedCall__c getCallForWorkOrderId( Id workOrderId ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.getCallForWorkOrderId: Enter - WorkOrderId = [' + workOrderId + ']' );
            FSLClearQueuedCall__c result = null;
            List<FSLClearQueuedCall__c> clearQueuedCalls = dao.fetchCallsForWorkOrderId( new Set<Id>{ workOrderId } );
            if( clearQueuedCalls.size() == 1 ) {
                result = clearQueuedCalls[0];
            }
            return result;
        }

        private void processSuccessfullClearResult( FSLClearQueuedCall__c call ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.processSuccessfullClearResult: Enter' );
            ClearQueueCallStatus newStatus;
            if( call.Mileage_Received__c == 'Complete' ) {
                newStatus = ClearQueueCallStatus.CLEARED_WITH_MILEAGE;
            }
            else {
                newStatus = ClearQueueCallStatus.CLEARED_WITHOUT_MILEAGE;
            }
            updateStatus( new List<FSLClearQueuedCall__c>{ call }, newStatus );
        }
    
        private void processUnsuccessfullClearResult( FSLClearQueuedCall__c call ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.processUnsuccessfullClearResult: Enter' );
            ClearQueueCallStatus newStatus;
            FSL_Clearing_Queue__mdt config = getClearQueueConfiguration();
            call.Retry_Count__c++;
            if( call.Retry_Count__c > config.Max_Retries__c ) {
                newStatus = ClearQueueCallStatus.CASE_CREATED;
                caseService.openClearQueueFailureCase( call.Work_Order__c, workOrderService );
            }
            else {
                newStatus = ClearQueueCallStatus.PENDING;
            }
            updateStatus( new List<FSLClearQueuedCall__c>{ call }, newStatus );
        }

        private void detectOutage( FSL_Schedule.IMinuteScheduleService minuteScheduleService ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.detectOutage: Enter' );
            FSL_Clearing_Queue__mdt config = getClearQueueConfiguration();
            Datetime earliestModifiedTime = Datetime.now().addMinutes( -config.Outage_detection_window_minutes__c.intValue() );
            Integer maxConsecutiveCalls = config.Max_consecutive_fails__c.intValue();
            Integer consecutiveFails = 0;
            List<FSLClearQueuedCall__c> calls = dao.fetchLatestProcessedCalls( maxConsecutiveCalls, earliestModifiedTime );
            for( FSLClearQueuedCall__c call : calls ) {
                if( !call.State__c.startsWith( 'Cleared' ) ) {
                    consecutiveFails++;
                }
            }
            if( consecutiveFails == maxConsecutiveCalls ) {
                minuteScheduleService.haltClearQueueProcessingDueToPotentialOutage( caseService );
            }
        }

        public void updateMileageReceived( Id workOrderId, ClearQueuedCallMileageReceivedStatus status ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_ClearQueuedCall.ClearQueuedCallService.updateMileageReceived: Enter - WorkOrderId = [' + workOrderId + '] - Status = [' + status + ']' );
            FSLClearQueuedCall__c call = getCallForWorkOrderId( workOrderId );
            if( call != null ) {
                if( call.State__c == 'Pending' ) {
                    switch on status {
                        when PARTIAL {
                            call.Mileage_Received__c = 'Partial';
                        }
                        when COMPLETE {
                            call.Mileage_Received__c = 'Complete';
                        }
                    }
                }
                else {
                    System.debug( LoggingLevel.WARN, 'FSL_ClearQueuedCall.ClearQueuedCallService.updateMileageReceived: Mileage received for call not in Pending state - WorkOrder Id = [' + workOrderId + '] - Call Id = [' + call.Id + '] - State = [' + call.State__c + '] - Mileage Received State = [' + call.Mileage_Received__c + ']' );
                }
                call.Mileage_Received_Timestamp__c = Datetime.now();
                dao.updateRecords( new List<FSLClearQueuedCall__c>{ call } );
            }
        }
    }

    public enum ClearQueueCallStatus {
        PENDING,
        IN_PROGRESS,
        CLEARED_WITH_MILEAGE,
        CLEARED_WITHOUT_MILEAGE,
        CASE_CREATED
    }

    public enum ClearQueuedCallMileageReceivedStatus {
        PENDING,
        PARTIAL,
        COMPLETE
    }

    // *********************************************
    // * Application Log
    // *********************************************
    public class ClearQueueApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public ClearQueueApplicationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'Clear Queue';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void logClearQueueException( String message, Exception ex ) {
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message;
            appendFormattedExceptionToErrorMessage( ex );
        }
    }
  
    // *********************************************
    // * Batchable Implementation
    // *********************************************
    public interface IClearQueueProcessingBatch extends FSL_IterableBatchable.IBatchable {
        void setCalls( List<FSLClearQueuedCall__c> calls );
    }

    public class ClearQueueProcessingBatch implements IClearQueueProcessingBatch {
        private List<FSLClearQueuedCall__c> calls;

        public ClearQueueProcessingBatch() {
            this.calls = new List<FSLClearQueuedCall__c>();
        }

        public void setCalls( List<FSLClearQueuedCall__c> calls ) {
            this.calls = calls;
        }

        public Iterable<SObject> start( Database.BatchableContext context ) {
            return calls;
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            FSL_ClearQueuedCall.IClearQueuedCallService service = new FSL_ClearQueuedCall.Factory().createService();
            FSL_Schedule.IMinuteScheduleService minuteScheduleService = new FSL_Schedule.Factory().createService();

            service.sendClearRequests( (List<FSLClearQueuedCall__c>)items, minuteScheduleService );
        }
    
        public void finish( Database.BatchableContext context ) {
        }
    }
}