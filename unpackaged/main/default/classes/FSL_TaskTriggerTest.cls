/**
 * @File Name          : FSL_TaskTriggerTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 11-09-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
**/
// @isTest
public class FSL_TaskTriggerTest {
    
    //  ***    Service Tech Team: Test class body is commented out as target class is retired   ***

    
    // static testMethod void testTask(){        
    //     FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     System.Test.startTest();
    //     List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
    //     ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
    //     list<ServiceAppointment> SAList = new list<ServiceAppointment>();
    //     list<AssignedResource> ARList = new list<AssignedResource>();
    //     FSL_User_Message__c userMessage=new FSL_User_Message__c();
    //     userMessage.Message_Id__c='SM-040';
    //     userMessage.Message_Text__c='Your Service Appointment has been cancelled.  Please clear the call.';
    //     insert userMessage;
    //     for(workOrder wo : workOrderList){
    //         wo.ServiceAppointments[0].SchedStartTime = System.now();
    //         wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
    //         wo.ServiceAppointments[0].actualstarttime = System.now();
    //         wo.ServiceAppointments[0].PTA__c = System.now();
    //         SAList.add(wo.ServiceAppointments[0]); 
            
    //         AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
	// 		ARList.add(assignedResource);
    //     }
        
    //     update SAList;
    //     insert ARList;
        
    //     List<Task> taskList = new List<Task>();
        
