public class ACG_ScreenPopService {

    private static String caseRecordType = 'ACG_ERS';
    private static String[] caseStatuses = new string[] {'Spotted', 'In Progress', 'Work Order In Progress'};

    //NOTE: The reason why this method return a comma separated string of case ids is to make it easy for the softphone to pass it to the intake component via the URL
    public string searchCase(string memNum, string phoneNumber) {

        phoneNumber =  String.isNotBlank(phoneNumber) ? phoneNumber : '';
        memNum =  String.isNotBlank(memNum) ? memNum : '';

        if(String.isNotBlank(memNum)) {
            Case[] cases  = searchCaseByMemNum(memNum);
            if(cases?.size() > 0)
                return toCaseIdsString(cases);
        }

       // if(String.isNotBlank(phoneNumber)) {
       //     Case[] cases  = searchCaseByPhone(phoneNumber);
       //     if(cases?.size() > 0)
       //         return toCaseIdsString(cases);
       // }

        return null;
    }

    public List<string> searchCaseAndGetGenesysId(string memNum, string phoneNumber) {

        phoneNumber =  String.isNotBlank(phoneNumber) ? phoneNumber : '';
        memNum =  String.isNotBlank(memNum) ? memNum : '';
        List<string> response;

        if(String.isNotBlank(memNum)) {
            Case[] cases  = searchCaseByMemNum(memNum);
            if(cases?.size() > 0){
                response = new List<String>();
                response.add(toCaseIdsString(cases));
                response.add(toGenesysIdsString(cases));
            }
                return response;
        }

       // if(String.isNotBlank(phoneNumber)) {
       //     Case[] cases  = searchCaseByPhone(phoneNumber);
       //     if(cases?.size() > 0){
       //         response = new List<String>();
       //         response.add(toCaseIdsString(cases));
       //         response.add(toGenesysIdsString(cases));
       //     }
        //        return response;
       // }

        return null;
    }

    private static string toCaseIdsString(Case[] cases) {
        string caseIds = '';
        for(Case aCase : cases) {
            caseIds += aCase.Id + ',';
        }
        return caseIds.removeEnd(',');
    }

    private static string toGenesysIdsString(Case[] cases) {
        string genesysIds = '';
        for(Case aCase : cases) {
            if(String.isNotBlank(aCase.Genesys_ConversationId__c)){
                genesysIds += aCase.Genesys_ConversationId__c + ',';
            }else{
                genesysIds += '' + ',';
            }
        }
        return genesysIds.removeEnd(',');
    }


    public static Case[] searchCaseByMemNum(string memNum) {

        if(memNum.length() == 16) {
            memNum = memNum.substring(0, 15) + '%'; //Replace last char with wildcard
        }

        Case[] cases = [
            SELECT Id,Genesys_ConversationId__c FROM Case
            WHERE RecordType.DeveloperName =: caseRecordType
            AND ACG_AAA_Membership__c LIKE :memNum
            AND (Status IN :caseStatuses)
            ORDER BY CreatedDate DESC];
            
        return cases;
    }

    //public static Case[] searchCaseByPhone(string phoneNum) {
    //    Account[] accounts = [
    //        SELECT Id, ACG_AAA_Membership__c
    //        FROM Account
    //        WHERE Phone =:phoneNum
    //        AND isPersonAccount = true
    //        AND RecordType.DeveloperName = 'ACG_Member'
    //    ];

     //   Case[] cases = getCaseRecordByAccounts(accounts);
     //   return cases;

        // if(cases?.size() > 0)
        //  return cases;

        //This call can take a long time causing timeout so we don't use it
        // return apiSearchByPhone(phoneNum);
    //}

    public static Case[] getCaseRecordByAccounts(Account[] accounts) {

        Case[] cases = [
            SELECT Id,Genesys_ConversationId__c FROM Case
            WHERE RecordType.DeveloperName =: caseRecordType
            AND AccountId IN :accounts
            AND (Status IN :caseStatuses)
            ORDER BY CreatedDate DESC];
            
        return cases;
    }
    
    
    // public static Case[] apiSearchByPhone(string phoneNumber){
    //  Map<String, String> props = new Map<String, String> {
    //      'MSsearchByPhNumber_phnum'=> phoneNumber
    //  };
    //  ACG_GlobalSearchController.Results res = ACG_GlobalSearchController.invokeMembershipSearchAPI(props);
    //  ACG_GlobalSearchController.SearchResultsWrapper[] results = res?.searchResults;
    //  if(results?.size() == 1) {
    //      INTMembershipLookupResponse_Wrapper result = INTMembershipLookupAPI.getMemberlookup(results[0].MembershipNumber);
    //      if(result?.STATUS_CODE == 200) {
    //          string memNum = result?.customers?.customer[0]?.membershipId;
    //          return searchCaseByMemNum(memNum);
    //      }
    //  }

    //  return null;
    // }

    public static string getRelatedCases(string caseIdsStr, string delimiter) {
        Id[] caseIds = caseIdsStr.split(delimiter);

        Case[] cases = [
            SELECT
                Id,
                AccountId,
                ACG_Case_Contact_Number__c,
                ACG_AAA_Membership__c
                FROM Case
            WHERE Id IN : caseIds ORDER BY CreatedDate DESC
        ];

        Set<string> memNumbs = new Set<string>();
        Set<string> phoneNumbs = new Set<string>();
        Set<Id> accounts = new Set<Id>();

        for (Case aCase : cases) {
            if(aCase.ACG_AAA_Membership__c != null) {
                string memNum = aCase.ACG_AAA_Membership__c;
                if(memNum.length() == 16) {
                    memNum = memNum.substring(0, 15) + '%'; //Replace last char with wildcard
                }
                memNumbs.add(memNum);
            }
            if(aCase.ACG_Case_Contact_Number__c != null) {
                phoneNumbs.add(aCase.ACG_Case_Contact_Number__c);
            }
            if(aCase.AccountId != null) {
                accounts.add(aCase.AccountId);
            }
        }

        Case[] finaleCases = new Case[] {};

        cases = [
            SELECT Id FROM Case
            WHERE CreatedDate = LAST_N_DAYS:2
            AND RecordType.DeveloperName = :caseRecordType
            AND Status IN :caseStatuses
            AND (ACG_AAA_Membership__c LIKE :memNumbs OR ACG_Case_Contact_Number__c IN :phoneNumbs OR AccountId IN :accounts)
            ORDER BY CreatedDate DESC];

        finaleCases.addAll(cases);

        cases = [
            SELECT Id FROM Case
            WHERE CreatedDate = LAST_N_DAYS:2
            AND RecordType.DeveloperName = :caseRecordType
            AND Status NOT IN :caseStatuses
            AND (ACG_AAA_Membership__c LIKE :memNumbs OR ACG_Case_Contact_Number__c IN :phoneNumbs OR AccountId IN :accounts)
            ORDER BY CreatedDate DESC];

        finaleCases.addAll(cases);

        return toCaseIdsString(finaleCases);
    }

    @AuraEnabled
    public static Case[] getCasesHelper(string caseIdsStr, string delimiter) {
        try {
            Id[] caseIds = caseIdsStr.split(delimiter);

            return [
                SELECT
                    ID,
                    CaseNumber,
                    format(CreatedDate) FormatedCreatedDate,
                    Member_Account_Name__c,
                    ACG_Case_Contact_Number__c,
                    Account.Phone,
                    ACG_AAA_Membership__c,
                    Breakdown_Address__c,
                    Status 
                FROM Case
                WHERE Id IN : caseIds ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}