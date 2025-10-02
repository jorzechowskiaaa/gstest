/**** Apex Test Class Name:    INTEntitlementGETAPITest
    * Description        :     This is the test class used to test INTEntitlementGETAPI class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla               Sep 14 2021             Created
*********************************************************************************/

@isTest(SeeAllData = false)
public class INTEntitlementGETAPI_Test {

   @isTest
   static void testGetEntitlementsWithContracts() {
       // Create a mock request
      RestRequest request = new RestRequest();
      request.requestUri = '/services/apexrest/Entitlements/6022404455667788';
      request.httpMethod = 'GET';
      RestContext.request = request;

      // Set up test data
      Account objAcc = new Account();
      objAcc.Name	 = 'Test Account' ;
      objAcc.ACG_Primary_Phone_Type__c = 'Home';
      insert objAcc;
      ServiceContract testContract = new ServiceContract(
         Name = 'Test',
         AAA_ACA_Membership16ID__c = '6022404455667788',
         AAA_ACA_Membership_Type__c = 'Member',
         AAA_ACA_Membership_Status__c = 'Active',
         StartDate = Date.today().addDays(-10),
         EndDate = Date.today().addDays(1),
         AAA_Total_of_Calls_Allowed__c = 4,
         AAA_Total_of_Calls_Consumed__c = 2,
         AccountId = objAcc.Id
      );
      insert testContract;

      Test.startTest();
         String successResponse = '{\"STATUS_CODE\":200,\"customers\":{\"customer\":[{\"membershipType\":\"Member\",\"membershipStatus\":\"Active\",\"membershipId\":\"6022404455667788\",\"lastName\":\"BIASETTI\",\"isLocalClub\":true,\"impairmentType\":null,\"firstName\":\"FRANCES\"}]}}';
         INTEntitlementGETAPI.mockResponse(successResponse);

         INTEntitlementGETAPIResWrapper response = INTEntitlementGETAPI.getEntitlements();
         INTEntitlementGETAPIResWrapper.Entitlements entitlement = response.entitlements[0];
         System.assertEquals(4, Integer.valueOf(entitlement.entitlementsAllotted));
         System.assertEquals(2, Integer.valueOf(entitlement.entitlementsUsed));
         System.assertEquals(2, Integer.valueOf(entitlement.entitlementsRemaining));
         //System.assertEquals('6022404455667788', entitlement.membershipId);
         System.assertEquals('Member', entitlement.membershipType);
         System.assertEquals('Active', entitlement.membershipStatus);
      Test.stopTest(); 
   }

   @isTest
   static void testGetEntitlementsWithNoContracts() {
       // Create a mock request
      RestRequest request = new RestRequest();
      request.requestUri = '/services/apexrest/Entitlements/6022404455667700';
      request.httpMethod = 'GET';
      RestContext.request = request;

      Test.startTest();
         String errorResponse = '{\"STATUS_CODE\":400,\"customers\":{\"customer\":[{\"membershipType\":\"AssociateMember\",\"membershipStatus\":\"Active\",\"membershipId\":\"6202404416500202\",\"lastName\":\"BIASETTI\",\"isLocalClub\":true,\"impairmentType\":null,\"firstName\":\"FRANCES\"}]}}';
         INTEntitlementGETAPI.mockResponse(errorResponse);

         INTEntitlementGETAPIResWrapper response = INTEntitlementGETAPI.getEntitlements();
         System.assertEquals(200, Integer.valueOf(response.statusCode), 'Response should be success and Entitlements are null');
      Test.stopTest(); 
   }

   @isTest
   static void testGetEntitlementsWithEntitlements() {
      // Create a mock request
      RestRequest request = new RestRequest();
      request.requestUri = '/services/apexrest/Entitlements/6022404455667788';
      request.httpMethod = 'GET';
      RestContext.request = request;

      String successResponse = '{\"STATUS_CODE\":200,\"customers\":{\"customer\":[{\"membershipType\":\"AssociateMember\",\"membershipStatus\":\"Pending\",\"membershipId\":\"6202404416500202\",\"lastName\":\"BIASETTI\",\"isLocalClub\":true,\"impairmentType\":null,\"firstName\":\"FRANCES\",\"entitlement\":{\"callsAllowed\":4,\"callsRemaining\":2,\"callsUsed\":2}}]}}';
      INTEntitlementGETAPI.mockResponse(successResponse);
      INTEntitlementGETAPIResWrapper response = INTEntitlementGETAPI.getEntitlements();
      INTEntitlementGETAPIResWrapper.Entitlements entitlement = response.entitlements[0];
      System.assertEquals('Pending', entitlement.membershipStatus, 'membershipStatus should be Pending');
   }

   public class MockMemberVerificationAPIs implements HttpCalloutMock {
      public HttpResponse respond(HttpRequest req) { 
          HttpResponse res; 
              res = new HttpResponse(); 
              res.setStatusCode(200); 
              res.setBody( '{\"statusCode\":200,\"statusDescription\":\"Success\",\"customer\":{\"contact\":{\"firstName\":\"RESNY\",\"lastName\":\"DETTWEILER\",\"phones\":[]},\"memberships\":[{\"membershipType\":\"\",\"memberBirthday\":\"\",\"expirationDate\":\"\",\"memberStatus\":\"Active\"}],\"entitlement\":{\"callsAllowed\":4,\"callsRemaining\":2,\"callsUsed\":2}}}');
          return res;
      } 
  }
   /*
     //@isTest 
     static void getDetailsByValidId() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account WHERE Name='Acme Test' LIMIT 1];
        String recordId = acct.ACG_AAA_Membership__c;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Entitlements/'+ recordId;
        request.httpMethod = 'GET';
        RestContext.request = request;
        Test.startTest();
        string response='{\"responseHeaders\":{\"tranId\":\"52d31885-90ac-dc17-e404-ccb543f3853b\",\"tranCode\":\"200\",\"tranStatus\":\"Success\",\"timeStamp\":\"2022-03-16T12:59:07.193-04:00\",\"tranStatusDescription\":\"Retrievedthememberdetailssuccessfully\"},\"MembershipSearchResponse\":{\"members\":[{\"membershipNumber\":\"7684567890123456\",\"lastName\":\"MARKETING\",\"firstName\":\"JULMID\",\"adressLine1\":\"6795AW19thPl\",\"addressLine2\":null,\"city\":\"DENVER\",\"state\":\"COL\",\"zip5\":\"80111\",\"membershipStatus\":\"ACTIVE\",\"birthDate\":\"1950-01-02\",\"expirationDate\":\"2022-01-01\",\"membershipType\":null,\"phoneNumber\":\"2222233334\"}]}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock (response, 200)); 
        INTEntitlementGETAPIResWrapper entitlements = INTEntitlementGETAPI.getEntitlements();
         system.assertEquals('200',entitlements.statusCode);
        Test.stopTest();
     }
            
    
   /*
   * Method name    : getDetailsByInvalidId
   * Description    : Used to test a class with the invalid membership id
   * Return Type    : void
   * Parameter      : none
   
    
     @isTest static void getDetailsByInvalidId() {
        String recordId = '989348';
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/Entitlements/'+ recordId;
        request.httpMethod = 'GET';
        RestContext.request = request;
        Test.startTest();
        INTEntitlementGETAPIResWrapper entitlements = INTEntitlementGETAPI.getEntitlements();
        system.assertEquals('400',entitlements.statusCode);
        Test.stopTest();

     } */
}