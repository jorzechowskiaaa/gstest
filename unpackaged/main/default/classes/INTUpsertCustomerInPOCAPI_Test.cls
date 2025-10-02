/**** Apex Test Class Name:    INTUpsertCustomerInPOCAPI_Test
    * Description         :    This is the test class used to test INTUpsertCustomerInPOCAPI class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla         Oct 04 2021             Created
*********************************************************************************/

@isTest(SeeAllData = false)
public class INTUpsertCustomerInPOCAPI_Test {
    
    /*
   * Method name    : setup
   * Description    : Used to create a record in Integration settings
   * Return Type    : void
   * Parameter      : none
   */
    
    @testSetup static void setup() {
        
        Integration_Settings__c IntegrationSetting = new Integration_Settings__c();
        IntegrationSetting.name = 'UpsertCustomerinPOC_API';
        IntegrationSetting.Method__c='POST';
        IntegrationSetting.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"},{"key":"Content-Type","value":"application/json"},{"key":"source","value":"CRM"}]';
        IntegrationSetting.Named_Credential__c='callout:UpsertCustomerInPOC';
        IntegrationSetting.Path__c='/membership/customer/1.0.0/upsert';
        IntegrationSetting.Request_Timeout__c=120000;
        System.assertEquals(IntegrationSetting.name, 'UpsertCustomerinPOC_API', 'name mismatch');
        Insert IntegrationSetting;
    }
    
    /*
   * Method name    : testupsertCustomer
   * Description    : Used to test a class to upsert a customer
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest(SeeAllData = false)
    static void testupsertCustomer() { 
    Test.startTest();
    String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-09T08:23:48 -0500","tranStatusDescription":"upserted the customer successfully"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"}}';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200)); 
    INTUpsertCustomerInPOCRequest_Wrapper req = INTUpsertCustomerInPOCAPI_Test.createReqWrapper();
    INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(req);
    System.assertEquals(response.responseHeaders.tranCode, '200', 'unsuccessful');
    Test.stopTest();   
    }
    
    /*
   * Method name    : testExceptionDetails
   * Description    : Used to test a class with a scenario of exceptional handling 
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest(SeeAllData = false)
    static void testExceptionDetails() { 
    Test.startTest();
    String res = '';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 500)); 
    INTUpsertCustomerInPOCRequest_Wrapper req = INTUpsertCustomerInPOCAPI_Test.createReqWrapper();
    INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(req);
    System.assertEquals(response.statusCode,500, 'failed');
    Test.stopTest();   
    }
    
    /*
   * Method name    : testBadRequest
   * Description    : Used to test a class with a scenario of bad request
   * Return Type    : void
   * Parameter      : none
   */
    
	@isTest(SeeAllData = false)
    static void testBadRequest() { 
    Test.startTest();
    String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Bad Request"}}';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400)); 
    INTUpsertCustomerInPOCRequest_Wrapper req = INTUpsertCustomerInPOCAPI_Test.createReqWrapper();
    INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(req);
    System.assertEquals(response.responseHeaders.tranCode, '400', 'unsuccessful');
    Test.stopTest();   
    }
    
    /*
   * Method name    : createReqWrapper
   * Description    : Used to create a request wrapper for INTUpsertCustomerInPOCRequest_Wrapper
   * Return Type    : INTUpsertCustomerInPOCRequest_Wrapper
   * Parameter      : none
   */
    
