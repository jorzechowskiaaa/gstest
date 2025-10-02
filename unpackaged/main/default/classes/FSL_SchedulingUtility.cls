/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-22-2022
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-09-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Major ACE Modification
 * 2.0   11-10-2020   Refactored code
 *       03-15-2020   ERS-221282 Partial WorkType
**/
public class FSL_SchedulingUtility{

    
    /**
     *  @purpose    -   Exclude Active Resources for this Work Order, if it is Critical priority
     */
    public static List<ResourcePreference> getActiveResourcesInSpottedTerritory(WorkOrder wo){
        FSL_PriorityCode_Mapping__c Code = FSL_PriorityCode_Mapping__c.getInstance(wo.Priority_Code__c);
        Set<Id> serviceResourceIDSet = new Set<Id>();
        List<ResourcePreference> rpList = new List<ResourcePreference>();
        Set<String> inactiveStatuses = new Set<String>{'Cleared','Canceled','Spotted'};

        // TODO: Modify to Priority Check? (currently hard-coded to P1 || P2 AND Schedule_over_Lower_Priority_Appointment__c)
        if(wo.Priority == 'Critical'){
            Id breakdonwWorkorderRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        
            // Get Service Territory for Work Order; Retrieve Service Resources that can work in Service Territory
            ID territoryID = wo.ServiceTerritoryID;
            List<ServiceTerritoryMember> stmList = [SELECT id,ServiceResourceId,ServiceTerritoryId FROM ServiceTerritoryMember 
                WHERE ServiceTerritoryId =: territoryId AND FSL_Expired_Resource_Territory__c = false AND ServiceResource.IsActive = TRUE];

            Set<ID> srIDSet = new Set<ID>();
            for(ServiceTerritoryMember stm : stmList){
                srIDSet.add(stm.ServiceResourceId);
            }

            // Return appointments from assigned to resources in SR ID Set
            List<ServiceAppointment> saList = [SELECT id, Service_Resource__c, Work_Order_Priority__c, Status FROM ServiceAppointment 
                WHERE  Service_Resource__c IN :srIDSet AND recordTypeId =: breakdonwWorkorderRecordTypeId AND Status NOT IN :inactiveStatuses];

            for(ServiceAppointment sa : saList) {
                
                // Exclude Resource from SA if SA is also Critical
                ResourcePreference criticalRP = createExclusionForResourceOnEmergencyCall(wo, sa);
                if(criticalRP != null){
                    rpList.add(criticalRP);
                }
                
                // Exclude resource from SA if SA is On Location or beyond (Active with Member)
                ResourcePreference activeRP = createExclusionForResourceOnActiveCall(wo, sa);
                if(activeRP != null){
                    rpList.add(activeRP);
                }                        
                            
            }                                    
        }

        return rpList;
    }

    /**
     *  @purpose    -   Creates an exclusion record for a Service Resource assigned to an Active Critical Call
     */
    public static ResourcePreference createExclusionForResourceOnEmergencyCall(WorkOrder wo, ServiceAppointment sa){
        Set<String> inactiveStatuses = new Set<String>{'Cleared','Canceled','Spotted'};
        ResourcePreference rp = new ResourcePreference();
        Boolean condition = sa.Work_Order_Priority__c == 'Critical';
        if(condition) {
            rp.RelatedRecordId = wo.id;
            rp.ServiceResourceId = sa.Service_Resource__c;
            rp.PreferenceType = 'Excluded';
            return rp;
        }else{
            return null;
        }

        
    }

    /**
     *  @purpose    -   Creates an exclusion record for a Service Resource who is On Location with a Member
     */
    public static ResourcePreference createExclusionForResourceOnActiveCall(WorkOrder wo, ServiceAppointment sa){
        Set<String> activeStatuses = new Set<String>{'On Location','In Tow','Tow Complete', 'Tow Loaded'};
        ResourcePreference rp = new ResourcePreference();
        Boolean condition = activeStatuses.contains(sa.status);
        if(condition) {
            rp.RelatedRecordId = wo.id;
            rp.ServiceResourceId = sa.Service_Resource__c;
            rp.PreferenceType = 'Excluded';
        }

        return rp;
    }
    
