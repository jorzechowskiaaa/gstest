/**** Apex Class Name    :    INTAddressValidationAPI_Test
    * Description        :    Test class for INTAddressValidationAPI class  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Saumya              		Oct 4 2021             Created
*********************************************************************************/
@isTest
public class INTAddressValidationAPI_Test {
    
   /*
   * Method name    : setup
   * Description    : Used to create Integration settings test records
   * Return Type    : void
   * Parameter      : none
   */
    @testSetup static void setup() {
        Integration_Settings__c IntegrationSetting = new Integration_Settings__c();
        IntegrationSetting.name = 'Address_Validation_API';
        IntegrationSetting.Method__c='POST';
		IntegrationSetting.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"}, {"key":"Content-Type","value":"application/json"}, {"key":"source","value":"DRR"}]';
        IntegrationSetting.Named_Credential__c='callout:AddressValidation';
        IntegrationSetting.Path__c='/membership/1.0.0/address/validation';
        IntegrationSetting.Enpoint_URL__c='';
        IntegrationSetting.Request_Timeout__c=120000;
        System.assertEquals(IntegrationSetting.name, 'Address_Validation_API', 'name mismatch');
        Insert IntegrationSetting;
    }
    
    /*
   * Method name    : testvalidateaddress
   * Description    : Used to test validate address success scenario.
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest (SeeAllData = false)
    static void testvalidateaddress() {
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Retrieved the Address Details"},"membershipAddress":{"addressLine1":"100 main street","addressLine2":"Apt 234","city":"Charlotte","state":"NC","zip5":"12331","zip4":"1233","latitude":28.26,"longitude":29.26,"censusBlock":"TBD","deliveryPointBarcode":"TBD","deliveryPoint":290,"carrierRoute":"R049","stateFIPS":13,"countryFIPS":117,"censusTract":"130410"}}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 
		INTAddressValidationRequest_Wrapper req = INTAddressValidationAPI_Test.createReqWrapper();
        INTAddressValidationResponse_Wrapper responseWrapper= INTAddressValidationAPI.validateAddress(req);
        System.assertEquals( 200,responseWrapper.statusCode, 'unsuccessful');
        Test.stopTest();
    }
    
    /*
   * Method name    : testBadRequest
   * Description    : Used to test bad request.
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest (SeeAllData = false)
    static void testBadRequest() {
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Bad Request"}}';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,400,'Bad request'));
		INTAddressValidationRequest_Wrapper req = INTAddressValidationAPI_Test.createReqWrapper();
        INTAddressValidationResponse_Wrapper responseWrapper= INTAddressValidationAPI.validateAddress(req);
        System.assertEquals(400,responseWrapper.statusCode, 'unsuccessful');
        Test.stopTest();
    }
    
    /*
   * Method name    : testExceptionDetails
   * Description    : Used to test internal server error.
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest (SeeAllData = false)
    static void testExceptionDetails() {
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"500","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Internal Server Error"}}';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 
		INTAddressValidationRequest_Wrapper req = INTAddressValidationAPI_Test.createReqWrapper();
        INTAddressValidationResponse_Wrapper responseWrapper= INTAddressValidationAPI.validateAddress(req);
        System.assertEquals( 500,responseWrapper.statusCode, 'failed');
        Test.stopTest();
    }
	
    /*
   * Method name    : getExceptionLog
   * Description    : Used to test exceptional scenario.
   * Return Type    : void
   * Parameter      : none
   */
    
	@isTest (SeeAllData = false)
    static void getExceptionLog() {
        Test.startTest();
        String res = '';
       	Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 
		INTAddressValidationRequest_Wrapper req = INTAddressValidationAPI_Test.createReqWrapper();
        INTAddressValidationResponse_Wrapper responseWrapper= INTAddressValidationAPI.validateAddress(req);
        System.assertEquals(500,responseWrapper.statusCode, 'failed');
        Test.stopTest();
    }

    /*
   * Method name    : createReqWrapper
   * Description    : Used to create a request wrapper.
   * Return Type    : INTAddressValidationRequest_Wrapper
   * Parameter      : none
   */
    
    static INTAddressValidationRequest_Wrapper createReqWrapper(){
        
        INTAddressValidationRequest_Wrapper req = new INTAddressValidationRequest_Wrapper();
        
        req.addressLine1 = 'test street 1';
        req.addressLine2 = 'cout 123';
        req.city = 'test city';
        req.state = 'test state';
        req.zip5 = '123';
		return req ; 
	}
	
}