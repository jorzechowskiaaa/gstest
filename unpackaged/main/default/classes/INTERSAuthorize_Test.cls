/**** Apex Class Name    :    INTERSAuthorize_Test
    * Description        :    This is the test class used to test INTERSAuthorize class
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri              Sep 30 2021             Created
*********************************************************************************/
@isTest(SeeAllData = false)
public class INTERSAuthorize_Test {
 /*
   * Method name    : setup
   * Description    : Used to create a test records
   * Return Type    : void
   * Parameter      : none
   */
    @testSetup static void setup() {

    	Id MEMBER_ACCOUNT_RECORDTYPEID = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
        
        ACG_Skip_Automations__c objSkipAutomations = ACG_Skip_Automations__c.getInstance(System.UserInfo.getProfileId());
        objSkipAutomations.ACG_Skip_Trigger__c = false;
        upsert objSkipAutomations;
        
        List<SObject> lstToInsert = new List<sObject>();
        
        
        //create members
        List<Account> lstMembers = ACG_TestDataFactory.createAccounts(MEMBER_ACCOUNT_RECORDTYPEID,1,false,true);
        for(Account objacc:lstMembers){
            objacc.ACG_AAA_Membership__c='4299941234757815';
            objacc.AAA_Membership_Level__c='Plus';
            objacc.phone = '9999999999';
            objacc.Long_Tow_Kilometers_Used__c =161;
            objacc.Long_Tow_Miles_Used__c=100;
        }
        lstToInsert.addAll(lstMembers);
        
       
        insert lstToInsert;
     }
    
	//valid scenario with SC and no same day service 
    @isTest static void getERSwActiveSCNoSameDay() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        //system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    //valid scenario w/o SC 
    @isTest static void getERSwNoSC() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        acct.Member_ID__c = '4299941234757815';
        acct.Member_Card_Num__pc = '4299941234757815';
        update acct;
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    @isTest static void getERSwPendingSC() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'PENDING';
        sc.AAA_ACA_Membership_Status__c = 'PENDING';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        //system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    @isTest static void getERSwPendingSC0Calls() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 0;
        sc.AAA_Total_of_Calls_Consumed__c = 0;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'PENDING';
        sc.AAA_ACA_Membership_Status__c = 'PENDING';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    @isTest static void getERSwPendingSCEndDatePassed() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 0;
        sc.AAA_Total_of_Calls_Consumed__c = 0;
        sc.EndDate = Date.today().addDays(-10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'PENDING';
        sc.AAA_ACA_Membership_Status__c = 'PENDING';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    @isTest static void getERSwSCActiveAllCallsConsumed() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 8;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    @isTest static void getERSwSCActiveValidSameDay() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','212');
        request.params.put('clb_cd',Label.FSL_SourceClubCode);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
     }
    
    //invalid scenario with incorrect club code
    @isTest static void getERSIncorrectClubCode() {
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        system.debug(acct.ACG_AAA_Membership__c);
        String recordId = acct.ACG_AAA_Membership__c;
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        system.assertNOTEquals(sc.Id,null,'Service Contract Not created');
               
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.headers.put('mbr_id',recordId);
        request.params.put('service_year',String.valueof(system.today().Year()));
        request.params.put('service_month',String.valueof(system.today().Month()));
        request.params.put('service_date',String.valueof(system.today().Day()));
        request.params.put('source_clb','003');
        request.params.put('clb_cd','205');
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response= response;
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));
        INTERSAuthorize.getERSAuthorize();
        system.assertEquals(400,response.statusCode);
        Test.stopTest();
     }
    

}