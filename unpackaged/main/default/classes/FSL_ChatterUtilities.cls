/****
 * *@Name: FSL_ChatterUtilities.cls
 * *@Description: This class contains generic ChatterUtility methods.
 * *@Date: 10/24/2018
 * *@Version: 1.0
 * *@Author: Divyendra Naidu
 * **/

public class FSL_ChatterUtilities {

    /**********
     * @Method Name:postThis
     * @Parameters:(Map<Id, String>)
     * @Description: Method posts chatter to the ids in the keyset of the passed map. The message posted is the message corresponding to the Message id string.
       @Requirement: N/A- Generic utility method
       @Author: Divyendra Naidu
     * **********/
    public static void postThis(Map<Id, String> idMessage) {

        list<FeedItem> postList = new list<FeedItem>();
        List<FSL_User_Message__c> messageList = [Select id, Message_Id__c, Message_Text__c FROM FSL_User_Message__c WHERE Message_Id__c IN :idMessage.values()];
        System.debug('User Message List to post = ' + messageList);

        // Map<Id, String> idMessageText = new Map<Id,String>();

        for(Id i : idMessage.keySet()) {
            for(FSL_User_Message__c um : messageList) {
                if(um.Message_Id__c == idMessage.get(i)) {
                    FeedItem post = new FeedItem(ParentId = i, body = um.Message_Text__c, Visibility = 'AllUsers');
                    postList.add(post);

                }
            }

        }
        if(!postList.isEmpty()) {
                //start Only for debugging
                set<id> IdSet = new set<id>();
                for(Id i : idMessage.keySet()) {
                    IdSet.add(i);
                }
                List<EntitySubscription> SubscriptionsList = new List<EntitySubscription>([SELECT Id, subscriberId, parentId, createddate FROM EntitySubscription WHERE parentId IN : IdSet]);
                system.debug('##### Before SubscriptionsList:'+SubscriptionsList);
                system.debug('#####SubscriptionIDs:'+IdSet);
                //End Only for debugging
            try{
                insert postList;
                //start Only for debugging
                SubscriptionsList = new List<EntitySubscription>([SELECT Id, subscriberId, parentId, createddate FROM EntitySubscription WHERE parentId IN : IdSet]);
                system.debug('##### After SubscriptionsList:'+SubscriptionsList);
                //End Only for debugging
            }
            catch(Exception ex){
                System.debug('An error occurred while posting to chatter :' + ex.getMessage());

            }
        }
    }


    /**********
 * @Method Name:followRecords
 * @Parameters:(Map<Id, Id>)
 * @Description: Accepts a map of parentId and SubscriberId's, iterates through the keyset and creates entity subscription record
   @Requirement: N/A- Generic utility method
   @Author: Divyendra Naidu
 * **********/

    public static void followRecords(Map<Id,Id> esToCreate) {
        List<EntitySubscription> esInsertList = new List<EntitySubscription>();
        Map<Id,Set<Id>> workorderIdSubscriberIdSet = new Map<Id,Set<Id>>();
        FSL_Contractor_Community__c cc = FSL_Contractor_Community__c.getInstance('FSL_Contractor_Community');
        String s = cc.Community_Name__c;
        List<Network> networkList = [SELECT Id, Name FROM Network WHERE Name =: s];

        //Code change for Duplicate Subscription for the same user - 29.10.2018
        List<EntitySubscription> subscriptionList = [select parentId,subscriberId from EntitySubscription where parentId in:esToCreate.keySet() and subscriberId IN :esToCreate.values() LIMIT 1000];
        for(EntitySubscription eSubscription : subscriptionList) {
            if(!workorderIdSubscriberIdSet.containsKey(eSubscription.parentId)) {
                workorderIdSubscriberIdSet.put(eSubscription.parentId,new Set<Id>{eSubscription.subscriberId});
            }else {
                workorderIdSubscriberIdSet.get(eSubscription.parentId).add(eSubscription.subscriberId);
            }
        }
        for(Id i : esToCreate.keyset()) {

            //Code change for Duplicate Subscription for the same user - 29.10.2018
            if(workorderIdSubscriberIdSet.get(i) != null && workorderIdSubscriberIdSet.get(i).contains(esToCreate.get(i))) {
                continue;
            }
            if(!networkList.isEmpty()){
            EntitySubscription es = new EntitySubscription(parentId = i , subscriberId = esToCreate.get(i), NetworkId = networkList.get(0).Id);
                  esInsertList.add(es);
            }
        }


        if(!esInsertList.isEmpty()) {
            insert esInsertList;
        }
    }

