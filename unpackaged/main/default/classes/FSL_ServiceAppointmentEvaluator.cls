/**
 * @File Name          : FSL_ServiceAppointmentEvaluator.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/26/2020, 6:05:01 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    1/20/2020   Rajesh Kemisetti     Initial Version
**/
public class FSL_ServiceAppointmentEvaluator{

    public static List<ServiceAppointment> getAppointmentsWithUpdatedValue(Map<id, ServiceAppointment> originalAppointmentMap, List<ServiceAppointment> updatedAppointments, String fieldAPIName){
        // get field details from schema get describe
        List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
        for(ServiceAppointment updatedSA : updatedAppointments){
			ServiceAppointment originalSA = originalAppointmentMap.get(updatedSA.id);
			
			if(updatedSA.Service_Resource__c != null && originalSA.Service_Resource__c != null && updatedSA.Service_Resource__c != originalSA.Service_Resource__c){
				matchingList.add(updatedSA);
			}
        }
        
        return matchingList;
    }    
    
    //   ***    Service Tech Team: Commented out methods below as their logic is moved to FSL_ServiceAppointmentTriggerHandler    ***

    /*
    public static List<ServiceAppointment> getAppointmentsWithNewServiceResource(Map<id, ServiceAppointment> originalAppointmentMap, List<ServiceAppointment> updatedAppointments){
        List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
        for(ServiceAppointment updatedSA : updatedAppointments){
			ServiceAppointment originalSA = originalAppointmentMap.get(updatedSA.id);
			
			if(updatedSA.Service_Resource__c != null && originalSA.Service_Resource__c != null && updatedSA.Service_Resource__c != originalSA.Service_Resource__c){
				matchingList.add(updatedSA);
			}
        }
        
        return matchingList;
    }
    */
    
    // public static List<ServiceAppointment> getAppointmentsWithNewStatus(Map<id, ServiceAppointment> originalAppointmentMap, List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		ServiceAppointment originalSA = originalAppointmentMap.get(updatedSA.id);
			
	// 		if(updatedSA.Status != originalSA.Status){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> getAppointmentsNowEnRoute(List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		// TODO: Replace hard coded value
	// 		if(updatedSA.Status == 'En Route'){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> getAppointmentsNowOnLocation(List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		// TODO: Replace hard coded value
	// 		if(updatedSA.Status == 'On Location'){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // } 
    
    // public static List<ServiceAppointment> getAppointmentsNowInTow(List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		// TODO: Replace hard coded value
	// 		if(updatedSA.Status == 'In Tow' || updatedSA.Status == 'Tow Loaded'){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> getAppointmentsThatCleared(List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		// TODO: Replace hard coded value
	// 		if(updatedSA.Status == 'Cleared'){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> appointmentsScheduledFromSpotted(Map<id, ServiceAppointment> originalAppointmentMap, List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		ServiceAppointment originalSA = originalAppointmentMap.get(updatedSA.id);
			
	// 		if(String.isBlank(String.valueOf(originalSA.SchedStartTime)) && updatedSA.SchedStartTime != originalSA.SchedStartTime){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> getMemberScheduledAppointments(List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		// TODO: Replace hard coded value
	// 		if(updatedSA.Member_Scheduled__c){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }
    
    // public static List<ServiceAppointment> appointmentsWithNewTerritory(Map<id, ServiceAppointment> originalAppointmentMap, List<ServiceAppointment> updatedAppointments){
    //     List<ServiceAppointment> matchingList = new List<ServiceAppointment>();
    //     for(ServiceAppointment updatedSA : updatedAppointments){
	// 		ServiceAppointment originalSA = originalAppointmentMap.get(updatedSA.id);
			
	// 		if(updatedSA.ServiceTerritoryId != originalSA.ServiceTerritoryId){
	// 			matchingList.add(updatedSA);
	// 		}
    //     }
        
    //     return matchingList;
    // }

    //   ***    End    ***

    
    public static List<FSL_ServiceAppointment.ServiceAppointment> getScheduledTowAppointments(List<ServiceAppointment> appointments, FSL_ServiceAppointment.IFactory serviceAppointmentFactory) {
        List<ServiceAppointment> towSAList = new List<ServiceAppointment>();
        Set<String> towStatusesToNotSyncSet = new Set<String>{ 'Spotted', 'Tow Complete', 'Canceled' };
        for (ServiceAppointment app : appointments) {
			if (!app.isBreakdown__c && app.Service_Resource__c != null && !towStatusesToNotSyncSet.contains(app.Status)) {
				towSAList.add(app);
			}
        }
        return serviceAppointmentFactory.createServiceAppointments(towSAList, new Map<Id, AssignedResource>());
    }
}