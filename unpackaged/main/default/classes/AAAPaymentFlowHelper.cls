global without sharing class AAAPaymentFlowHelper {
    @InvocableMethod(label = 'Batch Payment Flow Helper')
    global static List<FlowOutput> runPaymentFlowHelper(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();

        for (FlowInput flowInput : input) {
            FlowOutput output = new FlowOutput();
            List<String> invcsToUpdate = new List<String>();
            List<Payment__c> pmtsToInsert = new List<Payment__c>();
            List<Spend_Category__mdt> scMdtList = flowInput.scMdtList;
            List<Statement_Field_Spend_Category_Mappings__mdt> fieldSCMdtList = flowInput.fieldSCMdtList;
            List<Invoice__c> invoiceList = flowInput.invcList;
            BackOffice_Settings__c boSettings = flowInput.boSettings;
            Statement__c statement = flowInput.stmt;
            ServiceTerritory fac = flowInput.fac;
            String paymentDesc = 'FACILITY PAYMENT';
            String clubCode = boSettings.Club_Code__c;
            String pmtVendor = fac.Name;
            String pmtAddress = fac.Street;
            String pmtCity = fac.City;
            String pmtState = fac.State;
            String pmtZip = fac.PostalCode;
            Integer lineRow = 0;
            Map<String,List<String>> scToStmtFieldsMap = new Map<String,List<String>>();
            Map<String, String> spendCategoryMap = new Map<String, String>();
            Map<String, Object> facAdjCatInvcMap = new Map<String, Object>();
            Map<String, Object> statementFieldsToValue = statement.getPopulatedFieldsAsMap();

            // build spend category map
            for(Spend_Category__mdt scMdt : scMdtList) {
                spendCategoryMap.put(scMdt.Label, scMdt.Spend_Category__c);
            }

            //build Statement Category To Statement Field Mapping
            for (Statement_Field_Spend_Category_Mappings__mdt scTostFieldMdt : fieldSCMdtList) {
                String scLabel = scTostFieldMdt.Spend_Category_Label__c;
                String mdtLabel = scTostFieldMdt.Label__c;

                if (
                    scToStmtFieldsMap.get(scLabel) != null 
                    && scToStmtFieldsMap.get(scLabel).size() > 0
                ) {
                    List<String> lstStatementFields = scToStmtFieldsMap.get(scLabel);

                    lstStatementFields.add(mdtLabel);
                    scToStmtFieldsMap.put(scLabel, lstStatementFields);                                                    
                } else {
                    scToStmtFieldsMap.put(scLabel, new List<String>{mdtLabel});
                }           
            }

            if (clubCode == '212') {
                if (String.isNotBlank(fac.DBA_Name__c)) {
                    pmtVendor = fac.DBA_Name__c;
                }

                String dbaAddress = fac.DBA_Address_Line_1__c;
                String dbaCity = fac.DBA_City__c;
                String dbaState = fac.DBA_State__c;
                String dbaZip = fac.DBA_Zip_Code__c;

                if (
                    String.isNotBlank(dbaAddress)
                    && String.isNotBlank(dbaCity)
                    && String.isNotBlank(dbaState)
                    && String.isNotBlank(dbaZip)
                ) {
                    pmtAddress = dbaAddress;
                    pmtCity = dbaCity;
                    pmtState = dbaState;
                    pmtZip = dbaZip;
                }
            }

            for (String scLabel : scToStmtFieldsMap.keySet()) {
                if (
                    scToStmtFieldsMap.get(scLabel) != null 
                    && scToStmtFieldsMap.get(scLabel).size() > 0
                ) {
                    Decimal totalCost = 0.00;
                    String spendCatNumber = '';

                    for (String stFieldName : scToStmtFieldsMap.get(scLabel)) {
                        Object obj = statementFieldsToValue.get(stFieldName);

                        if (obj != null) {
                            String costStr = String.valueOf(obj);

                            totalCost += Decimal.valueOf(costStr);
                        }
                    }
                    
                    if (spendCategoryMap.get(scLabel) != null) {
                        spendCatNumber = spendCategoryMap.get(scLabel);
                    }
                    
                    if (totalCost != 0.00) {
                        pmtsToInsert.add(
                            new Payment__c(
                                Statement__c = statement.Id,
                                Service_Territory__c = fac.Id,
                                Vendor_Id__c = fac.Facility_Number__c,
                                Document_Date__c = statement.End_Date__c,
                                Document_Number__c = statement.Name,
                                Document_Description__c = paymentDesc,
                                Line_Row__c = ++lineRow,
                                Item_Description__c = scLabel,
                                Spend_Category__c = spendCatNumber,
                                Amount__c = totalCost,
                                Vendor_Name__c = pmtVendor,
                                Address_1__c = pmtAddress,
                                City__c = pmtCity,
                                State__c = pmtState,
                                Zip__c = pmtZip
                            )
                        );
                    }  
                }
            }

            if (invoiceList != null && invoiceList.size() > 0) {
                // iterate through invoices and build map for same facility adjustment categories
                for (Invoice__c invoice : invoiceList) {
                    if (invoice.Status__c == 'Ready for Payment') {
                        if (invoice.Type__c == 'Facility Adjustments') {
                            Map<String, Object> invcContainer;
                            String facAdjCat = invoice.Facility_Adjustment_Category__c;
                            String adjType = invoice.Facility_Adjustment_Type__c;
                            Decimal total = invoice.Total_Amount__c;
                            String vendorName = fac.Name;
                            String spendCategoryCode = spendCategoryMap.get(facAdjCat);
    
                            if (adjType == 'Debit') {
                                total = -total;
                            }
    
                            if (clubCode == '212' && String.isNotBlank(fac.DBA_Name__c)) {
                                vendorName = fac.DBA_Name__c;
                            }
    
                            if (facAdjCatInvcMap.get(facAdjCat) == null) {
                                invcContainer = new Map<String, Object>{
                                    'vendorId' => fac.Facility_Number__c,
                                    'itemDesc' => facAdjCat,
                                    'spendCat' => spendCategoryCode,
                                    'amount' => total,
                                    'vendorName' => vendorName
                                };
                            } else {
                                invcContainer = (Map<String, Object>) facAdjCatInvcMap.get(facAdjCat);
                                            
                                Decimal prevAmt = (Decimal) invcContainer.get('amount');
                                            
                                invcContainer.put('amount', prevAmt + total);
                            }
                            
                            facAdjCatInvcMap.put(facAdjCat, invcContainer);
                        }
                        
                        invoice.Status__c = 'Submitted for Payment';
                        invcsToUpdate.add(invoice.Id);
                    }
                }
            }

            // iterate over mapped facility adjustment categories and generate payment records
            for (String facAdjCatKey : facAdjCatInvcMap.keySet()) {
                Map<String, Object> invcCont = (Map<String, Object>) facAdjCatInvcMap.get(facAdjCatKey);

                pmtsToInsert.add(
                    new Payment__c(
                        Statement__c = statement.Id,
                        Service_Territory__c = fac.Id,
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

            if (pmtsToInsert.size() > 0) {
                output.hasPmtsToInsert = true;
                output.pmtList = pmtsToInsert;
            }

            if (invcsToUpdate.size() > 0) {
                output.hasInvcsToUpdate = true;
                output.invcList = invcsToUpdate;
            }

            statement.Payment_Date__c = Date.today();
            statement.Processed__c = true;
            output.hasStmtToUpdate = true;
            output.stmt = statement;

            outputList.add(output);
        }

        return outputList;
    }

    global class FlowInput {
        @InvocableVariable(label = 'Statement') global Statement__c stmt;
        @InvocableVariable(label = 'Service Territory') global ServiceTerritory fac;
        @InvocableVariable(label = 'Back Office Settings') global BackOffice_Settings__c boSettings;
        @InvocableVariable(label = 'Spend Category Metadata') global List<Spend_Category__mdt> scMdtList;
        @InvocableVariable(label = 'Statement Field Spend Category Mapping Metadata') global List<Statement_Field_Spend_Category_Mappings__mdt> fieldSCMdtList;
        @InvocableVariable(label = 'Invoices') global List<Invoice__c> invcList;
    }
    
    global class FlowOutput {
        @InvocableVariable(label = 'Has Payments To Insert') global Boolean hasPmtsToInsert;
        @InvocableVariable(label = 'Payments To Insert') global List<Payment__c> pmtList;
        @InvocableVariable(label = 'Has Invoices To Update') global Boolean hasInvcsToUpdate;
        @InvocableVariable(label = 'Invoice Ids To Update') global List<String> invcList;
        @InvocableVariable(label = 'Has Statement To Update') global Boolean hasStmtToUpdate;
        @InvocableVariable(label = 'Statement To Update') global Statement__c stmt;
    }
}