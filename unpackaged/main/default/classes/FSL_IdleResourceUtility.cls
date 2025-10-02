/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 08-26-2022
 * @last modified by  : Clement Shiu
**/
public without sharing class FSL_IdleResourceUtility {
    
    @TestVisible private static  Boolean runRowLock=false;
    
    
    public static void evaluateIdleIndicatorOnResources( List<ServiceResource> resources ) {
        System.debug( 'FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources: Enter' );
        List<ServiceResource> resourcesToUpdate = new List<ServiceResource>();
        List<Id> pendingResourceIds = new List<Id>();
        Datetime currentTime = System.now();
        Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>( resources );
        
        List<AssignedResource> pendingAssignees = 
            [SELECT Id, ServiceAppointmentId, ServiceResourceId 
            FROM AssignedResource 
            WHERE ServiceResourceId IN :resourceMap.keySet() 
            AND ServiceAppointment.Status NOT IN ('Canceled', 'Cleared') 
            AND ServiceAppointment.SchedStartTime = Today];

        for( AssignedResource pendingAssignee : pendingAssignees ) {
            pendingResourceIds.add( pendingAssignee.ServiceResourceId );
        }
        System.debug( 'FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources: Updated Resources count = [' + resources.size() + '] - Pending Assigned Resources count = [' + pendingResourceIds.size() + ']' );
        for( ServiceResource resource : resources ) {
            if( pendingResourceIds.contains( resource.Id ) ) {
                if( resource.Idle__c && resource.RelatedRecord.isactive) {
                    resource.Idle__c = false;
                    resourcesToUpdate.add( resource );
                    System.debug( 'FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources: Setting Idle to false for Service Resource Id = [' + resource.Id + ']' );
                }
            } else {
                if( !resource.Idle__c && resource.RelatedRecord.isactive) {
                    resource.Idle__c = true;
                    resourcesToUpdate.add( resource );
                    System.debug( 'FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources: Setting Idle to true for Service Resource Id = [' + resource.Id + ']' );
                }
            }
        }
        if( !resourcesToUpdate.isEmpty() ) {
            System.debug( 'FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources: Updating Idle flags for [' + resourcesToUpdate.size() + '] Service Resources' );
            try{
                //update resourcesToUpdate;
                 updateServiceResources(resourcesToUpdate);
            }catch(Exception e){
                FSL_ApplicationLogCreator.schedulingLogger('FSL_IdleResource.evaluateIdleIndicatorOnResources',e.getmessage(),true);
            }
        }
    }
    private static void delay(Integer milliSec) {
        Long start = Datetime.now().getTime();
        while(Datetime.now().getTime() - start < milliSec);
    }
    
    @Future
    public static void updateRowLockResources(Map<Id,Boolean> serviceResources){
        FSL_Row_Lock_Retry_Configuration__mdt[]  entries = [SELECT Enabled__c, Maximum_Retries__c, Retry_Interval_In_Milliseconds__c FROM FSL_Row_Lock_Retry_Configuration__mdt WHERE Label = 'ServiceResource Retry'];
        if(!entries.isEmpty()){
            delay((Integer)entries[0].Retry_Interval_In_Milliseconds__c);
        }
        else{
                delay(1000);// Defaulting to 1 Second
        }
        List<ServiceResource> serviceResourceList=new List<ServiceResource>();
        for(Id serviceResourceId:serviceResources.keySet()){
            ServiceResource sr= new ServiceResource();
            sr.id=serviceResourceId;
            sr.Idle__c=serviceResources.get(serviceResourceId);
            serviceResourceList.add(sr);
        }
        if(!serviceResourceList.isEmpty()){
            try{
                update serviceResourceList;
            }
            catch(Exception e){
            FSL_ApplicationLogCreator.schedulingLogger('FSL_IdleResource.updateRowLockResources',e.getmessage(),true);
            }
        }
    }
    
    public static void updateServiceResources(List<ServiceResource> resourcesToUpdate){
        Map<Id,Boolean> newFailedObjects=new Map<Id,Boolean>();
        List<Database.upsertResult> resultList = Database.upsert(resourcesToUpdate, false);
        for (Integer i = 0; i < resourcesToUpdate.size(); i++) {
            Database.upsertResult sr = resultList[i];
            if (!sr.Issuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                        newFailedObjects.put(resourcesToUpdate[i].Id,resourcesToUpdate[i].Idle__c);
                    }else{
                        DMLException e =new  DMLException();
                        e.setMessage(err.getMessage());
                        throw e;
                    }
                }
            }
            if(runRowLock){
                newFailedObjects.put(resourcesToUpdate[0].id,resourcesToUpdate[0].Idle__c);
            }
        }
        if(!newFailedObjects.isEmpty()){
            updateRowLockResources(newFailedObjects);
        }
    }

    public static void removeIdleIndicatorOnAssignedResources(Map<Id, AssignedResource> assignedResourceMap){
        List<ServiceResource> resourcesToUpdate= new List<ServiceResource>();
        
        for(AssignedResource ar : assignedResourceMap.values()){
            if(ar.ServiceResource.Idle__c && ar.ServiceResource.RelatedRecord.Isactive){
                ServiceResource sr = new ServiceResource();
                sr.id = ar.ServiceResourceId;
                sr.Idle__c = false;
                resourcesToUpdate.add(sr);
            }
        }
        
        system.debug(resourcesToUpdate);
        if(!resourcesToUpdate.isEmpty()){
            try{
                //update resourcesToUpdate;
                updateServiceResources(resourcesToUpdate);
            }catch(Exception e){
                FSL_ApplicationLogCreator.schedulingLogger('FSL_IdleResource.removeIdleIndicatorOnAssignedResources',e.getmessage(),true);
            }
        }
    }
}