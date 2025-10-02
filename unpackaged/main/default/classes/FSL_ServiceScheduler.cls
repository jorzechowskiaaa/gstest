/**
 * @File Name          : FSL_ServiceScheduler
 * @Description        :  
 * @Modification Log   : 
 * Ver      Date            Author             Modification
 * 1.0      11/11/2020      Khanh Tran         Refactored and replaced FSL_SchedulingHelper
 * 1.0      2/12/2020       Dylan Truong       ERS-221339 Hack simulate user remove and update address.
 * 1.0      5/12/2020       Khanh Tran         Added Instrumentation
 **/

public class FSL_ServiceScheduler {

    public class DTO {
        public FSL__Scheduling_Policy__c schedulingPolicy;
        public FSL__Scheduling_Policy__c firstRetrySchedulingPolicy;        
        public FSL__Scheduling_Policy__c reSchedulingPolicy;        
        public ServiceAppointment scheduleAppointment;
        public ServiceAppointment relatedAppointment;
        public Boolean isFromAutosceduleRetryBatch;  //AGB added for SSFI-560 11/19/24
    }

    public Enum CurrentStatus {
        SUCCESS,
        NO_CANDIDATE_FOUND,
        ERROR_ROW_LOCK,
        ERROR_CONFIG,
        ERROR_UNKNOWN_EXCEPTION
    }

    public Enum FinalStatus {
        STAT_DONE,
        STAT_CONTINUE_NEXT_POLICY,
        STAT_CONTINUE_ROWLOCK_RETRY
    }

    class PolicyResult {
        CurrentStatus status;
        String message;
        Exception ex;

        Integer rowLockCount = 0;

        Datetime managedStart;
        Datetime managedEnd;

        FSL_Instrumentation instrumentation;

        void setScheduleExecutionTimeWindow(Datetime startTime, Datetime endTime) {
            managedStart = startTime;
            managedEnd = endTime;
        }

        Long calculateTotalDuration() {
            return managedEnd.getTime() - managedStart.getTime();
        }

        Long calculateUnmanagedDuration() {
            return instrumentation.calculateTotalEntriesDuration();
        }


        String getUnmanagedDurationSummary() {
            return instrumentation.toStringSummary();
        }
        String getUnmanagedDurationDetails() {
            return instrumentation.toStringDetail();
        }
    }

    private PolicyResult[] mPolicyResults = new List<PolicyResult>();

    private DTO mDTO;
    private IScheduleService mScheduleService;
    private List<SchedulingPolicy> mPolicies = new List<SchedulingPolicy>();
    private FSL_Row_Lock_Retry_Configuration__mdt mRetryInfo;

    private SchedulingPolicy mCurrentPolicy;
    private Integer mCurrentPolicyIndex = 0;
    private FSL_ServiceScheduler.CurrentStatus mCurrentStatus = FSL_ServiceScheduler.CurrentStatus.SUCCESS;
    private Integer mRowLockRetryCount = 0;
    private Boolean mHasError = false;

    public FSL_ServiceScheduler(DTO dto) {
        this(dto, null);
    }

    public FSL_ServiceScheduler(DTO dto, IScheduleService scheduleService) {

        this.mDTO = dto;

        this.mScheduleService = scheduleService == null ? new ScheduleService(new TestConfig(false, '')) : scheduleService;

        this.mPolicies.add(new SchedulingPolicy(this.mScheduleService, dto.schedulingPolicy, dto.scheduleAppointment, dto.relatedAppointment));
        this.mPolicies.add(new FirstRetrySchedulingPolicy(this.mScheduleService, dto.firstRetrySchedulingPolicy, dto.scheduleAppointment, dto.relatedAppointment));
        this.mPolicies.add(new RetrySchedulingPolicy(this.mScheduleService, dto.reSchedulingPolicy, dto.scheduleAppointment, dto.relatedAppointment));
        
        for (Integer i = 0; i < this.mPolicies.size(); i++) {
            mPolicyResults.add(new PolicyResult());
        }

        mRetryInfo = GetRetryConfiguration();
    }

