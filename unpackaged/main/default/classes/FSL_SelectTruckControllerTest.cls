@isTest
public class FSL_SelectTruckControllerTest {
    
    static testmethod void getPickListValuesIntoListTest(){
        System.Test.StartTest(); 
        
        List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias='T_Fleet' LIMIT 1];
        system.debug('----listsize----------'+userList.size());
        
        System.runAs(userList[0]){
            list<ServiceTerritory> sts = [select id, Facility_Number__c from ServiceTerritory ]; 
            
            system.debug('SR *****************serter'+sts.size());
            List<ServiceResource> ServiceResources = [select id,Primary_Facility_Id__c,ResourceType from ServiceResource where RelatedRecordId = :userList[0].id];
            ServiceResources[0].Primary_Facility_Id__c = sts[0].Id;
            ServiceResources[0].ResourceType = 'T';
            update ServiceResources[0];
            
            List<Schema.Location> location = [select id from Location LIMIT 1];
            system.debug('-----locationlist---------'+location.size());
            location[0].Facility__c = sts[0].Id;
            location[0].in_Use__c = false;
            update location;
        
           
            FSL_SelectTruckController.getPickListValuesIntoList(userlist[0].id);            
        }
        System.Test.stopTest();
    }
        
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   
    
}