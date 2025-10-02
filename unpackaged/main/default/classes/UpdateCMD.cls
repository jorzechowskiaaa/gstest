/**
 * This invocable class will allow you to update/create custom metadata using Flow.
 * User running the flow needs only Read access to the custom metadata type.
 * Modified code from https://www.mhamzas.com/blog/2021/01/22/flow-create-update-custommetadata/
 * **/
global class UpdateCMD implements Metadata.DeployCallback {

@InvocableMethod(label = 'Update Custom Metadata')
    public static void updateMetadata(List <FlowInput> inputs) {
          for (flowInput input:  inputs) {
             
              for(sObject obj: input.data){
                  Map<String, Object> fieldsToValueMap = obj.getPopulatedFieldsAsMap();
                  Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
                  String MetadataDevName; // To Store Custom Metadata Record API/Developer name
                  String MetadataLabel; // To Store Custom Metadata Label name
                  // Looping on all the populated fields
                 
                  for (String fieldName : fieldsToValueMap.keySet()){
                      if(fieldName == 'Label'){
                          MetadataLabel = (String)fieldsToValueMap.get(fieldName);
                      } else if(fieldName == 'DeveloperName'){
                          MetadataDevName = (String)fieldsToValueMap.get(fieldName);
                      } else if(fieldName != 'Id') {
                          // Populating Map for Processing later
                          metadataFieldValueMap.put(fieldName, fieldsToValueMap.get(fieldName));
                      }
                  }
                 
                  System.debug('Label is ' + MetadataLabel + '& DeveloperName is ' + MetadataDevName);
                  // Making sure to have either Label or Developer Name for the CMD record to process
                  if(String.isBlank(MetadataDevName) && String.isBlank(MetadataLabel)){
                      throw new customException('Label and/or DeveloperName are required.');
                  } else {
                      if(!String.isBlank(MetadataDevName)){
                          UpdateCMD.updateCustomMetadata(String.valueof(obj.getSObjectType()),MetadataDevName, MetadataLabel,metadataFieldValueMap);
                       
                      
                      } else {
                          // First, check if the DeveloperName exists based on Label
                          // Needed bc some users with read access to custom metadata do not have access to DeveloperName
                          // No transaction limit on SOQL queries for custom metadata
                          String query = 'Select DeveloperName from ' + String.valueof(obj.getSObjectType()) + ' WHERE Label = \'' + MetadataLabel + '\' Limit 1';
                          List<sObject> devNames = Database.query(query);
                         
                          if(!devNames.isEmpty()) {
                              for (sobject objDev: devNames) {
                                Map<String, Object> devFieldsToValueMap = objDev.getPopulatedFieldsAsMap();
                                MetadataDevName = (String)objDev.get('DeveloperName');
                              }
                              System.debug('Metadata DeveloperName: ' + MetadataDevName);
                          }
                         
                          if(!String.isBlank(MetadataDevName)) {
                          UpdateCMD.updateCustomMetadata(String.valueof(obj.getSObjectType()),MetadataDevName, MetadataLabel,metadataFieldValueMap);
                            System.debug('Updating custom metadata');
                          }
                          else {    
                              UpdateCMD.createCustomMetadata(String.valueof(obj.getSObjectType()), MetadataLabel, metadataFieldValueMap);
                              System.debug('Creating custom metadata');
                          }
                       }
                  }
                  // END
              }
          }
    }
   
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            //Success
            System.debug('Success Result-' + result);
        } else {
            //Failed
            System.debug('Failed Result-' + result);
            throw new customException(String.valueof(result));
        }
    }
     
    //Create Custom Metadata record
    public static void createCustomMetadata(String metdataName, String label, Map<String, Object> metadataFieldValueMap){
        String recordDevName = label.replaceAll(' ', '_');
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
         
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key);
            cMetadata.values.add(cMetadataValue);
        }
        if (!Test.isRunningTest()) {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(cMetadata);
           
            UpdateCMD callback = new UpdateCMD();
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    //Update Custom Metadata record
    public static void updateCustomMetadata(String metdataName, String recordDevName, String label, Map<String, Object> metadataFieldValueMap){
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
         
        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key);
            cMetadata.values.add(cMetadataValue);
        }
         
        if (!Test.isRunningTest()) {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(cMetadata);
           
            UpdateCMD callback = new UpdateCMD();
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
     
    }

    // accepts a list (record collection) of custom metadata records
    public class FlowInput {
        @InvocableVariable(label = 'Metadata Records' required=True)
        public List<sObject> data;
    }
   
    // exception handling
    public class CustomException extends Exception {}
   
}