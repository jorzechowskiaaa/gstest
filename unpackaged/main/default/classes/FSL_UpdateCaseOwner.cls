/*
  @description:     Rest Resource to update case owner
  @date:            NOV 02, 2023
  @author:          Salesforce Services
*/

@RestResource(urlMapping='/UpdateCaseOwner/')
global with sharing class FSL_UpdateCaseOwner {
    public static String caseId;
    public static String emailId;
    public static UpdateCaseOwnerResponse response;

    @HttpPost
    global static UpdateCaseOwnerResponse updateCaseOwner() {
        RestRequest request = RestContext.request;
        //RestResponse response = RestContext.response;
        UpdateCaseOwnerRequest req = (UpdateCaseOwnerRequest) JSON.deserialize(request.requestBody.toString(), UpdateCaseOwnerRequest.class);
        caseId = req.callEvents[0].caseId;
        emailId = req.callEvents[0].emailId;
        return updateCase();
    }

    private static UpdateCaseOwnerResponse updateCase() {
        try{
            if(String.isEmpty(caseId) || String.isEmpty(emailId)){
                setResponse('400','Bad Request','Missing Required values');
            }else{
                Case c = new Case();
                c.Id = caseId;
                c.OwnerId = getUserIdByEmail;
                if(String.isEmpty(c.ownerId)){
                    setResponse('404','Not Found','Unable to find a user with the provided email');
                }else{
                    Database.SaveResult sr = Database.update(c, true);
                    if(sr.isSuccess()){
                        setResponse('200','success','Updated owner successfully');
                    }else{
                        setResponse('500','error','Internal Server Error');
                    }
                }
            }
        }Catch (Exception e){
            setResponse('500','error',e.getMessage());
            FSL_ApplicationLogCreator.integrationLog ('caseId:'+caseId+' emailId: '+emailId,e.getMessage(),'/UpdateCaseOwner/','UpdateCaseOwnerResponse',true,e.getMessage(),null);
        }
        
        return response;
    }

    private static String getUserIdByEmail{
        get{
            List<User> users = [Select Id from User where Email = :emailId limit 1];
            if(users.size() > 0){
                return users[0].Id;
            }
            return '';
        }
        private set;
    }

    private static void setResponse (String statusCode, String status, String statusDescription){
        response = new UpdateCaseOwnerResponse();
        response.statusCode          =   statusCode;
        response.status              =   status;
        response.statusDescription   =   statusDescription;
    }

    public class UpdateCaseOwnerRequest {
        public List<callEvents> callEvents;
    }

    public class callEvents {
        public String caseId;
        public String emailId;
    }

    global class UpdateCaseOwnerResponse {
        global string statusCode;
        global String status;
        global String statusDescription;
    }
}