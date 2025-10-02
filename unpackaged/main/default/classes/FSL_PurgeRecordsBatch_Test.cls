@isTest
public class FSL_PurgeRecordsBatch_Test {
    @isTest
    public static void testPurgeBatch(){
        string q = 'select id from Technology_Preference__c'; 
        
        FSL_PurgeRecordsBatch batch = new FSL_PurgeRecordsBatch(q, 1);        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, batch); 
		
        Database.executeBatch(batch, 1);
        
        list<Technology_Preference__c> prefs  = [select id from Technology_Preference__c];
        batch.execute(null, prefs);        
    }
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
}