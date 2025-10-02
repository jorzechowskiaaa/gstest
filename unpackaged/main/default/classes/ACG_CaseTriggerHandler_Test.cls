@isTest
private class ACG_CaseTriggerHandler_Test {

    @isTest
    static void testInsertCase() {
        // Test method to insert a new Case record
         Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();       
        Case newCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Vehicle_Location_State__c = 'CA',
            Tow_Destination_State__c = 'TX',
            recordtypeid = ERSRecordTypeId
        );

        Test.startTest();
        insert newCase;
        Test.stopTest();

        // Verify that the Case was inserted successfully
        Case insertedCase = [SELECT Id, Subject, Status, Vehicle_Location_State__c, Tow_Destination_State__c FROM Case WHERE Id = :newCase.Id];
        //System.assertEquals('Test Case', insertedCase.Subject, 'Expected Subject to be "Test Case"');
        System.assertEquals('New', insertedCase.Status, 'Expected Status to be "New"');
        System.assertEquals('CA', insertedCase.Vehicle_Location_State__c, 'Expected Vehicle Location State to be "CA"');
        System.assertEquals('TX', insertedCase.Tow_Destination_State__c, 'Expected Tow Destination State to be "TX"');
    }


    @isTest
    static void testUpdateCase() {
        // Test method to update an existing Case record
         Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
        Case newCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Vehicle_Location_State__c = 'CA',
            Tow_Destination_State__c = 'TX',
            Vehicle_Location_Street__c = 'test',
            recordtypeid = ERSRecordTypeId
        );
        insert newCase;

        // Modify the Case record
        newCase.Subject = 'Updated Case';
        newCase.Status = 'Closed';
        newCase.Vehicle_Location_Street__c = 'test1';

        Test.startTest();
        update newCase;
        Test.stopTest();

        // Verify that the Case was updated successfully
        Case updatedCase = [SELECT Id, Subject, Status FROM Case WHERE Id = :newCase.Id];
        System.assertEquals('Updated Case', updatedCase.Subject);
        System.assertEquals('Closed', updatedCase.Status);
    }

    @isTest
    static void testDeleteCase() {
        // Test method to delete a Case record
         Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
         Case newCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Vehicle_Location_State__c = 'CA',
            Tow_Destination_State__c = 'TX',
            recordtypeid = ERSRecordTypeId
        );
        insert newCase;

        Test.startTest();
        delete newCase;
        Test.stopTest();

        // Verify that the Case was deleted successfully
        List<Case> deletedCases = [SELECT Id FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(0, deletedCases.size(), 'Case should have been deleted');
    }

   
}