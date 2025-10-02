/**
 *  Helper class to schedule appointments in future calls 
 * @Modification Log   : 
 * Ver       Date            Author                 Modification 
 *       12/09/2020      Clement Shiu    ERS-220415 - Optimization helper refractoring
**/
global without sharing class FSL_AppointmentScheduleHelper{


    public static void callScheduleService(ID policyID, ID scheduleAppointmentID){
       FSL.ScheduleService.Schedule(policyID, scheduleAppointmentID);
    }

     /**********
    * @Method Name:    shiftAppointments
    * @Parameters:     Map<ServiceAppointment, Integer> appointmentToTimeSavedMap, DateTime threshold
    * @Return:         void
    * @Description:    Shifts all appointments scheduled past the recently completed appointment earlier in the schedule, based on time saved
      @Author:         Ryan Johnson
    * **********/      
   public static void shiftAppointments(Map<ServiceAppointment, Integer> appointmentToTimeSavedMap, Map<ID, Boolean> appointmentToRunRSO, Map<ID, Boolean> appointmentToRunInDay){
       List<ETA_Notification__e> completedApppointmentETAList = new List<ETA_Notification__e>();
       for(ServiceAppointment completedSA : appointmentToTimeSavedMap.keySet()){
         // TODO: Make this check on record type
         if(completedSA.subject.contains('Tow') || completedSA.FSL__Related_Service__c == null){
               boolean runRSO = appointmentToRunRSO.containsKey(completedSA.Service_Resource__c) ? true : false;
               boolean runInDay = appointmentToRunInDay.containsKey(completedSA.Service_Resource__c) ? true : false;              
               ETA_Notification__e completedAppointmentNotification;
               if(completedSA.status=='Canceled'){
                   completedAppointmentNotification = FSL_OptimizationHelper.createETAPlatformEvent(completedSA, appointmentToTimeSavedMap.get(completedSA) * -1, 'Canceled Call', null, false, false, runRSO, runInDay);
               }else{
                   string etaType='Call Completed';
                   if((appointmentToTimeSavedMap.get(completedSA) * -1) >= 0){
                       etaType = 'Call Completed Late';
                   }else if((appointmentToTimeSavedMap.get(completedSA) * -1)< 0){
                       etaType = 'Call Completed Early';
                   }
                   completedAppointmentNotification = FSL_OptimizationHelper.createETAPlatformEvent(completedSA, appointmentToTimeSavedMap.get(completedSA) * -1, etaType, null, true, false, runRSO, runInDay);
               }
               
               completedApppointmentETAList.add(completedAppointmentNotification);            
         }
       }
       
       if(!completedApppointmentETAList.isEmpty()){
         List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(completedApppointmentETAList);
       }
    
       
   }
       
    /**********
    * @Method Name:    makeFutureScheduleAdjustment
    * @Parameters:     Set<ID> saAptIDs, Map<AssignedResource, Decimal> newScheduleDelta
    * @Return:         void
    * @Description:    Shifts all appointments to account for an adjusted drive time based on address change
    * @Author:         Ryan Johnson
    * **********/    
    public static void handleAddressChangeTraveTimelUpdates(Set<ID> saAptIDs, Map<AssignedResource, Decimal> newScheduleDelta){
       system.debug('+-+- in handleAddressChangeTraveTimelUpdates +-+-');
       FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
       Map<ServiceAppointment, Id> appointmentToResourceMap = new Map<ServiceAppointment, Id>();
       List<ServiceAppointment> saList = [SELECT id, Address_Changed__c, SchedStartTime, FSL__Related_Service__c, SchedEndTime, Schedule_Delta__c, ETA__c, 
                                   AppointmentNumber FROM ServiceAppointment WHERE id IN :saAptIDs AND Address_Changed__c = true];
       
           if(!saList.isEmpty()){
             List<ETA_Notification__e> addressChangeNotificationList = new List<ETA_Notification__e>();
             
             // update the match based on ETA delta
             for(AssignedResource ar : newScheduleDelta.keyset()){
                 for(ServiceAppointment sa : saList){
                   if(ar.ServiceAppointmentID == sa.id){
                   // create platform events
                       Integer deltaVal = Integer.valueOf(newScheduleDelta.get(ar));
                       // TODO: Add RSO threshold check for deltaVal
                       Boolean runRSO = false;
                       Boolean runInDay = false;
                       if(math.abs(deltaVal) > oSettings.In_Day_Gap_Threshold__c){
                           runInDay = true;
                       }
                       else if(math.abs(deltaVal) > oSettings.RSO_Threshold__c){
                           runRSO = true;
                       }

                       ETA_Notification__e addressChangeNotification = FSL_OptimizationHelper.createETAPlatformEvent(sa, deltaVal, 'Address Changed', null, false, true, runRSO, runInDay);                      
                       addressChangeNotificationList.add(addressChangeNotification);
                         
                       // if the eta has reduced, add service resource to have their schedule filled in
                       if(Integer.valueOf(newScheduleDelta.get(ar)) < 0){
                           FSL_ApplicationLogCreator.calloutLogger('*+*+ travel time changed for ' + sa, 'reducing by ' + String.valueOf(Integer.valueOf(newScheduleDelta.get(ar))) + ' minutes', '', 'update', false, '', '', 'Drive Time Reduced');
                       }
                         
                     }
                 }
             }
             
             if(!addressChangeNotificationList.isEmpty()){
               List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(addressChangeNotificationList);
             }
           
           }
    }
    
}