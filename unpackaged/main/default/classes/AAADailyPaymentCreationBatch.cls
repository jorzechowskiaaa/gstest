/**
 * @description       : Creates Payment records from Statements and Invoices. Will create a Facility Adjustment if the Statement is reconciled with a negative total amount.
 * @author            : soham.saha@salesforce.com
 * @group             : 
 * @last modified on  : 05-29-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-14-2024   soham.saha@salesforce.com
 *       05-24-2024   joshtupas@salesforce.com             Modified query to accomodate "Eligible_for_Payment__c" flag for NE club while maintaining original logic for ACA club
 *       05-28-2024   joshtupas@salesforce.com             Removed ACA vs NE logic to enable "Eligible_for_Payment__c" for ACA club. Refactored query to use SOQL instead of query string. Changed Invoice update logic to query via Statement start and end dates instead of a list of Invoice Ids.
 *       05-29-2024   joshtupas@salesforce.com             Lowered batch size from 50 to 10. Included additional query condition for Spend Category metadata.
**/
public class AAADailyPaymentCreationBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    public String query;
    private Date stmtStartDate;
    private Date stmtEndDate;
    private Integer dmlRows;
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
    private List<String> processedStmtList;
    private List<String> remainingStmtList;
    private List<Statement__c> totalStmtUpdateList;
    private List<Payment__c> totalPmtInsertList;
    private List<ACG_Facility_Adjustment__c> totalFAInsertList;
    private Set<String> exceptionMsgSet;

    public AAADailyPaymentCreationBatch() {
        resetGlobalVars();
    }

    public AAADailyPaymentCreationBatch(Map<String, Object> inputListMap) {
        resetGlobalVars();
        
        try {
            Date stmtStartDate = (Date) inputListMap.get('stmtStartDate');
            Date stmtEndDate = (Date) inputListMap.get('stmtEndDate');
            List<String> processedStmtList = (List<String>) inputListMap.get('processedStmtList');
            List<Statement__c> totalStmtUpdateList = (List<Statement__c>) inputListMap.get('totalStmtUpdateList');
            List<Payment__c> totalPmtInsertList = (List<Payment__c>) inputListMap.get('totalPmtInsertList');
            List<ACG_Facility_Adjustment__c> totalFAInsertList = (List<ACG_Facility_Adjustment__c>) inputListMap.get('totalFAInsertList');
            Set<String> exceptionMsgSet = (Set<String>) inputListMap.get('exceptionMsgSet');
    
            if (stmtStartDate != null) {
                this.stmtStartDate = stmtStartDate;
            }

            if (stmtEndDate != null) {
                this.stmtEndDate = stmtEndDate;
            }

            if (processedStmtList != null && processedStmtList.size() > 0) {
                this.processedStmtList = processedStmtList;
            }
    
            if (totalStmtUpdateList != null && totalStmtUpdateList.size() > 0) {
                this.totalStmtUpdateList = totalStmtUpdateList;
            }
    
            if (totalPmtInsertList != null && totalPmtInsertList.size() > 0) {
                this.totalPmtInsertList = totalPmtInsertList;
            }

            if (totalFAInsertList != null && totalFAInsertList.size() > 0) {
                this.totalFAInsertList = totalFAInsertList;
            }
        
            if (exceptionMsgSet != null && exceptionMsgSet.size() > 0) {
                this.exceptionMsgSet = exceptionMsgSet;
            }

            if (Test.isRunningTest() && boSettings.Club_Code__c == '240') {
                this.remainingStmtList = (List<String>) inputListMap.get('testStatementIdList');
            }
        } catch (Exception e) {
            processExceptionMsg(e);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (processedStmtList != null && processedStmtList.size() > 0) {
            return Database.getQueryLocator(
                [
                    SELECT 
                        Id, 
                        Basic_Cost__c, 
                        Basic_Cost_Tax_ERS__c, 
                        Basic_Cost_Adjustment__c, 
                        Basic_Cost_Tax_Adjustment__c, 
                        Basic_Cost_Reciprocal__c, 
                        Basic_Cost_Tax_Reciprocal__c, 
                        Basic_Cost_Reciprocal_Adjustment__c, 
                        Basic_Cost_Tax_Reciprocal_Adjustment__c, 
                        Other_Cost_Adjustment__c, 
                        Other_Cost_Tax_Adjustment__c, 
                        Other_Cost_ERS__c, 
                        Other_Cost_Tax_ERS__c, 
                        Other_Cost_Reciprocal__c, 
                        Other_Cost_Tax_Reciprocal__c, 
                        Other_Cost_Reciprocal_Adjustment__c, 
                        Other_Cost_Tax_Reciprocal_Adjustment__c, 
                        Plus_Cost__c, 
                        Plus_Cost_Tax_ERS__c, 
                        Plus_Cost_Adjustment__c, 
                        Plus_Cost_Tax_Adjustment__c, 
                        Plus_Cost_Reciprocal__c, 
                        Plus_Cost_Tax_Reciprocal__c, 
                        Plus_Cost_Reciprocal_Adjustment__c, 
                        Plus_Cost_Tax_Reciprocal_Adjustment__c, 
                        Premier_Cost__c, 
                        Premier_Cost_Tax_ERS__c, 
                        Premier_Cost_Adjustment__c, 
                        Premier_Cost_Tax_Adjustment__c, 
                        Premier_Cost_Reciprocal__c, 
                        Premier_Cost_Tax_Reciprocal__c, 
                        Premier_Cost_Reciprocal_Adjustment__c, 
                        Premier_Cost_Tax_Reciprocal_Adjustment__c, 
                        RV_Cost__c, 
                        RV_Cost_Tax_ERS__c, 
                        RV_Cost_Adjustment__c, 
                        RV_Cost_Tax_Adjustment__c, 
                        RV_Cost_Reciprocal__c, 
                        RV_Cost_Tax_Reciprocal__c, 
                        RV_Cost_Reciprocal_Adjustment__c, 
                        RV_Cost_Tax_Reciprocal_Adjustment__c, 
                        Club_Station_Contractor_Battery__c, 
                        Club_Station_Contractor_Basic__c, 
                        Club_Station_Contractor_Plus__c, 
                        Club_Station_Contractor_PLRV__c, 
                        Club_Station_Contractor_PRM__c, 
                        Club_Station_Programs_Basic__c, 
                        Club_Station_Programs_Plus__c, 
                        Club_Station_Programs_prem__c, 
                        Club_Station_RAP__c, 
                        Club_Station_Reciprocal__c, 
                        Status__c, 
                        Start_Date__c, 
                        End_Date__c, 
                        Name, 
                        Processed__c, 
                        Total_Cost__c, 
                        Service_Territory__c,
                        Service_Territory__r.Payment_Schedule__c,
                        Service_Territory__r.Facility_Number__c, 
                        Service_Territory__r.Name, 
                        Service_Territory__r.Street, 
                        Service_Territory__r.City, 
                        Service_Territory__r.State, 
                        Service_Territory__r.PostalCode, 
                        Service_Territory__r.DBA_Name__c, 
                        Service_Territory__r.DBA_Address_Line_1__c, 
                        Service_Territory__r.DBA_City__c, 
                        Service_Territory__r.DBA_State__c, 
                        Service_Territory__r.DBA_Zip_Code__c
                    FROM Statement__c
                    WHERE Service_Territory__r.Non_Payment_Facility__c = false
                    AND Status__c = 'Reconciled'
                    AND Processed__c = false
                    AND Service_Territory__r.Eligible_for_Payment__c = true
                    AND Id NOT IN :processedStmtList
                ]
            );
        }

        return Database.getQueryLocator(
            [
                SELECT 
                    Id, 
                    Basic_Cost__c, 
                    Basic_Cost_Tax_ERS__c, 
                    Basic_Cost_Adjustment__c, 
                    Basic_Cost_Tax_Adjustment__c, 
                    Basic_Cost_Reciprocal__c, 
                    Basic_Cost_Tax_Reciprocal__c, 
                    Basic_Cost_Reciprocal_Adjustment__c, 
                    Basic_Cost_Tax_Reciprocal_Adjustment__c, 
                    Other_Cost_Adjustment__c, 
                    Other_Cost_Tax_Adjustment__c, 
                    Other_Cost_ERS__c, 
                    Other_Cost_Tax_ERS__c, 
                    Other_Cost_Reciprocal__c, 
                    Other_Cost_Tax_Reciprocal__c, 
                    Other_Cost_Reciprocal_Adjustment__c, 
                    Other_Cost_Tax_Reciprocal_Adjustment__c, 
                    Plus_Cost__c, 
                    Plus_Cost_Tax_ERS__c, 
                    Plus_Cost_Adjustment__c, 
                    Plus_Cost_Tax_Adjustment__c, 
                    Plus_Cost_Reciprocal__c, 
                    Plus_Cost_Tax_Reciprocal__c, 
                    Plus_Cost_Reciprocal_Adjustment__c, 
                    Plus_Cost_Tax_Reciprocal_Adjustment__c, 
                    Premier_Cost__c, 
                    Premier_Cost_Tax_ERS__c, 
                    Premier_Cost_Adjustment__c, 
                    Premier_Cost_Tax_Adjustment__c, 
                    Premier_Cost_Reciprocal__c, 
                    Premier_Cost_Tax_Reciprocal__c, 
                    Premier_Cost_Reciprocal_Adjustment__c, 
                    Premier_Cost_Tax_Reciprocal_Adjustment__c, 
                    RV_Cost__c, 
                    RV_Cost_Tax_ERS__c, 
                    RV_Cost_Adjustment__c, 
                    RV_Cost_Tax_Adjustment__c, 
                    RV_Cost_Reciprocal__c, 
                    RV_Cost_Tax_Reciprocal__c, 
                    RV_Cost_Reciprocal_Adjustment__c, 
                    RV_Cost_Tax_Reciprocal_Adjustment__c, 
                    Club_Station_Contractor_Battery__c, 
                    Club_Station_Contractor_Basic__c, 
                    Club_Station_Contractor_Plus__c, 
                    Club_Station_Contractor_PLRV__c, 
                    Club_Station_Contractor_PRM__c, 
                    Club_Station_Programs_Basic__c, 
                    Club_Station_Programs_Plus__c, 
                    Club_Station_Programs_prem__c, 
                    Club_Station_RAP__c, 
                    Club_Station_Reciprocal__c, 
                    Status__c, 
                    Start_Date__c, 
                    End_Date__c, 
                    Name, 
                    Processed__c, 
                    Total_Cost__c, 
                    Service_Territory__c, 
                    Service_Territory__r.Payment_Schedule__c,
                    Service_Territory__r.Facility_Number__c, 
                    Service_Territory__r.Name, 
                    Service_Territory__r.Street, 
                    Service_Territory__r.City, 
                    Service_Territory__r.State, 
                    Service_Territory__r.PostalCode, 
                    Service_Territory__r.DBA_Name__c, 
                    Service_Territory__r.DBA_Address_Line_1__c, 
                    Service_Territory__r.DBA_City__c, 
                    Service_Territory__r.DBA_State__c, 
                    Service_Territory__r.DBA_Zip_Code__c
                FROM Statement__c
                WHERE Service_Territory__r.Non_Payment_Facility__c = false
                AND Status__c = 'Reconciled'
                AND Processed__c = false
                AND Service_Territory__r.Eligible_for_Payment__c = true
            ]
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Statement__c> scope) {
        try {
            String clubCode = boSettings.Club_Code__c;
            Map<String, List<Invoice__c>> invcMapList = new Map<String, List<Invoice__c>>();
            Map<String, Statement__c> stmtMap = new Map<String, Statement__c>();
            Map<String, Integer> stmtInvcNumMap = new Map<String, Integer>();
            List<String> stmtIdList = new List<String>();
            List<String> stmtProcessList = new List<String>();
            List<Statement__c> statementUpdateList = new List<Statement__c>();
            List<Invoice__c> totalInvoiceList = new List<Invoice__c>();
            List<Payment__c> paymentInsertList = new List<Payment__c>();
            List<ACG_Facility_Adjustment__c> facAdjInsertList = new List<ACG_Facility_Adjustment__c>();
            List<Statement_Field_Spend_Category_Mappings__mdt> fieldSCMdtList = new List<Statement_Field_Spend_Category_Mappings__mdt>();
            List<Spend_Category__mdt> scMdtList = [
                SELECT Id, Label, Spend_Category__c 
                FROM Spend_Category__mdt 
                WHERE Club_Code__c = :clubCode
                AND (
                    NOT DeveloperName LIKE '%_Reimbursement'
                )
            ];
    
            for (Statement__c stmt : scope) {
                stmtIdList.add(stmt.Id);
                stmtMap.put(stmt.Id, stmt);
            }

            if (clubCode == 'OOT') {
                totalInvoiceList = AAADailyPaymentCreationBatchTest.mockInvcList();
            } else {
                totalInvoiceList = [
                    SELECT
                        Id,
                        Type__c,
                        Status__c,
                        Total_Amount__c,
                        Facility_Adjustment__c,
                        Facility_Adjustment_Type__c,
                        Facility_Adjustment_Category__c,
                        Statement__c
                    FROM Invoice__c
                    WHERE Status__c = 'Ready for Payment'
                    AND Statement__c IN :stmtIdList
                ];
            }
    
            // build invoice map list so invoices are grouped by statement
            for (Invoice__c invc : totalInvoiceList) {
                String stmtId = invc.Statement__c;
    
                if (invcMapList.get(stmtId) == null) {
                    invcMapList.put(stmtId, new List<Invoice__c>{invc});
                    stmtInvcNumMap.put(stmtId, 1);
                } else {
                    List<Invoice__c> tempList = invcMapList.get(stmtId);
                    Integer invcCount = stmtInvcNumMap.get(stmtId);
    
                    tempList.add(invc);
                    invcMapList.put(stmtId, tempList);
                    stmtInvcNumMap.put(stmtId, invcCount + 1);
                }
            }
    
            // sort and save remaining statements for later
            if (totalInvoiceList.size() > 10000 || clubCode == 'OOT') {
                Integer totalUpdateSize = 0;
                List<List<Object>> stmtInvcNumList = new List<List<Object>>();
    
                for (String key : stmtInvcNumMap.keySet()) {
                    stmtInvcNumList.add(new List<Object>{key, stmtInvcNumMap.get(key)});
                }
    
                quickSort(stmtInvcNumList, 0, stmtInvcNumList.size() - 1);

                for (Integer i = stmtInvcNumList.size() - 1; i >= 0; i--) {
                    List<Object> container = stmtInvcNumList[i];
                    String stmtId = (String) container[0];
                    Integer invcCount = (Integer) container[1];
    
                    if ((totalUpdateSize + invcCount) < 10000) {
                        stmtProcessList.add(stmtId);
                        totalUpdateSize += invcCount;
                    } else {
                        remainingStmtList.add(stmtId);
                    }
                }
            } else {
                stmtProcessList = stmtIdList;
            }
    
            if (Test.isRunningTest()) {
                fieldSCMdtList = AAADailyPaymentCreationBatchTest.mockFieldSCMdtNE();
            } else {
                fieldSCMdtList = [
                    SELECT Id, Label, Label__c, Spend_Category_Label__c 
                    FROM Statement_Field_Spend_Category_Mappings__mdt 
                    WHERE Club_Code__c = :clubCode
                ];
            }

            for (String stmtId : stmtProcessList) { 
                Statement__c statement = stmtMap.get(stmtId);
                ServiceTerritory fac = statement.Service_Territory__r;
                List<Invoice__c> invoiceList = invcMapList.get(stmtId);
                AAAPaymentFlowHelper.FlowInput flowInput = new AAAPaymentFlowHelper.FlowInput();
                AAAPaymentFlowHelper.FlowOutput flowOutput = new AAAPaymentFlowHelper.FlowOutput();

                flowInput.stmt = statement;
                flowInput.fac = fac;
                flowInput.boSettings = boSettings;
                flowInput.scMdtList = scMdtList;
                flowInput.fieldSCMdtList = fieldSCMdtList;
                flowInput.invcList = invoiceList;

                List<AAAPaymentFlowHelper.FlowOutput> flowOutputList = AAAPaymentFlowHelper.runPaymentFlowHelper(new List<AAAPaymentFlowHelper.FlowInput>{flowInput});

                flowOutput = flowOutputList[0];

                if (flowOutput.pmtList != null) {
                    paymentInsertList.addAll(flowOutput.pmtList);
                }
                if (flowOutput.stmt != null) {
                    statementUpdateList.add(flowOutput.stmt);
                }
                if (processedStmtList == null) {
                    processedStmtList = new List<String>{statement.Id};
                } else {
                    processedStmtList.add(statement.Id);
                }
                if (statement.Total_Cost__c < 0) {
                    String pmtSchedule = statement.Service_Territory__r.Payment_Schedule__c;
                    Date faStartDate = statement.End_Date__c;

                    if (faStartDate == null) {
                        faStartDate = Date.today();
                    }

                    Integer year = faStartDate.year();
                    Integer month = faStartDate.month();

                    faStartDate = Date.newInstance(year, month + 1, 1);

                    if (pmtSchedule == 'Bi-monthly' || pmtSchedule == null) {
                        if (faStartDate.day() < 16) { 
                            faStartDate = Date.newInstance(year, month, 16);
                        }
                    }

                    facAdjInsertList.add(
                        new ACG_Facility_Adjustment__c(
                            Service_Territory__c = statement.Service_Territory__c,
                            ACG_Description__c = 'THE FACILITY DID NOT EARN ENOUGH TO PAY FOR CURRENT ADJUSTMENTS',
                            ACG_Adjustment_Type__c = 'Debit',
                            ACG_Charge_1099__c = false,
                            ACG_Status__c = 'Active',
                            ACG_Adjustment_Category__c = clubCode == '212' ? 'OVER DRAWN' : 'Overdrawn',
                            ACG_Payment_Amount__c = Math.abs(statement.Total_Cost__c),
                            ACG_Start_Date__c = faStartDate,
                            ACG_Nature_of_Payments__c = 'Fixed',
                            ACG_No_of_Payments__c = 1
                        )
                    );
                }
                if (stmtStartDate == null || statement.Start_Date__c < stmtStartDate) {
                    stmtStartDate = statement.Start_Date__c;
                }
                if (stmtEndDate == null || statement.End_Date__c > stmtEndDate) {
                    stmtEndDate = statement.End_Date__c;
                }
            }

            if (statementUpdateList.size() > 0) {
                if (totalStmtUpdateList == null) {
                    totalStmtUpdateList = statementUpdateList;
                } else {
                    totalStmtUpdateList.addAll(statementUpdateList);
                }
            }
            
            if (paymentInsertList.size() > 0) {
                if (totalPmtInsertList == null) {
                    totalPmtInsertList = paymentInsertList;
                } else {
                    totalPmtInsertList.addAll(paymentInsertList);
                }
            }

            if (facAdjInsertList.size() > 0) {
                if (totalFAInsertList == null) {
                    totalFAInsertList = facAdjInsertList;
                } else {
                    totalFAInsertList.addAll(facAdjInsertList);
                }
            }

            processDMLRows();

            dmlRows = 0;
        } catch (Exception e) {
            processExceptionMsg(e);
        }
    }

    public void quickSort(List<List<Object>> sortList, Integer startNum, Integer endNum) {
        if (startNum < endNum) {
            Integer mid = partition(sortList, startNum, endNum);

            quickSort(sortList, startNum, mid - 1);
            quickSort(sortList, mid + 1, endNum);
        }
    }

    private Integer partition(List<List<Object>> sortList, Integer startNum, Integer endNum) {
        List<Object> startContainer = sortList[endNum];
        Integer pivot = (Integer) startContainer[1];
        Integer i = startNum - 1;

        for (Integer j = startNum; j < endNum; j++) {
            List<Object> container = sortList[j];
            Integer invcCount = (Integer) container[1];

            if (invcCount <= pivot) {
                i++;

                List<Object> tempContainer1 = sortList[i];

                sortList[i] = sortList[j];
                sortList[j] = tempContainer1;
            }
        }

        List<Object> tempContainer2 = sortList[i + 1];

        sortList[i + 1] = sortList[endNum];
        sortList[endNum] = tempContainer2;

        return i + 1;
    }

    private void processDMLRows() {
        Integer stmtSize = totalStmtUpdateList != null ? totalStmtUpdateList.size() : 0;
        Integer pmtSize = totalPmtInsertList != null ? totalPmtInsertList.size() : 0;
        Integer faSize = totalFAInsertList != null ? totalFAInsertList.size() : 0;
        List<Statement__c> stmtUpdateList = new List<Statement__c>();
        List<Invoice__c> invcUpdateList = new List<Invoice__c>();
        List<Payment__c> pmtInsertList = new List<Payment__c>();
        List<ACG_Facility_Adjustment__c> faInsertList = new List<ACG_Facility_Adjustment__c>();

        if (faSize > 0) {
            if ((dmlRows + faSize) < 10000) {
                insert totalFAInsertList;

                dmlRows += faSize;
                totalFAInsertList = null;
            } else {
                List<ACG_Facility_Adjustment__c> tempFAList = new List<ACG_Facility_Adjustment__c>();

                for (ACG_Facility_Adjustment__c fa : totalFAInsertList) {
                    if ((dmlRows + 1) < 10000) {
                        faInsertList.add(fa);
                        dmlRows++;
                    } else {
                        tempFAList.add(fa);
                    }
                }

                update faInsertList;

                totalFAInsertList = tempFAList;
            }
        }

        if (stmtSize > 0) {
            if ((dmlRows + stmtSize) < 10000) {
                update totalStmtUpdateList;
                
                dmlRows += stmtSize;
                totalStmtUpdateList = null;
            } else {
                List<Statement__c> tempStmtList = new List<Statement__c>();
    
                for (Statement__c stmt : totalStmtUpdateList) {
                    if ((dmlRows + 1) < 10000) {
                        stmtUpdateList.add(stmt);
                        dmlRows++;
                    } else {
                        tempStmtList.add(stmt);
                    }
                }
    
                update stmtUpdateList;
    
                totalStmtUpdateList = tempStmtList;
            }
        }
    
        if (pmtSize > 0) {
            if ((dmlRows + pmtSize) < 10000) {
                insert totalPmtInsertList;
    
                dmlRows += pmtSize;
                totalPmtInsertList = null;
            } else if (dmlRows < 10000) {
                List<Payment__c> tempPmtList = new List<Payment__c>();
    
                for (Payment__c pmt : totalPmtInsertList) {
                    if ((dmlRows + 1) < 10000) {
                        pmtInsertList.add(pmt);
                        dmlRows++;
                    } else {
                        tempPmtList.add(pmt);
                    }
                }
    
                insert pmtInsertList;
    
                totalPmtInsertList = tempPmtList;
            }
        }
    }

    private void resetGlobalVars() {
        dmlRows = 0;
        stmtStartDate = null;
        stmtEndDate = null;
        remainingStmtList = new List<String>();
        processedStmtList = new List<String>();
        totalStmtUpdateList = new List<Statement__c>();
        totalPmtInsertList = new List<Payment__c>();
        totalFAInsertList = new List<ACG_Facility_Adjustment__c>();
        exceptionMsgSet = new Set<String>();
    }

    private void processExceptionMsg(Exception e) {
        String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();
        
        insert new FSL_Application_Log__c(
            Operation__c = 'AAADailyPaymentCreationBatch',
            Error_Message__c = errMsg
        );
    }
    
    public void finish(Database.BatchableContext bc) {
        try {
            if (remainingStmtList.size() > 0) {
                Database.executeBatch(new AAADailyPaymentCreationBatch(
                    new Map<String, Object>{
                        'stmtStartDate' => stmtStartDate,
                        'stmtEndDate' => stmtEndDate,
                        'processedStmtList' => processedStmtList, 
                        'totalStmtUpdateList' => totalStmtUpdateList, 
                        'totalPmtInsertList' => totalPmtInsertList,
                        'totalFAInsertList' => totalFAInsertList,
                        'exceptionMsgSet' => exceptionMsgSet
                    }
                ), 50);
            } else {
                if (stmtStartDate != null && stmtEndDate != null) {
                    String startDate = String.valueOf(stmtStartDate);
                    String endDate = String.valueOf(stmtEndDate);
                    String newStatus = 'Submitted for Payment';
                    String query = 
                        'SELECT ' +
                            'Id, Status__c, Type__c' +
                        ' FROM Invoice__c' +
                        ' WHERE Statement__r.Start_Date__c >= ' + startDate +
                        ' AND Statement__r.Start_Date__c <= ' + endDate +
                        ' AND Statement__r.Status__c = \'Reconciled\'' + 
                        ' AND Status__c = \'Ready for Payment\'' +
                        ' ORDER BY Statement__c';

                    Database.executeBatch(new AAABatchInvoiceUpdateHelper(
                        query, newStatus
                    ), 1000);
                }
    
                System.debug('Batch Job Completed');
            }
        } catch (Exception e) {
            processExceptionMsg(e);
        }
    }

    public void execute(SchedulableContext ctx) {
        AAADailyPaymentCreationBatch batch = new AAADailyPaymentCreationBatch();

        Database.executeBatch(batch, 10);
    }
}