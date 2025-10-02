/**** Apex Class Name    :    INTAxisLaunchAPI
    * Description        :    This class is used to launch Axis application   
    * Modification Log   :
    * Test Class Name    :    INTAxisLaunchAPI_Test
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla           Oct 07 2021             Created
*********************************************************************************/
public without sharing class INTAxisLaunchAPI {
    
   
    /*
   * Method name    : axisLaunch
   * Description    : Used to launch AXIS desktop application from button on Opportunity and trip record page.
   * Return Type    : INTAxisLaunchResponse_Wrapper
   */
    
    @AuraEnabled()
    public static INTAxisLaunchResponse_Wrapper axisLaunch(String pId,String methodType,
                                                      String proxyUI,String axisTripNumber,String opportunityId, String guId,String axisType,String navigationScreen){    
        
         // Get Configuration
        Map<String,Integration_Settings__c> mapIntSettings = 
                                                             IntegrationUtil.getIntegrationSettings();                                                  
		INTAxisLaunchResponse_Wrapper objWrapper=new INTAxisLaunchResponse_Wrapper();
        HttpRequest request=new HttpRequest();
        Httpresponse response=new Httpresponse();
        
        try{
            
            INTAxisLaunchRequest_Wrapper req = new INTAxisLaunchRequest_Wrapper();
            INTAxisLaunchRequest_Wrapper.AddRequest addReq = new INTAxisLaunchRequest_Wrapper.AddRequest();
            INTAxisLaunchRequest_Wrapper.Requestor requestor = new INTAxisLaunchRequest_Wrapper.Requestor();
            INTAxisLaunchRequest_Wrapper.RequestDetail requestDetail = new INTAxisLaunchRequest_Wrapper.RequestDetail();
            requestor.requestorID = pId;
            addReq.requestor = requestor;
            requestDetail.type = axisType;
            requestDetail.parm1 = navigationScreen;
            requestDetail.parm2 = methodType;
            requestDetail.parm3 = proxyUI;
            requestDetail.parm4 = axisTripNumber;
            requestDetail.parm7 = guId;
            if(opportunityId != '' && opportunityId != null){
            	requestDetail.parm6 = opportunityId; 
            }
            else{
            	requestDetail.parm6 = ACG_ConstantsClass.SALESFORCE; 
            }
            addReq.requestDetail = requestDetail;
            req.addRequest = addReq;
            Integration_Settings__c objSetting=mapIntSettings.get(ACG_ConstantsClass.POST_AXIS_LAUNCH_API);
            request = IntegrationUtil.preparerequest(objSetting,req,false);
            request.setHeader(ACG_ConstantsClass.TRAN_ID,IntegrationUtil.generateuniqueId());
            response = IntegrationUtil.makecallout(request);
            
            if(response.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS) {
                
                objWrapper = INTAxisLaunchResponse_Wrapper.parse(response.getBody());
                objWrapper.statusCode = response.getStatusCode();
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.AXISLAUNCHAPI,ACG_ConstantsClass.AXISLAUNCH,false,response.getStatus(),null);
            }
            else{
                
                objWrapper = INTAxisLaunchResponse_Wrapper.parse(response.getBody());
                Map<String, Object> res = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); 
                objWrapper.statusCode = response.getStatusCode();
                 objWrapper.errorMessage = res.containsKey(ACG_ConstantsClass.RESPONSE_HEADERS) ? String.ValueOf(((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(res.get(ACG_ConstantsClass.RESPONSE_HEADERS)))).get(ACG_ConstantsClass.TRAN_STATUS_DESCRIPTION)) : String.ValueOf(res.get(ACG_ConstantsClass.ERROR));
                FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                          ACG_ConstantsClass.AXISLAUNCHAPI,ACG_ConstantsClass.AXISLAUNCH,true,Label.ACG_APIErrorMessage +' : '+response.getStatusCode()+' '+response.getStatus(),null);
            }
        }catch(Exception e){
            
            String message = e.getStackTraceString();
            objWrapper.statusCode = ACG_ConstantsClass.ERROR_CODE500;
            objWrapper.errorMessage = message;
            FSL_ApplicationLogCreator.integrationLog (request.getBody(),response.getBody(),
                                                      ACG_ConstantsClass.AXISLAUNCHAPI,ACG_ConstantsClass.AXISLAUNCH,true,message,null);    
        }                                                     
        return objWrapper;    
    }
}