/****
 * *@Name: FSL_BatteryTruckAvailability
 * *@Description: Callout class to check Battery truck availability with Service Resource when it called from D3.
 * *@Date: 07-05-2020
 * *@Version: 1.0
 * * 
 * **/

@RestResource(urlMapping='/facility/battery/*')
global with sharing class FSL_BatteryTruckAvailability {

    /**********
     *@Method Name:checkTruckAvailability
     *@Parameters: (TruckAvailabilityRequest )
     *@Description: This method parses the json request comming from D3 and send the Battery truck availability.
     * Sample Payload:
     * {
        "transactionID" : "1111112222",
        "locationLatitude" : "28.68441",
        "locationLongitude" : "-81.32394",
        "skills":["Battery_Capable","Battery_Replacement"]
      }
     **************/
    @HttpPost
    global static FSL_BatteryTruckAvailability.FSL_TruckAvailabilityResponse checkTruckAvailability() {
        FSL_BatteryTruckAvailability.FSL_TruckAvailabilityResponse responseJson = new FSL_BatteryTruckAvailability.FSL_TruckAvailabilityResponse();
        RestRequest request = RestContext.request;
        FSL_BatteryTruckAvailability.FSL_TruckAvailabilityRequest requestWrap = new FSL_BatteryTruckAvailability.FSL_TruckAvailabilityRequest();
        try {
            System.debug('request.requestBody.toString()==>'+request.requestBody.toString());
            
            try {
                requestWrap  = (FSL_BatteryTruckAvailability.FSL_TruckAvailabilityRequest)Json.deserialize(request.requestBody.toString(),FSL_BatteryTruckAvailability.FSL_TruckAvailabilityRequest.class);                
            }catch(Exception ex) {
                system.debug('Exception data:'+ex);
                Map<String, Object> requestJSONMap =  (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
                responseJson.transactionID = (String)requestJSONMap.get('transactionID');
                responseJson.statusCode = '405';
                responseJson.statusDescription = 'Incorrect JSON formate ::'+ex.getStackTraceString();
                return responseJson;
            }
            responseJson.transactionID = requestWrap.transactionID;
            responseJson.availability = 'No';
            if(requestWrap.locationLongitude != null && requestWrap.locationLatitude != null) {
                if(requestWrap.skills == null || requestWrap.skills.isEmpty()) {
                    requestWrap.skills = new List<String>{'Battery_Replacement'};
                    //requestWrap.skillName = 'Battery_Capable';
                }
                DateTime currentDateTime = System.now();
                String currentDay = currentDateTime.format('EEEE');
                Time currentTime = Time.newInstance(currentDateTime.hourGmt(), currentDateTime.minuteGmt(), currentDateTime.secondGmt(), currentDateTime.millisecondGmt());
                
                Set<Id> resourceIdSet = new Set<Id>();
                Set<Id> opHoursIdSet = new Set<Id>();
                Set<Id> activeSrIdSet = new Set<Id>();
                String territoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(requestWrap.locationLongitude,requestWrap.locationLatitude);                                 

                if(territoryId != null) {

                    // ERS-230370 ACE Service Territory Override                      
                    territoryId = getServiceTerritoryOverrideId(territoryId);
                
                    Set<ID> activeOperatingHoursSet = new Set<ID>();
                    Set<ID> inactiveOperatingHoursSet = new Set<ID>();
                    List<ServiceResource> srList = new List<ServiceResource>();
                    ServiceTerritory st = [Select Id, OperatingHours.timezone,OperatingHoursId from ServiceTerritory where Id =:territoryId];
                    FSL_LKL_Timezone__mdt lklTZ = [select timezone_DL__c, timezone__c from FSL_LKL_Timezone__mdt where timezone__c=:st.OperatingHours.timezone];
                    DateTime DateTime_tz = DateTime.valueOf(currentDateTime.format('yyyy-MM-dd HH:mm:ss', lklTZ.timezone_DL__c));       
                    String Day_tz = DateTime_tz.format('EEEE');
                    Time Time_tz = Time.newInstance(DateTime_tz.hour(), DateTime_tz.minute(), DateTime_tz.second(), DateTime_tz.millisecond());                
                    //Query is to get all service resources that aligned to the territory.
                    for(ServiceTerritoryMember stm : [Select Id,ServiceResourceId,ServiceTerritoryId,operatingHoursId from ServiceTerritoryMember 
                                        where ServiceTerritoryId =: territoryId AND FSL_Expired_Resource_Territory__c = false AND
                                        /*ServiceResource.Currently_Scheduled__c = true AND*/ ServiceResource.IsActive = TRUE]) {
                                            resourceIdSet.add(stm.ServiceResourceId);
                                            //opHoursIdSet.add(stm.operatingHoursId);
                                            srList.add(new ServiceResource(id=stm.ServiceResourceId));
                    }
                    //Query it to get the resources Primary territorytype STM's to get the actual operating hours
                    for(ServiceTerritoryMember primStm : [Select Id,ServiceResourceId,ServiceTerritoryId,operatingHoursId,TerritoryType from ServiceTerritoryMember 
                    where ServiceResourceId In : resourceIdSet AND (TerritoryType ='P' OR TerritoryType ='S')]) {
                        opHoursIdSet.add(primStm.operatingHoursId);
                    }
                    //Get Operating hours timeslots to identify active timeslots by passing stm's operating hours
                    Map<String, List<OperatingHours>> OperatingHoursMap = getActiveOperatingHours(Time_tz, Day_tz, opHoursIdSet);
                    for(string active_or_inactive : OperatingHoursMap.keySet()){
                        for(OperatingHours OperatingHours : OperatingHoursMap.get(active_or_inactive)){
                            if(active_or_inactive.equalsIgnoreCase('Active')){
                                activeOperatingHoursSet.add(OperatingHours.id);
                            }else if (active_or_inactive.equalsIgnoreCase('Inactive')){
                                inactiveOperatingHoursSet.add(OperatingHours.id);
                            }
                        }    
                    }

                    Set<Id> resourcesWithActiveAbsenceIdSet = getResourcesWithActiveAbsenceIdSet(srList);

                    //To Be confirmed whether to update service resource currently_schedule flag to true.
                    Set<ID> scheduledResources = FSL_TruckAvailabilityResponse.getScheduledResources(activeOperatingHoursSet, inactiveOperatingHoursSet, resourcesWithActiveAbsenceIdSet, srList);
                    if(!scheduledResources.isEmpty()) {
                        activeSrIdSet.addAll(scheduledResources);
                    }
                    /*OperatingHour opHour = [SELECT id, Name, TimeZone, (SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlots WHERE DayOfWeek = :Day_tz) 
                    FROM OperatingHours WHERE Id = :st.operatingHoursId];
                    boolean activeTimeslotFound = true;
                    for(TimeSlot tSlot : opHour.TimeSlots){
                        system.debug(currentOpHour.Name);
                        system.debug('Day: ' + tSlot.DayOfWeek);
                        system.debug('Start Time: ' + tSlot.StartTime);
                        system.debug('End Time: ' + tSlot.EndTime); 
                        system.debug('Current Time: ' + currentTime);                   
                        
                        // Determine if the hours on the current day are active
                        if( (tSlot.StartTime == midnight || tSlot.StartTime <= currentTime) &&
                            (tSlot.EndTime == midnight || tSlot.EndTime >= currentTime)){
                            system.debug('active');
                            activeTimeslotFound = false;
                            break;
                        }
                    }*/

                    //Get all shifts for the resources where status='Confirmed'
                    List<Shift> sfList = [SELECT id,startTime,EndTime,ServiceTerritoryId,ServiceResourceId,Status,TimeSlotType,
                    ServiceTerritory.OperatingHours.Timezone from Shift where status='Confirmed' AND ServiceResourceId IN : resourceIdSet];
                    
                    //Call getActiveShifts method to identify the segrigate the resources who are having active Shifts
                    FSL_LastKnownLocationUtility.ShiftLKL shiftLKL = new FSL_LastKnownLocationUtility.ShiftLKL(srList, resourcesWithActiveAbsenceIdSet);                   
                    // for(Shift activeShift :  shiftLKL.getActiveShifts(DateTime_tz,sfList)) {
                    //     activeSrIdSet.add(activeShift.ServiceResourceId);
                    // }
                    shiftLKL.addAllActiveShifts();
                    activeSrIdSet.addAll(shiftLKL.getActiveShiftsResourceIdSet());

                    if(!activeSrIdSet.isEmpty()) {
                        Map<Id,Set<String>> resourceIdSkillMap = new Map<Id,Set<String>>();
                        for(ServiceResourceSkill srSkill : [Select Id,SkillId,Skill.DeveloperName,ServiceResourceId from ServiceResourceSkill where skill.DeveloperName IN:requestWrap.skills AND ServiceResourceId IN : activeSrIdSet]) {
                            //responseJson.availability = 'Yes';
                            if(!resourceIdSkillMap.containsKey(srSkill.ServiceResourceId)) {
                                resourceIdSkillMap.put(srSkill.ServiceResourceId,new Set<String>{srSkill.skill.DeveloperName});
                            }else {
                                resourceIdSkillMap.get(srSkill.ServiceResourceId).add(srSkill.skill.DeveloperName);
                            }
                            
                        }
                        if(!resourceIdSkillMap.isEmpty()) {
                            for(Id resId : resourceIdSkillMap.keySet()) {
                                Boolean foundAllSkills = true;
                                Set<String> resSkillSet = resourceIdSkillMap.get(resId);
                                System.debug('resId===>'+resId+'====>'+resSkillSet);
                                System.debug('requestWrap.skills===>'+requestWrap.skills);
                                for(String skillFromWrap : requestWrap.skills) {
                                    if(!resSkillSet.contains(skillFromWrap)) {
                                        foundAllSkills = false;
                                    }
                                }
                                System.debug('foundAllSkills===>'+foundAllSkills);
                                if(foundAllSkills) {
                                    responseJson.availability = 'Yes';
                                    break;
                                }
                            }
                        }
                    }
                }               
            }else {
                responseJson.statusCode = '405';
                responseJson.statusDescription = 'Please provide Lattitude And Longitude'; 
                return responseJson;  
            }
            responseJson.statusCode = '200';
            responseJson.statusDescription = 'SUCCESS';            
        }catch(Exception ex) {
            responseJson.statusCode = '400';
            responseJson.statusDescription = ex.getStackTraceString();
            return responseJson;
        }
        return responseJson;
    }

    
    public static Set<Id> getScheduledResources(Set<Id> activeOHSet, Set<Id> inactiveOHSet, Set<Id> resourcesWithActiveAbsenceIdSet, List<ServiceResource> ServiceResources) {
        // System.debug('active shifts: ' + activeShiftIDs);
        // System.debug('inactive shifts: ' + inactiveShiftIDs);
        // System.debug('ServiceResources: ' + ServiceResources);

        List<ServiceTerritoryMember> stmList = [
            SELECT id, OperatingHoursId, ServiceResourceId, ServiceResource.IsActive, ServiceResource.Currently_Scheduled__c, ServiceResource.Idle__c
            FROM ServiceTerritoryMember
            WHERE (TerritoryType = 'P' OR TerritoryType = 'S')
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
                
        
        // iterate over all resources to see if they should be updated to being on the schedule
        // List<ServiceResource> onScheduleSRrList = [SELECT id, Currently_Scheduled__c FROM  ServiceResource WHERE ID IN :scheduledResourceSet];
        // List<ServiceResource> notOnScheduleSRrList = [SELECT id, Currently_Scheduled__c, Vehicle__c, Idle__c FROM  ServiceResource WHERE ID IN :notScheduledResourceSet];

        List<ServiceResource> srUpdateList = new List<ServiceResource>();
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

        for (ServiceTerritoryMember stm : stmList) {
            if (activeOHSet.contains(stm.OperatingHoursId)) {
                if (stm.ServiceResource.Currently_Scheduled__c) {
                    if (resourcesWithActiveAbsenceIdSet.contains(stm.ServiceResourceId)) {
                        ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = false);
                        srUpdateList.add(servRes);
                    } else {
                        scheduledResourceSet.add(stm.ServiceResourceId);
                    }
                } else if (!resourcesWithActiveAbsenceIdSet.contains(stm.ServiceResourceId)) {
                    ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = true);
                    srUpdateList.add(servRes);
                    scheduledResourceSet.add(stm.ServiceResourceId);
                }
                
            } else if (stm.ServiceResource.Currently_Scheduled__c && stm.ServiceResource.Idle__c) {
                ServiceResource servRes = new ServiceResource(Id = stm.ServiceResourceId, Currently_Scheduled__c = false);
                srUpdateList.add(servRes);
            }
        }
        
        if (!srUpdateList.isEmpty()) {
            update srUpdateList;
        }
        
        return scheduledResourceSet;
    }

    public static Map<String, List<OperatingHours>> getActiveOperatingHours(Time currentTime, String strDay, Set<Id> operatingHoursId){
        Map<String, List<OperatingHours>> operatingHourMap = new Map<String, List<OperatingHours>>();
        
       // Updat 11/19: Removing DayOfWeek from TimeSlot query to pull all inactive hours - WHERE DayOfWeek = :strDay
       List<OperatingHours> operatingHourList = [SELECT id, Name, TimeZone, 
                                                        (SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlots WHERE DayOfWeek = :strDay) 
                                                        FROM OperatingHours WHERE Id IN :operatingHoursId];
       system.debug('Time: ' + currentTime);                                                
       //system.debug(tZone + ': ' + operatingHourList);
       
                                                        
       List<OperatingHours> activeOperatingHourList = new List<OperatingHours>();
       List<OperatingHours> inactiveOperatingHourList = new List<OperatingHours>();
              
       
       Time midnight = Time.newInstance(0,0,0,0);       
       system.debug('midnight: ' + midnight);                                   
        
        // StartTime < :currentTime AND EndTime > :currentTime
        for(OperatingHours currentOpHour : operatingHourList){
            if(currentOpHour.TimeSlots.size()>0){
                for(TimeSlot tSlot : currentOpHour.TimeSlots){
                    if(tSlot.DayOfWeek == strDay){
                        // Determine if the hours on the current day are active
                        if( (tSlot.StartTime == midnight || tSlot.StartTime <= currentTime) &&
                            (tSlot.EndTime == midnight || tSlot.EndTime >= currentTime)){
                            activeOperatingHourList.add(currentOpHour);
                            system.debug('active');
                        }else{
                            inactiveOperatingHourList.add(currentOpHour);
                            system.debug('inactive');
                        }
                    }
                }
            }else {
                inactiveOperatingHourList.add(currentOpHour);
            }
        }
        
        system.debug('All Active Hours: ' + activeOperatingHourList);
        system.debug('All Inactive Hours: ' + inactiveOperatingHourList);
        operatingHourMap.put('Active', activeOperatingHourList);
        operatingHourMap.put('Inactive', inactiveOperatingHourList);
        
        //return activeOperatingHourList;
        return operatingHourMap;
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

    global class FSL_TruckAvailabilityResponse {
        public String transactionID;
        public String availability;
        public String statusCode;
        public String statusDescription;
    }

    global class FSL_TruckAvailabilityRequest {
        public String transactionID;
        public Double locationLatitude;
        public Double locationLongitude;
        public List<String>  skills;
    }

    @testVisible
    private static Id getServiceTerritoryOverrideId(Id serviceTerritoryId){
        // This routine takes the incoming Service Territory Id and check to see if there is a ST override, if it does, return that ST override Id       
        Id overrideSTId = serviceTerritoryId;

        // Check to see if input service territory is a map territory
        Boolean isMapST = isMapServiceTerritory(serviceTerritoryId);
        if(isMapST){
            // Retrieve the Overide ST Id from Scheduling Override Object
            WorkOrder wo = New WorkOrder();

            

            // Now get the WorkType ID
            List<WorkType> workTypes = [SELECT Id FROM WorkType WHERE NAME = 'Battery Jumpstart'];
            if(!workTypes.isEmpty()) {
                wo.WorktypeId = workTypes[0].Id;
                wo.Pta__c =  System.now();

                // Call overrite routine
                overrideSTId = FSL_SchedulingUtility.getScheduleOverrideSTId(serviceTerritoryId, wo);
            }            
        }
                
        return overrideSTId;
    }

    @testVisible
    private static boolean isMapServiceTerritory(Id serviceTerritoryId){        
        Id RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Map Territory').getRecordTypeId();
        List<ServiceTerritory> mapSTList = [SELECT Id FROM ServiceTerritory WHERE Id = :serviceTerritoryId AND RecordTypeId = :RecordTypeId];

        // TODO, log error if more than one entries returned
        return !mapSTList.isEmpty() ? true : false;
    }  

}