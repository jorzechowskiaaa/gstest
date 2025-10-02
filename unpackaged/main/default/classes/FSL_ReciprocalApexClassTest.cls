@isTest
public class FSL_ReciprocalApexClassTest {
    private static Id obRecRT = Schema.SObjectType.Reciprocal__c
        .getRecordTypeInfosByDeveloperName()
        .get('Outbound_Payment_Requests')
        .getRecordTypeId();
    private static Id ibRecRT = Schema.SObjectType.Reciprocal__c
        .getRecordTypeInfosByDeveloperName()
        .get('Inbound_Payment_Requests')
        .getRecordTypeId();

    @isTest
    public static void reciprocalTests() {
        Reciprocal__c rec = new Reciprocal__c(
            CDX_Authorization_Code__c = '19268307',
            Service_Call_Date__c = Date.parse('01/31/2024'),
            Membership_Expiration_Date__c = Date.parse('07/07/2024'),
            Member_ClubCode__c = '212',
            Total_Dollar_Amount__c = 224.71,
            Member_ID__c = '236360602',
            Service_Club_Code__c = '240',
            Submitting_Club_Code__c = '240',
            Service_Facility_ID__c = '33',
            Service_Call_Tow_Miles__c = 42,
            Service_Call_ID__c = '49463',
            Member_Last_Name__c = 'Bedard',
            Member_First_Name__c = 'Olivia',
            recordTypeId = obRecRT,
            Cost_Buffer__c = 'TEST/REC/BON/12345',
            Service_Call_Trouble_Code__c = 'T5'
        );

        Test.startTest();
        insert rec;

        Reciprocal__c recold = [
            SELECT Id, Total_Dollar_Amount__c 
            FROM Reciprocal__c
        ];
        
        recold.Cost_Buffer__c = 'TEST/REC/BON/12445';
        update recold;

        Reciprocal__c recnew = [
            SELECT Id, Cost_Buffer__c, Total_Dollar_Amount__c 
            FROM Reciprocal__c
        ];
        Test.stopTest();

        System.assertEquals(225.71, recnew.Total_Dollar_Amount__c, 'Failed test.');
    }