    static INTUpsertCustomerInPOCRequest_Wrapper createReqWrapper(){
        
		INTUpsertCustomerInPOCRequest_Wrapper req = new INTUpsertCustomerInPOCRequest_Wrapper();
        req.ui = '';
        req.hui = '';
        req.prefix = '';
        req.suffix = '';
        req.firstName = 'michael';
        req.lastName = 'ordian';
        req.middleInitial = '';
        req.gender = 'None';

		List<INTUpsertCustomerInPOCRequest_Wrapper.Address> addresses 
            = new List<INTUpsertCustomerInPOCRequest_Wrapper.Address>();
			
        INTUpsertCustomerInPOCRequest_Wrapper.Address ad1 = new INTUpsertCustomerInPOCRequest_Wrapper.Address();
        ad1.addrTypeDetail = 'something';
        ad1.addressLine1 = '2449 LARKWOOD RD';
        ad1.addressLine2 = '';
        ad1.city = 'TITUSVILLE';
        ad1.state = 'FL';
        ad1.zip5 = '32780';
        ad1.zip4 = '1234';
        ad1.declinedVerification = 'NO';
        ad1.latitude = 41.272800;
        ad1.longitude = -72.975200;
        ad1.censusBlock = '5001';
        ad1.deliveryPointBarcode = '378229';
        ad1.deliveryPoint = '912';
        ad1.carrierRoute = 'R001';
        ad1.foreignPostalCode = '500012';
        ad1.foreignCountry = '';
        ad1.stateFIPS = 12;
        ad1.censusTract = '060600';
        addresses.add(ad1);
        
        INTUpsertCustomerInPOCRequest_Wrapper.Address ad2= new INTUpsertCustomerInPOCRequest_Wrapper.Address();
        ad2.addrTypeDetail = 'nothing';
        ad2.addressLine1 = '2449 LARKWOOD RD';
        ad2.addressLine2 = '';
        ad2.city = 'TITUSVILLE';
        ad2.state = 'FL';
        ad2.zip5 = '32780';
        ad2.zip4 = '1234';
        ad2.declinedVerification = 'NO';
        ad2.foreignCountry = '';
        ad2.stateFIPS = 12;
        ad2.censusTract = '060600';
        addresses.add(ad2);
        
        req.address = addresses;
        
        List<INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress> tempaddresses 
                    = new List<INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress>();
                    
        INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress tempadd = new INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress();
        
        tempadd.addressLine1 = '1 Autoclub Dr';
        tempadd.addressLine2 = '';
        tempadd.city = 'DEARBORN';
        tempadd.state = 'MI';
        tempadd.zip5 = '48126';
        tempadd.zip4 = '';
        tempadd.foreignInd = '';
        tempadd.foreignPostalCode = '';
        tempadd.foreignCountry = '';
        tempadd.startDate = '10/10/2020';
        tempadd.endDate = '12/12/2021';
        tempadd.recurringInd = 'N';
        tempadd.tempInd = 'Y';
        tempadd.activeInd = 'Y';
        
        tempaddresses.add(tempadd);
        
        INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress tempadd1 = new INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress();
        
        tempadd1.addressLine1 = '1 Autoclub Dr';
        tempadd1.addressLine2 = '';
        tempadd1.city = 'DEARBORN';
        tempadd1.state = 'MI';
        tempadd1.zip5 = '48126';
        tempadd1.startDate = '10/10/2020';
        tempadd1.endDate = '12/12/2021';
        
        
        
        tempaddresses.add(tempadd1);
        
        req.temporaryAddress = tempaddresses;
        
        List<INTUpsertCustomerInPOCRequest_Wrapper.Phones> phs = new List<INTUpsertCustomerInPOCRequest_Wrapper.Phones>();
        
        INTUpsertCustomerInPOCRequest_Wrapper.Phones p1 = new INTUpsertCustomerInPOCRequest_Wrapper.Phones();
        
        p1.phoneType = 'WORK';
        p1.phoneNumber = '2483638977';
        p1.areaCode = '248';
        
        phs.add(p1);
        
        INTUpsertCustomerInPOCRequest_Wrapper.Phones p2 = new INTUpsertCustomerInPOCRequest_Wrapper.Phones();
        
        p2.phoneType = 'HOME';
        p2.phoneNumber = '2483638978';
        p2.areaCode = '248';
        
        phs.add(p2);
        req.phones = phs;
        
        INTUpsertCustomerInPOCRequest_Wrapper.Agent agent = new INTUpsertCustomerInPOCRequest_Wrapper.Agent();
        
        agent.pId = 'p56789';
        agent.branchCode = 'AOB';
        agent.ipAddress = '0.0.0.0';
        req.agent = agent;
		return req;
    }

}