@isTest
public class ACG_Facility_Adj_TriggerHandlerTest {
    private static String SerTerrRecordTypeID = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Facility Territory').getRecordTypeId();
    private static String invoiceRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
    private static Organization orgData = [
        SELECT Id, Name 
        FROM Organization 
        LIMIT 1
    ];
    private static Boolean isNEOrg = orgData.Name == 'AAA Northeast';

    @TestSetup
    static void setup() {
        Date startDate = Date.newInstance(2024, 2, 1);
        Date endDate = Date.newInstance(2024, 2, 29);
        RecordType facAdjType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Facility_Adjustment' 
            AND SobjectType = 'Invoice__c' 
            LIMIT 1
        ];

        OperatingHours OperatingHrs = new OperatingHours(
            Name = 'Daytime',
            TimeZone = 'America/New_York'
        );
        insert OperatingHrs;

        ServiceTerritory servTerr = new ServiceTerritory(
            Name = 'Test Service Territory',
            RecordTypeId = SerTerrRecordTypeID,
            OperatingHoursId = OperatingHrs.Id, 
            Payment_Schedule__c = 'Monthly',
            IsActive = true
        );
        insert servTerr;

        Statement__c stmt = new Statement__c(
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Service_Territory__c = servTerr.Id,
            Status__c = 'Unreconciled'
        );
        insert stmt;
        
