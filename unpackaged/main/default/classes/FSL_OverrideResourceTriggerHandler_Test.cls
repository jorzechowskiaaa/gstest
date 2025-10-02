/**
 * @File Name          : FSL_OverrideResourceTriggerHandler_Test.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 03-29-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/6/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
private without sharing class FSL_OverrideResourceTriggerHandler_Test{

    static testmethod void validatePreferenceEntries(){
        list<ServiceTerritory> STs = [select id from ServiceTerritory];
        list<Override_Resource_Preference__c> OverridePrefs = [SELECT Name, Type__c, Service_Territory__c, Service_Resource__c, Service_Resource__r.Primary_Service_Territory__c FROM Override_Resource_Preference__c];
        for(Override_Resource_Preference__c OverridePref : OverridePrefs){
            if(OverridePref.Service_Resource__c==null){
            	OverridePref.Service_Territory__c = STs[1].id;
            }
        }
        try{
        	update OverridePrefs;
        }catch(exception e){
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
    }

    static testmethod void validatePreferenceEntries_test2(){
        list<ServiceResource> SRs = [select id from ServiceResource];
        list<ServiceTerritory> STs = [select id from ServiceTerritory];
		list<Service_Territory_Scheduling_Override__c> schOverrides = [select id from Service_Territory_Scheduling_Override__c];
        try{
            Override_Resource_Preference__c orp1 = new Override_Resource_Preference__c();
            orp1.Scheduling_Override__c = schOverrides[1].id;
            orp1.Service_Resource__c = SRs[1].id; 
            orp1.Type__c = 'Excluded';
            insert orp1;
        
        
        /*list<Override_Resource_Preference__c> OverridePrefs = [SELECT Name, Type__c, Service_Territory__c, Scheduling_Override__c, Service_Resource__c, Service_Resource__r.Primary_Service_Territory__c FROM Override_Resource_Preference__c];
        for(Override_Resource_Preference__c OverridePref : OverridePrefs){
            OverridePref.Service_Territory__c = STs[0].id; 
            OverridePref.Scheduling_Override__c = schOverrides[1].id;
        }
        try{
        	update OverridePrefs;*/
        }catch(exception e){
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
    }

    // ERS-221282: Partial WorkType Test: WorkOrder WorkType matches the Scheduled Override WorkType
    public static testmethod void testServiceTerritorySchedulingOverride_ScheduleOverrideApplies_SchedOverrideReturnsNotNull() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
                
        // Create a WorkOrder and assign it to the SR
        Test.startTest();      
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');             
        Test.stopTest();

        // Setup Service_Territory_Scheduling_Override__c
        list<ServiceTerritory> STs = [SELECT  Id FROM ServiceTerritory];        
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id,name,EstimatedDuration FROM WorkType]);
        System.debug('worktypeIdMap: ' + worktypeIdMap);

        List<WorkOrder> workOrderList = [SELECT Id, WorkTypeId, (SELECT Id, ServiceTerritoryId,ArrivalWindowStartTime,ServiceTerritory.Name, ServiceTerritory.OperatingHours.Timezone FROM ServiceAppointments) FROM WorkOrder];      

        //ServiceAppointment saBreakdown = [SELECT Id,ServiceTerritoryId,ArrivalWindowStartTime,ServiceTerritory.Name, ServiceTerritory.OperatingHours.Timezone FROM ServiceAppointment limit 1];

        Timezone tz = Timezone.getTimeZone(workOrderList[0].ServiceAppointments[0].ServiceTerritory.OperatingHours.Timezone);
        DateTime arrivalWindowStartTime = workOrderList[0].ServiceAppointments[0].ArrivalWindowStartTime;

        // Setup Override_Resource_Preference__c: Tire Change   
        Service_Territory_Scheduling_Override__c schedOverride;
        schedOverride = FSL_SchedulingUtility.checkIfScheduleOverrideApplies(STs[0].Id, tz, arrivalWindowStartTime, worktypeIdMap, workOrderList[0].WorkTypeId);

        System.assertNotEquals( null, schedOverride );

    }

    // ERS-221282: Partial WorkType Test: WorkOrder WorkType does not match any of the Scheduled Override WorkTypes 
    public static testmethod void testServiceTerritorySchedulingOverride_ScheduleOverrideApplies_SchedOverrideReturnsNull() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
                
        // Create a WorkOrder and assign it to the SR
        Test.startTest();      
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');             
        Test.stopTest();

        // Setup Service_Territory_Scheduling_Override__c
        list<ServiceTerritory> STs = [SELECT  Id FROM ServiceTerritory];       
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id,name,EstimatedDuration FROM WorkType]);
        System.debug('worktypeIdMap: ' + worktypeIdMap);

        List<WorkOrder> workOrderList = [SELECT Id, WorkTypeId, (SELECT Id, ServiceTerritoryId,ArrivalWindowStartTime,ServiceTerritory.Name, ServiceTerritory.OperatingHours.Timezone FROM ServiceAppointments) FROM WorkOrder];      

        //ServiceAppointment saBreakdown = [SELECT Id,ServiceTerritoryId,ArrivalWindowStartTime,ServiceTerritory.Name, ServiceTerritory.OperatingHours.Timezone FROM ServiceAppointment limit 1];

        Timezone tz = Timezone.getTimeZone(workOrderList[0].ServiceAppointments[0].ServiceTerritory.OperatingHours.Timezone);
        DateTime arrivalWindowStartTime = workOrderList[0].ServiceAppointments[0].ArrivalWindowStartTime;

        // Modify the STSO for that specific territory, the sto WorkType = 'Tire Change', change it to 'Lockout'
        List<Service_Territory_Scheduling_Override__c> stolist = [SELECT Id, Name, Work_Types__c FROM Service_Territory_Scheduling_Override__c WHERE Service_Territory__c = :STs[0].Id];
        stolist[0].Work_Types__c = 'Lockout';
        update stolist;         

        // Setup Override_Resource_Preference__c: Tire Change <> Lockout  
        Service_Territory_Scheduling_Override__c schedOverride;
        schedOverride = FSL_SchedulingUtility.checkIfScheduleOverrideApplies(STs[0].Id, tz, arrivalWindowStartTime, worktypeIdMap, workOrderList[0].WorkTypeId);

        System.assertEquals( null, schedOverride );

    }
    // Make sure when there is zero record created for:  Override_Resource_Preference__c object, there should be No override
    public static testmethod void testServiceTerritorySchedulingOverride_Override_Resource_PreferenceIsEmptyReturnFalse() {

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
                
        // Create a WorkOrder and assign it to the SR
        Test.startTest();      
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');             
        Test.stopTest();

        // Remove the Override_Resource_Preference__c Record
        List<Override_Resource_Preference__c> OprefList = [SELECT Id FROM Override_Resource_Preference__c];
        for (Override_Resource_Preference__c Opref : OprefList){
            Delete Opref;            
        }

        // Setup Service_Territory_Scheduling_Override__c
        list<ServiceTerritory> STs = [SELECT  Id FROM ServiceTerritory];        
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id,name,EstimatedDuration FROM WorkType]);
        System.debug('worktypeIdMap: ' + worktypeIdMap);

        List<WorkOrder> workOrderList = [SELECT Id, WorkTypeId, (SELECT Id, ServiceTerritoryId,ArrivalWindowStartTime,ServiceTerritory.Name, ServiceTerritory.OperatingHours.Timezone FROM ServiceAppointments) FROM WorkOrder];              

        Timezone tz = Timezone.getTimeZone(workOrderList[0].ServiceAppointments[0].ServiceTerritory.OperatingHours.Timezone);
        DateTime arrivalWindowStartTime = workOrderList[0].ServiceAppointments[0].ArrivalWindowStartTime;

        // Setup Override_Resource_Preference__c: Tire Change   
        Service_Territory_Scheduling_Override__c schedOverride;
        schedOverride = FSL_SchedulingUtility.checkIfScheduleOverrideApplies(STs[0].Id, tz, arrivalWindowStartTime, worktypeIdMap, workOrderList[0].WorkTypeId);

        System.assertEquals( null, schedOverride );

    }

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    } 
}