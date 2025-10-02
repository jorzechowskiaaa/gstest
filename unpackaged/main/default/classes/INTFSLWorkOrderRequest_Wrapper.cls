/**** Apex Class Name    :    INTFSLWorkOrderRequest_Wrapper
    * Description        :    This  is wrapper class for  for Intake Work Order API  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Sep 2 2021             Created
*********************************************************************************/
public without sharing class  INTFSLWorkOrderRequest_Wrapper {

	public class Vehicle {
		public string year;
		public String make;
        public String plate;//EMI
		public String model;
		public String color;
		public String trim;
		public Double odometer;
		public String vin;
		public String specialEquipmentNeeds;
		public String driveType;
		public String fuelType;
		public String licensePlateIdentifier;
		public String licensePlateState;
		public string driveLine;
		public Boolean flatbedRequired;
		public String type;

        public String rvClass;
        public Double rvLength;

        public String trailerHitchType;
        public Double trailerLength;

	}

	public string id;
	public string memberNumber;
	public String pacesetterCode;
    public String IssueType;
	public string policy;
	public String priority;
    public String priorityCode; //AGB SSFI-893 2/17/25
	public String callType;
    public String OperationType;
	public String sourceOrgCode;
	public String sourceOrgName;
    public string CaseId;
    public string channel;
    public string os;
    public string device;
    public string SlotStartDateTime;
    public string SlotEndDateTime;
    public string WorkorderID;
	public String callStatus;
	public Integer numberOfPassengers;
    public string hasSpareTire;
    public string lockedOutType;
    public string typeOfFuel;
	public String userId;
	public String requestingSystemCallId;
	public String callId;
	public String UTCTimeZoneOffset;
	public String timeZoneOffset;
	public String timeZoneId;
	public String redFlag;
	public String collision;
	public String facilityId;
	public String facilityName;
	public String facilityType;
	public String genesysConversationId;
	public String impairmentId;
	public List<String> comments;
	public ContactInformation contactInformation;
	public Vehicle vehicle;
	public BreakdownLocation breakdownLocation;
	public TowDestination towDestination;
	public Decimal totalMileage;

	public class BreakdownLocation {
		public String streetNumber;
		public String streetName;
		public String crossStreet;
		public String city;
		public String postalCode;
		public String state;
		public String landmark;
		public Double latitude;
		public Double longitude;
		public String pickupPoint;
        public String driverDirections;
		public String locationCode;
	}

	public class TowDestination {
		public String shopId;
		public String locationName;
		public String streetNumber;
		public String streetName;
		public String crossStreet;
		public String city;
		public String state;
        public String postalCode;
		public Double latitude;
		public Double longitude;
	}

	public class ContactInformation {
		public String firstName;
		public String lastName;
		public String telephoneNumber;
		public Boolean smsOptin;
		public Boolean callOptIn;
		public String callBackType;
		public Integer callBackMinutes;
		public String currentBenefitLevel;
		public String joinYear;
		public String sponsor;
		public String program;
        public String orgCode; //PR893288-5062 Added to populate club code on account
	}
	
	public static List<INTFSLWorkOrderRequest_Wrapper> parse(String json) {

		List<INTFSLWorkOrderRequest_Wrapper> objList;
		if(json.startsWith('[')) {
			objList = (List<INTFSLWorkOrderRequest_Wrapper>) System.JSON.deserialize(json, List<INTFSLWorkOrderRequest_Wrapper>.class);
		} else {
			INTFSLWorkOrderRequest_Wrapper obj = (INTFSLWorkOrderRequest_Wrapper) System.JSON.deserialize(json, INTFSLWorkOrderRequest_Wrapper.class);
			objList = new List<INTFSLWorkOrderRequest_Wrapper>();
			objList.add(obj);
		}
		return objList;

		//try {
		//	INTFSLWorkOrderRequest_Wrapper obj = (INTFSLWorkOrderRequest_Wrapper)System.JSON.deserialize(json, INTFSLWorkOrderRequest_Wrapper.class);
		//	List<INTFSLWorkOrderRequest_Wrapper> objList = new List<INTFSLWorkOrderRequest_Wrapper>();
		//	objList.add(obj);
		//	return objList;
		//} catch (jsonException e) {
		//	return (List<INTFSLWorkOrderRequest_Wrapper>) System.JSON.deserialize(json, List<INTFSLWorkOrderRequest_Wrapper>.class);
		//}
	}	
}