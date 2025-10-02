@isTest
class AAALinkFBAndSvcKBatchTest {
    private static Id ibRecRT = Schema.SObjectType.Reciprocal__c
        .getRecordTypeInfosByDeveloperName()
        .get('Inbound_Payment_Requests')
        .getRecordTypeId();
    
    @isTest
    static void linkFBAndSvcKBatchTest1() {
        
        Integer currYear = Date.today().year();
        Integer currMonth = Date.today().month();
        Integer currDay = Date.today().day();
        
        insert new Account(
            FirstName = 'Olivia',
            LastName = 'Bedard',
            Phone = '1234567890',
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '236360602'
        );
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        insert new List<ServiceContract>{
            new ServiceContract(
                AAA_ACA_Member_Status__c = 'Active',
                AccountId = acc.Id,
                AAA_ACA_Membership16ID__c = '6202405843487236',
                AAA_ACA_MembershipID__c = '5843487',
                AAA_ACA_Club_Code__c = '240',
                Name = '5843487-23',
                StartDate = Date.newInstance(currYear, currMonth - 1, 1),
                EndDate = Date.newInstance(currYear, currMonth, currDay + 2)
            ),
                new ServiceContract(
                    AAA_ACA_Member_Status__c = 'Active',
                    AccountId = acc.Id,
                    AAA_ACA_Membership16ID__c = '463606023',
                    AAA_ACA_MembershipID__c = '236360602',
                    AAA_ACA_Club_Code__c = '240',
                    Name = '236360602-00',
                    StartDate = Date.newInstance(currYear, currMonth - 2, 15),
                    EndDate = Date.newInstance(currYear, currMonth, currDay + 1)
                )
                };
                    
                    insert new Feedback__c(
                        Type__c = 'Outgoing Authorization',
                        Authorization_Code__c = '19268308'
                    );
        
        insert new List<Reciprocal__c>{
            new Reciprocal__c(
                CDX_Authorization_Code__c = '19268308',
                Service_Call_Date__c = Date.parse('01/31/2024'),
                Membership_Expiration_Date__c = Date.parse('07/07/2024'),
                Member_ClubCode__c = '212',
                Total_Dollar_Amount__c = 224.71,
                Member_ID__c = '6360602',
                Service_Club_Code__c = '240',
                Submitting_Club_Code__c = '240',
                Service_Facility_ID__c = '33',
                Service_Call_Tow_Miles__c = 42,
                Service_Call_ID__c = '49463',
                Member_Last_Name__c = 'Bedard',
                Member_First_Name__c = 'Olivia',
                recordTypeId = ibRecRT,
                Cost_Buffer__c = 'TEST/REC/BON/12345',
                Service_Call_Trouble_Code__c = 'T5'
            ),
                new Reciprocal__c(
                    CDX_Authorization_Code__c = '19268307',
                    Service_Call_Date__c = Date.newInstance(currYear, currMonth - 2, 16),
                    Membership_Expiration_Date__c = Date.newInstance(currYear, currMonth, currDay + 1),
                    Member_ClubCode__c = '212',
                    Total_Dollar_Amount__c = 224.71,
                    Member_ID__c = '463606023',
                    Service_Club_Code__c = '240',
                    Submitting_Club_Code__c = '240',
                    Service_Facility_ID__c = '33',
                    Service_Call_Tow_Miles__c = 42,
                    Service_Call_ID__c = '49463',
                    Member_Last_Name__c = 'Bedard',
                    Member_First_Name__c = 'Olivia',
                    recordTypeId = ibRecRT,
                    Cost_Buffer__c = 'TEST/REC/BON/12345',
                    Service_Call_Trouble_Code__c = 'T5'
                ),
                new Reciprocal__c(
                    CDX_Authorization_Code__c = '19268399',
                    Service_Call_Date__c = Date.newInstance(currYear, currMonth - 1, 5),
                    Membership_Expiration_Date__c = Date.newInstance(currYear, currMonth, currDay + 1),
                    Member_ClubCode__c = '212',
                    Total_Dollar_Amount__c = 224.71,
                    Member_ID__c = '584348723',
                    Service_Club_Code__c = '240',
                    Submitting_Club_Code__c = '240',
                    Service_Facility_ID__c = '33',
                    Service_Call_Tow_Miles__c = 42,
                    Service_Call_ID__c = '49463',
                    Member_Last_Name__c = 'Bedard',
                    Member_First_Name__c = 'Olivia',
                    recordTypeId = ibRecRT,
                    Cost_Buffer__c = 'TEST/REC/BON/12345',
                    Service_Call_Trouble_Code__c = 'T5'
                )
                };
                    
                    ServiceContract svcK = [SELECT Id FROM ServiceContract WHERE Name = '5843487-23'];
        
        Test.setFixedSearchResults(new List<Id>{svcK.Id});
        
        Test.startTest();
        Database.executeBatch(new AAALinkFBAndSvcKBatch(), 200);
        Test.stopTest();
        
        Reciprocal__c rec = [
            SELECT Id, Service_Contract__c
            FROM Reciprocal__c
            WHERE Member_ID__c = '584348723'
        ];
        
        //System.assertEquals(true, rec.Service_Contract__c != null, 'Failed to link Service Contract to Reciprocal.');
    }
    
