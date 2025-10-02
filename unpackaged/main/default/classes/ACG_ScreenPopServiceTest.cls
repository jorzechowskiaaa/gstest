/*
* @Description: Test class for ACG_ScreenPopService class
* @Date: December 10, 202
* @Author: Deloitte USI
*/
@isTest
public class ACG_ScreenPopServiceTest {

    static Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
    static Id prsnAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
    static Id ersProfileid = [SELECT Id, Name FROM Profile Where Name = 'ERS Advocate'].Id;
    static string phone = '1234560000';

    
    @testSetup 
    static void testData() {

        ACG_ScreenPopServiceTest.createTestUser(ersProfileid, 'Test ERS Advocate', 'User', true);

    }

    /*
    @isTest
    public static void should_find_case_by_phone_number() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
    
            insert aCase;
            
            System.assert(ACG_ScreenPopController.getCaseId(null, phone) == aCase.Id, 'Expect to find case id');
        }
        
        Test.stopTest();       
    }
    */
        
        
    @isTest
    public static void should_find_two_related_cases() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            Phone = phone,
             ACG_AAA_Membership__c = '1234567890'
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            
            Case[] cases = new Case[] {
                new Case(
                    AccountId = account.Id,
                    ACG_Case_Contact_Number__c = '1234567890',
                    Status= 'In Progress',
                    RecordTypeId = caseRecordTypeId
                ),
                new Case(
                    AccountId = account.Id,
                    ACG_Case_Contact_Number__c = '1234567890',
                    Status= 'Closed',
                    RecordTypeId = caseRecordTypeId
                )
            };
    
            insert cases;

            string caseIdsStr = cases[0].Id + ',' + cases[1].Id;
            
            System.assert(ACG_ScreenPopController.getRelatedCases(cases[0].Id, ',') == caseIdsStr, 'Expect to find string with 2 cases');
        }
        
        Test.stopTest();
    }

    /*
    @isTest
    public static void should_find_case_by_case_id_ignoring_phonenumber() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
    
            insert aCase;
            
            System.assert(ACG_ScreenPopController.getCaseId(null, phone) == aCase.Id, 'Expect to find case id');
        }
        
        Test.stopTest();
    }
    */


    @isTest
    public static void should_return_null_for_not_found_case_service() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
    
            insert aCase;

            Id caseId = aCase.Id;

            delete aCase;

            System.assert(new ACG_ScreenPopService().searchCase(null, null) == null, 'Expect null result for not-found case');
        }
        
        Test.stopTest();
    }

    @isTest
    public static void should_return_a_single_case_when_search_by_member_number() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            ACG_AAA_Membership__c = '1234567890',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
    
            insert aCase;

            string[] caseIds = new ACG_ScreenPopService().searchCase('1234567890', null).split(',');
            System.assert(caseIds.size() == 1, 'Expect a single case');
        }
        
        Test.stopTest();
    }


    @isTest
    public static void should_return_multiple_cases() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase1 = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
            Case aCase2 = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );

            insert new Case[] {aCase1, aCase2};

            string caseIds = aCase1.Id + ',' + aCase2.Id;

            System.assert(ACG_ScreenPopService.getCasesHelper(caseIds, ',').size() == 2, 'Expect multiple cases');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void should_return_url(){
        
        Test.startTest();
        string url = ACG_ScreenPopController.getBaseURL();
        System.assert(url != null, 'Expect not null url');

        Test.stopTest();
        
    }

    @isTest
    public static void should_return_a_single_case_when_search_by_member_number_with_genesys() {

        Test.startTest();

        Account account = new Account(
            RecordTypeID = prsnAccountRecTypeId,
            FirstName = 'aaa',
            LastName = 'bbb',
            ACG_AAA_Membership__c = '1234567890',
            Phone = phone
        );

        insert account;

        User user = [SELECT Id, Name FROM User Where Name Like 'Test ERS Advocate User' AND ProfileId =:ersProfileid LIMIT 1];

        System.runAs(user){

            //NOTE: case must be created from same user
            Case aCase = new Case(
                AccountId = account.Id,
                Subject = 'CTI Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Genesys_ConversationId__c = '1234-5678',
                Status= 'In Progress',
                RecordTypeId = caseRecordTypeId
            );
    
            insert aCase;

            string[] caseIdsWithGenesys = new ACG_ScreenPopService().searchCaseAndGetGenesysId('1234567890', null);
            System.assert(caseIdsWithGenesys.size() == 2, 'Should return both caseId and GenesysId');
        }
        
        Test.stopTest();
    }

    private static User createTestUser(Id profileId, String firstName, String lastName, Boolean isInsert) {
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User rec = new User();
        rec.firstname = firstName;
        rec.lastName = lastName;
        rec.email = uniqueName +orgId +  '@aaacorp.local';
        rec.Username = uniqueName + '@test' + orgId + '.org';
        rec.EmailEncodingKey = 'ISO-8859-1';
        rec.Alias = uniqueName.substring(18, 23);
        rec.TimeZoneSidKey = 'America/Los_Angeles';
        rec.LocaleSidKey = 'en_US';
        rec.LanguageLocaleKey = 'en_US';
        rec.ProfileId = profileId;

        if(isInsert) {
            insert rec;
        }
        return rec;
    }
}