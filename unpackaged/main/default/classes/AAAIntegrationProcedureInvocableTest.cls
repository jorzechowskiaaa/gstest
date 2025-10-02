@isTest
class AAAIntegrationProcedureInvocableTest {
    @TestSetup
    static void setupData(){
        RecordType facTerritoryType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Facility_Territory' LIMIT 1];

        OperatingHours opHrs = new OperatingHours(
            TimeZone = 'America/New_York',
            Name = 'Apex Test Time Zone'
        );
        insert opHrs;

        ServiceTerritory svcTerritory = new ServiceTerritory(
            Name = 'Apex Test Service Territory',
            RecordTypeId = facTerritoryType.Id,
            OperatingHoursId = opHrs.Id,
            Enable_Calculate_Mileage__c = 'From Service Territory',
            isActive = true
        );
        insert svcTerritory;
        
        WorkOrder wo = new WorkOrder(
            Call_Id__c = 'Apex Test Work Order 22',
            Status = 'Cleared',
            Resolution_Code__c = 'G101',
            ServiceTerritoryId = svcTerritory.Id
        );
        insert wo;
    }

    @isTest
    static void runIntegrationServiceInvocableTest() {
        WorkOrder wo = [SELECT Id, Status, Resolution_Code__c, Clearing_Code__c FROM WorkOrder WHERE Call_Id__c = 'Apex Test Work Order 22' LIMIT 1];
        List<AAAIntegrationProcedureInvocable.IntegrationProcedureInput> ipInputList = new List<AAAIntegrationProcedureInvocable.IntegrationProcedureInput>();
        AAAIntegrationProcedureInvocable.IntegrationProcedureInput ipInput = new AAAIntegrationProcedureInvocable.IntegrationProcedureInput();
        Boolean calledIntegrationProcedure = false;

        ipInput.currentWorkOrderId = wo.Id;
        ipInput.procedureAPIName = 'backOffice_CreateNewServiceLineWithBA';
        ipInputList.add(ipInput);

        Test.startTest();
            try {
                AAAIntegrationProcedureInvocable.runIntegrationServiceInvocable(ipInputList);
                calledIntegrationProcedure = true;
            } catch (Exception e) {
                System.debug(e.getStackTraceString());
            }
        Test.stopTest();

        System.assertEquals(calledIntegrationProcedure, true, 'Unable to call integration procedure.');
    }
}