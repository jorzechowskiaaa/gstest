/**
 * @File Name          : FSL_FacilitySelectionHelper.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 11/5/2019, 5:22:19 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    11/4/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public without sharing class FSL_FacilitySelectionHelper {        
        @InvocableMethod
        public static void updateServiceResourceTerritoryMembership(List<String> selectedTerritoryMember){
           String selectedTerritoryMemberId = '';
           for(String s : selectedTerritoryMember) {
               selectedTerritoryMemberId = s;
           }
           system.debug('selectedTerritoryMemberId '+selectedTerritoryMemberId);
        	// Step 0) - Find related records
        	// ID is of the STM - Query the STM to store the Service Resource ID in a variable
        	// Find all STM records for the Service Resource ID
        	list<ServiceTerritoryMember> stm = [select id, ServiceTerritoryId, ServiceResourceId, TerritoryType, 
                                                	   EffectiveStartDate, EffectiveEndDate,
                                                	   Street, City, State, PostalCode, Country, OperatingHoursId
                								from ServiceTerritoryMember where id = :selectedTerritoryMemberId];
            if(stm!=null && stm.size()>0){
            	string serviceResourceId = stm[0].ServiceResourceId;
				system.debug('serviceResourceId '+serviceResourceId);
                // Step 1) - Verify that primary has changed
                // Identify if the serviceResourceID is already assigned as a primary member for the selected territory
                
                //Perform below changes only if the current STM is non-primary
                if(!stm[0].TerritoryType.equalsignorecase('P')){
					//List<ServiceTerritoryMember> upsertSTMs = new List<ServiceTerritoryMember>();
                    list<ServiceTerritoryMember> stmPrimary = [select id, ServiceTerritoryId, ServiceResourceId, TerritoryType, 
                                                                      EffectiveStartDate, EffectiveEndDate,
                                                               		  Street, City, State, PostalCode, Country, OperatingHoursId
                                                                from ServiceTerritoryMember 
                                                               where ServiceResourceId = :serviceResourceId AND 
                                                               		 TerritoryType = 'P' and FSL_Expired_Resource_Territory__c = false		
                                                              ];                    

                    //if the service resource has an existing primary territory make it a secondary
                    if(stmPrimary!=null && stmPrimary.size()>0){
                        for(ServiceTerritoryMember primary : stmPrimary){
                            primary.TerritoryType = 'S';
                        }
                        update stmPrimary;
                    }
                    
                    //Update the input STM as primary only after the current primary is flipped to secondary
                    stm[0].TerritoryType = 'P';
                    update stm[0];
                    
                    // Step 2) - Mark the selected territory as primary
                    // If not, update the selected territory as a Primary (start date as now, no end date)
                    // Look for a matching expired primary territory first, if one is not found, create a new primary stm for the selected territory

                    // Step 3) - Mark the previous primary as a secondary
                    // Look for a
                    //  matching expired secondary territory first, if one is not found, create a new secondary stm for the selected territory                    
                 	
                }else{
                    //No changes to make
                }                   
            }
            //return new list<string>{stm[0].ServiceTerritoryId};
        }
}