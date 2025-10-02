trigger FSL_AllocationTrigger on Allocations__c (before insert) {
    FSL_TriggerDispatcher.run(new FSL_AllocationTriggerHandler());
}