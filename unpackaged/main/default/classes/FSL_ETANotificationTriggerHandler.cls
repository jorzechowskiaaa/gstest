/**
 * @File Name          : FSL_ETANotificationTriggerHandler.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 12-11-2020
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    1/14/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 *       12/02/2020   Clement Shiu  ERS-220415 - Optimization helper refractoring 
**/
public class FSL_ETANotificationTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<ETA_Notification__e> newList = Trigger.new;
    List<ETA_Notification__e> oldList = Trigger.old;
    Map<Id, ETA_Notification__e> newMap = (Map<Id, ETA_Notification__e>)Trigger.newMap;
    Map<Id, ETA_Notification__e> oldMap = (Map<Id, ETA_Notification__e>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ETA_Notification__e');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        handlePlatformETANotifications(newList);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    public static void handlePlatformETANotifications(List<ETA_Notification__e> notificationList){
        try{ 
            map<String, ETA_Notification__e> mapAppointmentNumberToEvent = new map<String, ETA_Notification__e>();
            map<ID, ETA_Notification__e> mapResourceIDsToEvent = new map<ID, ETA_Notification__e>();
            map<ETA_Notification__e, ID> mapEventToRSOResourceID = new map<ETA_Notification__e, ID>();
            map<ETA_Notification__e, List<String>> mapEventToterritoryIdList = new map<ETA_Notification__e, List<String>>();
            Map<ETA_Notification__e, ServiceAppointment> platformEventToSAMap = new Map<ETA_Notification__e, ServiceAppointment>();
            Map<ServiceAppointment, List<ServiceAppointment>> saToSAListMap = new Map<ServiceAppointment, List<ServiceAppointment>>();
            Id towRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
            Map<Id,Id> rsIdAbsenceIdMap = new Map<Id,Id>();
            Integer stackedCallThresholdCount;
            Map<ID, Integer> srToTimeDeltaMap = new Map<ID, Integer>();
            map<ETA_Notification__e, Wrapper> mapEventToChange = new map<ETA_Notification__e, Wrapper>();
            // TODO: Add logic so this will also work for Events related to Resource Absences
            for(ETA_Notification__e etaNotice : notificationList){

                if(etaNotice.Appointment_Number__c != null) {
                    mapAppointmentNumberToEvent.put(etaNotice.Appointment_Number__c, etaNotice);
                }
                //when service resource is available the SA is not passed to this notification as input
                System.debug('=etaNotice.Service_Resource_Id__c====>'+etaNotice.Service_Resource_Id__c);
                if(etaNotice.Service_Resource_Id__c != null) {
                    mapResourceIDsToEvent.put(etaNotice.Service_Resource_Id__c, etaNotice);
                    System.debug('etaNotice.Resource_Absence_Id__c===>'+etaNotice.Resource_Absence_Id__c);
                    if(etaNotice.Resource_Absence_Id__c != null) {
                        rsIdAbsenceIdMap.put(etaNotice.Service_Resource_Id__c,etaNotice.Resource_Absence_Id__c);
                    }
                }                                             
            }
            System.debug('=resourceIDs====>'+mapResourceIDsToEvent.keySet());
            // Get additional data about updated SAs by using the SA# from the Platform Event
            if(!mapAppointmentNumberToEvent.isEmpty()){
                List<ServiceAppointment> saQueryList = [
                    SELECT SchedStartTime, Schedule_Delta__c, Address_Changed__c, Service_Resource__r.Name, FSL_Needs_Address__c, Technician_Schedule_Override_Counter__c, 
                           SchedEndTime, Duration, RecordTypeId, AppointmentNumber, Address_Change_Counter__c, ParentRecordId
                    FROM ServiceAppointment
                    WHERE AppointmentNumber IN :mapAppointmentNumberToEvent.keyset()
                ];

                if (!saQueryList.isEmpty()) {
                    for(ServiceAppointment sa : saQueryList){
                        for(ETA_Notification__e evt : notificationList){
                            // add map of Platform Event to Service Appointment
                            if(sa.AppointmentNumber == evt.Appointment_Number__c){
                                platformEventToSAMap.put(evt, sa);
                                srToTimeDeltaMap.put(sa.Service_Resource__c, Integer.valueOf(evt.Time_Delta__c));
                            }       
                        }
                        // add all service resource ids of updated SAs to Set (for finding related appointments) 
                        mapResourceIDsToEvent.put(sa.Service_Resource__c, mapAppointmentNumberToEvent.get(sa.AppointmentNumber));  
                    }
                    saToSAListMap = createSAtoRelatedSAMap(mapResourceIDsToEvent.keyset(), saQueryList);
                }
            }
            system.debug('mapResourceIDsToEvent==>'+mapResourceIDsToEvent);
            // perform final updates on service appointments based on the maps created
            List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
            for(ETA_Notification__e etaNotice : notificationList){ 
                system.debug('**Interating for **'+etaNotice);
                ID RSOResourceID ;
                List<String> territoryIdList = new List<String>();
    
                stackedCallThresholdCount = oSettings.Stacked_Appointments_Count__c!=null ? Integer.valueOf(oSettings.Stacked_Appointments_Count__c) : 0;
                System.debug('=stackedCallThresholdCount====>'+stackedCallThresholdCount);

                List<ServiceAppointment> relatedAppointments = new List<ServiceAppointment>();
                ServiceAppointment sa = platformEventToSAMap.get(etaNotice);
                ServiceAppointment saToUpdate = new ServiceAppointment(Id = sa.Id);
                
                Decimal timeDelta;
                // get full SA detail from Platform Event Map
                // sa = platformEventToSAMap.get(etaNotice);
                if (etaNotice.ETA__c != null) {
                    saToUpdate.ETA__c = etaNotice.ETA__c;
                }
                
                if (etaNotice.Time_Delta__c != null) {
                    timeDelta = etaNotice.Time_Delta__c;
                }
                if (!saToSAListMap.isEmpty()) {
                    relatedAppointments = saToSAListMap.get(sa);
                }
                // updated related appointments (if platform event flag is true)
                if (etaNotice.Update_Related_Appointments__c) {
                    if(!saToSAListMap.isEmpty()){
                        //relatedAppointments = saToSAListMap.get(sa);
                        for(ServiceAppointment relatedSA : relatedAppointments){
                            // ensure the related appointment is still scheduled after the updated appointment
                            if(etaNotice.Original_Scheduled_Start__c == null || etaNotice.Original_Scheduled_Start__c <  relatedSA.SchedStartTime){
                                DateTime schedStart = relatedSA.SchedStartTime.addMinutes(Integer.valueOf(timeDelta));
                                DateTime schedEnd = relatedSA.SchedEndTime.addMinutes(Integer.valueOf(timeDelta));
                                Decimal counter = relatedSA.Technician_Schedule_Override_Counter__c == null? 1 : relatedSA.Technician_Schedule_Override_Counter__c+1;
                                ServiceAppointment addedSA = new ServiceAppointment(SchedStartTime = schedStart, SchedEndTime = schedEnd, Technician_Schedule_Override_Counter__c = counter, id = relatedSA.id);
                                saUpdateList.add(addedSA);
                            }
                        }
                    }
                }
    
                // update root appointment that started the whole transaction
                if(etaNotice.Update_Current_Appointment__c){           
                    saToUpdate.SchedStartTime = sa.SchedStartTime.addMinutes(Integer.valueOf(timeDelta));
                    saToUpdate.SchedEndTime = sa.SchedEndTime.addMinutes(Integer.valueOf(timeDelta));
                    saToUpdate.Technician_Schedule_Override_Counter__c = sa.Technician_Schedule_Override_Counter__c == null? 1 : sa.Technician_Schedule_Override_Counter__c+1;
                    
                    
                    //UAT UF-763
                    if(etaNotice.Type__c == 'Address Changed'){
                        // stacked call count for address change is alwasy 1
                        stackedCallThresholdCount = 1;
                        if(sa.Address_Changed__c){
                            saToUpdate.Address_Changed__c = false;
                        }
                        if(sa.RecordTypeId == towRecordTypeId && sa.FSL_Needs_Address__c){
                            saToUpdate.Duration = sa.Duration - Integer.valueOf(System.Label.FSL_Tow_Duration_Extension);
                            saToUpdate.SchedEndTime = sa.SchedEndTime.addMinutes(Integer.valueOf(System.Label.FSL_Tow_Duration_Extension) * -1);
                            saToUpdate.FSL_Needs_Address__c = false;
                        }
                        saToUpdate.Address_Change_Counter__c++;
                    }
                    
                    // reset schedule delta
                    saToUpdate.Schedule_Delta__c = 0;           
                    saUpdateList.add(saToUpdate);
                    
                } else {
                    if (sa != null && sa.Schedule_Delta__c != null && sa.Schedule_Delta__c > 0) {
                        saToUpdate.Schedule_Delta__c = 0;
                        saUpdateList.add(saToUpdate);
                    }

                }

                // stacked calls do not count when the type is an emergency overlap
                if('Resource Absence Overlap'.equals(etaNotice.Type__c) || 
                   'Emergency Assignment Overlap'.equals(etaNotice.Type__c) 
                  ){
                    stackedCallThresholdCount = 0;
                }

                //Run RSO
                if(etaNotice.Run_RSO__c){
                    if(!saToSAListMap.isEmpty()){
                        //relatedAppointments = saToSAListMap.get(sa);
                        Integer stackedCount = 0;
                        if(relatedAppointments != null) {
                            System.debug('relatedAppointments=====>'+relatedAppointments.size());
                            Set<String> parentWOIdSet = new Set<String>();
                            for(ServiceAppointment relatedSA : relatedAppointments){
                                if(sa.parentRecordId != relatedSA.parentRecordId) {
                                    parentWOIdSet.add(relatedSA.parentRecordId);
                                }
                            }
                            System.debug('parentWOId data===>'+parentWOIdSet+'===parentWOIdSet=====>'+parentWOIdSet.size());
                            if(parentWOIdSet.size() >= stackedCallThresholdCount) {
                                for(ServiceAppointment relatedSA : relatedAppointments){
                                    RSOResourceID = relatedSA.Service_Resource__c;
                                }
                            }
                            stackedCount = parentWOIdSet.size();
                        }  
                        //track the stacked calls for the resource
                        Wrapper wrap = new Wrapper();
                        wrap.StackedCalls = stackedCount;
                        mapEventToChange.put(etaNotice, wrap);                      
                    }else if(!string.isEmpty(etaNotice.Service_Resource_Id__c) ) {// this will have value when the PE is triggered with just resource and no SA
                        Map<String,Set<Id>> resIdWoSetMap = createSRtoRelatedWoMap(etaNotice.Service_Resource_Id__c, rsIdAbsenceIdMap);
                        if(stackedCallThresholdCount == 0 || (resIdWoSetMap.get(etaNotice.Service_Resource_Id__c) != null && resIdWoSetMap.get(etaNotice.Service_Resource_Id__c).size() >= stackedCallThresholdCount) ) {
                            RSOResourceID = etaNotice.Service_Resource_Id__c;
                        } 
                        //track the stacked calls for the resource
                        Wrapper wrap = new Wrapper();
                        wrap.StackedCalls = resIdWoSetMap.get(etaNotice.Service_Resource_Id__c)!=null ? resIdWoSetMap.get(etaNotice.Service_Resource_Id__c).size() : 0;                        
                        mapEventToChange.put(etaNotice, wrap);                                               
                    }
                    system.debug('RSOResourceID==>'+RSOResourceID);
                    if(!string.isEmpty(RSOResourceID)){
                        mapEventToRSOResourceID.put(etaNotice, RSOResourceID);
                    }
                }

                //Run InDay
                if(etaNotice.Run_InDay__c){
                    System.debug('etaNotice.Territory_Ids__c=====>'+etaNotice.Territory_Ids__c);
                    if(string.isEmpty(etaNotice.Territory_Ids__c)){                    
                        for(ServiceTerritoryMember stm : [Select Id,ServiceTerritoryId, ServiceResourceId 
                                                            from ServiceTerritoryMember 
                                                        where FSL_Expired_Resource_Territory__c = false And 
                                                                ServiceResourceId IN : mapResourceIDsToEvent.keyset()]) {
                            territoryIdList.add(stm.ServiceTerritoryId);
                        }   
                    }else{//run In Day when only terr are passed in the PE
                        territoryIdList.addAll(etaNotice.Territory_Ids__c.split(','));
                    }
                    mapEventToterritoryIdList.put(etaNotice, territoryIdList);                 
                }
            }        
            System.debug('saUpdateList=====>'+saUpdateList);
            //TODO: do not optimize the resource if the their primary terrioty is being optimized
            if(!saUpdateList.isEmpty()){
                update saUpdateList;

                //TODO: this may not be required as per the logic commented inside this method
                // check if resources with SA Updates have any new overlaps with Resource Absences
                Set<ID> resourcesWithNewOverlaps = checkForNewOverlaps(mapResourceIDsToEvent.keyset(), srToTimeDeltaMap);
                
                // add these resources to the RSO Resource Set
                set<ID> RSOResourceIDs = new set<ID>();
                RSOResourceIDs.addAll(mapEventToRSOResourceID.values());
                for(ID srid : resourcesWithNewOverlaps){
                    if(!RSOResourceIDs.contains(srid)){                        
                        mapEventToRSOResourceID.put(mapResourceIDsToEvent.get(srid), srid);
                    } 
                }
                
            }
            System.debug('Check InDay to Run=====>'+mapEventToterritoryIdList);
            if(mapEventToterritoryIdList!=null && !mapEventToterritoryIdList.isEmpty()){
                map<ETA_Notification__e, Id> mapEventToLogId = FSL_ApplicationLogCreator.createPlatFormEventLogger(notificationList, platformEventToSAMap, mapEventToterritoryIdList, null, mapEventToChange); 
                //InDay call
                for(ETA_Notification__e event :  mapEventToterritoryIdList.keyset()){
                    System.debug('InDay Run=====>');
                    //pass the log id for each iteration
                    FSL_OptimizationHelper.callInDayWithPrimarySeconderyTerritories(mapEventToterritoryIdList.get(event), mapEventToLogId.get(event));
                }
            }
            
            System.debug('Check RSO to Run=====>'+mapEventToRSOResourceID);
            map<String, Id> eventreplaytoResourceId = new map<String, Id>();
            for(ETA_Notification__e etan:mapEventToRSOResourceID.keyset()){
                eventreplaytoResourceId.put(etan.EventKey__c,mapEventToRSOResourceID.get(etan));
            }
            if(mapEventToRSOResourceID!=null && !mapEventToRSOResourceID.isEmpty()){
                map<ETA_Notification__e, Id> mapEventToLogId = FSL_ApplicationLogCreator.createPlatFormEventLogger(notificationList, platformEventToSAMap, null, mapEventToRSOResourceID, mapEventToChange); 
                
                map<Id, Id> resourceToLogId = new map<Id, Id>();
                for(ETA_Notification__e event : notificationList){
                  /*  if(mapEventToRSOResourceID.containskey(event)){
                        resourceToLogId.put(mapEventToRSOResourceID.get(event), mapEventToLogId.get(event));
                    }*/
                    if(eventreplaytoResourceId.containskey(event.EventKey__c)){
                        resourceToLogId.put(eventreplaytoResourceId.get(event.EventKey__c), mapEventToLogId.get(event));
                    }
                }
                set<ID> resIds = new set<ID>(mapEventToRSOResourceID.values());
                System.debug('RSO Run=====>'+mapEventToRSOResourceID);
                FSL_OptimizationHelper.optimizeScheduleOverlapsbulk(resIds, resourceToLogId);
            }            
            createAppLogforPE(notificationList, platformEventToSAMap, mapEventToterritoryIdList, mapEventToRSOResourceID, mapEventToChange);
            //FSL_ETANotificationTriggerHandler.insertPlatformEventLog(notificationList, platformEventToSAMap, saToSAListMap);
        }
        catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());

            if (EventBus.TriggerContext.currentContext().retries < 2) {
                // Condition isn't met, so try again later.
                throw new EventBus.RetryableException(
                     'Failure when updating the Service Appointment. Trying Again...');
            }
        }
        //DML operation Update not allowed
        //update notificationList;
    }

    /**
    * @description This method will see if there is any event that is not runnning RSO or InDay and log them 
    * @author Rajesh Kemisetti | 4/10/2020 
    * @param notificationList 
    * @param platformEventToSAMap 
    * @param mapEventToterritoryIdList 
    * @param mapEventToRSOResourceIDs 
    * @return void 
    **/
    public static void createAppLogforPE(List<ETA_Notification__e> notificationList, Map<ETA_Notification__e, ServiceAppointment> platformEventToSAMap, map<ETA_Notification__e, List<String>> mapEventToterritoryIdList, map<ETA_Notification__e,ID> mapEventToRSOResourceIDs, map<ETA_Notification__e, Wrapper> mapEventToChange){
        List<ETA_Notification__e> PENotificationList = new List<ETA_Notification__e> ();
        map<id, ETA_Notification__e> mapNotificationList = new map<id, ETA_Notification__e>(notificationList);
        set<ETA_Notification__e> InDayOrRSOEvents = new set<ETA_Notification__e>(); 
        if(!mapEventToterritoryIdList.isEmpty()){
            InDayOrRSOEvents.addAll(mapEventToterritoryIdList.keySet());
        }
        if(!mapEventToRSOResourceIDs.isEmpty()){
            InDayOrRSOEvents.addAll(mapEventToRSOResourceIDs.keySet());
        }

        //If non of the events were used for RSO or InDay
        if(InDayOrRSOEvents.isEmpty()){
            PENotificationList.addAll(notificationList);
        }else{
            //some of the events were used for RSO or InDay, so exclude them for the logging
            for(ETA_Notification__e event : mapNotificationList.Values()){
                if(!InDayOrRSOEvents.contains(event)){
                    PENotificationList.add(event);
                }
            }
        }
        FSL_ApplicationLogCreator.createPlatFormEventLogger(PENotificationList, platformEventToSAMap, null, null, mapEventToChange); 
    }
    /*public static void insertPlatformEventLog(List<ETA_Notification__e> notificationList, Map<ETA_Notification__e, ServiceAppointment> platformEventToSAMap, Map<ServiceAppointment, List<ServiceAppointment>> saToSAListMap){
        List<FSL_Application_Log__c> LstApplicationLog = new List<FSL_Application_Log__c>();
        for(ETA_Notification__e etaNotice : notificationList){        
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Operation__c = 'ETALog');
            appLog.Api_Name__c= etaNotice.Type__c;
            appLog.Request_Body__c   = JSON.serialize(etaNotice);
            if(platformEventToSAMap.ContainsKey(etaNotice)){
                appLog.Service_Appointment__c = platformEventToSAMap.get(etaNotice).Id;
                
                if(etaNotice.Update_Related_Appointments__c && saToSAListMap.containsKey(platformEventToSAMap.get(etaNotice))){
                    for(ServiceAppointment sa : saToSAListMap.get(platformEventToSAMap.get(etaNotice))){
                       FSL_Application_Log__c appLogRelated = new FSL_Application_Log__c();
                       appLogRelated.Api_Name__c = etaNotice.Type__c;
                       appLogRelated.Request_Body__c = JSON.serialize(etaNotice);
                       appLogRelated.Service_Appointment__c = sa.Id;
                       LstApplicationLog.add(appLogRelated);
                    }
                }
            }
            
            LstApplicationLog.add(appLog);
        }
        if(LstApplicationLog.size() > 0){
            insert LstApplicationLog;
        }        
    }*/
    
    public static Map<ServiceAppointment, List<ServiceAppointment>> createSAtoRelatedSAMap(Set<ID> resourceIDs, List<ServiceAppointment> saQueryList){
        Map<ServiceAppointment, List<ServiceAppointment>> saToSAListMap = new Map<ServiceAppointment, List<ServiceAppointment>>();
        
        // Get related SAs by looking at the same resource and filtering the start time by some horizon (now)
        DateTime scheduleStartHorizon = System.now().addHours(-6);
        List<ServiceAppointment> relatedServiceAppointments = [SELECT SchedStartTime, id, FSL__Pinned__c, Address_Changed__c, Service_Resource__c, 
                Technician_Schedule_Override_Counter__c, SchedEndTime,parentRecordId, AppointmentNumber, FSL__Related_Service__c
            FROM ServiceAppointment 
            WHERE (Service_Resource__c IN :resourceIDs 
            AND SchedStartTime > :scheduleStartHorizon 
            AND Status != 'Cleared' AND Status != 'Cancelled')];
        
        // Add map of Service Appointment to Related Appointments
        for(ServiceAppointment sa : saQueryList){
            List<ServiceAppointment> relatedSAs = new List<ServiceAppointment>();
            for(ServiceAppointment relatedSA : relatedServiceAppointments){
                // if the assigned resource is the same and the related service appointment is scheduled later
                if(sa.Service_Resource__c == relatedSA.Service_Resource__c && 
                    sa.SchedStartTime < relatedSA.SchedStartTime){
                    
                    // only add appointments that are not pinned to the update list
                    // unless the pinned appointment is part of a dependency for the SA that caused the Platform Event to be created
                    if(!relatedSA.FSL__Pinned__c || relatedSA.FSL__Related_Service__c == sa.id){
                        relatedSAs.add(relatedSA);
                    }

                    
                }
            }
            system.debug('Related Service Appointments impacted by ETA updated = ' + relatedSAs);
            if(!relatedSAs.isEmpty()) {
                saToSAListMap.put(sa, relatedSAs);
            }
        }
        
        return saToSAListMap;

    }

    public static Map<String,Set<Id>> createSRtoRelatedWoMap(ID resourceID,Map<Id,Id> rsIdAbsenceMap) {
        Map<String, Set<Id>> saToWoIdListMap = new Map<String, Set<Id>>();
        Id breakDownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        // Get related SAs by looking at the same resource and filtering the start time by some horizon (now)
        //DateTime scheduleStartHorizon = System.now().addHours(-6);
        DateTime currentTime = System.now();
        List<ServiceAppointment> relatedServiceAppointments = [SELECT SchedStartTime, id, FSL__Pinned__c, Address_Changed__c, Service_Resource__c, Technician_Schedule_Override_Counter__c, SchedEndTime,parentRecordId, AppointmentNumber 
            FROM ServiceAppointment WHERE Service_Resource__c = :resourceID AND SchedStartTime > :currentTime AND recordTypeId =:breakDownRecordTypeId AND FSL__Pinned__c = false AND Status != 'Cleared' AND Status != 'Cancelled'];
            Map<Id,ResourceAbsence> absensesMap = new Map<Id,ResourceAbsence>();
            for(ResourceAbsence rs : [Select Id,ResourceId,Start,End from ResourceAbsence where Id IN : rsIdAbsenceMap.values()]) {
                absensesMap.put(rs.ResourceId,rs);
            }
           // Add map of Service Appointment to Related Appointments
           for(ServiceAppointment relatedSA : relatedServiceAppointments){
            // if the assigned resource is the same and the related service appointment is scheduled later
            
            if(absensesMap.isEmpty() || (absensesMap.get(relatedSA.Service_Resource__c) != null && relatedSA.SchedStartTime > absensesMap.get(relatedSA.Service_Resource__c).start)) {            
                if(saToWoIdListMap.containsKey(relatedSA.Service_Resource__c)) {
                    saToWoIdListMap.get(relatedSA.Service_Resource__c).add(relatedSA.parentRecordId);
                }else {
                    saToWoIdListMap.put(relatedSA.Service_Resource__c,new Set<Id>{relatedSA.parentRecordId});
                }
            }
        }
        system.debug('Related Service Appointments impacted by ETA updated = ' + saToWoIdListMap);
        return saToWoIdListMap;
    }
    

    public static Set<ID> checkForNewOverlaps(Set<ID> resourceIDSet, Map<ID, Integer> srToTimeDeltaMap){
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        DateTime thresholdTime = System.now();
        Set<ID> resourcesWithNewOverlaps = new Set<ID>();
        
        List<ResourceAbsence> raList = [SELECT id, ResourceID, Start, End, FSL__EstTravelTime__c, FSL__EstTravelTimeFrom__c 
                                         FROM ResourceAbsence WHERE ResourceID IN :resourceIDSet AND Start > :thresholdTime];

        // NOTE: didCallCreateOverlap is NOT bulkified
        for(ResourceAbsence ra : raList){
            if(FSL_OptimizationHelper.didCallCreateOverlap(null, null, ra)){
                resourcesWithNewOverlaps.add(ra.ResourceID);
            }
        }

        return resourcesWithNewOverlaps;
    }
    
    public class Wrapper{
        public integer StackedCalls {get;set;} 
    }

}