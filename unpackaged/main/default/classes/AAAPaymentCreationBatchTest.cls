@isTest
class AAAPaymentCreationBatchTest {
    @TestSetup
    static void createTestData() {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType facAdjType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Adjustment' AND SobjectType = 'Invoice__c' LIMIT 1];
        RecordType ersType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ERS' LIMIT 1];

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            IsActive = true,
            Non_Payment_Facility__c = false,
            Street = '415 Mission St.',
            City = 'San Francisco',
            State = 'CA',
            PostalCode = '94105',
            Country = 'United States'
        );
        insert svcTerritory;
        
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId,1,false,false)[0];
        insert objFacility1 ;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id,
            Account__c = objFacility1.Id
        );
        insert facAdj;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = facAdj.Id,
            ACG_Payment_Amount__c = 0.0
        );
        insert facAdjPmt;

        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt;

        List<Invoice__c> invcList = new List<Invoice__c>{
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Basic',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Basic Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Other',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Other Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Plus',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Plus Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'RV',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'RV Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Premier',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Premier Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            )
        };
        insert invcList;


        List<Invoice_Line_Item__c> invcListLI = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(
                Invoice__c = invcList[0].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[1].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[2].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[3].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[4].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'O',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[5].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'O',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[6].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'P',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[7].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'P',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[8].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'R',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[9].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'R',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[10].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'E',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[11].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'E',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[12].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            )
        };
        insert invcListLI;
    }

    @isTest
    static void paymentCreationBatchTest() {
        Test.startTest();
        AAAPaymentCreationBatch bc = new AAAPaymentCreationBatch();
        Database.executeBatch(bc);
        Test.stopTest();

        Statement__c stmt = [SELECT Id, Processed__c, Name FROM Statement__c WHERE Statement_Name__c = 'Apex Test Statement 1' LIMIT 1];
        List<Invoice__c> invcList = [SELECT Id, Status__c FROM Invoice__c WHERE Statement__c =: stmt.Id];
        List<Payment__c> pmtList = [SELECT Id, Line_Row__c, Amount__c, Item_Description__c FROM Payment__c WHERE Document_Number__c =: stmt.Name ORDER BY Line_Row__c];

        System.assertEquals(stmt.Processed__c, true, 'Statement was not processed.');

        for(Invoice__c invc : invcList) {
            System.assertEquals(invc.Status__c, 'Submitted for Payment', 'Invoice status was not updated.');
        }

        System.assertEquals(pmtList.size(), 11, 'The appropriate amount of Payment records was not created.');

        for(Integer i = 1; i < 12; i++) {
            Payment__c pmt = pmtList[i - 1];

            if(pmt.Item_Description__c == 'Hardware') {
                System.assertEquals(pmt.Amount__c, 30.0, 'Amount on Payment record not updated correctly.');
            }

            System.assertEquals(pmt.Line_Row__c, i, 'Line rows were not correctly updated.');
        }
    }
}