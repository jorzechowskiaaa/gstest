@isTest
class AAAInvoiceReadyForPaymentBatchTest {
    @TestSetup
    static void createData() {
        RecordType facTerritoryType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Territory' 
            AND SobjectType = 'ServiceTerritory' 
            LIMIT 1
        ];
        RecordType facAdjType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Adjustment' 
            AND SobjectType = 'Invoice__c' 
            LIMIT 1
        ];

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

        List<Statement__c> stmtList = new List<Statement__c>();
        for (Integer i = 0; i < 3; i++) {
            stmtList.add(
                new Statement__c(
                    Service_Territory__c = svcTerritory.Id,
                    Start_Date__c = System.today(),
                    End_Date__c = System.today(),
                    Statement_Name__c = 'Apex Test Statement' + (i + 1),
                    Status__c = 'Reconciled',
                    Processed__c = false
                )
            );
        }
        insert stmtList;

        List<Invoice__c> invcList = new List<Invoice__c>();
        for (Statement__c stmt : stmtList) {
            invcList.add(
                new Invoice__c(
                    Status__c = 'Ready for Processing',
                    Facility_Adjustment__c = facAdj.Id,
                    Service_Territory__c = svcTerritory.Id,
                    Statement__c = stmt.Id,
                    Facility_Adjustment_Category__c = 'Hardware',
                    RecordTypeId = facAdjType.Id,
                    Type__c = 'Facility Adjustments'
                )
            );
        }
        insert invcList;
    }

    @isTest
    static void runReadyForPaymentBatchTest() {
        String expectedResult = 'Ready for Payment';
        List<String> stmtIdList = new List<String>();
        List<Statement__c> stmtList = [
            SELECT Id
            FROM Statement__c
        ];

        for (Statement__c stmt : stmtList) {
            stmtIdList.add(stmt.Id);
        }

        Test.startTest();
        Database.executeBatch(new AAAInvoiceReadyForPaymentBatch(stmtIdList), 9000);
        Test.stopTest();

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
        ];

        for (Invoice__c invc : invcList) {
            System.assertEquals(expectedResult, invc.Status__c, 'Failed to update Invoices.');
        }
    }
}