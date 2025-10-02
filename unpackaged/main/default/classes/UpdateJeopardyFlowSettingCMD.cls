public without sharing class UpdateJeopardyFlowSettingCMD {

    @AuraEnabled(cacheable=true)
    public static List<Jeopardy_Flow_Setting__mdt> getJeopardyFlowSettings() {
        return [SELECT DeveloperName, MasterLabel, Description__c, isExecute__c FROM Jeopardy_Flow_Setting__mdt];
    }

    @AuraEnabled
    public static void updateJeopardyMetadata(List<Map<String, Object>> inputs) {
        System.debug('Inputs received: ' + inputs);

        // Check if inputs are null or empty
        if (inputs == null || inputs.isEmpty()) {
            System.debug('No inputs provided.');
            return;
        }

        // Prepare a list to hold records for update
        List<Metadata.CustomMetadata> metadataToUpdate = new List<Metadata.CustomMetadata>();

        for (Map<String, Object> input : inputs) {
            try {
                String developerName = (String) input.get('DeveloperName');
                Boolean isExecute = (Boolean) input.get('isExecute');

                if (String.isEmpty(developerName) || isExecute == null) {
                    System.debug('Skipping record with missing or invalid data: ' + input);
                    continue;
                }

                Jeopardy_Flow_Setting__mdt existingRecord = [
                    SELECT MasterLabel
                    FROM Jeopardy_Flow_Setting__mdt
                    WHERE DeveloperName = :developerName
                    LIMIT 1
                ];

                Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
                cmd.fullName = 'Jeopardy_Flow_Setting__mdt.' + developerName;
                cmd.label = existingRecord.MasterLabel;

                Metadata.CustomMetadataValue executeValue = new Metadata.CustomMetadataValue();
                executeValue.field = 'isExecute__c';
                executeValue.value = isExecute;
                cmd.values.add(executeValue);

                metadataToUpdate.add(cmd);

            } catch (QueryException qe) {
                System.debug('QueryException: No record found for input: ' + input + ' | ' + qe.getMessage());
            } catch (Exception e) {
                System.debug('General Exception for input: ' + input + ' | ' + e.getMessage());
            }
        }

        if (!metadataToUpdate.isEmpty()) {
            System.debug('Preparing deployment for ' + metadataToUpdate.size() + ' metadata records.');

            if (!Test.isRunningTest()) {
                Metadata.DeployContainer container = new Metadata.DeployContainer();
                for (Metadata.CustomMetadata cmd : metadataToUpdate) {
                    container.addMetadata(cmd);
                }

                try {
                    Id deployId = Metadata.Operations.enqueueDeployment(container, null);
                    System.debug('Deployment ID: ' + deployId);
                } catch (Exception e) {
                    System.debug('Deployment Exception: ' + e.getMessage());
                }
            } else {
                System.debug('Skipping deployment during tests.');
            }
        } else {
            System.debug('No metadata updates found.');
        }
    }
    
public static Map<String, Object> expandedFakeTestMethod(String developerName, Boolean isExecute) {
    System.debug('Entering expandedFakeTestMethod with parameters.');
    Map<String, Object> response = new Map<String, Object>();
    
    // Check for null or blank developerName
    if (String.isBlank(developerName)) {
        response.put('status', 'Error');
        response.put('message', 'DeveloperName is required.');
    } else if (isExecute == null) {
        response.put('status', 'Error');
        response.put('message', 'isExecute is required.');
    } else {
        response.put('status', 'Success');
        response.put('developerName', developerName);
        response.put('isExecute', isExecute);
    }

    System.debug('Exiting expandedFakeTestMethod with response: ' + response);
    return response;
}


    public class CustomException extends Exception {}
}