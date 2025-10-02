@isTest
class AAABatchInvoiceUpdateHelperTest {
    @TestSetup
    static void makeData() {
        RecordType facAdjType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Adjustment' 
            AND SobjectType = 'Invoice__c' 
            LIMIT 1
        ];
        RecordType facTerritoryType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Territory' 
            AND SobjectType = 'ServiceTerritory' 
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
        
        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt;

        List<Invoice__c> invcList = new List<Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            invcList.add(
                new Invoice__c(
                    Status__c = 'Ready for Payment',
                    Facility_Adjustment__c = facAdj.Id,
                    Statement__c = stmt.Id,
                    Facility_Adjustment_Category__c = 'Apex Test Facility Adj ' + i,
                    RecordTypeId = facAdjType.Id
                )
            );
        }
        insert invcList;
    }

    @isTest
    static void batchInvoiceUpdateHelperTest() {
        String readyForProcessing = 'Ready for Processing';
        String readyForPayment = 'Ready for Payment';
        String query = 'SELECT Id, Status__c, Type__c FROM Invoice__c WHERE Status__c = \'' + readyForPayment + '\'';
        List<Invoice__c> invcList = [
            SELECT Id FROM Invoice__c WHERE Status__c = :readyForPayment
        ];

        Test.startTest();
        Database.executeBatch(new AAABatchInvoiceUpdateHelper(
            query, readyForProcessing
        ));
        Test.stopTest();

        List<Invoice__c> resInvcList = [
            SELECT Id FROM Invoice__c WHERE Status__c = :readyForProcessing
        ];

        System.assertEquals(true, invcList.size() != 0 && invcList.size() == resInvcList.size(), 'Failed to update Invoice statuses.');
    }
}