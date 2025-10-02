@IsTest
public class FSL_ServiceAppointmentTriggerTest {
    static Integer recordCount = 4;

    @testSetup
    public static void SetUp() {
        //FSL_DataFactoryUtility.userdataSetup();

        List<User> users = FSL_DataFactory.createTestuser();
        User user ;
        for( User u : users ) {
            if( u.alias=='C_Admin' ) {
                user = u;
            }
        }
        system.runAs(user){    
            FSL_DataFactoryUtility.setupCustomSettingsData();
        }

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)'];
        List<User> techs = new List<User>();
        for( Integer i = 0; i < recordCount; ++i ) {
            techs.add( new User( Alias = 'Tech' + i, 
                                Email = 'test_user' + i + '@ace.aaa.com', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'Testing' + i, 
                                LanguageLocaleKey = 'en_US', 
                                LocaleSidKey = 'en_US', 
                                ProfileId = profiles[0].Id, 
                                TimeZoneSidKey = 'America/Los_Angeles', 
                                UserName = 'Tech' + i + '@fleettech.com') );
        }
        insert techs;
    }
    
    // Even items in the ServiceAppointment list are Light Service, Odd items are Tow Service
    private static List<ServiceAppointment> createData() {
        // List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        List<Account> accounts = new List<Account>();
        for( Integer i = 0; i < recordCount; ++i ) {
            accounts.add( new Account( Name = 'Name ' + i ) );
        }
        insert accounts;

        // List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        List<Contact> contacts = new List<Contact>();
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts.add( new Contact( LastName = 'Last Name ' + i, AccountId = accounts[i].Id ) );
            // contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            String recordType = ( math.mod( i, 2 ) == 0 ? 'Light Service' : 'Tow' );
            WorkOrder wo = FSL_DataFactory.createWorkOrderShell( recordType, contacts[i] );
            wo.Status = 'In Progress';
            workOrders.add( wo );
        }
        insert workOrders;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        insert sts;

        List<User> techs = [SELECT Id, Name, IsActive FROM User WHERE Alias LIKE 'Tech%' and IsActive = true];

        List<Schema.Location> locs = new List<Schema.Location>();
        for( Integer i = 0; i < recordCount; ++i ) {
            locs.add( new Schema.Location( Name = 'Name' + i, IsInventoryLocation = true, IsMobile = true, Vehicle_Type__c = 'Flatbed', Facility__c = st1.Id ) );
        }
        locs.add( new Schema.Location( Name = 'Address Change' ) );
        insert locs;

        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for( Integer i = 0; i < recordCount; ++i ) {
            serviceResources.add( FSL_DataFactory.createServiceResource( techs[i].Id, locs[i].Id ) );
        }
        insert serviceResources;

        List<ServiceTerritoryMember> stms = new List<ServiceTerritoryMember>();
        for( Integer i = 0; i < recordCount; i++ ) {
            stms.add( FSL_DataFactory.createServiceTerritoryMember( serviceResources[i].Id, st1.Id ) );
        }
        insert stms;

        List<FSL__User_Territory__c> userTerritories = new List<FSL__User_Territory__c>();
        for( Integer i = 0; i < recordCount; i++ ) {
            userTerritories.add( FSL_DataFactory.createUserTerritories( serviceResources[i].RelatedRecordId, st1.Id ) );
        }
        insert userTerritories;

        Map<String, FSL_WO_To_SA_Status_Mapping__mdt> woStatusToSaStatus = new Map<String, FSL_WO_To_SA_Status_Mapping__mdt>();
        for( FSL_WO_To_SA_Status_Mapping__mdt woToSaStatus : [SELECT MasterLabel, Breakdown_Appointment__c, Tow_Appointment__c FROM FSL_WO_To_SA_Status_Mapping__mdt] ) {
            woStatusToSaStatus.put( woToSaStatus.MasterLabel, woToSaStatus );
        }

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for( Integer i = 0; i < recordCount; ++i ) {
            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
            breakdownSa.EarliestStartTime = breakdownSa.SchedStartTime.addMinutes( -2 );
            breakdownSa.DueDate = breakdownSa.SchedStartTime.addHours( 3 );
            breakdownSa.ParentRecordId = workOrders[i].Id;
            breakdownSa.ServiceTerritoryId = st1.Id;
            breakdownSa.Status = 'Scheduled';
            serviceAppointments.add( breakdownSa );
            if( math.mod( i, 2 ) == 1 ) {
                ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
                towSa.EarliestStartTime = towSa.SchedStartTime.addMinutes( -2 );
                towSa.DueDate = towSa.SchedStartTime.addHours( 3 );
                towSa.ParentRecordId = workOrders[i].Id;
                towSa.ServiceTerritoryId = st2.Id;
                towSa.Status = null;
                serviceAppointments.add( towSa );
            }
        }
        //FSL_ServiceAppointmentTriggerHandler.updateActualStart( serviceAppointments );
        insert serviceAppointments;


        return serviceAppointments;
    }
    
    @IsTest
    public static void test1() {
		Test.startTest();
        List<ServiceAppointment> serviceAppointments = createData();
        Test.stopTest();
        System.assertEquals(6, serviceAppointments.size());
    }
    private static List<ServiceAppointment> createDataWithCancelFlag(Boolean cancelFromFlowFlag) {
    List<ServiceAppointment> serviceAppointments = createData(); // Call the original createData method

    // Set Cancel_From_Flow__c based on the parameter
    for (ServiceAppointment sa : serviceAppointments) {
        sa.Cancel_From_Flow__c = cancelFromFlowFlag;
    }
    update serviceAppointments; // Update with the modified Cancel_From_Flow__c flag

    return serviceAppointments;
}
@IsTest
public static void testTriggerWithCancelFromFlowTrue() {
    Test.startTest();
    // Create ServiceAppointments with Cancel_From_Flow__c set to true
    List<ServiceAppointment> serviceAppointments = createDataWithCancelFlag(true);
    Test.stopTest();

    // Assert that Cancel_From_Flow__c is true for each ServiceAppointment
    for (ServiceAppointment sa : serviceAppointments) {
        System.assertEquals(true, sa.Cancel_From_Flow__c, 'Cancel_From_Flow__c should be true to test trigger condition');
    }
}

@IsTest
public static void testTriggerWithCancelFromFlowFalse() {
    Test.startTest();
    // Create ServiceAppointments with Cancel_From_Flow__c set to false
    List<ServiceAppointment> serviceAppointments = createDataWithCancelFlag(false);
    Test.stopTest();

    // Assert that Cancel_From_Flow__c is false for each ServiceAppointment
    for (ServiceAppointment sa : serviceAppointments) {
        System.assertEquals(false, sa.Cancel_From_Flow__c, 'Cancel_From_Flow__c should be false to allow trigger processing');
    }
}

}