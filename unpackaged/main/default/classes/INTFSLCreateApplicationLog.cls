/**** Apex Class Name    :    INTFSLCreateApplicationLog
    * Description        :    API class  to for D3 CallBack to send data back to SFDC 
*********************************************************************************/
@RestResource(urlMapping='/createApplicationLog/*')
global without sharing class INTFSLCreateApplicationLog {

    @HttpPost
    global static Response createApplicationLog() {
        System.debug('------------- TIMESTAMP -----W : ' + Datetime.now());
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        Response rsp = new Response();
        System.debug('------------- json : ' + request.requestBody.toString());
        try{
        if(request.requestBody != null){
            String json = request.requestBody.toString();
          
            ApplicationLogRequest obj = (ApplicationLogRequest) System.JSON.deserialize(json, ApplicationLogRequest.class);
            system.debug('******* Application Log' + obj);
            //String request, String response, String apiName,String operation,Boolean isError,String message,String woId
            FSL_ApplicationLogCreator.integrationLog(json, obj.statusDescription + obj.D3CallKey + obj.statusCode,'INTFSLCreateApplicationLog','Clear Call D3 Sync Success',false, obj.statusDescription, null);
            rsp.message = 'Success';
            return rsp;
        }
        }catch(Exception e){
            String ERROR_MESSAGE = 'Failed to store the response from D3 CallBack' + e.getMessage();
            FSL_ApplicationLogCreator.integrationLog(request.requestBody.toString(),JSON.serialize(request),'INTFSLCreateApplicationLog','Clear Call D3 Sync Error',true,ERROR_MESSAGE,null);
        	rsp.message = 'Failure';
            return rsp;
        }
        return null;
    }
    
    public class ApplicationLogRequest{
        public string id{get;set;}
        public string statusCode{get;set;}
        public string statusDescription{get;set;}
        public string D3CallKey{get;set;}
    }
    
    global class Response{
        public string message{get;set;}
        
    }
        
    }