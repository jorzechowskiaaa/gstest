@isTest 
public class CallReceiveWorkOrderIntegrationTest {
    public static FSL_JSonParserWorkOrder jsonParserWO = new FSL_JSonParserWorkOrder();

    public static void setup() {
        
        jsonParserWO.id = 'Test Id';
        jsonParserWO.requestEventType = 'Test requestEventType';
    	jsonParserWO.subType = 'Test subType'; 
    	jsonParserWO.status = 'Test status'; 
    	jsonParserWO.version = 'Test version';
    	jsonParserWO.createDate = 'Test createDate';
        jsonParserWO.reconcileEntitlement = false;
        
        FSL_JSonParserWorkOrder.Phones_Contacts phoneContact = new FSL_JSonParserWorkOrder.Phones_Contacts();
        phoneContact.phoneNumber = '9999999999';
        phoneContact.phoneType = 'Work';
        phoneContact.preferred = true;
         
        FSL_JSonParserWorkOrder.SystemOrganziation systemOrg = new FSL_JSonParserWorkOrder.SystemOrganziation();
        systemOrg.code = 'Test Code';
        systemOrg.name = 'Test Name';
        
        FSL_JSonParserWorkOrder.SourceSystem sourceSystem = new FSL_JSonParserWorkOrder.SourceSystem();
        sourceSystem.systemId = 'Test System Id';
        sourceSystem.systemOrganziation = systemOrg;
        
        jsonParserWo.sourceSystem = sourceSystem;
        jsonParserWo.targetSystem = sourcesystem;
        
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        
        FSL_JSonParserWorkOrder.Contact contact = new FSL_JSonParserWorkOrder.Contact();        
        contact.userId = 'USER ID';
        contact.contactType = 'Test Contact Type';
        
        FSL_JSonParserWorkOrder.Location location = new FSL_JSonParserWorkOrder.Location();
        FSL_JSonParserWorkOrder.Address address = new FSL_JSonParserWorkOrder.Address();
        address.addressType = 'Home Address';
        address.city = 'City';
        //address.country = 'USA';
        address.county = 'County';
        address.crossStreet = 'Cross Street';
        address.crossStreet2 = 'Cross Street1';
        address.full = '';
        address.postalCode = '12345';
        address.state = 'CA';
        address.street = 'Street';
        address.streetDirection = '';
        address.streetName = 'Street Name';
        address.streetNumber = '1234B';
        
        location.address = address;
        location.latitude = 3.4385112;
        location.longitude = -1.18573;
        
        FSL_JSonParserWorkOrder.Channel channel = new FSL_JSonParserWorkOrder.Channel();
        channel.channelType = 'Test Channel Type';
        channel.org = systemOrg;
        channel.contact = contact;
        channel.location = location;
        
        FSL_JSonParserWorkOrder.Customer customer = new FSL_JSonParserWorkOrder.Customer();
        FSL_JSonParserWorkOrder.Memberships membership = new FSL_JSonParserWorkOrder.Memberships();
        FSL_JSonParserWorkOrder.Contact_customer custContact = new FSL_JSonParserWorkOrder.Contact_customer();
        FSL_JSonParserWorkOrder.Entitlements entitlements = new FSL_JSonParserWorkOrder.Entitlements();
        entitlements.serviceChargeIndicator = true;
        
        membership.authorizationCode = '010';
        membership.authorizationLevel = 'P';
        // membership.authorizationTransactionId = 'Test Auth TransactionId';
        membership.entitlements = new List<FSL_JSonParserWorkOrder.Entitlements>{entitlements};
        //membership.expirationDate = '10/10/2019';  
        membership.id = 'TestId';
        membership.isLocalClub = true;
        membership.memberBirthday = '10/10/2000';
        membership.memberLevel = '1';
        membership.membershipType = 'Test Type';
        membership.memberSince = '2016';
        membership.memberStatus = 'Active';
        membership.org = systemOrg;
        membership.originalMemberId = '12345';
        membership.program = 'Test Program';
        membership.sponsor = 'Test Sponsor';   
        membership.goodwill = 'N';   

        FSL_JSonParserWorkOrder.Phones contactPhone = new FSL_JSonParserWorkOrder.Phones();
        contactPhone.phoneNumber = '9999999999';
        contactPhone.phoneType = 'Work';
        contactPhone.preferred = true;
        contactPhone.smsOptIn = true;

        custContact.contactType = 'Test Contact Type';
        custContact.firstName = 'Test First Name';
        custContact.lastName = 'Test Last Name';
        custContact.phones = new List<FSL_JSonParserWorkOrder.Phones>{contactPhone};
        
        customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{membership};
        customer.languagePreference = 'English';
        customer.contact = custContact;
        customer.contact.contactType = 'MEMBER';
        customer.contact.firstName = 'FIRSTNAME';
        customer.contact.lastName = 'LASTNAME';

        FSL_JSonParserWorkOrder.Vehicle vehicle = new FSL_JSonParserWorkOrder.Vehicle();
        FSL_JSonParserWorkOrder.TrailerInfo trailerInfo = new FSL_JSonParserWorkOrder.TrailerInfo();
        FSL_JSonParserWorkOrder.RvInfo rvInfo = new FSL_JSonParserWorkOrder.RvInfo();
        rvInfo.engineLocation = 'Test engine location';
        rvInfo.gooseNeck = true;
        rvInfo.height = 10.00;
        rvInfo.length = 10.00;
        rvInfo.rvClass = 'R1';
        rvInfo.towing = true;
        rvInfo.towingType = 'TowType';
      //  rvInfo.weight = 10;
        
        trailerInfo.axles = 1;
        trailerInfo.condition = 'Condition';
        trailerInfo.gooseNeck = true;
        trailerInfo.hitchSize = 10.00;
        trailerInfo.hitchType = 'Hitch';
        trailerInfo.length = 10.00;
        trailerInfo.loaded = 'loaded';
        trailerInfo.loadType = 'Load';
        trailerInfo.loadWeight = 'Weight';
        trailerInfo.plugType = 'Plug type';
        trailerInfo.trailerType = 'Trailor Type';
        
        vehicle.color = 'Red';
        vehicle.driveType = 'Regular';
        vehicle.fuelType = 'Petrol';
        vehicle.make = 'Make';
        vehicle.model = 'Model';
        vehicle.odometer = 10;
        vehicle.specialEquipmentNeeds = 'Test Needs';
        vehicle.state = 'CA';
        vehicle.tag = 'Test Tag';
        vehicle.trim = 'Test Trim';
        vehicle.vehicleType = 'Test Vehicle Type';
        vehicle.vin = '12POUBVXRR142865';
        vehicle.year = 2015;
        vehicle.trailerInfo = trailerInfo;
        vehicle.rvInfo = rvInfo;
        vehicle.keycodes = new FSL_JSonParserWorkOrder.Keycodes();
        vehicle.keycodes.door = 'door';
        vehicle.keycodes.ignition = 'ignition';
        vehicle.keycodes.mmpv = 'mmpv';
        vehicle.keycodes.vats = 'vats';
        
        FSL_JSonParserWorkOrder.Service service = new FSL_JSonParserWorkOrder.Service();
        FSL_JSonParserWorkOrder.Facility facility = new FSL_JSonParserWorkOrder.Facility();
        FSL_JSonParserWorkOrder.Policies policy = new FSL_JSonParserWorkOrder.Policies();
        FSL_JSonParserWorkOrder.ServiceLocations serviceLocation = new FSL_JSonParserWorkOrder.ServiceLocations();

        FSL_JSonParserWorkOrder.ServiceLocations serviceLocationTow = new FSL_JSonParserWorkOrder.ServiceLocations();

        FSL_JSonParserWorkOrder.Foi foi = new FSL_JSonParserWorkOrder.Foi();
        FSL_JSonParserWorkOrder.Contacts contacts = new FSL_JSonParserWorkOrder.Contacts();
        FSL_JSonParserWorkOrder.ServiceLocations_Location serviceLocationLocation = new FSL_JSonParserWorkOrder.ServiceLocations_Location();
        FSL_JSonParserWorkOrder.Location_TowDest loc_towDest = new FSL_JSonParserWorkOrder.Location_TowDest();
        FSL_JSonParserWorkOrder.Address_TowAddress add_TowAdd = new FSL_JSonParserWorkOrder.Address_TowAddress();
        FSL_JSonParserWorkOrder.Foi_TowDest foi_TowDest = new FSL_JSonParserWorkOrder.Foi_TowDest();
        FSL_JSonParserWorkOrder.TroubleCodes troubleCode = new FSL_JSonParserWorkOrder.TroubleCodes();
        FSL_JSonParserWorkOrder.Status status = new FSL_JSonParserWorkOrder.Status();
        
        add_TowAdd.addressType = 'Test Address type';
        add_TowAdd.city = 'Test City';
        //add_TowAdd.country = 'USA';
        add_TowAdd.county = 'County';
        add_TowAdd.crossStreet = 'Cross Street';
        add_TowAdd.full = '';
        add_TowAdd.postalCode = '12345';
        add_TowAdd.state = 'CA';
        add_TowAdd.streetName = 'Street Name';
        add_TowAdd.streetNumber = '1234B';
        
        loc_towDest.address = add_TowAdd;
        loc_towDest.landmark = 'Test Landmark';
        loc_towDest.latitude = 9.98;
        loc_towDest.longitude = 98.09;
        
        foi_TowDest.location = loc_towDest;
        foi_TowDest.name = 'Test Name';
        
        serviceLocationLocation.address = address;
        serviceLocationLocation.grid = 'Test Grid';
        serviceLocationLocation.highway = 'Test Highway';
        serviceLocationLocation.landmark = 'Test Landmark';
        serviceLocationLocation.latitude = 10.987;
        serviceLocationLocation.locationCode = 'Test Code';
        serviceLocationLocation.longitude = 96.97;
        serviceLocationLocation.mileMarker = 'Test Mile Marker';
        serviceLocationLocation.zone = 'Test Zone';
        
        contacts.contactType = 'Test Contact Type';
        contacts.firstName = 'Test First Name';
        contacts.lastName = 'Test Last Name';
        contacts.phones = new List<FSL_JSonParserWorkOrder.Phones_Contacts>{phoneContact};
        
        foi.location = serviceLocationLocation;
        foi.name = 'Test Name';
        foi.contacts = new List<FSL_JSonParserWorkOrder.Contacts>{contacts};
            
        serviceLocation.driverDirections = 'Test driver direction';
        serviceLocation.dropBoxInfo = 'Test DropBox Info';
        serviceLocation.foi = foi;
        serviceLocation.mileageCalculated = 12;
        serviceLocation.milesFromOrigin = 19;
        serviceLocation.serviceLocationType = 'BREAKDOWN';

        serviceLocationTow.driverDirections = 'Test driver direction';
        serviceLocationTow.dropBoxInfo = 'Test DropBox Info';
        serviceLocationTow.foi_towDest = foi_TowDest;
        serviceLocationTow.mileageCalculated = 12;
        serviceLocationTow.milesFromOrigin = 19;
        serviceLocationTow.serviceLocationType = 'TOW_DESTINATION';        
        
        facility.foiType = 'Test foiType';
        facility.id = '9198';
        facility.name = 'ABC TEST';
        
        troubleCode.code = 'T923';
        troubleCode.description = 'Test description';
        troubleCode.troubleCodeType = 'PACESETTER';
        
        //status.eta = '2022-12-07T00:30:24Z[UTC]';
        status.modifiedDate = '2022-12-06T23:30:24Z[UTC]';
        status.pta = '2022-12-07T00:30:24Z[UTC]';
        status.status = 'SP';
        status.waitTime = 60;
        
        policy.code = 'Test Code';
        policy.description = 'Test Description';
        
        service.apdSeqId = 'apdSeqId';
        //service.appointmentTime = '';
        service.callType = 'Test Call Type';
        service.collision = true;
        service.flatbedRequested = true;
        service.legacyPriorityCode = 'P3';
        service.needsFlatbed = true;
        service.numberOfPassengers = 10;
        service.policies = new List<FSL_JSonParserWorkOrder.Policies>{policy}; 
        service.priorityCode = 'Medium';
        service.redFlag = true;
        service.timezoneId = 'Test Time Zone Id';
        service.timezoneOffset = 'UTC-08:00';
        service.status = status;
        service.chargeEntitlement = true;
        service.useHomeLockoutEntitlement = true;
       // service.useBatteryEntitlement = false;
        service.useYourLongTowEntitlement = false;
        service.TroubleCodes = new List<FSL_JSonParserWorkOrder.TroubleCodes>{troubleCode};
        service.serviceLocations = new List<FSL_JSonParserWorkOrder.ServiceLocations>{serviceLocation, serviceLocationTow};

        service.facility = facility;
       
        
        FSL_JSonParserWorkOrder.Payment payment = new FSL_JSonParserWorkOrder.Payment();
        payment.codes = 'Test Codes';
        payment.paymentType = 'Test Payment Type';
        payment.required = true;
            
        FSL_JSonParserWorkOrder.Comments comment = new FSL_JSonParserWorkOrder.Comments();
        comment.commentType = 'Test Comment Type';
        comment.contact = contact;
        comment.date_str = 'Test Date String';
        comment.system_Z = sourceSystem;
        comment.text = 'Test Text';
        comment.visibility = 'Public';
        
        
        call.callDate = '10/10/2019';
        call.callId = 'ID-01987';
        call.callKey = 'Test Call Key';
        call.channel = channel;
        call.date_str = 'Date-str';
        call.id = 1;
        call.woLookup = false;
        call.version = 'Test Version';
        call.customer = customer;
        call.vehicle = vehicle;
        call.service = service;
        call.payment = payment;
        call.comments = new List<FSL_JSonParserWorkOrder.Comments>{comment};
                     
        jsonParserWo.calls = new List<FSL_JSonParserWorkOrder.Calls>{call};
            
		FSL_JSonParserWorkOrder.Contact_customer cust_Contact = new FSL_JSonParserWorkOrder.Contact_customer(); 
        FSL_JSonParserWorkOrder.Emails email = new FSL_JSonParserWorkOrder.Emails();
        FSL_JSonParserWorkOrder.Phones phone = new FSL_JSonParserWorkOrder.Phones();
        
        phone.phoneExtension = 'Test Phone Extension';
        phone.phoneNumber = '9999999999';
        phone.phoneType = 'Test Phone Type';
        phone.preferred = true;
        phone.smsOptIn = true;
            
        email.address = 'Test Address';
        email.emailType = 'Test Email Type';
        
        cust_Contact.contactType = 'Test Contact Type';
        cust_Contact.firstName = 'Test First Name';
        cust_Contact.lastName = 'Test Last Name';
        cust_Contact.title = 'Title';
        cust_Contact.emails = new List<FSL_JSonParserWorkOrder.Emails>{email};
        cust_Contact.phones = new List<FSL_JSonParserWorkOrder.Phones>{phone};    
    }

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

