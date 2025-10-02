//!!! This is a coverage only test

@IsTest
public with sharing class AutoscheduleQuickActionController_Test 
{
    static Integer recordCount = 2;

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
            wo.Is_Tow_WorkType__c = true;
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
            breakdownSa.Work_Order__c = workOrders[i].Id;
            serviceAppointments.add( breakdownSa );
            if( math.mod( i, 2 ) == 1 ) {
                ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
                towSa.EarliestStartTime = towSa.SchedStartTime.addMinutes( -2 );
                towSa.DueDate = towSa.SchedStartTime.addHours( 3 );
                towSa.ParentRecordId = workOrders[i].Id;
                towSa.ServiceTerritoryId = st2.Id;
                towSa.Status = null;
                towSa.Subject = 'Tow Appointment';
                towSa.Work_Order__c = workOrders[i].Id;
                serviceAppointments.add( towSa );
            }
        }
        //FSL_ServiceAppointmentTriggerHandler.updateActualStart( serviceAppointments );
        insert serviceAppointments;

        //serviceAppointments[0].FSL__Related_Service__c = serviceAppointments[1].Id;
        serviceAppointments[1].FSL__Related_Service__c = serviceAppointments[0].Id;
        serviceAppointments[1].FSL__Same_Resource__c = true;
        update serviceAppointments;
        System.debug('RECS-'+serviceAppointments);

        List<AssignedResource> assignedResources = new List<AssignedResource>();
        AssignedResource assignedResource = new AssignedResource(ServiceAppointmentId = serviceAppointments[0].id, ServiceResourceId = serviceResources[0].id,
                                            FSL__UpdatedByOptimization__c = false);
        assignedResources.add(assignedResource);
        
        system.debug('assignedResources 133' + assignedResources);
        
        insert assignedResources;

        return serviceAppointments;
    }

    @IsTest 
    public static void testAutoschedule()
    {
        List<ServiceAppointment> serviceAppointments = createData();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));

        Test.startTest();
        //String saId = nimSa.getObject('bkdnNormalTowBestTow').Id;
        String saId = serviceAppointments[1].Id;
        AutoscheduleQuickActionController.autoschedule(saId);
        Test.stopTest();

    }
}