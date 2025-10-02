/**** Apex Class Name    :    ERS_WorkOrderFromCase
    * Description        :    Class for submitting a Case. Creates WorkOrder,WorkOrderLineItems,determines WorkType,determines the Product, created and schedules Serv.Appts.
    * Test Class Name    :    ERS_WorkOrderFromCase_Test
    * Modification Log   :
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Viomesh Srivastava                                Created
    * Tarun Singh                                       Modified
    * Monika Jha                                        Modified
    * John Orzechowski      2025-05-23                  Modified impairment logic in validateCase method
*****************************************************************************************/

public without sharing class ERS_WorkOrderFromCase {
    public class customException extends Exception {} //Custom Exception
    public class WrapperClass{  // Values passed to the LWC after submission
       @AuraEnabled public Id WorkOrderId;
       @AuraEnabled public String WorkOrderNumber;
       @AuraEnabled public Id ServApptId;
    }
	 public class CaseupdateWC{ 
       public Boolean isSuccess;
        public String CallKey;
        public String description;
        public string[] IdTcodePCC;
        public string Errormessage;
    }
    
    /************EMI--Start-SSFI-832 ---04/06/2025****************/
    
    // =========================================
    // This is for 'Add Vehicle By Make/Model'
    // CMDT: ERS_Case_VehicleType_Mapping__mdt
    // Columns used :
    // - Label  (display value to return, e.g., "Truck", "R1", "GC")
    // - DeveloperName
    // - MasterLabel
    // - QualifiedApiName
    // - Vehicle_Type_Case__c
    // - Vehicle_Type_Master_Vehicle__c  (canonical like TRUCK/CAR/R1/etc.)
    // =========================================
  
    private static String norm(String s) { return String.isBlank(s) ? '' : s.trim().toUpperCase(); }
    private static String safe(String s) { return String.isBlank(s) ? '' : s.trim(); }

    // =========================
    // CMDT -> Label map (ANY key -> Label)
    // =========================
    private static final Map<String, String> TYPE_MAP = buildTypeMap();

    private static Map<String, String> buildTypeMap() {
        Map<String, String> out = new Map<String, String>();
        for (ERS_Case_VehicleType_Mapping__mdt row : ERS_Case_VehicleType_Mapping__mdt.getAll().values()) {
            String label = safe(row.Label);
            if (String.isBlank(label)) continue;

            List<String> keys = new List<String>{
                norm(row.Label),
                norm(row.DeveloperName),
                norm(row.MasterLabel),
                norm(row.QualifiedApiName),
                norm(row.Vehicle_Type_Case__c),
                norm(row.Vehicle_Type_Master_Vehicle__c)
            };
          
            for (String k : keys) {
                if (!String.isBlank(k) && !out.containsKey(k)) out.put(k, label);
            }
        }
        return out;
    }

    // Map whatever candidate we got to a CMDT Label; if not default to "PS"
    private static String mapToCmdtLabelOrFallback(String candidate) {
        String mapped = TYPE_MAP.get(norm(candidate));
        return String.isBlank(mapped) ? 'PS' : mapped;
    }

    // =========================
    // Label -> Case picklist value map
    // =========================
    private static final Map<String, String> LABEL_TO_CASE = buildLabelToCaseMap();

    private static Map<String, String> buildLabelToCaseMap() {
        Map<String, String> out = new Map<String, String>();
        for (ERS_Case_VehicleType_Mapping__mdt row : ERS_Case_VehicleType_Mapping__mdt.getAll().values()) {
            String label   = safe(row.Label);
            String caseVal = safe(row.Vehicle_Type_Case__c);
            if (String.isBlank(label)) continue;
            if (!out.containsKey(norm(label))) {
                out.put(norm(label), String.isBlank(caseVal) ? 'PS (Passenger Car/Truck)' : caseVal);
            }
        }
        return out;
    }

    private static String toCaseValueFromLabel(String label) {
        if (String.isBlank(label)) return 'PS (Passenger Car/Truck)';
        String v = LABEL_TO_CASE.get(norm(label));
        return String.isBlank(v) ? 'PS (Passenger Car/Truck)' : v;
    }

    // =========================
    // MASTER LOOKUP (case-sensitive SOQL)
    // =========================
    private static String resolveTypeFromMaster(String make, String model, String year, String driveType) {
        if (String.isBlank(make) || String.isBlank(model) || String.isBlank(year)) return '';

        String makeKey  = make.trim();
        String modelKey = model.trim();
        String yr       = safe(year);
      

        List<ACG_Master_Vehicle__c> rows = [
            SELECT Vehicle_Type__c
            FROM ACG_Master_Vehicle__c
            WHERE ACG_Vehicle_Make__c  = :makeKey
              AND ACG_Vehicle_Model__c = :modelKey
              AND ACG_Vehicle_Year__c  = :yr
            LIMIT 1
        ];

        return rows.isEmpty() ? '' : safe(rows[0].Vehicle_Type__c);
    }

  
    @AuraEnabled(cacheable=true)
    public static String getFinalVehicleTypeLabel(String make, String model, String year, String driveType) {
        String masterType = resolveTypeFromMaster(make, model, year, driveType);
        return mapToCmdtLabelOrFallback(masterType);
    }

    public static void applyVehicleTypeToCaseAndMember(
        Case cse,
        SObject memberVehicle, 
        String make,
        String model,
        String year,
        String driveType
    ) {
        String finalLabel = getFinalVehicleTypeLabel(make, model, year, driveType);

        // Member Vehicle gets the Label (e.g., "Truck", "R1", "GC")
        memberVehicle.put('Vehicle_Type__c', finalLabel);

        // Case gets the Case-facing picklist value (e.g., "PS (Passenger Car/Truck)")
        cse.ACG_Vehicle_Type__c = toCaseValueFromLabel(finalLabel);
    }

    // =========================
    // Label->Case value in other places
    // =========================
    @AuraEnabled(cacheable=true)
    public static String labelToCaseValue(String label) {
        return toCaseValueFromLabel(label);
    }
    
    
    @AuraEnabled(cacheable=true)
    public static String mapVehicleTypeToLabel(String inputType) {
        // Default early if blank
        if (String.isBlank(inputType)) return 'PS';
        
        String key      = inputType.trim();
        String upperKey = key.toUpperCase();
        
        List<ERS_Case_VehicleType_Mapping__mdt> mdt = [
            SELECT Label
            FROM ERS_Case_VehicleType_Mapping__mdt
            WHERE Label = :key
            LIMIT 1
        ];
        if (!mdt.isEmpty()) return mdt[0].Label;
        
        //  DeveloperName
        mdt = [
            SELECT Label
            FROM ERS_Case_VehicleType_Mapping__mdt
            WHERE DeveloperName = :key
            LIMIT 1
        ];
        if (!mdt.isEmpty()) return mdt[0].Label;
        
        //  MasterLabel
        mdt = [
            SELECT Label
            FROM ERS_Case_VehicleType_Mapping__mdt
            WHERE MasterLabel = :key
            LIMIT 1
        ];
        if (!mdt.isEmpty()) return mdt[0].Label;
        
        //  Vehicle_Type_Master_Vehicle__c (often stored uppercase like "CAR")
        mdt = [
            SELECT Label
            FROM ERS_Case_VehicleType_Mapping__mdt
            WHERE Vehicle_Type_Master_Vehicle__c = :upperKey
            LIMIT 1
        ];
        if (!mdt.isEmpty()) return mdt[0].Label;
        return 'PS';
    }
    
    
    @AuraEnabled
    public static void linkVehicleToCase(Id caseId, Id vehicleId) {
        if (String.isBlank(caseId) || String.isBlank(vehicleId)) {
            throw new AuraHandledException('Case ID and Vehicle ID are required.');
        }
        
        Case c = [SELECT Id, Member_Vehicle__c FROM Case WHERE Id = :caseId LIMIT 1];
        c.Member_Vehicle__c = vehicleId;
        update c;
    }
    
    // =========================================
    // This is for 'Add Vehicle By License Plate/State'   
    // =========================================
    
    @AuraEnabled(cacheable=true)
    public static String mapVehicleType(String masterVehicleType) {
        if (String.isBlank(masterVehicleType)) return '';
        
        List<ERS_Case_VehicleType_Mapping__mdt> mdtRec = [
            SELECT Vehicle_Type_Case__c
            FROM ERS_Case_VehicleType_Mapping__mdt
            WHERE Vehicle_Type_Master_Vehicle__c = :masterVehicleType
            LIMIT 1
        ];
        
        if (!mdtRec.isEmpty()) {
            return mdtRec[0].Vehicle_Type_Case__c;
        }
        return '';
    }
 
    @AuraEnabled
    public static Map<String, Id> createMemberVehicleFromLwc(
        String year,
        String make,
        String model,
        String plate,
        String state,
        String color,
        String vin,
        String vinPattern,
        String engineDisplacement,
        String trim,
        Decimal odometer,
        String driveType,
        Id accountId,
        Id caseId
    ) {
        System.debug('Creating vehicle from license plate search');
        
        // Resolve vehicle type label from Master + CMDT
        String label = getFinalVehicleTypeLabel(make, model, year, driveType);
        String casePicklistValue = labelToCaseValue(label);
        
        System.debug('Resolved Label: ' + label);
        System.debug('Resolved Case Value: ' + casePicklistValue);
        
        // Get RecordType for Member Vehicle
        Id vehicleRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'FSL_Member_Vehicle__c' AND Name = 'Member'
            LIMIT 1
        ].Id;
        
        // Create Member Vehicle
        FSL_Member_Vehicle__c vehicle = new FSL_Member_Vehicle__c(
            Name = String.join(new List<String>{ year, make, model, color, plate, label }, ' '),
            Vehicle_Year__c = year,
            Vehicle_Make__c = make,
            Vehicle_Model__c = model,
            Vehicle_Plate__c = plate,
            Vehicle_State__c = state,
            Vehicle_Color__c = color,
            Vehicle_VIN__c = vin,
            Vehicle_Vin_Pattern__c = vinPattern,
            Vehicle_Engine_Displacement_CL__c = engineDisplacement,
            Vehicle_Trim__c = trim,
            Vehicle_Odometer__c = odometer,
            Vehicle_Drive_Type__c = driveType,
            Vehicle_Type__c = label, // Member gets Label
            ACG_Member__c = accountId,
            RecordTypeId = vehicleRecordTypeId
        );
        
        try {
            insert vehicle;
            System.debug('Member Vehicle inserted: ' + vehicle.Id);
            
            //  Update the Case
            if (caseId != null) {
                Case cToUpdate = new Case(Id = caseId);
                cToUpdate.ACG_Vehicle_Type__c = casePicklistValue; // Case gets Picklist value
                update cToUpdate;
                System.debug('Case updated: ' + caseId);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error inserting vehicle or updating case: ' + e.getMessage());
        }
        
        return new Map<String, Id>{
            'vehicleId' => vehicle.Id
           };
       }
    
    @AuraEnabled
    public static void updateDriveTypeOnCase(Id caseId, String driveType) {
        if (String.isBlank(caseId)) return; //  skip if caseId is blank
        
        try {
            Case caseRecord = [
                SELECT Id, Vehicle_Drive_Type__c 
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
            
            //  Always update the field (even if blank)
            caseRecord.Vehicle_Drive_Type__c = driveType;
            update caseRecord;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update case: ' + e.getMessage());
        }
    }



    @AuraEnabled
    public static void updateMemberContactNumber(Id caseId, String contactNumber, String driverNotes, Boolean textUpdatesEnabled) {
        List<Case> updateCaseList = new List<Case>();
    
        // Update Case fields
        Case updateCase = new Case();
        updateCase.Id = caseId;
        updateCase.ACG_Case_Contact_Number__c = contactNumber;
        updateCase.ERS_Notes__c = driverNotes;
        
        if (textUpdatesEnabled != null) {
            updateCase.ACG_SMS_Opt_In__c = textUpdatesEnabled;
        }
    
        updateCaseList.add(updateCase);
    
        if (!updateCaseList.isEmpty()) {
            update updateCaseList;
            System.debug('Case updated: ' + caseId);
        }
    
        // update Contact's SMS_Optin__c if needed
        if (textUpdatesEnabled != null) {
            try {
                Case c = [SELECT Account.PersonContactId FROM Case WHERE Id = :caseId LIMIT 1];
                if (c.Account.PersonContactId != null) {
                    Contact con = new Contact(
                        Id = c.Account.PersonContactId,
                        Sms_Optin__c = textUpdatesEnabled
                    );
                    update con;
                    System.debug('Contact SMS opt-in updated.');
                }
            } catch (Exception e) {
                System.debug('Error updating contact SMS opt-in: ' + e.getMessage());
            }
        }
    }
                     
    @AuraEnabled
    public static void addCallComments(Id caseId,Id workOrderId,Decimal lat,Decimal lon,
                                       Boolean isHearingImpaired,Boolean DRRWebComment) {
        List<FSL_Call_Comments__c> commentsToInsert = new List<FSL_Call_Comments__c>();
        Set<String> existingComments = new Set<String>();
        
        // If fetch lat/lon from Case  not provided
        if (lat == null || lon == null) {
            Case c = [SELECT Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s,ACG_Priority_Code__c FROM Case WHERE Id = :caseId LIMIT 1];
            if (lat == null) lat = c.Vehicle_Geolocation__Latitude__s;
            if (lon == null) lon = c.Vehicle_Geolocation__Longitude__s;
        }
        
        try {
            List<FSL_Call_Comments__c> existing = [
                SELECT FSL_Comment__c 
                FROM FSL_Call_Comments__c 
                WHERE ACG_Case__c = :caseId AND FSL_Work_Order__c = :workOrderId
            ];
            for (FSL_Call_Comments__c comm : existing) {
                existingComments.add(comm.FSL_Comment__c);
            }
        } catch (Exception e) {
            System.debug('Skipping duplicate check due to DRR Site access error: ' + e.getMessage());
        }
        
        // Add coordinate comment as per DRR
        if (lat != null && lon != null) {
            String coordComment = 'Breakdown Location Coordinates: ' + lat + ', ' + lon;
           // System.debug('### coordComment = ' + coordComment);
            if (!existingComments.contains(coordComment)) {
                commentsToInsert.add(new FSL_Call_Comments__c(
                    FSL_Comment__c = coordComment,
                    ACG_Case__c = caseId,
                    FSL_Work_Order__c = workOrderId,
                    OwnerId = UserInfo.getUserId()
                ));
            }
        }
        
        // Breakdown location Google Maps link as per DRR
        if (lat != null && lon != null) {
            String linkComment = 'Breakdown Location Link: https://www.google.com/maps?q=' + lat + ',' + lon;
            
            if (!existingComments.contains(linkComment)) {
                commentsToInsert.add(new FSL_Call_Comments__c(
                    FSL_Comment__c = linkComment,
                    ACG_Case__c = caseId,
                    FSL_Work_Order__c = workOrderId,
                    OwnerId = UserInfo.getUserId()
                ));
            }
        }
        
        // DRR Web Comment as per DRR
        if (DRRWebComment) {
            String DRRComment = 'DRRWeb 2.0';
            if (!existingComments.contains(DRRComment)) {
                commentsToInsert.add(new FSL_Call_Comments__c(
                    FSL_Comment__c = DRRComment,
                    ACG_Case__c = caseId,
                    FSL_Work_Order__c = workOrderId,
                    OwnerId = UserInfo.getUserId()
                ));              
            }
        }
        
        // Hearing impaired as per DRR
        if (isHearingImpaired) {
            String hearingComment = 'I\'m hearing impaired.';
            if (!existingComments.contains(hearingComment)) {
                commentsToInsert.add(new FSL_Call_Comments__c(
                    FSL_Comment__c = hearingComment,
                    ACG_Case__c = caseId,
                    FSL_Work_Order__c = workOrderId,
                    OwnerId = UserInfo.getUserId()
                ));
            }
        }                                         
                                
       
        if (!commentsToInsert.isEmpty()) {
           // System.debug('Testing Final comments to insert: ' + JSON.serialize(commentsToInsert)); 
            insert commentsToInsert;
        }
    }    
         
    @AuraEnabled
        public static String updatePriorityBasedOnInputs(
            Id caseId,
            Boolean isLovedOne,
            Boolean isMedication,
            Boolean isAccident,
            String serviceTypeParam,
            String lockReasonParam
        ) {
            String debugInfo = 'Start | ';
            try {
                Case caseRecord = [
                    SELECT Id, Priority, ACG_Priority_Code__c
                    FROM Case 
                    WHERE Id = :caseId 
                    LIMIT 1
                ];
        
                String serviceType = serviceTypeParam != null ? serviceTypeParam.trim().toLowerCase() : '';
                String lockReason = lockReasonParam != null ? lockReasonParam.trim().toLowerCase() : '';
        
                debugInfo += 'Case found | serviceType = [' + serviceType + '] | lockReason = [' + lockReason + ']';
                debugInfo += ' | isLovedOne = ' + String.valueOf(isLovedOne) + ' | isMedication = ' + String.valueOf(isMedication) + ' | isAccident = ' + String.valueOf(isAccident) + ' | ';
        
                Boolean shouldUpdate = false;
                String result = 'No changes made.';
        
                // Priority: Critical (P1) - Loved One Locked in Car
                if (isLovedOne && serviceType == 'vehicle lockout' && lockReason == 'locked in the vehicle') {
                    caseRecord.Priority = 'Critical';
                    caseRecord.ACG_Priority_Code__c = 'P1-Baby Locked in Car';
                    result = 'Updated to Critical (P1)';
                    shouldUpdate = true;
                    debugInfo += 'Matched loved one logic | ';
                }
                // Priority: High (P2) - Medication in Vehicle
                else if (isMedication && serviceType == 'vehicle lockout' && lockReason == 'locked in the vehicle') {
                    caseRecord.Priority = 'High';
                    caseRecord.ACG_Priority_Code__c = 'P2-Member Safety/Medical Concern';
                    result = 'Updated to High (P2)';
                    shouldUpdate = true;
                    debugInfo += 'Matched medication logic | ';
                }
                // Priority: High (P6) - Accident
                else if (isAccident && serviceType == 'tow') {
                    caseRecord.Priority = 'High';
                    caseRecord.ACG_Priority_Code__c = 'P6-Accident';
                    result = 'Updated to High (P6)';
                    shouldUpdate = true;
                    debugInfo += 'Matched accident logic | ';
                } else {
                    debugInfo += 'No matching update logic | ';
                }
        
                if (shouldUpdate) {
                    update caseRecord;
                    debugInfo += 'Update successful.';
                }
        
                System.debug('Debug Info: ' + debugInfo);
                return result + ' | ' + debugInfo;
        
            } catch (Exception ex) {
                String errorMessage = 'Error updating Case priority: ';
                try {
                    errorMessage += ex.getTypeName() + ': ' + ex.getMessage();
                } catch (Exception innerEx) {
                    errorMessage += 'Unknown Apex Error (message failed to extract)';
                }
        
                System.debug('Final Error: ' + errorMessage);
                throw new AuraHandledException(errorMessage + ' | ' + debugInfo);
            }
        }
         
	/*        
        @AuraEnabled
        public static void setTowRequestReason(Id caseId, String reason) {
            Case c = new Case(Id = caseId);
            c.Tow_Request_Reason__c = reason;
            update c;
        }
   
        @AuraEnabled
        public static void setTowRequestReason(Id caseId, String reason) {
            try {
                update new Case(Id = caseId, Tow_Request_Reason__c = reason);
            } catch (Exception e) {
                throw new AuraHandledException('Failed to update Tow_Request_Reason__c: ' + e.getMessage());
            }
        }
      */
        
    /************EMI--END****************/
    
    
    public static final String CALL_MOVER_EXCEPTION = 'The member\'s breakdown location is outside of the ACE Territory, this call will be moved.';
    
    /* Description: Method that handles Case Submission.
     * Method Name: workOrderIntake
     * params: Id
	*/
    @AuraEnabled
    public static WrapperClass workOrderIntake(Id caseId){
        
        List<Case> casObject = [SELECT Id, Case_Membership_Level__c, CaseNumber, FSL_Service_Type_Internal__c,
                                        AccountId,Account.ACG_Membership_Status__c, Account.ACG_SMS_Opt_In__c, Account.firstName, Account.lastName, Account.phone, 
                                        Account.PersonContactId, Account.RecordType.DeveloperName, ACG_AAA_Membership__c, ACG_Membership_Status__c, 
                                        ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,ACG_SMS_Opt_In__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                                        ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                                        ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c, ACG_Year__c,
                                        ACG_Make__c, ACG_Model__c, Vehicle_Trim_Level__c, ACG_Color__c, Vehicle_Drive_Type__c,
                                        Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,  ACG_VIN__c, Vehicle_Odometer__c, 
                                Call_Origin__c,Contact_at_Drop_off__c,Call_Date__c, Case_Priority_Override__c,Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_TransactionId__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,                                        
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                                        CDX_Phone_Number__c, Critical_Call_Reason__c,ACG_Priority_Code__c,Club_Name__c,CreatedDate,Channel__c,
                                        ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,Landmark__c,Tow_Destination_Name__c,
                                        Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                                        Gross_Weight__c, 
                                Member_Household__c,Member_Vehicle__c,Member_Vehicle_Type__c,
										Number_of_passengers__c,Non_Active_Dues_Paid__c,
										Over_Entitlement_Fee_Paid__c,Override_Reason__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,
										Same_Day_Service_Fee_Paid__c,Special_Equipment_Selection__c, Status,
                                        Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                                Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,T_Code__c,Tow_Request_Reason__c,Tow_Request_Miscellaneous_Details__c,Total_Mileage__c,
                                Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,Vehicle_Location_Country__c,Vehicle_Location_Postal_Code__c,
                                        Vehicle_Geolocation__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c, Member_Location_TZ_Offset__c, Locksmith_Issue__c,
                                        Impairment__c, Impairment__r.Payment_Required__c, Impairment__r.Information_Only__c, Impairment_Payment_Collected__c, Impairment_COD_Payment__c, Impairment_Supervisor_Override__c,
                                        PTA__c,ServiceContractId,Reconcile_Entitlement__c, Use_Home_Lock_Entitlement__c, Impairment_SameDay_Service__c,Which_service_is_the_member_requesting__c,Tow_Destination_Landmark__c,
                                		RAP_CSR__c,RAP_CSR_ID__c,RAP_Case_Number__c,RAP_Club__c //AGB added RAP fields for SSFI-14
                                FROM Case 
                                WHERE Id = :caseId];
        
        Case casObj = new Case();
        WorkOrder WO = new WorkOrder();
        WorkOrderLineItem WOLI = new WorkOrderLineItem();
        WrapperClass wrapper = new WrapperClass();
        if(! casObject.isEmpty())
        {
            casObj = casObject[0];
            try{
                
                validateCase(casObj);     //Validate necessary fields are populated on the Case
                //AGB updated for SSFI-14
				String clubcode = validateClubCode(casObj);     //Validate if location is in ACG territory (for CallMover scenario)
                System.debug ( ' WorkorderIntake.validateClubCode returned: ' + clubCode );
                //AGB updated for SSFI-14
                if(casObj.RAP_Club__c != '' && casObj.RAP_Club__c != null)
                {
                    clubcode = casObj.RAP_Club__c.split(' - ')[0].trim();
                    System.debug(' RAP Club Code:'+ clubCode);
                    casObj.ERS_Event_Type__c = 'RAP';
                }
				//end AGB updated for SSFI-14
                /*if(validateMembershipCoverage(casObj.id, NULL) == false){   //Validate member's coverage based on Membership level
                   throw new customException('You are not eligible for this service, please check member\'s membership level');
                }*/

                FSL_JSonParserWorkOrder jsonParser = new FSL_JSonParserWorkOrder();
                CallReceiveWorkOrderIntegration.CaseToJsonWrapper jsonWrapper = new CallReceiveWorkOrderIntegration.CaseToJsonWrapper();
                
                String[] IdTcodePCC =  (getWorkTypeId(casObj)).split('#');
                if(IdTcodePCC.size()==3) {
                    casObj.ACG_Work_Type__c = IdTcodePCC[0];
                    casObj.T_Code__c = IdTcodePCC[1];
                    casObj.Pacesetter_Code__c = IdTcodePCC[2];
                }
                casObj.Call_Origin__c = 'Salesforce';

                jsonParser = jsonWrapper.Wrap(casObj, clubcode);
                WorkOrder WO_returned = CallReceiveWorkOrderIntegration.createWO(jsonParser); 
                
                // *** MPatel: Set ERS_Notes__c = Vehicle_Location_Type / ERS_Notes ***
                String combinedNotes = '';
                if (!String.isBlank(casObj.ACG_Vehicle_Location_Type__c)) {
                    combinedNotes += casObj.ACG_Vehicle_Location_Type__c;
                }
                if (!String.isBlank(casObj.ERS_Notes__c)) {
                    if (!String.isBlank(combinedNotes)) combinedNotes += ' / ';
                    combinedNotes += casObj.ERS_Notes__c;
                }
                if (!String.isBlank(combinedNotes)) {
                    WO_returned.ERS_Notes__c = combinedNotes;
                    update WO_returned;
    
                    List<ServiceAppointment> saUpdates = [
                        SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :WO_returned.Id
                    ];
                    for (ServiceAppointment sa : saUpdates) {
                        sa.ERS_Notes__c = combinedNotes;
                    }
                    if (!saUpdates.isEmpty()) {
                        update saUpdates;
                    }
                }
                // *** END Notes ***
                             
                //WorkOrder WO_returned = FSL_WorkOrderIntake.createWorkOrderAndRelatedObjects(jsonParser);
                // Commented as Service contract will be updated only after work order got cleared
                /*if(WO_returned.Use_your_long_tow_entitlement__c == true && WO_returned.ServiceContract?.ParentServiceContractId != null){
                    Boolean isLongTowUpdated = AAA_ServiceContractUtility.updateLongTowConsumed(WO_returned.ServiceContract.ParentServiceContractId, WO_returned.Use_your_long_tow_entitlement__c);
                }*/
                casObj.Status = Label.ERS_CASE_STATUS_ON_WO_CREATION ; //ERSBO-1728
                casObj.FSL_Work_Order__c = WO_returned.Id;
                casObj.Pta__c = WO_returned.Pta__c;
 
               // update casObj;
                //if(casObj.ERS_Notes__c != NULL){
                    createWorkOrderFeedItem(casObj, WO_returned);
                //}
                //
                ////TODO: Repair Shop Call Here 
                if(casObj.Repair_Shop__c != null){
                    system.debug('******* repair shop available' + casObj.Repair_Shop__c);
                    //FSL_INTRepairShopOutbound.Response_wrapper resp = 
                    if(System.label.RepairShopFunctionality == 'TRUE'){
                        FSL_INTRepairShopOutbound.generateRepairShopRequest(casObj.Id,WO_returned.Id);
                    }
                    //System.debug('******* repair shop available'+ resp.isSuccess);
                }

                wrapper.WorkOrderId = WO_returned.Id;
                wrapper.WorkOrderNumber = WO_returned.WorkOrderNumber;
                wrapper.ServApptId = WO_returned.ServiceAppointments[0].Id;
                casObj.FSL_Service_Appointment__c = WO_returned.ServiceAppointments[0].Id;
                update casObj;
           }
           catch(customException cstExp){   // Handle all exceptions occuring during Case submission.
                String ErrMsg;
                if(cstExp.getMessage() == 'Work Orders cannot be created once the Case is canceled.'){
                    ErrMsg = cstExp.getMessage();
                }
                else if(cstExp.getMessage() == 'You are not eligible for this service, please check member\'s membership level'){
                    ErrMsg = cstExp.getMessage();
                }
                else if(cstExp.getMessage() == 'This Member is not broken down in this Territory, this is a Call Mover Call'){
                        system.debug('calling generateCallMoverRequest');
                    FSL_INTCallMoverOutbound.Response_wrapper resp = FSL_INTCallMoverOutbound.generateCallMoverRequest(casObj.Id);
                    CaseupdateWC WCcaseobj = new CaseupdateWC();
                    WCcaseobj.isSuccess = resp.isSuccess;
         			WCcaseobj.CallKey = resp.CallKey;
         			WCcaseobj.description = resp.description;
         			WCcaseobj.IdTcodePCC = resp.IdTcodePCC;
                    System.debug(resp.isSuccess);
                    System.Debug([select Status from case where Id =: casObj.Id]);
                    if(resp.isSuccess){
                   	    WCcaseobj.Errormessage = 'This Member is not broken down in this Territory, this is a Call Mover Call';
                        ErrMsg = JSON.serialize(WCcaseobj);
                    }else{
                        WCcaseobj.Errormessage = 'This Member is not broken down in this Territory, this is a Call Mover Call.Error: Could not contact National Call Mover API. Call Mover was not successful. Voice call the servicing club, provide the details, then manually close the case';
                        ErrMsg = JSON.serialize(WCcaseobj);
                    }
                }
                else{   
                    ErrMsg = 'Work Order could not be created: '+cstExp.getMessage();
                }
                AuraHandledException auraHandledException = new AuraHandledException(ErrMsg);
                auraHandledException.setMessage(ErrMsg);    //To be visible in the test methods
                throw auraHandledException;
            }
            catch(Exception e){		//Catch unhandled exceptions during Case submission.
                String ErrMsg = 'Work Order could not be created: Contact System Admin' +'\n' +String.valueOf(e)+'. \n'+e.getStackTraceString()+(e.getCause() != NULL ?'. \n'+String.valueof(e.getCause()):'');
                AuraHandledException auraHandledException = new AuraHandledException(ErrMsg);
                auraHandledException.setMessage(ErrMsg);    //To be visible in the test methods
                throw auraHandledException;
            }      
        }else{   System.debug('No Case Object found'); }
        //Return the Id & WorkOrdernumber to display on the toast message (ERSBO-1610)               

        return wrapper;
    }

         
    /*
     * Description: Creates the WorkOrder.
     * Method Name: createWO
     * params: Case
	*/
    public static WorkOrder createWO(Case objCase){
        /* Case to Work order field mappings (ERSBO-1566) */
        WorkOrder wo = new WorkOrder();
        if(objCase.ACG_Service_Type__c != NULL && objCase.ACG_Service_Type__c.contains('Tow')){     // If Tow service,create a Tow Work Order
            wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
            wo.Is_Tow_WorkType__c = true;
        }else{      //If not Tow service, create a Light service work order
            wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
            wo.Is_Tow_WorkType__c= false;
        }
        wo.Driving_Directions__c = objCase.ACG_Driving_Directions__c;
        wo.ERS_Notes__c = objCase.ERS_Notes__c; //MPatel SSFI -1264
        String[] IdTcodePCC =  (getWorkTypeId(objCase)).split('#');
        wo.CaseId = objCase.Id;
        wo.WorkTypeId = IdTcodePCC[0];
        wo.T_Code__c = IdTcodePCC[1];
            system.debug('Workorder'+IdTcodePCC[2]);
        wo.FSL_Pacesetter__c = IdTcodePCC[2];
			system.debug(wo.FSL_Pacesetter__c);
        wo.Acting_Agent__c= objCase.Acting_Agent__c;
        wo.Acting_Agent_Details__c = objCase.Acting_Agent_Details__c;
        wo.Pick_up_Point_Comments__c = objCase.ACG_Pick_up_Point_Comments__c;
        wo.Member_Location_Address__c = objCase.ACG_Member_Location_Address__c;
        wo.Member_Location_Comments__c = objCase.ACG_Member_Location_Comments__c;
        wo.Member_Present_at_vehicle__c = objCase.ACG_Member_present_at_Vehicle__c;
            system.debug('objCase.ERS_Event_Type__c-->'+objCase.ERS_Event_Type__c);
        wo.ACG_Call_Type__c = objCase.ERS_Event_Type__c;
        wo.ContactId = objCase.Account.PersonContactId;   //ERSBO-3797
        wo.Member_Account__c = objCase.AccountId;
		 wo.Landmark__c = objCase.Landmark__c;
        wo.Tow_Destination_Name__c = objCase.Tow_Destination_Name__c;
        wo.Household__c = objCase.Member_Household__c;
        wo.WO_Member_Phone_Number__c = objCase.ACG_Case_Contact_Number__c;
        wo.Member_Vehicle__c = objCase.Member_Vehicle__c;
        wo.Alternate_Phone_Number__c = objCase.ACG_Alternate_Phone_Number__c;
		 wo.Use_your_long_tow_entitlement__c = objCase.Use_your_long_tow_entitlement__c;
        wo.Vehicle_Location_Type__c = objCase.ACG_Vehicle_Location_Type__c;
        wo.Vehicle_Type__c =  objCase.Member_Vehicle_Type__c;
        wo.Breakdown_Location__Latitude__s = objCase.Vehicle_Geolocation__Latitude__s;
        wo.Breakdown_Location__Longitude__s = objCase.Vehicle_Geolocation__Longitude__s;
        wo.ACG_Requested_Appointment_Date__c = objCase.ACG_Requested_Appointment_Date__c;
        wo.ACG_Requested_Appointment_Time__c = objCase.ACG_Requested_Appointment_Time__c;
        if(objCase.ACG_Requested_Appointment_Date__c!=Null){
          wo.Appointment_Requested__c = TRUE;
        }
        if(objCase.Critical_Call_Reason__c != NULL){
            wo.Priority_Description__c = objCase.Critical_Call_Reason__c;
        }
        else if(objCase.Case_Priority_Override__c && objCase.Case_Priority_Override_Reason__c != NULL){
            wo.Priority_Description__c = objCase.Case_Priority_Override_Reason__c;
        }
       	/*Address compound fields*/
        wo.Street = objCase.Vehicle_Location_Street__c;
        wo.City = objCase.Vehicle_Location_City__c;
        wo.State = objCase.Vehicle_Location_State__c;
        wo.Country = objCase.Vehicle_Location_Country__c;
        wo.PostalCode = objCase.Vehicle_Location_Postal_Code__c;
        wo.Latitude = objCase.Vehicle_Geolocation__Latitude__s;
        wo.Longitude = objCase.Vehicle_Geolocation__Longitude__s;
        /*End of <Address compound fields>*/
        wo.Call_Origin__c = objCase.Call_Origin__c;
        //wo.Call_Date__c = (objCase.CreatedDate.Date()).format();
        wo.Channel__c = objCase.Channel__c;
        wo.Collision__c = objCase.ACG_Collision__c;
        List<WorkType> Duration = [SELECT EstimatedDuration,DurationType
                                    FROM WorkType 
                                    WHERE Id=:wo.WorkTypeId LIMIT 1];
        wo.Duration = Duration.isEmpty() ? NULL : Duration[0].EstimatedDuration;
        wo.DurationType = Duration.isEmpty() ? NULL : Duration[0].DurationType;
        wo.Number_Of_Passengers__c = objCase.Number_of_passengers__c;
        wo.Tow_Request_Reason__c = objCase.Tow_Request_Reason__c;
        wo.Tow_Request_Miscellaneous_Details__c = objCase.Tow_Request_Miscellaneous_Details__c;
        wo.Needs_Flatbed__c = objCase.Flatbed_Required__c;
        wo.Requested_Destination_Unavailable__c = objCase.Requested_Destination_Unavailable__c;
        wo.Contact_at_Drop_off__c = objCase.Contact_at_Drop_off__c;
        wo.Total_Mileage__c = objCase.Total_Mileage__c;
        wo.Special_Equipment_Selection__c = objCase.Special_Equipment_Selection__c;
        wo.ServiceTerritoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(double.valueof(objCase.Vehicle_Geolocation__Longitude__s),
                                                                          double.valueof(objCase.Vehicle_Geolocation__Latitude__s));
        
        if(!(wo.ServiceTerritoryId == null || wo.ServiceTerritoryId == ''))  {
            ServiceTerritory st = [Select OperatingHours.TimeZone from ServiceTerritory where Id =:wo.ServiceTerritoryId];
            if(st != null ) {
                string targetTimezone = st.OperatingHours.TimeZone;
                Datetime  dttime = Datetime.now();
                Integer offset=UserInfo.getTimeZone().getOffset(dttime);
                // target Timezone.
                TimeZone targetTZ = Timezone.getTimeZone(targetTimezone);
                integer offsetTotargetTZ = targetTZ.getOffset(dttime);
                integer correction = offsetTotargetTZ- offset;
                
                DateTime targetDT = dttime.addMinutes(correction / (1000 * 60));
                string calldate = targetDT.format('yyyy-MM-dd');
                system.debug(calldate);
                wo.Call_Date__c = calldate;
            }
        } 
        //wo.ServiceTerritoryId = FSL.PolygonUtils.getTerritoryIdByPolygons(double.valueof(-81.00),double.valueof(28.60));
        wo.Priority = objCase.Priority;
        /* Tow Address compound Fields */
        wo.Tow_Street__c = objCase.Tow_Destination_Street__c;
        wo.Tow_City__c = objCase.Tow_Destination_City__c;
        wo.Tow_State__c = objCase.Tow_Destination_State__c;
        wo.Tow_Country__c = objCase.Tow_Destination_Country__c;
        wo.Tow_Postal_Code__c = objCase.Tow_Destination_Postal_Code__c;
        /*End of <Tow Address compound fields> */
        wo.Tow_Location__Latitude__s = objCase.Tow_Geolocation__Latitude__s;
        wo.Tow_Location__Longitude__s = objCase.Tow_Geolocation__Longitude__s;
        wo.Repair_Shop__c = objCase.Repair_Shop__c;
        /*CDX Mappings*/
        wo.CDX_Authorization_Code__c = objCase.CDX_Authorization_Code__c;
        wo.CDX_Authorization_Level__c = objCase.CDX_Authorization_Level__c;
        wo.CDX_Authorization_Message__c = objCase.CDX_Authorization_Message__c;
        wo.CDX_Membership_Level__c = objCase.CDX_Membership_Level__c;
        wo.CDX_Membership_Status__c = objCase.CDX_Membership_Status__c;
        wo.CDX_Active__c = objCase.CDX_Active__c;
        wo.CDX_Motorcycle_Coverage__c = objCase.CDX_Motorcycle_Coverage__c;
        wo.CDX_Home_Address__c = objCase.CDX_Home_Address__c;
        wo.CDX_Member_Since__c = objCase.CDX_Member_Since__c;
        wo.CDX_Type__c = objCase.CDX_Type__c;
        wo.CDX_Expiration__c = objCase.CDX_Expiration__c;
        wo.CDX_Name__c = objCase.CDX_Name__c;
        wo.CDX_Phone_Number__c = objCase.CDX_Phone_Number__c;
        /**End of <CDX Mappings> */        
        return wo;
        
    }
    
	/* Description: Create WOLI record. 
     * Method Name: createWOLIFromWorkTypeProduct
     * params: workTypeId, pricebookEntryId, productCode, WorkOrderID
    *
    public static WorkOrderLineItem createWOLIFromWorkTypeProduct(id workTypeId , id pricebookEntryId, string productCode, Id WorkOrderID){SELECT  Case_Membership_Level__c, Vehicle_Location_Postal_Code__c,  Vehicle_Location_City__c, Vehicle_Location_State__c, BSP_Available__c, Club_Name__c, Enter_Home_during_Lockout__c, ERS_Event_Type__c, Flat_Tire_Status__c, Gross_Weight__c, Vehicle_Lockout_Reason__c, ACG_Service_Type__c, Special_Equipment_Selection__c, Total_Mileage__c, ACG_Drivetrain__c, Vehicle_Fuel_Type__c, ACG_Vehicle_Location_Type__c, Member_Vehicle_Type__c, Tow_Request_Reason__c FROM Case WHERE id='5002g000005cypsAAA'
SELECT Id, Level_of_Membership__c, AAA_Membership_Level__c FROM Account WHERE Id =
        
        WorkOrderLineItem woliObj = new WorkOrderLineItem();
        woliObj.WorkOrderId = WorkOrderID;
        woliObj.WorkTypeId = workTypeId;
        woliObj.PricebookEntryId = pricebookEntryId;
        woliObj.ERS_Product_Code__c = productCode;
        woliObj.Mileage__c = 5;
        //woliObj.Total_Amount__c = 25;
        return woliObj;
    }*/
    
	 /* Description: 
     * Method Name: workTypeProductMapInsertWOLI
     * params: Case, WorkOrder, booleanflag
    *
    public static void workTypeProductMapInsertWOLI(Case caseObject, WorkOrder WO_Obj,Boolean isThrowError){
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        Set<String> productSet = new Set<String>();
        Map<String,Id> productnameIdMap = new Map<string,Id>();
        Map<String,String> productnameCodeMap = new Map<string,string>();
        
        String eventType = caseObject.ERS_Event_Type__c;
        String stateCode = getStateLabelCodeMap().get(caseObject.Vehicle_Location_State__c);
            
        if( caseObject.ACG_Work_Type__c != NULL){ 
            String workTypeName = [SELECT Id,Name FROM WorkType WHERE Id =: caseObject.ACG_Work_Type__c].Name;
            List<ERS_Work_Type_to_Product_Mapping__mdt> mdtList = [SELECT ERS_Work_Type__c,ERS_Product__c,ERS_Is_Rap_Product__c,ERS_Is_Holiday_Product__c,City__c,State_Code__c, 
                                                                            Vehicle_Location_Type__c 
                                                                    FROM ERS_Work_Type_to_Product_Mapping__mdt  
                                                                    WHERE ERS_Work_Type__c =: workTypeName LIMIT 50000];
            if(!mdtList.isEmpty()){
                for(ERS_Work_Type_to_Product_Mapping__mdt WTPRec : mdtList){
                    
                    productSet.add(WTPRec.ERS_Product__c);
                    
                }
            }
            
            for(PriceBookEntry priceBookEntry : [SELECT id,Product2.Name, Product2.ProductCode 
                                                    FROM PriceBookEntry 
                                                    WHERE Product2.Name IN:productSet AND Pricebook2.isStandard = true LIMIT 50000]){
                
                productnameIdMap.put(priceBookEntry.Product2.Name,priceBookEntry.id);
                productnameCodeMap.put(priceBookEntry.Product2.Name,priceBookEntry.Product2.ProductCode);
            }

            List<ACG_Holidays__mdt> holidayMdtList = [SELECT ACG_Start_Date__c,ACG_End_Date__c FROM ACG_Holidays__mdt LIMIT 50000];
            if(!mdtList.isEmpty()){
                for(ERS_Work_Type_to_Product_Mapping__mdt WTPRec : mdtList){
                    if(WTPRec.ERS_Is_Holiday_Product__c != 'Yes' && WTPRec.ERS_Is_Rap_Product__c != 'Yes')
                    {
                        if(!String.isBlank(WTPRec.City__c) && !String.isBlank(WTPRec.State_Code__c) && WTPRec.City__c.equals(caseObject.Vehicle_Location_City__c) &&  WTPRec.State_Code__c.equals(stateCode))
                        {
                            woliList.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(caseObject.ACG_Work_Type__c,productnameIdMap.get(WTPRec.ERS_Product__c),productnameCodeMap.get(WTPRec.ERS_Product__c),WO_Obj.Id));
                        }
                        else if(!String.isBlank(WTPRec.Vehicle_Location_Type__c)  &&  WTPRec.Vehicle_Location_Type__c.equals(caseObject.ACG_Vehicle_Location_Type__c))
                        {
                            woliList.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(caseObject.ACG_Work_Type__c,productnameIdMap.get(WTPRec.ERS_Product__c),productnameCodeMap.get(WTPRec.ERS_Product__c),WO_Obj.Id));
                        }
                        else if((String.isBlank(WTPRec.City__c) && String.isBlank(WTPRec.State_Code__c))&&(String.isBlank(WTPRec.Vehicle_Location_Type__c))){
                            woliList.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(caseObject.ACG_Work_Type__c,productnameIdMap.get(WTPRec.ERS_Product__c),productnameCodeMap.get(WTPRec.ERS_Product__c),WO_Obj.Id));
                        }
                    }
                    else if(WTPRec.ERS_Is_Rap_Product__c == 'Yes')
                    {
                        if(eventType =='RAP')
                        {
                            woliList.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(caseObject.ACG_Work_Type__c,productnameIdMap.get(WTPRec.ERS_Product__c),productnameCodeMap.get(WTPRec.ERS_Product__c),WO_Obj.Id));
                        }
                    }
                    else if(WTPRec.ERS_Is_Holiday_Product__c == 'Yes')
                    {
                        if(!holidayMdtList.isEmpty()){
                            for(ACG_Holidays__mdt hol : holidayMdtList)
                            {
                                if(System.now()>=hol.ACG_Start_Date__c && System.now()<=hol.ACG_End_Date__c)
                                {
                                    woliList.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(caseObject.ACG_Work_Type__c,productnameIdMap.get(WTPRec.ERS_Product__c),productnameCodeMap.get(WTPRec.ERS_Product__c),WO_Obj.Id));
                                }
                            }
                        }else { 
                            if(isThrowError){
                                throw new customException('No holiday metadata record found '); 
                        }
         			   }
                    }
                }
            }
            else {
                //  if(isThrowError)
                //  throw new customException('Work Type To Product Mapping Metadata record not found '); 
            }
                
            if( !woliList.isEmpty() ){   
                insert woliList;
            }
        } 
    }*/
     
    
  /*  * Method name  : getStateCodeLabelMap
    * Description  : ICEPHX-2456 
    * Parameter    : NA
    * Return Type  : Map of state code and state labels
    * Developer    : Monika Jha
    * Date         : 22 oct, 2021
    */  
    public static Map<String,String> getStateLabelCodeMap(){
        
        Map<String,String> stateLabelCodeMap = new Map<String,String>();
        for( Schema.PicklistEntry f : User.statecode.getDescribe().getPicklistValues()){
            stateLabelCodeMap.put(f.getLabel(),f.getValue());
        }
        return stateLabelCodeMap;
    }
    
   
    /*
     * Description: This method populates the Work type of the Case.
     * Method Name: getWorkTypeId
     * params: Case Id
	*/
    
    public static String getWorkTypeId(Case caseObj){
        //System.debug('caseObj Id '+ caseObj.Id);
        //System.debug('caseObj Id '+ caseObj.FSL_Service_Type_Internal__c);
        //Get Membership level of the associated Member
        List<Account> MemberAccount= [SELECT Id, Level_of_Membership__c, AAA_Membership_Level__c FROM Account WHERE Id =:caseObj.AccountId];
        String MembershipLevel = MemberAccount.isEmpty() ? NULL : MemberAccount[0].AAA_Membership_Level__c;
      
        //Get all the Active Metadata records                                   
        List<ERS_Case_to_Work_Type_Mapping__mdt> mdtList = [SELECT  Appointment_Requested__c,
                                                                    Breakdown_Location_City__c, Breakdown_Location_State__c, BSP_Available__c,
                                                                    Club__c, Case_to_Work_Type_Mapping_Status__c,
                                                                    Enter_Home_during_Lockout__c,ERS_Event_Type__c,
                                                                    Flat_Tire_Status__c,
                                                                    Gross_Weight__c,Tow_Request_Reason__c,
                                                                    Vehicle_Lockout_Reason__c,
                                                                    Member_Needs_Air__c, Membership_Level__c,
                                                                    PCC_DISP_CODE__c,Priority__c,
                                                                    Service_Type__c, Special_Equipment_Selection__c,
                                                                    Total_Mileage__c,T_Code__c,
                                                                    Vehicle_Drivetrain__c, Vehicle_Fuel_Type__c, Vehicle_Type__c,Vehicle_Location_Type__c,
                                                                    Work_Type__c,Battery_Service_Type__c
                                                           FROM ERS_Case_to_Work_Type_Mapping__mdt
                                                           WHERE Case_to_Work_Type_Mapping_Status__c ='Active'
                                                           ORDER BY Priority__c ASC NULLS LAST 
                                                            ];
        system.debug('@@@@@@@ Size @@@@'+mdtList.size());
        //If there are Active mappings available
        if(!mdtList.isEmpty()){
            List<ERS_Case_to_Work_Type_Mapping__mdt> lstWorkType = new List<ERS_Case_to_Work_Type_Mapping__mdt>();  
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
                    &&((mdtRec.Vehicle_Lockout_Reason__c == caseObj.Vehicle_Lockout_Reason__c  || mdtRec.Vehicle_Lockout_Reason__c == caseObj.Locksmith_Issue__c)      || mdtRec.Vehicle_Lockout_Reason__c == NULL)
                    &&(mdtRec.Membership_Level__c == MembershipLevel                    || mdtRec.Membership_Level__c == NULL)
                    //&&(mdtRec.Service_Type__c == caseobj.ACG_Service_Type__c            || mdtRec.Service_Type__c == NULL || mdtRec.Service_Type__c == caseobj.FSL_Service_Type_Internal__c)
                    &&( (caseobj.FSL_Service_Type_Internal__c == 'Extrication Tow Only' && mdtRec.Service_Type__c == caseobj.FSL_Service_Type_Internal__c) 
                        || (caseobj.FSL_Service_Type_Internal__c != 'Extrication Tow Only' && (mdtRec.Service_Type__c == caseobj.ACG_Service_Type__c || mdtRec.Service_Type__c == NULL)))   
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
                   &&(mdtRec.Tow_Request_Reason__c == caseObj.Tow_Request_Reason__c       || mdtRec.Tow_Request_Reason__c == NULL)
                   &&(mdtRec.Battery_Service_Type__c == caseObj.Which_service_is_the_member_requesting__c       || mdtRec.Battery_Service_Type__c == NULL)
                   
         
                  ){
                        system.debug('@@@metadataRec@@@@'+mdtRec);
                      System.debug('What are Matched MDT: ' + mdtRec.Work_Type__c);//EMI
                        lstWorkType.add(mdtRec);
                  }
            }
            //Fall back Work Type for time being
            if(lstWorkType != null && !lstWorkType.isEmpty()) {
                System.debug(' @@@ ELSE @@@@@ ');
                lstWorkType.add(mdtList[0]);
            }
            System.debug('Work type(s) found: '+lstWorkType);
            if(lstWorkType.isEmpty()){      //If no Work Type was identified from the existing values.
                System.debug('CASE FIELDS: ' + caseObj);//EMI
				System.debug('MATCHING MDT LIST: ' + lstWorkType);//EMI
                throw new customException('No Active Work Type identified'); } 
            List<WorkType> workTypeID = [SELECT Id FROM WorkType WHERE Name=:lstWorkType[0].Work_Type__c LIMIT 1];
            //system.assertEquals('Raj','Raj51');
            if(!workTypeID.isEmpty()){
                System.debug('Work Type ID will be '+workTypeID[0].Id);
                String retVal = (workTypeID[0].Id+'#'+lstWorkType[0].T_Code__c+'#'+lstWorkType[0].PCC_DISP_CODE__c);
                return retVal;
            }
            else{
                throw new customException('No Work Type named "'+ lstWorkType[0].Work_Type__c +'" found');    //If the Work type name does not match with existing records 
            }
        }
        else{
            throw new customException('No ACTIVE Work Type mappings found');    //If there are no active metadata records
        }
    }	
	  

	 /*************EMI- Commented this method and updated below on 04/15/2025 for DRR Guest user error ******************/    
	/* Description: 
     * Method Name: createWorkOrderFeedItem
     * params: Case object, WorkOrder object
	*/
    /*
    public static void createWorkOrderFeedItem(Case caseObject, WorkOrder WO_Obj){
       /* FeedItem post = new FeedItem();
        post.ParentId = WO_Obj.id;
        post.Body = caseObject.ERS_Notes__c;
        insert post; */
    /*    List<FeedItem> listFeedItem = new List<FeedItem>();

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
        post1.ParentId = WO_Obj.id;
        post1.Visibility = 'AllUsers';
        post1.Body = feedBodyInfo;

        listFeedItem.add(post1);
        insert listFeedItem;
    }
    */
    /*************EMI- Start ******************/
    public static void createWorkOrderFeedItem(Case caseObject, WorkOrder WO_Obj) {
        if (UserInfo.getUserType() == 'Standard') { // Only internal users
            List<FeedItem> listFeedItem = new List<FeedItem>();
            String feedBodyInfo = 'Service Type: ' + caseObject.ACG_Service_Type__c;
            
            if (caseObject.Locksmith_Issue__c != null) {
                feedBodyInfo += ', Key Issue: ' + caseObject.Locksmith_Issue__c;
            }
            if (caseObject.ERS_Notes__c != null) {
                feedBodyInfo += ', Notes Detail: ' + caseObject.ERS_Notes__c;
            }
            
            FeedItem post = new FeedItem();
            post.ParentId = WO_Obj.Id;
            post.Visibility = 'AllUsers';
            post.Body = feedBodyInfo;
            
            listFeedItem.add(post);
            
            try {
                insert listFeedItem;
            } catch (DmlException ex) {
                System.debug('FeedItem insert failed: ' + ex.getMessage());
            }
        } else {
            System.debug('FeedItem creation skipped for non-internal user.');
        }
    }
    
      /*************EMI- End ******************/
    
    /* Description: Create Service Appointments related to Work Order.
     * Method Name: createServiceAppointment
     * params: WorkOrder object.
	*/
    public static Id createServiceAppointment(WorkOrder objWO){
        //WorkOrder wo = [SELECT WorkOrderNumber,Scheduling_Policy__c FROM WorkOrder WHERE Id =:objWO.Id LIMIT 1];
        List<ServiceAppointment> lstSA = new List<ServiceAppointment>();
        Boolean isTow = false;
        /*Breakdown Appointment Creation*/
        ServiceAppointment breakdownSA = INTFSLWorkOrderIntake.createServiceAppointment('Breakdown Appointment', objWO, NULL);
        INTFSLWorkOrderIntake.breakdownAddressLoader(breakdownSA,objWO);
        breakdownSA.FSL_IsLight_Service__c = true;
        breakdownSA.Landmark__c = objWO.Landmark__c;
        lstSA.add(breakdownSA);
        
        /*Tow Appointment creation*/
        if(objWO.Is_Tow_WorkType__c){
            isTow = true;
            ServiceAppointment towSA = INTFSLWorkOrderIntake.createServiceAppointment('Tow Appointment', objWO, NULL);
			towSA.Tow_Destination_Name__c = objWO.Tow_Destination_Name__c;
            INTFSLWorkOrderIntake.towAddressLoader(towSA,objWO);
            lstSA.add(towSA);
        }
        
        try{
            if(!lstSA.isEmpty()){
                insert lstSA;
                if(!Test.isRunningTest()){
                    objWO.Scheduling_Policy__c = [SELECT Id,Name FROM FSL__Scheduling_Policy__c WHERE Id=:lstSA[0].FSL__Scheduling_Policy_Used__c LIMIT 1].Name;    
                    update objWO;
                }
                if(isTow){
                    Id brkdownApp_Id = [SELECT Id FROM ServiceAppointment WHERE Id = :lstSA[0].Id LIMIT 1].Id;
                    lstSA[1].FSL__Related_Service__c = brkdownApp_Id;
                    lstSA[1].FSL__Time_Dependency__c = 'Start After Finish';
                    update lstSA[1];
                }
                scheduleAppointment(lstSA, isTow);
            }
		
        }catch(Exception e){
             throw new AuraHandledException('Service Appointment could not be created'); 
        }
        return lstSA[0].Id;
    }
    
	/* Description: Method to schedule the Service Appointment.
     * Method Name: scheduleAppointment
     * params: List<ServiceAppointment>
	*/
    public static void scheduleAppointment(List<ServiceAppointment> lstSA, Boolean isTow){
        if(isTow){  //If Tow, create a Time Dependency
          FSL__Time_Dependency__c FTD = INTFSLWorkOrderIntake.createAppointmentDependency(lstSA[0],lstSA[1]);
          insert FTD;
          INTFSLWorkOrderIntake.scheduleCall(lstSA[0],lstSA[1]);
        }
        else{ 
            INTFSLWorkOrderIntake.scheduleCall(lstSA[0],NULL);
        }       
    }
   
	 /* Description: To validate the Submitted Case.
     * Method Name: validateCase
     * params: Case obj
	*/
	public static void validateCase(Case objcase){
       String validationMsg = ''; 
       if(objCase.Status == 'Canceled'){
           throw new customException('Work Orders cannot be created once the Case is canceled.');
       }
       else{
           Integer count = 0;
            if(objcase.AccountId == Null){
                validationMsg += '\n'+(++count)+'. '+'Member information is missing';  }
        
            if(objcase.ACG_Service_Type__c==null){
                validationMsg += '\n'+(++count)+'. '+'Service type information is missing'; }
        
            if(objcase.ACG_Case_Contact_Number__c==null){
                validationMsg += '\n'+(++count)+'. '+'Member contact information is missing';   }
        
            if(objcase.Vehicle_Geolocation__c==null){
                validationMsg += '\n'+(++count)+'. '+'Breakdown information is missing';    }
        
            if(objCase.ACG_Service_Type__c == 'Tow' && objCase.Tow_Geolocation__c == NULL && objCase.Requested_Destination_Unavailable__c == false){
                validationMsg += '\n'+(++count)+'. '+'Tow Destination information is missing';  }
        
            if( objCase.ACG_Service_Type__c != 'Home Lockout' && objcase.Member_Vehicle_Type__c==null){
                validationMsg += '\n'+(++count)+'. '+'Vehicle information is missing';  }
        
            if( objCase.ACG_Service_Type__c == 'Locksmith' && objcase.Locksmith_Issue__c==null){
                 validationMsg += '\n'+(++count)+'. '+'Key Issue information is missing';  }  

            if( objCase.ACG_Color__c == null){
                 validationMsg += '\n'+(++count)+'. '+'Vehicle Color information is missing';  }  
            
            if( objCase.ACG_Year__c == null){
                validationMsg += '\n'+(++count)+'. '+'Vehicle Year information is missing';  }  
            
            if( objCase.ACG_Make__c == null){
                validationMsg += '\n'+(++count)+'. '+'Vehicle Make information is missing';  }  
                
            if( objCase.ACG_Model__c == null){
                validationMsg += '\n'+(++count)+'. '+'Vehicle Model information is missing';  }  
                

            // ERS-230821 Changes ACG to ACE Type Impairment handling
            // if( (objcase.Remaining_Entitlement__c != NULL && Integer.valueOf(objcase.Remaining_Entitlement__c) <=0 ) && objcase.Non_Active_Dues_Paid__c == false && objcase.Over_Entitlement_Fee_Paid__c==False && objcase.Override_Reason__c==NULL && !objcase.CDX_Motorcycle_Coverage__c && objcase.Account.RecordType.DeveloperName == 'ACG_Member'){
            //     validationMsg += '\n'+(++count)+'. '+'The member has reached their maximum allotted entitlements';  }
            
            // ERS-230821 Changes ACG to ACE Type Impairment handling
			//  if( objcase.Account.ACG_Membership_Status__c != 'Active' && objcase.Non_Active_Dues_Paid__c == false
            //  && objcase.Account.RecordType.DeveloperName == 'ACG_Member'){
            //     validationMsg += '\n'+(++count)+'. '+'The membership status is Non-Active with No Dues Paid';  }
          
            // ERS-230821 Changes ACG to ACE Type Impairment handling
            //   if( (objcase.Account.ACG_Membership_Status__c == 'Cancelled' || objcase.Account.ACG_Membership_Status__c == 'Lapsed')
            //      && objcase.Non_Active_Dues_Paid__c == true
            //      && objcase.Same_Day_Service_Fee_Paid__c == false
            //      && objcase.Account.RecordType.DeveloperName == 'ACG_Member'){
            //         validationMsg += '\n'+(++count)+'. '+'The membership status is Non-Active with No Same Day Service Fee Paid';  }

            // ERS-230821 Changes ACG to ACE Type Impairment handling
            // if( (objcase.Account.ACG_Membership_Status__c == 'Pending' || objcase.Account.ACG_Membership_Status__c == 'Renewal') 
            //    && objcase.Same_Day_Service_Fee_Paid__c == true
            //  && objcase.Account.RecordType.DeveloperName == 'ACG_Member'){
            //     validationMsg += '\n'+(++count)+'. '+'This member does not require a Same Day Service Fee to be paid';  }     
           
            // 2025-05-23 JWO for SSFI-1195
            // removed "||  objCase.Reconcile_Entitlement__c == false" condition 
            // updated "objCase.Information_Impairment__c == false" to "objCase.Impairment__r.Information_Only__c == true"
            if ( objCase.Impairment__c != null && !String.IsBlank(objCase.Impairment__c) ) {
                if ( objCase.Impairment_Payment_Collected__c || objCase.Impairment_COD_Payment__c  ||
                     objCase.Impairment_Supervisor_Override__c || (objCase.Impairment__r.Payment_Required__c == false) 
                     || objCase.Impairment__r.Information_Only__c == true) {
                    // The impairment related payment is arranged or waived or no payment is required
                }
                else {
                    validationMsg += '\n'+(++count)+'. '+'This member has an unresolved impairment. This case cannot be submitted into a Work Order';
                }
            }
            
            if(! String.isBlank(validationMsg)){
                throw new customException(validationMsg);
            }
        } 
   }
     
    public Static string validateClubCode(Case objCase){
        List<Zip_Code__c> cm = [SELECT Club_Code__c FROM Zip_Code__c WHERE Name =:objCase.Vehicle_Location_Postal_Code__c AND Club_Code__c = :Label.FSL_SourceClubCode LIMIT 1];
        if(cm.size() > 0){ //  && cm[0].Club_Code__c == Label.FSL_SourceClubCode
            return cm[0].Club_Code__c;
        }
        else {
            throw new customException('This Member is not broken down in this Territory, this is a Call Mover Call');
        }
    }
  
    /* Description: To log the Exceptions occurring during Case submission.
     * Method Name: updateExceptionFieldOnCase
     * params: String, String
	*/
    @AuraEnabled
    Public static void updateExceptionFieldOnCase(String caseId, String msg){

        String ExceptionVals = '';
        Case caseRec = [Select id, Exception__c,Status,Technical_Issue__c from Case Where Id = :caseId];
        String ExceptionsToAdd = caseRec.Exception__c;
        String currentExceptionVal =caseRec.Exception__c != NULL? caseRec.Exception__c : '';
        if(msg == 'This Member is not broken down in this Territory, this is a Call Mover Call'){
		    caseRec.ERS_BypassStatusValidationforFlow__c = true; 
            caseRec.Status = 'Closed - National Territory';
            system.debug(caseRec.Status);
                        
        }else{
            
            if(msg.contains('Member information is missing')){
                ExceptionVals += 'No Member Info;' ;
            }
            if(msg.contains('Service type information is missing')){
                ExceptionVals += 'No Service Type;';

            }
            if(msg.contains('Member contact information is missing')){
                ExceptionVals +='No Member Contact Number;';
                
            }
            if(msg.contains('Breakdown information is missing' )){
                ExceptionVals += 'Not Spotted;';

            }
            if(msg.contains('Vehicle information is missing')){
                ExceptionVals += 'No Vehicle;';

            }
            if( msg.contains('Tow Destination information is missing')){
                ExceptionVals += 'No Tow To Decision;' ;

            }
            if( msg.contains('Key Issue information is missing')){
                ExceptionVals += 'No Key Issue;' ;

            }
            if( msg.contains('The member has reached their maximum allotted entitlements') 
                || msg.contains('Work Orders cannot be created once the Case is canceled.')
                || msg.contains('You are not eligible for this service, please check member\'s membership level')
                || msg.contains('Contact System Admin')){
                    ExceptionVals += 'Other Technical Issue;';
					if(msg.contains('Contact System Admin')){
						String error = msg.substringAfter('Contact System Admin').trim();
						if(String.isNotBlank(error)) {caseRec.Technical_Issue__c = error; }
                }
            }

            if(String.isBlank(currentExceptionVal)){
                ExceptionsToAdd = ExceptionVals ; 
             }
             else{
                 for(String ExceptionVal : ExceptionVals.split(';')){
                      if(!(currentExceptionVal.contains(ExceptionVal.trim()))){
                            ExceptionsToAdd = currentExceptionVal +';'+ ExceptionVal.trim();    
                        }
                    }
                }
            caseRec.Exception__c = ExceptionsToAdd;
        }
        if(String.isNotBlank(ExceptionsToAdd)){
        Update caseRec;
    }
    }
    
    /* Description: Validate if the member is eligible for the selected Vehicle type
     * Method Name: validateMembershipCoverage
     * params: Id, String
    */
    @AuraEnabled
    public static boolean validateMembershipCoverage(Id caseId, String vehicleTypeFromTriage){
       
        Case obj = [SELECT id,Case_Membership_Level__c,Vehicle_Location_State__c,Vehicle_Location_Postal_Code__c,ACG_Service_Type__c,Member_Vehicle_Type__c,Account.AAA_Special_Member_Type__c FROM Case where id = :caseId LIMIT 1];
        
        String vehicleType = vehicleTypeFromTriage != NULL ? vehicleTypeFromTriage : obj.Member_Vehicle_Type__c;
        String benefitLevel = obj?.Case_Membership_Level__c?.toUpperCase();
        
        boolean memberCoverage = false;
        

        if(vehicleTypeFromTriage != NULL){      //When called from the Triage component
            List<Zip_Code__c> cm = [SELECT  Name,Club_Name__c FROM Zip_Code__c WHERE Name =:obj.Vehicle_Location_Postal_Code__c LIMIT 50000];
            if(cm.isEmpty()){       //If location is out of ACG Territory (CallMover Scenario), do not validate coverage
                memberCoverage = true;    
                return memberCoverage;
            }
        }

        // Add special coverage lookup for those service types, which are not tied to Vehicle Types )
        List<Membership_Coverage_Metadata__mdt> mbrshipCoverageMetadata = new List<Membership_Coverage_Metadata__mdt>();

        if ( obj.ACG_Service_Type__c == 'Home Lockout') {

            if(!String.isBlank(obj.Case_Membership_Level__c) && !String.isBlank(obj.Vehicle_Location_State__c) ){
                mbrshipCoverageMetadata.addAll([SELECT Vehicle_Type__c,State__c,Service_Type__c,Membership_Level__c,Max_Tow_Miles__c,X200_Miles_Coverage__c,ACE__c,Special_Membership__c 
                                                FROM Membership_Coverage_Metadata__mdt 
                                                WHERE State__c = :obj.Vehicle_Location_State__c 
                                                AND Service_Type__c = :obj.ACG_Service_Type__c 
                                                AND ACE__c = true 
                                                AND (Membership_Level__c = :benefitLevel ) 
                                        ]);

            }
        }     
        else if(!String.isBlank(obj.Case_Membership_Level__c) && !String.isBlank(obj.Vehicle_Location_State__c) && !String.isBlank(obj.ACG_Service_Type__c) && !String.isBlank(vehicleType)){
             
             mbrshipCoverageMetadata.addAll([SELECT Vehicle_Type__c,State__c,Service_Type__c,Membership_Level__c,Max_Tow_Miles__c,X200_Miles_Coverage__c,ACE__c,Special_Membership__c 
                                                                          FROM Membership_Coverage_Metadata__mdt 
                                                                          WHERE State__c = :obj.Vehicle_Location_State__c 
                                                                          AND Service_Type__c = :obj.ACG_Service_Type__c 
                                                                          AND ACE__c = true 
                                                                          AND (Vehicle_Type__c like :(vehicleType+';%')  OR Vehicle_Type__c like :('%;'+vehicleType+';%') OR Vehicle_Type__c like :('%;'+vehicleType)  OR Vehicle_Type__c like :(vehicleType))
                                        								  AND (Membership_Level__c = :benefitLevel )
                                      ]);
            mbrshipCoverageMetadata.addAll([SELECT Vehicle_Type__c,State__c,Service_Type__c,Membership_Level__c,Max_Tow_Miles__c,X200_Miles_Coverage__c,ACE__c,Special_Membership__c 
                                                                          FROM Membership_Coverage_Metadata__mdt 
                                                                          WHERE State__c = :obj.Vehicle_Location_State__c 
                                                                          AND Service_Type__c = :obj.ACG_Service_Type__c 
                                                                          AND ACE__c = true 		 
                                                                          AND (Vehicle_Type__c like :(vehicleType+';%')  OR Vehicle_Type__c like :('%;'+vehicleType+';%') OR Vehicle_Type__c like :('%;'+vehicleType) OR Vehicle_Type__c like :(vehicleType))
                                       									  AND Special_Membership__c != NULL
                                        								  AND ( Special_Membership__c = :benefitLevel)
                                      ]);
        }
        System.debug('membership metadata-->'+mbrshipCoverageMetadata);
        if(mbrshipCoverageMetadata.size()>0)
        {
            memberCoverage = true;
        }
        return memberCoverage;
    }



    public class CDXWrapper{  // Values passed to the LWC component
        @AuraEnabled public boolean showModal = false;
        @AuraEnabled public String CDXMessage = '';
     }
    
    /* Description: To display CDX Messages on the Triage component
    * Method Name: showCDXMessage
    * params: String, String, String, String, String
    */
    @AuraEnabled
    public static CDXWrapper showCDXMessage(String CDXAuthCode, String accountId, String CDXAuthLevel, String CDXStatus,String homeClub){
        CDXWrapper respWrap = new CDXWrapper();
        if(String.isNotBlank(CDXAuthCode)){
            homeClub = homeClub == 'null' || homeClub == null ? '':homeClub;
            
            if(CDXAuthLevel == 'X'){
                respWrap.showModal = true;    
                respWrap.CDXMessage = 'Please call the Member\'s home club <b>'+homeClub+'</b>.';
            }
            else if(CDXStatus == 'Active' && CDXAuthLevel == 'C'){
                respWrap.showModal = true;    
                respWrap.CDXMessage = 'The non-local Member has a current status of Active but the Member is out of entitlements because CDX Authorization Level = COD (C). Please call the home club <b>'+homeClub+'</b> to verify membership status';
            }
            else if(CDXStatus == 'Pending'){
                respWrap.showModal = true;
                respWrap.CDXMessage = 'The non-local Member has a current status of Pending. Please call the home club <b>'+homeClub+'</b> to verify membership status.';
            }
            /*else if(CDXStatus == 'Cancelled'){
                respWrap.showModal = true;
                respWrap.CDXMessage = 'The non-local Member has a current status of Cancelled. Please call the home club <b>'+homeClub+'</b> to verify membership status.';
            }*/
        }
        else{
            respWrap.showModal = false;
        }

        return respWrap;
    }
	
    @AuraEnabled
    public static Double getDistanceInMilesUsingAPI(String origin_Lat, String origin_Long, String dest_Lat, String dest_Long){
        INTDistanceMatrixAPIResponseWrapper response = new INTDistanceMatrixAPIResponseWrapper();
        response = ACG_INTPlacesautocompleteAPIController.getDistanceMatrixDetails(origin_Lat,origin_Long,dest_Lat,dest_Long,'imperial');
        String distance = response?.rows[0]?.elements[0]?.distance?.text;
        Double dist_Miles = 0;

        if(distance != NULL){
		distance = distance.replace(',','');
            if(distance.containsIgnoreCase('mi')){
                dist_Miles = Double.valueOf(distance.replace('mi',''));
            }
            if(distance.containsIgnoreCase('ft')){
                dist_Miles = 0.000189394 *  Double.valueOf(distance.replace('ft',''));
            }
    }
        return dist_Miles;
    }
	/*
	//Utility method for Flow: ERS Update Case Status wrt Work Order
    public class FlowInputs {
        @InvocableVariable public String caseId;
        @InvocableVariable public String newStatus;
    }
    @InvocableMethod(label='Update Case Status wrt WorkOrder')
    public static void updateCaseStatusFromFlow_IM( List<FlowInputs> flowInputs){
        updateCaseStatusFromFlow_Future(flowInputs[0].caseId, flowInputs[0].newStatus);
    }
    
    @future
    public static void updateCaseStatusFromFlow_Future(Id caseId, String newStatus){
        if(caseId != NULL){
        	Case cs = new Case(Id = caseId);
            cs.ERS_BypassStatusValidationforFlow__c = true;
            cs.Status = newStatus;
            update cs;
            cs.ERS_BypassStatusValidationforFlow__c = false;
            update cs;    
        } 
        
    }
	*/
}