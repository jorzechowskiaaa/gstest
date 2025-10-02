/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 12-01-2022
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   07-21-2021   Clement Shiu   Initial Version
 * 2.0   08-30-2021   ERS-225103 Part#2 Automate Reroute Process on Decline Call in Field Service for Tow Call
**/
@isTest
public with sharing class FSL_ServiceAppointmentFlowTest {
    public FSL_ServiceAppointmentFlowTest() {

    }

    // // *********************************************
    // // * DAO
    // // *********************************************
    private static void createDaoData() {
        Integer recordCount = 5;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
        }
        insert workOrders;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        insert sts;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for( Integer i = 0; i < recordCount; ++i ) {
            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
            breakdownSa.ParentRecordId = workOrders[i].Id;
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
            serviceAppointments.add( breakdownSa );           
        }
        insert serviceAppointments;
    }   

    private static String getFakeId(Schema.SObjectType sot) {
        Integer s_num = Integer.valueOf(123456789*Math.random());
          String result = String.valueOf(s_num++);
          return sot.getDescribe().getKeyPrefix() + 
         '0'.repeat(12-result.length()) + result;
    } 

    private static FSL__Scheduling_Policy__c createPolicy(string policyName) {
        if(policyName == null)
            return null;

        FSL__Scheduling_Policy__c p = new FSL__Scheduling_Policy__c();     
        p.Name = policyName;        

        return p;
    }   
    public class RescheduleServiceMock implements FSL_ServiceScheduler.IScheduleService {
        public Boolean isException = false;
        public Boolean isSuccessful = true;

        public Boolean Schedule(FSL__Scheduling_Policy__c fsl_schedulingPolicy, ServiceAppointment scheduleAppointment) {
            if (isException) {
                throw new RescheduleException();
            }
            return isSuccessful;
        }
        public Boolean ScheduleExtended(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {
            if (isException) {
                throw new RescheduleException();
            }
            return isSuccessful;
        }
        public FSL_ServiceScheduler.TestConfig TestConfig()  {
           return new FSL_ServiceScheduler.TestConfig(true, 'testing');
        }
        public Datetime startTime() {
            return Datetime.Now();
        }
        public Datetime endTime() {
            return DateTime.Now();
        }


    }
    public class RescheduleException extends Exception {

    }

    @IsTest
    static void test_Rescheduler_doSchedule_Successful() {
        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        FSL_ServiceScheduler.IScheduleService mockService = new RescheduleServiceMock();
        List<Id> serviceAppointmentIds = new List<Id>();
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));

        FSL_ServiceAppointmentFlow.Rescheduler rescheduler = new FSL_ServiceAppointmentFlow.Rescheduler(mockService, schedPolicy, serviceAppointmentIds);
        
        Test.startTest();
        Boolean result = rescheduler.doSchedule();
        System.assertEquals(true, result);
        Test.stopTest();       
    }

    @IsTest
    static void test_Rescheduler_doSchedule_Fail() {
        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        RescheduleServiceMock mockService = new RescheduleServiceMock();
        List<Id> serviceAppointmentIds = new List<Id>();
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));

        FSL_ServiceAppointmentFlow.Rescheduler rescheduler = new FSL_ServiceAppointmentFlow.Rescheduler(mockService, schedPolicy, serviceAppointmentIds);
        
        Test.startTest();
        mockService.isSuccessful = false;
        Boolean result = rescheduler.doSchedule();
        System.assertEquals(false, result);
        Test.stopTest();        
    }

    @IsTest
    static void test_ServiceAppointmentFlowService_doSchedule() {
        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        RescheduleServiceMock mockService = new RescheduleServiceMock();
        List<Id> serviceAppointmentIds = new List<Id>();
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));

        FSL_ServiceAppointmentFlow.Rescheduler rescheduler = new FSL_ServiceAppointmentFlow.Rescheduler(mockService, schedPolicy, serviceAppointmentIds);
        FSL_ServiceAppointmentFlow.ServiceAppointmentFlowService saFlowService = new  FSL_ServiceAppointmentFlow.ServiceAppointmentFlowService();

        Test.startTest();
        List<Boolean> result = saFlowService.doReschedule(rescheduler);
        System.assertEquals(true, result[0]);
        Test.stopTest();
     
    }

    @IsTest
    static void test_ServiceAppointmentFlowService_doSchedule_Tow_Call() {
        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        RescheduleServiceMock mockService = new RescheduleServiceMock();
        List<Id> serviceAppointmentIds = new List<Id>();
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));

        FSL_ServiceAppointmentFlow.Rescheduler rescheduler = new FSL_ServiceAppointmentFlow.Rescheduler(mockService, schedPolicy, serviceAppointmentIds);
        FSL_ServiceAppointmentFlow.ServiceAppointmentFlowService saFlowService = new  FSL_ServiceAppointmentFlow.ServiceAppointmentFlowService();

        Test.startTest();
        List<Boolean> result = saFlowService.doReschedule(rescheduler);
        System.assertEquals(true, result[0]);
        Test.stopTest();        
    }


    @IsTest
    static void testCodeCoverage_reScheduleServiceApptToSecondarySeviceTerritory() {
        // Just for code coverage
        createDaoData();      

        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment];
        List<Id> serviceApptIDs = new List<Id>();
        ServiceApptIDs.add(serviceAppointments[0].Id);   

        List<List<Id>> arrayServiceAppointments = new List<List<Id>>();
        arrayServiceAppointments.add(serviceApptIDs);     
        
        List<Boolean> returnVals = FSL_ServiceAppointmentFlow.reScheduleServiceApptToSecondarySeviceTerritory(arrayServiceAppointments);        
        System.debug('returnVals = ' + returnVals);
    }

    @IsTest
    static void test_reScheduleServiceApptToSecondaryServiceTerritory_Mock() {

        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        RescheduleServiceMock mockService = new RescheduleServiceMock();
        List<Id> serviceAppointmentIds = new List<Id>();
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));
        serviceAppointmentIds.add(getFakeId(ServiceAppointment.SObjectType));
        FSL_ServiceAppointmentFLow.ServiceAppointmentFlowService rescheduleService  = new FSL_ServiceAppointmentFLow.ServiceAppointmentFlowService(mockService);
        Test.startTest();
        List<Boolean> result = rescheduleService.reScheduleServiceApptToSecondarySeviceTerritory(serviceAppointmentIds);
        Test.stopTest();     
    }

    @IsTest
    static void testCodeCoverage_reScheduleServiceApptToSecondarySeviceTerritory_Tow() {
        // Just for code coverage
        createDaoData();      

        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;
        

        List<ServiceAppointment> serviceAppointments = [SELECT Id, ParentRecordId,ContactId,ServiceTerritoryId, SchedEndTime FROM ServiceAppointment];
        ServiceAppointment towAppointment = FSL_DataFactory.createAppointmentShell(serviceAppointments[0],20);
        insert towAppointment;

        List<Id> serviceApptIDs = new List<Id>();
        ServiceApptIDs.add(serviceAppointments[0].Id);  
        serviceApptIDs.add(towAppointment.Id);

        List<List<Id>> arrayServiceAppointments = new List<List<Id>>();
        arrayServiceAppointments.add(serviceApptIDs);     
        
        List<Boolean> returnVals = FSL_ServiceAppointmentFlow.reScheduleServiceApptToSecondarySeviceTerritory(arrayServiceAppointments);        
        System.debug('returnVals = ' + returnVals);
    }

    @IsTest
    static void testCoverage() { 
        
        Test.startTest();
        FSL_ServiceAppointmentFlow.RescheduleService service = new FSL_ServiceAppointmentFlow.RescheduleService(new FSL_ServiceScheduler.TestConfig(true,'Testing Mocking'));
        FSL_ServiceScheduler.TestConfig config = service.TestConfig();
        Datetime startTime = service.startTime();
        Datetime endTime = service.endTime();
        System.assertEquals(true, config.isMocking);
        System.assertEquals(true, startTime != null);
        System.assertEquals(true, endTime != null);
        Test.stopTest();
        
    }

    @IsTest
    static void test_rescheduleServiceApptToSecondaryTerritory_Exception() {
        
        List<List<Id>> arrayServiceAppointments = new List<List<Id>>();

        Test.startTest();
        List<Boolean> returnVals = FSL_ServiceAppointmentFlow.reScheduleServiceApptToSecondarySeviceTerritory(arrayServiceAppointments);  
        System.assertEquals(false, returnVals[0]);
        Test.stopTest();
        
    }
}