    // Returns true: done, false: need re-queuing request
    public FinalStatus scheduleCall() {
        try {

            FinalStatus status = doScheduleCall();

            if(status == FinalStatus.STAT_DONE) {
                if(mCurrentStatus != FSL_ServiceScheduler.CurrentStatus.SUCCESS) {
                    try {
                        handleNoCandidatesFound(mCurrentPolicy);
                    } catch (Exception ex) {
                        //khanh todo???
                    }
                } else {  //AGB added for SSFI-560 11/19/24
                    if (this.mDTO.isFromAutosceduleRetryBatch) {
                        try {
                            handleCheckIfScheduledFromBatch();
                        } catch (Exception ex) {
    
                        }
                    }
                }  //end AGB added for SSFI-560 11/19/24
                updateAppLog();
            } else if(status == FinalStatus.STAT_CONTINUE_NEXT_POLICY) {
                mCurrentPolicyIndex++; //point to next policy (if FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY continue with same policy)
            }
    
            return status;

        } catch (Exception ex) {

            logFatal(ex);

            return FinalStatus.STAT_DONE;

        }
    }

    private FinalStatus doScheduleCall() {

        if(mCurrentStatus == FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK) {
            //NOTE: delay at the start of this schedule after previous schedule rowlock to prevent adding time to managed code record locking transaction period
            delay((integer)this.mRetryInfo.Retry_Interval_In_Milliseconds__c);
        }

        PolicyResult entry = mPolicyResults[mCurrentPolicyIndex];
        entry.instrumentation = FSL_Instrumentation.createInstance(FSL_ServiceScheduler.class.getname());
        
        mCurrentPolicy = mPolicies[mCurrentPolicyIndex];

        mCurrentStatus = mCurrentPolicy.schedule(entry.instrumentation);

        mPolicyResults[mCurrentPolicyIndex].setScheduleExecutionTimeWindow(mScheduleService.startTime(), mScheduleService.endTime());

        switch on mCurrentStatus {

            when SUCCESS {
                queueInfo('SCHEDULED');
                return FinalStatus.STAT_DONE;
            }
            when NO_CANDIDATE_FOUND {
                queueInfo('No Candidate Found'); //NOTE: NO_CANDIDATE_FOUND is not treated as error
                return hasNextPolicy();
            }
            when ERROR_ROW_LOCK {
                if(mRetryInfo.Enabled__c) {
                    if(mRowLockRetryCount++ < (integer)this.mRetryInfo.Maximum_Retries__c) {
                        mPolicyResults[mCurrentPolicyIndex].rowLockCount = mRowLockRetryCount;
                        return FinalStatus.STAT_CONTINUE_ROWLOCK_RETRY;
                    } else {
                        queueError('Row-lock retries failed after ' + (integer)this.mRetryInfo.Maximum_Retries__c + ' attempts');
                        return hasNextPolicy();
                    }
                } else {
                    queueError('Row-lock error - Retry is currently disabled');
                    return hasNextPolicy();
                }
            }
            when ERROR_CONFIG {
                queueError('Configuration error: scheduling policy is NULL');
                return hasNextPolicy();
            }
            when ERROR_UNKNOWN_EXCEPTION {
                queueException(mCurrentPolicy.schedulingException);
                return hasNextPolicy();
            }
            when else {
                queueError('Coding error: unexpected status ' + mCurrentStatus.name());
                return hasNextPolicy();
            }
        }
    }

    public static FSL_Row_Lock_Retry_Configuration__mdt GetRetryConfiguration() {
        FSL_Row_Lock_Retry_Configuration__mdt entry;
        FSL_Row_Lock_Retry_Configuration__mdt[]  entries = [SELECT Enabled__c, Maximum_Retries__c, Retry_Interval_In_Milliseconds__c FROM FSL_Row_Lock_Retry_Configuration__mdt WHERE Label = 'Service Scheduling'];

        if(entries.size() > 0) {
            entry = entries[0];
        } else {
            entry = new FSL_Row_Lock_Retry_Configuration__mdt();
            entry.Enabled__c = false;
        }

        return entry;
    }

    public String ScheduledPolicyName {
        get {
            return mCurrentPolicy == null ? null : mCurrentPolicy.Name;
        }
    }

    public FSL_ServiceScheduler.CurrentStatus currentStatus {
        get {
            return mCurrentStatus;
        }
    }

    private FinalStatus hasNextPolicy() {
        mRowLockRetryCount = 0;
        //NOTE: do not increment mCurrentPolicyIndex here. Let outer method does it to properly handle fatal exception
        return (mCurrentPolicyIndex + 1) < mPolicies.size() ? FinalStatus.STAT_CONTINUE_NEXT_POLICY : FinalStatus.STAT_DONE;
    }

