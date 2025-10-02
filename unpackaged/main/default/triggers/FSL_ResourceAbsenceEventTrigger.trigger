/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 */

trigger FSL_ResourceAbsenceEventTrigger on Resource_Absence_Event__e (after insert) {
   if(!FSL_TriggerUtility.isDisabled('Resource_Absence_Event__e')){
      FSL_ResourceAbsenceEvent.IResourceAbsenceEventService resourceAbsenceEventService = (new FSL_ResourceAbsenceEvent.Factory()).createService();
      FSL_ResourceAbsence.IResourceAbsenceService resourceAbsenceService = (new FSL_ResourceAbsence.Factory()).createService();
      resourceAbsenceEventService.processEventMessages(Trigger.new,resourceAbsenceService); 
   }
}