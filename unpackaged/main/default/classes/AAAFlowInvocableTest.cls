@isTest
public class AAAFlowInvocableTest {
    @isTest
    static void getSLIPricesOnRESTTest() {
        Boolean hasException = false;

        Test.startTest();
        WorkOrder wo = setupTowSLIs('G101', '000');
        Test.stopTest();

        List<FSL_Service_Line_Item__c> sliList = [
            SELECT
                Id,
                Product__c,
                Product_Code__c,
                Work_Order__c,
                Cost__c,
                Unit__c,
                Calculated_Unit__c,
                Tax__c,
                Override_Pricing__c,
                Total_Price__c,
                Cleared_Timestamp_TOD_Code__c,
                Requested_Unit__c,
                Requested_Cost__c,
                Charge_to_Account__c,
                Ready_for_Invoicing__c
            FROM FSL_Service_Line_Item__c
            WHERE Work_Order__c = :wo.Id
        ];

        try {
            List<AAAFlowInvocable.FlowInput> flowInputList = new List<AAAFlowInvocable.FlowInput>();
            AAAFlowInvocable.FlowInput flowInput = new AAAFlowInvocable.FlowInput();

            flowInput.wo = wo;
            flowInput.sliList = sliList;
            flowInput.flowAPIName = 'Get_SLI_Prices_On_REST_AutoLaunched';
            flowInputList.add(flowInput);

            AAAFlowInvocable.runFlowInvocable(flowInputList);
        } catch (Exception e) {
            hasException = true;
        }

        System.assertEquals(false, hasException, 'Failed to run method.');
    }

    @isTest
    static void getSLIPricesOnRESTMiniBatchTest() {
        Boolean hasException = false;

        Test.startTest();
        WorkOrder wo = setupTowSLIs('G101', '000');
        Test.stopTest();

        List<FSL_Service_Line_Item__c> sliList = [
            SELECT
                Id,
                Product__c,
                Product_Code__c,
                Work_Order__c,
                Cost__c,
                Unit__c,
                Calculated_Unit__c,
                Tax__c,
                Override_Pricing__c,
                Total_Price__c,
                Cleared_Timestamp_TOD_Code__c,
                Requested_Unit__c,
                Requested_Cost__c,
                Charge_to_Account__c,
                Ready_for_Invoicing__c
            FROM FSL_Service_Line_Item__c
            WHERE Work_Order__c = :wo.Id
        ];

        try {
            List<AAAFlowInvocable.FlowInput> flowInputList = new List<AAAFlowInvocable.FlowInput>();
            AAAFlowInvocable.FlowInput flowInput = new AAAFlowInvocable.FlowInput();

            flowInput.wo = wo;
            flowInput.sli = sliList[0];
            flowInput.flowAPIName = 'Get_SLI_Prices_On_REST_AutoLaunched_insert/update';
            flowInputList.add(flowInput);

            AAAFlowInvocable.runFlowInvocable(flowInputList);
        } catch (Exception e) {
            hasException = true;
        }

        System.assertEquals(false, hasException, 'Failed to run method.');
    }

    @isTest
    static void runTaxationAutolaunchedFlowTest() {
        WorkOrder wo = setupTowSLIs('G101', '000');
        List<FSL_Service_Line_Item__c> sliList = [
            SELECT
                Id,
                Product__c,
                Product_Code__c,
                Work_Order__c,
                Cost__c,
                Unit__c,
                Calculated_Unit__c,
                Tax__c,
                Override_Pricing__c,
                Total_Price__c
            FROM FSL_Service_Line_Item__c
            WHERE Work_Order__c = :wo.Id
        ];
        AAAFlowInvocable.FlowInput flowInput = new AAAFlowInvocable.FlowInput();

        flowInput.flowAPIName = 'Taxation_Autolaunched_Flow';
        flowInput.sliList = sliList;
        flowInput.wo = wo;

        List<AAAFlowInvocable.FlowOutput> flowOutput = AAAFlowInvocable.runFlowInvocable(
            new List<AAAFlowInvocable.FlowInput>{flowInput}
        );
        List<FSL_Service_Line_Item__c> resSLIList = flowOutput[0].sliList;
        FSL_Service_Line_Item__c resSLI = resSLIList[0];

        System.assertEquals(resSLI.Ready_for_Invoicing__c, true, 'Failed to tax SLI.');
        System.assertEquals(resSLI.Product_Code__c, 'TW', 'Failed to tax SLI.');
        System.assertEquals(resSLI.Cost__c, 15.0, 'Failed to tax SLI.');
        System.assertEquals(resSLI.Tax__c, 1.33, 'Failed to tax SLI.');
    }

