@isTest
public class FSL_D3ToFSLRequestTest {

    private FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
    private FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService = new FSL_ServiceAppointmentTest.FactoryMock().createService();
    private FSL_CallComments.ICalLCommentsService callCommentsService = new FSL_CallCommentsTest.FactoryMock().createService();

    // Including some unit tests for the FSL_D3ToFSLWorkOrderUpdateResponse class here
    @IsTest
    public static void testD3ToFSLWorkOrderUpdateResponse_constructSuccessResponse_SuccessResponseConstructed() {

        FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest woUpdReq = constructRawWorkOrderUpdateRequest('Cancel', '123-456-789');
        Set<String> workOrderNumbers = new Set<String>();
        workOrderNumbers.add('456789');

        System.test.startTest();
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLWorkOrderUpdateResponse.constructSuccessResponse(woUpdReq, workOrderNumbers);
        System.test.stopTest();
        System.assertEquals('200', woUpdRes.statusCode);
        System.assertEquals('456789', woUpdRes.workOrderNumber);
        System.assertEquals('Cancel', woUpdRes.header.subType);
        System.assertEquals(woUpdReq.id, woUpdRes.header.id);
        
    }

     // Including some unit tests for the FSL_D3ToFSLWorkOrderUpdateResponse class here
     @IsTest
     public static void testD3ToFSLWorkOrderUpdateResponse_constructErrorResponse_ErrorResponseConstructed() {
         FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest woUpdReq = constructRawWorkOrderUpdateRequest('Cancel', '123-456-789');
         Set<String> workOrderNumbers = new Set<String>();
         workOrderNumbers.add('456789');
         System.test.startTest();
         FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLWorkOrderUpdateResponse.constructErrorResponse(woUpdReq, workOrderNumbers, '400', 'subType field is missing in the request');
         System.assertEquals('400', woUpdRes.statusCode);
         System.test.stopTest();
         System.assertEquals('456789', woUpdRes.workOrderNumber);
         System.assertEquals('subType field is missing in the request', woUpdRes.statusDescription);
         System.assertEquals('Cancel', woUpdRes.header.subType);
         System.assertEquals(woUpdReq.id, woUpdRes.header.id);
     }


