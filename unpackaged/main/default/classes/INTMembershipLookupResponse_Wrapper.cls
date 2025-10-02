/**** Apex Class Name    :    ACG_INTMembershipLookupResponse_Wrapper
* Description        :    This class is used to prepare response for membership lookup api call   
* Modification Log   :
* Test Class Name    :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Dhruv Javiya               Aug 12 2021             Created
*********************************************************************************/
public  without sharing class INTMembershipLookupResponse_Wrapper {
    
    public class ResponseHeaders{
        @AuraEnabled
        public String tranId;
        @AuraEnabled
        public String tranCode;
        @AuraEnabled
        public String tranStatus;
        @AuraEnabled
        public String timeStamp;
        @AuraEnabled
        public String tranStatusDescription;
    }
    
    public class Phone{
        @AuraEnabled
        public String phoneType;
        @AuraEnabled
        public String phonNumber;
        @AuraEnabled
        public String isPrimary;
        @AuraEnabled
        public String phoneExtension;
        @AuraEnabled
        public Boolean smsOptIn;
    }
    
    public class Address{
        @AuraEnabled
        public String addrType;
        @AuraEnabled
        public String addressLine1;
        @AuraEnabled
        public String addressLine2;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String postCode;
        @AuraEnabled
        public String county;
        @AuraEnabled
        public String country;
    }
    
    public class AssociatedRole{
        @AuraEnabled
        public String role;
    }
    
    public class Producer{
        @AuraEnabled
        public String agentType;
        @AuraEnabled
        public String agentNumber;
        @AuraEnabled
        public String dofCode;
        @AuraEnabled
        public String agentEmail;
        @AuraEnabled
        public String agentPhoneNumber;
        @AuraEnabled
        public String agentName;
        @AuraEnabled
        public String agencyName;
    }
    
    public class AddressDetail{
        @AuraEnabled
        public String addrType;
        @AuraEnabled
        public String addressLine1;
        @AuraEnabled
        public String addressLine2;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String postCode;
        @AuraEnabled
        public String county;
        @AuraEnabled
        public String country;
    }
    
    public class ProductInfo{
        @AuraEnabled
        public String isQuote;
        @AuraEnabled
        public String subCompanyCd;
        @AuraEnabled
        public String customerNumber;
        @AuraEnabled
        public String productNumber;
        @AuraEnabled
        public String sourceSystemIdentifier;
        @AuraEnabled
        public String productType;
        @AuraEnabled
        public String productStatus;
        @AuraEnabled
        public List<AssociatedRole> associatedRoles;
        @AuraEnabled
        public String productEffectiveDate;
        @AuraEnabled
        public String productExpirationDate;
        @AuraEnabled
        public Producer producer;
        @AuraEnabled
        public List<AddressDetail> addressDetail;
        @AuraEnabled
        public String productInceptionDate;
        @AuraEnabled
        public String transactionApplicableDate;
        @AuraEnabled
        public String pniClientId;
        @AuraEnabled
        public String cancelReasonCode;
        @AuraEnabled
        public String currentCarrierExpDate;
        @AuraEnabled
        public String currentCarrier;
        @AuraEnabled
        public String premierScore;
        @AuraEnabled
        public String cancellationDate;
        @AuraEnabled
        public String householdID;
        @AuraEnabled
        public String authorizationMessage;
        @AuraEnabled
        public String motorcycleCoverage;
        @AuraEnabled
        public String membershipType;
    }
    
    public class Authorize{
        @AuraEnabled
        public String returnCd;
        @AuraEnabled
        public String level;
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String transactionId;
        @AuraEnabled
        public String memberId;
        @AuraEnabled
        public String longTowMiles;
        @AuraEnabled
        public String longTowKilometers;
        @AuraEnabled
        public String rentalDays;
    }
    
    public class Customer{
        @AuraEnabled
        public String membershipId; //Need this to store full membership Id resulted from partial memebership Id search
        @AuraEnabled
        public String memberLevel;
        @AuraEnabled
        public String pniFlag;
        @AuraEnabled
        public String birthDate;
        @AuraEnabled
        public String gender;
        @AuraEnabled
        public String maritalStatus;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String otherName;
        @AuraEnabled
        public String suffix;
        @AuraEnabled
        public String licState;
        @AuraEnabled
        public String mbrSuplTelNr;
        @AuraEnabled
        public String mbrJnAaaDt;
        @AuraEnabled
        public String mbrsPaidThruDt;
        @AuraEnabled
        public List<Phone> phone;
        @AuraEnabled
        public List<Address> address;
        @AuraEnabled
        public List<ProductInfo> productInfo;
        @AuraEnabled
        public Authorize authorize;


        //No need for @AuraEnabled since it is used only by Apex codes
        public FSL_LightningEntitlementWrapper entitlement;

        public string impairmentType;

        //New Addtions
        @AuraEnabled
        public String membershipType;
        @AuraEnabled
        public String program;
        @AuraEnabled
        public String sponsor;
        @AuraEnabled
        public String membershipStatus;
        @AuraEnabled
        public Boolean isLocalClub;
        @AuraEnabled
        public String memberClubCode;
        @AuraEnabled
        public String memberClubName;
        @AuraEnabled
        public string expirationDate;
        @AuraEnabled
        public string startDate;
        @AuraEnabled
        public string primaryExpirationDate;
        @AuraEnabled
        public string primaryStartDate;
        @AuraEnabled
        public string cancellationDate;
        @AuraEnabled
        public string emailAddress;
        @AuraEnabled
        public string emailType;
        @AuraEnabled
        public String contactType;
        @AuraEnabled
        public string memberSinceDate;
    }
    
    public class Customers{
        @AuraEnabled
        public List<Customer> customer;
    }
    @AuraEnabled
    public ResponseHeaders responseHeaders;
    @AuraEnabled
    public Customers customers;
    
    
    @AuraEnabled
    public String error;
    
    @AuraEnabled
    public Integer STATUS_CODE;
    @AuraEnabled
    public String ERR_MESSAGE; 

    public String impairmentType;
    
    public static INTMembershipLookupResponse_Wrapper parse(String json) {
        return (INTMembershipLookupResponse_Wrapper) System.JSON.deserialize(json, INTMembershipLookupResponse_Wrapper.class);
    }
}