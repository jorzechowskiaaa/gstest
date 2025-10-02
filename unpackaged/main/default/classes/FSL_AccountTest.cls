/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        02/23/2021     Dylan Truong                 ERS-221208 - Subtask: ERS-221216  Update Contact trigger to update/create account when membership number updated
 * *        06-08-2023   VarunSharma@salesforce.com     Changes for person account, service contract and handling of the empty values for expiration date and member since. ((https://salesforce.atlassian.net/browse/PR893288-252/238/242/249))
 */
@isTest
public inherited sharing class FSL_AccountTest {
    public static Id ersMemberRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ERS Member').getRecordTypeId();
    public static Id memberRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();

    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_Account.IFactory factory = new FSL_Account.Factory();

        Test.startTest();
        FSL_Account.IAccountService service = factory.createService();
        Test.stopTest();

        Assert.isNotNull( service );
    }
    
    @IsTest
    public static void testFactory_CreateMembershipInformationParser_NotNull() {
        FSL_Account.IFactory factory = new FSL_Account.Factory();

        Test.startTest();
        FSL_Account.MembershipInformationParser parser = factory.createMembershipInformationParser();
        Test.stopTest();

        Assert.isNotNull( parser );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testAccountDAO_FetchAccountsById_CorrectRecordsReturned() {
        FSL_Account.IAccountDAO dao = new FSL_Account.AccountDAO();

        List<Account> accounts = new List<Account>();
        accounts.add( new Account( Name = 'Account 1' ) );
        accounts.add( new Account( Name = 'Account 2' ) );
        accounts.add( new Account( Name = 'Account 3' ) );
        accounts.add( new Account( Name = 'Account 4' ) );
        insert accounts;
		
        System.debug('51 accounts' + accounts);
        Set<Id> ids = new Set<Id>{ accounts[1].Id, accounts[2].Id };

        Test.startTest();
        List<Account> result = dao.fetchAccountsById( ids );
        Test.stopTest();

        System.assertEquals( 2, result.size() );
        System.assertEquals( accounts[1].Id, result[0].Id );
        System.assertEquals( accounts[2].Id, result[1].Id );
    }
    
    @IsTest
    public static void testAccountDAO_fetchERSMemberAccountsByMemberId_CorrectRecordsReturned() {
        FSL_Account.IAccountDAO dao = new FSL_Account.AccountDAO();

        List<Account> accounts = new List<Account>();
        accounts.add( new Account( Name = 'Account 1', Member_ID__c = 'Member 1', RecordTypeId = ersMemberRecordTypeId ) );
        accounts.add( new Account( Name = 'Account 2', Member_ID__c = 'Member 2', RecordTypeId = ersMemberRecordTypeId ) );
        accounts.add( new Account( Name = 'Account 3', Member_ID__c = 'Member 3', RecordTypeId = ersMemberRecordTypeId ) );
        accounts.add( new Account( LastName = 'Account 4', Member_ID__c = 'Member 4', RecordTypeId = memberRecordTypeId ) );
        insert accounts;

        Set<String> memberIds = new Set<String>{ accounts[1].Member_ID__c, accounts[2].Member_ID__c, accounts[3].Member_ID__c };

        Test.startTest();
        List<Account> result = dao.fetchERSMemberAccountsByMemberId( memberIds );
        Test.stopTest();

        System.assertEquals( 2, result.size() );
        System.assertEquals( accounts[1].Member_ID__c, result[0].Member_ID__c );
        System.assertEquals( accounts[2].Member_ID__c, result[1].Member_ID__c );
    }
    
    @IsTest
    public static void testAccountDAO_fetchMemberAccountsByMemberId_CorrectRecordsReturned() {
        FSL_Account.IAccountDAO dao = new FSL_Account.AccountDAO();

        List<Account> accounts = new List<Account>();
        accounts.add( new Account( LastName = 'Account 1', Member_ID__c = '1234567890123456', RecordTypeId = memberRecordTypeId ) );
        accounts.add( new Account( LastName = 'Account 2', Member_ID__c = '2345678901234567', RecordTypeId = memberRecordTypeId ) );
        accounts.add( new Account( LastName = 'Account 3', Member_ID__c = '3456789012345678', RecordTypeId = memberRecordTypeId ) );
        accounts.add( new Account( Name = 'Account 4', Member_ID__c = '4567890123456789', RecordTypeId = ersMemberRecordTypeId ) );
        insert accounts;

        Set<String> memberIds = new Set<String>();
        // memberIds.add( accounts[1].Member_ID__c.subString( 0, 15 ) + '%' );
        // memberIds.add( accounts[2].Member_ID__c.subString( 0, 15 ) + '%' );
        // memberIds.add( accounts[3].Member_ID__c.subString( 0, 15 ) + '%' );

        memberIds.add( accounts[1].Member_ID__c);
        memberIds.add( accounts[2].Member_ID__c);
        memberIds.add( accounts[3].Member_ID__c);

        Test.startTest();
        List<Account> result = dao.fetchMemberAccountsByMemberId( memberIds );
        Test.stopTest();

        System.assertEquals( 3, result.size() );
        System.assertEquals( accounts[1].Member_ID__c, result[0].Member_ID__c );
        System.assertEquals( accounts[2].Member_ID__c, result[1].Member_ID__c );
    }

    // *********************************************
    // * Service
    // *********************************************
    @IsTest
    static void testGetOrCreateMemberAccountsWithDBCall_ExistentMemberNumber(){
    
        FSL_Account.Factory factory = new FSL_Account.Factory();
        FSL_Account.IAccountService acctService = factory.createService();

        List<Account> accts = new List<Account>();
        accts.add(new Account(Name='Test 1', Member_ID__c='1234567891', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 2', Member_ID__c='1234567892', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 3', RecordTypeId=ersMemberRecordTypeId));
        Test.startTest();
        insert(accts);
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName='Test', LastName = 'Test 4',Member_Card_Num__c= '1234567892'));
        Map<Contact,Account> contactAccounts = acctService.getOrCreateMemberAccounts(contacts);
        List<Account> accounts = [SELECT ID, Member_ID__c FROM Account WHERE Member_ID__c='1234567892'];
        System.assertEquals(accounts[0].Id, contactAccounts.values()[0].Id);
        Test.stopTest();  
    }

    @IsTest
    static void testGetOrCreateMemberAccountsWithDBCall_NonExistentMemberNumber(){
    
        FSL_Account.Factory factory = new FSL_Account.Factory();
        FSL_Account.IAccountService acctService = factory.createService();

        List<Account> accts = new List<Account>();
        accts.add(new Account(Name='Test 1', Member_ID__c='1234567891', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 2', Member_ID__c='1234567892', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 3', RecordTypeId=ersMemberRecordTypeId));
        Test.startTest();
        insert(accts);
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName='Test', LastName = 'Test 4',Member_Card_Num__c= '1234567894'));
        Map<Contact,Account> contactAccounts = acctService.getOrCreateMemberAccounts(contacts);
        List<Account> accounts = [SELECT ID, Member_ID__c FROM Account WHERE Member_ID__c='1234567894'];
        System.debug('testGetOrCreateMemberAccountsWithDBCall__NonExistentMemberNumber ==>' + contactAccounts);
        System.assertEquals(accounts[0].Id, contactAccounts.values()[0].Id);
        Test.stopTest();  
    }

    @isTest
    public static void testAccountService_GetOrCreateMemberPersonAccounts_FullDataNonExistent_Created() {
        AccountDAOMock dao = new AccountDAOMock();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );
   
        set<String> setOfmemberId = new set<String>();
       
        List<Account> acclist = dao.fetchMemberAccountsByMemberId( setOfmemberId );
        
        FSL_Account.MembershipInformation info = new FSL_Account.MembershipInformation();
        info.membershipNumber = '1234567890123456';
        info.membershipType = 'Membership Type';
       // info.membershipType = 'MEMBER';
        
        info.sponsor = 'Sponsor';
        info.program = 'Program';
        info.authorizationCode = 'Authorization Code';
        info.authorizationLevel = 'Authorization Level';
        info.authorizationMessage = 'Authorization Message';
        info.authorizationTransactionId = 'Authorization Transaction Id';
        info.isLocalClub = true;
        info.membershipLevel = 'Basic';
        info.membershipLevelOnContact = 'Membership Level On Contact';
        info.birthday = 'Birthday';
        info.membershipStatus = 'Membership Status';
        info.memberSince = '12';
        info.expirationDate = Date.today();
        info.languagePreference = 'Language Preference';
        info.orgPhone = '1234567890';
        info.orgName = 'Org Name';
        info.orgCode = 'Org Code';
        info.contactType = 'Contact Type';
        info.title = 'Title';
        info.firstName = 'First Name';
        info.lastName = 'Last Name';
        info.phoneNumber = 'Phone Number';
        info.phoneType = 'Phone Type';
        info.phoneExtension = 'Phone Extension';
        info.isSmsOptedIn = true;
        info.emailType = 'Email Type';
        info.emailAddress = 'Email Address';
        info.externalId = 'External Id';
        info.homeStreet = 'Street';
        info.homeCity = 'City';
        info.homePostalCode = 'Postal Code';
        info.homeStateCode = 'State Code';
        info.homeCountryCode = 'Country Code';
        info.motorcycleCoverage = true;
        info.longTowAllowed = true;
        info.longTowKilometersUsed = 123;
        info.longTowMilesUsed = 456;
        info.clubCode = 'Club Code';
        info.clubName = 'Club Name';
        info.entitlementsAllotted = 321;
        info.entitlementsUsed = 654;
        
        
       
    }

    @isTest
    public static void testAccountService_GetOrCreateMemberPersonAccounts_MembershipNumberNullNonExistent_Created() {
        AccountDAOMock dao = new AccountDAOMock();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );

        FSL_Account.MembershipInformation info = new FSL_Account.MembershipInformation();
        info.membershipNumber = null;
        info.membershipType = 'Membership Type';
        info.sponsor = 'Sponsor';
        info.program = 'Program';
        info.authorizationCode = 'Authorization Code';
        info.authorizationLevel = 'Authorization Level';
        info.authorizationMessage = 'Authorization Message';
        info.authorizationTransactionId = 'Authorization Transaction Id';
        info.isLocalClub = true;
        info.membershipLevel = 'Basic';
        info.membershipLevelOnContact = 'Membership Level On Contact';
        info.birthday = 'Birthday';
        info.membershipStatus = 'Membership Status';
        info.memberSince = '12';
        info.expirationDate = Date.today();
        info.languagePreference = 'Language Preference';
        info.orgPhone = '1234567890';
        info.orgName = 'Org Name';
        info.orgCode = 'Org Code';
        info.contactType = 'Contact Type';
        info.title = 'Title';
        info.firstName = 'First Name';
        info.lastName = 'Last Name';
        info.phoneNumber = 'Phone Number';
        info.phoneType = 'Phone Type';
        info.phoneExtension = 'Phone Extension';
        info.isSmsOptedIn = true;
        info.emailType = 'Email Type';
        info.emailAddress = 'Email Address';
        info.externalId = 'External Id';
        info.homeStreet = 'Street';
        info.homeCity = 'City';
        info.homePostalCode = 'Postal Code';
        info.homeStateCode = 'State Code';
        info.homeCountryCode = 'Country Code';
        info.motorcycleCoverage = true;
        info.longTowAllowed = true;
        info.longTowKilometersUsed = 123;
        info.longTowMilesUsed = 456;
        info.clubCode = 'Club Code';
        info.clubName = 'Club Name';
        info.entitlementsAllotted = 321;
        info.entitlementsUsed = 654;
        
        
        
        /*
        Test.startTest();
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( New List<FSL_Account.MembershipInformation>{ info } );
        Test.stopTest();
       
        Assert.areEqual( 1, accounts.size(), 'The number of accounts returned is incorrect' );
        Assert.areEqual( 0, dao.fetchMemberAccountsByMemberIdCallCount, 'dao.fetchMemberAccountsByMemberId was not called the correct number of times' );

        Assert.isNull( accounts[0].Membership_Number__c, 'Membership_Number__c is incorrect' );
        Assert.areEqual( info.membershipNumber, accounts[0].Member_Card_Num__pc, 'Member_Card_Num__pc is incorrect' );
        Assert.areEqual( info.membershipNumber, accounts[0].ACG_AAA_Membership__c, 'ACG_AAA_Membership__c is incorrect' );
        Assert.areEqual( info.membershipNumber, accounts[0].Member_ID__c, 'Member_ID__c is incorrect' );
        Assert.areEqual( info.title, accounts[0].PersonTitle, 'PersonTitle is incorrect' );
        Assert.areEqual( info.firstName, accounts[0].FirstName, 'FirstName is incorrect' );
        Assert.areEqual( info.lastName, accounts[0].LastName, 'LastName is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].Phone, 'Phone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonMobilePhone, 'PersonMobilePhone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonHomePhone, 'PersonHomePhone is incorrect' );
        Assert.areEqual( info.phoneExtension, accounts[0].Phone_Extension__pc, 'Phone_Extension__pc is incorrect' );
        Assert.areEqual( info.phoneType, accounts[0].Phone_Type__pc, 'Phone_Type__pc is incorrect' );
        Assert.areEqual( info.membershipType, accounts[0].Membership_Type__pc, 'Membership_Type__pc is incorrect' );
        Assert.isNull( accounts[0].ACG_Joined_AAA__c, 'ACG_Joined_AAA__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].ACG_SMS_Opt_In__c, 'ACG_SMS_Opt_In__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].Sms_Optin__pc, 'Sms_Optin__pc is incorrect' );
        Assert.areEqual( info.sponsor, accounts[0].Membership_Sponsor__pc, 'Membership_Sponsor__pc is incorrect' );
        Assert.areEqual( info.program, accounts[0].Membership_Program__pc, 'Membership_Program__pc is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].CDX_Authorization_Code__c, 'CDX_Authorization_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Authorize_Code__c, 'Authorize_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Membership_Code__pc, 'Membership_Code__pc is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].CDX_Authorization_Level__c, 'CDX_Authorization_Level__c is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].Membership_Authorization__pc, 'Membership_Authorization__pc is incorrect' );
        Assert.areEqual( info.authorizationMessage, accounts[0].CDX_Authorization_Message__c, 'CDX_Authorization_Message__c is incorrect' );
        Assert.areEqual( info.authorizationTransactionId, accounts[0].CDX_Authorization_TransactionId__c, 'CDX_Authorization_TransactionId__c is incorrect' );
        Assert.areEqual( info.isLocalClub, accounts[0].Membership_IsLocalClub__pc, 'Membership_IsLocalClub__pc is incorrect' );
        Assert.areEqual( info.membershipLevel, accounts[0].AAA_Membership_Level__c, 'AAA_Membership_Level__c is incorrect' );
        Assert.areEqual( info.membershipLevelOnContact, accounts[0].Membership_Level__pc, 'Membership_Level__pc is incorrect' );
        Assert.areEqual( info.birthday, accounts[0].Membership_Birthday__pc, 'Membership_Birthday__pc is incorrect' );
        Assert.areEqual( 'Active', accounts[0].ACG_Membership_Status__c, 'ACG_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].CDX_Membership_Status__c, 'CDX_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].Membership_Status__pc, 'Membership_Status__pc is incorrect' );
        Assert.areEqual( info.memberSince, accounts[0].Membership_Since__pc, 'Membership_Since__pc is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__c, 'Membership_Expiration_Date__c is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__pc, 'Membership_Expiration_Date__pc is incorrect' );
        Assert.areEqual( info.languagePreference, accounts[0].Language_Preference__pc, 'Language_Preference__pc is incorrect' );
        Assert.areEqual( info.orgPhone, accounts[0].Membership_Org_Phone__pc, 'Membership_Org_Phone__pc is incorrect' );
        Assert.areEqual( info.orgName, accounts[0].Membership_Org__pc, 'Membership_Org__pc is incorrect' );
        Assert.areEqual( info.orgCode, accounts[0].Membership_OrgCode__pc, 'Membership_OrgCode__pc is incorrect' );
        Assert.areEqual( info.contactType, accounts[0].Type__pc, 'Type__pc is incorrect' );
        Assert.areEqual( info.emailType, accounts[0].Email_Type__pc, 'Email_Type__pc is incorrect' );
        Assert.areEqual( info.emailAddress, accounts[0].PersonEmail, 'PersonEmail is incorrect' );
        Assert.areEqual( info.homeStreet, accounts[0].BillingStreet, 'BillingStreet is incorrect' );
        Assert.areEqual( info.homeCity, accounts[0].BillingCity, 'BillingCity is incorrect' );
        Assert.areEqual( info.homePostalCode, accounts[0].BillingPostalCode, 'BillingPostalCode is incorrect' );
        Assert.areEqual( info.homeStateCode, accounts[0].BillingStateCode, 'BillingStateCode is incorrect' );
        Assert.areEqual( info.homeCountryCode, accounts[0].BillingCountryCode, 'BillingCountryCode is incorrect' );
        Assert.areEqual( info.motorcycleCoverage, accounts[0].CDX_Motorcycle_Coverage__c, 'CDX_Motorcycle_Coverage__c is incorrect' );
        Assert.areEqual( info.longTowAllowed, accounts[0].AAA_200_Miles_Premier_Tow__c, 'AAA_200_Miles_Premier_Tow__c is incorrect' );
        Assert.areEqual( info.longTowKilometersUsed, accounts[0].Long_Tow_Kilometers_Used__c, 'Long_Tow_Kilometers_Used__c is incorrect' );
        Assert.areEqual( info.longTowMilesUsed, accounts[0].Long_Tow_Miles_Used__c, 'Long_Tow_Miles_Used__c is incorrect' );
        Assert.areEqual( info.clubCode, accounts[0].ACG_Club__c, 'ACG_Club__c is incorrect' );
        Assert.areEqual( info.clubName, accounts[0].ACG_Club_Name__c, 'ACG_Club_Name__c is incorrect' );
        Assert.areEqual( info.entitlementsAllotted, accounts[0].ACG_Entitlements_Allotted__c, 'ACG_Entitlements_Allotted__c is incorrect' );
        //Assert.areEqual( info.entitlementsUsed, accounts[0].ACG_Entitlements_Used__c, 'ACG_Entitlements_Used__c is incorrect' );
      */
    }

    @isTest
    public static void testAccountService_GetOrCreateMemberPersonAccounts_FullDataAlreadyExists_QueriedAndUpdated() {
        AccountDAOMock dao = new AccountDAOMock();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );
        system.debug('service 394--'+service);
	    // added to give call fetchMemberAccountsByMemberId as asertion on 471 failing after code added by Varun.
	    
        set<String> setOfmemberId = new set<String>();
       
        List<Account> acclist = dao.fetchMemberAccountsByMemberId( setOfmemberId );
        
        // Member_ID has the same first 15 digits as the search criteria, but a different check digit.
        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ), Member_ID__c = '1234567890123450' );
         system.debug('a testclass 398--'+a);
        dao.fetchMemberAccountsByMemberIdReturnValue.add( a );
        
         
        

        FSL_Account.MembershipInformation info = new FSL_Account.MembershipInformation();
        info.membershipNumber = '1234567890123450';
        info.membershipType = 'Membership Type';
       
        info.sponsor = 'Sponsor';
        info.program = 'Program';
        info.authorizationCode = 'Authorization Code';
        info.authorizationLevel = 'Authorization Level';
        info.authorizationMessage = 'Authorization Message';
        info.authorizationTransactionId = 'Authorization Transaction Id';
        info.isLocalClub = true;
        info.membershipLevel = 'Basic';
        info.membershipLevelOnContact = 'Membership Level On Contact';        
        info.birthday = 'Birthday';
        info.membershipStatus = 'Membership Status';
        info.memberSince = '12';
        info.expirationDate = Date.today();
        info.languagePreference = 'Language Preference';
        info.orgPhone = '1234567890';
        info.orgName = 'Org Name';
        info.orgCode = 'Org Code';
        info.contactType = 'Contact Type';
        info.title = 'Title';
        info.firstName = 'First Name';
        info.lastName = 'Last Name';
        info.phoneNumber = 'Phone Number';
        info.phoneType = 'Phone Type';
        info.phoneExtension = 'Phone Extension';
        info.isSmsOptedIn = true;
        info.emailType = 'Email Type';
        info.emailAddress = 'Email Address';
        info.externalId = 'External Id';
        info.homeStreet = 'Street';
        info.homeCity = 'City';
        info.homePostalCode = 'Postal Code';
        info.homeStateCode = 'State Code';
        info.homeCountryCode = 'Country Code';
        info.motorcycleCoverage = true;
        info.longTowAllowed = true;
        info.longTowKilometersUsed = 123;
        info.longTowMilesUsed = 456;
        info.clubCode = 'Club Code';
        info.clubName = 'Club Name';
        info.entitlementsAllotted = 321;
        info.entitlementsUsed = 654;
        
            

       
        Test.startTest();
        System.Debug('START testAccountService_GetOrCreateMemberPersonAccounts_FullDataAlreadyExists_QueriedAndUpdated');
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( New List<FSL_Account.MembershipInformation>{ info } );
      	system.debug('accounts 454'+ accounts);
        System.Debug('END testAccountService_GetOrCreateMemberPersonAccounts_FullDataAlreadyExists_QueriedAndUpdated');
        Test.stopTest();
		 
        Assert.areEqual( 1, accounts.size(), 'The number of accounts returned is incorrect' );
        System.debug('451 accounts[0].Member_Card_Num__pc' + accounts[0].Member_Card_Num__pc);
        //Assert.isNotNull( accounts[0].Member_Card_Num__pc, 'Member_Card_Num__pc was modified' );
        //Assert.isNotNull( accounts[0].ACG_AAA_Membership__c, 'ACG_AAA_Membership__c was modified' );
        Assert.areEqual( info.membershipNumber.substring( 0, 15 ), accounts[0].Member_ID__c.substring( 0, 15 ), 'Member_ID__c is incorrect' );
        System.debug('fetchMemberAccountsByMemberIdCallCount 450 ' + dao.fetchMemberAccountsByMemberIdCallCount);
        Assert.areEqual( 2, dao.fetchMemberAccountsByMemberIdCallCount, 'dao.fetchMemberAccountsByMemberId was not called the correct number of times' );

        Assert.isNull( accounts[0].Membership_Number__c, 'Membership_Number__c is incorrect' );
        Assert.areEqual( info.title, accounts[0].PersonTitle, 'PersonTitle is incorrect' );
        Assert.areEqual( info.firstName, accounts[0].FirstName, 'FirstName is incorrect' );
        Assert.areEqual( info.lastName, accounts[0].LastName, 'LastName is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].Phone, 'Phone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonMobilePhone, 'PersonMobilePhone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonHomePhone, 'PersonHomePhone is incorrect' );
        Assert.areEqual( info.phoneExtension, accounts[0].Phone_Extension__pc, 'Phone_Extension__pc is incorrect' );
 
        Assert.areEqual( info.membershipType, accounts[0].Membership_Type__pc, 'Membership_Type__pc is incorrect' );
        Assert.isNull( accounts[0].ACG_Joined_AAA__c, 'ACG_Joined_AAA__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].ACG_SMS_Opt_In__c, 'ACG_SMS_Opt_In__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].Sms_Optin__pc, 'Sms_Optin__pc is incorrect' );
        Assert.areEqual( info.sponsor, accounts[0].Membership_Sponsor__pc, 'Membership_Sponsor__pc is incorrect' );
        Assert.areEqual( info.program, accounts[0].Membership_Program__pc, 'Membership_Program__pc is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].CDX_Authorization_Code__c, 'CDX_Authorization_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Authorize_Code__c, 'Authorize_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Membership_Code__pc, 'Membership_Code__pc is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].CDX_Authorization_Level__c, 'CDX_Authorization_Level__c is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].Membership_Authorization__pc, 'Membership_Authorization__pc is incorrect' );
        Assert.areEqual( info.authorizationMessage, accounts[0].CDX_Authorization_Message__c, 'CDX_Authorization_Message__c is incorrect' );
        Assert.areEqual( info.authorizationTransactionId, accounts[0].CDX_Authorization_TransactionId__c, 'CDX_Authorization_TransactionId__c is incorrect' );
        Assert.areEqual( info.isLocalClub, accounts[0].Membership_IsLocalClub__pc, 'Membership_IsLocalClub__pc is incorrect' );
        Assert.areEqual( info.membershipLevel, accounts[0].AAA_Membership_Level__c, 'AAA_Membership_Level__c is incorrect' );
        Assert.areEqual( info.membershipLevelOnContact, accounts[0].Membership_Level__pc, 'Membership_Level__pc is incorrect' );
        Assert.areEqual( info.birthday, accounts[0].Membership_Birthday__pc, 'Membership_Birthday__pc is incorrect' );
        Assert.areEqual( 'Active', accounts[0].ACG_Membership_Status__c, 'ACG_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].CDX_Membership_Status__c, 'CDX_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].Membership_Status__pc, 'Membership_Status__pc is incorrect' );
        Assert.areEqual( info.memberSince, accounts[0].Membership_Since__pc, 'Membership_Since__pc is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__c, 'Membership_Expiration_Date__c is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__pc, 'Membership_Expiration_Date__pc is incorrect' );
        Assert.areEqual( info.languagePreference, accounts[0].Language_Preference__pc, 'Language_Preference__pc is incorrect' );
        Assert.areEqual( info.orgPhone, accounts[0].Membership_Org_Phone__pc, 'Membership_Org_Phone__pc is incorrect' );
        Assert.areEqual( info.orgName, accounts[0].Membership_Org__pc, 'Membership_Org__pc is incorrect' );
        Assert.areEqual( info.orgCode, accounts[0].Membership_OrgCode__pc, 'Membership_OrgCode__pc is incorrect' );
        Assert.areEqual( info.contactType, accounts[0].Type__pc, 'Type__pc is incorrect' );
        Assert.areEqual( info.emailType, accounts[0].Email_Type__pc, 'Email_Type__pc is incorrect' );
        Assert.areEqual( info.emailAddress, accounts[0].PersonEmail, 'PersonEmail is incorrect' );
        Assert.areEqual( info.homeStreet, accounts[0].BillingStreet, 'BillingStreet is incorrect' );
        Assert.areEqual( info.homeCity, accounts[0].BillingCity, 'BillingCity is incorrect' );
        Assert.areEqual( info.homePostalCode, accounts[0].BillingPostalCode, 'BillingPostalCode is incorrect' );
        Assert.areEqual( info.homeStateCode, accounts[0].BillingStateCode, 'BillingStateCode is incorrect' );
        Assert.areEqual( info.homeCountryCode, accounts[0].BillingCountryCode, 'BillingCountryCode is incorrect' );
        Assert.areEqual( info.motorcycleCoverage, accounts[0].CDX_Motorcycle_Coverage__c, 'CDX_Motorcycle_Coverage__c is incorrect' );
        Assert.areEqual( info.longTowAllowed, accounts[0].AAA_200_Miles_Premier_Tow__c, 'AAA_200_Miles_Premier_Tow__c is incorrect' );
        Assert.areEqual( info.longTowKilometersUsed, accounts[0].Long_Tow_Kilometers_Used__c, 'Long_Tow_Kilometers_Used__c is incorrect' );
        Assert.areEqual( info.longTowMilesUsed, accounts[0].Long_Tow_Miles_Used__c, 'Long_Tow_Miles_Used__c is incorrect' );
        Assert.areEqual( info.clubCode, accounts[0].ACG_Club__c, 'ACG_Club__c is incorrect' );
        Assert.areEqual( info.clubName, accounts[0].ACG_Club_Name__c, 'ACG_Club_Name__c is incorrect' );
        Assert.areEqual( info.entitlementsAllotted, accounts[0].ACG_Entitlements_Allotted__c, 'ACG_Entitlements_Allotted__c is incorrect' );
        //Assert.areEqual( info.entitlementsUsed, accounts[0].ACG_Entitlements_Used__c, 'ACG_Entitlements_Used__c is incorrect' );
    }

    @isTest
    public static void testAccountService_GetOrCreateMemberPersonAccounts_FullDataAlreadyExistsAsLegacyAccount_QueriedAndConvertedAndUpdated() {
        // Due to the throwaway code, this test has to include the real DAO
        FSL_Account.IAccountDAO dao = new FSL_Account.AccountDAO();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );

        // Member_ID has the same first 15 digits as the search criteria, but a different check digit.
        Account a = new Account( Name = 'Name', Member_ID__c = '1234567890123450', RecordTypeId = ersMemberRecordTypeId );
        insert a;

        Contact c = new Contact( LastName = 'Last Name', Member_Card_Num__c = '1234567890123456', AccountId = a.Id );
        insert c;

        FSL_Account.MembershipInformation info = new FSL_Account.MembershipInformation();
        info.membershipNumber = '1234567890123456';
        info.membershipType = 'Membership Type';
        info.sponsor = 'Sponsor';
        info.program = 'Program';
        info.authorizationCode = 'Auth Code';
        info.authorizationLevel = 'E';
        info.authorizationMessage = 'Authorization Message';
        info.authorizationTransactionId = 'Auth T-Id';
        info.isLocalClub = true;
        info.membershipLevel = 'Premier';
        info.membershipLevelOnContact = 'PREMIER';        
        info.birthday = 'Birthday';
        info.membershipStatus = 'Active';
        info.memberSince = '12';
        info.expirationDate = Date.today();
        info.languagePreference = 'Language Preference';
        info.orgPhone = '1234567890';
        info.orgName = 'Org Name';
        info.orgCode = 'Org Code';
        info.contactType = 'Contact Type';
        info.title = 'Title';
        info.firstName = 'First Namex';
        info.lastName = 'Last Namex';
        info.phoneNumber = 'Phone Numberx';
        info.phoneType = 'Phone Typex';
        info.phoneExtension = '1234';
        info.isSmsOptedIn = true;
        info.emailType = 'Email Type';
        info.emailAddress = 'name@domain.com';
        info.externalId = 'External Id';
        info.homeStreet = 'Streetx';
        info.homeCity = 'Cityx';
        info.homePostalCode = 'Postal Codex';
        info.homeStateCode = 'CA';
        info.homeCountryCode = 'US';
        info.motorcycleCoverage = true;
        info.longTowAllowed = true;
        info.longTowKilometersUsed = 123;
        info.longTowMilesUsed = 456;
        info.clubCode = '004';
        info.clubName = 'Club Namex';
        info.entitlementsAllotted = 321;
        info.entitlementsUsed = 654;
        
        /*
        Test.startTest();
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( New List<FSL_Account.MembershipInformation>{ info } );
        Test.stopTest();

        Assert.areEqual( 1, accounts.size(), 'The number of accounts returned is incorrect' );
        Assert.areEqual( memberRecordTypeId, accounts[0].RecordTypeId, 'The account was not converted to a Person Account' );
        Assert.areEqual( accounts[0].Member_Card_Num__pc, accounts[0].Member_ID__c, 'Member_ID__c was not synced' );
        Assert.areEqual( accounts[0].Member_Card_Num__pc, accounts[0].ACG_AAA_Membership__c, 'ACG_AAA_Membership__c was not synced' );
        
        Assert.isNull( accounts[0].Membership_Number__c, 'Membership_Number__c is incorrect' );
        Assert.areEqual( info.title, accounts[0].PersonTitle, 'PersonTitle is incorrect' );
        Assert.areEqual( info.firstName, accounts[0].FirstName, 'FirstName is incorrect' );
        Assert.areEqual( info.lastName, accounts[0].LastName, 'LastName is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].Phone, 'Phone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonMobilePhone, 'PersonMobilePhone is incorrect' );
        Assert.areEqual( info.phoneNumber, accounts[0].PersonHomePhone, 'PersonHomePhone is incorrect' );
        Assert.areEqual( info.phoneExtension, accounts[0].Phone_Extension__pc, 'Phone_Extension__pc is incorrect' );
        Assert.areEqual( info.phoneType, accounts[0].Phone_Type__pc, 'Phone_Type__pc is incorrect' );
        Assert.areEqual( info.membershipType, accounts[0].Membership_Type__pc, 'Membership_Type__pc is incorrect' );
        Assert.isNull( accounts[0].ACG_Joined_AAA__c, 'ACG_Joined_AAA__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].ACG_SMS_Opt_In__c, 'ACG_SMS_Opt_In__c is incorrect' );
        Assert.areEqual( info.isSmsOptedIn, accounts[0].Sms_Optin__pc, 'Sms_Optin__pc is incorrect' );
        Assert.areEqual( info.sponsor, accounts[0].Membership_Sponsor__pc, 'Membership_Sponsor__pc is incorrect' );
        Assert.areEqual( info.program, accounts[0].Membership_Program__pc, 'Membership_Program__pc is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].CDX_Authorization_Code__c, 'CDX_Authorization_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Authorize_Code__c, 'Authorize_Code__c is incorrect' );
        Assert.areEqual( info.authorizationCode, accounts[0].Membership_Code__pc, 'Membership_Code__pc is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].CDX_Authorization_Level__c, 'CDX_Authorization_Level__c is incorrect' );
        Assert.areEqual( info.authorizationLevel, accounts[0].Membership_Authorization__pc, 'Membership_Authorization__pc is incorrect' );
        Assert.areEqual( info.authorizationMessage, accounts[0].CDX_Authorization_Message__c, 'CDX_Authorization_Message__c is incorrect' );
        Assert.areEqual( info.authorizationTransactionId, accounts[0].CDX_Authorization_TransactionId__c, 'CDX_Authorization_TransactionId__c is incorrect' );
        Assert.areEqual( info.isLocalClub, accounts[0].Membership_IsLocalClub__pc, 'Membership_IsLocalClub__pc is incorrect' );
        Assert.areEqual( info.membershipLevel, accounts[0].AAA_Membership_Level__c, 'AAA_Membership_Level__c is incorrect' );
        Assert.areEqual( info.membershipLevelOnContact, accounts[0].Membership_Level__pc, 'Membership_Level__pc is incorrect' );
        Assert.areEqual( info.birthday, accounts[0].Membership_Birthday__pc, 'Membership_Birthday__pc is incorrect' );
        Assert.areEqual( 'Active', accounts[0].ACG_Membership_Status__c, 'ACG_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].CDX_Membership_Status__c, 'CDX_Membership_Status__c is incorrect' );
        Assert.areEqual( info.membershipStatus, accounts[0].Membership_Status__pc, 'Membership_Status__pc is incorrect' );
        Assert.areEqual( info.memberSince, accounts[0].Membership_Since__pc, 'Membership_Since__pc is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__c, 'Membership_Expiration_Date__c is incorrect' );
        Assert.areEqual( info.expirationDate, accounts[0].Membership_Expiration_Date__pc, 'Membership_Expiration_Date__pc is incorrect' );
        Assert.areEqual( info.languagePreference, accounts[0].Language_Preference__pc, 'Language_Preference__pc is incorrect' );
        Assert.areEqual( info.orgPhone, accounts[0].Membership_Org_Phone__pc, 'Membership_Org_Phone__pc is incorrect' );
        Assert.areEqual( info.orgName, accounts[0].Membership_Org__pc, 'Membership_Org__pc is incorrect' );
        Assert.areEqual( info.orgCode, accounts[0].Membership_OrgCode__pc, 'Membership_OrgCode__pc is incorrect' );
        Assert.areEqual( info.contactType, accounts[0].Type__pc, 'Type__pc is incorrect' );
        Assert.areEqual( info.emailType, accounts[0].Email_Type__pc, 'Email_Type__pc is incorrect' );
        Assert.areEqual( info.emailAddress, accounts[0].PersonEmail, 'PersonEmail is incorrect' );
        Assert.areEqual( info.homeStreet, accounts[0].BillingStreet, 'BillingStreet is incorrect' );
        Assert.areEqual( info.homeCity, accounts[0].BillingCity, 'BillingCity is incorrect' );
        Assert.areEqual( info.homePostalCode, accounts[0].BillingPostalCode, 'BillingPostalCode is incorrect' );
        Assert.areEqual( info.homeStateCode, accounts[0].BillingStateCode, 'BillingStateCode is incorrect' );
        Assert.areEqual( info.homeCountryCode, accounts[0].BillingCountryCode, 'BillingCountryCode is incorrect' );
        Assert.areEqual( info.motorcycleCoverage, accounts[0].CDX_Motorcycle_Coverage__c, 'CDX_Motorcycle_Coverage__c is incorrect' );
        Assert.areEqual( info.longTowAllowed, accounts[0].AAA_200_Miles_Premier_Tow__c, 'AAA_200_Miles_Premier_Tow__c is incorrect' );
        Assert.areEqual( info.longTowKilometersUsed, accounts[0].Long_Tow_Kilometers_Used__c, 'Long_Tow_Kilometers_Used__c is incorrect' );
        Assert.areEqual( info.longTowMilesUsed, accounts[0].Long_Tow_Miles_Used__c, 'Long_Tow_Miles_Used__c is incorrect' );
        Assert.areEqual( info.clubCode, accounts[0].ACG_Club__c, 'ACG_Club__c is incorrect' );
        Assert.areEqual( info.clubName, accounts[0].ACG_Club_Name__c, 'ACG_Club_Name__c is incorrect' );
        Assert.areEqual( info.entitlementsAllotted, accounts[0].ACG_Entitlements_Allotted__c, 'ACG_Entitlements_Allotted__c is incorrect' );
        //Assert.areEqual( info.entitlementsUsed, accounts[0].ACG_Entitlements_Used__c, 'ACG_Entitlements_Used__c is incorrect' );
        
        */
    }

    @IsTest
    static void testUpdateMemberAccounts(){
    
        FSL_Account.Factory factory = new FSL_Account.Factory();
        FSL_Account.IAccountService acctService = factory.createService();

        List<Account> accts = new List<Account>();
        accts.add(new Account(Name='Test 1', Member_ID__c='1234567891', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 2', Member_ID__c='1234567892', RecordTypeId=ersMemberRecordTypeId));
        accts.add(new Account(Name='Test 3', RecordTypeId=ersMemberRecordTypeId));
        Test.startTest();
        insert(accts);
        Map<Id,String> accountMemberIds = new Map<Id,String>();
        accountMemberIds.put(accts[0].id, '1234567890123454');
        acctService.updateMemberAccounts(accountMemberIds);
        List<Account> accounts = [SELECT ID, Member_ID__c FROM Account WHERE Id =: accts[0].id];
        System.debug('testUpdateMemberAccounts ==>' + accounts);
        System.assertEquals('1234567890123454', accounts[0].Member_ID__c);
        Test.stopTest();  
    }

    @IsTest
    public static void testAccountService_DeleteAccounts_DaoReturnsRecords_Deleted() {
        AccountDAOMock dao = new AccountDAOMock();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );

        Account a1 = new Account( Id = dao.Builder.getMockId() );
        Account a2 = new Account( Id = dao.Builder.getMockId() );
        Account a3 = new Account( Id = dao.Builder.getMockId() );
        Account a4 = new Account( Id = dao.Builder.getMockId() );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );
        System.assertEquals( 4, dao.accounts.size(), 'Arrange: Number of Accounts in DAO Mock are not correct' );

        Set<Id> ids = new Set<Id>{ a2.Id, a3.Id };
        
        Test.startTest();
        service.deleteAccounts( ids );
        Test.stopTest();

        System.assertEquals( 2, dao.accounts.size(), 'Assert: Accounts were not deleted' );
        System.assertEquals( null, dao.accounts.get( a2.Id ), 'Assert: Account 2 was not deleted' );
        System.assertEquals( null, dao.accounts.get( a3.Id ), 'Assert: Account 3 was not deleted' );
    }

    @IsTest
    public static void testAccountService_DeleteAccounts_DaoReturnsNoRecords_NotDeleted() {
        AccountDAOMock dao = new AccountDAOMock();
        FSL_Account.IAccountService service = new FSL_Account.AccountService( dao );

        Account a1 = new Account( Id = dao.Builder.getMockId() );
        Account a2 = new Account( Id = dao.Builder.getMockId() );
        Account a3 = new Account( Id = dao.Builder.getMockId() );
        Account a4 = new Account( Id = dao.Builder.getMockId() );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );
        System.assertEquals( 4, dao.accounts.size(), 'Arrange: Number of Accounts in DAO Mock are not correct' );

        Id nonExistentAccountId1 = dao.Builder.getMockId();
        Id nonExistentAccountId2 = dao.Builder.getMockId();
        Set<Id> ids = new Set<Id>{ nonExistentAccountId1, nonExistentAccountId2 };

        System.assertEquals( null, dao.accounts.get( nonExistentAccountId1 ), 'Arrange: Account 1 is in the DAO Mock' );
        System.assertEquals( null, dao.accounts.get( nonExistentAccountId2 ), 'Arrange: Account 2 is in the DAO Mock' );
        
        Test.startTest();
        service.deleteAccounts( ids );
        Test.stopTest();

        System.assertEquals( 4, dao.accounts.size(), 'Assert: Accounts were deleted' );
    }

    // *********************************************
    // * MembershipInformation
    // *********************************************
    @IsTest
    public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithAllFieldsPopulated_MembershipInformationCreatedAndPopulated(){
        String membershipNumber = '1234567890123456';
        String membershipType = 'Membership Type';
        String sponsor = 'Sponsor';
        String program = 'Program';
        String authorizationCode = 'Auth Code';
        String authorizationLevel = 'Auth Level';
        Boolean isLocalClub = true;
        String membershipLevel = 'Basic';
        String birthday = 'Birthday';
        String membershipStatus = 'Status';
        String memberSince = 'Since';
        Date expirationDate = Date.today();
        String languagePreference = 'Language';
        String orgPhone = 'Org Phone';
        String orgName = 'Org Name';
        String orgCode = 'Org Code';
        String contactType = 'Contact Type';
        String title = 'Title';
        String firstName = 'First Name';
        String lastName = 'Last Name';
        String phoneNumber = 'Phone Number';
        String phoneType = 'Phone Type';
        String phoneExtension = 'Phone Extension';
        Boolean isSmsOptedIn = true;
        String emailType = 'Email Type';
        String emailAddress = 'Email Address';
        String externalId = 'External ID';
        
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.contact = new FSL_JSonParserWorkOrder.Contact_customer();
        call.customer.contact.phones = new List<FSL_JSonParserWorkOrder.Phones>{new FSL_JSonParserWorkOrder.Phones()};
        call.customer.contact.emails = new List<FSL_JSonParserWorkOrder.Emails>{new FSL_JSonParserWorkOrder.Emails()};
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.channel = new FSL_JSonParserWorkOrder.Channel();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        
        call.customer.memberships[0].id = membershipNumber;
        call.customer.memberships[0].membershipType = membershipType;
        call.customer.memberships[0].sponsor = sponsor;
        call.customer.memberships[0].program = program;
        call.customer.memberships[0].authorizationCode = authorizationCode;
        call.customer.memberships[0].authorizationLevel = authorizationLevel;
        call.customer.memberships[0].isLocalClub = isLocalClub;
        call.customer.memberships[0].memberLevel = membershipLevel;
        call.customer.memberships[0].memberBirthday = birthday;
        call.customer.memberships[0].memberStatus = membershipStatus;
        call.customer.memberships[0].memberSince = memberSince;
        call.customer.memberships[0].expirationDate = String.valueOf( expirationDate );
        call.customer.languagePreference = languagePreference;
        call.customer.memberships[0].programPhone = orgPhone;
        call.customer.memberships[0].programName = orgName;
        call.customer.memberships[0].org.code = orgCode;

        call.customer.contact.contactType = contactType;
        call.customer.contact.title = title;
        call.customer.contact.firstName = firstName;
        call.customer.contact.lastName = lastName;
        call.customer.contact.contactType = contactType;
        call.customer.contact.phones[0].phoneNumber = phoneNumber;
        call.customer.contact.phones[0].phoneType = phoneType;
        call.customer.contact.phones[0].phoneExtension = phoneExtension;
        call.customer.contact.phones[0].smsOptIn = isSmsOptedIn;
        call.customer.contact.emails[0].emailType = emailType;
        call.customer.contact.emails[0].address = emailAddress;
        call.channel.contact.userId = externalId;


        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();

        Assert.areEqual( membershipNumber, info.membershipNumber, 'MembershipNumber is not correct' );
        Assert.areEqual( membershipType, info.membershipType, 'MembershipType is not correct' );
        Assert.areEqual( sponsor, info.sponsor, 'Sponsor is not correct' );
        Assert.areEqual( program, info.program, 'program is not correct' );
        Assert.areEqual( authorizationCode, info.authorizationCode, 'AuthorizationCode is not correct' );
        Assert.areEqual( authorizationLevel, info.authorizationLevel, 'AuthorizationLevel is not correct' );
        Assert.isNull( info.authorizationMessage, 'AuthorizationMessage is not correct' );
        Assert.isNull( info.authorizationTransactionId, 'AuthorizationTransactionId is not correct' );
        Assert.areEqual( isLocalClub, info.isLocalClub, 'IsLocalClub is not correct' );
        Assert.areEqual( membershipLevel, info.membershipLevel, 'MembershipLevel is not correct' );
        Assert.areEqual( birthday, info.birthday, 'Birthday is not correct' );
        Assert.areEqual( membershipStatus, info.membershipStatus, 'MembershipStatus is not correct' );
        Assert.areEqual( memberSince, info.memberSince, 'MemberSince is not correct' );
        Assert.areEqual( expirationDate, info.expirationDate, 'ExpirationDate is not correct' );
        Assert.areEqual( languagePreference, info.languagePreference, 'LanguagePreference is not correct' );
        Assert.areEqual( orgPhone, info.orgPhone, 'OrgPhone is not correct' );
        Assert.areEqual( orgName, info.orgName, 'OrgName is not correct' );
        Assert.areEqual( orgCode, info.orgCode, 'OrgCode is not correct' );
        Assert.areEqual( contactType, info.contactType, 'ContactType is not correct' );
        Assert.areEqual( title, info.title, 'Title is not correct' );
        Assert.areEqual( firstName, info.firstName, 'FirstName is not correct' );
        Assert.areEqual( lastName, info.lastName, 'LastName is not correct' );
        Assert.areEqual( phoneNumber, info.phoneNumber, 'PhoneNumber is not correct' );
        Assert.areEqual( phoneType, info.phoneType, 'PhoneType is not correct' );
        Assert.areEqual( phoneExtension, info.phoneExtension, 'PhoneExtension is not correct' );
        Assert.areEqual( isSmsOptedIn, info.isSmsOptedIn, 'IsSmsOptedIn is not correct' );
        Assert.areEqual( emailType, info.emailType, 'EmailType is not correct' );
        Assert.areEqual( emailAddress, info.emailAddress, 'EmailAddress is not correct' );
        Assert.areEqual( externalId, info.externalId, 'ExternalId is not correct' );
        Assert.isNull( info.homeStreet, 'HomeStreet is not correct' );
        Assert.isNull( info.homeCity, 'HomeCity is not correct' );
        Assert.isNull( info.homePostalCode, 'HomePostalCode is not correct' );
        Assert.isNull( info.homeStateCode, 'HomeStateCode is not correct' );
        Assert.isNull( info.homeCountryCode, 'HomeCountryCode is not correct' );
        Assert.isNull( info.motorcycleCoverage, 'MotorcycleCoverage is not correct' );
        Assert.isNull( info.longTowAllowed, 'LongTowAllowed is not correct' );
        Assert.isNull( info.longTowKilometersUsed, 'LongTowKilometersUsed is not correct' );
        Assert.isNull( info.longTowMilesUsed, 'LongTowMilesUsed is not correct' );
        Assert.isNull( info.clubCode, 'clubCode is not correct' );
        Assert.isNull( info.clubName, 'clubName is not correct' );
        Assert.isNull( info.entitlementsAllotted, 'entitlementsAllotted is not correct' );
        Assert.isNull( info.entitlementsUsed, 'entitlementsUsed is not correct' );

        call.customer.memberships[0].memberLevel = 'PREMIER';
        info = parser.parse( call );
        Assert.areEqual( 'Premier', info.membershipLevel, 'MembershipLevel is not correct' );
        call.customer.memberships[0].memberLevel = 'PREMIER RV';
        info = parser.parse( call );
        Assert.areEqual( 'Premier RV', info.membershipLevel, 'MembershipLevel is not correct' );
        call.customer.memberships[0].memberLevel = 'PLUS RV';
        info = parser.parse( call );
        Assert.areEqual( 'Plus RV', info.membershipLevel, 'MembershipLevel is not correct' );
        call.customer.memberships[0].memberLevel = 'PLUS';
        info = parser.parse( call );
        Assert.areEqual( 'Plus', info.membershipLevel, 'MembershipLevel is not correct' );
        call.customer.memberships[0].memberLevel = 'CLASSIC RV';
        info = parser.parse( call );
        Assert.areEqual( 'Basic', info.membershipLevel, 'MembershipLevel is not correct' );   
        call.customer.memberships[0].memberLevel = '';
        info = parser.parse( call );
        Assert.areEqual( 'Basic', info.membershipLevel, 'MembershipLevel is not correct' );           
             
    }

    @IsTest
    public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithIdNotNumeric_MembershipNumberIsNull(){
        String id = 'Membership Number';
        
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.channel = new FSL_JSonParserWorkOrder.Channel();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
        call.customer.memberships[0].id = id;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();

        Assert.isNull( info.membershipNumber, 'MembershipNumber is not correct' );
    }

    @IsTest
    public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithIdNumericButNot16Characters_MembershipNumberIsNull(){
        String id = '123456789012345';
        
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.channel = new FSL_JSonParserWorkOrder.Channel();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
        call.customer.memberships[0].id = id;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();

        Assert.isNotNull( info.membershipNumber, 'MembershipNumber is not correct' );
    }
    
