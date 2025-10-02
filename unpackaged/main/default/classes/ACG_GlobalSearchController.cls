/************************************************************************************
Apex Class Name     : ACG_GlobalSearchController
Created Date        : 5th August 2021
Function            : Aura Enabled Class for ACGGlobalSearch LWC
Author              : Deloitte Consulting 
*************************************************************************************/
public without sharing class ACG_GlobalSearchController {
    
    public static User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Branch_Number__c, EmployeeNumber 
                                        FROM User 
                                        WHERE Id =: UserInfo.getUserId()];

    /************************************************************************
    Method Name: getAccountRecordType
    Description: get RecordType Description for Account
    Returns   :  Map<String,String>
    *************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getAccountRecordType() {
        Map<String,Object> recordTypeMap = new Map<String,Object>();
        for(RecordType rec : [SELECT Id,  Name, DeveloperName, IsPersonType FROM RecordType 
                                WHERE SobjectType = 'Account'
                                AND IsPersonType = true]) {
            recordTypeMap.put(rec.DeveloperName, rec);
        }
        return recordTypeMap;
    }
    
     /************************************************************************
    Method Name: getPickListValues
    Description: get picklist values of ACG Club field on Account
    Returns   :  Map<String,String>
    *************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String, AAA_Club_Details__mdt> getClubNames() {
        Map<String, AAA_Club_Details__mdt> mapAAAClub = new Map<String, AAA_Club_Details__mdt>();
        for(AAA_Club_Details__mdt listAAAClub : [SELECT MasterLabel, DeveloperName, Club_Code__c, Parent_Club__c 
                                                    FROM AAA_Club_Details__mdt 
                                                    ORDER BY Club_Code__c]){
             mapAAAClub.put(listAAAClub.DeveloperName, listAAAClub);
        }
        return mapAAAClub;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, ERS_Membership_Unavailable_Reason__mdt> getMembershipUnavailableReasons() {
        Map<String, ERS_Membership_Unavailable_Reason__mdt> mapReasons = new Map<String, ERS_Membership_Unavailable_Reason__mdt>();
        for(ERS_Membership_Unavailable_Reason__mdt reason : [SELECT MasterLabel, DeveloperName, Reason__c, Comments__c
                                                    FROM ERS_Membership_Unavailable_Reason__mdt 
                                                    ORDER BY DeveloperName]){
             mapReasons.put(reason.DeveloperName, reason);
        }
        return mapReasons;
    }

    @AuraEnabled
    public static String insertCustomerRecord(Account accRecord){
        System.debug('Account - > '+accRecord);
        if(accRecord != null){
            try{
                insert accRecord;
                System.debug('accRecord-->'+accRecord);
                return accRecord.Id;
            }catch(Exception e){
                System.debug(e.getMessage());
                return null;
        }
        }else{
            return null;
        }
    }

     /************************************************************************
    Method Name : sendProxyIdToAxis
    Description : sends guid and proxyId of selected Account record to AXIS
    Returns :  INTAxisLaunchResponse_Wrapper object
    Author : Japleen Kaur
    *************************************************************************/
    /*@AuraEnabled
    public static INTAxisLaunchResponse_Wrapper sendProxyIdToAxis(STring accRecId, String guid){
        try {
            Account acc = [SELECT Id, Proxy_UI__c FROM Account WHERE Id=:accRecId];
            INTAxisLaunchResponse_Wrapper response = new INTAxisLaunchResponse_Wrapper();
            if(acc.Proxy_UI__c != null){
                response = INTAxisLaunchAPI.axisLaunch(loggedInUser.EmployeeNumber, 'ADDPAX', acc.Proxy_UI__c, '', '', guid, 'AXIS',  'TPOS');
                System.debug('INTAxisLaunchResponse_Wrapper-->response-->'+response);
                return response;
            }else{
                response.errorMessage = 'Selected record does not have Proxy Id populated.';
                return response;
        }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/

    /************************************************************************
    Method Name : cancelAXISFromSearchPage
    Description : cancel AXIS session
    Returns :  
    Author : Japleen Kaur
    *************************************************************************/
    @AuraEnabled
    public static MembershipController.APICalloutResponseWrapper cancelAXISFromSearchPage(String guid, String proxyId){
        try{
            MembershipController.APICalloutResponseWrapper responseWrap = MembershipController.launchAXIS(guid, proxyId);
            return responseWrap;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
    @description: service method to invoke membership apis
    @return: results in the Results Wrapper format on the basis of API invoked
    @param1: sApiIdentifier - api identofier (valid options: search, lookup)
    @param2: mapRequestParams -> parameters on the basis of api to invoke
    @date: August 22, 2021
    */
    @AuraEnabled
    public static Results invokeMembershipAPIs(String sApiIdentifier, Map<String,String> mapRequestParams, String guid){
        //return null;
        try{ //will update once API is completed.
            if(String.isBlank(sApiIdentifier)){
                throw new AuraHandledException(Label.ACG_EMPTY_IDENTIFIER);
            }
            sApiIdentifier = sApiIdentifier.toLowerCase().trim();
            switch on sApiIdentifier {
                when  'search'{
                    return invokeMembershipSearchAPI(mapRequestParams);
                }

                when  'lookup'{
                    return invokeMembershipLookupAPI(mapRequestParams, guid);
                }
                when else {
                    throw new AuraHandledException(Label.ACG_INVALID_IDENTIFIER);
                }
            }
            
        } 
        catch(Exception e){
            System.debug('*** Exception invokeMembershipAPIs: ' + e.getStackTraceString());
            throw e;
        }
    }
    
     /*
    @description: service method to invoke Profile Names on which local search can be done
    @return: results in the List of String of Profile Names
    @date: Sept 28, 2021
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getProfileNamesForLocalSearch() {
        List<String> profileNames = new List<String>();
        //Functionality_vs_Profile_Access__mdt fpa = Functionality_vs_Profile_Access__mdt.getInstance('Local_Search');
        Functionality_vs_Profile_Access__mdt fpa = [SELECT Id, MasterLabel, DeveloperName, Profile_List__c, QualifiedApiName FROM Functionality_vs_Profile_Access__mdt WHERE DeveloperName = 'Local_Search' limit 1];
        if(fpa.Profile_List__c != '' && fpa.Profile_List__c != null) {
            if(fpa.Profile_List__c.contains(',')) {
                profileNames = fpa.Profile_List__c.split(',');
            } else {
                profileNames.add(fpa.Profile_List__c);
            }
        }
        for(String profile : profileNames) {
            profile = profile.trim();
        }
        return profileNames;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTravelProfileNames() {
        List<String> profileNames = new List<String>();
        Functionality_vs_Profile_Access__mdt [] fpa = [SELECT Id, MasterLabel, DeveloperName, Profile_List__c, QualifiedApiName
                                                        FROM Functionality_vs_Profile_Access__mdt WHERE
                                                        DeveloperName = 'Travel_Profiles'];
        if(fpa[0].Profile_List__c != '' && fpa[0].Profile_List__c != null) {
            if(fpa[0].Profile_List__c.contains(',')) {
                profileNames = fpa[0].Profile_List__c.split(',');
            } else {
                profileNames.add(fpa[0].Profile_List__c);
            }
        }
        for(String profile : profileNames) {
            profile = profile.trim();
        }
        return profileNames;
    }

    @AuraEnabled
    public static Results getLocalSearchResults(Map<String, Object> mapRequestParams){
        try {
            System.debug('getLocalSeachResults Parameters are-->'+ mapRequestParams);
            System.debug('Keys are-->'+ mapRequestParams.keySet());
            // 05-10-2024 removed ACG_Expired_Date__c from query as this field is not present in Account Object. 
            String soqlQuery = 'SELECT Id, Name, ACG_AAA_Membership__c, ACG_Membership_Status__c, ACG_Foreign_Postal_Code__c, BillingStreet, BillingCity, ACG_Military_City__c,BillingStateCode, BillingPostalCode, BillingCountryCode, ACG_Military_City_Detail__c, Phone, PersonEmail, ACG_Membership_Product__c, Membership_Expiration_Date__c, ACG_Date_of_Birth__c, ACG_Address_Type_Detail__c FROM Account';
            String soslQuery = 'FIND ';
            String returningQuery = ' RETURNING Account(Id, Name, ACG_AAA_Membership__c, ACG_Membership_Status__c, ACG_Foreign_Postal_Code__c, BillingStreet, BillingCity, BillingCountryCode, BillingPostalCode, ACG_Military_City__c, ACG_Military_City_Detail__c, BillingStateCode, Phone, PersonEmail, BillingAddress, ACG_Membership_Product__c,Membership_Expiration_Date__c, ACG_Date_of_Birth__c, ACG_Address_Type_Detail__c )';
            if(mapRequestParams!=null || !mapRequestParams.isEmpty()){
                //for combination 1
                if(mapRequestParams.keySet().contains('MSsearchByMemNumber_Memnum')) {
                    if(mapRequestParams.get('MSsearchByMemNumber_Memnum') != null) {
                        String membershipNum = mapRequestParams.get('MSsearchByMemNumber_Memnum').toString();
                        soqlQuery += ' WHERE (RecordType.DeveloperName = \'ACG_Member\' OR RecordType.DeveloperName = \'ACG_Customer\')';
                        soqlQuery += ' AND ACG_AAA_Membership__c = \''+membershipNum+'\'';
                        system.debug('soqlQuery =>' + soqlQuery);
                        List<Account> accounts = Database.Query(soqlQuery);
                        if(!accounts.isEmpty()) {
                            return new Results(accounts);
                        }else{
                            return null;
                        }
                    }
                }
                //for combination 2
                else if(mapRequestParams.keySet().contains('MSsearchByPhNumber_phnum')) {
                    if(mapRequestParams.get('MSsearchByPhNumber_phnum') != null) {
                        String phoneNum = mapRequestParams.get('MSsearchByPhNumber_phnum').toString();
                        String phoneNum2 = formatPhoneNumber(phoneNum);
                        System.debug('Formatted-->'+phoneNum2);
                        soslQuery += '\'\"' + phoneNum + '\"' + ' OR ' + '\"' + phoneNum2 + '\"\'' + ' IN Phone FIELDS';
                        soslQuery += returningQuery;
                        System.debug('Query-->'+soslQuery );
                        List<List <sObject>> queryData = Search.Query(soslQuery);
                        System.debug('Data-->'+queryData[0]);
                        
                        if(!queryData[0].isEmpty()) {
                            return new Results(queryData[0]);
                        }
                    }
                }
                //for combination 3
                else if(mapRequestParams.keySet().contains('MSsearchByEmailId_email')) {
                    if(mapRequestParams.get('MSsearchByEmailId_email') != null) {
                        String email = mapRequestParams.get('MSsearchByEmailId_email').toString();
                        soslQuery += '\'' + email + '\'' + ' IN Email FIELDS';
                        soslQuery += returningQuery;
                        List<List <sObject>> queryData = Search.Query(soslQuery);
                        System.debug('Data-->'+queryData[0]);
                        if(!queryData[0].isEmpty()) {
                            return new Results(queryData[0]);
                        }
                    }
                }
                //for combination 4
                else if(mapRequestParams.keySet().contains('MSsearchByNameZip_fName') || mapRequestParams.keySet().contains('MSsearchByNameZip_lName')
                || mapRequestParams.keySet().contains('MSsearchByNameZip_zip')) {
                    if(mapRequestParams.get('MSsearchByNameZip_fName') != null || mapRequestParams.get('MSsearchByNameZip_lName') != null
                    || mapRequestParams.get('MSsearchByNameZip_zip') != null) {
                        String fname = mapRequestParams.get('MSsearchByNameZip_fName').toString() != null ? mapRequestParams.get('MSsearchByNameZip_fName').toString() : '';
                        String lname = mapRequestParams.get('MSsearchByNameZip_lName').toString() != null ? mapRequestParams.get('MSsearchByNameZip_lName').toString() : '';
                        String zip = mapRequestParams.get('MSsearchByNameZip_zip').toString() != null ? mapRequestParams.get('MSsearchByNameZip_zip').toString() : '';
                        soslQuery += '\'';
                        //soslQuery += String.isNotBlank(fname) ? '\"' + fname + '*\" AND ' : '';
                        if(String.isNotBlank(fname)) {
                            soslQuery += String.isNotBlank(fname) ? '\"' + fname + '*\" AND ' : '';
                        } 
                        if(String.isNotBlank(lname)){
                            soslQuery += String.isNotBlank(lname) ? '\"' + lname + '*\"' : '';
                        }
                        if(String.isNotBlank(zip)) {
                            soslQuery += String.isNotBlank(zip) ? ' AND ' + '\"' + zip + '\"' : '';
                        } 
                        /*else {
                            soslQuery += String.isNotBlank(zip) ? '\"' + zip + '\"' : '';
                        }*/
                        soslQuery += '\' IN ALL FIELDS';
                        soslQuery += returningQuery;
                        System.debug('Query-->'+soslQuery);
                        List<List <sObject>> queryData = Search.Query(soslQuery);
                        System.debug('Data-->'+queryData[0]);
                        if(!queryData[0].isEmpty()) {
                            return new Results(queryData[0]);
                        }
                    }
                }
                 //for Trip Number
                /* 
                else if(mapRequestParams.keySet().contains('MSsearchByTripNumber')) {
                    if(mapRequestParams.get('MSsearchByTripNumber') != null) {
                        String tripNumber = mapRequestParams.get('MSsearchByTripNumber').toString();
                        List<Id> accountIds = new List<Id>();
                        if(String.isNotBlank(tripNumber)) {
                            for (Trip__c trip : [SELECT Id, Trip_Number__c, Account__c, Integration_Id__c FROM Trip__c WHERE Trip_Number__c =: tripNumber OR Integration_Id__c = :tripNumber ]) {
                                if(trip.Account__c != null) {
                                    accountIds.add(trip.Account__c);
                                }
                            }
                        }
                        if(!accountIds.isEmpty()) {
                            soqlQuery += ' WHERE Id IN :accountIds';
                            List<Account> accounts = Database.Query(soqlQuery);
                            if(!accounts.isEmpty()) {
                                return new Results(accounts);
                            }
                        }
                    }
                } */
            }
        } catch (Exception e) {
            System.debug('enter in catch-->'+e.getMessage());
            System.debug(e.getCause());
            System.debug(e.getStackTraceString());
            System.debug(e.getLineNumber());
            System.debug(e.getTypeName());
        }
        return null;
    }

    public static String formatPhoneNumber(String phoneNum) {
        return '(' + phoneNum.substring(0, 3) + ') ' + phoneNum.substring(3, 6) + '-' + phoneNum.substring(6);
    }

    /*
    @description: method to invoke membership search API
    @return: results in the Results Wrapper format on thw basis of API invoked
    @param1: mapRequestParams -> parameters for search api
    @date: August 22, 2021
    */
    @testVisible
    public static Results invokeMembershipSearchAPI(Map<String,String> mapRequestParams){
        //return null;
        if(mapRequestParams==null || mapRequestParams.isEmpty()){
            throw new AuraHandledException(Label.ACG_INVALID_SEARCH_CRITERIA);
        }
        MembershipSearchRespJSONWrapper response = INTMembershipSearchAPI.getMembersearch(mapRequestParams);
        if(response == null){
            throw new AuraHandledException(Label.ACG_NO_RESPONSE);    
        } else {
            if(response.responseHeaders.tranCode == '200')
                return new Results(response);
            throw new AuraHandledException(response.responseHeaders.tranStatusDescription);
        }
    }

    /*
    @description: method to invoke membership Lookup API
    @return: results in the Results Wrapper format on thw basis of API invoked
    @param1: mapRequestParams -> parameters for Lookup api
    @date: August 22, 2021
    */
    @testVisible
    private static Results invokeMembershipLookupAPI(Map<String,String> mapRequestParams, String guid){
        //return null;
        String sMemberId = mapRequestParams?.get('memberId');
        if(String.isBlank(sMemberId)){
            throw new AuraHandledException(Label.ACG_INVALID_MEMBERID);
        }
        INTMembershipLookupResponse_Wrapper response = INTMembershipLookupAPI.getMemberlookup(sMemberId);

        if(response == null){
            throw new AuraHandledException(Label.ACG_NO_RESPONSE);    
        }else if(response.STATUS_CODE != 200){
            if(guid == 'GUID_API'){
                system.debug('No Membership Info Returned');
                return null;
            }
        else if(guid == 'ERSINB') {
                system.debug('@@@@@ No Membership Info Returned');
                Results result = new Results('ERSINB');
                return result;
            }       
        else {
                throw new AuraHandledException(response.ERR_MESSAGE);
            }
        }
        system.debug('@@@@@memberId@@@@@'+sMemberId);
        system.debug('@@@@@response@@@@@'+response);
        //ERS-227393  //ERS-230821
        Results result = new Results(ACG_GlobalSearchControllerHelper.performUpsertOnLookupRecord(sMemberId, response, guid));
        result.warningMessage = response.responseHeaders.tranStatusDescription;
        return result;
    }
    public static void invokeMembershipLookupAPIFromBatch(String memberIDs, String guid){
 
     
        INTMembershipLookupResponse_Wrapper response = INTMembershipLookupAPI.getMemberlookup(memberIDs);

        if(response == null){
            throw new AuraHandledException(Label.ACG_NO_RESPONSE);    
        }
        //ACG_GlobalSearchControllerHelper.performUpsertOnLookupRecord(memberIDs, response, guid);    
    }
    
    @AuraEnabled
    public static Results upsertNoMembershipRecord(Id accountId, string firstName, string lastName, string caseNumber) {
        try {
            Account thisMember = new Account();
            if(accountId != null) {
                thisMember.Id = accountId;
            }
            thisMember.FirstName = firstName != null? firstName : caseNumber;
            thisMember.LastName = lastName;
            thisMember.ACG_Entitlements_Allotted__c = 1;
            thisMember.ACG_Membership_Status__c = 'Active';
            thisMember.recordtypeId = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
            thisMember.PersonEmail = lastName.trim().replace(' ','_')+caseNumber+'@uniqemail.com'; //AGB 1/27/2025 SSFI-14 (same error as belows)

            NoMembershipAccountHelper.setNoMembershipStatus(thisMember);

            upsert thisMember;

            return new Results(thisMember.Id);

        } catch (Exception ex) {
            System.debug('upsertNoMembershipRecord exception occurred --> '+ ex.getStackTraceString());
            throw new AuraException(ex.getMessage());
        }
    }
    
    //AGB 1/7/2025 for SSFI-14
    @AuraEnabled
    public static Results upsertRAPNoMembershipRecord(Id accountId, string firstName, string lastName, string caseNumber, string selectedRAPClub) {
        try {
            Account thisMember = new Account();
            if(accountId != null) {
                thisMember.Id = accountId;
            }
            thisMember.FirstName = firstName != null? firstName : caseNumber;
            thisMember.LastName = lastName;
            thisMember.ACG_Entitlements_Allotted__c = 1;
            thisMember.ACG_Membership_Status__c = 'Active';
            thisMember.Membership_Status__pc = 'Active';
            thisMember.recordtypeId = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
            thisMember.PersonEmail = lastName.trim().replace(' ','_')+caseNumber+'@uniqemail.com'; //AGB 1/27/2025 SSFI-14 
            
            thisMember.Member_Card_Num__pc = caseNumber;
            thisMember.Membership_Level__pc = 'Plus';
            thisMember.AAA_Membership_Level__c = 'Plus';
            thisMember.Membership_Type__pc = 'RAP';
            thisMember.Membership_Org__pc = 'EDS';
            thisMember.Membership_OrgCode__pc = selectedRAPClub.split(' - ')[0].trim();
            //thisMember.Membership_Org__pc = selectedRAPClub.split(' - ')[1].trim();
			//this.Membership_Number__c = caseNumber;
            
            NoMembershipAccountHelper.setNoMembershipStatus(thisMember);

            upsert thisMember;

            return new Results(thisMember.Id);

        } catch (Exception ex) {
            System.debug('upsertRAPNoMembershipRecord exception occurred --> '+ ex.getStackTraceString());
            throw new AuraException(ex.getMessage());
        }
    } 
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Club_Name_Mappings__mdt> getRAPClubNames() { //AGB 1/10/2024 for SSFI-14
        Map<String, Club_Name_Mappings__mdt> mapRAPClub = new Map<String, Club_Name_Mappings__mdt>();
        for(Club_Name_Mappings__mdt listRAPClub : [SELECT MasterLabel, DeveloperName, Club_Code__c, RAP_Club__c
                                                    FROM Club_Name_Mappings__mdt where RAP_Club__c = true
                                                    ORDER BY Club_Code__c]){
             mapRAPClub.put(listRAPClub.DeveloperName, listRAPClub);
        }
        return mapRAPClub;
    }    
    //End AGB 1/7/2025 for SSFI-14
    

    /*
    @description: Wrapper for returning the invoked api results
    @date: August 22, 2021
    */
    public class Results {
        
        @AuraEnabled
        public List<SearchResultsWrapper> searchResults; //for search api

        @AuraEnabled
        public Boolean isLookupSuccess = false; //for lookup api

        @AuraEnabled
        public Id updatedRecordId ; //for lookup api

        @AuraEnabled
        public String impairmentType; // To pass impairment type

        @AuraEnabled
        public string warningMessage; //ERS-227393

        // To display contract/Entitlements after Member verification
        @AuraEnabled
        public ContractWrapper contract;
        
        @AuraEnabled
        public EntitlementsWrapper entitlement;

        @AuraEnabled
        public Boolean isLocalClub;

        @AuraEnabled
        public string accountId;
    
    @AuraEnabled
        public string custMessage;

        //constructor when search api is invoked
        public Results(MembershipSearchRespJSONWrapper responseWrapper){
            searchResults = new List<SearchResultsWrapper>();
            SearchResultsWrapper thisWrapper;

            for(MembershipSearchRespJSONWrapper.members thisMember : responseWrapper.MembershipSearchResponse.members){
                thisWrapper = new SearchResultsWrapper();
                thisWrapper.Name =  thisMember.firstName + ' ' + thisMember.lastName;
                thisWrapper.MembershipNumber = thisMember.membershipNumber;
                thisWrapper.MembershipStatus = String.IsNotBlank(thisMember.membershipStatus) ? thisMember.membershipStatus : null; 
                thisWrapper.Phone = String.IsNotBlank(thisMember.phoneNumber) ? thisMember.phoneNumber : '';

                //ERS-229007
                thisWrapper.Address = thisMember.adressLine1
                    + ( String.IsNotBlank(thisMember.addressLine2) ? ', ' + thisMember.addressLine2 : '')
                    + ( String.IsNotBlank(thisMember.city) ? ', ' + thisMember.city : '')
                    + ( String.IsNotBlank(thisMember.state) ? ', ' + thisMember.state : '');
                    
                //thisWrapper.ExpirationDate = String.isNotBlank(thisMember.expirationDate) ?  thisMember.expirationDate : '';  
                thisWrapper.ExpirationDate = String.isNotBlank(thisMember.expirationDate) ? Date.valueOf(thisMember.expirationDate).month() + '/' + Date.valueOf(thisMember.expirationDate).day() +'/'+ Date.valueOf(thisMember.expirationDate).year() : '';
                thisWrapper.MemberProduct = String.IsNotBlank(thisMember.membershipType) ? thisMember.membershipType : '';
                thisWrapper.DOB = String.IsNotBlank(thisMember.birthDate) ? Date.valueOf(thisMember.birthDate).month() + '/' + Date.valueOf(thisMember.birthDate).day() +'/'+ Date.valueOf(thisMember.birthDate).year() : '';
                thisWrapper.Email = thisMember.emailAddress;
                //thisWrapper.recordId = getAccountRecord(thisMember.membershipNumber);
                //'0010500000KyRKRAA3'; //TODO" new method for record search on the basis of membership number and populate here
                searchResults.add(thisWrapper);
            }
        }
        
        //constructor when lookup api is invoked
        public Results(Id updatedId){
            isLookupSuccess = true;
            updatedRecordId = updatedId;
        }
    
    //constructor when lookup api is invoked
        public Results(string customMessage){
            custMessage = customMessage;
        }

         //ERS-230821 MV Impairments
        //constructor when lookup api is invoked
        public Results(MbrValAPIWrapper mvWrapper){
            contract = new ContractWrapper();
            entitlement = new EntitlementsWrapper();
            isLookupSuccess = true;
            updatedRecordId = mvWrapper.recordId;
            impairmentType = mvWrapper.impairmentType;
            isLocalClub = mvWrapper.isLocalClub;
            accountId = mvWrapper.accountId;
            if(isLocalClub){
                if(mvWrapper.inMemberContract != null){
                    contract.contractId = mvWrapper.inMemberContract.Id;
                    contract.callsAllowed = String.valueOf(mvWrapper.inMemberContract.AAA_Total_of_Calls_Allowed__c);
                    mvWrapper.inMemberContract.AAA_Total_of_Reciprocals__c = (mvWrapper.inMemberContract.AAA_Total_of_Reciprocals__c == null) ? 0 : mvWrapper.inMemberContract.AAA_Total_of_Reciprocals__c;
                    contract.callsRemaining = String.valueOf(mvWrapper.inMemberContract.AAA_Total_of_Calls_Allowed__c - mvWrapper.inMemberContract.AAA_Total_of_Calls_Consumed__c - mvWrapper.inMemberContract.AAA_Total_of_Reciprocals__c);
                    contract.contractStartDate = (mvWrapper.inMemberContract.StartDate != null) ? Date.valueOf(mvWrapper.inMemberContract.StartDate).month() + '/' + Date.valueOf(mvWrapper.inMemberContract.StartDate).day() +'/'+ Date.valueOf(mvWrapper.inMemberContract.StartDate).year() : '';
                    contract.contractEndDate = (mvWrapper.inMemberContract.EndDate != null) ? Date.valueOf(mvWrapper.inMemberContract.EndDate).month() + '/' + Date.valueOf(mvWrapper.inMemberContract.EndDate).day() +'/'+ Date.valueOf(mvWrapper.inMemberContract.EndDate).year() : '';
                    contract.sameDayService = mvWrapper.sameDayService;
                } else{
                    contract = null;
                }  
                entitlement = null;
            }else{
                entitlement.authorizationCode = mvWrapper.outMemberContract.authorizationCode;
                entitlement.authorizationLevel = mvWrapper.outMemberContract.authorizationLevel;
                entitlement.callsRemaining = mvWrapper.outMemberContract.callsRemaining;
                contract = null;
            }
        }

        //constructor when local search happened
        public Results(List<Account> accounts) {
            searchResults = new List<SearchResultsWrapper>();
            SearchResultsWrapper thisWrapper;
            for(Account acc : accounts) {
                String address = '';
                
                if(acc.ACG_Address_Type_Detail__c == 'Foreign') {
                    address += String.isNotBlank(acc.BillingCity) ? +' '+acc.BillingCity : '';
                    address += String.isNotBlank(acc.BillingCountryCode) ? +' '+acc.BillingCountryCode : '';
                    address += String.isNotBlank(acc.ACG_Foreign_Postal_Code__c) ? +' '+acc.ACG_Foreign_Postal_Code__c : '';
                }
                 else if(acc.ACG_Address_Type_Detail__c == 'Military') {
                    address += String.isNotBlank(acc.ACG_Military_City__c) ? +' '+acc.ACG_Military_City__c : '';
                    address += String.isNotBlank(acc.ACG_Military_City_Detail__c) ? +' '+acc.ACG_Military_City_Detail__c : '';
                    address += String.isNotBlank(acc.BillingPostalCode) ? +' '+acc.BillingPostalCode : '';
                } else {
                    address += String.isNotBlank(acc.BillingCity) ? +' '+acc.BillingCity : '';
                    address += String.isNotBlank(acc.BillingStateCode) ? +' '+acc.BillingStateCode : '';
                    address += String.isNotBlank(acc.BillingPostalCode) ? +' '+acc.BillingPostalCode : '';
                }
                thisWrapper = new SearchResultsWrapper();
                thisWrapper.Name =  acc.Name;
                thisWrapper.MembershipNumber = acc.ACG_AAA_Membership__c != null ? acc.ACG_AAA_Membership__c : '';
                thisWrapper.MembershipStatus = acc.ACG_Membership_Status__c != null ? acc.ACG_Membership_Status__c : '';
                thisWrapper.Phone = acc.Phone != null ? acc.Phone : '';
                thisWrapper.Address = acc.BillingStreet != null ? acc.BillingStreet +', '+ address : address;
                thisWrapper.ExpirationDate = acc.Membership_Expiration_Date__c != null ? acc.Membership_Expiration_Date__c.month() + '/' + acc.Membership_Expiration_Date__c.day() + '/' + acc.Membership_Expiration_Date__c.year() : '';
                thisWrapper.MemberProduct = acc.ACG_Membership_Product__c != null ? acc.ACG_Membership_Product__c : '';
                thisWrapper.DOB = acc.ACG_Date_of_Birth__c != null ? acc.ACG_Date_of_Birth__c.month() + '/' + acc.ACG_Date_of_Birth__c.day() + '/' + acc.ACG_Date_of_Birth__c.year() : '';
                thisWrapper.Email = acc.PersonEmail != null ? acc.PersonEmail : '';
                thisWrapper.recordId = acc.Id;
                searchResults.add(thisWrapper);
            }
        }
    }

    //ERS-230821 MV Impairments
    public class MbrValAPIWrapper {
        public Id recordId;
        public String impairmentType;
        public Boolean isLocalClub;
        public EntitlementsWrapper outMemberContract;
        public ServiceContract inMemberContract;
        public Boolean showImpairment;
        public boolean sameDayService;
        public string accountId;
        public MbrValAPIWrapper() {}
        public MbrValAPIWrapper(Id id, String impType) {
            recordId = id;
            impairmentType = impType;
        }
    }

    public class ContractWrapper {   // Local Club Members Data
        @AuraEnabled
        public String contractId;
        @AuraEnabled
        public String callsAllowed;
        @AuraEnabled
        public String callsRemaining;
        @AuraEnabled
        public String contractStartDate;
        @AuraEnabled
        public String contractEndDate;
        @AuraEnabled
        public boolean sameDayService;
    }

    public class EntitlementsWrapper {  //Out of Club Members Data
        @AuraEnabled
        public String authorizationCode;
        @AuraEnabled
        public String authorizationLevel;
        @AuraEnabled
        public Integer callsRemaining;
    }

    /*
    @description: Wrapper to send search results on client side
    @date: August 22, 2021
    */
    public class SearchResultsWrapper {
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String MembershipNumber;
        @AuraEnabled
        public String MembershipStatus;
        @AuraEnabled
        public String Phone;
        @AuraEnabled
        public String Address;
        @AuraEnabled
        public String MemberProduct;
        @AuraEnabled
        public String ExpirationDate;
        @AuraEnabled
        public String DOB;
        @AuraEnabled
        public String Email;
        @AuraEnabled
        public String recordId;
    }
}