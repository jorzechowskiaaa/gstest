@IsTest
public with sharing class FSL_PurgeScheduleTest {
    // FIXME: This is bad practice. The Unit Test should use the scheduler
    // However, there seems to be an issue with triggering the scheduler
    // Until the issue is solved, use the bad practice test to validate the code
    @IsTest
    static void testExecute_BadPracticeButUseUntilBugWithSchedulerIsFixed() {
        FSL_PurgeSchedule schedule = new FSL_PurgeSchedule();
        FactoryMock factory = new FactoryMock();
        PurgeScheduleTaskDAOMock dao = new PurgeScheduleTaskDAOMock();
        factory.dao = dao;
        schedule.scheduleFactory = factory;
        
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Application Log Purge', Days_to_retain__c = 12, Max_Records__c = 21 ) );
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Optimization Data Purge', Days_to_retain__c = 23, Max_Records__c = 32 ) );
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Orphan Member Contact Purge', Days_to_retain__c = 34, Max_Records__c = 43 ) );
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Resource Absence Purge', Days_to_retain__c = 45, Max_Records__c = 54 ) );
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Task Purge', Days_to_retain__c = 45, Max_Records__c = 54 ) );
        dao.activeScheduledTasks.add( new FSL_Purge_Scheduled_Task__mdt( MasterLabel = 'Resource Preference Purge', Days_to_retain__c = 45, Max_Records__c = 54 ) );
        
        Test.startTest();
        schedule.execute( null );
        Test.stopTest();
                        
        System.assertEquals( true, schedule.executed );
        System.assertEquals( 6, schedule.configCount );
    }
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreatePurgeScheduleDAO_NotNull() {
        FSL_PurgeSchedule.IFactory factory = new FSL_PurgeSchedule.Factory();

        Test.startTest();
        FSL_PurgeSchedule.IPurgeScheduleTaskDAO dao = factory.createPurgeScheduleDAO();
        Test.stopTest();

        System.assertNotEquals( null, dao );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testPurgeSchedulTaskDAO_GetActiveScheduledTasks_CoverageOnly() {
        // Since Custom Metadata cannot be inserted without a release, this test is only for coverage of the class
        FSL_PurgeSchedule.IPurgeScheduleTaskDAO dao = new FSL_PurgeSchedule.PurgeScheduleTaskDAO();

        Test.startTest();
        List<FSL_Purge_Scheduled_Task__mdt> configs = dao.getActiveScheduledPurgeTasks();
        Test.stopTest();
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_PurgeSchedule.IFactory {
        public FSL_PurgeSchedule.IPurgeScheduleTaskDAO dao = new PurgeScheduleTaskDAOMock();
        public Integer createPurgeScheduleDAOCallCount = 0;
        public FSL_PurgeSchedule.IPurgeScheduleTaskDAO createPurgeScheduleDAO() {
            createPurgeScheduleDAOCallCount++;
            return dao;
        }

        public FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        public Integer createClearQueuedCallServiceCallCount = 0;
        public FSL_ClearQueuedCall.IClearQueuedCallService createClearQueuedCallService() {
            createClearQueuedCallServiceCallCount++;
            return clearQueuedCallService;
        }
    }

    @isTest
    public static void testFactoryMock_CreatePurgeScheduleDAO_NotNullAndCallCountIncremented() {
        FactoryMock factory = new FactoryMock();

        System.assertEquals( 0, factory.createPurgeScheduleDAOCallCount );

        Test.startTest();
        FSL_PurgeSchedule.IPurgeScheduleTaskDAO dao = factory.createPurgeScheduleDAO();
        Test.stopTest();

        System.assertNotEquals( null, dao );
        System.assertEquals( 1, factory.createPurgeScheduleDAOCallCount );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    public class PurgeScheduleTaskDAOMock implements FSL_PurgeSchedule.IPurgeScheduleTaskDAO {
        public List<FSL_Purge_Scheduled_Task__mdt> activeScheduledTasks = new List<FSL_Purge_Scheduled_Task__mdt>();
        public Integer getActiveScheduledTasksCallCount = 0;
        public List<FSL_Purge_Scheduled_Task__mdt> getActiveScheduledPurgeTasks() {
            getActiveScheduledTasksCallCount++;
            return activeScheduledTasks;
        }
    }

    @isTest
    public static void testPurgeScheduleTaskDaoMock_GetActiveScheduledPurgeTasks_ConfiguredListReturnedAndCallCountIncremented() {
        List<FSL_Purge_Scheduled_Task__mdt> expected = new List<FSL_Purge_Scheduled_Task__mdt>();
        expected.add( new FSL_Purge_Scheduled_Task__mdt() );
        expected.add( new FSL_Purge_Scheduled_Task__mdt() );
        PurgeScheduleTaskDAOMock dao = new PurgeScheduleTaskDAOMock();
        dao.activeScheduledTasks = expected;

        System.assertEquals( 0, dao.getActiveScheduledTasksCallCount );

        Test.startTest();
        List<FSL_Purge_Scheduled_Task__mdt> actual = dao.getActiveScheduledPurgeTasks();
        Test.stopTest();

        System.assertEquals( expected, actual );
        System.assertEquals( 1, dao.getActiveScheduledTasksCallCount );
    }
}