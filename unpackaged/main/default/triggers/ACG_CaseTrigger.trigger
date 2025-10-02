/************************************************************************************
 Trigger Name        : ACG_CaseTrigger
 Created Date        : 16th Aug 2021
 Function            : Trigger for Case Object.
 Author              : Deloitte Consulting
*************************************************************************************/

trigger ACG_CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    //Get Skip Automations setting for current/logged-in user.
    //ACG_Skip_Automations__c objSkipAutomations = ACG_Skip_Automations__c.getInstance();
    
	 
    //Get Bypass Trigger setting for Individual triggers for objects.
    Execute_Trigger__c objBypassTrigger = Execute_Trigger__c.getInstance('Case');
    
    if(objBypassTrigger == null || objBypassTrigger.Disabled__c == false){
    //if(objSkipAutomations.ACG_Skip_Trigger__c == false){
        ACG_CaseTriggerHandler objCaseTriggerHandler = new ACG_CaseTriggerHandler();
       	ACG_TriggerDispatcher.Run(objCaseTriggerHandler);
    //}
	}
	
}