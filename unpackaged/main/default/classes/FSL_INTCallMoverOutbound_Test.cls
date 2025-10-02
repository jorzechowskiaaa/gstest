/**** Apex Test Class Name:    FSL_INTCallMoverOutbound_Test
    * Description        :     This is the test class used to test FSL_INTCallMoverOutbound class
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Nov 15 2021             Created
*********************************************************************************/
@isTest(SeeAllData = false)
public class FSL_INTCallMoverOutbound_Test {
    
    @Testsetup
    public static void datasetforCON(){
        
        
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        Integration_Settings__c IntegrationSetting = new Integration_Settings__c();
        IntegrationSetting.name = 'CallMover_Outbound_API';
        IntegrationSetting.Method__c='POST';
        IntegrationSetting.Header_Value__c='[{"key":"Content-Type","value":"application/json"}]';
        IntegrationSetting.Enpoint_URL__c='https://api-qa.national.aaa.com/automotive/services/ci/v1/calls/move';
        IntegrationSetting.Request_Timeout__c=120000;
        lstIntegrationSetting.add(IntegrationSetting);
        
        Integration_Settings__c IntegrationSetting1 = new Integration_Settings__c();
        IntegrationSetting1.name = 'National_OAuth_API';
        IntegrationSetting1.Method__c='POST';
        IntegrationSetting1.Header_Value__c='[{"key":"Content-Type","value":"application/json"}]';
        IntegrationSetting1.Extra_Header_Value__c = 'grant_type=client_credentials';
        IntegrationSetting1.Enpoint_URL__c='https://api-qa.national.aaa.com/common/oauth2/token';
        IntegrationSetting1.Request_Timeout__c=120000;
        lstIntegrationSetting.add(IntegrationSetting1);
        
        insert lstIntegrationSetting;
        
        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Id MEMBER_ACCOUNT_RECORDTYPEID = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
        List<Account> lstMembers = ACG_TestDataFactory.createAccounts(MEMBER_ACCOUNT_RECORDTYPEID,1,false,true);
        for(Account objacc:lstMembers){  
            objacc.ACG_AAA_Membership__c='4299941234757815';
            objacc.AAA_Membership_Level__c='Plus';
            objacc.phone = '9999999999';
            objacc.Long_Tow_Kilometers_Used__c =161;
            objacc.Long_Tow_Miles_Used__c=100;
           // objacc.Rental_Days__c=2;
            objacc.ACG_Entitlements_Allotted__c=2;
            objacc.ACG_Entitlements_Used__c=1;
           // objacc.Rental_Days__c=2;
         }
        
        insert lstMembers; 
        
        Account acc = [Select id from Account  where recordtypeId=:MEMBER_ACCOUNT_RECORDTYPEID limit 1];
        FSL_Member_Vehicle__c mem = new FSL_Member_Vehicle__c(Vehicle_Make__c = 'Jeeps',ACG_Member__c = acc.Id);
        insert mem;
        
        WorkType WT_Rec = new WorkType(Name = 'Fuel Delivery', EstimatedDuration = 10.0, DurationType = 'Minutes');
        insert WT_Rec;
        
        Case objcs = new Case();
        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone',true);
        objcs.AccountId = acc.Id;
        objcs.Member_Vehicle__c = mem.ID;
        objcs.ACG_Make__c = 'Honda';
        objcs.ACG_Color__c = 'Silver';
        objcs.ACG_Year__c = '2019';
        objcs.ACG_Model__c = 'Aista';
        objcs.Vehicle_Location_Street__c = '15029 TYACKE DR';
        objcs.Vehicle_Location_City__c = 'Charlotte';
        objcs.Vehicle_Location_State__c = 'NC';
        objcs.Vehicle_Location_Postal_Code__c  = '28202';
        objcs.ACG_Driving_Directions__c = 'Near Parking plot';
        objcs.Vehicle_Geolocation__Latitude__s = 34.779527;
        objcs.Vehicle_Geolocation__Longitude__s = -122.537032;
        objcs.Tow_Destination_Street__c = '15029 TYACKE DR';
        objcs.Tow_Destination_City__c = 'Charlotte';
        objcs.Tow_Destination_State__c = 'North Carolina';
        objcs.Tow_Destination_Postal_Code__c  = '28202';
        objcs.Tow_Geolocation__Latitude__s = 34.779527;
        objcs.Tow_Geolocation__Longitude__s = -122.537032;
        objcs.T_Code__C = 'T6';
        objcs.Pacesetter_Code__c = 'T480';
        objcs.ACG_Work_type__C = WT_Rec.Id;
        update objcs;
       
    }
    
