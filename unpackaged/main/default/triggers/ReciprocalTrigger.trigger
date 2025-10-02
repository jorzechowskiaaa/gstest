trigger ReciprocalTrigger on Reciprocal__c (before insert, before update, after update) {   
    FSL_TriggerDispatcher.run(new FSL_ReciprocalApexClass());
}