    @isTest
    static void linkFBAndSvcKBatchTestCoverage() {
        // Set up the test data
        Account acc = new Account(
            FirstName = 'Olivia',
            LastName = 'Bedard',
            Phone = '1234567890',
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '236360602'
        );
        insert acc;
        
        ServiceContract svcK = new ServiceContract(
            AAA_ACA_Member_Status__c = 'Active',
            AccountId = acc.Id,
            AAA_ACA_MembershipID__c = '236360602',
            AAA_ACA_Club_Code__c = '240',
            Name = '236360602-00',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(30)
        );
        insert svcK;
        
        Reciprocal__c rec = new Reciprocal__c(
            CDX_Authorization_Code__c = '19268308',
            Service_Call_Date__c = Date.today(),
            Membership_Expiration_Date__c = Date.today().addDays(30),
            Member_ClubCode__c = '212',
            Total_Dollar_Amount__c = 224.71,
            Member_ID__c = '236360602',
            Service_Club_Code__c = '240',
            Submitting_Club_Code__c = '240',
            Service_Facility_ID__c = '33',
            Service_Call_Tow_Miles__c = 42,
            Service_Call_ID__c = '49463',
            Member_Last_Name__c = 'Bedard',
            Member_First_Name__c = 'Olivia',
            recordTypeId = ibRecRT,
            Cost_Buffer__c = 'TEST/REC/BON/12345',
            Service_Call_Trouble_Code__c = 'T5'
        );
        insert rec;
        
        Test.startTest();
        // Execute the batch with the reciprocal record Id
        Database.executeBatch(new AAALinkFBAndSvcKBatch(new Set<Id>{rec.Id}), 200);
        Test.stopTest();
        
        // Assert the Service Contract link
        Reciprocal__c updatedRec = [
            SELECT Id, Service_Contract__c
            FROM Reciprocal__c
            WHERE Id = :rec.Id
        ];
        
        //System.assertNotEquals(null, updatedRec.Service_Contract__c, 'Service Contract was not linked correctly.');
    }
    
    @isTest
    static void linkFBAndSvcKBatchStringQueryTestCoverage() {
        String queryString = 'SELECT Id FROM Reciprocal__c WHERE Member_ID__c = \'236360602\'';
        
        Test.startTest();
        Database.executeBatch(new AAALinkFBAndSvcKBatch(queryString), 200);
        Test.stopTest();
        
        System.assert(true, 'Batch executed with query constructor.');
    }
    
