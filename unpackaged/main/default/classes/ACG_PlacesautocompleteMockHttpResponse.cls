/**** Apex Class Name    :    ACG_PlacesautocompleteMockHttpResponse
    * Description        :    This  is Http mock class for  for Places Autocomplete API   
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Aug 6 2020             Created
*********************************************************************************/
@isTest
global class ACG_PlacesautocompleteMockHttpResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('GET', req.getMethod());
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"predictions": [{"description": "Texas City, TX, USA","matched_substrings":' 
                    +'[{"length": 5,"offset": 0}],"place_id": "ChIJF7HtoBJ5P4YR4bTurbycLYY","reference": "ChIJF7HtoBJ5P4YR4bTurbycLYY",'
                    +'"structured_formatting": {"main_text": "Texas City","main_text_matched_substrings": [{"length": 5,"offset": 0}],'
                    +'"secondary_text": "TX, USA"},"terms": [{"offset": 0,"value": "Texas City"}],'
                    +'"types": ["locality","political","geocode"]}],"status": "OK"}');
        res.setStatusCode(200);
        return res;
    }
}