/**
 *  Utility Class containing methods that assist with Dispatching Work Orders and Service appointments
 * @Modification Log   : 
 * Ver       Date           Author           Modification
 *      01/05/2020     Clement Shiu         ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
 *      03/26/2020     Clement Shiu         ERS-222208: Prod Unpin Appt Clear call issue
 *      04/28/2021     Clement Shiu         ERS-222668: When a WorkOrder in Active Status other than Scheduled moved from one resource to another, it can not be auto Dispatched
 *      05/26/2021     Clement Shiu         ERS-223296: When a Call in 'En Route' or 'On Location' status was dragged to another Service Resource as a Stacked Call, the status was not automatically changed back to Scheduled.
 */

public class FSL_DispatchUtility {

    /**
     *  @purpose    -   Dispatch the next Work Order Scheduled to the Service Resource that just cleared their current call
     * 
     *  canceledClearedSAList - a list of canceled or cleared SAs
     *  saToUpdateMap - a map from SA trigger handler that collects SAs to update in the afterUpdate scope
     */
    public static void dispatchNextCall(List<ServiceAppointment> canceledClearedSAList, Map<Id, ServiceAppointment> saToUpdateMap) {
        // Set<Id> scheduledWoIdSet = new Set<Id>();
        Set<Id> resourceIdSet = new Set<Id>();       
        Set<String> activeStatuses = new Set<String>{'Scheduled'};    //ERS-220594: Only process pending SA in Scheduled Status
   
        for (ServiceAppointment sa : canceledClearedSAList) {
            // scheduledWoIdSet.add(sa.Work_Order__c);
            resourceIdSet.add(sa.Service_Resource__c);
        }
            
        //ERS-222208: Prod Unpin Appt Clear call issue - Filter out those out of Sync SAs that is older than 1 days old
        Map<Id, ServiceAppointment> pendingSAMap = new Map<Id, ServiceAppointment>([
            SELECT Id, Status, ParentRecordId, Service_Resource__c, SchedStartTime, SchedEndTime, 
                    IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c, FSL__Pinned__c,
                    Work_Order__r.Non_Emergency_Appointment_Time__c, Work_Order__r.Service_Resource__c
            FROM ServiceAppointment
            WHERE Status IN :activeStatuses
            AND Service_Resource__c IN :resourceIdSet
            // AND Work_Order__c NOT IN :scheduledWoIdSet
            AND IsBreakdown__c = true
            // AND SchedStartTime = LAST_N_DAYS:1
            AND SchedStartTime >= :System.now().addHours(-12)
            AND SchedStartTime <= :System.now().addHours(12)
        ]);

        if (pendingSAMap.isEmpty()) {
            return;
        }

        Map<Id, ServiceAppointment> dispatchedSAMap = dispatchCurrentCall(pendingSAMap);
        for (ServiceAppointment dispatchedSA : dispatchedSAMap.values()) {
            //  Calling a method from SA handler for adding SAs for autodispatch to the handler map to update them in handler's afterUpdate scope
            ServiceAppointment saToUpdate = FSL_ServiceAppointmentTriggerHandler.getSAToUpdateFromMap(dispatchedSA.Id, saToUpdateMap);
            saToUpdate.Status = dispatchedSA.Status;
            saToUpdate.Dispatched_Timestamp__c = dispatchedSA.Dispatched_Timestamp__c;
        }
    }

    public static Map<Id, ServiceAppointment> dispatchResourceNextCall(Set<Id> servResIdSet) {
        Map<Id, ServiceAppointment> scheduledSAMap = new Map<Id, ServiceAppointment>([
            SELECT Id, Status, ParentRecordId, Service_Resource__c, SchedStartTime, SchedEndTime, 
                   IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c, FSL__Pinned__c
            FROM ServiceAppointment
            WHERE Status = 'Scheduled'
            AND Service_Resource__c IN :servResIdSet
            AND IsBreakdown__c = true
            // AND SchedStartTime = LAST_N_DAYS:1
            AND SchedStartTime >= :System.now().addHours(-12)
            AND SchedStartTime <= :System.now().addHours(12)
        ]);

        if (scheduledSAMap.isEmpty()) {
            return new Map<Id, ServiceAppointment>();
        }

        return dispatchCurrentCall(scheduledSAMap);
    }

