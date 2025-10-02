/**** Apex Class Name    :    INTMembershipLookupAPI_Test
    * Description        :    Test class for INTMembershipLookupAPI class  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Dhruv               		Aug 16 2021             Created
*********************************************************************************/
@isTest
public class INTMembershipLookupAPI_Test {
    @testSetup static void setup() {
        /*
        Integration_Settings__c IntegrationSetting = ACG_TestDataFactory.createIntegrationSetting('Membership_Lookup_API', 'GET', 'callout:Membership_Lookup', '/enterprise/2.0.0/customer/lookup', 'https://acg-enterprise-customer-lookup-api-qa.us-e2.cloudhub.io/enterprise/2.0.0/customer/lookup', true);
        System.assert(IntegrationSetting.Id!=null,'Error While Creating Record');
*/
    }
    
    @isTest 
    static void getMemberDetailWithMemberNumber() {
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"CHLOE","lastName":"JONES","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":null,"phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":null}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4299941234758818","sourceSystemIdentifier":null,"productType":null,"productStatus":"ACTIVE","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]},"access_token":"TestAccessToken"}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 
        INTMembershipLookupResponse_Wrapper responseWrapper= INTMembershipLookupAPI.getMemberlookup('4299941234758818');
        System.assertEquals( 200,responseWrapper.STATUS_CODE,'Success');
        Test.stopTest();
    }
    
    @isTest 
    static void getInvalidMemberNumber() {
        Test.startTest();
        String res = '{ "responseHeaders": { "tranId": null, "tranCode": "400", "tranStatus": "E", "timeStamp": "2021-09-08T05:05:07.893-04:00", "tranStatusDescription": "The number you entered is not a valid AAA member number. Please try again. If the issue persists, please call the 800# on the back of your membership card for further assistance" } }';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,400,'Membership number is not valid')); 
        INTMembershipLookupResponse_Wrapper responseWrapper= INTMembershipLookupAPI.getMemberlookup('429994123475881');
        System.assertEquals(400,responseWrapper.STATUS_CODE,'URL not found');
        System.assertEquals('Membership number is not valid',responseWrapper.ERR_MESSAGE);
        Test.stopTest();
    }
    
    @isTest 
    static void getInternalServerError() {
        Test.startTest();
        String res = '{ "responseHeaders": { "tranId": "965b6a88-50d3-2730-d5a6-aa1e7fcba603", "tranCode": "500", "tranStatus": "Error", "timeStamp": "2019-11-18T08:23:48 -0500", "tranStatusDescription": "Internal Server Error" } }';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 
        INTMembershipLookupResponse_Wrapper responseWrapper= INTMembershipLookupAPI.getMemberlookup('123');
        System.assertEquals( 500,responseWrapper.STATUS_CODE);
        System.assertEquals( 'Internal Server Error',responseWrapper.ERR_MESSAGE,'Internal Server Error Occured');
        Test.stopTest();
    }
    
    @isTest 
    static void getExceptionLog() {
        Test.startTest();
        String res = '';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 
        INTMembershipLookupResponse_Wrapper responseWrapper= INTMembershipLookupAPI.getMemberlookup('123');
        System.assertEquals(500,responseWrapper.STATUS_CODE,'Internal Server Error Occured');
        Test.stopTest();
    }
    @isTest 
    static void getExceptionHandingLog() {
        Test.startTest();
        String res = '[{}]';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 
        INTMembershipLookupResponse_Wrapper responseWrapper= INTMembershipLookupAPI.getMemberlookup('123');
        System.assertEquals(500,responseWrapper.STATUS_CODE,'Invalid Response Return');
        Test.stopTest();
    }
	
}