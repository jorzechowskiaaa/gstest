@isTest
public with sharing class NE_CallIntakeUtilityTest {
    @isTest
    public static void testMemberLevel(){
        string level = NE_CallIntakeUtility.getMembershipLevel('BASIC');
        system.assertEquals(level,'Basic');
        level = NE_CallIntakeUtility.getMembershipLevel('PREMIER');
        system.assertEquals(level,'Premier');
        level = NE_CallIntakeUtility.getMembershipLevel('PREMIER RV');
        system.assertEquals(level,'Premier RV');
        level = NE_CallIntakeUtility.getMembershipLevel('PLUS RV');
        system.assertEquals(level,'Plus RV');
        level = NE_CallIntakeUtility.getMembershipLevel('PLUS');
        system.assertEquals(level,'Plus');
        level = NE_CallIntakeUtility.getMembershipLevel('EVERYDAY');
        system.assertEquals(level,'Everyday');
        level = NE_CallIntakeUtility.getMembershipLevel('NON STANDARD MEMBERSHIP LEVEL');
        system.assertEquals(level,'Non Standard');
        level = NE_CallIntakeUtility.getMembershipLevel('PLUSEXS');
        system.assertEquals(level,'Basic');
    }
}