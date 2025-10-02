/**
 * @description       : Creates Statements from Service Territories
 * @author            : soham.saha@salesforce.com
 * @group             : 
 * @last modified on  : 06-05-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   10-23-2023   soham.saha@salesforce.com
 *       05-24-2024   joshtupas@salesforce.com             Modified query to accomodate "Eligible_for_Payment__c" flag for NE club while maintaining original logic for ACA club. Changed query for Statements to look at a set of start dates instead of a single start date. Added try-catch and error logging.
 *       05-28-2024   joshtupas@salesforce.com             Removed ACA vs NE logic to enable "Eligible_for_Payment__c" for ACA club
 *       05-29-2024   joshtupas@salesforce.com             Added query condition to exclude Service Territories with null payment schedules
 *       06-04-2024   joshtupas@salesforce.com             Reworked query for FAs to only query ones that have adjustments remaining AND does not already have Invoices / FAPs that are ready for processing / payment
 *       06-05-2024   joshtupas@salesforce.com             Reworked condition for FA query to only fetch FAs that have a total invoice count (pending and paid) that is less than the number of payments
**/
public class AAAStatementCreationBatch implements Database.Batchable<sObject>, Schedulable {
    public String query;
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        query = 
            'SELECT '+
                'Id,'+
                'Name,'+
                'Group__c,'+
                'Payment_Schedule__c'+
            ' FROM ServiceTerritory'+
            ' WHERE Eligible_for_Payment__c = true'+
            ' AND Payment_Schedule__c != null';

