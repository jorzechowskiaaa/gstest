/**
 * @description       : Statement trigger handler
 * @author            : joshtupas@salesforce.com 
 * @group             : 
 * @last modified on  : 06-05-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   04-26-2024   joshtupas@salesforce.com 
 *       06-05-2024   joshtupas@salesforce.com             Made condition more specific when checking Invoice list size
**/
public class FSL_StatementTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    List<Statement__c> newList = Trigger.new;
    List<Statement__c> oldList = Trigger.old;
    Map<Id, Statement__c> newMap = (Map<Id, Statement__c>) Trigger.newMap;
    Map<Id, Statement__c> oldMap = (Map<Id, Statement__c>) Trigger.oldMap;
    private static String currUserId = UserInfo.getUserId();
    private static List<PermissionSetAssignment> permSetList = [
        SELECT Id
        FROM PermissionSetAssignment 
        WHERE PermissionSet.Name = 'Skip_Automation_Logic'
        AND AssigneeId = :currUserId
    ];

    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Statement__c');
    }

    public override void afterUpdate() {
        markInvcsReadyForPayment(oldMap, newMap);
    }

    public static void markInvcsReadyForPayment(Map<Id, Statement__c> oldStmtMap, Map<Id, Statement__c> newStmtMap) {
        if (permSetList == null || permSetList.isEmpty()) {
            if (newStmtMap != null) {
                List<String> stmtIdList = new List<String>();

                for (String stmtId : oldStmtMap.keySet()) {
                    Statement__c oldStmt = oldStmtMap.get(stmtId);
                    Statement__c newStmt = newStmtMap.get(stmtId);
                    String oldStatus = oldStmt.Status__c;
                    String newStatus = newStmt.Status__c;

                    if (newStatus == 'Reconciled' && newStatus != oldStatus) {
                        stmtIdList.add(stmtId);
                    }
                }

                if (stmtIdList.size() == 1) {
                    List<Invoice__c> invcList = [
                        SELECT Id, Status__c
                        FROM Invoice__c
                        WHERE Status__c = 'Ready for Processing'
                        AND Statement__c = :stmtIdList
                    ];

                    if (invcList != null && invcList.size() > 0) {
                        if (invcList.size() < 1000) {
                            List<Invoice__c> invcUpdateList = new List<Invoice__c>();
    
                            for (Invoice__c invc : invcList) {
                                invc.Status__c = 'Ready for Payment';
                                invcUpdateList.add(invc);
                            }
    
                            if (invcUpdateList.size() > 0) {
                                update invcUpdateList;
                            }
                        } else {
                            Database.executeBatch(new AAAInvoiceReadyForPaymentBatch(stmtIdList), 9000);
                        }
                    }
                } else if (stmtIdList.size() > 1) {
                    Database.executeBatch(new AAAInvoiceReadyForPaymentBatch(stmtIdList), 9000);
                }
            }
        }
    }
}