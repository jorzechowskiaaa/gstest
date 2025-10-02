public class ReciprocalTriggerHandler {
    
    public static void checkForDuplicates(List<Reciprocal__c> recips){
        Set<String> nameDateTroubleCodes = new Set<String>();
        Set<String> nameDateTroubleCodesDupes = new Set<String>();
        Id recordTypeId = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();
        
        
        //put all the name/date/trouble code combos in a set
        for (Reciprocal__c r: recips){
            if (r.RecordTypeId == recordTypeId){
            if (nameDateTroubleCodes.contains(r.NameDateTroubleCode__c.toUpperCase()) == false){
                nameDateTroubleCodes.add(r.NameDateTroubleCode__c.toUpperCase());
            }
            else{
                nameDateTroubleCodesDupes.add(r.NameDateTroubleCode__c.toUpperCase());
            }
        }
        }
        
        Set<String> existingDupes = new Set<String>(); 
        List<Reciprocal__c> existingRs = [Select Id, is_Duplicate__c, NameDateTroubleCode__c from Reciprocal__c where NameDateTroubleCode__c in: nameDateTroubleCodes and is_Duplicate__c = false and RecordTypeId=:recordTypeId];
		//loop through all of these, mark all of them as duplicates, update later
		
        for(Reciprocal__c existingR : existingRs){
            existingR.is_Duplicate__c = true;
            existingDupes.add(existingR.NameDateTroubleCode__c.toUpperCase());
        }
		
        // loop through reciprocals again, this time check against both sets, mark as dupe if so
        for (Reciprocal__c r: recips){
            if (r.RecordTypeId == recordTypeId){
            if (nameDateTroubleCodesDupes.contains(r.NameDateTroubleCode__c.toUpperCase())){
                r.Is_Duplicate__c = true;
            }
            if (existingDupes.contains(r.NameDateTroubleCode__c.toUpperCase())){
                r.is_Duplicate__c = true;
            }
            }
        }
        
         update existingRs;
        
    }

}