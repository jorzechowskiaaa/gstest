global class FSL_D3ToFSLWorkOrderUpdateResponse {

    public FSL_WorkOrderUpdateResponse_Header header;
    public String statusCode;
    public String statusDescription; 
    public string workOrderNumber;    

    public FSL_D3ToFSLWorkOrderUpdateResponse() {}
    public FSL_D3ToFSLWorkOrderUpdateResponse (String statusCode, String statusDescription, Set<String> workOrderNumbers) {
        this.statusCode = statusCode;    
        workOrderNumber = '';
        Integer i = workOrderNumbers.size();
        for(String woNumber : workOrderNumbers){
            i--;
            workOrderNumber += woNumber;
            if(i > 0){
                workOrderNumber += ', ';
            }
        }
        this.statusDescription = statusDescription;
    }

    public static FSL_D3ToFSLWorkOrderUpdateResponse constructSuccessResponse (FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest woUpdRequest , Set<String> workOrderNumbers) {
        FSL_D3ToFSLWorkOrderUpdateResponse res = new FSL_D3ToFSLWorkOrderUpdateResponse('200', 'Workorders Updated Successfully', workOrderNumbers );
        res.poupulateHeader(woUpdRequest, 'Success');
        return res;
    }

    public static FSL_D3ToFSLWorkOrderUpdateResponse constructErrorResponse (FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest woUpdRequest , Set<String> workOrderNumbers,  String error, String description ) {
        FSL_D3ToFSLWorkOrderUpdateResponse res = new FSL_D3ToFSLWorkOrderUpdateResponse(error, description, workOrderNumbers );
        res.poupulateHeader(woUpdRequest, 'Error');
        return res;
    }

    public void poupulateHeader(FSL_D3ToFSLRequest.FSL_WorkOrderUpdateRequest woUpdRequest, String status) {
        header = new FSL_WorkOrderUpdateResponse_Header();
        header.id           = woUpdRequest.id;
        header.type         = woUpdRequest.requestEventType;
        header.subType      = woUpdRequest.subType;
        header.status       = status;
        header.version      = woUpdRequest.version;            
    }

    public class FSL_WorkOrderUpdateResponse_Header {
        public string id;
        public string type;
        public string subType;
        public string status;
        public string version;
    }

    public static FSL_D3ToFSLWorkOrderUpdateResponse constructResponse (string statusCode, string statusdesc) {
        system.debug('@@@response@@@@');
        system.debug('@@@response@@@@');
        set<string> woNumbers = new set<string>();
        FSL_D3ToFSLWorkOrderUpdateResponse woRes = new FSL_D3ToFSLWorkOrderUpdateResponse(statusCode, statusdesc,woNumbers);
        system.debug('@@@woRes@@@@'+woRes);
        woRes.poupulateHeader();
        return woRes;
    }
    public void poupulateHeader() {
        header = new FSL_WorkOrderUpdateResponse_Header();
        header.type         = 'update';
        header.subType      = 'call_details';          
    }
}