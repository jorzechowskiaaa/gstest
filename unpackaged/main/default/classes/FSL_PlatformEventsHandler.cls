/**
 *  Helper class for creating Platform Events that are subscribed to by AAA ESB.
 */ 
public without sharing class FSL_PlatformEventsHandler {
    /**
     *      @purpose    -   Create platform of call details after Intake
     *                      
     *      @NOTE       -   This method is bulkified, but cannot be called in an After Insert Trigger
     *                      because the related objects are inserted after the Work Order is created.
     * 
     *                      This may be moved to the Service Appointment Trigger in the future,
     *                      if it needs to be decoupled from the Intake class
     *                           
     */
    public static void createWorkOrderEvent(List<WorkOrder> wolist) {
        Set<Id> serviceTerritoryIDList =  new Set<Id>(); 
        Set<Id> contactIDSet = new Set<Id>();
        Set<Id> memberVehicleIDList =  new Set<Id>(); 
        Set<String> clubcodeList = new Set<String>(); //AGB 6/16/2025 for SSFI-1183
        Map<Id, WorkOrder_Creation_Event__e> workOrderIdToEventMap = new Map<Id, WorkOrder_Creation_Event__e>();
        Map<Id, List<FSL_TroubleCode__c>> workOrderIdToTroubleCodeMap = new Map<Id, List<FSL_TroubleCode__c>>();
        
        for (WorkOrder wo : wolist) {
            serviceTerritoryIDList.add(wo.ServiceTerritoryID);
            contactIDSet.add(wo.ContactID);
            memberVehicleIDList.add(wo.Member_Vehicle__c);
            clubcodeList.add(wo.Call_Origin_OrgCode__c); //AGB 6/16/2025 for SSFI-1183
        }
        
		List<FSL_Member_Vehicle__c> memberVehicles = [
            SELECT 
                Id, 
                Vehicle_Color__c, 
                Vehicle_Make__c, 
                Vehicle_Model__c, 
                Vehicle_Year__c, 
                Work_Order__c, 
                Maximum_Mileage__c,
                Vehicle_Plate__c 
            FROM FSL_Member_Vehicle__c 
            WHERE Id IN :memberVehicleIDList
        ];
        Map<Id, FSL_Member_Vehicle__c> workOrderIdToVehicleMap = new Map<Id, FSL_Member_Vehicle__c>(memberVehicles);  
        
        // create member map
        List<Contact> members = [
            SELECT 
                Id, 
                Membership_Org__c, 
                Membership_Type__c, 
                Membership_Org_Phone__c, 
                Membership_OrgCode__c, 
                Membership_Program__c, 
                Membership_Sponsor__c
            FROM Contact 
            WHERE Id IN :contactIDSet
        ];
        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>(members);

        // Create Service Territory Map
        List<ServiceTerritory> territoryList = [
            SELECT Id, Facility_Number__c, Name 
            FROM ServiceTerritory 
            WHERE Id IN :serviceTerritoryIDList
        ];        
        Map<Id, ServiceTerritory> territoryIdToTerritoryMap = new Map<Id, ServiceTerritory>(territoryList);

        // Create Trouble Code Map
        List<FSL_TroubleCode__c> tCodeList = [
            SELECT 
                Id, Code__c, Description__c, Type__c, Work_Order__c 
            FROM FSL_TroubleCode__c 
            WHERE Work_Order__c IN :wolist
        ];   

        for (FSL_TroubleCode__c tCode : tCodeList) {
            List<FSL_TroubleCode__c> mappedTCodes = workOrderIdToTroubleCodeMap.get(tCode.Work_Order__c);

            if (mappedTCodes == null) {
                mappedTCodes = new List<FSL_TroubleCode__c>();
            }

            mappedTCodes.add(tCode);
            workOrderIdToTroubleCodeMap.put(tCode.Work_Order__c, mappedTCodes);
        }

        //Club_Name_Mappings__mdt //AGB 6/16/2025 for SSFI-1183
        List<Club_Name_Mappings__mdt> clubList = [
            SELECT Id,RAP_Phone__c, Club_Code__c
            FROM Club_Name_Mappings__mdt 
            WHERE Club_Code__c IN :clubcodeList
        ];        
        Map<string, string> clubcodeMap = new Map<string, string>();
        for(Club_Name_Mappings__mdt rec : clubList)
        {
			clubcodeMap.put(rec.Club_Code__c, rec.RAP_Phone__c);            
        }
        //end Club_Name_Mappings__mdt //AGB 6/16/2025 for SSFI-1183

        for (WorkOrder wo : wolist) {
            WorkOrder_Creation_Event__e WoSU = new WorkOrder_Creation_Event__e();
            //Removing - Filter to Generate PE for SF Origin WOs - RAP/DRR/CallMover Update, ODS
            if (isEligibleCall(wo)) {   //&& wo.Call_Source__c == 'Salesforce'
                String callKey = '';
                String externalId = wo.External_Id__c;
                String woNum = wo.WorkOrderNumber;
                Boolean isSalesforce = wo.Call_Source__c == 'Salesforce';
                Boolean externalIdNull = externalId == null;
                
                if (!externalIdNull) {
                    callKey = externalId.replace('null', woNum);
                }

                WoSU.D3_CallId__c = isSalesforce ? wo.WorkOrderNumber : wo.Call_Id__c;
                WoSU.D3_CallDate__c = wo.Call_Date__c;
                WoSU.D3_CallKey__c = isSalesforce ? callKey : externalId;
                WoSU.EventTime__c = System.now();
                WoSU.WorkOrder_CallType__c = wo.Call_Type__c;
                WoSU.WorkOrder_PTA__c = wo.Pta__c;
                WoSU.WorkOrder_Status__c = wo.Status;
                WoSU.WorkOrder_WaitTime__c = String.valueOf(wo.Wait_Time__c);

                // Facility / Territory Details
                ServiceTerritory WoST = territoryIdToTerritoryMap.get(wo.ServiceTerritoryID);

                if (WoST != null) {
                    WoSU.Facility_Id__c = WoST.Facility_Number__c; 
                    WoSU.Facility_Name__c = WoST.Name;
                }

                // breakdown location
                WoSU.BL_Address__c = wo.street + ', ' + wo.city + ', ' + wo.state + ', ' + wo.postalCode;
                WoSU.BL_City__c = wo.city;
                WoSU.BL_Latitude__c = wo.latitude;
                WoSU.BL_Longitude__c = wo.longitude;
                WoSU.BL_State__c = wo.state;
                WoSU.BL_Street__c = wo.street;
                WoSU.BL_Zip__c = wo.postalCode;

                // tow location
                WoSU.TD_Address__c =  wo.Tow_Street__c + ', ' + wo.Tow_City__c + ', ' + wo.Tow_State__c + ', ' + wo.Tow_Postal_Code__c;
                WoSU.TD_City__c = wo.Tow_City__c;
                WoSU.TD_Latitude__c = wo.Tow_Location__Latitude__s;
                WoSU.TD_Longitude__c = wo.Tow_Location__Longitude__s;
                WoSU.TD_State__c = wo.Tow_State__c;
                WoSU.TD_Street__c = wo.Tow_Street__c;
                WoSU.TD_Zip__c = wo.Tow_Postal_Code__c;

                // RAP Information
                WoSU.RAP_CallId__c = wo.RAP_Case_Number__c;
                WoSU.Contact_OriginalMemberId__c = wo.Original_Member_Id__c; //wo.RAP_Case_Number__c; PR893288-4432
                
                Contact WOCM = contactIdToContactMap.get(wo.ContactID);
                
                if (WOCM != null) {
                    //WoSU.RAP_Code__c = WOCM.Membership_OrgCode__c; //AGB 6/16/2025 for SSFI-1183
                    //WoSU.RAP_Name__c = WOCM.Membership_Org__c; //AGB 6/16/2025 for SSFI-1183
                    //WoSU.RAP_Phone__c = WOCM.Membership_Org_Phone__c; //AGB 6/16/2025 for SSFI-1183
                    WoSU.RAP_Program__c = WOCM.Membership_Program__c;
                    WoSU.RAP_Sponsor__c = WOCM.Membership_Sponsor__c;
                }

                // Vehicle Information (from Map)
                if (Test.isRunningTest()) {
                    FSL_Member_Vehicle__c WOVM = new FSL_Member_Vehicle__c(
                        Vehicle_Color__c = 'Black',
                        Vehicle_Make__c='Suzuki',
                        Vehicle_Model__c='Ciaz',
                        Vehicle_Year__c='2022',
                        Maximum_Mileage__c=10
                    );
                } else {
                    FSL_Member_Vehicle__c WOVM = workOrderIdToVehicleMap.get(wo.Member_Vehicle__c);
                    if (WOVM != null) {
                        WoSU.Vehicle_Color__c = WOVM.Vehicle_Color__c;
                        WoSU.Vehicle_Make__c = WOVM.Vehicle_Make__c;
                        WoSU.Vehicle_Model__c = WOVM.Vehicle_Model__c;
                        WoSU.Vehicle_Year__c = WOVM.Vehicle_Year__c;
                        if(wo.Call_Type__c == 'RAP') //AGB 6/16/2025 for SSFI-1183 RAP
                		{
                        	WoSU.RAP_MaxMileage__c = String.valueOf(WOVM.Maximum_Mileage__c);
                        } //end AGB 6/16/2025 for SSFI-1183 RAP
                    } 
                }

                //Membership Type
                if (WOCM?.Membership_Type__c != null) {
                    String mbrType = WOCM.Membership_Type__c;
                    Boolean hasMember = mbrType.toUpperCase().contains('MEMBER');

                    WoSU.Contact_MembershipType__c = hasMember ? 'MEMBER' : mbrType;
                }

                List<FSL_TroubleCode__c> tCodes = workOrderIdToTroubleCodeMap.get(wo.Id);

                if (tCodes != null && !tCodes.isEmpty()) {
                    for (FSL_TroubleCode__c tCode : tCodes) {
                        if (tCode.Type__c == 'PROBLEM') {
                            WoSU.Problem_Code__c = tCode.Code__c;
                            WoSU.Problem_Desc__c = tCode.Description__c;
                        } else if (tCode.Type__c == 'PACESETTER') {
                            WoSU.Pacesetter_Code__c = tCode.Code__c;
                            WoSU.Pacesetter_Desc__c = tCode.Description__c;
                        }
                    }
                }

                if (
                    !String.isBlank(wo.External_Id__c) 
                    && wo.External_Id__c.contains('-')
                ) {
                    WoSU.SourceSystem_Id__c = wo.External_Id__c.split('-')[0];
                }

                WoSU.SourceSystem_OrgCode__c = wo.Call_Origin_OrgCode__c;
                WoSU.SourceSystem_OrgName__c = wo.Call_Origin_OrgName__c;
                
                WoSU.WorkOrder_ChannelType__c = wo.WorkOrder_ChannelType__c; //AGB 6/16/2025 for SSFI-1183
				WoSU.Timezone_Id__c = wo.Timezone_Id__c == null ? 'America/New_York' : wo.Timezone_Id__c; //AGB 6/16/2025 for SSFI-1183
                WoSU.Timezone_Offset__c = wo.Timezone_Offset__c; //AGB 6/16/2025 for SSFI-1183
				WoSU.Pacesetter_Code__c = wo.Case_Pacesetter_Code__c; //AGB 6/16/2025 for SSFI-1183
               	WoSU.Problem_Code__c  = wo.Case_T_Code__c; //AGB 6/16/2025 for SSFI-1183
                WoSU.BL_City__c  = wo.City; //AGB 6/16/2025 for SSFI-1183
                WoSU.BL_State__c  = wo.State; //AGB 6/16/2025 for SSFI-1183
                WoSU.SourceSystem_Id__c  = wo.Call_Origin_OrgCode__c; //AGB 6/16/2025 for SSFI-1183
                WoSU.SourceSystem_OrgName__c  = wo.Call_Origin_OrgName__c; //AGB 6/16/2025 for SSFI-1183
                if(wo.Call_Type__c == 'RAP')
                {
                    WoSU.RAP_Name__c  = wo.Call_Origin_OrgName__c; //AGB 6/16/2025 for SSFI-1183 RAP
                    WoSU.RAP_Phone__c  = clubcodeMap.get(wo.Call_Origin_OrgCode__c); //AGB 6/16/2025 for SSFI-1183 RAP
                    //WoSU.RAP_MaxMileage__c  = wo.Maximum_Mileage__c; //AGB 6/16/2025 for SSFI-1183 RAP
                    WoSU.RAP_Goodwill__c  = wo.Goodwill_Indicator__c ? 'True' : 'False'; //AGB 6/16/2025 for SSFI-1183  RAP  
                }
                workOrderIdToEventMap.put(wo.Id, WoSU);
            }
        }
        
        if (!workOrderIdToEventMap.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(workOrderIdToEventMap.Values());

            if (results[0].isSuccess()) {
                FSL_ApplicationLogCreator.insertWorkOrderCreationEventLog(workOrderIdToEventMap);
            }
        }  
    }    

    /**
     *      @purpose    -   Create a Platform Event containing the invite URL from
     *                      Glympse when the field is populated
     */
    public static void createStatusTrackingEvent(List<ServiceAppointment> salist) {
        Map<Id, Service_Tracking__e> SaIdToEventMap  = new Map<Id, Service_Tracking__e>();
        Map<Id, ServiceAppointment> saIdToSaMap= new Map<Id, ServiceAppointment>(salist);
        Set<Id> WorkorderId = new Set<Id>();  
        
        for (ServiceAppointment sa : salist) {
            workOrderId.add(sa.ParentRecordId);            
        }
       
        // added RecordTypeId
        List<WorkOrder> woreclist = [
            SELECT 
                Id,
                Status,
                Call_Id__c,
                Call_Date__c,
                Call_Source__c,
                Call_Type__c,
                Call_Origin_OrgCode__c,
                Repair_Shop__c,
                Repair_Shop__r.Integration_Id__c, 
                Call_Origin_OrgName__c,
                ServiceTerritoryId, 
                ServiceTerritory.Name,
                ServiceTerritory.Facility_Number__c, 
                External_ID__c,
                PTA__c,
                Wait_Time__c
            FROM WorkOrder 
            WHERE Id IN :workOrderId
        ];

        // create map of Service Appointment to Work Order
        Map<Id, WorkOrder> woIdToWOMap = new Map<Id, WorkOrder>(woreclist);
        Id breakDownRecordTypeId = 
            Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByName()
                .get('Breakdown')
                .getRecordTypeId();
        Id towRecordTypeId = 
            Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByName()
                .get('Tow')
                .getRecordTypeId();
        
        for (ServiceAppointment sa : salist) {
            //Removing - Filter to Generate PE for SF Origin WOs - RAP/DRR/CallMover Update, ODS
            if (isEligibleCall(woIdToWOMap.get(sa.ParentRecordId)) ) {
                Service_Tracking__e ste = new Service_Tracking__e(
                    D3_CallId__c = woreclist[0].Call_Id__c,
                    D3_CallKey__c = woreclist[0].External_Id__c,
                    D3_CallDate__c = woreclist[0].Call_Date__c,
                    EventTime__c = System.now(),
                    SourceSystem_OrgCode__c = woreclist[0].Call_Origin_OrgCode__c,
                    SourceSystem_OrgName__c = woreclist[0].Call_Origin_OrgName__c,
                    WorkOrder_CallType__c = woreclist[0].Call_Type__c,
                    WorkOrder_Status__c = woreclist[0].status
                );
                
                System.debug('Repair Shop' + woreclist[0].Repair_Shop__c);

                if (woreclist[0].Repair_Shop__c != null) {
                    if (woreclist[0].Repair_Shop__r.Integration_Id__c != null) {
                        ste.Repair_Shop__c = woreclist[0].Repair_Shop__r.Integration_Id__c;
                    }
                }
                
                if (woreclist[0].External_Id__c.contains('-')) {
                    ste.SourceSystem_Id__c = woreclist[0].External_Id__c.split('-')[0];
                }

                // ServiceAppointment.RecordTypeId
                if (sa.recordTypeId  == breakDownRecordTypeId ) { 
                    ste.Tracking_Type__c = 'BREAKDOWN_LOCATION' ;
                }

                if (sa.recordTypeId == towRecordTypeId ) { 
                    ste.Tracking_Type__c = 'TOW_DESTINATION' ;
                }
                
                //ERS-230874 Glympse Removal - Part I
                //ste.Tracking_System__c = 'Glympse';
                //if (sa.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c.contains('?')) {
                //    ste.Tracking_Url__c = ste.Tracking_Url__c = sa.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c.split('\\?')[0];
                //} else {
                //    ste.Tracking_Url__c = sa.Glympse_EnRoute__Glympse_EnRoute_Invite_URL__c;
                //}                
                //ste.Tracking_Id__c = String.ValueOf(sa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c);
                
                SaIdToEventMap.put(sa.Id, ste);
            }
        }
          
        System.debug('MapResult ------ TrackMap'+SaIdToEventMap.Values());

        if (!SaIdToEventMap.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(SaIdToEventMap.Values());

            if (results[0].isSuccess()) {
                System.debug('SERVICE-TRACKING-PLATFORM-EVENT: Successfully published event.');

                FSL_ApplicationLogCreator.insertStatusTrackingEventLog(saIdToSaMap,SaIdToEventMap);
            } else {
                for (Database.Error err : results[0].getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }  
    }
   
    /**
     *      @purpose    -   Create a Platform Event for the ESB whenever the Status Changes 
     * 
     */   
    public static void statusUpdatesOnPlatformEvent(List<ServiceAppointment> saList) {
        Id breakDownRecordTypeId = 
            Schema.SObjectType.ServiceAppointment
                .getRecordTypeInfosByName()
                .get('Breakdown')
                .getRecordTypeId();    
        Map<Id, WorkOrder_StatusUpdate__e > woIdToEventMap = new Map<Id, WorkOrder_StatusUpdate__e>();
        Set<Id> workOrderId = new Set<Id>();
        Set<Id> saIDSet = new Set<Id>();
        Map<Id, AssignedResource> woIdToARMap = new Map<Id, AssignedResource>();

        for (ServiceAppointment sa : salist) {
            if (sa.RecordTypeId == breakDownRecordTypeId) {
                workOrderId.add(sa.ParentRecordId);
                saIDSet.add(sa.id);
            }
        }
        
        // Query AssignedResource for Map Creation
        List<AssignedResource> arList = [
            SELECT 
                Id, 
                ServiceAppointmentID, 
                ServiceResourceID, 
                ServiceResource.Primary_Service_Territory__r.Facility_Number__c,  
                ServiceResource.Primary_Service_Territory__r.Name, 
                ServiceResource.Driver_Id__c, 
                ServiceResource.Vehicle__r.Truck_ID__c, 
                ServiceAppointment.ParentRecordID
            FROM AssignedResource 
            WHERE ServiceAppointmentID IN :saIDSet
        ];

        List<WorkOrder> woreclist = [
            SELECT 
                Id,
                Status,
                Call_Id__c,
                Call_Type__c,
                Call_Origin_OrgCode__c,
                Call_Source__c,
                Call_Date__c,
                Call_Origin_OrgName__c,
                ServiceTerritoryId, 
                ServiceTerritory.Name,
                ServiceTerritory.Facility_Number__c, 
                External_ID__c,
                PTA__c,
                Wait_Time__c,
                Is_Tow_WorkType__c,
                Repair_Shop__c,
                Repair_Shop__r.Integration_Id__c,
                (
                    SELECT 
                        Id,
                        Status,
                        SchedStartTime, 
                        ServiceTerritoryID, 
                        ServiceTerritory.Name, 
                        Service_Resource__r.Driver_Id__c,
                        Service_Resource__r.Vehicle__r.Truck_ID__c,
                        Service_Resource__r.Vehicle__r.Name 
                    FROM Serviceappointments
                ) 
            FROM WorkOrder 
            WHERE Id IN :workOrderId
        ];

        for (AssignedResource ar : arList) {
            woIdToARMap.put(ar.ServiceAppointment.ParentRecordID, ar);
        }
        
        System.debug('@@@@@ WorkORder @@@@' + woreclist);
        
        List<WorkOrder_StatusUpdate__e> WoStatusListUpdate = new list<WorkOrder_StatusUpdate__e>(); 

        for (WorkOrder wo : woreclist) {
            //Removing - Filter to Generate PE for SF Origin WOs - RAP/DRR/CallMover Update, ODS
            if (isEligibleCall(wo)) {  // && wo.Call_Source__c == 'Salesforce'
            	string woStatus = getSaStatus(wo);//SSFI-1168 AGB 6/13/25
                if(woStatus != 'Declined' && woStatus != 'Canceled' && woStatus != 'Tow Loaded'){ //SSFI-1168 AGB 6/13/25
                    WorkOrder_StatusUpdate__e WoSU = new WorkOrder_StatusUpdate__e(
                        D3_CallId__c = wo.Call_Id__c,
                        D3_CallDate__c = wo.Call_Date__c,
                        D3_CallKey__c = wo.External_ID__c,
                        WorkOrder_PTA__c = wo.PTA__c,
                        WorkOrder_Status__c = woStatus, //was WorkOrder_Status__c = getSaStatus(wo), no need to call twice SSFI-1168 AGB 6/13/25
                        WorkOrder_WaitTime__c = String.Valueof(wo.Wait_Time__c),
                        SA_ScheduledStart__c = wo.ServiceAppointments[0].SchedStartTime,
                        SourceSystem_Id__c = Label.FSL_SourceClubCode,
                        SourceSystem_OrgCode__c = Label.FSL_SourceClubCode, //wo.Call_Origin_OrgCode__c;
                        SourceSystem_OrgName__c = Label.Club_Name, //wo.Call_Origin_OrgName__c;
                        Type__c = wo.Call_Type__c,
                        EventTime__c = System.now()
                    ); 
                    AssignedResource SRFromMap = woIdToARMap.get(wo.Id);
                    
                    if (SRFromMap != null) {
                        WoSU.Resource_Id__c = SRFromMap.ServiceResource.Driver_Id__c;
                        WoSU.Resource_Truck__c = SRFromMap.ServiceResource.Vehicle__r.Truck_ID__c;
                        WoSU.Facility_Id__c = SRFromMap.ServiceResource.Primary_Service_Territory__r.Facility_Number__c;
                        WoSU.Facility_Name__c= SRFromMap.ServiceResource.Primary_Service_Territory__r.Name;                    
                    }
                    
                    System.debug('Repair Shop' + wo.Repair_Shop__c);
                    
                    if (wo.Repair_Shop__c != null) {
                        if (wo.Repair_Shop__r.Integration_Id__c != null) {
                            WoSU.Repair_Shop__c = wo.Repair_Shop__r.Integration_Id__c;
                        }
                    }
                    
                    woIdToEventMap.put(wo.Id, WoSU);
                }
                else{ //SSFI-1168 AGB 6/13/25
                    System.debug('SSFI-1168 | Skipped Item Status: '+woStatus);    
                } 
            } 
        }

        System.debug('MapResult ------ StatusUpdatesOnPlatformEvent' + woIdToEventMap.Values());
            
        if (!woIdToEventMap.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(woIdToEventMap.values());

            if (results[0].isSuccess()) {
                System.debug('WorkOrder Status Update Platform Event: Successfully published event.');

                FSL_ApplicationLogCreator.insertWorkOrderStatusUpdatePlatformEventLog(woIdToEventMap);
            } else {
                for (Database.Error err : results[0].getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }   
    }

    /**
     *      @purpose    -     Determine if this call is eligible for Platform Event Creation
     */    
    private static Boolean isEligibleCall(WorkOrder wo) {
        FSL_Settings__c rapSetting = FSL_Settings__c.getInstance('RAP Events Only');

        if (wo.Call_Type__c == 'RAP') {
            return true;
        } else if (rapSetting != null && rapSetting.value__c.toLowerCase() == 'true') {
            return false;
        }

        return true;    
    }

    private static String getSaStatus(WorkOrder wo) {
        // Change the WO Status to use the Service Appointment Status
        String saStatus = '';
        
        System.debug('@@@@@ WorkORder @@@@'+wo.ServiceAppointments);
        System.debug('@@@@@ WorkORder @@@@'+wo.ServiceAppointments.size());

        if (wo.Is_Tow_WorkType__c && wo.ServiceAppointments[0].status == 'Tow Loaded') {
            // If the Breakdown SA Status is 'Tow Loaded', and Tow SA still in Dispatched, it means the Tow SA has not been sync up yet
            if (wo.ServiceAppointments[1].status == 'Dispatched' ) {
                saStatus = 'In Tow';
            } else {
                saStatus = wo.ServiceAppointments[1].status;
            }            
        } else {
            saStatus = wo.ServiceAppointments[0].status;        
        }

        System.debug('ESB WorkOrder_Status__c ------ StatusUpdatesOnPlatformEvent: '+ saStatus);

        return saStatus;
    }


    /**
     *      ERS-229371 - Create a Platform Event for Natioanal RAP Listener whenever the Status Changes to Cleared
     */   
    public static void statusClearOnPlatformEvent(List<ServiceAppointment> saList) {
        Map<Id, WorkOrder_Clear__e> woIdToClearEventMap = new Map<Id, WorkOrder_Clear__e>();
        Set<Id> workOrderId = new Set<Id>();
        Set<Id> saIDSet = new Set<Id>();
        Map<Id, AssignedResource> woIdToARMap = new Map<Id, AssignedResource>();

        for (ServiceAppointment sa : salist) {
            workOrderId.add(sa.ParentRecordId);
            saIDSet.add(sa.id);
        }
        
        // Query AssignedResource for Map Creation
        List<AssignedResource> arList = [
            SELECT 
                Id, 
                ServiceAppointmentID, 
                ServiceResourceID, 
                ServiceResource.Driver_Id__c, 
                ServiceResource.Vehicle__r.Truck_ID__c, 
                ServiceAppointment.ParentRecordID
            FROM AssignedResource 
            WHERE ServiceAppointmentID IN :saIDSet
        ];
        
        List<WorkOrder> woreclist = [
            SELECT 
                Id,
                Call_Id__c,
                Call_Origin__c,
                Call_Date__c,
                External_ID__c,
                PTA__c,
                Call_Origin_OrgName__c,
                Call_Origin_OrgCode__c,
                Call_Type__c,
                Call_Source__c,
                WO_Member_Phone_Number__c,
                Contact.Firstname,
                Contact.Lastname,
                Contact.Email,
                Contact.Membership_Type__c,
                Contact.Membership_Sponsor__c,
                Contact.Membership_Program__c,
                Contact.Membership_OrgCode__c,
                Contact.Membership_Org__c,
                Contact.Membership_Level__c,
                Contact.Membership_Status__c,
                Contact.Membership_Since__c,
                Contact.Membership_Id__c,
                Contact.Membership_Expiration_Date__c,
                Contact.Membership_Code__c,
                Contact.Membership_Authorization__c,
                Member_Account__r.ACG_Club__c,
                Member_Account__r.ACG_Club_Name__c,
                Member_Account__r.Member_ID__c,
                RAP_Case_Number__c,
                Original_Member_Id__c,
                Member_Vehicle__r.Vehicle_Year__c,
                Member_Vehicle__r.Vehicle_Type__c,
                Member_Vehicle__r.Vehicle_Tag__c,
                Member_Vehicle__r.Vehicle_State__c,
                Member_Vehicle__r.Vehicle_Model__c,
                Member_Vehicle__r.Vehicle_Make__c,
                Member_Vehicle__r.Vehicle_Plate__c,
                Member_Vehicle__r.Vehicle_Fuel_Type__c,
                Member_Vehicle__r.Vehicle_Drive_Type__c,
                Member_Vehicle__r.Vehicle_Color__c,
                Wait_Time__c,
                Non_Emergency_Appointment_Time__c,
                FSL_Pacesetter__c,
                Resolution_Code__c,
                Collision__c,
                Red_Flag__c,
                Priority_Code__c,
                Number_Of_Passengers__c,
                Needs_Flatbed__c,
                Flatbed_Requested__c,
                Payment_Required__c,
                ServiceTerritory.Name,
                ServiceTerritory.Facility_Number__c,
                Breakdown_Location__Latitude__s,
                Breakdown_Location__Longitude__s,
                Is_Tow_WorkType__c,
                Tow_Location__Latitude__s,
                Tow_Location__Longitude__s,
                Repair_Shop__c,
                Repair_Shop__r.Integration_Id__c,
				WorkOrder_ChannelType__c, //AGB 6/16/2025 for SSFI-1190
            	CDX_Membership_Status__c, //AGB 6/16/2025 for SSFI-1190
            	ServiceContract.AAA_ACA_Membership_Coverage_Level__c, //AGB 6/16/2025 for SSFI-1190
            	Service_Resource__r.Driver_Id__c, //AGB 6/16/2025 for SSFI-1190
            	case.Pacesetter_Code__c, //AGB 6/16/2025 for SSFI-1190
            	Vehicle_Type__c, //AGB 6/16/2025 for SSFI-1190
            	Service_Resource__r.Vehicle__r.Truck_ID__c, //AGB 6/16/2025 for SSFI-1190
            	case.Repair_Shop__r.Integration_Id__c,  //AGB 6/16/2025 for SSFI-1190
                (
                    SELECT Id, Code__c, Type__c 
                    FROM TroubleCodes__r 
                    WHERE Work_Order__c IN :workOrderId
                ),
                (
                    SELECT Id, Policy_Code__c  
                    FROM Policies__r 
                    WHERE Work_Order__c IN: workOrderId
                ),
                (
                    SELECT Id, Product__r.ProductCode 
                    FROM Service_Line_Items__r
                ),
                (
                    SELECT 
                        Id,
                        Status,
                        Cleared_Timestamp__c,
                        Resolution_Code__c,
                        Latitude,
                        longitude,
                        Address_Change_Counter__c,
                        Landmark__c,
                        Street,
                        State,
                        postalcode,
                        country,
                        city,
                        Cross_Street__c,
                        Tow_Destination_Name__c,
                        isBreakdown__c,
                        Subject 
                    FROM ServiceAppointments
                )                                    
            FROM WorkOrder 
            WHERE Id IN :workOrderId
        ];
        
        // Put WO and AR into a MAP
        for (AssignedResource ar : arList) {
            for (WorkOrder wo : woreclist) {
                if (ar.ServiceAppointment.ParentRecordID == wo.Id) {
                    woIdToARMap.put(wo.Id, ar);
                }
            }
        }

        // Start mapping wo to wo clear Platform Event  
        for (WorkOrder wo : woreclist) {
            //Removing - Filter to Generate PE for SF Origin WOs - RAP/DRR/CallMover Update, ODS
            if (isEligibleCall(wo)) { 
                Contact ctc = wo.Contact;
                Boolean isRAP = wo.Call_Type__c == 'RAP'; //Boolean isRAP = wo.Call_Origin__c == 'RAP'; //AGB 6/16/2025 for SSFI-1190
                String mbrType = ctc.Membership_Type__c;
                String mbrExpDate = String.valueOf(ctc.Membership_Expiration_Date__c);

                if (mbrType != null && mbrType.contains('Member')) {
                    mbrType = 'MEMBER';
                }

                WorkOrder_Clear__e woSC = new WorkOrder_Clear__e(
                    // The folloiwing fields are needed per specification
                    D3_CallId__c = wo.Call_Id__c,
                    D3_CallDate__c = wo.Call_Date__c,
                    D3_CallKey__c = wo.External_ID__c,
                    WorkOrder_PTA__c = wo.PTA__c,
                    WorkOrder_Status__c = isRAP ? 'Clear Pending' : 'Cleared', //AGB 6/16/2025 for SSFI-1190
                    Channel_Name__c = wo.Call_Origin_OrgName__c,
                    Channel_Code__c = wo.Call_Origin_OrgCode__c,
                    WorkOrder_CallType__c = wo.Call_Type__c,
                    Member_PhoneNumber__c = wo.WO_Member_Phone_Number__c, //AGB 6/16/2025 for SSFI-1190
                    Member_LastName__c = ctc.LastName,
                    Member_FirstName__c = ctc.FirstName,
                    Member_EmailAddress__c = ctc.Email,
                    //Member_MemberType__c = mbrType, //AGB 6/16/2025 for SSFI-1190
                    Member_MemberType__c = wo.Call_Type__c, //AGB 6/16/2025 for SSFI-1190
                    
                    //RAP Program Related Mappings                
                    RAP_Sponsor__c = ctc.Membership_Sponsor__c,
                    RAP_Program__c = ctc.Membership_Program__c,
                    Member_ClubCode__c = wo.Member_Account__r.ACG_Club__c,
                    Member_ClubName__c = wo.Member_Account__r.ACG_Club_Name__c,
                    //Member_MemberLevel__c = ctc.Membership_Level__c,
                    Member_MemberLevel__c = wo.ServiceContract.AAA_ACA_Membership_Coverage_Level__c == null ? ctc.Membership_Level__c : wo.ServiceContract.AAA_ACA_Membership_Coverage_Level__c, //AGB 6/16/2025 for SSFI-1190
                    //Member_Status__c = ctc.Membership_Status__c,
                    //Vishnu Popuru #07/07/2025
                    Member_Status__c = ctc.Membership_Status__c!=null?ctc.Membership_Status__c.left(1):'', //AGB 6/16/2025 for SSFI-1190
                    Member_Since__c = ctc.Membership_Since__c,
                    Member_Id__c = wo.Member_Account__r.Member_ID__c,
                    Member_ExpirationDate__c = mbrExpDate,
                    CDX_AuthCode__c = ctc.Membership_Code__c,
                    CDX_AuthLevel__c = ctc.Membership_Authorization__c,

                    //Vehicle_VehicleType__c = wo.Member_Vehicle__r.Vehicle_Type__c, //AGB 6/16/2025 for SSFI-1190
                    Vehicle_Tag__c = wo.Member_Vehicle__r.Vehicle_Tag__c,
                    Vehicle_State__c = wo.Member_Vehicle__r.Vehicle_State__c,
                    Vehicle_Model__c = wo.Member_Vehicle__r.Vehicle_Model__c,
                    Vehicle_Make__c = wo.Member_Vehicle__r.Vehicle_Make__c,
                    Vehicle_FuelType__c = wo.Member_Vehicle__r.Vehicle_Fuel_Type__c,
                    Vehicle_DriveType__c = wo.Member_Vehicle__r.Vehicle_Drive_Type__c, //AGB 6/16/2025 for SSFI-1190
                    Vehicle_VehicleType__c = wo.Vehicle_Type__c == null ? '' :  wo.Vehicle_Type__c.left(2) == 'Tr' ? 'PS' : wo.Vehicle_Type__c.left(2), //AGB 6/16/2025 for SSFI-1190
                    Vehicle_Color__c = wo.Member_Vehicle__r.Vehicle_Color__c,
                    WaitTime__c = String.valueOf(wo.Wait_Time__c),
                    WorkOrder_ApptTime__c = wo.Non_Emergency_Appointment_Time__c,
                    WorkOrder_Collision__c = wo.Collision__c,
                    WorkOrder_RedFlag__c = wo.Red_Flag__c,
                    Codes_Priority__c = wo.Priority_Code__c,
                    WorkOrder_NumPass__c = String.valueOf(wo.Number_Of_Passengers__c),
                    WorkOrder_NeedsFlat__c = wo.Needs_Flatbed__c,
                    WorkOrder_RequestFlat__c = wo.Flatbed_Requested__c,
                    WorkOrder_CashCall__c = wo.Payment_Required__c,
                    Facility_Id__c = wo.ServiceTerritory.Facility_Number__c,
                    Facility_Name__c= wo.ServiceTerritory.Name,
                    SourceSystem_OrgCode__c = Label.FSL_SourceClubCode,
                    SourceSystem_OrgName__c = Label.Club_Name,
                    SourceSystem_Id__c = Label.FSL_SourceClubCode,
                    WorkOrder_ChannelType__c = wo.WorkOrder_ChannelType__c, //AGB 6/16/2025 for SSFI-1190
                    //Member_Status__c = wo.CDX_Membership_Status__c.left(1); //AGB 6/16/2025 for SSFI-1190 (no data in field, see above Member_Status__c = ctc.Membership_Status__c.left(1),)
                    Driver_Id__c = wo.Service_Resource__r.Driver_Id__c, //AGB 6/16/2025 for SSFI-1190
              		Truck_Id__c = wo.Service_Resource__r.Vehicle__r.Truck_ID__c, //AGB 6/16/2025 for SSFI-1190
              		Codes_Pacesetter__c = wo.case.Pacesetter_Code__c //AGB 6/16/2025 for SSFI-1190
                ); 
 				
                /*AGB 6/16/2025 for SSFI-1190
                System.debug('Repair Shop' + wo.Repair_Shop__c);

                if (wo.Repair_Shop__c != null) {
                    if (wo.Repair_Shop__r.Integration_Id__c != null) {    //Facility_ID__c
                        woSC.Repair_Shop__c = wo.Repair_Shop__r.Integration_Id__c; 
                    }
                }
				//AGB 6/16/2025 for SSFI-1190 */
				if(wo.case.Repair_Shop__r.Integration_Id__c != null)
                {
                    woSC.Repair_Shop__c = wo.case.Repair_Shop__r.Integration_Id__c;
                } //AGB 6/16/2025 for SSFI-1190

                if (wo.Member_Vehicle__r.Vehicle_Year__c != null) {
                    woSC.Vehicle_Year__c = wo.Member_Vehicle__r.Vehicle_Year__c;
                } 

                //Populating trouble Codes: need confirmation on the PROBLEM code              
                for (FSL_TroubleCode__c t : wo.TroubleCodes__r) {
                    if (t.Type__c == 'PROBLEM') {                     
                        woSC.Codes_Problem__c = t.Code__c;
                    }
                    if (t.Type__c == 'PACESETTER') {
                        //woSC.Codes_Pacesetter__c = t.Type__c ;  //AGB 6/16/2025 for SSFI-1190
                    }
                }               

                //Populating policies Codes
                for (FSL_Policy__c p: wo.Policies__r) {
                    if (p.Policy_Code__c != null) {
                        if (woSC.Codes_Policy__c != null) {
                            woSC.Codes_Policy__c += ',' + p.Policy_Code__c;
                        } else {
                            woSC.Codes_Policy__c = p.Policy_Code__c;
                        }
                    }                    
                }

                //Populating Provider Service Codes
                for (FSL_Service_Line_Item__c s : wo.Service_Line_Items__r) {
                    if (woSC.Codes_Service__c != null) {
                       woSC.Codes_Service__c += ','+s.Product__r.ProductCode;
                    } else {
                        woSC.Codes_Service__c = s.Product__r.ProductCode;
                    }
                }                
                
                /* //AGB 6/16/2025 for SSFI-1190
                //Populating Driver id and truck id
                if (woIdToARMap.get(wo.Id) != null) {
                    woSC.Driver_Id__c = woIdToARMap.get(wo.Id).ServiceResource.Driver_Id__c;
                    woSC.Truck_Id__c = woIdToARMap.get(wo.Id).ServiceResource.Vehicle__r.Truck_ID__c;
                }
				*/

                
                // SourceSystem_Id__c: eg: 004
                if (wo.External_Id__c != null && wo.External_Id__c.contains('-')) {
                    woSC.SourceSystem_Id__c = wo.External_Id__c.split('-')[0];               
                }

                // Service Appointments
                for (ServiceAppointment sa : wo.ServiceAppointments) {
                    if (sa.isBreakdown__c) {                      
                        woSC.WorkOrder_StatusTime__c = String.valueofGMT(
                            convertToGMT(sa.Cleared_Timestamp__c)
                        ).replace(' ', 'T') + 'Z';
                        
                        System.debug('$$ woSC.Codes_Resolution__c: ' + woSC.Codes_Resolution__c);
                        System.debug('$$ sa.Address_Change_Counter__c: ' + sa.Address_Change_Counter__c);
                        
                        woSC.Codes_Resolution__c = sa.Resolution_Code__c;

                        if (
                            sa.Address_Change_Counter__c != null 
                            && sa.Address_Change_Counter__c > 0
                        ) {
                            woSC.BL_Latitude__c = sa.Latitude; 
                            woSC.BL_Longitude__c = sa.longitude;              
                        } else {
                            woSC.BL_Latitude__c = wo.Breakdown_Location__Latitude__s;
                            woSC.BL_Longitude__c = wo.Breakdown_Location__Longitude__s; 
                        }
                        
                        woSC.BL_Landmark__c = sa.Landmark__c; 
                        woSC.BL_StreetName__c = sa.Street;
                        woSC.BL_State__c = sa.State;
                        woSC.BL_PostalCode__c = sa.postalcode;
                        woSC.BL_Country__c = sa.country;
                        woSC.BL_City__c = sa.City;
                        
                        String strStreet = String.isBlank(woSC.BL_StreetName__c) ? '' : woSC.BL_StreetName__c + ' ';
                        String strCity = String.isBlank(woSC.BL_City__c) ? '' : woSC.BL_City__c + ', ';
                        String strState = String.isBlank(woSC.BL_State__c) ? '' : woSC.BL_State__c + ' ';
                        String strPostalCode = String.isBlank(woSC.BL_PostalCode__c) ? '' : woSC.BL_PostalCode__c + ' ';
                        String strCountry = String.isBlank(woSC.BL_Country__c) ? '' : woSC.BL_Country__c;

                        woSC.BL_FullAddress__c = strStreet + strCity + strState + strPostalCode + strCountry;
                        woSC.BL_CrossStreet__c = sa.Cross_Street__c;
                        woSC.BL_FOIType__c = 'ADDRESS';
                    } else if (sa.Subject == 'Tow Appointment') {                        
                        woSC.TD_Name__c = sa.Tow_Destination_Name__c;

                        if (
                            sa.Address_Change_Counter__c != null 
                            && sa.Address_Change_Counter__c > 0
                        ) {
                            woSC.TD_Latitude__c = sa.Latitude;
                            woSC.TD_Longitude__c = sa.longitude;
                        } else {
                            woSC.TD_Latitude__c = wo.Tow_Location__Latitude__s;
                            woSC.TD_Longitude__c = wo.Tow_Location__Longitude__s;
                        }

                        woSC.TD_Landmark__c = sa.Landmark__c;
                        woSC.TD_StreetName__c = sa.Street;
                        woSC.TD_State__c = sa.State;
                        woSC.TD_PostalCode__c = sa.postalcode;
                        woSC.TD_Country__c = sa.country;
                        woSC.TD_City__c = sa.City;

                        String strStreet = String.isBlank(woSC.TD_StreetName__c) ? '' : woSC.TD_StreetName__c + ' ';
                        String strCity = String.isBlank(woSC.TD_City__c) ? '' : woSC.TD_City__c + ', ';
                        String strState = String.isBlank(woSC.TD_State__c) ? '' : woSC.TD_State__c + ' ';
                        String strPostalCode = String.isBlank(woSC.TD_PostalCode__c) ? '' : woSC.TD_PostalCode__c + ' ';
                        String strCountry = String.isBlank(woSC.TD_Country__c) ? '' : woSC.TD_Country__c;

                        woSC.TD_FullAddress__c = strStreet + strCity + strState + strPostalCode + strCountry;
                        woSC.TD_CrossStreet__c = sa.Cross_Street__c;                                               
                        woSC.TD_AddressType__c = 'PHYSICAL';
                        woSC.TD_FOIType__c = 'ADDRESS';
                    }
                }
                
                // Put the WorkOrder Clear Event to the Map with WO Id as key
                woIdToClearEventMap.put(wo.Id, woSC);
            } //end if (isEligibleCall(wo))
        } //end for (WorkOrder wo : woreclist)
              
        if (!woIdToClearEventMap.isEmpty()) {            
            // Publish all WO Clear Events
            List<Database.SaveResult> results = EventBus.publish(woIdToClearEventMap.values());
            
            // Verify Results       
            if (results[0].isSuccess()) {
                System.debug('RAP Clear Platform Event: Successfully published event');  

                FSL_ApplicationLogCreator.insertWorkOrderClearPlatformEventLog(
                    woIdToClearEventMap, false, 'RAP Clear Platform Event: Successfully published event'
                );
            } else {
                String erroMessage ='RAP Clear Platform Event Error: ';

                for (Database.Error err : results[0].getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());

                    erroMessage = erroMessage +  err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }        

                FSL_ApplicationLogCreator.insertWorkOrderClearPlatformEventLog(woIdToClearEventMap, true, erroMessage);        
            }
        }   
    }

    public static DateTime convertToGMT(DateTime dt) { 
        if (dt != null) {
            return DateTime.newInstanceGmt(
                dt.yearGMT(), 
                dt.monthGMT(), 
                dt.dayGMT(), 
                dt.hourGMT(), 
                dt.minuteGMT(), 
                dt.secondGMT()
            );
        } else {
            return null;
        }
    } 
}