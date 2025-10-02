/**
* @File Name          : FSL_LoginFlowTest.cls 
* @Description        : 
* @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
* @Group              : 
* @Last Modified By   : Rajesh Kemisetti
* @Last Modified On   : 4/24/2020, 5:51:18 PM
* @Modification Log   : 
* Ver       Date            Author              Modification
* 1.0    11/11/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
private with sharing class FSL_LoginFlowTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
        ServiceResource sr = [select id from ServiceResource where ResourceType ='T' LIMIT 1];
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1];
        List<ServiceTerritoryMember> newSTMList = new List<ServiceTerritoryMember>();
        ServiceTerritoryMember serTerMem = FSL_DataFactory.createServiceTerritoryMember(sr.Id, serterlist[0].Id);
        newSTMList.add(serTerMem); 
    }
    
    static testMethod void LoginFlow_rowcountTest() {
        ServiceResource serviceResource = [select id from serviceResource limit 1];
        ServiceTerritoryMember serTerMem = [select id,fsl_part_time__c from ServiceTerritoryMember where serviceresourceid = :serviceResource.id and territorytype='P' limit 1];
        list<string> srIds = new list<string>(); 
        srIds.add(serviceResource.id);
        
        Test.startTest();
        List<String> rowCount;
        
        rowCount = FSL_LoginFlowHelper.getRowCount(srIds);
        system.assertEquals(null, rowCount);
        
        serTerMem.fsl_part_time__c = TRUE;
        update serTerMem;
        
        rowCount = FSL_LoginFlowHelper.getRowCount(srIds);
        system.assertEquals(1, rowCount.size());        
        
        Test.stopTest();
    }
    
 /*   static testMethod void LoginFlow_updateSTMTest() {
        ServiceResource serviceResource = [select id from serviceResource limit 1];
        ServiceTerritoryMember serTerMem = [select id,fsl_part_time__c from ServiceTerritoryMember where serviceresourceid = :serviceResource.id and territorytype='S' limit 1];
        
        list<string> srIds = new list<string>(); 
        srIds.add(serviceResource.id);
        
        Test.startTest();
        
        FSL_FacilitySelectionHelper.updateServiceResourceTerritoryMembership(srIds);
        
        srIds.clear();
        srIds.add(serTerMem.id);
        
        try{
            FSL_FacilitySelectionHelper.updateServiceResourceTerritoryMembership(srIds);
        }catch(exception e){}
        Test.stopTest();        
    }    
*/
}