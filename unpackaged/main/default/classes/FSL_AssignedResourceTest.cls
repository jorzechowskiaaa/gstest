@IsTest
public with sharing class FSL_AssignedResourceTest {

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_AssignedResource.IFactory factory = new FSL_AssignedResource.Factory();

        Test.startTest();
        FSL_AssignedResource.IAssignedResourceService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactory_CreateAssignedResource_NotNull() {
        FSL_AssignedResource.IFactory factory = new FSL_AssignedResource.Factory();

        Test.startTest();
        FSL_AssignedResource.AssignedResource assignedResource = factory.createAssignedResource( null );
        Test.stopTest();

        System.assertNotEquals( null, assignedResource );
    }

    // *********************************************
    // * DAO
    // *********************************************
    private static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
        List<User> users = [SELECT Id 
                            FROM user 
                            WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,
                                   PermissionSetId=pset.Id); 

        System.runAs( users[0] ) {
            List<WorkType> workTypes = [SELECT Id FROM WorkType];
            List<OperatingHours> operatingHours = [SELECT Id FROM OperatingHours];

            Account a = new Account( Name = 'Account Name' );
            insert a;

            Contact c = new Contact( LastName = 'Contact Last Name' );
            insert c;

            List<WorkOrder> workOrders = new List<WorkOrder>();
            for( Integer i = 0; i < 4; ++i ) {
                WorkOrder wo = new WorkOrder();
                wo.AccountId = a.Id;
                wo.ContactId = c.Id;
                wo.WorkTypeId = workTypes[0].Id;
                wo.Member_Account__c = a.Id;
                wo.External_Id__c = 'ERS-' + i;
                wo.Call_Date__c = '2023-05-04'; //new added by sanket for testing
                workOrders.add( wo );
            }
            System.debug('workOrders 58 == ' + workOrders);
            insert workOrders;

            ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = operatingHours[0].Id, IsActive = true );
            ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = operatingHours[0].Id, IsActive = true );
            List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;

            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            for( Integer i = 0; i < 2; ++i ) {
                ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
                sa1.SchedStartTime = System.now();
                sa1.SchedEndTime = System.now() + 1800;
                sa1.actualstarttime = System.now();
                sa1.PTA__c = System.now();
                serviceAppointments.add( sa1 );
                ServiceAppointment sa2 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st2.Id );
                sa2.SchedStartTime = System.now() + 1800;
                sa2.SchedEndTime = System.now() + 3600;
                serviceAppointments.add( sa2 );
            }
            for( Integer i = 2; i < 4; ++i ) {
                ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
                sa1.SchedStartTime = System.now();
                sa1.SchedEndTime = System.now() + 1800;
                sa1.actualstarttime = System.now();
                sa1.PTA__c = System.now();
                serviceAppointments.add( sa1 );
            }
            insert serviceAppointments;

            ServiceResource serviceResource = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
                                                FROM ServiceResource 
                                                WHERE ResourceType='T' limit 1];
            List<AssignedResource> assignedResources = new List<AssignedResource>();
            for( Integer i = 0; i < 6; ++i ) {
                assignedResources.add( FSL_DataFactory.createAssignedResource( serviceAppointments[i].Id, serviceResource.Id ) );
            }
            insert assignedResources;
        }
    }

    @IsTest
    public static void testAssignedResourceDAO_FetchAssignedResourcesForClearing_CorrectNumberOfRecordsReturned() {
        FSL_AssignedResourceTest.dataSetup();
        FSL_AssignedResource.IAssignedResourceDAO dao = new FSL_AssignedResource.AssignedResourceDAO();
        List<ServiceAppointment> insertedServiceAppointments = [SELECT Id FROM ServiceAppointment];

        System.assertEquals( 6, insertedServiceAppointments.size() );
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>{ insertedServiceAppointments[2], insertedServiceAppointments[3] };
        
        Test.startTest();
        
        
        List<AssignedResource> assignedResources = dao.fetchAssignedResourcesForServiceAppointments( serviceAppointments );
        
        //Mock call out added by Sanket
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        Test.stopTest();

        System.assertEquals( 2, assignedResources.size() );
        System.assertEquals( insertedServiceAppointments[2].Id, assignedResources[0].ServiceAppointmentId );
        System.assertEquals( insertedServiceAppointments[3].Id, assignedResources[1].ServiceAppointmentId );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    public static void testAssignedResourceService_GetServiceAppointmentIdToAssignedResourceMap_DAOCalled() {
        FSL_AssignedResourceTest.dataSetup();
        AssignedResourceDAOMock dao = new AssignedResourceDAOMock();
        FSL_AssignedResource.IAssignedResourceService service = new FSL_AssignedResource.AssignedResourceService( dao );
        Set<String> externalIds = new Set<String>{ 'ERS-1', 'ERS-2' };
        List<WorkOrder> workOrders = [SELECT Id, 
                                        (SELECT Id 
                                            FROM ServiceAppointments)
                                        FROM WorkOrder
                                        WHERE External_Id__c IN :externalIds];
        System.assertEquals( 2, workOrders.size() );

        ServiceAppointment sa1 = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );
        ServiceAppointment sa2 = new ServiceAppointment( Id = workOrders[0].ServiceAppointments[0].Id );
        ServiceAppointment sa3 = new ServiceAppointment( Id = workOrders[0].ServiceAppointments[1].Id );
        ServiceAppointment sa4 = new ServiceAppointment( Id = workOrders[1].ServiceAppointments[0].Id );
        ServiceAppointment sa5 = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );
        
        AssignedResource ar1 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = sa1.Id );
        AssignedResource ar2 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = sa2.Id );
        AssignedResource ar3 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = sa3.Id );
        AssignedResource ar4 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = sa4.Id );
        AssignedResource ar5 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = sa5.Id );
        dao.assignedResources.put( ar1.Id, ar1 );
        dao.assignedResources.put( ar2.Id, ar2 );
        dao.assignedResources.put( ar3.Id, ar3 );
        dao.assignedResources.put( ar4.Id, ar4 );
        dao.assignedResources.put( ar5.Id, ar5 );

        Test.startTest();
        Map<Id, AssignedResource> assignedResources = service.getServiceAppointmentIdToAssignedResourceMap( workOrders );
        //Mock call out added by Sanket
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        Test.stopTest();

        System.assertEquals( 3, assignedResources.size() );
        System.assertEquals( ar2, assignedResources.get( sa2.Id ) );
        System.assertEquals( ar3, assignedResources.get( sa3.Id ) );
        System.assertEquals( ar4, assignedResources.get( sa4.Id ) );
    }

    // *********************************************
    // * Domain
    // *********************************************
    @IsTest
    public static void testAssignedResource_GetAssignedResource_InjectedInConstructor_SameValue() {
        AssignedResource ar = new AssignedResource();
        FSL_AssignedResource.AssignedResource assignedResource = new FSL_AssignedResource.AssignedResource( ar );

        System.assertEquals( ar, assignedResource.getAssignedResource() );
    }

    @IsTest
    public static void testAssignedResource_GetServiceResource_NotNull_SameValue() {
        dataSetup();
        AssignedResource ar = [SELECT Id, ServiceResourceId, ServiceResource.Name FROM AssignedResource LIMIT 1];
        FSL_AssignedResource.AssignedResource assignedResource = new FSL_AssignedResource.AssignedResource( ar );

        ServiceResource expected = ar.ServiceResource;
		
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
       
        System.assertEquals( expected, assignedResource.getServiceResource() );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_AssignedResource.IFactory {
        public FSL_AssignedResource.IAssignedResourceService createService() {
            return new AssignedResourceServiceMock();
        }

        public FSL_AssignedResource.AssignedResource createAssignedResource( AssignedResource assignedResource ) {
            return new FSL_AssignedResource.AssignedResource( assignedResource );
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FSL_AssignedResource.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_AssignedResource.IAssignedResourceService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    @IsTest
    public static void testFactoryMock_CreateAssignedResource_NotNull() {
        FSL_AssignedResource.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_AssignedResource.AssignedResource assignedResource = factory.createAssignedResource( null );
        Test.stopTest();

        System.assertNotEquals( null, assignedResource );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType ASSIGNEDRESOURCE_TYPE = Schema.AssignedResource.getSObjectType();
    public class AssignedResourceDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_AssignedResource.IAssignedResourceDAO {
        public Map<Id, AssignedResource> assignedResources;
        public Boolean isSuccess = true;

        public AssignedResourceDAOMock() {
            super( new Map<Id, AssignedResource>(), ASSIGNEDRESOURCE_TYPE );
            this.assignedResources = (Map<Id, AssignedResource>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from AssignedResourceDAOMock' );
            }
        }

        public List<AssignedResource> fetchAssignedResourcesForServiceAppointments( List<ServiceAppointment> serviceAppointments ) {
            isQueryException();
            List<AssignedResource> result = new List<AssignedResource>();
            for( AssignedResource ar : assignedResources.values() ) {
                for( ServiceAppointment sa : serviceAppointments ) {
                    if( ar.ServiceAppointmentId == sa.Id ) {
                        result.add( ar );
                    }
                }
            }
            return result;
        }
    }

    @IsTest
    public static void testAssignedResourceDAOMock_FetchAssignedResourcesForServiceAppointments_CorrectNumberOfRecordsReturned() {
        AssignedResourceDAOMock dao = new AssignedResourceDAOMock();
        ServiceAppointment serviceAppointment1 = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );
        ServiceAppointment serviceAppointment2 = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );
        ServiceAppointment serviceAppointment3 = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );

        AssignedResource assignedResource1 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = serviceAppointment1.Id );
        AssignedResource assignedResource2 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = serviceAppointment2.Id );
        AssignedResource assignedResource3 = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = serviceAppointment3.Id );
        dao.assignedResources.put( assignedResource1.Id, assignedResource1 );
        dao.assignedResources.put( assignedResource2.Id, assignedResource2 );
        dao.assignedResources.put( assignedResource3.Id, assignedResource3 );
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>{ serviceAppointment1, serviceAppointment2 };

        Test.startTest();
        List<AssignedResource> assignedResources = dao.fetchAssignedResourcesForServiceAppointments( serviceAppointments );
        Test.stopTest();

        System.assertEquals( 2, assignedResources.size() );
        System.assertEquals( assignedResource1, assignedResources[0] );
        System.assertEquals( assignedResource2, assignedResources[1] );
    }

    @IsTest
    public static void testAssignedResourceDAOMock_FetchAssignedResourcesForClearing_IsException_ExceptionThrown() {
        AssignedResourceDAOMock dao = new AssignedResourceDAOMock();
        ServiceAppointment serviceAppointment = new ServiceAppointment( Id = dao.Builder.getMockId( Schema.ServiceAppointment.getSObjectType() ) );
        AssignedResource assignedResource = new AssignedResource( Id = dao.Builder.getMockId(), ServiceAppointmentId = serviceAppointment.Id );
        dao.assignedResources.put( assignedResource.Id, assignedResource );
        dao.isSuccess = false;
        QueryException ex = null;

        Test.startTest();
        try {
            List<AssignedResource> assignedResources = dao.fetchAssignedResourcesForServiceAppointments( new List<ServiceAppointment>{ serviceAppointment } );
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
    public class AssignedResourceServiceMock implements FSL_AssignedResource.IAssignedResourceService {
        public Integer getServiceAppointmentIdToAssignedResourceMapCallCount = 0;
        public Map<Id, AssignedResource> getServiceAppointmentIdToAssignedResourceMapReturnValue = new Map<Id, AssignedResource>();

        public Map<Id, AssignedResource> getServiceAppointmentIdToAssignedResourceMap( List<WorkOrder> workOrders ) {
            ++ getServiceAppointmentIdToAssignedResourceMapCallCount;
            return getServiceAppointmentIdToAssignedResourceMapReturnValue;
        }
    }

    @IsTest
    public static void testAssignedResourceServiceMock_GetServiceAppointmentIdToAssignedResourceMap_CorrectValueReturnedAndCallCountIncremented() {
        AssignedResourceServiceMock service = new AssignedResourceServiceMock();
        FSL_DAOTest.MockIdGenerator idGen = new FSL_DAOTest.MockIdGenerator( ASSIGNEDRESOURCE_TYPE );

        Test.startTest();
        Integer callCount0 = service.getServiceAppointmentIdToAssignedResourceMapCallCount;

        Map<Id, AssignedResource> assignedResources1 = service.getServiceAppointmentIdToAssignedResourceMap( new List<WorkOrder>() );
        Integer callCount1 = service.getServiceAppointmentIdToAssignedResourceMapCallCount;

        Id assignedResourceId = idGen.getMockId();
        Map<Id, AssignedResource> expected = new Map<Id, AssignedResource>();
        expected.put( assignedResourceId, new AssignedResource( Id = assignedResourceId ) );
        service.getServiceAppointmentIdToAssignedResourceMapReturnValue = expected;
        Map<Id, AssignedResource> assignedResources2 = service.getServiceAppointmentIdToAssignedResourceMap( new List<WorkOrder>() );
        Integer callCount2 = service.getServiceAppointmentIdToAssignedResourceMapCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 0, AssignedResources1.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expected, AssignedResources2 );
        System.assertEquals( 2, callCount2 );
    }

    // *********************************************
    // * DomainMock
    // *********************************************
    public class AssignedResourceMock extends FSL_AssignedResource.AssignedResource {
        public AssignedResourceMock() {
            super( null );
        }

        public Integer getAssignedResourceCallCount = 0;
        public Schema.AssignedResource getAssignedResourceReturnValue = null;
        public override Schema.AssignedResource getAssignedResource() {
            getAssignedResourceCallCount++;
            return getAssignedResourceReturnValue;
        }

        public Integer getServiceResourceCallCount = 0;
        public ServiceResource getServiceResourceReturnValue = null;
        public override ServiceResource getServiceResource() {
            getServiceResourceCallCount++;
            return getServiceResourceReturnValue;
        }
    }
}