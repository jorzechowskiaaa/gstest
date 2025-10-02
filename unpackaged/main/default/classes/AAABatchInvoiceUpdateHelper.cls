/**
 * @description       : Batch class that helps update Invoice status then proceeds to update associated Facility Adjustment Payments
 * @author            : joshtupas@salesforce.com 
 * @group             : 
 * @last modified on  : 05-28-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   05-16-2024   joshtupas@salesforce.com  
 *       05-28-2024   joshtupas@salesforce.com             Removed looping for appending Invoice Ids to batch query. Included logic to invoke AAAUpdateFAPWithInvoiceStatusBatch only on Invoices that are type 'Facility Adjustments'.
**/
public class AAABatchInvoiceUpdateHelper implements Database.Batchable<SObject>, Database.Stateful {
    public String query;
    private String newStatus;
    List<String> invcIdList;

    public AAABatchInvoiceUpdateHelper() {}

    public AAABatchInvoiceUpdateHelper(String query, String newStatus) {
        this.query = query;
        this.newStatus = newStatus;
        this.invcIdList = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = query != null && newStatus != null ? query : '';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        List<Invoice__c> invcUpdateList = new List<Invoice__c>();

        for (Invoice__c invc : scope) {
            invc.Status__c = this.newStatus;
            invcUpdateList.add(invc);

            if (invc.Type__c == 'Facility Adjustments') {
                invcIdList.add(invc.Id);
            }
        }

        if (invcUpdateList.size() > 0) {
            update invcUpdateList;
        }
    }

    public void finish(Database.BatchableContext bc) {
        Database.executeBatch(new AAAUpdateFAPWithInvoiceStatusBatch(invcIdList), 1000);
    }
}