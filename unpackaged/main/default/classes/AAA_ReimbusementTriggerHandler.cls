public class AAA_ReimbusementTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
    
    List<ACG_Reimbursement__c > newList = Trigger.new;
    List<ACG_Reimbursement__c > oldList = Trigger.old;
    Map<Id, ACG_Reimbursement__c > newMap = (Map<Id, ACG_Reimbursement__c >)Trigger.newMap;
    Map<Id, ACG_Reimbursement__c > oldMap = (Map<Id, ACG_Reimbursement__c >)Trigger.oldMap;
    
    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ACG_Reimbursement__c');
    }

    public override void beforeInsert() {
        populateDateReceived(newList);
    }

    public override void beforeUpdate() {
        validateAltAddress(newList);
    }
    
    public override void afterInsert() {
       populateMemberInfo(newMap.keySet());
    }
    
    @future (callout = true)
    public static void populateMemberInfo(Set<Id> setRemIds){     
        List<ACG_Reimbursement__c> lstRem = [
            SELECT 
                Id, ACG_Member_Name__c, Member_Id__c, ACG_Member_Name__r.Member_Card_Num__pc
            FROM ACG_Reimbursement__c 
            WHERE Id IN :setRemIds
        ];
        List<ACG_Reimbursement__c> lstRemToUpdate = new List<ACG_Reimbursement__c>();

        if (lstRem != null && lstRem.size() > 0) {
            Boolean genMembershipFlag = false;

            for (ACG_Reimbursement__c rem : lstRem) {
                if (!String.isBlank(rem.Member_Id__c) && rem.Member_Id__c.length() < 16) {
                    if(rem.ACG_Member_Name__c != null) {
                        rem.Member_Id__c = rem.ACG_Member_Name__r.Member_Card_Num__pc;
                        genMembershipFlag = true;
                    } else {
                        rem.Member_Id__c = AAA_GenerateMembershipId.genMembershipIdMain(rem.Member_Id__c);
                    }
                }

                if (!String.isBlank(rem.Member_Id__c)) {
                    Map<String,String> mapRequestParams  = new Map<String,String>();
                    mapRequestParams.put('memberId', rem.Member_Id__c); 
                    
                    try {
                        ACG_GlobalSearchController.Results res = ACG_GlobalSearchController.invokeMembershipAPIs('lookup', mapRequestParams, '');

                        if (genMembershipFlag) {
                        rem.ACG_Member_Name__c = res.updatedRecordId;
                        lstRemToUpdate.add(rem);
                        genMembershipFlag = false;
                        }

                        if (res.updatedRecordId != null && res.updatedRecordId != rem.ACG_Member_Name__c) {
                            rem.ACG_Member_Name__c = res.updatedRecordId;
                            lstRemToUpdate.add(rem);
                        }
                    } catch (Exception e) {
                        System.debug('AAA_ReimbusementTriggerHandler.populateMemberInfo exception: '+e.getStackTraceString());
                    }
                }
            }
        }

        if (lstRemToUpdate != null && lstRemToUpdate.size() > 0) {
            update lstRemToUpdate;
        }
    }

    public static void populateDateReceived(List<ACG_Reimbursement__c > rmbList) {
        for (ACG_Reimbursement__c rmb : rmbList) {
            rmb.ACG_Date_Received__c = System.today();
        }
    }

    public static void validateAltAddress(List<ACG_Reimbursement__c > rmbList) {
        for (ACG_Reimbursement__c rmb : rmbList) {
            if (rmb.Use_Alternative_Address__c) {
                if (
                    String.isBlank(rmb.Alt_City__c)
                    || String.isBlank(rmb.Alt_First_Name__c)
                    || String.isBlank(rmb.Alt_Last_Name__c)
                    || String.isBlank(rmb.Alt_State__c)
                    || String.isBlank(rmb.Alt_Street_Address__c)
                    || String.isBlank(rmb.Alt_Zip__c)
                ) {
                    rmb.addError('Alternative Address information must be filled if "Use Alternative Address" is checked.');
                }
            } else {
                if (String.isBlank(rmb.Member_Id__c)) {
                    rmb.addError('Member must be associated with a Reimbursement if "Use Alternative Address" is unchecked.');
                }
            }
        }
    }
}