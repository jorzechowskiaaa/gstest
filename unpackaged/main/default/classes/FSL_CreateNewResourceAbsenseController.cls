public class FSL_CreateNewResourceAbsenseController {

    public ServiceResource resource{get;set;}
    public ResourceAbsence resourceAbsence{get;set;}
    public Boolean useCurrentLocatin{get;set;}
    //public Boolean errorCaught{get;set;}
    public FSL_CreateNewResourceAbsenseController ()  {
         //errorCaught = false;
         resourceAbsence = new ResourceAbsence();
         ID resourceID = ApexPages.currentPage().getParameters().get('id');
         resource = [Select Id,Name,LastKnownLatitude,LastKnownLongitude from ServiceResource where Id =:resourceId];
    }
    
    public PageReference saveAbsence() {
        Id breakRecordTypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByName().get('Non Availability').getRecordTypeId();
        resourceAbsence.recordTypeId = breakRecordTypeId;
        resourceAbsence.resourceId = resource.Id;
        if(useCurrentLocatin) {
            resourceAbsence.longitude = resource.LastKnownLongitude;
            resourceAbsence.latitude = resource.LastKnownLatitude;
            resourceAbsence.FSL__InternalSLRGeolocation__Latitude__s = resource.LastKnownLatitude;
            resourceAbsence.FSL__InternalSLRGeolocation__Longitude__s = resource.LastKnownLongitude;
        }else {
            resourceAbsence.country = 'United States';
        }
        if(resourceAbsence.start == resourceAbsence.End) {
            //errorCaught = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Start End Dates should not be SAME!'));
            return null;
            
        }
        
        insert resourceAbsence;
        //errorCaught = false;
        return null;
    }
}