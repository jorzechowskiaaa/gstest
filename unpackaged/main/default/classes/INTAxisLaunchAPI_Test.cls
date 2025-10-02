/**** Apex Test Class Name:    INTAxisLaunchAPI_Test
    * Description         :    This is the test class used to test INTAxisLaunchAPI class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla          Oct 18 2021             Created
*********************************************************************************/

@isTest(SeeAllData = false)
public class INTAxisLaunchAPI_Test {
    
    /*
   * Method name    : setup
   * Description    : Used to create a record in Integration settings
   * Return Type    : void
   * Parameter      : none
   */
    
    @testSetup static void setup() {
        
        Integration_Settings__c IntegrationSetting = new Integration_Settings__c();
        IntegrationSetting.name = 'AXISlaunch_API';
        IntegrationSetting.Method__c='POST';
        IntegrationSetting.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"},{"key":"Content-Type","value":"application/json"},{"key":"source","value":"CRM"}]';
        IntegrationSetting.Named_Credential__c='callout:AxisLaunch';
        IntegrationSetting.Path__c='/travel/axis/1.0.0/trip';
        IntegrationSetting.Request_Timeout__c=120000;
        System.assertEquals(IntegrationSetting.name, 'AXISlaunch_API', 'name mismatch');
        Insert IntegrationSetting;
    }

    /*
   * Method name    : testLaunchAxisWithOpportunityId
   * Description    : Used to launch AXIS application with opportunity Id
   * Return Type    : void
   * Parameter      : none
   */
    
	@isTest(SeeAllData = false)
    static void testLaunchAxisWithOpportunityId() { 
    Test.startTest();
    String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Success"}}';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200)); 
    INTAxisLaunchResponse_Wrapper response = INTAxisLaunchAPI.axisLaunch('P73610','ENTRY','1000170413','','00605000004tVXaAAM','','POS','TPOS');
    System.assertEquals(response.responseHeaders.tranCode, '200', 'unsuccessful');
    Test.stopTest();   
    }
    
    /*
   * Method name    : testLaunchAxisWithoutOpportunityId
   * Description    : Used to launch AXIS application without opportunity Id
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest(SeeAllData = false)
    static void testLaunchAxisWithoutOpportunityId() { 
    Test.startTest();
    String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Success"}}';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200)); 
    INTAxisLaunchResponse_Wrapper response = INTAxisLaunchAPI.axisLaunch('P73610','ENTRY','1000170413','','','','POS','TPOS');
    System.assertEquals(response.responseHeaders.tranCode, '200', 'unsuccessful');
    Test.stopTest();   
    }
    
    /*
   * Method name    : testBadRequest
   * Description    : Used to test bad request
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest(SeeAllData = false)
    static void testBadRequest() { 
    Test.startTest();
    String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Bad Request"}}';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400)); 
    INTAxisLaunchResponse_Wrapper response = INTAxisLaunchAPI.axisLaunch('P73610','ENTRY','1000170413','','','','POS','TPOS');
    System.assertEquals(response.responseHeaders.tranCode, '400', 'unsuccessful');
    Test.stopTest();   
    }
    
    /*
   * Method name    : testExceptionDetails
   * Description    : Used to test exceptions
   * Return Type    : void
   * Parameter      : none
   */
    
    @isTest(SeeAllData = false)
    static void testExceptionDetails() { 
    Test.startTest();
    String res = '';
    Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 500)); 
    INTAxisLaunchResponse_Wrapper response = INTAxisLaunchAPI.axisLaunch('P73610','ENTRY','1000170413','','','','POS','TPOS');
    System.assertEquals(response.statusCode,500, 'failed');
    Test.stopTest();   
    }
}