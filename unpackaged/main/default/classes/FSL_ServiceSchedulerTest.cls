/**
 * @File Name          : FSL_ServiceScheduler
 * @Description        :  
 * @Modification Log   : 
 * Ver      Date            Author             Modification
 * 1.0      11/11/2020      Khanh Tran         Intial Version
**/

@isTest
public class FSL_ServiceSchedulerTest {

    private static final Integer numOfPolicies = 3;

    private class MockInstrumentationConfigService implements FSL_Instrumentation.IConfigService {
        private Boolean bEnabled;

        public MockInstrumentationConfigService(Boolean bEnabled) {
            this.bEnabled = bEnabled;
        }
        public FSL_Instrumentation_Setting__mdt getSettings(String name) {
        
            FSL_Instrumentation_Setting__mdt setting = new FSL_Instrumentation_Setting__mdt();
            setting.Enabled__c = bEnabled;
            setting.Label = name;
    
            return setting;
        }
    }

    @isTest
    private static void test_successfulFirstPolicyWithInstrumentationLog() {
        FSL_Instrumentation.configService = new MockInstrumentationConfigService(true);
        Integer appLogSize = doTest_successfulFirstPolicy();
        System.assert(appLogSize == 1);
    }

    @isTest
    private static void test_successfulFirstPolicyWithoutInstrumentationLog() {
        FSL_Instrumentation.configService = new MockInstrumentationConfigService(false);
        Integer appLogSize = doTest_successfulFirstPolicy();
        //System.assert(appLogSize == 0);
    }

    private static Integer doTest_successfulFirstPolicy(){
        
        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>(); //send empty list to always return successful

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_successfulFirstPolicy'));

        Test.starttest();


        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        System.assert(sched.ScheduledPolicyName == PolicyNames_First);

        Test.stoptest();
        
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c WHERE Operation__c = 'Scheduling'];

        return apLogs.size();
    }

    @isTest
    private static void test_successfulSecondPolicy(){

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>(); //send empty list to always return successful

        FSL_ServiceScheduler.DTO dto = generateTestData(null, PolicyNames_Second, null);        
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_successfulSecondPolicy'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        System.assert(sched.ScheduledPolicyName == PolicyNames_Second);
        Test.stoptest();         
    }

    @isTest
    private static void test_successfulThirdPolicy(){

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>(); //send empty list to always return successful

        FSL_ServiceScheduler.DTO dto = generateTestData(null, null, PolicyNames_Third);
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_successfulThirdPolicy'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        System.assert(sched.ScheduledPolicyName == PolicyNames_Third);
        Test.stoptest();         
    }

    @isTest
    private static void test_allNullPolicies(){
        
        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>(); //send empty list to always return successful

        FSL_ServiceScheduler.DTO dto = generateTestData(null, null, null);
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_allNullPolicies'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_CONFIG);
        Test.stoptest();         
    }

    @isTest
    private static void test_firstPolicyException() {

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowException);
        
        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);  
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_firstPolicyException'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        System.assert(sched.ScheduledPolicyName == PolicyNames_Second);
        Test.stoptest();         
    }

    @isTest

    private static void test_firstPolicyNoCandidateException() {

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowNoCandidateFoundException);
        
        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);  
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_firstPolicyNoCandidateException'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        System.assert(sched.ScheduledPolicyName == PolicyNames_Second);
        Test.stoptest();
    }

    @isTest
    private static void test_firstPolicyRowLockRecovery() {
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        
        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowRowLockException);

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_firstPolicyRowLockRecovery'));

        Test.starttest();
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        if(retryConfiguration.Enabled__c) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
            System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        } else {
            System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK);
        }
        System.assert(sched.ScheduledPolicyName == PolicyNames_First);
        Test.stoptest();
    }
    
    @isTest
    private static void test_firstPolicyRowLockException() {
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfExceptionsToThrow = maxRetries + 1;

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        for (Integer i = 0; i < numberOfExceptionsToThrow; i++) {
            actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowRowLockException);
        }

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_firstPolicyRowLockException'));
      

        Test.starttest();

        for (Integer i = 0; i < maxRetries; i++) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        }
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK);

        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);

        System.assert(sched.ScheduledPolicyName == PolicyNames_Second);
        
        Test.stoptest();
    }

    @isTest

    private static void test_firstPolicyRowLock_SecondPolicyException() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfExceptionsToThrow = maxRetries + 1;

        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        for (Integer i = 0; i < numberOfExceptionsToThrow; i++) {
            actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowRowLockException);
        }
        actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowException);


        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_firstPolicyRowLock_SecondPolicyException'));

        Test.starttest();

        for (Integer i = 0; i < maxRetries; i++) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        }
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK);


        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_UNKNOWN_EXCEPTION);

        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);
        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.SUCCESS);
        
        System.assert(sched.ScheduledPolicyName == PolicyNames_Third);

        Test.stoptest();

    }


    @isTest
    private static void test_allPoliciesRowLock() {
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;


        List<FSL_ServiceSchedulerTestHelper.Behavior> actions = new List<FSL_ServiceSchedulerTestHelper.Behavior>();
        for (Integer i = 0; i < (maxRetries+1) * numOfPolicies; i++) {
            actions.add(FSL_ServiceSchedulerTestHelper.Behavior.ThrowRowLockException);
        }

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new FSL_ServiceSchedulerTestHelper.MockScheduleService(actions, 'test_allPoliciesRowLock'));

        Test.starttest();

        for (Integer i = 0; i < maxRetries; i++) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        }
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);

        for (Integer i = 0; i < maxRetries; i++) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        }
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_NEXT_POLICY);

        for (Integer i = 0; i < maxRetries; i++) {
            System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY);
        }
        System.assert(sched.scheduleCall() == FSL_ServiceScheduler.FinalStatus.STAT_DONE);

        System.assert(sched.currentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK);

        Test.stoptest();
    }

    //=========================================================================================================================
    //Apex doesn't allow static variables to be declared in inner class :(
    private static final string PolicyNames_First = '1st Policy';
    private static final string PolicyNames_Second ='2nd Policy';
    private static final string PolicyNames_Third = '3rd Policy';
    
    //khanh move this to utility class
    private static String getFakeId(Schema.SObjectType sot) {
        Integer s_num = Integer.valueOf(123456789*Math.random());
          String result = String.valueOf(s_num++);
          return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
    }   

    private static FSL__Scheduling_Policy__c createPolicy(string policyName) {
        if(policyName == null)
            return null;

        FSL__Scheduling_Policy__c p = new FSL__Scheduling_Policy__c();
        p.Id = getFakeId(FSL__Scheduling_Policy__c.SObjectType);
        p.Name = policyName;

        return p;
    }

            
    private static FSL_ServiceScheduler.DTO generateTestData(string strSchedulingPolicies, string strFirstRetrySchedulingPolicy, string strReSchedulingPolicy) {

        FSL_ServiceScheduler.DTO dto = new FSL_ServiceScheduler.DTO();

        dto.schedulingPolicy = createPolicy(strSchedulingPolicies);
        dto.firstRetrySchedulingPolicy = createPolicy(strFirstRetrySchedulingPolicy);
        dto.reSchedulingPolicy = createPolicy(strReSchedulingPolicy);

        dto.scheduleAppointment = new ServiceAppointment();
        dto.scheduleAppointment.Id = getFakeId(ServiceAppointment.SObjectType);
        dto.relatedAppointment = new ServiceAppointment();
        dto.relatedAppointment.Id = getFakeId(ServiceAppointment.SObjectType);

        return dto;
    }
}