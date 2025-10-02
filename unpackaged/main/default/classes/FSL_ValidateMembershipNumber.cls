/**
 * @File Name          : FSL_ValidateMembershipNumber.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06-16-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/28/2020   Rajesh Kemisetti     Initial Version
 * 1.0    9/14/2020   Dylan Truong          ERS-218775 : When Valid Membership is Validated to FSL, Remove the Payment Required Flag  
 * 2.0    5/14/2020   Dylan Truong         ERS-221083 MembershipValidation Phrase 2: Partial Search
**/
public class FSL_ValidateMembershipNumber {

    public class MembershipSearchRequest{     
        public String  sourceClubCode {get;set;} //required
        public Boolean isLocalMember  {get;set;} //required
        public String  memberClubCode {get;set;} //required
        public String  memberNumber   {get;set;} //required
        public Boolean includeCallCounts {get;set;} //optional
        public String  serviceDate {get;set;} //required  
        public String lastName {get;set;}
        public String firstName {get;set;}                  
        public String phoneNumber {get;set;} //khtx in progress                
        public String zipCode {get;set;} //khtx in progress                
        public String policyNumber {get;set;} //khtx in progress ??               
        public String quoteNumber {get;set;} //khtx in progress  ??             
    }

    public class ResponseHeader {
        public Integer responseStatusCode {get;set;}
        public String responseDescription {get; set;}
        public String responseTransactionId {get; set;}
    }

    public class RequestResponse{
        public HttpRequest request {get;set;}
        public HttpResponse response {get;set;}
    }

    
    public RequestResponse invokeCallout(String requestData, String endPointMetadata){
        Util_ManageAccessTokens utilToken = new Util_ManageAccessTokens();
      //  String token = utilToken.callOAuth('Mulesoft_OAuth');
        String token = retrieveToken(); //EMI -- SSFI-662--11-18-2024
        Http http = new Http(); 
        HttpRequest request = new HttpRequest();
        HttpResponse response;
        FSL_Service_Endpoints__c searchEndpoint;
        if(token != null){
            if(Test.isRunningTest()){
                searchEndpoint = new FSL_Service_Endpoints__c(Timeout__c = 3000, Endpoint_URL__c='testSearch');
            }else{
                searchEndpoint = FSL_Service_Endpoints__c.getValues(endPointMetadata);
            }
            request.setMethod('GET');
            request.setHeader('Content-Type','application/json;charset=UTF-8');
             //request.setHeader('Content-Type','application/x-www-form-urlencoded;charset=UTF-8'); //EMI -- SSFI-662--11-18-2024
            request.setHeader('Authorization','Bearer '+token);
            if(searchEndpoint.Timeout__c != null){
                request.setTimeout(integer.ValueOf(searchEndpoint.Timeout__c));
            }
            if(!string.isEmpty(searchEndpoint.Endpoint_URL__c)){
                String endpoint = searchEndpoint.Endpoint_URL__c;
                String queryParams = constructURL(requestData);               
                request.setEndpoint(endpoint+'?'+queryParams);
            }
            if(String.isNotBlank(searchEndpoint.Client_Cert_Name__c)){
                request.setClientCertificateName(searchEndpoint.Client_Cert_Name__c);
            }
            response = http.send(request);
            System.debug('invokeCallout Response: '+response);//check here invalid token.//EMI
        }
        RequestResponse rr = new RequestResponse();
        rr.request = request;
        rr.response = response;
        return rr;
    } 
    
    /**EMI -- SSFI-662--11-14-2024**/
    