    @isTest
    public static void WorkOrderCreateTest() {

        setup();
        //WorkOrder wo = CallReceiveWorkOrderIntegration.createWorkOrder(jsonParserWO);

        FSL_DataFactory.createReqFldValidationSetting();
        //FSL_DataFactory.createWorkTypes();

        //CallReceiveWorkOrderIntegration.createTroubleCodes(jsonParserWO, wo);

        //CallReceiveWorkOrderIntegration.createMemberVehicle(jsonParserWO, wo);

        //CallReceiveWorkOrderIntegration.createPolicy(jsonParserWO, wo);

        CallReceiveWorkOrderIntegration.createWO(jsonParserWO);
    }

    @isTest
    static void TestCaseToJsonWrapper() {

        Id recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case objcs = new Case();
        objcs = ACG_TestDataFactory.createcase(recordTypeID,'In Progress','Phone',false);
        Id MEMBER_ACCOUNT_RECORDTYPEID =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        List<Account> lstMemberAcc=ACG_TestDataFactory.createAccounts(MEMBER_ACCOUNT_RECORDTYPEID,1,false,true);
        lstMemberAcc[0].ACG_AAA_Membership__c='123';
        //MemberAcc.PersonEmail='test@gmail.com';
        lstMemberAcc[0].Email_Type__pc='PERSONAL';
        lstMemberAcc[0].Fax='2222222222';
        lstMemberAcc[0].Phone='2222222222';
        lstMemberAcc[0].PersonHomePhone='2222222222';
        lstMemberAcc[0].PersonMobilePhone='2222222222';
        insert lstMemberAcc;
        objcs.AccountId=lstMemberAcc[0].id;
        objcs.Account = lstMemberAcc[0];
        objcs.Appointment_Requested__c=false;
        objcs.ACG_Year__c = '2015';
        List<WorkType> workTypes = [SELECT Id FROM WorkType LIMIT 1];
        objcs.ACG_Work_Type__c = workTypes[0].Id;
        objcs.Tow_Destination_Street__c = '111 Street St';
        insert objcs;

        INTFSLWorkOrderRequest_Wrapper requestJson = new INTFSLWorkOrderRequest_Wrapper();
        requestJson.vehicle = new INTFSLWorkOrderRequest_Wrapper.Vehicle();

        requestJson.vehicle.rvClass = 'CLASS';
        requestJson.vehicle.rvLength = 10.0;      
        requestJson.vehicle.trailerHitchType = 'HITCH';
        requestJson.vehicle.trailerLength = 10.0;          

        CallReceiveWorkOrderIntegration.CaseToJsonWrapper caseJson = new CallReceiveWorkOrderIntegration.CaseToJsonWrapper();
        caseJson.Wrap(objcs, '004', requestJson);
    }

