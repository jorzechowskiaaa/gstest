/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 *          07/14/2021   Dylan Truong         ERS-224559 - Map missing Type and Approved to the ResourceAbsence for PlatformEvent Retry
 *          07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log
 */

@isTest
public with sharing class FSL_ResourceAbsenceEventTest {

    private static final Schema.SObjectType RESOURCE_ABSENCE_TYPE = Schema.ResourceAbsence.getSObjectType();
    private static Boolean isExtendedLoggingEnabled;

    private static List<Resource_Absence_Event__e> eventMessages;

    static {
        List<FSL_Feature_Flag__mdt> featureFlag = [SELECT DeveloperName,Enabled__c,Id,Label,Language,MasterLabel,NamespacePrefix,QualifiedApiName FROM FSL_Feature_Flag__mdt WHERE Label='Extended Logging Feature'];
        isExtendedLoggingEnabled = featureFlag[0].Enabled__c;
        system.debug('Initialize Variable ==> ' + isExtendedLoggingEnabled);
    }

    static void makeData() {
        Id recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Break' ).getRecordTypeId();
        System.debug('Testing RecordId ==> ' + recordTypeId); 
        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c=daoMock.Builder.getMockId(),Latitude__c=1.1212352,Record_Type_Id__c = recordTypeId,
                                                        Longtitude__c = 3.1254854, Gantt_Label__c ='Gantt Label Test 1',  Start_Time__c= DateTime.now(), End_Time__c = DateTime.now().addMinutes(20), Type__c='Idle', Approved__c = true));
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c=daoMock.Builder.getMockId(),Latitude__c=1.1254623,Record_Type_Id__c = recordTypeId,
                                                        Longtitude__c = 3.1245612, Gantt_Label__c ='Gantt Label Test 2', Start_Time__c= DateTime.now(),End_Time__c = DateTime.now().addMinutes(20), Type__c='Idle', Approved__c = true));
    }

    static List<ResourceAbsence> createResourceTestData() {
        Id recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Break' ).getRecordTypeId();
        List <ResourceAbsence> resource = new List<ResourceAbsence>();
        ResourceAbsence resAbs = new ResourceAbsence();
        resAbs.FSL__GanttLabel__c = 'Gantt Label Test 1';
        resAbs.ResourceId = '0Hn1k0000004f6eCAA';
        resAbs.RecordTypeId = recordTypeId;
        resAbs.Latitude = 1.123456;
        resAbs.Longitude= 2.12354;
        resAbs.Start = DateTime.now();
        resAbs.End = DateTime.now().addMinutes(30);  
        resAbs.FSL__Approved__c = true;
        resAbs.Type = 'Idle';
        resource.add(resAbs);
        return resource; 
    }
    
    @IsTest
    static void testProcessEventMessages(){
        makeData();
        system.debug('Data ==> ' + eventMessages);
        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = new FSL_ResourceAbsenceEvent.Factory().createService();
        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.ResourceAbsenceService resourceAbsenseService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
    
        Test.startTest();
        resourceAbsenceEventService.processEventMessages(eventMessages,resourceAbsenseService);
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                    Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        for(FSL_Application_Log__c log : appLogs) {
            System.debug('Application Log ==> ' + log);
        }
        Test.stopTest();
        if(isExtendedLoggingEnabled) {
            System.assertEquals(1, appLogs.size());
        } else {
            System.assertEquals(0,appLogs.size());
        }
        system.assertEquals(true, daoMock.getRecords().size()>0);   
    }

    @IsTest
    static void testProcessEventMessageWithNormalException(){
        makeData();
        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = new FSL_ResourceAbsenceEvent.Factory().createService();
        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.ResourceAbsenceService resourceAbsenseService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
        Test.startTest();
        daoMock.isNormalException = true;
        try {
            resourceAbsenceEventService.processEventMessages(eventMessages,resourceAbsenseService);
        }catch (Exception e ) {
            System.debug('Exception == > ' + e);
            System.assertEquals(true, e.getMessage().contains('Normal Exception Messages'));
        }
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                    Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        for (FSL_Application_Log__c log : appLogs) {
            System.debug('Log : ' + log);
        }
        System.debug('Extended Log ==>' + isExtendedLoggingEnabled);
        if(isExtendedLoggingEnabled) {
            System.assertEquals(2, appLogs.size());
        } else {
            System.assertEquals(1,appLogs.size());
        }
        Test.stopTest();        
    }

    @IsTest
    static void testProcessEventMessageWithRowLockException(){
        makeData();
        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = new FSL_ResourceAbsenceEvent.Factory().createService();
        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.ResourceAbsenceService resourceAbsenseService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
        Test.startTest();
        daoMock.isRowLockException = true;
        try {
            resourceAbsenceEventService.processEventMessages(eventMessages,resourceAbsenseService);
        }catch (Exception e ) {
            System.debug('Exception == > ' + e);
            System.assertEquals(true, e.getTypeName().contains('RetryableException'));
        }
        Test.getEventBus().deliver();
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                        Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        Test.stopTest();   
        for (FSL_Application_Log__c log : appLogs) {
            System.debug('Log : ' + log);
        }   
        if(isExtendedLoggingEnabled) {
            System.assertEquals(3, appLogs.size());
        } else {
            System.assertEquals(0,appLogs.size());
        }  
    }   
    @IsTest
    static void testCreateResourceAbsenseEventMessages(){
        List <ResourceAbsence> resourceAbsences = createResourceTestData();
        Test.startTest();
        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = new FSL_ResourceAbsenceEvent.Factory().createService();
        List<Resource_Absence_Event__e> resourceAbsenceEvents = resourceAbsenceEventService.createResourceAbsenceEventMessages(resourceAbsences);
        System.assertEquals(true, resourceAbsenceEvents.size()>0);
        Test.stopTest();
        
    }

    @IsTest
    static void testGetNumberOfRetries(){
        Test.startTest();
        FSL_ConfigurationSetting.IConfigurationSettingService configSettingService = (new FSL_ConfigurationSetting.Factory()).createService();
        List<FSL_Configuration_Setting__mdt> mdts = configSettingService.getConfigurationSettingByName('Resource Absence Platform Event');
               FSL_ResourceAbsenceEvent.IResourceAbsenceEventDAO dao = new FSL_ResourceAbsenceEvent.ResourceAbsenceEventDAO();
        FSL_ResourceAbsenceEvent.ResourceAbsenceEventService resourceAbsenceEventService = new FSL_ResourceAbsenceEvent.ResourceAbsenceEventService(dao);
        System.debug('Number of Retries' + resourceAbsenceEventService.getNumberOfRetries());
        if (!mdts.isEmpty() && mdts[0].Enabled__c) {
                System.assertEquals(true, resourceAbsenceEventService.getNumberOfRetries() > 0);
        } else {
            System.assertEquals(true, resourceAbsenceEventService.getNumberOfRetries() == 0);
        } 
        Test.stopTest();
    }
}