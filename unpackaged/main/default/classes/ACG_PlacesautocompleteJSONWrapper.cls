/**** Apex Class Name    :    ACG_PlacesautocompleteJSONWrapper
    * Description        :    This  is wrapper class for  for Places Autocomplete API   
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Jul 31 2021             Created
*********************************************************************************/
public class ACG_PlacesautocompleteJSONWrapper {

	public class Matched_substrings {
		public Integer length;
		public Integer offset;
	}

	public List<Predictions> predictions;
	public String status;

	public class Predictions {
		public String description;
		public String id;
		public List<Matched_substrings> matched_substrings;
		public String place_id;
		public String reference;
		public Structured_formatting structured_formatting;
		public List<Terms> terms;
		public List<String> types;
	}

	public class Terms {
		public Integer offset;
		public String value;
	}

	public class Structured_formatting {
		public String main_text;
		public List<Matched_substrings> main_text_matched_substrings;
		public String secondary_text;
	}

    public class Address {
		public String placeId;
		public String description;
    }
    
	/*
    * Method name            : parse
    * Description            : This method is used parse the JSON in string format to Specified Object 
    * @return List reference : Returns list of Address
    * @Param strjson         : JSON response in string format
    */
	public static List<Address> parse(String strjson) {
        
        ACG_PlacesautocompleteJSONWrapper objResponse = (ACG_PlacesautocompleteJSONWrapper) System.JSON.deserialize(strjson, ACG_PlacesautocompleteJSONWrapper.class);
        List<predictions> lstpredicitons = objResponse.predictions;
        List<Address> lstAddress = new List<Address>();

        for(predictions p : lstpredicitons){
            Address a = new Address();
            a.description = p.description;
            a.placeId = p.place_id;
            lstAddress.add(a);
        }
        return lstAddress;
	}
}