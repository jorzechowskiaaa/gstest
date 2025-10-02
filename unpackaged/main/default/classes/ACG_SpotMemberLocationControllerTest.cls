/************************************************************************************
Apex Class Name     : ACG_SpotMemberLocationControllerTest
Created Date        : 3rd Aug 2021
Function            : Test Class for ACG_SpotMemberLocationController. 
Author              : Deloitte Consulting 
*************************************************************************************/
@isTest 
public class ACG_SpotMemberLocationControllerTest {
    //loads the test data
    @testSetup static void testDataSetup() {
        Id RecordtypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        List<Case> lstCase = new List<Case>();
        lstCase.add(ACG_TestDataFactory.createcase(RecordtypeId,'New','Phone',true));
        ACG_CaseTriggerService.generateEncryptedId(lstCase);
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'BING_API_GEOCODE', 
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=', API_Key__c ='AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc',
            Request_Timeout__c=120000
            
        ));           
        insert lstIntegrationSetting;
    }
    
    //tests the update case and fetch case methods
    @IsTest
    static void updateCaseTestWithZip(){  
        case objCS = [select id,Encrypted_Case_Id__c from case limit 1];
        String res2 = '{"resourceSets":[{"resources":[{"timeZone":{"windowsTimeZoneId":"Pacific Standard Time","utcOffset":"-8:00","ianaTimeZoneId":"America/Los_Angeles","genericName":"Pacific Standard Time","convertedTime":{"utcOffsetWithDst":"-7:00","timeZoneDisplayName":"Pacific Daylight Time","timeZoneDisplayAbbr":"PDT","localTime":"2023-09-07T08:41:17"},"abbreviation":"PST"},"point":{"coordinates":[37.072445,-120.075726]},"name":"22322 Road 26, Madera, CA 93638, United States","geocodePoints":[{"type":"Point","coordinates":[37.072445,-120.075726]}],"entityType":"Address","address":{"postalCode":"93638","locality":"Madera","landmark":null,"formattedAddress":"22322 Road 26, Madera, CA 93638, United States","countryRegion":"United States","adminDistrict2":"Madera Co.","adminDistrict":"CA","addressLine":"22322 Road 26"}}]}]}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res2, 200));
        
        Test.startTest();
        ACG_SpotMemberLocationController.fetchcase(objCS.Encrypted_Case_Id__c);
        string result = ACG_SpotMemberLocationController.updateCasedetails(12.3444,76.1333,'4 Columbine,US','4 Columbine','Irvine','US','Texas','92604',objCS.Encrypted_Case_Id__c);
        system.debug('result'+result);
        Test.stopTest();
        system.assertEquals('Success', result);
    }
    @IsTest
    static void updateCaseTestWithoutZip(){  
        case objCS = [select id,Encrypted_Case_Id__c from case limit 1];
        String res2 = '{"resourceSets":[{"resources":[{"timeZone":{"windowsTimeZoneId":"Pacific Standard Time","utcOffset":"-8:00","ianaTimeZoneId":"America/Los_Angeles","genericName":"Pacific Standard Time","convertedTime":{"utcOffsetWithDst":"-7:00","timeZoneDisplayName":"Pacific Daylight Time","timeZoneDisplayAbbr":"PDT","localTime":"2023-09-07T08:41:17"},"abbreviation":"PST"},"point":{"coordinates":[37.072445,-120.075726]},"name":"22322 Road 26, Madera, CA 93638, United States","geocodePoints":[{"type":"Point","coordinates":[37.072445,-120.075726]}],"entityType":"Address","address":{"postalCode":"93638","locality":"Madera","landmark":null,"formattedAddress":"22322 Road 26, Madera, CA 93638, United States","countryRegion":"United States","adminDistrict2":"Madera Co.","adminDistrict":"CA","addressLine":"22322 Road 26"}}]}]}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res2, 200));
        
        Test.startTest();
        ACG_SpotMemberLocationController.fetchcase(objCS.Encrypted_Case_Id__c);
        string result = ACG_SpotMemberLocationController.updateCasedetails(12.3444,76.1333,'4 Columbine,US','4 Columbine','Irvine','US','Texas','',objCS.Encrypted_Case_Id__c);
        system.debug('result'+result);
        Test.stopTest();
        //system.assertEquals('Success', result);
    }
    
    @isTest
    static void getDecryptedIDTest(){
        Case cs = [select id,Encrypted_Case_Id__c from case limit 1];
        Test.startTest();
        String decryptedId = ACG_SpotMemberLocationController.getDecryptedID(cs.Encrypted_Case_Id__c);
        Test.stopTest();
        system.assertEquals(cs.Id, decryptedId, 'Decrypted Id does not match');
    }
}