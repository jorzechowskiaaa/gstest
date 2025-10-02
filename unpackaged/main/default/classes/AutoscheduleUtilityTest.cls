@isTest
public with sharing class AutoscheduleUtilityTest {
    @isTest
    private static void autoschedule_success() {
        WorkType testWorkType = new WorkType(Name = 'Test Work Type', EstimatedDuration = 10);
        insert testWorkType;
        OperatingHours testOperatingHours = new OperatingHours(Name = 'Test Operating Hours');
        insert testOperatingHours;
        ServiceTerritory testTerritory = new ServiceTerritory(Name = 'Test Service Territory', OperatingHoursId = testOperatingHours.Id, IsActive = true);
        insert testTerritory;
        WorkOrder testWo = new WorkOrder(ServiceTerritoryId = testTerritory.Id, WorkTypeId = testWorkType.Id);
        insert testWo;
        // ServiceAppointment testRelatedSa = new ServiceAppointment(ParentRecordId = testWo.Id);
        // insert testRelatedSa;
        ServiceAppointment testSa = new ServiceAppointment(ParentRecordId = testWo.Id, Work_Order__c = testWo.Id, Subject = 'Tow Appointment');
        insert testSa;

        Test.startTest();
        AutoscheduleUtility.autoschedule(testSa.Id, true);  //AGB added for SSFI-560 11/19/24
        Test.stopTest();
    }
    
    @isTest //AGB added for SSFI-560 11/19/24
    private static void autoschedule_success2() {
        WorkType testWorkType = new WorkType(Name = 'Test Work Type', EstimatedDuration = 10);
        insert testWorkType;
        OperatingHours testOperatingHours = new OperatingHours(Name = 'Test Operating Hours');
        insert testOperatingHours;
        ServiceTerritory testTerritory = new ServiceTerritory(Name = 'Test Service Territory', OperatingHoursId = testOperatingHours.Id, IsActive = true);
        insert testTerritory;
        WorkOrder testWo = new WorkOrder(ServiceTerritoryId = testTerritory.Id, WorkTypeId = testWorkType.Id);
        insert testWo;
        // ServiceAppointment testRelatedSa = new ServiceAppointment(ParentRecordId = testWo.Id);
        // insert testRelatedSa;
        ServiceAppointment testSa = new ServiceAppointment(ParentRecordId = testWo.Id, Work_Order__c = testWo.Id, Subject = 'Tow Appointment');
        insert testSa;

        Test.startTest();
        List<String> serviceAppointmentIds = new List<string>();
        serviceAppointmentIds.add(testSa.Id);
        AutoscheduleUtility.invokeAutoschedule(serviceAppointmentIds);
        Test.stopTest();
    }        
}