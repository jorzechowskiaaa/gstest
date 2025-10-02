@isTest
public class AAACreateOMAndTWSLIsTest {
    // for http GET request to google maps
    private class MockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String reqEndpoint = req.getEndpoint();
            String bodyJSONStr = '';

            if (reqEndpoint.contains('https://12345.com/')) {
                bodyJSONStr = '{' +
                        '\"routes\": [' +
                                '{' + 
                                    '\"legs\": [' +
                                        '{' +
                                            '\"distance\": {' +
                                                '\"text\": \"12345.2 m mi.\"' +
                                            '}' +
                                    '}' +
                                ']' +
                            '}' +
                        ']' +
                    '}';
            }
            
            res.setHeader('Content-Type', 'application/json');
            res.setBody(bodyJSONStr);
            res.setStatusCode(200);
    
            return res;
        }
    }

    @isTest
    static void createOMAndTWSLIsTest1() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        Test.startTest();
        WorkOrder wo = invokable('From Service Territory');
        Test.stopTest();

        AAACreateOMAndTWSLIs.FlowInput flowInput = new AAACreateOMAndTWSLIs.FlowInput();

        flowInput.workOrder = wo;

        List<AAACreateOMAndTWSLIs.FlowOutput> resList = AAACreateOMAndTWSLIs.runCreateOMAndTWSLIs(
            new List<AAACreateOMAndTWSLIs.FlowInput>{flowInput}
        );
        List<FSL_Service_Line_Item__c> resSLI = resList[0].outputList;

        System.assertEquals(resSLI[0].Unit__c, 12346, 'Failed to create SLI.');
        System.assertEquals(resSLI[0].Calculated_Unit__c, 12346, 'Failed to create SLI.');
    }

    @isTest
    static void createOMAndTWSLIsTest2() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
    
        Test.startTest();
        WorkOrder wo = invokable('From Driver Location');
        Test.stopTest();

        AAACreateOMAndTWSLIs.FlowInput flowInput = new AAACreateOMAndTWSLIs.FlowInput();

        flowInput.workOrder = wo;

        List<AAACreateOMAndTWSLIs.FlowOutput> resList = AAACreateOMAndTWSLIs.runCreateOMAndTWSLIs(
            new List<AAACreateOMAndTWSLIs.FlowInput>{flowInput}
        );
        List<FSL_Service_Line_Item__c> resSLI = resList[0].outputList;

        System.assertEquals(resSLI[0].Unit__c, 12346, 'Failed to create SLI.');
        System.assertEquals(resSLI[0].Calculated_Unit__c, 12346, 'Failed to create SLI.');
    }

    @isTest
    static void createOMAndTWSLIsTest3() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
    
        Test.startTest();
        WorkOrder wo = invokable('From Service Territory');
        List<String> prodCodes = new List<String>{'OM', 'TW'};
        List<Product2> productList = [
            SELECT Id
            FROM Product2
            WHERE ProductCode IN :prodCodes
        ];

        List<FSL_Service_Line_Item__c> sliList = new List<FSL_Service_Line_Item__c>{
            new FSL_Service_Line_Item__c(
                Work_Order__c = wo.Id,
                Product__c = productList[0].Id,
                Unit__c = 23,
                Cost__c = 100.0,
                Override_Pricing__c = false
            ),
            new FSL_Service_Line_Item__c(
                Work_Order__c = wo.Id,
                Product__c = productList[1].Id,
                Unit__c = 20,
                Cost__c = 20.0,
                Override_Pricing__c = false
            )
        };
        insert sliList;
        Test.stopTest();

        AAACreateOMAndTWSLIs.FlowInput flowInput = new AAACreateOMAndTWSLIs.FlowInput();

        flowInput.workOrder = wo;
        flowInput.recalMileage = true;

        AAACreateOMAndTWSLIs.runCreateOMAndTWSLIs(new List<AAACreateOMAndTWSLIs.FlowInput>{flowInput});

        List<String> sliIds = new List<String>{sliList[0].Id, sliList[1].Id};
        List<FSL_Service_Line_Item__c> resList = [
            SELECT Id, Unit__c, Product_Code__c
            FROM FSL_Service_Line_Item__c
            WHERE Id IN :sliIds
            ORDER BY Product_Code__c
        ];

        for (FSL_Service_Line_Item__c sli : resList) {
            if (sli.Product_Code__c == 'OM') {
                System.assertEquals(12346.0, sli.Unit__c, 'Failed to update mileage.');
            }
        }
    }

    private static WorkOrder invokable(String calcMileage) {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType acctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' AND SobjectType = 'Account' LIMIT 1];
        RecordType woTWType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Tow' AND SobjectType = 'WorkOrder' LIMIT 1];

        insert new BackOffice_Settings__c(
            Club_Code__c = '240'
        );

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

        Contract__c svcContract = new Contract__c(
            Name = 'APEXTESTINGCONTRACT'
        );
        insert svcContract;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = calcMileage,
            isActive = true,
            Facility_Number__c = 'TEST',
            City = 'FLUSHING',
            Contract__c = svcContract.Id,
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert svcTerritory;

        List<Product2> prodList = new List<Product2>{
            new Product2(
                Club__c = 'NE',
                Family = 'Service Item',
                IsActive = true,
                Name = 'TW-Tow',
                ProductCode = 'TW',
                QuantityUnitOfMeasure = 'Each'
            ),
            new Product2(
                Club__c = 'NE',
                Family = 'Service Item',
                IsActive = true,
                Name = 'Enroute Mileage',
                ProductCode = 'OM',
                QuantityUnitOfMeasure = 'Each'
            )
        };
        insert prodList;

        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

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
            Clearing_Code__c = '01',
            ContactId = contact.Id,
            RecordType = woTWType
        );
        insert wo;

        Integration_Settings__c mockAPISettings = new Integration_Settings__c(
            API_Key__c = '12345',
            Enpoint_URL__c = 'https://12345.com/',
            Name = 'Google_Directions_API'
        );
        insert mockAPISettings;

        return [
            SELECT
                Id,
                Call_Id__c,
                Status,
                Resolution_Code__c,
                ServiceTerritoryId,
                City,
                Country,
                PostalCode,
                State,
                Street,
                Call_Origin__c,
                Call_Origin_OrgCode__c,
                Call_Origin_OrgName__c,
                Call_Source__c,
                Call_Type__c,
                Clearing_Code__c,
                ContactId,
                Facility_Calculated_Mileage_Type__c,
                Record_Type_Dev_Name__c,
                Breakdown_Location__Latitude__s,
                Latitude,
                Breakdown_Location__Longitude__s,
                Longitude,
                Facility_Latitude__c,
                Facility_Longitude__c,
                Tow_Location__Latitude__s,
                Tow_Latitude__c,
                Tow_Location__Longitude__s,
                Tow_Longitude__c,
                Facility_Calculated_Tow_Mileage__c
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];
    }

    public static List<ServiceAppointment> mockServiceAppointments(String woId) {
        return new List<ServiceAppointment>{
            new ServiceAppointment(
                Subject = 'Breakdown Appointment',
                Work_Order__c = woId
            ),
            new ServiceAppointment(
                Subject = 'Tow Appointment',
                Work_Order__c = woId
            )
        };
    }

    public static List<Service_Appointment_Status_Location__c> mockSALocations(String woId) {
        return new List<Service_Appointment_Status_Location__c>{
            new Service_Appointment_Status_Location__c(
                End_States__c = 'ER - Cancelled_Clear',
                From_Latitude__c = 42.576812,
                From_Longitude__c = -72.605955,
                Work_Order__c = woId
            )
        };
    }
}