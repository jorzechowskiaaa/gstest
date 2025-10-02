@isTest
public with sharing class ACG_INTPlacesautocompleteAPICtrlTest {
    @isTest
    static void testGetAddressAutoComplete() {

        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        Integration_Settings__c ObjSetting = new Integration_Settings__c();
        ObjSetting.name = 'Place_AutoComplete_API';
        ObjSetting.Method__c='GET';
        ObjSetting.Enpoint_URL__c='https://maps.googleapis.com/maps/api/place/autocomplete/json?components=country:us|country:in&input=';
        ObjSetting.Request_Timeout__c=120000;
        
        insert ObjSetting;        

        String result = ACG_INTPlacesautocompleteAPIController.getAddressAutoComplete('3333 Fairview Rd Costa Mesa CA 92626');
        System.assert(result != null);
    }
    
}