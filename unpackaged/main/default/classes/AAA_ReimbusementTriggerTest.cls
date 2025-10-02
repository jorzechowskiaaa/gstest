@isTest
class AAA_ReimbusementTriggerTest {
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

    @TestSetup
    static void createTestData() {
        RecordType acgMember = [SELECT Id FROM RecordType WHERE DeveloperName = 'ACG_Member' LIMIT 1];

        insert new Account(
            FirstName = 'Test',
            LastName = 'Test',
            Phone = '1234567890',
            RecordTypeId = acgMember.Id,
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '6202404941373216'
        );

        insert new Account(
            FirstName = 'Test1',
            LastName = 'Test1',
            Phone = '1234567891',
            RecordTypeId = acgMember.Id,
            Member_Card_Num__pc = '6202405941374444',
            Member_ID__c = '620240594137444'
        );
    }

    @isTest
    static void populateMemberInfoTest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());

        Account acct1 = [SELECT Id, FirstName, LastName, Member_ID__c, Phone FROM Account WHERE Member_ID__c = '620240594137444' LIMIT 1];
        Account acct2 = [SELECT Id, FirstName, LastName, Member_ID__c, Phone FROM Account WHERE Member_ID__c = '6202404941373216' LIMIT 1];

        // Test.start / stop required due to 'populateMemberInfo'
        // using '@future (callout = true)'
        Test.startTest();
        ACG_Reimbursement__c rem = new ACG_Reimbursement__c(
            ACG_Member_Name__c = acct1.Id,
            Member_Id__c = acct1.Member_ID__c
        );
        insert rem;

        rem.ACG_Member_Name__c = acct2.Id;
        update rem;
        Test.stopTest();

        ACG_Reimbursement__c resultRem = [
                SELECT 
                    Id, First_Name__c, Last_Name__c, Phone__c, Member_Id__c, ACG_Member_Name__c, ACG_Date_Received__c
                FROM ACG_Reimbursement__c 
                WHERE Id =: rem.Id
        ];
        
        System.assertEquals(acct2.FirstName, resultRem.First_Name__c, 'Member First Name information on Reimbursement does not match Account First Name.');
    }

    @isTest
    static void validateAltAddressTest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        Account acct1 = [SELECT Id, FirstName, LastName, Member_ID__c, Phone FROM Account WHERE Member_ID__c = '620240594137444' LIMIT 1];
        Boolean hasError = false;
        String validationError = 'Alternative Address information must be filled if "Use Alternative Address" is checked.';
    
        try {
            Test.startTest();
            ACG_Reimbursement__c rem = new ACG_Reimbursement__c(
                ACG_Member_Name__c = acct1.Id,
                Member_Id__c = acct1.Member_ID__c,
                Use_Alternative_Address__c = true,
                Alt_First_Name__c = 'Johnny',  
                Alt_Last_Name__c = 'Doe Jr.',
                ACG_Email__c = 'test@test.com',
                Email_Confirmed__c = true,
                Address__c = '123 Main St',  
                Alt_Street_Address__c = '456 Elm St',  
                Alt_City__c = 'New York',  
                Alt_Zip__c = '54321',  
                Alt_State__c = 'NY',
                ACG_Status__c = 'Decision Approved'
            );
            insert rem;

            rem.Alt_State__c = '';
            update rem;
            Test.stopTest();
        } catch (Exception e) {
            if (e.getMessage().contains(validationError)) {
                hasError = true;
            }
        }
        
        System.assertEquals(true, hasError, 'Failed to validate field.');
    }
}