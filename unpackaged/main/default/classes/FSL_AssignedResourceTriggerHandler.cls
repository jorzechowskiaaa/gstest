/**
 * @File Name          : FSL_AssignedResourceTriggerHandler.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 04-27-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    3/12/2020   Rajesh Kemisetti     Initial Version
 *       12/02/2020   Clement Shiu  ERS-220415: Optimization helper refractoring
 *       02/01/2020   Clement Shiu  ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
**/
public without sharing class FSL_AssignedResourceTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
 
    List<AssignedResource> newList = Trigger.new;
    List<AssignedResource> oldList = Trigger.old;
    Map<Id, AssignedResource> newMap = (Map<Id, AssignedResource>)Trigger.newMap;
    Map<Id, AssignedResource> oldMap = (Map<Id, AssignedResource>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('AssignedResource');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        populateEmergencyFlag(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        List<ServiceAppointment> updateAppointmentList = new List<ServiceAppointment>();
        
        FSL_NotificationFramework.arEvaluator(null, newMap, 'Scheduled');
        //afterAssignedResourcesInsert(newList);

        // FSL_IdleResourceUtility.removeIdleIndicatorOnAssignedResources(newMap); //added by Matt 5/24 for removing idle indicator

        // updated to set static lists for WO and SA updates
        updateServiceResourceAndServiceTerritoryLookupsOnRelatedObjects(updateAppointmentList, newList);

        // passes in lists from previous update methods to reduce DML statements
        // FSL_PopulateFacility.populateFacility(newMap, 'INSERT',  updateWorkOrderList, updateAppointmentList);
        checkForOverlapsOnResource(newList);
    }

    public override void beforeUpdate() {
        checkAppointmentStatusIfResourceChange(newList, oldMap);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        List<ServiceAppointment> updateAppointmentList = new List<ServiceAppointment>();
        
        Map<AssignedResource, Decimal> resourceToTravelDeltaMap = new Map<AssignedResource, Decimal>();
        Map<Id, AssignedResource> assignedResourceMap = new Map<Id, AssignedResource>();
        List<AssignedResource> serviceResourceReassignments = new List<AssignedResource>();
        // Service Tech Team: Changes to reduce the number of getts
        for(AssignedResource newAR : newMap.values()){
            // Service Tech Team: Create an extra variable to avoid duplicate getts
            AssignedResource oldAR = oldMap.get(newAR.Id);
            // US-301 and US-306 - adjust appointment based on drive time updates
            //Boolean travelTimeChanged = ( (Trigger.newMap.get(arID).EstimatedTravelTime != null) && (Trigger.newMap.get(arID).EstimatedTravelTime != Trigger.oldMap.get(arID).EstimatedTravelTime) );
            Boolean travelTimeChanged = ( (newAR.EstimatedTravelTime != null) && (newAR.EstimatedTravelTime != oldAR.EstimatedTravelTime) );
            Boolean previousTravelTime =  (oldAR.EstimatedTravelTime != null);
            Boolean newResourceAssigned = newAR.ServiceResourceID != oldAR.ServiceResourceID;

            // check if there is a new estimated travel time
            system.debug(oldAR.EstimatedTravelTime);
            system.debug(newAR.EstimatedTravelTime);
            system.debug('Previous Travel Time :' + previousTravelTime);
            system.debug('traveltimeChanged : ' + travelTimeChanged);
            if(previousTravelTime && travelTimeChanged){
                Decimal timeDelta = newAR.EstimatedTravelTime - oldAR.EstimatedTravelTime;
                system.debug('*+*+ travel time changed for ' + oldAR + ' *+*+');
                resourceToTravelDeltaMap.put(newAR, timeDelta);
            }

            if(newResourceAssigned){
                assignedResourceMap.put(newAR.Id, newAR);
                serviceResourceReassignments.add(newAR);
            }
        }

        if (!resourceToTravelDeltaMap.isEmpty()) {
            handleTravelTimeUpdates(resourceToTravelDeltaMap);
        }
        if (!assignedResourceMap.isEmpty()) {
            updateServiceResourceAndServiceTerritoryLookupsOnRelatedObjects(updateAppointmentList, serviceResourceReassignments);
            
            // moving logic so it only runs when the service resource is updated on the AR
            // evaluateIdleIndicatorOnUpdatedResources(newMap, oldMap);

        }

        //Following added by Divyendra 02/18/2019 for enabling auto-refresh on mobile app
        //Commented out by Divyendra on 9/11 and added to FSL_NotificationFramework.cls
        //1. Construct maps of Id, AssignedResource where the ServiceResourceId has changed
        List<AssignedResource> oldARs = oldList;
        Map<Id, AssignedResource> newARMap = newMap;
        List<AssignedResource> updatedOldARs = new List<AssignedResource>();
        Map<Id, AssignedResource> updatedARNewMap = new Map<Id, AssignedResource>();

        for (AssignedResource ar : oldARs) {
            // Service Tech Team: Create an extra variable to avoid duplicate getts
            AssignedResource newAR = newARMap.get(ar.Id);
            if (ar.FSL__Estimated_Travel_Time_To_Source__c != newAR.FSL__Estimated_Travel_Time_To_Source__c) {
                updatedOldARs.add(ar);
                updatedARNewMap.put(ar.Id, newAR);
            }
        }
        if(!updatedOldARs.isEmpty()){
            afterAssignedResourceRoutingChange(updatedOldARs, updatedARNewMap);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterDelete() {
        // evaluateIdleIndicatorOnDeletedResources(oldMap); //added by Matt 5/24. Replaced with newMap (was oldMap)
        dispatchResourceNextCall(oldMap);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================



   /**********
   * @Method Name:  handleTravelTimeUpdates
   * @Parameters:   Map<AssignedResource, Decimal>
   * @Return:       void
   * @Description:  Associates the Service Appointments that need updating to the Assigned Resource / Travel Time Delta Map
     @Author:       Ryan Johnson
   * **********/
    public static void handleTravelTimeUpdates(Map<AssignedResource, Decimal> newScheduleDelta) {
        Set<ID> impactedSAs = new Set<ID>();
        for (AssignedResource ar : newScheduleDelta.keyset()) {
            impactedSAs.add(ar.ServiceAppointmentID);
        }
        FSL_AppointmentScheduleHelper.handleAddressChangeTraveTimelUpdates(impactedSAs, newScheduleDelta);

    }


    /**
     *  @purpose    -   Determine if a Service Resource should have their Idle updated when they are
     *                  removed from a Service Appointment via Assigned Resource deletion 
     * 
     **/    
    // public static void evaluateIdleIndicatorOnDeletedResources(Map<Id, AssignedResource> assignedResourceMap) {
    //     Set<Id> resourceIdSet = new Set<Id>();
    //     for(AssignedResource ar : assignedResourceMap.values()){
    //         resourceIdSet.add(ar.ServiceResourceId);
    //     }
    //     List<ServiceResource> resources = [SELECT Id, Idle__c,RelatedRecord.isactive FROM ServiceResource WHERE Id IN :resourceIdSet];
    //     FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(resources);
    // }

    public void dispatchResourceNextCall(Map<Id, AssignedResource> assignedResourceMap) {
        Set<Id> servResIdSet = new Set<Id>();
        for(AssignedResource ar : assignedResourceMap.values()){
            servResIdSet.add(ar.ServiceResourceId);
        }
        Map<Id, ServiceAppointment> dispatchedSAMap = FSL_DispatchUtility.dispatchResourceNextCall(servResIdSet);
        if (!dispatchedSAMap.isEmpty()) {
            update dispatchedSAMap.values();
        }
    }

    private void checkAppointmentStatusIfResourceChange(List<AssignedResource> newList, Map<Id, AssignedResource> oldMap) {
        Map<Id, AssignedResource> newSAIdToARMap = new Map<Id, AssignedResource>();
        for (AssignedResource newAR : newList) {
            AssignedResource oldAR = oldMap.get(newAR.Id);
            if (newAR.ServiceResourceId != oldAR.ServiceResourceId) {
                newSAIdToARMap.put(newAR.ServiceAppointmentId, newAR);
            }
        }

        if (newSAIdToARMap.isEmpty()) {
            return;
        }

        Set<String> prohibitedForResourceChangeStatusSet = new Set<String>{ 'Tow Loaded', 'In Tow', 'Tow Complete', 'Canceled', 'Cleared' };
        for (ServiceAppointment sa : [SELECT Status FROM ServiceAppointment WHERE Id IN :newSAIdToARMap.keySet()
                                      AND Status IN :prohibitedForResourceChangeStatusSet]) {
            AssignedResource ar = newSAIdToARMap.get(sa.Id);
            ar.addError(Label.A_call_with_a_Status_after_On_Location_cannot_be_reassigned_to_another_resource);
        }
    }

    /**
     *  @purpose    -   Determine if the Service Resource of an updated Assigned Resource,
     *                  with a new Service Resource ID, should have their Idle indicator updated
     * 
     **/     
    // public static void evaluateIdleIndicatorOnUpdatedResources(Map<Id, AssignedResource> newAssignees, Map<Id, AssignedResource> oldAssignees){
    //     System.debug('Entering Idle Evaluation');
    //     List<Id> resourceIds = new List<Id>();
    //     Set<Id> resourceIdSet = new Set<Id>();
    //     List<ServiceResource> resources = new List<ServiceResource>();
    //     for(AssignedResource ar : newAssignees.values()){
    //         resourceIds.add(ar.ServiceResourceId);
    //     }
    //     for (AssignedResource ar : oldAssignees.values()){
    //         resourceIds.add(ar.ServiceResourceId);
    //     }
    //     resourceIdSet.addAll(resourceIds);
    //     resources = [SELECT Id, Idle__c,RelatedRecord.isactive FROM ServiceResource WHERE Id IN :resourceIdSet];
    //     system.debug(resources);
    //     FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(resources);
    // }


    /**
     *  @purpose    -   Create an Application Log to record an update to an Assigned Resource 
     *                  when the Source of the Estimated Travel Time To changes 
     * 
     **/     
    public static void afterAssignedResourceRoutingChange(List<AssignedResource> updatedOldARs, Map<Id, AssignedResource> updatedARNewMap){ //List<AssignedResource> oldARs,
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.Factory().createService();
        FSL_ApplicationLogCreator.routingLogger(updatedOldARs, updatedARNewMap, service);
    }
    
    /**
     *  @purpose    -   Update lookups to Service Resource on Service Appointment and Work Order
     *                  to match the value of the Service Resource on the related Assigned Resource
     *
     *                  Also calls the Dispatch Utility to update Service Appointment Status 
     *                  based on availability of the Service Resource
     * 
     **/       
    private void updateServiceResourceAndServiceTerritoryLookupsOnRelatedObjects(List<ServiceAppointment> updateAppointmentList, List<AssignedResource> arList) {
        Map<Id, AssignedResource> newSAIdToARMap = new Map<Id, AssignedResource>();
        Set<Id> srIdSet = new Set<Id>();
        Set<Id> prevSRIdSet = new Set<Id>();
        // find service appointments
        for(AssignedResource ar : arList){
            newSAIdToARMap.put(ar.ServiceAppointmentId, ar);
            srIdSet.add(ar.ServiceResourceId);
            if (oldMap != null) {
                prevSRIdSet.add(oldMap.get(ar.Id).ServiceResourceId);
            }
        }

        // ERS-220594: Added Work_Order__r.Non_Emergency_Appointment_Time__c
        List<ServiceAppointment> serviceAppointmentList = [
            SELECT RecordTypeId, FSL__Schedule_over_lower_priority_appointment__c, Member_Scheduled_Appointment_Time__c,
                   Status, Service_Resource__c, FSL__Schedule_Mode__c, Work_Order_Priority__c, isScheduledByDispatcher__c,
                   FSL_IsLight_Service__c, ParentRecordId, Work_Order__r.Non_Emergency_Appointment_Time__c, Service_Resource__r.Currently_Scheduled__c,
                   ServiceTerritoryId, Facility__c, SchedStartTime, SchedEndTime, IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c, FSL__Pinned__c
            FROM ServiceAppointment
            WHERE Id IN :newSAIdToARMap.keySet()
            OR (Service_Resource__c IN :prevSRIdSet
                AND Status = 'Scheduled'
                AND isBreakdown__c = true
                // AND SchedStartTime = LAST_N_DAYS:1
                AND SchedStartTime >= :System.now().addHours(-12)
                AND SchedStartTime <= :System.now().addHours(12)
            )
        ];
        // Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>(saQueryList);

        List<ServiceTerritoryMember> stms = [
            SELECT MemberNumber, ServiceTerritoryId, ServiceResourceId, ServiceTerritory.Name, ServiceResource.RelatedRecordId, ServiceResource.Primary_Service_Territory__r.Id, ServiceResource.LocationId__c
            FROM ServiceTerritoryMember
            WHERE ServiceResourceId IN :srIdSet
            AND TerritoryType = 'P'
            AND FSL_Expired_Resource_Territory__c = false
        ];
        Map<Id, ServiceTerritoryMember> serviceTerritoryMemberMap = new Map<Id, ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : stms) {
            serviceTerritoryMemberMap.put(stm.ServiceResourceId, stm);
        }

        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();
        // Map<Id, ServiceAppointment> saForAutoDispatchMap = new Map<Id, ServiceAppointment>();
        Map<Id, WorkOrder> woUpdateMap = new Map<Id, WorkOrder>();
        // Map<Id, Id> woIdToServiceTerritoryIds = new Map<Id, Id>();
        // Map<Id, Id> woIdToTruckIds = new Map<Id, Id>();
        
        // create resource to SA Map
        // Map<ID,ID> saToSR = new Map<ID,ID>();
        // Map<ID,ID> woToSR = new Map<ID,ID>();
        // Set<ID> woIDs = new Set<ID>();

        for (ServiceAppointment sa : serviceAppointmentList) {
            // ServiceAppointment sa = serviceAppointmentMap.get(ar.ServiceAppointmentId);
            AssignedResource ar = newSAIdToARMap.get(sa.Id);

            if (ar != null) {
                // saToSR.put(sa.id, ar.ServiceResourceID);
                
                // check if resource lookups match
                if (sa.Service_Resource__c != ar.ServiceResourceId) {
                    // sync lookup and record
                    sa.Service_Resource__c = ar.ServiceResourceId;
                                    
                    // instantiate and update WO shell
                    WorkOrder wo = new WorkOrder(Id = sa.ParentRecordId, Service_Resource__c = sa.Service_Resource__c);

                    ServiceTerritoryMember stm = serviceTerritoryMemberMap.get(ar.ServiceResourceId);
                    
                    if (stm != null) {
                        if (Trigger.isInsert /*'INSERT'.equals(operation)*/ && sa.Facility__c != stm.ServiceTerritoryId) {
                            sa.Facility__c = stm.ServiceTerritoryId;
                        }
                        if (sa.ServiceTerritoryId != stm.ServiceTerritoryId) {
                            sa.ServiceTerritoryId = stm.ServiceTerritoryId;
                        }
                        if (wo.ServiceTerritoryId != stm.ServiceResource.Primary_Service_Territory__r.Id) {
                            wo.ServiceTerritoryId = stm.ServiceResource.Primary_Service_Territory__r.Id;
                        }
                        if (wo.LocationId != stm.ServiceResource.LocationId__c) {
                            wo.LocationId = stm.ServiceResource.LocationId__c;
                        }
                    }

                    if (sa.IsBreakdown__c && sa.Status != 'Cleared') { // Vishnu Popuru #07/07/2025
                        sa.Status = 'Scheduled';
                    }
                    saToUpdateMap.put(sa.Id, sa);
                    woUpdateMap.put(wo.Id, wo); 
                }
            }
            else {
                saToUpdateMap.put(sa.Id, sa);
            }
        }

        if (!saToUpdateMap.isEmpty()) {
            update saToUpdateMap.values();
        }

        if (!woUpdateMap.isEmpty()) {
            update woUpdateMap.values();
        }
    }

    /**********
   * @Method Name:  populateEmergencyFlag
   * @Parameters:   List<AssignedResource> arList
   * @Return:       void
   * @Description:  Method to update Resource with Emergency flag if an Emergency appointment is assigning to a resource.
     @Author:       Balaram Naidu
   * **********/
    public static void populateEmergencyFlag(List<AssignedResource> arList) {
        Set<ID> saIDs = new Set<ID>();
        Map<Id,Id> resourceIdsMap = new Map<Id,Id>();
         Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();
        for(AssignedResource aResource : arList) {
            saIDs.add(aResource.ServiceAppointmentID);
            resourceIdsMap.put(aResource.ServiceAppointmentID,aResource.ServiceResourceId);
        }
        if(!saIDs.isEmpty()) {
            List<ServiceResource> arListToUpdate = new List<ServiceResource>();
            //List<ServiceAppointment> appointmentList = [Select Id,Work_Order_Priority__c from ServiceAppointment where Id in : saIDs];
            for(ServiceAppointment sa : [Select Id,Work_Order_Priority__c from ServiceAppointment where Id in : saIDs AND recordTypeId =:breakDownRecordTypeId ]) {
                if(sa.Work_Order_Priority__c == 'Critical') {
                    if(resourceIdsMap.get(sa.Id) != null) {
                        ServiceResource ar = new ServiceResource();
                        ar.Id = resourceIdsMap.get(sa.Id);
                        ar.Eligible_For_Emergencey_Call__c = true;
                        arListToUpdate.add(ar);
                    } 
                }
            }
            if(!arListToUpdate.isEmpty()) {
                update arListToUpdate;
            }
        }
    }
    
    /**
     *  @purpose    -   When an Emergency Assignment is made, this method checks if any overlaps
     *                  has occurred, and creates a Platform Event to handle any RSO requirements  
     *
     *
     *
     */    
    public static void checkForOverlapsOnResource(List<AssignedResource> arList){
        // try{
            FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
            Id towRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId();
            if(oSettings.Optimize_Emergency_Overlaps__c){
                // create map of resource to newly created appointment
                Map<AssignedResource, ServiceAppointment> resourceToAppointmentMap = new Map<AssignedResource, ServiceAppointment>();
                Map<ID, AssignedResource> appointmentToResourceMap = new Map<ID, AssignedResource>();
                
                // find all appointments for these resources
                Set<ID> resourceIDSet = new Set<ID>();
                Set<ID> appointmentIDSet = new Set<ID>();
                
                for(AssignedResource ar : arList){
                    resourceIDSet.add(ar.ServiceResourceID);
                    appointmentIDSet.add(ar.ServiceAppointmentID);
                    appointmentToResourceMap.put(ar.ServiceAppointmentID, ar);
                }

                List<ServiceAppointment> overlapAppointmentCandidates = [SELECT id,isCritical__c,appointmentNumber, recordTypeId,FSL_IsLight_Service__c, ParentRecordId, FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime, SchedEndTime, Status,ETA__c
                    FROM ServiceAppointment WHERE ID IN :appointmentIDSet AND FSL__Schedule_over_lower_priority_appointment__c = true];
                    
                List<ServiceAppointment> overlappingAppointments = new List<ServiceAppointment>();
                for(ServiceAppointment sa : overlapAppointmentCandidates){
                    // create wrapper for overlap utility method
                    AssignedResource ar = appointmentToResourceMap.get(sa.id);
                    Integer travelTimeTo = ar.EstimatedTravelTime != null ? Integer.valueOf(ar.EstimatedTravelTime) : 0;
                    Integer travelTimeFrom = ar.FSL__EstimatedTravelTimeFrom__c != null ? Integer.valueOf(ar.FSL__EstimatedTravelTimeFrom__c) : 0;
                    FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper wrapper = new FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper(sa, travelTimeTo, travelTimeFrom);
                    if(sa.recordTypeId == towRecordTypeId && sa.isCritical__c) {
                        continue;
                    }
                    // check for overlaps
                    if(FSL_OptimizationHelper.didCallCreateOverlap(wrapper, null, null)){
                        overlappingAppointments.add(sa);
                    }
                    
                }
                
                // run RSO for the resources with overlapping SAs
                if(!overlappingAppointments.isEmpty()){
                    FSL_OptimizationHelper.bulkFixOverlaps(overlappingAppointments);
                }
            }
        
        // }catch(Exception e){
        //     system.debug('Exception caught - ' + e);
        // }
        
    }
}