/**
 * @File Name          : FSL_MilestoneTimeCalculator.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 3/5/2020, 10:22:31 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    1/23/2020   Rajesh Kemisetti     Initial Version
**/
//class implements Support.MilestoneTriggerTimeCalculator to provide milestone violation time based on time trigger

public without sharing class FSL_MilestoneTimeCalculator implements Support.MilestoneTriggerTimeCalculator {
    
    
    //  ***    Service Tech Team: This class is retired    ***


    public Integer calculateMilestoneTriggerTime(String woId, String milestoneTypeId) {
        
    //     system.debug('Milestone Trigger for workorder: '+woId+' with milestone: '+milestoneTypeId);
    //     milestoneTypeId = get18CharId(milestoneTypeId);
    //     Integer minTrigger = 0;
    //     FSL_Milestone_Time_Trigger__c mt = FSL_Milestone_Time_Trigger__c.getInstance(milestoneTypeId);

    //     if(mt!=null){
    //         WorkOrder wo = [SELECT Id, Status, Enroute_Timestamp__c, In_Tow_Timestamp__c, WorkTypeId, 
    //                                On_Location_Timestamp__c, PTA__c,
    //                                worktype.name, worktype.EstimatedDuration, worktype.DurationType,
    //                             (SELECT Id, SchedStartTime, SchedEndTime, ParentRecordId, RecordType.Name 
    //                                 FROM ServiceAppointments)
    //                         FROM WorkOrder 
    //                         WHERE Id = : woId];            
            
    //         if(wo.Status == 'Spotted' && mt.Time_Trigger_Minutes__c!=null){
    //             minTrigger =  Integer.valueOf(mt.Time_Trigger_Minutes__c);
    //         }else if(wo.Status == 'Scheduled' && mt.Time_Trigger_Minutes__c!=null) {
    //             minTrigger =  Integer.valueOf(mt.Time_Trigger_Minutes__c);
    //         }else if(wo.Status == 'Dispatched' && mt.Time_Trigger_Minutes__c!=null) {
    //             minTrigger =  Integer.valueOf(mt.Time_Trigger_Minutes__c);
    //         }else if(wo.Status == 'En Route'){
    //             ServiceAppointment sa = getBreakdownDetails(wo);
    //             minTrigger = ((sa.SchedStartTime.addMinutes(Integer.valueOf(mt.Time_Trigger_Minutes__c)).getTime() - System.now().getTime())/60000).intValue();
    //         }else if(wo.Status == 'In Tow' && mt.Time_Trigger_Minutes__c!=null) {
    //             ServiceAppointment sa = getTowDetails(wo);
    //             if(sa.SchedStartTime!=null)
    //                 minTrigger = (( sa.SchedStartTime.addMinutes(Integer.valueOf(mt.Time_Trigger_Minutes__c)).getTime() - System.now().getTime())/60000).intValue();
    //         }else if(wo.Status == 'On Location' || wo.Status == 'Tow Complete') {
    //             Integer durationInMins;
    //             Decimal multiplier = 1;
    //             if(mt.WORKTYPE_DURATION__C!=null){
    //                 multiplier = mt.WORKTYPE_DURATION__C;
    //             }
                
    //             if(wo.worktype.DurationType == 'Hours') {
    //                 durationInMins = Integer.valueOf(Integer.valueOf(wo.worktype.EstimatedDuration)* 60 * multiplier);
    //             } else {
    //                 durationInMins = Integer.valueOf(Integer.valueOf(wo.worktype.EstimatedDuration) * multiplier);
    //             }
                
    //             minTrigger = ((System.now().addMinutes(durationInMins).getTime() - System.now().getTime())/60000).intValue();
    //         }
    //     }else{
    //         system.debug('FSL_Milestone_Time_Trigger__c config is not setup or not required for this milestone:'+milestoneTypeId);
    //     }
        
    //     if(minTrigger <= 0) {
    //         minTrigger = 1;
    //     }              
    //     return minTrigger;
        return 0;
    }
    
    // /**
    // * @description 
    // * @author Rajesh Kemisetti | 1/23/2020 
    // * @param wo 
    // * @return ServiceAppointment 
    // **/
    // private static ServiceAppointment getBreakdownDetails(WorkOrder wo){
    //     ServiceAppointment brkDownAppt;
    //     List<ServiceAppointment> saList = wo.ServiceAppointments;
    //     for(ServiceAppointment sa : wo.ServiceAppointments){
    //         if(sa.RecordType.Name == 'Breakdown'){
    //             brkDownAppt = sa; 
    //         }
    //     }
    //     return brkDownAppt;
    // }

    // /**
    // * @description 
    // * @author Rajesh Kemisetti | 1/23/2020 
    // * @param wo 
    // * @return ServiceAppointment 
    // **/
    // private static ServiceAppointment getTowDetails(WorkOrder wo){
    //     ServiceAppointment towAppt;
    //     List<ServiceAppointment> saList = wo.ServiceAppointments;
    //     for(ServiceAppointment sa : wo.ServiceAppointments){
    //         if(sa.RecordType.Name == 'Tow'){
    //             towAppt = sa; 
    //         }
    //     }
    //     return towAppt;
    // } 

    // /**
    // * @description 
    // * @author Rajesh Kemisetti | 3/5/2020 
    // * @param idSalesforce 
    // * @return string 
    // **/
    // private static string get18CharId(string idSalesforce){
    //     string milestoneId = idSalesforce;
    //     if(idSalesforce.length() == 15){
    //         String suffix = '';
    //         String idOut= '';
    //         String InChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
    //         for(Integer i = 0; i<3; i++){
    //             Integer flags = 0;
    //             for(Integer j = 0; j<5; j++){
    //                 String c = idSalesforce.substring(i*5+j, i*5+j+1);
    //                 if((c.compareTo('A')>=0) && (c.compareTo('Z')<=0)){
    //                     flags += 1 << j;
    //                 }
    //             }
    //             suffix = suffix + InChars.substring(flags, flags+1);
    //         }
    //         milestoneId = idSalesforce + suffix;
    //         system.debug('Id Output 15: '+idSalesforce);
    //         system.debug('Id Output 18: '+milestoneId);
    //     }
    //     return milestoneId;        
    // }    
}