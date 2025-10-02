@isTest
class AAAUpdateFAPWithInvoiceStatusBatchTest {
    private static String readyForProcessing = 'Ready for Processing';
    private static String readyForPayment = 'Ready for Payment';

    @TestSetup
    static void makeData() {
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
            Non_Payment_Facility__c = false
        );
        insert svcTerritory;

        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt;

        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId, 1, false, false)[0];
        insert objFacility1 ;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id,
            Account__c = objFacility1.Id
        );
        insert facAdj;

        Invoice__c invc = new Invoice__c(
            Status__c = readyForPayment,
            Facility_Adjustment__c = facAdj.Id,
            Service_Territory__c = svcTerritory.Id,
            Statement__c = stmt.Id,
            Facility_Adjustment_Category__c = 'Hardware',
            RecordTypeId = facAdjType.Id,
            Type__c = 'Facility Adjustments'
        );
        insert invc;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = facAdj.Id,
            ACG_Payment_Amount__c = 0.0
        );
        insert facAdjPmt;

        insert new Invoice_Line_Item__c(
            Invoice__c = invc.Id,
            Facility_Adjustment_Payment__c = facAdjPmt.Id,
            Charge_to_Account__c = 'B',
            Cost__c = 10.0,
            Tax__c = 0.0
        );
    }

    @isTest
    static void runUpdateFAPWithInvoiceStatusBatchTest1() {
        Test.startTest();
        Database.executeBatch(new AAAUpdateFAPWithInvoiceStatusBatch());
        Test.stopTest();

        List<ACG_Facility_Adjustment_Payment__c> fapList = [
            SELECT Id, ACG_Status__c
            FROM ACG_Facility_Adjustment_Payment__c
        ];

        for (ACG_Facility_Adjustment_Payment__c fap : fapList) {
            System.assertEquals(fap.ACG_Status__c, readyForPayment, 'Failed to update FAP status.');
        }
    }

    @isTest
    static void runUpdateFAPWithInvoiceStatusBatchTest2() {
        List<String> invcIdList = new List<String>();
        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
        ];
        for (Invoice__c invc : invcList) {
            invc.Status__c = readyForProcessing;
            invcIdList.add(invc.Id);
        }
        update invcList;

        List<ACG_Facility_Adjustment_Payment__c> fapList = [
            SELECT Id, ACG_Status__c
            FROM ACG_Facility_Adjustment_Payment__c
        ];
        for (ACG_Facility_Adjustment_Payment__c fap : fapList) {
            fap.ACG_Status__c = readyForPayment;
        }
        update fapList;

        Test.startTest();
        Database.executeBatch(new AAAUpdateFAPWithInvoiceStatusBatch(invcIdList));
        Test.stopTest();

        List<ACG_Facility_Adjustment_Payment__c> fapResList = [
            SELECT Id, ACG_Status__c
            FROM ACG_Facility_Adjustment_Payment__c
        ];

        for (ACG_Facility_Adjustment_Payment__c fap : fapResList) {
            System.assertEquals(fap.ACG_Status__c, readyForProcessing, 'Failed to update FAP status.');
        }
    }
}