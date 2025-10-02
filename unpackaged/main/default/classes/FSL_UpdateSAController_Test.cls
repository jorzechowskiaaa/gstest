@isTest
public class FSL_UpdateSAController_Test {
    
    static testMethod void SAControllertest(){
        delete [select id from Technology_Preference__c];
        Test.starttest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');        
        Test.stopTest();
		
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        list<ServiceAppointment> SAs = [select id, SchedEndTime, status, Schedule_Delta__c, service_resource__c  from ServiceAppointment];        
        system.debug('**SAs: '+SAs);
        system.debug('**serviceresources: '+[select id, IsActive, Primary_Service_Territory__c from ServiceResource]);
        system.debug('**serviceTerritories: '+[select id,facility_number__c  from ServiceTerritory]);
        
        PageReference pageRef = Page.FSL_Extend_WorkType_Duration;
        pageRef.getParameters().put('id',SAs[0].id);
        Test.setCurrentPage(pageRef);   
        FSL_UpdateSAController cntlr = new FSL_UpdateSAController();
        cntlr.saUpdate.Schedule_Delta__c = 10;
        cntlr.saUpdate.Extend_Work_Time_Counter__c=null;
        cntlr.updateServiceAppointment();
    }
    
    @TestSetup
    static void testSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }    
    
}