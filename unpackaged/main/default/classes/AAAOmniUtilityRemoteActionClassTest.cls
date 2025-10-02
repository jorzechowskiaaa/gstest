@isTest
class AAAOmniUtilityRemoteActionClassTest {
    @isTest
    static void getFilteredProductsByFacSLIsTest() {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];

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
            Facility_Number__c = 'TEST',
            City = 'FLUSHING',
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert svcTerritory;

        List<Product2> prod2List = new List<Product2>{
            new Product2(
                ProductCode = 'T1',
                Name = 'Test 1',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T2',
                Name = 'Test 2',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T3',
                Name = 'Test 3',
                IsActive = true,
                Family = 'Service Item'
            ),
            new Product2(
                ProductCode = 'T4',
                Name = 'Test 4',
                IsActive = true,
                Family = 'Service Item'
            )
        };
        insert prod2List;

        insert new List<Facility_Service_Item__c>{
            new Facility_Service_Item__c(
                Facility__c = svcTerritory.Id,
                Product__c = prod2List[0].Id
            ),
            new Facility_Service_Item__c(
                Facility__c = svcTerritory.Id,
                Product__c = prod2List[2].Id
            )
        };

        Test.startTest();
        String methodName = 'getFilteredProductsByFacSLIs';
        Map<String, Object> input = new Map<String, Object>{
            'ProductName' => 't',
            'ServiceTerritoryId' => svcTerritory.Id
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        AAAOmniUtilityRemoteActionClass remoteClass = new AAAOmniUtilityRemoteActionClass();

        remoteClass.invokeMethod(methodName, input, output, options);
        
        List<Map<String, Object>> resList = (List<Map<String, Object>>) output.get('Products');
        
        System.assertEquals(resList.size(), 2, 'Failed to filter products.');
        System.assertEquals(resList[0].get('ProductName'), 'Test 2', 'Failed to filter products.');
        System.assertEquals(resList[1].get('ProductName'), 'Test 4', 'Failed to filter products.');
        Test.stopTest();
    }
}