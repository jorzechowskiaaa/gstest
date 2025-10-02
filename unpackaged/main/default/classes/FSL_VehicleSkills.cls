/**
 * @File Name          : FSL_VehicleSkills.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 6/12/2020, 12:07:12 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/27/2020   Rajesh Kemisetti     Initial Version
**/
public class FSL_VehicleSkills {   
    
    
    /**********
     * @Method Name: manipulateSkills
     * @Parameters:(Map<id,ServiceResource>, Map<Id, ServiceResource>, String)
     * @Return Value: none
     * @Description: Accepts the map of ServiceResources and creates ServiceResourceSkill based on vehicle type
       @Author: Divyendra Naidu
     * **********/ 

    //Start Method            
    public static void manipulateSkills(Map<Id, ServiceResource> oldMap, Map<Id, ServiceResource> newMap, String operation) {
        System.debug('Entering manipulateSkills');
        List<Skill> skillList = new List<Skill>([SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN
        ('Change_Tire','Extrication','Lockout_Entry','Locksmith','Tire_Fill')]);

        List<Id> skillIdList = new List<Id>();
        for(Skill sk : skillList) {
            skillIdList.add(sk.Id);
        }
        //Begin Insert Operation    
        if(operation == 'insert') {
            List<ServiceResourceSkill> srSkillList = new List<ServiceResourceSkill>();
            for(ServiceResource sr : newMap.values()) {
                for(Skill sk : skillList) {
                    ServiceResourceSkill srsTemp = new ServiceResourceSkill(SkillId = sk.id, ServiceResourceId = sr.Id, EffectiveStartDate = System.today(), SkillLevel = 1,Skill_Type__c = 'Resource-Dependent');
                    srSkillList.add(srsTemp);
                    }                    
            }          
            insert srSkillList;
        } //End Insert Operation
    }//End Method 
    
    public static void assignVehicleSkills(List<ServiceResource> modifiedServiceResources) {
        Set<ID> srIDSet = new Set<ID>();
        Set<ID> vehicleTypeIDSet = new Set<ID>();
        Map<String, Skill> skillMap = skillMapHelper();
        Map<ServiceResource, ID> resourceToVehicleTypeMap = new Map<ServiceResource, ID>();
        Set<Id> vehicleIds = new Set<Id>();
        Map<Id,Schema.Location> vehicleMap = new Map<Id,Schema.Location>();
        for(ServiceResource updatedSR : modifiedServiceResources){
            System.debug('updatedSR.Vehicle__c======>'+updatedSR.Vehicle__c);
            if(updatedSR.Vehicle__c != null) {
                vehicleIds.add(updatedSR.Vehicle__c);
            }
        }
        System.debug('vehicleIds====>'+vehicleIds);
        if(!vehicleIds.isEmpty()) {
            vehicleMap = new Map <Id,Schema.Location> ([Select Id, Vehicle_Type__c,VehicleType__c, Battery_Capable__c, RV_Capable__c, Motorcycle_Capable__c FROM Location WHERE Id IN: vehicleIds]);
        }
        System.debug('vehicleMap======>'+vehicleMap);
        // iterate over updated srs
        for(ServiceResource updatedSR : modifiedServiceResources){
            
            // add sr ids to set
            srIDSet.add(updatedSR.id); 
            
            // add vehicle type ids to set
            if(updatedSR.Vehicle__c != null) {
                vehicleTypeIDSet.add(vehicleMap.get(updatedSR.Vehicle__c).VehicleType__c);

                // create map of service resource (key) to vehicle type  (value / id)
                resourceToVehicleTypeMap.put(updatedSR, vehicleMap.get(updatedSR.Vehicle__c).VehicleType__c);
            }
        }       
        system.debug('**vehicleTypeIDSet**'+vehicleTypeIDSet);
        // query junction object using vehicle type IDs
        List<Vehicle_Skill__c> vehicleSkills = [SELECT id, Skill__c, Skill__r.Developer_Name__c, Skill_Level__c, Vehicle_Type__c
            FROM Vehicle_Skill__c 
            WHERE Vehicle_Type__c IN :vehicleTypeIDSet];
        System.debug('vehicleSkills===>'+vehicleSkills);
        // create map of vehicle type (key) to list of vehicle type skills (value)
        Map<ID, List<Vehicle_Skill__c>> vehicleTypeToSkillListMap = new Map<ID, List<Vehicle_Skill__c>>();
        List<Vehicle_Skill__c> profileSkills = new List<Vehicle_Skill__c>();
        for(Vehicle_Skill__c vehicleSkill : vehicleSkills) {
            if(vehicleTypeToSkillListMap.get(vehicleSkill.Vehicle_Type__c) != null) {
                vehicleTypeToSkillListMap.get(vehicleSkill.Vehicle_Type__c).add(vehicleSkill);
            }else {
                vehicleTypeToSkillListMap.put(vehicleSkill.Vehicle_Type__c,new List<Vehicle_Skill__c>{vehicleSkill});
            }
        }

        // query service resource skills assigned to srs
        List<ServiceResourceSkill> currentResourceSkills = [SELECT id, Skill_DeveloperName__c, Skill_Type__c, ServiceResourceId, SkillID, SkillLevel
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :srIDSet AND Skill_Type__c = 'Vehicle-Dependent'];
        
        
        // create map of service resource ID to assigned skills
        Map<Id,List<ServiceResourceSkill>> currentResourcesVehicleSkills = new Map<Id,List<ServiceResourceSkill>>();
        for(ServiceResourceSkill currentResourceSkill : currentResourceSkills) {
            if(currentResourcesVehicleSkills.get(currentResourceSkill.ServiceResourceId) != null) {
                currentResourcesVehicleSkills.get(currentResourceSkill.ServiceResourceId).add(currentResourceSkill);
            }else {
                currentResourcesVehicleSkills.put(currentResourceSkill.ServiceResourceId,new List<ServiceResourceSkill>{currentResourceSkill});
            }
        }

        // iterate over assigned resource that was modified
        List<ServiceResourceSkill> skillsToDelete = new List<ServiceResourceSkill>(); 
        List<ServiceResourceSkill> skillsToInsert = new List<ServiceResourceSkill>();
        
        for(ServiceResource srToModify : modifiedServiceResources){
            skillsToDelete.addAll(assignedSkillToAppliedSkillParser(srToModify, currentResourcesVehicleSkills, vehicleTypeToSkillListMap, vehicleMap));
            skillsToInsert.addAll(appliedSkillToAssignedSkillModified(srToModify, currentResourcesVehicleSkills, vehicleTypeToSkillListMap, skillMap, vehicleMap));
        }
         
        // perform deletes
        if(!skillsToDelete.isEmpty()){
            delete skillsToDelete;
        }

        // perform inserts
        if(!skillsToInsert.isEmpty()){
            // TODO: Database.upsert with partial success
            Database.upsert(skillsToInsert,false);
        }

                 
            
    }
    
