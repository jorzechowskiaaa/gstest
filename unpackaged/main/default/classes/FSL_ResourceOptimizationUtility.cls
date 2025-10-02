/**
 * @File Name          : FSL_ResourceOptimizationUtility.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 12-10-2020
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    2/28/2020   Rajesh Kemisetti     Initial Version
 *        11/30/2020  Clement Shiu- ERS-220022 Check to see if Optimization is Already Running before Attempting to run Again     
**/
public with sharing class FSL_ResourceOptimizationUtility {
    // defect: need to adjust statuses after RSO runs. 
    public Datetime horizonStart;
    public Datetime horizonEnd;
    public Set<Id> candidateAppointments = new Set<Id>();
    public Boolean includeAllTasks = true; //if false, only includes unscheduled calls
    public Boolean includeOnlyResourceSA; //if true, only appointments assigned to the resource are considered
    public Set<Id> unschedulableServices = new Set<Id>(); //will not remove from schedule
    public integer maxOptRunTime = 20;
    public Integer radius = null;

    public FSL_ResourceOptimizationUtility(){
        horizonStart = System.now().addHours(-7); //needs Enhancement to adjust for timezone rather than hard coded
        horizonEnd = horizonStart.addHours(12); //is 12 hour window necessary? will reducing this value improve performance?
        //default constructor to have a 12 hour horizon spanning from current time minus 2 hours to current time plus 10 hours
    }

    public FSL_ResourceOptimizationUtility(Datetime horizonStart, Integer horizonHours){
        this.horizonStart = horizonStart;
        this.horizonEnd = this.horizonStart.addHours(horizonHours);
        //constructor to initialize the horizon with parameters
    }

    public void optimizeScheduleGaps(Id resourceId, Id policyId){
        System.debug('Entering optimizeScheduleGaps');
        FSL.OAAS optimizationRequest = new FSL.OAAS();
        FSL.TimeInterval horizon = new FSL.TimeInterval(horizonStart, horizonEnd);
            System.debug('Local Horizon Start : ' + horizon.start.time());
            System.debug('Local Horizon End : ' + horizon.finish.time());
        maxOptRunTime = 20;
        includeOnlyResourceSA = false;

        Id facilityId = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId =: resourceId AND TerritoryType = 'P' AND (EffectiveEndDate > Today OR EffectiveEndDate = null)].ServiceTerritoryId;
        Id parentTerritoryId = [SELECT ParentTerritoryId FROM ServiceTerritory WHERE Id =: facilityId].ParentTerritoryId;
        List<ServiceTerritory> territories = [SELECT Id FROM ServiceTerritory WHERE Id =: parentTerritoryId or ParentTerritoryId =: parentTerritoryId];
        List<Id> territoryIds = new List<Id>();
        for(ServiceTerritory st : territories){
            territoryIds.add(st.Id);
        }

        List<ServiceAppointment> saList = [SELECT Id, ParentRecordId, AppointmentNumber FROM ServiceAppointment 
            WHERE (Status = 'Spotted' AND FSL__InJeopardy__c = TRUE AND FSL__InJeopardyReason__c = 'Spotted Violation' 
                AND ServiceTerritoryId =: parentTerritoryId) OR (Status in ('Scheduled', 'Dispatched') 
                AND ServiceTerritoryId in: territoryIds AND FSL_IsLight_Service__c = true)];
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>(saList);
        List<Id> woIds = new List<Id>();
        for(ServiceAppointment sa : saList){
            woIds.add(sa.ParentRecordId);
        }
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, Priority FROM WorkOrder WHERE Id in: woIds]);

        if (!saList.isEmpty()){
            for(ServiceAppointment sa : saList){
                if(woMap.get(saMap.get(sa.Id).ParentRecordId).Priority.equals('Critical')){
                     unschedulableServices.add(sa.Id);
                     System.debug('Unschedulable Service: ' + sa.appointmentNumber);
                } 
                candidateAppointments.add(sa.Id);
            }
        
           // Id requestId = optimizationRequest.resourceDayOptimization(resourceId, policyId, horizon, includeAllTasks, includeOnlyResourceSA, null, candidateAppointments, null, maxOptRunTime);
           //callRSO(resourceId, policyId, horizonStart, horizonEnd, includeAllTasks, includeOnlyResourceSA, radius, candidateAppointments, candidateAppointments, maxOptRunTime);
        }else {
            System.debug('No Service Appointments found as candidates');
        }
    }

    public void optimizeScheduleOverlaps(Id resourceId, Id appLogId){
        System.debug('Entering optimizeScheduleOverlaps');
        
        FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
        String policyName = oSettings.RSO_Scheduling_Policy__c;
        
        
        Id policyId = [SELECT id, Name FROM FSL__Scheduling_Policy__c WHERE Name = :policyName].id;
        
        String candidateSAField = oSettings.RSO_Candidate_SA_Field_API_Name__c;
        String remainScheduledSAField = oSettings.RSO_Remain_Scheduled_SA_Field_API_Name__c;
        String query = 
            candidateSAField != remainScheduledSAField ? 
                'SELECT id, ' + candidateSAfield + ', ' + remainScheduledSAField + ' FROM ServiceAppointment WHERE Status NOT IN (\'Canceled\', \'Cleared\') AND SchedStartTime >= ' + Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')  + ' AND Service_Resource__c = \'' + resourceId + '\' ' :
                'SELECT id, ' + candidateSAfield + ' FROM ServiceAppointment WHERE Status NOT IN (\'Canceled\', \'Cleared\') AND SchedStartTime >= ' + Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + ' AND Service_Resource__c = \'' + resourceId + '\' ';
        if(String.isNotBlank(candidateSAField)){
            query += ' AND (' + candidateSAField + ' = true';
        }
        if(String.isNotBlank(remainScheduledSAField) && remainScheduledSAField != candidateSAField){
            query += ' OR ' + remainScheduledSAField + ' = true)';
        }else{
            query += ')';
        }
        system.debug(query);

        List<ServiceAppointment> fullAppointmentList = new List<ServiceAppointment>();
        fullAppointmentList = Database.query(query);
        Set<ID> candidateIDSet = new Set<ID>();
        Set<ID> unschedulableIDSet = new Set<ID>();
        for(ServiceAppointment sa : fullAppointmentList){
            if(sa.get(candidateSAField)==true){
                candidateIDSet.add(sa.id);
            }
            if(candidateSAField != remainScheduledSAField){
                if(sa.get(remainScheduledSAField)==true){
                    unschedulableIDSet.add(sa.id);
                }
            }else if(sa.get(candidateSAField)==true){
                unschedulableIDSet.add(sa.id);
            }
           
        }

        includeOnlyResourceSA = true;
        maxOptRunTime = Integer.ValueOf(oSettings.RSO_Max_Run_Time__c);
                
        FSL.OAAS optimizationRequest = new FSL.OAAS();
        FSL.TimeInterval horizon = new FSL.TimeInterval(horizonStart, horizonEnd);
        
        System.debug('Local Horizon Start : ' + horizon.start.time());
        System.debug('Local Horizon End : ' + horizon.finish.time());
        System.debug('Resource : ' + resourceId);
        System.debug('PolicyId :' + policyId);
        System.debug('Candidates : ' + candidateIDSet.size());
        System.debug('Unschedulable: ' + unschedulableIDSet.size());
        
        // Id requestId = optimizationRequest.resourceDayOptimization(resourceId, policyId, horizon, includeAllTasks, includeOnlyResourceSA, null, candidateAppointments, unschedulableServices, maxOptRunTime, system.now().addhours(-6));
        System.debug('Candidate SAs :' + candidateAppointments);
        // saIDSet
        List<FSL__Optimization_Request__c> pendingORList = getPendingORsForResource(resourceId);
        if(pendingORList.isEmpty()) {
            callRSO(resourceId, policyId, horizonStart, horizonEnd, includeAllTasks, includeOnlyResourceSA, radius, candidateIDSet, unschedulableIDSet, maxOptRunTime, appLogId);   //refactor to invoke in future method
        }
        //callRSO(resourceId, policyId, horizonStart, horizonEnd, includeAllTasks, includeOnlyResourceSA, radius, candidateSAField, remainScheduledSAField, maxOptRunTime);   //refactor to invoke in future method
    
    }

    public static List<FSL__Optimization_Request__c> getPendingORsForResource(String resourceId) {
        return [Select Id from FSL__Optimization_Request__c where FSL__Service_Resource__c =:resourceId And FSL__Status__c IN ('Open','Queued','In Progress') AND FSL__Type__c='Resource Schedule Optimization'];
    }
    /*@future(callout=true)
    public static void runIndayService(List<String> primaryTerritoryIdList){
                
        FSL_Service_Endpoints__c clearEndpoint = FSL_Service_Endpoints__c.getValues('FSL_INDAY_SERVICE');
        Http http = new Http();
        httprequest request = new httprequest();
        request.setEndpoint(clearEndpoint.Endpoint_URL__c);
        request.setMethod('POST');  
        request.setTimeout(integer.ValueOf(clearEndpoint.Timeout__c));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer '+ FSL_ConnectedAppUsers__c.getAll().values()[0].Access_Token__c); 
        string body = (string)JSON.serialize(primaryTerritoryIdList);
        system.debug(body);
        request.setBody(body);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            FSL_ApplicationLogCreator.calloutLogger(body, JSON.serializePretty(response.getBody()), 'SUCCESS', '', false, '', '', 'runIndayService');
        }else{
            FSL_ApplicationLogCreator.calloutLogger(body, JSON.serializePretty(response.getBody()),
                                            'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus(),
                                            '', true, '', '', 'runIndayService');
        }         
    } */
    @future(callout=true)
    public static void callInDay(List<String>primaryTerritoryIdList){
        //runIndayService(primaryTerritoryIdList);
        try{
        DateTime start=Datetime.now();
        DateTime finish=Datetime.now().addDays(3);
        
        LIST<Id> lstServiceTerritories = new List<Id>();
        // add all territories from primaryTerritoryIDList
        lstServiceTerritories.add(primaryTerritoryIdList.get(0));
        
        FSL.OAASRequest oaasRequest = new FSL.OAASRequest();
        oaasRequest.allTasksMode = true;
        oaasRequest.filterFieldAPIName = null;
        oaasRequest.start = start;
        oaasRequest.finish = finish;
        oaasRequest.includeServicesWithEmptyLocation = false;
        oaasRequest.locations = lstServiceTerritories;
        // retrieve In-Day Policy (todo: use custom setting)
        List<FSL__Scheduling_Policy__c> inDayPolicies = [SELECT id, Name FROM FSL__Scheduling_Policy__c WHERE FSL__Daily_Optimization__c = :true];
        oaasRequest.schedulingPolicyID = inDayPolicies.get(0).id;
        FSL.OAAS oaas = new FSL.OAAS();        
        // run optimization
        id optRequest = oaas.optimize(oaasRequest);
        }catch(Exception e){
            system.debug('Exception caught: ' + e);
        }   
    }
    @future(callout=true)
    public static void callInDayWithPrimarySeconderyTerritories(List<String> primarySecTrIdList, ID appLogId){
        //runIndayService(primarySecTrIdList);
        try{
            DateTime start=Datetime.now();
            DateTime finish=Datetime.now().addDays(1);
                    
            //  ERS-220022: Filter out those Territories that are in the middle of running already
            primarySecTrIdList = removeSerTerWithPendingOptimization(primarySecTrIdList);

            LIST<Id> lstServiceTerritories = new List<Id>();
            // add all territories from primaryTerritoryIDList
            lstServiceTerritories.addAll(primarySecTrIdList);
            
            FSL.OAASRequest oaasRequest = new FSL.OAASRequest();
            oaasRequest.allTasksMode = true;
            oaasRequest.filterFieldAPIName = null;
            oaasRequest.start = start;
            oaasRequest.finish = finish;
            oaasRequest.includeServicesWithEmptyLocation = false;
            oaasRequest.locations = lstServiceTerritories;
            // retrieve In-Day Policy (todo: use custom setting)
            List<FSL__Scheduling_Policy__c> inDayPolicies = [SELECT id, Name FROM FSL__Scheduling_Policy__c WHERE FSL__Daily_Optimization__c = :true];
            oaasRequest.schedulingPolicyID = inDayPolicies.get(0).id;

            FSL.OAAS oaas = new FSL.OAAS();        
            // run optimization
            id optRequestid = oaas.optimize(oaasRequest);
            FSL_Application_Log__c appLog = new FSL_Application_Log__c(Optimization_Request__c = optRequestid, id=appLogId);
            update appLog;
        }catch(Exception e){
            system.debug('Exception caught: ' + e);
        }   
    }    
    /**
     *  @purpose     - Check to see if the input Optimization Request for the Territory is already running, remove them from the list
     *                 if they are in the middle of optimization. 
     *  Clement Shiu - ERS-220022 Check to see if Optimization is Already Running before Attempting to run Again     
     */
    public static List<String> removeSerTerWithPendingOptimization(List<String> svTrIdsList) {
        List<String> svTrToBeOptimized = new List<String>();

        try {
            // Convert the list to set, so that we can remove the entry from the set later
            Set<String> svTrIdsSet = new Set<String>(svTrIdsList);
                    
            //Retrieve pending inday optimization request within the last 24 hrs        
            List<FSL__Territory_Optimization_Request__c> terOptReqList = [SELECT Id,FSL__ServiceTerritory__c FROM FSL__Territory_Optimization_Request__c WHERE FSL__Optimization_Request__r.FSL__Status__c NOT IN ('Failed','Completed','Completed First Optimization Day') AND FSL__Optimization_Request__r.FSL__Type__c='In Day Optimization' AND createddate = LAST_N_DAYS:2];
            for(FSL__Territory_Optimization_Request__c terOptReq : terOptReqList) {            
                // Remove the Territory from the Set if it is already in the middle of optimization
                if(svTrIdsSet.contains(terOptReq.FSL__ServiceTerritory__c)){
                    svTrIdsSet.remove(terOptReq.FSL__ServiceTerritory__c);
                    System.debug('Removing ' + terOptReq.FSL__ServiceTerritory__c + ' from nonQueuedTrIdSet');
                }                
            }
            // Convert the Service Territory ID Set to List
            svTrToBeOptimized.addAll(svTrIdsSet);                                  
        }catch(Exception e){
            system.debug('Exception caught: ' + e);            
        }    
        return svTrToBeOptimized;                                  
    }

    /*@future (callout=true)
    public static void callRSO(Id resourceId, Id policyId, Datetime horizonStart, Datetime horizonEnd, Boolean includeAllTasks, Boolean includeOnlyResourceSA, Integer radius, String candidateAppointments, String unschedulableServices, Integer maxOptRunTime){
        FSL.OAAS optimization = new FSL.OAAS();
        Datetime horizonStart2 = System.now().addHours(-7); //needs Enhancement to adjust for timezone rather than hard coded
        Datetime horizonEnd2 = horizonStart2.addHours(24); //is 12 hour window necessary? will reducing this value improve performance?
        FSL.TimeInterval horizon2 = new FSL.TimeInterval(horizonStart2, horizonEnd2);
        //Id optId = optimization.resourceDayOptimization(resourceId, policyId, horizon2, includeAllTasks, includeOnlyResourceSA, radius, candidateAppointments, unschedulableServices, maxOptRunTime);
        Id optId = optimization.resourceDayOptimization(resourceId, policyId, horizon2, includeAllTasks, includeOnlyResourceSA, radius, candidateAppointments, unschedulableServices, maxOptRunTime);
    }*/   
    @future (callout=true)
    public static void callRSO(Id resourceId, Id policyId, Datetime horizonStart, Datetime horizonEnd, Boolean includeAllTasks, Boolean includeOnlyResourceSA, Integer radius, Set<ID> candidateAppointments, Set<ID> unschedulableServices, Integer maxOptRunTime, Id appLogId){
        FSL.OAAS optimization = new FSL.OAAS();
        Datetime horizonStart2 = System.now().addHours(-7); //needs Enhancement to adjust for timezone rather than hard coded
        Datetime horizonEnd2 = horizonStart2.addHours(24); //is 12 hour window necessary? will reducing this value improve performance?
        FSL.TimeInterval horizon2 = new FSL.TimeInterval(horizonStart2, horizonEnd2);
        //Id optId = optimization.resourceDayOptimization(resourceId, policyId, horizon2, includeAllTasks, includeOnlyResourceSA, radius, candidateAppointments, unschedulableServices, maxOptRunTime);
        Id optId = optimization.resourceDayOptimization(resourceId, policyId, horizon2, includeAllTasks, includeOnlyResourceSA, radius, candidateAppointments, unschedulableServices, maxOptRunTime);
        FSL_Application_Log__c appLog = new FSL_Application_Log__c(Optimization_Request__c = optId, id=appLogId);
        update appLog;
    }       
    /**********
    *@MethodName : optimizeResourceAbsenceOverlaps
    *@Parameters : (Id resourceId, Id policyId)
    *@Description:
    *@Author :  
    **********/
    /*public void optimizeResourceAbsenceOverlaps(Id resourceId, Id policyId){ 
        
    }*/            
               
    public class ServiceAppointmentWrapper{
        public ServiceAppointment sa{get;set;}
        public Integer travelTimeTo{get;set;}
        public Integer travelTimeFrom{get;set;}
        
        public ServiceAppointmentWrapper(ServiceAppointment sa, Integer travelTimeTo, Integer travelTimeFrom){
            this.sa = sa;
            this.travelTimeTo = travelTimeTo;
            this.travelTimeFrom = travelTimeFrom;
        }
    }

}