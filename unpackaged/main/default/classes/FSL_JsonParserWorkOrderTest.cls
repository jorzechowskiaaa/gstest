/**
 * @File Name          : FSL_JsonParserWorkOrderTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 09/30/2020
 * @Modification Log   : 
 * Ver       Date            Author              Modification
 * 1.0    5/13/2020   Rajesh Kemisetti     Initial Version
 *	  09/30/2020  Dylan Truong	   ERS-219581 FSL Timeout adding woLookup into test case;
**/

@isTest
public class FSL_JsonParserWorkOrderTest {
    static testMethod void jsonParserWOTest(){
        FSL_JSonParserWorkOrder jsonParserWO = new FSL_JSonParserWorkOrder();
        
        jsonParserWO.id = 'Test Id';
        jsonParserWO.requestEventType = 'Test requestEventType';
    	jsonParserWO.subType = 'Test subType'; 
    	jsonParserWO.status = 'Test status'; 
    	jsonParserWO.version = 'Test version';
    	jsonParserWO.createDate = 'Test createDate';
        jsonParserWO.towRequestReason = 'TowRequestReason';//EMI
        jsonParserWO.towRequestMiscellaneousDetails = 'TowRequestMiscellaneousDetails';//EMI
 
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
        address.country = 'Country';
        address.county = 'County';
        address.crossStreet = 'Cross Street';
        address.crossStreet2 = 'Cross Street1';
        address.full = '';
        address.postalCode = '12345';
        address.state = 'State';
        address.street = 'Street';
        address.streetDirection = '';
        address.streetName = 'Street Name';
        address.streetNumber = '1234B';
        
        location.address = address;
        location.latitude = 09.09;
        location.longitude = 10.09;
        
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
        membership.authorizationLevel = 'Test Level';
        membership.entitlements = new List<FSL_JSonParserWorkOrder.Entitlements>{entitlements};
        membership.expirationDate = '10/10/2019';  
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
        
        customer.memberships = new List<FSL_JSonParserWorkOrder.Memberships>{membership};
        customer.languagePreference = 'English';
        customer.contact = custContact;
            
        FSL_JSonParserWorkOrder.Vehicle vehicle = new FSL_JSonParserWorkOrder.Vehicle();
        FSL_JSonParserWorkOrder.TrailerInfo trailerInfo = new FSL_JSonParserWorkOrder.TrailerInfo();
        FSL_JSonParserWorkOrder.RvInfo rvInfo = new FSL_JSonParserWorkOrder.RvInfo();
        rvInfo.engineLocation = 'Test engine location';
        rvInfo.gooseNeck = true;
        rvInfo.height = 10.00;
        rvInfo.length = 10.00;
        rvInfo.rvClass = 'Test rvClass';
        rvInfo.towing = true;
        rvInfo.towingType = 'Test Towing Type';
        rvInfo.weight = '10';
        
        trailerInfo.axles = 1;
        trailerInfo.condition = 'Test Condition';
        trailerInfo.gooseNeck = true;
        trailerInfo.hitchSize = 10.00;
        trailerInfo.hitchType = 'Test Hitch type';
        trailerInfo.length = 10.00;
        trailerInfo.loaded = 'Test loaded';
        trailerInfo.loadType = 'Test Load Type';
        trailerInfo.loadWeight = 'Test Load Weight';
        trailerInfo.plugType = 'Test Plug type';
        trailerInfo.trailerType = 'Test Trailor Type';
        
        vehicle.color = 'Red';
        vehicle.driveType = 'Regular';
        vehicle.fuelType = 'Petrol';
        vehicle.make = 'Test Make';
        vehicle.model = 'Test Model';
        vehicle.odometer = 10;
        vehicle.specialEquipmentNeeds = 'Test Needs';
        vehicle.state = 'Test State';
        vehicle.tag = 'Test Tag';
        vehicle.trim = 'Test Trim';
        vehicle.vehicleType = 'Test Vehicle Type';
        vehicle.vin = '12POUBVXRR142865';
        vehicle.year = 2015;
        vehicle.trailerInfo = trailerInfo;
        vehicle.rvInfo = rvInfo;
        
        FSL_JSonParserWorkOrder.Service service = new FSL_JSonParserWorkOrder.Service();
        FSL_JSonParserWorkOrder.Facility facility = new FSL_JSonParserWorkOrder.Facility();
        FSL_JSonParserWorkOrder.Policies policy = new FSL_JSonParserWorkOrder.Policies();
        FSL_JSonParserWorkOrder.ServiceLocations serviceLocation = new FSL_JSonParserWorkOrder.ServiceLocations();
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
        add_TowAdd.country = 'Country';
        add_TowAdd.county = 'County';
        add_TowAdd.crossStreet = 'Cross Street';
        add_TowAdd.full = '';
        add_TowAdd.postalCode = '12345';
        add_TowAdd.state = 'State';
        add_TowAdd.streetName = 'Street Name';
        add_TowAdd.streetNumber = '1234B';
        
        loc_towDest.address = add_TowAdd;
        loc_towDest.landmark = 'Test Landmark';
        loc_towDest.latitude = 109.98;
        loc_towDest.longitude = 198.09;
        
        foi_TowDest.location = loc_towDest;
        foi_TowDest.name = 'Test Name';
        
        serviceLocationLocation.address = address;
        serviceLocationLocation.grid = 'Test Grid';
        serviceLocationLocation.highway = 'Test Highway';
        serviceLocationLocation.landmark = 'Test Landmark';
        serviceLocationLocation.latitude = 10.987;
        serviceLocationLocation.locationCode = 'Test Code';
        serviceLocationLocation.longitude = 196.97;
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
        serviceLocation.foi_towDest = foi_TowDest;
        serviceLocation.mileageCalculated = 12;
        serviceLocation.milesFromOrigin = 19;
        serviceLocation.serviceLocationType = 'Test Service Location Type';
        
        facility.foiType = 'Test foiType';
        facility.id = 'Test Id';
        facility.name = 'Test Name';
        
        troubleCode.code = 'Test Code';
        troubleCode.description = 'Test description';
        troubleCode.troubleCodeType = 'Test Trouble Code type';
        
        status.eta = '5678906';
        status.modifiedDate = '10/10/2019';
        status.pta = '98876543';
        status.status = 'Test Status';
        status.waitTime = 1875;
        
        policy.code = 'Test Code';
        policy.description = 'Test Description';
        
        service.apdSeqId = 'Test apdSeqId';
        service.appointmentTime = 'Test Time';
        service.callType = 'Test Call Type';
        service.collision = true;
        service.flatbedRequested = true;
        service.legacyPriorityCode = 'Test Legacy Priority Code';
        service.needsFlatbed = true;
        service.numberOfPassengers = 10;
        service.policies = new List<FSL_JSonParserWorkOrder.Policies>{policy}; 
        service.priorityCode = 'Test Priority Code';
        service.redFlag = true;
        service.timezoneId = 'Test Time Zone Id';
        service.timezoneOffset = 'Test Time Zone Offset';
        service.status = status;
        service.TroubleCodes = new List<FSL_JSonParserWorkOrder.TroubleCodes>{};
        service.serviceLocations = new List<FSL_JSonParserWorkOrder.ServiceLocations>{serviceLocation};
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


         // Added by Varun        
        System.Debug(jsonParserWO.caseId);
        System.Debug(jsonParserWO.id);
        System.Debug(jsonParserWO.requestEventType);
        System.Debug(jsonParserWO.subType);
        System.Debug(jsonParserWO.status);
        System.Debug(jsonParserWO.version);
        System.Debug(jsonParserWO.createDate);
        System.Debug(call.requestingSystemCallId);

        vehicle.keycodes = new FSL_JSonParserWorkOrder.Keycodes(); 

        vehicle.keycodes.mmpv = 'mmpv';
        vehicle.keycodes.door = 'door';
        vehicle.keycodes.ignition ='ignition';
        vehicle.keycodes.vats  ='vats';

        System.Debug(vehicle.keycodes.mmpv);
        System.Debug(vehicle.keycodes.door);
        System.Debug(vehicle.keycodes.ignition);
        System.Debug(vehicle.keycodes.vats);


        service.duty = 'Duty';
        service.memberPhone = '1321232';
        System.Debug(service.duty);
        System.Debug(service.memberPhone);

        payment.responsible = 'responsible';
        system.debug(payment.responsible);

        membership.goodwill = 'New Value';
        membership.programName = 'New Value';
        membership.programPhone = 'New Value';
        membership.programMaxMileage = 'New Value';
        system.debug(membership.goodwill);
        system.debug(membership.programName);
        system.debug(membership.programPhone);
        system.debug(membership.programMaxMileage);


        policy.code = 'New Value';
        policy.description = 'New Value';
        system.debug(policy.code );
        system.debug(policy.description);

    
        foi.foiType = 'New Value';
        system.debug(foi.foiType);

        serviceLocation.foiType= 'New Value';
        system.debug(serviceLocation.foiType);

        facility.preferenceType= 'New Value';
        system.debug(facility.preferenceType);
        


    }

}