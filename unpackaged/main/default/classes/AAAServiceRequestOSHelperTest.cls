@isTest
public class AAAServiceRequestOSHelperTest {
    @TestSetup
    static void makeData() {
        Date currDate = System.today();
        RecordType facTerritoryType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Territory' 
            AND SobjectType = 'ServiceTerritory' 
            LIMIT 1
        ];
        RecordType acctType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'ACG_Member' 
            AND SobjectType = 'Account' 
            LIMIT 1
        ];

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

        insert new ServiceContract(
            Name = 'APEXTEST-00001',
            AccountId = acct.Id,
            StartDate = currDate,
            AAA_ACA_Membership16ID__c = acct.ACG_AAA_Membership__c,
            EndDate = Date.newInstance(currDate.year() + 1, currDate.month(), currDate.day())
        );

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        Contract__c svcContract = new Contract__c(
            Name = 'APEXTESTINGCONTRACT'
        );
        insert svcContract;

        ServiceTerritory fac = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = 'APEXFAC22',
            City = 'FLUSHING',
            Contract__c = svcContract.Id,
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert fac;

        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

        insert new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = 'G201',
            ServiceTerritoryId = fac.Id,
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
            ContactId = contact.Id
        );

        insert new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 23',
            Status = 'Cleared',
            Resolution_Code__c = 'G201',
            ServiceTerritoryId = fac.Id,
            City = 'GARDEN CITY',
            Country = 'United States',
            PostalCode = '11530',
            State = 'NY',
            Street = '1415 KELLUM PL',
            Tow_City__c = 'GARDEN CITY',
            Tow_Country__c = 'United States',
            Tow_Postal_Code__c = '11530',
            Tow_State__c = 'NY',
            Tow_Street__c = '1415 KELLUM PL',
            Call_Origin__c = 'RAP',
            Call_Origin_OrgCode__c = '801',
            Call_Origin_OrgName__c = 'EDS',
            Call_Source__c = 'Salesforce',
            Call_Type__c = 'MEMBER',
            Clearing_Code__c = '01',
            ContactId = contact.Id
        );
    }

    @isTest
    static void getSvcTerritoryInfoTest() {
        ServiceTerritory fac = [
            SELECT Id, Facility_Number__c
            FROM ServiceTerritory
            WHERE Name = 'Apex Test Service Territory'
            AND Facility_Number__c = 'APEXFAC22'
        ];
        Date today = System.today();
        String username = 'apex@test.com';
        String batchId = username + fac.Facility_Number__c + today.month() + today.day() + today.year();
        String methodName = 'getSvcTerritoryInfo';
        Map<String, Object> input = new Map<String, Object>{
            'ContextId' => fac.Id,
            'userName' => username
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        Map<String, Object> resObj = (Map<String, Object>) output.get('svcTerritoryInfo');
        Map<String, Object> facRes = (Map<String, Object>) resObj.get('ServiceTerritory');
        String batchIdRes = (String) resObj.get('BatchId');

        System.assertEquals(fac.Id, (String) facRes.get('Id'), 'Failed to find Service Territory.');
        System.assertEquals(batchId, batchIdRes, 'Generated incorrect batch Id.');
    }

    @isTest
    static void setDefaultResAndClearCodeTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'setDefaultResAndClearCode';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        Map<String, Object> svcReqWrapper = (Map<String, Object>) output.get('Add Service Request');
        Map<String, Object> callInfoWrapper = (Map<String, Object>) svcReqWrapper.get('Call Information');
        String resCode = (String) callInfoWrapper.get('Resolution Code');
        String clearCode = (String) callInfoWrapper.get('Clear Code');

        System.assertEquals('N590', resCode, 'Unable to assign the appropriate Resolution Code.');
        System.assertEquals('RR', clearCode, 'Unable to assign the appropriate Clearing Code.');
    }

    @isTest
    static void getMemberServiceContractDetailsNETest() {
        String methodName = 'getMemberServiceContractDetails';
        Map<String, Object> input = new Map<String, Object>{
            'membershipId' => '4941373217'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        
        List<Map<String, Object>> resList = (List<Map<String, Object>>) output.get('ServiceContract');
        Map<String, Object> res = resList[0];

        System.assertEquals(res.containsKey('ServiceContractId'), true, 'Missing field.');
        System.assertEquals(res.containsKey('ServiceContractName'), true, 'Missing field.');
        System.assertEquals(res.containsKey('ACG_Billing_State_and_Zip__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Address'), true, 'Missing field.');
        System.assertEquals(res.containsKey('City'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Zip'), true, 'Missing field.');
        System.assertEquals(res.containsKey('State'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Street'), true, 'Missing field.');
        System.assertEquals(res.containsKey('FirstName'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Id'), true, 'Missing field.');
        System.assertEquals(res.containsKey('LastName'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Member_ID__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('MemberLevel'), true, 'Missing field.');
        System.assertEquals(res.containsKey('FullName'), true, 'Missing field.');
        System.assertEquals(res.containsKey('Phone'), true, 'Missing field.');
        System.assertEquals(res.containsKey('BatteryConsumed'), true, 'Missing field.');
        System.assertEquals(res.containsKey('AAA_Total_of_Calls_Consumed__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('AAA_Total_of_Calls_Remaining__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('LongTowConsumed'), true, 'Missing field.');
        System.assertEquals(res.containsKey('AAA_Total_of_Calls_Allowed__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('HomeLockoutConsumed'), true, 'Missing field.');
        System.assertEquals(res.containsKey('AAA_Total_of_Reciprocals__c'), true, 'Missing field.');
        System.assertEquals(res.containsKey('AbbrevClubCode'), true, 'Missing field.');
        System.assertEquals(res.containsKey('hasEntitlement'), true, 'Missing field.');
    }

    @isTest 
    static void getBreakdownLocationTest() {
        WorkOrder woLocation = [
            SELECT Id, Breakdown_Address__c
            FROM WorkOrder
            WHERE Call_Id__c = 'Apex Test Work Order 22'
            LIMIT 1
        ];
        String methodName = 'getBreakdownLocation';
        Map<String, Object> input = new Map<String, Object>{
            'breakdownAddress' => '1415 kell'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        List<Object> resList = (List<Object>) output.get('breakdownLocations');
        Map<String, Object> resObj = (Map<String, Object>) resList[0];

        System.assertEquals(1, resList.size(), 'Failed to find Breakdown Locations.');
        System.assertEquals(woLocation.Breakdown_Address__c, (String) resObj.get('address'), 'Incorrect Location found.');
    }

    @isTest 
    static void getTowLocationTest() {
        WorkOrder woLocation = [
            SELECT Id, Tow_Address__c
            FROM WorkOrder
            WHERE Call_Id__c = 'Apex Test Work Order 23'
            LIMIT 1
        ];
        String methodName = 'getTowLocation';
        Map<String, Object> input = new Map<String, Object>{
            'towAddress' => '1415 kell'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        List<Object> resList = (List<Object>) output.get('towLocations');
        Map<String, Object> resObj = (Map<String, Object>) resList[0];

        System.assertEquals(1, resList.size(), 'Failed to find Tow Locations.');
        System.assertEquals(woLocation.Tow_Address__c, (String) resObj.get('towAddress'), 'Incorrect Location found.');
    }

    @isTest
    static void getTroubleCodesTest() {
        Map<String, Object> input = new Map<String, Object>{
            'problemCode' => 't',
            'svcTerritoryInfo' => new Map<String, Object>{
                'ServiceTerritory' => new Map<String, Object>{
                    'State' => 'NJ'
                }
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'getTroubleCodes';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));
        List<Taxation_State_by_Problem_Codes__mdt> mockTCodes = mockTCodeWorkTypeMDT();
        Taxation_State_by_Problem_Codes__mdt expectedTCode = mockTCodes[0];
        List<Object> tCodes = (List<Object>) output.get('troubleCodes');
        Map<String, Object> tCode = (Map<String, Object>) tCodes[0];
        String code = (String) tCode.get('problemCode');
        String svcType = (String) tCode.get('svcType');

        System.assertEquals(expectedTCode.Problem_Code__c, code, 'Failed to find Trouble Code.');
    }

    @isTest
    static void setChargeToAccountTest() {
        Map<String, Object> input = new Map<String, Object>{
            'Add Service Request' => new Map<String, Object>{
                'Member Information' => new Map<String, Object>{
                    'Membership Id-Block' => new Map<String, Object>{
                        'MemberLevel' => 'Basic'
                    }
                }
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'setChargeToAccount';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        Map<String, Object> sliDetailsWrapper = (Map<String, Object>) output.get('AddServiceLineItems');
        Map<String, Object> sliDetails = (Map<String, Object>) sliDetailsWrapper.get('ServiceLineItemDetails');
        String chargeAcct = (String) sliDetails.get('ChargeToAccount');

        System.assertEquals('B', chargeAcct, 'Failed to set Charge To Account.');
    }

    @isTest
    static void validateInputTest() {
        Map<String, Object> input = new Map<String, Object>{
            'Add Service Request' => new Map<String, Object>{
                'Service Request Information' => new Map<String, Object> {
                    'Ticket Number' => '234532462546',
                    'ContextId' => 'I43H64H6HO3JH4O6J'
                }
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'validateInput';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        String res = (String) output.get('processedRes');

        System.assertEquals('good', res, 'Error validating input.');
    }

    @isTest
    static void processSvcReqInfoTest() {
        Account acct = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'APEX'
            AND LastName = 'TEST'
            LIMIT 1
        ];
        String methodName = 'processSvcReqInfo';
        Map<String, Object> input = mockOmniData(acct.Id, '');
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        List<WorkOrder> woList = [
            SELECT Id, WorkOrderNumber
            FROM WorkOrder
            WHERE AccountId = :acct.Id
            ORDER BY CreatedDate DESC
        ];
        Map<String, Object> resWrapper = (Map<String, Object>) output.get('AddServiceLineItems');
        Map<String, Object> resObj = (Map<String, Object>) resWrapper.get('ServiceLineItemDetails');
        String resWOId = (String) resObj.get('woId');
        String resWONum = (String) resObj.get('WorkOrderNbr2');
        WorkOrder wo = woList.size() > 0 ? (WorkOrder) woList[0] : new WorkOrder();

        System.assertEquals(wo.Id, resWOId, 'Failed to create Work Order.');
        System.assertEquals(wo.WorkOrderNumber, resWONum, 'Failed to create Work Order.');
    }

    @isTest
    static void getProductsTest() {
        ServiceTerritory fac = [
            SELECT Id
            FROM ServiceTerritory
            WHERE Facility_Number__c = 'APEXFAC22'
            LIMIT 1
        ];

        List<Product2> prod2List = new List<Product2>{
            new Product2(
                ProductCode = 'T1',
                Name = 'Test 1',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T2',
                Name = 'Test 2',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T3',
                Name = 'Test 3',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T4',
                Name = 'Test 4',
                IsActive = true,
                Family = 'Service Item'
            )
        };
        insert prod2List;

        insert new List<Facility_Service_Item__c>{
            new Facility_Service_Item__c(
                Facility__c = fac.Id,
                Product__c = prod2List[0].Id
            ),
            new Facility_Service_Item__c(
                Facility__c = fac.Id,
                Product__c = prod2List[2].Id
            )
        };

        String methodName = 'getProducts';
        Map<String, Object> input = new Map<String, Object>{
            'code' => 't',
            'facId' => fac.Id
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        
        List<Map<String, Object>> resList = (List<Map<String, Object>>) output.get('productList');
        
        System.assertEquals(resList.size(), 4, 'Failed to filter products.');
    }

    @isTest
    static void getSLIsTest() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        List<Product2> prod2List = new List<Product2>{
            new Product2(
                ProductCode = 'T1',
                Name = 'Test 1',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T2',
                Name = 'Test 2',
                IsActive = true,
                Family = 'Service Item'
            )
        };
        insert prod2List;

        insert new List<FSL_Service_Line_Item__c>{
            new FSL_Service_Line_Item__c(
                Product__c = prod2List[0].Id,
                Work_Order__c = wo.Id,
                Unit__c = 1
            ),
            new FSL_Service_Line_Item__c(
                Product__c = prod2List[1].Id,
                Work_Order__c = wo.Id,
                Unit__c = 1
            )
        };
        
        Map<String, Object> input = new Map<String, Object>{
            'WorkOrderId' => wo.Id
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'getSLIs';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        List<Object> resList = (List<Object>) output.get('sli');

        System.assertEquals(2, resList.size(), 'Failed to fetch SLIs.');
    }

    @isTest
    static void createSLIsTest() {
        Product2 prod = new Product2(
            ProductCode = 'T1',
            Name = 'Test 1',
            IsActive = true,
            Family = 'Service Item'
        );
        insert prod;

        Account acct = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'APEX'
            AND LastName = 'TEST'
            LIMIT 1
        ];
        String methodName = 'processSvcReqInfo';
        Map<String, Object> input = mockOmniData(acct.Id, '');
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        List<WorkOrder> woList = [
            SELECT Id
            FROM WorkOrder
        ];
        WorkOrder wo = woList.size() > 0 ? (WorkOrder) woList[0] : new WorkOrder();

        methodName = 'createSLIs';
        input = new Map<String, Object>{
            'CreateServiceLineItem' => new Map<String, Object>{
                'ChargeToAccount' => 'B',
                'Cost' => 5.00,
                'Tax' => 0.00,
                'Quantity' => 0.00,
                'OverridePricing' => false,
                'ProductLookup-Block' => new Map<String, Object>{
                    'ProductId' => prod.Id
                }
            },
            'WorkOrderId' => wo.Id
        };
        output = new Map<String, Object>();

        remoteClass.invokeMethod(methodName, input, output, options);

        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        List<Object> resSLIWrapper = (List<Object>) output.get('sli');
        Map<String, Object> resSLI = (Map<String, Object>) resSLIWrapper[0];

        System.assertEquals(resSLI.get('Product_Code__c'), prod.ProductCode, 'Failed to create the appropriate Service Line Item.');
    }

    @isTest
    static void updateSLITest() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Product2 prod = new Product2(
            ProductCode = 'T1',
            Name = 'Test 1',
            IsActive = true,
            Family = 'Service Item'
        );
        insert prod;

        FSL_Service_Line_Item__c sli = new FSL_Service_Line_Item__c(
            Product__c = prod.Id,
            Work_Order__c = wo.Id,
            Unit__c = 1
        );
        insert sli;

        Map<String, Object> input = new Map<String, Object>{
            'newOvrd' => false,
            'newQty' => 10.0,
            'newCost' => null,
            'newTax' => null,
            'sliId' => sli.Id
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'updateSLI';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);
        output = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(output));

        List<Object> resList = (List<Object>) output.get('sli');
        Map<String, Object> resSLI = (Map<String, Object>) resList[0];
        Decimal resUnits = (Decimal) resSLI.get('Unit__c');

        System.assertEquals((Decimal) input.get('newQty'), resUnits, 'Failed to update SLI.');
    }

    @isTest
    static void deleteSLITest() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Product2 prod = new Product2(
            ProductCode = 'T1',
            Name = 'Test 1',
            IsActive = true,
            Family = 'Service Item'
        );
        insert prod;

        FSL_Service_Line_Item__c sli = new FSL_Service_Line_Item__c(
            Product__c = prod.Id,
            Work_Order__c = wo.Id,
            Unit__c = 1
        );
        insert sli;

        Map<String, Object> input = new Map<String, Object>{
            'sliId' => sli.Id,
            'WorkOrderId' => wo.Id
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'deleteSLI';
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        String res = (String) output.get('sli');

        System.assertEquals('success', res, 'Failed to delete SLI.');
    }

    @isTest
    static void createComment() {
        Account acct = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'APEX'
            AND LastName = 'TEST'
            LIMIT 1
        ];
        String methodName = 'processSvcReqInfo';
        Map<String, Object> input = mockOmniData(acct.Id, '');
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAServiceRequestOSHelper remoteClass = new AAAServiceRequestOSHelper();

        remoteClass.invokeMethod(methodName, input, output, options);

        List<WorkOrder> woList = [
            SELECT Id
            FROM WorkOrder
        ];
        WorkOrder wo = woList.size() > 0 ? (WorkOrder) woList[0] : new WorkOrder();

        methodName = 'createComment';
        input = mockOmniData(acct.Id, wo.Id);
        output = new Map<String, Object>();

        remoteClass.invokeMethod(methodName, input, output, options);
        
        List<FSL_Call_Comments__c> callCommentList = [
            SELECT Id
            FROM FSL_Call_Comments__c
            WHERE FSL_Work_Order__c = :wo.Id
        ];

        System.assertEquals(1, callCommentList.size(), 'Failed to create Call Comments.');
    }

    public static List<Taxation_State_by_Problem_Codes__mdt> mockTCodeWorkTypeMDT() {
        return new List<Taxation_State_by_Problem_Codes__mdt>{
            new Taxation_State_by_Problem_Codes__mdt(
                Problem_Code__c = '6T',
                State__c = 'NJ'
            ),
            new Taxation_State_by_Problem_Codes__mdt(
                Problem_Code__c = '9',
                State__c = 'MA'
            )
        };
    }

    private static Map<String, Object> mockOmniData(String acctId, String woId) {
        ServiceTerritory fac = [
            SELECT Id
            FROM ServiceTerritory
            WHERE Facility_Number__c = 'APEXFAC22'
            LIMIT 1
        ];
        ServiceContract svcCont = [
            SELECT Id
            FROM ServiceContract
            WHERE Name = 'APEXTEST-00001'
            LIMIT 1
        ];
        String mockData = '{"ContextId":"' + fac.Id + '","timeStamp":"2024-03-10T20:39:24.345Z","userProfile":"System Administrator","userTimeZoneName":"America/New_York","userTimeZone":"-240","userCurrencyCode":"USD","userName":"apex@salesforce.com","userId":"005Ek000003E1LtIAK","omniProcessId":"0jNEk0000000iCLMAY","localTimeZoneName":"America/Denver","svcTerritoryInfo":{"isTypeTow":false,"BatchId":"apex@salesforce.com54546543102024","ServiceTerritory":{"attributes":{"type":"ServiceTerritory","url":"/services/data/v60.0/sobjects/ServiceTerritory/' + fac.Id + '"},"Id":"' + fac.Id + '","Comm_Ctr__c":"097","Facility_Number__c":"5454654","State":"NJ"}},"Add Service Request":{"Member Information":{"Membership Id-Block":{"BatteryConsumed":false,"LongTowConsumed":false,"HomeLockoutConsumed":true,"Membership Id":"6202404500461006","hasEntitlement":true,"Member_ID__c":"6202404500461006","LastName":"LANGELLO","Id":"' + acctId + '","FirstName":"TYLER","Address":{"city":"EAST PROVIDENCE","country":"United States","countryCode":"US","geocodeAccuracy":null,"latitude":null,"longitude":null,"postalCode":"02914","state":"RI","stateCode":"RI","street":"11100192 MAIN ST"},"ACG_Billing_State_and_Zip__c":"RI 02914","ServiceContractName":"4500461-00","ServiceContractId":"' + svcCont.Id + '","AbbrevClubCode":"240","AAA_Total_of_Reciprocals__c":0,"AAA_Total_of_Calls_Allowed__c":4,"AAA_Total_of_Calls_Remaining__c":0,"AAA_Total_of_Calls_Consumed__c":7,"Phone":"4015559926","FullName":"TYLER LANGELLO","MemberLevel":"Basic","Street":"11100192 MAIN ST","State":"RI","Zip":"02914","City":"EAST PROVIDENCE"},"Charge entitlement":true},"Service Request Information":{"Comm Ctr":"097","BatchID":"apex@salesforce.com54546543102024","Ticket Number":"45234532452345245","Call Date":"2024-03-10"},"Call Information":{"Call Type":"SVC","Resolution Code":"G103","Clear Code":"01","problemCode-Block":{"problemCode": "L101","svcType": "Light Service"},"ProblemDescription":"SOMETHING"},"Vehicle Information":{"Vehicle Year":"1989","Vehicle Make":"DODGE","Vehicle Model":"TOYOTA","Vehicle Tag":"IDKHELP"},"Breakdown Information":{"Breakdown Location Address-Block":{"Breakdown Location Address":"5322 Date Ave, Sacramento, CA 95841","breakdownPostalCode":"95841","breakdownState":"CA","breakdownCity":"Sacramento","breakdownStreet":"5322 Date Ave","address":"5322 Date Ave, Sacramento, CA 95841","Breakdown_Location__Longitude__s":-121.3562551,"Breakdown_Location__Latitude__s":38.6633075}},"Tow Destination":{"Tow Destination Address-Block":{"Tow Destination Address":"400 116th Ave NE, Bellevue, NY 7631","towPostalCode":"7631","towState":"NY","towCity":"Bellevue","towStreet":"400 116th Ave NE","towAddress":"400 116th Ave NE, Bellevue, NY 7631","Tow_Location__Longitude__s":-122.1850841,"Tow_Location__Latitude__s":47.6132943}}},"AddServiceLineItems":{"ServiceLineItemDetails":{"woId":"' + woId + '","OverridePricing":false,"Cost":null,"Tax":null,"WorkOrderNbr2":"00039978","ProductLookup-Block":{"ProductLookup":null,"ProductId":null,"ProductCode":null,"ProductName":null},"Quantity":null,"Product":null,"ChargeToAccount":null},"CallComments":"testing"}}';

        return (Map<String, Object>) JSON.deserializeUntyped(mockData);
    }
}