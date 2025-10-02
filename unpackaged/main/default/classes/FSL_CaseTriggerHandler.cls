/**
 * @File Name          : FSL_CaseTriggerHandler.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 12-01-2022
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    11/05/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 *        09/21/2020   Josh Lovejoy - Change permission to allow Cases to create a facility disptacher
**/
public class FSL_CaseTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<Case> newList = Trigger.new;
    List<Case> oldList = Trigger.old;
    Map<Id, Case> newMap = (Map<Id, Case>)Trigger.newMap;
    Map<Id, Case> oldMap = (Map<Id, Case>)Trigger.oldMap;

    ID provisioningRequest = Schema.SObjectType.CASE.getRecordTypeInfosByName().get('User Provisioning Request').getRecordTypeId();
    ID deprovisioningRequest = Schema.SObjectType.Case.getRecordTypeInfosByName().get('User De-Provisioning Request').getRecordTypeId();

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Case');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        List<Case> newUserRequests = new List<Case>();
        list<Group> approversQueue = [select Id,name from Group where Type = 'Queue' AND DeveloperNAME = 'FSL_User_De_Provisioning_Approvers'];
        for(Case cs : newList){
            if(cs.RecordTypeId == provisioningRequest){
                newUserRequests.add(cs);
            }else if(cs.RecordTypeId == deprovisioningRequest){
                if(!System.isBatch()){
                    cs.ownerId  =   approversQueue!=null && approversQueue.size()>0 ? approversQueue[0].id : UserInfo.getUserId();
                }
            }
            
        }
        
        if(!newUserRequests.isEmpty()){
            FSL_CaseTriggerHandler.validateUserProvisioningRequest(newUserRequests);
        }
    }

    //========================================================================================================================
    public override void beforeUpdate() {        
    }
    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        List<Case> userRequests = new List<Case>();
        List<Case> userDeProvRequests = new List<Case>();
        
        for(Case cs : newList){                
            if(cs.RecordTypeId == provisioningRequest){
                userRequests.add(cs);
            }else if(cs.RecordTypeId == deprovisioningRequest && cs.Origin.equalsignorecase('OnDemand')){                    
                userDeProvRequests.add(cs);
            }
        }
        if(!userDeProvRequests.isEmpty()){
            FSL_CaseTriggerHandler.handleUserDeProvisioningRequest(userDeProvRequests);
        }
        if(!userRequests.isEmpty()){
            FSL_CaseTriggerHandler.handleUserProvisioningRequest(userRequests);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() { 
        // check if this is a user de-provisioning request
        List<Case> userRequests = new List<Case>();
        for(Case cs : newList){
            if(cs.RecordTypeId == deprovisioningRequest && 
                !string.isEmpty(cs.FSL_Approval_Status__c) && 
                cs.FSL_Approval_Status__c.equals('Approved') && 
                cs.Origin.equalsignorecase('Automation')
                )
            {
                userRequests.add(cs);
            }
        }
        
        if(!userRequests.isEmpty()){
            FSL_CaseTriggerHandler.handleUserDeProvisioningRequest(userRequests);
        }
    }
 
    @Future
    public static void handleUserdeactivation(map<ID,ID> userIds){
        list<User> users = new list<User>();
        for(User   user :  [SELECT id, isActive
                            FROM   User 
                            WHERE  id IN :userIds.keySet()])
        {
            user.isActive = false;           
            users.add(user);
        }
        if(users.size()>0){
            Database.SaveResult[] userList = Database.update(users, false);
            for (Database.SaveResult sr : userList) {
                if (!sr.isSuccess()){ 
                    system.debug('Save result failed :'+sr);
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.'+err.getMessage()+' and StatusCode :'+err.getStatusCode());                    
                    }    
                }
            }            
        }        
    }

    public static void handleUserDeProvisioningRequest(List<Case> userRequests){
        try{        
            map<Id, Id> userIds    =   new map<Id, Id>();//Map<UserId, CaseId>
            list<Id> resourceIds=   new list<Id>();
            list<SObject> recordstoUpdate =  new list<SObject>();
            list<SObject> recordstoDelete =  new list<SObject>();

            for(Case cs : userRequests){
                if(cs.FSL_User__c!=null){
                    userIds.put(cs.FSL_User__c,cs.id);
                }
                if(cs.FSL_Service_Resource__c!=null){
                    resourceIds.add(cs.FSL_Service_Resource__c);
                }            
            }
            
            //For OnDemand de provising if the user has not privided the service resource, 
            //below code will automatically retrieve the resource related to the user and deactivate the service resource.
            if(resourceIds.size()==0){
                for(ServiceResource sr : [select id, RelatedRecordId from ServiceResource where RelatedRecordId IN :userIds.keySet() and IsActive = true]){
                        resourceIds.add(sr.id);
                }
            }
            //If the service resource is not available for the deactivated user then do not execute the below logic which is highly unlikely
            if(resourceIds!=null && resourceIds.size()>0){
                list<ServiceResource> resources = new list<ServiceResource>();
                for(ServiceResource   resource :  [select id, isActive
                                                    from ServiceResource 
                                                    where id IN :resourceIds])
                {
                    resource.isActive   =   false;
                    resources.add(resource);
                }
                //Update ServiceResuurce as inactive
                recordstoUpdate.addAll(resources);

                list<ServiceTerritoryMember> stmlist = [select id, OperatingHoursId from ServiceTerritoryMember where ServiceResourceId IN: resources];
                list<ID> opHrsIds       =   new list<ID>();
                for(ServiceTerritoryMember stm : stmlist){
                    opHrsIds.add(stm.OperatingHoursId);
                }
                if(stmlist.size()>0){
                    recordstoDelete.addAll(stmlist);
                }

                list<OperatingHours> opHourList = [select id from OperatingHours where ID IN :opHrsIds];        
                if(opHourList.size()>0){
                    recordstoDelete.addAll(opHourList);
                }
            }
            //To avoid MIXED_DML_OPERATION issue making a future call for user updates
            FSL_CaseTriggerHandler.handleUserdeactivation(userIds);

            //Delete the child records related to user and ServiceResource
            list<FSL__User_Territory__c> userTerrList = [select id from FSL__User_Territory__c where FSL__User__c IN :userIds.keySet()];
            if(userTerrList.size()>0){
                recordstoDelete.addAll(userTerrList);
            }
            
            update recordstoUpdate;
            delete recordstoDelete;
        }catch(exception e){
           // system.debug('Exception Caught: ' + e);
           throw e;
        }finally{
            list<Case> cases = new list<Case>();
            for(Case c : [select id,status from Case where ID IN :userRequests AND Status <> 'Closed']){
                c.Status    =   'Closed';
                c.ownerID   =   UserInfo.getUserId();
                cases.add(c);
            }
            if(cases.size()>0){
                update cases;
            }        
        }
    }
    
    public static void handleUserProvisioningRequest(List<Case> userRequests){ 
        try{
            List<User> newUsersList = new List<User>();
            List<Contact> newContactsList = new List<Contact>();
            List<FSL_Audio_Preferences__c> aPrefList = new List <FSL_Audio_Preferences__c>();
            List<ServiceResource> newResourcesList = new List<ServiceResource>();
            List<OperatingHours> newOperatingHoursList = new List<OperatingHours>();
            List<ServiceTerritoryMember> newSTMList = new List<ServiceTerritoryMember>();
            List<FSL__User_Territory__c> newUserTerritoryList = new List<FSL__User_Territory__c>();
            Map<String,Case> userNameCaseMap = new Map<String,Case>();
            Map<String, Profile> typeToProfileMap = new Map<String, Profile>();
            List<User> usersToActivate = new List<User>();         
            List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name LIKE '%FSL%'];
            typeToProfileMap = createProfileMap(profileList);
            Map<String,User> createdUsersMap = new Map<String,User>();
            
            Set<Id> territoryIdSet = new Set<Id>();
            Map<Id,ServiceTerritory> territoryIdMap = new Map<Id,ServiceTerritory>();
            Set<Id> userIdSet = new Set<Id>();
            Map<String,ServiceResource> userIdSRMap = new Map<String,ServiceResource>();
            List<ServiceResource> srActivationList = new List<ServiceResource>();
            Map<Id,Account> accountPTerritoryMap = new Map<Id,Account>();
            for(Case cs : userRequests){ 
                if(cs.FSL_Primary_Service_Territory__c != null) {
                    territoryIdSet.add(cs.FSL_Primary_Service_Territory__c);
                }
                if(cs.FSL_Re_Activate__c == true) {
                    userIdSet.add(cs.FSL_User_Id__c);
                }                                               
            }
            if(!territoryIdSet.isEmpty()) {
                territoryIdMap = new Map<Id,ServiceTerritory>([Select Id,OperatingHours.Id,OperatingHours.TimeZone from ServiceTerritory where Id IN :territoryIdSet ]);
                for(Account acc : [SELECT id, Name,Service_Territory__c FROM Account WHERE Service_Territory__c = :territoryIdSet  ]){
                    accountPTerritoryMap.put(acc.Service_Territory__c,acc);
                }
            }
            if(!userIdSet.isEmpty()) {
                for(ServiceResource sr : [Select Id,RelatedRecordId,IsActive from ServiceResource where RelatedRecordId IN : userIdSet]) {
                    String srId = sr.RelatedRecordId;
                    srId = srId.substring(0,15);
                    userIdSRMap.put(srId,sr);
                }
            }
            List<ServiceTerritory> prentTerritoriesList = [Select Id from ServiceTerritory where ParentTerritoryId = null];
            Organization myOrg = [Select o.Name From Organization o];
            for(Case cs : userRequests){
                String externalUserID = createExternalUserID(cs, myOrg);
                User user_ref = new User(External_Id__c = externalUserID);
                if(cs.FSL_Re_Activate__c == false) {
                    userNameCaseMap.put(cs.FSL_Username__c,cs);
                    User usr = createUser(cs, typeToProfileMap,territoryIdMap,myOrg, externalUserID);                                  
                    if(cs.FSL_Contractor__c){
                        Contact con_ref = new Contact(External_Id__c = externalUserID); 
                        Contact con = createContact(cs,externalUserID,accountPTerritoryMap);
                        usr.Contact = con_ref;
                        //ERS-230874 Glympse Removal - Part I
                        //usr.Glympse_EnRoute__Glympse_EnRoute_Enabled__c =true;
                        //system.debug('==========usr.Glympse_EnRoute__Glympse_EnRoute_Enabled__c'+usr.Glympse_EnRoute__Glympse_EnRoute_Enabled__c) ;    
                        newContactsList.add(con);
                    }
                    newUsersList.add(usr);
                }else {
                    usersToActivate.add(new User(Id=cs.FSL_User_Id__c,ISACTIVE = true));
                }
                //Create Audio Preferences by default for UserProvisions .
                //String externalUserID = createExternalUserID(cs, myOrg);
                //User user_ref_2 = new User(External_Id__c = externalUserID);
                if(cs.FSL_Profile__c.contains('Dispatcher') && !cs.FSL_Profile__c.contains('Club')){
                    //User usr = createUser(cs, typeToProfileMap,territoryIdMap,myOrg, externalUserID);  
                    FSL_Audio_Preferences__c fap = new FSL_Audio_Preferences__c();
                        fap.User__r = user_ref;
                        fap.Notification_on_Cancellation__c = true;
                        fap.Notifications_on_New_Call__c = true;
                        fap.Time_Interval_In_Seconds__c = Decimal.ValueOf(System.Label.FSL_Audio_Time_Interval);
                        aPrefList.add(fap); 
                        system.debug('============'+aPrefList.size());
                }    
                // create operating hours, service resource and STMs for Technicians
                if(cs.FSL_Profile__c == 'Technician'){
                    String ophName = cs.FSL_Employee_ID__c + ' - ' + cs.FSL_First_Name__c + ' ' +  cs.FSL_Last_Name__c+' Schedule';
                    OperatingHours operatingHours_ref = new OperatingHours(External_Id__c = ophName);
                    OperatingHours operatingHours = createOperatingHours(ophName,territoryIdMap.get(cs.FSL_Primary_Service_Territory__c).operatingHours.timeZone);
                    newOperatingHoursList.add(operatingHours);
                    
                    ServiceResource resource_ref = new ServiceResource(External_Id__c = externalUserID);
                    if(cs.FSL_Re_Activate__c == false) {
                        ServiceResource resource = createServiceResource(cs, user_ref);
                        newResourcesList.add(resource);
                    }else {
                        //System.debug('userIdSRMap====>'+userIdSRMap);
                        //System.debug('cs.FSL_User_Id__c====>'+cs.FSL_User_Id__c);
                        if(userIdSRMap.get(cs.FSL_User_Id__c) != null) {
                            resource_ref = userIdSRMap.get(cs.FSL_User_Id__c);
                            //resource_ref.IsActive = true;
                            //srActivationList.add(resource_ref);
                        } 
                        
                    }
                                 
                    //System.debug('resource_ref=====>'+resource_ref);
                    ServiceTerritoryMember stm = createServiceTerritoryMembers(cs, resource_ref, operatingHours_ref);
                    newSTMList.add(stm);
                    
                    FSL__User_Territory__c ut = createUserTerritory(cs, user_ref);
                    newUserTerritoryList.add(ut);                    
                }
                //Create User territory records for Admin with Territories having No Parent Territory
                else if(cs.FSL_Profile__c.contains('Admin') || cs.FSL_Profile__c.contains('Club Dispatcher') ) {
                    for(ServiceTerritory st : prentTerritoriesList) {
                        FSL__User_Territory__c ut = new FSL__User_Territory__c();
                        ut.FSL__ServiceTerritory__c = st.Id;
                        //ut.FSL__User__c = usr.Id;
                        if(cs.FSL_Re_Activate__c == true) {
                            ut.FSL__User__c = cs.FSL_User_Id__c;
                        }else {
                            ut.FSL__User__r = user_ref;
                        }
                        newUserTerritoryList.add(ut); 
                    }                    
                }
                // create User Territories for Dispatchers
                else if(cs.FSL_Profile__c.contains('Dispatcher')){
                    FSL__User_Territory__c ut = createUserTerritory(cs, user_ref);
                    newUserTerritoryList.add(ut);
                }
                
            
            }
            List<SObject> userWithSRsList = new List<SObject>();
            // Handle Insert Methods
            if(!newContactsList.isEmpty()){
                //insert newContactsList;
                userWithSRsList.addAll(newContactsList);
            }
            if(!newUsersList.isEmpty() ){
                //insert newUsersList;
                userWithSRsList.addAll(newUsersList);
            }           
            
            /*if(!srActivationList.isEmpty()) {
                update srActivationList;
            }*/
            if(!newResourcesList.isEmpty()){
                userWithSRsList.addAll(newResourcesList);
            }  
            System.debug('opHours====>'+newOperatingHoursList);
            if(!newOperatingHoursList.isEmpty()){
                userWithSRsList.addAll(newOperatingHoursList);
            }
            if(!newSTMList.isEmpty()){
                userWithSRsList.addAll(newSTMList);
            }
            if(!newUserTerritoryList.isEmpty()){
                userWithSRsList.addAll(newUserTerritoryList);
            }
            if(!aPrefList.isEmpty()){
                userWithSRsList.addAll(aPrefList);
            }

            //Activating the users before creating child records
            if(!usersToActivate.isEmpty()) {
                ActivateUsersQueueble activateQueueble = new ActivateUsersQueueble(usersToActivate,userWithSRsList);
                System.enqueueJob(activateQueueble);
               //update usersToActivate;
            }
            if(!userWithSRsList.isEmpty() && usersToActivate.isEmpty()) {
                system.debug('userWithSRsList:'+userWithSRsList);
                insert userWithSRsList;
            }
            //*  Needs to go in future method (record is read-only error)
            //Updating Cases with userId
           
            
            updatecases(json.serialize(newUsersList),JSON.serialize(userNameCaseMap));
            assignPermissionSets(json.serialize(newUsersList),JSON.serialize(userNameCaseMap));
            activateUsersWithMail(json.serialize(newUsersList)); 
            //GlympseUseractivateWithMail(json.serialize(newUsersList));
            //EnableGlympseTechnicianQueue queue = new EnableGlympseTechnicianQueue(usersToActivate);           
            //UpdateServiceResources(json.serialize(newUsersList)); 
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            throw e;
        }
        
    }
    
    @Future
    public static void activateUsersWithMail(String usersString) {
        List<User> usersListNew = (List<User>)JSON.deserialize(usersString,List<User>.class);
        /*Database.DMLOptions dmo = new Database.DMLOptions(); // this didnt make any difference
        dmo.EmailHeader.triggerUserEmail = true;
        for(User u : usersListNew) {
            u.setOptions(dmo);  // this didnt make any difference, could remove it
            u.IsActive = TRUE;
            
        }
        Database.update(usersListNew,dmo);*/
        for(User u : usersListNew) {
            System.resetPassword(u.Id,TRUE);                    
        }
        
        //ERS-230874 Glympse Removal - Part I
        //EnableGlympseTechnicianQueue queuee = new EnableGlympseTechnicianQueue(usersListNew);
        //System.enqueuejob(queuee);
    }   
    public class ActivateUsersQueueble implements Queueable {
        List<User> usersToActivate;
        List<SObject> userWithSTMsList;
        public ActivateUsersQueueble(List<User> usersToActivate,List<SObject> userWithSTMsList) { 
            this.usersToActivate = usersToActivate;
            this.userWithSTMsList = userWithSTMsList;
        }
        public void execute(QueueableContext context) {
            if(!usersToActivate.isEmpty()) {
                update usersToActivate;
            }
            if(!userWithSTMsList.isEmpty()) {
                CreateChildRecordsQueueble childQueue = new CreateChildRecordsQueueble(userWithSTMsList);
                System.enqueueJob(childQueue);
            }                
        }
    }
    
    public class UpdateServiceResourceQueue implements Queueable {
       // List<User> usersToActivate;
        List<SObject> userWithSRsList;
        public UpdateServiceResourceQueue (List<SObject> userWithSRsList) { 
            //this.usersToActivate = usersToActivate;
            this.userWithSRsList= userWithSRsList;
        }
        public void execute(QueueableContext context) {
            //if(!usersToActivate.isEmpty()) {
                update userWithSRsList;
            //}
            
                
        }
    }
    //ERS-230874 Glympse Removal - Part I
    /*-----------------------------------------------------------------
    public class EnableGlympseTechnicianQueue implements Queueable {
        List<User> usersToActivate;
        List<SObject> userWithSRsList;
        public EnableGlympseTechnicianQueue (List<User> usersToActivate) { 
            this.usersToActivate = usersToActivate;
           
        }
        public void execute(QueueableContext context) {
            
            for(user u: usersToActivate){
                u.Glympse_EnRoute__Glympse_EnRoute_Enabled__c =true;        
               }
            
            if(!usersToActivate.isEmpty()) {
                update usersToActivate;
            }                
        }
    }
    -------------------------------------------------------------------*/

    public class CreateChildRecordsQueueble implements Queueable {
        List<SObject> userWithSTMsList;
        public CreateChildRecordsQueueble(List<SObject> userWithSTMsList) {
            this.userWithSTMsList = userWithSTMsList;
        }
        public void execute(QueueableContext context) {
                insert userWithSTMsList;
        }
    }
    @Future
    Public static void assignPermissionSets(String usersString,String userNameCaseMapStr){
        List<User> newUsersList = (List<User>)json.deserialize(usersString,list<User>.class);
        Map<String,Case> userNameCaseMap = (Map<String,Case>)JSON.deserialize(userNameCaseMapStr,Map<String,Case>.class);
        List<PermissionSetAssignment> permissionAssignList = new List<PermissionSetAssignment>(); 
        List<Id> technicianUsersList = new List<Id>();
        List<ServiceResource> srListToUpdate = new List<ServiceResource>();
        for(User usr : newUsersList ) {
            Case readOnlyCase = userNameCaseMap.get(usr.userName);
            if(readOnlyCase != null && readOnlyCase.FSL_Re_Activate__c == true){
                continue;
            }
            String pSetName = readOnlyCase.FSL_Contractor__c == true ? 'Contractor '+readOnlyCase.FSL_Profile__c : readOnlyCase.FSL_Profile__c;
  
            UP_Permission_Sets__c permissionSetCS = UP_Permission_Sets__c.getValues(pSetName);                       
            Map<String,PermissionSet> permissionSetMap = createPermissionSetMap();
            if(permissionSetCS.AppliedPermissionSet__c != null) {
                for(String appliedPSet : permissionSetCS.AppliedPermissionSet__c.split(',')) {
                    if(permissionSetMap.get(appliedPSet) != null) {
                        Schema.PermissionSetAssignment pAssignment = new Schema.PermissionSetAssignment();
                        pAssignment.AssigneeId = usr.Id;
                        pAssignment.PermissionSetId = permissionSetMap.get(appliedPSet).Id;
                        permissionAssignList.add(pAssignment);
                    }
                    
                }
            }
            if(readOnlyCase.FSL_Profile__c.contains('Technician')) {
                technicianUsersList.add(usr.Id);
            }
        }
        if(!permissionAssignList.isEmpty()) {
            insert permissionAssignList;
        }
        if(!technicianUsersList.isEmpty()) {
            for(ServiceResource srToUpdate : [Select Id,IsOptimizationCapable from ServiceResource where isActive=true AND IsOptimizationCapable = false AND relatedRecordId In : technicianUsersList]){
                srToUpdate.IsOptimizationCapable = true;
                srListToUpdate.add(srToUpdate);
            }
            if(!srListToUpdate.isEmpty()) {
                UpdateServiceResourceQueue UpdateServiceResourcequeue  = new UpdateServiceResourceQueue (srListToUpdate);
                System.enqueueJob(UpdateServiceResourcequeue);
               //update srListToUpdate;
            }
        }
    }
  
  /*@Future
  public static void UpdateServiceResources(String serviceResourceString) 
  {
     List<ServiceResource> newUsersList = (List<ServiceResource>)System.JSON.deserialize(serviceResourceString,list<ServiceResource>.class); 
      List<Id> technicianUsersList = new List<Id>();
      List<ServiceResource> srListToUpdate = new List<ServiceResource>();
       if(!technicianUsersList.isEmpty()) {
            for(ServiceResource srToUpdate : [Select Id,IsOptimizationCapable from ServiceResource where isActive=true AND IsOptimizationCapable = false AND relatedRecordId In : technicianUsersList]){
                srToUpdate.IsOptimizationCapable = true;
                srListToUpdate.add(srToUpdate);
            }
            if(!srListToUpdate.isEmpty()) {
               update srListToUpdate;
            }
        }  
        
   }*/
    
    @Future
    Public static void updateCases(String usersString,String userNameCaseMapStr){
        List<User> newUsersList = (List<User>)json.deserialize(usersString,list<User>.class);
        Map<String,Case> userNameCaseMap = (Map<String,Case>)JSON.deserialize(userNameCaseMapStr,Map<String,Case>.class);
        List<Case> caseList = new List<Case>();
        Map<String, String> permSetMap = new Map<String, String>();
        List<String> permSetList = new List<String>();
        //List<UP_Permission_Sets__c> permSets = UP_Permission_Sets__c.getAll().values();                
        for(User usr : newUsersList ) {
                //System.debug('======>'+u.Id);
                if(userNameCaseMap.get(usr.userName) != null) {
                    if(userNameCaseMap.get(usr.userName) != null && userNameCaseMap.get(usr.userName).FSL_Re_Activate__c){
                        continue;
                    }
                    Id csId = userNameCaseMap.get(usr.userName).Id;
                    Case cs = new Case(Id= csId);                   
                    cs.FSL_User__c = usr.Id;
                    caseList.add(cs);
                }
            }
            if(!caseList.isEmpty()) {
                update caseList;
                //updatecases(json.serialize(caseList));
            }
    }
   
    private static User createUser(Case cs, Map<String, Profile> typeToProfileMap,Map<Id,ServiceTerritory> territoryIdMap,Organization myOrg, String externalUserID) {
        try{
            User usr = new User();
            // defaults
            usr.LANGUAGELOCALEKEY = 'en_US';
            usr.EMAILENCODINGKEY = 'ISO-8859-1';
            usr.LOCALESIDKEY = 'en_US';
            usr.UserPreferencesDisableAllFeedsEmail = true;        
            
            // populate from case
            usr.firstName = cs.FSL_First_Name__c;
            usr.lastName = cs.FSL_Last_Name__c;
            usr.EmployeeNumber = cs.FSL_Employee_ID__c;
            usr.Email = cs.FSL_Email__c;
            usr.Phone = cs.FSL_Phone__c;
            
            //usr.username = usr.Email + '.' + myOrg.name.replace(' ', '');
            usr.username = cs.FSL_Username__c;
            
            usr.CommunityNickname = cs.FSL_Nickname__c != null ? cs.FSL_Nickname__c : cs.FSL_Employee_ID__c ;
            //usr.CommunityNickname = usr.firstName.substring(usr.firstName.length() - 2) + usr.lastName.substring(usr.firstName.length() - 2);
            //usr.alias = usr.firstName.substring(usr.firstName.length() - 2) + usr.lastName.substring(usr.firstName.length() - 2);
            //usr.alias = usr.firstName.substring(0,2) + usr.lastName.substring(0,2);
            usr.alias = cs.FSL_Alias__c != null ? cs.FSL_Alias__c : cs.FSL_Employee_ID__c;
            usr.external_Id__c = externalUserID;
            // time zone is pulled from selected territory
            //ServiceTerritory selectedPrimary = [SELECT id, OperatingHoursID, OperatingHours.TimeZone FROM ServiceTerritory WHERE id = :cs.FSL_Primary_Service_Territory__c];
            if(cs.Fsl_Profile__c == 'Admin' || cs.Fsl_Profile__c == 'Club Dispatcher') {
                usr.TimeZoneSidKey = [Select Id,TimeZoneSidKey FROM Organization].TimeZoneSidKey;
            }else {
                usr.TimeZoneSidKey = territoryIdMap.get(cs.FSL_Primary_Service_Territory__c).OperatingHours.TimeZone;
            }
                        
            // profile is pulled from case profile
            if(cs.FSL_Profile__c == 'Technician'){
                if(cs.FSL_Contractor__c){
                    usr.ProfileId = typeToProfileMap.get('Mobile Technician - Contractor').ID;
                }else{
                    usr.ProfileId = typeToProfileMap.get('Mobile Technician').ID;
                }
            }else if(cs.FSL_Profile__c == 'Dispatcher'){
                if(cs.FSL_Contractor__c){
                    usr.ProfileId = typeToProfileMap.get('Contractor Dispatcher').ID;
                }
            }
            else if(cs.FSL_Profile__c == 'Club Dispatcher'){
                usr.ProfileId = typeToProfileMap.get('Club Dispatcher').ID;
            }
            else if(cs.FSL_Profile__c == 'Admin'){
                usr.ProfileId = typeToProfileMap.get('Club Admin').ID;
            }
            else if(cs.FSL_Profile__c == 'Facility Dispatcher'){
                if(cs.FSL_Contractor__c){
                    usr.ProfileId = typeToProfileMap.get('Contractor Dispatcher').ID;                   
                }else{
                    usr.ProfileId = typeToProfileMap.get('Facility Dispatcher').ID;
                }               
            }     
            if(cs.FSL_Profile__c.contains('Club Dispatcher') || cs.FSL_Profile__c.contains('Admin')) {
                usr.UserPermissionsInteractionUser = true; 
            }
            // TODO: add process to set this as active        
            usr.ISACTIVE = true; 
            return usr;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }
    
    private static Contact createContact(Case cs,String externalUserID,Map<Id,Account> accountPTerritoryMap){
        try{
            ID communityUserTypeID = Schema.SObjectType.CONTACT.getRecordTypeInfosByName().get('Community User').getRecordTypeId();
            
            Contact con = new Contact();
            con.FirstName = cs.FSL_First_Name__c;
            con.LastName = cs.FSL_Last_Name__c;
            con.Email = cs.FSL_Email__c;
            con.Phone = cs.FSL_Phone__c;
            con.recordTypeId = communityUserTypeID;
            
            // Account ID is pulled from the primary facility Name
            //Account facilityAccount = [SELECT id, Name FROM Account WHERE Service_Territory__c = :cs.FSL_Primary_Service_Territory__c ];
            Account facilityAccount = null;
            if(accountPTerritoryMap != null && accountPTerritoryMap.get(cs.FSL_Primary_Service_Territory__c) != null) {
                facilityAccount = accountPTerritoryMap.get(cs.FSL_Primary_Service_Territory__c);
            }
            //facilityAccount = ?  : new Account();
            System.debug('======>'+facilityAccount);
            con.AccountId = facilityAccount.id;
            System.debug('======>'+facilityAccount.Id);
            con.External_Id__c = externalUserID;
            return con;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }

    private static ServiceTerritoryMember createServiceTerritoryMembers(Case cs, ServiceResource sr, OperatingHours opHours) {
        try{
            ServiceTerritoryMember stm = new ServiceTerritoryMember();
            //stm.ServiceResourceID = sr.ID;
            if(cs.FSL_Re_Activate__c == true) {
                stm.ServiceResourceId = sr.Id;
            }else {
                stm.ServiceResource = sr;
            }            
            //stm.OperatingHoursID = opHours.ID;
            stm.OperatingHours = opHours;
            stm.ServiceTerritoryID = cs.FSL_Primary_Service_Territory__c;
            stm.EffectiveStartDate = cs.FSL_Start_Date__c;
            stm.TerritoryType = 'P';
            
            return stm;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }

    private static FSL__User_Territory__c createUserTerritory(Case cs, User usr){
        try{
            FSL__User_Territory__c ut = new FSL__User_Territory__c();
            ut.FSL__ServiceTerritory__c = cs.FSL_Primary_Service_Territory__c;
            //ut.FSL__User__c = usr.Id;
            if(cs.FSL_Re_Activate__c == true) {
                ut.FSL__User__c = cs.FSL_User_Id__c;
            }else {
                ut.FSL__User__r = usr;
            }           
            
            return ut;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }    

    private static OperatingHours createOperatingHours(String name, String timeZone) { 
        try{
            OperatingHours opHours = new OperatingHours();
            opHours.Name = name;
            opHours.TimeZone = timeZone;
            opHours.External_Id__c = name;
            return opHours;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }
 
    private static ServiceResource createServiceResource(Case objCase, User usr) {
        try{
            ServiceResource sResource = new ServiceResource();
            sResource.Name = objCase.FSL_Employee_ID__c + ' - ' + objCase.FSL_First_Name__c + ' ' +  objCase.FSL_Last_Name__c;
            sResource.Driver_Id__c = objCase.FSL_Employee_ID__c;
            sResource.ResourceType = 'T';
            /*if(objCase.FSL_Profile__c.contains('Technician')) {
                sResource.IsOptimizationCapable = true;
            }*/
            
            if(objCase.FSL_Re_Activate__c == true) {
                sResource.RelatedRecordId = objCase.FSL_User_Id__c;
            }else {
                sResource.RelatedRecord = usr;
            }            
            sResource.External_Id__c = usr.External_Id__c;
            sResource.isActive = true;
            system.debug('service resource created: ' + sResource);
            
            return sResource;
        }catch(Exception e){
            system.debug('Exception Caught: ' + e);
            //return null;
            throw e;
        }
    }
    
    /*
     *  Create configurable map for assigning a profile from the Case Profile picklist
     */
   
    private static Map<String, Profile> createProfileMap(List<Profile> profileList){
        Map<String, Profile> typeToProfileMap = new Map<String, Profile>();
        // TODO: Remove hard-coded profile names
        for(Profile p : profileList){
            if(p.Name == 'FSL Mobile (Fleet Technician)'){
                typeToProfileMap.put('Mobile Technician', p);
            }
            if(p.Name == 'FSL Contractor Technician Access'){
                typeToProfileMap.put('Mobile Technician - Contractor', p);
            }
            if(p.Name == 'FSL Club Dispatcher'){
                typeToProfileMap.put('Club Dispatcher', p);
            }
            if(p.Name == 'FSL Facility Dispatcher (Fleet)'){
                typeToProfileMap.put('Facility Dispatcher', p);
            }
            if(p.Name == 'FSL Contractor Dispatcher Access'){
                typeToProfileMap.put('Contractor Dispatcher', p);
            }
            if(p.Name == 'FSL Club Administrator'){
                typeToProfileMap.put('Club Admin', p);
            }                                           
        }
        
        return typeToProfileMap;
    }

     private static String createExternalUserID(Case cs, Organization myOrg){
        String externalIDString = cs.FSL_Username__c + '.' + myOrg.name.replace(' ', '');
        return externalIDString;
    }
    
  
    private static void validateUserProvisioningRequest(List<Case> userRequests){
        Organization myOrg = [Select o.Name From Organization o];
        
        Map<Id,Account> accountPTerritoryMap = new Map<Id,Account>();
        Map<Id,ServiceTerritory> territoryIdMap = new Map<Id,ServiceTerritory>();
        // check if username is unique
        Set<String> selectedUserNames = new Set<String>();
        Set<String> selectedNicknames = new Set<String>();
        Set<String> selectedExternalIDs = new Set<String>();
        Map<Case, String> externalIDTOCaseMap = new Map<Case, String>();
        Set<String> primaryTerritoryIdSet = new Set<String>();
        for(Case cs : userRequests){
            // check if username is in valid format
            selectedUserNames.add(cs.FSL_Username__c);
            selectedNicknames.add(cs.FSL_Nickname__c);
            String externalID = createExternalUserID(cs, myOrg);
            selectedExternalIDs.add(externalID);
            externalIDTOCaseMap.put(cs, externalID);
            if(cs.FSL_Primary_Service_Territory__c != null) 
                primaryTerritoryIdSet.add(cs.FSL_Primary_Service_Territory__c);
        }

        if(!primaryTerritoryIdSet.isEmpty()) {
                territoryIdMap = new Map<Id,ServiceTerritory>([Select Id,OperatingHours.Id,OperatingHours.TimeZone from ServiceTerritory where Id IN :primaryTerritoryIdSet ]);
                for(Account acc : [SELECT id, Name,Service_Territory__c FROM Account WHERE Service_Territory__c = :primaryTerritoryIdSet  ]){
                    accountPTerritoryMap.put(acc.Service_Territory__c,acc);
                }
            }
        
        // query all matching usernames
        List<User> usrList = [SELECT id, UserName, CommunityNickname, External_Id__c,IsActive  
                                FROM User 
                            WHERE Username IN :selectedUserNames 
                                OR External_Id__c IN :selectedExternalIDs];
        
        //REMOVED: OR CommunityNickname IN :selectedNicknames - was not considered a "Selective" query
        
        for(Case cs : userRequests){
            for(User usr : usrList){
                if(usr.isActive == true && cs.FSL_Re_Activate__c == false) {
                    if(cs.FSL_Username__c == usr.UserName){
                        cs.addError('Duplicate username exists for the following user: ' + usr.id);
                    }
                    else if(cs.FSL_Nickname__c == usr.CommunityNickname){
                        cs.addError('Duplicate CommunityNickname exists for the following user: ' + usr.id);
                    }  
                    else if(externalIDTOCaseMap.get(cs) == usr.External_Id__c){
                        
                        cs.addError('Duplicate External_Id__c exists for the following user: ' + usr.id);
                    }
                }
                                           
            }
            if(cs.FSL_Contractor__c == true && cs.FSL_Primary_Service_Territory__c != null && accountPTerritoryMap.get(cs.FSL_Primary_Service_Territory__c) == null) {
                cs.addError('Facility On-Boarding has not been completed. Please link this service territory to a Partner Account');
            }
        }
        
        
    }
    
    
    public static Map<String, PermissionSet> createPermissionSetMap(){
        // TODO: populate from custom setting
        Map<String,PermissionSet> permissionSetMap = new Map<String,PermissionSet>();
        Set<String> permSetList = new Set<String>();
        for(UP_Permission_Sets__c permSet : UP_Permission_Sets__c.getAll().values()) {
            if(permSet.AppliedPermissionSet__c != null) {
                permSetList.addAll(permSet.AppliedPermissionSet__c.split(','));
            }
        }
        if(!permSetList.isEmpty()) {
            for(PermissionSet ps :[Select Id,Name from PermissionSet where Name IN : permSetList]) {
                permissionSetMap.put(ps.Name,ps);
            }

        }
        
        return permissionSetMap;
    }
    
    
}