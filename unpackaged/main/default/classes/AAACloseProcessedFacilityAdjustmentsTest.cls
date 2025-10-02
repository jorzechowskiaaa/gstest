@isTest
class AAACloseProcessedFacilityAdjustmentsTest {
    @TestSetup
    static void createTestData() {
        RecordType facTerritoryType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Territory' 
            LIMIT 1
        ];
        RecordType facAcctType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility' 
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
            OperatingHoursId = opHrs.Id
        );
        insert svcTerritory;

        Statement__c stmt = new Statement__c(
            Start_Date__c = Date.newInstance(2024, 2, 1),
            End_Date__c = Date.newInstance(2024, 2, 29),
            Service_Territory__c = svcTerritory.Id,
            Status__c = 'Unreconciled'
        );
        insert stmt;

        List<ACG_Facility_Adjustment__c> facAdjListToInsert = new List<ACG_Facility_Adjustment__c>();
        for (Integer i = 0; i < 10; i++) {
            facAdjListToInsert.add(
                new ACG_Facility_Adjustment__c(
                    Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment ' + i,
                    ACG_Start_Date__c = Date.newinstance(2024, 2, 14),
                    Service_Territory__c = svcTerritory.Id,
                    ACG_Adjustment_Type__c = 'Debit',
                    ACG_Status__c = 'Active',
                    ACG_No_of_Payments__c = 1,
                    ACG_Payment_Amount__c = 100  
                )
            );
        }
        insert facAdjListToInsert;

        stmt.Status__c = 'Reconciled';
        update stmt;

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
        ];
        for (Invoice__c invc : invcList) {
            invc.Status__c = 'Submitted for Payment';
        }
        update invcList;
    }

    @isTest
    static void closeProcessedFacilityAdjustmentsTest() {
        Integer numCancelledFacAdj = Database.countQuery('SELECT COUNT() FROM ACG_Facility_Adjustment__c WHERE Facility_Adjustment_Name__c LIKE \'Apex Test Facility Adjustment%\' AND ACG_Status__c = \'Active\'');

        Test.startTest();
        Database.executeBatch(new AAACloseProcessedFacilityAdjustments());
        Test.stopTest();

        Integer numClosedFacAdj = Database.countQuery('SELECT COUNT() FROM ACG_Facility_Adjustment__c WHERE Facility_Adjustment_Name__c LIKE \'Apex Test Facility Adjustment%\' AND ACG_Status__c = \'Closed\'');

        System.assertEquals(numCancelledFacAdj, numClosedFacAdj, 'Failed to close Facility Adjustments.');
    }
}