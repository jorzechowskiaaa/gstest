global with sharing class FSL_UpdateArrivalWindowAction implements FSL.CustomGanttServiceAppointmentAction {
    public static final String BRKDOWN = 'Breakdown';
    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        try{
            String reply = '';
            List<String> appointmentNumbers = new List<String>();
            List<ServiceAppointment> saList = [SELECT Id, AppointmentNumber, RecordType.Name, Work_Order__r.RecordType.Name, Work_Order__r.Priority, Work_Order__r.WorkType.FSL__Due_Date_Offset__c, ArrivalWindowStartTime, ArrivalWindowEndTime, DueDate, ServiceTerritory.Name, ServiceTerritory.ParentTerritory.Name FROM ServiceAppointment WHERE id in :serviceAppointmentsIds OR FSL__Related_Service__c in :serviceAppointmentsIds];
            //Map<String, FSL_SLA_Arrival_Window__c> ArrivalWindowMap = FSL_SLA_Arrival_Window__c.getAll();
           
            Map<Id, FSL_SLA_ArrivalWindow__c> arrivalWindowMap = new Map<Id,FSL_SLA_ArrivalWindow__c>([Select Id,Name,LS_SLA__c,Retry_Policy__c,Scheduling_Policy__c,First_Retry_Policy__c,Scheduling_Policy__r.Name,Service_Territory__r.Name,Service_Territory__c,Tow_SLA__c,Priority__c from FSL_SLA_ArrivalWindow__c]);//FSL_SLA_Arrival_Window__c.getAll();
            Map<Id, ServiceTerritory> stMap = new Map<Id, ServiceTerritory>([SELECT Id, Name, ParentTerritoryId FROM ServiceTerritory]);
        
            for(ServiceAppointment sa : saList){
                if(sa.RecordType.Name == BRKDOWN){
                    //update arrival window to current time + sla for Breakdown appointments
                    sa.ArrivalWindowEndTime = System.now().addMinutes(getSLA(sa, arrivalWindowMap, stMap));
                    system.debug(sa.AppointmentNumber + ' Arrival Window Updated to ' + sa.ArrivalWindowEndtime);
                }
                //update due date to current time + due date offset for Breakdown & Tows
                sa.DueDate = system.now().addMinutes(Integer.valueOf(sa.Work_Order__r.WorkType.FSL__Due_Date_Offset__c));
                appointmentnumbers.add(sa.AppointmentNumber);
                system.debug(sa.AppointmentNumber + ' Due Date Updated to ' + sa.DueDate);
            }
            

            upsert saList;
            appointmentNumbers.sort();
            reply = String.join(appointmentNumbers, ', ');
            return 'The following Service Appointments have been updated with a new Arrival Window & Due Date: ' + reply;
        } catch(Exception e){
            system.debug('Exception Caught: ' + e);
            return 'Error processing request: ' + e;
        }
    }

    public integer getSLA(ServiceAppointment sa, Map<Id, FSL_SLA_ArrivalWindow__c> arrivalWindowMap, Map<Id, ServiceTerritory> stmap){

        WorkOrder wo = new WorkOrder();

        wo.Priority = sa.Work_Order__r.Priority;
        wo.is_Tow_WorkType__c  =   (sa.RecordType.Name == 'BRKDOWN') ? false : true;

        FSL_Schedule_Config schedConfig = FSL_SchedulingUtility.extractMatchingScheduleConfig(sa, wo, stMap, arrivalWindowMap);
        if ( schedConfig != null) {
            return schedConfig.slaValue;
        }
        else {
            return 0;
        }

    }
    

}