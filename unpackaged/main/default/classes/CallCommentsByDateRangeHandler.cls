/**
 * @description			: Handler Class for the Call Comment Consolidation Job
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
public class CallCommentsByDateRangeHandler {    
    
    // Determine number of days to look back
    private Decimal numberDaysLookback = Time_Limit_Configuration__mdt.getInstance('Call_Comment_Merge_After_Clear_In_Days').Number_of_Days__c;
    
    // Default query to pull in WorkOrders for Comment Consolidation
    public String queryText = 'SELECT Id FROM WorkOrder WHERE Status = \'Cleared\' AND Cleared_Timestamp__c = N_DAYS_AGO:' + Integer.valueOf(numberDaysLookback);
    
    public void execute(List<WorkOrder> woList){
        
        // Call Existing Apex Method that Flow uses which utilized list of list WO
        list<list<string>> listOfstringMessgetoReturn = FSL_CallCommentsByDateRange.createDeleteCallComment(new list<list<workOrder>> {woList}); 
        
        // Take return list of list String and create App Log via Platform Event mirroring Flow's logic
        if(listOfstringMessgetoReturn != null && listOfstringMessgetoReturn.size() > 0 && listOfstringMessgetoReturn[0] != null && listOfstringMessgetoReturn[0].size() > 0){
            
            String commentString = 'From ' + string.valueOf(Datetime.now()) + ' Cleared N_DAYS_AGO:' + Integer.valueOf(numberDaysLookback) + ' [';
            for(String curString : listOfstringMessgetoReturn[0]){
                commentString = commentString + '\n' + curString;
            }
            if(commentString.length() > 32760){
                commentString = commentString.abbreviate(32760);
            }
            commentString = commentString + ']';
            
            Application_Log_Event__e appLogEvent = new Application_Log_Event__e();
            appLogEvent.Error_Caught__c= false;
            appLogEvent.Message__c = commentString;
            appLogEvent.Operation__c = 'CallCommentMerge';
            EventBus.publish(appLogEvent);                
        } 
    }
}