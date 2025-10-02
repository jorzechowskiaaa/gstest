@isTest
public class AAAOutgoingReciprocalBatchTest {
    @TestSetup
    static void makeData() {
        Date currDate = System.today();
        Date futureDate = Date.newInstance(currDate.year() + 1, currDate.month(), currDate.day());
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
            Club_Code__c = '240',
            RECIPSCFAC__c = false,
            PAY_FAC_BONUS_FOR_ADJ__c = true,
            RECIPSTYPE__c = 'P',
            RECIPSCFIX__c = 3.0
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
            EndDate = futureDate
        );

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
        ServiceTerritory fac = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = 'APEXFAC22',
            City = 'FLUSHING',
 //           Contract__c = svcContract.Id,
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert fac;

        Statement__c stmt = new Statement__c(
            Start_Date__c = currDate,
            End_Date__c = futureDate,
            Service_Territory__c = fac.Id,
            Status__c = 'Reconciled'
        );
        insert stmt;

        Contact contact = [SELECT Id FROM Contact WHERE AccountId =: acct.Id];

        WorkOrder wo = new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = 'G101',
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
        insert wo;

        Invoice__c invc = new Invoice__c(
            Type__c = 'Reciprocals',
            Reciprocal_Sync_Ready__c = true,
            Status__c = 'Ready for Processing',
            Work_Order__c = wo.Id,
            Service_Territory__c = fac.Id,
            Statement__c = stmt.Id
        );
        insert invc;

        insert new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(
                Cost__c = 45.32,
                Tax__c = 1.01,
                Quantity__c = 3.0,
                Charge_to_Account__c = 'P',
                Code__c = '2C',
                Invoice__c = invc.Id
            ),
            new Invoice_Line_Item__c(
                Cost__c = 333.32,
                Tax__c = 10.01,
                Quantity__c = 200.0,
                Charge_to_Account__c = 'B',
                Code__c = 'OM',
                Invoice__c = invc.Id
            ),
            new Invoice_Line_Item__c(
                Cost__c = 450.32,
                Tax__c = 1.44,
                Quantity__c = 145.0,
                Charge_to_Account__c = 'B',
                Code__c = 'TW',
                Invoice__c = invc.Id
            )
        };

        insert new Feedback__c(
            Authorization_Code__c = 'B',
            Work_Order__c = wo.Id
        );
        
        insert new List<FSL_TroubleCode__c>{
            new FSL_TroubleCode__c(
                Code__c = '2',
                Type__c = 'PROBLEM',
                Work_Order__c = wo.Id,
                Description__c = 'test'
            ),
            new FSL_TroubleCode__c(
                Code__c = '2A',
                Type__c = 'PROBLEM',
                Work_Order__c = wo.Id,
                Description__c = 'test'
            ),
            new FSL_TroubleCode__c(
                Code__c = '3',
                Type__c = 'PROBLEM',
                Work_Order__c = wo.Id,
                Description__c = 'test'
            )
        };
    }

    @isTest
    static void outgoingReciprocalBatchTest() {
        Test.startTest();
        Database.executeBatch(new AAAOutgoingReciprocalBatch());
        Test.stopTest();

        List<Reciprocal__c> recList = [SELECT Id FROM Reciprocal__c];
        Invoice__c invc = [
            SELECT Id, Reciprocal_Sync_Ready__c 
            FROM Invoice__c 
            LIMIT 1
        ];

        System.assertEquals(1, recList.size(), 'Failed to create the appropriate amount of Reciprocals.');
        System.assertEquals(false, invc.Reciprocal_Sync_Ready__c, 'Failed to update Invoice.');
    }

    public static List<Local_to_Reciprocal_T_Code_Mapping__mdt> mockRecTCodeMdt() {
        return new List<Local_to_Reciprocal_T_Code_Mapping__mdt>{
            new Local_to_Reciprocal_T_Code_Mapping__mdt(
                Label = '2',
                T_Code__c = 'T1'
            ),
            new Local_to_Reciprocal_T_Code_Mapping__mdt(
                Label = '2A',
                T_Code__c = 'T2'
            ),
            new Local_to_Reciprocal_T_Code_Mapping__mdt(
                Label = '3',
                T_Code__c = 'T5'
            )
        };
    }
}