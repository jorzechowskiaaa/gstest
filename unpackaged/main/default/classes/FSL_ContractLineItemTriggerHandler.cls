public class FSL_ContractLineItemTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<ContractLineItem> newList = Trigger.new;
    List<ContractLineItem> oldList = Trigger.old;
    Map<Id, ContractLineItem> newMap = (Map<Id, ContractLineItem>)Trigger.newMap;
    Map<Id, ContractLineItem> oldMap = (Map<Id, ContractLineItem>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ContractLineItem');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
		List<ContractLineItem> newLineItems = new List<ContractLineItem>();

		for(ContractLineItem lineItem : newList){
			newLineItems.add(lineItem);
		}
		if(!newLineItems.isEmpty()){
			handleNewLineItems(newLineItems);
		}
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
		List<ContractLineItem> updatedLineItems = new List<ContractLineItem>();

		for(ContractLineItem lineItem : newList){
			if( (lineItem.Type__c != oldMap.get(lineItem.id).Type__c) 
				||	(lineItem.StartDate != oldMap.get(lineItem.id).StartDate)
				|| 	(lineItem.EndDate != oldMap.get(lineItem.id).EndDate) 
				|| (lineItem.UnitPrice != oldMap.get(lineItem.id).UnitPrice) )
			{
				updatedLineItems.add(lineItem);		
			}
		}
		if(!updatedLineItems.isEmpty()){
			handleUpdatedLineItems(updatedLineItems);
		}
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterDelete() {
		List<ContractLineItem> deletedLineItems = new List<ContractLineItem>();

		for(ContractLineItem lineItem : oldList){
			deletedLineItems.add(lineItem);	
		}
		if(!deletedLineItems.isEmpty()){
			handleNewDeletedItems(deletedLineItems);
		}
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

  
    private static void handleNewLineItems(List<ContractLineItem> recordSet){
    	// get list of child service contracts
    	List<ContractLineItem> itemsToCreate = new List<ContractLineItem>();
    	try{
	    	system.debug('In handleNewLineItems');
	    	List<ServiceContract> childServiceContracts = getChildContracts(recordSet);
	    	
	    	// get Map of Children Line Items (same product in a child Service Contract)
	    	Map<ServiceContract, List<ContractLineItem>> sContractToLineItemMap = getContractToLineItemListMap(recordSet, childServiceContracts);
	    	
	    	// if no match is found in the map, add new line item to child contract
	    	for(ServiceContract contract : sContractToLineItemMap.keySet()){
	    		for(ContractLineItem itemToClone : sContractToLineItemMap.get(contract)){
					ContractLineItem newItem = itemToClone.clone(false, true, false, false);
					newItem.ServiceContractID = contract.id;
					itemsToCreate.add(newItem);
	    		}
	    	}
	    	
	    	upsert itemsToCreate;
    	}
    	catch(Exception e){
			system.debug('Error creating new line items: ' + e.getMessage() + ' at ' + e.getLineNumber());	
	
    	}
    	
    }
    
    private static void handleUpdatedLineItems(List<ContractLineItem> recordSet){
    	List<ContractLineItem> itemsToUpdate = new List<ContractLineItem>();
    	try{
	     	system.debug('In handleUpdatedLineItems');
	    	
	    	// get list of child service contracts
	    	List<ServiceContract> childServiceContracts = getChildContracts(recordSet);
	    	
	    	// get Map of Children Line Items (same product in a child Service Contract)
			// NOTE** Map has child contract line item as the key (to ensure uniqueness)
	    	Map<ContractLineItem, ContractLineItem> itemMap = getLineItemMap(recordSet, childServiceContracts);
	    	
	    	// if match is found in the map, update line item on child contract
	    	for(ContractLineItem childItem : itemMap.keySet()){
	    		ContractLineItem triggerIem = itemMap.get(childItem);
	    		childItem.Type__c = triggerIem.Type__c;
				childItem.StartDate = triggerIem.StartDate;
				childItem.EndDate = triggerIem.EndDate;
				childItem.UnitPrice = triggerIem.UnitPrice;
	    		itemsToUpdate.add(childItem);
	    	}
	    	
	    	upsert itemsToUpdate;
	    	
	    	
    	}
    	catch(Exception e){
    		system.debug('Error updating existing line items: ' + e);	
    	}    	
    }
    
    private static void handleNewDeletedItems(List<ContractLineItem> recordSet){
    	List<ContractLineItem> itemsToDelete = new List<ContractLineItem>();
    	try{    	
	        system.debug('In handleNewDeletedItems');
	    	
	    	// get list of child service contracts
	    	List<ServiceContract> childServiceContracts = getChildContracts(recordSet);
	    	
	    	// get Map of Children Line Items (same product in a child Service Contract)
			// NOTE** Map has child contract line item as the key (to ensure uniqueness)
	    	Map<ContractLineItem, ContractLineItem> itemMap = getLineItemMap(recordSet, childServiceContracts);
	    	
	    	// if match is found in the map, delete line item on child contract
	    	for(ContractLineItem childItem : itemMap.keySet()){
	    		itemsToDelete.add(childItem);
	    	}
	    	
	    	delete itemsToDelete;
    	}
    	catch(Exception e){
    		system.debug('Error deleting new child line items: ' + e);	
    	}     	
    	
    }
    
    private static List<ServiceContract> getChildContracts(List<ContractLineItem> contractLineItemList){
    	Set<ID> serviceContractIDSet = new Set<ID>();
    	// get list of service contract corresponding to the line item
    	for(ContractLineItem lineItem : contractLineItemList){
    		serviceContractIDSet.add(lineItem.ServiceContractID);
    	}
    	
    	List<ServiceContract> childServiceContracts = [SELECT id, ParentServiceContractID FROM ServiceContract WHERE ParentServiceContractID IN :serviceContractIDSet];
    	system.debug('Found the following child service contracts: ' + childServiceContracts);
    	return childServiceContracts;
    	
    }
    
    private static Map<ServiceContract, List<ContractLineItem>> getContractToLineItemListMap(List<ContractLineItem> contractLineItemList, List<ServiceContract> childServiceContracts){
		Set<ID> serviceContractIDSet = new Set<ID>();
    	Map<ServiceContract, List<ContractLineItem>> contractItemInsertList = new Map<ServiceContract, List<ContractLineItem>>();
    	
    	for(ServiceContract sContract : childServiceContracts){
    		serviceContractIDSet.add(sContract.ID);
    	}		

		// Get list of all of the contract line items from child service contracts
		List<ContractLineItem> childContractLineItems = [SELECT id, EndDate, StartDate, ServiceContractID, Product2ID, Status 
			FROM ContractLineItem WHERE ServiceContractID IN :serviceContractIDSet];
			
		// create map of contract to set of product IDs
		Map<ID, Set<ID>> contractIDTOProductIDsMap = new Map<ID, Set<ID>>();
		for(ContractLineItem itm : childContractLineItems){
			Set<ID> productIDSet = contractIDTOProductIDsMap.get(itm.ServiceContractID);
			if(productIDSet == null){
				productIDSet = new Set<ID>();
			}
			productIDSet.add(itm.Product2ID);
			contractIDTOProductIDsMap.put(itm.ServiceContractID, productIDSet);

		}
			
		// find if child contract contains product from new item
		
		// check each child contract
		for(ServiceContract childContract : childServiceContracts){
			List<ContractLineItem> clonedContractItemList = new List<ContractLineItem>();
			// to see if the item that started the trigger 
			for(ContractLineItem triggerItem : contractLineItemList){
				// has an entry with the same product in the child contract			
				Set<ID> productsFromChildContract = contractIDTOProductIDsMap.get(childContract.id);
				if( (productsFromChildContract == null) || (!productsFromChildContract.contains(triggerItem.Product2ID)) ){
					// add the new contract item to the list to be inserted
					clonedContractItemList.add(triggerItem);
				}
			}
			contractItemInsertList.put(childContract, clonedContractItemList);
			
		}
		
		system.debug('Created the following service contract to contract item map: ' + contractItemInsertList);
		return contractItemInsertList;
		


    }
    
    private static Map<ContractLineItem, ContractLineItem> getLineItemMap(List<ContractLineItem> contractLineItemList, List<ServiceContract> childServiceContracts){
		Set<ID> serviceContractIDSet = new Set<ID>();
    	Map<ContractLineItem, ContractLineItem> childToParentContractLineItemMap = new Map<ContractLineItem, ContractLineItem>();
    	
    	for(ServiceContract sContract : childServiceContracts){
    		serviceContractIDSet.add(sContract.ID);
    	}		

		List<ContractLineItem> childContractLineItems = [SELECT id, EndDate, StartDate, ServiceContractID, Product2ID, Status 
			FROM ContractLineItem WHERE ServiceContractID IN :serviceContractIDSet];
			
		for(ContractLineItem triggerItem : contractLineItemList){
			for(ContractLineItem relatedItem : childContractLineItems){
				if(triggerItem.Product2ID == relatedItem.Product2ID){
					childToParentContractLineItemMap.put(relatedItem, triggerItem);
				}
			}
		}
		
		system.debug('Created the following map of child line item to parent line item: ' + childToParentContractLineItemMap);
		return childToParentContractLineItemMap;

    }                
}