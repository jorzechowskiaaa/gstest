/**
 * Name : FSL_ResourceAbsenceScheduler
 * Description : Class for purging yesterday's resource absence records.
 */

global class FSL_ResourceAbsenceScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		List<ResourceAbsence> absences;
		Datetime dt = System.now();
		dt = dt.addDays(Integer.valueOf(System.Label.FSL_RESOURCE_ABSENCE_DAYS_PURGE));
		try {
			absences = [SELECT Id, AbsenceNumber FROM ResourceAbsence WHERE CreatedDate < :dt LIMIT 9999];
			delete absences;
		} catch (QueryException e) {
			System.debug(e.getStackTraceString());
		} catch (DmlException e){
			System.debug(e.getStackTraceString());
		}
	}
}