    public String retrieveToken() {
        System.debug('Starting retrieveToken method');
        
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        if (orgPart == null) {
            System.debug('Cache partition not found or not configured.');
            return null;
        }
        // Retrieve token and expiry from cache
        String orgCacheToken = (String) orgPart.get('token');
        DateTime expiry = (DateTime) orgPart.get('expiry');
        
        System.debug('Cached Token: ' + orgCacheToken);
        System.debug('Cached Expiry: ' + expiry);
        
        // Use cached token if valid
        if (String.isNotBlank(orgCacheToken) && expiry != null && expiry > System.now()) {
            System.debug('Token is still valid. Returning cached token.');
            return orgCacheToken;
        }
        
        System.debug('Token is expired or missing. Fetching a new token...');
        try {
            Util_ManageAccessTokens utilToken = new Util_ManageAccessTokens();
            Map<String, String> newAccessToken = utilToken.callOAuth('Mulesoft_OAuth'); // Fetch token
            
            // Extract the token and expires_in values from the Map
            String token = newAccessToken.get('access_token');
            String expiresInStr = newAccessToken.get('expires_in');
            
            if (String.isNotBlank(token) && String.isNotBlank(expiresInStr)) {
                Integer expiresIn = Integer.valueOf(expiresInStr);
                expiry = System.now().addSeconds(expiresIn);
                
                // Store the new token and expiry in the cache
                orgPart.put('token', token);
                orgPart.put('expiry', expiry);
                
                System.debug('New token fetched and stored: ' + token);
                System.debug('New expiry calculated: ' + expiry.format('yyyy-MM-dd HH:mm:ss'));
                
                return token;
            } else {
                throw new CalloutException('Failed to retrieve valid access_token or expires_in from OAuth response.');
            }
        } catch (Exception ex) {
            System.debug('Error fetching new token: ' + ex.getMessage());
            throw new CalloutException('Failed to fetch token due to: ' + ex.getMessage());
        }
    }

	/**EMI -- SSFI-662--11-14-2024**/
 
	/*
	FSL_ValidateMembershipNumber fslObj = new FSL_ValidateMembershipNumber();
    String token = fslObj.retrieveToken();
    System.debug('Retrieved Token: ' + token);
	*/
 
     /**EMI -- SSFI-662--11-14-2024**/
    
    private String constructURL(String requestData){
        String queryParams = '';
        Map<String, Object> requestDataMap = (Map<String, Object>) JSON.deserializeUntyped(requestData);
        for(String key: requestDataMap.keySet()){
            Object value = (Object) requestDataMap.get(key);
            if(value instanceof String && !String.isEmpty(value.toString()) || (value instanceof Boolean && Boolean.valueOf(value) != null)){
                queryParams+= key + '=' + EncodingUtil.urlEncode(String.ValueOf(requestDataMap.get(key)),'UTF-8') + '&';
            }else{
                queryParams+= key + '=' + '&';
            }
        }
        return queryParams.removeEnd('&');
    }

    public abstract class WebCallService {
        protected FSL_Service_Endpoints__c serviceEndpoints;
        protected HttpRequest request;
        protected String requestData; 
        
        public WebCallService(FSL_Service_Endpoints__c serviceEndpoints) {
            this.serviceEndpoints = serviceEndpoints == null? new FSL_Service_Endpoints__c(): serviceEndpoints;
        }
        abstract public HttpResponse invokeWebRequest(String requestData);
        abstract protected void setupHttpRequest();
        public virtual HttpRequest retrieveHttpRequest() {
            return this.request ;
        }
    }

    public class MembershipWebService extends WebCallService {

        public MembershipWebService( FSL_Service_Endpoints__c serviceEndpoints) {
            super(serviceEndpoints);
            setupHttpRequest();
        }

        public override HttpResponse invokeWebRequest(String requestData) {
            Http http = new Http();
            HttpResponse response = new HttpResponse();  
            request.setBody(requestData);  
            FSL_ApplicationLogCreator.serviceStartTime = system.now();
            response = http.send(request);
            FSL_ApplicationLogCreator.serviceEndTime = system.now();
            return response;
        }
        @TestVisible
        public override HttpRequest retrieveHttpRequest() {
            return this.request;
        }
    

