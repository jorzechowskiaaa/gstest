public with sharing class FSL_UpdateSAController {
    public ServiceAppointment saUpdate{get;set;}
    public FSL_UpdateSAController() {
        ID saId = ApexPages.currentPage().getParameters().get('id');
        saUpdate = [Select Id,Extend_Work_Time_Counter__c,Schedule_Delta__c from ServiceAppointment where Id =: saId];
        //saUpdate.Id = saId;
    }

    public PageReference updateServiceAppointment() {
        if(saUpdate.Schedule_Delta__c != null && saUpdate.Schedule_Delta__c != 0) {
            if(saUpdate.Extend_Work_Time_Counter__c == null){
                saUpdate.Extend_Work_Time_Counter__c = 0;
            }
            saUpdate.Extend_Work_Time_Counter__c = saUpdate.Extend_Work_Time_Counter__c+1;
        }
        update saUpdate;
        return null;
    }
}