    private string createCalloutReq() {
        String calloutReq;
        if(mDTO.schedulingPolicy != null)
            calloutReq = 'Scheduling ' + mDTO.scheduleAppointment.Id + ' using the ' + mDTO.schedulingPolicy.name + ' Policy';
        else {
            calloutReq = 'Scheduling ' + mDTO.scheduleAppointment.Id + ' - There was no intial scheduling policy specified';
        }

        return calloutReq;
    }


    private FSL_ApplicationLogCreator.CalloutLoggerData createCalloutLoggerData() {
        FSL_ApplicationLogCreator.CalloutLoggerData data = new FSL_ApplicationLogCreator.CalloutLoggerData();
        
        if(!mScheduleService.TestConfig().isMocking) {
            try {
                data.callId = [SELECT Call_Id__c FROM WorkOrder WHERE ID =: mDTO.scheduleAppointment.parentRecordId LIMIT 1].Call_Id__c;
                data.serviceAppointmentId = mDTO.scheduleAppointment.Id;
                data.workOrderId = mDTO.scheduleAppointment.parentRecordId;
            } catch (Exception ex) {
                //Can be called by logFatal so ignore exception here
            }
        }
        

        data.apiName = FSL_Instrumentation.createApiName(FSL_ServiceScheduler.class.getName());
        data.operation = 'Scheduling';
        data.version = '';
        data.isError = false;
        data.calloutRequest = createCalloutReq();

        return data;
    
    }
    private void updateAppLog() {
        FSL_Instrumentation_Setting__mdt instrSettings = FSL_Instrumentation.LoadSettings(FSL_ServiceScheduler.class.getName());

        FSL_ApplicationLogCreator.CalloutLoggerData data = createCalloutLoggerData();

        FSL_Instrumentation.LineBuffer lnBuff = new FSL_Instrumentation.LineBuffer();

        if(mScheduleService.TestConfig().isMocking) {
            lnBuff.addline('Test Name: ' + mScheduleService.TestConfig().testName);
        }

        FSL_Instrumentation.LineBuffer statusSummary = new FSL_Instrumentation.LineBuffer();

        Long lastManagedDuration = 0;
        Long lastUnmanagedDuration = 0;

        for (Integer i = 0; i < mPolicies.size(); i++) {
            SchedulingPolicy p = mPolicies[i];
            PolicyResult result = mPolicyResults[i];
            
            if(result.status != null) {
                statusSummary.addLine((i+1) + '. ' + result.status.name());

                lnBuff.addLine('\n=====' + (i+1) + '. ' + p.Name + '=====');
                lnBuff.addLine('Status: ' + result.message);
                lnBuff.addLine('Rowlock Count: ' + result.rowLockCount);

                if(instrSettings.Enabled__c) {
              
                    //Get the latest unmanaged duration
                    Long totalDuration = result.calculateTotalDuration();
                    lastUnmanagedDuration = result.calculateUnmanagedDuration();
                    lastManagedDuration = totalDuration - lastUnmanagedDuration;
                    
                    lnBuff.addLine('\n--- Execution Summary ---\n');
                    lnBuff.addLine('Total Duration: ');
                    lnBuff.addline(result.managedStart.format('HH:mm:ss.SSS') + ' - ' + result.managedEnd.format('HH:mm:ss.SSS') + ' = ' + totalDuration);
                    lnBuff.addLine('Managed Exclusive Duration: ' + lastManagedDuration);
                    lnBuff.addLine('Unmanaged Exclusive Duration: ' + lastUnmanagedDuration);

                    lnBuff.addLine('\n--- Nested Triggers Summary ---');
                    lnBuff.addLine(result.getUnmanagedDurationSummary());

                    if(instrSettings.Detail_Level__c == 'Verbose') {
                        lnBuff.addLine('\n--- Nested Triggers Details ---');
                        lnBuff.addLine(result.getUnmanagedDurationDetails());
                        lnBuff.addLine();
                    }

                }

            }
        }

        String stackTrace = '';
        for (Integer i = 0; i < mPolicies.size(); i++) {
            SchedulingPolicy p = mPolicies[i];
            PolicyResult entry = mPolicyResults[i];
            
            Exception ex = entry.ex;
            if(ex != null) {
                stackTrace = stackTrace + '\n=====' + (i+1) + '. ' + p.Name + '=====\n\n';
                stackTrace = stackTrace + ex.getMessage() + '\n\n' + ex.getStackTraceString() + '\n\n';
            }
        }
        
        if(String.isNotBlank(stackTrace)) {
            lnBuff.addLine();
            lnBuff.addline('========== Stack Traces ==========');
            lnBuff.addline(stackTrace);
        }

        data.calloutResponse = lnBuff.toString();

        if(mCurrentStatus != FSL_ServiceScheduler.CurrentStatus.SUCCESS) {
            //NO_CANDIDATE_FOUND with no prior error will not be treat as error
            data.isError = (mCurrentStatus != FSL_ServiceScheduler.CurrentStatus.NO_CANDIDATE_FOUND) || mHasError;
        }

        data.message = statusSummary.toString();
        data.serviceTime = lastManagedDuration;
        data.outputProcessingTime = lastUnmanagedDuration;
        
        if(data.isError || instrSettings.Enabled__c)
            FSL_ApplicationLogCreator.calloutLogger(data);
    }

