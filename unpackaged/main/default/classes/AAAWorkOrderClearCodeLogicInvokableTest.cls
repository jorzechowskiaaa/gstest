@isTest
class AAAWorkOrderClearCodeLogicInvokableTest {
    @isTest
    static void clearCodeLogicACATest1() {
        Map<String, String> params = new Map<String, String>{
            'clubCode' => 'TTT',
            'facNum' => 'TEST',
            'resCode' => 'G201',
            'clearCode' => '01'
        };
        Map<String, Object> dataMap = setupTestData(params);
        WorkOrder wo = (WorkOrder) dataMap.get('wo');
        List<FSL_Service_Line_Item__c> sliList = (List<FSL_Service_Line_Item__c>) dataMap.get('sliList');

        List<FSL_TroubleCode__c> tcList = new List<FSL_TroubleCode__c>{
            new FSL_TroubleCode__c(
                Work_Order__c = wo.Id,
                Code__c = '6',
                Description__c = 'Apex Test Trouble Code 1',
                Type__c = 'ApexTest'
            ),
            new FSL_TroubleCode__c(
                Work_Order__c = wo.Id,
                Code__c = '1',
                Description__c = 'Apex Test Trouble Code 2',
                Type__c = 'ApexTest'
            )
        };
        insert tcList;

        Map<String, Object> resMap = callClearCodeLogic(wo, sliList);
        WorkOrder resWO = (WorkOrder) resMap.get('wo');
        List<FSL_Service_Line_Item__c> resSLIs = (List<FSL_Service_Line_Item__c>) resMap.get('sliList');

        System.assertEquals(resWO.Clearing_Code__c, 'XX', 'Failed to update Work Order.');

        for (FSL_Service_Line_Item__c sli : resSLIs) {
            if (sli.Product_Code__c == 'TW') {
                System.assertEquals(sli.Unit__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Cost__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Override_Pricing__c, true, 'Failed to update SLI.');
            }

            if (sli.Product_Code__c == 'WN') {
                System.assertEquals(sli.Unit__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Cost__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Override_Pricing__c, true, 'Failed to update SLI.');
            }
        }
    }

    @isTest
    static void clearCodeLogicACATest2() {
        Map<String, String> params = new Map<String, String>{
            'clubCode' => 'TTT',
            'facNum' => 'TEST',
            'resCode' => 'N101',
            'clearCode' => '01'
        };
        Map<String, Object> dataMap = setupTestData(params);
        WorkOrder wo = (WorkOrder) dataMap.get('wo');
        List<FSL_Service_Line_Item__c> sliList = (List<FSL_Service_Line_Item__c>) dataMap.get('sliList');
        Map<String, Object> resMap = callClearCodeLogic(wo, sliList);
        List<FSL_Service_Line_Item__c> resSLIs = (List<FSL_Service_Line_Item__c>) resMap.get('sliList');

        for (FSL_Service_Line_Item__c sli : resSLIs) {
            if (sli.Product_Code__c == 'MA') {
                System.assertEquals(sli.Unit__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Cost__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Unit_Price__c, 0, 'Failed to update SLI.');
                System.assertEquals(sli.Override_Pricing__c, true, 'Failed to update SLI.');
            }
        }
    }

    @isTest
    static void clearCodeLogicNETest() {
        Map<String, String> params = new Map<String, String>{
            'clubCode' => '240',
            'facNum' => 'TEST',
            'resCode' => 'X001',
            'clearCode' => '01'
        };
        Map<String, Object> dataMap = setupTestData(params);
        WorkOrder wo = (WorkOrder) dataMap.get('wo');
        List<FSL_Service_Line_Item__c> sliList = (List<FSL_Service_Line_Item__c>) dataMap.get('sliList');
        Map<String, Object> resMap = callClearCodeLogic(wo, sliList);
        List<FSL_Service_Line_Item__c> resSLIs = (List<FSL_Service_Line_Item__c>) resMap.get('sliList');

        for (FSL_Service_Line_Item__c sli : resSLIs) {
            if (sli.Product_Code__c == 'TW') {
                System.assertEquals(sli.Unit__c, null, 'Failed to update SLI.');
                System.assertEquals(sli.Cost__c, null, 'Failed to update SLI.');
                System.assertEquals(sli.Calculated_Unit__c, null, 'Failed to update SLI.');
                System.assertEquals(sli.Override_Pricing__c, true, 'Failed to update SLI.');
            }
        }
    }

