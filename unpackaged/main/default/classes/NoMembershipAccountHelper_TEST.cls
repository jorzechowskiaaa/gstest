@IsTest
private class NoMembershipAccountHelper_TEST {

    @IsTest
    static void testGetNoMembershipValue() {
        String value = NoMembershipAccountHelper.getNoMembershipValue();
        Assert.areEqual(NoMembershipAccountHelper.DUMMY_MEMBERSHIP, value, 'Expected dummy membership string');
    }
    
    @IsTest
    static void testClearNoMembershipStatus() {
        Account acct = new Account();
        acct.Membership_Number__c = '123456';
        NoMembershipAccountHelper.clearNoMembershipStatus(acct);
        Assert.isNull(acct.Membership_Number__c, 'Expected membership number to be set to null');
    }
    
    @IsTest
    static void testSetNoMembershipStatus() {
        Account acct = new Account();
        acct.Membership_Number__c = '123456';
        NoMembershipAccountHelper.setNoMembershipStatus(acct);
        Assert.areEqual(NoMembershipAccountHelper.DUMMY_MEMBERSHIP, acct.Membership_Number__c, 'Expected dummy membership string');
    }
    
}