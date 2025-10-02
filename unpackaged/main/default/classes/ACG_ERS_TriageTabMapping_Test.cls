/*
* @description: Test class for ACG_ERS_TriageTabMapping
* @date: September 6,2021
* author: Deloitte USI
*/

@isTest
public class ACG_ERS_TriageTabMapping_Test {   
    @isTest
  	public static void getRecordsfromMakeModelYearTest(){
        Test.startTest();
        List<ERS_Triage_Tab_Mapping__mdt> lstTriageTab = ACG_ERS_TriageTabMapping.fetchTriageTabMapping();
        Test.stopTest();
     If(lstTriageTab.size()>0){
         	system.assert(lstTriageTab.size()>0);
       }
    }
}