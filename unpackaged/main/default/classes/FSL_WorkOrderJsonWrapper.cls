global with sharing class FSL_WorkOrderJsonWrapper {
    // *********************************************
    // * JSON PAYLOAD WRAPPER
    // *********************************************
    global virtual class WrapperFactory {
        public virtual WorkOrderJsonWrapper createWrapper() {
            SystemOrganizationWrapper systemOrganizationWrapper = new SystemOrganizationWrapper();
            SourceSystemWrapper sourceSystemWrapper = new SourceSystemWrapper( systemOrganizationWrapper );
            UpdatedByWrapper updatedByWrapper = new UpdatedByWrapper();
            CommentContactWrapper commentContactWrapper = new CommentContactWrapper();
            CommentWrapper commentWrapper = new CommentWrapper( commentContactWrapper, sourceSystemWrapper );
            PaymentWrapper paymentWrapper = new PaymentWrapper();
            ChargeWrapper chargeWrapper = new ChargeWrapper();
            ProvidedServiceWrapper providedServiceWrapper = new ProvidedServiceWrapper( chargeWrapper );
            PolicyWrapper policyWrapper = new PolicyWrapper();
            ContactPhoneWrapper contactPhoneWrapper = new ContactPhoneWrapper();
            ContactWrapper contactWrapper = new ContactWrapper( contactPhoneWrapper );
            BreakdownAddressWrapper breakdownAddressWrapper = new BreakdownAddressWrapper();
            BreakdownLocationWrapper breakdownLocationWrapper = new BreakdownLocationWrapper( breakdownAddressWrapper );
            FoiWrapper foiWrapper = new FoiWrapper( breakdownLocationWrapper, contactWrapper );
            ServiceLocationWrapper serviceLocationWrapper = new ServiceLocationWrapper( foiWrapper );
            TroubleCodeWrapper troubleCodeWrapper = new TroubleCodeWrapper();
            DriverContactWrapper driverContactWrapper = new DriverContactWrapper();
            DriverWrapper driverWrapper = new DriverWrapper( driverContactWrapper );
            TruckWrapper truckWrapper = new TruckWrapper( driverWrapper );
            LocationWrapper locationWrapper = new LocationWrapper();
            FacilityWrapper facilityWrapper = new FacilityWrapper( locationWrapper );
            StatusWrapper statusWrapper = new StatusWrapper();
            ServiceWrapper serviceWrapper = new ServiceWrapper( facilityWrapper, policyWrapper, providedServiceWrapper, serviceLocationWrapper, statusWrapper, troubleCodeWrapper, truckWrapper );
            StatusDetailWrapper statusDetailWrapper = new StatusDetailWrapper( facilityWrapper, truckWrapper, updatedByWrapper );
            CallEventWrapper callEventWrapper = new CallEventWrapper( statusDetailWrapper );
            TrailerInfoWrapper trailerInfoWrapper = new TrailerInfoWrapper();
            RvInfoWrapper rvInfoWrapper = new RvInfoWrapper();
            VehicleWrapper vehicleWrapper = new VehicleWrapper( rvInfoWrapper, trailerInfoWrapper );
            CustomerEmailWrapper customerEmailWrapper = new CustomerEmailWrapper();
            CustomerPhoneWrapper customerPhoneWrapper = new CustomerPhoneWrapper();
            CustomerContactWrapper customerContactWrapper = new CustomerContactWrapper( customerEmailWrapper, customerPhoneWrapper );
            EntitlementWrapper entitlementWrapper = new EntitlementWrapper();
            MembershipWrapper membershipWrapper = new MembershipWrapper( entitlementWrapper, systemOrganizationWrapper );
            CustomerWrapper customerWrapper = new CustomerWrapper( customerContactWrapper, membershipWrapper );
            LocationAddressWrapper locationAddressWrapper = new LocationAddressWrapper();
            ChannelLocationWrapper channelLocationWrapper = new ChannelLocationWrapper( locationAddressWrapper );
            ChannelContactWrapper channelContactWrapper = new ChannelContactWrapper();
            ChannelWrapper channelWrapper = new ChannelWrapper( channelContactWrapper, channelLocationWrapper, systemOrganizationWrapper );
            CallWrapper callWrapper = new CallWrapper( callEventWrapper, channelWrapper, commentWrapper, customerWrapper, paymentWrapper, serviceWrapper, sourceSystemWrapper, vehicleWrapper );
            WorkOrderJsonWrapper workOrderJsonWrapper = new WorkOrderJsonWrapper( callWrapper );
            return workOrderJsonWrapper;
        }
    }

    global virtual class WorkOrderJsonWrapper {
        private CallWrapper callWrapper;

        public WorkorderJsonWrapper( CallWrapper callWrapper ) {
            this.callWrapper = callWrapper;
        }

        public virtual WorkOrderJson wrap( FSL_ServiceSettings__c serviceSetting, List<FSL_WorkOrder.WorkOrder> workOrders ) {
            WorkOrderJson workOrderJson = new WorkOrderJson();
            workOrderJson.id = generateGUID();
            workOrderJson.requestEventType = serviceSetting.RequestEventType__c;
            workOrderJson.subType = serviceSetting.RequestSubtype__c;
            workOrderJson.version = serviceSetting.Version__c;
            workOrderJson.calls = wrapCalls( serviceSetting, workOrders );
            return workOrderJson;
        }

        // TODO: this is very generic, so perhaps belongs in a more centralized location
        private String generateGUID () {
            Blob b = Crypto.GenerateAESKey( 256 );
            String h = EncodingUtil.ConvertTohex( b );
            String guid = h.SubString( 0, 8 )+ '-' + h.SubString( 8, 12 ) + '-' + h.SubString( 12, 16 ) + '-' + h.SubString( 16, 20 ) + '-' + h.substring( 20, 32 );
            return guid;
        }

        private List<Call> wrapCalls( FSL_ServiceSettings__c serviceSetting, List<FSL_WorkOrder.WorkOrder> workOrders ) {
            List<Call> calls = new List<Call>();
            for( FSL_WorkOrder.WorkOrder workOrder : workOrders ) {
                calls.add( callWrapper.wrap( workOrder, serviceSetting ) );
            }
            return calls;
        }
    }

    global virtual class CallWrapper {
        private CallEventWrapper callEventWrapper;
        private ChannelWrapper channelWrapper;
        private CommentWrapper commentWrapper;
        private CustomerWrapper customerWrapper;
        private PaymentWrapper paymentWrapper;
        private ServiceWrapper serviceWrapper;
        private SourceSystemWrapper sourceSystemWrapper;
        private VehicleWrapper vehicleWrapper;

        public CallWrapper( CallEventWrapper callEventWrapper, ChannelWrapper channelWrapper, CommentWrapper commentWrapper, CustomerWrapper customerWrapper, PaymentWrapper paymentWrapper, ServiceWrapper serviceWrapper, SourceSystemWrapper sourceSystemWrapper, VehicleWrapper vehicleWrapper ) {
            this.callEventWrapper = callEventWrapper;
            this.channelWrapper = channelWrapper;
            this.commentWrapper = commentWrapper;
            this.customerWrapper = customerWrapper;
            this.paymentWrapper = paymentWrapper;
            this.serviceWrapper = serviceWrapper;
            this.sourceSystemWrapper = sourceSystemWrapper;
            this.vehicleWrapper = vehicleWrapper;
        }

        public virtual Call wrap( FSL_WorkOrder.WorkOrder workOrder, FSL_ServiceSettings__c serviceSetting ) {
            WorkOrder wo = workOrder.getWorkOrder();
            Call call = new Call();
            call.callDate = wo.Call_Date__c;
            call.callEvents = wrapCallEvents( workOrder );
            call.callId = wo.Call_Id__c;
            call.callKey = wo.External_ID__c;
            call.channel = channelWrapper.wrap( wo );
            call.comments = wrapComments( workOrder, serviceSetting );
            call.createDate = wo.CreatedDate.getTime();
            call.customer = customerWrapper.wrap( wo );
            call.payment = paymentWrapper.wrap( wo );
            call.requestingSystemCallId = wo.RAP_Case_Number__c;
            call.service = serviceWrapper.wrap( workOrder );
            call.sourceSystem = sourceSystemWrapper.wrap( serviceSetting );
            call.targetSystem = sourceSystemWrapper.wrap( wo );
            call.vehicle = vehicleWrapper.wrap( wo.Member_Vehicles__r[0] );
            return call;
        }

        private List<CallEvent> wrapCallEvents( FSL_WorkOrder.WorkOrder workOrder ) {
            List<CallEvent> callEvents = new List<CallEvent>();
            Datetime defaultEventTime = System.now();
            WorkOrder wo = workOrder.getWorkOrder();

            FSL_ServiceAppointment.ServiceAppointment serviceAppointment = workOrder.getBreakDownServiceAppointment();
            ServiceAppointment brkdnSA = serviceAppointment.getServiceAppointment();
            ServiceAppointment towSA = null;
            if ( wo.Is_Tow_WorkType__c ) {
                FSL_ServiceAppointment.ServiceAppointment towServiceAppointment = workOrder.getTowServiceAppointment();
                towSA = towServiceAppointment.getServiceAppointment();
            }
            
            // Spotted
            callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.Spotted_Timestamp__c != null ? brkdnSA.Spotted_Timestamp__c : defaultEventTime, 'SP', 'FS' ) );

            // Assigned (Scheduled)
            if( brkdnSA.Scheduled_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.Scheduled_Timestamp__c, 'AS', '' ) );
            }

            // Dispatched
            if( brkdnSA.Dispatched_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.Dispatched_Timestamp__c, 'DI', '' ) );
            }

            // Enroute
            if( brkdnSA.En_route_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.En_route_Timestamp__c, 'ER', '' ) );
            }
            
            // On Location
            if( brkdnSA.On_Location_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.On_Location_Timestamp__c, 'OL', '' ) );
            }
            
            // In Tow
            if( towSA != null && towSA.In_Tow_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder,towSA.In_Tow_Timestamp__c, 'TW', '' ) );
            }
            
            // Clear
            if( brkdnSA.Cleared_Timestamp__c != null ) {
                callEvents.add( callEventWrapper.wrap( workOrder, brkdnSA.Cleared_Timestamp__c, 'CL', '' ) );
            }

            return callEvents;
        }

        private List<Comment> wrapComments( FSL_WorkOrder.WorkOrder workOrder, FSL_ServiceSettings__c serviceSetting ) {
            WorkOrder wo = workOrder.getWorkOrder();
            List<Comment> comments = new List<Comment>();
            for( FSL_Call_Comments__c callComment : wo.Call_Comments__r ) {
                if( callComment.FSL_Comment__c != null ) {
                    comments.add( commentWrapper.wrap( callComment, serviceSetting ) );
                }
            }
            for( FeedItem feed : workOrder.getFeedItems() ) {
                comments.add( commentWrapper.wrap( feed, serviceSetting ) );
            }
            return comments;
        }
    }

    global virtual class ChannelWrapper {
        private ChannelContactWrapper channelContactWrapper;
        private ChannelLocationWrapper channelLocationWrapper;
        private SystemOrganizationWrapper systemOrganizationWrapper;

        public ChannelWrapper( ChannelContactWrapper channelContactWrapper, ChannelLocationWrapper channelLocationWrapper, SystemOrganizationWrapper systemOrganizationWrapper ) {
            this.channelContactWrapper = channelContactWrapper;
            this.channelLocationWrapper = channelLocationWrapper;
            this.systemOrganizationWrapper = systemOrganizationWrapper;
        }

        public virtual Channel wrap( WorkOrder workOrder ) {
            Channel channel = new Channel();
            channel.channelType = workOrder.Call_Origin__c;
            channel.contact = channelContactWrapper.wrap( workOrder );
            channel.location = channelLocationWrapper.wrap();
            channel.org = systemOrganizationWrapper.wrap( workOrder.Contact );
            return channel;
        }
    }

    global virtual class ChannelContactWrapper {
        public virtual ChannelContact wrap( WorkOrder workOrder ) {
            ChannelContact channelContact = new ChannelContact();
            channelContact.contactType = workOrder.Responder_ID__c;
            channelContact.userId = 'AGENT';
            return channelContact;
        }
    }

    global virtual class ChannelLocationWrapper {
        private LocationAddressWrapper locationAddressWrapper;

        public ChannelLocationWrapper( LocationAddressWrapper locationAddressWrapper ) {
            this.locationAddressWrapper = locationAddressWrapper;
        }

        public virtual ChannelLocation wrap() {
            ChannelLocation channelLocation = new ChannelLocation();
            channelLocation.address = locationAddressWrapper.wrap();
            return channelLocation;
        }
    }

    global virtual class LocationAddressWrapper {
        public virtual LocationAddress wrap() {
            LocationAddress locationAddress = new LocationAddress();
            locationAddress.addressType = 'PHYSICAL';
            locationAddress.city = '';
            locationAddress.country = '';
            locationAddress.county = '';
            locationAddress.crossStreet = '';
            locationAddress.full = '';
            locationAddress.postalCode = '';
            locationAddress.state = '';
            locationAddress.streetDirection = '';
            locationAddress.streetName = '';
            locationAddress.streetNumber = '';
            return locationAddress;
        }
    }

    global virtual class CustomerWrapper {
        private CustomerContactWrapper customerContactWrapper;
        private MembershipWrapper membershipWrapper;

        public CustomerWrapper( CustomerContactWrapper customerContactWrapper, MembershipWrapper membershipWrapper ) {
            this.customerContactWrapper = customerContactWrapper;
            this.membershipWrapper = membershipWrapper;
        }

        public virtual Customer wrap( WorkOrder workOrder ) {
            Schema.Contact contact = workOrder.Contact;
            Customer customer = new Customer();
            customer.contact = customerContactWrapper.wrap( contact );
            customer.languagePreference = contact != null ? contact.Language_Preference__c : null;
            customer.memberships = wrapMemberships( contact, workOrder );
            return customer;
        }

        private List<Membership> wrapMemberships( Schema.Contact contact, WorkOrder workOrder ) {
            List<Membership> memberships = new List<Membership>();
            memberships.add( membershipWrapper.wrap( contact, workOrder ) );
            return memberships;
        }
    }

    global virtual class MembershipWrapper {
        private EntitlementWrapper entitlementWrapper;
        private SystemOrganizationWrapper systemOrganizationWrapper;

        public MembershipWrapper( EntitlementWrapper entitlementWrapper, SystemOrganizationWrapper systemOrganizationWrapper ) {
            this.entitlementWrapper = entitlementWrapper;
            this.systemOrganizationWrapper = systemOrganizationWrapper;
        }

        public virtual Membership wrap( Schema.Contact contact, WorkOrder workOrder ) {
            Membership membership = new Membership();
            if( contact != null ) {
                membership.authorizationCode = contact.Membership_Code__c;
                membership.authorizationLevel = contact.Membership_Authorization__c;
                membership.expirationDate = String.Valueof( contact.Membership_Expiration_Date__c );
                membership.id = String.isNotBlank( contact.Member_Card_Num__c ) ? contact.Member_Card_Num__c : workOrder.Original_Member_Id__c;
                membership.isLocalClub = contact.Membership_Islocalclub__c;
                membership.memberBirthday = contact.Membership_Birthday__c;
                membership.memberLevel = contact.Membership_Level__c;
                membership.membershipType = contact.Membership_Type__c;
                membership.memberSince = contact.Membership_Since__c;
                membership.memberStatus = contact.Membership_Status__c;
                membership.org = systemOrganizationWrapper.wrap( contact );
                membership.originalMemberId = workOrder.Original_Member_Id__c;
                membership.program = contact.Membership_Program__c;
                membership.sponsor = contact.Membership_Sponsor__c;
            }
            membership.entitlements = wrapEntitlements();
            return membership;
        }

        private List<Entitlement> wrapEntitlements() {
            List<Entitlement> entitlements = new List<Entitlement>();
            entitlements.add( entitlementWrapper.wrap() );
            return entitlements;
        }
    }

    global virtual class EntitlementWrapper {
        public virtual Entitlement wrap() {
            Entitlement entitlement = new Entitlement();
            return entitlement;
        }
    }

    global virtual class CustomerContactWrapper {
        private CustomerEmailWrapper customerEmailWrapper;
        private CustomerPhoneWrapper customerPhoneWrapper;

        public CustomerContactWrapper( CustomerEmailWrapper customerEmailWrapper, CustomerPhoneWrapper customerPhoneWrapper ) {
            this.customerEmailWrapper = customerEmailWrapper;
            this.customerPhoneWrapper = customerPhoneWrapper;
        }

        public virtual CustomerContact wrap( Schema.Contact contact ) {
            CustomerContact customerContact = new CustomerContact();
            if( contact != null ) {
                customerContact.contactType = contact.Type__c;
                customerContact.firstName = contact.FirstName;
                customerContact.lastName = contact.LastName;
                customerContact.title = contact.Title;
            }
            customerContact.emails = wrapEmails( contact );
            customerContact.phones = wrapPhones( contact );
            return customerContact;
        }

        private List<CustomerEmail> wrapEmails( Schema.Contact contact ) {
            List<CustomerEmail> customerEmails = new List<CustomerEmail>();
            customerEmails.add( customerEmailWrapper.wrap( contact ) );
            return customerEmails;
        }

        private List<CustomerPhone> wrapPhones( Schema.Contact contact ) {
            List<CustomerPhone> customerPhones = new List<CustomerPhone>();
            customerPhones.add( customerPhoneWrapper.wrap( contact ) );
            return customerPhones;
        }
    }

    global virtual class CustomerPhoneWrapper {
        public virtual CustomerPhone wrap( Schema.Contact contact ) {
            CustomerPhone customerPhone = new CustomerPhone();
            if( contact != null ) {
                customerPhone.phoneExtension = contact.Phone_Extension__c;
                customerPhone.phoneNumber = contact.MobilePhone;
                customerPhone.phoneType = contact.Phone_Type__c;
                customerPhone.smsOptIn = contact.Sms_Optin__c;
            }
            return customerPhone;
        }
    }

    global virtual class CustomerEmailWrapper {
        public virtual CustomerEmail wrap( Schema.Contact contact ) {
            CustomerEmail customerEmail = new CustomerEmail();
            if( contact != null ) {
                customerEmail.address = contact.Email;
                customerEmail.emailType = contact.Email_Type__c;
            }
            return customerEmail;
        }
    }

    global virtual class VehicleWrapper {
        private RvInfoWrapper rvInfoWrapper;
        private TrailerInfoWrapper trailerInfoWrapper;

        public VehicleWrapper( RvInfoWrapper rvInfoWrapper, TrailerInfoWrapper trailerInfoWrapper ) {
            this.rvInfoWrapper = rvInfoWrapper;
            this.trailerInfoWrapper = trailerInfoWrapper;
        }

        public virtual Vehicle wrap( FSL_Member_Vehicle__c memberVehicle ) {
            Vehicle vehicle = new Vehicle();
            vehicle.color = memberVehicle.Vehicle_Color__c;
            vehicle.driveType = memberVehicle.Vehicle_Drive_Type__c;
            vehicle.fuelType = memberVehicle.Vehicle_Fuel_Type__c;
            vehicle.make = memberVehicle.Vehicle_Make__c;
            vehicle.model = memberVehicle.Vehicle_Model__c;
            vehicle.odometer = memberVehicle.Vehicle_Odometer__c != null ? memberVehicle.Vehicle_Odometer__c.intValue() : null;
            vehicle.rvInfo = rvInfoWrapper.wrap( memberVehicle );
            vehicle.specialEquipmentNeeds = memberVehicle.Vehicle_Special_Equipment_Needs__c;
            vehicle.state = memberVehicle.Vehicle_State__c;
            vehicle.tag = memberVehicle.Vehicle_Tag__c;
            vehicle.trailerInfo = trailerInfoWrapper.wrap( memberVehicle );
            vehicle.trim = memberVehicle.Vehicle_Trim__c;
            vehicle.vehicleType = memberVehicle.Vehicle_Type__c;
            vehicle.vin = memberVehicle.Vehicle_Vin__c;
            vehicle.year = memberVehicle.Vehicle_Year__c != null ? Integer.Valueof( memberVehicle.Vehicle_Year__c ) : null;
            return vehicle;
        }
    }
    
    global virtual class RvInfoWrapper {
        public virtual RvInfo wrap( FSL_Member_Vehicle__c memberVehicle ) {
            RvInfo rvInfo = new RvInfo();
            rvInfo.length = memberVehicle.RV_Length__c;
            rvInfo.rvClass = memberVehicle.RV_Class__c;
            return rvInfo;
        }
    }

    global virtual class TrailerInfoWrapper {
        public virtual TrailerInfo wrap( FSL_Member_Vehicle__c memberVehicle ) {
            TrailerInfo trailerInfo = new TrailerInfo();
            trailerInfo.hitchType = memberVehicle.Trailer_Hitchtype__c;
            trailerInfo.length = memberVehicle.Trailer_Length__c;
            return trailerInfo;
        }
    }
    
    global virtual class CallEventWrapper {
        private StatusDetailWrapper statusDetailWrapper;

        public CallEventWrapper( StatusDetailWrapper statusDetailWrapper ) {
            this.statusDetailWrapper = statusDetailWrapper;
        }

        public virtual CallEvent wrap( FSL_WorkOrder.WorkOrder workOrder, Datetime eventTime, String status, String reasonCode ) {
            WorkOrder wo = workOrder.getWorkOrder();
            CallEvent callEvent = new CallEvent();
            callEvent.callDate = wo.Call_Date__c;
            callEvent.callId = wo.Call_Id__c;
            callEvent.callKey = wo.External_Id__c;
            callEvent.eventTime = eventTime;
            callEvent.statusDetail = statusDetailWrapper.wrap( workOrder, status, reasonCode );
            return callEvent;
        }
    }

    public virtual class StatusDetailWrapper {
        private FacilityWrapper facilityWrapper;
        private TruckWrapper truckWrapper;
        private UpdatedByWrapper updatedByWrapper;

        public StatusDetailWrapper( FacilityWrapper facilityWrapper, TruckWrapper truckWrapper, UpdatedByWrapper updatedByWrapper ) {
            this.facilityWrapper = facilityWrapper;
            this.truckWrapper = truckWrapper;
            this.updatedByWrapper = updatedByWrapper;
        }

        public virtual StatusDetail wrap( FSL_WorkOrder.WorkOrder workOrder, String status, String reasonCode ) {
            FSL_ServiceAppointment.ServiceAppointment breakdownServiceAppointment = workOrder.getBreakDownServiceAppointment();
            FSL_AssignedResource.AssignedResource assignedResource = breakdownServiceAppointment.getAssignedResource();
            ServiceResource serviceResource = assignedResource != null ? assignedResource.getServiceResource() : null;
            StatusDetail statusDetail = new StatusDetail();
            statusDetail.eta = breakdownServiceAppointment.getServiceAppointment().SchedStartTime;
            statusDetail.facility = facilityWrapper.wrap( workOrder );
            statusDetail.reasonCode = reasonCode;
            statusDetail.status = status;
            statusDetail.truck = truckWrapper.wrap( serviceResource );
            statusDetail.updatedBy = updatedByWrapper.wrap();
            return statusDetail;
        }
    }

    public virtual class ServiceWrapper {
        private FacilityWrapper facilityWrapper;
        private PolicyWrapper policyWrapper;
        private ProvidedServiceWrapper providedServiceWrapper;
        private ServiceLocationWrapper serviceLocationWrapper;
        private StatusWrapper statusWrapper;
        private TroubleCodeWrapper troubleCodeWrapper;
        private TruckWrapper truckWrapper;

        public ServiceWrapper( FacilityWrapper facilityWrapper, PolicyWrapper policyWrapper, ProvidedServiceWrapper providedServiceWrapper, ServiceLocationWrapper serviceLocationWrapper, StatusWrapper statusWrapper, TroubleCodeWrapper troubleCodeWrapper, TruckWrapper truckWrapper ) {
            this.facilityWrapper = facilityWrapper;
            this.policyWrapper = policyWrapper;
            this.providedServiceWrapper = providedServiceWrapper;
            this.serviceLocationWrapper = serviceLocationWrapper;
            this.statusWrapper = statusWrapper;
            this.troubleCodeWrapper = troubleCodeWrapper;
            this.truckWrapper = truckWrapper;
        }

        public virtual Service wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            WorkOrder wo = workOrder.getWorkOrder();
            Service service = new Service();
            service.appointmentTime = wo.Non_Emergency_Appointment_Time__c;
            service.callType = wo.Call_Type__c;
            service.collision = wo.Collision__c;
            service.facility = facilityWrapper.wrap( workOrder );
            service.flatbedRequested = wo.Flatbed_Requested__c;
            service.legacyPriorityCode = wo.Legacy_Priority_Code__c;
            service.needsFlatbed = wo.Needs_Flatbed__c;
            service.numberOfPassengers = wo.Number_Of_Passengers__c != null ? wo.Number_Of_Passengers__c.intValue() : null;
            service.policies = wrapPolicies( wo.Policies__r );
            service.priorityCode = wo.Priority_Code__c;
            service.providedServices = wrapProvidedServices( wo.Service_Line_Items__r );
            service.redFlag = wo.Red_Flag__c;
            service.serviceLocations = wrapServiceLocations( workOrder );
            service.status = statusWrapper.wrap( workOrder );
            service.timezoneId = wo.Timezone_Id__c;
            service.timezoneOffset = wo.Timezone_Offset__c;
            service.troubleCodes = wrapTroubleCodes( wo.TroubleCodes__r, wo.Resolution_Code__c );
            service.truck = wrapTruck( workOrder );
            return service;
        }

        private List<Policy> wrapPolicies( List<FSL_Policy__c> workOrderPolicies ) {
            List<Policy> policies = new List<Policy>();
            for( FSL_Policy__c workOrderPolicy : workOrderPolicies ) {
                policies.add( policyWrapper.wrap( workOrderPolicy ) );
            }
            return policies;
        }

        private List<ProvidedService> wrapProvidedServices( List<FSL_Service_Line_Item__c> serviceLineItems ) {
            List<ProvidedService> providedServices = new List<ProvidedService>();
            for( FSL_Service_Line_Item__c serviceLineItem : serviceLineItems ) {
                providedServices.add( providedServiceWrapper.wrap( serviceLineItem ) );
            }
            return providedServices;
        }

        private List<ServiceLocation> wrapServiceLocations( FSL_WorkOrder.WorkOrder workOrder ) {
            List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = workOrder.getServiceAppointments();
            WorkOrder wo = workOrder.getWorkOrder();
            List<ServiceLocation> serviceLocations = new List<ServiceLocation>();
            for( FSL_ServiceAppointment.ServiceAppointment serviceAppointment : serviceAppointments ) {
                serviceLocations.add( serviceLocationWrapper.wrap( serviceAppointment, wo ) );
            }
            return serviceLocations;
        }

        private List<TroubleCode> wrapTroubleCodes( List<FSL_TroubleCode__c> workOrderTroubleCodes, string resolutionCode ) {
            List<TroubleCode> troubleCodes = new List<TroubleCode>();
            for( FSL_TroubleCode__c workOrderTroubleCode : workOrderTroubleCodes ) {
                troubleCodes.add( troubleCodeWrapper.wrap( workOrderTroubleCode ) );
            }
            if( resolutionCode != null ) {
                troubleCodes.add( troubleCodeWrapper.wrap( resolutionCode ) );
            }
            return troubleCodes;
        }

        private Truck wrapTruck( FSL_WorkOrder.WorkOrder workOrder ) {
            FSL_ServiceAppointment.ServiceAppointment breakdownServiceAppointment = workOrder.getBreakDownServiceAppointment();
            FSL_AssignedResource.AssignedResource assignedResource = breakdownServiceAppointment.getAssignedResource();
            ServiceResource serviceResource = assignedResource != null ? assignedResource.getServiceResource() : null;
            return truckWrapper.wrap( serviceResource );
        }
    }
    
    public virtual class StatusWrapper {
        public virtual Status wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            WorkOrder wo = workOrder.getWorkOrder();
            FSL_ServiceAppointment.ServiceAppointment serviceAppointment = workOrder.getBreakDownServiceAppointment();
            ServiceAppointment sa = serviceAppointment.getServiceAppointment();
            Datetime statusTimestamp = workOrder.getStatusTimestamp();
            Status status = new Status();
            status.eta = sa.ETA__c != null ? sa.ETA__c.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' ) : null;
            status.modifiedDate = statusTimestamp != null ? statusTimestamp.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' ) : null;
            status.pta = String.isNotBlank( String.valueOfGmt( wo.Pta__c ) ) ? wo.Pta__c.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' ) : null;
            status.scheduleStartTime = sa.SchedStartTime != null ? sa.SchedStartTime.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' ) : null;
            status.status = sa.Status;
            status.waitTime = wo.Wait_Time__c != null ? wo.Wait_Time__c.intValue() : null;
            return status;
        }
    }
    
    public virtual class FacilityWrapper {
        private LocationWrapper locationWrapper;

        public FacilityWrapper( LocationWrapper locationWrapper ) {
            this.locationWrapper = locationWrapper;
        }

        public virtual Facility wrap( FSL_WorkOrder.WorkOrder workOrder ) {
            FSL_ServiceAppointment.ServiceAppointment breakdownServiceAppointment = workOrder.getBreakDownServiceAppointment();
            ServiceAppointment sa = breakdownServiceAppointment.getServiceAppointment();
            WorkOrder wo = workOrder.getWorkOrder();
            Facility facility = new Facility();
            facility.foiType = 'ADDRESS';
            facility.id = String.isNotBlank( sa.ServiceTerritory.Facility_Number__c ) ? sa.ServiceTerritory.Facility_Number__c : wo.Account.Facility_ID__c;
            facility.location = locationWrapper.wrap();
            facility.name = String.isNotBlank( sa.ServiceTerritory.Facility_Number__c ) ? sa.ServiceTerritory.Name : wo.Account.Name;
            return facility;
        }
    }

    public virtual class LocationWrapper {
        public virtual FSL_WorkOrderJsonWrapper.Location wrap() {
            FSL_WorkOrderJsonWrapper.Location location = new FSL_WorkOrderJsonWrapper.Location();
            return location;
        }
    }

    public virtual class TruckWrapper {
        private DriverWrapper driverWrapper;

        public TruckWrapper( DriverWrapper driverWrapper ) {
            this.driverWrapper = driverWrapper;
        }

        public virtual Truck wrap( ServiceResource serviceResource ) {
            Truck truck = new Truck();
            truck.driver = driverWrapper.wrap( serviceResource );
            truck.id = serviceResource != null ? serviceResource.Vehicle__r.Truck_ID__c : null;
            return truck;
        }
    }

    public virtual class DriverWrapper {
        private DriverContactWrapper driverContactWrapper;
        
        public DriverWrapper( DriverContactWrapper driverContactWrapper ) {
            this.driverContactWrapper = driverContactWrapper;
        }

        public virtual Driver wrap( ServiceResource serviceResource ) {
            Driver driver = new Driver();
            if( serviceResource != null ) {
                driver.id = String.isNotBlank( serviceResource.Driver_Id__c ) ? serviceResource.Driver_Id__c : '';
                driver.contact = driverContactWrapper.wrap( serviceResource );
            }
            return driver;
        }
    }

    public virtual class DriverContactWrapper {
        public virtual DriverContact wrap( ServiceResource serviceResource ) {
            DriverContact driverContact = new DriverContact();
            driverContact.contactType = 'DRIVER';
            driverContact.lastName = serviceResource.Name;
            return driverContact;
        }
    }

    public virtual class TroubleCodeWrapper {
        public virtual TroubleCode wrap( FSL_TroubleCode__c tc ) {
            TroubleCode troubleCode = new TroubleCode();
            troubleCode.code = tc.Code__c;
            troubleCode.description = tc.Description__c;
            troubleCode.troubleCodeType = tc.Type__c;
            return troubleCode;
        }

        public virtual TroubleCode wrap( String resolutionCode ) {
            TroubleCode troubleCode = new TroubleCode();
            troubleCode.code = resolutionCode;
            troubleCode.description = '';
            troubleCode.troubleCodeType = 'RESOLUTION';
            return troubleCode;
        }
    }

    public virtual class ServiceLocationWrapper {
        private FoiWrapper foiWrapper;

        public ServiceLocationWrapper( FoiWrapper foiWrapper ) {
            this.foiWrapper = foiWrapper;
        }

        public virtual ServiceLocation wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            ServiceAppointment sa = serviceAppointment.getServiceAppointment();
            ServiceLocation serviceLocation = new ServiceLocation();
            serviceLocation.dropBoxInfo = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ? sa.Drop_Box_Info__c : null;
            serviceLocation.foi = foiWrapper.wrap( serviceAppointment, workOrder );
            serviceLocation.mileageCalculated = sa.FSL_Actual_Miles_Driven__c != null ? sa.FSL_Actual_Miles_Driven__c.round( System.RoundingMode.HALF_UP ).intValue() : null;
            serviceLocation.serviceLocationType = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ? 'BREAKDOWN' : serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ? 'TOW_DESTINATION' : null;
            return serviceLocation;
        }
    }
    
    public virtual class FoiWrapper {
        private BreakdownLocationWrapper breakdownLocationWrapper;
        private ContactWrapper contactWrapper;

        public FoiWrapper( BreakdownLocationWrapper breakdownLocationWrapper, ContactWrapper contactWrapper ) {
            this.breakdownLocationWrapper = breakdownLocationWrapper;
            this.contactWrapper = contactWrapper;
        }

        public virtual Foi wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            Foi foi = new Foi();
            foi.contacts = wrapContacts( serviceAppointment, workOrder );
            foi.foiType = 'ADDRESS';
            foi.location = breakdownLocationWrapper.wrap( serviceAppointment, workOrder );
            foi.name = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ? serviceAppointment.getServiceAppointment().Tow_Destination_Name__c : null;
            return foi;
        }

        private List<FSL_WorkOrderJsonWrapper.Contact> wrapContacts( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            List<FSL_WorkOrderJsonWrapper.Contact> contacts = new List<FSL_WorkOrderJsonWrapper.Contact>();
            if( serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ) {
                contacts.add( contactWrapper.wrap( workOrder ) );
            }
            return contacts;
        }
    }

    public virtual class BreakdownLocationWrapper {
        private BreakdownAddressWrapper breakdownAddressWrapper;

        public BreakdownLocationWrapper( BreakdownAddressWrapper breakdownAddressWrapper ) {
            this.breakdownAddressWrapper = breakdownAddressWrapper;
        }

        public virtual BreakdownLocation wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            ServiceAppointment sa = serviceAppointment.getServiceAppointment();
            BreakdownLocation breakdownLocation = new BreakdownLocation();
            breakdownLocation.address = breakdownAddressWrapper.wrap( serviceAppointment );
            breakdownLocation.highway = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ? sa.Highway__c : null;
            breakdownLocation.landmark = sa.Landmark__c;
            breakdownLocation.driverInstructions = sa.Driving_Directions__c;
            breakdownLocation.latitude = wrapLatitude( serviceAppointment, workOrder );
            breakdownLocation.locationCode = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ? sa.Location_Code__c : null;
            breakdownLocation.longitude = wrapLongitude( serviceAppointment, workOrder );
            breakdownLocation.mileMarker = serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ? sa.Mile_Marker__c : null;
            return breakdownLocation;
        }

        private Double wrapLatitude( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            Double latitude = null;
            if( serviceAppointment.hasAddressChanged() ) {
                latitude = serviceAppointment.getServiceAppointment().Latitude;
            }
            else if( serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ) {
                latitude = workOrder.Breakdown_Location__Latitude__s;
            }
            else if( serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ) {
                latitude = workOrder.Tow_Location__Latitude__s;
            }
            return latitude;
        }

        private Double wrapLongitude( FSL_ServiceAppointment.ServiceAppointment serviceAppointment, WorkOrder workOrder ) {
            Double longitude = null;
            if( serviceAppointment.hasAddressChanged() ) {
                longitude = serviceAppointment.getServiceAppointment().Longitude;
            }
            else if( serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ) {
                longitude = workOrder.Breakdown_Location__Longitude__s;
            }
            else if( serviceAppointment.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ) {
                longitude = workOrder.Tow_Location__Longitude__s;
            }
            return longitude;
        }
    }

    public virtual class BreakdownAddressWrapper {
        public virtual BreakdownAddress wrap( FSL_ServiceAppointment.ServiceAppointment serviceAppointment ) {
            ServiceAppointment sa = serviceAppointment.getServiceAppointment();
            BreakdownAddress breakdownAddress = new BreakdownAddress();
            breakdownAddress.addressType = 'PHYSICAL';
            breakdownAddress.city = sa.City;
            breakdownAddress.country = sa.Country;
            breakdownAddress.crossStreet = sa.Cross_Street__c;
            breakdownAddress.crossStreet2 = sa.Cross_Street_2__c;
            breakdownAddress.full = serviceAppointment.getFullAddress();
            breakdownAddress.postalCode = sa.PostalCode;
            breakdownAddress.state = sa.State;
            breakdownAddress.streetName = sa.Street;
            return breakdownAddress;
        }
    }

    public virtual class ContactWrapper {
        private ContactPhoneWrapper contactPhoneWrapper;

        public ContactWrapper( ContactPhoneWrapper contactPhoneWrapper ) {
            this.contactPhoneWrapper = contactPhoneWrapper;
        }

        public virtual FSL_WorkOrderJsonWrapper.Contact wrap( WorkOrder workOrder ) {
            FSL_WorkOrderJsonWrapper.Contact contact = new FSL_WorkOrderJsonWrapper.Contact();
            contact.contactType = 'TOWDEST';
            contact.firstName = workOrder.Tow_Contact_First_Name__c;
            contact.lastName = workOrder.Tow_Contact_Last_Name__c;
            contact.phones = wrapPhones( workOrder );
            return contact;
        }

        private List<ContactPhone> wrapPhones( WorkOrder workOrder ) {
            List<ContactPhone> phones = new List<ContactPhone>();
            if( workOrder.Tow_Contact_Phone_Number__c != null ) {
                phones.add( contactPhoneWrapper.wrap( workOrder ) );
            }
            return phones;
        }
    }

    public virtual class ContactPhoneWrapper {
        public virtual ContactPhone wrap( WorkOrder workOrder ) {
            ContactPhone phone = new ContactPhone();
            phone.phoneNumber = workOrder.Tow_Contact_Phone_Number__c;
            phone.phoneType = 'BUSINESS';
            return phone;
        }
    }

    public virtual class PolicyWrapper {
        public virtual Policy wrap( FSL_Policy__c workOrderPolicy ) {
            Policy policy = new Policy();
            policy.code = workOrderPolicy.Policy_Code__c;
            policy.description = workOrderPolicy.Policy_Description__c;
            return policy;
        }
    }

    public virtual class ProvidedServiceWrapper {
        private ChargeWrapper chargeWrapper;

        public ProvidedServiceWrapper( ChargeWrapper chargeWrapper ) {
            this.chargeWrapper = chargeWrapper;
        }

        public virtual ProvidedService wrap( FSL_Service_Line_Item__c serviceLineItem ) {
            ProvidedService providedService = new ProvidedService();
            providedService.charge = chargeWrapper.wrap( serviceLineItem );
            providedService.quantity = serviceLineItem.Unit__c != null ? serviceLineItem.Unit__c.intValue() : 0;
            providedService.service = serviceLineItem.Product__r.ProductCode;
            return providedService;
        }
    }

    public virtual class ChargeWrapper {
        public virtual Charge wrap( FSL_Service_Line_Item__c serviceLineItem ) {
            Charge charge = new Charge();
            charge.amount = String.valueOf( serviceLineItem.Cost__c );
            return charge;
        }
    }

    public virtual class PaymentWrapper {
        public virtual Payment wrap( WorkOrder workOrder ) {
            Payment payment = new Payment();
            for( ServiceAppointment sa: workOrder.ServiceAppointments){
                if( sa.isBreakdown__c ) {
                    payment.paymentType = sa.Payment_Type__c;
                    payment.required = sa.Payment_Required__c;
                }
            }
            payment.codes = workOrder.Payment_Codes__c;
            return payment;
        }
    }

    public virtual class CommentWrapper {
        private CommentContactWrapper commentContactWrapper;
        private SourceSystemWrapper sourceSystemWrapper;

        public CommentWrapper( CommentContactWrapper commentContactWrapper, SourceSystemWrapper sourceSystemWrapper ) {
            this.commentContactWrapper = commentContactWrapper;
            this.sourceSystemWrapper = sourceSystemWrapper;
        }

        public virtual Comment wrap( FSL_Call_Comments__c callComment, FSL_ServiceSettings__c serviceSetting ) {
            Comment comment = new Comment();
            comment.commentDate = callComment.CreatedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
            comment.commentType = 'NORMAL';
            comment.contact = commentContactWrapper.wrap( callComment );
            comment.system_Z = sourceSystemWrapper.wrap( serviceSetting );
            comment.text = callComment.FSL_Comment__c;
            comment.visibility = 'EXTERNAL';
            return comment;
        }

        public virtual Comment wrap( FeedItem feedItem, FSL_ServiceSettings__c serviceSetting ) {
            Comment comment = new Comment();
            comment.commentDate = feedItem.LastModifiedDate.formatGmt( 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' );
            comment.commentType = 'NORMAL';
            comment.contact = commentContactWrapper.wrap( feedItem );
            comment.system_Z = sourceSystemWrapper.wrap( serviceSetting );
            comment.text = feedItem.Body.stripHtmlTags();
            comment.visibility = 'EXTERNAL';
            return comment;
        }
    }

    public virtual class CommentContactWrapper {
        private final String DEFAULT_USER_ID = 'S999999';

        public virtual CommentContact wrap( FSL_Call_Comments__c callComment ) {
            CommentContact commentContact = new CommentContact();
            commentContact.contactType = 'SYSTEM';
            commentContact.userId = String.isNotBlank( callComment.CreatedBy.EmployeeNumber ) ? callComment.CreatedBy.EmployeeNumber : DEFAULT_USER_ID;
            return commentContact;
        }

        public virtual CommentContact wrap( FeedItem feedItem ) {
            CommentContact commentContact = new CommentContact();
            commentContact.contactType = 'SYSTEM';
            commentContact.userId = feedItem.InsertedBy.Name;
            return commentContact;
        }
    }

    public virtual class UpdatedByWrapper {
        public virtual UpdatedBy wrap() {
            UpdatedBy updatedBy = new UpdatedBy();
            updatedBy.contactType = 'SYSTEM';
            return updatedBy;
        }
    }

    public virtual class SourceSystemWrapper {
        private SystemOrganizationWrapper systemOrganizationWrapper;
        public SourceSystemWrapper( SystemOrganizationWrapper systemOrganizationWrapper ) {
            this.systemOrganizationWrapper = systemOrganizationWrapper;
        }

        public virtual SourceSystem wrap( FSL_ServiceSettings__c serviceSetting ) {
            SourceSystem sourceSystem = new SourceSystem();
            sourceSystem.systemId = serviceSetting.Source_System_ID__c;
            sourceSystem.systemOrganization = systemOrganizationWrapper.wrap( serviceSetting );
            return sourceSystem;
        }

        public virtual SourceSystem wrap( WorkOrder workOrder ) {
            SourceSystem sourceSystem = new SourceSystem();
            sourceSystem.systemId = '';
            sourceSystem.systemOrganization = systemOrganizationWrapper.wrap( workOrder );
            return sourceSystem;
        }
    }

    public virtual class SystemOrganizationWrapper {
        public virtual SystemOrganization wrap( Schema.Contact contact ) {
            SystemOrganization systemOrganization = new SystemOrganization();
            if( contact != null ) {
                systemOrganization.code = contact.Membership_OrgCode__c;
                systemOrganization.name = contact.Membership_Org__c;
            }
            return systemOrganization;
        }

        public virtual SystemOrganization wrap( FSL_ServiceSettings__c serviceSetting ) {
            SystemOrganization systemOrganization = new SystemOrganization();
            systemOrganization.code = serviceSetting.Source_System_Org_Code__c;
            systemOrganization.name = serviceSetting.Source_System_Org_Name__c;
            return systemOrganization;
        }

        public virtual SystemOrganization wrap( WorkOrder workOrder ) {
            SystemOrganization systemOrganization = new SystemOrganization();
            systemOrganization.code = workOrder.Call_Origin_OrgCode__c;
            systemOrganization.name = workOrder.Call_Origin_OrgName__c;
            return systemOrganization;
        }
    }

    // *********************************************
    // * JSON PAYLOAD STRUCTURE
    // *********************************************
    
    global class WorkOrderJson {
        public String id {get;set;}
        public String requestEventType {get;set;}
        public String subType {get;set;}
        public String version {get;set;}
        public List<Call> calls {get;set;}
        public Integer statusCode {get;set;}
        public String statusDescription {get;set;}
    }

    global class Call {
        public String callKey {get;set;}
        public String callDate {get;set;}
        public String callId {get;set;}
        public Long createDate {get;set;}
        public String requestingSystemCallId {get;set;}
        public Channel channel {get;set;}
        public Customer customer {get;set;}
        public Vehicle vehicle {get;set;}
        public Service service {get;set;}
        public Payment payment {get;set;}
        public List<Comment> comments {get;set;}
        public List<CallEvent> callEvents {get;set;}
        public SourceSystem sourceSystem {get;set;}
        public SourceSystem targetSystem {get;set;}
    }

    global class Channel {
        public String channelType {get;set;}
        public SystemOrganization org {get;set;}
        public ChannelContact contact {get;set;}
        public ChannelLocation location {get;set;}
    }

    global class ChannelContact {
        public String userId {get;set;}
        public String contactType {get;set;}
    }

    global class ChannelLocation {
        public LocationAddress address {get;set;}
    }

    global class LocationAddress {
        public String addressType {get;set;}
        public String full {get;set;}
        public String streetNumber {get;set;}
        public String streetDirection {get;set;}
        public String streetName {get;set;}
        public String crossStreet {get;set;}
        public String city {get;set;}
        public String county {get;set;}
        public String state {get;set;}
        public String postalCode {get;set;}
        public String country {get;set;}
    }

    global class Customer {
        public List<Membership> memberships {get;set;}
        public CustomerContact contact {get;set;}
        public String languagePreference {get;set;}
    }

    global class Membership {
        public String membershipType {get;set;}
        public String sponsor {get;set;}
        public String program {get;set;}
        public String authorizationCode {get;set;}
        public String authorizationLevel {get;set;}
        public Boolean isLocalClub {get;set;}
        public SystemOrganization org {get;set;}
        public String id {get;set;}
        public String originalMemberId {get;set;}
        public String expirationDate {get;set;}
        public String memberLevel {get;set;}
        public String memberBirthday {get;set;}
        public String memberSince {get;set;}
        public String memberStatus {get;set;}
        public List<Entitlement> entitlements {get;set;}
    }

    global class Entitlement {
    }

    global class CustomerContact {
        public String contactType {get;set;}
        public String title {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public List<CustomerPhone> phones {get;set;}
        public List<CustomerEmail> emails {get;set;}
    }

    global class CustomerPhone {
        public String phoneType {get;set;}
        public String phoneNumber {get;set;}
        public String phoneExtension {get;set;}
        public Boolean smsOptIn {get;set;}
    }

    global class CustomerEmail {
        public String emailType {get;set;}
        public String address {get;set;}
    }

    global class Vehicle {
        public String vehicleType {get;set;}
        public Integer year {get;set;}
        public String make {get;set;}
        public String model {get;set;}
        public String trim {get;set;}
        public String color {get;set;}
        public String driveType {get;set;}
        public String vin {get;set;}
        public String tag {get;set;}
        public String state {get;set;}
        public Integer odometer {get;set;}
        public String fuelType {get;set;}
        public RvInfo rvInfo {get;set;}
        public TrailerInfo trailerInfo {get;set;}
        public String specialEquipmentNeeds {get;set;}
    }

    global class RvInfo {
        public String rvClass {get;set;}
        public Double length {get;set;}
    }

    global class TrailerInfo {
        public String hitchType {get;set;}
        public Double length {get;set;}
    }

    global class Service {
        public String callType {get;set;}
        public String timezoneId {get;set;}
        public String timezoneOffset {get;set;}
        public Status status {get;set;}
        public String appointmentTime {get;set;}
        public Facility facility {get;set;}
        public Truck truck {get;set;}
        public List<TroubleCode> troubleCodes {get;set;}
        public List<ServiceLocation> serviceLocations {get;set;}
        public Boolean collision {get;set;}
        public Boolean redFlag {get;set;}
        public String priorityCode {get;set;}
        public String legacyPriorityCode {get;set;}
        public Integer numberOfPassengers {get;set;}
        public Boolean needsFlatbed {get;set;}
        public Boolean flatbedRequested {get;set;}
        public List<Policy> policies {get;set;}
        public List<ProvidedService> providedServices {get;set;}
    }

    global class Status {
        public String status {get;set;}
        public String modifiedDate {get;set;}
        public String eta {get;set;}
        public String pta {get;set;}
        public Integer waitTime {get;set;}
        public String scheduleStartTime {get;set;}
    }

    global class Facility {
        public String foiType {get;set;}
        public FSL_WorkOrderJsonWrapper.Location location {get;set;}
        public String id {get;set;}
        public String name {get;set;}
    }

    global class Location {
    }

    global class Truck {
        public String id {get;set;}
        public Driver driver {get;set;}
    }

    global class Driver {
        public String id {get;set;}
        public DriverContact contact {get;set;}
    }

    global class DriverContact {
        public String contactType {get;set;}
        public String lastName {get;set;}
    }

    global class TroubleCode {
        public String troubleCodeType {get;set;}
        public String code {get;set;}
        public String description {get;set;}
    }

    global class ServiceLocation {
        public String serviceLocationType {get;set;}
        public Foi foi {get;set;}
        public Integer mileageCalculated {get;set;}
        public String dropBoxInfo {get;set;}
    }

    global class Foi {
        public String foiType {get;set;}
        public BreakdownLocation location {get;set;}
        public String name {get;set;}
        public List<FSL_WorkOrderJsonWrapper.Contact> contacts {get;set;}
    }

    global class BreakdownLocation {
        public Double latitude {get;set;}
        public Double longitude {get;set;}
        public BreakdownAddress address {get;set;}
        public String landmark {get;set;}
        public String driverInstructions {get;set;}
        public String highway {get;set;}
        public String mileMarker {get;set;}
        public String locationCode {get;set;}
    }

    global class BreakdownAddress {
        public String addressType {get;set;}
        public String full {get;set;}
        public String streetName {get;set;}
        public String crossStreet {get;set;}
        public String crossStreet2 {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String postalCode {get;set;}
        public String country {get;set;}
    }

    global class Contact {
        public String contactType {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public List<ContactPhone> phones {get;set;}
    }

    global class ContactPhone {
        public String phoneType {get;set;}
        public String phoneNumber {get;set;}
    }

    global class Policy {
        public String code {get;set;}
        public String description {get;set;}
    }

    global class ProvidedService {
        public String service {get;set;}
        public Integer quantity {get;set;}
        public Charge charge {get;set;}
    }

    global class Charge {
        public String amount {get;set;}
    }

    global class Payment {
        public Boolean required {get;set;}
        public String paymentType {get;set;}
        public String codes {get;set;}
    }

    global class Comment {
        public SourceSystem system_Z {get;set;}
        public CommentContact contact {get;set;}
        public String commentDate {get;set;}
        public String commentType {get;set;}
        public String visibility {get;set;}
        public String text {get;set;}
    }

    global class CommentContact {
        public String userId {get;set;}
        public String contactType {get;set;}
    }

    global class CallEvent {
        public String callKey {get;set;}
        public String callDate {get;set;}
        public String callId {get;set;}
        public Datetime eventTime {get;set;}
        public StatusDetail statusDetail {get;set;}
    }

    global class StatusDetail {
        public String status {get;set;}
        public String reasonCode {get;set;}
        public UpdatedBy updatedBy {get;set;}
        public Datetime eta {get;set;}
        public Facility facility {get;set;}
        public Truck truck {get;set;}
    }

    global class UpdatedBy {
        public String contactType {get;set;}
    }

    global class SourceSystem {
        public String systemId {get;set;}
        public SystemOrganization systemOrganization {get;set;}
    }

    global class SystemOrganization {
        public String name {get;set;}
        public String code {get;set;}
    }
}