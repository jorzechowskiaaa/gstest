public class ERS_Case_GuidanceSuccessMapping {
	@AuraEnabled(cacheable=true)
    public static List<String> getGuidance( String ServType, Id AccountId, String FuelType, String VehicleType,String BSPAvailable, String FlatTireStatus,String CurrentTab, String towMiles, Id caseId){
        //Get all the Active metadata mappings specific to the Current tab.
        List<ERS_Case_Guidance_Success_Mapping__mdt> mdtList = [SELECT 	BSP_Available__c,
                                                                		Case_Guidance_Success_Status__c,
                                                                		Flat_Tire_Status__c,
                                                                		Guidance_Success__c,
                                                                		Membership_Level__c, 
                                                                		Name_of_Triage_Tab__c,
                                                                		Service_Type__c,
                                                                		Vehicle_Fuel_Type__c,
                                                                		DeveloperName,
                                                                		Vehicle_Type__c	 
                                                                FROM ERS_Case_Guidance_Success_Mapping__mdt
																WHERE Name_of_Triage_Tab__c =:CurrentTab
                                                                	AND Case_Guidance_Success_Status__c = 'Active'];
		//Get the Membership level based on the Member Account
        List<Account> MemberAccount= [SELECT Id,
                                      		Level_of_Membership__c,
                                      		AAA_Membership_Level__c 
                                      FROM Account 
                                      WHERE Id =:AccountId];
  		String MembershipLevel = MemberAccount.isEmpty() ? NULL : MemberAccount[0].AAA_Membership_Level__c;
        
        Set<String> setGuidance = new Set<String>();
        //If there are Active mapppings available
        if(!mdtList.isEmpty()){
            	//Search through the metadata records
            for(ERS_Case_Guidance_Success_Mapping__mdt mdtRec : mdtList){
                if( ( ( ServType!=NULL && mdtRec.Service_Type__c!= NULL && ServType.containsIgnoreCase(mdtRec.Service_Type__c) )	|| mdtRec.Service_Type__c == NULL ) 
                  &&( mdtRec.Vehicle_Fuel_Type__c == FuelType		|| mdtRec.Vehicle_Fuel_Type__c == NULL) 
                  &&( mdtRec.Vehicle_Type__c == VehicleType			|| mdtRec.Vehicle_Type__c == NULL ) 
                  &&( mdtRec.BSP_Available__c == BSPAvailable		|| mdtRec.BSP_Available__c == NULL ) 
                  &&( mdtRec.Flat_Tire_Status__c == FlatTireStatus	|| mdtRec.Flat_Tire_Status__c == NULL ) 
                  &&( mdtRec.Membership_Level__c == MembershipLevel	|| mdtRec.Membership_Level__c == NULL )){
                    
                      if(mdtRec.DeveloperName == 'BR_Tow_Tab_3'){
                          String overMileGuidance = ERS_Case_GuidanceSuccessMapping.parseGuidanceMessage(MembershipLevel, towMiles, caseId, mdtRec);
                          if(overMileGuidance != null){
                          	setGuidance.add(overMileGuidance);    
                          }
                          
                      }else{
                          setGuidance.add(mdtRec.Guidance_Success__c);
                      }
                      
                }
            }
        }
        return new List<String>(setGuidance); 
    }
    
    public static String parseGuidanceMessage(String MemLevel, String towMiles, Id caseId, ERS_Case_Guidance_Success_Mapping__mdt mdtRec){

        
        if(caseId != null){
            if(towMiles == null || towMiles == '0'){
                return null;
            }
            List<Case> caseObj = [Select Id,
                                    Allotted_Mileage__c
                                    FROM Case
                                    WHERE Id =:caseId];
            
        	Case cs = caseObj[0];
            if(cs.Allotted_Mileage__c != null){
                String allottedMiles = String.valueOf(cs.Allotted_Mileage__c);
                mdtRec.Guidance_Success__c = mdtRec.Guidance_Success__c.replace('{Membership_Level__c}',MemLevel);
                mdtRec.Guidance_Success__c = mdtRec.Guidance_Success__c.replace('{Allotted_Mileage__c}',allottedMiles);
                String overMiles = String.valueOf((Integer.valueOf(towMiles) - cs.Allotted_Mileage__c));
                if(Integer.valueOf(overMiles) < = 0){
                    String str = '<p style="color:red">You are using '+towMiles+' miles out of your allotted '+allottedMiles+' miles.</p>';
                    return str;
                }
                mdtRec.Guidance_Success__c = mdtRec.Guidance_Success__c.replace('{Over_Miles__c}',overMiles);
                mdtRec.Guidance_Success__c = mdtRec.Guidance_Success__c.replace('{Total_Mileage__c}',towMiles);
            }
            else{
            	return null;
        	}
        }
        
        return mdtRec.Guidance_Success__c;
    }
}