/**
 * @File Name          : FSL_LastKnownLocationUtility.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 08-30-2022
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    3/3/2020   Rajesh Kemisetti     Initial Version
 *        1/5/2020   Clement Shiu     ERS-220594: Added code to Auto Dispatch Ideling Scheduled Appointment Calls in the next 45 min (Appt Dispatch Window)
 * 
**/
public with sharing class FSL_LastKnownLocationUtility {
    
    public static void lastKnownLocationJob(list<ServiceResource> ServiceResources) {
        Boolean createAbsenceInBatch = false;

        FSL_Instrumentation instrumentation = FSL_Instrumentation.createInstance(FSL_LastKnownLocationUtility.class.getName());
        instrumentation.startInstrumenting();

        if (FSL_Optimization_Settings__c.getOrgDefaults().Create_ResourceAbsence_In_Trigger__c) {
            doLastKnownLocationJob(ServiceResources);
        } else {
            // We are creating ResourceAbsence in Flow, so we have to just Update OnSchedule Flags here for Regular Operation Hr Resources
            updateSROnScheduleFlag(ServiceResources);                
        }       
        
        // Perform Auto Dispatch Appointment Calls here
        //   ***   Service Tech Team: Commented out autodispatch function as autodispatching Appt calls is implemented by a Scheduled flow   ***
        // autoDispatchAppointments();

        instrumentation.stopInstrumenting();
        instrumentation.logResult();
    }    

    private static boolean isShiftEnabled() {
        // if (FSL_Optimization_Settings__c.getOrgDefaults().Run_Shifts__c) {
        //     return true;
        // } else {
        //     return false;
        // }

        return FSL_Optimization_Settings__c.getOrgDefaults().Run_Shifts__c;
    }
    
    // private static void autoDispatchAppointments() {
    //     // Move the Auto Dispatch Service Appointment Appointment Calls to: FSL_ServiceAppointmentQueueable            
    //     FSL_ServiceAppointmentQueueable.DispatchAppointmentCalls apptCallsQueueble = new FSL_ServiceAppointmentQueueable.DispatchAppointmentCalls();
    //     System.enqueueJob(apptCallsQueueble);
    // }

    private static void doLastKnownLocationJob(list<ServiceResource> ServiceResources) {
        try {
            Map<Id, ServiceResource> srToUpdateMap = new Map<Id, ServiceResource>();

            DateTime currentDateTime = System.now();
            String currentDay = currentDateTime.format('EEEE');
            Time currentTime = Time.newInstance(currentDateTime.hourGmt(), currentDateTime.minuteGmt(), currentDateTime.secondGmt(), currentDateTime.millisecondGmt());
            // ShiftLKL srShift = new ShiftLKL();           
            
            // Get shifts and operating hours for the timezones         
            Set<Id> activeOperatingHoursSet = new Set<Id>();
            Set<Id> inactiveOperatingHoursSet = new Set<Id>();

            for (FSL_LKL_Timezone__mdt lklTZ : [SELECT timezone_DL__c, timezone__c from FSL_LKL_Timezone__mdt]) {
                DateTime DateTime_tz = DateTime.valueOf(currentDateTime.format('yyyy-MM-dd HH:mm:ss', lklTZ.timezone_DL__c));       
                String Day_tz = DateTime_tz.format('EEEE');
                Time Time_tz = Time.newInstance(DateTime_tz.hour(), DateTime_tz.minute(), DateTime_tz.second(), DateTime_tz.millisecond());                
                
                // // Add all the active shifts                
                // srShift.addAllActiveShifts(System.now());

                Map<String, List<OperatingHours>> OperatingHoursMap = FSL_LastKnownLocationUtility.getActiveOperatingHours(Time_tz, Day_tz, lklTZ.timezone__c);                
                
                for(string active_or_inactive : OperatingHoursMap.keySet()){
                    for(OperatingHours OperatingHours : OperatingHoursMap.get(active_or_inactive)){
                        if(active_or_inactive.equalsIgnoreCase('Active')){
                            activeOperatingHoursSet.add(OperatingHours.id);
                        }else if (active_or_inactive.equalsIgnoreCase('Inactive')){
                            inactiveOperatingHoursSet.add(OperatingHours.id);
                        }
                    }    
                }
            }

            Set<Id> resourcesWithActiveAbsenceIdSet = getResourcesWithActiveAbsenceIdSet(ServiceResources);

            ShiftLKL srShift = new ShiftLKL(ServiceResources, resourcesWithActiveAbsenceIdSet);
            if (isShiftEnabled()) {
                // Add all the active shifts                
                srShift.addAllActiveShifts();
            }

            // get service resources that have those operating hours
            Set<Id> scheduledResources = FSL_LastKnownLocationUtility.getScheduledResources(activeOperatingHoursSet, inactiveOperatingHoursSet, resourcesWithActiveAbsenceIdSet, ServiceResources, srToUpdateMap);
                                    
            // get active appointments 
            List<ServiceAppointment> activeAppointments = FSL_LastKnownLocationUtility.getActiveAppointments(currentDateTime, ServiceResources);
            
            // get active absences
            // List<ResourceAbsence> activeAbsences = FSL_LastKnownLocationUtility.getActiveAbsences(currentDateTime, ServiceResources);
            
            // add resources from active appointments and absences to get active resources
            Set<Id> activeResources = FSL_LastKnownLocationUtility.getActiveResources(activeAppointments/*, activeAbsences*/);
            activeResources.addAll(resourcesWithActiveAbsenceIdSet);

            // Step 3) Determine which resources are idle            
            List<ServiceResource> idleFulltimeResources = FSL_LastKnownLocationUtility.getIdleResources(scheduledResources, activeResources);            
            
            // Add the regular fulltime Idle Resource list to the combined idle list
            List<ServiceResource> idleResources = new  List<ServiceResource>();
            idleResources.addAll(idleFulltimeResources);

            // Process Shifts
            doShifts(srShift,currentDateTime, idleResources, srToUpdateMap);

            if (!srToUpdateMap.isEmpty()) {
                update srToUpdateMap.values();
            }

            // Step 4) Create Absences for Idle Resources
            if (!idleResources.isEmpty()) {
                FSL_LastKnownLocationUtility.createAbsences(idleResources, currentDateTime);
            }

            FSL_Application_Log__c lklLog = new FSL_Application_Log__c();
            lklLog.Operation__c = 'LKL';
            lklLog.Request_Body__c = ('Active Appointments: \n' + activeAppointments + '\n\n Active Resources: \n' + activeResources + '\n\n Idle Resources: \n ' + idleResources);
            insert lklLog;
        }
        catch(exception e) {
            System.debug('------------------e' + e);
            System.debug('-------------' + e.getStackTraceString());
        }
    }

    private static void doShifts(ShiftLKL srShift, DateTime currentDateTime, List<ServiceResource> idleResources, Map<Id, ServiceResource> srToUpdateMap) {
        if (isShiftEnabled()) {
            //Shift : Get the list of Shifts with idle resources
            List<ServiceResource> idleShiftResources = srShift.getIdleShiftResources(currentDateTime, srToUpdateMap);

            //Shift : Add shift Idle Resource list to the combined Idle List
            idleResources.addAll(idleShiftResources);       
        }               
    }

    public static void updateSROnScheduleFlag(list<ServiceResource> ServiceResources) {
        try {
            Map<Id, ServiceResource> srToUpdateMap = new Map<Id, ServiceResource>();

            DateTime currentDateTime = System.now();
            String currentDay = currentDateTime.format('EEEE');
            Time currentTime = Time.newInstance(currentDateTime.hourGmt(), currentDateTime.minuteGmt(), currentDateTime.secondGmt(), currentDateTime.millisecondGmt());
            // ShiftLKL srShift = new ShiftLKL();           
            
            // Get shifts and operating hours for the timezones         
            Set<Id> activeOperatingHoursSet = new Set<Id>();
            Set<Id> inactiveOperatingHoursSet = new Set<Id>();

            for (FSL_LKL_Timezone__mdt lklTZ : [SELECT timezone_DL__c, timezone__c FROM FSL_LKL_Timezone__mdt]) {
                DateTime DateTime_tz = DateTime.valueOf(currentDateTime.format('yyyy-MM-dd HH:mm:ss', lklTZ.timezone_DL__c));       
                String Day_tz = DateTime_tz.format('EEEE');
                Time Time_tz = Time.newInstance(DateTime_tz.hour(), DateTime_tz.minute(), DateTime_tz.second(), DateTime_tz.millisecond());                
                
                // // Add all the active shifts into a Set => activeShiftsSet  
                // if (isShiftEnabled()) {          
                //     srShift.addAllActiveShifts(System.now());
                // }

                Map<String, List<OperatingHours>> OperatingHoursMap = FSL_LastKnownLocationUtility.getActiveOperatingHours(Time_tz, Day_tz, lklTZ.timezone__c);                
                
                for (string active_or_inactive : OperatingHoursMap.keySet()) {
                    for (OperatingHours OperatingHours : OperatingHoursMap.get(active_or_inactive)) {
                        if (active_or_inactive.equalsIgnoreCase('Active')) {
                            activeOperatingHoursSet.add(OperatingHours.id);
                        } else if (active_or_inactive.equalsIgnoreCase('Inactive')) {
                            inactiveOperatingHoursSet.add(OperatingHours.id);
                        }
                    }    
                }
            }

            Set<Id> resourcesWithActiveAbsenceIdSet = getResourcesWithActiveAbsenceIdSet(ServiceResources);
                
            ShiftLKL srShift = new ShiftLKL(ServiceResources, resourcesWithActiveAbsenceIdSet);
            // Add all the active shifts into a Set => activeShiftsSet  
            if (isShiftEnabled()) {          
                srShift.addAllActiveShifts();
            }

            
            //Update the On Schedule Flag for the Regular Oper Service Resources
            // updateSROnScheduleFlag(activeOperatingHoursSet, inactiveOperatingHoursSet, ServiceResources);

            //      Replaced updateSROnScheduleFlag() on getScheduledResources() as they're the same
            getScheduledResources(activeOperatingHoursSet, inactiveOperatingHoursSet, resourcesWithActiveAbsenceIdSet, ServiceResources, srToUpdateMap);

            //Shift : update Currently_Scheduled__c flag
            if (isShiftEnabled()) {
                List<ServiceResource> srToUpdateList = srShift.updateShiftResourceOnScheduleFlag();
                srToUpdateMap.putAll(srToUpdateList);
            }
                        
            if (!srToUpdateMap.isEmpty()) {
                //update srToUpdateMap.values();
                startServiceResourceUpdateBatch(srToUpdateMap.values());                
            }
        }
        catch(exception e) {
            System.debug('------------------e' + e);
            System.debug('-------------' + e.getStackTraceString());
        }
    }

    public static void createAbsences(Set<Id> idleResources, DateTime now) {
        // Do the ResourceAbsense filter here, filter out those AR that has Stale SR Lat/Long                
        // Get the ServiceResource 
        
        // Get the comparison min in metadata
        Integer staleMin = getLKLStaleIdleTime();
        List<ServiceResource> srList = [SELECT Id, LastKnownLatitude, LastKnownLongitude FROM ServiceResource WHERE Id IN :idleResources AND LastKnownLocationDate > :DateTime.now().addMinutes(-staleMin)];
                
        createAbsences(srList, System.now());
    }
    
    public static void createAbsences(List<ServiceResource> idleResources, DateTime now) {
        List<ResourceAbsence> raList = new List<ResourceAbsence>();
        Set<ResourceAbsence> raSet = new Set<ResourceAbsence>();

        for (ServiceResource sr : idleResources) {   
            ResourceAbsence ra = new ResourceAbsence();              
            ra.ResourceID = sr.Id;
            ra.FSL_Resource_ID__c = sr.Id;
            ra.FSL__Approved__c = true;
            ra.Latitude = sr.LastKnownLatitude;
            ra.Longitude = sr.LastKnownLongitude;
            ra.Start = now;
            ra.End = now.addMinutes(1);
            ra.Type = 'Idle';
            ra.recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get('Non Availability').getRecordTypeId();                
            ra.FSL__GanttLabel__c = 'LKL';
            raSet.add(ra);        
        }
        
        // Convert set back to List
        raList = new List<ResourceAbsence>(raSet);

        System.debug('absences inserted = ' +  raList);
        if (!raList.isEmpty()) {
            List<FSL_BatchSize__mdt> batchSizeConfig = [SELECT Batch_Size__c FROM FSL_BatchSize__mdt WHERE DeveloperName = 'LKL_Resource_Absence_Upsert'];
            Integer batchSize = 25; // Default value
            if (!batchSizeConfig.isEmpty()) {
                batchSize = batchSizeConfig[0].Batch_Size__c.intValue();
            }             
            FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( raList );
            Database.executeBatch( batch, batchSize );
            // upsert raList FSL_Resource_ID__c;
        }
    }
   
    private static Set<Id> getResourcesWithActiveAbsenceIdSet(List<ServiceResource> serviceResourceList) {
        Set<Id> resourceWithActiveAbsenceIdSet = new Set<Id>();
        for (ResourceAbsence absence : [SELECT ResourceId
                                        FROM ResourceAbsence
                                        WHERE ResourceId IN :serviceResourceList
                                        AND FSL__Approved__c = true
                                        AND Start <= :System.now()
                                        AND End > :System.now()
                                        AND FSL__GanttLabel__c != 'LKL']) {
            resourceWithActiveAbsenceIdSet.add(absence.ResourceId);
        }
        return resourceWithActiveAbsenceIdSet;
    }
    
    /**
     *  @purpose    - Retrieve all operating hours for the current time zone 
     *  @params     - currentTime: for evaluating if the current time is within the time slot
     *              - tZone: the time zone for the operating hours
     *  @return     - Map<String, List<OperatingHours>> a list of two operating hours, active and inactive  
     *
     */
    public static Map<String, List<OperatingHours>> getActiveOperatingHours(Time currentTime, String strDay, String tZone) {
        Map<String, List<OperatingHours>> operatingHourMap = new Map<String, List<OperatingHours>>();
        
       // Updat 11/19: Removing DayOfWeek from TimeSlot query to pull all inactive hours - WHERE DayOfWeek = :strDay
       List<OperatingHours> operatingHourList = [
            SELECT Id, Name, TimeZone, 
                   (SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId
                    FROM TimeSlots
                    WHERE DayOfWeek = :strDay) 
            FROM OperatingHours
            WHERE TimeZone = :tZone
        ];
       System.debug('Time: ' + currentTime);                                                
       System.debug(tZone + ': ' + operatingHourList);
       
                                                        
       List<OperatingHours> activeOperatingHourList = new List<OperatingHours>();
       List<OperatingHours> inactiveOperatingHourList = new List<OperatingHours>();
              
       
       Time midnight = Time.newInstance(0,0,0,0);       
                         
        
        // StartTime < :currentTime AND EndTime > :currentTime
        for (OperatingHours currentOpHour : operatingHourList) {
            if (currentOpHour.TimeSlots.size() > 0) {
                for (TimeSlot tSlot : currentOpHour.TimeSlots) {
                    if (tSlot.DayOfWeek == strDay) {
                        
                        // Determine if the hours on the current day are active
                        if ((tSlot.StartTime == midnight || tSlot.StartTime <= currentTime) &&
                            (tSlot.EndTime == midnight || tSlot.EndTime >= currentTime)) {
                            activeOperatingHourList.add(currentOpHour);
                        } else {
                            inactiveOperatingHourList.add(currentOpHour);
                        }
                    }
                }
            } else {
                inactiveOperatingHourList.add(currentOpHour);
            }
        }

        operatingHourMap.put('Active', activeOperatingHourList);
        operatingHourMap.put('Inactive', inactiveOperatingHourList);
        
        //return activeOperatingHourList;
        return operatingHourMap;
        
    }
    
    // public static Set<Id> addHoursToSet(List<OperatingHours> activeHours, Set<Id> existingSet) {
    //     for(OperatingHours op : activeHours){
    //         existingSet.add(op.id);
    //     }
    //     return existingSet;
    // }    

    /**
     *  @purpose    - Traverse Primary STMs to find matches for active and inactive operating hours, then perform updates
     *  @params     - activeShiftIDs: ids for all of the active operating hours (all time zones)
     *              - inactiveShiftIDs: ids for all of the active operating hours (all time zones)
     *  @return     - Set<Id>: ids of all of the resources on the schedule  
     *
     */    
    public static Set<Id> getScheduledResources(Set<Id> activeOHSet, Set<Id> inactiveOHSet, Set<Id> resourcesWithActiveAbsenceIdSet, List<ServiceResource> ServiceResources, Map<Id, ServiceResource> srToUpdateMap) {
        // System.debug('active shifts: ' + activeShiftIDs);
        // System.debug('inactive shifts: ' + inactiveShiftIDs);
        // System.debug('ServiceResources: ' + ServiceResources);

        List<ServiceTerritoryMember> stmList = [
            SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, ServiceResource.Currently_Scheduled__c, ServiceResource.Idle__c
            FROM ServiceTerritoryMember
            WHERE TerritoryType = 'P'
            AND ServiceResourceId IN :ServiceResources
            AND ServiceResource.IsActive = true
            AND (OperatingHoursId IN :activeOHSet
            OR OperatingHoursId IN :inactiveOHSet)
        ];

        // List<ServiceTerritoryMember> inactiveSTMList = [
        //     SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, TerritoryType
        //     FROM ServiceTerritoryMember
        //     WHERE OperatingHoursId IN :inactiveShiftIDs
        //     AND TerritoryType = 'P'
        //     AND ServiceResourceId IN :ServiceResources
        //     AND ServiceResource.IsActive = true
        // ];
                                                
        Set<Id> scheduledResourceSet = new Set<Id>();
        // Set<Id> notScheduledResourceSet = new Set<Id>();
        
        // for(ServiceTerritoryMember stm : stmList){
        //     if(stm.ServiceResource.IsActive){
        //         scheduledResourceSet.add(stm.ServiceResourceId);
        //     }
        // }
        
        // for(ServiceTerritoryMember stm : inactiveSTMList){
        //     if(stm.ServiceResource.IsActive){
        //         notScheduledResourceSet.add(stm.ServiceResourceId);
        //     }
        // }
                
        
        // // iterate over all resources to see if they should be updated to being on the schedule
        // List<ServiceResource> onScheduleSRrList = [SELECT id, Currently_Scheduled__c FROM  ServiceResource WHERE ID IN :scheduledResourceSet];
        // List<ServiceResource> notOnScheduleSRrList = [SELECT id, Currently_Scheduled__c, Vehicle__c, Idle__c FROM  ServiceResource WHERE ID IN :notScheduledResourceSet];

        // List<ServiceResource> srUpdateList = new List<ServiceResource>();
        // for(ServiceResource sr : onScheduleSRrList){
        //     if(!sr.Currently_Scheduled__c){
        //         sr.Currently_Scheduled__c = true;
        //         srUpdateList.add(sr);
        //     }
        // }
        
        // for(ServiceResource sr : notOnScheduleSRrList){
        //     if(sr.Currently_Scheduled__c && sr.Idle__c){
        //         sr.Currently_Scheduled__c = false;
        //         //sr.Vehicle__c = null;
        //         srUpdateList.add(sr);               
        //     }
        // }
        
        // if(!srUpdateList.isEmpty()){
        //     update srUpdateList;
        // }

        for (ServiceTerritoryMember stm : stmList) {
            if (activeOHSet.contains(stm.OperatingHoursId)) {
                if (stm.ServiceResource.Currently_Scheduled__c) {
                    if (resourcesWithActiveAbsenceIdSet.contains(stm.ServiceResourceId)) {
                        ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = false);
                        srToUpdateMap.put(servRes.Id, servRes);
                    } else {
                        scheduledResourceSet.add(stm.ServiceResourceId);
                    }
                } else if (!resourcesWithActiveAbsenceIdSet.contains(stm.ServiceResourceId)) {
                    ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = true);
                    srToUpdateMap.put(servRes.Id, servRes);
                    scheduledResourceSet.add(stm.ServiceResourceId);
                }
                
            } else if (stm.ServiceResource.Currently_Scheduled__c && stm.ServiceResource.Idle__c) {
                ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = false);
                srToUpdateMap.put(servRes.Id, servRes);
            }
        }
        
        return scheduledResourceSet;
    }

    // The following method is used by Deloitte code and need to be cleaned up later
    public static Set<ID> getScheduledResources (Set<ID> activeShiftIDs, Set<ID> inactiveShiftIDs, list<ServiceResource> ServiceResources){
        system.debug('active shifts: ' + activeShiftIDs);
        system.debug('inactive shifts: ' + inactiveShiftIDs);
        system.debug('ServiceResources: ' + ServiceResources);        
        List<ServiceTerritoryMember> stmList = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, TerritoryType FROM ServiceTerritoryMember 
                                                WHERE OperatingHoursId IN :activeShiftIDs AND TerritoryType = 'P' AND ServiceResourceId  IN :ServiceResources];

        List<ServiceTerritoryMember> inactiveSTMList = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, TerritoryType FROM ServiceTerritoryMember 
                                                WHERE OperatingHoursId IN :inactiveShiftIDs AND TerritoryType = 'P' AND ServiceResourceId  IN :ServiceResources];

                                                
        Set<ID> scheduledResourceSet = new Set<ID>();
        Set<ID> notScheduledResourceSet = new Set<ID>();
        
        for(ServiceTerritoryMember stm : stmList){
            if(stm.ServiceResource.IsActive){
                scheduledResourceSet.add(stm.ServiceResourceId);
            }
        }
        
        for(ServiceTerritoryMember stm : inactiveSTMList){
            if(stm.ServiceResource.IsActive){
                notScheduledResourceSet.add(stm.ServiceResourceId);
            }
        }
                
        
        // iterate over all resources to see if they should be updated to being on the schedule
        List<ServiceResource> onScheduleSRrList = [SELECT id, Currently_Scheduled__c FROM  ServiceResource WHERE ID IN :scheduledResourceSet];
        List<ServiceResource> notOnScheduleSRrList = [SELECT id, Currently_Scheduled__c, Vehicle__c, Idle__c FROM  ServiceResource WHERE ID IN :notScheduledResourceSet];

        List<ServiceResource> srUpdateList = new List<ServiceResource>();
        for(ServiceResource sr : onScheduleSRrList){
            if(!sr.Currently_Scheduled__c){
                sr.Currently_Scheduled__c = true;
                srUpdateList.add(sr);
            }
        }
        
        for(ServiceResource sr : notOnScheduleSRrList){
            if(sr.Currently_Scheduled__c && sr.Idle__c){
                sr.Currently_Scheduled__c = false;
                //sr.Vehicle__c = null;
                srUpdateList.add(sr);               
            }
        }
        
        if(!srUpdateList.isEmpty()){
            update srUpdateList;
        }

        
        return scheduledResourceSet;
        
    }

    //     ***  updateSROnScheduleFlag() is commented out as it's the same as getScheduledResources()   ***

    // public static void updateSROnScheduleFlag(Set<Id> activeShiftIDs, Set<Id> inactiveShiftIDs, List<ServiceResource> ServiceResources) {
    //     System.debug('active shifts: ' + activeShiftIDs);
    //     System.debug('inactive shifts: ' + inactiveShiftIDs);
    //     System.debug('ServiceResources: ' + ServiceResources);        
    //     List<ServiceTerritoryMember> stmList = [
    //         SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, TerritoryType
    //         FROM ServiceTerritoryMember
    //         WHERE OperatingHoursId IN :activeShiftIDs
    //         AND TerritoryType = 'P'
    //         AND ServiceResourceId IN :ServiceResources
    //     ];

    //     List<ServiceTerritoryMember> inactiveSTMList = [
    //         SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, TerritoryType
    //         FROM ServiceTerritoryMember
    //         WHERE OperatingHoursId IN :inactiveShiftIDs
    //         AND TerritoryType = 'P'
    //         AND ServiceResourceId IN :ServiceResources
    //     ];
                                                
    //     Set<Id> scheduledResourceSet = new Set<Id>();
    //     Set<Id> notScheduledResourceSet = new Set<Id>();
        
    //     for (ServiceTerritoryMember stm : stmList) {
    //         if (stm.ServiceResource.IsActive) {
    //             scheduledResourceSet.add(stm.ServiceResourceId);
    //         }
    //     }
        
    //     for (ServiceTerritoryMember stm : inactiveSTMList) {
    //         if (stm.ServiceResource.IsActive) {
    //             notScheduledResourceSet.add(stm.ServiceResourceId);
    //         }
    //     }

    //     // iterate over all resources to see if they should be updated to being on the schedule
    //     List<ServiceResource> onScheduleSRrList = [SELECT id, Currently_Scheduled__c FROM  ServiceResource WHERE ID IN :scheduledResourceSet];
    //     List<ServiceResource> notOnScheduleSRrList = [SELECT id, Currently_Scheduled__c, Vehicle__c, Idle__c FROM  ServiceResource WHERE ID IN :notScheduledResourceSet];

    //     List<ServiceResource> srUpdateList = new List<ServiceResource>();
    //     for(ServiceResource sr : onScheduleSRrList){
    //         if(!sr.Currently_Scheduled__c){
    //             sr.Currently_Scheduled__c = true;
    //             srUpdateList.add(sr);
    //         }
    //     }
        
    //     for(ServiceResource sr : notOnScheduleSRrList){
    //         if(sr.Currently_Scheduled__c && sr.Idle__c){
    //             sr.Currently_Scheduled__c = false;               
    //             srUpdateList.add(sr);               
    //         }
    //     }
        
    //     if(!srUpdateList.isEmpty()){
    //         update srUpdateList;
    //     }                  
    // }

    public static List<ServiceAppointment> getActiveAppointments(DateTime rightNow, list<ServiceResource> ServiceResources) {
        List<ServiceAppointment> activeAppointmentList = [
            SELECT Id, SchedStartTime, SchedEndTime, Service_Resource__c
            FROM ServiceAppointment
            WHERE SchedStartTime < :rightNow
            AND SchedEndTime > :rightNow 
            AND Service_Resource__c IN :ServiceResources
        ];
        return activeAppointmentList;
    }
    
    // public static List<ResourceAbsence> getActiveAbsences(DateTime rightNow, List<ServiceResource> ServiceResources) {
    //     List<ResourceAbsence> activeAbsenceList = [
    //         SELECT Id, Start, End, ResourceId
    //         FROM ResourceAbsence
    //         WHERE Start < :rightNow
    //         AND End > :rightNow
    //         AND ResourceId IN :ServiceResources
    //     ];
    //     return activeAbsenceList;
    // }
    
    public static Set<Id> getActiveResources(List<ServiceAppointment> activeAppointments/*, List<ResourceAbsence> activeAbsences*/) {
        Set<Id> activeResourceIDs = new Set<Id>();
        for(ServiceAppointment sa : activeAppointments){
            activeResourceIDs.add(sa.Service_Resource__c);
        }
        // for(ResourceAbsence ra : activeAbsences){
        //     activeResourceIDs.add(ra.ResourceId);
        // }
        System.debug('Active Resource List = ' + activeResourceIDs);
        return activeResourceIDs;
    }
    
    public static List<ServiceResource> getIdleResources(Set<Id> scheduledResources, Set<Id> activeResources) {
        Set<Id> idleResourceSet = new Set<Id>();
        
        // iterate over each resource on the schedule
        for(ID scheduledResourceID : scheduledResources){
            // if the set of active resources does not contain the scheduled resource
            if(!activeResources.contains(scheduledResourceID)){
                // add the scheduled resource to the idle set
                idleResourceSet.add(scheduledResourceID);
            }
        }

        // Now futher filter the idle list to get only those SR who are really idling        
        List<ServiceResource> idleResourceList = getNonStaleIdleServiceResources(idleResourceSet);

        return idleResourceList;
    }

    public static List<ServiceResource> getNonStaleIdleServiceResources(Set<Id> idleResourceSet) {
        // Do the ResourceAbsense filter here, filter out those AR that has Stale SR Lat/Long                
        // Get rid of those SR that does not have Idel__c flag set to true 

        // Get the comparison min in metadata
        Integer staleMin = getLKLStaleIdleTime();
        List<ServiceResource> srList = [
            SELECT Id, Currently_Scheduled__c, LastKnownLatitude, LastKnownLongitude
            FROM ServiceResource
            WHERE Id IN :idleResourceSet
            AND Idle__c = true
            AND LastKnownLocationDate > :DateTime.now().addMinutes(-staleMin)
        ];
        return srList;
    }

    public static Integer getLKLStaleIdleTime() {
        List<FSL_LKL_Configuration__mdt> lklStaleIdelTimeConfig = getFSLKLConfiguration('Non_Stale_Idle_Resource');

        Integer staleTime = 30; // Default value
        if (!lklStaleIdelTimeConfig.isEmpty()) {
            staleTime = lklStaleIdelTimeConfig[0].LastKnownLocationFilter__c.intValue();
        }
        return staleTime;
    }

    private static List<FSL_LKL_Configuration__mdt> getFSLKLConfiguration(String configName) {
        return [SELECT LastKnownLocationFilter__c
                FROM   FSL_LKL_Configuration__mdt
                WHERE  DeveloperName = :configName  
                LIMIT 1];
    }

    public static void startServiceResourceUpdateBatch( List<ServiceResource> srList ) {    
        FSL_IterableBatchable batch = new FSL_IterableBatchable( new UpdateServiceResourceBatchable( srList ) );
        Database.executeBatch( batch );            
    }

    public class ShiftLKL {
        private Set<Shift> activeShiftsSet;                             // The Shifts Set containing all the latest active shifts
        private Set<Id> activeShiftsResourceIdSet;             
        private Map<Id,List<ServiceAppointment>> shiftsWithActiveAppt;
        private Map<Id,ServiceResource> srActiveShiftsMap;
        private List<ServiceResource> serviceResourceList;
        private Set<Id> resourcesWithActiveAbsenceIdSet;
        // private List<Shift>  confirmedShifts;

        public ShiftLKL(List<ServiceResource> serviceResourceList, Set<Id> resourcesWithActiveAbsenceIdSet) {
            activeShiftsSet = new Set<Shift>();
            activeShiftsResourceIdSet = new Set<Id>();
            shiftsWithActiveAppt = new Map<Id,List<ServiceAppointment>>();
            srActiveShiftsMap = new Map<Id,ServiceResource>();
            this.serviceResourceList = serviceResourceList;
            this.resourcesWithActiveAbsenceIdSet = resourcesWithActiveAbsenceIdSet;
            // confirmedShifts = new  List<Shift>();
        }
        
        private List<Shift> getActiveConfirmedShifts() {
            // Get the confirmed list of Shifts - this list is only retrieved once for all Timezones
            // Also get the ServiceResources Records here to save a trip to db

            // if (confirmedShifts.size() < 1) {
            //     confirmedShifts = [
            return [
                SELECT Id, StartTime, EndTime, ServiceTerritoryId, ServiceResourceId, Status, TimeSlotType, ServiceTerritory.OperatingHours.Timezone,
                        ServiceResource.Id, ServiceResource.LastKnownLatitude, ServiceResource.LastKnownLongitude, ServiceResource.LastKnownLocationDate,
                        ServiceResource.isActive, ServiceResource.Currently_Scheduled__c
                FROM Shift
                WHERE Status = 'Confirmed'
                AND StartTime <= :System.now()
                AND EndTime >= :System.now()
                AND ServiceResourceId IN :this.serviceResourceList
            ];
            // return confirmedShifts;            
        }

        // public Set<Shift> getActiveShifts(DateTime currentTime) {
        //     List<Shift> confirmedShifts = getConfirmedShifts();
            // Set<Shift> activeShifts = getActiveShifts(currentTime, confirmedShifts);           
            // return activeShifts;
        // }

        // public Set<Shift> getActiveShifts(DateTime currentTime, List<Shift> confirmedShifts) {            
        //     // Make sure the shift is active compared to the current Datetime
        //     Set<Shift> activeShifts = new Set<Shift>();
        //     for(Shift shiftRec : confirmedShifts) {
        //         if(currentTime >= shiftRec.startTime && currentTime <= shiftRec.endTime) {
        //             activeShifts.add(shiftRec);
        //         }
        //     }

        //     System.Debug('activeShifts - ' + activeShifts);
        //     return activeShifts;
        // }

        public Set<Shift> addAllActiveShifts() {           
            activeShiftsSet.addAll(getActiveConfirmedShifts());
            System.Debug('activeShiftsSet - ' + activeShiftsSet);
            return activeShiftsSet;
        }

        public Set<Id> getActiveShiftsResourceIdSet() {
            for (Shift sf : activeShiftsSet) {
                activeShiftsResourceIdSet.add(sf.ServiceResourceId);
            }
            return activeShiftsResourceIdSet;
        }

        public Map<Id,List<ServiceAppointment>> getActiveAppointmentsWithResources(DateTime currentTime) {
            activeShiftsResourceIdSet = getActiveShiftsResourceIdSet();           
            for(ServiceAppointment apt : [SELECT id, SchedStartTime, SchedEndTime, Service_Resource__c 
                                          FROM ServiceAppointment
                                          WHERE Status NOT IN ('Canceled','Cleared')
                                          AND Service_Resource__c IN :activeShiftsResourceIdSet]) {
                if (shiftsWithActiveAppt.containsKey(apt.Service_Resource__c)) {
                    shiftsWithActiveAppt.get(apt.Service_Resource__c).add(apt);
                } else {
                    shiftsWithActiveAppt.put(apt.Service_Resource__c,new List<ServiceAppointment>{apt});
                }       
            }
            return shiftsWithActiveAppt;    
        }

        public Set<Id> getActiveResourcesWithCurrentSchedule() {
            Set<Id> rsIdSet = new Set<Id>();
            //for(ServiceResource sr : [SELECT Id FROM ServiceResource WHERE isActive = true AND Id IN : activeShiftsResourceIdSet AND Currently_Scheduled__c = true]) {
            // Filter throught the activeShiftsSet and identify those that are currently on schedule
            for (Shift sf : activeShiftsSet) {
                if (sf.ServiceResource.isActive && sf.ServiceResource.Currently_Scheduled__c) {
                    rsIdSet.add(sf.ServiceResource.Id);
                }                
            }
            return rsIdSet;
        }

        public Map<Id,ServiceResource> GetActiveShiftsResources() {
            // Create active Shift ServiceResource
            // Map<Id,ServiceResource> srShiftMap = new Map<Id,ServiceResource>([SELECT Id,Currently_Scheduled__c FROM ServiceResource WHERE Id IN : activeShiftsResourceIdSet]);            
            Map<Id,ServiceResource> srActiveShiftMap = new Map<Id,ServiceResource>();

            for (Shift sf : activeShiftsSet) {
                ServiceResource sr = new ServiceResource();
                if (srActiveShiftMap.get(sf.ServiceResource.Id) == null) {
                    sr.Currently_Scheduled__c = sf.ServiceResource.Currently_Scheduled__c;
                    sr.Id = sf.ServiceResource.Id;                   
                    sr.LastKnownLatitude = sf.ServiceResource.LastKnownLatitude;
                    sr.LastKnownLongitude = sf.ServiceResource.LastKnownLongitude;
                    sr.LastKnownLocationDate = sf.ServiceResource.LastKnownLocationDate;
                    
                    srActiveShiftMap.put(sf.ServiceResource.Id, sr);
                }                
            }

            return srActiveShiftMap;
        }

        public List<ServiceResource> updateShiftResourceOnScheduleFlag() {
            //Shift : #Step-3 Current Sheduled Resources
            Set<Id> onScheduleSRIdSet = getActiveResourcesWithCurrentSchedule();
            srActiveShiftsMap = GetActiveShiftsResources();

            List<ServiceResource> resourOnScheduleList = new List<ServiceResource>();
            for (Id resId : srActiveShiftsMap.keySet()) {
                if (!onScheduleSRIdSet.contains(resId)) {
                    ServiceResource sr = new ServiceResource();
                    if (!srActiveShiftsMap.get(resId).Currently_Scheduled__c && !this.resourcesWithActiveAbsenceIdSet.contains(resId)) {
                        sr.Currently_Scheduled__c = true;
                        sr.Id = resId;
                        resourOnScheduleList.add(sr);
                    }
                } else {
                    ServiceResource sr = new ServiceResource();
                    if (srActiveShiftsMap.get(resId).Currently_Scheduled__c && this.resourcesWithActiveAbsenceIdSet.contains(resId)) {
                        sr.Currently_Scheduled__c = false;
                        sr.Id = resId;
                        resourOnScheduleList.add(sr);
                    }
                }
            }
            // if (!resourOnScheduleList.isEmpty()) {
            //     update resourOnScheduleList;
            // }      
            
            return resourOnScheduleList;
        }

        public List<ServiceResource> getIdleShiftResources() {
            // Filter through the list of active resources for shifts and get what we want - idle resources
            // AND LastKnownLocationDate > :DateTime.now().addMinutes(-staleMin)];

            //Shift : #Step-4 For Every member of Step-1 That is not in Step-2 Create LKL
            List<ServiceResource> idleShiftResources = new List<ServiceResource>();
            
             // Get the comparison min in metadata
            Integer staleMin = getLKLStaleIdleTime();            
            DateTime staleDateTime = DateTime.now().addMinutes(-staleMin);

            for (Id resId : srActiveShiftsMap.keySet()) {
                System.debug('shiftsWithActiveAppt - ' + shiftsWithActiveAppt);
                System.debug('srActiveShiftsMap - ' + srActiveShiftsMap);

                // If an active Shift Resource does not have an active SA, and it is within the stale datetime windown, then add it to the shift idle list
                if (!shiftsWithActiveAppt.containsKey(resId) && srActiveShiftsMap.get(resId).LastKnownLocationDate > staleDateTime ) {
                    idleShiftResources.add(srActiveShiftsMap.get(resId));
                }
            }
            return idleShiftResources;
        }

        public List<ServiceResource> getIdleShiftResources(DateTime currentDateTime, Map<Id, ServiceResource> srToUpdateMap) {
            //Shift : #Step-2 Get Active Appointments             
            getActiveAppointmentsWithResources(currentDateTime);

            //Shift : #Step-3 update Currently_Scheduled__c flag, return the idel list of Shift Resources
            List<ServiceResource> srToUpdateList = updateShiftResourceOnScheduleFlag();
            srToUpdateMap.putAll(srToUpdateList);

            //Shift : Get the list of Shifts with idle resources
            List<ServiceResource> idleShiftResources = getIdleShiftResources();
            return idleShiftResources;
        }              
    }

    // ****************************************************************************
    // * Batchable Implementation - Update the Service Resource 'On Schedule' Flag
    // ****************************************************************************
    private class UpdateServiceResourceBatchable implements FSL_IterableBatchable.IBatchable {

        private List<ServiceResource> srList;

        public UpdateServiceResourceBatchable(List<ServiceResource> srList) {
            this.srList = srList;
        }

        public Iterable<SObject> start( Database.BatchableContext context ) {           
            return srList;
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            if( items.size() > 0 ) {
                update items;
            }
        }
        public void finish( Database.BatchableContext context ) {
        }
    }
}