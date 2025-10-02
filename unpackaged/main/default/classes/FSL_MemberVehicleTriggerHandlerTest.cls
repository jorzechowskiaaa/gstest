/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 11-09-2021
 * @last modified by  : Clement Shiu
**/
@isTest
Public class FSL_MemberVehicleTriggerHandlerTest{
    Static testmethod void CreateMembervehicle(){
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        List<WorkOrder>wolist =[select id from Workorder LIMIT 1];
        List<FSL_Member_Vehicle__c> memberlist = FSL_DataFactory.createMemberVehicle(wolist[0].id);
  
        memberlist [0].Vehicle_Model__c ='test';
        update memberlist [0];    
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
}