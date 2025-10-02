global class RestResponse_PatchCall {
    public ResponseHeader header;
    public RestApi_PatchCall.ERSCallInfo callInfo;

    public class ResponseHeader {
        public Integer statusCode;
        public string status;
        public List<ErrorInfo> errors;

    }

    public class ErrorInfo {
        public Integer error;
        public String message;

        public ErrorInfo(Integer err, String msg) {
            error = err;
            message = msg;
        }
    }

    public RestResponse_PatchCall(Integer code, String msg) {
        header = new ResponseHeader();
        header.statusCode = code;
        header.status = msg;
        header.errors = new List<ErrorInfo>();
        callInfo = new RestApi_PatchCall.ERSCallInfo();
    }
    public static RestResponse_PatchCall constructSuccessResponse(String msg, String status) {
        RestResponse_PatchCall res = new RestResponse_PatchCall(200, msg);
        res.callInfo.status = status;
        return res;
    }

    public static RestResponse_PatchCall constructErrorResponse(Integer errorCode, String errorMessage) {
        RestResponse_PatchCall res = new RestResponse_PatchCall(errorCode, 'Update Operation Failed');
        res.header.errors.add(new ErrorInfo(errorCode, errorMessage));
        return res;
    }
}