    /**
     *      @purpose    -     Check to see if the Call can be dispatched 
     *                        1) If it is a non appointment call, then it is eligible if it has a Service Resource Assigned.
     *                        2) If it is an Appt Call, then check the Appointment Call Window
     */    
    public static Boolean isEligibleForDispatch(ServiceAppointment sa) {
        Boolean isEligible = false;

        if (sa.Service_Resource__c != null && sa.Service_Resource__r.Currently_Scheduled__c) {
            if (sa.Member_Scheduled__c) {
                Integer dispatchWindow = getAppointmentDispatchWindow();
                Datetime apptTime = System.now().addMinutes(dispatchWindow);

                if (apptTime >= sa.SchedStartTime) {
                    isEligible = true;
                }
            }
            else {
                isEligible = true;
            }
        }
        return isEligible;
    }

    /**
     *      @purpose    -     Get the custom setting values for the Appointment Call Dispatch Window in min.
     */    
    public static Integer getAppointmentDispatchWindow() {
        FSL_Settings__c apptDispatchWindow = FSL_Settings__c.getInstance('Appointment Dispatch Window');
        Integer minValue = apptDispatchWindow?.Value__c != null ? Integer.valueOf(apptDispatchWindow.Value__c) : 0;
        return minValue;
    }

     public static Map<Id, ServiceAppointment> dispatchCurrentCall(Map<Id, ServiceAppointment> newSAToDispatchMap) {
        return new AutoDispatchHandler(newSAToDispatchMap).execute();
    }

    /**
     * @description Method is used for autodispatching Appointment calls from Scheduled flow
     * 
     */
    @InvocableMethod(label='Auto-Dispatch Appointment Call Update')
    public static List<List<ServiceAppointment>> dispatchCurrentCallFlowUpdate(List<List<ServiceAppointment>> newSAToDispatchList) {
        Map<Id, ServiceAppointment> newSAToDispatchMap = new Map<Id, ServiceAppointment>();       
        for(List<ServiceAppointment> newSAList : newSAToDispatchList)
        {
            for(ServiceAppointment sa : newSAList)
            {
                newSAToDispatchMap.put(sa.id,sa);
            }           
        }
        List<ServiceAppointment> updateSAList = dispatchCurrentCall(newSAToDispatchMap).values();
        if (!updateSAList.isEmpty()) {
            update updateSAList;
        }
        return newSAToDispatchList;
    }

    public static void dispatchCurrentCallWithUpdate(Map<Id, ServiceAppointment> saToDispatchMap) {
        if (!saToDispatchMap.isEmpty()) {
            Map<Id, ServiceAppointment> dispatchedSAMap = dispatchCurrentCall(saToDispatchMap);   
            
            if (!dispatchedSAMap.isEmpty()) {
                update dispatchedSAMap.values();
            }
        }
    }

    public static Boolean isStackedSAEligibleForReschedule(ServiceAppointment stackedSA) {
        Set<String> statusesSet = new Set<String>{'Dispatched','En Route','On Location'};
        Boolean isEligible = statusesSet.contains(stackedSA.Status) ? true : false;
        return isEligible;        
    }

    public static Boolean isWOHighPriority(WorkOrder wo) {
        if(wo == null) return false ;
        String prioritycode = wo.Priority_Code__c != null ? wo.Priority_Code__c : 'NA';       
        FSL_PriorityCode_Mapping__c priorityCodeMapping = FSL_PriorityCode_Mapping__c.getInstance(prioritycode);
        return priorityCodeMapping != null && priorityCodeMapping.Schedule_over_Lower_Priority_Appointment__c;
    }
    
