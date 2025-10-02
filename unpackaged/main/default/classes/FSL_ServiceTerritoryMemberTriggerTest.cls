/**
 * @File Name          : FSL_ServiceTerritoryMemberTriggerTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/24/2020, 4:11:58 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/24/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_ServiceTerritoryMemberTriggerTest {
  
    static testMethod void serTerrMemTest(){  
        System.Test.StartTest();
        ServiceTerritoryMember serTerMem = [select TerritoryType from ServiceTerritoryMember where TerritoryType='P' limit 1]; 

        serTerMem.street = '';
        serTerMem.City = '';
        serTerMem.Country = '';
        serTerMem.State = '';
        serTerMem.PostalCode = '';
        serTerMem.Latitude = null;
        serTerMem.Longitude = null;        
        serTerMem.TerritoryType = 'S';
        update serTerMem;
        
        serTerMem.TerritoryType = 'P';
        update serTerMem;
        
        System.Test.StopTest();
    }    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
}