@isTest
public with sharing class AutoscheduleBatchTest {
    @isTest
    private static void autoscheduleBatchTest_success() {

        WorkType testWorkType = new WorkType(Name = 'Test Work Type', EstimatedDuration = 10);
        insert testWorkType;
        OperatingHours testOperatingHours = new OperatingHours(Name = 'Test Operating Hours');
        insert testOperatingHours;
        ServiceTerritory testTerritory = new ServiceTerritory(Name = 'Test Service Territory', OperatingHoursId = testOperatingHours.Id, Apply_Autoschedule_Retry_Batch__c = true, IsActive = true);
        insert testTerritory;
        WorkOrder testWo = new WorkOrder(Is_Tow_WorkType__c = true, ServiceTerritoryId = testTerritory.Id, WorkTypeId = testWorkType.Id);
        insert testWo;
        // ServiceAppointment testRelatedSa = new ServiceAppointment(ParentRecordId = testWo.Id);
        // insert testRelatedSa;
        ServiceAppointment testSa = new ServiceAppointment(Status = 'Spotted', ParentRecordId = testWo.Id, Work_Order__c = testWo.Id, Subject = 'Breakdown Appointment', ServiceTerritoryId = testTerritory.Id);
        insert testSa;

        Test.startTest();
        Database.executeBatch(new AutoscheduleBatch());
        Test.stopTest();
    }
}