    /**
     *  @purpose    -   Evaluate a completed RSO Request, locating Service Appointments that were adjusted by the
     *                  Request and need to be updated to a new Status (Scheduled or Dispatched)
     */
     public static void reDispatchOptimizedAppointments(List<FSL__Optimization_Request__c> completedOptimizationRequests) {
        // final update list
        List<ServiceAppointment> finalUpdatedAppointmentsList = new List<ServiceAppointment>();
        List<FSL__Optimization_Request__c> rsoRequests = new List<FSL__Optimization_Request__c>();
        List<FSL__Optimization_Request__c> inDayRequests = new List<FSL__Optimization_Request__c>();

        // Create RSO and In Day Lists
        for (FSL__Optimization_Request__c req : completedOptimizationRequests) {
            // Service Resource field is populated for RSO Reqeusts
            if (req.FSL__Service_Resource__c != null) {
                rsoRequests.add(req);
            } else {
                // add to In Day list
                inDayRequests.add(req);
            }
        }
        
        // for every RSO Request, evaluate SR for SA Statuses
        for (FSL__Optimization_Request__c rsoReq : rsoRequests) {
            // re-dispatch Service Resource
            List<ServiceAppointment> appointmentsWithNewStatus = reDispatchServiceResource(rsoReq.FSL__Service_Resource__c);
            finalUpdatedAppointmentsList.addAll(appointmentsWithNewStatus);
        }
        

        // for every In Day Request, evaluate Territories for SA Statuses
        for (FSL__Optimization_Request__c inDayReq : inDayRequests) {
            // re-dispatch service territories
            List<ServiceAppointment> appointmentsWithNewStatus = reDispatchTerritories(inDayReq);
            finalUpdatedAppointmentsList.addAll(appointmentsWithNewStatus);
        }

        // update all Service Appointments to their new Statuses
        if (!finalUpdatedAppointmentsList.isEmpty()) {
            update finalUpdatedAppointmentsList;
        }
    }
    
    /**
     *  @purpose    -   Evaluate order of Service Appointments after RSO runs on the Service Resource
     *                  and update the Appointments so the earliest call is Dispatched
     */
    public static List<ServiceAppointment> reDispatchServiceResource(ID srID) {
        Set<String> invalidStatusesForSA = new Set<String>{'Cleared','Canceled'};
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
                
        List<ServiceAppointment> assignedSAs = [
            SELECT Id, ParentRecordId, Status, Service_Resource__r.Currently_Scheduled__c,
                    Work_Order__r.Service_Resource__c, Work_Order__r.Non_Emergency_Appointment_Time__c,
                    SchedStartTime, SchedEndTime, IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c,
                    FSL__Pinned__c
            FROM ServiceAppointment 
            WHERE Service_Resource__c = :srID
            AND Status NOT IN :invalidStatusesForSA
            AND IsBreakdown__c = true
            AND SchedStartTime != null
            ORDER BY SchedStartTime ASC
        ];

        // ERS-220594: Filter out those WOs that has appointments outside the Appt dispatch window (eg: 45 min away)
        // Find the WO related to the Service Resource
        List<WorkOrder> workOrderList = new List<WorkOrder>();
        for (ServiceAppointment sa : assignedSAs) {
            workOrderList.add(sa.Work_Order__r);
        }
        
        // run sortServiceAppointments
        updatedAppointments = sortServiceAppointments(assignedSAs, workOrderList);

        return updatedAppointments;
    }

