trigger FSL_InvoiceLineItemTrigger on Invoice_Line_Item__c (before insert) {
    FSL_TriggerDispatcher.run(new FSL_InvoiceLineItemTriggerHandler());
}