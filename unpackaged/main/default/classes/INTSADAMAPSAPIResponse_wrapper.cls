/**** Apex Class Name    :    INTSADAMAPSAPIResponse_wrapper
    * Description        :    Wrrapper Class for SADAGEOJSON API 
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Ravi Kumar              Dec 15 2021            Created
*********************************************************************************/
public class INTSADAMAPSAPIResponse_wrapper {

	public class Address {
        public String streetnumber;
        public String street;
        public String intersection;
        public String suburb;
        public String city;
        public String state;
        public String zip;
        public String country;
		public String long_name;
		public String short_name;
		public List<String> types;
	}

	public class Geometry {
		public Location location;
		public String location_type;
		public Viewport viewport;
	}

	public List<Results> results;
	public String status;
	public List<custom_results> custom_results;

	public class Results {
		public Address address;
        public POI poi;
        public Location location;
		public String formatted_address;
        public String name;
        public String source;
		public Geometry geometry;
		public String place_id;
		public List<String> types;
	}

	public class Viewport {
		public Location northeast;
		public Location southwest;
	}
	
	public class Items {
		public String type;
		public String name;
		public Double lat;
		public Double lng;
	}
	
	public class Location {
		public Double lat;
		public Double lng;
	}
	
	public class custom_results {
		public String name;
        public String formatted_address;
		public Double lat;
		public Double lng;
		public Double distance;
		public Integer bearing;
		public String type;
		public List<Items> items;
	}
    
    public class POI {
		public String sid;
        public String location;
		public Double latitude;
		public Double longitude;
        public String address;
        public String cross_street_1;
        public String cross_street_2;
        public String city;
        public String state;
        public String county;
        public String alert_text;
		public String poi_type;
		public String action;
		public String google_place_id;
		public List<String> pick_up_points;
	}

	
	public static INTSADAMAPSAPIResponse_wrapper parse(String json) {
		return (INTSADAMAPSAPIResponse_wrapper) System.JSON.deserialize(json, INTSADAMAPSAPIResponse_wrapper.class);
	}
}