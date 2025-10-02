@isTest
public class BSPAvailabilityTest {
    
   @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
     
  @isTest
  public static void BatteryTrucktest(){
        List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
        List<ServiceResource> serviceResource = [select id, Vehicle__c, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T'];
        List<ServiceTerritoryMember> serTerMem = [select TerritoryType from ServiceTerritoryMember where TerritoryType='P' ]; 
        List<Skill> lstskl = [select id,DeveloperName from Skill WHERE DeveloperName = 'Battery_Replacement'];
		system.assertEquals(1, lstskl.size());
		for(ServiceTerritoryMember stm : serTerMem){
            stm.operatingHoursId = OperatingHours[0].Id;
      }
      
        update serTerMem;
        list<string> lstsk = new List<String>();
        lstsk.add(lstskl[0].DeveloperName);
        ServiceTerritory st =new ServiceTerritory();
        List<TimeSlot> TimeSlots = FSL_DataFactory.createTimeSlots();
        
        List<Shift> shiftlist = new List<Shift>();
        Shift sh = new Shift();
        sh.ServiceTerritoryId = st.id;
        sh.ServiceresourceId = serviceResource[0].id;
        sh.StartTime =System.now();
        sh.Status ='Confirmed';
        sh.TimeSlotType ='Normal';
        sh.EndTime = System.now()+1;
        shiftlist.add(sh);
        insert shiftlist;

       
        
      List<ServiceResourceSkill> srskSkill = new List<ServiceResourceSkill>();
      for(ServiceResource sr : serviceResource){
        ServiceResourceSkill srsk = new ServiceResourceSkill();
        srsk.Skill_Type__c = 'Vehicle-Dependent	';
        srsk.SkillLevel = 2;
        srsk.EffectiveStartDate = System.now();
        srsk.ServiceResourceId = sr.id;
        srsk.SkillId = lstskl[0].Id;
        srskSkill.add(srsk);  
      }
      upsert srskSkill;
        
       
      Double lat = 28.68441;
      Double lng = -81.32394;
        BSPAvailability.bspAvailabilityCheck(lat,lng);
             
        
    }
}