@IsTest
public with sharing class FSL_GroupTest {
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_Group.IFactory factory = new FSL_Group.Factory();

        Test.startTest();
        FSL_Group.IGroupService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void createDaoData() {
        List<Group> groups = new List<Group>();
        groups.add( new Group( Type = 'Regular', DeveloperName = 'Developer_Name', Name = 'Name1' ) );
        groups.add( new Group( Type = 'Queue', DeveloperName = 'Developer_Name', Name = 'Name2' ) );
        groups.add( new Group( Type = 'Queue', DeveloperName = 'Not_Developer_Name', Name = 'Name3' ) );
        insert groups;
    }

    @IsTest
    public static void testGroupDAO_FetchGroup_CorrectRecordReturned() {
        createDaoData();
        FSL_Group.IGroupDAO dao = new FSL_Group.GroupDAO();
        String groupType = 'Queue';
        String devName = 'Developer_Name';

        Test.startTest();
        List<Group> groups = dao.fetchGroup( groupType, devName );
        Test.stopTest();

        System.assertEquals( 1, groups.size() );
        System.assertEquals( groupType, groups[0].Type );
        System.assertEquals( devName, groups[0].DeveloperName );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testGroupService_GetGroupForClearQueueCaseOwnership_DAOReturnsSingleRecord_GroupReturned() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Not Queue', DeveloperName = 'Clear_Queue' );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Clear_Queue' );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Not_Clear_Queue' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );

        Test.startTest();
        Group g = service.getGroupForClearQueueCaseOwnership();
        Test.stopTest();

        System.assertEquals( g2.Id, g.Id );
    }

    @IsTest
    public static void testGroupService_GetGroupForClearQueueCaseOwnership_DAOReturnsMultipleObjects_FirstObjectReturned() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Not Queue', DeveloperName = 'Developer_Name' );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Clear_Queue' );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Different_Developer_Name' );
        Group g4 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Clear_Queue' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );
        dao.groups.put( g4.Id, g4 );

        Test.startTest();
        Group g = service.getGroupForClearQueueCaseOwnership();
        Test.stopTest();

        System.assertEquals( g2.Id, g.Id );
    }

    @IsTest
    public static void testGroupService_GetGroupForClearQueueCaseOwnership_DAOReturnsEmptyList_ExceptionThrown() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        String groupType = 'Non-existent Group Type';
        String devName = 'Non_Existent_Developer_Name';
        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Different Group Type', DeveloperName = devName );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = 'Group Type', DeveloperName = 'Developer_Name' );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = groupType, DeveloperName = 'Different_Developer_Name' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );
        Exception ex = null;

        Test.startTest();
        try {
            Group g = service.getGroupForClearQueueCaseOwnership();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    public static void testGroupService_GetGroupForLandLineCallCanceled_DAOReturnsSingleRecord_GroupReturned() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Not Queue', DeveloperName = 'Non_Technology_Queue' );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Non_Technology_Queue' );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Some_Other_Queue' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );

        Test.startTest();
        Group g = service.getGroupForClearQueueCaseOwnership();
        Test.stopTest();

        System.assertEquals( g2.Id, g.Id );
    }

    @IsTest
    public static void testGroupService_GetGroupForLandLineCallCanceled_DAOReturnsMultipleObjects_FirstObjectReturned() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Not Queue', DeveloperName = 'Developer_Name' );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Non_Technology_Queue' );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Different_Developer_Name' );
        Group g4 = new Group( Id = dao.Builder.getMockId(), Type = 'Queue', DeveloperName = 'Non_Technology_Queue' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );
        dao.groups.put( g4.Id, g4 );

        Test.startTest();
        Group g = service.getGroupForLandLineCallCanceled();
        Test.stopTest();

        System.assertEquals( g2.Id, g.Id );
    }

    @IsTest
    public static void testGroupService_GetGroupForLandLineCallCanceled_DAOReturnsEmptyList_ExceptionThrown() {
        GroupDAOMock dao = new GroupDAOMock();
        FSL_Group.IGroupService service = new FSL_Group.GroupService( dao );

        String groupType = 'Non-existent Group Type';
        String devName = 'Non_Existent_Developer_Name';
        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Different Group Type', DeveloperName = devName );
      
        dao.groups.put( g1.Id, g1 );
        Exception ex = null;

        Test.startTest();
        try {
            Group g = service.getGroupForLandLineCallCanceled();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_Group.IFactory {
        public FSL_Group.IGroupService createService() {
            return new GroupServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_Group.IGroupService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType GROUP_TYPE = Schema.Group.getSObjectType();
    public class GroupDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Group.IGroupDAO {
        public Map<Id, Group> groups;
        public Boolean isSuccess = true;

        public GroupDAOMock() {
            super( new Map<Id, Group>(), GROUP_TYPE );
            this.groups = (Map<Id, Group>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from GroupDAOMock' );
            }
        }

        public List<Group> fetchGroup( String groupType, String developerName ) {
            isQueryException();
            List<Group> result = new List<Group>();
            for( Group g : groups.values() ) {
                if( g.Type == groupType && g.DeveloperName == developerName ) {
                    result.add( g );
                }
            }
            return result;
        }
    }

    @IsTest
    public static void testGroupDAOMock_FetchGroup_CorrectNumberOfRecordsReturned() {
        GroupDAOMock dao = new GroupDAOMock();
        String groupType = 'Group Type';
        String devName = 'Developer_Name';
        Group g1 = new Group( Id = dao.Builder.getMockId(), Type = 'Different Group Type', DeveloperName = devName );
        Group g2 = new Group( Id = dao.Builder.getMockId(), Type = groupType, DeveloperName = devName );
        Group g3 = new Group( Id = dao.Builder.getMockId(), Type = groupType, DeveloperName = 'Different_Developer_Name' );
        dao.groups.put( g1.Id, g1 );
        dao.groups.put( g2.Id, g2 );
        dao.groups.put( g3.Id, g3 );

        Test.startTest();
        List<Group> groups = dao.fetchGroup( groupType, devName );
        Test.stopTest();

        System.assertEquals( 1, groups.size() );
        System.assertEquals( g2.Id, groups[0].Id );
        System.assertEquals( groupType, groups[0].Type );
        System.assertEquals( devName, groups[0].DeveloperName );
    }

    @IsTest
    public static void testGroupDAOMock_FetchGroup_IsException_ExceptionThrown() {
        GroupDAOMock dao = new GroupDAOMock();
        String groupType = 'Group Type';
        String devName = 'Developer_Name';
        Group g = new Group( Id = dao.Builder.getMockId(), Type = groupType, DeveloperName = devName );
        dao.groups.put( g.Id, g );
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<Group> groups = dao.fetchGroup( groupType, devName );
        }
        catch( QueryException e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class GroupServiceMock implements FSL_Group.IGroupService {
        public Integer getGroupForClearQueueCaseOwnershipCallCount = 0;
        public Integer getGroupForLandLineCallCanceledCallCount = 0;
        public Group getGroupForClearQueueCaseOwnershipReturnValue = null;   
        public Group getGroupForLandLineCallCanceledReturnValue = null;
        public Group getGroupForQueueNameReturnValue = null;
        public Integer getGroupForQueueNameCallCount = 0;
        public Boolean throwsException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in FSL_GroupTest.GroupServiceMock' );
            }
        }

        public Group getGroupForClearQueueCaseOwnership() {
            ++getGroupForClearQueueCaseOwnershipCallCount;
            throwExceptionIfConfigured();
            return getGroupForClearQueueCaseOwnershipReturnValue;
        }

        public Group getGroupForQueueName(string queuename) {
            ++getGroupForQueueNameCallCount;
            throwExceptionIfConfigured();
            return getGroupForQueueNameReturnValue;
        }
       
        public  Group getGroupForLandLineCallCanceled() { 
            ++getGroupForLandLineCallCanceledCallCount;
            throwExceptionIfConfigured();
            return getGroupForLandLineCallCanceledReturnValue;
        }
    }

    @IsTest
    public static void testGroupServiceMock_GetGroupForClearQueueCaseOwnership_CallCountIncrementedAndReturnValueReturned() {
        GroupServiceMock service = new GroupServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.getGroupForClearQueueCaseOwnershipCallCount;

        Group group1 = service.getGroupForClearQueueCaseOwnership();
        Integer callCount1 = service.getGroupForClearQueueCaseOwnershipCallCount;

        Group expected = new Group();
        service.getGroupForClearQueueCaseOwnershipReturnValue = expected;
        Group group2 = service.getGroupForClearQueueCaseOwnership();
        Integer callCount2 = service.getGroupForClearQueueCaseOwnershipCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( null, group1 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, group2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testGroupServiceMock_GetGroupForClearQueueCaseOwnership_ThrowsExceptionTrue_ExceptionThrown() {
        GroupServiceMock service = new GroupServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            Group g = service.getGroupForClearQueueCaseOwnership();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }


    @IsTest
    public static void testGroupServiceMock_GetGroupForLandLineCallCanceled_CallCountIncrementedAndReturnValueReturned() {
        GroupServiceMock service = new GroupServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.getGroupForLandLineCallCanceledCallCount;

        Group group1 = service.getGroupForLandLineCallCanceled();
        Integer callCount1 = service.getGroupForLandLineCallCanceledCallCount;

        Group expected = new Group();
        service.getGroupForLandLineCallCanceledReturnValue = expected;
        Group group2 = service.getGroupForLandLineCallCanceled();
        Integer callCount2 = service.getGroupForLandLineCallCanceledCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( null, group1 );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, group2 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testGroupServiceMock_GetGroupForLandLineCallCanceled_ThrowsExceptionTrue_ExceptionThrown() {
        GroupServiceMock service = new GroupServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            Group g = service.getGroupForLandLineCallCanceled();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }
}