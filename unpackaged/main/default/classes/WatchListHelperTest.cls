/**
* @File Name : WatchListHelper.cls
* @Description : For https://aaa-ne.atlassian.net/browse/SSFI-931, Gets active warning for ERS watch list
* @Author : John Orzechowski
* @Last Modified On : May 7, 2025
**/

@isTest
public class WatchListHelperTest {
	
	@isTest public static void testGetMessageWithRecord() {

		Id watchListRT = Schema.SObjectType.Winter_Advisory__c.getRecordTypeInfosByDeveloperName()
    		.get('ERS_Watch_List').getRecordTypeId();
        
        Winter_Advisory__c wa = new Winter_Advisory__c(
            Advisory_Message_Display__c = 'Test',
            Active__c = True,
			recordTypeId = watchListRT
        	);
        insert wa;

		Test.startTest();
		String warningText = WatchListHelper.getWarningText();
		Test.stopTest();
		System.assertEquals('Test', warningText, 'Method should return test advisory message');
 
    }

	@isTest public static void testGetMessageWithoutRecord() {


		Test.startTest();
		String warningText = WatchListHelper.getWarningText();
		Test.stopTest();
		System.assertEquals(null, warningText, 'Method should not return test advisory message');
 
    }

	@isTest public static void testGetStatusWithRecord() {
		
		ERS_Watch_List__c ewl = new ERS_Watch_List__c(
			AAA_ACA_Club_Code__c = '240',
			AAA_ACA_MembershipID__c = 'test',
			AAA_ACA_AssociateId__c = '22'
		);
		insert ewl;

		Test.startTest(); 
		Boolean result = WatchListHelper.getWatchListStatus('240', 'test', '22', '620240test022222');
		Test.stopTest();
		System.assertEquals(True, result, 'Method should return true');
	
	}

	@isTest public static void testGetStatusWithoutRecord() {
		

		Test.startTest(); 
		// also test with membership number of length < 16
		Boolean result = WatchListHelper.getWatchListStatus('240', 'test111222333', '22', '620240test0222');
		Test.stopTest();
		System.assertEquals(False, result, 'Method should not return true');
	
	}
}