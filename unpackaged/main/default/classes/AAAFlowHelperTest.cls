@isTest
private class AAAFlowHelperTest {
    
    @isTest
    static void testSplit(){
        List<AAAFlowHelper.inputVariables> inputVars = new List<AAAFlowHelper.inputVariables>();
        List<String> choicesMulti = new List<String>();
        
        String multi = 'a;b;c;';
        choicesMulti.add(multi);
        AAAFlowHelper.inputVariables inputVar = new  AAAFlowHelper.inputVariables();
        inputVar.choicesMulti = choicesMulti;
        inputVars.add(inputVar);
        
        List<AAAFlowHelper.outputVariables> results = AAAFlowHelper.splitMultiSelect(inputVars);
        
        System.assertEquals(3, results[0].choicesSplit.size());
        
    }
    
        @isTest
    static void testNullString(){
        List<AAAFlowHelper.inputVariables> inputVars = new List<AAAFlowHelper.inputVariables>();
        List<String> choicesMulti = new List<String>();
        
        String multi = '';
        choicesMulti.add(multi);
        AAAFlowHelper.inputVariables inputVar = new  AAAFlowHelper.inputVariables();
        inputVar.choicesMulti = choicesMulti;
        inputVars.add(inputVar);
        
        List<AAAFlowHelper.outputVariables> results = AAAFlowHelper.splitMultiSelect(inputVars);
        
        System.assertEquals('', results[0].choicesSplit[0]);
        
    }
    
        @isTest
    static void testNull(){
        List<AAAFlowHelper.inputVariables> inputVars = new List<AAAFlowHelper.inputVariables>();
        
        List<AAAFlowHelper.outputVariables> results = AAAFlowHelper.splitMultiSelect(inputVars);
        
        System.assertEquals(null, results);
        
    }    

}