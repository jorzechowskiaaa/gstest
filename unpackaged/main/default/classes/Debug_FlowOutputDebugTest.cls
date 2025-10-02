@isTest
class Debug_FlowOutputDebugTest {
    @isTest
    static void debugFlowTest() {
        Boolean hasException = false;
        Debug_FlowOutputDebug.FlowInput input = new Debug_FlowOutputDebug.FlowInput();

        input.debugInput = 'APEX TEST';

        try {
            Debug_FlowOutputDebug.runDebugFlow(new List<Debug_FlowOutputDebug.FlowInput>{input});
        } catch (Exception e) {
            hasException = true;
        }

        System.assertEquals(hasException, false, 'Encountered error when invoking method.');
    }
}