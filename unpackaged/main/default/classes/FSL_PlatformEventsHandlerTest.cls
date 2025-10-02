@isTest
class FSL_PlatformEventsHandlerTest {
    @isTest
    private static List<WorkOrder> createTestWorkOrders() {
      RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
      RecordType acctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' AND SobjectType = 'Account' LIMIT 1];

        Account acct = new Account(
            AAA_Membership_Level__c = 'Basic',
            ACG_AAA_Membership__c = '6202404941373217',
            ACG_Club__C = '240',
            ACG_Club_Name__c = 'AAA South Central New England',
            ACG_Entitlements_Allotted__c = 4,
            ACG_Membership_Status__c = 'Active',
            ACG_Priority_Service__c = false,
            ACG_SMS_Opt_In__c = false,
            BillingCity = 'TEMPLETON',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            BillingPostalCode = '01468',
            BillingState = 'MA',
            BillingStateCode = 'MA',
            BillingStreet = '2914341 MAIN ST',
            CDX_Membership_Status__c = 'Active',
            CDX_Motorcycle_Coverage__c = false,
            FirstName = 'APEX',
            LastName = 'TEST',
            Member_Card_Num__pc = '6202404941373217',
            Member_ID__c = '6202404941373216',
            Membership_Level__pc = 'BASIC',
            Membership_Org__pc = 'EDS',
            Membership_OrgCode__pc = '240',
            Membership_Program__pc = '00000109',
            Membership_Service_Charge_Indicator__pc = false,
            Membership_Sponsor__pc = '00000035',
            Membership_Status__pc = 'ACTIVE',
            Membership_Type__pc = 'Associate Member',
            PersonHomePhone = '9785552168',
            PersonMobilePhone = '9785552168',
            Phone = '9785552168',
            Phone_Type__pc = 'CELLULAR',
            RecordTypeId = acctType.Id,
            Sms_Optin__pc = false,
            Type__pc = 'CUSTOMER',
            X200_Mile_Tow_Used__c = false
        );
        insert acct;

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;
		
        /*        
        Group gRec = new Group();
        gRec.Name = 'ContractApproval';
        insert gRec;

        
        Contract__c svcContract = new Contract__c(
            Name = 'APEXTESTINGCONTRACT'
        );
        insert svcContract;
		*/
        
        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = 'TEST',
            City = 'FLUSHING',
            //Contract__c = svcContract.Id,
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert svcTerritory;
        
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acct.Id];

