/**
 * @File Name          : FSL_GlympseMileageToFSL.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/11/2020, 10:25:11 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/4/2020   Rajesh Kemisetti     Initial Version
**/
@RestResource(urlMapping='/Glympse/Mileage/*')


    global without sharing class FSL_GlympseMileageToFSL{
    
    public Static String errorMessage = '';

    @HttpPost
    global static FSL_WorkOrderResponse updateMileage(){
        RestRequest request = RestContext.request;
        FSL_WorkOrderResponse response = new FSL_WorkOrderResponse();
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        String serviceApptId;
        Integer taskId;

        try{
        	System.debug('requestBody====>'+request.requestBody.toString());
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
            Object distanceByPhase = m.get('distance_travelled_by_phase');
            taskId = Integer.valueOf(m.get('task_id'));
            Map<String, Object> distanceByPhaseMap = (Map<String, Object>) distanceByPhase;
            system.debug('taskId' +taskId);
            system.debug('distanceByPhaseMap:'+distanceByPhaseMap);
			
            //Sort in Asc order
            List<string> glympseEvents = new list<string>();
            glympseEvents.addAll(distanceByPhaseMap.keySet());
            glympseEvents.sort();

            //Sort in desc order
            List<String> finalList = new List<String>();
            for(Integer i = glympseEvents.size()-1; i>=0; i--)
            {
                finalList.add(glympseEvents.get(i));
            }
            Decimal actMilesDriven = 0 ;
            for(string key : finalList){
                //pick the first live instance sorted in desc order which contains the distance travelled 
                if(key.containsIgnoreCase('live')){
                	system.debug(key+' value: '+distanceByPhaseMap.get(key));
                    actMilesDriven = (Decimal)distanceByPhaseMap.get(key)/1609;
                    break;
                }
            }

            FSL_ServiceAppointment.IFactory serviceAppointmentFactory = new FSL_ServiceAppointment.Factory();
            FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService = serviceAppointmentFactory.createService();
            FSL_ClearQueuedCall.IFactory clearQueuedCallFactory = new FSL_ClearQueuedCall.Factory();
            ServiceAppointment updatedServiceAppointment = serviceAppointmentService.updateActualMilesDriven( taskId, actMilesDriven, clearQueuedCallFactory.createService() );
            
            if( updatedServiceAppointment == null ) {
                response.statusCode = '201';
                response.statusDescription = 'Task '+ taskId +' not found';
            }
            else {
                response.statusCode = '200';
                response.statusDescription = 'SUCCESS';
                serviceApptId = updatedServiceAppointment.Id;
            }
        }
        catch(Exception e){
           system.debug(e.getStackTraceString());
           response.statusCode = '400';
           response.statusDescription = e.getTypeName()+' '+e.getMessage();
           errorMessage = e.getStackTraceString() +' At Line: '+e.getLineNumber();
           String nullTaskId =  taskId == null?'NoTaskId':String.valueOf(taskId);
           FSL_ApplicationLogCreator.callInGlympseLogger(request.requestBody.toString(), Label.FSL_API_BadInput, errorMessage, true, '', nullTaskId,'GlympseMileage', serviceApptId);
           return response;
        }
        return response;
    }
}