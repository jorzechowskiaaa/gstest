@isTest
class AAAPaymentFlowHelperTest {
    @isTest
    static void paymentCreationBatchTest() {
        List<AAAPaymentFlowHelper.FlowOutput> outputList = AAAPaymentFlowHelper.runPaymentFlowHelper(new List<AAAPaymentFlowHelper.FlowInput>{createInputData()});
        AAAPaymentFlowHelper.FlowOutput output = outputList[0];
        Statement__c stmt = output.stmt;
        List<String> invcIdList = output.invcList;
        List<Payment__c> pmtList = output.pmtList;
        List<Invoice__c> invcList = [
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Id IN :invcIdList
        ];

        System.assertEquals(stmt.Processed__c, true, 'Statement was not processed.');

        System.assertEquals(invcIdList.size(), invcList.size(), 'Invoice status was not updated.');

        System.assertEquals(pmtList.size(), 11, 'The appropriate amount of Payment records was not created.');

        for(Integer i = 1; i < 12; i++) {
            Payment__c pmt = pmtList[i - 1];

            if(pmt.Item_Description__c == 'Hardware') {
                System.assertEquals(pmt.Amount__c, 30.0, 'Amount on Payment record not updated correctly.');
            }

            System.assertEquals(pmt.Line_Row__c, i, 'Line rows were not correctly updated.');
        }
    }