    /**
     *  @purpose    -   Identify all Service Appointments recently modified by the Optimization Job
     *                  and query the Appointments assigned to these Service Resources for the sort method
     */    
     public static List<ServiceAppointment> reDispatchTerritories(FSL__Optimization_Request__c req) {
        Set<String> invalidStatusesForSA = new Set<String>{'Cleared','Canceled'};        
        ID fslUserID = req.LastModifiedById;

        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();

        // Query all Territory Optimization Requests related to the Optimization Request
        List<FSL__Territory_Optimization_Request__c> territoryOptimizationRequests = [
            SELECT id, FSL__Optimization_Request__c, FSL__ServiceTerritory__c
            FROM FSL__Territory_Optimization_Request__c
            WHERE FSL__Optimization_Request__c = :req.id
        ];

        // Add Territory IDs to Set
        Set<ID> territoryIDSet = new Set<ID>();
        for (FSL__Territory_Optimization_Request__c territoryOptReq : territoryOptimizationRequests) {
            territoryIDSet.add(territoryOptReq.FSL__ServiceTerritory__c);
        }

        // query all appointments assigned to Territory IDs that have been recently modified by FSL Optimzation User (same LastModifiedByID on the req) 
        // filter for only Breakdown, not Cleared / Cancelled, sort by Scheduled Start Time
        List<ServiceAppointment> assignedSAs = [
            SELECT Id, ParentRecordId, Status, Service_Resource__r.Currently_Scheduled__c,
                    Work_Order__r.Service_Resource__c, Work_Order__r.Non_Emergency_Appointment_Time__c,
                    SchedStartTime, SchedEndTime, IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c,
                    FSL__Pinned__c
            FROM ServiceAppointment 
            WHERE ServiceTerritoryID IN :territoryIDSet
            AND Status NOT IN : invalidStatusesForSA
            AND IsBreakdown__c = true
            AND LastModifiedById = :fslUserID
            AND SchedStartTime != null
            ORDER BY SchedStartTime ASC
        ];        

        // create map of Service Resource to Service Appointment List
        Map<ID, List<ServiceAppointment>> srIDToSAListMap = new Map<ID, List<ServiceAppointment>>();
        
        // ERS-220594: Filter out those WOs that has appointments outside the Appt dispatch window (eg: 45 min away)               
        // Get the list of related WOs for the SA
        for (ServiceAppointment sa : assignedSAs) {
            // get all appointments in map assigned to service resource
            List<ServiceAppointment> mappedSAs;
            mappedSAs = srIDToSAListMap.get(sa.Service_Resource__c);
            if (mappedSAs == null) {
                mappedSAs = new List<ServiceAppointment>();                
            }
            mappedSAs.add(sa);
            srIDToSAListMap.put(sa.Service_Resource__c, mappedSAs);            
        }

        // Create a Map Of ServiceResource, WorkOrder
        Map<ID, List<WorkOrder>> srIDToWOListMap = new Map<ID, List<WorkOrder>>();
        // Get the list of WorkOrder for all the Service Resources
        List<WorkOrder> srWOList = [
            SELECT Id, Service_Resource__c, Non_Emergency_Appointment_Time__c
            FROM WorkOrder
            WHERE Service_Resource__c IN :srIDToSAListMap.keyset()
        ];
        for (WorkOrder wo : srWOList) {
            // get all WorkOrder in map assigned to service resource
            List<WorkOrder> mappedWOs;
            mappedWOs = srIDToWOListMap.get(wo.Service_Resource__c);
            if (mappedWOs == null) {
                mappedWOs = new List<WorkOrder>();                
            }
            mappedWOs.add(wo);
            srIDToWOListMap.put(wo.Service_Resource__c, mappedWOs);            
        }

        updatedAppointments = getSortServiceAppointments(srIDToSAListMap,srIDToWOListMap);

        return updatedAppointments;
    }

    // ERS-220594: New routine to wrap around the sortServiceAppointments
    public static List<ServiceAppointment> getSortServiceAppointments(Map<ID, List<ServiceAppointment>> srIDToSAListMap, Map<ID, List<WorkOrder>> srIDToWOListMap) {
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();

        // Run sortServiceAppointments value in the map
        List<ServiceAppointment> SAList;
        List<WorkOrder> woList;
        List<ServiceAppointment> saWithNewStatus;

        for (ID srID : srIDToSAListMap.keyset()) {
            SAList = srIDToSAListMap.get(srID);
            woList = srIDToWOListMap.get(srID);
            saWithNewStatus = sortServiceAppointments(SAList, woList);
            if (!saWithNewStatus.isEmpty()) {
                updatedAppointments.addAll(saWithNewStatus);
            }
        }
        return updatedAppointments;
    }

