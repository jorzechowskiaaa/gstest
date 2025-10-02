/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 *          07/14/2021   Dylan Truong         ERS-224559 - Map missing Type and Approved to the ResourceAbsence for PlatformEvent Retry
 *          07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log
 */
@IsTest
public with sharing class FSL_ResourceAbsenceTest {
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_ResourceAbsence.IFactory factory = new FSL_ResourceAbsence.Factory();

        Test.startTest();
        FSL_ResourceAbsence.IResourceAbsenceService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************   

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testResourceAbsenceService_FetchLklResourceAbsencesOlderThanProvidedDate_NoException_CorrectRecordsReturned() {
        // Since this method invokes a Batchable, use a real DAO instead of a Mock
        FSL_ResourceAbsence.IResourceAbsenceDAO dao = new FSL_ResourceAbsence.ResourceAbsenceDAO();
        FSL_ResourceAbsence.IResourceAbsenceService service = new FSL_ResourceAbsence.ResourceAbsenceService( dao );

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        System.assertEquals( 1, profiles.size(), 'Arrange: The number of profiles returned is incorrect' );

        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profiles[0].Id LIMIT 4];
        System.assertEquals( 4, users.size(), 'Arrange: The number of users returned is incorrect' );

        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add( new ServiceResource( RelatedRecordId = users[0].Id, Name = 'Resource 1', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[1].Id, Name = 'Resource 2', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[2].Id, Name = 'Resource 3', IsActive = true ) );
        srs.add( new ServiceResource( RelatedRecordId = users[3].Id, Name = 'Resource 4', IsActive = true ) );
        insert srs;

        ResourceAbsence ra1 = new ResourceAbsence( ResourceId = srs[0].Id, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL' );
        ResourceAbsence ra2 = new ResourceAbsence( ResourceId = srs[1].Id, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL' );
        ResourceAbsence ra3 = new ResourceAbsence( ResourceId = srs[2].Id, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'LKL' );
        ResourceAbsence ra4 = new ResourceAbsence( ResourceId = srs[3].Id, Start = Datetime.Now().addMinutes( 10 ), End = Datetime.Now().addMinutes( 20 ), FSL__GanttLabel__c = 'Not LKL' );
        List<ResourceAbsence> absences = new List<ResourceAbsence>{ ra1, ra2, ra3, ra4 };
        insert absences;

        Integer daysToRetain = 15;
        Integer maxRecords = 23;
        Datetime createdDatetime = Datetime.now().addDays( -daysToRetain );
        Test.setCreatedDate( ra1.Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( ra2.Id, createdDatetime );
        Test.setCreatedDate( ra3.Id, createdDatetime.addDays( 1 ) );
        Test.setCreatedDate( ra4.Id, createdDatetime.addDays( -1 ) );

        absences = [SELECT Id, CreatedDate, FSL__GanttLabel__c FROM ResourceAbsence];
        System.assertEquals( 4, absences.size(), 'Arrange: The number of Resource Absences is incorrect' );

        Test.startTest();
        service.deleteOldResourceAbsences( daysToRetain, maxRecords );
        Test.stopTest();

        absences = [SELECT Id, CreatedDate, FSL__GanttLabel__c FROM ResourceAbsence];
        System.assertEquals( 3, absences.size(), 'Assert: The number of Resource Absences is incorrect' );
    }
    
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ResourceAbsence.IFactory {
        public FSL_ResourceAbsence.IResourceAbsenceService createService() {
            return new ResourceAbsenceServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_ResourceAbsence.IResourceAbsenceService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType RESOURCEABSENCE_TYPE = ResourceAbsence.getSObjectType();
    public class ResourceAbsenceDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ResourceAbsence.IResourceAbsenceDAO {
        public Map<Id, ResourceAbsence> resourceAbsences;
        public Boolean isSuccess = true;
        public Boolean isNormalException = false;
        public Boolean isRowLockException = false;

        public ResourceAbsenceDAOMock() {
            super( new Map<Id, ResourceAbsence>(), RESOURCEABSENCE_TYPE );
            this.resourceAbsences = (Map<Id, ResourceAbsence>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ResourceAbsenceDAOMock' );
            }
        }

        public override void upsertRecords(List<sObject> records) {
            if (isNormalException) {
                throw new MockException('Normal Exception Messages');
            }
            if (isRowLockException) {
                throw new MockException('UNABLE_TO_LOCK_ROW Message');
            }
            super.upsertRecords(records);
        }

    }
    public class MockException extends Exception {}

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ResourceAbsenceServiceMock implements FSL_ResourceAbsence.IResourceAbsenceService {
        public Boolean throwsException = false;
        public Boolean isNormalException = false;
        public Boolean isRowLockException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ContactServiceMock' );
            }
        }

        public Integer deleteOldResourceAbsencesCallCount = 0;
        public void deleteOldResourceAbsences( Integer daysToRetain, Integer maxRecords ) {
            ++deleteOldResourceAbsencesCallCount;
            throwExceptionIfConfigured();
        }

        public void upsertResourceAbsencesByEventMessage(List<sObject> eventMessages) {
            if (isNormalException) {
                throw new MockException('Normal Exception Messages');
            }
            if (isRowLockException) {
                throw new MockException('UNABLE_TO_LOCK_ROW Message');
            }
        }
    }

    @IsTest
    public static void testResourceAbsenceServiceMock_DeleteOldResourceAbsences_NoException_CallCountIncremented() {
        ResourceAbsenceServiceMock service = new ResourceAbsenceServiceMock();

        System.assertEquals( 0, service.deleteOldResourceAbsencesCallCount );

        Test.startTest();
        service.deleteOldResourceAbsences( null, null );
        Integer callCount1 = service.deleteOldResourceAbsencesCallCount;
        
        service.deleteOldResourceAbsences( null, null );
        Integer callCount2 = service.deleteOldResourceAbsencesCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testResourceAbsenceServiceMock_DeleteOldResourceAbsences_Exception_ExceptionThrownAndCallCountIncremented() {
        ResourceAbsenceServiceMock service = new ResourceAbsenceServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.deleteOldResourceAbsencesCallCount );

        Test.startTest();
        try {
            service.deleteOldResourceAbsences( null, null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.deleteOldResourceAbsencesCallCount );
    }

    @IsTest
    public static void testUpsertResourceAbsencesByEventMessage(){
        Id breakRecordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Non Availability' ).getRecordTypeId();
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
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();

        FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceService = (new FSL_ResourceAbsenceEvent.Factory()).createService();
        eventMessages = resourceService.createResourceAbsenceEventMessages(batchAbsences);
    
        // FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.IResourceAbsenceDAO dao = new FSL_ResourceAbsence.ResourceAbsenceDAO();
        FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService = new FSL_ResourceAbsence.ResourceAbsenceService(dao);
        Test.startTest();
        resourceAbsenceService.upsertResourceAbsencesByEventMessage(eventMessages);
        List<ResourceAbsence> newUpsertedAbsences = [SELECT Id, ResourceId, FSL_Resource_ID__c, Start, End, FSL__GanttLabel__c FROM ResourceAbsence];
        List<FSL_Application_Log__c> appLogs = [SELECT Id, Error_Caught__c,Error_Message__c,Failed_Record_Count__c, Success_Message__c, 
                                                Success_Record_Count__c, Total_Record_Count__c, Operation__c 
                                                FROM FSL_Application_Log__c 
                                                WHERE Operation__c in ('UpsertResourceAbsencePlatformEvent','UpsertResourceAbsencePublishEvent') ];
        for (FSL_Application_Log__c log : appLogs) {
            System.debug('Print Applog ==> ' + log);
        }
        System.assertEquals(2, newUpsertedAbsences.size());
        System.assertEquals(1,appLogs.size());
        Test.stopTest();
    }


    @IsTest
    public static void testUpsertResourceAbsencesByEventMessage_Mock(){
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages = createResourceAbsenceEventTestData();

        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
        Test.startTest();
        resourceAbsenceService.upsertResourceAbsencesByEventMessage(eventMessages);
        Test.stopTest();
        System.assertEquals(true, daoMock.getRecords().size() > 0);
    }

    @IsTest
    public static void testUpsertResourceAbsencesByEventMessageWithNormalException(){
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages = createResourceAbsenceEventTestData();

        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
        daoMock.isNormalException = true;
        Test.startTest();
        try {
            resourceAbsenceService.upsertResourceAbsencesByEventMessage(eventMessages);
        }catch (Exception e ) {
            System.assertEquals(true, e.getMessage().contains('Normal Exception Messages'));
        }
        Test.stopTest();
    }

    @IsTest
    public static void testUpsertResourceAbsencesByEventMessageWithRowLockException(){
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages = createResourceAbsenceEventTestData();

        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService = new FSL_ResourceAbsence.ResourceAbsenceService(daoMock);
        daoMock.isRowLockException = true;
        Test.startTest();
        try {
            resourceAbsenceService.upsertResourceAbsencesByEventMessage(eventMessages);
        }catch (Exception e ) {
            System.assertEquals(true, e.getMessage().contains('UNABLE_TO_LOCK_ROW'));
        }
        Test.stopTest();
    }

    private static List<Resource_Absence_Event__e> createResourceAbsenceEventTestData() {
        Id recordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get( 'Break' ).getRecordTypeId();
        FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock daoMock = new FSL_ResourceAbsenceTest.ResourceAbsenceDAOMock();
        List<Resource_Absence_Event__e> eventMessages = new List<Resource_Absence_Event__e>();
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c=daoMock.Builder.getMockId(),Latitude__c=3.12345611, Record_Type_Id__c = recordTypeId,
                                                        Longtitude__c = 3.1234567, Gantt_Label__c ='Gantt Label Test 1',  Start_Time__c= DateTime.now(), End_Time__c = DateTime.now().addMinutes(20),Type__c='Idle', Approved__c = true));
        eventMessages.add(new Resource_Absence_Event__e(Resource_Absense_Id__c=daoMock.Builder.getMockId(),Latitude__c=1.12345612,Record_Type_Id__c = recordTypeId,
                                                        Longtitude__c = 3.1234567, Gantt_Label__c ='Gantt Label Test 2', Start_Time__c= DateTime.now(),End_Time__c = DateTime.now().addMinutes(20), Type__c='Idle', Approved__c = true));
        return eventMessages;
    }
}