/* Below is not a valid value. As per business it will be either blank or a 4 digit numeric value.  
From: Fortney, James <JFortney@aaamidatlantic.com>
Date: Mon, Jun 5, 2023 at 8:37 PM
Subject: RE: [EXTERNAL] Service Contract Discussion @ Fri, Jun 2, 2023 9:30pm – 10:00pm (GMT+05:30)
To: Varun Sharma <varunsharma@salesforce.com>, Hunter, Landen <lhunter@aaacorp.com>
Cc: Turner, Brad <BTurner@aaa-alliedgroup.com>, Pai, Seema <SPai@aaamidatlantic.com>, Klichinsky, Ed <eklichinsky@aaamidatlantic.com>, Ventura, Chris <cventura2@aaamidatlantic.com>, Trung Phan <tphan@salesforce.com>, Raj Avirneni <ravirneni@salesforce.com>, Welch, Susan <swelch@aaa-alliedgroup.com>, Vanamala, Mahesh <mvanamala@aaacorp.com>

Expiration Date will be YYYY-MM-DD ("expirationDate": "2023-03-15") or an Empty/NULL value ("expirationDate": "")

Join Date will be YYYY ("memberSince": "1993") or an Empty/NULL value ("memberSince": "")        
        */

    // @IsTest
    // public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithMemberSinceContainingASingleCharacter_LeftPaddedToTwoCharactersWithZero(){
    //     String memberSince = 'A';
    //     String expectedMemberSince = '0A';
        
    //     FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
    //     call.channel = new FSL_JSonParserWorkOrder.Channel();
    //     call.customer = new FSL_JSonParserWorkOrder.Customer();
    //     call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
    //     call.customer.memberships[0].memberSince = memberSince;
        
    //     Test.StartTest();
    //     FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
    //     FSL_Account.MembershipInformation info = parser.parse( call );
    //     Test.StopTest();

    //     Assert.areEqual( expectedMemberSince, info.memberSince, 'MemberSince is not correct' );
    // }

    @IsTest
    public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithProgramNameNullAndOrgNameSet_OrgNameIsUsed(){
        String orgName = 'A';
        
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.channel = new FSL_JSonParserWorkOrder.Channel();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();

        call.customer.memberships[0].org.name = orgName;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();

        Assert.areEqual( orgName, info.orgName, 'OrgName is not correct' );
    }
    
    @IsTest
    public static void testMembershipInformationParser_ParseFSL_JSonParserWorkOrderWithFieldsNull_MembershipInformationCreatedAndPopulatedWithNulls(){
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{new FSL_JSonParserWorkOrder.Memberships()};
        call.channel = new FSL_JSonParserWorkOrder.Channel();

        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        system.debug('***call***'+ call);
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();

        Assert.isNull( info.membershipNumber, 'MembershipNumber is not correct' );
        Assert.isNull( info.membershipType, 'MembershipType is not correct' );
        Assert.isNull( info.sponsor, 'Sponsor is not correct' );
        Assert.isNull( info.program, 'program is not correct' );
        Assert.isNull( info.authorizationCode, 'AuthorizationCode is not correct' );
        Assert.isNull( info.authorizationLevel, 'AuthorizationLevel is not correct' );
        Assert.isNull( info.authorizationMessage, 'AuthorizationMessage is not correct' );
        Assert.isNull( info.authorizationTransactionId, 'AuthorizationTransactionId is not correct' );
        Assert.isNull( info.isLocalClub, 'IsLocalClub is not correct' );
        Assert.isNotNull( info.membershipLevel, 'MembershipLevel is not correct' );   //This field defaults to Classic
        Assert.isNotNull( info.membershipLevelOnContact, 'MembershipLevelOnContact is not correct' );
        Assert.isNull( info.birthday, 'Birthday is not correct' );
        Assert.isNull( info.membershipStatus, 'MembershipStatus is not correct' );
        Assert.isNull( info.memberSince, 'MemberSince is not correct' );
        Assert.isNull( info.expirationDate, 'ExpirationDate is not correct' );
        Assert.isNull( info.languagePreference, 'LanguagePreference is not correct' );
        Assert.isNull( info.orgPhone, 'OrgPhone is not correct' );
        Assert.isNull( info.orgName, 'OrgName is not correct' );
        Assert.isNull( info.orgCode, 'OrgCode is not correct' );
        Assert.isNull( info.contactType, 'ContactType is not correct' );
        Assert.isNull( info.title, 'Title is not correct' );
        Assert.isNull( info.firstName, 'FirstName is not correct' );
        Assert.isNull( info.lastName, 'LastName is not correct' );
        Assert.isNull( info.phoneNumber, 'PhoneNumber is not correct' );
        Assert.isNull( info.phoneType, 'PhoneType is not correct' );
        Assert.isNull( info.phoneExtension, 'PhoneExtension is not correct' );
        Assert.isNull( info.isSmsOptedIn, 'IsSmsOptedIn is not correct' );
        Assert.isNull( info.emailType, 'EmailType is not correct' );
        Assert.isNull( info.emailAddress, 'EmailAddress is not correct' );
        Assert.isNull( info.externalId, 'ExternalId is not correct' );
        Assert.isNull( info.homeStreet, 'HomeStreet is not correct' );
        Assert.isNull( info.homeCity, 'HomeCity is not correct' );
        Assert.isNull( info.homePostalCode, 'HomePostalCode is not correct' );
        Assert.isNull( info.homeStateCode, 'HomeStateCode is not correct' );
        Assert.isNull( info.homeCountryCode, 'HomeCountryCode is not correct' );
        Assert.isNull( info.motorcycleCoverage, 'MotorcycleCoverage is not correct' );
        Assert.isNull( info.longTowAllowed, 'LongTowAllowed is not correct' );
        Assert.isNull( info.longTowKilometersUsed, 'LongTowKilometersUsed is not correct' );
        Assert.isNull( info.longTowMilesUsed, 'LongTowMilesUsed is not correct' );
        Assert.isNull( info.clubCode, 'clubCode is not correct' );
        Assert.isNull( info.clubName, 'clubName is not correct' );
        Assert.isNull( info.entitlementsAllotted, 'entitlementsAllotted is not correct' );
        Assert.isNull( info.entitlementsUsed, 'entitlementsUsed is not correct' );
    }

    @IsTest
    public static void testMembershipInformationParser_INTFSLWorkOrderRequestWrapperWithAllFieldsPopulated_MembershipInformationCreatedAndPopulated(){
        String membershipNumber = '1234567890123456';
        String membershipLevel = 'Level';
        String memberSince = 'Since';
        String orgName = 'Org Name';
        String orgCode = 'Org Code';
        String firstName = 'First Name';
        String lastName = 'Last Name';
        String inputPhoneNumber = '123-456-7890';
        String expectedPhoneNumber = '1234567890';
        String sponsor = 'Sponsor';
        String program = 'Program';
        Boolean isSmsOptedIn = true;
        
        INTFSLWorkOrderRequest_Wrapper call = new INTFSLWorkOrderRequest_Wrapper();
        call.contactInformation = new INTFSLWorkOrderRequest_Wrapper.ContactInformation();
        
        call.memberNumber = membershipNumber;
        call.contactInformation.currentBenefitLevel = membershipLevel;
        call.contactInformation.joinYear = memberSince;
        call.sourceOrgName = orgName;
        call.sourceOrgCode = orgCode;
        call.contactInformation.sponsor = sponsor;
        call.contactInformation.program = program;
        call.contactInformation.firstName = firstName;
        call.contactInformation.lastName = lastName;
        call.contactInformation.telephoneNumber = inputPhoneNumber;
        call.contactInformation.smsOptin = isSmsOptedIn;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( call );
        Test.StopTest();
        System.Debug('membershipNumber::' + membershipNumber + ' , info.membershipNumber::' + info.membershipNumber);
        Assert.areEqual( membershipNumber, info.membershipNumber, 'MembershipNumber is not correct' );
        Assert.isNotNull( info.membershipType, 'MembershipType is not correct' );
        Assert.areEqual( sponsor, info.sponsor, 'Sponsor is not correct' );
        Assert.areEqual( program, info.program, 'program is not correct' );
        Assert.isNull( info.authorizationCode, 'AuthorizationCode is not correct' );
        Assert.isNull( info.authorizationLevel, 'AuthorizationLevel is not correct' );
        Assert.isNull( info.authorizationMessage, 'AuthorizationMessage is not correct' );
        Assert.isNull( info.authorizationTransactionId, 'AuthorizationTransactionId is not correct' );
        Assert.isNull( info.isLocalClub, 'IsLocalClub is not correct' );
        Assert.areEqual( 'Basic', info.membershipLevel, 'MembershipLevel is not correct' );
        Assert.isNull( info.birthday, 'Birthday is not correct' );
        Assert.areEqual( 'Active', info.membershipStatus, 'MembershipStatus is not correct' );
        Assert.areEqual( memberSince, info.memberSince, 'MemberSince is not correct' );
        Assert.isNull( info.expirationDate, 'ExpirationDate is not correct' );
        Assert.isNull( info.languagePreference, 'LanguagePreference is not correct' );
        Assert.isNull( info.orgPhone, 'OrgPhone is not correct' );
        Assert.areEqual( orgName, info.orgName, 'OrgName is not correct' );
        Assert.areEqual( orgCode, info.orgCode, 'OrgCode is not correct' );
        Assert.isNull( info.contactType, 'ContactType is not correct' );
        Assert.isNull( info.title, 'Title is not correct' );
        Assert.areEqual( firstName, info.firstName, 'FirstName is not correct' );
        Assert.areEqual( lastName, info.lastName, 'LastName is not correct' );
        Assert.areEqual( expectedPhoneNumber, info.phoneNumber, 'PhoneNumber is not correct' );
        Assert.isNull( info.phoneType, 'PhoneType is not correct' );
        Assert.isNull( info.phoneExtension, 'PhoneExtension is not correct' );
        Assert.areEqual( isSmsOptedIn, info.isSmsOptedIn, 'IsSmsOptedIn is not correct' );
        Assert.isNull( info.emailType, 'EmailType is not correct' );
        Assert.isNull( info.emailAddress, 'EmailAddress is not correct' );
        Assert.isNull( info.externalId, 'ExternalId is not correct' );
        Assert.isNull( info.homeStreet, 'HomeStreet is not correct' );
        Assert.isNull( info.homeCity, 'HomeCity is not correct' );
        Assert.isNull( info.homePostalCode, 'HomePostalCode is not correct' );
        Assert.isNull( info.homeStateCode, 'HomeStateCode is not correct' );
        Assert.isNull( info.homeCountryCode, 'HomeCountryCode is not correct' );
        Assert.isNull( info.motorcycleCoverage, 'MotorcycleCoverage is not correct' );
        Assert.isNull( info.longTowAllowed, 'LongTowAllowed is not correct' );
        Assert.isNull( info.longTowKilometersUsed, 'LongTowKilometersUsed is not correct' );
        Assert.isNull( info.longTowMilesUsed, 'LongTowMilesUsed is not correct' );
        Assert.isNull( info.clubCode, 'clubCode is not correct' );
        Assert.isNull( info.clubName, 'clubName is not correct' );
        Assert.isNull( info.entitlementsAllotted, 'entitlementsAllotted is not correct' );
        Assert.isNull( info.entitlementsUsed, 'entitlementsUsed is not correct' );

        call.contactInformation.currentBenefitLevel = 'CLASSIC';
        info = parser.parse( call );
        Assert.areEqual( 'Basic', info.membershipLevel, 'MembershipLevel is not correct' );
        call.contactInformation.currentBenefitLevel = 'PREMIER';
        info = parser.parse( call );
        Assert.areEqual( 'Premier', info.membershipLevel, 'MembershipLevel is not correct' );
        call.contactInformation.currentBenefitLevel = 'PREMIER RV';
        info = parser.parse( call );
        Assert.areEqual( 'Premier RV', info.membershipLevel, 'MembershipLevel is not correct' );
        call.contactInformation.currentBenefitLevel = 'PLUS RV';
        info = parser.parse( call );
        Assert.areEqual( 'Plus RV', info.membershipLevel, 'MembershipLevel is not correct' );
        call.contactInformation.currentBenefitLevel = 'PLUS';
        info = parser.parse( call );
        Assert.areEqual( 'Plus', info.membershipLevel, 'MembershipLevel is not correct' );
        call.contactInformation.currentBenefitLevel = 'CLASSIC RV';
        info = parser.parse( call );
        Assert.areEqual( 'Basic', info.membershipLevel, 'MembershipLevel is not correct' );                                        
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithAllFieldsPopulated_MembershipInformationCreatedAndPopulated(){
        String membershipNumber = '1234567890123456';
        // String membershipType = 'Membership Type';
        // String sponsor = 'Sponsor';
        // String program = 'Program';
        String authorizationCode = 'Auth Code';
        String authorizationLevel = 'Auth Level';
        String authorizationMessage = 'Auth Message';
        // Boolean isLocalClub = true;
        String inputMembershipLevel = 'Level';
        String expectedMembershipLevel = 'Basic';
        String birthday = 'Birthday';
        String membershipStatus = 'Status';
        String memberSince = 'Since';
        Date expirationDate = Date.today();
        // String languagePreference = 'Language';
        // String orgPhone = 'Org Phone';
        // String orgName = 'Org Name';
        // String orgCode = 'Org Code';
        // String contactType = 'Contact Type';
        String title = 'Title';
        String firstName = 'First Name';
        String lastName = 'Last Name';
        String phoneNumber = 'Phone Number';
        String phoneType = 'Phone Type';
        // String phoneExtension = 'Phone Extension';
        // Boolean isSmsOptedIn = true;
        // String emailType = 'Email Type';
        // String emailAddress = 'Email Address';
        // String externalId = 'External ID';
        String addressLine1 = 'Address Line 1';
        String addressLine2 = 'Address Line 2';
        String expectedStreet = addressLine1 + '; ' + addressLine2;
        String city = 'City';
        String postalCode = 'Postal Code';
        String stateCode = 'State Code';
        String countryCode = 'Country Code';
        String inputMotorcycleCoverage = 'Y';
        Boolean expectedMotorcycleCoverage = true;
        Boolean longTowAllowed = true;
        Integer longTowKilometersUsed = 111;
        Integer longTowMilesUsed = 222;
        String clubCode = '456'; // Characters 4-6 of membership number
        Integer entitlementsAllotted = 333;
        Integer entitlementsUsed = 444;
        
        INTMembershipLookupResponse_Wrapper.Customer customer = new INTMembershipLookupResponse_Wrapper.Customer();
        customer.productInfo = new List<INTMembershipLookupResponse_Wrapper.ProductInfo>{ new INTMembershipLookupResponse_Wrapper.ProductInfo() };
        customer.phone = new List<INTMembershipLookupResponse_Wrapper.Phone>{ new INTMembershipLookupResponse_Wrapper.Phone() };
        customer.address = new List<INTMembershipLookupResponse_Wrapper.Address>{ new INTMembershipLookupResponse_Wrapper.Address() };
        customer.authorize = new INTMembershipLookupResponse_Wrapper.Authorize();
        customer.entitlement = new FSL_LightningEntitlementWrapper();

        customer.membershipId = membershipNumber;
        customer.authorize.code = authorizationCode;
        customer.authorize.level = authorizationLevel;
        customer.productInfo[0].authorizationMessage = authorizationMessage;
        customer.memberLevel = inputMembershipLevel;
        customer.birthDate = birthday;
        customer.productInfo[0].productStatus = membershipStatus;
        customer.mbrJnAaaDt = memberSince;
        customer.productInfo[0].productExpirationDate = String.valueOf( expirationDate );
        customer.title = title;
        customer.firstName = firstName;
        customer.lastName = lastName;
        customer.phone[0].isPrimary = 'Yes';
        customer.phone[0].phonNumber = phoneNumber;
        customer.phone[0].phoneType = phoneType;
        customer.address[0].addressLine1 = addressLine1;
        customer.address[0].addressLine2 = addressLine2;
        customer.address[0].city = city;
        customer.address[0].postCode = postalCode;
        customer.address[0].state = stateCode;
        customer.address[0].country = countryCode;
        customer.productInfo[0].motorcycleCoverage = inputMotorcycleCoverage;
        customer.entitlement.longTowAllowed = longTowAllowed;
        customer.authorize.longTowKilometers = String.valueOf( longTowKilometersUsed );
        customer.authorize.longTowMiles = String.valueOf( longTowMilesUsed );
        customer.entitlement.callsAllowed = entitlementsAllotted;
        customer.entitlement.callsUsed = entitlementsUsed;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( customer );
        Test.StopTest();

        Assert.areEqual( membershipNumber, info.membershipNumber, 'MembershipNumber is not correct' );
        Assert.isNull( info.membershipType, 'MembershipType is not correct' );
        Assert.isNull( info.sponsor, 'Sponsor is not correct' );
        Assert.isNull( info.program, 'program is not correct' );
        Assert.areEqual( authorizationCode, info.authorizationCode, 'AuthorizationCode is not correct' );
        Assert.areEqual( authorizationLevel, info.authorizationLevel, 'AuthorizationLevel is not correct' );
        Assert.areEqual( authorizationMessage, info.authorizationMessage, 'AuthorizationMessage is not correct' );
        Assert.isNull( info.isLocalClub, 'IsLocalClub is not correct' );
        Assert.areEqual( expectedMembershipLevel, info.membershipLevel, 'MembershipLevel is not correct' );
        Assert.areEqual( birthday, info.birthday, 'Birthday is not correct' );
        Assert.areEqual( membershipStatus, info.membershipStatus, 'MembershipStatus is not correct' );
        Assert.areEqual( memberSince, info.memberSince, 'MemberSince is not correct' );
        Assert.areEqual( expirationDate, info.expirationDate, 'ExpirationDate is not correct' );
        Assert.isNull( info.languagePreference, 'LanguagePreference is not correct' );
        Assert.isNull( info.orgPhone, 'OrgPhone is not correct' );
        Assert.isNull( info.orgName, 'OrgName is not correct' );
        Assert.isNull( info.orgCode, 'OrgCode is not correct' );
        Assert.isNull( info.contactType, 'ContactType is not correct' );
        Assert.areEqual( title, info.title, 'Title is not correct' );
        Assert.areEqual( firstName, info.firstName, 'FirstName is not correct' );
        Assert.areEqual( lastName, info.lastName, 'LastName is not correct' );
        Assert.areEqual( phoneNumber, info.phoneNumber, 'PhoneNumber is not correct' );
        Assert.areEqual( phoneType, info.phoneType, 'PhoneType is not correct' );
        Assert.isNull( info.phoneExtension, 'PhoneExtension is not correct' );
        Assert.isNull( info.isSmsOptedIn, 'IsSmsOptedIn is not correct' );
        //Assert.isNull( info.emailType, 'EmailType is not correct' ); Setting PERSONAL AS DEFAULT
        Assert.isNull( info.emailAddress, 'EmailAddress is not correct' );
        Assert.isNull( info.externalId, 'ExternalId is not correct' );
        Assert.areEqual( expectedStreet, info.homeStreet, 'HomeStreet is not correct' );
        Assert.areEqual( city, info.homeCity, 'HomeCity is not correct' );
        Assert.areEqual( postalCode, info.homePostalCode, 'HomePostalCode is not correct' );
        Assert.areEqual( stateCode, info.homeStateCode, 'HomeStateCode is not correct' );
        Assert.areEqual( countryCode, info.homeCountryCode, 'HomeCountryCode is not correct' );
        Assert.areEqual( expectedMotorcycleCoverage, info.motorcycleCoverage, 'MotorcycleCoverage is not correct' );
        Assert.areEqual( longTowAllowed, info.longTowAllowed, 'LongTowAllowed is not correct' );
        //Assert.areEqual( longTowKilometersUsed, info.longTowKilometersUsed, 'LongTowKilometersUsed is not correct' );
        //Assert.areEqual( longTowMilesUsed, info.longTowMilesUsed, 'LongTowMilesUsed is not correct' );
        Assert.areEqual( clubCode, info.clubCode, 'clubCode is not correct' );
        Assert.isNull( info.clubName, 'clubName is not correct' );
        Assert.areEqual( entitlementsAllotted, info.entitlementsAllotted, 'entitlementsAllotted is not correct' );
        Assert.areEqual( entitlementsUsed, info.entitlementsUsed, 'entitlementsUsed is not correct' );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClassic_MembershipInformationCreatedAndMembershipLevelPopulatedWithClassic(){
        String inputMembershipLevel = 'classic';
        String expectedMembershipLevel = 'Basic';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithClassic(){
        String inputMembershipLevel = 'clsc';
        String expectedMembershipLevel = 'Basic';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelBasic_MembershipInformationCreatedAndMembershipLevelPopulatedWithClassic(){
        String inputMembershipLevel = 'Basic';
        String expectedMembershipLevel = 'Basic';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPremier_MembershipInformationCreatedAndMembershipLevelPopulatedWithPremier(){
        String inputMembershipLevel = 'Premier';
        String expectedMembershipLevel = 'Premier';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPrem_MembershipInformationCreatedAndMembershipLevelPopulatedWithPremier(){
        String inputMembershipLevel = 'Prem';
        String expectedMembershipLevel = Label.Club_Name == 'NE' ? 'Basic' : 'Premier';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPremierRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithPremierRv(){
        String inputMembershipLevel = 'Premier RV';
        String expectedMembershipLevel = 'Premier RV';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPrRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithPremierRv(){
        String inputMembershipLevel = 'Prrv';
        String expectedMembershipLevel = Label.Club_Name == 'NE' ? 'Basic' : 'Premier RV';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPlusRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithPlusRv(){
        String inputMembershipLevel = 'Plus RV';
        String expectedMembershipLevel = 'Plus RV';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPlRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithPlusRv(){
        String inputMembershipLevel = 'Plrv';
        String expectedMembershipLevel = Label.Club_Name == 'NE' ? 'Basic' : 'Plus RV';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelPlus_MembershipInformationCreatedAndMembershipLevelPopulatedWithPlus(){
        String inputMembershipLevel = 'Plus';
        String expectedMembershipLevel = 'Plus';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClassicRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithClassicRv(){
        String inputMembershipLevel = 'Classic RV';
        String expectedMembershipLevel = 'Basic';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    @IsTest
    public static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClRv_MembershipInformationCreatedAndMembershipLevelPopulatedWithClassicRv(){
        String inputMembershipLevel = 'Clrv';
        String expectedMembershipLevel = 'Basic';
        
        testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( inputMembershipLevel, expectedMembershipLevel );
    }

    private static void testMembershipInformationParser_INTMembershipLookupResponseWrapperWithMemberLevelClsc_MembershipInformationCreatedAndMembershipLevelPopulatedWithExpectedValue( String inputMembershipLevel, String expectedMembershipLevel ) {
        INTMembershipLookupResponse_Wrapper.Customer customer = new INTMembershipLookupResponse_Wrapper.Customer();
        customer.productInfo = new List<INTMembershipLookupResponse_Wrapper.ProductInfo>{ new INTMembershipLookupResponse_Wrapper.ProductInfo() };
        
        customer.memberLevel = inputMembershipLevel;
        
        Test.StartTest();
        FSL_Account.MembershipInformationParser parser = new FSL_Account.MembershipInformationParser();
        FSL_Account.MembershipInformation info = parser.parse( customer );
        Test.StopTest();

        Assert.areEqual( expectedMembershipLevel, info.membershipLevel, 'MembershipLevel is not correct' );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_Account.IFactory {
        public FSL_Account.IAccountService createService() {
            return new AccountServiceMock();
        }

        public FSL_Account.MembershipInformationParser createMembershipInformationParser() {
            return new MembershipInformationParserMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FSL_Account.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_Account.IAccountService service = factory.createService();
        Test.stopTest();

        Assert.isNotNull( service );
    }

    @IsTest
    public static void testFactoryMock_CreateMembershipInformationParser_NotNull() {
        FSL_Account.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_Account.MembershipInformationParser parser = factory.createMembershipInformationParser();
        Test.stopTest();

        Assert.isNotNull( parser );
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType ACCOUNT_TYPE = Schema.Account.getSObjectType();
    public class AccountDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Account.IAccountDAO {
        public Map<Id, Account> accounts;
        public Boolean isSuccess = true;

        public AccountDAOMock() {
            super( new Map<Id, Account>(), ACCOUNT_TYPE );
            this.accounts = (Map<Id, Account>)super.Records;
            System.Debug('Creating mock class instance::AccountDAOMock::' + this.accounts);
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ClearQueuedCallDAOMock' );
            }
        }
       
        public List<Account> fetchAccountsById( Set<Id> ids ) {
            System.Debug('Creating mock class instance::AccountDAOMock::fetchAccountsById');
            isQueryException();
            List<Account> result = new List<Account>();
            for( Id id : ids ) {
                if( accounts.containsKey( id ) ) {
                    result.add( accounts.get( id ) );
                }
            }
            return result;
        }

        public List<Account> fetchERSMemberAccountsByMemberId( Set<String> memberIds ) {
            System.Debug('Creating mock class instance::AccountDAOMock::fetchERSMemberAccountsByMemberId');
            isQueryException();
            List<Account> result = new List<Account>();
            for( Account a : accounts.values() ) {
                if( memberIds.contains( a.Member_ID__c ) ) {
                    result.add( a );
                }
            }
            return result;
        }
        
        public Integer fetchMemberAccountsByMemberIdCallCount = 0;
      
        public List<Account> fetchMemberAccountsByMemberIdReturnValue = new List<Account>();
        
        
        public List<Account> fetchMemberAccountsByMemberId( Set<String> memberIds ) {            
            fetchMemberAccountsByMemberIdCallCount++;
            System.Debug('Increment by 1::' + fetchMemberAccountsByMemberIdCallCount);
            isQueryException();        
            return fetchMemberAccountsByMemberIdReturnValue;
        }

        public List<Account> fetchMemberAccountsById( Set<String> memberRecordIds ) {
            fetchMemberAccountsByMemberIdCallCount++;
            System.Debug('Increment by 1::' + fetchMemberAccountsByMemberIdCallCount);
            isQueryException();
            return fetchMemberAccountsByMemberIdReturnValue;
        }
    }

    @IsTest
    public static void testAccountDAOMock_FetchAccountsById_NoException_CorrectRecordsReturned() {
        AccountDAOMock dao = new AccountDAOMock();

        Account a1 = new Account( Id = dao.Builder.getMockId() );
        Account a2 = new Account( Id = dao.Builder.getMockId() );
        Account a3 = new Account( Id = dao.Builder.getMockId() );
        Account a4 = new Account( Id = dao.Builder.getMockId() );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );

        Set<Id> ids = new Set<Id>{ a2.Id, a3.Id };

        Test.startTest();
        List<Account> accounts = dao.fetchAccountsById( ids );
        Test.stopTest();

        System.assertEquals( 2, accounts.size(), 'The amount of records returned is not correct' );
        System.assertEquals( a2.Id, accounts[0].Id, 'The Id of the first Account returned does not match' );
        System.assertEquals( a3.Id, accounts[1].Id, 'The Id of the second Account returned does not match' );
    }

    @IsTest
    public static void testAccountDAOMock_FetchAccountsById_Exception_ExceptionThrown() {
        AccountDAOMock dao = new AccountDAOMock();

        Account a1 = new Account( Id = dao.Builder.getMockId() );
        Account a2 = new Account( Id = dao.Builder.getMockId() );
        Account a3 = new Account( Id = dao.Builder.getMockId() );
        Account a4 = new Account( Id = dao.Builder.getMockId() );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );
        dao.isSuccess = false;

        Set<Id> ids = new Set<Id>{ a2.Id, a3.Id };
        Exception ex = null;

        Test.startTest();
        try {
            dao.fetchAccountsById( ids );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testAccountDAOMock_fetchERSMemberAccountsByMemberId_NoException_CorrectRecordsReturned() {
        AccountDAOMock dao = new AccountDAOMock();

        Account a1 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 1' );
        Account a2 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 2' );
        Account a3 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 3' );
        Account a4 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 4' );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );

        Set<String> memberIds = new Set<String>{ a2.Member_ID__c, a3.Member_ID__c };

        Test.startTest();
        List<Account> accounts = dao.fetchERSMemberAccountsByMemberId( memberIds );
        Test.stopTest();

        System.assertEquals( 2, accounts.size(), 'The amount of records returned is not correct' );
        System.assertEquals( a2.Member_ID__c, accounts[0].Member_ID__c, 'The Member Id of the first Account returned does not match' );
        System.assertEquals( a3.Member_ID__c, accounts[1].Member_ID__c, 'The Member Id of the second Account returned does not match' );
    }

    @IsTest
    public static void testAccountDAOMock_fetchERSMemberAccountsByMemberId_Exception_ExceptionThrown() {
        AccountDAOMock dao = new AccountDAOMock();

        Account a1 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 1' );
        Account a2 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 2' );
        Account a3 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 3' );
        Account a4 = new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 4' );
        dao.accounts.put( a1.Id, a1 );
        dao.accounts.put( a2.Id, a2 );
        dao.accounts.put( a3.Id, a3 );
        dao.accounts.put( a4.Id, a4 );
        dao.isSuccess = false;

        Set<String> memberIds = new Set<String>{ a2.Member_ID__c, a3.Member_ID__c };
        Exception ex = null;

        Test.startTest();
        try {
            dao.fetchERSMemberAccountsByMemberId( memberIds );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testAccountDAOMock_fetchMemberAccountsByMemberId_NoException_CorrectRecordsReturnedAndCallCountIncremented() {
        AccountDAOMock dao = new AccountDAOMock();

        List<Account> returnValue = new List<Account>();
        returnValue.add( new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 1' ) );
        returnValue.add( new Account( Id = dao.Builder.getMockId(), Member_ID__c = 'Member Id 2' ) );
        dao.fetchMemberAccountsByMemberIdReturnValue = returnValue;

        Set<String> memberIds = new Set<String>();

        Assert.areEqual( 0, dao.fetchMemberAccountsByMemberIdCallCount, 'FetchMemberAccountsByMemberIdCallCount is not 0' );

        Test.startTest();
        List<Account> accounts = dao.fetchMemberAccountsByMemberId( memberIds );
        Test.stopTest();

        Assert.areEqual( returnValue, accounts, 'FetchMemberAccountsByMemberId did not return the expected list' );
        Assert.areEqual( 1, dao.fetchMemberAccountsByMemberIdCallCount, 'FetchMemberAccountsByMemberIdCallCount is not 1' );
    }

    @IsTest
    public static void testAccountDAOMock_fetchMemberAccountsByMemberId_Exception_ExceptionThrownAndCallCountIncremented() {
        AccountDAOMock dao = new AccountDAOMock();

        dao.isSuccess = false;

        Set<String> memberIds = new Set<String>();
        Exception ex = null;

        Assert.areEqual( 0, dao.fetchMemberAccountsByMemberIdCallCount, 'FetchMemberAccountsByMemberIdCallCount is not 0' );

        Test.startTest();
        try {
            dao.fetchMemberAccountsByMemberId( memberIds );
            Assert.fail( 'No exception was thrown' );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        Assert.isNotNull( ex, 'No exception was thrown' );
        Assert.areEqual( 1, dao.fetchMemberAccountsByMemberIdCallCount, 'FetchMemberAccountsByMemberIdCallCount is not 1' );
    }
    
    // *********************************************
    // * ServiceMock
    // *********************************************
    public class AccountServiceMock implements FSL_Account.IAccountService {
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in AccountServiceMock' );
            }
        }

        public Integer updateMemberAccountCallCount = 0;
        public void updateMemberAccounts( Map<Id,String> conMapAcct ) {
            ++updateMemberAccountCallCount;
            throwExceptionIfConfigured();
        }

        public Integer getOrCreateMemberPersonAccountsCallCount = 0;
        public List<Account> getOrCreateMemberPersonAccountsReturnValue = new List<Account>();
        
        public List<Account> getOrCreateMemberPersonAccounts( List<FSL_Account.MembershipInformation> membershipInfos ) {
            System.Debug('Creating mock class instance::AccountServiceMock::getOrCreateMemberPersonAccounts');
            getOrCreateMemberPersonAccountsCallCount++;
            System.Debug('Creating mock class instance::AccountServiceMock::getOrCreateMemberPersonAccountsCallCount::' + getOrCreateMemberPersonAccountsCallCount);
            throwExceptionIfConfigured();
            return getOrCreateMemberPersonAccountsReturnValue;
        }

        public Integer getOrCreateContactMemberAccountCallCount = 0;
        public List<Account> getOrCreateContactMemberAccounts = new List<Account>();
        public Map<Contact, Account> getOrCreateMemberAccounts( List<Contact> contacts ) {
            System.Debug('Creating mock class instance::AccountServiceMock::getOrCreateMemberAccounts');
            getOrCreateContactMemberAccountCallCount++;
            System.Debug('Creating mock class instance::AccountServiceMock::getOrCreateContactMemberAccountCallCount::' + getOrCreateContactMemberAccountCallCount);
            throwExceptionIfConfigured();
            Map<Contact, Account> result = new Map<Contact, Account>();
            for( Integer i = 0; i < contacts.size(); i++ ) {
                result.put( contacts[i], i < getOrCreateContactMemberAccounts.size() ? getOrCreateContactMemberAccounts[i] : null );
            }
            return result;
        }

        public Integer getAccountByMemberIdsCallCount = 0;
        public Map<Id, Account> getAccountByMemberIdsReturnValue = new Map<Id, Account>();
        public Map<Id, Account> getAccountByMemberIds( Set<String> memberIds ) {
            System.Debug('Creating mock class instance::AccountServiceMock::getAccountByMemberIds');
            getAccountByMemberIdsCallCount++;
            System.Debug('Creating mock class instance::AccountServiceMock::getAccountByMemberIdsCallCount::' + getAccountByMemberIdsCallCount);
            throwExceptionIfConfigured();
            return getAccountByMemberIdsReturnValue;
        }

        public Integer getAccountMapByMemberIdsCallCount = 0;
        public Map<String, Account> getAccountMapByMemberIdsReturnValue = new Map<String, Account>();
        public Map<String, Account> getAccountMapByMemberIds( Set<String> memberIds ) {
            System.Debug('Creating mock class instance::AccountServiceMock::getAccountMapByMemberIds');
            ++getAccountMapByMemberIdsCallCount;
            System.Debug('Creating mock class instance::AccountServiceMock::getAccountMapByMemberIdsCallCount::' + getAccountMapByMemberIdsCallCount);
            throwExceptionIfConfigured();
            return getAccountMapByMemberIdsReturnValue;
        }

        public Integer deleteAccountsCallCount = 0;
        public void deleteAccounts( Set<Id> ids ) {
            System.Debug('Creating mock class instance::AccountServiceMock::deleteAccounts');
            ++deleteAccountsCallCount;
            throwExceptionIfConfigured();
        }
    }

    @IsTest
    public static void testAccountServiceMock_UpdateMemberAccounts_NoException_CallCountIncremented() {
        AccountServiceMock service = new AccountServiceMock();

        System.assertEquals( 0, service.updateMemberAccountCallCount );

        Test.startTest();
        service.updateMemberAccounts( null );
        Integer callCount1 = service.updateMemberAccountCallCount;

        service.updateMemberAccounts( null );
        Integer callCount2 = service.updateMemberAccountCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testAccountServiceMock_UpdateMemberAccounts_Exception_ExceptionThrownAndCallCountIncremented() {
        AccountServiceMock service = new AccountServiceMock();
        service.throwsException = true;

        Exception ex = null;
        System.assertEquals( 0, service.updateMemberAccountCallCount );

        Test.startTest();
        try {
            service.updateMemberAccounts( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.updateMemberAccountCallCount );
    }

    @IsTest
    public static void testAccountServiceMock_GetOrCreateMemberPersonAccounts_NoException_CallCountIncrementedAndValueReturned() {
        AccountServiceMock service = new AccountServiceMock();

        List<Account> expectedReturnValue = new List<Account>{ new Account() };
        service.getOrCreateMemberPersonAccountsReturnValue = expectedReturnValue;
        
        Test.startTest();
        Integer callCount0 = service.getOrCreateMemberPersonAccountsCallCount;
        List<Account> actualReturnValue = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>() );
        Integer callCount1 = service.getOrCreateMemberPersonAccountsCallCount;
        Test.stopTest();

        Assert.areEqual( 0, callCount0, 'Call Count before test is not 0' );
        Assert.areEqual( expectedReturnValue, actualReturnValue, 'The return value is incorrect' );
        Assert.areEqual( 1, callCount1, 'Call Count is incorrect' );
    }

    @IsTest
    public static void testAccountServiceMock_getOrCreateMemberPersonAccounts_ThrowsException_ExceptionThrown() {
        AccountServiceMock service = new AccountServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        Integer callCount0 = service.getOrCreateMemberPersonAccountsCallCount;
        try {
            service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>() );
            Assert.fail( 'No exception was thrown' );
        }
        catch( Exception e ) {
            ex = e;
        }
        Integer callCount1 = service.getOrCreateMemberPersonAccountsCallCount;
        Test.stopTest();

        Assert.areEqual( 0, callCount0, 'Call Count before test is not 0' );
        Assert.isNotNull( ex, 'No exception was thrown' );
        Assert.areEqual( 1, callCount1, 'Call Count is incorrect' );
    }

    @IsTest
    public static void testAccountServiceMock_GetOrCreateMemberAccounts_NoException_CallCountIncrementedAndValueReturned() {
        AccountServiceMock service = new AccountServiceMock();
        
        Test.startTest();
        Integer callCount0 = service.getOrCreateContactMemberAccountCallCount;

        Map<Contact, Account> defaultReturnValue = service.getOrCreateMemberAccounts( new List<Contact>() );
        Integer callCount1 = service.getOrCreateContactMemberAccountCallCount;

        // Service Mock doesn't have same number of accounts
        Account expectedAccount1 = null;
        Contact c1 = new Contact();
        Map<Contact, Account> contactAccountMap1 = service.getOrCreateMemberAccounts( new List<Contact>{ c1 } );
        Integer callCount2 = service.getOrCreateContactMemberAccountCallCount;
        
        // Service Mock has same number of accounts
        Account expectedAccount2 = new Account();
        service.getOrCreateContactMemberAccounts.add( expectedAccount2 );
        Map<Contact, Account> contactAccountMap2 = service.getOrCreateMemberAccounts( new List<Contact>{ c1 } );
        Integer callCount3 = service.getOrCreateContactMemberAccountCallCount;
        
        // Service Mock has greater number of accounts
        Account ignoredAccount = new Account();
        service.getOrCreateContactMemberAccounts.add( ignoredAccount );
        Map<Contact, Account> contactAccountMap3 = service.getOrCreateMemberAccounts( new List<Contact>{ c1 } );
        Integer callCount4 = service.getOrCreateContactMemberAccountCallCount;
        Test.stopTest();

        System.assertEquals( 0, callCount0 );
        System.assertEquals( 0, defaultReturnValue.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 1, contactAccountMap1.size() );
        System.assertEquals( expectedAccount1, contactAccountMap1.get( c1 ) );
        System.assertEquals( 2, callCount2 );
        System.assertEquals( 1, contactAccountMap2.size() );
        System.assertEquals( expectedAccount2, contactAccountMap2.get( c1 ) );
        System.assertEquals( 3, callCount3 );
        System.assertEquals( 1, contactAccountMap3.size() );
        System.assertEquals( expectedAccount2, contactAccountMap3.get( c1 ) );
        System.assertEquals( 4, callCount4 );
    }

    @IsTest
    public static void testAccountServiceMock_getOrCreateMemberAccounts_ThrowsException_ExceptionThrown() {
        AccountServiceMock service = new AccountServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.getOrCreateMemberAccounts( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testAccountServiceMock_DeleteAccounts_NoException_CallCountIncremented() {
        AccountServiceMock service = new AccountServiceMock();

        System.assertEquals( 0, service.deleteAccountsCallCount );

        Test.startTest();
        service.deleteAccounts( null );
        Integer callCount1 = service.deleteAccountsCallCount;

        service.deleteAccounts( null );
        Integer callCount2 = service.deleteAccountsCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testAccountServiceMock_DeleteAccounts_Exception_ExceptionThrownAndCallCountIncremented() {
        AccountServiceMock service = new AccountServiceMock();
        service.throwsException = true;

        Exception ex = null;
        System.assertEquals( 0, service.deleteAccountsCallCount );

        Test.startTest();
        try {
            service.deleteAccounts( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.deleteAccountsCallCount );
    }

    //Varun Changes Start
    // These changes are for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238
    @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_firstTime(){
        createPersonAccountFromD3Payload('{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-100001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382122694719024","originalMemberId": "4382122694719024","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719024","contactType": "CUSTOMER","title": "MR","suffix": "Jr","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANK AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}');

        // There is only single person account with name MICHAEL and no duplicate is created
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 1);
    }

    @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_findExistingWithMemberID(){
        
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];

        // There is only single person account with name MICHAEL and no duplicate is created
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 1);
    }

    @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_findExistingWithSecondCondition(){
        
        ///Create a member record first
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();

        // Provide a different Membership ID so the system will search person by First name, last name and email id
        createPersonAccountFromD3Payload('{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-100001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382122694719034","originalMemberId": "4382122694719034","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719034","contactType": "CUSTOMER","title": "MR","suffix": "Jr","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANK AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}');
        
         // There is only single person account with name MICHAEL and no duplicate is created
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 2);
    }

    @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_findExistingWithThirdCondition(){
        
        ///Create a member record first
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();

        // Provide a different Membership ID and email id so that so the system will search person by First name, last name, title, suffix and address
        createPersonAccountFromD3Payload('{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-100001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382122694719034","originalMemberId": "4382122694719034","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719034","contactType": "CUSTOMER","title": "MR","suffix": "Jr","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills1@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANK AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}');
        
         // There is only single person account with name MICHAEL and no duplicate is created
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 2);
    }

    @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_findExistingWithFourthCondition(){
        
        ///Create a member record first
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();

        // Provide a different Membership ID, email id and suffix so that so the system will search person by First name, last name, title and address
        createPersonAccountFromD3Payload('{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-100001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382122694719034","originalMemberId": "4382122694719034","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719034","contactType": "CUSTOMER","title": "MR","suffix": "Jr1","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills1@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANK AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}');
        
         // There is only single person account with name MICHAEL and no duplicate is created
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 2);
    }

     @isTest
    public static void testAccountService_getOrCreateMemberPersonAccounts_findExistingWithFifthCondition(){
        
        ///Create a member record first
        testAccountService_getOrCreateMemberPersonAccounts_firstTime();

        // Provide a different Membership ID, email id and suffix so that so the system will search person by First name, last name, title and address
        createPersonAccountFromD3Payload('{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-100001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382122694719034","originalMemberId": "4382122694719034","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719034","contactType": "CUSTOMER","title": "MR1","suffix": "Jr1","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills1@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANK AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}');
        
         // There is only single person account with name MICHAEL and no duplicate is created
        List<Account> accounts= [select id from Account where Name = 'MICHAEL MILLS'];
        Assert.isNotNull(accounts.size());
        Assert.isTrue(accounts.size() == 2);
    }

    public static void createPersonAccountFromD3Payload(string inputD3JSON){
        FSL_JSonParserWorkOrder jsonParser = new FSL_JSonParserWorkOrder();
        FSL_Account.IFactory accountFactory = new FSL_Account.Factory();
        // sent the sme request with different membership id so that we locate the person account by first name, last name and the email id
        try {
            jsonParser  = (FSL_JSonParserWorkOrder)Json.deserialize(inputD3JSON,FSL_JSonParserWorkOrder.class);
            System.Debug(jsonParser);    
        } catch(Exception ex) {System.Debug(ex);}        
        
        // Creating membership Person Account
        FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
        FSL_Account.IAccountService service = accountFactory.createService();

        FSL_Account.MembershipInformation info = parser.parse( jsonParser.calls[0] );
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );
    }

    //Varun Changes End
    
    // *********************************************
    // * MembershipInformationParserMock
    // *********************************************
    public class MembershipInformationParserMock extends FSL_Account.MembershipInformationParser {
        public Integer parseJsonParserWorkOrderCallCount = 0;
        public FSL_Account.MembershipInformation parseJsonParserWorkOrderReturnValue = null;
        public override FSL_Account.MembershipInformation parse( FSL_JSonParserWorkOrder.Calls call ) {
            parseJsonParserWorkOrderCallCount++;
            return parseJsonParserWorkOrderReturnValue;
        }

        public Integer parseIntFslWorkOrderRequestWrapperCallCount = 0;
        public FSL_Account.MembershipInformation parseIntFslWorkOrderRequestWrapperReturnValue = null;
        public override FSL_Account.MembershipInformation parse( INTFSLWorkOrderRequest_Wrapper call ) {
            parseIntFslWorkOrderRequestWrapperCallCount++;
            return parseIntFslWorkOrderRequestWrapperReturnValue;
        }
    }
}