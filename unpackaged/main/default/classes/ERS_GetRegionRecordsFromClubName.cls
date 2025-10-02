/************************************************************************************
Apex Class Name     : ERS_GetRegionRecordsFromClubName
Created Date        : 19th Nov 2021
Function            : Get the records from ClubName To Region Mapping Metadata
Author              : Deloitte Consulting 
*************************************************************************************/
public class ERS_GetRegionRecordsFromClubName {
 @AuraEnabled(cacheable=true)
  Public Static List<String> getRegionNames(String ClubName)
  {
    List<String> clubRegionsList = new List<String>();  
    for(ClubName_To_Region_Mapping__mdt  regNames:[SELECT Club_Region__c FROM ClubName_To_Region_Mapping__mdt WHERE Club_Name__c=:ClubName ])
    {
        clubRegionsList.add(regNames.Club_Region__c);
    }
    return clubRegionsList;
  }
}