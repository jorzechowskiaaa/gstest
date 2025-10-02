/**** Apex Class Name    :    INTDistanceMatrixAPIResponseWrapper
    * Description        :    This  is wrapper class for  for Distance Matrix API   
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Ravi Kumar               Feb 23 2022            Created
*********************************************************************************/
public class INTDistanceMatrixAPIResponseWrapper {

	public class Elements {
		public Distance distance;
		public Distance duration;
		public String status;
	}

	public List<String> destination_addresses;
	public List<String> origin_addresses;
	public List<Rows> rows;
	public String status;

	public class Distance {
		public String text;
		public Integer value;
	}

	public class Rows {
		public List<Elements> elements;
	}

	
	public static INTDistanceMatrixAPIResponseWrapper parse(String json) {
		return (INTDistanceMatrixAPIResponseWrapper) System.JSON.deserialize(json, INTDistanceMatrixAPIResponseWrapper.class);
	}
}