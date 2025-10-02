/**
 * Name : FSL_DataFactory
 * Description : Class for creating and populating test data.
 * 09/29/2020  Dylan Truong     ERS-219581 -- Timeouts - FSL Changes   Change : Modified createWoIntakeCall method to return FSL_WorkOrderResponse instead of void.
 * 11/20/2020  Dylan Truong     Rectify the incorrect checking for commit 8e4076b
 * 01/19/2021  Clement Shiu     Added routine to insert Appointment Dispatch Window to FSL_Settings custom settings
 */
public with sharing class FSL_DataFactory {

    public static FSL_WorkOrderResponse createWOIntakeCall(string resourceName){
        StaticResource sr = [select id, body from StaticResource where name = :resourceName];
        string JSON = sr.body.toString();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(json);
        
        RestContext.request = req;
        RestContext.response= res;  
        return FSL_WorkOrderIntake.UpsertWorkOrder();
    }

    public static List<Technology_Preference__c> createTechPreference(List<ServiceTerritory> ServiceTerritories){
        List<Technology_Preference__c> techPrefs = new List<Technology_Preference__c>();
        list<string> types = new list<string>{'Landline','SMS','Full FSL Technology'};
            for(ServiceTerritory st : ServiceTerritories){//[select id, name from ServiceTerritory limit 3]){
            integer i = 0;
            Technology_Preference__c tp = new Technology_Preference__c(
                                                SERVICE_TERRITORY__C = st.id,
                                                DAYS_APPLIED__C = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
                                                END_TIME__C = Time.newInstance(23,0,0,0),
                                                START_TIME__C = Time.newInstance(0,0,0,0),
                                                TECHNOLOGY_TYPE__C = types[i]
                                                );
            i=i+1;
            techPrefs.add(tp);
        }
        insert techPrefs;
        return techPrefs;
    }
    
    //Create Resource absence
    public static List<ResourceAbsence > CreateResourceAbsences(string g_label){
        List<ResourceAbsence > Ralist= new List<ResourceAbsence >();
        for(ServiceResource serviceResource : [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T']){
            ResourceAbsence resAbs = new ResourceAbsence();
            resAbs.ResourceId = serviceResource.Id;
            resAbs.FSL__GanttLabel__c =g_label; 
            resAbs.Start =  system.Now().addMinutes(10); 
            resAbs.End=  system.Now().addMinutes(20);
            Ralist.add(resAbs);                        
        }
        insert Ralist;
        return Ralist;
        
    }

    /**
    * Method name  : createWorkTypes
    * Description  : Creates 5 worktypes with the specified name and estimated duration
    * Return Type  : List<WorkType>
    * Parameter    : String wtName, Decimal wtEstimatedDuration
    **/
    public static List<WorkType> createWorkTypes() {
        return Test.loadData(WorkType.sObjectType,'FSL_WorkType') ;    
    }
    
    public static List<Account> createAccounts() {
        return Test.loadData(Account.sObjectType,'FSL_Account') ;    
    }
    
    public static List<Contact> createContacts() {
        return Test.loadData(Contact.sObjectType,'FSL_Contact') ;    
    }    

    /**
    * Method name  : createAssignedResource
    * Description  : method for creating the AssignedResource junction between ServiceAppointment and ServiceResource.
    * Return Type  : AssignedResource
    * Parameter    : Id saId, Id srId
    **/
    public static AssignedResource createAssignedResource(Id saId, Id srId) {
        AssignedResource assignedResource = new AssignedResource(ServiceAppointmentId = saId, ServiceResourceId = srId,
                                            FSL__UpdatedByOptimization__c = false);
        return assignedResource;
    }
    
    /**
    * Method name  : createServiceResource
    * Description  : method for creating the AssignedResource junction between ServiceAppointment and ServiceResource.
    * Return Type  : AssignedResource
    * Parameter    : Id userId, Id locId
    **/
    public static ServiceResource createServiceResource(Id userId, Id locId) {
        ServiceResource serviceResource = new ServiceResource(Name = 'TestUserSR', IsActive = true, Available__c = true, 
                                                            RelatedRecordId = userId, LocationId = locId,Driver_Id__c='Test Driver', ResourceType='T');
        return serviceResource;
    }

    public static FSL__User_Territory__c createUserTerritories(id userid, id servterrid){
        FSL__User_Territory__c userTer = new FSL__User_Territory__c (FSL__ServiceTerritory__c=servterrid, FSL__User__c=userid);
        return userTer;
    }
    
    /**
    * Method name   : createLocation
    * Description   : methods for creating test Locations
    * Return Type   : Schema.Location
    * Parameter     : void
    **/
    public static List<Schema.Location> createLocation() {
        return Test.loadData(Schema.Location.sobjectType, 'FSL_Location');
    }
    
    public static list<User> createTestuser() {
        
        map<id, Profile> mapProfiles = new map<id, Profile>([SELECT Id, Name 
                                                            FROM Profile 
                                                            WHERE Name IN ( 'System Administrator', 
                                                                            'FSL Mobile (Fleet Technician)', 
                                                                            'FSL Facility Dispatcher (Fleet)')
                                                            ]);
        system.debug('mapProfiles:'+mapProfiles);
        map<string, set<string>> mapProfileToPermissionSet = new map<string, set<string>>();
        list<Id> profileIds = new list<Id>();
        profileIds.addAll(mapProfiles.keyset());
        
        mapProfileToPermissionSet.put(profileIds[0], new set<String>{'FSL_Admin_Permissions','FSL_Admin_License','FSL_Dispatcher_Permissions','FSL_Dispatcher_License','FSL_Resource_License','FSL_Resource_Permissions','FSL_Dispatcher_Permissions','FSL_Dispatcher_License'});
        mapProfileToPermissionSet.put(profileIds[1], new set<String>{'FSL_Mobile_License','FSL_Resource_License','FSL_Resource_Permissions','Moblie_Technician_Permission_Set'});
        mapProfileToPermissionSet.put(profileIds[2], new set<String>{'FSL_Dispatcher_Permissions','FSL_Dispatcher_License'});
        system.debug('mapProfileToPermissionSet:'+mapProfileToPermissionSet);
        List<User> users = new List<User>();
        for(ID pid : mapProfiles.keySet()){  
            system.debug('pid:'+pid);
            User userObj;
            if(mapProfiles.get(pid).Name == 'System Administrator'){ 
                userObj = new User(Alias = 'C_Admin',Email='test_user@ace.aaa.com', 
                    EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = pid, 
                    TimeZoneSidKey='America/Los_Angeles', UserName='Cap@capadmin.com');
        
            }else if(mapProfiles.get(pid).Name == 'FSL Mobile (Fleet Technician)'){ 
                userObj = new User(Alias = 'T_Fleet', Email='test_user@ace.aaa.com', 
                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = pid, 
                    TimeZoneSidKey='America/Los_Angeles', UserName='Cap@fleettech.com');
            }else if(mapProfiles.get(pid).Name == 'FSL Facility Dispatcher (Fleet)'){ 
                userObj = new User(Alias = 'D_Fleet', Email='test_user@ace.aaa.com', 
                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = pid, 
                    TimeZoneSidKey='America/Los_Angeles', UserName='Cap@fleetdispatch.com');
            }
            users.add(userObj);
        }
        insert users;
        
        list<PermissionSetAssignment> listPS = new list<PermissionSetAssignment>();
        list<PermissionSet> psets =  [SELECT Id, Name 
                                    From PermissionSet 
                                    WHERE Name IN ( 'FSL_Admin_Permissions', 
                                                    'FSL_Mobile_License', 
                                                    'FSL_Resource_Permissions', 
                                                    'FSL_Resource_License', 
                                                    'FSL_Dispatcher_License', 
                                                    'Moblie_Technician_Permission_Set', 
                                                    'Glympse_EnRoute_Admin', 
                                                    'Glympse_Community_User')];
        for(User u : users)
        {
            for(PermissionSet ps : psets){
                if(mapProfileToPermissionSet.get(u.profileid).contains(ps.Name)){
                    listPS.add(new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id ));
                }
            }
        }
        
        insert listPS;
                                 
        return users; 
    }    
    
    /**
    * Method name  : createSchedulingPolicies
    * Description  : method for creating scheduling policy.
    * Return Type  : FSL__Scheduling_Policy_Used__c
    * Parameter    : NA
    **/
    public static list<FSL__Scheduling_Policy__c> createSchedulingPolicies() {
        return Test.loadData(FSL__Scheduling_Policy__c.sobjectType, 'FSL_SchedulingPolicy');
    }

    /**
    * Method name  : createOperatingHours
    * Description  : method for creating createOperatingHours.
    * Return Type  : createOperatingHours
    * Parameter    : NA
    **/
    public static List<OperatingHours> createOperatingHours() {
        return Test.loadData(OperatingHours.sobjectType, 'FSL_OperatingHour');
    }

    /**
    * Method name  : createTimeSlots
    * Description  : method for creating TimeSlot records. creates five TimeSlot records for Monday to Friday
    * Return Type  : createTimeSlots
    * Parameter    : NA
    **/
    public static List<TimeSlot> createTimeSlots() {
        return Test.loadData(TimeSlot.sobjectType, 'FSL_TimeSlot');
    }

    /**
    * Method name  : createServiceTerritory
    * Description  : method for creating createServiceTerritory.
    * Return Type  : Service Territory
    * Parameter    : Operating Hours Id
    **/
    public static List<ServiceTerritory> createServiceTerritory() {
        return Test.loadData(ServiceTerritory.sobjectType, 'FSL_ServiceTerritory');        
    }
    
    public static list<FSL__Polygon__c> createpolygon(){
        return Test.loadData(FSL__Polygon__c.sobjectType, 'FSL_Polygon');        
    }
    
    public static list<Product2> createProducts(){
        return Test.loadData(Product2.sobjectType, 'FSL_Product');        
    }
    /**
    * Method name  : createServiceTerritoryMember
    * Description  : method for creating createServiceTerritoryMember.
    * Return Type  : ServiceTerritoryMember
    * Parameter    : ServiceResourceId, ServiceTerritoryId
    **/

    public static ServiceTerritoryMember createServiceTerritoryMember(Id ServiceResourceId, Id ServiceTerritoryId) {
    
        ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember(ServiceResourceId = ServiceResourceId, ServiceTerritoryId = ServiceTerritoryId, TerritoryType = 'P',EffectiveStartDate = (system.now()-1) );
        return serviceTerritoryMember;
    }
    
   /**
    * Method name  : createServiceLineItems
    * Description  : method for creating ServiceLineItems.
    * Return Type  : FSL_Service_Line_Item__c
    * Parameter    : WorkOrderId
    **/
    public static FSL_Service_Line_Item__c createServiceLineItems(Id WorkOrderId, Integer Cost, Integer unit, ID productID) {
        
        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c(Product__c = productID, Work_Order__c = WorkOrderId,Unit__c = unit,Cost__c = cost);
        return serviceLineItem;
    }  

    public static FSL_Service_Line_Item__c createServiceLineItems(Id WorkOrderId) {
        return createServiceLineItems(WorkOrderId, 5000, 20, null);
    }     
    
    public static ResourceAbsence createResourceAbsence(Id serviceResourceId, DateTime startTime, DateTime endTime){
        ResourceAbsence resAbs = new ResourceAbsence();
        resAbs.ResourceId = serviceResourceId; 
        resAbs.Start =  startTime; 
        resAbs.End =  endTime;
        return resAbs;        
    }
    
    public static Entitlement createEntitlement(String name, ID accId, ID slaId){
        Entitlement entitlement = new Entitlement();
        entitlement.Name = name;
        entitlement.AccountId = accId;
        entitlement.SlaProcessId = slaId;
        entitlement.StartDate = system.today();
        insert entitlement;
        return entitlement;
    }
    
    public static FeedItem createFeedItem(Id WorkOrderId){
        
         FeedItem feedItem=new FeedItem();
         feedItem.ParentId = workOrderId;
         feedItem.TYPE = 'TextPost';
         feedItem.body = 'TextBody';
         feedItem.Visibility = 'AllUsers';
            
        return feedItem;
    }
    
    public static List<FSL_Contractor_Community__c> createContractorCommunity(){
        List<FSL_Contractor_Community__c> contractorCommList = new List<FSL_Contractor_Community__c>();
        FSL_Contractor_Community__c contractorComm = new FSL_Contractor_Community__c();
        contractorComm.Name = 'FSL_Contractor_Community';
        contractorComm.Community_Name__c = 'ContractorCommunity';
        contractorCommList.add(contractorComm);
        return contractorCommList;
    }
    
    public static List<FSL_Audio_Preferences__c>  CreateAudioPref( Id UserId){
        List<FSL_Audio_Preferences__c> CreateAudioPrefList = new List<FSL_Audio_Preferences__c>();
        
        FSL_Audio_Preferences__c Ap1 = new FSL_Audio_Preferences__c();
        
        Ap1.Notifications_on_New_Call__c = true;
        Ap1.Time_Interval_In_Seconds__c = 2;
        Ap1.User__c = UserId;
        CreateAudioPrefList.add(Ap1);
     
        FSL_Audio_Preferences__c Ap2 =new FSL_Audio_Preferences__c();
        Ap2.Time_Interval_In_Seconds__c = 10;
        Ap2.Notifications_on_New_Call__c = true;
        Ap2.User__c = UserId;
        CreateAudioPrefList.add(Ap2);
        //insert CreateAudioPrefList;
        return CreateAudioPrefList;
    }
    
    public static List<FSL_Call_Comments__c >  CreatecallComments( Id WorkOrderid){
        List<FSL_Call_Comments__c > CreateCallComm = new List<FSL_Call_Comments__c >();
        
        FSL_Call_Comments__c  CC = new FSL_Call_Comments__c ();
        
        CC.FSL_Comment__c  = 'Test comments';
        CC.FSL_Work_Order__c = WorkOrderid;
        
        CreateCallComm.add(CC);
     
        FSL_Call_Comments__c  CC1 = new FSL_Call_Comments__c ();
        CC1.FSL_Comment__c  = 'Test comments';
        CC1.FSL_Work_Order__c = WorkOrderid;
       
        CreateCallComm.add(CC1);
        
        return CreateCallComm;
    }
    
    
    public static List<FSL_SLA_ArrivalWindow__c> CreateSLAWindow(list<FSL__Scheduling_Policy__c> SchedulingPolicy, List<ServiceTerritory> ServiceTerritories){
        List<FSL_SLA_ArrivalWindow__c> slalist = new list <FSL_SLA_ArrivalWindow__c>();

        for(ServiceTerritory st : ServiceTerritories){
            FSL_SLA_ArrivalWindow__c sla = new FSL_SLA_ArrivalWindow__c();
            sla.LS_SLA__c = 20;
            sla.Retry_Policy__c = SchedulingPolicy[1].id;
            sla.Scheduling_Policy__c = SchedulingPolicy[0].id;
            sla.Service_Territory__c = st.id;
            sla.Tow_SLA__c =  20;
            sla.Priority__c = 'Medium';
            
            FSL_SLA_ArrivalWindow__c sla1 = new FSL_SLA_ArrivalWindow__c();
            sla1.LS_SLA__c = 20;
            sla1.Retry_Policy__c = SchedulingPolicy[1].id;
            sla1.Scheduling_Policy__c = SchedulingPolicy[0].id;
            sla1.Service_Territory__c = st.id;
            sla1.Tow_SLA__c =  30;
            sla1.Priority__c = 'Critical'; 
            
            FSL_SLA_ArrivalWindow__c sla2 = new FSL_SLA_ArrivalWindow__c();
            sla2.LS_SLA__c = 20;
            sla2.Retry_Policy__c = SchedulingPolicy[1].id;
            sla2.Scheduling_Policy__c = SchedulingPolicy[0].id;
            sla2.Service_Territory__c = st.id;
            sla2.Tow_SLA__c =  40;
            sla2.Priority__c = 'High'; 
            
            slalist.add(sla);
            slalist.add(sla1);
            slalist.add(sla2);
        }
        insert slalist;
        return slalist ;
    }
    
    
   public static List<Override_Resource_Preference__c> ORprefList(List<Service_Territory_Scheduling_Override__c> schOverrides, List<ServiceResource> ServiceResources){
   
     List<Override_Resource_Preference__c> OprefList = new list <Override_Resource_Preference__c >();
       for(Integer i=0; i < ServiceResources.size(); i++){
        Override_Resource_Preference__c orp = new Override_Resource_Preference__c();
        orp.Scheduling_Override__c = schOverrides[i].id;
        //orp.Service_Resource__c = ServiceResources[i].id;
        orp.Service_Territory__c = ServiceResources[i].Primary_Service_Territory__c;
        orp.Type__c = 'Excluded';
         
        /*Override_Resource_Preference__c orp1 = new Override_Resource_Preference__c();
        orp1.Scheduling_Override__c = schOverrides[i].id;
        orp1.Service_Resource__c = ServiceResources[i].id; 
        orp1.Type__c = 'Excluded';
        OprefList.add(orp1);*/
        OprefList.add(orp);
       }
       insert OprefList;
        return OprefList;
   
    }

    public static Case createCase( String recordType ) {
        Case c = new Case();
        c.Status = 'New';
        c.Origin = 'Automation';
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( recordType ).getRecordTypeId();
        return c;
    }

   public static List<Case> CreateUserProvisionCase(Id SerterId){
   
            List<Case> cslist = new list<Case>();
                Case cs = new Case();
                cs.Status = 'New';
                cs.FSL_Email__c ='test@gmail.com';
                cs.FSL_Primary_Service_Territory__c = SerterId;
                cs.FSL_First_Name__c = 'Test First Name3';
                cs.FSL_Username__c  = 'UserName3@testUsername.acb';
                cs.FSL_Last_Name__c = 'User3';
                cs.FSL_Email__c = 'testEmail3@ace.aaa.com';
                cs.FSL_Alias__c  = 'TstAlia3';  
                cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('User Provisioning Request').getRecordTypeId();
                cs.FSL_Nickname__c = 'Testers';
                cs.FSL_Re_Activate__c = false;
                cs.FSL_Contractor__c = false;
                cs.FSL_Profile__c = 'Club Dispatcher';
            
            Case cs1 =  new Case();
            cs1.FSL_First_Name__c = 'Test First Name2';
            cs1.FSL_Username__c  = 'UserName2@testUsername.acb';
            cs1.FSL_Last_Name__c = 'User2';
            cs1.FSL_Email__c = 'testEmail2@ace.aaa.com';
            cs1.FSL_Alias__c  = 'TstAlia2';  
            cs1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('User Provisioning Request').getRecordTypeId();
            cs1.FSL_Primary_Service_Territory__c =SerterId;
            cs1.FSL_Employee_ID__c = 'Tester';
            cs1.FSL_Profile__c = 'Admin';     
            
            Case cs2 =  new Case();
            cs2.FSL_First_Name__c = 'Test First Name3';
            cs2.FSL_Username__c  = 'UserName4@testUsername.acb';
            cs2.FSL_Last_Name__c = 'User4';
            cs2.FSL_Email__c = 'testEmail4@ace.aaa.com';
            cs2.FSL_Alias__c  = 'TstAlia4';  
            cs2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('User Provisioning Request').getRecordTypeId();
            cs2.FSL_Primary_Service_Territory__c = SerterId;
            cs2.FSL_Employee_ID__c = '1234';
            cs2.FSL_Profile__c = 'Technician';
            cs2.FSL_Start_Date__c = system.today(); 
                
            cslist.add(cs2);
            cslist.add(cs);
            cslist.add(cs1);
            insert cslist;
            return cslist;
   }
   
   Public Static List<Schedule_Freeze__c> ScheduleFreezelist(list<WorkType> worktypes, List<ServiceTerritory> ServiceTerritories ){
   
       List<Schedule_Freeze__c> schedFreezeList = new List<Schedule_Freeze__c>();
       for(ServiceTerritory st :ServiceTerritories){
           integer i=0;
           Schedule_Freeze__c sfreeze =  new Schedule_Freeze__c(
                                            End_Date__c=system.today().addDays(10), 
                                            Service_Territory__c=st.id, 
                                            Start_Date__c=system.today(), 
                                            //Unique_Identifier__c='1232133'+i, 
                                            Work_Type__c=worktypes[0].id);   
           schedFreezeList.add(sfreeze);
           i = i+1;           
       }
       insert schedFreezeList;
       return schedFreezeList ;
   
   }
     
   Public Static List<Service_Territory_Scheduling_Override__c> ServiceTerritoryOverride(list<FSL__Scheduling_Policy__c> SchedulingPolicy, List<ServiceTerritory> ServiceTerritories ){
   
        List<Service_Territory_Scheduling_Override__c> Stolist = new List<Service_Territory_Scheduling_Override__c>();
       for(ServiceTerritory st : ServiceTerritories){
            Service_Territory_Scheduling_Override__c schOverride = new Service_Territory_Scheduling_Override__c(
                                                                    Name=st.name+'Towing',
                                                                    Days_Applied__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
                                                                    // End_Hour__c=Time.newInstance(22, 0, 0, 0),
                                                                    End_Hour__c=Time.newInstance(23, 59, 0, 0),
                                                                    Scheduling_Policy__c= SchedulingPolicy[0].id,
                                                                    Service_Territory__c=st.id,
                                                                    Start_Hour__c=Time.newInstance(0, 0, 0, 0),
                                                                    Work_Types__c = 'Tire Change');   
            Stolist.add(schOverride );
       }        
        insert Stolist;
        return Stolist;
        
     } 
     
     
    Public Static List <FSL_Application_Log__c> CreateApplicationLog(){
        
         List<FSL_Application_Log__c> applist = new list<FSL_Application_Log__c>();
           FSL_Application_Log__c applog = new FSL_Application_Log__c();
               applog.API_Name__c = 'Glympse';
           FSL_Application_Log__c applog1 = new FSL_Application_Log__c ();
               applog1.API_Name__c = 'update';
           applist.add(applog);
           applist.add(applog1);
    
          return applist;
    
     }    
    
    
    Public static List <FSL_User_Message__c> CreateUserMessages(){
        return Test.loadData(FSL_User_Message__c.sobjectType, 'FSL_UserMessage');    
    }     
    
    public static Execute_Trigger__c ExecuteTriggerSetting(string sObjectType){
        Execute_Trigger__c e = new Execute_Trigger__c(name=sObjectType, disabled__c = false, Execute_Logic__c=true);
        return e;
    }

    public static FSL_Optimization_Settings__c createOptimizationSetting(){
        FSL_Optimization_Settings__c oSettings = new FSL_Optimization_Settings__c();
        oSettings.Glympse_Login_Threshold__c = 1;
        oSettings.In_Day_Gap_Threshold__c = 10;
        oSettings.Optimize_Absence_Overlaps__c = true;
        oSettings.Optimize_Emergency_Overlaps__c = true;
        oSettings.RSO_Candidate_SA_Field_API_Name__c = 'Not_Pinned__c';
        oSettings.RSO_Max_Run_Time__c = 30;
        oSettings.RSO_Remain_Scheduled_SA_Field_API_Name__c = 'Not_Pinned__c';
        oSettings.RSO_Scheduling_Policy__c = 'No PTA';
        oSettings.RSO_Threshold__c = 5;
        oSettings.Run_InDay_on_Cancellation__c = true;
        oSettings.Run_InDay_Over_Vehicle_Change__c = true;
        oSettings.Run_LKL__c = true;
        oSettings.Run_Shifts__c = false;
        oSettings.Create_ResourceAbsence_In_Trigger__c = true;
        oSettings.Stacked_Appointments_Count__c = 0 ;
        return oSettings;
    }
    
    public static Chatter_Delete_Settings__c chatterDelSetting(){
        return new Chatter_Delete_Settings__c(Allow_Feed_Post_and_Comment_deletes__c=true); 
    }
    
    public static list<FSL_API_Exception_Codes__c> createExceptionCodessetting(){
        return Test.loadData(FSL_API_Exception_Codes__c.sObjectType, 'FSL_APIExceptionCode');
    }
    
    public static FSL_Contractor_Community__c contractorCommunitysetting(){
        FSL_Contractor_Community__c cc =  new FSL_Contractor_Community__c(Name='FSL_Contractor_Community', Community_Name__c='ContractorCommunity');
        insert cc;
        return cc;
    }
    
    public static FSL_Custom_Notification_Settings__c CustomNotificationSetting(){
        return new FSL_Custom_Notification_Settings__c(Enable_Address_Change_Notification__c= true, 
                                                Enable_Dispatcher_Auto_Follow_Logic__c=true, 
                                                Enable_Tech_Auto_Follow_Logic__c=true, 
                                                Enable_Unassignment_Notification_Logic__c=true, 
                                                Status_Post_Breakdown_Only__c=true,
                                                Relevant_Statuses__c='Tow Complete,On Location');
    }
    
    public static FSL_Integration_User__c  createIntegrationUsersetting(){
        return new FSL_Integration_User__c(
                                            Name = 'Integration User',
                                            isSandbox__c=true,
                                            Sandbox_Email__c ='test787@ace.aaa.com',
                                            Sandbox_Phone__c ='4079999999'
                                            //User_Name__c='test98989@capgmeni.com.integ'
                                          );

    }
    
    public static List<FSL_ServiceSettings__c> createFSLServiceSettings(){
        return Test.loadData(FSL_ServiceSettings__c.sObjectType, 'FSL_ServiceSetting');
    }    

    public static List<FSL_Milestone_Time_Trigger__c> createMilestoneViolationSetting() {
        List<FSL_Milestone_Time_Trigger__c> milestoneViolationConfigList = new List<FSL_Milestone_Time_Trigger__c>();
        
        for(MilestoneType mt : [select Id,name from MilestoneTYpe ]){
            FSL_Milestone_Time_Trigger__c  mileStoneTimeTrigger = new FSL_Milestone_Time_Trigger__c ();
            mileStoneTimeTrigger.Name = mt.id;
            mileStoneTimeTrigger.milestone_name__c = mt.name;
            mileStoneTimeTrigger.Time_Trigger_Minutes__c = 2;
            milestoneViolationConfigList.add(mileStoneTimeTrigger);            
        }        
        insert milestoneViolationConfigList;
        return milestoneViolationConfigList;
    }
    
    public static FSL_Pinned_Statuses__c pinnedStatusSetting(){
       return new FSL_Pinned_Statuses__c(Territory_Locked_Status__c='En Route,On Location,In Tow,Tow Complete,Cleared');        
    }
    
    public static list<FSL_PriorityCode_Mapping__c> createFSLPriorityCodeSetting(){
        return Test.loadData(FSL_PriorityCode_Mapping__c.sObjectType, 'FSL_PriorityCode');
    }
    public static list<FSL_RAP_Matrix__c> fslRAPMatrixSetting(){
        return Test.loadData(FSL_RAP_Matrix__c.sObjectType, 'FSL_RAPMatrix');
    }
    
    public static List<FSL_Service_Endpoints__c>  createServiceEndpointsSetting(){
        return Test.loadData(FSL_Service_Endpoints__c.sObjectType, 'FSL_ServiceEndpoint');
    }

    public static List<FSL_Territory_Mapping__c> createTerritoryMappingSetting(){
        return Test.loadData(FSL_Territory_Mapping__c.sObjectType, 'FSL_TerritoryMapping');        
    } 
    
    public static List<FSL_Work_Order_Status_Code_Mapping__c> createWorkOrderStatusCodeSetting(){
        return Test.loadData(FSL_Work_Order_Status_Code_Mapping__c.sObjectType, 'FSL_WorkOrderStatusCode');        
    }
    
    public static list<UP_Permission_Sets__c> UPPermissionSetSetting(){
        return Test.loadData(UP_Permission_Sets__c.sObjectType, 'UP_PermissionSet');       
    }
    
    public static list<FSL_Settings__c> FSLSettings(){
        return Test.loadData(FSL_Settings__c.sObjectType, 'FSL_Settings');       
    }
    
    public static FSL_Settings__c FSLSettings_AppointmentDispatchWindow (){
        FSL_Settings__c ApptDispatchWin =  new FSL_Settings__c(Name='Appointment Dispatch Window', Value__c='45');
        insert ApptDispatchWin;
        return ApptDispatchWin;  
    }    

    public static list<FSL_Required_Fields_Validation__c> createReqFldValidationSetting(){
        return Test.loadData(FSL_Required_Fields_Validation__c.sObjectType, 'FSL_RequiredFieldValidation');       
    }
    
    public static FSL_Glympse_Token__c createGlympseToken(){
            FSL_Glympse_Token__c cs = new FSL_Glympse_Token__c();
            cs.Name = 'GlympseToken';
            cs.Bearer_Token_Endpoint__c = 'https://aaa-api.enterprise.glympse.com/api/v1/account/login';
            cs.Type__c = 'tracking';
            cs.Password__c = 'Glympse@2019';
            cs.Username__c = 'sbagam@aaa.com';
            cs.ETA_Endpoint__c = 'https://aaa-api.enterprise.glympse.com/api/v1/ivr?org_id=81511&foreign_id=';     
            insert cs;
            return cs;        
    }

    public static ContractLineItem createCLI(String type, ID sContractID, ID priceBookEntryID, Integer price, Integer quantity, Date startDate){
        ContractLineItem cli = new ContractLineItem();
        cli.Type__c = type;
        cli.ServiceContractID = sContractID;
        cli.PricebookEntryID = priceBookEntryID;
        cli.UnitPrice = price;
        cli.Quantity = quantity;
        cli.StartDate = startDate;
        return cli;
    }

    // Deloitte/ACG version
    public static ContractLineItem createCLI(String type, ID sContractID, ID priceBookEntryID, Integer price, Integer quantity, Date startDate, Date EndDate){
        ContractLineItem cli = new ContractLineItem();
        cli.Type__c = type;
        cli.ServiceContractID = sContractID;
        cli.PricebookEntryID = priceBookEntryID;
        cli.UnitPrice = price;
        cli.Quantity = quantity;
        cli.StartDate = startDate;
        cli.EndDate = EndDate;
        return cli;
    }


     public static List<FSL_Member_Vehicle__c> createMemberVehicle(Id WorkOrderId) {
    
      List<FSL_Member_Vehicle__c> memberlist = new List<FSL_Member_Vehicle__c>(); 
        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();
        memberVehicle.Vehicle_Type__c = 'PS';
        memberVehicle.Vehicle_Year__c = '2012';
        memberVehicle.Vehicle_Make__c = 'HONDA';
        memberVehicle.Vehicle_Model__c = 'ACCORD';
        memberVehicle.Vehicle_Trim__c = 'RX';
        memberVehicle.Vehicle_Color__c = 'BLUE';
        memberVehicle.Vehicle_Drive_Type__c = 'FW';
        memberVehicle.Vehicle_Vin__c = '432143124124E234';
        memberVehicle.Vehicle_Tag__c = 'N12ABC';
        memberVehicle.Vehicle_State__c = 'FL';
        memberVehicle.Vehicle_Odometer__c = 78310;
        memberVehicle.Vehicle_Fuel_Type__c = 'GAS';
        memberVehicle.Vehicle_Special_Equipment_Needs__c = 'NEED Jack';
        memberVehicle.Work_Order__c = WorkOrderId;
        memberlist.add(memberVehicle);
        insert memberlist;
        return memberlist ;
    }

    Public static list<Shift> CreateShift(Id serTer, id serviceresourceid){
    
        List<Shift> shiftlist = new List<Shift>();
        Shift sh = new Shift();
        sh.ServiceTerritoryId = serTer;
        sh.ServiceresourceId = serviceresourceid;
        sh.StartTime =System.now();
        sh.Status ='Confirmed';
        sh.TimeSlotType ='Normal';
        sh.EndTime = System.now()+1;
         
        Shift sh1 = new Shift();
        sh1.ServiceTerritoryId = serTer;
        sh1.ServiceresourceId = serviceresourceid;
        sh1.StartTime =System.now();
        sh1.Status ='Tentative';
        sh1.TimeSlotType ='Normal';
        sh1.EndTime = System.now()+4;
        shiftlist.add(sh);
        shiftlist.add(sh1);
        
        return shiftlist;    
    }

    public static WorkOrder createWorkOrderShell(String recordType, Contact contact){
        Id recordTypeID = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        WorkOrder wo = new WorkOrder();
        wo.Locked_After_Clear__c = false;
        wo.Call_Id__c = '20001';
        wo.AccountID = contact.accountID;
        wo.ContactID = contact.ID;
        Date dToday = Date.today();
		String dateStr = dToday.year() + '-' + dToday.month() + '-' + dToday.day();
        wo.Call_Date__c = dateStr; // added as failing class FSL_ToD3Update method wrapperBuilder line 135 not getting all params
        // NOTE: should be a different account than the one facility
        wo.Member_Account__c = contact.accountID;
        wo.recordTypeId = recordTypeID;
        //wo.recordTypeId = '0120m000000O8wg';
        return wo;
    }
    
    public static ServiceAppointment createAppointmentShell(String recordType, ID territoryID, ID workorderID, ID contactID, DateTime startTime, Integer duration, String subject){
        Id recordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get(recordType).getRecordTypeId();

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordID = workorderID;
        sa.ContactID = contactID;
        sa.ServiceTerritoryID = territoryID;
        sa.SchedStartTime = startTime;
        sa.SchedEndTime = startTime.addMinutes(duration);
        sa.Subject = subject;
        sa.recordTypeId = recordTypeID;
        //sa.recordTypeId = '0120m000000Hprh';
        return sa;
    }
    
    public static ServiceAppointment createAppointmentShell(ServiceAppointment breakdownAppointment, Integer duration){
        Id recordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordID = breakdownAppointment.ParentRecordID;
        sa.ContactID = breakdownAppointment.ContactID;
        sa.ServiceTerritoryID = breakdownAppointment.ServiceTerritoryID;
        sa.SchedStartTime = breakdownAppointment.SchedEndTime.addMinutes(duration);
        sa.SchedEndTime = sa.SchedStartTime.addMinutes(duration);
        sa.Subject = 'Tow Appointment';
        sa.RecordTypeId = recordTypeID;
        //sa.recordTypeId = '0120m000000Hprh';
        return sa;
    }

    //Commercial Changes added by sneha on 12-08-2021 , Changes moved to Prod on 12/06
    public static List<Account> createcommercialaccount(){
        List<Account> accList = new List<Account>();
        Account acc = new Account();
        acc.Name = 'test name 1';
        Account acc1 = new Account();
        acc1.Name = 'test name2';
        accList.add(acc);
        accList.add(acc1);
        
        return accList ;
       
    }    

    public static List<Contact> createCommercialcontact(Id AccountId){
        User u = [select accountid, contact.Accountid, contact.account.Service_Territory__c from user where id =: userinfo.getUserId()]; 
         List<Contact> conlist = new list<Contact>();
         contact con = new Contact();
         con.firstname = 'test namefirst';
         con.lastname = 'test namelast';
         con.accountid = u.Accountid;
         
         contact con1 = new Contact();
         con1.firstname = 'test namefirst';
         con1.lastname = 'test namelast';
         con1.accountid = u.Accountid;
         conlist .add(con);
         conlist.add(con1);
         return conlist;
     
     }
         
    public static FSLClearQueuedCall__C createClearQueuedCall( Id workOrderId  ) {
        return new FSLClearQueuedCall__C( Name = workOrderId, 
                                        Work_Order__c = workOrderId );
    }

    public static Contact createContact( String lastName ) {
        return new Contact( LastName = lastName );
    }

    public static List<Contact> createContacts( Integer count ) {
        List<Contact> contacts = new List<Contact>();
        for( Integer i = 1; i <= count; ++i ) {
            contacts.add( createContact( 'Last Name ' + i ) );
        }
        return contacts;
    }

    public static Account createAccount( String name ) {
        return new Account( Name = name );
    }

    public static List<Account> createAccounts( Integer count ) {
        List<Account> accounts = new List<Account>();
        for( Integer i = 1; i <= count; ++i ) {
            accounts.add( createAccount( 'Name ' + i ) );
        }
        return accounts;
    }
}