    /**
     *  @purpose    -   Iterate over SA List sorted by Scheduled Start Time for a specific SR, updating the 
     *                  Status to Dispatched or Scheduled, depending on the order (Dispatched first)
     *              -   Updated the 1st pair of appointment to Dispatched, and the rest paris to Scheduled.
     */
    public static List<ServiceAppointment> sortServiceAppointments(List<ServiceAppointment> saList, List<WorkOrder> woList) {
        List<ServiceAppointment> updatedAppointments = new List<ServiceAppointment>();
        Set<Id> relatedAppointmentSet = new Set<Id>();
        for (ServiceAppointment sa : saList) {
            relatedAppointmentSet.add(sa.id);
        }
        
        // iterate over appointments
        Integer itr = 1;
        ServiceAppointment saRef;
        ServiceAppointment towRef;
        for (ServiceAppointment sa : saList) {            
            if (itr == 1) {
                // if 1st appointment is in 'Scheduled' status, Auto Dispatch it, for Appt Call if it is within Appt Dispatch Window
                if (sa.Status == 'Scheduled' && isEligibleForDispatch(sa)) {                    
                    saRef = new ServiceAppointment();
                    saRef.Id = sa.Id;
                    saRef.Status = 'Dispatched';
                    saRef.Dispatched_Timestamp__c = System.now();
                    updatedAppointments.add(saRef);
                }
            } else {
                // if other appointment != Scheduled, set Status and add to update List                
                if (isStackedSAEligibleForReschedule(sa)) {
                    saRef = new ServiceAppointment();
                    saRef.Id = sa.Id;
                    saRef.Status = 'Scheduled';
                    saRef.Scheduled_Timestamp__c = System.now();
                    updatedAppointments.add(saRef);
                }                                                                
            }
            itr++;
        }
        
        return updatedAppointments;
    }

    public static void dispatchCurrentApptCalls() {
        // Get the default appointment dispatch window time, then add 5 min there
        Integer dispatchWindow = getAppointmentDispatchWindow() + 5;
        Datetime apptCallDispatchWindow = DateTime.now().addMinutes(dispatchWindow);

        Map<Id, ServiceAppointment> saMapToUpdate = new Map<Id, ServiceAppointment>([
            SELECT Id, Status, ParentRecordId, Service_Resource__c, SchedStartTime, SchedEndTime,
                    IsBreakdown__c, FSL__Related_Service__c, Member_Scheduled__c, FSL__Pinned__c
            FROM ServiceAppointment
            WHERE SchedStartTime < :apptCallDispatchWindow
            AND Status = 'Scheduled'
            AND IsBreakdown__c = true
            AND Member_Scheduled__c = true
            AND Service_Resource__r.Currently_Scheduled__c = true
            // AND SchedStartTime = LAST_N_DAYS:1
            AND SchedStartTime >= :System.now().addHours(-12)
            AND SchedStartTime <= :System.now().addHours(12)
        ]);

        if (!saMapToUpdate.isEmpty()) {
            dispatchCurrentCallWithUpdate(saMapToUpdate);
        }
    }

    //========================================================================================================================
    //========================================================================================================================

    
    /**
     * @description Handler for checking Resources' SAs on Autodispatch. Returns a map with dispatched appointments but doesn't save them to the database.
     * 
     * Pass to the AutoDispatch handler only Breakdown SAs in a map.
     * Their related Tow SAs will then be subsequently updated in SA trigger handler when updating Breakdown SAs.
     */
    class AutoDispatchHandler {

        private Map<Id, ServiceAppointment> newSAMap;

        AutoDispatchHandler(Map<Id, ServiceAppointment> newSAToDispatchMap) {
            this.newSAMap = newSAToDispatchMap;
        }