    @IsTest
    public static void testD3ToFSLRequest_CancelRequest_InvalidRequest_ExceptionRaised() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        String body = '{"UpdateRequest": "Missing", "subType" : "CANCEL"}';
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        System.test.startTest();
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes =  FSL_D3ToFSLRequest.Update_D3Request();  
        System.test.stopTest();
        System.assertEquals('500', woUpdRes.statusCode);  
    }

    @IsTest
    public static void testD3ToFSLRequest_CancelRequest_NoMatchingCalls_ErrorResponse() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';

        StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'FSL_D3ToFSLRequest_Cancel'];
        string body = WorkOrder_Cancel_Request.body.toString();       
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock( );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        workOrderService.throwsException = true;
        workOrderService.exceptiontothrow = new FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException('Test  NoMatchingWorkOrdersToUpdateException Exception');

        System.test.startTest();
        workOrderService.throwsException = true;
        workOrderService.exceptiontothrow = new FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException('Test  NoMatchingWorkOrdersToUpdateException Exception');
     
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLRequest.processWorkOrderUpdateRequest(req, res, workOrderService, serviceAppointmentServiceMock, calLCommentsServiceMock);

        System.assertEquals('404', woUpdRes.statusCode, woUpdRes.statusDescription);
    }

     @IsTest
    public static void testD3ToFSLRequest_CancelRequest_ValidRequest_SuccessResponse() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';

        StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'FSL_D3ToFSLRequest_Cancel'];
        string body = WorkOrder_Cancel_Request.body.toString();       
        req.requestBody = Blob.valueof(body);

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock( );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        workOrderService.processWorkOrderCancelRequestReturnValue = new Set<String> { '3001234'};
        
        RestContext.request = req;
        RestContext.response= res;

        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLRequest.processWorkOrderUpdateRequest(req, res, workOrderService, serviceAppointmentServiceMock, calLCommentsServiceMock);
        System.assertEquals(1, workOrderService.processWorkOrderCancelRequestCallCount);
        System.assert(workOrderService.processWorkOrderCancelRequestReturnValue.contains(woUpdRes.workOrderNumber));
    }

    @IsTest
    public static void testD3ToFSLRequest_UpdateRequest_ValidRequest_SuccessResponse() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';

        StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'JSON_testD3ToFSLRequest'];
        //StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'FSL_D3ToFSLRequest_Update'];
        
               
        string body = WorkOrder_Cancel_Request.body.toString();       
        req.requestBody = Blob.valueof(body);

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock( );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        workOrderService.processWorkOrderUpdateRequestReturnValue = new Set<String> { '3001234'};
        
        RestContext.request = req;
        RestContext.response= res;

        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLRequest.processWorkOrderUpdateRequest(req, res, workOrderService, serviceAppointmentServiceMock, calLCommentsServiceMock);
        system.debug('@@@woUpdRes 144@@@' + woUpdRes);
    }

    
    @IsTest
    public static void testD3ToFSLRequest_UpdateRequest_InValidSubType_ExceptionThrown() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';

        StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'FSL_D3ToFSLRequest_Cancel'];
        string body = WorkOrder_Cancel_Request.body.toString().replace('CANCEL', 'Invalid') ;
        req.requestBody = Blob.valueof(body);

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock( );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();
        
        RestContext.request = req;
        RestContext.response= res;
       
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLRequest.processWorkOrderUpdateRequest(req, res, workOrderService, serviceAppointmentServiceMock, calLCommentsServiceMock);
        System.assertEquals('400', woUpdRes.statusCode);
    }

    @IsTest
    public static void testD3ToFSLRequest_CancelRequest_UpdateWorkOrderDMLException_ErrorResponse() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/D3Request/';
        req.httpMethod = 'POST';

        StaticResource WorkOrder_Cancel_Request = [select id, body from StaticResource where name = 'FSL_D3ToFSLRequest_Cancel'];
        string body = WorkOrder_Cancel_Request.body.toString();       
        req.requestBody = Blob.valueof(body);

        RestContext.request = req;
        RestContext.response= res;

        FSL_WorkOrderTest.WorkOrderServiceMock workOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock( );
        FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock serviceAppointmentServiceMock = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        FSL_CallCommentsTest.CalLCommentsServiceMock calLCommentsServiceMock = new FSL_CallCommentsTest.CalLCommentsServiceMock();

        workOrderService.throwsException = true;
        workOrderService.exceptiontothrow = new FSL_WorkOrder.UpdateWorkOrderDMLException('Test  UpdateWorkOrderDMLException Exception');

        System.test.startTest();
        FSL_D3ToFSLWorkOrderUpdateResponse woUpdRes = FSL_D3ToFSLRequest.processWorkOrderUpdateRequest(req, res, workOrderService, serviceAppointmentServiceMock, callCommentsServiceMock);
        System.test.stopTest();

        System.assertEquals('500', woUpdRes.statusCode);
    }  

    private static FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest  constructRawWorkOrderUpdateRequest(String subType, String extId) {

        FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest  woUpdRequest = new  FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest();

        woUpdRequest.id = '12345';
        woUpdRequest.subType = subType;
        woUpdRequest.version = '1.0';

        FSL_D3ToFSLRequest.FSL_WOReq_CallEvent callEvent = new FSL_D3ToFSLRequest.FSL_WOReq_CallEvent();
        woUpdRequest.callEvents = new List<FSL_D3ToFSLRequest.FSL_WOReq_CallEvent>();
        woUpdRequest.callEvents.add(callEvent);

        callEvent.callId = '123456';
        callEvent.callKey = extId;

        FSL_D3ToFSLRequest.FSL_WOReq_Comment callComment = new FSL_D3ToFSLRequest.FSL_WOReq_Comment();
        callEvent.comments = new List<FSL_D3ToFSLRequest.FSL_WOReq_Comment>();
        callEvent.comments.add(callComment);

        callComment.text = 'This is the comment from a WorkOrder ' + subType + ' request';

        return woUpdRequest;
    }

}