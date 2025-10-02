/**** Apex Class Name    :    FSL_CallMoverJSONRequest_Wrapper
    * Description        :    This  is wrapper class for  for CallMover API  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Sep 2 2021             Created
*********************************************************************************/
public without sharing class FSL_CallMoverJSONRequest_Wrapper {
    public string id {get;set;} 
    public String requestEventType {get;set;} 
    public String subType {get;set;} 
    public String version {get;set;} 
    public Long createDate {get;set;}
    public SourceSystem sourceSystem {get;set;} 
    public SourceSystem targetSystem {get;set;} 
    public List<Calls> calls {get;set;}
    
    public class Calls {
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
        public String requestingSystemCallId{get;set;}
    }
    
    public class Channel {
        public String channelType {get;set;} 
        public systemOrganization org {get;set;} 
        public Contact contact {get;set;}       
    }
    
    public class Customer {
        public List<Memberships> memberships {get;set;} 
        public Contact_customer contact {get;set;} 
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
        public String specialEquipmentNeeds {get;set;} 
    }
    
    public class Service {
        public String callType {get;set;} 
        public String timezoneId {get;set;} 
        public String timezoneOffset {get;set;} 
        public Status status {get;set;} 
        public List<TroubleCodes> troubleCodes {get;set;} 
        public List<ServiceLocations> serviceLocations {get;set;} 
        public Boolean collision {get;set;} 
        public Boolean redFlag {get;set;} 
        public Integer numberOfPassengers {get;set;} 
        public Boolean needsFlatbed {get;set;} 
        public Boolean flatbedRequested {get;set;} 
        public String duty {get;set;} 
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
        public systemOrganization org {get;set;} 
        public String id {get;set;}
        public String originalMemberId {get;set;} 
        public String expirationDate {get;set;} 
        public String memberLevel {get;set;} 
        public String memberBirthday {get;set;} 
        public String memberSince {get;set;} 
        public String memberStatus {get;set;} 
        public List<Entitlements> entitlements {get;set;}
        public String programName{get;set;}
        public String programPhone{get;set;} 
    }
    
    public class Address {
        public String addressType {get;set;} 
        public String full {get;set;} 
        public String streetNumber {get;set;} 
        public String street {get;set;}
        public String streetDirection {get;set;} 
        public String streetName {get;set;} 
        public String crossStreet {get;set;}
        public String city {get;set;} 
        public String state {get;set;} 
        public String postalCode {get;set;} 
        public String country {get;set;} 
    }
    
    public class Phones_Contacts {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} 
        public Boolean preferred {get;set;} 
    }
    
    public class systemOrganization {
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
        public String updatecode {get;set;} 
        public Datetime modifiedDate{get;set;}
        public String pta {get;set;} 
        public Integer waitTime {get;set;} 
    }
    
    public class Foi {
        public string foiType{get;set;}
        public ServiceLocations_Location location {get;set;}
        public List<Contacts> contacts {get;set;}
        public String name {get;set;}
    }
    
    public class Comments {
        public SourceSystem system_Z {get;set;} // in json: system
        public Contact contact {get;set;} 
        public String commentDate {get;set;} 
        public String commentType {get;set;} 
        public String visibility {get;set;} 
        public String text {get;set;} 
    }
    
    public class Contact_customer {
        public String contactType {get;set;} 
        public String title {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Phones> phones {get;set;} 
        public List<Emails> emails {get;set;} 
    }
    
    public class ServiceLocations {
        public String serviceLocationType {get;set;} 
        public Foi foi {get;set;} 
        public Double mileageCalculated {get;set;} 
        public Integer milesFromOrigin {get;set;} 
        public String driverDirections {get;set;} 
        public String dropBoxInfo {get;set;} 
        
    }
    
    public class Contact {
        public String userId {get;set;}
        public String contactType {get;set;}        
    }
    
    public class Entitlements {
        public Integer associates{get;set;} 
        public Integer callsAllowed{get;set;}
        public Integer callsRemaining{get;set;}
        public Integer callsUsed{get;set;}
        public string chargeableCalls{get;set;}
        public string currentCalls{get;set;}
        public Boolean onlineGarageMember{get;set;}
        public Boolean longTowAllowed{get;set;} 
    }
    
    public class SourceSystem {
        public String systemId {get;set;} 
        public systemOrganization systemOrganization {get;set;} 
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
    }
}