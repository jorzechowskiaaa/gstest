/**
 * @File Name          : FSL_ServiceResourceTriggerHandler.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 01-23-2021
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    1/28/2020   Rajesh Kemisetti     Initial Version
 *       12/02/2020   Clement Shiu       ERS-220415: Optimization helper refractoring
 *       01/05/2020   Clement Shiu       ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
**/
public class FSL_ServiceResourceTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<ServiceResource> newList = Trigger.new;
    List<ServiceResource> oldList = Trigger.old;
    Map<Id, ServiceResource> newSRMap = (Map<Id, ServiceResource>)Trigger.newMap;
    Map<Id, ServiceResource> oldSRMap = (Map<Id, ServiceResource>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ServiceResource');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        Map<Id, ServiceResource> relevantMap = new Map<Id, ServiceResource>();
        Map<Id, ServiceResource> nullMap = new Map<Id, ServiceResource>();
        for(Id i : newSRMap.keySet()) {
            if(oldSRMap.get(i).Vehicle__c != newSRMap.get(i).Vehicle__c) {
                relevantMap.put(i, newSRMap.get(i));
            }
        }
        if(!relevantMap.isEmpty()) {
            FSL_ServiceResourceTriggerHandler.updateGanttLabel(relevantMap);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        system.debug('boolean after update check');
        Map<Id, ServiceResource> oldMap = new Map<Id, ServiceResource>();
        Map<Id, ServiceResource> newMap = new Map<Id, ServiceResource>();
        Set<Id> vehicleChangeResIdSet = new Set<Id>();
        Set<Id> lightSRIdSet = new Set<Id>();
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        for(ServiceResource sr: newList) {
            if(newSRMap.get(sr.Id).Vehicle__c != oldSRMap.get(sr.Id).Vehicle__c){
                oldMap.put(sr.Id, newSRMap.get(sr.Id));
                newMap.put(sr.Id, oldSRMap.get(sr.Id));
            }
            if((newSRMap.get(sr.Id).Vehicle__c != null && oldSRMap.get(sr.Id).Vehicle__c == null) 
                || (oldSRMap.get(sr.Id).Vehicle_Type__c != newSRMap.get(sr.Id).Vehicle_Type__c && newSRMap.get(sr.Id).Vehicle_Type__c != null)) {
                vehicleChangeResIdSet.add(sr.Id);
                if(newSRMap.get(sr.Id).Vehicle_Type__c == 'Light_Service') {
                    lightSRIdSet.add(sr.Id);
                }
            }
        }

        if(!newMap.isEmpty() && !oldMap.isEmpty()){
            System.debug('Entering Manipulate Skills ' + newMap + oldMap);
            FSL_VehicleSkills.assignVehicleSkills(newList);
            system.debug('SkillMethod******************'+newMap.size());
            //FSL_VehicleSkills.manipulateSkills(oldSRMap, newSRMap, 'update');
           //populateBearerTokenOnUser(JSON.serialize(newList),JSON.serialize(oldSRMap));
        }
        Set<String> statusesNotConsidered = new Set<String>{'Scheduled','Dispatched'};
        if(!lightSRIdSet.isEmpty()) {
            List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
            Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();
            for(ServiceAppointment sa : [Select Id,Status from ServiceAppointment where service_Resource__c IN : lightSRIdSet AND 
            status IN : statusesNotConsidered AND FSL_IsLight_Service__c = false AND recordTypeId =: breakDownRecordTypeId]) {
                sa.status='Spotted';
                saUpdateList.add(sa);
            }
            
            if(!saUpdateList.isEmpty()) {
                try {
                    update saUpdateList;
                }catch(Exception ex) {
                    System.debug('Calls with non Scheduled and Dispatched');
                }
            }
            
        }
        if(!vehicleChangeResIdSet.isEmpty() && oSettings.Run_InDay_Over_Vehicle_Change__c) {
            //ToDo Call Utility method to run inday logic
            List<ETA_Notification__e> etaNotList = new List<ETA_Notification__e>();
            for(Id idRes : vehicleChangeResIdSet) {
                ETA_Notification__e etaNote = FSL_OptimizationHelper.createETAPlatformEvent(null, 0, 'Vehicle Type Changed', idRes, false, false, false, true);
                etaNotList.add(etaNote);
            }
            if(!etaNotList.isEmpty()) {
                List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(etaNotList);
            }

        }

        //ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
        dispatchCurrentCallWhenResourceStarts(oldList, oldSRMap, newList, newSRMap);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    /**********
     * @Method Name:updateGanttLabel
     * @Parameters:(Map<id,ServiceResource>)
     * @Description: Accepts the map of ServiceResources and updates the Gantt Label
       @Author: Divyendra Naidu
     * **********/   
    
    //Method to update gantt label based on Vehicle Selection
    public static void updateGanttLabel(Map<Id, ServiceResource> newSRMap) {
        
        List<Schema.Location>  locList = new List<Schema.Location>();
        List<Id> idList = new List<Id>();
        List<ServiceResource> srToUpdate = new List<ServiceResource>();
        
        for(ServiceResource sr: newSRMAp.values()) {
            idList.add(sr.Vehicle__c);                       
        }
        locList = [Select Id,Vehicle_Name__c,Vehicle_Type__c from Location Where Id IN: idList];
        for(ServiceResource sr : newSRMap.values()) {
            if(sr.Vehicle__c != null) {
                for(Schema.Location l : locList) {
                    if(sr.Vehicle__c == l.Id) {
                        sr.FSL__GanttLabel__c = l.Vehicle_Name__c;
                        srToUpdate.add(sr);
                    }
                }
            }

            else {
                sr.FSL__GanttLabel__c = 'DRIVER OFFLINE';
                srToUpdate.add(sr);
            }
        }
       // update srToUpdate;
         
    }
        
    /****************
     * @Method Name:dispatchCurrentCallWhenResourceStarts     
     * @Description: //ERS-220594: When a Service Resource starts his workday, Dispatch regular non Appointment Calls automatically if they are in 'Scheduled' status and has not prior pending calls.
     *              - Loop through new SRs and find those that just started their workday and have 'Scheduled' appointments within Dispatch Window, then auto dispath them. 
       @Author: Clement Shiu
     * *************/   
    public static void dispatchCurrentCallWhenResourceStarts(List<ServiceResource> oldList, Map<Id, ServiceResource> oldSRMap, List<ServiceResource> newList, Map<Id, ServiceResource> newSRMap) {
      
        // try {                     
            Set<Id> resourceIdSet = new Set<Id>();        
            // Loop through newSRMap and find out which SR 'Currently_Scheduled__c' flag changed
            for(Id id : newSRMap.keySet()) {
                // Add only SRs that has the 'Currently_Scheduled__C' flag changed from false to true
                if( !oldSRMap.get(id).Currently_Scheduled__c && newSRMap.get(id).Currently_Scheduled__c) {
                    resourceIdSet.add(id);                
                }
            }

            if (!resourceIdSet.isEmpty()) {

                //     ***   Service Tech Team: Rework FSL_DispatchUtility logic to be based on SA statuses instead of WO's    ***

                // Retrieve related WO that are in Scheduled Status and auto Dispatch them 
                // TODO: How do we make sure that resource does not have any open WO before current time?     
                
                // List<WorkOrder> woListToUpdate = new List<WorkOrder>();
                // for(WorkOrder woUpdate : [SELECT Id, status, Non_Emergency_Appointment_Time__c,Service_Resource__c, Priority_Code__c FROM WorkOrder WHERE Service_Resource__c IN : resourceIdSet and status = 'Scheduled']) {                                
                //     if (FSL_DispatchUtility.isEligibleForDispatch(woUpdate)){                    
                //         woListToUpdate.add(woUpdate);
                //     }
                // }
        
                // // Update the Actual list of WOs
                // FSL_DispatchUtility.dispatchCurrentCallWithUpdate(woListToUpdate);     

                //////

                Map<Id, ServiceAppointment> saToDispatchMap = new Map<Id, ServiceAppointment>();
                for (ServiceAppointment sa : [SELECT Id, Status, ParentRecordId, Service_Resource__c, SchedStartTime, SchedEndTime, 
                                                     IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c, FSL__Pinned__c
                                              FROM ServiceAppointment
                                              WHERE Service_Resource__c IN :resourceIdSet
                                              AND IsBreakdown__c = true
                                              AND Status = 'Scheduled'
                                            //   AND SchedStartTime = LAST_N_DAYS:1
                                              AND SchedStartTime >= :System.now().addHours(-12)
                                              AND SchedStartTime <= :System.now().addHours(12)])
                {
                    // if (FSL_DispatchUtility.isEligibleForDispatch(sa.Work_Order__r)) {
                       saToDispatchMap.put(sa.Id, sa);
                    // }
                }
                if (!saToDispatchMap.isEmpty()) {
                    FSL_DispatchUtility.dispatchCurrentCallWithUpdate(saToDispatchMap);
                }
            }
                                

        // } catch (Exception e) {
        //     System.debug('dispatchCurrentCallWhenResourceStarts Error ::' + e.getMessage());
        // }
    }   

    /*@future(callout=true)
    public static void populateBearerTokenOnUser(String srNewListStr, String oldSRMapStr) {
        String bToken = FSL_ToGlympseCallout.getBearerToken();
        List<ServiceResource> newSRList = (List<ServiceResource>)JSON.deserialize(srNewListStr,List<ServiceResource>.class);
        Map<Id,ServiceResource> oldSRMap = (Map<Id,ServiceResource>)JSON.deserialize(oldSRMapStr,Map<Id,ServiceResource>.class);
        List<User> userList = new List<User>();
        for(ServiceResource sr : newSRList) {
            if(sr.Vehicle__c != oldSRMap.get(sr.Id).Vehicle__c && sr.RelatedRecordId != null) {
                User us = new User();
                us.Id = sr.relatedRecordId;
                us.Glympse_Token__c = bToken;
                userList.add(us);
            } 
        }
        if(!userList.isEmpty()) {
            update userList;
        }
        
    }*/

}