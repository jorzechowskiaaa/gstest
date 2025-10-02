/**** Apex Class Name:    INTAxisLaunchResponse_Wrapper
* Description        :    This class is used to prepare response for launching an AXIS   
* Modification Log   :
* Test Class Name    :    INTAxisLaunchAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Oct 07 2021             Created
*********************************************************************************/
public without sharing class INTAxisLaunchResponse_Wrapper {
    
	@AuraEnabled
    public Integer statusCode;
    
    @AuraEnabled
    public String errorMessage;
    
    @AuraEnabled
    public ResponseHeaders responseHeaders;
    
    public without sharing class ResponseHeaders{
        
        @AuraEnabled
        public String tranId;
        
        @AuraEnabled
        public String tranCode;
        
        @AuraEnabled
        public String tranStatus;
        
        @AuraEnabled
        public String timeStamp;
        
        @AuraEnabled
        public String tranStatusDescription;
    }
    
    public static INTAxisLaunchResponse_Wrapper parse(String json) {
		return (INTAxisLaunchResponse_Wrapper) System.JSON.deserialize(json, INTAxisLaunchResponse_Wrapper.class);
	}
}