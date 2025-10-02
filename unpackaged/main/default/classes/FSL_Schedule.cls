public with sharing class FSL_Schedule implements Schedulable {
    @testVisible private IFactory scheduleFactory = new Factory();
    @testVisible private FSL_ClearQueuedCall.IFactory clearQueuedCallFactory = new FSL_ClearQueuedCall.Factory();
    @testVisible private FSL_WorkOrder.IFactory workOrderFactory = new FSL_WorkOrder.Factory();
    @testVisible private FSL_ServiceLineItem.IFactory serviceLineItemFactory = new FSL_ServiceLineItem.Factory();
    @testVisible private Integer configCount = 0;
    @testVisible private Boolean executed = false;

    public void execute( System.SchedulableContext schedulableContext ) {
     
        IMinuteScheduleTaskDAO dao = scheduleFactory.createMinuteScheduleDAO();
        List<FSL_Minute_Schedule_Task__mdt> configs = dao.fetchActiveScheduledTasks();
        for( FSL_Minute_Schedule_Task__mdt config : configs ) {
            configCount++;
            if ( shouldRunTaskThisMinute(config) ) {
                switch on config.MasterLabel {
                     when 'Clear Queue Processing' {
                         executeClearQueueProcessing();
                     }
                     when 'Check Lockable Work Orders' {
                        executeCheckAndLockWorkOrders();
                     }
                }
                executed = true;
            }
        }
    }

    @testVisible private Boolean shouldRunTaskThisMinute(FSL_Minute_Schedule_Task__mdt config) {
        Boolean result = true;

        Integer repeatInterVal = (Integer)config.Repeat_Interval_Minutes__c;
        if ( repeatInterVal != 1 ) {
            if ( Math.mod((Integer)(DateTime.now().getTime() / 1000 / 60), repeatInterVal) != 0 ) {
                result = false;
            }
        }
        return result;
    }

    private void executeClearQueueProcessing() {
        if( !Test.isRunningTest() ) clearQueuedCallFactory = new FSL_ClearQueuedCall.Factory();
        FSL_ClearQueuedCall.IClearQueuedCallService service = clearQueuedCallFactory.createService();
        FSL_ClearQueuedCall.IClearQueueProcessingBatch clearQueueProcessingBatch = clearQueuedCallFactory.createClearQueueProcessingBatch();

        service.processQueue( clearQueueProcessingBatch );
    }

    @testVisible private void executeCheckAndLockWorkOrders() {

        // Need to call FSL_WorkOrder.IWorkOrderService to check and add workoders to the Clear Queue)

        if( !Test.isRunningTest() ) workOrderFactory = new FSL_WorkOrder.Factory();
        FSL_WorkOrder.IWorkOrderService workOrderService =  workOrderFactory.createService();

        if( !Test.isRunningTest() ) clearQueuedCallFactory = new FSL_ClearQueuedCall.Factory();
        FSL_ClearQueuedCall.IClearQueuedCallService clrQueueService =  clearQueuedCallFactory.createService();

        if( !Test.isRunningTest() ) serviceLineItemFactory = new FSL_ServiceLineItem.Factory();
        FSL_ServiceLineItem.IServiceLineItemService sliService =  serviceLineItemFactory.createService();

        workOrderService.lockWorkOrdersAndPrepareToClear(clrQueueService, sliService);
      
    }

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IMinuteScheduleTaskDAO createMinuteScheduleDAO();
        IMinuteScheduleService createService();
    }

    public class Factory implements IFactory {
        public IMinuteScheduleTaskDAO createMinuteScheduleDAO() {
            return new MinuteScheduleTaskDAO();
        }

        public IMinuteScheduleService createService() {
            return new MinuteScheduleService( createMinuteScheduleDAO() );
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IMinuteScheduleTaskDAO extends FSL_DAO.DmlInterface {
        List<FSL_Minute_Schedule_Task__mdt> fetchActiveScheduledTasks();
        List<FSL_Minute_Schedule_Task__mdt> fetchScheduledTasksByMasterLabel( String masterLabel );
    }

    public class MinuteScheduleTaskDAO extends FSL_DAO.DmlBase implements IMinuteScheduleTaskDAO {
        public List<FSL_Minute_Schedule_Task__mdt> fetchActiveScheduledTasks() {
            Datetime now = Datetime.now();
            return [SELECT MasterLabel, DeveloperName, Start_Date_Time__c, End_Date_Time__c, Repeat_Interval_Minutes__c
                    FROM FSL_Minute_Schedule_Task__mdt 
                    WHERE Start_Date_Time__c <= :now 
                    AND End_Date_Time__c >= :now];
        }

        public List<FSL_Minute_Schedule_Task__mdt> fetchScheduledTasksByMasterLabel( String masterLabel ) {
            return [SELECT MasterLabel, DeveloperName, Start_Date_Time__c, End_Date_Time__c, Repeat_Interval_Minutes__c
                    FROM FSL_Minute_Schedule_Task__mdt 
                    WHERE MasterLabel = :masterLabel];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IMinuteScheduleService {
        void haltClearQueueProcessingDueToPotentialOutage( FSL_Case.ICaseService caseService );
    }

    public class MinuteScheduleService implements IMinuteScheduleService {
        private IMinuteScheduleTaskDAO dao;

        public MinuteScheduleService( IMinuteScheduleTaskDAO dao ) {
            this.dao = dao;
        }

        public void haltClearQueueProcessingDueToPotentialOutage( FSL_Case.ICaseService caseService ) {
            List<FSL_Minute_Schedule_Task__mdt> configs = dao.fetchScheduledTasksByMasterLabel( 'Clear Queue Processing' );
            if( !configs.isEmpty() && configs[0].End_Date_Time__c > Datetime.now() ) {
                configs[0].End_Date_Time__c = Datetime.now();
                FSL_MetaDataUtility.upsertMetadata(configs);
                caseService.openClearQueueProcessingHaltedCase();
            }
        }
    }
}