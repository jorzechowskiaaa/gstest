public class FSL_UserTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<User> newList = Trigger.new;
    List<User> oldList = Trigger.old;
    Map<Id, User> newMap = (Map<Id, User>)Trigger.newMap;
    Map<Id, User> oldMap = (Map<Id, User>)Trigger.oldMap;

    Map<Id,Profile> profMap = New Map<Id,Profile>([select id,Name from Profile]);
    List<String> profileIdForFacilityAccSharing = System.Label.FSL_Facility_Account_sharing_Profiles.split(';');
    List<String> profileIdForMemberAccSharing = System.Label.FSL_Member_Account_sharing_Profiles.split(';');


    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('User');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        List<user> lstUserFacilityAccountViewer = new List<User>();
        List<user> lstUserMemberAccountViewer = new List<User>();
        for (user u: newMap.values()){
            if (profileIdForFacilityAccSharing.contains(profMap.get(u.profileId).Name ))
                lstUserFacilityAccountViewer.add(u);
            if (profileIdForMemberAccSharing.contains(profMap.get(u.profileId).Name ))
                lstUserMemberAccountViewer.add(u);
        }
        if (!lstUserFacilityAccountViewer.isEmpty())
            FSL_UserTriggerHandler.insertGroupMemberForFacilityAccountViewer(lstUserFacilityAccountViewer);
        if (!lstUserMemberAccountViewer.isEmpty())
            FSL_UserTriggerHandler.insertGroupMemberForMemberAccountViewer(lstUserMemberAccountViewer);
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterUpdate() {
        FSL_UserTriggerHandler.truckAssignment(oldMap, newMap);

        List<user> lstUserFacilityAccountViewer = new List<User>();
        List<user> lstUserMemberAccountViewer = new List<User>();

        for (User u:newMap.values()){
            if (u.profileId != oldMap.get(u.id).ProfileId)
            {
                if (profileIdForFacilityAccSharing.contains(profMap.get(u.profileId).Name )) {
                    lstUserFacilityAccountViewer.add(u);
                }
                if (profileIdForMemberAccSharing.contains(profMap.get(u.profileId).Name )) {
                    lstUserMemberAccountViewer.add(u);
                }
            }
        }
        if (!lstUserFacilityAccountViewer.isEmpty()) {
            FSL_UserTriggerHandler.insertGroupMemberForFacilityAccountViewer(lstUserFacilityAccountViewer);
        }
        if (!lstUserMemberAccountViewer.isEmpty()) {
            FSL_UserTriggerHandler.insertGroupMemberForMemberAccountViewer(lstUserMemberAccountViewer);
        }
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================

    
    public static void truckAssignment(Map<Id, User> oldUserMap, Map<Id, User> newUserMap) {
        Map<Id,User>relevantRecordMap = new Map<Id, User>();
        Boolean isVehicleNull = false;
        
        //Identify the user records where the truck actually changed
        for(Id iNew : newUserMap.keySet()) {
            for(Id iOld : oldUserMap.keySet()) {
                if(iNew == iOld) {
                    system.debug('Truck Number inew = ' + newUserMap.get(iNew).Truck_Number__c  + ' Truck number iold = ' + oldUserMap.get(iOld).Truck_Number__c);
                    
                    //if((newUserMap.get(iNew).Truck_Number__c).equalsIgnoreCase(oldUserMap.get(iOld).Truck_Number__c))
                    if((newUserMap.get(iNew).Truck_Number__c !=  oldUserMap.get(iOld).Truck_Number__c)) {
                        relevantRecordMap.put(iNew, newUserMap.get(iNew));
                    } 
                    
                }
            }
        }
          system.debug('relevant record  map = ' + relevantRecordMap);
        
        
        //get the map of ServiceResource(of type technician) to User
        Map<ServiceResource, User> relevantSRUMap = getSRUMap(relevantRecordMap);
        
        system.debug('relevant sru map = ' + relevantSRUMap);
        
        //get the map of ServiceResource to ServiceTerritoryId(only primary territories)
        Map<ServiceResource, Id>relevantSRSTIdMap = getSRSTIdMap(relevantSRUMap.keySet());
        
        //get the LocationId(truck) selected by the user
        System.debug('--------relevantSRSTIdMap.values()-------'+relevantSRSTIdMap.values());
        List<Schema.Location> locList = [Select id, Facility__c, Truck_ID__c FROM Location WHERE Facility__c IN:relevantSRSTIdMap.values()];
        
        List<ServiceResource> srToUpdate = new List<ServiceResource>();
        for(ServiceResource sr : relevantSRSTIdMap.keySet()) {
            User u = relevantSRUMap.get(sr);
            for(Schema.Location loc : locList) {
                System.debug('Relevant serviceterritoyId = ' + relevantSRSTIdMap.get(sr) + ' loc.Facility__c =' + loc.Facility__c);
                if(relevantSRSTIdMap.get(sr) == loc.Facility__c){
                    if(u.Truck_Number__c == null) {
                        sr.Vehicle__c = null;
                        srToUpdate.add(sr);
                    } else if(u.Truck_Number__c == loc.Truck_ID__c){
                        sr.Vehicle__c = loc.Id;                
                      srToUpdate.add(sr);
                      
                    }
                } 
            }
            
            
        }
        if(!srToUpdate.isEmpty()) {
            update srToUpdate;            
        }
        

        
        
    
    }
    
    
    
    //Method to get the ServiceResource-User Map
    public static Map<ServiceResource, User> getSRUMap(Map<Id, User> mapList1) {
        
        System.debug('MapList 1 = ' + mapList1);
        Map<ServiceResource, User> srUMap = new Map<ServiceResource, User>();
        List<ServiceResource> srList = new List<ServiceResource>();
        srList = [Select id,ResourceType, RelatedRecordId, Vehicle__c From ServiceResource Where RelatedRecordId IN: mapList1.keySet()];
        for(User u : mapList1.values()) {
        for(ServiceResource sr : srList) {
          if(u.Id == sr.RelatedRecordId) {
            if(sr.ResourceType == 'T') {
              srUMap.put(sr, u);
            }
          }
        }
      }
        system.debug('SRU Map =' + srUMap);
        return srUMap;
    }
    
    
    
    
    //Method to get the ServiceResource-ServiceTerritory Map
    public static  Map<ServiceResource, Id> getSRSTIdMap(Set<ServiceResource> srSet) {
        Map<ServiceResource, Id> srSTId = new Map<ServiceResource, Id>();
        List<Id>srIds =new List<Id>();
        
        
        for(ServiceResource srTemp : srSet) {
            srIds.add(srTemp.Id);
        }
        
        System.debug('Service Resource Ids = ' + srIds);
        
        List<ServiceTerritoryMember> stmList = [Select id, TerritoryType, ServiceResourceId, ServiceTerritoryId From ServiceTerritoryMember Where ServiceResourceId IN: srIds AND TerritoryType = 'P'];
        System.debug('STM List = ' + stmList);
        for(ServiceResource sr : srSet) {
            for(ServiceTerritoryMember stm : stmList) {
                if(sr.Id == stm.ServiceResourceId) {
                    srSTId.put(sr,stm.ServiceTerritoryId);
                }
            }
            
        }
        
        System.debug('srSTIDs = ' + srSTId);
        return srSTId;
    }
    
    
    public static void shareAccountWithUser(List<User>usersToShareWith) {
        List<Account> facilityList = new List<Account>([SELECT Id FROM Account WHERE RecordType.Name = 'Facility']);
        List<AccountShare> shareList = new List<AccountShare>();

        for(Account a : facilityList) {
            for(User u : usersToShareWith){
                AccountShare aShare = new AccountShare(UserOrGroupId = u.Id, AccountId = a.Id, AccountAccessLevel = 'Read');
                shareList.add(aShare);
            }
        }
        try {
            insert shareList;
        }
        catch(exception e) {
            System.debug('Account could not be shared : ' + shareList);
        }
    }
    
    public static void insertGroupMemberForFacilityAccountViewer(List<User> lstUser){
        
        //List<User> lstUser = [Select id, name from User where Profile.Name = 'FSL Club Administrator' ];
        Group gp = [select id from Group where DeveloperName = 'FSL_Facility_Account_viewer_Group'];

        List<GroupMember> lstGroupMember = New List<GroupMember>();

        for (user u:lstUser){

            GroupMember gm = new GroupMember();
            gm.GroupId = gp.id;
            gm.UserOrGroupId = u.id; 
            lstGroupMember.add(gm);
            
        }
        if(!lstGroupMember.isEmpty()) {
            //Database.insert(lstGroupMember);
            insertGMFuture(JSON.serialize(lstGroupMember));
        }
    
    }
    
    public static void insertGroupMemberForMemberAccountViewer(List<User> lstUser){
        
        //List<User> lstUser = [Select id, name from User where Profile.Name = 'FSL Club Administrator' ];
        Group gp = [select id from Group where DeveloperName = 'FSL_Member_Account_viewer_Group'];

        List<GroupMember> lstGroupMember = New List<GroupMember>();

        for (user u:lstUser){

            GroupMember gm = new GroupMember();
            gm.GroupId = gp.id;
            gm.UserOrGroupId = u.id; 
            lstGroupMember.add(gm);
            
        }
        if(!lstGroupMember.isEmpty()) {
            //Database.insert(lstGroupMember);
            insertGMFuture(JSON.serialize(lstGroupMember));
        }
        
    
    }
    
    @future
    public static void insertGMFuture(String groupMemberStr) {
        List<GroupMember> groupMemberList = (List<GroupMember> )JSON.deserialize(groupMemberStr,List<GroupMember>.class);
        insert groupMemberList;
    }
    
    
}


    
    
    

    
    
    
    
    
    
    

    
/*
    public static void truckAssignment(Map<Id, User> oldUserMap, Map<Id, User> newUserMap) {
        Map<Id,User>relevantRecordMap = new Map<Id, User>();
        Map<ServiceResource, Id> srSTIdmap= new Map<ServiceResource, Id> ();
        Map<ServiceResource, User> srUMap = new Map<ServiceResource, User>();
        Map<ServiceResource,ServiceTerritoryMember> srSTMMap = new Map<ServiceResource,ServiceTerritoryMember>();
        for(Id iNew : newUserMap.keySet()) {
            for(Id iOld : oldUserMap.keySet()) {
                if(iNew == iOld) {
                    if((newUserMap.get(iNew).Truck_Number__c !=  oldUserMap.get(iOld).Truck_Number__c)) {
                        relevantRecordMap.put(iNew, newUserMap.get(iNew));
                    }
                }
            }
        }
        srUMap = getSRUMap(newUserMap);
        srSTMMap = getSTMRecords(relevantRecordMap);
        srSTIdMap = getSTRecords(srSTMMap);
        
        
        List<Schema.Location> locList = new List<Schema.Location>();
        locList = [Select id, Facility__c FROM Location];
    }
    
    
    public static Map<ServiceResource,User> getSRUMap(Map<Id,User> idUserMap) {
      Map<ServiceResource, User> srUMap = new Map<ServiceResource, User>();
      List<ServiceResource> srList = [Select id,ResourceType, Vehicle__c From ServiceResource Where RelatedRecordId IN: idUserMap.keySet()];
      for(User u : idUserMap.values()) {
        for(ServiceResource sr : srList) {
          if(u.Id == sr.RelatedRecordId) {
            if(sr.ResourceType == 'Technician') {
              srUMap.put(sr, u);
            }
          }
        }
      }
        return srUMap;
      
      
    }
    
    
    
    
    //Method accepts Map of users id and record and returns a map of ServiceResource and its primary ServiceTerritoryMember
    public static Map<ServiceResource,ServiceTerritoryMember> getSTMRecords(Map<Id, User> idUserMap) {
        
        List<ServiceTerritoryMember> stmList = new List<ServiceTerritoryMember>();
        List<ServiceResource>srList = new List<ServiceResource>();
        List<Id> srIdList = new List<id>();
        Map<ServiceResource,ServiceTerritoryMember> srSTMMap = new Map<ServiceResource,ServiceTerritoryMember>();
        srList = [Select id, ResourceType, Vehicle__c From ServiceResource Where RelatedRecordId IN: idUserMap.keySet()];
        
        for(ServiceResource sr : srList) {
            srIdList.add(sr.Id);
        }
        
        
        stmList = [Select id, TerritoryType, ServiceTerritoryId From ServiceTerritoryMember Where ServiceResourceId IN: srIdList];
        
        for(ServiceResource sr : srList) {
            for(ServiceTerritoryMember stm : stmList) {
                if(sr.id==stm.ServiceResourceId && sr.ResourceType == 'Technician') {
                    if(stm.TerritoryType == 'Primary') {
                        srSTMMap.put(sr,stm);
                    }
                }
            }
        }
        
        return srSTMMap;
    } 
    
    
    
    
    //Method accepts a map of ServiceResurce and its primary ServiceTerritoryMember and returns map of ServiceResource to its Primary STM's serviceterritory Id
    public static Map<ServiceResource, Id> getSTRecords(Map<ServiceResource, ServiceTerritoryMember> srSTMMap) {
      
      Map<ServiceResource, Id> srSTIdMap = new Map<ServiceResource, Id>();
      
      for(ServiceResource sr : srSTMMap.keySet()) {
         
          srSTIdMap.put(sr, srSTMMap.get(sr).ServiceTerritoryId);          
        
        
      }
      
      return srSTIdMap;
    }
    
    
    */