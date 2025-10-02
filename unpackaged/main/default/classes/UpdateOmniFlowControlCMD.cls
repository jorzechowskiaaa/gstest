public without sharing class UpdateOmniFlowControlCMD {

    @InvocableMethod(label = 'Update Omni Flow Control Metadata')
    public static void updateMetadata(List<MetadataInput> inputs) {
        for (MetadataInput input : inputs) {
            // Validate the required fields
            if (String.isEmpty(input.Label)) {
                throw new CustomException('Label cannot be null or blank');
            }
            
            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.fullName = 'Omni_Flow_Control__mdt.Omni_Flow_Control';
            cmd.label = input.Label;

            if (input.Aging_120_Flow_Control != null) {
                Metadata.CustomMetadataValue value120 = new Metadata.CustomMetadataValue();
                value120.field = 'Aging_120_Flow_Control__c';
                value120.value = input.Aging_120_Flow_Control;
                cmd.values.add(value120);
            }

            if (input.Aging_75_Flow_Control != null) {
                Metadata.CustomMetadataValue value75 = new Metadata.CustomMetadataValue();
                value75.field = 'Aging_75_Flow_Control__c';
                value75.value = input.Aging_75_Flow_Control;
                cmd.values.add(value75);
            }

            if (input.Aging_60_Flow_Control != null) {
                Metadata.CustomMetadataValue value60 = new Metadata.CustomMetadataValue();
                value60.field = 'Aging_60_Flow_Control__c';
                value60.value = input.Aging_60_Flow_Control;
                cmd.values.add(value60);
            }
            
            if (input.Cancelled_Call != null) {
                Metadata.CustomMetadataValue valueCancel = new Metadata.CustomMetadataValue();
                valueCancel.field = 'Cancelled_Call__c';
                valueCancel.value = input.Cancelled_Call;
                cmd.values.add(valueCancel);
            }
            if (input.ETA_Request != null) {
                Metadata.CustomMetadataValue valueETA = new Metadata.CustomMetadataValue();
                valueETA.field = 'ETA_Request__c';
                valueETA.value = input.ETA_Request;
                cmd.values.add(valueETA);
            }
            	

            // Skip the actual metadata deployment during tests
            if (!Test.isRunningTest()) {
                Metadata.DeployContainer container = new Metadata.DeployContainer();
                container.addMetadata(cmd);

                try {
                    // Deploy Metadata (only during real execution, not in test context)
                    Id deployId = Metadata.Operations.enqueueDeployment(container, null);
                    System.debug('Deployment ID: ' + deployId);
                } catch (Exception e) {
                    throw new CustomException('Metadata deployment failed: ' + e.getMessage());
                }
            } else {
                // Log that metadata deployment is skipped in test
                System.debug('Skipping metadata deployment in test context');
            }
        }
    }

    // Input class for Flow
    public class MetadataInput {
        @InvocableVariable(label = 'Developer Name' required = true)
        public String DeveloperName;

        @InvocableVariable(label = 'Label' required = true)
        public String Label;

        @InvocableVariable(label = 'Aging 120 Flow Control')
        public Boolean Aging_120_Flow_Control;

        @InvocableVariable(label = 'Aging 75 Flow Control')
        public Boolean Aging_75_Flow_Control;

        @InvocableVariable(label = 'Aging 60 Flow Control')
        public Boolean Aging_60_Flow_Control;
        @InvocableVariable(label = 'Cancelled Call')
        public Boolean 	Cancelled_Call;
        @InvocableVariable(label = 'ETA Request')
        public Boolean 	ETA_Request;
    }

    // Exception handling
    public class CustomException extends Exception {}
}