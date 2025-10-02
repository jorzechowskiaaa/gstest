trigger FSL_InvoiceTrigger on Invoice__c (after insert, before update, after update, after delete, after undelete) {
    FSL_TriggerDispatcher.run(new FSL_InvoiceTriggerHandler());
}