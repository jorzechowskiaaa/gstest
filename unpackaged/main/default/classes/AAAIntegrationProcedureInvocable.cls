global without sharing class AAAIntegrationProcedureInvocable {
 @InvocableMethod(label = 'Call Integration Procedure')
 global static void runIntegrationServiceInvocable(List < IntegrationProcedureInput > input) {
  System.debug(LoggingLevel.Error, JSON.serialize(input));
  System.debug('Input: ' +input); //SF support debug lines
     //IntegrationProcedureOutput result = new IntegrationProcedureOutput();
   //result.output = JSON.serialize(
   omnistudio.IntegrationProcedureService.runIntegrationService(
    input[0].procedureAPIName,
    new Map < String, Object >
    {
     'workOrderId' => input[0].currentWorkOrderId
    },
    new Map < String, Object > ());
    //);
  //System.debug(LoggingLevel.Error, JSON.serialize(result));
  /*return new List < IntegrationProcedureOutput >
   {
    result
   };/*/
   //return null;
 }
 global class IntegrationProcedureInput
 {
  @InvocableVariable(label = 'Procedure Name') global String procedureAPIName;
  @InvocableVariable(label = 'Work Order') global Id currentWorkOrderId;
  //@InvocableVariable(label = 'Service Items Input') global List<FSL_Service_Line_Item__c> lstServItemsInput;
 }
 /*global class IntegrationProcedureOutput
 {
  @InvocableVariable(label = 'Service Items Output') global List<FSL_Service_Line_Item__c> lstServItemsOutput;
 }*/
}