    private void logFatal(Exception ex) {
        FSL_ApplicationLogCreator.CalloutLoggerData data = createCalloutLoggerData();
        data.isError = true;
        data.message = 'Fatal Error: ' + ex.getMessage();
        data.calloutResponse = ex.getStackTraceString();

        FSL_ApplicationLogCreator.calloutLogger(data);
    }

    private void delay(Integer milliSec) {
        Long start = Datetime.now().getTime();
        while(Datetime.now().getTime() - start < milliSec);
    }

    private void queueInfo(string msg) {
        queueMessage(false, msg, null);
    }

    private void queueError(string msg) {
        queueMessage(true, msg, null);
    }
    
    private void queueException(Exception e) {
        queueMessage(true, e.getMessage(), e);
    }

    private void queueMessage(Boolean isError, string message, Exception ex) { 

        mHasError = mHasError ? true : isError; //don't change status if it's already true

        PolicyResult entry = mPolicyResults[mCurrentPolicyIndex];
        
        entry.status = mCurrentStatus;
        entry.message = message;
        entry.ex = ex;
    }

	private void handleCheckIfScheduledFromBatch() { //AGB added for SSFI-560 11/19/24
        ServiceAppointment saBreakdownCurrent = [SELECT Scheduled_by_Autoschedule_Retry_Batch__c FROM ServiceAppointment WHERE id = :mDTO.scheduleAppointment.Id];
        saBreakdownCurrent.Scheduled_by_Autoschedule_Retry_Batch__c = true;
        update saBreakdownCurrent;
        


    } //end AGB added for SSFI-560 11/19/24

    private void handleNoCandidatesFound(SchedulingPolicy currentPolicy) {

        System.debug('handleNoCandidatesFound - currentPolicy: ' + currentPolicy.Name);

        if(mScheduleService.TestConfig().isMocking == false) {

            ID retryPolicyID = currentPolicy == null ?
                null :
                currentPolicy == mPolicies[0] ?
                    null :
                    currentPolicy.fsl_schedulingPolicy == null ?
                        null :
                        currentPolicy.fsl_schedulingPolicy.Id; 
            
            ServiceAppointment saBreakdown = new ServiceAppointment();
            saBreakdown.Id = mDTO.scheduleAppointment.Id;
            /*saBreakdown.FSL__InJeopardyReason__c = 'No Candidates Found';
            saBreakdown.FSL__InJeopardy__c = true;*/
            
            ServiceAppointment saBreakdownCurrent = [SELECT id, ParentRecordId,FSL__Scheduling_Policy_Used__c FROM ServiceAppointment WHERE id = :mDTO.scheduleAppointment.Id];


            //====================================================================================================================================
            // NOTE:
            //   Previous code used:
            //      saBreakdown.FSL__Scheduling_Policy_Used__c
            //   instead of:
            //      saBreakdownCurrent.FSL__Scheduling_Policy_Used__c
            //   which doesn't make sense since saBreakdown.FSL__Scheduling_Policy_Used__c is unitialized before used
            //====================================================================================================================================

            // Boolean isPolicyChanged = retryPolicyID != null && retryPolicyID != saBreakdown.FSL__Scheduling_Policy_Used__c;
            Boolean isPolicyChanged = retryPolicyID != null && retryPolicyID != saBreakdownCurrent.FSL__Scheduling_Policy_Used__c;

    

            if(isPolicyChanged) {
                saBreakdown.FSL__Scheduling_Policy_Used__c = retryPolicyID;
            }
    
            List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();
            saListToUpdate.add(saBreakdown);
            
            if(mDTO.relatedAppointment != null) {
                ServiceAppointment saTow = new ServiceAppointment();
                saTow.id = mDTO.relatedAppointment.Id;
                /*saTow.FSL__InJeopardyReason__c = 'No Candidates Found';
                saTow.FSL__InJeopardy__c = true;*/
                if(isPolicyChanged) {
                    saTow.FSL__Scheduling_Policy_Used__c = retryPolicyID;
                }
                saListToUpdate.add(saTow);
            }
    
            update saListToUpdate;      
            
            WorkOrder wo = new WorkOrder();
            wo.id = saBreakdownCurrent.ParentRecordId;
            wo.In_Jeopardy__c = true;
            
            update wo;
        }
        
    }

