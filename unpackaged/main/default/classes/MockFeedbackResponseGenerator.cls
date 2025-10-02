@isTest
global class MockFeedbackResponseGenerator implements HttpCalloutMock{
    Boolean isSuccess;
    global MockFeedbackResponseGenerator(Boolean isSuccess) {
        this.isSuccess = isSuccess;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(this.isSuccess){
            response.setBody('{"return_cd":"0"}');
            response.setStatusCode(200);
        }else{
            response.setBody('{"errorCode":"404","errorMessage":"Not Found","transactionId":"2674674648"}');
            response.setStatusCode(404);
        }
        return response;
    }
}