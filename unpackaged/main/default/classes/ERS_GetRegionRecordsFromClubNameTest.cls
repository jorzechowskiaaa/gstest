@isTest
public class ERS_GetRegionRecordsFromClubNameTest {
   @isTest
     Public Static void getRegionNamesTest()
     {
      List<ClubName_To_Region_Mapping__mdt> regList=[SELECT Club_Region__c FROM ClubName_To_Region_Mapping__mdt WHERE Club_Name__c=:'AAA North Dakota - 113'];
       Test.startTest();
      List<string> lstRegions = ERS_GetRegionRecordsFromClubName.getRegionNames('AAA North Dakota - 113');
        Test.stopTest();
      If(lstRegions.size()>0){
           system.assertEquals(regList[0].Club_Region__c,lstRegions[0]);
      } 

     }
}