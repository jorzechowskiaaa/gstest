@isTest
public class IntegrationUtilTest {
    
    // USED TO BUILD THE REQUEST OBJECT FOR TESTING
    public class ObjRequest {
        public String key1 {get;set;}
        public String key2 {get;set;}
        public String key3 {get;set;}
        public String key4 {get;set;}
    }
    
    @testSetup
    public static void testSetup(){
        
        createEmailTemplate();
        
        Integration_Settings__c setting = new Integration_Settings__c();
        setting.Name = 'Test Setting';
        setting.Method__c = 'GET';
        setting.Enpoint_URL__c = 'www.test.com';
        setting.Path__c = '/test';
        setting.Extra_Header_Value__c = '[{"key":"Authorization","value":"Bearer:kj93lkjlksfj"}]';
        setting.Named_Credential__c = 'Test_Cred';
        setting.Request_Timeout__c = 12;
        setting.Path__c = 'Test_Path';
        setting.Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]';
        insert setting;
        
        Account testAcct = new Account(Name='Test Account');
        insert testAcct;
        
        Case testCase = new Case();
        testCase.SuppliedName = 'Test User';
        testCase.SuppliedEmail = 'test@gmail.com';
        testCase.AccountId = testAcct.Id;
        insert testCase;
    }
    
    @future
    public static void createEmailTemplate(){
        EmailTemplate testTemp = new EmailTemplate();
        testTemp.Body = 'This is a test template';
        testTemp.DeveloperName = 'Test_Template';
        testTemp.IsActive = true;
        testTemp.Subject = 'Test';
        testTemp.Name = 'Test';
        testTemp.FolderId = UserInfo.getUserId();
        testTemp.TemplateType = 'custom';
        insert testTemp;
    }
    
    @isTest // NEED TO REWORK TO INCLUDE MOCK CALLOUT CODE
    public static void testMakeCallout(){
        
        Integration_Settings__c objSetting = [SELECT Id, Header_Value__c, Named_Credential__c,
                                              Request_TimeOut__c, Path__c, Extra_Header_Value__c,
                                              Enpoint_Url__c, Method__c, Name
                                              FROM Integration_Settings__c LIMIT 1];
        
        HttpRequest objRequest = IntegrationUtil.prepareRequest(objSetting);
        Test.setMock(HttpCalloutMock.class, new IntegrationUtilCalloutMock());
        Test.startTest();
        	HttpResponse res = IntegrationUtil.makeCallout(objRequest);
        Test.stopTest();
        
        system.debug('response --> ' + res);
    }
    
    @isTest
    public static void testPrepareRequestWithOnlyIntegrationSettings(){
        
        Integration_Settings__c objSetting = [SELECT Id, Header_Value__c, Named_Credential__c,
                                              Request_TimeOut__c, Path__c, Extra_Header_Value__c,
                                              Enpoint_Url__c, Method__c, Name
                                              FROM Integration_Settings__c LIMIT 1];
        
        Test.startTest();
        	HttpRequest httpReq = IntegrationUtil.prepareRequest(objSetting);
        Test.stopTest();
        
        system.debug('request ' + httpReq);
        
    }
    
    @isTest
    public static void testPrepareRequestWithIntSettingsObjReqSuppressApexObjNulls(){
        
        ObjRequest objReq = new ObjRequest();
        objReq.key1 = 'Test Value 1';
        objReq.key2 = 'Test Value 2';
        objReq.key3 = 'Test Value 3';
        objReq.key4 = 'Test Value 4';
        
        Integration_Settings__c objSetting = [SELECT Id, Header_Value__c, Named_Credential__c,
                                              Request_TimeOut__c, Path__c, Extra_Header_Value__c,
                                              Enpoint_Url__c, Method__c, Name
                                              FROM Integration_Settings__c LIMIT 1];
        
        Test.startTest();
        	HttpRequest httpReq = IntegrationUtil.prepareRequest(objSetting,objReq,true);
        Test.stopTest();
        
        String expectedBody = '{"key4":"Test Value 4","key3":"Test Value 3","key2":"Test Value 2","key1":"Test Value 1"}';
        
        system.assertEquals(httpReq.getBody(), expectedBody);
        Assert.IsNotNull(httpReq);
        Assert.IsNotNull(httpReq.getBody());
    }
    
    @isTest
    public static void testPrepareRequestWithIntSettingsObjReq(){
        
        ObjRequest objReq = new ObjRequest();
        objReq.key1 = 'Test Value 1';
        objReq.key2 = 'Test Value 2';
        objReq.key3 = 'Test Value 3';
        objReq.key4 = 'Test Value 4';
        
        Integration_Settings__c objSetting = [SELECT Id, Header_Value__c, Named_Credential__c,
                                              Request_TimeOut__c, Path__c, Extra_Header_Value__c,
                                              Enpoint_Url__c, Method__c, Name
                                              FROM Integration_Settings__c LIMIT 1];
        
        Test.startTest();
        	HttpRequest httpReq = IntegrationUtil.prepareRequest(objSetting,objReq);
        Test.stopTest();
        
        String expectedBody = '{"key4":"Test Value 4","key3":"Test Value 3","key2":"Test Value 2","key1":"Test Value 1"}';
        
        system.assertEquals(httpReq.getBody(), expectedBody);
        Assert.IsNotNull(httpReq);
        Assert.IsNotNull(httpReq.getBody());
    }
    
    @isTest
    public static void testGenerateUniqueId(){
        String uniqueId = IntegrationUtil.generateUniqueId();
        Assert.isNotNull(uniqueId);
        Assert.isInstanceOfType(uniqueId,String.class);
    }
    
    @isTest
    public static void testGetIntegrationSettings(){
        
        Test.startTest();
        	Map<String,Integration_Settings__c> results = IntegrationUtil.getIntegrationSettings();
        Test.stopTest();
        
        system.assertEquals(results.keySet().size(),1);
    }
    
    @isTest
    public static void testGetHeaderValue(){
        List<Integration_Settings__c> isList = [SELECT Id, Header_Value__c FROM Integration_Settings__c];
             
        Test.startTest();
        	Map<String,String> parsedHeader = IntegrationUtil.getHeaderValue(isList[0].Header_Value__c);
        Test.stopTest();
        
        // IF MORE HEADERS ARE ADDED TO INTEGRATION SETTINGS IN TEST SETUP, THIS WILL NEED TO CHANGE OR TEST WILL FAIL
        system.assertEquals(parsedHeader.keySet().size(), 1); 
    }
	
    @isTest
    public static void testSendEmail(){
        
        INTSendEmailRequest_Wrapper emailReqWrapper = new INTSendEmailRequest_Wrapper();
        emailReqWrapper.toAddresses = new List<String>{'test@gmail.com'};
		emailReqWrapper.saveAsActivity = false;
        emailReqWrapper.senderDisplayName = 'Test User';
       	emailReqWrapper.targetObjectId = UserInfo.getUserId();
        emailReqWrapper.treatTargetObjectAsRecipient = false;
        emailReqWrapper.templateName = 'Test_Template';
       
        Test.startTest();
        	IntegrationUtil.sendEmail(emailReqWrapper);
        	Integer numEmailSent = Limits.getEmailInvocations();
        Test.stopTest();
        
        system.assertEquals(numEmailSent,1);
    }
}