@isTest
global class INTMapSearchAddressWithAPI_Test{
      @testSetup static void setup() {
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'BING_API_GEOCODE',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=', API_Key__c ='AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc',
            Request_Timeout__c=120000
            
        )); 
               
        insert lstIntegrationSetting;
        
        List<ARR_Call_Receive_LWC_UI_Configuration__c> lstARRLWCetting = new List<ARR_Call_Receive_LWC_UI_Configuration__c>();
        lstARRLWCetting.add(new ARR_Call_Receive_LWC_UI_Configuration__c(
            Map_Search_Display_limit__c = 2, ACE_POI_Search_Radius_mile__c =7     
        ));
        insert lstARRLWCetting;
     }
    
    global class AddressHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{
                if(req.getEndpoint()!='https://maps.googleapis.com/maps/api/geocode/json?'){
                    system.debug('if');
                    HttpResponse res= new HttpResponse();
                    //res.getMethod('GET');
                    //res.setBody('{"results":[{"formatted_address":"Disney, OK 74340, USA","geometry":{"location":{"lat":36.4809948,"lng":-95.0153292},"viewport":{"northeast":{"lat":36.489782,"lng":-95.0060258},"southwest":{"lat":36.46065189999999,"lng":-95.028205}}},"name":"Disney","place_id":"ChIJ7QGcYOLUyYcRzt5PlhNjizg","types":["locality","political"]}],"status":"OK"}');
                    res.setBody('{"results":[{"formatted_address":"Disney, OK 74340, USA","location":{"lat":36.4809948,"lng":-95.0153292},"name":"Disney","place_id":"ChIJ7QGcYOLUyYcRzt5PlhNjizg","types":["locality","political"]},{"formatted_address":"8687 N Central Expy, Dallas, TX 75225, United States","location":{"lat":32.86873570000001,"lng":-96.7718582},"name":"Disney Store","place_id":"ChIJbyg4-76fToYRIzjT05n-d1Y","types":["clothing_store","point_of_interest","store","establishment"]}],"status":"OK"}');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;                    
                }else{
                    HttpResponse res= new HttpResponse();
                    res.setBody('INTDistanceMatrixAPIResponseWrapper:[destination_addresses=(28 HI-11, Hilo, HI 96720, USA), origin_addresses=(28 HI-11, Hilo, HI 96720, USA), rows=(Rows:[elements=(Elements:[distance=Distance:[text=1 ft, value=0], duration=Distance:[text=1 min, value=0], status=OK])]), status=OK]');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
               }
               }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
               }
                return null;
             }
      }
    
    global class DistanceHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{           
                    HttpResponse res= new HttpResponse();
                    res.setBody('INTDistanceMatrixAPIResponseWrapper:[destination_addresses=(28 HI-11, Hilo, HI 96720, USA), origin_addresses=(28 HI-11, Hilo, HI 96720, USA), rows=(Rows:[elements=(Elements:[distance=Distance:[text=1 ft, value=0], duration=Distance:[text=1 min, value=0], status=OK])]), status=OK]');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
               }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
               }
                return null;
             }
      }

      global class POIGeoCodeResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{           
                    HttpResponse res= new HttpResponse();
                    res.setBody('{\"results\":[{\"location\":{\"lat\":42.125604,\"lng\":-72.569085},\"formatted_address\":\"I291(MA)&4,Springfield,MA01104\",\"source\":\"google\",\"address\":{\"number\":null,\"streetNumber\":null,\"street\":\"I291(MA)&4,Springfield,MA01104\",\"suburb\":\"\",\"city\":\"Springfield\",\"state\":\"MA\",\"zip\":\"01104\",\"county\":\"HampdenCounty\",\"country\":\"\"},\"place_id\":\"R1694954,N70020773\",\"types\":[\"exit\"]}],\"status\":\"OK\"}');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
               }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
               }
                return null;
             }
      }
      
    global class ExceptionHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{           
                    HttpResponse res= new HttpResponse();
                    //res.setBody('INTDistanceMatrixAPIResponseWrapper:[destination_addresses=(28 HI-11, Hilo, HI 96720, USA), origin_addresses=(28 HI-11, Hilo, HI 96720, USA), rows=(Rows:[elements=(Elements:[distance=Distance:[text=1 ft, value=0], duration=Distance:[text=1 min, value=0], status=OK])]), status=OK]');
                    res.setBody('[{"results":[{"formatted_address":"Disney, OK 74340, USA","geometry":{"location":{"lat":36.4809948,"lng":-95.0153292}},"name":"Disney","place_id":"ChIJ7QGcYOLUyYcRzt5PlhNjizg","types":["locality","political"]},{"formatted_address":"8687 N Central Expy, Dallas, TX 75225, United States","geometry":{"location":{"lat":32.86873570000001,"lng":-96.7718582}},"name":"Disney Store","place_id":"ChIJbyg4-76fToYRIzjT05n-d1Y","types":["clothing_store","point_of_interest","store","establishment"]}],"status":"OK"}]');
          
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
               }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
               }
                return null;
             }
      }
      
    global class GeoCodeHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{
                if(req.getEndpoint()=='https://maps.googleapis.com/maps/api/geocode/json?'){
                    system.debug('if');
                    HttpResponse res= new HttpResponse();
                    //res.getMethod('GET');
                    res.setBody('[{"title":"1313 Disneyland Dr, Anaheim, CA 92802, USA","description":"1313 Disneyland Dr, Anaheim, CA 92802, USA","location":{"Latitude":"33.81539590000001","Longitude":-117.9263991}}]');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
                    
                }else{
                    HttpResponse res= new HttpResponse();
                    
                    res.setBody('{'+
                       '"plus_code" : {'+
                          '"compound_code" : "R37F+2CP Anaheim, CA, USA",'+
                          '"global_code" : "8554R37F+2CP"'+
                       '},'+
                        '"results" : ['+        
                       '{'+
                         '"address_components" : ['+
                            '{'+
                               '"long_name" : "1131",'+
                               '"short_name" : "1131",'+
                               '"types" : [ "street_number" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Magic Way",'+
                               '"short_name" : "Magic Way",'+
                               '"types" : [ "route" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Anaheim Resort",'+
                               '"short_name" : "Anaheim Resort",'+
                               '"types" : [ "neighborhood", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Anaheim",'+
                               '"short_name" : "Anaheim",'+
                               '"types" : [ "locality", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Orange County",'+
                               '"short_name" : "Orange County",'+
                               '"types" : [ "administrative_area_level_2", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "California",'+
                               '"short_name" : "CA",'+
                               '"types" : [ "administrative_area_level_1", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "United States",'+
                               '"short_name" : "US",'+
                               '"types" : [ "country", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "92802",'+
                               '"short_name" : "92802",'+
                               '"types" : [ "postal_code" ]'+
                            '}'+
                         '],'+
                         '"formatted_address" : "1131 Magic Way, Anaheim, CA 92802, USA",'+
                         '"geometry" : {'+
                            '"location" : {'+
                               '"lat" : 33.81277130000001,'+
                               '"lng" : -117.9265127'+
                            '},'+
                            '"location_type" : "ROOFTOP",'+
                            '"viewport" : {'+
                               '"northeast" : {'+
                                  '"lat" : 33.81412028029151,'+
                                  '"lng" : -117.9251637197085'+
                               '},'+
                               '"southwest" : {'+
                                  '"lat" : 33.81142231970851,'+
                                  '"lng" : -117.9278616802915'+
                               '}'+
                            '}'+
                         '},'+
                         '"place_id" : "ChIJ8zNSICoo3YARd0DgDhg2rMU",'+
                         '"plus_code" : {'+
                            '"compound_code" : "R37F+49 Anaheim, CA, USA",'+
                            '"global_code" : "8554R37F+49"'+
                         '},'+
                         '"types" : [ "street_address" ]'+
                      '},'+
                      '{'+
                         '"address_components" : ['+
                            '{'+
                               '"long_name" : "1150",'+
                               '"short_name" : "1150",'+
                               '"types" : [ "street_number" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Magic Way",'+
                               '"short_name" : "Magic Way",'+
                               '"types" : [ "route" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Anaheim Resort",'+
                               '"short_name" : "Anaheim Resort",'+
                               '"types" : [ "neighborhood", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Anaheim",'+
                               '"short_name" : "Anaheim",'+
                               '"types" : [ "locality", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "Orange County",'+
                               '"short_name" : "Orange County",'+
                               '"types" : [ "administrative_area_level_2", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "California",'+
                               '"short_name" : "CA",'+
                               '"types" : [ "administrative_area_level_1", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "United States",'+
                               '"short_name" : "US",'+
                               '"types" : [ "country", "political" ]'+
                            '},'+
                            '{'+
                               '"long_name" : "92802",'+
                               '"short_name" : "92802",'+
                               '"types" : [ "postal_code" ]'+
                            '}'+
                         '],'+
                         '"formatted_address" : "1150 Magic Way, Anaheim, CA 92802, USA",'+
                         '"geometry" : {'+
                            '"bounds" : {'+
                               '"northeast" : {'+
                                  '"lat" : 33.8126352,'+
                                  '"lng" : -117.9262566'+
                               '},'+
                               '"southwest" : {'+
                                  '"lat" : 33.8126351,'+
                                  '"lng" : -117.9272085'+
                               '}'+
                            '},'+
                            '"location" : {'+
                               '"lat" : 33.8126352,'+
                               '"lng" : -117.9267325'+
                            '},'+
                            '"location_type" : "GEOMETRIC_CENTER",'+
                            '"viewport" : {'+
                               '"northeast" : {'+
                                  '"lat" : 33.81398413029149,'+
                                  '"lng" : -117.9253835697085'+
                               '},'+
                               '"southwest" : {'+
                                  '"lat" : 33.8112861697085,'+
                                  '"lng" : -117.9280815302915'+
                               '}'+
                            '}'+
                         '},'+
                         '"place_id" : "ChIJlxt8ICoo3YARwgKlSTE3qL4",'+
                         '"types" : [ "route" ]'+
                      '}         '+
                       '],'+
                           '"status" : "OK"'+
                        '}');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
                    
                
                }
            }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
            }
                return null;
             }
        }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{
                if(req.getEndpoint()!='https://maps.googleapis.com/maps/api/geocode/json?'){
                    system.debug('if');
                    HttpResponse res= new HttpResponse();
                    //res.getMethod('GET');
                    //res.setBody('[{"title":"1313 Disneyland Dr, Anaheim, CA 92802, USA","description":"1313 Disneyland Dr, Anaheim, CA 92802, USA","location":{"Latitude":"33.81539590000001","Longitude":-117.9263991}}]');
                    res.setBody('{    "result" : {       "address_components" : [          {             "long_name" : "4015",             "short_name" : "4015",             "types" : [ "street_number" ]          },          {             "long_name" : "Interstate 35",             "short_name" : "I-35",             "types" : [ "route" ]          },          {             "long_name" : "San Marcos",             "short_name" : "San Marcos",             "types" : [ "locality", "political" ]          },          {             "long_name" : "Hays County",             "short_name" : "Hays County",             "types" : [ "administrative_area_level_2", "political" ]          },          {             "long_name" : "Texas",             "short_name" : "TX",             "types" : [ "administrative_area_level_1", "political" ]          },          {             "long_name" : "United States",             "short_name" : "US",             "types" : [ "country", "political" ]          },          {             "long_name" : "78666",             "short_name" : "78666",             "types" : [ "postal_code" ]          }       ],       "formatted_address" : "4015 I-35, San Marcos, TX 78666, USA",       "geometry" : {          "location" : {             "lat" : 29.8242474,             "lng" : -97.98525749999999          }       },       "name" : "Disney Store",       "place_id" : "ChIJcS2e9t-lXIYRVJ_sKDRrDcI",       "types" : [ "clothing_store", "store", "point_of_interest", "establishment" ]   },    "status" : "OK" }');

                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
                    
                }else{
                    //HttpResponse res= new HttpResponse();
                    
                    //res.setBody('INTDistanceMatrixAPIResponseWrapper:[destination_addresses=(28 HI-11, Hilo, HI 96720, USA), origin_addresses=(28 HI-11, Hilo, HI 96720, USA), rows=(Rows:[elements=(Elements:[distance=Distance:[text=1 ft, value=0], duration=Distance:[text=1 min, value=0], status=OK])]), status=OK]');
                    //res.setStatusCode(200);
                    //String responseBody = res.getBody(); 
                    //return res;
                                        HttpResponse res= new HttpResponse();
                    //res.getMethod('GET');
                    //res.setBody('[{"title":"1313 Disneyland Dr, Anaheim, CA 92802, USA","description":"1313 Disneyland Dr, Anaheim, CA 92802, USA","location":{"Latitude":"33.81539590000001","Longitude":-117.9263991}}]');
                    res.setBody('{    "result" : {       "address_components" : [          {             "long_name" : "4015",             "short_name" : "4015",             "types" : [ "street_number" ]          },          {             "long_name" : "Interstate 35",             "short_name" : "I-35",             "types" : [ "route" ]          },          {             "long_name" : "San Marcos",             "short_name" : "San Marcos",             "types" : [ "locality", "political" ]          },          {             "long_name" : "Hays County",             "short_name" : "Hays County",             "types" : [ "administrative_area_level_2", "political" ]          },          {             "long_name" : "Texas",             "short_name" : "TX",             "types" : [ "administrative_area_level_1", "political" ]          },          {             "long_name" : "United States",             "short_name" : "US",             "types" : [ "country", "political" ]          },          {             "long_name" : "78666",             "short_name" : "78666",             "types" : [ "postal_code" ]          }       ],       "formatted_address" : "4015 I-35, San Marcos, TX 78666, USA",       "geometry" : {          "location" : {             "lat" : 29.8242474,             "lng" : -97.98525749999999          }       },       "name" : "Disney Store",       "place_id" : "ChIJcS2e9t-lXIYRVJ_sKDRrDcI",       "types" : [ "clothing_store", "store", "point_of_interest", "establishment" ]   },    "status" : "OK" }');

                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;

                    
                
                }
            }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
            }
                return null;
             }
        }
    
    @isTest
    public static void testGetPlaceDetails(){
        
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1QWzrnXEcc'
        ));
        insert lstIntegrationSetting;
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new MockHttpResponseGenerator());
        INTMapSearchAddressWithAPI.getPlaceDetails('ChIJLZ4H3NbX3IARwauZXe2gOhg');
        Test.stopTest();
    }
    
    @isTest
    public static void testgetPlaceDetailsFromSADA(){ //AGB 4/18/2024 SFI-509 SADA API Part 3
        
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1QWzrnXEcc',
            Request_Timeout__c=120000
        ));
        insert lstIntegrationSetting;
        Test.startTest();
        String res = '{"address_components" : [{"long_name" : "1131","short_name" : "1131","types" : [ "street_number" ]},{"long_name" : "Magic Way","short_name" : "Magic Way","types" : [ "route" ]},{"long_name" : "Anaheim Resort","short_name" : "Anaheim Resort","types" : [ "neighborhood", "political" ]},{"long_name" : "Anaheim","short_name" : "Anaheim","types" : [ "locality", "political" ]},{"long_name" : "Orange County","short_name" : "Orange County","types" : [ "administrative_area_level_2", "political" ]},{"long_name" : "California","short_name" : "CA","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "United States","short_name" : "US","types" : [ "country", "political" ]},{"long_name" : "92802","short_name" : "92802","types" : [ "postal_code" ]}],"formatted_address" : "1131 Magic Way, Anaheim, CA 92802, USA","geometry" : {"location" : {"lat" : 33.81277130000001,"lng" : -117.9265127},"location_type" : "ROOFTOP","viewport" : {"northeast" : {"lat" : 33.81412028029151,"lng" : -117.9251637197085},"southwest" : {"lat" : 33.81142231970851,"lng" : -117.9278616802915}}},"place_id" : "ChIJ8zNSICoo3YARd0DgDhg2rMU","plus_code" : {"compound_code" : "R37F+49 Anaheim, CA, USA","global_code" : "8554R37F+49"},"types" : [ "street_address" ]},{"address_components" : [{"long_name" : "1150","short_name" : "1150","types" : [ "street_number" ]},{"long_name" : "Magic Way","short_name" : "Magic Way","types" : [ "route" ]},{"long_name" : "Anaheim Resort","short_name" : "Anaheim Resort","types" : [ "neighborhood", "political" ]},{"long_name" : "Anaheim","short_name" : "Anaheim","types" : [ "locality", "political" ]},{"long_name" : "Orange County","short_name" : "Orange County","types" : [ "administrative_area_level_2", "political" ]},{"long_name" : "California","short_name" : "CA","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "United States","short_name" : "US","types" : [ "country", "political" ]},{"long_name" : "92802","short_name" : "92802","types" : [ "postal_code" ]}],"formatted_address" : "1150 Magic Way, Anaheim, CA 92802, USA","geometry" : {"bounds" : {"northeast" : {"lat" : 33.8126352,"lng" : -117.9262566},"southwest" : {"lat" : 33.8126351,"lng" : -117.9272085}},"location" : {"lat" : 33.8126352,"lng" : -117.9267325},"location_type" : "GEOMETRIC_CENTER","viewport" : {"northeast" : {"lat" : 33.81398413029149,"lng" : -117.9253835697085},"southwest" : {"lat" : 33.8112861697085,"lng" : -117.9280815302915}}},"place_id" : "ChIJlxt8ICoo3YARwgKlSTE3qL4","types" : [ "route" ]}]}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        list<map<string,object>> listResults = INTMapSearchAddressWithAPI.getPlaceDetailsFromSADA('ChIJLZ4H3NbX3IARwauZXe2gOhg','00000000');
        Test.stopTest();
        assert.areEqual((string)listResults[0].get('city'), 'Anaheim');
        assert.areEqual((string)listResults[0].get('state'), 'California');
        assert.areEqual((string)listResults[0].get('zip'), '92802');
    }
    
    @isTest
    public static void testsadaplacedetailresponse() //AGB 4/18/2024 SFI-509 SADA API Part 3
    {
        String res = '{"address_components" : [{"long_name" : "1131","short_name" : "1131","types" : [ "street_number" ]},{"long_name" : "Magic Way","short_name" : "Magic Way","types" : [ "route" ]},{"long_name" : "Anaheim Resort","short_name" : "Anaheim Resort","types" : [ "neighborhood", "political" ]},{"long_name" : "Anaheim","short_name" : "Anaheim","types" : [ "locality", "political" ]},{"long_name" : "Orange County","short_name" : "Orange County","types" : [ "administrative_area_level_2", "political" ]},{"long_name" : "California","short_name" : "CA","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "United States","short_name" : "US","types" : [ "country", "political" ]},{"long_name" : "92802","short_name" : "92802","types" : [ "postal_code" ]}],"formatted_address" : "1131 Magic Way, Anaheim, CA 92802, USA","geometry" : {"location" : {"lat" : 33.81277130000001,"lng" : -117.9265127},"location_type" : "ROOFTOP","viewport" : {"northeast" : {"lat" : 33.81412028029151,"lng" : -117.9251637197085},"southwest" : {"lat" : 33.81142231970851,"lng" : -117.9278616802915}}},"place_id" : "ChIJ8zNSICoo3YARd0DgDhg2rMU","plus_code" : {"compound_code" : "R37F+49 Anaheim, CA, USA","global_code" : "8554R37F+49"},"types" : [ "street_address" ]},{"address_components" : [{"long_name" : "1150","short_name" : "1150","types" : [ "street_number" ]},{"long_name" : "Magic Way","short_name" : "Magic Way","types" : [ "route" ]},{"long_name" : "Anaheim Resort","short_name" : "Anaheim Resort","types" : [ "neighborhood", "political" ]},{"long_name" : "Anaheim","short_name" : "Anaheim","types" : [ "locality", "political" ]},{"long_name" : "Orange County","short_name" : "Orange County","types" : [ "administrative_area_level_2", "political" ]},{"long_name" : "California","short_name" : "CA","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "United States","short_name" : "US","types" : [ "country", "political" ]},{"long_name" : "92802","short_name" : "92802","types" : [ "postal_code" ]}],"formatted_address" : "1150 Magic Way, Anaheim, CA 92802, USA","geometry" : {"bounds" : {"northeast" : {"lat" : 33.8126352,"lng" : -117.9262566},"southwest" : {"lat" : 33.8126351,"lng" : -117.9272085}},"location" : {"lat" : 33.8126352,"lng" : -117.9267325},"location_type" : "GEOMETRIC_CENTER","viewport" : {"northeast" : {"lat" : 33.81398413029149,"lng" : -117.9253835697085},"southwest" : {"lat" : 33.8112861697085,"lng" : -117.9280815302915}}},"place_id" : "ChIJlxt8ICoo3YARwgKlSTE3qL4","types" : [ "route" ]}]}';
		system.assertEquals('ChIJ8zNSICoo3YARd0DgDhg2rMU',sadaplacedetailsresponse.parse(res).place_id);
    }
    
    @isTest
    public static void testgetAutoSuggestAddressFromSADA(){ //AGB 4/18/2024 SFI-509 SADA API Part 3
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
        ));
        insert lstIntegrationSetting;
        String res = '{"predictions":[{"description":"SomethingAddComplete","place_id":"SomethingPlace","structured_formatting":{"main_text":"SomethingLocName"}}]}'; 
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        Test.startTest();
        List<INTMapSearchAddressWithAPI.AutoSuggestionWrapper> suggestions = INTMapSearchAddressWithAPI.getAutoSuggestAddressFromSADA('45,12-30','00000000');
        Test.stopTest();        
        assert.areEqual('SomethingPlace',suggestions[0].placeId);
        assert.areEqual('SomethingLocName',suggestions[0].locName);
        assert.areEqual('SomethingAddComplete',suggestions[0].AddComplete);
    } 
   
      @isTest
    public static void testGetException(){
        
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1QWzrnXEcc'
        ));
        insert lstIntegrationSetting;
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new ExceptionHttpResponseGenerator());
        INTMapSearchAddressWithAPI.getPlaceDetails('ChIJLZ4H3NbX3IARwauZXe2gOhg');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGetMileMarker() {
      Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Mile Marker').getRecordTypeId();
        Schema.Location loc = new Schema.Location();
        loc.Name = 'test';
        loc.recordTypeId = recordTypeId;
        loc.Mile_Marker__c = '2';
        loc.Highway__c = '170';
        loc.State__c = 'NM';
        loc.Landmark__c = 'test landmark';
        loc.Country__c = 'US';
        loc.County__c = 'test county';
        loc.GeoLocation__latitude__s = 36.7642024;
        loc.GeoLocation__longitude__s = -108.2395278;
        insert loc;
        
        INTMapSearchAddressWithAPI.getMileMarker(loc.Highway__c, loc.Mile_Marker__c,loc.State__c);
        System.assertEquals('test landmark', loc.Landmark__c);
    }
    
    @isTest
    public static void testGetPOILocation() {
      Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('ACE POI').getRecordTypeId();
       // ARR_Call_Receive_LWC_UI_Configuration__c cs = new ARR_Call_Receive_LWC_UI_Configuration__c();
        //cs.ACE_POI_Search_Radius_mile__c = 7;
       // insert cs;
       // Decimal miles = cs.ACE_POI_Search_Radius_mile__c;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'test';
        loc.recordTypeId = recordTypeId;
        loc.Landmark__c = 'test landmark';
        loc.Country__c = 'US';
        loc.City__c = 'CA';
        loc.GeoLocation__latitude__s = 36.7642024;
        loc.GeoLocation__longitude__s = -108.2395278;
         insert loc;
        
        INTMapSearchAddressWithAPI.getPOILocation(String.valueOf(loc.GeoLocation__latitude__s), string.valueOf(loc.GeoLocation__longitude__s));
        System.assertEquals('test landmark', loc.Landmark__c);
    }
    
    @isTest
    public static void testGetPOIBasedOnSelectedAddress() {
        Schema.Location loc = new Schema.Location();
        loc.Name = 'test';
        loc.Mile_Marker__c = '2';
        loc.Highway__c = '170';
        loc.State__c = 'NM';
        loc.Landmark__c = 'test landmark';
        loc.Country__c = 'US';
        loc.County__c = 'test county';
        loc.GeoLocation__latitude__s = 36.7642024;
        loc.GeoLocation__longitude__s = -108.2395278;
        insert loc;
        INTMapSearchAddressWithAPI.getPOIBasedOnSelectedAddress(loc.Id);
        System.assertEquals(loc.Id, loc.Id);
    }
    
    @isTest
    public static void testUpdateCaseRecord(){
        Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('ACE POI').getRecordTypeId();
        Id mileMarkerRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Mile Marker').getRecordTypeId();
        Schema.Location loc = new Schema.Location();
        loc.Name = 'test';
        loc.Mile_Marker__c = '2';
        loc.recordTypeId = recordTypeId;
        loc.Highway__c = '170';
        loc.State__c = 'NM';
        loc.Landmark__c = 'test landmark';
        loc.Country__c = 'US';
        loc.County__c = 'test county';
        loc.GeoLocation__latitude__s = 36.7642024;
        loc.GeoLocation__longitude__s = -108.2395278;
        insert loc;
        
        Schema.Location loc1 = new Schema.Location();
        loc1.Name = 'test';
        loc1.Mile_Marker__c = '2';
        loc1.recordTypeId = mileMarkerRecordTypeId;
        loc1.Highway__c = '170';
        loc1.State__c = 'NM';
        loc1.Landmark__c = 'test landmark';
        loc1.Country__c = 'US';
        loc1.County__c = 'test county';
        loc1.GeoLocation__latitude__s = 36.7642024;
        loc1.GeoLocation__longitude__s = -108.2395278;
        insert loc1;
        
        Integer recordCount = 2;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;
        
         List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
        
         List<Case> cases = new List<Case>();
        for( WorkOrder workOrder : workOrders ) {
            Case c1 = FSL_DataFactory.createCase( 'ERS' );
            cases.add( c1 );
        }
        insert cases;
        INTMapSearchAddressWithAPI.updateCaseRecord(cases[0].Id, loc.Id);
        INTMapSearchAddressWithAPI.updateCaseRecord(cases[0].Id, loc1.Id);
        INTMapSearchAddressWithAPI.getCaseDetails(cases[0].Id);
        INTMapSearchAddressWithAPI.updateCaseBasedonAddressValue(cases[0].Id,'1313 Disneyland Dr, Anaheim, CA 92802, USA', '1313 Disneyland Dr','Anaheim','CA','92802','USA','33.81209183', '-117.91897583','XX');
        INTMapSearchAddressWithAPI.updateCaseBasedontowAddressValue(cases[0].Id,'1313 Disneyland Dr, Anaheim, CA 92802, USA', '1313 Disneyland Dr','Anaheim','CA','92802','USA','33.81209183', '-117.91897583','XX',2);
    }
    
    @isTest
    public static void testGetgeoCodeDetails(){
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc'
        ));
        insert lstIntegrationSetting;
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new GeoCodeHttpResponseGenerator());
        INTMapSearchAddressWithAPI.getgeoCodeDetails('-117.92310495','33.81539590000001');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetAddress(){
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc',
            Request_Timeout__c = 10
        ));
        insert lstIntegrationSetting;
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new AddressHttpResponseGenerator());
        INTMapSearchAddressWithAPI.getAddress('1313 Disneyland Dr, Anaheim, CA 92802, USA');
        Test.stopTest();
    }

    @isTest
    public static void testGetAddress_POI(){
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc',
            Request_Timeout__c = 10
        ));
        //, Header_Value__c = '[{\"key\":\"X-Sada-Api-Key\",\"value\":\"abcd\"}]'
        insert lstIntegrationSetting;
        Test.startTest();
        Test.setMock(HttpCalloutMock.Class, new POIGeoCodeResponseGenerator());
        INTMapSearchAddressWithAPI.getAddress('POI- Exit 21');
        Test.stopTest();
    }
    
    //SSFI-1111 MPatel commented Bing
    /*
        @isTest
    static void testBing(){
        test.startTest();
        String res2 = '{"resourceSets":[{"estimatedTotal":1,"resources":[{"bbox":[32.92852128242932,-96.95662605044866,32.936246717570675,-96.94435394955134],"name":"313 Sheridan Trail, Irving, TX 75063","point":{"type":"Point","coordinates":[32.932384,-96.95049]},"address":{"addressLine":"313 Sheridan Trail","adminDistrict":"TX","adminDistrict2":"Dallas County","countryRegion":"United States","formattedAddress":"313 Sheridan Trail, Irving, TX 75063","locality":"Irving","neighborhood":"South Dallas","postalCode":"75063"},"confidence":"Medium","entityType":"Address","geocodePoints":[{"type":"Point","coordinates":[32.932384,-96.95049],"calculationMethod":"Rooftop","usageTypes":["Display"]},{"type":"Point","coordinates":[32.9321974,-96.9504909],"calculationMethod":"Rooftop","usageTypes":["Route"]}],"matchCodes":["Good"]}]}],"statusCode":200,"statusDescription":"OK"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res2, 200));
        INTMapSearchAddressWithAPI.BingResource bingRes = new INTMapSearchAddressWithAPI.BingResource();
        INTMapSearchAddressWithAPI.Address bingAddress = new INTMapSearchAddressWithAPI.Address();
        INTMapSearchAddressWithAPI.Point bingPoint = new INTMapSearchAddressWithAPI.Point();
        //String response=INTMapSearchAddressWithAPI.getGeoJSONAddress('ChIJLZ4H3NbX3IARwauZXe2gOhg','Test Address');
        //system.assertNotEquals('',response);
        test.stopTest();
    }*/
    
         @isTest
    static void testCMT(){
        test.startTest();
        INTMapSearchAddressWithAPI.getCustomSettingsForAPISelection();
        INTMapSearchAddressWithAPI.getCustomSettings();
        test.stopTest();
    }
    
        @isTest
    static void testGetDistanceInMilesUsingAPI(){
         test.startTest();      
        
        insert new Integration_Settings__c(Name = 'GETDistance_Matrix_API', Method__c= 'GET',Request_Timeout__c = 32000, API_Key__c ='AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc',
                                            Enpoint_URL__c = 'https://maps.googleapis.com/maps/api/distancematrix/json?');

        Test.setMock(HttpCalloutMock.Class, new DistanceHttpResponseGenerator());
        INTMapSearchAddressWithAPI.getDistanceInMilesUsingAPI('38.910704','-94.660378','32.428549','99.785775');
        INTMapSearchAddressWithAPI.getDistanceMatrixDetails('38.910704','-94.660378','32.428549','99.785775','imperial');
        
         test.stopTest();
    }
    
       @isTest
    static void testUpdateCaseDriverDirection(){
        test.startTest();
        
        Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('ACE POI').getRecordTypeId();
        Id mileMarkerRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Mile Marker').getRecordTypeId();
        Schema.Location loc = new Schema.Location();
        loc.Name = 'test';
        loc.Mile_Marker__c = '2';
        loc.recordTypeId = recordTypeId;
        loc.Highway__c = '170';
        loc.State__c = 'NM';
        loc.Landmark__c = 'test landmark';
        loc.Country__c = 'US';
        loc.County__c = 'test county';
        loc.GeoLocation__latitude__s = 36.7642024;
        loc.GeoLocation__longitude__s = -108.2395278;
        insert loc;
        
        Schema.Location loc1 = new Schema.Location();
        loc1.Name = 'test';
        loc1.Mile_Marker__c = '2';
        loc1.recordTypeId = mileMarkerRecordTypeId;
        loc1.Highway__c = '170';
        loc1.State__c = 'NM';
        loc1.Landmark__c = 'test landmark';
        loc1.Country__c = 'US';
        loc1.County__c = 'test county';
        loc1.GeoLocation__latitude__s = 36.7642024;
        loc1.GeoLocation__longitude__s = -108.2395278;
        insert loc1;
        
        Integer recordCount = 2;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;
        
         List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
        
         List<Case> cases = new List<Case>();
        for( WorkOrder workOrder : workOrders ) {
            Case c1 = FSL_DataFactory.createCase( 'ERS' );
            cases.add( c1 );
        }
        insert cases;
        INTMapSearchAddressWithAPI.updateCaseDriverDirection(cases[0].Id,'driverDirection test');
        test.stopTest();
    }
    
    //SSFI-1111 MPatel Commented Bing
    /*
    @IsTest
    static void testInnerClasses() {
        INTMapSearchAddressWithAPI.BingResource br = new INTMapSearchAddressWithAPI.BingResource();
        br.point = new INTMapSearchAddressWithAPI.Point();
        INTMapSearchAddressWithAPI.BingResourceSet brs = new INTMapSearchAddressWithAPI.BingResourceSet();
        brs.resources = new List<INTMapSearchAddressWithAPI.BingResource>();
        INTMapSearchAddressWithAPI.BingResponse  bresp = new INTMapSearchAddressWithAPI.BingResponse();
        bresp.resourceSets = new List<INTMapSearchAddressWithAPI.BingResourceSet>();
        
        INTMapSearchAddressWithAPI.GeocodePoints gp = new INTMapSearchAddressWithAPI.GeocodePoints();
        gp.type = 'testType';
        gp.coordinates = new List<Double>();
        
        INTMapSearchAddressWithAPI.bingTimezone btz = new INTMapSearchAddressWithAPI.bingTimezone();
        btz.statusCode = 100;
        btz.statusDescription = 'Desc';
        btz.resourceSets = new List<INTMapSearchAddressWithAPI.BingResourceSet>();
        
        INTMapSearchAddressWithAPI.ConvertedTime ct = new INTMapSearchAddressWithAPI.ConvertedTime();
        ct.localTime = '01:00';
        ct.timeZoneDisplayAbbr = 'abbr';
        ct.timeZoneDisplayName = 'TZ Name';
        ct.utcOffsetWithDst = '5';
        
        INTMapSearchAddressWithAPI.TimeZone tz = new INTMapSearchAddressWithAPI.TimeZone();
        tz.abbreviation = 'abb';
        tz.convertedTime = ct;
        tz.genericName = 'generic';
        tz.ianaTimeZoneId = 'iana';
        tz.utcOffset = '5';
        tz.windowsTimeZoneId = 'wtz';
        
    }*/
    
    @isTest
    static void testCalculateDistanceMilesMethod() {
        // Coordinates for LA and SF
        Double lat1 = 34.0522;
        Double lon1 = -118.2437;
        Double lat2 = 37.7749;
        Double lon2 = -122.4194;

        // Call method
        Double distance = INTMapSearchAddressWithAPI.calculateDistanceMiles(lat1, lon1, lat2, lon2);

        // Assertions
        System.assertNotEquals(null, distance, 'Distance should not be null');
        System.assert(distance > 0, 'Distance should be positive');
    }

    @isTest
    static void testGetCaseTowMileageMethod() {
        // Create a test Case with geolocation
        Case c = new Case(
            Vehicle_Geolocation__Latitude__s = 34.0522,
            Vehicle_Geolocation__Longitude__s = -118.2437
        );
        insert c;

        // Destination: SF
        Double destLat = 37.7749;
        Double destLon = -122.4194;

        Test.startTest();
        Decimal mileage = INTMapSearchAddressWithAPI.getCaseTowMileage(c.Id, destLat, destLon);
        Test.stopTest();

        System.assertNotEquals(null, mileage, 'Mileage should not be null');
        System.assert(mileage > 0, 'Mileage should be positive');
    }
    
    @isTest
