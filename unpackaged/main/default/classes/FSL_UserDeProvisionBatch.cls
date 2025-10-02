/*
*********************************************************************************************************
Class         :  FSL_UserDeProvisionBatch.cls
Developer     :  Rajesh Kemisetti
Created      :  Nov , 2019
Objective    :  
*********************************************************************************************************
*/

global class FSL_UserDeProvisionBatch implements Database.Batchable<sObject>, Database.Stateful {
    
   
    global final String queryString;
    global List<String> errorList;
    global Integer totalProcessed;
    global Integer saveCounter;
    global FSL_UserDeProvisionBatch()
    {    
       errorList = new List<String>();   
    }
    
    global FSL_UserDeProvisionBatch(string q)
    {
        errorList = new List<String>();
        queryString = q;

    }
    
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        saveCounter = 0;
        totalProcessed = 0;
        
        DateTime dt = System.Now()-Integer.ValueOf(Label.FSL_DAYS_FROM_LAST_LOGIN);
        
        //[Step 1 - Get All the Line Tier Records]
          if(queryString == NULL){

            list<string> deactiveProfiles = new list<string>();
            for(FSL_Deactivate_Profile__mdt deactiveProfile : [select Profile__c from FSL_Deactivate_Profile__mdt]){
                deactiveProfiles.add(deactiveProfile.Profile__c);
            }  

            list<Id> profileIds = new list<Id>();
            for(Profile profile : [select id from profile where name in :deactiveProfiles ]){
                profileIds.add(profile.id);
            }
            
            return Database.getQueryLocator([Select id, Name, IsActive, LastLoginDate, EmployeeNumber, 
                                                    profile.Name, IsPortalEnabled, email 
                                               from User 
                                               where IsActive=true and 
                                                     ProfileId IN :profileIds and 
                                                    lastlogindate < :dt ]); 
        }else{
            return Database.getQueryLocator(queryString);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<User> scope){
        
        try
        {          
            //create the case list
            list<Case> cases = new list<Case>();               
            //map for linking the user and the service resource
            map<string, string> userResourcesMap = new map<string, string>();//map<userid,serviceresourceid>
            
            list<Group> approversQueue = [select Id,name from Group where Type = 'Queue' AND DeveloperNAME = 'FSL_User_De_Provisioning_Approvers'];
            //query the active service resources based on the user scope
            for(ServiceResource sr : [select id, RelatedRecordId 
                                        from ServiceResource 
                                       where RelatedRecordId IN :scope AND 
                                             IsActive = true]){
                userResourcesMap.put(sr.RelatedRecordId, sr.id);
            }
            
            /*Start Logic for determining the approver for the request*/
            map<ID, String>  userProfileMap = new map<ID, String>();
            for(User u : scope){
                userProfileMap.put(u.ID, u.profile.Name);    
            }
            
            //club territory
            string clubDispatchManager = '';
            for(ServiceTerritory st : [select FSL_Manager__c from ServiceTerritory where Name= :Label.FSL_Club_Territory]){
                clubDispatchManager = st.FSL_Manager__c;
            }

            //map<serviceresourceId, userTerriroty>
            map<ID, FSL__User_Territory__c> facilityDispatchUserMap = new map<ID, FSL__User_Territory__c>();
            for(FSL__User_Territory__c ut : [select id, FSL_Manager__c, FSL__User__c 
                                                from FSL__User_Territory__c 
                                               where FSL__User__c IN :userResourcesMap.keyset()])
            {
                facilityDispatchUserMap.put(ut.FSL__User__c, ut);
            }

            //map<serviceresourceId, STM>
            map<ID, ServiceTerritoryMember> technicianUserMap = new map<ID, ServiceTerritoryMember>();
            for(ServiceTerritoryMember stm : [select id, ServiceTerritory.FSL_Manager__c, ServiceResourceId,
                                                     ServiceResource.RelatedRecordId
                                                from ServiceTerritoryMember 
                                               where TerritoryType='P' AND 
                                                     FSL_Expired_Resource_Territory__c = FALSE AND 
                                                     EffectiveStartDate <= :system.now() AND 
                                                     ServiceResourceId IN :userResourcesMap.values()])
            {
                technicianUserMap.put(stm.ServiceResource.RelatedRecordId, stm);
            }
            /*End Logic for determining the approver for the request*/
            
            for(User user : scope)  
            {
                Case c          =   new Case();
                c.status        =   'New';
                c.origin        =   'Automation';
                c.recordtypeid  =   Schema.SObjectType.Case.getRecordTypeInfosByName().get('User De-Provisioning Request').getRecordTypeId();
                c.subject       =   'Automated De-Provisioning Case Created for '+user.Name;
                c.FSL_User__c   =   user.id;
                c.FSL_Email__c  =   user.Email;
                c.FSL_LastLoginDate__c =   user.lastlogindate;
                c.FSL_Employee_ID__c   =   user.EmployeeNumber;
                c.FSL_Service_Resource__c   =   userResourcesMap.containsKey(user.id) ? userResourcesMap.get(user.id) : null;
                c.ownerId       =   approversQueue!=null && approversQueue.size()>0 ? approversQueue[0].id : UserInfo.getUserId();
                /*Start Logic for determining the approver for the request*/
                if(userProfileMap.containsKey(user.id)){
                    if(userProfileMap.get(user.id).equalsIgnoreCase('FSL Facility Dispatcher (Fleet)') ||
                       userProfileMap.get(user.id).equalsIgnoreCase('FSL Contractor Dispatcher Access')
                      )
                    {
                        c.FSL_Manager__c=   facilityDispatchUserMap.containsKey(user.id) ? 
                                                        facilityDispatchUserMap.get(user.id).FSL_Manager__c : 
                                                        null;
                    }else if(userProfileMap.get(user.id).equalsIgnoreCase('FSL Mobile (Fleet Technician)') ||
                             userProfileMap.get(user.id).equalsIgnoreCase('FSL Contractor Technician Access')
                            )
                    {
                        c.FSL_Manager__c=   technicianUserMap.containsKey(user.id) ? 
                                                        technicianUserMap.get(user.id).ServiceTerritory.FSL_Manager__c : 
                                                        null;
                    }else if(userProfileMap.get(user.id).equalsIgnoreCase('FSL Club Dispatchers')){
                        c.FSL_Manager__c=   !string.isEmpty(clubDispatchManager) ? clubDispatchManager : null;
                    }
                    if(c.FSL_Manager__c!=null)  
                        c.ownerId       =   c.FSL_Manager__c;                    
                }
                /*End Logic for determining the approver for the request*/
                cases.add(c);
            }
            system.debug('Cases to Add: '+cases.size());
            if(cases.size() > 0)
            {
                Database.SaveResult[] caseList = Database.insert(cases, false);
                system.debug('totalProcessed:'+totalProcessed);
                totalProcessed += cases.size() ;
                for (Database.SaveResult sr : caseList) {
                    if (sr.isSuccess()) {
                        saveCounter++;
                        
                    }
                    else{
                        system.debug('Save result failed :'+sr);
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.'+err.getMessage()+' and StatusCode :'+err.getStatusCode());                    
                            errorList.add(err.getStatusCode() + ': ' + err.getMessage());
                        }    
                    }
                }                
            }
        } 
        catch (DmlException e) {
            // Process exception here
            system.debug(e.getMessage()+' '+ e.getLineNumber());
        } 
        catch(Exception e)
        {
            errorList.add(e.getMessage()  + '\n' + string.valueof(e.getLineNumber()) + '\n' + e.getStackTraceString());
            InsertLogData();
        }
    }  
    
    global void finish(Database.BatchableContext BC){       
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        //String body;
        InsertLogData();
        
        
       
        //UtilityClasses.sendEmailFrmBatchJob('E2E Cumulative % Calculation Job', body);
    }
    
    public  void InsertLogData()
    {
         string body =  'Total Records Processed : '+ totalProcessed + '\r\n Successes : ' + saveCounter + '\r\n Errors : ' + errorList.size() ;
        if(!errorList.isEmpty())
        {
            body = body +'\r\n\nBelow are errors occurred:-';
            for(String err : errorList)
            {
                body = body +'\r\n'+err;
            }
        }
        
        FSL_Application_Log__c AppLog =  new FSL_Application_Log__c();
        AppLog.Response_Body__c = body;
        AppLog.API_Name__c = 'FSL_UserDeProvisionBatch';        
        insert AppLog;
        
    }
}