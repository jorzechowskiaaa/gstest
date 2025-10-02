/**
 * Name : FSL_SAResourceLocator
 * Description : Class for locating service absent resources every 15 minutes (the timer is configured in FSL_Resource_Locator_Timer custom label).
 */

 global with sharing class FSL_SAResourceLocator implements Schedulable {
	global void execute(SchedulableContext sc) {
		List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
		List<AssignedResource> allAssignedResources = new List<AssignedResource>();
		List<ServiceResource> serviceResources = new List<ServiceResource>();
		
		try {
		    serviceAppointments = [SELECT Id, (SELECT Id FROM ServiceResources) FROM ServiceAppointment 
		    						WHERE SchedStartTime >: System.now() AND SchedEndTime >: System.now()];
		    for (ServiceAppointment sa : serviceAppointments) {
		        allAssignedResources.addAll(sa.ServiceResources);
		    }
		    serviceResources = [SELECT Id, LocationId, (SELECT Id FROM ServiceAppointments WHERE Id IN: allAssignedResources) FROM ServiceResource];
		    for (ServiceResource sr : serviceResources) {
		        //calculate the prior location
		        sr.CreatedDate.addHours(1);
		    }
		}
		catch (Exception e) {
		    //FSL_ApplicationLogCreator
		}
	}
}