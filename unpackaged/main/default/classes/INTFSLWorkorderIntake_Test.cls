/**** Apex Class Name    :    INTFSLWorkorderIntake_Test
    * Description        :    This is the test class used to test INTFSLWorkorderIntake class 
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri              Oct 1 2021             Created
*********************************************************************************/
@isTest
public class INTFSLWorkorderIntake_Test {
    private class MockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String reqEndpoint = req.getEndpoint();
            String bodyJSONStr = '';
            res.setHeader('Content-Type', 'application/json');

            if (reqEndpoint == 'testurl') {   // Util_ManageAccessTokens::callOAuth
                bodyJSONStr = '{"access_token":"test1234"}';
            } else if (reqEndpoint.contains('testSearch')) {    // FSL_ValidateMembershipNumber::invokeCallout
                bodyJSONStr = '{"statusCode":200,"statusDescription":"Success","customer":{"languagePreference":null,"contact":{"contactType":"CUSTOMER","title":null,"firstName":"Test","middleName":"","lastName":"Test","suffix":"","phones":[{"phoneType":"MOBILE","phoneNumber":"9785552168","preferred":true,"smsOptIn":false},{"phoneType":"WORK","phoneNumber":"9785555404","preferred":false,"smsOptIn":false,"phoneExtension":""}],"emails":[{"emailType":"PERSONAL","address":null}]},"memberships":[{"dispatchCenter":"","dealerName":"","dealerPhone":"","goodwill":"","membershipType":"Associate Member","sponsor":"","authorizationCode":"","authorizationLevel":"","org":{"name":"","code":"240"},"memberLevel":"Basic","isLocalClub":true,"memberStatus":"Active","program":null,"programName":"","programPhone":"","programMaxMileage":"","memberBirthday":"1990-01-01","memberSince":"2017","memberSinceDate":"2017-07-06","originalMemberId":"6202404941373216","id":"6202404941373216","expirationDate":"2023-07-15","startDate":"2022-07-16","primaryMemberExpirationDate":"2023-04-01","primaryMemberStartDate":"2022-07-16","riders":"","ersAbuser":"","badCheck":"Active","motorcycleIndicator":"","cdxMessage":"","primaryValid":"","primaryPaid":"","cancelCode":null,"cancelType":"","cancellationDate":"","inArrears":"","inRenewal":"","totalPastDue":null,"totalAmountApplied":null,"totalAmountDue":null,"renewalExpirationDate":"","membershipPaidThroughDate":"2023-07-15","billPlan":"","emsMessage":"","entitlements":[{"serviceChargeIndicator":false,"associates":null,"chargeableCalls":null,"currentCalls":null,"callsAllowed":"4","callsRemaining":null,"callsUsed":null,"onlineGarageMember":false,"longTowAllowed":false,"longTowKilometers":null,"longTowMiles":null,"rentalDays":null,"homeLockoutEntitled":false,"carRentalEntitled":false,"RVUsage":false,"CAPREeligible":false,"sameDayService":null,"joinFeeEndDate":"","joinFeePerCallFlag":"","joinFeeNumberOfDays":null,"joinFeeAmount":null,"serviceChargeAmount":null,"unpaidCardFeeAmount":null}]}],"customProperties":[{"name":"In Renewal","value":"Membership is in renewal, please attempt to collect payment in MRM. If no payment is made, the member may be billed a service charge fee for their service today."},{"name":"Home Lockout Entitled","value":""},{"name":"Car Rental Entitled","value":""},{"name":"RV Usage","value":""},{"name":"Same Day Service","value":""},{"name":"CAPRE","value":""}],"impairments":[{"name":"In Renewal","message":""}],"foi":{"foiType":"ADDRESS","location":{"latitude":null,"longitude":null,"address":{"addressType":"PHYSICAL","full":"2914341 MAIN STTEMPLETON, MA 01468USA","street":"2914341 MAIN ST","streetNumber":"","line2":null,"streetDirection":"","streetName":"2914341 MAIN ST","city":"TEMPLETON","state":"MA","postalCode":"01468","country":"USA"}}}}}';
            }

            res.setBody(bodyJSONStr);
            res.setStatusCode(200);

