/************************************************************************************
Apex Class Name     : ACG_CaseTriggerService
Created Date        : 16th August 2021
Function            : Service Class for ACG_CaseTrigger. 
Author              : Deloitte Consulting 
*************************************************************************************/

public without sharing class ACG_CaseTriggerService {
 	private static Id callAdjustmentRecTypeId = EP.getRecordTypeId(ERS_Payment__c.SObjectType, 'Call_Adjustment');  
    private static Id callRecTypeId = EP.getRecordTypeId(ERS_Payment__c.SObjectType, 'Call_Payment');   
    
     /*
     * @description: To update ERS Cases to from 'New' ->'In Progress'(status) on first update. And update status to 'Spotted' when vehicle location is saved
     * @date: August 16, 2021
     * @param1: newMap -> newly updated records
     * @param2: oldMap -> old records
     * @author: Tarun Singh (tbondili@acg.aaa.com)
     * User Story: ERSBO -282
     */ 
     public static void updateStatus(List<Case> newList, Map<Id, Case> oldMap){
        for(Case objCase: newList){
             if(( oldMap == NULL && objCase.ACG_Vehicle_Location_Address__c != NULL ) ||
                (oldMap != NULL
                 && objCase.ACG_Vehicle_Location_Address__c != NULL
                 && objCase.ACG_Vehicle_Location_Address__c != oldMap.get(objCase.Id).ACG_Vehicle_Location_Address__c
                 && objCase.Status == 'In Progress'
                 && objCase.Status != 'Spotted')){  // on update
                     objCase.Status = 'Spotted';
                 }
            else if(  ( oldMap == NULL && objCase.Status == 'Escalated' ) 
                    ||(objCase.Status != (oldMap.get(objCase.Id)).Status && objCase.Status == 'Escalated')){
                	objCase.IsEscalated = true;
            }
            else{
                if(objCase.Status != (oldMap.get(objCase.Id)).Status ){ //When Status field is updated
                    validateCaseStatus(objCase);
                }
            }
        }
        
    }
    
    /*
     * @description: To update ERS Cases to from 'New' ->'In Progress'(status) on first update.
     * @date: August 16, 2021
     * @param1: newMap -> newly updated records
     * @param2: oldMap -> old records
     * @author: Tarun Singh (tbondili@acg.aaa.com)
     * User Story: ERSBO -282
     */
     public static void updateSMSOptIn(List<Case> lstCases){
        /*Set<Id> setAccountIds = new Set<Id>();
        list<Case> caseList = new List<Case>();
        for(Case objCase: lstCases){
            if(objCase.AccountId != null && objCase.ACG_Case_Contact_Number__c != null){
           		setAccountIds.add(objCase.AccountId);
            	caseList.add(objCase);
            }
            else{
                objCase.ACG_SMS_Opt_In__c = false;
            }
        }
         
        system.debug('caseList*******'+caseList);
        system.debug('setAccountIds*******'+setAccountIds);
        Map<Id, Account> mapAccounts = new Map<Id,Account>([SELECT Id,ACG_SMS_Opt_In__c, Phone, ACG_Primary_Phone_Type__c, PersonHomePhone, ACG_Secondary_Phone_Type__c, ACG_Alternate_Phone_Type__c, ACG_Alternate_Phone__c FROM Account WHERE Id IN :setAccountIds LIMIT :Limits.getLimitQueryRows()]);
        system.debug('mapAccounts*******'+mapAccounts);
        
        for(Case objCase: caseList){
            if(mapAccounts.containsKey(objCase.AccountId)){
                system.debug('match*******'+mapAccounts.get(objCase.AccountId).ACG_Primary_Phone_Type__c);
                system.debug('match*******'+mapAccounts.get(objCase.AccountId).Phone);
                system.debug('match*******'+objCase.ACG_Case_Contact_Number__c);
                if(mapAccounts.get(objCase.AccountId).ACG_Primary_Phone_Type__c == 'Mobile' && mapAccounts.get(objCase.AccountId).Phone == objCase.ACG_Case_Contact_Number__c){
                    system.debug('match*******');
                    objCase.ACG_SMS_Opt_In__c = true;
                    system.debug('objCase*******'+objCase);
                } 
                else if(mapAccounts.get(objCase.AccountId).ACG_Secondary_Phone_Type__c == 'Mobile' && mapAccounts.get(objCase.AccountId).PersonHomePhone == objCase.ACG_Case_Contact_Number__c){
                    system.debug('match*******');
                    objCase.ACG_SMS_Opt_In__c = true;
                    system.debug('objCase*******'+objCase);
                } 
                else if(mapAccounts.get(objCase.AccountId).ACG_Alternate_Phone_Type__c == 'Mobile' && mapAccounts.get(objCase.AccountId).ACG_Alternate_Phone__c == objCase.ACG_Case_Contact_Number__c){
                    system.debug('match*******');
                    objCase.ACG_SMS_Opt_In__c = true;
                    system.debug('objCase*******'+objCase);
                }
                else{
                    objCase.ACG_SMS_Opt_In__c = false;
                }
            }    
        }*/
    }
    
    
    public static void updateClubName(List<Case> lstCases){
         Set<Id> setAccountIds = new Set<Id>();
        for(Case objCase: lstCases){
           
            if(objCase.AccountId == null)
            {
                objCase.Club_Name__c = '';
                objCase.Club_Code__c = '';
            }
            else{
                setAccountIds.add(objCase.AccountId);
            }
        }
        
        Map<Id, Account> mapAccounts = new Map<Id,Account>([SELECT Id,ACG_Club_Name__c,ACG_Club__c FROM Account WHERE Id IN :setAccountIds  LIMIT :Limits.getLimitQueryRows()]);          
        if(mapAccounts.size() > 0){
           
            for(Case objCase: lstCases){
                if( mapAccounts.get(objCase.AccountId) != NULL &&
                ( (mapAccounts.get(objCase.AccountId)).ACG_Club_Name__c != NULL || (mapAccounts.get(objCase.AccountId)).ACG_Club__c != NULL ) ){
                  
                    objCase.Club_Name__c = (mapAccounts.get(objCase.AccountId)).ACG_Club_Name__c;
                    objCase.Club_Code__c =  (mapAccounts.get(objCase.AccountId)).ACG_Club__c;  
                }
                
            }
        }
     
        
    }
     /*
     * @description: To populate the household associated to the member account.
     * @date: August 24, 2021
     * @param1: lstCase -> newly updated records
     * @param2: mapCase -> old records
     * @author: Sarita Mishra(sarimishra@deloitte.com)
     */ 
     public static void populateHouseholdName(List<case> lstCase,Map<Id,case> mapCase){     
        try{
            Set<Id> setAccountIds = new Set<Id>(); 
            for(Case objCase:lstCase){
                Case objOldCase = mapCase==null?null:mapCase.get(objCase.Id);              
                if(objOldCase==null || (objOldCase!=null && objCase.AccountId != objOldCase.AccountId)){
                    if(objCase.AccountId != null){
                        setAccountIds.add(objCase.AccountId);       
                    }
                }
            }
            Id household_RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
            List<AccountContactRelation> lstHouseholdAccounts = [SELECT AccountId,Contact.AccountId
                                                                FROM AccountContactRelation 
                                                                WHERE ContactId IN (SELECT PersonContactId
                                                                                    FROM Account
                                                                                    WHERE Id IN: setAccountIds) 
                                                                AND Account.RecordTypeId =: household_RecordTypeId LIMIT :Limits.getLimitQueryRows()];
            Map<Id,Id> mapHouseholds = new Map<Id,Id>();
            for(AccountContactRelation objAccCon: lstHouseholdAccounts){
                mapHouseholds.put(objAccCon.Contact.AccountId,objAccCon.AccountId); //map->(memberId,householdId)
            }
            for(Case objCase:lstCase){
                if(objCase.AccountId != null && mapHouseholds.containsKey(objCase.AccountId) && setAccountIds.contains(objCase.AccountId)){
                    objCase.Member_Household__c =  mapHouseholds.get(objCase.AccountId);
                }
            }
        }catch(Exception ex){
            system.debug('Error occured while populating household Name: ' + ex.getMessage());
        } 
    }
	 
    /*
     * @description: To populate the Agent Club Name field based on the Case owner's Club Name. (ERSBO-2663)
     * @date: Nov 19,2021
     * @param1: lstCase 
     * @author: Tarun Singh
     */
    public static void update_AgentClubName(List<Case> lstCases){
        Set<Id> setUserId = new Set<Id>();
        for(Case cs : lstCases){
            if(string.valueOf(cs.OwnerId).startsWith('005')){	//if assigned to a User and not a Queue
                setUserId.add(cs.OwnerId);}
        }
        Map<Id,User> mapUser = new Map<Id,User>([SELECT Id, Club_Name__c FROM USER WHERE Id IN :setUserId]);
        for(Case objCase : lstCases){
            if(string.valueOf(objCase.OwnerId).startsWith('005') && objCase.ERS_Agent_Club_Name__c == NULL){	//Update only once
                objCase.ERS_Agent_Club_Name__c = (mapUser.get(objCase.OwnerId)).Club_Name__c;    
            }
            
        }
    }
    /*
     * @description: To set the Case priority to 'Critical'
     * @date: Nov 15, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */ 
    public static void handleVIPCases(List<Case> lstCases, Map<Id,Account> mapAccounts){	//ERSBO-2663
    }
    //     for(Case objCase : lstCases){
            
    //          if(mapAccounts == NULL){	//Before Insert scenario (lstCases contains only Cases with VIP members)
    //         	objCase.VIP_Case__c = true;
    //              objCase.IsEscalated = true;
    //              objCase.Was_Escalated__c = true;
    //              objCase.ERS_BypassStatusValidationforFlow__c = true;
    //              objCase.Status = 'Escalated';
    //         }else if(mapAccounts != NULL){	//Before Update scenario (lstCases contains Cases whose Member account was updated)
    //             if(objCase.AccountId == NULL ){
    //                 objCase.VIP_Case__c = false;
    //             }
    //             else if(objCase.AccountId != NULL && mapAccounts.containsKey(objCase.AccountId)){
	// 				if((mapAccounts.get(objCase.AccountId)).VIP__c){
    //                     objCase.VIP_Case__c = true;
    //                     objCase.IsEscalated = true;
    //              		objCase.Was_Escalated__c = true;
	// 					objCase.ERS_BypassStatusValidationforFlow__c = true;
    //                     objCase.Status = 'Escalated';
    //                 }else {
    //                     objCase.VIP_Case__c = false;
    //                 }
    //             }
    //         }
    //     }
    // }
    
    /*
     * @description: To create Task and notification to Supervisors on VIP cases
     * @date: Nov 18, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */
    public static void handle_VIP_Escalation(List<Case> lstCases){
    }
    //     List<CustomNotificationType> type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'VIP_ERS_Case_Escalation'];
    //     //Get Supervisor Queues wrt. Club Names
    //     Set<String> lstClubNames = new Set<String>();
    //     List<Schema.PicklistEntry> picklistVals = User.Club_Name__c.getDescribe().getPicklistValues();
        
    //     for(Schema.PicklistEntry val : picklistVals){
    //         if(val.isActive()){
    //             lstClubNames.add(val.getLabel());
    //         }
    //     }
    //     Map<String, Id> mapClubNameToQueue = new Map<String,Id>();	//Contains a map from 'Club Name' -> 'VIP Supervisor Queue'
    //     Id ACG_VIP_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'ACG_VIP_Supervisor_Queue' AND Type ='Queue'].Id;
    //     Id CMC_VIP_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'CMC_VIP_Supervisor_Queue' AND Type ='Queue'].Id;
    //     Id CO_VIP_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'CO_VIP_Supervisor_Queue' AND Type ='Queue'].Id;
        
    //     for(String clubName : lstClubNames){
    //         if((Label.CO_VIP_Supervisor_Queue).containsIgnoreCase(clubName)){
    //             mapClubNameToQueue.put(clubName, CO_VIP_Supervisor_Queue_Id );
    //         }else if((Label.CMC_VIP_Supervisor_Queue).containsIgnoreCase(clubName)){
    //             mapClubNameToQueue.put(clubName, CMC_VIP_Supervisor_Queue_Id );
    //         }else if((Label.ACG_VIP_Supervisor_Queue).containsIgnoreCase(clubName)){
    //             mapClubNameToQueue.put(clubName, ACG_VIP_Supervisor_Queue_Id );
    //         }
    //     }
	// 	Set<Id> setAccountId = new Set<Id>();     	
    //     for(Case cs : lstCases){
    //         setAccountId.add(cs.AccountId);
    //     }
        
    //     Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :setAccountId]);
    //     List<Task> taskToCreate = new List<Task>();
        
    //     for(Case objCase : lstCases){
    //         Id SupervisorQueueId = mapClubNameToQueue.get(objCase.ERS_Agent_Club_Name__c);
    //         if(SupervisorQueueId != NULL){
    //             Id ERSSupervisor_RecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('ERS_Supervisor').getRecordTypeId();
    //             if(Task.sObjectType.getDescribe().isCreateable()){
    //                 Task Tsk = new Task();
    //                 Tsk.OwnerId = SupervisorQueueId;
    //                 Tsk.WhatId = objCase.Id;
    //                 /* FIXME The following field does not exists in DevEnero
    //                 Tsk.Member_Name__c = mapAccounts.get(objCase.AccountId).Name;
    //                 Tsk.Due_Date_Time__c = (System.now()).addMinutes(5);
    //                 */
    //                 Tsk.Subject = 'VIP Case Escalation';
    //                 Tsk.Type = 'VIP Escalation';
    //                 Tsk.Priority = 'High';
    //                 Tsk.Status = 'Open';
    //                 Tsk.ActivityDate = System.today();
                    
    //                 Tsk.RecordTypeId = ERSSupervisor_RecTypeId;
    //                 taskToCreate.add(Tsk);
    //             }
                
    //             Messaging.CustomNotification notification = new Messaging.CustomNotification();
    //             notification.setBody('VIP escalation for ERS Case '+objCase.CaseNumber);
    //             notification.setTitle('VIP Escalation');
    //             notification.setSenderId(objCase.OwnerId);
    //             notification.setNotificationTypeId(type[0].id);
    //             notification.setTargetId(objCase.Id);
    //             Set<String> recipientId = new Set<String>();
    //             recipientId.add(String.valueOf(SupervisorQueueId));
    //             system.debug('***'+recipientId);
    //             notification.send(recipientId);
    //         }
    //     } 
            
	// 	if(!taskToCreate.isEmpty()){
	// 		insert taskToCreate;
	// 	}
    // }
    
    /*
     * @description: To update the Case owner to Supervisor queues when Escalated
     * @date: Nov 23, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */
    public static void handle_Escalation(List<Case> lstCases){


        
        //=======================================================================================================================
        //NOTE: This method needs work before re-enable it (ex. Group queries need fixing - Type = 'Regular' instead of 'Queue')
        //=======================================================================================================================



        // //Get Supervisor Queues wrt. Club Names
        // List<String> lstClubNames = new List<String>();
        // List<Schema.PicklistEntry> picklistVals = User.Club_Name__c.getDescribe().getPicklistValues();
        // for(Schema.PicklistEntry val : picklistVals){
        //     if(val.isActive()){
        //         lstClubNames.add(val.getLabel());
        //     }
        // }
        
        //  Map<String, Id> mapClubNameToQueue = new Map<String,Id>();	//Contains a map from 'Club Name' -> 'VIP Supervisor Queue'
        // Id ACG_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'ACG_Supervisor_Queue' AND Type ='Queue'].Id;
        // Id CMC_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'CMC_Supervisor_Queue' AND Type ='Queue'].Id;
        // Id CO_Supervisor_Queue_Id = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'CO_Supervisor_Queue' AND Type ='Queue'].Id;
        
        // for(String clubName : lstClubNames){
        //     if((Label.CO_Supervisor_Queue).containsIgnoreCase(clubName)){
        //         mapClubNameToQueue.put(clubName, CO_Supervisor_Queue_Id );
        //     }else if((Label.CMC_Supervisor_Queue).containsIgnoreCase(clubName)){
        //         mapClubNameToQueue.put(clubName, CMC_Supervisor_Queue_Id );
        //     }else if((Label.ACG_Supervisor_Queue).containsIgnoreCase(clubName)){
        //         mapClubNameToQueue.put(clubName, ACG_Supervisor_Queue_Id );
        //     }
        // }
        
        // for(Case objCase : lstCases){
        //     Id SupervisorQueueId = mapClubNameToQueue.get(objCase.ERS_Agent_Club_Name__c);
        //     if(SupervisorQueueId != NULL){
        //         if(objCase.Status != 'Escalated'){
        //             objCase.ERS_BypassStatusValidationforFlow__c = true;
        //             objCase.Status = 'Escalated';
        //             objCase.IsEscalated = true;
		// 		}
		// 		objCase.Was_Escalated__c = true;
        //         objCase.OwnerId = SupervisorQueueId;
        //     }
        // }
    }
    
    /*
     * @description: To set the Case priority to 'Critical'
     * @date: Nov 15, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */ 
  
    public static void updatePriorityToCritical(List<Case> lstCases){	//ERSBO-2663
        for(Case objCase : lstCases){
            objCase.Bypass_Priority_Update__c = true;
           if( objCase.Priority != 'Critical'){	//If current Priority is not 'Critical', update to critical
                  objCase.Priority = 'Critical';
        	}
    	}
    }
    /*
     * @description: To determine if the same member has a case created within the last 24 hrs
     * @date: Nov 22, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */ 
    public static void handleMultipleRequests(List<Case> lstCases){
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> setAccountWithCases = new Set<Id>();
        for(Case cs : lstCases){
            setAccountId.add(cs.AccountId);
        }
        DateTime Last_24_Hrs = (System.now()).addHours(-24);
        for(Case cas : [SELECT Id,AccountId,CreatedDate FROM Case WHERE AccountId IN: setAccountId AND CreatedDate >= :Last_24_Hrs]){
            setAccountWithCases.add(cas.AccountId);
        }
        
        for(Case objCase : lstCases){
            if(setAccountWithCases.contains(objCase.AccountId)){
                objCase.ERS_Same_Member_in_24_Hrs__c = true;
            }
            else{
                objCase.ERS_Same_Member_in_24_Hrs__c = false;
            }
        }
    }
  /*
     * @description: To determine the Case priority
     * @date: Sept 3, 2021
     * @param1: List<Case>
     * @author: Tarun Singh
     */ 
    public static void updateCasePriority(List<Case> lstCases){
        
        
        List<ACG_ERS_Case_Priority_Mapping__mdt> mdtList = [SELECT  ACG_Case_Priority__c,
                                                                    ACG_Case_Priority_Mapping_Status__c,
                                                                    ACG_Case_Record_Type__c,
                                                                    ACG_Club__c,
                                                                    ACG_ERS_Event_Type__c,
                                                                    ACG_Membership_Level__c,Tow_Request_Reason__c,
                                                                    ACG_Service_Type__c, 
                                                                    ACG_Vehicle_Location_Type__c,
                                                                    ACG_Vehicle_Type__c,
                                                                    VIP_Case__c,Same_Member_in_24_Hrs__c
                                                            FROM ACG_ERS_Case_Priority_Mapping__mdt
                                                            WHERE ACG_Case_Priority_Mapping_Status__c = 'Active'
                                                            AND ACG_Case_Record_Type__c = 'ERS'];
        //If active Metadata records exist
        if(!mdtList.isEmpty()){ 
            //Fetch the Membership level of all associated members
            List<Id> lstMembers = new List<Id>(); 
            for(Case objCase: lstCases){    
                if(objCase.AccountId != NULL){
                    lstMembers.add(objCase.AccountId);
                }
            }
            Map<Id,Account> mapMembershipLevel = new Map<Id,Account>([SELECT Id,
                                                                            Level_of_Membership__c,
                                                                            AAA_Membership_Level__c
                                                                      FROM Account 
                                                                      WHERE Id IN :lstMembers]);
            
            // Get the Priority values that matches the case criteria from metadata records 
            for(Case objCase: lstCases){
                
                if( !objCase.Bypass_Priority_Update__c ){
                    Set<String> setPriority = new Set<String>();
                    for(ACG_ERS_Case_Priority_Mapping__mdt mdtRec : mdtList){
                        
                        if(   ( mdtRec.ACG_Vehicle_Location_Type__c == objCase.ACG_Vehicle_Location_Type__c || mdtRec.ACG_Vehicle_Location_Type__c == 'All' ) 
                           && ( mdtRec.ACG_Vehicle_Type__c == objCase.Member_Vehicle_Type__c                   ||  mdtRec.ACG_Vehicle_Type__c == 'All' )
                           && ( mdtRec.ACG_Club__c == objCase.Club_Name__c                   				||  mdtRec.ACG_Club__c == 'All' )
                           && ( mdtRec.ACG_ERS_Event_Type__c == objCase.ERS_Event_Type__c                   ||  mdtRec.ACG_ERS_Event_Type__c == 'All' )
                           && ( ( mapMembershipLevel.get(objCase.AccountId) != NULL
                                 && mdtRec.ACG_Membership_Level__c == (mapMembershipLevel.get(objCase.AccountId)).AAA_Membership_Level__c)  ||  mdtRec.ACG_Membership_Level__c == 'All')
                           && ( ( objCase.ACG_Service_Type__c != NULL 
                                 && (objCase.ACG_Service_Type__c).containsIgnoreCase(mdtRec.ACG_Service_Type__c)    ||  mdtRec.ACG_Service_Type__c == 'All' ))
                           && ( mdtRec.VIP_Case__c == objCase.VIP_Case__c || mdtRec.VIP_Case__c == false)
                           && ( mdtRec.Same_Member_in_24_Hrs__c == objCase.ERS_Same_Member_in_24_Hrs__c || mdtRec.Same_Member_in_24_Hrs__c == false)
						   && ( mdtRec.Tow_Request_Reason__c == objCase.Tow_Request_Reason__c || mdtRec.Tow_Request_Reason__c == 'All')
                           ) {
                              setPriority.add(mdtRec.ACG_Case_Priority__c);
                          }
                    }
    
                    String defaultPriority = (String)(Case.Priority.getDescribe().getDefaultValue());
                    //Assign the highest priority value 
                    String priorityToAssign =   setPriority.contains('Critical')? 'Critical':
                                                setPriority.contains('High')    ? 'High'    :
                                                setPriority.contains('Medium')  ? 'Medium'  :
                                                setPriority.contains('Low')     ? 'Low'     : defaultPriority ; // Set to default case priority, if no value found.
                    
                    system.debug('@@Case Priority will update to '+priorityToAssign+' from the list '+setPriority);
                    objCase.Priority = priorityToAssign;    
                }
                
            }
        }
        }
    
    /*
     * @description: To create payment and payment line items for approved call adjustmets
     * @date: Sept 17, 2021
     * @param1: List<Case>
     * @author: Abhishek Kashyap
     */
    
     // This method is commented in ACG_CaseTriggerHandler

    /*public static void createPaymentForApprovedCallAdjustments(List<Case> approvedCallAdjustmentList){
        Set<Id> workOrderIds = new Set<Id>();
        for(Case eachCallAdjustment : approvedCallAdjustmentList){
            workOrderIds.add(eachCallAdjustment.FSL_Work_Order__c);
        }
        Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, 
                                                                  Member_Account__c 
                                                                  FROM WorkOrder 
                                                                  WHERE Id = :workOrderIds]);
        Map<Id, List<ACG_Call_Adjustment_Line_Item__c>> callAdjustmentToLineItemMap = new Map<Id, List<ACG_Call_Adjustment_Line_Item__c>>();
        List<ERS_Payment__c> newPaymentList = new List<ERS_Payment__c>();
        List<ERS_Payment_Line_Item__c> paymentLineItemList = new List<ERS_Payment_Line_Item__c>();
        
        for(ACG_Call_Adjustment_Line_Item__c eachLineItem : [Select Id, ACG_Case__c,ACG_Case__r.Call_Date__c, ACG_Cost__c, ACG_Product__c,
                                                             ACG_Quantity__c From ACG_Call_Adjustment_Line_Item__c Where ACG_Case__c In :approvedCallAdjustmentList
                                                             And ACG_Approval__c=true]){
                                                                 if(callAdjustmentToLineItemMap.containsKey(eachLineItem.ACG_Case__c)){
                                                                     callAdjustmentToLineItemMap.get(eachLineItem.ACG_Case__c).add(eachLineItem);
                                                                 }
                                                                 else{
                                                                     callAdjustmentToLineItemMap.put(eachLineItem.ACG_Case__c, new List<ACG_Call_Adjustment_Line_Item__c>{eachLineItem});
                                                                 } 
                                                             }
        if(!callAdjustmentToLineItemMap.isEmpty()){
            for(Case eachCallAdjustment : approvedCallAdjustmentList){
                try {
                ERS_Payment__c eachPayment = new ERS_Payment__c();
                eachPayment.RecordTypeId = callAdjustmentRecTypeId;
                //eachPayment.Payment__c = eachCallAdjustment.Payment__c;
                eachPayment.Case__c = eachCallAdjustment.Id;
                eachPayment.Call_Date__c = eachCallAdjustment.Call_Date__c;
                eachPayment.Work_Order__c = eachCallAdjustment.FSL_Work_Order__c;
                eachPayment.Member__c = mapWorkOrder.get(eachCallAdjustment.FSL_Work_Order__c).Member_Account__c;
                eachPayment.Status__c = 'Ready for Payment';
                eachPayment.Facility__c = eachCallAdjustment.Facility__c; 
                eachPayment.Adjustment_Type__c = 'Debit'; 
                eachPayment.X1099__c = true;
                newPaymentList.add(eachPayment);
                }
                catch (System.NullPointerException ex) {
            		 // can be assigned to a variable to display a user-friendly error message
                    system.debug('Error occured while adding work order values: '+ ex.getMessage());
       			 }
            }
            if(newPaymentList.size()>0 
               && Schema.sObjectType.ERS_Payment__c.fields.RecordTypeId.isCreateable()
               //&& Schema.sObjectType.ERS_Payment__c.fields.Payment__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Case__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Call_Date__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Work_Order__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Member__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Status__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Facility__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.Adjustment_Type__c.isCreateable()
               && Schema.sObjectType.ERS_Payment__c.fields.X1099__c.isCreateable()){
                Database.insert(newPaymentList, false);
            }
            
            for(ERS_Payment__c eachPayment : newPaymentList){
                for(ACG_Call_Adjustment_Line_Item__c eachLineItem : callAdjustmentToLineItemMap.get(eachPayment.Case__c)){
                    ERS_Payment_Line_Item__c eachPaymentLineItem = new ERS_Payment_Line_Item__c();
                    eachPaymentLineItem.Payment_ID__c = eachPayment.Id;
                    eachPaymentLineItem.ACG_Product__c = eachLineItem.ACG_Product__c;
                    eachPaymentLineItem.ACG_Units__c = eachLineItem.ACG_Quantity__c;
                    eachPaymentLineItem.Total_Amount__c = eachLineItem.ACG_Cost__c;
                    paymentLineItemList.add(eachPaymentLineItem);
                }
            }
            if(paymentLineItemList.size()>0 
               && Schema.sObjectType.ERS_Payment_Line_Item__c.fields.Payment_ID__c.isCreateable()
               && Schema.sObjectType.ERS_Payment_Line_Item__c.fields.ACG_Product__c.isCreateable()
               && Schema.sObjectType.ERS_Payment_Line_Item__c.fields.ACG_Units__c.isCreateable()
               && Schema.sObjectType.ERS_Payment_Line_Item__c.fields.Total_Amount__c.isCreateable()){
                Database.insert(paymentLineItemList, false);
            }
            
        }
        else{
            for(Case eachCallAdjustment  :approvedCallAdjustmentList){
                eachCallAdjustment.addError('No Call Adjustment Line Items are approved');
            }
        }
    }*/

    /*
     * @description: To validate Case Status for Call Adjustment Requests.
     * @date: Sept 20, 2021
     * @param1: lstCallAdjustment -> new cases 
     * @param2: mapCallAdjustments -> old cases
     * @author: Manmeet Kaur
     */ 
    // This method is commented in ACG_CaseTriggerHandler

    /*Public static void validateCaseStatus(List<Case> lstCallAdjustment, Map<Id,Case> mapCallAdjustments) {
        Id callAdjustmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Call Adjustment').getRecordTypeId();
        String CASE_APPROVED_STATUS = ACG_ConstantsClass.CASE_APPROVED_STATUS;
        String CASE_DENIED_STATUS = ACG_ConstantsClass.CASE_DENIED_STATUS;
        String CASE_PARTIALLY_APPROVED_STATUS = ACG_ConstantsClass.CASE_PARTIALLY_APPROVED_STATUS;

        Set<Id> setCaseIds = new Set<Id>();
        for(Case objCase: lstCallAdjustment){
            Case objOldCase = mapCallAdjustments.get(objCase.Id);
            if(objCase.recordTypeId == callAdjustmentRecordTypeId && objOldCase.Status != objCase.Status){
                setCaseIds.add(objCase.Id);
            }  
        }
        Map<Id,String> caseValidateStatus = new Map<Id,String>();     
        for(ACG_Call_Adjustment_Line_Item__c objCALI: [SELECT ACG_Case__c, 
                                                        ACG_Approval__c 
                                                        FROM ACG_Call_Adjustment_Line_Item__c
                                                        WHERE ACG_Case__c IN: setCaseIds]){
            if(caseValidateStatus.containsKey(objCALI.ACG_Case__c)){
                String casStatus = caseValidateStatus.get(objCALI.ACG_Case__c);
                casStatus = String.ValueOf(objCALI.ACG_Approval__c) + ',' + casStatus;
                caseValidateStatus.put(objCALI.ACG_Case__c,casStatus);
            }else{
                caseValidateStatus.put(objCALI.ACG_Case__c,String.ValueOf(objCALI.ACG_Approval__c));
            }           
        }
        for(Case objCase: lstCallAdjustment){
            String status = objCase.Status;
            if(setCaseIds.contains(objCase.Id) && caseValidateStatus.containsKey(objCase.Id)){
                if(status == CASE_APPROVED_STATUS && caseValidateStatus.get(objCase.Id).contains('false')){
                    objCase.addError(System.Label.Call_Adjustment_Approved);
                }else if(status == CASE_DENIED_STATUS && caseValidateStatus.get(objCase.Id).contains('true')){
                    objCase.addError(System.Label.Call_Adjustment_Denied);
                }else if(status == CASE_PARTIALLY_APPROVED_STATUS && ((caseValidateStatus.get(objCase.Id).contains('true') && !caseValidateStatus.get(objCase.Id).contains('false'))
                    || (caseValidateStatus.get(objCase.Id).contains('false') && !caseValidateStatus.get(objCase.Id).contains('true')))){
                    objCase.addError(System.Label.Call_Adjustment_Partially_Approved);
                }
            }  
        }
    }*/   
    /*
     * @description: To update Work Oder values attached to case
     * @date: Sept 30, 2021
     * @param1: lstCallAdjustment -> new cases 
     * @param2: mapCallAdjustments -> old cases
     * @author: Sarita Mishra
     */ 
   Public static void updateWorkOrderValues(Map<Id,Case> mapNewERSCases) {
        try{
            List<WorkOrder> lstWOUpdate = new List<WorkOrder>();
            List<ServiceAppointment> lstSAUpdate =  new List<ServiceAppointment>();
            if(!mapNewERSCases.isEmpty()){
                for(WorkOrder objWO: [SELECT Id,CaseId,statecode,(Select Id,RecordTypeId from Service_Appointments__r) FROM WorkOrder WHERE CaseId =: mapNewERSCases.keySet()]){
                    WorkOrder objWorkOrder = new WorkOrder();
                    Case objCase = mapNewERSCases.get(objWO.CaseId);
                    objWorkOrder.Id = objWO.Id;
                    objWorkOrder.WO_Member_Phone_Number__c=objCase.ACG_Case_Contact_Number__c;
                    objWorkOrder.Tow_Street__c = objCase.Tow_Destination_Street__c;
                    objWorkOrder.Tow_City__c = objCase.Tow_Destination_City__c;
                    objWorkOrder.Tow_State__c = objCase.Tow_Destination_State__c;
                    objWorkOrder.Tow_Country__c = objCase.Tow_Destination_Country__c;
                    objWorkOrder.Tow_Postal_Code__c = objCase.Tow_Destination_Postal_Code__c;
                    objWorkOrder.Tow_Landmark__c = objCase.Tow_Destination_Name__c;
                    objWorkOrder.Tow_Destination_Name__c = objCase.Tow_Destination_Name__c;
                    objWorkOrder.Tow_Cross_Street__c = '';
                    objWorkOrder.Tow_Cross_Street_2__c = '';
                    objWorkOrder.Tow_Latitude__c = objCase.Tow_Geolocation__Latitude__s;
                    objWorkOrder.Tow_Longitude__c = objCase.Tow_Geolocation__Longitude__s;
                    objWorkOrder.Tow_Location__Latitude__s = objCase.Tow_Geolocation__Latitude__s;
                    objWorkOrder.Tow_Location__Longitude__s = objCase.Tow_Geolocation__Longitude__s;
                    //objWorkOrder.Breakdown_Location__Latitude__s = objCase.Vehicle_Geolocation__Latitude__s;
                    //objWorkOrder.Breakdown_Location__Longitude__s = objCase.Vehicle_Geolocation__Longitude__s;
                    objWorkOrder.Priority_Description__c=objCase.Critical_Call_Reason__c;
                    objWorkOrder.Country = objCase.Vehicle_Location_Country__c;
                    objWorkOrder.Street = objCase.Vehicle_Location_Street__c;
                    objWorkOrder.City = objCase.Vehicle_Location_City__c;
                    objWorkOrder.State = objCase.Vehicle_Location_State__c;
                    objWorkOrder.PostalCode = objCase.Vehicle_Location_Postal_Code__c;
                    objWorkOrder.Latitude = objCase.Vehicle_Geolocation__Latitude__s;
                    objWorkOrder.Longitude = objCase.Vehicle_Geolocation__Longitude__s;
					objworkOrder.Use_your_long_tow_entitlement__c = objCase.Use_your_long_tow_entitlement__c;
                    objworkOrder.Repair_Shop__c  = objCase.Repair_Shop__c ;
                    lstWOUpdate.add(objWorkOrder); 
                    
                    for(ServiceAppointment objSA: objWO.Service_Appointments__r){
    					if(objSA.RecordTypeId == Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId()){
                            ServiceAppointment Breakdown_SA = new ServiceAppointment(Id = objSA.Id);
                            Breakdown_SA.Street = objCase.Vehicle_Location_Street__c;
                         	Breakdown_SA.City = objCase.Vehicle_Location_City__c;
                         	if(objCase.Vehicle_Location_State__c!=null){
                          		Breakdown_SA.State = objCase.Vehicle_Location_State__c;
                          	}else if(objWO.statecode!=null){
                          		Breakdown_SA.statecode = objWO.statecode;
                           	}
                            Breakdown_SA.PostalCode = objCase.Vehicle_Location_Postal_Code__c;
                            Breakdown_SA.Countrycode = ACG_ConstantsClass.US;
                            Breakdown_SA.Latitude = objCase.Vehicle_Geolocation__Latitude__s;
                            Breakdown_SA.Longitude = objCase.Vehicle_Geolocation__Longitude__s;
                            lstSAUpdate.add(Breakdown_SA);
                       }
                         else if(objSA.RecordTypeId == Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId()){
                             ServiceAppointment Tow_SA = new ServiceAppointment(Id = objSA.Id);
                             Tow_SA.Street = objCase.Tow_Destination_Street__c;
                             Tow_SA.City = objCase.Tow_Destination_City__c;
                             if(objCase.Tow_Destination_State__c!=null){
                                 Tow_SA.State = objCase.Tow_Destination_State__c;
                             }
                             Tow_SA.PostalCode = objCase.Tow_Destination_Postal_Code__c;
                             Tow_SA.Countrycode = ACG_ConstantsClass.US;
                             Tow_SA.Latitude = objCase.Tow_Geolocation__Latitude__s;
                             Tow_SA.Longitude = objCase.Tow_Geolocation__Longitude__s;
                             lstSAUpdate.add(Tow_SA);
                         }
                    }
                }
                if(!lstWOUpdate.isEmpty()){
                    Update lstWOUpdate;	
                	if(!lstSAUpdate.isEmpty()){
                        Update lstSAUpdate;	
                    }
                }
            }
        }catch(Exception ex){
            system.debug('Error occured while updating work order values: '+ ex.getMessage());    
        }
    }

    /*
     * @description: To call Google APIs to get Lat/Long
     * @date: Mar 07, 2024
     * @param1: caseIds  
     * @author: Salesforce Services
     */ 
   /* @future(callout=true)
    public static void handle_Breakdown_Location_Changes(List<String> caseIds) {
        String breakdownAddress;
        List<Case> locationUpdatecases;
        List<Double> locationCoords;
        try{
            locationUpdatecases = [SELECT Id, Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c,
                            Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                            Vehicle_Geolocation__Latitude__s,Vehicle_Geolocation__Longitude__s,FSL_Service_Appointment__c from Case where Id IN:caseIds];
            for(Case c : locationUpdatecases){
                breakdownAddress = c.Vehicle_Location_Street__c + ',' + c.Vehicle_Location_City__c + ',' + c.Vehicle_Location_State__c + ',' + c.Vehicle_Location_Postal_Code__c + ',' + c.Vehicle_Location_Country__c;
                if(Test.isRunningTest()){
                    locationCoords = new List<Double>{41.547,-73.6474};
                }else{
                    locationCoords = INTSADAGeoMapAPI.getLatLongFromGoogle(breakdownAddress);
                }
                if(locationCoords.size() == 2){
                    c.Vehicle_Geolocation__Latitude__s = locationCoords[0];
                    c.Vehicle_Geolocation__Longitude__s = locationCoords[1];
                }
            }
            update locationUpdatecases;
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (breakdownAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Updated Breakdown Geolocation successfully', 'getLatLongFromGoogle', false, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__c );
        }catch(Exception ex){
            system.debug('Error occured while calling Google APIs for Breakdown Location'+ ex.getMessage()); 
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (breakdownAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Error while updating Breakdown Geolocation', 'getLatLongFromGoogle', true, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__c );
        }
    }*/
    
    @future(callout=true)
    public static void handle_Breakdown_Location_Changes(List<String> caseIds) {
        String breakdownAddress;
        List<Case> locationUpdatecases;
        // Tyler Antony: Added workorder/serviceappointment updates
        List<WorkOrder> locationUpdateWorkOrders;
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        Map<Id, WorkOrder> caseIdWorkOrderMap = new Map<Id, WorkOrder>();
        List<Double> locationCoords;
        try{
            system.debug('###In try part of try-catch');
            locationUpdatecases = [SELECT Id, Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c,
                            Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                            Vehicle_Geolocation__Latitude__s,Vehicle_Geolocation__Longitude__s,FSL_Service_Appointment__c from Case where Id IN:caseIds];
            locationUpdateWorkOrders = [SELECT Id, CaseId, (Select Id,RecordTypeId, Latitude, Longitude, FSL__InternalSLRGeolocation__Latitude__s, FSL__InternalSLRGeolocation__Longitude__s,Total_Mileage__c  from Service_Appointments__r),Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,Total_Mileage__c  FROM WorkOrder WHERE CaseId IN:caseIds];
            for (WorkOrder wo:locationUpdateWorkOrders) {
                caseIdWorkOrderMap.put(wo.CaseId, wo);
            }
            system.debug('###After workorder for loop');
            for(Case c : locationUpdatecases){
                breakdownAddress = c.Vehicle_Location_Street__c + ',' + c.Vehicle_Location_City__c + ',' + c.Vehicle_Location_State__c + ',' + c.Vehicle_Location_Postal_Code__c + ',' + c.Vehicle_Location_Country__c;
                if(Test.isRunningTest()){
                    locationCoords = new List<Double>{41.547,-73.6474};
                        }else{
                            locationCoords = INTSADAGeoMapAPI.getLatLongFromGoogle(breakdownAddress);
                        }
                if(locationCoords.size() == 2){
                    system.debug('###locationCoords size is 2');
                    c.Vehicle_Geolocation__Latitude__s = locationCoords[0];
                    c.Vehicle_Geolocation__Longitude__s = locationCoords[1];
                    if(caseIdWorkOrderMap.containsKey(c.Id)) {
                        WorkOrder wo = caseIdWorkOrderMap.get(c.Id);
                        wo.Breakdown_Location__Latitude__s = locationCoords[0];
                    	wo.Breakdown_Location__Longitude__s = locationCoords[1];
                        workOrdersToUpdate.add(wo);
                        for(ServiceAppointment sa: wo.Service_Appointments__r) {
                            sa.Latitude = locationCoords[0];
                            sa.Longitude = locationCoords[1];
                            sa.FSL__InternalSLRGeolocation__Latitude__s = locationCoords[0];
                            sa.FSL__InternalSLRGeolocation__Longitude__s = locationCoords[1];
                            saToUpdate.add(sa);
                        }
                    }
                }
            }
            System.debug('###Before cases update');
            update locationUpdatecases;
            if (!workOrdersToUpdate.isEmpty()) {
                update workOrdersToUpdate;
                if(!saToUpdate.isEmpty()){
                    update saToUpdate;
                }
            }
            System.debug('###After updates');
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (breakdownAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Updated Breakdown Geolocation successfully', 'getLatLongFromGoogle', false, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__c );
            System.debug('###After application log insert');
        }catch(Exception ex){
            system.debug('Error occured while calling Google APIs for Breakdown Location'+ ex.getMessage()); 
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (breakdownAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Error while updating Breakdown Geolocation', 'getLatLongFromGoogle', true, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__c );
        }
    }

    @future(callout=true)
    public static void handle_Tow_Location_Changes(List<String> caseIds) {
        String towAddress;
         /**EMI Start - Updated for SSFI-605 DATE:11-05-2024 - only 'Total Mileage' part**/  
        Decimal totalMileage = 0.0;
        List<WorkOrder> locationUpdateWorkOrders;
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
        Map<Id, Case> caseIdWorkOrderMap = new Map<Id, Case>();
        
        List<Case> locationUpdatecases;
        List<Double> locationCoords;
        try{
            locationUpdatecases = [SELECT Id, Tow_Destination_Street__c, Tow_Destination_City__c,Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s,Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                        Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,Total_Mileage__c,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,
                        Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,FSL_Service_Appointment__r.FSL__Related_Service__c from Case where Id IN:caseIds];
            for(Case c : locationUpdatecases){
                towAddress = c.Tow_Destination_Street__c + ',' + c.Tow_Destination_City__c + ',' + c.Tow_Destination_State__c + ',' + c.Tow_Destination_Postal_Code__c + ',' + c.Tow_Destination_Country__c;
            
                if(Test.isRunningTest()){
                    locationCoords = new List<Double>{41.547,-73.6474};
                }else{
                   // locationCoords = INTSADAGeoMapAPI.getLatLongFromGoogle(towAddress);
                    locationCoords = Test.isRunningTest() ? new List<Double>{41.547, -73.6474} : INTSADAGeoMapAPI.getLatLongFromGoogle(towAddress);
                }
                if(locationCoords.size() == 2){
                    c.Tow_Geolocation__Latitude__s = locationCoords[0];
                    c.Tow_Geolocation__Longitude__s = locationCoords[1];
               }
           
               // FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
               // FSL_Mapping.IMap mappingService = new FSL_Mapping.BingMap( appLogService ); 
            
              //  if (c.Vehicle_Geolocation__Latitude__s != null && c.Vehicle_Geolocation__Longitude__s != null 
                  //  && c.Tow_Geolocation__Latitude__s != null && c.Tow_Geolocation__Longitude__s != null) {
                  //  totalMileage = mappingService.calculateDistanceInMiles(
                     //   Double.valueOf(c.Vehicle_Geolocation__Latitude__s),
                     //   Double.valueOf(c.Vehicle_Geolocation__Longitude__s),
                     //   Double.valueOf(c.Tow_Geolocation__Latitude__s),
                     //   Double.valueOf(c.Tow_Geolocation__Longitude__s)
                   // );
                if (c.Vehicle_Geolocation__Latitude__s != null && c.Vehicle_Geolocation__Longitude__s != null 
                && c.Tow_Geolocation__Latitude__s != null && c.Tow_Geolocation__Longitude__s != null) {
                
                FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
                //SSFI-1111 MPatel commented Bing references
               //FSL_Mapping.IMap mappingService = new FSL_Mapping.BingMap(appLogService);

               //totalMileage = mappingService.calculateDistanceInMiles(
                  //Double.valueOf(c.Vehicle_Geolocation__Latitude__s),
                  //Double.valueOf(c.Vehicle_Geolocation__Longitude__s),
                  //Double.valueOf(c.Tow_Geolocation__Latitude__s),
                  //Double.valueOf(c.Tow_Geolocation__Longitude__s)
              //);             
                 if (totalMileage == -1 || totalMileage == 0) {
                       totalMileage = calculateDistance(double.valueOf(c.Vehicle_Geolocation__Latitude__s), double.valueOf(c.Vehicle_Geolocation__Longitude__s),
                                                       double.valueOf(c.Tow_Geolocation__Latitude__s), double.valueOf(c.Tow_Geolocation__Longitude__s));
                 }
                       c.Total_Mileage__c = Math.round(totalMileage);
                         System.debug('Calculated Total_Mileage__c for Case ID ' + c.Id + ': ' + c.Total_Mileage__c);
              } else {
                   	     System.debug('missing coordinates for Case: ' + c.Id);
                }
                 caseIdWorkOrderMap.put(c.Id, c);
            
            }
            update locationUpdatecases;
            
            /**EMI Query WorkOrders to set Total_Mileage__c from updated Case***/
            locationUpdateWorkOrders = [SELECT Id, CaseId, (Select Id,RecordTypeId, Latitude, Longitude, FSL__InternalSLRGeolocation__Latitude__s, FSL__InternalSLRGeolocation__Longitude__s,Total_Mileage__c  from Service_Appointments__r),Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,Total_Mileage__c  FROM WorkOrder WHERE CaseId IN:caseIds];
             for (WorkOrder wo : locationUpdateWorkOrders) {
                if (caseIdWorkOrderMap.containsKey(wo.CaseId)) {
                    Case relatedCase = caseIdWorkOrderMap.get(wo.CaseId);
                    wo.Total_Mileage__c = relatedCase.Total_Mileage__c; 
                    workOrdersToUpdate.add(wo);
                }else {
                    System.debug('Total_Mileage__c is null for Case ID ' + wo.CaseId);
                }
            }
            
            if (!workOrdersToUpdate.isEmpty()) {
                update workOrdersToUpdate; 
            }else {
            System.debug('No WorkOrders to update.');
       		}
              /**EMI End 11/05/2024*/ 
            if(locationCoords[0] != null){
               // update locationUpdatecases;
                FSL_ApplicationLogCreator.insertAplicationLogGeneric (towAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Updated Tow Geolocation successfully', 'getLatLongFromGoogle', false, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__r.FSL__Related_Service__c );
            }
        }catch(Exception ex){
            system.debug('Error occured while calling Google APIs for Tow Location'+ ex.getMessage()); 
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (towAddress, String.valueOf(locationCoords[0])+', '+String.valueOf(locationCoords[1]), 'Error while updating Tow Geolocation', 'getLatLongFromGoogle', true, '', null, 'INTSADAGeoMapAPI', locationUpdatecases[0].FSL_Service_Appointment__r.FSL__Related_Service__c );
        }
    }
    
          
     /**EMI Start 11/05/2024*/ 
     public static Decimal calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
             
               try {
                        Double R = 3958.8; // Radius of Earth in miles
                
                        // Convert degrees to radians
                        Double dLat = (lat2 - lat1) * Math.PI / 180;
                        Double dLon = (lon2 - lon1) * Math.PI / 180;
                
                        // Convert latitude values to radians
                        Double radLat1 = lat1 * Math.PI / 180;
                        Double radLat2 = lat2 * Math.PI / 180;
                
                        Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                                   Math.cos(radLat1) * Math.cos(radLat2) *
                                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
                        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                   		//Double c= =ACOS(COS(RADIANS(90-Lat1)) *COS(RADIANS(90-Lat2)) +SIN(RADIANS(90-Lat1)) *SIN(RADIANS(90-Lat2)) *COS(RADIANS(Long1-Long2)))
                        Decimal haversineDistance = R * c;
                
                        // Updated scaling factor to approximate more complex driving routes
                        Decimal drivingDistanceEstimate = haversineDistance * 1.4;
                        System.debug('Estimated driving distance in miles (1.4 scaling factor): ' + drivingDistanceEstimate);
                        return drivingDistanceEstimate;
                    } catch (Exception ex) {
                        System.debug('Error in calculateDistance: ' + ex.getMessage());
                        return null;
                    }
            }

    /***EMI--End--only part of Total Mileage update**/
  
    @future(callout=true)
    public static void getTimezoneFromMemberLocation(List<String> caseIds) {
        String latlong;
        List<String> resultFromTimezone;
        List<Case> casesToUpdateTimezone;
        try{
            casesToUpdateTimezone = [SELECT Id, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s from Case where Id IN:caseIds];
            for(Case ctz : casesToUpdateTimezone){
                latlong = ctz.Vehicle_Geolocation__Latitude__s + ',' + ctz.Vehicle_Geolocation__Longitude__s;
                if(Test.isRunningTest()){
                    resultFromTimezone = new List<String>{'America/New_York','-1800'};
                }else{
                    resultFromTimezone = INTSADAGeoMapAPI.getTimeZoneFromGoogle(latlong);
                }
                if(resultFromTimezone != null && resultFromTimezone.size() == 2){
                    String timezoneId = resultFromTimezone[0];
                    TimeZone tz = TimeZone.getTimeZone(timezoneId);
                    String offset = tz.getDisplayName();
                    if(String.isNotBlank(offset)){    
                        offset = offset.mid(1,9);
                    }
                    ctz.Member_Location_TZ_Offset__c = offset;
                }
            }
            if(resultFromTimezone[0] != null){
                update casesToUpdateTimezone;
                FSL_ApplicationLogCreator.insertAplicationLogGeneric (latlong, String.valueOf(resultFromTimezone[0])+', '+String.valueOf(resultFromTimezone[1]), 'Updated Member Timezone successfully', 'getTimezoneFromMemberLocation', false, '', null, 'INTSADAGeoMapAPI', null );
            }
        }catch(Exception ex){
            system.debug('Error occured while calling Google APIs to get Timezone of Member Location'+ ex.getMessage()); 
            FSL_ApplicationLogCreator.insertAplicationLogGeneric (latlong, String.valueOf(resultFromTimezone[0])+', '+String.valueOf(resultFromTimezone[1]), 'Error while updating Timezone of member Location', 'getTimezoneFromMemberLocation', true, '', null, 'INTSADAGeoMapAPI', null );
        }
    }

    public static void notifyRepairShopUpdate(List<Case> casesToNotify){
        for(Case objCase : casesToNotify) {
            if(System.label.RepairShopFunctionality == 'TRUE'){
                //FSL_INTRepairShopOutbound.generateRepairShopRequest(objCase.Id,objCase.FSL_Work_Order__c);
                System.enqueueJob(new INTRSPQueuable(objCase.Id,objCase.FSL_Work_Order__c));
            }
        }
    }
        
         
      public static void populateFields(List<Case> newItems){
     	Set<Id> caseIds = new Set<Id>();
        for(Case caseobj : newItems){
            if(caseobj.ERS_Event_Type__c == 'RAP')
                   caseIds.add(caseobj.Id);       
        }
          List<ERS_Payment__c> lst =   [ SELECT Id,Case__c FROM ERS_Payment__c where Case__c in:caseIds];
                for(ERS_Payment__c erp: lst){
                     if((erp.RecordTypeId == callRecTypeId ||erp.RecordTypeId == callAdjustmentRecTypeId))
                        erp.RAP__c = true;              
                }
         update lst;
    }
    
    
    /*
     * @description: Status can only updated to canceled By ERS Advocate Profile User
     * @date: oct 12, 2021
     * @param1: newMap -> newly updated records
     * @param2: oldMap -> old records
     * @author: Sarita Mishra (sarimishra@deloitte.com)
     * User Story: ERSBO -1728
     */ 
 
     public static void validateCaseStatus(Case objCase){
          List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
           String MyProfileName = PROFILE[0].Name;
             if( /*MyProfileName == 'ERS Advocate' && */objCase.Status=='Canceled'  && (objCase.FSL_Work_Order__c != NULL))
             {
                objCase.addError('Once a Work Order is created, you can only cancel the Case via canceling the Work Order.');
             }
             else if(	/*MyProfileName == 'ERS Advocate' 
                     	&&*/  ( ! (Label.ERS_ALLOWED_CASE_STATUS_VALS).containsIgnoreCase(';'+objCase.Status+';') )   
                		&& !(objCase.FSL_Work_Order__c != NULL && objCase.Status == Label.ERS_CASE_STATUS_ON_WO_CREATION ) //Bypass validation when Status is updated on WO creation.
               		&& !objCase.ERS_BypassStatusValidationforFlow__c){
                
                objCase.Status.addError(Label.ERS_CASE_STATUS_VALIDATION_MSG);
             }
     }
    
     /*
     * @description: Populating Case Membership Level on Case using the Account Membership Level
     * @date: Nov 18, 2021
     * @param1: newMap -> newly inserted and to be updated records
     * @author: Sonikaa(ssaiilakshmi@deloitte.com)
     * User Story: ERSBO -1440(Subtask-2918)
     */ 
    
     public static void updateMembership(List<Case> lstCases){
        Set<Id> accSet = new Set<Id>();
		Id customerRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId();

         for(Case cs: lstCases){
             accSet.add(cs.AccountId);
         }
         system.debug(accSet);
         Map<Id,Account> AccMap = new Map<Id,Account>([select Id,AAA_Membership_Level__c, Membership_Number__c from Account where Id =: accSet  AND RecordTypeId != :customerRecordtypeId]);
         system.debug(AccMap);
		 if(AccMap.size()>0){
         for(Case cs: lstCases){
            if(AccMap.containsKey(cs.AccountId) && AccMap.get(cs.AccountId).AAA_Membership_Level__c!=null){
                 switch on AccMap.get(cs.AccountId).AAA_Membership_Level__c {
   						when 'Basic'   {cs.Case_Membership_Level__c = 'Basic';}	
    					when 'Plus'    {cs.Case_Membership_Level__c = 'Plus'; }
    					when 'Plus RV'  {cs.Case_Membership_Level__c = 'Plus RV'; }
                        when 'Premier' {cs.Case_Membership_Level__c = 'Premier';}
                        when 'Premier RV' {cs.Case_Membership_Level__c = 'Premier RV';}
                        when 'Classic'   {cs.Case_Membership_Level__c = 'Basic';}
						}
            } else if (AccMap.get(cs.AccountId).Membership_Number__c == NoMembershipAccountHelper.DUMMY_MEMBERSHIP){
                cs.Case_Membership_Level__c = 'Basic';
            }
            else {
                 cs.Case_Membership_Level__c = '';
            }
          }
		 }
    }
     /*
     * @description: Calculate Over Miles Field on Case
     * @date: Nov 24, 2021
     * @param1: lstCases-> newly inserted and to be updated records
     * @param2: mapCases -> old instance of cases
     * @author: Manmeet Kaur
     * User Story: ERSBO -1440(Subtask-2958)
     */ 
    
     public static void updateOverMiles(List<Case> lstCases, Map<Id,Case> mapCases){
         try{
             Map<Id,Case> mapTotalMilage = new Map<Id,Case>();
             Set<Id> accountIdSet = new Set<Id>();
             Set<String> membershipLevels = new Set<String>();
             Set<String> States = new Set<String>();
             Set<String> servceTypes = new Set<String>();
             for(Case objCase: lstCases){
                 Case objOldCase = mapCases.get(objCase.Id);
                 if(objCase.Total_Mileage__c != null && objOldCase.Total_Mileage__c != objCase.Total_Mileage__c){
                     mapTotalMilage.put(objCase.Id,objCase);
                     if(objCase.AccountId!=null){
                         accountIdSet.add(objCase.AccountId);
                     }
                     if(objCase.ACG_Service_Type__c!=null){
                         servceTypes.add(objCase.ACG_Service_Type__c);
                     }
                     if(objCase.Case_Membership_Level__c!=null){
                         membershipLevels.add(objCase.Case_Membership_Level__c.toUpperCase());
                     }
                     if(objCase.Vehicle_Location_State__c!=null){
                         States.add(objCase.Vehicle_Location_State__c);
                     }
                 }
             }
             Map<Id,Account> memberMap = new Map<Id,Account>([SELECT 
                                                              AAA_200_Miles_Premier_Tow__c,
                                                              X200_Mile_Tow_Used__c
                                                              FROM 
                                                              Account
                                                              WHERE 
                                                              Id IN: accountIdSet]);
             Map<String,Decimal> mapTowMiles = new Map<String,Decimal>();
             if(!mapTotalMilage.values().isEmpty()){
                List<Membership_Coverage_Metadata__mdt> mapMembershipCoverage = [SELECT 
                                                                                 Max_Tow_Miles__c,
                                                                                 Membership_Level__c,
                                                                                 Service_Type__c,
                                                                                 State__c,
                                                                                 Vehicle_Type__c
                                                                                 FROM 
                                                                                 Membership_Coverage_Metadata__mdt
                                                                                 WHERE
                                                                                 Membership_Level__c IN: membershipLevels AND
                                                                                 Service_Type__c IN: servceTypes AND 
                                                                                 State__c IN: States];
                
             
                 for(Membership_Coverage_Metadata__mdt mcMdt: mapMembershipCoverage){
                     List<String> lstVehicleTypes = mcMdt.Vehicle_Type__c.split(';');
                     for(String vehType: lstVehicleTypes){
                          mapTowMiles.put(mcMdt.Membership_Level__c + '#-#' +  mcMdt.Service_Type__c + '#-#' + vehType + '#-#' +  mcMdt.State__c ,  mcMdt.Max_Tow_Miles__c);
                     } 
                 }
                 for(Case objCase: mapTotalMilage.values()){
                    Decimal AllotedMiles = mapTowMiles.get(objCase.Case_Membership_Level__c.toUpperCase() 
                                                           + '#-#' + objCase.ACG_Service_Type__c 
                                                           + '#-#' + objCase.Member_Vehicle_Type__c 
                                                           + '#-#' + objCase.Vehicle_Location_State__c);
                     if(AllotedMiles != null && memberMap.get(objCase.AccountId).AAA_200_Miles_Premier_Tow__c 
                        && !memberMap.get(objCase.AccountId).X200_Mile_Tow_Used__c
                        && objCase.Total_Mileage__c >200){
                            objCase.Over_Miles__c = objCase.Total_Mileage__c - 200;
                     }else if(AllotedMiles != null && AllotedMiles < objCase.Total_Mileage__c){
                            objCase.Over_Miles__c = objCase.Total_Mileage__c - AllotedMiles;
                     } 
                 }
             }
         }catch(Exception ex){
             system.debug('Exception occured while updating the Over Miles field on Case:' + ex.getMessage());
         }
     }
     /*
     * @description: Calculate Allotted Mileage Field on Case
     * @date: Dec 22, 2021
     * @param1: lstCases-> newly inserted and to be updated records
     * @param2: mapCases -> old instance of cases
     * @author: Monika Jha
     */ 

     public static void updateAllotedMiles(List<Case> lstCases, Map<Id,Case> mapOldCases){
        Map<id,Case> updatedCaseList = new Map<id,Case>();
        Map<id,Case> nonTowUpdatedCaseList = new Map<id,Case>();
        Map<id,Boolean> allotedMilesUsedMap = new Map<id,Boolean>();    
        List<Membership_Coverage_Metadata__mdt> membershipMetadata = new List<Membership_Coverage_Metadata__mdt>();
        
        for(Case eachCase : lstCases)
        {
            if(eachCase.ACG_Service_Type__c == 'Tow' || eachCase.Case_Membership_Level__c != mapOldCases.get(eachCase.id).Case_Membership_Level__c) 
            {  
                updatedCaseList.put(eachCase.id,eachCase);
            }
            if(eachCase.ACG_Service_Type__c != 'Tow' || eachCase.Case_Membership_Level__c != mapOldCases.get(eachCase.id).Case_Membership_Level__c) 
            { 
                nonTowUpdatedCaseList.put(eachCase.id,eachCase);
            }
        }
        
        if(updatedCaseList.size() > 0){
            
            membershipMetadata.addAll([SELECT State__c,Service_Type__c,Membership_Level__c,Max_Tow_Miles__c,X200_Miles_Coverage__c 
                                       FROM Membership_Coverage_Metadata__mdt 
                                       WHERE Service_Type__c = 'Tow']);
            
            for(Case caserec : [SELECT id,ServiceContractId,ServiceContract.ParentServiceContract.AAA_Long_Tow_Consumed__c FROM Case WHERE id IN :updatedCaseList.keySet()]){
                if(caserec.ServiceContractId != NULL && caserec.ServiceContract.ParentServiceContractId != NULL){
                    allotedMilesUsedMap.put(caserec.id,caserec.ServiceContract.ParentServiceContract.AAA_Long_Tow_Consumed__c);
                } else{
                    allotedMilesUsedMap.put(caserec.Id,true);
                }
            }
            
            if(allotedMilesUsedMap.size()>0){
                for(Case eachCase : updatedCaseList.values()){
                    if(eachCase.AccountId != NULL){
                    for(Membership_Coverage_Metadata__mdt mdt : membershipMetadata){
                        if(eachCase.ACG_Service_Type__c == mdt.Service_Type__c && eachCase.Case_Membership_Level__c == mdt.Membership_Level__c)
                        {
                            if( allotedMilesUsedMap.get(eachCase.id) == True && mdt.X200_Miles_Coverage__c == True){
                                eachCase.Allotted_Mileage__c = mdt.Max_Tow_Miles__c;
                            }
                            else if(allotedMilesUsedMap.get(eachCase.id) == False && mdt.X200_Miles_Coverage__c == True){
                                eachCase.Allotted_Mileage__c = 200;
                            }
                            else if(mdt.X200_Miles_Coverage__c == False){
                                eachCase.Allotted_Mileage__c = mdt.Max_Tow_Miles__c;
                            }
                        }
                    }
                    }
                    else{
                         eachCase.Allotted_Mileage__c = NULL;
                    }
                }
            }
        }
        
        if(nonTowUpdatedCaseList.size() > 0){
            for(Case caseRec  : nonTowUpdatedCaseList.values())
            {
                caseRec.Allotted_Mileage__c = null;
            }
        }
    }
    
    /*public static void updateAllotedMiles(List<Case> lstCases, Map<Id,Case> mapOldCases){
        Map<id,Case> updatedCaseList = new Map<id,Case>();
        Map<id,Case> nonTowUpdatedCaseList = new Map<id,Case>();
        Map<id,Boolean> allotedMilesUsedMap = new Map<id,Boolean>();    
        List<Membership_Coverage_Metadata__mdt> membershipMetadata = new List<Membership_Coverage_Metadata__mdt>();
        
        for(Case eachCase : lstCases)
        {
            if(eachCase.ACG_Service_Type__c == 'Tow' || eachCase.Case_Membership_Level__c != mapOldCases.get(eachCase.id).Case_Membership_Level__c
               || eachCase.Vehicle_Location_State__c != mapOldCases.get(eachCase.id).Vehicle_Location_State__c) 
            {  
                updatedCaseList.put(eachCase.id,eachCase);
            }
            if(eachCase.ACG_Service_Type__c != 'Tow' || eachCase.Case_Membership_Level__c != mapOldCases.get(eachCase.id).Case_Membership_Level__c
               || eachCase.Vehicle_Location_State__c != mapOldCases.get(eachCase.id).Vehicle_Location_State__c) 
            { 
                nonTowUpdatedCaseList.put(eachCase.id,eachCase);
            }
        }
        
        if(updatedCaseList.size() > 0){
            
            membershipMetadata.addAll([SELECT State__c,Service_Type__c,Membership_Level__c,Max_Tow_Miles__c,X200_Miles_Coverage__c 
                                       FROM Membership_Coverage_Metadata__mdt 
                                       WHERE Service_Type__c = 'Tow']);
            
            for(Case caserec : [SELECT id,AccountId,Account.X200_Mile_Tow_Used__c FROM Case WHERE id IN :updatedCaseList.keySet()]){
                if(caserec.AccountId != NULL){
                    allotedMilesUsedMap.put(caserec.id,caserec.Account.X200_Mile_Tow_Used__c);
                }
                
            }
            
            if(allotedMilesUsedMap.size()>0){
                for(Case eachCase : updatedCaseList.values()){
                    if(eachCase.AccountId != NULL){
                    for(Membership_Coverage_Metadata__mdt mdt : membershipMetadata){
                        if(eachCase.ACG_Service_Type__c == mdt.Service_Type__c && eachCase.Case_Membership_Level__c == mdt.Membership_Level__c
                           && eachCase.Vehicle_Location_State__c == mdt.State__c)
                        {
                            if( allotedMilesUsedMap.get(eachCase.id) == True && mdt.X200_Miles_Coverage__c == True){
                                eachCase.Allotted_Mileage__c = mdt.Max_Tow_Miles__c;
                            }
                            else if(allotedMilesUsedMap.get(eachCase.id) == False && mdt.X200_Miles_Coverage__c == True){
                                eachCase.Allotted_Mileage__c = 200;
                            }
                            else if(mdt.X200_Miles_Coverage__c == False){
                                eachCase.Allotted_Mileage__c = mdt.Max_Tow_Miles__c;
                            }
                        }
                    }
                    }
                    else{
                         eachCase.Allotted_Mileage__c = NULL;
                    }
                }
            }
        }
        
        if(nonTowUpdatedCaseList.size() > 0){
            for(Case caseRec  : nonTowUpdatedCaseList.values())
            {
                caseRec.Allotted_Mileage__c = null;
            }
        }
    }*/
	
	/*
     * @description: Populate CDX Information from the Account
     * @date: Jan 31, 2022
     * @param1: lstCases-> newly inserted and to be updated records
     * @param2: mapCases -> old instance of cases
     * @author: Tarun Singh
     */ 

	public static void updateCDXInfo(List<Case> lstNewCases, Set<Id> setaccountIds){
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT AAA_Membership_Level__c,CDX_Authorization_Code__c,CDX_Authorization_Level__c,
                                                                    CDX_Authorization_Message__c,CDX_Authorization_TransactionId__c, CDX_Membership_Level__c,CDX_Membership_Status__c,
                                                                    CDX_Motorcycle_Coverage__c,ACG_Club__c,ACG_Club_Name__c,ACG_Joined_AAA__c,
                                                                    BillingStreet,BillingCity,BillingStateCode,BillingCountryCode,BillingPostalCode,Membership_Expiration_Date__c,
                                                                    Name,Phone,PersonHomePhone,ACG_Alternate_Phone__c
                                                          FROM Account
                                                          WHERE Id IN :setaccountIds LIMIT 50000]);
        
        
            for(Case objCase: lstNewCases){
                Boolean isCDXMember = objCase.AccountId != NULL && String.isNotBlank(mapAccounts.get(objCase.AccountId).CDX_Authorization_Code__c);
                
                if(isCDXMember){   //If its a CDX member, populate the fields
                objCase.CDX_Authorization_Code__c =  mapAccounts.get(objCase.AccountId).CDX_Authorization_Code__c;
                objCase.CDX_Authorization_Level__c = mapAccounts.get(objCase.AccountId).CDX_Authorization_Level__c;
                objCase.CDX_Entitlement__c = mapAccounts.get(objCase.AccountId).CDX_Authorization_Level__c == 'C' ? false : true;
                objCase.CDX_Authorization_Message__c = mapAccounts.get(objCase.AccountId).CDX_Authorization_Message__c;
                objCase.CDX_Authorization_TransactionId__c = mapAccounts.get(objCase.AccountId).CDX_Authorization_TransactionId__c;
                String CDX_Membership_Level = mapAccounts.get(objCase.AccountId).AAA_Membership_Level__c;
                    objCase.CDX_Membership_Level__c = CDX_Membership_Level;
                    objCase.Case_Membership_Level__c = CDX_Membership_Level;
                String CDX_Membership_Status = mapAccounts.get(objCase.AccountId).CDX_Membership_Status__c;
                    objCase.CDX_Membership_Status__c = CDX_Membership_Status;
                    objCase.CDX_Active__c = CDX_Membership_Status == 'Active' || CDX_Membership_Status == 'Pending' ? true : false;
                objCase.CDX_Motorcycle_Coverage__c = mapAccounts.get(objCase.AccountId).CDX_Motorcycle_Coverage__c;
                objCase.CDX_Home_Address__c =   (  mapAccounts.get(objCase.AccountId).BillingStreet != NULL ? mapAccounts.get(objCase.AccountId).BillingStreet+', ' : '' ) +
                                                (  mapAccounts.get(objCase.AccountId).BillingCity != NULL ? mapAccounts.get(objCase.AccountId).BillingCity+', ' : '' ) +
                                                (  mapAccounts.get(objCase.AccountId).BillingStateCode != NULL ? mapAccounts.get(objCase.AccountId).BillingStateCode+', ' : '' ) +
                                                (  mapAccounts.get(objCase.AccountId).BillingCountryCode != NULL ? mapAccounts.get(objCase.AccountId).BillingCountryCode+', ' : '' ) +
                                                (  mapAccounts.get(objCase.AccountId).BillingPostalCode != NULL ? mapAccounts.get(objCase.AccountId).BillingPostalCode : '' );
                if ( mapAccounts.get(objCase.AccountId).ACG_Joined_AAA__c != null ) {
                    objCase.CDX_Member_Since__c = String.valueOf((mapAccounts.get(objCase.AccountId).ACG_Joined_AAA__c).year()) ;
                }
                objCase.CDX_Type__c = 'N/A' ;
                objCase.CDX_Expiration__c = mapAccounts.get(objCase.AccountId).Membership_Expiration_Date__c ;
                objCase.CDX_Name__c = mapAccounts.get(objCase.AccountId).Name ;
                if(mapAccounts.get(objCase.AccountId).Phone != NULL){
                    objCase.CDX_Phone_Number__c = mapAccounts.get(objCase.AccountId).Phone ;}
                else if(mapAccounts.get(objCase.AccountId).PersonHomePhone != NULL){
                     objCase.CDX_Phone_Number__c = mapAccounts.get(objCase.AccountId).PersonHomePhone ;}
                else if(mapAccounts.get(objCase.AccountId).ACG_Alternate_Phone__c != NULL){
                     objCase.CDX_Phone_Number__c = mapAccounts.get(objCase.AccountId).ACG_Alternate_Phone__c ;}
            }
            else {
                objCase.CDX_Authorization_Code__c =  '';
                objCase.CDX_Authorization_Level__c = '';
                objCase.CDX_Entitlement__c = false;
                objCase.CDX_Authorization_Message__c = '';
                objCase.CDX_Authorization_TransactionId__c = '';
                objCase.CDX_Membership_Level__c = '';
                objCase.CDX_Phone_Number__c = '';
                objCase.CDX_Membership_Status__c = '';
                objCase.CDX_Active__c = false;
                objCase.CDX_Motorcycle_Coverage__c =false;
                objCase.CDX_Home_Address__c = '';
                objCase.CDX_Member_Since__c = '';
                objCase.CDX_Type__c = '';
                objCase.CDX_Expiration__c = NULL;
                objCase.CDX_Name__c = '';
            }
        }
    }
	
	/*
     * @description: Invoked from a Flow. Encrypts the Id of the Case using AES128 encryption. (ERSBO-4393)
     * @date: Feb 28,2022
     * @param1: List<Case>
     * @author: Tarun Singh
     */ 
    @InvocableMethod(label='Encrypt Case Id' description='Encrypt Case Id')
    public static List<Case> generateEncryptedId( List<Case> lstCase){
        Blob encryption_Key = EncodingUtil.base64Decode(Label.ERS_Encryption_Key);
        for(Case cs : lstCase){
            Blob Id = Blob.valueOf(cs.Id);
            Blob encrypted_Id = Crypto.encryptWithManagedIv('AES128', encryption_Key, Id);
            String encrypted_Id_String = EncodingUtil.base64Encode(encrypted_Id);
            cs.Encrypted_Case_Id__c = EncodingUtil.urlEncode(encrypted_Id_String,'UTF-8');
            update cs;
        }
        return lstCase;
    }
} //171