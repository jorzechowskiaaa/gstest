@isTest
public class ReciprocalServiceContractLkpQbleTest {
    @isTest
    static void getReciprocalAttributes() {
        //Create Reciprocal
        Reciprocal__c rec = new Reciprocal__c(
            CDX_Authorization_Code__c = '19268307',
            Service_Call_Date__c = Date.parse('01/31/2024'),
            Membership_Expiration_Date__c = Date.parse('07/07/2024'),
            Member_ClubCode__c = '212',
            Total_Dollar_Amount__c = 224.71,
            Member_ID__c = '236360602',
            Service_Club_Code__c = '240',
            Submitting_Club_Code__c = '240',
            Service_Facility_ID__c = '33',
            Service_Call_Tow_Miles__c = 42,
            Service_Call_ID__c = '49463',
            Member_Last_Name__c = 'Bedard',
            Member_First_Name__c = 'Olivia'
        );
        
        insert new Account(
            FirstName = 'Olivia',
            LastName = 'Bedard',
            Phone = '1234567890',
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '236360602'
        );
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        insert new ServiceContract (
            AAA_ACA_Member_Status__c = 'Active',
            AccountId = acc.Id,
            AAA_ACA_MembershipID__c = '236360602',
            AAA_ACA_Club_Code__c = '240',
            Name = '236360602-00',
            StartDate = Date.parse('01/30/2024'),
            EndDate = Date.parse('01/30/2025')
        );

        ServiceContract sc = [SELECT Id FROM ServiceContract LIMIT 1];
        String results = '{"Results":{"accountId":"001Ea00000JbX7OIAV", "contract":{"ContractWrapper":{"callsAllowed":"5", "callsRemaining":"5", "contractEndDate":"7/1/2024", "contractId":"810Ea00000OgYKSIA3", "contractStartDate":"7/2/2023", "sameDayService":"null"}}, "entitlement":"null", "impairmentType":"", "isLocalClub":"true", "isLookupSuccess":"true", "searchResults":"null", "updatedRecordId":"001Ea00000JbX7OIAV", "warningMessage":""}}';
        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "236360602", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"Olivia","lastName":"Bedard","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';
        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res));
        
        Test.startTest();
        try {
            insert rec;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        List<Reciprocal__c> recList = [SELECT Member_Id__c FROM Reciprocal__c LIMIT 1];
        Map<Id, Reciprocal__c> recMap = new Map<Id, Reciprocal__c>(recList);

        try {
        	System.enqueueJob(new ReciprocalServiceContractLkpQueueable(recMap));
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }
}