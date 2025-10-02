/*
  @description:     Util class for Incoming Authorization - Feedback
  @date:            OCT 18, 2021
  @author:          Salesforce Services
*/

public with sharing class AAA_FeedbackIncomingAuthUtil {

    public static final String INCOMING_AUTH = 'Incoming Authorization';
    public static final String OUTGOING_AUTH = 'Outgoing Authorization';
    public static final String STATUS_OPEN = 'Open';
    public static final String STATUS_INPROCESS = 'In Process';
    public static final String STATUS_CLOSED = 'Closed';
    public static FeedbackWrapperRequest wrapper = new FeedbackWrapperRequest();
    public static Map<String,Integration_Settings__c> mapIntSettings;
    
    //source org storing open authorization - incoming authorization
    public static void createOpenFeedback(INTMembershipLookupResponse_Wrapper.Customer customer, String accountId){
        try{
            Feedback__c feedback = new Feedback__c();
            setInitialValues(feedback, customer, accountId);
            upsert feedback;
        }Catch(Exception exp){
            throw exp;
        }   
    }
    
    private static void setInitialValues(Feedback__c feedback, INTMembershipLookupResponse_Wrapper.Customer customer, String accountId){
        INTMembershipLookupResponse_Wrapper.Authorize authorize = customer.authorize;
        feedback.Member_ID__c           =   customer.membershipId;
        feedback.Authorization_Code__c  =   authorize.code;
        feedback.Authorization_Level__c =   authorize.level;
        feedback.Rental_Days__c         =   authorize.rentalDays;
        feedback.Long_Tow_Miles__c      =   authorize.longTowMiles;
        feedback.Long_Tow_Kilometers__c =   authorize.longTowKilometers;
        feedback.Type__c                =   INCOMING_AUTH;
        feedback.Account__c             =   accountId;
        feedback.Status__c              =   STATUS_OPEN;
        feedback.Member_Club__c         =   customer.membershipId.mid(3,3);
        feedback.Source_Club__c         =   Label.FSL_SourceClubCode;
        feedback.Service_Date__c = Date.Today(); //check if INTMembershipLookupResponse_Wrapper has servicedate
    }
    
    //source org updating authorization in progress - incoming authorization
    /*public static void upsertFeedback(String workOrderId){
        try{
            List<Feedback__c> fb = [SELECT Id, Status__c, Work_Order__c, Ticket_Number__c, Trouble_Code__c 
                                FROM Feedback__c 
                                WHERE Account__c 
                                IN (SELECT Member_Account__c FROM WorkOrder WHERE ID = :workOrderId)
                                ORDER BY CreatedDate DESC 
                                LIMIT 1];
            if(fb.size() > 0){
                fb[0].Work_Order__c    =   workOrderId;
                fb[0].Status__c        =   STATUS_INPROCESS;
                fb[0].Trouble_Code__c  =   getWODetails(workOrderId).get('tCode');
                fb[0].Ticket_Number__c =  getWODetails(workOrderId).get('callId');
                upsert fb;
            }
        }Catch(Exception exp){
            throw exp;
        }    
    }*/
    public static void upsertFeedback(String workOrderId) {
    try {
        List<Feedback__c> fb = [SELECT Id, Status__c, Work_Order__c, Ticket_Number__c, Trouble_Code__c, 
                                       Source_Club__c, Member_Club__c 
                                FROM Feedback__c 
                                WHERE Account__c 
                                IN (SELECT Member_Account__c FROM WorkOrder WHERE ID = :workOrderId)
                                ORDER BY CreatedDate DESC 
                                LIMIT 1];
                                
        if (!fb.isEmpty()) {
            Map<String, String> woDetails = getWODetails(workOrderId);
            if (woDetails != null) {
                Feedback__c feedback = fb[0];

                // Check the Source_Club__c and Member_Club__c values
                if (feedback.Source_Club__c != '240' || feedback.Member_Club__c != '240') {
                    feedback.Status__c = STATUS_INPROCESS;
                }

                feedback.Work_Order__c = workOrderId;
                feedback.Trouble_Code__c = woDetails.get('tCode');
                feedback.Ticket_Number__c = woDetails.get('callId');
                upsert feedback;
            }
        }
    } catch (Exception exp) {
        System.debug('Error in upsertFeedback: ' + exp.getMessage());
        throw exp; // Optionally log or re-throw with additional context
    }
}


    //source org sending feedback to target org - incoming authorization
    @InvocableMethod(label='Send Feedback to National' description='Callout to National to send Feedback record' category= 'Feedback')
    public static void sendFeedbackToNational(List<Id> feedbackIds){
        try{
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Integration_Settings__c objSetting=new Integration_Settings__c();
            mapIntSettings = IntegrationUtil.getIntegrationSettings();
			system.debug('@@@@ 73 mapIntSettings @@@@'+mapIntSettings);
            system.debug('@@@@ 74 mapIntSettings @@@@'+mapIntSettings.get('POSTNational_Feedback_API'));
            String accessToken = getAccessTokenFromNational();
            if(accessToken != null){
                parseRequest(feedbackIds[0]);
                objSetting = mapIntSettings.get('POSTNational_Feedback_API');
                system.debug('@@@@ 78 objSetting @@@@'+objSetting);
                request = IntegrationUtil.prepareRequest(objSetting, wrapper, true);
                request.setHeader('Authorization','Bearer '+accessToken);
                system.debug('@@@@82 reuest@@@@'+request.getHeader('Authorization'));
                system.debug('@@@@ reuest@@@@'+request.getbody());
                response = IntegrationUtil.makeCallout(request);
                System.debug('STATUS CODE : '+response.getStatusCode());
                System.debug('RESPONSE : '+JSON.deserializeUntyped(response.getBody()));
                Map<string,object> responseMap = (Map<string,object>)JSON.deserializeUntyped(response.getBody());
                parseAndStoreResponse(feedbackIds[0], response);
            }
        }
        Catch(Exception exp){
            throw exp;
        }    
    }

    private static String getAccessTokenFromNational(){
        if(Test.isRunningTest()){
            return '1234';
        }
        HttpRequest  oauthobjRequest = new HttpRequest();
        HttpResponse oauthobjResponse = new HttpResponse();
        String body;

        Integration_Settings__c OAuthobjSetting=new Integration_Settings__c();
        OAuthobjSetting = mapIntSettings.get('POSTNational_OAuth_API');
        body = OAuthobjSetting.Extra_Header_Value__c;
        OAuthobjSetting.Extra_Header_Value__c =null;
        oauthobjRequest = IntegrationUtil.prepareRequest(OAuthobjSetting);
        oauthobjRequest.setbody(body);
        oauthobjResponse = IntegrationUtil.makeCallout(oauthobjRequest);
        if(oauthobjResponse.getStatusCode()==200){
            Map<string,object> mapofObjects = (Map<string,object>)JSON.deserializeUntyped(oauthobjResponse.getBody());
            return (String)mapofObjects.get('access_token');
        }else{
            return null;
        }
    }

    private static void parseRequest(String feedbackId){
        List<Feedback__c> feedback = [SELECT Authorization_Code__c, Authorization_Log__c, Long_Tow_Kilometers__c, Long_Tow_Miles__c,
                                        Member_Club__c, Member_ID__c, Rental_Days__c, Service_Date__c, Source_Club__c,
                                        Ticket_Number__c, Trouble_Code__c, Work_Order__c 
                                        FROM Feedback__c WHERE Id = :feedbackId LIMIT 1 ];
        if(feedback.size() > 0){
            if(!String.isEmpty(feedback[0].Authorization_Code__c)) {
                wrapper.authorization_code = feedback[0].Authorization_Code__c;
            }
            //wrapper.authorization_code      = String.isEmpty(feedback[0].Authorization_Code__c) ? '' : feedback[0].Authorization_Code__c;
            //wrapper.authorization_log       = String.isEmpty(feedback[0].Authorization_Log__c) ? '123' : feedback[0].Authorization_Log__c;
            //wrapper.long_tow_kilometers     = String.isEmpty(feedback[0].Long_Tow_Kilometers__c) ? 0 : Integer.valueOf(feedback[0].Long_Tow_Kilometers__c);
            wrapper.long_tow_miles          = String.isEmpty(feedback[0].Long_Tow_Miles__c) ? 0 : Integer.valueOf(feedback[0].Long_Tow_Miles__c);
            wrapper.member_club             = feedback[0].Member_Club__c;
            wrapper.member_id               = feedback[0].Member_ID__c;
            wrapper.rental_days             = String.isEmpty(feedback[0].Rental_Days__c) ? 0 : Integer.valueOf(feedback[0].Rental_Days__c);
            wrapper.service_date            = feedback[0].Service_Date__c != null ? feedback[0].Service_Date__c.day() : 0;
            wrapper.service_month           = feedback[0].Service_Date__c != null ? feedback[0].Service_Date__c.month() : 0;
            wrapper.service_year            = feedback[0].Service_Date__c != null ? feedback[0].Service_Date__c.year() : 0;
            wrapper.source_club             = feedback[0].Source_Club__c;
            wrapper.ticket_number           = feedback[0].Ticket_Number__c;
            wrapper.trouble_code            = feedback[0].Trouble_Code__c;
        }
    }

    private static Map<String,String> getWODetails(String woId){
        Map<String,String> woMap = new Map<String,String>();
        List<WorkOrder> wOrders = [SELECT Call_Id__c, (SELECT Code__c FROM TroubleCodes__r WHERE Type__c = 'PROBLEM' LIMIT 1) FROM WorkOrder WHERE Id =:woId];

        //List<FSL_TroubleCode__c> codes = [SELECT Code__c FROM FSL_TroubleCode__c WHERE Work_Order__c= :woId AND Type__c = 'PROBLEM' LIMIT 1];
        if(wOrders.size() > 0){
            woMap.put('callId',wOrders[0].Call_Id__c);
            List<FSL_TroubleCode__c> tCodes = wOrders[0].TroubleCodes__r;
            if(tCodes.size() > 0){
                woMap.put('tCode',tCodes[0].Code__c);
                list<Local_to_Reciprocal_T_Code_Mapping__mdt> tCodeList = [select id,T_Code__c, masterLabel 
                                                                                    from Local_to_Reciprocal_T_Code_Mapping__mdt 
                                                                                    where masterLabel =: tCodes[0].Code__c];
                if(tCodeList != null && !tCodeList.isEmpty()) {
                    woMap.put('tCode',tCodeList[0].T_Code__c);
                }
            }
        }
        return woMap;
    }

    private static void parseAndStoreResponse(String feedbackId, HttpResponse response){
        try{
            Map<string,object> responseMap = (Map<string,object>)JSON.deserializeUntyped(response.getBody());
            Feedback__c feedback = new Feedback__c();
            feedback.Id = feedbackId;
            String statusCode = String.valueOf(response.getStatusCode());
            //String returnCode = responseMap.get('return_cd') != null ? (String) responseMap.get('return_cd') : '1';
            if(statusCode == '200'){    //success

                feedback.Is_Sent_To_National__c = true;
                Map<string,object> successMap = new Map<string,object>();
                successMap = (Map<string,object>) responseMap.get('Response');
                if(successMap != null){
                    feedback.Error_Code__c = successMap.get('return_cd') != null ? String.valueOf((String) successMap.get('return_cd')) : '0';
                    feedback.Transaction_ID__c = successMap.get('receive_num') != null ? (String) successMap.get('receive_num') : '';
                    
                }
            }else{
                feedback.Is_Sent_To_National__c = false;
                Map<string,object> errorMap = new Map<string,object>();
                errorMap = (Map<string,object>) responseMap.get('error');
                if(errorMap != null){
                    feedback.Error_Code__c = errorMap.get('errorCode') != null ? String.valueOf((Integer) errorMap.get('errorCode')) : '';
                    feedback.Error_Message__c = errorMap.get('errorMessage') != null ? (String) errorMap.get('errorMessage') : '';
                    feedback.Transaction_ID__c = errorMap.get('transactionId') != null ? (String) errorMap.get('transactionId') : '';
                }
            }
            feedback.Time_Stamp__c = system.today().format();
            update feedback;
        }
        Catch(Exception exp){
            System.debug('Unable to store the response of POST Feedback API' +exp.getMessage());
        }
    }

    public class FeedbackWrapperRequest{
        public String authorization_code { get; set; }
        //public String authorization_log { get; set; }
        //public Integer long_tow_kilometers { get; set; }
        public Integer long_tow_miles { get; set; }
        public String member_club { get; set; }
        public String member_id { get; set; }
        public Integer rental_days { get; set; }
        public Integer service_date { get; set; }
        public Integer service_month { get; set; }
        public Integer service_year { get; set; }
        public String source_club { get; set; }
        public String ticket_number { get; set; }
        public String trouble_code { get; set; }
    }
}