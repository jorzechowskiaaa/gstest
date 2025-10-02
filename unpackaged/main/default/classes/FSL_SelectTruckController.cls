/**
 * Created by divnaidu on 1/9/2019.
 */

public class FSL_SelectTruckController {

    @AuraEnabled
    public static List<String> getPickListValuesIntoList(Id uId){

        List<String> pickListValuesList = new List<String>();
        /*Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }*/
        ServiceResource sr = [SELECT Id, Name, Vehicle__c, Primary_Facility_Id__c FROM ServiceResource WHERE RelatedRecordId = :uId AND ResourceType = 'T'];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Id =: sr.Primary_Facility_Id__c];
        List<Schema.Location> locList = new List<Schema.Location> ([SELECT Id, Name FROM Location WHERE Facility__c = :st.Id AND In_Use__c = false]);
        for(Schema.Location loc : locList) {
            pickListValuesList.add(loc.Name);
        }
        return pickListValuesList;
    }


}