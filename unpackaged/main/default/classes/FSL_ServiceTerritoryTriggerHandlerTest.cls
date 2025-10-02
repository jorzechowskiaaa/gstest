/**
* @File Name          : FSL_ServiceTerritoryTriggerHandlerTest.cls
* @Description        : 
* @Author             : venkat Makireddy
* @Group              : 
* @Last Modified By   : venkat Makireddy
* @Last Modified On   : 
* @Modification Log   : 
* Ver       Date            Author              Modification
* 1.0         venkat Makireddy     Initial Version
**/
@isTest
Public class FSL_ServiceTerritoryTriggerHandlerTest {
   @isTest
    static void validateTest(){
        try
        {
            ServiceTerritory svt=[select id from ServiceTerritory where Name='Orlando' limit 1];
            
            ServiceTerritory svt1=[select id from ServiceTerritory where Name='Miami' limit 1];
            svt1.ParentTerritoryId=null;
            update svt1;
            ServiceTerritory svt2=[select id from ServiceTerritory where Name='Florida' limit 1];
            svt1.ParentTerritoryId=svt2.id;
            update svt1;
            svt2.ParentTerritoryId=null;
            update svt2;
            svt2.ParentTerritoryId=svt2.id;
            update svt2;
            Set<Id> svtlist=new Set<Id>();
            List<ServiceTerritory> sterrlist = new List<ServiceTerritory>{svt, svt1, svt2}; 
            svtlist.add(svt.Id);
            svtlist.add(svt1.Id);
            svtlist.add(svt2.Id);
            
            Set<Id> parentsvtlist=new Set<Id>(); 
            parentsvtlist.add(svt1.Id);
            parentsvtlist.add(svt2.Id);
            Map<Id,Id> faciltymap=new Map<Id,Id>();
            faciltymap.put(svt1.Id,svt1.ParentTerritoryId);
            faciltymap.put(svt2.Id,svt2.ParentTerritoryId);
            Test.startTest();
            //FSL_ServiceTerritoryTriggerHandler sc=new FSL_ServiceTerritoryTriggerHandler();
            
            FSL_ServiceTerritoryTriggerHandler.createNewSTMs(sterrlist, svtlist);
            FSL_ServiceTerritoryTriggerHandler.deleteOldSecondarySTMs(svtlist,parentsvtlist,faciltymap);
            
            Test.stopTest();
        }
        catch(Exception e)
        {
            system.debug(e);
            
        }
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    } 
}