    @isTest
    public static void TestPopulateServicePTAFromCase () {

        CallReceiveWorkOrderIntegration.CaseToJsonWrapper crwoi = new CallReceiveWorkOrderIntegration.CaseToJsonWrapper();
        FSL_JSonParserWorkOrder.Service service = new FSL_JSonParserWorkOrder.Service();
        Case caseObj = new Case();

        // _whereCaseHasDefinedScheduledDateTime_ResultIsServiceJSONHascorrectPtaString
        // Set up a datetime with the expected result. This is serialized 

        Test.startTest();
        caseObj.ACG_Requested_Appointment_Date__c = Date.today();
        caseObj.ACG_Requested_Appointment_Time__c = '11:30 PM';
        caseObj.Member_Location_TZ_Offset__c = 'UTC-7:00';
        Datetime dtResult = FSL_Case.getPTAFromCaseAppointmentAsOrgTime (caseObj);
        String dtSer = (String) JSON.serialize( dtResult );
        crwoi.populateServicePta ( service,  caseObj );

        // Check the dateTimeResult and the Case.PTA__c results
        System.assertNotEquals ( null, service.status.pta );
        //System.assertEquals ( dtSer, service.status.pta, 'mismatch serTime for pta. ' + dtSer + ' vs. ' + service.status.pta );
        //System.assertNotEquals ( null, caseObj.PTA__c );

        caseObj.ACG_Requested_Appointment_Date__c = null;
        caseObj.ACG_Requested_Appointment_Time__c = null;
        caseObj.Vehicle_Location_State__c = 'TX';
        caseObj.ACG_Service_Type__c = 'Flat Tire';
        crwoi.populateServicePta ( service,  caseObj );

        System.assertNotEquals ( null, service.status.pta );
        //System.assertEquals ( dtSer, service.status.pta, 'mismatch serTime for pta. ' + dtSer + ' vs. ' + service.status.pta );
        //System.assertNotEquals ( null, caseObj.PTA__c );

        Test.stopTest();
    }
       /***************EMI START***************/
  
