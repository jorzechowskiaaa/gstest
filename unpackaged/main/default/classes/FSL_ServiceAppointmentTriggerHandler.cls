/**** 
 * *@Name: ServiceAppointmentTriggerHandler 
 * *@Description: when the workorder is created Update the ServiceAppointment Address,lat,lag etc.. from WorkOrder. *  * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0    10/04/2018   Rajesh Kemisetti     Initial Version
 *        07/23/2020   Clement Shiu         Added updateGanttIconsOnSA()
 *        11/19/2020   Dylan Truong         ERS-220004 - 3rd Scheduling Policy
 *        12/02/2020   Clement Shiu         ERS-220415 - Optimization helper refractoring
 *        12/03/2020   Clement Shiu         ERS-220518 - Introduce RAP GAP changes into ACE Org
 *        01/07/2021   Clement Shiu         ERS-220594 - Added D3/4 Release routines related to auto Dispatch Scheduled Calls
 *        01/07/2021   Dylan Truong         ERS-218555 - Enhancement: Improve Visibility of RAP calls  
 *  *     03/18/2021   Dylan Truong         ERS-221797 - Fix Gantt Icon issue when status change by user who are not part of club dispatcher
 *        11/7/2023    Sara Renberg         PR893288-1320 - Fire Robocall event if Call Opt in = true and SMS Opt in = false
 ***/
