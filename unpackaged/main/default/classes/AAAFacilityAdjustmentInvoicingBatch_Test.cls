@IsTest
public class AAAFacilityAdjustmentInvoicingBatch_Test {

    private static Integer NUM_FA = 10;
    private static Integer NUM_STMT = 5;
    //          query = 'SELECT Id,Service_Territory__c,ACG_Adjustment_Category__c, ACG_Adjustment_Type__c,ACG_Payment_Amount__c FROM ACG_Facility_Adjustment__c WHERE ACG_Status__c = \'Active\' AND ACG_Adjustments_Remaining__c > 0';
//SELECT Id,Service_Territory__c,Start_Date__c FROM Statement__c WHERE Service_Territory__c IN: setFacilityId AND Start_Date__c =: Date.Today()
//
    @TestSetup
    static void setup() {
        OperatingHours hours = new OperatingHours();
        hours.Name = 'Test Hours';
        hours.TimeZone = 'America/New_York';
        insert hours;
        
        ServiceTerritory testTerritory = new ServiceTerritory();
        testTerritory.Name = 'Test Territory';
        testTerritory.OperatingHoursId = hours.Id;
        insert testTerritory;
        
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId,1,false,false)[0];
        insert objFacility1 ;
        
		// create some ACG_Facility_Adjustment__c records
        List<ACG_Facility_Adjustment__c> records = new List<ACG_Facility_Adjustment__c>();
        for(Integer i=0; i<NUM_FA; i++) {
            ACG_Facility_Adjustment__c rec = new ACG_Facility_Adjustment__c();
            rec.ACG_Status__c = 'Active';
            rec.Facility_Adjustment_Name__c = 'Test FA Name ' + i;
            rec.Service_Territory__c = testTerritory.Id;
            rec.ACG_Adjustment_Category__c='BATTERY';
            rec.ACG_Adjustment_Type__c='Debit';
            rec.ACG_Payment_Amount__c=4734.00;
            rec.Account__c = objFacility1.Id ; 
            records.add(rec);
        }
        insert records;
        
        // create some statements
        List<Statement__c> statements = new List<Statement__c>();
        for(Integer i=0; i<NUM_STMT; i++) {
            Statement__c stmt = new Statement__c();
            stmt.Service_Territory__c = testTerritory.Id;
            stmt.Start_Date__c = Date.Today();
            statements.add(stmt);
        }
        insert statements;
    }
    
    @IsTest
    static void testBatch() {
        Test.startTest();
        // Instantiate your batch class and call the start method
        AAAFacilityAdjustmentInvoicingBatch batchInstance = new AAAFacilityAdjustmentInvoicingBatch();
        Id batchProcessId = Database.executeBatch(batchInstance);
        // Assert that the returned QueryLocator is not null and contains expected data
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id,Name FROM Invoice__c];
        Assert.areEqual(NUM_FA, invoices.size(), 'Expected invoices for each ACG_Facility_Adjustment__c');
    }
    
}