    @isTest
    static void roundUpSLIUnitsNETest() {
        BackOffice_Settings__c boSettings = new BackOffice_Settings__c(
            Club_Code__c = '240'
        );
        insert boSettings;
        
        //AGB 2/25/25 for SSFI-976
        List<Product2> productList = new List<Product2>{
            new Product2(IsActive = true, ProductCode = 'TW',Name = 'TW - TOW MILEAGE'),
            new Product2(IsActive = true, ProductCode = 'OM',Name = 'EN ROUTE MILEAGE'),
            new Product2(IsActive = true, ProductCode = 'XX',Name = 'RAP - CANCEL WITHOUT PAYMENT')
        };
        insert productList;
        Map<String, Id> prodMap = new Map<String, Id>();
        for(Product2 p: productList)
        {
            prodMap.put(p.ProductCode, p.Id);
        }

        List<FSL_Service_Line_Item__c> sliList = new List<FSL_Service_Line_Item__c>{
            new FSL_Service_Line_Item__c(
                Unit__c = 1.1,
                Calculated_Unit__c = 2.1,
                Product__c = prodMap.get('TW')
            ),
            new FSL_Service_Line_Item__c(
                Unit__c = 2.4,
                Calculated_Unit__c = 3.4,
                Product__c = prodMap.get('OM')
            ),
            new FSL_Service_Line_Item__c(
                Unit__c = 3.3,
                Calculated_Unit__c = 4.3,
                Product__c = prodMap.get('XX')
            )
        };
        AAAFlowInvocable.FlowInput input = new AAAFlowInvocable.FlowInput();

        input.sliList = sliList;
        input.flowAPIName = 'Round Up Units NE';

        List<AAAFlowInvocable.FlowOutput> resOutput = AAAFlowInvocable.runFlowInvocable(
            new List<AAAFlowInvocable.FlowInput>{input}
        );
        List<FSL_Service_Line_Item__c> resList = resOutput[0].sliList;

        System.assertEquals(resList[0].Unit__c, 2, 'Failed to round up SLI quantity.');
        System.assertEquals(resList[0].Calculated_Unit__c, 3, 'Failed to round up SLI quantity.');
        System.assertEquals(resList[1].Unit__c, 3, 'Failed to round up SLI quantity.');
        System.assertEquals(resList[1].Calculated_Unit__c, 4, 'Failed to round up SLI quantity.');
        System.assertEquals(resList[2].Unit__c, 3.3, 'Rounding should not occur.');
        System.assertEquals(resList[2].Calculated_Unit__c, 4.3, 'Rounding should not occur.');
    }

    public static List<Taxation_Excluded_SLI_By_Club__mdt> mockTaxExclusionMDT() {
        String jsonStr = '[{"Product_Code__c":"BS"},{"Product_Code__c":"FL","State__c":"NJ"},{"Product_Code__c":"FL","State__c":"NY"},{"Product_Code__c":"MA"},{"Product_Code__c":"MB"},{"Product_Code__c":"RI"},{"Product_Code__c":"TL"}]';

        return (List<Taxation_Excluded_SLI_By_Club__mdt>) JSON.deserialize(jsonStr, List<Taxation_Excluded_SLI_By_Club__mdt>.Class);
    }

    public static List<FSL_Service_Line_Item__c> mockTaxSLIResult(List<FSL_Service_Line_Item__c> sliList) {
        FSL_Service_Line_Item__c sli = sliList[0];
        String jsonStr = '[{"Id":"' + sli.Id +'","Charge_to_Account__c":"B","Cleared_Timestamp_TOD_Code__c":"D 06:00-18:59","Cost__c":15,"Facility__c":"Apex Test Service Territory","Override_Pricing__c":false,"Product__c":"' + sli.Product__c + '","Product_Code__c":"TW","Unit__c":5,"Ready_for_Invoicing__c":true,"Tax__c":1.33,"Work_Order__c":"' + sli.Work_Order__c + '","Reason_for_Decision__c":""}]';

        return (List<FSL_Service_Line_Item__c>) JSON.deserialize(jsonStr, List<FSL_Service_Line_Item__c>.Class);
    }

