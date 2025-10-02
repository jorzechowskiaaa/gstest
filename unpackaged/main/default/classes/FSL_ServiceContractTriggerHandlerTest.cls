@isTest
public class FSL_ServiceContractTriggerHandlerTest{

    @TestSetup
    static void setupData(){
        // also includes initial account and service contract setup
        FSL_DataFactoryUtility.userdataSetup();
    }

    static testMethod void test_shareContractWithTerritoryGroup(){
        
        Test.startTest();
            
            // locate any service contract with an Account
            ServiceContract sContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
                FROM ServiceContract WHERE AccountID != null
                LIMIT 1];

            // query Account details
            Account territoryAccount = [SELECT id, Service_Territory__c, Service_Territory__r.Name 
                FROM Account WHERE ID = :sContract.AccountID
                LIMIT 1];

            system.debug('territory account = ' + territoryAccount);
        
            // identify sharing on service contract sharing records
            List<ServiceContractShare> shareRecordList = [SELECT ParentId, UserOrGroupId, UserOrGroup.Name, AccessLevel 
                FROM ServiceContractShare WHERE ParentId = :sContract.id];

            Set<String> groupsWithContractSharing = new Set<String>();
            for(ServiceContractShare shareRecord : shareRecordList){
                system.debug(shareRecord);
                groupsWithContractSharing.add(shareRecord.UserOrGroup.Name);
            }

            // assert that the Service Contract is shared with the Service Territory Group
            system.assertEquals(groupsWithContractSharing.contains(territoryAccount.Service_Territory__r.Name), true, 'Contract is not Shared With ' + territoryAccount.Service_Territory__r.Name);

            // locate a new territory account
            Account territoryAccount2 = [SELECT  id, Service_Territory__c, Service_Territory__r.Name 
            FROM Account WHERE ID != :territoryAccount.ID AND Service_Territory__c != null
            LIMIT 1];

            // update the account on the Service Contract and verify sharing
            sContract.AccountID = territoryAccount2.id;
            update sContract;

            groupsWithContractSharing.clear();
            for(ServiceContractShare shareRecord : shareRecordList){
                system.debug(shareRecord);
                groupsWithContractSharing.add(shareRecord.UserOrGroup.Name);
            }

            // assert that the Service Contract is shared with the Service Territory Group
            system.assertEquals(groupsWithContractSharing.contains(territoryAccount.Service_Territory__r.Name), true, 'Contract is not Shared With ' + territoryAccount.Service_Territory__r.Name);

        Test.stopTest();
    }

    static testMethod void test_deleteStaleLineItems(){
        Test.startTest();

            Date yesterday = Date.today().addDays(-1);
            // locate any service contract with an Account
            ServiceContract parentServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
                FROM ServiceContract WHERE AccountID != null AND ParentServiceContractID = null
                LIMIT 1];

            ServiceContract childServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
                FROM ServiceContract WHERE AccountID != null AND ParentServiceContractID = :parentServiceContract.id
                LIMIT 1];     

            List<PricebookEntry> priceEntries = [SELECT ID, IsActive, Pricebook2ID 
                FROM PricebookEntry 
                WHERE IsActive = true AND Pricebook2ID = :childServiceContract.Pricebook2ID];
            
            // remove parent contract
            childServiceContract.ParentServiceContractID = null;
            update childServiceContract;
            
            // add line item to child contract
            ContractLineItem childContractItem = FSL_DataFactory.createCLI('Variable', childServiceContract.ID, priceEntries.get(0).id, 10, 3, yesterday);
            insert childContractItem;

            // query number of line itmes assigned to contract
            List<ContractLineItem> assignedItems = [SELECT id FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
            system.assertEquals(1, assignedItems.size(), 'The number of assigned contract line items is incorrect');

            // update the parent service contract to one that does not have any line items assigned
            childServiceContract.ParentServiceContractID = parentServiceContract.id;
            update childServiceContract;           

            // query number of line itmes assigned to contract
            assignedItems.clear();
            assignedItems = [SELECT id FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
            system.assertEquals(0, assignedItems.size(), 'The number of assigned contract line items is incorrect');


        Test.stopTest();
    }

    /*
    static testMethod void test_createContractLineItemMap(){} 
    */  
    
    static testMethod void test_populateLineItemsFromParent(){
        Test.startTest();

            Date yesterday = Date.today().addDays(-1);
            // locate any service contract with an Account
            ServiceContract parentServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
                FROM ServiceContract WHERE AccountID != null AND ParentServiceContractID = null
                LIMIT 1];

            ServiceContract childServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
                FROM ServiceContract WHERE AccountID != null AND ParentServiceContractID = :parentServiceContract.id
                LIMIT 1];     

            List<PricebookEntry> priceEntries = [SELECT ID, IsActive, Pricebook2ID 
                FROM PricebookEntry 
                WHERE IsActive = true AND Pricebook2ID = :parentServiceContract.Pricebook2ID];
            
            // remove parent contract
            childServiceContract.ParentServiceContractID = null;
            update childServiceContract;
            
            // add line item to parent contract
            ContractLineItem parentContractItem = FSL_DataFactory.createCLI('Variable', parentServiceContract.ID, priceEntries.get(0).id, 10, 3, yesterday);
            insert parentContractItem;

            // query number of line itmes assigned to child contract
            List<ContractLineItem> assignedItems = [SELECT id FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
            system.assertEquals(0, assignedItems.size(), 'The number of assigned contract line items is incorrect');

            // update the parent service contract to one that does have line items assigned
            childServiceContract.ParentServiceContractID = parentServiceContract.id;
            update childServiceContract;           

            // query number of line itmes assigned to contract
            assignedItems.clear();
            assignedItems = [SELECT id FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
            system.assertEquals(1, assignedItems.size(), 'The number of assigned contract line items is incorrect');


        Test.stopTest();


    }   

}