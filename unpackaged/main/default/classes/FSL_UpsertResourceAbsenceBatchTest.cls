/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 *          7/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log: adding total record count
 * 
 */
@IsTest
public with sharing class FSL_UpsertResourceAbsenceBatchTest {
    private static Id breakRecordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Non Availability' ).getRecordTypeId();
    private static Boolean isExtendedLoggingEnabled;

    static {
        List<FSL_Feature_Flag__mdt> featureFlag = [SELECT DeveloperName,Enabled__c,Id,Label,Language,MasterLabel,NamespacePrefix,QualifiedApiName FROM FSL_Feature_Flag__mdt WHERE Label='Extended Logging Feature'];
        isExtendedLoggingEnabled = featureFlag[0].Enabled__c;
    }

    static List<ResourceAbsence> setupData() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profiles[0].Id LIMIT 4];
        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add( new ServiceResource( RelatedRecordId = users[0].Id, Name = 'Resource 1', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[1].Id, Name = 'Resource 2', IsActive = true ) );
        insert srs;

        List<ResourceAbsence> absences = new List<ResourceAbsence>();
        absences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL', Type='Idle' , FSL__Approved__c =true) );
        insert absences;

        List<ResourceAbsence> batchAbsences = new List<ResourceAbsence>();
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL2' , Type='Idle' , FSL__Approved__c =true) );
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[1].Id, FSL_Resource_ID__c = srs[1].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL3', Type='Idle' , FSL__Approved__c =true ) );
        return batchAbsences;
    }

    @IsTest
    public static void testExecute_ListContainsExistentAndNonExistentResourceIds_Upserted() {
        
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        System.assertEquals( 1, profiles.size() );

        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profiles[0].Id LIMIT 4];
        System.assertEquals( 4, users.size() );

        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add( new ServiceResource( RelatedRecordId = users[0].Id, Name = 'Resource 1', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[1].Id, Name = 'Resource 2', IsActive = true ) );
        insert srs;

        List<ResourceAbsence> absences = new List<ResourceAbsence>();
        absences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL', Type='Idle' , FSL__Approved__c =true ) );
        insert absences;

        List<ResourceAbsence> batchAbsences = new List<ResourceAbsence>();
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL', Type='Idle' , FSL__Approved__c =true ) );
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[1].Id, FSL_Resource_ID__c = srs[1].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL' , Type='Idle' , FSL__Approved__c =true) );

        Test.startTest();
        FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( batchAbsences );
        Database.executeBatch( batch );
        Test.stopTest();

        List<ResourceAbsence> upsertedAbsences = [SELECT Id, ResourceId, FSL_Resource_ID__c, Start, End, FSL__GanttLabel__c FROM ResourceAbsence];
        List<FSL_Application_Log__c> applicationLogs = [SELECT Id FROM FSL_Application_Log__c WHERE Operation__c = 'UpsertResourceAbsence'];
        System.assertEquals( 2, upsertedAbsences.size() );
        System.assertEquals( srs[0].Id, upsertedAbsences[0].FSL_Resource_ID__c );
        System.assertEquals( srs[1].Id, upsertedAbsences[1].FSL_Resource_ID__c );
        System.assertNotEquals( absences[0].Start, upsertedAbsences[0].Start );
        System.assertEquals( 1, applicationLogs.size() );
    }

    // *********************************************
    // * ApplicationLog
    // *********************************************
    @IsTest
    public static void testLklUpsertApplicationLog_GetApplicationLog_DefaultConstructor_RecordTypeIsGeneral() {
        FSL_UpsertResourceAbsenceBatch.LklUpsertResultApplicationLog appLog = new FSL_UpsertResourceAbsenceBatch.LklUpsertResultApplicationLog();
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        FSL_Application_Log__c log = appLog.getApplicationLog();

        System.assertEquals( generalRecordTypeId, log.RecordTypeId );
    }
  
    @IsTest
    static void testPublishEventMessageForFailedUpsert_Successful(){          
        Test.startTest();
        List<ResourceAbsence> batchAbsences = setupData();
        FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( batchAbsences );
        batch.publishEventMessagesForFailedUpsert(batchAbsences, new FSL_UpsertResourceAbsenceBatch.EventSubscriberService());
        Test.getEventBus().deliver();
        List<ResourceAbsence> newUpsertedAbsences = [SELECT Id, ResourceId, FSL_Resource_ID__c, Start, End, FSL__GanttLabel__c FROM ResourceAbsence];
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        for (FSL_Application_Log__c log : appLogs) {
            System.debug ('Print Log ==> ' + log );
        }
        if(isExtendedLoggingEnabled) {
            System.assertEquals(3, appLogs.size());
        } else {
            System.assertEquals(1,appLogs.size());
        }
        System.assertEquals( 2, newUpsertedAbsences.size() );
        Test.stopTest();
    }


    @IsTest
    static void testPublishEventMessageForFailedUpsert_Failure(){          
        Test.startTest();
        List<ResourceAbsence> batchAbsences = setupData();
        MockEventSubcriberService mockService = new MockEventSubcriberService();
        mockService.isSuccessfulTest = false;
        FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( batchAbsences );
        batch.publishEventMessagesForFailedUpsert(batchAbsences, mockService);
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        for (FSL_Application_Log__c log : appLogs) {
            System.debug ('Print Log ==> ' + log );
        }
        System.assertEquals(1,appLogs.size());
        Test.stopTest();
    }


    @IsTest
    static void testPublishEventMessageForFailedUpsert_SucessfulPublish_ExceptionInUpsert(){     

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profiles[0].Id LIMIT 4];
        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add( new ServiceResource( RelatedRecordId = users[0].Id, Name = 'Resource 1', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[1].Id, Name = 'Resource 2', IsActive = true ) );
        insert srs;

        List<ResourceAbsence> absences = new List<ResourceAbsence>();
        absences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL', Type='Idle' , FSL__Approved__c =true) );
        insert absences;

        Test.startTest();
        List<ResourceAbsence> absences2 = [SELECT ResourceId, FSL_Resource_ID__c,Latitude, Longitude, RecordTypeId, Start,End, FSL__GanttLabel__c, Type, FSL__Approved__c,FSL__Gantt_Color__c FROM ResourceAbsence WHERE  ResourceId =:srs[0].Id LIMIT 1 FOR UPDATE ];
        List<ResourceAbsence> batchAbsences = new List<ResourceAbsence>();
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[0].Id, FSL_Resource_ID__c = srs[0].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL2' , Type='Idle' , FSL__Approved__c =true) );
        batchAbsences.add( new ResourceAbsence( ResourceId = srs[1].Id, FSL_Resource_ID__c = srs[1].Id, RecordTypeId =breakRecordTypeId, Start = Datetime.Now(), End = Datetime.Now().addMinutes( 1 ), FSL__GanttLabel__c = 'LKL3', Type='Idle' , FSL__Approved__c =true ) );
        batchAbsences.add(absences2[0]);
        FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( batchAbsences );
        batch.publishEventMessagesForFailedUpsert(batchAbsences,new FSL_UpsertResourceAbsenceBatch.EventSubscriberService());
        Test.getEventBus().deliver();
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        if(isExtendedLoggingEnabled) {
            System.assertEquals(3, appLogs.size());
        } else {
            System.assertEquals(1,appLogs.size());
        }
        for (FSL_Application_Log__c log : appLogs) {
            System.debug ('Print Log ==> ' + log );
        }
        Test.stopTest();
        
    }

    @IsTest
    static void testLogPublishingEventError(){
        Id recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Break' ).getRecordTypeId();
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c='0Hn1k0000004f6eCAA',Latitude__c=1.1212352,Record_Type_Id__c = recordTypeId,Type__c = 'Idle', Approved__c = true,
                                                        Longtitude__c = 3.1254854, Gantt_Label__c ='Gantt Label Test 1',  Start_Time__c= DateTime.now(), End_Time__c = DateTime.now().addMinutes(20)));
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c='0Hn1k0000004f7GCAQ',Latitude__c=1.1254623,Record_Type_Id__c = recordTypeId,Type__c = 'Idle', Approved__c = true,
                                                        Longtitude__c = 3.1245612, Gantt_Label__c ='Gantt Label Test 2', Start_Time__c= DateTime.now(),End_Time__c = DateTime.now().addMinutes(20)));
        Test.startTest();
        List<ResourceAbsence> batchAbsences = new List<ResourceAbsence>();
        FSL_UpsertResourceAbsenceBatch batch = new FSL_UpsertResourceAbsenceBatch( batchAbsences );
        batch.logPublishingEventError(new MockException('Mock Exception from publish event'),eventMessages );
        List<FSL_Application_Log__c> applicationLogs = [SELECT Id FROM FSL_Application_Log__c WHERE Operation__c = 'UpsertResourceAbsencePublishEvent'];
        System.assertEquals(true, applicationLogs.size()>0);
        Test.stopTest();
        
    }
    public class MockException extends Exception{}

    public class MockEventSubcriberService extends FSL_UpsertResourceAbsenceBatch.EventSubscriber {
        public boolean isSuccessfulTest = true;
       
        public MockEventSubcriberService () {
            super();
        }
        
        public override void publishEvents(List<sObject> eventMessages) {
            if(!isSuccessfulTest) {
                throw new MockException('Failed to publish message to platform Event');
            }
        }
    }

}