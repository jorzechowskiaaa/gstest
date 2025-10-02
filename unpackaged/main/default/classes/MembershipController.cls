/********************************************************************************************************
Apex Class Name     : MembershipController
Created Date        : 30th August 2021
Function            : Aura Enabled Class for acg_cmf_customerInfo LWC
Author              : Deloitte Consulting

********************************************************************************************************/
public without sharing class MembershipController {
    public static User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Club_Name__c, Branch_Number__c, EmployeeNumber 
                                        FROM User 
                                        WHERE Id =: UserInfo.getUserId()];
        
    @AuraEnabled
    public static Boolean isUserCore() {
        if(loggedInUser.Club_Name__c != null){
            String clubCode = loggedInUser.Club_Name__c.right(3);
            //Check if User is a member of ACG Core
            if(Label.ACG_Core_Club_Codes.contains(clubCode)){
                return true;
            }else{
               return false;
            }      
        }else{
            return false;
        }
    }

    //Method to fetch Customer Account Record Type Id
    @AuraEnabled(cacheable=true)
    public static String getCustomerRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId();
    }

    @AuraEnabled
    public static String getIpAddressOfCurrentUser(){
        try {
            AuthSession authSessionRec = [SELECT Id, SourceIp 
                                            FROM AuthSession 
                                            WHERE UsersId = :UserInfo.getUserId() 
                                            ORDER BY CreatedDate DESC LIMIT 1];
            return authSessionRec.SourceIp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Method to update Email of Customer Account
    @AuraEnabled()
    public static String updateEmail(String recordId, String confirmEmail) {
        String id = '';
        try{
            Account acc = [SELECT Id, PersonEmail, ACG_Does_Not_Have__c FROM Account WHERE Id =:recordId];
            acc.PersonEmail = confirmEmail;
            if(acc.ACG_Does_Not_Have__c) {
                acc.ACG_Does_Not_Have__c = false;
            }
            Database.SaveResult sr = Database.update(acc,false);
            if(sr.isSuccess()) {
                id = acc.Id;
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        } catch (Exception e) {
            System.debug('enter in catch-->'+e.getMessage());
            return id;    
        }
        return id;
    }
    
    // Method to create Customer record from Membership Flow
    @AuraEnabled
    public static String createMember(Account personAcc, String ownerId, Boolean isMemberRecord) {
        String id = '';
        try {
            if(isMemberRecord) {
                personAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
                personAcc.ACG_Is_Primary_Member_in_Household__c = true;
            }
            System.debug('Account->'+personAcc);
            System.debug('---ownerId-->'+ownerId);
            if(ownerId != null && ownerId != '') {
				personAcc.OwnerId = ownerId;                
            }
            Database.UpsertResult sr = Database.upsert(personAcc,false);
            if(sr.isSuccess()) {
                id = personAcc.Id;
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        } catch (Exception e) {
            System.debug('enter in catch-->'+e.getMessage());
            return id;    
        }
        return id;
    }
    
    @AuraEnabled
    public static APICalloutResponseWrapper validateAddress(Account acc){
        /*Account acc = [SELECT FirstName, MiddleName, LastName, ACG_Suffix__c, ACG_Prefix__c, ACG_Gender__c, PersonEmail, ACG_Date_of_Birth__c,
                        Phone, ACG_Primary_Phone_Type__c, PersonHomePhone, ACG_Secondary_Phone_Type__c, ACG_Alternate_Phone__c, 
                        ACG_Alternate_Phone_Type__c, BillingStreet, ACG_Address_Type_Detail__c, BillingCity, BillingStateCode, 
                        BillingLatitude, BillingLongitude, BillingPostalCode, ACG_Foreign_Postal_Code__c 
                        FROM Account
                        WHERE ID =:accId];*/
        APICalloutResponseWrapper apiResponse = new APICalloutResponseWrapper();
        if(acc != null){
            
            //Validate Address before sending it to POC
            INTAddressValidationRequest_Wrapper addWrapper = new INTAddressValidationRequest_Wrapper();
            if(acc.BillingStreet != null){
            List<String> addArray = acc.BillingStreet.split('; ');
                if(addArray.size() == 1){
                    addWrapper.addressLine1 = acc.BillingStreet;
                }else if(addArray.size() > 1){
                    addWrapper.addressLine1 = addArray[0];
                    addWrapper.addressLine2 = addArray[1];
                }
            }
            addWrapper.city = acc.BillingCity;
            addWrapper.state = acc.BillingStateCode;
            addWrapper.zip5 = acc.BillingPostalCode;
            INTAddressValidationResponse_Wrapper addressAPIResponse = INTAddressValidationAPI.validateAddress(addWrapper);
            System.debug('INTAddressValidationResponse_Wrapper-->response-->'+addressAPIResponse);

            if(addressAPIResponse != null && addressAPIResponse.statusCode == 200 && addressAPIResponse.errorMessage == null){
                apiResponse.resultMessage = 'Success';
                apiResponse.variant = 'success';
                apiResponse.addressResponse = addressAPIResponse;
            }else if(addressAPIResponse.statusCode == 500){
                apiResponse.resultMessage = 'Internal Server Error';
                apiResponse.variant = 'error';
            }else{
                apiResponse.resultMessage = addressAPIResponse.responseHeaders.tranStatusDescription != null ? addressAPIResponse.responseHeaders.tranStatusDescription : '';
                apiResponse.variant = 'error';
            }
        }
        System.debug('apiResponse-->'+apiResponse);
        return apiResponse;
    }
    @AuraEnabled
    public static APICalloutResponseWrapper createCustomerInPOC(String ipAddress, String guid, Account acc, String addressResponse,String ownerId, Boolean isMemberRecord, Boolean bypassAddressValidation){
        System.debug('addressResponse--->'+addressResponse);
        APICalloutResponseWrapper apiResponse = new APICalloutResponseWrapper();
        INTAddressValidationResponse_Wrapper addResponse = new INTAddressValidationResponse_Wrapper();
        INTUpsertCustomerInPOCResponse_Wrapper response = new INTUpsertCustomerInPOCResponse_Wrapper();
        If(Test.isRunningTest()){
            String jsonString='{"statusCode":200,"responseHeaders":{"tranId":"965b6a88-50d3-2730-d5a6-aa1e7fcba603","tranCode":"200","tranStatus":"Success","timeStamp":"2021-09-09T08:23:48 -0500","tranStatusDescription":"upserted the customer successfully"},"customer":{"ui":"324358476","proxyUi":"324358476","hui":"324358476"}}';
            response=(INTUpsertCustomerInPOCResponse_Wrapper)JSON.deserialize(jsonString, INTUpsertCustomerInPOCResponse_Wrapper.Class);
        }
        else{
            if(String.isNotBlank(addressResponse) && String.isNotEmpty(addressResponse)){
                addResponse = (INTAddressValidationResponse_Wrapper)JSON.deserialize(addressResponse, INTAddressValidationResponse_Wrapper.class);
                System.debug('addResponse = '+addResponse);
                response = CreateCustomerInPOCHandler.invokeCreateCustomerAPI(acc, ipAddress, addResponse, bypassAddressValidation);
                System.debug('CreateCustomerInPOCHandler-->response-->'+response);
            }else{
                response = CreateCustomerInPOCHandler.invokeCreateCustomerAPI(acc, ipAddress, null, bypassAddressValidation);
            System.debug('CreateCustomerInPOCHandler-->response-->'+response);
            }
        }

        try{
            
            if(response != null && response.customer != null){
                if(response.statusCode == 200){
                    String id = '';
                    //insert account in SF and update proxyUI, hui and POCId received from POC
                    Account accRec = new Account();
                    accRec = acc;
                    accRec.Proxy_UI__c = response.customer.proxyUi;
                    accRec.POC_ID__c = response.customer.ui;
                    accRec.ACG_Household_Id__c = response.customer.hui;
                    accRec.GUID__c = guid;
                    if(addResponse != null && addResponse.membershipAddress != null){
                        System.debug('addResponse-->response-->'+addResponse);
                    accRec.BillingStreet = addResponse.membershipAddress.addressLine1+'; '+addResponse.membershipAddress.addressLine2;
                    accRec.BillingCity = addResponse.membershipAddress.city;
                    accRec.BillingStateCode = addResponse.membershipAddress.state; 
                    accRec.BillingPostalCode = addResponse.membershipAddress.zip5;
                    accRec.Zip4__c = addResponse.membershipAddress.zip4;
                    accRec.BillingLatitude = Decimal.valueOf(addResponse.membershipAddress.latitude);
                    accRec.BillingLongitude = Decimal.valueOf(addResponse.membershipAddress.longitude);
                    accRec.Census_Block__c = addResponse.membershipAddress.censusBlock;
                    accRec.Delivery_Point_Barcode__c = addResponse.membershipAddress.deliveryPointBarcode;
                    accRec.Delivery_Point__c = addResponse.membershipAddress.deliveryPoint;
                    accRec.Carrier_Route__c = addResponse.membershipAddress.carrierRoute;
                    accRec.State_FIPS__c = addResponse.membershipAddress.stateFIPS;
                    accRec.Country_FIPS__c = addResponse.membershipAddress.countryFIPS;
                    accRec.Census_Tract__c = addResponse.membershipAddress.censusTract;
                    }


                    if(isMemberRecord) {
                        accRec.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
                        accRec.ACG_Is_Primary_Member_in_Household__c = true;
                    }
                    if(ownerId != null && ownerId != '') {
                        accRec.OwnerId = ownerId;                
                    }

                    Database.SaveResult sr = Database.insert(accRec, false);
                    if(sr.isSuccess()) {
                        apiResponse.resultMessage = 'Success';
                        apiResponse.variant = 'success';
                        apiResponse.accRecord = accRec;
                    } else {
                        apiResponse.resultMessage = 'There was an error saving the record in salesforce. Please try again.';
                        apiResponse.variant = 'error';
                        for(Database.Error err : sr.getErrors()) {
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                        }
                    }
                }else{
                    apiResponse.resultMessage = String.valueOf(response.errorMessage);
                    apiResponse.variant = 'error';
                }
            }else{
                    apiResponse.resultMessage = 'Error';
                    apiResponse.variant = 'error';
            }
        } catch (Exception e) {
            System.debug('enter in catch-->' + e.getMessage());
        }
        
        return apiResponse;
    }

    @AuraEnabled
    public static APICalloutResponseWrapper launchAXIS(String guid, String proxyId){
        try {
            APICalloutResponseWrapper apiResponse = new APICalloutResponseWrapper();
            //Call AXIS API
            //send pId - currently hard-coded as there is only one
            INTAxisLaunchResponse_Wrapper axisResponse = INTAxisLaunchAPI.axisLaunch(loggedInUser.EmployeeNumber, 'ADDPAX', proxyId, '', '', guid, 'AXIS', 'TPOS');
            System.debug('INTAxisLaunchResponse_Wrapper-->response-->'+axisResponse);
            if(axisResponse.statusCode == 200 && axisResponse.responseHeaders.tranStatusDescription == 'Success'){
                apiResponse.resultMessage = axisResponse.responseHeaders.tranStatusDescription;
                apiResponse.variant = 'success';
                apiResponse.proxyId = '';
            }else if(axisResponse.statusCode == 200 && axisResponse.responseHeaders.tranStatusDescription != 'Success'){
                apiResponse.resultMessage = axisResponse.responseHeaders.tranStatusDescription;
                apiResponse.variant = 'error';
                apiResponse.proxyId = '';
            }else{
                apiResponse.resultMessage = axisResponse.errorMessage != null ? axisResponse.errorMessage : '';
                apiResponse.variant = 'error';
                apiResponse.proxyId = '';
            }
            return apiResponse;      
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
        

    @AuraEnabled
    public static string convertCustomerRecord(String recordId, String ownerId){
        String id = '';
        try{
            Account acc = [SELECT id FROM ACCOUNT WHERE id =: recordId];

            if(ownerId != null && ownerId != '') {
                acc.OwnerId = ownerId;                
            }
            Id recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
            
            if(recordTypeID!=null){
                acc.RecordTypeId = recordTypeID;
            }
            Database.SaveResult sr = Database.update(acc,false);
            if(sr.isSuccess()) {
                id = acc.Id;
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        } catch (Exception e) {
            System.debug('enter in catch-->'+e.getMessage());
            return id;    
        }
        return id;
    }

     /*
    * @description: to add associate members in the household
    * @param2: associateMembers -> associate members to add
    * #date: 12 Oct, 2021
    */
    @AuraEnabled
    public static void addAssociateMembersToHousehold(Id primaryMemberId, String sMembersJson){
        try{
            List<Map<String,String>> lstMembers = (List<Map<String,String>>)JSON.deserialize(sMembersJson,List<Map<String,String>>.class);
            if(String.isBlank(primaryMemberId) || lstMembers == null || lstMembers.isEmpty()) 
                throw new CustomException('Invalid Paramteres to add associate members');
            
            List<Account> lstAssociateMembers = new List<Account>();
            for(Map<String,String> thisMember : lstMembers){
                Account newMember = new Account(
                    RecordTypeId = ACG_UtilityClass.MEMBER_RECORDTYPE_ID,
                    FirstName = thisMember.get('firstName'),
                    MiddleName = thisMember.get('mi'),
                    LastName = thisMember.get('lastName'),
                    ACG_Suffix__c = thisMember.get('suffix'),
                    Phone = thisMember.get('phone'),
                    PersonEmail = thisMember.get('email'),
                    Motorcycle_Included__c = Boolean.valueOf(thisMember.get('motorcycleIncluded')),
                    RV_Offering__c = thisMember.get('rvOfferingName')
                );
                if(String.isNotBlank(thisMember.get('recordId'))){
                    newMember.Id = thisMember.get('recordId');
                }
                if(String.isNotBlank(thisMember.get('dob'))){
                    newMember.ACG_Date_of_Birth__c = Date.valueOf(thisMember.get('dob'));
                }
                lstAssociateMembers.add(newMember);     
            }
            if(!lstAssociateMembers.isEmpty()){
                upsert lstAssociateMembers;
                
                //create ACRs
                List<AccountContactRelation> lstACRs = new List<AccountContactRelation>();
                for(Integer i = 0; i < lstAssociateMembers.size(); i++){
                    lstMembers[i].put('recordId',lstAssociateMembers[i].Id);
                }
                
                List<Account> lstPrimaryAccount = [SELECT Id, ACG_Household_Id__c FROM Account WHERE Id=:primaryMemberId LIMIT 1];
                if(lstPrimaryAccount == null || lstPrimaryAccount.isEmpty() || String.isBlank(lstPrimaryAccount[0].ACG_Household_Id__c))
                    throw new CustomException('No Primary Household found to add associate members');
                
                Map<Id,Account> mapAssociateMembers = new Map<Id,Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN:lstAssociateMembers LIMIT :lstMembers.size()]);
                String relation;
                
                for(Map<String,String> thisMember : lstMembers){
                    relation = String.isBlank(thisMember.get('relationship')) ? 'Other' : thisMember.get('relationship');
                    lstACRs.add(new AccountContactRelation(
                        AccountId = lstPrimaryAccount[0].ACG_Household_Id__c,
                    	ContactId = mapAssociateMembers.get(thisMember.get('recordId')).PersonContactId,
                    	ACG_Relationship_to_primary__c = relation,
                        Roles = relation
                    ));
                }
                if(!lstACRs.isEmpty()){
                    Database.insert(lstACRs,false);
                }
            }
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    

    /************************************************************************
    Method Name: getZipCodes
    Description: validate Zip Code of the logged in agent
    Returns   :  Map<String, Zip_Code_Details__mdt>
    *************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String, Zip_Code_Details__mdt> getZipCodes(String loggedInUserClubCode) {
        Map<String, Zip_Code_Details__mdt> mapZipCodes = new Map<String, Zip_Code_Details__mdt>();
        String queryString = 'SELECT MasterLabel, DeveloperName, Club_Code__c, Start_Zip_Code__c, End_Zip_Code__c FROM Zip_Code_Details__mdt';
        String clubCode = loggedInUserClubCode.right(3);
        //Check if User is a member of ACG Core
        if(Label.ACG_Core_Club_Codes.contains(clubCode)){
            queryString += ' WHERE Club_Code__c IN ('+Label.ACG_Core_Club_Codes+')';
        }else{
            queryString += ' WHERE Club_Code__c =: clubCode';
        }

        List<Zip_Code_Details__mdt> zipCodeList = Database.query(queryString);
        if(zipCodeList.size() > 0){
            for(Zip_Code_Details__mdt zipCodeRec : zipCodeList){
                    if(!mapZipCodes.containsKey(zipCodeRec.DeveloperName)){
                        mapZipCodes.put(zipCodeRec.DeveloperName, zipCodeRec);
                    }
                    mapZipCodes.put(zipCodeRec.DeveloperName, zipCodeRec);
                }
        }
        return mapZipCodes;       
    }

    /************************************************************************
    Method Name: createCustInPOCFromOpportunity
    Description: create customer in pOC from Opportunity if parent account poc id is null
    Returns   :  
    *************************************************************************/
    @AuraEnabled
    public static APICalloutResponseWrapper createCustInPOCFromOpportunity(String accountId){
        APICalloutResponseWrapper apiResponse = new APICalloutResponseWrapper();
        if(String.isNotBlank(accountId) && String.isNotEmpty(accountId)) {
                List<Account> accountList = [SELECT Id, FirstName, MiddleName, LastName, ACG_Prefix__c, ACG_Suffix__c, ACG_Gender__c, PersonEmail, ACG_Date_of_Birth__c, BillingStreet, 
                ACG_Address_Type__c, ACG_Address_Type_Detail__c, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingLatitude, BillingLongitude, ACG_Foreign_Postal_Code__c, BillingCountry,
                ACG_Military_City__c, ACG_Military_City_Detail__c, Phone, PersonHomePhone, ACG_Primary_Phone_Type__c, ACG_Secondary_Phone_Type__c, ACG_Alternate_Phone__c,
                ACG_Alternate_Phone_Type__c, Proxy_UI__c, Census_Block__c, Delivery_Point_Barcode__c, Delivery_Point__c, Carrier_Route__c, State_FIPS__c, Country_FIPS__c,
                Census_Tract__c, Zip4__c, BillingCountryCode, Is_Address_Valid__c FROM Account WHERE Id =:accountId];

                System.debug('JK--Accounts-->'+accountList);
                if(!accountList.isEmpty()) {
                    String ipAdd = MembershipController.getIpAddressOfCurrentUser();
                    if(ipAdd != null) {
                        INTUpsertCustomerInPOCResponse_Wrapper response = CreateCustomerInPOCHandler.invokeCreateCustomerAPI(accountList[0], ipAdd, null, false);
                        System.debug('CreateCustomerInPOCQueueable-->response-->'+response);
                        if(response != null && response.customer != null){
                            if(response.statusCode == 200 && response.errorMessage == null){
                                //query account and update proxyUI, hui and POCId
                                Account acc = new Account(Id=accountList[0].Id, Proxy_UI__c=response.customer.proxyUi, POC_ID__c=response.customer.ui);
                                Database.SaveResult sr = Database.update(acc, false);
                                if(sr.isSuccess()) {
                                    apiResponse.resultMessage = 'Success';
                                    apiResponse.variant = 'success';
                                    apiResponse.accRecord = acc;
                                } else {
                                    apiResponse.resultMessage = 'There was an error saving the record in salesforce. Please try again.';
                                    apiResponse.variant = 'error';
                                }
                            }else{
                                apiResponse.resultMessage = String.valueOf(response.errorMessage);
                                apiResponse.variant = 'error';
                            }
                            
                        }else{
                            apiResponse.resultMessage = 'Error';
                            apiResponse.variant = 'error';
                        }
                    }
                }
            }
            return apiResponse;
    }

    public class APICalloutResponseWrapper{
        @AuraEnabled
        public Account accRecord;
        @AuraEnabled
        public INTAddressValidationResponse_Wrapper addressResponse;
        @AuraEnabled
        public String resultMessage; 
        @AuraEnabled
        public String variant;
        @AuraEnabled
        public String proxyId = ''; 
    }
    
    public class CustomException extends Exception {}
}