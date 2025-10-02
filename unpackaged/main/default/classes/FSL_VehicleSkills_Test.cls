@isTest
public class FSL_VehicleSkills_Test {
    
    static testMethod void manipulateSkillswithVehicleTest(){
        System.Test.startTest();
        
        List<Skill> skill = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName NOT IN
                             ('Battery_Replacement', 
                              'Change_Tire',
                              'Extrication', 
                              'Flatbed', 
                              'Light_Service',
                              'Lockout_Entry',
                              'Motorcycle_Capable',
                              'RV_Capable', 
                              'Tire_Fill', 
                              'Tow', 
                              'Wheel_Lift')];
        
        ServiceResource serviceResource = [select id, Vehicle__c, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        Map<Id, ServiceResource> newMap = new Map<Id, ServiceResource>();
        newMap.put(serviceResource.Id, serviceResource);
        FSL_VehicleSkills.manipulateSkills(new Map<Id, ServiceResource>(), newMap, 'insert'); 
        System.Test.stopTest();
    }
    
    static testMethod void manipulateSkills_UpdateTest(){
        System.Test.startTest();
        ServiceTerritory st = [select id from ServiceTerritory where facility_number__c = '9198'];
        List<ServiceResource> serviceResource = [select id, Vehicle__c, Vehicle__r.name, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        Vehicle_Type__c vtype = new Vehicle_Type__c(Name='Light_Service');
        insert vtype;
        Schema.Location loc = new Schema.Location(Name='Light_Service',
                                                  IsInventoryLocation=true,
                                                  IsMobile=true,
                                                  Vehicle_Type__c='Light_Service',
                                                  Facility_Number__c='9198',
                                                  Facility__c= st.id,
                                                 VehicleType__c = vtype.Id);
        insert loc; 
        Schema.Location location = [select id, VehicleType__c from Location where name='Light_Service'];
        
        ProfileSkill pskill = new ProfileSkill(name='Light_Service',Developer_Name__c='Light_Service');
        insert pskill;
        Skill sk = new Skill(developerName='Light_Service');
        //insert sk;
                
        Vehicle_Skill__c vs = new Vehicle_Skill__c();
        vs.Skill_Level__c =2;
        vs.Skill__c = pskill.id;
        vs.Vehicle_Type__c = vtype.id;
        insert vs;
        
        Map<Id, ServiceResource> oldMap = new Map<Id, ServiceResource>();
        oldMap.put(serviceResource[0].Id, serviceResource[0]);
        
        serviceResource[0].Vehicle__c = location.Id;
        Map<Id, ServiceResource> newMap = new Map<Id, ServiceResource>();
        newMap.put(serviceResource[0].Id, serviceResource[0]);
        
        
        
        List<ServiceResourceSkill> serResSkill_BeforeUpdate = [select Id from ServiceResourceSkill where serviceResourceId = :serviceResource[0].Id];
        system.debug('serResSkill_BeforeUpdate 64 ' + serResSkill_BeforeUpdate);
        
        FSL_VehicleSkills.manipulateSkills(oldMap, newMap, 'insert');
        FSL_VehicleSkills.assignVehicleSkills(serviceResource);

        
        ProfileSkill pskill1 = new ProfileSkill(name='test1');
        insert pskill1;
        
        Vehicle_Type__c vtype1 = new Vehicle_Type__c(Name=location.VehicleType__c);
        insert vtype1;
        
        Vehicle_Skill__c vs1 = new Vehicle_Skill__c();
        vs1.Skill_Level__c =2;
        vs1.Skill__c = pskill1.id;
        vs1.Vehicle_Type__c = vtype1.id;
        insert vs1;

        
        List<ServiceResourceSkill> serResSkill_AfterUpdate = [select Id from ServiceResourceSkill where serviceResourceId = :serviceResource[0].Id];
        serResSkill_AfterUpdate[0].Skill_Type__c = 'Vehicle-Dependent';
        update serResSkill_AfterUpdate[0];
        update serviceResource;
        FSL_VehicleSkills.assignVehicleSkills(serviceResource);
        //System.assert(serResSkill_BeforeUpdate.size() <= serResSkill_AfterUpdate.size(),'Unable to update the Service Resource Skill record');
        System.Test.stopTest();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
}