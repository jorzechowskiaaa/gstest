/**** Apex Test Class Name:    INTMembershipSearchAPI_Test
    * Description        :     This is the test class used to test INTMembershipSearchAPI class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla               Aug 16 2021             Created
*********************************************************************************/

@isTest(SeeAllData = false)
public class INTMembershipSearchAPI_Test {

    @isTest(SeeAllData = false) 
    static void getRecordNotFound() {
        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 
        Test.setMock(HttpCalloutMock.class, searchmock);
        String res = '{"responseHeaders": {"tranId": "111111","tranCode": "404","tranStatus": "SUCCESS","timeStamp": "2021-09-06T10:26:33.848-04:00","tranStatusDescription": "Record Not Found"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,404)); 
        Map<string,string> a = new Map<string,string>();
        a.put('MSsearchByNameZip_fName','CHLOE');
        a.put('MSsearchByNameZip_lName','JONES');
        a.put('MSsearchByNameZip_zip','01004'); 
        a.put('MSsearchByNameZip_clubCode','994');
        try{
            MembershipSearchRespJSONWrapper response = INTMembershipSearchAPI.getMembersearch(a);
        }Catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        
        Test.stopTest();
        //System.assertEquals('404', response.responseHeaders.tranCode);
    }

    @isTest
    static void testImpairmentMessage() {
     
        List<FSL_MembershipImpairmentWrapper> custwrap = new List<FSL_MembershipImpairmentWrapper>();
        FSL_MembershipImpairmentWrapper  mbrImpWrap1 = new FSL_MembershipImpairmentWrapper();
        mbrImpWrap1.name = 'Impairment-1';
        mbrImpWrap1.message = 'Impairment-1 exists in the membership';
        custwrap.add(mbrImpWrap1);

        INTMembershipSearchAPI.getImpairmentMessages(custwrap);

    }
    
    @isTest
    static void testTryResponseFormat1() {
        Test.startTest();
        
        String resString = '{\"statusCode\":200,\"statusDescription\":\"Success\",\"customer\":{\"contact\":{\"firstName\":\"RESNY\",\"lastName\":\"DETTWEILER\",\"phones\":[]},\"memberships\":[{\"membershipType\":\"\",\"memberBirthday\":\"\",\"expirationDate\":\"\",\"memberStatus\":\"\"}]}}';
        HttpResponse res = new HTTPResponse();
        res.setBody(resString);
        
        MembershipSearchRespJSONWrapper response = INTMembershipSearchAPI.tryResponseFormat1(res);
        Test.stopTest();
    }
    
    @isTest
    static void testTryResponseFormat2() {
        Test.startTest();
        String resString = '{\"message\":\"Success\",\"status\":200,\"members\":[{\"name\":\"MARTIN,CESAR\",\"memberNumber\":\"6200049749630002\",\"address\":\"16858,ENCINO,CA\",\"statusIndicator\":\"Active\",\"phoneNumber\":null,\"emailAddress\":null,\"expirationDate\":null}]}'; 
        HttpResponse res = new HTTPResponse();
        res.setBody(resString);
        
        MembershipSearchRespJSONWrapper response = INTMembershipSearchAPI.tryResponseFormat2(res);
        Test.stopTest();
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
}