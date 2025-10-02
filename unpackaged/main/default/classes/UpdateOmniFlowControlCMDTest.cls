@isTest
private class UpdateOmniFlowControlCMDTest {

    // Test method for valid input scenario
    @isTest
    static void testValidMetadataUpdate() {
        // Setup test data
        UpdateOmniFlowControlCMD.MetadataInput input = new UpdateOmniFlowControlCMD.MetadataInput();
        input.Label = 'Test Metadata Label';
        input.DeveloperName = 'Omni_Flow_Control_Test';
        input.Aging_120_Flow_Control = true;
        input.Aging_75_Flow_Control = false;
        input.Aging_60_Flow_Control = true;
        input.Cancelled_Call = true;
        input.ETA_Request = false;

        List<UpdateOmniFlowControlCMD.MetadataInput> inputs = new List<UpdateOmniFlowControlCMD.MetadataInput>();
        inputs.add(input);

        Test.startTest();
        
        // Call the method that updates metadata (but avoid actual deployment)
        try {
            UpdateOmniFlowControlCMD.updateMetadata(inputs);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.assert(false, 'Unexpected exception thrown: ' + e.getMessage());
        }

        Test.stopTest();

        // Confirm method ran successfully
        System.assert(true, 'Metadata processing should run successfully.');
    }

    // Test method for missing required fields (to trigger exception)
    @isTest
    static void testMissingRequiredField() {
        UpdateOmniFlowControlCMD.MetadataInput input = new UpdateOmniFlowControlCMD.MetadataInput();
        input.Label = null;  // Missing Label
        input.DeveloperName = 'Omni_Flow_Control_Test';

        List<UpdateOmniFlowControlCMD.MetadataInput> inputs = new List<UpdateOmniFlowControlCMD.MetadataInput>();
        inputs.add(input);

        Test.startTest();
        try {
            UpdateOmniFlowControlCMD.updateMetadata(inputs);
            System.assert(false, 'Expected exception for missing Label.');
        } catch (Exception e) {
            // Assert the correct exception for missing Label
            System.assert(e.getMessage().contains('Label cannot be null or blank'));
        }
        Test.stopTest();
    }
}