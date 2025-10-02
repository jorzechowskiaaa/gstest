@isTest 
public class Util_ManageAccessTokensTest {
   /**EMI ---Start----SSFI--662---11/25/2024--**/
        @isTest
        static void testCallOAuth() {
            // Set mock response for HTTP callout
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // Test data 
            insert new FSL_Service_Endpoints__c(
                Name = 'Mulesoft_OAuth',
                Timeout__c = 3000,
                Endpoint_URL__c = 'https://example.com/oauth',
                client_id__c = 'test_client_id',
                client_secret__c = 'test_client_secret',
                Scope__c = 'test_scope'
            );
            Util_ManageAccessTokens util = new Util_ManageAccessTokens();
            Map<String, String> result = util.callOAuth('Mulesoft_OAuth');
          }
       private class MockHttpResponseGenerator implements HttpCalloutMock {
            public HttpResponse respond(HttpRequest request) {
                HttpResponse response = new HttpResponse();
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"access_token":"mock_access_token","expires_in":"3600"}');
                response.setStatusCode(200);
                return response;
            }
      }
     /**EMI ----End----SSFI--662------11/25/2024--**/  
    @isTest 
    static void testSendAndGetAccessToken() { 
        Manage_Access_Tokens__c customSetting = new Manage_Access_Tokens__c(Name = 'TestSetting', Token__c = 'TestToken'); 
        insert customSetting; 
        new Util_ManageAccessTokens().sendAccessTokenToMetadata('TestSetting', 'NewTestToken'); 
        String retrievedToken = new Util_ManageAccessTokens().getAccessTokenFromMetadata('TestSetting'); 
        // Assert that the token was updated and retrieved correctly 
        System.assertEquals('NewTestToken', retrievedToken,'Token should be same as retrived');
    } 

    public class MockAccessTokenGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { 
           HttpResponse res = new HttpResponse(); 
           res.setStatusCode(200); 
           res.setBody('{"access_token":"TestAccessToken"}'); 
           return res; 
        } 
    }

    public class MockSearchAPIResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { 
           HttpResponse res = new HttpResponse(); 
           res.setStatusCode(200); 
           res.setBody('{\"message\":\"Success\",\"status\":200,\"members\":[{\"name\":\"MARTIN,CESAR\",\"memberNumber\":\"6200049749630002\",\"address\":\"16858,ENCINO,CA\",\"statusIndicator\":\"Active\",\"phoneNumber\":null,\"emailAddress\":null,\"expirationDate\":null}]}'); 
           return res; 
        } 
    } 
}