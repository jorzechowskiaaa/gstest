/**
 * @description			: Scheduler Class for Call Comment Consolidation Job
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
public class CallCommentsByDateRange_Scheduler implements schedulable{

    public static void execute(SchedulableContext sc){
        CallCommentsByDateRangeHandler handler = new CallCommentsByDateRangeHandler();
        Database.executeBatch(new CallCommentsByDateRange_Batch(handler), 200);
    }
}