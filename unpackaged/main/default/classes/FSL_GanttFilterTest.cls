@isTest
Public class FSL_GanttFilterTest {
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }    
    static Testmethod void FSLGantFilter(){
        
        FSL__Gantt_Filter__c gantfilter = new FSL__Gantt_Filter__c();
        gantfilter.Name = 'TestGantfilter';
        gantfilter.FSL__Public__c = true;    
        insert gantfilter;
        
        List<FSL__Gantt_Filter__Share> shareRecords = [Select Id from FSL__Gantt_Filter__Share ];
        System.assert(shareRecords.size() > 0,'Share records should be created');
    }
    
}