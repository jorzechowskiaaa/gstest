public class FSL_AllocationTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<Allocations__c> newList = Trigger.new;
    List<Allocations__c> oldList = Trigger.old;
    Map<Id, Allocations__c> newMap = (Map<Id, Allocations__c>) Trigger.newMap;
    Map<Id, Allocations__c> oldMap = (Map<Id, Allocations__c>) Trigger.oldMap;

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Allocations__c');
    }

    public override void beforeInsert() {
        validateOtherAccount(newList);
    }

    public static void validateOtherAccount(List<Allocations__c> allocations) {
        for (Allocations__c allocation : allocations) {
            if (allocation.Account__c == 'OTHER' && allocation.Other_Account__c == null) {
                allocation.addError('Other Account field must be populated if Charge to Account is "OTHER".');
            }
        }
    }
}