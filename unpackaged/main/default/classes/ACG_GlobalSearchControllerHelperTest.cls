/*
``@description: Test class for ACG_GlobalSearchControllerHelper Logic
  @date: DEC 01, 2023
  @author: Salesforce Services
*/
@isTest
public with sharing class ACG_GlobalSearchControllerHelperTest {
    @testSetup
    public static void testSetup() {
        doTestSetup();
    }
    @isTest
    public static void doTestSetup(){
        Id caserecid=Schema.SObjectType.Case.getRecordTypeInfosByName().get('ERS').getRecordTypeId();
        Case cs=ACG_TestDataFactory.createcase(caserecid,'Spotted','Web',true);
        Id worecid=Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
        Workorder wo=new workorder();
        wo.RecordTypeId=worecid;
        wo.CaseId=cs.id;
        insert wo;
    }
    @isTest
    public static void doLookupApiActiveTest() { 
        try{
            Workorder wo=[SELECT id,caseid from workorder limit 1];
            case caseobj=[SELECT id from case limit 1];
            String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6502404416510202", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": true, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';
            Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res));
            test.startTest();
                INTMembershipLookupResponse_Wrapper responseWrapper=(INTMembershipLookupResponse_Wrapper)JSON.deserialize(res, INTMembershipLookupResponse_Wrapper.class);
                system.debug('responseWrapper '+responseWrapper);
                ACG_GlobalSearchController.MbrValAPIWrapper mwrap = ACG_GlobalSearchControllerHelper.performUpsertOnLookupRecord('6502404416510202', responseWrapper, '76823683');
                system.assertNotEquals(mwrap.inMemberContract, null);
            test.stopTest();
        }
        catch(Exception ex){
            system.debug(ex.getMessage());
        }
    } 
    
    @isTest
    public static void doLookupApiNonLocalTest() { 
        try{
            Workorder wo=[SELECT id,caseid from workorder limit 1];
            case caseobj=[SELECT id from case limit 1];
            String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6202770085890052", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": false, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';
            Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res));
            test.startTest();
                INTMembershipLookupResponse_Wrapper responseWrapper=(INTMembershipLookupResponse_Wrapper)JSON.deserialize(res, INTMembershipLookupResponse_Wrapper.class);
                system.debug('responseWrapper '+responseWrapper);
                ACG_GlobalSearchController.MbrValAPIWrapper mwrap = ACG_GlobalSearchControllerHelper.performUpsertOnLookupRecord('6202770085890052', responseWrapper, '76823683');
                system.assertEquals(mwrap.inMemberContract, null);
            test.stopTest();
        }
        catch(Exception ex){
            system.debug(ex.getMessage());
        }
    } 
}