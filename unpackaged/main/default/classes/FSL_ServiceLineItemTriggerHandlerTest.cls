@isTest
public class FSL_ServiceLineItemTriggerHandlerTest {
    @isTest
    static void runMethodTest() {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' LIMIT 1];

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = 'TEST'
        );
        insert svcTerritory;

        WorkOrder wo1 = new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = 'N101',
            ServiceTerritoryId = svcTerritory.Id,
            In_Tow_Timestamp__c = DateTime.now(),
            On_Location_Timestamp__c = DateTime.now()
        );
        insert wo1;

        Product2 prod2 = new Product2(
            Name = 'Apex Test Product 2',
            Family = 'Service Item',
            ProductCode = 'MA'
        );
        insert prod2;

        Boolean hasError = false;

        try {
            insert new FSL_Service_Line_Item__c(
                Work_Order__c = wo1.Id,
                Product__c = prod2.Id,
                Unit__c = 1,
                Cost__c = 100.00,
                Override_Pricing__c = false
            );
        } catch (Exception e) {
            hasError = true;
        }
        
        System.assertEquals(false, hasError, 'Failed.');
    }
}