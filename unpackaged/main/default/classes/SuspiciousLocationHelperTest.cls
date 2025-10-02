@IsTest
public class SuspiciousLocationHelperTest {
	 
	@isTest public static void testCase1() {
		
		SuspiciousLocationHelper.flowInput input = new SuspiciousLocationHelper.flowInput(); 
		List<Case> caseList = new List<Case>();
		Case c = new Case(Landmark__c = 'Test'); 
		caseList.add(c);

		Case d = new Case(Tow_Destination_Name__c = 'Begins with');
		caseList.add(d);

		Case e = new Case(Landmark__c = 'Landmark', Tow_Destination_Name__c = 'At the end');
		caseList.add(e);

		Case f = new Case(Tow_Destination_Name__c = 'Second end');
		caseList.add(e);

		Case g = new Case();
		caseList.add(g); 

		input.caseList = caseList; 
		List<SuspiciousLocationHelper.FlowInput> inputs = new List<SuspiciousLocationHelper.FlowInput>();
		inputs.add(input); 

		//case d = new case(Tow_Destination_Name__c = 'Salvage');
		//case e = new case(Landmark__c = 'Test3', Tow_Destination_Name__c = 'Recycling');

		Test.startTest();
		SuspiciousLocationHelper slh = new SuspiciousLocationHelper(); 
		List<SuspiciousLocationHelper.FlowOutput> outputs = new List<SuspiciousLocationHelper.FlowOutput>(); 
		outputs = SuspiciousLocationHelper.checkCaseList(inputs); 
		Test.stopTest();
		System.assertEquals(True, outputs[0].processedCases[0].Investigate_Location__c, 'First test should equal true'); 
		system.assertEquals(caseList.size(), outputs[0].processedCases.size(), 'Input size should equal output size'); 
	} 

}