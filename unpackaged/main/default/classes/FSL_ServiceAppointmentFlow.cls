/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-05-2021
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-15-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
 * 2.0   08-30-2021   ERS-225103 Part#2 Automate Reroute Process on Decline Call in Field Service for Tow Call
**/
public class FSL_ServiceAppointmentFlow {   

     @InvocableMethod
     public static List<Boolean> reScheduleServiceApptToSecondarySeviceTerritory(List<List<Id>> serviceApptIDs ){         
      List<Boolean> returnVals = new List<Boolean>();
           try{
                // Get the Scheduler Policy Object = FSL__Scheduling_Policy__c          
                FSL_ServiceAppointmentFlow.IFactory factory = new FSL_ServiceAppointmentFlow.Factory();        
                FSL_ServiceAppointmentFlow.IServiceAppointmentFlowService  service = factory.createService();
           
                // Validate result
                returnVals =  service.reScheduleServiceApptToSecondarySeviceTerritory(serviceApptIDs[0]);  
                
           }catch (Exception e) {
                returnVals.add(false);
           }
           return returnVals;
     }
 
     
      // *********************************************
      // * Factory
      // *********************************************
      public interface IFactory {
           IServiceAppointmentFlowService createService();        
      }
 
      public class Factory implements IFactory {
           public IServiceAppointmentFlowService createService() {               
                return new ServiceAppointmentFlowService();
           }  
      }
 
      // *********************************************
      // * Service
      // *********************************************
      public interface IServiceAppointmentFlowService {                 
 
           List<Boolean> reScheduleServiceApptToSecondarySeviceTerritory(List<Id> serviceApptIDs);
      }
 
      public class ServiceAppointmentFlowService implements IServiceAppointmentFlowService {     
           private FSL_ServiceScheduler.IScheduleService reschedulerService;

           public ServiceAppointmentFlowService() {               
           }

           public ServiceAppointmentFlowService(FSL_ServiceScheduler.IScheduleService reSchedulerService) {
               this.reschedulerService = reschedulerService;
           }
 
           public List<Boolean> reScheduleServiceApptToSecondarySeviceTerritory(List<Id> serviceApptIDs) {   
 
                FSL_SchedulingPolicy.IFactory factory = new FSL_SchedulingPolicy.Factory();   
                FSL_SchedulingPolicy.ISchedulingPolicyService  service = factory.createService();
 
                string schedPolicyName = 'Automated Reroute Policy';
                FSL__Scheduling_Policy__c schedPolicy = service.getSchedulingPolicy(schedPolicyName);            
                System.debug('SchedPolicy = ' + schedPolicy);
 
                return doReschedule(new FSL_ServiceAppointmentFlow.Rescheduler(this.reschedulerService, schedPolicy, serviceApptIds));        
           }
           @testVisible
           private List<Boolean> doReschedule(FSL_ServiceAppointmentFlow.Scheduler rescheduler) {
                List<Boolean> returnVals =  new List<Boolean>();
                Boolean isSucessful = rescheduler.doSchedule();
                returnVals.add(isSucessful);
 
                return returnVals ;
                
           }
      }
      
      @testVisible
      private abstract class Scheduler {
          
           private FSL__Scheduling_Policy__c policy;
           private List<Id> serviceAppointmentIds;   
           protected FSL_ServiceScheduler.IScheduleService serviceRescheduler;
 
           public Scheduler (FSL_ServiceScheduler.IScheduleService serviceRescheduler, FSL__Scheduling_Policy__c policy, List<Id> serviceAppointmentIds) {
                this.policy = policy;
                this.serviceAppointmentIds = serviceAppointmentIds;
                this.serviceRescheduler = serviceRescheduler == null ? new RescheduleService(new FSL_ServiceScheduler.TestConfig(false, '')) : serviceRescheduler;
           }
          
           public virtual  Boolean doSchedule(){
                List<FSL.ScheduleResult> scheduleResults = new List<FSL.ScheduleResult>();
           
                Boolean isSuccess = false;
                if(serviceAppointmentIds.size()> 1 && String.isNotBlank(serviceAppointmentIds[1])) {
                     isSuccess = serviceRescheduler.ScheduleExtended(policy, new ServiceAppointment(Id = serviceAppointmentIds[0]));
                } else {
                    isSuccess = serviceRescheduler.Schedule(policy, new ServiceAppointment(Id = serviceAppointmentIds[0]));
                }
                return isSuccess;
           }
 
      }
      @testVisible
      private class Rescheduler extends Scheduler {
           public Rescheduler (FSL_ServiceScheduler.IScheduleService serviceScheduler, FSL__Scheduling_Policy__c policy, List<Id> serviceAppointmentIds) {
                super(serviceScheduler, policy, serviceAppointmentIds);
           }
      }
      
      @testVisible
      private class RescheduleService implements FSL_ServiceScheduler.IScheduleService {
           protected FSL_ServiceScheduler.TestConfig mTestConfig;
           private Datetime startTime;
           private Datetime endTime;
   
           public RescheduleService(FSL_ServiceScheduler.TestConfig testConfig) {
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
                   FSL.ScheduleResult res = FSL.ScheduleService.Schedule(fsl_schedulingPolicy.Id, scheduleAppointment.Id);
                   return res != null;        
           }
   
           public Boolean ScheduleExtended(FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment) {
                   List<FSL.ScheduleResult> resultList = FSL.ScheduleService.ScheduleExtended(fsl_schedulingPolicy.Id, scheduleAppointment.Id);
                   return resultList != null && resultList.isEmpty() == false;      
           }
       }
 }