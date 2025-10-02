/****
 **@Name: WorkOrderTriggerHandler
 **@Description: when the workorder is changed, Update the ServiceAppointment Address,lat,long etc.
 * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0    10/04/2018   Rajesh Kemisetti     Initial Version 
 *        07/23/2020   Clement Shiu         Added updateGanttIconOnSA()
 *        12/03/2020   Clement Shiu         ERS-220518 - Introduce RAP GAP changes into ACE Org
 *        01/05/2020   Clement Shiu         ERS-220594: Unpinned Appointment Calls Auto-Dispatch and shift based on other calls
 *        01/15/2021   Dylan Truong         ERS-218555 Enhancement Improve Visibility of RAP calls 
 ***/
 
public class FSL_WorkOrderTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
     
    List<WorkOrder> newList = Trigger.new;
    List<WorkOrder> oldList = Trigger.old;
    Map<Id, WorkOrder> newMap = (Map<Id, WorkOrder>)Trigger.newMap;
    Map<Id, WorkOrder> oldMap = (Map<Id, WorkOrder>)Trigger.oldMap;
	private static Set<Id> processedWorkOrders = new Set<Id>();//EMI-01-22-2025-Added for SSFI-77
    public static Boolean isfirsttimeupdate = true ;//EMI-01-23-2025-Added for SSFI-77
    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('WorkOrder');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        checkCredentialsForWOCreation(newList);
        populateTimeOfCall(newList);//should be oldMap variable
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        FSL_PlatformEventsHandler.createWorkOrderEvent(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        //===============================================================================================
        //Relocated code block from FSL_WorkOrderTrigger.trigger here
        //===============================================================================================
        FSL_Contact.IContactService contactService = new FSL_Contact.Factory().createService();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
        workOrderService.onBeforeUpdate( oldMap, newMap, contactService );
        //===============================================================================================


        Set<string> setWorkOrderId = new Set<string>();
        // For identifying Work Orders that need to be Cleared
        List<WorkOrder> callsWithNewResolutionCodes = new List<WorkOrder>();
        
        // For identifying recently cleared calls - for Dispatching
        // Set<String> clearedStatuses = new Set<String>{'Cleared', 'Canceled'};  //   ***   Service Tech Team: The only use is commented out 
        // List<WorkOrder> clearedCalls = new List<WorkOrder>();

        //   ***   Service Tech Team: Moved FSL_DispatchUtility calls to FSL_ServiceAppointmentTriggerHandler    ***
        // Set<String> scheduledStatuses = new Set<String>{'Scheduled'};
        // List<WorkOrder> scheduledCalls = new List<WorkOrder>();

        List<ID> statusChangeList = new List<ID>();
        List<WorkOrder> statusChangeWOList = new List<WorkOrder>();
        
        //   ***   Service Tech Team: Commented out as WO has different Status transition than SA now
        // checkStatusTransition(newList,oldMap);

        // check if updates are allowed
        allowUpdates(oldList, newList);

        //   ***   Service Tech Team: Moved logic to FSL_ServiceAppointmentTriggerHandler    ***
        // resourceCheckForScheduleWO(newList, oldMap);           
        
        //   ***   Service Tech Team: Changes to reduce the number of getts
        for(WorkOrder newWo : newMap.values()){   
            WorkOrder oldWo = oldMap.get(newWo.Id);     
            //System.debug('OLD WO STATUS** '+ oldWo.status + ' **NEW WO STATUS**' + newWo.status);
            if(oldWo.status != newWo.status){
                statusChangeList.add(newWo.Id);
                statusChangeWOList.add(newWo);
                // Can not add it here since the WO status has not changed to Clear yet
                //if(clearedStatuses.contains(newWo.status)){
                //    clearedCalls.add(newWo);
                //}

                  
                
            }

            //   ***   Service Tech Team: Moved FSL_DispatchUtility calls to FSL_ServiceAppointmentTriggerHandler    ***
            // ERS-220594: We need to include Appointment calls here and check if it is within the Appt Call Dispatch Window                    
            // The Scheduled Status can remain the same during inital auto diaptch, we need to check if the Service Resource was assigned               
            
            // if(scheduledStatuses.contains(newWo.status) && FSL_DispatchUtility.isEligibleForDispatch(newWo)){
            //     scheduledCalls.add(newWo);
            // }                

            Boolean newResolutionCode = String.isBlank(oldWo.Resolution_Code__c) && String.isNotBlank(newWo.Resolution_Code__c);
            //system.debug('resolution code status = ' + newResolutionCode);
            if(newResolutionCode){
                callsWithNewResolutionCodes.add(newWo);
            }
        }

        //   ***   Service Tech Team: Moved FSL_DispatchUtility calls to FSL_ServiceAppointmentTriggerHandler    ***
        // if(!scheduledCalls.isEmpty()){
        //     // Handle Auto-Dispatch on Schedule
        //     //FSL_WorkOrderTriggerHandler.dispatchWorkOrderWhenItsScheduled(newList, oldMap);
        //     FSL_DispatchUtility.dispatchCurrentCall(scheduledCalls);
        // }
        
        if(!statusChangeList.isEmpty()){
            //clear the jeopardy
            //system.debug('USERNAME** '+Userinfo.getUserName()+' '+Userinfo.getSessionId());
            //system.debug('CALLING WOJeopardy API from WORKORDER Trigger');
            // Removed the WOJeopardyAPI call when UserInfo.getSessionId() == null, since the callout fails for that reason
            // Because of this, the callout is completely useless.
            // TODO: find another way to handle the Jeopardy
            if(Userinfo.getSessionId()!=null) {
                for(WorkOrder wo : statusChangeWOList){
                    wo.In_Jeopardy__c = false;
                    wo.FSL_Milestone_Issued_Warning__c = false;
                }
            }
        }

        //Shankar ERS-226724  - handleBeforeUpdateTriggerForCancelledCall is now obsolete
        // ERS-221785 Refactoring
        //FSL_WorkOrder.CancelledWorkOrdersInfo  cancelledWOInfo =   
        //new FSL_WorkOrder.Factory().createService().handleBeforeUpdateTriggerForCancelledCall(oldMap, newMap);
        //callsWithNewResolutionCodes.addAll(cancelledWOInfo.autoClearableCalls);
        // End ERS-221785 Refactoring


        if(!callsWithNewResolutionCodes.isEmpty()){
            markCallsAsCleared(callsWithNewResolutionCodes);
        }

        // updateWorkOrderStatusTimeStamp(newMap.values(),oldMap);

        //   ***   Service Tech Team: Moved this "for" inside first "for" in beforeUpdate()   ***
        // for(WorkOrder newWo : newMap.values()){
        //     WorkOrder oldWo;
        //     oldWo = oldMap.get(newWo.Id); 

        //     //Add by Sunil for Uf-160 Sub task UF-802
        //     if(oldWo.status != 'Cleared' && newWo.status == 'Cleared'){
        //         setWorkOrderId.add(newWo.ID);
        //     }
        // }


        if(!setWorkOrderId.isEmpty()) {
            PopulateServiceVehicle(newMap.values(), setWorkOrderId);
        }
        
        //FSL_WorkOrderTriggerHandler.releaseQueuedWoToDispatch(newList, oldMap);            
        //   ***   Service Tech Team: Moved FSL_DispatchUtility calls to FSL_ServiceAppointmentTriggerHandler    ***
        // FSL_DispatchUtility.dispatchNextCall(newList, oldMap);
    }
	
    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        //   ***   Service Tech Team: Creation of an additional map to avoid a large number of updates in methods
        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();
        //   ***   Service Tech Team: Changing lists to maps to avoid unnecessary variables inside methods
        Map<Id, WorkOrder> workOrdersWithNewContacts = new Map<Id, WorkOrder>();
        // Map<Id, WorkOrder> workOrdersWithOverrideReasons = new Map<Id, WorkOrder>();
        //Dylan Change ERS-218555
        List<WorkOrder> wOsWithPmtReqOrRap = new List<WorkOrder>();
        List<WorkOrder> callsNeedingThirdPartyNotifications = new List<WorkOrder>();
        List<WorkOrder> callsNeedingThirdPartyDispatch = new List<WorkOrder>();
        List<WorkOrder> callsNeedingThirdPartyUpdate = new List<WorkOrder>();//EMI-01-22-2025-Added for SSFI-77
        List<Audit_Log__c> auditLogs = new List<Audit_Log__c>();
        Set<Id> idsTOCallRBPAPI = new Set<Id>(); 

        //   ***   Service Tech Team: Moved to FSL_ServiceAppointmentTriggerHandler  ***
        // List<Id> workOrdersToCloseCaseOnSchedule=new List<Id>();

        // iterate over records to look for updates
        //   ***    Service Tech Team: Changes to reduce the number of getts
        for (WorkOrder newWO : newList) {        
            WorkOrder oldWO = oldMap.get(newWO.ID);//improve Apex character limit 
            Boolean contactChanged = oldWO.ContactID != newWO.ContactID;
            if (contactChanged) {
                workOrdersWithNewContacts.put(newWO.Id, newWO);
            }

            if ( oldWO.servicing_technology_type__c != newWO.servicing_technology_type__c && 
                 newWO.servicing_technology_type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK) {
                    callsNeedingThirdPartyDispatch.add(newWO);
            }
            //system.debug('========================newWO===================  ' +newWO);
            //PR893288-3664
              // if (!platformTriggerExecutionTracker.processedWorkOrders.contains(newWO.Id)) {//EMI-01-22-2025-Added for SSFI-77
            if (oldWO.Breakdown_Address__c != newWO.Breakdown_Address__c || oldWO.Breakdown_Location__Latitude__s != newWO.Breakdown_Location__Latitude__s ||
                oldWO.Breakdown_Location__Longitude__s != newWO.Breakdown_Location__Longitude__s || oldWO.Tow_Location__Longitude__s != newWO.Tow_Location__Longitude__s ||
                oldWO.Tow_Location__Latitude__s != newWO.Tow_Location__Latitude__s || oldWO.Tow_Street__c != newWO.Tow_Street__c || oldWO.Tow_City__c != newWO.Tow_City__c ||
                oldWO.Tow_State__c != newWO.Tow_State__c || oldWO.Tow_Country__c != newWO.Tow_Country__c || oldWO.Tow_Postal_Code__c != newWO.Tow_Postal_Code__c) {
             
                    callsNeedingThirdPartyUpdate.add(newWO);//EMI-01-22-2025-Added for SSFI-77
              
                    String oldMessage = '';
                    String newMessage = '';
                    if (oldWO.Breakdown_Address__c != newWO.Breakdown_Address__c){
                        oldMessage += 'Old Breakdown Address: ' + oldWO.Breakdown_Address__c + ',  ';
                        newMessage += 'New Breakdown Address: ' + newWO.Breakdown_Address__c + ',  ';
                    } 
                    if (oldWO.Breakdown_Location__Latitude__s != newWO.Breakdown_Location__Latitude__s ||
                		oldWO.Breakdown_Location__Longitude__s != newWO.Breakdown_Location__Longitude__s){
                            if (oldWO.Breakdown_Location__Latitude__s != newWO.Breakdown_Location__Latitude__s) {
                                oldMessage += 'Old Breakdown Location Latitude: ' + oldWO.Breakdown_Location__Latitude__s + ',  ';
                        		newMessage += 'New Breakdown Location Latitude: ' + newWO.Breakdown_Location__Latitude__s + ',  ';
                            }
                            if (oldWO.Breakdown_Location__Longitude__s != newWO.Breakdown_Location__Longitude__s) {
                                oldMessage += 'Old Breakdown Location Longitude: ' + oldWO.Breakdown_Location__Longitude__s + ',  ';
                        		newMessage += 'New Breakdown Location Longitude: ' + newWO.Breakdown_Location__Longitude__s + ',  ';
                            }
                        
                    } 
                    if (oldWO.Tow_Location__Longitude__s != newWO.Tow_Location__Longitude__s ||
                		oldWO.Tow_Location__Latitude__s != newWO.Tow_Location__Latitude__s) {
                            if(oldWO.Tow_Location__Latitude__s != newWO.Tow_Location__Latitude__s){
                                oldMessage += 'Old Tow Location Latitude: ' + oldWO.Tow_Location__Latitude__s + ',  ';
                        		newMessage += 'New Tow Location Latitude: ' + newWO.Tow_Location__Latitude__s + ',  ';
                            }
                            if(oldWO.Tow_Location__Longitude__s != newWO.Tow_Location__Longitude__s){
                                oldMessage += 'Old Tow Location Longitude: ' + oldWO.Tow_Location__Longitude__s + ',  ';
                        		newMessage += 'New Tow Location Longitude: ' + newWO.Tow_Location__Longitude__s + ',  ';
                            }
                    }  
                    if (oldWO.Tow_Street__c != newWO.Tow_Street__c){
                        oldMessage += 'Old Tow Street: ' + oldWO.Tow_Street__c + ',  ';
                        newMessage += 'New Tow Street: ' + newWO.Tow_Street__c + ',  ';
                    } 
                    if (oldWO.Tow_City__c != newWO.Tow_City__c){
                        oldMessage += 'Old Tow City: ' + oldWO.Tow_City__c + ',  ';
                        newMessage += 'New Tow City: ' + newWO.Tow_City__c + ',  ';
                    } 
                    if (oldWO.Tow_State__c != newWO.Tow_State__c){
                        oldMessage += 'Old Tow State: ' + oldWO.Tow_State__c + ',  ';
                        newMessage += 'New Tow State: ' + newWO.Tow_State__c + ',  ';
                    } 
                    if (oldWO.Tow_Country__c != newWO.Tow_Country__c){
                        oldMessage += 'Old Tow Country: ' + oldWO.Tow_Country__c + ',  ';
                        newMessage += 'New Tow Country: ' + newWO.Tow_Country__c + ',  ';
                    } 
                    if (oldWO.Tow_Postal_Code__c != newWO.Tow_Postal_Code__c){
                        oldMessage += 'Old Tow Postal Code: ' + oldWO.Tow_Postal_Code__c + ',  ';
                        newMessage += 'New Tow Postal Code: ' + newWO.Tow_Postal_Code__c + ',  ';
                    }
                    
                    Map<String,Object> mapInputs = new Map<String,Object>();
                    mapInputs.put('oldMessage',oldMessage);
                    mapInputs.put('newMessage',newMessage);
                    mapInputs.put('CaseId',newWO.CaseId);
                    mapInputs.put('workOrderId',newWO.ID);
                    //system.debug('========================mapInputs===================  ' +mapInputs);
                    Map<String, Object> ipOutput = new Map<String, Object> (); 
                    try {
                        /*ipOutput = (Map<String, Object>)omnistudio.IntegrationProcedureService.runIntegrationService(
                            'backOffice_generateAuditLogOnAfterUpdate',
                             mapInputs,
                             new Map < String, Object > ());*/

                        //Replacing Omnistudio Feautures with Apex. ERS users will not have License to Omnistudio.
                        Audit_Log__c log = new Audit_Log__c(
                            Details__c = oldMessage + ',' + newMessage,
                            Case__c = newWO.CaseId,
                            Work_Order__c = newWO.ID
                        );
                        auditLogs.add(log);
                             
                    } catch(DmlException e) {
                        system.debug(' ##### DmlException #### '+ e);
                    }
                  //  platformTriggerExecutionTracker.processedWorkOrders.add(newWO.Id);//EMI-01-22-2025-Added for SSFI-77
            }
             
        	//}//EMI-01-22-2025-Added for SSFI-77

            //   ***    Service Tech Team: Override Reason is kept on WO level now
            // Boolean newOverrideReason = oldWO.Manual_Override_Reason__c != newWO.Manual_Override_Reason__c;                
            
            //Dylan Change
            Boolean newPmtReqOrRap  = /*oldWO.Payment_Required__c != newWO.Payment_Required__c ||*/ oldWO.Call_Type__c != newWO.Call_Type__c;
            //ERS-218373:  Set/Reset the Gantt Icon for based upon Payment Required Flag
            // ERS-218555 Improve Visibility for RAP Call
            if (newPmtReqOrRap) {
                wOsWithPmtReqOrRap.add(newWO);
            }

            //   ***    Service Tech Team: Override Reason is kept on WO level now
            // if(newOverrideReason){
            //     workOrdersWithOverrideReasons.put(newWO.Id, newWO);
            // }

            //   ***   Service Tech Team: Moved to FSL_ServiceAppointmentTriggerHandler  ***
            // if (oldWO.Status != newWo.
            // Status && newWo.Status == 'Scheduled') {
            //     workOrdersToCloseCaseOnSchedule.add(newWo.id);
            // }

            if( newWO.Status!=oldMap.get(newWO.Id).Status) {
                if( IsNeedingThirdPartyNotification(newWO) ) {
                    callsNeedingThirdPartyNotifications.add(newWO); 
                } 
            }

            // if( newWO.RAP_Status__c!=oldMap.get(newWO.Id).RAP_Status__c && newWO.RAP_Status__c == 'RAP Cleared') {
            //     idsTOCallRBPAPI.add(newWO.Id);
            // }
        }

        if(auditLogs != null && auditLogs.size() > 0){
            insert auditLogs;
        }

        // handle updates
        if(!workOrdersWithNewContacts.isEmpty()){
            updateContactOnSA(workOrdersWithNewContacts, saToUpdateMap);
        }

        //   ***   Service Tech Team: Now we keep Override Reason on WO level only  ***
        // if(!workOrdersWithOverrideReasons.isEmpty()){
        //     updateOverrideReasonOnSA(workOrdersWithOverrideReasons, saToUpdateMap);
        // }

        //Dylan ERS-218555
        if(!wOsWithPmtReqOrRap.isEmpty()){
            updateGanttIconOnSA(wOsWithPmtReqOrRap, saToUpdateMap);
        }

        //   ***   Service Tech Team: Logic is moved to FSL_ServiceAppointmentTriggerHandler   ***
        // OnAfterUpdate(oldList, newMap, saToUpdateMap);

        if(!saToUpdateMap.isEmpty()){
            update saToUpdateMap.values();
        }

        retryScheduleAppointmentonLocationUpdate(newList,oldMap);
        checkUpdateOnWorkOrderAfterClearedStatus(newMap.values(), oldMap);
        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.Factory().createService();

        if( !callsNeedingThirdPartyNotifications.isEmpty() ) {
            sendThirpartyNotifications(callsNeedingThirdPartyNotifications, thirdPartyService);
        }
        for ( WorkOrder wo: callsNeedingThirdPartyDispatch) {
            try {
                thirdPartyService.sendDispatchOfferPlatformEvent(wo);
            }
            catch(Exception e) {
                thirdPartyService.logDiagnosticMessage('Failed to Dispatch a Call to a ThirdParty Dispatch Service on a reroute', wo.External_Id__c);
            }
        }
        /**EMI-01-22-2025-Added for SSFI-77---Start-*/
        for ( WorkOrder wo: callsNeedingThirdPartyUpdate) {
             try {
                 if(!System.isFuture()){
                 thirdPartyService.sendDispatchUpdatePlatformEvent(wo);
                 }
             }
            catch(Exception e) {
                thirdPartyService.logDiagnosticMessage('Failed to Update a Call to a ThirdParty Dispatch Service on a reroute', wo.External_Id__c);
            }
              
        }
       /**EMI--01-22-2025-Added for SSFI-77---End*/

        //   ***    Service Tech Team: Moved to FSL_ServiceAppointmentTriggerHandler    ***
        // if (!workOrdersToCloseCaseOnSchedule.isEmpty()) {
        //     closeCaseWhenWOScheduled(workOrdersToCloseCaseOnSchedule);  
        // }

        if(idsTOCallRBPAPI.size() > 0){
            //sendWorkOrderToRBP(idsTOCallRBPAPI);
        }
    }

    @TestVisible
    private boolean IsNeedingThirdPartyNotification(WorkOrder newWO) {
        if( (newWO.Status=='Cleared' && newWO.Servicing_Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK_NOTIFY ) || 
            (newWO.Status=='Canceled' && newWO.Servicing_Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK ) ) {
                return true; 
        } 
        return false;
    }

    @TestVisible
    private void sendThirpartyNotifications(List<WorkOrder> calls, ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService) {
        thirdPartyService.sendStatusChangePlatformEvents(calls);
    }
    
    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    //   ***   Service Tech Team: Moved these Sets to OnAfterUpdate(), where they're only used
    // static set<ID> woIdsAlreadySentToFuture = new set<ID>();
    // static set<ID> serviceAppointmentStatusUpdated = new set<ID>();


    /**********
     * @Method Name:        allowUpdates
     * @Parameters:         List<WorkOrder> oldList, List<WorkOrder> newList
     * @Description:        checks if updates are allowed on workOrders
       @Requirement:        
       @Author:             Ryan Johnson
     * **********/ 
    public static void allowUpdates(List<WorkOrder> oldList, List<WorkOrder> newList){
        //   ***   Service Tech Team: Creating a map to avoid using a nested loop
        Map<Id, WorkOrder> woNewMap = new Map<Id, WorkOrder>(newList);
         
        if(Execute_Trigger__c.getValues('WorkOrder') != null && Execute_Trigger__c.getValues('WorkOrder').Execute_Logic__c){
            for(WorkOrder wo : oldList){
                if(wo.Editable__c == false && !FeatureManagement.checkPermission('Update_Work_order_after_Cleared')){        
                    WorkOrder woNew = woNewMap.get(wo.Id);           
                    woNew.addError('Work Orders can only be updated during a configurable, limited time interval after being cleared');
                }
            }
        }
    }

    private void retryScheduleAppointmentonLocationUpdate(List<WorkOrder> newList, Map<Id,WorkOrder> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrder wo : newList) {
            //   ***   Service Tech Team: Create an extra variable to avoid duplicate getts
            WorkOrder oldWO = oldMap.get(wo.Id);
            if (wo.Servicing_Technology_Type__c != 'Landline'
                 && wo.Latitude != oldWO.Latitude && wo.Longitude != oldWO.Longitude && oldWO.Longitude == null && oldWO.Latitude == null
                 && wo.Status == 'Spotted' && (wo.GeocodeAccuracy == 'Address' || wo.GeocodeAccuracy == 'NearAddress' || wo.GeocodeAccuracy == 'Block'))
            {
                workOrderIds.add(wo.id);
            }
        }
        if (!workOrderIds.isEmpty()) {
            scheduleRetry(workOrderIds);
        }
    }


    //   ***   Service Tech Team: Commented out as WO has different Status transition than SA now

     /********
      * @purpose    -   Validate the Work Order status transition is valid according to FSL Settings
      *
      */
    //   public static void checkStatusTransition(List<WorkOrder> newList, Map<Id,WorkOrder> oldMap) {
    //     list<FSL.StatusTransition> sts =FSL.GlobalAPIS.GetAllStatusTransitions();
    //     for(WorkOrder wo : newList) {
    //         //   ***   Service Tech Team: Create an extra variable to avoid duplicate getts
    //         WorkOrder oldWO = oldMap.get(wo.Id);
    //         if(wo.status != oldWO.status) {
    //             Boolean isAllowed = FSL_TriggerUtility.isStatusTransitionAllowed(oldWO.status,wo.status,sts);
    //             System.debug('isAllowed======>>>>'+isAllowed);
    //             if(!isAllowed) {
    //                 wo.addError('Status change not allowed From '+ oldWO.status +' To '+wo.status);
    //             }
    //         }
    //     }
    // }


