public class FSL_ServiceTerritoryMemberTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
     
    List<ServiceTerritoryMember> newList = Trigger.new;
    List<ServiceTerritoryMember> oldList = Trigger.old;
    Map<Id, ServiceTerritoryMember> newMap = (Map<Id, ServiceTerritoryMember>)Trigger.newMap;
    Map<Id, ServiceTerritoryMember> oldMap = (Map<Id, ServiceTerritoryMember>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('ServiceTerritoryMember');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        FSL_UpdateSRPrimaryTerritory.updateTerritoryMemberAddress(newList);

    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        Map<Id,Id> srSTIdMap = new Map<Id,Id>();
        //List<ServiceTerritoryMember> primarySTMList = new List<ServiceTerritoryMember>();
        for(ServiceTerritoryMember stm : newMap.values()) {
            if(stm.TerritoryType == 'P') {
                srSTIdMap.put(stm.ServiceResourceId,stm.ServiceTerritoryId);
            }
        }
        System.debug('///////srSTIdMap = ' + srSTIdMap);

        if(!srSTIdMap.isEmpty()) {
            FSL_UpdateSRPrimaryTerritory.updateSRPrimaryTerritory(srSTIdMap);
            FSL_UpdateSRPrimaryTerritory.shareServiceResourcewithPublicGroup(srSTIdMap);
        }

        List<ServiceTerritoryMember> primarySTMInserts = new List<ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : newList){
            if (stm.TerritoryType == 'P'){
                primarySTMInserts.add(stm);
            }
        }
        if(!primarySTMInserts.isEmpty()){
            FSL_UpdateSRPrimaryTerritory.addRelatedTerritories(primarySTMInserts);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        FSL_UpdateSRPrimaryTerritory.updateTerritoryMemberAddress(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        Map<Id,Id> srSTIdMap = new Map<Id,Id>();
        for(ServiceTerritoryMember stmNew : newList) {
            for(ServiceTerritoryMember stmOld : oldList) {
                if(stmNew.Id == stmOld.Id) {
                    if(stmNew.TerritoryType == 'P' && stmOld.TerritoryType != 'P') {
                        srSTIdMap.put(stmNew.ServiceResourceId, stmNew.ServiceTerritoryId);

                    } else if(stmNew.TerritoryType != 'P' && stmOld.TerritoryType == 'P') {
                        srSTIdMap.put(stmNew.ServiceResourceId, null);
                    }
                }
            }
        }
        System.debug('///////srSTIdMap = ' + srSTIdMap);
        if(!srSTIdMap.isEmpty()) {
            FSL_UpdateSRPrimaryTerritory.updateSRPrimaryTerritory(srSTIdMap);
        }

        List<ServiceTerritoryMember> primarySTMUpdates = new List<ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : newList){
            if (stm.TerritoryType == 'P'){
                primarySTMUpdates.add(stm);
            }
        }
        if(!primarySTMUpdates.isEmpty()){
            FSL_UpdateSRPrimaryTerritory.addRelatedTerritories(primarySTMUpdates);
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

}