	private static FSL_JSonParserWorkOrder createMockJsonWO(String callId) {
          
        FSL_JSonParserWorkOrder.Calls call = new FSL_JSonParserWorkOrder.Calls();
        FSL_JSonParserWorkOrder jsonWO = new FSL_JSonParserWorkOrder();
        jsonWO.calls = new List<FSL_JSonParserWorkOrder.Calls>();
        jsonWO.calls.add(new FSL_JSonParserWorkOrder.Calls());
        jsonWO.calls[0].callId = callId;
        return jsonWO;
    }

    @isTest
    static void testDefaultLogFields() {
        CallReceiveWorkOrderIntegration.CaseToWorkOrderLog log = new CallReceiveWorkOrderIntegration.CaseToWorkOrderLog();
        FSL_Application_Log__c logRecord = log.getApplicationLog();
        
        System.assertEquals('CallCreate', logRecord.Operation__c);
        System.assertEquals('Case To WorkOrder', logRecord.Api_Name__c);
        System.assertNotEquals(null, logRecord.DateTime__c);
    }
	
      @isTest
    static void testLogFailureWithNonNullJson() {
        CallReceiveWorkOrderIntegration.CaseToWorkOrderLog log = new CallReceiveWorkOrderIntegration.CaseToWorkOrderLog();
        FSL_JSonParserWorkOrder jsonWO = createMockJsonWO('12345');
        String message = 'Failure encountered during processing';

        log.logFailure(jsonWO, message, 'CallCreate', null);

        FSL_Application_Log__c logRecord = log.getApplicationLog();
        System.assertEquals(true, logRecord.Error_Caught__c);
        System.assertEquals(message, logRecord.Error_Message__c);
        System.assertEquals('12345', logRecord.Call_Id__c);
        System.assertNotEquals(null, logRecord.Request_Body__c);
    }

