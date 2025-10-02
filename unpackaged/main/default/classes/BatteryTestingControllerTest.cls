/**
 * @description       : Test class for BatteryTestingController - SSFI 1176 B2Q App
 * @author            : Patel Minesh
 * @last modified on  : 08-12-2025
 * @last modified by  : Patel Minesh
**/
@isTest
private class BatteryTestingControllerTest {

    @isTest
    static void testCheckBatteryTestingPermission_Granted() {
        User testUser = new User(
            ProfileId = UserInfo.getProfileId(),
            LastName = 'tTest',
            FirstName = 'tUser',
            Email = 'testuser@ttest.com',
            Username = 'testuser@ttest.com' + System.now().millisecond(),
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Battery_Testing']; 

        PermissionSet ps = new PermissionSet();
        ps.Label = 'Test Battery Testing';
        ps.Name = 'Test_Battery_Testing' + System.now().millisecond();
        insert ps;
        
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testUser.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = cp.Id;
        insert sea;

        System.runAs(testUser) {
            Boolean hasPermission = BatteryTestingController.checkBatteryTestingPermission();
            System.assertEquals(true, hasPermission, 'Expected Battery_Testing permission to be granted.');
        }
    }

    @isTest
    static void testCheckBatteryTestingPermission_NotGranted() {
        Boolean hasPermission = BatteryTestingController.checkBatteryTestingPermission();
        System.assertEquals(false, hasPermission, 'Expected Battery_Testing permission to not be granted.');
    }
}