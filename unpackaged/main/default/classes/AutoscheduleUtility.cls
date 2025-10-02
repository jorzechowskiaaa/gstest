public with sharing class AutoscheduleUtility {

    @InvocableMethod
    public static void invokeAutoschedule(List<String> serviceAppointmentIds) 
    {
        for (String saId : serviceAppointmentIds)
        {
            AutoscheduleUtility.autoschedule(saId, false);
        }
    } 
    
    public static void autoschedule(String recordId, Boolean isFromAutosceduleRetryBatch){ //AGB added for SSFI-560 11/19/24
        try {
        System.debug('autoschedule - '+recordId);
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id, Name, EstimatedDuration FROM WorkType]);  
        Map<Id, FSL__Scheduling_Policy__c> policyMap = new Map<Id, FSL__Scheduling_Policy__c>([SELECT Id, Name FROM FSL__Scheduling_Policy__c]);

        ServiceAppointment breakdownSA;
        ServiceAppointment towSA;

        List<String> ids = new List<Id>();
        ids.add(recordId);           

        ServiceAppointment rec = AutoscheduleUtility.fetchServiceAppointment(recordId);
        system.debug('rec - ' + rec);

        WorkOrder wo = [SELECT Id,Is_Tow_WorkType__c,Schedule_Freeze__c, ServiceTerritoryId, ServiceTerritory.OperatingHours.Timezone,WorkTypeId,External_ID__c,Call_Id__c,
            Call_Date__c,Goodwill_Indicator__c,Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,
            Vehicle_Type__c,RAP_Case_Number__c,Payment_Codes__c,Payment_Responsibility__c,Original_Member_Id__c,T_Code__c,
            Vehicle_Profile__c,FSL_Pacesetter__c,RecordTypeId,Priority
            FROM WorkOrder 
            WHERE Id = :rec.Work_Order__c LIMIT 1];


        if (wo.Is_Tow_WorkType__c)
        {
            ServiceAppointment relatedRec = AutoscheduleUtility.fetchServiceAppointment(rec.FSL__Related_Service__c);
            if (rec.Subject == 'Tow Appointment')
            {
                towSA = rec;
                breakdownSA = relatedRec;
            }
            else 
            {
                breakdownSA = rec;
            }
        }
        else 
        {
            breakdownSA = rec;
        }

        // System.debug('AQAC tow-'+towSA);
        // System.debug('AQAC breakdown-'+breakdownSA);
        // System.debug('AQAC WO-'+wo);
        // System.debug('AQAC policy-'+policyMap);
        FSL_Schedule_Config scheduleConfig = FSL_SchedulingUtility.populateArrivalWindowAndPolicy(breakdownSA, wo, policyMap);
        
        FSL_AppointmentDependencyHelper.ScheduleQueueableAppointment(breakdownSA, towSA, wo, worktypeIdMap,scheduleConfig, policyMap, isFromAutosceduleRetryBatch); //AGB added for SSFI-560 11/19/24

        // rec.Autoschedule_Retry_Count__c = rec.Autoschedule_Retry_Count__c + 1;
        update rec;

    } catch (Exception e) {
        system.debug('EXCEPTION >> ' + e.getMessage());
    }
}

private static ServiceAppointment fetchServiceAppointment(String saId)
{
    ServiceAppointment rec = [SELECT Id,Service_Resource__c,Member_Scheduled__c,SchedStartTime,FSL__Pinned__c,FSL__Related_Service__c,
        ParentRecordId,Status,Work_Order__c,Subject,ServiceTerritoryId,EarliestStartTime,PTA__c
        FROM ServiceAppointment 
        WHERE Id = :saId LIMIT 1];

    return rec;
}
}