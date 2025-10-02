trigger AAA_Reimbursement_Trigger on ACG_Reimbursement__c (before insert, before update, after insert) {
	FSL_TriggerDispatcher.run(new AAA_ReimbusementTriggerHandler());  
}