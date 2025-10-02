/**** Apex Class Name    :    ServiceMock_REST_TEST
    * Description        :    This  is General Mock class for Rest API  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Dhruv               Aug 12 2021             Created
*********************************************************************************/
@isTest
global without sharing class RestServiceMock_TEST implements HttpCalloutMock{
	
	public object responseBody;
	public Integer StatusCode;
    public String StatusDescription;
    
    //Default constructor
    public RestServiceMock_TEST(){
        StatusCode=200;
        StatusDescription='Success';
    }
    //Default constructor
    public RestServiceMock_TEST(String responseBody){
        StatusCode=200;
        StatusDescription='Success';
        this.responseBody=responseBody;
    }
    
    public RestServiceMock_TEST(String responseBody,Integer StatusCode,String StatusDescription){	
        this.StatusCode=StatusCode;
        this.StatusDescription=StatusDescription;
        this.responseBody=responseBody;
    }
    
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json'); 
        response.setBody(responseBody instanceof string ? (string) responseBody : JSON.serializePretty(responseBody));
        response.setStatusCode(StatusCode);
        response.setStatus(StatusDescription);
        
        return response; 
    }
    
}