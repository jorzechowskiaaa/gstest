/****
 * *@Name: WorkOrderIntake
 * *@Description: Callout class to create workorders when it called from D3.
 * *@Date: 09-27-2018
 * *@Version: 1.0
 * * 
 * * Dylan Truong               09-28-2020   ERS-219581 Timeouts - FSL Changes 
 * * Clement Shiu               12-18-2020   Row Lock fix and custom exception  added
 * * Shankar Krishnan           01-29-2021   Updated Row Lock Error Handling
 * * VarunSharma@salesforce.com 06-08-2023   Changes for person account, service contract and handling of the empty values for expiration date and member since. ((https://salesforce.atlassian.net/browse/PR893288-252/238/242/249))
 * **/
@RestResource(urlMapping='/ProcessWorkOrderIntake/*') 
global without sharing class FSL_WorkOrderIntake {
    // public static String callId {get;set;}   // *** Service Tech Team: variable is used only in local scope  ***
    // public static String version {get;set;}   // *** Service Tech Team: variable is used only in local scope  ***
    // public static final String SUCCESS_MESSAGE = 'Successfully created workorder';   // *** Service Tech Team: variable is used only in local scope  ***
    private static String ERROR_MESSAGE = '';    // *** Service Tech Team: variable is used only in this class, so it should be private  ***
    // public static String WORKORDER_ERROR_MESSAGE = '';   // *** Service Tech Team: variable is used only in local scope  ***
    // public static String TRCODES_ERROR_MESSAGE = '';   // *** Service Tech Team: variable is used only in local scope  ***
    // public Static string WorkOrderId;    // *** Service Tech Team: variable is used only in local scope  ***
    private static String paceSetterTroubleCode;    // *** Service Tech Team: variable is used only in this class, so it should be private  ***
    // private static Boolean contactFound = false;   // *** Service Tech Team: never used variable  ***
    private static String tCode;   // *** Service Tech Team: added a static variable for Work Order creation  ***
    private static Boolean woSmsOptIn = false;
    @testVisible
    public static FSL_Account.IFactory accountFactory = new FSL_Account.Factory();

    
    /**********
     *@Method Name:WorkOrderResponse
     *@Parameters: (JSonParserWorkOrder jsonParser )
     *@Description: This method parses the json request comming from D3 and creates corresponding workorder, contact and trouble code records. 
     **************/
    @TestVisible
    @HttpPost
    global static FSL_WorkOrderResponse UpsertWorkOrder() {
        //Added Line by Raj
        // call handler method to process the work order intake, return result element
        DateTime serviceStartTime = System.now();
        Savepoint sp;
        /*if (!Test.isRunningTest()) { // Changed the sp location as Lookup callout fails if it has any prior DML statements
            sp = Database.setSavepoint();
        }*/
        WorkOrder workOrderRecord;
        String callId;
        String callKey;
        String version;
        String SUCCESS_MESSAGE = 'Successfully created workorder';
        String callOutType;
        String memberShipId;
        

        FSL_WorkOrderResponse res = new FSL_WorkOrderResponse();
        FSL_WorkOrderResponse.HEADER hed = new FSL_WorkOrderResponse.HEADER();
        RestRequest request = RestContext.request; 
        
        try {
            System.debug('request.requestBody.toString()==>'+request.requestBody.toString());
            FSL_JSonParserWorkOrder jsonParser = new FSL_JSonParserWorkOrder();     
            try {
                jsonParser  = (FSL_JSonParserWorkOrder)Json.deserialize(request.requestBody.toString(),FSL_JSonParserWorkOrder.class);                
                hed = new FSL_WorkOrderResponse.HEADER(request.headers);
            } catch(Exception ex) {
                System.debug('Error Caught: ' + ex.getStackTraceString() +' At Line:'+ex.getLineNumber());
                Map<String, Object> results =  (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
                List<Object> lstCalls = (List<Object>)results.get('calls');
                Map<String, Object> customerAttributes = (Map<String, Object>)lstCalls[0];
                callId = (String)customerAttributes.get('callId');
                callKey = (String)customerAttributes.get('callKey');
                version = (String)customerAttributes.get('version');
                callOutType = (String)results.get('requestEventType');
                res.callKey = callKey;
                res.statusCode = '405';
                RestResponse response = RestContext.response;
                response.statusCode = 400;
                res.statusDescription = ex.getStackTraceString();
                res.header = hed;
                ERROR_MESSAGE = ex.getMessage()+' At Line:'+ex.getLineNumber();
                
                FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
                FSL_ApplicationLogCreator.serviceEndTime = System.now();
                FSL_ApplicationLogCreator.insertAplicationLog(request, res, ERROR_MESSAGE, callOutType , true, callId, version, null);
                // *** Service Tech Team: it's better to exit the whole method after unsuccesfull deserializing  ***
                return res;
            }
            //Creating workorder and related records in their respective methods below.
            if (jsonParser.Calls != null && !jsonParser.calls.isEmpty()) {
                callId = jsonParser.calls[0].callId;
                callKey = jsonParser.calls[0].callKey;
                List<WorkOrder> retrieveWO = new List<WorkOrder>();
                if (jsonParser.calls[0].woLookup == true || callKey != null) {
                    if (!Test.isRunningTest()) {
                       // sp = Database.setSavepoint();
                    }
                    retrieveWO = workOrderLookUpByCallKey(callKey);
                }
                if (!retrieveWO.isEmpty()) {
                    workOrderRecord = retrieveWO[0];
                }
                else {
                    version = jsonParser.calls[0].version;
                    WorkOrder workOrder_reference = new WorkOrder(External_Id__c = jsonParser.calls[0].callKey);
                    //Calling createTroubleCodes
                    List<FSL_TroubleCode__c> troubleCodes = createTroubleCodes(jsonParser, workOrder_reference);
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    System.debug(paceSetterTroubleCode);

                    WorkOrder create_workOrder = createWorkOrder(jsonParser);
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

                    Case create_case;
                    
                    // Get Membership Type
                    String membershipType = jsonParser.calls[0]?.customer?.memberships[0].membershipType;
                    string phoneNumber = jsonParser.calls[0]?.customer?.contact?.phones[0]?.phoneNumber;
                    boolean smsOptIn = jsonParser.calls[0]?.customer?.contact?.phones[0]?.smsOptIn;
                    String membershipOrgCode = jsonParser.calls[0]?.customer?.memberships[0].org?.code;
                    // If Type = Member and Member Code = Org Code (In Club Members)
                    // Call Lookup API -> Upsert Person Account -> Upsert Service Contract
                    if(membershipType != null && membershipType == 'MEMBER' && membershipOrgCode == Label.FSL_SourceClubCode){
                        memberShipId = jsonParser.calls[0]?.customer?.memberships[0]?.id; // Get Membership Id - 9 digits or 16 digits
                        if(Label.FSL_SourceClubCode == '240' && memberShipId.length() == 9){
                            memberShipId = Label.FSL_ISO_Code + Label.FSL_SourceClubCode + memberShipId;
                        }
                        Map<String,String> mapRequestParams = new Map<String,String>{
                            'memberId' => memberShipId
                        };
                        ACG_GlobalSearchController.Results gsResults = ACG_GlobalSearchController.invokeMembershipAPIs('lookup', mapRequestParams, 'GUID_API');
                        if(gsResults.isLookupSuccess == true && gsResults.updatedRecordId != null){
                            if (!Test.isRunningTest()) {
                                //sp = Database.setSavepoint();
                            }
                            
                            Account acc = [SELECT PersonContactId,Phone FROM Account WHERE Id = :gsResults.updatedRecordId LIMIT 1];
                            create_workOrder.ContactId = acc.PersonContactId;
                            create_workOrder.Member_Account__c = gsResults.updatedRecordId;
                            create_workOrder.WO_Member_Phone_Number__c = phoneNumber;
                            create_workOrder.SMS_OptIn__c = smsOptIn;
                            woSmsOptIn = smsOptIn;
                            create_case = createWOCase(gsResults.updatedRecordId,create_workOrder.ContactId,callKey);
                            if(gsResults.contract != null){
                                create_workOrder.ServiceContractId = gsResults.contract.contractId;
                            } 
                        }
                    }
                    // If Type = RAP
                    // Call existing methods to create person Accounts and Service contracts
                    else{
                        if (!Test.isRunningTest()) {
                            //sp = Database.setSavepoint();
                        }
                        FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
                        FSL_Account.IAccountService service = accountFactory.createService();
                        
                        FSL_Account.MembershipInformation info = parser.parse( jsonParser.calls[0] );
                        List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );

                        if (!accounts.isEmpty()) {
                            
                            create_workOrder.ContactId = [SELECT PersonContactId FROM Account WHERE Id = :accounts[0].Id].PersonContactId;
                            //create_workOrder.putSObject('Contact', contacts[0]);
                            create_workOrder.Member_Account__c = accounts[0].Id;
                            //create_workOrder.WO_Member_Phone_Number__c = accounts[0].Phone;
                            create_workOrder.WO_Member_Phone_Number__c = phoneNumber;
                            create_workOrder.SMS_OptIn__c = smsOptIn;
                            create_case = createWOCase(accounts[0].Id,create_workOrder.ContactId,callKey);
                        }

                        Datetime callCreateDateTime = DateTime.newInstance(Long.valueOf(jsonParser.createDate)); 
                        if(membershipType != null && membershipType == 'RAP' && membershipOrgCode == Label.FSL_SourceClubCode) {
                            ServiceContract membershipContract = getOrCreateMembershipContract( info, create_workOrder, callCreateDateTime);
                        }
                    }

                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    FSL_WorkOrderIntake.validateWorkOrder('WorkOrder', create_workOrder);
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

                    if (ERROR_MESSAGE.length() > 1) {
                        res.callKey = callKey;
                        res.statusDescription = ERROR_MESSAGE;
                        return res;
                    }

                    //Calling createMemberVehicle
                    FSL_Member_Vehicle__c memberVehicle = createMemberVehicle(jsonParser, workOrder_reference);
                    upsert memberVehicle;
                    if(memberVehicle != null){
                        create_workOrder.Member_Vehicle__c = memberVehicle.Id;
                    }
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                                       
                    //Calling Policy Vehicle
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    FSL_Policy__c policy = createPolicy(jsonParser, workOrder_reference);                
                           
                    // ERS-230370 ACE Service Territory Override, need to call it here after the TroubleCodes and Location, Vehicle Info are there
                    if(create_workOrder.ServiceTerritoryId != null){           
                        create_workOrder.ServiceTerritoryId = getServiceTerritoryOverrideId(create_workOrder);                        
                        create_workOrder = checkForTechnologyPrefAndFreeze(create_workOrder);
                    }                              
                    
                    //Creating Case for the incoming Call
                    if(create_case != null && create_case.accountId != null) {
                        //insert Case
                        insert create_case;
                        if(create_case.Id != null) {
                            create_workOrder.CaseId = create_case.Id;
                        }
                    }
                    //Inserting the WorkOrder & TroubleCodes
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

                    System.debug('DMLs before - ' + Limits.getDMLStatements());
                    // List<Database.SaveResult> results = Database.insert(workOrderTroubleCodeList);  //new List<Database.SaveResult>();
                    create_workOrder.Call_Source__c = 'D3';
                    create_workOrder.AAA_Charge_Entitlement__c = true;
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    insert create_workOrder;
                    
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    
                    //  ***  Service Tech Team: child records are important or not ? (safe-operation creation question)
                    
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    insert troubleCodes;
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    memberVehicle.Work_Order__c = create_workOrder.Id;
                    upsert memberVehicle;
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    insert policy;
                
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    // if(jsonParser.calls[0].comments != null) {
                    //     List<FSL_Call_Comments__c> callCommList = createCallComments(jsonParser.calls[0].comments,workOrder_reference);
                    //     if(!callCommList.isEmpty()) {
                    //         insert callCommList;
                    //     }
                    // }

                    createAndInsertCallComments(jsonParser, workOrder_reference);

                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

                    System.debug('DMLs after - ' + Limits.getDMLStatements());
                    
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    
                    //Code to temporarily get Work order id  
                    // string resString = string.Valueof(results);
                    // system.debug('results:'+resString);
                    // WorkOrderId = resString.mid(resString.indexOf('0WO'), 18); // create_workOrder.Id; 
                    // system.debug('WorkOrderId:'+WorkOrderId);

                    // List<FSL_Service_Line_Item__c> serviceList = new List<FSL_Service_Line_Item__c>();
                    // if (WorkOrderId != null) {                                            
                    workOrderRecord = [
                        SELECT Id, WorkOrderNumber, D3_Tow_Mileage__c, ServiceTerritory.OperatingHours.Timezone, ServiceTerritory.Facility_Number__c, Call_Source__c 
                        FROM WorkOrder
                        WHERE Id = :create_workOrder.Id
                    ];
                    create_workOrder.ServiceTerritoryId = workOrderRecord.ServiceTerritoryId;
        
                    create_workOrder.putSObject('ServiceTerritory', workOrderRecord.ServiceTerritory);
                    
                    system.debug('@@@@@@@TowMileage@@@@@@@@'+workOrderRecord.D3_Tow_Mileage__c);
            /*        if (workOrderRecord.D3_Tow_Mileage__c != null) {   
                        FSL_ServiceLineItem.IServiceLineItemService serviceLineItem = new FSL_ServiceLineItem.Factory().createService();
                        FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService CMLineItem = new FSL_CalculatedMileageLineItem.Factory().createService();
                        System.debug('@@@@@@@@@@@@@@@Tow TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                        serviceLineItem.createServiceLineItem(workOrderRecord.Id, workOrderRecord.D3_Tow_Mileage__c.intValue(), 'TW - TOW MILEAGE');
                        CMLineItem.createCalculatedMileageLineItem(workOrderRecord.Id, workOrderRecord.D3_Tow_Mileage__c.intValue(), 'CT - Calculated Tow');
                        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    } else if(create_workOrder.Is_Tow_WorkType__c) {

                        createCMLIWithMileage(workOrderRecord.id, 
                                             'CT - Calculated Tow',
                                             Double.valueOf(create_workOrder.Breakdown_Location__Latitude__s), 
                                             Double.valueOf(create_workOrder.Breakdown_Location__Longitude__s), 
                                             Double.valueOf(create_workOrder.Tow_Location__Latitude__s), 
                                             Double.valueOf(create_workOrder.Tow_Location__Longitude__s));

                        /*createSLIWithMileage(workOrderRecord.id, 
                                            'TW - TOW MILEAGE',
                                            Double.valueOf(create_workOrder.Breakdown_Location__Latitude__s), 
                                            Double.valueOf(create_workOrder.Breakdown_Location__Longitude__s), 
                                            Double.valueOf(create_workOrder.Tow_Location__Latitude__s), 
                                            Double.valueOf(create_workOrder.Tow_Location__Longitude__s));*/                                      
                //    }  */                     

                    // }
                   
                    //      *** Service Tech Team: logic commented out below is moved to createAndInsertResourcePreferences()-method

                    // List<ResourcePreference> rpList = new List<ResourcePreference>();
                    // Set<ID> serviceResourceIDSet = new Set<ID>();
                    // try{
                    //     System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

                    //     // Landline Calls are not assigned, therefore Preferences are not needed
                    //     Technology_Preference__c techPref = FSL_SchedulingUtility.checkForTechnologyPreference(create_workOrder.ServiceTerritoryId);
                    //     if (techPref == null || techPref.Technology_Type__c != 'Landline') {
                    //         // Create Excluded Resource Preference Records for Critical Work Orders
                    //         List<ResourcePreference> excludedResourcesForCriticalCall = new List<ResourcePreference>();
                    //         excludedResourcesForCriticalCall = FSL_SchedulingUtility.getActiveResourcesInSpottedTerritory(create_workOrder);
                    //         if (!excludedResourcesForCriticalCall.isEmpty()) {
                    //             rpList.addAll(excludedResourcesForCriticalCall);
                    //             for (ResourcePreference rp : excludedResourcesForCriticalCall) {
                    //                 serviceResourceIDSet.add(rp.ServiceResourceId);
                    //             }
                    //         }                    
                            
                    //         // Create Resource Preferences based on Intake infor
                    //         if (jsonParser.calls[0].service.facility.preferenceType != null) {                                    
                    //             String territId = create_workOrder.ServiceTerritoryId;
                    //             List<ResourcePreference> resourcePreferencesFromIntake = new List<ResourcePreference>();
                    //             resourcePreferencesFromIntake = FSL_SchedulingUtility.addResourcePreferencesBasedOnPrefType(create_workOrder.Id, jsonParser.calls[0].service.facility.preferenceType, territId, serviceResourceIDSet);
                    //             if (!resourcePreferencesFromIntake.isEmpty()) {
                    //                 rpList.addAll(resourcePreferencesFromIntake);
                    //             }                                    
                    //         }
                    //     }

                    //     if (!rpList.isEmpty()) {
                    //         System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    //         insert rpList;
                    //         System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    //     }
                    // }
                    // catch(Exception ex){//Ignore
                    //     system.debug('Error Caught: ' + ex.getStackTraceString() +' At Line:'+ex.getLineNumber());
                    // }

                    createAndInsertResourcePreferences(jsonParser, create_workOrder);

                    //      ***  End Refactoring  ***

                    //Create and Schedule Service Appointment(s) 
                    List<WorkOrder> woList = new List<WorkOrder>();
                    woList.add(create_workOrder);
                    System.debug('Time before SA insert - ' + Datetime.now());  //  *** Service Tech Team debug ***
                    FSL_AppointmentDependencyHelper.createAndScheduleServiceAppointments(woList.get(0), jsonParser);
                    System.debug('Time after SA insert - ' + Datetime.now());  //  *** Service Tech Team debug ***
                }//Dylan Change    
            }

            // WorkOrder woOrder = [SELECT Id, WorkOrderNumber from WorkOrder where Id = :WorkOrderId];            
            FSL_JSonParserWorkOrder.SourceSystem jsonSource = jsonParser.sourceSystem;
            res.callKey = callKey;
            res.statusCode = '200';
            res.statusDescription = SUCCESS_MESSAGE +' '+ 'Created work order number :' + workOrderRecord.WorkOrderNumber;
            res.workOrderNumber = workOrderRecord.WorkOrderNumber;            
            res.header = hed;
                        
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = System.now();
            String birthdayMasked = request.requestBody.toString().replace('"memberBirthday": "[0-9]-[]-[]"','"memberBirthday": "XXXX-XX-XX"');
            FSL_ApplicationLogCreator.insertAplicationLog(request, res, SUCCESS_MESSAGE, 'CallCreate', false, callId, version, workOrderRecord);        
        }
        catch(Exception e) {
            if (!Test.isRunningTest()) {
                //Database.rollback(sp);
            }
            System.debug('Error Caught: ' + e.getStackTraceString() +' At Line:'+e.getLineNumber());
            //ERS-220606: Catch the custom Row Lock Error here
            if (e instanceof FSL_CustomExceptions.ExclusiveRowLockException) {
                res.statusCode = '409';                
                RestResponse response = RestContext.response;
                response.statusCode = 400;
                ERROR_MESSAGE = 'Row Lock Error Detected: Status Code = 409\n';                
            }
            else if(e.getMessage().contains('DUPLICATE_EXTERNAL_ID')) {
                    List<WorkOrder> woOrder = workOrderLookUp(callId);
                    System.debug('Value of woOrder: ' + woOrder);
                    if (!woOrder.isEmpty()) {
                        res.statusCode = '200';
                        res.callKey = callKey;
                        res.statusDescription = SUCCESS_MESSAGE +' '+ 'Retrieved work order number :' + woOrder[0].WorkOrderNumber;
                        res.workOrderNumber = woOrder[0].WorkOrderNumber;       
                        res.header = hed;

//                        RestResponse response2 = RestContext.response;
//                        response2.statusCode = 400;

                        FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
                        FSL_ApplicationLogCreator.serviceEndTime = System.now();
                        String birthdayMasked = request.requestBody.toString().replace('"memberBirthday": "[0-9]-[]-[]"','"memberBirthday": "XXXX-XX-XX"');
                        FSL_ApplicationLogCreator.insertAplicationLog(request, res, SUCCESS_MESSAGE, 'CallCreate', false, callId, version, woOrder[0]);
                        return res;
                    }
                    else {
                        res.statusCode = '406';
                        RestResponse response = RestContext.response;
                        response.statusCode = 400;
                }
            } else {
                res.statusCode = '407';
                RestResponse response = RestContext.response;
                response.statusCode = 400;
            }

            res.callKey = callKey;
            res.statusDescription = e.getTypeName()+' '+e.getmessage();
            res.header = hed;
            ERROR_MESSAGE = ERROR_MESSAGE + e.getStackTraceString() +' At Line:'+ e.getLineNumber();
            
            //Create Application log here
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = System.now();
            FSL_ApplicationLogCreator.insertAplicationLog(request, res, ERROR_MESSAGE, 'CallCreate', true, callId, version, null);
        }
        return res; 
    }   
    
    //Varun Code Starts
    
    /**********
    *@Method Name:getOrCreateMembershipContract
    *@Parameters: MembershipInformation info, Work Order for this request, Created Date Time for the Call
    *@Description: Method is to set workorder data from JSON request which comming from D3. 
    **************/    
    @TestVisible
    private static ServiceContract getOrCreateMembershipContract(FSL_Account.MembershipInformation info, WorkOrder workOrder,Datetime callCreateDateTime) {
        //System.Debug('****VARUN::getOrCreateMembershipContract::info::' + info);
        //System.Debug('****VARUN::getOrCreateMembershipContract::workOrder::' + workOrder);
        //System.Debug('****VARUN::getOrCreateMembershipContract::callCreateDateTime::' + callCreateDateTime);
        
        List<ServiceContract> allServiceContracts = new List<ServiceContract>();
        ServiceContract memberContract;
        ServiceContract parentMembership ;
        Boolean isCreateMainServiceContract = false;
        Boolean isCreateParentServiceContract = false;
        string membershipType;
        string membership16DigitID;
        string membershipHouseholdID;
        
        try{
            membershipType           = string.isNotBlank(info.membershipType) ? info.membershipType : '';
            membership16DigitID      = string.isNotBlank(info.membershipNumber) ? info.membershipNumber : '';            

            if ( (new List<string> {'MEMBER','RAP'}).contains(membershipType) && membership16DigitID.length()>0 ){                
                
                // Create service contract in case of Member and RAP only
                isCreateMainServiceContract = true;

                // If we have a member then we shall also check for the parent service contract (House hold service contract)
                if(membershipType == 'MEMBER'){
                    isCreateParentServiceContract = true;
                    if(membership16DigitID.length()>=16){
                        membershipHouseholdID = info.membershipNumber.mid(6,7);
                    }
                    else {
                        membershipHouseholdID = info.membershipNumber;
                    }
                }                
            }
            //System.Debug('****VARUN::getOrCreateMembershipContract::isCreateMainServiceContract::' + isCreateMainServiceContract);
            
            //System.Debug('****VARUN::getOrCreateMembershipContract::Searching for Existing Contract.');
            List<ServiceContract> foundContracts = getContractByMembership16ID(info.membershipNumber);
            
            if(foundContracts != null && !foundContracts.isEmpty()){
                //System.Debug('****VARUN::getOrCreateMembershipContract:: Found an Existing Contract.');
                // If an existing service memberhip contract found then return the same else we try to create new service membership contract 
                memberContract = foundContracts[0];
                
                ServiceContract tempMemberContract = new ServiceContract();                
                //Create a temporary service contract with input values
                UpdateStartEndDateOnContract(tempMemberContract, info.memberSince, info.expirationDate);
                
                //Check if the value have changed and there is a need for an update.
                if(isServiceConrtactUpdateRequired(memberContract, tempMemberContract)){
                    memberContract.StartDate                            = tempMemberContract.StartDate;
                    memberContract.EndDate                              = tempMemberContract.EndDate;
                    memberContract.AAA_ACA_Member_Status__c             = tempMemberContract.AAA_ACA_Member_Status__c;
                    memberContract.AAA_ACA_Membership_Status__c         = tempMemberContract.AAA_ACA_Membership_Status__c;
                    memberContract.AAA_ACA_Membership_Coverage_Level__c = tempMemberContract.AAA_ACA_Membership_Coverage_Level__c;
                    allServiceContracts.add(memberContract);                    
                }
                workOrder.ServiceContractId = memberContract.ID;
                //System.Debug('****VARUN::getOrCreateMembershipContract::Existing Contract Found.' + memberContract);
            }else{
                //System.Debug('****VARUN::getOrCreateMembershipContract::NO Existing Contract found. Proceeding to create a new one');                
                if(isCreateMainServiceContract) {
                    //System.Debug('****VARUN::getOrCreateMembershipContract::membershipType::' + membershipType);
                    //System.Debug('****VARUN::getOrCreateMembershipContract::workOrder.ContactId::' + workOrder.ContactId);
                    
                    //For all RAP and Members create a service contract and associate that the Person Acccount            
                    //System.Debug('****VARUN::getOrCreateMembershipContract::START CREATING Main Service Contract');                
                    
                    memberContract = createNewServiceContract(info, membershipType, workOrder.Member_Account__c, callCreateDateTime);
                    //System.Debug('****VARUN::getOrCreateMembershipContract::Main Service Contract::' + memberContract);

                    //System.Debug('****VARUN::UpsertWorkOrder:: END CREATING Main Service Contract');
                    
                    // Add new service contract to the master list to create
                    allServiceContracts.add(memberContract);
                    //System.Debug('****VARUN::getOrCreateMembershipContract::allServiceContracts.Size()::' + allServiceContracts.Size() + allServiceContracts);
                }
            }
            // If its not a RAP then try to associate it to the parent and create parent record (if required).                
            if(memberContract != null && isCreateParentServiceContract){
                // Get parent membership details
                //System.Debug('****VARUN::UpsertWorkOrder:: START CREATING Parent Service Contract::');
                //parentMembership = createOrGetParentServiceContract(info.membershipNumber.mid(6,7));
                parentMembership = createOrGetParentServiceContract(membershipHouseholdID);
                
                // For the house hold, we shall populate the start and finish from whatever information we have so far.                        

                // Either we ger request from an associte membership and we create a parent service contract then the start date is null and we shall populate it with best values from the associate membership 
                // If we get the primary member call first or at later point, we shall try to update the values from Primary membership on the household membership parent service contract
                boolean updatedParentConrtact = false;

                if(memberContract.AAA_ACA_Membership_Type__c == 'Primary'){
                    //System.Debug('****VARUN::getOrCreateMembershipContract::memberContract.AAA_ACA_Membership_Type__c::' + memberContract.AAA_ACA_Membership_Type__c);
                    //System.Debug('****VARUN::getOrCreateMembershipContract::parentMembership.StartDate::' + parentMembership.StartDate + ' ,parentMembership.EndDate::' + parentMembership.EndDate);
                    //System.Debug('****VARUN::getOrCreateMembershipContract::memberContract.StartDate::' + memberContract.StartDate + ' ,memberContract.EndDate::' + memberContract.EndDate);
                    
                    // check if are not updating same value with same value
                    if(parentMembership.StartDate != memberContract.StartDate && parentMembership.EndDate != memberContract.EndDate){
                        parentMembership.StartDate  = memberContract.StartDate;
                        parentMembership.EndDate    = memberContract.EndDate;
                        updatedParentConrtact       = true;
                        //System.Debug('****VARUN::UpsertWorkOrder:: Update Required on the Parent Service Contract::' + parentMembership + ' ,updatedParentConrtact::' + updatedParentConrtact);
                    }
                }
            
                // We shall upsert parent only if the parent has been created now OR there is an update on the record
                if(parentMembership.Id == null || updatedParentConrtact){
                    allServiceContracts.add(parentMembership);
                }
                //System.Debug('****VARUN::UpsertWorkOrder:: FINISHED CREATING Parent Service Contract::' + parentMembership);
            }                    
                
            if(!allServiceContracts.isEmpty()){
                //System.Debug('****VARUN::UpsertWorkOrder::Service Contracts Eligible for update. Starting to insert allServiceContracts');
                upsert allServiceContracts;
                workOrder.ServiceContractId = memberContract.ID;
                if(parentMembership!=null && memberContract.parentServiceContractId == null){
                    //System.Debug('****VARUN::UpsertWorkOrder::Updating Parent Service Contract on the main contract.');
                    memberContract.parentServiceContractId = parentMembership.ID;
                    upsert memberContract;
                }
                //System.Debug('****VARUN::UpsertWorkOrder::Finished inserting allServiceContracts');
            }           
            
            // for(ServiceContract membership: allServiceContracts){
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::ID::' + membership.ID);               
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_Membership_Type__c::' + membership.AAA_ACA_Membership_Type__c);
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_Membership16ID__c::' + membership.AAA_ACA_Membership16ID__c);
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_ISO_Code__c::' + membership.AAA_ACA_ISO_Code__c);
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_Club_Code__c::' + membership.AAA_ACA_Club_Code__c);
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_MembershipID__c::' + membership.AAA_ACA_MembershipID__c );
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_AssociateID__c::' + membership.AAA_ACA_AssociateID__c);
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::AAA_ACA_Check_Digit__c::' + membership.AAA_ACA_Check_Digit__c );  
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::StartDate::' + membership.StartDate );  
            //     System.Debug('****VARUN::UpsertWorkOrder::Service Contract::EndDate::' + membership.EndDate );  
            //     System.Debug('****VARUN::UpsertWorkOrder::Parent Service Contract::parentServiceContractId::' + membership.parentServiceContractId );                 
            // }
        }
        catch(exception exp){system.debug(String.format('Exception type caught::{0},Message::{1}, Cause::{2}, Line Number::{3}, Stack Trace::{4}', new List<object> { exp.getTypeName(), exp.getMessage(),exp.getCause(), exp.getLineNumber(),exp.getStackTraceString()}));throw exp;} 
        return memberContract;
    }
    
    /**********
    * @Method Name:createNewServiceContract
    *@Parameters: MembershipInformation info, Member Type, Person Contact for this service contract, Created Date Time for the Call
    *@Description: Method to create a new service contract for elgible work orders as per jira story https://salesforce.atlassian.net/browse/PR893288-252
    **************/ 
    @TestVisible
    private static ServiceContract createNewServiceContract(FSL_Account.MembershipInformation info, string memberType, string contactID, Datetime callCreateDateTime){
        //System.Debug('****VARUN::createNewServiceContract::info::' + info);
        //System.Debug('****VARUN::createNewServiceContract::memberType::' + memberType);
        //System.Debug('****VARUN::createNewServiceContract::contactID::' + contactID);
        
        ServiceContract newMemberContract = new ServiceContract();
        
        string membership16DigitID = null;
        string membershipHouseholdID = null;
        string CONST_RAP    = 'RAP';
        string CONST_MEMBER = 'MEMBER';

        try{
            if(info!=null && String.isNotEmpty(info.membershipNumber)){
                // Membership 16 Digit ID
                membership16DigitID = info.membershipNumber;
                
                // If the memership number is 16 digit then take out the house hold membership ID else consider it as full in case of RAP
                if(info.membershipNumber.length() >= 16){
                    membershipHouseholdID = info.membershipNumber.mid(6,7);
                }else{
                    // In case of RAP lets use complete value if less than 16 digits
                    membershipHouseholdID = info.membershipNumber;
                }
                //System.Debug('****VARUN::createNewServiceContract::membershipHouseholdID::' + membershipHouseholdID);
                
                //System.Debug('****VARUN::createNewServiceContract::Start Creating Non Member Membership.');
                if(String.isNotBlank(membership16DigitID)){
                    //In the json payload the 16 digit membership id is membership.id (ISO = 3 / Club Code = 3 / Member Id = 7 / Assoc Member Id = 2 / Check Digit = 1
                    //Example: If membership.id = 4382121353733003, then Household Member ID = 1353733
                    //string membershipID = info.membershipNumber;
                    newMemberContract.AAA_ACA_MembershipID__c                   = membershipHouseholdID;                    
                    newMemberContract.AAA_ACA_Membership16ID__c                 = info.membershipNumber;

                    // Set the values if this is RAP
                    if(memberType.equalsIgnoreCase(CONST_RAP)){
                        newMemberContract.AAA_ACA_Membership_Type__c            = info.membershipType;
                        newMemberContract.Name                                  = membershipHouseholdID + '-' + CONST_RAP;
                        newMemberContract.AAA_ACA_RAP_ID__c                     = info.membershipNumber;
                        newMemberContract.AAA_ACA_RAP_Program__c                = info.program;
                        newMemberContract.AAA_ACA_RAP_Sponsor__c                = info.sponsor;                             
                        newMemberContract.StartDate                             = callCreateDateTime.date();
                        newMemberContract.EndDate                               = newMemberContract.StartDate.AddDays(1);                    
                    }else{
                        // Set the value for Member Service Contract
                        newMemberContract.AAA_ACA_ISO_Code__c                   = (info.membershipNumber.length() >= 3) ? info.membershipNumber.mid(0,3) :'';
                        newMemberContract.AAA_ACA_Club_Code__c                  = (info.membershipNumber.length() >= 6) ? info.membershipNumber.mid(3,3) :'';
                        newMemberContract.AAA_ACA_AssociateID__c                = (info.membershipNumber.length() >= 15) ? info.membershipNumber.mid(13,2) :'';
                        newMemberContract.AAA_ACA_Check_Digit__c                = (info.membershipNumber.length() >= 16) ? info.membershipNumber.mid(15,1) :'';
                        newMemberContract.AAA_ACA_Member_Status__c              = info.membershipStatus;
                        newMemberContract.AAA_ACA_Membership_Status__c          = info.membershipStatus;
                        newMemberContract.AAA_ACA_Membership_Coverage_Level__c  = info.membershipLevel;
                        newMemberContract.Name                                  = membershipHouseholdID + '-' + newMemberContract.AAA_ACA_AssociateID__c;
                        
                        if(newMemberContract.AAA_ACA_AssociateID__c == '00'){
                            newMemberContract.AAA_ACA_Membership_Type__c = 'Primary';
                        }else{
                            newMemberContract.AAA_ACA_Membership_Type__c = 'Associate';
                        }
                        
                        //System.Debug('****VARUN::createNewServiceContract::info.memberSince::'      + info.memberSince);
                        //System.Debug('****VARUN::createNewServiceContract::info.expirationDate::'   + info.expirationDate);
                        UpdateStartEndDateOnContract(newMemberContract, info.memberSince, info.expirationDate);                            
                    }

                    // In case of Membership Service Contract (Root hosuehold contract), this could be blank
                    if(String.isNotBlank(contactID)){
                        newMemberContract.AccountId     = contactID;
                    }
                }
                //System.Debug('****VARUN::createNewServiceContract::newMemberContract::' + newMemberContract);
                //System.Debug('****VARUN::createNewServiceContract::Finish Creating Non Member Membership.');               
            }
        }
        catch(exception exp){throw exp;}
        return newMemberContract;
    }
    @TestVisible
    private static boolean isServiceConrtactUpdateRequired(ServiceContract oldMemberContract, ServiceContract newMemberContract){
        boolean updateRequired = false;
        try{
            if(oldMemberContract != null && newMemberContract!= null){
                // if(oldMemberContract.AAA_ACA_Membership16ID__c != newMemberContract.AAA_ACA_Membership16ID__c){
                //     updateRequired = true;
                // }

                if(oldMemberContract.AAA_ACA_Membership_Type__c != newMemberContract.AAA_ACA_Membership_Type__c){
                    updateRequired = true;
                }

                if(oldMemberContract.StartDate != newMemberContract.StartDate){
                    updateRequired = true;
                }

                if(oldMemberContract.EndDate != newMemberContract.EndDate){
                    updateRequired = true;
                }

                if(oldMemberContract.AAA_ACA_Member_Status__c != newMemberContract.AAA_ACA_Member_Status__c){
                    updateRequired = true;
                }

                if(oldMemberContract.AAA_ACA_Membership_Status__c != newMemberContract.AAA_ACA_Membership_Status__c){
                    updateRequired = true;
                }

                if(oldMemberContract.AAA_ACA_Membership_Coverage_Level__c != newMemberContract.AAA_ACA_Membership_Coverage_Level__c){
                    updateRequired = true;
                }
            }
        }
        catch(exception exp){system.debug(String.format('Exception type caught::{0},Message::{1}, Cause::{2}, Line Number::{3}, Stack Trace::{4}', new List<object> { exp.getTypeName(), exp.getMessage(),exp.getCause(), exp.getLineNumber(),exp.getStackTraceString()}));throw exp;} 
        //System.Debug('****VARUN::isServiceConrtactUpdateRequired::' + updateRequired);
        return updateRequired;
    }

    
    /**********
    * @Method Name:createOrGetParentServiceContract
    *@Parameters: membershipHouseholdID represents the 7-13 digits of the 16 Digit membership ID
    *@Description: Method to create a new Parent service contract for elgible work orders as per jira story https://salesforce.atlassian.net/browse/PR893288-252
    **************/ 
    @TestVisible
    private static ServiceContract createOrGetParentServiceContract(string membershipHouseholdID){
        string CONST_MEMBER = 'Member';        
        ServiceContract parentMemberContract;
        try{
            if(String.isNotBlank(membershipHouseholdID)){
                List<ServiceContract> foundContracts = getContractByMembershipID(membershipHouseholdID, CONST_MEMBER);
                if(foundContracts.isEmpty()){
                    //System.Debug('****VARUN::createOrGetParentServiceContract:: NO Parent Contract Found. Need to create a new one.');
                    parentMemberContract = new ServiceContract();
                    parentMemberContract.Name                        = membershipHouseholdID;
                    parentMemberContract.AAA_ACA_Membership_Type__c  = CONST_MEMBER;
                    parentMemberContract.AAA_ACA_MembershipID__c     = membershipHouseholdID;            
                }else{
                    //System.Debug('****VARUN::createOrGetParentServiceContract:: Found an Existing Parent Service Contract::');
                    parentMemberContract = foundContracts[0];
                }
            } 
            //System.Debug('****VARUN::createOrGetParentServiceContract:: Parent Service Contract::' + parentMemberContract);
        }
        catch(exception exp){throw exp;} 
        return parentMemberContract;
    }
    
	@TestVisible
    private static void UpdateStartEndDateOnContract(ServiceContract newMemberContract, string memberSince, Date expirationDate){
        try{
            //System.Debug('****VARUN::UpdateStartEndDateOnContract::newMemberContract::' + newMemberContract);
            //System.Debug('****VARUN::UpdateStartEndDateOnContract::memberSince::' + memberSince);
            //System.Debug('****VARUN::UpdateStartEndDateOnContract::expirationDate::' + expirationDate);

            // For new requirement to handle null/empty values for memberSince and expirationDate attriutes            
            // If expiration date is null then set both expiration and memberSince to today/current year.                        
            if(expirationDate == null){                
                //System.Debug('****VARUN::UpdateStartEndDateOnContract::NULL expirationDate::expirationDate::' + expirationDate);
                newMemberContract.StartDate = Date.today();
                newMemberContract.EndDate   = Date.today();
                //System.Debug('****VARUN::UpdateStartEndDateOnContract::newMemberContract.StartDate::' + newMemberContract.StartDate +  ' ,newMemberContract.EndDate::' + newMemberContract.EndDate);
            }
            else{
                // If expiration Date is not null in the D3 Payload, set the value from the payload
                //System.Debug('****VARUN::UpdateStartEndDateOnContract::NOT NULL expirationDate');
                newMemberContract.EndDate = expirationDate;
                //System.Debug('****VARUN::UpdateStartEndDateOnContract::NOT NULL expirationDate::newMemberContract.StartDate::' + newMemberContract.StartDate);

                // if the memberSince is null, the get the value of year from the expirationdate and set it to the memberSince
                if(memberSince == '00' || memberSince == '0' || string.isBlank(memberSince)
                    || (!string.isBlank(memberSince) && memberSince.length() != 4) || 
                    (!string.isBlank(memberSince) && memberSince.length() == 4 && (Integer.valueOf(memberSince) < 1900 || Integer.valueOf(memberSince) > 2100))){
                    //System.Debug('****VARUN::UpdateStartEndDateOnContract::NULL memberSince');
                    newMemberContract.StartDate = newMemberContract.EndDate;
                    //System.Debug('****VARUN::UpdateStartEndDateOnContract::NULL memberSince::newMemberContract.StartDate::' + newMemberContract.StartDate +  ' ,newMemberContract.EndDate::' + newMemberContract.EndDate);
                }
                // It means both the expirationDate and the memberSince had a non empty value
                //If both of them have a value then check if the expiration is in past then the memberSince
                else {
                    // Get the start date based on Year from MemberSince, Day & Month from the ExpirationDate 
                    //System.Debug('****VARUN::UpdateStartEndDateOnContract::NOT NULL memberSince and expirationDate');                    
                    Date calculatedStartDate = Date.newInstance(integer.ValueOf(memberSince), newMemberContract.EndDate.month(), newMemberContract.EndDate.day());
                    
                    // Check if the calculatedStartDate is ahead of expirationDate i.e. calculatedStartDate is 31-Oct-2023 and expirationDate is 30-June-2023
                    // and set the memberSince as expirationDate
                    if(calculatedStartDate > newMemberContract.EndDate){                        
                        newMemberContract.StartDate = newMemberContract.EndDate;
                        //System.Debug('****VARUN::UpdateStartEndDateOnContract::NOT NULL memberSince and expirationDate, calculatedStartDate greater than expirationDate ::newMemberContract.StartDate::' + newMemberContract.StartDate +  ' ,newMemberContract.EndDate::' + newMemberContract.EndDate);
                    }else{
                        newMemberContract.StartDate = calculatedStartDate;
                        //System.Debug('****VARUN::UpdateStartEndDateOnContract::NOT NULL memberSince and expirationDate, calculatedStartDate less than or equal to the expirationDate::newMemberContract.StartDate::' + newMemberContract.StartDate +  ' ,newMemberContract.EndDate::' + newMemberContract.EndDate);
                    }
                }
            }

            ////System.Debug('****VARUN::UpdateStartEndDateOnContract::expirationDate::' + expirationDate);
            
        }
        catch(exception exp){throw exp;}
    }


     /**********
    * @Method Name:getContractByMembership16ID
    *@Parameters: 16 Digit membership ID
    *@Description: Retrieves existing membership with 16 Digit membership ID search
    **************/ 
    @TestVisible    
    private static List<ServiceContract> getContractByMembership16ID(string membershipNumber){
        List<ServiceContract> memberContract ;
        try{
            //System.Debug('****VARUN::getContractByMembership16ID::membershipNumber::' + membershipNumber);
            if(String.isNotBlank(membershipNumber) && membershipNumber != null){
                memberContract = [Select Id, AAA_ACA_Membership_Type__c,AAA_ACA_Membership16ID__c, StartDate, EndDate, AAA_ACA_Member_Status__c, AAA_ACA_Membership_Status__c, AAA_ACA_Membership_Coverage_Level__c from ServiceContract where AAA_ACA_Membership16ID__c =: membershipNumber];           
            } 
            //System.Debug('****VARUN::getContractByMembership16ID::memberContract::' + memberContract?.Size() + ' , ' + memberContract);
        }
        catch(exception exp){throw exp;}
        return memberContract;
    }
        
    /**********
    * @Method Name:getContractByMembership16ID
    *@Parameters: hosueHoldMembershipID represents the 7-13 digits of the 16 Digit membership ID
    *@Description: Retrieves existing house hold membership with hosueHoldMembershipID search
    **************/ 
    @TestVisible
    private static List<ServiceContract> getContractByMembershipID(string hosueHoldMembershipID, string memberType){
        List<ServiceContract> memberContract;
        try{
            //System.Debug('****VARUN::getContractByMembershipID::hosueHoldMembershipID::' + hosueHoldMembershipID + ' ,memberType::' + memberType);            
            if(String.isNotBlank(hosueHoldMembershipID)){
                memberContract = [Select Id, AAA_ACA_Membership_Type__c,AAA_ACA_Membership16ID__c, StartDate, EndDate from ServiceContract where AAA_ACA_MembershipID__c =:hosueHoldMembershipID and AAA_ACA_Membership_Type__c= :memberType];            
            }
            //System.Debug('****VARUN::getContractByMembershipID::Existing memberContract Found Count::' + memberContract?.Size() + ' , ' + memberContract);
        }
        catch(exception exp){throw exp;}
        return memberContract;
    }    
    
    //Varun Code Ends
    
    /**********
     *@Method Name:createWorkOrder
     *@Parameters: (JSonParserWorkOrder jsonParser )
     *@Description: Method is to set workorder data from JSON request which comming from D3. 
     **************/    
    @TestVisible
    private static WorkOrder createWorkOrder(FSL_JSonParserWorkOrder jsonParser) {
        WorkOrder workOrder = new WorkOrder();

        //   ***  Service Tech Team: moved logic to handleParserServiceCallInfo()  ***

        // String ACCOUNT_ERROR_MESSAGE = '';
        // Boolean isAccountFieldsMissing = false;
       
        // //Populating the AccountId in to the WorkOrder
        // List<Account> acc = null;
        // String facilityId = jsonParser.calls[0].service.facility.id;
        // if (String.isBlank(facilityId)) {
        //     facilityId = 'N/A';
        // } else {
        //     acc = [SELECT Id FROM Account WHERE Facility_Id__c = :facilityId LIMIT 1];
        // }

        // if (acc != null && !acc.isEmpty()) {
        //     workOrder.AccountId = acc[0].Id;
        //     //workOrder.Spotted_Facility__c = acc[0].Id;
        // }
        // else {
        //     Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();           
        //     Account newAccount = new Account();
        //     newAccount.Name = jsonParser.calls[0].service.facility.name;
        //     newAccount.Facility_Id__c = facilityId;
        //     newAccount.Facility_Type__c = jsonParser.calls[0].service.facility.foiType;
        //     newAccount.RecordTypeId = accountRecordTypeId;
            
        //     FSL_Required_Fields_Validation__c accountFieldSetting = FSL_Required_Fields_Validation__c.getValues('Account'); 
        //     List<String> accountFields = accountFieldSetting.Fields__c.split(',');
            
        //     for (String field : accountFields) { 
        //         if (newAccount.get(field) != null && newAccount.get(field) == '') {
        //             isAccountFieldsMissing = true;
        //             if (field.contains('__c')) {
        //                 ACCOUNT_ERROR_MESSAGE = field.substring(0, field.indexof('__c')) + ACCOUNT_ERROR_MESSAGE; 
        //             } else {
                        
        //                 ACCOUNT_ERROR_MESSAGE = field + ACCOUNT_ERROR_MESSAGE; 
        //             }
        //         }
        //     }
            
        //     if (isAccountFieldsMissing) {
        //         ERROR_MESSAGE += 'Reqruied Fields are missing on Account: ' + ACCOUNT_ERROR_MESSAGE;
        //         System.debug(isAccountFieldsMissing + '====isAccountFieldsMissing===' + ERROR_MESSAGE);
        //     }
            
        //     System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
        //     insert newAccount;
        //     System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

        //     workOrder.AccountId = newAccount.Id;
        // }
        // System.debug('jsonParser.calls[0].service.facility.preferenceType===>'+jsonParser.calls[0].service.facility.preferenceType);
       
        //  ***  End   ***

        workOrder.External_ID__c = jsonParser.calls[0].callKey;
        workOrder.Call_Id__c = jsonParser.calls[0].callId;
        workOrder.Call_Date__c = jsonParser.calls[0].callDate;
        
        //  *** Service Tech Team: Replace if with the field assignment to reduce method complexity
        
        // if (jsonParser.calls[0].customer.memberships[0].goodwill == 'Y') {
        //     workOrder.Goodwill_Indicator__c = true;
        // } else {
        //    workOrder.Goodwill_Indicator__c = false;
        // }
        workOrder.Goodwill_Indicator__c = (jsonParser.calls[0].customer.memberships[0].goodwill == 'Y');

        //workOrder.Goodwill_Indicator__c = Boolean.valueOf(jsonParser.calls[0].customer.memberships[0].goodwill);
        if (jsonParser.calls[0].Channel != null) {
            workOrder.Call_Origin__c = jsonParser.calls[0].Channel.channelType;
            workOrder.Call_Origin_OrgCode__c = jsonParser.calls[0].Channel.org.code;
            workOrder.Call_Origin_OrgName__c = jsonParser.calls[0].Channel.org.Name;
            workOrder.Responder_ID__c = jsonParser.calls[0].Channel.contact.userId;
        }
        
        //Vehicletype Information
        
        if (jsonParser.calls[0].vehicle.vehicleType != null) {
            workOrder.Vehicle_Type__c = jsonParser.calls[0].vehicle.vehicleType;    
        }   
        workOrder.RAP_Case_Number__c = jsonParser.calls[0].requestingSystemCallId; 
        
        //Service Information
        if (jsonParser.calls[0].service != null) {

            //  ***  Service Tech Team: moved commented out logic to handleParserServiceCallInfo()  ***

            workOrder = handleParserServiceCallInfo(jsonParser, workOrder);

        //     String pCode = jsonParser.calls[0].service.priorityCode;
        //     String legacyPCode = jsonParser.calls[0].service.legacyPriorityCode;
        //     FSL_WorkOrderIntake.populareWorkOrderPriority(workOrder, pCode, legacyPCode);
            
        //     //Add Start date and end date on Work order (For Glympse) 
        //     //workOrder.StartDate = sysytem.Now(); 
        //     //workOrder.EndDate = sysytem.Now(); 
        //     workOrder.Call_Type__c = jsonParser.calls[0].service.callType;
        //     //if(workOrder.Call_Type__c.equals('RAP') && !string.isEmpty(jsonParser.calls[0].customer.memberships[0].id) && jsonParser.calls[0].customer.memberships[0].id.length() <= 8){
        //     //    workOrder.RAP_Case_Number__c = jsonParser.calls[0].customer.memberships[0].id;
        //     //}
        //     workOrder.Timezone_Id__c = jsonParser.calls[0].service.timezoneId;
        //     workOrder.Timezone_Offset__c = jsonParser.calls[0].service.timezoneOffset;
        //     workOrder.Non_Emergency_Appointment_Time__c = jsonParser.calls[0].service.appointmentTime;              
        //     workOrder.Collision__c = jsonParser.calls[0].service.collision; 
        //     workOrder.Red_Flag__c = jsonParser.calls[0].service.redFlag;
        //     workOrder.Priority_Code__c = jsonParser.calls[0].service.priorityCode;
        //     workOrder.Number_Of_Passengers__c = jsonParser.calls[0].service.numberOfPassengers; 
        //     workOrder.Needs_Flatbed__c = jsonParser.calls[0].service.needsFlatbed; 
        //     workOrder.Flatbed_Requested__c = jsonParser.calls[0].service.flatbedRequested;
        //     workOrder.Flatbed_Requested__c = false;           
        //     workOrder.ADP_SeqID__c = jsonParser.calls[0].service.apdSeqId; 
              
        //     FSL_JSonParserWorkOrder.ServiceLocations_Location breakDownLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
        //     FSL_JSonParserWorkOrder.ServiceLocations_Location towLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
              
        //     //ServiceLocations
        //     if (jsonParser.calls[0].service.serviceLocations != null && !jsonParser.calls[0].service.serviceLocations.isEmpty()) {
        //         for (FSL_JSonParserWorkOrder.ServiceLocations serviceLoc : jsonParser.calls[0].service.serviceLocations) {
        //             if(serviceLoc.serviceLocationType == 'BREAKDOWN') {
        //                 if (serviceLoc.foi != null && serviceLoc.foi.Location != null) {
        //                     breakDownLocation = serviceLoc.foi.Location;
        //                     workOrder.D3_ER_Mileage__c = serviceLoc.mileageCalculated;                              
        //                     // workOrder.Driver_Directions__c = serviceLoc.driverDirections;
        //                 }
        //             }
        //             if(serviceLoc.serviceLocationType == 'TOW_DESTINATION') {
        //                 if(serviceLoc.foi != null && serviceLoc.foi.Location != null) {
        //                     towLocation = serviceLoc.foi.Location;
        //                     workOrder.Drop_Box_Info__c = serviceLoc.dropBoxInfo;
        //                     workOrder.D3_Tow_Mileage__c = serviceLoc.mileageCalculated;
        //                     workOrder.Tow_Landmark__c = towLocation.landmark;
        //                     if(serviceLoc.foi.contacts != null && !serviceLoc.foi.contacts.isEmpty() ) {
        //                         workOrder.Tow_Contact_First_Name__c = serviceLoc.foi.contacts[0].firstName;
        //                         workOrder.Tow_Contact_Last_Name__c = serviceLoc.foi.contacts[0].lastname;
        //                         if(serviceLoc.foi.contacts[0].phones != null && !serviceLoc.foi.contacts[0].phones.isEmpty()){
        //                           workOrder.Tow_Contact_Phone_Number__c = serviceLoc.foi.contacts[0].phones[0].phoneNumber;
        //                         }
        //                     }
        //                     workOrder = towAddressLoader(workOrder, towLocation, serviceLoc.foi.name);
        //                 }
        //             }
        //         }
        //     }

        //     workOrder = breakDownAddressLoader(workOrder, breakDownLocation);

        //     //   ***  Service Tech Team: logic is moved to FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility()   ***

        //     // //Added this logic for #1387
        //     // if (jsonParser.calls[0].service.facility.preferenceType == 'Required') {
        //     //     workOrder.ServiceTerritoryId = FSL_AppointmentDependencyHelper.getTerritoryIdFromIntakeFacility(facilityId);
        //     //     // if territory is STILL null, set the call to In Jeopardy
        //     //     if(workOrder.ServiceTerritoryId == null){
        //     //         workOrder.In_Jeopardy__c = true;
        //     //     }
        //     //     System.debug('Breakdown location is not within an existing polygon');
        //     // } else {
        //     //     //adding Polygon logic to populate service territory on Work Oder
        //     //     if (workOrder.Breakdown_Location__Latitude__s != null && workOrder.Breakdown_Location__Longitude__s != null) {
        //     //         workOrder.ServiceTerritoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(double.valueOf(workOrder.Breakdown_Location__Longitude__s), double.valueOf(workOrder.Breakdown_Location__Latitude__s));
        //     //     } else {
        //     //         System.debug('Polygon logic was not run because Breakdown address is not geo-coded');
        //     //         workOrder.In_Jeopardy__c = true;
        //     //     }
        //     // }

        //     // // ensure territory is populated
        //     // if (workOrder.ServiceTerritoryId == null) {
        //     //     // retrieve the territory from the Facility ID 
        //     //     workOrder.ServiceTerritoryId = FSL_AppointmentDependencyHelper.getTerritoryFromIntakeFacility(facilityId);
        //     //     // if territory is STILL null, set the call to In Jeopardy
        //     //     if (workOrder.ServiceTerritoryId == null) {
        //     //         workOrder.In_Jeopardy__c = true;
        //     //     }
        //     //     System.debug('Breakdown location is not within an existing polygon');
        //     // } else{   
        //     //     System.debug('Work Order Service Territory Resolved to ' + workOrder.ServiceTerritory.Name);
        //     // }    
            
        //     workOrder.ServiceTerritoryId = getTerritoryIdFromIntakeFacility(jsonParser, facilityId);
        //     if (workOrder.ServiceTerritoryId == null) {
        //         workOrder.In_Jeopardy__c = true;
        //     }

        //     //   ***  End  ***

        //     // driver directions should be copied to the SA as well
        //     workOrder.Driving_Directions__c = jsonParser.calls[0].service.serviceLocations[0].driverDirections;
        //     // country must be United States
        //     if(String.isBlank(workOrder.Country)){
        //         workOrder.Country = 'United States';
        //     }
        // }

        // if (jsonParser.calls[0].service.status != null) {
        //     //workOrder.Status = jsonParser.calls[0].service.status.status;
        //     workOrder.Status = 'Spotted';
        //     workOrder.InitialETA_Legacy__c = jsonParser.calls[0].service.status.eta;
        //     workOrder.Wait_Time__c =  jsonParser.calls[0].service.status.waitTime;              
        //     if (String.isNotBlank(jsonParser.calls[0].service.status.pta)) {
        //         String pta = jsonParser.calls[0].service.status.pta;
        //         pta = pta.substring(0 , pta.indexOf('Z') + 1);
        //         DateTime  dt = DateTime.valueOf(JSON.deserialize('"' + pta + '"', DateTime.class));
        //         System.Debug('DateValue is '+dt);
        //         workOrder.Pta__c = dt;
        //     }
        //     workOrder.Spotted_Timestamp__c = System.now();
        }

        //  ***  End  ***

        //Payment Information
        if (jsonParser.calls[0].payment != null) {
            // workOrder.Payment_Required__c = jsonParser.calls[0].payment.required;
            // workOrder.Payment_Type__c = jsonParser.calls[0].payment.paymentType;
            workOrder.Payment_Codes__c = jsonParser.calls[0].payment.codes;
            workOrder.Payment_Responsibility__c = jsonParser.calls[0].payment.responsible;
        }
         
        // add original member id
        if (jsonParser.calls[0].customer != null && jsonParser.calls[0].customer.memberships[0] != null && 
            jsonParser.calls[0].customer.memberships[0].originalMemberId != null)
        {            
            workOrder.Original_Member_Id__c = jsonParser.calls[0].customer.memberships[0].originalMemberId;
        }


        //      ***  Service Tech Team: logic for Vehicle Profile, "obtaining the Work Type Id" and "WO's Active Freeze logic" is moved here  ***

        workOrder.T_Code__c = tCode;
        workOrder.Vehicle_Profile__c = String.join(new List<String>{
                                                                    jsonParser.calls[0].vehicle.color,
                                                                    String.valueOf(jsonParser.calls[0].vehicle.year),
                                                                    jsonParser.calls[0].vehicle.make,
                                                                    jsonParser.calls[0].vehicle.plate,
                                                                    jsonParser.calls[0].vehicle.model
                                                                }, ' ').normalizeSpace();
        workOrder.Vehicle_Profile__c += String.isNotBlank(jsonParser.calls[0].vehicle.vehicleType) ? ' - ' + jsonParser.calls[0].vehicle.vehicleType : ''; 

        if (paceSetterTroubleCode != null) {
            workOrder.FSL_Pacesetter__c = paceSetterTroubleCode.substring(1,2);
            workOrder = obtainWorkTypeIdAndRecordTypeIdForWorkOrder(workOrder);
        }
 
        /* ERS-231104 Fix bug for territory override, remvoed the following to its own function to be called later
        if (workOrder.ServiceTerritoryId != null) {
            Schedule_Freeze__c activeFreeze = FSL_SchedulingUtility.checkIfFreezeApplies(workOrder.ServiceTerritoryId, workOrder.WorkTypeId);
            if (activeFreeze == null) {
                Technology_Preference__c techPref = FSL_SchedulingUtility.checkForTechnologyPreference(workOrder.ServiceTerritoryId);
                if (techPref != null) {
                    workOrder.Servicing_Technology_Type__c =  techPref.Technology_Type__c ;
                    if (techPref.Technology_Type__c == 'Landline') {
                        workOrder.In_Jeopardy__c = true;
                        workOrder.EntitlementId = null;
                    }
                    else if (techPref.Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK ) {
                        workOrder.EntitlementId = null;
                    }
                }
            } else {
                workOrder.Schedule_Freeze__c = activeFreeze.Id;
            }
        }
        */
        //      ***  End Refactoring  ***

                    
        return workOrder;
    }

    private static WorkOrder checkForTechnologyPrefAndFreeze(WorkOrder wo){

        if (wo.ServiceTerritoryId != null) {
            Schedule_Freeze__c activeFreeze = FSL_SchedulingUtility.checkIfFreezeApplies(wo.ServiceTerritoryId, wo.WorkTypeId);
            if (activeFreeze == null) {
                Technology_Preference__c techPref = FSL_SchedulingUtility.checkForTechnologyPreference(wo.ServiceTerritoryId);
                if (techPref != null) {
                    wo.Servicing_Technology_Type__c =  techPref.Technology_Type__c ;
                    if (techPref.Technology_Type__c == 'Landline') {
                        wo.In_Jeopardy__c = true;
                        wo.EntitlementId = null;
                    }
                    else if (techPref.Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK ) {
                        wo.EntitlementId = null;
                    }
                }
            } else {
                wo.Schedule_Freeze__c = activeFreeze.Id;
            }
        }
        return wo;
    }

    //   ***   Service Tech Team: new methods related to WO creation   ***

    private static WorkOrder handleParserServiceCallInfo(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder) {
        String facilityId = jsonParser.calls[0].service.facility.id;
        system.debug('facilityId 972 : '+facilityId);
        if (String.isBlank(facilityId)) {
            facilityId = 'N/A';
        }

        workOrder.AccountId = obtainAccountIdForWorkOrder(jsonParser, facilityId);
        
        String pCode = jsonParser.calls[0].service.priorityCode;
        String legacyPCode = jsonParser.calls[0].service.legacyPriorityCode;
        FSL_WorkOrderIntake.populareWorkOrderPriority(workOrder, pCode, legacyPCode);
        
        workOrder.Call_Type__c = jsonParser.calls[0].service.callType;
        workOrder.Timezone_Id__c = jsonParser.calls[0].service.timezoneId;
        workOrder.Timezone_Offset__c = jsonParser.calls[0].service.timezoneOffset;
        workOrder.Non_Emergency_Appointment_Time__c = jsonParser.calls[0].service.appointmentTime;
        workOrder.Collision__c = jsonParser.calls[0].service.collision; 
        workOrder.Red_Flag__c = jsonParser.calls[0].service.redFlag;
        workOrder.Priority_Code__c = jsonParser.calls[0].service.priorityCode;
        workOrder.Number_Of_Passengers__c = jsonParser.calls[0].service.numberOfPassengers; 
        workOrder.Needs_Flatbed__c = jsonParser.calls[0].service.needsFlatbed; 
        workOrder.Flatbed_Requested__c = jsonParser.calls[0].service.flatbedRequested;
        workOrder.Flatbed_Requested__c = false;
        workOrder.ADP_SeqID__c = jsonParser.calls[0].service.apdSeqId; 
           
        //ServiceLocations
        if (jsonParser.calls[0].service.serviceLocations != null && !jsonParser.calls[0].service.serviceLocations.isEmpty()) {
            workOrder = handleServiceLocations(jsonParser.calls[0].service.serviceLocations, workOrder);
        }
        
        if (String.isBlank(workOrder.Country)) {
            workOrder.Country = 'United States';
        }
        
        workOrder.ServiceTerritoryId = getTerritoryIdFromIntakeFacility(jsonParser, workOrder, facilityId);
        if (workOrder.ServiceTerritoryId == null) {
            workOrder.In_Jeopardy__c = true;
        }

        workOrder.Driving_Directions__c = jsonParser.calls[0].service.serviceLocations[0].driverDirections;

        if (jsonParser.calls[0].service.status != null) {
            workOrder.Status = 'Spotted';
            workOrder.InitialETA_Legacy__c = jsonParser.calls[0].service.status.eta;
            FSL_WorkOrder.IWorkOrderService workOrderService =  (new FSL_WorkOrder.Factory()).createService();
            workOrder.Wait_Time__c =  workOrderService.getValidatedWaitTimeOnIntake(jsonParser.calls[0].service.status.waitTime);
            if (String.isNotBlank(jsonParser.calls[0].service.status.pta)) {
                String pta = jsonParser.calls[0].service.status.pta;
                pta = pta.substring(0 , pta.indexOf('Z') + 1);
                DateTime dt = DateTime.valueOf(JSON.deserialize('"' + pta + '"', DateTime.class));
                workOrder.Pta__c = dt;
            }
            workOrder.Spotted_Timestamp__c = System.now();
        }

        return workOrder;
    }

    private static Id obtainAccountIdForWorkOrder(FSL_JSonParserWorkOrder jsonParser, String facilityId) {       
        if (facilityId != 'N/A') {
            List<Account> accountList = [SELECT Id FROM Account WHERE Facility_Id__c = :facilityId LIMIT 1];
            if (!accountList.isEmpty()) {
                return accountList[0].Id;
            }
        }
        
        Account newAccount = new Account();
        newAccount.Name = jsonParser.calls[0].service.facility.name;
        newAccount.Facility_Id__c = facilityId;
        newAccount.Facility_Type__c = jsonParser.calls[0].service.facility.foiType;
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();
        List<String> accountFields;
        if(Test.isRunningTest()){
            accountFields = new List<String>{'Name'};
        }else{
            FSL_Required_Fields_Validation__c accountFieldSetting = FSL_Required_Fields_Validation__c.getValues('Account'); 
            accountFields = accountFieldSetting.Fields__c.split(',');
        }
        
        String accountErrorMessage = '';
        for (String field : accountFields) { 
            if (newAccount.get(field) != null && newAccount.get(field) == '') {
                if (field.contains('__c')) {
                    accountErrorMessage = field.substring(0, field.indexof('__c')) + accountErrorMessage; 
                } else {
                    accountErrorMessage = field + accountErrorMessage; 
                }
            }
        }
        
        if (String.isNotBlank(accountErrorMessage)) {
            ERROR_MESSAGE += 'Reqruied Fields are missing on Account: ' + accountErrorMessage;
            System.debug('====isAccountFieldsMissing===' + ERROR_MESSAGE);
        }
        
        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
        insert newAccount;
        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

        return newAccount.Id;
    }

    private static WorkOrder handleServiceLocations(List<FSL_JSonParserWorkOrder.ServiceLocations> serviceLocationList, WorkOrder workOrder) {       
        FSL_JSonParserWorkOrder.ServiceLocations_Location breakDownLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
        FSL_JSonParserWorkOrder.ServiceLocations_Location towLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
         
        for (FSL_JSonParserWorkOrder.ServiceLocations serviceLoc : serviceLocationList) {
            if (serviceLoc.foi == null || serviceLoc.foi.Location == null) {
                continue;
            }
            
            if (serviceLoc.serviceLocationType == 'BREAKDOWN') {
                breakDownLocation = serviceLoc.foi.Location;
                workOrder.D3_ER_Mileage__c = serviceLoc.mileageCalculated;
            } else if (serviceLoc.serviceLocationType == 'TOW_DESTINATION') {
                towLocation = serviceLoc.foi.Location;
                workOrder.Drop_Box_Info__c = serviceLoc.dropBoxInfo;
                workOrder.D3_Tow_Mileage__c = serviceLoc.mileageCalculated;
                workOrder.Tow_Landmark__c = towLocation.landmark;
                if (serviceLoc.foi.contacts != null && !serviceLoc.foi.contacts.isEmpty() ) {
                    workOrder.Tow_Contact_First_Name__c = serviceLoc.foi.contacts[0].firstName;
                    workOrder.Tow_Contact_Last_Name__c = serviceLoc.foi.contacts[0].lastname;
                    if (serviceLoc.foi.contacts[0].phones != null && !serviceLoc.foi.contacts[0].phones.isEmpty()) {
                        workOrder.Tow_Contact_Phone_Number__c = serviceLoc.foi.contacts[0].phones[0].phoneNumber;
                    }
                    assignWOD3AARIdFromServicLocation ( workOrder, serviceloc );
                }
                workOrder = towAddressLoader(workOrder, towLocation, serviceLoc.foi.name);
            }
        }
        workOrder = breakDownAddressLoader(workOrder, breakDownLocation);
        return workOrder;
    }

    @testVisible
    private static void assignWOD3AARIdFromServicLocation ( WorkOrder workOrder, FSL_JSonParserWorkOrder.ServiceLocations serviceLoc ) {
        System.debug ('-- Entering assignWOD3AARIdFromServicLocation -- foiType= ' + serviceLoc.foi.foiType );
        if ( serviceLoc.foi.id != null ) {
            System.debug (' Assigning D3_AAR_ID to Workorder' + serviceloc.foi.id );
            workOrder.D3_AAR_Id__c = serviceloc.foi.id;
        }
    }

    //      ***   End   ***

    /**********
     *@Method Name:breakDownAddressLoader
     *@Parameters: (JSonParserWorkOrder breakdown )
     *@Description: Method is to set breakdown address comming from D3.
     **************/
    @TestVisible
    private static WorkOrder breakDownAddressLoader(WorkOrder workOrder, FSL_JSonParserWorkOrder.ServiceLocations_Location breakDownLocation){
        //   *** Service Tech Team: added a check for breakdown location address and refactor
        
        workOrder.Latitude                          = breakDownLocation.Latitude == 0 ? null : breakDownLocation.Latitude;
        workOrder.Longitude                         = breakDownLocation.longitude == 0 ? null : breakDownLocation.longitude;
        System.debug('lat received: ' + breakDownLocation.Latitude);
        System.debug('long received: ' + breakDownLocation.longitude);        
        workOrder.Breakdown_Location__Latitude__s   = breakDownLocation.Latitude == 0 ? null : breakDownLocation.Latitude;
        workOrder.Breakdown_Location__Longitude__s  = breakDownLocation.longitude == 0 ? null : breakDownLocation.longitude;
        
        workOrder.Location_Code__c      = breakDownLocation.locationCode;
        workOrder.Mile_Marker__c        = breakDownLocation.mileMarker;
        workOrder.Highway__c            = breakDownLocation.highway;
        workOrder.Landmark__c           = breakDownLocation.landmark;
        
        if (breakDownLocation.address == null) {
            return workOrder;
        }
        
        workOrder.Cross_Street__c   = breakDownLocation.address.crossStreet;
        workOrder.Cross_Street_2__c = breakDownLocation.address.crossStreet2;

        /*
        Story UF-309
        A street address is defined as:
        a) If streetNumber is provided, street address = streetNumber + streetDirection + streetName
        b) If streetNumber is not provided, street address = street
        c) If street address is still blank and crossStreet is not, street address = crossStreet + '&' + crossStreet2
         */
        //For case (a)
        if (String.isNotBlank(breakDownLocation.address.streetNumber) || System.Test.isRunningTest()){
            String bdStreetNumber       = (/*String.isBlank(breakDownLocation.address.streetNumber) || */ breakDownLocation.address.streetNumber == 'null') ? '' : breakDownLocation.address.streetNumber + ' ';   //  ***   Service Tech Team: commented out the redundant check  ***
            String bdStreetDirection    = (String.isBlank(breakDownLocation.address.streetDirection) || breakDownLocation.address.streetDirection == 'null') ? '' : breakDownLocation.address.streetDirection + ' ';
            workOrder.street            = bdStreetNumber + bdStreetDirection + breakDownLocation.address.streetName;
        } else {//For case (b)
            workOrder.street            = breakDownLocation.address.street;
        }
        //For case (c)
        if (String.isBlank(workOrder.street) && String.isNotBlank(workOrder.Cross_Street__c)) {
            workOrder.street   = workOrder.Cross_Street__c;
            if (String.isNotBlank(workOrder.Cross_Street_2__c)) {
                workOrder.street += ' & ' + workOrder.Cross_Street_2__c;
            }
            
        }

        workOrder.City                  = breakDownLocation.address.city;
        workOrder.state                 = breakDownLocation.address.state;
        workOrder.postalCode            = breakDownLocation.address.postalCode;
        workOrder.country               = breakDownLocation.address.country;

        //  ***  Service Tech Team: moved this lines to the method beginning

        // workOrder.Location_Code__c      = breakDownLocation.locationCode;
        // workOrder.Mile_Marker__c        = breakDownLocation.mileMarker;
        // workOrder.Highway__c            = breakDownLocation.highway;
        // workOrder.Landmark__c           = breakDownLocation.landmark;

        //   ***  End   ***
        return workOrder;
    }

    /**********
     *@Method Name:towAddressLoader
     *@Parameters: (JSonParserWorkOrder towLocation )
     *@Description: Method is to set tow address coming from D3.
     **************/
    @TestVisible
    private static WorkOrder towAddressLoader(WorkOrder workOrder, FSL_JSonParserWorkOrder.ServiceLocations_Location towLocation, String foiName) {
        //   ***  Service Tech Team: replaced "try-catch" with tow location address check

        // try {
        workOrder.Tow_Destination_Name__c    = foiName;
        workOrder.Tow_Location__Latitude__s  = towLocation.Latitude == 0 ? null : towLocation.Latitude;
        workOrder.Tow_Location__Longitude__s = towLocation.longitude == 0 ? null : towLocation.longitude;
        workOrder.Tow_Latitude__c            = towLocation.Latitude == 0 ? null : towLocation.Latitude;
        workOrder.Tow_Longitude__c           = towLocation.longitude == 0 ? null : towLocation.longitude;
            // workOrder.Tow_Cross_Street__c        = towLocation.address.crossStreet;
            // workOrder.Tow_Cross_Street_2__c      = towLocation.address.crossStreet2;
        // }
        // } catch (NullPointerException e) {
        //     System.debug('FSL_WorkOrderIntake::workOrderAddressNullPointerException\n'+e.getMessage());
        // } catch (Exception e) {
        //     System.debug('FSL_WorkOrderIntake::workOrderAddressException\n'+e.getMessage());
        // }

        if (towLocation.address == null) {
            return workOrder;
        }
        
        workOrder.Tow_Cross_Street__c = towLocation.address.crossStreet;
        workOrder.Tow_Cross_Street_2__c = towLocation.address.crossStreet2;

        /*
        Story UF-309
        A street address is defined as:
        a) If streetNumber is provided, street address = streetNumber + streetDirection + streetName
        b) If streetNumber is not provided, street address = street
        c) If street address is still blank and crossStreet is not, street address = crossStreet + '&' + crossStreet2
        */
        //For case (a)
        if (String.isNotBlank(towLocation.address.streetNumber)) {
            String towStreetNumber = (/*String.isBlank(towLocation.address.streetNumber) || */ towLocation.address.streetNumber == 'null') ? '' : towLocation.address.streetNumber + ' ';   //  ***   Service Tech Team: commented out the redundant check  ***
            String towStreetDirection   = (String.isBlank(towLocation.address.streetDirection) || towLocation.address.streetNumber == 'null') ? '' : towLocation.address.streetDirection + ' ';
            workOrder.Tow_Street__c     = towStreetNumber + towStreetDirection + towLocation.address.streetName;
        } else {//For case (b)
            workOrder.Tow_Street__c     = towLocation.address.street;
        }
        //For case (c)
        if (String.isBlank(workOrder.Tow_Street__c) && String.isNotBlank(workOrder.Tow_Cross_Street__c)) {
            workOrder.Tow_Street__c = workOrder.Tow_Cross_Street__c;
            // if(String.isNotBlank(workOrder.Tow_Cross_Street_2__c)){
            //     workOrder.Tow_Street__c += ' & ' + workOrder.Tow_Cross_Street_2__c;
            // }
            
            workOrder.Tow_Street__c += String.isNotBlank(workOrder.Tow_Cross_Street_2__c) ? ' & ' + workOrder.Tow_Cross_Street_2__c : '';
        }

        workOrder.Tow_City__c           = towLocation.address.city;
        workOrder.Tow_State__c          = towLocation.address.state;
        workOrder.Tow_Postal_Code__c    = towLocation.address.postalCode;
        workOrder.Tow_Country__c        = towLocation.address.country;
        workOrder.Tow_Country__c        = 'United States';

        //   ***   End  ***

        return workOrder;
    }

    @TestVisible
    private static Id getTerritoryIdFromIntakeFacility(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder, String facilityId) {

        Id ServiceTerritoryId = null;
        Boolean doesLatLongExist = workOrder.Breakdown_Location__Latitude__s != null && workOrder.Breakdown_Location__Longitude__s != null;

        if (jsonParser.calls[0].service.facility.preferenceType == 'Required' || !doesLatLongExist) {
            ServiceTerritoryId = getServiceTerritoryByFacilityId(facilityId);       
        } else if (doesLatLongExist) {
            ServiceTerritoryId =  FSL.PolygonUtils.getTerritoryIdByPolygons(Double.valueOf(workOrder.Breakdown_Location__Longitude__s), Double.valueOf(workOrder.Breakdown_Location__Latitude__s));
            // When the Managed package failed to get the Service Territory ID through Lat/long, we are going to force a get from the ServiceTerritory object by FacilityId
            if(ServiceTerritoryId == null){
                ServiceTerritoryId = getServiceTerritoryByFacilityId(facilityId);
            }
        }
        return ServiceTerritoryId;
    }

    private static Id getServiceTerritoryByFacilityId(String facilityId){
        List<ServiceTerritory> spottedSTList = [SELECT Id FROM ServiceTerritory WHERE Facility_Number__c = :facilityId];
        return !spottedSTList.isEmpty() ? spottedSTList[0].Id : null;   
    }

    @testVisible
    private static Id getServiceTerritoryOverrideId(WorkOrder wo){
        // This routine takes the incoming Service Territory Id and check to see if there is a ST override, if it does, return that ST override Id
        Id serviceTerritoryId = wo.ServiceTerritoryId;
        Id overrideSTId = serviceTerritoryId;

        // Check to see if input service territory is a map territory
        Boolean isMapST = isMapServiceTerritory(serviceTerritoryId);
        if(isMapST){
            // Retrieve the Overide ST Id from Scheduling Override Object
            overrideSTId = FSL_SchedulingUtility.getScheduleOverrideSTId(serviceTerritoryId, wo);
        }
                
        return overrideSTId;
    }
    @testVisible
    private static boolean isMapServiceTerritory(Id serviceTerritoryId){        
        Id RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Map Territory').getRecordTypeId();
        List<ServiceTerritory> mapSTList = [SELECT Id FROM ServiceTerritory WHERE Id = :serviceTerritoryId AND RecordTypeId = :RecordTypeId];

        // TODO, log error if more than one entries returned
        return !mapSTList.isEmpty() ? true : false;
    }

    //   ***   Service Tech Team: new methods related to WO creation   ***

    private static WorkOrder obtainWorkTypeIdAndRecordTypeIdForWorkOrder(WorkOrder workOrder) {
        system.debug('@@@@@paceSetterTroubleCode@@@@@@'+paceSetterTroubleCode);
        List<FSL_TroubleCode_WorkType__mdt> troubleCodeWorkTypeList = [
            SELECT Id,AdditionalCriteria__c, TroubleCode__c, WorkType__c, Service_Type__c
            FROM FSL_TroubleCode_WorkType__mdt
            WHERE TroubleCode__c = :paceSetterTroubleCode
        ];
        system.debug('@@@@@troubleCodeWorkTypeList@@@@@@'+troubleCodeWorkTypeList);
        if (troubleCodeWorkTypeList.isEmpty()) {
            return workOrder;
        }

        FSL_TroubleCode_WorkType__mdt troubleCodeWorkType = troubleCodeWorkTypeList[0];
        String requestedWorkType = '';
        
        if (troubleCodeWorkType.AdditionalCriteria__c) {
            Set<String> validRVVehiclesSet = new Set<String>(System.Label.FSL_Valid_RV_VehicleTypes.split(';'));
            Set<String> validLocationSet = new Set<String>(System.Label.FSL_Valid_LC_LocationCode.split(';'));
            Set<String> validMotorVehicleSet = new Set<String>(System.Label.FSL_Valid_MV_VehicleTypes.split(';'));
            Set<String> validRVMVVehicleSet = new Set<String>(System.Label.FSL_Valid_RV_MV_VehicleTypes.split(';'));
                                                    
            if (troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Extrication')) {
                requestedWorkType = validRVVehiclesSet.contains(workOrder.Vehicle_Type__c) ? System.Label.FSL_RV_Extrication_WorkType : System.Label.FSL_Non_RV_Extrication_WorkType;
            }
            else if (troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Tow')) {
                requestedWorkType = obtainTowWorkType(workOrder, validRVVehiclesSet, validLocationSet, validMotorVehicleSet, validRVMVVehicleSet);
            }
            //Bastine
            else if (troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Accident First')) {
                requestedWorkType = obtainAccidentFirstWorkType(workOrder, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
            }
            else if (troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Accident Second')) {
                requestedWorkType = obtainAccidentSecondWorkType(workOrder, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
            }
            else if (troubleCodeWorkType.WorkType__c.equalsIgnoreCase('Accident Continuation')) {
                requestedWorkType = obtainAccidentContinuationWorkType(workOrder, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
            }
            //End Bastine                                                                             
        } else {
            requestedWorkType = troubleCodeWorkType.WorkType__c;                            
        }
        System.Debug('requestedWorkType:'+ requestedWorkType);  
        WorkType worktype = [SELECT Id, Name FROM WorkType WHERE Name = :requestedWorkType];
        System.Debug('requestedWorkType:'+ worktype);     
        if (troubleCodeWorkType.Service_Type__c.equalsIgnoreCase('Tow')) {
            workOrder.Is_Tow_WorkType__c = true;
            Id towWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            workOrder.RecordTypeId = towWorkorderRecordTypeId;                                    
        } else {
            Id lightWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
            workOrder.RecordTypeId = lightWorkorderRecordTypeId;
        }
        System.Debug('worktype.Id:'+worktype);
        workOrder.WorktypeId = worktype.Id;
        return workOrder;
    }

    private static String obtainTowWorkType(WorkOrder workOrder, Set<String> validRVVehiclesSet, Set<String> validLocationSet, Set<String> validMotorVehicleSet, Set<String> validRVMVVehicleSet) {
       
        // Addded by @Vishnu Popuru #15/04/2025
        // Changes: Added => Long Tow(LT) & rearranged the conditions 
        if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) {             // Motorcycle (MC)
            return System.Label.FSL_Motorcycle_Tow_WorkType;
        }else if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {         // Recreational Vehicle (RV)
            return System.Label.FSL_RV_Tow_WorkType;
        }else if(workOrder.Total_Mileage__c > 25){                                  // Long Tow (LT)
            return System.Label.FSL_Long_Tow_WorkType;
        }else if (workOrder.Flatbed_Requested__c || workOrder.Needs_Flatbed__c) {   // Flatbed (FB)
            return System.Label.FSL_Flatbed_Tow_WorkType;
        }else if (validLocationSet.contains(workOrder.Location_Code__c)) {          // Low Clearance (LC)
            return System.Label.FSL_Low_Clearance_Tow_WorkType;
        }else if (!validRVMVVehicleSet.contains(workOrder.Vehicle_Type__c)) {       // Passenger Car Tow 
            return System.Label.FSL_Passenger_Car_Tow_WorkType;
        }

        return '';
    }

    private static String obtainAccidentFirstWorkType(WorkOrder workOrder, Set<String> validRVVehiclesSet, Set<String> validMotorVehicleSet, Set<String> validRVMVVehicleSet) {
        if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_RV_First_Tow;
        } else if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_MV_First_Tow;
        } else if (!validRVMVVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_First_Tow; 
        }
        return '';
    }

    private static String obtainAccidentSecondWorkType(WorkOrder workOrder, Set<String> validRVVehiclesSet, Set<String> validMotorVehicleSet, Set<String> validRVMVVehicleSet) {
        if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_RV_Second_Tow; 
        } else if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_MV_Second_Tow; 
        } else if (!validRVMVVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_Second_Tow; 
        }
        return '';
    }

    private static String obtainAccidentContinuationWorkType(WorkOrder workOrder, Set<String> validRVVehiclesSet, Set<String> validMotorVehicleSet, Set<String> validRVMVVehicleSet) {
        if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_RV_Continuation_Tow; 
        } else if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_MV_Continuation_Tow; 
        } else if (!validRVMVVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Accident_Assist_Continuation_Tow; 
        }
        return '';
    }

    //      ***   End   *** 

    /**********
     *@Method Name:createTroubleCodes
     *@Parameters: (JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference )
     *@Description: Method is to create troublecode objects by extracting the data from JSON request which comming from D3.
     **************/
    private static List<FSL_TroubleCode__c> createTroubleCodes(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference) {
        List<FSL_TroubleCode__c> troubleCodeList = new List<FSL_TroubleCode__c>();
        List<FSL_JSonParserWorkOrder.troubleCodes> wrapperTroubleCodeList = new List<FSL_JSonParserWorkOrder.troubleCodes>();

        //   ***  Service Tech Team: return the empty list if the payload trouble codes are null/empty  ***
        if (jsonParser.calls[0].service.troubleCodes == null || jsonParser.calls[0].service.troubleCodes.isEmpty()) {
            return troubleCodeList;
        }

        //   ***  Service Tech Team: commented out and replaced with if above  ***
        // if (jsonParser.calls[0].service.troubleCodes != null && !jsonParser.calls[0].service.troubleCodes.isEmpty()) {
        for (FSL_JSonParserWorkOrder.TroubleCodes trCode : jsonParser.calls[0].service.troubleCodes) {
            FSL_TroubleCode__c troubleCode = new FSL_TroubleCode__c();
            troubleCode.Code__c = trCode.code;
            troubleCode.Description__c = trCode.description;
            troubleCode.Type__c = trCode.troubleCodeType;
            troubleCode.Work_Order__r = workOrder_reference;
            if (trCode.troubleCodeType != null && trCode.troubleCodeType.equalsIgnoreCase('PACESETTER') ) {
                paceSetterTroubleCode = trCode.code;
            }
            /*
            if (trCode.troubleCodeType != null && trCode.troubleCodeType.equalsIgnoreCase('PROBLEM') ) { //new
                tCode = trCode.code;
            }
            */
            troubleCodeList.add(troubleCode);
        }
        // }
        
        
        Boolean isTroubleCodeFieldsMissing = false;
        String TRCODES_ERROR_MESSAGE = '';
        List<String> trCodeFields;
        if(Test.isRunningTest()){
            trCodeFields = new List<String>{'Type__c'};
        }else{
            FSL_Required_Fields_Validation__c fieldstrcode = FSL_Required_Fields_Validation__c.getValues('TroubleCode'); 
            trCodeFields = fieldstrcode.Fields__c.split(',');

        }
        
        for (FSL_TroubleCode__c t: troubleCodeList) {
            if (t.Type__c.equalsIgnoreCase('PACESETTER')) {
                tCode = t.Code__c + ' - ' + t.Description__c;
            }
            for (String ss : trCodeFields) {
                if (t.get(ss) != null && t.get(ss) == '') {
                    isTroubleCodeFieldsMissing = true;
                    TRCODES_ERROR_MESSAGE = ss.substring(0,ss.indexof('__c'))+TRCODES_ERROR_MESSAGE+'\n'; 
                }
            }
         }
         
        if (isTroubleCodeFieldsMissing) {
            ERROR_MESSAGE += 'Required Fields are missing on TroubleCodes: '+TRCODES_ERROR_MESSAGE;
        }
                    
        return troubleCodeList;
    }

    /**********
     *@Method Name:createMemberVehicle
     *@Parameters: (JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference )
     *@Description: Method is to create memberVehicle objects by extracting the data from JSON request which comming from D3.
     **************/
    private static FSL_Member_Vehicle__c createMemberVehicle(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference) {
        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();

        //Vehicle Information
        if(jsonParser.calls[0].vehicle != null){
            memberVehicle.Vehicle_Type__c =  jsonParser.calls[0].vehicle.vehicleType;
            memberVehicle.Vehicle_Year__c =  String.valueOf(jsonParser.calls[0].vehicle.year);
            memberVehicle.Vehicle_Make__c =  jsonParser.calls[0].vehicle.make;
            memberVehicle.Vehicle_Plate__c =  jsonParser.calls[0].vehicle.plate;//EMI
            memberVehicle.Vehicle_Model__c = jsonParser.calls[0].vehicle.model;
            memberVehicle.Vehicle_Trim__c = jsonParser.calls[0].vehicle.trim;
            memberVehicle.Vehicle_Color__c = jsonParser.calls[0].vehicle.color;
            memberVehicle.Vehicle_Drive_Type__c = jsonParser.calls[0].vehicle.driveType;
            memberVehicle.Vehicle_Vin__c = jsonParser.calls[0].vehicle.vin;
            memberVehicle.Vehicle_Tag__c = jsonParser.calls[0].vehicle.tag;
            memberVehicle.Vehicle_State__c = jsonParser.calls[0].vehicle.state;
            memberVehicle.Vehicle_Odometer__c = jsonParser.calls[0].vehicle.odometer;
            memberVehicle.Vehicle_Fuel_Type__c = jsonParser.calls[0].vehicle.fuelType;
            memberVehicle.Vehicle_Special_Equipment_Needs__c = jsonParser.calls[0].vehicle.specialEquipmentNeeds;
            //memberVehicle.Work_Order__r = workOrder_reference;
            
            if(jsonParser.calls[0].vehicle.rvInfo != null){
                memberVehicle.RV_Class__c = jsonParser.calls[0].vehicle.rvInfo.rvClass;
                memberVehicle.RV_Length__c = jsonParser.calls[0].vehicle.rvInfo.length;
            }
            if(jsonParser.calls[0].vehicle.trailerInfo != null){
                memberVehicle.Trailer_Hitchtype__c = jsonParser.calls[0].vehicle.trailerInfo.hitchType;
                /*if(jsonParser.calls[0].vehicle.trailerInfo.length != null) {
                    String notValidNumber= '[^0-9]';  
                    string tLength =jsonParser.calls[0].vehicle.trailerInfo.length.replaceAll( notValidNumber, '' ) );  
                    memberVehicle.RV_Length__c = tLength;
                }*/
                memberVehicle.Trailer_Length__c = jsonParser.calls[0].vehicle.trailerInfo.length;
            }
            
            if(jsonParser.calls[0].customer.memberships!= null && jsonParser.calls[0].customer.memberships[0].programMaxMileage!= null){
                memberVehicle.Maximum_Mileage__c= integer.ValueOf(jsonParser.calls[0].customer.memberships[0].programMaxMileage);
            }
            
            if(jsonParser.calls[0].service!= null){
                memberVehicle.Duty__c = jsonParser.calls[0].service.duty;

            }
            if(jsonParser.calls[0].vehicle.keycodes != null){          
                memberVehicle.MMPV_Keycodes__c = jsonParser.calls[0].vehicle.keycodes.mmpv;
                memberVehicle.Ignition_Keycodes__c = jsonParser.calls[0].vehicle.keycodes.ignition;
                memberVehicle.Door_Keycodes__c = jsonParser.calls[0].vehicle.keycodes.door;
                memberVehicle.Vats_Keycodes__c = jsonParser.calls[0].vehicle.keycodes.vats;            
            }
        }

        return memberVehicle;
    }
    
    /**********
     *@Method Name:policies
     *@Parameters: (JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference )
     *@Description: Method is to create Policy objects by extracting the data from JSON request which comming from D3.
     **************/

    private static FSL_Policy__c createPolicy(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference ){
        FSL_Policy__c policy = new FSL_Policy__c();

        if(!(jsonParser.calls[0].service.policies == null  ) ){
            if(jsonParser.calls[0].service.policies.size() > 0 ){
                if(String.isNotBlank(jsonParser.calls[0].service.policies[0].Code)){
                    policy.Policy_Code__c = jsonParser.calls[0].service.policies[0].Code;
                    policy.Policy_Description__c = jsonParser.calls[0].service.policies[0].description;
                    policy.Work_Order__r = workOrder_reference;
                }
            }
        }
        return policy;
    }
    
    public static void validateWorkOrder(String objectName, WorkOrder create_workOrder){
        Boolean isWorkOrderFieldsMissing = false;
        String WORKORDER_ERROR_MESSAGE = '';
        List<String> woFields;
        if(Test.isRunningTest()){
            woFields = new List<String>{'External_Id__c','Status'};
        }else{
            FSL_Required_Fields_Validation__c FieldsWo = FSL_Required_Fields_Validation__c.getValues(objectName);
            woFields = FieldsWo.Fields__c.split(',');
        }
        
        for (String ss : woFields) {
            if(create_workOrder.get(ss) != null && create_workOrder.get(ss) == '') {
                isWorkOrderFieldsMissing = true;
                WORKORDER_ERROR_MESSAGE = WORKORDER_ERROR_MESSAGE + ss.substring(0,ss.indexof('__c'))+'\n';
            }
        }
        if(isWorkOrderFieldsMissing) {
            ERROR_MESSAGE+= 'Reqruied Fields are missing on ' + objectName + ': ' + WORKORDER_ERROR_MESSAGE;
        }       
    }
    
    public static void populareWorkOrderPriority(WorkOrder workOrder, String priorityCode, String legacyPriorityCode){
        priorityCode = String.isNotBlank(priorityCode) ? priorityCode :'NA';
        priorityCode = priorityCode.toUpperCase();
        FSL_PriorityCode_Mapping__c code = FSL_PriorityCode_Mapping__c.getInstance(priorityCode);
        if (code != null) {
            workOrder.Priority = code.WorkOrder_Priority__c;
            workOrder.Priority_Description__c = code.Priority_Description__c;
        } else {
            // if we receive a priority code but it does not match with anyting on file
            // default to high priority
            workOrder.Priority = 'High';
            workOrder.Priority_Description__c = LegacyPrioritycode;
        }
        workOrder.Legacy_Priority_Code__c = legacyPriorityCode;         
    }

    //      ***  Service Tech Team: Created and refactored methods for WO related records creation  ***

    // public static List<FSL_Call_Comments__c> createCallComments(List<FSL_JSonParserWorkOrder.Comments> comments, WorkOrder wo_ref) {
    //     List<FSL_Call_Comments__c> callCommentList = new List<FSL_Call_Comments__c>();
    //     for(FSL_JSonParserWorkOrder.Comments comment : comments) {
    //         if(String.isNotBlank(comment.text)){
    //             FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
    //             callComment.FSL_Comment__c = comment.text;
    //             callComment.FSL_Work_Order__r = wo_ref;
    //             callCommentList.add(callComment);
    //          }   
    //     }
    //     return callCommentList;
    // }

    private static void createAndInsertCallComments(FSL_JSonParserWorkOrder jsonParser, WorkOrder wo_ref) {
        if (jsonParser.calls[0].comments == null) {
            return;
        }
        
        List<FSL_Call_Comments__c> callCommentList = new List<FSL_Call_Comments__c>();
        for (FSL_JSonParserWorkOrder.Comments comment : jsonParser.calls[0].comments) {
            if (String.isNotBlank(comment.text)) {
                FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
                callComment.FSL_Comment__c = comment.text;
                callComment.FSL_Work_Order__r = wo_ref;
                callCommentList.add(callComment);
             }   
        }
        if (!callCommentList.isEmpty()) {
            insert callCommentList;
        }
    }


    private static void createAndInsertResourcePreferences(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder) {
        List<ResourcePreference> rpList = new List<ResourcePreference>();
        Set<ID> serviceResourceIDSet = new Set<ID>();
        try {
            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

            // Landline Calls are not assigned, therefore Preferences are not needed
            if (workOrder.Servicing_Technology_Type__c != 'Landline') {
                // Create Excluded Resource Preference Records for Critical Work Orders
                List<ResourcePreference> excludedResourcesForCriticalCall = new List<ResourcePreference>();
                excludedResourcesForCriticalCall = FSL_SchedulingUtility.getActiveResourcesInSpottedTerritory(workOrder);
                if (!excludedResourcesForCriticalCall.isEmpty()) {
                    rpList.addAll(excludedResourcesForCriticalCall);
                    for (ResourcePreference rp : excludedResourcesForCriticalCall) {
                        serviceResourceIDSet.add(rp.ServiceResourceId);
                    }
                }                    
                
                // Create Resource Preferences based on Intake infor
                if (jsonParser.calls[0].service.facility.preferenceType != null) {                                    
                    String territId = workOrder.ServiceTerritoryId;
                    List<ResourcePreference> resourcePreferencesFromIntake = new List<ResourcePreference>();
                    resourcePreferencesFromIntake = FSL_SchedulingUtility.addResourcePreferencesBasedOnPrefType(workOrder.Id, jsonParser.calls[0].service.facility.preferenceType, territId, serviceResourceIDSet);
                    if (!resourcePreferencesFromIntake.isEmpty()) {
                        rpList.addAll(resourcePreferencesFromIntake);
                    }                                    
                }
            }

            if (!rpList.isEmpty()) {
                System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                insert rpList;
                System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
            }
        }
        catch(Exception ex){//Ignore
            System.debug('Error Caught: ' + ex.getStackTraceString() +' At Line:'+ex.getLineNumber());
        }
    }
    //      ***  End Refactoring  ***

    //   ***  Service Tech Team: adding additional ST fields for WorkOrder's Service Appointment creation
    
    /**********
     *@Method Name:workOrderLookUp
     *@Parameters: (String CallId)
     *@Description: Method return Work Order just recently create within a day with specific callid
     * Modifier : Dylan Truong 
     * User Story : ERS-219581 -- FSL_Timeout.  
     **************/
    public static List<WorkOrder> workOrderLookUp(String callId) {
        List<WorkOrder> wo = [
            SELECT Id, WorkOrderNumber, ServiceTerritory.OperatingHours.Timezone
            FROM WorkOrder
            WHERE Call_Id__c = :callId
            AND CreatedDate = LAST_N_DAYS:1
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return wo;
    }

    /**********
     *@Method Name:workOrderLookUpByCallKey
     *@Parameters: (String callKey)
     *@Description: Method return Work Order just recently with external Id as callkey
     * Modifier : Rohit
     * User Story :   
     **************/
    public static List<WorkOrder> workOrderLookUpByCallKey(String callKey) {
        List<WorkOrder> wo = [
            SELECT Id, WorkOrderNumber, ServiceTerritory.OperatingHours.Timezone
            FROM WorkOrder
            WHERE External_Id__c = :callKey
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return wo;
    }


    // *********************************************
    // * Utility static helper class
    // ********************************************* 
    // SSFI-1111 MPatel Commented Bing   
    /*@future(callout=true)
    private static void createCMLIWithMileage(Id WorkOrderId, String productName, 
                Double latOrigin, Double longOrigin, Double latDestination, Double longDestination) {
        try {

            FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
            FSL_Mapping.IMap mappingService = new FSL_Mapping.BingMap( appLogService );
            FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService sliService = new FSL_CalculatedMileageLineItem.Factory().createService();

            Decimal totalMileage = 0.0;
            if(latOrigin != null && longOrigin != null && latDestination != null && longDestination != null) {
                totalMileage = mappingService.calculateDistanceInMiles( latOrigin, longOrigin, latDestination, longDestination );
            }
            system.debug(LoggingLevel.DEBUG, 'totalMileage: [' + totalMileage + ']');
            if(!sliService.doesCalculatedMileageLineItemForWorkOrderAndProductCodeExist(WorkOrderId, 'CT')) {
                sliService.createCalculatedMileageLineItem(WorkOrderId, totalMileage.intValue(), productName);
            }
        }
        catch( Exception ex ) {
            System.debug( LoggingLevel.ERROR, 'FSL_WorkOrderIntake.createCMLIWithMileage: Exception = [' + ex.getMessage() + ']' );
        }            
    }*/

   /*@future(callout=true)
    private static void createSLIWithMileage(Id WorkOrderId, String productName, 
                Double latOrigin, Double longOrigin, Double latDestination, Double longDestination) {
        try {

            FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
            FSL_Mapping.IMap mappingService = new FSL_Mapping.BingMap( appLogService );
            FSL_ServiceLineItem.IServiceLineItemService sliService = new FSL_ServiceLineItem.Factory().createService();

            Decimal totalMileage = 0.0;
            if(latOrigin != null && longOrigin != null && latDestination != null && longDestination != null) {
                totalMileage = mappingService.calculateDistanceInMiles( latOrigin, longOrigin, latDestination, longDestination );
            }
            system.debug(LoggingLevel.DEBUG, 'totalMileage: [' + totalMileage + ']');
            if(!sliService.doesServiceLineItemForWorkOrderAndProductCodeExist(WorkOrderId, 'TW')) {
                sliService.createServiceLineItem(WorkOrderId, totalMileage.intValue(), productName);
            }
        }
        catch( Exception ex ) {
            System.debug( LoggingLevel.ERROR, 'FSL_WorkOrderIntake.createSLIWithMileage: Exception = [' + ex.getMessage() + ']' );
        }            
    }*/

    @TestVisible
    public static Case createWOCase(string accId, string contactId, string callKey) {
        Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ERS_Case').getRecordTypeId();
        Case cs = new Case();
        cs.accountId = accId;
        cs.contactId = contactId;
        cs.Status = 'New';
        cs.Origin = 'Automated';
        cs.Subject = 'New Case for D3 WorkOrder Intake for CallKey : '+callKey;
        cs.recordTypeId = caseRecTypeId;
        cs.call_Source__c = 'D3';
        cs.ACG_SMS_Opt_In__c = woSmsOptIn;
        //cs.ServiceContractId = '';
        return cs;
    }
}