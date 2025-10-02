/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 07-29-2022
 * @last modified by  : Clement Shiu
**/
public class BSPAvailability {
    @AuraEnabled
    public static String bspAvailabilityCheck(Double lat, Double lng){
        String availability = 'No';
        DateTime currentDateTime = System.now();
        String currentDay = currentDateTime.format('EEEE');
        Time currentTime = Time.newInstance(currentDateTime.hourGmt(), currentDateTime.minuteGmt(), currentDateTime.secondGmt(), currentDateTime.millisecondGmt());
        List<String> skills = new List<String>{'Battery_Replacement'};
        Set<Id> resourceIdSet = new Set<Id>();
        Set<Id> opHoursIdSet = new Set<Id>();
        Set<Id> activeSrIdSet = new Set<Id>();
        String territoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(lng,lat); 
        system.debug('territoryId--->'+territoryId);
        if(territoryId != null) {
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
            system.debug('srList-->'+srList);
            //Query it to get the resources Primary territorytype STM's to get the actual operating hours
            for(ServiceTerritoryMember primStm : [Select Id,ServiceResourceId,ServiceTerritoryId,operatingHoursId,TerritoryType from ServiceTerritoryMember 
                                                  where ServiceResourceId In : resourceIdSet AND TerritoryType ='P']) {
                                                      opHoursIdSet.add(primStm.operatingHoursId);
                                                  }
            //Get Operating hours timeslots to identify active timeslots by passing stm's operating hours
            system.Debug('opHoursIdSet'+opHoursIdSet);
            Map<String, List<OperatingHours>> OperatingHoursMap = getActiveOperatingHours(Time_tz, Day_tz, opHoursIdSet);
            system.debug('OperatingHoursMap-->'+OperatingHoursMap);
            for(string active_or_inactive : OperatingHoursMap.keySet()){
                for(OperatingHours OperatingHours : OperatingHoursMap.get(active_or_inactive)){
                    if(active_or_inactive.equalsIgnoreCase('Active')){
                        activeOperatingHoursSet.add(OperatingHours.id);
                    }else if (active_or_inactive.equalsIgnoreCase('Inactive')){
                        inactiveOperatingHoursSet.add(OperatingHours.id);
                    }
                }    
            }
            system.debug('activeOperatingHoursSet-->'+activeOperatingHoursSet);
            system.debug('inactiveOperatingHoursSet--->'+inactiveOperatingHoursSet);
            
            Set<ID> scheduledResources = FSL_LastKnownLocationUtility.getScheduledResources(activeOperatingHoursSet, inactiveOperatingHoursSet,srList);            

            if(!scheduledResources.isEmpty()) {
                activeSrIdSet.addAll(scheduledResources);
            }
            system.debug('activeSrIdSet-->'+activeSrIdSet);
            //Get all shifts for the resources where status='Confirmed'
            List<Shift> sfList = [SELECT id,startTime,EndTime,ServiceTerritoryId,ServiceResourceId,Status,TimeSlotType,
              ServiceTerritory.OperatingHours.Timezone from Shift where status='Confirmed' AND ServiceResourceId IN : resourceIdSet];
              
            //Call getActiveShifts method to identify the segrigate the resources who are having active Shifts
            /* FIXME - the following shift routines are completely rewritten in the latest Service Team Dispatch System
            for(Shift activeShift : FSL_LastKnownLocationUtility.getActiveShifts(DateTime_tz,sfList)) {
                activeSrIdSet.add(activeShift.ServiceResourceId);
            }
            */
            if(!activeSrIdSet.isEmpty()) {
                Map<Id,Set<String>> resourceIdSkillMap = new Map<Id,Set<String>>();
                for(ServiceResourceSkill srSkill : [Select Id,SkillId,Skill.DeveloperName,ServiceResourceId from ServiceResourceSkill where skill.DeveloperName IN:skills AND ServiceResourceId IN : activeSrIdSet]) {
                    //responseJson.availability = 'Yes';
                    if(!resourceIdSkillMap.containsKey(srSkill.ServiceResourceId)) {
                        resourceIdSkillMap.put(srSkill.ServiceResourceId,new Set<String>{srSkill.skill.DeveloperName});
                    }else {
                        resourceIdSkillMap.get(srSkill.ServiceResourceId).add(srSkill.skill.DeveloperName);
                    }                      
                }
            system.debug('resourceIdSkillMap--->'+resourceIdSkillMap);
                if(!resourceIdSkillMap.isEmpty()) {
                    for(Id resId : resourceIdSkillMap.keySet()) {
                        Boolean foundAllSkills = true;
                        Set<String> resSkillSet = resourceIdSkillMap.get(resId);
                        System.debug('resId===>'+resId+'====>'+resSkillSet);
                        System.debug('requestWrap.skills===>'+skills);
                          
                        for(String skillFromWrap : skills) {
                            if(!resSkillSet.contains(skillFromWrap)) {
                                foundAllSkills = false;
                            }
                        }
                        System.debug('foundAllSkills===>'+foundAllSkills);
                        if(foundAllSkills) {
                            availability = 'Yes';
                            break;
                        }
                    }
                }
            }
        }
        System.debug('availabilityCheck!--->'+availability);
        return availability;
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
}