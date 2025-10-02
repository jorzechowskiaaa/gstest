/**** 
* Apex Class Name    :    INTNationalRBPAPIResponse_Wrapper
* Description        :    This class is used to prepare response for ERS Medallia api call   
* Modification Log   :
* Test Class Name    :    
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Dhruv Javiya             OCT 29 2021             Initial version
*********************************************************************************/
public class INTNationalRBPAPIResponse_Wrapper {    
    public Integer STATUS_CODE {get;set;}
    public String ERR_MESSAGE {get;set;}
    public String RETRY_COUNT {get;set;}
    public String ERR_STATUS {get;set;}
    public ResponseHeaders responseHeaders {get;set;}
    
    public class ResponseHeaders {
        public String tranId {get;set;}
        public String tranCode {get;set;}
        public String tranStatus {get;set;}
        public String timeStamp {get;set;}
        public String tranStatusDescription {get;set;}
    }

    public static INTNationalRBPAPIResponse_Wrapper parse(String jsonResp) {
        INTNationalRBPAPIResponse_Wrapper resp = new INTNationalRBPAPIResponse_Wrapper();

        try {
            resp = (INTNationalRBPAPIResponse_Wrapper) System.JSON.deserialize(jsonResp, INTNationalRBPAPIResponse_Wrapper.class);
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString() + '\n\n' + 'JSON RESPONSE:\n' + jsonResp;
            
            System.debug(JSON.serializePretty(new Map<String, Object>{
                'operation' => 'INTNationalRBPAPIResponse_Wrapper',
                'error' => errMsg
            }));
        }

        return resp;
    }
}