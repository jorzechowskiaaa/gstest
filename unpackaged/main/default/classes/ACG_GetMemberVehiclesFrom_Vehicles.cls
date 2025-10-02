/************************************************************************************
Apex Class Name     : ACG_GetRecordsFrom_MasterVehicle
Created Date        : 27th Sept 2021
Function            : Get the records from Master Vehicle 
Author              : Deloitte Consulting 
*************************************************************************************/

public class ACG_GetMemberVehiclesFrom_Vehicles {
    @AuraEnabled(cacheable=false)
    Public static List<FSL_Member_Vehicle__c> getMemberVehicles(Id AccountId){
        Id customer_RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        if(AccountId != NULL){
            // ----------- Commented out by SF team as ACE and NE doesn't use Financial Service cloud ------------
         	/*Id household_RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
            List<AccountContactRelation> lstHouseholdAccounts = [SELECT AccountId,Contact.AccountId
                                                                FROM AccountContactRelation 
                                                                WHERE ContactId IN (SELECT PersonContactId
                                                                                    FROM Account
                                                                                    WHERE Id =:AccountId) 
                                                                AND Account.RecordTypeId =: household_RecordTypeId LIMIT 1];
            if(!lstHouseholdAccounts.isEmpty()){
                Id householdId = lstHouseholdAccounts[0].AccountId;
                List<FSL_Member_Vehicle__c> lstMemberVehicles=[SELECT Id,Name 
                                                       FROM FSL_Member_Vehicle__c
                                                       WHERE ACG_Member_Household__c= :householdId];
                if(!lstMemberVehicles.isEmpty()) {
                    lstMemberVehicles.sort();
                    return lstMemberVehicles;
                }
            }*/
            //else {
            Account accObj = new Account();
            accObj = [SELECT RecordTypeId  FROM Account WHERE Id =:AccountId];
                if(accObj.RecordTypeId == customer_RecordTypeId){
                List<FSL_Member_Vehicle__c> lstMemberVehicles = [SELECT Id,Name FROM FSL_Member_Vehicle__c
                                                                WHERE ACG_Member__c= : AccountId];
                  if(!lstMemberVehicles.isEmpty()) {
                    lstMemberVehicles.sort();
                    return lstMemberVehicles;
                }
                }
            //}
        }
        return NULL;
    }

    @AuraEnabled(cacheable = true)
    public static String getVehicleType(Id memberVehicle){
        FSL_Member_Vehicle__c vehicleInfo = [SELECT Id, Vehicle_Type__c 
                                             FROM FSL_Member_Vehicle__c 
                                             WHERE Id =:memberVehicle
                                             LIMIT 1];
        
        List<ERS_Case_VehicleType_Mapping__mdt> mdtRec = new List<ERS_Case_VehicleType_Mapping__mdt>();
        if( String.isNotBlank(vehicleInfo.Vehicle_Type__c)){
           mdtRec.add([SELECT Id, Vehicle_Type_Case__c, Vehicle_Type_Master_Vehicle__c
                                                          FROM ERS_Case_VehicleType_Mapping__mdt
                                                          WHERE Vehicle_Type_Master_Vehicle__c = :vehicleInfo.Vehicle_Type__c LIMIT 1]);
        }
            
        String retVal = '';
        if(!mdtRec.isEmpty()){
            retVal = mdtRec[0].Vehicle_Type_Case__c;
        }
            return retVal;
        
    }

    @AuraEnabled(cacheable = true)
    public static String getVehicleDetails(Id vehicleId){
        ACG_Master_Vehicle__c vehicleInfo = new ACG_Master_Vehicle__c();
        try{
            vehicleInfo = [SELECT Id
                                                , Vehicle_Type__c 
                                                , ACG_Vehicle_Make__c
                                                , ACG_Vehicle_Model__c
                                                , ACG_Vehicle_Year__c
                                                FROM ACG_Master_Vehicle__c 
                                                WHERE Id =:vehicleId
                                                LIMIT 1];
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(vehicleInfo);
    }

    @AuraEnabled(cacheable=false)
    public static FSL_Member_Vehicle__c getMemberVehicleDetail(Id memberVehicleId){
        List<FSL_Member_Vehicle__c> results = [
                                            SELECT Id,
                                            Vehicle_Year__c,
                                            Vehicle_Make__c,
                                            Vehicle_Model__c,
                                            Vehicle_Color__c,
                                            Vehicle_Type__c,
            								Vehicle_Plate__c, //added for plate2vin AGB 6/3/2025 SSFI-245
            								Vehicle_State__c //added for plate2vin AGB 6/3/2025 SSFI-245
                                            FROM FSL_Member_Vehicle__c 
                                            WHERE Id =:memberVehicleId
                                            LIMIT 1];
        

        return !results.isEmpty() ? results[0] : null;
        
    }

    @AuraEnabled(cacheable = true)
    public static String mapVehicleType(String masterVehicleType){
        List<ERS_Case_VehicleType_Mapping__mdt> mdtRec = [SELECT Vehicle_Type_Case__c
                                                          FROM ERS_Case_VehicleType_Mapping__mdt
                                                          WHERE Vehicle_Type_Master_Vehicle__c = :masterVehicleType LIMIT 1];
                                                                     
        String retVal = '';
        if(!mdtRec.isEmpty()){
            retVal = mdtRec[0].Vehicle_Type_Case__c;
        }
        return retVal;
        
    }
}