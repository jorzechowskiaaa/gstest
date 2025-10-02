/**
 * @description			: Test Class for CallCommentsByDateRange_Batch.
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
@isTest
public class CallCommentsByDateRange_BatchTest {
    
	public testMethod static void excerciseBatchCallComments(){
        
        Decimal numberDaysLookback = Time_Limit_Configuration__mdt.getInstance('Call_Comment_Merge_After_Clear_In_Days').Number_of_Days__c;
        WorkOrder wo = new WorkOrder();
        wo.Cleared_Timestamp__c =  Datetime.now().addDays(-Integer.valueOf(numberDaysLookback));
        wo.Status = 'Cleared';
        insert wo;
        
        List <FSL_Call_Comments__c> commentsList = new List <FSL_Call_Comments__c>();
        
        FSL_Call_Comments__c comment1 = new FSL_Call_Comments__c();
        comment1.FSL_Work_Order__c = wo.Id;
        comment1.FSL_Comment__c = 'DRRWeb 2.0 In a Parking Lot PASSENGERS: 0';
        commentsList.add(comment1);
        
        FSL_Call_Comments__c comment2 = new FSL_Call_Comments__c();
        comment2.FSL_Work_Order__c = wo.Id;
        comment2.FSL_Comment__c = 'Breakdown Location Coordinates: 41.846419,-71.413194';
        commentsList.add(comment2);
        
        insert commentsList;
        
        CallCommentsByDateRangeHandler handler = new CallCommentsByDateRangeHandler();
        Database.executeBatch(new CallCommentsByDateRange_Batch(handler), 200);
    }
}