            return res;
        }
    }

    @testSetup
    public static void dataSetForCon() {
        //FSL_DataFactoryUtility.userdataSetup();
        //user objuser =[select id from user limit 1];
        //system.runAs(objuser){
        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case objcs = new Case();
        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone',false);
        Id MEMBER_ACCOUNT_RECORDTYPEID =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        List<Account> lstMemberAcc=ACG_TestDataFactory.createAccounts(MEMBER_ACCOUNT_RECORDTYPEID,1,false,true);
        lstMemberAcc[0].ACG_AAA_Membership__c='123';
        lstMemberAcc[0].Member_id__c='123';
        lstMemberAcc[0].Member_Card_Num__pc='123';
        //MemberAcc.PersonEmail='test@gmail.com';
        lstMemberAcc[0].Email_Type__pc='PERSONAL';
        lstMemberAcc[0].Fax='2222222222';
        lstMemberAcc[0].Phone='2222222222';
        lstMemberAcc[0].PersonHomePhone='2222222222';
        lstMemberAcc[0].PersonMobilePhone='2222222222';
        insert lstMemberAcc;
        objcs.AccountId=lstMemberAcc[0].id;
        objcs.Appointment_Requested__c=false;
        insert objcs;
        Id repairrectypeid=ACG_UtilityClass.REPAIRSHOP_RECORDTYPE_ID;
        Account ARRAcc=ACG_TestDataFactory.createAccount(repairrectypeid,'AAR Repair Account',false);
        ARRAcc.type='AAR';
        insert ARRAcc;
        AAA_Location__C coracc=new AAA_Location__C();
        coracc.name='cor repair account';
        coracc.Active__c=true;
        coracc.Car_Care__c=true;
        coracc.Car_Care_Location_Number__c='123';
       coracc.Car_Care_Manager__c=userinfo.getUserId();
        coracc.Car_Care_Region_Manager__c=userinfo.getUserId();
        coracc.Car_Care_Region__c='Colorado';
        insert coracc;
        Account ARRAcc1=ACG_TestDataFactory.createAccount(repairrectypeid,'AAA Repair Account',false);
        ARRAcc1.type='COR';
        ARRAcc1.ACG_AAA_Location__C=coracc.id;
        ARRAcc1.Facility_id__c='12345';
        insert ARRAcc1;
        FSL__Scheduling_Policy__c sp= new FSL__Scheduling_Policy__c();
        sp.name='Future Appointments';
         insert sp;
        FSL__Scheduling_Policy__c sp1= new FSL__Scheduling_Policy__c();
        sp1.name='Blended Policy';
         insert sp1;
        WorkType wt= new WorkType();
        wt.Name='Lockout';
        wt.EstimatedDuration=14;
        insert wt;
        WorkType wt1= new WorkType();
        wt1.Name='Tire Change';
        wt1.EstimatedDuration=14;
        insert wt1;
        FSL_SLA_ArrivalWindow__c arrwin= new FSL_SLA_ArrivalWindow__c();
        arrwin.Retry_Policy__c=sp1.id;
        arrwin.Priority__c='High';
        insert arrwin;
        FSL_SLA_ArrivalWindow__c arrwin1= new FSL_SLA_ArrivalWindow__c();
        arrwin1.Retry_Policy__c=sp1.id;
        arrwin1.Priority__c='Medium';
        insert arrwin1;
        FSL_SLA_ArrivalWindow__c arrwin2= new FSL_SLA_ArrivalWindow__c();
        arrwin2.Retry_Policy__c=sp1.id;
        arrwin2.Priority__c='Low';
        insert arrwin2;
         FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();
        memberVehicle.Vehicle_Make__c = 'YAMAHA';
        memberVehicle.Vehicle_Model__c = 'EXPLORER SPORT TR';
        memberVehicle.Vehicle_Year__c = '2022';
        memberVehicle.Vehicle_Color__c = 'Black';
        memberVehicle.Name ='2022' +' '+'YAMAHA'+' '+'EXPLORER SPORT TR';
        memberVehicle.ACG_Member__c = lstMemberAcc[0].id;
        INSERT memberVehicle;
       // }
       insert new Account(
            FirstName = 'Test',
            LastName = 'Test',
            Phone = '1234567890',
            RecordTypeId = MEMBER_ACCOUNT_RECORDTYPEID,
            Member_ID__c = '6202404941373216'
        );


        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Place_Details_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Place_AutoComplete_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
         lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API_GEOCODE',
            Method__c='GET',
            //Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Header_Value__c ='[{"key": "Authorization","value": "ABC"}]',
            Enpoint_URL__c='https://dev.ane.sadaapis.com/',
            Request_Timeout__c=120000
            
        ));
        /*SSFI-1111 MPatel commented Bing Methods 5/8/25
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'BING_API_GEOCODE',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        )); */
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'SADA_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Named_Credential__c='callout:SADA_MAPS',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            Request_Timeout__c=120000
            
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Google_Timezone_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Enpoint_URL__c='https://test/maps/api/timezone/json?language=en&region=en&address=',
            API_Key__c='test',
            Request_Timeout__c=120000           
        ));
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Google_Geocode_API',
            Method__c='GET',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
            Enpoint_URL__c='https://test/maps/api/geocode/json?language=en&region=en&address=',
            API_Key__c='test',
            Request_Timeout__c=120000           
        ));
         
        insert lstIntegrationSetting;
    }
    
    //Case Creation Operation Test Scenario
    @isTest
    static void caseCreationRAPTest(){
        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        string RAPRequestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"RAP\",\"callType\":\"RAP\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(RAPRequestbody);
        List<Case> cases = [SELECT Id from Case LIMIT 1];
        System.assert(cases.size() > 0, 'Cases should be created');
        /*system.assertEquals('200',resp.statusCode);
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=resp.caseId;
        requestWrapper.OperationType=ACG_ConstantsClass.CANCEL;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp1 = new INTFSL_WorkOrderResponse_Wrapper();
        resp1=createWOIntakeCall(Requestbody);*/
        System.Test.StopTest();          
    } 

    @isTest
    static void caseCreationDRR_MemberNotFoundTest(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        System.Test.StartTest();
        /*Account memacc=[select id from Account where ACG_AAA_Membership__c='123' limit 1];
        memacc.ACG_AAA_Membership__c='4299941234757815';
        memacc.Member_id__c='4299941234757815';
        memacc.Member_Card_Num__pc='4299941234757815';
        update memacc;*/
        string IVRRequestbody = '{\"memberNumber\":4299941234700000,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"SmartActions\",\"callType\":\"SmartActions\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"timeZoneId\":\"America/New_York\",\"timeZoneOffset\":\"UTC-05:00\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"joinYear\":\"2016\",\"currentBenefitLevel\":\"Basic\",\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(IVRRequestbody);
        System.Test.StopTest();           
    } 
    
    @isTest
    static void caseCreationTestIVR(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        System.Test.StartTest();
        /*Account memacc=[select id from Account where ACG_AAA_Membership__c='123' limit 1];
        memacc.ACG_AAA_Membership__c='4299941234757815';
        memacc.Member_id__c='4299941234757815';
        memacc.Member_Card_Num__pc='4299941234757815';
        update memacc;*/
        string IVRRequestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"timeZoneId\":\"America/New_York\",\"timeZoneOffset\":\"UTC-05:00\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"joinYear\":\"2016\",\"currentBenefitLevel\":\"Basic\",\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(IVRRequestbody);
        //system.assertEquals('200',resp.statusCode);
        /*INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody);
        requestWrapper.caseId=resp.caseId;
        requestWrapper.OperationType=ACG_ConstantsClass.CANCEL;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp1 = new INTFSL_WorkOrderResponse_Wrapper();
        resp1=createWOIntakeCall(Requestbody);*/
        System.Test.StopTest();          
    }

    @isTest
    static void caseUpdationTestIVR(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        System.Test.StartTest();
        Case aCase = new Case(
                Subject = 'Genesys Case',
                ACG_Case_Contact_Number__c = '1234567890',
                Genesys_ConversationId__c = '1234-5678',
                Status= 'In Progress'
            );
            insert aCase;
        string IVRRequestbody = '{\"OperationType\":\"UpdateGenesysId\",\"genesysConversationId\":\"5678-2345\",\"channel\":\"IVR\",\"CaseId\":\"'+aCase.Id+'\"}';
        //string IVRRequestbody = '{"OperationType":"UpdateGenesysId","genesysConversationId":"5678-2345","channel":"IVR","CaseId":'+aCase.Id+'}';
        //string IVRRequestbody = '{\"OperationType\":\"UpdateGenesysId\",\"genesysConversationId\":\"5678-2345\",\"channel\":\"IVR\",\"CaseId\":\"1234\"}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(IVRRequestbody);
        system.assertEquals('200',resp.statusCode);
        /*INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody);
        requestWrapper.caseId=resp.caseId;
        requestWrapper.OperationType=ACG_ConstantsClass.CANCEL;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp1 = new INTFSL_WorkOrderResponse_Wrapper();
        resp1=createWOIntakeCall(Requestbody);*/
        System.Test.StopTest();          
    }

    
    @isTest
    static void caseCreationTestCatch(){
        System.Test.StartTest();
        try{
            string Requestbody = '{\"memberNumber\":\"4299941234757815}';
            INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
            //Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST('',400)); 
            resp=createWOIntakeCall(Requestbody);
        }Catch(Exception e){

        }
        
        System.Test.StopTest();          
    }    
    
    //Case creation Operation Negative Test Scenario
    @isTest
    static void CreateCaseNegTest(){
        System.Test.StartTest();
        string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"DRR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":\"Zero\",\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals(resp, null);
        System.Test.StopTest();          
    } 
    
    //W/o Operation Type in Request body Scenario
    @isTest
    static void caseCreationNegTest(){
        System.Test.StartTest();
        string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"2022-03-31 02:30:00\",\"SlotEndDateTime\":\"2022-03-31 04:30:00\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('400',resp.statusCode);
        System.Test.StopTest();          
    }
    
    //Case Update Scenario
    @isTest
    static void caseUpdationTest(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        objcs.Vehicle_Location_Street__c = '15029 TYACKE DR';
        objcs.Vehicle_Location_City__c = 'Charlotte';
        objcs.Vehicle_Location_State__c = 'NC';
        objcs.Vehicle_Location_Postal_Code__c = '28202';
        objcs.Vehicle_Geolocation__Latitude__s = 35.44128209281916;
        objcs.Vehicle_Geolocation__Longitude__s = -80.83753430355662;
        //objcs.Vehicle_Location_Country__c = 'United States';
        update objcs;
        //\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseUpdate\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('200',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    //Case Update Negative Scenario
    @isTest
    static void caseUpdationNegTest(){
        System.Test.StartTest();
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseUpdate\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('400',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    //Create WorkOrder with Light service Test Scenario
    //@isTest
    static void CreateWorkOrderTest(){
        System.Test.StartTest();
        Id Member_RecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        Account Member = new Account(FirstName ='TestPersonAcc', LastName = 'ERS**', RecordTypeId = Member_RecTypeId, ACG_Is_Primary_Member_in_Household__c = true,AAA_Membership_Level__c = 'Plus');
        insert Member;
        case objcs = [select id from case limit 1];
        objcs.AccountId = Member.Id;
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"flatbedRequired\":true},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        //system.assertEquals('200',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    //Create WorkOrder with Tow type Test Scenario
    //@isTest
    static void CreateTowWorkOrderTest(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"0\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":35.44519791730036,\"longitude\":-80.93881451595897}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        requestWrapper.WorkorderID=resp.WorkorderID;
        requestWrapper.SlotStartDateTime = Datetime.now().format('yyyy-MM-dd  hh:mm:ss');
        Datetime enddateTime= Datetime.now()+(1/24);
        requestWrapper.SlotEndDateTime = enddateTime.format('yyyy-MM-dd  hh:mm:ss');
        requestWrapper.OperationType='Update Service appointment';
        requestWrapper.ContactInformation.telephoneNumber = '8888888888';
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp1 = new INTFSL_WorkOrderResponse_Wrapper();
        resp1=createWOIntakeCall(Requestbody);
        //system.assertEquals('200',resp.statusCode);
        System.Test.StopTest();          
    }
    
    
    //Create WorkORder Test Scenario for Call Type IVR
    @isTest
    static void CreateWOrkOrderIVRTest(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"T480\",\"issueType\":\"\",\"policy\":\"1234\",\"priority\":\"Normal\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"IVR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"TR\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"0\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":35.44519791730036,\"longitude\":-80.93881451595897}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        //system.assertEquals('200',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    //Cancel WorkOrder Test Scenario
    //@isTest
    static void CancelWorkOrderTest(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"flatbedRequired\":true},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        createWOIntakeCall(Requestbody);
        WorkOrder wo = [select id,workordernumber,status from workorder 
                                                  where caseId=:requestWrapper.CaseId order by createddate desc limit 1];
        requestWrapper.OperationType = 'Cancel';
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('400',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    //Update Service Appointment Negative scenario
    @isTest
    static void UpdateServiceAppointmentNegTest(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"Update Service appointment\",\"callType\":\"DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        resp.callDate = '2021-12-12';
        resp.callId = '12345';
        resp.ptaminutes = 21;
        INTFSL_WorkOrderResponse_Wrapper.slotDetails sl = new INTFSL_WorkOrderResponse_Wrapper.slotDetails();
        sl.startTime = String.valueof(Datetime.now());
        sl.finishTime = String.valueof(Datetime.now());
        List<INTFSL_WorkOrderResponse_Wrapper.slotDetails> lstsl = new List<INTFSL_WorkOrderResponse_Wrapper.slotDetails>();
        lstsl.add(sl);
        resp.ListOfSlots = lstsl;
        system.assertEquals('400',resp.statusCode);
        System.Test.StopTest();          
    } 
    
    @isTest
    static Void callMoverTest(){
       System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"callMover\",\"callType\":\"DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('200',resp.statusCode);
        system.Test.stopTest();
    }
    
    @isTest
    static Void callMoverTest1(){
       System.Test.StartTest();
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"callMover\",\"callType\":\"DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2022,\"make\":\"YAMAHA\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        system.assertEquals('200',resp.statusCode);
        system.Test.stopTest();
    }
    
    //Invoke the CreateWorkOrderIntake Call
    public static INTFSL_WorkOrderResponse_Wrapper createWOIntakeCall(string Requestbody){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/createWorkOrder/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(Requestbody);
        RestContext.request = req;
        RestContext.response= res; 
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        try {
            resp=INTFSLWorkorderIntake.createWorkOrder().get(0);
        } catch(Exception e) {
            system.debug('Err:'+e);
            return null;
        }
        return resp;
    }

    //@isTest
    static void CreateWorkOrderTest1(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
         Account acc=[Select id from Account where type='AAR' limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"slotEndDateTime\":\"2022-03-31 3:30:00\",\"slotStartDateTime\":\"2022-03-31 1:30:00\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"0\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":35.44519791730036,\"longitude\":-80.93881451595897}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        requestWrapper.ContactInformation.telephoneNumber = '8888888888';
        requestWrapper.towDestination.shopId=acc.Id;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        System.Test.StopTest();        
    }  
    //@isTest
    static void CreateWorkOrderTest2(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
         Account acc=[Select id,ACG_AAA_Location__C from Account where type='COR' limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"slotEndDateTime\":\"2022-03-31 3:30:00\",\"slotStartDateTime\":\"2022-03-31 1:30:00\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"0\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":35.44519791730036,\"longitude\":-80.93881451595897}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        requestWrapper.ContactInformation.telephoneNumber = '8888888888';
        requestWrapper.towDestination.shopId=acc.ACG_AAA_Location__C;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        System.Test.StopTest();        
    }

    //@isTest
    static void CreateWorkOrderTest3(){
        System.Test.StartTest();
        case objcs = [select id from case limit 1];
        objcs.ACG_Case_Contact_Number__c='7894561230';
        update objcs;
         Account acc=[Select id,ACG_AAA_Location__C from Account where type='COR' limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"slotEndDateTime\":\"2022-03-31 3:30:00\",\"slotStartDateTime\":\"2022-03-31 1:30:00\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2022,\"make\":\"YAMAHA\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"1234\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":35.44519791730036,\"longitude\":-80.93881451595897}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        requestWrapper.ContactInformation.telephoneNumber = '8888888888';
        requestWrapper.towDestination.shopId='12345';//acc.ACG_AAA_Location__C;
        Requestbody = JSON.serialize(requestWrapper);
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(Requestbody);
        System.Test.StopTest();        
    }

    @isTest
    static Void createCallCommentsTest(){
       
       System.Test.StartTest();
       Test.setMock(HttpCalloutMock.class, new MockResponse());
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        string RAPRequestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"RAP\",\"callType\":\"RAP\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(RAPRequestbody);
        List<WorkOrder> wo = [Select Id from WorkOrder LIMIT 1];
       List<FeedItem> feed = new List<FeedItem>();
       List<string> comments = new List<String>{'Test'};
       if(wo.size() >0){
        feed = INTFSLWorkorderIntake.createCallComments(comments,wo[0]);
       }
       
       System.Test.StopTest();    
    }

    @isTest
    static void caseCreationTestCatchException(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        System.Test.StartTest();
        string IVRRequestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"slotEndDateTime\":\"2022-03-31 3:30:00\",\"slotStartDateTime\":\"2022-03-31 1:30:00\",\"OperationType\":\"ImmediateAppointment\",\"channel\":\"IVR\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2022,\"make\":\"YAMAHA\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":null,\"longitude\":null,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"1234\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":\"\",\"longitude\":\"\"}}';
        //string IVRRequestbody = '{\"memberNumber\":4299941234700000,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"SmartActions\",\"callType\":\"SmartActions\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        
        String res = '{"dstOffset":0,"rawOffset":-28800,"status":"OK","timeZoneId":"America/Los_Angeles","timeZoneName":"PacificStandardTime"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"timeZoneId\":\"America/New_York\",\"timeZoneOffset\":\"UTC-05:00\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"joinYear\":\"2016\",\"currentBenefitLevel\":\"Basic\",\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        try{
            resp=createWOIntakeCall(IVRRequestbody);
        }Catch(Exception e){

        }  
        System.Test.StopTest();          
    }

    @isTest
    static void caseCreationTestLatLong(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        System.Test.StartTest();
        //string IVRRequestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"1234\",\"priority\":\"Normal\",\"slotEndDateTime\":\"2022-03-31 3:30:00\",\"slotStartDateTime\":\"2022-03-31 1:30:00\",\"OperationType\":\"ImmediateAppointment\",\"channel\":\"IVR\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pmuDAAQ\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"comments\":[\"MBR Stated No COVID-19 Exposure or Symptoms\"],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2022,\"make\":\"YAMAHA\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"licensePlateIdentifier\":\"\",\"licensePlateState\":\"\",\"driveLine\":null,\"flatbedRequired\":false,\"type\":\"PS\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":null,\"longitude\":null,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"1234\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\",\"latitude\":\"\",\"longitude\":\"\"}}';
        //\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,
        string IVRRequestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Vehicle Lockout\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"timeZoneId\":\"\",\"timeZoneOffset\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\"},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"},\"towDestination\":{\"shopId\":\"1234\",\"locationName\":\"AAA CAR CARE CENTER #448 (MONTFORD DR)\",\"streetNumber\":\"01\",\"streetName\":\"65J3+23\",\"crossStreet\":\"65J3+23\",\"city\":\"Charlotte\",\"state\":\"NC\",\"postalCode\":\"28202\"}}'; 
        String res = '{"results":[{"formatted_address":"1600AmphitheatrePkwy,MountainView,CA94043,USA","geometry":{"location":{"lat":37.4224428,"lng":-122.0842467}},"place_id":"ChIJeRpOeF67j4AR9ydy_PIzPuM"}],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200));
        //string Requestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"timeZoneId\":\"America/New_York\",\"timeZoneOffset\":\"UTC-05:00\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"joinYear\":\"2016\",\"currentBenefitLevel\":\"Basic\",\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSL_WorkOrderResponse_Wrapper resp = new INTFSL_WorkOrderResponse_Wrapper();
        resp=createWOIntakeCall(IVRRequestbody);
        System.Test.StopTest();          
    }
    
     @isTest
    static void createServiceAppointment(){
     System.Test.StartTest();
    // string RAPRequestbody = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"RAP\",\"callType\":\"RAP\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":["Test"],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
     //INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);  
        case objcs = [select id from case limit 1];
        string Requestbody = '{\"memberNumber\":\"4299941234758818\",\"pacesetterCode\":\"\",\"issueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"ImmediateAppointment\",\"callType\":\"ACG DRR\",\"callStatus\":\"\",\"CaseId\":\"50005000003pvkHAAQ\",\"numberOfPassengers\":1,\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"userId\":\"SAIVR\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS\",\"lastName\":\"CARDELLA\",\"telephoneNumber\":\"6129105371\",\"smsOptin\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30},\"vehicle\":{\"year\":2021,\"make\":\"FORD\",\"model\":\"EXPLORER SPORT TR\",\"color\":\"BLACK\",\"flatbedRequired\":true},\"breakdownLocation\":{\"streetNumber\":\"15029\",\"streetName\":\"TYACKE DR\",\"crossStreet\":\"\",\"city\":\"Charlotte\",\"postalCode\":\"28202\",\"state\":\"NC\",\"landmark\":\"\",\"latitude\":35.44128209281916,\"longitude\":-80.83753430355662,\"pickupPoint\":\"\",\"driverDirections\":\"\",\"locationCode\":\"Home\"}}';
        INTFSLWorkOrderRequest_Wrapper requestWrapper = INTFSLWorkOrderRequest_Wrapper.parse(Requestbody).get(0);
        requestWrapper.caseId=objcs.id;
        Requestbody = JSON.serialize(requestWrapper);
        createWOIntakeCall(Requestbody);
        WorkOrder wo = [select id,workordernumber,caseId,status,Vehicle_Profile__c,Member_Account__c,ServiceTerritoryId,is_Tow_WorkType__c,Priority,ACG_Requested_Appointment_Date__c,ACG_Requested_Appointment_Time__c from workorder 
                                                  where caseId=:requestWrapper.CaseId order by createddate desc limit 1];
        INTFSLWorkorderIntake obj = new INTFSLWorkorderIntake();
        ServiceAppointment sa = INTFSLWorkorderIntake.createServiceAppointment('test',wo,requestWrapper);
    }

    @isTest
    public static void createWorkOrderFeedItem_Future_TEST(){ //AGB 10/15/2024 SSFI-469
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId,ERS_Notes__c = '!@# TEST NOTE #@!' , ACG_Service_Type__c = 'Locksmith', Locksmith_Issue__c = 'Key Broken');
        insert caseRec;
        Test.startTest();
        WorkOrder woRec = new WorkOrder(CaseId = caseRec.Id);
        insert woRec;
        
       
        //Test Scenario
        INTFSLWorkorderIntake.createWorkOrderFeedItem_Future(caseRec.id, woRec.id);
        Test.stopTest();
        List<FeedItem> lstFeedItems = [SELECT Id, ParentId, Body FROM FeedItem WHERE ParentId = :woRec.Id];
        
        System.assertEquals(false, lstFeedItems.isEmpty(), 'FeedItem not created');
        
    }
    
    //createCallComments_Future
    @isTest
    public static void createCallComments_Future_TEST(){ //AGB 10/15/2024 SSFI-469
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId,ERS_Notes__c = '!@# TEST NOTE #@!' , ACG_Service_Type__c = 'Locksmith', Locksmith_Issue__c = 'Key Broken');
        insert caseRec;
        Test.startTest();
        WorkOrder woRec = new WorkOrder(CaseId = caseRec.Id);
        insert woRec;
        
        list<string> comments = new list<string>{'!@# TEST comment #@!'};
        //Test Scenario
        INTFSLWorkorderIntake.createCallComments_Future(comments,woRec.id,caseRec.id);
        Test.stopTest();
        List<FSL_Call_Comments__c> lstCallCommentItems = [SELECT Id, ACG_Case__c, FSL_Comment__c,FSL_Work_Order__c FROM FSL_Call_Comments__c WHERE ACG_Case__c = :caseRec.id];
        
        System.assertEquals(false, lstCallCommentItems.isEmpty(), 'Call Comment not created');
        
    }
    
   	@isTest
    public static void createCallComments_2_TEST(){ //AGB 10/15/2024 SSFI-469
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId,ERS_Notes__c = '!@# TEST NOTE #@!' , ACG_Service_Type__c = 'Locksmith', Locksmith_Issue__c = 'Key Broken');
        insert caseRec;
        Test.startTest();
        WorkOrder woRec = new WorkOrder(CaseId = caseRec.Id);
        insert woRec;
        
        list<string> comments = new list<string>{'!@# TEST comment #@!'};
        //Test Scenario
        //createCallComments(list<string> comments, String woId, String caseId)
        List<FSL_Call_Comments__c> returnedList = new List<FSL_Call_Comments__c>(); 
        returnedList = INTFSLWorkorderIntake.createCallComments(comments,woRec.id,caseRec.id);
        Test.stopTest();
        
        System.assertEquals(false, returnedList.isEmpty(), 'createCallComments_2_TEST: Returned list is empty');
        
    }
    
}