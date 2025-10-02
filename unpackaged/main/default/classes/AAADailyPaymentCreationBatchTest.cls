@isTest
public class AAADailyPaymentCreationBatchTest {
    private static RecordType facAdjType = [
        SELECT Id 
        FROM RecordType 
        WHERE DeveloperName = 'Facility_Adjustment' 
        AND SobjectType = 'Invoice__c' 
        LIMIT 1
    ];
    private static Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
    private static Boolean isNEOrg = orgData.Name == 'AAA Northeast';

    static void createTestData(Map<String, String> argMap) {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType ersType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ERS' LIMIT 1];
        Date startDate = Date.today();
        Date endDate = Date.today();

        if (startDate.day() > 1 && startDate.day() < 16) {
            startDate = Date.newInstance(startDate.year(), startDate.month(), 1);
        } else {
            startDate = Date.newInstance(startDate.year(), startDate.month(), 16);
        }

        if (startDate.day() == 1) {
            endDate = Date.newInstance(endDate.year(), endDate.month(), 15);
        } else {
            endDate = Date.newInstance(endDate.year(), endDate.month() + 1, 1);
            endDate = endDate.addDays(-1);
        }

        insert new BackOffice_Settings__c(
            Club_Code__c = argMap.get('clubCode')
        );

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            IsActive = true,
            Non_Payment_Facility__c = false
        );
        insert svcTerritory;
        
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId, 1, false, false)[0];
        insert objFacility1;

        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Unreconciled',
            Processed__c = false
        );
        insert stmt;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id,
            Account__c = objFacility1.Id,
            ACG_Start_Date__c = startDate,
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Payment_Amount__c = 100    
        );
        insert facAdj;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = [
            SELECT Id 
            FROM ACG_Facility_Adjustment_Payment__c 
            WHERE ACG_Adjustment_ID__c = :facAdj.Id
        ];

        List<Invoice__c> invcList = new List<Invoice__c>{
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Basic',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Basic Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Other',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Other Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Plus',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Plus Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'RV',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'RV Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Premier',
                Type__c = 'ERS Calls'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Premier Reciprocal',
                Type__c = 'Reciprocals'
            ),
            new Invoice__c(
                Status__c = 'Ready for Payment',
                Facility_Adjustment__c = facAdj.Id,
                Service_Territory__c = svcTerritory.Id,
                Statement__c = stmt.Id,
                Facility_Adjustment_Category__c = 'Hardware',
                RecordTypeId = facAdjType.Id,
                Type__c = 'Facility Adjustments'
            )
        };
        insert invcList;


        List<Invoice_Line_Item__c> invcListLI = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(
                Invoice__c = invcList[0].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[1].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[2].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[3].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[4].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'O',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[5].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'O',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[6].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'P',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[7].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'P',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[8].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'R',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[9].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'R',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[10].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'E',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[11].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'E',
                Cost__c = 10.0,
                Tax__c = 0.0
            ),
            new Invoice_Line_Item__c(
                Invoice__c = invcList[12].Id,
                Facility_Adjustment_Payment__c = facAdjPmt.Id,
                Charge_to_Account__c = 'B',
                Cost__c = 10.0,
                Tax__c = 0.0
            )
        };
        insert invcListLI;

        stmt.Status__c = 'Reconciled';
        update stmt;
    }

    @isTest
    static void paymentCreationBatchTestNE() {
        createTestData(new Map<String, String>{
            'clubCode' => '240'
        });

        Test.startTest();
        AAADailyPaymentCreationBatch bc = new AAADailyPaymentCreationBatch();
        Database.executeBatch(bc);
        Test.stopTest();

        Statement__c stmt = [SELECT Id, Processed__c, Name FROM Statement__c WHERE Statement_Name__c = 'Apex Test Statement 1' LIMIT 1];
        List<Invoice__c> invcList = [SELECT Id, Status__c FROM Invoice__c WHERE Statement__c =: stmt.Id];
        List<Payment__c> pmtList = [SELECT Id, Line_Row__c, Amount__c, Item_Description__c FROM Payment__c WHERE Document_Number__c =: stmt.Name ORDER BY Line_Row__c];

        System.assertEquals(stmt.Processed__c, true, 'Statement was not processed.');

        for(Invoice__c invc : invcList) {
            System.assertEquals(invc.Status__c, 'Submitted for Payment', 'Invoice status was not updated.');
        }

        System.assertEquals(12, pmtList.size(), 'The appropriate amount of Payment records was not created.');

        for(Integer i = 1; i < 13; i++) {
            Payment__c pmt = pmtList[i - 1];

            if(pmt.Item_Description__c == 'Hardware') {
                System.assertEquals(pmt.Amount__c, 30.0, 'Amount on Payment record not updated correctly.');
            }

            System.assertEquals(pmt.Line_Row__c, i, 'Line rows were not correctly updated.');
        }
    }

    @isTest
    static void paymentCreationBatchTestACA() {
        createTestData(new Map<String, String>{
            'clubCode' => '212'
        });

        Test.startTest();
        AAADailyPaymentCreationBatch bc = new AAADailyPaymentCreationBatch();
        Database.executeBatch(bc);
        Test.stopTest();

        Statement__c stmt = [SELECT Id, Processed__c, Name FROM Statement__c WHERE Statement_Name__c = 'Apex Test Statement 1' LIMIT 1];
        List<Invoice__c> invcList = [SELECT Id, Status__c FROM Invoice__c WHERE Statement__c =: stmt.Id];
        List<Payment__c> pmtList = [SELECT Id, Line_Row__c, Amount__c, Item_Description__c FROM Payment__c WHERE Document_Number__c =: stmt.Name ORDER BY Line_Row__c];

        System.assertEquals(stmt.Processed__c, true, 'Statement was not processed.');

        for(Invoice__c invc : invcList) {
            System.assertEquals(invc.Status__c, 'Submitted for Payment', 'Invoice status was not updated.');
        }

        System.assertEquals(12, pmtList.size(), 'The appropriate amount of Payment records was not created.');

        for(Integer i = 1; i < 13; i++) {
            Payment__c pmt = pmtList[i - 1];

            if(pmt.Item_Description__c == 'Hardware') {
                System.assertEquals(pmt.Amount__c, 30.0, 'Amount on Payment record not updated correctly.');
            }

            System.assertEquals(pmt.Line_Row__c, i, 'Line rows were not correctly updated.');
        }
    }

    @isTest
    static void paymentCreationBatchExceptionTest() {
        createTestData(new Map<String, String>{
            'clubCode' => 'OOT'
        });

        Test.startTest();
        AAADailyPaymentCreationBatch bc = new AAADailyPaymentCreationBatch();
        Database.executeBatch(bc);
        Test.stopTest();

        List<FSL_Application_Log__c> appLogList = [SELECT Id FROM FSL_Application_Log__c];

        System.assertEquals(true, appLogList.size() > 0, 'Exception was not encountered.');
    }

    @isTest
    static void paymentCreationBatchConstructorTest1() {
        createTestData(new Map<String, String>{
            'clubCode' => '240'
        });

        Statement__c stmt1 = [SELECT Id FROM Statement__c LIMIT 1];
        List<Invoice__c> invcList = [SELECT Id FROM Invoice__c];

        Test.startTest();
        AAADailyPaymentCreationBatch bc = new AAADailyPaymentCreationBatch(
            new Map<String, Object>{
                'processedStmtList' => new List<String>{stmt1.Id}, 
                'totalStmtUpdateList' => new List<Statement__c>{stmt1},
                'totalPmtInsertList' => new List<Payment__c>{new Payment__c()},
                'exceptionMsgSet' => new Set<String>{'test'}
            }
        );
        Database.executeBatch(bc);
        Test.stopTest();

        List<Payment__c> pmtList = [SELECT Id FROM Payment__c];

        System.assertEquals(0, pmtList.size(), 'Unexpected Payment records created.');
    }

    @isTest
    static void paymentCreationBatchConstructorTest2() {
        createTestData(new Map<String, String>{
            'clubCode' => '240'
        });

        Statement__c stmt1 = [SELECT Id FROM Statement__c LIMIT 1];
        ServiceTerritory fac = [SELECT Id FROM ServiceTerritory LIMIT 1];
        List<Invoice__c> invcList = [SELECT Id FROM Invoice__c];

        Statement__c stmt2 = new Statement__c(
            Service_Territory__c = fac.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt2;

        Test.startTest();
        AAADailyPaymentCreationBatch bc = new AAADailyPaymentCreationBatch(
            new Map<String, Object>{
                'processedStmtList' => new List<String>{stmt1.Id}, 
                'totalStmtUpdateList' => new List<Statement__c>{stmt1}, 
                'totalPmtInsertList' => new List<Payment__c>{new Payment__c()},
                'exceptionMsgSet' => new Set<String>{'test'},
                'testStatementIdList' => new List<String>{stmt2.Id}
            }
        );
        
        Database.executeBatch(bc);
        Test.stopTest();

        List<Payment__c> pmtList = [SELECT Id FROM Payment__c];

        System.assertEquals(1, pmtList.size(), 'Expected Payment record to be created.');
    }

    @isTest
    static void paymentCreationBatchQuickSortTest() {
        AAADailyPaymentCreationBatch testBatch = new AAADailyPaymentCreationBatch();
        List<Integer> orderedResList = new List<Integer>();
        List<List<Object>> objList = new List<List<Object>>{
            new List<Object>{
                'test', 54
            },
            new List<Object>{
                'test', 1
            },
            new List<Object>{
                'test', 53
            },
            new List<Object>{
                'test', 1000
            },
            new List<Object>{
                'test', 6
            }
        };

        testBatch.quickSort(objList, 0, objList.size() - 1);

        for (List<Object> container : objList) {
            orderedResList.add((Integer) container[1]);
        }

        System.assertEquals(1, orderedResList[0], 'Failed to order list.');
        System.assertEquals(6, orderedResList[1], 'Failed to order list.');
        System.assertEquals(53, orderedResList[2], 'Failed to order list.');
        System.assertEquals(54, orderedResList[3], 'Failed to order list.');
        System.assertEquals(1000, orderedResList[4], 'Failed to order list.');
    }

    @isTest
    static void negativeStatementCostTest() {
        createTestData(new Map<String, String>{
            'clubCode' => isNEOrg ? '240' : '212'
        });

        ACG_Facility_Adjustment__c facAdj = [
            SELECT Id, Service_Territory__c, Account__c
            FROM ACG_Facility_Adjustment__c
            LIMIT 1
        ];
        Statement__c stmt = [
            SELECT Id, Total_Cost__c
            FROM Statement__c
            LIMIT 1
        ];

        Test.startTest();
        ACG_Facility_Adjustment__c newFacAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment 42',
            Service_Territory__c = facAdj.Service_Territory__c,
            Account__c = facAdj.Account__c,
            ACG_Adjustment_Type__c = 'Debit'
        );
        insert newFacAdj;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = newFacAdj.Id,
            ACG_Payment_Amount__c = 100000.0
        );
        insert facAdjPmt;

        Invoice__c invc = new Invoice__c(
            Status__c = 'Ready for Payment',
            Facility_Adjustment__c = newFacAdj.Id,
            Service_Territory__c = newFacAdj.Service_Territory__c,
            Statement__c = stmt.Id,
            Facility_Adjustment_Category__c = 'Basic',
            Type__c = 'ERS Calls',
            Facility_Adjustment_Type__c = 'Debit'
        );
        insert invc;

        insert new Invoice_Line_Item__c(
            Invoice__c = invc.Id,
            Facility_Adjustment_Payment__c = facAdjPmt.Id,
            Charge_to_Account__c = 'B',
            Cost__c = -100000.0,
            Tax__c = 0.0
        );

        Database.executeBatch(new AAADailyPaymentCreationBatch());
        Test.stopTest();

        List<ACG_Facility_Adjustment__c> resList = [
            SELECT Id, ACG_Description__c
            FROM ACG_Facility_Adjustment__c
            WHERE ACG_Description__c = 'THE FACILITY DID NOT EARN ENOUGH TO PAY FOR CURRENT ADJUSTMENTS'
        ];
        
        System.assertEquals(1, resList.size(), 'Failed to create the appropriate amount of Facility Adjustments.');
    }

    public static List<Statement_Field_Spend_Category_Mappings__mdt> mockFieldSCMdtNE() {
        return new List<Statement_Field_Spend_Category_Mappings__mdt>{
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost__c',
                Label__c = 'Basic_Cost__c',
                Spend_Category_Label__c = 'Basic',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Adjustment__c',
                Label__c = 'Basic_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Basic',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Reciprocal__c',
                Label__c = 'Basic_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Basic Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Basic_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Basic Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Adjustment__c',
                Label__c = 'Other_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Other',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_ERS__c',
                Label__c = 'Other_Cost_ERS__c',
                Spend_Category_Label__c = 'Other',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Reciprocal__c',
                Label__c = 'Other_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Other Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Other_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Other Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost__c',
                Label__c = 'Plus_Cost__c',
                Spend_Category_Label__c = 'Plus',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Adjustment__c',
                Label__c = 'Plus_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Plus',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Reciprocal__c',
                Label__c = 'Plus_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Plus Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Plus_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Plus Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost__c',
                Label__c = 'Premier_Cost__c',
                Spend_Category_Label__c = 'Premier',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Adjustment__c',
                Label__c = 'Premier_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Premier',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Reciprocal__c',
                Label__c = 'Premier_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Premier Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Premier_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Premier Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost__c',
                Label__c = 'RV_Cost__c',
                Spend_Category_Label__c = 'RV',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Adjustment__c',
                Label__c = 'RV_Cost_Adjustment__c',
                Spend_Category_Label__c = 'RV',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Reciprocal__c',
                Label__c = 'RV_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'RV Reciprocal',
                Club_Code__c = '240'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Reciprocal_Adjustment__c',
                Label__c = 'RV_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'RV Reciprocal',
                Club_Code__c = '240'
            )
        };
    }

    public static List<Invoice__c> mockInvcList() {
        List<Invoice__c> invcList = new List<Invoice__c>();
        ACG_Facility_Adjustment__c facAdj = [
            SELECT Id
            FROM ACG_Facility_Adjustment__c
            LIMIT 1
        ];
        ServiceTerritory svcTerritory = [
            SELECT Id
            FROM ServiceTerritory
            LIMIT 1
        ];
        Statement__c stmt = [
            SELECT Id
            FROM Statement__c
            LIMIT 1
        ];

        for (Integer i = 0; i < 10; i++) {
            invcList.add(
                new Invoice__c(
                    Status__c = 'Ready for Payment',
                    Facility_Adjustment__c = facAdj.Id,
                    Service_Territory__c = svcTerritory.Id,
                    Statement__c = stmt.Id,
                    Facility_Adjustment_Category__c = 'Hardware',
                    RecordTypeId = facAdjType.Id,
                    Type__c = 'Facility Adjustments'
                )
            );
        }

        return invcList;
    }
}