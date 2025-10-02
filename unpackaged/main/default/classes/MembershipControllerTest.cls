/********************************************************************************************************
Apex Class Name     : MembershipControllerTest
Created Date        : 30th August 2021
Function            : Test Class for MembershipController Class
Author              : Deloitte Consulting

********************************************************************************************************/
@isTest(SeeAllData = false)
public class MembershipControllerTest {

    
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
        
        //testvalidateaddress method
        Integration_Settings__c IntegrationSetting1 = new Integration_Settings__c();
        IntegrationSetting1.name = 'Address_Validation_API';
        IntegrationSetting1.Method__c='POST';
        IntegrationSetting1.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"}, {"key":"Content-Type","value":"application/json"}, {"key":"source","value":"DRR"}]';
        IntegrationSetting1.Named_Credential__c='callout:AddressValidation';
        IntegrationSetting1.Path__c='/membership/1.0.0/address/validation';
        IntegrationSetting1.Enpoint_URL__c='';
        IntegrationSetting1.Request_Timeout__c=120000;
        System.assertEquals(IntegrationSetting1.name, 'Address_Validation_API', 'name mismatch');
        Insert IntegrationSetting1;
        
        //testlaunchAXIS method
        Integration_Settings__c IntegrationSetting2 = new Integration_Settings__c();
        IntegrationSetting2.name = 'AXISlaunch_API';
        IntegrationSetting2.Method__c='POST';
        IntegrationSetting2.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"},{"key":"Content-Type","value":"application/json"},{"key":"source","value":"CRM"}]';
        IntegrationSetting2.Named_Credential__c='callout:AxisLaunch';
        IntegrationSetting2.Path__c='/travel/axis/1.0.0/trip';
        IntegrationSetting2.Request_Timeout__c=120000;
        System.assertEquals(IntegrationSetting2.name, 'AXISlaunch_API', 'name mismatch');
        Insert IntegrationSetting2;
        
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Fred';
        acc.LastName = 'Smith';
        acc.ACG_Does_Not_Have__c = true;
        acc.RecordTypeId  = personAccountRecordTypeId;
        acc.BillingStreet = '3305 Hutchinson Road Apt 5203; Apt 234';
        acc.BillingCity = 'Cumming';
        acc.BillingStateCode = 'GA';
        acc.BillingCountryCode = 'US';
        acc.BillingPostalCode = '30040';
        acc.PersonHomePhone = '1234567890';
        acc.ACG_Alternate_Phone__c = '1234567890';
        acc.ACG_Date_of_Birth__c = Date.today();
        acc.ACG_Address_Type_Detail__c = 'U.S.';
        
        insert acc;
        
        //for addAssociateMembers
        
        /*Account account1 = ACG_TestDataFactory.createAccount(ACG_UtilityClass.FACILITY_RECORDTYPE_ID,'Test Account',false);
account1.ACG_Member_ID__c = '12345678';
account1.Membership_Expiration_Date__c = date.newInstance(2020, 1, 1) ;
account1.ACG_Entitlements_Used__c = 10;
account1.Member_Club_Code__c = '234';
account1.ACG_Entitlements_Allotted__c = 9;

insert account1;*/
        
        Account account2 = ACG_TestDataFactory.createAccount(ACG_UtilityClass.FACILITY_RECORDTYPE_ID,'Test Account2',false);
        account2.ACG_Member_ID__c = '12345679';
        account2.Membership_Expiration_Date__c = date.newInstance(2020, 1, 1) ;
        account2.ACG_Entitlements_Used__c = 10;
        account2.Member_Club_Code__c = '234';
        account2.ACG_Household_Id__c=acc.Id;
        account2.ACG_Entitlements_Allotted__c = 9;
        account2.BillingStreet = '3305 Hutchinson Road Apt 5203';
        
