trigger ACG_Facility_Adjustment_Trigger on ACG_Facility_Adjustment__c (before insert, after insert, before update, after update, before delete, after delete) {
	FSL_TriggerDispatcher.run(new ACG_Facility_Adj_TriggerHandler());  
}