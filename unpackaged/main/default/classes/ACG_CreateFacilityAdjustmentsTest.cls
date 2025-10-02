@isTest
public class ACG_CreateFacilityAdjustmentsTest {
    private static Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
    private static Boolean isNEOrg = orgData.Name == 'AAA Northeast';
    private static RecordType facType = [
        SELECT Id 
        FROM RecordType 
        WHERE DeveloperName = 'Facility_Territory' 
        AND SobjectType = 'ServiceTerritory' 
        LIMIT 1
    ];

    static void setup() {
        OperatingHours opHrs = new OperatingHours(
            Name = 'Daytime',
            TimeZone = 'America/New_York'
        );
        insert opHrs;
        
        ServiceTerritory fac = new ServiceTerritory(
            Name = 'Test Service Territory',
            RecordTypeId = facType.Id,
            OperatingHoursId = opHrs.Id, 
            Payment_Schedule__c = 'Monthly',
            IsActive = true
        );
        insert fac;
        
        insert new Statement__c(
            Start_Date__c = Date.newInstance(2024, 2, 1),
            End_Date__c = Date.newInstance(2024, 2, 29),
            Service_Territory__c = fac.Id,
            Status__c = 'Unreconciled'
        );
        
        insert new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = Date.newinstance(2024, 2, 1),
            Service_Territory__c = fac.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Interstate Battery' : 'BATTERY',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Payment_Amount__c = 100            
        );
    }

    @isTest
    static void checkForDupeStmtsTest() {
        setup();

        ServiceTerritory fac = [SELECT Id FROM ServiceTerritory];
        Statement__c createdStmt = [
            SELECT Id, Status__c
            FROM Statement__c
            WHERE Service_Territory__c = :fac.Id
        ];

        insert new List<Statement__c> { 
            new Statement__c(
                Start_Date__c = Date.newInstance(2024, 3, 1),
                End_Date__c = Date.newInstance(2024, 3, 31),
                Service_Territory__c = fac.Id,
                Status__c = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c = Date.newInstance(2024, 4, 1),
                End_Date__c = Date.newInstance(2024, 4, 30),
                Service_Territory__c = fac.Id,
                Status__c = 'Unreconciled'
            )
        };

        createdStmt.Status__c = 'Reconciled';
        update createdStmt;

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = Date.newinstance(2024, 2, 1),
            Service_Territory__c = fac.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Interstate Battery' : 'BATTERY',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 2,
            ACG_Payment_Amount__c = 100            
        );
        insert fa;

        List<Invoice__c> invcList = [
            SELECT Id, Statement__r.Start_Date__c 
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        System.assertEquals(2, invcList.size(), 'Failed to create the correct number of Invoices.');

        List<Statement__c> stmtList = [
            SELECT Id, Start_Date__c
            FROM Statement__c
            WHERE Service_Territory__c = :fac.Id
        ];
        Set<Date> stmtDateSet = new Set<Date>();
        Boolean hasDuplicateStartDate = false;

        for (Statement__c stmt : stmtList) {
            Date stmtStartDate = stmt.Start_Date__c;

            if (!stmtDateSet.contains(stmtStartDate)) {
                stmtDateSet.add(stmtStartDate);
            } else {
                hasDuplicateStartDate = true;
                break;
            }
        }

        System.assertEquals(false, hasDuplicateStartDate, 'Created duplicate Statements.');
    }
    
    @isTest
    static void afterInsertTest() {
        // FA gets created in setup method which invokes class being tested
        setup();

        List<ACG_Facility_Adjustment__c> facAdj = [SELECT Id FROM ACG_Facility_Adjustment__c];
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];

        System.assertEquals(facAdj.size(), invoices.size(), 'One invoice should be created');

        ServiceTerritory fac = [SELECT Id FROM ServiceTerritory];

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = Date.newinstance(2024, 1, 1),
            Service_Territory__c = fac.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Interstate Battery' : 'BATTERY',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 2,
            ACG_Payment_Amount__c = 100            
        );
        insert fa;

        List<Invoice__c> invcList = [
            SELECT Id, Statement__r.Start_Date__c 
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        System.assertEquals(2, invcList.size(), 'Failed to create the correct number of Invoices.');

        Set<Date> stmtDateSet = new Set<Date>();
        Boolean hasDuplicateStartDate = false;

        for (Invoice__c invc : invcList) {
            Date stmtStartDate = invc.Statement__r.Start_Date__c;

            if (!stmtDateSet.contains(stmtStartDate)) {
                stmtDateSet.add(stmtStartDate);
            } else {
                hasDuplicateStartDate = true;
                break;
            }
        }

        System.assertEquals(false, hasDuplicateStartDate, 'Created duplicate Statements.');
    }
    
    @isTest
    static void futureMethodTest() {
        setup();
        
        String STATUS_ACTIVE = 'Active';
        List<ACG_Facility_Adjustment__c> lstFacAdj = [
            SELECT 
                Id, 
                ACG_Start_Date__c, 
                ACG_End_Date__c, 
                Service_Territory__c, 
                ACG_Adjustment_Category__c, 
                ACG_Adjustment_Type__c, 
                ACG_Payment_Amount__c, 
                ACG_Adjustments_Remaining__c, 
                ACG_Status__c,
                ACG_No_of_Payments__c,
                Reactivation_Date__c,
                Service_Territory__r.Payment_Schedule__c
            FROM ACG_Facility_Adjustment__c 
            WHERE ACG_Adjustments_Remaining__c > 0
            AND ACG_Status__c = :STATUS_ACTIVE
        ]; 
        
        Test.startTest();
        // Call the future method
        ACG_Facility_Adj_TriggerHandler.createFacAdjInvoices(lstFacAdj);
        Test.stopTest();
        
        // Assertions to verify the future method's effects
        List<Invoice__c> invcList = [SELECT Id FROM Invoice__c];
        System.assertEquals(1, invcList.size(), 'Expected 1 Invoice.');
    }

    @isTest
    static void newStatementTest() {
        setup();
        
        // Test for future date processing.
        Date validStartDate = Date.newinstance(2024, 3, 14); // create a Fac Adj with a date in the future
        Date validEndDate = Date.newinstance(2024, 3, 14);
        Date statementFutureStartDate = Date.newinstance(2024,3,01);
        ServiceTerritory serviceTerr = [SELECT Id FROM ServiceTerritory WHERE Name = 'Test Service Territory'];
        
        // Create Facility Adjustment record
        insert new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = validStartDate,
            Service_Territory__c = serviceTerr.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Bonus': 'BASIC',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Payment_Amount__c = 100            
        );
        
        // Assertions to verify that no new Statements were created
        List<Statement__c> stmt = [
            SELECT Id 
            FROM Statement__c 
            WHERE Start_Date__c =:statementFutureStartDate
        ];

        System.assertEquals(0, stmt.size(), 'No statement should be created');   
    }

    @isTest
    static void backdatedFATest() {
        Integer numPayments = 3;

        OperatingHours opHrs = new OperatingHours(
            Name = 'Daytime',
            TimeZone = 'America/New_York'
        );
        insert opHrs;
        
        ServiceTerritory fac = new ServiceTerritory(
            Name = 'Test Service Territory',
            RecordTypeId = facType.Id,
            OperatingHoursId = opHrs.Id, 
            Payment_Schedule__c = 'Bi-monthly',
            IsActive = true
        );
        insert fac;
        
        List<Statement__c> stmtList = new List<Statement__c>{
            new Statement__c(
                Start_Date__c 		 = Date.newInstance(2024, 2, 1),
                End_Date__c   		 = Date.newInstance(2024, 2, 15),
                Service_Territory__c = fac.Id,
                Status__c 		     = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c 		 = Date.newInstance(2024, 2, 16),
                End_Date__c   		 = Date.newInstance(2024, 2, 29),
                Service_Territory__c = fac.Id,
                Status__c 		     = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c 		 = Date.newInstance(2024, 3, 1),
                End_Date__c   		 = Date.newInstance(2024, 3, 15),
                Service_Territory__c = fac.Id,
                Status__c 		     = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c 		 = Date.newInstance(2024, 3, 16),
                End_Date__c   		 = Date.newInstance(2024, 3, 31),
                Service_Territory__c = fac.Id,
                Status__c 		     = 'Unreconciled'
            )
        };
        insert stmtList;

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = Date.newinstance(2024, 1, 1),
            Service_Territory__c = fac.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Interstate Battery' : 'BATTERY',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = numPayments,
            ACG_Payment_Amount__c = 1000.0            
        );
        insert fa;

        // ACG_CreateFacilityAdjustments.processFacilityAdjustments(
        //     new List<ACG_Facility_Adjustment__c>{fa}
        // );

        List<Invoice__c> invcList = [
            SELECT Id, Statement_Date__c, Statement__c
            FROM Invoice__c 
            WHERE Facility_Adjustment__c = :fa.Id
            ORDER BY Statement_Date__c DESC
        ];
        List <ACG_Facility_Adjustment_Payment__c> fapList = [
            SELECT Id 
            FROM ACG_Facility_Adjustment_Payment__c
            WHERE ACG_Adjustment_ID__c = :fa.Id
        ];
        stmtList = [
            SELECT Id, Start_Date__c
            FROM Statement__c
        ];

        System.assertEquals(numPayments, invcList.size(), 'Failed to create the appropriate number of Invoices.');
        System.assertEquals(numPayments, fapList.size(), 'Failed to create the appropriate number of Facility Adjustment Payments.');

        Map<String, Statement__c> stmtMap = new Map<String, Statement__c>();

        for (Statement__c stmt : stmtList) {
            stmtMap.put(stmt.Id, stmt);
        }

        for (Invoice__c invc : invcList) {
            Statement__c stmt = stmtMap.get(invc.Statement__c);
    
            System.assertEquals(stmt.Start_Date__c, invc.Statement_Date__c, 'Failed to create the appropriate Invoice.');
        }
    }
}