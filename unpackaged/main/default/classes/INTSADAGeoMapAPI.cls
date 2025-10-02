/**** Apex Class Name    :    INTSADAGeoMapAPI
    * Description        :    Call out class to SADAGEOJSON API 
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Ravi Kumar              Dec 15 2021            Created
    * Minesh Patel            May 8  2025			 Updated SSFI-1111
*********************************************************************************/
public with sharing class INTSADAGeoMapAPI {
    
    public static Map<String, Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();
    public static Set<String> poiEntities = new Set<String>();


    @AuraEnabled
    public static string getJSONPlaceDetails(String strplaceId, String sessionToken) {
        return getPlaceDetailsFromSADA(strplaceId, sessionToken);   //Need to uncomment the private method getAddressFromSADA when this becomes a custom settings/metadata - 2022/10/17
    }

    private static string getPlaceDetailsFromSADA(String strplaceId, String sessionToken){
        Integration_Settings__c objSetting = mapIntSettings.get('GETSADA_API');
        String completeUrl =  objSetting.Enpoint_URL__c + 'places/place-details?place_id=' + strplaceId + '&sessiontoken=' + sessionToken ;
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest.setTimeout(120000);
        try{
           objSetting.Enpoint_URL__c = completeUrl;
           objRequest = IntegrationUtil.preparerequest(objSetting);
           Datetime startTime = Datetime.now(); //khtx test
           objResponse = IntegrationUtil.makecallout(objRequest);
           Long diff = Datetime.now().getTime() - startTime.getTime(); 
           FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getAddressFromSADA', false, string.valueOf(diff), null); //khtx TEST
           string strResponse = objResponse.getbody();
           return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','SADAGeoJSON',true,message,null);
        }
        return null; 
    }


/////////////////This Method/////////////////////////////

    @AuraEnabled
    public static string getGeoJSONAddress(String strplaceId, String address) {
        // Boolean isBing = true; //khtx TODO: need custom settings/metadata to support changing map implementation during runtime; Ali: Setting to true to test bing implementation
        // if(isBing) {
        //     return getAddressFromBing(string.isNotBlank(address) ? address : strplaceId);
        // }
        //system.debug('called getGeoJSONAddress SADA' + address);
        //system.debug('called getGeoJSONAddress SADA strplaceId' + strplaceId);
		System.debug('**Get Sada');
        return getAddressFromSADA(strplaceId, address);   //Need to uncomment the private method getAddressFromSADA when this becomes a custom settings/metadata - 2022/10/17
    }
    
    @InvocableMethod(label='Update Miles' description='Update Miles when Breakdown\'s or Tow Destination\'s Geolocation changes')
    public static List<String> getMilesFromFlows(List<Double> geoLocations){
        List<String> towMilesResult = new List<String>();
        //Pass Breakdown Lat/Long and Tow Lat/Long
        String response = getMileageFromGoogleAPI(geoLocations[0],geoLocations[1],geoLocations[2],geoLocations[3]);
        return (List<String>)towMilesResult.add(response);
    }
    
    public static String getMileage(Location fromLocation, Location toLocation){
        Double fromLatitude = fromLocation.Latitude;
        Double fromLongitude = fromLocation.Longitude;
        Double toLatitude = toLocation.Latitude;
        Double toLongitude = toLocation.Longitude;

        return getMileageFromGoogleAPI(fromLatitude, fromLongitude, toLatitude, toLongitude);
    }
    
    public static String getMileageFromGoogleAPI(Double fromLatitude, Double fromLongitude,Double toLatitude, Double toLongitude){
        //system.debug('  #### mapIntSettings ##### '+ mapIntSettings);		
        Integration_Settings__c objSetting = mapIntSettings.get('GETGoogle_Directions_API');
        String completeUrl = objSetting.Enpoint_URL__c;
        String key = objSetting.API_Key__c;

        if(fromLatitude != null && fromLongitude!=null && toLatitude != null && toLongitude != null){
            String originString = String.valueOf(fromLatitude)+','+String.valueOf(fromLongitude);
            String destinationString = String.valueOf(toLatitude)+','+String.valueOf(toLongitude);
            //system.debug('origin String URL Encoded : '+EncodingUtil.urlEncode(originString, 'UTF-8'));
            //system.debug('destination String URL Encoded : '+EncodingUtil.urlEncode(destinationString, 'UTF-8'));
            completeUrl += 'origin='+EncodingUtil.urlEncode(originString, 'UTF-8');
            completeUrl += '&destination='+EncodingUtil.urlEncode(destinationString, 'UTF-8');
            completeUrl += '&key='+key;
            
        }else {
			//system.debug('called getMileageFromGoogleAPI no From and/or To Co-ordinates');
            return null;
        }    
               
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest.setTimeout(60000);
        try{

            //system.debug('called getMileageFromGoogleAPI calling preparerequest');
            
            objSetting.Enpoint_URL__c = completeUrl;
            objRequest = IntegrationUtil.preparerequest(objSetting);
            //system.debug('endpoint' + objRequest.getEndpoint());


            //system.debug('called getMileageFromGoogleAPI calling makecallout' );

            Datetime startTime = Datetime.now(); //khtx test
            objResponse = IntegrationUtil.makecallout(objRequest);

            Long diff = Datetime.now().getTime() - startTime.getTime(); 
            FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getMileageFromGoogleAPI', false, string.valueOf(diff), null); //khtx TEST

            //ResponseSADA res = buildResponse(objResponse.getbody());
            //String autosuggestResponse = JSON.serialize(res);
        

            string strResponse = objResponse.getbody();
            //system.debug('getMileageFromGoogleAPI response: ' + strResponse);
            ////system.debug('getAddressFromSADA ResponseSADA: ' + res);
            return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','getMileageFromGoogleAPI',true,message,null);
        }
        
        return null;
    }
    
    /* SSFI-1111 MPatel commented Bing Methods 5/8/25
    private static string getAddressFromBing(String address){
        Integration_Settings__c objSetting = mapIntSettings.get('GETBING_API_GEOCODE');
        Map<String,String> mapHeaderKeyToValue = IntegrationUtil.getHeaderValue(objSetting.Header_Value__c);
        String key = mapHeaderKeyToValue.get('Authorization');
        String completeUrl = objSetting.Enpoint_URL__c;
        
        Boolean combinePoiAndLocationAPI = false;
        Boolean combineLocationAndTimezoneAPI = true;
        List<BingResource> listOfResources = new List<BingResource>();
        
        if(string.isNotBlank(address)){
            //This condition is failing for cr --> 241 and tx-173, hondo tx
            //if(address.contains(',') && address.contains('-') && address.split(',').size() == 2 && !address.split(',')[0].isAlpha() && !address.split(',')[1].isAlpha()){
            Pattern p = Pattern.compile('^[-+]?([1-8]?\\d(\\.\\d+)?|90(\\.0+)?),\\s*[-+]?(180(\\.0+)?|((1[0-7]\\d)|([1-9]?\\d))(\\.\\d+)?)$');
            Matcher pm = p.matcher( address );
            if(pm.matches()) {    
                //Address is lat/long            
                completeUrl += 'Locations/' + address + '?&key=' + key;         
            } else {
                combinePoiAndLocationAPI = true;
                //completeUrl += 'Locations?maxResults=7&strictMatch=1&countryRegion=US&includeNeighborhood=1&addressLine=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key;
                completeUrl += 'Locations?maxResults=7&strictMatch=1&includeNeighborhood=1&addressLine=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key;
            }
        } else {
            return null;
        }
        HttpRequest  req = new HttpRequest();
        HttpResponse resp;
        try{

            ////system.debug('completeUrl: ' + completeUrl);

            req.setEndpoint(completeUrl);
            req.setMethod('GET');

            //Datetime startTime = Datetime.now(); //khtx test
            resp = new Http().send(req);
            //Long diff = Datetime.now().getTime() - startTime.getTime(); //khtx test
            //FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getAddressFromBing', false, string.valueOf(diff), null); //khtx TEST


            string strResponse = resp.getbody();

            ////system.debug('getAddressFromBing response: ' + strResponse);
            //ERS-230388: Change by Ali for POI search using Bing
            //Code for POI search in Bing Start
            BingResponse responseObj = (BingResponse) JSON.deserialize(strResponse, BingResponse.class);
            listOfResources.addAll(parseAndGetBingResources(responseObj));

            if(combinePoiAndLocationAPI) {
                completeUrl = objSetting.Enpoint_URL__c + 'LocalSearch?maxResults=7&query=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + key;
                req.setEndpoint(completeUrl);
                resp = new Http().send(req);
                strResponse = resp.getbody();
                ////system.debug('getAddressFromBing POI response: ' + strResponse);
                BingResponse responseObj2 = (BingResponse) JSON.deserialize((strResponse.replaceFirst('"Address"', '"address"')), BingResponse.class);
                List<BingResource> tempList = new List<BingResource>();
                //Moving POI results to top of list of suggestions
                tempList.addAll(parseAndGetBingResources(responseObj2));
                tempList.addAll(listOfResources);
                listOfResources.clear();
                listOfResources.addAll(tempList);
                tempList.clear();
                responseObj = responseObj2;                        
            }
            if (combineLocationAndTimezoneAPI && !Test.isRunningTest()) {  
                ////system.debug(' combineLocationAndTimezoneAPI = true getting latlong from the BingAddress String');
                List<Double> llPoint = getLatLongfromBingAddress ( responseObj );
                ////system.debug(' llPoint= ' + llPoint );
                if(llPoint.size() == 2) {
                String tzResp = getTimezoneFromBing(llPoint);
                BingTimezone bingTZ = (BingTimezone) JSON.deserialize( tzResp, BingTimezone.class );
                TimeZone innerTz = (Timezone) bingTZ.resourceSets.get(0).resources.get(0).timeZone;
                //String tzName = innerTz.abbreviation;
                //String offset = innerTz.utcOffset;
                ////system.debug(' after parsing tzResp string: timezone, tzOffset= ' + tzName + ',' + offset );
                ////system.debug ( ' Lat/Lon ' + llPoint + ' UTC Offset= ' + 'UTC' + offset );
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
        catch(Exception e){
            String message = e.getMessage() + ': ' + e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (req.getBody(),resp?.getBody(),'INTSADAGeoMapAPI','SADAGeoJSON',true,message,null);
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
    } */


    
    @AuraEnabled
    public static string getAddressAutoComplete(String strInput, String strcountries){
        Integration_Settings__c objSetting = mapIntSettings.get('GETPlace_AutoComplete_API');
        //system.debug(JSON.serialize(objSetting));
        //system.debug(strInput);
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
      	objRequest.setMethod('GET');
        objRequest.setEndpoint(objSetting.Enpoint_URL__c + EncodingUtil.urlEncode(strInput, 'UTF-8') +'&key=' + System.Label.ACG_Google_Maps_Key);
        try{
            //system.debug(objRequest);
            objResponse = IntegrationUtil.makecallout(objRequest);
            string strResponse = objResponse.getbody(); 
            Map<string,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(strResponse);
            List<ACG_PlacesautocompleteJSONWrapper.Address> lstAddress = new List<ACG_PlacesautocompleteJSONWrapper.Address>();
            if(mapResponse.get('status')==ACG_ConstantsClass.OK){
                return strResponse;
            } else {
                // FSL_ApplicationLogCreator.integrationLog (objSetting.Path__c,objResponse.getBody(),'INTSADAGeoMapAPI','SADAautocompleteJSON',false,'',null);
            } 
            return null;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','SADAautocompleteJSON',true,message,null);
        }
        return null;
    }


    /**
     * Description: Created Wrappers to store response from bing
     * Author: Ali Syed for ERS-230388
     */
    /*SSFI-1111 MPatel commented Bing Methods 5/7/25
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
        public string name;
        public string entityType;
        public Address address;
        public Point point;
        public List<GeocodePoints> geocodePoints {get;set;}
        public TimeZone timeZone {get;set;}

        public BingResource() {
            this.address = new Address();
            this.entityType = null;
            this.name = null;
        }
    } */ //SSFI-1111 End

    public class Point {
        public List<Double> coordinates;

        public Point() {
            this.coordinates = new List<Double>();
        }
    }

    /* SSFI-1111 MPatel commented Bing Methods 5/7/25
    public class Address {
        public string addressLine;
        public string adminDistrict;
        public string adminDistrict2;
        public string countryRegion;
        public string formattedAddress;
        public string landmark;
        public string locality;
        public string postalCode;

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

    //Called by Call Create api when service appointment has address but no lat/long
    public static List<Double> getLatLongfromBingAddress ( String address ) {
        String bingAddrResp = getAddressFromBing ( address );
        BingResponse bingAddr = (BingResponse) JSON.deserialize( bingAddrResp, BingResponse.class );
        List<Double> llPoint = getLatLongfromBingAddress ( bingAddr );
        return llPoint;
    }

    public static string getTimezone ( String address ) {
        return getTimezoneFromBing( address );
    }

    private static string getTimezoneFromBing (String address) {
        String bingAddrResp = getAddressFromBing ( address );
        BingResponse bingAddr = (BingResponse) JSON.deserialize( bingAddrResp, BingResponse.class );
        List<Double> llPoint = getLatLongfromBingAddress ( bingAddr );
        String tzResp = getTimezoneFromBing(llPoint);
        return tzResp;
    }

    public static List<Double> getLatLongfromBingAddress ( BingResponse bingAddr ) {
        List<Double> llPoint = new List<Double>();
        if( bingAddr.resourceSets.size() > 0 && bingAddr.resourceSets[0].resources.size() > 0 &&
         bingAddr.resourceSets[0].resources[0].geocodePoints.size() > 0) {
            llPoint = bingAddr.resourceSets[0].resources[0].geocodePoints[0].coordinates;
        }
        ////system.debug(' after parsing addrResp string: geocodePoint= ' + llPoint );
        return llPoint;
    }
    // private static String concatLatLon ( List<Double> llPoint ) {
    //     return llPoint[0] + ',' + llPoint[1];
    // }

    public static string getTimezoneFromBing ( List<Double> latLong ) {

        Integration_Settings__c objSetting = mapIntSettings.get('GETBING_API_GEOCODE');
        Map<String,String> mapHeaderKeyToValue = IntegrationUtil.getHeaderValue(objSetting.Header_Value__c);
        String key = mapHeaderKeyToValue.get('Authorization');
        //example https://dev.virtualearth.net/REST/v1/timezone/61.768335,-158.808765?key={BingMapsKey}
        String completeUrl = objSetting.Enpoint_URL__c;

        String latLongVal = latLong[0] + ',' + latLong[1];
        //Address is lat/long
        completeUrl += 'timezone/' + latLongVal + '?&key=' + key;
        ////system.debug('completeUrl: ' + completeUrl);

        HttpRequest  req = new HttpRequest();
        HttpResponse resp;
        try{

            req.setEndpoint(completeUrl);
            req.setMethod('GET');

            //Datetime startTime = Datetime.now(); //khtx test
            resp = new Http().send(req);
            //Long diff = Datetime.now().getTime() - startTime.getTime(); //khtx test
            //FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getAddressFromBing', false, string.valueOf(diff), null); //khtx TEST
            string tzResp = resp.getbody();

            ////system.debug('getTimezoneFromBing response: ' + tzResp);
            //BingTimezone bingTZ = (BingTimezone) JSON.deserialize( tzResp, BingTimezone.class );
            ////system.debug(' after parsing tzResp string: statusCode= ' + bingTZ.statusCode);
            //String tzAbbr = bingTZ.resourceSets[0].resources[0].timeZone.abbreviation;
            //String offset = bingTZ.resourceSets[0].resources[0].timeZone.utcOffset;
            ////system.debug(' after parsing combined Offset= ' + tzAbbr + ':' + offset );

            return tzResp;
        }
        catch(Exception e){
            String message = e.getMessage() + ': ' + e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (req.getBody(),resp?.getBody(),'INTSADAGeoMapAPI','SADAGeoJSON',true,message,null);
        }
        return null; 
    }

    public static string getTimezoneUTCOffset ( Double lat, Double lon ) {
        return getTimezoneUTCOffset ( new List<Double> { lat, lon });
    }

    // Javascript enabled with string params
    @AuraEnabled
    public static string getTimezoneUTCOffset_Str ( String lat, String lng ) {
        //system.debug('INTSADAGeoMapAPI. getTimezoneUTCOffset_Str ( ' + lat + ', ' + lng );
        List<Double> latLong = new List<Double> { Double.valueOf(lat), Double.valueOf(lng) };
        return getTimezoneUTCOffset ( latLong );
    }

    public static string getTimezoneUTCOffset ( List<Double> latLong ) {
        String tzResp = getTimezoneFromBing(latLong);
        ////system.debug('getTimezoneFromBing response: ' + tzResp);
        BingTimezone bingTZ = (BingTimezone) JSON.deserialize( tzResp, BingTimezone.class );
        //String UTCString = 'UTC' + bingTZ.resourceSets[0].resources[0].timeZone.utcOffset;
        String UTCString = 'UTC' + bingTZ.resourceSets[0].resources[0].timeZone.convertedTime.utcOffsetWithDst;
        ////system.debug(' after parsing combined Offset= ' + UTCString );
        return UTCString;
    }

    // Brief geopoint bingAddress Json mapping class
    // public class bingAddress {
    //     public String authenticationResultCode {get;set;}
    //     public List<BingResource> resourceSets {get;set;}
    //     //public List<ResourceSets> resourceSets {get;set;}
    //     public Integer statusCode {get;set;}
    //     public String statusDescription {get;set;}
    // }
    // public class ResourceSets {
    //     public Integer estimatedTotal {get;set;} 
    //     public List<Resources> resources {get;set;} 
    // }
    // public class Resources {
    //     public String name {get;set;} 
    //     public Address address {get;set;} 
    //     public List<GeocodePoints> geocodePoints {get;set;}
    //     public TimeZone timeZone {get;set;}
    // }
    // public class Address {
    //     public String addressLine {get;set;} 
    //     public String formattedAddress {get;set;} 
    //     public String postalCode {get;set;} 
    // }
    public class GeocodePoints {
        public String type {get;set;} 
        public List<Double> coordinates {get;set;} 
    }

    // Full bingAddress Json mapping class
    // public class bingAddress {
    //     public String authenticationResultCode {get;set;}
    //     public String brandLogoUri {get;set;}
    //     public String copyright {get;set;}
    //     public List<ResourceSets> resourceSets {get;set;}
    //     public Integer statusCode {get;set;}
    //     public String statusDescription {get;set;}
    //     public String traceId {get;set;}
    // }
    // public class ResourceSets {
    //     public Integer estimatedTotal {get;set;} 
    //     public List<Resources> resources {get;set;} 
    // }
    // public class Resources {
    //     public String xtype {get;set;} // in json: __type
    //     public List<Double> bbox {get;set;} 
    //     public String name {get;set;} 
    //     public Point point {get;set;} 
    //     public Address address {get;set;} 
    //     public String confidence {get;set;} 
    //     public String entityType {get;set;} 
    //     public List<GeocodePoints> geocodePoints {get;set;} 
    //     public List<String> matchCodes {get;set;} 
    // }
    // public class Address {
    //     public String addressLine {get;set;} 
    //     public String adminDistrict {get;set;} 
    //     public String adminDistrict2 {get;set;} 
    //     public String countryRegion {get;set;} 
    //     public String formattedAddress {get;set;} 
    //     public String locality {get;set;} 
    //     public String neighborhood {get;set;} 
    //     public String postalCode {get;set;} 
    // }
    // public class GeocodePoints {
    //     public String type {get;set;} 
    //     public List<Double> coordinates {get;set;} 
    //     public String calculationMethod {get;set;} 
    //     public List<String> usageTypes {get;set;} 
    // }
    // public class Point {
    //     public String type {get;set;}
    //     public List<Double> coordinates {get;set;}
    // }

    // bingTimezone Json mapping class
    public class bingTimezone {
        //public String authenticationResultCode {get;set;}
        //public String brandLogoUri {get;set;}
        //public String copyright {get;set;}
        //public List<ResourceSets> resourceSets {get;set;}
        public List<BingResourceSet> resourceSets {get;set;}
        public Integer statusCode {get;set;}
        public String statusDescription {get;set;}
        //public String traceId {get;set;}
    }
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
    } */ //SSFI-1111 End 





    public class ResponseSADA {
        public List<ResultSetSADA> resultSets;

        public ResponseSADA() {
            this.resultSets = new List<ResultSetSADA>();
        }
    }

    public class ResultSetSADA {
        public List<ResultSADA> results;

        public ResultSetSADA() {
            this.results = new List<ResultSADA>();
        }
    }


    public class ResultSADA {
        public string source;
        public Point location;
        public string name;
        public string formatted_address;
        public AddressSADA address;
        public string place_id;
        public string plus_code;

        public ResultSADA() {
            this.source = null;
            this.location = new Point();
            this.name = null;
            this.formatted_address = null;
            this.address = new AddressSADA();
            this.place_id = null;
            this.plus_code = null;            
        }
    }

    public class AddressSADA{
        public string intersection;
        public string mileMumber;
        public string streetNumber;
        public string street;
        public string suburb;
        public string city;
        public string county;
        public string state;
        public string zip;
        public string country;
        public string source;
        public Double lat;
        public Double lng;
        public string name;
        public string formattedAddress;
        public string placeId;
        public string plusCode;        

        public AddressSADA() {
            this.intersection = null;
            this.mileMumber = null;
            this.streetNumber = null;
            this.street = null;
            this.suburb = null;
            this.city = null;
            this.county = null;
            this.state = null;
            this.zip = null;
            this.country = null;
            this.source = null;
            this.lat = null;
            this.lng = null;
            this.name = null;
            this.formattedAddress = null;
            this.placeId = null;
            this.plusCode = null;                
        }
    }



    private static ResponseSADA buildResponse( String response ) {

        //system.debug( 'buildResponse: ' + response );
        ResponseSADA responseObj = (ResponseSADA) JSON.deserialize(response, ResponseSADA.class);
		//system.debug( 'responseObj: ' + responseObj );

        List<ResultSADA> results = new List<ResultSADA>();
        results.addAll(parseSADAGeocodeResults(responseObj));

        ResultSetSADA resultSet = new ResultSetSADA();
        resultSet.results = results;
        ResponseSADA res = new ResponseSADA();
        res.resultSets.add(resultSet);

        return res;
    }


    @TestVisible //AGB added TestVisible 4/24/2024 for SFI-509 SADA API Part 3
    private static List<ResultSADA> parseSADAGeocodeResults(ResponseSADA responseObj) {
        //system.debug( 'called parseSADAGeocodeResults' ) ;
        List<ResultSADA> results = new List<ResultSADA>();
        
        try {
            if( responseObj?.resultSets != null &&
                responseObj?.resultSets[0]?.results != null) {
                for(ResultSADA resultNode: responseObj.resultSets[0].results) {
                    //system.debug( 'parseSADAGeocodeResults results.add  ' + resultNode ) ;

                    AddressSADA addrResult = new AddressSADA();
                    addrResult.source = resultNode.source;
                    addrResult.lat = resultNode.location.coordinates[0];
                    addrResult.lng = resultNode.location.coordinates[1];
                    addrResult.name = resultNode.name;
                    addrResult.formattedAddress = resultNode.formatted_address;
                    addrResult.placeId = resultNode.place_id;
                    addrResult.plusCode = resultNode.plus_code;

                    AddressSADA addrNode = resultNode.address;
                    addrResult.streetNumber = addrNode.streetNumber;
                    addrResult.street = addrNode.street;
                    addrResult.city = addrNode.city;
                    //update state...
                    System.debug('***update state');
                    addrResult.state = stateToStateCode(addrNode.state);
                    addrResult.zip = addrNode.zip;
                    addrResult.country = addrNode.country;

                    ResultSADA result = new ResultSADA();
                    result.address = addrResult;
                    results.add( result );
                }
            }
        } catch (Exception e) {
            results = new List<ResultSADA>();
        }
        return results;
    }    

    



    private static string getAddressFromSADA(String strplaceId, String add){
        String address;
        if (add!= null && add != '')
			address = add.replace('%20', ' ');
        
        system.debug('called getAddressFromSADA' + strplaceId + address);
		//This is null
        Integration_Settings__c objSetting = mapIntSettings.get('GETSADA_API');
        system.debug('object setting **' + objSetting);
        system.debug('object setting Hvalue**' + objSetting.Header_Value__c);
        Map<String,String> mapHeaderKeyToValue = IntegrationUtil.getHeaderValue(objSetting.Header_Value__c);
        String key = mapHeaderKeyToValue.get('SADA-API-KEY');
        //String completeUrl = objSetting.Enpoint_URL__c + 'geocode';
        String completeUrl = objSetting.Enpoint_URL__c + 'search';


        if(strplaceId != null && strplaceId !=''){
			//place id search api 
            system.debug('***placeid***'+EncodingUtil.urlEncode(strplaceId, 'UTF-8') );
            completeUrl += '/'+EncodingUtil.urlEncode(strplaceId, 'UTF-8');
            completeUrl += '?format=simplified';
            system.debug('**completeUrl= '+ completeUrl);
        } else if(string.isNotBlank(address)){
            if(address.contains(',') && address.contains('-') && address.split(',').size() == 2 && !address.split(',')[0].isAlpha() && !address.split(',')[1].isAlpha()){
				//co-ordinate geocode api
                completeUrl = '';
				completeUrl = objSetting.Enpoint_URL__c + 'geocode';
                system.debug('called getAddressFromSADA ?latlng= '+ EncodingUtil.urlEncode(address, 'UTF-8') );
				completeUrl += '?latlng='+EncodingUtil.urlEncode(address, 'UTF-8'); 
                completeUrl += '&format=simplified';
                system.debug('**completeUrl= '+ completeUrl);
            } else if(address.startsWithIgnoreCase('POI-')){
                //poi search geocode api
                completeUrl = '';
                system.debug('*****POI****');
                completeUrl = objSetting.Enpoint_URL__c + 'geocode';
                address = address.removeStart('POI-'); 
                system.debug('called getAddressFromSADA ?address= '+ EncodingUtil.urlEncode(address, 'UTF-8') );
                completeUrl += '?address='+EncodingUtil.urlEncode(address, 'UTF-8'); 
                completeUrl += '&format=simplified';
               system.debug('**completeUrl= '+ completeUrl);
            }else {
                //search api address 
                system.debug('called getAddressFromSADA ?address= '+ EncodingUtil.urlEncode(address, 'UTF-8') );
                completeUrl += '?query='+EncodingUtil.urlEncode(address, 'UTF-8');  
                completeUrl += '&format=simplified';
                system.debug('**completeUrl= '+ completeUrl);
			}
            
        } else {
            system.debug('called getAddressFromSADA no placeId and no address');
            return null;
        }    
               
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest.setTimeout(120000);
        try{

            system.debug('called getAddressFromSADA calling preparerequest' + completeUrl);
            
            objSetting.Enpoint_URL__c = completeUrl;

            objRequest = IntegrationUtil.preparerequest(objSetting);
            system.debug('endpoint' + objRequest.getEndpoint());


            system.debug('called getAddressFromSADA calling makecallout' );

            Datetime startTime = Datetime.now(); //khtx test
            objResponse = IntegrationUtil.makecallout(objRequest);
            
            system.debug('*****objResponse' + objResponse.getbody());
			
            Long diff = Datetime.now().getTime() - startTime.getTime(); 
            FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getAddressFromSADA', false, string.valueOf(diff), null); //khtx TEST

            
            string strResponse = objResponse.getbody();
            system.debug('getAddressFromSADA response: ' + strResponse);
           
            return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','SADAGeoJSON',true,message,null);
        }
        return null; 
    }

    public static List<Double> getLatLongFromGoogle(String address){
        List<Double> latLongCords = new List<Double>();
        //address = address.replace(' ', '%20');
        String geoCodeResponse = getLatLongByAddressFromGoogle(address);
        if(String.isNotBlank(geoCodeResponse)){
            GoogleGeoCodeResponse response = new GoogleGeoCodeResponse();
            response = (GoogleGeoCodeResponse)JSON.deserialize(geoCodeResponse, GoogleGeoCodeResponse.class);
            latLongCords.add(Decimal.valueOf(response.results[0]?.geometry?.location?.lat).setScale(8));
            latLongCords.add(Decimal.valueOf(response.results[0]?.geometry?.location?.lng).setScale(8));
            return latLongCords;
        }
        else{
            return null;
        }
    }

    private static string getLatLongByAddressFromGoogle(String address){
        system.debug('called getLatLongByAddressFromGoogle' + address);
        Integration_Settings__c objSetting = mapIntSettings.get('GETGoogle_Geocode_API');
        String completeUrl = objSetting.Enpoint_URL__c;
        if(String.isNotBlank(address)){
            completeUrl += 'address='+EncodingUtil.urlEncode(address, 'UTF-8');
            completeUrl += '&key='+EncodingUtil.urlEncode(objSetting.API_Key__c, 'UTF-8');
        } else {
            system.debug('called getLatLongByAddressFromGoogle no address');
            return null;
        }    
               
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest.setTimeout(120000);
        try{
            system.debug('called getLatLongByAddressFromGoogle calling preparerequest' + completeUrl);
            
            objSetting.Enpoint_URL__c = completeUrl;
            objRequest = IntegrationUtil.preparerequest(objSetting);

            Datetime startTime = Datetime.now();
            objResponse = IntegrationUtil.makecallout(objRequest);

            Long diff = Datetime.now().getTime() - startTime.getTime(); 
            //FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getLatLongByAddressFromGoogle', false, string.valueOf(diff), null); //khtx TEST

            string strResponse = objResponse.getbody();
            system.debug('getLatLongByAddressFromGoogle response: ' + strResponse);
           
            return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','getLatLongByAddressFromGoogle',true,message,null);
        }
        return null; 
    }

    public static List<String> getTimeZoneFromGoogle(String latlong){ //comma separated LatLong
        List<String> timezoneResult = new List<String>();
        String timestampInSeconds = String.valueOf((DateTime.now().getTime()) / 1000); //Get Timestamp in sec since Jan 1, 1970
        String timezoneResponse = getTimezoneByLatLngFromGoogle(latlong, timestampInSeconds);
        if(String.isNotBlank(timezoneResponse)){
            Map<String,Object> response = new Map<String,Object>();
            response = (Map<String,Object>)JSON.deserializeUntyped(timezoneResponse);
            timezoneResult.add((String)response.get('timeZoneId'));
            timezoneResult.add(String.valueOf((Integer)response.get('rawOffset')));
            return timezoneResult;
        }
        else{
            return null;
        }
    }

    private static string getTimezoneByLatLngFromGoogle(String latlong, String timestampInSeconds){
        system.debug('called getTimezoneByLatLngFromGoogle' + latlong + timestampInSeconds);
        Integration_Settings__c objSetting = mapIntSettings.get('GETGoogle_Timezone_API');
        String completeUrl = objSetting.Enpoint_URL__c;
        if(String.isNotBlank(latlong)){
            completeUrl += 'location='+EncodingUtil.urlEncode(latlong, 'UTF-8');
            completeUrl += '&timestamp='+EncodingUtil.urlEncode(timestampInSeconds, 'UTF-8');
            completeUrl += '&key='+EncodingUtil.urlEncode(objSetting.API_Key__c, 'UTF-8');
        } else {
            system.debug('called getTimezoneByLatLngFromGoogle no latlong and no timestampInSeconds');
            return null;
        }    
               
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest.setTimeout(120000);
        try{
            system.debug('called getTimezoneByLatLngFromGoogle calling preparerequest' + completeUrl);
            
            objSetting.Enpoint_URL__c = completeUrl;
            objRequest = IntegrationUtil.preparerequest(objSetting);

            Datetime startTime = Datetime.now();
            objResponse = IntegrationUtil.makecallout(objRequest);

            Long diff = Datetime.now().getTime() - startTime.getTime(); 
            //FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getTimezoneByLatLngFromGoogle', false, string.valueOf(diff), null); //khtx TEST

            string strResponse = objResponse.getbody();
            system.debug('getTimezoneByLatLngFromGoogle response: ' + strResponse);
           
            return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','getTimezoneByLatLngFromGoogle',true,message,null);
        }
        return null; 
    }

    public class GoogleGeoCodeResponse{
        public results[] results;
        public String status;
    }	
    public class results {
		public cls_geometry geometry;
		public String formatted_address;
		public String place_id;
		public String[] types;
	}
    public class cls_geometry {
        public cls_location location;
    }
	public class cls_location {
		public Double lat;
		public Double lng;
	}


    public class ResponseAutosuggest {
        public List<PredictionSet> predictionSets;

        public ResponseAutosuggest() {
            this.predictionSets = new List<PredictionSet>();
        }
    }

    public class PredictionSet {
        public List<Prediction> predictions;

        public PredictionSet() {
            this.predictions = new List<Prediction>();
        }
    }


    public class Prediction {
        public string description;
        public string place_id;

        public Prediction() {
            this.description = null;
            this.place_id = null;
        }

    } 

    @AuraEnabled
    public static string getJSONAutosuggestAddresses(String userQuery, String sessionToken) {
        return getAutoSuggestAddressFromSADA( userQuery, sessionToken); 
    }

    private static string getAutoSuggestAddressFromSADA( String userQuery, String sessionToken) {

        Integration_Settings__c objSetting = mapIntSettings.get('GETSADA_API');
        String completeUrl = objSetting.Enpoint_URL__c + 'autocomplete/autocomplete' + '?sessionToken=' + sessionToken;
        if ( userQuery != null && userQuery !='' ){
          completeUrl += '&input='+userQuery +'&locationbias=' + objSetting.locationbias__c;
        } else {
            return null;
        }    
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        try{
            objSetting.Enpoint_URL__c = completeUrl;
            objRequest = IntegrationUtil.preparerequest(objSetting);
            Datetime startTime = Datetime.now(); //khtx test
            objResponse = IntegrationUtil.makecallout(objRequest);
            Long diff = Datetime.now().getTime() - startTime.getTime(); //khtx test
            FSL_ApplicationLogCreator.integrationLog ('', '', 'INTSADAGeoMapAPI', 'getAutosuggestResponse', false, string.valueOf(diff), null); //khtx TEST
            ResponseAutosuggest res = buildResponseAutosuggest(objResponse.getbody());
            String autosuggestResponse = JSON.serialize(res);
            string strResponse = objResponse.getbody();
            return strResponse;
        }
        catch(Exception e){
            String message = e.getStackTraceString();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'INTSADAGeoMapAPI','getAutosuggestResponse',true,message,null);
        }
        return null; 
    }

    private static ResponseAutosuggest buildResponseAutosuggest( String response ) {

        system.debug( 'buildResponseAutosuggest: ' + response );
        ResponseAutosuggest responseObj = (ResponseAutosuggest) JSON.deserialize(response, ResponseAutosuggest.class);


        List<Prediction> predictions = new List<Prediction>();
        predictions.addAll(parseSADAAutosuggestResults(responseObj));

        PredictionSet predSet = new PredictionSet();
        predSet.predictions = predictions;
        ResponseAutosuggest res = new ResponseAutosuggest();
        res.predictionSets.add(predSet);

        return res;
    }    

    


    private static List<Prediction> parseSADAAutosuggestResults(ResponseAutosuggest responseObj) {
        //system.debug( 'called parseSADAAutosuggestResults' ) ;
        List<Prediction> predictions = new List<Prediction>();
        
        try {
            if( responseObj?.predictionSets != null &&
                responseObj?.predictionSets[0]?.predictions != null) {
                for(Prediction predNode: responseObj.predictionSets[0].predictions) {
                    //system.debug( 'parseSADAAutosuggestResults predictions.add  ' ) ;

                    Prediction pred = new Prediction();
                    pred.description = predNode.description;
                    pred.place_id = predNode.place_id;

                    predictions.add( pred );
                }
            }
        } catch (Exception e) {
            predictions = new List<Prediction>();
        }
        return predictions;
    }    

	@TestVisible //AGB added TestVisible 4/24/2024 for SFI-509 SADA API Part 3
    private static String stateToStateCode(String state){
         System.debug('***State Code');
        if (state.length() == 2){
            return state;
        }
       
        
      Schema.DescribeFieldResult fieldResult = Account.BillingStateCode.getDescribe();

        for(Schema.PicklistEntry f : fieldResult.getPicklistValues()){
            if (state == f.getLabel())
                return f.getValue();
		}
        //if we didn't get a match, just return
        return state;
    }




}