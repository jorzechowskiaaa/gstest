public with sharing class ACG_GetRelated_CaseHistoryRecords {
    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCaseHistory(Id caseId,Integer Ndays)  {
        Id accountId= [SELECT AccountId FROM case WHERE Id=:caseId].AccountId;
        if(accountId == NULL) return NULL;
        
        Id ERS_RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Id household_RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        List<Id> lstHouseholdIds = new List<Id>();
        List<Id> lstContactIds = new List<Id>();
        List<Id> lstAccountIds = new List<Id>();
        //Fetch corresponding Households the Member(Person Accounts) belongs to.
        List<AccountContactRelation> lstHouseholdAccounts = [SELECT AccountId
                                                            FROM AccountContactRelation 
                                                            WHERE ContactId IN (SELECT PersonContactId
                                                                                FROM Account
                                                                                WHERE Id =: accountId) 
                                                            AND Account.RecordTypeId =: household_RecordTypeId 
                                                            LIMIT 10];

        for(AccountContactRelation objHousehold: lstHouseholdAccounts){
           
            lstHouseholdIds.add(objHousehold.AccountId);
        }           
        //Fetch corresponding Members(PersonAccount) that belong to these Households.                                               
        List<AccountContactRelation> lstContacts = [SELECT ContactId 
                                                    FROM AccountContactRelation 
                                                    WHERE AccountId = :lstHouseholdIds
                                                    LIMIT 10];
        
        for(AccountContactRelation objContact: lstContacts){
            
            lstContactIds.add(objContact.ContactId);
        }
        //Fetch the Ids of all the related Members(PersonAccounts)
        List<Account> lstAccounts = [SELECT Id FROM Account WHERE PersonContactId IN :lstContactIds LIMIT 10];
        for(Account objAccount: lstAccounts){
            
            lstAccountIds.add(objAccount.Id);
        }

        String strQuery = 'SELECT Id, CaseNumber, Status, CreatedDate, AccountId, Account.Name, ClosedDate'
                        +' FROM Case'
                        +' WHERE AccountId IN :lstAccountIds'
                        +' AND RecordTypeId = :ERS_RecordTypeId'
                        +' AND Id != :caseId'
                        +' AND (Isclosed=FALSE'
                        +' OR'
                        +' ClosedDate=LAST_N_DAYS:'+Ndays+')'
                        +' ORDER BY IsClosed, CreatedDate DESC'
                        +' LIMIT 50000';
        
        List<Case> lstCase = Database.query(strQuery);
      
       return lstCase;
    }
}