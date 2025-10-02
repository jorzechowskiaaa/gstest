public with sharing class FSL_ClearQueueProcessingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    private List<FSLClearQueuedCall__c> calls;
    private FSL_ClearQueuedCall.IClearQueuedCallService service;
    private FSL_Schedule.IMinuteScheduleService minuteScheduleService;
    
    public FSL_ClearQueueProcessingBatch( List<FSLClearQueuedCall__c> calls ) {
        this.calls = calls;
    }
      
    public Iterable<SObject> start( Database.BatchableContext bc ) {
        return calls;
    }
        
    public void execute( Database.BatchableContext bc, List<SObject> scope ) {
        FSL_ClearQueuedCall.IClearQueuedCallService service = new FSL_ClearQueuedCall.Factory().createService();
        FSL_Schedule.IMinuteScheduleService minuteScheduleService = new FSL_Schedule.Factory().createService();

        service.sendClearRequests( (List<FSLClearQueuedCall__c>)scope, minuteScheduleService );
    }
        
    public void finish( Database.BatchableContext bc ) {
    }
}