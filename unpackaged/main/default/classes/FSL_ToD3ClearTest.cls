/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 11-09-2021
 * @last modified by  : Clement Shiu
**/
@isTest
public class FSL_ToD3ClearTest{
    private static User user = new User();
    static String body = '';
    static Map<String, String> responseHeaders = new Map<String, String>{'Content-Type' => 'application/json;charset=UTF-8'};

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

    static testMethod void clearWorkOrderstatus() {
        System.Test.StartTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.setMock( HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator( false ) );
     
        list<WorkOrder> workOrders = [SELECT Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                        (SELECT id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                            Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                            FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                            SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                        FROM ServiceAppointments
                                        ORDER BY recordtype.name ASC) 
                                    FROM Workorder LIMIT 1];
       Id wID = workOrders[0].Id;

       createTestData( wID );

       FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallServiceMock = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
       FSL_ToD3Clear.clearQueuedCallService = clearQueuedCallServiceMock;

       body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
       System.Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 200, 'OK', body, responseHeaders ) );
       
       List<FSL_ClearJsonWorkOrder> jsonWorkOrderList= FSL_ToD3Clear.clearedWorkOrders( New Set<ID>{ wID }, 'Clear' );
        FSL_ClearJsonWorkOrder jsonWorkOrder =jsonWorkOrderList[0];

       Set<String> userIdSet = new Set<String>();
       Set<String> contactTypeSet = new Set<String>();

       Boolean DEFAULT_USER_ID_found = false;
       for( FSL_ClearJsonWorkOrder.Comments c : jsonWorkOrder.calls[0].comments ) {
            userIdSet.add( c.contact.userId );
            if( c.contact.userId == FSL_WorkOrderD3JsonWrapper.DEFAULT_USER_ID )
                DEFAULT_USER_ID_found = true;
       }

       System.assert( userIdSet.size() > 1, 'Comments from at least 2 distinct users not presented' );
       System.assert( DEFAULT_USER_ID_found, 'Blank or null userId was not replaced with default user ID' );

       System.Test.StopTest();
    }

    static private User createTestUser( String alias, String emplNum, Id profileId, Id userRoleId ) { //alias must be <= 8 letters
        User user = new User( Alias = alias, Email = alias + '@ace.aaa.com', 
            EmailEncodingKey='UTF-8', FirstName=alias + '_firstname', LastName=alias + '_lastname', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId =profileId, UserRoleId = userRoleId, EmployeeNumber = emplNum,
            TimeZoneSidKey='America/Los_Angeles', UserName=alias + '@aaa.com' );
        insert user;
        return user;
    }

    static private void createTestData( Id wID ) {
        List<User> users = [SELECT Id FROM user WHERE alias = 'C_Admin'];
        system.runAs( users[0] ) {
            List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            Id profileId = profiles[0].id;

            List<UserRole> uroles = [SELECT Id, PortalRole, PortalType FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            Id userRoleId = uroles[0].Id;
            
            User user1 = createTestUser( 'TstUsr1', 'E1234', profileId, userRoleId );
            User user2 = createTestUser( 'TstUsr2', 'E5678', profileId, userRoleId );
            User user3 = createTestUser( 'TstUsr3', '', profileId, userRoleId ); // For testing default user ID

            createTestComment( user1, wID );
            createTestComment( user2, wID );
            createTestComment( user3, wID );
        }
    }


    static private void createTestComment( User user, Id wID ) {
        System.runAs( user ) {
            FSL_Call_Comments__c  cc = new FSL_Call_Comments__c();
            cc.FSL_Comment__c = 'Test comment created by ' + user.UserName;
            cc.FSL_Work_Order__c = wID;
            insert cc;
        }
    }
      
    static testmethod void CallCommentsTest() {
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );
        list<WorkOrder> workOrders = [SELECT Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                        (SELECT id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                            Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                            FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                            SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                        FROM ServiceAppointments
                                        ORDER BY recordtype.name ASC) 
                                    FROM Workorder];
        Test.setMock( HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator( false ) );
        FSL_Call_Comments__c fc = new FSL_Call_Comments__c();
        fc.FSL_Comment__c = 'Test comments ';
        fc.FSL_Work_Order__c =workOrders[0].Id;
        insert fc;
    }
    
    static testMethod void exceptionTest() {
        System.Test.StartTest();
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );

        FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock clearQueuedCallServiceMock = new FSL_ClearQueuedCallTest.ClearQueuedCallServiceMock();
        FSL_ToD3Clear.clearQueuedCallService = clearQueuedCallServiceMock;

        Test.setMock( HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator( false ) );
        // body = '{\"body\": {\"access_token\": \"lGVtg2D43wGwoFLEavZ9Rwt\",\"token_type\": \"Bearer\",\"expires_in\": 15552000},\"meta\": {\"time\": 1548061709658},\"result\": \"ok\"}';
        list<WorkOrder> workOrders = [SELECT Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
                                        (SELECT id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
                                            Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
                                            FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
                                            SchedEndTime, actualstarttime, FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
                                        FROM ServiceAppointments
                                        ORDER BY recordtype.name ASC) 
                                    FROM Workorder];
        body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
        System.Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 400, 'OK', body, responseHeaders ) );

        FSL_ToD3Clear.clearedWorkOrders( New Set<ID>{workOrders[0].Id}, 'Clear' );
        System.Test.StopTest();
    }

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateToD3Clear_NotNull() {
        FSL_ToD3Clear.IFactory factory = new FSL_ToD3Clear.Factory();

        Test.startTest();
        FSL_ToD3Clear.IToD3Clear toD3Clear = factory.createToD3Clear();
        Test.stopTest();

        System.assertNotEquals( null, toD3Clear );
    }

    // *********************************************
    // * ToD3Clear
    // *********************************************
    @IsTest
    public static void testToD3Clear_ClearWorkOrders_SetOfWorkOrderIdsAndCalloutReturnsOkWithBodyStatusCode200_SuccessReturned() {
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        System.assertEquals( 1, workOrders.size(), 'More than 1 Work Order was returned' );
        Set<Id> workOrderIds = new Set<Id>{ workOrders[0].Id };
            
                FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c();
                endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
                endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
                endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
                endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
                endpoint.Timeout__c = 20000;
                endpoint.Named_Credential__c = 'OAuth';
                endpoint.Name='OAuth';
                insert endpoint;

        body = '{"header": {"id": "d26c7791-7a58-4ff6-8dac-82a147cd8235","status": "","subType": "","type": "Clear","version": "1"},"statusCode": 200,"statusDescription": "%STATUS_DESCRIPTION%"}';
        System.Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 200, 'OK', body, responseHeaders ) );

        FSL_ToD3Clear.IFactory toD3ClearFactory = new FSL_ToD3Clear.Factory();
        FSL_ToD3Clear.IToD3Clear toD3Clear = toD3ClearFactory.createToD3Clear();

        Test.startTest();
        Map<Id, Boolean> clearResults = toD3Clear.clearWorkOrders( workOrderIds );
        Test.stopTest();
          system.debug('####');
        system.debug(clearResults);
        system.debug('clearResults.get( workOrders[0].Id' + clearResults.get( workOrders[0].Id));

        System.assertEquals( 1, clearResults.size(), 'Number of Clear Results is incorrect' );
        System.assertEquals( true, clearResults.containsKey( workOrders[0].Id ), 'The Clear Results do not contain a value for the passed WorkOrder Id' );
        System.assertEquals( true, clearResults.get( workOrders[0].Id ), 'The Clear Result for the passed WorkOrder Id is returned as a failure' );
    } @IsTest
    public static void testToD3Clear_ClearWorkOrders() {
        Test.startTest();    
        Integer recordCount = 5;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
        
        Map<id,WorkOrder> workOrdersmap = new Map<id,workorder>([SELECT Id FROM WorkOrder]);
        System.assertEquals( 5, workOrdersmap.size(), 'More/Less than 5 Work Order was returned' );
        
        List<WorkOrder> returnedWorkOrders=FSL_TOD3Clear.getWorkOrderDataForClearProcessing(workOrdersmap.keyset());
        
        System.assertEquals( 2, returnedWorkOrders.size(), 'Mor/Less Than 2 Work Order was returned' );
        Test.stopTest();
    }

    @IsTest
    public static void testToD3Clear_ClearWorkOrders_SetOfWorkOrderIdsAndCalloutReturnsOkWithBodyStatusCodeNot200_FailureReturned() {
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        System.assertEquals( 1, workOrders.size(), 'More than 1 Work Order was returned' );
        Set<Id> workOrderIds = new Set<Id>{ workOrders[0].Id };

        body = '{"header": {"id": "d26c7791-7a58-4ff6-8dac-82a147cd8235","status": "","subType": "","type": "Clear","version": "1"},"statusCode": 500,"statusDescription": "%STATUS_DESCRIPTION%"}';
        System.Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 200, 'OK', body, responseHeaders ) );

        FSL_ToD3Clear.IFactory toD3ClearFactory = new FSL_ToD3Clear.Factory();
        FSL_ToD3Clear.IToD3Clear toD3Clear = toD3ClearFactory.createToD3Clear();

        Test.startTest();
        Map<Id, Boolean> clearResults = toD3Clear.clearWorkOrders( workOrderIds );
        Test.stopTest();

        System.assertEquals( 1, clearResults.size(), 'Number of Clear Results is incorrect' );
        System.assertEquals( true, clearResults.containsKey( workOrders[0].Id ), 'The Clear Results do not contain a value for the passed WorkOrder Id' );
        System.assertEquals( false, clearResults.get( workOrders[0].Id ), 'The Clear Result for the passed WorkOrder Id is returned as a success' );
    }

    @IsTest
    public static void testToD3Clear_ClearWorkOrders_SetOfWorkOrderIdsAndCalloutReturnsNotOk_FailureReturned() {
        FSL_DataFactory.createWOIntakeCall( 'FSL_LightCall' );
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        System.assertEquals( 1, workOrders.size(), 'More than 1 Work Order was returned' );
        Set<Id> workOrderIds = new Set<Id>{ workOrders[0].Id };

        body = '{"header": {"id": "d26c7791-7a58-4ff6-8dac-82a147cd8235","status": "","subType": "","type": "Clear","version": "1"},"statusCode": 200,"statusDescription": "%STATUS_DESCRIPTION%"}';
        System.Test.setMock( HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl( 408, 'OK', body, responseHeaders ) );

        FSL_ToD3Clear.IFactory toD3ClearFactory = new FSL_ToD3Clear.Factory();
        FSL_ToD3Clear.IToD3Clear toD3Clear = toD3ClearFactory.createToD3Clear();

        Test.startTest();
        Map<Id, Boolean> clearResults = toD3Clear.clearWorkOrders( workOrderIds );
        Test.stopTest();

        System.assertEquals( 1, clearResults.size(), 'Number of Clear Results is incorrect' );
        System.assertEquals( true, clearResults.containsKey( workOrders[0].Id ), 'The Clear Results do not contain a value for the passed WorkOrder Id' );
        System.assertEquals( false, clearResults.get( workOrders[0].Id ), 'The Clear Result for the passed WorkOrder Id is returned as a success' );
    }
    
    // *********************************************
    // * ToD3ClearMock
    // *********************************************
    public class ToD3ClearMock implements FSL_ToD3Clear.IToD3Clear {
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in FSL_ToD3ClearTest.ToD3ClearMock' );
            }
        }

        public Integer clearWorkOrdersWithIdsCallCount = 0;
        public Map<Id, Boolean> clearWorkOrdersWithIdsReturnValue = new Map<Id, Boolean>();
        public Map<Id, Boolean> clearWorkOrders( Set<Id> workOrderIds ) {
            ++clearWorkOrdersWithIdsCallCount;
            throwExceptionIfConfigured();
            return clearWorkOrdersWithIdsReturnValue;
        }

        public Integer clearWorkOrdersWithObjectsCallCount = 0;
        public Map<Id, Boolean> clearWorkOrdersWithObjectsReturnValue = new Map<Id, Boolean>();
        public Map<Id, Boolean> clearWorkOrders( List<WorkOrder> workOrders, 
                                    Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                    Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap ) {
            ++clearWorkOrdersWithObjectsCallCount;
            throwExceptionIfConfigured();
            return clearWorkOrdersWithObjectsReturnValue;
        }

        public Integer clearWorkOrderCallCount = 0;
        public FSL_ToD3Clear.ClearResult clearWorkOrderReturnValue = null;
        public FSL_ToD3Clear.ClearResult clearWorkOrder( WorkOrder workOrder, 
                                                        Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap, 
                                                        Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap,
                                                        Map<String, String> zipCodeToClubCode ) {
            ++clearWorkOrderCallCount;
            throwExceptionIfConfigured();
            return clearWorkOrderReturnValue;
        }
    }

    @IsTest
    public static void testToD3ClearMock_ClearWorkOrders_UsingIdSet_CallCountIncremented() {
        ToD3ClearMock toD3Clear = new ToD3ClearMock();
        FSL_DAOTest.MockIdGenerator idGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        System.assertEquals( 0, toD3Clear.clearWorkOrdersWithIdsCallCount, 'Default Call Count is not 0' );

        Test.startTest();
        Map<Id, Boolean> defaultReturnValue = toD3Clear.clearWorkOrders( new Set<Id>() );
        Integer callCount1 = toD3Clear.clearWorkOrdersWithIdsCallCount;

        Map<Id, Boolean> expectedReturnValue = new Map<Id, Boolean>{ idGenerator.getMockId() => true, idGenerator.getMockId() => false };
        toD3Clear.clearWorkOrdersWithIdsReturnValue = expectedReturnValue;
        Map<Id, Boolean> actualReturnValue = toD3Clear.clearWorkOrders( new Set<Id>() );
        Integer callCount2 = toD3Clear.clearWorkOrdersWithIdsCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1, 'The Call Count was not incremented (1st time)' );
        System.assertEquals( true, defaultReturnValue.isEmpty(), 'The default Return Value is not empty' );
        System.assertEquals( 2, callCount2, 'The Call Count was not incremented (2nd time)' );
        System.assertEquals( expectedReturnValue, actualReturnValue, 'The Return Value is incorrect' );
    }

    @IsTest
    public static void testToD3ClearMock_ClearWorkOrders_UsingObjectList_CallCountIncremented() {
        ToD3ClearMock toD3Clear = new ToD3ClearMock();
        FSL_DAOTest.MockIdGenerator idGenerator = new FSL_DAOTest.MockIdGenerator( Schema.WorkOrder.getSObjectType() );
        System.assertEquals( 0, toD3Clear.clearWorkOrdersWithObjectsCallCount, 'Default Call Count is not 0' );

        Test.startTest();
        Map<Id, Boolean> defaultReturnValue = toD3Clear.clearWorkOrders( new List<WorkOrder>(), new Map<Id, AssignedResource>(), new Map<Id, List<FeedItem>>() );
        Integer callCount1 = toD3Clear.clearWorkOrdersWithObjectsCallCount;

        Map<Id, Boolean> expectedReturnValue = new Map<Id, Boolean>{ idGenerator.getMockId() => true, idGenerator.getMockId() => false };
        toD3Clear.clearWorkOrdersWithObjectsReturnValue = expectedReturnValue;
        Map<Id, Boolean> actualReturnValue = toD3Clear.clearWorkOrders( new List<WorkOrder>(), new Map<Id, AssignedResource>(), new Map<Id, List<FeedItem>>() );
        Integer callCount2 = toD3Clear.clearWorkOrdersWithObjectsCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1, 'The Call Count was not incremented (1st time)' );
        System.assertEquals( true, defaultReturnValue.isEmpty(), 'The default Return Value is not empty' );
        System.assertEquals( 2, callCount2, 'The Call Count was not incremented (2nd time)' );
        System.assertEquals( expectedReturnValue, actualReturnValue, 'The Return Value is incorrect' );
    }

    @IsTest
    public static void testToD3ClearMock_ClearWorkOrder_CallCountIncremented() {
        ToD3ClearMock toD3Clear = new ToD3ClearMock();
        System.assertEquals( 0, toD3Clear.clearWorkOrderCallCount, 'Default Call Count is not 0' );

        Test.startTest();
        FSL_ToD3Clear.ClearResult defaultReturnValue = toD3Clear.clearWorkOrder( new WorkOrder(), new Map<Id, AssignedResource>(), new Map<Id, List<FeedItem>>(), null );
        Integer callCount1 = toD3Clear.clearWorkOrderCallCount;

        FSL_ToD3Clear.ClearResult expectedReturnValue = new FSL_ToD3Clear.ClearResult( 'Request Body', 'Call Id', System.now(), null );
        toD3Clear.clearWorkOrderReturnValue = expectedReturnValue;
        FSL_ToD3Clear.ClearResult actualReturnValue = toD3Clear.clearWorkOrder( new WorkOrder(), new Map<Id, AssignedResource>(), new Map<Id, List<FeedItem>>(), null );
        Integer callCount2 = toD3Clear.clearWorkOrderCallCount;
        Test.stopTest();

        System.assertEquals( 1, callCount1, 'The Call Count was not incremented (1st time)' );
        System.assertEquals( null, defaultReturnValue, 'The default Return Value is not null' );
        System.assertEquals( 2, callCount2, 'The Call Count was not incremented (2nd time)' );
        System.assertEquals( expectedReturnValue, actualReturnValue, 'The Return Value is incorrect' );
    }

    @IsTest
    public static void testStringValueOf_Null_Null() {
        Object o = null;
        Exception ex = null;
        String valueOf = null;

        try {
            valueOf = String.valueOf( o );
        }
        catch( Exception e ) {
            ex = e;
        }
        
        System.assertEquals( null, valueOf );
        System.assertEquals( null, ex );
    }
}