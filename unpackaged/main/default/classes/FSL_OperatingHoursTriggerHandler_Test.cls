@isTest
public class FSL_OperatingHoursTriggerHandler_Test {

    @TestSetup
    static void setupData(){
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    public static testMethod void updateOperatingHours(){
        System.Test.startTest();
		delete [select id from Override_Resource_Preference__c];
        delete [SELECT Id FROM ServiceTerritory];
        list<OperatingHours> OpHrs = [select id, name from OperatingHours];
        for(OperatingHours OpHr:OpHrs){
            OpHr.name = 'test';
        }
        try{
        	update OpHrs;
        }catch(exception e){
            system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        System.Test.stopTest();

    }
}