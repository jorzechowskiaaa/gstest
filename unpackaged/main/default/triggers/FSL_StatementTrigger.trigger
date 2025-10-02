trigger FSL_StatementTrigger on Statement__c (after update) {
    FSL_TriggerDispatcher.run(new FSL_StatementTriggerHandler());
}