/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-01-2021
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-10-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public class FSL_AppointmentDependencyHelperTest {
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }

    static testMethod void addResourcePreferencesBasedOnPrefTypeTest(){
        delete [select id from Technology_Preference__c];
        Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        Test.stopTest();
        try{
            list<WorkOrder> wos = [select id,status, serviceterritoryid,(select service_resource__c from serviceappointments) from WorkOrder];
            //system.assertEquals('In Progress', wos[0].status);//EMI--commented for----SSFI-700
            //system.assertEquals('Spotted', wos[0].status); //EMI---SSFI-700
            list<ServiceTerritory> STs = [select id from ServiceTerritory];
            set<id> SRIDs = new set<ID>();
            SRIDs.add(wos[0].serviceappointments[0].service_resource__c);
            FSL_SchedulingUtility.addResourcePreferencesBasedOnPrefType(wos[0].id, 'Required', STs[1].id, SRIDs);          
        } catch (Exception e) {
                    System.debug('Exceptioning...'+e.getMessage());
        }            
        
    }
    
    static testMethod void isQualifyAddressTest(){
        Test.startTest();
    	FSL_DataFactory.createWOIntakeCall('FSL_TowCall');
        list<ServiceAppointment> SAs = [select id, street, city, state, postalcode from ServiceAppointment];
        Boolean testresult = FSL_AppointmentDependencyHelper.isQualifyAddress(SAs[0]);
        system.assertEquals(true, testresult);
        Test.stopTest();
    }

}