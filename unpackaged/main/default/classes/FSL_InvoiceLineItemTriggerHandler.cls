public class FSL_InvoiceLineItemTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<Invoice_Line_Item__c> newList = Trigger.new;
    List<Invoice_Line_Item__c> oldList = Trigger.old;
    Map<Id, Invoice_Line_Item__c> newMap = (Map<Id, Invoice_Line_Item__c>)Trigger.newMap;
    Map<Id, Invoice_Line_Item__c> oldMap = (Map<Id, Invoice_Line_Item__c>)Trigger.oldMap;

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Invoice_Line_Item__c');
    }

    public override void beforeInsert() {
        System.debug('');
    }
}