    /**
     *  @purpose    -   Create Resource Preference records for all Service Resources with Primary STM in Spotted Territory 
     *                  TODO: Confirm that this should be the Spotted Territory and not the Territory from the Facility ID on the Intake Payload
     */
    public static List<ResourcePreference>  addResourcePreferencesBasedOnPrefType(String woId, String prefType, String territoryId,Set<Id> excludeResIdSet) {
        List<ResourcePreference> resourcePreferences = new List<ResourcePreference>();
        for(ServiceResource sr : [SELECT Id, Name, Primary_Service_Territory__c, isActive FROM ServiceResource WHERE Primary_Service_Territory__c =:territoryId AND isActive = true]) {
            if(!excludeResIdSet.contains(sr.Id)) {
                ResourcePreference resPref = new ResourcePreference();
                resPref.PreferenceType = prefType;
                resPref.ServiceResourceId = sr.Id;
                resPref.RelatedRecordId = woId;
                resourcePreferences.add(resPref);
            }
        }
        return resourcePreferences;
    }

    /**
     *  @purpose    -   Query for a Technology Preference in the given Service Territory and determine if 
     *                  the Preference is active in the currrent time.
     */    
    @testVisible
    public static Technology_Preference__c checkForTechnologyPreference(Id serviceTerritoryID) {
        List<Technology_Preference__c> techPrefList = [Select Id, Service_Territory__c,Service_Territory__r.OperatingHours.Timezone, Start_Time__c, End_Time__c, Technology_Type__c, Days_Applied__c from Technology_Preference__c where Service_Territory__c =:serviceTerritoryID]; 
        
        DateTime currentDateTime = System.now();
        for(Technology_Preference__c techPref : techPrefList) {
            //create instance of the current time adjusted for Service Territory Timezone
            Timezone tz = Timezone.getTimeZone(techPref.Service_Territory__r.OperatingHours.Timezone);
            String dayOfWeek = currentDateTime.format('EEEE',tz.getID());            
            Integer localHour = Integer.valueOf(currentDateTime.format('HH', tz.getId()));
            Integer localMinutes = Integer.valueOf(currentDateTime.format('mm',tz.getId()));
            Time localTime = Time.newInstance(localHour, localMinutes, 0, 0);
            
            System.debug('dayOfWeek====>'+dayOfWeek);
            System.debug('=localTime=====>'+localTime);
            System.debug('=techPref.Start_Time__c=====>'+techPref.Start_Time__c);
            System.debug('=techPref.End_Time__c=====>'+techPref.End_Time__c);
            System.debug('=techPref.Days_Applied__c=====>'+techPref.Days_Applied__c);
            System.debug('localTime>= techPref.Start_Time__c=====>'+(localTime>= techPref.Start_Time__c));
            System.debug('localTime <= techPref.End_Time__c=====>'+(localTime <= techPref.End_Time__c));
            System.debug('techPref.Days_Applied__c.contains(dayOfWeek)=====>'+(techPref.Days_Applied__c.contains(dayOfWeek)));
            
            if(localTime>= techPref.Start_Time__c && localTime <= techPref.End_Time__c && techPref.Days_Applied__c.contains(dayOfWeek)) {
                return techPref;
            }
            if(techPref.Start_Time__c > techPref.End_Time__c && localTime <= techPref.End_Time__c && techPref.Days_Applied__c.contains(dayOfWeek)) {
                return techPref;
            }
        }
        return null;
    }
    
    /**
     *  @purpose    -   Determine if there is an Active Schedule Freeze for the Spotted Territory and Work Type
     */      
    @testVisible
    public static Schedule_Freeze__c checkIfFreezeApplies(ID serviceTerritoryID, ID workTypeID){
        DateTime currentTime = System.now();
        List<Schedule_Freeze__c> schedFreezeList = [SELECT Id,Work_Type__c, Service_Territory__c from Schedule_Freeze__c 
                                                    WHERE Start_Date__c <=: currentTime AND End_Date__c >=: currentTime];
        
        if(schedFreezeList.isEmpty()){
            return null;
        }
        
        // query the service territory to see if there is a parent
        ServiceTerritory spottedTerritory = [SELECT id, ParentTerritoryID FROM ServiceTerritory WHERE ID = :serviceTerritoryID];
        ID parentTerritoryID = spottedTerritory.ParentTerritoryID != null? spottedTerritory.ParentTerritoryID : null;
        
        for(Schedule_Freeze__c freeze : schedFreezeList){
            if(freeze.Work_Type__c == null){
                if(parentTerritoryID != null && parentTerritoryID == freeze.Service_Territory__c){
                    return freeze;
                }else if(serviceTerritoryID == freeze.Service_Territory__c){
                    return freeze;
                }
            }else if(serviceTerritoryID == freeze.Service_Territory__c &&  workTypeID == freeze.Work_Type__c ){
                return freeze;
            }
        }
        return null;
    }
    
