@isTest
public class BackOfficeReimbursementBatchTest {
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

        insert new List<Account>{
            new Account(
                FirstName = 'Fred',
                LastName = 'Smith',
                Phone = '1234567890',
                RecordTypeId = acgMember.Id,
                BillingStreet = '3305 Hutchinson Road Apt 5203; Apt 234',
                BillingCity = 'Cumming',
                BillingStateCode = 'GA',
                BillingCountryCode = 'US',
                BillingPostalCode = '30040',
                PersonHomePhone = '1234567890',
                ACG_Alternate_Phone__c = '1234567890',
                ACG_Date_of_Birth__c = Date.today(),
                ACG_Address_Type_Detail__c = 'U.S.',
                Member_ID__c = '6202404941373216'
            ),
            new Account(
                FirstName = 'Test1',
                LastName = 'Test1',
                Phone = '1234567891',
                RecordTypeId = acgMember.Id,
                Member_ID__c = '6202404941373217'
            )
        };
    }
   
    @isTest
    static void paymentCreationBatchTest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
        Boolean isNEOrg = orgData.Name == 'AAA Northeast';
        Account acct1 = [SELECT Id, FirstName, LastName, Member_ID__c, Phone FROM Account WHERE Member_ID__c = '6202404941373217' LIMIT 1];

        if (!isNEOrg) {
            insert new BackOffice_Settings__c(
                Club_Code__c = '212'
            );
        }

        // Test.start / stop required due to 'populateMemberInfo'
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

        // Create the Allocations__c
        if (isNEOrg) {
            insert new List<Allocations__c>{
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'BASIC',
                    Approved__c  = 100.00
                ),
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'OTHER',
                    Other_Account__c = 'BATT WAR AGM',
                    Approved__c  = 50.00
                ),
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'PLUS',
                    Approved__c = 200.00
                )
            };
        } else {
            insert new List<Allocations__c>{
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'OTHER',
                    Other_Account__c = 'GOOD_WILL',
                    Approved__c  = 100.00
                ),
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'OTHER',
                    Other_Account__c = 'BATT_WAR_AGM',
                    Approved__c  = 50.00
                ),
                new Allocations__c(
                    Reimbursement__c = rem.Id,
                    Account__c = 'OTHER',
                    Other_Account__c = 'BASIC_LKSMTH',
                    Approved__c = 200.00
                )
            };
        }
        
        BackOfficeReimbursementBatch batch = new BackOfficeReimbursementBatch();

        Database.executeBatch(batch);
        Test.stopTest();

        List<Payment__c> payments = [
            SELECT Id, Vendor_Name__c, Spend_Category__c, Amount__c 
            FROM Payment__c
            ORDER BY Amount__c
        ];
        ACG_Reimbursement__c rmb = [
            SELECT Id, ACG_Status__c
            FROM ACG_Reimbursement__c
            WHERE Id = :rem.Id
        ];

        System.assertEquals(3, payments.size(), 'Failed to create Payment records.');
        System.assertEquals(50.0, payments[0].Amount__c, 'Failed to assign proper Amount.');
        System.assertEquals(100.0, payments[1].Amount__c, 'Failed to assign proper Amount.');
        System.assertEquals(200.0, payments[2].Amount__c, 'Failed to assign proper Amount.');
        System.assertEquals('Ready for Payment', rmb.ACG_Status__c, 'Failed to update Reimbursement.');
    }
}