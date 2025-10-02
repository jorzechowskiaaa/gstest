/*
  @description:     Rest Resource to update status of D3 sync
  @date:            NOV 06, 2023
  @author:          Salesforce Services
*/

@RestResource(urlMapping='/UpdateCaseSyncStatus/')
global with sharing class FSL_UpdateD3Sync {
    private static final Id MANUAL_SERVICE_RTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Manual_Service_Order').getRecordTypeId();
    public static final String SYNC_FAILURE_SUBJECT = 'WorkOrder Clear retry failed, manual service order creation required';
    public static final String SYNC_FAILURE_DESC = 'The Clear Queue was unable to clear the WorkOrder, and a manual retry failed. A manual service order creation in IRAS may be necessary';
    public static String d3CallKey;
    public static String workOrderId;
    public static StatusRequest req;
    public static StatusResponse response;
    
    @HttpPost
    global static StatusResponse updateSyncStatus() {
        try{
            RestRequest request = RestContext.request;
            response = new StatusResponse();
            req = (StatusRequest) JSON.deserialize(request.requestBody.toString(), StatusRequest.class);
            d3CallKey = req.D3CallKey;
            workOrderId = req.id;
            if(req.statusCode == 200){
                updateWorkOrder();
                setResponse(200, 'Success', 'Sucessfully update Workorder with D3 Call Key');
            }else {
                updateWorkOrder();
                Boolean isCreated = createClearQueueCase();
                FSL_ApplicationLogCreator.integrationLog (JSON.serialize(req),'Created Manual Service order: '+isCreated,'/UpdateCaseSyncStatus/','updateSyncStatus',true,SYNC_FAILURE_SUBJECT,null);
                if(isCreated == true){
                    setResponse(200, 'Success', 'Successfully created Manual Service Order case');
                }else{
                    setResponse(400, 'Error', 'Error in creating the Manual Service Order case');
                }
            }    
        }Catch(Exception e){
            setResponse(500, 'Error', e.getMessage());
            FSL_ApplicationLogCreator.integrationLog (JSON.serialize(req),'Error in creating the Manual Sevice order case','/UpdateCaseSyncStatus/','updateSyncStatus',true,e.getMessage(),null);
        }
        return response;
    }

    private static void updateWorkOrder(){
        WorkOrder wo = new WorkOrder();
        wo.Id                =       workOrderId;
        wo.D3_Call_Key__c    =       d3CallKey;

        Database.SaveResult sr = Database.update(wo, true);
        System.debug('Updated D3 call key on WO '+sr.isSuccess());
    }

    private static Boolean createClearQueueCase(){
        Case c = new Case();
        c.RecordTypeId      =       MANUAL_SERVICE_RTID;
        c.FSL_Work_Order__c =       workOrderId;
        c.Subject           =       SYNC_FAILURE_SUBJECT;
        c.Description       =       SYNC_FAILURE_DESC;
        c.Origin            =       'Automation';
        c.OwnerId           =       getQueueIdByName;

        Database.SaveResult sr = Database.insert(c, true);
        return sr.isSuccess();
    }

    private static void setResponse (Integer statusCode, String status, String statusDescription){
        response.statusCode          =   statusCode;
        response.status              =   status;
        response.statusDescription   =   statusDescription;
    }

    private static String getQueueIdByName{
        get{
            List<Group> groups = [select Id from Group where  Type = 'Queue' AND NAME = 'Clear Queue'];
            if(groups.size() > 0){
                return groups[0].Id;
            }
            return '';
        }
        private set;
    }

    public class StatusRequest {
        public String id; // WorkOrderId
        public Integer statusCode;
        public String statusDescription;
        public String D3CallKey;
    }

    global class StatusResponse {
        public Integer statusCode;
        public String status;
        public String statusDescription;
    }
}