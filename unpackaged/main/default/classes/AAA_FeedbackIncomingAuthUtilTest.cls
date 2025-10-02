@isTest
public class AAA_FeedbackIncomingAuthUtilTest {
    
    @TestSetup
    static void makeData(){
        Account acc = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId());
        acc.FirstName = 'Test';
        acc.LastName = 'Member';
        acc.BillingStreet = '129 West St';
        acc.BillingCity = 'Wilmington';
        acc.BillingStateCode = 'DE';
        acc.BillingCountryCode = 'US';
        acc.BillingPostalCode = '19801';
        insert acc;

        //Create Work order
        Id recordTypeID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
        
        WorkOrder wo = new WorkOrder();
        wo.Locked_After_Clear__c = false;
        wo.Call_Id__c = '20018';
        wo.AccountID = acc.Id;
        Date dToday = Date.today();
		String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        wo.Call_Date__c = dateStr;
        wo.Member_Account__c = acc.Id;
        wo.recordTypeId = recordTypeID;
        insert wo;

        Integration_Settings__c setting = new Integration_Settings__c();
        setting.Name = 'National_Feedback_API';
        setting.Method__c = 'POST';
        setting.Request_Timeout__c = 12000;
        setting.Enpoint_URL__c = 'https://api-qa.national.aaa.com/membership/services/v1/member/feedback';
        setting.Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]';
        setting.Extra_Header_Value__c = '';
        setting.Named_Credential__c = '';
        insert setting;
    }

    @isTest
    public static void createOpenFeedbackTest(){
        Account acc = [select ID from Account Limit 1];
        INTMembershipLookupResponse_Wrapper.Customer cust = new INTMembershipLookupResponse_Wrapper.Customer();
        INTMembershipLookupResponse_Wrapper.Authorize auth = new INTMembershipLookupResponse_Wrapper.Authorize();
        auth.code = '23345452';
        auth.level = 'B';
        cust.authorize = auth;
        cust.membershipId = '4382121748112012';

        Test.startTest();
        AAA_FeedbackIncomingAuthUtil.createOpenFeedback(cust, acc.Id);
        Test.stopTest();

        List<Feedback__c> fb = [select Id, Type__c, Account__c, Status__c,Authorization_Code__c, Member_ID__c from Feedback__c];
        System.assertEquals(fb.size() > 0 , true, 'Should successfully return feedback');
        System.assertEquals(fb[0].Type__c , 'Incoming Authorization', 'Feedback type should be Incoming Authorization');
        System.assertEquals(fb[0].Account__c , acc.Id, 'Feedback should linked to Account');
        System.assertEquals(fb[0].Authorization_Code__c , '23345452', 'Feedback auth should be 23345452');
        System.assertEquals(fb[0].Member_ID__c , '4382121748112012', 'Feedback memberID should be 4382121748112012');
    }

    @isTest
    public static void createOpenFeedbackTestCatch(){
        Account acc = [select ID from Account Limit 1];
        INTMembershipLookupResponse_Wrapper.Customer cust = null;

        Test.startTest();
        try{
            AAA_FeedbackIncomingAuthUtil.createOpenFeedback(cust, acc.Id);
        }Catch(Exception exp){
            System.debug('Exception : '+ exp.getMessage());
            System.assertEquals('Attempt to de-reference a null object', exp.getMessage(), 'Show throw a null pointer exception');
        }
        Test.stopTest();
    }

    @isTest
    public static void upsertFeedbackTestTry(){
        Test.startTest();
        AAA_FeedbackIncomingAuthUtil.upsertFeedback('757847864');
        List<Feedback__c> fb = [Select ID from Feedback__c];
        System.assert(fb.size() == 0, 'No Feedback should be returned');
        Test.stopTest();
    }

    @isTest
    public static void upsertFeedbackTestSuccess(){
        Account acc = [select ID from Account Limit 1];
        INTMembershipLookupResponse_Wrapper.Customer cust = new INTMembershipLookupResponse_Wrapper.Customer();
        INTMembershipLookupResponse_Wrapper.Authorize auth = new INTMembershipLookupResponse_Wrapper.Authorize();
        auth.code = '23345452';
        auth.level = 'B';
        cust.authorize = auth;
        cust.membershipId = '4382121748112012';

        AAA_FeedbackIncomingAuthUtil.createOpenFeedback(cust, acc.Id);
        WorkOrder wo = [SELECT Id, Call_Id__c FROM WorkOrder WHERE Call_Id__c='20018' LIMIT 1];
        Test.startTest();
        AAA_FeedbackIncomingAuthUtil.upsertFeedback(wo.Id);
        List<Feedback__c> fb = [Select ID from Feedback__c];
        System.assert(fb.size() > 0, 'Feedback records should be returned');
        Test.stopTest(); 
    }

    @isTest
    public static void sendFeedbackToNationalSuccess(){
        Account acc = [select ID from Account Limit 1];
        INTMembershipLookupResponse_Wrapper.Customer cust = new INTMembershipLookupResponse_Wrapper.Customer();
        INTMembershipLookupResponse_Wrapper.Authorize auth = new INTMembershipLookupResponse_Wrapper.Authorize();
        auth.code = '23345452';
        auth.level = 'B';
        cust.authorize = auth;
        cust.membershipId = '4382121748112012';
        AAA_FeedbackIncomingAuthUtil.createOpenFeedback(cust, acc.Id);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockFeedbackResponseGenerator(true));
            List<Feedback__c> feedbacks = [SELECT Id from Feedback__c limit 1];
            List<Id> feedbackIds = new List<Id>();
            feedbackIds.add(feedbacks[0].Id);
            if(feedbacks.size() > 0){
                AAA_FeedbackIncomingAuthUtil.sendFeedbackToNational(feedbackIds);
            }     
        Test.stopTest();
        
        List<Feedback__c> feedbacks1 = [SELECT Id, Is_Sent_To_National__c from Feedback__c limit 1];
        System.assertEquals(feedbacks1[0].Is_Sent_To_National__c, true, 'Response should be successful');
    }

    @isTest
    public static void sendFeedbackToNationalFailure(){
        Account acc = [select ID from Account Limit 1];
        INTMembershipLookupResponse_Wrapper.Customer cust = new INTMembershipLookupResponse_Wrapper.Customer();
        INTMembershipLookupResponse_Wrapper.Authorize auth = new INTMembershipLookupResponse_Wrapper.Authorize();
        auth.code = '23345452';
        auth.level = 'B';
        cust.authorize = auth;
        cust.membershipId = '4382121748112012';
        AAA_FeedbackIncomingAuthUtil.createOpenFeedback(cust, acc.Id);

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockFeedbackResponseGenerator(false));
            List<Feedback__c> feedbacks = [SELECT Id from Feedback__c limit 1];
            List<Id> feedbackIds = new List<Id>();
            feedbackIds.add(feedbacks[0].Id);
            if(feedbacks.size() > 0){
                AAA_FeedbackIncomingAuthUtil.sendFeedbackToNational(feedbackIds);
            }     
        Test.stopTest();
        
        List<Feedback__c> feedbacks2 = [SELECT Id, Is_Sent_To_National__c, Error_Code__c, Error_Message__c from Feedback__c limit 1];
        System.assertEquals(feedbacks2[0].Is_Sent_To_National__c, false, 'Response should not be successful');
        //System.assertEquals(feedbacks2[0].Error_Code__c, '404', 'Response should be 404');
        //System.assertEquals(feedbacks2[0].Error_Message__c, 'Not Found', 'Response should be Not Found');
    } 
}