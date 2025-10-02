/*
``@description: helper class for ACG_GlobalSearchController class
  @date: August 23, 2021
  @author: Deloitte Consulting
*/
public inherited sharing class ACG_GlobalSearchControllerHelper {

    //private static final Id MEMBER_RECORD_TYPE_ID = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
	//private static final Id Customer_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId();	//ERS
    private static final Id MEMBERSC_RECORD_TYPE_ID = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get('Member').getRecordTypeId();	//Member SC
	private static final Id HOUSEHOLDSC_RECORD_TYPE_ID = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();	//Household SC
    @testVisible
    private static FSL_Account.IFactory accountFactory = new FSL_Account.Factory();
    
    //ERS-229202, //ERS-230821
    public static ACG_GlobalSearchController.MbrValAPIWrapper performUpsertOnLookupRecord(String sMemberId, INTMembershipLookupResponse_Wrapper response, String guid) {
        ACG_GlobalSearchController.MbrValAPIWrapper mvWrapper = new ACG_GlobalSearchController.MbrValAPIWrapper();

        FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
        FSL_Account.IAccountService service = accountFactory.createService();
        
        FSL_Account.MembershipInformation info = parser.parse( response.customers.customer[0] );
        INTMembershipLookupResponse_Wrapper.Customer customer = response.customers.customer[0];
        transformCountryCode(info);
        List<Club_Name_Mappings__mdt> records = [SELECT Id,Club_Name__c,Club_Code__c 
                                                FROM Club_Name_Mappings__mdt 
                                                WHERE Club_Code__c = :info.clubCode];
        if( records?.size() > 0 ) {
            string mdtRec = records[0].Club_Name__c;
            for(Schema.PicklistEntry ple1 : Account.ACG_Club_Name__c.getDescribe().getPicklistValues()) {
                if( mdtRec == ple1.getValue() && ple1.isActive() ) {
                    info.clubName = ple1.getValue();
                    break;
                }
            }
        }
        //Find Existing or Create new PersonAccount based on the information received in the lookup response
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );
        mvWrapper.recordId = accounts[0].Id;
        System.debug('@@@ Accounts --> ' + accounts[0].Id) ; 
        System.debug('@@@ customer --> ' + customer) ; 
        System.debug('@@@ customer.isLocalClub --> ' + customer.isLocalClub) ; 

        if(accounts.size() > 0 && !customer.isLocalClub){
            AAA_FeedbackIncomingAuthUtil.createOpenFeedback(customer, accounts[0].Id);
        }
        system.debug('@@@@ customer @@@@'+customer);
        //create Service Contract record only if it is Local Club
        if(accounts.size() > 0 && customer.isLocalClub) {
            AAA_ServiceContractUtility.ContractInformationWrapper cWrap = AAA_ServiceContractUtility.getOrCreateMembershipContract( response.customers.customer[0], system.Now(), accounts[0].Id);
            mvWrapper.inMemberContract = cWrap.membershipContract;
            mvWrapper.showImpairment = cWrap.showImpairment;
            mvWrapper.impairmentType = cWrap.impairmentType;
            mvWrapper.isLocalclub = customer.isLocalClub;
            mvWrapper.sameDayService = customer.entitlement.sameDayService;
            mvWrapper.accountId = accounts[0].Id;
            system.debug('@@@@ mvWrapper.inMemberContract'+ mvWrapper.inMemberContract);
            system.debug('@@@@ mvWrapper.showImpairment'+ mvWrapper.showImpairment);
            system.debug('@@@@ mvWrapper.impairmentType'+ mvWrapper.impairmentType);
            if(cWrap.membershipContract != null && mvWrapper.impairmentType == null) {
                mvWrapper.impairmentType = new ImpairmentsHelper.Factory().createService().extractMembershipImpairmentForLocal(customer,cWrap);
            }
            system.debug('@@@@ mvWrapper.impairmentType'+ mvWrapper.impairmentType);
        }else if(!customer.isLocalClub){
            ACG_GlobalSearchController.EntitlementsWrapper ent = new ACG_GlobalSearchController.EntitlementsWrapper();
            mvWrapper.impairmentType = response.impairmentType; 
            if(response.impairmentType != null) {
                mvWrapper.showImpairment = true;
            }
            mvWrapper.isLocalclub = customer.isLocalClub;
            mvWrapper.sameDayService = customer.entitlement.sameDayService;
            ent.authorizationCode = customer.authorize.code;
            ent.authorizationLevel = customer.authorize.level;
            ent.callsRemaining = customer.entitlement.callsRemaining;
            mvWrapper.outMemberContract = ent;
        }
        return mvWrapper;
    }
    /**********
    * @Method Name: transformCountryCode
    * @Parameters: FSL_Account.MembershipInformation
    * @Description: Transforms the country codes to salesforce configured values
    **************/
    private static void transformCountryCode(FSL_Account.MembershipInformation info){
        if(info.homeCountryCode != null){
            switch on info.homeCountryCode {
                when 'USA', 'United States', 'US' {
                    info.homeCountryCode = 'US';
                }
                when 'Canada', 'CA','CAN' {
                    info.homeCountryCode = 'CA';
                }
                when else {
                    info.homeCountryCode = 'US';
                }
            }
        }
    }
}