@isTest
global class FSL_WOJeopardy_MockResponseGenerator implements HttpCalloutMock {
    boolean isSuccess;
    global FSL_WOJeopardy_MockResponseGenerator(boolean isSuccess){
        this.isSuccess = isSuccess;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(this.isSuccess){
            system.debug('SUCCESS RESPONSE');
            response.setBody('SUCCESS');
            response.setStatusCode(200);
        }else{
            system.debug('ERROR RESPONSE');
           // response.setBody('"[{"errorCode":"FORBIDDEN","message":"You do not have access to the Apex class named: FSL_UpdateWorkOrder"}]');
            response.setBody('{"errorCode":"FORBIDDEN","message":"You do not have access to the Apex class named: FSL_UpdateWorkOrder"}');
            response.setStatusCode(403);            
        }
        return response;
    }
}