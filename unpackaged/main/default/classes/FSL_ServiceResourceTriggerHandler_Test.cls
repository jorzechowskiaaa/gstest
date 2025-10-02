/**
* @File Name          : FSL_ServiceResourceTriggerHandler_Test.cls
* @Description        : 
* @Author             : Rajesh Kemisetti
* @Group              : 
* @Last Modified By   : Rajesh Kemisetti
* @Last Modified On   : 4/6/2020, 3:02:34 PM
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    4/6/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
private class FSL_ServiceResourceTriggerHandler_Test {
    static User user;
    static Map<Id, ServiceResource> newSRMap = new Map<Id, ServiceResource>();
    
    @isTest
    static void updateGanttLabelTest(){
        Test.startTest();        

        ServiceResource serviceResource = [select id, Vehicle__c, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];

        newSRMap.put(serviceResource.Id, serviceResource);        
        FSL_ServiceResourceTriggerHandler.updateGanttLabel(newSRMap);
        
        serviceResource.Vehicle__c = null;
        update serviceResource;

        newSRMap.put(serviceResource.Id, serviceResource);        
        FSL_ServiceResourceTriggerHandler.updateGanttLabel(newSRMap);
        
        Test.stopTest();        
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   
}