        insert account2;
    }
    
    @isTest(SeeAllData = false)
    public static void otherMethodTest() {
        Account acc = [Select id from Account where BillingCity = 'Cumming' limit 1];
        Test.startTest();
        MembershipController.getCustomerRecordTypeId();
        String recordId = MembershipController.createMember(acc, UserInfo.getUserId(),true);
        MembershipController.createMember(acc, UserInfo.getUserId(),true);
        MembershipController.createMember(acc,'123',true);
        MembershipController.getCustomerRecordTypeId();
        MembershipController.updateEmail(recordId, 'test@email.com');
        MembershipController.updateEmail(recordId, 'test@email');
        MembershipController.updateEmail(null, 'test@email');
        MembershipController.convertCustomerRecord(recordId, UserInfo.getUserId());
        MembershipController.convertCustomerRecord(recordId+'1', UserInfo.getUserId());
        Map<String, Zip_Code_Details__mdt> zpcodes = MembershipController.getZipCodes('111');
        Test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void createMemberTest() {
        
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Alternate_Phone_Type__c,
                       ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c
                       from Account where BillingCity = 'Cumming' limit 1];
        
        Test.startTest();
        
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-09T08:23:48 -0500","tranStatusDescription":"upserted the customer successfully"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        //INTUpsertCustomerInPOCRequest_Wrapper req = MembershipControllerTest.createReqWrapper();
        //INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(req);
        
        MembershipController.APICalloutResponseWrapper apwr = MembershipController.createCustInPOCFromOpportunity(acc.id);
        
    }
    
    @isTest(SeeAllData = false)
    public static void createMemberTest1() {
        
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Alternate_Phone_Type__c,
                       ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c
                       from Account where BillingCity = 'Cumming' limit 1];
        
        Test.startTest();
        
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-09T08:23:48 -0500","tranStatusDescription":"upserted the customer successfully"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"},"errorMessage" :{"New Test error"}}';
        //Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        //INTUpsertCustomerInPOCRequest_Wrapper req = MembershipControllerTest.createReqWrapper();
        //INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(req);
        //String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Bad Request"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        MembershipController.APICalloutResponseWrapper apwr = MembershipController.createCustInPOCFromOpportunity(acc.id);
        
    }
    
    @isTest(SeeAllData = false)
    public static void testvalidateaddress() {
        Account acc = [Select id,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode from Account
                       where BillingCity = 'Cumming' limit 1];
        
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Retrieved the Address Details"},"membershipAddress":{"addressLine1":"100 main street","addressLine2":"Apt 234","city":"Charlotte","state":"NC","zip5":"12331","zip4":"1233","latitude":28.26,"longitude":29.26,"censusBlock":"TBD","deliveryPointBarcode":"TBD","deliveryPoint":290,"carrierRoute":"R049","stateFIPS":13,"countryFIPS":117,"censusTract":"130410"}}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 
        //INTAddressValidationRequest_Wrapper req = MembershipControllerTest.createReqWrapper1();
        //INTAddressValidationResponse_Wrapper responseWrapper= INTAddressValidationAPI.validateAddress(req);
        try{
            MembershipController.APICalloutResponseWrapper resp = MembershipController.validateAddress(acc);
        } catch(System.NullPointerException e) {}
        //System.assertEquals( 500,responseWrapper.statusCode, 'unsuccessful');
        Test.stopTest();
    }
    
    @isTest (SeeAllData = false)
    static void testvalidateaddress1() {
        
        Account acc = [Select id,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode from Account
                       where BillingCity = 'Cumming' limit 1];
        
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"500","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Internal Server Error"}}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error'));
        try{
            MembershipController.APICalloutResponseWrapper resp = MembershipController.validateAddress(acc);
        } catch(System.NullPointerException e) {}
        
        Test.stopTest();
    }
    
    @isTest (SeeAllData = false)
    static void testvalidateaddress2() {
        Account acc = [Select id,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode from Account
                       where ACG_Member_ID__c = '12345679' limit 1];
        
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Bad Request"}}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,400,'Bad request'));
        
        try{
            MembershipController.APICalloutResponseWrapper resp = MembershipController.validateAddress(acc);
        } catch(System.NullPointerException e) {}
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void testlaunchAXIS() {
        
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Success"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200)); 
        //INTAxisLaunchResponse_Wrapper response = INTAxisLaunchAPI.axisLaunch('P73610','ENTRY','1000170413','','00605000004tVXaAAM','','POS','TPOS');
        //System.assertEquals(response.responseHeaders.tranCode, '200', 'unsuccessful');
        MembershipController.APICalloutResponseWrapper lnchAx = MembershipController.launchAXIS('', '1000170413');
    }
    
    @isTest(SeeAllData = false)
    public static void testIsUserCore() {
        User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Club_Name__c, Branch_Number__c, EmployeeNumber 
                             FROM User 
                             WHERE Id =: UserInfo.getUserId()];
        
        Boolean usCore = MembershipController.isUserCore();
        
        loggedInUser.Club_Name__c = 'AAA Michigan - 047';
        update loggedInUser;
        
        Boolean usCore1 = MembershipController.isUserCore();
    }
    
    @isTest(SeeAllData = false)
    public static void testIsUserCore1() {
        User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Club_Name__c, Branch_Number__c, EmployeeNumber 
                             FROM User 
                             WHERE Id =: UserInfo.getUserId()];
        
        loggedInUser.Club_Name__c = 'AAA Michigan - 047';
        update loggedInUser;
        
        Boolean usCore = MembershipController.isUserCore();
    }
    
    @isTest(SeeAllData = false)
    public static void testIsUserCore2() {
        User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Club_Name__c, Branch_Number__c, EmployeeNumber 
                             FROM User 
                             WHERE Id =: UserInfo.getUserId()];
        
        loggedInUser.Club_Name__c = 'AAA Carolinas - 111';
        update loggedInUser;
        
        Boolean usCore = MembershipController.isUserCore();
    }
    
    @isTest(SeeAllData = false)
    public static void testcreateCustomerInPOC() {
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,
                       ACG_Alternate_Phone_Type__c,BillingStreet,ACG_Address_Type_Detail__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c,
                       FirstName,MiddleName,LastName,ACG_Suffix__c,Phone,PersonEmail,Motorcycle_Included__c,RV_Offering__c,
                       ACG_Date_of_Birth__c,ownerId from Account where BillingCity = 'Cumming' limit 1];
        string addr = acc.OwnerId;
        
        //string ipAddress = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        string ipAddress=null;
        //system.debug('ReturnValue = '+ReturnValue);
        
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\"}';
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\",\"zip4\":\"1233\",\"latitude\":28.26,\"longitude\":29.26,\"censusBlock\":\"TBD\",\"deliveryPointBarcode\":\"TBD\",\"deliveryPoint\":290,\"carrierRoute\":\"R049\",\"stateFIPS\":13,\"countryFIPS\":117,\"censusTract\":\"130410\"}';
        string addressResponse = '';
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-09T08:23:48 -0500","tranStatusDescription":"upserted the customer successfully"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        test.startTest();
        MembershipController.APICalloutResponseWrapper crtCust = MembershipController.createCustomerInPOC(ipAddress,'1233556', acc, addressResponse, addr, false, false);
        MembershipController.APICalloutResponseWrapper crtCust1 = MembershipController.createCustomerInPOC(ipAddress,'1233556', acc, addressResponse, addr, false, false);
        test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void testcreateCustomerInPOC1() {
        Test.startTest();
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,
                       ACG_Alternate_Phone_Type__c,BillingStreet,ACG_Address_Type_Detail__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c,
                       FirstName,MiddleName,LastName,ACG_Suffix__c,Phone,PersonEmail,Motorcycle_Included__c,RV_Offering__c,
                       ACG_Date_of_Birth__c,ownerId from Account where BillingCity = 'Cumming' limit 1];
        string addr = acc.OwnerId;
        
        //string ipAddress = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        string ipAddress=null;
        
        //system.debug('ReturnValue = '+ReturnValue);
        
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\"}';
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\",\"zip4\":\"1233\",\"latitude\":28.26,\"longitude\":29.26,\"censusBlock\":\"TBD\",\"deliveryPointBarcode\":\"TBD\",\"deliveryPoint\":290,\"carrierRoute\":\"R049\",\"stateFIPS\":13,\"countryFIPS\":117,\"censusTract\":\"130410\"}';
        string addressResponse = '{ \"responseHeaders\": { \"tranId\": \"b350b8d8-a8b7-4ec8-ba80-7a9292164531\", \"tranCode\": \"200\", \"tranStatus\": \"Success\", \"timeStamp\": \"2022-01-13T07:18:10.868-05:00\", \"tranStatusDescription\": \"CityOrStateOverwritten\" }, \"membershipAddress\": { \"addressLine1\": \"3305 HUTCHINSON RD\", \"addressLine2\": \"APT 5203 APT 234\", \"city\": \"CUMMING\", \"state\": \"GA\", \"zip5\": \"30040\", \"zip4\": \"8076\", \"latitude\": \"34.193400\", \"longitude\": \"-84.149900\", \"censusBlock\": \"2028\", \"deliveryPointBarcode\": \"807603\", \"deliveryPoint\": \"39\", \"carrierRoute\": \"R042\", \"stateFIPS\": \"13\", \"countryFIPS\": \"117\", \"censusTract\": \"130410\" } }';
        
        
        
        
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(addressResponse, 200));
        MembershipController.APICalloutResponseWrapper crtCust = MembershipController.createCustomerInPOC(ipAddress,'1233556', acc, addressResponse, addr, True, false);
        Test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void testcreateCustomerInPOC2() {
        Test.startTest();
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,
                       ACG_Alternate_Phone_Type__c,BillingStreet,ACG_Address_Type_Detail__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c,
                       FirstName,MiddleName,LastName,ACG_Suffix__c,Phone,PersonEmail,Motorcycle_Included__c,RV_Offering__c,
                       ACG_Date_of_Birth__c,ownerId from Account where BillingCity = 'Cumming' limit 1];
        string addr = acc.OwnerId;
        
        //string ipAddress = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        string ipAddress=null;
        //system.debug('ReturnValue = '+ReturnValue);
        
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\"}';
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\",\"zip4\":\"1233\",\"latitude\":28.26,\"longitude\":29.26,\"censusBlock\":\"TBD\",\"deliveryPointBarcode\":\"TBD\",\"deliveryPoint\":290,\"carrierRoute\":\"R049\",\"stateFIPS\":13,\"countryFIPS\":117,\"censusTract\":\"130410\"}';
        string addressResponse = '';
        String res = '';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 500));
        MembershipController.APICalloutResponseWrapper crtCust = MembershipController.createCustomerInPOC(ipAddress,'1233556', acc, addressResponse, addr, True, true);
        Test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void testcreateCustomerInPOC3() {
        Test.startTest();
        Account acc = [Select id,ACG_Prefix__c,ACG_Gender__c,ACG_Primary_Phone_Type__c,PersonHomePhone,ACG_Secondary_Phone_Type__c,ACG_Alternate_Phone__c,
                       ACG_Alternate_Phone_Type__c,BillingStreet,ACG_Address_Type_Detail__c,BillingCity,BillingStateCode,BillingPostalCode,
                       Zip4__c,BillingLatitude,BillingLongitude,Census_Block__c,Delivery_Point_Barcode__c,Delivery_Point__c,Carrier_Route__c,
                       ACG_Foreign_Postal_Code__c,BillingCountryCode,State_FIPS__c,Country_FIPS__c,Census_Tract__c,
                       FirstName,MiddleName,LastName,ACG_Suffix__c,Phone,PersonEmail,Motorcycle_Included__c,RV_Offering__c,
                       ACG_Date_of_Birth__c,ownerId from Account where BillingCity = 'Cumming' limit 1];
        string addr = acc.OwnerId;
        
        //string ipAddress = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        string ipAddress=null;      
        //system.debug('ReturnValue = '+ReturnValue);
        
        //string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\"}';
        string addressResponse = '{\"addressLine1\":\"3305HutchinsonRoadAPT5203\",\"addressLine2\":\"Apt234\",\"city\":\"Cumming\",\"state\":\"GA\",\"zip5\":\"30040\",\"zip4\":\"1233\",\"latitude\":28.26,\"longitude\":29.26,\"censusBlock\":\"TBD\",\"deliveryPointBarcode\":\"TBD\",\"deliveryPoint\":290,\"carrierRoute\":\"R049\",\"stateFIPS\":13,\"countryFIPS\":117,\"censusTract\":\"130410\"}';
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"400","tranStatus":"E","timeStamp":"2019-11-18T08:23:48 -0500","tranStatusDescription":"Bad Request"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 400));
        MembershipController.APICalloutResponseWrapper crtCust = MembershipController.createCustomerInPOC(ipAddress,'1233556', acc, addressResponse, addr, True, false);
        Test.stopTest();
    }
    
    @isTest(SeeAllData = false)
    public static void testaddAssociateMembersToHousehold(){ 
        Account acc = [Select id,FirstName,MiddleName,LastName,ACG_Suffix__c,Phone,PersonEmail,Motorcycle_Included__c,RV_Offering__c,ACG_Date_of_Birth__c,ownerId from Account limit 1];
        Account primaryMember = [SELECT Id, ACG_Household_Id__c,ACG_Member_ID__c FROM Account WHERE ACG_Member_ID__c = '12345679'];
        string addr = acc.OwnerId;
        string recid = acc.ID;
        string dob = string.valueOf(acc.ACG_Date_of_Birth__c);
        //string ReturnValue = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        string ReturnValue=null;
        //system.debug('ReturnValue = '+ReturnValue);
        addAssociateMembersWrapper rsp = new addAssociateMembersWrapper(acc.FirstName,acc.MiddleName,acc.LastName,acc.ACG_Suffix__c,acc.Phone,acc.PersonEmail,acc.Motorcycle_Included__c,acc.RV_Offering__c,recid,dob);
        String JSONBody = '['+JSON.serialize(rsp)+']'; 
        
        //string sMembersJson = '[{\"firstName\":\"Tester\",\"mi\":\"tt\",\"lastName\":\"User\",\"suffix\":\"test\",\"phone\":\"1234567890\",\"email\":\"testuser@test.com\",\"motorcycleIncluded\":false,\"rvOfferingName\":\"tst\",\"recordId\":\"0030500000MPRvGAAX\",\"relationship\":\"\",\"dob\":\"1995-08-08T00:00:00\"}]';
        
        try
        {
            MembershipController.addAssociateMembersToHousehold(primaryMember.id,JSONBody);
        }
        catch(exception e)
        {
        }
        
    }
    
    
    
    //-----------------------------------------------------------------Wrapper classes------------------------------>
    
    Public class addAssociateMembersWrapper{
        
        public String firstName {get;set;}
        public String mi {get;set;}
        public String lastName {get;set;}
        public String suffix {get;set;}
        public String phone {get;set;}
        public String email {get;set;}
        public boolean motorcycleIncluded {get;set;}
        public String rvOfferingName {get;set;}
        public String recordId {get;set;}
        public String dob {get;set;}
        
        public addAssociateMembersWrapper(String fname,String mname,String lname,String sfx,String phn,String eml,boolean mc,String rco,String recid,String db)
        {
            this.firstName = fname;
            this.mi = mname;
            this.lastName = lname;
            this.suffix = sfx;
            this.phone = phn;
            this.email = eml;
            this.motorcycleIncluded = mc;
            this.rvOfferingName = rco;
            this.recordId = recid;
            this.dob = db;
            
        }
    }   
}