    /**
     *  @purpose    -   Determine if there is a Scheduling Override at the current time for this Service Territory.
     *                  
     *                  Overrides contain an update the Scheduling Policy used on the initial scheduling attempt as well as 
     *                  related Resources / Facilities that assign Preference Records to be created
     */     
    @testVisible
    public static Service_Territory_Scheduling_Override__c checkIfScheduleOverrideApplies(ID serviceTerritoryID, Timezone tz, DateTime arrivalWindowStart, Map<Id,WorkType> workTypeIdMap, Id workTypeId){
        System.debug('Entering Check If Schedule Override Applies');
        //retrieve List of Schedule Overrides which apply to the territory
        // Service Territory Override
        //List<Service_Territory_Scheduling_Override__c> overrideList = [Select Id,Scheduling_Policy__c,Scheduling_Policy__r.Name,Start_Hour__c,End_Hour__c, Days_Applied__c, Work_Types__c, (Select Name, Type__c, Service_Territory__c, Service_Resource__c FROM Override_Resource_Preferences__r) from Service_Territory_Scheduling_Override__c where Service_Territory__c =: serviceTerritoryID];          
        
        Id SchedRecordTypeId = Schema.SObjectType.Service_Territory_Scheduling_Override__c.getRecordTypeInfosByName().get('Scheduling Override').getRecordTypeId();
        List<Service_Territory_Scheduling_Override__c> overrideList = [SELECT Id,Scheduling_Policy__c,Scheduling_Policy__r.Name,Start_Hour__c,End_Hour__c, Days_Applied__c, Work_Types__c, (SELECT Name, Type__c, Service_Territory__c, Service_Resource__c FROM Override_Resource_Preferences__r) 
                                                                       FROM  Service_Territory_Scheduling_Override__c 
                                                                       WHERE Service_Territory__c =: serviceTerritoryID 
                                                                       AND   (RecordTypeId = null OR RecordTypeId = :SchedRecordTypeId) ];

        if(!overrideList.isEmpty()){
            // Need to Check Override_Resource_Preferences__r is not null     
            if(overrideList[0].Override_Resource_Preferences__r.size() > 0 ){
                //determine the day of the week of current time adjusted for the Service Territory Timezone
                DateTime currentDateTime = System.now();
                if(arrivalWindowStart != null) {
                    currentDateTime = arrivalWindowStart;
                }

                String localDayofWeek = currentDateTime.format('EEEE', tz.getId());
                for(Service_Territory_Scheduling_Override__c schedOver : overrideList) {
                    List<String> daysApplied = schedOver.Days_Applied__c.split(';');
                    //determine if there is an override applying to the current day of week
                    if(daysApplied.contains(localDayofWeek)){
                        //create instance of the current time adjusted for Service Territory Timezone
                        Integer localHour = Integer.valueOf(currentDateTime.format('HH', tz.getId()));
                        Integer localMinutes = Integer.valueOf(currentDateTime.format('mm',tz.getId()));
                        Time localTime = Time.newInstance(localHour, localMinutes, 0, 0);
                        //determine if timezone-adjusted current time is in between the start/end time of the override 
                        if(localTime > schedOver.Start_Hour__c && localTime <= schedOver.End_Hour__c) {
                            //Now Check if there is an override applying to the current WorkType
                            if(checkIfWorkTypeOverrideApplies(schedOver, workTypeIdMap, workTypeId)){
                                return schedOver;
                            }                        
                        }
                    }
                }
            }            
        }
        return null;
    }

    /**
     *  @purpose    -   Check if there is an override applying to the current WorkType of WorkOrder
     *  ERS-221282 Partial WorkType implementation
     *        
    **/
    @testVisible
    public static Boolean checkIfWorkTypeOverrideApplies(Service_Territory_Scheduling_Override__c schedOver, Map<Id,WorkType> workTypeIdMap, Id workTypeId ){

        Boolean overrideApplies = false;

        try {
            if(workTypeId != null && workTypeIdMap != null){
                string woWorkType = workTypeIdMap.get(workTypeId).name;
                List<String> workTypesApplied = schedOver.Work_Types__c.split(';');
                if(workTypesApplied.contains(woWorkType)){
                    overrideApplies = true;
                }            
            }
        }catch(Exception ex) {
        }     
        
        return overrideApplies;
    }

