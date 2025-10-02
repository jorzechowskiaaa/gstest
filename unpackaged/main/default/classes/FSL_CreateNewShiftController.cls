public with sharing class FSL_CreateNewShiftController {
    public ServiceResource resource{get;set;}
    public Shift newShift{get;set;}
    public FSL_CreateNewShiftController() {
        
        ID resourceID = ApexPages.currentPage().getParameters().get('id');
        resource = [Select Id,Name,LastKnownLatitude,LastKnownLongitude,Primary_Service_Territory__c from ServiceResource where Id =:resourceId];
        newShift = new Shift(ServiceResourceId = resource.Id,ServiceTerritoryId = resource.Primary_Service_Territory__c,timeSlotType='Normal',status='Confirmed');
    }

    public PageReference saveShift() {
        insert newShift;
        return null;
    }
}