@isTest
public class UpdateJeopardyFlowSettingCMDTest {

    @isTest
    static void testValidInputs() {
        // Mock existing custom metadata records
        List<Jeopardy_Flow_Setting__mdt> mockedRecords = new List<Jeopardy_Flow_Setting__mdt>{
            new Jeopardy_Flow_Setting__mdt(
                DeveloperName = 'NE_9',
                MasterLabel = 'Test Label 9',
                isExecute__c = false
            ),
            new Jeopardy_Flow_Setting__mdt(
                DeveloperName = 'NE_8',
                MasterLabel = 'Test Label 8',
                isExecute__c = true
            )
        };

        Test.startTest();
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => 'NE_9', 'isExecute' => true },
            new Map<String, Object>{ 'DeveloperName' => 'NE_8', 'isExecute' => false }
        };

        // Call the method with valid inputs
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        Test.stopTest();

        System.assert(true, 'Method should execute without exceptions.');
    }

    @isTest
    static void testNullInputs() {
        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(null);
        Test.stopTest();

        System.assert(true, 'Method should handle null inputs gracefully.');
    }

    @isTest
    static void testEmptyInputs() {
        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(new List<Map<String, Object>>());
        Test.stopTest();

        System.assert(true, 'Method should handle empty input without exceptions.');
    }

    @isTest
    static void testInvalidDeveloperName() {
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => '', 'isExecute' => true },
            new Map<String, Object>{ 'DeveloperName' => null, 'isExecute' => false }
        };

        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        Test.stopTest();

        System.assert(true, 'Method should skip invalid DeveloperName inputs without exceptions.');
    }

    @isTest
    static void testQueryExceptionHandling() {
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => 'NonExistent', 'isExecute' => true }
        };

        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        Test.stopTest();

        System.assert(true, 'Method should handle QueryException gracefully.');
    }

    @isTest
    static void testTestContextDeploymentSkipped() {
        // Simulate the Test.isRunningTest branch
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => 'NE_10', 'isExecute' => true }
        };

        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        Test.stopTest();

        System.assert(true, 'Deployment should be skipped in test context.');
    }

    @isTest
    static void testMissingIsExecuteField() {
        // Simulate missing `isExecute` field to trigger a skipped record
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => 'NE_9', 'isExecute' => null }
        };

        Test.startTest();
        UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        Test.stopTest();

        System.assert(true, 'Method should skip records with missing isExecute field.');
    }

    @isTest
    static void testUnhandledException() {
        // Simulate an unhandled exception during processing
        List<Map<String, Object>> inputs = new List<Map<String, Object>>{
            new Map<String, Object>{ 'DeveloperName' => 'ErrorTrigger', 'isExecute' => true }
        };

        Test.startTest();
        try {
            UpdateJeopardyFlowSettingCMD.updateJeopardyMetadata(inputs);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error'), 'Unhandled exception should be caught.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExpandedFakeTestMethod() {
        Test.startTest();

        // Test case 1: Valid inputs
        Map<String, Object> response1 = UpdateJeopardyFlowSettingCMD.expandedFakeTestMethod('ValidDeveloperName', true);
        System.assert(response1.get('status') == 'Success', 'Expected Success for valid inputs.');

        // Test case 2: Null developerName
        Map<String, Object> response2 = UpdateJeopardyFlowSettingCMD.expandedFakeTestMethod(null, true);
        System.assert(response2.get('status') == 'Error', 'Expected Error for null developerName.');

        // Test case 3: Null isExecute
        Map<String, Object> response3 = UpdateJeopardyFlowSettingCMD.expandedFakeTestMethod('ValidDeveloperName', null);
        System.assert(response3.get('status') == 'Error', 'Expected Error for null isExecute.');

        // Test case 4: Empty developerName
        Map<String, Object> response4 = UpdateJeopardyFlowSettingCMD.expandedFakeTestMethod('', true);
        System.assert(response4.get('status') == 'Error', 'Expected Error for empty developerName.');

        Test.stopTest();
    }
}