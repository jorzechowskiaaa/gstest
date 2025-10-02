/**
 * @File Name          : FSL_ResourceAbsenceTriggerHandler.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 06-22-2021
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    2/24/2020   Rajesh Kemisetti     Initial Version
 *       12/02/2020   Clement Shiu      ERS-220415 - Optimization helper refractoring
 *       06/03/2021   Clement Shiu      ERS-223573 - move update RA to the LKL class so that we can combine all the updates in one place.
**/


public class FSL_ResourceAbsenceTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<ResourceAbsence> newList = Trigger.new;
    List<ResourceAbsence> oldList = Trigger.old;
    Map<Id, ResourceAbsence> newMap = (Map<Id, ResourceAbsence>)Trigger.newMap;
    Map<Id, ResourceAbsence> oldMap = (Map<Id, ResourceAbsence>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ResourceAbsence');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        handleLastKnowLocationUpdate();
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        handleResourceAbsencesOptimization();       
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        handleLastKnowLocationUpdate();
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        handleAbsenceUpdates();
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterDelete() {
        handleDeletion(oldList);
    }

    
    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

    private void handleLastKnowLocationUpdate() {
        List<ResourceAbsence> raWithoutAddress = new List<ResourceAbsence>();
        for(ResourceAbsence ra : newList){
            ra.FSL__Approved__c = true; //Line added for converting ProcesBuilder to Code
            if(ra.Address == null && 'LKL'.equals(ra.FSL__GanttLabel__c)){
                raWithoutAddress.add(ra);
            }
        }
        if(!raWithoutAddress.isEmpty()){
            updateAddressWithLastKnownLocation(raWithoutAddress);
        }
    }
    
    private void handleResourceAbsencesOptimization() {
        List<ResourceAbsence> overlappingAbsences = new List<ResourceAbsence>();
        // check for overlapping absences
        for(ResourceAbsence ra : newList){
            if( (ra.FSL__GanttLabel__c != 'LKL') && ra.Type != 'Travel Delay' && FSL_OptimizationHelper.didCallCreateOverlap(null, null, ra)){
                overlappingAbsences.add(ra);
            }
        }
        
        if(!overlappingAbsences.isEmpty()){
            FSL_OptimizationHelper.optimizeResourceAbsences(overlappingAbsences,null);
        }
    }

    /**********
     * @Method Name:        handleDeletion
     * @Parameters:         List<ResourceAbsence> deletedAbsences
     * @Description:        Will Fll in the schedule of the resource who just had an absence delted from their schedule (they are now availble)
       @Requirement:        Optimize Schedule When Driver is Available (ID-345H)
       @Author:             Ryan Johnson
     * **********/        
    public static void handleDeletion(List<ResourceAbsence> deletedAbsences){
        DateTime nowTime = System.now();
        map<ID, Integer> candidateResourceIDsToDelta = new map<ID, Integer>();
        Map<Id,ResourceAbsence> rsIdAbsenceMap = new Map<Id,ResourceAbsence>();
        // check if this is a future-dated absence
        for(ResourceAbsence ra : deletedAbsences){
            if(ra.Start > nowTime|| ra.End > nowTime){
                Integer timeDelta = Integer.valueOf((ra.End.getTime() - ra.Start.getTime()) / 60000);
                candidateResourceIDsToDelta.put(ra.ResourceID, timeDelta);
                rsIdAbsenceMap.put(ra.resourceId,ra);
            }
        }

        if(!candidateResourceIDsToDelta.isEmpty()){            
            FSL_OptimizationHelper.optimizeResourcesWhoBecameAvailable(candidateResourceIDsToDelta,rsIdAbsenceMap);
        }                        
    }
    
    private void handleAbsenceUpdates(){
        DateTime nowTime = System.now();
        List<ResourceAbsence> overlappingAbsences = new List<ResourceAbsence>();
        map<ID, Integer> candidateResourceIDsToDelta = new map<ID, Integer>();
        Map<Id,ResourceAbsence> resourceIdAbsenceMap = new Map<Id,ResourceAbsence>();
        // look for relevant updates
        for(ResourceAbsence newRA : newList){
            
            // If end time was updated, and the absence now overlaps with appointments
              if( (!'LKL'.Equals(newRA.FSL__GanttLabel__c) ) && (newRA.End > nowTime) && (newRA.End > oldMap.get(newRA.ID).End) ){
                if(FSL_OptimizationHelper.didCallCreateOverlap(null, null, newRA)){
                    overlappingAbsences.add(newRA);
                }
            }else if( (newRA.Start > nowTime) && (newRA.Start < oldMap.get(newRA.ID).Start) ){
                Integer newDuration = Integer.valueOf((newRA.End.getTime() - newRA.Start.getTime()) / 60000);
                Integer oldDuration = Integer.valueOf((oldMap.get(newRA.ID).End.getTime() - oldMap.get(newRA.ID).Start.getTime()) / 60000);                
                //Pass the difference of the old duration to new duration as delta so it can be compared against RSO threshold                
                candidateResourceIDsToDelta.put(newRA.ResourceID, math.abs(oldDuration-newDuration));
                resourceIdAbsenceMap.put(newRA.ResourceID,newRA);
            } else if((newRA.End > nowTime) && (newRA.End < oldMap.get(newRA.ID).End)) {
                Integer newDuration = Integer.valueOf((newRA.End.getTime() - newRA.Start.getTime()) / 60000);
                Integer oldDuration = Integer.valueOf((oldMap.get(newRA.ID).End.getTime() - oldMap.get(newRA.ID).Start.getTime()) / 60000);                
                //Pass the difference of the old duration to new duration as delta so it can be compared against RSO threshold                
                candidateResourceIDsToDelta.put(newRA.ResourceID, math.abs(newDuration-oldDuration));
                resourceIdAbsenceMap.put(newRA.ResourceID,newRA);
               /* if(FSL_OptimizationHelper.didCallCreateOverlap(null, null, newRA)){
                    overlappingAbsences.add(newRA);
                }*/
            }
            
        }
        
        // run RSO for each resource with an overlapping absence
        if(!overlappingAbsences.isEmpty()){
            FSL_OptimizationHelper.optimizeResourceAbsences(overlappingAbsences,oldMap);
        }
        
        if(!candidateResourceIDsToDelta.isEmpty()){
            FSL_OptimizationHelper.optimizeResourcesWhoBecameAvailable(candidateResourceIDsToDelta,resourceIdAbsenceMap);
        }
        
    }
    
    private void updateAddressWithLastKnownLocation(List<ResourceAbsence> newAbsences){
        Set<ID> srSet = new Set<ID>();
        for(ResourceAbsence ra : newAbsences){
            srSet.add(ra.ResourceId);
        }
        
        List<ServiceResource> srList = [SELECT id, LastKnownLatitude, LastKnownLongitude FROM ServiceResource WHERE ID IN :srSet];
        
        for(ResourceAbsence ra : newAbsences){
            for(ServiceResource sr : srList){
                if(sr.id == ra.ResourceId){
                    ra.Latitude = sr.LastKnownLatitude;
                    ra.Longitude = sr.LastKnownLongitude;
                }
            }
        }
        system.debug('resource absences after update = '+ newAbsences);
    }
    
    public static void checkAbsenceForOverlaps(List<ResourceAbsence> newAbsences){
        try{
            FSL_Optimization_Settings__c oSettings = FSL_Optimization_Settings__c.getOrgDefaults();
            if(oSettings.Optimize_Absence_Overlaps__c){
                
                List<ResourceAbsence> overlappingAbsences = new List<ResourceAbsence>();
                
                for(ResourceAbsence ra : newAbsences){
                    if(FSL_OptimizationHelper.didCallCreateOverlap(null, null, ra)){
                        overlappingAbsences.add(ra);
                    }
                }
                
                if(!overlappingAbsences.isEmpty()){
                    FSL_OptimizationHelper.bulkFixOverlaps(overlappingAbsences);
                }
            }
        }catch(Exception e){
            system.debug('Exception caught: ' + e);
        }
    }
    
    
    
}