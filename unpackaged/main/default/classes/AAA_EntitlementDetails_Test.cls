@isTest
private class AAA_EntitlementDetails_Test {
   @testSetup
   static void setupTestData() {
       //Get the account record type
       RecordType AccRecType = [
           select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'ERS_Member' limit 1
       ];
       // Create Account
       Account acc = new Account(
           Name = 'Test Account',
           ACG_AAA_Membership__c = '6202408673324206',
           RecordTypeId = AccRecType.Id);
       insert acc;
       // Create Active ServiceContract
       ServiceContract sc = new ServiceContract(
           AccountId = acc.Id,
           StartDate = Date.today(),
           Name = 'Test Service Contract'
       );
       insert sc;
       // WorkOrder
       WorkOrder wo = new WorkOrder(
           Subject = 'Test WO',
           ServiceContractId = sc.Id,
           Status = 'Cleared',
           AAA_Charge_Entitlement__c = true
       );
       insert wo;
       // Reciprocal__c
       Reciprocal__c rc = new Reciprocal__c(
           Service_Contract__c = sc.Id,
           Charge_Entitlements__c = true
       );
       insert rc;
       // ACG_Reimbursement__c
       ACG_Reimbursement__c re = new ACG_Reimbursement__c(
           Service_Contract__c = sc.Id,
           ACG_Charge_Entitlement__c = true,
           ACG_Member_Name__c = acc.id
       );
       insert re;
       // Feedback__c
       Feedback__c fb = new Feedback__c(
           Service_Contract__c = sc.Id,
           Charge_Entitlement__c = true,
           Source_Club__c = '111'
       );
       insert fb;
   }
   @isTest
   static void testWithContractsAndRecords() {
       Account acc = [SELECT Id FROM Account LIMIT 1];
       Test.startTest();
       AAA_EntitlementDetails.responseWrapper result =
           AAA_EntitlementDetails.getWorkOrderbyAccount(acc.Id);
       Test.stopTest();
       System.assertNotEquals(null, result, 'Response should not be null');
       System.assert(result.hasServiceContracts, 'Should detect service contracts');
       System.assert(result.records.size() > 0, 'Should return related records');
       // Validate record types
       Set<String> expectedTypes = new Set<String>{'Work Order','Reciprocal','Reimbursement','Feedback'};
       Set<String> actualTypes = new Set<String>();
       for (AAA_EntitlementDetails.CombinedRecord rec : result.records) {
           actualTypes.add(rec.recType);
           System.assertNotEquals(null, rec.createdDate, 'CreatedDate should be populated');
       }
       System.assertEquals(expectedTypes, actualTypes, 'All record types should be included');
   }
   @isTest
   static void testNoContracts() {
       Account acc2 = new Account(Name = 'No Contract Account');
       insert acc2;
       Test.startTest();
       AAA_EntitlementDetails.responseWrapper result =
           AAA_EntitlementDetails.getWorkOrderbyAccount(acc2.Id);
       Test.stopTest();
       System.assertEquals(false, result.hasServiceContracts, 'No contracts expected');
       System.assertEquals(0, result.records.size(), 'No records expected');
   }
   @isTest
   static void testNullAccountId() {
       Test.startTest();
       AAA_EntitlementDetails.responseWrapper result =
           AAA_EntitlementDetails.getWorkOrderbyAccount(null);
       Test.stopTest();
       System.assertEquals(false, result.hasServiceContracts, 'Should be false when accountId is null');
       System.assertEquals(0, result.records.size(), 'No records expected when accountId is null');
   }
}