        Date validDate = Date.newinstance(2024, 2, 1);

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = validDate,
            Service_Territory__c = servTerr.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Bonus' : 'BASIC',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Payment_Amount__c = 100            
        );
        insert fa;
    }
    
    @isTest
    static void afterInsertTest() {
        // Query for the test data
        ACG_Facility_Adjustment__c facAdj = [SELECT Id FROM ACG_Facility_Adjustment__c LIMIT 1];
        
        Test.startTest();
        // Perform a DML operation to invoke the trigger
        update facAdj;
        Test.stopTest();
        
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        System.assertEquals(1, invoices.size(), 'One invoice should be created');
    }
    
    @isTest
    static void futureMethodTest() {
        // Prepare a Set of Ids as expected by the future method
        Set<Id> setFacAdjIds = new Set<Id>{
            [SELECT Id FROM ACG_Facility_Adjustment__c LIMIT 1].Id
        };
        String status = 'Active';
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
                ACG_No_of_Payments__c,
                ACG_Status__c,
                Service_Territory__r.Payment_Schedule__c,
                Reactivation_Date__c
            FROM ACG_Facility_Adjustment__c 
            WHERE Id IN :setFacAdjIds
            AND ACG_Adjustments_Remaining__c > 0
            AND ACG_Status__c = :status
        ]; 
        Boolean encounteredError = false;
        
        if (!lstFacAdj.isEmpty()) {
            ACG_CreateFacilityAdjustments.processFacilityAdjustments(lstFacAdj);
        }
        
        Test.startTest();
        try {
            // Call the future method
            ACG_Facility_Adj_TriggerHandler.createFacAdjInvoices(lstFacAdj);
        } catch (Exception e) {
            System.debug(e.getMessage() + '\n\n' + e.getStackTraceString());
            encounteredError = true;
        }
        Test.stopTest();
        
        System.assertEquals(false, encounteredError, 'Encountered error invoking method.');
    }

    @isTest
    static void negativeTest() {
        Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
        Boolean isNEOrg = orgData.Name == 'AAA Northeast';
        ServiceTerritory servTerrId = [SELECT Id FROM ServiceTerritory WHERE Name = 'Test Service Territory'];
        
        // Create a date past the current statement's period - No payments/invoices should be created.
        Date notValidDate = Date.today();
        notValidDate = Date.newInstance(
            notValidDate.year(), 
            notValidDate.month() + 1, 
            16
        );
        
        // Create Facility Adjustment record
        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = notValidDate,
            Service_Territory__c = servTerrId.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Bonus' : 'BASIC',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Payment_Amount__c = 100            
        );
        insert facAdj;
        
        // Assertions to verify that no Invoice was created
        List<Invoice__c > testInvoice = [
            SELECT Id 
            FROM Invoice__c 
            WHERE Facility_Adjustment__c = :facAdj.Id
        ];

        System.assertEquals(0, testInvoice.size(), 'Invoices should not have been created');
    }

    @isTest
    static void validateBeforeInsertUpdateTest() {
        List<ServiceTerritory> facList = [SELECT Id FROM ServiceTerritory];
        String activeStatusErrMsg = 'Start Date is required for Active Facility Adjustments.';
        String cancelledStatusErrMsg = 'End Date is required for Cancelled Facility Adjustments.';
        String exceptionMsg = '';

        try {
            insert new ACG_Facility_Adjustment__c(
                ACG_Start_Date__c = null,
                Service_Territory__c = facList[0].Id,
                ACG_Adjustment_Category__c = isNEOrg ? 'Bonus' : 'BASIC',
                ACG_Adjustment_Type__c = 'Debit',
                ACG_Status__c = 'Active',
                ACG_No_of_Payments__c = 1,
                ACG_Payment_Amount__c = 100            
            );
        } catch (Exception e) {
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionMsg.contains(activeStatusErrMsg), 'Failed to validate Facility Adjustment.');

        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c, ACG_End_Date__c
            FROM ACG_Facility_Adjustment__c
            LIMIT 1
        ];
        
        try {
            fa.ACG_End_Date__c = null;
            fa.ACG_Status__c = 'Cancelled';

            update fa;
        } catch (Exception e) {
            exceptionMsg = e.getMessage();
        }

        System.assertEquals(true, exceptionMsg.contains(cancelledStatusErrMsg), 'Failed to validate Facility Adjustment.');
    }

    @isTest
    static void cancelFADeleteInvcsTest() {
        Date startDate = Date.newInstance(2024, 3, 1);
        Date endDate = Date.newInstance(2024, 3, 31);
        ACG_Facility_Adjustment__c fa = [
            SELECT 
                Id, 
                ACG_Status__c, 
                ACG_End_Date__c,
                ACG_Adjustment_Category__c,
                ACG_Adjustment_Type__c,
                Service_Territory__c
            FROM ACG_Facility_Adjustment__c
            LIMIT 1
        ];
        Statement__c stmt = [SELECT Id, Status__c FROM Statement__c LIMIT 1];
        ServiceTerritory fac = [SELECT Id FROM ServiceTerritory LIMIT 1];

        stmt.Status__c = 'Reconciled';
        update stmt;

        Statement__c newStmt = new Statement__c(
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Service_Territory__c = fac.Id,
            Status__c = 'Unreconciled'
        );
        insert newStmt;

        insert new Invoice__c(
            Facility_Adjustment__c = fa.Id,
            Facility_Adjustment_Category__c = fa.ACG_Adjustment_Category__c,
            Facility_Adjustment_Type__c = fa.ACG_Adjustment_Type__c,
            Service_Territory__c = fa.Service_Territory__c,
            Status__c = 'Ready for Processing',
            Type__c = 'Facility Adjustments',
            Statement_Date__c = newStmt.Start_Date__c,
            RecordTypeId = invoiceRecId,
            Statement__c = newStmt.Id   
        );

        List<Invoice__c> invcList = [
            SELECT Id 
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        System.assertEquals(2, invcList.size(), 'Expected given amount of associated Invoices.');

        fa.ACG_End_Date__c = Date.newinstance(2024, 2, 14);
        fa.ACG_Status__c = 'Cancelled';

        update fa;

        invcList = [
            SELECT Id 
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        System.assertEquals(1, invcList.size(), 'Failed to delete associated Invoices.');
    }

    @isTest
    static void validateUserPicklistValueTest() {
        Boolean hasException = false;
        String errMsg = 'is not an available value. Please pick from the following values:';
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@salesforce.com';
        Profile boMPProfile = [SELECT Id FROM Profile WHERE Name = 'BO MP - Full Access'];
        User boUser = new User(
            Alias = 'standt', 
            Email = 'standarduser@salesforce.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = boMPProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        System.runAs(boUser) {
            try {
                insert new ACG_Facility_Adjustment__c(
                    ACG_Status__c = 'Closed'
                );
            } catch (Exception e) {
                hasException = e.getMessage().contains(errMsg);
            }
        }

        System.assertEquals(true, hasException, 'Failed to validate Status field on insert.');
    }

    @isTest
    static void deferActivateRelatedInvoicesTest() {
        Boolean isDeferred = true;
        Boolean isActive = true;
        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c 
            FROM ACG_Facility_Adjustment__c 
            LIMIT 1
        ];

        fa.ACG_Status__c = 'Deferred';
        update fa;

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        for (Invoice__c invc : invcList) {
            if (invc.Status__c != 'Deferred') {
                isDeferred = false;
                break;
            }
        }

        System.assertEquals(true, invcList.size() > 0, 'Failed to create Invoices.');
        System.assertEquals(true, isDeferred, 'Failed to defer Invoices.');

        fa.ACG_Status__c = 'Active';
        fa.ACG_End_Date__c = Date.newInstance(2024, 2, 29);
        fa.Reactivation_Date__c = Date.newInstance(2024, 2, 29);
        update fa;

        invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        for (Invoice__c invc : invcList) {
            if (invc.Status__c != 'Ready for Processing') {
                isActive = false;
                break;
            }
        }

        System.assertEquals(true, isActive, 'Failed to activate Invoices.');
    }

    @isTest
    static void validateBeforeDeleteTest() {
        Boolean hasError = false;
        String errMsg = 'Cannot delete';
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@salesforce.com';
        Profile fslAPIOnlyProfile = [SELECT Id FROM Profile WHERE Name = 'FSL API Only'];
        User boUser = new User(
            Alias = 'standt', 
            Email = 'standarduser@salesforce.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = fslAPIOnlyProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c
            FROM ACG_Facility_Adjustment__c
        ];
        Statement__c stmt = [
            SELECT Id, Status__c
            FROM Statement__c
        ];

        fa.ACG_Status__c = 'Closed';
        update fa;
        
        System.runAs(boUser) {
            try {
                delete fa;
            } catch (Exception e) {
                if (e.getMessage().contains(errMsg)) {
                    hasError = true;
                }
            }
        }

        System.assertEquals(true, hasError, 'Failed to prevent deletion of a closed Facility Adjustment.');

        hasError = false;
        errMsg = 'Invoice(s) that are under reconciled Statements.';
        fa.ACG_Status__c = 'Active';
        update fa;

        stmt.Status__c = 'Reconciled';
        update stmt;

        System.runAs(boUser) {
            try {
                delete fa;
            } catch (Exception e) {
                if (e.getMessage().contains(errMsg)) {
                    hasError = true;
                }
            }
        }

        System.assertEquals(true, hasError, 'Failed to prevent deletion of a Facility Adjustment that has Invoices marked "Ready for Payment"');
    }

    @isTest
    static void deleteRelatedInvoicesTest() {
        List<ACG_Facility_Adjustment__c> faList = [
            SELECT Id
            FROM ACG_Facility_Adjustment__c
        ];

        delete faList;

        List<Invoice__c> invcList = [
            SELECT Id
            FROM Invoice__c
            WHERE Type__c = 'Facility Adjustments'
        ];

        System.assertEquals(0, invcList.size(), 'Failed to delete associated Invoices.');
    }

    @isTest
    static void preventActivationFromDeferredTest() {
        Boolean hasError = false;
        String errMsg = '"Reactivation Date" must be filled when re-activating a deferred Facility Adjustment.';
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@salesforce.com';
        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c 
            FROM ACG_Facility_Adjustment__c 
            LIMIT 1
        ];
        Profile fslAPIOnlyProfile = [SELECT Id FROM Profile WHERE Name = 'FSL API Only'];
        User boUser = new User(
            Alias = 'standt', 
            Email = 'standarduser@salesforce.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = fslAPIOnlyProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );

        fa.ACG_Status__c = 'Deferred';
        update fa;

        System.runAs(boUser) {
            try {
                fa.ACG_Status__c = 'Active';
                update fa;
            } catch (Exception e) {
                if (e.getMessage().contains(errMsg)) {
                    hasError = true;
                }
            }
        }

        System.assertEquals(true, hasError, 'Failed to prevent activation of deferred Facility Adjustment.');
    }

    @isTest
    static void deferThenActivateFATest1() {
        Boolean isDeferred = true;
        Boolean isActive = true;
        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c 
            FROM ACG_Facility_Adjustment__c 
            LIMIT 1
        ];

        fa.ACG_Status__c = 'Deferred';
        update fa;

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        for (Invoice__c invc : invcList) {
            if (invc.Status__c != 'Deferred') {
                isDeferred = false;
                break;
            }
        }

        System.assertEquals(true, invcList.size() > 0, 'Failed to create Invoices.');
        System.assertEquals(true, isDeferred, 'Failed to defer Invoices.');

        Statement__c oldStmt = [
            SELECT Id, Status__c
            FROM Statement__c
        ];
        oldStmt.Status__c = 'Reconciled';
        update oldStmt;

        ServiceTerritory servTerr = [
            SELECT Id
            FROM ServiceTerritory
        ];

        Statement__c newStmt = new Statement__c(
            Start_Date__c = Date.newInstance(2024, 3, 1),
            End_Date__c = Date.newInstance(2024, 3, 31),
            Service_Territory__c = servTerr.Id,
            Status__c = 'Unreconciled'
        );
        insert newStmt;

        fa.ACG_Status__c = 'Active';
        fa.ACG_End_Date__c = Date.newInstance(2024, 2, 29);
        fa.Reactivation_Date__c = Date.newInstance(2024, 2, 1);
        update fa;

        invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        isDeferred = false;
        isActive = false;

        for (Invoice__c invc : invcList) {
            if (invc.Status__c == 'Ready for Processing') {
                isActive = true;
            }
            if (invc.Status__c == 'Deferred') {
                isDeferred = true;
            }
        }

        System.assertEquals(2, invcList.size(), 'Failed to create the appropriate Invoices.');
        System.assertEquals(true, isActive, 'Failed to defer Invoice.');
        System.assertEquals(true, isDeferred, 'Failed to create Invoice.');
    }

    @isTest
    static void deferThenActivateFATest2() {
        Integer numActiveInvcs = 0;
        Boolean isDeferred = false;
        ACG_Facility_Adjustment__c fa = [
            SELECT Id, ACG_Status__c, ACG_No_of_Payments__c
            FROM ACG_Facility_Adjustment__c 
            LIMIT 1
        ];

        fa.ACG_Status__c = 'Deferred';
        fa.ACG_No_of_Payments__c = 3;
        update fa;

        Statement__c oldStmt = [
            SELECT Id, Status__c
            FROM Statement__c
        ];
        oldStmt.Status__c = 'Reconciled';
        update oldStmt;

        ServiceTerritory servTerr = [
            SELECT Id
            FROM ServiceTerritory
        ];

        insert new List<Statement__c>{
            new Statement__c(
                Start_Date__c = Date.newInstance(2024, 3, 1),
                End_Date__c = Date.newInstance(2024, 3, 31),
                Service_Territory__c = servTerr.Id,
                Status__c = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c = Date.newInstance(2024, 4, 1),
                End_Date__c = Date.newInstance(2024, 4, 30),
                Service_Territory__c = servTerr.Id,
                Status__c = 'Unreconciled'
            ),
            new Statement__c(
                Start_Date__c = Date.newInstance(2024, 5, 1),
                End_Date__c = Date.newInstance(2024, 5, 31),
                Service_Territory__c = servTerr.Id,
                Status__c = 'Unreconciled'
            )
        };

        fa.ACG_Status__c = 'Active';
        fa.ACG_End_Date__c = Date.newInstance(2024, 2, 29);
        fa.Reactivation_Date__c = Date.newInstance(2024, 2, 1);
        update fa;

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        for (Invoice__c invc : invcList) {
            if (invc.Status__c == 'Ready for Processing') {
                numActiveInvcs++;
            }
            if (invc.Status__c == 'Deferred') {
                isDeferred = true;
            }
        }

        System.assertEquals(4, invcList.size(), 'Failed to create the appropriate number of Invoices.');
        System.assertEquals(true, isDeferred, 'Failed to defer Invoice.');
    }

    @isTest
    static void deferThenActivateFATest3() {
        Integer numActiveInvcs = 0;
        Boolean isDeferred = false;
        ServiceTerritory fac = [SELECT Id FROM ServiceTerritory];
        Statement__c oldStmt = [
            SELECT Id, Status__c
            FROM Statement__c
        ];

        insert new List<Statement__c>{
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

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            ACG_Start_Date__c = Date.newInstance(2024, 2, 1),
            Service_Territory__c = fac.Id,
            ACG_Adjustment_Category__c = isNEOrg ? 'Bonus' : 'BASIC',
            ACG_Adjustment_Type__c = 'Debit',
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 3,
            ACG_Payment_Amount__c = 100            
        );
        insert fa;

        List<Statement__c> stmtList = [
            SELECT Id, Start_Date__c
            FROM Statement__c
            WHERE Service_Territory__c = :fac.Id
        ];
        Boolean hasDupeStmt = false;
        Set<Date> stmtDateSet = new Set<Date>();

        for (Statement__c stmt : stmtList) {
            Date stmtStartDate = stmt.Start_Date__c;

            if (!stmtDateSet.contains(stmtStartDate)) {
                stmtDateSet.add(stmtStartDate);
            } else {
                hasDupeStmt = true;
            }
        }

        System.assertEquals(false, hasDupeStmt, 'Created duplicate Statements.');

        fa.ACG_Status__c = 'Deferred';
        update fa;

        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        Boolean isActive = false;

        for (Invoice__c invc : invcList) {
            if (invc.Status__c != 'Deferred') {
                isActive = true;
                break;
            }
        }

        System.assertEquals(false, isActive, 'Failed to defer Invoices.');

        oldStmt.Status__c = 'Reconciled';
        update oldStmt;

        fa.ACG_Status__c = 'Active';
        fa.Reactivation_Date__c = Date.newInstance(2024, 3, 1);
        update fa;

        stmtList = [
            SELECT Id, Start_Date__c
            FROM Statement__c
            WHERE Service_Territory__c = :fac.Id
        ];
        hasDupeStmt = false;
        stmtDateSet = new Set<Date>();

        for (Statement__c stmt : stmtList) {
            Date stmtStartDate = stmt.Start_Date__c;

            if (!stmtDateSet.contains(stmtStartDate)) {
                stmtDateSet.add(stmtStartDate);
            } else {
                hasDupeStmt = true;
            }
        }

        System.assertEquals(false, hasDupeStmt, 'Created duplicate Statements.');

        invcList = [
            SELECT Id, Status__c, Statement__r.Start_Date__c
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
            AND Status__c = 'Ready for Processing'
        ];

        System.assertEquals(2, invcList.size(), 'Failed to activate Invoices.');
    }
}