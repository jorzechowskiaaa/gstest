/**** Apex Class Name    :    INTERSFeedbackInbound_Test
    * Description        :    This is the test class used to test INTERSFeedbackInbound class
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri              Nov 9 2021             Created
*********************************************************************************/
@isTest
public class INTERSFeedbackInbound_Test {

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
        
        Feedback__c objrecp = new Feedback__c();
        objrecp.Member_ID__c = '4299941234757815';
        objrecp.Authorization_Code__c = String.valueof(system.today().year())+String.valueof(system.today().month())
            +String.valueof(system.today().day());
        objrecp.Member_Club__c = '994';
        objrecp.Service_Date__c = system.today();
        
        insert objrecp;
     }
    
  	//valid response
    @isTest static void validResponseNewFeedback(){
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        Feedback__c recp = [SELECT Id,Name,Authorization_Code__c,Member_Club__c,Member_ID__c,Source_Club__c FROM  Feedback__c LIMIT 1];
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.AAA_Same_Day_Service__c = FALSE;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        
        INTERSFeedbackRequest_Wrapper reqBody = new INTERSFeedbackRequest_Wrapper();
        reqBody.member_id = acct.ACG_AAA_Membership__c;
        reqBody.authorization_code = recp.Authorization_Code__c;
        reqBody.service_date = string.valueof(system.today().day());
        reqBody.service_month = string.valueof(system.today().month());
        reqBody.service_year = string.valueof(system.today().year());
        reqBody.source_club = '311';
        reqBody.member_club = recp.Member_Club__c;
        reqBody.ticket_number ='T12341';
        reqBody.long_tow_miles = '121';
        reqBody.long_tow_kilometers='150';
        reqBody.trouble_code = 'T0';
        reqBody.rental_days = '20';
        reqBody.authorization_log = '12345';
        request.requestBody=Blob.valueof(JSON.serialize(reqBody));
        
        request.requestURI = '/services/apexrest/ERSFeedback/';
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response= response; 
        
        Test.startTest();
        INTERSFeedbackInbound.getERSFeedback();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
    }
    
    
    //valid response
    @isTest static void validResponseExistingFeedback(){
        Account acct = [SELECT ACG_AAA_Membership__c FROM Account  LIMIT 1];
        Feedback__c recp = [SELECT Id,Name,Type__c,Status__c,Authorization_Code__c,Member_Club__c,Member_ID__c,Source_Club__c FROM  Feedback__c LIMIT 1];
        recp.Type__c = 'Outgoing Authorization';
		recp.Status__c = 'Open';
        recp.Source_Club__c = '212';
        update recp;
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        ServiceContract sc = new ServiceContract();
        sc.AAA_Total_of_Calls_Allowed__c = 10;
        sc.AAA_Total_of_Calls_Consumed__c = 8;
        sc.AAA_Same_Day_Service__c = FALSE;
        sc.EndDate = Date.today().addDays(10);
        sc.StartDate = Date.today().addDays(-100);
        sc.AAA_ACA_Membership16ID__c  ='4299941234757815';
        sc.AccountId = acct.Id;
        sc.AAA_ACA_Membership_Coverage_Level__c = 'PLUS';
        sc.AAA_ACA_Member_Status__c = 'ACTIVE';
        sc.AAA_ACA_Membership_Status__c = 'ACTIVE';
        sc.Name = '1507528-00';
        insert sc;
        
        
        INTERSFeedbackRequest_Wrapper reqBody = new INTERSFeedbackRequest_Wrapper();
        reqBody.member_id = acct.ACG_AAA_Membership__c;
        reqBody.authorization_code = recp.Authorization_Code__c;
        reqBody.service_date = string.valueof(system.today().day());
        reqBody.service_month = string.valueof(system.today().month());
        reqBody.service_year = string.valueof(system.today().year());
        reqBody.source_club = '212';
        reqBody.member_club = recp.Member_Club__c;
        reqBody.ticket_number ='T12341';
        reqBody.long_tow_miles = '121';
        reqBody.long_tow_kilometers='150';
        reqBody.trouble_code = 'T0';
        reqBody.rental_days = '20';
        reqBody.authorization_log = '12345';
        request.requestBody=Blob.valueof(JSON.serialize(reqBody));
        
        request.requestURI = '/services/apexrest/ERSFeedback/';
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response= response; 
        
        Test.startTest();
        INTERSFeedbackInbound.getERSFeedback();
        system.assertEquals(200,response.statusCode);
        Test.stopTest();
    }
    
    /**EMI-START - for SSFI-211**/
    
    @IsTest
    static void testUpdateFeedbackRecord_NewFeedback() {
    
       INTERSFeedbackRequest_Wrapper reqWrapper = new INTERSFeedbackRequest_Wrapper();
       
        reqWrapper.member_id = '12345';
        reqWrapper.authorization_code = 'authcode';
        reqWrapper.long_tow_miles = '100';
        reqWrapper.long_tow_kilometers = '16.93';
        reqWrapper.rental_days = '5';
        reqWrapper.source_club = 'CC1';
        reqWrapper.service_month = '07';
        reqWrapper.service_date = '16';
        reqWrapper.service_year = '2024';
        reqWrapper.member_club = 'CC2';

        Test.startTest();
        Feedback__c result = INTERSFeedbackInbound.updateFeedbackRecord(reqWrapper);
        Test.stopTest();

    }

    @IsTest
    static void testUpdateFeedbackRecord_UpdateExistingFeedback() {
        // Insert a feedback record to update
        Feedback__c existingFeedback = new Feedback__c(
            Member_ID__c = '12345',
            Authorization_Code__c = 'authcode'
        );
        insert existingFeedback;
    }
  
    /**EMI - END **/
   
}