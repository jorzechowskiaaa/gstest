/**
 * @File Name          : FSL_ServiceAppointmentTrigger.trigger
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06-16-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    1/20/2020   Rajesh Kemisetti     Initial Version
 *        7/23/2020   Clement Shiu         Added updateGanttIconsOnSA()
 *        11/19/2020  Dylan Truong         ERS-220004 - 3rd Scheduling Policy
 *        12/03/2020  Clement Shiu         ERS-220518 - Introduce RAP GAP changes into ACE Org
 *        01/08/2020  Clement Shiu         ERS-220594 - Unpinned Appointment Calls 
**/
trigger FSL_ServiceAppointmentTrigger on ServiceAppointment (before insert, after insert, before update, after update) {
    // Check if any ServiceAppointment records have Cancel_From_Flow__c enabled
    Boolean runTrigger = true;
    for (ServiceAppointment sa : Trigger.new) {
        if (sa.Cancel_From_Flow__c) {
            runTrigger = false;
            break;
        }
    }
    
    // Run the handler only if Cancel_From_Flow__c is not enabled for any records
    if (runTrigger) {
        FSL_TriggerDispatcher.run(new FSL_ServiceAppointmentTriggerHandler());
    }
}