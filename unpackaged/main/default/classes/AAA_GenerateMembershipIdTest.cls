@isTest
public with sharing class AAA_GenerateMembershipIdTest {
    @isTest
    static void populateMemberInfoTest() {
        // ISO Clb Member# Assoc# CheckCode
        // 438 212 0641567  00      9
        Test.startTest();
        String checkDigit     = AAA_GenerateMembershipId.calculateCheckCode('438212064156700');
        String checkMemberAll = AAA_GenerateMembershipId.genMembershipIdMain('212064156700');
        String checkMember7a  = AAA_GenerateMembershipId.processSevenDigit('0641567'); 
        String checkMember7b  = AAA_GenerateMembershipId.genMembershipIdMain('0641567');
        String checkExtract2  = AAA_GenerateMembershipId.extractLastTwoDigits('240284248200');
        String checkExtract9  = AAA_GenerateMembershipId.genMembershipIdMain('064156700');
        Test.stopTest();
            
        System.assertEquals(checkDigit,     '9',                'Check digit not calculated correctly');
        System.assertEquals(checkMemberAll, '4382120641567009', 'Twelve Member Processing: Id not calculated correctly');
        System.assertEquals(checkMember7a,  '438212064156700',  'Seven Digit Processing: Member Id not calculated correctly');
        System.assertEquals(checkMember7b,  '4382120641567009', 'Seven Digit Processing 2: Member Id not calculated correctly');
        System.assertEquals(checkExtract2,  '00',               'Extract Last Two Digits: not calculated correctly'); 
        System.assertEquals(checkExtract9,  '4382120641567009', 'Nine Digit Processing: Member Id not calculated correctly'); 
    }

    public static List<AAA_ISO_Code__mdt> mockISOCodeMdt() {
        return new List<AAA_ISO_Code__mdt>{
            new AAA_ISO_Code__mdt(
                ISO_Code__c = '438'
            )
        };
    }

    public static String mockClubCode() {
        return '212';
    }
}