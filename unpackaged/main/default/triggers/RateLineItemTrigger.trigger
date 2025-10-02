trigger RateLineItemTrigger on Rate_Line_Item__c (after update) {
    Set<Id> rateLineItemIdsToApprove = new Set<Id>();
    Set<Id> rateLineItemIdsToReject = new Set<Id>(); // Set to collect rejected items
    Set<Id> contractIds = new Set<Id>();

    // Iterate through the updated Rate Line Items
    for (Rate_Line_Item__c item : Trigger.new) {
        if (item.Contract__c != null) {
            contractIds.add(item.Contract__c);
        }

        // Collect items that are being approved
        if (item.Approval_Status__c == 'Approved' && Trigger.oldMap.get(item.Id).Approval_Status__c != 'Approved') {
            rateLineItemIdsToApprove.add(item.Id);
        }

        // Collect items that are being rejected
        if (item.Approval_Status__c == 'Rejected' && Trigger.oldMap.get(item.Id).Approval_Status__c != 'Rejected') {
            rateLineItemIdsToReject.add(item.Id);
        }
    }

    // Process approved rate line items (if any)
    if (!rateLineItemIdsToApprove.isEmpty()) {
        RateLineItemTriggerHandler.updateRateLineItemsForApproval(rateLineItemIdsToApprove);
    }

    // Process rejected rate line items (if any) for deletion logic
    if (!rateLineItemIdsToReject.isEmpty()) {
        RateLineItemTriggerHandler.handleRejectedStatusWithHistory(rateLineItemIdsToReject);
    }

    // Process contract updates if necessary
    if (!contractIds.isEmpty()) {
        RateLineItemTriggerHandler.checkAndUpdateContractIsDeleted(contractIds);
    }
}