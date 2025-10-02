@isTest
public class ACG_GlobalSearchControllerSupportTest {
@isTest
    public static void doTest(){
        Account acct = new Account();
        acct.firstName = 'FTest';
        acct.LastName = 'LTest';
        acct.Phone = '4125551212';
        acct.PersonEmail = 'Test@test.com';
        acct.BillingStreet = '123 Test Street';
        acct.BillingCity = 'Pittsburgh';
        acct.BillingState = 'PA';
        acct.BillingPostalCode = '15317';
        acct.BillingCountry = 'United States';
        acct.Contact_Object_ID_MDM__c = '123213123'; 

        ACG_GlobalSearchControllerSupport.upsertCustomerRecord(acct);
    }
    @isTest
    public static void doTest2(){
        Account acct = new Account();
		acct = null;
        ACG_GlobalSearchControllerSupport.upsertCustomerRecord(acct);
    }
}