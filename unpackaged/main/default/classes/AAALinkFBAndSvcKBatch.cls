/**
* @description       : Links Feedback and Service Contract records to Inbound Reciprocals.
* @author            : joshtupas@salesforce.com
* @group             : 
* @last modified on  : 06-28-2024
* @last modified by  : Josh Tupas
* Modifications Log 
* Ver   Date         Author                               Modification
* 1.0   06-26-2024   joshtupas@salesforce.com
*       06-28-2024   joshtupas@salesforce.com             Added query condition for IB Reciprocals to query rows with "Is_Link_Batch_Processed__c = false". Added logic to flag IB Reciprocal if unable to connect it to Service Contract.
* 1.0   08/07/2024   vpopuru@aaanortheast.com			   Added a 4th condition: If first 3 conditions are failed, the Class with trigger MembersearchAPI and create Service Contract and Person account and tie it to reciprocal.
**/
//Vishnu
public class AAALinkFBAndSvcKBatch implements Database.Batchable<SObject>, Database.Stateful,Database.AllowsCallouts {
    public String query;
    private Set<Id> recIdSet;
    Set<Id> reciprocalsMap = new Set<Id>();
    
    public AAALinkFBAndSvcKBatch() {
        this.query = 
            'SELECT '+
            'Id,'+
            'Feedback__c,'+
            'Service_Contract__c,'+
            'CDX_Authorization_Code__c,'+
            'Member_ID__c,'+
            'Service_Call_Date__c,'+
            'Member_First_Name__c,'+
            'Is_Link_Batch_Processed__c'+
            ' FROM Reciprocal__c'+
            ' WHERE Record_Type_Developer_Name__c = \'Inbound_Payment_Requests\''+
            ' AND Transaction_Type__c != \'DSP\''+
            ' AND Is_Link_Batch_Processed__c = false'+
            ' AND ('+
            'Service_Contract__c = null'+
            ' OR Feedback__c = null'+
            ')';
    }
    
    public AAALinkFBAndSvcKBatch(Set<Id> recIdSet) {
        this.recIdSet = recIdSet;
    }
    
