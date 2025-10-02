/****
 * *@Name: FSL_LocationUpdateIntake
 * *@Description: Callout class to update Breakdown/Tow Destination when it called from D3.
 * *@Date: 05-2-2023
 * *@Version: 1.0
 * * 
 * **/
public with sharing class FSL_LocationUpdateIntake {
    public static final String SUCCESS_MESSAGE = 'successfully updated';
    private static String ERROR_MESSAGE = '';
    
    /**********
    *@Method Name:WorkOrderResponse
    *@Parameters: (FSL_JSONParserLocationUpdates jsonParser )
    *@Description: This method parses the json request comming from D3 and updates corresponding SA & WO for Breakdown/Tow updates 
    **************/
    //@HttpPost
    public static FSL_WorkOrderResponse UpsertServiceAppointment() {
        // call handler method to process the SA & WO update, return result element
        DateTime serviceStartTime = System.now();
        Savepoint sp;
        if (!Test.isRunningTest()) {
            sp = Database.setSavepoint();
        }
        WorkOrder workOrderRecord;
        ServiceAppointment breakdownSARecord;
        ServiceAppointment towSARecord;
        String callId;
        String callKey;
        String version;
        String facilityId;
        String SUCCESS_MESSAGE = 'Successfully updated ServiceAppointment';

        FSL_WorkOrderResponse res = new FSL_WorkOrderResponse();
        FSL_WorkOrderResponse.HEADER hed = new FSL_WorkOrderResponse.HEADER();
        RestRequest request = RestContext.request; 
        
        try {
            System.debug('request.requestBody.toString()==>'+request.requestBody.toString());
            FSL_JSONParserLocationUpdates jsonParser = new FSL_JSONParserLocationUpdates();     
            try {
                jsonParser  = (FSL_JSONParserLocationUpdates)Json.deserialize(request.requestBody.toString(),FSL_JSONParserLocationUpdates.class);                
                hed = new FSL_WorkOrderResponse.HEADER(request.headers);
            } 
            catch(Exception ex) {
                System.debug('Error Caught: ' + ex.getStackTraceString() +' At Line:'+ex.getLineNumber());
                Map<String, Object> results =  (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
                List<Object> lstCalls = (List<Object>)results.get('calls');
                Map<String, Object> customerAttributes = (Map<String, Object>)lstCalls[0];
                callId = (String)customerAttributes.get('callId');
                callKey = (String)customerAttributes.get('callKey');
                version = (String)customerAttributes.get('version');

                res.callKey = callKey;
                res.statusCode = '405';
                res.statusDescription = ex.getStackTraceString();
                res.header = hed;
                ERROR_MESSAGE = ex.getMessage()+' At Line:'+ex.getLineNumber();
                
                FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
                FSL_ApplicationLogCreator.serviceEndTime = System.now();
                FSL_ApplicationLogCreator.insertAppLogForUpdate(request, res, ERROR_MESSAGE, 'Inbound Update/Cancel', true, callId, version, null);
                // *** Service Tech Team: it's better to exit the whole method after unsuccesfull deserializing  ***
                return res;
            }
            //updating workorder and related SA records in their respective methods below.
            if (jsonParser.Calls != null && !jsonParser.calls.isEmpty()) {
                callId = jsonParser.calls[0].callId;
                callKey = jsonParser.calls[0].callKey;
                List<WorkOrder> retrieveWO = new List<WorkOrder>();
                List<ServiceAppointment> retrieveSAList = new List<ServiceAppointment>();
                List<ServiceAppointment> updateSAList = new List<ServiceAppointment>();

                retrieveWO = fetchWorkOrdersForExternalIds(callKey);
                System.debug('retrieve size : ' + retrieveWO.size());
                if (!retrieveWO.isEmpty()) {
                    workOrderRecord = retrieveWO[0];
                    retrieveSAList = workOrderRecord.ServiceAppointments;
                    if(retrieveSAList != null && !retrieveSAList.isEmpty()) {
                        for(ServiceAppointment sa : retrieveSAList) {
                            if(sa.isBreakdown__c == true) {
                                breakdownSARecord = sa;
                            }
                            else {
                                TowSARecord = sa;
                            }
                        }
                    }
                }
                
                system.debug('@@@@JSON Parser@@@@@'+jsonParser.calls[0].callId);
                //Apply Logic Here
                if(workOrderRecord != null && breakdownSARecord != null &&
                    jsonParser.calls[0].service != null && jsonParser.calls[0].service.status != null) {
                    facilityId = jsonParser.calls[0].service.facility.Id;
                    Boolean locationChanged = false;
                    FSL_JSONParserLocationUpdates.ServiceLocations_Location breakDownLocation = new FSL_JSONParserLocationUpdates.ServiceLocations_Location();
                    FSL_JSONParserLocationUpdates.ServiceLocations_Location towLocation = new FSL_JSONParserLocationUpdates.ServiceLocations_Location();
                    //having just Breakdown location info in payload
                    if (jsonParser.calls[0].service.serviceLocations != null && !jsonParser.calls[0].service.serviceLocations.isEmpty() ) {
                       //looping through the service locations and performing respective logic
                        for (FSL_JSONParserLocationUpdates.ServiceLocations serviceLoc : jsonParser.calls[0].service.serviceLocations) {
                            WorkOrder tempRecord = workOrderRecord.clone(false, true, false, false);
                            if(serviceLoc.serviceLocationType == 'BREAKDOWN') {
                                if (serviceLoc.foi != null && serviceLoc.foi.Location != null) {
                                   breakDownLocation = serviceLoc.foi.Location;
                                }
                                system.debug('@@@@ Temp Record @@@@'+tempRecord);
                                //Updating Breakdown Address fields on both WO and SA and it does not hurt
                                //to just do a dummy update even if it is not changed in case of Tow Address change request
                                workOrderRecord = breakDownAddressLoader(workOrderRecord, breakDownLocation);
                                workOrderRecord.Driving_Directions__c = jsonParser.calls[0].service.serviceLocations[0].driverDirections;
                                //Check if any of the WO data has been changed by comparing old data with new data
                                if((tempRecord.street != workOrderRecord.street) || (tempRecord.Cross_Street__c != workOrderRecord.Cross_Street__c) || (tempRecord.Cross_Street_2__c != workOrderRecord.Cross_Street_2__c) || 
                                (tempRecord.City != workOrderRecord.City) || (tempRecord.state != workOrderRecord.state) || (tempRecord.postalCode != workOrderRecord.postalCode) ||
                                (tempRecord.Driving_Directions__c != workOrderRecord.Driving_Directions__c) || (tempRecord.Location_Code__c != workOrderRecord.Location_Code__c) || (tempRecord.Mile_Marker__c != workOrderRecord.Mile_Marker__c) || 
                                (tempRecord.Landmark__c != workOrderRecord.Landmark__c) ) {
                                    
                                    breakdownSARecord = breakdownAddressLoader(breakdownSARecord,workOrderRecord);
                                    //06-14-2023 Not Needed as we are not touching anything other than address changes
                                    //Checking to see if the SA status is SP in the payload
                                    /*if(jsonParser.calls[0].service.status.status == 'SP' && facilityId != null) {
                                        list<ServiceTerritory> newFacility = [select id from ServiceTerritory 
                                                                                        where Facility_Number__c =:facilityId];
                                        breakdownSARecord.ServiceTerritoryId = newFacility[0].Id;
                                        breakdownSARecord.Spotted_Timestamp__c = system.now();
                                        breakdownSARecord.Dispatched_Timestamp__c = null;
                                        breakdownSARecord.Scheduled_Timestamp__c = null;
                                        breakdownSARecord.status = 'Spotted';
                                        workOrderRecord.status = 'Spotted';
                                        //workOrderRecord.serviceTerritoryId = newFacility[0].Id;
                                    } */
                                    system.debug('@@@@ ServiceAppointment!!!'+breakdownSARecord);
                                    updateSAList.add(breakdownSARecord);
                                    locationChanged = true;
                                }
                            }

                            if(serviceLoc.serviceLocationType == 'TOW_DESTINATION') {
                                if (serviceLoc.foi != null && serviceLoc.foi.Location != null) {
                                    towLocation = serviceLoc.foi.Location;
                                }
                                workOrderRecord = towAddressLoader(workOrderRecord, towLocation, serviceLoc.foi.name);
                                
                                if((tempRecord.Tow_Destination_Name__c != workOrderRecord.Tow_Destination_Name__c) || (tempRecord.Tow_Cross_Street__c != workOrderRecord.Tow_Cross_Street__c) || (tempRecord.Tow_Cross_Street_2__c != workOrderRecord.Tow_Cross_Street_2__c) || 
                                    (tempRecord.Tow_Street__c != workOrderRecord.Tow_Street__c) || (tempRecord.Tow_City__c != workOrderRecord.Tow_City__c) || (tempRecord.Tow_State__c != workOrderRecord.Tow_State__c)) {
                                        towSARecord = towAddressLoader(towSARecord,workOrderRecord);
                                        updateSAList.add(towSARecord);
                                        locationChanged = true;
                                }
                            }
                        }
                    }
                    system.debug('@@@@@update Appointment@@@@@@'+updateSAList);
                    if(updateSAList != null && !updateSAList.isEmpty()) {
                        update updateSAList;

                        system.debug('@@@@@update workOrderRecord@@@@@@'+workOrderRecord);
                        update workOrderRecord;
                        //Inserting Call Comments to Salesforce
                        map<Id,list<string>> workOrderComments = new map<Id,list<string>>{workOrderRecord.Id => new list<string>{'Location update has been received from D3'}};
                        FSL_CallComments.ICallCommentsService callCommentsService = new FSL_CallComments.Factory().createService();
                        system.debug('@@@@@ Before Call comments @@@@@@'+workOrderRecord);
                        callCommentsService.saveWorkOrderComments(workOrderComments);
                        system.debug('@@@@@ Call comments created @@@@@@'+workOrderRecord);
                        if(workOrderRecord.serviceTerritoryId != null) {
                            string Gname = workOrderRecord.serviceTerritory.Name;
                            //Query the public group associated to Service Territory for Notification
                            list<Group> groupList = [select id,Name from Group where Name =: gName];
                            if(groupList != null && !groupList.isEmpty()) {
                                notifyGroup(workOrderRecord.Id, groupList[0].Id);
                            }
                        }
                    }
                    res.callKey = callKey;
                    res.statusCode = '200';
                    res.statusDescription = SUCCESS_MESSAGE +' '+ 'location details for :' + workOrderRecord.WorkOrderNumber;
                    res.workOrderNumber = workOrderRecord.WorkOrderNumber;            
                    res.header = hed;
                                
                    FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
                    FSL_ApplicationLogCreator.serviceEndTime = System.now();
                    FSL_ApplicationLogCreator.insertAppLogForUpdate(request, res, SUCCESS_MESSAGE, 'Inbound Update/Cancel', false, callId, version, workOrderRecord);        
                    system.debug('@@@@@update insertAplicationLog@@@@@@');
                }
                else {
                    res.callKey = callKey;
                    res.statusCode = '400';
                    res.statusDescription =  'WorkOrder not found for the passed in call key'+callKey;
                    res.workOrderNumber = null;            
                    res.header = hed;
                                
                    FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
                    FSL_ApplicationLogCreator.serviceEndTime = System.now();
                    FSL_ApplicationLogCreator.insertAppLogForUpdate(request, res, 'WorkOrder not found for the passed in call key', 'Inbound Update/Cancel', false, callId, version, workOrderRecord);            
                }
            }
        }
        catch(Exception e) {
            if (!Test.isRunningTest()) {
                Database.rollback(sp);
            }
            System.debug('Error Caught: ' + e.getStackTraceString() +' At Line:'+e.getLineNumber());
            //ERS-220606: Catch the custom Row Lock Error here
            if (e instanceof FSL_CustomExceptions.ExclusiveRowLockException) {
                res.statusCode = '409';                
                RestResponse response = RestContext.response;
                response.statusCode = 409;
                ERROR_MESSAGE = 'Row Lock Error Detected: Status Code = 409\n';                
            }
            else {
                res.statusCode = '400';
            }

            res.callKey = callKey;
            res.statusDescription = e.getTypeName()+' '+e.getmessage();
            res.header = hed;
            ERROR_MESSAGE = ERROR_MESSAGE + e.getStackTraceString() +' At Line:'+ e.getLineNumber();

            //Create Application log here
            FSL_ApplicationLogCreator.serviceStartTime = serviceStartTime;
            FSL_ApplicationLogCreator.serviceEndTime = System.now();
            FSL_ApplicationLogCreator.insertAppLogForUpdate(request, res, ERROR_MESSAGE, 'Inbound Update/Cancel', true, callId, version, null);
        }
        system.debug('@@@@@response returned@@@@@@'+res);
        return res;
    }

    /**********
    *@Method Name:fetchWorkOrdersForExternalIds
    *@Parameters: callKey from JSON payload
    *@Description: Method is to get existing workOrder for passed in callKey
    **************/
    public static List<Schema.WorkOrder> fetchWorkOrdersForExternalIds(string extID) {
        system.debug('@@@callKey@@@'+extID);
        // Modified for ERS-228684 to include children SA information;
        String baseQuery = 'SELECT Id, External_Id__c, Location_Code__c, Mile_Marker__c, Highway__c, Landmark__c, Street, Cross_Street__c,Cross_Street_2__c, City, Status, state, postalCode, WorkOrderNumber, Call_Id__c, Driving_Directions__c, ServiceTerritoryId, ServiceTerritory.Name, ';
        baseQuery += ' Tow_Destination_Name__c,Tow_Cross_Street__c,Tow_Cross_Street_2__c, Tow_Street__c, Tow_City__c,Tow_State__c,Tow_Postal_Code__c, ';
        baseQuery += '(SELECT Id, AccountId, AppointmentNumber, isBreakdown__c, ParentRecordId, recordtypeId, Status, ServiceTerritoryId FROM ServiceAppointments) ';
        baseQuery += 'FROM WorkOrder WHERE External_Id__c = :extID';
        try {
            return Database.Query(String.escapeSingleQuotes(baseQuery));
        }
        catch (Exception QueryException) {
            return new List<Schema.WorkOrder>();
        }            
    } 
    /**********
    *@Method Name:breakDownAddressLoader
    *@Parameters: (WorkOrder, FSL_JSONParserLocationUpdates breakdownlocation )
    *@Description: Method is to set breakdown address on WO comming from D3.
    **************/
    @TestVisible
    private static WorkOrder breakDownAddressLoader(WorkOrder workOrder, FSL_JSONParserLocationUpdates.ServiceLocations_Location breakDownLocation){

        workOrder.Latitude                          = breakDownLocation.Latitude == 0 ? null : breakDownLocation.Latitude;
        workOrder.Longitude                         = breakDownLocation.longitude == 0 ? null : breakDownLocation.longitude;
        System.debug('lat received: ' + breakDownLocation.Latitude);
        System.debug('long received: ' + breakDownLocation.longitude);        
        workOrder.Breakdown_Location__Latitude__s   = breakDownLocation.Latitude == 0 ? null : breakDownLocation.Latitude;
        workOrder.Breakdown_Location__Longitude__s  = breakDownLocation.longitude == 0 ? null : breakDownLocation.longitude;
        
        workOrder.Location_Code__c      = breakDownLocation.locationCode;
        workOrder.Mile_Marker__c        = breakDownLocation.mileMarker;
        workOrder.Highway__c            = breakDownLocation.highway;
        workOrder.Landmark__c           = breakDownLocation.landmark;
        
        if (breakDownLocation.address == null) {
            return workOrder;
        }
        
        workOrder.Cross_Street__c   = breakDownLocation.address.crossStreet;
        workOrder.Cross_Street_2__c = breakDownLocation.address.crossStreet2;

        /*
        A street address is defined as:
        a) If streetNumber is provided, street address = streetNumber + streetDirection + streetName
        b) If streetNumber is not provided, street address = street
        c) If street address is still blank and crossStreet is not, street address = crossStreet + '&' + crossStreet2
         */
        //For case (a)
        if (String.isNotBlank(breakDownLocation.address.streetNumber) || System.Test.isRunningTest()){
            String bdStreetNumber       = (/*String.isBlank(breakDownLocation.address.streetNumber) || */ breakDownLocation.address.streetNumber == 'null') ? '' : breakDownLocation.address.streetNumber + ' ';   //  ***   Service Tech Team: commented out the redundant check  ***
            String bdStreetDirection    = (String.isBlank(breakDownLocation.address.streetDirection) || breakDownLocation.address.streetDirection == 'null') ? '' : breakDownLocation.address.streetDirection + ' ';
            workOrder.street            = bdStreetNumber + bdStreetDirection + breakDownLocation.address.streetName;
        } else {//For case (b)
            workOrder.street            = breakDownLocation.address.street;
        }
        //For case (c)
        if (String.isBlank(workOrder.street) && String.isNotBlank(workOrder.Cross_Street__c)) {
            workOrder.street   = workOrder.Cross_Street__c;
            if (String.isNotBlank(workOrder.Cross_Street_2__c)) {
                workOrder.street += ' & ' + workOrder.Cross_Street_2__c;
            }
            
        }
        workOrder.City                  = breakDownLocation.address.city;
        workOrder.state                 = breakDownLocation.address.state;
        workOrder.postalCode            = breakDownLocation.address.postalCode;
        workOrder.country               = 'United States';
        return workOrder;
    }
    /**********
    *@Method Name:breakDownAddressLoader
    *@Parameters: (ServiceAppointment, WorkOrder)
    *@Description: Method is to set breakdown address on SA comming from D3.
    **************/
    @TestVisible
    private static ServiceAppointment breakdownAddressLoader (ServiceAppointment sa, WorkOrder wo){
        Id breakdownRecordTypeId = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByName().get('Breakdown').getRecordTypeId();
        sa.recordTypeId                              = breakdownRecordTypeId;
        sa.Street                                    = wo.Street;
        sa.City                                      = wo.City;
        sa.State                                     = wo.State;
        sa.PostalCode                                = wo.PostalCode;
        sa.Country                                   = 'United States';
        sa.Latitude                                  = wo.Latitude;
        sa.Longitude                                 = wo.Longitude;
        sa.D3_Address_Geocode__Longitude__s          = wo.Longitude;
        sa.D3_Address_Geocode__Latitude__s           = wo.Latitude;
        sa.Cross_Street__c                           = wo.Cross_Street__c;
        sa.Cross_Street_2__c                         = wo.Cross_Street_2__c;
        sa.Landmark__c                               = wo.Landmark__c;
        sa.Location_Code__c                          = wo.Location_Code__c;
        //sa.Plus_Code__c                            = wo.Location_Plus_Code__c;
        sa.Mile_Marker__c                            = wo.Mile_Marker__c;
        sa.Highway__c                                = wo.Highway__c;
        //sa.D3_ER_Mileage__c                          = wo.D3_ER_Mileage__c;
        sa.Driving_Directions__c                     = wo.Driving_Directions__c;
        sa.Street                                    = wo.Street;
        return sa;
    }

    /**********
    *@Method Name:towAddressLoader
    *@Parameters: (WO, FSL_JSONParserLocationUpdates towLocation )
    *@Description: Method is to set tow address  on WO coming from D3.
    **************/
    @TestVisible
    private static WorkOrder towAddressLoader(WorkOrder workOrder, FSL_JSONParserLocationUpdates.ServiceLocations_Location towLocation, String foiName) {
        // try {
        workOrder.Tow_Destination_Name__c    = foiName;
        workOrder.Tow_Location__Latitude__s  = towLocation.Latitude == 0 ? null : towLocation.Latitude;
        workOrder.Tow_Location__Longitude__s = towLocation.longitude == 0 ? null : towLocation.longitude;
        workOrder.Tow_Latitude__c            = towLocation.Latitude == 0 ? null : towLocation.Latitude;
        workOrder.Tow_Longitude__c           = towLocation.longitude == 0 ? null : towLocation.longitude;

        if (towLocation.address == null) {
            return workOrder;
        }
        
        workOrder.Tow_Cross_Street__c = towLocation.address.crossStreet;
        workOrder.Tow_Cross_Street_2__c = towLocation.address.crossStreet2;
        
        /*
        A street address is defined as:
        a) If streetNumber is provided, street address = streetNumber + streetDirection + streetName
        b) If streetNumber is not provided, street address = street
        c) If street address is still blank and crossStreet is not, street address = crossStreet + '&' + crossStreet2
        */
        //For case (a)
        if (String.isNotBlank(towLocation.address.streetNumber)) {
            String towStreetNumber = (/*String.isBlank(towLocation.address.streetNumber) || */ towLocation.address.streetNumber == 'null') ? '' : towLocation.address.streetNumber + ' ';   //  ***   Service Tech Team: commented out the redundant check  ***
            String towStreetDirection   = (String.isBlank(towLocation.address.streetDirection) || towLocation.address.streetNumber == 'null') ? '' : towLocation.address.streetDirection + ' ';
            workOrder.Tow_Street__c     = towStreetNumber + towStreetDirection + towLocation.address.streetName;
        } else {//For case (b)
            workOrder.Tow_Street__c     = towLocation.address.street;
        }
        //For case (c)
        if (String.isBlank(workOrder.Tow_Street__c) && String.isNotBlank(workOrder.Tow_Cross_Street__c)) {
            workOrder.Tow_Street__c = workOrder.Tow_Cross_Street__c;
            // if(String.isNotBlank(workOrder.Tow_Cross_Street_2__c)){
            //     workOrder.Tow_Street__c += ' & ' + workOrder.Tow_Cross_Street_2__c;
            // }
            
            workOrder.Tow_Street__c += String.isNotBlank(workOrder.Tow_Cross_Street_2__c) ? ' & ' + workOrder.Tow_Cross_Street_2__c : '';
        }

        workOrder.Tow_City__c           = towLocation.address.city;
        workOrder.Tow_State__c          = towLocation.address.state;
        workOrder.Tow_Postal_Code__c    = towLocation.address.postalCode;
        workOrder.Tow_Country__c        = 'United States';
        //   ***   End  ***

        return workOrder;
    }
    /**********
    *@Method Name:towAddressLoader
    *@Parameters: (SA, WO)
    *@Description: Method is to set tow address  on SA coming from D3.
    **************/
    @TestVisible
    private static ServiceAppointment towAddressLoader(ServiceAppointment sa, WorkOrder wo) {
        sa.Latitude                                  = wo.Tow_Location__Latitude__s;
        sa.Longitude                                 = wo.Tow_Location__Longitude__s;
        sa.Street                                    = wo.Tow_Street__c;
        sa.City                                      = wo.Tow_City__c;
        sa.State                                     = wo.Tow_State__c;
        sa.PostalCode                                = wo.Tow_Postal_Code__c;
        sa.Country                                   = wo.Tow_Country__c;
        sa.D3_Address_Geocode__Longitude__s          = wo.Tow_Location__Longitude__s;
        sa.D3_Address_Geocode__Latitude__s           = wo.Tow_Location__Latitude__s;
        sa.Cross_Street__c                           = wo.Tow_Cross_Street__c;
        sa.Cross_Street_2__c                         = wo.Tow_Cross_Street_2__c;
        //sa.Landmark__c                               = wo.Tow_Landmark__c;
        //sa.Plus_Code__c                            = wo.Tow_Location_Plus_Code__c;
        sa.Tow_Destination_Name__c                   = wo.Tow_Destination_Name__c;
        //sa.Drop_Box_Info__c                          = wo.Drop_Box_Info__c;
        sa.Street                                    = wo.Tow_Street__c;
        return sa;
    }    

    public static void notifyGroup(Id workOrderId, Id groupId) {
        // Get the Id for our custom notification type to notify the group
        CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                            FROM CustomNotificationType 
                                                            WHERE DeveloperName = 'Notify_Location_Change'];
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle('Location update Received');
        notification.setBody('Location update Received from D3');
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(workOrderId);
        notification.send(new Set<String> {groupId});
    }
}