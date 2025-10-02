public class FSL_WorkOrderD3JsonWrapper {
    
    private Map<String, FSL_ServiceSettings__c> serviceSettings = FSL_ServiceSettings__c.getAll();

    private WorkOrder workOrder;
    private Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap;
    private Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap;
    private String serviceName;
    public static String DEFAULT_USER_ID = 'S999999';

    public FSL_WorkOrderD3JsonWrapper() {
    }

    public List<FSL_ClearJsonWorkOrder> Wrap( List<WorkOrder> workOrders, Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap, Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap, String serviceName) {
        List<FSL_ClearJsonWorkOrder> jsonWorkOrders = new List<FSL_ClearJsonWorkOrder>();
        this.serviceAppointmentIdToAssignedResourceMap = serviceAppointmentIdToAssignedResourceMap;
        this.workOrderIdToFeedItemsMap = workOrderIdToFeedItemsMap;
        this.serviceName = serviceName;

        for( WorkOrder workOrder : workOrders ) {
            jsonWorkOrders.add( Wrap( workOrder, null) );
        }
        
        return jsonWorkOrders;
    }

    public FSL_ClearJsonWorkOrder Wrap( WorkOrder workOrder, Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap, Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap, String serviceName) {
        this.serviceAppointmentIdToAssignedResourceMap = serviceAppointmentIdToAssignedResourceMap;
        this.workOrderIdToFeedItemsMap = workOrderIdToFeedItemsMap;
        this.serviceName = serviceName;

        return Wrap( workOrder, null );
    }

    public FSL_ClearJsonWorkOrder Wrap( WorkOrder workOrder, Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap, Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap, String serviceName,  Map<String, String> zipCodeToClubCode) {
        this.serviceAppointmentIdToAssignedResourceMap = serviceAppointmentIdToAssignedResourceMap;
        this.workOrderIdToFeedItemsMap = workOrderIdToFeedItemsMap;
        this.serviceName = serviceName;

        return Wrap( workOrder, zipCodeToClubCode );
    }

    private FSL_ClearJsonWorkOrder Wrap( WorkOrder workOrder, Map<String, String> zipCodeToClubCode ) {
        FSL_ClearJsonWorkOrder jsonWorkOrder = new FSL_ClearJsonWorkOrder();

        this.workOrder = workOrder;

        if(workOrder.Call_Source__c == 'Salesforce'){
            jsonWorkOrder.id = workOrder.Id;
        }else{
            jsonWorkOrder.id = GenerateGUID();
        }
        // jsonWorkOrder.memberId
        // jsonWorkOrder.ANI
        jsonWorkOrder.requestEventType = serviceSettings.get('Clear').RequestEventType__c;
        jsonWorkOrder.subType = serviceSettings.get('Clear').RequestSubtype__c;
        jsonWorkOrder.status = serviceSettings.get('Clear').Status__c;
        jsonWorkOrder.version = String.valueOf(serviceSettings.get('Clear').version__c);
        jsonWorkOrder.sourceSystem = PopulateSourceSystem();
        jsonWorkOrder.targetSystem = PopulateTargetSystem();
        jsonWorkOrder.createDate = workOrder.CreatedDate.getTime();
        jsonWorkOrder.calls = PopulateCalls( jsonWorkOrder.sourceSystem, zipCodeToClubCode );
        // jsonWorkOrder.respWrap
        jsonWorkOrder.callEvents = PopulateCallEvents( jsonWorkOrder.calls[0].service.facility, jsonWorkOrder.calls[0].service.truck, zipCodeToClubCode);
        // jsonWorkOrder.header
        // jsonWorkOrder.statusDescription
        // jsonWorkOrder.statusCode

        return jsonWorkOrder;
    }

    private String GenerateGUID () {
        Blob b = Crypto.GenerateAESKey( 256 );
        String h = EncodingUtil.ConvertTohex( b );
        String guid = h.SubString( 0, 8 )+ '-' + h.SubString( 8, 12 ) + '-' + h.SubString( 12, 16 ) + '-' + h.SubString( 16, 20 ) + '-' + h.substring( 20, 32 );
        return guid;
    }

    private FSL_ClearJsonWorkOrder.SourceSystem PopulateSourceSystem() {
        FSL_ClearJsonWorkOrder.SystemOrganization source = new FSL_ClearJsonWorkOrder.SystemOrganization();
        source.name = serviceSettings.get('Clear').Source_System_Org_Name__c;
        source.code = serviceSettings.get('Clear').Source_System_Org_Code__c;

        FSL_ClearJsonWorkOrder.SourceSystem sourceSystem = new FSL_ClearJsonWorkOrder.SourceSystem();
        sourceSystem.systemId = serviceSettings.get('Clear').Source_System_ID__c;
        sourceSystem.systemOrganization = source;
        
        return sourceSystem;
    }

    private FSL_ClearJsonWorkOrder.SourceSystem PopulateTargetSystem() {
        FSL_ClearJsonWorkOrder.SystemOrganization target = new FSL_ClearJsonWorkOrder.SystemOrganization();
        target.name = workOrder.Call_Origin_OrgName__c;
        target.code = workOrder.Call_Origin_OrgCode__c;
        
        FSL_ClearJsonWorkOrder.SourceSystem targetSystem = new FSL_ClearJsonWorkOrder.SourceSystem();
        targetSystem.systemId = '';
        targetSystem.systemOrganization = target;
        
        return targetSystem;
    }

    @TestVisible
    private String constructCallKey(String clubCode, String dateStr, String callId) {
        String dstr = dateStr;
        if ( dateStr != null ) {
            dstr  = dateStr.remove('-');
        }
        String callKey = clubCode + '-' + dstr + '-' + callId;
        return callKey;
    }

    private List<FSL_ClearJsonWorkOrder.Calls> PopulateCalls( FSL_ClearJsonWorkOrder.SourceSystem sourceSystem, Map<String, String> zipCodeToClubCode ) {
        List<FSL_ClearJsonWorkOrder.Calls> calls = new List<FSL_ClearJsonWorkOrder.Calls>();

        FSL_ClearJsonWorkOrder.Calls call = new FSL_ClearJsonWorkOrder.Calls();
        //call.callKey = workOrder.External_ID__c;
        call.callDate = workOrder.Call_Date__c;
        //call.callId = workOrder.Call_Id__c;

       /* Datetime createdDate = workOrder.CreatedDate;
        String month = String.valueOf(CreatedDate.month()).leftPad(2,'0');
        String day =  String.valueOf(CreatedDate.day()).leftPad(2,'0');
        string sdate = CreatedDate.year() + month  + day;*/
        string callid = workOrder.call_Id__c;
        //string clubCode = '555';

        if(String.iSBlank(workOrder.External_ID__c)) {
            String sClubcode = '004';
            
            if(zipCodeToClubCode != null && zipCodeToClubCode.containsKey(workOrder.PostalCode)){
                sClubcode = zipCodeToClubCode.get(workOrder.postalCode);
            }
            call.callKey = constructCallKey(sClubcode, workOrder.Call_Date__c, callid);
        } else {
            call.callKey = workOrder.External_ID__c;
        }
        if(String.iSNotBlank(workOrder.Call_Id__c)) {
            call.callId = workOrder.Call_Id__c;
        } else {
            call.callId = workOrder.Service_Order_Number__c;
        }

        call.requestingSystemCallId = workOrder.RAP_Case_Number__c;
        call.version = '1';
        call.channel = PopulateChannel();
        call.customer = PopulateCustomer( call.channel.org );
        call.vehicle = PopulateVehicle();
        call.service = PopulateService();
        call.payment = PopulatePayment();
        if( !serviceName.equals( 'IVRLookup' ) ) call.comments = PopulateCallComments( sourceSystem );
        
        calls.add( call );
        return calls;
    }

    private FSL_ClearJsonWorkOrder.Channel PopulateChannel() {
        FSL_ClearJsonWorkOrder.channel channel = new FSL_ClearJsonWorkOrder.channel();
        
        channel.channelType = workOrder.Call_Origin__c == 'Salesforce'? 'CALL_CENTER' : workOrder.Call_Origin__c;
        channel.location = PopulateChannelLocation();
        channel.org = PopulateSystemOrganization(); 
        if(String.isBlank(channel?.org?.name)){
            PopulateChannelOrganization();
        }
        channel.contact = PopulateChannelContact();

        return channel;
    }

    private FSL_ClearJsonWorkOrder.Channel_Location PopulateChannelLocation() {
        FSL_ClearJsonWorkOrder.Channel_Location location = new FSL_ClearJsonWorkOrder.Channel_Location();

        location.address = PopulateLocationAddress();

        return location;
    }

    private FSL_ClearJsonWorkOrder.Location_Address PopulateLocationAddress() {
        FSL_ClearJsonWorkOrder.Location_Address locationAddress = new FSL_ClearJsonWorkOrder.Location_Address();

        locationAddress.addressType = 'PHYSICAL';
        locationAddress.full = '';
        locationAddress.streetNumber = '';
        locationAddress.streetDirection = '';
        locationAddress.streetName = '';
        locationAddress.crossStreet = '';
        locationAddress.city = '';
        locationAddress.country = '';
        locationAddress.county = '';
        locationAddress.state = '';
        locationAddress.postalCode = '';

        return locationAddress;
    }

    private FSL_ClearJsonWorkOrder.SystemOrganization PopulateChannelOrganization() {
        FSL_ClearJsonWorkOrder.SystemOrganization org = new FSL_ClearJsonWorkOrder.SystemOrganization();

        org.code = Label.FSL_SourceClubCode;
        org.name = Label.FSL_SourceClubName;

        return org;
    }

    private FSL_ClearJsonWorkOrder.SystemOrganization PopulateSystemOrganization() {
        FSL_ClearJsonWorkOrder.SystemOrganization org = new FSL_ClearJsonWorkOrder.SystemOrganization();

        if( workOrder.Contact != null ) {
            System.debug('@@@ channel @@@ '+workOrder.Contact.Membership_Org__c);
            org.code = String.isNotBlank(workOrder.Contact.Membership_OrgCode__c) ? workOrder.Contact.Membership_OrgCode__c : Label.FSL_SourceClubCode;
            org.name = String.isNotBlank(workOrder.Contact.Membership_Org__c) ? workOrder.Contact.Membership_Org__c : Label.FSL_SourceClubName;
        } 

        return org;
    }

    private FSL_ClearJsonWorkOrder.Channel_Contact PopulateChannelContact() {
        FSL_ClearJsonWorkOrder.Channel_Contact channelContact = new FSL_ClearJsonWorkOrder.Channel_Contact();

        channelContact.userId =  workOrder.Call_Source__c == 'D3' ? workOrder.Responder_ID__c : 'SFHIST' ;
        channelContact.contactType = 'AGENT';

        return channelContact;
    }

    private FSL_ClearJsonWorkOrder.Customer PopulateCustomer( FSL_ClearJsonWorkOrder.SystemOrganization org ) {
        FSL_ClearJsonWorkOrder.Customer customer = new FSL_ClearJsonWorkOrder.Customer();

        customer.memberships = PopulateMemberships( org );
        customer.contact = PopulateCustomerContact();
        customer.languagePreference = ( workOrder.Contact != null ? workOrder.Contact.Language_Preference__c : null );

        return customer;
    }

    private List<FSL_ClearJsonWorkOrder.Memberships> PopulateMemberships( FSL_ClearJsonWorkOrder.SystemOrganization org ) {
        List<FSL_ClearJsonWorkOrder.Memberships> memberships = new List<FSL_ClearJsonWorkOrder.Memberships>();
        memberships.add( PopulateMembership( org ) );
        return memberships;
    }

    private FSL_ClearJsonWorkOrder.Memberships PopulateMembership( FSL_ClearJsonWorkOrder.SystemOrganization org ) {
        FSL_ClearJsonWorkOrder.Memberships membership = new FSL_ClearJsonWorkOrder.Memberships();
        Contact contact = workOrder.Contact;

        if( contact != null ) {
            if(contact.Membership_Type__c != null){
                membership.membershipType = contact.Membership_Type__c.toUpperCase().contains('MEMBER') ? 'MEMBER' : 'RAP';
            }else{ //For Non-Members, default membershipType as MEMBER as suggested by National
                membership.membershipType = 'MEMBER';
            }
            membership.sponsor = contact.Membership_Sponsor__c;
            membership.program = contact.Membership_Program__c;
            membership.authorizationCode = contact.Membership_Code__c;
            membership.authorizationLevel = contact.Membership_Authorization__c;
            membership.isLocalClub = contact.Membership_Islocalclub__c;
            FSL_ClearJsonWorkOrder.SystemOrganization memberOrg = PopulateSystemOrganization();
            //if(org != null && (org.name != null || org.name != '')){
            membership.org = memberOrg;
            membership.id = String.isNotBlank( contact.Member_Card_Num__c ) ? contact.Member_Card_Num__c : Label.Non_MemberId;
            membership.originalMemberId = membership.id; 
            membership.expirationDate = String.Valueof( contact.Membership_Expiration_Date__c );
            //membership.memberLevel = contact.Membership_Level__c;
            //if(Label.FSL_SourceClubCode == '212') {
            membership.memberLevel = contact.Membership_Level__c?.deleteWhitespace().toUpperCase();
            //}
            
            //membership.memberBirthday = contact.Membership_Birthday__c;
            membership.memberSince = contact.Membership_Since__c;
            membership.memberStatus = contact.Membership_Status__c;
        }
        membership.entitlements = PopulateEntitlements();

        return membership;
    }

    /*membership.id = String.isNotBlank( contact.Member_Card_Num__c ) ? contact.Member_Card_Num__c : workOrder.Original_Member_Id__c;
            membership.originalMemberId = String.isNotBlank(workOrder.Original_Member_Id__c) ? workOrder.Original_Member_Id__c : '';
            if(String.isBlank(membership.id)){
                membership.id = membership.originalMemberId;
                //membership.membershipType = 'MEMBER';
        membership.membershipType = contact.Membership_Type__c != null ? contact.Membership_Type__c.toUpperCase() : contact.Membership_Type__c;
        membership.membershipType = (contact.Membership_Type__c != null && membership.membershipType.contains('MEMBER')) ? 'MEMBER' : 'RAP';
    }*/

    private List<FSL_ClearJsonWorkOrder.Entitlements> PopulateEntitlements() {
        List<FSL_ClearJsonWorkOrder.Entitlements> entitlements = new List<FSL_ClearJsonWorkOrder.Entitlements>();
        entitlements.add( PopulateEntitlement() );
        return entitlements;
    }

    private FSL_ClearJsonWorkOrder.Entitlements PopulateEntitlement() {
        FSL_ClearJsonWorkOrder.Entitlements entitlement = new FSL_ClearJsonWorkOrder.Entitlements();
        return entitlement;
    }

    private FSL_ClearJsonWorkOrder.Customer_Contact PopulateCustomerContact() {
        FSL_ClearJsonWorkOrder.Customer_Contact customerContact = new FSL_ClearJsonWorkOrder.Customer_Contact();

        Contact contact = workOrder.Contact;

        if( contact != null ) {
            customerContact.contactType = contact.Type__c != null ? contact.Type__c.toUpperCase(): 'CUSTOMER';
            customerContact.title = contact.Title;
            customerContact.firstName = contact.FirstName;
            customerContact.lastName = contact.LastName;
        }
        customerContact.phones = PopulateCustomerPhones( contact, workOrder.WO_Member_Phone_Number__c );
        system.debug('@@@@customer Emailsa boeve@@@'+PopulateCustomerEmails( contact ));
        //Option1
        customerContact.emails = PopulateCustomerEmails( contact );
        //customerContact.emails = null;
        system.debug('@@@@customer customerContact @@@'+customerContact);
        return customerContact;
    }

    private List<FSL_ClearJsonWorkOrder.Customer_Phone> PopulateCustomerPhones( Contact contact, String WO_Member_Phone_Number ) {
        List<FSL_ClearJsonWorkOrder.Customer_Phone> customerPhones = new List<FSL_ClearJsonWorkOrder.Customer_Phone>();
        if( contact.Phone != null ) {
            customerPhones.add( PopulateCustomerPhone( contact, WO_Member_Phone_Number ) );
        }
        return customerPhones;
    }

    private FSL_ClearJsonWorkOrder.Customer_Phone PopulateCustomerPhone( Contact contact, String WO_Member_Phone_Number ) {
        FSL_ClearJsonWorkOrder.Customer_Phone customerPhone = new FSL_ClearJsonWorkOrder.Customer_Phone();

        if( contact != null ) {
            customerPhone.phoneType = contact.Phone_Type__c != null ? contact.Phone_Type__c.toUpperCase() : 'CELLULAR';
            customerPhone.phoneNumber = (String.isBlank(WO_Member_Phone_Number) ? contact.Phone : WO_Member_Phone_Number.replaceAll( '[^0-9]', '' ));  //VBR - ERS-230064
            customerPhone.phoneExtension = contact.Phone_Extension__c;
            // customerPhone.preferred
            customerPhone.smsOptIn = contact.Sms_Optin__c;
        }

        return customerPhone;
    }

    private List<FSL_ClearJsonWorkOrder.Customer_Email> PopulateCustomerEmails( Contact contact ) {
        List<FSL_ClearJsonWorkOrder.Customer_Email> customerEmails = new List<FSL_ClearJsonWorkOrder.Customer_Email>();
        if( contact.Email != null ) { 
            customerEmails.add( PopulateCustomerEmail( contact ) );
        }
        system.debug('@@@@@@@@ Customer Emails @@@@@'+customerEmails);
        return customerEmails;
    }

    private FSL_ClearJsonWorkOrder.Customer_Email PopulateCustomerEmail( Contact contact ) {
        FSL_ClearJsonWorkOrder.Customer_Email customerEmail = new FSL_ClearJsonWorkOrder.Customer_Email();
        system.debug('@@@@@@@@ CUstomer Email @@@@@'+customerEmail);
        system.debug('@@@@@@@@ CUstomer contact @@@@@'+contact);
        if( contact != null ) {
            customerEmail.address = contact.Email;
            customerEmail.emailType = contact.Email_Type__c != null ? contact.Email_Type__c.toUpperCase() : 'PERSONAL';
        }
        system.debug('@@@@@@@@ CUstomer Email @@@@@'+customerEmail);
        return customerEmail;
    }

    private FSL_ClearJsonWorkOrder.Vehicle PopulateVehicle() {
        FSL_ClearJsonWorkOrder.Vehicle vehicle = new FSL_ClearJsonWorkOrder.Vehicle();
        
        FSL_Member_Vehicle__c memberVehicle = workOrder.Member_Vehicles__r[0];
        //vehicle.vehicleType = memberVehicle.Vehicle_Type__c;
        if(memberVehicle.Vehicle_Type__c != null){
            List<ERS_Case_VehicleType_Mapping__mdt> caseMappings = [SELECT Id, Vehicle_Type_Case__c, Vehicle_Type_Master_Vehicle__c FROM ERS_Case_VehicleType_Mapping__mdt 
                                                        WHERE Vehicle_Type_Master_Vehicle__c = :memberVehicle.Vehicle_Type__c LIMIT 1];
            if(caseMappings.size() > 0 )
                vehicle.vehicleType = caseMappings[0]?.Vehicle_Type_Case__c.substring(0,2);
        }
        vehicle.vehicleType = String.isNotBlank(vehicle.vehicleType) ? vehicle.vehicleType : 'PS';
        if( memberVehicle.Vehicle_Year__c != null ) vehicle.year = Integer.Valueof( memberVehicle.Vehicle_Year__c );
        vehicle.make = memberVehicle.Vehicle_Make__c;
        vehicle.model = memberVehicle.Vehicle_Model__c;
        vehicle.trim = memberVehicle.Vehicle_Trim__c;
        vehicle.color = memberVehicle.Vehicle_Color__c;
        vehicle.driveType = memberVehicle.Vehicle_Drive_Type__c;
        vehicle.vin = memberVehicle.Vehicle_Vin__c;
        vehicle.tag = memberVehicle.Vehicle_Tag__c;
        vehicle.state = memberVehicle.Vehicle_State__c;
        vehicle.odometer = Integer.Valueof( memberVehicle.Vehicle_Odometer__c );
        vehicle.fuelType = memberVehicle.Vehicle_Fuel_Type__c;
        vehicle.rvInfo = PopulateRvInfo( memberVehicle );
        vehicle.trailerInfo = PopulateTrailerInfo( memberVehicle );
        vehicle.specialEquipmentNeeds = memberVehicle.Vehicle_Special_Equipment_Needs__c;

        return vehicle;
    }

    private FSL_ClearJsonWorkOrder.RvInfo PopulateRvInfo( FSL_Member_Vehicle__c memberVehicle ) {
        FSL_ClearJsonWorkOrder.rvInfo rvInfo = new FSL_ClearJsonWorkOrder.rvInfo();

        rvInfo.rvClass = memberVehicle.RV_Class__c;
        // rvInfo.engineLocation
        // rvInfo.gooseNeck
        // rvInfo.height
        rvInfo.length = memberVehicle.RV_Length__c;
        // rvInfo.weight
        // rvInfo.towing
        // rvInfo.towingType

        return rvInfo;
    }

    private FSL_ClearJsonWorkOrder.TrailerInfo PopulateTrailerInfo( FSL_Member_Vehicle__c memberVehicle ) {
        FSL_ClearJsonWorkOrder.trailerInfo trailerInfo = new FSL_ClearJsonWorkOrder.trailerInfo();

        // trailerInfo.axles
        // trailerInfo.condition
        // trailerInfo.gooseNeck
        // trailerInfo.hitchSize
        trailerInfo.hitchType = memberVehicle.Trailer_Hitchtype__c;
        trailerInfo.length = memberVehicle.Trailer_Length__c;
        // trailerInfo.loaded
        // trailerInfo.loadType
        // trailerInfo.loadWeight
        // trailerInfo.plugType
        // trailerInfo.trailerType

        return trailerInfo;
    }

    private FSL_ClearJsonWorkOrder.Service PopulateService() {
        FSL_ClearJsonWorkOrder.Service service = new FSL_ClearJsonWorkOrder.Service();

        service.callType = workOrder.Call_Type__c;
        TimeZone tz = UserInfo.getTimeZone();
        service.timezoneId = workOrder.Timezone_Id__c == null ? tz.getID() : workOrder.Timezone_Id__c;
        service.timezoneOffset = workOrder.Timezone_Offset__c == null ? 'UTC-05:00' : workOrder.Timezone_Offset__c;
        service.status = PopulateStatus();
        service.appointmentTime = workOrder.Non_Emergency_Appointment_Time__c;
        service.facility = PopulateFacility();
        if( !( serviceAppointmentIdToAssignedResourceMap.get( workOrder.ServiceAppointments[0].Id ) != null 
                && workOrder.Status == 'Spotted' ) ) {
            service.truck = PopulateTruck();
        }
        service.troubleCodes = PopulateTroubleCodes();
        service.ServiceLocations = PopulateServiceLocations();
        service.collision = workOrder.Collision__c;
        service.redFlag = workOrder.Red_Flag__c;
        service.priorityCode = workOrder.Priority_Code__c;
        service.legacyPriorityCode = workOrder.Legacy_Priority_Code__c;
        service.numberOfPassengers = workOrder.Number_Of_Passengers__c != null ? (Integer)workOrder.Number_Of_Passengers__c : 0;
        service.needsFlatbed = workOrder.Needs_Flatbed__c;
        service.flatbedRequested = workOrder.Flatbed_Requested__c;
        service.policies = PopulatePolicies();
        service.providedServices = PopulateProvidedServices();
        // service.charges

        return service;
    }

    private FSL_ClearJsonWorkOrder.Status PopulateStatus() {
        FSL_ClearJsonWorkOrder.Status status = new FSL_ClearJsonWorkOrder.Status();

        status.status = serviceSettings.get('Clear').Status__c;
        //status.status = workOrder.Status;
        if( workOrder.Cleared_Timestamp__c != null ) status.modifiedDate = workOrder.Cleared_Timestamp__c.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        //status.eta = workOrder.InitialETA_Legacy__c;
        for(ServiceAppointment sa :workOrder.ServiceAppointments){
            if(sa.Subject=='Breakdown Appointment'){
                if(sa.ETA__c!=null){
                    status.eta= sa.ETA__c.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
                }
                if(sa.SchedStartTime!=null){
                    status.scheduleStartTime = sa.SchedStartTime.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
                }
            }
        }
        if( String.isNotBlank( String.valueOfGmt( workOrder.Pta__c ) ) ) status.pta = workOrder.Pta__c.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        status.waitTime = Integer.valueOf( workOrder.Wait_Time__c );

        return status;
    }

    private FSL_ClearJsonWorkOrder.Facility PopulateFacility() {
        FSL_ClearJsonWorkOrder.Facility facility = new FSL_ClearJsonWorkOrder.Facility();

        facility.foiType = 'ADDRESS';
        facility.location = new FSL_ClearJsonWorkOrder.Location_Z();

        for ( ServiceAppointment sa : workOrder.ServiceAppointments ) {
            if( sa.Subject == 'Breakdown Appointment' ) {
                if( String.isNotBlank( sa.ServiceTerritory.Facility_Number__c ) ) {
                    facility.id = sa.ServiceTerritory.Facility_Number__c;
                    facility.name = sa.ServiceTerritory.Name;
                }
                else {
                    // D3 / IRAS Spotted Facility
                    facility.id = workOrder.Account.Facility_ID__c;
                    facility.name = workOrder.Account.Name;
                }
            }
        }

        return facility;
    }

    private FSL_ClearJsonWorkOrder.Truck PopulateTruck() {
        FSL_ClearJsonWorkOrder.Truck truck = new FSL_ClearJsonWorkOrder.Truck();

        truck.id = '';
        AssignedResource assignedresource = serviceAppointmentIdToAssignedResourceMap.get( workOrder.ServiceAppointments[0].Id );
        if( assignedresource != null ) {
            truck.id = assignedresource.ServiceResource.Vehicle__r.Truck_ID__c;
        }
        truck.driver = PopulateDriver( assignedresource );

        return truck;
    }

    private FSL_ClearJsonWorkOrder.Driver PopulateDriver( AssignedResource assignedResource ) {
        FSL_ClearJsonWorkOrder.Driver driver = new FSL_ClearJsonWorkOrder.Driver();
        
        driver.id = '';
        if( assignedResource != null ) {
            if( String.isNotBlank( assignedResource.ServiceResource.Driver_Id__c ) ) driver.id = assignedResource.ServiceResource.Driver_Id__c;
            driver.contact = PopulateDriverContact( assignedResource );
        }

        return driver;
    }

    private FSL_ClearJsonWorkOrder.Driver_Contact PopulateDriverContact( AssignedResource assignedResource ) {
        FSL_ClearJsonWorkOrder.Driver_Contact driverContact = new FSL_ClearJsonWorkOrder.Driver_Contact();

        driverContact.contactType = 'DRIVER';
        driverContact.lastName = assignedResource.ServiceResource.Name;

        return driverContact;
    }

    private List<FSL_ClearJsonWorkOrder.TroubleCodes> PopulateTroubleCodes() {
        List<FSL_ClearJsonWorkOrder.TroubleCodes> troubleCodes = new List<FSL_ClearJsonWorkOrder.TroubleCodes>();

        for( FSL_TroubleCode__c tc : workOrder.TroubleCodes__r ) {
            FSL_ClearJsonWorkOrder.TroubleCodes troubleCode = new FSL_ClearJsonWorkOrder.TroubleCodes();
            troubleCode.troubleCodeType = tc.Type__c;
            troubleCode.code = tc.Code__c;
            troubleCode.description = tc.Description__c;
            troubleCodes.add( troubleCode );
        }

        if( workOrder.Resolution_Code__c != null ) {
            FSL_ClearJsonWorkOrder.TroubleCodes troubleCode = new FSL_ClearJsonWorkOrder.TroubleCodes();
            troubleCode.troubleCodeType = 'RESOLUTION';
            troubleCode.code = workOrder.Resolution_Code__c;
            troubleCode.description = '';
            troubleCodes.add( troubleCode );
        }

        if( workOrder.Call_Source__c == 'Salesforce' && workOrder.Clearing_Code__c != null ) {
            FSL_ClearJsonWorkOrder.TroubleCodes troubleCode = new FSL_ClearJsonWorkOrder.TroubleCodes();
            troubleCode.troubleCodeType = 'CLEARING';
            troubleCode.code = workOrder.Clearing_Code__c;
            troubleCode.description = '';
            troubleCodes.add( troubleCode );
        }

        return troubleCodes;
    }

    private List<FSL_ClearJsonWorkOrder.ServiceLocations> PopulateServiceLocations() {
        List<FSL_ClearJsonWorkOrder.ServiceLocations> serviceLocations = new List<FSL_ClearJsonWorkOrder.ServiceLocations>();

        for( serviceAppointment sa: workOrder.ServiceAppointments ) {
            serviceLocations.add( PopulateServiceLocation( sa ) );
        }

        return serviceLocations;
    }

    private FSL_ClearJsonWorkOrder.ServiceLocations PopulateServiceLocation( ServiceAppointment serviceAppointment ) {
        FSL_ClearJsonWorkOrder.ServiceLocations serviceLocation = new FSL_ClearJsonWorkOrder.ServiceLocations();
        System.debug( LoggingLevel.DEBUG, 'FSL_WorkOrderD3JsonWrapper.PopulateServiceLocation: Enter' );

        if( serviceAppointment.Subject == 'Breakdown Appointment' ) {
            serviceLocation.serviceLocationType = 'BREAKDOWN';
            serviceLocation.foi = PopulateFoi( serviceAppointment );
            // serviceLocation.driverDirections
            // serviceLocation.dropBoxInfo
        }
        else if( serviceAppointment.Subject == 'Tow Appointment' ) {
            serviceLocation.serviceLocationType = 'TOW_DESTINATION';
            serviceLocation.foi = PopulateFoi( serviceAppointment );
            // serviceLocation.driverDirections
            serviceLocation.dropBoxInfo = serviceAppointment.Drop_Box_Info__c;
        }
        serviceLocation.mileageCalculated = ( serviceAppointment.FSL_Actual_Miles_Driven__c != null ? serviceAppointment.FSL_Actual_Miles_Driven__c.round( System.RoundingMode.HALF_UP ).intValue() : null );

        return serviceLocation;
    }

    private FSL_ClearJsonWorkOrder.Foi PopulateFoi( ServiceAppointment serviceAppointment ) {
        FSL_ClearJsonWorkOrder.Foi foi = new FSL_ClearJsonWorkOrder.Foi();

        foi.foiType = 'ADDRESS';
        foi.location = PopulateBreakdownLocation( serviceAppointment );
        if( serviceAppointment.Subject == 'Tow Appointment' ) {
            foi.name = serviceAppointment.Tow_Destination_Name__c;
            foi.contacts = PopulateContacts();
            SetFoiForAAR ( serviceAppointment, foi );
        }

        return foi;
    }

    @TestVisible
    private void SetFoiForAAR ( ServiceAppointment serviceAppointment, FSL_ClearJsonWorkOrder.Foi foi ) {
        if ( serviceAppointment.D3_AAR_Id__c != null && serviceAppointment.Address_Change_Counter__c == 0 ) {
            foi.foiType = 'AAR';
            foi.id = serviceAppointment.D3_AAR_Id__c;
        }
    }

    private FSL_ClearJsonWorkOrder.Breakdown_Location PopulateBreakdownLocation( ServiceAppointment serviceAppointment ) {
        FSL_ClearJsonWorkOrder.Breakdown_Location breakdownLocation = new FSL_ClearJsonWorkOrder.Breakdown_Location();

        if( serviceAppointment.Subject == 'Breakdown Appointment' ) {
            if( serviceAppointment.Address_Change_Counter__c != null && serviceAppointment.Address_Change_Counter__c > 0 ) {
                breakdownLocation.latitude = serviceAppointment.Latitude;
                breakdownLocation.longitude = serviceAppointment.Longitude;
            }
            else {
                breakdownLocation.latitude = workOrder.Breakdown_Location__Latitude__s;
                breakdownLocation.longitude = workOrder.Breakdown_Location__Longitude__s;
            }
            breakdownLocation.highway = serviceAppointment.Highway__c;
            breakdownLocation.mileMarker = serviceAppointment.Mile_Marker__c;
            breakdownLocation.locationCode = serviceAppointment.Location_Code__c;
        }
        else if( serviceAppointment.Subject == 'Tow Appointment' ) {
            if( serviceAppointment.Address_Change_Counter__c != null && serviceAppointment.Address_Change_Counter__c > 0 ) {
                breakdownLocation.latitude = serviceAppointment.Latitude;
                breakdownLocation.longitude = serviceAppointment.Longitude;
            }
            else {
                breakdownLocation.latitude = workOrder.Tow_Location__Latitude__s;
                breakdownLocation.longitude = workOrder.Tow_Location__Longitude__s;
            }
        }
        breakdownLocation.address = PopulateBreakdownAddress( serviceAppointment );
        breakdownLocation.landmark = serviceAppointment.Landmark__c;
        // breakdownLocation.grid
        // breakdownLocation.zone
            
        return breakdownLocation;
    }

    private FSL_ClearJsonWorkOrder.BreakdownAddress PopulateBreakdownAddress( ServiceAppointment serviceAppointment ) {
        FSL_ClearJsonWorkOrder.BreakdownAddress breakdownAddress = new FSL_ClearJsonWorkOrder.BreakdownAddress();
        
        String strStreet = String.isBlank( serviceAppointment.Street ) ? '' : serviceAppointment.Street + ' ';
        String strCity = String.isBlank( serviceAppointment.City ) ? '' : serviceAppointment.City + ', ';
        String strState = String.isBlank( serviceAppointment.State ) ? '' : serviceAppointment.State + ' ';
        String strPostalCode = String.isBlank( serviceAppointment.PostalCode ) ? '' : serviceAppointment.PostalCode + ' ';
        String strCountry = String.isBlank( serviceAppointment.Country ) ? '' : serviceAppointment.Country;
        boolean isNumber = false;
        string strNumber;
        string strName;
        system.debug('@@@ strStreet@@@'+serviceAppointment);
        system.debug('@@@ strStreet@@@'+strStreet);
        if(strStreet != '') {
            String[] streetList = strStreet.split(' ',2);
            strNumber = streetList[0];
            strName = streetList.size() > 1 ? streetList[1] : streetList[0];
            isNumber = strNumber.isNumeric();
        }
        system.debug('@@@ streetnumber@@@'+strNumber);
        system.debug('@@@ strName@@@'+strName);
        system.debug('@@@ isNumber@@@'+isNumber);
        breakdownAddress.addressType = 'PHYSICAL';
        breakdownAddress.full = strStreet + strCity + strState + strPostalCode + strCountry;
        // breakdownAddress.streetNumber
        // breakdownAddress.streetDirection
        breakdownAddress.streetNumber = isNumber ? strNumber : '';
        breakdownAddress.streetName = isNumber ? strName : serviceAppointment.Street;
        //breakdownAddress.streetName = serviceAppointment.Street;
        breakdownAddress.crossStreet = serviceAppointment.Cross_Street__c;
        breakdownAddress.crossStreet2 = serviceAppointment.Cross_Street_2__c;
        breakdownAddress.city = serviceAppointment.City;
        // breakdownAddress.county
        breakdownAddress.state = serviceAppointment.State;
        breakdownAddress.postalCode = serviceAppointment.PostalCode;
        // Country required to be sent as USA or 3 digit code
        breakdownAddress.country = serviceAppointment.Country != null && 'United States'.equalsIgnoreCase( serviceAppointment.Country ) ? 'USA' : serviceAppointment.Country;

        return breakdownAddress;
    }

    private List<FSL_ClearJsonWorkOrder.Contacts> PopulateContacts() {
        List<FSL_ClearJsonWorkOrder.Contacts> contacts = new List<FSL_ClearJsonWorkOrder.Contacts>();
        FSL_ClearJsonWorkOrder.Contacts contact = new FSL_ClearJsonWorkOrder.Contacts();

        contact.contactType = 'TOWDEST';
        contact.firstName = workOrder.Tow_Contact_First_Name__c;
        contact.lastName = workOrder.Tow_Contact_Last_Name__c;
        if( workOrder.Tow_Contact_Phone_Number__c != null ) contact.phones = PopulateContactPhones();

        contacts.add( contact );
        return contacts;
    }

    private List<FSL_ClearJsonWorkOrder.Contact_Phones> PopulateContactPhones() {
        List<FSL_ClearJsonWorkOrder.Contact_Phones> contactPhones = new List<FSL_ClearJsonWorkOrder.Contact_Phones>();
        FSL_ClearJsonWorkOrder.Contact_Phones contactPhone = new FSL_ClearJsonWorkOrder.Contact_Phones();

        contactPhone.phoneType = 'BUSINESS';
        contactPhone.phoneNumber = workOrder.Tow_Contact_Phone_Number__c;
        // contactPhone.preferred

        contactPhones.add( contactPhone );
        return contactPhones;
    }

    private List<FSL_ClearJsonWorkOrder.Policies> PopulatePolicies() {
        List<FSL_ClearJsonWorkOrder.Policies> policies = new List<FSL_ClearJsonWorkOrder.Policies>();

        for( FSL_Policy__c policy : workOrder.Policies__r ) {
            if(policy.Policy_Code__c != null){
                policies.add( PopulatePolicy( policy ) );
            }
        }

        return policies;
    }

    private FSL_ClearJsonWorkOrder.Policies PopulatePolicy( FSL_Policy__c workOrderPolicy ) {
        FSL_ClearJsonWorkOrder.Policies policy = new FSL_ClearJsonWorkOrder.Policies();

        policy.code = workOrderPolicy.Policy_Code__c;
        policy.description = workOrderPolicy.Policy_Description__c;

        return policy;
    }

    private List<FSL_ClearJsonWorkOrder.ProvidedServices> PopulateProvidedServices() {
        List<FSL_ClearJsonWorkOrder.ProvidedServices> providedServices = new List<FSL_ClearJsonWorkOrder.ProvidedServices>();

        for( FSL_Service_Line_Item__c serviceLineItem : workOrder.Service_Line_Items__r ) {
            providedServices.add( PopulateProvidedService( serviceLineItem ) );
        }

        return providedServices;
    }

    private FSL_ClearJsonWorkOrder.ProvidedServices PopulateProvidedService( FSL_Service_Line_Item__c serviceLineItem ) {
        FSL_ClearJsonWorkOrder.ProvidedServices providedService = new FSL_ClearJsonWorkOrder.ProvidedServices();

        // providedService.providedServiceType
        providedService.service = serviceLineItem.Product__r.ProductCode;
        // providedService.unit
        providedService.quantity = serviceLineItem.Unit__c != null ? Integer.valueOf( serviceLineItem.Unit__c ) : 0;
        providedService.charge = PopulateCharge( serviceLineItem );

        return providedService;
    }

    private FSL_ClearJsonWorkOrder.Charge PopulateCharge( FSL_Service_Line_Item__c serviceLineItem ) {
        FSL_ClearJsonWorkOrder.Charge charge = new FSL_ClearJsonWorkOrder.Charge();

        // charge.chargeType
        charge.amount = String.valueOf( serviceLineItem.Cost__c );

        return charge;
    }

    private FSL_ClearJsonWorkOrder.Payment PopulatePayment() {
        FSL_ClearJsonWorkOrder.Payment payment = new FSL_ClearJsonWorkOrder.Payment();
        for( serviceAppointment sa: workOrder.ServiceAppointments ) {
            if( sa.isBreakdown__c ) {
                payment.required = sa.Payment_Required__c;
                payment.paymentType = sa.Payment_Type__c;
            }
        }
        payment.codes = workOrder.Payment_Codes__c;

        return payment;
    }

    private List<FSL_ClearJsonWorkOrder.Comments> PopulateCallComments( FSL_ClearJsonWorkOrder.SourceSystem sourceSystem ) {
        List<FSL_ClearJsonWorkOrder.Comments> comments = new List<FSL_ClearJsonWorkOrder.Comments>();
        
        System.debug( 'FSL_WorkOrderD3JsonWrapper.PopulateCallComments: Populating Call Comments From Comments' );
        for( FSL_Call_Comments__c callComment : workOrder.Call_Comments__r ) {
            if( callComment.FSL_Comment__c != null ) {
                comments.add( PopulateComment( callComment, sourceSystem ) );
            }
        }

        System.debug( 'FSL_WorkOrderD3JsonWrapper.PopulateCallComments: Populating Call Comments From Feed' );
        try {
            if( workOrderIdToFeedItemsMap.containsKey( workOrder.Id ) ) {
                for( FeedItem feed : workOrderIdToFeedItemsMap.get( workOrder.Id ) ) {
                    comments.add( PopulateComment( feed, sourceSystem ) );
                }
            }
        }
        catch( NullPointerException e ) { System.debug( 'FSL_WorkOrderD3JsonWrapper.PopulateCallComments: NullPointerException = [' + e.getMessage() + ']' ); }
        catch( Exception e ) { System.debug( 'FSL_WorkOrderD3JsonWrapper.PopulateCallComments: OtherException = [' + e.getMessage() + ']' ); }

        return comments;
    }

    private FSL_ClearJsonWorkOrder.Comments PopulateComment( FSL_Call_Comments__c callComment, FSL_ClearJsonWorkOrder.SourceSystem sourceSystem ) {
        FSL_ClearJsonWorkOrder.Comments comment = new FSL_ClearJsonWorkOrder.Comments();
        
        comment.system_Z = sourceSystem;
        comment.contact  = PopulateCommentsContact( callComment );
        if( callComment.CreatedDate != null ) comment.commentDate = callComment.CreatedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        comment.commentType = 'NORMAL';
        comment.visibility = 'EXTERNAL';
        comment.text = callComment.FSL_Comment__c;

        return comment;
    }

    private FSL_ClearJsonWorkOrder.Comments_Contact PopulateCommentsContact( FSL_Call_Comments__c callComment ) {
        FSL_ClearJsonWorkOrder.Comments_Contact commentsContact = new FSL_ClearJsonWorkOrder.Comments_Contact();

        commentsContact.userId = String.isNotBlank( callComment.CreatedBy.EmployeeNumber ) ? callComment.CreatedBy.EmployeeNumber : DEFAULT_USER_ID;
        commentsContact.contactType = 'SYSTEM';

        return commentsContact;
    }

    private FSL_ClearJsonWorkOrder.Comments PopulateComment( FeedItem feedItem, FSL_ClearJsonWorkOrder.SourceSystem sourceSystem ) {
        FSL_ClearJsonWorkOrder.Comments comment = new FSL_ClearJsonWorkOrder.Comments();
        
        comment.system_Z = sourceSystem;
        comment.contact  = PopulateCommentsContact( feedItem );
        if( feedItem.LastModifiedDate != null ) comment.commentDate = feedItem.LastModifiedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
        comment.commentType = 'NORMAL';
        comment.visibility = 'EXTERNAL';
        comment.text = feedItem.Body.stripHtmlTags();

        return comment;
    }

    private FSL_ClearJsonWorkOrder.Comments_Contact PopulateCommentsContact( FeedItem feedItem ) {
        FSL_ClearJsonWorkOrder.Comments_Contact commentsContact = new FSL_ClearJsonWorkOrder.Comments_Contact();

        commentsContact.userId = DEFAULT_USER_ID; //feedItem.InsertedBy.Name; // D3 only accepts 9 digit char
        commentsContact.contactType = 'SYSTEM';
        
        return commentsContact;
    }

    private List<FSL_ClearJsonWorkOrder.CallEvent> PopulateCallEvents( FSL_ClearJsonWorkOrder.Facility facility, FSL_ClearJsonWorkOrder.Truck truck, Map<String, String> zipCodeToClubCode ) { 
        List<FSL_ClearJsonWorkOrder.CallEvent> callEvents = new List<FSL_ClearJsonWorkOrder.CallEvent>();

        Datetime eta;
        for( ServiceAppointment serviceAppointment : workOrder.ServiceAppointments ) {
            if( serviceAppointment.Subject == 'Breakdown Appointment' ) {
                eta = ConvertToGMT( serviceAppointment.SchedStartTime );
            }
        }
        Datetime eventTime = ConvertToGMT( System.now() ); // Why? System.now() is in GMT???

        // Spotted
        callEvents.add( PopulateCallEvent( workOrder.Spotted_Timestamp__c == null ? eventTime : ConvertToGMT( workOrder.Spotted_Timestamp__c ), 'SP', 'FS', facility, truck, eta, zipCodeToClubCode ) );
       
       // Assigned (Scheduled)
        if( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.Scheduled_Timestamp__c != null ) ) {
            callEvents.add( PopulateCallEvent( workOrder.Scheduled_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.Scheduled_Timestamp__c ), 'AS', '', facility, truck, eta, zipCodeToClubCode ) );
        }

        // Dispatched
        if( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.Dispatched_Timestamp__c != null ) ) {
            callEvents.add( PopulateCallEvent( workOrder.Dispatched_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.Dispatched_Timestamp__c ), 'DI', '', facility, truck, eta, zipCodeToClubCode ) );
        }

        // Enroute
       if( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.Enroute_Timestamp__c != null ) ) {
            callEvents.add( PopulateCallEvent( workOrder.Enroute_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.Enroute_Timestamp__c ), 'ER', '', facility, truck, eta, zipCodeToClubCode ) );
        }
        
        // On Location
        if( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.On_Location_Timestamp__c != null ) ) { 
            callEvents.add( PopulateCallEvent( workOrder.On_Location_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.On_Location_Timestamp__c ), 'OL', '', facility, truck, eta, zipCodeToClubCode ) );
        }
        
        // In Tow
        if( workOrder.Is_Tow_WorkType__c 
            && ( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.In_Tow_Timestamp__c != null ) ) ) {
            callEvents.add( PopulateCallEvent( workOrder.In_Tow_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.In_Tow_Timestamp__c ), 'TW', '', facility, truck, eta, zipCodeToClubCode ) );
        }
        
        // Clear
        if( serviceName == 'Clear' || ( serviceName == 'IVRLookup' && workOrder.Cleared_Timestamp__c != null ) ) {
            callEvents.add( PopulateCallEvent( workOrder.Cleared_Timestamp__c == null ? callEvents[callEvents.size() - 1].eventTime.addSeconds( 1 ) : ConvertToGMT( workOrder.Cleared_Timestamp__c ), 'CL', '', facility, truck, eta, zipCodeToClubCode ) );
        }

        return callEvents;
    }

    private DateTime ConvertToGMT( DateTime dt ) {
        Datetime gmt = null;
        if( dt != null ) {
            gmt = DateTime.newInstanceGmt( dt.yearGMT(), dt.monthGMT(), dt.dayGMT(), dt.hourGMT(), dt.minuteGMT(), dt.secondGMT() );
        }
        return gmt;
    }

    private FSL_ClearJsonWorkOrder.CallEvent PopulateCallEvent( Datetime eventTime, String status, String reasonCode, FSL_ClearJsonWorkOrder.Facility facility, FSL_ClearJsonWorkOrder.Truck truck, Datetime eta, Map<String, String> zipCodeToClubCode ) {
        FSL_ClearJsonWorkOrder.CallEvent callEvent = new FSL_ClearJsonWorkOrder.CallEvent();

        //callEvent.callKey = workOrder.External_Id__c;
        callEvent.callDate = workOrder.Call_Date__c;
        //callEvent.callId = workOrder.Call_Id__c;

        /*Datetime createdDate = workOrder.CreatedDate;
        String month = String.valueOf(CreatedDate.month()).leftPad(2,'0');
        String day =  String.valueOf(CreatedDate.day()).leftPad(2,'0');
        string sdate = CreatedDate.year() + month  + day;*/
        string callid = workOrder.Call_Id__c; //Service_Order_Number__c
        //string clubCode = '555';
        if(workOrder.External_ID__c == null) {
            String sClubcode = '004';
            if(zipCodeToClubCode != null && zipCodeToClubCode.containsKey(workOrder.PostalCode)){
                sClubcode = zipCodeToClubCode.get(workOrder.postalCode);
            }
            callEvent.callKey = constructCallKey(sClubcode, workOrder.Call_Date__c, callid);
        } else {
            callEvent.callKey = workOrder.External_ID__c;
        }
        if(workOrder.Call_Id__c != null) {
            callEvent.callId = workOrder.Call_Id__c;
        } else {
            callEvent.callId = workOrder.Service_Order_Number__c;
        }

        callEvent.eventTime = eventTime;
        callEvent.statusDetail = PopulateStatusDetail( status, reasonCode, facility, truck, eta );

        return callEvent;
    }

    private FSL_ClearJsonWorkOrder.StatusDetail PopulateStatusDetail( String status, String reasonCode, FSL_ClearJsonWorkOrder.Facility facility, FSL_ClearJsonWorkOrder.Truck truck, Datetime eta ) {
        FSL_ClearJsonWorkOrder.StatusDetail statusDetail = new FSL_ClearJsonWorkOrder.StatusDetail();

        statusDetail.status = status;
        statusDetail.reasonCode = reasonCode;
        statusDetail.updatedBy = PopulateUpdatedBy();
        statusDetail.facility = facility;
        statusDetail.truck = truck;
        statusDetail.eta = eta;

        return statusDetail;
    }

    private FSL_ClearJsonWorkOrder.UpdatedBy PopulateUpdatedBy() {
        FSL_ClearJsonWorkOrder.UpdatedBy updatedBy = new FSL_ClearJsonWorkOrder.UpdatedBy( 'SYSTEM' );

        // updatedBy.contactType = 'SYSTEM';

        return updatedBy;
    }
}