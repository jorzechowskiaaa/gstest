/**
 * @File Name          : FSL_SLA_Violation.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 2/26/2020, 3:17:21 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/26/2020   Rajesh Kemisetti     Initial Version
**/
public without sharing class FSL_SLA_Violation {
    
    //   ***   Service Tech Team: PTA violation logic is moved to flow   *** 
    
    /**
    * Method name  : missingPTABy5Minutes
    * Description  : Sets the child service appointments in jeopardy if ScheduledStart -PTA => 5 minutes
    * Return Type  : None
    * Parameter    : Map<Id, WorkOrder>
    * Author       : Divyendra Naidu
    **/
    // public static void missingPTAByMinutes(List<ServiceAppointment> saList) {
    //     FSL_Settings__c mttc = FSL_Settings__c.getInstance('PTA Violation');
    //     Integer timeValue = Integer.valueOf(mttc.Value__c);
    //     System.debug('PTA Time Value = ' + timeValue + ' minutes');
    //     Id tow = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
    //     Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
    //     //List<ServiceAppointment> saList = new List<ServiceAppointment>([SELECT Id, PTA__c, ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE ParentRecordId IN:woIdSet]);
    //     List<ServiceAppointment> breakdownAppointmentList = new List<ServiceAppointment>();
    //     List<ServiceAppointment> towAppointmentList = new List<ServiceAppointment>();
    //     Set<ID> towSAIDs = new Set<ID>();
    //     for(ServiceAppointment sa : saList) {
    //         if(sa.recordTypeId == breakDownRecordTypeId){
    //             breakdownAppointmentList.add(sa);
    //         }else{
    //             towAppointmentList.add(sa);
    //             towSAIDs.add(sa.id);
    //         }
    //     }


    //     Map<Id,Boolean> woIdIsViolationMap = new Map<Id,Boolean>();
    //     for(ServiceAppointment sa : breakdownAppointmentList) {
    //         sa.FSL__InJeopardy__c = false;
    //         if(sa.PTA__c != null && sa.SchedStartTime != null){
    //             if(sa.SchedStartTime.getTime() >=  sa.PTA__c.addMinutes(timeValue).getTime()) {
    //                 sa.FSL__InJeopardy__c = true;
    //                 sa.FSL__InJeopardyReason__c = 'PTA Violation';
    //                 //sa.FSL__InJeopardyReason__c = ('Missing PTA by ' + ((sa.SchedStartTime.getTime() - sa.PTA__c.getTime())/60000) + ' minutes.');
    //             }
    //         }
    //     }
    //     List<ServiceAppointment> appointmentContainer = [SELECT id, FSL__Related_Service__r.SchedStartTime, FSL__Related_Service__r.PTA__c FROM ServiceAppointment WHERE id IN :towSAIDs];
    //     for(ServiceAppointment sa : towAppointmentList) {
    //         for(ServiceAppointment containerSA : appointmentContainer){
    //             if(sa.id == containerSA.id){
    //                 sa.FSL__InJeopardy__c = false;            
    //                 if(containerSA.FSL__Related_Service__r.SchedStartTime != null && containerSA.FSL__Related_Service__r.PTA__c != null && 
    //                     containerSA.FSL__Related_Service__r.SchedStartTime.getTime() >=  containerSA.FSL__Related_Service__r.PTA__c.addMinutes(timeValue).getTime())
    //                 {    
    //                     sa.FSL__InJeopardy__c = true;
    //                     sa.FSL__InJeopardyReason__c = 'PTA Violation';                          
    //                 }
    //             }
    //         }
    //     }
        
    // }

    /**
   * Method name  : clearJeopardy
   * Description  : Clears the jeopardy flag on the list of Service Appointments passed into it
   * Return Type  : None
   * Parameters   : List<ServiceAppointment>
   * Author       : Divyendra Naidu
   **/


    public static void clearJeopardy(List<ServiceAppointment> saList) {
        for(ServiceAppointment sa : saList) {
            sa.FSL__InJeopardy__c = false;
            sa.FSL__InJeopardyReason__c =null;
        }
    }
    
    /*@future   
    public static void clearJeopardy(List<ID> woIds) {
        List<WorkOrder> woList = [select id, In_Jeopardy__c from workorder where ID IN :woIds ];
        for(WorkOrder wo : woList) {
            wo.In_Jeopardy__c = false;
        }
        update woList;
    }*/    


    //   ***   Service Tech Team: Commented out the method as it's used only in Task trigger handler to update flags on WOs   *** 

   /* Callout is made to overcome the issue listed in below article w.r.t the milestones not visible even though criteria is met
    * https://help.salesforce.com/articleView?id=000329328&type=1&mode=1
    **/   
    // @future(callout=true)   
    // public static void WOJeopardyAPI(List<ID> woIds, boolean true_or_false, string operation) {
    //     List<WorkOrder> woList = new List<WorkOrder>();
        
    //     for(WorkOrder wi : [select id, In_Jeopardy__c from workorder where ID IN :woIds ]) {
    //         WorkOrder wo = new WorkOrder();            
    //         if(operation=='Warning'){
    //             wo.FSL_Milestone_Issued_Warning__c = true_or_false;
    //         }else if (operation=='Jeopardy'){
    //             wo.In_Jeopardy__c = true_or_false;
    //             //reset the warning when the jeopardy flag is reset
    //             if(!true_or_false){
    //                 wo.FSL_Milestone_Issued_Warning__c = false;
    //             }
    //         }
    //         wo.id = wi.id;
    //         woList.add(wo);
    //     }        
    //     FSL_Service_Endpoints__c clearEndpoint = FSL_Service_Endpoints__c.getValues('FSL_UPDATEWORKORDER');
    //     Http http = new Http();
    //     httprequest request = new httprequest();
    //     request.setEndpoint(clearEndpoint.Endpoint_URL__c);
    //     request.setMethod('POST');  
    //     request.setTimeout(integer.ValueOf(clearEndpoint.Timeout__c));
    //     request.setHeader('Content-Type', 'application/json');
    //     request.setHeader('Authorization', 'Bearer '+ UserInfo.getSessionId()); 
    //     string body = (string)JSON.serialize(woList);
    //     system.debug(body);
    //     request.setBody(body);
    //     if(!Test.isRunningTest()){
    //         FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
    //         List<FSL_ApplicationLog.ApplicationLog> appLogs = new List<FSL_ApplicationLog.ApplicationLog>();
    //         try {
    //             HttpResponse response = http.send(request);
    //             if (response.getStatusCode() != 200) {
    //                 WoJeopardyApiApplicationLog log = new WoJeopardyApiApplicationLog();
    //                 log.logFailedCalloutResult( body, response );
    //                 appLogs.add( log );
    //             }
    //         }
    //     	catch( CalloutException ex ) {
    //             WoJeopardyApiApplicationLog log = new WoJeopardyApiApplicationLog();
    //             log.logCalloutException( body, ex );
    //             appLogs.add( log );
    //         }
    //         catch( Exception ex ) {
    //             WoJeopardyApiApplicationLog log = new WoJeopardyApiApplicationLog();
    //             log.logException( body, ex );
    //             appLogs.add( log );
    //         }
    //         if( !appLogs.isEmpty() ) {
    //             appLogService.saveApplicationLogs( appLogs );
    //         }
    //     }
    // }
    

    //   ***   Service Tech Team: Commented out exceptions as they're used only in commented WOJeopardyAPI() method above   *** 

    // public class WoJeopardyApiApplicationLog extends FSL_ApplicationLog.ApplicationLog {
    //     public WoJeopardyApiApplicationLog() {
    //         super();
    //     }

    //     protected override void setDefaultApplicationLogFields() {
    //         appLog.Operation__c = 'WOJeopardyAPI';
    //         appLog.DateTime__c = System.now();
    //         appLog.RecordTypeId = generalRecordTypeId;
    //     }

    //     public void logFailedCalloutResult( String body, HttpResponse response ) {
    //         String errorMessage = 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus();
    //         logFailedResult( body, errorMessage );
    //         appLog.Response_Body__c = JSON.serializePretty( response.getBody() );
    //     }

    //     public void logCalloutException( String body, CalloutException ex ) {
    //         logFailedResult( body, 'The WOJeopardyAPI callout threw an CalloutException: ' );
    //         appendFormattedExceptionToErrorMessage( ex );
    //     }

    //     public void logException( String body, Exception ex ) {
    //         logFailedResult( body, 'The WOJeopardyAPI callout threw an Exception: ' );
    //         appendFormattedExceptionToErrorMessage( ex );
    //     }

    //     private void logFailedResult( String body, String errorMessage ) {
    //         appLog.Error_Caught__c = true;
    //         appLog.Request_Body__c = body;
    //         appLog.Error_Message__c = errorMessage;
    //     }
    // }

    public static void createSLAViolationHistory(List<ServiceAppointment> newAppointmentList,Map<Id,ServiceAppointment> oldMap) {
        Set<Id> workOrderIdSet = new Set<Id>();
        Map<Id,ServiceAppointment> workOrderIdAppointmentMap = new Map<Id,ServiceAppointment>();
        Map<Id,ServiceAppointment> reasonBlankWoSaMap = new Map<Id,ServiceAppointment>();
        Set<String> jeopardyReasonList = new Set<String>();
        List<FSL_SLA_Violation_History__c> slaViolationInsertList = new List<FSL_SLA_Violation_History__c>();
        Map<Id,Case> woCaseMap = new Map<Id,Case>();
        DateTime currentTime = System.now();
        Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();
        for (ServiceAppointment sa : newAppointmentList) {
            if (sa.recordTypeId != breakDownRecordTypeId) {
                continue;
            }

            if (oldMap != null) {
                ServiceAppointment oldSA = oldMap.get(sa.Id);
                if (sa.FSL__InJeopardy__c != oldSA.FSL__InJeopardy__c) {
                    if (sa.FSL__InJeopardy__c && !oldSA.FSL__InJeopardy__c) {
                        workOrderIdSet.add(sa.parentRecordId);
                        workOrderIdAppointmentMap.put(sa.parentRecordId, sa);
                        jeopardyReasonList.add(sa.FSL__InJeopardyReason__c);
                    } else if (!sa.FSL__InJeopardy__c && oldSA.FSL__InJeopardy__c) {
                        // reasonBlankWoSaMap.put(sa.parentRecordId,sa);
                        reasonBlankWoSaMap.put(sa.parentRecordId, oldSA);
                        jeopardyReasonList.add(sa.FSL__InJeopardyReason__c);
                        jeopardyReasonList.add(oldSA.FSL__InJeopardyReason__c);
                    }                  
                } else if (sa.FSL__InJeopardyReason__c != oldSA.FSL__InJeopardyReason__c &&
                           sa.FSL__InJeopardy__c && oldSA.FSL__InJeopardy__c)
                    {
                        workOrderIdSet.add(sa.parentRecordId);
                        workOrderIdAppointmentMap.put(sa.parentRecordId, sa);
                        reasonBlankWoSaMap.put(sa.parentRecordId, oldSA);
                        jeopardyReasonList.add(oldSA.FSL__InJeopardyReason__c);
                        jeopardyReasonList.add(sa.FSL__InJeopardyReason__c);
                    }
            } else if (sa.FSL__InJeopardy__c) {
                workOrderIdAppointmentMap.put(sa.parentRecordId, sa);
                workOrderIdSet.add(sa.parentRecordId);
                jeopardyReasonList.add(sa.FSL__InJeopardyReason__c);
            }
        }
        
        if (!workOrderIdSet.isEmpty()) {
            System.debug('jeopardyReasonList===>'+jeopardyReasonList);
            System.debug('workOrderIdSet===>'+workOrderIdSet);
            List<Case> casesList = [
                SELECT Id, FSL_work_Order__c,FSL_In_Jeopardy_Reason__c
                FROM Case
                WHERE FSL_In_Jeopardy_Reason__c IN :jeopardyReasonList AND FSL_work_Order__c IN :workOrderIdSet
            ];
            System.debug('casesList====>'+casesList);
            for(Id woId : workOrderIdAppointmentMap.keySet()) {
                for(Case cs : casesList) {
                    System.debug('woId==>'+woId+'==cs.FSL_work_Order__c==>'+cs.FSL_work_Order__c);
                    System.debug('workOrderIdAppointmentMap.get(woId).FSL__InJeopardyReason__c==>'+workOrderIdAppointmentMap.get(woId).FSL__InJeopardyReason__c+'==cs.FSL_In_Jeopardy_Reason__c==>'+cs.FSL_In_Jeopardy_Reason__c);
                    if(woId == cs.FSL_work_Order__c && workOrderIdAppointmentMap.get(woId).FSL__InJeopardyReason__c == cs.FSL_In_Jeopardy_Reason__c) {
                        woCaseMap.put(woId,cs);
                        break;
                    }
                }
                
            }
        }
        System.debug('woCaseMap===>'+woCaseMap);
        for(Id woId : workOrderIdAppointmentMap.keySet()) {
            ServiceAppointment sa = workOrderIdAppointmentMap.get(woId);
            FSL_SLA_Violation_History__c slaHistory = new FSL_SLA_Violation_History__c();
            slaHistory.FSL_Reason__c = sa.FSL__InJeopardyReason__c != null ? sa.FSL__InJeopardyReason__c : 'NULL value provided';
            slaHistory.FSL_Service_Resource__c = sa.Service_Resource__c;
            slaHistory.FSL_Service_Territory__c = sa.serviceTerritoryId;
            slaHistory.FSL_Work_Order__c = woId;
            if (slaHistory.FSL_Reason__c.contains('Warning')) {
                slaHistory.FSL_Type__c = 'Warning';
            } else {
                slaHistory.FSL_Type__c = 'Violation';
            }
            if (woCaseMap.containsKey(woId)) {
                slaHistory.FSL_Case__c = woCaseMap.get(woId).Id;
            }
            slaViolationInsertList.add(slaHistory);
        }

        List<FSL_SLA_Violation_History__c> historyToUpdateList = new List<FSL_SLA_Violation_History__c>();
        if (!reasonBlankWoSaMap.isEmpty()) {            
            List<FSL_SLA_Violation_History__c> slaViolHistList = [
                SELECT Id,FSL_Work_Order__c,FSL_Reason__c,FSL_Resolution_Time__c,FSL_User__c
                FROM FSL_SLA_Violation_History__c
                WHERE FSL_Work_Order__c IN :reasonBlankWoSaMap.keySet() AND FSL_Reason__c IN :jeopardyReasonList
                AND FSL_Resolution_Time__c = null
            ];
            for (Id woId : reasonBlankWoSaMap.keySet()) {
                for (FSL_SLA_Violation_History__c slaHist : slaViolHistList) {
                    if (slaHist.FSL_Work_Order__c == woId && slaHist.FSL_Reason__c == reasonBlankWoSaMap.get(woId).FSL__InJeopardyReason__c) {
                        slaHist.FSL_Resolution_Time__c = currentTime;
                        slaHist.FSL_User__c = reasonBlankWoSaMap.get(woId).LastModifiedById;
                        historyToUpdateList.add(slaHist);
                    }
                }
            }           
        }
        if (!slaViolationInsertList.isEmpty()) {
            insert slaViolationInsertList;
        }
        if (!historyToUpdateList.isEmpty()) {
            update historyToUpdateList;
        }
    }

    //  ***   Service Tech Team: Refactored createSLAViolHistoryForWarning() method below    ***
    
// public static void createSLAViolHistoryForWarning(Map<Id,String> warningMap,String warningMesg) {
//     List<String> woIdList = new List<String>();
    
//     Map<Id,Workorder> woMap = new Map<Id,WorkOrder>([Select id,serviceTerritoryId,Service_Resource__c from WorkOrder where Id IN : warningMap.keySet()]);
//     List<FSL_SLA_Violation_History__c> slaVolHistory = new List<FSL_SLA_Violation_History__c>();
//     for(Id woId : warningMap.keySet()) {
//         FSL_SLA_Violation_History__c slaHistory = new FSL_SLA_Violation_History__c();
//         slaHistory.FSL_Reason__c = warningMesg;
//         slaHistory.FSL_Service_Resource__c = woMap.get(woId).Service_Resource__c;
//         slaHistory.FSL_Service_Territory__c = woMap.get(woId).serviceTerritoryId;
//         slaHistory.FSL_Work_Order__c = woId;
//         slaHistory.FSL_Type__c='Warning';
//         //slaHistory. 
//         slaVolHistory.add(slaHistory);
//     }
//     if(!slaVolHistory.isEmpty()) {
//         insert slaVolHistory;
//     }
// }

    public static void createSLAViolHistoryForWarning(List<ServiceAppointment> saList) {
        List<FSL_SLA_Violation_History__c> slaVolHistory = new List<FSL_SLA_Violation_History__c>();
        for (ServiceAppointment sa : saList) {
            FSL_SLA_Violation_History__c slaHistory = new FSL_SLA_Violation_History__c();
            slaHistory.FSL_Reason__c = sa.FSL__InJeopardyReason__c;
            slaHistory.FSL_Service_Resource__c = sa.Work_Order__r.Service_Resource__c;
            slaHistory.FSL_Service_Territory__c = sa.Work_Order__r.ServiceTerritoryId;
            slaHistory.FSL_Work_Order__c = sa.Work_Order__c;
            slaHistory.FSL_Type__c = 'Violation';
            slaVolHistory.add(slaHistory);
        }

        if (!slaVolHistory.isEmpty()) {
            insert slaVolHistory;
        }
    }

}