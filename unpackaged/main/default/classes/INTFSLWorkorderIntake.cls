/**** Apex Class Name    :    INTFSLWorkorderIntake
    * Description        :    API class  to Create WorkOrder,MemberVehciles for DRR and IVR Smart Action 
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Daraksha Shaikh             4 Feb 2022              Modified UpdateServiceAppointment method
    * Venkat Kommuri              Aug 31 2021             Created
*********************************************************************************/
@RestResource(urlMapping='/createWorkOrder/*')
global with sharing class INTFSLWorkorderIntake{
    public static String SUCCESS_MESSAGE;
    public static String ERROR_MESSAGE = '';
    public static String UPDATE_GENESYS_ID = 'UpdateGenesysId';
    private static Boolean boolMemberFound = false;
    //public static FSL_SchedulingUtility.slaWrapper slaWrapUsed;
    public static Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([Select Id,name,EstimatedDuration,FSL__Due_Date_Offset__c from WorkType]);
    public static String retrySchedPolicy;
    public static ACG_GlobalSearchController.Results gsResults;
    @testVisible
    public static FSL_Account.IFactory accountFactory = new FSL_Account.Factory();

    /***
    * Method name        : createWorkOrder
    * Description        : This method parses the json request comming from Mulesoft 
    *                      and creates corresponding workorder, Account,Member Vehicle records.
    * Return Type        : INTFSL_WorkOrderResponse_Wrapper 
    */
    @HttpPost
    global static List<INTFSL_WorkOrderResponse_Wrapper> createWorkOrder() {
        // NOTE: do not use Database.setSavepoint() in this method, as it will cause callouts to fail
        // Savepoint sp;
        // if(!Test.isRunningTest()) {
        //     sp = Database.setSavepoint();
        // }
        System.debug('------------- TIMESTAMP -----W : ' + Datetime.now());
        List<INTFSL_WorkOrderResponse_Wrapper> resList = new List<INTFSL_WorkOrderResponse_Wrapper>();
        List<INTFSLWorkOrderRequest_Wrapper> jsonParserList = new List<INTFSLWorkOrderRequest_Wrapper>();    

        INTFSL_WorkOrderResponse_Wrapper res = new INTFSL_WorkOrderResponse_Wrapper();
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
       	system.debug('Request Body: '+request.requestBody.toString());
        try {
 
            try {
                jsonParserList  =  INTFSLWorkOrderRequest_Wrapper.parse(request.requestBody.toString());            
            } catch(Exception ex) {
                res.statusCode = string.valueOf(ACG_ConstantsClass.ERROR_CODE400);
                response.statusCode = ACG_ConstantsClass.ERROR_CODE400;
                res.statusDescription = Label.INT_ERS_INVALID_REQUEST;
                //ERROR_MESSAGE = ex.getStackTraceString(); //ex.getMessage()+' At Line:'+ex.getLineNumber();
                ERROR_MESSAGE = 'Exception info' + '\r\n';
                ERROR_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                ERROR_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                ERROR_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';
                system.debug('ERROR_MESSAGE1:'+ERROR_MESSAGE);
                FSL_ApplicationLogCreator.integrationLog (request.requestBody.toString(),JSON.serialize(res),'IntakeWorkOrderAPI','IntakeWorkOrderAPI',true,ERROR_MESSAGE,null);
            }

            for(INTFSLWorkOrderRequest_Wrapper jsonParser : jsonParserList) {
                resList.add(processSingleRequest(jsonParser, request, response));
            }

        } catch(Exception e) {
            // if(!Test.isRunningTest()) {
            //     Database.rollback(sp);
            // }
            res.statusCode = ACG_ConstantsClass.STATUS_CODE;
            response.statusCode = ACG_ConstantsClass.ERROR_CODE400;
            
            res.statusDescription = e.getMessage();   //ACG_ConstantsClass.SERVER_ERROR;
            //ERROR_MESSAGE = e.getStackTraceString();   // +' At Line:'+e.getLineNumber()+e.getMessage();
            ERROR_MESSAGE = 'Exception info' + '\r\n';
            ERROR_MESSAGE += 'Message: ' + e.getMessage() + '\r\n';
            ERROR_MESSAGE += 'Cause: ' + e.getCause() + '\r\n';
            ERROR_MESSAGE += 'Stack Trace: ' + e.getStackTraceString() + '\r\n';
            system.debug('ERROR_MESSAGE2:'+ERROR_MESSAGE);            
            //Create Application log here
            FSL_ApplicationLogCreator.integrationLog (request.requestBody.toString(),JSON.serialize(res),'IntakeWorkOrderAPI','IntakeWorkOrderAPI',true,ERROR_MESSAGE ,null);
        }
        return resList;
    }

    private static INTFSLWorkOrderRequest_Wrapper preprocessCallouts(INTFSLWorkOrderRequest_Wrapper jsonParser) {
        ARR_Call_Receive_LWC_UI_Configuration__c cs = ARR_Call_Receive_LWC_UI_Configuration__c.getInstance();
        String addressSearchAPI = cs.API_Callout_Map_Search__c;
        Boolean isGoogle = addressSearchAPI == 'google' ? true : false;
        //Boolean isBing = addressSearchAPI == 'bing' ? true : false; /*SSFI-1111 MPatel commented Bing Methods 5/8/25 */
        if(Test.isRunningTest()){isGoogle = true;}
        //At Home Verint does not send in lat/long
        String addr = jsonParser.BreakdownLocation?.streetNumber!=null?jsonParser.BreakdownLocation?.streetNumber+' ':''; 
        addr += jsonParser.BreakdownLocation?.streetName!=null?jsonParser.BreakdownLocation?.streetName+' ':'';  
        addr +=  jsonParser.BreakdownLocation?.crossStreet!=null?jsonParser.BreakdownLocation?.crossStreet+' ':''; 
        addr += jsonParser.BreakdownLocation?.city!=null?jsonParser.BreakdownLocation?.city+' ':'';
        addr += jsonParser.BreakdownLocation?.postalCode!=null?jsonParser.BreakdownLocation?.postalCode+' ':''; 
        addr += jsonParser.BreakdownLocation?.state!=null?jsonParser.BreakdownLocation?.state:'';       
        
        if((jsonParser.BreakdownLocation?.latitude == null || jsonParser.BreakdownLocation?.longitude == null) &&
            !String.isBlank(addr)) {
            try {
                List<Double> coordinates;
                if(isGoogle){
                    coordinates = INTSADAGeoMapAPI.getLatLongFromGoogle(addr);
                }
                /*SSFI-1111 MPatel commented Bing Methods 5/8/25
                else if(isBing){
                    coordinates = INTSADAGeoMapAPI.getLatLongfromBingAddress(addr);
                }*/
                if(coordinates.size() == 2) {
                    jsonParser.BreakdownLocation.latitude = coordinates[0];
                    jsonParser.BreakdownLocation.longitude = coordinates[1];
                }
            } catch(Exception ex) {
                String ERROR_MESSAGE = 'Exception info' + '\r\n';
                ERROR_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                ERROR_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                ERROR_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';                            
                FSL_ApplicationLogCreator.integrationLog (addr, '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', 
                        true, 'Unable to get Lat/Long from Breakdown Address: ' + '\r\n' + ERROR_MESSAGE, null);
            }
        }

        if((jsonParser.channel == 'VERINT' && jsonParser.callType == 'Partial')) {

        } else {

            //If incoming payload is missing timezone info
            if((String.isBlank(jsonParser?.timezoneId) || String.isBlank(jsonParser?.timeZoneOffset)) && !String.isBlank(addr)) {
                try {
                    String s;
                    if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_BypassTimezoneInt)) //AGB 10/10/24 
                    {
                        system.debug('Timezone Integration Bypassed');
                        jsonParser.timezoneId = 'America/New_York';
                        //jsonParser.timezoneOffset = 'UTC-04:00';
                        TimeZone tz = TimeZone.getTimeZone('America/New_York');
                        String offset = tz.getDisplayName();
                        if(String.isNotBlank(offset)){    
                            offset = offset.mid(1,9); //When syncing to D3, it only accepts 9 chars
                        }
                        jsonParser.timezoneOffset = offset;
                    }else if(isGoogle){
                        if(jsonParser.BreakdownLocation?.latitude != null && jsonParser.BreakdownLocation?.longitude != null) {
                            List<String> timezoneResult;
                            String latLong = jsonParser.BreakdownLocation?.latitude+','+jsonParser.BreakdownLocation?.longitude;
                            timezoneResult = INTSADAGeoMapAPI.getTimeZoneFromGoogle ( latLong );
                            if(timezoneResult.size() == 2){
                                jsonParser.timezoneId = timezoneResult[0];
                                TimeZone tz = TimeZone.getTimeZone(jsonParser.timezoneId);
                                String offset = tz.getDisplayName();
                                if(String.isNotBlank(offset)){    
                                    offset = offset.mid(1,9); //When syncing to D3, it only accepts 9 chars
                                 }
                                jsonParser.timezoneOffset = offset;
                            }    
                        }
                    }
                    /*SSFI-1111 MPatel commented Bing Methods 5/8/25
                    else if(isBing){
                        if(jsonParser.BreakdownLocation?.latitude != null && jsonParser.BreakdownLocation?.longitude != null) {
                            List<Double> latLong = new List<Double>();
                            latLong.add(jsonParser.BreakdownLocation?.latitude);
                            latLong.add(jsonParser.BreakdownLocation?.longitude);
                            s = INTSADAGeoMapAPI.getTimezoneFromBing ( latLong );
                        } else {
                            s = INTSADAGeoMapAPI.getTimezone (addr);
                        }
                        INTSADAGeoMapAPI.BingResponse rs = (INTSADAGeoMapAPI.BingResponse) JSON.deserialize ( s, INTSADAGeoMapAPI.BingResponse.class );
                        if(String.isBlank(jsonParser?.timezoneId)) {
                            if(rs != null && rs.resourceSets.size() > 0) {
                                jsonParser.timezoneId = rs.resourceSets.get(0).resources.get(0).timeZone.abbreviation;
                            }
                        }
                        if(String.isBlank(jsonParser?.timeZoneOffset)) {
                            if(rs != null && rs.resourceSets.size() > 0) {
                                jsonParser.timezoneOffset = rs.resourceSets.get(0).resources.get(0).timeZone.abbreviation
                                                        +  rs.resourceSets.get(0).resources.get(0).timeZone.utcOffset;
                            }                        
                        }
                    } */
                    
                } catch(Exception ex) {
                    String ERROR_MESSAGE = 'Exception info' + '\r\n';
                    ERROR_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                    ERROR_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                    ERROR_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';                            
                    FSL_ApplicationLogCreator.integrationLog (addr, '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', 
                            true, 'Unable to get Timezone from Breakdown Address: ' + '\r\n' + ERROR_MESSAGE, null);
                }
            }

            //If Tow appointment is missing lat/long, will trigger calculate mileage callout and fails WO creation.
            if(jsonParser.TowDestination?.latitude == null || jsonParser.TowDestination?.longitude == null) {

                addr = jsonParser.TowDestination?.streetNumber!=null?jsonParser.TowDestination?.streetNumber+' ':''; 
                addr += jsonParser.TowDestination?.streetName!=null?jsonParser.TowDestination?.streetName+' ':'';
                addr += jsonParser.TowDestination?.crossStreet!=null?jsonParser.TowDestination?.crossStreet+' ':''; 
                addr += jsonParser.TowDestination?.city!=null?jsonParser.TowDestination?.city+' ':'';
                addr += jsonParser.TowDestination?.postalCode!=null?jsonParser.TowDestination?.postalCode +' ':'';
                addr += jsonParser.TowDestination?.state!=null?jsonParser.TowDestination?.state:'';

                if(!String.isBlank(addr)) {
                    try {
                        List<Double> coordinates;
                        if(isGoogle){
                            coordinates = INTSADAGeoMapAPI.getLatLongFromGoogle(addr);
                        }
                        /*SSFI-1111 MPatel commented Bing Methods 5/8/25
                        else if(isBing){
                            coordinates = INTSADAGeoMapAPI.getLatLongfromBingAddress(addr);
                        }*/
                        if(coordinates.size() == 2) {
                            jsonParser.TowDestination.latitude = coordinates[0];
                            jsonParser.TowDestination.longitude = coordinates[1];
                        }
                    } catch(Exception ex) {
                        String ERROR_MESSAGE = 'Exception info' + '\r\n';
                        ERROR_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                        ERROR_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                        ERROR_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';                            
                        FSL_ApplicationLogCreator.integrationLog (addr, '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', 
                                true, 'Unable to get Lat/Long from Tow Address: ' + '\r\n' + ERROR_MESSAGE, null);
                    }
                }
            }
            
            try {
                //Calculate total mileage for later
                jsonParser.totalMileage = 0.0;
                if(jsonParser.BreakdownLocation?.latitude != null && jsonParser.BreakdownLocation?.longitude != null && 
                   jsonParser.TowDestination?.latitude != null && jsonParser.TowDestination?.longitude != null) {

                    /*SSFI-1111 MPatel commented Bing and replaced it with ACG_CaseTriggerService.calculateDistance
                    FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
                    FSL_Mapping.IMap mappingService = new FSL_Mapping.BingMap( appLogService );                            
                    jsonParser.totalMileage = mappingService.calculateDistanceInMiles( jsonParser.BreakdownLocation?.latitude, jsonParser.BreakdownLocation?.longitude,
                                                                                       jsonParser.TowDestination?.latitude, jsonParser.TowDestination?.longitude );*/
                    
                }
            } catch(Exception ex) {
                String ERROR_MESSAGE = 'Exception info' + '\r\n';
                ERROR_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                ERROR_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                ERROR_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';                            
                FSL_ApplicationLogCreator.integrationLog (addr, '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', 
                        true, 'Unable to get Total Mileage: ' + '\r\n' + ERROR_MESSAGE, null);
            }


            // Lookup API -> Create Person Account -> Create Service Contract
            //EMI - ssfi-212 - updated line no:234--added this extra condition jsonParser.callType != 'RAP'
            //system.debug('jsonParser.ContactInformation?.orgCode:'+jsonParser.ContactInformation?.orgCode);
            //system.debug('AGB BypassCDXforClubCodeBypassCDXforClubCode:'+Label.BypassCDXforClubCode+' '+jsonParser.ContactInformation?.orgCode+' '+Label.BypassCDXforClubCode.contains(jsonParser.ContactInformation?.orgCode));          
            boolean CDXBypass = jsonParser.ContactInformation?.orgCode == null ? false : jsonParser.ContactInformation?.orgCode == '' ? false : Label.BypassCDXforClubCode.contains(jsonParser.ContactInformation?.orgCode);
            system.debug('CDXBypass1: '+CDXBypass);
            if((jsonParser.channel != 'RAP' && jsonParser.callType != 'RAP' && !String.isBlank( jsonParser.memberNumber )) 
               && !CDXBypass) { // jsonParser.memberNumber?.length() == 16 //AGB 10/1/24 SSFI-493 TO BYPASS CDX for 724 and 723 club code
                //objAccount = createAccount( jsonParser );
               String memberShipId = jsonParser.memberNumber;
                if(jsonParser.sourceOrgCode  == Label.FSL_SourceClubCode && memberShipId.length() == 9){
                    memberShipId = Label.FSL_ISO_Code + Label.FSL_SourceClubCode + memberShipId;
                }
                    Map<String,String> mapRequestParams = new Map<String,String>{
                    'memberId' => memberShipId
                };
                gsResults = ACG_GlobalSearchController.invokeMembershipAPIs('lookup', mapRequestParams, 'GUID_API');    
                system.debug('Global Search');
            }

        }

        return jsonParser;
    }

    private static INTFSL_WorkOrderResponse_Wrapper processSingleRequest(INTFSLWorkOrderRequest_Wrapper jsonParser, 
                                                                         RestRequest request,
                                                                         RestResponse response) {
        INTFSL_WorkOrderResponse_Wrapper res = new INTFSL_WorkOrderResponse_Wrapper();
        Case objCase = new Case();
        WorkOrder objwo = new WorkOrder();
        List<WorkOrder> lstworkorder = new List<WorkOrder>();
        FSL_Member_Vehicle__c objmemVehicle = new FSL_Member_Vehicle__c();
        List<FSL_Member_Vehicle__c> lstofMemVehicles = new List<FSL_Member_Vehicle__c>();
        List<FSL_Call_Comments__c> lstCallComments = new List<FSL_Call_Comments__c>();
        List <ServiceAppointment> relatedAppointments = new List <ServiceAppointment>();
        List<SObject> lstDeleteSobjects = new List<SObject>();
        ServiceAppointment breakdownSA = new ServiceAppointment();
        ServiceAppointment towSA = new ServiceAppointment();
        Id breakdownAppointmentId;
        Id towServiceAppointmentId;
        string strServiceType;
        String resultFromSearchCaseForIVR = null;
        String genesysIds = null;
        String serviceContractId;
        String accountId;
        Account objAccount = null;
        if(jsonParser.OperationType == ACG_ConstantsClass.CASE_CREATION && 
            (jsonParser.memberNumber != null || jsonParser.contactinformation?.telephoneNumber != null) ) {

            if(jsonParser.channel == 'IVR') {
                if(!Test.isRunningTest()) {
                    ACG_ScreenPopService service = new ACG_ScreenPopService();
                    if(Label.FSL_SourceClubCode == '212'){ //Only for ACA
                        List<String> caseAndGenesysIds = service.searchCaseAndGetGenesysId(jsonParser.memberNumber, jsonParser.contactinformation.telephoneNumber);
                        if(caseAndGenesysIds != null && caseAndGenesysIds.size() == 2){
                            resultFromSearchCaseForIVR = caseAndGenesysIds[0];
                            genesysIds = String.isNotBlank(caseAndGenesysIds[1]) ? caseAndGenesysIds[1] : '' ;
                        }
                    }else{
                        resultFromSearchCaseForIVR = service.searchCase(jsonParser.memberNumber, jsonParser.contactinformation.telephoneNumber);
                    }
                }
            }
            if(resultFromSearchCaseForIVR != null) {
                //objCase.Id = result;
            } else { 
                jsonParser = preprocessCallouts(jsonParser);
                try {
                    //For RAP call, if caller is not a AAA member, we create the Account with only firstname/lastname and 
                    //no membership number.
                    boolean CDXBypass = jsonParser.ContactInformation?.orgCode == null ? false : jsonParser.ContactInformation?.orgCode == '' ? false : Label.BypassCDXforClubCode.contains(jsonParser.ContactInformation?.orgCode);
                    system.debug('CDXBypass2: '+CDXBypass);
                    if(jsonParser.channel == 'RAP' || jsonParser.callType == 'RAP' || CDXBypass) {  //AGB 10/1/24 SSFI-493 TO BYPASS CDX for 724 and 723 club code
                        if(jsonParser.memberNumber?.trim().length() == 0) jsonParser.memberNumber = '';
                        if(String.IsBlank(jsonParser.ContactInformation?.currentBenefitLevel)) {
                            jsonParser.ContactInformation.currentBenefitLevel = 'Plus';
                        }
                        objAccount = createAccount( jsonParser );
                        accountId = objAccount.Id; // Added for PR893288-5086
                    }else{ //DRR
                        if(gsResults != null && gsResults.isLookupSuccess == true && gsResults.updatedRecordId != null){
                            accountId = gsResults.updatedRecordId;
                            objAccount = [SELECT Id,PersonContactId,PersonMobilePhone,FirstName,LastName,phone,ACG_SMS_Opt_In__c FROM Account WHERE ID =:accountId LIMIT 1];
                            if(gsResults.contract != null){
                                serviceContractId = gsResults.contract.contractId;
                            } 
                            if(gsResults.impairmentType != null){
                                jsonParser.impairmentId = gsResults.impairmentType;
                            }else{
                                jsonParser.impairmentId = '';
                            }
                        }
                        else{
                            FSL_ApplicationLogCreator.integrationLog ('', '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', true, 
                                'Unable to verify the member from MZP/CDX ' + jsonParser.memberNumber, null);
                            INTFSL_WorkOrderResponse_Wrapper.HEADER hed = new INTFSL_WorkOrderResponse_Wrapper.HEADER();
                            hed.id = (String.IsNotBlank(jsonParser.id) ? jsonParser.id : IntegrationUtil.generateuniqueId());
                            hed.type = jsonParser.OperationType;
                            res.header = hed;
                            res.CallDate = System.now().format('yyyy-MM-dd');
                            res.statusDescription = 'Unable to verify the member from MZP/CDX';
                            res.statusCode = String.valueOf(ACG_ConstantsClass.ERROR_CODE400);
                            return res;
                        }
                    }
                    
                    /*if(jsonParser.memberNumber?.length() == 16 ) { //|| String.isBlank( jsonParser.memberNumber )
                        if(gsResults != null){
                            if(gsResults.isLookupSuccess == true && gsResults.updatedRecordId != null){
                                accountId = gsResults.updatedRecordId;
                                objAccount = [SELECT Id,PersonContactId,FirstName,LastName,phone,ACG_SMS_Opt_In__c FROM Account WHERE ID =:accountId LIMIT 1];
                                if(gsResults.contract != null){
                                    serviceContractId = gsResults.contract.contractId;
                                } 
                            }
                        }else{
                            objAccount = createAccount( jsonParser );
                        }
                        
                    } else {
                        FSL_ApplicationLogCreator.integrationLog ('', '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', true, 
                                'Incoming Member Id length is not 16: ' + jsonParser.memberNumber, null);
                    }*/
                } catch(Exception ex) {
                    String INFO_MESSAGE = 'Exception info' + '\r\n';
                    INFO_MESSAGE += 'Message: ' + ex.getMessage() + '\r\n';
                    INFO_MESSAGE += 'Cause: ' + ex.getCause() + '\r\n';
                    INFO_MESSAGE += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';
                    FSL_ApplicationLogCreator.integrationLog ('', '', 'IntakeWorkOrderAPI', 'IntakeWorkOrderAPI', true, INFO_MESSAGE, null);
                }
                
                // Check for active Work Orders or Cases
                /*
                List<WorkOrder> activeWorkOrders = [SELECT Id FROM WorkOrder WHERE AccountId = :objAccount.Id AND Status IN ('In Progress', 'Spotted') LIMIT 1];
                List<Case> activeCases = [SELECT Id FROM Case WHERE AccountId = :objAccount.Id AND Status IN ('In Progress', 'Spotted') LIMIT 1];
                
                if (!activeWorkOrders.isEmpty() || !activeCases.isEmpty()) {
                    res.statusCode = String.valueOf(ACG_ConstantsClass.ERROR_CODE400);
                    res.statusDescription = 'There is already an active work order or case for this account';
                    return res;
                }*/
                
                objCase = createcase(objAccount, jsonParser);
                objCase.ServiceContractId = serviceContractId;
                insert objCase;

                //Make sure Work Type and T code is set for the case. For all other channel types that create work order,
                //this part is set at the time of the Work Order creation.
                //PR893288-5051 By pass WorkType Update for IVR Cases
                if(objCase.Channel__c =='IVR') {
                  
                    // PR893288-5051 Added to ensure that work Type is blank for IVR cases.
                } else{ 
                if(String.isBlank(objCase.Pacesetter_Code__c)) {
                    String[] IdTcodePCC =  (getWorkTypeId(objCase.Id)).split('#');
                    if(IdTcodePCC.size()==3) {
                        objCase.ACG_Work_Type__c = IdTcodePCC[0];
                        objCase.T_Code__c = IdTcodePCC[1];
                        objCase.Pacesetter_Code__c = IdTcodePCC[2];
                    }
                    update objCase;
                }
                }
                Case returnedCase = [select CaseNumber,Genesys_ConversationId__c,ACG_Case_Contact_Number__c,ACG_SMS_Opt_In__c, createdDate, Vehicle_Location_State__c, ACG_Service_Type__c from Case where id = :objCase.Id];//EMI
                if(jsonParser.channel == 'IVR' || (jsonParser.channel == 'VERINT' && jsonParser.callType == 'Partial')) {
                    res.CaseId = objCase.Id;
                    if(jsonParser.comments!=null && !jsonParser.comments.isempty()) {
                        if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_CallCommentsFuture)){
                            createCallComments_Future(jsonParser.comments,'',objCase.Id); //AGB 10/15/24 SSFI-469
                        }
                        else{
                            lstCallComments = createCallComments(jsonParser.comments,'',objCase.Id);
                            if(!lstCallComments.isempty()) {
                                insert lstCallComments;
                            }
                        }
                    }
                } else {
                    if(jsonParser.channel == 'VERINT') jsonParser.userId = 'EXPSVC';

                    //Prepare for Asynch callout for Work Order creation. We need to calculate the callKey here and pass it in json parser since
                    //Chatbot response needs this info. It also needs the pta info.
                    //Other channels need the callId
                    res.CaseId = objCase.Id;

                    //CallReceiveWorkOrderIntegration.CaseToJsonWrapper jsonWrapper = new CallReceiveWorkOrderIntegration.CaseToJsonWrapper();
                    //jsonParser.callId = jsonWrapper.PopulateCallId(returnedCase.caseNumber);

                    
                    //retrieve the pta
                    res.timezone = jsonParser.timezoneId;
                    res.PtaMinutes = Test.isRunningTest() ? 30 : DefaultStatePTA.getDefaultStatePTA ( returnedCase.Vehicle_Location_State__c, returnedCase.ACG_Service_Type__c );                    
                    DateTime pta = Test.isRunningTest() ? null : DefaultStatePTA.getPTADateTime ( returnedCase.Vehicle_Location_State__c, returnedCase.ACG_Service_Type__c );
                    if(pta != null) {
                        //res.PtaLocal = String.valueOfGMT(pta).replace(' ','T');
                        res.PtaLocal = pta.format('yyyy-MM-dd HH:mm:ss', res.timezone).replace(' ','T');
                        res.PtaUTC = String.valueOfGMT(pta).replace(' ','T');
                    }

                    //convert parameters to callout to String
                    //String stringJsonParser = json.serialize(jsonParser);
                    //String stringObjCase = json.serialize(objCase);

                    if(!Test.isRunningTest()) {
                        //createWorkOrderCallout(stringObjCase, stringJsonParser);
                    }
                    objwo = createWorkOrder(objCase, jsonParser);
                    objwo.Call_Id__c = objwo.WorkOrderNumber ;
                    objwo.Member_Account__c = accountId;
                    objwo.ServiceContractId = serviceContractId;
                    objwo.Call_Type__c = jsonParser.callType;
                    //objwo.Call_Id__c = objwo.WorkOrderNumber ;
                    //update objwo;
                    //Workorder returnedWO = [SELECT Id, Call_Id__c FROM WorkOrder WHERE Id =: objwo.Id];
                    jsonParser.callId = objwo.Call_Id__c  ;
                    //system.debug('*******' + returnedWO.Call_Id__c);
                    res.callId = objwo.Call_Id__c;
                    res.externalId = getCallKey(returnedCase.createdDate, getClubCode(jsonParser), jsonParser.callId);  
                    objwo.External_Id__c  = res.externalId ;
                    update objwo;
                    if(jsonParser.comments!=null && !jsonParser.comments.isempty()) {
                        if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_CallCommentsFuture)){
                            createCallComments_Future(jsonParser.comments,objwo.Id,objCase.Id); //AGB 10/15/24 SSFI-469
                        }
                        else{
                            lstCallComments = createCallComments(jsonParser.comments,objwo.Id,objCase.Id);
                            if(!lstCallComments.isempty()) {
                                insert lstCallComments;
                            }
                        }//end else
                    }//end if
                }
                if(String.isNotBlank(returnedCase.Genesys_ConversationId__c)){
                    genesysIds = returnedCase.Genesys_ConversationId__c;
                }
                if(returnedCase.ACG_Case_Contact_Number__c != null){
                    if(objAccount.PersonMobilePhone != returnedCase.ACG_Case_Contact_Number__c){
                        objAccount.PersonMobilePhone = returnedCase.ACG_Case_Contact_Number__c;
                        //objAccount.ACG_SMS_Opt_In__c = returnedCase.ACG_SMS_Opt_In__c;//EMI
                        update objAccount;
                    } 
                }
            }
            SUCCESS_MESSAGE = system.label.CASE_CREATE_SUCCESS_MSG;
        }
        else if(jsonParser.OperationType == UPDATE_GENESYS_ID && jsonparser.CaseId!=null 
                && jsonparser.CaseId!='') {
            updateGenesysConversationIdOnCase(request.requestBody.toString());
            objCase = [select Id,Genesys_ConversationId__c,casenumber,Member_Location_TZ_Offset__c from case where id=:jsonparser.CaseId];
            SUCCESS_MESSAGE = SYSTEM.label.CASE_UPDATE_SUCCESS_MSG;
            res.CaseId = objCase.Id;
            genesysIds = objCase.Genesys_ConversationId__c;
        }
        else if(jsonParser.OperationType == ACG_ConstantsClass.CASE_UPDATE && jsonparser.CaseId!=null 
                && jsonparser.CaseId!='') {
            updatecase(request.requestBody.toString());
            objCase = [select id,casenumber,Member_Location_TZ_Offset__c from case where id=:jsonparser.CaseId];
            SUCCESS_MESSAGE = SYSTEM.label.CASE_UPDATE_SUCCESS_MSG;
        }
        else if(jsonParser.OperationType ==ACG_ConstantsClass.CALL_MOVER && jsonparser.CaseId!=null 
                && jsonparser.CaseId!='') {
            objcase = [select id,AccountId,ACG_Service_type__C from case where id=:jsonParser.CaseId];
            if(objcase.AccountId!=null) {
                objAccount = [select id from Account where id =:objcase.AccountId];
                boolMemberFound =true;
            }
            if(boolMemberFound) {
                lstofMemVehicles = [select id,Vehicle_Make__c,Vehicle_Model__c,Vehicle_Year__c,Vehicle_Plate__c,
                               Vehicle_Color__c from FSL_Member_Vehicle__c where ACG_Member__C=:objAccount.Id
                               and  Vehicle_Make__c=:jsonParser.Vehicle.make 
                               and  Vehicle_Model__c=:jsonParser.Vehicle.model
                               and  Vehicle_Year__c=:jsonParser.Vehicle.year
                               and  Vehicle_Plate__c=:jsonParser.Vehicle.plate //EMI
                               and  Vehicle_Color__c=:jsonParser.Vehicle.color];           
            }
            if(!boolMemberFound ||(boolMemberFound && lstofMemVehicles.isEmpty())) {
                objmemVehicle = createMemberVehicle(jsonParser,objAccount);
                insert objmemVehicle;
            } else if(!lstofMemVehicles.isEmpty()) {
                objmemVehicle = lstofMemVehicles[0];
            }
            objcase = createcase(objAccount,jsonParser);
            objcase.Member_Vehicle__c = objmemVehicle.Id;
            upsert objcase;
            callMover(objcase.Id);
            SUCCESS_MESSAGE = SYSTEM.label.CASE_UPDATE_SUCCESS_MSG;
        }      
        else if(jsonParser.OperationType == ACG_ConstantsClass.UPDATE_SERVICE_APPOINTMENT && 
                jsonparser.WorkorderID!=null && jsonparser.WorkorderID!='' &&
                jsonparser.SlotStartDateTime!=null && jsonparser.SlotStartDateTime!='' &&
                jsonparser.SlotEndDateTime!=null && jsonparser.SlotEndDateTime!='' ) {
            //VBR
            //updateServiceAppointment(jsonparser.WorkorderID,jsonparser.SlotStartDateTime,jsonparser.SlotEndDateTime,jsonparser);
            //objcase = new case(Id=jsonparser.CaseId);
            //SUCCESS_MESSAGE = SYSTEM.Label.SERVICE_APPOINTMENT_UPDATE_SUCCESS_MSG;
            //workorder create_workorder = [select id,workordernumber from workorder where id=:jsonparser.WorkorderID];
            //res.workOrderNumber = create_workorder.workordernumber; 
            //res.WorkOrderId = create_workorder.id;
        }
        else if(jsonParser.OperationType == ACG_ConstantsClass.CANCEL &&
                jsonparser.CaseId!=null && jsonparser.CaseId!='') {
            objcase = new Case(Id = jsonParser.CaseId);
            List<workorder> create_workorder = [select id,workordernumber,status from workorder 
                                              where caseId=:jsonparser.CaseId order by createddate desc limit 1];
            if(!create_workorder.isempty()) {
                create_workorder[0].status=ACG_ConstantsClass.WORK_ORDER_STATUS_CANCELED;
                res.workOrderNumber = create_workorder[0].workordernumber; 
                res.WorkOrderId = create_workorder[0].id;
                SUCCESS_MESSAGE = SYSTEM.Label.WORK_ORDER_CANCEL_MSG+create_workorder[0].workordernumber;
                update create_workorder[0];
            } else {
                objcase.status = ACG_ConstantsClass.CASE_STATUS_CANCELED;
                objcase.ERS_BypassStatusValidationforFlow__c =true;
                update objcase;
                SUCCESS_MESSAGE = ACG_ConstantsClass.CASE_CANCEL_MSG;
            }
        }    
        else if(jsonParser.OperationType ==  ACG_ConstantsClass.IMMEDIATE_APPOINTMENT  ||jsonParser.OperationType == ACG_ConstantsClass.GET_SLOTS) {
            if(jsonParser.CaseId !=null) {
                objcase = [select id,AccountId,ACG_Service_type__C,ACG_Case_Contact_Number__c from case where id=:jsonParser.CaseId];
                strServiceType = objcase.ACG_Service_type__C;
                if(objcase.AccountId!=null) {
                    objAccount = [select id,phone,personcontactId,ispersonaccount from Account where id =:objcase.AccountId];
                    if(objcase.ACG_Case_Contact_Number__c!=null) {
                        objAccount.Phone=objcase.ACG_Case_Contact_Number__c;
                        update objAccount;  
                    } else if(jsonParser.ContactInformation?.telephoneNumber!=null) {
                        objAccount.Phone=jsonParser.ContactInformation?.telephoneNumber;
                        update objAccount; 
                    }
                    boolMemberFound =true;
                }
            }
            if(boolMemberFound) {
                lstofMemVehicles = [select id,Vehicle_Make__c,Vehicle_Model__c,Vehicle_Year__c,Vehicle_Plate__c,
                               Vehicle_Color__c from FSL_Member_Vehicle__c where ACG_Member__C=:objAccount.Id
                               and  Vehicle_Make__c=:jsonParser.Vehicle.make 
                               and  Vehicle_Model__c=:jsonParser.Vehicle.model
                               and  Vehicle_Year__c=:jsonParser.Vehicle.year
                               and  Vehicle_Plate__c=:jsonParser.Vehicle.plate//EMI
                               and  Vehicle_Color__c=:jsonParser.Vehicle.color];
            }
            if(!boolMemberFound ||(boolMemberFound && lstofMemVehicles.isEmpty())) {
                objmemVehicle = createMemberVehicle(jsonParser,objAccount);
                insert objmemVehicle;
            } else if(!lstofMemVehicles.isEmpty()) {
                objmemVehicle = lstofMemVehicles[0];
            }
            objCase = createcase(objAccount,jsonParser);
            objCase.Member_Vehicle__c = objmemVehicle.Id;
            upsert objCase;
            objwo = createWorkOrder(objAccount,objCase,jsonParser);
            objwo.Member_Vehicle__c = objmemVehicle.Id;
            objwo.Is_Draft_Work_Order__c = jsonParser.OperationType == ACG_ConstantsClass.GET_SLOTS?true:false;
            if(jsonParser.WorkorderId!=null && jsonParser.WorkorderId!='') {
                lstworkorder = [select id,case.ACG_Service_type__C,(select id,recordtype.name from serviceAppointments),(select id from workorderlineitems) 
                                from workorder where id=:jsonParser.WorkorderID];
                if(!lstworkorder.isempty()) {
                    objwo.id= lstworkorder[0].Id; 
                    for(serviceAppointment sa:lstworkorder[0].serviceAppointments) {
                        if(sa.recordtype.name=='Breakdown'){
                            breakdownAppointmentId = sa.Id;
                        } else if(sa.recordtype.name=='Tow'){
                            towServiceAppointmentId = sa.Id;
                        }
                    }
                    if(strServiceType!=jsonParser.IssueType){
                        for(workorderlineitem wli: lstworkorder[0].workorderlineitems){
                            lstDeleteSobjects.add(wli);
                        }
                    }
                }
            }
            upsert objwo;
            objcase.FSL_Work_Order__c = objwo.Id;
            if(objwo.Repair_Shop__c!=null){
                objcase.Repair_Shop__c = objwo.Repair_Shop__c;
                if(System.label.RepairShopFunctionality == 'TRUE'){
                    FSL_INTRepairShopOutbound.generateRepairShopRequest(objcase.Id,objwo.Id);
                }
            }
            objcase.status = ACG_Constantsclass.CASE_WORK_ORDER_CREATION_STATUS;
            update objcase;
            if(objcase.ERS_Notes__c!=null && objcase.ERS_Notes__c!='') {
                if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_WOFeedItemsFuture)){ //AGB 10/15/2024 SSFI-469
                    createWorkOrderFeedItem_Future(objcase.Id,objwo.Id);
                }
                else{
                    ERS_WorkOrderFromCase.createWorkOrderFeedItem(objcase,objwo);
                }
            }     
            if(jsonParser.comments!=null && !jsonParser.comments.isempty()) {
                if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_CallCommentsFuture)){
                    createCallComments_Future(jsonParser.comments,objwo.Id,objCase.Id); //AGB 10/15/24 SSFI-469
                }
                else{
                    lstCallComments = createCallComments(jsonParser.comments,objwo.Id,objCase.Id);
                    if(!lstCallComments.isempty()) {
                        insert lstCallComments;
                    }
                }//end else
            }//end if
            breakdownSA = createServiceAppointment(ACG_ConstantsClass.BREAKDOWN_APPOINTMENT, objwo,jsonParser);
            breakdownAddressLoader(breakdownSA,objwo);
            if(breakdownAppointmentId!=null) {
                breakdownSA.Id = breakdownAppointmentId;   
            }
            relatedAppointments.add(breakdownSA);
            if(jsonParser.TowDestination!=null && jsonParser.TowDestination.latitude !=null && jsonParser.TowDestination.latitude!=Double.valueOf('0') &&
                jsonParser.TowDestination.longitude !=null && jsonParser.TowDestination.longitude!=Double.valueOf('0')) {
                towSA = createServiceAppointment(ACG_ConstantsClass.TOW_APPOINTMENT, objwo,jsonParser);
                towSA.Duration = worktypeIdMap.get(objwo.WorktypeId) != null && towSA.Duration == null ? worktypeIdMap.get(objwo.WorktypeId).EstimatedDuration : towSA.Duration;
                towSA.Duration = towSA.Duration == null? 0: towSA.Duration; 
                if(breakdownAppointmentId!=null){
                    towSA.FSL__Related_Service__c=breakdownAppointmentId;
                    towSA.FSL__Time_Dependency__c =ACG_ConstantsClass.SA_TIME_DEPENCY;
                }

                towSA.FSL_Needs_Address__c = false;
                towSA.DurationType = ACG_ConstantsClass.MINUTES;
                if(towServiceAppointmentId!=null) {
                    towSA.Id = towServiceAppointmentId;   
                }
                breakdownSA.FSL_IsLight_Service__c = true;
                towAddressLoader(towSA,objwo);
                relatedAppointments.add(towSA);
            } else {
                if(towServiceAppointmentId!=null) {
                    ServiceAppointment sa = new serviceAppointment(Id=towServiceAppointmentId);
                    List<FSL__Time_Dependency__c> lstTimedepndency = [select id,FSL__Service_Appointment_1__c 
                                                                      from FSL__Time_Dependency__c where id=:towServiceAppointmentId];
                    if(!lstTimedepndency.isEmpty()) {
                       lstDeleteSobjects.add(lstTimedepndency[0]); 
                    }
                    lstDeleteSobjects.add(sa);
                }
            }
            upsert relatedAppointments;
            if(breakdownAppointmentId==null || breakdownAppointmentId=='') {
                string bdid;
                for(ServiceAppointment sa:relatedAppointments) {
                    if(sa.Subject==ACG_ConstantsClass.BREAKDOWN_APPOINTMENT){
                        bdid=sa.Id;
                    }
                }
                for(ServiceAppointment sa:relatedAppointments) {
                    if(sa.Subject==ACG_ConstantsClass.TOW_APPOINTMENT) {
                        sa.FSL__Related_Service__c=bdid;
                        sa.FSL__Time_Dependency__c =ACG_ConstantsClass.SA_TIME_DEPENCY;
                    }
                }
                upsert relatedAppointments;
            }
            if(!lstDeleteSobjects.isEmpty()) {
                delete lstDeleteSobjects;
            }
            if (jsonParser.TowDestination!=null && jsonParser.TowDestination.latitude !=null  && jsonParser.TowDestination.latitude!=Double.valueOf('0') &&
                jsonParser.TowDestination.longitude !=null  && jsonParser.TowDestination.longitude!=Double.valueOf('0') && towServiceAppointmentId==null) {
                FSL__Time_Dependency__c appointmentDependency = createAppointmentDependency(breakdownSA, towSA);
                insert appointmentDependency;
            }
            if(jsonParser.OperationType==ACG_ConstantsClass.IMMEDIATE_APPOINTMENT){
                schedulecall(breakdownSA,towSA);
            }
            workorder create_workorder = [select id,workordernumber from workorder where id=:objwo.id];
            res.workOrderNumber = create_workorder.workordernumber; 
            res.WorkOrderId = create_workorder.id;
            SUCCESS_MESSAGE = SYSTEM.Label.WORK_ORDER_CREATE_MSG+create_workorder.workordernumber;
        }
        else {
            SUCCESS_MESSAGE =ACG_ConstantsClass.INVALID_REQUEST;
            res.statusCode = ACG_ConstantsClass.STATUS_CODE;
            response.statusCode = ACG_ConstantsClass.ERROR_CODE400; 
        }
        res.statusCode = res.statusCode!='' && res.statusCode!=null?res.statusCode:ACG_ConstantsClass.STATUS_CODE_200;
        if(resultFromSearchCaseForIVR != null) {
            res.CaseId = resultFromSearchCaseForIVR;
            SUCCESS_MESSAGE = 'Retrieved cases successfully';
        }
        if(genesysIds != null){
            res.genesysConversationId = genesysIds;
        }

        res.CallDate = System.now().format('yyyy-MM-dd');
        res.statusDescription = SUCCESS_MESSAGE;
        INTFSL_WorkOrderResponse_Wrapper.HEADER hed = new INTFSL_WorkOrderResponse_Wrapper.HEADER();
        hed.id = (String.IsNotBlank(jsonParser.id) ? jsonParser.id : IntegrationUtil.generateuniqueId());
        hed.type = jsonParser.OperationType;
        res.header = hed;
        FSL_ApplicationLogCreator.integrationLog (request.requestBody.toString(),JSON.serialize(res),'IntakeWorkOrderAPI',jsonParser.OperationType,false,SUCCESS_MESSAGE ,res.WorkOrderId);
        System.debug('------------- TIMESTAMP -----W : ' + Datetime.now());
        return res;
    }

    private static String getCallKey(Datetime createdDate, String clubCode, String callId) {

        String dateStr = createdDate.format('yyyyMMdd');

        return clubCode + '-' + dateStr + '-' + callId;
    }

    private static String getClubCode(INTFSLWorkOrderRequest_Wrapper jsonParser) {
        String clubcode = '';
        //if(jsonParser.memberNumber.length() == 16) {
           // clubcode = jsonParser.memberNumber.substring(3, 6);
        //} else if(jsonParser.channel == 'RAP') {
           // clubcode = jsonParser.sourceOrgCode;
          clubcode = Label.FSL_SourceClubCode;
        //}

        return clubcode;
    }

    /***
    * Method name        : createAccount
    * Description        : This method  binds the Account fields with request wrapper
    * Param jsonParser   : Request wrapper
    * Return Type        : Account 
    */
    @Testvisible
    private static Account createAccount(INTFSLWorkOrderRequest_Wrapper jsonParser) {
        FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
        FSL_Account.IAccountService service = accountFactory.createService();
        
        FSL_Account.MembershipInformation info = parser.parse( jsonParser );
        List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );
        
        return accounts[0];
    }
    
    /***
    * Method name        : createCase
    * Description        : This method  binds the case fields with request wrapper
    * Param jsonParser   : Request wrapper
    * acc                : Account
    * Return Type        : Case 
    */ 
    @Testvisible
    private static Case createCase(Account acc, INTFSLWorkOrderRequest_Wrapper jsonParser) {
        Map<string,string> mapcvt =new Map<string,string>();
        List<ERS_Case_VehicleType_Mapping__mdt> lstcvtmap= ERS_Case_VehicleType_Mapping__mdt.getAll().values();
        for(ERS_Case_VehicleType_Mapping__mdt cvt:lstcvtmap) {
           mapcvt.put(cvt.MasterLabel,cvt.Vehicle_Type_Case__c);
        }
        case cs = new case ();
        cs.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('ERS').getRecordTypeId();
        cs.ERS_Event_Type__c = ACG_ConstantsClass.ACG_CALL_TYPE_MEMBER;
        if(jsonParser.channel == 'IVR' || (jsonParser.channel == 'VERINT' && jsonParser.callType == 'Partial')) {} //Only set the type if we are creating a Work Order
        else cs.Type = 'Auto Work Order Submit';
        
        // example:  PS
        cs.ACG_Vehicle_Type__c = (String.ISBLANK(jsonParser.Vehicle?.Type) ? 'PS' : jsonParser.Vehicle?.Type);
        // example:  PS (Passenger Car/Truck)
        //cs.Member_Vehicle_Type__c = jsonParser.channel==ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR?ACG_ConstantsClass.DRR_VEHICLE_TYPE:mapcvt.get(jsonParser.Vehicle?.Type);
        if( cs.ACG_Vehicle_Type__c == '2M' ) cs.Member_Vehicle_Type__c = '2M (2-Wheeled Motorcycle)';
        else if( cs.ACG_Vehicle_Type__c == '3M' ) cs.Member_Vehicle_Type__c = '3M (3 - Wheeled Motorcycle)';
        else if( cs.ACG_Vehicle_Type__c == '4M' ) cs.Member_Vehicle_Type__c = '4M (ATV)';
        else if( cs.ACG_Vehicle_Type__c == 'BK' ) cs.Member_Vehicle_Type__c = 'BK (Bicycles)';
        else if( cs.ACG_Vehicle_Type__c == 'DW' ) cs.Member_Vehicle_Type__c = 'DW (Dual Wheels)';
        else if( cs.ACG_Vehicle_Type__c == 'GC' ) cs.Member_Vehicle_Type__c = 'GC (Golf Cart)';
        else if( cs.ACG_Vehicle_Type__c == 'PS' ) cs.Member_Vehicle_Type__c = 'PS (Passenger Car/Truck)';
        else if( cs.ACG_Vehicle_Type__c == 'R1' ) cs.Member_Vehicle_Type__c = 'R1 (RV < 23 feet)';
        else if( cs.ACG_Vehicle_Type__c == 'R1' ) cs.Member_Vehicle_Type__c = 'R2 (RV 24-32 feet)';
        else if( cs.ACG_Vehicle_Type__c == 'R3' ) cs.Member_Vehicle_Type__c = 'R3 (RV > 33 feet)';
        else if( cs.ACG_Vehicle_Type__c == 'SM' ) cs.Member_Vehicle_Type__c = 'SM (Snowmobile)';
        else if( cs.ACG_Vehicle_Type__c == 'TR' ) cs.Member_Vehicle_Type__c = 'TR (Trailer)';
        else cs.Member_Vehicle_Type__c = 'PS (Passenger Car/Truck)';

        cs.Flat_Tire_Status__c = jsonParser.hasSpareTire;
        cs.Member_Location_TZ_Offset__c = (jsonParser?.timeZoneOffset == null ? '' : jsonParser?.timeZoneOffset.left(9));        

        if(jsonParser.genesysConversationId != null){
            cs.Genesys_ConversationId__c = jsonParser.genesysConversationId;
        }
        if(String.isNotBlank(jsonParser.impairmentId)){
            cs.Impairment__c = jsonParser.impairmentId;
        }
        if(jsonParser.channel==ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR) {
            cs.ACG_Vehicle_Location_Type__c =jsonParser.BreakdownLocation?.locationCode;
        }
        if(jsonParser.BreakdownLocation!=null) {
            cs.ACG_Vehicle_Location_Address__c = jsonParser.BreakdownLocation?.streetNumber!=null?jsonParser.BreakdownLocation?.streetNumber+' ':''; 
            cs.ACG_Vehicle_Location_Address__c += jsonParser.BreakdownLocation?.streetName!=null?jsonParser.BreakdownLocation?.streetName+' ':'';  
            cs.ACG_Vehicle_Location_Address__c +=  jsonParser.BreakdownLocation?.crossStreet!=null?jsonParser.BreakdownLocation?.crossStreet+' ':''; 
            cs.ACG_Vehicle_Location_Address__c += jsonParser.BreakdownLocation?.city!=null?jsonParser.BreakdownLocation?.city+' ':'';
            cs.ACG_Vehicle_Location_Address__c += jsonParser.BreakdownLocation?.postalCode!=null?jsonParser.BreakdownLocation?.postalCode+' ':''; 
            cs.ACG_Vehicle_Location_Address__c += jsonParser.BreakdownLocation?.state!=null?jsonParser.BreakdownLocation?.state:'';
            cs.Vehicle_Location_Street__c = jsonParser.BreakdownLocation?.streetNumber!=null?jsonParser.BreakdownLocation.streetNumber+' ':''; 
            cs.Vehicle_Location_Street__c += jsonParser.BreakdownLocation?.streetName!=null?jsonParser.BreakdownLocation.streetName:'' ;
            cs.Vehicle_Location_City__c = jsonParser.BreakdownLocation?.city;
            cs.Vehicle_Location_Postal_Code__c = jsonParser.BreakdownLocation?.postalCode;
            cs.Vehicle_Location_State__c = jsonParser.BreakdownLocation?.state;

            cs.Vehicle_Geolocation__Latitude__s = jsonParser.BreakdownLocation?.latitude;
            cs.Vehicle_Geolocation__Longitude__s = jsonParser.BreakdownLocation?.longitude;
            if(jsonParser.BreakdownLocation?.latitude!=null && jsonParser.BreakdownLocation?.longitude!=null) {
                cs.BSP_Available__c=BSPAvailability.bspAvailabilityCheck(jsonParser.BreakdownLocation?.latitude,jsonParser.BreakdownLocation?.longitude);
            }
        }
        if(jsonParser.TowDestination!=null) {
            cs.Tow_Destination_Street__c = jsonParser.TowDestination?.streetNumber!=null?jsonParser.TowDestination.streetNumber+' ':''; 
            cs.Tow_Destination_Street__c += jsonParser.TowDestination?.streetName!=null?jsonParser.TowDestination.streetName:'' ;
            cs.Tow_Destination_City__c = jsonParser.TowDestination?.city;
            cs.Tow_Destination_Postal_Code__c = jsonParser.TowDestination?.postalCode;
            cs.Tow_Destination_State__c = jsonParser.TowDestination?.state;
            cs.Tow_Geolocation__Latitude__s = jsonParser.TowDestination?.latitude;
            cs.Tow_Geolocation__Longitude__s = jsonParser.TowDestination?.longitude;
            cs.ACG_Tow_Destination_Address__c =  jsonParser.TowDestination?.streetNumber!=null?jsonParser.TowDestination?.streetNumber+' ':''; 
            cs.ACG_Tow_Destination_Address__c += jsonParser.TowDestination?.streetName!=null?jsonParser.TowDestination?.streetName+' ':'';
            cs.ACG_Tow_Destination_Address__c += jsonParser.TowDestination?.crossStreet!=null?jsonParser.TowDestination?.crossStreet+' ':''; 
            cs.ACG_Tow_Destination_Address__c += jsonParser.TowDestination?.city!=null?jsonParser.TowDestination?.city+' ':'';
            cs.ACG_Tow_Destination_Address__c += jsonParser.TowDestination?.postalCode!=null?jsonParser.TowDestination?.postalCode +' ':'';
            cs.ACG_Tow_Destination_Address__c += jsonParser.TowDestination?.state!=null?jsonParser.TowDestination?.state:'';
            //TODO: Default it for now, we don't have a mapping on CDM
            cs.Contact_at_Drop_off__c = 'Member will follow';

            //For a Verint call, if hasSpareTire is equal to 'No Spares', Tow_Request_Reason__c will be 'No Spare Tires'
            //Otherwise Tow_Request_Reason__c will be 'Miscellaneous'
            cs.Tow_Request_Reason__c = 'Miscellaneous';
            if(cs.Flat_Tire_Status__c == 'No Spares') {
                cs.Tow_Request_Reason__c = 'No Spare Tires';
                cs.Flat_Tire_Status__c = '';
            }
        } else {
            cs.Tow_Destination_Street__c = '';
            cs.Tow_Destination_City__c = '';
            cs.Tow_Destination_Postal_Code__c = '';
            cs.Tow_Destination_State__c = '';
            cs.Tow_Geolocation__Latitude__s = null;
            cs.Tow_Geolocation__Longitude__s = null;
            cs.ACG_Tow_Destination_Address__c = '';
        }
        cs.Subject =Label.INT_ERS_CASE_CALL;
        cs.Call_Origin__c = jsonParser.channel;
        cs.ACG_Driving_Directions__c = jsonParser.BreakdownLocation?.driverDirections;
        cs.ACG_Make__c = jsonParser.Vehicle?.make;
        cs.ACG_Color__c = jsonParser.Vehicle?.color;
        cs.ACG_Plate__c = jsonParser.Vehicle?.plate;//EMI
        cs.ACG_Model__c = jsonParser.Vehicle?.model;
        cs.ACG_Year__c = (jsonParser.Vehicle?.year == null ? '' : jsonParser.Vehicle?.year.left(5));
        cs.Vehicle_Trim_Level__c = jsonParser.Vehicle?.trim;
        cs.Vehicle_Odometer__c = jsonParser.Vehicle?.odometer;
        cs.ACG_VIN__c = jsonParser.Vehicle?.vin;
        cs.Vehicle_Drive_Type__c = (jsonParser.Vehicle?.driveType == null ? '' : jsonParser.Vehicle?.driveType.left(10));
        //specialEquipmentNeeds not in Case
        //licensePlateIdentifier not in case
        //licensePlateState not in case
        cs.Vehicle_Fuel_Type__c = (jsonParser.typeOfFuel == 'Gasoline' ? 'Gas' : jsonParser.typeOfFuel);
        cs.Flatbed_Required__c= jsonParser.Vehicle?.flatbedRequired!=null?jsonParser.Vehicle?.flatbedRequired:false;
        cs.ACG_Case_Contact_Number__c = jsonParser.ContactInformation?.telephoneNumber?.replaceAll('\\D', '');
        if(jsonParser.channel == 'IVR')
        {
        cs.ACG_SMS_Opt_In__c=true;    
        }
        else{
        cs.ACG_SMS_Opt_In__c=jsonParser.ContactInformation?.smsOptin!=null?jsonParser.ContactInformation?.smsOptin:false;
        }
        cs.Call_Opt_in__c = jsonParser.ContactInformation?.callOptin!=null?jsonParser.ContactInformation?.callOptin:false;
        system.debug('AGB Check1:'+jsonParser.ContactInformation?.telephoneNumber?.replaceAll('\\D', '')+' : '+jsonParser.ContactInformation?.smsOptin!=null?jsonParser.ContactInformation?.smsOptin:false);
        cs.Case_Membership_Level__c = jsonParser.ContactInformation?.currentBenefitLevel;
        //cs.Member_Since__c = jsonParser.ContactInformation?.joinYear;
        cs.Number_of_passengers__c = jsonParser.numberOfPassengers;
        cs.Vehicle_Lockout_Reason__c = jsonParser.lockedOutType;
        cs.Channel__c = jsonParser.userid=='SAIVR'?jsonParser.userid:jsonParser.channel;
        cs.OS__c = jsonParser.os;
        cs.Device__c = jsonParser.device;
        if(acc != null && acc.Id != null) {
            
            cs.AccountId = acc.Id;
            cs.Account = acc;
        }
        string wtvalue;
        cs.ACG_Service_Type__c = jsonParser.IssueType;
        if(jsonparser.CaseId != null && jsonparser.CaseId != '' 
            && jsonparser.operationType != ACG_ConstantsClass.CASE_CREATION) {
            cs.Id=jsonparser.CaseId;
        }
        if(jsonParser.IssueType != null && jsonParser.IssueType != '' && 
          (jsonParser.OperationType ==  ACG_ConstantsClass.IMMEDIATE_APPOINTMENT  
           ||jsonParser.OperationType == ACG_ConstantsClass.GET_SLOTS 
           || jsonParser.OperationType == ACG_ConstantsClass.CALL_MOVER)) {
            if(jsonparser.SlotStartDateTime != null && jsonparser.SlotStartDateTime != '' && jsonparser.SlotEndDateTime != null && jsonparser.SlotEndDateTime != '') {
                if(cs.Appointment_Requested__c != true) {
                    cs.Appointment_Requested__c = true;
                    update cs;
                }            
            }
            String[] IdTcodePCC =  (getWorkTypeId(jsonParser.CaseId)).split('#');
            if(IdTcodePCC.size() == 3) {
                cs.ACG_Work_Type__c = IdTcodePCC[0];
                cs.Pacesetter_Code__c = IdTcodePCC[2];
                cs.T_Code__c = IdTcodePCC[1];
            }
        } else if(jsonParser.pacesetterCode != null && jsonParser.pacesetterCode != '' && jsonParser.channel != ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR) {
            try {
                cs.Priority=jsonParser.priority=='Normal'?'Low':jsonParser.priority;//ERBO-4634,ERSBO-4573,ERSBO-4648 smart action team will be sending priority in payload
                if(String.isBlank(jsonParser.priority)){
                    cs.Priority = 'Medium';
                }
                cs.Bypass_Priority_Update__c=true;
                FSL_TroubleCode_WorkType__mdt troubleCodeWorkType = [Select Id,AdditionalCriteria__c,TroubleCode__c,WorkType__c,Service_Type__c,Legacy_Tcode__c 
                                                                 from FSL_TroubleCode_WorkType__mdt WHERE TroubleCode__c =:jsonParser.pacesetterCode];
                if(troubleCodeWorkType != null) {
                    string mdttcode=troubleCodeWorkType.Legacy_Tcode__c;
                    if(troubleCodeWorkType.Service_Type__c == 'Tow') {
                        cs.ACG_Service_Type__c = troubleCodeWorkType.Service_Type__c;
                    }
                    if (troubleCodeWorkType.AdditionalCriteria__c) {

                        //Matches <value>R1;R2;R3</value>
                        List<String> ValidRVVehicles = New List<String>();
                        ValidRVVehicles = System.Label.FSL_Valid_RV_VehicleTypes.split(';');
                        
                        //<value>PS;PG;LG;LC</value>
                        List<String> ValidLocation = New List<String>();
                        ValidLocation = System.Label.FSL_Valid_LC_LocationCode.split(';');
                        
                        //<value>2M;3M</value>
                        List<String> ValidMotorVehicle = New List<String>();
                        ValidMotorVehicle = System.Label.FSL_Valid_MV_VehicleTypes.split(';');
                        
                        //<value>2M;3M;R1;R2;R3</value>
                        List<String> ValidRV_MV_Vehicle = New List<String>();
                        ValidRV_MV_Vehicle = System.Label.FSL_Valid_RV_MV_VehicleTypes.split(';');                            
                        
                        if ((troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Extrication')) && (ValidRVVehicles.contains(cs.ACG_Vehicle_Type__c)))
                        {
                            wtvalue = System.Label.FSL_RV_Extrication_WorkType; 
                        }   
                        if ((troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Extrication')) && 
                            (!ValidRVVehicles.contains(cs.ACG_Vehicle_Type__c)))                                                     
                        {
                            //Requestedworktype = 'Non-RV Extrication';
                            wtvalue = System.Label.FSL_Non_RV_Extrication_WorkType;
                        }
                        if ((troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Tow')) ) 
                        {
                            //Requestedworktype = 'Passenger Car Tow';
                            wtvalue = System.Label.FSL_Passenger_Car_Tow_WorkType;
                        }                                                                                
                    } else {
                        wtvalue = troubleCodeWorkType.WorkType__c;                            
                    }
                    if(wtvalue!='' && wtvalue != null) {
                        WorkType worktype = [Select Id,name,T_Code__c from WorkType where name =:wtvalue limit 1];
                        cs.ACG_Work_Type__c = worktype.Id;
                        // updated bala for IVR Chnages 
                        List<ERS_Case_to_Work_Type_Mapping__mdt> mdtList = [SELECT  
                                                                        Service_Type__c, 
                                                                        Vehicle_Fuel_Type__c, 
                                                                        Work_Type__c,Vehicle_Location_Type__c,
                                                                        Vehicle_Lockout_Reason__c,Flat_Tire_Status__c
                                                                        FROM ERS_Case_to_Work_Type_Mapping__mdt
                                                                        WHERE Case_to_Work_Type_Mapping_Status__c =:ACG_ConstantsClass.ANNOUNCEMENTS_STATUS
                                                                        and Work_Type__c =: wtvalue 
                                                                        ORDER BY Priority__c ASC NULLS LAST limit 1];
                        if(!mdtList.isEmpty()) {
                            if(wtvalue.equalsIgnoreCase('Tire Change') && (jsonParser?.hasSpareTire == null || jsonParser?.hasSpareTire == '')) {
                                cs.Flat_Tire_Status__c = mdtList[0].Flat_Tire_Status__c;
                            }
                            //cs.Vehicle_Lockout_Reason__c = mdtList[0].Vehicle_Lockout_Reason__c;
                            cs.Vehicle_Fuel_Type__c = mdtList[0].Vehicle_Fuel_Type__c;
                            if(mdtList[0].Service_Type__c != 'Tow') {
                                cs.ACG_Service_Type__c = mdtList[0].Service_Type__c;
                            }
                        }
                    
                        cs.Pacesetter_Code__c = jsonParser.pacesetterCode;
                        cs.T_Code__c = worktype.T_Code__c!=null?worktype.T_Code__c:mdttcode;
                    }
                }  
            } catch(Exception e) {} 
        }

        //if(jsonParser.BreakdownLocation != null && cs.ACG_Service_Type__c == 'Battery') {
        //    if(jsonParser.BreakdownLocation?.latitude!=null && jsonParser.BreakdownLocation?.longitude!=null) {
        //        cs.BSP_Available__c=BSPAvailability.bspAvailabilityCheck(jsonParser.BreakdownLocation?.latitude,jsonParser.BreakdownLocation?.longitude);
        //    }
        //}
        
        if(jsonparser.comments != null) {
            if(jsonparser.comments.size()>0) {
                cs.ERS_Notes__c = jsonparser.comments[0];
            }
        }
        return cs;
    }

    //unused method
    //@future(Callout=true)
    /*private static void createWorkOrderCallout(String stringObjCase, String stringJsonParser) {

        INTFSLWorkOrderRequest_Wrapper jsonParser = 
            (INTFSLWorkOrderRequest_Wrapper)Json.deserialize(stringJsonParser, INTFSLWorkOrderRequest_Wrapper.class);
        Case objCase = (Case)Json.deserialize(stringObjCase, Case.class);
    
        createWorkOrder(objCase, jsonParser);
    }*/

    @TestVisible
    private static WorkOrder createWorkOrder(case casObj, INTFSLWorkOrderRequest_Wrapper requestJson) {

        //validateCase(casObj);     //Validate necessary fields are populated on the Case
        //string clubcode = validateClubCode(casObj);     //Validate if location is in ACG territory (for CallMover scenario)
        //string clubcode = '';  
        //if(validateMembershipCoverage(casObj.id, NULL) == false){   //Validate member's coverage based on Membership level
        //   throw new customException('You are not eligible for this service, please check member\'s membership level');
        //}

        FSL_JSonParserWorkOrder jsonParser = new FSL_JSonParserWorkOrder();
        CallReceiveWorkOrderIntegration.CaseToJsonWrapper jsonWrapper = new CallReceiveWorkOrderIntegration.CaseToJsonWrapper();

        String clubcode = '';
        /*if(requestJson.memberNumber.length() == 16) {
            clubcode = requestJson.memberNumber.substring(3, 6); //TODO
        } else if(requestJson.channel == 'RAP') {
            clubcode = requestJson.sourceOrgCode;
        }*/
        clubcode = Label.FSL_SourceClubCode;

        //String[] IdTcodePCC =  (getWorkTypeId(casObj.Id)).split('#');
        //if(IdTcodePCC.size()==3) {
        //    casObj.ACG_Work_Type__c = IdTcodePCC[0];
        //    casObj.T_Code__c = IdTcodePCC[1];
        //    casObj.Pacesetter_Code__c = IdTcodePCC[2];
        //}
        
        jsonParser = jsonWrapper.Wrap(casObj, clubcode, requestJson);
        system.debug('********' + jsonParser);
        WorkOrder WO_returned = CallReceiveWorkOrderIntegration.createWO(jsonParser);

        casObj.Status = Label.ERS_CASE_STATUS_ON_WO_CREATION ; //ERSBO-1728
        casObj.FSL_Work_Order__c = WO_returned.Id;
        casObj.FSL_Service_Appointment__c = WO_returned.ServiceAppointments[0].Id;
        casObj.Pta__c = WO_returned.Pta__c;
        // Check for Repair Shop. If yes, notify RSP
        if(requestJson.towDestination?.shopId != null){
            String repairShopId = requestJson.towDestination?.shopId;
            List<Account> AAR = [select Id from Account where Integration_Id__c = :repairShopId and Integration_Id__c!=null limit 1];
            if(AAR.size() > 0){
                casObj.Repair_Shop__c = AAR[0].Id;
            }
        }
        update casObj;
        if(System.label.RepairShopFunctionality == 'TRUE' && !Test.isRunningTest() && casObj.Repair_Shop__c != null){
            FSL_INTRepairShopOutbound.generateRepairShopRequest(casObj.Id,WO_returned.Id);
        }

        if(!String.ISBLANK(casObj.ERS_Notes__c)) {
            if(Boolean.ValueOf(Label.INTFSLWorkorderIntake_WOFeedItemsFuture)){ //AGB 10/15/2024 SSFI-469
                createWorkOrderFeedItem_Future(casObj.Id,WO_returned.Id); 
            }
            else{
                ERS_WorkOrderFromCase.createWorkOrderFeedItem(casObj, WO_returned);
            }
        }      
        
        WO_returned.Repair_Shop__c = casObj.Repair_Shop__c;
        return WO_returned;
    }
    
    /***
    * Method name        : createWorkOrder
    * Description        : This method  binds the workOrder fields with request wrapper
    * Param jsonParser   : Request wrapper
    * objAcc             : Account
    * objcs              : Case
    * Return Type        : WorkOrder 
    */  
    @TestVisible
    private static WorkOrder createWorkOrder(Account objAcc,case objcs,INTFSLWorkOrderRequest_Wrapper jsonParser) {
        WorkOrder wo = new WorkOrder();  
        Id lightWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
        Id towWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
        wo.WorkTypeId =objcs.ACG_Work_Type__c;
        wo.street = jsonParser.BreakdownLocation?.streetNumber + jsonParser.BreakdownLocation?.streetName;
        wo.city = jsonParser.BreakdownLocation?.city;
        if(jsonParser.BreakdownLocation.state!=null && 
           jsonParser.BreakdownLocation.state.length()==2){
          wo.StateCode = jsonParser.BreakdownLocation?.state;
        } else {
        wo.state = jsonParser.BreakdownLocation?.state;
        }
        wo.CountryCode =ACG_ConstantsClass.US;
        wo.postalcode = jsonParser.BreakdownLocation?.postalcode;
        wo.Cross_Street__c= jsonParser.BreakdownLocation?.crossStreet;
        wo.Location_Code__c= jsonParser.BreakdownLocation?.locationCode;
        wo.Driver_Directions__c = jsonParser.BreakdownLocation?.driverDirections;
        wo.Location_Code__c = jsonParser.BreakdownLocation?.locationCode;
        wo.Landmark__c= jsonParser.BreakdownLocation?.landmark;
        wo.WO_Member_Phone_Number__c = jsonParser.ContactInformation?.telephoneNumber;
        wo.Number_Of_Passengers__c = jsonParser.numberOfPassengers;
        wo.Channel__c = jsonParser.channel;
        wo.Call_Type__c= jsonParser.callType;
        wo.OS__c = jsonParser.os;
        wo.Device__c = jsonParser.device;
        if(objAcc != null) {
            wo.Member_Account__c =objAcc.Id;
            wo.contactid=objAcc.ispersonaccount==true?objAcc.personcontactId:null;
        }
        wo.ACG_Call_Type__c = objcs.ERS_Event_type__c;
        if(objcs.ACG_Vehicle_Location_Type__c!=null){
        wo.Vehicle_Location_Type__c = objcs.ACG_Vehicle_Location_Type__c;
        }
        wo.CaseId = objcs.Id;
        if(jsonParser.channel==ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR){
            wo.Vehicle_Type__c = objcs.Member_Vehicle_Type__c;
        } else{
            wo.vehicle_Type__C = jsonParser.Vehicle?.Type;
        }
        wo.FSL_Pacesetter__c = objcs.Pacesetter_Code__c;
        wo.T_Code__c = objcs.T_Code__c;
    
        string priority;
        if(objcs.Id!=null){
            priority = [select id,priority from case where id=:objcs.Id limit 1].priority;
        }
        //Map Tow destination Details 
        if(jsonParser.TowDestination!=null) {
            wo.Tow_City__c = jsonParser.TowDestination?.city;
            wo.Tow_State__c = jsonParser.TowDestination?.state;
            wo.Tow_Postal_Code__c = jsonParser.TowDestination?.postalCode;
            wo.Tow_Street__c = jsonParser.TowDestination?.streetNumber + jsonParser.TowDestination?.streetName;
            wo.Tow_Cross_Street__c=jsonParser.TowDestination?.crossStreet;
            wo.Tow_Destination_Name__c = jsonParser.TowDestination?.locationName;
            string AccountId = jsonParser.TowDestination?.shopId;
            if(AccountId != '' & AccountId != null) {
                try{
                    if(AccountId.length() < 15) {
                        Account oAAALoc = [Select id from Account where Facility_id__c=:AccountId and Recordtype.developername='ACG_AAR'];
                        AccountId= oAAALoc.id;
                    }
                    String objectName = Id.valueof(AccountId).getsobjecttype().getDescribe().getName();
                    List<Account> lstacc = new List<Account>();
                    if(objectName == 'Account') {
                        lstacc = [select id from account where id = :AccountId];
                    } else if(objectName == 'AAA_Location__C') {
                        lstacc =[select id from account where ACG_AAA_Location__C = :AccountId];
                    }
                    if(!lstacc.isEmpty())
                        wo.Repair_Shop__c = lstacc[0].Id;
                } Catch(Exception e){}
            }
            if (jsonParser.TowDestination.latitude != null && jsonParser.TowDestination.longitude != null) {
                if ((String.ValueOf(jsonParser.TowDestination.latitude) != ACG_ConstantsClass.NAN && String.ValueOf(jsonParser.TowDestination.longitude) != ACG_ConstantsClass.NAN)) {
                    wo.Tow_Location__Latitude__s = Decimal.ValueOf(jsonParser.TowDestination.latitude);
                    wo.Tow_Location__Longitude__s = Decimal.ValueOf(jsonParser.TowDestination.longitude);
                }
            }
        } else{
            wo.Tow_City__c ='';
            wo.Tow_State__c ='';
            wo.Tow_Postal_Code__c ='';
            wo.Tow_Street__c ='';
            wo.Tow_Cross_Street__c='';
            wo.Tow_Destination_Name__c ='';
            wo.Tow_Location__Latitude__s = null;
            wo.Tow_Location__Longitude__s = null;
        } 
        
        if (jsonParser.BreakdownLocation.latitude != null && jsonParser.BreakdownLocation.longitude != null) {
            if ((String.ValueOf(jsonParser.BreakdownLocation.latitude) != ACG_ConstantsClass.NAN && String.ValueOf(jsonParser.BreakdownLocation.longitude) != ACG_ConstantsClass.NAN)) {
                wo.Latitude = Decimal.ValueOf(jsonParser.BreakdownLocation.latitude);
                wo.Longitude = Decimal.ValueOf(jsonParser.BreakdownLocation.longitude);
                wo.Breakdown_Location__Latitude__s = wo.Latitude;
                wo.Breakdown_Location__Longitude__s = wo.Longitude;
                wo.ServiceTerritoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(double.valueOf(jsonParser.BreakdownLocation.longitude), double.valueOf(jsonParser.BreakdownLocation.latitude));
            }
        }
        wo.Priority = priority;
        if (jsonParser.TowDestination!=null && jsonParser.TowDestination.latitude != null && jsonParser.TowDestination.latitude!=Double.valueOf('0')
              && jsonParser.TowDestination.longitude != null && jsonParser.TowDestination.longitude!=Double.valueOf('0')) {
            wo.RecordTypeId = towWorkorderRecordTypeId;
            wo.Is_Tow_WorkType__c =true;
        }else{
            wo.RecordTypeId = lightWorkorderRecordTypeId;
            wo.Is_Tow_WorkType__c =false;
        }
        wo.Call_Type__c = jsonParser.callType;
        wo.Original_Member_Id__c = jsonParser.memberNumber;
        //if(String.isNotBlank(wo.Call_Type__c) && wo.Call_Type__c ==ACG_ConstantsClass.CALL_ORIGIN_IVR){
         //wo.Channel__c= jsonParser.userid;//ERSBO-4288:Modified as per Bala's inputs 
         //wo.ACG_Call_Type__c=jsonParser.userid;//ERSBO-4288:Modified as per Bala's inputs
         //wo.Call_Type__c=jsonParser.userid; //ERSBO-4288:Modified as per Bala's inputs 
        //}else if(wo.Call_Type__c ==ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR){
          // wo.Channel__c= ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR;    
        //}
        Datetime dt = System.now();
        String formattedDate = dt.format('yyyy-MM-dd');
        wo.Call_Date__c = formattedDate;
    if(jsonParser != null && wo.WO_Member_Phone_Number__c!=jsonParser.ContactInformation?.telephoneNumber){
            wo.WO_Member_Phone_Number__c=jsonParser.ContactInformation?.telephoneNumber;
        }
        if(jsonParser.Vehicle != null) {
            wo.Vehicle_Profile__c = String.isNotBlank(jsonParser.Vehicle.color) ? jsonParser.Vehicle.color + ' ' : '';
            wo.Vehicle_Profile__c += String.isNotBlank(jsonParser.Vehicle.year) ? jsonParser.Vehicle.year + ' ' : '';
            wo.Vehicle_Profile__c += String.isNotBlank(jsonParser.Vehicle.make) ? jsonParser.Vehicle.make + ' ' : '';
            wo.Vehicle_Profile__c += String.isNotBlank(jsonParser.Vehicle.model) ? jsonParser.Vehicle.model + ' ' : '';           
            wo.Vehicle_Profile__c += String.isNotBlank(jsonParser.Vehicle.plate) ? jsonParser.Vehicle.plate + ' ' : '';  //EMI
            wo.Flatbed_Requested__c=jsonParser.Vehicle.flatbedRequired;
       
        }
        return wo;
    }
    
    /***
    * Method name        : createMemberVehicle
    * Description        : This method  binds the MemberVehicle fields with request wrapper
    * Param jsonParser   : Request wrapper
    * objAcc             : Account
    * Return Type        : FSL_Member_Vehicle__c 
    */  
    @Testvisible
    private static FSL_Member_Vehicle__c createMemberVehicle(INTFSLWorkOrderRequest_Wrapper jsonParser,Account acc) {
        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();
        memberVehicle.Vehicle_Make__c = jsonParser.Vehicle?.make;
        memberVehicle.Vehicle_Model__c = jsonParser.Vehicle?.model;
        memberVehicle.Vehicle_Year__c = String.valueof(jsonParser.Vehicle?.year);
        memberVehicle.Vehicle_Color__c = jsonParser.Vehicle?.color;
        memberVehicle.Vehicle_Plate__c = jsonParser.Vehicle?.plate;//EMI
        memberVehicle.Name = String.valueof(jsonParser.Vehicle?.year) +' '+ jsonParser.Vehicle?.make+' '+jsonParser.Vehicle?.model+' '+jsonParser.Vehicle?.plate;//EMI
        memberVehicle.ACG_Member__c = (acc != null ? acc.id : null);
        return memberVehicle ;
    }
    
     /***
    * Method name        : createCallComments
    * Description        : This method  binds the FSL Call Comments fields with request wrapper
    * Param jsonParser   : Request wrapper
    * wo_ref             : WorkOrder
    * Return Type        : List of FSL Call comments 
    */  
     @Testvisible
     private static List<FeedItem> createCallComments(list<string> comments, WorkOrder wo_ref) {
        List<FeedItem> callCommentList = new List<FeedItem>();
        for(string comment : comments) {
            if(String.isNotBlank(comment)){
                FeedItem callComment = new FeedItem();
                callComment.Body = comment;
                callComment.ParentId = wo_ref.Id;
                callCommentList.add(callComment);
            }   
        }
        return callCommentList;
    }
    
    @TestVisible
    private static List<FSL_Call_Comments__c> createCallComments(list<string> comments, String woId, String caseId) {
        List<FSL_Call_Comments__c> callCommentList = new  List<FSL_Call_Comments__c>();
        for(string comment : comments) {
            if(String.isNotBlank(comment)){
                FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
                if(String.isNotBlank(woId)){
                    callComment.FSL_Work_Order__c = woId;
                }
                callComment.ACG_Case__c = caseId;
                callComment.FSL_Comment__c = comment;
                callCommentList.add(callComment);
            }   
        }
        return callCommentList;
    }
    
    @future
    @TestVisible
    private static void createCallComments_Future(list<string> comments, String woId, String caseId) {  //AGB 10/15/24 SSFI-469
        system.debug('createCallComments_Future');
        List<FSL_Call_Comments__c> callCommentList = new  List<FSL_Call_Comments__c>();
        for(string comment : comments) {
            if(String.isNotBlank(comment)){
                FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
                if(String.isNotBlank(woId)){
                    callComment.FSL_Work_Order__c = woId;
                }
                callComment.ACG_Case__c = caseId;
                callComment.FSL_Comment__c = comment;
                callCommentList.add(callComment);
            }   
        }
        if(!callCommentList.isempty()){insert callCommentList;}
    } //AGB 10/15/24 SSFI-469
     
      /*
     * Description: This method populates the Work type of the Case.
     * Method Name: getWorkTypeId
     * params: Case Id
    */ 
    @TestVisible
    public static string getWorkTypeId(Id caseId) {
        //Get required Case details 
        Case caseObj = [SELECT  Id,
                                AccountId, ACG_Service_Type__c,ACG_Vehicle_Type__c, Appointment_Requested__c,ACG_Drivetrain__c,ACG_Vehicle_Location_Type__c,
                                BSP_Available__c,
                                Club_Name__c,
                                Enter_Home_during_Lockout__c,ERS_Event_Type__c,Tow_Request_Reason__c,
                                Flat_Tire_Status__c,
                                Gross_Weight__c,
                                Vehicle_Lockout_Reason__c,
                                Vehicle_Fuel_Type__c,Vehicle_Location_City__c,Vehicle_Location_State__c,
                                Special_Equipment_Selection__c,Member_Vehicle_Type__c,Total_Mileage__c
                        FROM Case WHERE Id =:caseId LIMIT 1];
        String retVal;
        //Get Membership level of the associated Member
        List<Account> MemberAccount= [SELECT Id, AAA_Membership_Level__c FROM Account WHERE Id =:caseObj.AccountId];
        String MembershipLevel = MemberAccount.isEmpty() ? NULL : MemberAccount[0].AAA_Membership_Level__c;
      
        //Get all the Active Metadata records                                   
        List<ERS_Case_to_Work_Type_Mapping__mdt> mdtList = [SELECT  Appointment_Requested__c, Priority__c,
                                                                    Breakdown_Location_City__c, Breakdown_Location_State__c, BSP_Available__c,
                                                                    Club__c, Case_to_Work_Type_Mapping_Status__c,
                                                                    Enter_Home_during_Lockout__c,ERS_Event_Type__c,
                                                                    Flat_Tire_Status__c,
                                                                    Gross_Weight__c,
                                                                    Vehicle_Lockout_Reason__c,
                                                                    Member_Needs_Air__c, Membership_Level__c,Tow_Request_Reason__c,
                                                                    Service_Type__c, Special_Equipment_Selection__c,
                                                                    Vehicle_Drivetrain__c, Vehicle_Fuel_Type__c, Vehicle_Type__c,Vehicle_Location_Type__c,
                                                                    Work_Type__c,Total_Mileage__c,
                                                                    T_Code__c,PCC_DISP_CODE__c
                                                           FROM ERS_Case_to_Work_Type_Mapping__mdt
                                                           WHERE Case_to_Work_Type_Mapping_Status__c =:ACG_ConstantsClass.ANNOUNCEMENTS_STATUS
                                                           ORDER BY Priority__c ASC NULLS LAST];
        //If there are Active mappings available
        if(!mdtList.isEmpty()) {
            List<String> lstWorkType = new List<String>();  
                //Search through the metadata records 
            for(ERS_Case_to_Work_Type_Mapping__mdt mdtRec : mdtList){
                if( (mdtRec.Appointment_Requested__c == caseObj.Appointment_Requested__c)
                    &&(mdtRec.Breakdown_Location_City__c == caseObj.Vehicle_Location_City__c    || mdtRec.Breakdown_Location_City__c == NULL)
                    &&(mdtRec.Breakdown_Location_State__c == caseObj.Vehicle_Location_State__c  || mdtRec.Breakdown_Location_State__c == NULL)
                    &&(mdtRec.BSP_Available__c == caseObj.BSP_Available__c              || mdtRec.BSP_Available__c == NULL)
                    &&(mdtRec.Club__c == caseObj.Club_Name__c                           || mdtRec.Club__c == NULL)
                    &&(mdtRec.Enter_Home_during_Lockout__c == caseObj.Enter_Home_during_Lockout__c  || mdtRec.Enter_Home_during_Lockout__c == NULL)
                    &&(mdtRec.ERS_Event_Type__c == caseObj.ERS_Event_Type__c            || mdtRec.ERS_Event_Type__c ==NULL) 
                    &&(mdtRec.Flat_Tire_Status__c == caseObj.Flat_Tire_Status__c        || mdtRec.Flat_Tire_Status__c == NULL)
                    &&(mdtRec.Gross_Weight__c == caseobj.Gross_Weight__c                || mdtRec.Gross_Weight__c == NULL)
                    &&(mdtRec.Vehicle_Lockout_Reason__c == caseObj.Vehicle_Lockout_Reason__c    || mdtRec.Vehicle_Lockout_Reason__c == NULL)
                    &&(mdtRec.Membership_Level__c == MembershipLevel                    || mdtRec.Membership_Level__c == NULL)
                    &&(mdtRec.Service_Type__c == caseobj.ACG_Service_Type__c            || mdtRec.Service_Type__c == NULL)   
                    &&((caseObj.Special_Equipment_Selection__c!= NULL 
                        && mdtRec.Special_Equipment_Selection__c != NULL
                        && caseObj.Special_Equipment_Selection__c.containsIgnoreCase(mdtRec.Special_Equipment_Selection__c)) || mdtRec.Special_Equipment_Selection__c == NULL)
                    &&((caseObj.Total_Mileage__c!= NULL 
                        && mdtRec.Total_Mileage__c != NULL
                        && caseObj.Total_Mileage__c >= mdtRec.Total_Mileage__c )        || mdtRec.Total_Mileage__c == NULL)
                    &&(mdtRec.Vehicle_Drivetrain__c == caseObj.ACG_Drivetrain__c        || mdtRec.Vehicle_Drivetrain__c == NULL)    
                    &&(mdtRec.Vehicle_Fuel_Type__c ==caseObj.Vehicle_Fuel_Type__c       || mdtRec.Vehicle_Fuel_Type__c == NULL)
                    &&(mdtRec.Vehicle_Location_Type__c ==caseObj.ACG_Vehicle_Location_Type__c || mdtRec.Vehicle_Location_Type__c == NULL)
                    &&(mdtRec.Vehicle_Type__c == caseObj.Member_Vehicle_Type__c            || mdtRec.Vehicle_Type__c == NULL)
                    &&(mdtRec.Tow_Request_Reason__c == caseObj.Tow_Request_Reason__c   || mdtRec.Tow_Request_Reason__c == NULL)
                ) {
                    lstWorkType.add(mdtRec.Work_Type__c+'#'+mdtRec.T_Code__c+'#'+mdtRec.PCC_DISP_CODE__c);
                }
            }
            
            //If no WOrk Type was identified from the existing values.
            if(!lstWorkType.isempty()) {
                String[] Concat = lstWorkType[0].split('#');
                List<WorkType> workTypeID = [SELECT Id FROM WorkType WHERE Name=:Concat[0] LIMIT 1];
            
                if(!workTypeID.isEmpty()) {
                    retVal = (workTypeID[0].Id+'#'+concat[1]+'#'+concat[2]);
                    return retVal;
                }
            } else {
                List<WorkType> workTypeID = [SELECT Id,T_Code__C,Trouble_code__C FROM WorkType WHERE Name=:ACG_Constantsclass.LOCKOUT LIMIT 1];
                retVal = (workTypeID[0].Id+'#'+workTypeID[0].T_Code__C+'#'+workTypeID[0].Trouble_code__C);
                return retVal;
            }
        }
        return null;
    }
    
    /*
     * Description: This method identifies the Scheduling Policy based on Priority,ERS event type,WorkType.
     * Method Name: getSchedulePolicy
     * params: worrkOrder
     * 
    */ 
    @TestVisible
    private static ERS_Case_FSL_Priority_Mapping__mdt getSchedpolicy(WorkOrder Wo){
       ERS_Case_FSL_Priority_Mapping__mdt objFSLPriorityMappings = new ERS_Case_FSL_Priority_Mapping__mdt();
       Case cs= new Case();
       cs = [select id,priority,ERS_Event_Type__c,ACG_Work_Type__c from case where id=:wo.caseId];
       List<ERS_Case_FSL_Priority_Mapping__mdt> lstFSLPriorityMappings = [select id,Case_Priority__c,ERS_Event_Type__c,Priority_Description__c,
                                                                          Schedule_over_Lower_Priority_Appointment__c,Scheduling_Policy__c,Work_Order_Priority__c,
                                                                          Work_Type__c from ERS_Case_FSL_Priority_Mapping__mdt where Case_Priority__c =:cs.Priority and 
                                                                         Work_Order_Priority__c=:wo.Priority];
        string strWorktype; 
        if(cs.ACG_Work_Type__c!=null){
        strWorktype=worktypeIdMap.get(cs.ACG_Work_Type__c).Name;
        }
        for(ERS_Case_FSL_Priority_Mapping__mdt pmap: lstFSLPriorityMappings){
            if(pmap.ERS_Event_Type__c!=null && pmap.Work_Type__c!=null 
               && pmap.Work_Type__c == strWorktype && pmap.ERS_Event_Type__c==cs.ERS_Event_Type__c){
                   objFSLPriorityMappings=pmap;
                   //break;
               }
            else if(pmap.ERS_Event_Type__c!=null && pmap.Work_Type__c ==null
                    && pmap.ERS_Event_Type__c==cs.ERS_Event_Type__c) {
                        objFSLPriorityMappings=pmap;
                         break;
                    }
            else if(pmap.Work_Type__c!=null && pmap.ERS_Event_Type__c ==null
                    && pmap.Work_Type__c==strWorktype) {
                        objFSLPriorityMappings=pmap;
                         break;
                    } 
            else if(pmap.Work_Type__c==null && pmap.ERS_Event_Type__c ==null){
                        objFSLPriorityMappings=pmap;
                         break;
            }
        }
        return objFSLPriorityMappings;
    }
    
     /***
    * Method name        : createServiceAppointment
    * Description        : This method  binds the Service Appointment fields with request wrapper
    * Param Subject      : Defines Break down or Tow Appointment
    * wo                 : WorkOrder
    * Return Type        : ServiceAppointment 
    */  
     public static ServiceAppointment createServiceAppointment(String Subject, WorkOrder wo,INTFSLWorkOrderRequest_Wrapper jsonParser) {
        List<Account> lstmemberAccs = new List<Account>();
        Map<Id, FSL__Scheduling_Policy__c> policyMap = new Map<Id, FSL__Scheduling_Policy__c>();
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.id;
        sa.Subject = Subject;
        sa.FSL_Member_Vehicle_Name__c = wo.Vehicle_Profile__c;
        sa.Work_Order__c = wo.id;
        sa.Member_Account__c = wo.Member_Account__c;
        lstmemberAccs = [select id,personcontactId from account where id=:wo.Member_Account__c and ispersonaccount=true];
         if(!lstmemberAccs.isempty()){
             sa.ContactId = lstmemberAccs[0].personcontactId;
         }
        sa.ServiceTerritoryId = wo.ServiceTerritoryId;
        sa.Original_Service_Territory__c = wo.ServiceTerritoryId;
        if(sa.ServiceTerritoryId == null) {
            sa.FSL__InJeopardyReason__c = ACG_ConstantsClass.NO_LAT_LONG;
            sa.FSL__InJeopardy__c = true;
        }
        if(!wo.is_Tow_WorkType__c){ 
            sa.FSL_IsLight_Service__c = true;
        }        
        sa.Work_Order_Priority__c = wo.Priority;

        ERS_Case_FSL_Priority_Mapping__mdt objFSLmap = getSchedpolicy(wo);
        FSL__Scheduling_Policy__c schedPolicy = new FSL__Scheduling_Policy__c();
        if(objFSLmap.Scheduling_Policy__c!=null){
        schedPolicy = [select id, name from FSL__Scheduling_Policy__c where Name =:objFSLmap.Scheduling_Policy__c order by createddate desc limit 1];
        sa.FSL__Scheduling_Policy_Used__c = schedPolicy.Id;
        sa.FSL__Schedule_over_lower_priority_appointment__c = objFSLmap.Schedule_over_Lower_Priority_Appointment__c;
        } else{
        schedPolicy = [select id, name from FSL__Scheduling_Policy__c where Name =:label.INT_ERS_BLENDED_POLICY order by createddate desc limit 1];
        sa.FSL__Scheduling_Policy_Used__c = schedPolicy.Id;
        }
        
        sa.EarliestStartTime = System.now();
         if(jsonparser != null && jsonparser.SlotStartDateTime != null && jsonparser.SlotStartDateTime != '' && jsonparser.SlotEndDateTime != null && jsonparser.SlotEndDateTime != '') {
            //VBR
            //  sa.ArrivalWindowStartTime = Datetime.valueOfGMT(jsonparser.SlotStartDateTime);
            //  sa.ArrivalWindowEndTime = Datetime.valueOfGMT(jsonparser.SlotEndDateTime);
            //  schedPolicy = [select id, name from FSL__Scheduling_Policy__c where Name =: system.label.FUTURE_APPOINTMENTS order by createddate desc limit 1];
            //  sa.FSL__Scheduling_Policy_Used__c = schedPolicy.Id;
            //  sa.DueDate = sa.EarliestStartTime.addhours(Integer.valueOf(system.label.FUTURE_APPOINTMENT_DD_DURATION));
            //  sa.Work_Order_Priority__c=system.label.SA_WORKORDER_PRIORITY;
         } else if(jsonparser == null && wo.ACG_Requested_Appointment_Date__c != null && wo.ACG_Requested_Appointment_Time__c!= null){
            //VBR
            //  string concatReqDateTime = wo.ACG_Requested_Appointment_Date__c.format() + ' ' + wo.ACG_Requested_Appointment_Time__c;
            //  string requestedDateTimeVal = concatReqDateTime.replace('00:00:00', '');
            //  DateTime dt = DateTime.parse(requestedDateTimeVal); 
            //  DateTime dueDateValWithMinutes = dt.addMinutes(15);
            //  string dueDateValWithMinutesStr = dueDateValWithMinutes.format();
            //  string currentDateTime = DateTime.now().format();
            //  DateTime dueDateVal = DateTime.now().addDays(3);
            //  string dueDateStr = dueDateVal.format();
             
            //  sa.EarliestStartTime = DateTime.parse(currentDateTime);
            //  sa.dueDate = DateTime.parse(dueDateStr);
            //  sa.ArrivalWindowStartTime = DateTime.parse(requestedDateTimeVal);
            // sa.ArrivalWindowEndTime = DateTime.parse(dueDateValWithMinutesStr);
         } else {
             policyMap.put(schedPolicy.Id, schedPolicy);
             // FIXME: Commented out Deloitte/ACG code. Integrate with ACE's scheduling engine if neeeded
             /*slaWrapUsed = FSL_SchedulingUtility.populateArrivalWindowAndPolicy(sa, wo, policyMap);
             retrySchedPolicy=slaWrapUsed.reTrySchedulingPolicy;*/
         }
         
        return sa;
    }

    /***
    * Method name        : createAppointmentDependency
    * Description        : This method  binds the FSL Appointment Dependency fields with request wrapper
    * Return Type        : FSL__Time_Dependency__c 
    */    
     public static FSL__Time_Dependency__c createAppointmentDependency(ServiceAppointment breakdownSA, ServiceAppointment towSA) {
        FSL__Time_Dependency__c appointmentDependency = new FSL__Time_Dependency__c();
        appointmentDependency.FSL__Root_Service_Appointment__c = breakdownSA.id;
        appointmentDependency.FSL__Service_Appointment_1__c = towSA.id;
        appointmentDependency.FSL__Service_Appointment_2__c = breakdownSA.id;
        appointmentDependency.FSL__Same_Resource__c = true;
        appointmentDependency.FSL__Dependency__c = ACG_ConstantsClass.IMMEDIATELY_FOLLOW;
        return appointmentDependency;
    }
    
    /***
    * Method name        : towAddressLoader
    * Description        : This method  binds the Service Appointment tow address fields with request wrapper
    * Param sa           : Service Appointment
    * wo                 : WorkOrder
    */  
    public static void towAddressLoader(ServiceAppointment sa, WorkOrder wo) {
        Id towRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
        sa.recordTypeId = towRecordTypeId;
        sa.Latitude = wo.Tow_Location__Latitude__s;
        sa.Longitude = wo.Tow_Location__Longitude__s;
        sa.Street = wo.Tow_Street__c;
        sa.City = wo.Tow_City__c;
        if(wo.Tow_State__c!=null && wo.Tow_State__c.length()==2){
            sa.statecode = wo.Tow_State__c;
        } else{
            sa.State = wo.Tow_State__c;
        }
        sa.PostalCode = wo.Tow_Postal_Code__c;
        sa.Countrycode = ACG_ConstantsClass.US;
        sa.Cross_Street__c = wo.Tow_Cross_Street__c;
        sa.Tow_Destination_Name__c = wo.Tow_Destination_Name__c;
    }
    
    /***
    * Method name        : breakdownAddressLoader
    * Description        : This method  binds the Service Appointment Breakdown address fields with request wrapper
    * Param sa           : Service Appointment
    * wo                 : WorkOrder
    */  
    public static void breakdownAddressLoader(ServiceAppointment sa, WorkOrder wo) {
        Id breakdownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        sa.recordTypeId = breakdownRecordTypeId;
        sa.Street = wo.Street;
        sa.City = wo.City;
        if(wo.state!=null){
        sa.State = wo.State;
        }else if(wo.statecode!=null){
         sa.statecode = wo.statecode;
        }
        sa.PostalCode = wo.PostalCode;
        sa.Countrycode = ACG_ConstantsClass.US;
        sa.Latitude = wo.Latitude;
        sa.Longitude = wo.Longitude;
        sa.Cross_Street__c = wo.Cross_Street__c;
    }
    
    /***
    * Method name        : scheduleCall
    * Description        : This method enqueues FSL scheducling method
    * Param breakdownsa  : Service Appointment
    * towsa              : Service Appointment
    */  
    public static void scheduleCall(ServiceAppointment breakdownsa,ServiceAppointment towsa){
        FSL__Scheduling_Policy__c schedPolicy = new FSL__Scheduling_Policy__c();
        FSL__Scheduling_Policy__c oRetrySchedPolicy = new FSL__Scheduling_Policy__c();
        if(breakdownsa.FSL__Scheduling_Policy_Used__c !=null) {
            schedPolicy = [select id, name from FSL__Scheduling_Policy__c where Id =:breakdownsa.FSL__Scheduling_Policy_Used__c order by createddate asc limit 1];
            if(string.isNotEmpty(retrySchedPolicy)){
                oRetrySchedPolicy = [select id, name from FSL__Scheduling_Policy__c where Id =:retrySchedPolicy order by createddate asc limit 1];
            }
        }
        // FIXME: Commented out Deloitte/ACG code. Integrate with ACE's scheduling engine if needed
        /*
        if(towSA!=null&&towSA.id!=null){
        FSL_AppointmentScheduleQueueable appointmentQueueable = new FSL_AppointmentScheduleQueueable(schedPolicy,breakdownsa,towsa, null,oRetrySchedPolicy);
        System.enqueueJob(appointmentQueueable);
        } else{
            FSL_AppointmentScheduleQueueable appointmentQueueable = new FSL_AppointmentScheduleQueueable(schedPolicy,breakdownsa,null, null,oRetrySchedPolicy);
        System.enqueueJob(appointmentQueueable);
        }
        */
    }
    
    /***
    * Method name        : updateServiceAppointment
    * Description        : This method updates the service appointment with selected slot 
    *                      and calls the schedule method. 2022-02-15: Not used as ImmediateAppointment 
    *                       itself will be leveraged by using slotsstarttime and slotsendtime for schedule for later.
    *                      This method is commented till salesforce product team resolves get slots issue, till then Immediate appointment operation will be leveraged.
    * Param workOrderId  : Id of the workOrder
    * startTime          : Selected slot start time
    * endTime            : Selected slot end time */
     
    @TestVisible
    Private static void updateServiceAppointment(Id workOrderId,string startTime,string endTime,INTFSLWorkOrderRequest_Wrapper jsonParser){
        //VBR
        // List<ServiceAppointment> serviceAppointmentList = [SELECT Id, ArrivalWindowStartTime,ArrivalWindowEndTime, DueDate,FSL__Scheduling_Policy_Used__c,serviceTerritoryId,AppointmentNumber,RecordTypeId,FSL__Pinned__c,Work_Order_Priority__c FROM ServiceAppointment 
        //                         WHERE Work_Order__r.id = :workOrderId];
        //     serviceAppointment breakdownAppointment;
        //     serviceAppointment towAppointment;
        //     case cs = new case(Id=jsonparser.CaseId);
        //     if(jsonParser.callType==ACG_ConstantsClass.CALL_ORIGIN_ACG_DRR && jsonparser.comments.size()>0 && jsonparser.CaseId!=null){
        //       cs.ERS_Notes__c = jsonparser.comments[0];
        //       update cs;
        //      }
        //     List<workOrder> lstWO=[select id,WO_Member_Phone_Number__c from workorder where id=:workOrderId];
        //     if(!lstWO.isempty()){
        //         lstWO[0].Is_Draft_Work_Order__c = false;
        //         if(lstWO[0].WO_Member_Phone_Number__c!=jsonParser.ContactInformation?.telephoneNumber){
        //             lstWO[0].WO_Member_Phone_Number__c=jsonParser.ContactInformation?.telephoneNumber;
        //         }
        //         update lstWO[0];
        //         if(cs.ERS_Notes__c!=null && cs.ERS_Notes__c!=''){
        //          ERS_WorkOrderFromCase.createWorkOrderFeedItem(cs,lstWO[0]);     
        //         }
        //     }
        //     for(ServiceAppointment eachServiceAppointment : serviceAppointmentList){
        //            eachServiceAppointment.EarliestStartTime = DateTime.now();
        //         eachServiceAppointment.DueDate = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day(), 23, 59, 00).addDays(3); 
        //         eachServiceAppointment.FSL__Pinned__c=true;
        //            eachServiceAppointment.Work_Order_Priority__c=ACG_ConstantsClass.SCHEDULED;
        //            if(eachServiceAppointment.RecordTypeId == Schema.sObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId())
        //                 {
        //                     eachServiceAppointment.ArrivalWindowStartTime = Datetime.valueOfGMT(startTime);
        //                     eachServiceAppointment.ArrivalWindowEndTime = Datetime.valueOfGMT(endTime);
        //                     towAppointment=eachServiceAppointment;
        //                 }
        //            else if(eachServiceAppointment.RecordTypeId == Schema.sObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId())
        //                 {
        //                     eachServiceAppointment.ArrivalWindowStartTime = Datetime.valueOfGMT(startTime);
        //                     eachServiceAppointment.ArrivalWindowEndTime = Datetime.valueOfGMT(endTime);
        //                     breakdownAppointment = eachServiceAppointment;
        //                 }
        //     }
        
        //     if(!serviceAppointmentList.isempty()) {
        //         update serviceAppointmentList;
        //     }
        //     INTFSLWorkorderIntake.schedulecall(breakdownAppointment, towAppointment);
    }
    
    /***
    * Method name        : updateCase
    * Description        : This method updates case asychronously
    * Param strjson      : Request body 
    */  
    @future(Callout=true)
    public static void updateCase(string strjson) {
        INTFSLWorkOrderRequest_Wrapper jsonParser = new INTFSLWorkOrderRequest_Wrapper(); 
        try {
            jsonParser  =  INTFSLWorkOrderRequest_Wrapper.parse(strjson).get(0);    //TODO - needs to be uncommented and handle list of objects            
        } catch(Exception ex) {}
        case objcase =new case();
        Account objAccount = new Account();
        if(jsonParser.CaseId !=null) {
            objcase = [select id,AccountId from case where id=:jsonParser.CaseId];
            if(objcase.AccountId!=null)
                objAccount = [select id from Account where id =:objcase.AccountId];
        }
        objcase = createcase(objAccount,jsonParser);
        update objcase;
    }

    /***
    * Method name        : updateGenesysConversationIdOnCase
    * Description        : This method updates Genesys ConversationId on Case
    * Param strjson      : Request body 
    */  
    public static void updateGenesysConversationIdOnCase(string strjson) {
        INTFSLWorkOrderRequest_Wrapper jsonParser = new INTFSLWorkOrderRequest_Wrapper(); 
        try {
            jsonParser  =  INTFSLWorkOrderRequest_Wrapper.parse(strjson).get(0);          
        } catch(Exception ex) {}
        case objcase =new case();
        if(jsonParser.CaseId !=null) {
            objcase = [select Id,Genesys_ConversationId__c from case where id=:jsonParser.CaseId];
            objcase.Genesys_ConversationId__c = jsonParser.genesysConversationId;
        }
        update objcase;
    }
    /***
    * Method name        : callMover
    * Description        : This method moves the calls to national since it is out of ACG Territory
    * Param CaseId       : Id  of the case
    */ 
    @future(Callout=true)
    public static void callMover(Id CaseId){
        FSL_INTCallMoverOutbound.generateCallMoverRequest(CaseId);
    }
    
    /* Description: 
     * Method Name: createWorkOrderFeedItem
     * params: Case object, WorkOrder object
     */
    @future
    @TestVisible
    public static void createWorkOrderFeedItem_Future(string caseId, string woId){ //AGB 10/15/2024 SSFI-469
        system.debug('createWorkOrderFeedItem_Future');
        Case caseObject = [select Id,Locksmith_Issue__c,ERS_Notes__c,ACG_Service_Type__c from Case where Id = :caseId limit 1];
        
        List<FeedItem> listFeedItem = new List<FeedItem>();

        String feedBodyInfo = '';
        feedBodyInfo = 'Service Type : ' + caseObject.ACG_Service_Type__c;
        if(caseObject.Locksmith_Issue__c != null) {
            //feedBodyInfo = feedBodyInfo != null ? feedBodyInfo + '\n' : feedBodyInfo ;
            feedBodyInfo = feedBodyInfo + ', Key Issue : ' + caseObject.Locksmith_Issue__c;
        }
        if(caseObject.ERS_Notes__c != null) {
            feedBodyInfo = feedBodyInfo + ', Notes Detail : ' + caseObject.ERS_Notes__c;
        }

        FeedItem post1 = new FeedItem();
        post1.ParentId = woId;
        post1.Visibility = 'AllUsers';
        post1.Body = feedBodyInfo;

        listFeedItem.add(post1);
        insert listFeedItem;
    } 
}