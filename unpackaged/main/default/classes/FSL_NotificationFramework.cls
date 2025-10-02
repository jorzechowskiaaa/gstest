/**
 * Created by divnaidu on 8/20/2019.
 */
/**********
     * @Class Name:        FSL_NotificationFramework
     * @Description:       This class contains the framework for creating/deleting Manual Sharing and Entity Subscriptions based on the gantt actions taken by the user
       @Requirement:
       @Author:            Divyendra Naidu
* **********/

public with sharing class FSL_NotificationFramework {

    //Method accepts resource type as a String and returns whether the Custom Auto Follow logic is on or off for that type of resource-created by Divyendra
    public static Boolean customAutoFollowSwitch(String requestType) {
        FSL_Custom_Notification_Settings__c cs = FSL_Custom_Notification_Settings__c.getOrgDefaults();
        Boolean switchValue = false;
        if(requestType == 'Technician') {
            switchValue = cs.Enable_Tech_Auto_Follow_Logic__c;
        }
        if(requestType == 'Dispatcher') {
            switchValue = cs.Enable_Dispatcher_Auto_Follow_Logic__c;
        }

        if(requestType == 'Unassignment') {
            switchValue = cs.Enable_Unassignment_Notification_Logic__c;
        }

        if(requestType == 'Breakdown Only') {
            switchValue = cs.Status_Post_Breakdown_Only__c;
        }

        if(requestType == 'Address Change') {
            switchValue = cs.Enable_Address_Change_Notification__c;
        }
        return switchValue;
    }


    //Method arEvaluator() accepts the newMap and oldMap of AssignedResource and evaluates the changes in order to prepare the platform event
    public static void arEvaluator(Map<Id, AssignedResource>oldARMap, Map<Id, AssignedResource> newARMap, String operation) {
        List<Mobile_Notification_Event__e> mobileNotificationEventList = new List<Mobile_Notification_Event__e>();
        Set<Id>srIdSetOldNew = new Set<Id>();
        Set<Id>srIdSetOld = new Set<Id>();
        Set<Id>srIdSetNew = new Set<Id>();
        Set<Id>saIdSetOldNew = new Set<Id>();
        Set<Id>saIdSetOld = new Set<Id>();
        Set<Id>saIdSetNew = new Set<Id>();
        Map<Id,Id> srUIdMapOld = new Map<Id,Id>();
        Map<Id,Id> srUIdMapNew = new Map<Id,Id>();
        Map<Id,Id> srSTIdMapOld = new Map<Id,Id>();
        Map<Id,Id> srSTIdMapNew = new Map<Id,Id>();
        Map<Id, ServiceAppointment> oldSAMap = new Map<Id, ServiceAppointment>();
        Map<Id, ServiceAppointment> newSAMap = new Map<Id, ServiceAppointment>();
        Map<Id, AssignedResource> iteratorMap = new Map<Id, AssignedResource>();
        String eventSAId = '';
        String currentStatus = '';
        String previousStatus = '';
        String newSTId = '';
        String oldSTId = '';
        String newUId = '';
        String oldUId = '';
        String recTypeId = '';
        String oldStreet = '';
        String oldCity = '';
        String oldState = '';
        String oldZip = '';
        String newStreet = '';
        String newCity = '';
        String newState = '';
        String newZip = '';
        try{
            iteratorMap = newARMap;
            for(Id arId : iteratorMap.keySet()) {
                if(newARMap != null) {
                    srIdSetOldNew.add(newARMap.get(arId).ServiceResourceId);
                    srIdSetNew.add(newARMap.get(arId).ServiceResourceId);
                    saIdSetOldNew.add(newARMap.get(arId).ServiceAppointmentId);
                    saIdSetNew.add(newARMap.get(arId).ServiceAppointmentId);
                }
                if(oldARMap != null) {
                    srIdSetOldNew.add(oldARMap.get(arId).ServiceResourceId);                
                    srIdSetOld.add(oldARMap.get(arId).ServiceResourceId);
                    saIdSetOldNew.add(oldARMap.get(arId).ServiceAppointmentId);
                    saIdSetOld.add(oldARMap.get(arId).ServiceAppointmentId);
                    
                }
            }

            // query service resource records to map the primary service territory to the update being made
            if(!srIdSetOldNew.isEmpty()){
                list<ServiceResource> allSRs = [SELECT Id, RelatedRecordId,Primary_Service_Territory__c,ResourceType FROM ServiceResource WHERE Id IN : srIdSetOldNew];
            
                if(!allSRs.isEmpty()) {
                    for(ServiceResource sr : allSRs){//[SELECT Id, RelatedRecordId,Primary_Service_Territory__c,ResourceType FROM ServiceResource WHERE Id IN : srIdSetOld]) {
                        if(srIdSetOld.contains(sr.id)){
                            srUIdMapOld.put(sr.Id, sr.RelatedRecordId);
                            srSTIdMapOld.put(sr.Id, sr.Primary_Service_Territory__c);
                        }
                        if(srIdSetNew.contains(sr.id)){
                            srUIdMapNew.put(sr.Id, sr.RelatedRecordId);
                            srSTIdMapNew.put(sr.Id, sr.Primary_Service_Territory__c);
                        }
                    }
                }
            }

            //// query service appointment records to map the record type to the update being made
            if(!saIdSetOldNew.isEmpty()){
                list<ServiceAppointment> allSAs = [SELECT Id, Status, RecordTypeId FROM ServiceAppointment WHERE Id IN : saIdSetOldNew];
                if(allSAs != null) {
                    for(ServiceAppointment sa : allSAs){
                        if(saIdSetOld.contains(sa.id)){
                            oldSAMap.put(sa.id, sa);
                        }
                        if(saIdSetNew.contains(sa.id)){
                            newSAMap.put(sa.id, sa);
                        }
                    }
                }
            }

            for(Id arId : iteratorMap.keySet()) {
                Boolean createEvent = false;
                eventSAId = iteratorMap.get(arId).ServiceAppointmentId;

                if(operation == 'Scheduled') {
                    if(newSAMap != null && newSAMap.get(newARMap.get(arId).ServiceAppointmentId) != null){
                        recTypeId = newSAMap.get(newARMap.get(arId).ServiceAppointmentId).RecordTypeId;                        
                        newSTId = srSTIdMapNew.get(newARMap.get(arId).ServiceResourceId);
                        newUId = srUIdMapNew.get(newARMap.get(arId).ServiceResourceId);
                        createEvent = true;
                    }
                }

                if(createEvent){
                    Mobile_Notification_Event__e evt = prepareEvent(
                        eventSAId,
                        currentStatus,
                        previousStatus,
                        newSTId,
                        oldSTId,
                        newUId,
                        oldUId,
                        recTypeId,
                        oldStreet,
                        oldCity,
                        oldState,
                        oldZip,
                        newStreet,
                        newCity,
                        newState,
                        newZip,
                        operation );

                    mobileNotificationEventList.add(evt);
                }
            }
            System.debug('!@#$%EventList = ' + mobileNotificationEventList);
            if(!mobileNotificationEventList.isEmpty()) {
                insertEvent(mobileNotificationEventList);
            }
        }catch(exception e){
            System.debug('Exception: '+e.getMessage()+' '+e.getStackTraceString());
        }
    }

    //Method saEvaluator() accepts the newMap and oldMap of AssignedResource and evaluates the changes in order to prepare the platform event
    public static void saEvaluator(Map<Id, ServiceAppointment> oldSAMap, Map<Id,ServiceAppointment> newSAMap) {
        // TODO: Only run this code block if there have been relevant updates (Status / Address)
        
        List<Mobile_Notification_Event__e>mobileNotificationEventList = new List<Mobile_Notification_Event__e>();
        String eventSAId = '';
        String currentStatus = '';
        String previousStatus = '';
        String newSTId = '';
        String oldSTId = '';
        String newUId = '';
        String oldUId = '';
        String recTypeId = '';
        String oldStreet = '';
        String oldCity = '';
        String oldState = '';
        String oldZip = '';
        String newStreet = '';
        String newCity = '';
        String newState = '';
        String newZip = '';
        List<AssignedResource>oldARList = new List<AssignedResource>();
        Map<Id,Id>saSRIdMapOldNew = new Map<Id,Id>();
        Map<Id,Id>saSRIdMapOld = new Map<Id,Id>();
        List<AssignedResource>newARList = new List<AssignedResource>();
        Map<Id,Id>saSRIdMapNew = new Map<Id,Id>();
        set<ID> allSAIds = new set<ID>();
        allSAIds.addAll(oldSAMap.keySet());
        allSAIds.addAll(newSAMap.keySet());
        try{
            if(!allSAIds.isEmpty()){

                // iterate over new map to set the comparison values
                for(Id saId : newSAMap.keySet()) {
                    eventSAId = saId;
                    recTypeId = newSAMap.get(saId).RecordTypeId;
                    
                    currentStatus = newSAMap.get(saId).Status;
                    previousStatus = oldSAMap.get(saId).Status;
                    
                    newSTId = newSAMap.get(saId).ServiceTerritoryId;
                    oldSTId = oldSAMap.get(saId).ServiceTerritoryId;

                    newStreet = newSAMap.get(saId).Street;
                    oldStreet = oldSAMap.get(saId).Street;

                    newCity = newSAMap.get(saId).City;
                    oldCity = oldSAMap.get(saId).City;

                    newState = newSAMap.get(saId).State;
                    oldState = oldSAMap.get(saId).State;

                    newZip = newSAMap.get(saId).PostalCode;
                    oldZip = oldSAMap.get(saId).PostalCode;
                    
                    Mobile_Notification_Event__e evt = prepareEvent(
                            eventSAId,
                            currentStatus,
                            previousStatus,
                            newSTId,
                            oldSTId,
                            newUId,
                            oldUId,
                            recTypeId,
                            oldStreet,
                            oldCity,
                            oldState,
                            oldZip,
                            newStreet,
                            newCity,
                            newState,
                            newZip,
                            '');
                    mobileNotificationEventList.add(evt);
                }
                System.debug('!@#$%SA EventList = ' + mobileNotificationEventList);
                if(!mobileNotificationEventList.isEmpty()) {
                    insertEvent(mobileNotificationEventList);
                }
            }
        }catch(exception e){
            System.debug('Exception: '+e.getMessage()+' '+e.getStackTraceString());
        }
    }

    //Method prepareEvent() accepts a set of variables and returns a prepared event
    public static Mobile_Notification_Event__e prepareEvent(
            String eventSAId,
            String currentStatus,
            String previousStatus,
            String newSTId,
            String oldSTId,
            String newUId,
            String oldUId,
            String recTypeId,
            String oldStreet,
            String oldCity,
            String oldState,
            String oldZip,
            String newStreet,
            String newCity,
            String newState,
            String newZip,
            String operation
    ) {
        Id breakdown = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        Id tow = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
        Mobile_Notification_Event__e evt = new Mobile_Notification_Event__e();
        
        // set appointment ID to receive the post
        evt.Service_Appointment_Id__c = eventSAId;
        
        // set service resource values
        evt.Current_SR_User_Id__c = newUId;
        evt.Previous_SR_User_Id__c = oldUId;

        // set breakdown appointment indicator
        evt.Breakdown_Appointment__c = (recTypeId == breakdown);

        // TODO: use the same helper method from the SA Trigger
        evt.Address_Changed__c = (oldStreet != newStreet || oldCity != newCity || oldZip != newZip || oldState != newState) && (oldStreet != '' || newStreet != '');
        //Bastine
        if(evt.Address_Changed__c){
            evt.old_address__c=oldStreet+', '+oldCity+', '+oldZip+', '+oldState;
            evt.new_address__c=newStreet+', '+newCity+', '+newZip+', '+newState;
        }
        //Bastine - End
        // set schedule flags based on operation from ar evaluator
        evt.Rescheduled__c = false;
        evt.Scheduled__c = false;
        evt.Unscheduled__c = false;
        if('Rescheduled'.equals(operation)){
            evt.Rescheduled__c = true;
        }
        else if('Scheduled'.equals(operation)){
            evt.Scheduled__c = true;
        }
        else if('Unscheduled'.equals(operation)){
            evt.Unscheduled__c = true;
        }

        // set service territory parameters
        evt.Current_Service_Territory_Id__c = newSTId;
        evt.Previous_Service_Territory_Id__c = oldSTId;
        evt.Service_Territory_Changed__c = (oldSTId != newSTId);

        // set status update parameters
        evt.Current_Status__c = currentStatus;
        evt.Previous_Status__c = previousStatus;
        evt.Status_Updated__c = (previousStatus != currentStatus);

        return evt;
    }


    //insertEvent() method does the dml for inserting the notification list, triggering the Mobile_Notification_Event__e trigger-created by Divyendra
    public static void insertEvent(List<Mobile_Notification_Event__e> evtList) {
        System.debug('Platform event list for notifications : ' + evtList);
        if(!evtList.isEmpty()) {
            List<Database.SaveResult> resultList = EventBus.publish(evtList);
            for(Database.SaveResult sr : resultList) {
                if(sr.isSuccess()) {
                    System.debug('Successfully published Mobile Notification Event');
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }

    //statusChangePosts() creates posts for various status changes in order to refresh the list view of the mobile user-created by Divyendra
    public static void statusChangePosts(List<Mobile_Notification_Event__e> evtList) {
        List<Mobile_Notification_Event__e>breakDownEventsOnly = new List<Mobile_Notification_Event__e>();
        List<Mobile_Notification_Event__e>iteratorList = new List<Mobile_Notification_Event__e>();
        for(Mobile_Notification_Event__e evt : evtList) {
            if(evt.Breakdown_Appointment__c) {
                breakDownEventsOnly.add(evt);
            }
        }
        if(customAutoFollowSwitch('Breakdown Only')) {
            iteratorList = breakDownEventsOnly;
        }else {
            iteratorList = evtList;
        }

        
        map<string, FSL_User_Message__c> referenceMsgIdMap = new map<string, FSL_User_Message__c>();
        for(FSL_User_Message__c usermessage : [SELECT id, Message_Id__c, Message_Text__c, Reference__c 
                                                 FROM FSL_User_Message__c ])
        {
            if(!string.isEmpty(usermessage.reference__c)){
                referenceMsgIdMap.put(usermessage.reference__c, usermessage);
            }
        }
        Map<Id,String>postThis = new Map<Id,String>();
        for(Mobile_Notification_Event__e evt : iteratorList) {
            if(referenceMsgIdMap.containsKey(evt.Current_Status__c)){                
                postThis.put(evt.Service_Appointment_Id__c, referenceMsgIdMap.get(evt.Current_Status__c).Message_Id__c);
            }                    
        }              
        if(!postThis.isEmpty()) {
            FSL_ChatterUtilities.postThis(postThis);
        }
    }
     
    //addressChangedPost() method posts on the SA for address change based on whether its a breakdown or tow
    public static void addressChangedPost(List<Mobile_Notification_Event__e>evtList) {
        Map<Id,String> postThis = new Map<Id,String>();
        String messageId = '';
        //Bastine
        Map<Id,String> newAddressMapToSAId = new Map<Id,String>();
        Map<Id,String> oldAddressMapToSAId = new Map<Id,String>();
        if(customAutoFollowSwitch('Address Change')) {
            for(Mobile_Notification_Event__e evt : evtList) {
                if(evt.Breakdown_Appointment__c) {
                    messageId = 'SM-017';
                } else {
                    messageId = 'SM-018';
                }
                postThis.put(evt.Service_Appointment_Id__c, messageId);
                //Bastine
                newAddressMapToSAId.put(evt.Service_Appointment_Id__c,evt.new_address__c);
                oldAddressMapToSAId.put(evt.Service_Appointment_Id__c,evt.old_address__c);
            }
            if(!postThis.isEmpty()) {
                //FSL_ChatterUtilities.postThis(postThis);
                postThisAddressChange(postThis,newAddressMapToSAId,oldAddressMapToSAId);
            }

        }
    }
       
    public static void postThisAddressChange(Map<Id, String> idMessage, Map<Id,String> newAddressMap, Map<Id,String> oldAddressMap) {

        list<FeedItem> postList = new list<FeedItem>();
        List<FSL_User_Message__c> messageList = [Select id, Message_Id__c, Message_Text__c FROM FSL_User_Message__c WHERE Message_Id__c IN :idMessage.values()];
        System.debug('User Message List to post = ' + messageList);

        // Map<Id, String> idMessageText = new Map<Id,String>();

        for(Id i : idMessage.keySet()) {
            for(FSL_User_Message__c um : messageList) {
                if(um.Message_Id__c == idMessage.get(i)) {
                    String newAddress=newAddressMap.get(i);
                    String oldAddress=oldAddressMap.get(i);
                    FeedItem post = new FeedItem(ParentId = i, body = um.Message_Text__c+' to '+newAddress+' from '+oldAddress, Visibility = 'AllUsers');
                    postList.add(post);

                }
            }

        }
        if(!postList.isEmpty()) {
            try{
                insert postList;
            }
            catch(Exception ex){
                System.debug('An error occurred while posting to chatter :' + ex.getMessage());
            }
        }
    }


    //     ***   Service Tech Team: Changed methods name    ***

    /**
    * @description 
    * @author Rajesh Kemisetti | 2/27/2020 
    * @param evtList 
    * @return void 
    **/
    // public static void milestoneWarningPost(List<Mobile_Notification_Event__e> evtList) {
    public static void violationsPost(List<Mobile_Notification_Event__e> evtList) {
        Map<Id,String> postThis = new Map<Id,String>();
        for(Mobile_Notification_Event__e evt : evtList) {
            postThis.put(evt.Work_Order_Id__c, evt.Message_Id__c);
        }
        if(!postThis.isEmpty()) {
            FSL_ChatterUtilities.postThis(postThis);
        }        
    }

    public static Boolean shouldNotifySA(ServiceAppointment oldSA, ServiceAppointment newSA){
       FSL_Custom_Notification_Settings__c cs = FSL_Custom_Notification_Settings__c.getOrgDefaults(); 
        Boolean relevantChange = false;
        // TO DO: Ignore when new status = Dispatched / Spotted / En Route / Tow Loaded
        if(oldSA.Status != newSA.Status){
            // and new status is in the list of relevant statuses (from FSL Custom Notification Settings)
            if(!string.isEmpty(cs.Relevant_Statuses__c)){
                List<String> statusList = cs.Relevant_Statuses__c.split(',');
                if(statusList.contains(newSA.Status)){
                    relevantChange = true;
                }
            }           
        }
        else if(oldSA.Street != newSA.Street){
            relevantChange = true;
        }
        else if(oldSA.City != newSA.City){
            relevantChange = true;
        }
        else if(oldSA.State != newSA.State){
            relevantChange = true;
        }
        else if(oldSA.PostalCode != newSA.PostalCode){
            relevantChange = true;
        } 
        return relevantChange;
    }

    //  ***   Service Tech Team: Created a method for posting notifications in Spotted and PTA Violation flows   ***
    
    @InvocableMethod(label='Post Mobile Notifications')
    public static void postMobileNotifications(List<ServiceAppointment> saList) {
        Map<String, FSL_Milestone_Time_Trigger__c> milestoneNamesMap = new Map<String, FSL_Milestone_Time_Trigger__c>();
        for (FSL_Milestone_Time_Trigger__c milestoneConfig : FSL_Milestone_Time_Trigger__c.getall().values()) {
            milestoneNamesMap.put(milestoneConfig.Milestone_Name__c, milestoneConfig);
        }

        List<Mobile_Notification_Event__e> mobileEventList = new List<Mobile_Notification_Event__e>();
        for (ServiceAppointment sa : saList) {
            Mobile_Notification_Event__e mEvent = new Mobile_Notification_Event__e(
                Work_Order_Id__c = sa.Work_Order__c,
                Message_Id__c = milestoneNamesMap.get(sa.Status + ' Warning')?.User_Message_Id__c
            );
            mobileEventList.add(mEvent);
        }
        System.debug(mobileEventList);
        if (!mobileEventList.isEmpty()) {
            EventBus.publish(mobileEventList);
        }
        // FSL_SLA_Violation.createSLAViolHistoryForWarning(saList);        
    }
}