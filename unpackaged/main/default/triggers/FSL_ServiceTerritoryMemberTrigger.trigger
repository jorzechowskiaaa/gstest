/**
 * Modified by Clement Shiu 7/23/2022 - use ACE Trigger pattern
 */

trigger FSL_ServiceTerritoryMemberTrigger on ServiceTerritoryMember (after insert, after update, before insert, before update) {    
    FSL_TriggerDispatcher.run(new FSL_ServiceTerritoryMemberTriggerHandler());
}