        Map<Id, ServiceAppointment> execute() {
            Map<Id, ServiceAppointment> dispatchedSAMap = new Map<Id, ServiceAppointment>();
            Set<Id> newResourceIdSet = new Set<Id>();
            for (ServiceAppointment newSA : newSAMap.values()) {
                if (newSA.Service_Resource__c != null) {
                    newResourceIdSet.add(newSA.Service_Resource__c);             
                }
            }
        
            if (newResourceIdSet.isEmpty()) {
                return dispatchedSAMap;
            }
            
            Map<Id, Map<Id, ServiceAppointment>> resIdToSAMapMap = getResIdToActiveSAsMapByResourceIds(newResourceIdSet);
            
            Map<Id, ServiceResource> scheduledResourceMap = new Map<Id, ServiceResource>([
                SELECT Id
                FROM ServiceResource
                WHERE Id IN :newResourceIdSet
                AND Currently_Scheduled__c = true
            ]);

            Integer dispatchWindow = getAppointmentDispatchWindow();
            Datetime apptCallDispatchWindow = System.now().addMinutes(dispatchWindow);
            
            for (ServiceAppointment newSA : newSAMap.values()) {
                Boolean isApptCallToDispatchLater = (newSA.Member_Scheduled__c && apptCallDispatchWindow < newSA.SchedStartTime);
                //      If resource is not on schedule or appt call is not in dispatch window yet, skip the call
                if (isApptCallToDispatchLater || newSA.FSL__Pinned__c || !scheduledResourceMap.containsKey(newSA.Service_Resource__c)) {
                    continue;
                }

                //      Removing Breakdown SA and its related Tow SA from map to get a map with other resource's SAs
                Map<Id, ServiceAppointment> anotherResSAMap = resIdToSAMapMap.get(newSA.Service_Resource__c).clone();
                ServiceAppointment currentSA = anotherResSAMap.remove(newSA.Id);
                ServiceAppointment relatedSA = anotherResSAMap.remove(newSA.FSL__Related_Service__c);

                //      If resource has no other calls, dispatch the current new one
                if (anotherResSAMap.isEmpty()) {
                    dispatchSA(currentSA, dispatchedSAMap, scheduledResourceMap);
                    currentSA.Status = 'Dispatched';
                    continue;
                }

                //      Getting the earliest most prioritized or the earliest Scheduled call among other resource's calls
                ServiceAppointment closestCompetingSA = getResourcesMostPrioritizedOrEarliestScheduledSA(anotherResSAMap);

                Boolean isCompetingSACanBeDispatched = ( !closestCompetingSA.FSL__Pinned__c &&
                                                        (!closestCompetingSA.Member_Scheduled__c || apptCallDispatchWindow >= closestCompetingSA.SchedStartTime) );

                Boolean isCurrent_LightServiceP1 = isWOLightServiceP1(currentSA);
                Boolean isCompeting_LightServiceP1 = isWOLightServiceP1(closestCompetingSA);

                //      When one of the calls is P1 Light Service
                if (isCurrent_LightServiceP1 != isCompeting_LightServiceP1) {
                    if (isCurrent_LightServiceP1) {
                        //      dispatch current Light Service P1
                        dispatchSA(currentSA, dispatchedSAMap, scheduledResourceMap);
                        currentSA.Status = 'Dispatched';
                    } else if (closestCompetingSA.Status == 'Scheduled' && isCompetingSACanBeDispatched) {
                        //      dispatch competing Light Service P1
                        dispatchSA(closestCompetingSA, dispatchedSAMap, scheduledResourceMap);
                    }
                    continue;
                    
                //      When no calls or both calls are P1 Light Service and competing call is already after Dispatched status, skip the new call
                } else if (closestCompetingSA.Status != 'Scheduled' && closestCompetingSA.Status != 'Dispatched') {
                    continue;
                }

                Boolean isCurrentCall_HighPriority = isWOHighPriority(currentSA.Work_Order__r);
                Boolean isCompetingCall_HighPriority = isWOHighPriority(closestCompetingSA.Work_Order__r);

                Map<String, Datetime> currentCallTimesMap = getStartEndOfCallMap(currentSA);
                Datetime currentCallStart = currentCallTimesMap.get('callStart');
                Datetime currentCallEnd = currentCallTimesMap.get('callEnd');

                Map<String, Datetime> competingCallTimesMap = getStartEndOfCallMap(closestCompetingSA);
                Datetime competingCallStart = competingCallTimesMap.get('callStart');
                Datetime competingCallEnd = competingCallTimesMap.get('callEnd');

                //      If calls have different priorities
                if (isCurrentCall_HighPriority != isCompetingCall_HighPriority) {
                    if (isCurrentCall_HighPriority) {
                        if (currentCallStart < competingCallEnd) {
                            //      dispatch current High Priority
                            dispatchSA(currentSA, dispatchedSAMap, scheduledResourceMap);
                            currentSA.Status = 'Dispatched';
                        } else if (closestCompetingSA.Status == 'Scheduled' && isCompetingSACanBeDispatched) {
                            //      dispatch competing Low Priority
                            dispatchSA(closestCompetingSA, dispatchedSAMap, scheduledResourceMap);
                        }
                        
                    //      If competing call is Higher priority and in Scheduled status
                    } else if (closestCompetingSA.Status == 'Scheduled') {
                        if (currentCallEnd <= competingCallStart) {
                            //      dispatch current Low Priority
                            dispatchSA(currentSA, dispatchedSAMap, scheduledResourceMap);
                            currentSA.Status = 'Dispatched';
                        } else if (isCompetingSACanBeDispatched) {
                            //      dispatch competing High Priority
                            dispatchSA(closestCompetingSA, dispatchedSAMap, scheduledResourceMap);
                        }
                    }
                }
                //      If both calls have same priorities and competing call is in Scheduled status
                else if (closestCompetingSA.Status == 'Scheduled') {
                    if (currentCallStart <= competingCallStart) {
                        //      dispatch current call
                        dispatchSA(currentSA, dispatchedSAMap, scheduledResourceMap);
                        currentSA.Status = 'Dispatched';
                    } else if (isCompetingSACanBeDispatched) {
                        //      dispatch competing call
                        dispatchSA(closestCompetingSA, dispatchedSAMap , scheduledResourceMap);
                    }
                }
            }

            return dispatchedSAMap;
        }

