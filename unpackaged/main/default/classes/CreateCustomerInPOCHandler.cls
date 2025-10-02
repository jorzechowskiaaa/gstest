/********************************************************************************************************
Apex Class Name     : CreateCustomerInPOCHandler
Created Date        : 12 October 2021
Function            : Aura Enabled Class for acg_cmf_customerInfo LWC
Author              : Deloitte Consulting

********************************************************************************************************/
public without sharing class CreateCustomerInPOCHandler {
    /*
    @description: method to invoke create customer in POC API
    @return: results in the Results Wrapper format on the basis of API invoked
    @param1: request in INTUpsertCustomerInPOCRequest_Wrapper wrapper 
    @date: 12 October 2021
    */
    public static INTUpsertCustomerInPOCResponse_Wrapper invokeCreateCustomerAPI(Account personAccountRec, String ipAddress, INTAddressValidationResponse_Wrapper addressResponse, Boolean noAddressResponse){
        System.debug('JK@--personAccountRec:: ' + personAccountRec);
        
        try{
            INTUpsertCustomerInPOCRequest_Wrapper custAccWrap = createRequestParams(personAccountRec, ipAddress, addressResponse, noAddressResponse);
            System.debug('JK@--custAccWrap:: ' + custAccWrap);
            INTUpsertCustomerInPOCResponse_Wrapper response = INTUpsertCustomerInPOCAPI.upsertCustomer(custAccWrap);
            if(response == null){
                throw new CustomException(Label.ACG_NO_RESPONSE);    
            }else if(response.statusCode != 200){
                throw new CustomException(response.errorMessage);
            }else{
                System.debug('Response received --> '+ response);
            }
            return response;
        }catch(Exception exp){
            System.debug('Exception has occurred --> '+exp.getMessage()+' at Line Number : '+exp.getLineNumber());
            return null;
        } 
        
    }

    public static INTUpsertCustomerInPOCRequest_Wrapper createRequestParams(Account customerAccount, String ipAddress, INTAddressValidationResponse_Wrapper addressResponse, Boolean noAddressResponse){
        User loggedInUser = [SELECT Id, Name, FirstName, LastName, Email, Branch_Number__c, EmployeeNumber FROM User WHERE Id =: UserInfo.getUserId()];
        

        INTUpsertCustomerInPOCRequest_Wrapper wrapRec = new INTUpsertCustomerInPOCRequest_Wrapper();
        
        wrapRec.firstname = customerAccount.FirstName;
        wrapRec.middleInitial = customerAccount.MiddleName;
        wraprec.lastName = customerAccount.LastName;
        wrapRec.prefix = customerAccount.ACG_Prefix__c;
        wrapRec.suffix = customerAccount.ACG_Suffix__c;
        wrapRec.gender = customerAccount.ACG_Gender__c != null ? customerAccount.ACG_Gender__c : '';
        wrapRec.emailId = customerAccount.PersonEmail;
        wrapRec.birthdate = String.valueOf(customerAccount.ACG_Date_of_Birth__c);
        wrapRec.ui = '';
        wrapRec.hui = '';
         
        //populate Phone
        List<INTUpsertCustomerInPOCRequest_Wrapper.Phones> phoneList = new List<INTUpsertCustomerInPOCRequest_Wrapper.Phones>();
        INTUpsertCustomerInPOCRequest_Wrapper.Phones primaryPhnRecord = new INTUpsertCustomerInPOCRequest_Wrapper.Phones();
        primaryPhnRecord.phoneNumber = customerAccount.Phone != null ? customerAccount.Phone.replaceAll('\\D','').right(7) : null;
        primaryPhnRecord.phoneType = customerAccount.ACG_Primary_Phone_Type__c != null && customerAccount.ACG_Primary_Phone_Type__c != 'Mobile' ? customerAccount.ACG_Primary_Phone_Type__c : 'Cell';
        primaryPhnRecord.areaCode = customerAccount.Phone != null ? customerAccount.Phone.replaceAll('\\D','').left(3) : null;
        primaryPhnRecord.countryCode = '';
        phoneList.add(primaryPhnRecord);

        if(customerAccount.PersonHomePhone != null ){
            INTUpsertCustomerInPOCRequest_Wrapper.Phones secPhnRecord = new INTUpsertCustomerInPOCRequest_Wrapper.Phones();
            secPhnRecord.phoneNumber = customerAccount.PersonHomePhone.replaceAll('\\D','').right(7);
            //Added by Prateek Jain
            secPhnRecord.phoneType = customerAccount.ACG_Secondary_Phone_Type__c != null && customerAccount.ACG_Secondary_Phone_Type__c != 'Mobile' ? customerAccount.ACG_Secondary_Phone_Type__c : 'Cell';
            secPhnRecord.areaCode = customerAccount.PersonHomePhone.replaceAll('\\D','').left(3);
            secPhnRecord.countryCode = '';
            phoneList.add(secPhnRecord);
        }
        
        if(customerAccount.ACG_Alternate_Phone__c != null){
            INTUpsertCustomerInPOCRequest_Wrapper.Phones alternatePhone = new INTUpsertCustomerInPOCRequest_Wrapper.Phones();
            alternatePhone.phoneNumber = customerAccount.ACG_Alternate_Phone__c.replaceAll('\\D','').right(7);
            alternatePhone.phoneType = customerAccount.ACG_Alternate_Phone_Type__c == 'Mobile' ? 'Cell' : customerAccount.ACG_Alternate_Phone_Type__c;
            alternatePhone.areaCode = customerAccount.ACG_Alternate_Phone__c.replaceAll('\\D','').left(3);
            alternatePhone.countryCode = '';
            phoneList.add(alternatePhone);
        }
        wrapRec.Phones = phoneList;
        
        //populate agent
        INTUpsertCustomerInPOCRequest_Wrapper.Agent agentRecord = new INTUpsertCustomerInPOCRequest_Wrapper.Agent();
        agentRecord.pId = loggedInUser.EmployeeNumber; //'P42029'; //
        agentRecord.branchCode = loggedInUser.Branch_Number__c;
        agentRecord.ipAddress = ipAddress;  //'0.0.0.0';  
        wrapRec.Agent = agentRecord;

        //populate address
        List<INTUpsertCustomerInPOCRequest_Wrapper.Address> addressList = new List<INTUpsertCustomerInPOCRequest_Wrapper.Address>();
        INTUpsertCustomerInPOCRequest_Wrapper.Address addressRec = new INTUpsertCustomerInPOCRequest_Wrapper.Address();
        
        if(customerAccount.BillingStreet != null){
            List<String> addArray = customerAccount.BillingStreet.split('; ');
            if(addArray.size() == 1){
                addressRec.addressLine1 = customerAccount.BillingStreet;
            }else if(addArray.size() > 1){
                addressRec.addressLine1 = addArray[0];
                addressRec.addressLine2 = addArray[1];
            }
        } 
        //addressRec.addrType = customerAccount.ACG_Address_Type__c;
        if(addressResponse == null && !noAddressResponse) {
            addressRec.addrTypeDetail = customerAccount.ACG_Address_Type_Detail__c;
            addressRec.city = customerAccount.BillingCity;
            addressRec.state = customerAccount.BillingStateCode; 
            addressRec.zip5 = customerAccount.BillingPostalCode;
            addressRec.zip4 = customerAccount.Zip4__c != null? customerAccount.Zip4__c : '';
            addressRec.declinedVerification = customerAccount.Is_Address_Valid__c;
            addressRec.latitude = customerAccount.BillingLatitude != null? customerAccount.BillingLatitude : 0.0; 
            addressRec.longitude = customerAccount.BillingLongitude != null? customerAccount.BillingLongitude : 0.0;
            addressRec.censusBlock = customerAccount.Census_Block__c != null ? customerAccount.Census_Block__c : '';
            addressRec.deliveryPointBarcode = customerAccount.Delivery_Point_Barcode__c !=null ? customerAccount.Delivery_Point_Barcode__c: '';
            addressRec.deliveryPoint = customerAccount.Delivery_Point__c != null ? customerAccount.Delivery_Point__c : '';
            addressRec.carrierRoute = customerAccount.Carrier_Route__c != null? customerAccount.Carrier_Route__c : '';
            addressRec.foreignPostalCode = customerAccount.ACG_Foreign_Postal_Code__c != null ? customerAccount.ACG_Foreign_Postal_Code__c : '';
            addressRec.foreignCountry = customerAccount.BillingCountryCode != null ? customerAccount.BillingCountryCode : '';
            addressRec.stateFIPS = customerAccount.State_FIPS__c != null ? Decimal.valueOf(customerAccount.State_FIPS__c) : 0.0;
            addressRec.countryFIPS = customerAccount.Country_FIPS__c != null ? Decimal.valueOf(customerAccount.Country_FIPS__c) : 0.0;
            addressRec.censusTract = customerAccount.Census_Tract__c!=null ? customerAccount.Census_Tract__c : '';
            addressList.add(addressRec);
            wrapRec.Address = addressList;
        } else if(addressResponse == null && noAddressResponse){
            addressRec.addrTypeDetail = customerAccount.ACG_Address_Type_Detail__c;
            addressRec.city = customerAccount.BillingCity;
            addressRec.state = customerAccount.BillingStateCode; 
            addressRec.zip5 = customerAccount.BillingPostalCode;
            addressRec.zip4 = '';
            addressRec.declinedVerification = customerAccount.Is_Address_Valid__c;
            addressRec.latitude = 0.0;
            addressRec.longitude = 0.0;
            addressRec.censusBlock = '';
            addressRec.deliveryPointBarcode = '';
            addressRec.deliveryPoint = '';
            addressRec.carrierRoute = '';
            addressRec.foreignPostalCode = '';
            addressRec.foreignCountry = '';
            addressRec.stateFIPS = 0.0;
            addressRec.countryFIPS = 0.0;
            addressRec.censusTract = '';
            addressList.add(addressRec);
            wrapRec.Address = addressList;
        } else {
            addressRec.addressLine1 = addressResponse.membershipAddress.addressLine1;
            addressRec.addressLine2 = addressResponse.membershipAddress.addressLine2;
            addressRec.addrTypeDetail = customerAccount.ACG_Address_Type_Detail__c;
            addressRec.city = addressResponse.membershipAddress.city;
            addressRec.state = addressResponse.membershipAddress.state; 
            addressRec.zip5 = addressResponse.membershipAddress.zip5;
            addressRec.zip4 = addressResponse.membershipAddress.zip4;
            addressRec.declinedVerification = customerAccount.Is_Address_Valid__c;
            addressRec.latitude = Decimal.valueOf(addressResponse.membershipAddress.latitude);
            addressRec.longitude = Decimal.valueOf(addressResponse.membershipAddress.longitude);
            addressRec.censusBlock = addressResponse.membershipAddress.censusBlock;
            addressRec.deliveryPointBarcode = addressResponse.membershipAddress.deliveryPointBarcode;
            addressRec.deliveryPoint = addressResponse.membershipAddress.deliveryPoint;
            addressRec.carrierRoute = addressResponse.membershipAddress.carrierRoute;
            addressRec.foreignPostalCode = customerAccount.ACG_Foreign_Postal_Code__c;
            addressRec.foreignCountry = customerAccount.BillingCountryCode;
            addressRec.stateFIPS = Decimal.valueOf(addressResponse.membershipAddress.stateFIPS);
            addressRec.countryFIPS = Decimal.valueOf(addressResponse.membershipAddress.countryFIPS);
            addressRec.censusTract = addressResponse.membershipAddress.censusTract;
            addressList.add(addressRec);
            wrapRec.Address = addressList;
        }

        //populate Temporary Address
        List<INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress> tempAddressList = new List<INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress>();
        INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress tempAddressRec = new INTUpsertCustomerInPOCRequest_Wrapper.TemporaryAddress();
        
        tempAddressRec.addressLine1 = '';
        tempAddressRec.addressLine2 = '';
        tempAddressRec.city = '';
        tempAddressRec.state = ''; 
        tempAddressRec.zip5 = '';
        tempAddressRec.zip4 = '';
        tempAddressRec.foreignInd = '';
        tempAddressRec.foreignPostalCode = '';
        tempAddressRec.foreignCountry = '';
        tempAddressRec.startDate = '';
        tempAddressRec.endDate = '';
        tempAddressRec.recurringInd = '';
        tempAddressRec.activeInd = '';
        tempAddressRec.tempInd = '';
        tempAddressList.add(tempAddressRec);
        wrapRec.TemporaryAddress = tempAddressList;

        return wraprec;

    }
    //for throwing custom exceptions in current class
    public class CustomException extends Exception {}
}