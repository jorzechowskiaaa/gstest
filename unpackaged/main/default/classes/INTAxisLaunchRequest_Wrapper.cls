/**** Apex Class Name:    INTAxisLaunchRequest_Wrapper
* Description        :    This class is used to prepare request for launching Axis application  
* Modification Log   :
* Test Class Name    :    INTAxisLaunchAPI_Test
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Oct 07 2021             Created
*********************************************************************************/
public without sharing class INTAxisLaunchRequest_Wrapper {
    
    @AuraEnabled
    public AddRequest addRequest; 
    
    public without sharing  class AddRequest{
        @AuraEnabled
        public Requestor requestor = new Requestor();
        @AuraEnabled
        public RequestDetail requestDetail = new RequestDetail();
    }
    
    public without sharing class  Requestor{
        @AuraEnabled
        public String requestorID = '';
    }
    
    public without sharing  class RequestDetail{
        @AuraEnabled
        public String type = '';
        @AuraEnabled
        public String parm1 = '';
        @AuraEnabled
        public String parm2 = '';
        @AuraEnabled
        public String parm3 = '';
        @AuraEnabled
        public String parm4 = '';
        @AuraEnabled
        public String parm5 = '';
        @AuraEnabled
        public String parm6 = '';
        @AuraEnabled
        public String parm7 = '';
        @AuraEnabled
        public String parm8 = '';
        @AuraEnabled
        public String parm9 = '';
    }

}