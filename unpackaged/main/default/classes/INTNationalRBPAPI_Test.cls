/**** Apex Class Name    :    INTNationalRBPAPI_Test
    * Description        :    Test class for INTNatioanlRBPAPI class  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Dhruv               		Aug 16 2021             Created
*********************************************************************************/
@isTest
public class INTNationalRBPAPI_Test {
    @testSetup 
    static void setup() {
        insert new Integration_Settings__c(
            Name = 'NationalRBP_API',
            Method__c = 'POST',
            Enpoint_URL__c = 'https://api-qa.national.aaa.com/automotive/services/sf/v1/requests/close',
            Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]'
        );
        
        Integration_Settings__c integrationSetting = ACG_TestDataFactory.createIntegrationSetting(
            'NatioanlRBP_API', 
            'POST', 
            'callout:NatioanlRBP_API', 
            '/callClear', 
            'http://acg-ers-ulra-rbpcallclear-api-dev.us-e1.cloudhub.io/callClear', 
            true
        );

        System.assertEquals(true, integrationSetting.Id != null, 'Error While Creating Record');
        
        insert new Execute_Trigger__c(
            Name = 'Work Order'
        );
        
        Id accountMemberId = 
            Schema.SObjectType.Account
                .getRecordTypeInfosByName()
                .get('ERS Member')
                .getRecordTypeId();
        Id accountfacilityId = 
            Schema.SObjectType.Account
                .getRecordTypeInfosByName()
                .get('Facility')
                .getRecordTypeId();
        Id MEMBER_ACCOUNT_RECORDTYPEID = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
        Account FacilityAcc = ACG_TestDataFactory.createAccount(
            accountfacilityId,'FacilityUser', true
        );

        List<Account> lstMemberAcc = ACG_TestDataFactory.createAccounts(MEMBER_ACCOUNT_RECORDTYPEID, 1 , false, true);
        lstMemberAcc[0].ACG_AAA_Membership__c='123';
        lstMemberAcc[0].Email_Type__pc='PERSONAL';
        lstMemberAcc[0].Fax='2222222222';
        lstMemberAcc[0].Phone='2222222222';
        lstMemberAcc[0].PersonHomePhone='2222222222';
        lstMemberAcc[0].PersonMobilePhone='2222222222';
        lstMemberAcc[0].Member_Club_Code__c='006';
        insert lstMemberAcc;
        
        Id towID = 
            Schema.SObjectType.WorkOrder
                .getRecordTypeInfosByName()
                .get('Tow')
                .getRecordTypeId();

        WorkOrder wo = ACG_TestDataFactory.createWorkOrder(FacilityAcc.Id, lstMemberAcc[0].Id, towID, false);
        wo.Accountid = FacilityAcc.Id;
        wo.member_account__c = lstMemberAcc[0].Id;
        wo.RAP_Case_Number__c = '123456';
        insert wo;

        Product2 twProd = new Product2(
            Family = 'Service Item',
            IsActive = true,
            Name = 'TW-Tow',
            ProductCode = 'TW',
            QuantityUnitOfMeasure = 'Each'
        );
        insert twProd;
        
        insert new FSL_Service_Line_Item__c(
            Work_Order__c = wo.Id,
            Product__c = twProd.Id,
            Unit__c = 23.23,
            Cost__c = 23.23,
            Override_Pricing__c = false
        );

        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Id callAdjustmentRecTypeId  = EP.getRecordTypeId(Case.SObjectType, 'ACG_Call_Adjustment');
        
