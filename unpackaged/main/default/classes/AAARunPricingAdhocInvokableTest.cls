@isTest
public class AAARunPricingAdhocInvokableTest {
    @isTest
    static void runAdhocPricingTest() {
        Boolean hasError = false;

        try {
            AAARunPricingAdhocInvokable.runAdhocPricing();
        } catch (Exception e) {
            hasError = true;
        }

        System.assertEquals(false, hasError, 'Failed.');
    }
}