/******************/
        @Future
        public static void scheduleRetry(set<Id> workOrderIds){
            List<ServiceAppointment> serviceAppointments =new  List<ServiceAppointment>();
            List<WorkOrder> workOrders =new  List<WorkOrder>();
            workOrders = Database.query('SELECT ServiceTerritory.OperatingHours.Timezone, ' +
                                        String.join(new List<String>(Schema.getGlobalDescribe().get('WorkOrder').getDescribe().fields.getMap().keySet()), ',') +
                                        ' FROM WorkOrder '+
                                        ' Where Id in :workOrderIds');
            
            serviceAppointments = Database.query('SELECT ' + 
                                                String.join(new List<String>(Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().fields.getMap().keySet()), ',') + 
                                                ' FROM ServiceAppointment '+
                                                ' Where ParentRecordId in :workOrderIds');
            
            Map<Id, FSL__Scheduling_Policy__c> policyMap = new Map<Id, FSL__Scheduling_Policy__c>([SELECT Id, Name FROM FSL__Scheduling_Policy__c]);
            Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id, Name, EstimatedDuration FROM WorkType]);
            
            Map<Id, ServiceAppointment> woIdToBreakdownSAMap = new Map<Id, ServiceAppointment>();
            Map<Id, ServiceAppointment> woIdToTowSAMap = new Map<Id, ServiceAppointment>();

            //   ***   Service Tech Team: Creating a map to avoid using a nested loop
            for (ServiceAppointment sa : serviceAppointments) {
                if (sa.isBreakdown__c) {
                    woIdToBreakdownSAMap.put(sa.ParentRecordId, sa);
                } else {
                    woIdToTowSAMap.put(sa.ParentRecordId, sa);
                }
            }

            for (WorkOrder wo : workOrders) {
                ServiceAppointment breakdownSA = woIdToBreakdownSAMap.get(wo.Id);
                ServiceAppointment towSA = woIdToTowSAMap.get(wo.Id);
                FSL_Schedule_Config scheduleConfig = FSL_SchedulingUtility.populateArrivalWindowAndPolicy(breakdownSA, wo, policyMap);
                FSL_AppointmentDependencyHelper.ScheduleQueueableAppointment(breakdownSA, towSA, wo, worktypeIdMap, scheduleConfig, policyMap);                
            } 
        }
    /**********
    * @Method Name:createServiceAppointment
    * @Parameters:(List<WorkOrder> newWorkOrdersList)
    * @Description:    Method is to send the workorders to FSL_AppointmentDependencyHelper
    *                  to manually create Service appointments, including tow types
    * **********/

    //   ***   Service Tech Team: Moved to FSL_WorkOrderIntake  ***

    // public static void createServiceAppointment(List<WorkOrder> newWorkOrdersList){
    //     System.debug('//'+ newWorkOrdersList.get(0));
    //     FSL_AppointmentDependencyHelper.createAndScheduleServiceAppointments(newWorkOrdersList.get(0));
    // }

    //   ***   Service Tech Team: Moved to FSL_ServiceAppointmentTriggerHandler  ***
