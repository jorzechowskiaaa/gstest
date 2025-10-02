/**
 * @description       : Listens for updates to Optimization Requests and sends details to the Dispatch Utility
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-07-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   01-07-2021   Clement Shiu            ERS-220594: Modify this class and move most of the methods to FSL_DispatchUtility
**/
public class FSL_OptimizationRequestTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<FSL__Optimization_Request__c> newList = Trigger.new;
    List<FSL__Optimization_Request__c> oldList = Trigger.old;
    Map<Id, FSL__Optimization_Request__c> newMap = (Map<Id, FSL__Optimization_Request__c>)Trigger.newMap;
    Map<Id, FSL__Optimization_Request__c> oldMap = (Map<Id, FSL__Optimization_Request__c>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FSL__Optimization_Request__c');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        Boolean requestCompleted = false;
        Boolean objectsScheduled = false;
        List<FSL__Optimization_Request__c> completedOptimizationRequests = new List<FSL__Optimization_Request__c>();
        for(ID requestID : newMap.keySet()){
            // has status changed to completed
            requestCompleted = (newMap.get(requestID).FSL__Status__c == 'Completed') && (oldMap.get(requestID).FSL__Status__c != 'Completed');
            
            // have objects been scheduled
            objectsScheduled =  newMap.get(requestID).FSL__Objects_Scheduled__c > 0;

            if(requestCompleted && objectsScheduled){
                completedOptimizationRequests.add(newMap.get(requestID));
            }
        }

        if(!completedOptimizationRequests.isEmpty()){
            FSL_DispatchUtility.reDispatchOptimizedAppointments(completedOptimizationRequests);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterDelete() {
        FSL_OptimizationRequest.IFactory factory = new FSL_OptimizationRequest.Factory();
        FSL_OptimizationRequest.IOptimizationRequestService service = factory.createService();
        service.OnDelete(oldList);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

}