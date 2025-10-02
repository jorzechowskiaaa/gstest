@isTest
class AAAStatementCreationBatchTest {
    @TestSetup
    static void createTestData() {
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType facAcctType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility' AND SobjectType = 'Account' LIMIT 1];
        List<ACG_Facility_Adjustment__c> facAdjList = new List<ACG_Facility_Adjustment__c>();
        Date dateToday = Date.today();
        Integer year = dateToday.year();
        Integer month = dateToday.month();
        Integer day = dateToday.day();
        
        Date monthlyStartDate = Date.newInstance(year, month, 1);
        Date biMonthlyStartDate = day > 16 ? Date.newInstance(year, month, 16) : monthlyStartDate;

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        List<ServiceTerritory> svcTerritoryList = new List<ServiceTerritory>{
            new ServiceTerritory(
                Name = 'Apex Test Service Territory 1',
                RecordTypeId = facTerritoryType.Id,
                OperatingHoursId = opHrs.Id,
                isActive = true,
                Payment_Schedule__c = 'Bi-monthly'
            ),
            new ServiceTerritory(
                Name = 'Apex Test Service Territory 2',
                RecordTypeId = facTerritoryType.Id,
                OperatingHoursId = opHrs.Id,
                isActive = true,
                Payment_Schedule__c = 'Monthly'
            ),
            new ServiceTerritory(
                Name = 'Apex Test Service Territory 3',
                RecordTypeId = facTerritoryType.Id,
                OperatingHoursId = opHrs.Id,
                isActive = true,
                Payment_Schedule__c = 'Bi-monthly'
            ),
            new ServiceTerritory(
                Name = 'Apex Test Service Territory 4',
                RecordTypeId = facTerritoryType.Id,
                OperatingHoursId = opHrs.Id,
                isActive = true,
                Payment_Schedule__c = 'Monthly'
            )
        };
        insert svcTerritoryList;

        Account acct = new Account(
            Name = 'Apex Test Facility Account',
            Phone = '1234567890',
            RecordTypeId = facAcctType.Id
        );
        insert acct;

        for(Integer i = 0; i < 4; i++) {
            ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
                Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment ' + i + '-a',
                Service_Territory__c = svcTerritoryList[0].Id,
                ACG_Status__c = 'Active',
                ACG_No_of_Payments__c = 1,
                Account__c = acct.Id,
                ACG_Start_Date__c = biMonthlyStartDate,
                ACG_Payment_Amount__c = 100
            );
            facAdjList.add(facAdj);
        }

        for(Integer i = 0; i < 4; i++) {
            ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
                Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment ' + i + '-b',
                Service_Territory__c = svcTerritoryList[1].Id,
                ACG_Status__c = 'Active',
                ACG_No_of_Payments__c = 1, 
                Account__c = acct.Id,
                ACG_Start_Date__c = monthlyStartDate,
                ACG_Payment_Amount__c = 100
            );
            facAdjList.add(facAdj);
        }
        insert facAdjList;
    }

    @isTest
    static void createStatementBatchTest() {
        Test.startTest();
        Database.executeBatch(new AAAStatementCreationBatch(), 200);
        Test.stopTest();

        List<Statement__c> stmtList = [SELECT Id, Service_Territory__c, Start_Date__c, End_Date__c, Statement_Name__c, Status__c, Group__c FROM Statement__c WHERE Service_Territory__c IN (SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Apex Test Service Territory%') order by Statement_Name__c];
        Date startDate = Date.Today();
        Integer currentMonth = startDate.Month();
        Integer currentYear = startDate.Year();
        Date endDate;
        Date monthlyEndDate;
        Date nextMonthStartDate;

        if(startDate.day() <= 15){
           endDate = Date.newInstance(currentYear, currentMonth, 15); 
        } else {
            if(currentMonth == 12){
                endDate = Date.newInstance(currentYear, 12, 31);
            } else {
                nextMonthStartDate = Date.newInstance(currentYear, currentMonth + 1, 1);
                endDate = nextMonthStartDate.addDays(-1);
            }
        }

        if(currentMonth == 12){
            monthlyEndDate = Date.newInstance(currentYear, 12, 31);
        } else {
            nextMonthStartDate = Date.newInstance(currentYear, currentMonth + 1, 1);
            monthlyEndDate = nextMonthStartDate.addDays(-1);
        }

        System.assertEquals(4, stmtList.size(), 'Expected 4 Statements to be created.');
    }

    @isTest
    static void lateReconcileTest() {
        ServiceTerritory fac = [
            SELECT Id 
            FROM ServiceTerritory 
            WHERE Name = 'Apex Test Service Territory 4'
        ];
        Date today = Date.today();

        ACG_Facility_Adjustment__c fa = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Late FA',
            Service_Territory__c = fac.Id,
            ACG_Status__c = 'Active',
            ACG_No_of_Payments__c = 1,
            ACG_Start_Date__c = Date.newInstance(today.year(), today.month() - 1, 1),
            ACG_Payment_Amount__c = 100
        );
        insert fa;

        Test.startTest();
        Database.executeBatch(new AAAStatementCreationBatch(), 200);
        Test.stopTest();

        List<Invoice__c> invcList = [
            SELECT Id
            FROM Invoice__c
            WHERE Facility_Adjustment__c = :fa.Id
        ];

        System.assertEquals(1, invcList.size(), 'Expected 1 Invoice to be created.');
    }
}