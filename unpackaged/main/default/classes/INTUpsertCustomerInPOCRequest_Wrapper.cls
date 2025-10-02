/**** Apex Class Name:    INTUpsertCustomerInPOCRequest_Wrapper
* Description        :    This class is used to prepare request for upserting a customer in POC   
* Modification Log   :
* Test Class Name    :    INTUpsertCustomerInPOCAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Oct 04 2021             Created
*********************************************************************************/

public without sharing class INTUpsertCustomerInPOCRequest_Wrapper {
    
    @AuraEnabled
    public String ui = '';
    @AuraEnabled
    public String hui = '';
    @AuraEnabled
    public String prefix = '';
    @AuraEnabled
    public String suffix = '';
    @AuraEnabled
    public String firstName = '';
    @AuraEnabled
    public String lastName = '';
    @AuraEnabled
    public String middleInitial = '';
    @AuraEnabled
    public String gender = '';
    @AuraEnabled
    public List<Address> address = new List<Address>();
    @AuraEnabled
    public List<TemporaryAddress> temporaryAddress = new List<TemporaryAddress>();
    @AuraEnabled
    public String emailId = '';
    @AuraEnabled
    public String birthDate = '';
    @AuraEnabled
    public List<Phones> phones = new List<Phones>();
    @AuraEnabled
    public Agent agent = new Agent();
    
    public without sharing class Address{
        @AuraEnabled
        public String addrTypeDetail = '';
        @AuraEnabled
        public String addressLine1 = '';
        @AuraEnabled
        public String addressLine2 = '';
        @AuraEnabled
        public String city = '';
        @AuraEnabled
        public String state = '';
        @AuraEnabled
        public String zip5 = '';
        @AuraEnabled
        public String zip4 = '';
        @AuraEnabled
        public String declinedVerification = '';
        @AuraEnabled
        public Decimal latitude;
        @AuraEnabled
        public Decimal longitude;
        @AuraEnabled
        public String censusBlock = '';
        @AuraEnabled
        public String deliveryPointBarcode = '';
        @AuraEnabled
        public String deliveryPoint = '';
        @AuraEnabled
        public String carrierRoute = '';
        @AuraEnabled
        public String foreignPostalCode = '';
        @AuraEnabled
        public String foreignCountry = '';
        @AuraEnabled
       	public Decimal stateFIPS;
        @AuraEnabled
      	public Decimal countryFIPS;
        @AuraEnabled
      	public String censusTract = '';
    }
    
    public without sharing class TemporaryAddress{
        @AuraEnabled
        public String addressLine1 = '';
        @AuraEnabled
        public String addressLine2 = '';
        @AuraEnabled
        public String city = '';
        @AuraEnabled
        public String state = '';
        @AuraEnabled
        public String zip5 = '';
        @AuraEnabled
        public String zip4 = '';
        @AuraEnabled
        public String foreignInd = '';
        @AuraEnabled
        public String foreignPostalCode = '';
        @AuraEnabled
        public String foreignCountry = '';
        @AuraEnabled
        public String startDate = '';
        @AuraEnabled
        public String endDate = '';
        @AuraEnabled
        public String recurringInd = '';
        @AuraEnabled
        public String activeInd = '';
        @AuraEnabled
        public String tempInd = '';
    }
    
    public without sharing class Phones{
        @AuraEnabled
        public String phoneType = '';
        @AuraEnabled
        public String phoneNumber = '';
        @AuraEnabled
        public String areaCode = '';
        @AuraEnabled
        public String countryCode = '';
    }
    
    public without sharing class Agent{
        @AuraEnabled
        public String pId = '';
        @AuraEnabled
        public String branchCode = '';
        @AuraEnabled
        public String ipAddress = '';
    }
}