    @isTest static void casetransfertoNational(){
        Test.startTest();
        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        string res = '{"access_token": "eyJraWQiOiJVRHZyUHpm","expires_in": 3600,"token_type": "Bearer"}';
        string res1 = '{\"statusCode\":\"200\",\"statusDescription\":\"SuccessfullymovedcalltoD39f719f0c-1231-7cf6-661b-7360b634367e\",\"sourceSystem\":{\"systemId\":\"D3\"},\"header\":{\"version\":\"2.0\",\"type\":\"ResponseType\",\"subType\":\"ResponseSubType\",\"status\":\"SUCCESS\",\"id\":\"9f719f0c-1231-7cf6-661b-7360b634367e\"},\"responsePayload\":{\"callKey\":\"311-20211223-3\",\"pta\":\"2021-12-23T02:05:00.000Z\"}}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res1, 200));
        case objcs = [select id from case where recordtypeId=:recordTypeID limit 1];
        FSL_INTCallMoverOutbound.Response_wrapper resp = new FSL_INTCallMoverOutbound.Response_wrapper();
        resp=FSL_INTCallMoverOutbound.generateCallMoverRequest(objcs.Id);
        system.assertEquals(resp.isSuccess, true);
        FSL_CallMoverJSONRequest_Wrapper wrp= new FSL_CallMoverJSONRequest_Wrapper();
        FSL_CallMoverJSONRequest_Wrapper.Calls call = new FSL_CallMoverJSONRequest_Wrapper.Calls();
        FSL_CallMoverJSONRequest_Wrapper.Contact con = new FSL_CallMoverJSONRequest_Wrapper.Contact();
        con.userId='2135';
        con.contactType='test con';
        FSL_CallMoverJSONRequest_Wrapper.systemOrganization sys = new FSL_CallMoverJSONRequest_Wrapper.systemOrganization();
        sys.name='test';
        sys.code='1234';
        FSL_CallMoverJSONRequest_Wrapper.SourceSystem src = new FSL_CallMoverJSONRequest_Wrapper.SourceSystem();
        src.systemId='1111111';
        src.systemOrganization=sys;
        FSL_CallMoverJSONRequest_Wrapper.Comments com = new FSL_CallMoverJSONRequest_Wrapper.Comments();
        com.text='test';
        com.visibility='test';
        com.commentType='test';
        com.commentDate='01-05-2022';
        com.contact=con;
        com.system_Z=src;
        FSL_CallMoverJSONRequest_Wrapper.Comments com1 = new FSL_CallMoverJSONRequest_Wrapper.Comments();
        com1.text='test1';
        com1.visibility='test1';
        com1.commentType='test1';
        com1.commentDate='02-05-2022';
        com1.contact=con;
        com1.system_Z=src;
        FSL_CallMoverJSONRequest_Wrapper.Address add = new FSL_CallMoverJSONRequest_Wrapper.Address();
        add.full='test';
        add.streetNumber='99';
        add.streetDirection='right';
        add.streetName='test street';
        add.crossStreet='no';
        FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location serloc = new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location();
        serloc.latitude=1.2;
        serloc.longitude=4.5;
        serloc.highway='NH4';
        serloc.mileMarker='194';
        serloc.grid='test';
        serloc.zone='green';
        serloc.locationCode='890759';
        serloc.landmark='test mark';
        serloc.address=add;
        List<FSL_CallMoverJSONRequest_Wrapper.Phones_Contacts> Phones_Contacts=new List<FSL_CallMoverJSONRequest_Wrapper.Phones_Contacts>();
        FSL_CallMoverJSONRequest_Wrapper.Phones_Contacts Phones_Contact= new FSL_CallMoverJSONRequest_Wrapper.Phones_Contacts();
        Phones_Contact.phoneType='test';
        Phones_Contact.phoneNumber='test';
        Phones_Contact.preferred=true;
        Phones_Contacts.add(Phones_Contact);
        List<FSL_CallMoverJSONRequest_Wrapper.Contacts> contacts=new List<FSL_CallMoverJSONRequest_Wrapper.Contacts>();
        FSL_CallMoverJSONRequest_Wrapper.Contacts conts = new FSL_CallMoverJSONRequest_Wrapper.Contacts();
        conts.contactType='test';
        conts.firstName='test1';
        conts.lastName='test2';
        conts.phones=Phones_Contacts;
        contacts.add(conts);
        FSL_CallMoverJSONRequest_Wrapper.Foi fo = new FSL_CallMoverJSONRequest_Wrapper.Foi();
        fo.location=serloc;
        fo.contacts=contacts;
        fo.name='test';
        List<FSL_CallMoverJSONRequest_Wrapper.ServiceLocations> serlocations = new List<FSL_CallMoverJSONRequest_Wrapper.ServiceLocations>();
        FSL_CallMoverJSONRequest_Wrapper.ServiceLocations serlocation=new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations();
        serlocation.foi=fo;
        serlocation.mileageCalculated=1.0;
        serlocation.milesFromOrigin=10;
        serlocation.dropBoxInfo='test';
        serlocations.add(serlocation);
        
        FSL_CallMoverJSONRequest_Wrapper.Status Status = new FSL_CallMoverJSONRequest_Wrapper.Status();
        Status.status='draft';
        Status.updatecode='100';
        Status.modifiedDate=Datetime.newInstance(2022,2, 17);
        Status.pta='test';
        Status.waitTime=90;
        FSL_CallMoverJSONRequest_Wrapper.Service service = new FSL_CallMoverJSONRequest_Wrapper.Service();
        service.serviceLocations=serlocations;
        service.status=Status;
        
        FSL_CallMoverJSONRequest_Wrapper.Payment pay = new FSL_CallMoverJSONRequest_Wrapper.Payment();
        pay.required=true;
        pay.paymentType='net';
        pay.codes='test';
        pay.responsible='yes';
        List<FSL_CallMoverJSONRequest_Wrapper.Comments> lstcom1 = new List<FSL_CallMoverJSONRequest_Wrapper.Comments>();
        lstcom1.add(com1);
        lstcom1.add(com);
        call.service=service;
        call.comments=lstcom1;
        call.payment=pay;
        //wrp.calls.add(call);
        Test.stopTest();
    }

}