/**
 * Name : FSL_GlympseToFSLRequest
 * Description : Webhook/endpoint for journey status transitions
 * Methods :
 *   1. FSL_WorkOrderResponse : updateStatus
 */
 
@RestResource(urlMapping='/GlympseStatus/*')


    global without sharing class FSL_GlympseToFSLRequest{
    
    private static Map<String, FSL_API_Exception_Codes__c> apiExceptions = FSL_API_Exception_Codes__c.getAll();
    public Static String errorMessage = '';

    /*
    * Taskid and phase_name values in Event object*/
    @HttpPost
    global static FSL_WorkOrderResponse updateStatus(){
       
        
        FSL_WorkOrderResponse res = new FSL_WorkOrderResponse();
        //ERS-230874 Glympse Removal - Part I
        /* -----------------------------------------------------------------------------------------------------------------------------
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        List<WorkOrder> workOrders = new List<WorkOrder>();
        Set<Id> workOrderIds = new Set<Id>();
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        List<Glympse_EnRoute__Glympse_EnRoute_Phase__c> glympseStatus = new List<Glympse_EnRoute__Glympse_EnRoute_Phase__c>();
        String phase;
        Integer taskId;
        String serviceApptId;
        try{
        System.debug('requestBody====>'+request.requestBody.toString());
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
            Object operationsObject = m.get('operations');
            Map<String, Object> operationsMap = (Map<String, Object>) operationsObject;
            phase  = String.valueOf(operationsMap.get('phase'));
            taskId = Integer.valueOf(operationsMap.get('task_id'));
            List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
            system.debug('LivePhase' +phase);
            if(phase == 'arrived') {
                glympseStatus = [Select Id, Glympse_EnRoute__Status__c, Glympse_EnRoute__Phase__c FROM Glympse_EnRoute__Glympse_EnRoute_Phase__c
                                WHERE Glympse_EnRoute__Phase__c = : phase AND Name = 'On Location'];
    
                Id breadkdownRecordTypeId = Schema.Sobjecttype.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
    
                serviceAppointments = [Select Id,ParentRecordId, AppointmentNumber, Status FROM ServiceAppointment WHERE
                                        Glympse_EnRoute__Glympse_EnRoute_Task_ID__c =: taskId AND RecordTypeId =:breadkdownRecordTypeId];
                
                    for(ServiceAppointment sa: serviceAppointments) {
                        for (Glympse_EnRoute__Glympse_EnRoute_Phase__c glympse: glympseStatus) {
                            if(sa.Status == 'En Route'){
	                            sa.Status = glympse.Glympse_EnRoute__Status__c;
	                            sa.Auto_On_Location__c = true;
	                            saUpdateList.add(sa);
                            }
                        }
                    }
              
                if(!serviceAppointments.isEmpty()){
                    if(!saUpdateList.isEmpty()) {
                        update saUpdateList;
                        serviceApptId = saUpdateList[0].id;
                        res.statusCode = '200';
                        response.statusCode = 200;
                        res.statusDescription = 'ServiceAppointment '+ saUpdateList[0].AppointmentNumber +' status updated to '+saUpdateList[0].status;                        
                    }
                }
                else{
                    res.statusCode = '200';
                    response.statusCode = 200;
                    res.statusDescription = 'Task # '+taskId +' is not related to a breakdown appointment';                    
                }
                if (System.Test.isRunningTest()) {
                    throw new JSONException('GoInsideCatchBlock');
                }
            }
            if(phase == 'live') {
                Id breadkdownRecordTypeId = Schema.Sobjecttype.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
    
                serviceAppointments = [Select Id, Dispatched_Timestamp__c, LastModifiedDate, LastModifiedBy.Name, ParentRecordId, Scheduled_Timestamp__c, ServiceTerritory.Facility_Number__c, Spotted_Timestamp__c, Status, (SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.Driver_Id__c, ServiceResource.LocationId, ServiceAppointment.SchedStartTime,ServiceResource.Location.VIN__c, ServiceResource.Vehicle__r.Truck_Id__c FROM ServiceResources ) FROM ServiceAppointment WHERE
                                        Glympse_EnRoute__Glympse_EnRoute_Task_ID__c =: taskId AND RecordTypeId =:breadkdownRecordTypeId];
                
                if(!serviceAppointments.isEmpty()){
                    serviceApptId = serviceAppointments[0].id;
                    for (ServiceAppointment serviceAppointment : serviceAppointments) {
                        workOrderIds.add(serviceAppointment.ParentRecordId);
                    }
                    AssignedResource ar = null;
                    if(!serviceAppointments[0].ServiceResources.isEmpty()) {
                        ar = serviceAppointments[0].ServiceResources[0];
                    }
                    System.debug('GlympseRequest::workOrderIds::\n'+workOrderIds.size());
                    workOrders = [Select Id,WorkOrderNumber,Status,Call_Id__c,External_Id__c,Call_Date__c FROM WorkOrder WHERE Id IN: workOrderIds];
                    String servicingFacility = serviceAppointments[0].ServiceTerritory.Facility_Number__c;
                    FSL_ToD3Update.CalloutWrapperD3 wrapper = FSL_ToD3Update.wrapperBuilder(workOrders[0], serviceAppointments[0], ar, servicingFacility);
                    FSL_ToGlympseCallout.getEta(String.valueOf(serviceAppointments[0].id), JSON.serializePretty(wrapper), workOrders[0].Call_Id__c);
                }
            }
            
        }
        catch(Exception e){
           system.debug(e.getStackTraceString());
           res.statusCode = '400';
           response.statusCode = 400;
           res.statusDescription = e.getTypeName()+' '+e.getMessage();
           errorMessage = e.getStackTraceString() +' At Line:'+e.getLineNumber();
           String nullTaskId =  taskId == null?'NoTaskId':String.valueOf(taskId);
           FSL_ApplicationLogCreator.callInGlympseLogger(request.requestBody.toString(), Label.FSL_API_BadInput, errorMessage, true, nullTaskId, '','GlympseStatus', null);
           return res;
        }
        ------------------------------------------------------------------------------------------------------*/
        return res;
    }
}