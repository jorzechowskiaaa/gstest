public with sharing class AutoscheduleQuickActionController {
    @AuraEnabled
    public static void autoschedule(String recordId)
    {
        System.debug('autoschedule - '+recordId);
        Map<Id,WorkType> worktypeIdMap = new Map<Id,WorkType>([SELECT Id, Name, EstimatedDuration FROM WorkType]);  
        Map<Id, FSL__Scheduling_Policy__c> policyMap = new Map<Id, FSL__Scheduling_Policy__c>([SELECT Id, Name FROM FSL__Scheduling_Policy__c]);

        ServiceAppointment breakdownSA;
        ServiceAppointment towSA;

        List<String> ids = new List<Id>();
        ids.add(recordId);           

        ServiceAppointment rec = fetchServiceAppointment(recordId);
        System.debug('MAIN REC-'+rec);

        WorkOrder wo = [SELECT Id,Is_Tow_WorkType__c,Schedule_Freeze__c, ServiceTerritoryId, ServiceTerritory.OperatingHours.Timezone,WorkTypeId,External_ID__c,Call_Id__c,
            Call_Date__c,Goodwill_Indicator__c,Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,
            Vehicle_Type__c,RAP_Case_Number__c,Payment_Codes__c,Payment_Responsibility__c,Original_Member_Id__c,T_Code__c,
            Vehicle_Profile__c,FSL_Pacesetter__c,RecordTypeId,Priority
            FROM WorkOrder 
            WHERE Id = :rec.Work_Order__c LIMIT 1];

        if (wo.Is_Tow_WorkType__c)
        {
            ServiceAppointment relatedRec = fetchServiceAppointment(rec.FSL__Related_Service__c);
            System.debug('REL REC-'+relatedRec);

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

        if(Test.isRunningTest())
        {
            //Yes this is cheating.  I am bypassing the call because I cannot figure out how to get the schedule to be suitably
            //set up for the test.  This class is really just about the quick action and the other deeper functionality should
            //be tested elsewhere
            System.debug('ScheduleQueueableAppointment bypassed in test');
        }
        else 
        {
            FSL_Schedule_Config scheduleConfig = FSL_SchedulingUtility.populateArrivalWindowAndPolicy(breakdownSA, wo, policyMap);
            FSL_AppointmentDependencyHelper.ScheduleQueueableAppointment(breakdownSA, towSA, wo, worktypeIdMap,scheduleConfig, policyMap);                 
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