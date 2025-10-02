/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 08-02-2021
 * @last modified by  : Clement Shiu
**/
@isTest
public with sharing class FSL_ServiceAppointmentQueueableTest {
    public FSL_ServiceAppointmentQueueableTest() {

    }
    @isTest
    static void testDispatchAppointmentCalls_CoverageOnly(){
        Test.startTest();
        System.enqueueJob(new FSL_ServiceAppointmentQueueable.DispatchAppointmentCalls());
        Test.stopTest();
    }    
}