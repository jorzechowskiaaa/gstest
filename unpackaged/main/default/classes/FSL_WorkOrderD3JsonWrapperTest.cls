@isTest
public class FSL_WorkOrderD3JsonWrapperTest {
    private static List<WorkOrder> workOrders;
    private static List<AssignedResource> assignedResources;
    private static List<FeedItem> feedItems;
    private static FSL_WorkOrderD3JsonWrapper wrapper = new FSL_WorkOrderD3JsonWrapper();
    private static Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();
    private static Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap = new Map<Id, List<FeedItem>>();
    private static String serviceName = '';
    private static WorkOrder workOrder; // = new WorkOrder();

    @testSetup
    public static void SetUp() {
        FSL_DataFactoryUtility.userSetupwithStaticData();

        List<User> users = [SELECT Id 
                            FROM user 
                            WHERE alias = 'C_Admin'];
        PermissionSet pset = [SELECT Id FROM PermissionSet WHERE Name = 'Skip_Sharing_Logic'][0];

        insert new PermissionSetAssignment(AssigneeId=users[0].Id,
                                   PermissionSetId=pset.Id); 

        

        System.runAs( users[0] ) {
            List<WorkType> workTypes = [SELECT Id FROM WorkType];
            List<OperatingHours> operatingHours = [SELECT Id FROM OperatingHours];

            Account a = new Account( Name = 'Account Name' );
            insert a;

            Contact c = new Contact( LastName = 'Contact Last Name', email = 'test.test@gmail.com', Phone ='1234567890',Membership_Type__c = 'Member'  );
            insert c;

            WorkOrder wo = new WorkOrder();
            wo.AccountId = a.Id;
            wo.ContactId = c.Id;
            wo.WorkTypeId = workTypes[0].Id;
            wo.Call_Date__c = '2023-05-04';
            wo.Member_Account__c = a.Id;
            wo.Resolution_Code__c = 'N951' ; 
            wo.Clearing_Code__c = '01' ;
            insert wo;

            ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = operatingHours[0].Id, IsActive = true );
            ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = operatingHours[0].Id, IsActive = true );
            List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;

            ServiceAppointment sa1 = new ServiceAppointment( Work_Order__c = wo.Id, ParentRecordId = wo.Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st1.Id );
            sa1.SchedStartTime = System.now();
            sa1.SchedEndTime = System.now() + 1800;
            sa1.actualstarttime = System.now();
            sa1.PTA__c = System.now();
            //Adding BreackDown record type
            sa1.RecordTypeId =[Select Id,SobjectType,Name From RecordType WHERE Name ='Breakdown' and SobjectType ='ServiceAppointment'  limit 1].Id;
            
            
            ServiceAppointment sa2 = new ServiceAppointment( Work_Order__c = wo.Id, ParentRecordId = wo.Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = st2.Id );
            List<ServiceAppointment> sas = new List<ServiceAppointment> { sa1, sa2 };
            insert sas;

            FSL_TroubleCode__c t1 = new FSL_TroubleCode__c( Work_Order__c = wo.Id, Code__c = 'Code 1', Description__c = 'Description 1', Type__c = 'Type 1' );
            FSL_TroubleCode__c t2 = new FSL_TroubleCode__c( Work_Order__c = wo.Id, Code__c = 'Code 2', Description__c = 'Description 2', Type__c = 'Type 2' );
            List<FSL_TroubleCode__c> ts = new List<FSL_TroubleCode__c>{ t1, t2 };
            insert ts;

            FSL_Member_Vehicle__c vehicle = new FSL_Member_Vehicle__c( Work_Order__c = wo.Id );
            insert vehicle;

            FSL_Policy__c p1 = new FSL_Policy__c( Work_Order__c = wo.Id );
            FSL_Policy__c p2 = new FSL_Policy__c( Work_Order__c = wo.Id );
            List<FSL_Policy__c> ps = new List<FSL_Policy__c>{ p1, p2 };
            insert ps;

            FSL_Call_Comments__c comment1 = new FSL_Call_Comments__c( FSL_Work_Order__c = wo.Id, FSL_Comment__c = 'Comment 1' );
            FSL_Call_Comments__c comment2 = new FSL_Call_Comments__c( FSL_Work_Order__c = wo.Id, FSL_Comment__c = 'Comment 2' );
            List<FSL_Call_Comments__c> comments = new List<FSL_Call_Comments__c>{ comment1, comment2 };
            insert comments;

            Product2 product1 = new Product2( Name = 'Product1',FAMILY = 'Service Item',ProductCode = 'p1' );
            Product2 product2 = new Product2( Name = 'Product2',FAMILY = 'Service Item',ProductCode = 'p2' );
            List<Product2> products = new List<Product2>{ product1, product2 };
            insert products;

            FSL_Service_Line_Item__c sli1 = new FSL_Service_Line_Item__c( Work_Order__c = wo.Id, Product__c = product1.Id );
            FSL_Service_Line_Item__c sli2 = new FSL_Service_Line_Item__c( Work_Order__c = wo.Id, Product__c = product2.Id );
            List<FSL_Service_Line_Item__c> slis = new List<FSL_Service_Line_Item__c>{ sli1, sli2 };
            insert slis;

            Schema.Location l = new Schema.Location( Name = 'Location', IsInventoryLocation = true, IsMobile = true );
            Schema.Location veh = new Schema.Location( Name = 'Vehicle', IsInventoryLocation = true, IsMobile = true );
            List<Schema.Location> locs = new List<Schema.Location>{ l, veh };
            insert locs;
            
