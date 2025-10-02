public class FSL_ReciprocalApexClass extends FSL_TriggerDispatcher.TriggerHandlerBase {
	List<Reciprocal__c> newList = Trigger.new;
    List<Reciprocal__c> oldList = Trigger.old;
    Map<Id, Reciprocal__c> newMap = (Map<Id, Reciprocal__c>) Trigger.newMap;
    Map<Id, Reciprocal__c> oldMap = (Map<Id, Reciprocal__c>) Trigger.oldMap;
    public static Id ibRecTypeId = Schema.SObjectType.Reciprocal__c
        .getRecordTypeInfosByDeveloperName()
        .get('Inbound_Payment_Requests')
        .getRecordTypeId();
    public static Id obRecTypeId = Schema.SObjectType.Reciprocal__c
        .getRecordTypeInfosByDeveloperName()
        .get('Outbound_Payment_Requests')
        .getRecordTypeId();
    
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Reciprocal__c');
    }

    public override void beforeInsert() {
        checkIBDuplicates(newList);
    }
    
    public override void beforeUpdate() {
        validateOBReciprocalCB(oldMap, newMap);
        updateTransactionTypeOnStatusChange(oldMap, newMap);//EMI
    }

    public override void afterUpdate() {
        handleAfterUpsert(newList);
    }

    public static void checkIBDuplicates(List<Reciprocal__c> newList) {
        Set<String> nameDateTCodeSet = new Set<String>();
        Set<String> authCodeSet = new Set<String>();
        List<Reciprocal__c> ibRecList = new List<Reciprocal__c>();

        for (Reciprocal__c rec : newList) {
            if (rec.RecordTypeId == ibRecTypeId) {
                String nameDateTCode = rec.NameDateTroubleCode__c.toUpperCase();

                if (
                    rec.Feedback__c == null
                    && rec.Service_Contract__c == null
                    && rec.Transaction_Type__c != 'DSP'
                ) {
                    String authCode = rec.CDX_Authorization_Code__c;

                    if (authCode != null) {
                        authCodeSet.add(authCode);
                    }

                    ibRecList.add(rec);
                }

                nameDateTCodeSet.add(nameDateTCode);
            }
        }

        if (nameDateTCodeSet.size() > 0) {
            Map<String, List<Reciprocal__c>> recMapList = new Map<String, List<Reciprocal__c>>();
            Set<Reciprocal__c> recUpdateSet = new Set<Reciprocal__c>();
            List<Reciprocal__c> existingRs = [
                SELECT Id, is_Duplicate__c, NameDateTroubleCode__c 
                FROM Reciprocal__c 
                WHERE NameDateTroubleCode__c IN :nameDateTCodeSet 
                AND is_Duplicate__c = false 
                AND RecordTypeId = :ibRecTypeId
            ];

            for (Reciprocal__c rec : existingRs) {
                String nameDateTCode = rec.NameDateTroubleCode__c.toUpperCase();
                List<Reciprocal__c> tempRecList;

                if (recMapList.get(nameDateTCode) == null) {
                    tempRecList = new List<Reciprocal__c>{rec};
                } else {
                    tempRecList = recMapList.get(nameDateTCode);
                    tempRecList.add(rec);
                }

                recMapList.put(nameDateTCode, tempRecList);
            }
            
            // loop through all of these, mark all of them as duplicates, update later
            for (Reciprocal__c rec : newList) {
                String nameDateTCode = rec.NameDateTroubleCode__c.toUpperCase();
                List<Reciprocal__c> existingRecList = recMapList.get(nameDateTCode);
    
                if (existingRecList != null && existingRecList.size() > 0) {
                    for (Reciprocal__c existingRec : existingRecList) {
                        existingRec.is_Duplicate__c = true;
                        recUpdateSet.add(existingRec);
                    }
                    
                    rec.is_Duplicate__c = true;
                }
            }
            
            if (recUpdateSet.size() > 0) {
                update new List<Reciprocal__c>(recUpdateSet);
            }
        }   
    }

    public static void validateOBReciprocalCB(Map<Id, Reciprocal__c> oldMap, Map<Id, Reciprocal__c> newMap) {
        for (Id recId : newMap.keySet()) {
            Reciprocal__c newRec = newMap.get(recId);
            Reciprocal__c oldRec = oldMap.get(recId); 

            if (
                oldRec.RecordTypeId == obRecTypeId
                && newRec.Cost_Buffer__c != null
                && newRec.Cost_Buffer__c != oldRec.Cost_Buffer__c
            ) {
                List<String> newPartList = newRec.Cost_Buffer__c.split('BON/');
                List<String> oldPartList = oldRec.Cost_Buffer__c.split('BON/');
                Integer newBONCost = Integer.valueOf(newPartList[newPartList.size() - 1]) / 100;
                Integer oldBONCost = Integer.valueOf(oldPartList[oldPartList.size() - 1]) / 100;

                newRec.Total_Dollar_Amount__c += newBONCost - oldBONCost;
            }
        }
    }

    /**EMI - SSFI-380**/
    public static void updateTransactionTypeOnStatusChange(Map<Id, Reciprocal__c> oldMap, Map<Id, Reciprocal__c> newMap) {
    for (Id recId : newMap.keySet()) {
        Reciprocal__c newRec = newMap.get(recId);
        Reciprocal__c oldRec = oldMap.get(recId); 
		system.debug('newRec====>'+newRec);
        system.debug('oldRec====>'+oldRec);
        // Check if Status has changed
        if (newRec.Status__c != oldRec.Status__c) {

            // Apply logic based on Status and Transaction Type
            if (newRec.Status__c == 'New' && newRec.Transaction__c == 'PAY') {
                newRec.Transaction__c = 'PAY';
            } 
            else if (newRec.Status__c == 'Approved' && newRec.Transaction__c == 'PAY') {
                newRec.Transaction__c = 'PAY';
            } 
            else if (newRec.Status__c == 'Disputed' && newRec.Transaction__c == 'PAY') {
                newRec.Transaction__c = 'DSP';
            } 
            else if (newRec.Status__c == 'Write-Off' && newRec.Transaction__c == 'PAY') {
                newRec.Transaction__c = 'ERR';
            } 
            else if (newRec.Status__c == 'Rebilled' && newRec.Transaction__c == 'PAY') {
                newRec.Transaction__c = 'PAY';
            }

            else if (newRec.Status__c == 'New' && newRec.Transaction__c == 'ACP') {
                newRec.Transaction__c = 'ACP';
            } 
            else if (newRec.Status__c == 'Approved' && newRec.Transaction__c == 'ACP') {
                newRec.Transaction__c = 'PAY';
            } 
            else if (newRec.Status__c == 'Disputed' && newRec.Transaction__c == 'ACP') {
                newRec.Transaction__c = 'DSP';
            } 
            else if (newRec.Status__c == 'Write-Off' && newRec.Transaction__c == 'ACP') {
                newRec.Transaction__c = 'ERR';
            } 
            else if (newRec.Status__c == 'Rebilled' && newRec.Transaction__c == 'ACP') {
                newRec.Transaction__c = 'PAY';
            }

            else if (newRec.Status__c == 'New' && newRec.Transaction__c == 'ERR') {
                newRec.Transaction__c = 'ERR';
            } 
            else if (newRec.Status__c == 'Approved' && newRec.Transaction__c == 'ERR') {
                newRec.Transaction__c = 'PAY';
            } 
            else if (newRec.Status__c == 'Disputed' && newRec.Transaction__c == 'ERR') {
                newRec.Transaction__c = 'DSP';
            } 
            else if (newRec.Status__c == 'Write-Off' && newRec.Transaction__c == 'ERR') {
                newRec.Transaction__c = 'ERR';
            } 
            else if (newRec.Status__c == 'Rebilled' && newRec.Transaction__c == 'ERR') {
                newRec.Transaction__c = 'PAY';
            }

            else if (newRec.Status__c == 'New' && newRec.Transaction__c == 'DSP') {
                newRec.Transaction__c = 'DSP';
            } 
            else if (newRec.Status__c == 'Approved' && newRec.Transaction__c == 'DSP') {
                newRec.Transaction__c = 'PAY';
            } 
            else if (newRec.Status__c == 'Disputed' && newRec.Transaction__c == 'DSP') {
                newRec.Transaction__c = 'DSP';
            } 
            else if (newRec.Status__c == 'Write-Off' && newRec.Transaction__c == 'DSP') {
                newRec.Transaction__c = 'ERR';
            } 
            else if (newRec.Status__c == 'Rebilled' && newRec.Transaction__c == 'DSP') {
                newRec.Transaction__c = 'PAY';
            }
        }
   	 }
	}
	/**EMI - SSFI-380**/

    public static void handleAfterUpsert(List<Reciprocal__c> newList) {
        List<Reciprocal__c> ibRecList = new List<Reciprocal__c>();

        for (Reciprocal__c newRec : newList) {
            if (
                newRec.RecordTypeId == ibRecTypeId
                && newRec.Feedback__c == null
                && newRec.Service_Contract__c == null
            ) {
                ibRecList.add(newRec);
            }
        }

        if (ibRecList.size() > 0) {
            ReciprocalServiceContractLookup.FlowInput flowInput = new ReciprocalServiceContractLookup.FlowInput();

            flowInput.reciprocals = ibRecList;

            ReciprocalServiceContractLookup.reciprocalServiceContractInvocable(new List<ReciprocalServiceContractLookup.FlowInput>{flowInput});
        }
    }
}