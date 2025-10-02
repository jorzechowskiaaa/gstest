/**** Apex Test Class Name:    HttpRestCalloutMock
    * Description        :     This is the mock callout class used for INTMembershipSearchAPI test class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla               Aug 16 2021             Created
*********************************************************************************/

@isTest(SeeAllData = false)
global class HttpRestCalloutMock implements HttpCalloutMock{
    
	String mockResponse;
    Integer statusCode;
    
    /*
    * Method name    : ACG_HttpRestCalloutMock
    * Description    : Constructor class to set the mock response data and status code dynamically for a test class
    * Return Type    : void
    * Parameter      : none
    */
    
	public HttpRestCalloutMock(String response, Integer statcode){
        mockResponse = response;
        statusCode = statcode;
    }
    
     /*
     * Method name    : respond
     * Description    : Used to return the mock response data for a test class
     * Return Type    : response
     * Parameter      : none
     */
    
	 global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(mockResponse);
        response.setStatusCode(statusCode);
        return response; 
    }
}