/**
 * @File Name          : FSL_JSONParserLocationUpdates
 * @Description        : 
 * @Author             : Salesforce Services
 * @Group              : 
 * @Last Modified By   : Salesforce Services
 * @Last Modified On   : 5/1/2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
**/
public class FSL_JSONParserLocationUpdates {
    
    public string id {get;set;} 
    public String requestEventType {get;set;} 
    public String subType {get;set;} 
    public String version {get;set;} 
    public String createDate {get;set;}
    public List<Calls> calls {get;set;}
    
    public class Calls {
        public String version {get;set;} 
        public Channel channel {get;set;} 
        public Service service {get;set;} 
        public List<Comments> comments {get;set;} 
        public String callKey {get;set;}
        public String callDate {get;set;}
        public String callId {get;set;}
    }

    public class Service {
        public Status status {get;set;} 
        public Facility facility {get;set;} 
        public List<ServiceLocations> serviceLocations {get;set;} 
    }

    public class Status {
        public String status {get;set;} 
        public String modifiedDate {get;set;} 
        public String updateCode {get;set;} 
        public String pta {get;set;} 
        public Integer waitTime {get;set;} 
    }
    
    public class Facility {
        public String id {get;set;} 
        public String name {get;set;} 
    }

    public class ServiceLocations {
        public String serviceLocationType {get;set;} 
        public Foi foi {get;set;} 
        public Foi_TowDest foi_towDest {get;set;}
        public String driverDirections {get;set;} 
        public Integer mileageCalculated {get;set;} 
        public Integer milesFromOrigin {get;set;} 
    }

    public class Foi {
        public String foiType {get;set;} 
        public ServiceLocations_Location location {get;set;}
        public List<Contacts> contacts {get;set;}
        public String name {get;set;}
        public String id {get;set;}
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

    public class Contacts {
        public String contactType {get;set;} 
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public List<Phones_Contacts> phones {get;set;} 
    }

    public class Phones_Contacts {
        public String phoneType {get;set;} 
        public String phoneNumber {get;set;} // in json: number
        public Boolean preferred {get;set;} 
    }

    public class Emails {
        public String emailType {get;set;} 
        public String address {get;set;} 
    }

    public class Foi_TowDest {
        public String foiType {get;set;}
        public Location_TowDest location {get;set;} 
        public List<Contacts> contacts {get;set;}
        public String name {get;set;}
        public String id {get;set;} 
    }

    public class Location_TowDest {
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 
        public Address_TowAddress address {get;set;} 
        public String landmark {get;set;} 
        //public String pluscode {get;set;} 
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

    public class Channel {
        public String channelType {get;set;} 
        public SystemOrganziation org {get;set;} 
        public Contact contact {get;set;}       
    }

    public class Comments {
        public SourceSystem system_Z {get;set;} // in json: system
        public Contact contact {get;set;} 
        public String date_str {get;set;} 
        public String commentType {get;set;} 
        public String visibility {get;set;} 
        public String text {get;set;} 
    }

    public class SourceSystem {
        public String systemId {get;set;} 
        public SystemOrganziation systemOrganziation {get;set;} 
    }

    public class SystemOrganziation {
        public String name {get;set;} 
        public String code {get;set;} 
    }

    public class Contact {
        public String userId {get;set;}
        public String contactType {get;set;} 
        public string middleName {get;set;}       
    }
}