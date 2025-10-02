public class NationalCreateHaasJsonRequest { 
public String type;	//disabled_vehicle
	public String clubCode;	//240
	public String sourceId;	//SF
	public String external_id;	//20250207-10131256-DI
	public List<cls_features> features;
	public String street_name;	//Woodcreek Rd
	public String alert_message;	//Disabled Vehicle Ahead
	public String accuracy;	//3
	public class cls_features {
		public String type;	//point
		public List<cls_geometry> geometry;
	}
	public class cls_geometry {
		public Double lat;	//39.022929
		public Double lon;	//-77.216036
	}
	public static NationalCreateHaasJsonRequest parse(String json){
		return (NationalCreateHaasJsonRequest) System.JSON.deserialize(json, NationalCreateHaasJsonRequest.class);
	}
}