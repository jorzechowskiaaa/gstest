/**** Apex Class Name    :    INTERSAuthorize
* Description        :    API class  to authorize ERS request when member
*                         needs service outside of member home club service territory.  
* Modification Log   :
* Test Class Name    :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Venkat Kommuri              Sep 24 2021             Created
* Vishnu Popuru               Oct 25 2024             Updated(modified the code to send "X" as a authorization code for cancelled memebrs)
*********************************************************************************/
@RestResource(urlMapping='/ERSauthorize/*')
global without sharing class INTERSAuthorize {
    
    /***
    * Method name        : getERSAuthorize
    * Description        : This method  returns generates and returns an ERS Authorization. 
    */ 
    @HttpGet
    global static void getERSAuthorize(){
        
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        
        String strjson;
        String membershipNumber;
        Integer serviceYear;
        Integer serviceMonth;
        Integer serviceDay;
        String sourceClub;
        String memberClub;
        
        try{
            membershipNumber = request.headers.get('mbr_id'); 
            serviceYear  = Integer.valueof(request.params.get('service_year'));
            serviceMonth = Integer.valueof(request.params.get('service_month'));
            serviceDay  = Integer.valueof(request.params.get('service_date'));
            sourceClub = request.params.get('source_clb');
            memberClub = request.params.get('clb_cd');
            system.debug('*********' + membershipNumber);
            system.debug('*********' + serviceYear + serviceMonth + serviceDay);
            system.debug('*********' + '*Source*' + sourceClub + ' ' + '*Target*' + memberClub + ' ' + '*Label*' + Label.FSL_SourceClubCode);
            
            Map<string,string> mapofMemebershiplevels = new Map<string,string>();
            
            for(Membership_Type_Mapping__mdt membeshiptype: [SELECT Id, MasterLabel, Membership_Level__c FROM Membership_Type_Mapping__mdt]){
                mapofMemebershiplevels.put((membeshiptype.MasterLabel).trim().toLowerCase(),membeshiptype.Membership_Level__c);
            }
            system.debug('**mapofMemebershiplevels**' + mapofMemebershiplevels);
            
            
            Map<string,string> mapmetadatacoverage = new Map<string,string>();
            
            for(Membership_Coverage_Metadata__mdt coveragetype: [SELECT Id, MasterLabel, Max_Tow_Miles__c, Membership_Level__c FROM Membership_Coverage_Metadata__mdt]){
                mapmetadatacoverage.put((coveragetype.Membership_Level__c).trim().toLowerCase(),String.valueOf(coveragetype.Max_Tow_Miles__c));
            }
            system.debug('**mapmetadatacoverage**' + mapmetadatacoverage);
            
            Map<string,string> feedbackmessages = new Map<string,string>();
            
            for(Feedback_Message__mdt  feedbackmessage: [SELECT Id, MasterLabel, message__c FROM Feedback_Message__mdt ]){
                feedbackmessages.put(feedbackmessage.MasterLabel,feedbackmessage.message__c);
            }
            system.debug('**feedbackmessages**' + feedbackmessages);
            
            Map<String,String> params = new Map<String,String>();
            params.put('memberId', membershipNumber);
                  
            //Refresh Entitlements - Always In Territory 
            ACG_GlobalSearchController.Results memberDetails;
            
            if(memberClub == Label.FSL_SourceClubCode){
                
                Date serviceDate = Date.newInstance(serviceYear,serviceMonth,serviceDay);
                ServiceContract  objSc;
                if (!Test.isRunningTest())  {
                    memberDetails = ACG_GlobalSearchController.invokeMembershipAPIs('lookup', params, 'ERSINB');
                }
                if(!Test.isRunningTest() && memberDetails.custMessage == 'ERSINB') {
                    response.statusCode =404;
                    String message = 'Member ID not found';
                    strjson = generateErrorResponse('-9',message,membershipNumber );
                }
                else {
                    if(memberDetails != null && memberDetails.contract != null) {
                    objSc = getServiceContractDetails(membershipNumber, date.parse(memberDetails.contract.contractEndDate), date.parse(memberDetails.contract.contractStartDate));
                }
                else {
                    objSc = getServiceContractDetails(membershipNumber, Date.today().addDays(10), Date.today().addDays(-100));
                }
                //Contract data for InTerritory, entitlement data for outside territory
                system.debug('****objSc*****' + objSc);
                
                Boolean hasServiceContract = FALSE;
                if(objSc != null){
                    hasServiceContract = TRUE;
                }else{
                    hasServiceContract = FALSE;
                }
                
                
                Feedback__c objAuth = new Feedback__c();
                
                String message;
                String memberlevel;
                String towMiles;
                
                if(hasServiceContract){
                    if(objSc.AAA_ACA_Membership_Coverage_Level__c != null){
                        memberlevel = mapofMemebershiplevels.get((objSc.AAA_ACA_Membership_Coverage_Level__c).trim().toLowerCase());
                    }
                    
                    if(objSc.AAA_ACA_Membership_Coverage_Level__c != null){
                        towMiles = mapmetadatacoverage.get((objSc.AAA_ACA_Membership_Coverage_Level__c).trim().toLowerCase());
                    }
                    
                    system.debug('****memberlevel*****' + memberlevel ) ;
                    system.debug('****objSc.AAA_ACA_Membership_Status__c*****' + objSc.AAA_ACA_Membership_Status__c);
                    system.debug('****objSc.EndDate*****' + objSc.EndDate);
                    system.debug('****objSc.AAA_Total_of_Calls_Allowed__c*****' + objSc.AAA_Total_of_Calls_Allowed__c);
                    system.debug('****objSc.AAA_Total_of_Calls_Consumed__c*****' + objSc.AAA_Total_of_Calls_Consumed__c);
                    
                    
                    if(objSc.AAA_ACA_Membership_Status__c == AAA_CallIntakeUtils.MEMBER_STATUS_ACTIVE && objSc.EndDate >= serviceDate){
                        if(objSc.AAA_Total_of_Calls_Allowed__c > objSc.AAA_Total_of_Calls_Consumed__c + objSc.AAA_Total_of_Reciprocals__c){
                            
                            if(!Test.isRunningTest() && memberDetails.contract.sameDayService ==  false){
                                //same day service
                                memberlevel = 'C';
                                message = feedbackmessages.get('SAMEDAYSERVICE');
                            }else{
                                //happy path
                                //level = objSc.AAA_ACA_Membership_Coverage_Level__c ;
                                message = 'Good for Service';
                            }
                        }else{
                            //All Calls Consumed
                            memberlevel = 'C' ;
                            message = feedbackmessages.get('ALLCALLCONSUMED');
                        }
                    }
                    else if (objSc.AAA_ACA_Membership_Status__c == AAA_CallIntakeUtils.MEMBER_STATUS_PENDING) {
                        if (objSc.EndDate >= serviceDate) {
                            if (objSc.AAA_Total_of_Calls_Allowed__c == 0 || objSc.AAA_Total_of_Calls_Allowed__c == null) {
                                memberlevel = 'C';
                                message = feedbackmessages.get('CALLSALLOWED0');
                            } else if (objSc.AAA_Total_of_Calls_Allowed__c <= objSc.AAA_Total_of_Calls_Consumed__c + objSc.AAA_Total_of_Reciprocals__c) {
                                // All Calls Consumed for Pending Status
                                memberlevel = 'C';
                                message = feedbackmessages.get('ALLCALLCONSUMED');
                            } else if (objSc.AAA_Total_of_Calls_Allowed__c > objSc.AAA_Total_of_Calls_Consumed__c + objSc.AAA_Total_of_Reciprocals__c) {
                                // Happy path: calls remaining
                                message = 'Good for Service';
                            }
                        } else if (objSc.EndDate < serviceDate) {
                            memberlevel = 'C';
                            message = feedbackmessages.get('ENDDATEPASSED');
                        }
                    }
                    // Ensure Cancelled members always get 'C'
                    else if (objSc.AAA_ACA_Membership_Status__c == AAA_CallIntakeUtils.MEMBER_STATUS_CANCELLED) {
                        memberLevel = 'C';
                        message = feedbackMessages.get('CANCELLED') ?? feedbackMessages.get('CANCELED');
                        towMiles = '0';  // No coverage for cancelled members
                    }
                }else {
                    memberLevel = 'X';  // No valid service contract
                    message = feedbackMessages.get('CANCELLED') ?? feedbackMessages.get('CANCELED');
                    towMiles = '0';
                    Account objAcc = getMemberDetails(membershipNumber);
                    system.debug('objAccSc' + objAcc);
                }  
                system.debug('****memberlevel*****' + memberlevel ) ;
                system.debug('****message*****' + message ) ;
                    
                    if (memberlevel == 'X') {
                        // Set status to 'Closed' when memberlevel is 'X'
                        objAuth = createFeedbackRecord(objSc, membershipNumber, sourceClub, serviceDate, 'Outgoing Authorization', 'Closed', memberlevel, towMiles);
                    } else if (sourceClub == '240' && memberClub == '240') {
                        // Set status to 'Closed' if sourceClub and memberClub are both '240'
                        objAuth = createFeedbackRecord(objSc, membershipNumber, sourceClub, serviceDate, 'Outgoing Authorization', 'Closed', memberlevel, towMiles);
                    } else {
                        // Default case: Set status to 'Open'
                        objAuth = createFeedbackRecord(objSc, membershipNumber, sourceClub, serviceDate, 'Outgoing Authorization', 'Open', memberlevel, towMiles);
                    }

                    system.debug('****objAuth*****' + objAuth);
                    
                if(objAuth.Authorization_Code__c!=null){
                    
                    response.statusCode =ACG_ConstantsClass.STATUS_CODE_SUCCESS;
                    
                    INTERSAuthorize_ResponseSuccess respBody = new INTERSAuthorize_ResponseSuccess();
                    strjson=generateSuccessResponse(objAuth.Authorization_Code__c, objAuth.Authorization_Level__c,objAuth.Long_Tow_Miles__c, objAuth.Member_ID__c, message, 0 );
                    system.debug('***respBody***' + strjson );
                } else{
                    system.debug('****Exception - No Authorization Code Generated*****' );
                    message = 'Internal Server Error - No Authorization Code Generated';
                    strjson = generateErrorResponse('500',message,membershipNumber );
                    system.debug('***strjson***' + strjson );
                    }
                }
                
                response.responseBody = Blob.valueOf(strjson);
                FSL_ApplicationLogCreator.integrationLog (JSON.serialize(request.params),strjson,'ERSAuthorize API','ERSAuthorize',false,'',null);
            }else{
                system.debug('****Incorrect Club Code - Exception Thrown400*****');
                response.statusCode =400;
                String message = 'Internal Server Error - Incorrect Club Code';
                strjson = generateErrorResponse('400',message,membershipNumber );
                system.debug('***strjson***' + strjson );
                response.responseBody = Blob.valueOf(strjson);
                FSL_ApplicationLogCreator.integrationLog (JSON.serialize(request.params),strjson,'ERSAuthorize API','ERSAuthorize',false,'',null);
            }
        } 
        catch (AuraHandledException e) {
            //since the child throws AuraHandledException, catch it here, maybe check what the exception is, then do
            system.debug('@@@@@ line 197 Catching Aura Exception @@@@@');
        }
        Catch(Exception e){
            system.debug('****General Exception*****' + e.getLineNumber() + ' ' + e.getMessage());
            response.statusCode =400;
            String message = 'Internal Server Error' + e.getStackTraceString() +'Line Number: '+e.getLineNumber()+''+e.getMessage();
            strjson = generateErrorResponse('400',message,membershipNumber );
            system.debug('***strjson***' + strjson );
            response.responseBody = Blob.valueOf(strjson);
            FSL_ApplicationLogCreator.integrationLog (JSON.serialize(request.params),strjson,'ERSAuthorize API','ERSAuthorize',false,'',null);
        }
    }
    
    public static ServiceContract getServiceContractDetails(String membershipNumber, Date eDate, Date sDate){
        List<ServiceContract> lstServiceContract= new List<ServiceContract>();
        if(!String.isEmpty(membershipNumber)){
            /*lstServiceContract = [SELECT Id, AAA_Total_of_Calls_Allowed__c,AAA_Total_of_Calls_Consumed__c,AAA_Same_Day_Service__c,EndDate,  AAA_ACA_Membership16ID__c,AccountId, AAA_ACA_Membership_Coverage_Level__c,AAA_ACA_Member_Status__c,AAA_ACA_Membership_Status__c
                                  FROM ServiceContract WHERE AAA_ACA_Membership16ID__c =: membershipNumber LIMIT 1];*/
            lstServiceContract = [Select Id, AAA_ACA_Membership_Type__c,AAA_ACA_Membership16ID__c, AccountId, 
            StartDate, EndDate, AAA_ACA_Member_Status__c, AAA_ACA_MembershipID__c,parentServiceContractId,
            AAA_ACA_Membership_Status__c, AAA_ACA_Membership_Coverage_Level__c,
            AAA_Total_of_Calls_Allowed__c,AAA_Total_of_Calls_Remaining__c,AAA_Total_of_Calls_Consumed__c,AAA_Total_of_Reciprocals__c   
            from ServiceContract where 
                AAA_ACA_Membership16ID__c =: membershipNumber
                AND (EndDate =: eDate OR StartDate =: sDate)
            ];                              
        }
        if(!lstServiceContract.isempty()){
            return lstServiceContract[0];
        } else {
            return null;
        }
    }//End of getServiceContractDetails
    
    public static String generateErrorResponse(String code, String message, String membershipnumber ){
        String jsonresponse = '';
        INTERSAuthorize_ResponseError errorresp = new INTERSAuthorize_ResponseError();
        errorresp.errorCode = code;
        errorresp.errorMessage = message;
        errorresp.transactionId = membershipNumber;
        errorresp.timeStamp = String.valueOf(Datetime.now());
        jsonresponse = JSON.serialize(errorresp);
        return jsonresponse;
    }
    
    public static String generateSuccessResponse(String authCode, String level, String towMiles, String membrId, String message, Integer returnCode ){
        String jsonresponse = '';
        INTERSAuthorize_ResponseSuccess successResp = new INTERSAuthorize_ResponseSuccess();
        successResp.code = authCode;
        successResp.level = level;
        successResp.long_tow_kilometers = '0';
        successResp.long_tow_miles = towMiles;
        successResp.member_id = membrId;
        successResp.message = message;
        successResp.rental_days = '0';
        successResp.return_cd = returnCode;
        jsonresponse = JSON.serialize(successResp);
        return jsonresponse;
    }
    
    public static Account getMemberDetails(String membershipNumber){
        List<Account> lstAccounts= new List<Account>();
        if(membershipNumber!=null && membershipNumber!=''){
            lstAccounts = [SELECT Id,ACG_AAA_Membership__c,Member_ID__c,Member_Card_Num__pc,AAA_Membership_Level__c,Long_Tow_Miles_Used__c,
                           Long_Tow_Kilometers_Used__c,ACG_Membership_Status__c,Authorize_Code__c,ACG_Entitlements_Used__c,
                           ACG_Entitlements_Allotted__c FROM Account WHERE Member_ID__c =: membershipNumber OR Member_Card_Num__pc =: membershipNumber LIMIT 1];
        }
        return lstAccounts[0];
    }//End of getMemberDetails
    
   public static Feedback__c createFeedbackRecord(ServiceContract sc,String membershipNumber, String sourceClub,Date serviceDate, String type, String Status, String level, String maxTowMiles){
        
        Feedback__c objrec = new Feedback__c();
        if(sc != null){
            objrec.Account__c = sc.AccountId;
            objrec.Member_ID__c = sc.AAA_ACA_Membership16ID__c ;
            objrec.Member_Club__c = sc.AAA_ACA_Membership16ID__c.substring(3,6);
            objrec.Service_Contract__c = sc.Id;
        }else{
            Account objAcc = getMemberDetails(membershipNumber);
            
            if(objAcc != null){
                objrec.Account__c  = objAcc.id;
                objrec.Member_ID__c = objAcc.Member_Card_Num__pc ;
                objrec.Member_Club__c = objAcc.Member_Card_Num__pc.substring(3,6);
            }else{
                system.debug('No Acc No Sc' + membershipNumber);
            }
            
            
        }
        
        objrec.Source_Club__c = sourceClub; 
        objrec.Service_Date__c = serviceDate;
        objrec.Type__c = type;
        objrec.Status__c  = status;
        objrec.Authorization_Level__c   = level;
        objrec.Rental_Days__c = '0';
        objrec.Long_Tow_Kilometers__c = '0';
        objrec.Long_Tow_Miles__c = maxTowMiles; //ToTest
        if(objrec!=null){
            insert objrec;
        }
        
        if(objrec.Id!=null){
            objrec = [SELECT Id,Account__c,Member_ID__c,Rental_Days__c,Long_Tow_Kilometers__c,Long_Tow_Miles__c,Member_Club__c,Source_Club__c,Service_Date__c,Service_Contract__c,Type__c,Status__c,Authorization_Level__c
                      ,Auth_Autonumber__c FROM Feedback__c WHERE Id=: objrec.Id];
            objrec.Authorization_Code__c = objrec.Auth_Autonumber__c;
            update objrec;
        }
        return objrec;
    }
    
    global class INTERSAuthorize_ResponseSuccess{
        public String code{get;set;} //88573873
        public String level{get;set;} //E
        public String long_tow_kilometers{get;set;}//100
        public String long_tow_miles{get;set;}//100
        public String member_id{get;set;}//69773315
        public String message {get;set;}//string
        public String rental_days{get;set;}//30
        public Integer return_cd{get;set;}//0
    }//END of INTERSAuthorize_Response
    
    global class INTERSAuthorize_ResponseError{
        public String errorCode{get;set;} //4xx
        public String errorMessage{get;set;} //Error message
        public String transactionId{get;set;}//9bdc1bd3-271d-4f91-8dc1-f1d796765a85
        public String timeStamp{get;set;}//2022-02-18T15:44:06.858Z
    }//END of INTERSAuthorize_Response
    
    
    
}