    public static Map<String, Skill> skillMapHelper(){
        Map<String, Skill> skillMap = new Map<String, Skill>();
        List<Skill> skillList = [SELECT Id, DeveloperName FROM Skill];
        for(Skill sk : skillList){
            skillMap.put(sk.DeveloperName, sk);
        }

        return skillMap;
    }

    public static List<ServiceResourceSkill> assignedSkillToAppliedSkillParser(ServiceResource currentSR, Map<Id,List<ServiceResourceSkill>> currentResourcesVehicleSkills, Map<ID, List<Vehicle_Skill__c>> vehicleTypeToSkillListMap, Map<Id,Schema.Location> vehicleMap){
        List<ServiceResourceSkill> skillsToDelete = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> assignedSkills = currentResourcesVehicleSkills.get(currentSR.id);
        if(assignedSkills != null) {
            for(ServiceResourceSkill srSkill : assignedSkills){
                Boolean matchFound = false;
                // iterate over skills that should be updated for this resouces vehicle type
                if(currentSR.Vehicle__c != null && vehicleMap.get(currentSR.Vehicle__c).VehicleType__c != null && vehicleTypeToSkillListMap.get(vehicleMap.get(currentSR.Vehicle__c).VehicleType__c) != null) {
                    List<Vehicle_Skill__c> vehicleTypeSkills = vehicleTypeToSkillListMap.get(vehicleMap.get(currentSR.Vehicle__c).VehicleType__c);
                    for(Vehicle_Skill__c skillKey : vehicleTypeSkills){
                        if(srSkill.Skill_DeveloperName__c == skillKey.Skill__r.Developer_Name__c){
                            matchFound = true;
                            
                            // upsert list?
                        }
                    }
                }
                
                
                // if no match found, add to delete list
                if(!matchFound){
                    skillsToDelete.add(srSkill);
                }        
            }
        }
        

        return skillsToDelete;
    }


    public static List<ServiceResourceSkill> appliedSkillToAssignedSkillModified(ServiceResource currentSR, Map<Id,List<ServiceResourceSkill>> currentResourcesVehicleSkills, Map<ID, List<Vehicle_Skill__c>> vehicleTypeToSkillListMap, Map<String, Skill> skillMap, Map<Id,Schema.Location> vehicleMap){
        List<ServiceResourceSkill> skillsToUpsert = new List<ServiceResourceSkill>();
        system.debug('currentSR**'+currentSR);
        system.debug('vehicleMap**'+vehicleMap);
        system.debug('vehicleTypeToSkillListMap**'+vehicleTypeToSkillListMap);
        if(currentSR.Vehicle__c != null && vehicleMap.get(currentSR.Vehicle__c).VehicleType__c != null &&  vehicleTypeToSkillListMap.get(vehicleMap.get(currentSR.Vehicle__c).VehicleType__c) != null) {
            List<Vehicle_Skill__c> vehicleTypeSkills = vehicleTypeToSkillListMap.get(vehicleMap.get(currentSR.Vehicle__c).VehicleType__c);
        
            for(Vehicle_Skill__c skillKey : vehicleTypeSkills){
                Boolean matchFound = false;
                // iterate over skills that should be updated for this resouces vehicle type
                List<ServiceResourceSkill> assignedSkills = currentResourcesVehicleSkills.get(currentSR.id);
                if(assignedSkills != null) {
                    for(ServiceResourceSkill srSkill : assignedSkills){
                        if(srSkill.Skill_DeveloperName__c == skillKey.Skill__r.Developer_Name__c){
                            matchFound = true;
                            // update the skill
                            srSkill.SkillLevel = skillKey.Skill_Level__c;
                            skillsToUpsert.add(srSkill);
                        }
                    }
                }
                // if no match found, create a new skill for this resource
                if(!matchFound){
                    ID skillID = skillMap.get(skillKey.Skill__r.Developer_Name__c).id;
                    ServiceResourceSkill newSRSkill = new ServiceResourceSkill();
                    
                    newSRSkill.EffectiveStartDate = DateTime.now();
                    //srSkill.EffectiveEndDate
                    newSRSkill.ServiceResourceId = currentSR.id;
                    newSRSkill.SkillId = skillID;
                    newSRSkill.SkillLevel = skillKey.Skill_Level__c;
                    newSRSkill.Skill_Type__c = 'Vehicle-Dependent';
                    skillsToUpsert.add(newSRSkill);
                }        
            }

        }
        
        return skillsToUpsert;
    }    
}//End Class