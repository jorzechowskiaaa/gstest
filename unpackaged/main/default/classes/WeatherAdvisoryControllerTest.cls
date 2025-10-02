@isTest
public class WeatherAdvisoryControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test data for Winter_Advisory__c object
        Winter_Advisory__c advisory1 = new Winter_Advisory__c(
            State__c = 'California',
            City__c = 'San Francisco',
            Advisory_Message_Display__c = 'Winter storm warning in San Francisco.',
            Active__c = true
        );
        insert advisory1;

        Winter_Advisory__c advisory2 = new Winter_Advisory__c(
            State__c = 'California',
            Advisory_Message_Display__c = 'General winter advisory for California.',
            Active__c = true
        );
        insert advisory2;

        Winter_Advisory__c inactiveAdvisory = new Winter_Advisory__c(
            State__c = 'California',
            City__c = 'Los Angeles',
            Advisory_Message_Display__c = 'Inactive advisory.',
            Active__c = false
        );
        insert inactiveAdvisory;

        Winter_Advisory__c advisory3 = new Winter_Advisory__c(
            Service_Type__c= 'Battery',
            Advisory_Message_Display__c = 'General winter advisory for Battery.',
            Active__c = true
        );
        insert advisory3;
    }

    @isTest
    static void testGetAdvisoryMessage_CityAndStateMatch() {
        // Test case where both city and state match an active advisory
        Test.startTest();
        String result = WeatherAdvisoryController.getAdvisoryMessage('California', 'San Francisco');
        Test.stopTest();

        System.assertEquals('Winter storm warning in San Francisco.', result, 'City-specific advisory message should be returned.');
    }

    @isTest
    static void testGetAdvisoryMessage_StateOnlyMatch() {
        // Test case where only state matches an active advisory, no city specified
        Test.startTest();
        String result = WeatherAdvisoryController.getAdvisoryMessage('California', null);
        Test.stopTest();

        System.assertEquals('General winter advisory for California.', result, 'State-specific advisory message should be returned.');
    }

    @isTest
    static void testGetAdvisoryMessage_ServiceMatch() {
        // Test case where both city and state match an active advisory
        Test.startTest();
        String result = WeatherAdvisoryController.getAdvisoryMessageByService('Battery');
        Test.stopTest();

        System.assertEquals('General winter advisory for Battery.', result, 'Service-specific advisory message should be returned.');
    }

    @isTest
    static void testGetAdvisoryMessage_NoMatch() {
        // Test case where no active advisory matches
        Test.startTest();
        String result = WeatherAdvisoryController.getAdvisoryMessage('Nevada', null);
        Test.stopTest();

        System.assertEquals(null, result, 'No advisory message should be returned when no match is found.');
    }

    @isTest
    static void testGetAdvisoryMessage_ExceptionHandling() {
        // Test case to simulate an exception (e.g., malformed query)
        Test.startTest();
        try {
            String result = WeatherAdvisoryController.getAdvisoryMessage('test', 'test');
            System.assertEquals(null, result, 'Null input should result in null output.');
        } catch (Exception e) {
            System.assert(false, 'Method should handle exceptions gracefully.');
        }
        Test.stopTest();
    }
}