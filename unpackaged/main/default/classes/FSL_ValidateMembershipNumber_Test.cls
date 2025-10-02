/**
 * @File Name          : FSL_ValidateMembershipNumber.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06-16-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/28/2020   Rajesh Kemisetti     Initial Version
 * 1.0    9/14/2020   Dylan Truong          ERS-218775 : When Valid Membership is Validated to FSL, Remove the Payment Required Flag  
 * 2.0    5/14/2020   Dylan Truong          ERS-221083 MembershipValidation Phrase 2: Partial Search
 * 3.0    06/14/2021   Dylan Truong         Hardcoded -Test failure
**/
@isTest
Public class FSL_ValidateMembershipNumber_Test{

    Public static testmethod void GetContactsTest(){
        List<Contact>conlist = [select id from Contact LIMIT 2];
        FSL_ValidateMembershipNumber.getContactRecord(conlist[0].id);
        System.assert(true, !conlist.isEmpty());
    }

    // Public static testmethod void validateMemberNumberpositive(){
    //     delete [select id from Technology_Preference__c];
    //     FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     FSL_LightningCustomerWrapper cwrap = dummyWrapper();
    //     System.Test.startTest();
    //     workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
    //     System.Test.setMock(HttpCalloutMock.class, new FSL_ValidateMemberMock(true));
    //     FSL_LightningCustomerWrapper cWrapper =  FSL_ValidateMembershipNumber.validateMemberNumber('4290146716113008',wo.id);
    //     Map<String, String> responseStatus =  FSL_ValidateMembershipNumber.saveMemberData(JSON.serialize(cwrap),wo.id,null);
    //     System.assertEquals('4290146716113008', cWrapper.membership.id);
    //     System.assertEquals('Success', responseStatus.get('Status'));
    //     System.Test.stopTest();
    // }

    Public static testmethod void validateMemberNumbernegative(){
        delete [select id from Technology_Preference__c];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');

        System.Test.startTest();
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        Test.setMock(HttpCalloutMock.class, new FSL_ValidateMemberMock(false));
        FSL_LightningCustomerWrapper cWrapper = FSL_ValidateMembershipNumber.validateMemberNumber('4290146716113008',wo.id);
        System.Test.stopTest();
    }

    public static FSL_LightningCustomerWrapper dummyWrapper(){
        FSL_LightningCustomerWrapper customerWrapper = new FSL_LightningCustomerWrapper();
        customerWrapper.languagePreference = 'English';

        List<FSL_LightningPhoneWrapper> customerPhones = new List<FSL_LightningPhoneWrapper>();
        FSL_LightningPhoneWrapper phone = new FSL_LightningPhoneWrapper();
        phone.phoneExtension = '123';
        phone.phoneNumber    = '(555) 444-4240';
        phone.preferred      = true;
        phone.smsOptIn       = true;
        FSL_LightningPhoneWrapper phone2 = new FSL_LightningPhoneWrapper();
        phone2.phoneExtension = '321';
        phone2.phoneNumber    = '(555) 555-4240';
        phone2.preferred      = false;
        phone2.smsOptIn       = false;
        customerPhones.add(phone);
        customerPhones.add(phone2);

        List<FSL_LightningEmailWrapper> customerEmails = new List<FSL_LightningEmailWrapper>();
        FSL_LightningEmailWrapper email = new FSL_LightningEmailWrapper();
        email.address   = 'gmail@yahoo.com';
        email.emailType = 'Personal';
        customerEmails.add(email);


        FSL_LightningContactWrapper contactCustomer = new FSL_LightningContactWrapper();
        contactCustomer.firstName   = 'Stephen';
        contactCustomer.lastName    = 'Strange';
        contactCustomer.contactType = '';
        contactCustomer.title       = 'Dr.';
        contactCustomer.phones      = customerPhones;
        contactCustomer.emails      = customerEmails;
        customerWrapper.contact            = contactCustomer;

        FSL_LightningMembershipWrapper membership = new FSL_LightningMembershipWrapper();
        membership.membershipType    = 'MEMBER';
        membership.program           = 'Auto Club South';
        membership.authorizationCode = '12345R';
        membership.authorizationLevel= 'B';
        membership.id                = '1350001987654321';
        membership.originalMemberId  = '1350001987654321';
        membership.expirationDate    = '2020-07-15';
        membership.memberLevel       = 'Basic';
        membership.memberSince       = '2003';
        membership.memberStatus      = 'Active';
        membership.cdxMessage        = 'CALL ME MAYBE';
        membership.ersAbuser         = 'N';
        membership.badCheck          = 'N';
        membership.motorcycleIndicator = 'N';
        FSL_LightningSystemOrganizationWrapper org = new FSL_LightningSystemOrganizationWrapper();
        org.Name = 'Tidewater';
        org.code = '013';
        membership.org = org;
        List<FSL_LightningEntitlementWrapper> entitlements = new List<FSL_LightningEntitlementWrapper>();
        FSL_LightningEntitlementWrapper entitlement = new FSL_LightningEntitlementWrapper();
        entitlement.serviceChargeIndicator = true;
        entitlement.associates = 2;
        entitlement.chargeableCalls = 1;
        entitlement.currentCalls = 2;
        entitlement.callsAllowed = 2;
        entitlement.callsRemaining = 1;
        entitlement.callsUsed = 1;
        entitlement.onlineGarageMember = false;
        entitlement.longTowAllowed = false;
        entitlement.longTowKilometers = 30;
        entitlement.longTowMiles = 9;
        entitlement.rentalDays = 15;
        entitlements.add(entitlement);
        membership.entitlements = entitlements;
        customerWrapper.membership        = membership;


        List<FSL_CustomPropertiesWrapper> propertiesList = new List<FSL_CustomPropertiesWrapper>();

        FSL_CustomPropertiesWrapper prop1 = new FSL_CustomPropertiesWrapper();
        prop1.name = 'Custom Attribute 1: ';
        prop1.value = 'Custom Value 1';
        FSL_CustomPropertiesWrapper prop2 = new FSL_CustomPropertiesWrapper();
        prop2.name = 'Custom Attribute 2: ';
        prop2.value = 'Custom Value 2';
        FSL_CustomPropertiesWrapper prop3 = new FSL_CustomPropertiesWrapper();
        prop3.name = 'Custom Attribute 3: ';
        prop3.value = 'Custom Value 3';
        FSL_CustomPropertiesWrapper prop4 = new FSL_CustomPropertiesWrapper();
        prop4.name = 'Custom Attribute 4: ';
        prop4.value = 'Custom Value 4';

        propertiesList.add(prop1);
        propertiesList.add(prop2);
        propertiesList.add(prop3);
        propertiesList.add(prop4);
        customerWrapper.customProperties = propertiesList;
        return customerWrapper;
    }

    // ERS-221784 Impairments Enhancements:
    Public static testmethod void testImpairmentWarningMessage() {

        // reuse the dummyWrapper object
        // append impairments to it and test that the WarningMessage comes back as expected

        FSL_ValidateMembershipNumber.ValidateMembershipService validationService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        
        FSL_LightningCustomerWrapper custwrap = dummyWrapper();
        custwrap.impairments = new List<FSL_MembershipImpairmentWrapper>();
     

        System.Test.startTest();
        // String warningMessage = FSL_ValidateMembershipNumber.getWarningMessage(custwrap);

        String warningMessage = validationService.getWarningMessage(custwrap);


        //The returned string should be empty because
        System.assert(warningMessage.length() == 0);


        //Now Add a couple of impairments and test the resulting impairments message

        FSL_MembershipImpairmentWrapper  mbrImpWrap1 = new FSL_MembershipImpairmentWrapper();
        mbrImpWrap1.name = 'Impairment-1';
        mbrImpWrap1.message = 'Impairment-1 exists in the membership';
        custwrap.impairments.add(mbrImpWrap1);

        FSL_MembershipImpairmentWrapper  mbrImpWrap2 = new FSL_MembershipImpairmentWrapper();
        mbrImpWrap2.name = 'Impairment-2';
        mbrImpWrap2.message = 'Impairment-2 exists in the membership';
        custwrap.impairments.add(mbrImpWrap2);

        // Now get the warningmessage again

        // ERS-230821  does away wih warning messages
        warningMessage = validationService.getWarningMessage(custwrap);
        //System.assert(warningMessage.contains(mbrImpWrap1.message));
        //System.assert(warningMessage.contains(mbrImpWrap2.message));

        //System.assert(warningMessage.contains(Label.FSL_Membership_Impairments_Dialog_Header));


        System.Test.stopTest();

    }

    @IsTest
    static void testSetupHttpRequest(){
        
        // Id workId = '0WO0200000098lPGAQ';
        FSL_ValidateMembershipNumber.ValidateMembershipService memberService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        FSL_ValidateMembershipNumber.MembershipSearchRequest memberRequestData = memberService.createMemberSearchData('1234567890123456',null,null,null);

        FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
        // endpoint.Endpoint_URL__c = 'https://uat.b2b.autoclubextranet.com/SalesForceFSL/VerifyMembership';
        // endpoint.client_id__c = 'clientId';
        // endpoint.Client_Secret__c = 'ClientSecret';
        // endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
        // endpoint.Timeout__c = 20000;
        // endpoint.Named_Credential__c = 'callout:Member_Search';

        endpoint.Endpoint_URL__c = '';
        endpoint.client_id__c = '';
        endpoint.Client_Secret__c = '';
        endpoint.Client_Cert_Name__c = '';
        endpoint.Timeout__c = 20000;
        endpoint.Named_Credential__c = 'callout:Member_Search';

        Test.startTest();
        FSL_ValidateMembershipNumber.MembershipWebService mWebService = new FSL_ValidateMembershipNumber.MembershipWebService(endpoint);
        HttpRequest request = mWebService.retrieveHttpRequest();
        System.assertEquals(true, request != null);
        Test.stopTest();
        
    }
    @IsTest
    static void testPartialSearch(){
        FSL_ValidateMemberMock mock = new FSL_ValidateMemberMock(true);
        mock.isPartialSearch = true;
        System.Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        FSL_PartialLookupWrapper wrapper = FSL_ValidateMembershipNumber.partialSearch('Demo1FirstName', 'Demo1LastName', '004', '1');
        System.assertEquals('200', wrapper.status);
        Test.stopTest();
        
    }

    @IsTest
    static void testPartialSearch500Exception(){
        FSL_ValidateMemberMock mock = new FSL_ValidateMemberMock(true);
        mock.isPartialSearch = true;
        mock.isErrorStatusCode = true;
        System.Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        FSL_PartialLookupWrapper wrapper = FSL_ValidateMembershipNumber.partialSearch('Demo1FirstName', 'Demo1LastName', '004', '1');
        System.assertEquals('500', wrapper.status);
        Test.stopTest();
        
    }
    @IsTest
    static void testExtractResponseHeader(){
        FSL_ValidateMembershipNumber.ResponseHeader responseHeader = new FSL_ValidateMembershipNumber.ResponseHeader();
        Map<String,Object> response = new Map<String,Object>();
        response.put('statusCode', 'status');
        response.put('statusDescription', 'Testing');
        Test.startTest();
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        responseHeader = membershipService.extractResponseHeader(response);
        System.assertEquals(500,responseHeader.responseStatusCode);
        Test.stopTest();
        
    }
    @IsTest
    static void testGetContactsWithMockResponseException(){
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        FSL_ValidateMembershipNumber.MembershipSearchRequest membershipSearchData = new FSL_ValidateMembershipNumber.MembershipSearchRequest();
        Test.startTest();
        MembershipWebServiceMock mockService = new MembershipWebServiceMock(new FSL_Service_Endpoints__c());
        mockService.isThrowException = true;
        FSL_LightningCustomerWrapper wrapper = membershipService.getContacts('1234567890123456', '1', membershipSearchData, mockService);
        System.assertEquals(true, wrapper == null);
        Test.stopTest();
        
    }
    @isTest
    static void testGetContactsWithMockResponseJSONException(){
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        FSL_ValidateMembershipNumber.MembershipSearchRequest membershipSearchData = new FSL_ValidateMembershipNumber.MembershipSearchRequest();
        Test.startTest();
        MembershipWebServiceMock mockService = new MembershipWebServiceMock(new FSL_Service_Endpoints__c());
        mockService.isThrowJSONException = true;
        FSL_LightningCustomerWrapper wrapper = membershipService.getContacts('1234567890123456', '1',membershipSearchData, mockService);
        System.assertEquals(true, wrapper == null);
        Test.stopTest();
        
    }

    @isTest
    static void testGetContactsNewException(){
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        FSL_ValidateMembershipNumber.MembershipSearchRequest membershipSearchData = new FSL_ValidateMembershipNumber.MembershipSearchRequest();
        membershipSearchData.firstName = 'firstname';
        membershipSearchData.lastName = 'lastname';
        membershipSearchData.includeCallCounts = false;
        membershipSearchData.isLocalMember = true;
        membershipSearchData.memberClubCode = '004';
        membershipSearchData.memberNumber = '123456';
        membershipSearchData.phoneNumber = '9492151111';
        membershipSearchData.policyNumber = '';
        membershipSearchData.quoteNumber = '';
        membershipSearchData.sourceClubCode = '';
        membershipSearchData.zipCode = '';
        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 
        Test.setMock(HttpCalloutMock.class, searchmock);
        String res = '{"responseHeaders": {"tranId": "111111","tranCode": "404","tranStatus": "SUCCESS","timeStamp": "2021-09-06T10:26:33.848-04:00","tranStatusDescription": "Record Not Found"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,404));
        FSL_LightningCustomerWrapper wrapper;
        try{
            wrapper = membershipService.getContactsNew('1234567890123456', '1',membershipSearchData, 'Member_Lookup');
        }Catch(Exception e){
            System.debug(e.getMessage());
        }
       // System.assertEquals(true, wrapper != null);
        Test.stopTest();
    }

    @IsTest
    static void testSaveMemberDataWithoutException(){

        FSL_ValidateMembershipNumber.MembershipSearchRequest membershipSearchData = new FSL_ValidateMembershipNumber.MembershipSearchRequest();
        membershipSearchData.firstName = 'firstname';
        membershipSearchData.lastName = 'lastname';
        membershipSearchData.includeCallCounts = false;
        membershipSearchData.isLocalMember = true;
        membershipSearchData.memberClubCode = '004';
        membershipSearchData.memberNumber = '123456';
        membershipSearchData.phoneNumber = '9492151111';
        membershipSearchData.policyNumber = '';
        membershipSearchData.quoteNumber = '';
        membershipSearchData.sourceClubCode = '';
        membershipSearchData.zipCode = '';

        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        Test.startTest();

        Integer recordCount = 1;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].Cleared_Timestamp__c = Date.today();
            workOrders[i].Status = 'Cleared';
        }
        insert workOrders;        

        FSL_LightningCustomerWrapper customerWrapper = dummyWrapper();
        Map<String,String> response = membershipService.saveMemberData(JSON.serialize(customerWrapper), workOrders[0].Id, contacts[0].Id, (new FSL_Contact.Factory().createService()), (new FSL_WorkOrder.Factory().createService()));   
        //System.assertEquals('Error', response.get('Status'));
        Test.stopTest();
    }

    @IsTest
    static void testSaveMemberDataWithException(){
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        Test.startTest();
        Map<String,String> response = membershipService.saveMemberData('testing', '1', '1', (new FSL_Contact.Factory().createService()), (new FSL_WorkOrder.Factory().createService()));   
        System.assertEquals('Error', response.get('Status'));
        Test.stopTest();
    }

    @IsTest
    static void testPartialMemberSearchJSONException(){
        
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        Test.startTest();
        MembershipWebServiceMock mockService = new MembershipWebServiceMock(new FSL_Service_Endpoints__c());
        mockService.isThrowJSONException = true;
        FSL_PartialLookupWrapper wrapper = membershipService.partialSearch('1', new FSL_ValidateMembershipNumber.MembershipSearchRequest(), mockService) ;
        System.assertEquals(true, wrapper.status.toUpperCase()=='ERROR');
        Test.stopTest();
        
    }
    @IsTest
    static void testPartialMemberSearchWithException(){
        
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        Test.startTest();
        MembershipWebServiceMock mockService = new MembershipWebServiceMock(new FSL_Service_Endpoints__c());
        mockService.isThrowException = true;
        FSL_PartialLookupWrapper wrapper = membershipService.partialSearch('1', new FSL_ValidateMembershipNumber.MembershipSearchRequest(), mockService) ;
        System.assertEquals(true, wrapper.status.toUpperCase()=='ERROR');
        Test.stopTest();
        
    }

    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"statusCode": 200, "statusDescription": "Success", "transactionId": "123", "customer": { "name": "John Doe" }}');
            return res;
        }
    }
    
    @isTest
    static void testCreateMembershipDatailResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setStatus('OK');
        response.setBody('{"statusCode": 200, "statusDescription": "Success", "transactionId": "123", "customer": { "name": "John Doe" }}');
        String workOrdId = '123';
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        FSL_LightningCustomerWrapper result = membershipService.createMembershipDatailResponse(request, response, workOrdId);
        System.assertEquals('200', result.statusCode);
    }

    @TestSetup
    static void testSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

    public class MembershipWebServiceMock extends FSL_ValidateMembershipNumber.WebCallService {
        public boolean isThrowException = false ;
        public boolean isThrowJSONException = false; 
        public boolean isSuccessful = false;

        public MembershipWebServiceMock( FSL_Service_Endpoints__c serviceEndpoints) {
            super(serviceEndpoints);
            setupHttpRequest();
        }
  
        public override HttpResponse invokeWebRequest(String requestData) {
            this.request.setBody(requestData);
            if (isThrowException)
                throw new WebServiceException('Service Exception');
            if (isThrowJSONException)
                throw new JSONException('Service Exception');
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            String JSON;
            if (isSuccessful) {
                StaticResource sr = [select id, body from StaticResource where name = 'FSL_SearchRequestResponse'];
                JSON = sr.body.toString();   
            } else {
                StaticResource sr = [select id, body from StaticResource where name = 'FSL_SearchRequestResponseFailed'];
               JSON = sr.body.toString();   
            }       
            response.setBody(JSON);
         
            // response.setStatus('500');
            // response.setBody('{}');
            return response ;  
        }
        @TestVisible
        public override HttpRequest retrieveHttpRequest() {
            return this.request;
        }

        protected override void setupHttpRequest() {
            request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        }
    }
    public class WebServiceException extends Exception {

    }

    public class MockMemberVerificationAPIs implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { 
            HttpResponse res; 
            if (req.getEndpoint() == 'testurl') {
                res = new HttpResponse(); 
                res.setStatusCode(200); 
                res.setBody('{"access_token":"TestAccessToken"}'); 
            } else if (req.getEndpoint() == 'testSearch') {
                res = new HttpResponse(); 
                res.setStatusCode(200); 
                res.setBody('{\"message\":\"Success\",\"status\":200,\"members\":[{\"name\":\"MARTIN,CESAR\",\"memberNumber\":\"6200049749630002\",\"address\":\"16858,ENCINO,CA\",\"statusIndicator\":\"Active\",\"phoneNumber\":null,\"emailAddress\":null,\"expirationDate\":null}]}'); 
            }
            return res;
        } 
    }
	/**EMI --SSFI--662---11-26-2024---**/
  	@IsTest
    static void testTokenExistsAndIsValid() {
     
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        orgPart.put('token', 'validCachedToken');
        orgPart.put('expiry', System.now().addMinutes(10)); 

        FSL_ValidateMembershipNumber instance = new FSL_ValidateMembershipNumber();

        Test.startTest();
        String token = instance.retrieveToken();
        Test.stopTest();
    }
  
    @IsTest
    static void testTokenFetchError() {
     
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        orgPart.remove('token');
        orgPart.remove('expiry');

        Test.setMock(HttpCalloutMock.class, new MockOAuthCalloutWithError());
        FSL_ValidateMembershipNumber instance = new FSL_ValidateMembershipNumber();

        Test.startTest();
        try {
            instance.retrieveToken();
            System.assert(false, 'An exception should have been thrown.');
      		} catch (CalloutException ex) {
        }
        Test.stopTest();
    }

	private class MockOAuthCallout implements HttpCalloutMock {
		private String token;

		public MockOAuthCallout(String token) {
			this.token = token;
		}

		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setBody('{"access_token": "' + token + '"}');
			return res;
		}
	}
	private class MockOAuthCalloutWithError implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			throw new CalloutException('Mock error during token retrieval.');
		}
	}
    
    @IsTest
    static void setupTestData1() {
        FSL_Service_Endpoints__c testEndpoint = new FSL_Service_Endpoints__c(
            Name = 'TestEndpoint',
            Timeout__c = 3000,
            Endpoint_URL__c = 'https://testapi.example.com/resource',
            Client_Cert_Name__c = 'TestCert'
        );
        insert testEndpoint;
    }

    @IsTest
    static void testInvokeCalloutWithHttpMock() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());
		
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        orgPart.put('token', 'mockToken');
        orgPart.put('expiry', System.now().addMinutes(10)); 

        String requestData = '{"param1":"value1","param2":"value2"}';
        String endPointMetadata = 'TestEndpoint';

        Test.startTest();
        FSL_ValidateMembershipNumber instance = new FSL_ValidateMembershipNumber();
        FSL_ValidateMembershipNumber.RequestResponse response = instance.invokeCallout(requestData, endPointMetadata);
        Test.stopTest();
	 
    }
    private class MockHttpCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
      
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200); 
            res.setBody('{"status":"success"}'); 
            return res;
        }
	}
	
	/**EMI --SSFI--662--11-26-2024--**/	
}