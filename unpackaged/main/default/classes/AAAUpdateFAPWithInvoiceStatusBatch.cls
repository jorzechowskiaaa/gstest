/**
 * @description       : Batch class that helps update Facility Adjustment Payments with the associated Invoice's status
 * @author            : joshtupas@salesforce.com 
 * @group             : 
 * @last modified on  : 05-28-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   05-03-2024   joshtupas@salesforce.com  
 *       05-28-2024   joshtupas@salesforce.com             Refactored query to use SOQL instead of query string
**/
public class AAAUpdateFAPWithInvoiceStatusBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    public String query;
    private List<String> invcIdList;

    public AAAUpdateFAPWithInvoiceStatusBatch() {
        this.invcIdList = new List<String>();
    }

    public AAAUpdateFAPWithInvoiceStatusBatch(List<String> invcIdList) {
        this.invcIdList = invcIdList;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (invcIdList != null && invcIdList.size() > 0) {
            return Database.getQueryLocator(
                [
                    SELECT 
                        Id,
                        Facility_Adjustment_Payment__r.ACG_Status__c,
                        Invoice__r.Status__c
                    FROM Invoice_Line_Item__c
                    WHERE Facility_Adjustment_Payment__c != null
                    AND Invoice__c IN :invcIdList
                ]
            );
        }
        
        return Database.getQueryLocator(
            [
                SELECT 
                    Id,
                    Facility_Adjustment_Payment__r.ACG_Status__c,
                    Invoice__r.Status__c
                FROM Invoice_Line_Item__c
                WHERE Facility_Adjustment_Payment__c != null
                AND Facility_Adjustment_Payment__r.ACG_Status__c = null
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Invoice_Line_Item__c> scope) {
        List<ACG_Facility_Adjustment_Payment__c> fapUpdateList = new List<ACG_Facility_Adjustment_Payment__c>();

        for (Invoice_Line_Item__c ili : scope) {
            String invcStatus = ili.Invoice__r.Status__c;
            ACG_Facility_Adjustment_Payment__c fap = ili.Facility_Adjustment_Payment__r;

            if (fap.ACG_Status__c != invcStatus) {
                fap.ACG_Status__c = invcStatus;
                fapUpdateList.add(fap);
            }
        }

        if (fapUpdateList.size() > 0) {
            update fapUpdateList;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch Job Completed');
    }

    public void execute(SchedulableContext ctx) {
        AAAUpdateFAPWithInvoiceStatusBatch batch = new AAAUpdateFAPWithInvoiceStatusBatch();

        Database.executeBatch(batch, 1000);
    }
}