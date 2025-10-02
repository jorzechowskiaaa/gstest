global without sharing class Debug_FlowOutputDebug {
    @InvocableMethod(label = 'Call Debug')
    global static void runDebugFlow(List<FlowInput> input) {
        if (input != null && input.size() > 0) {
            String debugInput = input[0].debugInput;
            List<FSL_Service_Line_Item__c> sliList = input[0].sliList;
            FSL_Service_Line_Item__c sli = input[0].sli;
            Boolean serializePretty = input[0].serializePretty != null ? 
                input[0].serializePretty : false;
                
            System.debug('An exception has occured. Please investigate logs before this output.');
            System.debug(debugInput);
            System.debug('SLI List Size: ' + sliList?.size());
            
            if (serializePretty) {
                System.debug(JSON.serializePretty(input));
            } else {
                System.debug(sliList);
                System.debug(sli);
            }
        }
    }

    global class FlowInput {
        @InvocableVariable(label = 'Debug String') global String debugInput;
        @InvocableVariable(label = 'SLI List') global List<FSL_Service_Line_Item__c> sliList;
        @InvocableVariable(label = 'Serialized Pretty Output') global Boolean serializePretty;
        @InvocableVariable(label = 'SLI') global FSL_Service_Line_Item__c sli;
    }
}