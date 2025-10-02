@IsTest
private class ImpairmentsHelperTest {

    private static ImpairmentsHelper.IImpairmentsService impHelper = new ImpairmentsHelper.Factory().createService();
    
    @TestSetup
    static void setup() {
        // populate the Impairments database.
        List <ERS_Impairment__c> ersImps = new List<ERS_Impairment__c>();
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED, 'Membership is Canceled',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED_CDX, 'CDX Membership is Canceled',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CAPRE,  'CA Membership was opened today',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_SERVICE_CHARGE,  'Member has used all entitlements',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_SAME_DAY_SERVICE,  'Member has signed up only today',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD,  'Member may be in Renewal',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS,  'Member Not Paid Bills in a while',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_ERS_ABUSER,  'CDX reports ERS Abuser',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_ERS_ABUSER_RVMC,  'ERS Abuser for MC/RV',  True));
        insert ersImps;
    }

    private static FSL_LightningCustomerWrapper createTestData() {

        FSL_LightningCustomerWrapper mvCustomer = new FSL_LightningCustomerWrapper();
        mvCustomer.memberships = new List<FSL_LightningMembershipWrapper>();
        mvCustomer.statusCode = '200';
        mvCustomer.membership = new FSL_LightningMembershipWrapper();
        mvCustomer.memberships.add(mvCustomer.membership);
        mvCustomer.membership.originalMemberId = '6200041234567890';
        mvCustomer.membership.id = '6200041234567890';
        mvCustomer.membership.isLocalClub = true;
        mvCustomer.membership.primaryValid = 'Y';
        mvCustomer.membership.primaryPaid = 'Y';
        
        mvCustomer.membership.cancelCode = '';
        mvCustomer.membership.cancelType = '';
        mvCustomer.membership.inArrears = 'N';
        mvCustomer.membership.inRenewal = 'N';

        mvCustomer.membership.entitlements = new List<FSL_LightningEntitlementWrapper>();
        mvCustomer.membership.entitlements.add(new FSL_LightningEntitlementWrapper());
        mvCustomer.membership.entitlements[0].serviceChargeIndicator = false;
        mvCustomer.membership.entitlements[0].sameDayService = false;
        mvCustomer.membership.entitlements[0].CAPREeligible = false;
        mvCustomer.customProperties = new List<FSL_CustomPropertiesWrapper>();
        mvCustomer.customProperties.add(new FSL_CustomPropertiesWrapper());
        mvCustomer.customProperties.add(new FSL_CustomPropertiesWrapper());

        mvCustomer.customProperties[0].name = 'name';
        mvCustomer.customProperties[0].value = 'value';
        mvCustomer.customProperties[1].name = 'name';
        mvCustomer.customProperties[1].value = 'value';
        
        mvCustomer.membership.authorizationCode = '1234567';
        mvCustomer.membership.authorizationLevel = 'C';
        mvCustomer.membership.ersAbuser = '';
        mvCustomer.membership.motorCycleIndicator = '';
        
        return mvCustomer;
    }

    private static ServiceContract createServiceContract(){
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        Account acc = new Account(name='Test Account');
        insert acc;
        ServiceContract  sc1 = new ServiceContract ();
        sc1.AccountId = acc.id;
        sc1.Name= 'sample contract';
        sc1.Pricebook2Id= customPB.id;
        sc1.StartDate =system.today();
        sc1.EndDate =  System.today()+20;
        sc1.AAA_ACA_Member_Status__c = 'Active' ; 
        sc1.AAA_Total_of_Calls_Allowed__c = 4;
        insert sc1;
        return sc1 ; 
    }

    private static INTMembershipLookupResponse_Wrapper.Customer createCustomerTestData() {

        INTMembershipLookupResponse_Wrapper.Customer mvCustomer = new INTMembershipLookupResponse_Wrapper.Customer();
        mvCustomer.membershipId = '6200041234567890';
        mvCustomer.memberLevel = 'Basic';
        mvCustomer.pniFlag = '';
        mvCustomer.birthDate = '';
        
        mvCustomer.gender = 'Male';
        mvCustomer.maritalStatus = '';
        mvCustomer.title = '';
        mvCustomer.firstName = 'John';
        mvCustomer.lastName = 'Doe';
        mvCustomer.otherName = '';
        mvCustomer.licState = '';
        mvCustomer.mbrSuplTelNr = '';
        mvCustomer.mbrJnAaaDt = '';
        mvCustomer.mbrsPaidThruDt = '';
        
      
        // Also populate the Impairments database.
/*
        List <ERS_Impairment__c> ersImps = new List<ERS_Impairment__c>();
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED, 'Membership is Canceled',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED_CDX, 'CDX Membership is Canceled',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_CAPRE,  'CA Membership was opened today',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_SERVICE_CHARGE,  'Member has used all entitlements',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_SAME_DAY_SERVICE,  'Member has signed up only today',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD,  'Member may be in Renewal',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS,  'Member Not Paid Bills in a while',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_ERS_ABUSER,  'CDX reports ERS Abuser',  True));
        ersImps.add(createImpairment(ImpairmentsHelper.IMPAIRMENT_TYPE_ERS_ABUSER_RVMC,  'ERS Abuser for MC/RV',  True));
      
        insert ersImps;
*/
        return mvCustomer;
    }


    private static ERS_Impairment__c createImpairment(String name, String instructions, Boolean pymntReqd) {
        ERS_Impairment__c  imp = new ERS_Impairment__c(Name = name, Instructions__c = instructions, Payment_Required__c = True);
        imp.Payment_Collected_Comment__c = name + ': Comment for Payment_Collected';
        imp.COD_Comment__c = name + ': Comment for COD';
        imp.Cancel_Service_Comment__c = name + ': Comment for Cancel_Service';
        imp.Override_Comment__c = name + ': Comment for Override';
        return imp;
    }

    private static Boolean matchImpairment(String impairmentId, String impType) {

        Boolean result = false;
        if ( !String.isBlank(impairmentId) ) {
            List<ERS_Impairment__c> impairments = [Select Id, Name, Instructions__c, Payment_Required__c FROM ERS_Impairment__c WHERE Id = :impairmentId];
            if ( impairments.size() > 0 ) {
                result = impairments[0].Name.equals(impType);
            }
        }
        return result;
    }

    @IsTest
    private static void testImpairmentsHelper_resultCodeNot200_NoImpairments () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.statusCode = '401';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( False, matchImpairment(impairmentId, ''), 'Expected No Impairment due to statusCode not 200' );
        Test.stopTest();
    }

    @IsTest
    private static void testNoImpairments () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertNotEquals(impairmentId, null);
        System.assertEquals( False, matchImpairment(impairmentId, ''), 'Expected No Impairment' );
        Test.stopTest();
    }


    // @IsTest
    // private static void testCAPREImpairment_Yes () {

    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.entitlements[0].CAPREeligible = true;
    //     mvCustomer.membership.entitlements[0].sameDayService = true;

    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CAPRE ), 'Expected Impairment to be CAPRE' );
    //     Test.stopTest();
    // }

    @IsTest
    private static void testCAPREImpairment_No () {

        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.entitlements[0].CAPREeligible = false;
        mvCustomer.membership.entitlements[0].sameDayService = false;

        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( False, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CAPRE ), 'Expected to not flag CAPRE' );
        Test.stopTest();
    }

    // @IsTest
    // private static void testSameDayServiceImpairment_Yes () {

    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.entitlements[0].CAPREeligible = true;
    //     mvCustomer.membership.entitlements[0].sameDayService = true;
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CAPRE), 'Expected Impairment to be CAPRE because club code is 004' );
        
    //     // Now make it a non ACE CA Club
    //     mvCustomer.membership.originalMemberId = '62025141234567890';
    //     mvCustomer.membership.id = '6202511234567890';
    //     mvCustomer.customProperties[1].name = 'name';
    //     mvCustomer.customProperties[1].value = 'value';

    //     impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_SAME_DAY_SERVICE), 'Expected Impairment to be Same Day Service' );

     
    //     mvCustomer.membership.entitlements[0].CAPREeligible = false;
    //     impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_SAME_DAY_SERVICE), 'Expected Impairment to be Same Day Service because is not CA club');


    //     Test.stopTest();
    // }

    @IsTest
    private static void testSameDayServiceImpairment_PaidCAPRE () {

        Test.startTest();
        INTMembershipLookupResponse_Wrapper.Customer mvCustomer = createCustomerTestData();
        FSL_LightningEntitlementWrapper entWrap = new FSL_LightningEntitlementWrapper(); 
        entWrap.sameDayService = false ; 
        mvCustomer.entitlement = entWrap ; 

        AAA_ServiceContractUtility.ContractInformationWrapper contWrapper = new AAA_ServiceContractUtility.ContractInformationWrapper(); 
        contWrapper.membershipContract = createServiceContract(); 

        String impairmentId = impHelper.extractMembershipImpairmentForLocal(mvCustomer,contWrapper);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_SAME_DAY_SERVICE), 'Expected Impairment to be Same Day Service' );
        Test.stopTest();
    }

    // @IsTest
    // private static void testServiceChargeImpairment_Yes () {

    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.entitlements[0].serviceChargeIndicator = true;
    //     mvCustomer.membership.cancelCode = '';
    //     mvCustomer.membership.inRenewal = '';
    //     mvCustomer.membership.inArrears = '';
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_SERVICE_CHARGE ), 'Expected Impairment to be Service Charge' );
    //     Test.stopTest();
    // }


    // @IsTest
    // private static void testServiceChargeImpairment_Zero_Calls_Remaining () {

    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.entitlements[0].serviceChargeIndicator = false;
    //     mvCustomer.membership.entitlements[0].callsRemaining = 0;
    //     mvCustomer.membership.cancelCode = '';
    //     mvCustomer.membership.inRenewal = '';
    //     mvCustomer.membership.inArrears = '';
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_SERVICE_CHARGE ), 'Expected Impairment to be Service Charge' );
    //     Test.stopTest();
    // }

    @IsTest
    private static void testServiceChargeImpairment_Zero_Calls_Remaining_Canceled () {

        Test.startTest();
        INTMembershipLookupResponse_Wrapper.Customer mvCustomer = createCustomerTestData();
        mvCustomer.membershipStatus = ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED ; 

        String impairmentId = impHelper.extractMembershipImpairmentForLocal(mvCustomer,new AAA_ServiceContractUtility.ContractInformationWrapper());
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED), 'Expected Impairment to be Canceled' );
        Test.stopTest();
    }

    @IsTest
    private static void testNoCustomProperties () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.customProperties = new List<FSL_CustomPropertiesWrapper>();
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( False, matchImpairment(impairmentId, ''), 'Expected No Impairment' );
        ImpairmentsHelper imph = new ImpairmentsHelper();
        Test.stopTest();
    }

    @IsTest
    private static void testCancelledImpairment () {
        Test.startTest();
        INTMembershipLookupResponse_Wrapper.Customer mvCustomer = createCustomerTestData();
    
        AAA_ServiceContractUtility.ContractInformationWrapper contWrapper = new AAA_ServiceContractUtility.ContractInformationWrapper(); 
        contWrapper.membershipContract = createServiceContract(); 
        contWrapper.membershipContract.AAA_ACA_Member_Status__c = ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED ; 
        String impairmentId = impHelper.extractMembershipImpairmentForLocal(mvCustomer,contWrapper);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED), 'Expected Impairment to be Canceled' );
        Test.stopTest();
    }

    @IsTest
    private static void testInRenewalMember_NoImpairmentFlagged() {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.inRenewal = 'Some Value';
        mvCustomer.membership.primaryValid = 'Y';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( False, matchImpairment(impairmentId, ''), 'Expected No Impairment' );
        Test.stopTest();
    }

     
    // @IsTest
    // private static void test1To30DaysImpairment () {
    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.inRenewal = 'In Renewal';
    //     mvCustomer.membership.inArrears = '';
    //     mvCustomer.membership.cancelCode = '';
    //     Date testDate = Date.today().addYears(1).addDays(-10);
    //     mvCustomer.membership.renewalExpirationDate = testDate.format();

    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD ), 'Expected Impairment to be 1-30 Days after Expiration' );
    //     mvCustomer.membership.primaryPaid = 'N';
    //     impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD ), 'Expected Impairment to be 1-30 Days after Expiration' );

    //     Test.stopTest();
    // }

    // @IsTest
    // private static void test31to95DaysImpairment () {
    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.inArrears = 'Y';
    //     mvCustomer.membership.cancelCode = '';
    //     Date testDate = Date.today().addYears(1).addDays(-41);
    //     mvCustomer.membership.renewalExpirationDate = testDate.format();
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS ), 'Expected Impairment to be 31-90 Days after Expiration' );
    //     Test.stopTest();
    // }

    // @IsTest
    // private static void test31to60DaysImpairmentForACMO_Under60 () {
    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.id = '6200651234567890';
    //     mvCustomer.membership.inArrears = 'Y';
    //     mvCustomer.membership.cancelCode = '';
    //     Date testDate = Date.today().addYears(1).addDays(-48);
    //     mvCustomer.membership.renewalExpirationDate = testDate.format();
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS ), 'Expected Impairment to be 31-95 Days after Expiration' );
    //     Test.stopTest();
    // }

    @IsTest
    private static void test31to60DaysImpairmentForACMO_Over60 () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.id = '6200651234567890';
        mvCustomer.membership.inArrears = 'Y';
        mvCustomer.membership.cancelCode = '';
        Date testDate = Date.today().addYears(1).addDays(-65);
        mvCustomer.membership.renewalExpirationDate = testDate.format();
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( false, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS ), 'Expected Impairment not to be 31-95 Days after Expiration' );
        Test.stopTest();
    }
    // @IsTest
    // private static void test95PlusDaysImpairment () {
    //     Test.startTest();
    //     FSL_LightningCustomerWrapper mvCustomer = createTestData();
    //     mvCustomer.membership.inArrears = 'Y';
    //     mvCustomer.membership.cancelCode = '';
    //     Date testDate = Date.today().addYears(1).addDays(-98);
    //     mvCustomer.membership.renewalExpirationDate = testDate.format();
    //     String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
    //     System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED ), 'Expected Impairment to be CANCELED' );
    //     Test.stopTest();
    // }

    @IsTest
    private static void testCDXImpairmentCanceledStatus () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.customProperties[0].name = ImpairmentsHelper.MV_CUSTOM_PROPERTY_NAME_CANCELED;
        mvCustomer.customProperties[0].value = 'ImpairmentsText';
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.authorizationLevel = 'P';
        mvCustomer.membership.authorizationCode = '12345678';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED_CDX ), 'Expected Impairment to be Canceled' );
        Test.stopTest();
    }

    private static void testCDXImpairmentAuthCodeMissing() {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.authorizationCode = '';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED_CDX ), 'Expected Impairment to be Canceled' );
        Test.stopTest();
    }

    @IsTest
    private static void testCDXImpairmentAuthLevelCOD () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.authorizationLevel = 'C';
        mvCustomer.membership.authorizationCode = '12345678';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED_CDX ), 'Expected Impairment to be Canceled' );
        Test.stopTest();
    }
    @IsTest
    private static void testCDXNoImpairment () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.authorizationLevel = 'P';
        mvCustomer.membership.authorizationCode = '12345678';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( False, matchImpairment(impairmentId, ''), 'Expected No Impairment' );
        Test.stopTest();
    }

    @IsTest
    private static void testCDXImpairmentERSAbuser () {
        Test.startTest();
        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.authorizationLevel = 'P';
        mvCustomer.membership.authorizationCode = '12345678';
        mvCustomer.membership.ersAbuser = 'Y';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);
        System.assertEquals( True, matchImpairment(impairmentId, ImpairmentsHelper.IMPAIRMENT_TYPE_ERS_ABUSER), 'Expected Impairment to be ERS Abuser (CDX)' );
        Test.stopTest();
    }

    @IsTest
    private static void testCreateImpairmentResolutionFeedComment () {
        Test.startTest();

        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case objcs = new Case();
        objcs = ACG_TestDataFactory.createcase(recordTypeID,'Canceled','Phone', false);


        FSL_LightningCustomerWrapper mvCustomer = createTestData();
        mvCustomer.membership.isLocalClub = false;
        mvCustomer.membership.cancelCode = '500';
        mvCustomer.membership.inRenewal = '';
        mvCustomer.membership.inArrears = '';
        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);

        objCs.impairment__c = impairmentId;
        insert objCs;
        ImpairmentsHelper.createFeedRecord(objcs.Id);

        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone', false);
        objCs.impairment__c = impairmentId;
        objCs.impairment_Payment_Collected__c = true;
        insert objCs;
        ImpairmentsHelper.createFeedRecord(objcs.Id);

        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone', false);
        objCs.impairment__c = impairmentId;
        objCs.Impairment_COD_Payment__c = true;
        insert objCs;
        ImpairmentsHelper.createFeedRecord(objcs.Id);

        
        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone', false);
        objCs.impairment__c = impairmentId;
        objCs.Impairment_Supervisor_Override__c = true;
        insert objCs;
        ImpairmentsHelper.createFeedRecord(objcs.Id);
        
         ImpairmentsHelper.getEntitlementDetailsbyCaseId(objcs.Id);

        Test.stopTest();
    }

    @IsTest
    private static void testCreateFullBodiedMVObjects () {
        Test.startTest();

        FSL_LightningCustomerWrapper mvCustomer = createTestData();

        mvCustomer.membership.membershipType = '';
        mvCustomer.membership.sponsor = '';
        mvCustomer.membership.program = '';
        mvCustomer.membership.authorizationCode = '';
        mvCustomer.membership.authorizationLevel = '';
        mvCustomer.membership.authorizationCode = '';
        mvCustomer.membership.expirationDate = '';
        mvCustomer.membership.memberLevel = '';
        mvCustomer.membership.memberBirthDay = '';
        mvCustomer.membership.memberSince = '';
        mvCustomer.membership.memberStatus = '';
        mvCustomer.membership.goodwill = '';
        mvCustomer.membership.program = '';
        mvCustomer.membership.programName = '';
        mvCustomer.membership.programPhone = '';
        mvCustomer.membership.programMaxMileage = '';
        
        mvCustomer.membership.org = new FSL_LightningSystemOrganizationWrapper();
        mvCustomer.membership.org.code = '';
        mvCustomer.membership.org.name = '';
        
        mvCustomer.membership.cdxMessage = '';
        mvCustomer.membership.ersAbuser = '';
        mvCustomer.membership.badCheck = '';
        mvCustomer.membership.motorcycleIndicator = '';

        mvCustomer.membership.totalPastDue = '';
        mvCustomer.membership.totalAmountApplied = '';
        mvCustomer.membership.totalAmountDue = '';
        
        mvCustomer.membership.renewalExpirationDate = '';
        mvCustomer.membership.membershipPaidThroughDate = '';
        mvCustomer.membership.billPlan = '';

        mvCustomer.membership.entitlements[0].associates = 0;
        mvCustomer.membership.entitlements[0].chargeableCalls = 0;
        mvCustomer.membership.entitlements[0].currentCalls = 0;
        mvCustomer.membership.entitlements[0].callsAllowed = 0;
        mvCustomer.membership.entitlements[0].callsRemaining = 0;
        mvCustomer.membership.entitlements[0].callsUsed = 0;
        mvCustomer.membership.entitlements[0].callsAllowed = 0;
        mvCustomer.membership.entitlements[0].longTowKilometers = 0;
        mvCustomer.membership.entitlements[0].longTowMiles = 0;
        mvCustomer.membership.entitlements[0].rentalDays = 0;
        mvCustomer.membership.entitlements[0].specialMemberType = 0;
        mvCustomer.membership.entitlements[0].onlineGarageMember = false;
        mvCustomer.membership.entitlements[0].longTowAllowed = false;
        mvCustomer.membership.entitlements[0].homeLockoutEntitled = false;
        mvCustomer.membership.entitlements[0].carRentalEntitled = false;
        mvCustomer.membership.entitlements[0].RVUsage = false;

        
        mvCustomer.contact = new FSL_LightningContactWrapper();
        mvCustomer.languagePreference = '';
        mvCustomer.impairments = new List<FSL_MembershipImpairmentWrapper>();
        mvCustomer.foi = new FSL_LightningCustomerWrapper.Foi();
        mvCustomer.foi.foiType = '';
        mvCustomer.foi.location = new FSL_LightningCustomerWrapper.Location(); 
        mvCustomer.foi.location.latitude = '';
        mvCustomer.foi.location.longitude = '';

        mvCustomer.foi.location.address = new FSL_LightningCustomerWrapper.Address(); 
        mvCustomer.foi.location.address.addressType = '';
        mvCustomer.foi.location.address.full = '';
        mvCustomer.foi.location.address.streetName = '';
        mvCustomer.foi.location.address.streetNumber = '';
        mvCustomer.foi.location.address.street = '';
        mvCustomer.foi.location.address.streetDirection = '';
        mvCustomer.foi.location.address.line2 = '';
        mvCustomer.foi.location.address.crossStreet = '';
        mvCustomer.foi.location.address.city = '';
        mvCustomer.foi.location.address.state = '';
        mvCustomer.foi.location.address.postalCode = '';
        mvCustomer.foi.location.address.country = '';

        Test.stopTest();
    }

    @IsTest
    private static void testGetDaysPastDue () {

        Test.startTest();
        ImpairmentsHelper.ImpairmentsService impH = new ImpairmentsHelper.ImpairmentsService(null, null);
       
        Integer numDaysPast = 0;
        Integer tolerance = 1;
        for (Integer i = -150; i < 160; i = i+5) {
            Date testDate = Date.today().addYears(1).addDays(i);
            numDaysPast = impH.getDaysPastExpiration(testDate.format());

            Assert.isTrue(numDaysPast+i <= tolerance, 'Expecting the days past expiration to match the offset applied');
        }

        numDaysPast = impH.getDaysPastExpiration('');
        System.assertEquals(numDaysPast, -1, 'Expecting the days past expiration to matc the offset applied');

        numDaysPast = impH.getDaysPastExpiration(null);
        System.assertEquals(numDaysPast, -1, 'Expecting the days past expiration to matc the offset applied');
       
        Test.stopTest();
    }

    @IsTest
    private static void testWithPopulatedCustomerObject () {
        Test.startTest();

        FSL_LightningCustomerWrapper mvCustomer = createTestData();

        mvCustomer.membership.membershipType = 'MEMBER';
        mvCustomer.membership.sponsor = '';
        mvCustomer.membership.isLocalClub = true;
        mvCustomer.membership.authorizationCode = '';
        mvCustomer.membership.authorizationLevel = '';
        mvCustomer.membership.authorizationCode = '';
        mvCustomer.membership.expirationDate = '2023-12-01';
        mvCustomer.membership.memberLevel = 'PLUS';
        mvCustomer.membership.primaryValid = 'Y';
        mvCustomer.membership.primaryPaid = '';
        mvCustomer.membership.inArrears = 'Y';
        mvCustomer.membership.cancelCode = '';
        mvCustomer.membership.cancelType = '';
        mvCustomer.membership.inRenewal = 'Y';
        mvCustomer.membership.memberSince = '2017';
        mvCustomer.membership.memberStatus = 'VALD';
        mvCustomer.membership.goodwill = '';
        mvCustomer.membership.program = '';
        mvCustomer.membership.programName = '';
        mvCustomer.membership.programPhone = '';
        mvCustomer.membership.programMaxMileage = '';
        
        mvCustomer.membership.org = new FSL_LightningSystemOrganizationWrapper();
        mvCustomer.membership.org.code = '';
        mvCustomer.membership.org.name = '215';
        
        mvCustomer.membership.cdxMessage = '';
        mvCustomer.membership.ersAbuser = '';
        mvCustomer.membership.badCheck = '';
        mvCustomer.membership.motorcycleIndicator = '';

        mvCustomer.membership.totalPastDue = '';
        mvCustomer.membership.totalAmountApplied = '';
        mvCustomer.membership.totalAmountDue = '';
        
        mvCustomer.membership.renewalExpirationDate = '12/01/2023';
        mvCustomer.membership.membershipPaidThroughDate = '';
        mvCustomer.membership.billPlan = '';

        mvCustomer.membership.entitlements[0].associates = 0;
        mvCustomer.membership.entitlements[0].chargeableCalls = 0;
        mvCustomer.membership.entitlements[0].currentCalls = 0;
        mvCustomer.membership.entitlements[0].callsAllowed = 0;
        mvCustomer.membership.entitlements[0].callsRemaining = 4;
        mvCustomer.membership.entitlements[0].callsUsed = 0;
        mvCustomer.membership.entitlements[0].callsAllowed = 0;
        mvCustomer.membership.entitlements[0].longTowKilometers = 0;
        mvCustomer.membership.entitlements[0].longTowMiles = 0;
        mvCustomer.membership.entitlements[0].rentalDays = 0;
        mvCustomer.membership.entitlements[0].specialMemberType = 0;
        mvCustomer.membership.entitlements[0].onlineGarageMember = false;
        mvCustomer.membership.entitlements[0].longTowAllowed = false;
        mvCustomer.membership.entitlements[0].homeLockoutEntitled = false;
        mvCustomer.membership.entitlements[0].carRentalEntitled = false;
        mvCustomer.membership.entitlements[0].RVUsage = false;

        
        mvCustomer.contact = new FSL_LightningContactWrapper();
        mvCustomer.languagePreference = '';
        mvCustomer.impairments = new List<FSL_MembershipImpairmentWrapper>();
        mvCustomer.foi = new FSL_LightningCustomerWrapper.Foi();
        mvCustomer.foi.foiType = '';
        mvCustomer.foi.location = new FSL_LightningCustomerWrapper.Location(); 
        mvCustomer.foi.location.latitude = '';
        mvCustomer.foi.location.longitude = '';

        mvCustomer.foi.location.address = new FSL_LightningCustomerWrapper.Address(); 
        mvCustomer.foi.location.address.addressType = '';
        mvCustomer.foi.location.address.full = '';
        mvCustomer.foi.location.address.streetName = '';
        mvCustomer.foi.location.address.streetNumber = '';
        mvCustomer.foi.location.address.street = '';
        mvCustomer.foi.location.address.streetDirection = '';
        mvCustomer.foi.location.address.line2 = '';
        mvCustomer.foi.location.address.crossStreet = '';
        mvCustomer.foi.location.address.city = '';
        mvCustomer.foi.location.address.state = '';
        mvCustomer.foi.location.address.postalCode = '';
        mvCustomer.foi.location.address.country = '';

        String impairmentId = impHelper.checkAndExtractMembershipImpairment(mvCustomer);


        Test.stopTest();
    }  
      @IsTest
    private static void testImpairmentsHelper_isClubACECA_isClubACMO() {
        Test.startTest();
        ImpairmentsHelper.ImpairmentsService impServ = new ImpairmentsHelper.ImpairmentsService(null, null);
        Boolean isClubACECA = impServ.isClubACECA('6202401507528001');
        Boolean isClubACMO  = impServ.isClubACMO('6202401507528001');
        Test.stopTest();
    }


}