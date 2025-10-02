/************************************************************************************
Apex Class Name     : ACG_GetRecordsFrom_MasterVehicle
Created Date        : 31st August 2021
Function            : Get the records from Master Vehicle 
Author              : Deloitte Consulting 
*************************************************************************************/
public class ACG_GetRecordsFrom_MasterVehicle {
    @AuraEnabled(cacheable=true)
    Public Static List<AggregateResult> getRecordsfromMakeModelYear(String Make,String Model,String Year)
    {	List<AggregateResult> agrRecords =[SELECT ACG_Vehicle_Make__c,ACG_Vehicle_Model__c,ACG_Vehicle_Year__c,ACG_Vehicle_Drive_Type__c,ACG_Vehicle_Fuel_Type__c,Vehicle_Type__c,Vehicle_Body_Type__c
                           FROM ACG_Master_Vehicle__c 
                           WHERE ACG_Vehicle_Make__c =:Make 
                           AND ACG_Vehicle_Model__c =:Model
                           AND ACG_Vehicle_Year__c=:Year
                           GROUP BY ACG_Vehicle_Year__c,ACG_Vehicle_Make__c,ACG_Vehicle_Model__c,ACG_Vehicle_Drive_Type__c,ACG_Vehicle_Fuel_Type__c,Vehicle_Type__c,Vehicle_Body_Type__c];
    	
     	return agrRecords;
    }
    
    
    @AuraEnabled(cacheable=true)
    Public Static List<String> getUniqueMakes()
    {  
       Set<String> setMakes = new Set<String>();
        List<String> returnList	= new List<String>();
        for(AggregateResult getMake : [SELECT FORMAT(ACG_Vehicle_Make__c) VehicleDataERS FROM ACG_Master_Vehicle__c GROUP BY ACG_Vehicle_Make__c LIMIT 2000]){
            returnList.add((String)getMake.get('VehicleDataERS'));
        }
         return returnList;
     }
    
    @AuraEnabled(cacheable=true)
    Public Static List<String> getModelfromMake(String Make)
    {
        Set<String> setModels = new Set<String>();
        List<String> returnList	= new List<String>();
        for(AggregateResult getMake : [SELECT FORMAT(ACG_Vehicle_Model__c) VehicleDataERS FROM ACG_Master_Vehicle__c WHERE ACG_Vehicle_Make__c=:Make
                                        GROUP BY ACG_Vehicle_Model__c LIMIT 2000]){
        returnList.add((String)getMake.get('VehicleDataERS'));
        }
        return returnList;
    }
    @AuraEnabled(cacheable=true)
  Public Static List<String> getYearfromMakeAndModel(String Make,String Model)
  {
      Set<string> setYears=new Set<string>();
       List<String> returnList	= new List<String>();
      for(AggregateResult getMake : [SELECT FORMAT(ACG_Vehicle_Year__c) VehicleDataERS FROM ACG_Master_Vehicle__c WHERE ACG_Vehicle_Make__c=:Make AND 
                                     ACG_Vehicle_Model__c=:Model GROUP BY ACG_Vehicle_Year__c LIMIT 2000]){
                                      returnList.add((String)getMake.get('VehicleDataERS'));
        }
        return returnList;
   }
    
     @AuraEnabled(cacheable=true)
    Public Static List<String> getUniqueYears()
    {  
       Set<String> getYears = new Set<String>();
        List<String> returnList	= new List<String>();
        for(AggregateResult getYear : [SELECT FORMAT(ACG_Vehicle_Year__c) VehicleDataERS FROM ACG_Master_Vehicle__c GROUP BY ACG_Vehicle_Year__c LIMIT 2000]){
            returnList.add((String)getYear.get('VehicleDataERS'));
        }
         return returnList;
     }
    
    @AuraEnabled(cacheable=true)
    Public Static List<String> getMakefromYear(String Year)
    {
        Set<String> setMakes = new Set<String>();
        List<String> returnList	= new List<String>();
        for(AggregateResult getMake : [SELECT FORMAT(ACG_Vehicle_Make__c) VehicleDataERS FROM ACG_Master_Vehicle__c WHERE ACG_Vehicle_Year__c=:Year
                                        GROUP BY ACG_Vehicle_Make__c LIMIT 2000]){
        returnList.add((String)getMake.get('VehicleDataERS'));
        }
        return returnList;
    }
    
       @AuraEnabled(cacheable=true)
  Public Static List<String> getModelfromYearAndMake(String Year,String Make)
  {
      Set<string> setModels=new Set<string>();
       List<String> returnList	= new List<String>();
      for(AggregateResult getMake : [SELECT FORMAT(ACG_Vehicle_Model__c) VehicleDataERS FROM ACG_Master_Vehicle__c WHERE ACG_Vehicle_Make__c=:Make AND 
                                     ACG_Vehicle_Year__c=:Year GROUP BY ACG_Vehicle_Model__c LIMIT 2000]){
                                      returnList.add((String)getMake.get('VehicleDataERS'));
        }
        return returnList;
   }
    
  
}