//     private void closeCaseWhenWOScheduled(List<Id> woIds) {
//         List<Case> casesToClosed=[select id,status from case where  FSL_Service_Appointment__r.Work_Order__c in :woIds and FSL_In_Jeopardy_Reason__c = 'No Lat/Long' and FSL_Service_Appointment__r.Work_Order__r.Status='Scheduled'];
//         for(Case cse:casesToClosed){
//             cse.status='Closed'; 
//         }
//         if(!casesToClosed.isempty()){
//            update casesToClosed;
//         }
//    }



    //   ***    Service Tech Team: The whole method is commented out as status change now is going mostly from SA and D3 update is moved to FSL_ServiceAppointmentTriggerHandler   *** 

    /**********
    * @Method Name:OnAfterUpdate
    * @Parameters:(List<WorkOrder> oldWorkOrdersList, Map<Id, WorkOrder> newWorkOrderMap)
    * @Description:    Method is to copy Work order staus to Service Appointment. 
    *                 This method also makes outbound call to D3 on WorkOrder status change. 
    * **********/
    // public static void OnAfterUpdate(List<WorkOrder> oldWorkOrdersList, Map<Id, WorkOrder> newWorkOrderMap, Map<Id, ServiceAppointment> saToUpdateMap) {        
    //     List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
    
        // Shankar ERS=-226724 - This whole block is only used to set up the FSL_ToD3Updates.  
        // But since ToD3Update is now moved to the SA trigger handler We can get rid of this block here
    
    //     Set<Id> updatedWOStatuses = new Set<Id>();
    //     //Set<String> wOStatuses = new Set<String>{'Scheduled','Dispatched','En Route','On Location', 'Cleared'};
    //     Set<String> wOStatusesForD3 = new Set<String>{'En Route','On Location','Cannot Complete', 'In Tow'};
    //     Set<String> wOStatusesForSA = new Set<String>{'Dispatched','En Route','On Location','Cannot Complete', 'Cleared', 'Tow Complete', 'In Tow', 'Canceled'};        
    //     Set<Id> woIdsAlreadySentToFuture = new Set<Id>();

    //     for(WorkOrder WOobj : oldWorkOrdersList) {
    //         //   ***   Service Tech Team: Create an extra variable to avoid duplicate getts
    //         String woStatus = newWorkOrderMap.get(WOobj.Id).Status;
    //         if(WOobj.Status != woStatus && !woIdsAlreadySentToFuture.contains(WOobj.Id)) {
    //             if(wOStatusesForD3.contains(woStatus)){
    //                 updatedWOStatuses.add(WOobj.ID);
    //                 woIdsAlreadySentToFuture.add(WOobj.ID);
    //             }
             
    //             if(woStatus == 'Cleared'){
    //                 woIdsAlreadySentToFuture.add(WOobj.ID);
    //             }                             
    //         }
    //     }

    //     Map<string, FSL_WO_To_SA_Status_Mapping__mdt> WOStatusToSAStatus = new map<string, FSL_WO_To_SA_Status_Mapping__mdt>();
    //     for (FSL_WO_To_SA_Status_Mapping__mdt WOToSAStatus: [SELECT MasterLabel,Breakdown_Appointment__c,Tow_Appointment__c from FSL_WO_To_SA_Status_Mapping__mdt ]){
    //         WOStatusToSAStatus.put(WOToSAStatus.MasterLabel, WOToSAStatus);
    //     }

    //     Set<Id> serviceAppointmentStatusUpdated = new Set<Id>();

    //     for (ServiceAppointment sa : [SELECT Id, Status, FSL__Pinned__c, ParentRecordId, isBreakdown__c, 
    //                                          (SELECT id from ServiceResources)
    //                                     FROM ServiceAppointment
    //                                     WHERE ParentRecordId IN :newWorkOrderMap.keySet()])
    //     {   
    //         //   ***   Service Tech Team: Creation of an additional map to avoid a large number of updates in methods
    //         ServiceAppointment saToUpdate = getSAToUpdateFromMap(sa.Id, saToUpdateMap);
    //         //   ***   Service Tech Team: Create an extra variable to avoid duplicate getts
    //         WorkOrder wo = newWorkOrderMap.get(saToUpdate.ParentRecordId);
    //         //Status check added to stop recursive update logic for SA's 29/10/2019
    //         if(wOStatusesForSA.contains(wo.Status) && sa.status != wo.Status && !serviceAppointmentStatusUpdated.contains(sa.Id) ){
    //             //added if condetaion Code changed for UAT_ACE_Unable to manually assign tow appointment - 28/02/2019-Balaram
    //             if (sa.Status == 'Dispatched' && (sa.ServiceResources == null || sa.ServiceResources.isEmpty())) {
    //                 continue;
    //             }
    //             String status;
    //             //   ***   Service Tech Team: Changing ifs for more reliability
    //             if(sa.isBreakdown__c){
    //                 status = WOStatusToSAStatus.get(wo.Status).Breakdown_Appointment__c;
    //             }else{
    //                 status = WOStatusToSAStatus.get(wo.Status).Tow_Appointment__c;
    //             }
    //             //Update only those SAs for which the status has a value
    //             if (!string.isEmpty(status)) {
    //                 saToUpdate.Status = status;          
    //                 system.debug('===status=='+saToUpdate.Status);
    //                 system.debug('===FSL__Pinned__c=='+sa.FSL__Pinned__c);
    //             } else {
    //                 //set the jeopardy flag to false as for Complex calls the Tow appt status would not be changed in some cases
    //                 if (!wo.In_Jeopardy__c) {
    //                     saToUpdate.FSL__InJeopardy__c = false;
    //                     saToUpdate.FSL__InJeopardyReason__c = null;
    //                 }
    //             }
    //             //updating this list irrespective of status change to both the Appointments to handle other issue
    //             serviceAppointmentStatusUpdated.add(saToUpdate.Id);
    //             //   serviceAppointmentList.add(sa);

    //         }
    //     }

    //     //   ***   Service Tech Team: The update has been replaced by a map that will be called in the trigger method after all methods have been executed
        
    //     // if(!serviceAppointmentList.isEmpty() && !System.Test.isRunningTest()){        
    //     //     try {
    //     //         update serviceAppointmentList;
    //     //     }
    //     //     catch (DmlException e) {
    //     //         System.debug('ChildrenAppointments ' + e.getMessage());
    //     //         FSL_ApplicationLogCreator.schedulingLogger('FSL_WorkOrderTriggerHandler.OnAfterUpdate',e.getmessage(),true);
    //     //     }
    //     //         catch (Exception e) {
    //     //         System.debug('ChildrenAppointments ' + e.getMessage());
    //     //         FSL_ApplicationLogCreator.schedulingLogger('FSL_WorkOrderTriggerHandler.OnAfterUpdate',e.getmessage(),true);
    //     //     }
    //     // }
        
            // Shankar ERS=-226724 Integration Mapping Changes on top of Service Team Changes
            // Move this to the SA Trigger Handler
            
    //     if(!updatedWOStatuses.isEmpty()){
    //         System.debug('updatedWOStatuses:'+updatedWOStatuses);
    //         FSL_ToD3Update.loadWorkOrders(updatedWOStatuses);
    //     }

    // }
    
    
     /**********
     * @Method Name:postToFeed
     * @Parameters:(Map<Id, WorkOrder>, Map<Id, WorkOrder>)
     * @Description: Method accepts oldMap and newMap on after update trigger on WorkOrder, evaluates if the status on WO changed to cancelled, and calls the chatter utility class to create post with SM-005 message.
       @Requirement: BR-011
       @Author: Divyendra Naidu
     * **********/
    
    /*public static void postToFeed(Map<Id, WorkOrder> oldWOMap, Map<Id,WorkOrder> newWOMap) {
        String message_id;
        Map<Id,String> woIdMessage = new Map<Id,String>();
        for(WorkOrder woNew : newWOMap.values()) {
            for(WorkOrder woOld : oldWOMap.values()) {
                if(woNew.Id == woOld.Id && woNew.Status == 'Cannot Complete' && woOld.Status != 'Cannot Complete' && woOld.Status != 'Scheduled') {
                    message_id = 'SM-005';               
                    woIdMessage.put(woNew.Id, message_id);                 
                }
                
                if(woNew.Id == woOld.Id && woNew.Status == 'Dispatched') {
                  message_id = 'SM-002';               
                  woIdMessage.put(woNew.Id, message_id); 
                }
               
                
            }
            //Divyendra- Moved the resolution code piece to the work order trigger and commenting it out here
            //if(newWOMap.get(woNew.Id).Resolution_Code__c != null )
               //   newWOMap.get(WONew.Id).Status = 'Cleared';
        }
       
        //FSL_ChatterUtilities.postThis(woIdMessage);
    }*/



    /**********
     * @Description:    check user credentials before creating Work Order
    **********/

    private static void checkCredentialsForWOCreation(List<WorkOrder> workOrderList) {

        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;


        FSL_Integration_User__c fiu2 = FSL_Integration_User__c.getInstance('Integration User');
        FSL_Integration_User__c ers = FSL_Integration_User__c.getInstance('ERS Advocate');
        if (ers != null && String.isNotBlank(ers.User_Name__c) && profileName != ers.User_Name__c)  {

            FSL_Integration_User__c fiu = FSL_Integration_User__c.getInstance('Integration User');

            if (fiu != null && String.isNotBlank(fiu.User_Name__c) && UserInfo.getName() != fiu.User_Name__c) {


                for (WorkOrder wo:workOrderList){
                    wo.addError('Work Orders can only be created through Call Receive/D3/IRAS');
                }

            }  
               
        }

    }

    /**********
     * @Method          Name:checkUpdateOnWorkOrderAfterClearedStatus
     * @Parameters:     List<WorkOrder>,Map<Id,WorkOrder>
     * @Description:    Method is to check any update on Work order after status is changed to Cleared. 
     * @Requirement:    Lock Work order once status is changed to Cleared. 
     * @Author:         Binod Shaw
     * **********/
    public static void checkUpdateOnWorkOrderAfterClearedStatus(List<WorkOrder> woList, Map<Id,WorkOrder> oldWorkOrderMap){
        Id SysAdminId = FSL_OrgCache.sysAdminProfileId();
        Id BackOfficeRoleId = [SELECT Id FROM UserRole WHERE DeveloperName  = 'Back_Office'].Id;
        
        //   ***   Service Tech Team: If it is taken out for a cycle, to avoid a cycle in case of mismatch of conditions
        if ( UserInfo.getProfileId() != SysAdminId && UserInfo.getUserRoleId() != BackOfficeRoleId) {
            for (Workorder wo:woList){
                if(!oldWorkOrderMap.get(wo.Id).Editable__c && !FeatureManagement.checkPermission('Update_Work_order_after_Cleared')){
                //System.debug('wo.LastModifiedDate----'+wo.LastModifiedDate);   
                //System.debug('oldWorkOrderMap.get(wo.Id).LastModifiedDate----'+ oldWorkOrderMap.get(wo.Id));     
                //Long timeIntervalSec = (wo.LastModifiedDate.getTime() - oldWorkOrderMap.get(wo.Id).LastModifiedDate.getTime())/1000;
                //if ((timeIntervalSec > 60 ) && (UserInfo.getProfileId() != SysAdminId)){
                    wo.addError('Work order can not be changed after the Edit-After-Clear period has elapsed');            
                }  
            }
        }
    }
    
    /**********
     * @Method Name:    populateTimeOfCall
     * @Parameters:     Map<Id, WorkOrder>
     * @Description:    Populate WorkOrder.Local_Time_of_Call__c with a value 0 through 23 based on the time which the call was received, adjusted to the local timezone of the breakdown address
     * @Requirement:    UF-349
     * @Author:         Matthew Pantell
    **********/
    public static void populateTimeOfCall(List<WorkOrder> workOrderList) {
        for (WorkOrder wo : workOrderList){
            // try {
                String localTimezone = wo.Timezone_Id__c;
                if (String.isNotBlank(localTimezone)) {
                    String nowAdjusted = System.now().format('MM/dd/yyyy HH:mm:ss', localTimezone);
                    Integer timeOfCall = Integer.valueOf(nowAdjusted.substring(11,13));
                    // System.debug('Timezone of Call : ' + localTimezone);
                    // system.debug('Time of Call: ' + timeOfCall);
                    if (timeOfCall != null) {            
                        wo.Local_Time_of_Call__c = timeOfCall;
                    } 
                }
            // } catch (Exception e) {
            //     System.debug('Error populating time of call on WorkOrder ' + wo.workOrderNumber + ': ' + e);
            // }
        }
    }
    
 /**********
     * @Method Name:updateContactOnSA
     * @Parameters: List<WorkOrder> woList - work orders with a new contactID
     * @Description: Copies the Contact ID from the Work Order to the Service Appointment(s)
       @Requirement: Keep the contact id in sync between work order and appointment
       @Author: Ryan Johnson
     * **********/          
    public static void updateContactOnSA(Map<Id, WorkOrder> woMap, Map<Id, ServiceAppointment> saToUpdateMap) {

        //   ***   Service Tech Team: No need for additional variables
        // Set<ID> woIDs = new Set<ID>();
        // Map<ID, ID> woToContactMap = new Map<ID,ID>();
        // for(WorkOrder wo : woList){
        //     woIDs.add(wo.id);
        //     woToContactMap.put(wo.id, wo.ContactID);
        // }

        List<ServiceAppointment> childAppointments = [SELECT ParentRecordId, ContactId FROM ServiceAppointment WHERE ParentRecordId IN :woMap.keySet()]; 
        for (ServiceAppointment sa : childAppointments) {
           WorkOrder wo = woMap.get(sa.ParentRecordId);
            if (sa.ContactId != wo.ContactId) {
                ServiceAppointment saToUpdate = getSAToUpdateFromMap(sa.Id, saToUpdateMap);
                saToUpdate.ContactId = wo.ContactId;
            }
        }

        //   ***   Service Tech Team: The update has been replaced by a map that will be called in the trigger method after all methods have been executed
        // if(!saUpdateList.isEmpty()){
        //     update saUpdateList;
        // }
    }
    
        
    //   ***   Service Tech Team: Commented out the method as now we keep Override Reason on WO level only  ***

     /**********
     * @Method Name:updateOverrideReasonOnSA
     * @Parameters: List<WorkOrder> woList - work orders with a new override reason
     * @Description: Copies the override reason from the Work Order to the Service Appointment(s)
       @Requirement: 
       @Author: Ryan Johnson
     * **********/     
    // public static void updateOverrideReasonOnSA(Map<Id, WorkOrder> woMap, Map<Id, ServiceAppointment> saToUpdateMap){

        //   ***   Service Tech Team: No need for additional variables
        // Set<ID> woIDs = new Set<ID>();
        // Map<ID, String> woToOverrideReason= new Map<ID,String>();
        // for(WorkOrder wo : woList){
        //     woIDs.add(wo.id);
        //     woToOverrideReason.put(wo.id, wo.Manual_Override_Reason__c);
        // }

        // List<ServiceAppointment> saUpdateList = [SELECT id, ParentRecordId, Manual_Override_Reason__c FROM ServiceAppointment WHERE ParentRecordID IN :woMap.keySet()];
        // for(ServiceAppointment sa : saUpdateList){
        //     ServiceAppointment saToUpdate = getSAToUpdateFromMap(sa.Id, saToUpdateMap);
        //     saToUpdate.Manual_Override_Reason__c = woMap.get(sa.ParentRecordId).Manual_Override_Reason__c;
        // }

        //   ***   Service Tech Team: The update has been replaced by a map that will be called in the trigger method after all methods have been executed
        // if(!saUpdateList.isEmpty()){
        //     update saUpdateList;
        // }

    // }

    /**************
     * @Method Name: updateGanttIconOnSA
     * @Parameters:  List<WorkOrder> woList - work orders with a new payment required flag
     * @Description: Resets the FSL__GanttIcon__c flag on the Service Appointment(s)
       @Requirement: //ERS-218373:  Reset the Gantt Icon based on WO Payment Required Flag
       @Author:      Clement Shiu
     * **********/     
    public static void updateGanttIconOnSA(List<WorkOrder> woList, Map<Id, ServiceAppointment> saToUpdateMap){
        // try {   

            //   ***   Service Tech Team: No need for additional variables
            // Set<Id> woIDs = (new Map<Id,WorkOrder>(woList)).keySet().clone();

            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([
                SELECT ParentRecordId, Status, FSL__GanttIcon__c, isBreakdown__c, Payment_Required__c
                FROM ServiceAppointment
                WHERE ParentRecordId IN :woList
            ]);
            
            if (saMap.isEmpty()) {
                return;
            }

            List<ServiceAppointment> saClonedList = saMap.values().deepClone(true, true, true);
            FSL_ServiceAppointmentTriggerHandler.updateGanttIconsOnSA(saClonedList);        
            
            for (ServiceAppointment clonedSA : saClonedList) {
                ServiceAppointment sa = saMap.get(clonedSA.Id);
                if (clonedSA.FSL__GanttIcon__c != sa.FSL__GanttIcon__c) {
                    ServiceAppointment saToUpdate = getSAToUpdateFromMap(sa.Id, saToUpdateMap);
                    saToUpdate.FSL__GanttIcon__c = clonedSA.FSL__GanttIcon__c;
                }
            }

            //   ***   Service Tech Team: The update has been replaced by a map that will be called in the trigger method after all methods have been executed
            // if(!saUpdateList.isEmpty()){
            //     update saUpdateList;
            //     System.debug('Updated SA in FSL_WorOrderTriggerHandler.updateGanttIconOnSA');  
            // }

            // System.debug('Updated SA in FSL_WorOrderTriggerHandler.updateGanttIconOnSA');  
            
            // }                            
        // } catch (Exception e) {
        //     System.debug('RSL_WorkOrderTriggerHandler.updateGanttIconOnSA Error ::' + e.getMessage());
        // }            
    }
    
    /**********
     * @Method Name: updateWorkOrderStatusTimeStamp
     * @Parameters: List<WorkOrder> woList, Map<Id,WorkOrder> oldWorkOrderMap 
     * @Description: Updates timestamp for every status change on workOrder
       @Requirement: 
       @Author: Balaram Naidu.
     * **********/     
    // public static void updateWorkOrderStatusTimeStamp(List<WorkOrder> newWOList, Map<Id,WorkOrder> oldWorkOrderMap){
    //     for(WorkOrder wo : newWOList) {
    //         if(wo.status != oldWorkOrderMap.get(wo.Id).status) {
    //             if(wo.status == 'Scheduled') {
    //                 wo.Scheduled_Timestamp__c = System.now();                   
    //             }else if(wo.status == 'Dispatched') {
    //                 wo.Dispatched_Timestamp__c = System.now();
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }else if(wo.status == 'En Route') {
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //                 // if the en route time stamp hasn't been already set during the En Route Status Transition, update with System Time
    //                 if(wo.Enroute_Timestamp__c == oldWorkOrderMap.get(wo.Id).Enroute_Timestamp__c) {
    //                     wo.Enroute_Timestamp__c = System.now();
    //                 }
    //             }else if(wo.status == 'On Location') {
    //                 if(wo.On_Location_Timestamp__c == oldWorkOrderMap.get(wo.Id).On_Location_Timestamp__c) {
    //                     wo.On_Location_Timestamp__c = System.now();
    //                 }                   
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }else if(wo.status == 'In Tow') {
    //                 if(wo.In_Tow_Timestamp__c == oldWorkOrderMap.get(wo.Id).In_Tow_Timestamp__c) {
    //                     wo.In_Tow_Timestamp__c = System.now();
    //                 }                    
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }else if(wo.status == 'Tow Complete') {
    //                 if(wo.Tow_Complete_Timestamp__c == oldWorkOrderMap.get(wo.Id).Tow_Complete_Timestamp__c) {
    //                     wo.Tow_Complete_Timestamp__c = System.now();
    //                 }                    
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }else if(wo.status == 'Canceled' ) {
    //                 if(wo.Canceled_Timestamp__c == oldWorkOrderMap.get(wo.Id).Canceled_Timestamp__c) {
    //                     wo.Canceled_Timestamp__c = System.now();
    //                 }                    
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }else if(wo.status == 'Cleared') {
    //                 if(wo.Cleared_Timestamp__c == oldWorkOrderMap.get(wo.Id).Cleared_Timestamp__c) {
    //                     wo.Cleared_Timestamp__c = System.now();
    //                 }                    
    //                 wo.Last_Modified_Status_Timestamp__c = System.now();
    //             }
    //         }
    //     }
    // }
    

    //   ***   Service Tech Team: Moved logic to FSL_ServiceAppointmentTriggerHandler    ***

    /**********
     * @Method Name:    resourceCheckForScheduleWO
     * @Parameters:     List<WorkOrder> newWoList, Map<Id,WorkOrder> oldWoMap
     * @Description:    Work Order can not be moved without assigned resource.
     * @Requirement:    UF-98
     * @Author:         Balaram Naidu.
    **********/
    // public static void resourceCheckForScheduleWO(List<WorkOrder> newWoList, Map<Id,WorkOrder> oldWoMap) {
    //     Set<Id> woIdSet = new Set<Id>();
    //     Set<String> statusesToConsider = new Set<String>{'Scheduled','Dispatched','En Route','In Tow','Tow Complete','On Location'};
    //     for(WorkOrder wo : newWoList) {
    //         if(statusesToConsider.contains(wo.status) && wo.status != oldWoMap.get(wo.Id).status) {
    //             woIdSet.add(wo.Id);
    //         }
    //     }
    //     if(!woIdSet.isEmpty()) {
    //         Map<Id,AssignedResource> woResourceMap = new Map<Id,AssignedResource>(); 
    //         List<AssignedResource> assignList = [Select Id, ServiceAppointment.ParentRecordId from AssignedResource where ServiceAppointment.ParentRecordId IN : woIdSet];
    //         for(AssignedResource ass : assignList) {
    //             woResourceMap.put(ass.ServiceAppointment.ParentRecordId,ass);
    //         }
    //         for(WorkOrder wo : newWoList) {
    //          if(Test.isRunningTest()!=true){   
    //             if(wo.Servicing_Technology_Type__c != 'Landline' && woResourceMap.get(wo.Id) == null) {
    //                 wo.addError('Can not mark this status without an assigned resource'); 
    //                 //updated by Matt on 3/25 to remove validation for work orders assigned to landline facilities
    //             }
    //            } 
    //         }
    //     }
    // }
    
    
    /**********
     * @Method Name:    markCallsAsCleared
     * @Parameters:     List<WorkOrder> newWoList - calls with a new Resolution Code
     * @Description:    Work Order should be marked as Cleared when a Resolution Code is provided.
     * @Requirement:    UF-138
     * @Author:         Ryan Johnson
    **********/    
    
    public static void markCallsAsCleared(List<WorkOrder> newWoList){
        // try{
            Set<String> noGoResolutionCodes = new Set<String>();
            noGoResolutionCodes.add('X001');
            noGoResolutionCodes.add('X002');
            
            List<FSL_User_Message__c> messageList = [SELECT Id, Message_Id__c, Message_Text__c FROM FSL_User_Message__c WHERE Message_Id__c = 'SM-021'];
            
            for(WorkOrder wo : newWoList){
                if(wo.Status == 'Spotted' && !noGoResolutionCodes.contains(wo.Resolution_Code__c)){
                    if(!messageList.isEmpty() && messageList.get(0) != null){
                        wo.addError(messageList.get(0).Message_Text__c);
                    }else{
                        wo.addError('Error saving record - markCallsAsCleared');
                    }
                    wo.Resolution_Code__c = '';
                }else{
                    wo.Status = 'Cleared';
                    wo.Locked_After_Clear__c = false;
                }
            }
        
        // }catch(Exception e){
        //     system.debug('exception caught: ' + e);
        // }
    }
    
    /**********
     * @Method Name:    PopulateServiceVehicle
     * @Parameters:     MapOldWorkOrder - Old Map of WorkOrder,MapNewWorkOrder - New Map of WorkOrder,SetWorkOrderId - Id of WorkOrder, 
     * @Description:    Work Order should be marked as Cleared when a Resolution Code is provided.
     * @Requirement:    UF-160
     * @Author:         Sunil Chandani
    **********/    
    
    public static void PopulateServiceVehicle(List<WorkOrder> newWOList,set<string> SetWorkOrderId){
        // try{
            
            //Service Appointment --> Service Resource --> Vehicle --> Truck ID value to a new field on the Work Order called "Service Vehicle"
            Map<Id, Id> wOIdAndVehicleIdMap = new Map<Id, Id>();
        
            //   ***   Service Tech Team: Replaced Record Type Id with "isBreakdown__c" check in SOQL and moved Vehicle check to SOQL    ***
            // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            // for(ServiceAppointment sa : [SELECT Id,ParentRecordId,Service_Resource__r.Vehicle__r.Id FROM ServiceAppointment WHERE ParentRecordId IN : SetWorkOrderId AND RecordTypeId =: breakDownRecordTypeId ]) {
            for(ServiceAppointment sa : [SELECT Id, ParentRecordId, Service_Resource__r.Vehicle__r.Id
                                         FROM ServiceAppointment
                                         WHERE ParentRecordId IN :SetWorkOrderId
                                         AND isBreakdown__c = true
                                         AND Service_Resource__r.Vehicle__r.Id != null])
            {
                // if(sa.Service_Resource__r.Vehicle__r.Id != null) {
                    wOIdAndVehicleIdMap.put(sa.ParentRecordId, sa.Service_Resource__r.Vehicle__r.Id);
                // }
            }
            for(WorkOrder wo : newWOList) {
                Id serviceVehicleId = wOIdAndVehicleIdMap.get(wo.Id);
                if (serviceVehicleId != null ) {
                    wo.Service_Vehicle__c = serviceVehicleId;
                }
            }

        // } catch(Exception e) {
        //     system.debug('exception caught: ' + e);
        // }
    }

    /**********
     * @Method Name:    getSAToUpdateFromMap
     * @Parameters:     saId - Id of Srtvice Appointment, saToUpdateMap - Map of Service Appointment
     * @Description:    Help method that's used in afterUpdate() 
     * @Requirement:
     * @Author:         Sapozhnikov Vladimir
    **********/    
    
    public static ServiceAppointment getSAToUpdateFromMap(Id saId, Map<Id, ServiceAppointment> saToUpdateMap){
        ServiceAppointment saToReturn = saToUpdateMap.get(saId);
        if (saToReturn == null) {
            saToReturn = new ServiceAppointment(Id = saId);
            saToUpdateMap.put(saId, saToReturn);
        }
        return saToReturn;
    }

    /**********
    * @Method Name:sendWorkOrderToRBP
    * @Parameters: List<Id> WoId send to RBP 
    * @Description:Use to send the Work Order to RBP
    @Author: Dhruv Javiya
    * **********/  
    
    /*
    @future(callout=true)
    public static void sendWorkOrderToRBP(Set<Id> WOId){
	List<INTNationalRBPAPIRequest_Wrapper> lstreq=INTNationalRBPAPI.createrbprquest(WOId);
		for(INTNationalRBPAPIRequest_Wrapper req:lstreq){
            INTNationalRBPAPI.sendToStatusToRBP(req);
        }
    }  */ 


}