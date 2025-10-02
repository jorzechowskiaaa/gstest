/************************************************************************************
Apex Class Name     : ACG_GetRecordsFromAnnouncements
Created Date        : 15th September 2021
Function            : Get the records from Master Vehicle 
Author              : Deloitte Consulting 
Test Class Name    :    
Modification Log
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
*   Sarita Mishra           Sep 15 2021                 Created (ERSBO-73)
*   Tarun Singh             Sep 27 2021                 Edited  (ERSBO-1699)
*************************************************************************************/

public class ACG_GetRecordsFromAnnouncements {
     /***
    * Method name        : getRecordsFromAnnouncement
    * Description        : This method returns all the Announcement records, that match with the Case criteria.
    * Return Type        : List<Announcements__c>
    */
     @AuraEnabled(cacheable=false)
    Public Static List<Announcements__c> getRecordsFromAnnouncement(Id CaseId){
        Map<String, List<Announcements__c>> PriorityMap = new Map<String, List<Announcements__c>>();
        List<Announcements__c> lstToBeReturned = new List<Announcements__c>();
        
        Case objCase = [SELECT  Id, 
                                AccountId,ACG_Service_Type__c,Member_Vehicle_Type__c,
                                Club_Name__c,
                                Vehicle_Location_City__c,Vehicle_Location_State__c,Vehicle_Location_Postal_Code__c,
                                RecordTypeId
                        FROM Case
                        WHERE Id =:CaseId LIMIT 1];
           
        List<Account> MemberAccount= [SELECT Id, Level_of_Membership__c, AAA_Membership_Level__c FROM Account WHERE Id =:objCase.AccountId];
        String MembershipLevel = MemberAccount.isEmpty() ? NULL : MemberAccount[0].AAA_Membership_Level__c;
        
        List<Announcements__c> lstRecords=[SELECT  Id,
                                                   Announcement_Description__c,Announcement_Location__c,Announcement_Priority__c,Approval_Status__c,
                                                   Case_Record_Type__c,City__c,Club__c,
                                                   DRR__c,
                                                   Effective_Date__c,Expiration_Date__c,
                                                   Global__c,
                                                   Membership_Level__c,
                                                   Name,
                                                   Service_Types__c,State__c,Status__c,
                                                   Vehicle_Type__c,
                                                   Zip_Code__c 
                                           FROM Announcements__c
                                                /*ERSBO-73 (Sarita Mishra)*/
                                           WHERE Status__c='Active'             
                                           AND Approval_Status__c='Approved' 
                                           AND Effective_Date__c<=:System.now() 
                                           AND Expiration_Date__c>=:System.now() 
                                                /*ERSBO-1699 (Tarun Singh)*/
                                           AND (Service_Types__c =:objCase.ACG_Service_Type__c OR Service_Types__c = NULL)  
                                           AND (Global__c =TRUE 
                                                OR(    (City__c =: objCase.Vehicle_Location_City__c OR City__c = NULL)
                                                   AND (State__c =: objCase.Vehicle_Location_State__c OR State__c = NULL)
                                                   AND (Zip_Code__c =: objCase.Vehicle_Location_Postal_Code__c OR Zip_Code__c = NULL)
                                                  )
                                               )
                                           AND (Vehicle_Type__c =: objCase.Member_Vehicle_Type__c OR Vehicle_Type__c = NULL)
                                           AND (Membership_Level__c =:MembershipLevel OR Membership_Level__c = NULL)
                                           AND (Case_Record_Type__c = 'ERS' OR Case_Record_Type__c = NULL)
                                           AND (Announcement_Location__c INCLUDES ('Case') OR Announcement_Location__c = NULL )
                                           AND (Club__c =:objCase.Club_Name__c OR Club__c = NULL)
                                           ORDER BY Zip_Code__c NULLS LAST,City__c NULLS LAST,State__c NULLS LAST
                                           LIMIT :Limits.getLimitQueryRows()];
        
        system.debug('lstRECCSSS'+lstRecords);
        if(!lstRecords.isEmpty()){
            for(Announcements__c rec: lstRecords){
                /*Prioritize the Announcements*/
                List<Announcements__c> tempList = new List<Announcements__c>();
                    
                if(PriorityMap.get(rec.Announcement_Priority__c) != NULL){  // If there are existing records for that Priority
                    tempList = PriorityMap.get(rec.Announcement_Priority__c);
                    tempList.add(rec);
                }
                else{   // If there are no records for that priority.
                    tempList.add(rec);
                }
                //Assign based on Priority   
                PriorityMap.put(rec.Announcement_Priority__c, tempList);
            }
            if(PriorityMap.get('Critical') != NULL) { lstToBeReturned.addAll(PriorityMap.get('Critical'));  }
            if(PriorityMap.get('High') != NULL) { lstToBeReturned.addAll(PriorityMap.get('High'));  }
            if(PriorityMap.get('Medium') != NULL) { lstToBeReturned.addAll(PriorityMap.get('Medium'));  }
            if(PriorityMap.get('Normal') != NULL) { lstToBeReturned.addAll(PriorityMap.get('Normal'));  }
            if(PriorityMap.get('Low') != NULL) { lstToBeReturned.addAll(PriorityMap.get('Low'));    }
            if(PriorityMap.get(NULL) != NULL) { lstToBeReturned.addAll(PriorityMap.get(NULL));  }   //If no Announcement Priority is mentioned, add to last
            
            return lstToBeReturned;
        }
        return NULL;
   }
}