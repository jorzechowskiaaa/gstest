public without sharing class Plate2Vin {

    public class Plate2VinSearchRequest{
        public String state {get;set;}
        public String tag {get;set;}
        //public Boolean BatteryQuote {get;set;}
        //public string zipCode {get;set;}
        public string clubCode {get;set;}
        public string sourceId {get;set;}
    }
    
    @AuraEnabled(cacheable=false)
    public static Plate2Vin_ResponseWrapper getVin(string inpState, string inpTag) //was searchPlate , boolean batteryQuote, string postalCode
    {
        Plate2VinSearchRequest sr = new Plate2VinSearchRequest();
        sr.state = inpState;
        sr.tag = inpTag;
        //sr.BatteryQuote = batteryQuote;
        //sr.zipCode = postalCode;
        sr.clubCode = '240';
        sr.sourceId = 'AAANE';
        Plate2Vin_ResponseWrapper p2vRW = new Plate2Vin_ResponseWrapper();
        string request = System.JSON.serialize(sr);
        system.debug('Request:'+request);
        Plate2Vin_ResponseWrapper response = new Plate2Vin_ResponseWrapper();
        response = invokeCallout(request,'Plate2Vin');
        return response;
    }
   
    public static Plate2Vin_ResponseWrapper invokeCallout(String requestData, String endPointMetadata){
        Plate2Vin_ResponseWrapper p2vRW = new Plate2Vin_ResponseWrapper();
        Util_ManageAccessTokens utilToken = new Util_ManageAccessTokens();
        String token = '';
        String expiresInStr = '';
        Map<String, String> newAccessToken = new Map<String, String>();
        if(Test.isRunningTest()){
            token = 'sometokenhere';
            expiresInStr = '2000';
        }
        else{
            newAccessToken = utilToken.callOAuth('OAuth'); // Fetch token
            token = newAccessToken.get('access_token');
            expiresInStr = newAccessToken.get('expires_in');            
        }
        system.debug('Token:'+token);
        system.debug('expiresInStr:'+expiresInStr);
        Http http = new Http(); 
        HttpRequest request = new HttpRequest();
        HttpResponse response;
        FSL_Service_Endpoints__c searchEndpoint;
        if(token != null){
            if(Test.isRunningTest()){
                searchEndpoint = new FSL_Service_Endpoints__c(Timeout__c = 3000, Endpoint_URL__c='testSearch');
            }else{
                searchEndpoint = FSL_Service_Endpoints__c.getValues(endPointMetadata);
            }
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json;charset=UTF-8');
            request.setHeader('Authorization','Bearer '+token);
            if(searchEndpoint.Timeout__c != null){
                request.setTimeout(integer.ValueOf(searchEndpoint.Timeout__c));
            }
            if(!string.isEmpty(searchEndpoint.Endpoint_URL__c)){
                String endpoint = searchEndpoint.Endpoint_URL__c;
                //String queryParams = constructURL(requestData);               
                request.setEndpoint(endpoint);
            }
            if(String.isNotBlank(searchEndpoint.Client_Cert_Name__c)){
                request.setClientCertificateName(searchEndpoint.Client_Cert_Name__c);
            }
            //string body = '{"state": "ND","tag": "938BSJ","batteryQuote": true,"zipCode": "58072","clubCode": "420","sourceId": "ABC123"}';
            //string body = '{"state": "ND","tag": "464BLB","batteryQuote": true,"zipCode": "11201","clubCode": "420","sourceId": "ABC123"}';
            //string body = '{"state": "OH","tag": "6RT12","clubCode": "420","sourceId": "ABC123"}';
            request.setBody(requestData);
            response = http.send(request);
            System.debug('invokeCallout Response: '+response.getBody());
            p2vRW = Plate2Vin_ResponseWrapper.parse(response.getBody());
            //Map<String, Object> jsonmap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            //System.debug(jsonmap);
            //System.debug('AGB');
            //System.debug(JSON.serialize(response.getBody()));
        }
        return p2vRW;
    } 
   
}