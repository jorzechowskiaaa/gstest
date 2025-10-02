/**
 * @File Name          : FSL_DataFactoryUtility.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 04-26-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/4/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public with sharing class FSL_DataFactoryUtility {
    public static list<User> users;

    public static void userSetupwithStaticData() {
        //Note: if users on this setup are increased make to match the resources as well 
        users = FSL_DataFactory.createTestuser();
        User user ;
        for(User u : users){
            if(u.alias=='C_Admin'){
                user = u;
            }
        }
       
        system.runAs(user){    
            setupCustomSettingsData();
            setupCustomObjectData();
            setupStatusTransitionData(); 
        }

    }
    
    public static void userdataSetup() {
        //Note: if users on this setup are increased make to match the resources as well 
        users = FSL_DataFactory.createTestuser();
        User user ;
        for(User u : users){
            if(u.alias=='C_Admin'){
                user = u;
            }
        }
        system.runAs(user){    
            setupCustomSettingsData();
            setupCustomObjectData();
            setupProductsNContracts();
            setupWOExceptionConfigData();
            setupStatusTransitionData();            
            //setupWorkingData();
        }
    } 
    
    public static void setupCustomSettingsData(){
        //Enable Triggers
        list<string> triggers = new list<string>{'TimeSlot', 'ServiceAppointment', 'ServiceResource', 'FSL__Optimization_Request__c',
                                                'ServiceTerritoryMember', 'ETA_Notification__e', 'Contact', 'Shift', 'Override_Resource_Preference__c',
                                                'FeedItem', 'FeedComment', 'Location', 'Mobile_Notification_Event__e','Task','User',
                                                'ResourceAbsence','AssignedResource','FSL_Service_Line_Item__c','FSL__Gantt_Filter__c',
                                                'WorkOrder','Status_Change_Notification__e','ServiceContract','Case','FSL_Member_Vehicle__c',
                                                'Address','FSL_Audio_Preferences__c','ContractLineItem','OperatingHours'};
        
        list<Execute_Trigger__c> eTriggers = new List<Execute_Trigger__c>();
        for ( string triggerName : triggers )
        {
            eTriggers.add(FSL_DataFactory.ExecuteTriggerSetting(triggerName));
        }
        insert eTriggers;
        
        //Optimization settings
        FSL_Optimization_Settings__c osettings = FSL_DataFactory.createOptimizationSetting();
        insert osettings;
        
        //chatterdel
        Chatter_Delete_Settings__c chatterSettings = FSL_DataFactory.chatterDelSetting();
        insert chatterSettings;
        
        //exceptionCodes
        list<FSL_API_Exception_Codes__c> exceptionCodes = FSL_DataFactory.createExceptionCodessetting();
       
        //CustomNotificationSetting
        FSL_Custom_Notification_Settings__c CNSetting = FSL_DataFactory.CustomNotificationSetting();
        insert CNSetting;
        
        //Integrationuser
        FSL_Integration_User__c intUsersetting = FSL_DataFactory.createIntegrationUsersetting();
        insert intUsersetting;
        
        //ServiceSetting
        List<FSL_ServiceSettings__c> serviceSettingConfig = FSL_DataFactory.createFSLServiceSettings();
        
        //milestonetimetrigger
        List<FSL_Milestone_Time_Trigger__c> milestoneViolationConfig = FSL_DataFactory.createMilestoneViolationSetting();
        
        //PinnedStatus
        FSL_Pinned_Statuses__c PinnedStatus = FSL_DataFactory.pinnedStatusSetting();
        insert PinnedStatus;
        
        //PriorityCodeConfig
        list<FSL_PriorityCode_Mapping__c> PriorityCodeConfig = FSL_DataFactory.createFSLPriorityCodeSetting();
            
        //RAPMatrix
        list<FSL_RAP_Matrix__c> RAPMatrixConfig = FSL_DataFactory.fslRAPMatrixSetting();
        
        //ServiceEndpointsConfig
        List<FSL_Service_Endpoints__c> ServiceEndpointsConfig = FSL_DataFactory.createServiceEndpointsSetting();
       
        FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
          //endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
         endpoint.Endpoint_URL__c = 'https://api-uat.national.aaa.com/common/oauth2/token';
          endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
          endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
          endpoint.Client_Cert_Name__c = '';
          endpoint.Timeout__c = 20000;
          endpoint.Named_Credential__c = '';
          endpoint.Name='OAuth';
          insert endpoint;
        
               
       // List<FSL_Service_Endpoints__c>  createServiceEndpointsSetting = Test.loadData(FSL_Service_Endpoints__c.sObjectType, 'testSROauthCustomSetting');
        
        //TerritoryMappingConfig
        List<FSL_Territory_Mapping__c> TerritoryMappingConfig = FSL_DataFactory.createTerritoryMappingSetting();
        
        //WorkOrderStatusCode
        List<FSL_Work_Order_Status_Code_Mapping__c> WorkOrderStatusCodeConfig = FSL_DataFactory.createWorkOrderStatusCodeSetting();
        
        //UPPermissionSetConfig
        list<UP_Permission_Sets__c> UPPermissionSetConfig = FSL_DataFactory.UPPermissionSetSetting();
        
        //FSL_Settings
        FSL_DataFactory.FSLSettings();
        
        //Required Field Validations
        FSL_DataFactory.createReqFldValidationSetting();
        
        //ContractorCommunity
        FSL_DataFactory.contractorCommunitysetting();
        
        //Glympse Token
        FSL_DataFactory.createGlympseToken();
    } 
    
    public static void setupCustomObjectData(){

        //Account
        List<Account> accounts = FSL_DataFactory.createAccounts();
        
        //Contact
        List<Contact> contacts = FSL_DataFactory.createContacts();
        
        //Work Type
        List<WorkType> workTypes = FSL_DataFactory.createWorkTypes();
        
        //Operating Hour
        List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
        
        //TimeSlot
        List<TimeSlot> TimeSlots = FSL_DataFactory.createTimeSlots();
        
        //List<FSL_Member_Vehicle__c> memberlist = FSL_DataFactory.createMemberVehicle();
        
        //Service Territory
        List<ServiceTerritory> ServiceTerritories = FSL_DataFactory.createServiceTerritory();
        //Building Terr Hierarchy
        ServiceTerritories[0].ParentTerritoryId =  ServiceTerritories[2].id;
        ServiceTerritories[1].ParentTerritoryId =  ServiceTerritories[2].id;
        update ServiceTerritories;
        
        //Update account to terr
        for(Account acc : accounts){
            for(ServiceTerritory st : ServiceTerritories){
                if(st.Facility_Number__c == acc.Facility_ID__c){
                    acc.Service_Territory__c = st.id;
                }
            }
        }
        update accounts;
        
        //Location
        List<Schema.Location> locations = FSL_DataFactory.createLocation();

        //Service Resource
        List<ServiceResource> ServiceResources = new List<ServiceResource>();
        //will create 3 resources
        for(Integer i=0; i < Users.size(); i++){
            ServiceResources.add(FSL_DataFactory.createServiceResource(users[i].id, locations[i].id));
        }
        insert ServiceResources;
        
        //Schedule Policy 
        list<FSL__Scheduling_Policy__c> policies = FSL_DataFactory.createSchedulingPolicies();
        
        //Service Territory Member
        List<ServiceTerritoryMember> STMs = new List<ServiceTerritoryMember>();
        for(integer i = 0; i < ServiceResources.size(); i++){
            STMs.add(FSL_DataFactory.createServiceTerritoryMember(ServiceResources[i].id, ServiceTerritories[i].id));
        }
        insert STMs;

        //User Territory
        list<FSL__User_Territory__c> userTerrs = new list<FSL__User_Territory__c>();
        for(integer i = 0; i < ServiceResources.size(); i++){
            FSL__User_Territory__c uTerr = FSL_DataFactory.createUserTerritories(ServiceResources[i].RelatedRecordid, ServiceTerritories[i].id);
            userTerrs.add(uTerr);
        }
        insert userTerrs;
         
        //assign the vehicle to SR
        
        list<ServiceResource> SRs = new list<ServiceResource>();
        for(ServiceResource sr : [select id, Primary_Service_Territory__c from ServiceResource where ID in :ServiceResources]){
            system.debug('++ServiceResources++'+sr);
            for(Schema.Location location : locations){
                if(location.Facility__c == sr.Primary_Service_Territory__c){
                    sr.Vehicle__c = location.id;
                    SRs.add(sr);
                }
            }
        }
        system.debug('**ServiceResources**:'+SRs);
        update SRs;
        
        //Polygon
        list<FSL__Polygon__c> polygons = FSL_DataFactory.createpolygon();
        for(integer i=0; i < polygons.size() ; i++){
            polygons[i].FSL__Service_Territory__c = ServiceTerritories[i].id;
        }
        update polygons;

        //SLA Arrival Window
        List<FSL_SLA_ArrivalWindow__c> SLAArrivals = FSL_DataFactory.CreateSLAWindow(policies, ServiceTerritories);

    }  
    
    public static void setupWOExceptionConfigData(){
        
        list<ServiceTerritory> ServiceTerritories= [select id, Name from ServiceTerritory];
        list<FSL__Scheduling_Policy__c> policies  = [select id, Name from FSL__Scheduling_Policy__c];
        List<WorkType> workTypes = [select id from WorkType];
        list<ServiceResource> SRs = [select id,Primary_Service_Territory__c from ServiceResource];
        List<Account> accounts = [select id from Account];
        //Technology Preference
        List<Technology_Preference__c> preferences = FSL_DataFactory.createTechPreference(ServiceTerritories);
        
        //Service Territory Scheduling Override 
        List<Service_Territory_Scheduling_Override__c> schOverrides = FSL_DataFactory.ServiceTerritoryOverride(policies, ServiceTerritories);       
        
        //Schedule Freeze
        List<Schedule_Freeze__c> schfreezes = FSL_DataFactory.ScheduleFreezelist(workTypes,ServiceTerritories);
        
        //Override Resource Preference
        List<Override_Resource_Preference__c> ORprefs= FSL_DataFactory.ORprefList(schOverrides, SRs);
        
        //Entitlement
        //List<SlaProcess> slaList = [SELECT Id FROM SlaProcess WHERE Name = 'SLA Violation' AND IsActive = true];
        //Entitlement entitlement = FSL_DataFactory.createEntitlement('SLA Violation', accounts[0].id, slaList.get(0).Id);
        
        //User Message
        List <FSL_User_Message__c> userMessages = FSL_DataFactory.CreateUserMessages();
        
        //Audio Preferences
        List<FSL_Audio_Preferences__c> audioPrefs  = new List<FSL_Audio_Preferences__c>();
        for(User user : [select id from User where alias in ('T_Fleet', 'C_Admin', 'D_Fleet')]){
        //for(User user : [select id from User where alias in ('C_Admin')]){
            audioPrefs.addAll(FSL_DataFactory.CreateAudioPref(user.id));
        }
        insert audioPrefs;        
    }
    
    public static void setupProductsNContracts(){

        
        //Product
        list<Product2> products = FSL_DataFactory.createProducts();
        Id pricebookId = Test.getStandardPricebookId();
        
        //Price book Entry
        list<PricebookEntry> stdPBEs = new list<PricebookEntry>();
        for(Product2 p : products){
            PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = p.Id,
            UnitPrice = 10000, IsActive = true);      
            stdPBEs.add(standardPrice);
        }
        insert stdPBEs;
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        list<PricebookEntry> customPBEs = new list<PricebookEntry>();
        for(Product2 p : products){
            PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = customPB.id, Product2Id = p.Id,
            UnitPrice = 10000, IsActive = true);      
            customPBEs.add(standardPrice);
        }        
        insert customPBEs;
        
        //Parent Service Contracts        
        list<Account> accounts = [select id, Facility_ID__c from Account where Facility_ID__c in ('9121','9193','9198')];        
        list<ServiceContract> parentContracts = new list<ServiceContract>();
        for(Account acc : accounts){
            ServiceContract  sc = new ServiceContract ();
            sc.Accountid = acc.Id;
            sc.Pricebook2Id= customPB.id;
            sc.StartDate =system.today();
            sc.EndDate = System.today()+20;
            sc.Name = 'ParentContract - ' + acc.Facility_ID__c;
            parentContracts.add(sc);        
        }
        insert parentContracts;
        
        //Child Service Contracts
        list<ServiceContract> childContracts = new list<ServiceContract>();
        for(Integer i=0; i <  accounts.size(); i++ ){
            ServiceContract  sc = new ServiceContract ();
            sc.Accountid = accounts[i].Id;
            sc.Pricebook2Id= customPB.id;
            sc.StartDate =system.today();
            sc.EndDate = System.today()+20;
            sc.Name = 'ChildContract'; 
            sc.ParentServiceContractID = parentContracts[i].Id;
            childContracts.add(sc);        
        }
        insert childContracts;        
    }

    public static void setupStatusTransitionData(){
        //SA Appointment Status Transitions
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Spotted');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'En Route');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Cleared');
        FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Canceled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Spotted');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'En Route');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Cleared');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Canceled');
        FSL.GlobalAPIS.addStatusTransition('Spotted', 'Scheduled');        
        FSL.GlobalAPIS.addStatusTransition('Spotted', 'Dispatched'); 
        FSL.GlobalAPIS.addStatusTransition('Spotted', 'Canceled');
        FSL.GlobalAPIS.addStatusTransition('Cleared', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('En Route', 'On Location');
        FSL.GlobalAPIS.addStatusTransition('En Route', 'In Tow');
        FSL.GlobalAPIS.addStatusTransition('En Route', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('En Route', 'Canceled');
        FSL.GlobalAPIS.addStatusTransition('En Route', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('On Location', 'In Tow');
        FSL.GlobalAPIS.addStatusTransition('On Location', 'Dispatched');
        FSL.GlobalAPIS.addStatusTransition('On Location', 'Scheduled');        
        FSL.GlobalAPIS.addStatusTransition('In Tow', 'Tow Complete');
        FSL.GlobalAPIS.addStatusTransition('Tow Complete', 'Cleared');        
        FSL.GlobalAPIS.addStatusTransition('Canceled', 'On Location');
        FSL.GlobalAPIS.addStatusTransition('Canceled', 'Cleared');

    }

    
    /*public static void setupWorkingData(){
        //Work Order and Service Appointment
        //Light Call
        FSL_DataFactory.createWOIntakeCall('FSL_Required_LightCall');
        //Complex Call
        //FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');
        //FSL_DataFactory.createWOIntakeCall('FSL_Required_ComplexCall');        
        //FSL_DataFactory.createWOIntakeCall('FSL_Landline_ComplexCall');
        //FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        //Service Absence
        //
        
    }*/
}