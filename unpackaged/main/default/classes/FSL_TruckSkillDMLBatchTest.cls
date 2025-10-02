@isTest
public class FSL_TruckSkillDMLBatchTest {
    
    static testmethod void test1(){
        Test.startTest();
        
        Schema.Location[] vehLocations = [select id from Location];
        Vehicle_Skill__c[] vehSkills = [select id from Vehicle_Skill__c];
        ServiceResourceSkill[] createProfSkillAndDeleteSRS = [select id from ServiceResourceSkill];
        
        FSL_TruckSkillDMLBatch batchUpsert = new FSL_TruckSkillDMLBatch(vehLocations,'Upsert');
        Database.executeBatch(batchUpsert,500);

        FSL_TruckSkillDMLBatch batchUpdate = new FSL_TruckSkillDMLBatch(vehLocations,'Update');
        Database.executeBatch(batchUpdate,500);
        
        
        FSL_TruckSkillDMLBatch batchInsert = new FSL_TruckSkillDMLBatch(vehLocations,'Insert');
        Database.executeBatch(batchInsert,500);
        
        FSL_TruckSkillDMLBatch batchDelete = new FSL_TruckSkillDMLBatch(vehLocations,'Delete');
        Database.executeBatch(batchDelete,500);
        
		        
        Test.stopTest();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }	
}