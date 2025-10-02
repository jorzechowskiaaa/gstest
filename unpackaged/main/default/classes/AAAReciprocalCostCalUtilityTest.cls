@isTest
class AAAReciprocalCostCalUtilityTest {
    @isTest
    static void runIntegrationServiceInvocableTest() {
        List<AAAReciprocalCostCalUtility.CostInput> inputList = new List<AAAReciprocalCostCalUtility.CostInput>();
        AAAReciprocalCostCalUtility.CostInput costInput = new AAAReciprocalCostCalUtility.CostInput();
        List<String> expectedOutputList = new List<String>{
            '00000100',
            '0000000000200',
            '000000000000000300'
        };
        
        costInput.lstAmounts = new List<Integer>{100, 200, 300};
        costInput.lstLeadingZeroes = new List<Integer>{5, 10, 15};
        inputList.add(costInput);

        List<AAAReciprocalCostCalUtility.CostOutput> outputList = AAAReciprocalCostCalUtility.runIntegrationServiceInvocable(inputList);
        AAAReciprocalCostCalUtility.CostOutput costOutput = (AAAReciprocalCostCalUtility.CostOutput) outputList[0];
        List<String> costOutputList = (List<String>) costOutput.output;

        for(Integer i = 0; i < expectedOutputList.size(); i++) {
            System.assertEquals(costOutputList[i], expectedOutputList[i], 'Returned cost output list does not match expected output.');
        }
    }
}