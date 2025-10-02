@isTest
class PreventDeletingPaidPaymentTest {
    @TestSetup
    static void createTestData() {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' LIMIT 1];
        RecordType facAdjType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Adjustment' LIMIT 1];

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
        
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId,1,false,false)[0];
        insert objFacility1 ;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id , 
            Account__c  = objFacility1.Id 
        );
        insert facAdj;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = facAdj.Id,
            ACG_Payment_Amount__c = 555.43
        );
        insert facAdjPmt;

        Statement__c statement = new Statement__c();
        insert statement;

        Invoice__c invoice = new Invoice__c(
            Status__c = 'Paid',
            Facility_Adjustment__c = facAdj.Id,
            Statement__c = statement.Id
        );
        insert invoice;

        Invoice_Line_Item__c invoiceLI = new Invoice_Line_Item__c(
            Invoice__c = invoice.Id,
            Facility_Adjustment_Payment__c = facAdjPmt.Id
        );
        insert invoiceLI;
    }

    @isTest
    static void deleteFacilityAdjustmentPaymentTest() {
        ACG_Facility_Adjustment_Payment__c facAdjPmt = [SELECT Id FROM ACG_Facility_Adjustment_Payment__c WHERE ACG_Adjustment_ID__r.Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment'];
        Boolean exceptionThrown = false;
        Boolean hasExpectedMsg = false;

        try {
            delete facAdjPmt;
        } catch (Exception e) {
            // hasExpectedMsg = e.getMessage().contains('Sorry you cannot delete a payment that has already been paid.');
            exceptionThrown = true;
        }
        
        System.assertEquals(exceptionThrown, true, 'Facility Adjustment Payment deleted while related Invoice status is "Paid".');
    }
}