public class AAAPaymentCreationBatch implements Database.Batchable<SObject>, Schedulable {
    public String query;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = 
            'SELECT ' +
                'Id, ' +
                'Type__c, ' +
                'Status__c, ' +
                'Total_Amount__c, ' +
                'Service_Territory__c, ' +
                'Service_Territory__r.Facility_Number__c, ' +
                'Service_Territory__r.Name, ' +
                'Service_Territory__r.Street, ' +
                'Service_Territory__r.City, ' +
                'Service_Territory__r.State, ' +
                'Service_Territory__r.PostalCode, ' +
                'Facility_Adjustment__c, ' +
                'Facility_Adjustment_Category__c, ' +
                'Statement__c, ' +
                'Statement__r.SC5500_Basic__c, ' +
                'Statement__r.SC5500_Basic_Reciprocal__c, ' +
                'Statement__r.SC5500_Other__c, ' +
                'Statement__r.SC5500_Other_Reciprocal__c, ' +
                'Statement__r.SC5680_Plus__c, ' +
                'Statement__r.SC5680_Plus_Reciprocal__c, ' +
                'Statement__r.SC5680_RV__c, ' +
                'Statement__r.SC5680_RV_Reciprocal__c, ' +
                'Statement__r.SC5760_Premier__c, ' +
                'Statement__r.SC5760_Premier_Reciprocal__c, ' +
                'Statement__r.Status__c, ' +
                'Statement__r.Service_Territory__c, ' +
                'Statement__r.End_Date__c, ' +
                'Statement__r.Name, ' +
                'Statement__r.Processed__c' +
            ' FROM Invoice__c' +
            ' WHERE Status__c = \'Ready for Payment\'' +
                ' OR ' +
                    '(' +
                        'Service_Territory__r.IsActive = true ' +
                        'AND Service_Territory__r.Non_Payment_Facility__c = false ' +
                        'AND Statement__r.Status__c = \'Reconciled\' ' +
                        'AND Statement__r.Processed__c = false' +
                    ')';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        Map<Id, Map<String, Object>> statementMap = new Map<Id, Map<String, Object>>();
        List<Statement__c> statementUpdateList = new List<Statement__c>();
        List<Invoice__c> invoiceUpdateList = new List<Invoice__c>();
        List<Payment__c> paymentInsertList = new List<Payment__c>();
        Map<String, String> spendCategoryMap = new Map<String, String>();

        // build spend category map
        for(Spend_Category__mdt scMdt : [SELECT Id, Label, Spend_Category__c FROM Spend_Category__mdt]) {
            spendCategoryMap.put(scMdt.Label, scMdt.Spend_Category__c);
        }

        // build statement map so invoices are grouped by statement
        for(Invoice__c invoice : scope) {
            if(statementMap.get(invoice.Statement__c) == null) {
                Map<String, Object> container = new Map<String, Object>{
                    'statement' => invoice.Statement__r,
                    'invoices' => new List<Invoice__c>{
                        invoice
                    }
                };

                statementMap.put(invoice.Statement__c, container);
            } else {
                List<Invoice__c> tempList = (List<Invoice__c>) statementMap.get(invoice.Statement__c).get('invoices');

                tempList.add(invoice);
                statementMap.get(invoice.Statement__c).put('invoices', tempList);
            }
        }