        protected override void setupHttpRequest() {
            System.debug('Endpoint ==> ' + serviceEndpoints);
            request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            
            if (serviceEndpoints.client_id__c != null){ 
                request.setHeader('client_id', serviceEndpoints.client_id__c);
            }
            if(serviceEndpoints.client_secret__c != null) {
                request.setHeader('client_secret', serviceEndpoints.client_secret__c);
            }
            if(String.isNotBlank(serviceEndpoints.Client_Cert_Name__c)){
                request.setClientCertificateName(serviceEndpoints.Client_Cert_Name__c);
            }
            if(serviceEndpoints.Timeout__c != null){
                request.setTimeout(integer.ValueOf(serviceEndpoints.Timeout__c));
            }       
            if(!string.isEmpty(serviceEndpoints.Endpoint_URL__c)){
                request.setEndpoint(serviceEndpoints.Endpoint_URL__c);
            }else if (!string.isEmpty(serviceEndpoints.Named_Credential__c)){
                request.setEndpoint(serviceEndpoints.Named_Credential__c);
            }

        }
        
    }

    public class ValidateMembershipService {
        public Map<String,String> saveMemberData(String memberWrapperStr, String woId, String internalConId,
                                                 FSL_Contact.IContactService contactService, 
                                                 FSL_WorkOrder.IWorkOrderService workOrderService ) {
            Map<String, String> responseMap = new Map<String,String>();
            String message = 'Not able to update the membership, please check Application Logs or contact Administrator for detail !'; 
            String statusType = 'Error';
            Boolean isError = true;
            try {
                if(String.isNotBlank(memberWrapperStr)) { 
                    if(String.isNotBlank(woId)) {
                        FSL_LightningCustomerWrapper wrap = (FSL_LightningCustomerWrapper)JSON.deserialize(memberWrapperStr, FSL_LightningCustomerWrapper.class);   
                        List<Contact> contacts = contactService.createOrUpdateContact(wrap, internalConId);    
                        if(!contacts.isEmpty()) {
                            if(string.isNotBlank(contacts[0].id)) {
                                workOrderService.updateContactAndRemoveCODFromWorkOrder(woId, contacts[0]);
                                message = 'Work Order Updated Successfully!!!';
                                statusType = 'Success';
                                isError = false;
                            } 
                        } 
                    }     
                    String emptyWoId = String.isBlank(woId)?' Empty WorkOrderId\n ':''; 
                    responseMap.put('Status', statusType);
                    responseMap.put('Message', message);
                    message = emptyWoId + message;
                    FSL_ApplicationLogCreator.SaveMemberDataAppLog('saveMemberData',isError,message, woId);          
                }
            }catch(Exception ex) {    
                responseMap.put('Status', 'Error');
                responseMap.put('Message', message);   
                message = ex.getMessage() ;            
                FSL_ApplicationLogCreator.SaveMemberDataAppLog('saveMemberData',true,ex.getMessage()+' '+ex.getStackTraceString(),woId);
                system.debug('Exception:'+ex.getMessage()+' '+ex.getStackTraceString());
            }
            return responseMap;
        }

        public FSL_LightningCustomerWrapper getContactsNew(String memberNumber, String workOrdId,
                                                            MembershipSearchRequest memberSearchData,String endPointMetadata){
            HttpRequest request;
            HttpResponse response;
            FSL_LightningCustomerWrapper customerWrapper;// = new FSL_LightningCustomerWrapper();
            DateTime serviceStartTime = system.now();
            
            try {
                string requestData = JSON.serialize(memberSearchData, true);
                System.debug('FSL_ValidateMembershipNumber.getContacts -- requestData: ' + requestData);
                Http http = new Http(); 
                FSL_ValidateMembershipNumber.RequestResponse requestResponse= new FSL_ValidateMembershipNumber().invokeCallout(requestData,endPointMetadata);
                request = requestResponse.request;
                response = requestResponse.response;
                if(Test.isRunningTest()) {
                    FSL_LightningCustomerWrapper result = new FSL_LightningCustomerWrapper();
                    result.statusCode = String.valueOf(response.getStatusCode());
                    result.statusDescription = response.getStatus();
                    return result;
                } else {
                    // Don't rely on the Http return Code but instead try to read it from the payload
                    customerWrapper = createMembershipDatailResponse(request,response,workOrdId);
                }
            } catch (JSONException e) { 
                System.debug('JSONParsingException::' + e.getMessage());
                String message = e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(request,response,'getContacts',true,message,workOrdId);
            }
            catch (Exception e) { 
                System.debug('GeneralException::' + e.getMessage());
                String message = e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(request,response,'getContacts',true,message,workOrdId); 
            }

            return customerWrapper;
        }