    //     for(MilestoneType mt : [select Id,name from MilestoneType ]){
    //         Task taskSpotted = new Task();
    //         taskSpotted.subject = mt.name;
    //         taskSpotted.WhatId = workOrderList[0].Id;
    //         taskList.add(taskSpotted);         	   
    //     }
        
        
    //     string body = '{ "id" : "b45d456a-3bd4-4f73-92b5-547b603bcd07", "requestEventType" : "UPDATE", "subType" : "UPDATE", "status" : "UNUSED", "version" : "1.0.0", "sourceSystem" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "targetSystem" : { "systemId" : "SLTest", "systemOrganization" : { "name" : "Salesforce", "code" : "014" } }, "createDate" : 1539736591270, "calls" : [ { "callKey" : "014-20180915-30000", "callDate" : "2018-09-15", "callId" : 30000, "version" : "1", "channel" : { "channelType" : "CALL_CENTER", "org" : { "name" : "HEATHROW", "code" : "HEA" }, "contact" : { "userId" : "JDC1234", "contactType" : "AGENT" }, "location" : { "latitude" : 28.769527, "longitude" : -81.362267, "address" : { "addressType" : "PHYSICAL", "full" : "1000 AAA DR, LAKE MARY, FL 32725", "streetNumber" : "1000", "streetDirection" : "EAST", "streetName" : "AAA DR", "crossStreet" : "INTERNATIONAL PKWY", "city" : "LAKE MARY", "county" : "SEMINOLE", "state" : "FL", "postalCode" : "32746", "country" : "UNITED STATES" } } }, "customer" : { "memberships" : [ { "membershipType" : "VIP", "sponsor" : "LINCOLN", "program" : "BLACK LABEL", "authorizationCode" : "1234534523", "authorizationLevel" : "123", "isLocalClub" : true, "org" : { "name" : "Auto Club Group", "code" : "014" }, "id" : "1234567890123456", "originalMemberId" : "1234567890123456", "expirationDate" : "2018-10-01", "memberLevel" : "PREMIERE", "memberBirthday" : "1978-09-15", "memberSince" : "1994", "memberStatus" : "ACTIVE", "entitlements" : [ { "serviceChargeIndicator" : false } ] } ], "contact" : { "contactType" : "CUSTOMER", "title" : "MR", "firstName" : "STEVE", "lastName" : "JONES", "phones" : [ { "phoneType" : "CELLULAR", "phoneNumber" : "1234567890", "phoneExtension" : "456", "preferred" : true, "smsOptIn" : true } ], "emails" : [ { "emailType" : "PERSONAL", "address" : "someuser@foobar.com" } ] }, "languagePreference" : "ENGLISH" }, "vehicle" : { "vehicleType" : "PS", "year" : 2012, "make" : "HONDA", "model" : "ACCORD", "trim" : "RX", "color" : "BLUE", "driveType" : "FW", "vin" : "432143124124E234", "tag" : "N12ABC", "state" : "FL", "odometer" : 78310, "fuelType" : "GAS", "rvInfo" : { "rvClass" : "A", "engineLocation" : "REAR", "gooseNeck" : false, "height" : 15.5, "length" : 24.2, "weight" : 1055, "towing" : false, "towingType" : "NOT TOWING" }, "trailerInfo" : { "axles" : 2, "condition" : "GOOD", "gooseNeck" : true, "hitchSize" : 3.5, "hitchType" : "BALL", "length" : 35.6, "loaded" : "????", "loadType" : "WATER", "loadWeight" : "1000", "plugType" : "7 PIN", "trailerType" : "5TH WHEEL" }, "specialEquipmentNeeds" : "NEED A BIG JACK" }, "service" : { "callType" : "MEMBER", "timezoneId" : "America/New_York", "timezoneOffset" : "UTC-07:00", "status" : { "status" : "SP", "modifiedDate" : "2018-09-15T10:05:21Z[UTC]", "eta" : "2018-09-15T10:05:41Z[UTC]", "pta" : "2018-09-15T10:05:51Z[UTC]", "waitTime" : 30 }, "appointmentTime" : "2018-09-15T10:05:51Z[UTC]", "facility" : { "foiType" : "ERS", "location" : { }, "id" : "9193", "name" : "BOBS TOWING ORLANDO SOUTH" }, "truck" : { "id" : "B1", "driver" : { "id" : "123", "contact" : { "contactType" : "DRIVER", "lastName" : "Truckdriver" } } }, "troubleCodes" : [ { "troubleCodeType" : "PACESETTER", "code" : "T680", "description" : "Engine Stalled While Driving" }, { "troubleCodeType" : "PACESETTER2", "code" : "T505", "description" : "L505 Parking Brake Wont Release" }, { "troubleCodeType" : "PROBLEM", "code" : "T6", "description" : "ENGINE STALLED" }, { "troubleCodeType" : "PROBLEM2", "code" : "T9", "description" : "PARKING BRAKE" } ], "serviceLocations" : [ { "serviceLocationType" : "BREAKDOWN", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 28.53349, "longitude" : -81.37751, "address" : { "addressType" : "PHYSICAL", "full" : "700 MAIN LANE, ORLANDO FL, 32801", "streetNumber" : "700", "streetDirection" : "SW", "streetName" : "MAIN LANE", "crossStreet" : "LUCERNE CIRCLE SW", "crossStreet2" : "HIGHWAY TO SOMEWHERE", "city" : "ORLANDO", "county" : "MONROE", "state" : "FL", "postalCode" : "32801", "country" : "UNITED STATES" }, "landmark" : "BOBS DINER", "highway" : "I-4", "mileMarker" : "47", "grid" : "B23", "zone" : "A1", "locationCode" : "BR" } }, "mileageCalculated" : 25, "driverDirections" : "GATECODE IS 12345" }, { "serviceLocationType" : "TOW_DESTINATION", "foi" : { "foiType" : "ADDRESS", "location" : { "latitude" : 26.98492, "longitude" : -82.10246, "address" : { "addressType" : "PHYSICAL", "full" : "3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952", "streetNumber" : "3156", "streetName" : "TAMIAMI TR", "crossStreet" : "OCEAN BOULEVARD", "city" : "PORT CHARLOTTE", "county" : "PINELLAS", "state" : "FL", "postalCode" : "33952", "country" : "UNITED STATES" }, "landmark" : "AAR DON GASGARTHS CHARLOTTE CO FORD" }, "name" : "AAA DON GASGARTH CHARLOTTE CO FORD", "contacts" : [ { "contactType" : "TOWDEST", "firstName" : "BOB", "lastName" : "SHMOE", "phones" : [ { "phoneType" : "BUSINESS", "phoneNumber" : "8889996666", "preferred" : true } ] } ] }, "mileageCalculated" : 18, "dropBoxInfo" : "FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR" } ], "collision" : false, "redFlag" : false, "priorityCode" : "P1", "legacyPriorityCode" : "P1", "numberOfPassengers" : 2, "needsFlatbed" : false, "flatbedRequested" : true, "policies" : [ { "code" : "POL1", "description" : "Service Policy1" } ], "providedServices" : [ { "providedServiceType" : "EXTRA CHARGE", "service" : "LONG TOW", "unit" : "MILES", "quantity" : 10, "charge" : { "chargeType" : "SERVICE_PROVIDED", "amount" : "5.00" } }, { "providedServiceType" : "", "service" : "GAS DELIVERY", "unit" : "GALLONS", "quantity" : 5 } ], "charges" : [ { "chargeType" : "GAS", "amount" : "10.00" } ] }, "payment" : { "required" : true, "paymentType" : "CREDIT", "codes" : "SOME PAYMENT CODES GO HERE" }, "comments" : [ { "system" : { "systemId" : "AAAD3Test", "systemOrganization" : { "name" : "AAA", "code" : "014" } }, "contact" : { "userId" : "ab5678", "contactType" : "AGENT" }, "commentDate" : "2018-09-15T10:05:20Z[UTC]", "commentType" : "CALL", "visibility" : "EXTERNAL", "text" : "THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS" } ] } ] }';
    //     Map<String, String> responseHeaders = new Map<String, String>{'Content-Type' => 'application/json;charset=UTF-8'};
    //     System.Test.setMock(HttpCalloutMock.class, new FSL_ToD3UpdateCalloutMockImpl(200, 'OK', body, responseHeaders));
        