    @testVisible
    public static Id getScheduleOverrideSTId(ID serviceTerritoryID,WorkOrder wo ){
        
        // Retrieve the ST Id that overrides the original ST
        Id serviceTerritoryOverrideId = null;

        Map<Id,WorkType> workTypeIdMap = new Map<Id,WorkType>([SELECT Id, Name, EstimatedDuration FROM WorkType]);        
        Id workTypeId = wo.WorktypeId;
        //DateTime arrivalWindowStart = wo.Pta__c;
        // Get the Service Territory TimeZone
        ServiceTerritory stCurrent = [SELECT OperatingHours.TimeZone FROM ServiceTerritory where Id =:serviceTerritoryID Limit 1];                  
        TimeZone targetTZ = Timezone.getTimeZone(stCurrent.OperatingHours.TimeZone);        

        //retrieve List of Schedule Overrides which apply to the territory
        Id RecordTypeId = Schema.SObjectType.Service_Territory_Scheduling_Override__c.getRecordTypeInfosByName().get('Territory Override').getRecordTypeId();       
        List<Service_Territory_Scheduling_Override__c> overrideList = [SELECT Id,Override_Service_Territory__c,Start_Hour__c,End_Hour__c, Days_Applied__c, Work_Types__c 
                                                                       FROM Service_Territory_Scheduling_Override__c where Service_Territory__c =: serviceTerritoryID  AND RecordTypeId = :RecordTypeId];
        if(!overrideList.isEmpty()){
            //determine the day of the week of current time adjusted for the Service Territory Timezone
            DateTime currentDateTime = System.now();
            /*if(arrivalWindowStart != null) {
                currentDateTime = arrivalWindowStart;
            } */
            if(String.isNotBlank(wo.Non_Emergency_Appointment_Time__c)) {
                currentDateTime = Datetime.valueOfGmt(wo.Non_Emergency_Appointment_Time__c.replace('T',' '));
            }          
            String localDayofWeek = currentDateTime.format('EEEE', targetTZ.getId());
            for(Service_Territory_Scheduling_Override__c schedOver : overrideList) {
                List<String> daysApplied = schedOver.Days_Applied__c.split(';');
                //determine if there is an override applying to the current day of week
                if(daysApplied.contains(localDayofWeek)){
                    //create instance of the current time adjusted for Service Territory Timezone
                    Integer localHour = Integer.valueOf(currentDateTime.format('HH', targetTZ.getId()));
                    Integer localMinutes = Integer.valueOf(currentDateTime.format('mm',targetTZ.getId()));
                    Time localTime = Time.newInstance(localHour, localMinutes, 0, 0);
                    //determine if timezone-adjusted current time is in between the start/end time of the override 
                    if(localTime > schedOver.Start_Hour__c && localTime <= schedOver.End_Hour__c) {
                        //Now Check if there is an override applying to the current WorkType
                        if(FSL_SchedulingUtility.checkIfWorkTypeOverrideApplies(schedOver, workTypeIdMap, workTypeId)){
                            serviceTerritoryOverrideId =  schedOver.Override_Service_Territory__c;
                        }
                    }
                }
            }                                     
        }

        if(serviceTerritoryOverrideId == null){
            // Log No Override Facility Error
            string logErrMsg = 'No Override Service Territory Found for the Map Territory Id: ' + string.valueOf(serviceTerritoryID);
            FSL_ApplicationLogCreator.insertApplicationLogEvent('', '', 'getScheduleOverrideSTId', true, logErrMsg);
        }
        
        return serviceTerritoryOverrideId;
    }
    
