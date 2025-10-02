global without sharing class AAAIPInvocableWithOutputs {
 @InvocableMethod(label = 'Call Integration Procedure With Outputs')
 global static List<IntegrationProcedureOutput> runIntegrationServiceInvocable(List < IntegrationProcedureInput > input) {
  //System.debug(LoggingLevel.Error, JSON.serialize(input));
  //System.debug('Input:111111111111 ' +input[0].lstServItemsInput); //SF support debug lines
  //System.debug('22222222222222222 ' +JSON.serialize (input[0].lstServItemsInput));
   //Create Input            
   Map<String,Object> mapInputs = new Map<String,Object>();
   mapInputs.put('workOrderId',input[0].currentWorkOrderId);
   mapInputs.put('ServiceLineItem',JSON.deserializeUntyped(JSON.serialize(input[0].lstServItemsInput)));
   //system.debug(' ####### Final Map of Inputs ########### '+mapInputs);
   //Call IP            
   IntegrationProcedureOutput result = new IntegrationProcedureOutput();
   Map<String, Object> ipOutput = new Map<String, Object> (); 
     
     try {
            ipOutput = (Map<String, Object>)omnistudio.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(
                input[0].procedureAPIName,
                 mapInputs,
                new Map < String, Object > ());
        } catch(DmlException e) {
            system.debug(' ##### DmlException #### '+ e);
        }
     
     
    //system.debug(' ##### TEST TEST ipOutput 02 #### '+ ipOutput);
    //system.debug(' ############# First Output ##############  '+result.lstServItemsOutput ); 
     
    //System.debug(LoggingLevel.Error, JSON.serialize(result));
    result.lstServItemsOutput = JSON.serialize(ipOutput.get('ServiceLineItem'));
     
    //IntegrationProcedureOutput test = new IntegrationProcedureOutput();
     //test.lstServItemsOutput = result.lstServItemsOutput;
     List <IntegrationProcedureOutput> res = new List <IntegrationProcedureOutput>();
     res.add(result);
    return res;
 }
 global class IntegrationProcedureInput
 {
  @InvocableVariable(label = 'Procedure Name') global String procedureAPIName;
  @InvocableVariable(label = 'Work Order') global Id currentWorkOrderId;
  @InvocableVariable(label = 'Service Items Input') global List<FSL_Service_Line_Item__c> lstServItemsInput;
 }
 global class IntegrationProcedureOutput
 {
  @InvocableVariable(label = 'Service Items Output') global String lstServItemsOutput;
 }
}