/**
 * @File Name          : FSL_OptimizationTriggerHandler_test.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 6/12/2020, 6:05:47 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    6/4/2020   Rajesh Kemisetti     Initial Version
**/

@isTest
public class FSL_OptimizationTriggerHandler_test{
    // adding for test
    static String body = '';
    static Map<String, String> responseHeaders = new Map<String, String>{'Content-Type' => 'application/json;charset=UTF-8'};
    //
    
    static testMethod void testRSOOperationsWith_LightServiceScheduledCalls(){
        List<User> adminUserList = [SELECT id, Name, Alias FROM User WHERE Alias = 'C_Admin'];
        User adminUser = adminUserList.get(0);
        System.runAs(adminUser){
            
            Test.startTest();
           
            // 
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));          
            body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
            System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
            //
            
     
            List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id,accountid FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT id FROM ServiceResource];

            for (ServiceResource servRes : serviceResources) {
                servRes.Currently_Scheduled__c = true;
            }
            update serviceResources;

            // create shell objects for WO
            List<WorkOrder> woList = new List<WorkOrder>();
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo1);
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            WorkOrder wo3 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo2);
            woList.add(wo3);
            
            
            insert woList;

           
            // create shell objects for SA
            DateTime nowTime = Datetime.now();
            DateTime nextTime = nowTime.addMinutes(60);
            DateTime nextTime1 = nowTime.addMinutes(40);
            List<ServiceAppointment> saList = new List<ServiceAppointment>(); 
            ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
            ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');
            
            saList.add(sa);
            saList.add(sa2);
            insert saList;

            system.debug('appointments inserted: ' + saList);  

            // create assigned resources for two SAs
            List<AssignedResource> arList = new List<AssignedResource>();
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa.id, ServiceResources[0].id);
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);
            arList.add(ar1);
            arList.add(ar2);
            
            insert arList;

            // update SAs to Scheduled
            saList.clear();
            sa.status = 'Scheduled';
            sa2.status = 'Scheduled';
            sa.Service_Resource__c = ServiceResources[0].id;
            sa2.Service_Resource__c = ServiceResources[0].id;
            saList.add(sa);
            saList.add(sa2);
            update saList;

            system.debug('appointments updated: ' + saList);

            // find SR with appointments assigned
            List<ServiceAppointment> scheduledAppointmentList = [SELECT id, Service_Resource__c, Status 
                FROM ServiceAppointment WHERE Service_Resource__c != null];
            
        
            //update saList; 
            ID resourceID;
            if(!scheduledAppointmentList.isEmpty()){
                resourceID = scheduledAppointmentList[0].Service_Resource__c;
            }
            
            // create OR
            FSL__Optimization_Request__c optRequest = new FSL__Optimization_Request__c();
            optRequest.FSL__Service_Resource__c = resourceID;
            optRequest.FSL__Status__c = 'Queued';
            insert optRequest;

            // Update OR Status = Completed, Objects Scheduled > 0, Service Resource = SR.ID
            optRequest.FSL__Status__c = 'Completed';
            optRequest.FSL__Objects_Scheduled__c = 2;
            update optRequest;

            // Find count of appointments assigned to SR where Status = Dispatched
            List<ServiceAppointment> dispatchedAppointmentList = [SELECT id, Status FROM ServiceAppointment WHERE Status = 'Dispatched'];

            // Assert that the count == 1
            system.assertEquals(1, dispatchedAppointmentList.size(), 'The number of dispatched appointments is not correct');
            
            Test.stopTest();
        }
    }

    static testMethod void testRSOOperationsWith_LightServiceDispatchedCalls(){
        List<User> adminUserList = [SELECT id, Name, Alias FROM User WHERE Alias = 'C_Admin'];
        User adminUser = adminUserList.get(0);
        System.runAs(adminUser){

            Test.startTest();
            // 
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));          
            body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
            System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
            //
            
            List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id,accountid FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT id FROM ServiceResource];

            // create shell objects for WO
            List<WorkOrder> woList = new List<WorkOrder>();
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo1);
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            WorkOrder wo3 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo2);
            woList.add(wo3);
           
            insert woList;
		 
            
            // create shell objects for SA
            DateTime nowTime = Datetime.now();
            DateTime nextTime = nowTime.addMinutes(60);
            DateTime nextTime1 = nowTime.addMinutes(40);
            List<ServiceAppointment> saList = new List<ServiceAppointment>();
            ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');
            ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');
            
            saList.add(sa);
            saList.add(sa2);
            insert saList;

            system.debug('appointments inserted: ' + saList);

            // create assigned resources for two SAs
            List<AssignedResource> arList = new List<AssignedResource>();
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa.id, ServiceResources[0].id);
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);
            arList.add(ar1);
            arList.add(ar2);
            
            insert arList;

            // update SAs to Scheduled
            saList.clear();
            sa.status = 'Dispatched';
            sa2.status = 'Dispatched';
            sa.Service_Resource__c = ServiceResources[0].id;
            sa2.Service_Resource__c = ServiceResources[0].id;
            saList.add(sa);
            saList.add(sa2);
            update saList;

            system.debug('appointments updated: ' + saList);

            // find SR with appointments assigned
            List<ServiceAppointment> scheduledAppointmentList = [SELECT id, Service_Resource__c, Status 
                FROM ServiceAppointment WHERE Service_Resource__c != null];
            
        
            //update saList; 
            ID resourceID;
            if(!scheduledAppointmentList.isEmpty()){
                resourceID = scheduledAppointmentList[0].Service_Resource__c;
            }
            
            // create OR
            FSL__Optimization_Request__c optRequest = new FSL__Optimization_Request__c();
            optRequest.FSL__Service_Resource__c = resourceID;
            optRequest.FSL__Status__c = 'Queued';
            insert optRequest;

            // Update OR Status = Completed, Objects Scheduled > 0, Service Resource = SR.ID
            optRequest.FSL__Status__c = 'Completed';
            optRequest.FSL__Objects_Scheduled__c = 2;
            update optRequest;

            // Find count of appointments assigned to SR where Status = Dispatched
            List<ServiceAppointment> dispatchedAppointmentList = [SELECT id, Status FROM ServiceAppointment WHERE Status = 'Dispatched'];

            // Assert that the count == 1
            system.assertEquals(1, dispatchedAppointmentList.size(), 'The number of dispatched appointments is not correct');
        
            Test.stopTest();
        }
    }    

    static testMethod void testInDayOperationsWith_ComplexWorkScheduledCalls(){

        List<User> adminUserList = [SELECT id, Name, Alias FROM User WHERE Alias = 'C_Admin'];
        User adminUser = adminUserList.get(0);
        System.runAs(adminUser){
            
                    // 
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));          
            body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
            System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
            //
            
            Id recordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
            List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id,accountid FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT Currently_Scheduled__c FROM ServiceResource];

            for (ServiceResource servRes : serviceResources) {
                servRes.Currently_Scheduled__c = true;
            }
            update serviceResources;

            // create shell objects for WO
            List<WorkOrder> woList = new List<WorkOrder>();
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo1);
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo2);
            
            insert woList;
  			 
            // create shell objects for SA
            DateTime nowTime = Datetime.now();
            DateTime nextTime = nowTime.addMinutes(60);
            DateTime nextTime1 = nowTime.addMinutes(40);
            List<ServiceAppointment> saList = new List<ServiceAppointment>();

            ServiceAppointment breakdownSA = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Breakdown Appointment');                        
            ServiceAppointment breakdownSA2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Breakdown Appointment');
            
            saList.add(breakdownSA);
            saList.add(breakdownSA2);
            insert saList;

            system.debug('appointments inserted: ' + saList);
            ServiceAppointment towSA = FSL_DataFactory.createAppointmentShell(breakdownSA, 30);
            ServiceAppointment towSA2 = FSL_DataFactory.createAppointmentShell(breakdownSA2, 30);
            
            saList.clear();            
            saList.add(towSA);
            saList.add(towSA2);
            insert saList;            

            Test.startTest();
    
            FSL_AppointmentDependencyHelper.createAppointmentDependency(breakdownSA, towSA);
            FSL_AppointmentDependencyHelper.createAppointmentDependency(breakdownSA2, towSA2);


            
            saList.clear();

            breakdownSA.FSL__Related_Service__c = towSA.id;
            breakdownSA.FSL__Same_Resource__c = true;
            towSA.FSL__Related_Service__c= breakdownSA.id;
            towSA.FSL__Same_Resource__c = true;     
            
            breakdownSA2.FSL__Related_Service__c = towSA2.id;
            breakdownSA2.FSL__Same_Resource__c = true;
            towSA2.FSL__Related_Service__c= breakdownSA2.id;
            towSA2.FSL__Same_Resource__c = true; 

            breakdownSA.status = 'Scheduled';
            breakdownSA2.status = 'Scheduled';

            breakdownSA.Service_Resource__c = ServiceResources[0].id;
            breakdownSA2.Service_Resource__c = ServiceResources[0].id;
            towSA.Service_Resource__c = ServiceResources[0].id;
            towSA2.Service_Resource__c = ServiceResources[0].id; 

            saList.add(breakdownSA);
            saList.add(breakdownSA2);            
            saList.add(towSA);
            saList.add(towSA2);
            update saList;

            // create assigned resources for two SAs
            List<AssignedResource> arList = new List<AssignedResource>();
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(breakdownSA.id, ServiceResources[0].id);
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(breakdownSA2.id, ServiceResources[0].id);
            AssignedResource ar3 = FSL_DataFactory.createAssignedResource(towSA.id, ServiceResources[0].id);
            AssignedResource ar4 = FSL_DataFactory.createAssignedResource(towSA2.id, ServiceResources[0].id);            
            arList.add(ar1);
            arList.add(ar2);
            arList.add(ar3);
            arList.add(ar4);            
            
            insert arList;

            // update related SAs
            saList.clear();

            // breakdownSA.FSL__Related_Service__c = towSA.id;
            // breakdownSA.FSL__Same_Resource__c = true;
            // towSA.FSL__Related_Service__c= breakdownSA.id;
            // towSA.FSL__Same_Resource__c = true;     
            
            // breakdownSA2.FSL__Related_Service__c = towSA2.id;
            // breakdownSA2.FSL__Same_Resource__c = true;
            // towSA2.FSL__Related_Service__c= breakdownSA2.id;
            // towSA2.FSL__Same_Resource__c = true; 

            // breakdownSA.status = 'Scheduled';
            // breakdownSA2.status = 'Scheduled';

            // breakdownSA.Service_Resource__c = ServiceResources[0].id;
            // breakdownSA2.Service_Resource__c = ServiceResources[0].id;
            // towSA.Service_Resource__c = ServiceResources[0].id;
            // towSA2.Service_Resource__c = ServiceResources[0].id; 

            // saList.add(breakdownSA);
            // saList.add(breakdownSA2);            
            // saList.add(towSA);
            // saList.add(towSA2);
            // update saList;

            system.debug('appointments updated: ' + saList);

            // find SR with appointments assigned
            List<ServiceAppointment> scheduledAppointmentList = [SELECT id, Service_Resource__c, Status, ServiceTerritoryID 
                FROM ServiceAppointment WHERE Service_Resource__c != null];
            
        
            //update saList; 
            ID resourceID;
            if(!scheduledAppointmentList.isEmpty()){
                resourceID = scheduledAppointmentList[0].Service_Resource__c;
            }
            
            // create OR
            FSL__Optimization_Request__c optRequest = new FSL__Optimization_Request__c();
            optRequest.FSL__Status__c = 'Queued';
            insert optRequest;

            FSL__Territory_Optimization_Request__c territoryOptimization = new FSL__Territory_Optimization_Request__c();
            territoryOptimization.FSL__ServiceTerritory__c = scheduledAppointmentList[0].ServiceTerritoryID;
            territoryOptimization.FSL__Optimization_Request__c = optRequest.id;
            insert territoryOptimization;                

            // Update OR Status = Completed, Objects Scheduled > 0
            optRequest.FSL__Status__c = 'Completed';
            optRequest.FSL__Objects_Scheduled__c = 2;
            update optRequest;

            // Find count of appointments assigned to SR where Status = Dispatched
            List<ServiceAppointment> dispatchedAppointmentList = [SELECT id, Status 
                FROM ServiceAppointment 
                WHERE Status = 'Dispatched' AND recordTypeID = :recordTypeID];

            // Assert that the count == 1
            system.assertEquals(1, dispatchedAppointmentList.size(), 'The number of dispatched appointments is not correct');
            
            Test.stopTest();
        }
    }
    
    static testMethod void testInDayOperationsWith_ComplexWorkDispatchedCalls(){

        List<User> adminUserList = [SELECT id, Name, Alias FROM User WHERE Alias = 'C_Admin'];
        User adminUser = adminUserList.get(0);
       
        
        System.runAs(adminUser){
         
            
			        // 
            Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));          
            body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "CLEAR", "subType" : "CLEAR", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
            System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
            //            
            Id recordTypeID = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
	
            List<Account> accounts = [SELECT id FROM Account];
            List<Contact> contacts = [SELECT id, AccountId FROM Contact];
            List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory];
            List<ServiceResource> serviceResources = [SELECT id FROM ServiceResource];

            // create shell objects for WO
            List<WorkOrder> woList = new List<WorkOrder>();
            WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo1);
            WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', contacts[0]);
            woList.add(wo2);
            System.debug('376 ==== woList ' + woList);
            insert woList;

            // create shell objects for SA
            DateTime nowTime = Datetime.now();
            DateTime nextTime = nowTime.addMinutes(60);
            DateTime nextTime1 = nowTime.addMinutes(40);
            List<ServiceAppointment> saList = new List<ServiceAppointment>();

            ServiceAppointment breakdownSA = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30, 'Tow Appointment');                        
            ServiceAppointment breakdownSA2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30, 'Tow Appointment');
            
            saList.add(breakdownSA);
            saList.add(breakdownSA2);
            insert saList;

            system.debug('appointments inserted: ' + saList);
            ServiceAppointment towSA = FSL_DataFactory.createAppointmentShell(breakdownSA, 30);
            ServiceAppointment towSA2 = FSL_DataFactory.createAppointmentShell(breakdownSA2, 30);
            
            saList.clear();            
            saList.add(towSA);
            saList.add(towSA2);
            insert saList;            

            Test.startTest();
    
            FSL_AppointmentDependencyHelper.createAppointmentDependency(breakdownSA, towSA);
            FSL_AppointmentDependencyHelper.createAppointmentDependency(breakdownSA2, towSA2);


            
            saList.clear();

            //create assigned resources for two SAs
            List<AssignedResource> arList = new List<AssignedResource>();
            AssignedResource ar1 = FSL_DataFactory.createAssignedResource(breakdownSA.id, ServiceResources[0].id);
            AssignedResource ar2 = FSL_DataFactory.createAssignedResource(breakdownSA2.id, ServiceResources[0].id);
            AssignedResource ar3 = FSL_DataFactory.createAssignedResource(towSA.id, ServiceResources[0].id);
            AssignedResource ar4 = FSL_DataFactory.createAssignedResource(towSA2.id, ServiceResources[0].id);            
            arList.add(ar1);
            arList.add(ar2);
            arList.add(ar3);
            arList.add(ar4);            
            
            insert arList;

            // update related SAs
            saList.clear();

            breakdownSA.FSL__Related_Service__c = towSA.id;
            breakdownSA.FSL__Same_Resource__c = true;
            towSA.FSL__Related_Service__c= breakdownSA.id;
            towSA.FSL__Same_Resource__c = true;     
            
            breakdownSA2.FSL__Related_Service__c = towSA2.id;
            breakdownSA2.FSL__Same_Resource__c = true;
            towSA2.FSL__Related_Service__c= breakdownSA2.id;
            towSA2.FSL__Same_Resource__c = true; 

            breakdownSA.status = 'Dispatched';
            breakdownSA2.status = 'Dispatched';

            breakdownSA.Service_Resource__c = ServiceResources[0].id;
            breakdownSA2.Service_Resource__c = ServiceResources[0].id;
            towSA.Service_Resource__c = ServiceResources[0].id;
            towSA2.Service_Resource__c = ServiceResources[0].id; 

            saList.add(breakdownSA);
            saList.add(breakdownSA2);            
            saList.add(towSA);
            saList.add(towSA2);
            update saList;

            system.debug('appointments updated: ' + saList);

            // find SR with appointments assigned
            List<ServiceAppointment> scheduledAppointmentList = [SELECT id, Service_Resource__c, Status, ServiceTerritoryID 
                FROM ServiceAppointment WHERE Service_Resource__c != null];
            
        
            //update saList; 
            ID resourceID;
            if(!scheduledAppointmentList.isEmpty()){
                resourceID = scheduledAppointmentList[0].Service_Resource__c;
            }
            
            // create OR
            FSL__Optimization_Request__c optRequest = new FSL__Optimization_Request__c();
            optRequest.FSL__Status__c = 'Queued';
            insert optRequest;

            FSL__Territory_Optimization_Request__c territoryOptimization = new FSL__Territory_Optimization_Request__c();
            territoryOptimization.FSL__ServiceTerritory__c = scheduledAppointmentList[0].ServiceTerritoryID;
            territoryOptimization.FSL__Optimization_Request__c = optRequest.id;
            insert territoryOptimization;
            
            // Update OR Status = Completed, Objects Scheduled > 0
            optRequest.FSL__Status__c = 'Completed';
            optRequest.FSL__Objects_Scheduled__c = 2;
            update optRequest;

            // Find count of appointments assigned to SR where Status = Dispatched
            List<ServiceAppointment> dispatchedAppointmentList = [SELECT id, Status 
                FROM ServiceAppointment 
                WHERE Status = 'Dispatched' AND recordTypeID = :recordTypeID];
                
            // Assert that the count == 1
            system.assertEquals(1, dispatchedAppointmentList.size(), 'The number of dispatched appointments is not correct');
            
            Test.stopTest();
        }
    }    

    @testSetup
    public static void dataSetup() {
        List<User> users = FSL_DataFactory.createTestuser();
        List<User> adminUserList = [SELECT id, Name, Alias FROM User WHERE Alias = 'C_Admin'];
        User adminUser = adminUserList.get(0);        
        system.runAs(adminUser){    
            FSL_DataFactoryUtility.setupCustomSettingsData();
 			
         //Created custum setting for testing 
         FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); // Added this custom setting as required for makePostCallout method.
          endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
          endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
          endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
          endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
          endpoint.Timeout__c = 20000;
          endpoint.Named_Credential__c = 'OAuth';
          endpoint.Name='OAuth';
          insert endpoint;
                  
            
            FSL_DataFactoryUtility.setupStatusTransitionData();
            List<Account> accounts = FSL_DataFactory.createAccounts();            
            List<Contact> contacts = FSL_DataFactory.createContacts();
            List<WorkType> workTypes = FSL_DataFactory.createWorkTypes();
            List<OperatingHours> OperatingHours = FSL_DataFactory.createOperatingHours();
            List<TimeSlot> TimeSlots = FSL_DataFactory.createTimeSlots();
            List<ServiceTerritory> ServiceTerritories = FSL_DataFactory.createServiceTerritory();
            ServiceTerritories[0].ParentTerritoryId =  ServiceTerritories[2].id;
            ServiceTerritories[1].ParentTerritoryId =  ServiceTerritories[2].id;
            update ServiceTerritories;

            FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');
            List<ServiceAppointment> appListComplex = [Select Id from ServiceAppointment];
           
            //Update account to terr
            for(Account acc : accounts){
                for(ServiceTerritory st : ServiceTerritories){
                    if(st.Facility_Number__c == acc.Facility_ID__c){
                        acc.Service_Territory__c = st.id;
                    }
                }
            }
            update accounts;
            
            List<Schema.Location> locations = FSL_DataFactory.createLocation();
            List<ServiceResource> ServiceResources = new List<ServiceResource>();
            //will create 3 resources
            for(Integer i=0; i < Users.size(); i++){
                ServiceResources.add(FSL_DataFactory.createServiceResource(users[i].id, locations[i].id));
            }
            insert ServiceResources;
            
            list<FSL__Scheduling_Policy__c> policies = FSL_DataFactory.createSchedulingPolicies();
            List<ServiceTerritoryMember> STMs = new List<ServiceTerritoryMember>();
            for(integer i = 0; i < ServiceResources.size(); i++){
                STMs.add(FSL_DataFactory.createServiceTerritoryMember(ServiceResources[i].id, ServiceTerritories[i].id));
            }
            insert STMs;

            list<FSL__User_Territory__c> userTerrs = new list<FSL__User_Territory__c>();
            for(integer i = 0; i < ServiceResources.size(); i++){
                FSL__User_Territory__c uTerr = FSL_DataFactory.createUserTerritories(ServiceResources[i].RelatedRecordid, ServiceTerritories[i].id);
                userTerrs.add(uTerr);
            }
            insert userTerrs;
            
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
            
            //User Message
            List <FSL_User_Message__c> userMessages = FSL_DataFactory.CreateUserMessages();

            /*
                // create shell objects for WO
                List<WorkOrder> woList = new List<WorkOrder>();
                WorkOrder wo1 = FSL_DataFactory.createWorkOrderShell('Light Service', accounts[0].id);
                woList.add(wo1);
                WorkOrder wo2 = FSL_DataFactory.createWorkOrderShell('Light Service', accounts[0].id);
                WorkOrder wo3 = FSL_DataFactory.createWorkOrderShell('Light Service', accounts[0].id);
                woList.add(wo2);
                woList.add(wo3);
                insert woList;

                // create shell objects for SA
                DateTime nowTime = Datetime.now();
                DateTime nextTime = nowTime.addMinutes(60);
                DateTime nextTime1 = nowTime.addMinutes(40);
                List<ServiceAppointment> saList = new List<ServiceAppointment>();
                ServiceAppointment sa = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo1.id, contacts[0].id, nowTime, 30);
                ServiceAppointment sa2 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo2.id, contacts[0].id, nextTime, 30);
                
                ServiceAppointment sa3 = FSL_DataFactory.createAppointmentShell('Breakdown', ServiceTerritories[0].id, wo3.id, contacts[0].id, nextTime1 , 30);
                saList.add(sa);
                saList.add(sa2);
                saList.add(sa3);
                insert saList;

                system.debug('appointments inserted: ' + saList);

                // create assigned resources for two SAs
                List<AssignedResource> arList = new List<AssignedResource>();
                AssignedResource ar1 = FSL_DataFactory.createAssignedResource(sa.id, ServiceResources[0].id);
                AssignedResource ar2 = FSL_DataFactory.createAssignedResource(sa2.id, ServiceResources[0].id);
                AssignedResource ar3 = FSL_DataFactory.createAssignedResource(sa3.id, ServiceResources[0].id);
                arList.add(ar1);
                arList.add(ar2);
                arList.add(ar3);
                
                insert arList;

                // update SAs to Scheduled
                saList.clear();
                sa.status = 'Scheduled';
                sa2.status = 'Scheduled';
                sa3.status = 'Spotted';
                sa.Service_Resource__c = ServiceResources[0].id;
                sa2.Service_Resource__c = ServiceResources[0].id;
                saList.add(sa);
                saList.add(sa2);
                saList.add(sa3);
                for(ServiceAppointment saComp : appListComplex) {
                    saComp.Service_Resource__c = ServiceResources[0].id;
                    saList.add(saComp);
                    //saList.add(sa);
                }
                update saList;

                system.debug('appointments updated: ' + saList);
            */


            
            
        }
    }    

}