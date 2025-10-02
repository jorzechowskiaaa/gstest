/**
 * @File Name          : FSL_JSonParserWorkOrder.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/16/2020, 4:36:25 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
 *    09/30/2020    Dylan Truong       ERS-219581 -- FSL Timeout adding woLookup to the Call Objects
**/
public class FSL_JSonParserWorkOrder {
    
    public string id {get;set;} 
    public string caseId {get;set;}
    public string contractId {get;set;}
    public boolean reconcileEntitlement {get;set;}
    public String requestEventType {get;set;} 
    public String subType {get;set;} 
    public String status {get;set;} 
    public String version {get;set;} 
    public String createDate {get;set;}
    public SourceSystem sourceSystem {get;set;} 
    public SourceSystem targetSystem {get;set;} 
    public List<Calls> calls {get;set;}
    public String towRequestReason {get;set;}//EMI
    public String towRequestMiscellaneousDetails {get;set;}//EMI
    
    public class Calls {
        public String date_str {get;set;} 
        public Integer id {get;set;} 
        public String version {get;set;} 
        public Channel channel {get;set;} 
        public Customer customer {get;set;} 
        public Vehicle vehicle {get;set;} 
        public Service service {get;set;} 
        public Payment payment {get;set;} 
        public List<Comments> comments {get;set;} 
        public String callKey {get;set;}
        public String callDate {get;set;}
        public String callId {get;set;}
        public Boolean woLookup{get;set;}
        public String requestingSystemCallId{get;set;}
    }
    public class Channel {
        public String channelType {get;set;} 
        public SystemOrganziation org {get;set;} 
        public Contact contact {get;set;} 
        public Location location {get;set;}         
    }
    public class Customer {
        public List<Memberships> memberships {get;set;} 
        public Contact_customer contact {get;set;} 
        public String languagePreference {get;set;} 
    }
    public class Vehicle {
        public Id id {get;set;} 
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
        Public Keycodes keycodes{get;set;}
        public String plate {get;set;} //EMI
    }
        
    Public class Keycodes{
        public String mmpv {get;set;}
        public string door {get;set;}
        public string ignition {get;set;}
        public string vats {get;set;}
    
    }
    public class Service {
        public String callType {get;set;} 
        public String timezoneId {get;set;} 
        public String timezoneOffset {get;set;} 
        public Status status {get;set;} 
        public String appointmentTime {get;set;} 
        public Facility facility {get;set;} 
        public List<TroubleCodes> troubleCodes {get;set;} 
        public List<ServiceLocations> serviceLocations {get;set;} 
        public Boolean collision {get;set;} 
        public Boolean redFlag {get;set;} 
        public String priorityCode {get;set;}
        public String legacyPriorityCode {get;set;}
        public String priorityDescription {get;set;} 
        public Integer numberOfPassengers {get;set;} 
        public Boolean needsFlatbed {get;set;} 
        public Boolean flatbedRequested {get;set;} 
        public List<Policies> policies {get;set;}
        public String apdSeqId {get;set;}
        public String duty {get;set;} 
        public String memberPhone {get;set;} 
        public Boolean useYourLongTowEntitlement {get;set;}
        public Double totalMileage {get;set;}
        public boolean chargeEntitlement {get;set;}
        public Boolean useHomeLockoutEntitlement {get;set;}
        public String repairShopId {get;set;}
    }
    public class Payment {
        public Boolean required {get;set;} 
        public String paymentType {get;set;} 
        public String codes {get;set;} 
        public string responsible{get;set;}
    }
    
    public class Contacts {
        public String contactType {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Phones_Contacts> phones {get;set;} 
    }
    public class Memberships {
        public String membershipType {get;set;} 
        public String sponsor {get;set;} 
        public String program {get;set;} 
        public String authorizationCode {get;set;} 
        public String authorizationLevel {get;set;} 
        public Boolean isLocalClub {get;set;} 
        public SystemOrganziation org {get;set;} 
        public String id {get;set;}
        public String originalMemberId {get;set;} 
        public String expirationDate {get;set;} 
        public String memberLevel {get;set;} 
        public String memberBirthday {get;set;} 
        public String memberSince {get;set;} 
        public String memberStatus {get;set;} 
        public List<Entitlements> entitlements {get;set;}
        public String goodwill{get;set;}
        public String programName{get;set;}
        public String programPhone{get;set;}
        public String programMaxMileage{get;set;}  
    }
    