    public static WorkOrder setupTowSLIs(String resCode, String clubCode) {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType acctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' AND SobjectType = 'Account' LIMIT 1];
        RecordType rliType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service_Item' AND SobjectType = 'Rate_Line_Item__c' LIMIT 1];
        RecordType invcType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ERS' AND SobjectType = 'Invoice__c' LIMIT 1];
        Date currDate = System.today();
        Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
        Boolean isNEOrg = orgData.Name == 'AAA Northeast';
        
        BackOffice_Settings__c customSettingHelper = new BackOffice_Settings__c(
            Club_Code__c = clubCode
        );
        insert customSettingHelper;

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

        Product2 prodTw = new Product2(
            Club__c = 'NE',
            Family = 'Service Item',
            IsActive = true,
            Name = 'TW-Tow',
            ProductCode = 'TW',
            QuantityUnitOfMeasure = 'Each'
        );
        insert prodTw;

        Rate_Line_Item__c rli1 = new Rate_Line_Item__c(
            Calculation_Type__c = 'Unit',
            Charge_to_Account__c = 'B',
            Contract__c = svcContract.Id,
            End_Date__c = Date.newInstance(currDate.year() + 1, currDate.month(), currDate.day()),
            Fixed_Amount__c = 3,
            Has_Overlapping_Date__c = false,
            Max_Data_Range__c = 122,
            Min_Data_Range__c = 0,
            Product__c = prodTw.Id,
            RecordTypeId = rliType.Id,
            Service_Type_Picklist__c = 'Basic',
            Start_Date__c = currDate/*,
            Time_of_Day_Code__c = isNEOrg ? 'D 06:00-18:59' : 'DA - 07:00-22:59'*/
        );
        insert rli1;

        // Rate_Line_Item__c rli2 = new Rate_Line_Item__c(
        //     Calculation_Type__c = 'Unit',
        //     Charge_to_Account__c = 'B',
        //     Contract__c = svcContract.Id,
        //     End_Date__c = Date.newInstance(currDate.year() + 1, currDate.month(), currDate.day()),
        //     Fixed_Amount__c = 3,
        //     Has_Overlapping_Date__c = false,
        //     Max_Data_Range__c = 122,
        //     Min_Data_Range__c = 0,
        //     Product__c = prodTw.Id,
        //     RecordTypeId = rliType.Id,
        //     Service_Type_Picklist__c = 'Basic',
        //     Start_Date__c = currDate/*,
        //     Time_of_Day_Code__c = isNEOrg ? 'N1 19:00-23:59' : 'NT - 23:00-23:59'*/
        // );
        // insert rli2;

        // Rate_Line_Item__c rli3 = new Rate_Line_Item__c(
        //     Calculation_Type__c = 'Unit',
        //     Charge_to_Account__c = 'B',
        //     Contract__c = svcContract.Id,
        //     End_Date__c = Date.newInstance(currDate.year() + 1, currDate.month(), currDate.day()),
        //     Fixed_Amount__c = 3,
        //     Has_Overlapping_Date__c = false,
        //     Max_Data_Range__c = 122,
        //     Min_Data_Range__c = 0,
        //     Product__c = prodTw.Id,
        //     RecordTypeId = rliType.Id,
        //     Service_Type_Picklist__c = 'Basic',
        //     Start_Date__c = currDate/*,
        //     Time_of_Day_Code__c = isNEOrg ? 'N2 00:00 – 05:59' : 'NA - 00:00-05:59'*/
        // );
        // insert rli3;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
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

        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

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
            Clearing_Code__c = '01',
            ContactId = contact.Id,
            BO_Editable_WO_Specific_Membership_Level__c = 'Basic'
        );
        insert wo;

        Statement__c stmt = new Statement__c();
        insert stmt;

        Invoice__c invc = new Invoice__c(
            RecordTypeId = invcType.Id,
            Work_Order__c = wo.Id,
            Status__c = 'Ready for Processing',
            Statement__c = stmt.Id
        );
        insert invc;

        FSL_Service_Line_Item__c testSLI = new FSL_Service_Line_Item__c(
            Product__c = prodTw.Id,
            Unit__c = 5,
            Work_Order__c = wo.Id
        );
        insert testSLI;

        return wo;
    }
}