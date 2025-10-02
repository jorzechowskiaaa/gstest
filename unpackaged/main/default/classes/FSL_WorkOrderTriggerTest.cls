@IsTest
public inherited sharing class FSL_WorkOrderTriggerTest {
    @IsTest
    public static void testWorkOrderTrigger_BeforeUpdate_ContactIdChanged_MemberAccountIdUpdatedToRelatedIdOfContact() {

        List<Account> oldAccounts = new List<Account>();
        oldAccounts.add( new Account( Name = 'Old Account 1' ) );
        oldAccounts.add( new Account( Name = 'Old Account 2' ) );
        List<Account> newAccounts = new List<Account>();
        newAccounts.add( new Account( Name = 'New Account 1' ) );
        newAccounts.add( new Account( Name = 'New Account 2' ) );

        List<Account> allAccounts = new List<Account>();
        allAccounts.addAll( oldAccounts );
        allAccounts.addAll( newAccounts );
        insert allAccounts;

        List<Contact> oldContacts = new List<Contact>();
        oldContacts.add( new Contact( LastName = 'Old Contact 1', AccountId = oldAccounts[0].Id ) );
        oldContacts.add( new Contact( LastName = 'Old Contact 2', AccountId = oldAccounts[1].Id ) );
        List<Contact> newContacts = new List<Contact>();
        newContacts.add( new Contact( LastName = 'New Contact 1', AccountId = newAccounts[0].Id ) );
        newContacts.add( new Contact( LastName = 'New Contact 2', AccountId = newAccounts[1].Id ) );

        List<Contact> allContacts = new List<Contact>();
        allContacts.addAll( oldContacts );
        allContacts.addAll( newContacts );
        insert allContacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < 2; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', oldContacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;

        System.assertEquals( oldContacts[0].Id, workOrders[0].ContactId, 'Arrange: First WorkOrder\'s Contact ID does not match first old Contact\'s ID' );
        System.assertEquals( oldAccounts[0].Id, workOrders[0].Member_Account__c, 'Arrange: First WorkOrder\'s Member Account ID does not match first old Account\'s ID' );
        System.assertEquals( oldContacts[1].Id, workOrders[1].ContactId, 'Arrange: Second WorkOrder\'s Contact ID does not match second old Contact\'s ID' );
        System.assertEquals( oldAccounts[1].Id, workOrders[1].Member_Account__c, 'Arrange: Second WorkOrder\'s Member Account ID does not match second old Account\'s ID' );
        System.assertEquals( newAccounts[0].Id, newContacts[0].AccountId, 'Arrange: First new Contact\'s Account ID does not match second new Account\'s ID' );
        System.assertEquals( newAccounts[1].Id, newContacts[1].AccountId, 'Arrange: Second new Contact\'s Account ID does not match second new Account\'s ID' );
        
        Test.startTest();
        workOrders[0].ContactId = newContacts[0].Id;
        workOrders[1].ContactId = newContacts[1].Id;
        update workOrders;
        Test.stopTest();

        workOrders = [SELECT Id, ContactId, Member_Account__c FROM WorkOrder ORDER BY External_Id__c];
        System.assertEquals( newContacts[0].Id, workOrders[0].ContactId, 'Assert: First WorkOrder\'s Contact ID was not updated to the expected value' );
        System.assertEquals( newContacts[1].Id, workOrders[1].ContactId, 'Assert: Second WorkOrder\'s Contact ID was not updated to the expected value' );
        System.assertEquals( newAccounts[0].Id, workOrders[0].Member_Account__c, 'Assert: First WorkOrder\'s Member Account ID was not updated to the expected value' );
        System.assertEquals( newAccounts[1].Id, workOrders[1].Member_Account__c, 'Assert: Second WorkOrder\'s Member Account ID was not updated to the expected value' );
    }

    @IsTest
    public static void testTriggerUtility_StatusChanges_Cleared(){
        Test.startTest(); 
            Boolean allowed = FSL_TriggerUtility.isStatusTransitionAllowed('Cleared', 'In Progress', null); 
        Test.stopTest(); 
        System.assertEquals(false, allowed); 
    }
    @IsTest
    public static void testTriggerUtility_StatusChanges_New(){
        Test.startTest(); 
            Boolean allowed = FSL_TriggerUtility.isStatusTransitionAllowed('New', 'In Progress', null); 
        Test.stopTest(); 
        System.assertEquals(true, allowed); 
    }
    @IsTest
    public static void testTriggerUtility_StatusChanges_OnHold(){
        FSL.StatusTransition st = new FSL.StatusTransition('New' ,'On Hold' ); 
        Test.startTest(); 
            Boolean allowed = FSL_TriggerUtility.isStatusTransitionAllowed('New', 'On Hold', new List<FSL.StatusTransition> {st}); 
        Test.stopTest(); 
        System.assertEquals(true, allowed); 
    }
    
    @isTest
    public static void testClone(){
        Account acnt = new Account( Name = 'Test Account' );
        insert acnt;
        Contact cnt = new Contact( LastName = 'Test Contact', AccountId = acnt.Id );
        insert cnt;
        WorkOrder origWO = FSL_DataFactory.createWorkOrderShell('Light Service', cnt);
        origWO.External_Id__c = 'ERS-1';
        insert origWO;
        
        test.startTest();
        WorkOrder tWO = origWO.clone(false,false,false,false);
        insert tWO;
        Test.stopTest();
        
        WorkOrder testWO = [select Id, ClonedParent__c from WorkOrder where id = :tWO.id];       
        system.assertEquals(testWO.ClonedParent__c,origWO.Id);
    }

}