public class FSL_InvoiceTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<Invoice__c> newList = Trigger.new;
    List<Invoice__c> oldList = Trigger.old;
    Map<Id, Invoice__c> newMap = (Map<Id, Invoice__c>) Trigger.newMap;
    Map<Id, Invoice__c> oldMap = (Map<Id, Invoice__c>) Trigger.oldMap;
    private static BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
    private static String currUserId = UserInfo.getUserId();
    private static List<PermissionSetAssignment> permSetList = [
        SELECT Id
        FROM PermissionSetAssignment 
        WHERE PermissionSet.Name = 'Skip_Automation_Logic'
        AND AssigneeId = :currUserId
    ];

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Invoice__c');
    }

    public override void afterInsert() {
        rollUpValuesToStatement(oldList, newList, oldMap, newMap);
    }

    public override void beforeUpdate() {
        preventDeferredEdits(oldMap, newList);
    }

    public override void afterUpdate() {
        rollUpValuesToStatement(oldList, newList, oldMap, newMap);
        updateFAPStatus(oldList, newList, oldMap, newMap);
    }

    public override void afterUnDelete() {
        rollUpValuesToStatement(oldList, newList, oldMap, newMap);
    }

    public override void afterDelete() {
        rollUpValuesToStatement(oldList, newList, oldMap, newMap);
    }

    public static void preventDeferredEdits(Map<Id, Invoice__c> oldMap, List<Invoice__c> newList) {
        if (oldMap != null && newList != null && newList.size() > 0) {
            for (Invoice__c newInvc : newList) {
                Map<String, Object> newFieldsToValues = newInvc.getPopulatedFieldsAsMap();
                Invoice__c oldInvc = oldMap.get(newInvc.Id);

                if (
                    oldInvc != null 
                    && oldInvc.Type__c == 'Facility Adjustments' 
                    && oldInvc.Status__c == 'Deferred' 
                    && newInvc.Status__c == 'Deferred'
                ) {
                    for (String fieldName : newFieldsToValues.keySet()) {
                        if (
                            fieldName != 'Status__c'
                            && oldInvc.get(fieldName) != newInvc.get(fieldName)
                        ) {
                            newInvc.addError('Unable to edit deferred Invoices.');
                        }
                    }
                }
            }
        }
    }

    public static void rollUpValuesToStatement(
        List<Invoice__c> oldInvcList, List<Invoice__c> newInvcList,
        Map<Id, Invoice__c> oldMap, Map<Id, Invoice__c> newMap
    ) {
        // skip rollup logic if Data Migration user
        if (permSetList == null || permSetList.size() == 0) {
            Boolean runRollupLogic = false;
            List<Invoice__c> invcProcessList = new List<Invoice__c>();

            // on update, check fields to make sure to run if amounts were updated
            if (
                oldInvcList != null 
                && newInvcList != null 
                && oldInvcList.size() > 0
                && oldInvcList.size() == newInvcList.size()
            ) {
                for (Invoice__c oldInvc : oldInvcList) {
                    Invoice__c newInvc = newMap.get(oldInvc.Id);

                    if (
                        oldInvc.Other_Cost_Tax__c != newInvc.Other_Cost_Tax__c
                        || oldInvc.RV_Cost_Tax__c != newInvc.RV_Cost_Tax__c
                        || oldInvc.Premier_Cost_Tax__c != newInvc.Premier_Cost_Tax__c
                        || oldInvc.Plus_Cost_Tax__c != newInvc.Plus_Cost_Tax__c
                        || oldInvc.Basic_Cost_Tax__c != newInvc.Basic_Cost_Tax__c
                        || oldInvc.Total_Cost__c != newInvc.Total_Cost__c
                        || oldInvc.Total_Tax__c != newInvc.Total_Tax__c
                        || oldInvc.En_Route_Mileage__c != newInvc.En_Route_Mileage__c
                        || oldInvc.Tow_Mileage__c != newInvc.Tow_Mileage__c
                        || oldInvc.Other_Cost__c != newInvc.Other_Cost__c
                        || oldInvc.RV_Cost__c != newInvc.RV_Cost__c
                        || oldInvc.Premier_Cost__c != newInvc.Premier_Cost__c
                        || oldInvc.Plus_Cost__c != newInvc.Plus_Cost__c
                        || oldInvc.Basic_Cost__c != newInvc.Basic_Cost__c
                        || oldInvc.Total_Amount__c != newInvc.Total_Amount__c
                        || oldInvc.Number_of_Line_Items__c != newInvc.Number_of_Line_Items__c
                    ) {
                        invcProcessList.add(newInvc);
                        runRollupLogic = true;
                    }
                }
            } else {
                runRollupLogic = true;
            }

            if (runRollupLogic) {
                List<String> programClubs = new List<String>{
                    '050','298','299','311','400','750','798','850','951','997','998','999','785'
                };
                List<String> recList = new List<String>{'Reciprocals', 'Reciprocal Adjustments'};
                List<String> baList = new List<String>{'ERS Calls', 'Call Adjustments'};
                List<Statement__c> stmtsToUpdate = new List<Statement__c>();
                List<Statement__c> stmtList = new List<Statement__c>();
                List<Invoice__c> invcList = new List<Invoice__c>();
                Set<String> stmtIdSet = new Set<String>();
                String orgClub = boSettings.Club_Code__c;
                Boolean isDeletedInvc = oldInvcList != null && newInvcList == null;

                if (invcProcessList.size() > 0) {
                    invcList = invcProcessList;
                } else {
                    invcList = newInvcList != null ? newInvcList : oldInvcList;
                }
    
                for (Invoice__c invc : invcList) {
                    stmtIdSet.add(invc.Statement__c);
                }
    
                if (stmtIdSet.size() > 0) {
                    stmtList = [
                        SELECT
                            Id,
                            Basic_Cost_Tax_Adjustment__c,
                            Basic_Cost_Tax_ERS__c,
                            Basic_Cost_Tax_Reciprocal_Adjustment__c,
                            Basic_Cost_Tax_Reciprocal__c,
                            Other_Cost_Tax_Adjustment__c,
                            Other_Cost_Tax_ERS__c,
                            Other_Cost_Tax_Reciprocal_Adjustment__c,
                            Other_Cost_Tax_Reciprocal__c,
                            Plus_Cost_Tax_Adjustment__c,
                            Plus_Cost_Tax_ERS__c,
                            Plus_Cost_Tax_Reciprocal_Adjustment__c,
                            Plus_Cost_Tax_Reciprocal__c,
                            Premier_Cost_Tax_Adjustment__c,
                            Premier_Cost_Tax_ERS__c,
                            Premier_Cost_Tax_Reciprocal_Adjustment__c,
                            Premier_Cost_Tax_Reciprocal__c,
                            RV_Cost_Tax_Adjustment__c,
                            RV_Cost_Tax_ERS__c,
                            RV_Cost_Tax_Reciprocal_Adjustment__c,
                            RV_Cost_Tax_Reciprocal__c,
                            Club_Station_Contractor_Battery__c,
                            Club_Station_Contractor_Battery_Tax__c,
                            Club_Station_Contractor_Basic__c,
                            Club_Station_Contractor_Plus__c,
                            Club_Station_Contractor_PLRV__c,
                            Club_Station_Contractor_PRM__c,
                            Club_Station_Programs_Basic__c,
                            Club_Station_Programs_Plus__c,
                            Club_Station_Programs_prem__c,
                            Club_Station_RAP__c,
                            Club_Station_Reciprocal__c
                        FROM Statement__c
                        WHERE Id IN :stmtIdSet
                        // FOR UPDATE
                    ];
                    List<Invoice_Line_Item__c> totalILIList = [
                        SELECT
                            Id,
                            Tax__c,
                            Cost__c,
                            Charge_to_Account__c,
                            Invoice__r.Statement__c,
                            Invoice__r.Type__c,
                            Invoice__r.Work_Order__r.Program_Description__c,
                            Invoice__r.Work_Order__r.Call_Type__c,
                            Service_Line_Item__r.Product_Code__c
                        FROM Invoice_Line_Item__c
                        WHERE Invoice__c IN (
                            SELECT Id
                            FROM Invoice__c
                            WHERE Statement__c IN :stmtIdSet
                            AND Status__c != 'Deferred'
                        )
                    ];
                    Map<String, List<Invoice_Line_Item__c>> iliMapList = new Map<String, List<Invoice_Line_Item__c>>();

                    for (Invoice_Line_Item__c ili : totalILIList) {
                        String stmtId = ili.Invoice__r.Statement__c;

                        if (iliMapList.get(stmtId) == null) {
                            iliMapList.put(stmtId, new List<Invoice_Line_Item__c>{ili});
                        } else {
                            List<Invoice_Line_Item__c> tempILIList = iliMapList.get(stmtId);

                            tempILIList.add(ili);
                            iliMapList.put(stmtId, tempILIList);
                        }
                    }
    
                    for (Statement__c stmt : stmtList) {
                        Map<String, Decimal> taxMap = new Map<String, Decimal>();
                        List<Invoice_Line_Item__c> iliList = iliMapList.get(stmt.Id);
                        Decimal premBattCost = 0.0;
                        Decimal premBattTax = 0.0;
                        Decimal cscBasic = 0.0;
                        Decimal cscPlus = 0.0;
                        Decimal cscPRV = 0.0;
                        Decimal cscPrem = 0.0;
                        Decimal cspBasic = 0.0;
                        Decimal cspPlus = 0.0;
                        Decimal cspPrem = 0.0;
                        Decimal csRAP = 0.0;
                        Decimal csRec = 0.0;
        
                        if (iliList?.size() > 0) {
                            for (Invoice_Line_Item__c ili : iliList) {
                                String chargeAcct = ili.Charge_to_Account__c;
                                String invcType = ili.Invoice__r.Type__c;
                                String woClub = ili.Invoice__r.Work_Order__r.Program_Description__c;
                                String woCallType = ili.Invoice__r.Work_Order__r.Call_Type__c;
                                Boolean hasPremBatt = orgClub == '212' 
                                    && ili.Service_Line_Item__r.Product_Code__c == 'BR';
                                Boolean excFromPrem = chargeAcct == 'E' && baList.contains(invcType) 
                                    && hasPremBatt;
                    
                                if (
                                    chargeAcct != null 
                                    && invcType != 'Facility Adjustments'
                                    && !excFromPrem
                                ) {
                                    Decimal iliTax = ili.Tax__c != null ? ili.Tax__c : 0.0;
                                    String taxKey = invcType + chargeAcct;
                    
                                    if (taxMap.get(taxKey) == null) {
                                        taxMap.put(taxKey, 0.0);
                                    }
                    
                                    Decimal currTax = taxMap.get(taxKey);
                    
                                    taxMap.put(taxKey, currTax + iliTax);
                                }
                    
                                if (orgClub == '212') {
                                    Decimal iliCost = ili.Cost__c != null ? ili.Cost__c : 0.0;
                                    Decimal iliTax = ili.Tax__c != null ? ili.Tax__c : 0.0;
                                    // Decimal iliTotal = iliTax + iliCost;
                    
                                    if (excFromPrem) {
                                        // Club Station Contractor Battery
                                        premBattCost += iliCost;
                                        premBattTax += iliTax;
                                    } else if (baList.contains(invcType) && !hasPremBatt) {
                                        // Club Station Contractor B & O / P / R / E (no batt)
                                        if (chargeAcct == 'B' || chargeAcct == 'O') {
                                            cscBasic += iliCost;
                                        }
                    
                                        if (chargeAcct == 'P') {
                                            cscPlus += iliCost;
                                        }
                    
                                        if (chargeAcct == 'R') {
                                            cscPRV += iliCost;
                                        }
                    
                                        if (chargeAcct == 'E') {
                                            cscPrem += iliCost;
                                        }
                                    } else if (recList.contains(invcType) && programClubs.contains(woClub)) {
                                        // Club Station Program
                                        if (chargeAcct == 'B' || chargeAcct == 'O') {
                                            cspBasic += iliCost;
                                        }
                    
                                        if (chargeAcct == 'P' || chargeAcct == 'R') {
                                            cspPlus += iliCost;
                                        }
                    
                                        if (chargeAcct == 'E') {
                                            cspPrem += iliCost;
                                        }
                                    } else if (recList.contains(invcType) && woCallType == 'RAP') {
                                        // Club Station RAP
                                        csRAP += iliCost;
                                    } else if (recList.contains(invcType)) {
                                        // Club Station Reciprocal
                                        csRec += iliCost;
                                    }
                                }
                            }
                    
                            stmt.Basic_Cost_Tax_Adjustment__c = taxMap.get('Call AdjustmentsB');
                            stmt.Basic_Cost_Tax_ERS__c = taxMap.get('ERS CallsB');
                            stmt.Basic_Cost_Tax_Reciprocal_Adjustment__c = taxMap.get('Reciprocal AdjustmentsB');
                            stmt.Basic_Cost_Tax_Reciprocal__c = taxMap.get('ReciprocalsB');
                            stmt.Other_Cost_Tax_Adjustment__c = taxMap.get('Call AdjustmentsO');
                            stmt.Other_Cost_Tax_ERS__c = taxMap.get('ERS CallsO');
                            stmt.Other_Cost_Tax_Reciprocal_Adjustment__c = taxMap.get('Reciprocal AdjustmentsO');
                            stmt.Other_Cost_Tax_Reciprocal__c = taxMap.get('ReciprocalsO');
                            stmt.Plus_Cost_Tax_Adjustment__c = taxMap.get('Call AdjustmentsP');
                            stmt.Plus_Cost_Tax_ERS__c = taxMap.get('ERS CallsP');
                            stmt.Plus_Cost_Tax_Reciprocal_Adjustment__c = taxMap.get('Reciprocal AdjustmentsP');
                            stmt.Plus_Cost_Tax_Reciprocal__c = taxMap.get('ReciprocalsP');
                            stmt.Premier_Cost_Tax_Adjustment__c = taxMap.get('Call AdjustmentsE');
                            stmt.Premier_Cost_Tax_ERS__c = taxMap.get('ERS CallsE');
                            stmt.Premier_Cost_Tax_Reciprocal_Adjustment__c = taxMap.get('Reciprocal AdjustmentsE');
                            stmt.Premier_Cost_Tax_Reciprocal__c = taxMap.get('ReciprocalsE');
                            stmt.RV_Cost_Tax_Adjustment__c = taxMap.get('Call AdjustmentsR');
                            stmt.RV_Cost_Tax_ERS__c = taxMap.get('ERS CallsR');
                            stmt.RV_Cost_Tax_Reciprocal_Adjustment__c = taxMap.get('Reciprocal AdjustmentsR');
                            stmt.RV_Cost_Tax_Reciprocal__c = taxMap.get('ReciprocalsR');
                            stmt.Club_Station_Contractor_Battery__c = premBattCost;
                            stmt.Club_Station_Contractor_Battery_Tax__c = premBattTax;
                            stmt.Club_Station_Contractor_Basic__c = cscBasic;
                            stmt.Club_Station_Contractor_Plus__c = cscPlus;
                            stmt.Club_Station_Contractor_PLRV__c = cscPRV;
                            stmt.Club_Station_Contractor_PRM__c = cscPrem;
                            stmt.Club_Station_Programs_Basic__c = cspBasic;
                            stmt.Club_Station_Programs_Plus__c = cspPlus;
                            stmt.Club_Station_Programs_prem__c = cspPrem;
                            stmt.Club_Station_RAP__c = csRAP;
                            stmt.Club_Station_Reciprocal__c = csRec;
    
                            stmtsToUpdate.add(stmt);
                        }
                    }
                }
    
                if (stmtsToUpdate.size() > 0) {
                    update stmtsToUpdate;
                }
            }
        }
    }

    public static void updateFAPStatus(
        List<Invoice__c> oldInvcList, List<Invoice__c> newInvcList,
        Map<Id, Invoice__c> oldMap, Map<Id, Invoice__c> newMap
    ) {
        try {
            if (permSetList == null || permSetList.size() == 0) {
                List<Invoice__c> invcProcessList = new List<Invoice__c>();
    
                if (
                    oldInvcList != null 
                    && newInvcList != null 
                    && oldInvcList.size() > 0
                    && oldInvcList.size() == newInvcList.size()
                ) {
                    for (Invoice__c oldInvc : oldInvcList) {
                        Invoice__c newInvc = newMap.get(oldInvc.Id);
    
                        if (oldInvc.Status__c != newInvc.Status__c) {
                            invcProcessList.add(newInvc);
                        }
                    }
                }
    
                if (invcProcessList.size() > 0) {
                    Set<String> invcIdSet = new Set<String>();
                    Set<String> fapIdSet = new Set<String>();
    
                    for (Invoice__c invc : invcProcessList) {
                        invcIdSet.add(invc.Id);
                    }
    
                    if (invcProcessList.size() < 100) {
                        List<ACG_Facility_Adjustment_Payment__c> fapUpdateList = new List<ACG_Facility_Adjustment_Payment__c>();
                        List<Invoice_Line_Item__c> iliList = [
                            SELECT 
                                Id, 
                                Invoice__c, 
                                Facility_Adjustment_Payment__r.ACG_Status__c
                            FROM Invoice_Line_Item__c
                            WHERE Invoice__c IN :invcIdSet
                            AND Facility_Adjustment_Payment__c != null
                        ];
    
                        for (Invoice_Line_Item__c ili : iliList) {
                            String invcId = ili.Invoice__c;
                            Invoice__c invc = newMap.get(invcId);
                            ACG_Facility_Adjustment_Payment__c fap = ili.Facility_Adjustment_Payment__r;
    
                            if (!fapIdSet.contains(fap.Id)) {
                                fap.ACG_Status__c = invc.Status__c;
                                
                                fapUpdateList.add(fap);
                                fapIdSet.add(fap.Id);
                            }
                        }
    
                        if (fapUpdateList.size() > 0) {
                            update fapUpdateList;
                        }
                    } else {
                        List<AsyncApexJob> batchJobList = [
                            SELECT Id 
                            FROM AsyncApexJob 
                            WHERE ApexClass.Name IN (
                                'AAAInvoiceReadyForPaymentBatch', 
                                'AAABatchInvoiceUpdateHelper',
                                'UATBatchUpdateInvoices'
                            )
                            AND Status NOT IN ('Aborted', 'Completed', 'Failed')
                        ];

                        if (batchJobList.isEmpty()) {
                            Database.executeBatch(
                                new AAAUpdateFAPWithInvoiceStatusBatch(new List<String>(invcIdSet)), 1000
                            );
                        }
                    }
                }
            }
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();
        
            insert new FSL_Application_Log__c(
                Operation__c = 'FSL_InvoiceTriggerHandler',
                Error_Message__c = errMsg
            );

            throw e;
        }
    }
}