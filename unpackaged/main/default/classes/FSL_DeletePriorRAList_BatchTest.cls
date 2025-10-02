@isTest
Public class FSL_DeletePriorRAList_BatchTest{
    static testmethod void deletePriorAbscence(){
        
        List<ResourceAbsence> deltedAbsences = FSL_DataFactory.CreateResourceAbsences('LKL');
        Test.setCreatedDate(deltedAbsences[0].Id,System.now().addDays(-100));
        
        Test.startTest();

        FSL_DeletepriorResourceAbsenceList_Batch dRA = new FSL_DeletepriorResourceAbsenceList_Batch();
        dRA.errorList = new List<String>{'Test'};
        database.executeBatch(dRA);
        
        String squery = 'select id,type,FSL__GanttLabel__c from ResourceAbsence where FSL__GanttLabel__c =\'LKL\'order by CreatedDate';
        FSL_DeletepriorResourceAbsenceList_Batch dRA2 = new FSL_DeletepriorResourceAbsenceList_Batch(squery);
        database.executeBatch(dRA2);
		
        deltedAbsences = [select id from ResourceAbsence FOR UPDATE];
		dRA2 = new FSL_DeletepriorResourceAbsenceList_Batch(squery);
        database.executeBatch(dRA2);        

        Test.stopTest();
    }

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    } 
    
    
    
}