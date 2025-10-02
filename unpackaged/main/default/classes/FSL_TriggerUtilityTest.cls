@IsTest
private class FSL_TriggerUtilityTest {

    private static final String SKIP_PERMISSION_SET = 'Skip_Automation_Logic';
    private static final String SKIP_USERNAME = 'skipuser@test.aaa.com';
    private static final String NO_SKIP_USERNAME = 'noskipuser@test.aaa.com';
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        PermissionSet ps = [SELECT Id,Name FROM PermissionSet WHERE Name=:SKIP_PERMISSION_SET LIMIT 1];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
        	User u1 = new User(
                Alias = 'standu1',
                Email=SKIP_USERNAME,
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName=SKIP_USERNAME
            );
            insert u1;
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = ps.Id,
                AssigneeId = u1.Id
            );
            insert psa;
        	User u2 = new User(
                Alias = 'standu1',
                Email=NO_SKIP_USERNAME,
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName=NO_SKIP_USERNAME
            );
            insert u2;        
        }
        
        Execute_Trigger__c ec = new Execute_Trigger__c();
        ec.Name = 'TestClass2';
        ec.Disabled__c = true;
        insert ec;
        
    }
    
    @IsTest
    static void testIsDisabled() {
        // get skip user
        User skipuser = [SELECT Id,Username FROM User WHERE Email = :SKIP_USERNAME LIMIT 1];
        Boolean skipuserResult;
        System.debug(skipuser);
        
        // get no skip user
        User noskipuser = [SELECT Id,Username FROM User WHERE Email = :NO_SKIP_USERNAME LIMIT 1];
        Boolean noskipuserResult1;
        Boolean noskipuserResult2;
        System.debug(noskipuser);
        
        Test.startTest();
        System.runAs(skipuser) {
            skipuserResult = FSL_TriggerUtility.isDisabled('TestClass1');
		}
        System.runAs(noskipuser) {
            noskipuserResult1 = FSL_TriggerUtility.isDisabled('TestClass1');
            noskipuserResult2 = FSL_TriggerUtility.isDisabled('TestClass2');
        }
        Test.stopTest();
        
        Assert.isTrue(skipuserResult, 'Expected skip for Skip User');
        Assert.isFalse(noskipuserResult1, 'Expected no skip for No Skip User with TestClass1');
        Assert.isTrue(noskipuserResult2, 'Expected skip for No Skip User with TestClass2');
    }
    
    private static final String BOGUS_STATUS = 'Bogus';
    private static final String CLEARED_STATUS = 'Cleared';
    private static final String SPOTTED_STATUS = 'Spotted';
    private static final String IN_PROGRESS_STATUS = 'In Progress';
    private static final String CUSTOM_FROM_STATUS = 'CustomFrom';
    private static final String CUSTOM_TO_STATUS = 'CustomTo';
    
    @IsTest
    static void testIsStatusTransitionAllowed() {
        // setup StatusTransition list
        List<FSL.StatusTransition> sts = new List<FSL.StatusTransition>();
        sts.add(new FSL.StatusTransition(CUSTOM_FROM_STATUS, CUSTOM_TO_STATUS));
        
        Test.startTest();
        Boolean bogusResult = FSL_TriggerUtility.isStatusTransitionAllowed(BOGUS_STATUS, BOGUS_STATUS, sts);
        Boolean clearedResult = FSL_TriggerUtility.isStatusTransitionAllowed(CLEARED_STATUS, BOGUS_STATUS, sts);
        Boolean spottedResult = FSL_TriggerUtility.isStatusTransitionAllowed(BOGUS_STATUS, SPOTTED_STATUS, sts);
        Boolean fromInProgressResult = FSL_TriggerUtility.isStatusTransitionAllowed(IN_PROGRESS_STATUS, BOGUS_STATUS, sts);
        Boolean toInProgressResult = FSL_TriggerUtility.isStatusTransitionAllowed(BOGUS_STATUS, IN_PROGRESS_STATUS, sts);
        Boolean customNotMatchingResult = FSL_TriggerUtility.isStatusTransitionAllowed(BOGUS_STATUS, CUSTOM_TO_STATUS, sts);
        Boolean customMatchingResult = FSL_TriggerUtility.isStatusTransitionAllowed(CUSTOM_FROM_STATUS, CUSTOM_TO_STATUS, sts);
        Test.stopTest();
        
        Assert.isFalse(bogusResult, 'Expected not allowed with bogus status values');
        Assert.isFalse(clearedResult, 'Expected not allowed with clear status value');
        Assert.isTrue(spottedResult, 'Expected allowed with spotted status value');
        Assert.isTrue(fromInProgressResult, 'Expected allowed with from in progress status value');
        Assert.isTrue(toInProgressResult, 'Expected allowed with to in progress status value');
        Assert.isFalse(customNotMatchingResult, 'Expected not allowed when either status not matching custom FSL.StatusTransition');
        Assert.isTrue(customMatchingResult, 'Expected allowed when both status matching custom FSL.StatusTransition');
        
    }
    
    private class TestClass1 {}
    private class TestClass2 {}
    
    
    
}