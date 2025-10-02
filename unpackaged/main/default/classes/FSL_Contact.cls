/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        02/23/2021  Dylan Truong        ERS-221208 - Subtask: ERS-221216  Update Contact trigger to update/create account when membership number updated
 *  2.0     5/14/2020   Dylan Truong         ERS-221083 MembershipValidation Phrase 2: Partial Search
 * 2.1      5/14/2020   Dylan Truong         ERS-222271 Unhandling Exception by FSL_ContactTrigger: System.DmlException: Valid Member number cannot be changed
 */

public with sharing class FSL_Contact {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IContactService createService();
    }

    public class Factory implements IFactory {
        public IContactService createService() {
            FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
            IContactDAO dao = createDAO();
            return new ContactService( dao, new FSL_Account.Factory().createService(),appLogService );
        }

        private IContactDAO createDAO() {
            return new ContactDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IContactDAO extends FSL_DAO.DmlInterface {
        List<Contact> fetchContactsById (Set<Id> ids);
        List<Contact> fetchContactsByMembershipNumber( Set<String> membershipNumbers );
        List<Contact> fetchContactsByPhoneNumber( Set<String> phoneNumbers );
        List<Contact> fetchContactsByDriverdata(ThirdPartyDriverContactWrapper driverWrapper);
        Contact createContactByDriverData(ThirdPartyDriverContactWrapper driverWrapper);
        Id getrectypeIdbyDeveloperName(String rectypeDeveloperName);
    }

    public class ContactDAO extends FSL_DAO.DmlBase implements IContactDAO {
        public Id getrectypeIdbyDeveloperName(String rectypeDeveloperName){
            return Schema.SObjectType.Contact.getRecordTypeInfosbyDeveloperName().get(rectypeDeveloperName).getRecordTypeId();
         }

        public List<Contact> fetchContactsById(Set<Id> ids){
            return [SELECT AccountId,API_Type__c,AssistantName,AssistantPhone,Birthdate,CreatedById,CreatedDate,
                        Department,Description,DoNotCall,Email,EmailBouncedDate,EmailBouncedReason,
                        Email_Type__c,External_ID__c,Fax,FirstName,HasOptedOutOfEmail,HasOptedOutOfFax,HomePhone,Id,
                        IndividualId,IsDeleted,IsEmailBounced,Jigsaw,JigsawContactId,Language_Preference__c,LastActivityDate,
                        LastCURequestDate,LastCUUpdateDate,LastModifiedById,LastModifiedDate,LastName,LastReferencedDate,
                        LastViewedDate,LeadSource,MailingAddress,MailingCity,MailingCountry,MailingGeocodeAccuracy,MailingLatitude,
                        MailingLongitude,MailingPostalCode,MailingState,MailingStreet,MasterRecordId,Membership_Authorization__c,
                        Membership_Birthday__c,Membership_Code__c,Membership_Expiration_Date__c,Membership_Id__c,Membership_IsLocalClub__c,
                        Membership_Level__c,Membership_OrgCode__c,Membership_Org__c,Membership_Program__c,Membership_Service_Charge_Indicator__c,
                        Membership_Since__c,Membership_Sponsor__c,Membership_Status__c,Membership_Type__c,Member_Card_Num__c,MobilePhone,
                        Name,Original_Member_Id__c,OtherAddress,OtherCity,OtherCountry,OtherGeocodeAccuracy,OtherLatitude,OtherLongitude,
                        OtherPhone,OtherPostalCode,OtherState,OtherStreet,OwnerId,Phone,Phone_Extension__c,Phone_Type__c,PhotoUrl,
                        RecordTypeId,ReportsToId,Salutation,Sms_Optin__c,SystemModstamp,Title,Type__c 
                    FROM Contact
                    WHERE Id in :ids];
        }

        public List<Contact> fetchContactsByMembershipNumber( Set<String> membershipNumbers ) {
            return [SELECT AccountId,API_Type__c,AssistantName,AssistantPhone,Birthdate,CreatedById,CreatedDate,
                        Department,Description,DoNotCall,Email,EmailBouncedDate,EmailBouncedReason,
                        Email_Type__c,External_ID__c,Fax,FirstName,HasOptedOutOfEmail,HasOptedOutOfFax,HomePhone,Id,
                        IndividualId,IsDeleted,IsEmailBounced,Jigsaw,JigsawContactId,Language_Preference__c,LastActivityDate,
                        LastCURequestDate,LastCUUpdateDate,LastModifiedById,LastModifiedDate,LastName,LastReferencedDate,
                        LastViewedDate,LeadSource,MailingAddress,MailingCity,MailingCountry,MailingGeocodeAccuracy,MailingLatitude,
                        MailingLongitude,MailingPostalCode,MailingState,MailingStreet,MasterRecordId,Membership_Authorization__c,
                        Membership_Birthday__c,Membership_Code__c,Membership_Expiration_Date__c,Membership_Id__c,Membership_IsLocalClub__c,
                        Membership_Level__c,Membership_OrgCode__c,Membership_Org__c,Membership_Program__c,Membership_Service_Charge_Indicator__c,
                        Membership_Since__c,Membership_Sponsor__c,Membership_Status__c,Membership_Type__c,Member_Card_Num__c,MobilePhone,
                        Name,Original_Member_Id__c,OtherAddress,OtherCity,OtherCountry,OtherGeocodeAccuracy,OtherLatitude,OtherLongitude,
                        OtherPhone,OtherPostalCode,OtherState,OtherStreet,OwnerId,Phone,Phone_Extension__c,Phone_Type__c,PhotoUrl,
                        RecordTypeId,ReportsToId,Salutation,Sms_Optin__c,SystemModstamp,Title,Type__c 
                    FROM Contact
                    WHERE Member_Card_Num__c in :membershipNumbers];
        }

        public List<Contact> fetchContactsByPhoneNumber( Set<String> phoneNumbers ) {
            return [SELECT AccountId,API_Type__c,AssistantName,AssistantPhone,Birthdate,CreatedById,CreatedDate,
                        Department,Description,DoNotCall,Email,EmailBouncedDate,EmailBouncedReason,
                        Email_Type__c,External_ID__c,Fax,FirstName,HasOptedOutOfEmail,HasOptedOutOfFax,HomePhone,Id,
                        IndividualId,IsDeleted,IsEmailBounced,Jigsaw,JigsawContactId,Language_Preference__c,LastActivityDate,
                        LastCURequestDate,LastCUUpdateDate,LastModifiedById,LastModifiedDate,LastName,LastReferencedDate,
                        LastViewedDate,LeadSource,MailingAddress,MailingCity,MailingCountry,MailingGeocodeAccuracy,MailingLatitude,
                        MailingLongitude,MailingPostalCode,MailingState,MailingStreet,MasterRecordId,Membership_Authorization__c,
                        Membership_Birthday__c,Membership_Code__c,Membership_Expiration_Date__c,Membership_Id__c,Membership_IsLocalClub__c,
                        Membership_Level__c,Membership_OrgCode__c,Membership_Org__c,Membership_Program__c,Membership_Service_Charge_Indicator__c,
                        Membership_Since__c,Membership_Sponsor__c,Membership_Status__c,Membership_Type__c,Member_Card_Num__c,MobilePhone,
                        Name,Original_Member_Id__c,OtherAddress,OtherCity,OtherCountry,OtherGeocodeAccuracy,OtherLatitude,OtherLongitude,
                        OtherPhone,OtherPostalCode,OtherState,OtherStreet,OwnerId,Phone,Phone_Extension__c,Phone_Type__c,PhotoUrl,
                        RecordTypeId,ReportsToId,Salutation,Searchable_Phone_Number__c,Sms_Optin__c,SystemModstamp,Title,Type__c 
                    FROM Contact
                    WHERE MobilePhone in :phoneNumbers];
        }
        public List<Contact> fetchContactsByDriverdata(ThirdPartyDriverContactWrapper driverWrapper){
            return [Select Id From Contact Where AccountId=:driverWrapper.accountId AND External_Id__c=:driverWrapper.thirdpartydriverId];
        }

        public Contact createContactByDriverData(ThirdPartyDriverContactWrapper driverWrapper){
            Contact newContact=new Contact(AccountId=driverWrapper.accountId);
           
            if(String.isBlank(driverWrapper.Name)){
                //log
                return newContact;
            }
            List<String> names=driverWrapper.Name.split(' ');
            if(names.size()==1){
                newContact.LastName=driverWrapper.Name;
            }else{
                newContact.FirstName=names[0];
                newContact.LastName=names[1];
            }
            newContact.ThirdParty_Driver_Location__Latitude__s = driverWrapper.latitude;
            newContact.ThirdParty_Driver_Location__longitude__s = driverWrapper.longitude;
            newContact.External_Id__c = driverWrapper.thirdpartydriverId;
            newContact.RecordTypeId = getrectypeIdbyDeveloperName('Third_Party_Driver');
            List<Database.SaveResult> results= insertRecords( new List<Contact>{newContact}, true);
            if(results[0].isSuccess()){
                newContact.Id=results[0].getId();
            }
            return newContact;
         }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IContactService {
        List<Contact> getContactsById(Set<Id> ids);
        List<Contact> getContactsByMembershipNumber( Set<String> membershipNumbers );
        List<Contact> getContactsByPhoneNumber( Set<String> phoneNumbers );
        void onBeforeUpdate(Map<Id,Contact> oldContacts, Map<Id,Contact> newContacts);    
        void onBeforeInsert(List<Contact> newContacts); 
        List<Contact> createContacts( List<FSL_JSonParserWorkOrder.Calls> calls );
        void deleteOrphanMemberContacts( Integer daysToRetain );
        List<Contact> createOrUpdateContact(FSL_LightningCustomerWrapper wrap, String internalConId);
        Contact checkAndCreateNewContact(ThirdPartyDriverContactWrapper driverWrapper);
        List<Contact> searchContact(ThirdPartyDriverContactWrapper driverWrapper);
    }

    public class ContactService implements IContactService {
        private IContactDAO dao;
        private FSL_Account.IAccountService accountService;
        private FSL_ApplicationLog.IApplicationLogService appLogService;
        private final String MEMBER_NUMBER_ALREADY_EXIST_MESSAGE = 'Contact with this membership number already exists';
        private final String VALID_MEMBER_NUMBER_MESSAGE = 'Valid Member Number cannot be changed';
        private final Id MEMBER_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        public ContactService( IContactDAO dao, FSL_Account.IAccountService accountService, FSL_ApplicationLog.IApplicationLogService appLogService ) {
            this.dao = dao;
            this.accountService = accountService;
            this.appLogService = appLogService;

        }
        public ContactService( IContactDAO dao, FSL_Account.IAccountService accountService) {
            this.dao = dao;
            this.accountService = accountService;
            this.appLogService = new FSL_ApplicationLog.Factory().createService();
        }

        public List<Contact> getContactsById( Set<Id> ids ) {
            return dao.fetchContactsById( ids );
        }

        public List<Contact> getContactsByMembershipNumber( Set<String> membershipNumbers ) {
            return dao.fetchContactsByMembershipNumber( membershipNumbers );
        }

        public List<Contact> getContactsByPhoneNumber( Set<String> phoneNumbers ) {
            return dao.fetchContactsByPhoneNumber( phoneNumbers );
        }

        public List<Contact> createContacts( List<FSL_JSonParserWorkOrder.Calls> calls ) {
            List<Contact> contacts = new List<Contact>();
            List<Contact> existingContacts = getExistingContacts( calls );
            List<Contact> newContacts = createNewContacts( calls, existingContacts );
            contacts.addAll( newContacts );
            contacts.addAll( existingContacts );
            populateMemberAccountIds( contacts );
            maskContactDetailsForSandboxes( contacts );
            if( !newContacts.isEmpty() ) {
                dao.insertRecords( newContacts );
            }
            if( !existingContacts.isEmpty() ) {
                dao.updateRecords( existingContacts );
            }
            return contacts;
        }

        private List<Contact> getExistingContacts( List<FSL_JSonParserWorkOrder.Calls> calls ) {
            List<Contact> result = new List<Contact>();
            Set<String> membershipNumbers = getMembershipNumbers( calls );
            if( !membershipNumbers.isEmpty() ) {
                result = dao.fetchContactsByMembershipNumber( membershipNumbers );
            }
            return result;
        }

        private Set<String> getMembershipNumbers( List<FSL_JSonParserWorkOrder.Calls> calls ) {
            Set<String> membershipNumbers = new Set<String>();
            for( FSL_JSonParserWorkOrder.Calls call : calls ) {
                String membershipNumber = getMembershipNumber( call.customer );
                if( membershipNumber != null ) {
                    membershipNumbers.add( membershipNumber );
                }
            }
            return membershipNumbers;
        }

        private String getMembershipNumber( FSL_JSonParserWorkOrder.Customer customer ) {
            String membershipNumber = null;
            if( customer.memberships != null 
                    && !customer.memberships.isEmpty() 
                    && customer.memberships[0].id != null
                    && customer.memberships[0].id.isNumeric() 
                    && customer.memberships[0].id.length() == 16 ) {
                membershipNumber = customer.memberships[0].id;
            }
            return membershipNumber;
        }

        private List<Contact> createNewContacts( List<FSL_JSonParserWorkOrder.Calls> calls, List<Contact> existingContacts ) {
            List<Contact> newContacts = new List<Contact>();
            List<FSL_JSonParserWorkOrder.Calls> contactsToBeCreated = getContactsToBeCreatedAndUpdateExistingContacts( calls, existingContacts );
            for( FSL_JSonParserWorkOrder.Calls call : contactsToBeCreated ) {
                newContacts.add( createContact( call ) );
            }
            return newContacts;
        }

        private List<FSL_JSonParserWorkOrder.Calls> getContactsToBeCreatedAndUpdateExistingContacts( List<FSL_JSonParserWorkOrder.Calls> calls, List<Contact> existingContacts ) {
            List<FSL_JSonParserWorkOrder.Calls> result = new List<FSL_JSonParserWorkOrder.Calls>();
            for( FSL_JSonParserWorkOrder.Calls call : calls ) {
                Boolean exists = false;
                Integer index = 0;
                Integer topIndex = existingContacts.size();
                String membershipNumber = getMembershipNumber( call.customer );
                while( !exists 
                        && index < topIndex 
                        && membershipNumber != null ) {
                    if( existingContacts[index].Member_Card_Num__c == membershipNumber ) {
                        exists = true;
                        populateFields( existingContacts[index], call );
                    }
                    index++;
                }
                if( !exists ) {
                    result.add( call );
                }
            }
            return result;
        }

        private void populateMemberAccountIds( List<Contact> contacts ) {
            Map<Contact, Account> contactAccounts = accountService.getOrCreateMemberAccounts( contacts );
            for( Contact c : contacts ) {
                if( contactAccounts.containsKey( c ) ) {
                    c.AccountId = contactAccounts.get( c ).Id;
                }
                else {
                    // Create error application log/notification
                }
            }
        }

        private Contact createContact( FSL_JSonParserWorkOrder.Calls call ) {
            Contact c = new Contact();
            c.RecordTypeId = MEMBER_RECORD_TYPE_ID;
            String membershipNumber = getMembershipNumber( call.customer );
            if( membershipNumber != null ) {
                c.Member_Card_Num__c = membershipNumber;
            }
            populateFields( c, call );
            return c;
        }

        private void populateFields( Contact c, FSL_JSonParserWorkOrder.Calls call ) {
            FSL_JSonParserWorkOrder.Customer customer = call.customer;
            // Membership Information
            c.Membership_Type__c = customer.memberships[0].membershipType;
            c.Membership_Sponsor__c = customer.memberships[0].sponsor;
            c.Membership_Program__c = customer.memberships[0].program;
            c.Membership_Code__c = customer.memberships[0].authorizationCode;
            c.Membership_Authorization__c = customer.memberships[0].authorizationLevel;
            c.Membership_Islocalclub__c = customer.memberships[0].isLocalClub;
            c.Membership_Level__c = customer.memberships[0].memberLevel;
            c.Membership_Birthday__c = customer.memberships[0].memberBirthday;
            c.Membership_Status__c = customer.memberships[0].memberStatus;
            c.Membership_Since__c = customer.memberships[0].memberSince != null ? customer.memberships[0].memberSince.leftPad( 2, '0' ) : null;
            c.Membership_Expiration_Date__c = customer.memberships[0].expirationDate != null ? Date.Valueof( customer.memberships[0].expirationDate ) : null;

            // Language Information
            c.Language_Preference__c = customer.languagePreference;

            // Org Information
            if( customer.memberships[0] != null ) {
                c.Membership_Org_Phone__c = customer.memberships[0].programPhone;

                if( String.isNotBlank( customer.memberships[0].programName ) ) {
                    c.Membership_Org__c = customer.memberships[0].programName;
                }
                else if( customer.memberships[0].org != null ) {
                    c.Membership_Org__c = customer.memberships[0].org.name;
                }
                
                if( customer.memberships[0].org != null ) {
                    c.Membership_OrgCode__c = customer.memberships[0].org.code;
                }
            }

            // Contact Information
            if( customer.contact != null ) {
                c.Type__c = customer.contact.contactType;
                c.Title = customer.contact.title;
                c.FirstName = customer.contact.firstName;
                c.LastName = customer.contact.lastName;
                if( customer.contact.phones != null && !customer.contact.phones.isEmpty() ) {
                    c.Phone = customer.contact.phones[0].phoneNumber;
                    c.MobilePhone = customer.contact.phones[0].phoneNumber;
                    c.Phone_Type__c = customer.contact.phones[0].phoneType;
                    c.Phone_Extension__c = customer.contact.phones[0].phoneExtension;
                    c.Sms_Optin__c = customer.contact.phones[0].smsOptIn;
                }

                // Emails Information
                if( customer.contact.emails != null && !customer.contact.emails.isEmpty() ) {
                    c.Email_Type__c = customer.contact.emails[0].emailType;
                    c.Email = customer.contact.emails[0].address;
                }
            }

            // UserId Information    
            if( call.Channel.contact != null ) {
                c.External_ID__c = call.Channel.contact.userId;
            }
        }

        private void maskContactDetailsForSandboxes( List<Contact> contacts ) {
            FSL_Integration_User__c integrationUser = FSL_Integration_User__c.getInstance('Integration User');
            if( integrationUser != null && integrationUser.isSandbox__c ) {
                String sandboxPhone = integrationUser.Sandbox_Phone__c;
                String sandboxEmail = integrationUser.Sandbox_Email__c;

                for( Contact contact : contacts ) {
                    if( !String.isBlank( sandboxPhone ) ) {
                        contact.Phone = sandboxPhone;
                        contact.MobilePhone = sandboxPhone;
                    }
                    if( !String.isBlank( sandboxEmail ) ) {
                        contact.Email = sandboxEmail;
                    }
                }
            }
        } 

        public void onBeforeInsert(List<Contact> newContacts) {
             handleMemberRecordsCreation(newContacts);
        } 

        public void onBeforeUpdate(Map<Id, Contact> oldContacts, Map<Id, Contact> newContacts) {
            handleCardMemberShipNumberChange(oldContacts,newContacts);    
        }

        private void handleMemberRecordsCreation(List<Contact> contacts) {
            Set<String> memberNumbers = getMemberNumber(contacts);
            preventDuplicateMemberCardNumbers (memberNumbers, contacts);
            List<Contact> recordsToCreate = getCreateRecordsWithEmptyAccountId(contacts);
            setupContactWithNewMemberAccount(recordsToCreate);
        }

        private void preventDuplicateMemberCardNumbers (Set<String> memberNumbers, List<Contact> newContacts) {
            if (!memberNumbers.isEmpty()) {
               List<Contact> contacts =  dao.fetchContactsByMembershipNumber(memberNumbers);
               if (!contacts.isEmpty()) {
                   List<Contact> newContactWithExistenMembership = retrieveNewContactWithExistenMembership(contacts, newContacts);
                   addErrorMessageToContacts(MEMBER_NUMBER_ALREADY_EXIST_MESSAGE, newContactWithExistenMembership);
               }
            }
        }

        private List<Contact> retrieveNewContactWithExistenMembership(List<Contact> existenContacts, List<Contact> newContacts) {
            List<Contact> newContactWithExistenMembership = new List<Contact>();
            Set<String> memberNumbers = getMemberNumber(existenContacts);
            for (String memberNumber : memberNumbers) {
                for (Contact contact : newContacts) {
                    if(contact.Member_Card_Num__c == memberNumber) {
                        newContactWithExistenMembership.add(contact);
                    }
                }
            }
            return newContactWithExistenMembership; 
        }

        private void handleCardMemberShipNumberChange(Map<Id,Contact> oldContacts, Map<Id,Contact> newContacts) {
            List<Contact> contacts = getContactsWithChangeToValidMemberNumber(oldContacts,newContacts );
            if(!contacts.isEmpty()) {
                addErrorMessageToContacts(VALID_MEMBER_NUMBER_MESSAGE, contacts);
            } 
            List<Contact> changedRecords = getChangedRecords(oldContacts,newContacts);
            Set<String> memberNumbers = getMemberNumber(changedRecords);
            cascadeMemberCardNumbersUpdateToAccount(changedRecords,memberNumbers);    
        }

        private void addErrorMessageToContacts(String errorMessage, List<Contact> contacts) {
            for(Contact contact: contacts) {
                contact.addError(errorMessage);
            }
        }

        private void cascadeMemberCardNumbersUpdateToAccount(List<Contact> changedRecords, Set<String> memberNumbers) {
            preventDuplicateMemberCardNumbers(memberNumbers, changedRecords);
            
            List<Contact> recordsToUpdate = getMemberRecordsWithAccountId(changedRecords);
            List<Contact> recordsToCreate = getMemberRecordsWithEmptyAccountId(changedRecords);
            
            updateContactMemberAccounts(recordsToUpdate);
            setupContactWithNewMemberAccount(recordsToCreate);        
        }

        private List<Contact> getContactsWithChangeToValidMemberNumber(Map<Id,Contact> oldContact,Map<Id,Contact> newContacts ) {
            List<Contact> contacts = new List<Contact>();
            for (Id contactId : newContacts.keySet()) {
                if(newContacts.get(contactId).Member_Card_Num__c != oldContact.get(contactId).Member_Card_Num__c 
                        && newContacts.get(contactId).RecordTypeid ==MEMBER_RECORD_TYPE_ID 
                        && isValidMemberNumber(oldContact.get(contactId).Member_Card_Num__c)) {
                    contacts.add(newContacts.get(contactId));
                }      
            }
            return contacts;
        }

        private boolean isValidMemberNumber(String memberId) {
            return String.isNotBlank(memberId) 
                    && memberId.isNumeric()
                    && memberId.length()==16;   
        }

        private List<Contact> getChangedRecords(Map<Id,Contact> oldContacts, Map<Id,Contact> newContacts) {
            List<Contact> changedRecords  = new List<Contact>();
            for(Id contactId: newContacts.keySet() ) {
                if (newContacts.get(contactId).Member_Card_Num__c != oldContacts.get(contactId).Member_Card_Num__c) {      
                    changedRecords.add(newContacts.get(contactId));
                } 
            }
            return changedRecords;
        }

        private List<Contact> getMemberRecordsWithEmptyAccountId(List<Contact> contacts) {
            List<Contact> emptyMemberAccountIdRecords  = new List<Contact>();
            for(Contact contact : contacts){
                if (String.isBlank(contact.AccountId) && contact.RecordTypeId == MEMBER_RECORD_TYPE_ID) {      
                    emptyMemberAccountIdRecords.add(contact);
                } 
            }
            return emptyMemberAccountIdRecords;
        }

        private List<Contact> getMemberRecordsWithAccountId(List<Contact> contacts) {
            List<Contact> memberRecordsWithAccountId  = new List<Contact>();
            for(Contact contact : contacts) {
                if (String.isNotBlank(contact.AccountId) && contact.RecordTypeId == MEMBER_RECORD_TYPE_ID) {      
                    memberRecordsWithAccountId.add(contact);
                } 
            }
            return memberRecordsWithAccountId;
        }

        private void updateContactMemberAccounts(List<Contact> contacts) {
            Map<Id, String> acctIdMemberIds = new Map<Id,String>(); 
            for (Contact contact: contacts) {
                acctIdMemberIds.put(contact.AccountId,contact.Member_Card_Num__c);
            }
            if(!acctIdMemberIds.isEmpty()) {
                accountService.updateMemberAccounts(acctIdMemberIds);
            }
        }
        
        private Set<String> getMemberNumber(List<Contact> contacts) {
            Set<String> memberNumbers = new Set<String>();
            for(Contact contact : contacts) {
                if (contact.RecordTypeId == MEMBER_RECORD_TYPE_ID 
                        && String.isNotBlank(contact.Member_Card_Num__c)) {
                    memberNumbers.add(contact.Member_Card_Num__c);
                }      
            }
            return memberNumbers;
        }

        private void setupContactWithNewMemberAccount(List<Contact> contacts) {
            if(!contacts.isEmpty()) {
                Map<Contact,Account> conAccts = accountService.getOrCreateMemberAccounts(contacts);
                for(Contact con: contacts) {
                    con.AccountId = conAccts.get(con).Id;
                }
            }               
        }

        private List<Contact> getCreateRecordsWithEmptyAccountId(List<Contact> contacts) {
            List<Contact> emptyAccountIdRecords  = new List<Contact>();
            for(Contact contact : contacts) {
                if ( String.isBlank(contact.AccountId) 
                        && contact.RecordTypeId == MEMBER_RECORD_TYPE_ID) {      
                    emptyAccountIdRecords.add(contact);
                }
            }
            return emptyAccountIdRecords;
        }
	    public List<Contact> createOrUpdateContact(FSL_LightningCustomerWrapper wrap, String internalConId) {
            List<Contact> contacts = new List<Contact>();
            if(String.IsNotBlank(internalConId)) {
                Set<Id> ids = new Set<Id>();
                ids.add(internalConId);
                contacts = dao.fetchContactsById(ids);
            } else {
                String membershipId = retrieveMembershipNumber(wrap);
                Set<String> membershipIds = new Set<String>();
                membershipIds.add(membershipId);
                    contacts = dao.fetchContactsByMembershipNumber(membershipIds); 
            
                    if(contacts.isEmpty()) {
                        contacts = new List<Contact>();
                        Contact contactToCreate = new Contact();
                        contactToCreate = populateContactAndMembership(wrap, internalConId);
                        contacts.add(contactToCreate);
                        dao.insertRecords(contacts);
    
                    } else {
                        contacts[0].Membership_Level__c = wrap?.membership?.memberLevel;
                        dao.updateRecords(contacts);
                    }
                
            }
            return contacts;
        }

        private Contact populateContactAndMembership( FSL_LightningCustomerWrapper wrap, String internalConId) {
            Contact con = new Contact();           
            con = populateContact(wrap);
            con.Language_Preference__c = wrap.languagePreference;
            //Membership details
            if(wrap.membership!=null) {
                // memberNumberChangeFlag = con.Member_Card_Num__c <> wrap.membership.id;
                populateContactMembership(con, wrap);
                // con.Member_Card_Num__c          = wrap.membership.id;
            }
            return con;
        }

        private Contact populateContact(FSL_LightningCustomerWrapper wrap) {
            Contact con = new Contact();    
            con.firstName          = wrap.contact.firstName;
            con.lastName           = wrap.contact.lastName;
            con.Type__c            = wrap.contact.contactType;
            if(wrap.contact.phones!=null && !wrap.contact.phones.isEmpty()){
                con.Sms_Optin__c       = wrap.contact.phones[0].smsOptIn!=null ? wrap.contact.phones[0].smsOptIn : false;
                con.Phone_Type__c      = wrap.contact.phones[0].phoneType;
                con.MobilePhone        = wrap.contact.phones[0].phoneNumber;
            }
            if(wrap.contact.emails!=null && !wrap.contact.emails.isEmpty()){
                con.Email_Type__c      = wrap.contact.emails[0].emailType;
                con.Email              = wrap.contact.emails[0].address;
            }
            con.title              = wrap.contact.title; 
            return con;
        }

        private void populateContactMembership(Contact contact, FSL_LightningCustomerWrapper wrap) {
            contact.Member_Card_Num__c          = wrap.membership.id;
            contact.External_ID__c              = wrap.membership.id;
            contact.Membership_Type__c          = wrap.membership.membershipType;
            if(wrap.membership.org!=null){
                contact.Membership_Org__c           = wrap.membership.org.name;
                contact.Membership_OrgCode__c       = wrap.membership.org.code;
            }
            contact.Membership_Sponsor__c       = wrap.membership.sponsor;
            contact.Membership_Program__c       = wrap.membership.program;
            contact.Membership_Code__c          = wrap.membership.authorizationCode;
            contact.Membership_Authorization__c = wrap.membership.authorizationLevel;
            contact.Membership_Islocalclub__c   = wrap.membership.isLocalClub!=null ? wrap.membership.isLocalClub : false;
            string expDate = formatDate(wrap.membership.expirationDate);
            contact.Membership_Expiration_Date__c = !string.isEmpty(expDate) ? Date.ValueOf(expDate) : null;
            contact.Membership_Level__c         = wrap.membership.memberLevel;
            contact.Membership_Level__c         = wrap.membership.memberLevel;
            contact.Membership_Status__c        = wrap.membership.memberStatus;
            contact.Membership_Sponsor__c        = wrap.membership.sponsor;               
            contact.Membership_Since__c        = wrap.membership.memberSince;
        }

        /**
        * @description 
        * @author Rajesh Kemisetti | 5/21/2020 
        * @param expirationDate 
        * @return string 
        **/
        private String formatDate(string expirationDate) {
            string expDate = '';
            if(!string.isEmpty(expirationDate)){            
                if(expirationDate.split('-').size()==3){
                    expDate = expirationDate;
                }else{
                    if(expirationDate.length()==8){
                        expDate = expirationDate.substring(0,4)+'-'+expirationDate.substring(4,6)+'-'+expirationDate.substring(6,8);
                    }
                }
            }
            return expDate;        
        }

        private String retrieveMembershipNumber(FSL_LightningCustomerWrapper wrap) { 
            String membershipId = '';
            if(wrap != null) {
                if(wrap.membership != null) {
                    if(String.isNotBlank(wrap.membership.id)) {
                        membershipId = wrap.membership.id;
                    }
                }
            }
            return membershipId;
        }

        public void deleteOrphanMemberContacts( Integer daysToRetain ) {
            FSL_IterableBatchable delegate = new FSL_IterableBatchable( new PurgeOldRecordBatchable( daysToRetain ) );
            Database.executeBatch( delegate );
        }
        public List<Contact> searchContact(ThirdPartyDriverContactWrapper driverWrapper) {
            return dao.fetchContactsByDriverdata(driverWrapper);
        }
        public Contact checkAndCreateNewContact(ThirdPartyDriverContactWrapper driverWrapper) {
                List<Contact> contacts=searchContact(driverWrapper );
                if(!contacts.isEmpty()){
                    return contacts[0];
                }

                return dao.createContactByDriverData(driverWrapper);     
        }
    }
  
    // *********************************************
    // * Batchable Implementation
    // *********************************************
    private class PurgeOldRecordBatchable implements FSL_IterableBatchable.IBatchable {
        private Integer daysToRetain;

        public PurgeOldRecordBatchable( Integer daysToRetain ) {
            this.daysToRetain = daysToRetain;
        }

        public Iterable<SObject> start( Database.BatchableContext context ) {
            Date createdDate = System.now().dateGMT().addDays( -daysToRetain );
            Id memberRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get( 'Member' ).getRecordTypeId();

            Map<Id, Contact> contacts = new Map<Id, Contact>( 
                [SELECT Id, AccountId 
                FROM Contact 
                WHERE RecordTypeId = :memberRecordTypeId 
                AND Member_Card_Num__c = NULL
                AND Id NOT IN (SELECT ContactId FROM WorkOrder) 
                AND AccountId NOT IN (SELECT Member_Account__c FROM WorkOrder) 
                AND CreatedDate < :createdDate 
                ORDER BY CreatedDate 
                LIMIT 10000] );
            List<Case> cases = [SELECT ContactId 
                                FROM Case 
                                WHERE ContactId IN :contacts.keySet()];

            for( Case c : cases ) {
                contacts.remove( c.ContactId );
            }
            return contacts.values();
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            if( items.size() > 0 ) {
                deleteOrphanMemberContacts( (List<Contact>)items );
            }
        }

        private void deleteOrphanMemberContacts( List<Contact> orphans ) {
            Set<Id> accountIds = new Set<Id>();
            for( Contact c : orphans ) {
                if( c.AccountId != null ) {
                    accountIds.add( c.AccountId );
                }
            }
            delete orphans;
            if( !accountIds.isEmpty() ) {
                FSL_Account.IAccountService accountService = new FSL_Account.Factory().createService();
                accountService.deleteAccounts( accountIds );
            }
        }
    
        public void finish( Database.BatchableContext context ) {
        }
    }

    public class ThirdPartyDriverContactWrapper {
        public string thirdpartydriverId;
        public string driverId;
        public string name;
        public Decimal latitude;
        public Decimal longitude;
        public string facilityId;
        public string accountId;
        public ThirdPartyDriverContactWrapper(){
 
        }
        public ThirdPartyDriverContactWrapper(String thirdpartydriverId, String name, Decimal latitude, Decimal longitude, 
                                              String facilityId, String accountId){
            this.thirdpartydriverId=thirdpartydriverId;
            this.name = name;
            this.latitude = latitude;
            this.longitude = longitude;
            this.facilityId = facilityId;
            this.accountId = accountId;
        }
     }
}