        public FSL_LightningCustomerWrapper getContacts (String memberNumber, String workOrdId,
                                                         MembershipSearchRequest memberSearchData, 
                                                         FSL_ValidateMembershipNumber.WebCallService membershipService) {
            FSL_LightningCustomerWrapper customerWrapper;// = new FSL_LightningCustomerWrapper();
            DateTime serviceStartTime = system.now();
            HttpResponse response;
            try {
                string requestData = JSON.serialize(memberSearchData, true);
                System.debug('FSL_ValidateMembershipNumber.getContacts -- requestData: ' + requestData);
                response = membershipService.invokeWebRequest(requestData);
                if(Test.isRunningTest()) {
                    FSL_LightningCustomerWrapper result = new FSL_LightningCustomerWrapper();
                    result.statusCode = String.valueOf(response.getStatusCode());
                    result.statusDescription = response.getStatus();
                    return result;
                } else {
                    // Don't rely on the Http return Code but instead try to read it from the payload
                    customerWrapper = createMembershipDatailResponse(membershipService.retrieveHttpRequest(),response,workOrdId);
                }
            } catch (JSONException e) { 
                System.debug('JSONParsingException::' + e.getMessage());
                String message = e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(membershipService.retrieveHttpRequest(),response,'getContacts',true,message,workOrdId);
            }
            catch (Exception e) { 
                System.debug('GeneralException::' + e.getMessage());
                String message = e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(membershipService.retrieveHttpRequest(),response,'getContacts',true,message,workOrdId); 
            }

            return customerWrapper;
        }

        public FSL_PartialLookupWrapper partialSearch(String workOrdId, MembershipSearchRequest memberSearchData, 
                                                      FSL_ValidateMembershipNumber.WebCallService membershipService) {
            HttpResponse response;
            FSL_PartialLookupWrapper memberWrapper = new FSL_PartialLookupWrapper();
            memberWrapper.status = 'Error';
            memberWrapper.message = 'Please check Application Logs or contact administrator for details !';
            try {
                String requestData = JSON.serialize(memberSearchData, true);
                System.debug('FSL_ValidateMembershipNumber.partialSearch -- requestData: ' + requestData);
                response = membershipService.invokeWebRequest(requestData);
                if(Test.isRunningTest()) {
                    FSL_PartialLookupWrapper result = new FSL_PartialLookupWrapper();
                    result.status = String.valueOf(response.getStatusCode());
                    result.message = response.getStatus();
                    return result;
                } else {
                    memberWrapper = createPartialMemberLookUpResponse(response, membershipService.retrieveHttpRequest(),workOrdId);
                }
            } catch (JSONException e) { 
                System.debug('JSONParsingException::' + e.getMessage());
                String message = 'JSONParsingException \n ' +  e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(membershipService.retrieveHttpRequest(),response,'PartialSearch',true,message, workOrdId);
            }
            catch (Exception e) { 
                System.debug('GeneralException::' + e.getMessage());
                String message = 'General Exception \n ' + e.getStackTraceString();
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(membershipService.retrieveHttpRequest(),response,'PartialSearch',true,message, workOrdId); 
            }
            return memberWrapper;
        }

        private FSL_PartialLookupWrapper createPartialMemberLookUpResponse(HttpResponse response, HttpRequest request, String workOrdId) {
            FSL_PartialLookupWrapper memberWrapper = new FSL_PartialLookupWrapper();
            String responseBody = response.getBody();
            system.debug('Response Body:'+responseBody);
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);  
            Integer status = (Integer) response.getStatusCode();
            if (status == 200 && responseMap.get('statusCode') == 200) {
                memberWrapper = (FSL_PartialLookupWrapper) JSON.deserialize(responseBody, FSL_PartialLookupWrapper.class); 
                memberWrapper.status = 'Success';
                memberWrapper.message = '';
            }
            else {
                memberWrapper.status = 'Error';
                memberWrapper.message = 'Unable to retrieve member\'s information. Please check Application Log or contact administrator for details!';
                FSL_ApplicationLogCreator.insertMemberValidationAppLog(request, response, 'PartialSearch', false, (String) responseMap.get('statusDescription'), workOrdId);
            }  
            return memberWrapper;
        }

