@IsTest
private class ACG_GetRelated_CaseHistoryRecordsTest {

    static Id ERS_CASE_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
    static Id ERS_ACCOUNT_RECORDID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ERS_Member').getRecordTypeId();
    
    @TestSetup
    static void setup() {
        // create account
        Account acct = new Account();
        acct.Name = 'TEST ERS ACCOUNT';
        acct.RecordTypeID = ERS_ACCOUNT_RECORDID;
        insert acct;
        
        // create cases 
		Case theCase = new Case();
        theCase.Subject = 'TEST CASE SUBJECT';
        theCase.AccountId = acct.Id;
        
    }
    
    @IsTest
    static void getRelatedCaseHistory_TEST() {
        
    }
    
}