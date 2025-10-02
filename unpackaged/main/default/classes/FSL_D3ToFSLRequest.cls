/**
 * Name : FSL_D3ToFSLRequest
 * Description : Handling the incoming calls from D3 to update the status on WorkOrder records or flag them for sync.
 * Methods :
 *   1. None : D3Request
 */

@RestResource(urlMapping='/D3Request/*')
global with sharing class FSL_D3ToFSLRequest {

    private static Map<String, FSL_API_Exception_Codes__c> APIExceptions = FSL_API_Exception_Codes__c.getAll();

    /**********
     * @Method Name:D3Request
     * @Parameters:None
     * @Return: FSL_WorkOrderResponse
     * @Description: M
       @Author: 
     ***********/
    @HttpPost
    global static FSL_D3ToFSLWorkOrderUpdateResponse Update_D3Request() {
        RestRequest req = RestContext.request;
        RestResponse response = RestContext.response;
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
        FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService = new FSL_ServiceAppointment.Factory().createService();
        FSL_CallComments.ICallCommentsService callCommentsService = new FSL_CallComments.Factory().createService();
        return processWorkOrderUpdateRequest(req, response, workOrderService, serviceAppointmentService , callCommentsService );
    }

    @TestVisible
    private static FSL_D3ToFSLWorkOrderUpdateResponse processWorkOrderUpdateRequest(RestRequest req, RestResponse response, FSL_WorkOrder.IWorkOrderService workOrderService,
                                                        FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                                                        FSL_CallComments.ICallCommentsService callCommentsService)  {
        Exception  anyCaughtException = null;
        FSL_WorkOrderUpdateRequest woUpdateRequest = null;
        Set <String> updatedWorkOrderNumbers = new Set<String>();
        response.statusCode = 200;
        try{
            String callOutType;
            Map<String, Object> results =  (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
            callOutType = (String)results.get('subType');
            system.debug('@@@@@calloutType@@@@@@'+callOutType);
            system.debug('@@@@@woUpdateRequest@@@@@'+results);
            if ( 'Cancel'.equalsIgnoreCase(callOutType) ) {
                woUpdateRequest = (FSL_WorkOrderUpdateRequest) JSON.deserialize(req.requestBody.toString(), FSL_WorkOrderUpdateRequest.class); 
                FSL_WorkOrder.UpdateRequestWrapper   updateRequestWrapper = new  FSL_WorkOrder.UpdateRequestWrapper ();
                updateRequestWrapper.externalIDs = woUpdateRequest.extractWorkOrderExternalIDsInRequest();
                updateRequestWrapper.workOrderComments = woUpdateRequest.extractComments();
                updatedWorkOrderNumbers = workOrderService.processWorkOrderCancelRequest(updateRequestWrapper, serviceAppointmentService, callCommentsService);
            }
            // else   if ('Update'.equalsIgnoreCase(woUpdateRequest.subType)) {
            else if ('Call_Details'.equalsIgnoreCase(callOutType)) {
                system.debug('@@@@@Call_Details@@@@@'+callOutType);
                FSL_WorkOrderResponse resp = FSL_LocationUpdateIntake.UpsertServiceAppointment();
                system.debug('@@@@@ After Processing@@@@@'+resp);
                FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLWorkOrderUpdateResponse.constructResponse(resp.statusCode, resp.statusDescription);
                system.debug('@@@@@@woUpdRes@@@@@@'+woUpdRes);
                return woUpdRes;
                //updatedWorkOrderNumbers = workOrderService.processWorkOrderUpdateRequest(updateRequestWrapper, serviceAppointmentService, callCommentsService);
            }
            else {
                anyCaughtException = new FSL_WorkOrder.UpdateWorkOrderException ('Invalid subType field in WorkOrder Update request');
                response.statusCode = 400;               
            }
        }
        catch (JSONException ex) {
            anyCaughtException = ex;
            response.statusCode = 400;
        }
        catch (FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException ex) {
            anyCaughtException = ex;
            response.statusCode = 404;           
        }  
        catch (FSL_WorkOrder.UpdateWorkOrderDMLException ex) {
            anyCaughtException = ex;
            response.statusCode = 500;
        }
        catch (FSL_WorkOrder.UpdateWorkOrderException ex) { 
            anyCaughtException = ex;
            response.statusCode = 500;
        }
        catch (Exception ex) {
            anyCaughtException = ex;
            response.statusCode = 500;          
        }
        return LogAndConstructResponse(req.requestBody.toString(), woUpdateRequest, updatedWorkOrderNumbers, anyCaughtException, response.statusCode);
    }

    public static FSL_D3ToFSLWorkOrderUpdateResponse LogAndConstructResponse( String requestBody, FSL_WorkOrderUpdateRequest woUpdRequest, Set<String> workOrderNumbers, Exception  anyExceptionRaised, Integer responseStatusCode) {
       
        Boolean errorCaught = ( anyExceptionRaised != null);
        String logMessage = 'Success';
        String callIds = '';
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes;
        if ( errorCaught ) {
            if ( woUpdRequest == null ) {
                woUpdRequest = new FSL_WorkOrderUpdateRequest();
            }
            String error = String.valueOf(responseStatusCode);
            logMessage = anyExceptionRaised.getMessage() + ' at ' + anyExceptionRaised.getLineNumber() + ', Details: ' + anyExceptionRaised.getStackTraceString();
            woUpdRes = FSL_D3ToFSLWorkOrderUpdateResponse.constructErrorResponse(woUpdRequest, workOrderNumbers, error, logMessage);
        }
        else {
            woUpdRes = FSL_D3ToFSLWorkOrderUpdateResponse.constructSuccessResponse(woUpdRequest, workOrderNumbers);
            callIds = String.valueOf(woUpdRequest.extractCallIDs());
        }
        FSL_ApplicationLogCreator.callInLogger(requestBody, JSON.serialize(woUpdRes), logMessage, '', errorCaught, callIds, '', 'Inbound Update/Cancel');

        return  woUpdRes;
    }

    public class FSL_WorkOrderUpdateRequest {
        //API has defined it as an array
        public String id; 
        public String requestEventType;   
        public String subType;     
        public String status;   
        public String version;
        public String createDate;
        public List<FSL_WOReq_CallEvent> callEvents;

        public Set<String> extractWorkOrderExternalIDsInRequest () {
            Set <String> extIDs = new Set<String>();
            for ( FSL_WOReq_CallEvent callEvent : callEvents ) {
                extIDs.add(callEvent.callKey);
            }
            return extIDs;
        }
    
        public Set<String> extractCallIDs () {
            Set <String> callIDs = new Set<String>();
            for ( FSL_WOReq_CallEvent callEvent : callEvents ) {
                callIDs.add(callEvent.callId);
            }
            return callIDs;
        }
    
        public Map<String, List<String>> extractComments() {
            Map<String, List<String>> commmentsForCall = new Map<String, List<String>>();
            for ( FSL_WOReq_CallEvent callEvent : callEvents ) {
                List <String> callComments = new List<String>();
                if ( callEvent.comments != null ) {
                    for ( FSL_WOReq_Comment comment : callEvent.comments) {
                        callComments.add(comment.text);
                    }
                    commmentsForCall.put(callEvent.callKey, callComments);
                } else {
                    callComments.add('A ' + subType + ' request has been received from D3');
                    commmentsForCall.put(callEvent.callKey, callComments);
                }    
            }
            return commmentsForCall;
        }
    }

    public class FSL_WOReq_CallEvent {
        public String callKey;
        public String callId;
        public List<FSL_WOReq_Comment> comments;
    }

    public class FSL_WOReq_Comment {
        public String commentDate;
        public String commentType;
        public String visibility;
        public String text;
    }

    public class FSL_WOReq_Contact { 
        public String userId;
        public String contactType;
    } 

    
}