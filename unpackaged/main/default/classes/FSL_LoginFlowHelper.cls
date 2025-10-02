/**
 * Created by divnaidu on 3/29/2019.
 */

public with sharing class FSL_LoginFlowHelper {

	/**
	 *	Get the types of vehicles eligible for the selected primary facility
	 */
       /*@InvocableMethod
        public static List<String> getVehicleTypes(List<String>primaryTerritoryIdList) {
           Map<String, String> uniqueVehicleTypeMap = new Map<String,String>();
           List<String> vehicleTypeList = new List<String>();
           String primaryTerritoryIdString = '';
           for(String s : primaryTerritoryIdList) {
               primaryTerritoryIdString = s;
           }
           List<Schema.Location> vehicleList = [SELECT Id, Vehicle_Type__c FROM Location WHERE Facility__c =: primaryTerritoryIdString];
           for(Schema.Location loc : vehicleList) {
               uniqueVehicleTypeMap.put(loc.Vehicle_Type__c, null);
           }
           for(String s : uniqueVehicleTypeMap.keySet()) {
               IF(!STRING.ISEMPTY(s)){
                    vehicleTypeList.add(s);
               		SYSTEM.DEBUG(S);
               }
           }
           return vehicleTypeList;
        }*/
        
       @InvocableMethod
        public static List<String> getRowCount(List<String>serviceResource) {
           string serviceresourceId;
           for(String s : serviceResource) {
               serviceresourceId = s;
           }            
            list<ServiceTerritoryMember> stms = [select id 
                                                   from ServiceTerritoryMember 
                                                where serviceresourceId = :serviceresourceId and 
                                                      FSL_Part_Time__c=true and 
                                                      FSL_Expired_Resource_territory__c = false];

            system.debug('facilityOptions: '+stms.size()+' '+stms);
            list<string> str = null;
            if(stms!=null && stms.size()>0){
                str = new list<string>{'Has Data'};
            }
            system.debug('**RowCount**'+str);
            return str;            
        }
}