    @isTest
    public static void checkIBDuplicatesTest() {
        Boolean hasError = true;
        Reciprocal__c ogRec = new Reciprocal__c(
            CDX_Authorization_Code__c = '19268307',
            Service_Call_Date__c = Date.parse('01/31/2024'),
            Membership_Expiration_Date__c = Date.parse('07/07/2024'),
            Member_ClubCode__c = '212',
            Total_Dollar_Amount__c = 224.71,
            Member_ID__c = '236360602',
            Service_Club_Code__c = '240',
            Submitting_Club_Code__c = '240',
            Service_Facility_ID__c = '33',
            Service_Call_Tow_Miles__c = 42,
            Service_Call_ID__c = '49463',
            Member_Last_Name__c = 'Bedard',
            Member_First_Name__c = 'Olivia',
            recordTypeId = ibRecRT,
            Cost_Buffer__c = 'TEST/REC/BON/12345',
            Service_Call_Trouble_Code__c = 'T5'
        );
        insert ogRec;

        Reciprocal__c dupeRec = new Reciprocal__c(
            CDX_Authorization_Code__c = '19268307',
            Service_Call_Date__c = Date.parse('01/31/2024'),
            Membership_Expiration_Date__c = Date.parse('07/07/2024'),
            Member_ClubCode__c = '212',
            Total_Dollar_Amount__c = 224.71,
            Member_ID__c = '236360602',
            Service_Club_Code__c = '240',
            Submitting_Club_Code__c = '240',
            Service_Facility_ID__c = '33',
            Service_Call_Tow_Miles__c = 42,
            Service_Call_ID__c = '49463',
            Member_Last_Name__c = 'Bedard',
            Member_First_Name__c = 'Olivia',
            recordTypeId = ibRecRT,
            Cost_Buffer__c = 'TEST/REC/BON/12345',
            Service_Call_Trouble_Code__c = 'T5'
        );

        try {
            insert dupeRec;
            hasError = false;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        List<Reciprocal__c> resRecList = [
            SELECT
                Id,
                is_Duplicate__c
            FROM Reciprocal__c
            WHERE Id IN :new List<String>{ogRec.Id, dupeRec.Id}
        ];

        for (Reciprocal__c rec : resRecList) {
            System.assertEquals(true, rec.is_Duplicate__c, 'Failed to mark duplicate for Reciprocal.');
        }
    }
    
    /**EMI - SSFI-380**/
     // create test data for the Reciprocal__c object
    private static Reciprocal__c createReciprocalRecord(String status, String transactionType) {
        Reciprocal__c rec = new Reciprocal__c();
        rec.Status__c = status;
        rec.Transaction__c = transactionType;
        insert rec;
        return rec;
    }

    // Test case for when the status is changed to 'Approved' and the transaction is 'PAY'
    @isTest
    static void testTransactionTypeUpdatedToPay() {
        // Create old record
        Reciprocal__c oldRec = createReciprocalRecord('New', 'PAY');
        
        // Create a new record and simulate a status change
        Reciprocal__c newRec = [SELECT Id, Status__c, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        newRec.Status__c = 'Approved';

        // Simulate the old and new map
        Map<Id, Reciprocal__c> oldMap = new Map<Id, Reciprocal__c>{oldRec.Id => oldRec};
        Map<Id, Reciprocal__c> newMap = new Map<Id, Reciprocal__c>{newRec.Id => newRec};

        // Call the method 
        Test.startTest();
        FSL_ReciprocalApexClass.updateTransactionTypeOnStatusChange(oldMap, newMap);
        Test.stopTest();

        // Verify the transaction type is updated to 'PAY'
        newRec = [SELECT Id, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        System.assertEquals('PAY', newRec.Transaction__c);
    }
    
    // Test case for when the status is changed to 'Rebilled' and the transaction is 'PAY'
    @isTest
    static void testTransactionTypeUpdatedToDSP() {
        // Create old record
        Reciprocal__c oldRec = createReciprocalRecord('New', 'DSP');
        
        // Create a new record and simulate a status change
        Reciprocal__c newRec = [SELECT Id, Status__c, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        newRec.Status__c = 'Rebilled';

        // Simulate the old and new map
        Map<Id, Reciprocal__c> oldMap = new Map<Id, Reciprocal__c>{oldRec.Id => oldRec};
        Map<Id, Reciprocal__c> newMap = new Map<Id, Reciprocal__c>{newRec.Id => newRec};

        // Call the method being tested
        Test.startTest();
        FSL_ReciprocalApexClass.updateTransactionTypeOnStatusChange(oldMap, newMap);
        Test.stopTest();

        // Verify the transaction type is updated to 'DSP'
        newRec = [SELECT Id, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        System.assertEquals('DSP', newRec.Transaction__c);
    }
    
    // Test case for when the status is changed to 'Rebilled' and the transaction is 'ACP'
    @isTest
    static void testTransactionTypeUpdatedToERR() {
        // Create old record
        Reciprocal__c oldRec = createReciprocalRecord('New', 'ERR');
        
        // Create a new record and simulate a status change
        Reciprocal__c newRec = [SELECT Id, Status__c, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        newRec.Status__c = 'Rebilled';

        // Simulate the old and new map
        Map<Id, Reciprocal__c> oldMap = new Map<Id, Reciprocal__c>{oldRec.Id => oldRec};
        Map<Id, Reciprocal__c> newMap = new Map<Id, Reciprocal__c>{newRec.Id => newRec};

        // Call the method being tested
        Test.startTest();
        FSL_ReciprocalApexClass.updateTransactionTypeOnStatusChange(oldMap, newMap);
        Test.stopTest();

        // Verify the transaction type is updated to 'ERR'
        newRec = [SELECT Id, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        System.assertEquals('ERR', newRec.Transaction__c);
    }

    // Test case for when the status remains the same (no update expected)
    @isTest
    static void testNoStatusChange() {
        // Create old record
        Reciprocal__c oldRec = createReciprocalRecord('New', 'PAY');
        
        // No status change
        Reciprocal__c newRec = [SELECT Id, Status__c, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        
        // Simulate the old and new map
        Map<Id, Reciprocal__c> oldMap = new Map<Id, Reciprocal__c>{oldRec.Id => oldRec};
        Map<Id, Reciprocal__c> newMap = new Map<Id, Reciprocal__c>{newRec.Id => newRec};

        // Call the method being tested
        Test.startTest();
        FSL_ReciprocalApexClass.updateTransactionTypeOnStatusChange(oldMap, newMap);
        Test.stopTest();

        // Verify the transaction type has not changed
        newRec = [SELECT Id, Transaction__c FROM Reciprocal__c WHERE Id = :oldRec.Id];
        System.assertEquals('PAY', newRec.Transaction__c);
    }
	/**EMI - SSFI-380**/
}