        private Map<Id, Map<Id, ServiceAppointment>> getResIdToActiveSAsMapByResourceIds(Set<Id> newResourceIdSet) {
            Map<Id, Map<Id, ServiceAppointment>> resIdToSAMapMap = new Map<Id, Map<Id, ServiceAppointment>>();

            Set<String> activeStatuses = new Set<String>{'Scheduled', 'Dispatched', 'En Route', 'On Location', 'Tow Loaded'};

            List<ServiceAppointment> saList = [
                SELECT Id, Status, IsBreakdown__c, SchedStartTime, SchedEndTime, ParentRecordId, Service_Resource__c, Member_Scheduled__c,
                       FSL__Pinned__c, FSL__Related_Service__r.SchedStartTime, FSL__Related_Service__r.SchedEndTime,
                       Work_Order__r.Priority_Code__c
                FROM ServiceAppointment
                WHERE Id IN :newSAMap.keySet()
                OR (Service_Resource__c IN :newResourceIdSet
                    AND Status IN :activeStatuses
                    AND IsBreakdown__c = true
                    // AND SchedStartTime = LAST_N_DAYS:1
                    AND SchedStartTime >= :System.now().addHours(-12)
                    AND SchedStartTime <= :System.now().addHours(12)
                )
            ];

            for (ServiceAppointment sa : saList) {
                ServiceAppointment saToPut = newSAMap.get(sa.Id);
                if (saToPut == null) {
                    saToPut = sa;
                } else {
                    saToPut = saToPut.clone(true, true, true, true);
                    saToPut.putSObject('FSL__Related_Service__r', sa.FSL__Related_Service__r);
                    saToPut.putSObject('Work_Order__r', sa.Work_Order__r);
                }

                Map<Id, ServiceAppointment> resSAMap = resIdToSAMapMap.get(saToPut.Service_Resource__c);
                if (resSAMap == null) {
                    resSAMap = new Map<Id, ServiceAppointment>();
                    resIdToSAMapMap.put(saToPut.Service_Resource__c, resSAMap);
                }
                resSAMap.put(saToPut.Id, saToPut);
            }

            return resIdToSAMapMap;
        }

