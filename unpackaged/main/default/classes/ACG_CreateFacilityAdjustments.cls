/**
 * @description       : Creates Payment records from Allocations and Reimbursements
 * @author            : ksarathy@salesforce.com
 * @group             : 
 * @last modified on  : 06-10-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-25-2024   ksarathy@salesforce.com
 *       05-29-2024   joshtupas@salesforce.com             See https://salesforce.atlassian.net/browse/PR893288-5081
 *       06-10-2024   joshtupas@salesforce.com             Changed query for Statements to query ALL Statements regardless of status. Added logic to consider already reconciled Statements to prevent creating duplicate Statements by keeping track of dates already parsed through.
**/
public class ACG_CreateFacilityAdjustments {
    private static String faDevName = 'Facility_Adjustment';
    private static Id invoiceRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get(faDevName).getRecordTypeId();
    private static Id invoiceLIRecId = Schema.SObjectType.Invoice_Line_Item__c.getRecordTypeInfosByDeveloperName().get(faDevName).getRecordTypeId();

    public static void processFacilityAdjustments(List<ACG_Facility_Adjustment__c> lstFacAdj) {
        try {
            List<Invoice_Line_Item__c> lstNewInvLI = new List<Invoice_Line_Item__c>();
            Map<String, Object> resMap = createFAPInvoices(lstFacAdj);
            List<ACG_Facility_Adjustment_Payment__c> lstNewFacAdjPay = (List<ACG_Facility_Adjustment_Payment__c>) resMap.get('lstNewFacAdjPay');
            List<Invoice__c> lstNewInvoice = (List<Invoice__c>) resMap.get('lstNewInvoice');
    
            if (lstNewFacAdjPay != null && !lstNewFacAdjPay.isEmpty()) {
                insert lstNewFacAdjPay;
            }
            
            if (lstNewInvoice != null && !lstNewInvoice.isEmpty()) {
                insert lstNewInvoice;
    
                createInvoiceLineItems(lstNewInvLI, lstNewInvoice, lstNewFacAdjPay);
            }
            
            if (!lstNewInvLI.isEmpty()) {
                insert lstNewInvLI;
            }
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

            insert new FSL_Application_Log__c(
                Operation__c = 'ACG_CreateFacilityAdjustments.processFacilityAdjustments()',
                Error_Message__c = errMsg
            );

            throw e;
        }
    }

    private static void createInvoiceLineItems(List<Invoice_Line_Item__c> lstNewInvLI, List<Invoice__c> lstNewInvoice, List<ACG_Facility_Adjustment_Payment__c> lstNewFacAdjPay) {
        Map<String, ACG_Facility_Adjustment_Payment__c> mapFacAdjToFacAdjPay = new Map<String, ACG_Facility_Adjustment_Payment__c>();
        List<ACG_Facility_Adjustment_Payment__c> newLstNewFacAdjPay = new List<ACG_Facility_Adjustment_Payment__c>();

        for (ACG_Facility_Adjustment_Payment__c facAdjPay : lstNewFacAdjPay) {
            String key = '' + facAdjPay.Statement__c + facAdjPay.ACG_Adjustment_ID__c;

            mapFacAdjToFacAdjPay.put(key, facAdjPay);
        }
        
        for (Invoice__c inv : lstNewInvoice) {
            String key = '' + inv.Statement__c + inv.Facility_Adjustment__c;
            ACG_Facility_Adjustment_Payment__c facAdjPay = mapFacAdjToFacAdjPay.get(key);

            if (facAdjPay != null) {
                lstNewInvLI.add(
                    new Invoice_Line_Item__c(
                        Invoice__c = inv.Id,
                        Facility_Adjustment_Payment__c = facAdjPay.Id,
                        Cost__c = facAdjPay.ACG_Payment_Amount__c,
                        RecordTypeId = invoiceLIRecId
                    )
                );
            }
        }
    }

