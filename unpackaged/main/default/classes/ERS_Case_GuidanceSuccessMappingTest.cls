@isTest
public class ERS_Case_GuidanceSuccessMappingTest {
    //@testSetup
    public static void testSetup(){
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case();
        caseRec.RecordTypeId = ERS_RecTypeId;
        caseRec.ACG_Service_Type__c = 'Fuel';
        caseRec.Vehicle_Fuel_Type__c = 'Gas';
        caseRec.Subject = '@Test GuidanceSuccess Rec#';
        insert caseRec;
    }
    @isTest
    public static void getGuidanceTest_DefaultMsg(){
        String CurrentTab = 'Tow';
        List<ERS_Case_Guidance_Success_Mapping__mdt> mdtList = [SELECT  Case_Guidance_Success_Status__c,
                                                                        Guidance_Success__c,
                                                                        Name_of_Triage_Tab__c
                                                                FROM ERS_Case_Guidance_Success_Mapping__mdt
                                                                WHERE Name_of_Triage_Tab__c =:CurrentTab
                                                                AND Case_Guidance_Success_Status__c = 'Active'
                                                               LIMIT 1];
         List<String> GS_MSgs = ERS_Case_GuidanceSuccessMapping.getGuidance(NULL, NULL,NULL,NULL,NULL, NULL, CurrentTab, NULL, NULL);
        
        if( !mdtList.isEmpty() && !GS_MSgs.isEmpty()){
            system.assertEquals(true,GS_MSgs.contains(mdtList[0].Guidance_Success__c), 'Error getting the GS message;;;'+GS_MSgs+';;;'+mdtList[0].Guidance_Success__c);
        }
    }
    @isTest
    public static void getGuidanceTest(){
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case();
        caseRec.RecordTypeId = ERS_RecTypeId;
        caseRec.ACG_Service_Type__c = 'Fuel';
        caseRec.Vehicle_Fuel_Type__c = 'Gas';
        caseRec.Subject = '@Test GuidanceSuccess Rec#';
        insert caseRec;
        System.debug(caseRec);
        
        String CurrentTab = 'Fuel';
        List<ERS_Case_Guidance_Success_Mapping__mdt> mdtList = [SELECT  Case_Guidance_Success_Status__c,
                                                                        Guidance_Success__c,
                                                                        Service_Type__c,
                                                                        Vehicle_Fuel_Type__c,
                                                                        Name_of_Triage_Tab__c
                                                                FROM ERS_Case_Guidance_Success_Mapping__mdt
                                                                WHERE Name_of_Triage_Tab__c =:CurrentTab
                                                                    AND Case_Guidance_Success_Status__c = 'Active'
                                                                    AND Service_Type__c = 'Fuel'
                                                                    AND Vehicle_Fuel_Type__c = 'Gas'
                                                                LIMIT 1];
        
        //Case caseRec = [SELECT Id,ACG_Service_Type__c,Vehicle_Fuel_Type__c FROM Case WHERE Subject='@Test GuidanceSuccess Rec#' LIMIT 1];
                                                                            //String ServType, Id AccountId, String FuelType, String VehicleType,String BSPAvailable, String FlatTireStatus,String CurrentTab)
        List<String> GS_MSgs = ERS_Case_GuidanceSuccessMapping.getGuidance(caseRec.ACG_Service_Type__c, NULL,caseRec.Vehicle_Fuel_Type__c,NULL,NULL, NULL, CurrentTab, NULL, NULL);
        if( !mdtList.isEmpty() && !GS_MSgs.isEmpty()){
            system.assertEquals(true,GS_MSgs.contains(mdtList[0].Guidance_Success__c), 'Error getting the GS message');
        }
    }
    
    @isTest
    public static void parseGuidanceMessage_Test(){
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case();
        caseRec.RecordTypeId = ERS_RecTypeId;
        caseRec.ACG_Service_Type__c = 'Tow';
        caseRec.Allotted_Mileage__c = 50;
        caseRec.Subject = '#Test ERSCase Rec#';
        insert caseRec;
        
        ERS_Case_Guidance_Success_Mapping__mdt mdtRec = [SELECT Id,Guidance_Success__c,DeveloperName FROM ERS_Case_Guidance_Success_Mapping__mdt WHERE DeveloperName = 'BR_Tow_Tab_3' LIMIT 1];
        String parsedMsg ;

        Test.startTest();
        //Test Scenario 1 (towMiles > Allotted Mileage)
        parsedMsg = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage('Test_Membership_Level','75', caseRec.Id, mdtRec);
        String expectedMsg = mdtRec.Guidance_Success__c;
        expectedMsg = expectedMsg.replace('{Membership_Level__c}','Test_Membership_Level');
        expectedMsg = expectedMsg.replace('{Allotted_Mileage__c}','25');
        expectedMsg = expectedMsg.replace('{Over_Miles__c}','25');
        expectedMsg = expectedMsg.replace('{Total_Mileage__c}','25');

        System.assertEquals(expectedMsg, parsedMsg, 'ERROR');

        //Test Scenario 2 (towMiles < Allotted Mileage)
        parsedMsg = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage('Test_Membership_Level','25', caseRec.Id, mdtRec);
        expectedMsg = '<p style="color:red">You are using '+'25'+' miles out of your allotted '+'50'+' miles.</p>';
        System.assertEquals(expectedMsg, parsedMsg, 'ERROR');

        Test.stopTest();

        //Test Scenario 3 (towMiles = 0 / NULL)
        parsedMsg = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage('Test_Membership_Level','0', caseRec.Id, mdtRec);
        System.assertEquals(NULL, parsedMsg, 'ERROR');
        
        parsedMsg = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage('Test_Membership_Level',NULL, caseRec.Id, mdtRec);
        System.assertEquals(NULL, parsedMsg, 'ERROR');
        
        //Test Scenario 4 (Allotted Mileage = NULL)
        caseRec.Allotted_Mileage__c = NULL;
        update caseRec;
        
        parsedMsg = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage('Test_Membership_Level','75', caseRec.Id, mdtRec);
        System.assertEquals(NULL,parsedMsg , 'ERROR');
    }
}