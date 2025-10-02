/**
* @File Name : duplicateCallCheckController.cls
* @Description : For https://aaa-ne.atlassian.net/browse/SSFI-784, Checks for open work orders for a given contact id / member number
* @Author : John Orzechowski
* @Last Modified On : April 24, 2025
**/

public without sharing class duplicateCallCheckController {
	@AuraEnabled(cacheable=true)
	public static List<WorkOrder> checkForDuplicateWOs(String memberNumber, String contactId) { 
		System.debug('checking for duplicate work orders, contact id: ' +contactId + ' or member number: ' + memberNumber);
		
		try {
			List<WorkOrder> duplicateWOs = new List<WorkOrder>();
             
            // exclude query conditions that are null
            if (memberNumber != null && contactId != null) {
                duplicateWOs = [
                    SELECT Id, WorkOrderNumber, Channel__c, Status, Call_Date__c, Work_Order_Record_Type__c from WorkOrder WHERE 
                    (Member_Number__c = :memberNumber 
                    OR ContactId = :contactId)
                    AND Status in ('Spotted', 'In Progress') LIMIT 5
                ];
            } else if (memberNumber == null && contactId != null) {
                duplicateWOs = [
                    SELECT Id, WorkOrderNumber, Channel__c, Status, Call_Date__c, Work_Order_Record_Type__c from WorkOrder WHERE 
                    ContactId = :contactId
                    AND Status in ('Spotted', 'In Progress') LIMIT 5
                ];
            } else if (memberNumber != null && contactId == null) {
                duplicateWOs = [
                    SELECT Id, WorkOrderNumber, Channel__c, Status, Call_Date__c, Work_Order_Record_Type__c from WorkOrder WHERE 
                    Member_Number__c = :memberNumber
                    AND Status in ('Spotted', 'In Progress') LIMIT 5
                ];
            }
            // check that records were returned
            if (duplicateWOs.size() > 0) {
                return duplicateWOs;
            }
			else { 
				return null; 
			}
			
		} catch (exception e) {
			System.debug('Error fetching duplicate work orders: ' + e.getMessage());
		}

		return null; 	
	}

}