global class FSL_WorkOrderResponse {
    public HEADER header;
    public String statusCode;
    public String statusDescription; 
    public String callKey;
	public string workOrderNumber;    
    
    public class HEADER{
        public string id;
        public string type;
        public string subType;
        public string status;
        public string version;

        public HEADER() {}
        public HEADER(Map<String, String> headers) {
            /*
            this.id      = headers.get('id');
            this.type    = headers.get('type');
            this.subType = headers.get('subType');
            this.status  = headers.get('status');
            this.version = headers.get('version');
            */

            this.id      = '';
            this.type    = '';
            this.subType = '';
            this.status  = '';
            this.version = '';
        }
    }
}