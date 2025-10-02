/*
@Name              : INTMapSearchAddressWithAPI
@description       : Call Receive Enhancemnt - SF Services Team: Location LWC Class to invoke APIs
@author            : SF Services Team
@group             :
@last modified on  : 04-24-2023
@last modified by  : SF Services Team
 */

public without sharing class INTMapSearchAddressWithAPI {
    
    public static Map<String, Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();
    public static Set<String> poiEntities = new Set<String>();
    
    
    /**
     * @description:  Method for making callout to SADA Place details
     * @param: place Id - Place id
     * @param: session id - sesion token
     * @return: list of Maps
     */
    @AuraEnabled
    public static list< map<string,object>> getPlaceDetailsFromSADA(String placeId , String sessionId ) {
        if(String.isNotBlank(placeId)){
            String sadaresponse = INTSADAGeoMapAPI.getJSONPlaceDetails(placeId, sessionId);
            list< map<string,object>> markerList = new list< map<string,object>>();
            try {
                if(sadaresponse == null) return null ;
                sadaplacedetailsresponse SadaPlaceDetails = (sadaplacedetailsresponse)JSON.deserialize(sadaresponse, sadaplacedetailsresponse.class);
                map<string,object> markerMap = new map<string,object>();
                String streetNumber;
                String streetName;
                for(sadaplacedetailsresponse.Address_components addr : SadaPlaceDetails.address_components){
                    String typevalue = String.valueOf(addr.types);
                    String longName =  addr.long_name;
                    String shortName =  addr.short_name;
                    if(typevalue.contains('street_number')){
                        streetNumber = longName;
                    }
                    if(typevalue.contains('route')){
                        streetName = longName;
                    }
                    if(typevalue.contains('locality')){
                        markerMap.put('city',shortName);
                    }
                    if(typevalue.contains('administrative_area_level_1')){
                        markerMap.put('state',longName);
                    }
                    if(typevalue.contains('postal_code') && !typevalue.contains('postal_code_suffix')){
                        markerMap.put('zip',shortName);
                    }
                    if(typevalue.contains('country')){
                        markerMap.put('country',longName);
                    }
                }
                markerMap.put('street',streetNumber + ' ' + streetName);
                markerMap.put('title',SadaPlaceDetails.formatted_address);
                markerMap.put('description',SadaPlaceDetails.formatted_address);
                markerMap.put('name',SadaPlaceDetails.name);
                map<string,object> addressMap = new map<string,object>();
                addressMap.put('Latitude', ((Decimal)SadaPlaceDetails.geometry.location.lat).setScale(9));
                addressMap.put('Longitude', ((Decimal)SadaPlaceDetails.geometry.location.lng).setScale(9) );
                markerMap.put('location',addressMap);
                markerList.add(markerMap);
            }
            catch(TypeException e) {
                String message = e.getMessage() + ': ' + e.getStackTraceString();
                system.debug('Error occured in INTMapSearchAddressWithAPI   '+message);
            }
            return markerList;
            
        }
        else{
            return null;
        }
    }
    
    
    
    /**
     * @description:  Call Receive Enhancemnt - SF Services Team: Method for making callout Google Places
     * @param: businessUnit                String for businessUnit
     * @return                             Wrapper for InputSearch wrapper class
     */
    @AuraEnabled
    public static list< map<string,object>> getPlaceDetails(String placeId) {
        String street;
        String city;
        String state;
        String zip;
        String country;
        
        if(String.isNotBlank(placeId)){
            String sadaresponse = INTSADAGeoMapAPI.getGeoJSONAddress(placeId, '');
            system.debug('*** sadaresponse' + sadaresponse);
            
            /*Integration_Settings__c objSetting = Integration_Settings__c.getValues('Google_Place_Detail_API');
            String endPoint = objSetting.Enpoint_URL__c + 'placeid=' + EncodingUtil.urlEncode(placeId, 'UTF-8')
                + '&key=' + objSetting.API_Key__c;
            String method =  objSetting.Method__c;
            
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setMethod(method);
            req.setEndpoint(endPoint);
            req.setTimeout(120000);
            
            system.debug('****  Request'+req);
            res = h.send(req);
            String responseBody = res.getBody();
            
            system.debug('**** getPlaceDetails result'+responseBody);*/
                list< map<string,object>> markerList = new list< map<string,object>>();
            
            try {
                if(sadaresponse == null) return null ;
                Object o = JSON.deserializeUntyped(sadaresponse);
                //Object o = JSON.deserializeUntyped(responseBody);
                system.debug('o== '+o);
                sadaresponse n = (sadaresponse)JSON.deserialize(sadaresponse, sadaresponse.class);
                system.debug('n== '+n.results[0].address.city);
                // See if an object
                //Map<String, Object> m = (Map<String, Object>) o;
                //Map<String, Object> result = (Map<String, Object>)m.get('result');
                //system.debug('formatted_address '+ result.get('formatted_address'));
                //system.debug('location== '+ result.get('location'));
                
                map<string,object> markerMap = new map<string,object>();
                markerMap.put('street', n.results[0].address.streetNumber + ' ' + n.results[0].address.street);
                markerMap.put('city',(n.results[0].address.city != null ? n.results[0].address.city : n.results[0].address.suburb));
                markerMap.put('state',n.results[0].address.state);
                markerMap.put('zip',n.results[0].address.zip);
                markerMap.put('country',n.results[0].address.country);
                markerMap.put('title',n.results[0].formatted_address);
                markerMap.put('description',n.results[0].formatted_address);
                markerMap.put('name',n.results[0].name);
                
                
                map<string,object> addressMap = new map<string,object>();
                addressMap.put('Latitude', Decimal.valueOf(n.results[0].location.lat).setScale(8));
                addressMap.put('Longitude', Decimal.valueOf(n.results[0].location.lng ).setScale(8));
                markerMap.put('location',addressMap);
                
                markerList.add(markerMap);
                system.debug('markerList'+ markerList);
                
                /*List<Object> addresses = (List<Object>)result.get('address_components');
                for(Object addr : addresses){
                    system.debug('addr result== '+addr);
                    String typevalue = String.valueOf(((Map<String, Object>)addr).get('types'));
                    String longName =  String.valueOf(((Map<String, Object>)addr).get('long_name'));
                    String shortName =  String.valueOf(((Map<String, Object>)addr).get('short_name'));
                    
                    system.debug('addr typevalue== '+typevalue);
                    if(typevalue.contains('route') || typevalue.contains('street_number') || typevalue.contains('intersection')){
                        
                        if(street==null){
                            street=longName;
                            system.debug('addr street== ' +street);
                        }
                        else{
                            street=street+' '+longName;
                            system.debug('addr street else== ' +street);
                        }
                        markerMap.put('street',street);
                    }
                    
                    if(typevalue.contains('locality')){
                        city=shortName;
                        system.debug('addr city== '+shortName);
                        markerMap.put('city',city);
                    }
                    if(typevalue.contains('administrative_area_level_1')){
                        state=shortName;
                        system.debug('addr state== '+shortName);
                        markerMap.put('state',state);
                    }
                    if(typevalue.contains('postal_code') && !typevalue.contains('postal_code_suffix')){
                        zip=shortName;
                        system.debug('addr postal_code== '+shortName );
                        markerMap.put('zip',shortName);
                    }
                    if(typevalue.contains('country')){
                        country=shortName;
                        system.debug('addr country== '+shortName );
                        markerMap.put('country',shortName);
                    }
                    
                }
                Map<String, Object> geometry = (Map<String, Object>)result.get('geometry');
                
                Map<String, Object> location = (Map<String, Object>)geometry.get('location');
                
                system.debug('location== '+location);
                markerMap.put('title',result.get('formatted_address'));
                markerMap.put('description',result.get('formatted_address'));
                
                markerMap.put('name',result.get('name'));
                
                map<string,object> addressMap = new map<string,object>();
                addressMap.put('Latitude', ((Decimal)location.get('lat')).setScale(9));
                addressMap.put('Longitude', ((Decimal)location.get('lng')).setScale(9) );
                markerMap.put('location',addressMap);
                markerList.add(markerMap);  */
            } catch(TypeException e) {
                String message = e.getMessage() + ': ' + e.getStackTraceString();
                system.debug('Error occured in INTMapSearchAddressWithAPI   '+message);
            }
            return markerList;
            
        }
        return null;
    }
    
    ///// Start New Method here  JC, FM 3/28 /////
    
    @AuraEnabled(cacheable=false)
    public static String getSessionToken(){
        system.debug('getsession *** ' + UUID.randomUUID().toString());
        return UUID.randomUUID().toString();
    }
    
    @AuraEnabled
    Public Static List<AutoSuggestionWrapper> getAutoSuggestAddressFromSADA(String searchString, String sessionToken){
        searchString = searchString.replaceAll(' ', '%20');//To handle blank spaces
        searchString = searchString.replaceAll('&', 'and');
        ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
        Integer mapLimit = (Integer)cs.Map_Search_Display_limit__c;
        try{
            if(String.isNotBlank(searchString)){
                List<AutoSuggestionWrapper> suggestions=new List<AutoSuggestionWrapper>();
                String sadaAutoSuggestResponse = INTSADAGeoMapAPI.getJSONAutosuggestAddresses(searchString, sessionToken);
                Boolean isLatLongReq = FALSE;
                String areaType;
                if(searchString != '' && sadaAutoSuggestResponse != null){
                    if(searchString.contains(',') && searchString.contains('-') && searchString.split(',').size() == 2 && !searchString.split(',')[0].isAlpha() && !searchString.split(',')[1].isAlpha()){
                        isLatLongReq = TRUE;
                    }
                    Object sadaAutoSuggestResponseObject = JSON.deserializeUntyped(sadaAutoSuggestResponse);
                    Map<String, Object> sadaAutoSuggestResponseMap = (Map<String, Object>) sadaAutoSuggestResponseObject;
                    List<Object> sadaAutoSuggestResponseResults = (List<Object>)sadaAutoSuggestResponseMap.get('predictions');
                    Integer i=0;
                    for(Object result : sadaAutoSuggestResponseResults){
                        if(i < mapLimit){
                            String formattedAddress = String.valueOf(((Map<String, Object>)result).get('description'));
                            string CompleteAddress = '';
                            CompleteAddress = formattedAddress.replaceAll(',', ' ');
                            String placeId = String.valueOf(((Map<String, Object>)result).get('place_id'));
                            Map<String,Object> location = (Map<String, Object>)(((Map<String, Object>)result).get('structured_formatting'));
                            String locName = String.valueOf(location.get('main_text'));
                            Decimal lot;
                            Decimal longt;
                            suggestions.add(new AutoSuggestionWrapper(CompleteAddress,locName,placeId, lot , longt));
                            i++;
                        }
                    }
                    return suggestions;
                }
            }
            
        }catch(TypeException e) {
            String message = e.getMessage() + ': ' + e.getStackTraceString();
            system.debug('Error occured in INTMapSearchAddressWithAPI   '+message);
        }
        return null;
    }
    
    
    @AuraEnabled
    Public Static list<SuggestionWrapper> getAddress(String searchString){
        searchString = searchString.replaceAll(' ', '%20');//To handle blank spaces
        searchString = searchString.replaceAll('&', 'and');
        /*Integration_Settings__c objSetting = Integration_Settings__c.getValues('Google_Search_API');
        String endPoint = objSetting.Enpoint_URL__c + searchString +'&key='+ objSetting.API_Key__c;
        String method =  objSetting.Method__c;*/
            
        ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
        Integer mapLimit = (Integer)cs.Map_Search_Display_limit__c;
        
        try{
            if(String.isNotBlank(searchString)){
                List<SuggestionWrapper> suggestions=new List<SuggestionWrapper>();
                String sadaResponse = INTSADAGeoMapAPI.getGeoJSONAddress('', searchString);
                //String sadaResponse = INTSADAGeoMapAPI.getAutosuggestAddresses(searchString);
                system.debug('sadaResponse' + sadaResponse);
                
                /*searchString = EncodingUtil.urlEncode(searchString, 'UTF-8');
                Http http = new Http();
                
                HttpRequest Request = new HttpRequest();
                Request.setMethod(method);
                Request.setEndPoint(endPoint);
                system.debug('****  Request'+Request);
                HttpResponse Response = http.send(Request);
                String responseBody = Response.getBody();
                system.debug('****  Response'+responseBody);*/
                    
                //if(Response.getStatusCode()==200){
                    Boolean isLatLongReq = FALSE;
                    String areaType;
                    
                    if(searchString != '' && sadaResponse != null){
                        
                        if(searchString.contains(',') && searchString.contains('-') && searchString.split(',').size() == 2 && !searchString.split(',')[0].isAlpha() && !searchString.split(',')[1].isAlpha()){
                            isLatLongReq = TRUE;
                        }
                        Object o = JSON.deserializeUntyped(sadaResponse);
                        system.debug('o== '+o);
                        // See if an object
                        Map<String, Object> m = (Map<String, Object>) o;
                        List<Object> results = (List<Object>)m.get('results');
                        system.debug('results== '+results);
                        Integer i=0;
                        for(Object result : results){
                            system.debug('****  result'+result);
                            if(i < mapLimit){
                                String formattedAddress = String.valueOf(((Map<String, Object>)result).get('formatted_address'));
                                string CompleteAddress = '';
                                CompleteAddress = formattedAddress.replaceAll(',', ' ');
                                String locName = '';
                                locName = String.valueOf(((Map<String, Object>)result).get('name'));
                                String placeId = String.valueOf(((Map<String, Object>)result).get('place_id'));
                                
                                if(((Map<String, Object>)result).get('types') != null && isLatLongReq){
                                    areaType = String.valueOf(((Map<String, Object>)result).get('types'));
                                    system.debug('***Types******' + areaType.contains('route'));
                                    if(areaType != '' && areaType.contains('route')){
                                        system.debug('**** contains route' + isLatLongReq);
                                        suggestions.add(new SuggestionWrapper(CompleteAddress,locName,placeId));
                                    }
                                }else{
                                    system.debug('*** Not Lat Lang Req******' + isLatLongReq);
                                    suggestions.add(new SuggestionWrapper(CompleteAddress,locName,placeId));
                                }
                                
                                
                                i++;
                            }
                        }
                        return suggestions;
                    }
                    
                }
            } catch(TypeException e) {
                String message = e.getMessage() + ': ' + e.getStackTraceString();
                system.debug('Error occured in INTMapSearchAddressWithAPI   '+message);
            }
            return null;
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method for getting Mile markers location records
         * @param: highway,  mileMarker,  state                String for parameters
         * @return                                             Objects Location
         */
        @AuraEnabled
        public static Schema.Location getMileMarker(String highway, String mileMarker, String state){
            Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Mile Marker').getRecordTypeId();
            Schema.Location mileMarkerLocation = [SELECT Id,Highway__c,Mile_Marker__c,State__c, GeoLocation__latitude__s, 
                                                    GeoLocation__longitude__s, Landmark__c, County__c
                                                    FROM Location 
                                                    WHERE Highway__c =: highway 
                                                    AND Mile_Marker__c =: mileMarker 
                                                    AND State__c =: state 
                                                    AND recordTypeId =: recordTypeId
                                                    LIMIT 1];
            
            return mileMarkerLocation;
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method for getting POI locations based on location
         * @param: lng, lat                String for lng, String lat
         * @return                                             Objects Location
         */
        @AuraEnabled(cacheable=true)
        public static List<Schema.Location> getPOILocation(String latitude, String longitude){
            system.debug('latitude=== '+latitude);
            system.debug('longitude=== '+longitude);
            
            Id recordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('ACE POI').getRecordTypeId();
            
            ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
            Decimal miles = cs.ACE_POI_Search_Radius_mile__c;
            
            List<Schema.Location> poiLocation = [SELECT Id, Name, State__c, GeoLocation__latitude__s, GeoLocation__longitude__s, 
                                                    Landmark__c, County__c, City__c, Street_Address__c,
                                                    DISTANCE(GeoLocation__c,GEOLOCATION( :decimal.valueOf(latitude), :decimal.valueOf(longitude)),'mi')
                                                    FROM Location 
                                                    WHERE recordTypeId =: recordTypeId
                                                    AND DISTANCE(GeoLocation__c,GEOLOCATION( :decimal.valueOf(latitude), :decimal.valueOf(longitude)),'mi') <: miles
                                                    ORDER BY DISTANCE(GeoLocation__c, GEOLOCATION( :decimal.valueOf(latitude), :decimal.valueOf(longitude)), 'mi')];
            system.debug('poiLocation=== '+poiLocation);
            
            return poiLocation;
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method for getting POI locations based on location
         * @param: recId                                        String
         * @return                                             Objects Location
         */
        @AuraEnabled
        public static List<Schema.Location> getPOIBasedOnSelectedAddress(Id recId){
            List<Schema.Location> poiRecord = [SELECT Id, Name, State__c, Street_Address__c, City__c,
                                            GeoLocation__latitude__s, GeoLocation__longitude__s
                                            FROM Location 
                                            WHERE Id=: recId];
            system.debug('poiRecord=== '+poiRecord);
            
            return poiRecord;
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method for making callout Google Geocode API to get Map markers passing latitude and longitude
         * @param: lng, lat                String for lng, String lat
         * @return                         Map for Objects
         */
        @AuraEnabled
        public static List<Map<String,Object>> getgeoCodeDetails(String lng, String lat)
        {
            if(String.isNotBlank(lat) && String.isNotBlank(lng) ){
                String latlong = lat + ',' +lng;
                latlong.deleteWhitespace();
                list< map<string,object>> markerList = new list< map<string,object>>();
                
                String sadalatlongresponse = INTSADAGeoMapAPI.getGeoJSONAddress('',latlong);
                system.debug('sadalatlongresponse'+sadalatlongresponse);
                if(sadalatlongresponse == null) return markerList ;
                Object o = JSON.deserializeUntyped(sadalatlongresponse);
                
                system.debug('obj'+o);
                // See if an object
                Map<String, Object> m = (Map<String, Object>) o;
                List<Object> result = (List<Object>)m.get('results');
                system.debug('result++++'+result);
                map<string,object> markerMap = new map<string,object>();
                for(object objResult: result)
                {
                    system.debug('for');
                    String typevalue = String.valueOf(((Map<String, Object>)objResult).get('types'));
                    String premiseValue = 'premise';
                    if(typevalue.contains(premiseValue))
                    {
                        markerMap.put('title',((Map<String, Object>)objResult).get('formatted_address'));
                        markerMap.put('description',((Map<String, Object>)objResult).get('formatted_address'));
                        markerMap.put('name',((Map<String, Object>)objResult).get('formatted_address'));
                    }
                }
                
                map<string,object> addressMap = new map<string,object>();
                addressMap.put('Latitude',lat);
                addressMap.put('Longitude',lng);
                markerMap.put('location',addressMap);
                markerList.add(markerMap);
                system.debug('markerList'+markerList);
                return markerList;
                /*Integration_Settings__c objSetting = Integration_Settings__c.getValues('Google_Geocoding_API');
                String endPoint =  objSetting.Enpoint_URL__c
                    + 'latlng='+ lat +','+ lng
                    + '&key=' + objSetting.API_Key__c;
                String method =  objSetting.Method__c;
                
                list< map<string,object>> markerList = new list< map<string,object>>();
                
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();
                req.setMethod(method);
                req.setEndpoint(endPoint);
                req.setTimeout(120000);
                try {
                    res = h.send(req);
                    String responseBody = res.getBody();
                    system.debug('result'+responseBody);
                    Object o = JSON.deserializeUntyped(responseBody);
                    system.debug('obj'+o);
                    // See if an object
                    Map<String, Object> m = (Map<String, Object>) o;
                    List<Object> result = (List<Object>)m.get('results');
                    system.debug('result++++'+result);
                    map<string,object> markerMap = new map<string,object>();
                    for(object objResult: result)
                    {
                        system.debug('for');
                        String typevalue = String.valueOf(((Map<String, Object>)objResult).get('types'));
                        String premiseValue = 'premise';
                        if(typevalue.contains(premiseValue))
                        {
                            markerMap.put('title',((Map<String, Object>)objResult).get('formatted_address'));
                            markerMap.put('description',((Map<String, Object>)objResult).get('formatted_address'));
                            markerMap.put('name',((Map<String, Object>)objResult).get('formatted_address'));
                        }
                    }
                    
                    map<string,object> addressMap = new map<string,object>();
                    addressMap.put('Latitude',lat);
                    addressMap.put('Longitude',lng);
                    markerMap.put('location',addressMap);
                    markerList.add(markerMap);
                } catch(TypeException e) {
                    String message = e.getMessage() + ': ' + e.getStackTraceString();
                    system.debug('Error occured in INTMapSearchAddressWithAPI   '+message);
                }
                system.debug('markerList'+markerList);
                return markerList;  */
            }
            return null;
            
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method to get Custom Metadata Values for ARR_Call_Receive_LWC_UI_Configuration__c
         * @return                          Object
         */
        @AuraEnabled(cacheable=true)
        public static Decimal getCustomSettings(){
            
            ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
            Decimal MapUIZoomLevel = cs.Map_UI_Zoom_Level__c;
            return MapUIZoomLevel;
            
        }
        
        public class AutoSuggestionWrapper{
            @AuraEnabled
            public String AddComplete{get;set;}
            @AuraEnabled
            public String locName{get;set;}
            @AuraEnabled
            public String placeId{get;set;}
            @AuraEnabled
            public String latitude{get;set;}
            @AuraEnabled
            public String longitude{get;set;}
            
            public AutoSuggestionWrapper(string AddComplete, string locName, String placeId, Decimal latitude, Decimal longitude){
                this.AddComplete = AddComplete;
                this.locName = locName ;
                this.placeId = placeId;
                this.latitude = String.valueOf(latitude);
                this.longitude = String.valueOf(longitude);
            }
        }
        
        public class SuggestionWrapper{
            @AuraEnabled
            public String AddComplete{get;set;}
            @AuraEnabled
            public String locName{get;set;}
            @AuraEnabled
            public String placeId{get;set;}
            
            public SuggestionWrapper(string AddComplete, string locName, String placeId){
                this.AddComplete = AddComplete;
                this.locName = locName ;
                this.placeId = placeId;
            }
        }
        
        
        public class Location{
            @AuraEnabled
            public String icon{get;set;}
            @AuraEnabled
            public String title{get;set;}
            @AuraEnabled
            public String description{get;set;}
            @AuraEnabled
            public GeoLocation location{get;set;}
        }
        
        public class GeoLocation{
            @AuraEnabled
            public String Street{get;set;}
            @AuraEnabled
            public String PostalCode{get;set;}
            @AuraEnabled
            public String City{get;set;}
            @AuraEnabled
            public String State{get;set;}
            @AuraEnabled
            public String Country{get;set;}
        }
        
        // public static JsonParse parseSuggestion(String json) {
            //     return (JsonParse) System.JSON.deserialize(json, JsonParse.class);
        // }
        
        
        
        @AuraEnabled(cacheable=true)
        public static String getPlaceId(Double latitude, Double longitude) {
            String baseUrl = 'callout:GoogleMapsAPI/maps/api/geocode/json';
            Integration_Settings__c objSetting = mapIntSettings.get('GETGoogle_Directions_API');
            String key = objSetting.API_Key__c;
            // String completeUrl = baseUrl + '?latlng=' + latitude + ',' + longitude + '&key=' + '';
            // String completeUrl ='https://maps.googleapis.com/maps/api/geocode/json?latlng=14.449745062254772,80.00027184070102&key='+key;
            String completeUrl ='https://maps.googleapis.com/maps/api/geocode/json?latlng='+latitude+','+longitude+'&key='+key;
            
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(completeUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            HttpResponse resp;
            try {
                Http http = new Http();
                resp = http.send(req);
                
                if (resp.getStatusCode() != 200) {
                    throw new CalloutException('Error calling Google Maps API: ' + resp.getStatus() + ' - ' + resp.getBody());
                }
                
                // Parse JSON response
                Map<String, Object> responseObj = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                if (responseObj.containsKey('status') && responseObj.get('status') == 'OK') {
                    List<Object> results = (List<Object>) responseObj.get('results');
                    if (!results.isEmpty()) {
                        Map<String, Object> firstResult = (Map<String, Object>) results[0];
                        if (firstResult.containsKey('place_id')) {
                            return (String) firstResult.get('place_id');
                        }
                    }
                }
                return 'No Place ID found for given coordinates.';
            } catch (Exception e) {
                return 'Error: ' + e.getMessage();
            }
        }
        
        @AuraEnabled(cacheable=true)
        public static String getGoogleDirectionsAPIKey() {
            // Fetch the custom setting record
            Integration_Settings__c objSetting = mapIntSettings.get('GETGoogle_Directions_API');
            // Return the API key
            return objSetting.API_Key__c;
        }
        
        @AuraEnabled
        public static List<Account> getDestinationLocationCenters(Id caseId, String latitude,String longitude, String reason){
            return INTTowTabController.getAarMprDetails(caseId, latitude, longitude, reason);
        }
    
    @AuraEnabled
    public static void updateCaseField(Id caseId, String locationType) {
        try {
            // Fetch the Case record
            List<Case> casesToUpdate = [
                SELECT Id, Vehicle_Location_Types__c, Priority, ACG_Priority_Code__c 
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            
            if (!casesToUpdate.isEmpty()) {
                Case caseRecord = casesToUpdate[0];
                caseRecord.Vehicle_Location_Types__c = locationType;
                
                if (locationType == 'On the Interstate / Highway') {
                    caseRecord.Priority = 'Critical';
                    caseRecord.ACG_Priority_Code__c = 'P7-Freeway/Highway Call';
                }
                
                update caseRecord;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Case: ' + e.getMessage());
        }
    }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Method for updating Cse with POI address selected
         * @param:  Id                Id for caseId, Id for  locationId
         */
        // @AuraEnabled
        @AuraEnabled(cacheable=true)
        public static List<Case> updateCaseRecord(Id caseId, Id locationId){
            List<Case> caseListToUpdate = new List<Case>();
            system.debug('caseId'+caseId);
            system.debug('locationId'+locationId);
            Id ACEPOIRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('ACE POI').getRecordTypeId();
            Id mileMarkerRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Mile Marker').getRecordTypeId();
            List<Schema.Location> getLocationRecord = [SELECT Id, Name, State__c, Street_Address__c, Landmark__c,
                                            GeoLocation__latitude__s, GeoLocation__longitude__s, City__c,
                                            Country__c, recordTypeId, Highway__c, Mile_Marker__c,
                                            County__c, Zip__c
                                            FROM Location 
                                            WHERE Id=: locationId];
            Case cs = [SELECT Id, ACG_Vehicle_Location_Address__c, POI_Mile_Marker_Location__r.Highway__c,
                    POI_Mile_Marker_Location__r.Mile_Marker__c, POI_Mile_Marker_Location__r.State__c,
                    POI_Mile_Marker_Location__r.County__c,Landmark__c, POI_Mile_Marker_Location__r.GeoLocation__latitude__s,
                    POI_Mile_Marker_Location__r.GeoLocation__longitude__s
                    FROM Case
                    WHERE Id =: caseId];
            system.debug('cs== '+cs);
            for(Schema.Location loc : getLocationRecord){
                Case c = new Case();
                c.Id = caseId;
                c.POI_Mile_Marker_Location__c = loc.Id;
                c.Landmark__c = getLocationRecord[0].Landmark__c;
                c.Vehicle_Geolocation__latitude__s = loc.GeoLocation__latitude__s;
                c.Vehicle_Geolocation__longitude__s = loc.GeoLocation__longitude__s;
                if(loc.recordTypeId == ACEPOIRecordTypeId){
                    c.Vehicle_Location_State__c = loc.State__c;
                    c.Vehicle_Location_Street__c = loc.Street_Address__c;
                    c.Vehicle_Location_Country__c = loc.Country__c;
                    c.Vehicle_Location_City__c = loc.City__c;
                    c.Vehicle_Location_Postal_Code__c = loc.Zip__c;
                    c.ACG_Vehicle_Location_Address__c = loc.Street_Address__c;
                    if(loc.City__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.City__c;
                    }
                    if(loc.State__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.State__c;
                    }
                    if(loc.Country__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.Country__c;
                    }
                    if(loc.Zip__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.Zip__c;
                    }
                }
                if(loc.recordTypeId == mileMarkerRecordTypeId){
                    c.Vehicle_Location_State__c = loc.State__c;
                    c.Vehicle_Location_Country__c = loc.Country__c;
                    c.Vehicle_Location_City__c = '';
                    c.Vehicle_Location_Postal_Code__c = '';
                    c.Vehicle_Location_Street__c = 'highway# ' + loc.Highway__c + ', mile marker ' +
                        loc.Mile_Marker__c ;
                    c.ACG_Vehicle_Location_Address__c = 'highway# ' + loc.Highway__c + ', mile marker ' +
                        loc.Mile_Marker__c ;
                    if(loc.County__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.County__c;
                    }
                    if(loc.State__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.State__c;
                    }
                    if(loc.Country__c != null){
                        c.ACG_Vehicle_Location_Address__c = c.ACG_Vehicle_Location_Address__c + ', ' + loc.Country__c;
                    }
                }
                caseListToUpdate.add(c);
            }
            
            if(!caseListToUpdate.isEmpty()){
                update caseListToUpdate;
            }
            return caseListToUpdate;
        }
        
        
        
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Get case details
         * @param: caseId                            Id caseId
         * @return                                   List for Objects
         */
        @AuraEnabled
        public static List<Case> getCaseDetails(Id caseId){
            List<Case> csRecord = [SELECT Id, ACG_Vehicle_Location_Address__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, POI_Mile_Marker_Location__c, POI_Mile_Marker_Location__r.Highway__c,
                                POI_Mile_Marker_Location__r.Mile_Marker__c, POI_Mile_Marker_Location__r.State__c,
                                POI_Mile_Marker_Location__r.County__c,Landmark__c, POI_Mile_Marker_Location__r.GeoLocation__latitude__s,
                                POI_Mile_Marker_Location__r.GeoLocation__longitude__s
                                FROM Case
                                WHERE Id =: caseId];
            system.debug('csRecord=== '+csRecord);
            
            return csRecord;
        }
        
        /**
         * @description: Call Receive Enhancemnt - SF Services Team: Update casse details with breakdown location
         * @param: caseId, Address                Id caseId, String Address
         * @return                                List for Objects
         */
        @AuraEnabled
        public static List<Case> updateCaseBasedonAddressValue(Id caseId, String Address, String addrStreet, String addrCity, String addrState, String addrZip, String addrCountry, String latitude, String longitude, String landmark){
            List<Case> caseToBeUpdated = new List<Case>();
            List<Case> csRecord = [SELECT Id, ACG_Vehicle_Location_Address__c, Landmark__c, POI_Mile_Marker_Location__c,
                                Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c, 
                                Vehicle_Location_Postal_Code__c, Vehicle_Location_Country__c
                                FROM Case
                                WHERE Id =: caseId];
            Map<String, String> stateAbbreviations = new Map<String, String>{
                'Alabama' => 'AL',
                'Alaska' => 'AK',
                'Arizona' => 'AZ',
                'Arkansas' => 'AR',
                'California' => 'CA',
                'Colorado' => 'CO',
                'Connecticut' => 'CT',
                'Delaware' => 'DE',
                'Florida' => 'FL',
                'Georgia' => 'GA',
                'Hawaii' => 'HI',
                'Idaho' => 'ID',
                'Illinois' => 'IL',
                'Indiana' => 'IN',
                'Iowa' => 'IA',
                'Kansas' => 'KS',
                'Kentucky' => 'KY',
                'Louisiana' => 'LA',
                'Maine' => 'ME',
                'Maryland' => 'MD',
                'Massachusetts' => 'MA',
                'Michigan' => 'MI',
                'Minnesota' => 'MN',
                'Mississippi' => 'MS',
                'Missouri' => 'MO',
                'Montana' => 'MT',
                'Nebraska' => 'NE',
                'Nevada' => 'NV',
                'New Hampshire' => 'NH',
                'New Jersey' => 'NJ',
                'New Mexico' => 'NM',
                'New York' => 'NY',
                'North Carolina' => 'NC',
                'North Dakota' => 'ND',
                'Ohio' => 'OH',
                'Oklahoma' => 'OK',
                'Oregon' => 'OR',
                'Pennsylvania' => 'PA',
                'Rhode Island' => 'RI',
                'South Carolina' => 'SC',
                'South Dakota' => 'SD',
                'Tennessee' => 'TN',
                'Texas' => 'TX',
                'Utah' => 'UT',
                'Vermont' => 'VT',
                'Virginia' => 'VA',
                'Washington' => 'WA',
                'West Virginia' => 'WV',
                'Wisconsin' => 'WI',
                'Wyoming' => 'WY'
            };
            for(Case c : csRecord){
                
                String[] addressArr = Address.split(',');
                system.debug('addressArr== '+addressArr);
                //system.debug('addressArr== '+addressArr[2]);
                //system.debug('addressArr== '+addressArr[3]);
                //String[] splitState = addressArr[2].split(' ');
                //system.debug('splitState== '+ splitState[1]);
                c.ACG_Vehicle_Location_Address__c = Address;
                c.Vehicle_Location_Street__c = addressArr[0];
                c.Vehicle_Location_City__c = addrCity;
                c.Vehicle_Location_State__c = (addrState.length() > 2) ? stateAbbreviations.get(addrState) : addrState;
                //c.Vehicle_Location_State__c = addrState;
                //c.Vehicle_Location_State__c = splitState[1];
                c.Vehicle_Location_Postal_Code__c = addrZip;
                
                if(addrCountry != null && addrCountry.trim() == 'USA') {
                    c.Vehicle_Location_Country__c = 'United States';
                }
                else {
                    c.Vehicle_Location_Country__c = addrCountry;
                }
                //c.Vehicle_Location_Country__c = (addrCountry.trim() == 'USA' ? 'United States' : addrCountry.trim());
                //c.Vehicle_Location_Country__c = addressArr[3];
                c.Landmark__c = landmark;
                c.POI_Mile_Marker_Location__c = null;
                
                
                c.Vehicle_Geolocation__latitude__s = Decimal.valueOf(latitude).setScale(8) ;
                c.Vehicle_Geolocation__longitude__s = Decimal.valueOf(longitude).setScale(8) ;
                caseToBeUpdated.add(c);
                
                
            }
            
            if(!caseToBeUpdated.isEmpty()){
                update caseToBeUpdated;
            }
            
            return csRecord;
            
        }
        
        @AuraEnabled
        public static List<Case> updateCaseBasedontowAddressValue(Id caseId, String Address,
        String addrStreet, String addrCity, String addrState,
        String addrZip, String addrCountry, String latitude, String longitude,
        String landmark,Decimal howManyPeopleForTow){
            List<Case> caseToBeUpdated = new List<Case>();
            List<Case> csRecord = [SELECT Id, ACG_Tow_Destination_Address__c, Landmark__c, POI_Mile_Marker_Location__c,
                                Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, 
                                Tow_Destination_Postal_Code__c, Tow_Destination_Country__c
                                FROM Case
                                WHERE Id =: caseId];
            Map<String, String> stateAbbreviations = new Map<String, String>{
                'Alabama' => 'AL',
                'Alaska' => 'AK',
                'Arizona' => 'AZ',
                'Arkansas' => 'AR',
                'California' => 'CA',
                'Colorado' => 'CO',
                'Connecticut' => 'CT',
                'Delaware' => 'DE',
                'Florida' => 'FL',
                'Georgia' => 'GA',
                'Hawaii' => 'HI',
                'Idaho' => 'ID',
                'Illinois' => 'IL',
                'Indiana' => 'IN',
                'Iowa' => 'IA',
                'Kansas' => 'KS',
                'Kentucky' => 'KY',
                'Louisiana' => 'LA',
                'Maine' => 'ME',
                'Maryland' => 'MD',
                'Massachusetts' => 'MA',
                'Michigan' => 'MI',
                'Minnesota' => 'MN',
                'Mississippi' => 'MS',
                'Missouri' => 'MO',
                'Montana' => 'MT',
                'Nebraska' => 'NE',
                'Nevada' => 'NV',
                'New Hampshire' => 'NH',
                'New Jersey' => 'NJ',
                'New Mexico' => 'NM',
                'New York' => 'NY',
                'North Carolina' => 'NC',
                'North Dakota' => 'ND',
                'Ohio' => 'OH',
                'Oklahoma' => 'OK',
                'Oregon' => 'OR',
                'Pennsylvania' => 'PA',
                'Rhode Island' => 'RI',
                'South Carolina' => 'SC',
                'South Dakota' => 'SD',
                'Tennessee' => 'TN',
                'Texas' => 'TX',
                'Utah' => 'UT',
                'Vermont' => 'VT',
                'Virginia' => 'VA',
                'Washington' => 'WA',
                'West Virginia' => 'WV',
                'Wisconsin' => 'WI',
                'Wyoming' => 'WY'
            };
            for(Case c : csRecord){
                
                String[] addressArr = Address.split(',');
                system.debug('addressArr== '+addressArr);
                //system.debug('addressArr== '+addressArr[2]);
                //system.debug('addressArr== '+addressArr[3]);
                //String[] splitState = addressArr[2].split(' ');
                //system.debug('splitState== '+ splitState[1]);
                c.ACG_Tow_Destination_Address__c = Address;
                c.Tow_Destination_Street__c = addressArr[0];
                c.Tow_Destination_City__c = addrCity;
                if(addrState != null && addrState.trim() != ''){
                    c.Tow_Destination_State__c = (addrState.length() > 2) ? stateAbbreviations.get(addrState) : addrState;
                }
                //c.Vehicle_Location_State__c = addrState;
                //c.Vehicle_Location_State__c = splitState[1];
                c.Tow_Destination_Postal_Code__c = addrZip;
                
                if(addrCountry != null && addrCountry.trim() == 'USA') {
                    c.Tow_Destination_Country__c = 'United States';
                }
                else {
                    c.Tow_Destination_Country__c = addrCountry;
                }
                //c.Vehicle_Location_Country__c = (addrCountry.trim() == 'USA' ? 'United States' : addrCountry.trim());
                //c.Vehicle_Location_Country__c = addressArr[3];
                c.Landmark__c = landmark;
                c.Number_of_passengers__c = howManyPeopleForTow;
                c.POI_Mile_Marker_Location__c = null;
                
                
                c.Tow_Geolocation__Latitude__s = Decimal.valueOf(latitude).setScale(8) ;
                c.Tow_Geolocation__Longitude__s = Decimal.valueOf(longitude).setScale(8) ;
                caseToBeUpdated.add(c);
                
                
            }
            
            if(!caseToBeUpdated.isEmpty()){
                update caseToBeUpdated;
            }
            
            return csRecord;
            
        }
        
        @AuraEnabled
        public static Decimal getCaseTowMileage(Id caseId, Double latitude, Double longitude) {
            // Query the case using the case Id
            Case caseRecord = [SELECT Vehicle_Geolocation__Latitude__s,Vehicle_Geolocation__Longitude__s FROM Case WHERE Id = :caseId LIMIT 1];
            Double distanceInMiles = calculateDistanceMiles((Double)caseRecord.Vehicle_Geolocation__Latitude__s,
            (Double) caseRecord.Vehicle_Geolocation__Longitude__s,(Double)latitude,(Double)longitude);
            return distanceInMiles;
            
            // Return the Tow_Mileage__c value
            // return caseRecord.Tow_Mileage__c;
        }
        
        public static Double calculateDistanceMiles(Double latitude1, Double longitude1, Double latitude2, Double longitude2) {
            // Radius of Earth in miles
            Double R = 3958.8;
            
            // Convert degrees to radians manually
            Double lat1Rad = latitude1 * Math.PI / 180;
            Double lon1Rad = longitude1 * Math.PI / 180;
            Double lat2Rad = latitude2 * Math.PI / 180;
            Double lon2Rad = longitude2 * Math.PI / 180;
            
            // Haversine formula
            Double dLat = lat2Rad - lat1Rad;
            Double dLon = lon2Rad - lon1Rad;
            
            Double a = Math.pow(Math.sin(dLat / 2), 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.pow(Math.sin(dLon / 2), 2);
            
            Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            
            // Compute distance in miles
            Double distance = R * c;
            
            return Math.round(distance * 100) / 100.0; // Distance in miles
        }
        
        
        @AuraEnabled(cacheable=true)
        public static Boolean getCustomSettingsForAPISelection(){
            //return FSL_Settings__c.getValues('API_Callout_Map_Search').value__c == 'google';
            
            ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
            String APICallout = cs.API_Callout_Map_Search__c;
            if(cs.API_Callout_Map_Search__c=='google')
                return true;
            
            return false;
        }
        
        @AuraEnabled
        public static Double getDistanceInMilesUsingAPI(String origin_Lat, String origin_Long, String dest_Lat, String dest_Long){
            INTDistanceMatrixAPIResponseWrapper response = new INTDistanceMatrixAPIResponseWrapper();
            response = getDistanceMatrixDetails(origin_Lat,origin_Long,dest_Lat,dest_Long,'imperial');
            String distance = response?.rows[0]?.elements[0]?.distance?.text;
            Double dist_Miles = 0;
            
            if(distance != NULL){
                distance = distance.replace(',','');
                if(distance.containsIgnoreCase('mi')){
                    dist_Miles = Double.valueOf(distance.replace('mi',''));
                }
                if(distance.containsIgnoreCase('ft')){
                    dist_Miles = 0.000189394 *  Double.valueOf(distance.replace('ft',''));
                }
            }
            return dist_Miles;
        }
        
        /***
         * Method name            : getDistanceMatrixDetails
         * Description            : Returns a response in string for the selected lat longs. For miles send unitSystem as "imperial" and for kilometers send unitSystem as "metrics"
         * Return Type            : String
         * @Param strPlaceid      : Lat longs of the Selected addresses from the component
         */
        @AuraEnabled(cacheable=true)
        public static INTDistanceMatrixAPIResponseWrapper getDistanceMatrixDetails(String origLat, String origLong, String destLat, String destLong, String unitSystem){
            if(String.isNotEmpty(origLat) && String.isNotEmpty(origLong) && String.isNotEmpty(destLat) && String.isNotEmpty(destLong)){
                INTDistanceMatrixAPIResponseWrapper resp = new INTDistanceMatrixAPIResponseWrapper();
                Integration_Settings__c objSetting=Integration_Settings__c.getValues('GETDistance_Matrix_API');
                objSetting.Enpoint_URL__c += 'key=' + objSetting.API_Key__c+'&origins='+origLat+','+origLong+'&destinations='+destLat+','+destLong+'&units='+unitSystem;
                HttpRequest  objRequest = new HttpRequest();
                HttpResponse objResponse = new HttpResponse();
                try {
                    objRequest = IntegrationUtil.preparerequest(objSetting);
                    objResponse = IntegrationUtil.makecallout(objRequest);
                    string strResponse = objResponse.getbody();
                    resp = INTDistanceMatrixAPIResponseWrapper.parse(objResponse.getbody());
                    system.debug('resp== '+resp);
                    if(resp?.status==ACG_ConstantsClass.OK){
                        //FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',false,'',null);
                        return resp;
                    } else {
                        //FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',true,system.label.INTGOOGLE_DISTMAT_INVALIDREQ,null);
                    }
                } catch (Exception e){
                    //FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',true,e.getMessage(),null);
                    
                }
            }
            return null;
        }
        /* SSFI-545 MPatel Commented out getGeoJSONAddress  - 4/7/25 Updated
        @AuraEnabled
        public static string getGeoJSONAddress(String strplaceId, String address) {
            return getAddressFromBing(string.isNotBlank(address) ? address : strplaceId);
        }*/
        
        /**
         * @description:  Call Receive Enhancemnt - SF Services Team: Method for making callout to Bing API
         * @param: address                     String for address
         * @return                             string
         */
        /* private static string getAddressFromBing(String address){
            Integration_Settings__c objSetting = mapIntSettings.get('GETBING_API_GEOCODE');
            Map<String,String> mapHeaderKeyToValue = IntegrationUtil.getHeaderValue(objSetting.Header_Value__c);
            String key = mapHeaderKeyToValue.get('Authorization');
            String completeUrl = objSetting.Enpoint_URL__c;
            HttpRequest  req = new HttpRequest();
            System.debug('A');
            HttpResponse resp;
            System.debug('B');
            Boolean combinePoiAndLocationAPI = false;
            Boolean combineLocationAndTimezoneAPI = true;
            List<BingResource> listOfResources = new List<BingResource>();
            try{
                if(string.isNotBlank(address)){
                    Pattern p = Pattern.compile('^[-+]?([1-8]?\\d(\\.\\d+)?|90(\\.0+)?),\\s*[-+]?(180(\\.0+)?|((1[0-7]\\d)|([1-9]?\\d))(\\.\\d+)?)$');
                    Matcher pm = p.matcher( address );
                    if(pm.matches()) {
                        completeUrl += 'Locations/' + address + '?&key=' + key;
                    } else {
                        combinePoiAndLocationAPI = true;
                        completeUrl += 'Locations?maxResults=7&strictMatch=1&includeNeighborhood=1&addressLine=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key;
                    }
                    System.debug('completeUrl: ' + completeUrl);
                    req.setEndpoint(completeUrl);
                    req.setMethod('GET');
                    resp = new Http().send(req);
                    string strResponse = resp.getbody();
                    System.debug('getAddressFromBing response: ' + strResponse);
                    //ERS-230388: Change by Ali for POI search using Bing
                    //Code for POI search in Bing Start
                    BingResponse responseObj = (BingResponse) JSON.deserialize(strResponse, BingResponse.class);
                    listOfResources.addAll(parseAndGetBingResources(responseObj));
                    
                    if(combinePoiAndLocationAPI) {
                        completeUrl = objSetting.Enpoint_URL__c + 'LocalSearch?maxResults=7&query=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key;
                        req.setEndpoint(completeUrl);
                        resp = new Http().send(req);
                        strResponse = resp.getbody();
                        System.debug('getAddressFromBing POI response: ' + strResponse);
                        BingResponse responseObj2 = (BingResponse) JSON.deserialize((strResponse.replaceFirst('"Address"', '"address"')), BingResponse.class);
                        List<BingResource> tempList = new List<BingResource>();
                        //Moving POI results to top of list of suggestions
                        tempList.addAll(parseAndGetBingResources(responseObj2));
                        tempList.addAll(listOfResources);
                        listOfResources.clear();
                        listOfResources.addAll(tempList);
                        tempList.clear();
                        responseObj = responseObj2;
                        
                        System.debug('getAddressFromBing responseObj ' + responseObj);
                    }
                    if (combineLocationAndTimezoneAPI) {
                        List<Double> llPoint = getLatLongfromBingAddress ( responseObj );
                        if(llPoint!=null){
                            String tzResp = getTimezoneFromBing(llPoint);
                            BingTimezone bingTZ = (BingTimezone) JSON.deserialize( tzResp, BingTimezone.class );
                            TimeZone innerTz = (Timezone) bingTZ.resourceSets.get(0).resources.get(0).timeZone;
                            String tzName = innerTz.abbreviation;
                            String offset = innerTz.utcOffset;
                            System.debug ( ' Lat/Lon ' + llPoint + ' UTC Offset= ' + 'UTC' + offset );
                            listOfResources.get(0).timeZone = innerTz;
                        }
                    }
                    //Code for POI search in Bing Stop
                    BingResourceSet resourceSet = new BingResourceSet();
                    resourceSet.resources = listOfResources;
                    BingResponse res = new BingResponse();
                    res.resourceSets.add(resourceSet);
                    
                    return JSON.serialize(res);
                }
            }catch(Exception e){
                String message = e.getMessage() + ': ' + e.getStackTraceString();
                //FSL_ApplicationLogCreator.integrationLog (req.getBody(),resp?.getBody(),'INTMapSearchAddressWithAPI','SADAGeoJSON',true,message,null);
            }
            return null;
        }
        
        private static List<BingResource> parseAndGetBingResources(BingResponse responseObj) {
            List<BingResource> listOfResources = new List<BingResource>();
            try {
                if(poiEntities.size() == 0) {
                    for(POI_Entity_type__mdt entity: [SELECT Entity_Type_Name__c FROM POI_Entity_type__mdt]) {
                        poiEntities.add(entity.Entity_Type_Name__c);
                    }
                }
                if( responseObj?.resourceSets != null &&
                    responseObj.resourceSets.size() > 0 &&
                    responseObj?.resourceSets[0]?.resources != null &&
                responseObj.resourceSets[0].resources.size() > 0) {
                    for(BingResource resource: responseObj.resourceSets[0].resources) {
                        if(resource.name != 'United States' && (resource.address.countryRegion == 'United States' || resource.address.countryRegion == 'US')) {
                            if(resource.address.countryRegion == 'US') {
                                resource.address.countryRegion = 'United States';
                            }
                            if(poiEntities.contains(resource.entityType)) {
                                resource.address.landmark = resource.name;
                            }
                            listOfResources.add(resource);
                        }
                    }
                }
            } catch (Exception e) {
                listOfResources = new List<BingResource>();
            }
            return listOfResources;
        }
        
        private static List<Double> getLatLongfromBingAddress ( BingResponse bingAddr ) {
            if(!bingAddr.resourceSets[0].resources.isEmpty() ){
                List<Double> llPoint = bingAddr.resourceSets[0].resources[0].geocodePoints[0].coordinates;
                return llPoint;
            }
            return null;
        }
        
        private static string getTimezoneFromBing ( List<Double> latLong ) {
            Integration_Settings__c objSetting = mapIntSettings.get('GETBING_API_GEOCODE');
            Map<String,String> mapHeaderKeyToValue = IntegrationUtil.getHeaderValue(objSetting.Header_Value__c);
            String key = mapHeaderKeyToValue.get('Authorization');
            String completeUrl = objSetting.Enpoint_URL__c;
            if(latLong!=null){
                String latLongVal = latLong[0] + ',' + latLong[1];
                completeUrl += 'timezone/' + latLongVal + '?&key=' + key;
                HttpRequest  req = new HttpRequest();
                HttpResponse resp;
                try{
                    req.setEndpoint(completeUrl);
                    req.setMethod('GET');
                    resp = new Http().send(req);
                    string tzResp = resp.getbody();
                    return tzResp;
                }
                catch(Exception e){
                    String message = e.getMessage() + ': ' + e.getStackTraceString();
                    //FSL_ApplicationLogCreator.integrationLog (req.getBody(),resp?.getBody(),'INTSADAGeoMapAPI','SADAGeoJSON',true,message,null);
                }
            }
            return null;
        } */
        /**
         * Description: Created Wrappers to store response from bing
         * Author: Ali Syed for ERS-230388
         */
        /*SSFI-1111 MPatel commented Bing
        public class BingResponse {
            public List<BingResourceSet> resourceSets;
            
            public BingResponse() {
                this.resourceSets = new List<BingResourceSet>();
            }
        }
        
        public class BingResourceSet {
            public List<BingResource> resources;
            
            public BingResourceSet() {
                this.resources = new List<BingResource>();
            }
        }
        
        public class BingResource {
            public string name {get;set;}
            public string entityType {get;set;}
            public Address address {get;set;}
            public Point point {get;set;}
            public List<GeocodePoints> geocodePoints {get;set;}
            public TimeZone timeZone {get;set;}
            
            public BingResource() {
                this.address = new Address();
                this.entityType = null;
                this.name = null;
            }
        } */
        
        public class Point {
            List<Double> coordinates;
            
            public Point() {
                this.coordinates = new List<Double>();
            }
        }
        
        public class Address {
            public string addressLine {get;set;}
            public string adminDistrict {get;set;}
            public string adminDistrict2 {get;set;}
            public string countryRegion {get;set;}
            public string formattedAddress {get;set;}
            public string landmark {get;set;}
            public string locality {get;set;}
            public string postalCode {get;set;}
            
            public Address() {
                this.addressLine = null;
                this.adminDistrict = null;
                this.adminDistrict2 = null;
                this.countryRegion = null;
                this.formattedAddress = null;
                this.locality = null;
                this.postalCode = null;
                this.landmark = null;
            }
        }
        
        public class GeocodePoints {
            public String type {get;set;}
            public List<Double> coordinates {get;set;}
        }
        
        // bingTimezone Json mapping class
        /*SSFI-1111 MPatel commented Bing
        public class bingTimezone {
            public List<BingResourceSet> resourceSets {get;set;}
            public Integer statusCode {get;set;}
            public String statusDescription {get;set;}
        } */
        public class TimeZone {
            public String genericName {get;set;}
            public String abbreviation {get;set;}
            public String ianaTimeZoneId {get;set;}
            public String windowsTimeZoneId {get;set;}
            public String utcOffset {get;set;}
            public ConvertedTime convertedTime {get;set;}
        }
        public class ConvertedTime {
            public String localTime {get;set;}
            public String utcOffsetWithDst {get;set;}
            public String timeZoneDisplayName {get;set;}
            public String timeZoneDisplayAbbr {get;set;}
        }
        
        @AuraEnabled
        public static List<Case> updateCaseDriverDirection(Id caseId, String driverDirection){
            List<Case> caseToBeUpdated = new List<Case>();
            List<Case> csRecord = [SELECT Id, ACG_Driving_Directions__c
                                FROM Case
                                WHERE Id =: caseId];
            for(Case c : csRecord){
                c.ACG_Driving_Directions__c = driverDirection;
                caseToBeUpdated.add(c);
            }
            if(!caseToBeUpdated.isEmpty()){
                update caseToBeUpdated;
            }
            
            return csRecord;
        }
        
        public class sadaresponse{
            public results[] results;
            public String status;
        }
        public class results {
            public String source;	//google
            public cls_location location;
            public String name;	//Independence, KS 67301, USA
            public String formatted_address;	//Independence, KS 67301, USA
            public cls_address address;
            public String place_id;	//ChIJ3xvUaT8ruIcRbENR8JE_Cq8
            public String[] types;
            public String plus_code;	//869667FP+5R
        }
        
        public class cls_location {
            public Double lat;	//37.2229544
            public Double lng;	//-95.712966
        }
        public class cls_address {
            public String city;	//Independence
            public String state;	//Kansas
            public String zip;	//67301
            public String country;	//United States
            public String street;
            public String streetNumber;
            public String suburb;
            
        }
        
        
        
        
    }