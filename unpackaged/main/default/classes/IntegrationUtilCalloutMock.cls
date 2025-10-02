@isTest
public class IntegrationUtilCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('GET', req.getMethod());
    
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Request Received":"true"}');
        res.setStatusCode(200);
        return res;
    }
}