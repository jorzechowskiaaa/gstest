@isTest
class FSL_InvoiceTriggerHandlerTest {
    @TestSetup
    static void createTestData() {
        List<String> invcTypeList = new List<String>{
            'Call Adjustments',
            'ERS Calls',
            'Reciprocal Adjustments',
            'Reciprocals'
        };
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType ersType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ERS' AND SobjectType = 'Invoice__c' LIMIT 1];
        RecordType facAdjType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Adjustment' AND SobjectType = 'Invoice__c' LIMIT 1];
        RecordType acctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' AND SobjectType = 'Account' LIMIT 1];

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        Account acct1 = new Account(
            AAA_Membership_Level__c = 'Basic',
            ACG_AAA_Membership__c = '6202984941373217',
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
            Member_Card_Num__pc = '6202984941373217',
            Member_ID__c = '6202984941373216',
            Membership_Level__pc = 'BASIC',
            Membership_Org__pc = 'EDS',
            Membership_OrgCode__pc = '298',
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
        insert acct1;

        Account acct2 = new Account(
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
        insert acct2;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            IsActive = true,
            Non_Payment_Facility__c = false
        );
        insert svcTerritory;

        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId, 1, false, false)[0];
        insert objFacility1;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id,
            Account__c = objFacility1.Id
        );
        insert facAdj;

