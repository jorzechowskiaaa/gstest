@isTest
public class duplicateCallCheckControllerTest {
    @testSetup
    static void setupTestData() {
        
        Contact c = new Contact(
            LastName = 'Tester',
            Member_Card_Num__c = '123456789'
        	);
        insert c;
        
        WorkOrder wo = new WorkOrder(
        	Status = 'Spotted',
            ContactId = (String)c.Id,
            Member_Number2__c = '123456789'
        );
        
        insert wo; 
    }
    
    
    @isTest public static void testSearchOnContactId() {
        
        WorkOrder s = [select contactId from WorkOrder WHERE ContactId != null and Status in ('Spotted', 'In Progress') limit 1];
        String contId = s.ContactId;
        
        Test.startTest();
        list<WorkOrder> dupWOs = duplicateCallCheckController.checkForDuplicateWOs(null, contId);
        Test.stopTest();
        
        System.Assert(dupWOs.size() > 0, 'duplicates should be returned');
    }
    
    @isTest public static void testSearchOnMembershipNumber() {
        List<WorkOrder> WOs = [select Member_Number__c from WorkOrder WHERE Member_Number__c != null and Status in ('Spotted', 'In Progress') limit 1];
        String memNumber; 
        for (WorkOrder w : WOs) {
            memNumber = w.Member_Number__c; 
        } 
        Test.startTest();
        list<WorkOrder> dupWOs = duplicateCallCheckController.checkForDuplicateWOs(memNumber, null);
        Test.stopTest();
        
        System.Assert(dupWOs.size() > 0, 'duplicates should be returned');
    }
    
    @isTest public static void testNoResults() {
		Test.startTest();
        list<WorkOrder> dupWOs = duplicateCallCheckController.checkForDuplicateWOs('0000', '0000');
        Test.stopTest();
        System.AssertEquals(dupWOs, null, 'no duplicates should be returned');
    }
    
    @isTest public static void testQueryException() {

        String longString = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';
        Test.startTest();
        try {
        	list<WorkOrder> dupWOs = duplicateCallCheckController.checkForDuplicateWOs(null, longString);
        	System.AssertEquals(dupWOs, null, 'no duplicates should be returned');
        } catch (Exception e) {
             System.assert(false, 'Method should handle exceptions gracefully.');
        }
        Test.stopTest();
    }
    
}