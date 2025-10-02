/**
* @File Name : SuspiciousLocationHelper.cls
* @Description : Identifies potentially suspicious breakdown destination/tow locations based on criteria, for SSFI-1242
* @Author : John Orzechowski
* @Last Modified By :
* @Last Modified On : July 18, 2025
**/

public with sharing class SuspiciousLocationHelper {
	
	private static List<String> startsWithSearch;
	private static List<String> endsWithSearch;
	private static List<String> containsSearch;

    public class FlowInput {
        @InvocableVariable(label = 'Cases' required=True)
        public List<Case> caseList;
    }
	public class FlowOutput { 
		@InvocableVariable(label = 'Processed Cases') 
		public List<Case> processedCases; 
	}

     /*
     * @description: queries the custom metadata and processes various types of search parameters needed to evaluate case
     * @param: none
	 * @date: July 18, 2025
     * @author: John Orzechowski
     */ 
	public static void getParams() {
		List<Suspicious_Location_Parameters__mdt> params = [Select Parameter__c from Suspicious_Location_Parameters__mdt WHERE Operator__c = 'Contains']; 
		list<String> containsParams = new List<String>(); 
		list<String> startsParams = new List<String>(); 
		list<String> endsParams = new List<String>(); 

		if( Test.IsRunningTest() ) {
            Suspicious_Location_Parameters__mdt c = new Suspicious_Location_Parameters__mdt(Parameter__c = '%Test%', Operator__c = 'Contains');
			Suspicious_Location_Parameters__mdt d = new Suspicious_Location_Parameters__mdt(Parameter__c = 'Begin%', Operator__c = 'Contains');
			Suspicious_Location_Parameters__mdt e = new Suspicious_Location_Parameters__mdt(Parameter__c = '%End', Operator__c = 'Contains');
			params.add(c); params.add(d); params.add(e);  
		}
		// process the suspicious location metadata
		if( !params.isEmpty() ) {
			for (Suspicious_Location_Parameters__mdt p : params) {
				
				if( p.Parameter__c.length() > 0 && p.Parameter__c != null ) { 
					
					// add parameter to appropriate list depending on where '%' exists in string
					if( p.Parameter__c.left(1) == '%' && p.Parameter__c.right(1) == '%' ) {
						containsParams.add(p.Parameter__c.replaceAll('%','').toLowerCase());
					} else if( p.Parameter__c.left(1) == '%' && p.Parameter__c.right(1) != '%' ) {
						endsParams.add(p.Parameter__c.replaceAll('%','').toLowerCase());
					} else if( p.Parameter__c.left(1) != '%' && p.Parameter__c.right(1) == '%' ) {
						startsParams.add(p.Parameter__c.replaceAll('%','').toLowerCase());
					} else {
						containsParams.add(p.Parameter__c.replaceAll('%','').toLowerCase());
					}
				}	 
			}
		}
		if ( !containsParams.isEmpty() ) { 
			containsSearch = containsParams; 
		} 
		if ( !startsParams.isEmpty() ) { 
			startsWithSearch = startsParams; 
		}
		if ( !endsParams.isEmpty() ) { 
			endsWithSearch = endsParams; 
		}
	}
     /*
     * @description: flow invocable, checks a list of cases (within the FlowInput wrapper class)
     * @param: List<FlowInput>
	 * @date: July 18, 2025
     * @author: John Orzechowski
     */ 
	@InvocableMethod(label = 'Check Case for Suspicious Locations')
    public static List<FlowOutput> checkCaseList(List <FlowInput> inputs) {
          List<FlowOutput> outputs = new List<FlowOutput>(); 
		  getParams();
		  for (flowInput input:  inputs) {
			List<case> processedList = new List<Case>();
			FlowOutput output = new FlowOutput(); 
			
			if (!input.caseList?.isEmpty()) {
				for (Case c: input.caseList) {
					
					Case thisCase = new Case();
					thisCase.Id = c.Id; 
					thisCase.Landmark__c = c.Landmark__c;
					thisCase.Tow_Destination_Name__c = c.Tow_Destination_Name__c; 
					thisCase.Investigate_Location__c = isLocationSuspiciousByCase(thisCase); 
					processedList.add(thisCase); 
				}
			}
			output.processedCases = processedList; 
			outputs.add(output); 
		  }

		  return outputs; 
	}

     /*
     * @description: checks case record for suspicious activity based on Landmark__c and Tow_Destination_Name__c fields
     * @param: caseRecord
	 * @date: July 18, 2025
     * @author: John Orzechowski
     */ 
	public static Boolean isLocationSuspiciousByCase(Case caseRecord) {
		
		if ( !String.isBlank(caseRecord.Landmark__c) && !String.isBlank(caseRecord.Tow_Destination_Name__c) ) {
			return isSuspiciousByNames(caseRecord.Landmark__c, caseRecord.Tow_Destination_Name__c);
		} else if ( !String.isBlank(caseRecord.Tow_Destination_Name__c) ) {
			return isSuspiciousByName(caseRecord.Tow_Destination_Name__c);
		} else if ( !String.isBlank(caseRecord.Landmark__c) ) {
			return isSuspiciousByName(caseRecord.Landmark__c);
		}

		return False; 
	}

     /*
     * @description: checks one string location name for match with suspicious criteria
     * @param: string of location name
	 * @date: July 18, 2025
     * @author: John Orzechowski
     */ 
	public static Boolean isSuspiciousByName(String locationName) {
		
		if (locationName == null || locationName.length() == 0 ) { 
			return False; 
		}
		// set lowercase to be case insensitive
		String locationLowercase = locationName.toLowerCase();

		// first query for an exact match on location name
		List<Suspicious_Location_Parameters__mdt> locList = 
			[Select Id from Suspicious_Location_Parameters__mdt WHERE Operator__c = 'Equals' and Parameter__c = :locationLowerCase]; 
		
		if(locList.size() > 0) { 
			return True; 
		}

		// compare the location name with the parameters in containsSearch
		if( containsSearch != null && containsSearch.size() > 0 ) { 
			for (String s : containsSearch) { 
				if (locationLowercase.contains(s)) {
					return True; 
				}
			}
		}

		// compare the location name with the parameters in startsWithSearch
		if( startsWithSearch != null && startsWithSearch.size() > 0 ) {
			for (String s : startsWithSearch) { 
				if (locationLowercase.startsWith(s)) {
					return True; 
				}
			}
		}
	
		// compare the location name with the parameters in endsWithSearch
		if( endsWithSearch != null && endsWithSearch.size() > 0 ) { 
			for (String s : endsWithSearch) { 
				if (locationLowercase.endsWith(s)) {
					return True; 
				}
			}
		}

		return False; 
	}
     /*
     * @description: checks two location names for suspicious criteria -- more efficiently matches when a record has both fields populated vs.
	 *   searching for one at a time
     * @param: two strings of location names
	 * @date: July 18, 2025
     * @author: John Orzechowski
     */ 
	public static Boolean isSuspiciousByNames(String locationName, String location2Name) {
		
		if ( String.isBlank(locationName) || String.isBlank(location2Name) ) { 
			return False; 
		}
		// set lowercase to be case insensitive
		String locationLowercase = locationName.toLowerCase();
		String location2Lowercase = location2Name.toLowerCase(); 

		// first query for an exact match on location name
		List<Suspicious_Location_Parameters__mdt> locList = 
			[Select Id from Suspicious_Location_Parameters__mdt WHERE Operator__c = 'Equals' and 
			( Parameter__c = :locationLowerCase 
			or Parameter__c = :location2Lowercase )]; 
		if(locList.size() > 0) { 
			return True; 
		}

		// compare the location name with the parameters in containsSearch
		if( containsSearch != null && containsSearch.size() > 0 ) { 
			for (String s : containsSearch) { 
				if (locationLowercase.contains(s) || location2Lowercase.contains(s)) {
					return True; 
				}
			}
		}

		// compare the location name with the parameters in startsWithSearch
		if( startsWithSearch != null && startsWithSearch.size() > 0 ) {
			for (String s : startsWithSearch) { 
				if (locationLowercase.startsWith(s) || location2Lowercase.startsWith(s)) {
					return True; 
				}
			}
		}
	
		// compare the location name with the parameters in endsWithSearch
		if( endsWithSearch != null && endsWithSearch.size() > 0 ) { 
			for (String s : endsWithSearch) { 
				if (locationLowercase.endsWith(s) || location2Lowercase.endsWith(s)) {
					return True; 
				}
			}
		}

		return False; 
	}

}