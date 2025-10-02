/************************************************************************************
Apex Class Name     : ACG_CaseTriggerHandler
Created Date        : 16th Aug 2021
Function            : Handler Class for Case Trigger. 
Author              : Deloitte Consulting 
*************************************************************************************/
public without sharing class ACG_CaseTriggerHandler implements ACG_TriggerHandlerInterface {

    //khtx - hack for now until getting real solution
    public static Map<string, string> stateCodesMap = new Map<string, string> {
        'Alabama' => 'AL', 
        'Alaska' => 'AK',
        'Arizona' => 'AZ', 
        'Arkansas' => 'AR', 
        'California' => 'CA', 
        'Colorado' => 'CO', 
        'Connecticut' => 'CT', 
        'Delaware' => 'DE', 
        'Florida' => 'FL', 
        'Georgia' => 'GA', 
        'Hawaii' => 'HI', 
        'Idaho' => 'ID', 
        'Illinois' => 'IL', 
        'Indiana' => 'IN', 
        'Iowa' => 'IA', 
        'Kansas' => 'KS', 
        'Kentucky' => 'KY', 
        'Louisiana' => 'LA', 
        'Maine' => 'ME', 
        'Maryland' => 'MD', 
        'Massachusetts' => 'MA', 
        'Michigan' => 'MI', 
        'Minnesota' => 'MN', 
        'Mississippi' => 'MS', 
        'Missouri' => 'MO', 
        'Montana' => 'MT', 
        'Nebraska' => 'NE', 
        'Nevada' => 'NV', 
        'New Hampshire' => 'NH', 
        'New Jersey' => 'NJ', 
        'New Mexico' => 'NM', 
        'New York' => 'NY', 
        'North Carolina' => 'NC', 
        'North Dakota' => 'ND', 
        'Ohio' => 'OH', 
        'Oklahoma' => 'OK', 
        'Oregon' => 'OR', 
        'Pennsylvania' => 'PA', 
        'Rhode Island' => 'RI', 
        'South Carolina' => 'SC', 
        'South Dakota' => 'SD', 
        'Tennessee' => 'TN', 
        'Texas' => 'TX', 
        'Utah' => 'UT', 
        'Vermont' => 'VT', 
        'Virginia' => 'VA', 
        'Washington' => 'WA', 
        'West Virginia' => 'WV', 
        'Wisconsin' => 'WI', 
        'Wyoming' => 'WY', 
        'Ontario' => 'ON', 
        'Quebec' => 'QC', 
        'QuéBec' => 'QC', 
        'British Columbia' => 'BC', 
        'Alberta' => 'AB', 
        'Manitoba' => 'MB', 
        'Saskatchewan' => 'SK', 
        'Nova Scotia' => 'NS', 
        'New Brunswick' => 'NB', 
        'Newfoundland And Labrador' => 'NL', 
        'Prince Edward Island' => 'PE', 
        'Northwest Territories' => 'NT', 
        'Yukon' => 'YT', 
        'Nunavut' => 'NU' 
    };
        
         
    static private void convertStateCode(Case objCase)
    {
        string stateCode = stateCodesMap.get(objCase.Vehicle_Location_State__c);
        if(stateCode != null) {
            objCase.Vehicle_Location_State__c = stateCode;
        }
        stateCode = stateCodesMap.get(objCase.Tow_Destination_State__c);
        if(stateCode != null) {
            objCase.Tow_Destination_State__c = stateCode;
        }
    }

    //Handler Method for Before Insert.
    public void beforeInsert(List<sObject> newItems) {
        List<Case> lstAllERSCases= new List<Case>();
        List<Case> lstNewERSCases = new List<Case>();
        List<Case> lstERSCasesToUpdateStatus=new List<Case>();
        List<Case> lstCases_UpdateToCritical = new List<Case>();
        List<Case> lst_VIP_Cases = new List<Case>();
        Set<Id> lstAccountId = new Set<Id>();
     
        Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
       
        for(Case objCase : (List<Case>)newItems) {

            Datetime GMTDate = Datetime.now();
            String strConvertedDate = GMTDate.format('yyyy-MM-dd HH:mm:ss','America/New_York');
            objCase.Subject = strConvertedDate + ' by ' + UserInfo.getName() ;
            
            convertStateCode(objCase);
            
            if(objCase.RecordTypeId == ERSRecordTypeId) { //For ERS Cases
                lstAllERSCases.add(objCase);    //All ERS Cases
                
                if(objCase.AccountId != NULL) {
                    lstNewERSCases.add(objCase);    //ERS Cases with Member Account
                    lstAccountId.add(objCase.AccountId);
                }
                if(objCase.ACG_Vehicle_Location_Address__c != NULL){
                    lstERSCasesToUpdateStatus.add(objCase);
                }
                
                if(objCase.Case_Priority_Override__c 
                   && objCase.Case_Priority_Override_Reason__c != NULL &&
                   objCase.Priority != 'Critical'){ // Critical ERS Cases
                    lstCases_UpdateToCritical.add(objCase);
                }
                
            }
        }
        if(!lstNewERSCases.isEmpty())
        {
         ACG_CaseTriggerService.updateCDXInfo(lstNewERSCases, lstAccountId);
        }
        /*Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, VIP__c FROM Account WHERE Id IN :lstAccountId]);
        for(Case cs : lstNewERSCases){
            if(mapAccounts.containsKey(cs.AccountId) && (mapAccounts.get(cs.AccountId)).VIP__c){
                lst_VIP_Cases.add(cs);
            }
        }*/
        
        //(ERSBO-2665)
        if(!lstAllERSCases.isEmpty()){
            ACG_CaseTriggerService.update_AgentClubName(lstAllERSCases);
            ACG_CaseTriggerService.updateClubName(lstAllERSCases);
        }
       //Handle VIP Cases (ERSBO-2663)
        /*if(!lst_VIP_Cases.isEmpty()){
            ACG_CaseTriggerService.handleVIPCases(lst_VIP_Cases, NULL);
        }*/
        //Handle Cases from Same member in 24 HRs (ERSBO-2663) 
        if(!lstNewERSCases.isEmpty()){
            ACG_CaseTriggerService.handleMultipleRequests(lstNewERSCases);
        }
        //Populate the Household the Case is associated with.
        if(!lstNewERSCases.isEmpty()){
            //ACG_CaseTriggerService.populateHouseholdName(lstNewERSCases,null);
            ACG_CaseTriggerService.updateSMSOptIn(lstNewERSCases);
           ACG_CaseTriggerService.updateMembership(lstNewERSCases);
            
        }
        // Set priority to Critical on Override (ERSBO-2663)
        if(!lstCases_UpdateToCritical.isEmpty()){
            ACG_CaseTriggerService.updatePriorityToCritical(lstCases_UpdateToCritical);
        }
        //Populate the Case Priority. (ERSBO-1071)
        if(!lstAllERSCases.isEmpty()){
            ACG_CaseTriggerService.updateCasePriority(lstAllERSCases);}
        
        //Populate the Case status as Spotted(ERSBO-1728)
        if(!lstERSCasesToUpdateStatus.isEmpty()){
          ACG_CaseTriggerService.updateStatus(lstAllERSCases,Null); 
        }
    }
    
    //Handler Method for Before Update.
    public void beforeUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems) {
        
        List<Case> lstAllERSCases = new List<Case>();
        List<Case> lstERSCasesToSetPriority = new List<Case>();
        List<Case> lstCaseWithUpdatedMember = new List<Case>();
        List<Case> lstCasesToSetMembershipLevel = new List<Case>();
        List<Case> lstCases_UpdateToCritical = new List<Case>();
        List<Case> lstCases_UpdatedAccount = new List<Case>();
        List<Id> lstToGetMemberTimezone = new List<Id>();
        Set<Id> lstAccountId = new Set<Id>();
        List<Case> lst_Escalated_Cases = new List<Case>();
        List<Case> lst_VIP_Cases = new List<Case>();
        Map<Id,Case> mapOldCases = new Map<Id,Case>((Map<Id,Case>)oldItems);
        Map<Id,Case> mapNewCases = new Map<Id,Case>((Map<Id,Case>)newItems);
        List<Case> lstUpdatedOwners = new List<Case>();
        List<Case> lstCaseWithUpdatedAccountMember = new List<Case>();      
        Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
        
        for(Case objCase : (List<Case>)newItems.values()) {

            convertStateCode(objCase);

            if(objCase.IsEscalated != (mapOldCases.get(objCase.Id)).IsEscalated){ system.debug('ESCALATED'+objCase.IsEscalated); }
            if(objCase.RecordTypeId == ERSRecordTypeId ) {  //For ERS Cases
                
                lstAllERSCases.add(objCase);    //All ERS Cases
                
                if(objCase.OwnerId != (mapOldCases.get(objCase.Id)).OwnerId 
                  && string.valueOf(objCase.OwnerId).startsWith('005')){//Owner is User       

                      lstUpdatedOwners.add(objCase);
                }
                if( (objCase.Case_Priority_Override__c != (mapOldCases.get(objCase.Id)).Case_Priority_Override__c
                    || objCase.Case_Priority_Override_Reason__c != (mapOldCases.get(objCase.Id)).Case_Priority_Override_Reason__c) 
                   && objCase.Case_Priority_Override__c
                   && objCase.Case_Priority_Override_Reason__c != NULL
                   && objCase.Priority != 'Critical'){  //ERS Cases with Priority Override, which are not already critical
                        
                       lstCases_UpdateToCritical.add(objCase);
                }
                
                if( ((objCase.ACG_Vehicle_Location_Type__c != (mapOldCases.get(objCase.Id)).ACG_Vehicle_Location_Type__c)
                    || (objCase.ACG_Vehicle_Type__c != (mapOldCases.get(objCase.Id)).ACG_Vehicle_Type__c)
                    || (objCase.ERS_Event_Type__c != (mapOldCases.get(objCase.Id)).ERS_Event_Type__c)
                    || (objCase.AccountId != (mapOldCases.get(objCase.Id)).AccountId)
                    || (objCase.ACG_Service_Type__c != (mapOldCases.get(objCase.Id)).ACG_Service_Type__c)
                    || (objCase.Tow_Request_Reason__c != (mapOldCases.get(objCase.Id)).Tow_Request_Reason__c)
                    ) && objCase.Critical_Call_Reason__c == NULL)
                     // && !(objCase.AccountId != NULL && objCase.Account.ACG_VIP_Code__c != NULL)  //Exclude VIP cases from List (ERSBO-2663)
                {   //ERS Cases whose fields were updated
                       lstERSCasesToSetPriority.add(objCase);
                }
                              
               if((objCase.AccountId != (mapOldCases.get(objCase.Id)).AccountId)){     //Cases whose Member account is changed
                    lstCases_UpdatedAccount.add(objCase);
                    if(objCase.AccountId !=NULL ){
                        lstCaseWithUpdatedMember.add(objCase);
                        lstAccountId.add(objCase.AccountId); //ERSBO-2663
                    }
                }
                if( objCase.AccountId != (mapOldCases.get(objCase.Id)).AccountId){
                    lstCasesToSetMembershipLevel.add(objCase);
                }
                
                if( ((objCase.IsEscalated != (mapOldCases.get(objCase.Id)).IsEscalated && objCase.IsEscalated)
                  || (objCase.Status != (mapOldCases.get(objCase.Id)).Status && objCase.Status == 'Escalated'))
                  && !objCase.VIP_Case__c){ //If case was escalated and not a VIP
                      lst_Escalated_Cases.add(objCase);
                  }

                if((objCase.AccountId != (mapOldCases.get(objCase.Id)).AccountId) || (objCase.ACG_Case_Contact_Number__c != (mapOldCases.get(objCase.Id)).ACG_Case_Contact_Number__c)){     //Cases whose Member account is changed
                    system.debug('**********'+objCase);
                    lstCaseWithUpdatedAccountMember.add(objCase);                    
                }

                // Get Timezone from Member Breakdown Location
                if( (objCase.Vehicle_Geolocation__Latitude__s != (mapOldCases.get(objCase.Id)).Vehicle_Geolocation__Latitude__s
                || objCase.Vehicle_Geolocation__Longitude__s != (mapOldCases.get(objCase.Id)).Vehicle_Geolocation__Longitude__s)){
                    lstToGetMemberTimezone.add(objCase.Id);
                }
              }
        }
        
        /*Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, VIP__c FROM Account WHERE Id IN :lstAccountId]);
        for(Case objCase : lstAllERSCases) {
         //(ERSBO-2663) VIP Cases
                if( (objCase.AccountId != (mapOldCases.get(objCase.Id)).AccountId)      
                   && ( (objCase.AccountId != NULL && mapAccounts.containsKey(objCase.AccountId) && (mapAccounts.get(objCase.AccountId)).VIP__c )                   
                       || (mapOldCases.get(objCase.Id)).VIP_Case__c) ){ //If Member account was updated to VIP, or if the case was already a VIP    
                            
                           lst_VIP_Cases.add(objCase);
                   }
                
        }*/
        if(!lstToGetMemberTimezone.isEmpty()){
            System.enqueueJob(new INTGetMemberTimeZoneQueuable(lstToGetMemberTimezone));
            //ACG_CaseTriggerService.getTimezoneFromMemberLocation(lstToGetMemberTimezone);
        }
       
        //(ERSBO-2665)
        if(!lstUpdatedOwners.isEmpty()){
            ACG_CaseTriggerService.update_AgentClubName(lstUpdatedOwners);
        }
         if(!lst_Escalated_Cases.isEmpty()){
            ACG_CaseTriggerService.handle_Escalation(lst_Escalated_Cases);
        }
        if(!lstCaseWithUpdatedMember.isEmpty() || !lstCases_UpdatedAccount.isEmpty()){
            ACG_CaseTriggerService.updateCDXInfo(lstCases_UpdatedAccount, lstAccountId);
            ACG_CaseTriggerService.handleMultipleRequests(lstCaseWithUpdatedMember);
             ACG_CaseTriggerService.updateClubName(lstCases_UpdatedAccount);   //populate Club name from Account(ERSBO-362)
            
            
        }
        //Handle New/Old VIP cases (ERSBO-2663) 
         /*if(!lst_VIP_Cases.isEmpty()){
            ACG_CaseTriggerService.handleVIPCases(lst_VIP_Cases,mapAccounts);
        }*/
        //Update ERS Cases to 'In Progress' status when first update occurs. (ERSBO-282)        
        
        //Trung update comment out
        /*
        if(!lstAllERSCases.isEmpty()){
           ACG_CaseTriggerService.updateStatus( lstAllERSCases, (Map<Id, Case>)oldItems);
           //ERSBO-2958
           ACG_CaseTriggerService.updateOverMiles(lstAllERSCases, (Map<Id, Case>)oldItems); 
        }
          
        //Populate the Household the Case is associated with. 
        if(!lstAllERSCases.isEmpty()){
            //ACG_CaseTriggerService.populateHouseholdName(lstAllERSCases,(Map<Id,Case>)oldItems);
            ACG_CaseTriggerService.updateAllotedMiles(lstAllERSCases,(Map<Id,Case>)oldItems);
            }
         */   
          
        if(!lstCaseWithUpdatedAccountMember.isEmpty()){
            system.debug('*********'+lstCaseWithUpdatedAccountMember);
            ACG_CaseTriggerService.updateSMSOptIn(lstCaseWithUpdatedAccountMember);     //Populate the SMS Opt-In from Account (ERSBO-1753)
            }
        if(!lstCasesToSetMembershipLevel.isEmpty()){
            ACG_CaseTriggerService.updateMembership(lstCasesToSetMembershipLevel); 
        }

        //Handle VIP Cases (ERSBO-2663)
        if(!lst_VIP_Cases.isEmpty()){
            ACG_CaseTriggerService.updatePriorityToCritical(lst_VIP_Cases);
        }
        //Set Case Priority (ERSBO-2663)
        if(!lstCases_UpdateToCritical.isEmpty()){
            ACG_CaseTriggerService.updatePriorityToCritical(lstCases_UpdateToCritical);
        }

        
        //Populate the Case Priority. (ERSBO-1071)
        //if(!lstERSCasesToSetPriority.isEmpty()){
        //    ACG_CaseTriggerService.updateCasePriority(lstERSCasesToSetPriority);}     //VBR - Don't change Priority when the member is selected in Triage
        
       
        /*ACG_CaseTriggerService.validateCaseStatus(mapNewCases.Values(),mapOldCases);
        List<Case> approvedCallAdjustmentList = new List<Case>(); 
        Id callAdjustmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Call Adjustment').getRecordTypeId();
        for(Id eachCaseId : mapNewCases.keySet()){
            if(String.isNotBlank(mapNewCases.get(eachCaseId).RecordTypeId) && mapNewCases.get(eachCaseId).RecordTypeId.equals(callAdjustmentRecordTypeId) 
               && String.isNotBlank(mapOldCases.get(eachCaseId).Status) && (mapOldCases.get(eachCaseId).Status.equals('Pending'))
               && (mapNewCases.get(eachCaseId).Status.equals('Approved') 
                   || mapNewCases.get(eachCaseId).Status.equals('Partially Approved'))
              ){
                  mapNewCases.get(eachCaseId).Status = 'Payment Processing';
                  approvedCallAdjustmentList.add(mapNewCases.get(eachCaseId));
            }
        }
        if(!approvedCallAdjustmentList.isEmpty()){
            ACG_CaseTriggerService.createPaymentForApprovedCallAdjustments(approvedCallAdjustmentList);
        }*/
      
    }
    
    //Handler Method for Before Delete.    
    public void beforeDelete(Map<Id, sObject> oldItems) {
               
    }
    //Handler method for After Insert.
    public void afterInsert(Map<Id, sObject> newItems) {
        List<Case> lst_VIP_ERS_Cases = new List<Case>();
        List<Case> lst_ERS_EscalatedCases = new List<Case>(); 
        Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
       
        for(Case objCase : (List<Case>)newItems.values() ){
            if(objCase.RecordTypeId == ERSRecordTypeId){
                if(objCase.VIP_Case__c) { //For ERS Cases
                    lst_VIP_ERS_Cases.add(objCase);    
                }
                if(objCase.IsEscalated){
                    //handle Escalations
                }
            }
        }
        
        if(!lst_VIP_ERS_Cases.isEmpty()){
            ACG_CaseTriggerService.handle_VIP_Escalation(lst_VIP_ERS_Cases);
        }
    }
    
    //Handler method for After Update.    
     public void afterUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems) {
        Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
        Map<Id,Case> mapERSCases = new Map<Id,Case>();
        Map<Id,Case> mapOldCases = (Map<Id,Case>)oldItems;
         List<Case> lst_VIP_Cases = new List<Case>();
         List<Id> lstBreakdownLocationChanged = new List<Id>();
         List<Id> lstTowLocationChanged = new List<Id>();
         List<Case> lstToNotifyRepairShop = new List<Case>(); 
         List<Case> lst_Escalated_Cases = new List<Case>();
        for(Case objCase :(List<Case>)newItems.values()) {
          if(objCase.RecordTypeId == ERSRecordTypeId ){
               Case oldCase = mapOldCases.get(objCase.Id);
               if( (oldCase.Vehicle_Location_Street__c != null) 
                        &&  (objCase.Vehicle_Location_Street__c != oldCase.Vehicle_Location_Street__c
                            || objCase.Vehicle_Location_State__c !=oldCase.Vehicle_Location_State__c
                            || objCase.Vehicle_Location_City__c !=oldCase.Vehicle_Location_City__c
                            || objCase.Vehicle_Location_Country__c !=oldCase.Vehicle_Location_Country__c
                            || objCase.Vehicle_Location_Postal_Code__c !=oldCase.Vehicle_Location_Postal_Code__c
                            )  
                 )
                   {
                     mapERSCases.put(objCase.Id, objCase);
                     lstBreakdownLocationChanged.add(objCase.Id);
                   }

                if( (oldCase.Tow_Destination_Street__c != null )
                        && 
                        (   objCase.Tow_Destination_Street__c != oldCase.Tow_Destination_Street__c 
                            || objCase.Tow_Destination_City__c != oldCase.Tow_Destination_City__c 
                            || objCase.Tow_Destination_State__c != oldCase.Tow_Destination_State__c 
                            || objCase.Tow_Destination_Country__c != oldCase.Tow_Destination_Country__c 
                            || objCase.Tow_Destination_Postal_Code__c != oldCase.Tow_Destination_Postal_Code__c      
                        ) //|| objCase.Repair_Shop__c != oldCase.Repair_Shop__c
                )
                   {
                    if(!mapERSCases.containsKey(objCase.Id)){
                        mapERSCases.put(objCase.Id, objCase);
                    } 
                     lstTowLocationChanged.add(objCase.Id);
                   }

                if( objCase.ACG_Case_Contact_Number__c != oldCase.ACG_Case_Contact_Number__c
                  || objCase.Critical_Call_Reason__c !=oldCase.Critical_Call_Reason__c
                  || objCase.Use_your_long_tow_entitlement__c !=oldCase.Use_your_long_tow_entitlement__c
                  || objCase.Vehicle_Geolocation__Latitude__s !=oldCase.Vehicle_Geolocation__Latitude__s
                  || objCase.Vehicle_Geolocation__Longitude__s != oldCase.Vehicle_Geolocation__Longitude__s
                  || objCase.Tow_Geolocation__Latitude__s !=oldCase.Tow_Geolocation__Latitude__s
                  || objCase.Tow_Geolocation__Longitude__s != oldCase.Tow_Geolocation__Longitude__s
                )
                   {
                    if(!mapERSCases.containsKey(objCase.Id)){
                        mapERSCases.put(objCase.Id, objCase);
                    } 
                   }

                if(((objCase.Tow_Geolocation__Latitude__s != oldCase.Tow_Geolocation__Latitude__s || objCase.Tow_Geolocation__Longitude__s != oldCase.Tow_Geolocation__Longitude__s) 
                    && (objCase.Repair_Shop__c != null)) 
                    || (objCase.Repair_Shop__c == null && oldCase.Repair_Shop__c != null))
                {
                    lstToNotifyRepairShop.add(objCase);
                }

              if(objCase.VIP_Case__c != (mapOldCases.get(objCase.Id)).VIP_Case__c
                && objCase.VIP_Case__c){
                  lst_VIP_Cases.add(objCase);
              }
          }
        }
         
        if(!lst_VIP_Cases.isEmpty()){
             ACG_CaseTriggerService.handle_VIP_Escalation(lst_VIP_Cases);
        }

        if(!lstBreakdownLocationChanged.isEmpty()){
            ACG_CaseTriggerService.handle_Breakdown_Location_Changes(lstBreakdownLocationChanged);
        }

        if(!lstTowLocationChanged.isEmpty()){
            ACG_CaseTriggerService.handle_Tow_Location_Changes(lstTowLocationChanged);
        }

        if(!lstToNotifyRepairShop.isEmpty()){
            ACG_CaseTriggerService.notifyRepairShopUpdate(lstToNotifyRepairShop);
        }
          
         //Fetch Updated Lat/Long - Google APIs
        /*for(Case objCase :(List<Case>)newItems.values()) {
             if(objCase.RecordTypeId == ERSRecordTypeId ){
                 Case oldCase = mapOldCases.get(objCase.Id);
                 system.debug('******* repair shop available' + System.label.RepairShopFunctionality + objCase.Repair_Shop__c + oldCase.Repair_Shop__c);
                 if(objCase.Repair_Shop__c !=oldCase.Repair_Shop__c){
                     system.debug('******* repair shop available has changed');
                     if(objCase.Repair_Shop__c != null){
                         if(System.label.RepairShopFunctionality == 'TRUE'){
                             system.debug('******* fire api');
                             FSL_INTRepairShopOutbound.generateRepairShopRequest(objCase.Id,objCase.FSL_Work_Order__c);
                         }
                     }
                 }
             }
        }*/
         
         
        //Update corresponding Work order fields 
        ACG_CaseTriggerService.updateWorkOrderValues(mapERSCases);
    }
    
    //Handler method for After Delete    
    public void afterDelete(Map<Id, sObject> oldItems) {
    
    }

    //Handler method for After Undelete.
    public void afterUndelete(Map<Id, sObject> oldItems) {
    }   
}