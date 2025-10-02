/************************************************************************************
 Apex Class Name     : ACG_TriggerDispatcher
 Created Date        : 22nd July 2021
 Function            : Dispatcher method used to call methods based on Trigger Context
 Author              : Deloitte Consulting
*************************************************************************************/

public class ACG_TriggerDispatcher{
    /*
        NOTE: Call this static method from Trigger and pass instance of TriggerHandler which implements TriggerHandlerInterface
    */
    public static void run(ACG_TriggerHandlerInterface handler){
        //Before Trigger Logic
        if (Trigger.IsBefore){
            if(Trigger.IsInsert){
                handler.beforeInsert(trigger.new);
            }
            if(Trigger.IsUpdate){
                handler.beforeUpdate(trigger.newMap, trigger.oldMap);
            }
            if(Trigger.IsDelete){
                handler.beforeDelete(trigger.oldMap);
            }
        }
        //After Trigger Logic
        if (Trigger.IsAfter){
            if(Trigger.IsInsert){
                handler.afterInsert(Trigger.newMap);
            }
            if(Trigger.IsUpdate){
                handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
            if(Trigger.IsDelete){
                handler.afterDelete(Trigger.oldMap);
            }
            if(Trigger.IsUndelete){
                handler.afterUndelete(Trigger.newMap);
            }
        }
    }
}