    @isTest
    static void testLogFailureWithNullJson() {
        CallReceiveWorkOrderIntegration.CaseToWorkOrderLog log = new CallReceiveWorkOrderIntegration.CaseToWorkOrderLog();
        String message = 'Failure encountered, no JSON data';

        log.logFailure(null, message, 'CallCreate', '{"sample":"data"}');

        FSL_Application_Log__c logRecord = log.getApplicationLog();
        System.assertEquals(true, logRecord.Error_Caught__c);
        System.assertEquals(message, logRecord.Error_Message__c);
        System.assertEquals('{"sample":"data"}', logRecord.Request_Body__c);
    }

   	@isTest
    static void testsetDefaultApplicationLogFields() {
        CallReceiveWorkOrderIntegration crWorkOrderIntegration = new CallReceiveWorkOrderIntegration();
        CallReceiveWorkOrderIntegration.CaseToWorkOrderLog log = new CallReceiveWorkOrderIntegration.CaseToWorkOrderLog();
		Test.startTest();
		log.setDefaultApplicationLogFields('','');
		Test.stopTest();
	}

     static testMethod void testRVVehicles() {
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'RV');
        Set<String> validRVVehiclesSet = new Set<String>{'RV'};
        Set<String> validMotorVehicleSet = new Set<String>{};
        Set<String> validRVMVVehicleSet = new Set<String>{};

