/*
* @description: Test class for ACG_GetRecordsFrom_MasterVehicle
* @date: September 2,2021
* author: Deloitte USI
*/

@isTest
public class ACG_GetRecordsFrom_MasterVehicleTest {  
    
    @testSetup static void setup() {
        // Create common test accounts
        ACG_Master_Vehicle__c MasterVehicle1= New ACG_Master_Vehicle__c(ACG_Vehicle_Make__c='DODGE',ACG_Vehicle_Model__c='AVENGER',ACG_Vehicle_Year__c='1996');
        Insert MasterVehicle1;
    }
    
     @isTest
     Public Static void getRecordsfromMakeModelYearTest()
     {
         Test.startTest();
         List<AggregateResult> lstVehicles=ACG_GetRecordsFrom_MasterVehicle.getRecordsfromMakeModelYear('DODGE','AVENGER','1996');
         Test.stopTest();
         If(lstVehicles.size()>0){
          system.assertEquals(1,lstVehicles.size());
        
       }
     }
 
      @isTest
    public static void getUniqueMakesTest(){
        Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getUniqueMakes();
        Test.stopTest();
      If(lstVehicles.size()>0){
           system.assertEquals('DODGE',lstVehicles[0]);
       }
        
    }
     @isTest
    public static void getModelfromMakeTest(){
        Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getModelfromMake('DODGE');
        Test.stopTest();
      If(lstVehicles.size()>0){
           system.assertEquals('AVENGER',lstVehicles[0]);
      } 
    }
     @isTest
    public static void getYearfromMakeAndModelTest(){
        Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getYearfromMakeAndModel('DODGE','AVENGER');
        Test.stopTest();
      If(lstVehicles.size()>0){
           system.assertEquals('1996',lstVehicles[0]);
      }
    } 
    
    @isTest
    public static void getUniqueYearsTest(){
       Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getUniqueYears();
         Test.stopTest();
      If(lstVehicles.size()>0){
           system.assertEquals('1996',lstVehicles[0]);
       }
    }
     @isTest
    public static void getMakefromYearTest(){
    Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getMakefromYear('1996'); 
       If(lstVehicles.size()>0){
           system.assertEquals('DODGE',lstVehicles[0]);
       }
    }
     @isTest
    public static void getModelfromYearAndMakeTest(){
      Test.startTest();
      List<string> lstVehicles = ACG_GetRecordsFrom_MasterVehicle.getModelfromYearAndMake('1996','DODGE');  
        If(lstVehicles.size()>0){
           system.assertEquals('AVENGER',lstVehicles[0]);
       }
    }
}