public class FSL_ContactTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<Contact> newList = Trigger.new;
    List<Contact> oldList = Trigger.old;
    Map<Id, Contact> newMap = (Map<Id, Contact>)Trigger.newMap;
    Map<Id, Contact> oldMap = (Map<Id, Contact>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Contact');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        conService.onBeforeInsert(newList);            
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        conService.onBeforeUpdate(oldMap, newMap);
    }


    FSL_Contact.Factory factory = new FSL_Contact.Factory();
    FSL_Contact.IContactService conService = factory.createService();


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================
}