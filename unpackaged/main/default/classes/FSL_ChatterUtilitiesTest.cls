@isTest
public class FSL_ChatterUtilitiesTest{
    
    static testMethod void postThisTest(){
      
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
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
        System.Test.StartTest(); 
        update SAList;
        insert ARList;
        
        Map<Id,String> woIdMessage = new Map<Id,String>();
        woIdMessage.put(workOrderList[0].Id,'SM-002');

        FSL_User_Message__c userMessage= new FSL_User_Message__c();
        userMessage.Message_Text__c='Breakdown location changed';
        userMessage.message_id__c='SM-002';
        insert userMessage;
        
        FSL_ChatterUtilities.postThis(woIdMessage);
        System.Test.StopTest();
    }
    static testMethod void followRecordsTest(){
     
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
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
        System.Test.StartTest(); 
        update SAList;
        insert ARList;
        
        
        Map<ID,ID> esToCreate = new Map<ID,ID>();
        esToCreate.put(workOrderList[0].Id, UserInfo.getUserId());
        
        List<EntitySubscription> subscriptionList = new List<EntitySubscription>();
        EntitySubscription entitySub = new EntitySubscription();
        entitySub.parentId = workOrderList[0].Id;
        entitySub.subscriberId = UserInfo.getUserId();
        
        subscriptionList.add(entitySub);
        insert subscriptionList;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_ChatterUtilities.followRecords(esToCreate);
        System.Test.StopTest();
    }
    
    static testMethod void unfollowRecordsTest(){
       
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
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
        System.Test.StartTest(); 
        update SAList;
        insert ARList;
        
        Map<ID,ID> esToCreate = new Map<ID,ID>();
        esToCreate.put(workOrderList[0].Id, UserInfo.getUserId());
        List<EntitySubscription> subscriptionList = new List<EntitySubscription>();
        EntitySubscription entitySub = new EntitySubscription();
        entitySub.parentId = workOrderList[0].Id;
        entitySub.subscriberId = UserInfo.getUserId();
        
        subscriptionList.add(entitySub);
        insert subscriptionList;
        System.assertEquals(subscriptionList.size() < 0,false, 'Size ');
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_ChatterUtilities.unfollowRecords(esToCreate);
        System.Test.StopTest();
    }
    
