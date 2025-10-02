/****
 * *@Name: ServiceAppointment
 * *@Description: when the workorder is created Update the ServiceAppointment Address,lat,lag etc.. from WorkOrder. *  * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0                 Vincent               Initial Version
 *  *     04/20/2021   Dylan Truong         UpdateSertMetaData
 ***/

public with sharing class FSL_MetaDataUtility{

    public static String upsertMetadata(List<sObject> customMetadataList ) {
    
        //Create Deployment container for custom Metadata
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer = createMetaDataDeployContainer(customMetadataList);
        Id jobId = '111A0000000A11A'; //Fake Id Job
        // Enqueue custom metadata deployment
        // jobId is the deployment ID
        // Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback); // if you would like to have a asynchronous call.
        if (mdContainer != null && !Test.isRunningTest()) {
            jobId =  Metadata.Operations.enqueueDeployment(mdContainer, null);// make synchronous call
        }
        return jobId;
    }

    @testVisible
    private static Metadata.DeployContainer createMetaDataDeployContainer(List<sObject> customMetadataList )
    {
        //Create Deployment container for custom Metadata
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(sobject sObMD : customMetadataList) {
            
            //Get metadata object name and details
            String sObjectname = sObMD.getSObjectType().getDescribe().getName();
            
            //Create custom Metadata instance
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            String recordName = String.valueOf(sObMD.get('DeveloperName')).replaceAll(' ','_');
            customMetadata.fullName = sObjectname +'.'+recordName;
            customMetadata.label = (String)sObMD.get('MasterLabel');
            
            //Get all fields
            schema.SObjectType sobjType = Schema.getGlobalDescribe().get(sObjectname );

            Set<String> skipFieldSet = new Set<String>{'developername','masterlabel','language','namespaceprefix', 'label','qualifiedapiname', 'id'};
            
            // Use getPopulatedFieldsAsMap to get the populate field and iterate over them
            for(String fieldName : sObMD.getPopulatedFieldsAsMap().keySet()) {
                if(skipFieldSet.contains(fieldName.toLowerCase())|| sObMD.get(fieldName) == null)
                    continue;
                
                Object value = sObMD.get(fieldName);    
                //create field instance and populate it with field API name and value
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = fieldName;
                customField.value = value;
                //Add fields in the object, similar to creating sObject instance
                customMetadata.values.add(customField);
            }
            //Add metadata in container
            mdContainer.addMetadata(customMetadata);
        }
        return mdContainer;
    }

}