    private static Map<String, Object> createFAPInvoices(List<ACG_Facility_Adjustment__c> lstFacAdj) {
        String readyForProcessing = 'Ready for Processing';
        String facAdjType = 'Facility Adjustments';
        String facAdjKey = 'facAdj';
        String numPmtsKey = 'numPmtsToCreate';
        String newFAPKey = 'newFAP';
        String newInvcKey = 'newInvc';
        String unreconciled = 'Unreconciled';
        String reconciled = 'Reconciled';
        String bimonthly = 'Bi-monthly';
        Date earliestDate = Date.today();
        Set<String> servTerrIds = new Set<String>();
        List<ACG_Facility_Adjustment_Payment__c> lstNewFacAdjPay = new List<ACG_Facility_Adjustment_Payment__c>();
        List<Invoice__c> lstNewInvoice = new List<Invoice__c>();
        List<Statement__c> stmtInsertList = new List<Statement__c>();
        List<String> stmtIdList = new List<String>();
        List<String> faIdList = new List<String>();
        Map<String, List<Statement__c>> queryStmtMap = new Map<String, List<Statement__c>>();
        Map<String, ServiceTerritory> facMap = new Map<String, ServiceTerritory>();
        Map<String, Object> newStmtMap = new Map<String, Object>();
        Map<String, Set<Date>> totalExistingStartDates = new Map<String, Set<Date>>();

        for (ACG_Facility_Adjustment__c facAdj : lstFacAdj) {
            String facId = facAdj.Service_Territory__c;
            Date faStartDate = facAdj.Reactivation_Date__c != null ? 
                facAdj.Reactivation_Date__c : facAdj.ACG_Start_Date__c;
            
            if (earliestDate > faStartDate) {
                earliestDate = faStartDate;
            }

            servTerrIds.add(facId);
            faIdList.add(facAdj.Id);
        }
        
        List<Statement__c> allStatements = [
            SELECT 
                Id, 
                Name, 
                Status__c,
                Start_Date__c, 
                End_Date__c, 
                Service_Territory__c
            FROM Statement__c 
            WHERE Service_Territory__c IN :servTerrIds
            AND Start_Date__c >= :earliestDate
            ORDER BY Start_Date__c ASC
        ];

        List<ServiceTerritory> facList = [
            SELECT Id, Payment_Schedule__c, Group__c, Name
            FROM ServiceTerritory
            WHERE Id IN :servTerrIds
        ];

        for (Statement__c stmt : allStatements) {
            String facId = stmt.Service_Territory__c;

            if (queryStmtMap.get(facId) == null) {
                queryStmtMap.put(facId, new List<Statement__c>{stmt});
            } else {
                List<Statement__c> tempList = queryStmtMap.get(facId);

                tempList.add(stmt);
                queryStmtMap.put(facId, tempList);
            }

            stmtIdList.add(stmt.Id);
        }

        List<Invoice__c> existingInvcList = [
            SELECT 
                Id, 
                Facility_Adjustment__c, 
                Service_Territory__c,
                Statement__c,
                Statement__r.Start_Date__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c IN :faIdList
        ];

        for (ServiceTerritory fac : facList) {
            String facId = fac.Id;

            if (facMap.get(facId) == null) {
                facMap.put(facId, fac);
            }
        }
        
        for (Invoice__c invc : existingInvcList) {
            String faId = invc.Facility_Adjustment__c;
            Date stmtDate = invc.Statement__r.Start_Date__c;
            
            if (totalExistingStartDates.get(faId) == null) {
                totalExistingStartDates.put(faId, new Set<Date>{stmtDate});
            } else {
                totalExistingStartDates.get(faId).add(stmtDate);
            }
        }

        for (ACG_Facility_Adjustment__c facAdj : lstFacAdj) {
            Date faStartDate = facAdj.Reactivation_Date__c != null ?
                facAdj.Reactivation_Date__c : facAdj.ACG_Start_Date__c;
            Date nextDate = faStartDate;
            String facId = facAdj.Service_Territory__c;
            String facAdjId = facAdj.Id;
            ServiceTerritory fac = facMap.get(facId);
            String facPmtSchedule = fac.Payment_Schedule__c;
            Decimal numPmts = facAdj.ACG_No_of_Payments__c != null ? 
                facAdj.ACG_No_of_Payments__c : 0;
            Decimal remainingPmts = facAdj.ACG_Adjustments_Remaining__c != null ? 
                facAdj.ACG_Adjustments_Remaining__c : 0;
            Decimal numPmtsToCreate = remainingPmts != 0 ? remainingPmts : numPmts;
            List<Statement__c> stmtList = queryStmtMap.get(facId);
            Set<Date> existingStartDates = new Set<Date>();

            if (totalExistingStartDates.get(facAdjId) != null) {
                existingStartDates.addAll(totalExistingStartDates.get(facAdjId));
            }

            if (stmtList != null) {
                for (Statement__c stmt : stmtList) {
                    Date stmtStartDate = stmt.Start_Date__c;
                    Boolean hasInvc = existingStartDates?.contains(stmtStartDate);
                    
                    if (numPmtsToCreate > 0 && hasInvc != true) {
                        if (
                            stmtStartDate > faStartDate 
                            && stmt.Status__c == unreconciled
                        ) {
                            while (nextDate < stmtStartDate && numPmtsToCreate > 0) {
                                Boolean hasNextDate = existingStartDates?.contains(nextDate);
                                Date stmtEndDate = Date.newInstance(nextDate.year(), nextDate.month() + 1, 1);
                                stmtEndDate = stmtEndDate.addDays(-1);
                                
                                if (
                                    nextDate.day() == 1
                                    && (facPmtSchedule == bimonthly || facPmtSchedule == null)
                                ) {                                
                                    stmtEndDate = Date.newInstance(nextDate.year(), nextDate.month(), 15);
                                }

                                if (hasNextDate != true) {
                                    String stmtName = generateStmtName(fac.Name, nextDate, stmtEndDate);
        
                                    stmtInsertList.add(
                                        new Statement__c(
                                            Start_Date__c = nextDate,
                                            Group__c = fac.Group__c,
                                            Status__c = unreconciled,
                                            Service_Territory__c = facId,
                                            End_Date__c = stmtEndDate,
                                            Statement_Name__c = stmtName
                                        )
                                    );
        
                                    newStmtMap.put(stmtName, new Map<String, Object>{
                                        newFAPKey => new ACG_Facility_Adjustment_Payment__c(
                                            ACG_Adjustment_ID__c = facAdjId,
                                            ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c,
                                            ACG_Status__c = readyForProcessing
                                        ),
                                        newInvcKey => new Invoice__c(
                                            Facility_Adjustment__c = facAdjId,
                                            Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c,
                                            Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c,
                                            Service_Territory__c = facId,
                                            Status__c = readyForProcessing,
                                            Type__c = facAdjType,
                                            Statement_Date__c = nextDate,
                                            RecordTypeId = invoiceRecId
                                        )
                                    });
        
                                    numPmtsToCreate -= 1;
                                }

                                nextDate = stmtEndDate.addDays(1);
                            }

                            if (numPmtsToCreate > 0) {
                                lstNewFacAdjPay.add(
                                    new ACG_Facility_Adjustment_Payment__c(
                                        ACG_Adjustment_ID__c = facAdjId,
                                        ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c,
                                        ACG_Status__c = readyForProcessing,
                                        Statement__c = stmt.Id
                                    )
                                );
                                lstNewInvoice.add(
                                    new Invoice__c(
                                        Facility_Adjustment__c = facAdjId,
                                        Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c,
                                        Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c,
                                        Service_Territory__c = facId,
                                        Status__c = readyForProcessing,
                                        Type__c = facAdjType,
                                        Statement_Date__c = stmtStartDate,
                                        RecordTypeId = invoiceRecId,
                                        Statement__c = stmt.Id   
                                    )
                                );
        
                                numPmtsToCreate -= 1;
                            }
                        } else if (
                            stmtStartDate >= faStartDate 
                            && stmt.End_Date__c > faStartDate 
                            && stmt.Status__c == unreconciled
                        ) {
                            lstNewFacAdjPay.add(
                                new ACG_Facility_Adjustment_Payment__c(
                                    ACG_Adjustment_ID__c = facAdjId,
                                    ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c,
                                    ACG_Status__c = readyForProcessing,
                                    Statement__c = stmt.Id
                                )
                            );
                            lstNewInvoice.add(
                                new Invoice__c(
                                    Facility_Adjustment__c = facAdjId,
                                    Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c,
                                    Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c,
                                    Service_Territory__c = facId,
                                    Status__c = readyForProcessing,
                                    Type__c = facAdjType,
                                    Statement_Date__c = stmtStartDate,
                                    RecordTypeId = invoiceRecId,
                                    Statement__c = stmt.Id   
                                )
                            );
    
                            numPmtsToCreate -= 1;
                        }

                        existingStartDates.add(stmtStartDate);
                    }
                }
            } else {
                Date stmtStartDate = Date.today();
                Integer year = stmtStartDate.year();
                Integer month = stmtStartDate.month();

                stmtStartDate = Date.newInstance(year, month, 1);

                if (facPmtSchedule == bimonthly && Date.today().day() > 16) {
                    stmtStartDate = Date.newInstance(year, month, 16);
                }

                if (numPmtsToCreate > 0 && stmtStartDate > faStartDate) {
                    while (nextDate < stmtStartDate && numPmtsToCreate > 0) {
                        Date stmtEndDate = Date.newInstance(nextDate.year(), nextDate.month() + 1, 1);
                        stmtEndDate = stmtEndDate.addDays(-1);

                        if (
                            nextDate.day() == 1
                            && (facPmtSchedule == bimonthly || facPmtSchedule == null)
                        ) {                                
                            stmtEndDate = Date.newInstance(nextDate.year(), nextDate.month(), 15);
                        }

                        String stmtName = generateStmtName(fac.Name, nextDate, stmtEndDate);

                        stmtInsertList.add(
                            new Statement__c(
                                Start_Date__c = nextDate,
                                Group__c = fac.Group__c,
                                Status__c = unreconciled,
                                Service_Territory__c = facId,
                                End_Date__c = stmtEndDate,
                                Statement_Name__c = stmtName
                            )
                        );

                        newStmtMap.put(stmtName, new Map<String, Object>{
                            newFAPKey => new ACG_Facility_Adjustment_Payment__c(
                                ACG_Adjustment_ID__c = facAdjId,
                                ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c,
                                ACG_Status__c = readyForProcessing
                            ),
                            newInvcKey => new Invoice__c(
                                Facility_Adjustment__c = facAdjId,
                                Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c,
                                Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c,
                                Service_Territory__c = facId,
                                Status__c = readyForProcessing,
                                Type__c = facAdjType,
                                Statement_Date__c = nextDate,
                                RecordTypeId = invoiceRecId
                            )
                        });

                        nextDate = stmtEndDate.addDays(1);
                        numPmtsToCreate -= 1;
                    }
                }
            }
        }

        if (stmtInsertList.size() > 0) {
            insert stmtInsertList;

            for (Statement__c stmt : stmtInsertList) {
                String stmtName = stmt.Statement_Name__c;
                Map<String, Object> newStmtContainer = (Map<String, Object>) newStmtMap.get(stmtName);
                ACG_Facility_Adjustment_Payment__c newFAP = (ACG_Facility_Adjustment_Payment__c) newStmtContainer.get(newFAPKey);
                Invoice__c newInvc = (Invoice__c) newStmtContainer.get(newInvcKey);

                newFAP.Statement__c = stmt.Id;
                newInvc.Statement__c = stmt.Id;
                lstNewFacAdjPay.add(newFAP);
                lstNewInvoice.add(newInvc);
            }
        }

        return new Map<String, Object>{
            'lstNewFacAdjPay' => lstNewFacAdjPay,
            'lstNewInvoice' => lstNewInvoice
        };
    }

    private static String generateStmtName(String facName, Date startDate, Date endDate) {
        String startDateStr = String.valueOf(startDate);
        String endDateStr = String.valueOf(endDate);

        return facName + ' (' + startDateStr + ' - ' + endDateStr + ')';
    }
}