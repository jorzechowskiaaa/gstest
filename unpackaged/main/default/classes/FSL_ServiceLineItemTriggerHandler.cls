public class FSL_ServiceLineItemTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<FSL_Service_Line_Item__c> newList = Trigger.new;
    List<FSL_Service_Line_Item__c> oldList = Trigger.old;
    Map<Id, FSL_Service_Line_Item__c> newMap = (Map<Id, FSL_Service_Line_Item__c>)Trigger.newMap;
    Map<Id, FSL_Service_Line_Item__c> oldMap = (Map<Id, FSL_Service_Line_Item__c>)Trigger.oldMap;

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FSL_Service_Line_Item__c');
    }

    public override void beforeInsert() {
        runMethod();
    }

    public static void runMethod() {
        System.debug('');
    }
}