/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 * *        06/21/2021   Dylan Truong         ERS-223791 - Create Platform Events for LKL upsertResourceAbsence failure: create configuration settings.
 */

@isTest
public with sharing class FSL_FeatureFlagTest {

    @IsTest
    static void testGetFeatureFlagByName(){
        FSL_FeatureFlag.IFeatureFlagService featureService = (new FSL_FeatureFlag.Factory()).createService();
        string labelName = 'Resource Absence Platform Feature';
        Test.startTest();
        List<FSL_Feature_Flag__mdt> features = featureService.getFeatureFlagByName(labelName);
        System.debug('Test ==> ' + features);
        System.assertEquals(true, features.size()>0);
        Test.stopTest();
        
    }

    @IsTest
    static void testGetFeatureFlags(){
        FSL_FeatureFlag.IFeatureFlagService featureService = (new FSL_FeatureFlag.Factory()).createService();
        Test.startTest();
        List<FSL_Feature_Flag__mdt> features = featureService.getFeatureFlags();
        System.assertEquals(true, features.size()>0);
        Test.stopTest();
        
    }
}