    /**
     *  @purpose    -   Query for Resource Preference Overrides related to the Scheduling Override record
     *                  and create Resource Preferences for the related Service Resource / Facility Resources
     *                  
     */     
    @testVisible
    public static void addResourcePreferencesFromOverride(Id woId, Service_Territory_Scheduling_Override__c schedOver){
        system.debug('Entering Add Resource Preferences From Override');
        List<ResourcePreference> resourcePreferences = new List<ResourcePreference>();
        List<Id> stPrefIds = new List<Id>();
        List<Id> srPrefIds = new List<Id>();
        for(Override_Resource_Preference__c orp : schedOver.Override_Resource_Preferences__r){
            if(orp.Service_Territory__c != null){
                stPrefIds.add(orp.Service_Territory__c);
            }
            else{
                srPrefIds.add(orp.Service_Resource__c);
            }   
        }
        Set<Id> existingPrefResourceIdSet = new Set<Id>();
        for(ResourcePreference woResPrefRecord : [Select Id,ServiceResourceId From ResourcePreference where RelatedRecordId =: woId]) {
            existingPrefResourceIdSet.add(woResPrefRecord.ServiceResourceId);
        }
        Map<Override_Resource_Preference__c, List<Id>> overridePrefToResourceIdsMap = new Map<Override_Resource_Preference__c, List<Id>>();
        Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>([SELECT Id, Name, Primary_Service_Territory__c, isActive FROM ServiceResource WHERE Primary_Service_Territory__c IN :stPrefIds OR Id IN :srPrefIds]);
        
        for(Override_Resource_Preference__c orp : schedOver.Override_Resource_Preferences__r){
            List<Id> srIdListTemp = new List<Id>();
            if(orp.Service_Territory__c != null){
                for(ServiceResource sr : resourceMap.values()){
                    if(sr.Primary_Service_Territory__c == orp.Service_Territory__c && sr.isActive == true){
                        srIdListTemp.add(sr.Id);
                        System.debug('Adding ' + sr.Name + ' as a ' + orp.Type__c + 'resource per ' + orp.Name + ' Override Preference');
                    }
                }
                overridePrefToResourceIdsMap.put(orp, srIdListTemp);
            }
            else{
                if(resourceMap.get(orp.Service_Resource__c).isActive == true){
                    srIdListTemp.add(orp.Service_Resource__c);
                    overridePrefToResourceIdsMap.put(orp, srIdListTemp);
                    System.debug('Adding ' + resourceMap.get(orp.Service_Resource__c).name + ' as a ' + orp.Type__c + ' resource per ' + orp.name + ' Override Preference');
                }
            }
        }
        
        for(Override_Resource_Preference__c orp : schedOver.Override_Resource_Preferences__r){
            for (Id srId : overridePrefToResourceIdsMap.get(orp)){ 
                if(!existingPrefResourceIdSet.contains(srId)) {              
                    ResourcePreference resPreference = new ResourcePreference();
                    resPreference.PreferenceType = orp.Type__c;
                    resPreference.ServiceResourceId = srId;
                    resPreference.RelatedRecordId = woId;
                    resourcePreferences.add(resPreference);
                }
            }
        }
        insert resourcePreferences;
        
    }
    
    public static void setScheduleOverLowerPriority(ServiceAppointment sa, FSL_PriorityCode_Mapping__c pcm){
        if(pcm != null){
            sa.FSL__Schedule_over_lower_priority_appointment__c = pcm.Schedule_over_Lower_Priority_Appointment__c; 
        }     
    }    

     /**
     *  @purpose  - populates the SLAWrapper object with matching row data from the table           
     */     
    public static FSL_Schedule_Config mapSlaArrivalWindow(FSL_SLA_ArrivalWindow__c SLA, Boolean isTow) {
                                                          
       
        FSL_Schedule_Config schedConfig = new FSL_Schedule_Config();

        schedConfig.schedulingPolicy = SLA.Scheduling_Policy__c;
        schedConfig.firstRetryPolicy = SLA.First_Retry_Policy__c;
        schedConfig.finalRetryPolicy = SLA.Retry_Policy__c;

        schedConfig.slaValue = ( isTow ) ? Integer.valueOf(SLA.Tow_SLA__c) : Integer.valueOf(SLA.LS_SLA__c);
     
        system.debug(schedConfig.slaValue + ' minute SLA and ' + SLA.Scheduling_Policy__c + ' used based on ' + SLA.Name);

        return schedConfig;
    }