    private static AAAPaymentFlowHelper.FlowInput createInputData() {
        AAAPaymentFlowHelper.FlowInput input = new AAAPaymentFlowHelper.FlowInput();
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' AND SobjectType = 'ServiceTerritory' LIMIT 1];
        RecordType facAdjType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Adjustment' AND SobjectType = 'Invoice__c' LIMIT 1];
        
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
            Non_Payment_Facility__c = false,
            Street = '415 Mission St.',
            City = 'San Francisco',
            State = 'CA',
            PostalCode = '94105',
            Country = 'United States'
        );
        insert svcTerritory;
        
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId,1,false,false)[0];
        insert objFacility1 ;

        ACG_Facility_Adjustment__c facAdj = new ACG_Facility_Adjustment__c(
            Facility_Adjustment_Name__c = 'Apex Test Facility Adjustment',
            Service_Territory__c = svcTerritory.Id,
            Account__c = objFacility1.Id
        );
        insert facAdj;

        ACG_Facility_Adjustment_Payment__c facAdjPmt = new ACG_Facility_Adjustment_Payment__c(
            ACG_Adjustment_ID__c = facAdj.Id,
            ACG_Payment_Amount__c = 0.0
        );
        insert facAdjPmt;

        Statement__c stmt = new Statement__c(
            Service_Territory__c = svcTerritory.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Statement_Name__c = 'Apex Test Statement 1',
            Status__c = 'Reconciled',
            Processed__c = false
        );
        insert stmt;

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

        Set<String> invcIdSet = new Set<String>();
        for (Invoice__c invc : invcList) {
            invcIdSet.add(invc.Id);
        }

        input.stmt = [
            SELECT 
                Id,
                End_Date__c,
                Name,
                Payment_Date__c,
                Processed__c,
                Basic_Cost__c,
                Basic_Cost_Tax_ERS__c,
                Basic_Cost_Adjustment__c,
                Basic_Cost_Tax_Adjustment__c,
                Basic_Cost_Reciprocal__c,
                Basic_Cost_Tax_Reciprocal__c,
                Basic_Cost_Reciprocal_Adjustment__c,
                Basic_Cost_Tax_Reciprocal_Adjustment__c,
                Other_Cost_Adjustment__c,
                Other_Cost_Tax_Adjustment__c,
                Other_Cost_ERS__c,
                Other_Cost_Tax_ERS__c,
                Other_Cost_Reciprocal__c,
                Other_Cost_Tax_Reciprocal__c,
                Other_Cost_Reciprocal_Adjustment__c,
                Other_Cost_Tax_Reciprocal_Adjustment__c,
                Plus_Cost__c,
                Plus_Cost_Tax_ERS__c,
                Plus_Cost_Adjustment__c,
                Plus_Cost_Tax_Adjustment__c,
                Plus_Cost_Reciprocal__c,
                Plus_Cost_Tax_Reciprocal__c,
                Plus_Cost_Reciprocal_Adjustment__c,
                Plus_Cost_Tax_Reciprocal_Adjustment__c,
                Premier_Cost__c,
                Premier_Cost_Tax_ERS__c,
                Premier_Cost_Adjustment__c,
                Premier_Cost_Tax_Adjustment__c,
                Premier_Cost_Reciprocal__c,
                Premier_Cost_Tax_Reciprocal__c,
                Premier_Cost_Reciprocal_Adjustment__c,
                Premier_Cost_Tax_Reciprocal_Adjustment__c,
                RV_Cost__c,
                RV_Cost_Tax_ERS__c,
                RV_Cost_Adjustment__c,
                RV_Cost_Tax_Adjustment__c,
                RV_Cost_Reciprocal__c,
                RV_Cost_Tax_Reciprocal__c,
                RV_Cost_Reciprocal_Adjustment__c,
                RV_Cost_Tax_Reciprocal_Adjustment__c,
                Club_Station_Contractor_Battery__c,
                Club_Station_Contractor_Basic__c,
                Club_Station_Contractor_Plus__c,
                Club_Station_Contractor_PLRV__c,
                Club_Station_Contractor_PRM__c,
                Club_Station_Programs_Basic__c,
                Club_Station_Programs_Plus__c,
                Club_Station_Programs_prem__c,
                Club_Station_RAP__c,
                Club_Station_Reciprocal__c,
                Status__c
            FROM Statement__c
            WHERE Id = :stmt.Id
            LIMIT 1
        ];
        input.fac = [
            SELECT
                Id,
                Facility_Number__c,
                Name,
                Street,
                City,
                State,
                PostalCode,
                DBA_Name__c,
                DBA_Address_Line_1__c,
                DBA_City__c,
                DBA_State__c,
                DBA_Zip_Code__c
            FROM ServiceTerritory
            WHERE Id = :svcTerritory.Id
            LIMIT 1
        ];
        input.invcList = [
            SELECT
                Id,
                Type__c,
                Status__c,
                Total_Amount__c,
                Facility_Adjustment_Category__c,
                Facility_Adjustment_Type__c
            FROM Invoice__c
            WHERE Id IN :invcIdSet
        ];
        input.boSettings = new BackOffice_Settings__c(
            Club_Code__c = '240'
        );
        input.scMdtList = new List<Spend_Category__mdt>{
            new Spend_Category__mdt(
                Label = 'AAA Loans and Advances',
                Spend_Category__c = 'RC0301'
            ),
            new Spend_Category__mdt(
                Label = 'BKGRND',
                Spend_Category__c = 'SC9060'
            ),
            new Spend_Category__mdt(
                Label = 'Basic',
                Spend_Category__c = 'SC5500'
            ),
            new Spend_Category__mdt(
                Label = 'Basic Reciprocal',
                Spend_Category__c = 'SC5500'
            ),
            new Spend_Category__mdt(
                Label = 'Battery Warranty Reserve-Club Assist',
                Spend_Category__c = 'SC0780'
            ),
            new Spend_Category__mdt(
                Label = 'Battery Warranty Reserve-Interstate',
                Spend_Category__c = 'SC0785'
            ),
            new Spend_Category__mdt(
                Label = 'Battery and Battery Charger Costs',
                Spend_Category__c = 'SC1100'
            ),
            new Spend_Category__mdt(
                Label = 'Bonus',
                Spend_Category__c = 'SC5520'
            ),
            new Spend_Category__mdt(
                Label = 'Damage',
                Spend_Category__c = 'SC5600'
            ),
            new Spend_Category__mdt(
                Label = 'Fuel Subsidy',
                Spend_Category__c = 'SC5640'
            ),
            new Spend_Category__mdt(
                Label = 'Hardware',
                Spend_Category__c = 'SC7640'
            ),
            new Spend_Category__mdt(
                Label = 'Intersate Battery',
                Spend_Category__c = 'SC0320'
            ),
            new Spend_Category__mdt(
                Label = 'Interstate Battery',
                Spend_Category__c = 'SC0320'
            ),
            new Spend_Category__mdt(
                Label = 'NSF',
                Spend_Category__c = 'SC5620'
            ),
            new Spend_Category__mdt(
                Label = 'Other',
                Spend_Category__c = 'SC5500'
            ),
            new Spend_Category__mdt(
                Label = 'Other Reciprocal',
                Spend_Category__c = 'SC5500'
            ),
            new Spend_Category__mdt(
                Label = 'Plus',
                Spend_Category__c = 'SC5680'
            ),
            new Spend_Category__mdt(
                Label = 'Plus Reciprocal',
                Spend_Category__c = 'SC5680'
            ),
            new Spend_Category__mdt(
                Label = 'Premier',
                Spend_Category__c = 'SC5760'
            ),
            new Spend_Category__mdt(
                Label = 'Premier Reciprocal',
                Spend_Category__c = 'SC5760'
            ),
            new Spend_Category__mdt(
                Label = 'RV',
                Spend_Category__c = 'SC5680'
            ),
            new Spend_Category__mdt(
                Label = 'RV Reciprocal',
                Spend_Category__c = 'SC5680'
            ),
            new Spend_Category__mdt(
                Label = 'Tablets',
                Spend_Category__c = 'SC7710'
            ),
            new Spend_Category__mdt(
                Label = '3rd Party (Outside of AAA)',
                Spend_Category__c = 'RC0300'
            ),
            new Spend_Category__mdt(
                Label = '3rd Party (Outside of AAA)',
                Spend_Category__c = 'RC0300'
            )
        };
        input.fieldSCMdtList = new List<Statement_Field_Spend_Category_Mappings__mdt>{
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost__c',
                Label__c = 'Basic_Cost__c',
                Spend_Category_Label__c = 'Basic'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Adjustment__c',
                Label__c = 'Basic_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Basic'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Reciprocal__c',
                Label__c = 'Basic_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Basic Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Basic_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Basic Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Tax_Adjustment__c',
                Label__c = 'Basic_Cost_Tax_Adjustment__c',
                Spend_Category_Label__c = 'Basic'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Tax_ERS__c',
                Label__c = 'Basic_Cost_Tax_ERS__c',
                Spend_Category_Label__c = 'Basic'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Tax_Reciprocal__c',
                Label__c = 'Basic_Cost_Tax_Reciprocal__c',
                Spend_Category_Label__c = 'Basic Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Basic_Cost_Tax_Reciprocal_Adjustment__c',
                Label__c = 'Basic_Cost_Tax_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Basic Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Adjustment__c',
                Label__c = 'Other_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Other'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_ERS__c',
                Label__c = 'Other_Cost_ERS__c',
                Spend_Category_Label__c = 'Other'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Reciprocal__c',
                Label__c = 'Other_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Other Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Other_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Other Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Tax_Adjustment__c',
                Label__c = 'Other_Cost_Tax_Adjustment__c',
                Spend_Category_Label__c = 'Other'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Tax_ERS__c',
                Label__c = 'Other_Cost_Tax_ERS__c',
                Spend_Category_Label__c = 'Other'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Tax_Reciprocal_Adjustment__c',
                Label__c = 'Other_Cost_Tax_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Other Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Other_Cost_Tax_Reciprocal__c',
                Label__c = 'Other_Cost_Tax_Reciprocal__c',
                Spend_Category_Label__c = 'Other Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost__c',
                Label__c = 'Plus_Cost__c',
                Spend_Category_Label__c = 'Plus'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Adjustment__c',
                Label__c = 'Plus_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Plus'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Reciprocal__c',
                Label__c = 'Plus_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Plus Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Plus_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Plus Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Tax_Adjustment__c',
                Label__c = 'Plus_Cost_Tax_Adjustment__c',
                Spend_Category_Label__c = 'Plus'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Tax_ERS__c',
                Label__c = 'Plus_Cost_Tax_ERS__c',
                Spend_Category_Label__c = 'Plus'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Tax_Reciprocal_Adjustment__c',
                Label__c = 'Plus_Cost_Tax_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Plus Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Plus_Cost_Tax_Reciprocal__c',
                Label__c = 'Plus_Cost_Tax_Reciprocal__c',
                Spend_Category_Label__c = 'Plus Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost__c',
                Label__c = 'Premier_Cost__c',
                Spend_Category_Label__c = 'Premier'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Adjustment__c',
                Label__c = 'Premier_Cost_Adjustment__c',
                Spend_Category_Label__c = 'Premier'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Reciprocal__c',
                Label__c = 'Premier_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'Premier Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Reciprocal_Adjustment__c',
                Label__c = 'Premier_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Premier Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Tax_Adjustment__c',
                Label__c = 'Premier_Cost_Tax_Adjustment__c',
                Spend_Category_Label__c = 'Premier'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Tax_ERS__c',
                Label__c = 'Premier_Cost_Tax_ERS__c',
                Spend_Category_Label__c = 'Premier'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Tax_Reciprocal_Adjustment__',
                Label__c = 'Premier_Cost_Tax_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'Premier Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'Premier_Cost_Tax_Reciprocal__c',
                Label__c = 'Premier_Cost_Tax_Reciprocal__c',
                Spend_Category_Label__c = 'Premier Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost__c',
                Label__c = 'RV_Cost__c',
                Spend_Category_Label__c = 'RV'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Adjustment__c',
                Label__c = 'RV_Cost_Adjustment__c',
                Spend_Category_Label__c = 'RV'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Reciprocal__c',
                Label__c = 'RV_Cost_Reciprocal__c',
                Spend_Category_Label__c = 'RV Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Reciprocal_Adjustment__c',
                Label__c = 'RV_Cost_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'RV Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Tax_Adjustment__c',
                Label__c = 'RV_Cost_Tax_Adjustment__c',
                Spend_Category_Label__c = 'RV'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Tax_ERS__c',
                Label__c = 'RV_Cost_Tax_ERS__c',
                Spend_Category_Label__c = 'RV'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Tax_Reciprocal_Adjustment__c',
                Label__c = 'RV_Cost_Tax_Reciprocal_Adjustment__c',
                Spend_Category_Label__c = 'RV Reciprocal'
            ),
            new Statement_Field_Spend_Category_Mappings__mdt(
                Label = 'RV_Cost_Tax_Reciprocal__c',
                Label__c = 'RV_Cost_Tax_Reciprocal__c',
                Spend_Category_Label__c = 'RV Reciprocal'
            )
        };

        return input;
    }
}