        public FSL_LightningCustomerWrapper createMembershipDatailResponse(HttpRequest request, HttpResponse response, String workOrdId) {
            FSL_LightningCustomerWrapper customerWrapper = new FSL_LightningCustomerWrapper();
            string responseBody = response.getBody();
            system.debug('Response Body:'+responseBody);
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);  
            ResponseHeader resHeader = extractResponseHeader(responseMap);
            if(resHeader.responseStatusCode != 200) {
                customerWrapper = createUnsuccessfulResponse(resHeader);
               //Vishnu FSL_ApplicationLogCreator.insertMemberValidationAppLog(request,response,'getContacts',true,'',workOrdId);
            }else{
                customerWrapper = createSuccessfulResponse(responseMap,resHeader);
               //Vishnu FSL_ApplicationLogCreator.insertMemberValidationAppLog(request,response,'getContacts',false,'',workOrdId);
            }
            return customerWrapper;
        }

        @TestVisible
        private ResponseHeader extractResponseHeader(Map<String,Object> response) {
            ResponseHeader resHeader = new ResponseHeader();
            try {
                //ERS-229202
                //NOTE: statusCode can be an integer or a string so must use Integer.valueOf
                //resHeader.responseStatusCode  = (Integer)response.get('statusCode');
                resHeader.responseStatusCode  = Integer.valueOf(response.get('statusCode'));

                resHeader.responseDescription = (String)response.get('statusDescription');
                resHeader.responseTransactionId = (String)response.get('transactionId');

            } catch (Exception ex){
                resHeader.responseStatusCode = 500;
                resHeader.responseDescription = 'Invalid Response';
            }
            return resHeader;
        }

        private FSL_LightningCustomerWrapper createUnsuccessfulResponse(ResponseHeader resHeader) {
            FSL_LightningCustomerWrapper customerWrapper = new FSL_LightningCustomerWrapper();
            customerWrapper.statusDescription = resHeader.responseDescription;
            customerWrapper.statusCode = string.valueOf(resHeader.responseStatusCode);
            system.debug('customerWrapper:** '+customerWrapper);
            return customerWrapper;
        }

        private FSL_LightningCustomerWrapper createSuccessfulResponse(Map<String,Object> response, ResponseHeader resHeader) {
            FSL_LightningCustomerWrapper customerWrapper = new FSL_LightningCustomerWrapper();
            string customerJSON = JSON.serializePretty(response.get('customer'), true); 
            system.debug('Customer: '+customerJSON);
            
            customerWrapper = (FSL_LightningCustomerWrapper) JSON.deserialize(customerJSON, FSL_LightningCustomerWrapper.class);                                
            if(customerWrapper.memberships!=null){
                for(FSL_LightningMembershipWrapper imembership : customerWrapper.memberships){
                    customerWrapper.membership = imembership;
                    break;
                }
            }
            //customerWrapper.statusDescription = getWarningMessage(customerWrapper);
            customerWrapper.statusDescription = '';
            customerWrapper.statusCode = string.valueOf(resHeader.responseStatusCode);
            customerWrapper.transactionId = string.valueOf(resHeader.responseTransactionId);            
            system.debug('customerWrapper: '+customerWrapper);
            return customerWrapper;
        }

        @TestVisible
        public MembershipSearchRequest createMemberSearchData(string memberNumber, String firstName, String lastName, String clubCode) {
            MembershipSearchRequest requestwrap = new MembershipSearchRequest();
            //sourceClubCode: Custom label that is the org code (Car: 111, ACG: 014, ACE: 004)
            //Some clubs have multiple codes with a ; delimiter
            list<string> sourceclubCodes = Label.FSL_SourceClubCode.split(';');
            requestwrap.sourceClubCode = sourceclubCodes[0];

            //ERS-229007
            string memberClubCode = String.isNotBlank(memberNumber) && memberNumber.length() == 16 ? memberNumber.substring(3,6) : (clubCode == null ? requestwrap.sourceClubCode : clubCode);
            requestwrap.memberClubCode = memberClubCode;

            requestwrap.isLocalMember  = false;

            requestwrap.memberNumber   = memberNumber;
            requestwrap.serviceDate    = String.valueOf(Date.Today()) ;
            requestwrap.includeCallCounts = false;
            requestwrap.firstName = firstName;
            requestwrap.lastName = lastName;
            return requestwrap;
        }
        /**
        * @description Returns a summary list of impairments found in response to a Membership Validation query
        * @author Shankar Krishnan | 03/18/2021
        * @param customerWrapper 
        * @return string 
        **/
        @TestVisible
        private String getWarningMessage(FSL_LightningCustomerWrapper customerWrapper) {
        
            List<String> messages = new List<String>();
            String message = '';

            if ( customerWrapper.impairments != null)  {
                try{
                    Integer ndx = 1;
                    for( FSL_MembershipImpairmentWrapper impairment : customerWrapper.impairments) {
                            messages.add( '(' + ndx + ') ' + impairment.message);
                            ndx++;
                    }
                    message = String.join(messages, '\n ');

                    if ( !String.isBlank(message) ) {
                        message = Label.FSL_Membership_Impairments_Dialog_Header + '\n\n' + message;
                    }
                }
                catch (Exception ex) {
            //         // possibly no impairments came in the JSON
                }
            }
            return message;
        }
    }

    /**
    * @description 
    * @author Rajesh Kemisetti | 5/13/2020 
    * @param memberNumber 
    * @param workOrdId 
    * @return FSL_LightningCustomerWrapper 
    **/
    @AuraEnabled
    public static FSL_LightningCustomerWrapper validateMemberNumber(String memberNumber,String workOrdId) {
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService  = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        MembershipSearchRequest memberSearchData = membershipService.createMemberSearchData(memberNumber, null, null, null);
        //return membershipService.getContacts(memberNumber, workOrdId, memberSearchData, new FSL_ValidateMembershipNumber.MembershipWebService(FSL_Service_Endpoints__c.getValues('Member_Lookup')));
        return membershipService.getContactsNew(memberNumber, workOrdId, memberSearchData,'Member_Lookup');
    }

    /**
    * @description 
    * @author Rajesh Kemisetti | 5/13/2020 
    * @param contactId 
    * @return Contact 
    **/
    @AuraEnabled
    public static Contact getContactRecord(String contactId){
        FSL_Contact.IContactService contactService = (new FSL_Contact.Factory()).createService();
        Set<Id> ids = new Set<Id>();
        ids.add(contactId);
        return contactService.getContactsById(ids)[0];
    }
    
    /**
    * @description 
    * @author Rajesh Kemisetti | 5/13/2020 
    * @param memberWraperStr 
    * @param woId 
    * @param internalConId 
    * @return map<String, string> 
    **/
    @AuraEnabled
    public static map<String, string> saveMemberData(String memberWraperStr,String woId, String internalConId) {
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService  = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        return membershipService.saveMemberData(memberWraperStr, woId, internalConId, (new FSL_Contact.Factory()).createService(), (new FSL_WorkOrder.Factory()).createService());
    }
    
    @AuraEnabled
    public static FSL_PartialLookupWrapper partialSearch(String firstName,String lastName,String clubCode, String workOrderId){
        FSL_ValidateMembershipNumber.ValidateMembershipService membershipService  = new FSL_ValidateMembershipNumber.ValidateMembershipService();
        MembershipSearchRequest memberSearchData = membershipService.createMemberSearchData('', firstName, lastName, clubCode);
        FSL_PartialLookupWrapper wrapper = membershipService.partialSearch(workOrderId, memberSearchData, new FSL_ValidateMembershipNumber.MembershipWebService(FSL_Service_Endpoints__c.getValues('Member_Search')));
        return wrapper; 
    }

}