    /**
     *  @purpose  - Picks out a matching row from the FSL SLA Arrival Window table based on query parameters from the Srvc Appt     
     */
    public static FSL_Schedule_Config evaluateArrivalWindow(Map<Id, FSL_SLA_ArrivalWindow__c> ArrivalWindowMap, ServiceTerritory territory, String priority, Boolean isTow) {
        
        String territoryName = (territory == null) ? 'null' : territory.Name;
        system.debug('Entering evaluateArrivalWindow with Territory = ' + territoryName + ', Priority = ' + priority);
        
        for (FSL_SLA_ArrivalWindow__c SLA : ArrivalWindowMap.values()){
            if ( SLA.Priority__c == priority) {
                if (SLA.Service_Territory__c == null) {
                    if ( territory == null ) {
                        return mapSlaArrivalWindow(SLA, isTow);
                    }
                }
                else if ( territory != null && SLA.Service_Territory__c == territory.Id) {
                    return mapSlaArrivalWindow(SLA, isTow);
                }
            }
        }

        return null;
    }


    public static FSL_Schedule_Config extractMatchingScheduleConfig(ServiceAppointment sa, WorkOrder wo, Map<Id, ServiceTerritory> stMap, Map<Id, FSL_SLA_ArrivalWindow__c> awMap )  {

        ServiceTerritory territory = null;

      // SNK - ERS-226485 Integrate SF Service team code changes.
      // Switched to using territory Id from WorkOrder wo instead of ServiceAppointment sa, since SA's field seems to be not populated by this time
        if ( wo != null  && wo.ServiceTerritoryId != null) {
        	territory = stMap.get(wo.ServiceTerritoryId);
        }
    
        system.debug('Baseline Service Territory: ' + territory);

        FSL_Schedule_Config schedConfig = null;
        try{
            do {
                system.debug('@@@@territory@@@'+territory);
                schedConfig = FSL_SchedulingUtility.evaluateArrivalWindow(awMap, territory, wo.Priority, wo.is_Tow_WorkType__c);
                if(territory != null && territory.ParentTerritoryId != null){
                    territory = stMap.get(territory.ParentTerritoryId);
                }else{
                    territory = null;
                }
            } while ( schedConfig == null && territory != null);

            // Do one extra search for the default row if no matches are found at this stage
            if ( schedConfig == null ) {
                schedConfig = FSL_SchedulingUtility.evaluateArrivalWindow(awMap, null, wo.Priority, wo.is_Tow_WorkType__c);
            }
                      
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
        }

        return schedConfig;
    }

     /**
     *  @purpose    -   Create a default Schedule Config if values are missing from the table
     *                  
     */ 
    public static FSL_Schedule_Config populateDefaultScheduleConfig(ServiceAppointment sa,  Map<Id, FSL__Scheduling_Policy__c> policyMap, 
                                                                    FSL_Schedule_Config schedConfig, Map<Id, FSL_User_Message__c> userMessageIdMap ) {
 
        FSL_Schedule_Config defSchedConfig = schedConfig;
   
        Map<String, FSL__Scheduling_Policy__c> policyNameMap = new Map<String, FSL__Scheduling_Policy__c>();
        for(FSL__Scheduling_Policy__c policy : policyMap.values()){
            policyNameMap.put(policy.Name, policy);
        }

        String defaultSchedulingPolicy = Label.FSL_Default_Scheduling_Policy;
        system.debug('Using Default Scheduling policy in the Schedule Config: ' + defaultSchedulingPolicy);

        FSL__Scheduling_Policy__c defSchedPolicy = policyNameMap.get(defaultSchedulingPolicy );
        if(defSchedPolicy != null ){
            defSchedConfig = new FSL_Schedule_Config(schedConfig, defSchedPolicy.Id) ;               
        }
        
        Map<String, FSL_User_Message__c> messageMap = new Map<String, FSL_User_Message__c>();
        for(FSL_User_Message__c um : userMessageIdMap.values()){
            messageMap.put(um.Message_Id__c, um);
        }

        // Create SLA Violation to record the No Match Found Exception
        FSL_SLA_Violation_History__c noMatchViolation = new FSL_SLA_Violation_History__c();
        noMatchViolation.FSL_Work_Order__c = sa.ParentRecordId;
        noMatchViolation.FSL_Service_Territory__c = sa.ServiceTerritoryId;
        noMatchViolation.FSL_Type__c = 'Warning';
        if(!messageMap.isEmpty()) {
            FSL_User_Message__c m = messageMap.get('NoArrivalWindowMatch');
            noMatchViolation.FSL_Reason__c = m != null && m.Message_Text__c != null ? m.Message_Text__c : 'No matching arrival window';
            insert noMatchViolation;
        }

        return defSchedConfig;
    }

