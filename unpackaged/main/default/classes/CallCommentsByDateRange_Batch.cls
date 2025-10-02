/**
 * @description			: Batch Class for Call Comment Consolidation Job. This was created because the scheduled flow was hiting Apex Heap limits trying to pull in all cleared WO's.
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
public class CallCommentsByDateRange_Batch implements Database.Batchable<sObject>{
    
    public CallCommentsByDateRangeHandler handler;
    
    public CallCommentsByDateRange_Batch(CallCommentsByDateRangeHandler handlerImpl){
        handler = handlerImpl;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(handler.queryText);
    }
    
    public void execute(Database.BatchableContext bc, list<WorkOrder> scope){
        handler.execute(scope);
    }
    
    public void finish(Database.Batchablecontext bc){
        System.debug('CallCommentsByDateRange_Batch: Finished current job.');
    }
}