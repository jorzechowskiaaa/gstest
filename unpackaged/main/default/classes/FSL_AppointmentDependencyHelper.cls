/**
 * @Descrption        This class will serve as the helper for creating appointment
 *                    dependencies for tow work types
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   12-18-2020   Clement Shiu   ERS-220606: Add Error Handling for Row Lock  
 * 2.0   12/28/2020   Dylan Truong         ERS-220602 When a call comes in to FSL without Lat/Long - try to geocode call
 * 3.0   01-29-2021   Shankar Krishnan ERS-220870, ERS-220872 extracted original exception message
 * 4.0   2/12/2021    Dylan Truong ERS-221339 UAT issue tow appointment is not working properly when auto schedule or dispatch
**/

public with sharing class FSL_AppointmentDependencyHelper {

    public static void createAndScheduleServiceAppointments(WorkOrder wo, FSL_JSonParserWorkOrder jsonParser) {
        // List<ServiceAppointment> saInsertList = new List<ServiceAppointment>();     // *** Service Tech Team: never used variable  ***   
        Map<Id, ServiceAppointment> saToUpdateMap = new Map<Id, ServiceAppointment>();     // *** Service Tech Team: added a map variable to update SAs after all operations ***   
        
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id, Name, EstimatedDuration FROM WorkType]);  
        
        String legacyPrioritycode = wo.Priority_Code__c != null ? wo.Priority_Code__c : 'NA';
        
        // gets the correct scheduled policy from custom settings
        FSL_PriorityCode_Mapping__c schedulingPolicyMapping = FSL_PriorityCode_Mapping__c.getInstance(legacyPrioritycode);            

        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
        ServiceAppointment breakdownSA = createServiceAppointment('Breakdown Appointment', false, wo, null, null, schedulingPolicyMapping, jsonParser);
        saToUpdateMap.put(breakdownSA.Id, breakdownSA);     //   ***  Service Tech Team: Collecting the Appointment to update it in the method end   ***

        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

        //  SNK ERS-219715  line of code moved here from inside createServiceAppointment, so we do not have to use a static slaWrapper (old version of FSL_SchedPolicies_ArrivalWindow)
        //  Do this only for the breakdown SA
        //  ***  Service Tech Team: variable is moved here, to local scope *** 
        Map<Id, FSL__Scheduling_Policy__c> policyMap = new Map<Id, FSL__Scheduling_Policy__c>([SELECT Id, Name FROM FSL__Scheduling_Policy__c]);
        FSL_Schedule_Config scheduleConfig = FSL_SchedulingUtility.populateArrivalWindowAndPolicy(breakdownSA, wo, policyMap);

        ServiceAppointment towSA;
        
        System.debug('------wo-------'+ wo);

        if (wo.Is_Tow_WorkType__c) {
            System.debug('------------- THAT\'s A TOW WORKTYPE   -----------------------');  //  *** Service Tech Team debug ***
            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
            towSA = createServiceAppointment('Tow Appointment', true, wo, null, null, schedulingPolicyMapping, jsonParser);
            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
            
            saToUpdateMap.put(towSA.Id, towSA);     //   ***  Service Tech Team: Collecting the Appointment to update it in the method end   ***

            //Relate Breakdown & Tow Service appointments.
            breakdownSA.FSL__Related_Service__c = towSA.id;
            breakdownSA.FSL__Same_Resource__c = true;
            towSA.FSL__Related_Service__c= breakdownSA.id;
            towSA.FSL__Same_Resource__c = true;

            // ***  Service Tech Team: Service Appointments are collected to saToUpdateMap to be updated at the method end   ***

            // List<ServiceAppointment> relatedAppointments = new List<ServiceAppointment>();
            // relatedAppointments.add(breakdownSA);
            // relatedAppointments.add(towSA);
            
            // check for tow lat/lon, add duration to appointment if none exists
            if (wo.Tow_Location__Latitude__s == null && wo.Tow_Location__Longitude__s == null) {
                //Dylan Change ERS-220602 -Lat/Long
                if (isQualifyAddress(towSa)) {
                    System.debug('Lat/Long Complete address');
                    List<ServiceAppointment> saList = new List<ServiceAppointment>();
                    saList.add(towSa);
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                    FSL_AddressTriggerHandler.sAsWithNewAddress(saList);
                    System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                }
                towSA.Duration = worktypeIdMap.get(wo.WorktypeId) != null && towSA.Duration == null ? worktypeIdMap.get(wo.WorktypeId).EstimatedDuration : towSA.Duration;
                towSA.Duration = towSA.Duration == null ? 0 : towSA.Duration; 
                towSA.Duration = towSA.Duration + Integer.valueOf(System.Label.FSL_Tow_Duration_Extension);
                towSA.FSL_Needs_Address__c = true;
                
                // TODO: Add flag to highlight these appointments need a tow destination
                //Setting same Lat & Langs of Breakdown for not overlaping with Travel time when tow is not geocoded.
                towSA.longitude = breakdownSA.longitude;
                towSA.latitude = breakdownSA.latitude;
            }
                      
            FSL__Time_Dependency__c appointmentDependency = FSL_AppointmentDependencyHelper.createAppointmentDependency(breakdownSA, towSA);
            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***

        }       

        // ***  Shankar - Incorporated a change made in FSL-2021-17, which moved a bunch of code into the ScheduleQueueableAppointment method
        // ***  So, I ended up reversing the expression in the if condition below to how it was before to avoid an extra else condition        
        if (wo.Servicing_Technology_Type__c == 'Landline') {      //  ***  Service Tech Team: change the condition as the previous one was moved to FSL_WorkOrderIntake.createWorkOrder()  ***            
            /*breakdownSA.FSL__InJeopardyReason__c = 'Landline Facility';
            breakdownSA.FSL__InJeopardy__c = true;            
            if (towSA != null) {
                towSA.FSL__InJeopardyReason__c = 'Landline Facility';
                towSA.FSL__InJeopardy__c = true;                
            }*/
           
            try {
                System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
                //Commenting out for this build
                //createLandlineFacilityCase(wo, breakdownSA);
                System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
            } catch(Exception ex) {
                System.debug('Exception while creating Landline Facility Case : ' + ex.getMessage());  //  *** Service Tech Team debug ***
            }
        } 
        else if (wo.Servicing_Technology_Type__c == ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK) {
            ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService = new ThirdPartyIntegration.Factory().createService();
            thirdPartyIntegrationService.sendDispatchOfferPlatformEvent(wo);
        }

         // Calls that are not geo-coded are not auto-scheduled
        else if (wo.Breakdown_Location__Latitude__s != null && wo.Breakdown_Location__Longitude__s != null) {
            FSL_AppointmentDependencyHelper.ScheduleQueueableAppointment(breakdownSA,towSA,wo,worktypeIdMap,scheduleConfig, policyMap, false); //AGB added for SSFI-560 11/19/24
        }            
        try{
            update saToUpdateMap.values();
        }
        catch(Exception e)
        {
            system.debug('Error while updating SA:'+e.getMessage()+' at line '+e.getLineNumber());
		}
        
  
    }

    public static void ScheduleQueueableAppointment(ServiceAppointment breakdownSA, ServiceAppointment towSA, WorkOrder wo, 
                                                    Map<Id,WorkType> worktypeIdMap,FSL_Schedule_Config scheduleConfig, Map<Id, FSL__Scheduling_Policy__c> policyMap) {   
       ScheduleQueueableAppointment(breakdownSA, towSA, wo, worktypeIdMap, scheduleConfig, policyMap, false);
        
    } //AGB added for SSFI-560 11/19/24

    public static void ScheduleQueueableAppointment(ServiceAppointment breakdownSA, ServiceAppointment towSA, WorkOrder wo, 
                                                    Map<Id,WorkType> worktypeIdMap,FSL_Schedule_Config scheduleConfig, Map<Id, FSL__Scheduling_Policy__c> policyMap, Boolean isFromAutosceduleRetryBatch) {   //AGB added for SSFI-560 11/19/24

        // Calls that are not geo-coded are not auto-scheduled
        String req1;
        try {            
            if (wo.Schedule_Freeze__c == null) {    //  ***  Service Tech Team: changed the condition as the previous one was moved to FSL_WorkOrderIntake.createWorkOrder()  ***              
                Timezone tz = Timezone.getTimeZone(wo.ServiceTerritory.OperatingHours.Timezone);
                Service_Territory_Scheduling_Override__c schedOverRide = FSL_SchedulingUtility.checkIfScheduleOverrideApplies(wo.ServiceTerritoryId, tz, breakdownSA.ArrivalWindowStartTime, worktypeIdMap, wo.WorkTypeId);
                System.debug('SchedOverRide=====>' + schedOverRide);
                if (schedOverRide != null) {
                    FSL_SchedulingUtility.addResourcePreferencesFromOverride(wo.Id, schedOverRide);
                    FSL__Scheduling_Policy__c schedPolicy = new FSL__Scheduling_Policy__c(Id = schedOverRide.Scheduling_Policy__c, Name = schedOverRide.Scheduling_Policy__r.Name);

                    //SNK ERS-219715
                    // Perform the override in the scheduleConfig
                    scheduleConfig.schedulingPolicy = schedPolicy.Id;
                }

                //SNK ERS-219715
                // Create a Data Transfer Object containing relvant information for scheduling and enqueue the scheduling request
                FSL_AppointmentScheduleQueueable appointmentQueueable =  FSL_SchedulingUtility.createScheduleQueuable(breakdownSA, towSA, scheduleConfig, policyMap, isFromAutosceduleRetryBatch); //AGB added for SSFI-560 11/19/24
                System.enqueueJob(appointmentQueueable);                
            }
        }
        catch(Exception e) {
            FSL_ApplicationLogCreator.calloutLogger(req1, e.getStackTraceString(), e.getMessage(), 'Scheduling', true, String.valueOf(breakdownSA.id), '', 'FSL.ScheduleService');
        }        
    }
    
    public static FSL__Time_Dependency__c createAppointmentDependency(ServiceAppointment breakdownSA, ServiceAppointment towSA){
        FSL__Time_Dependency__c appointmentDependency = new FSL__Time_Dependency__c();
        appointmentDependency.FSL__Root_Service_Appointment__c = breakdownSA.id;
        appointmentDependency.FSL__Service_Appointment_1__c = towSA.id;
        appointmentDependency.FSL__Service_Appointment_2__c = breakdownSA.id;
        appointmentDependency.FSL__Same_Resource__c = true;
        //UAT_CAR_ Tows are scheduling the Breakdown appt to a service resource who is off shortly.  The tow appt is then scheduled when the service resource is scheduled back.
        appointmentDependency.FSL__Dependency__c = 'Immediately Follow';
        insert appointmentDependency;
        return appointmentDependency;       
    }
    
    public static ServiceAppointment createServiceAppointment(String subject, Boolean isTow, WorkOrder wo, WorkOrderLineItem towLineItem, WorkOrderLineItem breakdownLineItem, FSL_PriorityCode_Mapping__c pCode, FSL_JSonParserWorkOrder jsonParser){
        ServiceAppointment sa = new ServiceAppointment();
        try{
            sa.FSL__Auto_Schedule__c = false;
            sa.Subject = subject;
            sa.FSL__GanttLabel__c = wo.Call_Id__c;        
            sa.Schedule_Overridden_By__c = 'None';
            sa.pta__c = wo.pta__c;
            sa.Spotted_Timestamp__c = System.now();
           // sa.Case__c = wo.CaseId; // https://salesforce.atlassian.net/browse/PR893288-682 by sanket
            // sa.ServiceTerritoryId = wo.ServiceTerritoryId;   //    ***  Service Tech Team: Commented out the line that's causing the row lock error of the Service Territory ***
            sa.Original_Service_Territory__c = wo.ServiceTerritoryId;
            
            if (wo.ServiceTerritoryId == null || (wo.Longitude == null && wo.Latitude == null)) {   //  ***  Service Tech Team: merge "if"-s with the same body in one "if"  ***
                /*sa.FSL__InJeopardyReason__c = 'No Lat/Long';
                sa.FSL__InJeopardy__c = true;*/
            }        
            
            sa.Work_Order_Priority__c = wo.Priority;
            sa.D3_Call_Id__c = wo.Call_Id__c;
            sa.ParentRecordId = wo.Id;
            sa.Work_Order__c = wo.Id;
            sa.D3_AAR_Id__c = wo.D3_AAR_Id__c;
            
            if (!wo.Is_Tow_WorkType__c) {
                sa.FSL_IsLight_Service__c = true;
            }
            
            sa.ContactId = wo.ContactId;
            //ERS-230874 Glympse Removal - Part I
            //sa.Glympse_EnRoute__Glympse_EnRoute_Notify__c = false;
            
            if (isTow) {
                sa = towAddressLoader(sa, wo);
                sa.Payment_Required__c = wo.Payment_Required__c;//EMI---SSFI-700
            } else {
                //sa.Payment_Required__c = jsonParser.calls[0].payment.required;//EMI---commented for--SSFI-700
                sa.Payment_Type__c = jsonParser.calls[0].payment.paymentType;
                sa.Payment_Required__c = wo.Payment_Required__c;//EMI---SSFI-700
                sa = breakdownAddressLoader(sa, wo);                
                //ERS-230874 Glympse Removal - Part I
                //if (wo.ContactId != null) {
                //    sa.Glympse_EnRoute__Glympse_EnRoute_Notify__c = wo.Contact.Sms_Optin__c;
                //}
            }                       

            // auto populate secondary service territory from custom 
            System.debug('------------wo.State-------------'+wo.State);
               
            if('Critical'.equals(wo.Priority)) {
                sa.FSL__Emergency__c = true;
                sa.FSL__GanttColor__c = '#f47142';
            }
            setScheduleOverLowerPriority(sa, pCode);
            if (String.isNotBlank(wo.Non_Emergency_Appointment_Time__c)) {
                sa.EarliestStartTime =  Datetime.valueOfGmt(wo.Non_Emergency_Appointment_Time__c.replace('T',' '));
                sa.Member_Scheduled__c = true;
            } else {
                sa.EarliestStartTime = System.now();
            } 
            sa.FSL_Member_Vehicle_Name__c = wo.Vehicle_Profile__c;
            if(wo.Call_Source__c != null) {
                sa.Call_Source__c = wo.Call_Source__c;
            }

            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***
            insert sa;
            System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());  //  *** Service Tech Team debug ***           

        } catch(DmlException e) {
            //ERS-220606: Check to see if it is a Row Lock Error, if it is, then throw up a custom exception
            if (e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                throw new FSL_CustomExceptions.ExclusiveRowLockException(e.getMessage());
            }
            else {
                throw e;
            }
        }
      
        return sa;
    }

    public static void setScheduleOverLowerPriority(ServiceAppointment sa, FSL_PriorityCode_Mapping__c pcm) {
        if (pcm != null) {
            sa.FSL__Schedule_over_lower_priority_appointment__c = pcm.Schedule_over_Lower_Priority_Appointment__c; 
        }     
    }

    @testVisible
    private static void populateArrivalWindowFromSetting(ServiceAppointment sa){
        String arrivalWindowLabel = System.Label.FSL_Arrival_Window_Field;
        if(String.isNotBlank(arrivalWindowLabel)){
            sa.ArrivalWindowEndTime = (DateTime) sa.get(arrivalWindowLabel);
        }else{
            sa.ArrivalWindowEndTime = (DateTime) sa.get('pta__c');
        }
    } 
    //@testVisible
   /* private static void createLandlineFacilityCase(WorkOrder wo,ServiceAppointment sa) {
        List<FSL_TroubleCode__c> trCodeList = [SELECT Id,Description__c,Type__c From FSL_TroubleCode__c WHERE Type__c = 'PACESETTER' AND Work_Order__c =:wo.Id];
        WorkOrder workOrderRec = [SELECT Id,workOrderNumber,workType.Name FROM WorkOrder WHERE id =:wo.Id];
        Id nonTechRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Non Technology').getRecordTypeId();
        Case cs = new Case();
        String paceSetterDesc = '';
        if(!trCodeList.isEmpty()) {
            paceSetterDesc = trCodeList[0].Description__c;
        }
        
        cs.Number_Of_Passengers__c = wo.Number_Of_Passengers__c;
        cs.FSL_Service_Appointment_Territory__c = wo.ServiceTerritoryId;
        cs.FSL_Vehicle_Description__c = wo.Vehicle_Profile__c;
        cs.FSL_Work_Order__c = wo.Id;
        cs.subject = wo.Call_Id__c+' '+'Landline Technology';
        cs.contactId = wo.contactId;
        cs.FSL_Service_Appointment__c = sa.Id;      
        cs.FSL_Service_Appointment_Tow__c = sa.FSL__Related_Service__c != null ? sa.FSL__Related_Service__c : null;
        cs.recordTypeId = nonTechRecTypeId;
        cs.Origin = 'Automation';
        cs.FSL_Service_Type__c = workOrderRec.workType.Name+' - '+paceSetterDesc;
        
        //Assigning Case through the latest active assignment rule.
        AssignmentRule AR = [SELECT id FROM AssignmentRule WHERE SobjectType = 'Case' and Active = true limit 1];
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.id;
        Database.insert(cs, dmlOpts );
    }*/

    @TestVisible
    private static ServiceAppointment breakdownAddressLoader (ServiceAppointment sa, WorkOrder wo){
        Id breakdownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        sa.recordTypeId                              = breakdownRecordTypeId;
        sa.Street                                    = wo.Street;
        sa.City                                      = wo.City;
        sa.State                                     = wo.State;
        sa.PostalCode                                = wo.PostalCode;
        sa.Country                                   = wo.Country;
        sa.Latitude                                  = wo.Latitude;
        sa.Longitude                                 = wo.Longitude;
        sa.D3_Address_Geocode__Longitude__s          = wo.Longitude;
        sa.D3_Address_Geocode__Latitude__s           = wo.Latitude;
        sa.Cross_Street__c                           = wo.Cross_Street__c;
        sa.Cross_Street_2__c                         = wo.Cross_Street_2__c;
        sa.Landmark__c                               = wo.Landmark__c;
        sa.Location_Code__c                          = wo.Location_Code__c;
        //sa.Plus_Code__c                            = wo.Location_Plus_Code__c;
        sa.Mile_Marker__c                            = wo.Mile_Marker__c;
        sa.Highway__c                                = wo.Highway__c;
        sa.D3_ER_Mileage__c                          = wo.D3_ER_Mileage__c;
        sa.Driving_Directions__c                     = wo.Driving_Directions__c;
        sa.Street                                    = wo.Street;

        return sa;
    }

    @TestVisible
    private static ServiceAppointment towAddressLoader(ServiceAppointment sa, WorkOrder wo) {
        Id towRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
        sa.recordTypeId                              = towRecordTypeId;
        sa.Latitude                                  = wo.Tow_Location__Latitude__s;
        sa.Longitude                                 = wo.Tow_Location__Longitude__s;
        sa.Street                                    = wo.Tow_Street__c;
        sa.City                                      = wo.Tow_City__c;
        sa.State                                     = wo.Tow_State__c;
        sa.PostalCode                                = wo.Tow_Postal_Code__c;
        sa.Country                                   = wo.Tow_Country__c;
        sa.D3_Address_Geocode__Longitude__s          = wo.Tow_Location__Longitude__s;
        sa.D3_Address_Geocode__Latitude__s           = wo.Tow_Location__Latitude__s;
        sa.Cross_Street__c                           = wo.Tow_Cross_Street__c;
        sa.Cross_Street_2__c                         = wo.Tow_Cross_Street_2__c;
        sa.Landmark__c                               = wo.Tow_Landmark__c;
        //sa.Plus_Code__c                            = wo.Tow_Location_Plus_Code__c;
        sa.Tow_Destination_Name__c                   = wo.Tow_Destination_Name__c;
        sa.D3_Tow_Mileage__c                         = wo.D3_Tow_Mileage__c;
        sa.Drop_Box_Info__c                          = wo.Drop_Box_Info__c;

        sa.Street                                    = wo.Tow_Street__c;
        assignSAD3AARIDfromWorkOrder(sa, wo);

        return sa;
    }    

    @testVisible
    public static Boolean isQualifyAddress(ServiceAppointment sa) {
        Boolean isCompleteAddress = String.isNotBlank(sa.Street) && String.isNotBlank(sa.City) 
                                    && String.isNotBlank(sa.State) && String.isNotBlank(sa.PostalCode);
        return isCompleteAddress;
    }
 
    @testVisible
    private static void assignSAD3AARIDfromWorkOrder ( ServiceAppointment sa, WorkOrder wo ) {
        sa.D3_AAR_Id__c = wo.D3_AAR_Id__c;
    }    
    
}