        String result = CallReceiveWorkOrderIntegration.obtainAccidentFirstWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
        String result1 = CallReceiveWorkOrderIntegration.obtainAccidentSecondWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
        String result2 = CallReceiveWorkOrderIntegration.obtainAccidentContinuationWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
      }

    static testMethod void testMotorVehicles() {
  
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'MotorVehicle');
        Set<String> validRVVehiclesSet = new Set<String>{};
        Set<String> validMotorVehicleSet = new Set<String>{'MotorVehicle'};
        Set<String> validRVMVVehicleSet = new Set<String>{};

        String result = CallReceiveWorkOrderIntegration.obtainAccidentFirstWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
	    String result1 = CallReceiveWorkOrderIntegration.obtainAccidentSecondWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
       String result2 = CallReceiveWorkOrderIntegration.obtainAccidentContinuationWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
        
	 }

    static testMethod void testOtherVehicles() {
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'OtherVehicle');
        Set<String> validRVVehiclesSet = new Set<String>{};
        Set<String> validMotorVehicleSet = new Set<String>{};
        Set<String> validRVMVVehicleSet = new Set<String>{'RV', 'MotorVehicle'};

        String result = CallReceiveWorkOrderIntegration.obtainAccidentFirstWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
	 	String result1 = CallReceiveWorkOrderIntegration.obtainAccidentSecondWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
        String result2 = CallReceiveWorkOrderIntegration.obtainAccidentContinuationWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
      }

    static testMethod void testEmptySets() {
      
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'UnknownVehicle');
        Set<String> validRVVehiclesSet = new Set<String>{};
        Set<String> validMotorVehicleSet = new Set<String>{};
        Set<String> validRVMVVehicleSet = new Set<String>{};
	    String result = CallReceiveWorkOrderIntegration.obtainAccidentFirstWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
		String result1 = CallReceiveWorkOrderIntegration.obtainAccidentSecondWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
        String result2 = CallReceiveWorkOrderIntegration.obtainAccidentContinuationWorkType(wo, validRVVehiclesSet, validMotorVehicleSet, validRVMVVehicleSet);
    }
  	
     @IsTest
    static void testLongTowWithFlatbed() {
        WorkOrder wo = new WorkOrder(
           // Total_Mileage__c = Integer.valueOf(System.Label.FSL_LongTow_Mileage) + 10,
            Flatbed_Requested__c = true
        );
    	 String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(	
            wo, new Set<String>{}, new Set<String>{}, new Set<String>{}, new Set<String>{}
        );

    }

    @IsTest
    static void testLongTowWithoutFlatbed() {
        WorkOrder wo = new WorkOrder(
           // Total_Mileage__c = Integer.valueOf(System.Label.FSL_LongTow_Mileage) + 10,
            Flatbed_Requested__c = false,
            Needs_Flatbed__c = false
        );

        String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{}, new Set<String>{}, new Set<String>{}, new Set<String>{}
        );

     }

    @IsTest
    static void testMotorcycleTow() {
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'Motorcycle');

        String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{}, new Set<String>{}, new Set<String>{'Motorcycle'}, new Set<String>{}
        );

       }

    @IsTest
    static void testRVVehiclesTow() {
     	WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'RV');

	    String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{'RV'}, new Set<String>{}, new Set<String>{}, new Set<String>{}
        );
	
    }

    @IsTest
    static void testFlatbedTowRequested() {
        WorkOrder wo = new WorkOrder(
            Flatbed_Requested__c = true
        );
    
        String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{}, new Set<String>{}, new Set<String>{}, new Set<String>{}
        );
	  }

    @IsTest
    static void testLowClearanceTow() {
        WorkOrder wo = new WorkOrder(Location_Code__c = 'LowClearanceArea');
	    String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{}, new Set<String>{'LowClearanceArea'}, new Set<String>{}, new Set<String>{}
        );
	 }

    @IsTest
    static void testPassengerCarTow() {
        WorkOrder wo = new WorkOrder(Vehicle_Type__c = 'PassengerCar');

        String result = CallReceiveWorkOrderIntegration.obtainTowWorkType(
            wo, new Set<String>{}, new Set<String>{}, new Set<String>{}, new Set<String>{'RV', 'Motorcycle'}
        );

    }
    
    @isTest
    static void testValidateWorkOrder() {
        FSL_Required_Fields_Validation__c obj = new FSL_Required_Fields_Validation__c(
            Name = 'TestObject',
            Fields__c = 'External_Id__c,Status'
        );
        insert obj;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            External_Id__c = '123',
            Status = 'Open'
        );
        insert wo;
        
        Test.startTest();
        CallReceiveWorkOrderIntegration.validateWorkOrder('FSL_Required_Fields_Validation__c', wo);
        Test.stopTest();
   
    }
    
    @isTest
    static void testValidateWorkOrderMissingFields() {
	    FSL_Required_Fields_Validation__c obj = new FSL_Required_Fields_Validation__c(
            Name = 'TestObject',
            Fields__c = 'External_Id__c,Status'
        );
        insert obj;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'Open'
        );
        insert wo;
        Test.startTest();
        CallReceiveWorkOrderIntegration.validateWorkOrder('FSL_Required_Fields_Validation__c', wo);
        Test.stopTest();
  
    }
   
    @isTest
    static void testPopulateWorkOrderPriority() {
        FSL_PriorityCode_Mapping__c  code = new FSL_PriorityCode_Mapping__c (
            Name = 'TestCode',
            WorkOrder_Priority__c = 'High',
            Priority_Description__c = 'High Priority'
        );
        insert code;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Legacy_Priority_Code__c = 'L2'
        );
        Test.startTest();
        CallReceiveWorkOrderIntegration.populateWorkOrderPriority(wo, 'High', 'L2');
        Test.stopTest();
     }
    
    @isTest
    static void testPopulateWorkOrderPriorityNoMatch() {
         WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Legacy_Priority_Code__c = 'NonExistentCode'
        );
        
        Test.startTest();
        CallReceiveWorkOrderIntegration.populateWorkOrderPriority(wo, 'Medium', 'NonExistentCode');
        Test.stopTest();
        
      }   
    /************EMI END******************/
}