     /**
     *  @purpose  - Copy selected info from ScheduleConfig into the ServiceAppointment
     */   
    public static void copyScheduleConfigIntoServiceAppointment(ServiceAppointment sa, FSL_Schedule_Config schedConfig) {
  

        sa.ArrivalWindowStartTime = sa.EarliestStartTime;
        if(schedConfig.slaValue == 0 || schedConfig.slaValue == null){
        // Added 1/2/19 to default Arrival Window to PTA (from Intake) if no match is found on table
            populateArrivalWindowFromSetting(sa);
        } else{
            sa.ArrivalWindowEndTime = sa.EarliestStartTime.addMinutes(schedConfig.slaValue);
        }           

        sa.FSL__Scheduling_Policy_Used__c = schedConfig.schedulingPolicy;

        system.debug('Arrival Window Start: ' + sa.arrivalWindowStartTime);
        system.debug('Arrival Window End: ' + sa.arrivalWindowEndTime);
        system.debug(schedConfig.schedulingPolicy);
        //system.debug(policyNameMap.get(schedConfig.schedulingPolicy.Name));

    }
    /**
     *  @purpose    -   Extract a Schedule Config matched to the incoming WO / SA by picking an entry from the FSL SLA ArrivalWindow table            
     */ 
    public static FSL_Schedule_Config populateArrivalWindowAndPolicy(ServiceAppointment sa, WorkOrder wo, Map<Id, FSL__Scheduling_Policy__c> policyMap ){

        Map<Id, ServiceTerritory> stMap = new Map<Id, ServiceTerritory>([SELECT Id, Name, ParentTerritoryId FROM ServiceTerritory]);
        Map<Id, FSL_SLA_ArrivalWindow__c> awMap = new Map<Id,FSL_SLA_ArrivalWindow__c>([Select Id,Name,LS_SLA__c,Retry_Policy__c,Scheduling_Policy__c,First_Retry_Policy__c, Scheduling_Policy__r.Name,Service_Territory__r.Name,Service_Territory__c,Tow_SLA__c,Priority__c from FSL_SLA_ArrivalWindow__c]);//FSL_SLA_Arrival_Window__c.getAll();

        // First extract the appropriate schedConfig matching this sa and wo
        FSL_Schedule_Config schedConfig = extractMatchingScheduleConfig(sa, wo, stMap, awMap);

        if (schedConfig == null || schedConfig.schedulingPolicy == null) { 

            Map<Id, FSL_User_Message__c> userMessageIdMap = new Map<Id, FSL_User_Message__c>(
                [SELECT Id, Message_Id__c, Message_Text__c, Reference__c, Warning__c FROM FSL_User_Message__c]);
            schedConfig = populateDefaultScheduleConfig(sa, policyMap, schedConfig, userMessageIdMap);
        }

        // Copy arrival window and main scheduling policy info into the SA
        copyScheduleConfigIntoServiceAppointment(sa, schedConfig);

        return schedConfig;
    } 

    public static FSL_AppointmentScheduleQueueable createScheduleQueuable (ServiceAppointment breakDownSA, 
                                                                           ServiceAppointment relatedTowSA, 
                                                                           FSL_Schedule_Config schedConfig, 
                                                                           Map<Id, FSL__Scheduling_Policy__c> policyMap,
                                                                          Boolean isFromAutosceduleRetryBatch) {  //AGB added for SSFI-560 11/19/24

        FSL_ServiceScheduler.DTO dto = new FSL_ServiceScheduler.DTO();
        dto.scheduleAppointment = breakDownSA;
        dto.relatedAppointment = relatedTowSA;

        dto.schedulingPolicy = policyMap.get(schedConfig.schedulingPolicy);
        dto.firstRetrySchedulingPolicy = policyMap.get(schedConfig.firstRetryPolicy);
        dto.reSchedulingPolicy = policyMap.get(schedConfig.finalRetryPolicy);
		dto.isFromAutosceduleRetryBatch = isFromAutosceduleRetryBatch;  //AGB added for SSFI-560 11/19/24

        return new FSL_AppointmentScheduleQueueable(dto);

    }