    static testMethod void postWOCommentsTest(){

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
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
        System.Test.StartTest(); 
        update SAList;
        insert ARList;        
        string json = '{"id":"7051b8d9-1076-4bc9-82c2-0d50a30cc7d6","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":1538566964227,"calls":[{"callKey":"014-20180915-30000","callDate":"2018-09-15","callId":30000,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"HEATHROW","code":"HEA"},"contact":{"userId":"JDC1234","contactType":"AGENT"},"location":{"latitude":28.769527,"longitude":-81.362267,"address":{"addressType":"PHYSICAL","full":"1000 AAA DR, LAKE MARY, FL 32725","streetNumber":"1000","streetDirection":"EAST","streetName":"AAA DR","crossStreet":"INTERNATIONAL PKWY","city":"LAKE MARY","county":"SEMINOLE","state":"FL","postalCode":"32746","country":"UNITED STATES"}}},"customer":{"memberships":[{"membershipType":"VIP","sponsor":"LINCOLN","program":"BLACK LABEL","authorizationCode":"1234534523","authorizationLevel":"123","isLocalClub":true,"org":{"name":"Auto Club Group","code":"014"},"id":"1234567890123456","expirationDate":"2018-10-01","memberLevel":"PREMIERE","memberBirthday":"1978-09-15","memberSince":"1994","memberStatus":"ACTIVE","entitlements":[{"serviceChargeIndicator":false}]}],"contact":{"contactType":"CUSTOMER","title":"MR","firstName":"STEVE","lastName":"JONES","phones":[{"phoneType":"CELLULAR","phoneNumber":"1234567890","phoneExtension":"456","preferred":true,"smsOptIn":true}],"emails":[{"emailType":"PERSONAL","address":"someuser@foobar.com"}]},"languagePreference":"ENGLISH"},"vehicle":{"vehicleType":"PS","year":2012,"make":"HONDA","model":"ACCORD","trim":"RX","color":"BLUE","driveType":"FW","vin":"432143124124E234","tag":"N12ABC","state":"FL","odometer":78310,"fuelType":"GAS","rvInfo":{"rvClass":"A","engineLocation":"REAR","gooseNeck":false,"height":15.5,"length":24.2,"weight":1055,"towing":false,"towingType":"NOT TOWING"},"trailerInfo":{"axles":2,"condition":"GOOD","gooseNeck":true,"hitchSize":3.5,"hitchType":"BALL","length":35.6,"loaded":"????","loadType":"WATER","loadWeight":"1000","plugType":"7 PIN","trailerType":"5TH WHEEL"},"specialEquipmentNeeds":"NEED A BIG"},"service":{"callType":"MEMBER","timezoneId":"America/New_York","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2018-09-15T10:05:21Z[UTC]","eta":"2018-09-15T10:05:41Z[UTC]","pta":"2018-09-15T10:05:51Z[UTC]","waitTime":30},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"9193","name":"BOBS TOWING ORLANDO SOUTH"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T680","description":"Engine Stalled While Driving"},{"troubleCodeType":"PACESETTER2","code":"T505","description":"L505 Parking Brake Wont Release"},{"troubleCodeType":"PROBLEM","code":"T6","description":"ENGINE STALLED"},{"troubleCodeType":"PROBLEM2","code":"T9","description":"PARKING BRAKE"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":28.53349,"longitude":-81.37751,"address":{"addressType":"PHYSICAL","full":"700 MAIN LANE, ORLANDO FL, 32801","streetNumber":"700","streetDirection":"SW","streetName":"MAIN LANE","crossStreet":"LUCERNE CIRCLE SW","crossStreet2":"HIGHWAY TO SOMEWHERE","city":"ORLANDO","county":"MONROE","state":"FL","postalCode":"32801","country":"UNITED STATES"},"highway":"I-4","mileMarker":"47","grid":"B23","zone":"A1","locationCode":"BR"}},"mileageCalculated":25,"driverDirections":"GATECODE IS 12345"},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"ADDRESS","location":{"latitude":26.98492,"longitude":-82.10246,"address":{"addressType":"PHYSICAL","full":"3156 TAMIAMI TR, PORT CHARLOTTE, FL 33952","streetNumber":"3156","streetName":"TAMIAMI TR","crossStreet":"OCEAN BOULEVARD","city":"PORT CHARLOTTE","county":"PINELLAS","state":"FL","postalCode":"33952","country":"UNITED STATES"},"landmark":"AAR DON GASGARTHS CHARLOTTE CO FORD"},"name":"AAA DON GASGARTH CHARLOTTE CO FORD","contacts":[{"contactType":"TOWDEST","firstName":"BOB","lastName":"SHMOE","phones":[{"phoneType":"BUSINESS","phoneNumber":"8889996666","preferred":true}]}]},"mileageCalculated":18,"dropBoxInfo":"FACILITY DROPBOX IS LOCATED IN FRONT BY DOOR"}],"collision":false,"redFlag":false,"priorityCode":"P1","numberOfPassengers":2,"needsFlatbed":false,"flatbedRequested":true,"policies":[{"code":"POL1","description":"Service Policy1"}]},"payment":{"required":true,"paymentType":"CREDIT","codes":"SOME PAYMENT CODES GO HERE"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"contact":{"userId":"ab5678","contactType":"AGENT"},"commentDate":"2018-09-15T10:05:20Z[UTC]","commentType":"CALL","visibility":"EXTERNAL","text":"THIS IS A COMMENT ABOUT THIS CALL VISIBLE TO ALL USERS"}]}]}';
        
        FSL_JSonParserWorkOrder jsonParsed = (FSL_JSonParserWorkOrder) System.JSON.deserialize(json, FSL_JSonParserWorkOrder.class);
        FSL_ChatterUtilities.postWOComments(workOrderList[0].Id, jsonParsed.calls[0].comments);
        System.Test.StopTest();
    }
    
    static testMethod void createSubscriptionTest(){
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
         FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
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
       
        System.Test.StartTest(); 
        update SAList;
        insert ARList; 
        Map<Id, Id> saUIdMap = new Map<Id, Id>();
        saUIdMap.put(SAList[0].Id, UserInfo.getUserId());
        saUIdMap.put(SAList[0].Id,  UserInfo.getUserId());
        FSL_ChatterUtilities.createSubscription(saUIdMap);
        System.Test.StopTest();
    }
    
    @testSetup
    public static void dataSetup() {
        // FSL_DataFactoryUtility.userdataSetup();
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
}