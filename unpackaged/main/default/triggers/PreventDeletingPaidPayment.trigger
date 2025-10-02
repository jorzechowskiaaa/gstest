trigger PreventDeletingPaidPayment on ACG_Facility_Adjustment_Payment__c (before delete) {
    if (trigger.isBefore && trigger.isDelete) {
        if (!trigger.old.isEmpty()) {
            for (ACG_Facility_Adjustment_Payment__c fap : trigger.old) {
                List<Invoice_Line_Item__c> invoiceLIs = [SELECT Invoice__r.Status__c FROM Invoice_Line_Item__c WHERE Facility_Adjustment_Payment__c =: fap.Id AND Invoice__r.Status__c = 'Paid' LIMIT 1];

                if (!invoiceLIs.isEmpty() && invoiceLIs[0].Invoice__r.Status__c == 'Paid') {
                    fap.addError('Sorry you cannot delete a payment that has already been paid.');
                }
            }
        }
    }
}