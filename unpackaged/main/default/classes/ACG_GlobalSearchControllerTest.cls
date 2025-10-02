/************************************************************************************
Apex Class Name     : ACG_GlobalSearchControllerTest
Created Date        : 9th May 2024
Function            : Test Aura Enabled Class for ACGGlobalSearch LWC
Author              : Salesforce Inc. 
*************************************************************************************/
@isTest
public class ACG_GlobalSearchControllerTest {
    @testSetup
    public static void testSetup() { 
        RecordType acctType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'ACG_Member' 
            AND SobjectType = 'Account' 
            LIMIT 1
        ];

        insert new Account(
            AAA_Membership_Level__c = 'Basic',
            ACG_AAA_Membership__c = '6202404941373217',
            ACG_Club__C = '240',
            ACG_Email__c = '12345@test.com',
            PersonEmail = '12345@test.com', 
            ACG_Club_Name__c = 'AAA South Central New England',
            ACG_Entitlements_Allotted__c = 4,
            ACG_Membership_Status__c = 'Active',
            ACG_Priority_Service__c = false,
            ACG_SMS_Opt_In__c = false,
            BillingCity = 'TEMPLETON',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            BillingPostalCode = '01468',
            BillingState = 'MA',
            BillingStateCode = 'MA',
            BillingStreet = '2914341 MAIN ST',
            CDX_Membership_Status__c = 'Active',
            CDX_Motorcycle_Coverage__c = false,
            FirstName = 'APEX0513',
            LastName = 'TEST0513',
            Member_Card_Num__pc = '6202404941373217',
            Member_ID__c = '6202404941373216',
            Membership_Level__pc = 'BASIC',
            Membership_Org__pc = 'EDS',
            Membership_OrgCode__pc = '240',
            Membership_Program__pc = '00000109',
            Membership_Service_Charge_Indicator__pc = false,
            Membership_Sponsor__pc = '00000035',
            Membership_Status__pc = 'ACTIVE',
            Membership_Type__pc = 'Associate Member',
            PersonHomePhone = '9785552168',
            PersonMobilePhone = '9785552168',
            Phone = '9785552168',
            Phone_Type__pc = 'CELLULAR',
            RecordTypeId = acctType.Id,
            Sms_Optin__pc = false,
            Type__pc = 'CUSTOMER',
            X200_Mile_Tow_Used__c = false
        );
    }
    
    // This method tests GetAccountRecortype method from ACG_GlobalSearchController class.The method expects recordtype is of account object.  
    @isTest
    static void testGetAccountRecordType() {
        Map<String,Object> AccountRecordType = ACG_GlobalSearchController.getAccountRecordType();
        recordType recType = (recordType) AccountRecordType.values()[0];
        recordType accountRecType = [
            SELECT SobjectType 
            FROM RecordType 
            WHERE Id = :recType.Id
        ];    

        Assert.areEqual('Account', accountRecType.SobjectType, 'Record types is of not Account Object');       
    }

    // This method tests getclubNames method. 
    @isTest
    static void testgetClubNames() {
        Map<String, AAA_Club_Details__mdt> clubMap = ACG_GlobalSearchController.getClubNames();

        Assert.isNotNull(clubMap, 'AAA_Club_Details__mdt does not have values');
    }

    // This method tests getMembershipUnavailableReasons method. 
    @isTest
    static void testgetMembershipUnavailableReasons() {
        Map<String, ERS_Membership_Unavailable_Reason__mdt> ersMap = ACG_GlobalSearchController.getMembershipUnavailableReasons();
        
        Assert.isNotNull(ersMap, 'ERS_Membership_Unavailable_Reason__mdt does not have values');
    }

    // This method tests insertCustomer record method.
    @isTest
    static void testInsertCustomerRecord() {
        Assert.isNotNull(
            ACG_GlobalSearchController.insertCustomerRecord(
                new Account(
                    Name = 'ACG_GlobalSearchControllerTest'
                )
            ), 
            'Account record NOT created'
        );

        Assert.isNull(ACG_GlobalSearchController.insertCustomerRecord(new Account()), 'Account record created with null values');
    }

    // This method tests getProfileNamesforLocalSearch method. 
    @isTest
    static void testgetProfileNamesForLocalSearch() {
        Functionality_vs_Profile_Access__mdt fpa1 =  new Functionality_vs_Profile_Access__mdt(
            DeveloperName = 'Local_Search',
            Profile_List__c = 'Test Profile1,Test Profile2'
        );
        List<String> profileNames = ACG_GlobalSearchController.getProfileNamesForLocalSearch();
        Functionality_vs_Profile_Access__mdt fpa = [
            SELECT 
                Id, 
                MasterLabel, 
                DeveloperName, 
                Profile_List__c, 
                QualifiedApiName 
            FROM Functionality_vs_Profile_Access__mdt
            WHERE DeveloperName = 'Local_Search' 
            LIMIT 1
        ];

        for (String profileName : profileNames) {
            Assert.isTrue(fpa.Profile_List__c.contains(profileName), 'Profile for local search is missing');
        }
    }
    
    // This method tests getTravelProfileNames method. 
    @isTest
    static void testgetTravelProfileNames() {
        Functionality_vs_Profile_Access__mdt fpa1 =  new Functionality_vs_Profile_Access__mdt(
            DeveloperName = 'Travel_Profiles',
            Profile_List__c = 'Test Profile1,Test Profile2'
        );
        List<String> profileNames = ACG_GlobalSearchController.getTravelProfileNames();

        Functionality_vs_Profile_Access__mdt fpa = [
            SELECT 
                Id, 
                MasterLabel, 
                DeveloperName, 
                Profile_List__c,
                QualifiedApiName 
            FROM Functionality_vs_Profile_Access__mdt
            WHERE DeveloperName = 'Travel_Profiles' 
            LIMIT 1
        ];

        for (String profileName : profileNames) {
            Assert.isTrue(fpa.Profile_List__c.contains(profileName), 'Profile for Travel_Profiles is missing');
        }
    }

    // This method tests invokeMembershipSearchAPI method.
    static void testinvokeMembershipSearchAPI() {
        Account member1 = [
            SELECT 
                Id, ACG_AAA_Membership__c, Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];

        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 

        Test.setMock(HttpCalloutMock.class, searchmock);

        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6502404416510202", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": true, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';   

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,200)); 

        try { 
           ACG_GlobalSearchController.Results result2 = ACG_GlobalSearchController.invokeMembershipSearchAPI(getRequestMap(member1));
        } catch(Exception e) {
         	System.assertEquals('Script-thrown exception', e.getMessage(), '');
        }
        Test.stopTest(); 
    }
    
    // This method tests GetLocalSearchResults method.
    @isTest
    static void testGetLocalSearchResults() {
        Account member1 = [
            SELECT 
                Id, ACG_AAA_Membership__c, Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];
        
        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 

        Test.setMock(HttpCalloutMock.class, searchmock);

        String res = '{"responseHeaders": {"tranId": "111111","tranCode": "404","tranStatus": "SUCCESS","timeStamp": "2021-09-06T10:26:33.848-04:00","tranStatusDescription": "Record Not Found"}}';

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,404)); 

        try {
            ACG_GlobalSearchController.Results membershipSearch = 
                ACG_GlobalSearchController.invokeMembershipAPIs(
                    'search', 
                    new Map<String, String>{
                        'MSsearchByNameZip_fName' => 'CHLOE',
                        'MSsearchByNameZip_lName' => 'JONES',
                        'MSsearchByNameZip_zip' => '01004',
                        'MSsearchByNameZip_clubCode' => '994'
                    },
                    'GUID_API'
                );      
        } catch(Exception e) {
            System.debug('Exception at testGetLocalSearchResults ' + e.getMessage());
        }
        Test.stopTest(); 
    }

    @isTest
    // This method tests invokeMembershipAPIsLookup method.
    static void testinvokeMembershipAPIsLookup() {
        Account member1 = [SELECT Id,ACG_AAA_Membership__c,Member_ID__c FROM account WHERE FirstName = 'APEX0513' AND LastName = 'TEST0513' AND Member_Card_Num__pc = '6202404941373217' AND Member_ID__c = '6202404941373216' LIMIT 1];
        
        Test.startTest();
        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"CHLOE","lastName":"JONES","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":null,"phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":null}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4299941234758818","sourceSystemIdentifier":null,"productType":null,"productStatus":"ACTIVE","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]},"access_token":"TestAccessToken"}';

        Test.setMock(HttpCalloutMock.class, new RestServiceMock_TEST(res)); 

        try {
            ACG_GlobalSearchController.Results membershipLookup = 
                ACG_GlobalSearchController.invokeMembershipAPIs(
                    'lookup',
                    new Map<String,String>{
                        'memberId'=>'4299941234758818'
                    },
                    'GUID_API'
                );
        } catch(Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest(); 
    }
   
    @isTest
    static void testAPICalloutResponseWrapper() {
        String res = '{"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"S","timeStamp":"2019-11-18T08:23:48-0500","tranStatusDescription":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res, 200)); 

        MembershipController.APICalloutResponseWrapper memWrapper = ACG_GlobalSearchController.cancelAXISFromSearchPage('', '1000170413');
        
        Assert.isNotNull(memWrapper,'Unexpected error occured in testAPICalloutResponseWrapper');
    }
    
    // This method tests local search funtionality.
    @isTest
    static void testGetLocalSearchResult() {
        Account member1 = [
            SELECT 
                Id,
                RecordType.DeveloperName,
                ACG_AAA_Membership__c,
                Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];

        Id [] fixedSearchResults= new Id[1];

        fixedSearchResults[0] = member1.Id;

        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 

        Test.setMock(HttpCalloutMock.class, searchmock);

        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6502404416510202", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": true, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';     

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,200));    

        try {
            ACG_GlobalSearchController.Results resultMemNumber = ACG_GlobalSearchController.getLocalSearchResults(getRequestMap(member1));
        } catch(Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest(); 
    }
    
    // This method tests local search funtionality when address type is Foreign.
    @isTest
    static void testGetLocalSearchResultForeign() {
        Account member1 = [
            SELECT 
                Id,RecordType.DeveloperName,ACG_AAA_Membership__c,ACG_Address_Type_Detail__c,Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];

        member1.ACG_Address_Type_Detail__c = 'Foreign';
        update member1;

        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 
        
        Test.setMock(HttpCalloutMock.class, searchmock); 
        
        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6502404416510202", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": true, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';    

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,200)); 

        try {
            ACG_GlobalSearchController.Results resultMemNumber = ACG_GlobalSearchController.getLocalSearchResults(getRequestMap(member1));
        } catch(Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), '');
        }
        Test.stopTest(); 
    }
    
    // This method tests local search funtionality when address type is Military.
    @isTest
    static void testGetLocalSearchResultMillitary() {
        Account member1 = [
            SELECT 
                Id,
                RecordType.DeveloperName,
                ACG_AAA_Membership__c,
                ACG_Address_Type_Detail__c,
                Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];

        member1.ACG_Address_Type_Detail__c = 'Military';
        update member1;

        Test.startTest();
        HttpCalloutMock searchmock = new MockMemberVerificationAPIs(); 

        Test.setMock(HttpCalloutMock.class, searchmock);

        String res = '{"responseHeaders":{"tranId":"123456789","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-13T12:38:01.16-04:00","tranStatusDescription":"Retrieved the member details successfully"},"customers":{"customer":[{"membershipId": "6502404416510202", "membershipType" : "Member", "memberLevel" : "Premier", "isLocalClub": true, "membershipStatus" : "Active","primaryMemberStartDate" : "2023-12-31","primaryMemberExpirationDate" : "2024-12-31","startDate" : "2023-12-31","memberSinceDate" : "2021-12-31", "expirationDate" : "2024-12-31", "pniFlag":null,"birthDate":null,"gender":null,"maritalStatus":null,"title":null,"firstName":"TestLook","lastName":"APITEST","otherName":null,"suffix":null,"licState":null,"mbrSuplTelNr":null,"mbrJnAaaDt":null,"mbrsPaidThruDt":null,"phone":[{"phoneType":"Work","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Home","phonNumber":"2234571803","isPrimary":null},{"phoneType":"Mobile","phonNumber":"2234571803","isPrimary":null}],"address":[{"addrType":null,"addressLine1":"112 Maple Lane","addressLine2":null,"city":"Riverside","state":"NY","postCode":"01004","county":null,"country":"USA"}],"productInfo":[{"isQuote":null,"subCompanyCd":null,"customerNumber":null,"productNumber":"4290041234758818","sourceSystemIdentifier":null,"productType":"MEM","productStatus":"ACTIVE","motorcycleCoverage":"true","membershipType":"B","associatedRoles":[{"role":null}],"productEffectiveDate":null,"productExpirationDate":"2025-12-31","producer":{"agentType":null,"agentNumber":null,"dofCode":null,"agentEmail":null,"agentPhoneNumber":null,"agentName":null,"agencyName":null},"addressDetail":[{"addrType":null,"addressLine1":null,"addressLine2":null,"city":null,"state":null,"postCode":null,"county":null,"country":null}],"productInceptionDate":null,"transactionApplicableDate":"20211231","pniClientId":null,"cancelReasonCode":null,"currentCarrierExpDate":null,"currentCarrier":null,"premierScore":null,"cancellationDate":null,"householdID":null}],"entitlement":{"callsAllowed":"4","longTowAllowed" : false},"authorize":{"returnCd":"0","level":"P","code":"210913163801","memberId":"12347588","longTowMiles":"100","longTowKilometers":"161","rentalDays":"2"}}]}}';   

        Test.setMock(HttpCalloutMock.class, new HttpRestCalloutMock(res,200)); 

        try {
            ACG_GlobalSearchController.Results resultMemNumber = ACG_GlobalSearchController.getLocalSearchResults(getRequestMap(member1));
        } catch(Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), '');
        }
        Test.stopTest(); 
    }
    
    // This method tests local search funtionality for various combination of input parameters.
    @isTest
    static void testLocalSearchResult1() {
        Account member1 = [
            SELECT 
                Id,
                RecordType.DeveloperName,
                ACG_AAA_Membership__c,
                ACG_Address_Type_Detail__c,
                Member_ID__c 
            FROM account 
            WHERE FirstName = 'APEX0513' 
            AND LastName = 'TEST0513' 
            AND Member_Card_Num__pc = '6202404941373217' 
            AND Member_ID__c = '6202404941373216' 
            LIMIT 1
        ];
        Id [] fixedSearchResults= new Id[1];

        fixedSearchResults[0] = member1.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        
        Map<String, String> mapRequestParamMemNumber = new Map<String, String>{
            'MSsearchByMemNumber_Memnum' => member1.ACG_AAA_Membership__c
        };
        ACG_GlobalSearchController.Results resultMemNumber = ACG_GlobalSearchController.getLocalSearchResults(mapRequestParamMemNumber);
        Map<String, String> mapRequestParamPhone = new Map<String, String>{
            'MSsearchByPhNumber_phnum' => '9785552168'
        };
        ACG_GlobalSearchController.Results resultPhone = ACG_GlobalSearchController.getLocalSearchResults(mapRequestParamPhone);
        Map<String, String> mapRequestParamEmail = new Map<String, String>{
            'MSsearchByEmailId_email' => '12345@test.com'
        };
        ACG_GlobalSearchController.Results resultEmail = ACG_GlobalSearchController.getLocalSearchResults(mapRequestParamEmail);
        Map<String, String> mapRequestParamZip = new Map<String, String>{
            'MSsearchByNameZip_zip' => '01004',
            'MSsearchByNameZip_fName' => 'APEX0513',
            'MSsearchByNameZip_lName' => 'TEST0513'
        };
        ACG_GlobalSearchController.Results resultZip = ACG_GlobalSearchController.getLocalSearchResults(mapRequestParamZip);
       
        try {
            ACG_GlobalSearchController.Results resultNull = ACG_GlobalSearchController.getLocalSearchResults(new Map<String, String>());
        } catch(Exception e) {
            System.debug('Exception =>'+ e.getMessage());
        }
    }

    @isTest
    static void resultsConstructorTest() {
        // TODO: FIND ASSERTION FOR TEST
        MembershipSearchRespJSONWrapper jsonMbrWrapper = new MembershipSearchRespJSONWrapper();
        jsonMbrWrapper.MembershipSearchResponse = new MembershipSearchRespJSONWrapper.MembershipSearchResponse();
        jsonMbrWrapper.MembershipSearchResponse.members = new List<MembershipSearchRespJSONWrapper.Members>();

        MembershipSearchRespJSONWrapper.Members mbr = new MembershipSearchRespJSONWrapper.Members();
        mbr.membershipNumber = '1234';
        mbr.lastName = 'TEST';
        mbr.firstName = 'APEX';
        mbr.adressLine1 = 'TEST APEX 4321 WAY';
        mbr.city = 'MARICOPA';
        mbr.state = 'CALIFORNIA';
        mbr.membershipStatus = 'GOOD';
        mbr.birthDate = '1234-5-6';
        mbr.expirationDate = '2345-6-7';
        mbr.membershipType = 'PREMIUMVIP';
        mbr.phoneNumber = '1234567890';
        mbr.emailAddress = 'apex.test@salesforce.com';

        jsonMbrWrapper.MembershipSearchResponse.members.add(mbr);

        ACG_GlobalSearchController.Results resObj = new ACG_GlobalSearchController.Results(jsonMbrWrapper);
    }

    @isTest
    static void resultsMbrAPIWrapperTest() {
        // TODO: FIND ASSERTION FOR TEST
        Account acct = [SELECT Id, ACG_AAA_Membership__c FROM Account LIMIT 1];
        ACG_GlobalSearchController.MbrValAPIWrapper mbrAPIWrapper = new ACG_GlobalSearchController.MbrValAPIWrapper(acct.Id, 'blind');
        mbrAPIWrapper.isLocalClub = true;
        mbrAPIWrapper.sameDayService = true;
        mbrAPIWrapper.inMemberContract = new ServiceContract(
            Name = 'APEXTEST-00001',
            AccountId = acct.Id,
            StartDate = Date.today(),
            EndDate = Date.newInstance(3456, 1, 1),
            AAA_ACA_Membership16ID__c = acct.ACG_AAA_Membership__c,
            AAA_Total_of_Calls_Allowed__c = 5,
            AAA_Total_of_Reciprocals__c = 1,
            AAA_Total_of_Calls_Consumed__c = 1
        );

        ACG_GlobalSearchController.Results resObj = new ACG_GlobalSearchController.Results(mbrAPIWrapper);
    }

    @isTest
    private static void testUpsertNoMembershipRecord() {
        ACG_GlobalSearchController.Results result = ACG_GlobalSearchController.upsertNoMembershipRecord(null, 'TestFName', 'TestLName', '');
    }

    private static Map<string,string> getRequestMap(Account member) {
        return new Map<String, String>{
            'MSsearchByNameZip_fName' => 'APEX0513',
            'MSsearchByNameZip_lName' => 'TEST0513',
            'MSsearchByNameZip_zip' => '01004',
            'MSsearchByNameZip_clubCode' => '240',
            'MSsearchByEmailId_email' => '12345@test.com',
            'MSsearchByMemNumber_Memnum' => member.ACG_AAA_Membership__c
        };
    }
    
    public class MockMemberVerificationAPIs implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { 
            HttpResponse res; 

            if (req.getEndpoint() == 'testurl') {
                res = new HttpResponse(); 

                res.setStatusCode(200); 
                res.setBody('{"access_token":"TestAccessToken"}'); 
            } else if (req.getEndpoint() == 'testSearch') {
                res = new HttpResponse(); 

                res.setStatusCode(200); 
                res.setBody('{\"message\":\"Success\",\"status\":200,\"members\":[{\"name\":\"MARTIN,CESAR\",\"memberNumber\":\"6200049749630002\",\"address\":\"16858,ENCINO,CA\",\"statusIndicator\":\"Active\",\"phoneNumber\":null,\"emailAddress\":null,\"expirationDate\":null}]}'); 
            }

            return res;
        } 
    }
    
    @isTest //AGB SSFI-14
    private static void testUpsertRAPNoMembershipRecord() {
        ACG_GlobalSearchController.Results result = ACG_GlobalSearchController.upsertRAPNoMembershipRecord(null, 'TestFName', 'TestLName', '123456', '999 - Tow_To_Go');
        
        Assert.isNotNull(result, 'UpsertRAPNoMembershipRecord Error');
    }
    
    @isTest //AGB SSFI-14
    static void testgetRAPClubNames() {
        Map<String, Club_Name_Mappings__mdt> rapMap = ACG_GlobalSearchController.getRAPClubNames();
        
        Assert.isNotNull(rapMap, 'Club_Name_Mappings__mdt does not have values');
    }    
    
}