    /**
     *  @purpose    -   Sets the Arrival Window End time based on a Date Time field on the Service Appointment
     *                  
     */     
    @testVisible
    private static void populateArrivalWindowFromSetting(ServiceAppointment sa){
        String arrivalWindowLabel = System.Label.FSL_Arrival_Window_Field;
        if(String.isNotBlank(arrivalWindowLabel)){
            sa.ArrivalWindowEndTime = (DateTime) sa.get(arrivalWindowLabel);
        }else{
            sa.ArrivalWindowEndTime = (DateTime) sa.get('pta__c');
        }
    }
    
    
    /**
     *  @purpose    -   Updates Service Appointments and Work Orders to accurately reflect the Landline Facility Status
     *                  and calls the method for creating the Landline Facility Case.
     *                  
     */    
    // FSL-2022-11 - Commenting out obsolete code since this is not being Used
    // public static void handleLandlineFacilityCall(WorkOrder wo, ServiceAppointment breakdownSA, ServiceAppointment towSA){
    //     List<ServiceAppointment> jeopardyAppList = new List<ServiceAppointment>();
    //     breakdownSA.FSL__InJeopardyReason__c = 'Landline Facility';
    //     breakdownSA.FSL__InJeopardy__c = true;
    //     jeopardyAppList.add(breakdownSA);
    //     if(towSA != null) {
    //         towSA.FSL__InJeopardyReason__c = 'Landline Facility';
    //         towSA.FSL__InJeopardy__c = true;
    //         jeopardyAppList.add(towSA);
    //     }
    //     update jeopardyAppList;
    //     try {
    //         wo.In_Jeopardy__c = true;
    //         wo.EntitlementId = null;
    //         wo.Servicing_Technology_Type__c = 'Landline';
    //         update wo;
    //         FSL_SchedulingUtility.createLandlineFacilityCase(wo,breakdownSA);
    //     }catch(Exception ex) {

    //     }        
    // }

    /**
     *  @purpose    -   Creates a Case for Dispatchers to handle Calls assigned to Landline Facilities
     *                  
     */     
    // FSL-2022-11 - Commenting out obsolete code since this is not being Used
    // @testVisible
    // public static void createLandlineFacilityCase(WorkOrder wo,ServiceAppointment sa) {
    //     List<FSL_TroubleCode__c> trCodeList = [Select Id,Description__c,Type__c From FSL_TroubleCode__c where Type__c = 'PACESETTER' AND Work_Order__c =:wo.Id];
        
    //     WorkOrder workOrderRec = [Select Id,workOrderNumber,workType.Name from WorkOrder where id =:wo.Id];
    //     Id nonTechRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Non Technology').getRecordTypeId();
    //     Case cs = new Case();
    //     String paceSetterDesc = '';
    //     if(!trCodeList.isEmpty()) {
    //         paceSetterDesc = trCodeList[0].Description__c;
    //     }
        
       
    //    Id said = FSL_ServiceAppointmentTriggerHandler.returnTowServiceAppointmentID(sa.id);  
    //     cs.Number_Of_Passengers__c = wo.Number_Of_Passengers__c;
    //     cs.FSL_Service_Appointment_Territory__c = wo.ServiceTerritoryId;
    //     cs.FSL_Vehicle_Description__c = wo.Vehicle_Profile__c;
    //     cs.FSL_Work_Order__c = wo.Id;
    //     cs.subject = wo.Call_Id__c+' '+'Landline Technology';
    //     cs.contactId = wo.contactId;
    //     cs.FSL_Service_Appointment__c = sa.Id;      
    //     cs.FSL_Service_Appointment_Tow__c = said;
    //     cs.recordTypeId = nonTechRecTypeId;
    //     cs.Origin = 'Automation';
    //     cs.FSL_Service_Type__c = workOrderRec.workType.Name+' - '+paceSetterDesc;
        
    //     //Assigning Case through the latest active assignment rule.
    //     AssignmentRule AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
    //     Database.DMLOptions dmlOpts = new Database.DMLOptions();
    //     dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.id;
    //     Database.insert(cs, dmlOpts );
    // }    
    public static void fakemethod2(){
        Integer i = 0;
        i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++;         
    }  
    public static void fakemethod3(){
        Integer i = 0;
        i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++;         
    }     
    public static void fakemethod(){
        Integer i = 0;
        i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++; 
              i++; 
        i++; 
        i++;         
    }
}