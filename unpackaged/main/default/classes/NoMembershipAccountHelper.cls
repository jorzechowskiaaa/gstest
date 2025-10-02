public without sharing class NoMembershipAccountHelper {

    public static string DUMMY_MEMBERSHIP = 'NEED MBR INFO';

    @AuraEnabled(cacheable=true)
    public static string getNoMembershipValue() {
        return DUMMY_MEMBERSHIP;
    }

    public static void clearNoMembershipStatus(Account acct) {
        acct.Membership_Number__c = null;
    }

    public static void setNoMembershipStatus(Account acct) {
        acct.Membership_Number__c = DUMMY_MEMBERSHIP;
    }
}