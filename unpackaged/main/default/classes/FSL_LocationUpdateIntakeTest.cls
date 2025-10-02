@isTest
public class FSL_LocationUpdateIntakeTest {

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
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    @isTest
    static  void TestUpsertServiceAppointment() {
        
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        FSL_WorkOrderResponse woObj = FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');

        Test.startTest();
        
        
        //StaticResource srWo = [select id, body from StaticResource where name = 'TowCallforLocationUpdate'];
        
        // FSL_JSonParserWorkOrder jsonParser  = (FSL_JSonParserWorkOrder)Json.deserialize(srWo.body.toString(),FSL_JSonParserWorkOrder.class);   
        // system.debug('facility Id : '+jsonParser.calls[0].service.facility.id);
        
        
        // HttpCalloutMock mock = new Util_ManageAccessTokensTest.MockAccessTokenGenerator(); 
        // Test.setMock(HttpCalloutMock.class, mock);
        
        System.debug('woObj Work Order Number : '  + woObj.WorkOrderNumber+' woObj External ID : '  + woObj.callKey);        
        system.debug('workOrderNumber : '+woObj.workOrderNumber);
        system.debug('id : '+woObj.HEADER.id);
        //ServiceTerritory woTerritory =
        system.debug('wo : '+[SELECT Id, External_Id__c FROM WorkOrder WHERE External_Id__c =: woObj.callKey]);
        String callKey = woObj.callKey;
        
        StaticResource sr = [select id, body from StaticResource where name = 'LocationUpdate'];
        
        
        system.debug('callKey : '+callKey);
        FSL_JSONParserLocationUpdates jsonWorkOrder = (FSL_JSONParserLocationUpdates)Json.deserialize(sr.body.toString(), FSL_JSONParserLocationUpdates.class);
        
        List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
        List<ServiceTerritory> ServiceTerritories = Test.loadData(ServiceTerritory.sobjectType, 'Location_Territory');
        ServiceTerritories[0].Facility_Number__c = jsonWorkOrder.calls[0].service.facility.id;
        update ServiceTerritories;
        system.debug('ServiceTerritories[0].Facility_Number__c : '+ServiceTerritories[0].Facility_Number__c);
        
        
        jsonWorkOrder.calls[0].callKey = callKey;
        system.debug('jsonWorkOrder.calls[0].callKey : '+jsonWorkOrder.calls[0].callKey);
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        
        //System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_LocationUpdateIntake.UpsertServiceAppointment();
        system.assertEquals('200', resp.statusCode);
        system.assertEquals(callKey, resp.callKey);
        //System.Test.StopTest();
        
        test.stopTest();
    }  
    
    static testMethod void TestUpsertServiceAppointmentNoWorkOrder() {
        
        test.startTest();
        
        StaticResource srWo = [select id, body from StaticResource where name = 'TowCallforLocationUpdate'];
        
        FSL_JSonParserWorkOrder jsonParser  = (FSL_JSonParserWorkOrder)Json.deserialize(srWo.body.toString(),FSL_JSonParserWorkOrder.class);   
        system.debug('facility Id : '+jsonParser.calls[0].service.facility.id);
        
        
        
        FSL_WorkOrderResponse woObj = FSL_DataFactory.createWOIntakeCall('TowCallforLocationUpdate');
        System.debug('woObj Work Order Number : '  + woObj.WorkOrderNumber+' woObj External ID : '  + woObj.callKey);        
        system.debug('workOrderNumber : '+woObj.workOrderNumber);
        system.debug('id : '+woObj.HEADER.id);
        //ServiceTerritory woTerritory =
        system.debug('wo : '+[SELECT Id, External_Id__c FROM WorkOrder WHERE External_Id__c =: woObj.callKey]);
        String callKey = woObj.callKey;
        
        StaticResource sr = [select id, body from StaticResource where name = 'LocationUpdate'];
        
        
        system.debug('callKey : '+callKey);
        FSL_JSONParserLocationUpdates jsonWorkOrder = (FSL_JSONParserLocationUpdates)Json.deserialize(sr.body.toString(), FSL_JSONParserLocationUpdates.class);
        
        List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
        List<ServiceTerritory> ServiceTerritories = Test.loadData(ServiceTerritory.sobjectType, 'Location_Territory');
        ServiceTerritories[0].Facility_Number__c = jsonWorkOrder.calls[0].service.facility.id;
        update ServiceTerritories;
        system.debug('ServiceTerritories[0].Facility_Number__c : '+ServiceTerritories[0].Facility_Number__c);
        
        
        jsonWorkOrder.calls[0].callKey = 'Invalid_Key';
        system.debug('jsonWorkOrder.calls[0].callKey : '+jsonWorkOrder.calls[0].callKey);
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        //System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_LocationUpdateIntake.UpsertServiceAppointment();
        system.assertEquals('400', resp.statusCode);
        system.assertEquals('Invalid_Key', resp.callKey);
        //System.Test.StopTest();
        
        test.stopTest();
    }  
    static testMethod void TestUpsertServiceAppointmentInvalidJSON() {
        
        test.startTest();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('');
        
        RestContext.request = req;
        RestContext.response= res;
        
        //System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_LocationUpdateIntake.UpsertServiceAppointment();
        system.assertEquals('400', resp.statusCode);
        //system.assertEquals('Invalid_Key', resp.callKey);
        //System.Test.StopTest();
        
        test.stopTest();
    }
}