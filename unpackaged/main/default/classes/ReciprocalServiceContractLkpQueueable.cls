public class ReciprocalServiceContractLkpQueueable implements Queueable, Database.AllowsCallouts {
	public Map<Id, Reciprocal__c> reciprocals = new Map<Id, Reciprocal__c>();
    
    public ReciprocalServiceContractLkpQueueable (Map<Id, Reciprocal__c> rcpls ) {
        reciprocals = rcpls;
    }
    
    public void execute(QueueableContext qc) {
        Map<Id, Reciprocal__c> reciprocalsProc = new Map<Id, Reciprocal__c>();
        List<Reciprocal__c> updateRecList = new List<Reciprocal__c>();
		List<FSL_Application_Log__c> appLogInsertList = new List<FSL_Application_Log__c>();
        Integer noOfElements = 0;
        
        if (reciprocals.size() > 0) {
            for(Reciprocal__c rec : reciprocals.values()) {
				//Restricting to 1 record because there is a call to Class.Util_ManageAccessTokens.callOAuth which needs to save current record
            	if (noOfElements >= 1) {
					break; 
				} 

                reciprocalsProc.put(rec.Id, rec);
            	reciprocals.remove(rec.Id);
            	noOfElements++;
            }      
            
        	for(Reciprocal__c rec : reciprocalsProc.values()) {
            	if (!String.isBlank(rec.Member_Id__c)) {
					Map<String, String> mapRequestParams  = new Map<String, String>{
						'memberId' => rec.Member_Id__c
					};

            		if (mapRequestParams != null && !mapRequestParams.isEmpty()) {
            			try {
            				ACG_GlobalSearchController.Results res = 
								ACG_GlobalSearchController.invokeMembershipAPIs(
									'lookup', mapRequestParams, ''
								);

                			rec.Member__c = res?.updatedRecordId;
							rec.Service_Contract__c = res?.contract?.contractId;
                			updateRecList.add(rec);
            			} catch (Exception e) {
							String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

							appLogInsertList.add(
								new FSL_Application_Log__c(
									Operation__c = 'ReciprocalServiceContractLkpQueueable',
									Error_Message__c = errMsg
								)
							);
        				}
        			}
        		}
        	}
        }
        
		if (updateRecList.size() > 0) {
			update updateRecList;
		}

		if (appLogInsertList.size() > 0) {
			insert appLogInsertList;
		}
        
        if (reciprocals.size() > 0) {
			System.enqueueJob(new ReciprocalServiceContractLkpQueueable(reciprocals));
        }
    }
}