@isTest
public class FSL_INTRepairShopOutboundTest {
    
    private class RestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req){
            String fullJson = '{"access_token":"1234","data":{"statusCode":200,"code":"E200","message":"success"}}';  
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            res.setStatus('OK');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @testSetup
    public static void testSetup(){
        
        Integration_Settings__c nationalOAuthAPI = new Integration_Settings__c();
        nationalOAuthAPI.Name = 'National_OAuth_API';
        nationalOAuthAPI.Method__c = 'POST';
        nationalOAuthAPI.Enpoint_URL__c = 'https://api-qa.national.aaa.com/common/oauth2/token';        
        nationalOAuthAPI.Extra_Header_Value__c = 'grant_type=client_credentials&client_id=1234&client_secret=4565';
        nationalOAuthAPI.Request_Timeout__c = 120000;
        nationalOAuthAPI.Header_Value__c = '[{"key":"Content-Type","value":"application/x-www-form-urlencoded"}]';
        insert nationalOAuthAPI;
        
        Integration_Settings__c repairShopOutboundAPI = new Integration_Settings__c();
        repairShopOutboundAPI.Name = 'RepairShop_Outbound_API';
        repairShopOutboundAPI.Method__c = 'POST';
        repairShopOutboundAPI.Enpoint_URL__c = 'https://api-qa.national.aaa.com/automotive/services/ci/v1/rsp/orders';        
        repairShopOutboundAPI.Request_Timeout__c = 120000;
        repairShopOutboundAPI.Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]';
        insert repairShopOutboundAPI;
        
        Integration_Settings__c testSetting = new Integration_Settings__c();
        testSetting.Name = 'Test Setting';
        testSetting.Method__c = 'GET';
        testSetting.Enpoint_URL__c = 'www.test.com';
        testSetting.Path__c = '/test';
        testSetting.Extra_Header_Value__c = '[{"key":"Authorization","value":"Bearer:kj93lkjlksfj"}]';
        testSetting.Named_Credential__c = 'Test_Cred';
        testSetting.Request_Timeout__c = 12;
        testSetting.Path__c = 'Test_Path';
        testSetting.Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]';
        insert testSetting;
        
        Account testAcct = new Account();
        testAcct.Name = 'Test Acct';
        insert testAcct;
        
        Case testCase = new Case();
        testCase.ACG_Vehicle_Location_Address__c = '153 Midland Ave, East Orange, NJ 07017, USA';
        testCase.Tow_Geolocation__Longitude__s = -74.0919171;
        testCase.Tow_Geolocation__Latitude__s = 40.885276;
        testCase.Source__c = 'Salesforce';
        testCase.ACG_Year__c = '2024';
        testCase.ACG_Model__c = 'Sierra 1500';
        testCase.ACG_Make__c = 'GMC';
        testCase.Vehicle_Location_Street__c = '6455 W Archer Ave';
        testCase.Vehicle_Location_City__c = 'Chicago';
        testCase.Vehicle_Location_Postal_Code__c = '60638';
        testCase.Vehicle_Location_Country__c = 'USA';
        insert testCase;
        
        WorkOrder testWO = new WorkOrder();
        testWO.CaseId = testCase.Id;
        testWO.AccountId = testAcct.Id;
        insert testWO;
    }
    
    @isTest
    public static void testFetchCase(){
        Id caseId = [SELECT Id FROM Case WHERE Source__c = 'Salesforce'].Id;
        
        Test.startTest();
            
            Case response = FSL_INTRepairShopOutbound.fetchCase(caseId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, response);
    }
    
    @isTest
    public static void testGenerateRepairShopRequest(){
        Id caseId = [SELECT Id FROM Case WHERE Source__c = 'Salesforce'].Id;
        Id workOrderId = [SELECT Id FROM WorkOrder WHERE Case.Source__c = 'Salesforce'].Id;
        
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        
            FSL_INTRepairShopOutbound.generateRepairShopRequest(CaseId, workOrderId);
        
        Test.stopTest();
        
        List<FSL_Application_Log__c> logs = [SELECT Id, Name, API_Name__c, Operation__c, Response_Body__c, 
                                             Request_Body__c, Success_Message__c, Success_Record_Count__c, 
                                             Type__c, Work_Order__c 
                                             FROM FSL_Application_Log__c
                                             WHERE Operation__c = 'National Repair Shop'];
        system.debug('logs >> ' + logs);
        system.assertEquals('National Repair Shop Outbound API - Success', logs[0].API_Name__c);
    }
    
}