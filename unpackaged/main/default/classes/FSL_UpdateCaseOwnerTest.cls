@isTest
public with sharing class FSL_UpdateCaseOwnerTest {
    
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

        Case c = new Case(RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId());
        c.Subject = 'Test';
        c.AccountId = acc.Id;
        insert c;

        User testUser = new User(
            Username = 'testuser@aaatest.com',
            Email = 'testuser@aaatest.com',
            LastName = 'AAATestUser',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }

    @isTest
    private static void testSuccess200(){
        Case c = [select Id from Case Limit 1];
        String email = 'testuser@aaatest.com';
        String requestJson = '{"callEvents": [{"caseId": "' + c.Id + '", "emailId": "' + email + '"}]}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/UpdateCaseOwner/';
        request.httpMethod = 'POST';
        request.addHeader('Sforce-Auto-Assign', 'false');
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        FSL_UpdateCaseOwner.UpdateCaseOwnerResponse response = FSL_UpdateCaseOwner.updateCaseOwner();
        System.assertEquals('200', response.statusCode, 'Status code should be 200');
        System.assertEquals('success', response.status, 'Status should be "success"');
        System.assertEquals('Updated owner successfully', response.statusDescription, 'Status description should match');
        
    }

    @isTest
    private static void testMissingRequired(){
        Case c = [select Id from Case Limit 1];
        String email = '';
        String requestJson = '{"callEvents": [{"caseId": "' + c.Id + '", "emailId": "' + email + '"}]}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/UpdateCaseOwner/';
        request.httpMethod = 'POST';
        request.addHeader('Sforce-Auto-Assign', 'false');
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        FSL_UpdateCaseOwner.UpdateCaseOwnerResponse response = FSL_UpdateCaseOwner.updateCaseOwner();
        System.assertEquals('400', response.statusCode, 'Status code should be 400');
        System.assertEquals('Bad Request', response.status, 'Status should be Bad Request');
        System.assertEquals('Missing Required values', response.statusDescription, 'Missing Required values');
        
    }

    @isTest
    private static void testException500(){
        Case c = [select Id from Case Limit 1];
        String email = 'test@aaatest.com';
        String requestJson = '{"callEvents": [{"caseId": "' + c.Id + '", "emailId": "' + email + '"}]}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/UpdateCaseOwner/';
        request.httpMethod = 'POST';
        request.addHeader('Sforce-Auto-Assign', 'false');
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        FSL_UpdateCaseOwner.UpdateCaseOwnerResponse response = FSL_UpdateCaseOwner.updateCaseOwner();
        System.assertEquals('500', response.statusCode, 'Status code should be 500');
        System.assertEquals('error', response.status, 'error');       
    }
}