        return Database.getQueryLocator(query);         
    }
    
    public void execute(Database.BatchableContext BC, List<ServiceTerritory> scope) {
        try {
            List<Statement__c> lstNewStatements = new List<Statement__c>();
            List<Id> lstScopeIds = new List<Id>();
            Set<Date> startDateSet = new Set<Date>();
            Date startDate = Date.Today();
            
            for (ServiceTerritory fac : scope) {
                lstScopeIds.add(fac.id);
            }
            
            List<Statement__c> lstExistingStatements = [
                SELECT Id, Service_Territory__c
                FROM Statement__c 
                WHERE Service_Territory__c IN :lstScopeIds 
                AND End_Date__c >= :startDate
            ];
            
            Set<Id> setExistingStatementFacilites = new Set<Id>();
            for (Statement__c st : lstExistingStatements) {
                setExistingStatementFacilites.add(st.Service_Territory__c);
            }
    
            Integer currentMonth = startDate.Month();
            Integer currentYear = startDate.Year();
            Date endDate;
            Date monthlyEndDate;
            Date nextMonthStartDate;
    
            //Bi-monthly logic
            if (startDate.day() <= 15) {
               endDate = Date.newInstance(currentYear, currentMonth, 15); 
            } else {
                if (currentMonth == 12) {
                    endDate = Date.newInstance(currentYear, 12, 31);
                } else {
                    nextMonthStartDate = Date.newInstance(currentYear, currentMonth + 1, 1);
                    endDate = nextMonthStartDate.addDays(-1);
                }            
            }
            
            //Monthly logic
            if (currentMonth == 12) {
                monthlyEndDate = Date.newInstance(currentYear, 12, 31);
            } else {
                nextMonthStartDate = Date.newInstance(currentYear, currentMonth + 1, 1);
                monthlyEndDate = nextMonthStartDate.addDays(-1);
            }
            
            Set<Id> setInScopeFac = new Set<Id>();
            
            for (ServiceTerritory fac : scope) {
                if (!setExistingStatementFacilites.contains(fac.id)) {
                    Date stmtEndDate;
                    String stmtName;
    
                    if (fac.Payment_Schedule__c == 'Monthly') {
                        startDate = Date.newInstance(currentYear, currentMonth, 1);
                        stmtEndDate = monthlyEndDate;
                        stmtName = generateStmtName(fac.Name, startDate, monthlyEndDate);                   
                    } else {
                        if (endDate.day() == 15) {
                            startDate = Date.newInstance(currentYear, currentMonth, 1);
                        } else {
                            startDate = Date.newInstance(currentYear, currentMonth, 16);
                        }
    
                        stmtEndDate = endDate;
                        stmtName = generateStmtName(fac.Name, startDate, endDate);
                    }
    
                    lstNewStatements.add(
                        new Statement__c(
                            Start_Date__c = startDate,
                            Group__c = fac.Group__c,
                            Status__c = 'Unreconciled',
                            Service_Territory__c = fac.Id,
                            End_Date__c = stmtEndDate,
                            Statement_Name__c = stmtName
                        )
                    );
                    setInScopeFac.add(fac.Id);
                    startDateSet.add(startDate);
                }
            }
            
            if (lstNewStatements != null && lstNewStatements.size() > 0) {
                insert lstNewStatements;
            }
            
            List<ACG_Facility_Adjustment__c> lstFacAdj = [
                SELECT 
                    Id,
                    Service_Territory__c,
                    ACG_Adjustment_Category__c, 
                    ACG_Adjustment_Type__c,
                    ACG_Payment_Amount__c 
                FROM ACG_Facility_Adjustment__c 
                WHERE ACG_Status__c = 'Active' 
                AND Processed_Adjustments_Remaining__c > 0
                AND Service_Territory__c IN :setInScopeFac
            ];
    
            //Get RecordType Ids
            Id invoiceRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
            Id invoiceLIRecId = Schema.SObjectType.Invoice_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
            String readyForProcessing = 'Ready for Processing';
            List<ACG_Facility_Adjustment_Payment__c> lstNewFacAdjPay = new List<ACG_Facility_Adjustment_Payment__c>();
            List<Invoice__c> lstnewInvoice = new List<Invoice__c>();
            Set<Id> setFacilityId = new Set<Id>();
            
            for (ACG_Facility_Adjustment__c facAdj : lstFacAdj) {
                //New Facility Adjustment Payment
                lstNewFacAdjPay.add(
                    new ACG_Facility_Adjustment_Payment__c(
                        ACG_Adjustment_ID__c = facAdj.id,
                        ACG_Payment_Amount__c = facAdj.ACG_Payment_Amount__c,
                        ACG_Status__c = readyForProcessing
                    )
                );
                
                //New Invoice
                lstnewInvoice.add(
                    new Invoice__c(
                        Facility_Adjustment__c = facAdj.id,
                        Facility_Adjustment_Category__c = facAdj.ACG_Adjustment_Category__c,
                        Facility_Adjustment_Type__c = facAdj.ACG_Adjustment_Type__c,
                        Service_Territory__c = facAdj.Service_Territory__c,
                        Status__c = readyForProcessing,
                        Type__c = 'Facility Adjustments',
                        RecordTypeId = invoiceRecId
                    )
                );            
                
                //Set of Facility Ids in the Facility Adjustment records in scope 
                setFacilityId.add(facAdj.Service_Territory__c);
            }
            
            //Insert Facility Adjustment Payment records
            if (lstNewFacAdjPay != null && lstNewFacAdjPay.size() > 0) {
                insert lstNewFacAdjPay;
            }
            
            //Map of Facility Adjustment to Facility Adjustment Payment
            Map<Id, ACG_Facility_Adjustment_Payment__c> mapFacAdjToFacAdjPay = new Map<Id, ACG_Facility_Adjustment_Payment__c>();
            for (ACG_Facility_Adjustment_Payment__c facAdjPay : lstNewFacAdjPay) {
                mapFacAdjToFacAdjPay.put(facAdjPay.ACG_Adjustment_ID__c, facAdjPay);
            }
           
            //Create a map of Facility to Statement for this payment period
            Map<Id,Statement__c> mapFacilityToStatement = new Map<Id,Statement__c>();
            List<Statement__c> lstStatements = [
                SELECT Id, Service_Territory__c, Start_Date__c 
                FROM Statement__c 
                WHERE Service_Territory__c IN :setFacilityId 
                AND Start_Date__c IN :startDateSet
            ];
    
            for (Statement__c st : lstStatements) {
                mapFacilityToStatement.put(st.Service_Territory__c, st);
            }
            
            //Assign remaining Statement values on Invoice
            for (Invoice__c inv : lstnewInvoice) {
                Statement__c st = mapFacilityToStatement.get(inv.Service_Territory__c);
                inv.Statement__c = st.Id;
                inv.Statement_Date__c = st.Start_Date__c;
            }
            
            //Insert Invoice records
            if (lstnewInvoice != null && lstnewInvoice.size() > 0) {
                insert lstnewInvoice;
            }
            
            //Insert Invoice Line Item records
            List<Invoice_Line_Item__c> lstNewInvLI = new List<Invoice_Line_Item__c>();
            for (Invoice__c inv : lstnewInvoice) {
                ACG_Facility_Adjustment_Payment__c fap = mapFacAdjToFacAdjPay.get(inv.Facility_Adjustment__c);
                Invoice_Line_Item__c invLI = new Invoice_Line_Item__c(
                    Invoice__c = inv.Id
                );
    
                if (fap != null) {
                    if (fap.Id != null) {
                        invLI.Facility_Adjustment_Payment__c = fap.Id;
                    }
                    
                    if (fap.ACG_Payment_Amount__c != null) {
                        invLI.Cost__c = fap.ACG_Payment_Amount__c;
                    }
                }
    
                invLI.RecordTypeId = invoiceLIRecId;
                lstNewInvLI.add(invLI);
            }
            
            if (lstNewInvLI!=null && lstNewInvLI.size() > 0) {
                insert lstNewInvLI;
            }
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();
        
            insert new FSL_Application_Log__c(
                Operation__c = 'AAAStatementCreationBatch',
                Error_Message__c = errMsg
            );

            throw e;
        }
    }

    private String generateStmtName(String facName, Date startDate, Date endDate) {
        String startDateStr = String.valueOf(startDate);
        String endDateStr = String.valueOf(endDate);

        return facName + ' (' + startDateStr + ' - ' + endDateStr + ')';
    }
    
   	public void finish(Database.BatchableContext BC) {        
        // Finish logic here
   	}
    
    public void execute(SchedulableContext ctx) {
        AAAStatementCreationBatch batch = new AAAStatementCreationBatch();
        Database.executebatch(batch, 200);
    }
}