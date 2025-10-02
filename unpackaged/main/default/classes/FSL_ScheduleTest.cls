@IsTest
public with sharing class FSL_ScheduleTest {
    
    // NOTE: This commented out test is an old and invalid version of a previous test class
    //       When the issues with testing scheduled jobs are fixed, this will require some modifications to make it work
    //       For those modifications, use the information in the 'bad practice' test below
    // @IsTest
    // static void testMinuteSchedule() {
    //     FSL_ClearQueue_Manager_Mock clearQueueManagerMock = new FSL_ClearQueue_Manager_Mock();
    //     FSL_MinuteScheduleTaskDAOMock dao = new FSL_MinuteScheduleTaskDAOMock();

    //     Test.startTest();
    //     FSL_MinuteSchedule minuteSchedule = new FSL_MinuteSchedule();
    //     minuteSchedule.clearQueueManager = clearQueueManagerMock;
    //     minuteSchedule.dao = dao;
    //     String schedule = '0 0 * * * ?';
    //     String jobId = System.schedule( 'Minute Schedule Test', schedule, minuteSchedule );

    //     // Get the information from the CronTrigger API object
    //     CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
    //                     FROM CronTrigger 
    //                     WHERE id = :jobId];

    //     // Verify the expressions are the same
    //     System.assertEquals( schedule, ct.CronExpression );

    //     // Verify the job has not run
    //     System.assertEquals( 0, ct.TimesTriggered );
    //     Test.stopTest();

    //     ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
    //                     FROM CronTrigger 
    //                     WHERE id = :jobId];
    //     System.assertEquals( 1, ct.TimesTriggered );
                        
    //     System.assertEquals( true, minuteSchedule.executed );
    //     System.assertEquals( 1, minuteSchedule.configCount );
    //     System.assertEquals( true, clearQueueManagerMock.processCallsReadyForClearCalled );
    // }

    // FIXME: This is bad practice. The Unit Test should use the scheduler
    // However, there seems to be an issue with triggering the scheduler, see commented out test above
    // Until the issue is solved, use the bad practice test to validate the code
    @IsTest
    static void testExecute_BadPracticeButUseUntilBugWithSchedulerIsFixed() {
        FSL_Schedule schedule = new FSL_Schedule();
        FactoryMock factory = new FactoryMock();
        MinuteScheduleTaskDAOMock dao = new MinuteScheduleTaskDAOMock();
        factory.dao = dao;
        schedule.scheduleFactory = factory;

        FSL_ClearQueuedCallTest.FactoryMock clearQueuedCallFactory = new FSL_ClearQueuedCallTest.FactoryMock();
        schedule.clearQueuedCallFactory = clearQueuedCallFactory;
        
        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallService = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        clearQueuedCallFactory.createServiceReturnValue = clearQueuedCallService;

        FSL_Minute_Schedule_Task__mdt minuteScheduleConfig = new FSL_Minute_Schedule_Task__mdt( Id = dao.Builder.getMockId(), MasterLabel = 'Clear Queue Processing', Start_Date_Time__c = Datetime.now().addDays( -1 ), End_Date_Time__c = Datetime.now().addDays( 1 ), Repeat_Interval_Minutes__c = 1 );
        dao.configs.put( minuteScheduleConfig.Id, minuteScheduleConfig );
        
        Test.startTest();
        schedule.execute( null );
        Test.stopTest();
                        
        System.assertEquals( true, schedule.executed );
        System.assertEquals( 1, schedule.configCount );
        System.assertEquals( 1, clearQueuedCallService.processQueueCallCount );
    }

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateMinuteScheduleDAO_NotNull() {
        FSL_Schedule.IFactory factory = new FSL_Schedule.Factory();

        Test.startTest();
        FSL_Schedule.IMinuteScheduleTaskDAO dao = factory.createMinuteScheduleDAO();
        Test.stopTest();

        System.assertNotEquals( null, dao );
    }

    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_Schedule.IFactory factory = new FSL_Schedule.Factory();

        Test.startTest();
        FSL_Schedule.IMinuteScheduleService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testMinuteSchedulTaskDAO_FetchActiveScheduledTasks_CoverageOnly() {
        // Since Custom Metadata cannot be inserted without a release, this test is only for coverage of the class
        FSL_Schedule.IMinuteScheduleTaskDAO dao = new FSL_Schedule.MinuteScheduleTaskDAO();

        Test.startTest();
        List<FSL_Minute_Schedule_Task__mdt> configs = dao.fetchActiveScheduledTasks();
        Test.stopTest();
    }

    @IsTest
    public static void testMinuteSchedulTaskDAO_GetScheduledTasksByMasterLabel_CoverageOnly() {
        // Since Custom Metadata cannot be inserted without a release, this test is only for coverage of the class
        FSL_Schedule.IMinuteScheduleTaskDAO dao = new FSL_Schedule.MinuteScheduleTaskDAO();

        Test.startTest();
        List<FSL_Minute_Schedule_Task__mdt> configs = dao.fetchScheduledTasksByMasterLabel( 'Test' );
        Test.stopTest();
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testMinuteSchedulService_HaltClearQueueProcessingDueToPotentialOutage_ClearQueueProcessingActive_DeactivatedAndCaseServiceCalled() {
        MinuteScheduleTaskDAOMock dao = new MinuteScheduleTaskDAOMock();
        FSL_Schedule.IMinuteScheduleService service = new FSL_Schedule.MinuteScheduleService( dao );
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();

        FSL_Minute_Schedule_Task__mdt minuteScheduleConfig = new FSL_Minute_Schedule_Task__mdt( Id = dao.Builder.getMockId(), DeveloperName ='Clear Queue Processing',  MasterLabel = 'Clear Queue Processing', Start_Date_Time__c = Datetime.now().addDays( -1 ), End_Date_Time__c = Datetime.now().addDays( 1 ), Repeat_Interval_Minutes__c = 1  );
        dao.configs.put( minuteScheduleConfig.Id, minuteScheduleConfig );

        System.assertEquals( 0, caseService.openClearQueueProcessingHaltedCaseCallCount, 'Arrange: caseService.openClearQueueProcessingHaltedCaseCallCount is not 0' );

        Test.startTest();
        service.haltClearQueueProcessingDueToPotentialOutage( caseService );
        Test.stopTest();

        System.assertEquals( 1, caseService.openClearQueueProcessingHaltedCaseCallCount, 'caseService.openClearQueueProcessingHalted() was not called' );
        System.assert( dao.configs.get( minuteScheduleConfig.Id ).End_Date_Time__c <= Datetime.now(), 'The config\'s End Time was not updated' );
    }

    @IsTest
    public static void testMinuteSchedulService_HaltClearQueueProcessingDueToPotentialOutage_ClearQueueProcessingNotActive_NoActionsTaken() {
        MinuteScheduleTaskDAOMock dao = new MinuteScheduleTaskDAOMock();
        FSL_Schedule.IMinuteScheduleService service = new FSL_Schedule.MinuteScheduleService( dao );
        FSL_CaseTest.CaseServiceMock caseService = new FSL_CaseTest.CaseServiceMock();

        Datetime endTime = Datetime.now().addMinutes( -1 );
        FSL_Minute_Schedule_Task__mdt minuteScheduleConfig = new FSL_Minute_Schedule_Task__mdt( Id = dao.Builder.getMockId(), DeveloperName ='Clear Queue Processing', MasterLabel = 'Clear Queue Processing', Start_Date_Time__c = Datetime.now().addDays( -1 ), End_Date_Time__c = endTime, Repeat_Interval_Minutes__c = 1  );
        dao.configs.put( minuteScheduleConfig.Id, minuteScheduleConfig );

        System.assertEquals( 0, caseService.openClearQueueProcessingHaltedCaseCallCount, 'Arrange: caseService.openClearQueueProcessingHaltedCaseCallCount is not 0' );

        Test.startTest();
        service.haltClearQueueProcessingDueToPotentialOutage( caseService );
        Test.stopTest();

        System.assertEquals( 0, caseService.openClearQueueProcessingHaltedCaseCallCount, 'caseService.openClearQueueProcessingHalted() was called' );
        System.assertEquals( endTime, dao.configs.get( minuteScheduleConfig.Id ).End_Date_Time__c, 'The config\'s End Time was updated' );
    }


    @IsTest
    public static void testFSLScheduleShouldRunTaskThisMinute_Interval_1_TaskRun () {

        FSL_Schedule fslSchedule = new FSL_Schedule(); 
        FSL_Minute_Schedule_Task__mdt config = new FSL_Minute_Schedule_Task__mdt();
        config.Repeat_Interval_Minutes__c = 1;
        Boolean answer = fslSchedule.ShouldRunTaskThisMinute(config);
        System.assertEquals(answer, true);
    }

    @IsTest
    public static void testFSLScheduleShouldRunTaskThisMinute_Interval_2and3_TaskRunAsExpected () {

        FSL_Schedule fslSchedule = new FSL_Schedule();

        Integer interval = 2;
        FSL_Minute_Schedule_Task__mdt config = new FSL_Minute_Schedule_Task__mdt();
        config.Repeat_Interval_Minutes__c = interval;
        Boolean answer = fslSchedule.ShouldRunTaskThisMinute(config);
        Boolean expected = (Math.mod((Integer)(DateTime.now().getTime() / 1000 / 60), interval) == 0);  
        System.assertEquals(answer, expected);

        interval = 3;
        config.Repeat_Interval_Minutes__c = interval;
        answer = fslSchedule.ShouldRunTaskThisMinute(config);
        expected = (Math.mod((Integer)(DateTime.now().getTime() / 1000 / 60), interval) == 0);
        System.assertEquals(answer, expected);
    }


    @IsTest
    public static void testFSLScheduleExecuteCheckAndLockWorkOrders_NoException_TaskPerformed () {

        Test.startTest();
        FSL_Schedule fslSchedule = new FSL_Schedule();
        fslSchedule.clearQueuedCallFactory = new FSL_ClearQueuedCallTest.FactoryMock();
        fslSchedule.workOrderFactory = new FSL_WorkOrderTest.FactoryMock();
        fslSchedule.serviceLineItemFactory = new FSL_ServiceLineItemTest.FactoryMock();

        fslSchedule.executeCheckAndLockWorkOrders();

        Test.stopTest();

    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_Schedule.IFactory {
        public FSL_Schedule.IMinuteScheduleTaskDAO dao = new MinuteScheduleTaskDAOMock();
        public Integer createMinuteScheduleDAOCallCount = 0;
        public FSL_Schedule.IMinuteScheduleTaskDAO createMinuteScheduleDAO() {
            createMinuteScheduleDAOCallCount++;
            return dao;
        }

        public Integer createServiceCallCount = 0;
        public FSL_Schedule.IMinuteScheduleService service = new MinuteScheduleServiceMock();
        public FSL_Schedule.IMinuteScheduleService createService() {
            ++createServiceCallCount;
            return service;
        }
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType FSL_MINUTE_SCHEDULE_TASK_TYPE = FSL_Minute_Schedule_Task__mdt.getSObjectType();
    public class MinuteScheduleTaskDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Schedule.IMinuteScheduleTaskDAO {
        public Map<Id, FSL_Minute_Schedule_Task__mdt> configs;
        public Boolean isSuccess = true;

        public MinuteScheduleTaskDAOMock() {
            super( new Map<Id, FSL_Minute_Schedule_Task__mdt>(), FSL_MINUTE_SCHEDULE_TASK_TYPE );
            this.configs = (Map<Id, FSL_Minute_Schedule_Task__mdt>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from MinuteScheduleTaskDAOMock' );
            }
        }

        public List<FSL_Minute_Schedule_Task__mdt> fetchActiveScheduledTasks() {
            isQueryException();
            List<FSL_Minute_Schedule_Task__mdt> result = new List<FSL_Minute_Schedule_Task__mdt>();
            Datetime n = Datetime.now();
            for( FSL_Minute_Schedule_Task__mdt config : configs.values() ) {
                if( config.Start_Date_Time__c <= n && config.End_Date_Time__c >= n ) {
                    result.add( config );
                }
            }
            return result;
        }

        public List<FSL_Minute_Schedule_Task__mdt> fetchScheduledTasksByMasterLabel( String masterLabel ) {
            isQueryException();
            List<FSL_Minute_Schedule_Task__mdt> result = new List<FSL_Minute_Schedule_Task__mdt>();
            Datetime n = Datetime.now();
            for( FSL_Minute_Schedule_Task__mdt config : configs.values() ) {
                if( config.MasterLabel == masterLabel ) {
                    result.add( config );
                }
            }
            return result;
        }
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class MinuteScheduleServiceMock implements FSL_Schedule.IMinuteScheduleService {
        public Integer haltClearQueueProcessingDueToPotentialOutageCallCount = 0;
        public Boolean throwsException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in MinuteScheduleServiceMock' );
            }
        }

        public void haltClearQueueProcessingDueToPotentialOutage( FSL_Case.ICaseService caseService ) {
            haltClearQueueProcessingDueToPotentialOutageCallCount++;
            throwExceptionIfConfigured();
        }
    }

    @isTest
    public static void testMinuteScheduleServiceMock_HaltClearQueueProcessingDueToPotentialOutage_NoException_CallCountIncremented() {
        MinuteScheduleServiceMock service = new MinuteScheduleServiceMock();

        System.assertEquals( 0, service.haltClearQueueProcessingDueToPotentialOutageCallCount );

        Test.startTest();
        service.haltClearQueueProcessingDueToPotentialOutage( null );
        Test.stopTest();

        System.assertEquals( 1, service.haltClearQueueProcessingDueToPotentialOutageCallCount );
    }

    @isTest
    public static void testMinuteScheduleServiceMock_HaltClearQueueProcessingDueToPotentialOutage_Exception_ExceptionThrownAndCallCountIncremented() {
        MinuteScheduleServiceMock service = new MinuteScheduleServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.haltClearQueueProcessingDueToPotentialOutageCallCount );

        Test.startTest();
        try {
            service.haltClearQueueProcessingDueToPotentialOutage( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.haltClearQueueProcessingDueToPotentialOutageCallCount );
    }
}