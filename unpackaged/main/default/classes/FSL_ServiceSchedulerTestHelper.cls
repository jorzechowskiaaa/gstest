public class FSL_ServiceSchedulerTestHelper {

    public static void test_successfulFirstPolicy() {
        
        List<Behavior> actions = new List<Behavior>(); //send empty list to always return successful

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_successfulFirstPolicy'));

        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);

    }

    public static void test_firstPolicyNoCandidateFound() {
        
        List<Behavior> actions = new List<Behavior>();
        actions.add(Behavior.ThrowNoCandidateFoundException);
        
        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);  
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_firstPolicyNoCandidateFound'));

        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);

    }

    public static void test_firstPolicyRowLockRecovery() {
        List<Behavior> actions = new List<Behavior>();
        actions.add(Behavior.ThrowRowLockException);

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_firstPolicyRowLockRecovery'));
        
        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_firstPolicyRowLockException() {
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfRowLockExceptionsToThrow = maxRetries + 1;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < numberOfRowLockExceptionsToThrow; i++) {
            actions.add(Behavior.ThrowRowLockException);
        }

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_firstPolicyRowLockException'));

        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_firstPolicyRowLock_SecondPolicyException() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfRowLockExceptionsToThrow = maxRetries + 1;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < numberOfRowLockExceptionsToThrow; i++) {
            actions.add(Behavior.ThrowRowLockException);
        }
        actions.add(Behavior.ThrowException);


        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_firstPolicyRowLock_SecondPolicyException'));
        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_allPoliciesRowLock() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfRowLockExceptionsToThrow = (maxRetries + 1) * NumOfPolicies;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < numberOfRowLockExceptionsToThrow; i++) {
            actions.add(Behavior.ThrowRowLockException);
        }


        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_allPoliciesRowLock'));

        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_rowLockTwiceThenNoCandidate() {
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;
        integer numberOfRowLockExceptionsToThrow = (maxRetries + 1) * 2;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < numberOfRowLockExceptionsToThrow * 2; i++) {
            actions.add(Behavior.ThrowRowLockException);
        }
        actions.add(Behavior.ThrowNoCandidateFoundException);

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_rowLockTwiceThenNoCandidate'));

        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_allPolicyExceptions() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < NumOfPolicies; i++) {
            actions.add(Behavior.ThrowException);
        }

        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_allPolicyExceptions'));
        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_allPolicyNoCandidateFound() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < NumOfPolicies; i++) {
            actions.add(Behavior.ThrowNoCandidateFoundException);
        }


        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_allPolicyNoCandidateFound'));
        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    public static void test_finalPolicyNoCandidateFoundWithPreviousError() {
        
        FSL_Row_Lock_Retry_Configuration__mdt retryConfiguration = FSL_ServiceScheduler.GetRetryConfiguration();
        integer maxRetries = retryConfiguration.Enabled__c ? (integer)retryConfiguration.Maximum_Retries__c : 0;

        List<Behavior> actions = new List<Behavior>();
        for (Integer i = 0; i < NumOfPolicies-1; i++) {
            actions.add(Behavior.ThrowException);
        }
        actions.add(Behavior.ThrowNoCandidateFoundException);


        FSL_ServiceScheduler.DTO dto = generateTestData(PolicyNames_First, PolicyNames_Second, PolicyNames_Third);                   
        FSL_ServiceScheduler sched  = new FSL_ServiceScheduler(dto, new MockScheduleService(actions, 'test_finalPolicyNoCandidateFoundWithPreviousError'));
        FSL_AppointmentScheduleQueueable appointmentQueueable =  new FSL_AppointmentScheduleQueueable(sched);
        System.enqueueJob(appointmentQueueable);
    }

    private static final string PolicyNames_First = 'First Policy';
    private static final string PolicyNames_Second ='Second Policy';
    private static final string PolicyNames_Third = 'Third Policy';
    private static final integer NumOfPolicies = 3;

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

    private static FSL__Scheduling_Policy__c createPolicy(string policyName) {
        if(policyName == null)
            return null;

        FSL__Scheduling_Policy__c p = new FSL__Scheduling_Policy__c();
        p.Id = getFakeId(FSL__Scheduling_Policy__c.SObjectType);
        p.Name = policyName;

        return p;
    }

    //khanh move this to utility class
    private static String getFakeId(Schema.SObjectType sot) {
        Integer s_num = Integer.valueOf(123456789*Math.random());
          String result = String.valueOf(s_num++);
          return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
    }   


    public enum Behavior {
        ReturnSuccessful,
        ThrowException,
        ThrowNoCandidateFoundException,
        ThrowRowLockException
    }

    public class MockScheduleService implements FSL_ServiceScheduler.IScheduleService {
        protected FSL_ServiceScheduler.TestConfig mTestConfig;
        private List<Behavior> actions;
        private Datetime startTime;
        private Datetime endTime;

        public MockScheduleService(List<Behavior> actions, string testName) {
            this.actions = actions;
            this.mTestConfig = new FSL_ServiceScheduler.TestConfig(true, testName);
            this.startTime = this.endTime = Datetime.now(); //So null check is not needed
        }

        public FSL_ServiceScheduler.TestConfig TestConfig() {
            return mTestConfig;
        }

        public Datetime startTime() {
            return startTime;
        }
        public Datetime endTime() {
            return endTime;
        }

        public Boolean Schedule(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {
            return handleBehavior(schedulingPolicy, scheduleAppointment);
        }

        public Boolean ScheduleExtended(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {
            return handleBehavior(schedulingPolicy, scheduleAppointment);
        }

        Boolean handleBehavior(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {

            startTime = Datetime.now();

            try {
                if(actions.size() != 0) {
                    switch on actions.remove(0) {
                        when ThrowException  {
                            throw new CalloutException(); //throw a random exception
                        }
                        when ThrowNoCandidateFoundException  {
                            throw new FSL_CustomExceptions.NoCandidateFoundException();
                        }
                        when ThrowRowLockException  {
                            throw new FSL_CustomExceptions.ExclusiveRowLockException();
                        }
                    }
                }
            } finally {
                endTime = Datetime.now();
            }

            return true;
        }
    }

    private void forAnnonymousApexTesting() {

        //Select the code block below, hit F1, type apex, then select SFDX: Execute Anonymous Apex with Currently Selected Text
        //Check results in application logs

        FSL_ServiceSchedulerTestHelper.test_allPolicyNoCandidateFound();
        FSL_ServiceSchedulerTestHelper.test_firstPolicyNoCandidateFound();
        FSL_ServiceSchedulerTestHelper.test_firstPolicyRowLockRecovery();
        FSL_ServiceSchedulerTestHelper.test_firstPolicyRowLockException();
        FSL_ServiceSchedulerTestHelper.test_firstPolicyRowLock_SecondPolicyException();
        FSL_ServiceSchedulerTestHelper.test_successfulFirstPolicy();
        FSL_ServiceSchedulerTestHelper.test_finalPolicyNoCandidateFoundWithPreviousError();
        FSL_ServiceSchedulerTestHelper.test_allPolicyExceptions();
        FSL_ServiceSchedulerTestHelper.test_allPoliciesRowLock();
        FSL_ServiceSchedulerTestHelper.test_rowLockTwiceThenNoCandidate();
    }
}