            ServiceResource serviceResource = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId 
                                                FROM ServiceResource 
                                                WHERE ResourceType='T' limit 1];
            AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa1.Id, ServiceResourceId = serviceResource.Id, FSL__UpdatedByOptimization__c = false );
            insert ar;
                  

            FeedItem feed1 = new FeedItem( Type = 'TextPost', Body = 'Body 1', ParentId = wo.Id );
            FeedItem feed2 = new FeedItem( Type = 'TextPost', Body = 'Body 2', ParentId = wo.Id );
            List<FeedItem> feeds = new List<FeedItem>{ feed1, feed2 };
            insert feeds;
        }
    }

    static void LoadData() {
        workOrders = ( [SELECT Id,Call_Source__c, Resolution_Code__c, Clearing_Code__c,Drop_Box_Info__c, Tow_Destination_Name__c, Tow_Contact_Phone_Number__c, Tow_Contact_First_Name__c, Tow_Contact_Last_Name__c, State, City, 
                            postalcode, country, Street, CreatedDate, WorkOrderNumber, WO_Member_Phone_Number__c, Status, External_Id__c, Call_Origin__c, Call_Origin_OrgCode__c, Call_Origin_OrgName__c, Responder_ID__c, 
                            LastModifiedBy.Name, LastModifiedDate, Tow_Location__Latitude__s, Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s, Tow_Location__Longitude__s, Call_Id__c, RAP_Case_Number__c, 
                            Dispatched_Timestamp__c, Cleared_Timestamp__c, Call_Type__c, Timezone_Id__c, Timezone_Offset__c, Non_Emergency_Appointment_Time__c, Collision__c, Red_Flag__c, Number_Of_Passengers__c, 
                            Is_Tow_WorkType__c, In_Tow_Timestamp__c, Needs_Flatbed__c, Scheduled_Timestamp__c, Legacy_Priority_Code__c, Priority_Code__c, Flatbed_Requested__c, Call_Date__c, Latitude, longitude, 
                            Landmark__c, Highway__c, Mile_Marker__c, Original_Member_Id__c, Cross_Street__c, Cross_Street_2__c, Location_Code__c, Tow_Latitude__c, Tow_Longitude__c, Tow_Landmark__c, Tow_Street__c, 
                            Tow_City__c, Tow_State__c, Spotted_Timestamp__c, Wait_Time__c, Tow_Postal_Code__c, Enroute_Timestamp__c, Tow_Country__c, 
                            InitialETA_Legacy__c, Service_Order_Number__c, Pta__c, Payment_Codes__c, On_Location_Timestamp__c, 
                            Account.Name, Account.Facility_ID__c, Account.Facility_Type__c, 
                            Contact.Original_Member_Id__c, Contact.Membership_Type__c, Contact.Membership_Sponsor__c, Contact.Membership_Program__c, Contact.Membership_Code__c, Contact.Membership_Authorization__c, 
                            Contact.Membership_Islocalclub__c, Contact.Member_Card_Num__c, Contact.Membership_Expiration_Date__c, Contact.Membership_Level__c, Contact.Membership_Birthday__c, Contact.Membership_Since__c,
                            Contact.Membership_Status__c, Contact.Membership_Org__c, Contact.Membership_OrgCode__c, Contact.External_ID__c, Contact.Type__c, Contact.Title, Contact.FirstName, 
                            Contact.LastName, Contact.Phone_Type__c, Contact.Phone, Contact.Phone_Extension__c, Contact.Sms_Optin__c, Contact.Email_Type__c, Contact.Email, Contact.Language_Preference__c, 
                                (SELECT Id,address,Drop_Box_Info__c,SLR_En_Route_Miles__c,SLR_Tow_Miles__c,Landmark__c,Highway__c,Mile_Marker__c,Location_Code__c,Street,State,City,Country,
                                    postalcode,Cross_Street__c,Cross_Street_2__c,ETA__c,Tow_Destination_Name__c,Subject,ParentRecordId,SchedStartTime, Latitude,Longitude,Service_Resource__c, Address_Change_Counter__c, 
                                    ServiceTerritory.Facility_Number__c,ServiceTerritory.Name, FSL_Actual_Miles_Driven__c,Payment_Required__c, Payment_Type__c, isBreakdown__c
                                    ,D3_AAR_Id__c
                                FROM ServiceAppointments),
                                (SELECT Id,Name,Code__c,Description__c,Type__c 
                                FROM TroubleCodes__r), 
                                (SELECT Id,Name,RV_Class__c,RV_Length__c,Trailer_Hitchtype__c,Trailer_Length__c,Vehicle_Color__c,Vehicle_Drive_Type__c,Vehicle_Fuel_Type__c,Vehicle_Make__c,Vehicle_Model__c,
                                    Vehicle_Odometer__c,Vehicle_Special_Equipment_Needs__c,Vehicle_State__c,Vehicle_Tag__c,Vehicle_Trim__c,Vehicle_Type__c,Vehicle_VIN__c,Vehicle_Year__c,Work_Order__c 
                                FROM Member_Vehicles__r),
                                (SELECT Id,Name,Policy_Code__c,Policy_Description__c 
                                FROM Policies__r),
                                (SELECT Id,Name,CreatedBy.EmployeeNumber,FSL_Comment__c,FSL_Work_Order__c,createdDate  //kht: modified
                                FROM Call_Comments__r),
                                (SELECT Id,Cost__c,Unit__c, Product__c, Product__r.ProductCode 
                                FROM Service_Line_Items__r)
                            FROM WorkOrder] );
        workOrder = workOrders[0];

        assignedResources = ( [SELECT Id, ServiceAppointmentId, ServiceResourceId, 
                                    ServiceResource.Name,ServiceResource.LocationId, ServiceResource.Driver_Id__c, 
                                    ServiceResource.Vehicle__r.Truck_ID__c, 
                                    ServiceResource.Location.Longitude, ServiceResource.Location.Latitude, ServiceResource.Location.VIN__c
                                FROM AssignedResource] );

        feedItems = ( [SELECT Id, InsertedBy.Name, LastModifiedDate, ParentId, Type, Body 
                        FROM FeedItem 
                        WHERE TYPE = 'TextPost'] );
    }

    static testMethod void ValidateData() {
        // Test.startTest();
        LoadData();
        // Test.stopTest();
        
        System.assertEquals( 2, workOrder.ServiceAppointments.size() );
        System.assertEquals( 2, workOrder.TroubleCodes__r.size() );
        System.assertEquals( 2, workOrder.Policies__r.size() );
        System.assertEquals( 2, workOrder.Call_Comments__r.size() );
        System.assertEquals( 2, workOrder.Service_Line_Items__r.size() );
        System.assertEquals( 1, assignedResources.size() );
        System.assertEquals( 2, feedItems.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_IdMatchesPattern() {
        // Test.startTest();
        LoadData();
        Pattern guidPattern = Pattern.compile( '^\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}$' );
        String expected = 'CLEAR'; // Comes from the FSL_ServiceSettings__c object "Clear"

        workOrder.Call_Source__c = 'Salesforce1' ; 
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        System.debug('id is ' + clearJsonWorkOrder.id);
        System.assert( guidPattern.matcher( clearJsonWorkOrder.id ).matches() );
    }

    static testMethod void Wrap_SingleWorkOrder_MemberIdNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.memberId );
    }

    static testMethod void Wrap_SingleWorkOrder_ANINull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.ANI );
    }

    static testMethod void Wrap_SingleWorkOrder_RequestEventType() {
        // Test.startTest();
        LoadData();
        String expected = 'CLEAR'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.requestEventType );
    }

    static testMethod void Wrap_SingleWorkOrder_SubType() {
        // Test.startTest();
        LoadData();
        String expected = 'CLEAR'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.subType );
    }

    static testMethod void Wrap_SingleWorkOrder_Status() {
        // Test.startTest();
        LoadData();
        String expected = 'CL'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.status );
    }

    static testMethod void Wrap_SingleWorkOrder_Version() {
        // Test.startTest();
        LoadData();
        String expected = '1.0.0'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.version );
    }

    static testMethod void Wrap_SingleWorkOrder_SourceSystem_SystemId() {
        // Test.startTest();
        LoadData();
        String expected = 'Salesforce'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.sourceSystem.systemId );
    }

    static testMethod void Wrap_SingleWorkOrder_SourceSystem_SystemOrganization_Name() {
        // Test.startTest();
        LoadData();
        String expected = 'Salesforce'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.sourceSystem.systemOrganization.name );
    }

    static testMethod void Wrap_SingleWorkOrder_SourceSystem_SystemOrganization_Code() {
        // Test.startTest();
        LoadData();
        String expected = '014'; // Comes from the FSL_ServiceSettings__c object "Clear"

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.sourceSystem.systemOrganization.code );
    }

    static testMethod void Wrap_SingleWorkOrder_TargetSystem_SystemId() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.targetSystem.systemId );
    }

    static testMethod void Wrap_SingleWorkOrder_TargetSystem_SystemOrganization_Name() {
        // Test.startTest();
        LoadData();
        String expected = 'OrgName';
        workOrder.Call_Origin_OrgName__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.targetSystem.systemOrganization.name );
    }

    static testMethod void Wrap_SingleWorkOrder_TargetSystem_SystemOrganization_Code() {
        // Test.startTest();
        LoadData();
        String expected = 'OrgCode';
        workOrder.Call_Origin_OrgCode__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.targetSystem.systemOrganization.code );
    }

    static testMethod void Wrap_SingleWorkOrder_CreatedDate() {
        // Test.startTest();
        LoadData();
        Long expected = workOrder.CreatedDate.getTime();

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.createDate );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_SingleCallInList() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_CallKey() {
        // Test.startTest();
        LoadData();
        String expected = 'CallKey';
        workOrder.External_ID__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].callKey );
    }

    static testMethod void testConstuctCallKey_Success() {

        String clubCode = '014';
        String dateStr = '20220916';
        String callID = '123456';

        String callKey = wrapper.constructCallKey(clubCode, dateStr, callID);
        System.assertEquals('014-20220916-123456', callKey, 'Callkey not in 123-yyyymmdd-123456 Format');

        clubCode = '014';
        dateStr = '2022-09-16';
        callID = '123456';

        callKey = wrapper.constructCallKey(clubCode, dateStr, callID);
        System.assertEquals('014-20220916-123456', callKey, 'Callkey not in 123-yyyymmdd-123456 Format');

    }

    static testMethod void Wrap_SingleWorkOrder_Calls_CallDate() {
        // Test.startTest();
        LoadData();
        String expected = 'CallDate';
        workOrder.Call_Date__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].callDate );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_CallId() {
        // Test.startTest();
        LoadData();
        String expected = 'CallId';
        workOrder.Call_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].callId );
    }

    static testMethod void Wrap_SingleWorkOrder_AR_Calls_CallId() {
        // Test.startTest();
        LoadData();
        String expected =  workOrder.WorkOrderNumber;
        workOrder.Call_Id__c = expected;
        //workOrder.Call_Id__c = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].callId );
    }

    static testMethod void Wrap_SingleWorkOrder_AR_Calls_CallKey() {
        // Test.startTest();
        LoadData();
        //String expected = 'CallKey';
        
		Datetime createdDate = workOrder.CreatedDate;
        String month = String.valueOf(CreatedDate.month()).leftPad(2,'0');
        String day =  String.valueOf(CreatedDate.day()).leftPad(2,'0');
        string sdate = CreatedDate.year() + month  + day;
        string callid = workOrder.Service_Order_Number__c;
        string clubCode = '555';
        String expected = clubCode+'-'+sdate+'-'+callid;
        
		workOrder.External_ID__c = expected;
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].callKey );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_RequestingSystemCallId() {
        // Test.startTest();
        LoadData();
        String expected = 'RequestingSystemCallId';
        workOrder.RAP_Case_Number__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].requestingSystemCallId );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_VersionIs1() {
        // Test.startTest();
        LoadData();
        String expected = '1';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].version );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelType() {
        // Test.startTest();
        LoadData();
        String expected = 'Channel Type';
        workOrder.Call_Origin__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.channelType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_Org_Name() {
        // Test.startTest();
        LoadData();
        String expected = 'Salesforce';
        workOrder.Contact.Membership_Org__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.org.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_Org_Code() {
        // Test.startTest();
        LoadData();
        String expected = Label.FSL_SourceClubCode;
        workOrder.Contact.Membership_OrgCode__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.org.code );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelContact_UserId() {
        // Test.startTest();
        LoadData();
        String expected = 'User Id';
        workOrder.Responder_ID__c = expected;
        workOrder.Call_Source__c = 'D3' ; 

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.contact.userId );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelContact_ContactTypeIsAGENT() {
        // Test.startTest();
        LoadData();
        String expected = 'AGENT';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.contact.contactType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LatitudeIsNull() {
        // Test.startTest();
        LoadData();
        Double expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.latitude );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LongitudeIsNull() {
        // Test.startTest();
        LoadData();
        Double expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.longitude );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_AddressTypeIsPHYSICAL() {
        // Test.startTest();
        LoadData();
        String expected = 'PHYSICAL';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.addressType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_FullIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.full );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_StreetNumberIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.streetNumber );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_StreetDirectionIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.streetDirection );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_StreetNameIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.streetName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_CrossStreetIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.crossStreet );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_CityIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.city );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_CountyIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.county );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_StateIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.state );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_PostalCodeIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.postalCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Channel_ChannelLocation_LocationAddress_CountryIsEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].channel.location.address.country );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_SingleMembership() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_MembershipType() {
        // Test.startTest();
        LoadData();
        String membershipType = 'MEMBERSHIP TYPE';
        workOrder.Contact.Membership_Type__c = membershipType;
        String expected = 'MEMBER' ;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].membershipType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_Sponsor() {
        // Test.startTest();
        LoadData();
        String expected = 'Sponsor';
        workOrder.Contact.Membership_Sponsor__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].sponsor );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_Program() {
        // Test.startTest();
        LoadData();
        String expected = 'Program';
        workOrder.Contact.Membership_Program__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].program );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_AuthorizationCode() {
        // Test.startTest();
        LoadData();
        String expected = 'Authorization Code';
        workOrder.Contact.Membership_Code__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].authorizationCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_AuthorizationLevel() {
        // Test.startTest();
        LoadData();
        String expected = 'Authorization Level';
        workOrder.Contact.Membership_Authorization__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].authorizationLevel );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_IsLocalClub() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Contact.Membership_Islocalclub__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].isLocalClub );
    }

    /*static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_Org() {
        // Test.startTest();
        LoadData();

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( clearJsonWorkOrder.calls[0].channel.org, clearJsonWorkOrder.calls[0].customer.memberships[0].org );
    }*/

    static testMethod void Wrap_SingleWorkOrderWithMemberCardNumSet_Calls_Customer_Memberships_IdIsMemberCardNum() {
        // Test.startTest();
        LoadData();
        String expected = 'ID';
        workOrder.Contact.Member_Card_Num__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].id );
    }

    static testMethod void Wrap_SingleWorkOrderWithMemberCardNumEmpty_Calls_Customer_Memberships_IdIsOriginalMemberId() {
        // Test.startTest();
        LoadData();
        String expected = 'ID';
        workOrder.Contact.Member_Card_Num__c = expected; //''
        //workOrder.Original_Member_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].id );
    }

    static testMethod void Wrap_SingleWorkOrderWithMemberCardNumNull_Calls_Customer_Memberships_IdIsOriginalMemberId() {
        // Test.startTest();
        LoadData();
        String expected = 'ID';
        workOrder.Contact.Member_Card_Num__c = null;
        workOrder.Original_Member_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( Label.Non_MemberId, clearJsonWorkOrder.calls[0].customer.memberships[0].id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_OriginalMemberId() {
        // Test.startTest();
        LoadData();
        String expected = 'Original Member Id';
        workOrder.Contact.Member_Card_Num__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].originalMemberId );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_ExpirationDate() {
        // Test.startTest();
        LoadData();
        Date expirationDate = Date.today();
        String expected = String.Valueof( expirationDate );
        workOrder.Contact.Membership_Expiration_Date__c = expirationDate;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].expirationDate );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_MemberLevel() {
        // Test.startTest();
        LoadData();
        String expected = 'MEMBERLEVEL';
        workOrder.Contact.Membership_Level__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].memberLevel );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_MemberBirthday() {
        // Test.startTest();
        LoadData();
        String expected = null; //commented out in code
        workOrder.Contact.Membership_Birthday__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].memberBirthday );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_MemberSince() {
        // Test.startTest();
        LoadData();
        String expected = 'Member Since';
        workOrder.Contact.Membership_Since__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].memberSince );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_MemberStatus() {
        // Test.startTest();
        LoadData();
        String expected = 'Member Status';
        workOrder.Contact.Membership_Status__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].memberStatus );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_Entitlements_SingleItemInList() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].entitlements.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_Memberships_Entitlements_ServiceChargeIndicatorNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.memberships[0].entitlements[0].serviceChargeIndicator );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_ContactType() {
        // Test.startTest();
        LoadData();
        String expected = 'CONTACT TYPE';
        workOrder.Contact.Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.contactType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Title() {
        // Test.startTest();
        LoadData();
        String expected = 'Title';
        workOrder.Contact.Title = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.title );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_FirstName() {
        // Test.startTest();
        LoadData();
        String expected = 'First Name';
        workOrder.Contact.FirstName = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.firstName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_LastName() {
        // Test.startTest();
        LoadData();
        String expected = 'Last Name';
        workOrder.Contact.LastName = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.lastName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_PhonesHasSingleRecord() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
      
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Phone_PhoneType() {
        // Test.startTest();
        LoadData();
        String expected = 'PHONE TYPE';
        workOrder.Contact.Phone_Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
         
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones[0].phoneType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Phone_PhoneNumber() {
        // Test.startTest();
        LoadData();
        String expected = 'Phone Number';
        workOrder.Contact.Phone = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones[0].phoneNumber );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Phone_PhoneExtension() {
        // Test.startTest();
        LoadData();
        String expected = 'Phone Extension';
        workOrder.Contact.Phone_Extension__c = expected;
        
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        System.debug('clearJsonWorkOrder 956 ' + clearJsonWorkOrder);
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones[0].phoneExtension );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Phone_PreferredIsNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones[0].preferred );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_Phone_SmsOptIn() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Contact.Sms_Optin__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.phones[0].smsOptIn );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_EmailsHasSingleRecord() {
        // Test.startTest();
        LoadData();
       // workOrder.Contact.Email = 'test@gmail.com';
        Integer expected = 1;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.emails.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_CustomerEmail_EmailType() {
        // Test.startTest();
        LoadData();
        String expected = 'EMAIL TYPE';
      //  workOrder.Contact.Email = 'test@gmail.com';
        workOrder.Contact.Email_Type__c = expected;
		//System.debug('workOrder 999 ' + JSON.serialize(workOrder));
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        
        //System.debug('clearJsonWorkOrder 1002 -'+JSON.serialize(clearJsonWorkOrder.calls));
        // Test.stopTest();
           
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.emails[0].emailType );
        
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_CustomerContact_CustomerEmail_Address() {
        // Test.startTest();
        LoadData();
        String expected = 'Address';
        workOrder.Contact.Email = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.contact.emails[0].address );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Customer_LanguagePreference() {
        // Test.startTest();
        LoadData();
        String expected = 'Language Preference';
        workOrder.Contact.Language_Preference__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].customer.languagePreference );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_VehicleType() {
        // Test.startTest();
        LoadData();
        String expected = 'PS';
        workOrder.Member_Vehicles__r[0].Vehicle_Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.vehicleType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_YearIsNotNull() {
        // Test.startTest();
        LoadData();
        String year = '2020';
        Integer expected = Integer.Valueof( year );
        workOrder.Member_Vehicles__r[0].Vehicle_Year__c = year;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.year );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_YearIsNull() {
        // Test.startTest();
        LoadData();
        Integer expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.year );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Make() {
        // Test.startTest();
        LoadData();
        String expected = 'Make';
        workOrder.Member_Vehicles__r[0].Vehicle_Make__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.make );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Model() {
        // Test.startTest();
        LoadData();
        String expected = 'Model';
        workOrder.Member_Vehicles__r[0].Vehicle_Model__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.model );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Trim() {
        // Test.startTest();
        LoadData();
        String expected = 'Trim';
        workOrder.Member_Vehicles__r[0].Vehicle_Trim__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trim );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Color() {
        // Test.startTest();
        LoadData();
        String expected = 'Color';
        workOrder.Member_Vehicles__r[0].Vehicle_Color__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.color );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_DriveType() {
        // Test.startTest();
        LoadData();
        String expected = 'Drive Type';
        workOrder.Member_Vehicles__r[0].Vehicle_Drive_Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.driveType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Vin() {
        // Test.startTest();
        LoadData();
        String expected = 'Vin';
        workOrder.Member_Vehicles__r[0].Vehicle_Vin__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.vin );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_Tag() {
        // Test.startTest();
        LoadData();
        String expected = 'Tag';
        workOrder.Member_Vehicles__r[0].Vehicle_Tag__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.tag );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_State() {
        // Test.startTest();
        LoadData();
        String expected = 'State';
        workOrder.Member_Vehicles__r[0].Vehicle_State__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.state );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_OdometerIsNotNull() {
        // Test.startTest();
        LoadData();
        Decimal odometer = 123.00;
        Integer expected = Integer.Valueof( odometer );
        workOrder.Member_Vehicles__r[0].Vehicle_Odometer__c = odometer;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.odometer );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_OdometerIsNull() {
        // Test.startTest();
        LoadData();
        Integer expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.odometer );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_FuelType() {
        // Test.startTest();
        LoadData();
        String expected = 'Fuel Type';
        workOrder.Member_Vehicles__r[0].Vehicle_Fuel_Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.fuelType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_RvClass() {
        // Test.startTest();
        LoadData();
        String expected = 'RV Class';
        workOrder.Member_Vehicles__r[0].RV_Class__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.rvClass );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_EngineLocationIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.engineLocation );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_GooseNeckIsNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.gooseNeck );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_HeightIsNull() {
        // Test.startTest();
        LoadData();
        Double expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.height );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_Length() {
        // Test.startTest();
        LoadData();
        Double expected = 123.45;
        workOrder.Member_Vehicles__r[0].RV_Length__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.length );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_WeightIsNull() {
        // Test.startTest();
        LoadData();
        Integer expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.weight );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_TowingIsNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.towing );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_RvInfo_TowingTypeIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.rvInfo.towingType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_AxlesIsNull() {
        // Test.startTest();
        LoadData();
        Integer expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.axles );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_ConditionIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.condition );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_GooseNeckIsNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.gooseNeck );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_HitchSizeIsNull() {
        // Test.startTest();
        LoadData();
        Double expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.hitchSize );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_HitchType() {
        // Test.startTest();
        LoadData();
        String expected = 'Hitch Type';
        workOrder.Member_Vehicles__r[0].Trailer_Hitchtype__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.hitchType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_Length() {
        // Test.startTest();
        LoadData();
        Double expected = 123.45;
        workOrder.Member_Vehicles__r[0].Trailer_Length__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.length );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_LoadedIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.loaded );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_LoadTypeIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.loadType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_LoadWeightIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.loadWeight );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_PlugTypeIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.plugType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_TrailerInfo_TrailerTypeIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.trailerInfo.trailerType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Vehicle_SpecialEquipmentNeeds() {
        // Test.startTest();
        LoadData();
        String expected = 'Special Equipment Needs';
        workOrder.Member_Vehicles__r[0].Vehicle_Special_Equipment_Needs__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].vehicle.specialEquipmentNeeds );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_CallType() {
        // Test.startTest();
        LoadData();
        String expected = 'Call Type';
        workOrder.Call_Type__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.callType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TimezoneId() {
        // Test.startTest();
        LoadData();
        String expected = 'Timezone Id';
        workOrder.Timezone_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.timezoneId );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TimezoneOffset() {
        // Test.startTest();
        LoadData();
        String expected = 'Timezone Offset';
        workOrder.Timezone_Offset__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.timezoneOffset );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_Status() {
        // Test.startTest();
        LoadData();
       
        String expected = 'CL'; // Comes from the FSL_ServiceSettings__c object "Clear"
          System.debug('workOrder--1471='+workOrder);
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        System.debug('clearJsonWorkOrder--1473='+clearJsonWorkOrder);
        // Test.stopTest();
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.status );
       // System.assertEquals( workOrder.status, clearJsonWorkOrder.calls[0].service.status.status );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_ModifiedDateIsNotNull() {
        // Test.startTest();
        LoadData();
        DateTime modifiedDate = DateTime.now();
        String expected = String.valueOfGmt( DateTime.newInstanceGmt( modifiedDate.yearGmt(), modifiedDate.monthGmt(), modifiedDate.dayGmt(), modifiedDate.hourGmt(), modifiedDate.minuteGmt(), modifiedDate.secondGmt() ) ).replace( ' ', 'T' ) + 'Z';
        workOrder.Cleared_Timestamp__c = modifiedDate;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.modifiedDate );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_ModifiedDateIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.modifiedDate );
    }

   /* static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_Eta() {
        // Test.startTest();
        LoadData();
        String expected = 'ETA';
        workOrder.InitialETA_Legacy__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.eta );
    }*/
     static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_GlympseEta() {
        // Test.startTest();
        LoadData();
      //  String expected = 'ETA';
        DateTime eta = DateTime.now().addMinutes(15);
        String expectedETA = String.valueOfGmt( eta ).replace( ' ', 'T' ) + 'Z';
        String expectedScheduledStartTime = String.valueOfGmt( DateTime.now() ).replace( ' ', 'T' ) + 'Z';
        //workOrder.InitialETA_Legacy__c = expected;
        for ( ServiceAppointment sa : workOrder.ServiceAppointments ) {
           sa.Subject = 'Breakdown Appointment' ;
             // system.debug('####'+sa.ETA__c+ ' '+ sa.SchedStartTime+' '+sa.id+' '+sa.Subject);
               sa.ETA__c =eta;
                      
             sa.SchedStartTime=DateTime.now();
                
          
        }

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        //System.assertEquals( expectedETA, clearJsonWorkOrder.calls[0].service.status.eta );
        //System.assertEquals( expectedScheduledStartTime, clearJsonWorkOrder.calls[0].service.status.scheduleStartTime );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_PtaIsNotNull() {
        // Test.startTest();
        LoadData();
        DateTime pta = DateTime.now(); //added two hours to bypass the potenrial issue automation issue flow
        String expected = String.valueOfGmt( pta ).replace( ' ', 'T' ) + 'Z';
        workOrder.PTA__c = pta;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.pta );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_PtaIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.pta );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Status_WaitTime() {
        // Test.startTest();
        LoadData();
        Double waitTime = 123.45;
        Integer expected = Integer.valueOf( waitTime );
        workOrder.Wait_Time__c = waitTime;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.status.waitTime );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_AppointmentTime() {
        // Test.startTest();
        LoadData();
        String expected = 'Appointment Time';
        workOrder.Non_Emergency_Appointment_Time__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.appointmentTime );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_FoiTypeIsADDRESS() {
        // Test.startTest();
        LoadData();
        String expected = 'ADDRESS';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.foiType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_LocationIsNotNull() {
        // Test.startTest();
        LoadData();

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertNotEquals( null, clearJsonWorkOrder.calls[0].service.facility.location );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_IdFirstServiceAppointmentIsBreakdownAndIdIsNotBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Id';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
       // workOrder.ServiceAppointments[0].ServiceTerritory.Facility_Number__c = expected;
		ServiceTerritory st = new ServiceTerritory();
        st.id = workOrder.ServiceAppointments[0].ServiceTerritory.id;
        st.name = workOrder.ServiceAppointments[0].ServiceTerritory.name;
        st.Facility_Number__c = expected;
        
        workOrder.ServiceAppointments[0].ServiceTerritory = st;
        
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_IdSecondServiceAppointmentIsBreakdownAndIdIsNotBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Id';
        workOrder.ServiceAppointments[0].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].ServiceTerritory.Facility_Number__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_IdFirstServiceAppointmentIsBreakdownAndIdIsBlank() {
        // Test.startTest();
        LoadData();
         
        String expected = 'Facility Id';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        //workOrder.ServiceAppointments[0].ServiceTerritory.Facility_Number__c = '';
        ServiceTerritory st = new ServiceTerritory();
        st.id = workOrder.ServiceAppointments[0].ServiceTerritory.id;
        st.name = workOrder.ServiceAppointments[0].ServiceTerritory.name;
        st.Facility_Number__c = '';
        
        workOrder.ServiceAppointments[0].ServiceTerritory = st;
         
        workOrder.Account.Facility_ID__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_IdSecondServiceAppointmentIsBreakdownAndIdIsBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Id';
        workOrder.ServiceAppointments[0].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].ServiceTerritory.Facility_Number__c = '';
        workOrder.Account.Facility_ID__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_IdNoBreakdownServiceAppointment() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.id );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_NameFirstServiceAppointmentIsBreakdownAndIdIsNotBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Name';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        //workOrder.ServiceAppointments[0].ServiceTerritory.Facility_Number__c = 'Not Blank';
        //workOrder.ServiceAppointments[0].ServiceTerritory.name = expected;
        
         ServiceTerritory st = new ServiceTerritory();
        st.id = workOrder.ServiceAppointments[0].ServiceTerritory.id;
        st.name = expected;
        st.Facility_Number__c = 'Not Blank';
        
        workOrder.ServiceAppointments[0].ServiceTerritory = st;
       
        

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_NameSecondServiceAppointmentIsBreakdownAndIdIsNotBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Name';
        workOrder.ServiceAppointments[0].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].ServiceTerritory.Facility_Number__c = 'Not Blank';
        workOrder.ServiceAppointments[1].ServiceTerritory.name = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_NameFirstServiceAppointmentIsBreakdownAndIdIsBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Name';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        //workOrder.ServiceAppointments[0].ServiceTerritory.Facility_Number__c = '';
        ServiceTerritory st = new ServiceTerritory();
        st.id = workOrder.ServiceAppointments[0].ServiceTerritory.id;
        st.name = workOrder.ServiceAppointments[0].ServiceTerritory.name;
        st.Facility_Number__c = '';
        
        workOrder.ServiceAppointments[0].ServiceTerritory = st;
        workOrder.Account.Name = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_NameSecondServiceAppointmentIsBreakdownAndIdIsBlank() {
        // Test.startTest();
        LoadData();
        String expected = 'Facility Name';
        workOrder.ServiceAppointments[0].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].ServiceTerritory.Facility_Number__c = '';
        workOrder.Account.Name = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Facility_NameNoBreakdownServiceAppointment() {
        // Test.startTest();
        LoadData();
        String expected = null;
        workOrder.ServiceAppointments[0].Subject = 'Not Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Not Breakdown Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.facility.name );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResourceAndStatusIsSpotted_Calls_Service_TruckIsNull() {
        // Test.startTest();
        LoadData();
        FSL_ClearJsonWorkOrder.Truck expected = null;
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.Status = 'Spotted';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentDoesNotHaveAssignedResourceAndStatusIsSpotted_Calls_Service_TruckIsNotNull() {
        // Test.startTest();
        LoadData();
        FSL_ClearJsonWorkOrder.Truck expected = null;
        workOrder.Status = 'Spotted';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertNotEquals( expected, clearJsonWorkOrder.calls[0].service.truck );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentDoesntHaveAssignedResource_Calls_Service_Truck_IdEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResource_Calls_Service_Truck_Id() {
        // Test.startTest();
        LoadData();
        String expected = 'Truck Id';
        assignedResources[0].ServiceResource.Vehicle__r.Truck_ID__c = expected;
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.status = 'In Progress' ;
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest(); 
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentDoesntHaveAssignedResource_Calls_Service_Truck_Driver_IdEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResourceAndDriverIdNotBlank_Calls_Service_Truck_Driver_Id() {
        // Test.startTest();
        LoadData();
        String expected = 'Driver Id';
        assignedResources[0].ServiceResource.Driver_Id__c = expected;
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.status = 'In Progress' ; 

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResourceAndDriverIdBlank_Calls_Service_Truck_Driver_IdEmpty() {
        // Test.startTest();
        LoadData();
        String expected = '';
        assignedResources[0].ServiceResource.Driver_Id__c = null;
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.status = 'In Progress' ; 
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentDoesntHaveAssignedResource_Calls_Service_Truck_Driver_ContactNull() {
        // Test.startTest();
        LoadData();
        FSL_ClearJsonWorkOrder.Driver_Contact expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.contact );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResource_Calls_Service_Truck_Driver_Contact_ContactTypeIsDRIVER() {
        // Test.startTest();
        LoadData();
        String expected = 'DRIVER';
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.status = 'In Progress' ; 

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.contact.contactType );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAssignedResource_Calls_Service_Truck_Driver_Contact_LastName() {
        // Test.startTest();
        LoadData();
        String expected = 'Last Name';
        assignedResources[0].ServiceResource.Name = expected;
        serviceAppointmentIdToAssignedResourceMap.put( WorkOrder.ServiceAppointments[0].Id, assignedResources[0] );
        workOrder.status = 'In Progress' ;  
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.truck.driver.contact.lastName );
    }

    static testMethod void Wrap_SingleWorkOrderAndWorkOrderHasTwoTroubleCodesAndResolutionCodeIsNull_Calls_Service_TroubleCodesContainsTwoItems() {
        // Test.startTest();
        LoadData();
        Integer expected = 2;
        WorkOrder.Resolution_Code__c = null;
        WorkOrder.Clearing_Code__c = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.troubleCodes.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndWorkOrderHasTwoTroubleCodesAndResolutionCodeIsNotNull_Calls_Service_TroubleCodesContainsThreeItems() {
        // Test.startTest();
        LoadData();
        Integer expected = 4;
        WorkOrder.Resolution_Code__c = 'Not Null';
        WorkOrder.Call_Origin__c = 'Salesforce';
        WorkOrder.Clearing_Code__c = 'Not Null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.troubleCodes.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndWorkOrderHasTwoTroubleCodesAndResolutionCodeIsNotNull_Calls_Service_TroubleCodes_TroubleCodeType() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Trouble Code 1';
        String expected2 = 'Trouble Code 2';
        String expected3 = 'RESOLUTION';
        workOrder.TroubleCodes__r[0].Type__c = expected1;
        workOrder.TroubleCodes__r[1].Type__c = expected2;
        WorkOrder.Resolution_Code__c = 'Not Null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.troubleCodes[0].troubleCodeType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.troubleCodes[1].troubleCodeType );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].service.troubleCodes[2].troubleCodeType );
    }

    static testMethod void Wrap_SingleWorkOrderAndWorkOrderHasTwoTroubleCodesAndResolutionCodeIsNotNull_Calls_Service_TroubleCodes_Code() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Code 1';
        String expected2 = 'Code 2';
        String expected3 = 'Code 3';
        workOrder.TroubleCodes__r[0].Code__c = expected1;
        workOrder.TroubleCodes__r[1].Code__c = expected2;
        WorkOrder.Resolution_Code__c = expected3;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.troubleCodes[0].code );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.troubleCodes[1].code );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].service.troubleCodes[2].code );
    }

    static testMethod void Wrap_SingleWorkOrderAndWorkOrderHasTwoTroubleCodesAndResolutionCodeIsNotNull_Calls_Service_TroubleCodes_Description() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Description 1';
        String expected2 = 'Description 2';
        String expected3 = '';
        workOrder.TroubleCodes__r[0].Description__c = expected1;
        workOrder.TroubleCodes__r[1].Description__c = expected2;
        WorkOrder.Resolution_Code__c = 'Not Null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.troubleCodes[0].description );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.troubleCodes[1].description );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].service.troubleCodes[2].description );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_ServiceLocationType() {
        // Test.startTest();
        LoadData();
        String expected1 = 'BREAKDOWN';
        String expected2 = 'TOW_DESTINATION';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].serviceLocationType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].serviceLocationType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_FoiTypeIsADDRESS() {
        // Test.startTest();
        LoadData();
        String expected1 = 'ADDRESS';
        String expected2 = 'ADDRESS';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.foiType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.foiType );
    }

    static testMethod void Wrap_SingleWorkOrder_WithAARIDAndTowAppointment_Calls_Service_TroubleCodes_ServiceLocations_Foi_FoiTypeIsAAR() {
        LoadData();
        String expected1 = 'ADDRESS';
        String expected2 = 'AAR';
        String expectedId = '12345';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].D3_AAR_Id__c = expectedId;
        workOrder.ServiceAppointments[1].Address_Change_Counter__c = 0;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.foiType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.foiType );
        System.assertEquals( expectedId, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.id );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasNoAddressChanges_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Latitude() {
        // Test.startTest();
        LoadData();
        Double expected1 = 123.45;
        Double expected2 = 987.65;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Address_Change_Counter__c = 0;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Address_Change_Counter__c = 0;
        workOrder.Breakdown_Location__Latitude__s = expected1;
        workOrder.Tow_Location__Latitude__s = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.latitude );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.latitude );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasNoAddressChanges_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Longitude() {
        // Test.startTest();
        LoadData();
        Double expected1 = 123.45;
        Double expected2 = 987.65;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Address_Change_Counter__c = 0;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Address_Change_Counter__c = 0;
        workOrder.Breakdown_Location__Longitude__s = expected1;
        workOrder.Tow_Location__Longitude__s = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.longitude );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.longitude );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAddressChanges_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Latitude() {
        // Test.startTest();
        LoadData();
        Double expected1 = 123.45;
        Double expected2 = 987.65;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Address_Change_Counter__c = 1;
        workOrder.ServiceAppointments[0].Latitude = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Address_Change_Counter__c = 1;
        workOrder.ServiceAppointments[1].Latitude = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.latitude );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.latitude );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceAppointmentHasAddressChanges_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Longitude() {
        // Test.startTest();
        LoadData();
        Double expected1 = 123.45;
        Double expected2 = 987.65;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Address_Change_Counter__c = 1;
        workOrder.ServiceAppointments[0].Longitude = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Address_Change_Counter__c = 1;
        workOrder.ServiceAppointments[1].Longitude = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.longitude );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.longitude );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_AddressTypeIsPHYSICAL() {
        // Test.startTest();
        LoadData();
        String expected1 = 'PHYSICAL';
        String expected2 = 'PHYSICAL';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.addressType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.addressType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_Full() {
        // Test.startTest();
        LoadData();
        String street1 = 'Street 1';
        String city1 = 'City 1';
        String state1 = 'State 1';
        String postalCode1 = 'Postal Code 1';
        String country1 = 'Country 1';
        String expected1 = street1 + ' ' + city1 + ', ' + state1 + ' ' + postalCode1 + ' ' + country1;
        String street2 = 'Street 2';
        String city2 = 'City 2';
        String state2 = 'State 2';
        String postalCode2 = 'Postal Code 2';
        String country2 = 'Country 2';
        String expected2 = street2 + ' ' + city2 + ', ' + state2 + ' ' + postalCode2 + ' ' + country2;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Street = street1;
        workOrder.ServiceAppointments[0].City = city1;
        workOrder.ServiceAppointments[0].State = state1;
        workOrder.ServiceAppointments[0].PostalCode = postalCode1;
        workOrder.ServiceAppointments[0].Country = country1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Street = street2;
        workOrder.ServiceAppointments[1].City = city2;
        workOrder.ServiceAppointments[1].State = state2;
        workOrder.ServiceAppointments[1].PostalCode = postalCode2;
        workOrder.ServiceAppointments[1].Country = country2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.full );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.full );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_StreetNumberIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = '';
        String expected2 = '';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.streetNumber );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.streetNumber );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_StreetDirectionIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.streetDirection );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.streetDirection );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_StreetName() {
        // Test.startTest();
        LoadData();
        String expected1 = '1';
        String expected2 = '2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Street = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Street = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        //System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.streetName );
        //System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.streetName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_CrossStreet() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Cross Street 1';
        String expected2 = 'Cross Street 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Cross_Street__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Cross_Street__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.crossStreet );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.crossStreet );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_CrossStreet2() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Cross Street 2-1';
        String expected2 = 'Cross Street 2-2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Cross_Street_2__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Cross_Street_2__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.crossStreet2 );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.crossStreet2 );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_City() {
        // Test.startTest();
        LoadData();
        String expected1 = 'City 1';
        String expected2 = 'City 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].City = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].City = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.city );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.city );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_CountyIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.county );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.county );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_State() {
        // Test.startTest();
        LoadData();
        String expected1 = 'State 1';
        String expected2 = 'State 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].State = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].State = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.state );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.state );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_PostalCode() {
        // Test.startTest();
        LoadData();
        String expected1 = 'State 1';
        String expected2 = 'State 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].PostalCode = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].PostalCode = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.postalCode );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.postalCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_Country() {
        // Test.startTest();
        LoadData();
        String expected1 = 'State 1';
        String expected2 = 'State 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Country = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Country = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.country );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.country );
    }

    static testMethod void Wrap_SingleWorkOrderAndCountryIsUnitedStates_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Address_CountryIsUSA() {
        // Test.startTest();
        LoadData();
        String expected1 = 'USA';
        String expected2 = 'USA';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Country = 'United States';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Country = 'United States';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.address.country );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.address.country );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Landmark() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Landmark 1';
        String expected2 = 'Landmark 2';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Landmark__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Landmark__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.landmark );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.landmark );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_Highway() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Highway';
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Highway__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.highway );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.highway );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_MileMarker() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Mile Marker';
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Mile_Marker__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.mileMarker );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.mileMarker );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_GridIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.grid );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.grid );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_ZoneIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.zone );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.zone );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_BreakdownLocation_LocationCode() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Location Code';
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].Location_Code__c = expected1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.location.locationCode );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.location.locationCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Name() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = 'Name';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Tow_Destination_Name__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.name );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.name );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_ContactsSize() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( null, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.contacts );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_ContactTypeIsTOWDEST() {
        // Test.startTest();
        LoadData();
        String expected = 'TOWDEST';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].contactType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_FirstName() {
        // Test.startTest();
        LoadData();
        String expected = 'First Name';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_First_Name__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].firstName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_LastName() {
        // Test.startTest();
        LoadData();
        String expected = 'Last Name';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_Last_Name__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].lastName );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_PhonesContainsOneItem() {
        // Test.startTest();
        LoadData();
        Integer expected = 1;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_Phone_Number__c = 'Not null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].phones.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndTwoContactPhoneNumberIsNull_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_PhonesIsNull() {
        // Test.startTest();
        LoadData();
        List<FSL_ClearJsonWorkOrder.Contact_Phones> expected = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].phones );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_Phones_PhoneTypeIsBUSINESS() {
        // Test.startTest();
        LoadData();
        String expected = 'BUSINESS';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_Phone_Number__c = 'Not null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].phones[0].phoneType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_Phones_PhoneNumber() {
        // Test.startTest();
        LoadData();
        String expected = 'Phone Number';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_Phone_Number__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].phones[0].phoneNumber );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_Foi_Contacts_Phones_PreferredIsNull() {
        // Test.startTest();
        LoadData();
        Boolean expected = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.Tow_Contact_Phone_Number__c = 'Not null';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.contacts[0].phones[0].preferred );
    }

    static testMethod void Wrap_SingleWorkOrderWithActualMilesDrivenNull_Calls_Service_TroubleCodes_ServiceLocations_MileageCalculatedIsNull() {
        // Test.startTest();
        LoadData();
        Decimal milesDriven1 = null;
        Decimal milesDriven2 = null;
        Integer expected1 = null;
        Integer expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].FSL_Actual_Miles_Driven__c = milesDriven1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].FSL_Actual_Miles_Driven__c = milesDriven2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].mileageCalculated );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].mileageCalculated );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_MileageCalculated() {
        // Test.startTest();
        LoadData();
        Decimal milesDriven1 = 123.45;
        Decimal milesDriven2 = 543.21;
        Integer expected1 = milesDriven1.round( System.RoundingMode.HALF_UP ).intValue();
        Integer expected2 = milesDriven2.round( System.RoundingMode.HALF_UP ).intValue();
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].FSL_Actual_Miles_Driven__c = milesDriven1;
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].FSL_Actual_Miles_Driven__c = milesDriven2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].mileageCalculated );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].mileageCalculated );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_DriverDirectionsIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].driverDirections );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].driverDirections );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_TroubleCodes_ServiceLocations_DropBoxInfo() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = 'Drop Box Info';
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[1].Subject = 'Tow Appointment';
        workOrder.ServiceAppointments[1].Drop_Box_Info__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].dropBoxInfo );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].dropBoxInfo );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Collision() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Collision__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.collision );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_RedFlag() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Red_Flag__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.redFlag );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_PriorityCode() {
        // Test.startTest();
        LoadData();
        String expected = 'Priority Code';
        workOrder.Priority_Code__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.priorityCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_LegacyPriorityCode() {
        // Test.startTest();
        LoadData();
        String expected = 'Legacy Priority Code';
        workOrder.Legacy_Priority_Code__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.legacyPriorityCode );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_NumberOfPassengers() {
        // Test.startTest();
        LoadData();
        Double numberOfPassengers = 123.45;
        Integer expected = (Integer)numberOfPassengers;
        workOrder.Number_Of_Passengers__c = numberOfPassengers;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.numberOfPassengers );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_NeedsFlatbed() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Needs_Flatbed__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.needsFlatbed );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_FlatbedRequested() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        workOrder.Flatbed_Requested__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.flatbedRequested );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_PoliciesSize() {
        // Test.startTest();
        LoadData();
        Integer expected = 2;

        String expected1 = 'Code 1';
        String expected2 = 'Code 2';
        workOrder.Policies__r[0].Policy_Code__c = expected1;
        workOrder.Policies__r[1].Policy_Code__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.policies.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Policies_Code() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Code 1';
        String expected2 = 'Code 2';
        workOrder.Policies__r[0].Policy_Code__c = expected1;
        workOrder.Policies__r[1].Policy_Code__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.policies[0].code );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_Policies_Description() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Description 1';
        String expected2 = 'Description 2';
        workOrder.Policies__r[0].Policy_Description__c = expected1;
        workOrder.Policies__r[0].Policy_Code__c = expected1;
        workOrder.Policies__r[1].Policy_Description__c = expected2;
        workOrder.Policies__r[1].Policy_Code__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.policies[0].description );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_ProvidedServicesSize() {
        // Test.startTest();
        LoadData();
        Integer expected = 2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].service.providedServices.size() );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_ProvidedServices_ProvidedServiceTypeNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].providedServiceType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].providedServiceType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_ProvidedServices_Service() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Service 1';
        String expected2 = 'Service 2';
        workOrder.Service_Line_Items__r[0].Product__r.ProductCode = expected1;
        workOrder.Service_Line_Items__r[1].Product__r.ProductCode = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].service );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].service );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_ProvidedServices_UnitNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].unit );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].unit );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Service_ProvidedServices_Quantity() {
        // Test.startTest();
        LoadData();
        Double quantity1 = 123.45;
        Double quantity2 = 987.54;
        Integer expected1 = Integer.valueOf( quantity1 );
        Integer expected2 = Integer.valueOf( quantity2 );
        workOrder.Service_Line_Items__r[0].Unit__c = expected1;
        workOrder.Service_Line_Items__r[1].Unit__c = expected2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].quantity );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].quantity );
    }

    static testMethod void Wrap_SingleWorkOrderAndUnitIsNull_Calls_Service_ProvidedServices_QuantityIsZero() {
        // Test.startTest();
        LoadData();
        Integer expected1 = 0;
        Integer expected2 = 0;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].quantity );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].quantity );
    }

    static testMethod void Wrap_SingleWorkOrderAndUnitIsNull_Calls_Service_ProvidedServices_Charge_ChargeTypeIsNull() {
        // Test.startTest();
        LoadData();
        String expected1 = null;
        String expected2 = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].charge.chargeType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].charge.chargeType );
    }

    static testMethod void Wrap_SingleWorkOrderAndUnitIsNull_Calls_Service_ProvidedServices_Charge_Amount() {
        // Test.startTest();
        LoadData();
        Decimal cost1 = 123.45;
        Decimal cost2 = 987.65;
        String expected1 = String.Valueof( cost1 );
        String expected2 = String.Valueof( cost2 );
        workOrder.Service_Line_Items__r[0].Cost__c = cost1;
        workOrder.Service_Line_Items__r[1].Cost__c = cost2;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.providedServices[0].charge.amount );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.providedServices[1].charge.amount );
    }

    static testMethod void Wrap_SingleWorkOrderAndUnitIsNull_Calls_Service_ChargesIsNull() {
        // Test.startTest();
        LoadData();

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( null, clearJsonWorkOrder.calls[0].service.charges );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Payment_Required() {
        // Test.startTest();
        LoadData();
        Boolean expected = true;
        for(ServiceAppointment sa: workOrder.ServiceAppointments){
            if(sa.isBreakdown__c){
                sa.Payment_Required__c = expected;
            }
        }

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].payment.required );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Payment_PaymentType() {
        // Test.startTest();
        LoadData();
        String expected = 'Payment Type';
        for(ServiceAppointment sa: workOrder.ServiceAppointments){
            if(sa.isBreakdown__c){
               
                sa.Payment_Type__c = expected;
                 System.debug('2900 Panda++' + sa.Payment_Type__c);
            }
        }

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        System.debug('clearJsonWorkOrder.calls[0]' + JSON.serialize(clearJsonWorkOrder.calls[0]));
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].payment.paymentType );
    }

    static testMethod void Wrap_SingleWorkOrder_Calls_Payment_Codes() {
        // Test.startTest();
        LoadData();
        String expected = 'Codes';
        workOrder.Payment_Codes__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].payment.codes );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsIVRLookup_Calls_Payment_CommentsIsNull() {
        // Test.startTest();
        LoadData();
        serviceName = 'IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( null, clearJsonWorkOrder.calls[0].comments );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_CommentsHas4Items() {
        // Test.startTest();
        LoadData();
        Integer expected = 4; // 2 from comments, 2 from feed
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_SystemZIsSourceSystem() {
        // Test.startTest();
        LoadData();
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( clearJsonWorkOrder.sourceSystem, clearJsonWorkOrder.calls[0].comments[0].system_Z );
        System.assertEquals( clearJsonWorkOrder.sourceSystem, clearJsonWorkOrder.calls[0].comments[1].system_Z );
        System.assertEquals( clearJsonWorkOrder.sourceSystem, clearJsonWorkOrder.calls[0].comments[2].system_Z );
        System.assertEquals( clearJsonWorkOrder.sourceSystem, clearJsonWorkOrder.calls[0].comments[3].system_Z );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_Contact_UserId() {
        // Test.startTest();
        LoadData();
        String expected1 = 'User ID';
        String expected2 = 'User ID';
        String expected3 = FSL_WorkOrderD3JsonWrapper.DEFAULT_USER_ID;
        String expected4 = FSL_WorkOrderD3JsonWrapper.DEFAULT_USER_ID;
        workOrder.Call_Comments__r[0].CreatedBy.EmployeeNumber = expected1;
        // workOrder.Call_Comments__r[1].CreatedBy.EmployeeNumber = expected2; // Same user as above, updating one will update the other
        //feedItems[0].InsertedBy.Name = expected3; // InsertedBy.Name is not updateable
        //feedItems[1].InsertedBy.Name = expected4; // InsertedBy.Name is not updateable
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].comments[0].contact.userId );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].comments[1].contact.userId );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].comments[2].contact.userId );
        System.assertEquals( expected4, clearJsonWorkOrder.calls[0].comments[3].contact.userId );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookupAndEmployeeIdIsNull_Calls_Payment_Comments_Contact_UserIdIsS999999() {
        // Test.startTest();
        LoadData();
        String expected = 'S999999';
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[0].contact.userId );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[1].contact.userId );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_Contact_ContactType() {
        // Test.startTest();
        LoadData();
        String expected = 'SYSTEM';
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[0].contact.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[1].contact.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[2].contact.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[3].contact.contactType );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookupAndCommendCreatedDateIsNullAndFeedLastModifiedDateIsNull_Calls_Payment_Comments_CommentDateIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        // Call Comments have a CreatedDate, Feed Items have their LastModifiedDate. Both fields are not writeable and not null. Null check is probably useless
        // System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[0].commentDate );
        // System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[1].commentDate );
        // System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[2].commentDate );
        // System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[3].commentDate );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookupAndCommendCreatedDateIsNotNullAndFeedLastModifiedDateIsNotNull_Calls_Payment_Comments_CommentDate() {
        // Test.startTest();
        LoadData();
        String expected1 = workOrder.Call_Comments__r[0].CreatedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expected2 = workOrder.Call_Comments__r[1].CreatedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expected3 = feedItems[0].LastModifiedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expected4 = feedItems[1].LastModifiedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].comments[0].commentDate );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].comments[1].commentDate );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].comments[2].commentDate );
        System.assertEquals( expected4, clearJsonWorkOrder.calls[0].comments[3].commentDate );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_CommentTypeIsNORMAL() {
        // Test.startTest();
        LoadData();
        String expected = 'NORMAL';
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[0].commentType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[1].commentType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[2].commentType );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[3].commentType );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_VisibilityIsEXTERNAL() {
        // Test.startTest();
        LoadData();
        String expected = 'EXTERNAL';
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[0].visibility );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[1].visibility );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[2].visibility );
        System.assertEquals( expected, clearJsonWorkOrder.calls[0].comments[3].visibility );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsNotIVRLookup_Calls_Payment_Comments_Text() {
        // Test.startTest();
        LoadData();
        String expected1 = 'Text 1';
        String expected2 = 'Text 2';
        String expected3 = 'Text 3';
        String expected4 = 'Text 4';
        workOrder.Call_Comments__r[0].FSL_Comment__c = expected1;
        workOrder.Call_Comments__r[1].FSL_Comment__c = expected2;
        feedItems[0].Body = expected3;
        feedItems[1].Body = expected4;
        workOrderIdToFeedItemsMap.put( workOrder.Id, feedItems );
        serviceName = 'Not IVRLookup';

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].comments[0].text );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].comments[1].text );
        System.assertEquals( expected3, clearJsonWorkOrder.calls[0].comments[2].text );
        System.assertEquals( expected4, clearJsonWorkOrder.calls[0].comments[3].text );
    }

    static testMethod void Wrap_SingleWorkOrder_RespWrapIsNull() {
        // Test.startTest();
        LoadData();
        FSL_ClearJsonWorkOrder.ResponseWrapper expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.respWrap );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndWorkOrderIsTowType_CallEventsHas6Items() {
        // Test.startTest();
        LoadData();
        Integer expected = 7;
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndWorkOrderIsNotTowType_CallEventsHas5Items() {
        // Test.startTest();
        LoadData();
        Integer expected = 6;
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = false;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents.size() );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_CallKey() {
        // Test.startTest();
        LoadData();
        String expected = 'Call Key';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.External_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[0].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[1].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[2].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[3].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[4].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[5].callKey );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[6].callKey );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_CallDate() {
        // Test.startTest();
        LoadData();
        String expected = 'Call Date';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Call_Date__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[0].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[1].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[2].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[3].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[4].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[5].callDate );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[6].callDate );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_CallId() {
        // Test.startTest();
        LoadData();
        String expected = 'Call ID';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Call_Id__c = expected;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[0].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[1].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[2].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[3].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[4].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[5].callId );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[6].callId );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndTimesAreNotNull_CallEvents_EventTime() {
        // Test.startTest();
        LoadData();
        Datetime spottedTime = Datetime.now().addHours( -7 );
        Datetime expected1 = Datetime.newInstanceGmt( spottedTime.yearGmt(), spottedTime.monthGmt(), spottedTime.dayGmt(), spottedTime.hourGmt(), spottedTime.minuteGmt(), spottedTime.secondGmt() );
        Datetime scheduledTime = Datetime.now().addHours( -6 );
        Datetime expected2 = Datetime.newInstanceGmt( scheduledTime.yearGmt(), scheduledTime.monthGmt(), scheduledTime.dayGmt(), scheduledTime.hourGmt(), scheduledTime.minuteGmt(), scheduledTime.secondGmt() );
        Datetime dispatchedTime = Datetime.now().addHours( -5 );
        Datetime expected3 = Datetime.newInstanceGmt( dispatchedTime.yearGmt(), dispatchedTime.monthGmt(), dispatchedTime.dayGmt(), dispatchedTime.hourGmt(), dispatchedTime.minuteGmt(), dispatchedTime.secondGmt() );
        Datetime enrouteTime = Datetime.now().addHours( -4 );
        Datetime expected4 = Datetime.newInstanceGmt( enrouteTime.yearGmt(), enrouteTime.monthGmt(), enrouteTime.dayGmt(), enrouteTime.hourGmt(), enrouteTime.minuteGmt(), enrouteTime.secondGmt() );
        Datetime onLocationTime = Datetime.now().addHours( -3 );
        Datetime expected5 = Datetime.newInstanceGmt( onLocationTime.yearGmt(), onLocationTime.monthGmt(), onLocationTime.dayGmt(), onLocationTime.hourGmt(), onLocationTime.minuteGmt(), onLocationTime.secondGmt() );
        Datetime inTowTime = Datetime.now().addHours( -2 );
        Datetime expected6 = Datetime.newInstanceGmt( inTowTime.yearGmt(), inTowTime.monthGmt(), inTowTime.dayGmt(), inTowTime.hourGmt(), inTowTime.minuteGmt(), inTowTime.secondGmt() );
        Datetime clearedTime = Datetime.now().addHours( -1 );
        Datetime expected7 = Datetime.newInstanceGmt( clearedTime.yearGmt(), clearedTime.monthGmt(), clearedTime.dayGmt(), clearedTime.hourGmt(), clearedTime.minuteGmt(), clearedTime.secondGmt() );
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = spottedTime;
        workOrder.Scheduled_Timestamp__c = scheduledTime;
        workOrder.Dispatched_Timestamp__c = dispatchedTime;
        workOrder.Enroute_Timestamp__c = enrouteTime;
        workOrder.On_Location_Timestamp__c = onLocationTime;
        workOrder.In_Tow_Timestamp__c = inTowTime;
        workOrder.Cleared_Timestamp__c = clearedTime;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.callEvents[0].eventTime );
        System.assertEquals( expected2, clearJsonWorkOrder.callEvents[1].eventTime );
        System.assertEquals( expected3, clearJsonWorkOrder.callEvents[2].eventTime );
        System.assertEquals( expected4, clearJsonWorkOrder.callEvents[3].eventTime );
        System.assertEquals( expected5, clearJsonWorkOrder.callEvents[4].eventTime );
        System.assertEquals( expected6, clearJsonWorkOrder.callEvents[5].eventTime );
        System.assertEquals( expected7, clearJsonWorkOrder.callEvents[6].eventTime );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndEnRouteIsNotNullAndOnLocationIsNull_CallEvents_EventTimeOnlocationTimeIsOneSecondAfterEnRouteTime() {
        // Test.startTest();
        LoadData();
        Datetime spottedTime = Datetime.now().addHours( -7 );         
        Datetime enrouteTime = Datetime.now().addHours( -4 );
        Datetime expectedEnrouteTime = Datetime.newInstanceGmt( enrouteTime.yearGmt(), enrouteTime.monthGmt(), enrouteTime.dayGmt(), enrouteTime.hourGmt(), enrouteTime.minuteGmt(), enrouteTime.secondGmt() );
        Datetime expectedOnLocationTime = expectedEnrouteTime.addSeconds(1);
        
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = spottedTime;      
        workOrder.Enroute_Timestamp__c = enrouteTime;
        workOrder.On_Location_Timestamp__c = null;
       
        
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();        
        
        System.assertEquals( expectedEnRouteTime, clearJsonWorkOrder.callEvents[3].eventTime, 'En Route time does not match the expected value' );
        System.assertEquals( expectedOnLocationTime, clearJsonWorkOrder.callEvents[4].eventTime, 'On Location time does not match the expected value' );
        
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndDispatchTimeIsNotNullAndEnRouteIsNullAndOnLocationIsNull_CallEvents_EventTimeOnlocationTimeIsOneSecondAfterDispatchTime() {
        // Test.startTest();
        //DI to CL requires ER to be inserted with a time 1 second after DI, and OL to be inserted with a time 1 second after ER,
        // and CL shall be the time entered by the user.

        LoadData();
        Datetime spottedTime = Datetime.now().addHours( -7 );     
        Datetime dispatchedTime = Datetime.now().addHours( -5 );
        Datetime expectedDispatchedTime = Datetime.newInstanceGmt( dispatchedTime.yearGmt(), dispatchedTime.monthGmt(), dispatchedTime.dayGmt(), dispatchedTime.hourGmt(), dispatchedTime.minuteGmt(), dispatchedTime.secondGmt() );
        Datetime expectedEnrouteTime = expectedDispatchedTime.addSeconds(1);
        Datetime expectedOnLocationTime = expectedEnrouteTime.addSeconds(1);
      
        
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = spottedTime;  
        workorder.Dispatched_Timestamp__c=dispatchedTime;    
        workOrder.Enroute_Timestamp__c = null;
        workOrder.On_Location_Timestamp__c = null;
       
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();        
        
        System.assertEquals( expectedDispatchedTime, clearJsonWorkOrder.callEvents[2].eventTime, 'Dispatch time does not match the expected value' );
        System.assertEquals( expectedEnrouteTime, clearJsonWorkOrder.callEvents[3].eventTime, 'EnRoute time does not match the expected value' );
        System.assertEquals( expectedOnLocationTime, clearJsonWorkOrder.callEvents[4].eventTime, 'On Location time does not match the expected value' );
        
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndScheduleTimeIsNotNullAndDisPatchedIsNullAndEnRouteIsNullAndOnLocationIsNull_CallEvents_EventTimeOnlocationTimeIsOneSecondAfterScheduleTime() {
        // Test.startTest();
        // AS to CL requires DI to be inserted with a time 1 second after AS,  ER to be inserted with a time 1 second after DI, 
        //and OL to be inserted with a time 1 second after ER, and CL shall be the time entered by the user.

        LoadData();
        Datetime spottedTime = Datetime.now().addHours( -7 );           
        Datetime scheduledTime = Datetime.now().addHours( -6 );
        Datetime expectedScheduledTime = Datetime.newInstanceGmt( scheduledTime.yearGmt(), scheduledTime.monthGmt(), scheduledTime.dayGmt(), scheduledTime.hourGmt(), scheduledTime.minuteGmt(), scheduledTime.secondGmt() );       
        Datetime expectedDispatchedTime = expectedScheduledTime.addSeconds(1);
        Datetime expectedEnrouteTime = expectedDispatchedTime.addSeconds(1);
        Datetime expectedOnLocationTime = expectedEnrouteTime.addSeconds(1);

                 
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = spottedTime;  
        workOrder.Scheduled_Timestamp__c = scheduledTime;

        workorder.Dispatched_Timestamp__c = null;    
        workOrder.Enroute_Timestamp__c = null;
        workOrder.On_Location_Timestamp__c = null;
              
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();  
        
      
        System.assertEquals( expectedScheduledTime, clearJsonWorkOrder.callEvents[1].eventTime, 'Scheduled time does not match the expected value' );
        System.assertEquals( expectedDispatchedTime, clearJsonWorkOrder.callEvents[2].eventTime, 'Dispatched time does not match the expected value' );
        System.assertEquals( expectedEnrouteTime, clearJsonWorkOrder.callEvents[3].eventTime, 'Enroute time does not match the expected value' );
        System.assertEquals( expectedOnLocationTime, clearJsonWorkOrder.callEvents[4].eventTime, 'On Location time does not match the expected value' );       
      
        
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndSpottedTimeIsNotNullAndScheduledTimeIsNullAndDisPatchedIsNullAndEnRouteIsNullAndOnLocationIsNull_CallEvents_EventTimeOnlocationTimeIsOneSecondAfterSpottedTime() {
        // Test.startTest();
        //SP to CL requires DI to be inserted with a time 1 second after SP, OL to be inserted with a time 1 second after DI, 
        //ER to be inserted with a time 1 second after DI, and OL to be inserted with a time 1 second after ER, and CL shall be the time entered by the user.
        LoadData();
        Datetime spottedTime = Datetime.now().addHours( -7 );        
        Datetime expectedSpottedTime = Datetime.newInstanceGmt( spottedTime.yearGmt(), spottedTime.monthGmt(), spottedTime.dayGmt(), spottedTime.hourGmt(), spottedTime.minuteGmt(), spottedTime.secondGmt() );
        Datetime expectedScheduledTime = expectedSpottedTime.addSeconds(1);
        Datetime expectedDispatchedTime = expectedScheduledTime.addSeconds(1);
        Datetime expectedEnrouteTime = expectedDispatchedTime.addSeconds(1);
        Datetime expectedOnLocationTime = expectedEnrouteTime.addSeconds(1);

                 
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = spottedTime; 

        workOrder.Scheduled_Timestamp__c = null;
        workorder.Dispatched_Timestamp__c = null;    
        workOrder.Enroute_Timestamp__c = null;
        workOrder.On_Location_Timestamp__c = null;
              
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();               
        
        System.assertEquals( expectedSpottedTime, clearJsonWorkOrder.callEvents[0].eventTime, 'Spotted time does not match the expected value' );
        System.assertEquals( expectedScheduledTime, clearJsonWorkOrder.callEvents[1].eventTime, 'Scheduled time does not match the expected value' );
        System.assertEquals( expectedDispatchedTime, clearJsonWorkOrder.callEvents[2].eventTime, 'Dispatched time does not match the expected value' );
        System.assertEquals( expectedEnrouteTime, clearJsonWorkOrder.callEvents[3].eventTime, 'Enroute time does not match the expected value' );
        System.assertEquals( expectedOnLocationTime, clearJsonWorkOrder.callEvents[4].eventTime, 'On Location time does not match the expected value' );
        
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_StatusDetail_Status() {
        // Test.startTest();
        LoadData();
        String expected1 = 'SP';
        String expected2 = 'AS';
        String expected3 = 'DI';
        String expected4 = 'ER';
        String expected5 = 'OL';
        String expected6 = 'TW';
        String expected7 = 'CL';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.callEvents[0].statusDetail.status );
        System.assertEquals( expected2, clearJsonWorkOrder.callEvents[1].statusDetail.status );
        System.assertEquals( expected3, clearJsonWorkOrder.callEvents[2].statusDetail.status );
        System.assertEquals( expected4, clearJsonWorkOrder.callEvents[3].statusDetail.status );
        System.assertEquals( expected5, clearJsonWorkOrder.callEvents[4].statusDetail.status );
        System.assertEquals( expected6, clearJsonWorkOrder.callEvents[5].statusDetail.status );
        System.assertEquals( expected7, clearJsonWorkOrder.callEvents[6].statusDetail.status );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_StatusDetail_ReasonCode() {
        // Test.startTest();
        LoadData();
        String expected1 = 'FS';
        String expected2 = '';
        String expected3 = '';
        String expected4 = '';
        String expected5 = '';
        String expected6 = '';
        String expected7 = '';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected1, clearJsonWorkOrder.callEvents[0].statusDetail.reasonCode );
        System.assertEquals( expected2, clearJsonWorkOrder.callEvents[1].statusDetail.reasonCode );
        System.assertEquals( expected3, clearJsonWorkOrder.callEvents[2].statusDetail.reasonCode );
        System.assertEquals( expected4, clearJsonWorkOrder.callEvents[3].statusDetail.reasonCode );
        System.assertEquals( expected5, clearJsonWorkOrder.callEvents[4].statusDetail.reasonCode );
        System.assertEquals( expected6, clearJsonWorkOrder.callEvents[5].statusDetail.reasonCode );
        System.assertEquals( expected7, clearJsonWorkOrder.callEvents[6].statusDetail.reasonCode );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_StatusDetail_UpdatedBy_ContactTypeIsSYSTEM() {
        // Test.startTest();
        LoadData();
        String expected = 'SYSTEM';
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[0].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[1].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[2].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[3].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[4].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[5].statusDetail.updatedBy.contactType );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[6].statusDetail.updatedBy.contactType );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClearAndServiceAppointmentIsBreakdownAppointmentWithScheduledStartTime_CallEvents_StatusDetail_Eta() {
        // Test.startTest();
        LoadData();
        Datetime eta = Datetime.now();
        Datetime expected = Datetime.newInstanceGmt( eta.yearGmt(), eta.monthGmt(), eta.dayGmt(), eta.hourGmt(), eta.minuteGmt(), eta.secondGmt() );
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );
        workOrder.ServiceAppointments[0].Subject = 'Breakdown Appointment';
        workOrder.ServiceAppointments[0].SchedStartTime = eta;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[0].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[1].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[2].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[3].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[4].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[5].statusDetail.eta );
        System.assertEquals( expected, clearJsonWorkOrder.callEvents[6].statusDetail.eta );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_StatusDetail_Facility() {
        // Test.startTest();
        LoadData();
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[0].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[1].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[2].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[3].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[4].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[5].statusDetail.facility );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.facility, clearJsonWorkOrder.callEvents[6].statusDetail.facility );
    }

    static testMethod void Wrap_SingleWorkOrderAndServiceNameIsClear_CallEvents_StatusDetail_Truck() {
        // Test.startTest();
        LoadData();
        serviceName = 'Clear';
        workOrder.Is_Tow_WorkType__c = true;
        workOrder.Spotted_Timestamp__c = Datetime.now().addHours( -7 );
        workOrder.Scheduled_Timestamp__c = Datetime.now().addHours( -6 );
        workOrder.Dispatched_Timestamp__c = Datetime.now().addHours( -5 );
        workOrder.Enroute_Timestamp__c = Datetime.now().addHours( -4 );
        workOrder.On_Location_Timestamp__c = Datetime.now().addHours( -3 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -2 );
        workOrder.In_Tow_Timestamp__c = Datetime.now().addHours( -1 );

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[0].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[1].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[2].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[3].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[4].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[5].statusDetail.truck );
        System.assertEquals( clearJsonWorkOrder.calls[0].service.truck, clearJsonWorkOrder.callEvents[6].statusDetail.truck );
    }

    // TODO: Add tests for IVRLookup

    static testMethod void Wrap_SingleWorkOrder_HeaderIsNull() {
        // Test.startTest();
        LoadData();
        FSL_ClearJsonWorkOrder.HeaderWrapper expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.header );
    }

    static testMethod void Wrap_SingleWorkOrder_StatusDescriptionIsNull() {
        // Test.startTest();
        LoadData();
        String expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.statusDescription );
    }

    static testMethod void Wrap_SingleWorkOrder_StatusCodeIsNull() {
        // Test.startTest();
        LoadData();
        Integer expected = null;

        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( expected, clearJsonWorkOrder.statusCode );
    }

    static testMethod void Wrap_ListOfWorkOrders_SameAmountOfItemsReturned() {
        // Test.startTest();
        LoadData();
        Integer expected = null;
        List<WorkOrder> workOrders = new List<WorkOrder>{ workOrder };

        List<FSL_ClearJsonWorkOrder> clearJsonWorkOrders = wrapper.Wrap( workOrders, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        // Test.stopTest();
        
        System.assertEquals( workOrders.size(), clearJsonWorkOrders.size() );
    }

    @IsTest
    public static void Wrap_ContactIsNull_NoExceptionThrown() {
        // Test.startTest();
        LoadData();
        Exception ex = null;
        workOrder.ContactId = null;

        try {
            System.debug('workOrder 3551 -'+workOrder);
            System.debug('serviceAppointmentIdToAssignedResourceMap 3552 -'+serviceAppointmentIdToAssignedResourceMap);
            System.debug('workOrderIdToFeedItemsMap 3553 -'+workOrderIdToFeedItemsMap);
            System.debug('serviceName 3554 -'+serviceName);
            FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( workOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
           
        System.debug('clearJsonWorkOrder 3554 -'+clearJsonWorkOrder);
        }
        catch( Exception e ) {
            System.debug('Exception 3564' + e);
            ex = e;
        }
        
        // Test.stopTest();
        
        System.assertEquals( null, ex );
    }
}