        // iterate over each statement and do logic to create payment records
        for(Id key : statementMap.keySet()) {
            Map<String, Object> facAdjCatInvcMap = new Map<String, Object>();
            Map<String, Object> container = statementMap.get(key);
            Statement__c statement = (Statement__c) container.get('statement');
            List<Invoice__c> invoiceList = (List<Invoice__c>) container.get('invoices');
            String basic = 'Basic';
            String basicRec = 'Basic Reciprocal';
            String other = 'Other';
            String otherRec = 'Other Reciprocal';
            String plus = 'Plus';
            String plusRec = 'Plus Reciprocal';
            String rv = 'RV';
            String rvRec = 'RV Reciprocal';
            String premier = 'Premier';
            String premierRec = 'Premier Reciprocal';
            String paymentDesc = 'FACILITY PAYMENT';
            String pmtAddress = invoiceList[0].Service_Territory__r.Street;
            String pmtCity = invoiceList[0].Service_Territory__r.City;
            String pmtState = invoiceList[0].Service_Territory__r.State;
            String pmtZip = invoiceList[0].Service_Territory__r.PostalCode;
            Integer lineRow = 0;

            if (statement.SC5500_Basic__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = basic,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5500_Basic__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5500_Basic_Reciprocal__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = basicRec,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5500_Basic_Reciprocal__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5500_Other__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = other,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5500_Other__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5500_Other_Reciprocal__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = otherRec,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5500_Other_Reciprocal__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5680_Plus__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = plus,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5680_Plus__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5680_Plus_Reciprocal__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = plusRec,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5680_Plus_Reciprocal__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5680_RV__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = rv,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5680_RV__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5680_RV_Reciprocal__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = rvRec,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5680_RV_Reciprocal__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5760_Premier__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = premier,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5760_Premier__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }
    
            if (statement.SC5760_Premier_Reciprocal__c > 0) {
                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = invoiceList[0].Service_Territory__r.Facility_Number__c,
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = premierRec,
                        Spend_Category__c = spendCategoryMap.get(basic),
                        Amount__c = statement.SC5760_Premier_Reciprocal__c,
                        Vendor_Name__c = invoiceList[0].Service_Territory__r.Name,
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }

            // iterate through invoices and build map for same facility adjustment categories
            for(Invoice__c invoice : invoiceList) {
                if(invoice.Status__c == 'Ready for Payment') {
                    if(invoice.Type__c == 'Facility Adjustments') {
                        Map<String, Object> invcContainer;
                        String spendCategoryCode = spendCategoryMap.get(invoice.Facility_Adjustment_Category__c);
                        String facAdjCat = invoice.Facility_Adjustment_Category__c;

                        if(facAdjCatInvcMap.get(facAdjCat) == null) {
                            invcContainer = new Map<String, Object>{
                                'vendorId' => invoice.Service_Territory__r.Facility_Number__c,
                                'itemDesc' => facAdjCat,
                                'spendCat' => spendCategoryCode,
                                'amount' => invoice.Total_Amount__c,
                                'vendorName' => invoice.Service_Territory__r.Name
                            };
                        } else {
                            invcContainer = (Map<String, Object>) facAdjCatInvcMap.get(facAdjCat);

                            Decimal prevAmt = (Decimal) invcContainer.get('amount');
                            Decimal addAmt = invoice.Total_Amount__c;

                            invcContainer.put('amount', prevAmt + addAmt);
                        }

                        facAdjCatInvcMap.put(facAdjCat, invcContainer);
                    }

                    invoice.Status__c = 'Submitted for Payment';
                    invoiceUpdateList.add(invoice);
                }
            }

            // iterate over mapped facility adjustment categories and generate payment records
            for(String facAdjCatKey : facAdjCatInvcMap.keySet()) {
                Map<String, Object> invcCont = (Map<String, Object>) facAdjCatInvcMap.get(facAdjCatKey);

                paymentInsertList.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = invoiceList[0].Service_Territory__c,
                        Vendor_Id__c = (String) invcCont.get('vendorId'),
                        Document_Date__c = statement.End_Date__c,
                        Document_Number__c = statement.Name,
                        Document_Description__c = paymentDesc,
                        Line_Row__c = ++lineRow,
                        Item_Description__c = (String) invcCont.get('itemDesc'),
                        Spend_Category__c = (String) invcCont.get('spendCat'),
                        Amount__c = (Decimal) invcCont.get('amount'),
                        Vendor_Name__c = (String) invcCont.get('vendorName'),
                        Address_1__c = pmtAddress,
                        City__c = pmtCity,
                        State__c = pmtState,
                        Zip__c = pmtZip
                    )
                );
            }

            statement.Processed__c = true;
            statement.Payment_Date__c = Date.today();
            statementUpdateList.add(statement);
        }

        update statementUpdateList;
        update invoiceUpdateList;
        insert paymentInsertList;
    }

    public void finish(Database.BatchableContext bc) {
        // finished batch logic
        System.debug('Finished payment creation batch');
    }

    public void execute(SchedulableContext ctx) {
        AAAPaymentCreationBatch batch = new AAAPaymentCreationBatch();

        Database.executeBatch(batch, 200);
    }
}