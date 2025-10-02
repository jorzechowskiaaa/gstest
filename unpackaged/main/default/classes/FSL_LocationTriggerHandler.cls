public class FSL_LocationTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<Schema.Location> newList = Trigger.new;
    List<Schema.Location> oldList = Trigger.old;
    Map<Id, Schema.Location> newMap = (Map<Id, Schema.Location>)Trigger.newMap;
    Map<Id, Schema.Location> oldMap = (Map<Id, Schema.Location>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('Location');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        shareLocationWithFacility(newMap);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() { 
        shareLocationWithFacility(newMap);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    private static void shareLocationWithFacility(Map<Id, Schema.Location> locationMap){
        Set<String> facilityNames = new Set<String>();
        for(Schema.Location loc : locationMap.values()){
            facilityNames.add(loc.Formula_Name__c);
        }
        
        system.debug('facility names = ' + facilityNames);        
        List<Group> pGroupList = [Select id,name from Group where name IN :facilityNames];
        system.debug('location groups = ' + pGroupList);
        
        List<LocationShare> locShareList = new List<LocationShare>();
        for(Schema.Location loc : locationMap.values()){
            for(Group pGrp : pGroupList ){
                system.debug('location facility: ' + loc.Formula_Name__c + '; Group Name: ' + pGrp.Name);
                if(loc.Formula_Name__c == pGrp.Name){
                    LocationShare shareRecord = new LocationShare();
                    shareRecord.ParentID = loc .Id;
                    shareRecord.UserOrGroupId = pGrp.Id;
                    shareRecord.AccessLevel = 'Edit';                                  
                    locShareList.add(shareRecord );
                }
            }
        }
        if(!locShareList.isEmpty()){
            Database.Insert(locShareList); 
        }
        
    }
}