/**
 * @description			: Test Class for CallCommentsByDateRangeHandler.
 * @author				: cyaskoski@aaanortheast.com
 * @last modified on	: 4-15-2024
 * @last modified by	: cyaskoski@aaanortheast.com
 * Modifications Log
 * Ver		Date			Author							Modification
 * 1.0		4-15-2024		cyaskoski@aaanortheast.com		Initial Version
**/ 
@isTest
public class CallCommentsByDateRangeHandlerTest {
  
    public testMethod static void commentMergeTest(){
        
        Decimal numberDaysLookback = Time_Limit_Configuration__mdt.getInstance('Call_Comment_Merge_After_Clear_In_Days').Number_of_Days__c;
        WorkOrder wo = new WorkOrder();
        wo.Cleared_Timestamp__c = Datetime.now().addDays(-Integer.valueOf(numberDaysLookback));
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
        Test.startTest();
        handler.execute(new List<WorkOrder>{wo});
        Test.stopTest();
        
        FSL_Call_Comments__c mergedComment = [SELECT FSL_Comment__c FROM FSL_Call_Comments__c WHERE FSL_Work_Order__c = :wo.Id LIMIT 1];        
        System.assert(mergedComment?.FSL_Comment__c.contains(comment1.FSL_Comment__c), 'Content from the first comment should be present in the merged comment.');
        System.assert(mergedComment?.FSL_Comment__c.contains(comment2.FSL_Comment__c), 'Content from the second comment should be present in the merged comment.');
        
        FSL_Application_Log__c appLogEntry = [SELECT Success_Message__c FROM FSL_Application_Log__c WHERE Operation__c = 'CallCommentMerge' LIMIT 1];
        System.assert(appLogEntry?.Success_Message__c.contains('Successfully Merged Call Comments'), 'App Log Entry for merged comments should be present.');
    }
}