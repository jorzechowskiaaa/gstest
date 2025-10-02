@isTest
public class FSL_ShiftTriggerHandlerTest {
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    public Static testmethod void ShiftTriggerTest(){
        Test.startTest();
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 2];
        
        ServiceTerritory st = [select id from ServiceTerritory limit 1];
        
        list<Shift> shifts = new list<Shift>();
        for(ServiceResource sr : [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' AND Primary_Service_Territory__c =: st.id  limit 2]){
            Shift sh =new Shift();
            sh.ServiceTerritoryId = st.Id;
            sh.StartTime =System.now();
            sh.Status ='Tentative';
            sh.TimeSlotType ='Normal';
            sh.EndTime = System.now()+1;
            sh.ServiceresourceId = sr.id;
            shifts.add(sh);
        }      
        insert shifts;
        system.assertEquals(1, shifts.size());
        
        shifts[0].ServiceTerritoryId = null;
        shifts[0].StartTime =System.now().addMinutes(30);
        update shifts;

        Test.stopTest();
    }
}