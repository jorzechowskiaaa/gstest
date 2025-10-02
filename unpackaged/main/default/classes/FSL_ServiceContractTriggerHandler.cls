/**
 *  Trigger Handler class for Service Contracts. This class will auto-populate Contract Line items from a Parent Service Contract when 
 *  a new Service Contract is inserted or an existing Service Contract is updated.
 */

public class FSL_ServiceContractTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {


    List<ServiceContract> newList = Trigger.new;
    List<ServiceContract> oldList = Trigger.old;
    Map<Id, ServiceContract> newMap = (Map<Id, ServiceContract>)Trigger.newMap;
    Map<Id, ServiceContract> oldMap = (Map<Id, ServiceContract>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ServiceContract');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        Map<ServiceContract, ID> serviceContractToParentContractMap = new Map<ServiceContract, ID>();
        List<ServiceContract> contractsWithNewAccount = new List<ServiceContract>();

        //BUG? This will be always empty since it is never get modified
        // Set<ID> newAccountIdSet = new Set<ID>();

        // check the parent contract field and populate matching line items from price book
        for(ServiceContract sContract : newList){
            if(sContract.ParentServiceContractID != null){
                serviceContractToParentContractMap.put(sContract, sContract.ParentServiceContractID);
            }
            if(sContract.Accountid !=Null){
                contractsWithNewAccount.add(sContract);               
            }
        }

        //BUG? This will be always empty since it is never get modified
        // if(!newAccountIdSet.isEmpty()) { 
        //     shareContractWithTerritoryGroup(contractsWithNewAccount);
        // }

        // add line items from parent
        if(!serviceContractToParentContractMap.isEmpty()){
            createContractLineItemMap(serviceContractToParentContractMap);
        }

        if(!contractsWithNewAccount.isEmpty()){
            // share contract with territory
            shareContractWithTerritoryGroup(contractsWithNewAccount);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        Map<ServiceContract, ID> serviceContractToParentContractMap = new Map<ServiceContract, ID>();
        List<ServiceContract> contractsWithNewAccount = new List<ServiceContract>();
        Set<ID> sContractIDSet = new Set<ID>();

        // check the parent contract field for updates
        for(ID sContractID : newMap.keySet()){
            if(newMap.get(sContractID).ParentServiceContractID != oldMap.get(sContractID).ParentServiceContractID){
                serviceContractToParentContractMap.put(newMap.get(sContractID), newMap.get(sContractID).ParentServiceContractID);
                sContractIDSet.add(sContractID);
                
            }
            if(newMap.get(sContractID).AccountID != oldMap.get(sContractID).AccountId){
                contractsWithNewAccount.add(newMap.get(sContractID));
            }       
        }

            // delete existing line items?
        if(!sContractIDSet.isEmpty()){
            deleteStaleLineItems(sContractIDSet);
        }

        // add line items from parent
        if(!serviceContractToParentContractMap.isEmpty()){
            createContractLineItemMap(serviceContractToParentContractMap);
        }

        if(!contractsWithNewAccount.isEmpty()){
            // share contract with territory
            shareContractWithTerritoryGroup(contractsWithNewAccount);
        }
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

  
    private static void shareContractWithTerritoryGroup(List<ServiceContract> sContractList){
        // get list of of accounts assoicated to service contracts (for territory names)
        Set<ID> accountIDs = new Set<ID>();
        for(ServiceContract sContract : sContractList){
            accountIDs.add(sContract.AccountID);
        }

        List<Account> accountList = [SELECT id, Service_Territory__c, Service_Territory__r.Name 
            FROM Account WHERE ID IN :accountIDs];

        Map<ServiceContract, String> contractToTerritoryMap = new Map<ServiceContract, String>();
        Set<String> territories = new Set<String>();
        // create map of Service Contract --> Territory Name
        for(ServiceContract sContract : sContractList){
            for(Account acc : accountList){
                if(sContract.AccountID == acc.ID){
                    contractToTerritoryMap.put(sContract, acc.Service_Territory__r.Name);
                    territories.add(acc.Service_Territory__r.Name);
                }
            }

        }

        // Get Territory Groups based on Territory Names
        List<Group> pGroupList = [Select id,name from Group where name IN :territories];

        List<ServiceContractShare> sharingList = new List<ServiceContractShare>();

        for(ServiceContract sContract : contractToTerritoryMap.keySet()){
            for(Group grp : pGroupList){
                if(contractToTerritoryMap.get(sContract) == grp.Name){
                    // create new share record
                    ServiceContractShare sContractShare = new ServiceContractShare();
                    sContractShare.ParentId = sContract.id;
                    sContractShare.UserOrGroupId  = grp.id;
                    sContractShare.AccessLevel = 'Read';
                    sharingList.add(sContractShare);
                }
            }
        }

        if(!sharingList.isEmpty()){
           delete [Select Id,UserOrGroupId from ServiceContractShare where userOrGroupId Not In(Select OwnerId from ServiceContract where Id IN : contractToTerritoryMap.keySet()) AND parentId IN :contractToTerritoryMap.keySet()];
            insert sharingList;
        }

    }
  
  private static void deleteStaleLineItems(Set<ID> sContractIDSet){
    List<ContractLineItem> staleLineItemList = [SELECT  id FROM ContractLineItem WHERE ServiceContractID IN :sContractIDSet];
    system.debug('Following contract line items are being deleted: ' + staleLineItemList);
    delete staleLineItemList;
  }
  
  private static List<ContractLineItem> createContractLineItemMap(Map<ServiceContract, ID> serviceContractToParentContractMap){

    List<ContractLineItem> newLineItemList = new List<ContractLineItem>();
    Map<ID, List<ContractLineItem>> parentContractToLineItemMap = new Map<ID, List<ContractLineItem>>();
    
    List<ContractLineItem> existingLineItems = [SELECT  PricebookEntryID,StartDate,EndDate, Product2ID, Type__c, ServiceContractID, ListPrice, UnitPrice, Quantity 
        FROM ContractLineItem WHERE ServiceContractID IN :serviceContractToParentContractMap.values() AND ActiveProduct__c = true];
    system.debug(existingLineItems);

    // Create Map of Contracts / Line Items
    for(ID parentContractID : serviceContractToParentContractMap.values()){
        List<ContractLineItem> selectedLineItems = new List<ContractLineItem>();
        for(ContractLineItem item : existingLineItems){
            if(item.ServiceContractID == parentContractID){
                selectedLineItems.add(item);
            }
        }
        parentContractToLineItemMap.put(parentContractID, selectedLineItems);
    }
    if(!parentContractToLineItemMap.isEmpty()){
    return populateLineItemsFromParent(serviceContractToParentContractMap, parentContractToLineItemMap);
    }else{
        return null;
    }
  }
  
  private static List<ContractLineItem> populateLineItemsFromParent(Map<ServiceContract, ID> serviceContractToParentContractMap, Map<ID, List<ContractLineItem>> parentContractToLineItemMap){
    List<ContractLineItem> itemsToCreate = new List<ContractLineItem>();
    // for each new / updated contract
    for(ServiceContract sContract : serviceContractToParentContractMap.keySet()){
        // Get the List of the parent contract's Line Items
        List<ContractLineItem> parentLineItems = parentContractToLineItemMap.get(sContract.ParentServiceContractID);
        for(ContractLineItem itemToClone : parentLineItems){
            // Clone each line item and associate with new / updated contract
            // 1) Do not preserve ID, 
            // 2) Deep Clone (create new references)
            // 3) Do not preserve timestamps
            // 4) Do not preserve autonumbers
            ContractLineItem newItem = itemToClone.clone(false, true, false, false);
            newItem.ServiceContractID = sContract.id;
            //newItem.StartDate = itemToClone.StartDate;
            //newItem.EndDate = itemToClone.EndDate;
            itemsToCreate.add(newItem);
            
        }
    }
    system.debug('following items will be created: ' + itemsToCreate);
    upsert itemsToCreate;
    return itemsToCreate;
  }  
}