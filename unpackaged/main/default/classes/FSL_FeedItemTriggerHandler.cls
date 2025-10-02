/**
 * @File Name          : FSL_FeedItemTriggerHandler.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 6/8/2020, 1:12:48 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    5/29/2020   Rajesh Kemisetti     Initial Version
**/

public class FSL_FeedItemTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {

    List<FeedItem> newList = Trigger.new;
    List<FeedItem> oldList = Trigger.old;
    Map<Id, FeedItem> newMap = (Map<Id, FeedItem>)Trigger.newMap;
    Map<Id, FeedItem> oldMap = (Map<Id, FeedItem>)Trigger.oldMap;

    //========================================================================================================================
    //========================================================================================================================
    public override Boolean isDisabled() {
        return FSL_TriggerUtility.isDisabled('FeedItem');
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void afterInsert() {
        List<FeedItem> appointmentFeed = new List<FeedItem>();
        List<FeedItem> workOrderFeed = new List<FeedItem>(); 
        for(FeedItem item : newList){
            system.debug('new item: ' + item);
            if(Schema.ServiceAppointment.SObjectType == item.parentId.getSobjectType()){
                appointmentFeed.add(item);
            }
        }
        //Commenting out as it is not required for sending it to techs
        /*if(!appointmentFeed.isEmpty()){
            FSL_FeedItemTriggerHandler.postAppointmentMessageToParent(appointmentFeed);
        }*/
    }

    //========================================================================================================================
    //========================================================================================================================
    public override void beforeDelete() {
        if (!FSL_DisableChatterDeleteDelegate.allowDelete()) {
            for(FeedItem f : oldList){
                /*if (((String)f.parentId).startsWith('00Q') && f.type == 'TrackedChange') {
                    // ok to ignore
                }*/
    
                f.addError('Your administrator has disabled feed post and comment deletions.');
    
            }
        }            
    }


    //========================================================================================================================
    //========================================================================================================================
    //========================================================================================================================


    public static List<FeedItem> postAppointmentMessageToParent(List<FeedItem> items){
        List<FeedItem> newItems = new List<FeedItem>();
        
        // get the Service Appointments ids from feed list 
        Set<ID> saIDSet = new Set<ID>();
        for(FeedItem item : items){
            saIDSet.add(item.parentId);
        }
        
        // query to get the service appointments parent record
        List<ServiceAppointment> saList = [SELECT id, parentRecordId FROM ServiceAppointment WHERE id IN :saIDSet];
        
        
        // create map of feed --> service appointment
        Map<FeedItem, ServiceAppointment> feedMap = new Map<FeedItem, ServiceAppointment>(); 
        for(FeedItem item : items){
            for(ServiceAppointment sa : saList){
                if(item.parentId == sa.id){
                    feedMap.put(item, sa);
                }
            }
        }
        
        // create new feed item with a related record that matches the SA's parent
        for(FeedItem item : items){
            FeedItem newItem = new FeedItem();
            newItem.body = item.Body.stripHtmlTags();
            newItem.parentId = feedMap.get(item).parentRecordId;
            newItem.Visibility = item.Visibility;
            newItems.add(newItem);
        }
        
        system.debug('new parent items: ' + newItems);
        insert newItems;
        return newItems;
        
    }
    
}