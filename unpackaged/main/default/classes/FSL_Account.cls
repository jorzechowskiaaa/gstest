/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * * 1.0    02/23/2021   Dylan Truong                   ERS-221208 - Subtask: ERS-221216  Update Contact trigger to update/create account when membership number updated
 * * 1.2    06-08-2023   VarunSharma@salesforce.com   Changes for person account, service contract and handling of the empty values for expiration date and member since. (https://salesforce.atlassian.net/browse/PR893288-252/238/242/249)
 */

public with sharing class FSL_Account {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IAccountService createService();
        MembershipInformationParser createMembershipInformationParser();
    }

    public class Factory implements IFactory {
        public IAccountService createService() {
            IAccountDAO dao = createDAO();
            return new AccountService( dao );
        }

        private IAccountDAO createDAO() {
            return new AccountDAO();
        }

        public MembershipInformationParser createMembershipInformationParser() {
            return new MembershipInformationParser();
        }
    }
    // *********************************************
    // * DAO
    // *********************************************
    public interface IAccountDAO extends FSL_DAO.DmlInterface {
        List<Account> fetchAccountsById( Set<Id> ids );
        List<Account> fetchERSMemberAccountsByMemberId( Set<String> memberIds );        
        List<Account> fetchMemberAccountsByMemberId( Set<String> memberIds );
        List<Account> fetchMemberAccountsById(Set<String> memberRecordIds );
    }
    public class AccountDAO extends FSL_DAO.DmlBase implements IAccountDAO {
        public List<Account> fetchAccountsById( Set<Id> ids ) {
            return [SELECT AccountNumber,AccountSource,AnnualRevenue,BillingAddress,BillingCity,BillingCountry,
                        BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,
                        BillingStreet,CreatedById,CreatedDate,Description,Facility_ID__c,Facility_Type__c,Fax,Id,
                        Industry,IsDeleted,IsPartner,Jigsaw,JigsawCompanyId,LastActivityDate,LastModifiedById,
                        LastModifiedDate,LastReferencedDate,LastViewedDate,MasterRecordId,Member_ID__c,Name,
                        NumberOfEmployees,OperatingHoursId,OwnerId,Ownership,ParentId,Phone,PhotoUrl,Rating,
                        RecordTypeId,Service_Territory__c,ShippingAddress,ShippingCity,ShippingCountry,ShippingGeocodeAccuracy,
                        ShippingLatitude,ShippingLongitude,ShippingPostalCode,ShippingState,ShippingStreet,Sic,
                        SicDesc,Site,SystemModstamp,TickerSymbol,Type,Website,
                        Club_Code__c // PR893288-5062 Added to populate Club Code on Account
                    FROM Account
                    WHERE Id IN :ids];
        }
        
        public List<Account> fetchERSMemberAccountsByMemberId( Set<String> memberIds ) {
            return [SELECT AccountNumber,AccountSource,AnnualRevenue,BillingAddress,BillingCity,BillingCountry,
                        BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,
                        BillingStreet,CreatedById,CreatedDate,Description,Facility_ID__c,Facility_Type__c,Fax,Id,
                        Industry,IsDeleted,IsPartner,Jigsaw,JigsawCompanyId,LastActivityDate,LastModifiedById,
                        LastModifiedDate,LastReferencedDate,LastViewedDate,MasterRecordId,Member_ID__c,Name,
                        NumberOfEmployees,OperatingHoursId,OwnerId,Ownership,ParentId,Phone,PhotoUrl,Rating,
                        RecordTypeId,Service_Territory__c,ShippingAddress,ShippingCity,ShippingCountry,ShippingGeocodeAccuracy,
                        ShippingLatitude,ShippingLongitude,ShippingPostalCode,ShippingState,ShippingStreet,Sic,
                        SicDesc,Site,SystemModstamp,TickerSymbol,Type,Website,
                        Club_Code__c // PR893288-5062 Added to populate Club Code on Account
                    FROM Account
                    WHERE Member_ID__c IN :memberIds
                    AND RecordType.Name = 'ERS Member'];
        }
        
        public List<Account> fetchMemberAccountsByMemberId( Set<String> memberIds ) {
            List<Account> foundAccounts = new List<Account>();
            try{
                // This change is for AAA-ACA Project on *Top of the AAA-ACE Code*, for considering exact match and not LIKE match as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238
                //WHERE Member_ID__c LIKE :memberIds
                foundAccounts = [SELECT AccountNumber,AccountSource,AnnualRevenue,BillingAddress,BillingCity,BillingCountry,
                        BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,
                        BillingStreet,CreatedById,CreatedDate,Description,Facility_ID__c,Facility_Type__c,Fax,Id,
                        Industry,IsDeleted,IsPartner,Jigsaw,JigsawCompanyId,LastActivityDate,LastModifiedById,
                        LastModifiedDate,LastReferencedDate,LastViewedDate,MasterRecordId,Member_ID__c,
                        NumberOfEmployees,OperatingHoursId,OwnerId,Ownership,ParentId,Phone,PhotoUrl,Rating,
                        RecordTypeId,Service_Territory__c,ShippingAddress,ShippingCity,ShippingCountry,ShippingGeocodeAccuracy,
                        ShippingLatitude,ShippingLongitude,ShippingPostalCode,ShippingState,ShippingStreet,Sic,
                        SicDesc,Site,SystemModstamp,TickerSymbol,Type,Website,
                        PersonTitle,PersonMobilePhone,PersonHomePhone,PersonEmail, PersonContactId,
                        ACG_AAA_Membership__c,Membership_Number__c,FirstName,LastName,ACG_Joined_AAA__c,ACG_SMS_Opt_In__c,
                        CDX_Authorization_Code__c,CDX_Home_Lockout_Entitled__c,Authorize_Code__c,CDX_Authorization_Level__c,CDX_Authorization_Message__c, CDX_Authorization_TransactionId__c,
                        AAA_Membership_Level__c,ACG_Membership_Status__c,CDX_Membership_Status__c,Membership_Expiration_Date__c,
                        Membership_Org_Phone__pc,BillingStateCode,BillingCountryCode,
                        CDX_Motorcycle_Coverage__c,AAA_200_Miles_Premier_Tow__c,Long_Tow_Kilometers_Used__c,Long_Tow_Miles_Used__c,
                        ACG_Club__c,ACG_Club_Name__c,ACG_Entitlements_Allotted__c,ACG_Entitlements_Used__c,
                        API_Type__pc,Email_Type__pc,External_ID__pc,Language_Preference__pc,Membership_Authorization__pc,
                        Membership_Birthday__pc,Membership_Code__pc,Membership_Expiration_Date__pc,Membership_Id__pc,Membership_IsLocalClub__pc,
                        Membership_Level__pc,Membership_OrgCode__pc,Membership_Org__pc,Membership_Program__pc,Membership_Service_Charge_Indicator__pc,
                        Membership_Since__pc,Membership_Sponsor__pc,Membership_Status__pc,Membership_Type__pc,Member_Card_Num__pc,
                        Original_Member_Id__pc,Phone_Extension__pc,Phone_Type__pc,Sms_Optin__pc,Type__pc, ACA_AAA_Suffix__c,
                        Club_Code__c // PR893288-5062 Added to populate Club Code on Account         
                    FROM Account
                        WHERE Member_ID__c IN :memberIds];
                    //AND RecordType.Name = 'Member'
        }
            catch(Exception exp){ throw exp;}
            return foundAccounts;
        } 
        
        public List<Account> fetchMemberAccountsById(Set<String> memberRecordIds){
            List<Account> foundAccounts = new List<Account>();
            try{
                // This change is for AAA-ACA Project on top of the AAA-ACE, for considering exact match and not LIKE match as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238            
                foundAccounts = [SELECT AccountNumber,AccountSource,AnnualRevenue,BillingAddress,BillingCity,BillingCountry,
                                 BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,
                                 BillingStreet,CreatedById,CreatedDate,Description,Facility_ID__c,Facility_Type__c,Fax,Id,
                                 Industry,IsDeleted,IsPartner,Jigsaw,JigsawCompanyId,LastActivityDate,LastModifiedById,
                                 LastModifiedDate,LastReferencedDate,LastViewedDate,MasterRecordId,Member_ID__c,
                                 NumberOfEmployees,OperatingHoursId,OwnerId,Ownership,ParentId,Phone,PhotoUrl,Rating,
                                 RecordTypeId,Service_Territory__c,ShippingAddress,ShippingCity,ShippingCountry,ShippingGeocodeAccuracy,
                                 ShippingLatitude,ShippingLongitude,ShippingPostalCode,ShippingState,ShippingStreet,Sic,
                                 SicDesc,Site,SystemModstamp,TickerSymbol,Type,Website,
                                 PersonTitle,PersonMobilePhone,PersonHomePhone,PersonEmail, PersonContactId,
                                 ACG_AAA_Membership__c,Membership_Number__c,FirstName,LastName,ACG_Joined_AAA__c,ACG_SMS_Opt_In__c,
                                 CDX_Authorization_Code__c,CDX_Home_Lockout_Entitled__c,Authorize_Code__c,CDX_Authorization_Level__c,CDX_Authorization_Message__c, CDX_Authorization_TransactionId__c,
                                 AAA_Membership_Level__c,ACG_Membership_Status__c,CDX_Membership_Status__c,Membership_Expiration_Date__c,
                                 Membership_Org_Phone__pc,BillingStateCode,BillingCountryCode,
                                 CDX_Motorcycle_Coverage__c,AAA_200_Miles_Premier_Tow__c,Long_Tow_Kilometers_Used__c,Long_Tow_Miles_Used__c,
                                 ACG_Club__c,ACG_Club_Name__c,ACG_Entitlements_Allotted__c,ACG_Entitlements_Used__c,
                                 API_Type__pc,Email_Type__pc,External_ID__pc,Language_Preference__pc,Membership_Authorization__pc,
                                 Membership_Birthday__pc,Membership_Code__pc,Membership_Expiration_Date__pc,Membership_Id__pc,Membership_IsLocalClub__pc,
                                 Membership_Level__pc,Membership_OrgCode__pc,Membership_Org__pc,Membership_Program__pc,Membership_Service_Charge_Indicator__pc,
                                 Membership_Since__pc,Membership_Sponsor__pc,Membership_Status__pc,Membership_Type__pc,Member_Card_Num__pc,
                                 Original_Member_Id__pc,Phone_Extension__pc,Phone_Type__pc,Sms_Optin__pc,Type__pc, ACA_AAA_Suffix__c, 
                                 Club_Code__c // PR893288-5062 Added to populate Club Code on Account
                                 FROM Account                   
                                 WHERE ID IN : memberRecordIds];
            }            
            catch(Exception exp){ throw exp;}
            return foundAccounts;
        }           
    }
    
    // *********************************************
    // * Service
    // *********************************************
    public interface IAccountService {
        void updateMemberAccounts(Map<Id,String> acctIdMemberIds);
        List<Account> getOrCreateMemberPersonAccounts( List<MembershipInformation> membershipInfos );
        Map<Contact,Account> getOrCreateMemberAccounts(List<Contact> contacts);
        void deleteAccounts( Set<Id> ids );
    }

    private static final Id MEMBER_ACCOUNT_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    public class AccountService implements IAccountService {
        private IAccountDAO dao;

        public AccountService(IAccountDAO dao ) {
            this.dao = dao;
        }

        public void updateMemberAccounts(Map<Id,String> acctIdMemberIds){
            List<Account> accts = dao.fetchAccountsById(acctIdMemberIds.keySet());
            if (!accts.isEmpty()){
                for(Account acct : accts){
                    acct.Member_ID__c = acctIdMemberIds.get(acct.Id);
                }  
                dao.updateRecords(accts);
            }
        }

        public List<Account> getOrCreateMemberPersonAccounts( List<MembershipInformation> membershipInfos ) {
            List<Account> accounts = new List<Account>();
            // Get membership Numbers from the List of Contacts pass (Business confiremd that one request from D3 will have only one contact)
            Set<String> membershipNumbers = getMembershipNumbers(membershipInfos);
            convertExistingLegacyMemberAccounts( membershipNumbers );
           
            // Check for and existing person account as per the extended checks and create one if required. (we are follow creation of the account resulting in error to check for duplicates)
            List<Account> existingAccounts = getExistingOrNewPersonAccounts( membershipInfos );
            
            system.debug('existingAccounts 174' + existingAccounts);
            //Update existing Person accounts with any modified/additional information in the the payload            
            Boolean updateRequired = false;
            if( !existingAccounts.isEmpty() ) {
                updateRequired = updateExistingMemberPersonAccounts( existingAccounts, membershipInfos );
                if(updateRequired ){
                dao.updateRecords( existingAccounts );
            }
                accounts.addAll( existingAccounts );
            }
            
            // // Check the payload with existing members and if not, we need to create them
            // List<MembershipInformation> membershipInfosWithNonExistingAccounts = determineMembershipInfosWithoutMemberPersonAccount( membershipInfos, existingAccounts );
            
            
            // if(!membershipInfosWithNonExistingAccounts.isEmpty()){
            //     List<Account> newAccounts = createNewMemberPersonAccounts( membershipInfosWithNonExistingAccounts );
            //     if( !newAccounts.isEmpty() ) {
            //         dao.insertRecords( newAccounts );
            //     }
            //     accounts.addAll( newAccounts );
            // }
            return accounts;
        }        
        
        private Set<String> getMembershipNumbers( List<MembershipInformation> membershipInfos ) {
            Set<String> membershipNumbers = new Set<String>();
            for( MembershipInformation info : membershipInfos ) {
                if( String.isNotBlank( info.membershipNumber ) ) { // && info.membershipType == 'MEMBER'
                    // Varun: Need to do exact and complete match with Member ID :: https://salesforce.atlassian.net/browse/PR893288-238
                    //membershipNumbers.add( info.membershipNumber.substring( 0, 15 ) + '%' );
                    membershipNumbers.add( info.membershipNumber );
                }
            }
            return membershipNumbers;
        }        

        // FIXME: Throwaway code used until full conversion from legacy accounts to person accounts is completed
        private void convertExistingLegacyMemberAccounts( Set<String> membershipNumbers ) {
            System.Debug('convertExistingLegacyMemberAccounts::' + membershipNumbers);
            List<Account> accounts = 
                [SELECT Id, RecordTypeId
                FROM Account
                 // Varun: Need to do exact and complete match with Member ID :: https://salesforce.atlassian.net/browse/PR893288-238
                 //WHERE Member_ID__c LIKE :membershipNumbers
                 WHERE Member_ID__c IN :membershipNumbers
                AND RecordType.Name = 'ERS Member'];
            
            system.debug('accounts 220 ' + accounts);            
            if( !accounts.isEmpty() ) {
                Id personAccountERSRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
                Set<Id> accountIds = new Set<Id>();
                for( Account a : accounts ) {
                    a.RecordTypeId = personAccountERSRecordTypeId;
                    accountIds.add( a.Id );
                }
                update accounts;

                accounts = 
                    [SELECT Id, ACG_AAA_Membership__c, Member_ID__c, Member_Card_Num__pc
                    FROM Account
                    WHERE Id IN :accountIds
                    AND Member_Card_Num__pc != null];
                for( Account a : accounts ) {
                    if(a.Member_ID__c != a.Member_Card_Num__pc){
                    a.Member_ID__c = a.Member_Card_Num__pc;
                    }
                    if(a.ACG_AAA_Membership__c != a.Member_Card_Num__pc){
                    a.ACG_AAA_Membership__c = a.Member_Card_Num__pc;
                }
                }
                update accounts;
            }
        }
        
        // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238              
        private List<Account> getExistingOrNewPersonAccounts(List<MembershipInformation> membershipInfo) {
            List<Account> existingAccounts = new List<Account>();            
            Set<string>     membershipIDs       = new Set<string>();
            if(!membershipInfo.isEmpty()) {                
                // Get membership IDs from the D3 Payload
                membershipIDs = getMembershipNumbers( membershipInfo );                
                // Person Check #1 : Exact and complete match with Member ID
                if(!membershipIDs.isEmpty()){                 
                    List<Account> foundRecords = dao.fetchMemberAccountsByMemberId( membershipIDs );
                    if(!foundRecords.isEmpty()){
                        existingAccounts.AddAll(foundRecords);
                    }                    
                }
                
                // Perform rest of the checks if no record found with Membership ID
                if(existingAccounts.isEmpty()){                  
                    List<Account> accDetailsToCheckList = createNewMemberPersonAccounts(membershipInfo);                    
                    for(Account accDetailsToCheck: accDetailsToCheckList){                        
                        
                        // If there is a duplicate then we will get the reference of the Duplicate Person Account
                        Account existingMemberAccount = getExistingMemberAccountID(accDetailsToCheck);
                        // If we got a duplicate account from the duplicate checks then add it to the existing accounts
                        if(existingMemberAccount != null){
                            List<Account> existingMemberAccounts = dao.fetchMemberAccountsById( new Set<String> { String.ValueOf(existingMemberAccount.ID)} );
                            existingAccounts.addAll(existingMemberAccounts);
                        }
                        // Add the newly created Account above i.e. accDetailsToCheck to the existing account list
                        else{
                            existingAccounts.add(accDetailsToCheck);
                        }
                    }
                }
            }
            return existingAccounts;
        }

        // Updates the Object Property only in the Class Instance and NOT in the DB.        
        private Boolean updateExistingMemberPersonAccounts( List<Account> accounts, List<MembershipInformation> infos ) {
            Boolean isUpadated = false;
            if(accounts.size() == 1 && infos.Size() == 1){
                if(populateMemberPersonAccountFields( accounts[0], infos[0] )){
                    isUpadated = true;
                }
            }else {
            for( Account account : accounts ) {
                for( MembershipInformation info : infos ) {
                        if( account.Member_ID__c == info.membershipNumber) {                    
                            if(populateMemberPersonAccountFields( account, info )){
                                isUpadated = true;
                            }
                        }
                    }
                }
            }
            return isUpadated;
        }

        // private List<MembershipInformation> determineMembershipInfosWithoutMemberPersonAccount( List<MembershipInformation> membershipInfos, List<Account> existingAccounts ) {
        //     List<MembershipInformation> membershipInfosWithNonExistingAccounts = new List<MembershipInformation>();
        //     Set<String> membershipNumbers = new Set<String>();
        //     for( Account account : existingAccounts ) {
        //         membershipNumbers.add( account.Member_ID__c);
        //     }
        //     for( MembershipInformation info : membershipInfos ) {
        //         if( String.isBlank( info.membershipNumber ) || !membershipNumbers.contains( info.membershipNumber ) ) {
        //             membershipInfosWithNonExistingAccounts.add( info );
        //         }
        //     }
        //     return membershipInfosWithNonExistingAccounts;
        // }
		
        private List<Account> createNewMemberPersonAccounts( List<MembershipInformation> membershipInfos ) {
            List<Account> accounts = new List<Account>();
            for( MembershipInformation info : membershipInfos ) {
                accounts.add( createNewMemberPersonAccount( info ) );
            }
            return accounts;
        }
	
        private Account createNewMemberPersonAccount( MembershipInformation info ) {
            Account account = new Account();
            account.RecordTypeId = MEMBER_ACCOUNT_RECORDTYPE_ID;
            account.Member_ID__c = info.membershipNumber;
            // TODO: ACG field
            account.ACG_AAA_Membership__c = info.membershipNumber;
            account.Member_Card_Num__pc = info.membershipNumber;
            populateMemberPersonAccountFields( account, info );
            return account;
        }

        private Boolean populateMemberPersonAccountFields( Account account, MembershipInformation info ) { 
            Boolean isUpadated = false;
            if(account.Membership_Number__c != null){
                account.Membership_Number__c = null; // Reset "No Membership" indicator
                isUpadated = true;
            }
            if( String.isNotBlank( info.title )     && account.PersonTitle != info.title) {                
                account.PersonTitle = info.title; 
                isUpadated = true;
            }
            
            if( String.isNotBlank( info.suffix )     && account.ACA_AAA_Suffix__c != info.suffix) {
                account.ACA_AAA_Suffix__c = info.suffix;
                isUpadated = true;
            }
            
            if( String.isNotBlank( info.firstName)   && account.FirstName != info.firstName) {
                account.FirstName = info.firstName;
                isUpadated = true;
            }
            if( String.isNotBlank( info.lastName)    && account.LastName != info.lastName)  {
                account.LastName = info.lastName;
                isUpadated = true;
            }
            if( String.isNotBlank( info.phoneNumber) && account.Phone != info.phoneNumber)  {
                account.Phone = info.phoneNumber;
                isUpadated = true;
            }
             if( String.isNotBlank( info.phoneNumber) && account.PersonMobilePhone != info.phoneNumber) {
                account.PersonMobilePhone = info.phoneNumber;
                isUpadated = true;
            }
            if( String.isNotBlank( info.phoneNumber) && account.PersonHomePhone != info.phoneNumber) {
                account.PersonHomePhone = info.phoneNumber;
                isUpadated = true;
            }
            if( String.isNotBlank( info.phoneNumber) && account.Membership_Org_Phone__pc != info.phoneNumber) {
                account.Membership_Org_Phone__pc = info.phoneNumber;
                isUpadated = true;
            }
            if( String.isNotBlank( info.phoneExtension) && account.Phone_Extension__pc != info.phoneExtension) {
                account.Phone_Extension__pc = info.phoneExtension;
                isUpadated = true;
            }
            /*if( String.isNotBlank( info.phoneType) && account.Phone_Type__pc != info.phoneType) {
                account.Phone_Type__pc = info.phoneType;
                isUpadated = true;
            }*/
            if( String.isNotBlank( info.membershipType) && account.Membership_Type__pc != info.membershipType) {
                account.Membership_Type__pc = info.membershipType;
                isUpadated = true;
            }
            
            // TODO: Is this necessary? If so, how to determine? Also, ACG field
            account.ACG_Joined_AAA__c = null;
            // TODO: ACG field
            
            if( info.isSmsOptedIn != null ) {
                if(account.Sms_Optin__pc != info.isSmsOptedIn){
                account.Sms_Optin__pc = info.isSmsOptedIn;
                    isUpadated = true;                
                }
                if(account.ACG_SMS_Opt_In__c != info.isSmsOptedIn){
                account.ACG_SMS_Opt_In__c = info.isSmsOptedIn;
                    isUpadated = true;
                }                
            }
            if( String.isNotBlank( info.sponsor ) && account.Membership_Sponsor__pc != info.sponsor) {
                account.Membership_Sponsor__pc = info.sponsor;
                isUpadated = true;
            }
            if( String.isNotBlank( info.program )  && account.Membership_Program__pc != info.program) {
                account.Membership_Program__pc = info.program;
                isUpadated = true;
            }
            if( String.isNotBlank( info.authorizationCode ) ) {
                if(account.CDX_Authorization_Code__c != info.authorizationCode){
                account.CDX_Authorization_Code__c = info.authorizationCode;
                    isUpadated = true;
                }
                if(account.Authorize_Code__c != info.authorizationCode){
                account.Authorize_Code__c = info.authorizationCode;
                    isUpadated = true;
                }
                if(account.Membership_Code__pc != info.authorizationCode){
                account.Membership_Code__pc = info.authorizationCode;
                    isUpadated = true;
                }
            }
            if( String.isNotBlank( info.authorizationLevel ) ) {
                if(account.Membership_Authorization__pc != info.authorizationLevel){
                account.Membership_Authorization__pc = info.authorizationLevel;
                    isUpadated = true;
                }
                if(account.CDX_Authorization_Level__c != info.authorizationLevel){
                account.CDX_Authorization_Level__c = info.authorizationLevel;
                    isUpadated = true;
                }
            }
            if( String.isNotBlank( info.authorizationMessage) && account.CDX_Authorization_Message__c != info.authorizationMessage)  {
                account.CDX_Authorization_Message__c = info.authorizationMessage;
                isUpadated = true;
            }
            if( String.isNotBlank( info.authorizationTransactionId ) &&  account.CDX_Authorization_TransactionId__c != info.authorizationTransactionId) {                
                account.CDX_Authorization_TransactionId__c = info.authorizationTransactionId;
                isUpadated = true;
            }
            if( info.isLocalClub != null  && account.Membership_IsLocalClub__pc != info.isLocalClub) {                
                account.Membership_IsLocalClub__pc = info.isLocalClub;
                isUpadated = true;
            }
            // TODO: check whether Contact and Account have the same picklist values
            if( String.isNotBlank( info.membershipLevel )  && account.AAA_Membership_Level__c != info.membershipLevel){
                account.AAA_Membership_Level__c = info.membershipLevel;
                isUpadated = true;
            }

            //This picklist on Contact is [CLASSIC, PLUS, PREMIER, PREMIERRV, PLUSRV, CLASSICRV]
            if( String.isNotBlank( info.membershipLevelOnContact )  && account.Membership_Level__pc != info.membershipLevelOnContact) {
                account.Membership_Level__pc = info.membershipLevelOnContact;
                isUpadated = true;
            }

            if( String.isNotBlank( info.birthday )  && account.Membership_Birthday__pc != info.birthday){
                account.Membership_Birthday__pc = info.birthday;
                isUpadated = true;
            }
            // FIXME: determine correct value. Also, ACG field
            if(account.ACG_Membership_Status__c != 'Active'){
            account.ACG_Membership_Status__c = 'Active';
                isUpadated = true;
            }
            if( String.isNotBlank( info.membershipStatus ) ) {
                if(account.CDX_Membership_Status__c != info.membershipStatus){
                account.CDX_Membership_Status__c = info.membershipStatus;
                    isUpadated = true;
                }
                if(account.Membership_Status__pc != info.membershipStatus){
                account.Membership_Status__pc = info.membershipStatus;
                    isUpadated = true;
                }
            }
            if( String.isNotBlank( info.memberSince )  && account.Membership_Since__pc != info.memberSince){
                account.Membership_Since__pc = info.memberSince;
                isUpadated = true;
            }
            // TODO: Are both dates needed?
            if( info.expirationDate != null  && account.Membership_Expiration_Date__c != info.expirationDate){
                account.Membership_Expiration_Date__c = info.expirationDate;
                isUpadated = true;
            }
            if( info.expirationDate != null  && account.Membership_Expiration_Date__pc != info.expirationDate){
                account.Membership_Expiration_Date__pc = info.expirationDate;
                isUpadated = true;
            }
            if( String.isNotBlank( info.languagePreference )  && account.Language_Preference__pc != info.languagePreference){
                account.Language_Preference__pc = info.languagePreference;
                isUpadated = true;
            }
            if( String.isNotBlank( info.orgPhone )  && account.Membership_Org_Phone__pc != info.orgPhone){
                account.Membership_Org_Phone__pc = info.orgPhone;
                isUpadated = true;
            }
            if( String.isNotBlank( info.orgName )  && account.Membership_Org__pc != info.orgName) {
                account.Membership_Org__pc = info.orgName;
                isUpadated = true;
            }
            if( String.isNotBlank( info.orgCode )  && account.Membership_OrgCode__pc != info.orgCode) {
                account.Membership_OrgCode__pc = info.orgCode;
                isUpadated = true;
            }
            if( String.isNotBlank( info.contactType )  && account.Type__pc != info.contactType) {
                account.Type__pc = info.contactType;
                isUpadated = true;
            }
            if( String.isNotBlank( info.emailType ) &&  account.Email_Type__pc != info.emailType) {
                account.Email_Type__pc = info.emailType;
                isUpadated = true;
            }
            if( String.isNotBlank( info.emailAddress )  && account.PersonEmail != info.emailAddress) {
                isUpadated = true;
                account.PersonEmail = info.emailAddress;
            }
            if( String.isNotBlank( info.homeStreet )  && account.BillingStreet != info.homeStreet) {
                account.BillingStreet = info.homeStreet;
                isUpadated = true;
            }
            if( String.isNotBlank( info.homeCity )  && account.BillingCity != info.homeCity) {
                account.BillingCity = info.homeCity;
                isUpadated = true;
            }
            if( String.isNotBlank( info.homePostalCode ) && account.BillingPostalCode != info.homePostalCode) {
                account.BillingPostalCode = info.homePostalCode;
                isUpadated = true;
            }
            if( String.isNotBlank( info.homeStateCode )  && account.BillingStateCode != info.homeStateCode) {
                account.BillingStateCode = info.homeStateCode;
                isUpadated = true;
            }
            if( String.isNotBlank( info.homeCountryCode ) &&  account.BillingCountryCode != info.homeCountryCode) {
                account.BillingCountryCode = info.homeCountryCode;
                isUpadated = true;
            }
            if( info.motorcycleCoverage != null  && account.CDX_Motorcycle_Coverage__c != info.motorcycleCoverage) {
                account.CDX_Motorcycle_Coverage__c = info.motorcycleCoverage;
                isUpadated = true;
            }
            if( info.longTowAllowed != null  && account.AAA_200_Miles_Premier_Tow__c != info.longTowAllowed) {
                account.AAA_200_Miles_Premier_Tow__c = info.longTowAllowed;
                isUpadated = true;
            }
            if( info.longTowKilometersUsed != null  && account.Long_Tow_Kilometers_Used__c != info.longTowKilometersUsed) {
                account.Long_Tow_Kilometers_Used__c = info.longTowKilometersUsed;
                isUpadated = true;
            }
            if( info.longTowMilesUsed != null  && account.Long_Tow_Miles_Used__c != info.longTowMilesUsed) {
                account.Long_Tow_Miles_Used__c = info.longTowMilesUsed;
                isUpadated = true;
            }
            if( String.isNotBlank( info.clubCode )  && account.ACG_Club__c != info.clubCode) {
                account.ACG_Club__c = info.clubCode;
                isUpadated = true;
            }
            // PR893288-5062 To populate Club code on Account from customer information org code. 
            if( String.isNotBlank( info.clubCodeText )  && account.Club_Code__c != info.clubCodeText) {
                account.Club_Code__c = info.clubCodeText;
                isUpadated = true;
            }
            if( String.isNotBlank( info.clubName )  && account.ACG_Club_Name__c != info.clubName) {
                account.ACG_Club_Name__c = info.clubName;
                isUpadated = true;
            }
            if( info.entitlementsAllotted != null  && account.ACG_Entitlements_Allotted__c != info.entitlementsAllotted) {
                account.ACG_Entitlements_Allotted__c = info.entitlementsAllotted;
                isUpadated = true;
            }
            /*if( info.entitlementsUsed != null  && account.ACG_Entitlements_Used__c != info.entitlementsUsed) {
                account.ACG_Entitlements_Used__c = info.entitlementsUsed;
                isUpadated = true;
            }*/
            if( info.homeLockoutEntitled != null  && account.CDX_Home_Lockout_Entitled__c != info.homeLockoutEntitled ) {
                account.CDX_Home_Lockout_Entitled__c = info.homeLockoutEntitled;
                isUpadated = true;
            }
            if( String.isNotBlank(account.Member_ID__c) && account.Member_ID__c != null && (account.Membership_Org__pc == null || account.ACG_Club_Name__c == null)){
                String memberCode = account.Member_ID__c.subString(3,6);
                List<Club_Name_Mappings__mdt> mdtrecords = [SELECT Id,Club_Name__c,Club_Code__c 
                                                FROM Club_Name_Mappings__mdt 
                                                WHERE Club_Code__c = :memberCode];
                if( mdtrecords?.size() > 0 ) { 
                    account.ACG_Club_Name__c =  mdtrecords[0].Club_Name__c;
                    account.Membership_Org__pc =  mdtrecords[0].Club_Name__c;
                }
                isUpadated = true;
            }
            return isUpadated;
        }

        public Map<Contact,Account> getOrCreateMemberAccounts(List<Contact> contacts) {
            Map<String,Account> existAccts = getExistentMemberAccounts(contacts);
            Map<Contact,Account> conAccts = createNonExistentMemberAccounts(contacts, existAccts);
            if( !existAccts.isEmpty() ) {
                mergeExistentAccountsInNonExistentAccountsMap( contacts, existAccts, conAccts );
            }
            return conAccts;
        }

        private Map<String,Account> getExistentMemberAccounts(List<Contact> contacts){
            Set<String> notNullMemberIds = getNonBlankMemberIds(contacts);
            Map<String,Account> existAccts = new Map<String,Account>();
            if (!notNullMemberIds.isEmpty())
                existAccts = createMemberAccountMap(dao.fetchERSMemberAccountsByMemberId(notNullMemberIds));
            return existAccts;
        }

        private Map<String,Account> createMemberAccountMap(List<Account> accts) {
            Map <String,Account> memberAccts = new Map<String,Account>();
            for (Account acct : accts)
            {
                memberAccts.put(acct.Member_ID__c, acct);
            }
            return memberAccts; 
        }

        private Set<String> getNonBlankMemberIds(List <Contact> contacts){
            Set<String> memberIds = new Set<String>();
            for(Contact contact : contacts){
                if (String.isNotBlank(contact.Member_Card_Num__c))
                    memberIds.add(contact.Member_Card_Num__c);
            }
            return memberIds;
        }  

        private Map<Contact,Account> createNonExistentMemberAccounts(List<Contact> contacts, Map<String, Account> existAccts) {
            Id accountERSRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ERS Member').getRecordTypeId();
            Map<Contact,Account> conAccts = new Map<Contact,Account>();
            for (Contact contact : contacts) {
                if (!existAccts.containsKey(contact.Member_Card_Num__c))
                    conAccts.put(contact, new Account(Name=contact.FirstName + ' ' + contact.LastName, Member_ID__c = contact.Member_Card_Num__c, RecordTypeId = accountERSRecordTypeId));
            }

            if(!conAccts.isEmpty())
                dao.insertRecords(conAccts.values());
            return conAccts;
        }
        
        private void mergeExistentAccountsInNonExistentAccountsMap( List<Contact> contacts, Map<String, Account> existentAccounts, Map<Contact, Account> nonExistentAccounts ) {
            for( Contact contact: contacts ) {
                if( existentAccounts.containsKey( contact.Member_Card_Num__c ) ) {
                    nonExistentAccounts.put( contact, existentAccounts.get( contact.Member_Card_Num__c ) );
                }
            }
        }

        public void deleteAccounts( Set<Id> ids ) {
            List<Account> accounts = dao.fetchAccountsById( ids );
            if( !accounts.isEmpty() ) {
                dao.deleteRecords( accounts );
            }
        }
        
        public Account getExistingMemberAccountID(Account accDetailsToCheck){
            Account existingMemberAccount = null;
            List<sObject> duplicateRecords = new List<sObject>();
            Database.SaveResult sr = Database.insert(accDetailsToCheck, false);
            if (!sr.isSuccess()) {
                // Insertion failed due to duplicate detected
                for(Database.Error duplicateError : sr.getErrors()){
                    if (duplicateError instanceof Database.DuplicateError) {
                        Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();
                        
                        // Return only match results of matching rules that find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                        
                        // Just grab first match result (which contains the duplicate record found and other match info)
                        Datacloud.MatchResult matchResult = matchResults[0];
                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        
                        // Add matched record to the duplicate records variable                        
                        for (Datacloud.MatchRecord matchRecord : matchRecords) {
                            duplicateRecords.add(matchRecord.getRecord());                            
                        }
                    }
                }
                // Varun Add logic to pick up latest modified record
                DateTime lastModifiedLatestDateTime = DateTime.newInstance(1970, 1, 1, 0, 0, 0);
                for(SObject dupAccounts: duplicateRecords){
                    if( ((Datetime)dupAccounts.get('LastModifiedDate')) > lastModifiedLatestDateTime){
                        existingMemberAccount = (Account)dupAccounts;                        
                    }
                }
            }
            return existingMemberAccount;
        }
        
    }
    
    // *********************************************
    // * MembershipInformation
    // *********************************************
    public class MembershipInformation {
        public String membershipNumber;
        public String membershipType;
        public String sponsor;
        public String program;
        public String authorizationCode;
        public String authorizationLevel;
        public String authorizationMessage;
        public String authorizationTransactionId;
        public Boolean isLocalClub;
        public String membershipLevel;
        public String membershipLevelOnContact;
        public String birthday;
        public String membershipStatus;
        public String memberSince;
        public Date expirationDate;
        public String languagePreference;
        public String orgPhone;
        public String orgName;
        public String orgCode;
        public String contactType;
        public String title;
        public String firstName;
        public String lastName;
        public String phoneNumber;
        public String phoneType;
        public String phoneExtension;
        public Boolean isSmsOptedIn;
        public String emailType;
        public String emailAddress;
        public String externalId;
        public String homeStreet;
        public String homeCity;
        public String homePostalCode;
        public String homeStateCode;
        public String homeCountryCode;
        public Boolean motorcycleCoverage;
        public Boolean longTowAllowed;
        public Integer longTowKilometersUsed;
        public Integer longTowMilesUsed;
        public String clubCode;
        public String clubName;
        public Integer entitlementsAllotted;
        public Integer entitlementsUsed;
        public Boolean homeLockoutEntitled;
        
        // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238
        public String suffix;

        // This change is for AAA-ACA Project on *Top of the AAA-ACE Code*, as  Jira Story https://salesforce.atlassian.net/browse/PR893288-252
        public String rapID;
        public String rapProgram;
        public String rapSponsor;
        public String role;
        public String clubCodeText; // PR893288-5062 Added to populate orgcode from input customer information. 
    }

    public virtual class MembershipInformationParser {

        //Parse from IRAS
        public virtual MembershipInformation parse( FSL_JSonParserWorkOrder.Calls call ) {
            MembershipInformation info = new MembershipInformation();

            FSL_JSonParserWorkOrder.Customer customer = call.customer;
            // Membership Information
            // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238 and 252
            if( customer.memberships[0].id != null
                    && customer.memberships[0].id.isNumeric() 
               // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-252
               // This condition is commented as for RAP it could be less than 16 digits also.
               // Also there could be case where membershipType ='MEMBER' and id comes as "NONMEMBER"
               //&& customer.memberships[0].id.length() == 16 
               ) {
                info.membershipNumber = customer.memberships[0].id;
            }
            info.membershipType = customer.memberships[0].membershipType;
            info.sponsor = customer.memberships[0].sponsor;
            info.program = customer.memberships[0].program;
            info.authorizationCode = customer.memberships[0].authorizationCode;
            info.authorizationLevel = customer.memberships[0].authorizationLevel;
            //info.authorizationTransactionId = NOT PRESENT
            info.isLocalClub = customer.memberships[0].isLocalClub;
            //info.membershipLevel = customer.memberships[0].memberLevel;
            switch on customer.memberships[0].memberLevel?.toUpperCase() {
                when 'CLASSIC', 'CLSC', 'BASIC' {
                    info.membershipLevel = 'Basic';
                }
                when 'PREMIER', 'PREM' {
                    info.membershipLevel = 'Premier';
                }
                when 'PREMIER RV', 'PRRV', 'PREMIERRV' {
                    info.membershipLevel = 'Premier RV';
                }
                when 'PLUS RV', 'PLRV', 'PLUSRV' {
                    info.membershipLevel = 'Plus RV';
                }
                when 'PLUS' {
                    info.membershipLevel = 'Plus';
                }
                when else {
                    info.membershipLevel = 'Basic';
                }
            }
            info.membershipLevelOnContact = info.membershipLevel;
            info.birthday = customer.memberships[0].memberBirthday;
            info.membershipStatus = customer.memberships[0].memberStatus;            
            
            // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-252
            info.memberSince = String.isNotBlank(customer.memberships[0].memberSince) ? customer.memberships[0].memberSince : null;

            // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-252
            info.expirationDate = String.isNotBlank(customer.memberships[0].expirationDate) ? Date.Valueof( customer.memberships[0].expirationDate ) : null;

            // Language Information
            info.languagePreference = customer.languagePreference;

            // Org Information
            if( customer.memberships[0] != null ) {
                info.orgPhone = customer.memberships[0].programPhone;

                if( String.isNotBlank( customer.memberships[0].programName ) ) {
                    info.orgName = customer.memberships[0].programName;
                }
                else if( customer.memberships[0].org != null ) {
                    info.orgName = customer.memberships[0].org.name;
                }
                
                if( customer.memberships[0].org != null ) {
                    info.orgCode = customer.memberships[0].org.code;
                }
            }

            // Contact Information
            if( customer.contact != null ) {
                info.contactType = customer.contact.contactType;
                info.title = customer.contact.title;
                info.firstName = customer.contact.firstName;
                info.clubCodeText = customer.contact.orgcode; // PR893288-5062 Modified for to populate orgcode recieved as part of customer information to customer's clubcode.
                // This change is for AAA-ACA Project on top of the AAA-ACE, as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238
                info.suffix = customer.contact.suffix;
                info.lastName = customer.contact.lastName;
                if( customer.contact.phones != null && !customer.contact.phones.isEmpty() ) {
                    info.phoneNumber = customer.contact.phones[0].phoneNumber;
                    info.phoneType = customer.contact.phones[0].phoneType;
                    info.phoneExtension = customer.contact.phones[0].phoneExtension;
                    info.isSmsOptedIn = customer.contact.phones[0].smsOptIn;
                }

                // Emails Information
                if( customer.contact.emails != null && !customer.contact.emails.isEmpty() ) {
                    info.emailType = customer.contact.emails[0].emailType;
                    info.emailAddress = customer.contact.emails[0].address;
                }
            }

            // UserId Information    
            if( call.Channel.contact != null ) {
                info.externalId = call.Channel.contact.userId;
            }
            // info.homeStreet = NOT PRESENT
            // info.homeCity = NOT PRESENT
            // info.homePostalCode = NOT PRESENT
            // info.homeStateCode = NOT PRESENT
            // info.homeCountryCode = NOT PRESENT
            // info.motorcycleCoverage = NOT PRESENT
            // info.longTowAllowed = NOT PRESENT
            // info.longTowKilometersUsed = NOT PRESENT
            // info.longTowMilesUsed = NOT PRESENT

            // info.clubName = NOT PRESENT
            // info.entitlementsAllotted = NOT PRESENT
            // info.entitlementsUsed = NOT PRESENT

            return info;
        }
        
        //Parse from INTFSLWorkorderIntake (api)
        public virtual MembershipInformation parse( INTFSLWorkOrderRequest_Wrapper call ) {
            MembershipInformation info = new MembershipInformation();

            // Membership Information
            info.membershipNumber = call.memberNumber;
            info.membershipType = (call.channel == 'RAP' || call.callType == 'RAP') ? 'RAP' : 'MEMBER';
            info.sponsor = call.contactInformation?.sponsor;
            info.program = call.contactInformation?.program;
            // info.authorizationCode = NOT PRESENT
            // info.authorizationLevel = NOT PRESENT
            // info.isLocalClub = NOT PRESENT
            if(Label.Club_Name == 'ACA') {
                info.membershipLevel =  ACA_CallIntakeUtility.getMembershipLevel(call.contactInformation?.currentBenefitLevel?.toUpperCase());
                info.membershipLevelOnContact =  ACA_CallIntakeUtility.getMembershipLevel(call.contactInformation?.currentBenefitLevel?.toUpperCase());
            }
            else {
                info.membershipLevel =  NE_CallIntakeUtility.getMembershipLevel(call.contactInformation?.currentBenefitLevel?.toUpperCase());
                info.membershipLevelOnContact =  NE_CallIntakeUtility.getMembershipLevel(call.contactInformation?.currentBenefitLevel?.toUpperCase());
            }
            //info.membershipLevel = call.contactInformation?.currentBenefitLevel;
            // info.birthday = NOT PRESENT
            info.membershipStatus = 'Active'; // FIXME: replace hardcoded value with real membership status
            info.memberSince = call.contactInformation?.joinYear;
            // info.expirationDate = NOT PRESENT

            // Language Information
            //info.languagePreference = NOT PRESENT

            // Org Information
            // info.orgPhone = NOT PRESENT
            info.orgName = call.sourceOrgName;
            info.orgCode = call.sourceOrgCode;

            // Contact Information
            // info.contactType = NOT PRESENT
            // info.title = NOT PRESENT
            info.firstName = call.contactInformation?.firstName;
            info.lastName = call.contactInformation?.lastName;
            info.phoneNumber = call.contactInformation?.telephoneNumber?.replaceAll( '\\D', '' );
            // info.phoneType = NOT PRESENT
            // info.phoneExtension = NOT PRESENT
            info.isSmsOptedIn = call.contactInformation?.smsOptin;
    
            // Emails Information
            // info.emailType = NOT PRESENT
            // info.emailAddress = NOT PRESENT
    
            // UserId Information    
            // info.externalId = NOT PRESENT
            // info.homeStreet = NOT PRESENT
            // info.homeCity = NOT PRESENT
            // info.homePostalCode = NOT PRESENT
            // info.homeStateCode = NOT PRESENT
            // info.homeCountryCode = NOT PRESENT
            // info.motorcycleCoverage = NOT PRESENT
            // info.longTowAllowed = NOT PRESENT
            // info.longTowKilometersUsed = NOT PRESENT
            // info.longTowMilesUsed = NOT PRESENT
               info.clubCodeText = call.contactInformation.orgcode; // PR893288-5062 To populate orgcode in club code field on account. 
            // info.clubName = NOT PRESENT
            // info.entitlementsAllotted = NOT PRESENT
            // info.entitlementsUsed = NOT PRESENT
            
            return info;
        }
        
        public virtual MembershipInformation parse( INTMembershipLookupResponse_Wrapper.Customer customer ) {
            MembershipInformation info = new MembershipInformation();

            INTMembershipLookupResponse_Wrapper.ProductInfo prodInfo = customer.productInfo[0];
            
            // Membership Information
            info.membershipNumber = customer.membershipId;
            info.membershipType = customer.membershipType;
            // info.sponsor = ;
            // info.program = ;
            info.authorizationCode = customer.authorize?.code;
            info.authorizationLevel = customer.authorize?.level;
            info.authorizationMessage = prodInfo.authorizationMessage;
            info.authorizationTransactionId = customer.authorize?.transactionId;
            // info.isLocalClub = ;
            if(Label.Club_Name == 'ACA') {
                info.membershipLevel =  ACA_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
                info.membershipLevelOnContact =  ACA_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
            }
            else {
                info.membershipLevel =  NE_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
                info.membershipLevelOnContact =  NE_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
            }
            
            info.birthday = customer.birthDate;
            info.membershipStatus = prodInfo.productStatus;
            info.memberSince = customer.mbrJnAaaDt;            
            info.expirationDate = String.isNotBlank( prodInfo.productExpirationDate ) ? Date.valueOf( prodInfo.productExpirationDate ) : null;

            // Language Information
            // info.languagePreference = ;

            // Org Information
            info.orgName = customer.memberClubName;
            info.orgCode = customer.memberClubCode;
            info.clubCode = customer.memberClubCode;
            info.clubName = customer.memberClubName;

            // Contact Information
            info.contactType = customer.contactType;

            
            info.title = customer.title;
            info.firstName = customer.firstName;
            info.lastName = customer.lastName;
            info.contactType = customer.contactType;
            if( customer.phone != null ) {
                for( Integer phIndex = 0; phIndex < customer.phone.size(); phIndex++ ) {
                    INTMembershipLookupResponse_Wrapper.Phone phone = customer.phone[phIndex];
                    if( phone.isPrimary == 'Yes' ) {
                        info.phoneNumber = phone.phonNumber;
                        info.phoneType = phone.phoneType;
                        info.phoneExtension = phone.phoneExtension;
                        info.isSmsOptedIn = phone.smsOptIn;
                    }
                }
            }
            
            info.emailType = customer.emailType != null ? customer.emailType.toUpperCase() : 'PERSONAL';
            info.emailAddress = customer.emailAddress;
            info.isLocalClub = customer.isLocalClub;
            // info.externalId = ;
            if( customer.address != null && customer.address.size() > 0 ) {
                INTMembershipLookupResponse_Wrapper.Address address = customer.address[0];
                String addressLine1 = address.addressLine1;
                String addressLine2 = String.isNotBlank( address.addressLine2 ) ? '; ' + address.addressLine2 : '';
                info.homeStreet = addressLine1 + addressLine2;
                info.homeCity = address.city;
                info.homePostalCode = address.postCode;
                if( String.isNotBlank( address.country ) ) {
                    info.homeCountryCode = address.country;
                    info.homeStateCode = address.state; 
                }
            }
            info.motorcycleCoverage = prodInfo.motorcycleCoverage == 'Y';
            info.longTowAllowed = customer.entitlement?.longTowAllowed;
            //info.longTowKilometersUsed = String.isBlank( customer.entitlement?.longTowKilometers ) ? 0 : Integer.valueOf( customer.entitlement.longTowKilometers );
            //info.longTowMilesUsed = String.isBlank( customer.entitlement?.longTowMiles ) ? 0 : Integer.valueOf( customer.entitlement.longTowMiles );
            info.clubCode = info.membershipNumber?.substring( 3, 6 );
            if( customer.entitlement != null ) {
                info.entitlementsAllotted = customer.entitlement.callsAllowed != -1 ? customer.entitlement.callsAllowed : null;
                info.entitlementsUsed = customer.entitlement.callsUsed != -1 ? customer.entitlement.callsUsed : null;
                info.homeLockoutEntitled = customer.entitlement.homeLockoutEntitled;
            }

            return info;
        }
    }
}