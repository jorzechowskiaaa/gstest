@isTest
private class DriverLogoutEventTriggerHandler_Test {

    private static final String USER_NAME = 'standarduser12221234@testorg.com';
    private static final String PERM_SET_NAME = 'Mobile_Technician_Permission_Set';
    
    @TestSetup
    static void setup() {
        
        Id createdUserId = null;
        
        // Create the user and permission set assignment as the current running user to avoid MIXED DML error
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name=:PERM_SET_NAME LIMIT 1];
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
            User u = new User(
                Alias = 'standu1',
                Email=USER_NAME,
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName=USER_NAME
            );
            insert u;
            createdUserId = u.Id;
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = ps.Id,
                AssigneeId = u.Id
            );
            insert psa;
        }
        
        // Create a service resource which is used in the trigger handler
        ServiceResource resource = new ServiceResource();
        resource.Name = USER_NAME;
        resource.Driver_Id__c = '1234';
        resource.RelatedRecordId = createdUserId;
        insert resource;
    }
    
    @IsTest
    static void triggerLogoutEvent(){
        User u = [SELECT Id,Username FROM User WHERE username = :USER_NAME LIMIT 1];
        Test.startTest();
        LogoutEventStream event = new LogoutEventStream();
        event.UserId = u.Id;
		event.Username = u.Username;
        event.EventDate = DateTime.now();
        EventBus.publish(event);
        Test.stopTest();
    }
    
}