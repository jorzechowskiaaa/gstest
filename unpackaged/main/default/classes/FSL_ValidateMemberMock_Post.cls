/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-16-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-16-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
global class FSL_ValidateMemberMock_Post implements HttpCalloutMock {
    boolean isSuccess;
    public boolean isPartialSearch = false; 
    public boolean isErrorStatusCode = false;
    global FSL_ValidateMemberMock_Post(boolean isSuccess){
        this.isSuccess = isSuccess;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('POST', req.getMethod());
        
        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(this.isPartialSearch) {
            String JSON ;
            if(isErrorStatusCode) {
                StaticResource  sr = [select id, body from StaticResource where name = 'FSL_SearchRequestResponseFailed'];
                JSON = sr.body.toString();
                response.setStatusCode(500);
            }else {
                StaticResource sr = [select id, body from StaticResource where name = 'FSL_SearchRequestResponse'];
                JSON = sr.body.toString();
                response.setStatusCode(200);
            }
            response.setBody(JSON);

        }else {

            if(this.isSuccess){
                StaticResource sr = [select id, body from StaticResource where name = 'FSL_ValidateMember_S'];
                string JSON = sr.body.toString();            
                system.debug('SUCCESS RESPONSE');
                response.setBody(JSON);
                response.setStatusCode(200);
            }else{
                StaticResource sr = [select id, body from StaticResource where name = 'FSL_ValidateMember_E'];
                string JSON = sr.body.toString();            
                system.debug('ERROR RESPONSE');
                response.setBody(JSON);
                response.setStatusCode(400);            
            }
        }
        
        return response;
    }
}