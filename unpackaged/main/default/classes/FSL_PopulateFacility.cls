public without sharing class FSL_PopulateFacility{

    //   ***    Service Tech Team: Commented out the whole class body as its logic is moved to FSL_AssignedResourceTriggerHandler    ***

    /**********
    * @Method Name: populateFacility
    * @Parameters:(Map<Id, AssignedResource>)
    * @Return Value: void
    * @Description: Updates the Service Appointment & WorkOrder's Facility field with the Assigned Resource's Primary ServiceTerritory via STM
    * @Author: Matthew Pantell
    * **********/ 
    
        // public static void populateFacility(Map<Id, AssignedResource> resources, String operation, List<WorkOrder> updatedWOs, List<ServiceAppointment> updatedSAs){
        //     // List<ServiceAppointment> apptUpdates = new List<ServiceAppointment>();
        //     // List<ServiceAppointment> finalUpdateList = new List<ServiceAppointment>();
        //     // List<WorkOrder> finalUpdate = new List<WorkOrder>();
            
            
        //     List<Id> srIds = new List<Id>();
        //     // Map<ID, Id> appointmentToTerritoryMap = new Map<ID, Id>();
        //     Map<Id, ServiceTerritoryMember> serviceTerritoryMemberMap = new Map<Id, ServiceTerritoryMember>();
        //     Map<id, ServiceAppointment> updatedSAMap = new Map<Id, ServiceAppointment>(updatedSAs);
        //     //  Map<ID, ID> appointmentToAssignedUserMap = new Map<ID, ID>();
        //     Map<Id, Id> woIdToServiceTerritoryIds = new Map<Id, Id>();
        //     Map<Id, Id> woIdToTruckIds = new Map<Id, Id>();
            
        //     // List<AssignedResource> assignees =
        //     //     [SELECT ServiceResourceId, ServiceAppointment.ServiceTerritoryID,ServiceAppointment.AppointmentNumber, ServiceResource.RelatedRecordId,
        //     //             ServiceAppointment.Facility__c,ServiceAppointment.ParentRecordId, ServiceResource.Primary_Service_Territory__r.Id, ServiceResource.LocationId__c
        //     //     FROM AssignedResource WHERE Id in :resources.keySet()];
    
    
        //     for (AssignedResource resource : resources.values()){
        //         srIds.add(resource.ServiceResourceId);
        //     }
            
        //     List<ServiceTerritoryMember> stms = [
        //         SELECT MemberNumber, ServiceTerritoryId, ServiceResourceId, ServiceTerritory.Name, ServiceResource.RelatedRecordId, ServiceResource.Primary_Service_Territory__r.Id, ServiceResource.LocationId__c
        //         // (SELECT ServiceAppointment.ParentRecordId, 
        //         // FROM AssignedResource WHERE Id in :resources.keySet())
        //         FROM ServiceTerritoryMember
        //         WHERE ServiceResourceId in :srIds AND TerritoryType = 'P' AND FSL_Expired_Resource_Territory__c = false
        //     ];
    
        //     for(ServiceTerritoryMember stm : stms){
        //         // if(stm.ServiceResourceId == resource.ServiceResourceId){
        //         //     stm.ServiceAppointment.ServiceTerritoryID = stm.ServiceTerritoryId;
                    
        //         //     if('INSERT'.equals(operation)){
        //         //         stm.ServiceAppointment.Facility__c = stm.ServiceTerritoryId;
        //         //     }

        //             // Temporarily added to skip duplicate id issue.
        //             // if (!apptUpdates.contains(resource.ServiceAppointment)){
        //             //     apptUpdates.add(resource.ServiceAppointment);
        //             //     appointmentToTerritoryMap.put(resource.ServiceAppointment.ParentRecordId, stm.ServiceTerritory.Name);
        //             //     appointmentToAssignedUserMap.put(resource.ServiceAppointment.ParentRecordId, resource.ServiceResource.RelatedRecordId);
        //             // }
        //         // }
        //         serviceTerritoryMemberMap.put(stm.ServiceResourceId, stm);
        //         // appointmentToTerritoryMap.put(stm.ServiceAppointment.id, stm.ServiceTerritoryId);
        //     }
        //     // if(!apptUpdates.isEmpty()){
    
        //         // update apptUpdates;
        //         //mergeSAUpdates(apptUpdates, updatedSAs, operation);
        //     for (AssignedResource resource : resources.values()){
        //         ServiceTerritoryMember stm = serviceTerritoryMemberMap.get(resource.ServiceResourceId);
        //         if (stm != null) {
        //             ServiceAppointment sa = updatedSAMap.get(resource.ServiceAppointmentId);
        //             if ('INSERT'.equals(operation) && sa.Facility__c != stm.ServiceTerritoryId) {
        //                 sa.Facility__c = stm.ServiceTerritoryId;
        //             }
        //             if (sa.ServiceTerritoryID != stm.ServiceTerritoryId) {
        //                 sa.ServiceTerritoryID = stm.ServiceTerritoryId;
        //             }
        //             woIdToServiceTerritoryIds.put(sa.ParentRecordId, stm.ServiceResource.Primary_Service_Territory__r.Id);
        //             woIdToTruckIds.put(sa.ParentRecordId, stm.ServiceResource.LocationId__c);
        //         }
        //     }
    
        //     if (!updatedSAMap.isEmpty()) {
        //         update updatedSAMap.values();
        //     }
    
        //         //   ***  Service Tech Team: Commented out the method of Member Account Apex sharing    ***
        //         // shareMemberDetailsWithAssignedResource(appointmentToTerritoryMap, appointmentToAssignedUserMap);
        //     // }
        //     //For UF-121 & 160
        //     // if(!woIdToServiceTerritoryIds.isEmpty()){
        //     //     List<WorkOrder> workOrders = [SELECT Id, ServiceTerritoryId, LocationId FROM WorkOrder WHERE Id IN : woIdToServiceTerritoryIds.keySet()];
        //     //     for (WorkOrder workOrder : workOrders) {
        //     //         workOrder.ServiceTerritoryId = woIdToServiceTerritoryIds.get(workOrder.Id);
        //     //         workOrder.LocationId = woIdToTruckIds.get(workOrder.Id);
        //     //     }
    
        //        // mergeWOUpdates(workOrders,updatedWOs);
    
        //     for (WorkOrder wo : updatedWOs) {  
        //         if(wo.ServiceTerritoryId != woIdToServiceTerritoryIds.get(wo.Id)){
        //             wo.ServiceTerritoryId = woIdToServiceTerritoryIds.get(wo.Id);
        //         }
        //         wo.LocationId = woIdToTruckIds.get(wo.Id);
        //     }
    
        //     if (!updatedWOs.isEmpty()) {
        //         update updatedWOs;
        //     }
        // }
        
        // // public static void mergeSAUpdates(List<ServiceAppointment> updateList1, List<ServiceAppointment> updateList2, String operation){
        // // 	List<ServiceAppointment> finalUpdateList = new List<ServiceAppointment>();
        // // 	for(ServiceAppointment sa1 : updateList1){
                
        // // 		Boolean matchFound1 = false;
        // // 		for(ServiceAppointment sa2 : updateList2){
        // //             Boolean matchFound2 = false;
        // // 			if(sa1.id == sa2.id){
        // // 				// combine records
        // // 				ServiceAppointment combinedSA = new ServiceAppointment();
        // // 				combinedSa.id = sa1.id;
        // // 				if('INSERT'.equals(operation)){
        // // 					combinedSa.Facility__c = sa1.Facility__c;
        // // 				}
        // // 				combinedSa.ServiceTerritoryID = sa1.ServiceTerritoryID;
        // // 				combinedSa.Service_Resource__c = sa2.Service_Resource__c;
        // // 				combinedSa.status = sa2.status;
        // // 				combinedSa.isScheduledByDispatcher__c = sa2.isScheduledByDispatcher__c;
        // // 				finalUpdateList.add(combinedSa);
        // // 				matchFound1 = true;
        // //                 matchFound2 = true;
        // // 			}
    
        // //             // if no match found, add sa2 to list
        // //             if(!matchFound2){
        // // 			    finalUpdateList.add(sa2);
        // // 		    }
        // // 		}
                
        // // 		// if no match found, add sa1 to list
        // // 		if(!matchFound1){
        // // 			finalUpdateList.add(sa1);
        // // 		}
        // // 	}
    
        // //     try {
        // //         update finalUpdateList;
        // //     } catch (Exception ex) {
                
        // //         //NOTE: Currently there are 2 known exceptions that can happen here:
        // //         // 1: Modified fields by non-admin user when workorder has been cleared.
        // //         //    Refer to WorkOrder Status field validation rules WO_Read_Only_On_Cleared
        // //         // 2: Change to an in-active ServiceTerritory
    
        // //         ServiceAppointment sa = finalUpdateList.size() == 1 ? finalUpdateList[0] : null; //Only use info if there's exactly 1 item
    
        // //         String detail = '==== ServiceAppointment(s) Info ====\n' + finalUpdateList;
        // //         handleException(ex, sa?.parentRecordId, sa?.Id, detail);
        // //     }
        // // }
        
        // // public static void mergeWOUpdates(List<WorkOrder> updateList1, List<WorkOrder> updateList2){
    
        // // 	Map<Id, WorkOrder> finalUpdate = new Map<Id, WorkOrder>();
            
        // // 	for(WorkOrder wo1 : updateList1){
        // //         Boolean matchFound1 = false;
        // //         for(WorkOrder wo2 : updateList2) {       
        // //         Boolean matchFound2 = false;
        // //             if(wo1.id == wo2.id) {
        // //                 // combine records
        // //                 WorkOrder combinedWO = new WorkOrder();
        // //                 combinedWO.id = wo1.id;
        // //                 combinedWO.ServiceTerritoryId = wo1.ServiceTerritoryId;
        // //                 combinedWO.LocationId = wo1.LocationId;
        // //                 combinedWO.Service_Resource__c = wo2.Service_Resource__c;
        // //                 finalUpdate.put(combinedWO.Id, combinedWO);
        // //                 matchFound1 = true;
        // //                 matchFound2 = true;
        // //             }
    
        // //             // if no match found, add sa2 to list
        // //             if( !matchFound2) {
        // //                 finalUpdate.put(wo2.Id, wo2);
        // //             }
        // //         }
                
        // //         // if no match found, add sa1 to list
        // //         if(!matchFound1){
        // //             finalUpdate.put(wo1.Id, wo1);
        // //         }
        // // 	}
            
        // //     try {
        // //         update finalUpdate.values();
        // //     } catch (Exception ex) {
    
        // //         //NOTE: Currently there are 2 known exceptions that can happen here:
        // //         // 1: Modified fields by non-admin user when workorder has been cleared.
        // //         //    Refer to WorkOrder Status field validation rules WO_Read_Only_On_Cleared
        // //         // 2: Change to an in-active ServiceTerritory
    
        // //         WorkOrder wo = finalUpdate.size() == 1 ? finalUpdate.values()[0] : null; //Only use info if there's exactly 1 item
        // //         String detail = '==== WorkOrder(s) Info ====\n' + finalUpdate.values();
        // //         handleException(ex, wo?.Id, null, detail);
        // //     }
    
        // // }
    
        // // private static void handleException(Exception ex, Id workOrderId, Id servApptId, String detail) {
    
        // //     String response =
        // //           'User Id: ' + UserInfo.getUserId() + '\n'
        // //         + 'User Name: ' + UserInfo.getUserName() + '\n'
        // //         + + '\n' + detail + '\n'
        // //         + '\n==== Stack Trace ====\n'
        // //         + ex.getStackTraceString();
    
        // //     //NOTE: Must use platform event since can't use regular logging mechanism when trigger is throwing exception.
    
        // //     Application_Log_Event__e ev = new Application_Log_Event__e();
    
        // //     ev.API_Name__c = 'Trigger Exception';
        // //     ev.Operation__c = 'Update Facility';
        // //     ev.Message__c = ex.getMessage();
        // //     ev.Error_Caught__c = true;
        // //     ev.Service_Appointment_Id__c = servApptId;
        // //     ev.Work_Order_Id__c = workOrderId;
        // //     ev.Response_Body__c = response;
    
        // //     EventBus.publish(ev);
    
        // //     throw ex;
    
        // // }
    
    
    
    
        // //   ***  Service Tech Team: Commented out the method of Member Account Apex sharing    ***
        
        // // public static void shareMemberDetailsWithAssignedResource(Map<ID, String> appointmentToTerritoryMap, Map<ID, ID> appointmentToAssignedUserMap){
        // //     Set<ID> woIDs = new Set<ID>();
        // //     Set<String> territories = new Set<String>();
        // //     for(ID woID : appointmentToTerritoryMap.keySet()){
        // //         woIDs.add(woID);
        // //     }
        // //     for(String territoryStr : appointmentToTerritoryMap.values()){
        // //         territories.add(territoryStr);
        // //     }
        // //     List<WorkOrder> woList = [SELECT id, Member_Account__c FROM WorkOrder WHERE ID IN :woIDs];
        // //     List<Group> pGroupList = [Select id,name from Group where name IN :territories];
            
        // //     List<AccountShare> accShareList = new List<AccountShare>();
        // //     for(WorkOrder wo : woList){
        // //         for(Group grp : pGroupList){
        // //             if(appointmentToTerritoryMap.get(wo.id) == grp.Name){
        // //                 AccountShare accShare = new AccountShare();
        // //                 accShare.AccountId = wo.Member_Account__c;
        // //                 accShare.UserOrGroupId = grp.Id;
        // //                 accShare.AccountAccessLevel = 'Edit'; 
        // //                 accShare.OpportunityAccessLevel  = 'Edit';
        // //                 //accshare.ContactAccessLevel  = 'Edit';    
        // //                 accShareList.add(accshare);            
        // //             }   
        // //         }
        // //     }
    
        // //     if(!accShareList.isEmpty()){        
        // //         Database.Insert(accShareList);      
        // //     }
        // // }
    }