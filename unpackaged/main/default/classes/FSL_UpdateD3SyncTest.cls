@isTest
public with sharing class FSL_UpdateD3SyncTest {
    @TestSetup
    static void makeData(){
        //Create Account
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
        wo.Call_Id__c = '20008';
        wo.AccountID = acc.Id;
        Date dToday = Date.today();
		String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        wo.Call_Date__c = dateStr;
        wo.Member_Account__c = acc.Id;
        wo.recordTypeId = recordTypeID;
        insert wo;
    }

    @isTest
    private static void testSyncCaseOnSucess(){
        WorkOrder wo = [select Id from WorkOrder where Call_Id__c='20008' limit 1];
        String requestJson = '{"id":"'+wo.Id+'","statusCode": 200,"statusDescription": "success","D3CallKey": "311-20230921-20129"}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/UpdateCaseSyncStatus/';
        request.httpMethod = 'POST';
        request.addHeader('Sforce-Auto-Assign', 'false');
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        FSL_UpdateD3Sync.StatusResponse response = FSL_UpdateD3Sync.updateSyncStatus();
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('Success', response.status, 'Status should be "success"');
        System.assertEquals('Sucessfully update Workorder with D3 Call Key', response.statusDescription, 'Status description should match');
    }

    @isTest
    private static void testSyncCaseOnFailure(){
        WorkOrder wo = [select Id from WorkOrder where Call_Id__c='20008' limit 1];
        String requestJson = '{"id":"'+wo.Id+'","statusCode": 500,"statusDescription": "Failed to create and clear call in D3","D3CallKey": "311-20230921-20129"}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/UpdateCaseSyncStatus/';
        request.httpMethod = 'POST';
        request.addHeader('Sforce-Auto-Assign', 'false');
        request.requestBody = Blob.valueOf(requestJson);
        RestContext.request = request;

        FSL_UpdateD3Sync.StatusResponse response = FSL_UpdateD3Sync.updateSyncStatus();
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('Success', response.status, 'Status should be "success"');
        System.assertEquals('Successfully created Manual Service Order case', response.statusDescription, 'Status description should match');
    }
}