        insert new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = facAdj.Id,
            ACG_Payment_Amount__c = 0.0
        );

        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement ' + System.today(),
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt;

        List<String>acctIds = new List<String>{acct1.Id, acct2.Id};
        List<Contact> contactList = [
            SELECT Id, Membership_OrgCode__c 
            FROM Contact 
            WHERE AccountId IN :acctIds
            ORDER BY AccountId ASC
        ];


        List<WorkOrder> woList = new List<WorkOrder>();
        for (Integer i = 0; i < invcTypeList.size(); i++) {
            woList.add(
                new WorkOrder(
                    Call_Id__c = 'Apex Test Work Order 2' + i,
                    Status = 'Cleared',
                    Resolution_Code__c = 'G201',
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
                    ContactId = contactList[0].Id
                )
            );
        }
        woList.add(
            new WorkOrder(
                Call_Id__c = 'Apex Test Work Order 24',
                Status = 'Cleared',
                Resolution_Code__c = 'G201',
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
                Clearing_Code__c = '01',
                ContactId = contactList[1].Id,
                Call_Type__c = 'RAP'
            )
        );
        woList.add(
            new WorkOrder(
                Call_Id__c = 'Apex Test Work Order 24',
                Status = 'Cleared',
                Resolution_Code__c = 'G201',
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
                Clearing_Code__c = '01',
                ContactId = contactList[1].Id,
                Call_Type__c = 'MEMBER'
            )
        );
        insert woList;

        Product2 prod2 = new Product2(
            Name = 'Apex Test Product 1',
            Family = 'Service Item',
            ProductCode = 'BR'
        );
        insert prod2;

        insert new FSL_Service_Line_Item__c(
            Work_Order__c = woList[0].Id,
            Product__c = prod2.Id,
            Unit__c = 1,
            Cost__c = 100.00,
            Override_Pricing__c = false
        );

        List<Invoice__c> invcList = new List<Invoice__c>();
        for (Integer i = 0; i < invcTypeList.size(); i++) {
            for (Integer j = 0; j < woList.size(); j++) {
                String adjStr = String.valueOf(i) + String.valueOf(j);

                invcList.add(
                    new Invoice__c(
                        Status__c = 'Ready for Payment',
                        Facility_Adjustment__c = facAdj.Id,
                        Statement__c = stmt.Id,
                        Facility_Adjustment_Category__c = 'Apex Test Facility Adj ' + adjStr,
                        RecordTypeId = ersType.Id,
                        Type__c = invcTypeList[i],
                        Work_Order__c = woList[j].Id
                    )
                );
            }
        }
        invcList.add(
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Apex Test Facility Adj 999',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments',
                Work_Order__c = woList[0].Id,
                Facility_Adjustment_Type__c = 'Debit'
            )
        );
        insert invcList;
    }

    @isTest
    static void updateStatementRollupTest1() {
        insert new BackOffice_Settings__c(
            Club_Code__c = '212'
        );

        String stmtName = 'Apex Test Statement ' + System.today();
        List<String> spendCatList = new List<String>{'B', 'O', 'P', 'E', 'R'};
        List<Invoice__c> invcList = [
            SELECT 
                Id, 
                Type__c,
                Status__c,
                Work_Order__c, 
                Work_Order__r.Call_Type__c
            FROM Invoice__c
            WHERE Facility_Adjustment_Category__c LIKE 'Apex Test Facility Adj%'
            ORDER BY Id ASC
        ];
        ACG_Facility_Adjustment_Payment__c facAdjPmt = [
            SELECT Id
            FROM ACG_Facility_Adjustment_Payment__c
            WHERE ACG_Adjustment_ID__r.Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment'
            LIMIT 1
        ];
        FSL_Service_Line_Item__c sliBR = [
            SELECT Id
            FROM FSL_Service_Line_Item__c
            WHERE Product_Code__c = 'BR'
            AND Work_Order__c != NULL
            LIMIT 1
        ];
        Boolean addedBR = false;

        List<Invoice_Line_Item__c> iliList = new List<Invoice_Line_Item__c>();
        for (Integer i = 0; i < invcList.size(); i++) {
            for (Integer x = 0; x < spendCatList.size(); x++) {
                Invoice__c invc = invcList[i];
                String invcType = invc.Type__c;
                String woCallType = invc.Work_Order__r.Call_Type__c;
                String chargeAcct = spendCatList[x];
                String sliBRId = chargeAcct == 'E' && invcType == 'ERS Calls' 
                    && woCallType != 'RAP' && !addedBR ? sliBR.Id : null;

                iliList.add(
                    new Invoice_Line_Item__c(
                        Invoice__c = invcList[i].Id,
                        Facility_Adjustment_Payment__c = facAdjPmt.Id,
                        Charge_to_Account__c = chargeAcct,
                        Cost__c = 10.0,
                        Tax__c = 1.0,
                        Service_Line_Item__c = sliBRId
                    )
                );

                if (!addedBR && sliBRId != null) {
                    addedBR = true;
                }
            }
        }
        insert iliList;

        Statement__c stmt1 = [
            SELECT
                Id,
                Basic_Cost_Tax_Adjustment__c,
			    Basic_Cost_Tax_ERS__c,
			    Basic_Cost_Tax_Reciprocal_Adjustment__c,
			    Basic_Cost_Tax_Reciprocal__c,
			    Other_Cost_Tax_Adjustment__c,
			    Other_Cost_Tax_ERS__c,
			    Other_Cost_Tax_Reciprocal_Adjustment__c,
			    Other_Cost_Tax_Reciprocal__c,
			    Plus_Cost_Tax_Adjustment__c,
			    Plus_Cost_Tax_ERS__c,
			    Plus_Cost_Tax_Reciprocal_Adjustment__c,
			    Plus_Cost_Tax_Reciprocal__c,
			    Premier_Cost_Tax_Adjustment__c,
			    Premier_Cost_Tax_ERS__c,
			    Premier_Cost_Tax_Reciprocal_Adjustment__c,
			    Premier_Cost_Tax_Reciprocal__c,
			    RV_Cost_Tax_Adjustment__c,
			    RV_Cost_Tax_ERS__c,
			    RV_Cost_Tax_Reciprocal_Adjustment__c,
			    RV_Cost_Tax_Reciprocal__c,
                Club_Station_Contractor_Battery__c,
                Club_Station_Contractor_Battery_Tax__c,
                Club_Station_Contractor_Basic__c,
                Club_Station_Contractor_Plus__c,
                Club_Station_Contractor_PLRV__c,
                Club_Station_Contractor_PRM__c,
                Club_Station_Programs_Basic__c,
                Club_Station_Programs_Plus__c,
                Club_Station_Programs_prem__c,
                Club_Station_RAP__c,
                Club_Station_Reciprocal__c,
                Total_Credit__c,
                Total_Debit__c
            FROM Statement__c
            WHERE Statement_Name__c = :stmtName
            LIMIT 1
        ];

        System.assertEquals(stmt1.Basic_Cost_Tax_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Basic_Cost_Tax_ERS__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Basic_Cost_Tax_Reciprocal_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Basic_Cost_Tax_Reciprocal__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Other_Cost_Tax_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Other_Cost_Tax_ERS__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Other_Cost_Tax_Reciprocal_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Other_Cost_Tax_Reciprocal__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Plus_Cost_Tax_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Plus_Cost_Tax_ERS__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Plus_Cost_Tax_Reciprocal_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Plus_Cost_Tax_Reciprocal__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Premier_Cost_Tax_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Premier_Cost_Tax_ERS__c, 5.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Premier_Cost_Tax_Reciprocal_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Premier_Cost_Tax_Reciprocal__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.RV_Cost_Tax_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.RV_Cost_Tax_ERS__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.RV_Cost_Tax_Reciprocal_Adjustment__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.RV_Cost_Tax_Reciprocal__c, 6.00, 'Tax is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_Battery__c, 10.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_Battery_Tax__c, 1.00, 'Tax cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_Basic__c, 240.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_Plus__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_PLRV__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Contractor_PRM__c, 110.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Programs_Basic__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Programs_Plus__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Programs_prem__c, 80.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_RAP__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Club_Station_Reciprocal__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt1.Total_Credit__c, 0.00, 'Total credit is incorrect.');
        System.assertEquals(stmt1.Total_Debit__c, 55.00, 'Total debit is incorrect.');

        for (Invoice_Line_Item__c ili : iliList) {
            ili.Tax__c = 4.00;
        }

        update iliList;

        Statement__c stmt2 = [
            SELECT
                Id,
                Basic_Cost_Tax_Adjustment__c,
			    Basic_Cost_Tax_ERS__c,
			    Basic_Cost_Tax_Reciprocal_Adjustment__c,
			    Basic_Cost_Tax_Reciprocal__c,
			    Other_Cost_Tax_Adjustment__c,
			    Other_Cost_Tax_ERS__c,
			    Other_Cost_Tax_Reciprocal_Adjustment__c,
			    Other_Cost_Tax_Reciprocal__c,
			    Plus_Cost_Tax_Adjustment__c,
			    Plus_Cost_Tax_ERS__c,
			    Plus_Cost_Tax_Reciprocal_Adjustment__c,
			    Plus_Cost_Tax_Reciprocal__c,
			    Premier_Cost_Tax_Adjustment__c,
			    Premier_Cost_Tax_ERS__c,
			    Premier_Cost_Tax_Reciprocal_Adjustment__c,
			    Premier_Cost_Tax_Reciprocal__c,
			    RV_Cost_Tax_Adjustment__c,
			    RV_Cost_Tax_ERS__c,
			    RV_Cost_Tax_Reciprocal_Adjustment__c,
			    RV_Cost_Tax_Reciprocal__c,
                Club_Station_Contractor_Battery__c,
                Club_Station_Contractor_Battery_Tax__c,
                Club_Station_Contractor_Basic__c,
                Club_Station_Contractor_Plus__c,
                Club_Station_Contractor_PLRV__c,
                Club_Station_Contractor_PRM__c,
                Club_Station_Programs_Basic__c,
                Club_Station_Programs_Plus__c,
                Club_Station_Programs_prem__c,
                Club_Station_RAP__c,
                Club_Station_Reciprocal__c,
                Total_Credit__c,
                Total_Debit__c
            FROM Statement__c
            WHERE Statement_Name__c = :stmtName
            LIMIT 1
        ];

        System.assertEquals(stmt2.Basic_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Basic_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Basic_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Basic_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Other_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Other_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Other_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Other_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Plus_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Plus_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Plus_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Plus_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Premier_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Premier_Cost_Tax_ERS__c, 20.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Premier_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Premier_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.RV_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.RV_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.RV_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.RV_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_Battery__c, 10.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_Battery_Tax__c, 4.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_Basic__c, 240.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_Plus__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_PLRV__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Contractor_PRM__c, 110.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Programs_Basic__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Programs_Plus__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Programs_prem__c, 80.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_RAP__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Club_Station_Reciprocal__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt2.Total_Credit__c, 0.00, 'Total credit is incorrect.');
        System.assertEquals(stmt2.Total_Debit__c, 70.00, 'Total debit is incorrect.');

        Invoice__c invc = invcList[invcList.size() - 1];
        invc.Status__c = 'Deferred';
        update invc;

        Statement__c stmt3 = [
            SELECT
                Id,
                Basic_Cost_Tax_Adjustment__c,
			    Basic_Cost_Tax_ERS__c,
			    Basic_Cost_Tax_Reciprocal_Adjustment__c,
			    Basic_Cost_Tax_Reciprocal__c,
			    Other_Cost_Tax_Adjustment__c,
			    Other_Cost_Tax_ERS__c,
			    Other_Cost_Tax_Reciprocal_Adjustment__c,
			    Other_Cost_Tax_Reciprocal__c,
			    Plus_Cost_Tax_Adjustment__c,
			    Plus_Cost_Tax_ERS__c,
			    Plus_Cost_Tax_Reciprocal_Adjustment__c,
			    Plus_Cost_Tax_Reciprocal__c,
			    Premier_Cost_Tax_Adjustment__c,
			    Premier_Cost_Tax_ERS__c,
			    Premier_Cost_Tax_Reciprocal_Adjustment__c,
			    Premier_Cost_Tax_Reciprocal__c,
			    RV_Cost_Tax_Adjustment__c,
			    RV_Cost_Tax_ERS__c,
			    RV_Cost_Tax_Reciprocal_Adjustment__c,
			    RV_Cost_Tax_Reciprocal__c,
                Club_Station_Contractor_Battery__c,
                Club_Station_Contractor_Battery_Tax__c,
                Club_Station_Contractor_Basic__c,
                Club_Station_Contractor_Plus__c,
                Club_Station_Contractor_PLRV__c,
                Club_Station_Contractor_PRM__c,
                Club_Station_Programs_Basic__c,
                Club_Station_Programs_Plus__c,
                Club_Station_Programs_prem__c,
                Club_Station_RAP__c,
                Club_Station_Reciprocal__c,
                Total_Credit__c,
                Total_Debit__c
            FROM Statement__c
            WHERE Statement_Name__c = :stmtName
            LIMIT 1
        ];

        System.assertEquals(stmt3.Basic_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Basic_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Basic_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Basic_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Other_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Other_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Other_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Other_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Plus_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Plus_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Plus_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Plus_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Premier_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Premier_Cost_Tax_ERS__c, 20.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Premier_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Premier_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.RV_Cost_Tax_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.RV_Cost_Tax_ERS__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.RV_Cost_Tax_Reciprocal_Adjustment__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.RV_Cost_Tax_Reciprocal__c, 24.00, 'Tax is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_Battery__c, 10.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_Battery_Tax__c, 4.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_Basic__c, 240.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_Plus__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_PLRV__c, 120.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Contractor_PRM__c, 110.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Programs_Basic__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Programs_Plus__c, 160.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Programs_prem__c, 80.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_RAP__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Club_Station_Reciprocal__c, 100.00, 'Total cost is incorrect.');
        System.assertEquals(stmt3.Total_Credit__c, 0.00, 'Total credit is incorrect.');
        System.assertEquals(stmt3.Total_Debit__c, 0.00, 'Total debit is incorrect.');
    }
}