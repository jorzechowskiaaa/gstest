/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 12-21-2022
 * @last modified by  : Clement Shiu
**/


global without sharing class CallReceiveWorkOrderIntegration {
    public CallReceiveWorkOrderIntegration() {  

    }
 
    private static String ERROR_MESSAGE = '';    // *** Service Tech Team: variable is used only in this class, so it should be private  ***
    private static String paceSetterTroubleCode;    // *** Service Tech Team: variable is used only in this class, so it should be private  ***
    private static String tCode;   // *** Service Tech Team: added a static variable for Work Order creation  ***

    public static WorkOrder createWO(FSL_JSonParserWorkOrder jsonParser) {

      // Log the Json That is coming in.
      FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLog.Factory().createService();
      CaseToWorkOrderLog appLog = new CaseToWorkOrderLog();
      String logMessage = 'Received a request to Create a WO from a Case';
      appLog.logSuccess(jsonParser, logMessage);
      List<CaseToWorkOrderLog> lstLogs = new List<CaseToWorkOrderLog>();
      lstLogs.add(appLog);
      logService.saveApplicationLogs(lstLogs);

       // SNK - Call Receive Integration Change
       // Moved Creation of Trouble Codes, Member Vehicle and Policy to a later point so workorder is ppulated correctly
       WorkOrder workOrderRecord = new WorkOrder();
      
       WorkOrder create_workOrder = createWorkOrder(jsonParser);
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

       /*
       List<Contact> contacts = new List<Contact>();
       if (jsonParser.calls[0].customer.contact.id == null) {
          //Calling createContact
          FSL_Contact.IContactService contactService = new FSL_Contact.Factory().createService();
          //System.debug('------------- createService TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
          contacts = contactService.createContacts( jsonParser.calls );
          //System.debug('------------- createContacts TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
      } else  {

          contacts = [SELECT Id, AccountId, Phone, Sms_Optin__c FROM Contact WHERE Id =: jsonParser.calls[0].customer.contact.id];

      }

      if (!contacts.isEmpty()) {
          create_workOrder.ContactId = contacts[0].Id;
          create_workOrder.putSObject('Contact', contacts[0]);
          create_workOrder.Member_Account__c = contacts[0].AccountId;
          create_workOrder.WO_Member_Phone_Number__c = contacts[0].Phone;
      }*/

      create_workOrder.ContactId = jsonParser?.calls?.get(0)?.customer?.contact.id;
      create_workOrder.Member_Account__c = jsonParser?.calls?.get(0)?.customer?.contact.accountId;
      //create_workOrder.WO_Member_Phone_Number__c = jsonParser?.calls?.get(0)?.customer?.contact?.phones?.get(0)?.phoneNumber;
      create_workOrder.WO_Member_Phone_Number__c = jsonParser.calls[0].service.memberPhone;
      create_workOrder.SMS_OptIn__c = jsonParser?.calls?.get(0)?.customer?.contact?.phones?.get(0)?.smsOptIn;
      if(create_workOrder.Member_Account__c != null){ //AGB 6/11 Updated for SSFI-35
      	UpdateContact(create_workOrder.Member_Account__c,create_workOrder.WO_Member_Phone_Number__c,create_workOrder.SMS_OptIn__c);	      
      }
      // create_workOrder.WO_Member_Phone_Number__c = Update from the Member Contact number from the Case Main Page

       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       FSL_WorkOrderIntake.validateWorkOrder('WorkOrder', create_workOrder);
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
              
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       //System.debug('DMLs before - ' + Limits.getDMLStatements());


       // SNK Call Receive Integration refactoring Changes

       //Calling createTroubleCodes
       List<FSL_TroubleCode__c> troubleCodes = createTroubleCodes(jsonParser, create_workOrder);
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       //System.debug(paceSetterTroubleCode);

       //Calling createMemberVehicle
       FSL_Member_Vehicle__c memberVehicle = createMemberVehicle(jsonParser, create_workOrder);
       upsert memberVehicle; // We would need memberVehicle created before WO creation as the Platform Event on WO would need vehicle details.
       
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
        if(memberVehicle != null){
            create_workOrder.Member_Vehicle__c = memberVehicle.Id;
        }
       //Calling createPolicy 
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       FSL_Policy__c policy = createPolicy(jsonParser, create_workOrder);
        system.debug('@@@@ 88ServiceTerritoryId@@@@@@'+create_workOrder.ServiceTerritoryId);
       // ERS-230370 ACE Service Territory Override, need to call it here after the TroubleCodes and Location, Vehicle Info are there
       if(create_workOrder.ServiceTerritoryId != null){           
            create_workOrder.ServiceTerritoryId = getServiceTerritoryOverrideId(create_workOrder);
            create_workOrder = checkForTechnologyPrefAndFreeze(create_workOrder);
       }
       system.debug('@@@@ 94ServiceTerritoryId@@@@@@'+create_workOrder.ServiceTerritoryId);
       //system.assertEquals('Raj','Raj51');
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       insert create_workOrder;
       
       System.Debug('Resolve WO ID: '  +  ' ID of Inserted WO:' + create_workOrder.Id) ;   
       resolveWorkOrderReferenceInRelatedObjects(create_workOrder, troubleCodes, memberVehicle, policy);

       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       insert troubleCodes;
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       upsert memberVehicle;
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       insert policy;
       
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       createAndInsertCallComments(jsonParser, create_workOrder);


       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

       //System.debug('DMLs after - ' + Limits.getDMLStatements());
       
       //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       AAA_FeedbackIncomingAuthUtil.upsertFeedback(create_workOrder.Id);

       workOrderRecord = [
           SELECT Id, WorkOrderNumber, Call_Id__c, D3_Tow_Mileage__c, ServiceTerritory.OperatingHours.Timezone, ServiceTerritory.Facility_Number__c
           FROM WorkOrder
           WHERE Id = :create_workOrder.Id
       ];

       create_workOrder.ServiceTerritoryId = workOrderRecord.ServiceTerritoryId;
       create_workOrder.putSObject('ServiceTerritory', workOrderRecord.ServiceTerritory);
       create_workOrder.Call_Id__c = workOrderRecord.Call_Id__c;
      
   /*    if (workOrderRecord.D3_Tow_Mileage__c != null) {   
           FSL_ServiceLineItem.IServiceLineItemService serviceLineItem = new FSL_ServiceLineItem.Factory().createService();
           FSL_CalculatedMileageLineItem.ICalculatedMileageLineItemService CMLineItem = new FSL_CalculatedMileageLineItem.Factory().createService();
           //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
           serviceLineItem.createServiceLineItem(workOrderRecord.Id, workOrderRecord.D3_Tow_Mileage__c.intValue(), 'TW - TOW MILEAGE');
           CMLineItem.createCalculatedMileageLineItem(workOrderRecord.Id, workOrderRecord.D3_Tow_Mileage__c.intValue(), 'CT - Calculated Tow');
           //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
       } else if(create_workOrder.Is_Tow_WorkType__c) {

           createCMLIWithMileage(workOrderRecord.id, 
                                'CT - Calculated Tow',
                                Double.valueOf(create_workOrder.Breakdown_Location__Latitude__s), 
                                Double.valueOf(create_workOrder.Breakdown_Location__Longitude__s), 
                                Double.valueOf(create_workOrder.Tow_Location__Latitude__s), 
                                Double.valueOf(create_workOrder.Tow_Location__Longitude__s));

          /* createSLIWithMileage(workOrderRecord.id, 
                               'TW - TOW MILEAGE',
                               Double.valueOf(create_workOrder.Breakdown_Location__Latitude__s), 
                               Double.valueOf(create_workOrder.Breakdown_Location__Longitude__s), 
                               Double.valueOf(create_workOrder.Tow_Location__Latitude__s), 
                               Double.valueOf(create_workOrder.Tow_Location__Longitude__s));        */                                     
     //  }   */                   
      
       //      *** Service Tech Team: logic moved to createAndInsertResourcePreferences()-method
       createAndInsertResourcePreferences(jsonParser, create_workOrder);


       //Create and Schedule Service Appointment(s) 
       List<WorkOrder> woList = new List<WorkOrder>();
       woList.add(create_workOrder);
       //System.debug('Time before SA insert - ' + Datetime.now());  //  *** Service Tech Team debug ***
       if(!Test.isRunningTest()) {
       FSL_AppointmentDependencyHelper.createAndScheduleServiceAppointments(woList.get(0), jsonParser);
       }
       //System.debug('Time after SA insert - ' + Datetime.now());  //  *** Service Tech Team debug ***

       // SNK We need the WorkOrderNumber to the Dispatch Side, SVC Appt Ids to be returned to the Call Receive side, so do a fresh query

       workOrderRecord = [
           SELECT Id, WorkOrderNumber, Pta__c, Use_your_long_tow_entitlement__c, ServiceContract.ParentServiceContractId,
               (SELECT Id FROM ServiceAppointments)
           FROM WorkOrder
           WHERE Id = :create_workOrder.Id
       ];

       //Need to fix thisFSL_ApplicationLogCreator.insertAplicationLog(request, res, SUCCESS_MESSAGE, 'CaseToWorkOrder', false, callId, version, workOrderRecord);            

       appLog = new CaseToWorkOrderLog();
       logMessage = 'Successfully Created a WorkOrder from a Call Receive Case';
       appLog.logSuccess(jsonParser, logMessage, workOrderRecord);
       lstLogs = new List<CaseToWorkOrderLog>();
       lstLogs.add(appLog);
       logService.saveApplicationLogs(lstLogs);
       return workOrderRecord;

    }
    
    private static void UpdateContact(string acntId, string memberphone, boolean smsoptin){ //AGB 6/11 Updated for SSFI-35 
        try{
            Account accountToUpdate = [SELECT id,PersonMobilePhone,Sms_Optin__pc FROM Account 
                                       WHERE id = :acntId
                                       LIMIT 1];
            accountToUpdate.Sms_Optin__pc = smsoptin;
            accountToUpdate.PersonMobilePhone = memberphone;
            update accountToUpdate;
        }
        catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
    }
    
    /**********
     *@Description: Method is to set workorder data from JSON request which comming from Call Receive/D3. 
     **************/    
    @TestVisible
    private static WorkOrder createWorkOrder(FSL_JSonParserWorkOrder jsonParser) {
        system.debug('jsonParser-line-197'+jsonParser);//EMI
        WorkOrder workOrder = new WorkOrder();
        workOrder.External_ID__c = jsonParser.calls[0].callKey;
        //Commenting out as part of callIntake 2837 redo 11/03/2023
        //workOrder.Call_Id__c = jsonParser.calls[0].callId;        
        if(jsonParser.calls[0].service.callType == 'RAP') //AGB SSFI-14
        {
            workOrder.ACG_Call_Type__c = 'RAP';
        }
        workOrder.Call_Date__c = jsonParser.calls[0].callDate;
        workOrder.CaseId = jsonParser.caseId;
        workOrder.ServiceContractId = jsonParser.contractId;
        //workOrder.AAA_Charge_Entitlement__c = true;
        workOrder.Reconcile_Entitlement__c = jsonParser.reconcileEntitlement;
        workOrder.Tow_Request_Reason__c = jsonParser.towRequestReason;//EMI
        workOrder.Tow_Request_Miscellaneous_Details__c = jsonParser.towRequestMiscellaneousDetails;//EMI
        
        
        Timezone tz = Timezone.getTimeZone('America/New_York');
        DateTime dtpre = DateTime.now();  //1:59:59AM local EDT
        Integer offSet = tz.getOffset(dtpre)/(1000*60*60);
        system.debug(offSet);

        workOrder.Timezone_Id__c  = 'America/New_York' ;
        workOrder.Timezone_Offset__c  = 'UTC'+offSet ;
         
        String goodwill = jsonParser?.calls[0]?.customer?.memberships[0]?.goodwill;
        if(goodwill != null) {
            workOrder.Goodwill_Indicator__c = (jsonParser.calls[0].customer.memberships[0].goodwill == 'Y');
        }

        FSL_JSonParserWorkOrder.Channel channel = jsonParser.calls[0].Channel;
        if ( channel != null) {
            if(channel.channelType.contains('DRR')){ //AGB 6/18/2024 for SFI-724
                workOrder.Call_Origin__c = 'DRR';
            }
            else{
            	workOrder.Call_Origin__c = channel.channelType;
            }
            workOrder.Channel__c = channel.channelType; //AGB 6/4/24 for SFI-724
            
            if ( channel.org != null) {
                workOrder.Call_Origin_OrgCode__c = channel.org.code != null ? channel.org.code : '';
                workOrder.Call_Origin_OrgName__c = channel.org.Name != null ? channel.org.Name : '';
            }

            String user = channel?.contact?.userId;
            if(user != null) {
                workOrder.Responder_ID__c = user;
            }
    
        }

        //Vehicletype Information
        
        if (jsonParser.calls[0].vehicle.vehicleType != null) {
            workOrder.Vehicle_Type__c = jsonParser.calls[0].vehicle.vehicleType;    
        }   
        workOrder.RAP_Case_Number__c = jsonParser.calls[0].requestingSystemCallId; 
        
        //Service Information
        if (jsonParser.calls[0].service != null) {

            workOrder = handleParserServiceCallInfo(jsonParser, workOrder);

        }

        //Payment Information
        if (jsonParser.calls[0].payment != null) {
            workOrder.Payment_Required__c = jsonParser.calls[0].payment.required;
            workOrder.Payment_Codes__c = jsonParser.calls[0].payment.codes;
            workOrder.Payment_Responsibility__c = jsonParser.calls[0].payment.responsible;
        }
         
        // add original member id
        if (jsonParser.calls[0].customer != null && jsonParser.calls[0].customer.memberships[0] != null && 
            jsonParser.calls[0].customer.memberships[0].originalMemberId != null)
        {            
            workOrder.Original_Member_Id__c = jsonParser.calls[0].customer.memberships[0].originalMemberId;
        }

        //CDX Information
        if (jsonParser.calls[0].customer != null && jsonParser.calls[0].customer.memberships[0] != null && 
            jsonParser.calls[0].customer.memberships[0].authorizationCode != null)  {
            workOrder.CDX_Authorization_Code__c = jsonParser.calls[0].customer.memberships[0].authorizationCode;    
            workOrder.CDX_Authorization_Level__c = jsonParser.calls[0].customer.memberships[0].authorizationLevel;    
            //workOrder.CDX_Authorization_TransactionId__c = jsonParser.calls[0].customer.memberships[0].authorizationTransactionId;    
        }
        
        // SNK - This is now done in createTroubleCodes
        //workOrder.T_Code__c = tCode;
        workOrder.Vehicle_Profile__c = String.join(new List<String>{
                                                                    jsonParser.calls[0].vehicle.color,
                                                                    String.valueOf(jsonParser.calls[0].vehicle.year),
                                                                    jsonParser.calls[0].vehicle.make,
                                                                    jsonParser.calls[0].vehicle.model,
                                                                    jsonParser.calls[0].vehicle.plate//EMI
                                                                }, ' ').normalizeSpace();
        workOrder.Vehicle_Profile__c += String.isNotBlank(jsonParser.calls[0].vehicle.vehicleType) ? ' - ' + jsonParser.calls[0].vehicle.vehicleType : ''; 

        // if (paceSetterTroubleCode != null) {
        //     workOrder.FSL_Pacesetter__c = paceSetterTroubleCode.substring(1,2);
        //     workOrder = obtainWorkTypeIdAndRecordTypeIdForWorkOrder(workOrder);
        // }
 
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
        if(workOrder.Call_Origin_OrgCode__c == '' || workOrder.Call_Origin_OrgCode__c == null){
            workOrder.Call_Origin_OrgCode__c = Label.FSL_SourceClubCode;
            workOrder.Call_Origin_OrgName__c = Label.Club_Name;
        }
         system.debug('workOrder-line-314'+workOrder); //EMI           
        return workOrder;
    }

    // ERS-231104 Fix bug for territory override
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
        if (String.isBlank(facilityId)) {
            facilityId = 'N/A';
        }

        if (!String.IsBlank(jsonParser.calls[0].service.facility.name)) {
            workOrder.AccountId = obtainAccountIdForWorkOrder(jsonParser, facilityId);
        }
        //String legacyPCode = jsonParser.calls[0].service.legacyPriorityCode;
        //CallReceiveWorkOrderIntegration.populateWorkOrderPriority(workOrder, PCode, legacyPCode );
        workOrder.Priority = jsonParser.calls[0].service.priorityCode;
        String priority = jsonParser.calls[0].service.priorityCode;
        String pCode = String.isNotBlank(jsonParser.calls[0].service.priorityDescription) ? jsonParser.calls[0].service.priorityDescription.substringBefore('-') : '';
        if(String.isNotBlank(pCode)){
            workOrder.Priority__c = pCode;
            workOrder.Priority_Code__c = pCode;
        }
        workOrder.Priority_Description__c = jsonParser.calls[0].service.priorityDescription;
        workOrder.Call_Type__c = jsonParser.calls[0].service.callType;
        workOrder.Timezone_Id__c = jsonParser.calls[0].service.timezoneId;
        workOrder.Timezone_Offset__c = jsonParser.calls[0].service.timezoneOffset;
        workOrder.Non_Emergency_Appointment_Time__c = jsonParser.calls[0].service.appointmentTime;
        workOrder.Collision__c = jsonParser.calls[0].service.collision; 
        workOrder.Red_Flag__c = jsonParser.calls[0].service.redFlag;
        workOrder.Number_Of_Passengers__c = jsonParser.calls[0].service.numberOfPassengers; 
        workOrder.Needs_Flatbed__c = jsonParser.calls[0].service.needsFlatbed; 
        workOrder.Flatbed_Requested__c = jsonParser.calls[0].service.flatbedRequested;
        workOrder.Flatbed_Requested__c = false;
        workOrder.ADP_SeqID__c = jsonParser.calls[0].service.apdSeqId; 
        workOrder.Use_your_long_tow_entitlement__c = jsonParser.calls[0].service.useYourLongTowEntitlement;
        workOrder.Use_Home_Lock_Entitlement__c = jsonParser.calls[0].service.useHomeLockoutEntitlement;
        workOrder.Total_Mileage__c = jsonParser.calls[0].service.totalMileage;
        WorkOrder.AAA_Charge_Entitlement__c = jsonParser.calls[0].service.chargeEntitlement;
        WorkOrder.Repair_Shop__c = jsonParser.calls[0].service.repairShopId;
        //ServiceLocations
        if (jsonParser.calls[0].service.serviceLocations != null && !jsonParser.calls[0].service.serviceLocations.isEmpty()) {
            workOrder = handleServiceLocations(jsonParser.calls[0].service.serviceLocations, workOrder);            
        }
        
        if (String.isBlank(workOrder.Country)) {
            workOrder.Country = 'United States';
        }
        
        workOrder.ServiceTerritoryId = getTerritoryIdFromIntakeFacility(jsonParser, workOrder, facilityId);
        system.debug('@@@@@ 365ServiceTerritoryId @@@@@'+ workOrder.ServiceTerritoryId);
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
                DateTime dt = (DateTime) JSON.deserialize(pta, DateTime.class);
                System.debug( 'handleParserServiceCallInfo ( from service.status.pta. DateTime= >' + dt.formatLong() + '<' );
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
            } else {
        Account newAccount = new Account();

        newAccount.Facility_Id__c = facilityId;
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();
        newAccount.Name = jsonParser.calls[0].service.facility.name;
        newAccount.Facility_Type__c = jsonParser.calls[0].service.facility.foiType;
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
                system.debug(' entered FSL_Required_Fields_Validation__c field ' + field);
                if (field.contains('__c')) {
                    accountErrorMessage = field.substring(0, field.indexof('__c')) + accountErrorMessage; 
                } else {
                    accountErrorMessage = field + accountErrorMessage; 
                }
            }
        }
        
        if (String.isNotBlank(accountErrorMessage)) {
            ERROR_MESSAGE += 'Required Fields are missing on Account: ' + accountErrorMessage;
            System.debug('====isAccountFieldsMissing===' + ERROR_MESSAGE);
        }
        
        //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
        insert newAccount;
        //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

        return newAccount.Id;
    }
        }
        
        return null;
    }

    private static WorkOrder handleBreakdownServiceLocation(FSL_JSonParserWorkOrder.ServiceLocations serviceLoc, WorkOrder workOrder) {       

        System.debug('====handlebreakdownServiceLocation: breakDownAddressLoader info ===');


        if (serviceLoc.foi != null && serviceLoc.foi.Location != null) {

            FSL_JSonParserWorkOrder.ServiceLocations_Location breakDownLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();

            breakDownLocation = serviceLoc.foi.Location;
            workOrder.D3_ER_Mileage__c = serviceLoc.mileageCalculated;
            //Add the missing Driving Directions
            workOrder.Driving_Directions__c = serviceLoc.driverDirections;

            workOrder = breakDownAddressLoader(workOrder, breakDownLocation);
    
        }

        return workOrder;

    }

    private static WorkOrder handleTowServiceLocation(FSL_JSonParserWorkOrder.ServiceLocations serviceLoc, WorkOrder workOrder) {       

        System.debug('====handleTowServiceLocation: info ===');


        if (serviceLoc.foi_towDest != null && serviceLoc.foi_towDest.Location != null) {

            FSL_JSonParserWorkOrder.Location_TowDest towLocation = new FSL_JSonParserWorkOrder.Location_TowDest();

            System.debug('====handleTowServiceLocation: towAddressLoader info ===');
            towLocation = serviceLoc.foi_towDest.Location;
            workOrder.D3_Tow_Mileage__c = serviceLoc.mileageCalculated;
            workOrder.Tow_Landmark__c =  serviceLoc.foi_towDest.location.landmark;

            workOrder = towAddressLoader(workOrder, towLocation, serviceLoc.foi_towDest.name);
    
        }

        return workOrder;

    }

    private static WorkOrder handleServiceLocations(List<FSL_JSonParserWorkOrder.ServiceLocations> serviceLocationList, WorkOrder workOrder) {       
        
        //FSL_JSonParserWorkOrder.ServiceLocations_Location breakDownLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
        //FSL_JSonParserWorkOrder.ServiceLocations_Location towLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
         
        for (FSL_JSonParserWorkOrder.ServiceLocations serviceLoc : serviceLocationList) {

            System.debug('====handleServiceLocations: serviceLocationType info === ' + serviceLoc.serviceLocationType);

            workOrder.Drop_Box_Info__c = serviceLoc.dropBoxInfo;


            if (serviceLoc.serviceLocationType == 'BREAKDOWN')  {
                
                workOrder = handleBreakdownServiceLocation(serviceLoc,workOrder);

            }
            else if (serviceLoc.serviceLocationType == 'TOW_DESTINATION') {

                workOrder = handleTowServiceLocation(serviceLoc,workOrder);
            }
           
            
        }
    //        workOrder = breakDownAddressLoader(workOrder, breakDownLocation);
        return workOrder;
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
    private static WorkOrder towAddressLoader(WorkOrder workOrder, FSL_JSonParserWorkOrder.Location_TowDest towLocation, String foiName) {
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
        //     System.debug('CallReceiveWorkOrderIntegration::workOrderAddressNullPointerException\n'+e.getMessage());
        // } catch (Exception e) {
        //     System.debug('CallReceiveWorkOrderIntegration::workOrderAddressException\n'+e.getMessage());
        // }

        if (towLocation.address == null) {
            System.debug('CallReceiveWorkOrderIntegration::workOrderAddressException: towLocation.address == null\n');
            return workOrder;
        }
        
        workOrder.Tow_Cross_Street__c = towLocation.address.crossStreet;
        //workOrder.Tow_Cross_Street_2__c = towLocation.address.crossStreet2;

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
            //String towStreetDirection   = (String.isBlank(towLocation.address.streetDirection) || towLocation.address.streetNumber == 'null') ? '' : towLocation.address.streetDirection + ' ';
            //workOrder.Tow_Street__c     = towStreetNumber + towStreetDirection + towLocation.address.streetName;
            workOrder.Tow_Street__c     = towStreetNumber + towLocation.address.streetName;
        } else {//For case (b)
            workOrder.Tow_Street__c     = towLocation.address.streetName;
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
        system.debug('@@@@@ 649 ServiceTerritoryId @@@@@'+facilityId);
        Id ServiceTerritoryId = null;
        Boolean doesLatLongExist = workOrder.Breakdown_Location__Latitude__s != null && workOrder.Breakdown_Location__Longitude__s != null;
        system.debug('@@@@@ 652 doesLatLongExist @@@@@'+doesLatLongExist);
        system.debug('@@@@@ 652 Longitude @@@@@'+Double.valueOf(workOrder.Breakdown_Location__Longitude__s));
        system.debug('@@@@@ 652 Latitude @@@@@'+Double.valueOf(workOrder.Breakdown_Location__Latitude__s));
        if (jsonParser.calls[0].service.facility.preferenceType == 'Required' || !doesLatLongExist) {
            ServiceTerritoryId = getServiceTerritoryByFacilityId(facilityId);       
        } else if (doesLatLongExist) {
            ServiceTerritoryId =  FSL.PolygonUtils.getTerritoryIdByPolygons(Double.valueOf(workOrder.Breakdown_Location__Longitude__s), Double.valueOf(workOrder.Breakdown_Location__Latitude__s));

            // When the Managed package failed to get the Service Territory ID through Lat/long, we are going to force a get from the ServiceTerritory object by FacilityId
            if(ServiceTerritoryId == null){

                ServiceTerritoryId = getServiceTerritoryByFacilityId(facilityId);
            }
        }
        system.debug('@@@@@ 666 ServiceTerritoryId @@@@@'+ServiceTerritoryId);
        return ServiceTerritoryId;
    }

    @testVisible
    private static Id getServiceTerritoryOverrideId(WorkOrder wo){
        // This routine takes the incoming Service Territory Id and check to see if there is a ST override, if it does, return that ST override Id
        Id serviceTerritoryId = wo.ServiceTerritoryId;
        Id overrideSTId = serviceTerritoryId;
        system.debug('@@@@@ 676 overrideSTId @@@@@'+overrideSTId);
        // Check to see if input service territory is a map territory
        Boolean isMapST = isMapServiceTerritory(serviceTerritoryId);
        system.debug('@@@@@ 679 isMapST @@@@@'+isMapST);
        if(isMapST){
            // Retrieve the Overide ST Id from Scheduling Override Object
            overrideSTId = FSL_SchedulingUtility.getScheduleOverrideSTId(serviceTerritoryId, wo);
            }
        system.debug('@@@@@ 684 overrideSTId @@@@@'+overrideSTId);       
        return overrideSTId;
        }
    
    @testVisible
    private static boolean isMapServiceTerritory(Id serviceTerritoryId){        
        Id RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Map Territory').getRecordTypeId();
        List<ServiceTerritory> mapSTList = [SELECT Id FROM ServiceTerritory WHERE Id = :serviceTerritoryId AND RecordTypeId = :RecordTypeId];

        // TODO, log error if more than one entries returned

        return !mapSTList.isEmpty() ? true : false;


    }

    private static Id getServiceTerritoryByFacilityId(String facilityId){
        List<ServiceTerritory> spottedSTList = [SELECT Id FROM ServiceTerritory WHERE Facility_Number__c = :facilityId];
        return !spottedSTList.isEmpty() ? spottedSTList[0].Id : null;   
    }

    //   ***   Service Tech Team: new methods related to WO creation   ***

    private static WorkOrder obtainWorkTypeIdAndRecordTypeIdForWorkOrder(WorkOrder workOrder) {
        List<FSL_TroubleCode_WorkType__mdt> troubleCodeWorkTypeList = [
            SELECT Id,AdditionalCriteria__c, TroubleCode__c, WorkType__c, Service_Type__c
            FROM FSL_TroubleCode_WorkType__mdt
            WHERE TroubleCode__c = :paceSetterTroubleCode
        ];

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
            
        WorkType worktype = [SELECT Id, Name FROM WorkType WHERE Name = :requestedWorkType];
       
        /*******EMI--start*********/
      /*  System.debug('Requested WorkType Name: ' + requestedWorkType);
        
        List<WorkType> workTypes = [SELECT Id, Name FROM WorkType WHERE Name = :requestedWorkType LIMIT 1];
        if (workTypes.isEmpty()) {
            throw new AuraHandledException('Work Order could not be created: WorkType "' + requestedWorkType + '" not found.');
        }
        WorkType worktype = workTypes[0];
		*/
        /*******EMI--End *********/
        
        
            
        if (troubleCodeWorkType.Service_Type__c.equalsIgnoreCase('Tow')) {
            workOrder.Is_Tow_WorkType__c = true;
            Id towWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            workOrder.RecordTypeId = towWorkorderRecordTypeId;                                    
        } else {
            Id lightWorkorderRecordTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
            workOrder.RecordTypeId = lightWorkorderRecordTypeId;
        }

        workOrder.WorktypeId = worktype.Id;
        return workOrder;
    }
    @TestVisible
    private static String obtainTowWorkType(WorkOrder workOrder, 
                                            Set<String> validRVVehiclesSet, Set<String> validLocationSet, 
                                            Set<String> validMotorVehicleSet, Set<String> validRVMVVehicleSet) {

        // Addded by @Vishnu Popuru #15/04/2025
        // Changes: Added => Long Tow(LT) & rearranged the conditions 
        if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) { // Motorcycle Tow takes precedence over Flatbed Tow (MC)
            return System.Label.FSL_Motorcycle_Tow_WorkType;
        } else if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {            // Recreational Vehicle (RV)
            return System.Label.FSL_RV_Tow_WorkType;
        }else if((workOrder.Total_Mileage__c != null ? workOrder.Total_Mileage__c : workOrder.D3_Tow_Mileage__c) > 25){                                      // Long Tow (LT)
            return System.Label.FSL_Long_Tow_WorkType;
        }
        else if (workOrder.Flatbed_Requested__c || workOrder.Needs_Flatbed__c) {       // Flatbed (FB)
            return System.Label.FSL_Flatbed_Tow_WorkType;
        } else if (validLocationSet.contains(workOrder.Location_Code__c)) {             // Low Clearance (LC)
            return System.Label.FSL_Low_Clearance_Tow_WorkType;
        } else if (!validRVMVVehicleSet.contains(workOrder.Vehicle_Type__c)) {          // Passenger Car Tow 
            return System.Label.FSL_Passenger_Car_Tow_WorkType;
        }
        return '';
    }

    /*
    else if (validMotorVehicleSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_Motorcycle_Tow_WorkType;
        } else if (validRVVehiclesSet.contains(workOrder.Vehicle_Type__c)) {
            return System.Label.FSL_RV_Tow_WorkType;
        } 
    */
    @TestVisible
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

         @TestVisible
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

         @TestVisible
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
    @TestVisible
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
            //troubleCode.Work_Order__r = workOrder_reference;
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

        if (paceSetterTroubleCode != null) {
            workOrder_reference.FSL_Pacesetter__c = paceSetterTroubleCode.substring(1,2);
            workOrder_reference = obtainWorkTypeIdAndRecordTypeIdForWorkOrder(workOrder_reference);
        }   
        
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
        workOrder_reference.T_Code__c = tCode;
                    
        return troubleCodeList;
    }

    /**********
     *@Method Name:createMemberVehicle
     *@Parameters: (JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference )
     *@Description: Method is to create memberVehicle objects by extracting the data from JSON request which comming from D3.
     **************/
    @TestVisible
    private static FSL_Member_Vehicle__c createMemberVehicle(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference) {
        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();

        //Vehicle Information
        if(jsonParser.calls[0].vehicle != null){
            if(jsonParser.calls[0].vehicle.id == null) {
                memberVehicle.Vehicle_Type__c =  jsonParser.calls[0].vehicle.vehicleType;
                memberVehicle.Vehicle_Year__c =  String.valueOf(jsonParser.calls[0].vehicle.year);
                memberVehicle.Vehicle_Make__c =  jsonParser.calls[0].vehicle.make;
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
                memberVehicle.Vehicle_Plate__c = jsonParser.calls[0].vehicle.plate;//EMI
                
                if(jsonParser.calls[0].vehicle.rvInfo != null){
                    memberVehicle.RV_Class__c = jsonParser.calls[0].vehicle.rvInfo.rvClass;
                    memberVehicle.RV_Length__c = jsonParser.calls[0].vehicle.rvInfo.length;
                }
                if(jsonParser.calls[0].vehicle.trailerInfo != null){
                    memberVehicle.Trailer_Hitchtype__c = jsonParser.calls[0].vehicle.trailerInfo.hitchType;
                    memberVehicle.Trailer_Length__c = jsonParser.calls[0].vehicle.trailerInfo.length;

                }
                
                // ----- Start of PLF : TEMP HACK 2022.08.14
                // if(jsonParser.calls[0].customer.memberships!= null && jsonParser.calls[0].customer.memberships[0].programMaxMileage!= null){
                //     memberVehicle.Maximum_Mileage__c= integer.ValueOf(jsonParser.calls[0].customer.memberships[0].programMaxMileage);

                // }
                // ----- End of PLF : TEMP HACK 2022.08.14
                
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
            else
            {
                memberVehicle = [SELECT Id, Work_Order__c FROM FSL_Member_Vehicle__c WHERE Id = :jsonParser.calls[0].vehicle.id];    
            }

            //memberVehicle.Work_Order__r = workOrder_reference;
            //memberVehicle.Work_Order__c = workOrder_reference.Id;
        }

        return memberVehicle;
    }
    
    /**********
     *@Method Name:policies
     *@Parameters: (JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference )
     *@Description: Method is to create Policy objects by extracting the data from JSON request which comming from D3.
     **************/
    @TestVisible
    private static FSL_Policy__c createPolicy(FSL_JSonParserWorkOrder jsonParser, WorkOrder workOrder_reference ){
        FSL_Policy__c policy = new FSL_Policy__c();

        if(!(jsonParser.calls[0].service.policies == null  ) ){
            if(jsonParser.calls[0].service.policies.size() > 0 ){
                if(String.isNotBlank(jsonParser.calls[0].service.policies[0].Code)){
                    policy.Policy_Code__c = jsonParser.calls[0].service.policies[0].Code;
                    policy.Policy_Description__c = jsonParser.calls[0].service.policies[0].description;
                    //policy.Work_Order__r = workOrder_reference;
                }
            }
        }
        return policy;
    }

       
    private static void resolveWorkOrderReferenceInRelatedObjects(WorkOrder insertedWO, List<FSL_TroubleCode__c> troubleCodes, 
                                                             FSL_Member_Vehicle__c memberVehicle,  FSL_Policy__c policy ) {
        System.Debug('Resolve WO ID: '  +  ' Passed WO Id: ' + insertedWO.Id) ;                                  
        for (FSL_TroubleCode__c trblCode : troubleCodes) {
            trblCode.Work_Order__c = insertedWO.Id;
        }
        memberVehicle.Work_Order__c = insertedWO.Id;
        policy.Work_Order__c = insertedWO.Id;
    }

    @TestVisible
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
            ERROR_MESSAGE+= 'Required Fields are missing on ' + objectName + ': ' + WORKORDER_ERROR_MESSAGE;
        }       
    }

    @TestVisible
    public static void populateWorkOrderPriority(WorkOrder workOrder, String priorityCode, String legacyPriorityCode){

        FSL_PriorityCode_Mapping__c code = FSL_PriorityCode_Mapping__c.getInstance(legacyPriorityCode);
        if (code != null) {
            workOrder.Priority = code.WorkOrder_Priority__c;
            workOrder.Priority_Description__c = code.Priority_Description__c;
        } else {
            // if we receive a priority code but it does not match with anyting on file
            // default to high priority
            workOrder.Priority = 'Medium';
            workOrder.Priority_Description__c = 'No Priority Code';
        }
        workOrder.Legacy_Priority_Code__c = legacyPriorityCode;         
    }



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
            //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

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
                //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                insert rpList;
                //System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
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


    // *********************************************
    // * Utility static helper class
    // ********************************************* 
    // SSFI-1111 MPatel commented Bing references   
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
            System.debug( LoggingLevel.ERROR, 'CallReceiveWorkOrderIntegration.createCMLIWithMileage: Exception = [' + ex.getMessage() + ']' );
        }            
    }*/

   /* @future(callout=true)
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
            System.debug( LoggingLevel.ERROR, 'CallReceiveWorkOrderIntegration.createSLIWithMileage: Exception = [' + ex.getMessage() + ']' );
        }            
    } */

    // ----- PLF : DESCRIPTION : populate FSL_JSonParserWorkOrder object with Case object data
    // ----- PLF : DESCRIPTION : populate FSL_JSonParserWorkOrder object with Case object data
    // ----- PLF : DESCRIPTION : populate FSL_JSonParserWorkOrder object with Case object data
    public class CaseToJsonWrapper {
 
        private Case caseObject;
        private WorkOrder workOrder;
        private string clubCode;
        INTFSLWorkOrderRequest_Wrapper WORequestJson = new INTFSLWorkOrderRequest_Wrapper();

        public CaseToJsonWrapper() {
        }

        public FSL_JSonParserWorkOrder Wrap(Case caseObject, string clubCode, INTFSLWorkOrderRequest_Wrapper requestJson) {
            this.WORequestJson = requestJson;
            return Wrap(caseObject, clubCode);
        }

        public FSL_JSonParserWorkOrder Wrap(Case caseObject, string clubCode) {
            
            System.debug(LoggingLevel.DEBUG,'Wrap entered');
            
            this.caseObject = caseObject;
            this.clubCode = clubCode;
            Workorder workOrder = new WorkOrder();
            
            FSL_JSonParserWorkOrder jsonParser = new FSL_JSonParserWorkOrder();
            
            jsonParser.status = caseObject.status;
            jsonParser.caseId = caseObject.Id;
            jsonParser.contractId = caseObject.ServiceContractId;
            jsonParser.reconcileEntitlement = caseObject.Reconcile_Entitlement__c;
            jsonParser.towRequestReason = caseObject.Tow_Request_Reason__c;//EMI
            jsonParser.towRequestMiscellaneousDetails = caseObject.Tow_Request_Miscellaneous_Details__c;//EMI
            jsonParser.calls = PopulateCalls();
            //AGB SSFI-14
            if(caseObject.RAP_Club__c != '' && caseObject.RAP_Club__c != null)
            {
                system.debug('RAP OVERRIDE ENTERED');
                jsonParser.calls[0].requestingSystemCallId = caseObject.RAP_Case_Number__c; //RAP Case Number
                jsonParser.calls[0].service.callType = 'RAP'; //Call_Type__c (used for Call_Type_Sub__c )
                jsonParser.calls[0].Channel.channelType = 'EDS';
                jsonParser.calls[0].Channel.org.code = caseObject.RAP_Club__c.split(' - ')[0].trim(); //Call_Origin_OrgCode__c
                jsonParser.calls[0].Channel.org.name = 'EDS'; //caseObject.RAP_Club__c.split(' - ')[1].trim(); //Call_Origin_OrgName__c
                string dateStr = caseObject.createdDate.format('yyyyMMdd');
                jsonParser.calls[0].callkey = PopulateCallKey( caseObject.RAP_Case_Number__c, dateStr );
            }
            //end AGB SSFI-14
            return jsonParser;
        }

        private List<FSL_JSonParserWorkOrder.Calls> PopulateCalls( ) {
            System.debug(LoggingLevel.DEBUG,'PopulateCalls entered');
            List<FSL_JSonParserWorkOrder.Calls> calls = new List<FSL_JSonParserWorkOrder.Calls>();
            
            FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();

            String dateStr;
            if(caseObject.createdDate == null) {
                Case cs = [SELECT CreatedDate FROM Case WHERE Id = :caseObject.Id];
                call.callDate = cs.createdDate.format('yyyy-MM-dd');
                dateStr = cs.createdDate.format('yyyyMMdd');
            } else {
                call.callDate = caseObject.createdDate.format('yyyy-MM-dd');
                dateStr = caseObject.createdDate.format('yyyyMMdd');
            }

            call.requestingSystemCallId = (WORequestJson?.requestingSystemCallId == null ? '' : WORequestJson?.requestingSystemCallId);
            system.debug('*****WORequestJsoncallId' + caseObject.Id );
            if(String.isBlank(WORequestJson?.callId)) {
                call.callId = PopulateCallId(caseObject.Id);                
            } else {
                call.callId = WORequestJson?.callId;
            }
            call.callkey = PopulateCallKey( call.callId, dateStr );
            call.channel = PopulateChannel();
            call.customer = PopulateCustomer( call.channel.org );
            call.vehicle = PopulateVehicle();
            call.service = PopulateService();
            call.payment = PopulatePayment();

            calls.add(call);
    
            return calls;
        }

        public string PopulateCallId(String caseId) {

            //Call_ID_Numbering__mdt callIDMetadata = new Call_ID_Numbering__mdt();
            //callIDMetadata = ([SELECT Max_Value__c, Min_Value__c FROM Call_ID_Numbering__mdt LIMIT 1]);
            //System.debug('Call_ID_Numbering metadata-->'+ callIDMetadata );
            string callId;  
            //string caseNumber = caseObject.CaseNumber;
            //if(caseNumber == null) {
                //system.debug('******cs1ss' + caseId);
                //Case cs = [SELECT Id FROM Case WHERE CaseNumber = :caseNumber];
                //system.debug('******csss' + cs.Id);
                //Workorder wo = [SELECT Call_Id__c, CaseId FROM WorkOrder WHERE CaseId = :caseId LIMIT 1];
                
                //callId = wo.Call_Id__c;
            //} 
            //Integer caseNumberLastFive = integer.valueOf(caseNumber.Substring(caseNumber.length() - 5));

            //Integer idRange = integer.valueOf(callIDMetadata.Max_Value__c) - integer.valueOf(callIDMetadata.Min_Value__c) + 1;

            //Integer id = System.Math.mod(caseNumberLastFive, idRange) + integer.valueOf(callIDMetadata.Min_Value__c);
            //string callId = string.valueOf(id);
                        
            return callId;
        }
    
        private string PopulateCallKey(string callId, String dateStr) {

            //string dateStr =  System.now().formatGmt('yyyyMMdd');
            //string callKey = clubCode + '-' + dateStr + '-' + callId;
            //string callKey = null;

            return this.clubCode + '-' + dateStr + '-' + callId;
        }

        private FSL_JSonParserWorkOrder.Channel PopulateChannel() {
            System.debug(LoggingLevel.DEBUG,'PopulateChannel entered');
            FSL_JSonParserWorkOrder.Channel channel = new FSL_JSonParserWorkOrder.Channel();

            channel.channelType = caseObject.Call_Origin__c;
            channel.org = PopulateSystemOrganization();
            channel.contact = PopulateContact();
    
            return channel;
        }

        private FSL_JSonParserWorkOrder.Contact PopulateContact() {
            FSL_JSonParserWorkOrder.Contact contact = new FSL_JSonParserWorkOrder.Contact();

            contact.userId = (WORequestJson?.userId == null ? '' : WORequestJson?.userId.left(9));

            return contact;
        }

        private FSL_JSonParserWorkOrder.SystemOrganziation PopulateSystemOrganization() {
            FSL_JSonParserWorkOrder.SystemOrganziation org = new FSL_JSonParserWorkOrder.SystemOrganziation();
    
            // if( workOrder.Contact != null ) {
            //     org.code = workOrder.Contact.Membership_OrgCode__c;
            //     org.name = workOrder.Contact.Membership_Org__c;
            // }    

            org.code = (WORequestJson?.sourceOrgCode == null ? '' : WORequestJson?.sourceOrgCode);
            org.name = (WORequestJson?.sourceOrgCode == null ? '' : WORequestJson?.sourceOrgName);
             return org;
        }

        private FSL_JSonParserWorkOrder.Customer PopulateCustomer( FSL_JSonParserWorkOrder.SystemOrganziation org ) {
            FSL_JSonParserWorkOrder.Customer customer = new FSL_JSonParserWorkOrder.Customer();
    
            customer.memberships = PopulateMemberships( org );
            customer.contact = PopulateCustomerContact();
            // customer.languagePreference = ( workOrder.Contact != null ? workOrder.Contact.Language_Preference__c : null ); //  PLF : TEMP HACK 2022.08.14
            customer.languagePreference = null;  //  PLF : TEMP HACK 2022.08.14

            return customer;
        }

        private List<FSL_JSonParserWorkOrder.Memberships> PopulateMemberships( FSL_JSonParserWorkOrder.SystemOrganziation org ) {
            List<FSL_JSonParserWorkOrder.Memberships> memberships = new List<FSL_JSonParserWorkOrder.Memberships>();
            memberships.add( PopulateMembership( org ) );
            return memberships;
        }        

        private FSL_JSonParserWorkOrder.Memberships PopulateMembership( FSL_JSonParserWorkOrder.SystemOrganziation org ) {
            FSL_JSonParserWorkOrder.Memberships membership = new FSL_JSonParserWorkOrder.Memberships();
 
            //membership.membershipType = contact.Membership_Type__c;
            //membership.sponsor = contact.Membership_Sponsor__c;
            //membership.program = contact.Membership_Program__c;
            membership.authorizationCode = caseObject.CDX_Authorization_Code__c;
            membership.authorizationLevel = caseObject.CDX_Authorization_Level__c;
            //membership.isLocalClub = contact.Membership_Islocalclub__c;
           // membership.authorizationTransactionId = caseObject.CDX_Authorization_TransactionId__c;            
            membership.org = org;
            membership.id = (caseObject.ACG_AAA_Membership__c != null ? caseObject.ACG_AAA_Membership__c : WORequestJson?.memberNumber); 
            membership.originalMemberId = (caseObject.ACG_AAA_Membership__c != null ? caseObject.ACG_AAA_Membership__c : WORequestJson?.memberNumber); 

            membership.memberLevel = caseObject.Case_Membership_Level__c;
            //membership.memberBirthday = ;
            //membership.memberSince = caseObject.Member_Since__c;
            membership.memberStatus = caseObject.ACG_Membership_Status__c;
        
            membership.entitlements = PopulateEntitlements();
    
            return membership;
        }

        private List<FSL_JSonParserWorkOrder.Entitlements> PopulateEntitlements() {
            List<FSL_JSonParserWorkOrder.Entitlements> entitlements = new List<FSL_JSonParserWorkOrder.Entitlements>();
            entitlements.add( PopulateEntitlement() );
            return entitlements;
        }
    
        private FSL_JSonParserWorkOrder.Entitlements PopulateEntitlement() {
            FSL_JSonParserWorkOrder.Entitlements entitlement = new FSL_JSonParserWorkOrder.Entitlements();

            return entitlement;
        }
        
        private FSL_JSonParserWorkOrder.Contact_customer PopulateCustomerContact() {
            FSL_JSonParserWorkOrder.Contact_customer customerContact = new FSL_JSonParserWorkOrder.Contact_customer();
    
            Id pContactId = caseObject.Account.PersonContactId;
            if(pContactId == null) {
                pContactId = [SELECT PersonContactId from Account where Id = :caseObject.Account.Id].PersonContactId;
            }
            customerContact.id = pContactId;
            customerContact.accountId = caseObject.Account.Id;
            customerContact.firstName = caseObject.Account.firstName;
            customerContact.lastName = caseObject.Account.lastName;

            customerContact.phones = PopulateCustomerPhones();
            customerContact.emails = PopulateCustomerEmails();
    
            return customerContact;
        }

        private List<FSL_JSonParserWorkOrder.Phones> PopulateCustomerPhones() {
            List<FSL_JSonParserWorkOrder.Phones> customerPhones = new List<FSL_JSonParserWorkOrder.Phones>();
            customerPhones.add( PopulateCustomerPhone() );
            return customerPhones;
        }
    
        private FSL_JSonParserWorkOrder.Phones PopulateCustomerPhone() {
            FSL_JSonParserWorkOrder.Phones customerPhone = new FSL_JSonParserWorkOrder.Phones();
    
            //customerPhone.phoneType = contact.Phone_Type__c;
            customerPhone.phoneNumber = caseObject.Account.phone;
            //customerPhone.phoneExtension = contact.Phone_Extension__c;
                // customerPhone.preferred
                customerPhone.smsOptIn = caseObject.ACG_SMS_Opt_In__c; //AGB SFI-735 SMS_OPT_IN being defaulted by account.
                /* //AGB SFI-735 SMS_OPT_IN being defaulted by account.
                if(caseObject.ACG_SMS_Opt_In__c == true){
                    customerPhone.smsOptIn = caseObject.ACG_SMS_Opt_In__c;
                }else{
                    customerPhone.smsOptIn = caseObject.Account.ACG_SMS_Opt_In__c;
                }
                */
            return customerPhone;
        }
    
        private List<FSL_JSonParserWorkOrder.Emails> PopulateCustomerEmails() {
            List<FSL_JSonParserWorkOrder.Emails> customerEmails = new List<FSL_JSonParserWorkOrder.Emails>();
            customerEmails.add( PopulateCustomerEmail() );
            return customerEmails;
        }
    
        private FSL_JSonParserWorkOrder.Emails PopulateCustomerEmail() {
            FSL_JSonParserWorkOrder.Emails customerEmail = new FSL_JSonParserWorkOrder.Emails();
    
            //customerEmail.emailType = contact.Email_Type__c;
            //customerEmail.address = contact.Email;
            
            return customerEmail;
        }

        private FSL_JSonParserWorkOrder.Payment PopulatePayment() {
            System.debug(LoggingLevel.DEBUG,'PopulatePayment entered');
            FSL_JSonParserWorkOrder.Payment payment = new FSL_JSonParserWorkOrder.Payment();

            //payment.required = !String.isBlank(caseObject.Impairment__c) && 
                                 //caseObject.Impairment__r.Payment_Required__c && caseObject.Impairment_COD_Payment__c;
            //Bastine for ERS-232239 no need to veify Impairment field on Case to mark Payment Required on WO.
            payment.required = caseObject.Impairment_COD_Payment__c;
            payment.paymentType = '';

            switch on caseObject.Case_Membership_Level__c {
                when 'Basic', 'Classic RV' {
                    payment.codes = '100001000B0XX20';
                }
                when 'Plus', 'Plus RV' {
                    payment.codes = '100001000B0XX34';
                }
                when 'Premier', 'Premier RV' {
                    payment.codes = '100001000B0XX37';
                }                
                when else {
                    payment.codes = '100001000B0XX20';
                }
            } 

            return payment;
        }

        private FSL_JSonParserWorkOrder.Vehicle PopulateVehicle() {
            System.debug(LoggingLevel.Debug, 'PopulateVehicle entered');
            FSL_JSonParserWorkOrder.Vehicle vehicle = new FSL_JSonParserWorkOrder.Vehicle();
            
            vehicle.id = caseObject.Member_Vehicle__c;
            //On Case creation, currently we only set Member_Vehicle_Type ( PS (Passenger Car/Truck)), we also need to set the ACG_Vehicle_Type (PS) because
            //On WorkOrder, we are saving (PS)
            vehicle.vehicleType = (caseObject.ACG_Vehicle_Type__c == null ? 'PS' : caseObject.ACG_Vehicle_Type__c);
            if(!String.ISBLANK(caseObject.ACG_Year__c)) {
                vehicle.year = Integer.valueof(caseObject.ACG_Year__c.trim());
            }
            vehicle.make = (caseObject.ACG_Make__c == null ? '' : caseObject.ACG_Make__c);
            vehicle.model = (caseObject.ACG_Model__c == null ? '' : caseObject.ACG_Model__c);
            vehicle.trim = (caseObject.Vehicle_Trim_Level__c == null ? '' : caseObject.Vehicle_Trim_Level__c);
            vehicle.color = (caseObject.ACG_Color__c == null ? '' : caseObject.ACG_Color__c);
            vehicle.driveType = (caseObject.Vehicle_Drive_Type__c == null ? '' : caseObject.Vehicle_Drive_Type__c);
            vehicle.vin = (caseObject.ACG_VIN__c == null ? '' : caseObject.ACG_VIN__c);
            vehicle.tag = (WORequestJson.vehicle?.licensePlateIdentifier == null ? '' : WORequestJson.vehicle?.licensePlateIdentifier);
            vehicle.state = (WORequestJson.vehicle?.licensePlateState == null ? '' : WORequestJson.vehicle?.licensePlateState);
            vehicle.odometer = (caseObject.Vehicle_Odometer__c == null ? 0 : (Integer)caseObject.Vehicle_Odometer__c);
            vehicle.fuelType = (caseObject.Vehicle_Fuel_Type__c == null ? '' : caseObject.Vehicle_Fuel_Type__c);
            vehicle.specialEquipmentNeeds = (WORequestJson.vehicle?.specialEquipmentNeeds == null ? '' : WORequestJson.vehicle?.specialEquipmentNeeds);

            if(!String.ISBLANK(WORequestJson.vehicle?.rvClass) || WORequestJson.vehicle?.rvLength > 0) {
                vehicle.rvInfo = new FSL_JSonParserWorkOrder.RvInfo();
                vehicle.rvInfo.rvClass = (WORequestJson.vehicle?.rvClass == null ? '' : WORequestJson.vehicle?.rvClass);
                vehicle.rvInfo.length = (WORequestJson.vehicle?.rvLength == null ? 0 : WORequestJson.vehicle?.rvLength);
            }

            if(!String.ISBLANK(WORequestJson.vehicle?.trailerHitchType) || WORequestJson.vehicle?.trailerLength > 0) {
                vehicle.trailerInfo = new FSL_JSonParserWorkOrder.TrailerInfo();
                vehicle.trailerInfo.hitchType = (WORequestJson.vehicle?.trailerHitchType == null ? '' : WORequestJson.vehicle?.trailerHitchType);
                vehicle.trailerInfo.length = (WORequestJson.vehicle?.trailerLength == null ? 0 : WORequestJson.vehicle?.trailerLength);
            }
    
            return vehicle;
        }

         private FSL_JSonParserWorkOrder.Service PopulateService() {
            System.debug( LoggingLevel.DEBUG, 'PopulateService entered' );
            FSL_JSonParserWorkOrder.Service service = new FSL_JSonParserWorkOrder.Service();

            service.collision = caseObject.ACG_Collision__c;  
            service.timezoneId = (WORequestJson?.timezoneId == null ? '' : WORequestJson?.timezoneId);
            service.timezoneOffset = caseObject.Member_Location_TZ_Offset__c;
            service.redFlag = (WORequestJson?.redFlag == null ? false : (WORequestJson?.redFlag.toLowercase() == 'true' ? true : false));
            service.collision = (WORequestJson?.collision == null ? false : (WORequestJson?.collision.toLowercase() == 'true' ? true : false));
			service.totalMileage = caseObject.Total_Mileage__c; //EMI:SSFI-605-11-05-2024
            service.priorityCode = caseObject.priority;
            if(String.isBlank(caseObject.ACG_Priority_Code__c) && String.isNotBlank(WORequestJson?.priorityCode) && WORequestJson?.priorityCode.startsWith('P')) //AGB 2/17/2025 for SSFI-893
            {
                Schema.DescribeSObjectResult objDescribe = caseObject.getSObjectType().getDescribe();
                Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('ACG_Priority_Code__c').getDescribe();
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    if (entry.getLabel().toLowerCase().contains(WORequestJson?.priorityCode.toLowerCase())) {
                        service.priorityDescription = entry.getValue();
                        break; // Stop looping after the first match	
                    }
                }
            }
            else
            {
            	service.priorityDescription = caseObject.ACG_Priority_Code__c; //original line
            } //end AGB 2/17/2025 for SSFI-893
            //service.callType = WORequestJson?.callType; //EMI - commented as per PROD MEMBER issue on 6/07/2024
            service.callType = (WORequestJson?.callType == null ? 'MEMBER' : WORequestJson?.callType);
           
            
            /*String priorityCode = (caseObject.priority != null ? caseObject.priority.toUpperCase() : caseObject.priority);
            switch on priorityCode {
                when 'MEDIUM' {
                    service.legacyPriorityCode = 'NA';
                }
                when 'CRITICAL' {
                    service.legacyPriorityCode = 'P1';
                }
                when 'HIGH' {
                    //Added by Ali for ERS-231229 Start
                    if(caseObject.Tow_Request_Reason__c == 'Collision') {
                        service.legacyPriorityCode = 'P6';
                        service.callType = 'Accident'; //hardcoding this for ERS-231229, Need to work on design for this
                    } else {
                        service.legacyPriorityCode = 'P3';
                    }
                    //Added by Ali for ERS-231229 Stop
                }                
                when 'LOW' {
                    service.legacyPriorityCode = 'R0';
                }                                
                when else {
                    service.legacyPriorityCode = 'NA';
                }
             }  */                      

            service.facility = PopulateFacility();
            service.ServiceLocations = PopulateServiceLocations();
            service.numberOfPassengers = (Integer)caseObject.Number_Of_Passengers__c;
            service.needsFlatbed = caseObject.Flatbed_Required__c;
            service.useYourLongTowEntitlement = caseObject.Use_your_long_tow_entitlement__c;
            service.useHomeLockoutEntitlement = caseObject.Use_Home_Lock_Entitlement__c;
            service.repairShopId = caseObject.Repair_Shop__c;
            service.totalMileage = caseObject.Total_Mileage__c;
            if(!caseObject.Impairment_COD_Payment__c && !caseObject.Impairment_Supervisor_Override__c && caseObject.Member_Vehicle_Type__c != 'BK (Bicycles)') { // AGB 5/1/24 - SFI-540 Bicycle Service - Member Entitlements
                service.chargeEntitlement = true;
            }
            else {
                service.chargeEntitlement = false;
            }
            List<WorkType> workTypes = [SELECT Name FROM WorkType WHERE Id=:caseObject.ACG_Work_Type__c LIMIT 1];
            if(!workTypes.isEmpty()) {
                service.troubleCodes = new List<FSL_JSonParserWorkOrder.TroubleCodes>();
                FSL_JSonParserWorkOrder.TroubleCodes trblCode = new  FSL_JSonParserWorkOrder.TroubleCodes();
                
                trblCode.troubleCodeType = 'PROBLEM';
                trblCode.code = caseObject.T_Code__c;
                trblCode.description = workTypes[0].Name;
                service.troubleCodes.add(trblCode);
    
                trblCode = new  FSL_JSonParserWorkOrder.TroubleCodes();
                trblCode.troubleCodeType = 'PACESETTER';
                trblCode.code = caseObject.Pacesetter_Code__c;
                trblCode.description = workTypes[0].Name;
    
                service.troubleCodes.add(trblCode);
            }
  
            service.memberPhone = caseObject.ACG_Case_Contact_Number__c;
            populateServicePta ( service, caseObject );
 
            return service;
        }

        @TestVisible
        private void populateServicePta ( FSL_JSonParserWorkOrder.Service service, Case caseObject ) {

            //System.debug( LoggingLevel.DEBUG, 'populateServicePta entered' );
    
            service.status = new FSL_JSonParserWorkOrder.Status ();
            DateTime ptaDT;
            if ( caseObject.ACG_Requested_Appointment_Date__c == Null ) {
                // Assign PTA for the normal non-scheduled call, i.e. a standard call. In this case, the default PTA is
                // is now() + default transitTime for state/service type.
                String state = caseObject.Vehicle_Location_State__c;
                String svc = caseObject.ACG_Service_Type__c;
                service.status.waitTime = DefaultStatePTA.getDefaultStatePTA ( state, svc );
                //System.debug( LoggingLevel.DEBUG, 'populateServicePta. waitTime= ' + service.status.waitTime );    
                ptaDT = DefaultStatePTA.getPTADateTime ( state, svc );
                service.status.pta = JSON.serialize ( ptaDT );

            } else {
                // Assign PTA for the scheduled appointment
                //if ( caseObject.PTA__c != null ) {
                //   ptaDT = caseObject.PTA__c;
                //} else {
                   ptaDT = FSL_Case.getPTAFromCaseAppointmentAsOrgTime ( caseObject );
                //}

                // By setting the service.appointmentTime, the value will propogate to the workorder's
                // Non_Emergency_Appointment_Time__c value which will ALSO set the value for the 
                // subsequent service EarliestStartTime
                service.appointmentTime = JSON.serialize ( ptaDT );
                service.status.waitTime = 60;
                service.status.pta = JSON.serialize ( ptaDT );
            }
            //System.debug( LoggingLevel.DEBUG, 'populateServicePta. service.status.pta= ' + service.status.pta );
        }

        private FSL_JSonParserWorkOrder.Facility PopulateFacility() {
            System.debug( LoggingLevel.DEBUG, 'PopulateFacility entered' );
            FSL_JSonParserWorkOrder.Facility facility = new FSL_JSonParserWorkOrder.Facility();
    
            facility.foiType = (WORequestJson?.facilityType == null ? '' : WORequestJson?.facilityType.left(18));
            facility.name = (WORequestJson?.facilityName == null ? '' : WORequestJson?.facilityName);
            facility.id = (WORequestJson?.facilityId == null ? '' : WORequestJson?.facilityId.left(18));
    
            return facility;
        }

        private List<FSL_JSonParserWorkOrder.ServiceLocations> PopulateServiceLocations() {
            System.debug( LoggingLevel.DEBUG, 'PopulateServiceLocations entered' );
            List<FSL_JSonParserWorkOrder.ServiceLocations> serviceLocations = new List<FSL_JSonParserWorkOrder.ServiceLocations>();

            serviceLocations.add(PopulateBreakdownServiceLocation());
            serviceLocations.add(PopulateTowDestServiceLocation());

            return serviceLocations;
        }

        private FSL_JSonParserWorkOrder.ServiceLocations PopulateBreakdownServiceLocation() {
            System.debug( LoggingLevel.DEBUG, 'PopulateBreakdownServiceLocation entered' );
            FSL_JSonParserWorkOrder.ServiceLocations serviceLocation = new FSL_JSonParserWorkOrder.ServiceLocations();

            serviceLocation.serviceLocationType = 'BREAKDOWN';
            serviceLocation.foi = PopulateFoi();

            // ERS-230031 Combine the Vehicle Location Type/Driver Direction if they both has values           
            if(caseObject.ACG_Vehicle_Location_Type__c != null && caseObject.ACG_Driving_Directions__c != null){
                serviceLocation.driverDirections = caseObject.ACG_Vehicle_Location_Type__c + '/' + caseObject.ACG_Driving_Directions__c;
            }
            else{
                serviceLocation.driverDirections = caseObject.ACG_Vehicle_Location_Type__c != null ? caseObject.ACG_Vehicle_Location_Type__c : caseObject.ACG_Driving_Directions__c;               
            }
            
            return serviceLocation;
        }

        private FSL_JSonParserWorkOrder.ServiceLocations PopulateTowDestServiceLocation() {
            System.debug( LoggingLevel.DEBUG, 'PopulateTowDestServiceLocation entered' );
            FSL_JSonParserWorkOrder.ServiceLocations serviceLocation = new FSL_JSonParserWorkOrder.ServiceLocations();

            serviceLocation.serviceLocationType = 'TOW_DESTINATION';
            serviceLocation.mileageCalculated = (WORequestJson?.totalMileage == null ? null : WORequestJson?.totalMileage.intValue());
            serviceLocation.foi_towDest = PopulateFoiTowDest();
    
            return serviceLocation;
        }

        private FSL_JSonParserWorkOrder.Foi PopulateFoi() {
            System.debug(LoggingLevel.Debug, 'PopulateFoi entered');
            FSL_JSonParserWorkOrder.Foi foi = new FSL_JSonParserWorkOrder.Foi();

            foi.location = PopulateBreakdownLocation();
            foi.contacts = PopulateContacts();
    
            return foi;
        }

        private List<FSL_JSonParserWorkOrder.Contacts> PopulateContacts() {
            System.debug(LoggingLevel.Debug, 'PopulateContacts entered');

            List<FSL_JSonParserWorkOrder.Contacts> contacts = new List<FSL_JSonParserWorkOrder.Contacts>();
            FSL_JSonParserWorkOrder.Contacts contact = new FSL_JSonParserWorkOrder.Contacts();
    
            contacts.add( contact );

            return contacts;
        }

        private FSL_JSonParserWorkOrder.ServiceLocations_Location PopulateBreakdownLocation() { 
            System.debug(LoggingLevel.Debug, 'PopulateBreakdownLocation entered');
            FSL_JSonParserWorkOrder.ServiceLocations_Location breakdownLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();

            breakdownLocation.mileMarker = '';      // PLF : TEMP HACK 2022.08.14
            breakdownLocation.grid = '';            // PLF : TEMP HACK 2022.08.14
            breakdownLocation.zone = '';            // PLF : TEMP HACK 2022.08.14

            FSL_JSonParserWorkOrder.Address address = new FSL_JSonParserWorkOrder.Address();
            address.street = caseObject.Vehicle_Location_Street__c;
            if(String.isEmpty(caseObject.Vehicle_Location_Street__c) && caseObject.ACG_Vehicle_Location_Address__c != null){
                address.street = caseObject.ACG_Vehicle_Location_Address__c.substringBefore(',');
            }
            address.city = caseObject.Vehicle_Location_City__c;
            address.state = caseObject.Vehicle_Location_State__c;
            address.postalCode = caseObject.Vehicle_Location_Postal_Code__c;
            address.country = caseObject.Vehicle_Location_Country__c;

            breakdownLocation.address = address;
            breakdownLocation.latitude = caseObject.Vehicle_Geolocation__Latitude__s;
            breakdownLocation.longitude = caseObject.Vehicle_Geolocation__Longitude__s;           
            breakdownLocation.landmark = caseObject.Landmark__c;                   
            //ERS-230031 Add the Location Code routine
            PopulateLocationCode(breakdownLocation); 

            return breakdownLocation;
        }
        
        private void PopulateLocationCode(FSL_JSonParserWorkOrder.ServiceLocations_Location breakdownLocation) {
                      
            breakdownLocation.locationCode = '';

            if(caseObject.ACG_Vehicle_Location_Type__c != null)
            {
                // Get the BLCode Custom Meta
                List<BLCODE__mdt> BLCodes = [                    
                    SELECT DeveloperName
                    FROM   BLCODE__mdt
                    WHERE  VehicleLocationType__c = :caseObject.ACG_Vehicle_Location_Type__c 
                    ];

                if (!BLCodes.isEmpty()) {    
                    // Map the Vehicle Location Type to Location Code              
                    breakdownLocation.locationCode = BLCodes[0].DeveloperName;                
                }
            }            
        }

        private FSL_JSonParserWorkOrder.Foi_TowDest PopulateFoiTowDest() {
            System.debug(LoggingLevel.Debug, 'PopulateFoiTowDest entered');
            FSL_JSonParserWorkOrder.Foi_TowDest foi_towDest = new FSL_JSonParserWorkOrder.Foi_TowDest();
    
            foi_towDest.location = PopulateTowDestLocation();
            foi_towDest.Name   = caseObject.Tow_Destination_Name__c ;
    
            return foi_towDest;
        }        

        private FSL_JSonParserWorkOrder.Location_TowDest PopulateTowDestLocation() { 
            System.debug(LoggingLevel.Debug, 'PopulateTowDestLocation entered');
            FSL_JSonParserWorkOrder.Location_TowDest towDestLocation = new FSL_JSonParserWorkOrder.Location_TowDest();

            towDestLocation.latitude = caseObject.Tow_Geolocation__Latitude__s;
            towDestLocation.longitude = caseObject.Tow_Geolocation__Longitude__s;
            towDestLocation.landmark = caseObject.Landmark__c;
            towDestLocation.address = PopulateTowAddress();

            return towDestLocation;
        }

        private FSL_JSonParserWorkOrder.Address_TowAddress PopulateTowAddress() { 
            System.debug(LoggingLevel.Debug, 'PopulateTowAddress entered');
            FSL_JSonParserWorkOrder.Address_TowAddress towAddress = new FSL_JSonParserWorkOrder.Address_TowAddress();

            towaddress.addressType = '';
            
            PopulateTowAddress_Street(towAddress);
            towAddress.city = caseObject.Tow_Destination_City__c;
            towAddress.state = caseObject.Tow_Destination_State__c;
            towAddress.country = caseObject.Tow_Destination_Country__c;
            towAddress.postalCode = caseObject.Tow_Destination_Postal_Code__c;
            towAddress.full ='';
            if (!String.isBlank(towAddress.streetNumber)) {
                towAddress.full += towAddress.streetNumber + ' ';
            }
            if (!String.isBlank(towAddress.streetName)) {
                towAddress.full += towAddress.streetName + ' ';
            }
            towAddress.full += towAddress.city + ' ' + towAddress.state + ' ' + towAddress.country + ' ' +  towAddress.postalCode;          

            return towAddress;
        }

        private void PopulateTowAddress_Street(FSL_JSonParserWorkOrder.Address_TowAddress towAddress) {

            System.debug(LoggingLevel.Debug, 'PopulateTowAddress_Street entered');

            if (caseObject.Tow_Destination_Street__c != null) {

                string street = (caseObject.Tow_Destination_Street__c == null ? '' : caseObject.Tow_Destination_Street__c);
                
                String[] streetList =  street.split(' ');
                towAddress.streetNumber = (streetList.size() > 0 ? (streetList[0].isNumeric() ? streetList[0] : '') : '');
                towAddress.streetName = (street != null ? street.substring(towAddress.streetNumber.length()).trim() : '');
                towAddress.crossStreet = towAddress.streetName;
            } else {
                towAddress.streetNumber = '';
                towAddress.streetName = '';
                towAddress.crossStreet = '';
            }
        }
    }

    // *********************************************
    // * Application Log
    // *********************************************
    public class CaseToWorkOrderLog extends FSL_ApplicationLog.ApplicationLog {
        public CaseToWorkOrderLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'CallCreate';
            appLog.DateTime__c = System.now();
            appLog.Api_Name__c = 'Case To WorkOrder';
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void setDefaultApplicationLogFields(String operation, String apiName) {
            appLog.Operation__c = operation;
            appLog.Api_Name__c = apiName;            
        }

        public void logFailure(FSL_JSonParserWorkOrder jsonWO, String message, String operation, String originalRequest) {
            appLog.Api_Name__c = 'Case To WorkOrder';
            appLog.Operation__c = 'CallCreate';
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message;
            if ( jsonWO != null && jsonWO.calls != null && !jsonWO.calls.isEmpty()) {
                applog.call_Id__c = jsonWO.calls[0].callId;
                appLog.Request_Body__c = JSON.serialize(jsonWO); 
            }
            else {
                appLog.Request_Body__c = originalRequest;
            }
            
        }

        public void logSuccess(FSL_JSonParserWorkOrder jsonWO, String message) {
            logSuccess(jsonWO, message, null);
        }

        public void logSuccess(FSL_JSonParserWorkOrder jsonWO, String message, WorkOrder wo) {
            appLog.Api_Name__c = 'Case To WorkOrder';
            appLog.Operation__c = 'CallCreate';
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message;
            applog.call_Id__c = jsonWO.calls[0].callId;
            appLog.Request_Body__c = JSON.serialize(jsonWO); 
            if ( wo != null ) {
                appLog.Work_Order__c = wo.Id;
            }
        }
    }
}