        WorkOrder wo = new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = 'G101',
            ServiceTerritoryId = svcTerritory.Id,
            City = 'GARDEN CITY',
            Country = 'United States',
            PostalCode = '11530',
            State = 'NY',
            Street = '1415 KELLUM PL',
            Call_Origin__c = 'RAP',
            Call_Origin_OrgCode__c = '801',
            Call_Origin_OrgName__c = 'EDS',
            Call_Source__c = 'Salesforce',
            Call_Type__c = 'MEMBER',
            Clearing_Code__c = 'N5',
            External_ID__c = '801-20230926-540808',
            Call_Date__c = '2024-02-01',
            PTA__c = System.today(),
            Wait_Time__c = 30,
            Latitude = 37.79135894952317,
            Longitude = -122.39706552873265,
            Tow_Location__Latitude__s = 37.79135894952317,
            Tow_Location__Longitude__s = -122.39706552873265,
            Tow_Street__c = '175 International Parkway',
            Tow_City__c = 'New York',
            Tow_State__c = 'NY',
            Tow_Postal_Code__c = '11530',
            RAP_Case_Number__c = '50000044',
            Original_Member_Id__c = '6202400000235007',
            T_Code__c = 'L101 - Tire Change',
            FSL_Pacesetter__c = '1',
            ContactId = contact.Id
        );
        insert wo;  
        
        List<WorkOrder> lstWO = [
            SELECT 
                Call_Id__c, 
                WorkOrderNumber, 
                Status, 
                Resolution_Code__c, 
                ServiceTerritoryId, 
                City, 
                Country, 
                PostalCode, 
                Member_Vehicle__c,
                State, 
                Street, 
                Call_Origin__c,
                Call_Origin_OrgCode__c, 
                Call_Origin_OrgName__c, 
                Call_Source__c,
                Call_Type__c, 
                Clearing_Code__c, 
                External_ID__c, 
                Call_Date__c, 
                PTA__c, 
                Wait_Time__c, 
                Latitude, 
                Longitude,  
                Tow_Street__c, 
                Tow_City__c, 
                Tow_State__c, 
                Tow_Postal_Code__c, 
                Work_Type_Name__c,
                Tow_Location__Latitude__s, 
                Tow_Location__Longitude__s, 
                RAP_Case_Number__c, 
                Original_Member_Id__c, 
                T_Code__c, 
                FSL_Pacesetter__c, 
                ContactId,
            	WorkOrder_ChannelType__c,
            	Timezone_Id__c,
            	Timezone_Offset__c,
            	Case_Pacesetter_Code__c,
            	Case_T_Code__c
            FROM WorkOrder 
            LIMIT 1
        ]; 
        
        return lstWO;
    }

    // Utility method to create mock ServiceAppointments linked to WorkOrders
    private static List<ServiceAppointment> createTestServiceAppointments(List<WorkOrder> workOrders, String serviceType) {
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        Id breakDownRecordTypeId = 
            Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByName()
                .get('Breakdown')
                .getRecordTypeId();
        Id towRecordTypeId = 
            Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByName()
                .get('Tow')
                .getRecordTypeId();
        ServiceTerritory svcTerritory = [SELECT Id FROM ServiceTerritory Limit 1];
        Id serviceRecordTypeId = null;

        if (serviceType == 'Breakdown') {
            serviceRecordTypeId = breakDownRecordTypeId;
        } else {
            serviceRecordTypeId = towRecordTypeId;
        }
        
        // Populate the list with ServiceAppointment records linked to WorkOrders
        for (WorkOrder wo : workOrders) {
            serviceAppointments.add(
                new ServiceAppointment(
                    ParentRecordId = wo.Id,
                    Status = 'Spotted',
                    recordTypeId = serviceRecordTypeId,
                    ServiceTerritoryId = svcTerritory.Id,
                    EarliestStartTime = System.now(),
                    Cleared_Timestamp__c = System.now(),
                    Address_Change_Counter__c = 1,
                    Subject = 'Tow Appointment',
                    DueDate = System.today() + 2
                )
            );
        }
        
        insert serviceAppointments;

        return serviceAppointments;
    }

    @isTest 
    static void testCreateWorkOrderEvent() {
        // Setup test data
        List<WorkOrder> testWorkOrders = createTestWorkOrders();

        Test.startTest();
        // Call the method under test
        FSL_PlatformEventsHandler.createWorkOrderEvent(testWorkOrders);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, testWorkOrders.size(), 'Work Orders should be created'); 
    }

    @isTest 
    static void testCreateStatusTrackingEvent() {
        // Setup test data
        List<WorkOrder> testWorkOrders = createTestWorkOrders();
        List<ServiceAppointment> testServiceAppointments = createTestServiceAppointments(testWorkOrders, 'Breakdown');

        Test.startTest();
        FSL_PlatformEventsHandler.createStatusTrackingEvent(testServiceAppointments);
        Test.stopTest();

       
        // Assertions
         System.assertEquals(1, testServiceAppointments.size(), 'Service Appointments should be created'); 
        
    }

    @isTest 
    static void testStatusUpdatesOnPlatformEvent() {
        // Setup test data
        List<WorkOrder> testWorkOrders = createTestWorkOrders();
        List<ServiceAppointment> testServiceAppointments = createTestServiceAppointments(testWorkOrders, 'Breakdown');

        Test.startTest();
        FSL_PlatformEventsHandler.statusUpdatesOnPlatformEvent(testServiceAppointments);
        Test.stopTest();

        // Assertions
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c Limit 1];
        System.assertEquals(1, apLogs.size(), 'Correct');
    }

    @isTest 
    static void teststatusClearOnPlatformEventBreakdown() {
        // Setup test data
        List<WorkOrder> testWorkOrders = createTestWorkOrders();
        List<ServiceAppointment> testServiceAppointments = createTestServiceAppointments(testWorkOrders, 'Breakdown');

        Test.startTest();
        FSL_PlatformEventsHandler.statusClearOnPlatformEvent(testServiceAppointments);
        Test.stopTest();
        
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c Limit 1];
        System.assertEquals(1, apLogs.size(), 'FSL_Application_Log Created');

    }
    
    @isTest 
    static void teststatusClearOnPlatformEventTow() {
        // Setup test data
        List<WorkOrder> testWorkOrders = createTestWorkOrders();
        List<ServiceAppointment> testServiceAppointments = createTestServiceAppointments(testWorkOrders, 'Tow');

        Test.startTest();
        FSL_PlatformEventsHandler.statusClearOnPlatformEvent(testServiceAppointments);
        Test.stopTest();

        // Assertions
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c Limit 1];
        System.assertEquals(1, apLogs.size(), 'FSL_Application_Log Created');
    }
}