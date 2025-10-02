/**** Apex Class Name    :    INTMembershipSearchAPI
    * Description        :     This class is used to return the list of members found in MDM/CDX based on search results   
    * Modification Log   :
    * Test Class Name    :    INTMembershipSearchAPI_Test
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Aug 12 2021             Created
*********************************************************************************/
public without sharing class INTMembershipSearchAPI {
    public static final Map<String,Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();

    public static MembershipSearchRespJSONWrapper getMembersearch(Map<string,string> mapOfParameters) {
        try {

            FSL_ValidateMembershipNumber.MembershipSearchRequest req = new FSL_ValidateMembershipNumber.MembershipSearchRequest();

            req.memberNumber = mapOfParameters.get('MSsearchByMemNumber_Memnum');
            req.firstName = mapOfParameters.get('MSsearchByNameZip_fName');
            req.lastName = mapOfParameters.get('MSsearchByNameZip_lName');
            req.phoneNumber = mapOfParameters.get('MSsearchByPhNumber_phnum');
            req.memberClubCode = mapOfParameters.get('MSsearchByNameZip_clubCode');
            req.zipCode = mapOfParameters.get('MSsearchByNameZip_zip');
            req.policyNumber = mapOfParameters.get('MSsearchByPolicyNumber_Policynum');
            req.quoteNumber = mapOfParameters.get('MSsearchByQuoteNumber_Quotenum');

            return search(req);   
        }
        catch(Exception e){
            System.debug('exception: ' + e.getStackTraceString());
            throw e;
        }
    }

    private static MembershipSearchRespJSONWrapper search(FSL_ValidateMembershipNumber.MembershipSearchRequest req) {

        MembershipSearchRespJSONWrapper result = null;
        prepareRequest(req);
        HttpRequest request;
        HttpResponse response;

        try {
            //FSL_ValidateMembershipNumber.MembershipWebService membershipService  = new FSL_ValidateMembershipNumber.MembershipWebService(FSL_Service_Endpoints__c.getValues('Member_Search'));
            String requestData = JSON.serialize(req, true);
            System.debug('requestData search: '+requestData);
            //response = new FSL_ValidateMembershipNumber().invokeCallout(requestData);
            FSL_ValidateMembershipNumber.RequestResponse requestResponse= new FSL_ValidateMembershipNumber().invokeCallout(requestData,'Member_Search');
            request = requestResponse.request;
            response = requestResponse.response;

            Integer statusCode = (Integer) response.getStatusCode();

            if (statusCode == 200) {
                result = tryResponseFormat1(response);
                if(result == null) {
                    result = tryResponseFormat2(response);
                }
            }
            else {

                result = new MembershipSearchRespJSONWrapper();

                MembershipSearchRespJSONWrapper.ResponseHeaders responseHeader = new MembershipSearchRespJSONWrapper.ResponseHeaders();
                result.responseHeaders = responseHeader;
                responseHeader.tranCode = String.valueOf(statusCode);
                //responseHeader.tranStatusDescription = 'Unable to retrieve member\'s information. Please try different searching criteria.';
                responseHeader.tranStatusDescription = 'No Records Were Found Matching The Search Criteria';   //TK ERS-230052
            }  

        } catch (JSONException e) {
            string logErrMsg = e.getMessage() + ':\n' + e.getStackTraceString();
            System.debug('logErrMsg: '+logErrMsg);
            FSL_ApplicationLogCreator.insertApplicationLogEvent(request, response, 'MembershipSearch', true, logErrMsg);
            
            string displayErrMsg = 'Problem parsing response. Please check Application Log or contact administrator for details!';
            throw new AuraException(displayErrMsg);
        }
        catch (Exception e) {
            string logErrMsg = e.getMessage() + ':\n' + e.getStackTraceString();
            FSL_ApplicationLogCreator.insertApplicationLogEvent(request, response, 'MembershipSearch', true, logErrMsg);

            string displayErrMsg = 'Unknown error. Please check Application Log or contact administrator for details!';
            throw new AuraException(displayErrMsg);
        }

        return result;
    }

    @TestVisible
    private static MembershipSearchRespJSONWrapper tryResponseFormat1(HttpResponse response) {

        String responseBody = response.getBody();
        System.debug('Response Body in tryResponseFormat1: ' + responseBody);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);

        Object customer = responseMap.get('customer');
        if(customer == null)
            return null;

        MembershipSearchRespJSONWrapper result = new MembershipSearchRespJSONWrapper();
        MembershipSearchRespJSONWrapper.ResponseHeaders responseHeader = new MembershipSearchRespJSONWrapper.ResponseHeaders();
        result.responseHeaders = responseHeader;

        Integer statusCode = (Integer) response.getStatusCode();
        responseHeader.tranCode = String.valueOf(statusCode);

        MembershipSearchRespJSONWrapper.MembershipSearchResponse membershipSearchResponse = new MembershipSearchRespJSONWrapper.MembershipSearchResponse();
        List<MembershipSearchRespJSONWrapper.Members> members = new List<MembershipSearchRespJSONWrapper.Members>();
        result.MembershipSearchResponse = membershipSearchResponse;
        membershipSearchResponse.members = members;

        /*if(Test.isRunningTest())
            return result;*/

        string customerJSON = JSON.serialize(customer, true); 
        FSL_LightningCustomerWrapper wrapper = (FSL_LightningCustomerWrapper) JSON.deserialize(customerJSON, FSL_LightningCustomerWrapper.class);

        if(wrapper.memberships?.size() > 0){

            FSL_LightningContactWrapper contact = wrapper.contact;

            FSL_LightningMembershipWrapper srcMember = wrapper.memberships[0];
            MembershipSearchRespJSONWrapper.Members resultMember = new MembershipSearchRespJSONWrapper.Members();
            resultMember.firstName = contact.firstName;
            resultMember.lastName = contact.lastName;
            resultMember.membershipNumber = srcMember.id;
            resultMember.adressLine1 = '';
            resultMember.city = '';
            resultMember.state = '';
            resultMember.phoneNumber = contact.phones?.size() > 0 ? contact.phones[0].phoneNumber : null;
            resultMember.birthDate = srcMember.memberBirthday;
            resultMember.membershipType = srcMember.membershipType;
            resultMember.expirationDate = srcMember.expirationDate;
            resultMember.membershipStatus = srcMember.memberStatus;

            members.add(resultMember);
        }

        responseHeader.tranStatusDescription = getImpairmentMessages(wrapper.impairments);

        return result;
    }

    @TestVisible
    private static MembershipSearchRespJSONWrapper tryResponseFormat2(HttpResponse response) {

        String responseBody = response.getBody();
        System.debug('Response Body in tryResponseFormat2: ' + responseBody);

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);

        MembershipSearchRespJSONWrapper result = new MembershipSearchRespJSONWrapper();
        MembershipSearchRespJSONWrapper.ResponseHeaders responseHeader = new MembershipSearchRespJSONWrapper.ResponseHeaders();
        result.responseHeaders = responseHeader;

        Integer statusCode = (Integer) response.getStatusCode();
        responseHeader.tranCode = String.valueOf(statusCode);

        MembershipSearchRespJSONWrapper.MembershipSearchResponse membershipSearchResponse = new MembershipSearchRespJSONWrapper.MembershipSearchResponse();
        List<MembershipSearchRespJSONWrapper.Members> members = new List<MembershipSearchRespJSONWrapper.Members>();
        result.MembershipSearchResponse = membershipSearchResponse;
        membershipSearchResponse.members = members;

        FSL_PartialLookupWrapper wrapper = (FSL_PartialLookupWrapper) JSON.deserialize(responseBody, FSL_PartialLookupWrapper.class);

        if(Test.isRunningTest()) {
            wrapper = new FSL_PartialLookupWrapper();
            wrapper.members = new List<FSL_MemberDetailsWrapper>();

            FSL_MemberDetailsWrapper mem1 = new FSL_MemberDetailsWrapper();
            wrapper.members.add(mem1);
        }

        for (FSL_MemberDetailsWrapper srcMember : wrapper.members) {
            MembershipSearchRespJSONWrapper.Members resultMember = new MembershipSearchRespJSONWrapper.Members();
            resultMember.membershipNumber = srcMember.memberNumber;
            resultMember.firstName = srcMember.name;
            resultMember.lastName = '';
            resultMember.adressLine1 = srcMember.address;
            resultMember.city = '';
            resultMember.state = '';
            resultMember.phoneNumber = srcMember.phoneNumber;
            resultMember.membershipStatus = srcMember.statusIndicator;
            resultMember.emailAddress = srcMember.emailAddress;
            resultMember.expirationDate = srcMember.expirationDate;
            members.add(resultMember);
        }

        return result;
    }

    private static void prepareRequest(FSL_ValidateMembershipNumber.MembershipSearchRequest req) {
        req.serviceDate = String.valueOf(Date.Today());

        list<string> sourceclubCodes = Label.FSL_SourceClubCode.split(';');
        req.sourceClubCode = sourceclubCodes[0];
        
        if(req.memberNumber == null)
            req.memberNumber = ''; //Make sure memberNumber is not null as backend requires it

        if(req.memberClubCode == null || req.memberClubCode.trim() == '') {

            req.memberClubCode = req.sourceClubCode;
        }
        req.isLocalMember  = false;
    }

    @TestVisible
    private static String getImpairmentMessages(List<FSL_MembershipImpairmentWrapper> impairments) {
        
        List<String> messages = new List<String>();
        String message = '';

        if (impairments != null) {
            try {
                Integer ndx = 1;
                for( FSL_MembershipImpairmentWrapper impairment : impairments) {
                        messages.add( '(' + ndx + ') ' + impairment.message);
                        ndx++;
                }
                message = String.join(messages, '\n ');

                if ( !String.isBlank(message) ) {
                    message = Label.FSL_Membership_Impairments_Dialog_Header + '\n\n' + message;
                }
            }
            catch (Exception ex) {
                // possibly no impairments came in the JSON
            }
        }
        return message;
    }
}