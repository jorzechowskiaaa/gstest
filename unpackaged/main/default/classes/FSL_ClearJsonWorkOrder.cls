/**
 * @File Name          : FSL_ClearJsonWorkOrder.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 12-22-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/29/2020   Rajesh Kemisetti     Initial Version
 *       12/22/2020   Clement Shiu        ERS-220799: RAP calls cleared in FSL are going back to IRAS/D3 without a facility id and without RAP id
**/
global class FSL_ClearJsonWorkOrder {
    
    public String id {get;set;} 
    public String memberId {get;set;} 
    public String ANI {get;set;} 
    public String requestEventType {get;set;} 
    public String subType {get;set;} 
    public String status {get;set;} 
    public String version {get;set;} 
    public SourceSystem sourceSystem {get;set;} 
    public SourceSystem targetSystem {get;set;} 
    public Long createDate {get;set;} 
    public List<Calls> calls {get;set;}
    public ResponseWrapper respWrap {get;set;}
    public List<CallEvent> callEvents {get;set;}    
    public HeaderWrapper header {get; set;}
    public String statusDescription {get;set;}
    public Integer statusCode {get;set;}
    
    public class ResponseWrapper {
        public String id {get;set;}      
        public String statusDescription {get;set;}
        public Integer statusCode {get;set;}       
    }
    public class HeaderWrapper {
        public String version {get;set;}
        public String type {get;set;}        
        public String subType {get;set;}
        public String status {get;set;}
        public String id {get;set;}
    }
    public class Calls {
        public String callKey {get;set;} 
        public String callDate {get;set;} 
        public String callId {get;set;} 
        public String requestingSystemCallId {get;set;}
        public String version {get;set;} 
        public Channel channel {get;set;} 
        public Customer customer {get;set;} 
        public Vehicle vehicle {get;set;} 
        public Service service {get;set;} 
        public Payment payment {get;set;} 
        public List<Comments> comments {get;set;} 
    }
    public class Channel {
        public String channelType {get;set;} 
        public SystemOrganization org {get;set;} 
        public Channel_Contact contact {get;set;} 
        public Channel_Location location {get;set;} 
    }
    public class Customer {
        public List<Memberships> memberships {get;set;} 
        public Customer_Contact contact {get;set;} 
        public String languagePreference {get;set;} 
    
    }
        
    public class Vehicle {
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
        
    
    public class Service {
        public String callType {get;set;} 
        public String timezoneId {get;set;} 
        public String timezoneOffset {get;set;} 
        public Status status {get;set;} 
        public String appointmentTime {get;set;} 
        public Facility facility {get;set;} 
        public Truck truck {get;set;} 
        public List<TroubleCodes> troubleCodes {get;set;} 
        public List<ServiceLocations> serviceLocations {get;set;} 
        public Boolean collision {get;set;} 
        public Boolean redFlag {get;set;} 
        public String priorityCode {get;set;} 
        public String legacyPriorityCode {get;set;} 
        public Integer numberOfPassengers {get;set;} 
        public Boolean needsFlatbed {get;set;} 
        public Boolean flatbedRequested {get;set;} 
        public List<Policies> policies {get;set;} 
        public List<ProvidedServices> providedServices {get;set;} 
        public List<Charge> charges {get;set;} 
        
    }
    public class Payment {
        public Boolean required {get;set;} 
        public String paymentType {get;set;} 
        public String codes {get;set;} 
    }
    public class Comments {
        public SourceSystem system_Z {get;set;} 
        public Comments_Contact contact {get;set;} 
        public String commentDate {get;set;} 
        public String commentType {get;set;} 
        public String visibility {get;set;} 
        public String text {get;set;} 
    }
    public class Comments_Contact {
        public String userId {get;set;} 
        public String contactType {get;set;} 
    }
    public class Channel_Contact {
        public String userId {get;set;} 
        public String contactType {get;set;} 
    }
    
    public class Channel_Location {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public Location_Address address {get;set;} 
    }
    public class Location_Address {
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
    public class Memberships {
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
        public List<Entitlements> entitlements {get;set;} 
    }
    
    public class Customer_Contact {
        public String contactType {get;set;} 
        public String title {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Customer_Phone> phones {get;set;} 
        public List<Customer_Email> emails {get;set;} 

    }
    public class SourceSystem {
        public String systemId {get;set;} 
        public SystemOrganization systemOrganization {get;set;} 
    }
    public class SystemOrganization {
        public String name {get;set;} 
        public String code {get;set;}
    }
    
    public class RvInfo {
        public String rvClass {get;set;} 
        public String engineLocation {get;set;} 
        public Boolean gooseNeck {get;set;} 
        public Double height {get;set;} 
        public Double length {get;set;} 
        public Integer weight {get;set;} 
        public Boolean towing {get;set;} 
        public String towingType {get;set;} 
    }
    
    public class TrailerInfo {
        public Integer axles {get;set;} 
        public String condition {get;set;} 
        public Boolean gooseNeck {get;set;} 
        public Double hitchSize {get;set;} 
        public String hitchType {get;set;} 
        public Double length {get;set;} 
        public String loaded {get;set;} 
        public String loadType {get;set;} 
        public String loadWeight {get;set;} 
        public String plugType {get;set;} 
        public String trailerType {get;set;} 
    }
    public class Facility {
        public String foiType {get;set;} 
        public Location_z location {get;set;} 
        public String id {get;set;} 
        public String name {get;set;} 
    }
    public class Truck {
        public String id {get;set;} 
        public Driver driver {get;set;} 
    }
    public class TroubleCodes {
        public String troubleCodeType {get;set;} 
        public String code {get;set;} 
        public String description {get;set;} 
    }
    public class ServiceLocations {
        public String serviceLocationType {get;set;} 
        public Foi foi {get;set;}
        //public Foi_TowDest foi_towDest {get;set;}       
        public Integer mileageCalculated {get;set;} 
        public String driverDirections {get;set;} 
        public String dropBoxInfo {get;set;} 
    }
    public class Policies {
        public String code {get;set;} 
        public String description {get;set;} 
    }
    public class ProvidedServices {
        public String providedServiceType {get;set;} 
        public String service {get;set;} 
        public String unit {get;set;} 
        public Integer quantity {get;set;} 
        public Charge charge {get;set;} 
    }
        
    public class Charge {
        public String chargeType {get;set;} 
        public String amount {get;set;} 
    }
    
    public class Location_Z {}
    
    public class Driver {
        public String id {get;set;} 
        public Driver_Contact contact {get;set;} 

    }
    public class Driver_Contact {
        public String contactType {get;set;} 
        public String lastName {get;set;} 
    }
    public class Foi {
        public String foiType {get;set;} 
        public Breakdown_Location location {get;set;}
        public String id {get;set;}
        public String name {get;set;}
        public List<Contacts> contacts {get;set;}
    }
    
    public class Breakdown_Location {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public BreakdownAddress address {get;set;} 
        public String landmark {get;set;} 
        public String highway {get;set;} 
        public String mileMarker {get;set;} 
        public String grid {get;set;} 
        public String zone {get;set;} 
        public String locationCode {get;set;} 

    }
    
    public class BreakdownAddress {
        public String addressType {get;set;} 
        public String full {get;set;} 
        public String streetNumber {get;set;} 
        public String streetDirection {get;set;} 
        public String streetName {get;set;} 
        public String crossStreet {get;set;} 
        public String crossStreet2 {get;set;} 
        public String city {get;set;} 
        public String county {get;set;} 
        public String state {get;set;} 
        public String postalCode {get;set;} 
        public String country {get;set;} 

        
    }
    public class Foi_TowDest {
        public TowDest_Location location {get;set;} 
        public String name {get;set;} 
        public List<Contacts> contacts {get;set;}
         
    }
    public class TowDest_Location {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public TowAddress address {get;set;} 
        public String landmark {get;set;} 
    }
    
    public class TowAddress {
        public String addressType {get;set;} 
        public String full {get;set;} 
        public String streetNumber {get;set;} 
        public String streetName {get;set;} 
        public String crossStreet {get;set;} 
        public String city {get;set;} 
        public String county {get;set;} 
        public String state {get;set;} 
        public String postalCode {get;set;} 
        public String country {get;set;}
    }
    
    public class Contacts {
        public String contactType {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Contact_Phones> phones {get;set;} 

    }
    public class Contact_Phones {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} 
        public Boolean preferred {get;set;} 
    }
    public class Customer_Phone {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} 
        public String phoneExtension {get;set;} 
        public Boolean preferred {get;set;} 
        public Boolean smsOptIn {get;set;} 
    }
    
    public class Customer_Email {
        public String emailType {get;set;} 
        public String address {get;set;} 
    }
    
    public class Status {
        public String status {get;set;} 
        public String modifiedDate {get;set;} 
        public String eta {get;set;} 
        public String pta {get;set;} 
        public Integer waitTime {get;set;} 
        public string scheduleStartTime {get;set;} 
    }
    
    public class Entitlements {
        public Boolean serviceChargeIndicator {get;set;} 

    }
    
    public class CallEvent {
        public String callKey {get;set;}
        public String callDate {get;set;}
        public String callId {get;set;}
        public Datetime eventTime {get;set;}
        public StatusDetail statusDetail {get;set;}
        public CallEvent(){}
        public CallEvent(String callKey, String callDate, String callId, Datetime eventTime) {
            this.callKey = callKey;
            this.callDate = callDate;
            this.callId = callId;
            this.eventTime = eventTime;
        }
    } 
    
    public class StatusDetail {
        public String status {get;set;}
        public String reasonCode {get;set;}
        public UpdatedBy updatedBy {get;set;}
        public Datetime eta {get;set;}
        //public String version {get;set;}
        public Facility facility {get;set;}
        public Truck truck {get;set;}
        public StatusDetail (){}
        public StatusDetail (String status, String reasonCode, UpdatedBy updatedBy, Facility facility, Truck truck, Datetime eta, String version) {
            this.status     = status;
            this.reasonCode = reasonCode;
            this.updatedBy  = updatedBy;
            this.eta        = eta;
            //this.version    = version;
            this.facility   = facility;
            this.truck      = truck;
        }
    }
    
    public class UpdatedBy {
        public String contactType {get;set;}
        public UpdatedBy(String contactType) {
            this.contactType = contactType;
        }
    }
    

    
    /*public class Foi_Z {
        public String foiType {get;set;} 
        public Location_X location {get;set;} 
        public String name {get;set;} 
        public List<Contacts> contacts {get;set;} 

    }*/
    
    
}