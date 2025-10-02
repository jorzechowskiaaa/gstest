@isTest
public with sharing class FSL_ConfigurationSettingTest {

    @IsTest
    static void testgetConfigurationSettingByName(){
        FSL_ConfigurationSetting.IConfigurationSettingService configSettingService = (new FSL_ConfigurationSetting.Factory()).createService();
        string labelName = 'Resource Absence Platform Event';
        Test.startTest();
        List<FSL_Configuration_Setting__mdt> configSettings = configSettingService.getConfigurationSettingByName(labelName);
        System.assertEquals(true, configSettings.size()>0);
        Test.stopTest();
        
    }

    @IsTest
    static void getConfigurationSettings(){
        FSL_ConfigurationSetting.IConfigurationSettingService configSettingService = (new FSL_ConfigurationSetting.Factory()).createService();
        Test.startTest();
        List<FSL_Configuration_Setting__mdt> configSettings = configSettingService.getConfigurationSettings();
        System.assertEquals(true, configSettings.size()>0);
        system.debug('ConfigSetting ==> ' + configSettings);
        Test.stopTest();
        
    }
}