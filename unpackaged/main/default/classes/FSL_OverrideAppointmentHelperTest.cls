@isTest
public class FSL_OverrideAppointmentHelperTest{
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    static testmethod void OverriderAppointment(){
        Test.startTest();
          FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        list<ServiceAppointment> salist = [select id from ServiceAppointment];
        PageReference pageRef = Page.FSL_OverrideAppointment; // Add your VF page Name here
        pageRef.getParameters().put('id', salist[0].Id);
        Test.setCurrentPage(pageRef); 
        
        ApexPages.StandardController sc = new ApexPages.StandardController(salist[0]);
        FSL_OverrideAppointmentHelper ovh = new FSL_OverrideAppointmentHelper();
        ovh.save();
        Test.stopTest();
    }
    
}