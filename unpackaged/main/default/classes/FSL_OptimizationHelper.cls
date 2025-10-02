/**
 * @File Name          : FSL_OptimizationHelper.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06-17-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    1/13/2020   Rajesh Kemisetti     Initial Version
 *        10/10/2020  Clement Shiu  Limit the Select Return on table FSL__Territory_Optimization_Request__c to last two days
 *        12/02/2020  Clement Shiu  ERS-220415 - Optimization helper refractoring
 *        06/16/2021  Clenent Shiu  ERS-223871 - In Day Optimization is not firing off platform events
**/
public with sharing class FSL_OptimizationHelper {

    /**
    * @description 
    * @author Rajesh Kemisetti | 1/13/2020 
    * @param workOrdIdSAMap 
    * @param appointmentToTimeDelta 
    * @param resourceIdTimeDeltaMap 
    * @param appointmentToResource 
    * @return void 
    **/
   
    public static void shiftAppointment(Map<Id,ServiceAppointment> workOrdIdSAMap, Map<ServiceAppointment, Integer> appointmentToTimeDelta, Map<Id,ServiceAppointment> resourceIdTimeDeltaMap, Map<ServiceAppointment, ID> appointmentToResource){
        DateTime currentTime = System.now();
        
        Map<ServiceAppointment,Integer> shiftAppointmentToResourceMap = new Map<ServiceAppointment,Integer>();
        Set<Id> currentWoIdSet = new Set<Id>();
        Set<Id> serviceResourceIdSet = new Set<Id>();
        Map<ServiceAppointment,Id> throsholdCheckSARsMap = new Map<ServiceAppointment,Id>();
        Set<Id> queUedOptimisingTerrIdSet = new Set<Id>();
        Map<ID, Boolean> appointmentToRunRSO = new Map<ID, Boolean>(); 
        Map<ID, Boolean> appointmentToRunInDay = new Map<ID, Boolean>();

        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();

        //Retrieve pending inday optimization request    
        List<FSL__Territory_Optimization_Request__c> territoryOptReqList = getPendingTerritoryOptReqList();

        for(FSL__Territory_Optimization_Request__c optTerrReq : territoryOptReqList) {
            queUedOptimisingTerrIdSet.add(optTerrReq.FSL__ServiceTerritory__c);
        }

        // Bypass In-Day or Platform Event Logic if Pending Optimization in Matching territory found
        for(WorkOrder wo : [Select Id,Resolution_Code__c from WorkOrder where Id In : workOrdIdSAMap.keySet()]) {
            if(!queUedOptimisingTerrIdSet.contains(workOrdIdSAMap.get(wo.Id).serviceTerritoryId)) {
                //if(wo.Resolution_Code__c == 'X001' || wo.Resolution_Code__c == 'X002') {
                    currentWoIdSet.add(wo.Id);
                    throsholdCheckSARsMap.put(workOrdIdSAMap.get(wo.Id),workOrdIdSAMap.get(wo.Id).Service_Resource__c);
                //}else {                        
                //    shiftAppointmentToResourceMap.put(workOrdIdSAMap.get(wo.Id),appointmentToTimeDelta.get(workOrdIdSAMap.get(wo.Id)));
                //}               
            }
        }
        
        // Determine if In-Day should run or if the appointment should be handled by Platform Event shift logic 
        if(!currentWoIdSet.isEmpty()) { 
        Set<Id> resourceIdSet = new Set<Id>();
        resourceIdSet.addAll(throsholdCheckSARsMap.values());
        //Map<id,Boolean> isRsHavingStkCallsMap= checkStackedCallsForTheResource(resourceIdSet);
        //checkStackedCallsForTheResource(resourceIdSet )
            for(ServiceAppointment sap : appointmentToTimeDelta.keySet()){//[Select Id,status,SchedStartTime,SchedEndTime,Service_Resource__c from ServiceAppointment where Service_Resource__c IN : throsholdCheckSARsMap.values() AND SchedStartTime >:currentTime AND (NOT parentRecordId IN : currentWoIdSet) AND (NOT Status IN ('Canceled','Cleared')) order by SchedStartTime asc ]) {
                if(!queUedOptimisingTerrIdSet.contains(resourceIdTimeDeltaMap.get(sap.Service_Resource__c).serviceTerritoryId)) {
                    
                    // If the call is cleared (late or early) in a time that exceeds the In Day threshold
                    //if(oSettings.In_Day_Gap_Threshold__c != null && (Math.abs(Integer.valueOf((sap.SchedStartTime.getTime()) - currentTime.getTime()))/60000) >= Integer.valueOf(oSettings.In_Day_Gap_Threshold__c)) {
                    if(oSettings.In_Day_Gap_Threshold__c != null && (Math.abs(appointmentToTimeDelta.get(sap))) >= Integer.valueOf(oSettings.In_Day_Gap_Threshold__c)) {
                        // run In-Day on resource's primary / seconday territories
                        serviceResourceIdSet.add(sap.Service_Resource__c);
                        //run In day
                        appointmentToRunInDay.put(sap.Service_Resource__c, true);
                    //else If the call is cleared in a time that exceeds the RSO threshold
                    //}else if(oSettings.RSO_Threshold__c != null && (Math.abs(Integer.valueOf((sap.SchedStartTime.getTime()) - currentTime.getTime()))/60000) >= Integer.valueOf(oSettings.RSO_Threshold__c)) {
                    }else if(oSettings.RSO_Threshold__c != null && (Math.abs(appointmentToTimeDelta.get(sap))) >= Integer.valueOf(oSettings.RSO_Threshold__c)) {
                        //run RSO
                        //if(isRsHavingStkCallsMap.get(sap.Service_Resource__c)!= null && isRsHavingStkCallsMap.get(sap.Service_Resource__c)){
                            appointmentToRunRSO.put(sap.Service_Resource__c, true);
                        //}
                        
                    }
                    //Run In day for Canceled calls
                    if(sap.status=='Canceled' && oSettings.Run_InDay_on_Cancellation__c){ 
                        // run In-Day on resource's primary / seconday territories
                        serviceResourceIdSet.add(sap.Service_Resource__c);
                        //run In day
                        appointmentToRunInDay.put(sap.Service_Resource__c, true);                          
                    }                    
                    shiftAppointmentToResourceMap.put(resourceIdTimeDeltaMap.get(sap.Service_Resource__c),appointmentToTimeDelta.get(resourceIdTimeDeltaMap.get(sap.Service_Resource__c)));
                }
            }
        }
        
        if(!serviceResourceIdSet.isEmpty()) {
            //Creating resource absence for LKL
            FSL_LastKnownLocationUtility.createAbsences(serviceResourceIdSet,System.now());
            //Calling inday After creating resource absence for LKL
            //runInDayAfterClearing(serviceResourceIdSet);                
        }       
        
        if(!shiftAppointmentToResourceMap.isEmpty()) {            
            shiftAppointments(shiftAppointmentToResourceMap, appointmentToRunRSO, appointmentToRunInDay); 
        }            
    }    

    public static List<FSL__Territory_Optimization_Request__c> getPendingTerritoryOptReqList(){

        // ERS-223871 - In Day Optimization is not firing off platform events    
        Set<String> completeStatuses = new Set<String>{'Aborted','Failed','Completed','Completed First Optimization Day'};

        Integer pendingIDOFilter = getPendingIDOFilter('Pending_IDO_Filter');
        List<FSL__Territory_Optimization_Request__c> territoryOptReqList = [SELECT Id,FSL__ServiceTerritory__c,FSL__Optimization_Request__c 
                                                                            FROM   FSL__Territory_Optimization_Request__c 
                                                                            WHERE  FSL__Optimization_Request__r.FSL__Status__c NOT IN :completeStatuses 
                                                                            AND    FSL__Optimization_Request__r.FSL__Type__c = 'In Day Optimization' 
                                                                            AND    createddate > :DateTime.now().addMinutes(-pendingIDOFilter)];
                                                 
        return territoryOptReqList;

    }
    
    public static Integer getPendingIDOFilter(String configName) {

        List<FSL_Optimization_Filter__mdt> pendingIDOFilter = [SELECT Filter_In_Minute__c
                                                                FROM  FSL_Optimization_Filter__mdt
                                                                WHERE DeveloperName = :configName  
                                                                LIMIT 1];

        Integer pendingFilter = 15; // Default value

        if(!pendingIDOFilter.isEmpty()) {
            Integer pendingFilterFromConfig = pendingIDOFilter[0].Filter_In_Minute__c.intValue();
            if(pendingFilterFromConfig > 0) pendingFilter = pendingFilterFromConfig;
        } 

        return pendingFilter;        
    }

    /**
    * @description 
    * @author Rajesh Kemisetti | 1/14/2020 
    * @param resourceIDs 
    * @param resourceToLogId 
    * @return void 
    **/
    public static void optimizeScheduleOverlapsbulk( Set<ID> resourceIDs, map<id, id> resourceToLogId){         
        for(ID resourceID : resourceIDs){
            FSL_ResourceOptimizationUtility optimization = new FSL_ResourceOptimizationUtility();
            optimization.optimizeScheduleOverlaps(resourceID, resourceToLogId.get(resourceID));
        }
    }    
    /**
    * @description 
    * @author Rajesh Kemisetti | 1/14/2020 
    * @param sa 
    * @param delta (in min)
    * @param type 
    * @param updateRelatedAppt 
    * @param updateCurrentAppt 
    * @param runRSO 
    * @param runInDay 
    * @return ETA_Notification__e 
    **/
    public static ETA_Notification__e createETAPlatformEvent(ServiceAppointment sa, Integer delta, String type, string ServiceResourceId, Boolean updateRelatedAppt, Boolean updateCurrentAppt, Boolean runRSO, boolean runInDay){
        ETA_Notification__e ETA = new ETA_Notification__e();
        if(sa!=null){
            ETA.Appointment_Number__c = sa.AppointmentNumber;
            ETA.Original_Scheduled_Start__c = sa.SchedStartTime;
            ETA.ETA__c = sa.ETA__C;
        }   
        ETA.Time_Delta__c = delta;                
        ETA.Type__c = type;        
        ETA.Update_Related_Appointments__c = updateRelatedAppt;
        ETA.Update_Current_Appointment__c = updateCurrentAppt;  
        ETA.Run_RSO__c   = runRSO;
        ETA.Run_InDay__c = runInDay;
        ETA.Service_Resource_Id__c = ServiceResourceId;
        ETA.Trigger_time__c = System.now();
        return ETA;
    }

    /**
    * @description 
    * @author Rajesh Kemisetti | 1/14/2020 
    * @param sa 
    * @param delta (in min)
    * @param type 
    * @param updateRelatedAppt 
    * @param updateCurrentAppt 
    * @param runRSO 
    * @param runInDay 
    * @return ETA_Notification__e 
    **/
    public static ETA_Notification__e createETAPlatformEvent(ServiceAppointment sa, Integer delta, String type, string ServiceResourceId, Boolean updateRelatedAppt, Boolean updateCurrentAppt, Boolean runRSO, boolean runInDay, ResourceAbsence ra){
        ETA_Notification__e ETA = new ETA_Notification__e();
        if(sa!=null){
            ETA.Appointment_Number__c = sa.AppointmentNumber;
            ETA.Original_Scheduled_Start__c = sa.SchedStartTime;
        } 
        if(ra!=null){
            ETA.Resource_Absence_Id__c = ra.Id;
            //ETA.Original_Scheduled_Start__c = ra.End;
        }   
        ETA.Time_Delta__c = delta;                
        ETA.Type__c = type;        
        ETA.Update_Related_Appointments__c = updateRelatedAppt;
        ETA.Update_Current_Appointment__c = updateCurrentAppt;  
        ETA.Run_RSO__c   = runRSO;
        ETA.Run_InDay__c = runInDay;
        ETA.Service_Resource_Id__c = ServiceResourceId;
        ETA.Trigger_time__c = System.now();
        return ETA;
    }  

    /**
    * @description 
    * @author Rajesh Kemisetti | 4/7/2020 
    * @param type 
    * @param terrIds 
    * @return ETA_Notification__e 
    **/
    public static ETA_Notification__e createETAPlatformEvent(String type, list<ID> terrIds){
        ETA_Notification__e ETA = new ETA_Notification__e();
        ETA.Time_Delta__c = 0;                
        ETA.Type__c = type;        
        ETA.Update_Related_Appointments__c = false;
        ETA.Update_Current_Appointment__c = false;  
        ETA.Run_RSO__c   = false;
        ETA.Run_InDay__c = true;
        for(Id terrId : terrIds){
            ETA.Territory_Ids__c = !string.isEmpty(ETA.Territory_Ids__c) ? ETA.Territory_Ids__c+','+terrId : terrId;
        }
        ETA.Trigger_time__c = System.now();
        return ETA;
    }  

    /**
    * @description Technician Operating Hours are reduced, added or removed
    * @author Rajesh Kemisetti | 1/15/2020 
    * @param oldMap 
    * @param Slots 
    * @param operation 
    * @return void 
    **/
    public static void changedOperatingHours(Map<Id, TimeSlot> oldMap, List<TimeSlot> Slots, string operation){
        boolean InDayRan = false;
        set<ID> allOperIds = new set<ID>();
        //get all the operating hour ids
        for(TimeSlot  Slot : Slots){ 
            allOperIds.add(Slot.operatinghoursId);
        }        
        SYSTEM.DEBUG('allOperIds:'+allOperIds);
        //get timezone for operating hour
        map<ID, OperatingHours> mapOperatingHours = new map<ID, OperatingHours>([select timezone from OperatingHours where ID in :allOperIds]);
        
        map<Id, TimeSlot> mapEligibleOpHour = new map<Id, TimeSlot>();        
        
        for(TimeSlot  Slot : Slots){
            string timezone = mapOperatingHours.get(Slot.operatinghoursId).timezone;
            DateTime currentDateTime = System.now();
            Time currentTime = Time.newInstance(Integer.valueof(currentDateTime.format('HH',timezone)), Integer.valueof(currentDateTime.format('mm',timezone)), 0, 0);
            String currentDay = currentDateTime.format('EEEE', timezone);

            system.debug(currentTime);
            system.debug(currentDay); 
            system.debug('timezone: '+timezone);       
            
            //If timeslots were updated/reduced (operation=Update)
            //-capture the changed time slot records where either start or end time has changed
            //-the change has to be for the current day, 
            //-also check the timezone on operating hour - convert all times to GMT and compare
            //for each timeslot capture the eligibile operating hour in a list or set
            //else If timeslots were removed (operation=Delete)
            //-the removal has to be for the current day             
            if( (
                    (operation == 'Update' && (oldMap.get(Slot.id).starttime < Slot.starttime || oldMap.get(Slot.id).endtime > Slot.endtime)) ||  //Reduction
                    (operation == 'Delete') || //Deletion
                    (operation == 'Insert') ||   //Addition
                    (operation == 'Update' && (oldMap.get(Slot.id).starttime > Slot.starttime || oldMap.get(Slot.id).endtime < Slot.endtime))  //Addition
                ) &&
               currentDay == Slot.dayofweek 
              )
            {
                //map the operating hour and the current day timeslot thats updated
                mapEligibleOpHour.put(Slot.OperatingHoursId, Slot);             
            }
        } 
        //run below logic only if there are any eligible timeslots operating hours
        if(!mapEligibleOpHour.isEmpty()){
            map<string, string> territoryIds = new map<string, string>();
            map<string, string> mapResourceTerrId= new map<string, string>();
            list<string> resourceIds = new list<string>();
            //for each active STM related to the operatinghour, pull the resource and the terr ids 
            list<ServiceTerritoryMember> stms = [SELECT Id, ServiceTerritoryId, ServiceResourceId, OperatingHoursId, ServiceResource.Vehicle__c
                                                FROM ServiceTerritoryMember 
                                            WHERE OperatingHoursId IN :mapEligibleOpHour.keySet() AND 
                                                    //TerritoryType='P' AND
                                                    FSL_Expired_Resource_Territory__c = false ];
            for(ServiceTerritoryMember stm : stms )
            {
                mapResourceTerrId.put(stm.ServiceResourceId, stm.OperatingHoursId);
                territoryIds.put(stm.ServiceTerritoryId, stm.ServiceTerritoryId);
            }
            system.debug('mapResourceTerrId:'+mapResourceTerrId);
            list<ServiceAppointment> servAppts = new list<ServiceAppointment>();
            //pull the appointments related to the resource that are scheduled outside of the new timeslot
            //-if the scheduledstarttime is not between the new timeslot for the current day and 
            //-the status is not in scheduled or dispatched so it can be unscheduled (status=Spotted)
            if(!mapResourceTerrId.isEmpty()){
                for(ServiceAppointment sa : [SELECT id, ServiceTerritoryid, Service_Resource__c, Service_Resource__r.Vehicle__c, schedendtime, schedstarttime 
                                               FROM ServiceAppointment
                                              WHERE Service_Resource__c IN :mapResourceTerrId.keySet() AND 
                                                    ServiceTerritoryid IN :territoryIds.keySet() AND
                                                    status IN ('Scheduled','Dispatched') AND
                                                    Work_Order__r.Appointment_Flag__c = false
                                            ])
                {    
                    string operatinghoursId = mapResourceTerrId.get(sa.Service_Resource__c);
                    DateTime currentDateTime = system.now(); 
                    DateTime opHoursStarttime = getOpeHrsDateTime(currentDateTime, Timezone.getTimeZone(mapOperatingHours.get(operatinghoursId).timezone), mapEligibleOpHour.get(operatinghoursId).starttime);
                    DateTime opHoursEndtime = getOpeHrsDateTime(currentDateTime, Timezone.getTimeZone(mapOperatingHours.get(operatinghoursId).timezone), mapEligibleOpHour.get(operatinghoursId).endtime);
                      
                    system.debug('sameday??'+sa.schedstarttime.isSameDay(system.now()));
                    system.debug('Comparision:'+sa.schedstarttime+' < '+opHoursStarttime);
                    system.debug('Comparision:'+sa.schedendtime+' > '+opHoursEndtime);

                    //If timeslots were updated (operation=Update)
                    //-appt start time is less than operating hour start OR end time is greater than operating hour end
                    //else If timeslots were deleted (operation=Delete)
                    //-appt start time is greater or equal to operating hour start and  start time is less than operating hour end
                    if( (
                            (operation=='Update' &&                        
                                (sa.schedendtime > opHoursEndtime || 
                                sa.schedstarttime < opHoursStarttime
                                )
                            ) || 
                            (operation=='Delete' &&
                                (sa.schedstarttime >= opHoursStarttime &&  
                                 sa.schedstarttime < opHoursEndtime 
                                )                             
                            )
                        ) &&
                         sa.schedstarttime.isSameDay(system.now())
                      )
                    {
                        system.debug('Appoitment Id:'+sa.id);
                        sa.status = 'Spotted';
                        servAppts.add(sa);
                    }
                }
                //for reduction and deletion, InDay will be run only if there is one appointment to unschedule
                if(!servAppts.isEmpty()){
                    system.debug('APPOINTMENTS UNSCHEDULED:'+servAppts.size()+' values:'+servAppts);
                    update servAppts;
                    //query the appointments and get the latest territory of the appointments after unscheduled 
                    for(ServiceAppointment sa : [select serviceterritoryid from ServiceAppointment where id in :servAppts]){
                        territoryIds.put(sa.serviceterritoryid, sa.serviceterritoryid);
                    }
                    system.debug('territoryIds size:'+territoryIds);
                    for(ServiceTerritoryMember stm : [SELECT Id, ServiceTerritoryId, ServiceResourceId, OperatingHoursId 
                                                        FROM ServiceTerritoryMember 
                                                       WHERE ServiceResourceId IN :mapResourceTerrId.keySet() AND
                                                             FSL_Expired_Resource_Territory__c = false ])
                    {
                        territoryIds.put(stm.serviceterritoryid, stm.serviceterritoryid);
                    }               
                    system.debug('territoryIds:'+territoryIds.size()+' '+territoryIds.values());     
                    //call inday                     
                    List<ETA_Notification__e> etaNotifications = new List<ETA_Notification__e>();
                    //call inday 
                    ETA_Notification__e etaNotification = createETAPlatformEvent('Reduced Working Hours', territoryIds.values());
                    etaNotifications.add(etaNotification);
                    if(!etaNotifications.isEmpty()){
                        List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
                    }
                    
                    //set falg to true
                    InDayRan = true;
                }
            }
            //This will be used when the operating hours are increased or Inserted
            if(!InDayRan && !mapResourceTerrId.isEmpty()){
                for(ServiceTerritoryMember stm : stms )
                {
                    DateTime currentDateTime = system.now(); 
                    string operatinghoursId = mapResourceTerrId.get(stm.ServiceResourceId);
                    DateTime opHoursStarttime = getOpeHrsDateTime(currentDateTime, Timezone.getTimeZone(mapOperatingHours.get(operatinghoursId).timezone), mapEligibleOpHour.get(operatinghoursId).starttime);
                    DateTime opHoursEndtime = getOpeHrsDateTime(currentDateTime, Timezone.getTimeZone(mapOperatingHours.get(operatinghoursId).timezone), mapEligibleOpHour.get(operatinghoursId).endtime);                    
                    if(   (
                                (operation=='Update' &&                        
                                    (currentDateTime < opHoursEndtime || 
                                    currentDateTime > opHoursStarttime
                                    )
                                ) || 
                                (operation=='Insert')
                            ) &&
                            currentDateTime.isSameDay(system.now())
                            )
                    {        
                        //select the resources who have the vehicle selected so In Day can be optimized only for those resource territories
                        if(stm.ServiceResource.Vehicle__c!=null){
                            resourceIds.add(stm.ServiceResourceId);
                        }
                    }
                }
                if(!resourceIds.isEmpty()){
                //for addition or increased timeslot, only InDay will be run
                    map<string, string> terrIds = new map<string, string>();
                    for(ServiceTerritoryMember stm : [SELECT Id, ServiceTerritoryId, ServiceResourceId, OperatingHoursId 
                                                        FROM ServiceTerritoryMember 
                                                       WHERE ServiceResourceId IN :resourceIds AND
                                                             FSL_Expired_Resource_Territory__c = false ])
                    {
                        terrIds.put(stm.ServiceTerritoryId, stm.ServiceTerritoryId);
                    }
                    //call inday 
                    if(!terrIds.isEmpty()){                        
                        List<ETA_Notification__e> etaNotifications = new List<ETA_Notification__e>();
                        //call inday 
                        ETA_Notification__e etaNotification = createETAPlatformEvent('Extended Working Hours', territoryIds.values());
                        etaNotifications.add(etaNotification);
                        if(!etaNotifications.isEmpty()){
                            List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
                        }                                                
                    }
                }
            }
        }
    }
    
    /**
    * @description 
    * @author Rajesh Kemisetti | 1/23/2020 
    * @param timezone 
    * @param optime 
    * @return DateTime 
    **/
    public static DateTime getOpeHrsDateTime(DateTime currentDateTime, TimeZone timezone, Time optime)
    {
        system.debug('APPT/SLOT TIMEZONE:'+ timezone);
        //DateTime currentDateTime = system.now(); 
        
        //Building the datetime for timeslot start and endtime in local timezone 
        DateTime opHourstime = DateTime.newInstance(currentDateTime.date(), optime);

        //difference of operating hours timezone and user time zone    
        Integer offsetHrs = Integer.valueof(timezone.getDisplayName().substring(6,7)) -
                            Integer.valueof(UserInfo.getTimeZone().getdisplayname().substring(6,7)) ;

        //adding the offset hours to the generated datetime so that the operating hours timezone is considered                      
        return opHourstime.addHours(offsetHrs);
    }

    /**
    * @description Technician Arrive on Location Early, Technician goes In Tow Early
    * @author Rajesh Kemisetti | 1/20/2020 
    * @param appointments 
    * @param serviceAppointmenttoDelta 
    * @return void 
    **/
    public static void EarlyOrLateArrival(list<ServiceAppointment> appointments, map<Id, Integer> serviceAppointmenttoDelta){
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        list<ETA_Notification__e> etaNotifications = new list<ETA_Notification__e>();
        Set<Id> resourceIdSet = new Set<Id>();
        for(ServiceAppointment sa : appointments){
             resourceIdSet.add(sa.Service_Resource__c);
        }
        //Map<id,Boolean> isRsHavingStkCallsMap= checkStackedCallsForTheResource(resourceIdSet);
        for(ServiceAppointment sa : appointments){            
            boolean runRSO = false;
            boolean runInDay = false;
            if(math.abs(serviceAppointmenttoDelta.get(sa.id)) >= oSettings.In_Day_Gap_Threshold__c
                /*&& (isRsHavingStkCallsMap.get(sa.Service_Resource__c) == null || (isRsHavingStkCallsMap.get(sa.Service_Resource__c)))*/){
                runInDay = true;
            }else if(math.abs(serviceAppointmenttoDelta.get(sa.id)) >= oSettings.RSO_Threshold__c 
                /*&& (isRsHavingStkCallsMap.get(sa.Service_Resource__c) == null || (isRsHavingStkCallsMap.get(sa.Service_Resource__c)))*/){
                runRSO = true;
            }
            system.debug('RUNNING RSO?'+runRSO);
            string etaType='Early or Late Arrival';
            if(serviceAppointmenttoDelta.get(sa.id) < 0){
                etaType = 'Early ';
            }else if (serviceAppointmenttoDelta.get(sa.id) >= 0){
                etaType = 'Late ';
            }
            etaType = etaType + sa.status;
            ETA_Notification__e etaNotification = createETAPlatformEvent(sa, serviceAppointmenttoDelta.get(sa.id), etaType, null, true, true, runRSO, runInDay);
            etaNotifications.add(etaNotification);
        }
        if(!etaNotifications.isEmpty()){
          List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
        }        
    }
    
    public static void optimizeResourcesWhoBecameAvailable(map<ID, Integer> resourceSet,Map<Id,ResourceAbsence> rsIdAbsenceMap){
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        // TODO: Add util method that passes set of resource IDs
         //Map<id,Boolean> isRsHavingStkCallsMap= checkStackedCallsForTheResource(resourceSet);
        // and returns a Map of Key resourceID and Value of True / False for whether or not they have stacked appointments in a Scheduled status
        list<ETA_Notification__e> etaNotifications = new list<ETA_Notification__e>();        
        //FSL_ResourceOptimizationUtility util = new FSL_ResourceOptimizationUtility();
        for(ID resourceID : resourceSet.keyset()){
            //if(isRsHavingStkCallsMap.get(resourceID)){
            if( resourceSet.get(resourceID) >= oSettings.In_Day_Gap_Threshold__c)    {
                //Run RSO
                ETA_Notification__e  eta = createETAPlatformEvent(null, resourceSet.get(resourceID), 'Resource Absence Shortened', resourceID, false, false, false, true,rsIdAbsenceMap.get(resourceID));
                etaNotifications.add(eta);                
                //util.optimizeScheduleOverlaps(resourceID);
            } else
            if( resourceSet.get(resourceID) >= oSettings.RSO_Threshold__c)    {
                //Run RSO
                ETA_Notification__e  eta = createETAPlatformEvent(null, resourceSet.get(resourceID), 'Resource Absence Shortened', resourceID, false, false, true, false,rsIdAbsenceMap.get(resourceID));
                etaNotifications.add(eta);                
                //util.optimizeScheduleOverlaps(resourceID);
            }    
            //}            
            // TODO: Only run RSO if map value is true
        }
        if(!etaNotifications.isEmpty()){
            List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
        }         
    }

     /**
     *      @purpose    -   Check if the newly inserted Resource Absence overlaps with any existing
     *                      Service Appointments or Resource Absences. Create a Platform Event to call IDO or RSO
     *                      based on the length of the absence
     */
    public static void optimizeResourceAbsences(List<ResourceAbsence> newAbsences,Map<Id,ResourceAbsence> oldRAMap){
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        Set<ID> inDayServiceResourceIDs = new Set<ID>();
        Set<ID> rsoResourceIDs = new Set<ID>();
        Set<ID> inDayTerritoryIDs = new Set<ID>();
        Map<Id,ResourceAbsence> resourceAndAbsenceMap = new Map<Id,ResourceAbsence>();
        Map<ID, Integer> resouceIdDeltaMap = new Map<ID, Integer>();
        // iterate absences for duration
        for(ResourceAbsence ra : newAbsences){
            Integer breakDuration = 0;
            if(oldRAMap == null) {
                breakDuration = Integer.valueOf(( (ra.End.getTime() - ra.Start.getTime()  )  / 60000));
            }else if(oldRAMap != null && ra.End > oldRAMap.get(ra.Id).End){
                breakDuration = Integer.valueOf(( (ra.End.getTime() - oldRAMap.get(ra.Id).End.getTime()  )  / 60000));
            }             
            if(breakDuration >= oSettings.In_Day_Gap_Threshold__c){
                // add resource to list for In-Day
                indayServiceResourceIDs.add(ra.ResourceID);
                resourceAndAbsenceMap.put(ra.ResourceID,ra);
                resouceIdDeltaMap.put(ra.ResourceID,breakDuration);
            }
            else if(breakDuration >= oSettings.RSO_Threshold__c){
                // add resource to list for RSO
                rsoResourceIDs.add(ra.ResourceID);
                resourceAndAbsenceMap.put(ra.ResourceID,ra);
                resouceIdDeltaMap.put(ra.ResourceID,breakDuration);
            }           
        }
        
        list<ETA_Notification__e> etaNotifications = new list<ETA_Notification__e>();

        // Run RSO for each resource 
        /*if(!rsoResourceIDs.isEmpty()){
            FSL_OptimizationHelper.optimizeScheduleOverlapsbulk(rsoResourceIDs);
        }*/
        // Run RSO for each resource 
        if(!rsoResourceIDs.isEmpty()){
            for(string ServiceResourceID : rsoResourceIDs){
                ETA_Notification__e  eta = createETAPlatformEvent(null, resouceIdDeltaMap.get(ServiceResourceID), 'Resource Absence Extended', ServiceResourceID, false, false, true, false,resourceAndAbsenceMap.get(ServiceResourceID));
                etaNotifications.add(eta);
            }
        }        

        //Run InDay for each resource
        for(string ServiceResourceID : indayServiceResourceIDs){
            ETA_Notification__e  eta = createETAPlatformEvent(null, resouceIdDeltaMap.get(ServiceResourceID), 'Resource Absence Extended', ServiceResourceID, false, false, false, true,resourceAndAbsenceMap.get(ServiceResourceID));
            etaNotifications.add(eta);
        }
        if(!etaNotifications.isEmpty()){
          List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
        }                
        // NOTE: TODO: do not run RSO on a resource if In-Day will be run on that resource's territory (edge case)
    } 
    
    /**********
    * @Method Name:    makeFutureScheduleAdjustment
    * @Parameters:     Set<ID> saAptIDs, Map<AssignedResource, Decimal> newScheduleDelta
    * @Return:         void
    * @Description:    Shifts all appointments to account for an adjusted drive time based on address change
    * @Author:         Ryan Johnson
    * **********/    
    public static void handleAddressChangeTravelTimeUpdates(Set<ID> saAptIDs, Map<AssignedResource, Decimal> newScheduleDelta){        
        system.debug('+-+- in handleAddressChangeTravelTimeUpdates +-+-');
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        Map<ServiceAppointment, Id> appointmentToResourceMap = new Map<ServiceAppointment, Id>();
        List<ServiceAppointment> saList = [SELECT id, Address_Changed__c, SchedStartTime, FSL__Related_Service__c, SchedEndTime, Schedule_Delta__c,ETA__C, 
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
                List<Database.SaveResult> results = publishPlatformEvents(addressChangeNotificationList);
              }            
            }
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
            List<Database.SaveResult> results = publishPlatformEvents(completedApppointmentETAList);
        }     
    }

    /**********
    * @Method Name:    shiftAppointments
    * @Parameters:     List<ResourceAbsence> deltedAbsences
    * @Return:         void
    * @Description:    Shifts all appointments scheduled past the recently deleted absence earlier in the schedule, based on the absence time
    * @Author:         Ryan Johnson
    * **********/      
   public static void shiftAppointments(List<ResourceAbsence> deltedAbsences){
       Map<ResourceAbsence, Integer> resourceToTimeSavedMap = new Map<ResourceAbsence, Integer>();
       Set<ID> saIDs = new Set<ID>();
       Set<ID> srIDSet = new Set<ID>();
       for(ResourceAbsence ra : deltedAbsences){
           DateTime currentTime = System.now();
           // TODO: create platform events
           
           if(ra.Start < currentTime && ra.End > currentTime ){
               // the break was cut short early
               resourceToTimeSavedMap.put(ra, Integer.valueOf((ra.End.getTime() - currentTime.getTime()) / 60000));
           }else if(ra.Start > currentTime){
               // the break never started
               resourceToTimeSavedMap.put(ra, Integer.valueOf((ra.End.getTime() - ra.Start.getTime()) / 60000));
           }
           
       }        
       
       for(ResourceAbsence ra : resourceToTimeSavedMap.keySet()){
           srIDSet.add(ra.ResourceID);
       }   
       
       // get all future appointments for the resource
       List<ServiceAppointment> affectedAppointments = [SELECT id, SchedStartTime, EarliestStartTime, SchedEndTime, Service_Resource__c, Technician_Schedule_Override_Counter__c FROM ServiceAppointment 
           WHERE Service_Resource__c IN :srIDSet AND SchedStartTime > :System.now()];
       
       if(!affectedAppointments.isEmpty()){
           for(ServiceAppointment affectedSA : affectedAppointments){
               for(ResourceAbsence deletedRA : resourceToTimeSavedMap.keySet()){
                   system.debug('-----affectedSA -----'+affectedSA );
                   // if the appointment was scheduled after the absence was supposed to end
                   if( (affectedSA.Service_Resource__c == deletedRA.ResourceID) && affectedSA.SchedStartTime > deletedRA.End){
                       affectedSA.SchedStartTime = affectedSA.SchedStartTime.addMinutes(resourceToTimeSavedMap.get(deletedRA) * -1);
                       affectedSA.SchedEndTime = affectedSA.SchedEndTime.addMinutes(resourceToTimeSavedMap.get(deletedRA) * -1);
                       affectedSA.Technician_Schedule_Override_Counter__c = affectedSA.Technician_Schedule_Override_Counter__c + 1;
                   }
               }
           }
           update affectedAppointments;
       }       
       
   }
   /**
    *   @purpose    -   Checks if the provided Service Appointment or Resource Absence overlaps
    *                   with any other Service Appointments that are currenly scheduled to the same resource.
    *
    *                   This method is used to trigger RSO for Emergency Calls or new Resource Absences that create overlaps
    */
   public static Boolean didCallCreateOverlap(FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper saWrapper, ServiceAppointment sa, ResourceAbsence ra){
        
    DateTime startInterval;
    DateTime endInterval;
    
    Set<String> includedStatuses = new Set<String>();
    includedStatuses.add('Scheduled');
    includedStatuses.add('Dispatched');
    includedStatuses.add('En Route');
    
    // put resource for this SA in a variable
    ID serviceResourceID;
    ID parentWorkOrderId;
    
    if(sa != null){
        serviceResourceID = sa.Service_Resource__c;
        startInterval = sa.SchedStartTime;
        endInterval = sa.SchedEndTime;
    }else if(saWrapper != null){
        startInterval = saWrapper.sa.SchedStartTime.addMinutes(saWrapper.travelTimeTo * -1);
        endInterval = saWrapper.sa.SchedEndTime.addMinutes(saWrapper.travelTimeFrom);
        serviceResourceID = saWrapper.sa.Service_Resource__c;
        parentWorkOrderId = saWrapper.sa.ParentRecordId;
    }
    else{
        serviceResourceID = ra.ResourceID;
        Integer travelToMinutes = ra.FSL__EstTravelTime__c != null ? Integer.valueOf(ra.FSL__EstTravelTime__c) * -1 : 0 ;
        Integer travelFromMinutes = ra.FSL__EstTravelTimeFrom__c != null ? Integer.valueOf(ra.FSL__EstTravelTimeFrom__c) : 0 ;
        
        startInterval = ra.Start.addMinutes(travelToMinutes);
        endInterval = ra.End.addMinutes(travelFromMinutes);
    }
    system.debug('finding appointments assigned to : ' + serviceResourceID);
    
    // Comment out the following to reduce hit on SOQL limit
    // List<ServiceResource> srList = [SELECT id, Vehicle__r.Vehicle_Type__c FROM ServiceResource WHERE id = :serviceResourceID];
    
    // TEMP: only run RSO for resource's in Light Service Vehicles
    //if(!srList.isEmpty() && srList.get(0).Vehicle__r.Vehicle_Type__c == 'Light_Service'){
        
        
        // find all Scheduled service appointments assigned to this resource
        List<ServiceAppointment> relatedSAList = [SELECT SchedStartTime, SchedEndTime, Status, ParentRecordId FROM ServiceAppointment 
            WHERE Service_Resource__c = :serviceResourceID AND Status IN :includedStatuses];
        
        Set<ID> saIDs = new Set<ID>();
        for(ServiceAppointment relatedSA : relatedSAList){
            saIDs.add(relatedSA.id);
        }
        // get all assigned resources related to these appointments
        List<AssignedResource> arList = [SELECT id, EstimatedTravelTime, FSL__EstimatedTravelTimeFrom__c, ServiceAppointmentID FROM AssignedResource WHERE ServiceAppointmentID IN :saIDs];

        List<FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper> wrapperList = new List<FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper>();
        for(ServiceAppointment relatedSA : relatedSAList){
            for(AssignedResource ar : arList){
                if(ar.ServiceAppointmentID == relatedSA.id){
                    Integer travelTimeTo = ar.EstimatedTravelTime != null ? Integer.valueOf(ar.EstimatedTravelTime) : 0;
                    Integer travelTimeFrom = ar.FSL__EstimatedTravelTimeFrom__c != null ? Integer.valueOf(ar.FSL__EstimatedTravelTimeFrom__c) : 0;                        
                    FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper wrapper = new FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper(relatedSA, travelTimeTo, travelTimeFrom);
                    wrapperList.add(wrapper);
                }       
            }
        }

        // iterate over each to see if there is an overlap between the scheduled times 
        for(FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper wrapper : wrapperList){
            ServiceAppointment relatedSA = wrapper.sa;
            DateTime saStartInterval = wrapper.sa.SchedStartTime.addMinutes(wrapper.travelTimeTo * -1);
            DateTime saEndInterval = wrapper.sa.SchedEndTime.addMinutes(wrapper.travelTimeFrom);                
            if(relatedSA.ParentRecordId != parentWorkOrderId){
                // if new record has its scheduled start between the related appointment
                if(startInterval >= saStartInterval  && startInterval < saEndInterval){
                    return true;
                }else if(endInterval <= saEndInterval && endInterval > saStartInterval){
                    // if new record has its scheduled end between the related appointment
                    return true;
                }else if(saStartInterval >= startInterval  && saStartInterval < endInterval){
                    return true;
                }else if(saEndInterval <= endInterval && saEndInterval > startInterval ){
                    return true;
                }
            }
        }
    
    //}
    return false;
}   
    /**
     *  @purpose    -   Creates multiple platform events for calling RSO when
     *                  multiple appointments have been identified as overlaps
     *                  
     */
    public static void bulkFixOverlaps(List<ServiceAppointment> overlappingApppointments){
        try{
            FSL_ResourceOptimizationUtility util = new FSL_ResourceOptimizationUtility();
            list<ETA_Notification__e> etaNotifications = new list<ETA_Notification__e>(); 
            Set<ID> resourceSet = new Set<ID>(); 
            for(ServiceAppointment sa : overlappingApppointments){
                // do not run RSO for the same resource twice
                if(!resourceSet.contains(sa.Service_Resource__c)){
                    resourceSet.add(sa.Service_Resource__c);
                    ETA_Notification__e  eta = FSL_OptimizationHelper.createETAPlatformEvent(sa, 0, 'Emergency Assignment Overlap', sa.Service_Resource__c, false, false, true, false);
                    etaNotifications.add(eta);                                
                }
            }
            if(!etaNotifications.isEmpty()){
                List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
            }            
        }catch(Exception e){
            system.debug('Exception caught: ' + e);
        }
    }        

    // ERS-220415: Centralize publish events to the helper 
    public static List<Database.SaveResult> publishPlatformEvents( List<ETA_Notification__e> etaNotifications){
        for(ETA_Notification__e etaNotice : etaNotifications){
            Blob b = Crypto.GenerateAESKey(128);
            etaNotice.EventKey__c=EncodingUtil.ConvertTohex(b).substring(0,20);
        }
        List<Database.SaveResult> results = EventBus.publish(etaNotifications);
        return results;
    }
    
    public static void bulkFixOverlaps(List<ResourceAbsence> overlappingAbsences){
        try{
            FSL_ResourceOptimizationUtility util = new FSL_ResourceOptimizationUtility();
            list<ETA_Notification__e> etaNotifications = new list<ETA_Notification__e>();  
            for(ResourceAbsence ra : overlappingAbsences){
                ETA_Notification__e  eta = FSL_OptimizationHelper.createETAPlatformEvent(null, 0, 'Resource Absence Overlap', ra.ResourceID, false, false, true, false);
                etaNotifications.add(eta);                 
            }
            if(!etaNotifications.isEmpty()){
                List<Database.SaveResult> results = publishPlatformEvents(etaNotifications);
            }            
        }catch(Exception e){
            system.debug('Exception caught: ' + e);
        }
    }
   
    /**
    * @description:     Wrapper method for the method in the FSL_ResourceOptimizationUtility class
    **/
    public static void callInDayWithPrimarySeconderyTerritories(List<String> primarySecTrIdList, ID appLogId){                
        FSL_ResourceOptimizationUtility.callInDayWithPrimarySeconderyTerritories(primarySecTrIdList, appLogId);        
    }            
}