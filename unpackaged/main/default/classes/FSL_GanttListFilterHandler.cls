public class FSL_GanttListFilterHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<FSL__Gantt_Filter__c> newList = Trigger.new;
    List<FSL__Gantt_Filter__c> oldList = Trigger.old;
    Map<Id, FSL__Gantt_Filter__c> newMap = (Map<Id, FSL__Gantt_Filter__c>)Trigger.newMap;
    Map<Id, FSL__Gantt_Filter__c> oldMap = (Map<Id, FSL__Gantt_Filter__c>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FSL__Gantt_Filter__c');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        handleGanttFilter(newList);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() { 
        handleGanttFilter(newList);
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    private static void handleGanttFilter(List<FSL__Gantt_Filter__c> ganttFilters) {
        List<String> stNames = New List<String>();
        List<Group> fslGroups = new List<Group>();
        List<FSL__Gantt_Filter__Share> filterShares = New List<FSL__Gantt_Filter__Share>();

        for (ServiceTerritory st : [SELECT Name FROM ServiceTerritory where isActive = true]) {
            stNames.add(st.name);
        }
        fslGroups = [SELECT Id, Name FROM Group WHERE Name in :stNames];
        
        //adding for debugging 
        Map<Id, Group> groupMap = new Map<Id, Group>(fslGroups);
        Map<Id, FSL__Gantt_Filter__c> filterMap = new Map<Id, FSL__Gantt_Filter__c>(ganttFilters);
        for(Group fslGroup : fslGroups){
            system.debug(fslGroup.name);
        }
        //
        
        for (FSL__Gantt_Filter__c gf : ganttFilters) {
            if (gf.FSL__Public__c == true) {
                for (Group fslGroup : fslGroups) {
                    FSL__Gantt_Filter__Share gfs = New FSL__Gantt_Filter__Share();
                    gfs.parentId = gf.id;
                    gfs.accessLevel = 'Read';
                    gfs.UserOrGroupId = fslGroup.id;
                    filterShares.add(gfs);
                }
            }
        }
        
        //adding for debugging
        for(FSL__Gantt_Filter__Share share : filterShares){
            System.debug(filterMap.get(share.parentId).Name + ' : Adding Share for : ' + groupMap.get(share.UserOrGroupId).name);
        }
        //

        insert filterShares;
    }
}