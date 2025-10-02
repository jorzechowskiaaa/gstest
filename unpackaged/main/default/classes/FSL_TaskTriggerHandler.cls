/*****
*@Name:FSL_TaskTriggerHandler
*@Description: Class is to check for violations like PTA,Enroute,Dispatched..etc.
*@CreatedDate:01-Aug-2019
* Ver       Date            Author              Modification
*       12/02/2020        Clement Shiu     ERS-220415 - Optimization helper refractoring
*****/


    //  ***    Service Tech Team: This class is retired    ***


public class FSL_TaskTriggerHandler { // extends FSL_TriggerDispatcher.TriggerHandlerBase {

//     List<Task> newList = Trigger.new;
//     List<Task> oldList = Trigger.old;
//     Map<Id, Task> newMap = (Map<Id, Task>)Trigger.newMap;
//     Map<Id, Task> oldMap = (Map<Id, Task>)Trigger.oldMap;

//     //========================================================================================================================
//     //========================================================================================================================
    // public override Boolean isDisabled() {
    //     return FSL_TriggerUtility.isDisabled('Task');
    // }

//     //========================================================================================================================
//     //========================================================================================================================
//     public override void beforeInsert() {
//         updateRecordType(newList);
//     }

//     //========================================================================================================================
//     //========================================================================================================================
//     public override void afterInsert() {
//         try{
        
//             Set<Id> spottedViolationWOIdSet = new Set<Id>();
//             Set<Id> dispatchedViolationWOIdSet = new Set<Id>();
//             Set<Id> enRouteViolationWOIdSet = new Set<Id>();
//             set<Id> onLocationViolationWOId = new set<Id>();
//             set<Id> inTowViolationWOId = new set<Id>(); 
//             set<Id> towCompleteViolationWOId = new set<Id>(); 
//             Map<Id, String> dispatchedWarningWOIdMessageMap = new Map<Id, String>();
//             Map<Id, String> enRouteWarningWOIdMessageMap = new Map<Id, String>();
//             Map<Id, String> inTowWarningWOIdMessageMap = new Map<Id, String>();
//             Map<Id, String> onLocationWarningWOIdMessageMap = new Map<Id, String>();
//             Map<Id, String> towCompleteWarningWOIdMessageMap = new Map<Id, String>();                       
//             Set<Id> clearPostWOIdSet = new Set<Id>();
//             Map<Id,String>clearMessage = new Map<Id, String>();
//             Set<Id> canceledWOIdSet = new Set<Id>();
//             Map<Id,String>canceledWOIdMessageMap = new Map<Id, String>();
//             set<Id> InViolationTaskIds = new set<Id>();
//             set<Id> InViolationWOIds = new set<Id>();
//             List<ETA_Notification__e> manualETAOverrideEventList = new List<ETA_Notification__e>();
//             //pull the WO fields
//             //map<ID, WorkOrder> WOMap = new map<ID, WorkOrder>([select id, In_Jeopardy__c from WorkOrder where ID IN :WOIds]);
            
//             list<ID> finalviolatedwoIds = new list<Id>();
//             list<ID> finalwarnedwoIds = new list<Id>();
            
//             List<ServiceAppointment> sAppointmentList = new List<ServiceAppointment>();
            
//             // Based on the milestone name, seggregate the logic          
//             for(Task t : newList) {
//                 if(T.WhatId.getSObjectType() == workorder.sObjectType){
//                     if(t.subject == 'Dispatched Warning') {
//                         dispatchedWarningWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'En Route Warning') {
//                         enRouteWarningWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'On Location Warning') {
//                         onLocationWarningWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'In Tow Warning') {
//                         inTowWarningWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Tow Complete Warning') {            
//                         towCompleteWarningWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'In Tow Violation') {
//                         inTowViolationWOId.add(t.whatId);
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject=='Spotted Violation') {
//                         spottedViolationWOIdSet.add(t.whatId); 
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Dispatched Violation') {
//                         dispatchedViolationWOIdSet.add(t.whatId);    
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'En Route Violation') {
//                         enRouteViolationWOIdSet.add(t.whatId);
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'On Location Violation') {
//                         onLocationViolationWOId.add(t.whatId);
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Canceled Warning') {
//                         canceledWOIdMessageMap.put(t.whatId, milestoneNamesMap.get(t.subject).User_Message_Id__c);
//                         finalwarnedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Canceled Violation') {
//                         canceledWOIdSet.add(t.whatId);
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Tow Complete Violation') {
//                         towCompleteViolationWOId.add(t.whatId);
//                         finalviolatedwoIds.add(t.whatId);
//                     }else if(t.subject == 'Clear Action') {
//                         clearPostWOIdSet.add(t.whatId);
//                     }else if(t.subject == 'Dispatched Escalation' || t.subject == 'En Route Escalation' || t.subject == 'In Tow Escalation' || t.subject == 'Spotted Escalation' || t.subject == 'Tow Complete Escalation' || t.subject == 'On Location Escalation'){
//                         InViolationTaskIds.add(t.id);
//                         InViolationWOIds.add(t.whatid);
//                     }
//                 }
//             }
//             // end trigger logic
            
        
//             // ***  Service Tech Team: Commented out Milestone Warning Posts as they're not needed anymore   ***

//             //WARNINGs start here
//             // if(!dispatchedWarningWOIdMessageMap.isEmpty()) {
//             //     postWarningMessage(dispatchedWarningWOIdMessageMap, DISPATCHED_STATUS+' Warning'); 
//             // }
//             // if(!enRouteWarningWOIdMessageMap.isEmpty()) {
//             //     postWarningMessage(enRouteWarningWOIdMessageMap, EN_ROUTE_STATUS+' Warning');                    
//             // }
//             // if(!onLocationWarningWOIdMessageMap.isEmpty()){
//             //     postWarningMessage(onLocationWarningWOIdMessageMap, ON_LOCATION_STATUS+' Warning');
//             // }
//             // if(!inTowWarningWOIdMessageMap.isEmpty()){
//             //     postWarningMessage(inTowWarningWOIdMessageMap, IN_TOW_STATUS+' Warning');                    
//             // }
//             // if(!towCompleteWarningWOIdMessageMap.isEmpty()){
//             //     postWarningMessage(towCompleteWarningWOIdMessageMap, TOW_COMPLETE_STATUS+' Warning');                    
//             // }

//             if(!canceledWOIdMessageMap.isEmpty()){
//                 //postWarningMessage(canceledWOIdMessageMap, CANCELED_STATUS+' Warning');
//                 Map<id,WorkOrder> workOrderData=new Map<id,WorkOrder>([Select id,Service_Resource__r.RelatedRecordid,Service_Resource__r.RelatedRecord.IsActive  from WorkOrder Where id in :canceledWOIdMessageMap.keyset()]);
//                 CustomNotificationType notificationType = [SELECT Id, DeveloperName 
//                                                            FROM CustomNotificationType 
//                                                            WHERE DeveloperName='Notification_to_Driver_about_Member_Cancelling_the_Service'];
//                 List<FSL_User_Message__c> messageList = [Select id, Message_Id__c, Message_Text__c FROM FSL_User_Message__c WHERE Message_Id__c = 'SM-040'];                    
//                 Map<Id,ServiceAppointment> serviceappointmentMap =new Map<id,ServiceAppointment> ([select id, AppointmentNumber, ParentRecordId 
//                                                                    from ServiceAppointment 
//                                                                    where parentrecordid in :canceledWOIdMessageMap.keyset()]);
//                     for(ServiceAppointment sa :serviceappointmentMap.values()){
//                         if(!messageList.isempty() && (workOrderData.get(sa.ParentRecordId).Service_Resource__r.RelatedRecord.IsActive)){
//                             Messaging.CustomNotification notification = new Messaging.CustomNotification();
//                             notification.setTitle('SA#:' + sa.AppointmentNumber);
//                             notification.setBody(messageList[0].Message_Text__c);
//                             notification.setNotificationTypeId(notificationType.Id);
//                             notification.setTargetId(sa.ParentRecordId);
//                             Set<String> addressee = new Set<String>();
//                             addressee.add(workOrderData.get(sa.ParentRecordId).Service_Resource__r.RelatedRecordid);
//                             notification.send(addressee);
//                         }
//                     }
//                 String statusWarning = CANCELED_STATUS+' Warning';
//                 FSL_SLA_Violation.createSLAViolHistoryForWarning(canceledWOIdMessageMap, statusWarning);
//             }

//             //VIOLATIONs start here
//             if(!spottedViolationWOIdSet.isEmpty()) {
//                 Set<String> jiopardyReasonsToAvoid = new Set<String>{'No Candidates Found','No Lat/Long'};

//                 for(ServiceAppointment  sp : [SELECT Id, FSL__InJeopardy__c,FSL__InJeopardyReason__c, ParentRecordId 
//                                                   FROM ServiceAppointment 
//                                                   WHERE ParentRecordId IN : spottedViolationWOIdSet AND (NOT FSL__InJeopardyReason__c IN: jiopardyReasonsToAvoid)]) {
//                                                       System.debug('FSL__InJeopardyReason__c===>'+sp.FSL__InJeopardyReason__c);
//                                                       sp.FSL__InJeopardy__c = true;
//                                                       sp.FSL__InJeopardyReason__c = SPOTTED_STATUS+' Violation';                        
//                                                       sAppointmentList.add(sp);
//                                                   }
//             }
            
//             if(!dispatchedViolationWOIdSet.isEmpty()) {
//                 Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
                
//                 for(ServiceAppointment  sp : [SELECT Id,AppointmentNumber,RecordTypeId,SchedStartTime,SchedEndTime, Subject, FSL__InJeopardy__c, ParentRecordId,ETA__c
//                                               FROM ServiceAppointment
//                                               WHERE ParentRecordId IN : dispatchedViolationWOIdSet]) {
//                                                   sp.FSL__InJeopardy__c = true;
//                                                   sp.FSL__InJeopardyReason__c = DISPATCHED_STATUS+' Violation';
                                                  
//                                                   sAppointmentList.add(sp);                    
                                                  
//                                                   if(sp.RecordTypeId == breakDownRecordTypeId){
//                                                       // UF-1652: Add the Warning Time + Violation Time for the Platform Event adjustment
//                                                       Decimal dispatchedWarning;
//                                                       Decimal dispacthedViolation;
//                                                       dispatchedWarning = milestoneNamesMap.get('Dispatched Warning').Time_Trigger_Minutes__c;
//                                                       dispacthedViolation = milestoneNamesMap.get('Dispatched Violation').Time_Trigger_Minutes__c;
                                                      
//                                                       Integer dispatchDelta = Integer.valueOf(dispatchedWarning + dispacthedViolation );
                                                      
//                                                       ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(sp, dispatchDelta, DISPATCHED_STATUS+' Violation', null, true, true, false, false);
//                                                       manualETAOverrideEventList.add(manualETAOverride);                      
//                                                   }
//                                               }
//             }
            
//             if(!inTowViolationWOId.isEmpty()) {
//                 for(ServiceAppointment sa : [SELECT Id, FSL__InJeopardy__c, ParentRecordId 
//                                              FROM ServiceAppointment 
//                                              WHERE ParentRecordId IN : inTowViolationWOId]) {
//                                                  sa.FSL__InJeopardy__c = true;
//                                                  sa.FSL__InJeopardyReason__c = IN_TOW_STATUS+' Violation';
//                                                  sAppointmentList.add(sa);
//                                              }
//             }
//             if(!canceledWOIdSet.isEmpty()) {
//                 for(ServiceAppointment sa : [SELECT Id, FSL__InJeopardy__c, ParentRecordId 
//                                             FROM ServiceAppointment 
//                                             WHERE ParentRecordId IN : canceledWOIdSet]) {
//                                                  sa.FSL__InJeopardy__c = true;
//                                                  sa.FSL__InJeopardyReason__c = CANCELED_STATUS+' Violation';
//                                                  sAppointmentList.add(sa);
//                                              }
//             }
            
//             //TOW COMPLETE and ON LOCATION VIOLATION WILL FOLLOW SAME LOGIC
//             if(!onLocationViolationWOId.isEmpty() || !towCompleteViolationWOId.isEmpty()) {
//                 //Pushing stacked calls to Violation time trigger minutes #https://urldefense.com/v3/__https://erstechnologies.atlassian.net/browse/UF-603__;!!ArZwysmuupPR!uYMTMM4P7x0HU9aNTSlQC7I338bJ0r1XtFLPKa4dniXC4adNeqVz-A3s-Bf9Ok67hEslvX5xgVDGtDhJELSyxW8kq5bWL95vDkubKY2S$
//                 set<ID> ViolatedWOIds = new set<id>();
//                 ViolatedWOIds.addAll(onLocationViolationWOId);
//                 ViolatedWOIds.addAll(towCompleteViolationWOId);
//                 List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
//                 string milestoneStatus ;
//                 Decimal duration ;
//                 Id prevRelWorkorderId = null;
//                 for(ServiceAppointment sa : [SELECT Id, FSL__InJeopardy__c,ParentRecordId,SchedEndTime,SchedStartTime, 
//                                              AppointmentNumber, Work_Order__r.worktype.EstimatedDuration,ETA__c 
//                                              FROM ServiceAppointment 
//                                              WHERE ParentRecordId IN : ViolatedWOIds]) {                    
//                                                  if(onLocationViolationWOId.contains(sa.ParentRecordId)){
//                                                      milestoneStatus = ON_LOCATION_STATUS+' Violation';
//                                                  }else if(towCompleteViolationWOId.contains(sa.ParentRecordId)){
//                                                      milestoneStatus = TOW_COMPLETE_STATUS+' Violation';
//                                                  }
//                                                  duration = milestoneNamesMap.get(milestoneStatus).Worktype_Duration__c;
                                                 
//                                                  if(duration != null) {  
//                                                      sa.FSL__InJeopardy__c = true;
//                                                      sa.FSL__InJeopardyReason__c = milestoneStatus; 
//                                                      if(prevRelWorkorderId  != sa.ParentRecordId) {                 
//                                                          Integer delta = Integer.valueOf((duration * sa.Work_Order__r.worktype.EstimatedDuration));
//                                                          sa.SchedEndTime = sa.SchedEndTime.addMinutes(delta);
//                                                          sa.FSL__InJeopardy__c = true;
//                                                          sa.FSL__InJeopardyReason__c = milestoneStatus;
//                                                          ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(sa, delta, milestoneStatus, null, true, false, false, false);
//                                                          manualETAOverrideEventList.add(manualETAOverride);
//                                                      }
//                                                      sAppointmentList.add(sa);                                
//                                                      prevRelWorkorderId = sa.ParentRecordId; 
//                                                  }                    
//                                              }
//             }
            
//             if(!enRouteViolationWOIdSet.isEmpty()) {
//                 List<ServiceAppointment> enrouteSAList = new List<ServiceAppointment>();
//                 Set<Id> parentWOIdSet = new Set<Id>();
//                 for(ServiceAppointment  sp : [SELECT Id, FSL__InJeopardy__c, ParentRecordId, ServiceTerritory.Facility_Number__c,
//                                                      Dispatched_Timestamp__c, LastModifiedDate, LastModifiedBy.Name, Scheduled_Timestamp__c, Spotted_Timestamp__c, Status,
//                                                      (SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.Driver_Id__c, ServiceResource.LocationId, ServiceAppointment.SchedStartTime,ServiceResource.Location.VIN__c, ServiceResource.Vehicle__r.Truck_Id__c
//                                                       FROM ServiceResources )
//                                               FROM ServiceAppointment
//                                               WHERE ParentRecordId IN : enRouteViolationWOIdSet]) {
//                     sp.FSL__InJeopardy__c = true;
//                     sp.FSL__InJeopardyReason__c = EN_ROUTE_STATUS+' Violation';
//                     parentWOIdSet.add(sp.ParentRecordId);
//                     enrouteSAList.add(sp);
//                     sAppointmentList.add(sp);
//                 }
                
//                 if(!enrouteSAList.isEmpty()) {
//                     try{
//                         //Getting new ETA for Enroute violation #https://urldefense.com/v3/__https://erstechnologies.atlassian.net/browse/UF-603__;!!ArZwysmuupPR!uYMTMM4P7x0HU9aNTSlQC7I338bJ0r1XtFLPKa4dniXC4adNeqVz-A3s-Bf9Ok67hEslvX5xgVDGtDhJELSyxW8kq5bWL95vDkubKY2S$
//                         Map<Id,WorkOrder> woIdMap = new Map<Id,WorkOrder>([Select Id,WorkOrderNumber,Status,Call_Id__c,External_Id__c,Call_Date__c,LastModifiedDate,Spotted_Timestamp__c,Scheduled_Timestamp__c,Dispatched_Timestamp__c FROM WorkOrder WHERE Id IN: parentWOIdSet]);
//                         for(ServiceAppointment saEnrViolation : enrouteSAList) {                    
//                             String servicingFacility = saEnrViolation.ServiceTerritory.Facility_Number__c;
//                             AssignedResource ar = null;
//                             if(saEnrViolation.ServiceResources != null && !saEnrViolation.ServiceResources.isEmpty()) {
//                                 ar = saEnrViolation.ServiceResources;
//                             }
//                             if(woIdMap.get(saEnrViolation.ParentRecordId) != null) {
//                                 FSL_ToD3Update.CalloutWrapperD3 wrapper = FSL_ToD3Update.wrapperBuilder(woIdMap.get(saEnrViolation.ParentRecordId), saEnrViolation, ar, servicingFacility);
//                                 callGetETA(String.valueOf(saEnrViolation.id), JSON.serializePretty(wrapper), woIdMap.get(saEnrViolation.ParentRecordId).Call_Id__c);
//                             }
//                         }
//                     }catch(Exception ex) {
//                         System.debug('Update failed. Error captured Enroute Violation : ' + ex.getMessage());
//                     }
//                 }
//             }
            
//             //update WO with the jeopardy flag set to true which will trigger the level 2 cases for dispatchers via milestone process
        
//             //   ***   Service Tech Team: Commented out as they only update WO's flags that will be removed   ***     
//             // if( !finalviolatedwoIds.isEmpty() ) {
//             //     FSL_SLA_Violation.WOJeopardyAPI(finalviolatedwoIds, true, 'Jeopardy');
//             // }
//             // if( !finalwarnedwoIds.isEmpty() ) {
//             //     FSL_SLA_Violation.WOJeopardyAPI(finalwarnedwoIds, true, 'Warning');
//             // }
            
//             if(!sAppointmentList.isEmpty()) {
//                 update sAppointmentList;
//             }
            
//             if (!manualETAOverrideEventList.isEmpty()) {
//                 List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(manualETAOverrideEventList);
//             }
//             //Create Case for all Escalations
//             if(!InViolationTaskIds.isEmpty()){
//                 createCase(InViolationTaskIds, InViolationWOIds);
//             }
//             if(!clearPostWOIdSet.isEmpty()) {
//                 Set<ServiceAppointment>saSet = new Set<ServiceAppointment>([SELECT Id, RecordType.Name FROM ServiceAppointment WHERE ParentRecordId IN: clearPostWOIdSet AND RecordType.Name = 'Breakdown']);
//                 for(ServiceAppointment sa : saSet) {
//                     clearMessage.put(sa.Id, 'SM-013');
//                 }
//                 FSL_ChatterUtilities.postThis(clearMessage);
//             }
//         }catch(exception ex){                
//             FSL_ApplicationLogCreator.calloutLogger('','', 'Exception: ' + ex.getMessage() + ' StackTrace: ' + ex.getStackTraceString(), '', true, '', '', 'FSL_TaskTriggerHandler.checkForSLAViolations');
//         }
//     }


//     //========================================================================================================================
//     //========================================================================================================================
//     //========================================================================================================================


//     public static final string SPOTTED_STATUS ='Spotted';
//     public static final string EN_ROUTE_STATUS ='En Route';
//     public static final string ON_LOCATION_STATUS ='On Location';
//     public static final string IN_TOW_STATUS ='In Tow';
//     public static final string TOW_COMPLETE_STATUS ='Tow Complete';
//     public static final string DISPATCHED_STATUS = 'Dispatched';
//     public static final string CANCELED_STATUS = 'Canceled';


//     public map<string, FSL_Milestone_Time_Trigger__c> milestoneNamesMap = new map<string, FSL_Milestone_Time_Trigger__c>();

//     public FSL_TaskTriggerHandler() {
//         for(FSL_Milestone_Time_Trigger__c milestoneConfig : FSL_Milestone_Time_Trigger__c.getall().values()){
//             milestoneNamesMap.put(milestoneConfig.Milestone_Name__c, milestoneConfig);
//         }
//     }
    
//     @TestVisible
//     private void updateRecordType (List<Task> newTasksList) {
//         ID taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('WO Milestone Task').getRecordTypeId();        
//         for(Task t : newTasksList) {
//             //since the subject name of the task will be same as the milestone name in the custom setting 
//             if(milestoneNamesMap.keyset().contains(t.subject))
//             {
//                 t.recordtypeId = taskRecTypeId;
//             }
//         }
//         system.debug('newTasksList-'+newTasksList);
//     }

//     // ***  Service Tech Team: Commented out Milestone Warning Posts as they're not needed anymore   ***
    
    // public static void postWarningMessage(Map<Id, String> warningWOIDMap, string warningStatus){
    //     //FSL_ChatterUtilities.postThis(warningWOIDMap);
    //     List <Mobile_Notification_Event__e> mobileEventList = new List <Mobile_Notification_Event__e>();
    //     for(string WOID : warningWOIDMap.keyset()){
    //         Mobile_Notification_Event__e mEvent = new Mobile_Notification_Event__e();
    //         mEvent.Work_Order_Id__c = WOID ;
    //         mEvent.Message_Id__c =  warningWOIDMap.get(WOId);
    //         mobileEventList.add(mEvent);
    //     }
    //     if (!mobileEventList.isEmpty()) {
    //         EventBus.publish(mobileEventList);
    //     }
    //     FSL_SLA_Violation.createSLAViolHistoryForWarning(warningWOIDMap, warningStatus);        
    // }    

//     @future(callout=true)
//     public static void callGetETA(String saId, String wrapperJson, String callId) {
//         FSL_ToGlympseCallout.getEta(saId,wrapperJson,callId);
//     }
//     // end handler logic
    
//     //Create Case for the Violated work orders    
//     public static void createCase(set<Id> InViolationTaskIds, set<Id> InViolationWOIds){
//         system.debug('InViolationTaskIds '+InViolationTaskIds);
//         list <Task> tasks = [select id, whatid,what.type, subject from Task where ID IN :InViolationTaskIds];
//         list<Case> cases  = new list<Case>();
        
//         //map of <workorderid, serviceappointment>
//         map <Id,ServiceAppointment> SAWOMap = new map<Id,ServiceAppointment>();
        
//         for(ServiceAppointment sa : [select id, serviceterritoryId, ContactId, ParentrecordId, Parentrecord.Name, Service_Resource__c,
//                                      FSL__InJeopardyReason__c
//                                      from ServiceAppointment 
//                                      where ParentrecordId IN :InViolationWOIds and 
//                                      recordtype.name='Breakdown'])
//         {
//             SAWOMap.put(sa.ParentrecordId, sa);
//         }
        
//         list<Group> ownersQueue = [select Id,name from Group where Type = 'Queue' AND DeveloperNAME = 'FSL_Violation_Handlers'];
//         Set<String> jeopardyReasonList = new Set<String>();
//         Set<Id> workOrderIdSet = new Set<Id>();
//         for(Task t : tasks){           
//             Case c = new Case(subject = 'WO#'+SAWOMap.get(t.whatid).Parentrecord.Name+' - '+SAWOMap.get(t.whatid).FSL__InJeopardyReason__c, 
//                               FSL_work_Order__c = t.whatid, 
//                               ContactId = SAWOMap.get(t.whatid).ContactId,
//                               status='New', 
//                               Origin='Milestone Violation', 
//                               priority='Medium', 
//                               recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Violation Resolution').getRecordTypeId(),
//                               FSL_Service_Appointment_Territory__c = SAWOMap.get(t.whatid).serviceterritoryId,
//                               FSL_Service_Appointment__c = SAWOMap.get(t.whatid).id,
//                               FSL_Service_Resource__c = SAWOMap.get(t.whatid).Service_Resource__c,
//                               ownerid = ownersQueue[0].id,
//                               FSL_In_Jeopardy_Reason__c = SAWOMap.get(t.whatid).FSL__InJeopardyReason__c
//                              );
//             cases.add(c);
//             workOrderIdSet.add(t.whatid);
//             jeopardyReasonList.add(SAWOMap.get(t.whatid).FSL__InJeopardyReason__c);
//         }
//         System.debug('*********Before Inserting Cases******'+System.now());
//         insert cases;
//         List<FSL_SLA_Violation_History__c> saHistToUpdateList = new List<FSL_SLA_Violation_History__c>();
//         System.debug('workOrderIdSet===>'+workOrderIdSet);
//         System.debug('jeopardyReasonList===>'+jeopardyReasonList);
//         if(!workOrderIdSet.isEMpty()) {
//             for(FSL_SLA_Violation_History__c saVilHist : [Select id,FSL_Reason__c,FSL_Work_Order__c,FSL_Case__c from FSL_SLA_Violation_History__c where FSL_Work_Order__c IN : workOrderIdSet AND FSL_Reason__c IN : jeopardyReasonList AND FSL_Case__c = null]) {
//                 for(Case insertedCase : cases) {
//                     if(saVilHist.FSL_Work_Order__c == insertedCase.FSL_work_Order__c && insertedCase.FSL_In_Jeopardy_Reason__c == saVilHist.FSL_Reason__c) {
//                         saVilHist.FSL_Case__c = insertedCase.Id;
//                         saHistToUpdateList.add(saVilHist);
//                     }
//                 }
//             }
//             if(!saHistToUpdateList.isEmpty()) {
//                 update saHistToUpdateList;
//             }
//         }
//     }
}