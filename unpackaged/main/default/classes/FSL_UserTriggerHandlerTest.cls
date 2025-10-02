@isTest
public class FSL_UserTriggerHandlerTest {
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    static testMethod void truckAssignmentTest(){
        
        User user = [select id,Truck_Number__c from User where alias = 'D_Fleet'];
        Schema.Location location = [select id from Location where Facility_Number__c='9198'];
        
        System.Test.startTest();
        user.Truck_Number__c = '9198';        	
        update user;
        ServiceResource serResAfterNullify = [select Id, Vehicle__c from ServiceResource where RelatedRecordId =: user.Id];
        system.debug('serResAfterNullify:'+serResAfterNullify);
        System.Test.stopTest();
    }
    
    static testMethod void userProfileUpdateTest(){
        Profile dispatcherProfile = [SELECT Id FROM Profile WHERE Name = 'FSL Club Dispatcher'];
        User user = [select id,Truck_Number__c,ProfileId from User where alias = 'D_Fleet'];
        System.Test.startTest();
        //List<GroupMember> beforeGroupMembers = [Select Id from GroupMember];
        user.ProfileId = dispatcherProfile.Id;
        update user;
        //List<GroupMember> afterGroupMembers = [Select Id from GroupMember];
        //System.assert(beforeGroupMembers.size() <= afterGroupMembers.size(),'Unextpected behavior while inserting group member');
        System.Test.stopTest();
    }
    
    static testMethod void userProfileUpdateTest1(){
        Profile clubAdminProfile = [SELECT Id FROM Profile WHERE Name = 'FSL Club Administrator'];        
        User user = [select id,Truck_Number__c,ProfileId from User where alias = 'D_Fleet'];
        System.Test.startTest();
        //List<GroupMember> beforeGroupMembers = [Select Id from GroupMember];
        user.ProfileId = clubAdminProfile.Id;
        update user;
        //List<GroupMember> afterGroupMembers = [Select Id from GroupMember];
        //System.assert(beforeGroupMembers.size() <= afterGroupMembers.size(),'Unextpected behavior while inserting group member');
        System.Test.stopTest();
    }
    
    static testMethod void shareAccountWithUserTest(){

        list<User> userList = [select id,Truck_Number__c,ProfileId from User where alias IN('D_Fleet','T_Fleet')];
        
        System.Test.startTest();
        List<AccountShare> beforeInsert = [select id from AccountShare];
        FSL_UserTriggerHandler.shareAccountWithUser(userList); 
        List<AccountShare> afterInsert = [select id from AccountShare];        	
        System.assert(beforeInsert.size() <= afterInsert.size() ,'Account could not be shared.');
        System.Test.stopTest();
        
    }
}