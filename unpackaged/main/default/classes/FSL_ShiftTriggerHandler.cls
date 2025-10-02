/**
 * @File Name          : FSL_ShiftTriggerHandler.cls
 * @Description        :
 * @Author             : Rajesh Kemisetti
 * @Group              :
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 3/17/2020, 2:59:09 PM
 * @Modification Log   :
 * Ver       Date            Author                  Modification
 * 1.0    3/9/2020   Rajesh Kemisetti     Initial Version
 **/

public class FSL_ShiftTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<Shift> newList = Trigger.new;
    List<Shift> oldList = Trigger.old;
    Map<Id, Shift> newMap = (Map<Id, Shift>)Trigger.newMap;
    Map<Id, Shift> oldMap = (Map<Id, Shift>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Shift');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeInsert() {
        updateShiftHrsPerResourceTZ(newList, oldMap);   
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        Set<Id> territoryIdSet = new Set<Id>();
        Map<Id, String> territoryNameMap = new Map<Id, String>();
        for (Shift sf : newList){
            if (sf.ServiceTerritoryId != null){
                territoryIdSet.add(sf.ServiceTerritoryId);
            }
        }
        //Sharing records
        if (!territoryIdSet.isEmpty()){
            List<ServiceTerritory> territoryList = [Select 
                                                          Id, 
                                                          Name
                                                    from ServiceTerritory
                                                    where Id IN :territoryIdSet];
            List<ShiftShare> shareShiftList = new List<ShiftShare>();
            for (ServiceTerritory str : territoryList){
                territoryNameMap.put(str.Id, str.Name);
            }
            // Get Territory Groups based on Territory Names
            List<Group> pGroupList = [Select 
                                            id, 
                                            name
                                      from Group
                                      where name IN :territoryNameMap.values()];
            Map<String, Group> groupNameMap = new Map<String, Group>();
            for (Group gp : pGroupList){
                groupNameMap.put(gp.Name, gp);
            }
            for (Shift sf : newList){
                if (sf.ServiceTerritoryId != null && groupNameMap.get(territoryNameMap.get(sf.ServiceTerritoryId)) != null){
                    ShiftShare sfShare = new ShiftShare();
                    sfShare.ParentId = sf.id;
                    sfShare.UserOrGroupId = groupNameMap.get(territoryNameMap.get(sf.ServiceTerritoryId)).Id;
                    sfShare.AccessLevel = 'Read';
                    shareShiftList.add(sfShare);
                }
            }
            if (!shareShiftList.isEmpty()){
                insert shareShiftList;
            }
        }
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeUpdate() {
        updateShiftHrsPerResourceTZ(newList, oldMap);   
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    /**
     * @description
     * @author Rajesh Kemisetti | 3/9/2020
     * @param newShifts
     * @return void
     **/
    private static void updateShiftHrsPerResourceTZ(List<Shift> newShifts, Map<Id, Shift> oldMap){
        Timezone userTimezone = UserInfo.getTimeZone();
        map<Id, list<Shift>> resourceToShifts = new map<Id, list<Shift>>();
        map<Id, Id> mapResourceToTerritoryId = new map<Id, Id>();
        Set<Id> notTerritoryShiftRsIdSet = new Set<Id>();
        for (Shift shft : newShifts){
            if (!resourceToShifts.containsKey(shft.ServiceResourceId)){
                resourceToShifts.put(shft.ServiceResourceId, new list<Shift>());
            }
            resourceToShifts.get(shft.ServiceResourceId).add(shft);
            if(shft.ServiceTerritoryId != null) {
                mapResourceToTerritoryId.put(shft.ServiceresourceId, shft.ServiceTerritoryId);
            }else {
                notTerritoryShiftRsIdSet.add(shft.ServiceresourceId);
            }
            
        }
        //Implemented this logic for UF-1425(Consider Primary service Territory of Resource when Territory not populated to shift)
        if(!notTerritoryShiftRsIdSet.isEmpty()) {
            for(ServiceResource sr : [Select Id,Primary_Service_Territory__c from ServiceResource where ID IN :notTerritoryShiftRsIdSet ]) {
                mapResourceToTerritoryId.put(sr.Id,sr.Primary_Service_Territory__c);
            }
        }
        
        map<Id, ServiceTerritory> mapTerritories = new map<Id, ServiceTerritory>([select 
                                                                                        id, 
                                                                                        OperatingHours.TimeZone
                                                                                  from ServiceTerritory
                                                                                  where ID IN :mapResourceToTerritoryId.values()]);
        if (!mapTerritories.isEmpty()){
            for (Shift shft : newShifts){
                TimeZone resourceTimeZone = Timezone.getTimeZone(mapTerritories.get(mapResourceToTerritoryId.get(shft.ServiceresourceId)).OperatingHours.TimeZone);
                system.debug(shft.StartTime);
                Integer offSetHours = (userTimeZone.getOffset(shft.StartTime) - resourceTimeZone.getOffset(shft.StartTime)) / (60000 * 60);
                if (oldMap==null)
                {
                    shft.Territory_LocalEndTime__c = shft.EndTime.format('MM/dd/yyyy h:mm a');
                    shft.Territory_LocalStartTime__c = shft.StartTime.format('MM/dd/yyyy h:mm a');
                    shft.StartTime = shft.StartTime.addHours(offSetHours);
                    shft.EndTime = shft.EndTime.addHours(offSetHours);
                }else if (!oldMap.isEmpty()){ 
                    if(
                        oldMap.containsKey(shft.id) && 
                        oldMap.get(shft.id).StartTime != shft.StartTime
                      )
                    {
                        shft.Territory_LocalStartTime__c = shft.StartTime.format('MM/dd/yyyy h:mm a');
                        shft.StartTime = shft.StartTime.addHours(offSetHours);
                    } 
                    if(
                        oldMap.containsKey(shft.id) && 
                        oldMap.get(shft.id).EndTime != shft.EndTime
                      )
                    {
                        shft.Territory_LocalEndTime__c = shft.EndTime.format('MM/dd/yyyy h:mm a');
                        shft.EndTime = shft.EndTime.addHours(offSetHours);                
                    }
                }
            }
        }
    }
}