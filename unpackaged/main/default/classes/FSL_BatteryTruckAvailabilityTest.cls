/**
* @File Name : FSL_BatteryTruckAvailabilityTest.cls
* @Description :
* @Author : Rajesh Kemisetti
* @Group :
* @Last Modified By : Rajesh Kemisetti
* @Last Modified On : 6/12/2020, 3:59:03 PM
* @Modification Log :
* Ver Date Author Modification
* 1.0 6/4/2020 Rajesh Kemisetti Initial Version
**/
@isTest
public class FSL_BatteryTruckAvailabilityTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    
    public static testmethod void testCheckTruckAvailability()
    {
        
        List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
        
        List<User> userlist= [Select id from user where alias = 'C_Admin'];
        
        ServiceResource sr = [select id from ServiceResource where ResourceType ='T' LIMIT 1];
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1];
        List<ServiceTerritoryMember> newSTMList = new List<ServiceTerritoryMember>();
        ServiceTerritoryMember serTerMem = FSL_DataFactory.createServiceTerritoryMember(sr.Id, serterlist[0].Id);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String json1 = '{ "transactionID" : "1111112222", "locationLatitude" : "28.68441", "locationLongitude" : "-81.32394", "skills":["Battery_Capable","Battery_Replacement"] }';
        
        req.requestURI = '/services/apexrest/facility/battery/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(json1);
        
        RestContext.request = req;
        RestContext.response= res;
        
        FSL_BatteryTruckAvailability.FSL_TruckAvailabilityResponse avilableRes=FSL_BatteryTruckAvailability.checkTruckAvailability();
        system.assertEquals(avilableRes.statuscode,'200');
        system.assertEquals(avilableRes.availability,'No');
        
    }
}