public class AAAInvoiceReadyForPaymentBatch implements Database.Batchable<SObject>, Database.Stateful {
    public String query;
    private List<String> stmtIdList;

    public AAAInvoiceReadyForPaymentBatch() {
        this.stmtIdList = new List<String>();
    }

    public AAAInvoiceReadyForPaymentBatch(List<String> stmtIdList) {
        this.stmtIdList = stmtIdList;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (stmtIdList != null && stmtIdList.size() > 0) {
            query = 
                'SELECT '+
                    'Id,'+
                    'Status__c'+
                ' FROM Invoice__c'+
                ' WHERE Status__c = \'Ready for Processing\''+
                ' AND Statement__c IN (';

            for (Integer i = 0; i < stmtIdList.size(); i++) {
                String stmtId = stmtIdList[i];

                query += '\'' + stmtId + '\'';

                if (i < stmtIdList.size() - 1) {
                    query += ',';
                }
            }

            query += ')';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        List<Invoice__c> invcUpdateList = new List<Invoice__c>();

        for (Invoice__c invc : scope) {
            invc.Status__c = 'Ready for Payment';
            invcUpdateList.add(invc);
        }

        if (invcUpdateList.size() > 0) {
            update invcUpdateList;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch Job Completed');
    }
}