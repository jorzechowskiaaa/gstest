@isTest
public with sharing class ACA_CallIntakeUtilityTest {
    @isTest
    public static void testMemberLevel(){
        string level = ACA_CallIntakeUtility.getMembershipLevel('BASIC');
        system.assertEquals(level,'Basic');
        level = ACA_CallIntakeUtility.getMembershipLevel('PREMIER');
        system.assertEquals(level,'Premier');
        level = ACA_CallIntakeUtility.getMembershipLevel('PREMIERRV');
        system.assertEquals(level,'Premier RV');
        level = ACA_CallIntakeUtility.getMembershipLevel('PLUSRV');
        system.assertEquals(level,'Plus RV');
        level = ACA_CallIntakeUtility.getMembershipLevel('PLUS');
        system.assertEquals(level,'Plus');
        level = ACA_CallIntakeUtility.getMembershipLevel('PLUSEXS');
        system.assertEquals(level,'Basic');
    }
}