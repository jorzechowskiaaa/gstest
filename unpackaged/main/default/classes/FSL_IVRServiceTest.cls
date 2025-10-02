/**
 * @File Name          : FSL_IVRServiceTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 6/4/2020, 12:01:54 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/4/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public with sharing class FSL_IVRServiceTest {
    
    @isTest
    public static void searchByMemberTest() {
        delete [select id from Technology_Preference__c];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_Required_ComplexCall');        
        Test.stopTest();
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/calls/searchByMemberId';
        request.httpMethod = 'POST';
        
        String payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a", "memberId": "1241114500308444"}';
        request.requestBody = Blob.valueOf(payload);
        RestContext.request = request;        
        List<FSL_ClearJsonWorkOrder> getcont1=FSL_IVRMemberId_v1.getContact();
        system.debug('####');
        system.debug(getcont1);
        DateTime ETA=getcont1[0].callEvents[0].statusDetail.eta;
        //system.assert(ETA!=null);
        String callid=getcont1[0].calls[0].callid;
        system.assertEquals(callid,'30000'); 
        
        payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a", "memberId": "1241114500308445"}';
        request.requestBody = Blob.valueOf(payload);
        List<FSL_ClearJsonWorkOrder> getcont2=FSL_IVRMemberId_v1.getContact();
        system.debug('####');
        system.debug(getcont2);
        
        String statusDescription=getcont2[0].statusDescription;
        system.assertEquals(statusDescription,'IVR_RESPONSE_Error::No member found with that 1241114500308445');
        
        payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a" "memberId": "1241114500308444"}';
        request.requestBody = Blob.valueOf(payload);
        List<FSL_ClearJsonWorkOrder> getcont3=FSL_IVRMemberId_v1.getContact(); 
        system.debug('####');
        system.debug(getcont3);
        String errorStatusDescription=getcont3[0].statusDescription;
        system.assert(errorStatusDescription.contains('Unexpected character'));
    }

    @isTest
    public static void searchByANITest() {
        delete [select id from Technology_Preference__c];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_Required_ComplexCall');        
        Test.stopTest();

        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/calls/searchByANI';
        request.httpMethod = 'POST';
        String payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a", "ANI": "4079999999"}';

        request.requestBody = Blob.valueOf(payload);
        RestContext.request = request;
      List<FSL_ClearJsonWorkOrder> getcont1=  FSL_IVRAni_v1.getContact();
         system.debug('####');
        system.debug(getcont1);
        
        DateTime ETA=getcont1[0].callEvents[0].statusDetail.eta;
        //system.assert(ETA!=null);
        String callid=getcont1[0].calls[0].callid;
        system.assertEquals(callid,'30000');
        
        
        Contact contact = new Contact(LastName='TestCon1', MobilePhone='4079999999');
		insert contact;
        List<FSL_ClearJsonWorkOrder> getcont2=FSL_IVRAni_v1.getContact();
        system.debug('####');
        system.debug(getcont2);
        
        String statusDescription=getcont2[0].statusDescription;
        system.assertEquals(statusDescription,'ANI_RESPONSE_Error::More than One member found with 4079999999');
        
		payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a", "ANI": "5079999999"}';
        request.requestBody = Blob.valueOf(payload);
       List<FSL_ClearJsonWorkOrder> getcont3=  FSL_IVRAni_v1.getContact();
        
          system.debug('####');
        system.debug(getcont3);
        
        String statusDescription2=getcont3[0].statusDescription;
        system.assertEquals(statusDescription2,'ANI_RESPONSE_Error::No member found with 5079999999');
        
        
        payload = '{ "transactionId": "78babf77-4bb5-832c-dcd0-5137d306af4a" "ANI": "5079999999"}';
        request.requestBody = Blob.valueOf(payload);
        List<FSL_ClearJsonWorkOrder> getcont4=FSL_IVRAni_v1.getContact();
        system.debug('####');
        system.debug(getcont4);
        String errorStatusDescription=getcont4[0].statusDescription;
        system.assert(errorStatusDescription.contains('Unexpected character'));
        
    }    
    @isTest
    public static void EmailWrapperTest() {
        FSL_LightningEmailWrapper ewrap = new FSL_LightningEmailWrapper();
		ewrap.emailType ='';
        ewrap.address ='';
    }

    @isTest
    public static void CustomPropertiesWrapperTest() {
    	FSL_CustomPropertiesWrapper cpwrap = new FSL_CustomPropertiesWrapper();
		cpwrap.name= '';
        cpwrap.value= '';

    }

    @isTest
    public static void SystemOrganizationWrapperTest() {
        FSL_LightningSystemOrganizationWrapper soWrap = new FSL_LightningSystemOrganizationWrapper();
		soWrap.name='';
        soWrap.code='';

    }

    @isTest
    public static void ContactWrapperTest() {

        FSL_LightningContactWrapper cwrap = new FSL_LightningContactWrapper();
		cwrap.contactType ='';
        cwrap.title ='';
        cwrap.firstName ='';
        cwrap.lastName ='';
        cwrap.phones =null;
        cwrap.emails = null;

    }

    @isTest
    public static void ApexConstantTest() {
        FSL_ApexConstants constant =  new FSL_ApexConstants ();
        system.debug(FSL_ApexConstants.API_LOG_FAILED_REQUEST);
        system.debug(FSL_ApexConstants.API_LOG_SUCCESS_REQUEST) ;
        system.debug(FSL_ApexConstants.API_LOG_FAILED_RESPONSE) ;
        system.debug(FSL_ApexConstants.API_LOG_SUCCESS_RESPONSE) ;
        system.debug(FSL_ApexConstants.IVR_FAILED_RESPONSE_NO_MEMBER_FOUND)  ;
        system.debug(FSL_ApexConstants.IVR_FAILED_RESPONSE_TOO_MANY_MEMBERS) ;
        system.debug(FSL_ApexConstants.IVR_SUCCESS_RESPONSE)                 ;
        system.debug(FSL_ApexConstants.ANI_FAILED_RESPONSE_NO_MEMBER_FOUND)  ;
        system.debug(FSL_ApexConstants.ANI_FAILED_RESPONSE_TOO_MANY_MEMBERS) ;
        system.debug(FSL_ApexConstants.ANI_SUCCESS_RESPONSE)                 ;
    }

    @isTest
    public static void phonewrapTest() {
        FSL_LightningPhoneWrapper pwrap = new FSL_LightningPhoneWrapper();
        pwrap.phoneType ='';
        pwrap.phoneNumber ='';
        pwrap.phoneExtension ='';
        pwrap.preferred =true;
        pwrap.smsOptIn =true;
    }

    @isTest
    public static void entitlementwrapTest() {
        FSL_LightningEntitlementWrapper ewrap = new FSL_LightningEntitlementWrapper();
        ewrap.serviceChargeIndicator=false ;
        ewrap.associates=0;
        ewrap.chargeableCalls=0;
        ewrap.currentCalls=0;
        ewrap.callsAllowed=0;
        ewrap.callsRemaining=0;
        ewrap.callsUsed=0;
        ewrap.onlineGarageMember=true;
        ewrap.longTowAllowed=true;
        ewrap.longTowKilometers=1;
        ewrap.longTowMiles=1;
        ewrap.rentalDays=1;
    }

    @isTest
    public static void memwrapTest() {
        FSL_LightningMembershipWrapper mwrap = new FSL_LightningMembershipWrapper();
    	mwrap.membershipType = '';
        mwrap.sponsor ='';
        mwrap.program ='';
        mwrap.authorizationCode ='';
        mwrap.authorizationLevel ='';
        mwrap.isLocalClub =false;
        mwrap.id= '';
        mwrap.originalMemberId ='';
        mwrap.expirationDate='';
        mwrap.memberLevel='';
        mwrap.memberBirthday ='';
        mwrap.memberSince ='';
        mwrap.memberStatus='';
        mwrap.entitlements=null;
        mwrap.goodwill='';
        mwrap.programName='';
        mwrap.programPhone='';
        mwrap.programMaxMileage='';
        mwrap.org=null;
        mwrap.cdxMessage='';
        mwrap.ersAbuser='';
        mwrap.badCheck='';
        mwrap.motorcycleIndicator='';
    }

    @isTest
    public static void custwrapTest() {
        FSL_LightningCustomerWrapper cwrap = new FSL_LightningCustomerWrapper();
        cwrap.membership =null;
    	cwrap.contact=null; 
        cwrap.languagePreference='';
        cwrap.customProperties=null;
    }    
    
    
    @TestSetup
    static void testSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    
}