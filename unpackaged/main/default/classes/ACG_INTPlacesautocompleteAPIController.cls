/**** Apex Class Name    :    ACG_INTPlacesautocompleteAPIController
* Description        :    This class is used for Places Autocomplete and Places Details API Callout   
* Modification Log   :
* Test Class Name    :    ACG_INTPlacesautocompleteAPICntrlTest
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Venkat Kommuri               Jul 31 2020             Created
*********************************************************************************/
public with sharing class ACG_INTPlacesautocompleteAPIController {
    public static final Map<String,Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();
    
    public string lexOrigin { 
        get { 
            return URL.getOrgDomainUrl().toExternalForm().split('.my.')[0]+'.lightning.force.com';
        } 
        set;
    }
    
    /***
    * Method name        : getAddressAutoComplete
    * Description        : Returns a list of place ids and description in serialized string 
    * Return Type        : String
    * @Param strInput    : user inputs the address
    */

    @AuraEnabled
    public static string getAddressAutoComplete(String strInput){
        Integration_Settings__c objSetting=mapIntSettings.get('GETPlace_AutoComplete_API');
        objSetting.Enpoint_URL__c += EncodingUtil.urlEncode(strInput, 'UTF-8')
            +'&key=' + System.Label.ACG_Google_Maps_Key;   //Added key parameter by Ali for ERS-229280
        
        List<LookupSearchResult> lstSearchResults = new List<LookupSearchResult>();
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        try{
            objRequest = IntegrationUtil.preparerequest(objSetting);
            objResponse = IntegrationUtil.makecallout(objRequest);
            string strResponse = objResponse.getbody(); 
            System.debug(strResponse);
            Map<string,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(strResponse);
            List<ACG_PlacesautocompleteJSONWrapper.Address> lstAddress = 
                new List<ACG_PlacesautocompleteJSONWrapper.Address>();
            if(mapResponse.get('status')==ACG_ConstantsClass.OK){
                lstAddress=ACG_PlacesautocompleteJSONWrapper.parse(strResponse);
            }
            
            for (ACG_PlacesautocompleteJSONWrapper.Address ad : lstAddress) {
                lstSearchResults.add(
                    new LookupSearchResult(
                        ad.placeId,
                        ad.description
                    )
                );
            }
        } catch (Exception e){
            System.debug(e.getStackTraceString());
            FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTAutoCompleteAPI','INTAutoComplete',true,e.getMessage(),null);
            
        }
        return JSON.serialize(lstSearchResults);
    }
    
    /***
    * Method name            : getPlaceDetailsFromGeolocation
    * Description            : Returns a response of plcae details in JSON format for the selected geolocation 
    * Return Type            : String
    * @Param strPlaceid      : geolocation of the Selected address from the component
    */
    @AuraEnabled(cacheable=true)
    public static string getPlaceDetailsFromGeolocation(String latLong){
        Integration_Settings__c objSetting=mapIntSettings.get('GETReverse_geocode_API');
        objSetting.Enpoint_URL__c += EncodingUtil.urlEncode(latLong, 'UTF-8')
            +'&key=' + System.Label.ACG_Google_Maps_Key;
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        objRequest = IntegrationUtil.preparerequest(objSetting);
        objResponse = IntegrationUtil.makecallout(objRequest);
        string strResponse = objResponse.getbody();
        Map<string,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(strResponse);
        if(mapResponse.get('status')=='OK'){
            System.debug('Sucess'+strResponse);
        }
        return strResponse;
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
            Integration_Settings__c objSetting=mapIntSettings.get('GETDistance_Matrix_API');
            objSetting.Enpoint_URL__c += 'key=' + System.Label.ACG_Google_Maps_Key+'&origins='+origLat+','+origLong+'&destinations='+destLat+','+destLong+'&units='+unitSystem;
            HttpRequest  objRequest = new HttpRequest();
            HttpResponse objResponse = new HttpResponse();
            try {
                objRequest = IntegrationUtil.preparerequest(objSetting);
                objResponse = IntegrationUtil.makecallout(objRequest);
                string strResponse = objResponse.getbody();
                resp = INTDistanceMatrixAPIResponseWrapper.parse(objResponse.getbody());
                if(resp?.status==ACG_ConstantsClass.OK){
                    FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',false,'',null);
                    return resp;
                } else {
                    FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',true,system.label.INTGOOGLE_DISTMAT_INVALIDREQ,null);
                }
            } catch (Exception e){
                FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTDistanceMatrixAPI','INTDistanceMatrix',true,e.getMessage(),null);
                
            }
        }
        return null;
    }
    
    /***
    * Method name            : getPlaceDetails
    * Description            : Returns a response in JSON format for the selected PlaceId 
    * Return Type            : String
    * @Param strPlaceid      : PlaceId of the Selected address from the component
    */
    @AuraEnabled
    public static string getPlaceDetails(String strPlaceid){
        Integration_Settings__c objSetting=mapIntSettings.get('GETPlace_Details_API');
        objSetting.Enpoint_URL__c += EncodingUtil.urlEncode(strPlaceid, 'UTF-8') //Added place_id parameter by Ali for ERS-229280
            +'&key=' + System.Label.ACG_Google_Maps_Key;
        string strResponse;
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        try{
            objRequest = IntegrationUtil.preparerequest(objSetting);
            objResponse = IntegrationUtil.makecallout(objRequest);
            strResponse = objResponse.getbody();
            Map<string,Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(strResponse);
            if(mapResponse.get('status')==ACG_ConstantsClass.OK){
                return strResponse;
            } 
        } catch (Exception e){
            FSL_ApplicationLogCreator.integrationLog (objSetting.Enpoint_URL__c,objResponse.getBody(),'INTPlaceDetailsAPI','INTPlaceDetails',true,e.getMessage(),null);
        }
        return strResponse;
    }
    
    
    
    //public static string VISUALFORCE_ORIGIN_LABEL = 'VisualForce_Origin';
    /***
    * Method name       : getVisualforceOrigin
    * Description       : Returns a origin domain url for Visualforce page
    * Return Type       : String
    * @Param            : None
    */
    @AuraEnabled(cacheable = true)
    public static string getVisualforceOrigin() {

        
        //String vfOriginSuffix = System.Label.VisualForce_Origin;
        //System.debug('Custom Label VisualForce_Origin = ' + vfOriginSuffix);

        string visualOrigin = '';
        string baseUrl = URL.getOrgDomainUrl().toExternalForm(); 
        if(baseUrl.contains('sandbox')) {
            visualOrigin = baseUrl.split('.sandbox.')[0] + '--c.sandbox.vf.force.com';
        } else {
            visualOrigin = baseUrl.split('.my.')[0] + '--c.visualforce.com';
        }
        System.debug('Code visualOrigin  = ' + visualOrigin);
        return visualOrigin;
        
        //return vfOriginSuffix;

    }
    
    //This wrapper class is used to structure the address object with placeid and description attributes
    public class LookupSearchResult {
        @AuraEnabled public String placeId{get;set;}
        @AuraEnabled public String description{get;set;}
        
        public LookupSearchResult(
            String placeId,
            String description
        ) {
            this.placeId = placeId;
            this.description = description;
        }
    }    
}