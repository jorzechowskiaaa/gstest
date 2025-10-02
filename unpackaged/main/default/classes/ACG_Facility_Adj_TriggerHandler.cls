/**
 * @description       : Creates Statements from Service Territories
 * @author            : ksarathy@salesforce.com
 * @group             : 
 * @last modified on  : 06-10-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-19-2024   ksarathy@salesforce.com
 *       05-24-2024   joshtupas@salesforce.com             Moved logic for deleting associated Invoices from "after delete" to "before delete" trigger
 *       06-05-2024   joshtupas@salesforce.com             Added logic to "backdate" activated FAs from a status of "Deferred"
 *       06-10-2024   joshtupas@salesforce.com             Added validation to require a "Reactivation Date" when activating deferred FAs. Added logic to ignore FA inserts that are future dated.
**/
public class ACG_Facility_Adj_TriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<ACG_Facility_Adjustment__c> newList = Trigger.new;
    List<ACG_Facility_Adjustment__c> oldList = Trigger.old;
    Map<Id, ACG_Facility_Adjustment__c> newMap = (Map<Id, ACG_Facility_Adjustment__c >) Trigger.newMap;
    Map<Id, ACG_Facility_Adjustment__c> oldMap = (Map<Id, ACG_Facility_Adjustment__c >) Trigger.oldMap;
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_CANCELLED = 'Cancelled';
    private static final String STATUS_DEFERRED = 'Deferred';
    private static List<PicklistValueInfo> faStatusPicklist = [
        SELECT Label, Value 
        FROM PicklistValueInfo 
        WHERE EntityParticle.EntityDefinition.QualifiedApiName = 'ACG_Facility_Adjustment__c'
        AND EntityParticle.QualifiedApiName = 'ACG_Status__c' 
        AND IsActive = true 
    ];
    private static Id userProfileId = UserInfo.getProfileId();
    private static Id sysAdminProfileId = FSL_OrgCache.sysAdminProfileId();

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ACG_Facility_Adjustment__c');
    }
    
    public override void beforeInsert() {
        validateBeforeInsertUpdate(newList);
        applyDeferActiveDate(oldMap, oldList, newList);
    }

    public override void afterInsert() {
        createFacAdjInvoices(newList);
    }

    public override void beforeUpdate() {
        validateBeforeInsertUpdate(newList);
        applyDeferActiveDate(oldMap, oldList, newList);
    }

    public override void afterUpdate() {
        handleCancelledFacAdjs(newMap);
        handleDeferredActiveFAs(oldMap, newMap);
    }

    public override void beforeDelete() {
        validateBeforeDelete(oldList);
    }

    public static void validateBeforeInsertUpdate(List<ACG_Facility_Adjustment__c> newList) {
        if (newList != null) {
            List<String> statusLabelList = new List<String>();
            List<String> statusValueList = new List<String>();

            if (faStatusPicklist.size() > 0) {
                for (PicklistValueInfo pvi : faStatusPicklist) {
                    statusLabelList.add(pvi.Label);
                    statusValueList.add(pvi.Value);
                }
            }

            for (ACG_Facility_Adjustment__c newFA : newList) {
                String faStatus = newFA.ACG_Status__c;

                if (
                    userProfileId != sysAdminProfileId
                    && !statusValueList.contains(faStatus)
                ) {
                    String errorMsg = faStatus + ' is not an available value. Please pick from the following values: ';

                    for (Integer i = 0; i < statusLabelList.size(); i++) {
                        String label = statusLabelList[i];

                        errorMsg += '\'' + label + '\'';

                        if (i < statusLabelList.size() - 1) {
                            errorMsg += ',';
                        }
                    }

                    newFA.addError(errorMsg);
                }

                if (faStatus == STATUS_ACTIVE && newFA.ACG_Start_Date__c == null) {
                    newFA.addError('Start Date is required for Active Facility Adjustments.');
                }

                if (faStatus == STATUS_CANCELLED && newFA.ACG_End_Date__c == null) {
                    newFA.addError('End Date is required for Cancelled Facility Adjustments.');
                }
            }
        }
    }

    public static void validateBeforeDelete(List<ACG_Facility_Adjustment__c> oldList) {
        Boolean hasValidationError = false;
        String userProfileId = UserInfo.getProfileId();
        String adminProfileId = FSL_OrgCache.sysAdminProfileId();
        List<String> validStatuses = new List<String>{'Active', 'Deferred'};
        List<String> invcStatuses = new List<String>{
            'Ready for Payment', 'Submitted for Payment', 'Paid'
        };
        List<String> faIdList = new List<String>();
        List<Invoice__c> invcList = new List<Invoice__c>();
        Map<String, List<Invoice__c>> faInvcMap = new Map<String, List<Invoice__c>>();

        for (ACG_Facility_Adjustment__c fa : oldList) {
            String faStatus = fa.ACG_Status__c;
    
            if (
                !validStatuses.contains(faStatus)
                && userProfileId != adminProfileId
            ) {
                String errMsg = 'Cannot delete ' + fa.Name 
                    + ' with a current status of ' + faStatus;

                fa.addError(errMsg);
                hasValidationError = true;
            }

            faIdList.add(fa.Id);
        }

        if (!hasValidationError) {
            invcList = [
                SELECT Id, Facility_Adjustment__c, Status__c
                FROM Invoice__c
                WHERE Facility_Adjustment__c IN :faIdList
            ];
    
            if (invcList.size() > 0) {
                for (Invoice__c invc : invcList) {
                    String faId = invc.Facility_Adjustment__c;
                    Boolean isInvalidStatus = invcStatuses.contains(invc.Status__c);
    
                    if (isInvalidStatus) {
                        if (faInvcMap.get(faId) == null) {
                            faInvcMap.put(faId, new List<Invoice__c>{invc});
                        } else {
                            List<Invoice__c> tempInvcList = faInvcMap.get(faId);
        
                            tempInvcList.add(invc);
                            faInvcMap.put(faId, tempInvcList);
                        }
                    }
                }
    
                for (ACG_Facility_Adjustment__c fa : oldList) {
                    List<Invoice__c> faInvcList = faInvcMap.get(fa.Id);
    
                    if (faInvcList?.size() > 0) {
                        String errMsg = 'Cannot delete ' + fa.Name 
                            + ' because it has ' + faInvcList.size() 
                            + ' Invoice(s) that are under reconciled Statements. Please cancel the Facility Adjustment instead.';
    
                        fa.addError(errMsg);
                        hasValidationError = true;
                    }
                }
            }
    
            if (!hasValidationError && invcList.size() > 0) {
                delete invcList;
            }
        }
    }

    public static void applyDeferActiveDate(
        Map<Id, ACG_Facility_Adjustment__c> oldMap, 
        List<ACG_Facility_Adjustment__c> oldList,
        List<ACG_Facility_Adjustment__c> newList
    ) {
        for (ACG_Facility_Adjustment__c newFA : newList) {
            ACG_Facility_Adjustment__c oldFA = oldMap?.get(newFA.Id);
            String newStatus = newFA.ACG_Status__c;
            Boolean populateDate = true;

            if (newStatus == STATUS_DEFERRED) {
                if (oldFA != null && oldFA.ACG_Status__c == STATUS_DEFERRED) {
                    populateDate = false;
                }

                if (populateDate) {
                    newFA.Reactivated_On__c = null;
                    newFA.Reactivation_Date__c = null;
                    newFA.Deferred_On__c = Datetime.now();
                }
            } else if (newStatus == STATUS_ACTIVE) {
                if (
                    (oldFA != null && oldFA.ACG_Status__c != STATUS_DEFERRED)
                    || oldFA == null
                ) {
                    populateDate = false;
                }

                if (
                    oldFA != null 
                    && oldFA.ACG_Status__c == STATUS_DEFERRED
                    && newFA.Reactivation_Date__c == null
                ) {
                    newFA.addError('"Reactivation Date" must be filled when re-activating a deferred Facility Adjustment.');

                    populateDate = false;
                }

                if (populateDate) {
                    newFA.Reactivated_On__c = Datetime.now();
                    newFA.Deferred_On__c = null;
                }
            }
        }
    }

    public static void createFacAdjInvoices(List<ACG_Facility_Adjustment__c> lstFacAdjInserts) {
        List<ACG_Facility_Adjustment__c> lstFacAdj = new List<ACG_Facility_Adjustment__c>();
        List<ACG_Facility_Adjustment__c> finalFAList = new List<ACG_Facility_Adjustment__c>();
        List<String> facIdList = new List<String>();
      
        for (ACG_Facility_Adjustment__c adj : lstFacAdjInserts) {
            if (adj.ACG_Adjustments_Remaining__c > 0 && adj.ACG_Status__c == STATUS_ACTIVE) {
                lstFacAdj.add(adj);
                facIdList.add(adj.Service_Territory__c );
            }
        }

        Map<Id, ServiceTerritory> facMap = new Map<Id, ServiceTerritory>(
            [
                SELECT Id, Payment_Schedule__c
                FROM ServiceTerritory
                WHERE Id IN :facIdList
            ]
        );
        Date latestBiMoStartDate = Date.today();
        Date latestMoStartDate = latestBiMoStartDate;

        latestMoStartDate = Date.newInstance(
            latestMoStartDate.year(), 
            latestMoStartDate.month() + 1, 
            1
        );
        latestMoStartDate = latestMoStartDate.addDays(-1);

        if (latestBiMoStartDate.day() > 15) {
            latestBiMoStartDate = latestMoStartDate;
        } else {
            latestBiMoStartDate = Date.newInstance(
                latestBiMoStartDate.year(), 
                latestBiMoStartDate.month(), 
                15
            );
        }

        for (ACG_Facility_Adjustment__c fa : lstFacAdj) {
            ServiceTerritory fac = facMap.get(fa.Service_Territory__c);
            Date faStartDate = fa.Reactivation_Date__c != null ?
                fa.Reactivation_Date__c : fa.ACG_Start_Date__c;
            String pmtSchedule = fac.Payment_Schedule__c;

            if (fac != null) {
                if (
                    pmtSchedule == 'Monthly'
                    && faStartDate <= latestMoStartDate
                ) {
                    finalFAList.add(fa);
                } else if (
                    pmtSchedule == 'Bi-monthly'
                    && faStartDate <= latestBiMoStartDate
                ) {
                    finalFAList.add(fa);
                }
            }
        }

        if (!finalFAList.isEmpty()) {
            ACG_CreateFacilityAdjustments.processFacilityAdjustments(finalFAList);
        }
    }

    public static void handleCancelledFacAdjs(Map<Id, ACG_Facility_Adjustment__c> faMap) {
        List<String> faIdList = new List<String>();
        List<String> statusList = new List<String>{
            'Ready for Processing', 'Deferred'
        };
        List<Invoice__c> invcList = new List<Invoice__c>();
        List<Invoice__c> invcDeleteList = new List<Invoice__c>();

        try {
            for (String key : faMap.keySet()) {
                ACG_Facility_Adjustment__c fa = faMap.get(key);

                if (fa.ACG_Status__c == STATUS_CANCELLED) {
                    faIdList.add(fa.Id);
                }
            }

            if (faIdList.size() > 0) {
                invcList = [
                    SELECT 
                        Id, 
                        Status__c, 
                        Facility_Adjustment__c,
                        Statement__r.End_Date__c
                    FROM Invoice__c
                    WHERE Facility_Adjustment__c IN :faIdList
                    AND Status__c IN :statusList
                    AND Statement__r.Status__c = 'Unreconciled'
                ];

                for (Invoice__c invc : invcList) {
                    String faId = invc.Facility_Adjustment__c;
                    ACG_Facility_Adjustment__c fa = faMap.get(faId);
    
                    if (
                        fa.ACG_Status__c == STATUS_CANCELLED
                        && invc.Statement__r.End_Date__c > fa.ACG_End_Date__c
                    ) {
                        invcDeleteList.add(invc);
                    }
                }
    
                if (invcDeleteList.size() > 0) {
                    delete invcDeleteList;
                }
            }
        } catch (Exception e) {
            handleException(e);
        }
    }

    public static void handleDeferredActiveFAs(Map<Id, ACG_Facility_Adjustment__c> oldMap, Map<Id, ACG_Facility_Adjustment__c> newMap) {
        List<String> faIdDeferList = new List<String>();
        List<String> faIdActiveList = new List<String>();
        List<Invoice__c> invcDeferList = new List<Invoice__c>();
        List<Invoice__c> invcActiveList = new List<Invoice__c>();
        List<Invoice__c> invcUpdateList = new List<Invoice__c>();
        List<ACG_Facility_Adjustment__c> activeFAList = new List<ACG_Facility_Adjustment__c>();
        
        try {
            for (String key : newMap.keySet()) {
                ACG_Facility_Adjustment__c newFA = newMap.get(key);
                ACG_Facility_Adjustment__c oldFA = oldMap.get(key);

                if (oldFA != null) {
                    if (
                        oldFA.ACG_Status__c != STATUS_DEFERRED
                        && newFA.ACG_Status__c == STATUS_DEFERRED
                    ) {
                        faIdDeferList.add(newFA.Id);
                    } else if (
                        oldFA.ACG_Status__c == STATUS_DEFERRED
                        && newFA.ACG_Status__c == STATUS_ACTIVE
                    ) {
                        faIdActiveList.add(newFA.Id);
                        activeFAList.add(newFA);
                    }
                }
            }

            if (faIdDeferList.size() > 0) {
                invcDeferList = [
                    SELECT 
                        Id, 
                        Status__c
                    FROM Invoice__c
                    WHERE Facility_Adjustment__c IN :faIdDeferList
                    AND Status__c = 'Ready for Processing'
                    AND Statement__r.Status__c = 'Unreconciled'
                ];

                for (Invoice__c invc : invcDeferList) {
                    invc.Status__c = 'Deferred';
                    invcUpdateList.add(invc);
                }
            }

            if (faIdActiveList.size() > 0) {
                invcActiveList = [
                    SELECT 
                        Id, 
                        Status__c,
                        Facility_Adjustment__c
                    FROM Invoice__c
                    WHERE Facility_Adjustment__c IN :faIdActiveList
                    AND Status__c = 'Deferred'
                    AND Statement__r.Status__c = 'Unreconciled'
                ];

                for (Invoice__c invc : invcActiveList) {
                    invc.Status__c = 'Ready for Processing';
                    invcUpdateList.add(invc);
                }
            }

            if (invcUpdateList.size() > 0) {
                update invcUpdateList;
            }

            if (activeFAList.size() > 0) {
                createFacAdjInvoices(activeFAList);
            }
        } catch (Exception e) {
            handleException(e);
        }
    }

    private static void handleException(Exception e) {
        String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

        insert new FSL_Application_Log__c(
            Operation__c = 'ACG_Facility_Adj_TriggerHandler',
            Error_Message__c = errMsg
        );
    }
}