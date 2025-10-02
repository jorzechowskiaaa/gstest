public with sharing class FSL_WorkOrder {


    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IWorkOrderService createService();
        List<FSL_WorkOrder.WorkOrder> createWorkOrders( List<Schema.WorkOrder> workOrders, Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap );
    }

    public static final String TOW_INVOLVING_RESOLUTION_CODES_PREFIX = 'N';
    public class Factory implements IFactory {
        public IWorkOrderService createService() {
            IWorkOrderDAO dao = createDAO();
            FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();

            return new WorkOrderService( dao, appLogService);
        }

        private IWorkOrderDAO createDAO() {
            return new WorkOrderDAO();
        }

        public List<FSL_WorkOrder.WorkOrder> createWorkOrders( List<Schema.WorkOrder> workOrders, Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap ) {
            List<WorkOrder> domainWorkOrders = new List<WorkOrder>();
                FSL_ServiceAppointment.IFactory serviceAppointmentFactory = new FSL_ServiceAppointment.Factory();
            for( Schema.WorkOrder workOrder : workOrders ) {
                List<FeedItem> feedItems = workOrderIdToFeedItemsMap.containsKey( workOrder.Id ) ? workOrderIdToFeedItemsMap.get( workOrder.Id ) : new List<FeedItem>();
                List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments = serviceAppointmentFactory.createServiceAppointments( workOrder.ServiceAppointments, serviceAppointmentIdToAssignedResourceMap );
                            system.debug('serviceAppointments:::::::::::'+serviceAppointments);

                domainWorkOrders.add(new FSL_WorkOrder.WorkOrder( workOrder, feedItems, serviceAppointments ));
            }
            system.debug('domainWorkOrders:::::::::::'+domainWorkOrders);
            return domainWorkOrders;
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IWorkOrderDAO extends FSL_DAO.DmlInterface {
        List<Schema.WorkOrder> fetchWorkOrdersForClearing( Set<Id> workOrderIds );
        List<Schema.WorkOrder> fetchDetailedWorkOrdersByCallIdAndDate( Set<String> callIds, Set<String> callDates );
        List<Schema.WorkOrder> fetchDetailedActiveWorkOrdersByContactId( Set<Id> contactIds );
        List<Schema.WorkOrder> fetchWorkOrdersForExternalIds ( Set<String> extIDs, Boolean lockForUpdate);
        List<Schema.WorkOrder> fetchWorkOrdersByIds(Set<Id> workOrderIds);
        List<Schema.WorkOrder> fetchAllReadOnlyWorkOrdersNotYetCleared(DateTime clearedTimestampCutoff, Integer lmt);

        FSL_WorkOrder.EODBean fetchAllWorkOrdersNotYetSentToBackOfficeEOD(DateTime clearedTimestampCutoff);

        List <FSL_WorkOrder_Configuration__mdt>  fetchWorkOrderConfiguration();

    }

    public class WorkOrderDAO extends FSL_DAO.DmlBase implements IWorkOrderDAO {
        public List<Schema.WorkOrder> fetchWorkOrdersForClearing( Set<Id> workOrderIds ) {
            return [SELECT Id,Resolution_Code__c,Clearing_Code__c,Call_Source__c, Drop_Box_Info__c,Tow_Destination_Name__c,Tow_Contact_Phone_Number__c,Tow_Contact_First_Name__c,Tow_Contact_Last_Name__c,State,City,
                        postalcode,country,Street,CreatedDate,WorkOrderNumber,Status, External_Id__c, Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c, WO_Member_Phone_Number__c,          
                        LastModifiedBy.Name,LastModifiedDate,Tow_Location__Latitude__s,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s, Call_Id__c,RAP_Case_Number__c,
                        Dispatched_Timestamp__c,Cleared_Timestamp__c,Call_Type__c,Timezone_Id__c,Timezone_Offset__c,Non_Emergency_Appointment_Time__c,Collision__c,Red_Flag__c,Number_Of_Passengers__c,
                        Is_Tow_WorkType__c,In_Tow_Timestamp__c,Service_Order_Number__c,Needs_Flatbed__c,Scheduled_Timestamp__c ,Legacy_Priority_Code__c, Priority_Code__c,Flatbed_Requested__c,Call_Date__c,Latitude,longitude,
                        Landmark__c,Highway__c,Mile_Marker__c,Original_Member_Id__c, Membership_Benefit_Level__c,Cross_Street__c,Cross_Street_2__c,Location_Code__c,Tow_Latitude__c,Tow_Longitude__c,Tow_Landmark__c,Tow_Street__c,
                        Tow_City__c,Tow_State__c,Spotted_Timestamp__c,Wait_Time__c,Tow_Postal_Code__c,Enroute_Timestamp__c,Tow_Country__c,Account.Name,Account.Facility_ID__c,InitialETA_Legacy__c,
                        Pta__c,Payment_Codes__c,On_Location_Timestamp__c,Account.Facility_Type__c,Contact.Original_Member_Id__c,Contact.Membership_Type__c, ServiceTerritoryId, 
                        Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,Contact.Membership_Islocalclub__c,
                        Contact.Member_Card_Num__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Level__c,Contact.Membership_Birthday__c,Contact.Membership_Since__c,
                        Contact.Membership_Status__c,Contact.Membership_Org__c,Contact.Membership_OrgCode__c,Contact.External_ID__c,Contact.Type__c,Contact.Title,Contact.FirstName,
                        Contact.LastName,Contact.Phone_Type__c,Contact.Phone,Contact.Phone_Extension__c,Contact.Sms_Optin__c,Contact.Email_Type__c,Contact.Email,Contact.Language_Preference__c,
                        (SELECT Id,address,Drop_Box_Info__c,SLR_En_Route_Miles__c,SLR_Tow_Miles__c,Landmark__c,Highway__c,Mile_Marker__c,Location_Code__c,Street,State,City,Country,
                            postalcode,Cross_Street__c,Cross_Street_2__c,Tow_Destination_Name__c,Subject,ParentRecordId,SchedStartTime, ServiceTerritory.Facility_Number__c,ServiceTerritory.Name,
                            Latitude,Longitude,Service_Resource__c, Address_Change_Counter__c, FSL_Actual_Miles_Driven__c,ETA__c, Payment_Type__c, Payment_Required__c, isBreakdown__c
                            ,D3_AAR_Id__c
                        FROM ServiceAppointments),
                        (SELECT Id,Name,Code__c,Description__c,Type__c 
                        FROM TroubleCodes__r), 
                        (SELECT Id,Name,RV_Class__c,RV_Length__c,Trailer_Hitchtype__c,Trailer_Length__c,Vehicle_Color__c,Vehicle_Drive_Type__c,Vehicle_Fuel_Type__c,Vehicle_Make__c,Vehicle_Model__c,
                            Vehicle_Odometer__c,Vehicle_Special_Equipment_Needs__c,Vehicle_State__c,Vehicle_Tag__c,Vehicle_Trim__c,Vehicle_Type__c,Vehicle_VIN__c,Vehicle_Year__c,Work_Order__c 
                        FROM Member_Vehicles__r),
                        (SELECT Id,Name,Policy_Code__c,Policy_Description__c 
                        FROM Policies__r),
                        (SELECT Id,Name,CreatedBy.EmployeeNumber,FSL_Comment__c,FSL_Work_Order__c,createdDate 
                        FROM Call_Comments__r),
                        (SELECT Id,Cost__c,Unit__c, Product__c, Product__r.ProductCode 
                        FROM Service_Line_Items__r)
                    FROM WorkOrder 
                    WHERE Id IN :workOrderIds];
        }

        public List<Schema.WorkOrder> fetchDetailedWorkOrdersByCallIdAndDate( Set<String> callIds, Set<String> callDates ) {
            return [SELECT Id,Resolution_Code__c,Clearing_Code__c,Call_Source__c,Drop_Box_Info__c,Tow_Destination_Name__c,Tow_Contact_Phone_Number__c,Tow_Contact_First_Name__c,Tow_Contact_Last_Name__c,State,City,
                        postalcode,country,Street,CreatedDate,WorkOrderNumber,Status, External_Id__c, Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,            
                        LastModifiedBy.Name,LastModifiedDate,Tow_Location__Latitude__s,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s, Call_Id__c,RAP_Case_Number__c,
                        Dispatched_Timestamp__c,Cleared_Timestamp__c,Call_Type__c,Timezone_Id__c,Timezone_Offset__c,Non_Emergency_Appointment_Time__c,Collision__c,Red_Flag__c,Number_Of_Passengers__c,
                        Is_Tow_WorkType__c,In_Tow_Timestamp__c,Needs_Flatbed__c,Scheduled_Timestamp__c ,Legacy_Priority_Code__c, Priority_Code__c,Flatbed_Requested__c,Call_Date__c,Latitude,longitude,
                        Landmark__c,Highway__c,Mile_Marker__c,Original_Member_Id__c, Membership_Benefit_Level__c, Cross_Street__c,Cross_Street_2__c,Location_Code__c,Tow_Latitude__c,Tow_Longitude__c,Tow_Landmark__c,Tow_Street__c,
                        Tow_City__c,Tow_State__c,Spotted_Timestamp__c,Wait_Time__c,Tow_Postal_Code__c,Enroute_Timestamp__c,Tow_Country__c,Account.Name,Account.Facility_ID__c,InitialETA_Legacy__c,
                        Pta__c,Payment_Codes__c,On_Location_Timestamp__c,Account.Facility_Type__c,Contact.Original_Member_Id__c,Contact.Membership_Type__c, ServiceTerritoryId, 
                        Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,Contact.Membership_Islocalclub__c,
                        Contact.Member_Card_Num__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Level__c,Contact.Membership_Birthday__c,Contact.Membership_Since__c,
                        Contact.Membership_Status__c,Contact.Membership_Org__c,Contact.Membership_OrgCode__c,Contact.External_ID__c,Contact.Type__c,Contact.Title,Contact.FirstName,
                        Contact.LastName,Contact.Phone_Type__c,Contact.Phone,Contact.MobilePhone,Contact.Phone_Extension__c,Contact.Sms_Optin__c,Contact.Email_Type__c,Contact.Email,Contact.Language_Preference__c,
                        (SELECT Id, AppointmentNumber, address,Drop_Box_Info__c,SLR_En_Route_Miles__c,SLR_Tow_Miles__c,Landmark__c,Highway__c,Mile_Marker__c,Location_Code__c,Street,State,City,Country,
                            postalcode,Cross_Street__c,Cross_Street_2__c, Driving_Directions__c, Tow_Destination_Name__c,Subject,ParentRecordId,SchedStartTime, ServiceTerritory.Facility_Number__c,ServiceTerritory.Name,
                            Latitude,Longitude,Service_Resource__c, Address_Change_Counter__c, FSL_Actual_Miles_Driven__c,ETA__c, Payment_Type__c, Payment_Required__c, isBreakdown__c,
                            Status, Canceled_Timestamp__c, Cleared_Timestamp__c, Dispatched_Timestamp__c, En_Route_Timestamp__c, In_Tow_Timestamp__c, Tow_Complete_Timestamp__C, On_Location_Timestamp__c, Scheduled_timestamp__c, Spotted_Timestamp__c
                        FROM ServiceAppointments),
                        (SELECT Id,Name,Code__c,Description__c,Type__c 
                        FROM TroubleCodes__r), 
                        (SELECT Id,Name,RV_Class__c,RV_Length__c,Trailer_Hitchtype__c,Trailer_Length__c,Vehicle_Color__c,Vehicle_Drive_Type__c,Vehicle_Fuel_Type__c,Vehicle_Make__c,Vehicle_Model__c,
                            Vehicle_Odometer__c,Vehicle_Special_Equipment_Needs__c,Vehicle_State__c,Vehicle_Tag__c,Vehicle_Trim__c,Vehicle_Type__c,Vehicle_VIN__c,Vehicle_Year__c,Work_Order__c 
                        FROM Member_Vehicles__r),
                        (SELECT Id,Name,Policy_Code__c,Policy_Description__c 
                        FROM Policies__r),
                        (SELECT Id,Name,CreatedBy.EmployeeNumber,FSL_Comment__c,FSL_Work_Order__c,createdDate 
                        FROM Call_Comments__r),
                        (SELECT Id,Cost__c,Unit__c, Product__c, Product__r.ProductCode 
                        FROM Service_Line_Items__r)
                    FROM WorkOrder 
                    WHERE Call_Id__c IN :callIds
                    AND Call_Date__c IN :callDates];
        }

        public List<Schema.WorkOrder> fetchDetailedActiveWorkOrdersByContactId( Set<Id> contactIds ) {
            return [SELECT Id,Resolution_Code__c,Clearing_Code__c,Call_Source__c,Drop_Box_Info__c,Tow_Destination_Name__c,Tow_Contact_Phone_Number__c,Tow_Contact_First_Name__c,Tow_Contact_Last_Name__c,State,City,
                        postalcode,country,Street,CreatedDate,WorkOrderNumber,Status, External_Id__c, Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,            
                        LastModifiedBy.Name,LastModifiedDate,Tow_Location__Latitude__s,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s, Call_Id__c,RAP_Case_Number__c,
                        Dispatched_Timestamp__c,Cleared_Timestamp__c,Call_Type__c,Timezone_Id__c,Timezone_Offset__c,Non_Emergency_Appointment_Time__c,Collision__c,Red_Flag__c,Number_Of_Passengers__c,
                        Is_Tow_WorkType__c,In_Tow_Timestamp__c,Needs_Flatbed__c,Scheduled_Timestamp__c ,Legacy_Priority_Code__c, Priority_Code__c,Flatbed_Requested__c,Call_Date__c,Latitude,longitude,
                        Landmark__c,Highway__c,Mile_Marker__c,Original_Member_Id__c, Membership_Benefit_Level__c, Cross_Street__c,Cross_Street_2__c,Location_Code__c,Tow_Latitude__c,Tow_Longitude__c,Tow_Landmark__c,Tow_Street__c,
                        Tow_City__c,Tow_State__c,Spotted_Timestamp__c,Wait_Time__c,Tow_Postal_Code__c,Enroute_Timestamp__c,Tow_Country__c,Account.Name,Account.Facility_ID__c,InitialETA_Legacy__c,
                        Pta__c,Payment_Codes__c,On_Location_Timestamp__c,Account.Facility_Type__c,Contact.Original_Member_Id__c,Contact.Membership_Type__c, ServiceTerritoryId, 
                        Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,Contact.Membership_Islocalclub__c,
                        Contact.Member_Card_Num__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Level__c,Contact.Membership_Birthday__c,Contact.Membership_Since__c,
                        Contact.Membership_Status__c,Contact.Membership_Org__c,Contact.Membership_OrgCode__c,Contact.External_ID__c,Contact.Type__c,Contact.Title,Contact.FirstName,
                        Contact.LastName,Contact.Phone_Type__c,Contact.Phone,Contact.Phone_Extension__c,Contact.Sms_Optin__c,Contact.Email_Type__c,Contact.Email,Contact.Language_Preference__c,
                        (SELECT Id,address,Drop_Box_Info__c,SLR_En_Route_Miles__c,SLR_Tow_Miles__c,Landmark__c,Highway__c,Mile_Marker__c,Location_Code__c,Street,State,City,Country,
                            postalcode,Cross_Street__c,Cross_Street_2__c,Driving_Directions__c,Tow_Destination_Name__c,Subject,ParentRecordId,SchedStartTime, ServiceTerritory.Facility_Number__c,ServiceTerritory.Name,
                            Latitude,Longitude,Service_Resource__c, Address_Change_Counter__c, FSL_Actual_Miles_Driven__c,ETA__c, Payment_Type__c, Payment_Required__c, isBreakdown__c,
                            Status, Canceled_Timestamp__c, Cleared_Timestamp__c, Dispatched_Timestamp__c, En_Route_Timestamp__c, In_Tow_Timestamp__c, Tow_Complete_Timestamp__C, On_Location_Timestamp__c, Scheduled_timestamp__c, Spotted_Timestamp__c
                        FROM ServiceAppointments),
                        (SELECT Id,Name,Code__c,Description__c,Type__c 
                        FROM TroubleCodes__r), 
                        (SELECT Id,Name,RV_Class__c,RV_Length__c,Trailer_Hitchtype__c,Trailer_Length__c,Vehicle_Color__c,Vehicle_Drive_Type__c,Vehicle_Fuel_Type__c,Vehicle_Make__c,Vehicle_Model__c,
                            Vehicle_Odometer__c,Vehicle_Special_Equipment_Needs__c,Vehicle_State__c,Vehicle_Tag__c,Vehicle_Trim__c,Vehicle_Type__c,Vehicle_VIN__c,Vehicle_Year__c,Work_Order__c 
                        FROM Member_Vehicles__r),
                        (SELECT Id,Name,Policy_Code__c,Policy_Description__c 
                        FROM Policies__r),
                        (SELECT Id,Name,CreatedBy.EmployeeNumber,FSL_Comment__c,FSL_Work_Order__c,createdDate 
                        FROM Call_Comments__r),
                        (SELECT Id,Cost__c,Unit__c, Product__c, Product__r.ProductCode 
                        FROM Service_Line_Items__r)
                    FROM WorkOrder 
                    WHERE ContactId IN :contactIds
                    AND Status NOT IN ('Cleared', 'Canceled')];
        }

        public List<Schema.WorkOrder> fetchWorkOrdersForExternalIds( Set<String> extIDs, Boolean lockForUpdate ) {

            // Modified for ERS-228684 to include children SA information;
            String baseQuery = 'SELECT Id, External_Id__c, Call_Source__c, Status, WorkOrderNumber, ContactId, Call_Id__c, D3_Sync_Issue__c, Number_Of_Passengers__c, Servicing_Technology_Type__c, ServiceTerritoryId, Vehicle_Profile__c, ';
            baseQuery += '(SELECT Id, AccountId, AppointmentNumber, isBreakdown__c, ParentRecordId, Status, Resolution_Code__c, SchedStartTime, SchedEndTime, ServiceTerritoryId, WorktypeId FROM ServiceAppointments) ';
            baseQuery += 'FROM WorkOrder WHERE External_Id__c IN :extIDs';

            if ( lockForUpdate ) {
                baseQuery += ' FOR UPDATE';
            }
            try {
                return Database.Query(String.escapeSingleQuotes(baseQuery));
            }
            catch (Exception QueryException) {
                return new List<Schema.WorkOrder>();
            }            
        }

        public List<Schema.WorkOrder> fetchWorkOrdersByIds( Set<Id> workOrderIds ) {
            return [SELECT Id,Resolution_Code__c,Clearing_Code__c,Call_Source__c,Drop_Box_Info__c,Tow_Destination_Name__c,Tow_Contact_Phone_Number__c,Tow_Contact_First_Name__c,Tow_Contact_Last_Name__c,State,City,
                            postalcode,country,Street,CreatedDate,WorkOrderNumber,Status, External_Id__c, Call_Origin__c,Call_Origin_OrgCode__c,Call_Origin_OrgName__c,Responder_ID__c,            
                            LastModifiedBy.Name,LastModifiedDate,Tow_Location__Latitude__s,Breakdown_Location__Latitude__s,Breakdown_Location__Longitude__s,Tow_Location__Longitude__s, Call_Id__c,RAP_Case_Number__c,
                            Dispatched_Timestamp__c,Cleared_Timestamp__c,Call_Type__c,Timezone_Id__c,Timezone_Offset__c,Non_Emergency_Appointment_Time__c,Collision__c,Red_Flag__c,Number_Of_Passengers__c,
                            Is_Tow_WorkType__c,In_Tow_Timestamp__c,Needs_Flatbed__c,Scheduled_Timestamp__c ,Legacy_Priority_Code__c, Priority_Code__c,Flatbed_Requested__c,Call_Date__c,Latitude,longitude,
                            Landmark__c,Highway__c,Mile_Marker__c,Original_Member_Id__c, Membership_Benefit_Level__c, Cross_Street__c,Cross_Street_2__c,Location_Code__c,Tow_Latitude__c,Tow_Longitude__c,Tow_Landmark__c,Tow_Street__c,
                            Tow_City__c,Tow_State__c,Spotted_Timestamp__c,Wait_Time__c,Tow_Postal_Code__c,Enroute_Timestamp__c,Tow_Country__c,Account.Name,Account.Facility_ID__c,InitialETA_Legacy__c,
                            Pta__c,Payment_Codes__c,On_Location_Timestamp__c,Account.Facility_Type__c,Contact.Original_Member_Id__c,Contact.Membership_Type__c, ServiceTerritoryId, 
                            Contact.Membership_Sponsor__c,Contact.Membership_Program__c,Contact.Membership_Code__c,Contact.Membership_Authorization__c,Contact.Membership_Islocalclub__c,
                            Contact.Member_Card_Num__c,Contact.Membership_Expiration_Date__c,Contact.Membership_Level__c,Contact.Membership_Birthday__c,Contact.Membership_Since__c,
                            Contact.Membership_Status__c,Contact.Membership_Org__c,Contact.Membership_OrgCode__c,Contact.External_ID__c,Contact.Type__c,Contact.Title,Contact.FirstName,
                            Contact.LastName,Contact.Phone_Type__c,Contact.Phone,Contact.Phone_Extension__c,Contact.Sms_Optin__c,Contact.Email_Type__c,Contact.Email,Contact.Language_Preference__c
                    FROM WorkOrder 
                    WHERE Id IN :workOrderIds];
        }

        public FSL_WorkOrder.EODBean fetchAllWorkOrdersNotYetSentToBackOfficeEOD(DateTime clearedTimestampCutoff) {
            List<Schema.WorkOrder> workOrderList =
                [SELECT Id, Breakdown_Address__c, Call_Source__c, Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,
                    Call_Date__c, Call_Id__c, Call_Type__c, Timezone_Id__c, Timezone_Offset__c,
                    City, Cross_Street__c, Cross_Street_2__c, Driving_Directions__c, Landmark__c, Legacy_Priority_Code__c,
                    Membership_Benefit_Level__c, Non_Emergency_Appointment_Time__c, Payment_Codes__c, Payment_Required__c, 
                    Program_Name__c, Program_Description__c, RAP_Case_Number__c, Resolution_Code__c, Responder_ID__c, State, Tow_Address__c, 
                    Tow_Location__Latitude__s, Tow_Location__Longitude__s, Tow_State__c, Tow_City__c, Wait_Time__c, Work_Type_Name__c,
                    CDX_Authorization_Code__c, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Member_Card_Num__c, 
                    Contact.Membership_Authorization__c, Contact.Membership_Expiration_Date__c, 
                    Contact.Membership_OrgCode__c, Contact.Membership_Program__c, Contact.Membership_Sponsor__c,
                    Contact.Membership_Type__c, Contact.Phone, Contact.Phone_Type__c, Contact.Sms_Optin__c,
                (SELECT Id, Vehicle_Color__c, Vehicle_Make__c, Vehicle_Model__c,  
                        Vehicle_Year__c, Vehicle_Vin__C, Vehicle_Odometer__c, Vehicle_Type__c
                        FROM Member_Vehicles__r),
                (SELECT Id, Code__c, Type__c 
                        FROM TroubleCodes__r),
                (SELECT Id, Product__r.ProductCode, Unit__c, Cost__c 
                        FROM Service_Line_Items__r),
                (SELECT ServiceTerritory.Facility_Number__c, ServiceTerritory.Statecode
                        FROM Service_Appointments__r)
                FROM WorkOrder 
                WHERE Sent_to_BackOffice__c = FALSE AND 
                    Status = 'Cleared' AND 
                    Cleared_Timestamp__c < :clearedTimestampCutoff AND
                    Cleared_Timestamp__c = LAST_N_DAYS:5
                LIMIT 2000];

            List<Id> idList = new List<Id>();
            for(Schema.WorkOrder w : workOrderList) {
                idList.add(w.Id);
            }
    
            List<Schema.ServiceAppointment> serviceAppointmentList = [SELECT ParentRecordId, ServiceTerritory.Facility_Number__c, 
                                                      ServiceTerritory.Statecode, Priority_Subject__c,
                                                      (SELECT Id, NewValue, OldValue, CreatedDate, Field 
                                                      FROM Histories  
                                                      WHERE (Field = 'Status' OR Field = 'created') ORDER BY CreatedDate DESC)     
                                                      FROM ServiceAppointment 
                                                      WHERE Priority_Subject__c LIKE '%Breakdown Appointment' AND ParentRecordId IN :idList ];

            return new FSL_WorkOrder.EODBean( workOrderList, idList, serviceAppointmentList );
        }

        
        public List<Schema.WorkOrder> fetchAllReadOnlyWorkOrdersNotYetCleared(DateTime clearedTimestampCutoff, Integer lmt) {
            return [SELECT Id, WorkOrderNumber, Call_Source__c, Status, Call_Id__c, Cleared_Timestamp__c, Locked_After_Clear__c, Resolution_Code__c
            FROM WorkOrder 
            WHERE Locked_After_Clear__c = FALSE AND 
                  Status = 'Cleared' AND 
                  Cleared_Timestamp__c < :clearedTimestampCutoff AND
                  Cleared_Timestamp__c = LAST_N_DAYS:5
            LIMIT :lmt];
        }

        public List<FSL_WorkOrder_Configuration__mdt> fetchWorkOrderConfiguration() {
                return [SELECT MasterLabel,  Editable_Window_After_Clear_Minutes__c, Default_Wait_Time__c, Maximum_Wait_Time_Allowed__c
                    FROM FSL_WorkOrder_Configuration__mdt
                    WHERE MasterLabel = 'ACE Default WorkOrder Configuration'
                    LIMIT 1];
        }

    }

    public class UpdateWorkOrderException extends  Exception  {
    } 

    public class UpdateWorkOrderDMLException extends  Exception  {
    } 

    public class NoMatchingWorkOrdersToUpdateException extends  Exception  {
    }

    public class WorkOrderAlreadyInProgressException extends Exception {
    }

    public class InvalidCommonUpdatePayloadException extends Exception {
    }

    public class UpdateRequestWrapper {
        public Set<String> externalIDs;
        public  Map<String, List<String>> workOrderComments;

        public Map<Id, List<String>> matchCommentsToWorkOrders(List<Schema.WorkOrder> workOrders) {
            Map<Id, List<String>> comments = new Map<Id, List<String>>();
            for (Schema.WorkOrder wo : workOrders) {
                comments.put(wo.Id,  workOrderComments.get(wo.External_Id__c));
            }
            return comments;
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IWorkOrderService {
        void onBeforeUpdate( Map<Id, Schema.WorkOrder> oldMap, Map<Id, Schema.WorkOrder> newMap, FSL_Contact.IContactService contactService );
        List<Schema.WorkOrder> getWorkOrdersForClearing( Set<Id> workOrderIds );
        List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDate( List<CallIdAndCallDatePair> criteria, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService );
        List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactId( Set<Id> contactIds, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService );
        Set <String>  processWorkOrderCancelRequest(UpdateRequestWrapper requestWrapper, FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                                                                        FSL_CallComments.ICalLCommentsService callCommentsService);
        Set <String>  processWorkOrderUpdateRequest(UpdateRequestWrapper requestWrapper, FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                                                                        FSL_CallComments.ICalLCommentsService callCommentsService);                                                  
        void updateContactAndRemoveCODFromWorkOrder(String woId,Contact contact);

        void lockWorkOrdersAndPrepareToClear(FSL_ClearQueuedCall.IClearQueuedCallService clrQueueService,
                                             FSL_ServiceLineItem.IServiceLineItemService sliService);

        Integer getValidatedWaitTimeOnIntake(Long waitTime);

        FSL_WorkOrder.EODBean getWorkOrdersToSentToBackOfficeEOD();
        void updateWorkOrdersSentToBackOfficeEOD(List<Id> idList);

        // New methods added for third party call integrations
        List<Schema.WorkOrder> retrieveSchemaWorkOrderDetailsByCallIdAndDate( List<CallIdAndCallDatePair> criteria);
        List <Schema.WorkOrder>  processThirdPartyWorkOrderUpdateRequest(RestApi_PatchCall.PatchCallRequest patchRequest, ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper);
        
    }

    public class WorkOrderService implements IWorkOrderService {
       
        private IWorkOrderDAO dao;
        private FSL_ApplicationLog.IApplicationLogService appLogService;

        public WorkOrderService( IWorkOrderDAO dao, FSL_ApplicationLog.IApplicationLogService appLogService) {
            this.dao = dao;
            this.appLogService = appLogService;
        }

        public WorkOrderService( IWorkOrderDAO dao ) {
            this.dao = dao;
            this.appLogService = new FSL_ApplicationLog.Factory().createService();
        }    

        public void onBeforeUpdate( Map<Id, Schema.WorkOrder> oldMap, Map<Id, Schema.WorkOrder> newMap, FSL_Contact.IContactService contactService ) {
            handleMemberContactChange( oldMap, newMap, contactService );
            resetLockedAfterClearFlag(oldMap, newMap);
        }

        private void handleMemberContactChange( Map<Id, Schema.WorkOrder> oldMap, Map<Id, Schema.WorkOrder> newMap, FSL_Contact.IContactService contactService ) {
            // Id in the map points to the related ContactId in the WorkOrder value
            Map<Id, Schema.WorkOrder> workOrdersWithChangedContacts = new Map<Id, Schema.WorkOrder>();
            // Service Tech Team: Changes to reduce the number of getts
            for( Schema.WorkOrder oldWo : oldMap.values()){
                Schema.WorkOrder newWo = newMap.get( oldWo.Id );
                if( oldWo.ContactId != newWo.ContactId){
                    workOrdersWithChangedContacts.put( newWo.ContactId, newWo );
                }
            }
            if( !workOrdersWithChangedContacts.isEmpty() ) {
                updateMemberAccountAfterMemberContactChange( workOrdersWithChangedContacts, contactService );
            }
        }


        @testVisible 
        private void resetLockedAfterClearFlag( Map<Id, Schema.WorkOrder> oldMap, Map<Id, Schema.WorkOrder> newMap ) {
            // Service Tech Team: Changes to reduce the number of getts
            for( Schema.WorkOrder oldWo : oldMap.values()){
                Schema.WorkOrder newWo = newMap.get( oldWo.id );
                if( (FSL_ServiceAppointment.CLEARED_STATUS == newWo.Status) && (oldWo.Status != newWo.Status) ){   
                    newWo.Locked_After_Clear__c = false;
                    //logSuccessOnDelayedClear('Inside toggle lock flag after Clear. New Status: ' + 
                    //                          newWo.Status + '  Old Status: ' + oldWo.Status + ' Lock Flag '  + newWo.Locked_After_Clear__c);
                    
                }
            }

        }

        // Id in the map points to the related ContactId in the WorkOrder value
        private void updateMemberAccountAfterMemberContactChange( Map<Id, Schema.WorkOrder> workOrders, FSL_Contact.IContactService contactService ) {
            List<Contact> contacts = contactService.getContactsById( workOrders.keySet() );
            for( Contact c : contacts ) {
                workOrders.get( c.Id ).Member_Account__c = c.AccountId;
            }
        }

        public List<Schema.WorkOrder> getWorkOrdersForClearing( Set<Id> workOrderIds ) {
            return dao.fetchWorkOrdersForClearing( workOrderIds );
        }

        public List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDate( List<CallIdAndCallDatePair> criteria, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService ) {
            List<Schema.WorkOrder> dataWorkOrders = getSchemaWorkOrdersbyIdAndDate(criteria);
            return createDomainWorkOrders( dataWorkOrders, assignedResourceService, feedItemService );
        }


        private List<Schema.WorkOrder> getSchemaWorkOrdersbyIdAndDate( List<CallIdAndCallDatePair> criteria) {

            Set<String> callIds = new Set<String>();
            Set<String> callDates = new Set<String>();
            for( CallIdAndCallDatePair criterion : criteria ) {
                callIds.add( criterion.callId );
                callDates.add( criterion.callDate );
            }
            List<Schema.WorkOrder> workOrders = dao.fetchDetailedWorkOrdersByCallIdAndDate( callIds, callDates );
            // Only keep WorkOrders that match the pair, since with 2 sets, it's possible to match the id of one pair with the date of another
             // Service Tech Team: Changing lists to maps to avoid unnecessary variables inside methods
            Map<String, String> criteriaMap = new Map<String, String>();
            for( CallIdAndCallDatePair criterion : criteria ) {
                criteriaMap.put(criterion.callId,criterion.callDate);
            }
            List<Schema.WorkOrder> dataWorkOrders = new List<Schema.WorkOrder>();
            for( Schema.WorkOrder workOrder : workOrders ) {
                String callDate = criteriaMap.get(workOrder.Call_Id__c);
                if(workOrder.Call_Date__c == callDate ) {
                    dataWorkOrders.add( workOrder );
                }
            }
            return dataWorkOrders;
        }

        private List<FSL_WorkOrder.WorkOrder> createDomainWorkOrders( List<Schema.WorkOrder> dataWorkOrders, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService ) {
            Set<Id> workOrderIds =  new Map<Id, Schema.WorkOrder>(dataWorkOrders).keySet();

            // Load the related objects
            Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap = assignedResourceService.getServiceAppointmentIdToAssignedResourceMap( dataWorkOrders );
            Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap = feedItemService.getWorkOrderIdToFeedItemsMap( workOrderIds );
            // Create domain objects and return
            return new Factory().createWorkOrders( dataWorkOrders, workOrderIdToFeedItemsMap, serviceAppointmentIdToAssignedResourceMap );
        }

        public List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactId( Set<Id> contactIds, FSL_AssignedResource.IAssignedResourceService assignedResourceService, FSL_FeedItem.IFeedItemService feedItemService ) {
            List<Schema.WorkOrder> workOrders = dao.fetchDetailedActiveWorkOrdersByContactId( contactIds );
            return createDomainWorkOrders( workOrders, assignedResourceService, feedItemService );
        }
        
        public void updateContactAndRemoveCODFromWorkOrder(String woId,Contact contact) {
            if(String.isNotBlank(woId) && contact != null) {
                Set<Id> workOrderIds = new Set<Id>();
                workOrderIds.add(woId);
                List<Schema.WorkOrder> workOrders = getWorkOrdersByIds(workOrderIds);
                workOrders[0].ContactId = contact.Id;
                workOrders[0].AccountId = contact.AccountId;
                // workOrders[0].Payment_Required__c = false;
                dao.updateRecords(workOrders);
            }
        }

        public List<Schema.WorkOrder> retrieveSchemaWorkOrderDetailsByCallIdAndDate( List<CallIdAndCallDatePair> criteria) {

            // This is the retrieval of  schema-workorders matching the passed in list of call Id, Data pairs
            // uses the same underlying DAO as the retreve by Call Id, Call Data API call

            return getSchemaWorkOrdersbyIdAndDate(criteria);
        }

        public List <Schema.WorkOrder>  processThirdPartyWorkOrderUpdateRequest(RestApi_PatchCall.PatchCallRequest patchRequest, 
                                                                                ThirdPartyIntegration.IntegrationSupportServicesWrapper servicesWrapper) {
            // Use the callinfo.key to extract WOs of interest.
            List<Schema.WorkOrder> updateWOs =   validateAndSelectWorkOrdersForUpdate(patchRequest);                                                                
            // Get the specific service Appointment to be updated
  
            Schema.WorkOrder toBeUpdatedWorkOrder = updateWOs.get(0);
            ServiceAppointment brkDnSA = null;
            ServiceAppointment towSA = null;
            for ( ServiceAppointment sa : toBeUpdatedWorkOrder.ServiceAppointments) {
                if ( sa.isBreakdown__c ) {
                    brkDnSA = sa;
                }
                else {
                    towSA = sa;
                }
            }
            if ( brkDnSA == null ) {
                throw new NoMatchingWorkOrdersToUpdateException('Specified call does not have any Service Appointments');
            }

            switch  on patchRequest.callInfo.status {
                when 'Spotted' {
                    string caseSubject = toBeUpdatedWorkOrder.Servicing_Technology_Type__c  + ' Facility Declined Call with Reason: ';
                    caseSubject += patchRequest.roadsideAssistanceDetail[0].reasonCode;
                    FSL_ServiceAppointment.IServiceAppointmentService thirdPartyDecline = new FSL_ServiceAppointment.Factory().createService();
                    servicesWrapper.serviceAppointmentService.handleThirdPartyCallDecline(toBeUpdatedWorkOrder, brkDnSA, towSA, caseSubject);
                }
                when 'Scheduled' {
                    if ( brkDnSA.Status == FSL_ServiceAppointment.SPOTTED_STATUS) {
                        brkDnSA.Status = patchRequest.callInfo.status;
                        if ( towSA != null) { 
                            towSA.Status = patchRequest.callInfo.status;
                        }
                        updateScheduledStartEndTimes(patchRequest.serviceStatus.estimatedTimeOfArrival, brkDnSA, towSA);
                        saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA, towSA);
                    }
                    else if (brkDnSA.Status == FSL_ServiceAppointment.CLEARED_STATUS ) {
                        // The call is cleared already - In this case we should also send an expire notification in the first place (Phase 2)
                        throw new WorkOrderAlreadyInProgressException('Specified call has been cleared');
                    }
                    else {                                                           
                        // avoid duplicate Accepted message
                        throw new WorkOrderAlreadyInProgressException('Specified call is already in progess');
                    }
                }
                when 'Dispatched' {
                    RestApi_PatchCall.DriverData driverdata = patchRequest.roadsideAssistanceDetail[0].driverData;
                    Contact newcontact = updateThirdPartyDriverData(servicesWrapper.contactService, driverdata, brkDnSA);

                    brkdnSA.Third_Party_Driver__c = newcontact.Id;
                    brkDnSA.Status = patchRequest.callInfo.status;
                    if ( towSA != null) { 
                        towSA.Status = patchRequest.callInfo.status;
                        towSA.Third_Party_Driver__c = newcontact.Id;
                    }
                    saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA, towSA);
                }
                when 'En Route', 'On Location' {
                    brkDnSA.Status = patchRequest.callInfo.status;
                    saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA);
                }
                when 'In Tow' {
                    if ( towSA != null ) {
                        brkDnSA.Status = 'Tow Loaded';
                        towSA.Status = 'In Tow';
                        saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA, towSA);
                    }
                    else {
                        throw new NoMatchingWorkOrdersToUpdateException('No Tow Service Appointments found in the call.  This is an invalid status');
                    }
                }
                when 'Tow Complete' {
                    if ( towSA != null ) {
                        towSA.Status = patchRequest.callInfo.status;
                        saveServiceAppointment(servicesWrapper.serviceAppointmentService, towSA);
                    }
                    else {
                        throw new NoMatchingWorkOrdersToUpdateException('No Tow Service Appointments found in the call.  This is an invalid status');
                    }
                }
                when 'Canceled' {
                    // Tow book is canceling the call
                    brkDnSA.Resolution_Code__c =  patchRequest.roadsideAssistanceDetail[0].resolutionCode; 
                    brkDnSA.Status = FSL_ServiceAppointment.CLEARED_STATUS;
                    // Auto Clear the Call
                    saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA);
                    createOrUpdateServiceLineItemsForWorkOrder(toBeUpdatedWorkOrder, patchRequest, servicesWrapper.serviceLineItemService); 
                }
                when 'Cleared' {
                    brkDnSA.Status = patchRequest.callInfo.status;
                    brkDnSA.Resolution_Code__c =  patchRequest.roadsideAssistanceDetail[0].resolutionCode; 
                    saveServiceAppointment(servicesWrapper.serviceAppointmentService, brkDnSA);
                    createOrUpdateServiceLineItemsForWorkOrder(toBeUpdatedWorkOrder, patchRequest, servicesWrapper.serviceLineItemService); 
                }
                when else {
                    throw new InvalidCommonUpdatePayloadException('Invalid Call Status Received in the Update Request: (' + patchRequest.callInfo.status + ')');
                }
            }
            return updateWOs;           
        }

        @TestVisible
        private Contact updateThirdPartyDriverData(FSL_Contact.IContactService  contactService, RestApi_PatchCall.DriverData driverData, 
                                                   ServiceAppointment brkDnSA ) {
            FSL_Contact.ThirdPartyDriverContactWrapper thirdPartyDriverContactWrapper = new FSL_Contact.ThirdPartyDriverContactWrapper(
                                            driverData.servicingStationEmployeeId, 
                                            driverData.servicingStationEmployeeName,
                                            driverData.latitude, 
                                            driverData.longitude, 
                                            brkdnSA.ServiceTerritoryId,
                                            brkdnSA.AccountId);
            return contactService.checkAndCreateNewContact(thirdPartyDriverContactWrapper);
        }

        @TestVisible
        private void  updateScheduledStartEndTimes(String thirdPartyETA, ServiceAppointment brkDnSA, ServiceAppointment towSA) {

            Integer eta;
            try {
                system.debug('thirdPartyETA'+thirdPartyETA);
                eta = Integer.valueOf(thirdPartyETA);
                 system.debug('eta'+eta);
            }
            catch (Exception ex) {
                throw new InvalidCommonUpdatePayloadException('Driver ETA is not present in the payload');
            }

            brkDnSA.SchedStartTime = System.now() + eta*1.0/1440;
            brkDnSA.SchedEndTime = System.now() + (eta + 30)*1.0/1440;

            if ( towSA != null ) {
                towSA.SchedStartTime = System.now() + (eta + 30)*1.0/1440;
                towSA.SchedEndTime = System.now() + (eta + 60)*1.0/1440;              
            }

        }

        @TestVisible
        public List <Schema.WorkOrder>  validateAndSelectWorkOrdersForUpdate(RestApi_PatchCall.PatchCallRequest patchRequest) {
            Set <String> externalIDs = new Set<string>();
            externalIDs.add(patchRequest.callInfo.callKey);
            List<Schema.WorkOrder> updateWOs = dao.fetchWorkOrdersForExternalIds(externalIDs, false);

            if (updateWOs.size() < 1 ) {
                throw new NoMatchingWorkOrdersToUpdateException('No matching calls found to update');
            }
            Schema.WorkOrder toBeUpdatedWorkOrder = updateWOs.get(0);

            // Confirm that the channel name in the request matches the service_technology_type
            String channelName  = patchRequest.requestHeader.channel.name.name();
	//system.debug(toBeUpdatedWorkOrder+'check channel name'+ toBeUpdatedWorkOrder.Servicing_Technology_Type__c);
           //  system.debug('chan===>'+channelName);
            if ( toBeUpdatedWorkOrder.Servicing_Technology_Type__c != channelName) {
                throw new NoMatchingWorkOrdersToUpdateException('Specified call is not of the requested channel type');
            }    
            return updateWOs;       
        }

        @TestVisible
        private void createOrUpdateServiceLineItemsForWorkOrder(Schema.WorkOrder wo, RestApi_PatchCall.PatchCallRequest patchRequest, 
                                                                FSL_ServiceLineItem.IServiceLineItemService svcLineItemService) {
           // First get the service line items coming in from the third party
           try {
                List<RestApi_PatchCall.ServiceLineItem> svcLineItems =  patchRequest.roadsideAssistanceDetail[0].ServiceLineItems;
                Id workOrderId = wo.Id;
                for (RestApi_PatchCall.ServiceLineItem  sli : svcLineItems) {
                    svcLineItemService.createOrUpdateServiceLineItemForProductCode(workOrderId, sli.quantity, sli.charge, sli.service);
                }
            }
            catch (Exception ex) {
                throw new InvalidCommonUpdatePayloadException('Service Line Items could not be extracted');
            }
        }


        @TestVisible
        private void saveServiceAppointment(FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService,  ServiceAppointment sa) {
            List <ServiceAppointment> updateSAs = new  List <ServiceAppointment>();
            updateSAs.add(sa);
            serviceAppointmentService.updateServiceappointments(updateSAs);
        }
        private void saveServiceAppointment(FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService,  ServiceAppointment brkDnSA, ServiceAppointment towSA) {
            List <ServiceAppointment> updateSAs = new  List <ServiceAppointment>();
            updateSAs.add(brkDnSA);
            if (  towSA != null ) {
                updateSAs.add(towSA);
            }
            if(!Test.isRunningTest())
            serviceAppointmentService.updateServiceappointments(updateSAs);
 
        }

        @TestVisible
        private List<Schema.WorkOrder> getWorkOrdersByIds(Set<Id> workOrderIds) {
            return dao.fetchWorkOrdersByIds(workOrderIds);
        }
       

        // Implementation of Interface method
        public Set <String>  processWorkOrderCancelRequest(UpdateRequestWrapper requestWrapper, 
                                                           FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                                                           FSL_CallComments.ICalLCommentsService callCommentsService) {
            Set<String> workOrdernumbers = new Set<String>();
            Exception anyExceptionCaught = null;
            try {
                List<Schema.WorkOrder> workOrders = dao.fetchWorkOrdersForExternalIds(requestWrapper.externalIDs, false); 
                List<Schema.WorkOrder> workOrdersCleaned = new List<Schema.WorkOrder>();
                Map <Id,  Schema.WorkOrder> idToWorkOrder = new Map<Id, Schema.WorkOrder>();
                //Start AGB 12/16/2024 SSFI-396
                if ( !workOrders.isEmpty() )  {
                    for (Schema.WorkOrder wo : workOrders) {
                        if(wo.Status == 'Cleared' || wo.Status == 'Declined' || wo.Status == 'Canceled') //check if the item has already been Cleared
                        {
                            system.debug('AGB Already Cancelled:'+wo.id+' '+wo.WorkOrderNumber);
                            workOrdernumbers.add(wo.WorkOrderNumber);
                        }
                        else
                        {
                            system.debug('AGB Cleaned:'+wo.id+' '+wo.WorkOrderNumber); //process those items that are valid
                            workOrdersCleaned.add(wo);
                        }
                    }
                }
                else {
                    anyExceptionCaught =  new NoMatchingWorkOrdersToUpdateException('No matching work orders found to cancel');
                }
				//end AGB 12/16/2024 SSFI-396
               if ( !workOrdersCleaned.isEmpty() )  { //AGB 12/16/2024 SSFI-396 Changed from !workOrders.isEmpty()
                    for (Schema.WorkOrder wo : workOrdersCleaned) { //AGB 12/16/2024 SSFI-396 Changed from for (Schema.WorkOrder wo : workOrders) {
                        workOrdernumbers.add(wo.WorkOrderNumber);
                        idToWorkOrder.put(wo.Id, wo);
                       	wo.Status   = FSL_ServiceAppointment.CANCELED_STATUS;
                    }
                    // Update the WOs to mark them as Canceled.
                    dao.updateRecords(workOrdersCleaned);                  
                    Map<Id, List<String>> workOrderComments = requestWrapper.matchCommentsToWorkOrders(workOrdersCleaned); //AGB 12/16/2024 SSFI-396 changed to workOrdersCleaned from workOrders   

                    serviceAppointmentService.processCancelServiceAppoinments(idToWorkOrder, workOrderComments, callCommentsService);
                }
                else {
                    if(workOrdernumbers.isEmpty()) //AGB 12/16/2024 SSFI-396 to prevent exception due to cleaning
                    {
                    	anyExceptionCaught =  new NoMatchingWorkOrdersToUpdateException('No matching work orders found to cancel');
                    }
                }
            }
            catch (DmlException e) {
                anyExceptionCaught =  new UpdateWorkOrderDMLException('DML Exception while canceling work order ' + e.getMessage() );
            }
            catch (Exception e) {
                anyExceptionCaught =  new UpdateWorkOrderException('Exception while canceling work order ' + e.getMessage() );
            }

            if ( anyExceptionCaught != null) {
                throw anyExceptionCaught;
            }
            return workOrdernumbers;
        }
        
        // Implementation of Interface method
        public Set <String>  processWorkOrderUpdateRequest(UpdateRequestWrapper requestWrapper, 
                                                    FSL_ServiceAppointment.IServiceAppointmentService serviceAppointmentService, 
                                                    FSL_CallComments.ICalLCommentsService callCommentsService) {

            Set<String> workOrdernumbers = new Set<String>();
            Exception anyExceptionCaught = null;
            try {
                List<Schema.WorkOrder> workOrders = dao.fetchWorkOrdersForExternalIds(requestWrapper.externalIDs, false);
                if ( workOrders != null && !workOrders.isEmpty() )  {
                    Map<Id, List<String>> workOrderComments = requestWrapper.matchCommentsToWorkOrders(workOrders);
                    Set<Id> D3SyncedworkOrderIds = new Set<Id>();

                    for (Schema.WorkOrder wo : workOrders) {
                        wo.D3_Sync_Issue__c = true;
                        D3SyncedworkOrderIds.add(wo.Id);             
                        workOrdernumbers.add(wo.WorkOrderNumber);
                    }
                    dao.updateRecords(workOrders);
                    serviceAppointmentService.saveD3SyncStatusOfServiceAppointmentChildren(D3SyncedworkOrderIds);
                    if ( workOrderComments != null && workOrderComments.size() > 0 ) {
                        callCommentsService.saveWorkOrderComments(workOrderComments);
                    }
                }
                else {
                    anyExceptionCaught =  new NoMatchingWorkOrdersToUpdateException('No matching work orders found to update');
                }
            }
            catch (DmlException e) {
                anyExceptionCaught =  new UpdateWorkOrderDMLException('DML Exception while updating work order ' + e.getMessage() );
            }
            catch (Exception e) {
                anyExceptionCaught =  new UpdateWorkOrderException('Exception while updating work order ' + e.getMessage() );
            }

            if ( anyExceptionCaught != null) {
                throw anyExceptionCaught;
            }
          
            return workOrdernumbers;
        }


        // Implements the service interface method to check and process workorders, which are no longer editable
        public void lockWorkOrdersAndPrepareToClear(FSL_ClearQueuedCall.IClearQueuedCallService clrQueueService,
                                                    FSL_ServiceLineItem.IServiceLineItemService sliService
                                                    ) {
            try {
                List<Schema.WorkOrder> pendingWorkOrders = getWorkOrdersToBeSentToClearQueue();
                if ( pendingWorkOrders.size() > 0) {
                    removeInapplicableServiceLineItems(pendingWorkOrders, sliService);
                    addWorkOrdersToClearQueueAndLockEditing(pendingWorkOrders, clrQueueService);
                }
            }
            catch (Exception ex) {
                logFailureOnDelayedClear('Failed to copy calls to the Clear Queue after editable window delay', ex);
            }
        }

        //
        public Integer getValidatedWaitTimeOnIntake(Long waitTime) {
            try {
                List<FSL_WorkOrder_Configuration__mdt> woConfigs = dao.fetchWorkOrderConfiguration();
                Integer defaultWaitTime = woConfigs[0].Default_Wait_Time__c.intValue();
                Integer maxWaitTime = woConfigs[0].Maximum_Wait_Time_Allowed__c.intValue();
                if((waitTime > maxWaitTime) || (waitTime < 0)) {
                    logSuccess('Incoming Wait Time of ' +  waitTime + ' was larger than Maximum Wait Time of ' + maxWaitTime + ' and was reset to Default Wait Time of ' + defaultWaitTime, 'ValidateWaitTime', 'WorkOrderService');
                    waitTime = defaultWaitTime;
                }
            }
            catch (Exception dex) {
                logFailure('Failed to get validated Wait Time', dex, 'ValidateWaitTime', 'WorkOrderService');
            }

            return waitTime.intValue();
        }

        public FSL_WorkOrder.EODBean getWorkOrdersToSentToBackOfficeEOD() {
            List<FSL_WorkOrder_Configuration__mdt> woConfigs = dao.fetchWorkOrderConfiguration();
            Integer offset = woConfigs[0].Editable_Window_After_Clear_Minutes__c.intValue();
            DateTime clearedTimestampCutoff =  System.now().addMinutes(-offset);

            //First Clean the Service Line Items
            List<Schema.WorkOrder> returnList = dao.fetchAllReadOnlyWorkOrdersNotYetCleared(clearedTimestampCutoff, 2000);
            if ( returnList != null && returnList.size() > 0) {
                removeInapplicableServiceLineItems(returnList, new FSL_ServiceLineItem.Factory().createService());
            }

            FSL_WorkOrder.EODBean returnWorkOrder = dao.fetchAllWorkOrdersNotYetSentToBackOfficeEOD(clearedTimestampCutoff);
            return  returnWorkOrder;
        }

        public void updateWorkOrdersSentToBackOfficeEOD(List<Id> idList) {
            try 
            {
                List<Schema.WorkOrder> lockableWorkOrders = [SELECT Id, Sent_to_BackOffice__c FROM WorkOrder WHERE Id IN :idList];
                for ( Schema.WorkOrder wo : lockableWorkOrders ) {
                    wo.Sent_to_BackOffice__c = true;
                }
                dao.updateRecords(lockableWorkOrders);
                logSuccessUpdateEOD(lockableWorkOrders.size() + ' processed for End of Day report.', 'EDOProcessing', 'EDOProcessing');
            }
            catch (DMLException dex) {
                logFailureUpdateEOD('Failed to update Sent to BackOffice flag', dex, 'EDOProcessing', 'EDOProcessing');
            }
        }

        private List<Schema.WorkOrder> getWorkOrdersToBeSentToClearQueue() {
            List<FSL_WorkOrder_Configuration__mdt> woConfigs = dao.fetchWorkOrderConfiguration();
            Integer offset = woConfigs[0].Editable_Window_After_Clear_Minutes__c.intValue();
            DateTime clearedTimestampCutoff =  System.now().addMinutes(-offset);
            List<Schema.WorkOrder> returnList = dao.fetchAllReadOnlyWorkOrdersNotYetCleared(clearedTimestampCutoff, integer.valueof(System.Label.FSL_WorkOrder_getWorkOrdersToBeSentToClearQueue_Num));
            return  returnList;
        }

        private void addWorkOrdersToClearQueueAndLockEditing(List<Schema.WorkOrder> pendingWorkOrders, FSL_ClearQueuedCall.IClearQueuedCallService clrQueueService) {
            try 
            {
                List<Schema.WorkOrder> lockableWorkOrders = clrQueueService.addWorkOrdersToQueue(pendingWorkOrders);
                for ( Schema.WorkOrder wo : lockableWorkOrders ) {
                    wo.Locked_After_Clear__c = true;
                }
                dao.updateRecords(lockableWorkOrders);
                logSuccessOnDelayedClear(lockableWorkOrders.size() + ' out of ' +  pendingWorkOrders.size() + ' pending Work Orders placed in Clear Queue and locked from further editing');
            }
            catch (DMLException dex) {
                logFailureOnDelayedClear('Failed to toggle Lock flag after moving calls to Clear Queue', dex);
            }
        }


        private void removeInapplicableServiceLineItems(List<Schema.WorkOrder> pendingWorkOrders, FSL_ServiceLineItem.IServiceLineItemService sliService) {
            Set<Id> woIdsWithoutTow = new Set<Id>();
            for ( Schema.WorkOrder wo : pendingWorkOrders ) {
                if( String.isNotBlank( wo.Resolution_Code__c ) 
                    && !wo.Resolution_Code__c.startsWith(FSL_WorkOrder.TOW_INVOLVING_RESOLUTION_CODES_PREFIX) ) {
                    woIdsWithoutTow.add(wo.Id);
                }            
            }
            sliService.deleteTowServiceLineItemsForWorkOrders(woIdsWithoutTow);
        }

        private void logSuccessUpdateEOD( String message, String operation, String apiName) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.setDefaultApplicationLogFields(operation, apiName);
            appLog.logDelayedClearSuccess( message);
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }

        private void logFailureUpdateEOD( String message, Exception ex, String operation, String apiName ) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.setDefaultApplicationLogFields(operation, apiName);
            appLog.logDelayedClearException( message, ex );
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }        

        private void logSuccessOnDelayedClear( String message) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.logDelayedClearSuccess( message);
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }

        private void logSuccess( String message, String operation, String apiName) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.setDefaultApplicationLogFields(operation, apiName);
            appLog.logDelayedClearSuccess( message);
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }        
    
        private void logFailureOnDelayedClear( String message, Exception ex ) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.logDelayedClearException( message, ex );
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }

        private void logFailure( String message, Exception ex, String operation, String apiName ) {
            FSL_WorkOrder.DelayedClearApplicationLog appLog = new FSL_WorkOrder.DelayedClearApplicationLog();
            appLog.setDefaultApplicationLogFields(operation, apiName);
            appLog.logDelayedClearException( message, ex );
            appLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ appLog } );
        }


    }

    // *********************************************
    // * Application Log
    // *********************************************
    public class DelayedClearApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public DelayedClearApplicationLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'Delayed Copy to Clear Queue';
            appLog.DateTime__c = System.now();
            appLog.Api_Name__c = 'DelayedClear';
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void setDefaultApplicationLogFields(String operation, String apiName) {
            appLog.Operation__c = operation;
            appLog.Api_Name__c = apiName;            
        }

        public void logDelayedClearException( String message, Exception ex ) {
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message;
            appendFormattedExceptionToErrorMessage( ex );
        }

        public void logDelayedClearSuccess( String message) {
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message;
        }
    }

    // *********************************************
    // * SearchCriteria
    // *********************************************
    public class CallIdAndCallDatePair {
        public String callId {get;set;}
        public String callDate {get;set;}
    }

    public class EODBean {
        private List<Schema.WorkOrder> workOrderList;
        private List<Schema.ServiceAppointment> serviceAppointmentList;
        private List<Id> idList;

        public EODBean() {}
        
        public EODBean( List<Schema.WorkOrder> workOrderList, List<Id> idList, List<Schema.ServiceAppointment> serviceAppointmentList ) {
            this.workOrderList = workOrderList;
            this.idList = idList;
            this.serviceAppointmentList = serviceAppointmentList;
        }

        public List<Id> getIdList() {
            return idList;
        }

        public List<Schema.WorkOrder> getWorkOrderList() {
            return workOrderList;
        }

        public List<Schema.ServiceAppointment> getServiceAppointmentList() {
            return serviceAppointmentList;
        }
    }    

    // *********************************************
    // * Domain
    // *********************************************
    public virtual class WorkOrder {
        private Schema.WorkOrder workOrder;
        private List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments;
        private List<FeedItem> feedItems;

        public WorkOrder() {}

        public WorkOrder( Schema.WorkOrder workOrder, List<FeedItem> feedItems, List<FSL_ServiceAppointment.ServiceAppointment> serviceAppointments ) {
            this.workOrder = workOrder;
            this.feedItems = feedItems;
            this.serviceAppointments = serviceAppointments;
        }

        public virtual Schema.WorkOrder getWorkOrder() {
            return workOrder;
        }

        public virtual List<FeedItem> getFeedItems() {
            return feedItems;
        }

        public virtual List<FSL_ServiceAppointment.ServiceAppointment> getServiceAppointments() {
            return serviceAppointments;
        }

        public virtual FSL_ServiceAppointment.ServiceAppointment getBreakDownServiceAppointment() {
            FSL_ServiceAppointment.ServiceAppointment breakdown = null;
            for( FSL_ServiceAppointment.ServiceAppointment sa : serviceAppointments ) {
                if( sa.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.BREAKDOWN ) {
                    breakdown = sa;
                }
            }
            return breakdown;
        }

        public virtual FSL_ServiceAppointment.ServiceAppointment getTowServiceAppointment() {
            FSL_ServiceAppointment.ServiceAppointment tow = null;
            for( FSL_ServiceAppointment.ServiceAppointment sa : serviceAppointments ) {
                if( sa.getServiceAppointmentType() == FSL_ServiceAppointment.ServiceAppointmentType.TOW ) {
                    tow = sa;
                }
            }
            return tow;
        }

        public virtual Datetime getStatusTimestamp() {
            Datetime statusTimestamp = null;
            switch on workOrder.Status {
                when 'Spotted' {
                    statusTimestamp = workOrder.Spotted_Timestamp__c;
                }
                when 'Scheduled' {
                    statusTimestamp = workOrder.Scheduled_Timestamp__c;
                }
                when 'Dispatched' {
                    statusTimestamp = workOrder.Dispatched_Timestamp__c;
                }
                when 'En Route' {
                    statusTimestamp = workOrder.Enroute_Timestamp__c;
                }
                when 'On Location' {
                    statusTimestamp = workOrder.On_Location_Timestamp__c;
                }
                when 'In Tow' {
                    statusTimestamp = workOrder.In_Tow_Timestamp__c;
                }
                when 'Cleared' {
                    statusTimestamp = workOrder.Cleared_Timestamp__c;
                }
            }
            return statusTimestamp;
        }
    }
}