    /**********
   * @Method Name:unfollowRecords
   * @Parameters:(Map<Id, Id>)
   * @Description: Accepts a map of parentId and SubscriberId's, finds entity the existing entity subscription records and deletes them
     @Requirement: N/A- Generic utility method
     @Author: Divyendra Naidu
   * **********/
    public static void unfollowRecords(Map<Id,Id> esToDelete) {
        System.debug('Entering unfollowRecords with esToDeleteMap = ' + esToDelete);
        List<EntitySubscription> esDeleteList = new List<EntitySubscription>();
        List<EntitySubscription> esList = [Select Id, parentId, subscriberId FROM EntitySubscription WHERE parentId IN: esToDelete.keySet() AND subscriberId IN:esToDelete.values() LIMIT 1000];
        for(Id i : esToDelete.keySet()) {
            for (EntitySubscription es : esList) {
                if (es.ParentId == i && es.SubscriberId == esToDelete.get(i)) {
                    esDeleteList.add(es);
                }
            }
        }
        if(!esDeleteList.isEmpty()) {
            delete esDeleteList;
        }
    }

    //Combine all commnets from D3 in Work order intake to reduce the number of Feed items.
    public static void postWOComments(Id woId, list<FSL_JSonParserWorkOrder.Comments> comments){

        list<FeedItem> postList = new list<FeedItem>();
        integer count = 1;
        string message = 'Comments from D3: ';
        for(FSL_JSonParserWorkOrder.Comments comment : comments) {
            message = message + count + ') ' ;
            if(comment.contact != null && comment.contact.userid != null)
                message =  message + comment.contact.userid + ': ' ;
            if(String.isNotBlank(comment.text))
                message = message + comment.text + '  ';
            count++;
        }
        FeedItem post = new FeedItem(ParentId = woId, body = message, Visibility = 'AllUsers');
        postList.add(post);
        insert postList;
    }


    /**********
   * @Method Name:createSubscription 
   * @Parameters:(Map<Id, Id>)
   * @Description: Accepts a map of parentId and SubscriberId's and inserts EntitySubscription records with or without Network Id based on whether the user is a community user
   * Also calls the postThis method to create a reassignment post, for auto refresh, and then deletes the entity subscription records.
     @Return: N/A
     @Author: Divyendra Naidu
   * **********/
    public static void createSubscription(Map<Id,Id>saUIdMap) {
        List<EntitySubscription> esToInsert = new List<EntitySubscription>();
        Set<User> userSet = new Set<User>([SELECT Id,isPortalEnabled FROM User WHERE Id IN : saUIdMap.values()]);
        Map<Id, Boolean> isPortalUser = new Map<Id, Boolean>();
        Set<ServiceAppointment> breakdownSASet = new Set<ServiceAppointment>();
        //Get the Network Id in order to enable insert for portal users
        FSL_Contractor_Community__c cc = FSL_Contractor_Community__c.getInstance('FSL_Contractor_Community');
        String s = cc.Community_Name__c;
        List<Network> networkList = [SELECT Id, Name FROM Network WHERE Name =: s];

        for(User u : userSet) {
            if(u.IsPortalEnabled) {
                isPortalUser.put(u.Id, true);
            }
            else {
                isPortalUser.put(u.Id, false);
            }

        }
        System.debug('isPortalUser' + isPortalUser);
        for(Id saId : saUIdMap.keySet()) {
            if(!isPortalUser.get(saUIdMap.get(saId))) {
                //For non portal user, we don't need network id
                EntitySubscription es = new EntitySubscription(ParentId = saId, SubscriberId = saUIdMap.get(saId));
                esToInsert.add(es);
            }
            else {
                //Network id is added for portal users
                if(!networkList.isEmpty()){
                  EntitySubscription es = new EntitySubscription(ParentId = saId, SubscriberId = saUIdMap.get(saId), NetworkId = networkList.get(0).Id);
                  esToInsert.add(es);
                }
                
            }
        }
        if(!esToInsert.isEmpty()) {
            try {
                insert esToInsert; //Create the entity subscription records
            }
            catch(Exception e) {
                System.debug('ES could not be inserted : ' + e.getMessage());
            }
        }

    }






    //Folloiwng code is commented. 
    /*public static void postWOComments(Id woId, list<FSL_JSonParserWorkOrder.Comments> comments){

        list<FeedItem> postList = new list<FeedItem>();
        for(FSL_JSonParserWorkOrder.Comments comment : comments) {
            if(String.isNotBlank(comment.text)) {
                string message = comment.text;
                if(comment.contact != null && comment.contact.userid != null)
                    message = comment.contact.userid + ': ' + message;
                FeedItem post = new FeedItem(ParentId = woId, body = message);
                postList.add(post);
            }
        }
        insert postList;
    }*/


}