@isTest
 public class FSL_ClearJsonWorkOrderTest {
    static testMethod void valuesTest(){
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = new FSL_ClearJsonWorkOrder();
        
        FSL_ClearJsonWorkOrder.SystemOrganization systemOrg = new FSL_ClearJsonWorkOrder.SystemOrganization();
        systemOrg.code = 'Test Code';
        systemOrg.name = 'Test Name';
         
        FSL_ClearJsonWorkOrder.SourceSystem sourceSystem = new FSL_ClearJsonWorkOrder.SourceSystem();
        sourceSystem.systemId = 'Test System Id';
        sourceSystem.systemOrganization = systemOrg;
        
        FSL_ClearJsonWorkOrder.Channel_Contact channelContact = new FSL_ClearJsonWorkOrder.Channel_Contact();
		channelContact.userId  = 'Test user Id'; 
        channelContact.contactType  = 'Test Contact Type'; 
        
        FSL_ClearJsonWorkOrder.Location_Address locationAddress = new FSL_ClearJsonWorkOrder.Location_Address();
        locationAddress.AddressType = 'Home locationAddress';
        locationAddress.city = 'City';
        locationAddress.country = 'Country';
        locationAddress.county = 'County';
        locationAddress.crossStreet = 'Cross Street';
        locationAddress.full = '';
        locationAddress.postalCode = '12345';
        locationAddress.state = 'State';
        locationAddress.streetDirection = '';
        locationAddress.streetName = 'Street Name';
        locationAddress.streetNumber = '1234B';
        
        FSL_ClearJsonWorkOrder.Channel_Location channelLocation = new FSL_ClearJsonWorkOrder.Channel_Location();
        channelLocation.latitude  = 10.09; 
        channelLocation.longitude  = 10.98; 
        channelLocation.address  = locationAddress;
        
        
        FSL_ClearJsonWorkOrder.Channel channel = new FSL_ClearJsonWorkOrder.Channel();
        channel.channelType  = 'Test Channel Type'; 
        channel.org  = systemOrg; 
        channel.contact  = channelContact; 
        channel.location  = channelLocation;
        
        FSL_ClearJsonWorkOrder.Entitlements entitlements = new FSL_ClearJsonWorkOrder.Entitlements();
        entitlements.serviceChargeIndicator = true;
        
        FSL_ClearJsonWorkOrder.Memberships membership = new FSL_ClearJsonWorkOrder.Memberships();
        membership.authorizationCode = '010';
        membership.authorizationLevel = 'Test Level';
        membership.entitlements = new List<FSL_ClearJsonWorkOrder.Entitlements>{entitlements};
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
        
        FSL_ClearJsonWorkOrder.Customer_Email customerEmail = new FSL_ClearJsonWorkOrder.Customer_Email();
        customerEmail.address = 'Test@test.com';
        customerEmail.emailType = 'Personal';
        
        FSL_ClearJsonWorkOrder.Customer_Phone customerPhone = new FSL_ClearJsonWorkOrder.Customer_Phone();
        customerPhone.phoneExtension = '+091';
        customerPhone.phoneNumber = '99999999999';
        customerPhone.phoneType = 'Home';
        customerPhone.preferred = true;
        customerPhone.smsOptIn = true;
        
        FSL_ClearJsonWorkOrder.Customer_Contact customerContact = new FSL_ClearJsonWorkOrder.Customer_Contact();
        customerContact.contactType = 'Test Contact Type';
        customerContact.firstName = 'First Name';
        customerContact.lastName = 'Last Name';
        customerContact.title = 'Title';
        customerContact.phones = new List<FSL_ClearJsonWorkOrder.Customer_Phone>{customerPhone};
        customerContact.emails = new List<FSL_ClearJsonWorkOrder.Customer_Email>{customerEmail};
        
        FSL_ClearJsonWorkOrder.Customer customer = new FSL_ClearJsonWorkOrder.Customer();
        customer.memberships  = new List<FSL_ClearJsonWorkOrder.Memberships>{membership}; 
        customer.contact  = customerContact; 
        customer.languagePreference  = 'Test Lang pref';
        
        FSL_ClearJsonWorkOrder.UpdatedBy updatedBy = new FSL_ClearJsonWorkOrder.UpdatedBy('Test Contact type');
        
		FSL_ClearJsonWorkOrder.Location_Z location = new FSL_ClearJsonWorkOrder.Location_Z();        
        
        FSL_ClearJsonWorkOrder.Facility facility = new FSL_ClearJsonWorkOrder.Facility();
        facility.foiType = 'Test Foi';
        facility.id = 'Test Id';
        facility.location = location;
        facility.name = 'Test Name';
        
        FSL_ClearJsonWorkOrder.Driver_Contact driverContact = new FSL_ClearJsonWorkOrder.Driver_Contact();
        driverContact.contactType = 'Test Contact type';
        driverContact.lastName = 'Test Last Name';
        
        FSL_ClearJsonWorkOrder.Driver driver = new FSL_ClearJsonWorkOrder.Driver();
        driver.contact = driverContact;
        driver.id = 'Test Id';
        
		FSL_ClearJsonWorkOrder.Truck truck = new FSL_ClearJsonWorkOrder.Truck();
        truck.driver = driver;
        truck.id = 'Test Id';

        new FSL_ClearJsonWorkOrder.StatusDetail();
        FSL_ClearJsonWorkOrder.StatusDetail statusDetail = new FSL_ClearJsonWorkOrder.StatusDetail ('Status', 'reasonCode', updatedBy, facility, truck, System.now(), 'Version1');
        
        new FSL_ClearJsonWorkOrder.CallEvent();
        FSL_ClearJsonWorkOrder.CallEvent callEvent = new FSL_ClearJsonWorkOrder.CallEvent('Test Call Key', '10102019', 'Test Call Id', System.now());
        callEvent.statusDetail = statusDetail;
        
        FSL_ClearJsonWorkOrder.RvInfo rvInfo = new FSL_ClearJsonWorkOrder.RvInfo();
        rvInfo.engineLocation = 'Test engine location';
        rvInfo.gooseNeck = true;
        rvInfo.height = 10.00;
        rvInfo.length = 10.00;
        rvInfo.rvClass = 'Test rvClass';
        rvInfo.towing = true;
        rvInfo.towingType = 'Test Towing Type';
        rvInfo.weight = 10;
        
        FSL_ClearJsonWorkOrder.TrailerInfo trailerInfo = new FSL_ClearJsonWorkOrder.TrailerInfo();
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
            
        FSL_ClearJsonWorkOrder.Vehicle vehicle = new FSL_ClearJsonWorkOrder.Vehicle();
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
        
        FSL_ClearJsonWorkOrder.Policies policy = new FSL_ClearJsonWorkOrder.Policies();
        policy.code = 'Test Code';
        policy.description = 'Test Description';
        
        FSL_ClearJsonWorkOrder.Payment payment = new FSL_ClearJsonWorkOrder.Payment();
        payment.codes = 'Test Codes';
        payment.paymentType = 'Test Payment Type';
        payment.required = true;
        
        FSL_ClearJsonWorkOrder.TroubleCodes troubleCode = new FSL_ClearJsonWorkOrder.TroubleCodes();
        troubleCode.code = 'T129';
        troubleCode.description = 'Test trouble code description';
        troubleCode.troubleCodeType = 'Test Code Type';
        
        FSL_ClearJsonWorkOrder.Status status = new FSL_ClearJsonWorkOrder.Status();
        status.eta = '5678906';
        status.modifiedDate = '10/10/2019';
        status.pta = '98876543';
        status.status = 'Test Status';
        status.waitTime = 1875;
        
        FSL_ClearJsonWorkOrder.Charge charge = new FSL_ClearJsonWorkOrder.Charge();
        charge.amount = '12000';
        charge.chargeType = 'Fees';
                      
        FSL_ClearJsonWorkOrder.Contact_Phones contactPhones = new FSL_ClearJsonWorkOrder.Contact_Phones();
        contactPhones.phoneNumber = '9999999999';
        contactPhones.phoneType = 'Work';
        contactPhones.preferred = true;
        
        FSL_ClearJsonWorkOrder.Contacts contacts = new FSL_ClearJsonWorkOrder.Contacts();
        contacts.contactType = 'Test Contact Type';
        contacts.firstName = 'Test First Name';
        contacts.lastName = 'Test Last Name';
        contacts.phones = new List<FSL_ClearJsonWorkOrder.Contact_Phones>{contactPhones};    
        
        FSL_ClearJsonWorkOrder.BreakdownAddress breakdownAddress = new FSL_ClearJsonWorkOrder.BreakdownAddress();
        breakdownAddress.AddressType = 'Home locationAddress';
        breakdownAddress.city = 'City';
        breakdownAddress.country = 'Country';
        breakdownAddress.county = 'County';
        breakdownAddress.crossStreet = 'Cross Street';
        breakdownAddress.crossStreet2 = 'Test Street 2';
        breakdownAddress.full = '';
        breakdownAddress.postalCode = '12345';
        breakdownAddress.state = 'State';
        breakdownAddress.streetDirection = '';
        breakdownAddress.streetName = 'Street Name';
        breakdownAddress.streetNumber = '1234B';    
            
        FSL_ClearJsonWorkOrder.Breakdown_Location breakdownLocation = new FSL_ClearJsonWorkOrder.Breakdown_Location(); 
        breakdownLocation.address = breakdownAddress;
		breakdownLocation.grid = 'Grid';
        breakdownLocation.highway = 'Highway';    
        breakdownLocation.landmark = 'Landmark';
        breakdownLocation.latitude = 109.98;
        breakdownLocation.locationCode = '10';
        breakdownLocation.longitude = 109.98;
        breakdownLocation.mileMarker = 'test Mile Marker';
        breakdownLocation.zone = 'GMT';
        
        FSL_ClearJsonWorkOrder.Foi foi = new FSL_ClearJsonWorkOrder.Foi();
        foi.foiType = 'Test Foi Types';
        foi.location = breakdownLocation;
        foi.name = 'Test Name';
        foi.contacts = new List<FSL_ClearJsonWorkOrder.Contacts>{contacts};
        
        FSL_ClearJsonWorkOrder.ServiceLocations serviceLocation = new FSL_ClearJsonWorkOrder.ServiceLocations();
		serviceLocation.driverDirections = 'Test direction';
        serviceLocation.dropBoxInfo = 'Test Info';
        serviceLocation.serviceLocationType = 'Type';
        serviceLocation.mileageCalculated = 1019;
        serviceLocation.foi = foi;
        
        FSL_ClearJsonWorkOrder.ProvidedServices providedService = new FSL_ClearJsonWorkOrder.ProvidedServices(); 
        providedService.charge = charge;
        providedService.providedServiceType = 'Test Service Type';
        providedService.quantity = 10;
        providedService.service = 'Test Service';
        providedService.unit = 'Test unit';
        
        FSL_ClearJsonWorkOrder.Service service = new FSL_ClearJsonWorkOrder.Service();
        service.appointmentTime = 'Test Time';
        service.callType = 'Test Call Type';
        service.collision = true;
        service.flatbedRequested = true;
        service.legacyPriorityCode = 'Test Legacy Priority Code';
        service.needsFlatbed = true;
        service.numberOfPassengers = 10;
        service.policies = new List<FSL_ClearJsonWorkOrder.Policies>{policy}; 
        service.priorityCode = 'Test Priority Code';
        service.redFlag = true;
        service.timezoneId = 'Test Time Zone Id';
        service.timezoneOffset = 'Test Time Zone Offset';
        service.status = status;
        service.TroubleCodes = new List<FSL_ClearJsonWorkOrder.TroubleCodes>{troubleCode};
        service.serviceLocations = new List<FSL_ClearJsonWorkOrder.ServiceLocations>{serviceLocation};
        service.providedServices = new List<FSL_ClearJsonWorkOrder.ProvidedServices>{providedService};    
        service.facility = facility;
        service.charges = new List<FSL_ClearJsonWorkOrder.Charge>{charge};
        service.truck = truck;    
        
        FSL_ClearJsonWorkOrder.Comments_Contact commentContact = new FSL_ClearJsonWorkOrder.Comments_Contact();        
        commentContact.userId = 'USER ID';
        commentContact.contactType = 'Test Contact Type';
        
        FSL_ClearJsonWorkOrder.Comments comment = new FSL_ClearJsonWorkOrder.Comments();
        comment.commentType = 'Test Comment Type';
        comment.contact = commentContact;
        comment.system_Z = sourceSystem;
        comment.text = 'Test Text';
        comment.visibility = 'Public';
        comment.commentDate = '10102019';
        
        FSL_ClearJsonWorkOrder.Calls call  = new FSL_ClearJsonWorkOrder.Calls();
        call.callKey = 'Test Key'; 
        call.callDate = '10102019'; 
        call.callId = 'Test Id'; 
        call.version = 'Test Version 1'; 
        call.channel = channel; 
        call.customer = customer; 
        call.vehicle = vehicle; 
        call.service = service; 
        call.payment = payment; 
        call.comments = new List<FSL_ClearJsonWorkOrder.Comments>{comment}; 
        System.assertEquals(call.callKey, 'Test Key', 'Inserted');
            
        clearJsonWorkOrder.id = 'Test Id'; 
        clearJsonWorkOrder.requestEventType  = 'Test Event Type'; 
        clearJsonWorkOrder.subType = 'Test Sub Type'; 
        clearJsonWorkOrder.status  = 'Test Status'; 
        clearJsonWorkOrder.version  = 'Test version'; 
        clearJsonWorkOrder.sourceSystem  = sourceSystem; 
        clearJsonWorkOrder.targetSystem  = sourceSystem; 
        clearJsonWorkOrder.createDate  = 10102019; 
        clearJsonWorkOrder.calls  =  new List<FSL_ClearJsonWorkOrder.Calls>{call};
        clearJsonWorkOrder.callEvents  = new List<FSL_ClearJsonWorkOrder.CallEvent>{callEvent} ;    
                
        FSL_ClearJsonWorkOrder.ResponseWrapper resposneWrapper = new FSL_ClearJsonWorkOrder.ResponseWrapper();
        resposneWrapper.id  = 'Test Id';
        resposneWrapper.statusDescription  = 'Test Status Description';
        resposneWrapper.statusCode  = 10;        
        clearJsonWorkOrder.respWrap = resposneWrapper;
        
        FSL_ClearJsonWorkOrder.TowDest_Location locTowDest = new FSL_ClearJsonWorkOrder.TowDest_Location();
        FSL_ClearJsonWorkOrder.TowAddress addTowAdd = new FSL_ClearJsonWorkOrder.TowAddress();
        FSL_ClearJsonWorkOrder.Foi_TowDest foiTowDest = new FSL_ClearJsonWorkOrder.Foi_TowDest();
        
        addTowAdd.addressType = 'Test Address type';
        addTowAdd.city = 'Test City';
        addTowAdd.country = 'Country';
        addTowAdd.county = 'County';
        addTowAdd.crossStreet = 'Cross Street';
        addTowAdd.full = '';
        addTowAdd.postalCode = '12345';
        addTowAdd.state = 'State';
        addTowAdd.streetName = 'Street Name';
        addTowAdd.streetNumber = '1234B';
        system.assertEquals(addTowAdd.postalCode, '12345');
        
        locTowDest.address = addTowAdd;
        locTowDest.landmark = 'Test Landmark';
        locTowDest.latitude = 109.98;
        locTowDest.longitude = 198.09;
        system.assertEquals(locTowDest.landmark, 'Test Landmark');
        
        foiTowDest.location = locTowDest;
        foiTowDest.name = 'Test Name';
        foiTowDest.contacts = new List<FSL_ClearJsonWorkOrder.Contacts>{contacts};
        System.assertEquals(foiTowDest.name, 'Test Name') ; 
    }

}