        List<Account> lstAccounts = new List<Account>();
        Account objFacility = ACG_TestDataFactory.createAccounts(facilityRecordTypeId, 1, false, false)[0];
        objFacility.Facility_ID__c = '9131';
        lstAccounts.add(objFacility);
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId, 1, false, false)[0];
        objFacility1.Facility_ID__c = 'CR567';
        lstAccounts.add(objFacility1);
        insert lstAccounts;
        
        List<Case> callAdjustments = new List<Case>();
        Case objCallAdjustment = ACG_TestDataFactory.createcase(callAdjustmentRecTypeId, 'Pending', 'Chat', false);
        objCallAdjustment.ACG_Provider_Comments__c = 'Test';
        objCallAdjustment.Facility__c = objFacility1.Id;
        callAdjustments.add(objCallAdjustment);
        Case objCallAdjustment1 = ACG_TestDataFactory.createcase(callAdjustmentRecTypeId, 'Pending', 'Chat', false);
        objCallAdjustment1.ERS_Event_Type__c = 'Accident Assist';
        objCallAdjustment1.ACG_Provider_Comments__c = 'Test';
        objCallAdjustment1.Facility__c = objFacility1.Id;
        callAdjustments.add(objCallAdjustment1);
        insert callAdjustments;
        
        Id EPRecordType = 
            Schema.SObjectType.ERS_Payment__c
                .getRecordTypeInfosByName()
                .get('Call')
                .getRecordTypeId();

        ERS_Payment__c ObjEP = ACG_TestDataFactory.createERSPayment(EPRecordType, false);
        ObjEP.Work_Order__c = wo.Id;
        ObjEP.Case__c = objCallAdjustment.Id;
        ObjEP.Facility__c = objFacility.Id;
        insert ObjEP;
        
        Product2 product= ACG_TestDataFactory.createProduct('Test', 'P1', true, true);
        ERS_Payment_Line_Item__c objEPLI= ACG_TestDataFactory.createERSPaymentLineItem(ObjEP.Id, product.Id, 10, true);
        
        insert new FeedItem(
            parentId = wo.Id,
            Body = 'test'
        );
        
        insert new WorkOrderHistory(
            WorkOrderId = wo.Id,
            Field = 'Status'
        );
    }
    
    @isTest 
    static void getRBPCallout() {
        String res = '{"responseHeaders": {"tranId": "8f03b3b0-4918-11ec-aeac-0a8918c0875d","tranCode": 200,"tranStatus": "E","timeStamp": "2021-11-19T04:10:42.1-05:00","tranStatusDescription": "Invalid callKey and try again."}}';

        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 

        INTNationalRBPAPIRequest_Wrapper req = new INTNationalRBPAPIRequest_Wrapper();
        req.comments = new List<INTNationalRBPAPIRequest_Wrapper.Comment>();
        INTNationalRBPAPIRequest_Wrapper.Comment comment = new INTNationalRBPAPIRequest_Wrapper.Comment();
        comment.Contact = new INTNationalRBPAPIRequest_Wrapper.Contact();
        comment.Contact.phones=new List<INTNationalRBPAPIRequest_Wrapper.Phone>();
        comment.Contact.phones.add(new INTNationalRBPAPIRequest_Wrapper.Phone());
        comment.Contact.Emails = new List<INTNationalRBPAPIRequest_Wrapper.Email>();
        comment.Contact.Emails.add(new INTNationalRBPAPIRequest_Wrapper.Email());
        req.comments.add(comment);
        req.callKey = '1223';

        Test.startTest(); 
        Map<String, Object> respMap = (Map<String, Object>) INTNationalRBPAPI.sendToStatusToRBP(req, null);

        HttpResponse resp = (HttpResponse) respMap.get('resp');

        System.assertEquals(200, resp.getStatusCode(), 'Success');
        Test.stopTest();
    }

    @isTest 
    static void getErrorLog() {
        String res = '{"responseHeaders": {"tranId": "8f03b3b0-4918-11ec-aeac-0a8918c0875d","tranCode": 400,"tranStatus": "E","timeStamp": "2021-11-19T04:10:42.1-05:00","tranStatusDescription": "Invalid callKey and try again."}}';
        
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res,500,'Internal Server Error')); 

        INTNationalRBPAPIRequest_Wrapper req=new INTNationalRBPAPIRequest_Wrapper();
        req.callKey='006-20220311-0-123456';

        Test.startTest();
        Map<String, Object> respMap = (Map<String, Object>) INTNationalRBPAPI.sendToStatusToRBP(req, null);

        HttpResponse resp = (HttpResponse) respMap.get('resp');
        Test.stopTest();
        
        System.assertEquals(500, resp.getStatusCode(), 'Internal Server Error Occured');
    }

    @isTest 
    static void getExceptionLog() {
        String res = '';

        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res, 500, 'Internal Server Error')); 

        Test.startTest();
        INTNationalRBPAPIRequest_Wrapper req = new INTNationalRBPAPIRequest_Wrapper();
        req.callKey='006-20220311-0-123456';
        Map<String, Object> respMap = (Map<String, Object>) INTNationalRBPAPI.sendToStatusToRBP(req, null);
        HttpResponse resp = (HttpResponse) respMap.get('resp');

        System.assertEquals(500, resp.getStatusCode(), 'Internal Server Error Occured');
        Test.stopTest();
    }
    
    @isTest 
    static void getCatchException() {
        String res = '[{"responseHeaders": {"tranId": "8f03b3b0-4918-11ec-aeac-0a8918c0875d","tranCode": 200,"tranStatus": "E","timeStamp": "2021-11-19T04:10:42.1-05:00","tranStatusDescription": "Invalid callKey and try again."}}]';
        
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res, 500, 'Internal Server Error')); 
        
        Test.startTest(); 
        INTNationalRBPAPIRequest_Wrapper req = new INTNationalRBPAPIRequest_Wrapper();
        req.callKey='006-20220311-0-123456';
        Map<String, Object> respMap = (Map<String, Object>) INTNationalRBPAPI.sendToStatusToRBP(req, null);
        HttpResponse resp = (HttpResponse) respMap.get('resp');

        System.assertEquals(500, resp.getStatusCode(), 'Internal Server Error Occured');
        Test.stopTest();
    }
    
    @isTest 
    static void getRBPRequest() {
        Set<Id> woIdSet = new Map<Id, WorkOrder>([SELECT Id FROM WorkOrder LIMIT 1]).keySet();

        Test.startTest(); 
        Map<String, Object> resMap = (Map<String, Object>) INTNationalRBPAPI.createrbprquest(woIdSet);
        List<INTNationalRBPAPIRequest_Wrapper> requestWrapper = (List<INTNationalRBPAPIRequest_Wrapper>) resMap.get('lstRBPReq');
        Test.stopTest();

        System.assertEquals(1, requestWrapper.size(), 'Expected request to be created');
    }

    @isTest
    static void rbpReqStatusTest() {
        RecordType facTerritoryType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Territory' 
            AND SobjectType = 'ServiceTerritory' 
            LIMIT 1
        ];

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        ServiceTerritory fac = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true,
            Facility_Number__c = 'APEXFAC22',
            City = 'FLUSHING',
            Country = 'United States',
            CountryCode = 'US',
            PostalCode = '01301',
            State = 'NY',
            StateCode = 'NY',
            Street = '86 RIVER ST'
        );
        insert fac;

        WorkOrder wo = [
            SELECT 
                Id,
                ServiceTerritoryId,
                Canceled_Timestamp__c,
                Cleared_Timestamp__c,
                Dispatched_Timestamp__c,
                Enroute_Timestamp__c,
                In_Tow_Timestamp__c,
                On_Location_Timestamp__c,
                Spotted_Timestamp__c
            FROM WorkOrder
            LIMIT 1
        ];
        wo.ServiceTerritoryId = fac.Id;
        wo.Canceled_Timestamp__c = Datetime.now();
        wo.Cleared_Timestamp__c = Datetime.now();
        wo.Dispatched_Timestamp__c = Datetime.now();
        wo.Enroute_Timestamp__c = Datetime.now();
        wo.In_Tow_Timestamp__c = Datetime.now();
        wo.On_Location_Timestamp__c = Datetime.now();
        wo.Spotted_Timestamp__c = Datetime.now();
        update wo;

        Test.startTest(); 
        Map<String, Object> resMap = (Map<String, Object>) INTNationalRBPAPI.createrbprquest(new Set<Id>{wo.Id});
        List<INTNationalRBPAPIRequest_Wrapper> reqWrapList = (List<INTNationalRBPAPIRequest_Wrapper>) resMap.get('lstRBPReq');
        Test.stopTest();

        System.assertEquals(1, reqWrapList.size(), 'Expected request to be created');
        System.assertEquals(7, reqWrapList[0].status.size(), 'Expected status list to be populated');

        Integer statusCount = 0;

        for (INTNationalRBPAPIRequest_Wrapper.Status statusObj : reqWrapList[0].status) {
            String status = statusObj.status;

            if (status == 'SP') {
                statusCount++;
            } else if (status == 'DI') {
                statusCount++;
            } else if (status == 'ER') {
                statusCount++;
            } else if (status == 'OL') {
                statusCount++;
            } else if (status == 'TW') {
                statusCount++;
            } else if (status == 'CL') {
                statusCount++;
            } else if (status == 'CA') {
                statusCount++;
            }
        }

        System.assertEquals(7, statusCount, 'Failed to include Work Order status into request');
    }

    @isTest
    static void gmtConvertTest() {
        Datetime result = INTNationalRBPAPI.convertToGMT(Datetime.now());

        System.assertEquals(true, result != null, 'Failed to convert to GMT.');
    }

    @isTest
    static void prepSLIForRBPTest() {
        Product2 tlProd = new Product2(
            ProductCode = 'TL',
            Name = 'TL',
            Family = 'Service Item'
        );
        insert tlProd;

        WorkOrder wo = new WorkOrder(
            Clearing_Code__c = '01',
            Call_Type__c = 'RAP',
            Resolution_Code__c = 'G201'
        );
        insert wo;
        
        FSL_Service_Line_Item__c tlSLI = new FSL_Service_Line_Item__c(
            Product__c = tlProd.Id,
            Cost__c = 45.45,
            Unit__c = 45.45,
            Charge_to_Account__c = 'B',
            Work_Order__c = wo.Id
        );
        insert tlSLI;

        tlSLI = [
            SELECT
                Id,
                Product_Code__c,
                Total_Price__c,
                Unit__c,
                Charge_to_Account__c
            FROM FSL_Service_Line_Item__c
            WHERE Id = :tlSLI.Id
        ];
        
        INTNationalRBPAPIRequest_Wrapper.providedService result = INTNationalRBPAPI.prepSLIForRBP(
            new Map<String, Object>{
                'unitMap' => new Map<String, String>{
                    'TL' => 'ML'
                },
                'sli' => tlSLI,
                'tCode' => 'T6'
            }
        );

        System.assertEquals(true, result != null, 'Failed to create object');
    }
}