/****
 * *@Name: ServiceAppointment
 * *@Description: when the workorder is created Update the ServiceAppointment Address,lat,lag etc.. from WorkOrder. *  * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0                 Vincent               Initial Version
 *  *     04/20/2021   Dylan Truong         UpdateSertMetaData
 ***/


@isTest
public with sharing class FSL_MetaDataUtilityTest {
    @isTest
    public static void testUpsertMetadata() {

        List<FSL_Gantt_Icon__mdt> ganttIcons = new List<FSL_Gantt_Icon__mdt>();
        ganttIcons.add(new FSL_Gantt_Icon__mdt(MasterLabel='Demo 1', DeveloperName='Demo1', Icon_Type__c = 'Demo1 Rap', Image_Name__c = 'Demo Image Rap 1'));
        Test.startTest();
        Id JobId = FSL_MetaDataUtility.upsertMetadata(ganttIcons);
        System.debug('Testing ==> ' + JobId);
        Test.stopTest();
        // Asserts
    }
    @isTest
    public static void testCreateMetaDataDeployContainer() {

        List<FSL_Gantt_Icon__mdt> ganttIcons = new List<FSL_Gantt_Icon__mdt>();
        ganttIcons.add(new FSL_Gantt_Icon__mdt(MasterLabel='Demo 1', DeveloperName='Demo1', Icon_Type__c = 'Demo1 Rap', Image_Name__c = 'Demo Image Rap 1'));
        Test.startTest();
        Metadata.DeployContainer mdContainer = FSL_MetaDataUtility.createMetaDataDeployContainer(ganttIcons);
        List<Metadata.Metadata> contents = mdContainer.getMetadata();
        System.debug('Testing ==> ' + contents);
        System.assertEquals(1, contents.size());
        Test.stopTest();
        // Asserts
    }
  

}