        /**
         * @description Filters out and returns the most prioritised call by the following levels:
         *                  1. P1 Light Service Dispatched or after call
         *                  2. the earliest P1 Light Service Scheduled call
         *                  3. the earliest En Route or after call
         *                  4. the earliest Dispatched call (considering priority)
         *                  5. the earliest Scheduled call
         * 
         * @param anotherResSAMap - map with all resource's calls except the current ongoing for autodispatch
         */
        private ServiceAppointment getResourcesMostPrioritizedOrEarliestScheduledSA(Map<Id, ServiceAppointment> anotherResSAMap) {
            //      earliestSA will contain the earliest SA by SchedStartTime with Status = Scheduled and which is not P1 Light Service
            ServiceAppointment earliestSA; //with schedule and without P1 Light Service SA
            //      earliestActiveSA will contain the earliest earliest SA with Status = ( Dispatched/En Route/On Location/Tow Loaded )
            //      or P1 Light Service SA
            ServiceAppointment earliestActiveSA; //with P1 Light Service SA

            for (ServiceAppointment sa : anotherResSAMap.values()) {
                Boolean isCall_LightServiceP1 = isWOLightServiceP1(sa);

                if (isCall_LightServiceP1) {
                    if (sa.Status != 'Scheduled') {
                        return sa;
                    } else if (earliestActiveSA == null || !isWOLightServiceP1(earliestActiveSA) || sa.SchedStartTime < earliestActiveSA.SchedStartTime) {
                        earliestActiveSA = sa;
                    }

                } else if (sa.Status != 'Scheduled') {
                    if (earliestActiveSA == null) {
                        earliestActiveSA = sa;
                    } else if (isWOLightServiceP1(earliestActiveSA)) {
                        continue;
                    } else if (sa.Status != 'Dispatched') {
                        if (earliestActiveSA.Status == 'Dispatched' || sa.SchedStartTime < earliestActiveSA.SchedStartTime) {
                            earliestActiveSA = sa;
                        }

                    //      If both calls are in Dispatched status
                    } else if (earliestActiveSA.Status == 'Dispatched') {
                        Boolean isCallHighPriority = isWOHighPriority(sa.Work_Order__r);
                        Boolean isEarliestHighPriority = isWOHighPriority(earliestActiveSA.Work_Order__r);
                        if ((isCallHighPriority && !isEarliestHighPriority) ||
                            (isCallHighPriority == isEarliestHighPriority && sa.SchedStartTime < earliestActiveSA.SchedStartTime))
                        {
                            earliestActiveSA = sa;
                        }
                    }

                } else if (earliestSA == null || sa.SchedStartTime < earliestSA.SchedStartTime) {
                    earliestSA = sa;
                }
            }

            return earliestActiveSA != null ? earliestActiveSA : earliestSA;
        }

        private Boolean isWOLightServiceP1(ServiceAppointment sa) {
            return sa.Work_Order__r.Priority_Code__c == 'P1' && sa.FSL__Related_Service__c == null;
        }

        private Map<String, Datetime> getStartEndOfCallMap(ServiceAppointment sa) {
            Datetime callStart = sa.SchedStartTime;
            Datetime callEnd = sa.FSL__Related_Service__r.SchedEndTime != null
                                ? sa.FSL__Related_Service__r.SchedEndTime
                                : sa.SchedEndTime;

            return new Map<String, Datetime> {
                'callStart' => callStart,
                'callEnd' => callEnd
            };
        }

        private void dispatchSA(ServiceAppointment sa, Map<Id, ServiceAppointment> dispatchedSAMap, Map<Id, ServiceResource> scheduledResourceMap) {
            ServiceAppointment saToDispatch = new ServiceAppointment(
                Id = sa.Id,
                Status = 'Dispatched',
                Dispatched_Timestamp__c = System.now()
            );
            dispatchedSAMap.put(saToDispatch.Id, saToDispatch);
            scheduledResourceMap.remove(sa.Service_Resource__c);
        }
    }
}