    //=========================================================================================================================
    //=========================================================================================================================

    virtual class SchedulingPolicy {

        private IScheduleService scheduleService;

        private FSL__Scheduling_Policy__c fsl_schedulingPolicy;
        private ServiceAppointment scheduleAppointment;
        private ServiceAppointment relatedAppointment;

        public String Name { get { return fsl_schedulingPolicy == null ? 'No policy defined' : fsl_schedulingPolicy.Name; } }
        public Exception schedulingException { get; private set; }


        public SchedulingPolicy(IScheduleService scheduleService, FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment, ServiceAppointment relatedAppointment) {
            this.scheduleService = scheduleService;

            this.fsl_schedulingPolicy = fsl_schedulingPolicy;
            this.scheduleAppointment = scheduleAppointment;
            this.relatedAppointment = relatedAppointment;

        }

        public virtual FSL_ServiceScheduler.CurrentStatus schedule(FSL_Instrumentation instr) {
            CurrentStatus status = CurrentStatus.ERROR_CONFIG;

            try {
                instr.startInstrumenting();
                
                Boolean ok;
                if(fsl_schedulingPolicy != null) {
                    if(relatedAppointment != null) {
                        ok = scheduleService.ScheduleExtended(fsl_schedulingPolicy, scheduleAppointment);
                        instr.stopInstrumenting(); //Stop here. Don't want to instrument TempHack 

                        if(ok) {
                            TempHack(scheduleAppointment, relatedAppointment);
                        }
                    } else {
                        ok = scheduleService.Schedule(fsl_schedulingPolicy, scheduleAppointment);
                        instr.stopInstrumenting();
                    }

                    status = ok ? FSL_ServiceScheduler.CurrentStatus.SUCCESS : FSL_ServiceScheduler.CurrentStatus.NO_CANDIDATE_FOUND;
                }
            } catch(FSL_CustomExceptions.NoCandidateFoundException ex) {

                status = FSL_ServiceScheduler.CurrentStatus.NO_CANDIDATE_FOUND;

            } catch(FSL_CustomExceptions.ExclusiveRowLockException ex) {

                status = FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK;
                schedulingException = ex;

            } catch(Exception ex) {

                status = FSL_ServiceScheduler.CurrentStatus.ERROR_UNKNOWN_EXCEPTION;
                schedulingException = ex;
            } finally {
                instr.stopInstrumenting();
            }


            return status;
        }

        private void TempHack(ServiceAppointment scheduleAppointment, ServiceAppointment relatedAppointment) {
            // Dylan ERS-221339 Hack Code for Lat/Long
            if(scheduleService.TestConfig().isMocking == false) {
                if(scheduleAppointment.Latitude == relatedAppointment.Latitude && scheduleAppointment.Longitude == relatedAppointment.Longitude && FSL_AppointmentDependencyHelper.isQualifyAddress(relatedAppointment))
                {
                    ServiceAppointment towSa = [SELECT Id, Street FROM ServiceAppointment WHERE Id =:relatedAppointment.Id];
                    towSa.Street = '';
                    update towSa;
                    towSa.Street = relatedAppointment.Street;
                    update towSa;
                }    
            }

            // Dylan ERS-221339 HackCode for Lat/Long           
        }

    }


    //=========================================================================================================================

    class FirstRetrySchedulingPolicy extends SchedulingPolicy {

        public FirstRetrySchedulingPolicy(IScheduleService scheduleService, FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment, ServiceAppointment relatedAppointment) {
            super(scheduleService, fsl_schedulingPolicy, scheduleAppointment, relatedAppointment);
        }

