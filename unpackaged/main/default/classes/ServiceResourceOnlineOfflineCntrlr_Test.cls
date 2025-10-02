@IsTest
public with sharing class ServiceResourceOnlineOfflineCntrlr_Test 
{
    //create user
    //create terr
    //create resource

    @testSetup
    private static void dataSetup() 
    {
        FSL_DataFactoryUtility.userSetupwithStaticData();
        List<User> users = [SELECT Id 
                            FROM user 
                            WHERE alias = 'C_Admin'];

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
            st1.Driver_can_go_Online_Offline__c = false;
            ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = operatingHours[0].Id, IsActive = true );
            st1.Driver_can_go_Online_Offline__c = true;
            List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;

            // ServiceResource sr = new ServiceResource( RelatedRecordId = users[0].Id, Name = 'Resource 1', IsActive = true );
            // sr.Primary_Service_Territory__c = st1.Id;
            // insert sr;

            // List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            // for( Integer i = 0; i < 2; ++i ) {
            //     ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
            //     sa1.SchedStartTime = System.now();
            //     sa1.SchedEndTime = System.now() + 1800;
            //     sa1.actualstarttime = System.now();
            //     sa1.PTA__c = System.now();
            //     serviceAppointments.add( sa1 );
            //     ServiceAppointment sa2 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st2.Id );
            //     sa2.SchedStartTime = System.now() + 1800;
            //     sa2.SchedEndTime = System.now() + 3600;
            //     serviceAppointments.add( sa2 );
            // }
            // for( Integer i = 2; i < 4; ++i ) {
            //     ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = workOrders[i].Id, ParentRecordId = workOrders[i].Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
            //     sa1.SchedStartTime = System.now();
            //     sa1.SchedEndTime = System.now() + 1800;
            //     sa1.actualstarttime = System.now();
            //     sa1.PTA__c = System.now();
            //     serviceAppointments.add( sa1 );
            // }
            // insert serviceAppointments;

            // ServiceResource serviceResource = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
            //                                     FROM ServiceResource 
            //                                     WHERE ResourceType='T' limit 1];
            // List<AssignedResource> assignedResources = new List<AssignedResource>();
            // for( Integer i = 0; i < 6; ++i ) {
            //     assignedResources.add( FSL_DataFactory.createAssignedResource( serviceAppointments[i].Id, serviceResource.Id ) );
            // }
            // insert assignedResources;
        }
    }

    @IsTest
    public static void getServiceResource() 
    {
        List<User> users = [SELECT Id 
            FROM user 
            WHERE alias = 'C_Admin'];

        Test.startTest();
        Map<String,String> result = ServiceResourceOnlineOfflineController.getServiceResource(users[0].Id);
        System.debug(result);
        System.assert(result.size() == 4);
        Test.stopTest();
    }

     @IsTest
    public static void testOnlineOffline() 
    {
        List<User> users = [SELECT Id 
            FROM user 
            WHERE alias = 'C_Admin'];
        String userId = users[0].Id;
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];
        Test.startTest();

        ServiceResourceOnlineOfflineController.goOffline(sr.Id);

        sr = [SELECT Vehicle__c, Last_Used_Vehicle__c,FSL__GanttLabel__c FROM ServiceResource WHERE Id = :sr.Id];
        System.debug(sr);
        System.assert(sr.Vehicle__c == NULL);
        System.assert(sr.Last_Used_Vehicle__c != NULL);
        System.assert(sr.FSL__GanttLabel__c == 'DRIVER OFFLINE');

        ServiceResourceOnlineOfflineController.goOnline(sr.Id);
        sr = [SELECT Vehicle__c, Last_Used_Vehicle__c,FSL__GanttLabel__c FROM ServiceResource WHERE Id = :sr.Id];
        System.debug(sr);
        System.assert(sr.Vehicle__c != NULL);
        System.assert(sr.FSL__GanttLabel__c != 'DRIVER OFFLINE');

        Test.stopTest();

    }
}