    private static Map<String, Object> setupTestData(Map<String, String> params) {
        String clubCode = params.get('clubCode');
        String facNum = params.get('facNum');
        String resCode = params.get('resCode');
        String clearCode = params.get('clearCode');
        RecordType acctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' AND SobjectType = 'Account' LIMIT 1];
        RecordType woTWType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Tow' AND SobjectType = 'WorkOrder' LIMIT 1];

        BackOffice_Settings__c boSettings = new BackOffice_Settings__c(
            Club_Code__c = clubCode
        );
        insert boSettings;

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

        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

        ServiceTerritory svcTerritory = setupFacility(facNum);

        WorkOrder wo = new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = resCode,
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
            Clearing_Code__c = clearCode,
            ContactId = contact.Id,
            In_Tow_Timestamp__c = System.today(),
            On_Location_Timestamp__c = System.today(),
            RecordType = woTWType
        );
        insert wo;

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
                Name = 'WN',
                ProductCode = 'WN',
                QuantityUnitOfMeasure = 'Each'
            ),
            new Product2(
                Club__c = 'NE',
                Family = 'Service Item',
                IsActive = true,
                Name = 'MX',
                ProductCode = 'MX',
                QuantityUnitOfMeasure = 'Each'
            ),
            new Product2(
                Club__c = 'NE',
                Family = 'Service Item',
                IsActive = true,
                Name = 'MA',
                ProductCode = 'MA',
                QuantityUnitOfMeasure = 'Each'
            ),
            new Product2(
                Club__c = 'NE',
                Family = 'Service Item',
                IsActive = true,
                Name = 'BA',
                ProductCode = 'BA',
                QuantityUnitOfMeasure = 'Each'
            )
        };
        insert prodList;

        List<FSL_Service_Line_Item__c> sliList = new List<FSL_Service_Line_Item__c>();
        for (Product2 prod : prodList) {
            sliList.add(
                new FSL_Service_Line_Item__c(
                    Work_Order__c = wo.Id,
                    Product__c = prod.Id
                )
            );
        }
        insert sliList;

        List<FSL_Service_Line_Item__c> sliQueryList = [
            SELECT
                Id,
                Product_Code__c,
                Unit__c,
                Cost__c,
                Unit_Price__c,
                Override_Pricing__c
            FROM FSL_Service_Line_Item__c
            WHERE Work_Order__c = :wo.Id
        ];

        WorkOrder woQuery = [
            SELECT
                Id,
                Record_Type_Dev_Name__c,
                ServiceTerritoryId,
                Clearing_Code__c,
                Resolution_Code__c,
                In_Tow_Timestamp__c,
                On_Location_Timestamp__c
            FROM WorkOrder
            WHERE Id = :wo.Id
            LIMIT 1
        ];

        return new Map<String, Object>{
            'wo' => woQuery,
            'sliList' => sliQueryList
        };
    }

    private static ServiceTerritory setupFacility(String facNum) {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];

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
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = facNum,
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

        return svcTerritory;
    }

    private static Map<String, Object> callClearCodeLogic(
        WorkOrder wo, List<FSL_Service_Line_Item__c> sliList
    ) {
        AAAWorkOrderClearCodeLogicInvokable.FlowInput input = new AAAWorkOrderClearCodeLogicInvokable.FlowInput();

        input.sliList = sliList;
        input.workOrder = wo;

        List<AAAWorkOrderClearCodeLogicInvokable.FlowOutput> resList = AAAWorkOrderClearCodeLogicInvokable.runClearCodeLogic(
            new List<AAAWorkOrderClearCodeLogicInvokable.FlowInput>{input}
        );

        return new Map<String, Object>{
            'wo' => resList[0].workOrder,
            'sliList' => resList[0].outputList
        };
    }
}