        public override FSL_ServiceScheduler.CurrentStatus schedule(FSL_Instrumentation instr) {

            CurrentStatus status = CurrentStatus.ERROR_CONFIG;

            if(fsl_schedulingPolicy != null) {
                
                if(scheduleService.TestConfig().isMocking == false) {
                    try {
                        //NOTE: This will break logic in FSL_HandleOperationsOnSATriggerHandler if more than 1 service appointment are upserted
                        //      Please see logic in FSL_HandleOperationsOnSATriggerHandler.IsPolicyArrivalEndWindowUpdate()
                        if(this.scheduleAppointment.PTA__c > scheduleAppointment.ArrivalWindowStartTime) {
                            this.scheduleAppointment.ArrivalWindowEndTime = scheduleAppointment.PTA__c;
                            this.scheduleAppointment.Arrival_Window_End_Time_Update_Timestamp__c = System.Now();
                            upsert scheduleAppointment;
                        }
                    } catch (Exception ex) {
                        if(RowLockException(ex))
                            status = FSL_ServiceScheduler.CurrentStatus.ERROR_ROW_LOCK;
                        else
                            status = FSL_ServiceScheduler.CurrentStatus.ERROR_UNKNOWN_EXCEPTION;

                        schedulingException = ex;
                        return status; // return for row-lock retry or skip to next policy
                    }
                }

                status =  super.schedule(instr);
            }

            return status;
        }
    }


    //=========================================================================================================================

    class RetrySchedulingPolicy extends SchedulingPolicy {
        public RetrySchedulingPolicy(IScheduleService scheduleService, FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment, ServiceAppointment relatedAppointment) {
            super(scheduleService, fsl_schedulingPolicy, scheduleAppointment, relatedAppointment);
        }

        public override FSL_ServiceScheduler.CurrentStatus schedule(FSL_Instrumentation instr) {
            return super.schedule(instr);
        }
    }



    //=========================================================================================================================
    //=========================================================================================================================
    public static Boolean NoCandidateFoundException(Exception e, ServiceAppointment scheduleAppointment) {
        Boolean bNoCandidateFound = false;
        if(e.getMessage().contains('No candidates were found')) {
            WorkOrder woRec = [SELECT id, Priority_Code__c,Priority FROM WorkOrder WHERE id = :scheduleAppointment.parentRecordId];
            bNoCandidateFound = woRec.Priority !='Critical' && woRec.Priority !='High';
        }
        return bNoCandidateFound;
    }

    public static Boolean RowLockException(Exception e) {
        return e.getMessage().toUpperCase().contains('UNABLE_TO_LOCK_ROW')
        ||     e.getMessage().toUpperCase().contains('PLEASE TRY AGAIN');
    } 


    public class TestConfig {
        private Boolean mIsMocking;
        private string mTestName;

        public TestConfig(Boolean isMocking, string testName) {
            mIsMocking = isMocking;
            mTestName = testName;
        }

        public string testName { get { return mTestName; } }
        public Boolean isMocking { get { return mIsMocking; } }
    }

    public interface IScheduleService {
        Boolean Schedule(FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment);
        Boolean ScheduleExtended(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment);
        FSL_ServiceScheduler.TestConfig TestConfig();
        Datetime startTime();
        Datetime endTime();
    }

    private class ScheduleService implements IScheduleService {
        protected FSL_ServiceScheduler.TestConfig mTestConfig;
        private Datetime startTime;
        private Datetime endTime;

        public ScheduleService(FSL_ServiceScheduler.TestConfig testConfig) {
            this.mTestConfig = testConfig;
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


        public Boolean Schedule(FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment) {
            startTime = Datetime.now();
            try {
                FSL.ScheduleResult res = FSL.ScheduleService.Schedule(fsl_schedulingPolicy.Id, scheduleAppointment.Id);
                return res != null;        
            } catch (Exception ex) {
                if(NoCandidateFoundException(ex, scheduleAppointment))
                    throw new FSL_CustomExceptions.NoCandidateFoundException();
                if(RowLockException(ex))
                    throw new FSL_CustomExceptions.ExclusiveRowLockException();
                throw ex;
            } finally {
                endTime = Datetime.now();
            }
        }

        public Boolean ScheduleExtended(FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment) {
            startTime = Datetime.now();
            try {
                List<FSL.ScheduleResult> resultList = FSL.ScheduleService.ScheduleExtended(fsl_schedulingPolicy.Id, scheduleAppointment.Id);
                return resultList != null && resultList.isEmpty() == false;      
            } catch (Exception ex) {
                if(NoCandidateFoundException(ex, scheduleAppointment))
                    throw new FSL_CustomExceptions.NoCandidateFoundException();
                if(RowLockException(ex))
                    throw new FSL_CustomExceptions.ExclusiveRowLockException();
                throw ex;
            } finally {
                endTime = Datetime.now();
            }
        }
    }

}