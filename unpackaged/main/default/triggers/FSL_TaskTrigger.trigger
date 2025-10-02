/*****
*@Name:FSL_TaskTrigger
*@Description: Trigger is on Task object to check for violations like PTA,Enroute,Dispatched..etc.
*@CreatedDate:01-Aug-2019
*****/
trigger FSL_TaskTrigger on Task (After Insert, Before Insert) {
    //FSL_TriggerDispatcher.run(new FSL_TaskTriggerHandler());

}