    public AAALinkFBAndSvcKBatch(String query) {
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> recIdSet = this.recIdSet;
        
        if (recIdSet != null && recIdSet.size() > 0) {
            return Database.getQueryLocator(
                [
                    SELECT
                    Id,
                    Feedback__c,
                    Service_Contract__c,
                    CDX_Authorization_Code__c,
                    Member_ID__c,
                    Service_Call_Date__c,
                    Member_First_Name__c,
                    Is_Link_Batch_Processed__c
                    FROM Reciprocal__c
                    WHERE Id IN :recIdSet
                    AND Record_Type_Developer_Name__c = 'Inbound_Payment_Requests'
                    AND Transaction_Type__c != 'DSP'
                    AND Is_Link_Batch_Processed__c = false
                    AND (
                        Service_Contract__c = null
                        OR Feedback__c = null
                    )
                ]
            ); 
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Reciprocal__c> scope) {
        List<Reciprocal__c> recUpdateList = new List<Reciprocal__c>();
        List<Reciprocal__c> recList2ndAttempt = new List<Reciprocal__c>();
        List<Reciprocal__c> recList3rdAttempt = new List<Reciprocal__c>();
        List<Reciprocal__c> recUpdatefailedList = new List<Reciprocal__c>();//Vishnu
        List<Feedback__c> fbList = new List<Feedback__c>();
        List<ServiceContract> svcKList = new List<ServiceContract>();
        List<ServiceContract> svcKResList = new List<ServiceContract>();
        Map<String, Reciprocal__c> recMap = new Map<String, Reciprocal__c>();
        Map<String, Feedback__c> fbMap = new Map<String, Feedback__c>();
        Set<String> authCodeSet = new Set<String>();
        Set<String> mbrIdSet = new Set<String>();
        
        try {
            for (Reciprocal__c rec : scope) {
                String authCode = rec.CDX_Authorization_Code__c;
                
                if (!String.isBlank(authCode)) {
                    authCodeSet.add(authCode);
                }
            }
            
            if (authCodeSet.size() > 0) {
                fbList = [
                    SELECT Id, Authorization_Code__c, Service_Contract__c 
                    FROM Feedback__c
                    WHERE Authorization_Code__c IN :authCodeSet
                    AND Type__c = 'Outgoing Authorization'
                ];
                
                for (Feedback__c fb : fbList) {
                    fbMap.put(fb.Authorization_Code__c, fb);
                }
            }
            
            // 1st attempt: associate FB with attached SvcK to IB Reciprocal
            if (fbList.size() > 0) {
                for (Reciprocal__c rec : scope) {
                    String authCode = rec.CDX_Authorization_Code__c;
                    Feedback__c fb = fbMap.get(authCode);
                    
                    rec.Is_Link_Batch_Processed__c = true;
                    
                    if (fb != null) {
                        String scId = fb.Service_Contract__c;
                        
                        rec.Feedback__c = fb.Id;
                        
                        if (scId != null) {
                            rec.Service_Contract__c = scId;
                            rec.Problem_Code__c = '';
                            recUpdateList.add(rec);
                        }
                    }
                    
                    // collect reciprocals for 2nd attempt
                    if (rec.Service_Contract__c == null) {
                        String mbrId = rec.Member_ID__c;
                        
                        if (!String.isBlank(mbrId)) {
                            mbrIdSet.add(mbrId);
                        }
                        
                        rec.Problem_Code__c = 'P8 - Invalid Membership Number';
                        recList2ndAttempt.add(rec);
                    }
                }
            }
            
            
            // 2nd attempt: match Service Contracts with 16-digit mbr Id from IB Reciprocal
            if (mbrIdSet.size() > 0) {
                Map<String, List<ServiceContract>> svcKMbrIdMap = new Map<String, List<ServiceContract>>();
                
                // Querying service contracts matching membership ID and filtering by service call date
                svcKList = [
                    SELECT 
                    Id, 
                    AAA_ACA_Membership16ID__c, 
                    AAA_ACA_Member_Status__c,
                    StartDate, 
                    EndDate,
                    Status
                    FROM ServiceContract
                    WHERE AAA_ACA_Membership16ID__c IN :mbrIdSet
                    AND AAA_ACA_Member_Status__c IN ('Cancelled', 'C', 'A', 'Active', 'Pending')
                    ORDER BY EndDate DESC
                ];
                
                if (svcKList.size() > 0) {
                    mbrIdSet = new Set<String>();
                    List<ServiceContract> svcKListTemp = new List<ServiceContract>();
                    svcKListTemp.addAll(svcKList);
                    svcKList.clear();
                    
                    for (ServiceContract sc : svcKListTemp) {
                        if (sc.AAA_ACA_Member_Status__c == 'Active') {
                            svcKList.add(sc);
                        }
                    }
                    
                    if (svcKList.isEmpty()) {
                        svcKList.addAll(svcKListTemp);
                    }
                    
                    for (ServiceContract sc : svcKList) {
                        List<ServiceContract> tempSCList;
                        String mbrId = sc.AAA_ACA_Membership16ID__c;
                        
                        if (svcKMbrIdMap.get(mbrId) == null) {
                            tempSCList = new List<ServiceContract>{sc};
                                } else {
                                    tempSCList = svcKMbrIdMap.get(mbrId);
                                    tempSCList.add(sc);
                                }
                        svcKMbrIdMap.put(mbrId, tempSCList);
                    }
                    
                    // Loop through Reciprocal records
                    for (Reciprocal__c rec : recList2ndAttempt) {
                        Date recSvcDate = rec.Service_Call_Date__c;
                        List<ServiceContract> tempSCList = svcKMbrIdMap.get(rec.Member_ID__c);
                        
                        rec.Is_Link_Batch_Processed__c = true;
                        
                        if (tempSCList != null) {
                            Boolean hasSvcK = false;
                            
                            for (ServiceContract sc : tempSCList) {
                                // Check if the Service_Call_Date__c falls within StartDate and EndDate
                                if (
                                    recSvcDate != null && 
                                    recSvcDate >= sc.StartDate && 
                                    recSvcDate <= sc.EndDate
                                ) {
                                    rec.Service_Contract__c = sc.Id;
                                    rec.Problem_Code__c = '';
                                    hasSvcK = true;
                                    
                                    // get an 'Active' SvcK and ignore the rest
                                    if (sc.Status == 'Active') {
                                        break;
                                    }
                                }
                            }
                            
                            recUpdateList.add(rec);
                        } else {
                            // collect reciprocals for last attempt
                            rec.Problem_Code__c = 'P8 - Invalid Membership Number';
                            mbrIdSet.add(rec.Member_ID__c);
                            recList3rdAttempt.add(rec);
                        }
                    }
                }
            }
            
            
            // last attempt: match on first name and partial mbr Id between Service Contract and IB Reciprocal
            if (svcKList.size() == 0 || recList3rdAttempt.size() > 0) {
                Map<String, List<ServiceContract>> svcKMap = new Map<String, List<ServiceContract>>();
                String mbrIdQuery = String.join(mbrIdSet, ' OR ');
                
                if (!String.isBlank(mbrIdQuery)) {
                    svcKResList = (List<ServiceContract>) [
                        FIND :mbrIdQuery
                        IN ALL FIELDS RETURNING ServiceContract(
                            Id, 
                            AAA_ACA_Membership16ID__c, 
                            AAA_ACA_MembershipID__c,
                            AAA_ACA_Member_Status__c,
                            Status,
                            StartDate,
                            EndDate,
                            Account.FirstName
                            WHERE AccountId != null
                            AND AAA_ACA_Member_Status__c IN ('Cancelled', 'C', 'A', 'Active', 'Pending') ORDER BY EndDate DESC
                        )
                    ][0];
                    
                    if (svcKResList.size() > 0) {
                        List<ServiceContract> svcKListTemp = new List<ServiceContract>();
                        svcKListTemp.addAll(svcKResList);
                        svcKResList.clear();
                        for (ServiceContract sc : svcKListTemp) {
                            if (sc.AAA_ACA_Member_Status__c == 'Active') {
                                svcKList.add(sc);
                            }
                        }
                        
                        if (svcKList.isEmpty()) {
                            svcKList.addAll(svcKListTemp);
                        }
                        
                        for (ServiceContract sc : svcKResList) {
                            List<ServiceContract> tempList;
                            String nameKey = sc.Account?.FirstName?.toUpperCase();
                            
                            if (nameKey != null) {
                                if (svcKMap.get(nameKey) == null) {
                                    tempList = new List<ServiceContract>{sc};
                                        } else {
                                            tempList = svcKMap.get(nameKey);
                                            tempList.add(sc);
                                        }
                                
                                svcKMap.put(nameKey, tempList);
                            }
                        }
                        
                        if (svcKList.size() == 0) {
                            recList3rdAttempt = recList2ndAttempt;
                        }
                        
                        for (Reciprocal__c rec : recList3rdAttempt) {
                            String nameKey = rec.Member_First_Name__c?.toUpperCase();
                            String recMbrId = rec.Member_ID__c;
                            Date recSvcDate = rec.Service_Call_Date__c;
                            
                            if (nameKey != null) {
                                List<ServiceContract> tempSCList = svcKMap.get(nameKey);
                                
                                if (tempSCList != null) {
                                    for (ServiceContract sc : tempSCList) {
                                        String scMbrId16 = sc.AAA_ACA_Membership16ID__c;
                                        String scMbrId = sc.AAA_ACA_MembershipID__c;
                                        Boolean validDate = recSvcDate >= sc.StartDate && recSvcDate <= sc.EndDate;
                                        Boolean hasPartialMatch = scMbrId16.contains(recMbrId)
                                            || scMbrId.contains(recMbrId)
                                            || recMbrId.contains(scMbrId16)
                                            || recMbrId.contains(scMbrId);
                                        
                                        if (validDate && hasPartialMatch) {
                                            rec.Service_Contract__c = sc.Id;
                                            rec.Problem_Code__c = '';
                                            
                                            // get an 'Active' SvcK and ignore the rest
                                            if (sc.Status == 'Active') {
                                                break;
                                            }
                                        }
                                    }
                                }
                                rec.Problem_Code__c = 'P8 - Invalid Membership Number';
                                rec.Is_Link_Batch_Processed__c = true;
                                recUpdateList.add(rec);
                            }
                        }
                    }
                }
            }
            //Vishnu
            List<INTMembershipLookupResponse_Wrapper> reslist = new List<INTMembershipLookupResponse_Wrapper>();
            Set<String> memberids = new Set<String>();
            List<Reciprocal__c> recupdatesvcklst = new List<Reciprocal__c>();
            List<Reciprocal__c> recupdatememberlst = new List<Reciprocal__c>();
            List<ServiceContract> svcKList1 = new List<ServiceContract>();
            List<Account> acclist1 = new List<Account>();
            if (fbList.size() == 0 && svcKList.size() == 0 && svcKResList.size() == 0) {
                
                for (Reciprocal__c rec : scope) {
                    rec.Problem_Code__c = 'P8 - Invalid Membership Number';
                    rec.Is_Link_Batch_Processed__c = true;
                    INTMembershipLookupResponse_Wrapper res = INTMembershipLookupAPI.getMemberlookup(rec.Member_Id__c);
                    memberids.add(rec.Member_Id__c);
                    reslist.add(res);
                    recUpdatefailedList.add(rec);
                }
            }
            if(!recUpdateList.isEmpty()){
                update recUpdateList;
            }
            if(!recUpdatefailedList.isEmpty()){            
                if(!reslist.isEmpty()){
                    for(Integer i=0;i<recUpdatefailedList.size();i++){
                        if(reslist[i].STATUS_CODE == 200){
                            ACG_GlobalSearchControllerHelper.performUpsertOnLookupRecord(recUpdatefailedList[i].Member_Id__c, reslist[i], '');
                        }
                    }
                    svcKList1 = [SELECT Id, AAA_ACA_Membership16ID__c, StartDate, EndDate,Status,AccountId, AAA_ACA_Member_Status__c
                                 FROM ServiceContract
                                 WHERE AAA_ACA_Membership16ID__c IN :memberids
                                 AND AAA_ACA_Member_Status__c IN ('Cancelled', 'C', 'A', 'Active', 'Pending')
                                 ORDER BY EndDate DESC
                                ];
                    acclist1 = [select id,Member_ID__c From Account where Member_ID__c IN:memberids];
                    if(!svcKList1.isEmpty()){
                        List<ServiceContract> svcKListTemp = new List<ServiceContract>();
                        svcKListTemp.addAll(svcKList1);
                        svcKList1.clear();
                        for (ServiceContract sc : svcKListTemp) {
                            if (sc.AAA_ACA_Member_Status__c == 'Active') {
                                svcKList1.add(sc);
                            }
                        }
                        
                        if (svcKList.isEmpty()) {
                            svcKList1.addAll(svcKListTemp);
                        }
                        
                        for(ServiceContract sc:svcKList1){
                            for(Reciprocal__c rec:recUpdatefailedList){
                                if(sc.AAA_ACA_Membership16ID__c == rec.Member_ID__c){
                                    rec.Service_Contract__c = sc.id;
                                    recupdatesvcklst.add(rec);
                                }
                            }
                        }
                    }
                    if(!acclist1.isEmpty()){
                        for(Account acc:acclist1){
                            for(Reciprocal__c rec:recUpdatefailedList){
                                if(acc.Member_ID__c == rec.Member_ID__c){
                                    rec.Member__c = acc.id;
                                    rec.Member_ID__c = acc.Member_ID__c;
                                    recupdatememberlst.add(rec);
                                }
                            }
                        }
                    }
                }
                Database.update(recUpdatefailedList,false); 
                if(recupdatesvcklst.isEmpty()){
                    Database.update(recupdatesvcklst,false);
                }
                if(recupdatememberlst.isEmpty()){
                    Database.Update(recupdatememberlst,false);
                }
            }
            
        } catch (Exception e) {
            String errMsg = e.getStackTraceString().substringAfter('\n') + '\n\n' + e.getMessage();
            
            /*insert new FSL_Application_Log__c(
Operation__c = 'AAALinkFBAndSvcKBatch',
Error_Message__c = errMsg
);*/
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // finish logic here
    }
}