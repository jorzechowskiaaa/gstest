@isTest
public class INTSADAGeoMapAPI_Test {
    
     @testSetup static void setup() {
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Place_Details_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Place_AutoComplete_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
         lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API_GEOCODE',
            Method__c='GET',
            //Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Header_Value__c ='[{"key": "Authorization","value": "ABC"}]',
            Enpoint_URL__c='https://dev.ane.sadaapis.com/',
            Request_Timeout__c=120000
            
        ));
        /*SSFI-1111 MPatel commented Bing Methods 5/7/25
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'BING_API_GEOCODE',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        )); */
		lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Google_Timezone_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Enpoint_URL__c='https://test/maps/api/timezone/json?language=en&region=en&address=',
            API_Key__c='test',
            Request_Timeout__c=120000           
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Google_Geocode_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            API_Key__c='test',
            Request_Timeout__c=120000           
        ));
       	
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Google_Directions_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            API_Key__c='test',
            Request_Timeout__c=120000           
        ));
         
        insert lstIntegrationSetting;

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
            Case c1 = FSL_DataFactory.createCase( 'Clear Queue Failure' );
            c1.FSL_Work_Order__c = workOrder.Id;
            cases.add( c1 );

            Case c2 = FSL_DataFactory.createCase( 'Manual Service Order' );
            c2.FSL_Work_Order__c = workOrder.Id;
            cases.add( c2 );
        }
        insert cases;
     }
    
    
    @isTest
    static void testSADAMap() { 
        Test.startTest();
        String res = '{"results": [{"address_components": [  {"long_name": "5652","short_name": "5652","types": [  "street_number"]},{"long_name": "Lankershim Boulevard","short_name": "Lankershim Blvd","types": [  "route"]},{"long_name": "North Hollywood","short_name": "NoHo","types": [  "neighborhood",  "political"]},{"long_name": "Los Angeles","short_name": "Los Angeles","types": [  "locality",  "political"]},{"long_name": "Los Angeles County","short_name": "Los Angeles County","types": [  "administrative_area_level_2",  "political"]},{"long_name": "California","short_name": "CA","types": [  "administrative_area_level_1",  "political"]},{"long_name": "United States","short_name": "US","types": [  "country",  "political"]},{"long_name": "91601","short_name": "91601","types": [  "postal_code"]}],"formatted_address": "5652 Lankershim Blvd, North Hollywood, CA 91601, USA","geometry": {"location": {"lat": 34.1738716,"lng": -118.3797732},"location_type": "RANGE_INTERPOLATED","viewport": {"northeast": {  "lat": 34.1752205802915,  "lng": -118.3784242197085},"southwest": {  "lat": 34.1725226197085,  "lng": -118.3811221802915}}},"place_id": "EjQ1NjUyIExhbmtlcnNoaW0gQmx2ZCwgTm9ydGggSG9sbHl3b29kLCBDQSA5MTYwMSwgVVNBIhsSGQoUChIJMx0Ik-iVwoARj6B3-UW2-6YQlCw","types": ["street_address"]}   ],   "status": "OK" }';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        String response=INTSADAGeoMapAPI.getGeoJSONAddress('5620', null);
        system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response).status);
        Test.stopTest();   
    }
    
    @isTest
    static void testMethod2(){
        test.startTest();
        String res2 = '{"predictions":[{"description":"New Delhi Indian Restaurant, Chestnut Street, Philadelphia, PA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJyQp0FfjGxokRb8SXEFjMVK4","reference":"ChIJyQp0FfjGxokRb8SXEFjMVK4","structured_formatting":{"main_text":"New Delhi Indian Restaurant","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Chestnut Street, Philadelphia, PA, USA"},"terms":[{"offset":0,"value":"New Delhi Indian Restaurant"},{"offset":29,"value":"Chestnut Street"},{"offset":46,"value":"Philadelphia"},{"offset":60,"value":"PA"},{"offset":64,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Diamond'+'s, West Green Street, Ithaca, NY, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJdQUbTJyB0IkRATx_-B0wSOA","reference":"ChIJdQUbTJyB0IkRATx_-B0wSOA","structured_formatting":{"main_text":"New Delhi Diamond\'s","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"West Green Street, Ithaca, NY, USA"},"terms":[{"offset":0,"value":"New Delhi Diamond\'s"},{"offset":21,"value":"West Green Street"},{"offset":40,"value":"Ithaca"},{"offset":48,"value":"NY"},{"offset":52,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace, East Colorado Boulevard, Pasadena, CA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJBSeul1zDwoARS6Wy7W2zNo8","reference":"ChIJBSeul1zDwoARS6Wy7W2zNo8","structured_formatting":{"main_text":"New Delhi Palace","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Colorado Boulevard, Pasadena, CA, USA"},"terms":[{"offset":0,"value":"New Delhi Palace"},{"offset":18,"value":"East Colorado Boulevard"},{"offset":43,"value":"Pasadena"},{"offset":53,"value":"CA"},{"offset":57,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Restaurant of India, Meacham Road, Schaumburg, IL, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJA7Tgr66vD4gRlHhkc059Qds","reference":"ChIJA7Tgr66vD4gRlHhkc059Qds","structured_formatting":{"main_text":"New Delhi Restaurant of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Meacham Road, Schaumburg, IL, USA"},"terms":[{"offset":0,"value":"New Delhi Restaurant of India"},{"offset":31,"value":"Meacham Road"},{"offset":45,"value":"Schaumburg"},{"offset":57,"value":"IL"},{"offset":61,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace-Cuisine Of India, East Broadway Boulevard, Tucson, AZ, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJpYJTXnNv1oYRSO9bMikSItM","reference":"ChIJpYJTXnNv1oYRSO9bMikSItM","structured_formatting":{"main_text":"New Delhi Palace-Cuisine Of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Broadway Boulevard, Tucson, AZ, USA"},"terms":[{"offset":0,"value":"New Delhi Palace-Cuisine Of India"},{"offset":35,"value":"East Broadway Boulevard"},{"offset":60,"value":"Tucson"},{"offset":68,"value":"AZ"},{"offset":72,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]}],"status":"ERROR"}	}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res2, 200));
        String response=INTSADAGeoMapAPI.getAddressAutoComplete('Test','Country:us|Country:pr');
        system.assertEquals(null,response);
        test.stopTest();
    }
    
    /*SSFI-1111 MPatel commented Bing Methods 5/8/25
    @isTest
    static void testBing(){
        test.startTest();
        String res2 = '{"resourceSets":[{"estimatedTotal":1,"resources":[{"bbox":[32.92852128242932,-96.95662605044866,32.936246717570675,-96.94435394955134],"name":"313 Sheridan Trail, Irving, TX 75063","point":{"type":"Point","coordinates":[32.932384,-96.95049]},"address":{"addressLine":"313 Sheridan Trail","adminDistrict":"TX","adminDistrict2":"Dallas County","countryRegion":"United States","formattedAddress":"313 Sheridan Trail, Irving, TX 75063","locality":"Irving","neighborhood":"South Dallas","postalCode":"75063"},"confidence":"Medium","entityType":"Address","geocodePoints":[{"type":"Point","coordinates":[32.932384,-96.95049],"calculationMethod":"Rooftop","usageTypes":["Display"]},{"type":"Point","coordinates":[32.9321974,-96.9504909],"calculationMethod":"Rooftop","usageTypes":["Route"]}],"matchCodes":["Good"]}]}],"statusCode":200,"statusDescription":"OK"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res2, 200));
        INTSADAGeoMapAPI.BingResource bingRes = new INTSADAGeoMapAPI.BingResource();
        INTSADAGeoMapAPI.Address bingAddress = new INTSADAGeoMapAPI.Address();
         INTSADAGeoMapAPI.Point bingPoint = new INTSADAGeoMapAPI.Point();
        String response=INTSADAGeoMapAPI.getGeoJSONAddress(null,'Test Address');
        system.assertNotEquals(null,response);
        test.stopTest();
    } */
    @isTest
    public static void testgetAddressAutoComplete(){
        Test.startTest();
        String res = '{"predictions":[{"description":"New Delhi Indian Restaurant, Chestnut Street, Philadelphia,n    PA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJyQp0FfjGxokRb8SXEFjMVK4","reference":"ChIJyQp0FfjGxokRb8SXEFjMVK4","structured_formatting":{"main_text":"New Delhi Indian Restaurant","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Chestnut Street, Philadelphia, PA, USA"},"terms":[{"offset":0,"value":"New Delhi Indian Restaurant"},{"offset":29,"value":"Chestnut Street"},{"offset":46,"value":"Philadelphia"},{"offset":60,"value":"PA"},{"offset":64,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Diamond'+'s, West Green Street, Ithaca, NY, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJdQUbTJyB0IkRATx_-B0wSOA","reference":"ChIJdQUbTJyB0IkRATx_-B0wSOA","structured_formatting":{"main_text":"New Delhi Diamond\'s","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"West Green Street, Ithaca, NY, USA"},"terms":[{"offset":0,"value":"New Delhi Diamond\'s"},{"offset":21,"value":"West Green Street"},{"offset":40,"value":"Ithaca"},{"offset":48,"value":"NY"},{"offset":52,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace, East Colorado Boulevard, Pasadena, CA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJBSeul1zDwoARS6Wy7W2zNo8","reference":"ChIJBSeul1zDwoARS6Wy7W2zNo8","structured_formatting":{"main_text":"New Delhi Palace","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Colorado Boulevard, Pasadena, CA, USA"},"terms":[{"offset":0,"value":"New Delhi Palace"},{"offset":18,"value":"East Colorado Boulevard"},{"offset":43,"value":"Pasadena"},{"offset":53,"value":"CA"},{"offset":57,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Restaurant of India, Meacham Road, Schaumburg, IL, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJA7Tgr66vD4gRlHhkc059Qds","reference":"ChIJA7Tgr66vD4gRlHhkc059Qds","structured_formatting":{"main_text":"New Delhi Restaurant of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Meacham Road, Schaumburg, IL, USA"},"terms":[{"offset":0,"value":"New Delhi Restaurant of India"},{"offset":31,"value":"Meacham Road"},{"offset":45,"value":"Schaumburg"},{"offset":57,"value":"IL"},{"offset":61,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace-Cuisine Of India, East Broadway Boulevard, Tucson, AZ, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJpYJTXnNv1oYRSO9bMikSItM","reference":"ChIJpYJTXnNv1oYRSO9bMikSItM","structured_formatting":{"main_text":"New Delhi Palace-Cuisine Of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Broadway Boulevard, Tucson, AZ, USA"},"terms":[{"offset":0,"value":"New Delhi Palace-Cuisine Of India"},{"offset":35,"value":"East Broadway Boulevard"},{"offset":60,"value":"Tucson"},{"offset":68,"value":"AZ"},{"offset":72,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]}],"status":"OK"}	}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 201));
        String response1 = INTSADAGeoMapAPI.getAddressAutoComplete('New Delhi','Country:us|Country:pr');
        system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response1).status);
        Test.stopTest();
    }
  //  @isTest
    // public static void testgetGeoJSONAddress(){
    //     Test.startTest();
    //     String res = '{"predictions":[{"description":"New Delhi Indian Restaurant, Chestnut Street, Philadelphia,n    PA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJyQp0FfjGxokRb8SXEFjMVK4","reference":"ChIJyQp0FfjGxokRb8SXEFjMVK4","structured_formatting":{"main_text":"New Delhi Indian Restaurant","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Chestnut Street, Philadelphia, PA, USA"},"terms":[{"offset":0,"value":"New Delhi Indian Restaurant"},{"offset":29,"value":"Chestnut Street"},{"offset":46,"value":"Philadelphia"},{"offset":60,"value":"PA"},{"offset":64,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Diamond'+'s, West Green Street, Ithaca, NY, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJdQUbTJyB0IkRATx_-B0wSOA","reference":"ChIJdQUbTJyB0IkRATx_-B0wSOA","structured_formatting":{"main_text":"New Delhi Diamond\'s","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"West Green Street, Ithaca, NY, USA"},"terms":[{"offset":0,"value":"New Delhi Diamond\'s"},{"offset":21,"value":"West Green Street"},{"offset":40,"value":"Ithaca"},{"offset":48,"value":"NY"},{"offset":52,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace, East Colorado Boulevard, Pasadena, CA, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJBSeul1zDwoARS6Wy7W2zNo8","reference":"ChIJBSeul1zDwoARS6Wy7W2zNo8","structured_formatting":{"main_text":"New Delhi Palace","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Colorado Boulevard, Pasadena, CA, USA"},"terms":[{"offset":0,"value":"New Delhi Palace"},{"offset":18,"value":"East Colorado Boulevard"},{"offset":43,"value":"Pasadena"},{"offset":53,"value":"CA"},{"offset":57,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Restaurant of India, Meacham Road, Schaumburg, IL, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJA7Tgr66vD4gRlHhkc059Qds","reference":"ChIJA7Tgr66vD4gRlHhkc059Qds","structured_formatting":{"main_text":"New Delhi Restaurant of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"Meacham Road, Schaumburg, IL, USA"},"terms":[{"offset":0,"value":"New Delhi Restaurant of India"},{"offset":31,"value":"Meacham Road"},{"offset":45,"value":"Schaumburg"},{"offset":57,"value":"IL"},{"offset":61,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]},{"description":"New Delhi Palace-Cuisine Of India, East Broadway Boulevard, Tucson, AZ, USA","matched_substrings":[{"length":9,"offset":0}],"place_id":"ChIJpYJTXnNv1oYRSO9bMikSItM","reference":"ChIJpYJTXnNv1oYRSO9bMikSItM","structured_formatting":{"main_text":"New Delhi Palace-Cuisine Of India","main_text_matched_substrings":[{"length":9,"offset":0}],"secondary_text":"East Broadway Boulevard, Tucson, AZ, USA"},"terms":[{"offset":0,"value":"New Delhi Palace-Cuisine Of India"},{"offset":35,"value":"East Broadway Boulevard"},{"offset":60,"value":"Tucson"},{"offset":68,"value":"AZ"},{"offset":72,"value":"USA"}],"types":["restaurant","food","point_of_interest","establishment"]}],"status":"OK"}	}';
    //     Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 201));
    //     String response1 = INTSADAGeoMapAPI.getGeoJSONAddress(null, 'New Delhi');
    //     system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response1).status);
    //     Test.stopTest();
    // }
    // 
     
    @isTest
    static void test_getGeoJSONAddressInvalidArgs(){
        Test.startTest();
        String strAddress ='';
        String strplaceId='';
        String actual = INTSADAGeoMapAPI.getGeoJSONAddress(strplaceId, null);
        System.assertEquals(null, actual);
        Test.stopTest();
    }
    
    @isTest
    static void test_getAddressAutoCompleteInvalidArgs(){
        Test.startTest();
        String strInput ='';
        string countrylist='';
        String actual = INTSADAGeoMapAPI.getAddressAutoComplete(strInput,countrylist);
        System.assertEquals(null, actual);
        Test.stopTest();
    }

    /*SSFI-1111 MPatel commented Bing Methods 5/8/25
    @isTest
    public static void testgetGeoJSONAddressWithTimezone(){
        Test.startTest();
        String res = '{"resourceSets":[{"resources":[{"timeZone":{"windowsTimeZoneId":"Central Standard Time","utcOffset":"-6:00","ianaTimeZoneId":"America/Chicago","genericName":"Central Standard Time","convertedTime":{"utcOffsetWithDst":"-6:00","timeZoneDisplayName":"Central Standard Time","timeZoneDisplayAbbr":"CST","localTime":"2022-12-06T17:23:49"},"abbreviation":"CST"},"point":{"coordinates":[32.93880463,-97.00925446]},"name":"AAA Texas Headquarters","geocodePoints":[{"type":"Point","coordinates":[32.93880463,-97.00925446]}],"entityType":"LocalBusiness","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 S Freeport Pkwy, Coppell, TX, 75019","countryRegion":"United States","adminDistrict2":null,"adminDistrict":"TX","addressLine":"1225 S Freeport Pkwy"}},{"timeZone":null,"point":{"coordinates":[32.9388,-97.009254]},"name":"1225 Freeport Pkwy, Coppell, TX 75019","geocodePoints":[{"type":"Point","coordinates":[32.9388,-97.009254]},{"type":"Point","coordinates":[32.9387271,-97.0092034]}],"entityType":"Address","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 Freeport Pkwy, Coppell, TX 75019","countryRegion":"United States","adminDistrict2":"Dallas County","adminDistrict":"TX","addressLine":"1225 Freeport Pkwy"}}]}]}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 201));
        String response1 = INTSADAGeoMapAPI.getTimezone('1225 freeport pkwy, coppell, tx 75019');
        INTSADAGeoMapAPI.BingResponse rs = (INTSADAGeoMapAPI.BingResponse) JSON.deserialize ( response1, INTSADAGeoMapAPI.BingResponse.class );
        String tzOff = rs.resourceSets.get(0).resources.get(0).timeZone.abbreviation
                    +  rs.resourceSets.get(0).resources.get(0).timeZone.utcOffset;
        System.debug(' TimezoneOffset = ' + tzOff );
        system.assertEquals('CST-6:00',tzOff, 'TimzoneOffset value not correct');
        Test.stopTest();
    }
	
    @isTest
    public static void testgetTimezoneUTCOffset_Str () {
        Test.startTest();
        String res = '{"resourceSets":[{"resources":[{"timeZone":{"windowsTimeZoneId":"Central Standard Time","utcOffset":"-6:00","ianaTimeZoneId":"America/Chicago","genericName":"Central Standard Time","convertedTime":{"utcOffsetWithDst":"-6:00","timeZoneDisplayName":"Central Standard Time","timeZoneDisplayAbbr":"CST","localTime":"2022-12-06T17:23:49"},"abbreviation":"CST"},"point":{"coordinates":[32.93880463,-97.00925446]},"name":"AAA Texas Headquarters","geocodePoints":[{"type":"Point","coordinates":[32.93880463,-97.00925446]}],"entityType":"LocalBusiness","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 S Freeport Pkwy, Coppell, TX, 75019","countryRegion":"United States","adminDistrict2":null,"adminDistrict":"TX","addressLine":"1225 S Freeport Pkwy"}},{"timeZone":null,"point":{"coordinates":[32.9388,-97.009254]},"name":"1225 Freeport Pkwy, Coppell, TX 75019","geocodePoints":[{"type":"Point","coordinates":[32.9388,-97.009254]},{"type":"Point","coordinates":[32.9387271,-97.0092034]}],"entityType":"Address","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 Freeport Pkwy, Coppell, TX 75019","countryRegion":"United States","adminDistrict2":"Dallas County","adminDistrict":"TX","addressLine":"1225 Freeport Pkwy"}}]}]}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 201));
        String tstLat = '32.93880463', tstLon = '-97.00925446';
        String offsetStr = INTSADAGeoMapAPI.getTimezoneUTCOffset_Str ( tstLat, tstLon );
        //System.debug(' TimezoneOffset = ' + offsetStr );
        system.assertEquals('UTC-6:00', offsetStr, 'TimezoneOffset value not correct' );
        Test.stopTest();
    } */
    

    @isTest
    public static void testgetGoogleTimezoneAPI(){
        Test.startTest();
        String res = '{"dstOffset":0,"rawOffset":-28800,"status":"OK","timeZoneId":"America/Los_Angeles","timeZoneName":"PacificStandardTime"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        List<String> response = INTSADAGeoMapAPI.getTimeZoneFromGoogle('35.76579,-122.6474');
        system.assertEquals('America/Los_Angeles',response[0], 'Timzone should be America/Los_Angeles');
        system.assertEquals('-28800',response[1], 'Timzoneoffset should be -28800');
        Test.stopTest();
    }

    @isTest
    public static void testgetGoogleTimezoneAPINullResponse(){
        Test.startTest();
        String res = '';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        List<String> response = INTSADAGeoMapAPI.getTimeZoneFromGoogle('35.76579,-122.6474');
        Assert.isNull(response, 'Response should be null');
        Test.stopTest();
    }

    @isTest
    public static void testgetGoogleTimezoneAPINoInput(){
        Test.startTest();
        String res = '';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        List<String> response = INTSADAGeoMapAPI.getTimeZoneFromGoogle('');
        Assert.isNull(response, 'Response should be null');
        Test.stopTest();
    }

    @isTest
    public static void testgetGoogleLatLongAPI(){
        Test.startTest();
        String res = '{"results":[{"formatted_address":"1600AmphitheatrePkwy,MountainView,CA94043,USA","geometry":{"location":{"lat":37.4224428,"lng":-122.0842467}},"place_id":"ChIJeRpOeF67j4AR9ydy_PIzPuM"}],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        List<Double> response = INTSADAGeoMapAPI.getLatLongFromGoogle('xxx mall blvd');
        system.assertEquals(37.4224428,response[0], 'Latitude should be 37.4224428');
        system.assertEquals(-122.0842467,response[1], 'Longitude should be -122.0842467');
        Test.stopTest();
    }

    @isTest
    public static void testgetGoogleLatLongeAPINullResponse(){
        Test.startTest();
        String res = '';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        List<Double> response = INTSADAGeoMapAPI.getLatLongFromGoogle('xxx mall blvd');
        Assert.isNull(response, 'Response should be null');
        Test.stopTest();
    }

    @isTest
    public static void testgetGoogleLatLongeAPINoInput(){
        Test.startTest();
        String res = '';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        List<Double> response = INTSADAGeoMapAPI.getLatLongFromGoogle('');
        Assert.isNull(response, 'Response should be null');
        Test.stopTest();
    }
    
    @isTest ///AGB 4/18/2024 SFI-509 SADA API Part 3
   	public static void test_getJSONPlaceDetails(){
        Test.startTest();
        String res = '{"results": [{"address_components": [  {"long_name": "5652","short_name": "5652","types": [  "street_number"]},{"long_name": "Lankershim Boulevard","short_name": "Lankershim Blvd","types": [  "route"]},{"long_name": "North Hollywood","short_name": "NoHo","types": [  "neighborhood",  "political"]},{"long_name": "Los Angeles","short_name": "Los Angeles","types": [  "locality",  "political"]},{"long_name": "Los Angeles County","short_name": "Los Angeles County","types": [  "administrative_area_level_2",  "political"]},{"long_name": "California","short_name": "CA","types": [  "administrative_area_level_1",  "political"]},{"long_name": "United States","short_name": "US","types": [  "country",  "political"]},{"long_name": "91601","short_name": "91601","types": [  "postal_code"]}],"formatted_address": "5652 Lankershim Blvd, North Hollywood, CA 91601, USA","geometry": {"location": {"lat": 34.1738716,"lng": -118.3797732},"location_type": "RANGE_INTERPOLATED","viewport": {"northeast": {  "lat": 34.1752205802915,  "lng": -118.3784242197085},"southwest": {  "lat": 34.1725226197085,  "lng": -118.3811221802915}}},"place_id": "EjQ1NjUyIExhbmtlcnNoaW0gQmx2ZCwgTm9ydGggSG9sbHl3b29kLCBDQSA5MTYwMSwgVVNBIhsSGQoUChIJMx0Ik-iVwoARj6B3-UW2-6YQlCw","types": ["street_address"]}   ],   "status": "OK" }';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        String response=INTSADAGeoMapAPI.getJSONPlaceDetails('5620', null); //also covers getPlaceDetailsFromSADA
        system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response).status);
        Test.stopTest();
    }   
    
    @isTest //AGB 4/18/2024 SFI-509 SADA API Part 3
   	public static void test_getJSONAutosuggestAddresses(){
        Test.startTest();
        String res = '{"results": [{"address_components": [  {"long_name": "5652","short_name": "5652","types": [  "street_number"]},{"long_name": "Lankershim Boulevard","short_name": "Lankershim Blvd","types": [  "route"]},{"long_name": "North Hollywood","short_name": "NoHo","types": [  "neighborhood",  "political"]},{"long_name": "Los Angeles","short_name": "Los Angeles","types": [  "locality",  "political"]},{"long_name": "Los Angeles County","short_name": "Los Angeles County","types": [  "administrative_area_level_2",  "political"]},{"long_name": "California","short_name": "CA","types": [  "administrative_area_level_1",  "political"]},{"long_name": "United States","short_name": "US","types": [  "country",  "political"]},{"long_name": "91601","short_name": "91601","types": [  "postal_code"]}],"formatted_address": "5652 Lankershim Blvd, North Hollywood, CA 91601, USA","geometry": {"location": {"lat": 34.1738716,"lng": -118.3797732},"location_type": "RANGE_INTERPOLATED","viewport": {"northeast": {  "lat": 34.1752205802915,  "lng": -118.3784242197085},"southwest": {  "lat": 34.1725226197085,  "lng": -118.3811221802915}}},"place_id": "EjQ1NjUyIExhbmtlcnNoaW0gQmx2ZCwgTm9ydGggSG9sbHl3b29kLCBDQSA5MTYwMSwgVVNBIhsSGQoUChIJMx0Ik-iVwoARj6B3-UW2-6YQlCw","types": ["street_address"]}   ],   "status": "OK" }';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        String response=INTSADAGeoMapAPI.getJSONAutosuggestAddresses('5620', null); //also covers getAutoSuggestAddressFromSADA
        system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response).status);
        Test.stopTest();  
    }   
    
    @isTest //AGB 4/18/2024 SFI-509 SADA API Part 3
   	public static void test_getMileage(){
        Test.startTest();
        String res = '{"results": [{"address_components": [  {"long_name": "5652","short_name": "5652","types": [  "street_number"]},{"long_name": "Lankershim Boulevard","short_name": "Lankershim Blvd","types": [  "route"]},{"long_name": "North Hollywood","short_name": "NoHo","types": [  "neighborhood",  "political"]},{"long_name": "Los Angeles","short_name": "Los Angeles","types": [  "locality",  "political"]},{"long_name": "Los Angeles County","short_name": "Los Angeles County","types": [  "administrative_area_level_2",  "political"]},{"long_name": "California","short_name": "CA","types": [  "administrative_area_level_1",  "political"]},{"long_name": "United States","short_name": "US","types": [  "country",  "political"]},{"long_name": "91601","short_name": "91601","types": [  "postal_code"]}],"formatted_address": "5652 Lankershim Blvd, North Hollywood, CA 91601, USA","geometry": {"location": {"lat": 34.1738716,"lng": -118.3797732},"location_type": "RANGE_INTERPOLATED","viewport": {"northeast": {  "lat": 34.1752205802915,  "lng": -118.3784242197085},"southwest": {  "lat": 34.1725226197085,  "lng": -118.3811221802915}}},"place_id": "EjQ1NjUyIExhbmtlcnNoaW0gQmx2ZCwgTm9ydGggSG9sbHl3b29kLCBDQSA5MTYwMSwgVVNBIhsSGQoUChIJMx0Ik-iVwoARj6B3-UW2-6YQlCw","types": ["street_address"]}   ],   "status": "OK" }';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        location fromLoc = Location.newInstance(28.635308,77.22496);
        location toLoc = Location.newInstance(37.7749295,-122.4194155);
        String response=INTSADAGeoMapAPI.getMileage(fromLoc, toLoc);
        system.assertEquals('OK',INTSADAMAPSAPIResponse_wrapper.parse(response).status);
        Test.stopTest();  
    }   
    
    @isTest //AGB 4/18/2024 SFI-509 SADA API Part 3
   	public static void test_stateToStateCode(){
        Test.startTest();
		string return1 = INTSADAGeoMapAPI.stateToStateCode('Manitoba');
        string return2 = INTSADAGeoMapAPI.stateToStateCode('NY');
        string return3 = INTSADAGeoMapAPI.stateToStateCode('QQQQQ');
        system.assertEquals('MB',return1);
        system.assertEquals('NY',return2);
        system.assertEquals('QQQQQ',return3);
        Test.stopTest();  
    }   
    
   @isTest //AGB 4/18/2024 SFI-509 SADA API Part 3
    public static void test_parseSADAGeocodeResults(){        
        INTSADAGeoMapAPI.ResultSetSADA resultSetSada1 = new INTSADAGeoMapAPI.ResultSetSADA();
        INTSADAGeoMapAPI.ResultSADA resultSada1 = new INTSADAGeoMapAPI.ResultSADA();
        INTSADAGeoMapAPI.AddressSADA addrResult = new INTSADAGeoMapAPI.AddressSADA();
        resultSada1.source = 'Test source';
        INTSADAGeoMapAPI.Point oPoint = new INTSADAGeoMapAPI.Point();
        oPoint.coordinates.add(28.635308);
        oPoint.coordinates.add(77.22496);
        resultSada1.location= oPoint;
        resultSada1.name = 'Test name';
        resultSada1.formatted_address = 'Test formatted_Address';
        resultSada1.place_id = 'Test place_id';
        resultSada1.plus_code = 'Test pluscode';
        addrResult.streetNumber = 'Test StreetNumber';
        addrResult.street = 'Test Street';
        addrResult.city = 'Test';
        addrResult.state = 'NY';
        addrResult.zip = '12345';
        addrResult.country = 'USA';
        resultSada1.address = addrResult;
        resultSetSada1.results.add(resultSada1);
        INTSADAGeoMapAPI.ResponseSADA responseSada1 = new INTSADAGeoMapAPI.ResponseSADA();
        responseSada1.resultSets.add(resultSetSada1);
        
		Test.startTest();
        List<INTSADAGeoMapAPI.ResultSADA> resultList = INTSADAGeoMapAPI.parseSADAGeocodeResults(responseSada1);
        system.assertEquals('Test source', resultList[0].address.source);
        Test.stopTest();
    }
   
   /*SSFI-1111 MPatel commented Bing Methods 5/8/25 
   @isTest //AK
    public static void testGetTimezoneUTCOffset() {
       
        Double tstLat = 32.93880463; 
        Double tstLon = -97.00925446;
        
		Test.startTest();
		String res = '{"resourceSets":[{"resources":[{"timeZone":{"windowsTimeZoneId":"Central Standard Time","utcOffset":"-6:00","ianaTimeZoneId":"America/Chicago","genericName":"Central Standard Time","convertedTime":{"utcOffsetWithDst":"-6:00","timeZoneDisplayName":"Central Standard Time","timeZoneDisplayAbbr":"CST","localTime":"2022-12-06T17:23:49"},"abbreviation":"CST"},"point":{"coordinates":[32.93880463,-97.00925446]},"name":"AAA Texas Headquarters","geocodePoints":[{"type":"Point","coordinates":[32.93880463,-97.00925446]}],"entityType":"LocalBusiness","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 S Freeport Pkwy, Coppell, TX, 75019","countryRegion":"United States","adminDistrict2":null,"adminDistrict":"TX","addressLine":"1225 S Freeport Pkwy"}},{"timeZone":null,"point":{"coordinates":[32.9388,-97.009254]},"name":"1225 Freeport Pkwy, Coppell, TX 75019","geocodePoints":[{"type":"Point","coordinates":[32.9388,-97.009254]},{"type":"Point","coordinates":[32.9387271,-97.0092034]}],"entityType":"Address","address":{"postalCode":"75019","locality":"Coppell","landmark":null,"formattedAddress":"1225 Freeport Pkwy, Coppell, TX 75019","countryRegion":"United States","adminDistrict2":"Dallas County","adminDistrict":"TX","addressLine":"1225 Freeport Pkwy"}}]}]}';
		Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 201));
        String timezoneOffset = INTSADAGeoMapAPI.getTimezoneUTCOffset( tstLat, tstLon );
        System.assertNotEquals(null, timezoneOffset, 'Timezone offset should not be null');
        System.assertNotEquals('', timezoneOffset, 'Timezone offset should not be empty');
        System.assert(String.valueOf(timezoneOffset).startsWith('UTC'), 'Timezone offset should start with "UTC"');
		Test.stopTest();
    } */
}