static void testUpdateCaseFieldMethod() {
    // Create a test Case record
    Case testCase = new Case(
        Vehicle_Location_Types__c = 'Initial'
    );
    insert testCase;

    // New value to update
    String newLocationType = 'Updated';

    Test.startTest();
    INTMapSearchAddressWithAPI.updateCaseField(testCase.Id, newLocationType);
    Test.stopTest();

    // Retrieve updated Case
    Case updatedCase = [SELECT Vehicle_Location_Types__c FROM Case WHERE Id = :testCase.Id];
    System.assertEquals(newLocationType, updatedCase.Vehicle_Location_Types__c, 'Case field should be updated');
}
    
    /*@isTest
static void testCancelCaseForReasonMethod() {
    // Create a test Case
    Case testCase = new Case(
        Status = 'New'
    );
    insert testCase;

    // Cancellation reason
    String cancelReason = 'Customer no longer needs service';

    Test.startTest();
    Boolean result = INTMapSearchAddressWithAPI.cancelCaseForReason(testCase.Id, cancelReason);
    Test.stopTest();

    // Assert method returned true
    System.assertEquals(true, result, 'Method should return true on successful update');

    // Query updated Case
    Case updatedCase = [SELECT Status, Cancelled_Reason__c FROM Case WHERE Id = :testCase.Id];
    System.assertEquals('Cancelled', updatedCase.Status, 'Status should be updated to Cancelled');
    System.assertEquals(cancelReason, updatedCase.Cancelled_Reason__c, 'Cancelled Reason should be updated');
}*/

}