@isTest
public class getAAALocationsTest {
 
     @testSetup
    public static void testSetup(){
        List<Account> accountLst = new List<Account>();
        List<AAA_Location__c> AAALocationLst = new List<AAA_Location__c>();
		Id repairShopAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_AAR').getRecordTypeId();
        Account acc = new Account(name = 'TestAccount',BillingLatitude = 35.91, BillingLongitude = -79.47,billingstreet = '2100 Woodward Ave',
                                 billingcity = 'Detroit',RecordtypeId = repairShopAccountRecordTypeId,type='AAR');
        accountLst.add(acc);
        Account acc1 = new Account(name = 'TestAccount1',BillingLatitude = 35.92, BillingLongitude = -79.47,billingstreet = '211 Woodward Ave',
                                 billingcity = 'New York',RecordtypeId = repairShopAccountRecordTypeId,type='AAR');
        accountLst.add(acc1);
        Account acc2 = new Account(name = 'TestAccount2',BillingLatitude = 35.91, BillingLongitude = -79.48,billingstreet = '210 Woodward Ave',
                                 billingcity = 'Chicago',RecordtypeId = repairShopAccountRecordTypeId,type='AAR',Vehicle_Make__c='ALFA ROMEO');
        accountLst.add(acc2);
        insert accountLst;
        AAA_Location__c aaa = new AAA_Location__c(name = 'TestAAA',Geocode__Latitude__s = 35.91,Geocode__Longitude__s = -79.47);
        AAALocationLst.add(aaa);
        AAA_Location__c aaa1 = new AAA_Location__c(name = 'TestAAA1',Geocode__Latitude__s = 35.92,Geocode__Longitude__s = -79.47);
        AAALocationLst.add(aaa1);
        AAA_Location__c aaa2 = new AAA_Location__c(name = 'TestAAA2',Geocode__Latitude__s = 35.91,Geocode__Longitude__s = -79.48);
        AAALocationLst.add(aaa2);
        insert AAALocationLst;
    }
    
    @isTest
    public static void tow_TEST(){
        getAAALocations.getAccounts(35.91,-79.47,'OTHER');
        System.assertEquals(3, getAAALocations.getAccounts(35.91,-79.47,'OTHER').size(),'Number of locations returned is not 3');
    }
    @isTest
    public static void tow_VehicleMakeTest(){
        getAAALocations.getAccounts(35.91,-79.47,'ALFA ROMEO');
        System.assertEquals(1, getAAALocations.getAccounts(35.91,-79.47,'ALFA ROMEO').size(),'Number of locations returned is not 1');
    }
}