@IsTest
public with sharing class FSL_WorkOrderJsonWrapperTest {
    
    // *********************************************
    // * WrapperFactory
    // *********************************************
    @IsTest
    public static void testWrapperFactory_CreateWrapper_NotNull() {
        FSL_WorkOrderJsonWrapper.WrapperFactory factory = new FSL_WorkOrderJsonWrapper.WrapperFactory();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper wrapper = factory.createWrapper();
        Test.stopTest();

        System.assertNotEquals( null, wrapper, 'Wrapper is null' );
    }

    public class WrapperFactoryMock extends FSL_WorkOrderJsonWrapper.WrapperFactory {
        public Integer createWrapperCallCount = 0;
        public FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper createWrapperReturnValue;
        public override FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper createWrapper() {
            createWrapperCallCount++;
            return createWrapperReturnValue;
        }
    }
    
    // *********************************************
    // * WorkOrderJsonWrapper
    // *********************************************
    @IsTest
    public static void testWorkOrderJsonWrapper_Wrap_ServiceSettingAndWorkOrders_Wrapped() {
        String expectedRequestEventType = 'Request Event Type';
        String expectedSubType = 'Sub Type';
        String expectedVersion = 'Version';
        List<FSL_WorkOrderJsonWrapper.Call> expectedCalls = new List<FSL_WorkOrderJsonWrapper.Call>{ new FSL_WorkOrderJsonWrapper.Call() };

        FSL_ServiceSettings__c serviceSetting = new FSL_ServiceSettings__c( RequestEventType__c = expectedRequestEventType, RequestSubtype__c = expectedSubType, Version__c = expectedVersion );
        List<FSL_WorkOrder.WorkOrder> workOrders = new List<FSL_WorkOrder.WorkOrder>{ new FSL_WorkOrderTest.WorkOrderMock() };

        CallWrapperMock callWrapper = new CallWrapperMock();
        callWrapper.wrapReturnValue = expectedCalls[0];

        FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper wrapper = new FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper( callWrapper );

        System.assertEquals( 0, callWrapper.wrapCallCount, 'CallWrapper.wrap has been called' );
        
        Test.startTest();
        FSL_WorkOrderJsonWrapper.WorkOrderJson workOrderJson = wrapper.wrap( serviceSetting, workOrders );
        Test.stopTest();

        System.assertNotEquals( null, workOrderJson, 'WorkOrder Json is null' );
        System.assertEquals( 1, callWrapper.wrapCallCount, 'CallWrapper.wrap has not been called' );
        System.assert( workOrderJson.id.length() == 36, 'Id does not have the expected length' );
        System.assertEquals( expectedRequestEventType, workOrderJson.requestEventType, 'Request Event Type does not have the expected value' );
        System.assertEquals( expectedSubType, workOrderJson.subType, 'Sub Type does not have the expected value' );
        System.assertEquals( expectedVersion, workOrderJson.version, 'Version does not have the expected value' );
        System.assertEquals( expectedCalls, workOrderJson.calls, 'Calls does not have the expected value' );
    }

    public class WorkOrderJsonWrapperMock extends FSL_WorkOrderJsonWrapper.WorkOrderJsonWrapper {
        public WorkorderJsonWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.WorkOrderJson wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.WorkOrderJson wrap( FSL_ServiceSettings__c serviceSetting, List<FSL_WorkOrder.WorkOrder> workOrders ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CallWrapper
    // *********************************************
    @IsTest
    public static void testCallWrapper_Wrap_WorkOrderAndServiceSettingAndTowWorkTypeWithAllEventsAndCallCommentsAndFeedItems_Wrapped() {
        List<FeedItem> feedItems = new List<FeedItem>{ new FeedItem() };

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        insert wo;

        FSL_Member_Vehicle__c vehicle = new FSL_Member_Vehicle__c( Work_Order__c = wo.Id );
        insert vehicle;

        FSL_Call_Comments__c comment1 = new FSL_Call_Comments__c( FSL_Work_Order__c = wo.Id, FSL_Comment__c = 'Comment 1' );
        FSL_Call_Comments__c comment2 = new FSL_Call_Comments__c( FSL_Work_Order__c = wo.Id, FSL_Comment__c = 'Comment 2' );
        List<FSL_Call_Comments__c> comments = new List<FSL_Call_Comments__c>{ comment1, comment2 };
        insert comments;

        wo = [SELECT Id, CreatedDate, Call_Date__c, Call_Id__c, External_ID__c, RAP_Case_Number__c, Is_Tow_WorkType__c, 
                Spotted_Timestamp__c, Scheduled_Timestamp__c, Dispatched_Timestamp__c, Enroute_Timestamp__c, On_Location_Timestamp__c, In_Tow_Timestamp__c, Cleared_Timestamp__c, 
                (SELECT Id FROM Member_Vehicles__r), 
                (SELECT Id, FSL_Comment__c FROM Call_Comments__r) 
            FROM WorkOrder 
            LIMIT 1];
        wo.Spotted_Timestamp__c = Datetime.now().addMinutes( -10 );
        wo.Scheduled_Timestamp__c = Datetime.now().addMinutes( -9 );
        wo.Dispatched_Timestamp__c = Datetime.now().addMinutes( -8 );
        wo.Enroute_Timestamp__c = Datetime.now().addMinutes( -7 );
        wo.On_Location_Timestamp__c = Datetime.now().addMinutes( -6 );
        wo.In_Tow_Timestamp__c = Datetime.now().addMinutes( -5 );
        wo.Cleared_Timestamp__c = Datetime.now().addMinutes( -4 );
        wo.Is_Tow_WorkType__c = true;

        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getFeedItemsReturnValue = feedItems;
        
        CallEventWrapperMock callEventWrapper = new CallEventWrapperMock();
        callEventWrapper.wrapReturnValue = new FSL_WorkOrderJsonWrapper.CallEvent();
        List<FSL_WorkOrderJsonWrapper.CallEvent> expectedCallEvents = new List<FSL_WorkOrderJsonWrapper.CallEvent>{ callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue };
        CommentWrapperMock commentWrapper = new CommentWrapperMock();
        commentWrapper.wrapCallCommentReturnValue = new FSL_WorkOrderJsonWrapper.Comment();
        List<FSL_WorkOrderJsonWrapper.Comment> expectedComments = new List<FSL_WorkOrderJsonWrapper.Comment>{ commentWrapper.wrapCallCommentReturnValue, commentWrapper.wrapCallCommentReturnValue };
        commentWrapper.wrapFeedItemReturnValue = new FSL_WorkOrderJsonWrapper.Comment();
        expectedComments.add( commentWrapper.wrapFeedItemReturnValue );

        testCallWrapper_Wrap( workOrder, wo, expectedCallEvents, callEventWrapper, expectedComments, commentWrapper );

        System.assertEquals( 7, callEventWrapper.wrapCallCount, 'CallEventWrapper.wrap has not been called the expected amount of times' );
        System.assertEquals( 2, commentWrapper.wrapCallCommentCallCount, 'CallCommentWrapper.wrap( CallComment ) has not been called the expected amount of times' );
        System.assertEquals( 1, commentWrapper.wrapFeedItemCallCount, 'CallCommentWrapper.wrap( FeedItem ) has not been called the expected amount of times' );
    }

    @IsTest
    public static void testCallWrapper_Wrap_WorkOrderAndServiceSettingAndNotTowWorkTypeWithAllEventsAndNoCallCommentsAndNoFeedItems_Wrapped() {
        List<FeedItem> feedItems = new List<FeedItem>();

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        insert wo;

        FSL_Member_Vehicle__c vehicle = new FSL_Member_Vehicle__c( Work_Order__c = wo.Id );
        insert vehicle;

        wo = [SELECT Id, CreatedDate, Call_Date__c, Call_Id__c, External_ID__c, RAP_Case_Number__c, Is_Tow_WorkType__c, 
                Spotted_Timestamp__c, Scheduled_Timestamp__c, Dispatched_Timestamp__c, Enroute_Timestamp__c, On_Location_Timestamp__c, In_Tow_Timestamp__c, Cleared_Timestamp__c, 
                (SELECT Id FROM Member_Vehicles__r), 
                (SELECT Id, FSL_Comment__c FROM Call_Comments__r) 
            FROM WorkOrder 
            LIMIT 1];
        wo.Spotted_Timestamp__c = Datetime.now().addMinutes( -10 );
        wo.Scheduled_Timestamp__c = Datetime.now().addMinutes( -9 );
        wo.Dispatched_Timestamp__c = Datetime.now().addMinutes( -8 );
        wo.Enroute_Timestamp__c = Datetime.now().addMinutes( -7 );
        wo.On_Location_Timestamp__c = Datetime.now().addMinutes( -6 );
        wo.In_Tow_Timestamp__c = Datetime.now().addMinutes( -5 );
        wo.Cleared_Timestamp__c = Datetime.now().addMinutes( -4 );
        wo.Is_Tow_WorkType__c = false;

        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getFeedItemsReturnValue = feedItems;
        
        CallEventWrapperMock callEventWrapper = new CallEventWrapperMock();
        callEventWrapper.wrapReturnValue = new FSL_WorkOrderJsonWrapper.CallEvent();
        List<FSL_WorkOrderJsonWrapper.CallEvent> expectedCallEvents = new List<FSL_WorkOrderJsonWrapper.CallEvent>{ callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue, callEventWrapper.wrapReturnValue };
        CommentWrapperMock commentWrapper = new CommentWrapperMock();
        List<FSL_WorkOrderJsonWrapper.Comment> expectedComments = new List<FSL_WorkOrderJsonWrapper.Comment>();

        testCallWrapper_Wrap( workOrder, wo, expectedCallEvents, callEventWrapper, expectedComments, commentWrapper );

        System.assertEquals( 6, callEventWrapper.wrapCallCount, 'CallEventWrapper.wrap has not been called the expected amount of times' );
        System.assertEquals( 0, commentWrapper.wrapCallCommentCallCount, 'CallCommentWrapper.wrap( CallComment ) has not been called the expected amount of times' );
        System.assertEquals( 0, commentWrapper.wrapFeedItemCallCount, 'CallCommentWrapper.wrap( FeedItem ) has not been called the expected amount of times' );
    }

    @IsTest
    public static void testCallWrapper_Wrap_WorkOrderAndServiceSettingAndTowWorkTypeWithNoEventTimestampsAndNoCallCommentsAndNoFeedItems_Wrapped() {
        List<FeedItem> feedItems = new List<FeedItem>();

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        insert wo;

        FSL_Member_Vehicle__c vehicle = new FSL_Member_Vehicle__c( Work_Order__c = wo.Id );
        insert vehicle;

        wo = [SELECT Id, CreatedDate, Call_Date__c, Call_Id__c, External_ID__c, RAP_Case_Number__c, Is_Tow_WorkType__c, 
                Spotted_Timestamp__c, Scheduled_Timestamp__c, Dispatched_Timestamp__c, Enroute_Timestamp__c, On_Location_Timestamp__c, In_Tow_Timestamp__c, Cleared_Timestamp__c, 
                (SELECT Id FROM Member_Vehicles__r), 
                (SELECT Id, FSL_Comment__c FROM Call_Comments__r) 
            FROM WorkOrder 
            LIMIT 1];
        wo.Spotted_Timestamp__c = null;
        wo.Scheduled_Timestamp__c = null;
        wo.Dispatched_Timestamp__c = null;
        wo.Enroute_Timestamp__c = null;
        wo.On_Location_Timestamp__c = null;
        wo.In_Tow_Timestamp__c = null;
        wo.Cleared_Timestamp__c = null;
        wo.Is_Tow_WorkType__c = false;

        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getFeedItemsReturnValue = feedItems;
        
        CallEventWrapperMock callEventWrapper = new CallEventWrapperMock();
        callEventWrapper.wrapReturnValue = new FSL_WorkOrderJsonWrapper.CallEvent();
        List<FSL_WorkOrderJsonWrapper.CallEvent> expectedCallEvents = new List<FSL_WorkOrderJsonWrapper.CallEvent>{ callEventWrapper.wrapReturnValue };
        CommentWrapperMock commentWrapper = new CommentWrapperMock();
        List<FSL_WorkOrderJsonWrapper.Comment> expectedComments = new List<FSL_WorkOrderJsonWrapper.Comment>();

        testCallWrapper_Wrap( workOrder, wo, expectedCallEvents, callEventWrapper, expectedComments, commentWrapper );

        System.assertEquals( 1, callEventWrapper.wrapCallCount, 'CallEventWrapper.wrap has not been called the expected amount of times' );
        System.assertEquals( 0, commentWrapper.wrapCallCommentCallCount, 'CallCommentWrapper.wrap( CallComment ) has not been called the expected amount of times' );
        System.assertEquals( 0, commentWrapper.wrapFeedItemCallCount, 'CallCommentWrapper.wrap( FeedItem ) has not been called the expected amount of times' );
    }

    private static void testCallWrapper_Wrap( FSL_WorkOrderTest.WorkOrderMock workOrder, Schema.WorkOrder wo, 
            List<FSL_WorkOrderJsonWrapper.CallEvent> expectedCallEvents, CallEventWrapperMock callEventWrapper, 
            List<FSL_WorkOrderJsonWrapper.Comment> expectedComments, CommentWrapperMock commentWrapper ) 
    {
        String expectedCallDate = 'Call Date';
        String expectedCallId = 'Call Id';
        String expectedCallKey = 'Call Key';
        FSL_WorkOrderJsonWrapper.Channel expectedChannel = new FSL_WorkOrderJsonWrapper.Channel();
        Long expectedCreateDate = wo.CreatedDate.getTime();
        FSL_WorkOrderJsonWrapper.Customer expectedCustomer = new FSL_WorkOrderJsonWrapper.Customer();
        FSL_WorkOrderJsonWrapper.Payment expectedPayment = new FSL_WorkOrderJsonWrapper.Payment();
        String expectedRequestingSystemCallId = 'Requesting System Call Id';
        FSL_WorkOrderJsonWrapper.Service expectedService = new FSL_WorkOrderJsonWrapper.Service();
        FSL_WorkOrderJsonWrapper.SourceSystem expectedSourceSystem = new FSL_WorkOrderJsonWrapper.SourceSystem();
        FSL_WorkOrderJsonWrapper.SourceSystem expectedTargetSystem = new FSL_WorkOrderJsonWrapper.SourceSystem();
        FSL_WorkOrderJsonWrapper.Vehicle expectedVehicle = new FSL_WorkOrderJsonWrapper.Vehicle();
        
        ServiceAppointment sa = new ServiceAppointment( 
            Spotted_Timestamp__c = wo.Spotted_Timestamp__c,
            Scheduled_Timestamp__c = wo.Scheduled_Timestamp__c,
            Dispatched_Timestamp__c = wo.Dispatched_Timestamp__c,
            En_route_Timestamp__c = wo.Enroute_Timestamp__c,
            On_Location_Timestamp__c = wo.On_Location_Timestamp__c,
            In_Tow_Timestamp__c = wo.In_Tow_Timestamp__c,
            Cleared_Timestamp__c = wo.Cleared_Timestamp__c
        );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;

        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;
        workOrder.getTowServiceAppointmentReturnValue = serviceAppointment;
        
        wo.Call_Date__c = expectedCallDate;
        wo.Call_Id__c = expectedCallId;
        wo.External_ID__c = expectedCallKey;
        wo.RAP_Case_Number__c = expectedRequestingSystemCallId;

        FSL_ServiceSettings__c serviceSetting = new FSL_ServiceSettings__c();

        workOrder.getWorkOrderReturnValue = wo;

        ChannelWrapperMock channelWrapper = new ChannelWrapperMock();
        channelWrapper.wrapReturnValue = expectedChannel;
        CustomerWrapperMock customerWrapper = new CustomerWrapperMock();
        customerWrapper.wrapReturnValue = expectedCustomer;
        PaymentWrapperMock paymentWrapper = new PaymentWrapperMock();
        paymentWrapper.wrapReturnValue = expectedPayment;
        ServiceWrapperMock serviceWrapper = new ServiceWrapperMock();
        serviceWrapper.wrapReturnValue = expectedService;
        SourceSystemWrapperMock sourceSystemWrapper = new SourceSystemWrapperMock();
        sourceSystemWrapper.wrapServiceSettingReturnValue = expectedSourceSystem;
        sourceSystemWrapper.wrapWorkOrderReturnValue = expectedTargetSystem;
        VehicleWrapperMock vehicleWrapper = new VehicleWrapperMock();
        vehicleWrapper.wrapReturnValue = expectedVehicle;

        FSL_WorkOrderJsonWrapper.CallWrapper wrapper = new FSL_WorkOrderJsonWrapper.CallWrapper( callEventWrapper, channelWrapper, commentWrapper, customerWrapper, paymentWrapper, serviceWrapper, sourceSystemWrapper, vehicleWrapper );

        System.assertEquals( 0, channelWrapper.wrapCallCount, 'ChannelWrapper.wrap has been called' );
        System.assertEquals( 0, callEventWrapper.wrapCallCount, 'CallEventWrapper.wrap has been called' );
        System.assertEquals( 0, commentWrapper.wrapCallCommentCallCount, 'CommentWrapper.wrap( CallComment ) has been called' );
        System.assertEquals( 0, commentWrapper.wrapFeedItemCallCount, 'CommentWrapper.wrap( FeedItem ) has been called' );
        System.assertEquals( 0, customerWrapper.wrapCallCount, 'CustomerWrapper.wrap has been called' );
        System.assertEquals( 0, paymentWrapper.wrapCallCount, 'PaymentWrapper.wrap has been called' );
        System.assertEquals( 0, serviceWrapper.wrapCallCount, 'ServiceWrapper.wrap has been called' );
        System.assertEquals( 0, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap( ServiceSetting ) has been called' );
        System.assertEquals( 0, sourceSystemWrapper.wrapWorkOrderCallCount, 'SourceSystemWrapper.wrap( WorkOrder ) has been called' );
        System.assertEquals( 0, vehicleWrapper.wrapCallCount, 'VehicleWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Call call = wrapper.wrap( workOrder, serviceSetting );
        Test.stopTest();

        System.assertNotEquals( null, call, 'Call is null' );
        System.assertEquals( 1, channelWrapper.wrapCallCount, 'ChannelWrapper.wrap has not been called' );
        System.assertEquals( 1, customerWrapper.wrapCallCount, 'CustomerWrapper.wrap has not been called' );
        System.assertEquals( 1, paymentWrapper.wrapCallCount, 'PaymentWrapper.wrap has not been called' );
        System.assertEquals( 1, serviceWrapper.wrapCallCount, 'ServiceWrapper.wrap has not been called' );
        System.assertEquals( 1, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap( ServiceSetting ) has not been called' );
        System.assertEquals( 1, sourceSystemWrapper.wrapWorkOrderCallCount, 'SourceSystemWrapper.wrap( WorkOrder ) has not been called' );
        System.assertEquals( 1, vehicleWrapper.wrapCallCount, 'VehicleWrapper.wrap has not been called' );
        System.assertEquals( expectedCallDate, call.callDate, 'call Date does not have the expected value' );
        System.assertEquals( expectedCallEvents, call.callEvents, 'Call Events does not have the expected value' );
        System.assertEquals( expectedCallId, call.callId, 'Call Id does not have the expected value' );
        System.assertEquals( expectedCallKey, call.callKey, 'Call Key does not have the expected value' );
        System.assertEquals( expectedChannel, call.channel, 'Channel does not have the expected value' );
        System.assertEquals( expectedComments, call.comments, 'Comments does not have the expected value' );
        System.assertEquals( expectedCreateDate, call.createDate, 'Create Date does not have the expected value' );
        System.assertEquals( expectedCustomer, call.customer, 'Customer does not have the expected value' );
        System.assertEquals( expectedPayment, call.payment, 'Payment does not have the expected value' );
        System.assertEquals( expectedRequestingSystemCallId, call.requestingSystemCallId, 'Requesting System Call Id does not have the expected value' );
        System.assertEquals( expectedService, call.service, 'Service does not have the expected value' );
        System.assertEquals( expectedSourceSystem, call.sourceSystem, 'Source System does not have the expected value' );
        System.assertEquals( expectedTargetSystem, call.targetSystem, 'Target System does not have the expected value' );
        System.assertEquals( expectedVehicle, call.vehicle, 'Vehicle does not have the expected value' );
    }

    public class CallWrapperMock extends FSL_WorkOrderJsonWrapper.CallWrapper {
        public CallWrapperMock() {
            super( null, null, null, null, null, null, null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Call wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Call wrap( FSL_WorkOrder.WorkOrder workOrder, FSL_ServiceSettings__c serviceSetting ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * ChannelWrapper
    // *********************************************
    @IsTest
    public static void testChannelWrapper_Wrap_WorkOrder_Wrapped() {
        String expectedChannelType = 'Channel Type';
        FSL_WorkOrderJsonWrapper.ChannelContact expectedContact = new FSL_WorkOrderJsonWrapper.ChannelContact();
        FSL_WorkOrderJsonWrapper.ChannelLocation expectedLocation = new FSL_WorkOrderJsonWrapper.ChannelLocation();
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedOrg = new FSL_WorkOrderJsonWrapper.SystemOrganization();

        WorkOrder workOrder = new WorkOrder( Call_Origin__c = expectedChannelType );

        ChannelContactWrapperMock channelContactWrapper = new ChannelContactWrapperMock();
        channelContactWrapper.wrapReturnValue = expectedContact;
        ChannelLocationWrapperMock channelLocationWrapper = new ChannelLocationWrapperMock();
        channelLocationWrapper.wrapReturnValue = expectedLocation;
        SystemOrganizationWrapperMock systemOrganizationWrapper = new SystemOrganizationWrapperMock();
        systemOrganizationWrapper.wrapContactReturnValue = expectedOrg;

        FSL_WorkOrderJsonWrapper.ChannelWrapper wrapper = new FSL_WorkOrderJsonWrapper.ChannelWrapper( channelContactWrapper, channelLocationWrapper, systemOrganizationWrapper );

        System.assertEquals( 0, channelContactWrapper.wrapCallCount, 'ChannelContactWrapper.wrap has been called' );
        System.assertEquals( 0, channelLocationWrapper.wrapCallCount, 'ChannelLocationWrapper.wrap has been called' );
        System.assertEquals( 0, systemOrganizationWrapper.wrapContactCallCount, 'SystemOrganizationWrapper.wrap( Contact ) has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Channel channel = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, channel, 'Channel is null' );
        System.assertEquals( 1, channelContactWrapper.wrapCallCount, 'ChannelContactWrapper.wrap has not been called' );
        System.assertEquals( 1, channelLocationWrapper.wrapCallCount, 'ChannelLocationWrapper.wrap has not been called' );
        System.assertEquals( 1, systemOrganizationWrapper.wrapContactCallCount, 'SystemOrganizationWrapper.wrap( Contact ) has not been called' );
        System.assertEquals( expectedChannelType, channel.channelType, 'Channel Type does not have the expected value' );
        System.assertEquals( expectedContact, channel.contact, 'Contact does not have the expected value' );
        System.assertEquals( expectedLocation, channel.location, 'Location does not have the expected value' );
        System.assertEquals( expectedOrg, channel.org, 'Org does not have the expected value' );
    }

    public class ChannelWrapperMock extends FSL_WorkOrderJsonWrapper.ChannelWrapper {
        public ChannelWrapperMock() {
            super( null, null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Channel wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Channel wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * ChannelContactWrapper
    // *********************************************
    @IsTest
    public static void testChannelContactWrapper_Wrap_WorkOrder_Wrapped() {
        String expectedContactType = 'Contact Type';
        String expectedUserId = 'AGENT';

        WorkOrder workOrder = new WorkOrder( Responder_ID__c = expectedContactType );

        FSL_WorkOrderJsonWrapper.ChannelContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.ChannelContactWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ChannelContact channelContact = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, channelContact, 'Channel Contact is null' );
        System.assertEquals( expectedContactType, channelContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedUserId, channelContact.userId, 'User Id does not have the expected value' );
    }

    public class ChannelContactWrapperMock extends FSL_WorkOrderJsonWrapper.ChannelContactWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.ChannelContact wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.ChannelContact wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * ChannelLocationWrapper
    // *********************************************
    @IsTest
    public static void testChannelLocationWrapper_Wrap_Wrapped() {
        FSL_WorkOrderJsonWrapper.LocationAddress expectedAddress = new FSL_WorkOrderJsonWrapper.LocationAddress();

        LocationAddressWrapperMock locationAddressWrapper = new LocationAddressWrapperMock();
        locationAddressWrapper.wrapReturnValue = expectedAddress;

        FSL_WorkOrderJsonWrapper.ChannelLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.ChannelLocationWrapper( locationAddressWrapper );

        System.assertEquals( 0, locationAddressWrapper.wrapCallCount, 'LocationAddressWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ChannelLocation channelLocation = wrapper.wrap();
        Test.stopTest();

        System.assertNotEquals( null, channelLocation, 'Channel Location is null' );
        System.assertEquals( 1, locationAddressWrapper.wrapCallCount, 'LocationAddressWrapper.wrap has not been called' );
        System.assertEquals( expectedAddress, channelLocation.address, 'Contact does not have the expected value' );
    }

    public class ChannelLocationWrapperMock extends FSL_WorkOrderJsonWrapper.ChannelLocationWrapper {
        public ChannelLocationWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.ChannelLocation wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.ChannelLocation wrap() {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * LocationAddressWrapper
    // *********************************************
    @IsTest
    public static void testLocationAddressWrapper_Wrap_Wrapped() {
        String expectedAddressType = 'PHYSICAL';
        String expectedCity = '';
        String expectedCountry = '';
        String expectedCounty = '';
        String expectedCrossStreet = '';
        String expectedFull = '';
        String expectedPostalCode = '';
        String expectedState = '';
        String expectedStreetDirection = '';
        String expectedStreetName = '';
        String expectedStreetNumber = '';

        FSL_WorkOrderJsonWrapper.LocationAddressWrapper wrapper = new FSL_WorkOrderJsonWrapper.LocationAddressWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.LocationAddress locationAddress = wrapper.wrap();
        Test.stopTest();

        System.assertNotEquals( null, locationAddress, 'Location Address is null' );
        System.assertEquals( expectedAddressType, locationAddress.addressType, 'Address Type does not have the expected value' );
        System.assertEquals( expectedCity, locationAddress.city, 'City does not have the expected value' );
        System.assertEquals( expectedCountry, locationAddress.country, 'Country does not have the expected value' );
        System.assertEquals( expectedCounty, locationAddress.county, 'County does not have the expected value' );
        System.assertEquals( expectedCrossStreet, locationAddress.crossStreet, 'CrossStreet does not have the expected value' );
        System.assertEquals( expectedFull, locationAddress.full, 'Full does not have the expected value' );
        System.assertEquals( expectedPostalCode, locationAddress.postalCode, 'Postal Code does not have the expected value' );
        System.assertEquals( expectedState, locationAddress.state, 'State does not have the expected value' );
        System.assertEquals( expectedStreetDirection, locationAddress.streetDirection, 'Street Direction does not have the expected value' );
        System.assertEquals( expectedStreetName, locationAddress.streetName, 'Street Name does not have the expected value' );
        System.assertEquals( expectedStreetNumber, locationAddress.streetNumber, 'Street Number does not have the expected value' );
    }

    public class LocationAddressWrapperMock extends FSL_WorkOrderJsonWrapper.LocationAddressWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.LocationAddress wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.LocationAddress wrap() {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CustomerWrapper
    // *********************************************
    @IsTest
    public static void testCustomerWrapper_Wrap_WorkOrderWithContactNotNull_Wrapped() {
        String expectedLanguagePreference = 'Language Preference';

        Contact contact = new Contact( Language_Preference__c = expectedLanguagePreference );
        WorkOrder workOrder = new WorkOrder( Contact = contact );

        testCustomerWrapper_Wrap( workOrder, expectedLanguagePreference );
    }
    
    @IsTest
    public static void testCustomerWrapper_Wrap_WorkOrderWithContactNull_Wrapped() {
        String expectedLanguagePreference = null;

        Contact contact = null;
        WorkOrder workOrder = new WorkOrder( Contact = contact );

        testCustomerWrapper_Wrap( workOrder, expectedLanguagePreference );
    }

    private static void testCustomerWrapper_Wrap( WorkOrder workOrder, String expectedLanguagePreference ) {
        FSL_WorkOrderJsonWrapper.CustomerContact expectedContact = new FSL_WorkOrderJsonWrapper.CustomerContact();
        List<FSL_WorkOrderJsonWrapper.Membership> expectedMemberships = new List<FSL_WorkOrderJsonWrapper.Membership>{ new FSL_WorkOrderJsonWrapper.Membership() };

        CustomerContactWrapperMock customerContactWrapper = new CustomerContactWrapperMock();
        customerContactWrapper.wrapReturnValue = expectedContact;
        MembershipWrapperMock membershipWrapper = new MembershipWrapperMock();
        membershipWrapper.wrapReturnValue = expectedMemberships[0];

        FSL_WorkOrderJsonWrapper.CustomerWrapper wrapper = new FSL_WorkOrderJsonWrapper.CustomerWrapper( customerContactWrapper, membershipWrapper );

        System.assertEquals( 0, customerContactWrapper.wrapCallCount, 'CustomerContactWrapper.wrap has been called' );
        System.assertEquals( 0, membershipWrapper.wrapCallCount, 'MembershipWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Customer customer = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, customer, 'Customer is null' );
        System.assertEquals( 1, customerContactWrapper.wrapCallCount, 'CustomerContactWrapper.wrap has not been called' );
        System.assertEquals( 1, membershipWrapper.wrapCallCount, 'MembershipWrapper.wrap has not been called' );
        System.assertEquals( expectedContact, customer.contact, 'Contact does not have the expected value' );
        System.assertEquals( expectedLanguagePreference, customer.languagePreference, 'Language Preference does not have the expected value' );
        System.assertEquals( expectedMemberships, customer.memberships, 'Memberships does not have the expected value' );
    }

    public class CustomerWrapperMock extends FSL_WorkOrderJsonWrapper.CustomerWrapper {
        public CustomerWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Customer wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Customer wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * MembershipWrapper
    // *********************************************
    @IsTest
    public static void testMembershipWrapper_Wrap_WorkOrderAndContactNotNullWithMemberCardNumberNotBlank_Wrapped() {
        String expectedAuthorizationCode = 'Authorization Code';
        String expectedAuthorizationLevel = 'Authorization Level';
        Date expirationDate = Date.today();
        String expectedExpirationDate = String.Valueof( expirationDate );
        String expectedId = 'Id';
        Boolean expectedIsLocalClub = true;
        String expectedMemberBirthday = 'Member Birthday';
        String expectedMemberLevel = 'Member Level';
        String expectedMembershipType = 'Membership Type';
        String expectedMemberSince = 'Member Since';
        String expectedMemberStatus = 'Member Status';
        String expectedOriginalMemberId = 'Original Member Id';
        String expectedProgram = 'Program';
        String expectedSponsor = 'Sponsor';
        Integer expectedSystemOrganizationWrapCallCount = 1;
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedOrg = new FSL_WorkOrderJsonWrapper.SystemOrganization();

        Contact contact = new Contact();
        contact.Membership_Code__c = expectedAuthorizationCode;
        contact.Membership_Authorization__c = expectedAuthorizationLevel;
        contact.Membership_Expiration_Date__c = expirationDate;
        contact.Member_Card_Num__c = expectedId;
        contact.Membership_Islocalclub__c = expectedIsLocalClub;
        contact.Membership_Birthday__c = expectedMemberBirthday;
        contact.Membership_Level__c = expectedMemberLevel;
        contact.Membership_Type__c = expectedMembershipType;
        contact.Membership_Since__c = expectedMemberSince;
        contact.Membership_Status__c = expectedMemberStatus;
        contact.Membership_Program__c = expectedProgram;
        contact.Membership_Sponsor__c = expectedSponsor;

        WorkOrder workOrder = new WorkOrder();
        workOrder.Original_Member_Id__c = expectedOriginalMemberId;

        testMembershipWrapper_Wrap( contact, workOrder, expectedAuthorizationCode, expectedAuthorizationLevel, expectedExpirationDate, 
                                    expectedId, expectedIsLocalClub, expectedMemberBirthday, expectedMemberLevel, expectedMembershipType, 
                                    expectedMemberSince, expectedMemberStatus, expectedOriginalMemberId, expectedProgram, expectedSponsor, 
                                    expectedOrg, expectedSystemOrganizationWrapCallCount );
    }

    @IsTest
    public static void testMembershipWrapper_Wrap_WorkOrderAndContactNotNullWithMemberCardNumberBlank_Wrapped() {
        String expectedAuthorizationCode = 'Authorization Code';
        String expectedAuthorizationLevel = 'Authorization Level';
        Date expirationDate = Date.today();
        String expectedExpirationDate = String.Valueof( expirationDate );
        Boolean expectedIsLocalClub = true;
        String expectedMemberBirthday = 'Member Birthday';
        String expectedMemberLevel = 'Member Level';
        String expectedMembershipType = 'Membership Type';
        String expectedMemberSince = 'Member Since';
        String expectedMemberStatus = 'Member Status';
        String expectedOriginalMemberId = 'Original Member Id';
        String expectedProgram = 'Program';
        String expectedSponsor = 'Sponsor';
        String expectedId = expectedOriginalMemberId;
        Integer expectedSystemOrganizationWrapCallCount = 1;
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedOrg = new FSL_WorkOrderJsonWrapper.SystemOrganization();
        
        Contact contact = new Contact();
        contact.Membership_Code__c = expectedAuthorizationCode;
        contact.Membership_Authorization__c = expectedAuthorizationLevel;
        contact.Membership_Expiration_Date__c = expirationDate;
        contact.Member_Card_Num__c = null;
        contact.Membership_Islocalclub__c = expectedIsLocalClub;
        contact.Membership_Birthday__c = expectedMemberBirthday;
        contact.Membership_Level__c = expectedMemberLevel;
        contact.Membership_Type__c = expectedMembershipType;
        contact.Membership_Since__c = expectedMemberSince;
        contact.Membership_Status__c = expectedMemberStatus;
        contact.Membership_Program__c = expectedProgram;
        contact.Membership_Sponsor__c = expectedSponsor;

        WorkOrder workOrder = new WorkOrder();
        workOrder.Original_Member_Id__c = expectedOriginalMemberId;

        testMembershipWrapper_Wrap( contact, workOrder, expectedAuthorizationCode, expectedAuthorizationLevel, expectedExpirationDate, 
                                    expectedId, expectedIsLocalClub, expectedMemberBirthday, expectedMemberLevel, expectedMembershipType, 
                                    expectedMemberSince, expectedMemberStatus, expectedOriginalMemberId, expectedProgram, expectedSponsor, 
                                    expectedOrg, expectedSystemOrganizationWrapCallCount );
    }

    @IsTest
    public static void testMembershipWrapper_Wrap_WorkOrderAndContactNull_Wrapped() {
        String expectedAuthorizationCode = null;
        String expectedAuthorizationLevel = null;
        String expectedExpirationDate = null;
        Boolean expectedIsLocalClub = null;
        String expectedMemberBirthday = null;
        String expectedMemberLevel = null;
        String expectedMembershipType = null;
        String expectedMemberSince = null;
        String expectedMemberStatus = null;
        String expectedOriginalMemberId = null;
        String expectedProgram = null;
        String expectedSponsor = null;
        String expectedId = null;
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedOrg = null;
        Integer expectedSystemOrganizationWrapCallCount = 0;
        
        Contact contact = null;
        WorkOrder workOrder = new WorkOrder();

        testMembershipWrapper_Wrap( contact, workOrder, expectedAuthorizationCode, expectedAuthorizationLevel, expectedExpirationDate, 
                                    expectedId, expectedIsLocalClub, expectedMemberBirthday, expectedMemberLevel, expectedMembershipType, 
                                    expectedMemberSince, expectedMemberStatus, expectedOriginalMemberId, expectedProgram, expectedSponsor, 
                                    expectedOrg, expectedSystemOrganizationWrapCallCount );
    }

    private static void testMembershipWrapper_Wrap( Schema.Contact contact, WorkOrder workOrder, String expectedAuthorizationCode, String expectedAuthorizationLevel, String expectedExpirationDate, 
                                                    String expectedId, Boolean expectedIsLocalClub, String expectedMemberBirthday, String expectedMemberLevel, String expectedMembershipType, 
                                                    String expectedMemberSince, String expectedMemberStatus, String expectedOriginalMemberId, String expectedProgram, String expectedSponsor, 
                                                    FSL_WorkOrderJsonWrapper.SystemOrganization expectedOrg, Integer expectedSystemOrganizationWrapCallCount ) {
        List<FSL_WorkOrderJsonWrapper.Entitlement> expectedEntitlements = new List<FSL_WorkOrderJsonWrapper.Entitlement>{ new FSL_WorkOrderJsonWrapper.Entitlement() };

        EntitlementWrapperMock entitlementWrapper = new EntitlementWrapperMock();
        entitlementWrapper.wrapReturnValue = expectedEntitlements[0];
        SystemOrganizationWrapperMock systemOrganizationWrapper = new SystemOrganizationWrapperMock();
        systemOrganizationWrapper.wrapContactReturnValue = expectedOrg;

        FSL_WorkOrderJsonWrapper.MembershipWrapper wrapper = new FSL_WorkOrderJsonWrapper.MembershipWrapper( entitlementWrapper, systemOrganizationWrapper );

        System.assertEquals( 0, entitlementWrapper.wrapCallCount, 'EntitlementWrapper.wrap has been called' );
        System.assertEquals( 0, systemOrganizationWrapper.wrapContactCallCount, 'SystemOrganizationWrapper.wrap( Contact ) has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Membership membership = wrapper.wrap( contact, workOrder );
        Test.stopTest();

        System.assertNotEquals( null, membership, 'Membership is null' );
        System.assertEquals( 1, entitlementWrapper.wrapCallCount, 'EntitlementWrapper.wrap has not been called' );
        System.assertEquals( expectedSystemOrganizationWrapCallCount, systemOrganizationWrapper.wrapContactCallCount, 'SystemOrganizationWrapper.wrap( Contact ) has not been called the expected amount of times' );
        System.assertEquals( expectedAuthorizationCode, membership.authorizationCode, 'Authorization Code does not have the expected value' );
        System.assertEquals( expectedAuthorizationLevel, membership.authorizationLevel, 'Authorization Level does not have the expected value' );
        System.assertEquals( expectedExpirationDate, membership.expirationDate, 'Expiration Date does not have the expected value' );
        System.assertEquals( expectedId, membership.id, 'Id does not have the expected value' );
        System.assertEquals( expectedIsLocalClub, membership.isLocalClub, 'Is Local Club does not have the expected value' );
        System.assertEquals( expectedMemberBirthday, membership.memberBirthday, 'Member Birthday does not have the expected value' );
        System.assertEquals( expectedMemberLevel, membership.memberLevel, 'Member Level does not have the expected value' );
        System.assertEquals( expectedMembershipType, membership.membershipType, 'Membership Type does not have the expected value' );
        System.assertEquals( expectedMemberSince, membership.memberSince, 'Member Since does not have the expected value' );
        System.assertEquals( expectedMemberStatus, membership.memberStatus, 'Member Status does not have the expected value' );
        System.assertEquals( expectedOrg, membership.org, 'Org does not have the expected value' );
        System.assertEquals( expectedOriginalMemberId, membership.originalMemberId, 'Original Member Id does not have the expected value' );
        System.assertEquals( expectedProgram, membership.program, 'Program does not have the expected value' );
        System.assertEquals( expectedSponsor, membership.sponsor, 'Sponsor does not have the expected value' );
        System.assertEquals( expectedEntitlements, membership.entitlements, 'Entitlements does not have the expected value' );
    }

    public class MembershipWrapperMock extends FSL_WorkOrderJsonWrapper.MembershipWrapper {
        public MembershipWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Membership wrapReturnValue;
        public override FSL_WorkOrderJsonWrapper.Membership wrap( Schema.Contact contact, WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * EntitlementWrapper
    // *********************************************
    @IsTest
    public static void testEntitlementWrapper_Wrap_NotNull() {
        FSL_WorkOrderJsonWrapper.EntitlementWrapper wrapper = new FSL_WorkOrderJsonWrapper.EntitlementWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Entitlement entitlement = wrapper.wrap();
        Test.stopTest();

        System.assertNotEquals( null, entitlement, 'Entitlement is null' );
    }

    public class EntitlementWrapperMock extends FSL_WorkOrderJsonWrapper.EntitlementWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Entitlement wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Entitlement wrap() {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CustomerContactWrapper
    // *********************************************
    @IsTest
    public static void testCustomerContactWrapper_Wrap_ContactNotNull_Wrapped() {
        String expectedContactType = 'Contact Type';
        String expectedFirstName = 'First Name';
        String expectedLastName = 'Last Name';
        String expectedTitle = 'Title';

        Contact contact = new Contact( Type__c = expectedContactType, FirstName = expectedFirstName, LastName = expectedLastName, Title = expectedTitle );

        testCustomerContactWrapper_Wrap( contact, expectedContactType, expectedFirstName, expectedLastName, expectedTitle );
    }

    @IsTest
    public static void testCustomerContactWrapper_Wrap_ContactNull_Wrapped() {
        String expectedContactType = null;
        String expectedFirstName = null;
        String expectedLastName = null;
        String expectedTitle = null;

        Contact contact = null;

        testCustomerContactWrapper_Wrap( contact, expectedContactType, expectedFirstName, expectedLastName, expectedTitle );
    }

    private static void testCustomerContactWrapper_Wrap( Contact contact, String expectedContactType, String expectedFirstName, String expectedLastName, String expectedTitle ) {
        List<FSL_WorkOrderJsonWrapper.customerEmail> expectedEmails = new List<FSL_WorkOrderJsonWrapper.customerEmail>{ new FSL_WorkOrderJsonWrapper.customerEmail() };
        List<FSL_WorkOrderJsonWrapper.customerPhone> expectedPhones = new List<FSL_WorkOrderJsonWrapper.customerPhone>{ new FSL_WorkOrderJsonWrapper.customerPhone() };

        CustomerEmailWrapperMock customerEmailWrapper = new CustomerEmailWrapperMock();
        customerEmailWrapper.wrapReturnValue = expectedEmails[0];
        CustomerPhoneWrapperMock customerPhoneWrapper = new CustomerPhoneWrapperMock();
        customerPhoneWrapper.wrapReturnValue = expectedPhones[0];

        FSL_WorkOrderJsonWrapper.CustomerContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.CustomerContactWrapper( customerEmailWrapper, customerPhoneWrapper );

        System.assertEquals( 0, customerEmailWrapper.wrapCallCount, 'CustomerEmailWrapper.wrap has been called' );
        System.assertEquals( 0, customerPhoneWrapper.wrapCallCount, 'CustomerPhoneWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CustomerContact customerContact = wrapper.wrap( contact );
        Test.stopTest();

        System.assertNotEquals( null, customerContact, 'Customer Contact is null' );
        System.assertEquals( 1, customerEmailWrapper.wrapCallCount, 'CustomerEmailWrapper.wrap has not been called' );
        System.assertEquals( 1, customerPhoneWrapper.wrapCallCount, 'CustomerPhoneWrapper.wrap has not been called' );
        System.assertEquals( expectedContactType, customerContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedFirstName, customerContact.firstName, 'First Name does not have the expected value' );
        System.assertEquals( expectedLastName, customerContact.lastName, 'Last Name does not have the expected value' );
        System.assertEquals( expectedTitle, customerContact.title, 'Title does not have the expected value' );
        System.assertEquals( expectedEmails, customerContact.emails, 'Emails does not have the expected value' );
        System.assertEquals( expectedPhones, customerContact.phones, 'Phones does not have the expected value' );
    }

    public class CustomerContactWrapperMock extends FSL_WorkOrderJsonWrapper.CustomerContactWrapper {
        public CustomerContactWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CustomerContact wrapReturnValue;
        public override FSL_WorkOrderJsonWrapper.CustomerContact wrap( Schema.Contact contact ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CustomerPhoneWrapper
    // *********************************************
   /* @IsTest
    public static void testCustomerPhoneWrapper_Wrap_ContactNotNull_Wrapped() {
        String expectedPhoneExtension = 'Phone Extension';
        String expectedPhoneNumber = 'Phone Number';
        String expectedPhoneType = 'Phone Type';
        Boolean expectedSmsOptIn = true;

        Contact contact = new Contact( Phone_Extension__c = expectedPhoneExtension, Phone = expectedPhoneNumber, Phone_Type__c = expectedPhoneType, Sms_Optin__c = expectedSmsOptIn );

        testCustomerPhoneWrapper_Wrap( contact, expectedPhoneExtension, expectedPhoneNumber, expectedPhoneType, expectedSmsOptIn );
    } */

    @IsTest
    public static void testCustomerPhoneWrapper_Wrap_ContactNull_WrappedWithNullValues() {
        String expectedPhoneExtension = null;
        String expectedPhoneNumber = null;
        String expectedPhoneType = null;
        Boolean expectedSmsOptIn = null;

        Contact contact = null;

        testCustomerPhoneWrapper_Wrap( contact, expectedPhoneExtension, expectedPhoneNumber, expectedPhoneType, expectedSmsOptIn );
    }

    private static void testCustomerPhoneWrapper_Wrap( Contact contact, String expectedPhoneExtension, String expectedPhoneNumber, String expectedPhoneType, Boolean expectedSmsOptIn ) {
        FSL_WorkOrderJsonWrapper.CustomerPhoneWrapper wrapper = new FSL_WorkOrderJsonWrapper.CustomerPhoneWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CustomerPhone customerPhone = wrapper.wrap( contact );
        Test.stopTest();

        System.assertNotEquals( null, customerPhone, 'Customer Phone is null' );
        System.assertEquals( expectedPhoneExtension, customerPhone.phoneExtension, 'Phone Extension does not have the expected value' );
        System.assertEquals( expectedPhoneNumber, customerPhone.phoneNumber, 'Phone Number does not have the expected value' );
        System.assertEquals( expectedPhoneType, customerPhone.phoneType, 'Phone Type does not have the expected value' );
        System.assertEquals( expectedSmsOptIn, customerPhone.smsOptIn, 'SMS Opt In does not have the expected value' );
    }

    public class CustomerPhoneWrapperMock extends FSL_WorkOrderJsonWrapper.CustomerPhoneWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CustomerPhone wrapReturnValue;
        public override FSL_WorkOrderJsonWrapper.CustomerPhone wrap( Schema.Contact contact ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CustomerEmailWrapper
    // *********************************************
    @IsTest
    public static void testCustomerEmailWrapper_Wrap_ContactNotNull_Wrapped() {
        String expectedAddress = 'Address';
        String expectedEmailType = 'Email Type';

        Contact contact = new Contact( Email = expectedAddress, Email_Type__c = expectedEmailType );

        testCustomerEmailWrapper_Wrap( contact, expectedAddress, expectedEmailType );
    }

    @IsTest
    public static void testCustomerEmailWrapper_Wrap_ContactNull_WrappedWithNullValues() {
        String expectedAddress = null;
        String expectedEmailType = null;

        Contact contact = null;

        testCustomerEmailWrapper_Wrap( contact, expectedAddress, expectedEmailType );
    }

    private static void testCustomerEmailWrapper_Wrap( Contact contact, String expectedAddress, String expectedEmailType ) {
        FSL_WorkOrderJsonWrapper.CustomerEmailWrapper wrapper = new FSL_WorkOrderJsonWrapper.CustomerEmailWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CustomerEmail customerEmail = wrapper.wrap( contact );
        Test.stopTest();

        System.assertNotEquals( null, customerEmail, 'Customer Email is null' );
        System.assertEquals( expectedAddress, customerEmail.address, 'Address does not have the expected value' );
        System.assertEquals( expectedEmailType, customerEmail.emailType, 'Email Type does not have the expected value' );
    }

    public class CustomerEmailWrapperMock extends FSL_WorkOrderJsonWrapper.CustomerEmailWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CustomerEmail wrapReturnValue;
        public override FSL_WorkOrderJsonWrapper.CustomerEmail wrap( Schema.Contact contact ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * VehicleWrapper
    // *********************************************
    @IsTest
    public static void testVehicleWrapper_Wrap_MemberVehicleWithoutNullValues_Wrapped() {
        Double odometer = 123.45;
        Integer expectedOdometer = odometer.intValue();
        Integer expectedYear = 456;
        String year = String.valueOf( expectedYear );

        testVehicleWrapper_Wrap( odometer, expectedOdometer, year, expectedYear );
    }

    
    @IsTest
    public static void testVehicleWrapper_Wrap_MemberVehicleWithNullValues_Wrapped() {
        Double odometer = null;
        Integer expectedOdometer = null;
        Integer expectedYear = null;
        String year = null;

        testVehicleWrapper_Wrap( odometer, expectedOdometer, year, expectedYear );
    }
    
    private static void testVehicleWrapper_Wrap( Double odometer, Integer expectedOdometer, String year, Integer expectedYear ) {
        String expectedColor = 'Color';
        String expectedDriveType = 'Drive Type';
        String expectedFuelType = 'Fuel Type';
        String expectedMake = 'Make';
        String expectedModel = 'Model';
        FSL_WorkOrderJsonWrapper.RvInfo expectedRvInfo = new FSL_WorkOrderJsonWrapper.RvInfo();
        String expectedSpecialEquipmentNeeds = 'Special Equipment Needs';
        String expectedState = 'State';
        String expectedTag = 'Tag';
        FSL_WorkOrderJsonWrapper.TrailerInfo expectedTrailerInfo = new FSL_WorkOrderJsonWrapper.TrailerInfo();
        String expectedTrim = 'Trim';
        String expectedVehicleType = 'Vehicle Type';
        String expectedVin = 'Vin';

        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c();
        memberVehicle.Vehicle_Color__c = expectedColor;
        memberVehicle.Vehicle_Drive_Type__c = expectedDriveType;
        memberVehicle.Vehicle_Fuel_Type__c = expectedFuelType;
        memberVehicle.Vehicle_Make__c = expectedMake;
        memberVehicle.Vehicle_Model__c = expectedModel;
        memberVehicle.Vehicle_Odometer__c = odometer;
        memberVehicle.Vehicle_Special_Equipment_Needs__c = expectedSpecialEquipmentNeeds;
        memberVehicle.Vehicle_State__c = expectedState;
        memberVehicle.Vehicle_Tag__c = expectedTag;
        memberVehicle.Vehicle_Trim__c = expectedTrim;
        memberVehicle.Vehicle_Type__c = expectedVehicleType;
        memberVehicle.Vehicle_Vin__c = expectedVin;
        memberVehicle.Vehicle_Year__c = year;

        RvInfoWrapperMock rvInfoWrapper = new RvInfoWrapperMock();
        rvInfoWrapper.wrapReturnValue = expectedRvInfo;
        TrailerInfoWrapperMock trailerInfoWrapper = new TrailerInfoWrapperMock();
        trailerInfoWrapper.wrapReturnValue = expectedTrailerInfo;

        FSL_WorkOrderJsonWrapper.VehicleWrapper wrapper = new FSL_WorkOrderJsonWrapper.VehicleWrapper( rvInfoWrapper, trailerInfoWrapper );

        System.assertEquals( 0, rvInfoWrapper.wrapCallCount, 'RvInfoWrapper.wrap has been called' );
        System.assertEquals( 0, trailerInfoWrapper.wrapCallCount, 'TrailerInfoWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Vehicle vehicle = wrapper.wrap( memberVehicle );
        Test.stopTest();

        System.assertNotEquals( null, vehicle, 'Vehicle is null' );
        System.assertEquals( 1, rvInfoWrapper.wrapCallCount, 'RvInfoWrapper.wrap has not been called' );
        System.assertEquals( 1, trailerInfoWrapper.wrapCallCount, 'TrailerInfoWrapper.wrap has not been called' );
        System.assertEquals( expectedColor, vehicle.color, 'Color does not have the expected value' );
        System.assertEquals( expectedDriveType, vehicle.driveType, 'Drive Type does not have the expected value' );
        System.assertEquals( expectedFuelType, vehicle.fuelType, 'Fuel Type does not have the expected value' );
        System.assertEquals( expectedMake, vehicle.make, 'Make does not have the expected value' );
        System.assertEquals( expectedModel, vehicle.model, 'Model does not have the expected value' );
        System.assertEquals( expectedOdometer, vehicle.odometer, 'Odometer does not have the expected value' );
        System.assertEquals( expectedRvInfo, vehicle.rvInfo, 'RV Info does not have the expected value' );
        System.assertEquals( expectedSpecialEquipmentNeeds, vehicle.specialEquipmentNeeds, 'Special Equipment Needs does not have the expected value' );
        System.assertEquals( expectedState, vehicle.state, 'State does not have the expected value' );
        System.assertEquals( expectedTag, vehicle.tag, 'Tag does not have the expected value' );
        System.assertEquals( expectedTrailerInfo, vehicle.trailerInfo, 'Trailer Info does not have the expected value' );
        System.assertEquals( expectedTrim, vehicle.trim, 'Trim does not have the expected value' );
        System.assertEquals( expectedVehicleType, vehicle.vehicleType, 'Vehicle Type does not have the expected value' );
        System.assertEquals( expectedVin, vehicle.vin, 'Vin does not have the expected value' );
        System.assertEquals( expectedYear, vehicle.year, 'Year does not have the expected value' );
    }

    public class VehicleWrapperMock extends FSL_WorkOrderJsonWrapper.VehicleWrapper {
        public VehicleWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Vehicle wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Vehicle wrap( FSL_Member_Vehicle__c memberVehicle ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * RvInfoWrapper
    // *********************************************
    @IsTest
    public static void testRvInfoWrapper_Wrap_MemberVehicle_Wrapped() {
        Double expectedLength = 123.45;
        String expectedRvClass = 'RV Class';

        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c( RV_Length__c = expectedLength, RV_Class__c = expectedRvClass );

        FSL_WorkOrderJsonWrapper.RvInfoWrapper wrapper = new FSL_WorkOrderJsonWrapper.RvInfoWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.RvInfo rvInfo = wrapper.wrap( memberVehicle );
        Test.stopTest();

        System.assertNotEquals( null, rvInfo, 'RV Info is null' );
        System.assertEquals( expectedLength, rvInfo.length, 'Length does not have the expected value' );
        System.assertEquals( expectedRvClass, rvInfo.rvClass, 'RV Class does not have the expected value' );
    }

    public class RvInfoWrapperMock extends FSL_WorkOrderJsonWrapper.RvInfoWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.RvInfo wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.RvInfo wrap( FSL_Member_Vehicle__c memberVehicle ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * TrailerInfoWrapper
    // *********************************************
    @IsTest
    public static void testTrailerInfoWrapper_Wrap_MemberVehicle_Wrapped() {
        String expectedHitchType = 'Hitch Type';
        Double expectedLength = 123.45;

        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c( Trailer_Hitchtype__c = expectedHitchType, Trailer_Length__c = expectedLength );

        FSL_WorkOrderJsonWrapper.TrailerInfoWrapper wrapper = new FSL_WorkOrderJsonWrapper.TrailerInfoWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.TrailerInfo trailerInfo = wrapper.wrap( memberVehicle );
        Test.stopTest();

        System.assertNotEquals( null, trailerInfo, 'Trailer Info is null' );
        System.assertEquals( expectedHitchType, trailerInfo.hitchType, 'Hitch Type does not have the expected value' );
        System.assertEquals( expectedLength, trailerInfo.length, 'Length does not have the expected value' );
    }

    public class TrailerInfoWrapperMock extends FSL_WorkOrderJsonWrapper.TrailerInfoWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.TrailerInfo wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.TrailerInfo wrap( FSL_Member_Vehicle__c memberVehicle ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * CallEventWrapper
    // *********************************************
    @IsTest
    public static void testCallEventWrapper_Wrap_WorkOrderAndEventTimeAndStatusAndReasonCode_Wrapped() {
        String expectedCallDate = 'Call Date';
        String expectedCallId = 'Call Id';
        String expectedCallKey = 'Call Key';
        Datetime expectedEventTime = Datetime.now();
        FSL_WorkOrderJsonWrapper.StatusDetail expectedStatusDetail = new FSL_WorkOrderJsonWrapper.StatusDetail();

        WorkOrder wo = new WorkOrder( Call_Date__c = expectedCallDate, Call_Id__c = expectedCallId, External_Id__c = expectedCallKey );
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;

        StatusDetailWrapperMock statusDetailWrapper = new StatusDetailWrapperMock();
        statusDetailWrapper.wrapReturnValue = expectedStatusDetail;

        FSL_WorkOrderJsonWrapper.CallEventWrapper wrapper = new FSL_WorkOrderJsonWrapper.CallEventWrapper( statusDetailWrapper );

        System.assertEquals( 0, statusDetailWrapper.wrapCallCount, 'StatusDetailWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CallEvent callEvent = wrapper.wrap( workOrder, expectedEventTime, null, null );
        Test.stopTest();

        System.assertNotEquals( null, callEvent, 'Call Event is null' );
        System.assertEquals( 1, statusDetailWrapper.wrapCallCount, 'StatusDetailWrapper.wrap has not been called' );
        System.assertEquals( expectedCallDate, callEvent.callDate, 'Call Date does not have the expected value' );
        System.assertEquals( expectedCallId, callEvent.callId, 'Call Id does not have the expected value' );
        System.assertEquals( expectedCallKey, callEvent.callKey, 'Call Key does not have the expected value' );
        System.assertEquals( expectedEventTime, callEvent.eventTime, 'Event Time does not have the expected value' );
        System.assertEquals( expectedStatusDetail, callEvent.statusDetail, 'Status Detail does not have the expected value' );
    }

    public class CallEventWrapperMock extends FSL_WorkOrderJsonWrapper.CallEventWrapper {
        public CallEventWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CallEvent wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.CallEvent wrap( FSL_WorkOrder.WorkOrder workOrder, Datetime eventTime, String status, String reasonCode ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * StatusDetailWrapper
    // *********************************************
    @IsTest
    public static void testStatusDetailWrapper_Wrap_WorkOrderAndStatusAndReasonCode_Wrapped() {
        Datetime expectedEta = Datetime.now();
        FSL_WorkOrderJsonWrapper.Facility expectedFacility = new FSL_WorkOrderJsonWrapper.Facility();
        String expectedReasonCode = 'Reason Code';
        String expectedStatus = 'Status';
        FSL_WorkOrderJsonWrapper.Truck expectedTruck = new FSL_WorkOrderJsonWrapper.Truck();
        FSL_WorkOrderJsonWrapper.UpdatedBy expectedUpdatedBy = new FSL_WorkOrderJsonWrapper.UpdatedBy();

        FacilityWrapperMock facilityWrapper = new FacilityWrapperMock();
        facilityWrapper.wrapReturnValue = expectedFacility;

        TruckWrapperMock truckWrapper = new TruckWrapperMock();
        truckWrapper.wrapReturnValue = expectedTruck;

        UpdatedByWrapperMock updatedByWrapper = new UpdatedByWrapperMock();
        updatedByWrapper.wrapReturnValue = expectedUpdatedBy;

        ServiceAppointment sa = new ServiceAppointment( SchedStartTime = expectedEta );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;

        WorkOrder wo = new WorkOrder();
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;

        FSL_WorkOrderJsonWrapper.StatusDetailWrapper wrapper = new FSL_WorkOrderJsonWrapper.StatusDetailWrapper( facilityWrapper, truckWrapper, updatedByWrapper );

        System.assertEquals( 0, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has been called' );
        System.assertEquals( 0, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has been called' );
        System.assertEquals( 0, updatedByWrapper.wrapCallCount, 'UpdatedByWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.StatusDetail statusDetail = wrapper.wrap( workOrder, expectedStatus, expectedReasonCode );
        Test.stopTest();
        
        System.assertNotEquals( null, statusDetail, 'Status Detail is null' );
        System.assertEquals( 1, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has not been called' );
        System.assertEquals( 1, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has not been called' );
        System.assertEquals( 1, updatedByWrapper.wrapCallCount, 'UpdatedByWrapper.wrap has not been called' );
        System.assertEquals( expectedEta, statusDetail.eta, 'ETA does not have the expected value' );
        System.assertEquals( expectedFacility, statusDetail.facility, 'Facility does not have the expected value' );
        System.assertEquals( expectedReasonCode, statusDetail.reasonCode, 'Reason Code does not have the expected value' );
        System.assertEquals( expectedStatus, statusDetail.status, 'Status does not have the expected value' );
        System.assertEquals( expectedTruck, statusDetail.truck, 'Truck does not have the expected value' );
        System.assertEquals( expectedUpdatedBy, statusDetail.updatedBy, 'Updated By does not have the expected value' );
    }

    public class StatusDetailWrapperMock extends FSL_WorkOrderJsonWrapper.StatusDetailWrapper {
        public StatusDetailWrapperMock() {
            super( null, null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.StatusDetail wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.StatusDetail wrap( FSL_WorkOrder.WorkOrder workOrder, String status, String reasonCode ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * ServiceWrapper
    // *********************************************
  /*  @IsTest
    public static void testServiceWrapper_Wrap_WorkOrderWithNumberOfPassengersAndResolutionCodeNotNull_Wrapped() {
        String expectedAppointmentTime = 'Appointment Time';
        String expectedCallType = 'Call Type';
        Boolean expectedCollision = true;
        FSL_WorkOrderJsonWrapper.Facility expectedFacility = new FSL_WorkOrderJsonWrapper.Facility();
        Boolean expectedFlatbedRequested = true;
        String expectedLegacyPriorityCode = 'Legacy Priority Code';
        Boolean expectedNeedsFlatbed = true;
        Integer expectedNumberOfPassengers = 123;
        List<FSL_WorkOrderJsonWrapper.Policy> expectedPolicies = new List<FSL_WorkOrderJsonWrapper.Policy>{ new FSL_WorkOrderJsonWrapper.Policy() };
        String expectedPriorityCode = 'Priority Code';
        List<FSL_WorkOrderJsonWrapper.ProvidedService> expectedProvidedServices = new List<FSL_WorkOrderJsonWrapper.ProvidedService>{ new FSL_WorkOrderJsonWrapper.ProvidedService() };
        Boolean expectedRedFlag = true;
        List<FSL_WorkOrderJsonWrapper.ServiceLocation> expectedServiceLocations = new List<FSL_WorkOrderJsonWrapper.ServiceLocation>{ new FSL_WorkOrderJsonWrapper.ServiceLocation() };
        FSL_WorkOrderJsonWrapper.Status expectedStatus = new FSL_WorkOrderJsonWrapper.Status();
        String expectedTimezoneId = 'Timezone Id';
        String expectedTimezoneOffset = 'Timezone Offset';
        List<FSL_WorkOrderJsonWrapper.TroubleCode> expectedTroubleCodes = new List<FSL_WorkOrderJsonWrapper.TroubleCode>{ new FSL_WorkOrderJsonWrapper.TroubleCode(), new FSL_WorkOrderJsonWrapper.TroubleCode() };
        FSL_WorkOrderJsonWrapper.Truck expectedTruck = new FSL_WorkOrderJsonWrapper.Truck();

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Non_Emergency_Appointment_Time__c = expectedAppointmentTime;
        wo.Call_Type__c = expectedCallType;
        wo.Collision__c = expectedCollision;
        wo.Flatbed_Requested__c = expectedFlatbedRequested;
        wo.Needs_Flatbed__c = expectedNeedsFlatbed;
        wo.Number_Of_Passengers__c = expectedNumberOfPassengers;
        wo.Red_Flag__c = expectedRedFlag;
        insert wo;

        FSL_Policy__c policy = new FSL_Policy__c( Work_Order__c = wo.Id );
        insert policy;

        Product2 product = new Product2( Name = 'Product',FAMILY = 'Service Item' );
        insert product;

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Work_Order__c = wo.Id, Product__c = product.Id );
        insert serviceLineItem;

        FSL_TroubleCode__c troubleCode = new FSL_TroubleCode__c( Work_Order__c = wo.Id, Code__c = 'Code 1', Description__c = 'Description 1', Type__c = 'Type 1' );
        insert troubleCode;

        wo = [SELECT Id, Non_Emergency_Appointment_Time__c, Call_Type__c, Collision__c, Flatbed_Requested__c, Legacy_Priority_Code__c, 
                Needs_Flatbed__c, Number_Of_Passengers__c, Priority_Code__c, Red_Flag__c, Timezone_Id__c, Timezone_Offset__c, Resolution_Code__c, 
                (SELECT Id FROM Policies__r), (SELECT Id FROM Service_Line_Items__r), (SELECT Id FROM TroubleCodes__r)
            FROM WorkOrder LIMIT 1];

        wo.Priority_Code__c = expectedPriorityCode;
        wo.Legacy_Priority_Code__c = expectedLegacyPriorityCode;
        wo.Timezone_Offset__c = expectedTimezoneOffset;
        wo.Timezone_Id__c = expectedTimezoneId;
        wo.Resolution_Code__c = 'Resolution Code';

        ServiceResource sr = new ServiceResource();
        FSL_AssignedResourceTest.AssignedResourceMock assignedResource = new FSL_AssignedResourceTest.AssignedResourceMock();
        assignedResource.getServiceResourceReturnValue = sr;

        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getAssignedResourceReturnValue = assignedResource;

        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getServiceAppointmentsReturnValue = new List<FSL_ServiceAppointment.ServiceAppointment>{ serviceAppointment };
        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;   

        FacilityWrapperMock facilityWrapper = new FacilityWrapperMock();
        facilityWrapper.wrapReturnValue = expectedFacility;

        PolicyWrapperMock policyWrapper = new PolicyWrapperMock();
        policyWrapper.wrapReturnValue = expectedPolicies[0];

        ProvidedServiceWrapperMock providedServiceWrapper = new ProvidedServiceWrapperMock();
        providedServiceWrapper.wrapReturnValue = expectedProvidedServices[0];

        ServiceLocationWrapperMock serviceLocationWrapper = new ServiceLocationWrapperMock();
        serviceLocationWrapper.wrapReturnValue = expectedServiceLocations[0];

        StatusWrapperMock statusWrapper = new StatusWrapperMock();
        statusWrapper.wrapReturnValue = expectedStatus;

        TroubleCodeWrapperMock troubleCodeWrapper = new TroubleCodeWrapperMock();
        troubleCodeWrapper.wrapTroubleCodeReturnValue = expectedTroubleCodes[0];
        troubleCodeWrapper.wrapResolutionCodeReturnValue = expectedTroubleCodes[1];

        TruckWrapperMock truckWrapper = new TruckWrapperMock();
        truckWrapper.wrapReturnValue = expectedTruck;

        FSL_WorkOrderJsonWrapper.ServiceWrapper wrapper = new FSL_WorkOrderJsonWrapper.ServiceWrapper( facilityWrapper, policyWrapper, providedServiceWrapper, serviceLocationWrapper, statusWrapper, troubleCodeWrapper, truckWrapper );

        System.assertEquals( 0, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has been called' );
        System.assertEquals( 0, policyWrapper.wrapCallCount, 'PolicyWrapper.wrap has been called' );
        System.assertEquals( 0, providedServiceWrapper.wrapCallCount, 'ProvidedServiceWrapper.wrap has been called' );
        System.assertEquals( 0, serviceLocationWrapper.wrapCallCount, 'ServiceLocationWrapper.wrap has been called' );
        System.assertEquals( 0, statusWrapper.wrapCallCount, 'StatusWrapper.wrap has been called' );
        System.assertEquals( 0, troubleCodeWrapper.wrapTroubleCodeCallCount, 'TroubleCodeWrapper.wrap( TroubleCode ) has been called' );
        System.assertEquals( 0, troubleCodeWrapper.wrapResolutionCodeCallCount, 'TroubleCodeWrapper.wrap( ResolutionCode ) has been called' );
        System.assertEquals( 0, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Service service = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, service, 'Service is null' );
        System.assertEquals( 1, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has not been called' );
        System.assertEquals( 1, policyWrapper.wrapCallCount, 'PolicyWrapper.wrap has not been called' );
        System.assertEquals( 1, providedServiceWrapper.wrapCallCount, 'ProvidedServiceWrapper.wrap has not been called' );
        System.assertEquals( 1, serviceLocationWrapper.wrapCallCount, 'ServiceLocationWrapper.wrap has not been called' );
        System.assertEquals( 1, statusWrapper.wrapCallCount, 'StatusWrapper.wrap has not been called' );
        System.assertEquals( 1, troubleCodeWrapper.wrapTroubleCodeCallCount, 'TroubleCodeWrapper.wrap( TroubleCode ) has not been called' );
        System.assertEquals( 1, troubleCodeWrapper.wrapResolutionCodeCallCount, 'TroubleCodeWrapper.wrap( ResolutionCode ) has not been called' );
        System.assertEquals( 1, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has not been called' );
        System.assertEquals( expectedAppointmentTime, service.appointmentTime, 'Appointment Time does not have the expected value' );
        System.assertEquals( expectedCallType, service.callType, 'Call Type does not have the expected value' );
        System.assertEquals( expectedCollision, service.collision, 'Collision does not have the expected value' );
        System.assertEquals( expectedFacility, service.facility, 'Facility does not have the expected value' );
        System.assertEquals( expectedFlatbedRequested, service.flatbedRequested, 'Flatbed Requested does not have the expected value' );
        System.assertEquals( expectedLegacyPriorityCode, service.legacyPriorityCode, 'Legacy Priority Code does not have the expected value' );
        System.assertEquals( expectedNeedsFlatbed, service.needsFlatbed, 'Needs Flatbed does not have the expected value' );
        System.assertEquals( expectedNumberOfPassengers, service.numberOfPassengers, 'Number Of Passengers does not have the expected value' );
        System.assertEquals( expectedPolicies, service.policies, 'Policies does not have the expected value' );
        System.assertEquals( expectedPriorityCode, service.priorityCode, 'Priority Code does not have the expected value' );
        System.assertEquals( expectedProvidedServices, service.providedServices, 'Provided Services does not have the expected value' );
        System.assertEquals( expectedRedFlag, service.redFlag, 'Red Flag does not have the expected value' );
        System.assertEquals( expectedServiceLocations, service.serviceLocations, 'Service Locations does not have the expected value' );
        System.assertEquals( expectedStatus, service.status, 'Status does not have the expected value' );
        System.assertEquals( expectedTimezoneId, service.timezoneId, 'Timezone Id does not have the expected value' );
        System.assertEquals( expectedTimezoneOffset, service.timezoneOffset, 'Timezone Offset does not have the expected value' );
        System.assertEquals( expectedTroubleCodes, service.troubleCodes, 'Trouble Codes does not have the expected value' );
        System.assertEquals( expectedTruck, service.truck, 'Truck does not have the expected value' );
    } */

  /*  @IsTest
    public static void testServiceWrapper_Wrap_WorkOrderWithNumberOfPassengersAndResolutionCodeNull_Wrapped() {
        String expectedAppointmentTime = 'Appointment Time';
        String expectedCallType = 'Call Type';
        Boolean expectedCollision = true;
        FSL_WorkOrderJsonWrapper.Facility expectedFacility = new FSL_WorkOrderJsonWrapper.Facility();
        Boolean expectedFlatbedRequested = true;
        String expectedLegacyPriorityCode = 'Legacy Priority Code';
        Boolean expectedNeedsFlatbed = true;
        Integer expectedNumberOfPassengers = null;
        List<FSL_WorkOrderJsonWrapper.Policy> expectedPolicies = new List<FSL_WorkOrderJsonWrapper.Policy>{ new FSL_WorkOrderJsonWrapper.Policy() };
        String expectedPriorityCode = 'Priority Code';
        List<FSL_WorkOrderJsonWrapper.ProvidedService> expectedProvidedServices = new List<FSL_WorkOrderJsonWrapper.ProvidedService>{ new FSL_WorkOrderJsonWrapper.ProvidedService() };
        Boolean expectedRedFlag = true;
        List<FSL_WorkOrderJsonWrapper.ServiceLocation> expectedServiceLocations = new List<FSL_WorkOrderJsonWrapper.ServiceLocation>{ new FSL_WorkOrderJsonWrapper.ServiceLocation() };
        FSL_WorkOrderJsonWrapper.Status expectedStatus = new FSL_WorkOrderJsonWrapper.Status();
        String expectedTimezoneId = 'Timezone Id';
        String expectedTimezoneOffset = 'Timezone Offset';
        List<FSL_WorkOrderJsonWrapper.TroubleCode> expectedTroubleCodes = new List<FSL_WorkOrderJsonWrapper.TroubleCode>{ new FSL_WorkOrderJsonWrapper.TroubleCode() };
        FSL_WorkOrderJsonWrapper.Truck expectedTruck = new FSL_WorkOrderJsonWrapper.Truck();

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Non_Emergency_Appointment_Time__c = expectedAppointmentTime;
        wo.Call_Type__c = expectedCallType;
        wo.Collision__c = expectedCollision;
        wo.Flatbed_Requested__c = expectedFlatbedRequested;
        wo.Needs_Flatbed__c = expectedNeedsFlatbed;
        wo.Number_Of_Passengers__c = expectedNumberOfPassengers;
        wo.Red_Flag__c = expectedRedFlag;
        insert wo;

        FSL_Policy__c policy = new FSL_Policy__c( Work_Order__c = wo.Id );
        insert policy;

        Product2 product = new Product2( Name = 'Product',FAMILY = 'Service Item' );
        insert product;

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Work_Order__c = wo.Id, Product__c = product.Id );
        insert serviceLineItem;

        FSL_TroubleCode__c troubleCode = new FSL_TroubleCode__c( Work_Order__c = wo.Id, Code__c = 'Code 1', Description__c = 'Description 1', Type__c = 'Type 1' );
        insert troubleCode;

        wo = [SELECT Id, Non_Emergency_Appointment_Time__c, Call_Type__c, Collision__c, Flatbed_Requested__c, Legacy_Priority_Code__c, 
                Needs_Flatbed__c, Number_Of_Passengers__c, Priority_Code__c, Red_Flag__c, Timezone_Id__c, Timezone_Offset__c, Resolution_Code__c, 
                (SELECT Id FROM Policies__r), (SELECT Id FROM Service_Line_Items__r), (SELECT Id FROM TroubleCodes__r)
            FROM WorkOrder LIMIT 1];

        wo.Priority_Code__c = expectedPriorityCode;
        wo.Legacy_Priority_Code__c = expectedLegacyPriorityCode;
        wo.Timezone_Offset__c = expectedTimezoneOffset;
        wo.Timezone_Id__c = expectedTimezoneId;
        wo.Resolution_Code__c = null;

        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getAssignedResourceReturnValue = null;

        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getServiceAppointmentsReturnValue = new List<FSL_ServiceAppointment.ServiceAppointment>{ serviceAppointment };
        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;   

        FacilityWrapperMock facilityWrapper = new FacilityWrapperMock();
        facilityWrapper.wrapReturnValue = expectedFacility;

        PolicyWrapperMock policyWrapper = new PolicyWrapperMock();
        policyWrapper.wrapReturnValue = expectedPolicies[0];

        ProvidedServiceWrapperMock providedServiceWrapper = new ProvidedServiceWrapperMock();
        providedServiceWrapper.wrapReturnValue = expectedProvidedServices[0];

        ServiceLocationWrapperMock serviceLocationWrapper = new ServiceLocationWrapperMock();
        serviceLocationWrapper.wrapReturnValue = expectedServiceLocations[0];

        StatusWrapperMock statusWrapper = new StatusWrapperMock();
        statusWrapper.wrapReturnValue = expectedStatus;

        TroubleCodeWrapperMock troubleCodeWrapper = new TroubleCodeWrapperMock();
        troubleCodeWrapper.wrapTroubleCodeReturnValue = expectedTroubleCodes[0];

        TruckWrapperMock truckWrapper = new TruckWrapperMock();
        truckWrapper.wrapReturnValue = expectedTruck;

        FSL_WorkOrderJsonWrapper.ServiceWrapper wrapper = new FSL_WorkOrderJsonWrapper.ServiceWrapper( facilityWrapper, policyWrapper, providedServiceWrapper, serviceLocationWrapper, statusWrapper, troubleCodeWrapper, truckWrapper );

        System.assertEquals( 0, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has been called' );
        System.assertEquals( 0, policyWrapper.wrapCallCount, 'PolicyWrapper.wrap has been called' );
        System.assertEquals( 0, providedServiceWrapper.wrapCallCount, 'ProvidedServiceWrapper.wrap has been called' );
        System.assertEquals( 0, serviceLocationWrapper.wrapCallCount, 'ServiceLocationWrapper.wrap has been called' );
        System.assertEquals( 0, statusWrapper.wrapCallCount, 'StatusWrapper.wrap has been called' );
        System.assertEquals( 0, troubleCodeWrapper.wrapTroubleCodeCallCount, 'TroubleCodeWrapper.wrap( TroubleCode ) has been called' );
        System.assertEquals( 0, troubleCodeWrapper.wrapResolutionCodeCallCount, 'TroubleCodeWrapper.wrap( ResolutionCode ) has been called' );
        System.assertEquals( 0, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Service service = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, service, 'Service is null' );
        System.assertEquals( 1, facilityWrapper.wrapCallCount, 'FacilityWrapper.wrap has not been called' );
        System.assertEquals( 1, policyWrapper.wrapCallCount, 'PolicyWrapper.wrap has not been called' );
        System.assertEquals( 1, providedServiceWrapper.wrapCallCount, 'ProvidedServiceWrapper.wrap has not been called' );
        System.assertEquals( 1, serviceLocationWrapper.wrapCallCount, 'ServiceLocationWrapper.wrap has not been called' );
        System.assertEquals( 1, statusWrapper.wrapCallCount, 'StatusWrapper.wrap has not been called' );
        System.assertEquals( 1, troubleCodeWrapper.wrapTroubleCodeCallCount, 'TroubleCodeWrapper.wrap( TroubleCode ) has not been called' );
        System.assertEquals( 0, troubleCodeWrapper.wrapResolutionCodeCallCount, 'TroubleCodeWrapper.wrap( ResolutionCode ) has been called' );
        System.assertEquals( 1, truckWrapper.wrapCallCount, 'TruckWrapper.wrap has not been called' );
        System.assertEquals( expectedAppointmentTime, service.appointmentTime, 'Appointment Time does not have the expected value' );
        System.assertEquals( expectedCallType, service.callType, 'Call Type does not have the expected value' );
        System.assertEquals( expectedCollision, service.collision, 'Collision does not have the expected value' );
        System.assertEquals( expectedFacility, service.facility, 'Facility does not have the expected value' );
        System.assertEquals( expectedFlatbedRequested, service.flatbedRequested, 'Flatbed Requested does not have the expected value' );
        System.assertEquals( expectedLegacyPriorityCode, service.legacyPriorityCode, 'Legacy Priority Code does not have the expected value' );
        System.assertEquals( expectedNeedsFlatbed, service.needsFlatbed, 'Needs Flatbed does not have the expected value' );
        System.assertEquals( expectedNumberOfPassengers, service.numberOfPassengers, 'Number Of Passengers does not have the expected value' );
        System.assertEquals( expectedPolicies, service.policies, 'Policies does not have the expected value' );
        System.assertEquals( expectedPriorityCode, service.priorityCode, 'Priority Code does not have the expected value' );
        System.assertEquals( expectedProvidedServices, service.providedServices, 'Provided Services does not have the expected value' );
        System.assertEquals( expectedRedFlag, service.redFlag, 'Red Flag does not have the expected value' );
        System.assertEquals( expectedServiceLocations, service.serviceLocations, 'Service Locations does not have the expected value' );
        System.assertEquals( expectedStatus, service.status, 'Status does not have the expected value' );
        System.assertEquals( expectedTimezoneId, service.timezoneId, 'Timezone Id does not have the expected value' );
        System.assertEquals( expectedTimezoneOffset, service.timezoneOffset, 'Timezone Offset does not have the expected value' );
        System.assertEquals( expectedTroubleCodes, service.troubleCodes, 'Trouble Codes does not have the expected value' );
        System.assertEquals( expectedTruck, service.truck, 'Truck does not have the expected value' );
    } */

    public class ServiceWrapperMock extends FSL_WorkOrderJsonWrapper.ServiceWrapper {
        public ServiceWrapperMock() {
            super( null, null, null, null, null, null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Service wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Service wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * StatusWrapper
    // *********************************************
    @IsTest
    public static void testStatusWrapper_Wrap_WorkOrderWithoutNullValues_Wrapped() {
        Datetime eta = Datetime.now();
        Datetime statusTimestamp = Datetime.now().addMinutes( -1 );
        Datetime pta = Datetime.now().addMinutes( -2 );
        Datetime scheduledStartTime = Datetime.now().addMinutes( -3 );
        String expectedEta = eta.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        string expectedModifiedDate = statusTimestamp.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expectedPta = pta.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expectedScheduledStartTime = scheduledStartTime.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        String expectedStatus = 'Status';
        Integer expectedWaitTime = 123;

        WorkOrder wo = new WorkOrder( Pta__c = pta, Status = expectedStatus, Wait_Time__c = expectedWaitTime + 0.1 ); 
        ServiceAppointment sa = new ServiceAppointment( ETA__c = eta, SchedStartTime = scheduledStartTime, Status = expectedStatus );
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;

        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;
        workOrder.getTowServiceAppointmentReturnValue = serviceAppointment;
        workOrder.getStatusTimestampReturnValue = statusTimestamp;

        FSL_WorkOrderJsonWrapper.StatusWrapper wrapper = new FSL_WorkOrderJsonWrapper.StatusWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Status status = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, status, 'Status is null' );
        System.assertEquals( expectedEta, status.eta, 'ETA does not have the expected value' );
        System.assertEquals( expectedModifiedDate, status.modifiedDate, 'Modified Date does not have the expected value' );
        System.assertEquals( expectedPta, status.pta, 'PTA does not have the expected value' );
        System.assertEquals( expectedScheduledStartTime, status.scheduleStartTime, 'Schedule Start Time does not have the expected value' );
        System.assertEquals( expectedStatus, status.status, 'Status does not have the expected value' );
        System.assertEquals( expectedWaitTime, status.waitTime, 'Wait Time does not have the expected value' );
    }
    
    @IsTest
    public static void testStatusWrapper_Wrap_WorkOrderWithNullValues_WrappedWithNulls() {
        Datetime eta = null;
        Datetime statusTimestamp = null;
        Datetime pta = null;
        Datetime scheduledStartTime = null;
        String expectedEta = null;
        string expectedModifiedDate = null;
        String expectedPta = null;
        String expectedScheduledStartTime = null;
        String expectedStatus = 'Status';
        Integer expectedWaitTime = null;

        WorkOrder wo = new WorkOrder( Pta__c = pta, Status = expectedStatus, Wait_Time__c = expectedWaitTime );
        ServiceAppointment sa = new ServiceAppointment( ETA__c = eta, SchedStartTime = scheduledStartTime, Status = expectedStatus);
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;

        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getBreakdownServiceAppointmentReturnValue = serviceAppointment;
        WorkOrder.getTowServiceAppointmentReturnValue = serviceAppointment;

        workOrder.getStatusTimestampReturnValue = statusTimestamp;

        FSL_WorkOrderJsonWrapper.StatusWrapper wrapper = new FSL_WorkOrderJsonWrapper.StatusWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Status status = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, status, 'Status is null' );
        System.assertEquals( expectedEta, status.eta, 'ETA does not have the expected value' );
        System.assertEquals( expectedModifiedDate, status.modifiedDate, 'Modified Date does not have the expected value' );
        System.assertEquals( expectedPta, status.pta, 'PTA does not have the expected value' );
        System.assertEquals( expectedScheduledStartTime, status.scheduleStartTime, 'Schedule Start Time does not have the expected value' );
        System.assertEquals( expectedStatus, status.status, 'Status does not have the expected value' );
        System.assertEquals( expectedWaitTime, status.waitTime, 'Wait Time does not have the expected value' );
    }

    public class StatusWrapperMock extends FSL_WorkOrderJsonWrapper.StatusWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Status wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Status wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * FacilityWrapper
    // *********************************************
    @IsTest
    public static void testFacilityWrapper_Wrap_WorkOrderAndFacilityNumberNotBlank_Wrapped() {
        String expectedFoiType = 'ADDRESS';
        String expectedId = 'Facility Number';
        FSL_WorkOrderJsonWrapper.Location expectedLocation = new FSL_WorkOrderJsonWrapper.Location();
        String expectedName = 'Facility Name';

        List<OperatingHours> operatingHours = Test.loadData( OperatingHours.SObjectType, 'FSL_OperatingHour' );

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Call_Id__c = '3333';
        wo.Status = 'Spotted';
        wo.Servicing_Technology_Type__c = 'Landline';
        wo.Vehicle_Profile__c = 'My Vehicle';
        insert wo;

        ServiceTerritory serviceTerritory = new ServiceTerritory( Name = expectedName, Facility_Number__c = expectedId, OperatingHoursId = operatingHours[0].Id, IsActive = true );
        insert serviceTerritory;

        ServiceAppointment sa = new ServiceAppointment( Work_Order__c = wo.Id, ParentRecordId = wo.Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = serviceTerritory.Id, Subject = 'Breakdown Appointment' );
        sa.SchedStartTime = System.now();
        sa.SchedEndTime = System.now() + 1800;
        sa.actualstarttime = System.now();
        sa.PTA__c = System.now();
        insert sa;
        sa = [SELECT Id, ServiceTerritory.Facility_Number__c, ServiceTerritory.Name FROM ServiceAppointment LIMIT 1];

        FSL_ServiceAppointmentTest.ServiceAppointmentMock breakdownServiceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        breakdownServiceAppointment.getServiceAppointmentReturnValue = sa;
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getBreakDownServiceAppointmentReturnValue = breakdownServiceAppointment;

        LocationWrapperMock locationWrapper = new LocationWrapperMock();
        locationWrapper.wrapReturnValue = expectedLocation;

        FSL_WorkOrderJsonWrapper.FacilityWrapper wrapper = new FSL_WorkOrderJsonWrapper.FacilityWrapper( locationWrapper );

        System.assertEquals( 0, locationWrapper.wrapCallCount, 'LocationWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Facility facility = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, facility, 'Facility is null' );
        System.assertEquals( 1, locationWrapper.wrapCallCount, 'LocationWrapper.wrap has not been called' );
        System.assertEquals( expectedFoiType, facility.foiType, 'Foi Type does not have the expected value' );
        System.assertEquals( expectedId, facility.id, 'Id does not have the expected value' );
        System.assertEquals( expectedLocation, facility.location, 'Id does not have the expected value' );
        System.assertEquals( expectedName, facility.name, 'Id does not have the expected value' );
    }
    
    @IsTest
    public static void testFacilityWrapper_Wrap_WorkOrderAndFacilityNumberNull_Wrapped() {
        String expectedFoiType = 'ADDRESS';
        String expectedId = 'FacilityNm';
        FSL_WorkOrderJsonWrapper.Location expectedLocation = new FSL_WorkOrderJsonWrapper.Location();
        String expectedName = 'Facility Name';

        List<OperatingHours> operatingHours = Test.loadData( OperatingHours.SObjectType, 'FSL_OperatingHour' );

        Account account = FSL_DataFactory.createAccount( expectedName );
        account.Facility_ID__c = expectedId;
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Call_Id__c = '3333';
        wo.Status = 'Spotted';
        wo.Servicing_Technology_Type__c = 'Landline';
        wo.Vehicle_Profile__c = 'My Vehicle';
        insert wo;

        ServiceTerritory serviceTerritory = new ServiceTerritory( Name = 'Another Name', Facility_Number__c = null, OperatingHoursId = operatingHours[0].Id, IsActive = true );
        insert serviceTerritory;

        ServiceAppointment sa = new ServiceAppointment( Work_Order__c = wo.Id, ParentRecordId = wo.Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = serviceTerritory.Id, Subject = 'Breakdown Appointment' );
        sa.SchedStartTime = System.now();
        sa.SchedEndTime = System.now() + 1800;
        sa.actualstarttime = System.now();
        sa.PTA__c = System.now();
        insert sa;
        sa = [SELECT Id, ServiceTerritory.Facility_Number__c, ServiceTerritory.Name FROM ServiceAppointment LIMIT 1];
        wo = [SELECT Id, Account.Facility_ID__c, Account.Name FROM WorkOrder LIMIT 1];

        FSL_ServiceAppointmentTest.ServiceAppointmentMock breakdownServiceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        breakdownServiceAppointment.getServiceAppointmentReturnValue = sa;
        FSL_WorkOrderTest.WorkOrderMock workOrder = new FSL_WorkOrderTest.WorkOrderMock();
        workOrder.getWorkOrderReturnValue = wo;
        workOrder.getBreakDownServiceAppointmentReturnValue = breakdownServiceAppointment;

        LocationWrapperMock locationWrapper = new LocationWrapperMock();
        locationWrapper.wrapReturnValue = expectedLocation;

        FSL_WorkOrderJsonWrapper.FacilityWrapper wrapper = new FSL_WorkOrderJsonWrapper.FacilityWrapper( locationWrapper );

        System.assertEquals( 0, locationWrapper.wrapCallCount, 'LocationWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Facility facility = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, facility, 'Facility is null' );
        System.assertEquals( 1, locationWrapper.wrapCallCount, 'LocationWrapper.wrap has not been called' );
        System.assertEquals( expectedFoiType, facility.foiType, 'Foi Type does not have the expected value' );
        System.assertEquals( expectedId, facility.id, 'Id does not have the expected value' );
        System.assertEquals( expectedLocation, facility.location, 'Id does not have the expected value' );
        System.assertEquals( expectedName, facility.name, 'Id does not have the expected value' );
    }

    public class FacilityWrapperMock extends FSL_WorkOrderJsonWrapper.FacilityWrapper {
        public FacilityWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Facility wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Facility wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * LocationWrapper
    // *********************************************
    @IsTest
    public static void testLocationWrapper_Wrap_NoParameters_EmtpyNotNullObject() {
        FSL_WorkOrderJsonWrapper.LocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.LocationWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Location location = wrapper.wrap();
        Test.stopTest();

        System.assertNotEquals( null, location, 'Location is null' );
    }

    public class LocationWrapperMock extends FSL_WorkOrderJsonWrapper.LocationWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Location wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Location wrap() {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * TruckWrapper
    // *********************************************
    @IsTest
    public static void testTruckWrapper_Wrap_ServiceResourceNotNull_Wrapped() {
        FSL_WorkOrderJsonWrapper.Driver expectedDriver = new FSL_WorkOrderJsonWrapper.Driver();
        String expectedId = 'Truck Id';

        Schema.Location vehicle = new Schema.Location( Truck_ID__c = expectedId, Name = 'Vehicle', IsInventoryLocation = true, IsMobile = true );
        insert vehicle;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'FSL Mobile (Fleet Technician)' LIMIT 1];
        User user = [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :profile.Id LIMIT 1];

        ServiceResource serviceResource = new ServiceResource( Vehicle__c = vehicle.Id, RelatedRecordId = user.Id, Name = 'Service Resource', IsActive = true );
        insert serviceResource;

        serviceResource = [SELECT Id, Vehicle__r.Truck_ID__c FROM ServiceResource LIMIT 1];

        DriverWrapperMock driverWrapper = new DriverWrapperMock();
        driverWrapper.wrapReturnValue = expectedDriver;

        FSL_WorkOrderJsonWrapper.TruckWrapper wrapper = new FSL_WorkOrderJsonWrapper.TruckWrapper( driverWrapper );

        System.assertEquals( 0, driverWrapper.wrapCallCount, 'DriverWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Truck truck = wrapper.wrap( serviceResource );
        Test.stopTest();

        System.assertNotEquals( null, truck, 'Truck is null' );
        System.assertEquals( 1, driverWrapper.wrapCallCount, 'DriverWrapper.wrap has not been called' );
        System.assertEquals( expectedDriver, truck.driver, 'Driver does not have the expected value' );
        System.assertEquals( expectedId, truck.id, 'Id does not have the expected value' );
    }
    
    @IsTest
    public static void testTruckWrapper_Wrap_ServiceResourceNull_WrappedWithIdNull() {
        FSL_WorkOrderJsonWrapper.Driver expectedDriver = new FSL_WorkOrderJsonWrapper.Driver();
        String expectedId = null;

        DriverWrapperMock driverWrapper = new DriverWrapperMock();
        driverWrapper.wrapReturnValue = expectedDriver;

        FSL_WorkOrderJsonWrapper.TruckWrapper wrapper = new FSL_WorkOrderJsonWrapper.TruckWrapper( driverWrapper );

        System.assertEquals( 0, driverWrapper.wrapCallCount, 'DriverWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Truck truck = wrapper.wrap( null );
        Test.stopTest();

        System.assertNotEquals( null, truck, 'Truck is null' );
        System.assertEquals( 1, driverWrapper.wrapCallCount, 'DriverWrapper.wrap has not been called' );
        System.assertEquals( expectedDriver, truck.driver, 'Driver does not have the expected value' );
        System.assertEquals( expectedId, truck.id, 'Id does not have the expected value' );
    }

    public class TruckWrapperMock extends FSL_WorkOrderJsonWrapper.TruckWrapper {
        public TruckWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Truck wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Truck wrap( ServiceResource serviceResource ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * DriverWrapper
    // *********************************************
    @IsTest
    public static void testDriverWrapper_Wrap_ServiceResourceWithDriverIdNotBlank_Wrapped() {
        String expectedId = 'Driver Id';
        FSL_WorkOrderJsonWrapper.DriverContact expectedContact = new FSL_WorkOrderJsonWrapper.DriverContact();

        ServiceResource serviceResource = new ServiceResource( Driver_Id__c = expectedId );

        DriverContactWrapperMock driverContactWrapper = new DriverContactWrapperMock();
        driverContactWrapper.wrapReturnValue = expectedContact;

        FSL_WorkOrderJsonWrapper.DriverWrapper wrapper = new FSL_WorkOrderJsonWrapper.DriverWrapper( driverContactWrapper );

        System.assertEquals( 0, driverContactWrapper.wrapCallCount, 'DriverContactWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Driver driver = wrapper.wrap( serviceResource );
        Test.stopTest();

        System.assertNotEquals( null, driver, 'Driver is null' );
        System.assertEquals( 1, driverContactWrapper.wrapCallCount, 'DriverContactWrapper.wrap has not been called' );
        System.assertEquals( expectedId, driver.id, 'Id does not have the expected value' );
        System.assertEquals( expectedContact, driver.contact, 'Id does not have the expected value' );
    }

    @IsTest
    public static void testDriverWrapper_Wrap_ServiceResourceWithDriverIdNull_WrappedWithIdEmpty() {
        String expectedId = '';
        FSL_WorkOrderJsonWrapper.DriverContact expectedContact = new FSL_WorkOrderJsonWrapper.DriverContact();

        ServiceResource serviceResource = new ServiceResource( Driver_Id__c = null );

        DriverContactWrapperMock driverContactWrapper = new DriverContactWrapperMock();
        driverContactWrapper.wrapReturnValue = expectedContact;

        FSL_WorkOrderJsonWrapper.DriverWrapper wrapper = new FSL_WorkOrderJsonWrapper.DriverWrapper( driverContactWrapper );

        System.assertEquals( 0, driverContactWrapper.wrapCallCount, 'DriverContactWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Driver driver = wrapper.wrap( serviceResource );
        Test.stopTest();

        System.assertNotEquals( null, driver, 'Driver is null' );
        System.assertEquals( 1, driverContactWrapper.wrapCallCount, 'DriverContactWrapper.wrap has not been called' );
        System.assertEquals( expectedId, driver.id, 'Id does not have the expected value' );
        System.assertEquals( expectedContact, driver.contact, 'Id does not have the expected value' );
    }

    @IsTest
    public static void testDriverWrapper_Wrap_ServiceResourceNull_WrappedWithNulls() {
        String expectedId = null;
        FSL_WorkOrderJsonWrapper.DriverContact expectedContact = null;

        ServiceResource serviceResource = null;

        FSL_WorkOrderJsonWrapper.DriverWrapper wrapper = new FSL_WorkOrderJsonWrapper.DriverWrapper( null );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Driver driver = wrapper.wrap( serviceResource );
        Test.stopTest();

        System.assertNotEquals( null, driver, 'Driver is null' );
        System.assertEquals( expectedId, driver.id, 'Id does not have the expected value' );
        System.assertEquals( expectedContact, driver.contact, 'Id does not have the expected value' );
    }

    public class DriverWrapperMock extends FSL_WorkOrderJsonWrapper.DriverWrapper {
        public DriverWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Driver wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Driver wrap( ServiceResource serviceResource ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * DriverContactWrapper
    // *********************************************
    @IsTest
    public static void testDriverContactWrapper_Wrap_ServiceResource_Wrapped() {
        String expectedContactType = 'DRIVER';
        String expectedLastName = 'Last Name';

        ServiceResource serviceResource = new ServiceResource( Name = expectedLastName );

        FSL_WorkOrderJsonWrapper.DriverContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.DriverContactWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.DriverContact driverContact = wrapper.wrap( serviceResource );
        Test.stopTest();

        System.assertNotEquals( null, driverContact, 'Driver Contact is null' );
        System.assertEquals( expectedContactType, driverContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedLastName, driverContact.lastName, 'Last Name does not have the expected value' );
    }

    public class DriverContactWrapperMock extends FSL_WorkOrderJsonWrapper.DriverContactWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.DriverContact wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.DriverContact wrap( ServiceResource serviceResource ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * TroubleCodeWrapper
    // *********************************************
    @IsTest
    public static void testTroubleCodeWrapper_Wrap_TroubleCode_Wrapped() {
        String expectedCode = 'Code';
        String expectedDescription = 'Description';
        String expectedTroubleCodeType = 'Trouble Code Type';

        FSL_TroubleCode__c tc = new FSL_TroubleCode__c( Code__c = expectedCode, Description__c = expectedDescription, Type__c = expectedTroubleCodeType );

        FSL_WorkOrderJsonWrapper.TroubleCodeWrapper wrapper = new FSL_WorkOrderJsonWrapper.TroubleCodeWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.TroubleCode troubleCode = wrapper.wrap( tc );
        Test.stopTest();

        System.assertNotEquals( null, troubleCode, 'Trouble Code is null' );
        System.assertEquals( expectedCode, troubleCode.code, 'Code does not have the expected value' );
        System.assertEquals( expectedDescription, troubleCode.description, 'Description does not have the expected value' );
        System.assertEquals( expectedTroubleCodeType, troubleCode.troubleCodeType, 'Trouble Code Type does not have the expected value' );
    }
    
    @IsTest
    public static void testTroubleCodeWrapper_Wrap_ResolutionCode_Wrapped() {
        String expectedCode = 'Code';
        String expectedDescription = '';
        String expectedTroubleCodeType = 'RESOLUTION';

        FSL_WorkOrderJsonWrapper.TroubleCodeWrapper wrapper = new FSL_WorkOrderJsonWrapper.TroubleCodeWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.TroubleCode troubleCode = wrapper.wrap( expectedCode );
        Test.stopTest();

        System.assertNotEquals( null, troubleCode, 'Trouble Code is null' );
        System.assertEquals( expectedCode, troubleCode.code, 'Code does not have the expected value' );
        System.assertEquals( expectedDescription, troubleCode.description, 'Description does not have the expected value' );
        System.assertEquals( expectedTroubleCodeType, troubleCode.troubleCodeType, 'Trouble Code Type does not have the expected value' );
    }

    public class TroubleCodeWrapperMock extends FSL_WorkOrderJsonWrapper.TroubleCodeWrapper {
        public Integer wrapTroubleCodeCallCount = 0;
        public FSL_WorkOrderJsonWrapper.TroubleCode wrapTroubleCodeReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.TroubleCode wrap( FSL_TroubleCode__c tc ) {
            wrapTroubleCodeCallCount++;
            return wrapTroubleCodeReturnValue;
        }

        public Integer wrapResolutionCodeCallCount = 0;
        public FSL_WorkOrderJsonWrapper.TroubleCode wrapResolutionCodeReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.TroubleCode wrap( String resolutionCode ) {
            wrapResolutionCodeCallCount++;
            return wrapResolutionCodeReturnValue;
        }
    }
    
    // *********************************************
    // * ServiceLocationWrapper
    // *********************************************
    @IsTest
    public static void testServiceLocationWrapper_Wrap_BreakdownServiceAppointmentAndWorkOrder_Wrapped() {
        String expectedDropBoxInfo = null;
        FSL_WorkOrderJsonWrapper.Foi expectedFoi = new FSL_WorkOrderJsonWrapper.Foi();
        Integer expectedMileageCalculated = 123;
        String expectedServiceLocationType = 'BREAKDOWN';

        ServiceAppointment sa = new ServiceAppointment( FSL_Actual_Miles_Driven__c = expectedMileageCalculated + 0.4 );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN;

        FoiWrapperMock foiWrapper = new FoiWrapperMock();
        foiWrapper.wrapReturnValue = expectedFoi;

        FSL_WorkOrderJsonWrapper.ServiceLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.ServiceLocationWrapper( foiWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, foiWrapper.wrapCallCount, 'FoiWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ServiceLocation serviceLocation = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, serviceLocation, 'Service Location is null' );
        System.assertEquals( 2, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 2 times' );
        System.assertEquals( 1, foiWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has not been called' );
        System.assertEquals( expectedDropBoxInfo, serviceLocation.dropBoxInfo, 'Dropbox Info does not have the expected value' );
        System.assertEquals( expectedFoi, serviceLocation.foi, 'Foi does not have the expected value' );
        System.assertEquals( expectedMileageCalculated, serviceLocation.mileageCalculated, 'Mileage Calculated does not have the expected value' );
        System.assertEquals( expectedServiceLocationType, serviceLocation.serviceLocationType, 'Service Location Type does not have the expected value' );
    }

    @IsTest
    public static void testServiceLocationWrapper_Wrap_TowServiceAppointmentAndWorkOrder_Wrapped() {
        String expectedDropBoxInfo = 'Drop Box Info';
        FSL_WorkOrderJsonWrapper.Foi expectedFoi = new FSL_WorkOrderJsonWrapper.Foi();
        Integer expectedMileageCalculated = 123;
        String expectedServiceLocationType = 'TOW_DESTINATION';

        ServiceAppointment sa = new ServiceAppointment( Drop_Box_Info__c = expectedDropBoxInfo, FSL_Actual_Miles_Driven__c = expectedMileageCalculated - 0.4 );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.TOW;

        FoiWrapperMock foiWrapper = new FoiWrapperMock();
        foiWrapper.wrapReturnValue = expectedFoi;

        FSL_WorkOrderJsonWrapper.ServiceLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.ServiceLocationWrapper( foiWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, foiWrapper.wrapCallCount, 'FoiWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ServiceLocation serviceLocation = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, serviceLocation, 'Service Location is null' );
        System.assertEquals( 3, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 2 times' );
        System.assertEquals( 1, foiWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has not been called' );
        System.assertEquals( expectedDropBoxInfo, serviceLocation.dropBoxInfo, 'Dropbox Info does not have the expected value' );
        System.assertEquals( expectedFoi, serviceLocation.foi, 'Foi does not have the expected value' );
        System.assertEquals( expectedMileageCalculated, serviceLocation.mileageCalculated, 'Mileage Calculated does not have the expected value' );
        System.assertEquals( expectedServiceLocationType, serviceLocation.serviceLocationType, 'Service Location Type does not have the expected value' );
    }

    public class ServiceLocationWrapperMock extends FSL_WorkOrderJsonWrapper.ServiceLocationWrapper {
        public ServiceLocationWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.ServiceLocation wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.ServiceLocation wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * FoiWrapper
    // *********************************************
    @IsTest
    public static void testFoiWrapper_Wrap_BreakdownServiceAppointmentAndWorkOrder_WrappedWithContactsAndNameNull() {
              List<FSL_WorkOrderJsonWrapper.Contact> expectedContacts = new List<FSL_WorkOrderJsonWrapper.Contact>();
        String expectedFoiType = 'ADDRESS';
        FSL_WorkOrderJsonWrapper.BreakdownLocation expectedLocation = new FSL_WorkOrderJsonWrapper.BreakdownLocation();
        String expectedName = null;

        ServiceAppointment sa = new ServiceAppointment();
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN;

        BreakdownLocationWrapperMock breakdownLocationWrapper = new BreakdownLocationWrapperMock();
        breakdownLocationWrapper.wrapReturnValue = expectedLocation;

        FSL_WorkOrderJsonWrapper.FoiWrapper wrapper = new FSL_WorkOrderJsonWrapper.FoiWrapper( breakdownLocationWrapper, null );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, breakdownLocationWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Foi foi = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, foi, 'Foi is null' );
        System.assertEquals( 2, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 2 times' );
        System.assertEquals( 1, breakdownLocationWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has not been called' );
        System.assertEquals( expectedContacts, foi.contacts, 'Contacts does not have the expected value' );
        System.assertEquals( expectedFoiType, foi.foiType, 'Foi Type does not have the expected value' );
        System.assertEquals( expectedLocation, foi.location, 'Location does not have the expected value' );
        System.assertEquals( expectedName, foi.name, 'Name does not have the expected value' );
    }

    @IsTest
    public static void testFoiWrapper_Wrap_TowServiceAppointmentAndWorkOrder_Wrapped() {
        List<FSL_WorkOrderJsonWrapper.Contact> expectedContacts = new List<FSL_WorkOrderJsonWrapper.Contact>{ new FSL_WorkOrderJsonWrapper.Contact() };
        String expectedFoiType = 'ADDRESS';
        FSL_WorkOrderJsonWrapper.BreakdownLocation expectedLocation = new FSL_WorkOrderJsonWrapper.BreakdownLocation();
        String expectedName = 'Name';

        ServiceAppointment sa = new ServiceAppointment( Tow_Destination_Name__c = expectedName );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.TOW;

        BreakdownLocationWrapperMock breakdownLocationWrapper = new BreakdownLocationWrapperMock();
        breakdownLocationWrapper.wrapReturnValue = expectedLocation;

        ContactWrapperMock contactWrapper = new ContactWrapperMock();
        contactWrapper.wrapReturnValue = expectedContacts[0];

        FSL_WorkOrderJsonWrapper.FoiWrapper wrapper = new FSL_WorkOrderJsonWrapper.FoiWrapper( breakdownLocationWrapper, contactWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, breakdownLocationWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has been called' );
        System.assertEquals( 0, contactWrapper.wrapCallCount, 'ContactWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Foi foi = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, foi, 'Foi is null' );
        System.assertEquals( 2, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 2 times' );
        System.assertEquals( 1, breakdownLocationWrapper.wrapCallCount, 'BreakdownLocationWrapper.wrap has not been called' );
        System.assertEquals( expectedContacts, foi.contacts, 'Contacts does not have the expected value' );
        System.assertEquals( expectedFoiType, foi.foiType, 'Foi Type does not have the expected value' );
        System.assertEquals( expectedLocation, foi.location, 'Location does not have the expected value' );
        System.assertEquals( expectedName, foi.name, 'Name does not have the expected value' );
    }

    public class FoiWrapperMock extends FSL_WorkOrderJsonWrapper.FoiWrapper {
        public FoiWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Foi wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Foi wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * BreakdownLocationWrapper
    // *********************************************
    @IsTest
    public static void testBreakdownLocationWrapper_Wrap_BreakdownServiceAppointmentWithAddressChangeAndWorkOrder_Wrapped() {
        FSL_WorkOrderJsonWrapper.BreakdownAddress expectedAddress = new FSL_WorkOrderJsonWrapper.BreakdownAddress();
        String expectedHighway = 'Highway';
        String expectedLandmark = 'Landmark';
        Double expectedLatitude = 123.45;
        String expectedLocationCode = 'Location Code';
        Double expectedLongitude = 456.78;
        String expectedMileMarker = 'Mile Marker';

        ServiceAppointment sa = new ServiceAppointment( Highway__c = expectedHighway, Landmark__c = expectedLandmark, Location_Code__c = expectedLocationCode, Mile_Marker__c = expectedMileMarker, Latitude = expectedLatitude, Longitude = expectedLongitude );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN;
        serviceAppointment.hasAddressChangedReturnValue = true;

        BreakDownAddressWrapperMock breakdownAddressWrapper = new BreakDownAddressWrapperMock();
        breakdownAddressWrapper.wrapReturnValue = expectedAddress;
        FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper( breakdownAddressWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has been called' );
        System.assertEquals( 0, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.BreakdownLocation breakdownLocation = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, breakdownLocation, 'Breakdown Location is null' );
        System.assertEquals( 3, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 3 times' );
        System.assertEquals( 2, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has not been called 2 times' );
        System.assertEquals( 1, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has not been called' );
        System.assertEquals( expectedAddress, breakdownLocation.address, 'Address does not have the expected value' );
        System.assertEquals( expectedHighway, breakdownLocation.highway, 'Highway does not have the expected value' );
        System.assertEquals( expectedLandmark, breakdownLocation.landmark, 'Landmark does not have the expected value' );
        System.assertEquals( expectedLatitude, breakdownLocation.latitude, 'Latitude does not have the expected value' );
        System.assertEquals( expectedLocationCode, breakdownLocation.locationCode, 'Location Code does not have the expected value' );
        System.assertEquals( expectedLongitude, breakdownLocation.longitude, 'Longitude does not have the expected value' );
        System.assertEquals( expectedMileMarker, breakdownLocation.mileMarker, 'Mile Marker does not have the expected value' );
    }
    
    @IsTest
    public static void testBreakdownLocationWrapper_Wrap_BreakdownServiceAppointmentWithoutAddressChangeAndWorkOrder_Wrapped() {
        FSL_WorkOrderJsonWrapper.BreakdownAddress expectedAddress = new FSL_WorkOrderJsonWrapper.BreakdownAddress();
        String expectedHighway = 'Highway';
        String expectedLandmark = 'Landmark';
        Double expectedLatitude = 123.45;
        String expectedLocationCode = 'Location Code';
        Double expectedLongitude = 456.78;
        String expectedMileMarker = 'Mile Marker';

        ServiceAppointment sa = new ServiceAppointment( Highway__c = expectedHighway, Landmark__c = expectedLandmark, Location_Code__c = expectedLocationCode, Mile_Marker__c = expectedMileMarker );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN;
        serviceAppointment.hasAddressChangedReturnValue = false;

        WorkOrder workOrder = new WorkOrder( Breakdown_Location__Latitude__s = expectedLatitude, Breakdown_Location__Longitude__s = expectedLongitude );

        BreakDownAddressWrapperMock breakdownAddressWrapper = new BreakDownAddressWrapperMock();
        breakdownAddressWrapper.wrapReturnValue = expectedAddress;
        FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper( breakdownAddressWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has been called' );
        System.assertEquals( 0, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.BreakdownLocation breakdownLocation = wrapper.wrap( serviceAppointment, workOrder );
        Test.stopTest();

        System.assertNotEquals( null, breakdownLocation, 'Breakdown Location is null' );
        System.assertEquals( 5, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 5 times' );
        System.assertEquals( 2, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has not been called 2 times' );
        System.assertEquals( 1, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has not been called' );
        System.assertEquals( expectedAddress, breakdownLocation.address, 'Address does not have the expected value' );
        System.assertEquals( expectedHighway, breakdownLocation.highway, 'Highway does not have the expected value' );
        System.assertEquals( expectedLandmark, breakdownLocation.landmark, 'Landmark does not have the expected value' );
        System.assertEquals( expectedLatitude, breakdownLocation.latitude, 'Latitude does not have the expected value' );
        System.assertEquals( expectedLocationCode, breakdownLocation.locationCode, 'Location Code does not have the expected value' );
        System.assertEquals( expectedLongitude, breakdownLocation.longitude, 'Longitude does not have the expected value' );
        System.assertEquals( expectedMileMarker, breakdownLocation.mileMarker, 'Mile Marker does not have the expected value' );
    }

    @IsTest
    public static void testBreakdownLocationWrapper_Wrap_TowServiceAppointmentWithAddressChangeAndWorkOrder_Wrapped() {
        FSL_WorkOrderJsonWrapper.BreakdownAddress expectedAddress = new FSL_WorkOrderJsonWrapper.BreakdownAddress();
        String expectedHighway = null;
        String expectedLandmark = 'Landmark';
        Double expectedLatitude = 123.45;
        String expectedLocationCode = null;
        Double expectedLongitude = 456.78;
        String expectedMileMarker = null;

        ServiceAppointment sa = new ServiceAppointment( Highway__c = 'Highway', Landmark__c = expectedLandmark, Location_Code__c = 'Location Code', Mile_Marker__c = 'Mile Marker', Latitude = expectedLatitude, Longitude = expectedLongitude );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.TOW;
        serviceAppointment.hasAddressChangedReturnValue = true;

        BreakDownAddressWrapperMock breakdownAddressWrapper = new BreakDownAddressWrapperMock();
        breakdownAddressWrapper.wrapReturnValue = expectedAddress;
        FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper( breakdownAddressWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has been called' );
        System.assertEquals( 0, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.BreakdownLocation breakdownLocation = wrapper.wrap( serviceAppointment, null );
        Test.stopTest();

        System.assertNotEquals( null, breakdownLocation, 'Breakdown Location is null' );
        System.assertEquals( 3, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 3 times' );
        System.assertEquals( 2, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has not been called 2 times' );
        System.assertEquals( 1, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has not been called' );
        System.assertEquals( expectedAddress, breakdownLocation.address, 'Address does not have the expected value' );
        System.assertEquals( expectedHighway, breakdownLocation.highway, 'Highway does not have the expected value' );
        System.assertEquals( expectedLandmark, breakdownLocation.landmark, 'Landmark does not have the expected value' );
        System.assertEquals( expectedLatitude, breakdownLocation.latitude, 'Latitude does not have the expected value' );
        System.assertEquals( expectedLocationCode, breakdownLocation.locationCode, 'Location Code does not have the expected value' );
        System.assertEquals( expectedLongitude, breakdownLocation.longitude, 'Longitude does not have the expected value' );
        System.assertEquals( expectedMileMarker, breakdownLocation.mileMarker, 'Mile Marker does not have the expected value' );
    }
    
    @IsTest
    public static void testBreakdownLocationWrapper_Wrap_TowServiceAppointmentWithoutAddressChangeAndWorkOrder_Wrapped() {
        FSL_WorkOrderJsonWrapper.BreakdownAddress expectedAddress = new FSL_WorkOrderJsonWrapper.BreakdownAddress();
        String expectedHighway = null;
        String expectedLandmark = 'Landmark';
        Double expectedLatitude = 123.45;
        String expectedLocationCode = null;
        Double expectedLongitude = 456.78;
        String expectedMileMarker = null;

        ServiceAppointment sa = new ServiceAppointment( Highway__c = 'Highway', Landmark__c = expectedLandmark, Location_Code__c = 'Location Code', Mile_Marker__c = 'Mile Marker', Latitude = expectedLatitude, Longitude = expectedLongitude );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getServiceAppointmentTypeReturnValue = FSL_ServiceAppointment.ServiceAppointmentType.TOW;
        serviceAppointment.hasAddressChangedReturnValue = false;

        WorkOrder workOrder = new WorkOrder( Tow_Location__Latitude__s = expectedLatitude, Tow_Location__Longitude__s = expectedLongitude );

        BreakDownAddressWrapperMock breakdownAddressWrapper = new BreakDownAddressWrapperMock();
        breakdownAddressWrapper.wrapReturnValue = expectedAddress;
        FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper wrapper = new FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper( breakdownAddressWrapper );

        System.assertEquals( 0, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has been called' );
        System.assertEquals( 0, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has been called' );
        System.assertEquals( 0, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.BreakdownLocation breakdownLocation = wrapper.wrap( serviceAppointment, workOrder );
        Test.stopTest();

        System.assertNotEquals( null, breakdownLocation, 'Breakdown Location is null' );
        System.assertEquals( 7, serviceAppointment.getServiceAppointmentTypeCallCount, 'ServiceAppointment.getServiceAppointmentType has not been called 7 times' );
        System.assertEquals( 2, serviceAppointment.hasAddressChangedCallCount, 'ServiceAppointment.hasAddressChanged has not been called 2 times' );
        System.assertEquals( 1, breakdownAddressWrapper.wrapCallCount, 'BreakdownAddressWrapper.wrap has not been called' );
        System.assertEquals( expectedAddress, breakdownLocation.address, 'Address does not have the expected value' );
        System.assertEquals( expectedHighway, breakdownLocation.highway, 'Highway does not have the expected value' );
        System.assertEquals( expectedLandmark, breakdownLocation.landmark, 'Landmark does not have the expected value' );
        System.assertEquals( expectedLatitude, breakdownLocation.latitude, 'Latitude does not have the expected value' );
        System.assertEquals( expectedLocationCode, breakdownLocation.locationCode, 'Location Code does not have the expected value' );
        System.assertEquals( expectedLongitude, breakdownLocation.longitude, 'Longitude does not have the expected value' );
        System.assertEquals( expectedMileMarker, breakdownLocation.mileMarker, 'Mile Marker does not have the expected value' );
    }

    public class BreakdownLocationWrapperMock extends FSL_WorkOrderJsonWrapper.BreakdownLocationWrapper {
        public BreakdownLocationWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.BreakdownLocation wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.BreakdownLocation wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * BreakdownAddressWrapper
    // *********************************************
    @IsTest
    public static void testBreakdownAddressWrapper_Wrap_ServiceAppointment_Wrapped() {
        String expectedAddressType = 'PHYSICAL';
        String expectedCity = 'City';
        String expectedCountry = 'Country';
        String expectedCrossStreet = 'Cross Street';
        String expectedCrossStreet2 = 'Cross Street 2';
        String expectedFull = 'Full';
        String expectedPostalCode = 'Postal Code';
        String expectedState = 'State';
        String expectedStreetName = 'Street Name';

        ServiceAppointment sa = new ServiceAppointment( City = expectedCity, Country = expectedCountry, Cross_Street__c = expectedCrossStreet, Cross_Street_2__c = expectedCrossStreet2, PostalCode = expectedPostalCode, State = expectedState, Street = expectedStreetName );
        FSL_ServiceAppointmentTest.ServiceAppointmentMock serviceAppointment = new FSL_ServiceAppointmentTest.ServiceAppointmentMock();
        serviceAppointment.getServiceAppointmentReturnValue = sa;
        serviceAppointment.getFullAddressReturnValue = expectedFull;

        FSL_WorkOrderJsonWrapper.BreakdownAddressWrapper wrapper = new FSL_WorkOrderJsonWrapper.BreakdownAddressWrapper();

        System.assertEquals( 0, serviceAppointment.getFullAddressCallCount, 'ServiceAppointment.getFullAddress has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.BreakdownAddress breakdownAddress = wrapper.wrap( serviceAppointment );
        Test.stopTest();

        System.assertNotEquals( null, breakdownAddress, 'Breakdown Address is null' );
        System.assertEquals( 1, serviceAppointment.getFullAddressCallCount, 'ServiceAppointment.getFullAddress has not been called' );
        System.assertEquals( expectedAddressType, breakdownAddress.addressType, 'Address Type does not have the expected value' );
        System.assertEquals( expectedCity, breakdownAddress.city, 'City does not have the expected value' );
        System.assertEquals( expectedCountry, breakdownAddress.country, 'Country does not have the expected value' );
        System.assertEquals( expectedCrossStreet, breakdownAddress.crossStreet, 'Cross Street does not have the expected value' );
        System.assertEquals( expectedCrossStreet2, breakdownAddress.crossStreet2, 'Cross Street 2 does not have the expected value' );
        System.assertEquals( expectedFull, breakdownAddress.full, 'Full does not have the expected value' );
        System.assertEquals( expectedPostalCode, breakdownAddress.postalCode, 'Postal Code does not have the expected value' );
        System.assertEquals( expectedState, breakdownAddress.state, 'State does not have the expected value' );
        System.assertEquals( expectedStreetName, breakdownAddress.streetName, 'Street Name does not have the expected value' );
    }
    
    public class BreakdownAddressWrapperMock extends FSL_WorkOrderJsonWrapper.BreakdownAddressWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.BreakdownAddress wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.BreakdownAddress wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * ContactWrapper
    // *********************************************
    @IsTest
    public static void testContactWrapper_Wrap_WorkOrderWithPhone_WrappedWithPhones() {
        String expectedContactType = 'TOWDEST';
        String expectedFirstName = 'First Name';
        String expectedLastName = 'Last Name';
        List<FSL_WorkOrderJsonWrapper.ContactPhone> expectedPhones = new List<FSL_WorkOrderJsonWrapper.ContactPhone>{ new FSL_WorkOrderJsonWrapper.ContactPhone() };

        WorkOrder workOrder = new WorkOrder( Tow_Contact_First_Name__c = expectedFirstName, Tow_Contact_Last_Name__c = expectedLastName, Tow_Contact_Phone_Number__c = 'Not Null' );

        ContactPhoneWrapperMock contactPhoneWrapper = new ContactPhoneWrapperMock();
        contactPhoneWrapper.wrapReturnValue = expectedPhones[0];
        FSL_WorkOrderJsonWrapper.ContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.ContactWrapper( contactPhoneWrapper );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Contact contact = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, contact, 'Contact is null' );
        System.assertEquals( expectedContactType, contact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedFirstName, contact.firstName, 'First Name does not have the expected value' );
        System.assertEquals( expectedLastName, contact.lastName, 'Last Name does not have the expected value' );
        System.assertEquals( expectedPhones, contact.phones, 'Phones does not have the expected value' );
    }
    
    @IsTest
    public static void testContactWrapper_Wrap_WorkOrderWithNullPhone_WrappedWithPhonesNull() {
        String expectedContactType = 'TOWDEST';
        String expectedFirstName = 'First Name';
        String expectedLastName = 'Last Name';
        List<FSL_WorkOrderJsonWrapper.ContactPhone> expectedPhones = new List<FSL_WorkOrderJsonWrapper.ContactPhone>();

        WorkOrder workOrder = new WorkOrder( Tow_Contact_First_Name__c = expectedFirstName, Tow_Contact_Last_Name__c = expectedLastName, Tow_Contact_Phone_Number__c = null );

        ContactPhoneWrapperMock contactPhoneWrapper = new ContactPhoneWrapperMock();
        FSL_WorkOrderJsonWrapper.ContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.ContactWrapper( contactPhoneWrapper );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Contact contact = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, contact, 'Contact is null' );
        System.assertEquals( expectedContactType, contact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedFirstName, contact.firstName, 'First Name does not have the expected value' );
        System.assertEquals( expectedLastName, contact.lastName, 'Last Name does not have the expected value' );
        System.assertEquals( expectedPhones, contact.phones, 'Phones does not have the expected value' );
    }

    public virtual class ContactWrapperMock extends FSL_WorkOrderJsonWrapper.ContactWrapper {
        public ContactWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Contact wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Contact wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * ContactPhoneWrapper
    // *********************************************
    @IsTest
    public static void testContactPhoneWrapper_Wrap_WorkOrder_Wrapped() {
        String expectedPhoneNumber = 'Phone Number';
        String expectedPhoneType = 'BUSINESS';

        WorkOrder workOrder = new WorkOrder( Tow_Contact_Phone_Number__c = expectedPhoneNumber );

        FSL_WorkOrderJsonWrapper.ContactPhoneWrapper wrapper = new FSL_WorkOrderJsonWrapper.ContactPhoneWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ContactPhone phone = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, phone, 'Phone is null' );
        System.assertEquals( expectedPhoneNumber, phone.phoneNumber, 'Phone Number does not have the expected value' );
        System.assertEquals( expectedPhoneType, phone.phoneType, 'Phone Type does not have the expected value' );
    }

    public class ContactPhoneWrapperMock extends FSL_WorkOrderJsonWrapper.ContactPhoneWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.ContactPhone wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.ContactPhone wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * PolicyWrapper
    // *********************************************
    @IsTest
    public static void testPolicyWrapper_Wrap_Policy_Wrapped() {
        String expectedCode = 'Code';
        String expectedDescription = 'Description';

        FSL_Policy__c p = new FSL_Policy__c( Policy_Code__c = expectedCode, Policy_Description__c = expectedDescription );

        FSL_WorkOrderJsonWrapper.PolicyWrapper wrapper = new FSL_WorkOrderJsonWrapper.PolicyWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Policy policy = wrapper.wrap( p );
        Test.stopTest();

        System.assertNotEquals( null, policy, 'Policy is null' );
        System.assertEquals( expectedCode, policy.code, 'Code does not have the expected value' );
        System.assertEquals( expectedDescription, policy.description, 'Description does not have the expected value' );
    }

    public class PolicyWrapperMock extends FSL_WorkOrderJsonWrapper.PolicyWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Policy wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Policy wrap( FSL_Policy__c workOrderPolicy ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * ProvidedServiceWrapper
    // *********************************************
    @IsTest
    public static void testProvidedServiceWrapper_Wrap_ServiceLineItemWithNotNullUnit_Wrapped() {
        FSL_WorkOrderJsonWrapper.Charge expectedCharge = new FSL_WorkOrderJsonWrapper.Charge();
        Double unit = 123.00;
        Integer expectedQuantity = 123;
        String expectedService = 'Service';

        String expectedAppointmentTime = 'Appointment Time';
        String expectedCallType = 'Call Type';
        Boolean expectedCollision = true;
        Boolean expectedFlatbedRequested = true;
        Boolean expectedNeedsFlatbed = true;
        Integer expectedNumberOfPassengers = 123;
        String expectedPriorityCode = 'Priority Code';
        Boolean expectedRedFlag = true;
        String expectedTimezoneId = 'Timezone Id';
        String expectedTimezoneOffset = 'Timezone Offset';
        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Non_Emergency_Appointment_Time__c = expectedAppointmentTime;
        wo.Call_Type__c = expectedCallType;
        wo.Collision__c = expectedCollision;
        wo.Flatbed_Requested__c = expectedFlatbedRequested;
        wo.Needs_Flatbed__c = expectedNeedsFlatbed;
        wo.Number_Of_Passengers__c = expectedNumberOfPassengers;
        wo.Red_Flag__c = expectedRedFlag;
        insert wo;


        Product2 product = new Product2( Name = 'Product', ProductCode = expectedService,Family = 'Service Item' );
        insert product;

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Unit__c = unit, Product__c = product.Id ,Work_Order__c = wo.Id  );
        insert serviceLineItem;

        serviceLineItem = [SELECT Id, Unit__c, Product__r.ProductCode FROM FSL_Service_Line_Item__c LIMIT 1];

        ChargeWrapperMock chargeWrapper = new ChargeWrapperMock();
        chargeWrapper.wrapReturnValue = expectedCharge;
        FSL_WorkOrderJsonWrapper.ProvidedServiceWrapper wrapper = new FSL_WorkOrderJsonWrapper.ProvidedServiceWrapper( chargeWrapper );

        System.assertEquals( 0, chargeWrapper.wrapCallCount, 'ChargeWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ProvidedService providedService = wrapper.wrap( serviceLineItem );
        Test.stopTest();

        System.assertNotEquals( null, providedService, 'Provided Service is null' );
        System.assertEquals( 1, chargeWrapper.wrapCallCount, 'ChargeWrapper.wrap has not been called' );
        System.assertEquals( expectedCharge, providedService.charge, 'Charge does not have the expected value' );
        System.assertEquals( expectedQuantity, providedService.quantity, 'Charge does not have the expected value' );
        System.assertEquals( expectedService, providedService.service, 'Charge does not have the expected value' );
    }
    
   /* @IsTest
    public static void testProvidedServiceWrapper_Wrap_ServiceLineItemWithNullUnit_WrappedWithQuantityZero() {
        FSL_WorkOrderJsonWrapper.Charge expectedCharge = new FSL_WorkOrderJsonWrapper.Charge();
        Double unit = null;
        Integer expectedQuantity = 0;
        String expectedService = 'Service';

        String expectedAppointmentTime = 'Appointment Time';
        String expectedCallType = 'Call Type';
        Boolean expectedCollision = true;
        Boolean expectedFlatbedRequested = true;
        Boolean expectedNeedsFlatbed = true;
        Integer expectedNumberOfPassengers = 123;
        String expectedPriorityCode = 'Priority Code';
        Boolean expectedRedFlag = true;
        String expectedTimezoneId = 'Timezone Id';
        String expectedTimezoneOffset = 'Timezone Offset';
        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.External_Id__c = 'ERS-12345';
        wo.Non_Emergency_Appointment_Time__c = expectedAppointmentTime;
        wo.Call_Type__c = expectedCallType;
        wo.Collision__c = expectedCollision;
        wo.Flatbed_Requested__c = expectedFlatbedRequested;
        wo.Needs_Flatbed__c = expectedNeedsFlatbed;
        wo.Number_Of_Passengers__c = expectedNumberOfPassengers;
        wo.Red_Flag__c = expectedRedFlag;
        insert wo;

        Product2 product = new Product2( Name = 'Product', ProductCode = expectedService , Family = 'Service Item' );
        insert product;

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Unit__c = unit, Product__c = product.Id,Work_Order__c = wo.Id );
        insert serviceLineItem;

        serviceLineItem = [SELECT Id, Unit__c, Product__r.ProductCode FROM FSL_Service_Line_Item__c LIMIT 1];

        ChargeWrapperMock chargeWrapper = new ChargeWrapperMock();
        chargeWrapper.wrapReturnValue = expectedCharge;
        FSL_WorkOrderJsonWrapper.ProvidedServiceWrapper wrapper = new FSL_WorkOrderJsonWrapper.ProvidedServiceWrapper( chargeWrapper );

        System.assertEquals( 0, chargeWrapper.wrapCallCount, 'ChargeWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.ProvidedService providedService = wrapper.wrap( serviceLineItem );
        Test.stopTest();

        System.assertNotEquals( null, providedService, 'Provided Service is null' );
        System.assertEquals( 1, chargeWrapper.wrapCallCount, 'ChargeWrapper.wrap has not been called' );
        System.assertEquals( expectedCharge, providedService.charge, 'Charge does not have the expected value' );
        System.assertEquals( expectedQuantity, providedService.quantity, 'Charge does not have the expected value' );
        System.assertEquals( expectedService, providedService.service, 'Charge does not have the expected value' );
    } */

    public class ProvidedServiceWrapperMock extends FSL_WorkOrderJsonWrapper.ProvidedServiceWrapper {
        public ProvidedServiceWrapperMock() {
            super( null );
        }

        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.ProvidedService wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.ProvidedService wrap( FSL_Service_Line_Item__c serviceLineItem ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    } 

    // *********************************************
    // * ChargeWrapper
    // *********************************************
    @IsTest
    public static void testChargeWrapper_Wrap_ServiceLineItemWithCostNotNull_Wrapped() {
        Double cost = 123.45;
        String expectedAmount = String.valueOf( cost );

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Cost__c = cost );

        FSL_WorkOrderJsonWrapper.ChargeWrapper wrapper = new FSL_WorkOrderJsonWrapper.ChargeWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Charge charge = wrapper.wrap( serviceLineItem );
        Test.stopTest();

        System.assertNotEquals( null, charge, 'Charge is null' );
        System.assertEquals( expectedAmount, charge.amount, 'Amount does not have the expected value' );
    }

    @IsTest
    public static void testChargeWrapper_Wrap_ServiceLineItemWithCostNull_WrappedWithAmountNull() {
        Double cost = null;
        String expectedAmount = null;

        FSL_Service_Line_Item__c serviceLineItem = new FSL_Service_Line_Item__c( Cost__c = cost );

        FSL_WorkOrderJsonWrapper.ChargeWrapper wrapper = new FSL_WorkOrderJsonWrapper.ChargeWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Charge charge = wrapper.wrap( serviceLineItem );
        Test.stopTest();

        System.assertNotEquals( null, charge, 'Charge is null' );
        System.assertEquals( expectedAmount, charge.amount, 'Amount does not have the expected value' );
    }
    
    public class ChargeWrapperMock extends FSL_WorkOrderJsonWrapper.ChargeWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Charge wrapReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Charge wrap( FSL_Service_Line_Item__c serviceLineItem ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }
    
    // *********************************************
    // * PaymentWrapper
    // *********************************************
    @IsTest
    public static void testPaymentWrapper_Wrap_WorkOrder_Wrapped() {
        
        String expectedCodes = 'Codes';
        String expectedPaymentType = 'Payment Type' ;
        Boolean expectedRequired = true;
        String expectedName = 'Facility Name';

        List<OperatingHours> operatingHours = Test.loadData( OperatingHours.SObjectType, 'FSL_OperatingHour' );

        Account account = FSL_DataFactory.createAccount( expectedName );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder wo = new WorkOrder();
        wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        wo.Payment_Codes__c = expectedCodes;
        wo.Payment_Type__c = expectedPaymentType;// added here

        insert wo;

        ServiceTerritory serviceTerritory = new ServiceTerritory( Name = 'Another Name', Facility_Number__c = null, OperatingHoursId = operatingHours[0].Id, IsActive = true );
        insert serviceTerritory;

        ServiceAppointment sa = new ServiceAppointment( Work_Order__c = wo.Id, ParentRecordId = wo.Id, EarliestStartTime = DateTime.now(), ServiceTerritoryId = serviceTerritory.Id, Subject = 'Breakdown Appointment');
        sa.Payment_Type__c = expectedPaymentType;
        sa.Payment_Required__c = expectedRequired;
        sa.RecordTypeId =[Select Id,SobjectType,Name From RecordType WHERE Name ='Breakdown' and SobjectType ='ServiceAppointment'  limit 1].Id;
             
        insert sa;
        system.debug('sa 2670' + sa);
        wo = [SELECT Id, Payment_Codes__c, Payment_Type__c,
        (SELECT Id, isBreakdown__c, Payment_Type__c, Payment_Required__c
        FROM ServiceAppointments 
        WHERE parentRecordId =: wo.id)
        FROM WorkOrder LIMIT 1];
        
        System.debug('wo 2678' + wo);
                
        FSL_WorkOrderJsonWrapper.PaymentWrapper wrapper = new FSL_WorkOrderJsonWrapper.PaymentWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Payment payment = wrapper.wrap( wo );
        Test.stopTest();

        System.assertNotEquals( null, payment, 'Payment is null' );
        System.assertEquals( expectedCodes, payment.codes, 'Codes does not have the expected value' );
        System.assertEquals( expectedPaymentType, payment.paymentType, 'Payment Type does not have the expected value' );
        System.assertEquals( expectedRequired, payment.required, 'Required does not have the expected value' );
    }

    public class PaymentWrapperMock extends FSL_WorkOrderJsonWrapper.PaymentWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Payment wrapReturnValue = null;
        public override Payment wrap( WorkOrder workOrder ) {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * CommentWrapper
    // *********************************************
    @IsTest
    public static void testCommentWrapper_Wrap_CallComment_Wrapped() {
        String expectedText = 'Text';
        String expectedCommentType = 'NORMAL';
        FSL_WorkOrderJsonWrapper.CommentContact expectedContact = new FSL_WorkOrderJsonWrapper.CommentContact();
        FSL_WorkOrderJsonWrapper.SourceSystem expectedSystemZ = new FSL_WorkOrderJsonWrapper.SourceSystem();
        String expectedVisibility = 'EXTERNAL';

        FSL_Call_Comments__c callComment = new FSL_Call_Comments__c( FSL_Comment__c = expectedText );
        insert callComment;
        callComment = [SELECT Id, CreatedDate, FSL_Comment__c FROM FSL_Call_Comments__c LIMIT 1];
        String expectedCommentDate = callComment.CreatedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );

        CommentContactWrapperMock commentContactWrapper = new CommentContactWrapperMock();
        commentContactWrapper.wrapCallCommentReturnValue = expectedContact;
        SourceSystemWrapperMock sourceSystemWrapper = new SourceSystemWrapperMock();
        sourceSystemWrapper.wrapServiceSettingReturnValue = expectedSystemZ;
        FSL_WorkOrderJsonWrapper.CommentWrapper wrapper = new FSL_WorkOrderJsonWrapper.CommentWrapper( commentContactWrapper, sourceSystemWrapper );

        System.assertEquals( 0, commentContactWrapper.wrapCallCommentCallCount, 'CallCommentWrapper.wrap has been called' );
        System.assertEquals( 0, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Comment comment = wrapper.wrap( callComment, null );
        Test.stopTest();

        System.assertNotEquals( null, comment, 'Comment is null' );
        System.assertEquals( 1, commentContactWrapper.wrapCallCommentCallCount, 'CallCommentWrapper.wrap has not been called' );
        System.assertEquals( 1, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap has not been called' );
        System.assertEquals( expectedCommentDate, comment.commentDate, 'Comment Date does not have the expected value' );
        System.assertEquals( expectedCommentType, comment.commentType, 'Comment Type does not have the expected value' );
        System.assertEquals( expectedContact, comment.contact, 'Contact does not have the expected value' );
        System.assertEquals( expectedSystemZ, comment.system_Z, 'System_Z does not have the expected value' );
        System.assertEquals( expectedText, comment.text, 'Text does not have the expected value' );
        System.assertEquals( expectedVisibility, comment.visibility, 'Visibility does not have the expected value' );
    }
    
    @IsTest
    public static void testCommentWrapper_Wrap_FeedItem_Wrapped() {
        String expectedText = 'Text';
        String expectedCommentType = 'NORMAL';
        FSL_WorkOrderJsonWrapper.CommentContact expectedContact = new FSL_WorkOrderJsonWrapper.CommentContact();
        FSL_WorkOrderJsonWrapper.SourceSystem expectedSystemZ = new FSL_WorkOrderJsonWrapper.SourceSystem();
        String expectedVisibility = 'EXTERNAL';

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder workOrder = new WorkOrder();
        workOrder = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        workOrder.External_Id__c = 'ERS-12345';
        workOrder.Call_Id__c = '3333';
        workOrder.Status = 'Spotted';
        workOrder.Servicing_Technology_Type__c = 'Landline';
        workOrder.Vehicle_Profile__c = 'My Vehicle';
        insert workOrder;

        FeedItem feedItem = new FeedItem( Type = 'TextPost', Body = expectedText, ParentId = workOrder.Id );
        insert feedItem;
        feedItem = [SELECT Id, Body, LastModifiedDate FROM FeedItem LIMIT 1];
        String expectedCommentDate = feedItem.LastModifiedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );

        CommentContactWrapperMock commentContactWrapper = new CommentContactWrapperMock();
        commentContactWrapper.wrapFeedItemReturnValue = expectedContact;
        SourceSystemWrapperMock sourceSystemWrapper = new SourceSystemWrapperMock();
        sourceSystemWrapper.wrapServiceSettingReturnValue = expectedSystemZ;
        FSL_WorkOrderJsonWrapper.CommentWrapper wrapper = new FSL_WorkOrderJsonWrapper.CommentWrapper( commentContactWrapper, sourceSystemWrapper );

        System.assertEquals( 0, commentContactWrapper.wrapFeedItemCallCount, 'CallCommentWrapper.wrap has been called' );
        System.assertEquals( 0, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap has been called' );

        Test.startTest();
        FSL_WorkOrderJsonWrapper.Comment comment = wrapper.wrap( feedItem, null );
        Test.stopTest();

        System.assertNotEquals( null, comment, 'Comment is null' );
        System.assertEquals( 1, commentContactWrapper.wrapFeedItemCallCount, 'CallCommentWrapper.wrap has not been called' );
        System.assertEquals( 1, sourceSystemWrapper.wrapServiceSettingCallCount, 'SourceSystemWrapper.wrap has not been called' );
        System.assertEquals( expectedCommentDate, comment.commentDate, 'Comment Date does not have the expected value' );
        System.assertEquals( expectedCommentType, comment.commentType, 'Comment Type does not have the expected value' );
        System.assertEquals( expectedContact, comment.contact, 'Contact does not have the expected value' );
        System.assertEquals( expectedSystemZ, comment.system_Z, 'System_Z does not have the expected value' );
        System.assertEquals( expectedText, comment.text, 'Text does not have the expected value' );
        System.assertEquals( expectedVisibility, comment.visibility, 'Visibility does not have the expected value' );
    }

    public class CommentWrapperMock extends FSL_WorkOrderJsonWrapper.CommentWrapper {
        public CommentWrapperMock() {
            super( null, null );
        }

        public Integer wrapCallCommentCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Comment wrapCallCommentReturnValue = null;
        public override Comment wrap( FSL_Call_Comments__c callComment, FSL_ServiceSettings__c serviceSetting ) {
            wrapCallCommentCallCount++;
            return wrapCallCommentReturnValue;
        }

        public Integer wrapFeedItemCallCount = 0;
        public FSL_WorkOrderJsonWrapper.Comment wrapFeedItemReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.Comment wrap( FeedItem feedItem, FSL_ServiceSettings__c serviceSetting ) {
            wrapFeedItemCallCount++;
            return wrapFeedItemReturnValue;
        }
    }

    // *********************************************
    // * CommentContactWrapper
    // *********************************************
    @IsTest
    public static void testCommentContactWrapper_Wrap_CallCommentWithEmployeeNumberNotBlank_Wrapped() {
        String expectedContactType = 'SYSTEM';
        String expectedUserId = 'User ID';

        FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
        insert callComment;
        callComment = [SELECT Id, CreatedBy.EmployeeNumber FROM FSL_Call_Comments__c LIMIT 1];
        callComment.CreatedBy.EmployeeNumber = expectedUserId;

        FSL_WorkOrderJsonWrapper.CommentContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.CommentContactWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CommentContact commentContact = wrapper.wrap( callComment );
        Test.stopTest();

        System.assertNotEquals( null, commentContact, 'Comment Contact is null' );
        System.assertEquals( expectedContactType, commentContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedUserId, commentContact.userId, 'User Id does not have the expected value' );
    }

    @IsTest
    public static void testCommentContactWrapper_Wrap_CallCommentWithEmployeeNumberBlank_WrappedWithDefaultUserId() {
        String expectedContactType = 'SYSTEM';
        String expectedUserId = 'S999999';

        FSL_Call_Comments__c callComment = new FSL_Call_Comments__c();
        insert callComment;
        callComment = [SELECT Id, CreatedBy.EmployeeNumber FROM FSL_Call_Comments__c LIMIT 1];
        callComment.CreatedBy.EmployeeNumber = null;

        FSL_WorkOrderJsonWrapper.CommentContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.CommentContactWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CommentContact commentContact = wrapper.wrap( callComment );
        Test.stopTest();

        System.assertNotEquals( null, commentContact, 'Comment Contact is null' );
        System.assertEquals( expectedContactType, commentContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedUserId, commentContact.userId, 'User Id does not have the expected value' );
    }

    @IsTest
    public static void testCommentContactWrapper_Wrap_FeedItem_Wrapped() {
        String expectedContactType = 'SYSTEM';
        String expectedUserId = null; // FeedItem.InsertedBy.Name cannot be modified

        Account account = FSL_DataFactory.createAccount( 'Name' );
        insert account;

        Contact contact = FSL_DataFactory.createContact( 'Name' );
        contact.AccountId = account.Id;
        insert contact;

        WorkOrder workOrder = new WorkOrder();
        workOrder = FSL_DataFactory.createWorkOrderShell( 'Light Service', contact );
        workOrder.External_Id__c = 'ERS-12345';
        workOrder.Call_Id__c = '3333';
        workOrder.Status = 'Spotted';
        workOrder.Servicing_Technology_Type__c = 'Landline';
        workOrder.Vehicle_Profile__c = 'My Vehicle';
        insert workOrder;

        FeedItem feedItem = new FeedItem( Type = 'TextPost', Body = 'Body', ParentId = workOrder.Id );
        insert feedItem;
        feedItem = [SELECT Id, InsertedBy.Name FROM FeedItem LIMIT 1];

        FSL_WorkOrderJsonWrapper.CommentContactWrapper wrapper = new FSL_WorkOrderJsonWrapper.CommentContactWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.CommentContact commentContact = wrapper.wrap( feedItem );
        Test.stopTest();

        System.assertNotEquals( null, commentContact, 'Comment Contact is null' );
        System.assertEquals( expectedContactType, commentContact.contactType, 'Contact Type does not have the expected value' );
        System.assertEquals( expectedUserId, commentContact.userId, 'User Id does not have the expected value' );
    }

    public class CommentContactWrapperMock extends FSL_WorkOrderJsonWrapper.CommentContactWrapper {
        public Integer wrapCallCommentCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CommentContact wrapCallCommentReturnValue = null;
        public override CommentContact wrap( FSL_Call_Comments__c callComment ) {
            wrapCallCommentCallCount++;
            return wrapCallCommentReturnValue;
        }

        public Integer wrapFeedItemCallCount = 0;
        public FSL_WorkOrderJsonWrapper.CommentContact wrapFeedItemReturnValue = null;
        public override CommentContact wrap( FeedItem feedItem ) {
            wrapFeedItemCallCount++;
            return wrapFeedItemReturnValue;
        }
    }

    // *********************************************
    // * UpdatedByWrapper
    // *********************************************
    @IsTest
    public static void testUpdatedByWrapper_Wrap_NoParameters_WrappedWithContactTypeSYSTEM() {
        String expectedContactType = 'SYSTEM';

        FSL_WorkOrderJsonWrapper.UpdatedByWrapper wrapper = new FSL_WorkOrderJsonWrapper.UpdatedByWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.UpdatedBy updatedBy = wrapper.wrap();
        Test.stopTest();

        System.assertNotEquals( null, updatedBy, 'Updated By is null');
        System.assertEquals( expectedContactType, updatedBy.contactType, 'Contact Type does not have the expected value' );
    }

    public class UpdatedByWrapperMock extends FSL_WorkOrderJsonWrapper.UpdatedByWrapper {
        public Integer wrapCallCount = 0;
        public FSL_WorkOrderJsonWrapper.UpdatedBy wrapReturnValue = null;
        public override UpdatedBy wrap() {
            wrapCallCount++;
            return wrapReturnValue;
        }
    }

    // *********************************************
    // * SourceSystemWrapper
    // *********************************************
    @IsTest
    public static void testSourceSystemWrapper_Wrap_ServiceSetting_Wrapped() {
        String expectedSystemId = 'System Code';
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedSystemOrganization = new FSL_WorkOrderJsonWrapper.SystemOrganization();
        FSL_ServiceSettings__c serviceSetting = new FSL_ServiceSettings__c( Source_System_ID__c = expectedSystemId );

        SystemOrganizationWrapperMock systemOrganizationWrapper = new SystemOrganizationWrapperMock();
        systemOrganizationWrapper.wrapServiceSettingReturnValue = expectedSystemOrganization;
        FSL_WorkOrderJsonWrapper.SourceSystemWrapper wrapper = new FSL_WorkOrderJsonWrapper.SourceSystemWrapper( systemOrganizationWrapper );

        System.assertEquals( 0, systemOrganizationWrapper.wrapServiceSettingCallCount, 'Call Count is not 0' );
        Test.startTest();
        FSL_WorkOrderJsonWrapper.SourceSystem sourceSystem = wrapper.wrap( serviceSetting );
        Test.stopTest();

        System.assertNotEquals( null, sourceSystem, 'Source System is null' );
        System.assertEquals( 1, systemOrganizationWrapper.wrapServiceSettingCallCount, 'SystemOrganizationWrapper.wrap was not called' );
        System.assertEquals( expectedSystemId, sourceSystem.systemId, 'System Id does not have the expected value' );
        System.assertEquals( expectedSystemOrganization, sourceSystem.systemOrganization, 'System Organization does not have the expected value' );
    }

    @IsTest
    public static void testSourceSystemWrapper_Wrap_WorkOrder_WrappedWithSystemIdEmtpy() {
        String expectedSystemId = '';
        FSL_WorkOrderJsonWrapper.SystemOrganization expectedSystemOrganization = new FSL_WorkOrderJsonWrapper.SystemOrganization();
        WorkOrder workOrder = new WorkOrder();

        SystemOrganizationWrapperMock systemOrganizationWrapper = new SystemOrganizationWrapperMock();
        systemOrganizationWrapper.wrapWorkOrderReturnValue = expectedSystemOrganization;
        FSL_WorkOrderJsonWrapper.SourceSystemWrapper wrapper = new FSL_WorkOrderJsonWrapper.SourceSystemWrapper( systemOrganizationWrapper );

        System.assertEquals( 0, systemOrganizationWrapper.wrapWorkOrderCallCount, 'Call Count is not 0' );
        Test.startTest();
        FSL_WorkOrderJsonWrapper.SourceSystem sourceSystem = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, sourceSystem, 'Source System is null' );
        System.assertEquals( 1, systemOrganizationWrapper.wrapWorkOrderCallCount, 'SystemOrganizationWrapper.wrap was not called' );
        System.assertEquals( expectedSystemId, sourceSystem.systemId, 'System Id does not have the expected value' );
        System.assertEquals( expectedSystemOrganization, sourceSystem.systemOrganization, 'System Organization does not have the expected value' );
    }

    public class SourceSystemWrapperMock extends FSL_WorkOrderJsonWrapper.SourceSystemWrapper {
        public SourceSystemWrapperMock() {
            super( null );
        }

        public Integer wrapServiceSettingCallCount = 0;
        public FSL_WorkOrderJsonWrapper.SourceSystem wrapServiceSettingReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.SourceSystem wrap( FSL_ServiceSettings__c serviceSetting ) {
            wrapServiceSettingCallCount++;
            return wrapServiceSettingReturnValue;
        }

        public Integer wrapWorkOrderCallCount = 0;
        public FSL_WorkOrderJsonWrapper.SourceSystem wrapWorkOrderReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.SourceSystem wrap( WorkOrder workOrder ) {
            wrapWorkOrderCallCount++;
            return wrapWorkOrderReturnValue;
        }
    }

    // *********************************************
    // * SystemOrganizationWrapper
    // *********************************************
    @IsTest
    public static void testSystemOrganizationWrapper_Wrap_ContactNotNull_Wrapped() {
        String expectedCode = 'Code';
        String expectedName = 'Name';
        Contact contact = new Contact( Membership_OrgCode__c = expectedCode, Membership_Org__c = expectedName );

        FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper wrapper = new FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.SystemOrganization systemOrganization = wrapper.wrap( contact );
        Test.stopTest();

        System.assertNotEquals( null, systemOrganization, 'System Organization is null' );
        System.assertEquals( expectedCode, systemOrganization.code, 'Code does not have the expected value' );
        System.assertEquals( expectedName, systemOrganization.name, 'Name does not have the expected value' );
    }
    
    @IsTest
    public static void testSystemOrganizationWrapper_Wrap_ContactNull_WrappedWithNullValues() {
        String expectedCode = null;
        String expectedName = null;
        Contact contact = null;

        FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper wrapper = new FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.SystemOrganization systemOrganization = wrapper.wrap( contact );
        Test.stopTest();

        System.assertNotEquals( null, systemOrganization, 'System Organization is null' );
        System.assertEquals( expectedCode, systemOrganization.code, 'Code does not have the expected value' );
        System.assertEquals( expectedName, systemOrganization.name, 'Name does not have the expected value' );
    }
    
    @IsTest
    public static void testSystemOrganizationWrapper_Wrap_ServiceSetting_Wrapped() {
        String expectedCode = 'Code';
        String expectedName = 'Name';
        FSL_ServiceSettings__c serviceSetting = new FSL_ServiceSettings__c( Source_System_Org_Code__c = expectedCode, Source_System_Org_Name__c = expectedName );

        FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper wrapper = new FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.SystemOrganization systemOrganization = wrapper.wrap( serviceSetting );
        Test.stopTest();

        System.assertNotEquals( null, systemOrganization, 'System Organization is null' );
        System.assertEquals( expectedCode, systemOrganization.code, 'Code does not have the expected value' );
        System.assertEquals( expectedName, systemOrganization.name, 'Name does not have the expected value' );
    }
    
    @IsTest
    public static void testSystemOrganizationWrapper_Wrap_WorkOrder_Wrapped() {
        String expectedCode = 'Code';
        String expectedName = 'Name';
        WorkOrder workOrder = new WorkOrder( Call_Origin_OrgCode__c = expectedCode, Call_Origin_OrgName__c = expectedName );

        FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper wrapper = new FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper();

        Test.startTest();
        FSL_WorkOrderJsonWrapper.SystemOrganization systemOrganization = wrapper.wrap( workOrder );
        Test.stopTest();

        System.assertNotEquals( null, systemOrganization, 'System Organization is null' );
        System.assertEquals( expectedCode, systemOrganization.code, 'Code does not have the expected value' );
        System.assertEquals( expectedName, systemOrganization.name, 'Name does not have the expected value' );
    }

    public class SystemOrganizationWrapperMock extends FSL_WorkOrderJsonWrapper.SystemOrganizationWrapper {
        public Integer wrapContactCallCount = 0;
        public FSL_WorkOrderJsonWrapper.SystemOrganization wrapContactReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.SystemOrganization wrap( Schema.Contact contact ) {
            wrapContactCallCount++;
            return wrapContactReturnValue;
        }

        public Integer wrapServiceSettingCallCount = 0;
        public FSL_WorkOrderJsonWrapper.SystemOrganization wrapServiceSettingReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.SystemOrganization wrap( FSL_ServiceSettings__c serviceSetting ) {
            wrapServiceSettingCallCount++;
            return wrapServiceSettingReturnValue;
        }

        public Integer wrapWorkOrderCallCount = 0;
        public FSL_WorkOrderJsonWrapper.SystemOrganization wrapWorkOrderReturnValue = null;
        public override FSL_WorkOrderJsonWrapper.SystemOrganization wrap( WorkOrder workOrder ) {
            wrapWorkOrderCallCount++;
            return wrapWorkOrderReturnValue;
        }
    }
}