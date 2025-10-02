public class sadaplacedetailsresponse {

    public class Address_components {
        public String long_name;
        public String short_name;
        public List<String> types;
    }

    public class Geometry {
        public Location location;
        public Viewport viewport;
    }

    public List<Address_components> address_components;
    public String adr_address;
    public String formatted_address;
    public Geometry geometry;
    public String icon;
    public String icon_background_color;
    public String icon_mask_base_uri;
    public String name;
    public String place_id;
    public String reference;
    public List<String> types;
    public String url;
    public Integer utc_offset;
    public String vicinity;

    public class Viewport {
        public Location northeast;
        public Location southwest;
    }

    public class Location {
        public Double lat;
        public Double lng;
    }

    
    public static sadaplacedetailsresponse parse(String json) {
        return (sadaplacedetailsresponse) System.JSON.deserialize(json, sadaplacedetailsresponse.class);
    }
 }