public class FSL_ServiceAppointmentTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<ServiceAppointment> newList = Trigger.new;
    List<ServiceAppointment> oldList = Trigger.old;
    Map<Id, ServiceAppointment> newMap = (Map<Id, ServiceAppointment>) Trigger.newMap;
    Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>) Trigger.oldMap;

    static Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();

    private List<ETA_Notification__e> manualETAOverrideEventList = new List<ETA_Notification__e>();

    private FSL_ServiceAppointment.IFactory serviceAppointmentFactory = new FSL_ServiceAppointment.Factory();
    private FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService = serviceAppointmentFactory.createService();


    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ServiceAppointment');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {

       //      ***   Service Tech Team: it's better to call getInstance()-method one time   ***



       // if (FSL_Integration_User__c.getInstance('Integration User') != null &&
        //         String.isNotBlank(FSL_Integration_User__c.getInstance('Integration User').User_Name__c) &&
        //         UserInfo.getName() != FSL_Integration_User__c.getInstance('Integration User').User_Name__c) {
        //     for (ServiceAppointment sa : newList) {
        //         sa.addError('Work Orders can only be created through D3/IRAS');
        //     }
        // }

        //Remove comments
        /*FSL_Integration_User__c integUserSetting = FSL_Integration_User__c.getInstance('Integration User');
        system.debug('current User : '+UserInfo.getName());
        Boolean isNotIntegrationUser = (integUserSetting != null && String.isNotBlank(integUserSetting.User_Name__c) && UserInfo.getName() != integUserSetting.User_Name__c);
        for (ServiceAppointment sa : newList) {
            sa.Work_Order__c = sa.ParentRecordId;
            if (isNotIntegrationUser) {
                sa.addError('Work Orders can only be created through D3/IRAS');
            }
        }*/



       //      ***  End Refactoring  ***
            
        FSL_ServiceAppointmentTriggerHandler.updateGanttColoursOnSA(newList, oldMap);
        //ERS-218373:  Set the Gantt Icon for COD                
        FSL_ServiceAppointmentTriggerHandler.updateGanttIconsOnSA(newList);
        //ERS-220220 Extended Zip Code Coverage

        //   *** Service Tech Team: replaced BeforeInsertZipCode-method() with common setZipCode() for both insert and update scope   ***
        // FSL_ServiceAppointmentTriggerHandler.BeforeInsertZipCode(newList);  
        FSL_ServiceAppointmentTriggerHandler.setZipCode(newList, null);  

        System.debug('------------- TIMESTAMP SA BEFORE INSERT finish ----- : ' + Datetime.now());
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        System.debug('------------- TIMESTAMP SA AFTER INSERT start ----- : ' + Datetime.now());
        System.debug('----- newMap.keySet() - ' + newMap.keySet());
        //MODIFY 11/29 - Create SLA Violation History Record for Each Violation.
        FSL_SLA_Violation.createSLAViolationHistory(newList, null);
        //MODIFY 11/7/23 - 
        System.debug('------------- TIMESTAMP SA AFTER INSERT finish ----- : ' + Datetime.now());
        INTNationalHAASAPI HassAPI = new INTNationalHAASAPI();
        HassAPI.prepareHAASalert(newList);
        
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        
        System.debug('@@@@@@ 90 before update begin state ----- : ');
        System.debug('@@@@@@ 91 New Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);
        System.debug('@@@@@@ 92 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
        System.debug('@@@@@@ 93 Old Status - ' + oldList[0].Status + ', SchedStart - ' + oldList[0].SchedStartTime);
        System.debug('@@@@@@ 94 Old Territory ID - ' + oldList[0].ServiceTerritoryID);
        //ERS-220220 Extended Zip Code Coverage

        //   ***   Service Tech Team: replaced BeforeInsertZipCode-method() with common setZipCode() for both insert and update scope   ***
        // FSL_ServiceAppointmentTriggerHandler.BeforeUpdateZipCode(newList, oldMap);
        FSL_ServiceAppointmentTriggerHandler.setZipCode(newList, oldMap);

        // check if appointment can be updated
        if (FSL_ServiceAppointmentTriggerHandler.isPolicyArrivalEndWindowUpdate(oldList, newList))      //   ***   Service Tech Team: strange method (checks only for one record per scope and one change)  ?????   ***
                                                                                                         //   ***   Service Tech Team: Replace this method with a static flag   ?????   ***
        {
            System.debug('------------- TIMESTAMP SA BEFORE UPDATE finish ----- : ' + Datetime.now());
            return;
        }

        //   ***  Service Tech Team: it's better to call getInstance()-method one time   ***
        FSL_Integration_User__c integUserSetting = FSL_Integration_User__c.getInstance('Integration User');
        system.debug('@@@@ Integration User111 @@@@'+integUserSetting);
        //   ***  Service Tech Team: Transfer allowUpdates() method logic (next two lines)   ***
        Execute_Trigger__c execTriggerSetting = Execute_Trigger__c.getValues('ServiceAppointment');
        Boolean isTriggerExecuteLogicEnabled = (execTriggerSetting != null && execTriggerSetting.Execute_Logic__c);


        //   ***  Service Tech Team: Get user name obtaining out of the loop   ***
        String contextUserName = UserInfo.getName();
        system.debug('@@@@ contextUserName @@@@'+contextUserName);
        // Id towRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId();
        List<FSL_ServiceAppointment.ServiceAppointment> scheduledTowAppointments = FSL_ServiceAppointmentEvaluator.getScheduledTowAppointments(newList, serviceAppointmentFactory);
        
        if (!scheduledTowAppointments.isEmpty()) {
            List<FSL_WO_To_SA_Status_Mapping__mdt> woToSaStatusMapping = [SELECT MasterLabel, Breakdown_Appointment__c, Tow_Appointment__c FROM FSL_WO_To_SA_Status_Mapping__mdt];
            serviceAppointmentService.syncStatusBetweenRelatedServiceAppointments(scheduledTowAppointments, woToSaStatusMapping);
        }

        System.debug('@@@@@@@ 128 New Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);
        System.debug('@@@@@@ 129 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
        System.debug('@@@@@@ Old Status - ' + oldList[0].Status + ', SchedStart - ' + oldList[0].SchedStartTime);
        System.debug('@@@@@@ Old Territory ID - ' + oldList[0].ServiceTerritoryID);

        //  ***   End   ***

        //   ***   Service Tech Team: Commented out this method and moved its logic to beforeUpdate()    ***
        // FSL_ServiceAppointmentTriggerHandler.allowUpdates(oldList, newList);
        
        // List<ServiceAppointment> appointmentsWithOverrideReason = new List<ServiceAppointment>();    //   ***   Service Tech Team: Now we keep Override Reason on WO level only  ***
        // List<ServiceAppointment> pinnedAppointments = new List<ServiceAppointment>();    //   ***    Service Tech Team: The only line where the list adds record was commented out before so it will be always empty and not needed  ***
        List<ServiceAppointment> unscheduledCalls = new List<ServiceAppointment>();
        // List<ServiceAppointment> callsInitiallyScheduled = new List<ServiceAppointment>();      //   ***   Service Tech Team: No more needed list   ***
        List<ServiceAppointment> clearedAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> appointmentsRunningLate = new List<ServiceAppointment>();
        // List<ServiceAppointment> appointmentsWithNewViolation = new List<ServiceAppointment>();     //   ***   Service Tech Team: No more needed list   *** 
        // List<ServiceAppointment> saToUpdatePTAViolation = new List<ServiceAppointment>();     //   ***   Service Tech Team: PTA violation logic is moved to flow   *** 
        
        //   ***   Service Tech Team: Not needed variables as its usage was commented out   ***

        // Map<Id, ServiceAppointment> oldAddressMap = new Map<Id, ServiceAppointment>();
        // Map<Id, ServiceAppointment> newAddressMap = new Map<Id, ServiceAppointment>();

        //   ***   Service Tech Team: Replaced newLatLongMap on a list   ***
        // Map<Id, ServiceAppointment> newLatLongMap = new Map<Id, ServiceAppointment>();
        List<ServiceAppointment> newLatLongList = new List<ServiceAppointment>();

        //   ***   Service Tech Team: move all boolean variales below inside the loop logic   ***

        // Boolean callOnLocation;
        // Boolean callInTow;
        // Boolean callCleared;
        // Boolean statusChanged;
        // Boolean callIsScheduled;
        // Boolean callHasNeverBeenScheduled;
        // Boolean newDeltaProvided;
        // Boolean newJeopardyReason;
        // Boolean wasPreviouslyAcknowledged;
        
        //   ***   Service Tech Team: Replaced FSL_ServiceAppointmentEvaluator methods with switch-block in the main loop   ***

        // List<ServiceAppointment> appointmentsWithNewStatus = FSL_ServiceAppointmentEvaluator.getAppointmentsWithNewStatus(oldMap, newList);
        // List<ServiceAppointment> callsSentEnRoute = FSL_ServiceAppointmentEvaluator.getAppointmentsNowEnRoute(appointmentsWithNewStatus);
        // List<ServiceAppointment> callsOnLocation = FSL_ServiceAppointmentEvaluator.getAppointmentsNowOnLocation(appointmentsWithNewStatus);
        // List<ServiceAppointment> callsInTow = FSL_ServiceAppointmentEvaluator.getAppointmentsNowInTow(appointmentsWithNewStatus);
        // List<ServiceAppointment> callsJustStarted = new List<ServiceAppointment>();
        // callsJustStarted.addAll(callsOnLocation);
        // callsJustStarted.addAll(callsInTow);
        
        // List<ServiceAppointment> callsNowCleared = FSL_ServiceAppointmentEvaluator.getAppointmentsThatCleared(appointmentsWithNewStatus);
        // List<ServiceAppointment> callsJustCompleted = new List<ServiceAppointment>();
        // callsJustCompleted.addAll(callsInTow);
        // callsJustCompleted.addAll(callsNowCleared);
        
        // List<ServiceAppointment> getMilesForServiceAppointment = new List<ServiceAppointment>();    
        // getMilesForServiceAppointment.addAll(callsSentEnRoute);
        // getMilesForServiceAppointment.addAll(callsInTow);

        List<ServiceAppointment> saToClearJeopardyList = new List<ServiceAppointment>();
        List<ServiceAppointment> callsSentEnRoute = new List<ServiceAppointment>();
        List<ServiceAppointment> callsJustStarted = new List<ServiceAppointment>();
        List<ServiceAppointment> callsJustCompleted = new List<ServiceAppointment>();
        Map<Id, ServiceAppointment> saToGetMilesMap = new Map<Id, ServiceAppointment>();
        //     ***   Service Tech Team: Move resourceCheckForScheduleWO() logic from FSL_WorkOrderTriggerHandler here    ***
        List<ServiceAppointment> saForResourceScheduleCheckList = new List<ServiceAppointment>();

        List<ServiceAppointment> saForETANotificationList = new List<ServiceAppointment>();
        List<ServiceAppointment> saForDispatchList = new List<ServiceAppointment>();

        List<ServiceAppointment> checkForManualSchedule = new List<ServiceAppointment>(); //AGB added for SSFI-560 11/19/24
        // List<ServiceAppointment> newlyScheduledAppointments = FSL_ServiceAppointmentEvaluator.appointmentsScheduledFromSpotted(oldMap, newList);    //   *** Service Tech Team: The List is used only in commented out code  ***

        //List<ServiceAppointment> scheduledNonEmergencyAppointments = FSL_ServiceAppointmentEvaluator.getMemberScheduledAppointments(newlyScheduledAppointments);


        //   ***   Service Tech Team: beforeUpdate() main loop  ***
        for (ServiceAppointment newSA : newMap.values()) {
            //   ***   Service Tech Team: it's better to get needed records from Trigger maps one time rather than doing it multiple times in the loop  ***
            ServiceAppointment oldSA = oldMap.get(newSA.Id);

            // *** only way to get here from one of the pre En Route state is from the Dispatchch GUI, 
            if ( newSA.Status == 'Canceled' ) {
                FSL_ServiceAppointment.IServiceAppointmentService saSvc = new FSL_ServiceAppointment.Factory().createService();
                if ( saSvc.isAutoClearableOnCancel(oldSA) ) {
                    newSA.Resolution_Code__c = FSL_ServiceAppointment.RESOLUTION_CODE_CANCELED_BEFORE_ENROUTE;
                }   
                newSA.Canceled_Timestamp__c = System.now();
            }
            
            //ASI-424 AGB added for SSFI-560 11/19/24
            if(oldSA.FSL__Schedule_Mode__c != newSA.FSL__Schedule_Mode__c) {
                
                if(newSA.FSL__Schedule_Mode__c == 'Automatic') {
                    newSA.System_Auto_Scheduled__c = true;
                }
               /* else if(newSA.FSL__Schedule_Mode__c == 'Manual') {
                    newSA.Manual_Schedule__c = true;
                }    */
            }
            
            if(oldSA.Service_Resource__c != newSA.Service_Resource__c) {
                checkForManualSchedule.add(newSA);
            } //END ASI-424 AGB added for SSFI-560 11/19/24

            //   ***   Service Tech Team: Added a check on Resolution Code population and, if populated, set "Cleared" status   ***
            if (oldSA.Resolution_Code__c == null && oldSA.Resolution_Code__c != newSA.Resolution_Code__c) {
                newSA.Status = 'Cleared';
            }

            Boolean statusChanged = (oldSA.Status != newSA.Status);
            if (statusChanged) {
                //   ***  Service Tech Team: Transfer allowUpdates() method logic here  ***
                if (isTriggerExecuteLogicEnabled && oldSA.Status == 'Cleared') {
                    newSA.addError('Service Appointment cannot be updated after Clear');
                    continue;
                }
                //   ***   End   ***

                // appointmentsWithNewStatus.add(newSA);

                switch on newSA.Status {
                    when 'Spotted' {
                        //comment below to resolve https://salesforce.atlassian.net/browse/PR893288-1798
                        //unscheduledCalls.add(newSA);
                        newSA.Spotted_Timestamp__c = System.now();
                        //Commented as Jeopardy is handled seperately
                        //saToClearJeopardyList.add(newSA);
                    }
                    when 'Scheduled' {
                        saForResourceScheduleCheckList.add(newSA);
                        newSA.Scheduled_Timestamp__c = System.now();
                        if (oldSA.Status == 'Spotted' && newSA.FSL__InJeopardyReason__c != 'PTA Violation') {
                            //saToClearJeopardyList.add(newSA);
                        }
                        if (integUserSetting != null && contextUserName.equals(integUserSetting.User_Name__c)) {
                            newSA.AutoScheduled__c = true;
                        } else if (newSA.FSL__Schedule_Mode__c != 'Optimization') {
                            newSA.isScheduledByDispatcher__c = true;
                        }
                    }
                    when 'Dispatched' {
                        //Commented as Jeopardy is handled seperately
                        /*
                        if (oldSA.Status == 'Spotted') {
                            saToClearJeopardyList.add(newSA);
                        }*/
                        saForResourceScheduleCheckList.add(newSA);
                        saToGetMilesMap.put(newSA.Id, newSA);
                        newSA.Dispatched_Timestamp__c = System.now();
                    }
                    when 'En Route' {
                        callsSentEnRoute.add(newSA);
                        saToGetMilesMap.put(newSA.Id, newSA);
                        saForResourceScheduleCheckList.add(newSA);
                        newSA.En_Route_Timestamp__c = System.now();
                    }
                    when 'On Location' {
                        callsJustStarted.add(newSA);
                        saForResourceScheduleCheckList.add(newSA);
                        newSA.On_Location_Timestamp__c = System.now();
                    }
                    when 'In Tow', 'Tow Loaded' {
                        // if (newSA.isBreakdown__c && newSA.Status == 'In Tow') {
                        //     newSA.Status = 'Tow Loaded';
                        // }
                        if (newSA.Status == 'In Tow') {
                            if (oldSA.Status == 'Tow Complete') {
                                newSA.Status = 'Tow Complete';
                            } else {
                                saForResourceScheduleCheckList.add(newSA);
                            }
                        }
                        saToGetMilesMap.put(newSA.Id, newSA);
                        callsJustStarted.add(newSA);
                        if (newSA.ActualEndTime == null) {
                            callsJustCompleted.add(newSA);
                        }
                        // if (newSA.Status == 'In Tow') {
                        //     saForResourceScheduleCheckList.add(newSA);
                        // }
                        newSA.In_Tow_Timestamp__c = System.now();
                    }
                    when 'Tow Complete' {
                        saForResourceScheduleCheckList.add(newSA);
                        newSA.Tow_Complete_Timestamp__c = System.now();
                    }
                    when 'Cleared' {
                        // if (!newSA.Is_Cleared__c) {
                        clearedAppointments.add(newSA);
                        // }
                        if (newSA.ActualEndTime == null) {
                            callsJustCompleted.add(newSA);
                        }
                        newSA.Cleared_Timestamp__c = System.now();
                        saToClearJeopardyList.add(newSA);
                    }
                    when 'Canceled' {
                        newSA.Canceled_Timestamp__c = System.now();
                    }
                }
            }

            System.debug('@@@@@@@ Status Changed @@@@' + statusChanged);
            System.debug('@@@@@@@ 319 New Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);
            System.debug('@@@@@@ 320 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
            System.debug('@@@@@@ 321 Status - ' + oldList[0].Status + ', SchedStart - ' + oldList[0].SchedStartTime);
            System.debug('@@@@@@ 322 Territory ID - ' + oldList[0].ServiceTerritoryID);
            system.debug('@@@@ Integration User248 @@@@'+newSA.AutoScheduled__c);
            // Boolean previouslyUnscheduled = String.isBlank(String.valueOf(oldMap.get(saID).SchedStartTime));      //   *** Service Tech Team: variable is never used  ***
            // Boolean futureDatedAppointment = newMap.get(saID).Member_Scheduled__c;      //   *** Service Tech Team: variable is used only in commented out code  ***
            // Boolean newAppointmentTime = oldMap.get(saID).SchedStartTime != newMap.get(saID).SchedStartTime;      //   *** Service Tech Team: variable is never used  ***

            //   ***    Service Tech Team: Placed this check to the only "if" where it's used   ***
            // Boolean inClearedStatus = (oldSA.Status != newSA.Status && newSA.Status == 'Cleared');

            Boolean addressChanged = (oldSA.Street != newSA.Street || oldSA.City != newSA.City || oldSA.PostalCode != newSA.PostalCode);
            
            //   ***    Service Tech Team: Placed this check to the only "if" where it's used  ***
            // Boolean latLongChanged = (oldSA.Latitude != newSA.Latitude || oldSA.Longitude != newSA.Longitude);
            
            //check if appt is breakdown and status is In Tow, change to Tow Loaded

            //   ***   Service Tech Team: Replaced getting a Record Type Id on a formula field ( but Breakdown SA cannot have 'In Tow' status ? )   ***
            // if(newMap.get(saID).RecordTypeId == Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId() && newMap.get(saID).Status == 'In Tow') {
            
            //   ***    Service Tech Team: "In Tow" status for Breakdown SA is not valid   ***
            // if (newSA.isBreakdown__c && newSA.Status == 'In Tow') {
            //     newSA.Status = 'Tow Loaded';
            // }

            // statusChanged = (oldSA.Status != newSA.Status);

            //   ***  Service Tech Team: Get user name obtaining out of the loop   ***
            // String contextUser = UserInfo.getName();

            System.debug('*******10**'+contextUserName);
            
            // TODO: Add to Assigned Resource trigger handler (when estimated travel time changes) for correct order 
            // --> Update Tow Mileage when Tow Address Changes -- Added by Matt on 3/12/2019

            //   ***  Service Tech Team: Replaced address checks on a variable with those checks and replaced SA Subject check on " ! isBreakdown__c" formula field check  ***

            // if ((oldSA.city != newSA.city || oldSA.street != newSA.street || oldSA.postalCode != newSA.postalCode) && newSA.subject == 'Tow Appointment' && !getMilesForServiceAppointment.contains(newSA)) {
            if (addressChanged && !newSA.isBreakdown__c && !saToGetMilesMap.containsKey(newSA.Id)) {
                saToGetMilesMap.put(newSA.Id, newSA);
            }

            //   ***  Service Tech Team: Moved this check directly to the "if"-statement where it's used   ***
            // Boolean callIsUnscheduled = oldSA.status != newSA.status && newSA.status == 'Spotted';

            //   ***  Service Tech Team: Move this check to "switch"-statement  ***
            // if(callIsUnscheduled){
            //     unscheduledCalls.add(newSA);
            // }

            //   ***  Service Tech Team: Place variables' conditions into "if"  ***

            // check to see if the appointment was just given a manual override
            // Boolean previousManualOverrideBlank = String.isBlank(oldSA.Manual_Override_Reason__c);
            // Boolean manualOverrideChanged = oldSA.Manual_Override_Reason__c != newSA.Manual_Override_Reason__c;

            // if(previousManualOverrideBlank && manualOverrideChanged){

            //   ***   Service Tech Team: Now we keep Override Reason on WO level only  ***
            // if (String.isBlank(oldSA.Manual_Override_Reason__c) && oldSA.Manual_Override_Reason__c != newSA.Manual_Override_Reason__c) {
            //     appointmentsWithOverrideReason.add(newSA);
            // }

            //   ***  Service Tech Team: Move this check to "switch"-statement  ***
            // if(inClearedStatus){
            //     clearedAppointments.add(newSA);
            // }

            // if (addressChanged) {
                //   ***  Service Tech Team: Move one line method logic here from setAddressChangedFlag()   ***

                // oldAddressMap.put(newSA.Id, oldSA);
                // newAddressMap.put(newSA.Id, newSA);

            newSA.Address_Changed__c = addressChanged;
            // }

            //   ***  Service Tech Team: Place variables' conditions into "if" and add conditions from reEvaluateServiceTerritoryByPolygons()  ***
            // if(latLongChanged){
            if ((oldSA.Latitude != newSA.Latitude || oldSA.Longitude != newSA.Longitude) && newSA.Status == 'Spotted' && newSA.isBreakdown__c) {
                //   ***   Service Tech Team: Replaced newLatLongMap on a list   ***
                // newLatLongMap.put(newSA.Id, newSA);
                newLatLongList.add(newSA);
            }
            
            //   ***  Service Tech Team: Place variables' conditions into "if" and moved status checks here from handleETAUpdates() method   ***
            // newDeltaProvided = newSA.Schedule_Delta__c != 0 && newSA.Schedule_Delta__c != oldSA.Schedule_Delta__c;
            // if(newDeltaProvided){
            if (newSA.Schedule_Delta__c != 0 && newSA.Schedule_Delta__c != oldSA.Schedule_Delta__c && newSA.Status != 'Cleared' && newSA.Status != 'Canceled') {
                appointmentsRunningLate.add(newSA);
            }                              
            
            //for populating the original scheduled start time
            Boolean callIsScheduled = (newSA.Status == 'Scheduled');
            Boolean callHasNeverBeenScheduled = (oldSA.Original_Scheduled_Start__c == null);
            Boolean firstTimeScheduled = (statusChanged && callIsScheduled && callHasNeverBeenScheduled);
            if (firstTimeScheduled) {
                //   ***   Service Tech Team: No more needed list   ***
                // callsInitiallyScheduled.add(newSA);

                newSA.Original_Scheduled_Start__c = newSA.SchedStartTime;
            }
            
            //   ***   Service Tech Team: PTA violation logic is moved to flow   *** 
            // if (callIsScheduled) {
            //     saToUpdatePTAViolation.add(newSA); 
            // }

            if (callIsScheduled && newSA.isBreakdown__c) {
                saForDispatchList.add(newSA);
            }
            
            Boolean newJeopardyReason = (String.isNotBlank(oldSA.FSL__InJeopardyReason__c) && String.isNotBlank(newSA.FSL__InJeopardyReason__c) && oldSA.FSL__InJeopardyReason__c != newSA.FSL__InJeopardyReason__c);
            //   ***  Service Tech Team: redundant variable  ***
            // wasPreviouslyAcknowledged = oldSA.Acknowledge__c;
            // if (wasPreviouslyAcknowledged && newJeopardyReason) {

            if (oldSA.Acknowledge__c && newJeopardyReason) {
                //   ***   Service Tech Team: No more needed list   ***
                // appointmentsWithNewViolation.add(newSA);
                newSA.Acknowledge__c = false;
            }


            //   ***   Service Tech Team: Moved this whole "if" below to "switch"-statement in main loop   ***

            //check to see if context user is National Integration User & status changing from spotted to scheduled
            // if (oldSA.Status != 'Scheduled' && newSA.Status == 'Scheduled') {

                // TODO: Add to Handler
                // try {
                //     String IntegrationUser = FSL_Integration_User__c.getInstance('Integration User').User_Name__c;
                // } catch (Exception e) {
                //     System.debug('FSL Integration User custom setting not configured');
                // }
                
                // String IntegrationUser = FSL_Integration_User__c.getInstance('Integration User').User_Name__c;
                // if(contextUser.equals(IntegrationUser)){
                //     newSA.AutoScheduled__c = true;
                // } else {
                //     if(newSA.FSL__Schedule_Mode__c != 'Optimization'){
                //         newSA.isScheduledByDispatcher__c = true;
                //     }
                // }
            // }

            if ((newSA.Status == 'On Location' || newSA.Status == 'Tow Complete') && oldSA.FSL__InJeopardy__c != newSA.FSL__InJeopardy__c && newSA.FSL__InJeopardy__c && newSA.isBreakdown__c) {
                saForETANotificationList.add(newSA);
            }
        }
        // ASI- 691 Changes //AGB added for SSFI-560 11/19/24
        if(!checkForManualSchedule.isEmpty()){
            checkManualSchedule(checkForManualSchedule, oldMap);
        }          

        //   ***   Service Tech Team: Move FSL_DispatchUtility.dispatchCurrentCall() invocation from WO handler to here   ***
        checkAndAutoDispatchAppointments(saForDispatchList);

        system.debug('@@@@unscheduledCalls@@@@@'+unscheduledCalls);
        
        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if (!unscheduledCalls.isEmpty()) {
            //   ***   Service Tech Team: Change method parameters list as oldMap is not needed   ***
            // FSL_ServiceAppointmentTriggerHandler.copyOriginalTerritoryToServiceTerritory(newList, oldMap);
        FSL_ServiceAppointmentTriggerHandler.copyOriginalTerritoryToServiceTerritory(unscheduledCalls);
        // }

        //   ***  Service Tech Team: "pinnedAppointments" list will always be empty  ***
        // if(!pinnedAppointments.isEmpty()){
        //     FSL_ServiceAppointmentTriggerHandler.clearpinAppointments(pinnedAppointments);
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!appointmentsWithOverrideReason.isEmpty()){
        // FSL_ServiceAppointmentTriggerHandler.updateOverrideUser(appointmentsWithOverrideReason);    //   ***   Service Tech Team: Now we keep Override Reason on WO level only  ***
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!getMilesForServiceAppointment.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.updateMilesOnServiceAppointment(saToGetMilesMap.values());
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!clearedAppointments.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.updateEndTimes(clearedAppointments);
        // }
        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!callsSentEnRoute.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.updateResourceLocation(callsSentEnRoute);
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!callsJustStarted.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.updateActualStart(callsJustStarted);
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if(!callsJustCompleted.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.updateActualEnd(callsJustCompleted);
        // }

        //   ***   Service Tech Team: Method logic is moved to the beforeUpdate() main loop   ***
        // if(!callsInitiallyScheduled.isEmpty()){
        //     FSL_ServiceAppointmentTriggerHandler.updateOriginalScheduledStart(callsInitiallyScheduled);
        // }

        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity and changed method signature   ***
        // if(!appointmentsRunningLate.isEmpty()){
        FSL_ServiceAppointmentTriggerHandler.handleETAUpdates(appointmentsRunningLate, oldMap, manualETAOverrideEventList);
        // }

        //   ***   Service Tech Team: Method logic is moved to the beforeUpdate() main loop   ***
        // if(!appointmentsWithNewViolation.isEmpty()){
        //     FSL_ServiceAppointmentTriggerHandler.resetAcknowledgeFlag(newList);
        // }
        
        //   ***  Service Tech Team: Commented out as method logic is moved to the main loop  ***
        
        // call appointment time update function
        // if(!oldAddressMap.isEmpty()){
        //     FSL_ServiceAppointmentTriggerHandler.setAddressChangedFlag(oldAddressMap, newAddressMap);
        //     //FSL_ServiceAppointmentTriggerHandler.reEvaluateServiceTerritoryByPolygons(newAddressMap);
        // }

        //   ***   Service Tech Team: Replaced newLatLongMap on a list and removed list check  ***
        // if(!newLatLongMap.isEmpty()){
            // FSL_ServiceAppointmentTriggerHandler.reEvaluateServiceTerritoryByPolygons(newLatLongMap);
        //FSL_ServiceAppointmentTriggerHandler.reEvaluateServiceTerritoryByPolygons(newLatLongList);
        // }

        //Code for SLA (PTA violation)
        // List<ServiceAppointment> saList = new List<ServiceAppointment>();  //   ***  Service Tech Team: never used list  ***

        //   ***  Service Tech Team: There is no need to check status change again when we already have the list "appointmentsWithNewStatus" of SAs with changed statuses  ***

        // List<ServiceAppointment> saToClearJeopardy = new List<ServiceAppointment>();

        // for(Id saId : newMap.keySet()) {
        //     if(newMap.get(saId).Status != oldMap.get(saId).Status) {
        //         // update 04/18: dont clear the jeopardy flag if the call is still in PTA Violation
        //         /*
        //         if(!(newMap.get(saId).PTA_Violation__c)) {
        //             saToClearJeopardy.add(newMap.get(saId));
        //         }
        //         */
        //         saToClearJeopardy.add(newMap.get(saId));
        //     }
        // }

        // if(!saToClearJeopardy.isEmpty()) {
        //     //clear jeopardy on status change
        //     FSL_SLA_Violation.clearJeopardy(saToClearJeopardy);
        // }
        
        //   ***   Service Tech Team: Commented out the check on empty list to reduce complexity   ***
        // if (!appointmentsWithNewStatus.isEmpty()) {
            //clear jeopardy on status change
        FSL_SLA_Violation.clearJeopardy(saToClearJeopardyList);
        // }

        //   ***  End   ***


        //   ***   Service Tech Team: PTA violation logic is moved to flow   *** 
        // if (!saToUpdatePTAViolation.isEmpty()) {
        //     FSL_SLA_Violation.missingPTAByMinutes(saToUpdatePTAViolation);
        // }

        
        FSL_ServiceAppointmentTriggerHandler.updateGanttColoursOnSA(newList, oldMap);
        //ERS-218373:  Set the Gantt Icon for COD
        FSL_ServiceAppointmentTriggerHandler.updateGanttIconsOnSA(newList);              
        FSL_ServiceAppointmentTriggerHandler.setGlympseBrand(newList);
        //     ***   Service Tech Team: Move resourceCheckForScheduleWO() from FSL_WorkOrderTriggerHandler here    ***
        FSL_ServiceAppointmentTriggerHandler.resourceCheckForSchedule(saForResourceScheduleCheckList);

        FSL_ServiceAppointmentTriggerHandler.handleOnLocationTowCompletedViolations(saForETANotificationList, manualETAOverrideEventList);

        //Added by Matt 6/20 to capture if the dispatcher is changing the assigned resource per UF-419
        for (ServiceAppointment sa : newMap.values()) {

            //   ***  Service Tech Team: merged several "if"-s in one and removed try-catch block  ***

            // try{
            //     if(newMap.get(sa.id).Service_Resource__c != oldMap.get(sa.id).Service_Resource__c 
            //         && newMap.get(sa.id).AutoScheduled__c == true && newMap.get(sa.id).FSL__Schedule_Mode__c != 'Optimization' ){
            //             if(FSL_Integration_User__c.getInstance('Integration User') == null){
            //                 sa.Dispatcher_Reassignment__c = true;
            //             }else if(!UserInfo.getName().equals(FSL_Integration_User__c.getInstance('Integration User').User_Name__c)){
            //                 sa.Dispatcher_Reassignment__c = true;
            //             } 
            //         }
            // }catch(Exception e){
            //     System.debug('Issue determining dispatcher reassignment field due to configuration of integration user : ' + e.getMessage());
            // }

            if (sa.Service_Resource__c != oldMap.get(sa.id).Service_Resource__c 
                && sa.AutoScheduled__c && sa.FSL__Schedule_Mode__c != 'Optimization'
                && (integUserSetting == null || !contextUserName.equals(integUserSetting.User_Name__c)) )
            {
                    sa.Dispatcher_Reassignment__c = true;
            }

            //   ***   End   ***
        }
        
        System.debug('------------- before update end state ----- : ');
        System.debug('Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);

        System.debug('------------- TIMESTAMP SA BEFORE UPDATE finish ----- : ' + Datetime.now());
        System.debug('Service TerritoryId Before Update finish- ' + newList[0].ServiceTerritoryId);
        System.debug('@@@@@@ 630 Territory ID - ' + oldList[0].ServiceTerritoryID);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        System.debug('------------- TIMESTAMP SA AFTER UPDATE start ----- : ' + Datetime.now());

        System.debug('------------- after update begin state ----- : ');
        System.debug('Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);

        System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Enter' );
        System.debug('@@@@@@ 643 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
        System.debug('@@@@@@ 644 Territory ID - ' + oldList[0].ServiceTerritoryID);
        if (FSL_ServiceAppointmentTriggerHandler.isPolicyArrivalEndWindowUpdate(oldList, newList))      //   ***   Service Tech Team: strange method (checks only for one record per scope and one change)  ?????   ***
                                                                                                         //   ***   Service Tech Team: Replace this method with a static flag   ?????   ***
        {
            System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Exit' );
            System.debug('------------- TIMESTAMP SA AFTER UPDATE finish ----- : ' + Datetime.now());
            return;
        }
        
        System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Not Policy Arrive End Window Update' );
        //   ***   Service Tech Team: Lists of Ids should be replaced by Sets of Ids   ***
        // List<Id> canceledSAIdList = new List<Id>();
        // List<Id> clearedSAIdList = new List<Id>();

        //   ***   Service Tech Team: Move En Route Platform Events publishing from Task handler here    ***
        Set<Id> enrouteSAIdSet = new Set<Id>();

        // Set<Id> canceledSAIdSet = new Set<Id>();
        // Set<Id> clearedSAIdSet = new Set<Id>();
        Set<Id> canceledOrClearedSAIdSet = new Set<Id>();
        //   ***   Service Tech Team: Move Case closing on Schedule from FSL_WorkOrderTriggerHandler here    ***
        Set<Id> workOrdersToCloseCase = new Set<Id>();

        Map<Id, ServiceAppointment> relatedSAIdToClearedSAMap = new Map<Id, ServiceAppointment>();

        List<ServiceAppointment> appointmentsWithNewStatus = new List<ServiceAppointment>();
        List<ServiceAppointment> saForDispatchNextCallList = new List<ServiceAppointment>();

        List<ServiceAppointment> SAsWithChangedAddress = new List<ServiceAppointment>();
        List<ServiceAppointment> SAswithInviteURL = new List<ServiceAppointment>();
        List<ServiceAppointment> statusChangeEvents = new List<ServiceAppointment>();
        List<ServiceAppointment> statusClearEvents = new List<ServiceAppointment>();        //ERS-229371 FSL RAP Clear Call Platform Event
        List<ServiceAppointment> saForETANotificationList = new List<ServiceAppointment>();

        //   ***   Service Tech Team: A Map of SA's to be put to FSL_NotificationFramework.saEvaluator()   ***
        Map<Id, ServiceAppointment> saToSendNotificationMap = new Map<Id, ServiceAppointment>();

        //   ***   Service Tech Team: Added a map for final bulk SA update DML   ***
        // Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();
        
        //Shankar ERS-226724 Move the ToD3Update initiation from WO to SA Trigger Handler
        Set<Id> woIdsForD3Update = new Set<Id>();
        Set<Id> workOrderIdSet=new Set<Id>();
        
        Map<String, String> saStatusToWOStatus = new Map<String, String>();
        Map<String, String> breakdownStatusToTowStatus = new Map<String, String>();
        for (FSL_WO_To_SA_Status_Mapping__mdt statusMeta : FSL_WO_To_SA_Status_Mapping__mdt.getAll().values()) {
            if (String.isNotBlank(statusMeta.Tow_Appointment__c)) {
                saStatusToWOStatus.put(statusMeta.Tow_Appointment__c, statusMeta.MasterLabel);
            }
            if (String.isNotBlank(statusMeta.Breakdown_Appointment__c)) {
                saStatusToWOStatus.put(statusMeta.Breakdown_Appointment__c, statusMeta.MasterLabel);
                breakdownStatusToTowStatus.put(statusMeta.Breakdown_Appointment__c, statusMeta.Tow_Appointment__c);
            }
        }

        Map<Id, ServiceAppointment> relatedSAMap = new Map<Id, ServiceAppointment>();
        Set<Id> serviceTerritoryIdset=new Set<Id>();
        for (ServiceAppointment newSA : newMap.values()) {
            workOrderIdSet.add(newSa.Work_Order__c);
            if (newSA.FSL__Related_Service__c != null) {
                relatedSAMap.put(newSA.FSL__Related_Service__c, null);
            }
            if(String.isNotBlank(newSa.serviceTerritoryId)){
                serviceTerritoryIdset.add(newSa.serviceTerritoryId);
            }
        }
        if (!relatedSAMap.isEmpty()) {
            relatedSAMap = new Map<Id, ServiceAppointment>([
                SELECT Status, ServiceTerritoryId, Resolution_Code__c, Acknowledge__c, FSL__GanttIcon__c
                FROM ServiceAppointment
                WHERE Id IN :relatedSAMap.keySet()
            ]);
        }

        Map<id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>([SELECT Id, Servicing_Technology_Type__c, External_Id__c, Call_Id__c, Call_Date__c FROM Workorder WHERE Id IN :workOrderIdSet limit 1]);

        Map<Id, List<Technology_Preference__c>> tpRefrenceMap = fetchTechnologyPreference(serviceTerritoryIdset);
        Boolean updateWorkOrders=false;
        //   ***   Service Tech Team: afterUpdate() main loop  ***
        for (ServiceAppointment newSA : newMap.values()) {
            //   ***    Service Tech Team: it's better to get needed records from Trigger maps one time rather multiple times  ***
            ServiceAppointment oldSA = oldMap.get(newSA.Id);

            // Boolean newSchedule = oldSA.SchedStartTime == null && newSA.SchedStartTime != null;      //   ***   Service Tech Team: Unused variable   ***

            //check for appointments that have just been dispatched
            Boolean statusChanged = (oldSA.Status != newSA.Status);
            Boolean serviceterorityIdChanged = (oldSA.serviceTerritoryId != newSA.serviceTerritoryId);
            system.debug('@@@@ service territory Changed@@@@@@'+serviceterorityIdChanged);
            if(serviceterorityIdChanged && newSA.serviceTerritoryId != null) {
                if(newSA.Status == 'Spotted' && newSA.isBreakdown__c) {
                    List<Technology_Preference__c> newSATechPrefList = tpRefrenceMap.get(newSA.serviceTerritoryId);
                    if(newSATechPrefList != null && !newSATechPrefList.isEmpty()) {
                        Workorder wo = workOrderMap.get(newSA.Work_Order__c);
                        if(wo != null) {
                            wo.Servicing_Technology_Type__c = newSATechPrefList[0].Technology_Type__c;
                            updateWorkOrders = true;
                            // SK ERS-229915 Moving this block of code to the After Update of the WO since the WO is updated in this transactiion first
                            // if(newSATechPrefList[0].Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK) {  
                            //     String oldTech = wo.Servicing_Technology_Type__c;
                            //     try {
                            //         ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService = new ThirdPartyIntegration.Factory().createService();
                            //         thirdPartyIntegrationService.sendDispatchOfferPlatformEvent(wo);
                            //     }
                            //     catch(Exception e) {
                            //         wo.Servicing_Technology_Type__c = oldTech;
                            //     }
                            // }
                        }
                    }   
                }

                if(!appointmentsWithNewStatus.Contains(newSA)) {
                    appointmentsWithNewStatus.add(newSA);
                    
                    system.debug('@@appointmentsWithNewStatus 756@@@' + appointmentsWithNewStatus);
                }
                /*if(newSA.Status == 'Scheduled') {
                    system.debug('@@@ 757 WOrkOrderIDs@@');
                    woIdsForD3Update.add(newSA.ParentRecordId);
                }*/
            }
            system.debug('@@@o ldSA.Id : '+oldSA.Id + 'oldSA.ServiceTerritoryId : '+oldSA.ServiceTerritoryId + ' oldSA.Status : '+oldSA.Status);
            system.debug('@@ newSA.Id : '+oldSA.Id + 'newSA.ServiceTerritoryId : '+newSA.ServiceTerritoryId+ ' newSA.Status : '+newSA.Status);

            //If Status changed from Spotted to Scheduled and No Territory Change
            //If Status Changed from Spotted to Scheduled and Territory Change

            if (statusChanged) {
                System.debug('@@@@@@ 768 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
                //appointmentsWithNewStatus.add(newSA);
                if(!appointmentsWithNewStatus.Contains(newSA)) {
                    appointmentsWithNewStatus.add(newSA);
                }

                switch on newSA.Status {
                    when 'Spotted' {
                        if (oldSA.Status == 'Scheduled' || oldSA.Status == 'Dispatched') {
                            workOrdersToCloseCase.add(newSA.ParentRecordId);
                        }
                    }
                    // when 'Scheduled' {
                        //   ***   Service Tech Team: Move Case closing on Schedule from FSL_WorkOrderTriggerHandler here    ***
                        // workOrdersToCloseCase.add(newSA.ParentRecordId);
                    // }
                    when 'Scheduled', 'Dispatched' {
                        if (oldSA.Status == 'Spotted' && newSA.IsBreakdown__c) {
                            system.debug('oldSA.ServiceTerritoryId : '+oldSA.ServiceTerritoryId);
                            system.debug('newSA.ServiceTerritoryId : '+newSA.ServiceTerritoryId);
                            workOrdersToCloseCase.add(newSA.ParentRecordId);
                        }
                        //if(newSA.status == 'Dispatched') {
                        system.debug('newSA.territory Id: '+newSA.ServiceTerritory.Id);
                        system.debug('newSA.territory Facility_Number__c: '+newSA.ServiceTerritory.Facility_Number__c);
                        //if(newSA.status == 'Dispatched') {
                            //woIdsForD3Update.add(newSA.ParentRecordId);
                        //}
                    }
                    //Shankar ERS-226724 Move the ToD3Update initiation from WO to SA Trigger Handler
                    when 'En Route', 'On Location', 'In Tow' {
                        //Only make a callout to D3 if CallSource is D3
                        if(newSA.Call_Source__c == 'D3') {
                            woIdsForD3Update.add( newSA.ParentRecordId);
                        }
                    }
                    when 'Canceled', 'Cleared' {
                        if (newSA.isBreakdown__c && newSA.Service_Resource__c != null) {
                            saForDispatchNextCallList.add(newSA);
                        }
                        canceledOrClearedSAIdSet.add( newSA.Id );
                        System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Service Appointment\'s status is changed to Canceled/Cleared - Id = [' + newSA.Id + '], Status = ' + newSA.Status);
                    }   
                    // when 'Canceled' {
                    //     if (newSA.isBreakdown__c && newSA.Service_Resource__c != null) {
                    //         saForDispatchNextCallList.add(newSA);
                    //     }
                    //     // canceledSAIdSet.add( newSA.Id );
                    //     System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Service Appointment\'s status is changed to Canceled - Id = [' + newSA.Id + ']' );
                    // }
                }
                


                // Take care Status update to National Platform Events
                if (newSA.Status != 'Spotted' && newSA.Status != 'Cleared' && newSA.Status != 'Tow Complete') {
                    statusChangeEvents.add(newSA);   
                } else if(newSA.Status == 'Cleared' && newSA.isBreakdown__c){ //ERS-229371 FSL RAP Clear Call Platform Event
                    statusClearEvents.add(newSA); 
                }
            }

            System.debug('@@@@@@ 825 Service TerritoryId Before Update Start- ' + newList[0].ServiceTerritoryId);
            System.debug('@@@@@@ 826 appointmentsWithNewStatus - ' + appointmentsWithNewStatus);

            if (FSL_NotificationFramework.shouldNotifySA(oldSA, newSA)) {
                saToSendNotificationMap.put(newSA.Id, newSA);
            }

            if (FSL_ServiceAppointmentTriggerHandler.isAddressChanged(oldSA, newSA)) {
                SAsWithChangedAddress.add(newSA);
            } 
            //ERS-230874 Glympse Removal - Part I
            //else if (FSL_ServiceAppointmentTriggerHandler.glympseInviteURL(oldSA, newSA)) {
            //    SAswithInviteURL.add(newSA);
            //}

            if (newSA.FSL__Related_Service__c != null) {
                ServiceAppointment relatedSA = relatedSAMap.get(newSA.FSL__Related_Service__c);

                if (statusChanged && (newSA.Status == 'Canceled' || 
                    (newSA.isBreakdown__c && ((newSA.Status != 'Scheduled' && newSA.Status != 'Dispatched') || relatedSA.Status != 'Spotted')) ) ) 
                {
                    String towCorrespondingStatus = breakdownStatusToTowStatus.get(newSA.Status);
                    if (relatedSA.Status != towCorrespondingStatus && String.isNotBlank(towCorrespondingStatus)) {
                        ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
                        saToUpdate.Status = towCorrespondingStatus;
                    }
                }

                if (newSA.Acknowledge__c != oldSA.Acknowledge__c && newSA.Acknowledge__c != relatedSA.Acknowledge__c) {
                    ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
                    saToUpdate.Acknowledge__c = newSA.Acknowledge__c;
                }

                // System.debug('newSA.Is_Cleared__c != oldSA.Is_Cleared__c = ' + (newSA.Is_Cleared__c != oldSA.Is_Cleared__c));
                // if (newSA.Is_Cleared__c != oldSA.Is_Cleared__c) {
                //     ServiceAppointment saToUpdate = getSAToUpdateFromMap(newSA.FSL__Related_Service__c, saToUpdateMap);
                //     saToUpdate.Is_Cleared__c = newSA.Is_Cleared__c;
                // }

                //   ***    Service Tech Team: Moved the setting of ServiceTerritoryId here from reEvaluateServiceTerritoryByPolygons() method of beforeUpdate()   ***
                if (newSA.ServiceTerritoryId != oldSA.ServiceTerritoryId && newSA.ServiceTerritoryId != relatedSA.ServiceTerritoryId) {
                    ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
                    saToUpdate.ServiceTerritoryId = newSA.ServiceTerritoryId;
                }

                if (newSA.isBreakdown__c && oldSA.Payment_Required__c != newSA.Payment_Required__c && newSA.FSL__GanttIcon__c != relatedSA.FSL__GanttIcon__c) {
                    ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
                    saToUpdate.FSL__GanttIcon__c = newSA.FSL__GanttIcon__c;
                }

                //   ***   Service Tech Team: Added a check on Resolution Code change and collect a map to clear the related appointments      ***

                if (oldSA.Resolution_Code__c == null && oldSA.Resolution_Code__c != newSA.Resolution_Code__c && relatedSA.Resolution_Code__c != newSA.Resolution_Code__c) {
                    // relatedSAIdToClearedSAMap.put(relatedSA.Id, newSA);

                    // saToUpdate.Status = 'Cleared';
                    // saToUpdate.Resolution_Code__c = newSA.Resolution_Code__c;

                    ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
                    saToUpdate.Status = 'Cleared';
                    saToUpdate.Resolution_Code__c = newSA.Resolution_Code__c;
                    saToUpdate.Cleared_Timestamp__c = System.now();
                    saToUpdate.Canceled_Timestamp__c = newSA.Canceled_Timestamp__c;
                }
            }

            //   ***   End   ***

            //   ***   Service Tech Team: Move Platform event publishing on Dispatch or En Route violations from Task handler here      ***

            if (oldSA.FSL__InJeopardy__c != newSA.FSL__InJeopardy__c && newSA.FSL__InJeopardy__c && newSA.isBreakdown__c) {
                if (newSA.Status == 'Dispatched') {
                    saForETANotificationList.add(newSA);
                } else if (newSA.Status == 'En Route') {
                    enrouteSAIdSet.add(newSA.Id);
                }
            }
            
        }

        //   ***   Service Tech Team: This block updates the related appointments if they're not yet updated    ***
        // if (!relatedSAIdToClearedSAMap.isEmpty()) {
        //     List<ServiceAppointment> relatedSAList = [SELECT Id FROM ServiceAppointment WHERE Id IN :relatedSAIdToClearedSAMap.keySet() AND Status != 'Cleared'];
        //     for (ServiceAppointment relatedSA : relatedSAList) {
        //         ServiceAppointment clearedSA = relatedSAIdToClearedSAMap.get(relatedSA.Id);
        //         ServiceAppointment saToUpdate = getSAToUpdateFromMap(relatedSA.Id, saToUpdateMap);
        //         saToUpdate.Status = 'Cleared';
        //         saToUpdate.Resolution_Code__c = clearedSA.Resolution_Code__c;
        //         saToUpdate.Cleared_Timestamp__c = System.now();
        //         System.debug('4' + saToUpdateMap.values());
        //     }
        // }

        if (!saForDispatchNextCallList.isEmpty()) {
            //   ***   Service Tech Team: Move FSL_DispatchUtility.dispatchNextCall() invocation from WO handler to here   ***
            FSL_DispatchUtility.dispatchNextCall(saForDispatchNextCallList, saToUpdateMap);
        }
        
        //   ***   Service Tech Team: Moved this logic block to afterUpdate() main loop   ***
        
        //Following code added by Divyendra 2/20 to make the assigned user follow the service appointment upon clear or cancel and then to post to feed for refresh of mobile app
        //Start refresh issue code
        //Following code added by Divyendra 9/11/2019 as part of the notification framework change
        //Begin new code added 9/11
        // Map<Id,ServiceAppointment> newSAMap = new Map<Id,ServiceAppointment>();
        // Map<Id, ServiceAppointment> oldSAMap = new Map<Id,ServiceAppointment>();
        
        // for(Id saId : newMap.keySet()) {
        //     Boolean relevantChange = FSL_NotificationFramework.shouldNotifySA(oldMap.get(saId), newMap.get(saId));
        //     if(relevantChange) {
        //         newSAMap.put(saId,newMap.get(saId));
        //         oldSAMap.put(saId, oldMap.get(saId));
        //     }
        // }
        
        //   ***   End   ***
        

        //   ***   Service Tech Team: Replaced two maps check on one   ***
        // if( (!newSAMap.isEmpty() && !oldSAMap.isEmpty()) ){
        //     FSL_NotificationFramework.saEvaluator(oldSAMap,newSAMap);
        // }       
        
        if (!saToSendNotificationMap.isEmpty()) {
            FSL_NotificationFramework.saEvaluator(oldMap, saToSendNotificationMap);
        }

        /*if(FSL_NotificationFramework.customAutoFollowSwitch('Technician') || FSL_NotificationFramework.customAutoFollowSwitch('Dispatcher')) {
            List<Mobile_Notification_Event__e>mobileNotificationEventList = new List<Mobile_Notification_Event__e>();
            mobileNotificationEventList = FSL_NotificationFramework.prepareSubscriptionEvent(oldMap, newMap,null,null);
            System.debug('!@#$%Events to insert : ' + mobileNotificationEventList );
            if(!mobileNotificationEventList.isEmpty()) {
                FSL_NotificationFramework.insertEvent(mobileNotificationEventList);
            }
        }*/
        //End new code added 9/11

        // if (!clearedSAIdSet.isEmpty() || !canceledSAIdSet.isEmpty()) {
        if (!canceledOrClearedSAIdSet.isEmpty()) {
            //   ***   Service Tech Team: Refactored "if" body to reduce SOQL-s   ***

            // System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Handling Cleared and/or Canceled service appointments' );
            // List<AssignedResource> arClosedList = new List<AssignedResource>([SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId IN :clearedSAIdList OR ServiceAppointmentId IN :canceledSAIdList]);
            // Map<Id, Id> saIdToSRIdMap = new Map<Id, Id>();
            // for (AssignedResource ar : arClosedList) {
            //     saIdToSRIdMap.put(ar.ServiceAppointmentId, ar.ServiceResourceId);
            // }
            // List<ServiceResource> srList = new List<ServiceResource>( [SELECT Id, RelatedRecordId, Idle__c,RelatedRecord.isactive FROM ServiceResource WHERE Id IN :saIdToSRIdMap.values()] );               
            // System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Handling Cleared and/or Canceled service appointments - Evaluating Idle Indicator on ' + srList.size() + ' Service Resources' );

            List<AssignedResource> arClosedList = [
                SELECT ServiceResource.Idle__c, ServiceResource.RelatedRecord.IsActive
                FROM AssignedResource
                // WHERE ServiceAppointmentId IN :clearedSAIdSet
                // OR ServiceAppointmentId IN :canceledSAIdSet
                WHERE ServiceAppointmentId IN :canceledOrClearedSAIdSet
            ];
            Map<Id, ServiceResource> srMap = new Map<Id, ServiceResource>();
            for (AssignedResource ar : arClosedList) {
                srMap.put(ar.ServiceResourceId, ar.ServiceResource);
            }

            //   ***   End   ***
            
            FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources( srMap.values() );
            // Since this code was dead, and the fix to enable this block of code was to deal with the Idle flag on the Service Resource, the following line will be commented out.
            // FSL_ServiceAppointmentTriggerHandler.clearEmergencyFlagOnResource( newList,oldMap );
        }


        //   ***   Service Tech Team: Moved this "for"-loop logic below to afterUpdate() main loop    ***

        //End Refresh Issue Code
        // List<ServiceAppointment> oldSAs = oldList;
        // List<ServiceAppointment> SAsWithChangedAddress = new List<ServiceAppointment>();
        // List<ServiceAppointment> SAswithInviteURL = new List<ServiceAppointment>();

        // for (ServiceAppointment oldSA : oldSAs) {
        //     ServiceAppointment newSA = newMap.get(oldSA.Id);
        //     Boolean addressFlag = FSL_ServiceAppointmentTriggerHandler.isAddressChanged(oldSA, newSA);
        //     Boolean returnInviteURL = FSL_ServiceAppointmentTriggerHandler.glympseInviteURL(oldSA, newSA);
        //     if (addressFlag) {
        //         SAsWithChangedAddress.add(newSA);
        //     } else if (returnInviteURL) {
        //         SAswithInviteURL.add(newSA);
        //     }
        // }

        //   ***   End   ***

        if (!SAsWithChangedAddress.isEmpty()) {
            FSL_AddressTriggerHandler.SAsWithNewAddress(SAsWithChangedAddress);
        }

        if (!SAswithInviteURL.isEmpty()) {
            FSL_PlatformEventsHandler.createStatusTrackingEvent(SAswithInviteURL);
        }

        //Dipatcher follow code: added by Divyendra 7/23:
        /*Map<Id,ServiceAppointment> saMapNew = new Map<Id, ServiceAppointment>();
        Map<Id,ServiceAppointment> saMapOld = new Map<Id, ServiceAppointment>();
        for(Id saNewId : newMap.keySet()) {
            if(newMap.get(saNewId).ServiceTerritoryId != oldMap.get(saNewId).ServiceTerritoryId) {
                saMapNew.put(saNewId, newMap.get(saNewId));
                saMapOld.put(saNewId, oldMap.get(saNewId));
            }
        }
        if(!saMapNew.isEmpty()) {
            FSL_ServiceAppointmentTriggerHandler.dispatcherSubscription(saMapOld, saMapNew);
        }*/

        //MODIFY 11/29 - Create SLA Violation History Record for Each Violation.
        FSL_SLA_Violation.createSLAViolationHistory(newList, oldMap);

        
        //   ***   Service Tech Team: Moved this "for"-loop logic below to afterUpdate() main loop    ***
        
        // Create platform events for service appointments with status change
        // List<ServiceAppointment> statusChangeEvents = new List<ServiceAppointment>();
        // for (ServiceAppointment sa : appointmentsWithNewStatus) {
        //     if (sa.Status != 'Spotted' && sa.Status != 'Cleared' && sa.Status != 'Tow Complete') {
        //         statusChangeEvents.add(sa);
        //     }
        // }
        
        //   ***   End   ***
        
        
        if (!statusChangeEvents.isEmpty()) {
            FSL_PlatformEventsHandler.statusUpdatesOnPlatformEvent(statusChangeEvents);
        }
        
        // ERS-229371 FSL RAP Clear Call Platform Event
        if(!statusClearEvents.isEmpty()){
            FSL_PlatformEventsHandler.statusClearOnPlatformEvent(statusClearEvents);   
        }

        //   ***   Service Tech Team: Performing final bulk SA update DML   ***
        if (!saToUpdateMap.isEmpty()) {
            System.debug(' ------------- // SAs in Trigger - ' + Trigger.newMap.keySet());
            System.debug(' ------------- // Service AppointmentTrigegerHandler' + saToUpdateMap.values());
            //List<ServiceAppointment> saToUpdateList = saToUpdateMap.values();
            List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
            for ( ServiceAppointment sa : saToUpdateMap.values()) {
                if ( sa.servicing_technology_type__c != ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK) {
                    saToUpdateList.add(sa);
                }
            }
            saToUpdateMap.clear();
            update saToUpdateList;
        }
        
        system.debug('@@@ 1076 Appointment with new status before @@@@');
        if (!appointmentsWithNewStatus.isEmpty()) {
            FSL_ServiceAppointmentTriggerHandler.syncStatusToWO(appointmentsWithNewStatus, saStatusToWOStatus);
        }

        system.debug('@@@ 1081 Appointment with new status after @@@@');
        //   ***   Service Tech Team: Move Case closing on Schedule from FSL_WorkOrderTriggerHandler here    ***
        if (!workOrdersToCloseCase.isEmpty()) {
            closeWOCase(workOrdersToCloseCase);  
        }

        handleDispatchedViolation(saForETANotificationList, manualETAOverrideEventList);

        //   ***   Service Tech Team: Move ETA Platform Events publishing from Task handler here    ***
        if (!manualETAOverrideEventList.isEmpty()) {
            List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(manualETAOverrideEventList);
        }
        
        //ERS-230874 Glympse Removal - Part I
        //if (!enrouteSAIdSet.isEmpty()) {
        //    callGlympseViolation(enrouteSAIdSet);
        //}

        //Shankar ERS-226724 Move the ToD3Update initiation from WO to SA Trigger Handler
        // Process the FSL_ToD3Updates
        system.debug('@@@@1093woIdsForD3Update@@@'+woIdsForD3Update);
        if (!woIdsForD3Update.isEmpty()) {
            FSL_ToD3Update.loadWorkOrders(woIdsForD3Update);
        }
        system.debug('@@@@@ workOrderMap@@@@'+workOrderMap);
        if(updateWorkOrders && !workOrderMap.isempty()){
            update workOrderMap.values();
        }

        System.debug('@@@@@@@@@@@@@ after update end state ----- : ');
        System.debug('Status - ' + newList[0].Status + ', SchedStart - ' + newList[0].SchedStartTime);

        System.debug( 'FSL_ServiceAppointmentTrigger - After Update: Exit' );
        System.debug('------------- TIMESTAMP SA AFTER UPDATE finish ----- : ' + Datetime.now());
        System.debug('Service TerritoryId After Update finish- ' + newList[0].ServiceTerritoryId);
        
        INTNationalHAASAPI HassAPI = new INTNationalHAASAPI();
        HassAPI.preapareToDeleteHAASalert(newList);
    }

    //   ***   Service Tech Team: Help method that's used in afterUpdate()   ***
    public static ServiceAppointment getSAToUpdateFromMap(Id saId, Map<Id, ServiceAppointment> saToUpdateMap) {
        ServiceAppointment saToReturn = saToUpdateMap.get(saId);
        if (saToReturn == null) {
            saToReturn = new ServiceAppointment(Id = saId);
            saToUpdateMap.put(saId, saToReturn);
        }
        return saToReturn;
    }

    //**********
    // * @Description:    check user credentials before creating Service Appointment
    //**********

    // private static void checkCredentialsForSACreation(List<ServiceAppointment> serviceAppointmentList) {

    //     Id profileId=userinfo.getProfileId();
    //     String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
    //     system.debug('ProfileName'+profileName);

    //     FSL_Integration_User__c ers = FSL_Integration_User__c.getInstance('ERS Advocate');
    //     if (ers != null && String.isNotBlank(ers.User_Name__c) && profileName != ers.User_Name__c)  {

    //         FSL_Integration_User__c fiu = FSL_Integration_User__c.getInstance('Integration User');
    //         for (ServiceAppointment sa : serviceAppointmentList) {

    //             //sa.Work_Order__c = sa.ParentRecordId;
    //             if (fiu != null && String.isNotBlank(fiu.User_Name__c) && UserInfo.getName() != fiu.User_Name__c) {
    //                 sa.addError('Service Appointments can only be created through Call Receive/D3/IRAS');
    //             }

    //         }
    //     }        
    // }

    //**********
    // * @Description:    check user credentials before creating Service Appointment
    //**********

    // private static void checkCredentialsForSACreation(List<ServiceAppointment> serviceAppointmentList) {

    //     Id profileId=userinfo.getProfileId();
    //     String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
    //     system.debug('ProfileName'+profileName);

    //     FSL_Integration_User__c ers = FSL_Integration_User__c.getInstance('ERS Advocate');
    //     if (ers != null && String.isNotBlank(ers.User_Name__c) && profileName != ers.User_Name__c)  {

    //         FSL_Integration_User__c fiu = FSL_Integration_User__c.getInstance('Integration User');
    //         for (ServiceAppointment sa : serviceAppointmentList) {

    //             //sa.Work_Order__c = sa.ParentRecordId;
    //             if (fiu != null && String.isNotBlank(fiu.User_Name__c) && UserInfo.getName() != fiu.User_Name__c) {
    //                 sa.addError('Service Appointments can only be created through Call Receive/D3/IRAS');
    //             }

    //         }
    //     }        
    // }

    //   ***   Service Tech Team: Move Case closing on Schedule from FSL_WorkOrderTriggerHandler here    ***
    private void closeWOCase(Set<Id> woIdSet) {
        List<Case> casesToCloseList = [
            SELECT Id
            FROM Case
            WHERE FSL_Work_Order__c IN :woIdSet
            AND RecordType.DeveloperName = 'Violation_Resolution'
            AND FSL_Service_Appointment__r.Status IN ('Spotted','Scheduled', 'Dispatched')
            AND IsClosed = false
        ];
        for (Case caseToClose : casesToCloseList) {
            caseToClose.Status = 'Closed'; 
        }
        if (!casesToCloseList.isEmpty()) {
           update casesToCloseList;
        }
    }

    //     ***   Service Tech Team: Move resourceCheckForScheduleWO() from FSL_WorkOrderTriggerHandler here    ***
    private static void resourceCheckForSchedule(List<ServiceAppointment> newSAList) {
        if (newSAList.isEmpty() || Test.isRunningTest()) {
            return;
        }

        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([
            SELECT Work_Order__r.Servicing_Technology_Type__c, (SELECT Id FROM ServiceResources)
            FROM ServiceAppointment
            WHERE Id IN :newSAList
            AND ServiceAppointment.Work_Order__c != null
        ]);
        for (ServiceAppointment newSA : newSAList) {
            ServiceAppointment sa = saMap.get(newSA.Id);
            if (sa != null && sa.ServiceResources.isEmpty() && (sa.Work_Order__r.Servicing_Technology_Type__c != 'Landline') 
            && (sa.Work_Order__r.Servicing_Technology_Type__c != ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK)) {
                newSA.addError('Can not mark this status without an assigned resource'); 
            }
        }
    }

    //     ***   Service Tech Team: Move On Location/Tow Complete ETA Platform Event creation from Task trigger handler here    ***
    private static void handleOnLocationTowCompletedViolations(List<ServiceAppointment> newSAList, List<ETA_Notification__e> manualETAOverrideEventList) {
        if (newSAList.isEmpty()) {
            return;
        }

        Map<String, FSL_Milestone_Time_Trigger__c> milestoneNamesMap = new map<string, FSL_Milestone_Time_Trigger__c>();
        for (FSL_Milestone_Time_Trigger__c milestoneConfig : FSL_Milestone_Time_Trigger__c.getall().values()) {
            milestoneNamesMap.put(milestoneConfig.Milestone_Name__c, milestoneConfig);
        }

        Set<Id> woIdSet = new Set<Id>();
        for (ServiceAppointment newSA : newSAList) {
            woIdSet.add(newSA.ParentRecordId);
        }
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Worktype.EstimatedDuration FROM WorkOrder WHERE Id IN :woIdSet]);
        
        for (ServiceAppointment newSA : newSAList) {
            String violationName = newSA.Status + ' Violation';
            Decimal duration = milestoneNamesMap.get(violationName).Worktype_Duration__c;
            
            if (duration != null) {
                Integer delta = Integer.valueOf(duration * woMap.get(newSA.ParentRecordId).Worktype.EstimatedDuration);
                newSA.SchedEndTime = newSA.SchedEndTime.addMinutes(delta);
                ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(newSA, delta, newSA.FSL__InJeopardyReason__c /* violationName */ , null, true, false, false, false);
                manualETAOverrideEventList.add(manualETAOverride);
            }
        }
    }

    //     ***   Service Tech Team: Move Dispatched ETA Platform Event creation from Task trigger handler here    ***
    private static void handleDispatchedViolation(List<ServiceAppointment> newSAList, List<ETA_Notification__e> manualETAOverrideEventList) {
        if (newSAList.isEmpty()) {
            return;
        }

        Map<String, FSL_Milestone_Time_Trigger__c> milestoneNamesMap = new map<string, FSL_Milestone_Time_Trigger__c>();
        for (FSL_Milestone_Time_Trigger__c milestoneConfig : FSL_Milestone_Time_Trigger__c.getall().values()) {
            milestoneNamesMap.put(milestoneConfig.Milestone_Name__c, milestoneConfig);
        }

        Decimal dispatchedWarning = milestoneNamesMap.get('Dispatched Warning').Time_Trigger_Minutes__c;
        system.debug('dispatchedWarning 1258' + dispatchedWarning);
        Decimal dispatchedViolation = milestoneNamesMap.get('Dispatched Violation').Time_Trigger_Minutes__c;
        Integer dispatchDelta = Integer.valueOf(dispatchedWarning + dispatchedViolation);
        
        for (ServiceAppointment newSA : newSAList) {
            ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(newSA, dispatchDelta, newSA.FSL__InJeopardyReason__c /* 'Dispatched Violation' */, null, true, true, false, false);
            manualETAOverrideEventList.add(manualETAOverride);
        }
    }

    private void checkAndAutoDispatchAppointments(List<ServiceAppointment> newSAForDispatchList) {
        if (newSAForDispatchList.isEmpty()) {
            return;
        }

        // Set<Id> woIdSet = new Set<Id>();
        // for(ServiceAppointment newSA : newSAForDispatchList) {
        //     woIdSet.add(newSA.ParentRecordId);
        // }

        // Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
        //     SELECT Service_Resource__c, Non_Emergency_Appointment_Time__c FROM WorkOrder WHERE Id IN :woIdSet
        // ]);

        Map<Id, ServiceAppointment> newSAToDispatchMap = new Map<Id, ServiceAppointment>(newSAForDispatchList);
        // for (ServiceAppointment newSA : newSAForDispatchList) {
            // WorkOrder workOrder = woMap.get(newSA.ParentRecordId);
            // workOrder.Service_Resource__c = newSA.Service_Resource__c;
            // if (FSL_DispatchUtility.isEligibleForDispatch(workOrder)) {
                // newSAToDispatchMap.put(newSA.Id, newSA);
            // }
        // }
        // if (!newSAToDispatchMap.isEmpty()) {
            Map<Id, ServiceAppointment> dispatchedSAMap = FSL_DispatchUtility.dispatchCurrentCall(newSAToDispatchMap);
            for (ServiceAppointment dispatchedSA : dispatchedSAMap.values()) {
                ServiceAppointment saToUpdate = newMap.get(dispatchedSA.Id);
                if (saToUpdate == null) {
                    saToUpdate = getSAToUpdateFromMap(dispatchedSA.Id, saToUpdateMap);
                }
                saToUpdate.Status = dispatchedSA.Status;
                saToUpdate.Dispatched_Timestamp__c = dispatchedSA.Dispatched_Timestamp__c;
            }

            //  ***   Service Tech Team: ADD Related App Status update to Dispatched if it exists in Trigger.new   ???????????? -- No
        // }
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

    //   ***   Service Tech Team: Commented out this method and moved its logic to beforeUpdate()    ***

    /**********
     * @Method Name:        allowUpdates
     * @Parameters:         List<ServiceAppointment> oldList, List<ServiceAppointment> newList
     * @Description:        checks if updates are allowed on appointments
       @Requirement:        
       @Author:             Ryan Johnson
     * **********/
    // public static void allowUpdates(List<ServiceAppointment> oldList, List<ServiceAppointment> newList) {
        // for (ServiceAppointment sa : oldList) {
        //     if (Execute_Trigger__c.getValues('ServiceAppointment') != null && Execute_Trigger__c.getValues('ServiceAppointment').Execute_Logic__c) {
        //         if (sa.Status == 'Cleared') {
        //             for (ServiceAppointment saNew : newList) {

        //                 Schema.SObjectType objType = ServiceAppointment.getSObjectType();
        //                 Map<String, Schema.SObjectField> M = Schema.SObjectType.ServiceAppointment.fields.getMap();
        //                 for (String str : M.keyset()) {
        //                     try {
        //                         System.debug('Field name: ' + str + '. New value: ' + saNew.get(str) + '. Old value: ' + sa.get(str));
        //                         if (saNew.get(str) != sa.get(str)) {
        //                             System.debug('******The value has changed!!!! ');
        //                         }
        //                     } catch (Exception e) {
        //                         System.debug('Error: ' + e);
        //                     }
        //                 }

        //                 if (sa.id == saNew.id) {
        //                     if (saNew.Status != sa.Status) {
        //                         saNew.addError('Service Appointment cannot be updated after Clear');
        //                     } else {
        //                         //saNew.D3_Sync_Issue__c = true;
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }
    // }


    //   ***   Service Tech Team: Commented out this method as it's never used anywhere    ***

    /**********
     * @Method Name:        resourceCheckForScheduleSA
     * @Parameters:         Map<Id,ServiceAppointment> oldSaMap, List<ServiceAppointment> newList
     * @Description:        checks if updates are allowed on appointments
       @Requirement:        
       @Author:             Tyler Lafferty
     * **********/
    // public static void resourceCheckForScheduleSA(Map<Id,ServiceAppointment> oldSaMap, List<ServiceAppointment> newList) {
    //     Set<Id> saIdSet = new Set<Id>();
    //     Set<String> statusesToConsider = new Set<String>{'Scheduled','Dispatched','En Route','In Tow','Tow Complete','On Location'};
    //     for (ServiceAppointment sa : newList) {
    //         if (statusesToConsider.contains(sa.Status) && sa.Status != oldSaMap.get(sa.Id).Status) {
    //             saIdSet.add(sa.Id);
    //         }
    //     }
    //     if (!saIdSet.isEmpty()) {
    //         Map<Id,AssignedResource> saResourceMap = new Map<Id,AssignedResource>();
    //         List<AssignedResource> assignList = [SELECT Id, ServiceAppointment.Id FROM AssignedResource WHERE ServiceAppointment.Id IN : saIdSet];
    //         System.debug('resourceCheckForScheduleSA assignList: ' + assignList);
    //         for (AssignedResource ass : assignList) {
    //             saResourceMap.put(ass.ServiceAppointment.Id, ass);
    //         }
    //         System.debug('resourceCheckForScheduleSA saResourceMap: ' + saResourceMap);
    //         for(ServiceAppointment sa : newList) {
    //             if (Test.isRunningTest() != true) {
    //                 if (saResourceMap.get(sa.Id) == null && statusesToConsider.contains(sa.Status) && sa.Status != oldSaMap.get(sa.Id).Status) {
    //                     sa.addError('Can not mark SA this status without an assigned resource');
    //                 }
    //             }
    //         }
    //     }
    // }
    

    //      ***  Service Tech Team: Commented out the unused method  ***
    //
    /**********
     * @Method Name:        pinAppointments
     * @Parameters:         List<ServiceAppointment> futureDatedAppointments
     * @Description:        Sets pinned flag for future Dated Appointments
       @Requirement:        
       @Author:             Ryan Johnson
     * **********/
    // public static void pinAppointments(List<ServiceAppointment> futureDatedAppointments) {
    //     for (ServiceAppointment sa : futureDatedAppointments) {
    //         sa.FSL__Pinned__c = true;
    //     }
    // }
    

    //      ***  Service Tech Team: Use one setZipCode()-method for both before insert / update instead of similar BeforeInsertZipCode() and BeforeUpdateZipCode() methods ***
    
    /**
     * @File Name          : FSL_ServiceTerritoryTrigger.trigger
     * @Description        : For Zip Code-Extended Match Rule. Calls Handler class to update all the SA's ZIP_Code_For_Coverage_Lookup__c field when the ST field Restrict_coverage_via_zip_code__c get updated.
                            ERS-220220-Extended Match on Zip Codes
    * @Author             : Bastine
    * @Last Modified On   : 12-12-2022
    * @Modification Log   : 
    * Ver       Date            Author                 Modificat
    * ion
    * 1.0    11/25/2020   Bastine             Initial Version
    **/
    private static void setZipCode(List<ServiceAppointment> saNewList, Map<Id, ServiceAppointment> saOldMap) {
        try {
            Set<Id> stIdSet = new Set<Id>();
            Set<String> postalCodes = new Set<String>();
            Map<String, ID> zipCodeNameIDMap = new Map<String, ID>();
            for (ServiceAppointment serApp : saNewList) {
                stIdSet.add(serApp.ServiceTerritoryId);
            }
            
            //      ***  Service Tech Team: Map of SObjects can be directly created from list  ***
            
            // Map<Id,ServiceTerritory> serTerritoriesMap = new Map<Id,ServiceTerritory>();
            // for(ServiceTerritory st : serTerritoriesList){
            //     serTerritoriesMap.put(st.Id,st);
            // }
            Map<Id, ServiceTerritory> serTerritoriesMap = new Map<Id, ServiceTerritory>([
                SELECT Id, Restrict_coverage_via_zip_code__c FROM ServiceTerritory WHERE Id IN :stIdSet
            ]);


            for (ServiceAppointment serApp : saNewList) {
                // If postal code is changed or the Record Type (very rare or may never happen) is changed
                
                //    ***  Service Tech Team: if-statement below handles both insert and update conditions  ***
    
                if ((Trigger.isInsert || serApp.PostalCode != saOldMap.get(serApp.ID).PostalCode || serApp.isBreakdown__c != saOldMap.get(serApp.ID).isBreakdown__c)
                    && serApp.ServiceTerritoryId != null && serApp.PostalCode != null && serApp.isBreakdown__c && serTerritoriesMap.get(serApp.ServiceTerritoryId).Restrict_coverage_via_zip_code__c) {
                        postalCodes.add(serApp.PostalCode);
                }
            }

            System.debug('UpdateZipCodeRestriction:: PostalCodeToRestrict ' + postalCodes);
            
            if (postalCodes.isEmpty()) {
                return;
            }
            
            for (Zip_Code__c zip : [SELECT ID, Name FROM Zip_Code__c WHERE Name IN :postalCodes]) {
                zipCodeNameIDMap.put(zip.Name, zip.Id);
                System.debug('UpdateZipcodeCoverageST::Adding Zipcode to cache::zip.Name' +zip.Name +', zip.Id' + zip.Id );
            }
            for (ServiceAppointment serApp : saNewList) {
                if (zipCodeNameIDMap.containsKey(serApp.PostalCode)) {
                    serApp.ZIP_Code_For_Coverage_Lookup__c = zipCodeNameIDMap.get(serApp.PostalCode);
                    System.debug('UpdateZipcodeCoverageST::Updated serApp::' + serApp);
                }
            }
        } catch(exception exp) {
            FSL_ApplicationLogCreator.schedulingLogger('FSL_ServiceAppointmentTriggerHandler.BeforeUpdateZipCode',exp.getmessage(),true);
        }
    }

    //ERS-220220 Extended Match Zip Code Coverage
    // public static List<ServiceAppointment> BeforeInsertZipCode(List<ServiceAppointment> sanewList) {
    //     Set<Id> stId = new Set<Id>();
    //     Set<String> postalCodes = new Set<String>();
    //     Map<string, ID> ZipCodeNameIDMap = new Map<string, ID>();
    //     List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
    //     try {
    //         for (ServiceAppointment serApp :sanewList) {
    //             stId.add(serApp.ServiceTerritoryId);
    //         }
            
    //         List<ServiceTerritory> serTerritoriesList = [SELECT Id, Restrict_coverage_via_zip_code__c FROM ServiceTerritory WHERE Id IN :stId];
    //         Map<Id, ServiceTerritory> serTerritoriesMap = new Map<Id, ServiceTerritory>();
    //         for (ServiceTerritory st:serTerritoriesList) {
    //             serTerritoriesMap.put(st.Id,st);
    //         }
            
    //         for (ServiceAppointment serApp : sanewList) {
    //             // If postal code is changed or the Record Type (very rare or may never happen) is changed
    //             if (serApp.ServiceTerritoryID != null && serApp.isBreakdown__c && serTerritoriesMap.get(serApp.ServiceTerritoryID).Restrict_coverage_via_zip_code__c) {
    //                 if (serApp.PostalCode != null) {
    //                     postalCodes.add(serApp.PostalCode);
    //                 }
    //                 System.debug('UpdateZipCodeRestriction:: PostalCodeToRestrict ' + postalCodes);
    //             }
    //         }
    //         if (!postalCodes.isEmpty()) {
    //             for (Zip_Code__c zip : [SELECT ID, Name from Zip_Code__c WHERE name IN:postalCodes]) {
    //                 ZipCodeNameIDMap.put(zip.Name, zip.Id);
    //                 System.debug('UpdateZipcodeCoverageST::Adding Zipcode to cache::zip.Name' +zip.Name +', zip.Id' + zip.Id );
    //             }
    //         }
    //         for (ServiceAppointment serApp: sanewList) {
    //             if (ZipCodeNameIDMap.containsKey(serApp.PostalCode)) {
    //                 serApp.ZIP_Code_For_Coverage_Lookup__c = ZipCodeNameIDMap.get(serApp.PostalCode);
    //                 System.debug('UpdateZipcodeCoverageST::Updated SA::' + serApp);
    //                 serviceAppointments.add(serApp);
    //             }
    //         }
    //     }//End of try
    //     catch(exception exp) {
    //         FSL_ApplicationLogCreator.schedulingLogger('FSL_ServiceAppointmentTriggerHandler.BeforeInsertZipCode',exp.getmessage(),true);
    //     }
    //     return serviceAppointments;
    // }

    //      ***  End  ***



    //   ***  Service Tech Team: The method is commented out as "pinnedAppointments" list will always be empty and the method will never be launched  ***

    /**********
     * @Method Name:        clearpinAppointments
     * @Parameters:         List<ServiceAppointment> pinnedAppointments
     * @Description:        Sets pinned flag for false ,when Status is On Location Appointments.
       @Requirement:        
       @Author:             Shravan bagam
     * **********/
    // public static void clearpinAppointments(List<ServiceAppointment> pinnedAppointments) {
    //     System.debug('====pinnedAppointments==' + pinnedAppointments);
    //     for (ServiceAppointment sa : pinnedAppointments) {
    //         sa.FSL__Pinned__c = false;
    //     }
    // }
 


    //   *** Service Tech Team: Changed method's signature  ***

    /**********
     * @Method Name:handleETAUpdates
     * @Parameters:(Map<Id, ServiceAppointment>,Map<Id, ServiceAppointment>)
     * @Description: Before a new schedule delta is sent in by the technician, the current service appointment times are incremented
       @Requirement: 
       @Author: Ryan Johnson
     * **********/
    // public static void handleETAUpdates(Map<ID, ServiceAppointment> newMap, Map<ID, ServiceAppointment> oldMap) {
    private static void handleETAUpdates(List<ServiceAppointment> appointmentsRunningLate, Map<ID, ServiceAppointment> oldMap, List<ETA_Notification__e> manualETAOverrideEventList) {
        List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        
        //   *** Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
        // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();

        // Set<Id> serviceAppointmentIdSet = new Set<Id>();    //   *** Service Tech Team: The Set is never used  ***
        // Set<Id> serviceResourceSet = new Set<Id>();   //   *** Service Tech Team: The Set is used only in commented out code  ***
        List<ServiceAppointment> arrivedSAList = new List<ServiceAppointment>();
        // Map<Id, AssignedResource> saIdAssignedRes = new Map<Id, AssignedResource>();        //   *** Service Tech Team: The Map is never used  ***

        // filter Service Appointments that just got a schedule update from the technician via the app
        for (ServiceAppointment newSA : appointmentsRunningLate) {
            //   ***    Service Tech Team: it's better to get needed records from Trigger maps one time rather multiple times  ***
            ServiceAppointment oldSA = oldMap.get(newSA.Id);
            
            //   ***    Service Tech Team: Moved this "if"-conditions to beforeUpdate() main loop   ***
            // if ((oldSA.Schedule_Delta__c != newSA.Schedule_Delta__c) &&
            //         (newSA.Schedule_Delta__c != 0) &&
            //         (newSA.Status != 'Cleared' && newSA.Status != 'Canceled')) {

            // check if the work type duration was extended
            if (oldSA.Extend_Work_Time_Counter__c < newSA.Extend_Work_Time_Counter__c) {
                // add to the arrived List
                arrivedSAList.add(newSA);
            }
            //   ***   Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
            // check breakdown appointment record type for status change
            // if ((newSA.RecordTypeId == breakDownRecordTypeId)) { isBreakdown__c
            else if (newSA.isBreakdown__c) {
                if (newSA.Status == 'Dispatched' || newSA.Status == 'En Route') {
                    saUpdateList.add(newSA);
                }
                if (newSA.Status == 'On Location') {
                    arrivedSAList.add(newSA);
                }
            } else {
                //   ***    Service Tech Team: Is "On Location" status removed for Tow SA  ?????   ***
                if (newSA.Status == 'On Location' || newSA.Status == 'In Tow') {
                    saUpdateList.add(newSA);
                }
                if (newSA.Status == 'Tow Complete') {
                    arrivedSAList.add(newSA);
                }
            }
                //   *** Service Tech Team: The Set is used only in commented out code  ***
                // if(newSA.service_resource__c != null){
                //      serviceResourceSet.add(newSA.service_resource__c);
                // }
            // }
        }

        if (!saUpdateList.isEmpty()) {
            handleEnrouteETA(saUpdateList, oSettings, manualETAOverrideEventList);
        }
        if (!arrivedSAList.isEmpty()) {
            handleArrivedETA(arrivedSAList, oSettings, manualETAOverrideEventList);
        }
        
        /*Map<id,Boolean> isRsHavingStkCallsMap = null;
        if(!serviceResourceSet.isEmpty()){
             isRsHavingStkCallsMap= FSL_OptimizationHelper.checkStackedCallsForTheResource(serviceResourceSet);
        }*/
        

        /*if (!manualETAOverrideEventList.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(manualETAOverrideEventList);
        }*/
    }
    
    @TestVisible
    private static void handleArrivedETA(List<ServiceAppointment> arrivedSAList, FSL_Optimization_Settings__c oSettings, List<ETA_Notification__e> manualETAOverrideEventList) {
        // List<ETA_Notification__e> manualETAOverrideEventList = new List<ETA_Notification__e>();
        for (ServiceAppointment sa : arrivedSAList) {
            // set the schedule delta
            Integer delta = Integer.valueOf(sa.Schedule_Delta__c);

            // move the scheduled end by the delta value
            sa.SchedEndTime = sa.SchedEndTime?.addMinutes(delta);
            sa.Duration = sa.Duration + delta;

            //Boolean runRSO = false;
            Boolean dispatchedViolation = false;
            /*if(isRsHavingStkCallsMap== null || isRsHavingStkCallsMap.get(sa.Service_Resource__c)){
                runRSO = true;
            }*/
            Boolean runRSO = false;
            if (delta > oSettings.RSO_Threshold__c) {
                runRSO = true;
            }            
            // create the platform event
            ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(sa, delta, 'Behind Schedule - Work In Progress', null, true, false, runRSO, false);//createTravelDelayPE(sa, delta);

            // add the event to the list
            manualETAOverrideEventList.add(manualETAOverride);
        }

        //   *** Service Tech Team: Moved Platform Events publishing to the end of afterUpdate()  ***
        // if (!manualETAOverrideEventList.isEmpty()) {
        //     List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(manualETAOverrideEventList);            
        // }
       
    }

    private static void handleEnrouteETA(List<ServiceAppointment> saUpdateList, FSL_Optimization_Settings__c oSettings, List<ETA_Notification__e> manualETAOverrideEventList) {
        List<ResourceAbsence> absenseList = new List<ResourceAbsence>();
        // List<ETA_Notification__e> manualETAOverrideEventList = new List<ETA_Notification__e>();
        for (ServiceAppointment sa : saUpdateList) {
            // set the schedule delta
            Integer delta = Integer.valueOf(sa.Schedule_Delta__c);
            //Boolean runRSO = false;
            Boolean dispatchedViolation = false;
            /*if(isRsHavingStkCallsMap== null || isRsHavingStkCallsMap.get(sa.Service_Resource__c)){
                runRSO = true;
            }*/
            Boolean runRSO = false;
            if (delta >= oSettings.RSO_Threshold__c) {
                runRSO = true;
            }            
            // create the platform event
            ETA_Notification__e manualETAOverride = FSL_OptimizationHelper.createETAPlatformEvent(sa, delta, 'Behind Schedule - Travel Delays', null, true, true, runRSO, false);//createTravelDelayPE(sa, delta);

            // add the event to the list
            manualETAOverrideEventList.add(manualETAOverride);

            // create the resource absence to block off the resources time
            ResourceAbsence ra = new ResourceAbsence();

            ra.ResourceID = sa.Service_Resource__c;

            // utilize same address for this absence as the appointment that is impacted
            ra.latitude = sa.latitude;
            ra.longitude = sa.longitude;

            ra.Start = sa.SchedStartTime;
            ra.End = (sa.SchedStartTime).addMinutes(delta);

            ra.Type = 'Travel Delay';

            //   *** Service Tech Team: it's better to get Record Type Ids by its DeveloperNames because they're less likely to change  ***

            // ra.recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get('Non Availability').getRecordTypeId();
            ra.recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability').getRecordTypeId();

            ra.FSL__GanttLabel__c = 'Running Late By ' + delta + ' minutes';
            absenseList.add(ra);
        }

        if (!absenseList.isEmpty()) {
            insert absenseList;
        }
        //   *** Service Tech Team: Moved Platform Events publishing to the end of afterUpdate()  ***
        // if (!manualETAOverrideEventList.isEmpty()) {
        //     List<Database.SaveResult> results = FSL_OptimizationHelper.publishPlatformEvents(manualETAOverrideEventList);
        // }
    }


    //   *** Service Tech Team: Commented out this method and moved to beforeUpdate() main loop as it's short and used only in one place  ***

    /**********
     * @Method Name:setAddressChangedFlag
     * @Parameters:(Map<Id, ServiceAppointment>,Map<Id, ServiceAppointment>)
     * @Description: Method accepts oldMap and newMap on after update trigger on ServiceAppointment, evaluates if the address on SA changed  and updates the flag
     * **********/
    // public static void setAddressChangedFlag(Map<Id, ServiceAppointment> oldSAMap, Map<Id, ServiceAppointment> newSAMap) {

    //     for (ServiceAppointment saNew : newSAMap.values()) {
    //         for (ServiceAppointment saOld : oldSAMap.values()) {
    //             if (saNew.Id == saOld.id) {
    //                 saNew.Address_Changed__c = true;
    //             }
    //         }
    //     }        
    // }


    //   ***   Service Tech Team: Commented out this method as it's not used anywhere   ***

    /**********
    * @Method Name:constructFeedItemMap
    * @Parameters:(List<Id>, String)
    * @Description: Method accepts the list of ServiceAppointment Ids and constructs the Id, Message map for calling the FSL_ChatterUtilities.postThis method
    @Return: N/A
    @Author: Divyendra Naidu
    * **********/
    // public static void constructFeedItemMap(List<Id>saIdList, String messageId) {
    //     Map<Id, String> posts = new Map<Id, String>();
    //     for (Id saId : saIdList) {
    //         posts.put(saId, messageId);
    //     }
    //     FSL_ChatterUtilities.postThis(posts);
    // }

    @TestVisible
    private static void syncStatusToWO(List<ServiceAppointment> updatedAppointments, Map<String, String> saStatusToWOStatus) {
        Set<Id> workOrderIdSet = new Set<Id>();
        Set<Id> updatedStatusWoIdSet = new Set<Id>();
        set<string> facilityNumberList = new set<string>();
        Map<Id, WorkOrder> updateWOMap = new Map<Id, WorkOrder>();
        Map<Id, string> saToFacilityMap = new Map<Id, string>();
        list<ServiceAppointment> newSAList = new list<ServiceAppointment>();
        Map<string, Id> facilityToAccMap = new Map<string, Id>();
        for (ServiceAppointment sa : updatedAppointments) {
            workOrderIdSet.add(sa.ParentRecordId);
            System.debug('@@@@1748 sa&&&' + sa.Facility_Number__c);
            System.debug('@@@@1748 sa&&&' + sa.ServiceTerritoryId);
        }

        //retrieve the statuses for SAtoWO sync
        // Map<String, String> SAStatusToWOStatus = new Map<String, String>();
        // for (FSL_WO_To_SA_Status_Mapping__mdt WOToSAStatus : [SELECT MasterLabel, Breakdown_Appointment__c, Tow_Appointment__c FROM FSL_WO_To_SA_Status_Mapping__mdt]) {
        //     if (!String.isEmpty(WOToSAStatus.Tow_Appointment__c)) {
        //         SAStatusToWOStatus.put(WOToSAStatus.Tow_Appointment__c, WOToSAStatus.MasterLabel);
        //     }
        //     if (!String.isEmpty(WOToSAStatus.Breakdown_Appointment__c)) {
        //         SAStatusToWOStatus.put(WOToSAStatus.Breakdown_Appointment__c, WOToSAStatus.MasterLabel);
        //     }
        // }
        
        //   ***   Service Tech Team: Unneeded map anymore   ***

        //map the SA status to the WO level so the WO status can be compared if it matches with any of the SA status  
        // Map<Id, Set<String>> woIdToSAStatusMap = new Map<Id, Set<String>>();
        // for (ServiceAppointment sa : updatedAppointments) {
        //     if (woIdToSAStatusMap.containsKey(sa.ParentRecordId)) {
        //         woIdToSAStatusMap.get(sa.ParentRecordId).add(sa.Status);
        //     } else {
        //         woIdToSAStatusMap.put(sa.ParentRecordId, new Set<String>{ sa.Status });
        //     }
        // }

        //   ***   Service Tech Team: Refactored code block   ***
        // for (WorkOrder wo : [SELECT Id, Status, Service_Resource__c, ServiceTerritoryId FROM WorkOrder WHERE Id IN :workOrderIdSet]) {
        //     for (ServiceAppointment sa : updatedAppointments) {
        //         System.debug('wo.status====>'+wo.status+'sa.status====>'+sa.status);
        //         System.debug('sa====>'+sa);
        //         //if the WO status does not match any of the SA status then update the WO. At least one SA status to be in sync with the WO status
        //         if (!WOToSAStatusMap.get(sa.ParentRecordId).contains(wo.Status) && !updateWoIdSet.contains(wo.Id)) {                    
        //             updateWoIdSet.add(wo.Id);
        //             //the WO status is retrived from the mapping based on the SA status via a custom metadata
        //             wo.Status = SAStatusToWOStatus.get(sa.Status);
        //             if (wo.ServiceTerritoryId != sa.serviceTerritoryId) {
        //                 wo.ServiceTerritoryId = sa.serviceTerritoryId;
        //             }
        //             // Only Update the WO Service Resource if the WO and SA are related and their SR is different
        //             if (sa.Service_Resource__c != null && wo.Id == sa.ParentRecordId && wo.Service_Resource__c != sa.Service_Resource__c) {
        //                 wo.Service_Resource__c = sa.Service_Resource__c;
        //             }
        //             updateWOList.add(wo);
        //         }
        //     }
        // }
       
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [SELECT Id, Status, AccountId, Service_Resource__c, ServiceTerritoryId FROM WorkOrder WHERE Id IN :workOrderIdSet
        ]);

        Map<Id, ServiceAppointment> clearedWOIdToSAMap = new Map<Id, ServiceAppointment>();

        for (ServiceAppointment sa : updatedAppointments) {
            WorkOrder wo = workOrderMap.get(sa.ParentRecordId);
            
            system.debug('wo.ServiceTerritoryId != sa.ServiceTerritoryId' + 'WO ' + wo.ServiceTerritoryId + 'SA ' + sa.ServiceTerritoryId);
            //   ***   Service Tech Team: Moved this block here from "if"-statement below (also it's a part of reEvaluateServiceTerritoryByPolygons() method )   ***
            if (wo.ServiceTerritoryId != sa.ServiceTerritoryId) {
                if(sa.Facility_Number__c != null) {
                    facilityNumberList.add(sa.Facility_Number__c);
                    saToFacilityMap.put(sa.Id,sa.Facility_Number__c);
                    newSAList.add(sa);
                }
                wo.ServiceTerritoryId = sa.ServiceTerritoryId;
               
                updateWOMap.put(wo.Id, wo); 
            }
            system.debug('@@@@@@ ServiceTerritoryId @@@@@@@@@@'+facilityNumberList);
            system.debug('@@@@@@ ServiceTerritoryId @@@@@@@@@@'+saToFacilityMap);
            system.debug('@@@@@@ ServiceTerritoryId @@@@@@@@@@'+newSAList);

            if(facilityNumberList != null && !facilityNumberList.isEmpty()) {
                list<Account> accList = [select id,Facility_ID__c from Account where Facility_ID__c IN :facilityNumberList];
                for(Account acc : accList) {
                    facilityToAccMap.put(acc.Facility_ID__c,acc.Id);
                }
                if(!facilityToAccMap.isEmpty()) {
                    for(ServiceAppointment sap : newSAList) {
                        WorkOrder wor = workOrderMap.get(sa.ParentRecordId);
                        if(saToFacilityMap.get(sap.Id) != null && facilityToAccMap.get(saToFacilityMap.get(sap.Id)) != null) {
                            wor.AccountId = facilityToAccMap.get(saToFacilityMap.get(sap.Id));
                            updateWOMap.put(wor.Id, wor);
                            
                         
                        }
                    }
                }
            }
            //if the WO status does not match any of the SA status then update the WO. At least one SA status to be in sync with the WO status

            //   ***   Service Tech Team: Refactored "if" statement   ***
            // if (!woIdToSAStatusMap.get(sa.ParentRecordId).contains(wo.Status) && !updatedStatusWoIdSet.contains(wo.Id)) {                    
            String correspondingWOStatus = saStatusToWOStatus.get(sa.Status);
            if (correspondingWOStatus != wo.Status && !updatedStatusWoIdSet.contains(wo.Id)) {                    
                updatedStatusWoIdSet.add(wo.Id);
                // wo.Status = SAStatusToWOStatus.get(sa.Status);

                
                //   ***   Service Tech Team: Added a check for not Spotted status to keep WO In Progress   ***
                if (sa.Status != 'Spotted') {
                    //the WO status is retrived from the mapping based on the SA status via a custom metadata
                    wo.Status = correspondingWOStatus;
                   
                    if (wo.Status == 'Cleared') {
                        wo.Resolution_Code__c = sa.Resolution_Code__c;
                        clearedWOIdToSAMap.put(wo.Id, sa);   
                    }
                    updateWOMap.put(wo.Id, wo);
                    
                    
                }

                //   ***   Service Tech Team: Moved this block out of "if"-statement   ***
                // if (wo.ServiceTerritoryId != sa.ServiceTerritoryId) {
                //     wo.ServiceTerritoryId = sa.ServiceTerritoryId;
                // }

                // Only Update the WO Service Resource if the WO and SA are related and their SR is different
                if (sa.Service_Resource__c != null && wo.Service_Resource__c != sa.Service_Resource__c) {
                    wo.Service_Resource__c = sa.Service_Resource__c;
                    updateWOMap.put(wo.Id, wo);
                    
                
                }
            }
        }

        if (!clearedWOIdToSAMap.isEmpty()) {
            populateStatusTimestampsOnClearedWOs(clearedWOIdToSAMap, updateWOMap);
        }

        //   ***   End   ***
        system.debug('@@@@@@ workOrder details @@@@@@@@@@'+updateWOMap);
        if (!updateWOMap.isEmpty()) {
            update updateWOMap.values();
            system.debug('@@@@@@ workOrder details @@@@@@@@@@:-- '+updateWOMap);

            // List<Database.SaveResult> results = Database.update(updateWOMap.values(), false);
            // for (Database.SaveResult saveResult : results) {
            //     if (!saveResult.success) {
            //         System.debug('AppointmentUpdateFailureAfterClear::' + saveResult.Id + '\nErrors::' + saveResult.getErrors());
            //     }
            // }
        }
        system.debug('@@@@@@ DOne with workOrder update @@@@@@@@@@');
    }


    //   ***   Service Tech Team: New method for filling WO timestamps from its related appointments   ***

    private static void populateStatusTimestampsOnClearedWOs(Map<Id, ServiceAppointment> clearedWOIdToSAMap, Map<Id, WorkOrder> updateWOMap) {
        Set<Id> relatedSAIdSet = new Set<Id>();
        for (ServiceAppointment sa : clearedWOIdToSAMap.values()) {
            if (sa.FSL__Related_Service__c != null) {
                relatedSAIdSet.add(sa.FSL__Related_Service__c);
            }
        }

        Map<Id, ServiceAppointment> relatedSAMap = new Map<Id, ServiceAppointment>();
        if (!relatedSAIdSet.isEmpty()) {
            relatedSAMap = new Map<Id, ServiceAppointment>([
                SELECT Scheduled_Timestamp__c, Dispatched_Timestamp__c, En_Route_Timestamp__c, On_Location_Timestamp__c,
                        In_Tow_Timestamp__c, Tow_Complete_Timestamp__c, Canceled_Timestamp__c, Payment_Required__c
                FROM ServiceAppointment
                WHERE Id IN :relatedSAIdSet
            ]);
        }

        for (Id woId : clearedWOIdToSAMap.keySet()) {
            WorkOrder woToUpdate = updateWOMap.get(woId);
            ServiceAppointment firstRelatedSA = clearedWOIdToSAMap.get(woId);
            ServiceAppointment breakdownSA;
            ServiceAppointment towSA;
            if (firstRelatedSA.isBreakdown__c) {
                breakdownSA = firstRelatedSA;
                towSA = relatedSAMap.get(firstRelatedSA.FSL__Related_Service__c);
            } else {
                towSA = firstRelatedSA;
                breakdownSA = relatedSAMap.get(firstRelatedSA.FSL__Related_Service__c);
            }

            //   ***   Service Tech Team: Filling the WO timestamps from its related appointments   ***

            if (breakdownSA != null) {
                woToUpdate.Scheduled_Timestamp__c = breakdownSA.Scheduled_Timestamp__c;
                woToUpdate.Dispatched_Timestamp__c = breakdownSA.Dispatched_Timestamp__c;
                woToUpdate.Enroute_Timestamp__c = breakdownSA.En_Route_Timestamp__c;
                woToUpdate.On_Location_Timestamp__c = breakdownSA.On_Location_Timestamp__c;
                woToUpdate.Canceled_Timestamp__c = breakdownSA.Canceled_Timestamp__c;
                
                // woToUpdate.Payment_Required__c = breakdownSA.Payment_Required__c;
            }
            
            if (towSA != null) {
                woToUpdate.In_Tow_Timestamp__c = towSA.In_Tow_Timestamp__c;
                woToUpdate.Tow_Complete_Timestamp__c = towSA.Tow_Complete_Timestamp__c;
            }

            woToUpdate.Cleared_Timestamp__c = System.now();
            woToUpdate.Last_Modified_Status_Timestamp__c = System.now();
        }
    }


    //   ***   Service Tech Team: Now we keep Override Reason on WO level only  ***

    /**********
     * @Method          Name:updateOverrideUser
     * @Parameters:     List<ServiceAppointment>
     * @Description:    Method will update the SA to indicate who moved the ServiceAppointment
     * @Requirement:    Ability to track what percentage of automatic assignments are overridden at a club and facility level
     * @Author:         Ryan Johnson
     * **********/
    // private static void updateOverrideUser(List<ServiceAppointment> appointmentsWithOverrideReason) {
    //     //   ***    Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()   ***
    //     if (appointmentsWithOverrideReason.isEmpty()) {
    //         return;
    //     }
    //     Profile userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
    //     String usrName = UserInfo.getName();
    //     String profileName = userProfile.Name.toLowerCase();
    //     for (ServiceAppointment sa : appointmentsWithOverrideReason) {
    //         sa.Overridden_By__c = usrName;
    //         if (profileName.contains('club')) {
    //             sa.Schedule_Overridden_By__c = 'Club';
    //         } else {
    //             sa.Schedule_Overridden_By__c = 'Facility';
    //         }
    //     }
    // }


    //   ***   Service Tech Team: Commented out this method as it's not used anywhere   ***

    /**********
     * @Method          Name:updateRelatedSAs
     * @Parameters:     Set<Id>
     * @Description:    Method updates the children SA of each of the (parent) SAs that are updated to the Spotted status.
     * @Requirement:    Ability to move other related SAs to Spotted status when one of the SA becomes Spotted.
     * @Author:         Ryan Johnson
     * **********/
    // public static void updateRelatedSAs(Set<Id> oldSpottedSAs) {
    //     String message = '';
    //     List<ServiceAppointment> parentSAs = new List<ServiceAppointment>();
    //     List<ServiceAppointment> childrenSA = new List<ServiceAppointment>();
    //     try {
    //         parentSAs = [
    //                 SELECT Id, FSL__Related_Service__c, D3_Call_ID__c, (SELECT Id, Status FROM FSL__Service_Appointments__r WHERE Status != :'Spotted')
    //                 FROM ServiceAppointment
    //                 WHERE Id IN:oldSpottedSAs
    //         ];
    //         for (ServiceAppointment parentSA : parentSAs) {
    //             childrenSA.addAll(parentSA.FSL__Service_Appointments__r);
    //         }
    //         for (ServiceAppointment childSA : childrenSA) {
    //             childSA.Status = 'Spotted';
    //         }

    //         update childrenSA;
    //         message = 'UnscheduledAppointmentIds::' + JSON.serializePretty(oldSpottedSAs) + '\n';
    //         message += 'RelatedUnscheduledAppointmentIds::' + JSON.serializePretty(childrenSA) + '\n';
    //         //FSL_ApplicationLogCreator.schedulingLogger('Unscheduling', message, false);
    //     } catch (Exception e) {
    //         message = 'Exception::' + e.getTypeName() + '::' + e.getMessage();
    //         message += 'UnscheduledAppointmentIds::' + JSON.serializePretty(oldSpottedSAs) + '\n';
    //         message += 'RelatedUnscheduledAppointmentIds::' + JSON.serializePretty(childrenSA) + '\n';
    //         //FSL_ApplicationLogCreator.schedulingLogger('Unscheduling', message, true);
    //     }
    // }


    /**
    *       Rolls the service appointment back to the original (parent) territory when the appointment is set to spotted status
    *
    */

    //   *** Service Tech Team: Changed method's parameters list as oldMap is not needed  ***

    // public static void copyOriginalTerritoryToServiceTerritory(List<ServiceAppointment> saList, Map<Id, ServiceAppointment> oldSAMap) {
    @TestVisible
    private static void copyOriginalTerritoryToServiceTerritory(List<ServiceAppointment> saList) {
        system.debug('@@@@@ COPY CALLED@@@@@@@');
        for (ServiceAppointment sa : saList) {
            //   *** Service Tech Team: Redundant "if", this check was already done in beforeUpdate()  ***
            
            // if (sa.status != oldSAMap.get(sa.Id).status && sa.status == 'Spotted') {
            sa.ServiceTerritoryId = sa.Original_Service_Territory__c;
            sa.Service_Resource__c = null;
            // }
        }
    }


    /**********
     * @Method Name:updateMilesOnServiceAppointment
     * @Parameters :List<ServiceAppointment> 
     * @Description: This will retrieve the assigned resource on Service appointment and update the miles on Service appointment
       @Requirement: Update SLR En Route Miles & SLR Tow Miles
       @Author: Binod Shaw
     * **********/
    @TestVisible
    private static void updateMilesOnServiceAppointment(List<ServiceAppointment> getMilesForServiceAppointmentList) {
        //   *** Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()  ***
        if (getMilesForServiceAppointmentList.isEmpty()) {
            return;
        }
        
        //   ***   Service Tech Team: This Set of Ids is used in SOQL but the List of records can be used in SOQL instead, so additional Set is not needed    ***
        // Set<Id> serviceAppointmentIds = new Set<Id>();
        // for (ServiceAppointment sa : getMilesForServiceAppointment) {
        //     serviceAppointmentIds.add(sa.Id);
        // }

        Map<Id, AssignedResource> saAssignedResourceMap = new Map<Id, AssignedResource>();
        List<AssignedResource> assignResourceList = [
            SELECT AssignedResourceNumber, ServiceAppointmentId, FSL__EstimatedTravelDistanceFrom__c, FSL__EstimatedTravelDistanceTo__c
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :getMilesForServiceAppointmentList      // :serviceAppointmentIds
        ];
        for (AssignedResource ar : assignResourceList) {
            saAssignedResourceMap.put(ar.ServiceAppointmentId, ar);
        }

        for (ServiceAppointment sa : getMilesForServiceAppointmentList) {

            //   ***   Service Tech Team: Refactored loop body   ***

            // if (sa.subject == 'Breakdown Appointment' && saAssignedResourceMap.get(sa.Id) != null) {
            //     sa.SLR_En_Route_Miles__c = saAssignedResourceMap.get(sa.Id).FSL__EstimatedTravelDistanceTo__c;
            // }
            // if (sa.subject == 'Tow Appointment' && saAssignedResourceMap.get(sa.Id) != null) {
            //     sa.SLR_Tow_Miles__c = saAssignedResourceMap.get(sa.Id).FSL__EstimatedTravelDistanceTo__c;
            // }

            AssignedResource assignRes = saAssignedResourceMap.get(sa.Id);
            if (assignRes == null) {
                continue;
            }

            if (sa.isBreakdown__c) {
                sa.SLR_En_Route_Miles__c = assignRes.FSL__EstimatedTravelDistanceTo__c;
            } else {
                sa.SLR_Tow_Miles__c = assignRes.FSL__EstimatedTravelDistanceTo__c;
            }
        }
    }

    /**
     *  @purpose  -  Update actual end times to allow for shift logic to run
     *
     *        -  Also adds a one minute buffer to the end times, since test cases are failing when
     *        -  the user goes from On Location to Cleared / Canceled within one minute
     */
    public static void updateEndTimes(List<ServiceAppointment> clearedOrCanceledAppointments) {
        //   *** Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()  ***
        if (clearedOrCanceledAppointments.isEmpty()) {
            return;
        }

        DateTime nowTime = System.now();
        // Remove second component for comparison to scheduled start / end times
        DateTime clearedTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
        // DateTime threshold = System.now();   //   ***   Service Tech Team: Unused variable   ***

        //   *** Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
        // Id breakdownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();

        Map<ServiceAppointment, Integer> appointmentToTimeDelta = new Map<ServiceAppointment, Integer>();
        Map<ServiceAppointment, ID> appointmentToResource = new Map<ServiceAppointment, ID>();
        Map<Id,ServiceAppointment> workOrdIdSAMap = new Map<Id,ServiceAppointment>();
        Map<Id,ServiceAppointment> resourceIdTimeDeltaMap = new Map<Id,ServiceAppointment>();

        Set<Id> woIds = new Set<Id>();
        for (ServiceAppointment sa : clearedOrCanceledAppointments) {
            woIds.add(sa.ParentRecordId);
        }

        //   ***    Service Tech Team: WO SOQL is not needed as Resolution Code appearing on SA first    ***
        // Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Resolution_Code__c FROM WorkOrder WHERE Id IN :woIds]);

        for (ServiceAppointment sa : clearedOrCanceledAppointments) {
            System.debug('SchedStartTime: '+sa.SchedStartTime);
            System.debug('SchedEndTime: '+sa.SchedEndTime);           
            
            //   ***   Service Tech Team: Moved this check to beforeUpdate() main loop    ***
            // is cleared check prevents this logic from running twice
            // if (!sa.Is_Cleared__c) {
                
            // Integer timeDelta;    //   ***  Service Tech Team: The variable is used only in one inner "if"   ***

            //   ***   Service Tech Team: Refactored "if"-statement below   ***
            // determine if this is the last appointment in the work order
            // if ((sa.FSL_IsLight_Service__c && sa.recordTypeId == breakdownRecordTypeId) || (sa.FSL_IsLight_Service__c == false && sa.recordTypeId != breakdownRecordTypeId)) {
            if (sa.FSL_IsLight_Service__c == sa.isBreakdown__c) {
                System.debug(' ----- HERE 0 ----');

                // if the call was cleared at a different time than expected
                if (sa.SchedEndTime != null && sa.SchedEndTime != clearedTime) {
                    //   ***   Service Tech Team: Cloning SAs before setting changes for further Platform Events creation in FSL_OptimizationHelper    ***
                    ServiceAppointment clonedSA = sa.clone(true, true, true, true);

                    System.debug(' ----- HERE 0 ----');

                    appointmentToResource.put(clonedSA, clonedSA.Service_Resource__c);

                    // get the delta between the expected end and actual end
                    Integer timeDelta = Integer.valueOf((clonedSA.SchedEndTime.getTime() - clearedTime.getTime()) / 60000);
                    appointmentToTimeDelta.put(clonedSA, timeDelta);
                    resourceIdTimeDeltaMap.put(clonedSA.Service_Resource__c, clonedSA);//need to change Here
                    workOrdIdSAMap.put(clonedSA.ParentRecordId, clonedSA);
            
                //   ***   Service Tech Team: This method gets only Cleared SAs, so Cancelled SAs cannot appear here  ?????   ***
                } else if (sa.status == 'Canceled') {//if call was cancelled, the run In Day
                    //   ***   Service Tech Team: Cloning SAs before setting changes for further Platform Events creation in FSL_OptimizationHelper    ***
                    ServiceAppointment clonedSA = sa.clone(true, true, true, true);

                    System.debug(' ----- HERE 0 ----');

                    appointmentToTimeDelta.put(clonedSA, 0);
                    resourceIdTimeDeltaMap.put(clonedSA.Service_Resource__c, clonedSA);
                    workOrdIdSAMap.put(clonedSA.ParentRecordId, clonedSA);
                }
            }

            //   ***   Service Tech Team: Merged two method's loops in one, second loop body is below this line   ***

            sa.Is_Cleared__c = true;

            //   ***    Service Tech Team: WO is not needed as Resolution Code now appears on SA first    ***
            // get the work order resolution code for the X001 exception
            // WorkOrder wo = woMap.get(sa.ParentRecordId);
            // String resolutionCode = '';
            // if (wo != null) {
            //     resolutionCode = wo.Resolution_Code__c;
            // }
            // System.debug('resolutionCode: ' + resolutionCode);
            // System.debug('clearedTime = ' + clearedTime);

            if (sa.isBreakdown__c) {
                // if clearedTime is less than scheduled start

                if (sa.SchedStartTime == null || clearedTime < sa.SchedStartTime) {

                    // update start to cleared time and end to cleared time + 1
                    if (!sa.FSL_IsLight_Service__c) {
                        sa.SchedStartTime = clearedTime.addMinutes(-3);
                        sa.SchedEndTime = clearedTime.addMinutes(-2);
                    } else {
                        sa.SchedStartTime = clearedTime.addMinutes(-1);
                        sa.SchedEndTime = clearedTime;
                    }
                // } else if ('X001'.equals(resolutionCode)) {
                } else if ('X001' == sa.Resolution_Code__c) {
                    sa.SchedEndTime = sa.SchedStartTime.addMinutes(1);
                    
                // if (sa.SchedStartTime == null || sa.Resolution_Code__c == 'X001' || clearedTime < sa.SchedStartTime) {
                //     sa.SchedStartTime = clearedTime;
                //     sa.SchedEndTime = clearedTime.addMinutes(1);

                // else update end to cleared time if this call is Light Service
                } else if (sa.FSL_IsLight_Service__c || clearedTime < sa.SchedEndTime) {
                    if (sa.SchedStartTime != clearedTime) {
                        sa.SchedEndTime = clearedTime;
                    } else {
                        sa.SchedStartTime = clearedTime.addMinutes(-1);
                        sa.SchedEndTime = clearedTime;
                    }
                }

            // if tow
            // and if clearedTime is less than scheduled start

            } else if (sa.SchedStartTime == null || clearedTime < sa.SchedStartTime) {

                // update start to cleared time + 3 and end to + 4 (to not overlap breakdown)
                sa.SchedStartTime = clearedTime.addMinutes(-1);
                sa.SchedEndTime = clearedTime;
            // } else if ('X001'.equals(resolutionCode)) {
            } else if ('X001' == sa.Resolution_Code__c) {
                sa.SchedEndTime = sa.SchedStartTime.addMinutes(1);
                
            // } else if (sa.SchedStartTime == null || sa.Resolution_Code__c == 'X001' || clearedTime < sa.SchedStartTime) {
            //     sa.SchedStartTime = clearedTime.addMinutes(2);
            //     sa.SchedEndTime = clearedTime.addMinutes(3);
                
                // else update end to clearedTime
            } else if (sa.SchedStartTime != clearedTime) {
                sa.SchedEndTime = clearedTime;
            } else {
                sa.SchedEndTime = clearedTime.addMinutes(1);
            }

            //   ***   End    ***

            // }
        }

        if (!appointmentToTimeDelta.isEmpty()) {
            System.debug(' ----- HERE 0 ----');
            FSL_OptimizationHelper.shiftAppointment(workOrdIdSAMap, appointmentToTimeDelta, resourceIdTimeDeltaMap, appointmentToResource);
        }


        //   ***   Service Tech Team: Merged this second loop with the first method's loop   ***

        // for (ServiceAppointment sa : clearedOrCanceledAppointments) {
        //     // set start time (if call was cleared before On Location)
        //      if(!sa.Is_cleared__c){
        //         sa.Is_Cleared__c = true;
                   
        //         // if breakdown
        //         if (sa.recordTypeId == breakdownRecordTypeId) {
        //             // if clearedTime is less than scheduled start
        //             if (sa.SchedStartTime == null || clearedTime < sa.SchedStartTime) {
        //                 // update start to cleared time and end to cleared time + 1
        //                 if (!sa.FSL_IsLight_Service__c) {
        //                     sa.SchedStartTime = clearedTime.addMinutes(-3);
        //                     sa.SchedEndTime = clearedTime.addMinutes(-2);
        //                 } else {
        //                     sa.SchedStartTime = clearedTime.addMinutes(-1);
        //                     sa.SchedEndTime = clearedTime;
        //                 }
        //             } else {
        //                 // else update end to cleared time if this call is Light Service
        //                 if (sa.FSL_IsLight_Service__c || clearedTime < sa.SchedEndTime) {
        //                     if (sa.SchedStartTime != clearedTime) {
        //                         sa.SchedEndTime = clearedTime;
        //                     } else {
        //                         sa.SchedStartTime = clearedTime.addMinutes(-1);
        //                         sa.SchedEndTime = clearedTime;
        //                     }
        //                 }
        //             }
        //         } else { // if tow

        //             // if clearedTime is less than scheduled start
        //             if (sa.SchedStartTime == null || clearedTime < sa.SchedStartTime) {
        //                 // update start to cleared time + 3 and end to + 4 (to not overlap breakdown)
        //                 sa.SchedStartTime = clearedTime.addMinutes(-1);
        //                 sa.SchedEndTime = clearedTime;

        //             } else {
        //                 // else update end to clearedTime
        //                 if (sa.SchedStartTime != clearedTime) {
        //                     sa.SchedEndTime = clearedTime;
        //                 } else {
        //                     sa.SchedEndTime = clearedTime.addMinutes(1);
        //                 }
        //             }
        //         }
        //     } 
        // }

    }


    //   ***   Service Tech Team: The method is commented out as it's never used in code   ***
    
    /**********
     * @Method          Name:checkUpdateOnServiceAppointmentAfterClearedStatus
     * @Parameters:     List<ServiceAppointment>,Map<Id,ServiceAppointment>
     * @Description:    Method is to check any update on ServiceAppointment after status is changed to Cleared. 
     * @Requirement:    Lock Service Appointment once status is changed to Cleared. 
     * @Author:         Binod Shaw
     * **********/

    // public static void checkUpdateOnServiceAppointmentAfterClearedStatus(List<ServiceAppointment> saList, Map<Id, ServiceAppointment> oldServiceAppointmentMap) {

    //     Id SysAdminId = FSL_OrgCache.sysAdminProfileId();

    //     for (ServiceAppointment sa : saList) {
    //         Long timeIntervalSec = (sa.LastModifiedDate.getTime() - oldServiceAppointmentMap.get(sa.Id).LastModifiedDate.getTime()) / 1000;
    //         if (oldServiceAppointmentMap.get(sa.Id).Status == 'Cleared' && (timeIntervalSec > 60) && (UserInfo.getProfileId() != SysAdminId)) {
    //             sa.addError('Service Appointment can not be changed after status is changed to Cleared');
    //         }
    //     }
    // }


    //   ***   Service Tech Team: Commented out and moved syncAcknowledgeIndicatorOnRelated()'s logic to afterUpdate()   ***

    /**********
     * @Method Name:        syncAcknowledgeIndicatorOnRelated
     * @Parameters:         List<ServiceAppointment> acknowledgements
     * @Description:        Syncs acknowledge indicator on related service appointments
       @Requirement:        
       @Author:             Matthew Pantell 3/12/2019
     * **********/
    // public static void syncAcknowledgeIndicatorOnRelated(Map<Id, ServiceAppointment> acknowledgementsMap, Boolean setValue) {
    //     List<ServiceAppointment> related = [SELECT Id, Acknowledge__c FROM ServiceAppointment where FSL__Related_Service__c in :acknowledgementsMap.keySet()];
    //     List<ServiceAppointment> acknowledgeRelatedUpdates = New List<ServiceAppointment>();
    //     for (ServiceAppointment sa : related) {
    //         sa.Acknowledge__c = setValue;
    //         acknowledgeRelatedUpdates.add(sa);
    //     }
    //     System.debug('Updating related');
    //     update acknowledgeRelatedUpdates;
    // }
    
    //   ***    End     ***
    
    


    /**********
     * @Method Name:fillInAppointment
     * @Parameters: List<ServiceAppointment> appointmentsCompletedEarly
     * @Description: Sets scheduled end to actual end and fills in the schedule
       @Requirement: Optimize Schedule on Early Call Completion
       @Author: Ryan Johnson
     * **********/

    /*public static void fillInAppointment(Map<ServiceAppointment, Integer> appointmentToTimeSavedMap, List<ServiceAppointment> appointmentsCompletedEarly, Map<ServiceAppointment, ID> appointmentToResource) {
        // shift impacted appointments earlied in time before fill-in schedule is called
        system.debug('entering shift appointment logic'); 
        FSL_AppointmentScheduleHelper.shiftAppointments(appointmentToTimeSavedMap, system.now().addDays(-1), appointmentToResource);

    }*/

    public static void updateResourceLocation(List<ServiceAppointment> saList) {
        //   ***   Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()    ***
        if (saList.isEmpty()) {
            return;
        }

        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>([
            SELECT Id, Resource_Latitude__c, Resource_Longitude__c, Service_Resource__r.LastKnownLatitude, Service_Resource__r.LastKnownLongitude
            FROM ServiceAppointment
            WHERE Id IN :saList
        ]);
        
        //   *** Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
        // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();

        for (ServiceAppointment sa : saList) {
            if (sa.Resource_Latitude__c == null && sa.Resource_Longitude__c == null) {
                sa.Resource_Latitude__c = saMap.get(sa.Id).Service_Resource__r.LastKnownLatitude;
                sa.Resource_Longitude__c = saMap.get(sa.Id).Service_Resource__r.LastKnownLongitude;
            }
    
            //   *** Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
            // if (sa.FSL_Enroute_Time_Stamp__c == null && sa.RecordTypeId == breakDownRecordTypeId) {
            if (sa.FSL_Enroute_Time_Stamp__c == null && sa.isBreakdown__c) {
                sa.FSL_Enroute_Time_Stamp__c = System.now();
            }
        }
    }

    /**********
     * @Method Name:updateActualStart
     * @Parameters: List<ServiceAppointment> saList - appointments that just went on location or in tow
     * @Description: Sets actual start for breakdown appointments
       @Requirement: Update the actual start the first time the call goes On Location
       @Author: Ryan Johnson
     * **********/
    public static void updateActualStart(List<ServiceAppointment> saList) {
        //   ***   Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()    ***
        if (saList.isEmpty()) {
            return;
        }

        //   ***   Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field   ***
        // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();

        DateTime nowTime = System.now();
        DateTime currentTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
        // DateTime currentTime = DateTime.newInstanceGMT(nowTime.yearGMT(), nowTime.monthGMT(), nowTime.dayGMT(), nowTime.hourGMT(), nowTime.minuteGMT(), 0);
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        Map<id, Integer> serviceAppointmenttoDelta = new Map<id, Integer>();

        for (ServiceAppointment sa : saList) {
            if (sa.FSL_In_Tow_Timestamp__c == null && ('In Tow'.equalsIgnoreCase(sa.status)) || 'Tow Loaded'.equalsIgnoreCase(sa.status)) {
                sa.FSL_In_Tow_Timestamp__c = System.now();
            }

            if (sa.ActualStartTime == null) {
                // if the appointment is a breakdown and the call doesn't already have an actual start time
                if ('On Location'.equals(sa.Status) && sa.IsBreakdown__c) {
                    //   ***   Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field  ***
                    // if (sa.RecordTypeId == breakDownRecordTypeId) {
                    sa.ActualStartTime = currentTime;//system.now();
                    System.debug('ActualEndTime:'+sa.ActualStartTime+' SchedEndTime:'+sa.SchedStartTime);                         
                    
                    //   ***   Service Tech Team: Removed "sa.ActualStartTime != null" condition as this field is populated above with the current time   ***
                    //Technician Arrives On Location Early or late
                    // if (sa.ActualStartTime != sa.SchedStartTime  && sa.ActualStartTime != null && sa.SchedStartTime != null) {
                    if (sa.ActualStartTime != sa.SchedStartTime && sa.SchedStartTime != null) {
                        appointments.add(sa);
                        serviceAppointmenttoDelta.put(sa.Id, Integer.valueOf(sa.ActualStartTime.getTime()-sa.SchedStartTime.getTime())/60000 );
                    }
                }

                //   ***   Service Tech Team: Merged two "if"-s in one and replaced Record Type Id check on " ! isBreakdown__c" formula field   ***
                // if ('Tow Complete'.equals(sa.Status)) {
                //     if (sa.RecordTypeId != breakDownRecordTypeId) {
                //         sa.ActualStartTime = System.now();
                //     }
                // }

                if (sa.Status.equals('Tow Complete') && !sa.isBreakdown__c) {
                    sa.ActualStartTime = System.now();
                }
            }
        }

        if (!appointments.isEmpty()) {
            System.debug('appointments:' + appointments.size());
            FSL_OptimizationHelper.EarlyOrLateArrival(appointments, serviceAppointmenttoDelta);
        }
    }

    
    //   ***   Service Tech Team: Method logic is moved to afterUpdate() method   ***
    
    // public static void syncUpdateClearFlag(Map<Id, ServiceAppointment> syncClearMap, Boolean updateflag) {
    //     List<ServiceAppointment> relatedSAList = [SELECT Id, Is_cleared__c FROM ServiceAppointment WHERE FSL__Related_Service__c IN :syncClearMap.keySet()];
    //     List<ServiceAppointment> updateRelatedApts = New List<ServiceAppointment>();
    //     for (ServiceAppointment sa : relatedSAList) {
    //         sa.Is_cleared__c = updateflag;
    //         updateRelatedApts.add(sa);
    //     }
    //     update UpdateRelatedapts;
    // }


    /**********
     * @Method Name:updateActualEnd 
     * @Parameters: List<ServiceAppointment> saList - appointments that just went in tow or cleared
     * @Description: Sets actual end for appointments
       @Requirement: Update the actual end when the call transitions through statuses
       @Author: Ryan Johnson
     * **********/
    public static void updateActualEnd(List<ServiceAppointment> saList) {
        //   ***   Service Tech Team: Add an empty list check here to reduce complexity in beforeUpdate()    ***
        if (saList.isEmpty()) {
            return;
        }

        //   ***   Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field   ***
        // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();

        DateTime nowTime = System.now();
        DateTime currentTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
        // DateTime currentTime = DateTime.newInstanceGMT(nowTime.yearGMT(), nowTime.monthGMT(), nowTime.dayGMT(), nowTime.hourGMT(), nowTime.minuteGMT(), 0);
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        Map<id, Integer> serviceAppointmenttoDelta = new Map<id, Integer>();

        for (ServiceAppointment sa : saList) {
            //   ***   Service Tech Team: Moved this check to beforeUpdate() main loop    ***
            // if (sa.ActualEndTime == null) {

            // if the appointment is a breakdown and the call doesn't already have an actual start time
            if (!sa.FSL_IsLight_Service__c) {
                if ('In Tow'.equals(sa.Status) || 'Tow Loaded'.equals(sa.Status)) {
                    //   ***   Service Tech Team: Replaced Record Type Id check on "isBreakdown__c" formula field   ***
                    // if (sa.RecordTypeId == breakDownRecordTypeId) {
                    if (sa.isBreakdown__c) {
                        sa.ActualEndTime = currentTime;//system.now(); 
                        System.debug('ActualEndTime:'+sa.ActualEndTime+' SchedEndTime:'+sa.SchedEndTime);                         
                        //Technician goes In Tow Early or late
                        if(sa.SchedEndTime != null && sa.ActualEndTime != sa.SchedEndTime) {
                            appointments.add(sa);
                            serviceAppointmenttoDelta.put(sa.Id, Integer.valueOf(sa.ActualEndTime.gettime()-sa.SchedEndTime.getTime())/60000 );
                        }                              
                    } else if (sa.FSL_In_Tow_Timestamp__c == null) {
                        sa.FSL_In_Tow_Timestamp__c = System.now();
                    }
                }

                //   ***   Service Tech Team: Merged two "if"-s in one and replaced Record Type Id check on " ! isBreakdown__c" formula field   ***
                // if ('Cleared'.equals(sa.Status)) {
                //     if (sa.RecordTypeId != breakDownRecordTypeId) {
                //         sa.ActualEndTime = currentTime;//system.now();
                //     }
                // }

                if (sa.Status.equals('Cleared') && !sa.isBreakdown__c) {
                    sa.ActualEndTime = currentTime;//system.now();
                }
            //   ***   Service Tech Team: Merged two "if"-s in one and replaced Record Type Id check on "isBreakdown__c" formula field   ***
            } else if (sa.Status.equals('Cleared') && sa.isBreakdown__c) {
                // if ('Cleared'.equals(sa.Status)) {
                //     if (sa.RecordTypeId == breakDownRecordTypeId) {
                //         sa.ActualEndTime = currentTime;//system.now();
                //     }
                // }

                sa.ActualEndTime = currentTime;//system.now();
            }

            // }
        }

        if (!appointments.isEmpty()) {
            System.debug('appointments:'+appointments.size());
            FSL_OptimizationHelper.EarlyOrLateArrival(appointments, serviceAppointmenttoDelta);
        }
    }

    
    //   ***   Service Tech Team: Method logic is moved to the beforeUpdate() main loop, so the method is commented out    ***

    /**********
    * @Method Name:updateOriginalScheduledStart
    * @Parameters: List<ServiceAppointment> saList - appointments that were scheduled for the first time
    * @Description: Sets original scheduled start time of the appointment
      @Requirement: Track the original scheduled start time for reporting
      @Author: Ryan Johnson
    * **********/
    // public static void updateOriginalScheduledStart(List<ServiceAppointment> saList) {
    //     for (ServiceAppointment sa : saList) {
    //         sa.Original_Scheduled_Start__c = sa.SchedStartTime;
    //     }
    // }



    /**********
     * @Method updateGanttColoursOnSA
     * @Parameters: List<ServiceAppointment> saList - all appointments
     * @Description: Changes the Appointment colour based on status of SA.
       @Requirement:
       @Author: Balaram naidu.
     * **********/
    public static void updateGanttColoursOnSA(List<ServiceAppointment> saList, Map<Id, ServiceAppointment> saOldMap) {
        List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
        for (ServiceAppointment sa : saList) {
            Boolean criticalPriority = sa.Work_Order_Priority__c == 'Critical';

            //   ***   Service Tech Team: The check " saOldMap != null " won't let set the Gantt color when inserting SAs because oldMap will always be null on insert  ?????    ***
            
            //   ***   Service Tech Team: So "if"-statement is refactored    ***
            // if (saOldMap != null && (sa.status != saOldMap.get(sa.Id).status || sa.FSL__InJeopardy__c != saOldMap.get(sa.Id).FSL__InJeopardy__c)) {

            if (saOldMap == null || (sa.Status != saOldMap.get(sa.Id).Status || sa.FSL__InJeopardy__c != saOldMap.get(sa.Id).FSL__InJeopardy__c)) {
                if (!criticalPriority && !sa.FSL__InJeopardy__c && sa.Status != 'Cleared' && sa.FSL__GanttColor__c != '#228B22') {
                    sa.FSL__GanttColor__c = '#228B22';
                } else if (!criticalPriority && sa.FSL__InJeopardy__c && sa.Status != 'Cleared' && sa.FSL__GanttColor__c != '#ffa500') {
                    sa.FSL__GanttColor__c = '#ffa500';
                } else if (criticalPriority && sa.Status != 'Cleared' && sa.FSL__GanttColor__c != '#FF0000') {
                    sa.FSL__GanttColor__c = '#FF0000';
                } else if (sa.Status == 'Cleared' && sa.FSL__GanttColor__c != '#A9A9A9') {
                    sa.FSL__GanttColor__c = '#A9A9A9';
                }
            }
        }
    }

    /**********
     * @Method updateGanttIconsOnSA
     * @Parameters: List<ServiceAppointment> saList - all appointments
     * @Description: Changes the Appointment icon for COD based on WO Payment Flag
     * @Requirement: //ERS-218373:  Set the Gantt Icon for COD if it is a COD call   
     * @Author: Clement Shiu
     * **********/      
    public static void updateGanttIconsOnSA(List<ServiceAppointment> saList) {  
        FSL_ServiceAppointment.IServiceAppointmentService serviceAppt = (new FSL_ServiceAppointment.Factory()).createService();
        // try {            
            List<Id> woIds = new List<Id>();

            for (ServiceAppointment sa : saList) {
                woIds.add(sa.ParentRecordId);
            }
            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
                SELECT Id, Status, Call_Type__c, Non_Emergency_Appointment_Time__c,
                       (SELECT Payment_Required__c
                        FROM ServiceAppointments
                        WHERE IsBreakdown__c = true)
                FROM WorkOrder
                WHERE Id IN :woIds
            ]);
            serviceAppt.setGanttIconUrlByType(saList, woMap);
        // }catch (Exception e) {
        //     System.debug('updateGanttIconsOnSA Error ::' + e.getMessage());
        // }                        
    }


    /**********
     * @Method isAddressChanged
     * @Parameters: ServiceAppointment oldSA, ServiceAppointment newSA
     * @Description: checks and returns boolean flag if the address is changed on the old and the new SAs.
       @Requirement:
       @Author: Balaram Naidu
     * **********/
    public static Boolean isAddressChanged(ServiceAppointment oldSA, ServiceAppointment newSA) {
        Boolean addressFlag = false;

        // try {
            addressFlag = oldSA.Street != newSA.Street || oldSA.City != newSA.City || oldSA.State != newSA.State || oldSA.PostalCode != newSA.PostalCode;
            //oldSA.Latitude != newSA.Latitude || oldSA.Longitude != newSA.Longitude
        // } catch (Exception e) {
        //     System.debug('AddressChangeException::' + e.getMessage());
        // }
        return addressFlag;
    }


    //   ***   Service Tech Team: Method logic is moved to the beforeUpdate() main loop, so the method is commented out    ***

    /**
     *      Resets the Acknowledge flag for all of the appointments 
     *      that just encountered another violation
     */
    // public static void resetAcknowledgeFlag(List<ServiceAppointment> saList) {
    //     for (ServiceAppointment sa : saList) {
    //         sa.Acknowledge__c = false;
    //     }
    // }


    //   ***   Service Tech Team: Method is commented out because its only usage is commented out    ***

    /**********
     * @Method clearEmergencyFlagOnResource
     * @Parameters: List<ServiceAppointment> saList
     * @Description: Set Emergency flat to False once Emergency clall is being cleared.
       @Requirement:
       @Author: Balaram Naidu
     * **********/
    // public static void clearEmergencyFlagOnResource(List<ServiceAppointment> saList, Map<Id, ServiceAppointment> odlMap) {
    //     Set<Id> criticalClearedCalSet = new Set<Id>();

    //     //   *** Service Tech Team: it's better to get Record Type Ids by its DeveloperNames because they're less likely to change  ***
        
    //     // Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
    //     Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();

    //     for (ServiceAppointment sa : saList) {
    //         if (sa.Work_Order_Priority__c == 'Critical' && (sa.status == 'Cleared' || sa.status == 'Canceled') && sa.status != odlMap.get(sa.Id).status
    //                 && sa.recordTypeId == breakDownRecordTypeId) {
    //             criticalClearedCalSet.add(sa.Id);
    //         }
    //     }
    //     if (!criticalClearedCalSet.isEmpty()) {
    //         List<ServiceResource> resourcesToUpdate = new List<ServiceResource>();
    //         for (AssignedResource ar : [SELECT Id,ServiceResourceId,ServiceResource.Eligible_For_Emergencey_Call__c from AssignedResource where ServiceAppointmentId IN :criticalClearedCalSet AND ServiceResource.Eligible_For_Emergencey_Call__c = true]) {
    //             resourcesToUpdate.add(new ServiceResource(Id = ar.ServiceResourceId, Eligible_For_Emergencey_Call__c = false));
    //         }
    //         if (!resourcesToUpdate.isEmpty()) {
    //             update resourcesToUpdate;
    //         }
    //     }
    // }
    
    /**********
     * @Method handleTerritoryUpdate
     * @Parameters: Map<Id, ServiceAppointment> oldMap, List<ServiceAppointment> saList - values from SA Trigger
     * @Description: Checks if SA Territory has been updated, and will only accept the new value if the Status is not pinned
       @Requirement: UF-1020
       @Author: Ryan Johnson
     * **********/ 
     
     /*   
    public static void handleTerritoryUpdate(Map<Id, ServiceAppointment> oldMap, List<ServiceAppointment> saList){
        List<ServiceAppointment> appointmentsWithNewTerritoryList = FSL_ServiceAppointmentEvaluator.appointmentsWithNewTerritory(oldMap, saList);
        system.debug('appointments with new territory: ' + appointmentsWithNewTerritoryList);
        List<String> pinnedTerritoryStatuses = new List<String>();
        if(!appointmentsWithNewTerritoryList.isEmpty()){
            FSL_Pinned_Statuses__c statusFlags = FSL_Pinned_Statuses__c.getOrgDefaults();
            if(statusFlags != null && String.isNotBlank(statusFlags.Territory_Locked_Status__c)){
                pinnedTerritoryStatuses = statusFlags.Territory_Locked_Status__c.split(',');
            }
        }
        
        for(ServiceAppointment sa : appointmentsWithNewTerritoryList){
            system.debug('*+*+ comparing ' + sa.Status + ' with the pinned statuses: ' + pinnedTerritoryStatuses);
            if(pinnedTerritoryStatuses.contains(sa.Status)){
                sa.ServiceTerritoryID = oldMap.get(sa.id).ServiceTerritoryID;
            }
        }
    }
    */

    /**********
     * @Method reEvaluateServiceTerritoryByPolygons
     * @Parameters: Map<Id, ServiceAppointment> newMap (values from SA Trigger)
     * @Description: Takes a list of Service Appointments that have address changes and re-runs polygon logic if the Status = Spotted
       @Requirement: UF-1020
       @Author: Matthew Pantell
     * **********/  

    /* public static void reEvaluateServiceTerritoryByPolygons(List<ServiceAppointment> newLatLongSAList) {
         System.debug('Entering reEvaluate Service Territory by Polygons');
         List<sObject> relatedRecordUpdates = new List<sObject>();
        //  Map<Id, ServiceTerritory> stMap = new Map<Id, ServiceTerritory>([SELECT Id, Name FROM ServiceTerritory]);   //  ***  Service Tech Team: SOQL is needed only for the debug  ***
         for (ServiceAppointment sa : newLatLongSAList) {
            //  if ('Spotted'.equals(sa.Status) && 'Breakdown Appointment'.equals(sa.Subject)) {   //  ***  Service Tech Team: Moved these checks to beforeUpdate() main loop  ***
            Id territoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(Double.valueOf(sa.Longitude), Double.valueOf(sa.Latitude));
            if (territoryId != null) {
                system.debug('territoryId : '+territoryId);
                sa.ServiceTerritoryId = territoryId;

                //  ***  Service Tech Team: Moved the update of related records to afterUpdate() scope    ***

                // WorkOrder wo = new WorkOrder();
                // wo.id = sa.Work_Order__c;
                // wo.ServiceTerritoryId = territoryId;
                // relatedRecordUpdates.add(wo);
                // System.debug('Updating Service Territory based on Polygon to ' + sa.ServiceTerritoryId); // stMap.get(sa.ServiceTerritoryId).Name);   //  ***  Service Tech Team: replaced Service Territory Name on ST Id  ***
                // if (sa.FSL__Related_Service__c != null) {
                //     ServiceAppointment rsa = new ServiceAppointment();
                //     rsa.Id = sa.FSL__Related_Service__c;
                //     rsa.ServiceTerritoryId = territoryId;
                //     relatedRecordUpdates.add(rsa);
                //     System.debug('Updating related appointment territory');
                // }
            }
            //  }
         }
         
        //  ***  Service Tech Team: Moved the update of related records to afterUpdate() scope    ***
        // if (!relatedRecordUpdates.isEmpty()) {
        //     update relatedRecordUpdates;
        // }
     }*/
        

    /**********
     * @Method evaluateForRSO
     * @Parameters: Map<Id, ServiceAppointmentment>, Map<Id, ServiceAppointment>
     * @Description: Evaluate whether to run RSO based on Service Appointment updates
       @Requirement: UF-538
       @Author: Matthew Pantell
     * **********/
    /*
    public static void evaluateForRSO(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {
        Integer threshold = 5;
        Id policyId = [SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name like '%Blended%'].id;
        for (ServiceAppointment sa : newMap.values()) {
            try {
                if ((oldMap.get(sa.Id).SchedStartTime.getTime() - newMap.get(sa.Id).SchedStartTime.getTime()) / 60000 > threshold || (oldMap.get(sa.Id).SchedEndTime.getTime() - newMap.get(sa.Id).SchedEndTIme.getTime()) / 60000 > threshold || newMap.get(sa.Id).Status.equals('Canceled')) {
                    FSL_ResourceOptimizationUtility optimization = new FSL_ResourceOptimizationUtility();
                    optimization.optimizeScheduleGaps(newMap.get(sa.Id).Service_Resource__c, policyId);
                    // runs RSO if: scheduled start reduced by 5+ min || scheduled end is reduced by 5+ || call is canceled (canceled status)
                }
                if ((newMap.get(sa.Id).SchedStartTime.getTime() - oldMap.get(sa.Id).SchedStartTime.getTime()) / 60000 > threshold || (newMap.get(sa.Id).SchedEndTime.getTime() - oldMap.get(sa.Id).SchedEndTime.getTime()) / 60000 > threshold) {
                    FSL_ResourceOptimizationUtility optimization = new FSL_ResourceOptimizationUtility();
                    optimization.optimizeScheduleOverlaps(newMap.get(sa.Id).Service_Resource__c, policyId);
                    // runs RSO if: scheduled start increased by 5+ min || scheduled end is increased by 5+ min
                }
            } catch (Exception e) {
                System.debug('Failed to optimize run RSO');
                System.debug('Resource ID: ' + newMap.get(sa.Id).Service_Resource__c);
                System.debug('Scheduling Policy:' + policyId);
            }
        }
    }
    */


    //  ***  Service Tech Team: Commented out this method as it's used only in commented out code  ***
    
    /**********
     * @Method dispatcherSubscriptionEvaluator
     * @Parameters: Map<Id, ServiceAppointment>, Map<Id, ServiceAppointment>
     * @Description: This method accepts the maps of old and new ServiceAppointments where territory has been changed (or a newly inserted ServiceAppointment with ServiceTerritory) and evaluates the users for whom subscriptions are needed.
       @Requirement: UF-119
       @Author: Divyendra Naidu
    ***********/

    // public static void dispatcherSubscription(Map<Id, ServiceAppointment> oldSAMap, Map<Id, ServiceAppointment> newSAMap) {
    //     List<EntitySubscription> esListToInsert = new List<EntitySubscription>();
    //     List<EntitySubscription> esListToDelete = new List<EntitySubscription>();
    //     List<EntitySubscription> idealESList = new List<EntitySubscription>();
    //     List<EntitySubscription> currentSADispatcherESList = new List<EntitySubscription>();
    //     List<EntitySubscription> existingSAESList = new List<EntitySubscription>();
    //     Map<Id, Id> oldSASTIdMap = new Map<Id, Id>();
    //     Map<Id, Id> newSASTIdMap = new Map<Id, Id>();
    //     Map<Id, Id> oldUTUIdMap = new Map<Id, Id>();
    //     Map<Id, Id> oldUTSTIdMap = new Map<Id, Id>();
    //     Map<Id, Id> newUTUIdMap = new Map<Id, Id>();
    //     Map<Id, Id> newUTSTIdMap = new Map<Id, Id>();

    //     for (Id saId : newSAMap.keySet()) {
    //         oldSASTIdMap.put(saId, oldSAMap.get(saId).ServiceTerritoryId);
    //         newSASTIdMap.put(saId, newSAMap.get(saId).ServiceTerritoryId);
    //     }//Created map of saId and STId


    //     List<FSL__User_Territory__c> oldUserTerritoryList = new List<FSL__User_Territory__c>([
    //             SELECT Id, FSL__User__c, FSL__ServiceTerritory__c
    //             FROM FSL__User_Territory__c
    //             WHERE FSL__ServiceTerritory__c IN :oldSASTIdMap.values()
    //     ]);

    //     List<FSL__User_Territory__c> newUserTerritoryList = new List<FSL__User_Territory__c>([
    //             SELECT Id, FSL__User__c, FSL__ServiceTerritory__c
    //             FROM FSL__User_Territory__c
    //             WHERE FSL__ServiceTerritory__c IN :newSASTIdMap.values()
    //     ]);

    //     for (FSL__User_Territory__c ut : oldUserTerritoryList) {
    //         oldUTUIdMap.put(ut.Id, ut.FSL__User__c);
    //         oldUTSTIdMap.put(ut.Id, ut.FSL__ServiceTerritory__c);
    //     }//Created maps of old utId to Uid and old utId to STId

    //     for (FSL__User_Territory__c ut : newUserTerritoryList) {
    //         newUTUIdMap.put(ut.Id, ut.FSL__User__c);
    //         newUTSTIdMap.put(ut.Id, ut.FSL__ServiceTerritory__c);
    //     }//Created maps of new utId to Uid and old utId to STId

    //     for (Id utId : oldUTSTIdMap.keySet()) {
    //         for (Id saId : oldSASTIdMap.keySet()) {
    //             if (oldUTSTIdMap.get(utId) == oldSASTIdMap.get(saId)) {
    //                 EntitySubscription es = new EntitySubscription(ParentId = saId, SubscriberId = oldUTUIdMap.get(utId));
    //                 existingSAESList.add(es);
    //             }
    //         }
    //     }

    //     for (Id utId : newUTSTIdMap.keySet()) {
    //         for (Id saId : newSASTIdMap.keySet()) {
    //             if (newUTSTIdMap.get(utId) == newSASTIdMap.get(saId)) {
    //                 EntitySubscription es = new EntitySubscription(ParentId = saId, SubscriberId = newUTUIdMap.get(utId), networkId = Network.getNetworkId());
    //                 esListToInsert.add(es);
    //             }
    //         }
    //     }

    //     currentSADispatcherESList = new List<EntitySubscription>([SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN:(oldSASTIdMap.keySet())]);
    //     System.debug('$%$%$%$% currentSADispatcherESList = ' + currentSADispatcherESList);

    //     for (EntitySubscription esExisting : existingSAESList) {
    //         for (EntitySubscription esCurrent : currentSADispatcherESList) {

    //             if ((esExisting.ParentId == esCurrent.ParentId) && (esExisting.SubscriberId == esCurrent.SubscriberId)) {
    //                 esListToDelete.add(esCurrent);
    //             }
    //         }
    //     }

    //     System.debug('$%$%$%$% esListToDelete = ' + esListToDelete);
    //     System.debug('$%$%$%$% esListToInsert = ' + esListToInsert);

    //     if (!esListToDelete.isEmpty()) {
    //         try {
    //             delete esListToDelete;
    //         } catch (Exception ex) {
    //             System.debug('Could not delete ES List :' + ex.getMessage());
    //         }
    //     }

    //     if (!esListToInsert.isEmpty()) {
    //         try {
    //             insert esListToInsert;
    //         } catch (Exception ex) {
    //             System.debug('Could not insert ES List :' + ex.getMessage());
    //         }
    //     }
    // }


    //   ***   Service Tech Team: Should we replace this method on class static flag variable  ???????    ***

    public static Boolean isPolicyArrivalEndWindowUpdate(List<ServiceAppointment> oldsaList, List<ServiceAppointment> sanewList)
    {
        if (sanewList.size() == 1)
        {
            //condition user for 3rd scheduling policy to update the ArrivalWindowEndTime with PTA.
            
            if (sanewList[0].Arrival_Window_End_Time_Update_Timestamp__c <> oldsaList[0].Arrival_Window_End_Time_Update_Timestamp__c)
            {
                System.debug('Update arrival Window End Time : ' + sanewList.size());
                return true;
                
            }
           
        }
        return false;
    }

    
    /*public static ETA_Notification__e createTravelDelayPE(ServiceAppointment sa, Integer delta){
        ETA_Notification__e manualETAOverride = new ETA_Notification__e();
        manualETAOverride.Appointment_Number__c = sa.AppointmentNumber;
        manualETAOverride.Time_Delta__c = delta;
        manualETAOverride.Original_Scheduled_Start__c = sa.SchedStartTime;
        manualETAOverride.Type__c = 'Travel Delays';

        // only all appointments should be moved out based on the previous appointment running behind
        manualETAOverride.Update_Related_Appointments__c = true;
        manualETAOverride.Update_Current_Appointment__c = true;     
        
        return manualETAOverride;
        
    }*/   
    /**
     *      @purpose    -   Identify the related Tow SA of a Breakdown SA. Replaces usage of SA.FSL__Related_Service__c
     *      breakdownID:    Breakdown Service Appointment ID
     */
    public static ID returnTowServiceAppointmentID(ID breakdownID){
        ID towID = null;
        
        List<FSL__Time_Dependency__c> appointmentDependency = [
            SELECT id, FSL__Service_Appointment_1__c, FSL__Service_Appointment_2__c
            FROM FSL__Time_Dependency__c
            WHERE FSL__Service_Appointment_1__c = :breakdownID
        ];

        if (!appointmentDependency.isEmpty()) {
            towID = appointmentDependency.get(0).FSL__Service_Appointment_2__c;
        }

        return towID;
    }

     /**
     *      @purpose        -   Identify the related Tow SA of a Breakdown SA. Replaces usage of SA.FSL__Related_Service__c
     *      Set<ID> saIDs   -   Bulkified to accept a set of Appointments and return a map of the SA and the related SA ID.
     */    
    public static Map<ID, ID> returnServiceAppointmentMap(Set<ID> saIDs){
        Map<ID, ID> saToRelatedSAMap = new Map<ID, ID>();
        
        List<FSL__Time_Dependency__c> appointmentDependencyList = [
            SELECT id, FSL__Service_Appointment_1__c, FSL__Service_Appointment_2__c
            FROM FSL__Time_Dependency__c
            WHERE FSL__Service_Appointment_1__c IN :saIDs OR FSL__Service_Appointment_2__c IN :saIDs
        ];

        for (ID sID : saIDs) {
            for (FSL__Time_Dependency__c dependency : appointmentDependencyList){
                if (dependency.FSL__Service_Appointment_1__c == sID) {
                    saToRelatedSAMap.put(sID, dependency.FSL__Service_Appointment_2__c);
                }
                if (dependency.FSL__Service_Appointment_2__c == sID) {
                    saToRelatedSAMap.put(sID, dependency.FSL__Service_Appointment_1__c);
                }
            }
        }

        return saToRelatedSAMap;
    }
    

    //   ***   Service Tech Team: Method is not used anywhere    ***

     /**
     *      @purpose        -   Identify the related Tow SA of a Breakdown SA. Replaces usage of SA.FSL__Related_Service__c
     *      Set<ID> saIDs   -   Bulkified to accept a set of Appointments and return a map of the SA to its Time Dependency.
     */      
    // public static Map<Id, FSL__Time_Dependency__c> returnRelatedAppointmentDetailMap(Set<ID> saIDs){
    //     Map<ID, FSL__Time_Dependency__c> saToRelatedSAMap = new Map<ID, FSL__Time_Dependency__c>();

    //     // find dependencies with appointments from input param
    //     List<FSL__Time_Dependency__c> appointmentDependencyList = [SELECT id, FSL__Service_Appointment_1__c, FSL__Service_Appointment_2__c,
    //     FSL__Service_Appointment_1__r.SchedStartTime, FSL__Service_Appointment_1__r.ArrivalWindowEndTime, FSL__Service_Appointment_2__r.ArrivalWindowEndTime, FSL__Service_Appointment_1__r.PTA__c, FSL__Service_Appointment_2__r.SchedStartTime, FSL__Service_Appointment_2__r.PTA__c
    //     FROM FSL__Time_Dependency__c 
    //     WHERE FSL__Service_Appointment_1__c IN :saIDs OR FSL__Service_Appointment_2__c IN :saIDs];
        
    //     for(ID inputID : saIDs){
    //         for(FSL__Time_Dependency__c dependency : appointmentDependencyList){
    //             if(inputID == dependency.FSL__Service_Appointment_1__c || inputID == dependency.FSL__Service_Appointment_2__c ){
    //                 saToRelatedSAMap.put(inputID, dependency);
    //             }
    //         }

    //     }

    //     return saToRelatedSAMap;

    // }

/**
     *  @purpose    -   Populates a custom field on the Service Appointment based on a 
     *                  mapping of the call's sponsor, program, and code. The Glympse Managed Package
     *                  is configured to read from this custom field (RAP_Brand__c) and generate a different UI/UX based on this value
     */

    public static void setGlympseBrand(List<ServiceAppointment> saList){
        // List<ServiceAppointment> saListtoUpdate = new List<ServiceAppointment>();    //   ***   Service Tech Team: The only usage of this list is commented out   ***
        Set<Id> conIdset = new Set<Id>();
        for (ServiceAppointment sa : saList) {
        // add contact ID to set , end loop
            conIdset.add(sa.ContactId);
        }
       
        //   ***   Service Tech Team: Replaced the list on a map of Contacts  ***
        // search for contacts in contact ID set to retrieve the Member Sponsor and Program
        // List<Contact> memberContacts = [SELECT id,name,Membership_OrgCode__c,Membership_Sponsor__c,Membership_Program__c from Contact WHERE id in :conIdset];
        Map<Id, Contact> memberContactsMap = new Map<Id, Contact>([
            SELECT Id, Name, Membership_OrgCode__c, Membership_Sponsor__c, Membership_Program__c
            FROM Contact
            WHERE Id IN :conIdset
        ]);
    
        //   ***   Service Tech Team: Having an SObject as a key in a map is not reliable, primitive types should be used as a key instead   ***
        // create map of Service Appointment (key) to Contact (value)
        // Map<ServiceAppointment, Contact> satoContactMap = new Map<ServiceAppointment, Contact>();         

        //   ***   Service Tech Team: This map is not needed   ***
        // Map<Id, Contact> saIdToContactMap = new Map<Id, Contact>();         
        // for (ServiceAppointment sa : saList){
        //     for(Contact con : memberContacts){
        //         if(con.id == sa.ContactId){
        //             satoContactMap.put(sa, con);
        //         }
        //     }
        // }
        
        // get all of the Glympse Branding information
        Map<String, FSL_Glympse_Brand_Mapping__c> BrandMap = FSL_Glympse_Brand_Mapping__c.getAll(); 
        for (ServiceAppointment sa : saList) {
            //   ***   Service Tech Team: Refactored loop body   ***
            
            // for (String str : BrandMap.keySet()) {
                // FSL_Glympse_Brand_Mapping__c brMap = BrandMap.get(str);
                // System.debug('custom settings'+brMap);
                // //check if contact on Service Appointment matches Sponsor and Program on Contact
                // Boolean contactMapped = satoContactMap.get(sa) != null;
                // Boolean matchesSponsor = contactMapped && brMap.FSL_Membership_Sponsor__c == satoContactMap.get(sa).Membership_Sponsor__c;
                // Boolean matchesProgram = contactMapped && brMap.FSL_Membership_Program__c == satoContactMap.get(sa).Membership_Program__c;
                // Boolean matchesCode = contactMapped && brMap.Brand_Code__c == satoContactMap.get(sa).Membership_OrgCode__c;

                // // if match is found, update RAP Brand
                // if (matchesSponsor && matchesProgram && matchesCode) {
                //     sa.RAP_Brand__c = brMap.Brand_Name__c;
                //     //saListtoUpdate .add(sa);
                // }                
            // }

            Contact memberContact = memberContactsMap.get(sa.ContactId);
            if (memberContact == null) {
                continue;
            }

            for (FSL_Glympse_Brand_Mapping__c brSetting : BrandMap.values()) {
                // System.debug('custom settings - ' + brSetting);
                //check if contact on Service Appointment matches Sponsor and Program on Contact
                Boolean matchesSponsor = brSetting.FSL_Membership_Sponsor__c == memberContact.Membership_Sponsor__c;
                Boolean matchesProgram = brSetting.FSL_Membership_Program__c == memberContact.Membership_Program__c;
                Boolean matchesCode = brSetting.Brand_Code__c == memberContact.Membership_OrgCode__c;

                // if match is found, update RAP Brand
                if (matchesSponsor && matchesProgram && matchesCode) {
                    sa.RAP_Brand__c = brSetting.Brand_Name__c;
                }
            }
        }        
    }

    //ERS-230874 Glympse Removal - Part I
    /*---------------------------------------------------------------------------------------------------------------------
    public static Boolean glympseInviteURL(ServiceAppointment oldSA, ServiceAppointment newSA) {
        Boolean urlAdded = false;
        Boolean newInvite = false;
    
        newInvite = String.isBlank(oldSA.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c); 
        urlAdded = (oldSA.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c != newSA.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c) ;
        
        return newInvite && urlAdded;
    }
    public static void callGlympseViolation(Set<Id> enrouteSAIdSet) {        
        List<AssignedResource> enrouteAssignResList = new List<AssignedResource>([
            SELECT Id, ServiceResource.Driver_Id__c, ServiceResource.Location.VIN__c, ServiceResource.Vehicle__r.Truck_Id__c,
                    ServiceAppointment.SchedStartTime, ServiceAppointment.Status, ServiceAppointment.FSL__InJeopardy__c, ServiceAppointment.LastModifiedDate,
                    ServiceAppointment.Spotted_Timestamp__c, ServiceAppointment.Scheduled_Timestamp__c, ServiceAppointment.Dispatched_Timestamp__c,
                    ServiceAppointment.ParentRecordId, ServiceAppointment.Work_Order__r.WorkOrderNumber, ServiceAppointment.Work_Order__r.Call_Id__c,
                    ServiceAppointment.Work_Order__r.External_Id__c, ServiceAppointment.Work_Order__r.Call_Date__c,
                    ServiceAppointment.ServiceTerritory.Facility_Number__c
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :enrouteSAIdSet
            AND ServiceAppointment.Work_Order__c != null
        ]);
        
        for (AssignedResource assignRes : enrouteAssignResList) {
            String servicingFacility = assignRes.ServiceAppointment.ServiceTerritory.Facility_Number__c;
            FSL_ToD3Update.CalloutWrapperD3 wrapper = FSL_ToD3Update.wrapperBuilder(assignRes.ServiceAppointment.Work_Order__r, assignRes.ServiceAppointment, assignRes, servicingFacility);
           
            callGetETA(assignRes.ServiceAppointmentId, JSON.serializePretty(wrapper), assignRes.ServiceAppointment.Work_Order__r.Call_Id__c);
        }
    }
      
    @future(callout=true)
    public static void callGetETA(String saId, String wrapperJson, String callId) {
        FSL_ToGlympseCallout.getEta(saId, wrapperJson, callId);
    }
    */

    /*  public List<Technology_Preference__c> fetchTechnologyPreference(string serviceTerritoryId){
        return [select id, Service_Territory__r.Name, Technology_Type__c from Technology_Preference__c where Service_Territory__c=:serviceTerritoryId];
    }*/
    public Map<Id,List<Technology_Preference__c>> fetchTechnologyPreference(Set<Id> serviceTerritoryIdSet){
        Map<Id,List<Technology_Preference__c>> tpMap=new Map<Id,List<Technology_Preference__c>>();
        for(Technology_Preference__c tp:[select id,Service_Territory__c, Service_Territory__r.Name, Technology_Type__c from Technology_Preference__c where Service_Territory__c IN:serviceTerritoryIdSet]){
            if(tpMap.containsKey(tp.Service_Territory__c)){
                tpMap.get(tp.Service_Territory__c).add(tp);
            }else{
                tpMap.put(tp.Service_Territory__c,new List<Technology_Preference__c>{tp});
            }
        }
       return tpMap;
    }
    
    // ASI-691 Changes- Don't DELETE checkManualSchedule Method AGB added for SSFI-560 11/19/24
    
    public static void checkManualSchedule(List<ServiceAppointment> saList, map<Id,ServiceAppointment> oldSAMap){
        User automationUser = [SELECT Id FROM User WHERE Name = 'Automation User' LIMIT 1];
        List<ServiceAppointmentHistory> histories = [SELECT Field, CreatedById, NewValue, OldValue, CreatedDate,ServiceAppointmentId 
                                                     FROM ServiceAppointmentHistory 
                                                     WHERE Field = 'Service_Resource__c' 
                                                     AND ServiceAppointmentId IN :saList 
                                                     ORDER BY CreatedDate DESC];
        Map<Id, Id> lastUpdatedByAutomationUser = new Map<Id, Id>();
        // For each history record, check if the last change was made by the automation user
        for (ServiceAppointmentHistory history : histories) {
            if (!lastUpdatedByAutomationUser.containsKey(history.ServiceAppointmentId)) {
                lastUpdatedByAutomationUser.put(history.ServiceAppointmentId, history.CreatedById);
            }
        }
        
        
        for (ServiceAppointment sa : saList) {
            ServiceAppointment oldSa = oldSAMap.get(sa.Id);
            if(sa.createdDate.addMinutes(2) > System.now()){
                if ((String.isBlank(oldSa.Service_Resource__c) && String.isNotBlank(sa.Service_Resource__c))) {
                    sa.Manual_Schedule__c = false;
                }
            }
            else {
                if(
                    (
                        ( String.isBlank(oldSa.Service_Resource__c) && String.isNotBlank(sa.Service_Resource__c) ) || 
                        (sa.Service_Resource__c != oldSa.Service_Resource__c)
                    ) && 
                    lastUpdatedByAutomationUser.get(sa.Id) != automationUser.Id
                ){
                    sa.Manual_Schedule__c = true;
                    sa.FSL__Schedule_Mode__c = 'Manual';
                }
                
                if((sa.Service_Resource__c != oldSa.Service_Resource__c) && lastUpdatedByAutomationUser.get(sa.Id) == automationUser.Id){
                    sa.Manual_Schedule__c = false;
                }
            }
        }
    }  
}