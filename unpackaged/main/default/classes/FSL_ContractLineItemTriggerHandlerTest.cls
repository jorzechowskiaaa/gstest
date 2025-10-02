@isTest    
Public class FSL_ContractLineItemTriggerHandlerTest{
    

    @TestSetup
    static void setupData(){
        // also includes initial account and service contract setup
        FSL_DataFactoryUtility.userdataSetup();
    }
    
    static testMethod void test_handleNewLineItems(){
        Test.startTest();

        Date yesterday = Date.today().addDays(-1);

        // find a Territory Account
        Account territoryAccount;
        List<Account> territoryAccountList = [SELECT id, Name, Service_Territory__c FROM Account WHERE Service_Territory__c != ''];
        if(!territoryAccountList.isEmpty()){
            territoryAccount = territoryAccountList.get(0);
        }

        // locate any service contract with an Account
        ServiceContract parentServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE AccountID = :territoryAccount.id AND ParentServiceContractID = null
            LIMIT 1];

        ServiceContract childServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE ParentServiceContractID = :parentServiceContract.id
            LIMIT 1];     

        List<PricebookEntry> priceEntries = [SELECT ID, IsActive, Pricebook2ID 
            FROM PricebookEntry 
            WHERE IsActive = true AND Pricebook2ID = :parentServiceContract.Pricebook2ID];
        
        // assert that the child contract has no items
        List<ContractLineItem> cliList = [SELECT id, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
        system.assertEquals(cliList.size(), 0, 'the contract does not have the correct number of line itmes');
        
        // add line item to parent contract
        ContractLineItem parentContractItem = FSL_DataFactory.createCLI('Variable', parentServiceContract.ID, priceEntries.get(0).id, 10, 3, yesterday);
        insert parentContractItem;   
        
        // assert that the child contract also received the item
        cliList.clear();
        cliList = [SELECT id, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];        
        system.assertEquals(cliList.size(), 1, 'the contract does not have the correct number of line itmes');


    }

    static testMethod void test_handleUpdatedLineItems(){
        Test.startTest();

        Date yesterday = Date.today().addDays(-1);

        // find a Territory Account
        Account territoryAccount;
        List<Account> territoryAccountList = [SELECT id, Name, Service_Territory__c FROM Account WHERE Service_Territory__c != ''];
        if(!territoryAccountList.isEmpty()){
            territoryAccount = territoryAccountList.get(0);
        }

        // locate any service contract with an Account
        ServiceContract parentServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE AccountID = :territoryAccount.id AND ParentServiceContractID = null
            LIMIT 1];

        ServiceContract childServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE ParentServiceContractID = :parentServiceContract.id
            LIMIT 1];     

        List<PricebookEntry> priceEntries = [SELECT ID, IsActive, Pricebook2ID 
            FROM PricebookEntry 
            WHERE IsActive = true AND Pricebook2ID = :parentServiceContract.Pricebook2ID];
        
        // add line item to parent contract
        ContractLineItem parentContractItem = FSL_DataFactory.createCLI('Variable', parentServiceContract.ID, priceEntries.get(0).id, 10, 3, yesterday);
        insert parentContractItem; 

        // assert that the child contract has no items
        List<ContractLineItem> cliList = [SELECT id, UnitPrice, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
        ContractLineItem childCLI;
        if(!cliList.isEmpty()){
            childCLI = cliList.get(0);
        }

        // assert price on child contract item is copied from parent on insert
        system.assertEquals(childCLI.UnitPrice, 10, 'contract line item price is unexpected');

        // update parent cli price
        Integer newPrice = 15;
        parentContractItem.UnitPrice = newPrice;
        update parentContractItem;

        // pull latest value from child CLI
        cliList = [SELECT id, UnitPrice, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
        if(!cliList.isEmpty()){
            childCLI = cliList.get(0);
        }

        // assert the price has changed
        system.assertEquals(childCLI.UnitPrice, newPrice, 'contract line item price is unexpected');
        

    }    
    
    static testMethod void test_handleNewDeletedItems(){
        Test.startTest();

        Date yesterday = Date.today().addDays(-1);

        // find a Territory Account
        Account territoryAccount;
        List<Account> territoryAccountList = [SELECT id, Name, Service_Territory__c FROM Account WHERE Service_Territory__c != ''];
        if(!territoryAccountList.isEmpty()){
            territoryAccount = territoryAccountList.get(0);
        }

        // locate any service contract with an Account
        ServiceContract parentServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE AccountID = :territoryAccount.id AND ParentServiceContractID = null
            LIMIT 1];

        ServiceContract childServiceContract = [SELECT id, AccountID, ParentServiceContractID, Pricebook2ID, StartDate, EndDate 
            FROM ServiceContract WHERE ParentServiceContractID = :parentServiceContract.id
            LIMIT 1];     

        List<PricebookEntry> priceEntries = [SELECT ID, IsActive, Pricebook2ID 
            FROM PricebookEntry 
            WHERE IsActive = true AND Pricebook2ID = :parentServiceContract.Pricebook2ID];
        
        // add line item to parent contract
        ContractLineItem parentContractItem = FSL_DataFactory.createCLI('Variable', parentServiceContract.ID, priceEntries.get(0).id, 10, 3, yesterday);
        insert parentContractItem; 

        List<ContractLineItem> cliList = [SELECT id, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];
        system.assertEquals(cliList.size(), 1, 'the contract does not have the correct number of line itmes');
        
        // delete parent line item
        delete parentContractItem;

        // query for latest count of CLI on chil contract
        cliList = [SELECT id, ServiceContractID FROM ContractLineItem WHERE ServiceContractID = :childServiceContract.id];

        // assert that the line items were deleted from the child contract
        system.assertEquals(cliList.size(), 0, 'the contract does not have the correct number of line itmes');
                
        
    } 
    
    static testMethod void test_getChildContracts(){
    
    }
    
    static testMethod void test_getContractToLineItemListMap(){
    
    } 
    
    static testMethod void test_getLineItemMap(){
    
    }     
    
    /*
    static testmethod void ContractlineitemTest(){
        Map<id,ContractLineItem> oldmap = new Map<id,ContractLineItem>();
        Map<id,ContractLineItem> newmap = new Map<id,ContractLineItem>();  
        Map<ContractLineItem,ContractLineItem> Clitem = new Map<ContractLineItem,ContractLineItem>();     
        // First, set up test price book entries.
        // Insert a test product.
        Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware');
        insert prod;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        // 2. Insert a price book entry with a custom price.
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice; 
        
        Account acc = new Account(name='Test Account');
        insert acc;
        ServiceContract  sc1 = new ServiceContract ();
        sc1.AccountId = acc.id;
        sc1.Name= 'sample contract';
        sc1.Pricebook2Id= customPB.id;
        sc1.StartDate =system.today();
        sc1.EndDate =  System.today()+20;
        insert sc1;
        
        ServiceContract  sc = new ServiceContract ();
        sc.AccountId = acc.id;
        sc.ParentServiceContract = sc1;
        sc.ParentServiceContractID = sc1.Id;
        sc.Name = 'sc contract';
        sc.Pricebook2Id= customPB.id;
        sc.StartDate =system.today();
        sc.EndDate = System.today()+20;
        insert sc;
        
        List<ContractLineItem> sloldlist = new list<ContractLineItem>(); 
        List<ContractLineItem> slnewlist = new list<ContractLineItem>(); 
        ContractLineItem cli = new ContractLineItem();
        cli.PricebookEntryId = customPrice.id;
        cli.Quantity = 20;
        cli.UnitPrice = 32;
        cli.ServiceContractId = sc1.Id;
        sloldlist.add(cli);  
        cli.Type__c ='variable';
        slnewlist.add(cli);
        
        
        ContractLineItem cli1 = new ContractLineItem();
        cli1.PricebookEntryId = customPrice.id;
        cli1.Quantity = 20;
        cli1.UnitPrice = 32;
        cli1.ServiceContractId = sc1.Id;
        ContractLineItem cli2 = new ContractLineItem();
        cli2.PricebookEntryId = customPrice.id;
        cli2.Quantity = 20;
        cli2.UnitPrice = 32;
        cli2.ServiceContractId = sc.Id;
        slnewlist.add(cli2);
        slnewlist.add(cli1);
        insert slnewlist;
        
    }
    Static testmethod void ContractlineitemTestUpdate(){
        Map<id,ContractLineItem> oldmap = new Map<id,ContractLineItem>();
        Map<id,ContractLineItem> newmap = new Map<id,ContractLineItem>();  
        Map<ContractLineItem,ContractLineItem> Clitem = new Map<ContractLineItem,ContractLineItem>();     
        // First, set up test price book entries.
        // Insert a test product.
        Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware');
        insert prod;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        // 2. Insert a price book entry with a custom price.
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice; 
        
        Account acc = new Account(name='Test Account');
        insert acc;
        ServiceContract  sc1 = new ServiceContract ();
        sc1.AccountId = acc.id;
        sc1.Name= 'sample contract';
        sc1.Pricebook2Id= customPB.id;
        sc1.StartDate =system.today();
        sc1.EndDate =  System.today()+20;
        insert sc1;
        
        ServiceContract  sc = new ServiceContract ();
        sc.AccountId = acc.id;
        sc.ParentServiceContract = sc1;
        sc.ParentServiceContractID = sc1.Id;
        sc.Name = 'sc contract';
        sc.Pricebook2Id= customPB.id;
        sc.StartDate =system.today();
        sc.EndDate = System.today()+20;
        insert sc;
        
        List<ContractLineItem> sloldlist = new list<ContractLineItem>(); 
        List<ContractLineItem> slnewlist = new list<ContractLineItem>(); 
        ContractLineItem cli = new ContractLineItem();
        cli.PricebookEntryId = customPrice.id;
        cli.Quantity = 20;
        cli.UnitPrice = 32;
        cli.ServiceContractId = sc1.Id;
        sloldlist.add(cli);  
        cli.Type__c ='variable';
        slnewlist.add(cli);
        
        ContractLineItem cli1 = new ContractLineItem();
        cli1.PricebookEntryId = customPrice.id;
        cli1.Quantity = 20;
        cli1.UnitPrice = 32;
        cli1.ServiceContractId = sc1.Id;
        ContractLineItem cli2 = new ContractLineItem();
        cli2.PricebookEntryId = customPrice.id;
        cli2.Quantity = 20;
        cli2.UnitPrice = 32;
        cli2.ServiceContractId = sc.Id;
        slnewlist.add(cli2);
        slnewlist.add(cli1);
        insert slnewlist;
        slnewlist[0].UnitPrice = 40;
        update slnewlist;
        
    }
    Static testmethod void ContractlineitemTestDelete(){
        Map<id,ContractLineItem> oldmap = new Map<id,ContractLineItem>();
        Map<id,ContractLineItem> newmap = new Map<id,ContractLineItem>();  
        Map<ContractLineItem,ContractLineItem> Clitem = new Map<ContractLineItem,ContractLineItem>();     
        // First, set up test price book entries.
        // Insert a test product.
        Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware');
        insert prod;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        // 2. Insert a price book entry with a custom price.
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice; 
        
        Account acc = new Account(name='Test Account');
        insert acc;
        ServiceContract  sc1 = new ServiceContract ();
        sc1.AccountId = acc.id;
        sc1.Name= 'sample contract';
        sc1.Pricebook2Id= customPB.id;
        sc1.StartDate =system.today();
        sc1.EndDate =  System.today()+20;
        insert sc1;
        
        ServiceContract  sc = new ServiceContract ();
        sc.AccountId = acc.id;
        sc.ParentServiceContract = sc1;
        sc.ParentServiceContractID = sc1.Id;
        sc.Name = 'sc contract';
        sc.Pricebook2Id= customPB.id;
        sc.StartDate =system.today();
        sc.EndDate = System.today()+20;
        insert sc;
        
        List<ContractLineItem> sloldlist = new list<ContractLineItem>(); 
        List<ContractLineItem> slnewlist = new list<ContractLineItem>(); 
        ContractLineItem cli = new ContractLineItem();
        cli.PricebookEntryId = customPrice.id;
        cli.Quantity = 20;
        cli.UnitPrice = 32;
        cli.ServiceContractId = sc1.Id;
        sloldlist.add(cli);  
        cli.Type__c ='variable';
        slnewlist.add(cli);
        
        ContractLineItem cli1 = new ContractLineItem();
        cli1.PricebookEntryId = customPrice.id;
        cli1.Quantity = 20;
        cli1.UnitPrice = 32;
        cli1.ServiceContractId = sc1.Id;
        ContractLineItem cli2 = new ContractLineItem();
        cli2.PricebookEntryId = customPrice.id;
        cli2.Quantity = 20;
        cli2.UnitPrice = 32;
        cli2.ServiceContractId = sc.Id;
        slnewlist.add(cli2);
        slnewlist.add(cli1);
        insert slnewlist;
        delete slnewlist;
        
    }

    */


}