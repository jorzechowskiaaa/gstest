/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        02/23/2021   Dylan Truong         ERS-221208 - Subtask: ERS-221216  Update Contact trigger to update/create account when membership number updated
 *   2.0    5/14/2020   Dylan Truong         ERS-221083 MembershipValidation Phrase 2: Partial Search
 */
@isTest
public inherited sharing class FSL_ContactTest {

    private static final Schema.SObjectType CONTACT_TYPE = Schema.Contact.getSObjectType();
    private static final Id CONTACT_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    private static final Id ACCOUNT_ERS_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ERS Member').getRecordTypeId();

    // @testSetup
    // Since the majority of the tests don't need this data, call this method explicitly in those that need it
    public static void dataSetup() {
    
      Id communityRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Community User').getRecordTypeId();
      List <Contact> contactData = new List<Contact>();
      contactData.add(new Contact(Member_Card_Num__c = '1234567890123451', FirstName='Test', LastName='Contact 1', RecordTypeId=CONTACT_RECORD_TYPE_ID));
      contactData.add(new Contact(Member_Card_Num__c = '1234567890123452', FirstName='Test', LastName='Contact 2', RecordTypeId=CONTACT_RECORD_TYPE_ID));
      contactData.add(new Contact(FirstName='Test', LastName='Contact 3', RecordTypeId=communityRecordTypeId));
      contactData.add(new Contact(FirstName='Test', LastName='Contact 4', RecordTypeId=CONTACT_RECORD_TYPE_ID));
      insert contactData;

      List<Account> accounts = new List<Account>();
      accounts.add(new Account(Name = 'Contact 5', Member_ID__c='1234567890123455'));
      insert accounts;
    }
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_Contact.IFactory factory = new FSL_Contact.Factory();

        Test.startTest();
        FSL_Contact.IContactService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testContactDAO_FetchContactsById_CorrectRecordsReturned() {
        FSL_Contact.IContactDAO dao = new FSL_Contact.ContactDAO();
        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact( LastName = 'LastName1' ) );
        contacts.add( new Contact( LastName = 'LastName2' ) );
        contacts.add( new Contact( LastName = 'LastName3' ) );
        contacts.add( new Contact( LastName = 'LastName4' ) );
        insert contacts;

        Test.startTest();
        List<Contact> fetchedContacts = dao.fetchContactsById( new Set<Id>{ contacts[1].Id, contacts[2].Id } );
        Test.stopTest();

        System.assertEquals( 2, fetchedContacts.size() );
        System.assertEquals( contacts[1].Id, fetchedContacts[0].Id );
        System.assertEquals( contacts[2].Id, fetchedContacts[1].Id );
    }

    @IsTest
    public static void testContactDAO_FetchContactsByMembershipNumber_CorrectRecordsReturned() {
        FSL_Contact.IContactDAO dao = new FSL_Contact.ContactDAO();
        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact( LastName = 'LastName1', Member_Card_Num__c = '123' ) );
        contacts.add( new Contact( LastName = 'LastName2', Member_Card_Num__c = '234' ) );
        contacts.add( new Contact( LastName = 'LastName3', Member_Card_Num__c = '345' ) );
        contacts.add( new Contact( LastName = 'LastName4', Member_Card_Num__c = '456' ) );
        insert contacts;

        Test.startTest();
        List<Contact> fetchedContacts = dao.fetchContactsByMembershipNumber( new Set<String>{ contacts[1].Member_Card_Num__c, contacts[2].Member_Card_Num__c } );
        Test.stopTest();

        System.assertEquals( 2, fetchedContacts.size() );
        System.assertEquals( contacts[1].Member_Card_Num__c, fetchedContacts[0].Member_Card_Num__c );
        System.assertEquals( contacts[2].Member_Card_Num__c, fetchedContacts[1].Member_Card_Num__c );
    }

    @IsTest
    public static void testContactDAO_FetchContactsByPhoneNumber_CorrectRecordsReturned() {
        FSL_Contact.IContactDAO dao = new FSL_Contact.ContactDAO();
        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact( LastName = 'LastName1', MobilePhone = '123' ) );
        contacts.add( new Contact( LastName = 'LastName2', MobilePhone = '234' ) );
        contacts.add( new Contact( LastName = 'LastName3', MobilePhone = '345' ) );
        contacts.add( new Contact( LastName = 'LastName4', MobilePhone = '456' ) );
        insert contacts;

        Set<String> phoneNumbers = new Set<String>{ contacts[1].MobilePhone, contacts[2].MobilePhone };

        Test.startTest();
        List<Contact> fetchedContacts = dao.fetchContactsByPhoneNumber( phoneNumbers );
        Test.stopTest();

        System.assertEquals( 2, fetchedContacts.size() );
        System.assert( phoneNumbers.contains( fetchedContacts[0].Searchable_Phone_Number__c ) );
        System.assert( phoneNumbers.contains( fetchedContacts[1].Searchable_Phone_Number__c ) );
    }
    
    // *********************************************
    // * Service
    // *********************************************
    private static FSL_JSonParserWorkOrder.Calls createJsonParserWorkOrderCall() {
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        call.channel = new FSL_JSonParserWorkOrder.Channel();
        call.customer = new FSL_JSonParserWorkOrder.Customer();
        call.customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{ new FSL_JSonParserWorkOrder.Memberships() };

        return call;
    }

    @isTest
    public static void testContactService_CreateContacts_MembershipNumberOnlyNonExistent_Created() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.customer.memberships[0].id = '1234567890123456';

        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( 1, contacts.size() );
        System.assertEquals( 1, dao.contacts.size() );
        System.assertEquals( contacts[0], dao.contacts.get( contacts[0].Id ) );
        System.assertEquals( call.customer.memberships[0].id, contacts[0].Member_Card_Num__c );
        System.assertEquals( memberContactRecordTypeId, contacts[0].RecordTypeId );
        System.assertEquals( 1, accountService.getOrCreateContactMemberAccountCallCount );
        System.assertEquals( a.Id, contacts[0].AccountId );
    }

    @isTest
    public static void testContactService_CreateContacts_MembershipNumberOnlyAlreadyExists_QueriedAndUpdated() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.customer.memberships[0].id = '1234567890123456';

        Contact c = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '1234567890123456' );
        dao.contacts.put( c.Id, c );
        System.assertEquals( 1, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( 1, contacts.size() );
        System.assertEquals( 1, dao.contacts.size() );
        System.assertEquals( contacts[0], dao.contacts.get( contacts[0].Id ) );
        System.assertEquals( call.customer.memberships[0].id, contacts[0].Member_Card_Num__c );
        System.assertEquals( 1, accountService.getOrCreateContactMemberAccountCallCount );
        System.assertEquals( a.Id, contacts[0].AccountId );
    }

    @isTest
    public static void testContactService_CreateContacts_FullDataNonExistent_Created() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.channel.contact.userId = 'User ID';
        call.customer.contact = new FSL_JSonParserWorkOrder.Contact_customer();
        call.customer.contact.contactType = 'Contact Type';
        call.customer.contact.emails = new List<FSL_JSonParserWorkOrder.Emails>{ new FSL_JSonParserWorkOrder.Emails() };
        call.customer.contact.emails[0].address = 'Email Address';
        call.customer.contact.emails[0].emailType = 'Email Type';
        call.customer.contact.firstName = 'Contact First Name';
        call.customer.contact.lastName = 'Contact Last Name';
        call.customer.contact.phones = new List<FSL_JSonParserWorkOrder.Phones>{ new FSL_JSonParserWorkOrder.Phones() };
        call.customer.contact.phones[0].phoneExtension = 'Phone Extension';
        call.customer.contact.phones[0].phoneNumber = 'Phone Number';
        call.customer.contact.phones[0].phoneType = 'Phone Type';
        call.customer.contact.phones[0].smsOptIn = true;
        call.customer.contact.title = 'Contact Title';
        call.customer.languagePreference = 'Language Preference';
        call.customer.memberships[0].authorizationCode = 'Authorization Code';
        call.customer.memberships[0].authorizationLevel = 'Authorization Level';
        call.customer.memberships[0].expirationDate = '2022-02-18';
        call.customer.memberships[0].id = '1234567890123456';
        call.customer.memberships[0].isLocalClub = true;
        call.customer.memberships[0].memberBirthday = 'Member Birthday';
        call.customer.memberships[0].memberLevel = 'Member Level';
        call.customer.memberships[0].membershipType = 'Membership Type';
        call.customer.memberships[0].memberSince = '12';
        call.customer.memberships[0].memberStatus = 'Member Status';
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.customer.memberships[0].org.code = 'Org Code';
        call.customer.memberships[0].org.name = 'Org Name';
        call.customer.memberships[0].program = 'Membership Program';
        call.customer.memberships[0].programName = 'Program Name';
        call.customer.memberships[0].programPhone = '1234567890';
        call.customer.memberships[0].sponsor = 'Membership Sponsor';
        
        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( 1, contacts.size() );
        System.assertEquals( 1, dao.contacts.size() );
        System.assertEquals( contacts[0], dao.contacts.get( contacts[0].Id ) );
        System.assertEquals( call.customer.memberships[0].id, contacts[0].Member_Card_Num__c );
        System.assertEquals( memberContactRecordTypeId, contacts[0].RecordTypeId );
        System.assertEquals( 1, accountService.getOrCreateContactMemberAccountCallCount );
        System.assertEquals( a.Id, contacts[0].AccountId );

        System.assertEquals( call.customer.memberships[0].membershipType, contacts[0].Membership_Type__c );
        System.assertEquals( call.customer.memberships[0].sponsor, contacts[0].Membership_Sponsor__c );
        System.assertEquals( call.customer.memberships[0].program, contacts[0].Membership_Program__c );
        System.assertEquals( call.customer.memberships[0].authorizationCode, contacts[0].Membership_Code__c );
        System.assertEquals( call.customer.memberships[0].authorizationLevel, contacts[0].Membership_Authorization__c );
        System.assertEquals( call.customer.memberships[0].isLocalClub, contacts[0].Membership_Islocalclub__c );
        System.assertEquals( call.customer.memberships[0].memberLevel, contacts[0].Membership_Level__c );
        System.assertEquals( call.customer.memberships[0].memberBirthday, contacts[0].Membership_Birthday__c );
        System.assertEquals( call.customer.memberships[0].memberStatus, contacts[0].Membership_Status__c );
        System.assertEquals( call.customer.memberships[0].memberSince, contacts[0].Membership_Since__c );
        System.assertEquals( Date.valueOf( call.customer.memberships[0].expirationDate ), contacts[0].Membership_Expiration_Date__c );
        System.assertEquals( call.customer.memberships[0].programPhone, contacts[0].Membership_Org_Phone__c );
        System.assertEquals( call.customer.memberships[0].programName, contacts[0].Membership_Org__c );
        System.assertEquals( call.customer.memberships[0].org.code, contacts[0].Membership_OrgCode__c );
        System.assertEquals( call.customer.languagePreference, contacts[0].Language_Preference__c );
        System.assertEquals( call.channel.contact.userId, contacts[0].External_ID__c );
        System.assertEquals( call.customer.contact.contactType, contacts[0].Type__c );
        System.assertEquals( call.customer.contact.title, contacts[0].Title );
        System.assertEquals( call.customer.contact.firstName, contacts[0].FirstName );
        System.assertEquals( call.customer.contact.lastName, contacts[0].LastName );
        System.assertEquals( call.customer.contact.phones[0].phoneNumber, contacts[0].MobilePhone );
        System.assertEquals( call.customer.contact.phones[0].phoneNumber, contacts[0].Phone );
        System.assertEquals( call.customer.contact.phones[0].phoneType, contacts[0].Phone_Type__c );
        System.assertEquals( call.customer.contact.phones[0].phoneExtension, contacts[0].Phone_Extension__c );
        System.assertEquals( call.customer.contact.phones[0].smsOptIn, contacts[0].Sms_Optin__c );
        System.assertEquals( call.customer.contact.emails[0].emailType, contacts[0].Email_Type__c );
        System.assertEquals( call.customer.contact.emails[0].address, contacts[0].Email );
    }

    @isTest
    public static void testContactService_CreateContacts_FullDataAlreadyExists_QueriedAndUpdated() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.channel.contact.userId = 'User ID';
        call.customer.contact = new FSL_JSonParserWorkOrder.Contact_customer();
        call.customer.contact.contactType = 'Contact Type';
        call.customer.contact.emails = new List<FSL_JSonParserWorkOrder.Emails>{ new FSL_JSonParserWorkOrder.Emails() };
        call.customer.contact.emails[0].address = 'Email Address';
        call.customer.contact.emails[0].emailType = 'Email Type';
        call.customer.contact.firstName = 'Contact First Name';
        call.customer.contact.lastName = 'Contact Last Name';
        call.customer.contact.phones = new List<FSL_JSonParserWorkOrder.Phones>{ new FSL_JSonParserWorkOrder.Phones() };
        call.customer.contact.phones[0].phoneExtension = 'Phone Extension';
        call.customer.contact.phones[0].phoneNumber = 'Phone Number';
        call.customer.contact.phones[0].phoneType = 'Phone Type';
        call.customer.contact.phones[0].smsOptIn = true;
        call.customer.contact.title = 'Contact Title';
        call.customer.languagePreference = 'Language Preference';
        call.customer.memberships[0].authorizationCode = 'Authorization Code';
        call.customer.memberships[0].authorizationLevel = 'Authorization Level';
        call.customer.memberships[0].expirationDate = '2022-02-18';
        call.customer.memberships[0].id = '1234567890123456';
        call.customer.memberships[0].isLocalClub = true;
        call.customer.memberships[0].memberBirthday = 'Member Birthday';
        call.customer.memberships[0].memberLevel = 'Member Level';
        call.customer.memberships[0].membershipType = 'Membership Type';
        call.customer.memberships[0].memberSince = '12';
        call.customer.memberships[0].memberStatus = 'Member Status';
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.customer.memberships[0].org.code = 'Org Code';
        call.customer.memberships[0].org.name = 'Org Name';
        call.customer.memberships[0].program = 'Membership Program';
        call.customer.memberships[0].programName = 'Program Name';
        call.customer.memberships[0].programPhone = '1234567890';
        call.customer.memberships[0].sponsor = 'Membership Sponsor';
        
        Contact c = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '1234567890123456' );
        dao.contacts.put( c.Id, c );
        System.assertEquals( 1, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( 1, contacts.size() );
        System.assertEquals( 1, dao.contacts.size() );
        System.assertEquals( contacts[0], dao.contacts.get( contacts[0].Id ) );
        System.assertEquals( call.customer.memberships[0].id, contacts[0].Member_Card_Num__c );
        System.assertEquals( 1, accountService.getOrCreateContactMemberAccountCallCount );
        System.assertEquals( a.Id, contacts[0].AccountId );

        System.assertEquals( call.customer.memberships[0].membershipType, contacts[0].Membership_Type__c );
        System.assertEquals( call.customer.memberships[0].sponsor, contacts[0].Membership_Sponsor__c );
        System.assertEquals( call.customer.memberships[0].program, contacts[0].Membership_Program__c );
        System.assertEquals( call.customer.memberships[0].authorizationCode, contacts[0].Membership_Code__c );
        System.assertEquals( call.customer.memberships[0].authorizationLevel, contacts[0].Membership_Authorization__c );
        System.assertEquals( call.customer.memberships[0].isLocalClub, contacts[0].Membership_Islocalclub__c );
        System.assertEquals( call.customer.memberships[0].memberLevel, contacts[0].Membership_Level__c );
        System.assertEquals( call.customer.memberships[0].memberBirthday, contacts[0].Membership_Birthday__c );
        System.assertEquals( call.customer.memberships[0].memberStatus, contacts[0].Membership_Status__c );
        System.assertEquals( call.customer.memberships[0].memberSince, contacts[0].Membership_Since__c );
        System.assertEquals( Date.valueOf( call.customer.memberships[0].expirationDate ), contacts[0].Membership_Expiration_Date__c );
        System.assertEquals( call.customer.memberships[0].programPhone, contacts[0].Membership_Org_Phone__c );
        System.assertEquals( call.customer.memberships[0].programName, contacts[0].Membership_Org__c );
        System.assertEquals( call.customer.memberships[0].org.code, contacts[0].Membership_OrgCode__c );
        System.assertEquals( call.customer.languagePreference, contacts[0].Language_Preference__c );
        System.assertEquals( call.channel.contact.userId, contacts[0].External_ID__c );
        System.assertEquals( call.customer.contact.contactType, contacts[0].Type__c );
        System.assertEquals( call.customer.contact.title, contacts[0].Title );
        System.assertEquals( call.customer.contact.firstName, contacts[0].FirstName );
        System.assertEquals( call.customer.contact.lastName, contacts[0].LastName );
        System.assertEquals( call.customer.contact.phones[0].phoneNumber, contacts[0].MobilePhone );
        System.assertEquals( call.customer.contact.phones[0].phoneNumber, contacts[0].Phone );
        System.assertEquals( call.customer.contact.phones[0].phoneType, contacts[0].Phone_Type__c );
        System.assertEquals( call.customer.contact.phones[0].phoneExtension, contacts[0].Phone_Extension__c );
        System.assertEquals( call.customer.contact.phones[0].smsOptIn, contacts[0].Sms_Optin__c );
        System.assertEquals( call.customer.contact.emails[0].emailType, contacts[0].Email_Type__c );
        System.assertEquals( call.customer.contact.emails[0].address, contacts[0].Email );
    }

    @isTest
    public static void testContactService_CreateContacts_MembershipNumberIs102AndProgramNameNull_CreatedWithNullMemberCardNum() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.channel.contact.userId = 'User ID';
        String authorizationCode = 'Authorization Code';
        String authorizationLevel = 'Authorization Level';
        String expirationDate = '2022-02-18';
        Boolean isLocalClub = true;
        String memberBirthday = 'Member Birthday';
        String memberLevel = 'Member Level';
        String membershipType = 'Membership Type';
        String memberSince = '12';
        String memberStatus = 'Member Status';
        String program = 'Membership Program';
        String sponsor = 'Membership Sponsor';
        call.customer.memberships[0].authorizationCode = authorizationCode;
        call.customer.memberships[0].authorizationLevel = authorizationLevel;
        call.customer.memberships[0].expirationDate = expirationDate;
        call.customer.memberships[0].id = '102';
        call.customer.memberships[0].isLocalClub = isLocalClub;
        call.customer.memberships[0].memberBirthday = memberBirthday;
        call.customer.memberships[0].memberLevel = memberLevel;
        call.customer.memberships[0].membershipType = membershipType;
        call.customer.memberships[0].memberSince = memberSince;
        call.customer.memberships[0].memberStatus = memberStatus;
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.customer.memberships[0].org.name = 'Org Name';
        call.customer.memberships[0].program = program;
        call.customer.memberships[0].sponsor = sponsor;
        
        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( null, contacts[0].Member_Card_Num__c );
        System.assertEquals( sponsor, contacts[0].Membership_Sponsor__c );
        System.assertEquals( program, contacts[0].Membership_Program__c );
        System.assertEquals( authorizationCode, contacts[0].Membership_Code__c );
        System.assertEquals( authorizationLevel, contacts[0].Membership_Authorization__c );
        System.assertEquals( isLocalClub, contacts[0].Membership_Islocalclub__c );
        System.assertEquals( memberLevel, contacts[0].Membership_Level__c );
        System.assertEquals( memberBirthday, contacts[0].Membership_Birthday__c );
        System.assertEquals( memberStatus, contacts[0].Membership_Status__c );
        System.assertEquals( memberSince, contacts[0].Membership_Since__c );
        System.assertEquals( membershipType, contacts[0].Membership_Type__c );
        System.assertEquals( Date.Valueof( expirationDate ), contacts[0].Membership_Expiration_Date__c );
        System.assertEquals( call.customer.memberships[0].org.name, contacts[0].Membership_Org__c );
    }

    @isTest
    public static void testContactService_CreateContacts_MembershipNumberIs105AndOtherFieldsNull_CreatedWithNullMemberCardNum() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.channel.contact.userId = 'User ID';
        call.customer.memberships[0].id = '105';
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.customer.memberships[0].org.name = 'Org Name';
        
        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( null, contacts[0].Member_Card_Num__c );
        System.assertEquals( null, contacts[0].Membership_Sponsor__c );
        System.assertEquals( null, contacts[0].Membership_Program__c );
        System.assertEquals( null, contacts[0].Membership_Code__c );
        System.assertEquals( null, contacts[0].Membership_Authorization__c );
        System.assertEquals( false, contacts[0].Membership_Islocalclub__c );
        System.assertEquals( null, contacts[0].Membership_Level__c );
        System.assertEquals( null, contacts[0].Membership_Birthday__c );
        System.assertEquals( null, contacts[0].Membership_Status__c );
        System.assertEquals( null, contacts[0].Membership_Since__c );
        System.assertEquals( null, contacts[0].Membership_Type__c );
        System.assertEquals( null, contacts[0].Membership_Expiration_Date__c );
        System.assertEquals( call.customer.memberships[0].org.name, contacts[0].Membership_Org__c );
    }

    @isTest
    public static void testContactService_CreateContacts_ValidMembershipAndMemberSinceLessThanTen_CreatedWithPaddedMemberSinceField() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.channel.contact.userId = 'User ID';
        call.customer.memberships[0].expirationDate = '2022-02-18';
        call.customer.memberships[0].id = '1234567890123456';
        call.customer.memberships[0].memberSince = '2';
        call.customer.memberships[0].org = new FSL_JSonParserWorkOrder.SystemOrganziation();
        call.customer.memberships[0].org.name = 'Org Name';
        
        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( '1234567890123456', contacts[0].Member_Card_Num__c );
        System.assertEquals( '0' + call.customer.memberships[0].memberSince, contacts[0].Membership_Since__c );
        System.assertEquals( call.customer.memberships[0].org.name, contacts[0].Membership_Org__c );
    }

    @isTest
    public static void testContactService_CreateContacts_IntegrationUserIsSandbox_PhoneAndEmailMasked() {
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        String maskedPhone = '5555555555';
        String maskedEmail = 'masked@email.com';
        FSL_Integration_User__c integrationUser = new FSL_Integration_User__c( Name = 'Integration User', isSandbox__c = true, Sandbox_Phone__c = maskedPhone, Sandbox_Email__c = maskedEmail );
        insert integrationUser;

        Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        accountService.getOrCreateContactMemberAccounts.add( a );

        FSL_JSonParserWorkOrder.Calls call = createJsonParserWorkOrderCall();
        call.channel.contact = new FSL_JSonParserWorkOrder.Contact();
        call.customer.contact = new FSL_JSonParserWorkOrder.Contact_customer();
        call.customer.contact.emails = new List<FSL_JSonParserWorkOrder.Emails>{ new FSL_JSonParserWorkOrder.Emails() };
        call.customer.contact.emails[0].address = 'Email Address';
        call.customer.contact.phones = new List<FSL_JSonParserWorkOrder.Phones>{ new FSL_JSonParserWorkOrder.Phones() };
        call.customer.contact.phones[0].phoneNumber = 'Phone Number';
        call.customer.memberships[0].id = '1234567890123456';
        
        Id memberContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        System.assertEquals( 0, dao.contacts.size() );

        Test.startTest();
        List<Contact> contacts = service.createContacts( New List<FSL_JSonParserWorkOrder.Calls>{ call } );
        Test.stopTest();

        System.assertEquals( maskedPhone, contacts[0].Phone );
        System.assertEquals( maskedEmail, contacts[0].Email );
    }

    @IsTest
    public static void testContactService_DeleteOrphanMemberContacts_DeletedAndCascadedToAccountService() {
        // Since the deletion involves a Batchable, it can't be done using a DAO Mock
        FSL_Contact.IContactDAO dao = new FSL_Contact.ContactDAO();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        // Test data description
        // 1. Orphan Contact/Account pair slightly younger than CreatedDate (same day, different hour)
        // 2. Orphan Contact/Account pair younger than CreatedDate (earlier day)
        // 3. Orphan Contact/Account pair older than CreatedDate (expected to be purged)
        // 4. Orphan Contact/Account pair but different Record Type
        // 5. Orphan Account, but Contact older than CreatedDate still used by a Work Order
        // 6. Orphan Contact older than CreatedDate, but Account still used by a Work Order
        // 7. Contact/Account used by test data 5 and 6
        // 8. Contact used by a Case

        List<Account> accounts = new List<Account>();
        accounts.add( new Account( Name = 'Account 1' ) );
        accounts.add( new Account( Name = 'Account 2' ) );
        accounts.add( new Account( Name = 'Account 3' ) );
        accounts.add( new Account( Name = 'Account 4' ) );
        accounts.add( new Account( Name = 'Account 5' ) );
        accounts.add( new Account( Name = 'Account 6' ) );
        accounts.add( new Account( Name = 'Account 7' ) );
        accounts.add( new Account( Name = 'Account 8' ) );
        insert accounts;

        Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        Id communityRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Community User').getRecordTypeId();
        List<Contact> contacts = new List<Contact>();
        contacts.add( new Contact( LastName = 'LastName 1', RecordTypeId = memberRecordTypeId, AccountId = accounts[0].Id ) );
        contacts.add( new Contact( LastName = 'LastName 2', RecordTypeId = memberRecordTypeId, AccountId = accounts[1].Id ) );
        contacts.add( new Contact( LastName = 'LastName 3', RecordTypeId = memberRecordTypeId, AccountId = accounts[2].Id ) );
        contacts.add( new Contact( LastName = 'LastName 4', RecordTypeId = communityRecordTypeId, AccountId = accounts[3].Id ) );
        contacts.add( new Contact( LastName = 'LastName 5', RecordTypeId = memberRecordTypeId, AccountId = accounts[4].Id ) );
        contacts.add( new Contact( LastName = 'LastName 6', RecordTypeId = memberRecordTypeId, AccountId = accounts[5].Id ) );
        contacts.add( new Contact( LastName = 'LastName 7', RecordTypeId = memberRecordTypeId, AccountId = accounts[6].Id ) );
        contacts.add( new Contact( LastName = 'LastName 8', RecordTypeId = memberRecordTypeId, AccountId = accounts[7].Id ) );
        insert contacts;

        Integer daysToRetain = 15;
        Datetime createdDatetime = Datetime.now().addDays( -daysToRetain );
        Date createdDate = createdDatetime.date();
        Test.setCreatedDate( contacts[0].Id, createdDatetime );
        Test.setCreatedDate( contacts[1].Id, createdDatetime.addDays( 1 ) );
        Test.setCreatedDate( contacts[2].Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( contacts[3].Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( contacts[4].Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( contacts[5].Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( contacts[6].Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( contacts[7].Id, createdDatetime.addDays( -1 ) );

        List<WorkOrder> workOrders = new List<WorkOrder>();
        workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[4] ) );
        workOrders[0].Member_Account__c = accounts[6].Id;
        workOrders[0].External_Id__c = 'ERS-1';
        workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[5] ) );
        workOrders[1].ContactId = contacts[6].Id;
        workOrders[1].External_Id__c = 'ERS-2';
        insert workOrders;

        List<Case> cases = new List<Case>();
        cases.add( FSL_DataFactory.createCase( 'Clear Queue Failure' ) );
        cases[0].ContactId = contacts[7].Id;
        insert cases;

        contacts = [SELECT Id, CreatedDate, RecordTypeId, AccountId FROM Contact];
        System.assertEquals( 8, contacts.size(), 'Arrange: the number of Contact records returned is incorrect' );

        accounts = [SELECT Id FROM Account];
        System.assertEquals( 8, contacts.size(), 'Arrange: the number of Account records returned is incorrect' );

        Test.startTest();
        service.deleteOrphanMemberContacts( daysToRetain );
        Test.stopTest();

        contacts = [SELECT Id, CreatedDate, RecordTypeId, AccountId FROM Contact];
        System.assertEquals( 7, contacts.size(), 'Assert: the number of Contact records returned is incorrect' );

        accounts = [SELECT Id FROM Account];
        System.assertEquals( 7, contacts.size(), 'Assert: the number of Account records returned is incorrect' );
    }

    //New Merge Section from Dylan
    @IsTest
    static void testOnBeforeInsertWithDBCall_NonExistentAccountMember(){
        dataSetup();
        Test.startTest();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(new Contact(Member_Card_Num__c = '1234567890123456', FirstName='Test', LastName='Contact 6', RecordTypeId=CONTACT_RECORD_TYPE_ID));
        contactService.onBeforeInsert(newContacts);
        System.debug('testOnBeforeNonExistentAccountMember ==>' + newContacts);
        System.assertEquals(true, String.isNotBlank(newContacts[0].AccountId));
        Test.stopTest();
        
    }
    @IsTest
    static void testOnBeforeWithInsertDBCall_ExistentAccountMember(){
        dataSetup();
        Test.startTest();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(new Contact(Member_Card_Num__c = '1234567890123455', FirstName='Test', LastName='Contact 7', RecordTypeId=CONTACT_RECORD_TYPE_ID));
        contactService.onBeforeInsert(newContacts);
        
        FSL_Account.AccountDAO accountDao = new FSL_Account.AccountDAO();
        Set<String> memberIds = new Set<String>();
        memberIds.add('1234567890123455');
        /*
        List<Account> account = accountDao.fetchAccountsByMemberId(memberIds);
        System.debug('testOnBeforeWithDBCall_ExistentAccountMember ==>' + newContacts);
        System.assertEquals(account[0].Id, newContacts[0].AccountId);
        Test.stopTest();
        */
    }
    @IsTest
    static void testOnBeforeWithInsertDBCall_NoMemberId(){
        dataSetup();
        Test.startTest();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(new Contact(FirstName='Test', LastName='Contact 8', RecordTypeId=CONTACT_RECORD_TYPE_ID));
        contactService.onBeforeInsert(newContacts);
        System.debug('testOnBeforeWithDBCall_NoMemberId ==>' + newContacts);
        System.assertEquals(true, String.isNotBlank(newContacts[0].AccountId));
        Test.stopTest();
        
    }
    @IsTest
    static void testOnBeforeInsertWithDBCall_NotMemberRecordType(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        List<Contact> newContacts = new List<Contact>();
        String communityRecordTypeId = '0121U000001HvwXQAS';
        Test.startTest();
        newContacts.add(new Contact(FirstName='Test', LastName='Contact 8', RecordTypeId=communityRecordTypeId));
        contactService.onBeforeInsert(newContacts);
        System.debug('testOnBeforeWithDBCall_NoMemberId ==>' + newContacts);
        System.assertEquals(true, String.isBlank(newContacts[0].AccountId));
        Test.stopTest();
        
    }
    @IsTest
    static void testOnBeforeInsertWithDBCall_ExistentMemberNumber(){
        dataSetup();
        Test.startTest();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(new Contact(FirstName='Test', LastName='Contact 8', Member_Card_Num__c='1234567890123451', RecordTypeId=CONTACT_RECORD_TYPE_ID));
        try{
            contactService.onBeforeInsert(newContacts);

        }catch (Exception e)
        {
            System.assertEquals(true, String.isNotBlank(e.getMessage()));
            System.debug('testOnBeforeInsertWithDBCall_ExistentMemberNumber Exception ==>' + e.getMessage());
        }
        Test.stopTest();
        
    }
    @IsTest
    static void testOnBeforeUpdateDBCall_ValidMemberNumber(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        Test.startTest();
        Map<Id,Contact> oldContacts = new Map<Id,Contact>([SELECT Id, Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE Member_Card_Num__c = '1234567890123451']);
        Map<Id,Contact> newContacts = new Map<Id,Contact>([SELECT Id,Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE Member_Card_Num__c = '1234567890123451' ]);
        newContacts.values()[0].Member_Card_Num__c = '1234567890123459';
        try{
            contactService.onBeforeUpdate(oldContacts, newContacts);
        }catch (Exception e){
            System.assertEquals(true, String.isNotBlank(e.getMessage()));
        }
        Test.stopTest();        
    }

    @IsTest
    static void testOnBeforeUpdateDBCall_NewMemberNumberAlreadyExistInAccount(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        Test.startTest();
        Map<Id,Contact> oldContacts = new Map<Id,Contact>([SELECT Id, Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        Map<Id,Contact> newContacts = new Map<Id,Contact>([SELECT Id,Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        newContacts.values()[0].Member_Card_Num__c = '1234567890123455';
        contactService.onBeforeUpdate(oldContacts, newContacts);
        System.assertEquals(true, String.isNotBlank(newContacts.values()[0].AccountId));
        Test.stopTest();        
    }

    @IsTest
    static void testOnBeforeUpdateDBCall_NewMemberNumberAlreadyExistInContact(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        Test.startTest();
        Map<Id,Contact> oldContacts = new Map<Id,Contact>([SELECT Id, Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        Map<Id,Contact> newContacts = new Map<Id,Contact>([SELECT Id,Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        newContacts.values()[0].Member_Card_Num__c = '1234567890123451';
        try{
            contactService.onBeforeUpdate(oldContacts, newContacts);
        }catch (Exception e){
            System.assertEquals(true, String.isNotBlank(e.getMessage()));
        }
        Test.stopTest();        
    }

    @IsTest
    static void testOnBeforeUpdateDBCall_ContactWithNoAccountId(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        Test.startTest();
        Map<Id,Contact> oldContacts = new Map<Id,Contact>([SELECT Id, Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 3']);
        Map<Id,Contact> newContacts = new Map<Id,Contact>([SELECT Id,Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 3']);
        newContacts.values()[0].Member_Card_Num__c = '1234567890123453';
        newContacts.values()[0].RecordTypeId = CONTACT_RECORD_TYPE_ID;
        System.assertEquals(true, String.IsBlank(newContacts.values()[0].AccountId));
        contactService.onBeforeUpdate(oldContacts, newContacts);
        System.assertEquals(true, String.IsNotBlank(newContacts.values()[0].AccountId));
        Test.stopTest();        
    }

    @IsTest
    static void testOnBeforeUpdateDBCall_NewMemberNumberWithAccountId(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        String memberNumber = '1234567890123454';
        Test.startTest();
        Map<Id,Contact> oldContacts = new Map<Id,Contact>([SELECT Id, Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        Map<Id,Contact> newContacts = new Map<Id,Contact>([SELECT Id,Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact WHERE LastName='Contact 4']);
        newContacts.values()[0].Member_Card_Num__c = memberNumber;
        contactService.onBeforeUpdate(oldContacts, newContacts);

        FSL_Account.AccountDAO accountDao = new FSL_Account.AccountDAO();
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(newContacts.values()[0].AccountId);
        List<Account> accounts = accountDao.fetchAccountsById(accountIds);
        System.assertEquals(memberNumber, accounts[0].Member_ID__c);
        Test.stopTest();        
    }

    @IsTest
    static void testGetContactListByIdWithDB(){
        dataSetup();
        FSL_Contact.Factory factory = new FSL_Contact.Factory();
        FSL_Contact.IContactService contactService = factory.createService();
        Test.startTest();
        List<Contact> contacts = [SELECT Member_Card_Num__c, AccountId, FirstName, LastName, RecordTypeId FROM Contact];
        Set<Id> ids = new Set<Id>();
        ids.add(contacts[1].Id);
        List<Contact> result = contactService.getContactsById(ids);
        System.debug('getContactListByIds ==>' + result);
        System.assertEquals(contacts[1].Id, result[0].Id);
        Test.stopTest();
    }
    //End merge  section from Dylan

    @IsTest
    static void testContactService_GetContactListByMembershipNumber_MultipleMembershipNumbers_DaoCalled(){
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        Contact c1 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '123' );
        Contact c2 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '234' );
        dao.contacts.put( c1.Id, c1 );
        dao.contacts.put( c2.Id, c2 );
        Set<String> membershipNumbers = new Set<String>{ c1.Member_Card_Num__c, c2.Member_Card_Num__c };

        Test.startTest();
        List<Contact> contacts = service.getContactsByMembershipNumber( membershipNumbers );
        Test.stopTest();

        System.assertEquals( 2, contacts.size() );
    }

    @IsTest
    static void testContactService_GetContactListByPhoneNumber_MultipleMembershipNumbers_DaoCalled(){
        ContactDAOMock dao = new ContactDAOMock();
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService service = new FSL_Contact.ContactService( dao, accountService );

        List<Contact> expected = new List<Contact>{ new Contact(), new Contact() };
        dao.fetchContactsByPhoneNumberReturnValue = expected;

        Set<String> phoneNumbers = new Set<String>();

        System.assertEquals( 0, dao.fetchContactsByPhoneNumberCallCount, 'dao.fetchContactsByPhoneNumber has been called' );

        Test.startTest();
        List<Contact> actual = service.getContactsByPhoneNumber( phoneNumbers );
        Test.stopTest();

        System.assertEquals( expected, actual );
        System.assertEquals( 1, dao.fetchContactsByPhoneNumberCallCount, 'dao.fetchContactsByPhoneNumber has not been called' );
    }    
    
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_Contact.IFactory {
        public FSL_Contact.IContactService createService() {
            return new ContactServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_Contact.IContactService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    public class ContactDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_Contact.IContactDAO {
        public Map<Id, Contact> contacts;
        public Boolean isSuccess = true;

        public ContactDAOMock() {
            super( new Map<Id, Contact>(), CONTACT_TYPE );
            this.contacts = (Map<Id, Contact>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ContactDAOMock' );
            }
        }

        public List<Contact> fetchContactsById( Set<Id> ids ) {
            isQueryException();
            List<Contact> result = new List<Contact>();
            for( Id id : ids ) {
                if( contacts.containsKey( id ) ) {
                    result.add( contacts.get( id ) );
                }
            }
            return result;
        }

        public List<Contact> fetchContactsByMembershipNumber( Set<String> membershipNumbers ) {
            isQueryException();
            List<Contact> result = new List<Contact>();
            for( Contact c : contacts.values() ) {
                if( membershipNumbers.contains( c.Member_Card_Num__c ) ) {
                    result.add( c );
                }
            }
            return result;
        }

        
        public List<Contact> fetchContactsByDriverdata(FSL_Contact.ThirdPartyDriverContactWrapper driverWrapper) {
            return null;
        }
        public Id getrectypeIdbyDeveloperName(String rectypeDeveloperName) {
            return '0x01';
        }

        // Stepping away from the DaoMock model where logic has to be put into the mock.
        // A second reason for this method, is that Searchable_Phone_Number is a formula field, which is read-only
        public Integer fetchContactsByPhoneNumberCallCount = 0;
        public List<Contact> fetchContactsByPhoneNumberReturnValue = new List<Contact>();
        public List<Contact> fetchContactsByPhoneNumber( Set<String> phoneNumbers ) {
            fetchContactsByPhoneNumberCallCount++;
            isQueryException();
            return fetchContactsByPhoneNumberReturnValue;
        }
        public Integer createContactByDriverDatarCallCount = 0;
        public Contact createContactByDriverDataReturnValue = new Contact();
        public Contact createContactByDriverData(FSL_Contact.ThirdPartyDriverContactWrapper driverWrapper) {
            createContactByDriverDatarCallCount++;
            isQueryException();
            return createContactByDriverDataReturnValue;
        }
    }

    @IsTest
    public static void testContactDAOMock_FetchContactListById_NoException_CorrectRecordsReturned() {
        ContactDAOMock dao = new ContactDAOMock();

        Contact c1 = new Contact( Id = dao.Builder.getMockId() );
        Contact c2 = new Contact( Id = dao.Builder.getMockId() );
        Contact c3 = new Contact( Id = dao.Builder.getMockId() );
        Contact c4 = new Contact( Id = dao.Builder.getMockId() );
        dao.contacts.put( c1.Id, c1 );
        dao.contacts.put( c2.Id, c2 );
        dao.contacts.put( c3.Id, c3 );
        dao.contacts.put( c4.Id, c4 );

        Test.startTest();
        List<Contact> contacts = dao.fetchContactsById( new Set<Id>{ c2.Id, c3.Id } );
        Test.stopTest();

        System.assertEquals( 2, contacts.size() );
        System.assertEquals( c2.Id, contacts[0].Id );
        System.assertEquals( c3.Id, contacts[1].Id );
    }

    @IsTest
    public static void testContactDAOMock_FetchCasesForWorkOrder_IsException_ExceptionThrown() {
        ContactDAOMock dao = new ContactDAOMock();

        Contact c1 = new Contact( Id = dao.Builder.getMockId() );
        dao.contacts.put( c1.Id, c1 );
        dao.isSuccess = false;

        Exception ex = null;

        Test.startTest();
        try {
            List<Contact> contacts = dao.fetchContactsById( new Set<Id>{ c1.Id } );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactDAOMock_FetchContactsByMembershipNumber_NoException_CorrectRecordsReturned() {
        ContactDAOMock dao = new ContactDAOMock();

        Contact c1 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '123' );
        Contact c2 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '234' );
        Contact c3 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '345' );
        Contact c4 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '456' );
        dao.contacts.put( c1.Id, c1 );
        dao.contacts.put( c2.Id, c2 );
        dao.contacts.put( c3.Id, c3 );
        dao.contacts.put( c4.Id, c4 );

        Test.startTest();
        List<Contact> contacts = dao.fetchContactsByMembershipNumber( new Set<String>{ c2.Member_Card_Num__c, c3.Member_Card_Num__c } );
        Test.stopTest();

        System.assertEquals( 2, contacts.size() );
        System.assertEquals( c2.Member_Card_Num__c, contacts[0].Member_Card_Num__c );
        System.assertEquals( c3.Member_Card_Num__c, contacts[1].Member_Card_Num__c );
    }

    @IsTest
    public static void testContactDAOMock_FetchContactsByMembershipNumber_IsException_ExceptionThrown() {
        ContactDAOMock dao = new ContactDAOMock();

        Contact c1 = new Contact( Id = dao.Builder.getMockId(), Member_Card_Num__c = '123' );
        dao.contacts.put( c1.Id, c1 );
        dao.isSuccess = false;

        Exception ex = null;

        Test.startTest();
        try {
            List<Contact> contacts = dao.fetchContactsByMembershipNumber( new Set<String>{ c1.Member_Card_Num__c } );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactDAOMock_FetchContactsByPhoneNumber_NoException_CorrectRecordsReturned() {
        ContactDAOMock dao = new ContactDAOMock();
        List<Contact> expectedContacts = new List<Contact>{ new Contact(), new Contact() };
        dao.fetchContactsByPhoneNumberReturnValue = expectedContacts;

        System.assertEquals( 0, dao.fetchContactsByPhoneNumberCallCount, 'fetchContactsByPhoneNumber has been called' );

        Test.startTest();
        List<Contact> contacts = dao.fetchContactsByPhoneNumber( new Set<String>() );
        Test.stopTest();

        System.assertEquals( expectedContacts, contacts );
        System.assertEquals( 1, dao.fetchContactsByPhoneNumberCallCount, 'fetchContactsByPhoneNumber has not been called' );
    }

    @IsTest
    public static void testContactDAOMock_FetchContactsByPhoneNumber_IsException_ExceptionThrown() {
        ContactDAOMock dao = new ContactDAOMock();
        dao.isSuccess = false;

        Exception ex = null;

        Test.startTest();
        try {
            List<Contact> contacts = dao.fetchContactsByPhoneNumber( new Set<String>() );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }
    
    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ContactServiceMock implements FSL_Contact.IContactService {

        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ContactServiceMock' );
            }
        }

        public Integer getContactsByIdCallCount = 0;
        public List<Contact> getContactsByIdReturnValue = new List<Contact>();
        public List<Contact> getContactsById( Set<Id> ids ) {
            ++getContactsByIdCallCount;
            throwExceptionIfConfigured();
            return getContactsByIdReturnValue;
        }

        public Integer getContactsByMembershipNumberCallCount = 0;
        public List<Contact> getContactsByMembershipNumberReturnValue = new List<Contact>();
        public List<Contact> getContactsByMembershipNumber( Set<String> membershipNumbers ) {
            ++getContactsByMembershipNumberCallCount;
            throwExceptionIfConfigured();
            return getContactsByMembershipNumberReturnValue;
        }

        public Integer getContactsByPhoneNumberCallCount = 0;
        public List<Contact> getContactsByPhoneNumberReturnValue = new List<Contact>();
        public List<Contact> getContactsByPhoneNumber( Set<String> phoneNumbers ) {
            ++getContactsByPhoneNumberCallCount;
            throwExceptionIfConfigured();
            return getContactsByPhoneNumberReturnValue;
        }

        public Integer createContactsCallCount = 0;
        public List<Contact> createContactsReturnValue = new List<Contact>();
        public List<Contact> createContacts( List<FSL_JSonParserWorkOrder.Calls> calls ) {
            ++createContactsCallCount;
            throwExceptionIfConfigured();
            return createContactsReturnValue;
        }

        public Integer onBeforeUpdateCallCount = 0;
        public void onBeforeUpdate(Map<Id,Contact> oldContacts, Map<Id,Contact> newContacts){
            ++onBeforeUpdateCallCount;
            throwExceptionIfConfigured();
        }

        public Integer onBeforeInsertCallCount = 0;
        public void onBeforeInsert(List<Contact> newContacts) {
            ++onBeforeInsertCallCount;
            throwExceptionIfConfigured();
        }
        
        public Integer deleteOrphanMemberContactsCallCount = 0;
        public void deleteOrphanMemberContacts( Integer daysToRetain ) {
            ++deleteOrphanMemberContactsCallCount;
            throwExceptionIfConfigured();
        }
        public List<Contact> createOrUpdateContact(FSL_LightningCustomerWrapper wrap, String internalConId) {
            ++createContactsCallCount;
            throwExceptionIfConfigured();
            return createContactsReturnValue;
        }
        public Integer checkAndCreateNewContactCallCount=0;
        public Contact checkAndCreateNewContactReturnValue=new Contact();
        public Contact checkAndCreateNewContact(FSL_Contact.ThirdPartyDriverContactWrapper driverWrapper) {
            ++checkAndCreateNewContactCallCount;
            throwExceptionIfConfigured();
            return checkAndCreateNewContactReturnValue;
        }
        public Integer searchContactCallCount=0;
        public List<Contact> searchContactReturnValue=new List<Contact>();
        public List<Contact> searchContact(FSL_Contact.ThirdPartyDriverContactWrapper driverWrapper) {
            ++searchContactCallCount;
            throwExceptionIfConfigured();
            return searchContactReturnValue;
        }
    }

    @IsTest
    public static void testContactServiceMock_GetContactListById_NoException_CallCountIncrementedAndValueReturned() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.getContactsByIdCallCount );

        Test.startTest();
        List<Contact> defaultReturnValue = service.getContactsById( null );
        Integer callCount1 = service.getContactsByIdCallCount;

        List<Contact> expectedUpdatedReturnValue = new List<Contact>{ new Contact() };
        service.getContactsByIdReturnValue = expectedUpdatedReturnValue;
        List<Contact> actualUpdatedReturnValue = service.getContactsById( null );
        Integer callCount2 = service.getContactsByIdCallCount;
        Test.stopTest();

        System.assertEquals( 0, defaultReturnValue.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expectedUpdatedReturnValue, actualUpdatedReturnValue );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_GetContactListById_ThrowsException_ExceptionThrown() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.getContactsById( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactServiceMock_GetContactListByMembershipNumber_NoException_CallCountIncrementedAndValueReturned() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.getContactsByMembershipNumberCallCount );

        Test.startTest();
        List<Contact> defaultReturnValue = service.getContactsByMembershipNumber( null );
        Integer callCount1 = service.getContactsByMembershipNumberCallCount;

        List<Contact> expectedUpdatedReturnValue = new List<Contact>{ new Contact() };
        service.getContactsByMembershipNumberReturnValue = expectedUpdatedReturnValue;
        List<Contact> actualUpdatedReturnValue = service.getContactsByMembershipNumber( null );
        Integer callCount2 = service.getContactsByMembershipNumberCallCount;
        Test.stopTest();

        System.assertEquals( 0, defaultReturnValue.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expectedUpdatedReturnValue, actualUpdatedReturnValue );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_GetContactListByMembershipNumber_ThrowsException_ExceptionThrown() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.getContactsByMembershipNumber( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactServiceMock_GetContactListByPhoneNumber_NoException_CallCountIncrementedAndValueReturned() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.getContactsByPhoneNumberCallCount );

        Test.startTest();
        List<Contact> defaultReturnValue = service.getContactsByPhoneNumber( null );
        Integer callCount1 = service.getContactsByPhoneNumberCallCount;

        List<Contact> expectedUpdatedReturnValue = new List<Contact>{ new Contact() };
        service.getContactsByPhoneNumberReturnValue = expectedUpdatedReturnValue;
        List<Contact> actualUpdatedReturnValue = service.getContactsByPhoneNumber( null );
        Integer callCount2 = service.getContactsByPhoneNumberCallCount;
        Test.stopTest();

        System.assertEquals( 0, defaultReturnValue.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expectedUpdatedReturnValue, actualUpdatedReturnValue );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_GetContactListByPhoneNumber_ThrowsException_ExceptionThrown() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.getContactsByPhoneNumber( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactServiceMock_CreateContacts_NoException_CallCountIncrementedAndValueReturned() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.createContactsCallCount );

        Test.startTest();
        List<Contact> defaultReturnValue = service.createContacts( null );
        Integer callCount1 = service.createContactsCallCount;

        List<Contact> expectedUpdatedReturnValue = new List<Contact>{ new Contact() };
        service.createContactsReturnValue = expectedUpdatedReturnValue;
        List<Contact> actualUpdatedReturnValue = service.createContacts( null );
        Integer callCount2 = service.createContactsCallCount;
        Test.stopTest();

        System.assertEquals( 0, defaultReturnValue.size() );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( expectedUpdatedReturnValue, actualUpdatedReturnValue );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_CreateContacts_ThrowsException_ExceptionThrown() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        Test.startTest();
        try {
            service.createContacts( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    @IsTest
    public static void testContactServiceMock_OnBeforeUpdate_NoException_CallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.onBeforeUpdateCallCount );

        Test.startTest();
        service.onBeforeUpdate( null, null );
        Integer callCount1 = service.onBeforeUpdateCallCount;

        service.onBeforeUpdate( null, null );
        Integer callCount2 = service.onBeforeUpdateCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_OnBeforeUpdate_ThrowsException_ExceptionThrownAndCallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.onBeforeUpdateCallCount );

        Test.startTest();
        try {
            service.onBeforeUpdate( null, null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.onBeforeUpdateCallCount );
    }

    @IsTest
    public static void testContactServiceMock_OnBeforeInsert_NoException_CallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.onBeforeInsertCallCount );

        Test.startTest();
        service.onBeforeInsert( null );
        Integer callCount1 = service.onBeforeInsertCallCount;

        service.onBeforeInsert( null );
        Integer callCount2 = service.onBeforeInsertCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_OnBeforeInsert_ThrowsException_ExceptionThrownAndCallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.onBeforeInsertCallCount );

        Test.startTest();
        try {
            service.onBeforeInsert( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.onBeforeInsertCallCount );
    }

    @IsTest
    public static void testContactServiceMock_DeleteOrphanMemberContacts_NoException_CallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        
        System.assertEquals( 0, service.deleteOrphanMemberContactsCallCount );

        Test.startTest();
        service.deleteOrphanMemberContacts( null );
        Integer callCount1 = service.deleteOrphanMemberContactsCallCount;

        service.deleteOrphanMemberContacts( null );
        Integer callCount2 = service.deleteOrphanMemberContactsCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @IsTest
    public static void testContactServiceMock_DeleteOrphanMemberContacts_ThrowsException_ExceptionThrownAndCallCountIncremented() {
        ContactServiceMock service = new ContactServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.deleteOrphanMemberContactsCallCount );

        Test.startTest();
        try {
            service.deleteOrphanMemberContacts( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
        System.assertEquals( 1, service.deleteOrphanMemberContactsCallCount );
    }

    @IsTest
    static void testcreateOrUpdateContact() {
        FSL_LightningCustomerWrapper wrap = FSL_ValidateMembershipNumber_Test.dummyWrapper();
        FSL_Contact.IContactService contactService = (new FSL_Contact.Factory().createService());
        String internalConId = null;
        List<Contact> contacts = new List<Contact>();
        Test.startTest();
        contacts= contactService.createOrUpdateContact(wrap, internalConId);
        contacts= contactService.createOrUpdateContact(wrap, internalConId);
        System.debug('Contacts ==> ' + contacts);
        System.assertEquals(true, !contacts.isEmpty());
        Test.stopTest();
        
    }
    @IsTest
    static void testcreateOrUpdateContactWithInteralConId(){
        FSL_LightningCustomerWrapper wrap = FSL_ValidateMembershipNumber_Test.dummyWrapper();
        FSL_Contact.IContactService contactService = (new FSL_Contact.Factory().createService());
        String internalConId = null;
        Test.startTest();
        List<Contact> contacts= contactService.createOrUpdateContact(wrap, internalConId);
        internalConId = contacts[0].Id;
        List<Contact> internalContacts= contactService.createOrUpdateContact(wrap, internalConId);
        System.assertEquals(true, !internalContacts.isEmpty());
        Test.stopTest();
        
    }
    @IsTest
    static void testCreateOrUpdateContactWithException(){
        
        ContactDAOMock dao = new ContactDAOMock();
        dao.isSuccess = false;
        FSL_AccountTest.AccountServiceMock accountService = new FSL_AccountTest.AccountServiceMock();
        FSL_Contact.IContactService contactService = new FSL_Contact.ContactService( dao, accountService );
        String internalConId = null;
        List<Contact> contacts = new List<Contact>();
        Test.startTest();
        FSL_LightningCustomerWrapper wrap = FSL_ValidateMembershipNumber_Test.dummyWrapper();
        try {
               contacts= contactService.createOrUpdateContact(wrap, internalConId);
        } catch(Exception e) {
            System.assertEquals(true, string.isNotBlank(e.getStackTraceString()));
        }
        Test.stopTest();
        
    }
     
      @isTest
    static void testCheckandCreateNewContact(){
        dataSetup();
        ContactDAOMock dao=new ContactDAOMock();
        FSL_Contact.IContactService contactService=new FSL_Contact.Factory().createService();
        //Account a = new Account( Id = dao.Builder.getMockId( Schema.Account.getSObjectType() ) );
        Account a=[Select Id From Account Limit 1];
        FSL_Contact.ThirdPartyDriverContactWrapper driverwrapper = new FSL_Contact.ThirdPartyDriverContactWrapper('123','Test TParty',2.00,3.10,'1234567', a.Id);
/*
        Test.startTest();
        contactService.checkAndCreateNewContact(driverwrapper);
        Test.stopTest();
       // System.assertEquals(1,)
       // 
      */

    }
}