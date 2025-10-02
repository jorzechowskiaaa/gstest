/************************************************************************************
 Apex Class Name     : ACG_TriggerHandlerInterface
 Created Date        : 22nd July  2021
 Function            : Interface methods to be used in all Triggers
 Author              : Deloitte Consulting
*************************************************************************************/

public Interface ACG_TriggerHandlerInterface{
    void beforeInsert(List<sObject> newItems);
    void beforeUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems);
    void beforeDelete(Map<Id, sObject> oldItems);
    void afterInsert(Map<Id, sObject> newItems);
    void afterUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems);
    void afterDelete(Map<Id, sObject> oldItems);
    void afterUndelete(Map<Id, sObject> oldItems);
}