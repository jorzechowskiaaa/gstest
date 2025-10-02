/**** Apex Class Name    :    ERS_UpdateERSPaymentStatusBatch
    * Description        :    This class is used for bulk processing of RAP Payments to RBP API  
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Derek Barker                April 23, 2024         Created
    * Josh Tupas                  June 11, 2024          Changed to schedulable to run at 1:00 AM ET. Modified query to pick up RAP calls that are 14 days old or more.
    * Josh Tupas                  June 19, 2024          Changed amount of processed records for scheduled batch to be 40 instead of 200 due to "Too many callouts 101" error. Each WO makes 2 callouts, one for token and one for sending RAP data.
    * Minesh Patel				  May 21, 2025           Refactored the code to remove the DataBase.Stateful , moved Batch Size to custom settings, eliminated variables rapVerfIdList & errMsgList by processing everything in the execute method. Moved the WorkOrder updates and log creation to the execute method. 
*********************************************************************************/
public class ERS_GrabRAPReadyWorkOrdersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
    /* SSFI-1191 MPatel commented 
    private List<String> rapVerfIdList;
    private List<Map<String, String>> errMsgList;
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();*/
    public String query;
    
    /* SSFI-1191 MPatel commented
	public ERS_GrabRAPReadyWorkOrdersBatch() {
        errMsgList = new List<Map<String, String>>();
        rapVerfIdList = new List<String>();
    }*/
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults(); //SSFI -1191
        Integer days = boSettings.RAP_Days_to_Verify__c != null ? 
            Integer.valueOf(boSettings.RAP_Days_to_Verify__c) : 0;

        query = 
            'SELECT ' +
                'Id,' + 
                'Call_Type__c,' +
                'RAP_Verified__c' +
            ' FROM WorkOrder' +
            ' WHERE Call_Type__c = \'RAP\'' + 
            ' AND RAP_Status__c = \'RAP Cleared\'' + 
            ' AND Days_Since_Created_Date__c >= ' + days + 
            ' AND RAP_Verified__c != true';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> woList) {
        List<String> rapVerfIdList = new List<String>(); //SSFI-1191
        List<FSL_Application_Log__c> appLogInsList = new List<FSL_Application_Log__c>();  //SSFI-1191
        
        try {
            Set<Id> woIdSet = new Set<Id>();
            
            for (WorkOrder wo : woList) {
                woIdSet.add(wo.Id);
            }

            Map<String, Object> resMap = (Map<String, Object>) INTNationalRBPAPI.createrbprquest(woIdSet);
            List<Map<String, Object>> rbpDataMapList = (List<Map<String, Object>>) resMap.get('woWithReqList');
            Integration_Settings__c integrStg;
            String respStr;

            for (Map<String, Object> reqMap : rbpDataMapList) {
                String woId = (String) reqMap.get('woId');
                INTNationalRBPAPIRequest_Wrapper req = (INTNationalRBPAPIRequest_Wrapper) reqMap.get('req');
                Map<String, Object> respWrapper = INTNationalRBPAPI.sendToStatusToRBP(req, integrStg);
                HttpResponse resp = (HttpResponse) respWrapper.get('resp');

                if (resp?.getStatusCode() >= 200 && resp?.getStatusCode() < 300) {
                    rapVerfIdList.add(woId);
                    respStr = 'GOOD RESPONSE:\n';
                } else {
                    respStr = 'BAD RESPONSE:\n';
                }

                HttpRequest reqObj = (HttpRequest) respWrapper.get('req');
                String jsonPrettifiedReq = JSON.serializePretty(JSON.deserializeUntyped(reqObj.getBody()));
                String respBody;
                List<Map<String, Object>> respHeaders = new List<Map<String, Object>>();

                if (resp != null) {
                    for (String key : resp.getHeaderKeys()) {
                        respHeaders.add(
                            new Map<String, Object>{
                                'key' => key,
                                'value' => resp.getHeader(key)
                            }
                        );
                    }
                }

                try {
                    respBody = JSON.serializePretty(JSON.deserializeUntyped(resp.getBody()));
                } catch (Exception e) {
                    respBody = e.getMessage();
                }
                
                integrStg = (Integration_Settings__c) respWrapper.get('integrStg');
                respStr += JSON.serializePretty(new Map<String, Object>{
                    'RETRY_COUNT' => null,
                    'STATUS_CODE' => resp.getStatusCode(),
                    'ERR_STATUS' => resp.getStatus(),
                    'ERR_MESSSAGE' => respBody,
                    'responseHeaders' => respHeaders
                });
                respStr += '\n\n------------------------------------------------------------';
                respStr += '\n\nRBP request endpoint:\n' + reqObj.getEndpoint();
                respStr += '\n\n------------------------------------------------------------';
                respStr += '\n\nRBP request headers:';
                respStr += '\n-----------------';
                respStr += '\n"Content-Type":\n' + reqObj.getHeader('Content-Type');
                respStr += '\n-----------------';
                respStr += '\n' + ACG_ConstantsClass.TRANSACTION_ID + ':\n' + reqObj.getHeader(ACG_ConstantsClass.TRANSACTION_ID);
                respStr += '\n\n------------------------------------------------------------';
                respStr += '\n\nRBP request sent to National:\n' + jsonPrettifiedReq;
                respStr += '\n\n------------------------------------------------------------';
                respStr += '\n\nOAuth request:\n' + JSON.serializePretty(respWrapper.get('oAuthReq'));

                // SSFI-1191 Moved from Database.BatchableContext to here
                String errMsg = respStr;
                //AGB 8/13/24 SSFI-300
                if(Test.isRunningTest()) { errMsg = errMsg.rightPad(200000, '\n'); } //error message buffer
                Integer i = 1;
                errMsg = 'Part '+i+': \n'+errMsg;
                while(errMsg.length() > 32768) 
                {
                    Integer indexNewLine = errMsg.left(32768).lastIndexOf('\n');
                    if(indexNewLine != -1) {
                        appLogInsList.add(
                            new FSL_Application_Log__c(
                                Operation__c = 'ERS_GrabRAPReadyWorkOrdersBatch',
                                Error_Message__c = errMsg.left(indexNewLine+1),
                                Work_Order__c = woId
                            )
                        );
                        i++;
                        errMsg = 'Part '+i+': \n'+errMsg.substring(indexNewLine+1);
                    }
                }
                
                if(errMsg.length() > 0) {
                    appLogInsList.add(
                        new FSL_Application_Log__c(
                            Operation__c = 'ERS_GrabRAPReadyWorkOrdersBatch',
                            Error_Message__c = errMsg,
                            Work_Order__c = woId
                        )
                    );                          
                } //END AGB 8/13/24 SSFI-300
            }

            // SSFI-1191 Update verified work orders
            if (!rapVerfIdList.isEmpty()) {
                List<WorkOrder> woListToUpdate = [
                    SELECT Id, RAP_Verified__c 
                    FROM WorkOrder 
                    WHERE Id IN :rapVerfIdList
                ];
                
                for (WorkOrder wo : woListToUpdate) {
                    wo.RAP_Verified__c = true;
                }
                
                update woListToUpdate;
            }
            
            
            if (!appLogInsList.isEmpty()) {
                insert appLogInsList;
            }
            
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();
            appLogInsList.add(
                new FSL_Application_Log__c(
                    Operation__c = 'ERS_GrabRAPReadyWorkOrdersBatch',
                    Error_Message__c = errMsg.left(32768)
                )
            );
            
            if (!appLogInsList.isEmpty()) {
                insert appLogInsList;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        /* SSFI-1191 No stateful operations needed, moved the code to execute method
        if (
            rapVerfIdList != null 
            && !rapVerfIdList.isEmpty()
        ) {
            List<WorkOrder> rapVerifiedWOs = new List<WorkOrder>();
            List<WorkOrder> woList = [
                SELECT Id, RAP_Verified__c 
                FROM WorkOrder 
                WHERE Id IN :rapVerfIdList
            ];

            for (WorkOrder wo : woList) {
                wo.RAP_Verified__c = true;
                rapVerifiedWOs.add(wo);
            }

            if (!rapVerifiedWOs.isEmpty()) {
                update rapVerifiedWOs;
            }
        }

        if (errMsgList != null && errMsgList.size() > 0) {
            List<FSL_Application_Log__c> appLogInsList = new List<FSL_Application_Log__c>();

            for (Map<String, String> errMsgMap : errMsgList) {
                String errMsg = errMsgMap.get('errMsg');
                String woId = errMsgMap.get('woId');
                
               	//AGB 8/13/24 SSFI-300
                if(Test.isRunningTest()){errMsg=errMsg.rightPad(200000, '\n');} //error message buffer
               	integer i = 1;
                errMsg = 'Part '+i+': \n'+errMsg;
                while(errMsg.length() > 32768)
                {
 					integer indexNewLine = errMsg.left(32768).lastindexof('\n');
                	if(indexNewLine != -1)
                	{
                 		appLogInsList.add(
                    		new FSL_Application_Log__c(
                        		Operation__c = 'ERS_GrabRAPReadyWorkOrdersBatch',
                        		Error_Message__c = errMsg.left(indexNewLine+1),
                        		Work_Order__c = woId
                    		)
               			 );
                       	if(Test.isRunningTest()){
                            system.debug('woID:'+woId);
                        	system.debug('Length:'+errMsg.left(indexNewLine+1).length());
							system.debug('errMsg:'+errMsg.left(errMsg.indexof('\n')));}
                        i++;
                    	errMsg = 'Part '+i+': \n'+errMsg.substring(indexNewLine+1);
                	}
            	}
            	if(errMsg.length() > 0)
            	{
                    if(Test.isRunningTest()){
                    	system.debug('woID_F:'+woId);
                    	system.debug('Length_F:'+errMsg.length());
                    	system.debug('errMsg_F:'+errMsg.left(errMsg.indexof('\n')));}
					appLogInsList.add(
                    		new FSL_Application_Log__c(
                        		Operation__c = 'ERS_GrabRAPReadyWorkOrdersBatch',
                        		Error_Message__c = errMsg,
                        		Work_Order__c = woId
                    		)
               		);               		               	
                } //END AGB 8/13/24 SSFI-300
            }

            if (appLogInsList.size() > 0) {
                insert appLogInsList;
            }
        } */
    }
    
    public void execute(SchedulableContext ctx) {
        //SSFI-1191 Batch size will be pulled from custom settings
        BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
        Integer batchSize = Integer.valueOf(boSettings.RAP_Batch_Size__c);
        Database.executeBatch(new ERS_GrabRAPReadyWorkOrdersBatch(), batchSize);
      //Database.executebatch(new ERS_GrabRAPReadyWorkOrdersBatch(), 40);
    }
}