    //     insert taskList;
    //     Task inViolation = new Task();
    //     inViolation.subject = 'Dispatched Escalation';
    //     inViolation.WhatId = workOrderList[0].Id;
    //     try {
    //         insert inViolation;
    //     }catch(Exception ex) {}
	
    //     System.Test.stopTest();
    // List<ServiceAppointment> UpdatedSAList=[Select id,FSL__InJeopardy__c,FSL__InJeopardyReason__c 
    //                                      FROM ServiceAppointment where ParentRecordId =:workOrderList[0].id];
   	// system.assertEquals(UpdatedSAList[0].FSL__InJeopardy__c,true);
	// system.assert(UpdatedSAList[0].FSL__InJeopardyReason__c.contains('Violation'));
    // }
    
    
    // static testMethod void updateRecordTypeTest(){
        
    //     List<Task> newTasksList = new List<Task>();
    //     Task t = new Task();
    //     t.Subject = 'Spotted Violation';
    //     newTasksList.add(t);
        
    //     t.Subject = 'In Tow Violation';
    //     newTasksList.add(t);
        
    //     t.Subject = 'On Location Violation';
    //     newTasksList.add(t);
        
    //     t.Subject = 'Dispatch In Violation';
    //     newTasksList.add(t);
        
    //     System.debug('#########before' + t.Subject);
    //     t.Subject = 'Clear Post';
    //     newTasksList.add(t);
    //     System.debug('#########after' + t.Subject);
        
    //     t.Subject = 'Dispatch In Violation';
    //     newTasksList.add(t);
        
    //     System.Test.startTest();
    //     new FSL_TaskTriggerHandler().updateRecordType(newTasksList); 
    //     System.Test.stopTest();     
    // }
    
    // @testSetup
    // public static void dataSetup() {
    //     FSL_DataFactoryUtility.userSetupwithStaticData();
    // }
    
}