    public class Policies {
        public String code {get;set;} 
        public String description {get;set;}        
    }
    
    public class Address {
        public String addressType {get;set;} 
        public String full {get;set;} 
        public String streetNumber {get;set;} 
        public String street {get;set;}
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
    
    public class Phones_Contacts {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} // in json: number
        public Boolean preferred {get;set;} 
    }
    
    public class SystemOrganziation {
        public String name {get;set;} 
        public String code {get;set;} 
    }
    
    public class Phones {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} // in json: number
        public String phoneExtension {get;set;} 
        public Boolean preferred {get;set;} 
        public Boolean smsOptIn {get;set;} 
    }
    
    public class Location_TowDest {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public Address_TowAddress address {get;set;} 
        public String landmark {get;set;} 
        //public String pluscode {get;set;} 
    }
    
    public class Emails {
        public String emailType {get;set;} 
        public String address {get;set;} 
    }
    
    public class TroubleCodes {
        public String troubleCodeType {get;set;} 
        public String code {get;set;} 
        public String description {get;set;} 
    }
    
    public class Status {
        public String status {get;set;} 
        public String modifiedDate {get;set;} 
        public String eta {get;set;} 
        public String pta {get;set;} 
        public Integer waitTime {get;set;} 
    }
    
    public class Foi {
        public String foiType {get;set;} 
        public ServiceLocations_Location location {get;set;}
        public List<Contacts> contacts {get;set;}
        public String name {get;set;}
        public String id {get;set;}
    }
    
    public class Comments {
        public SourceSystem system_Z {get;set;} // in json: system
        public Contact contact {get;set;} 
        public String date_str {get;set;} 
        public String commentType {get;set;} 
        public String visibility {get;set;} 
        public String text {get;set;} 
    }
    
    public class Contact_customer {
        public Id id {get;set;} 
        public String contactType {get;set;} 
        public String title {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Phones> phones {get;set;} 
        public List<Emails> emails {get;set;}
        public String accountId;
        public String orgCode {get;set;} // PR893288-5062 To populate orgcode in club code field on account. 
        // This change is for AAA-ACA Project on *Top of the AAA-ACE Code*, for considring exact match and not LIKE match as per Jira Story https://salesforce.atlassian.net/browse/PR893288-238
        public String suffix {get;set;} 
    }
    
    public class ServiceLocations {
        public String serviceLocationType {get;set;} 
        public Foi foi {get;set;} 
        public Foi_TowDest foi_towDest {get;set;}
        public Double mileageCalculated {get;set;} 
        public Double milesFromOrigin {get;set;} 
        public String driverDirections {get;set;} 
        public String dropBoxInfo {get;set;} 
        public String foiType {get;set;}
        
    }
    
    public class Contact {
        public String userId {get;set;}
        public String contactType {get;set;}        
    }
    
    public class Foi_TowDest {
        public Location_TowDest location {get;set;} 
        public String name {get;set;} 
         
    }
    
    public class Entitlements {
        public Boolean serviceChargeIndicator {get;set;} 
    }
    
    public class Facility {
        public String foiType {get;set;} 
        public String id {get;set;} 
        public String name {get;set;} 
        //Added for UF-1387
        public String preferenceType {get;set;} 
        //public Schema.Location location {get;set;} 
    }
    
    public class Address_TowAddress {
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
    
    public class SourceSystem {
        public String systemId {get;set;} 
        public SystemOrganziation systemOrganziation {get;set;} 
    }
    
    public class RvInfo {
        public String rvClass {get;set;} 
        public String engineLocation {get;set;} 
        public Boolean gooseNeck {get;set;} 
        public Double height {get;set;} 
        public Double length {get;set;} 
        public string weight {get;set;} 
        public Boolean towing {get;set;} 
        public String towingType {get;set;} 
    }
    
    public class Location {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public Address address {get;set;} 
    }
    
    public class ServiceLocations_Location {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public Address address {get;set;} 
        public String highway {get;set;} 
        public String mileMarker {get;set;} 
        public String grid {get;set;} 
        public String zone {get;set;} 
        public String locationCode {get;set;} 
        public String landmark {get;set;} 
        //public String pluscode {get;set;} 
    }
}