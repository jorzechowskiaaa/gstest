@isTest
class FSL_AllocationTriggerHandlerTest {
    @isTest
    static void validateOtherAccountTest() {
        Boolean hasError = false;
        String validationError = 'Other Account field must be populated if Charge to Account is "OTHER"';

        try {
            insert new Allocations__c(
                Account__c = 'OTHER',
                Approved__c  = 50.00
            );
        } catch (Exception e) {
            if (e.getMessage().contains(validationError)) {
                hasError = true;
            }
        }

        System.assertEquals(true, hasError, 'Failed to validate field.');
    }
}