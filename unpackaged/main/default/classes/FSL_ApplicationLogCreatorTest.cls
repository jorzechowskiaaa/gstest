/**
* @File Name          : FSL_ApplicationLogCreatorTest.cls
* @Description        : 
* @Author             : Rajesh Kemisetti
* @Group              : 
* @Last Modified By   : Clement Shiu
* @Last Modified On   : 11-09-2021
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    6/4/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_ApplicationLogCreatorTest {
    static testMethod void getProcessTimeTest(){
        
        FSL_ApplicationLogCreator.getProcessTime(System.now(), System.now().addMinutes(30));
    }
    
    static testMethod void schedulingLoggerTest(){
        FSL_ApplicationLogCreator.schedulingLogger('update', 'test Message', true); 
        FSL_ApplicationLogCreator.schedulingLogger('update', 'test Message', false);
    }
    
    static testMethod void insertAplicationLogTest(){
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonReq);
        
        String jsonRes = '{"id": "7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType": "CREATE","subType": "CREATE","status": "UNUSED","version": "1.0.0","sourceSystem": {"systemId": "AAAD3Test","systemOrganziation": {"name": "AAA","code": "014"}},"createDate": 1538566964227,"calls": [{"callKey": "A14-20180915-18933","callDate": "2018-09-15","callId": 30000,"version": "1"}]}"';
        FSL_WorkOrderResponse res = (FSL_WorkOrderResponse)Json.deserialize(jsonRes,FSL_WorkOrderResponse.class);
        System.Test.startTest(); 
        Workorder wo = [select id from Workorder limit 1];
        FSL_ApplicationLogCreator.insertAplicationLog(req, res, 'String message', 'Update', true, UserInfo.getUserId(), '1', wo);
        FSL_ApplicationLogCreator.insertAplicationLog(req, res, 'String message', 'Update', false, UserInfo.getUserId(), '1', wo);
        System.Test.stopTest();
        
    }
    
    static testMethod void createScheduleServiceLogTest(){
        System.Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        list<ServiceAppointment> saList = [select id from ServiceAppointment order by recordtype.name asc];        
        FSL__Scheduling_Policy__c schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1];
        
        //FSL.ScheduleResult scheduleRequest = FSL.ScheduleService.Schedule(schedulingPolicy.Id, saList[0].ID);
        FSL.ScheduleResult myResult = new FSL.ScheduleResult();
        
        
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        
        FSL_ApplicationLogCreator.createScheduleServiceLog(jsonReq, null, 'String message', 'Update', true, UserInfo.getUserId(), '1', saList[0].Id);
        FSL_ApplicationLogCreator.createScheduleServiceLog(jsonReq, myResult, 'String message', 'Update', false, UserInfo.getUserId(), '1', saList[0].Id);
        System.Test.stopTest();
    }
    
    static testMethod void calloutLoggerTest(){      
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        System.Test.startTest();
        FSL_ApplicationLogCreator.calloutLogger(jsonReq, jsonReq, 'String message', 'Update', true, UserInfo.getUserId(), '1', 'String APIName');
        FSL_ApplicationLogCreator.calloutLogger(jsonReq, jsonReq, 'String message', 'Update', false, UserInfo.getUserId()+',123467', '1', 'String APIName');
        System.Test.stopTest();
    }
    
    static testMethod void callInLoggerTest(){      
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        System.Test.startTest();
        FSL_ApplicationLogCreator.callInLogger(jsonReq, jsonReq, 'String message', 'Update', true, UserInfo.getUserId(), '1', 'String APIName');
        FSL_ApplicationLogCreator.callInLogger(jsonReq, jsonReq, 'String message', 'Update', false, UserInfo.getUserId()+',123467', '1', 'String APIName');
        System.Test.stopTest();
    }
    
    static testMethod void callInGlympseLoggerTest(){      
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        System.Test.startTest();
        FSL_ApplicationLogCreator.callInGlympseLogger(jsonReq, jsonReq, 'String message', true, UserInfo.getUserId(), '1', '', null); 
        FSL_ApplicationLogCreator.callInGlympseLogger(jsonReq, jsonReq, 'String message', false, UserInfo.getUserId()+',123467', '1', '', null);
        System.Test.stopTest();
    }
    
    @IsTest
    static void testApplicationLogCreator_RoutingLogger_EnabledTrue(){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));                                
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.startTest();
        
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            SAList.add(wo.ServiceAppointments[0]); 
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            ARList.add(assignedResource);
        }
        
        update SAList;
        insert ARList;        
        
        // Retrieve that Map, and update the FSL__Estimated_Travel_Time_To_Source__c field
        list<AssignedResource> ARListNew = [SELECT Id, FSL__Estimated_Travel_Time_To_Source__c FROM AssignedResource Limit 1];
        ARListNew[0].FSL__Estimated_Travel_Time_To_Source__c = 'Changed Estimated Travel Time (Minutes) from 9.00 To 0.00 and Estimated Travel Time To Source from SLR to None';
        
        Map<Id, AssignedResource> updatedARNewMap = new Map<Id, AssignedResource>();
        updatedARNewMap.put(ARListNew[0].Id, ARListNew[0]);        
        
        // Create service              
        FSL_ApplicationLogTest.ApplicationLogDAOMock daoMock = new FSL_ApplicationLogTest.ApplicationLogDAOMock();
        FSL_Feature_Flag__mdt expected = new FSL_Feature_Flag__mdt( Enabled__c = true );  
        daoMock.fslFeatureFlagConfiguration = expected;                
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService(daoMock);   
        
        Boolean isRoutingChangeLoggingEnabled = service.isRoutingChangeLoggingEnabled();
        FSL_ApplicationLogCreator.routingLogger(ARList, updatedARNewMap, service);
        
        Test.stopTest();
        
        // Verify results
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c WHERE Operation__c = 'RoutingChange' Limit 1];
        System.assertEquals( true, apLogs[0].API_Name__c.containsIgnoreCase('SLR'));        
        
        
    }
    
    @IsTest
    static void testApplicationLogCreator_RoutingLogger_EnabledFalse(){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));                                
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.startTest();
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            SAList.add(wo.ServiceAppointments[0]); 
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            ARList.add(assignedResource);
        }
        
        update SAList;
        insert ARList;        
        
        // Retrieve that Map, and update the FSL__Estimated_Travel_Time_To_Source__c field
        list<AssignedResource> ARListNew = [SELECT Id, FSL__Estimated_Travel_Time_To_Source__c FROM AssignedResource Limit 1];
        ARListNew[0].FSL__Estimated_Travel_Time_To_Source__c = 'Changed Estimated Travel Time (Minutes) from 9.00 To 0.00 and Estimated Travel Time To Source from SLR to None';
        
        Map<Id, AssignedResource> updatedARNewMap = new Map<Id, AssignedResource>();
        updatedARNewMap.put(ARListNew[0].Id, ARListNew[0]);        
        
        // Create service, disable this feature flag         
        FSL_ApplicationLogTest.ApplicationLogDAOMock daoMock = new FSL_ApplicationLogTest.ApplicationLogDAOMock();
        FSL_Feature_Flag__mdt expected = new FSL_Feature_Flag__mdt( Enabled__c = false );       
        daoMock.fslFeatureFlagConfiguration = expected;               
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService(daoMock);   
        
        Boolean isRoutingChangeLoggingEnabled = service.isRoutingChangeLoggingEnabled();
        FSL_ApplicationLogCreator.routingLogger(ARList, updatedARNewMap, service);
        
        Test.stopTest();
        
        // Verify results, since we disabled the Feature flag, there should be no Application Log entry
        List<FSL_Application_Log__c> apLogs = [SELECT Id, API_Name__c FROM FSL_Application_Log__c WHERE Operation__c = 'RoutingChange' Limit 1];
        System.assertEquals( false, apLogs.size() > 0);      
        
        FSL_ApplicationLogCreator.routingLogger(ARList);
        
        
    }
    
    @IsTest
    static void testInsertMemberValidationAppLog(){
        HttpResponse response = new HttpResponse();
        HttpRequest request = new HttpRequest();
        Test.startTest();
        request.setBody('Customer:{}');
        FSL_ApplicationLogCreator.insertMemberValidationAppLog(request, response, 'String Message', true, UserInfo.getUserId(), '1');
        FSL_ApplicationLogCreator.insertMemberValidationAppLog(request, response, 'String Message', false, UserInfo.getUserId(), '1');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testUncovered(){
        Test.startTest();
        
        String jsonRes = '{"id": "7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType": "CREATE","subType": "CREATE","status": "UNUSED","version": "1.0.0","sourceSystem": {"systemId": "AAAD3Test","systemOrganziation": {"name": "AAA","code": "014"}},"createDate": 1538566964227,"calls": [{"callKey": "A14-20180915-18933","callDate": "2018-09-15","callId": 30000,"version": "1"}]}"';
        FSL_WorkOrderResponse res = (FSL_WorkOrderResponse)Json.deserialize(jsonRes,FSL_WorkOrderResponse.class);
        
        HttpResponse response = new HttpResponse();
        HttpRequest request = new HttpRequest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, D3_Call_ID__c, Address, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        
        FSL_ApplicationLogCreator.insertApplicationLogEvent('reqBody', 'responseBody', 'apiName', true, 'message');
        FSL_ApplicationLogCreator.insertAplicationLogGeneric('String calloutRequest', 'String calloutResponse', 'String message','String operation',true,
                                                             'String callId', workOrderList[0].Id, 'String apiName', workOrderList[0].ServiceAppointments[0].Id);
        FSL_ApplicationLogCreator.integrationLog('String request', 'String response', 'String apiName','String operation',false,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.SaveMemberDataAppLog('String apiName',false,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.IVRLookupLogger('String request', 'String response', False, 'String bulkCallIds', 'String APIName', 'String successMsg', 'String errorMsg');
        FSL_ApplicationLogCreator.SaveMemberDataAppLog('String apiName',False,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.addressLogger(workOrderList[0].ServiceAppointments, New Map<Id, ServiceAppointment>(workOrderList[0].ServiceAppointments));
        FSL_ApplicationLogCreator.createLogReferenceWithoutInsert('String req', response, 'String message','String operation',false,'String callId','String version',workOrderList[0].ServiceAppointments[0].Id , 'String apiName');
        
        Test.stopTest();
        
    }
    
    static testMethod void insertAppLogForUpdateTest(){
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
        string jsonReq = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        String jsonRes = '{"id": "7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType": "CREATE","subType": "CREATE","status": "UNUSED","version": "1.0.0","sourceSystem": {"systemId": "AAAD3Test","systemOrganziation": {"name": "AAA","code": "014"}},"createDate": 1538566964227,"calls": [{"callKey": "A14-20180915-18933","callDate": "2018-09-15","callId": 30000,"version": "1"}]}"';
        FSL_WorkOrderResponse res = (FSL_WorkOrderResponse)Json.deserialize(jsonRes,FSL_WorkOrderResponse.class);
        
        HttpResponse response = new HttpResponse();
        HttpRequest request = new HttpRequest();
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, D3_Call_ID__c, Address, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        
        FSL_ApplicationLogCreator.insertApplicationLogEvent('reqBody', 'responseBody', 'apiName', true, 'message');
        FSL_ApplicationLogCreator.insertAplicationLogGeneric('String calloutRequest', 'String calloutResponse', 'String message','String operation',true,
                                                             'String callId', workOrderList[0].Id, 'String apiName', workOrderList[0].ServiceAppointments[0].Id);
        FSL_ApplicationLogCreator.integrationLog('String request', 'String response', 'String apiName','String operation',false,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.SaveMemberDataAppLog('String apiName',false,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.IVRLookupLogger('String request', 'String response', False, 'String bulkCallIds', 'String APIName', 'String successMsg', 'String errorMsg');
        FSL_ApplicationLogCreator.SaveMemberDataAppLog('String apiName',False,'String message',workOrderList[0].Id);
        FSL_ApplicationLogCreator.addressLogger(workOrderList[0].ServiceAppointments, New Map<Id, ServiceAppointment>(workOrderList[0].ServiceAppointments));
        FSL_ApplicationLogCreator.createLogReferenceWithoutInsert('String req', response, 'String message','String operation',false,'String callId','String version',workOrderList[0].ServiceAppointments[0].Id , 'String apiName');
        
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonReq);
        
        //String jsonRes = '{"id": "7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType": "CREATE","subType": "CREATE","status": "UNUSED","version": "1.0.0","sourceSystem": {"systemId": "AAAD3Test","systemOrganziation": {"name": "AAA","code": "014"}},"createDate": 1538566964227,"calls": [{"callKey": "A14-20180915-18933","callDate": "2018-09-15","callId": 30000,"version": "1"}]}"';
        //FSL_WorkOrderResponse res = (FSL_WorkOrderResponse)Json.deserialize(jsonRes,FSL_WorkOrderResponse.class);
        System.Test.startTest(); 
        Workorder wo = [select id from Workorder limit 1];
        FSL_ApplicationLogCreator.insertAppLogForUpdate(req, res, 'String message','String operation',false,'String callId','String version',wo);
        System.Test.stopTest();
        
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }	    
}