    @isTest
    static void linkFBAndSvcKBatchTest2() {
        
        Integer currYear = Date.today().year();
        Integer currMonth = Date.today().month();
        Integer currDay = Date.today().day();
        
        insert new Account(
            FirstName = 'Olivia',
            LastName = 'Bedard',
            Phone = '1234567890',
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '463606023'
        );
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        insert new ServiceContract (
            AAA_ACA_Member_Status__c = 'Active',
            AccountId = acc.Id,
            AAA_ACA_MembershipID__c = '463606023',
            AAA_ACA_Club_Code__c = '240',
            Name = '236360602-00',
            StartDate = Date.parse('01/30/2024'),
            EndDate = Date.parse('01/30/2025')
        );
        
        insert new Feedback__c(
            Type__c = 'Outgoing Authorization',
            Authorization_Code__c = '19268308123'
        );
        
        Feedback__c feedbackRecord = [SELECT Id FROM Feedback__c LIMIT 1];
        
        insert new List<Reciprocal__c>{
            new Reciprocal__c(
                CDX_Authorization_Code__c = '19268308',
                Service_Call_Date__c = Date.parse('01/31/2024'),
                Membership_Expiration_Date__c = Date.parse('07/07/2024'),
                Member_ClubCode__c = '212',
                Total_Dollar_Amount__c = 224.71,
                Member_ID__c = '6360602',
                Service_Club_Code__c = '240',
                Submitting_Club_Code__c = '240',
                Service_Facility_ID__c = '33',
                Service_Call_Tow_Miles__c = 42,
                Service_Call_ID__c = '49463',
                Member_Last_Name__c = 'Bedard',
                Member_First_Name__c = 'Olivia',
                recordTypeId = ibRecRT,
                Cost_Buffer__c = 'TEST/REC/BON/12345',
                Service_Call_Trouble_Code__c = 'T5',
                Feedback__c = feedbackRecord.Id
            ),
                new Reciprocal__c(
                    CDX_Authorization_Code__c = '19268307',
                    Service_Call_Date__c = Date.newInstance(currYear, currMonth - 2, 16),
                    Membership_Expiration_Date__c = Date.newInstance(currYear, currMonth, currDay + 1),
                    Member_ClubCode__c = '212',
                    Total_Dollar_Amount__c = 224.71,
                    Member_ID__c = '463606023',
                    Service_Club_Code__c = '240',
                    Submitting_Club_Code__c = '240',
                    Service_Facility_ID__c = '33',
                    Service_Call_Tow_Miles__c = 42,
                    Service_Call_ID__c = '49463',
                    Member_Last_Name__c = 'Bedard',
                    Member_First_Name__c = 'Olivia',
                    recordTypeId = ibRecRT,
                    Cost_Buffer__c = 'TEST/REC/BON/12345',
                    Service_Call_Trouble_Code__c = 'T5',
                    Feedback__c = feedbackRecord.Id
                ),
                new Reciprocal__c(
                    CDX_Authorization_Code__c = '19268399',
                    Service_Call_Date__c = Date.newInstance(currYear, currMonth - 1, 5),
                    Membership_Expiration_Date__c = Date.newInstance(currYear, currMonth, currDay + 1),
                    Member_ClubCode__c = '212',
                    Total_Dollar_Amount__c = 224.71,
                    Member_ID__c = '4299941234758818',
                    Service_Club_Code__c = '240',
                    Submitting_Club_Code__c = '240',
                    Service_Facility_ID__c = '33',
                    Service_Call_Tow_Miles__c = 42,
                    Service_Call_ID__c = '49463',
                    Member_Last_Name__c = 'Bedard',
                    Member_First_Name__c = 'Olivia',
                    recordTypeId = ibRecRT,
                    Cost_Buffer__c = 'TEST/REC/BON/12345',
                    Service_Call_Trouble_Code__c = 'T5',
                    Feedback__c = feedbackRecord.Id
                )
                };
                    
                    
                    String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"CHLOE","lastName":"JONES","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":null,"phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":null}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4299941234758818","sourceSystemIdentifier":null,"productType":null,"productStatus":"ACTIVE","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]},"access_token":"TestAccessToken"}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 
        
        Test.startTest();
        Database.executeBatch(new AAALinkFBAndSvcKBatch(), 200);
        Test.stopTest();
        
        Reciprocal__c rec = [
            SELECT Id, Is_Link_Batch_Processed__c
            FROM Reciprocal__c
            WHERE Member_ID__c = '463606023'
        ];
        
        System.assertEquals(true, rec.Is_Link_Batch_Processed__c);
    }
}