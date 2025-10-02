/****
 * *@Name: ServiceAppointment
 * *@Description: when the workorder is created Update the ServiceAppointment Address,lat,lag etc.. from WorkOrder. *  * @Modification Log   : 
 * Ver       Date           Author           Modification
 * 1.0                 Vincent               Initial Version
 *  *     03/18/2021   Dylan Truong         ERS-221797 - Fix Gantt Icon issue when status change by user who are not part of club dispatcher
 *  *     05/11/2021   Dylan Truong         ERS-220396 - Make Appointment Calls More Visible to FSL Users 
 ***/
public with sharing class FSL_ServiceAppointment {

    public enum IconType { RAP, COD, Appointment, AppointmentRAP, AppointmentCOD, Canceled }

     // Shankar ERS-226724 changes  

    public static final Set<String> STATUSES_REQURING_CASE_FOR_CANCELED_LANDLINE_CALL = new Set<String>{'Dispatched', 'En Route'};
    public static final Set<String> AUTO_CLEARABLE_STATUSES = new Set<String>{'Spotted', 'Scheduled', 'Dispatched'};
    public static final Set<String> LANDLINE_CALL_AUTO_CLEARABLE_STATUSES = new Set<String>{'Spotted', 'Scheduled'};
    public static final Set<String> TOWBOOK_AUTO_CLEARABLE_STATUSES = new Set<String>{'Spotted'};

    public static final String LANDLINE_TECHNOLOGY_TYPE = 'Landline';
    public static final String RESOLUTION_CODE_CANCELED_BEFORE_ENROUTE= 'X001';
    public static final String BREAKDOWN_TYPE= 'Breakdown';

    public static final String SPOTTED_STATUS           = 'Spotted';
    public static final String SCHEDULED_STATUS         = 'Scheduled';
    public static final String DISPATCHED_STATUS        = 'Dispatched';
    public static final String EN_ROUTE_STATUS          = 'En Route';
    public static final String ON_LOCATION_STATUS       = 'On Location';
    public static final String IN_TOW_STATUS            = 'In Tow';
    public static final String TOW_COMPLETE_STATUS      = 'Tow Complete';
    public static final String CANCELED_STATUS          = 'Canceled';
    public static final String CLEARED_STATUS           = 'Cleared';


    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IServiceAppointmentService createService();
        List<FSL_ServiceAppointment.ServiceAppointment> createServiceAppointments( List<Schema.ServiceAppointment> serviceAppointments, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap );
    }

    public class Factory implements IFactory {
        public IServiceAppointmentService createService() {
            IServiceAppointmentDAO dao = createDAO();
            return new ServiceAppointmentService( dao );
        }

        private IServiceAppointmentDAO createDAO() {
            return new ServiceAppointmentDAO();
        }

        public List<FSL_ServiceAppointment.ServiceAppointment> createServiceAppointments( List<Schema.ServiceAppointment> serviceAppointments, Map<Id, AssignedResource> serviceAppointmentIdToAssignedResourceMap ) {
            List<FSL_ServiceAppointment.ServiceAppointment> domainServiceAppointments = new List<FSL_ServiceAppointment.ServiceAppointment>();
            FSL_AssignedResource.IFactory assignedResourceFactory = new FSL_AssignedResource.Factory();
            for( Schema.ServiceAppointment serviceAppointment : serviceAppointments ) {
                FSL_AssignedResource.AssignedResource assignedResource = serviceAppointmentIdToAssignedResourceMap.containsKey( serviceAppointment.Id ) ? assignedResourceFactory.createAssignedResource( serviceAppointmentIdToAssignedResourceMap.get( serviceAppointment.Id ) ) : null;
                domainServiceAppointments.add( createServiceAppointment( serviceAppointment, assignedResource ) );
            }
            return domainServiceAppointments;
        }

        private FSL_ServiceAppointment.ServiceAppointment createServiceAppointment( Schema.ServiceAppointment serviceAppointment, FSL_AssignedResource.AssignedResource assignedResource ) {
            FSL_ServiceAppointment.ServiceAppointment domainServiceAppointment = null;
            // switch on serviceAppointment.Subject {
            //     when 'Breakdown Appointment' {
            //         domainServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment( serviceAppointment, assignedResource );
            //     }
            //     when 'Tow Appointment' {
            //         domainServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment( serviceAppointment, assignedResource );
            //     }
            // }
            if (serviceAppointment.IsBreakdown__c) {
                domainServiceAppointment = new FSL_ServiceAppointment.BreakdownServiceAppointment(serviceAppointment, assignedResource);
            } else {
                domainServiceAppointment = new FSL_ServiceAppointment.TowServiceAppointment(serviceAppointment, assignedResource);
            }
            return domainServiceAppointment;
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IServiceAppointmentDAO extends FSL_DAO.DmlInterface {
        List<Schema.ServiceAppointment> fetchBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds );
        //ERS-230874 Glympse Removal
        //List<Schema.ServiceAppointment> fetchServiceAppointmentByGlympseTaskId( Integer glympseTaskId );
        List<Schema.ServiceAppointment> fetchServiceAppointmentsForWorkOrders( Set<Id> workOrderIds );
        List<Schema.ServiceAppointment> fetchServiceAppointmentsForWorkOrders( Set<Id> workOrderIds, Set<Id> excludedServiceAppointmentIds );
        List<FSL_Gantt_Icon__mdt> fetchGanttIcons();
    }

    public class ServiceAppointmentDAO extends FSL_DAO.DmlBase implements IServiceAppointmentDAO {
        public List<Schema.ServiceAppointment> fetchBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds ) {
            return [SELECT Id, Status, Resolution_Code__c, Canceled_Timestamp__c, ContactId, FSL__InJeopardyReason__c, ParentRecordId, ServiceTerritoryId, Service_Resource__c, 
                        ParentRecord.Name, 
                        RecordType.Name,
                        Servicing_Technology_Type__c,
                        isBreakdown__c
                    FROM ServiceAppointment 
                    WHERE ParentRecordId IN :workOrderIds 
                    AND RecordType.Name = 'Breakdown'];
        }

        //ERS-230874 Glympse Removal
        //public List<Schema.ServiceAppointment> fetchServiceAppointmentByGlympseTaskId( Integer glympseTaskId ) {
        //    return [SELECT Id, AppointmentNumber, FSL_Actual_Miles_Driven__c, Glympse_EnRoute__Glympse_EnRoute_Task_ID__c, ParentRecordId, Status, 
        //                RecordType.Name 
        //            FROM ServiceAppointment 
        //            WHERE Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = :glympseTaskId 
        //            LIMIT 1];
        //}

        public List<Schema.ServiceAppointment> fetchServiceAppointmentsForWorkOrders( Set<Id> workOrderIds ) {
            return fetchServiceAppointmentsForWorkOrders( workOrderIds, new Set<Id>() );
        }

        public List<Schema.ServiceAppointment> fetchServiceAppointmentsForWorkOrders( Set<Id> workOrderIds, Set<Id> excludedServiceAppointmentIds ) {
            return [SELECT Id, AppointmentNumber, FSL_Actual_Miles_Driven__c, ParentRecordId, Status, Canceled_Timestamp__c, isBreakdown__c, Resolution_Code__c, Subject, 
                        RecordType.Name, D3_Sync_Issue__c,
                        Servicing_Technology_Type__c
                    FROM ServiceAppointment 
                    WHERE ParentRecordId IN :workOrderIds
                    AND Id NOT IN :excludedServiceAppointmentIds];
        }

        public List<FSL_Gantt_Icon__mdt> fetchGanttIcons() {
            return [SELECT Icon_Type__c, Image_Name__c
                    FROM   FSL_Gantt_Icon__mdt];
        }
        
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IServiceAppointmentService {
        List<Schema.ServiceAppointment> getBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds );
        Schema.ServiceAppointment updateActualMilesDriven( Integer glympseTaskId, Decimal actualMilesDriven, FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService );
        void setGanttIconUrlByType(List<Schema.ServiceAppointment> serviceAppointments, Map<Id,WorkOrder> wo );
        void saveD3SyncStatusOfServiceAppointmentChildren(Set<Id> workOrderIds);
        void syncStatusBetweenRelatedServiceAppointments( List<ServiceAppointment> serviceAppointments, List<FSL_WO_To_SA_Status_Mapping__mdt> woToSaStatusMapping );
        void processCancelServiceAppoinments( Map<Id, WorkOrder> idToWorkOrder, Map<Id, List<String>> cancelComments, FSL_CallComments.ICalLCommentsService callCommentsService);
        Boolean isAutoClearableOnCancel(Schema.ServiceAppointment sa);
        void updateServiceAppointments(List<Schema.ServiceAppointment> toBeUpdatedSAs);
        void handleThirdPartyCallDecline(WorkOrder wo, Schema.ServiceAppointment brkDnSA, Schema.ServiceAppointment towSA, String caseSubject);
    }

    public class ServiceAppointmentService implements IServiceAppointmentService {
        private IServiceAppointmentDAO dao;

        public ServiceAppointmentService( IServiceAppointmentDAO dao ) {
            this.dao = dao;
        }

        public List<Schema.ServiceAppointment> getBreakDownServiceAppointmentsForWorkOrders( Set<Id> workOrderIds ) {
            return dao.fetchBreakDownServiceAppointmentsForWorkOrders( workOrderIds );
        }
        
        //ERS-230874 Glympse Removal - Part I
        public Schema.ServiceAppointment updateActualMilesDriven( Integer glympseTaskId, Decimal actualMilesDriven, FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService ) {
            Schema.ServiceAppointment updatedServiceAppointment = null;
            //List<Schema.ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentByGlympseTaskId( glympseTaskId );
            //if( serviceAppointments.isEmpty() ) {
            //    System.debug( LoggingLevel.ERROR, 'FSL_ServiceAppointment.ServiceAppointmentService.updateActualMilesDriven: Failed to query the ServiceAppointment for Glympse Task Id = [' + glympseTaskId + ']' );
            //}
            //else {
            //    System.debug( LoggingLevel.DEBUG, 'FSL_ServiceAppointment.ServiceAppointmentService.updateActualMilesDriven: Updating Actual Miles Driven for Service Appointment Id = [' + serviceAppointments[0].Id + ']' );
            //    updateActualMilesDriven( serviceAppointments[0], actualMilesDriven );
            //    updateClearQueueIfAllServiceAppointmentsForWorkOrderHaveActualMilesPresent( serviceAppointments[0].ParentRecordId, clearQueuedCallService );
            //    updatedServiceAppointment = serviceAppointments[0];
            //}
            return updatedServiceAppointment;
        }

        private void updateActualMilesDriven( Schema.ServiceAppointment sa, Decimal actualMilesDriven ) {
            sa.FSL_Actual_Miles_Driven__c = actualMilesDriven;
            dao.updateRecords( new List<Schema.ServiceAppointment>{ sa } );
        }

        private void updateClearQueueIfAllServiceAppointmentsForWorkOrderHaveActualMilesPresent( Id workOrderId, FSL_ClearQueuedCall.IClearQueuedCallService clearQueuedCallService ) {
            if( isActualMilesDrivenPresentForAllServiceAppointmentsForWorkOrder( workOrderId ) ) {
                System.debug( LoggingLevel.DEBUG, 'FSL_ServiceAppointment.ServiceAppointmentService.updateClearQueueIfAllServiceAppointmentsForWorkOrderHaveActualMilesPresent: All Service Appointments have Actual Miles Driven present. Updating Clear Queued Call - WorkOrder Id [' + workOrderId + ']' );
                clearQueuedCallService.updateMileageReceived( workOrderId, FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.COMPLETE );
            }
            else {
                System.debug( LoggingLevel.DEBUG, 'FSL_ServiceAppointment.ServiceAppointmentService.updateClearQueueIfAllServiceAppointmentsForWorkOrderHaveActualMilesPresent: Not all Service Appointments have Actual Miles Driven present - WorkOrder Id [' + workOrderId + ']' );
                clearQueuedCallService.updateMileageReceived( workOrderId, FSL_ClearQueuedCall.ClearQueuedCallMileageReceivedStatus.PARTIAL );
            }
        }

        private Boolean isActualMilesDrivenPresentForAllServiceAppointmentsForWorkOrder( Id workOrderId ) {
            Boolean isPresent = true;
            Set<Id> woSet = new Set<Id> { workOrderId };
            List<Schema.ServiceAppointment> allServiceAppointmentsForWorkOrder = dao.fetchServiceAppointmentsForWorkOrders( woSet );

            for( Schema.ServiceAppointment sa : allServiceAppointmentsForWorkOrder ) {
                if( sa.FSL_Actual_Miles_Driven__c == null ) {
                    isPresent = false;
                }
            }
            return isPresent;
        }

        public void setGanttIconUrlByType( List<Schema.ServiceAppointment> serviceAppointments, Map<Id,WorkOrder> wo ) {
            Map<String,String> ganttIconUrls = new Map<String,String>();
            ganttIconUrls = generateGanttIconUrlSet();
            for(Schema.ServiceAppointment sa : serviceAppointments) {                                                            
                sa.FSL__GanttIcon__c = getGanttIconUrlByType(sa, wo, ganttIconUrls);
            }
        }

        @testVisible
        private String getGanttIconUrlByType(Schema.ServiceAppointment sa, Map<Id, WorkOrder> woSet, Map<String,String> ganttIconUrls){
            String ganttIconUrl = '';
            WorkOrder wo = woSet.get(sa.ParentRecordId) != null? woSet.get(sa.ParentRecordId): new WorkOrder() ;
            Boolean isAppointmentService = String.isNotBlank(wo.Non_Emergency_Appointment_Time__c);

            if ( wo.Status == 'Canceled' || sa.Status == 'Canceled') {
                ganttIconUrl = ganttIconUrls.get(IconType.Canceled.name());
            }
            else {
                if (isAppointmentService) {
                    ganttIconUrl = ganttIconUrls.get(IconType.Appointment.name());
                }
                if (wo.Call_Type__c == IconType.RAP.name()) {
                    if (isAppointmentService) {
                        ganttIconUrl = ganttIconUrls.get(IconType.AppointmentRAP.name());
                    } else {
                        ganttIconUrl = ganttIconUrls.get(IconType.RAP.name());
                    } 
                } else if ((sa.isBreakdown__c && sa.Payment_Required__c) ||
                    (!sa.isBreakdown__c && !wo.ServiceAppointments.isEmpty() && wo.ServiceAppointments[0].Payment_Required__c)
                ) {
                    if (isAppointmentService) {
                        ganttIconUrl = ganttIconUrls.get(IconType.AppointmentCOD.name());
                    } else {
                        ganttIconUrl = ganttIconUrls.get(IconType.COD.name());
                    } 
                }
            }
            return ganttIconUrl;
    
        }
    
        private Map<String,String> generateGanttIconUrlSet() {
            Map<String,String> ganttIconUrlMap   = new Map<String,String>();
            List<FSL_Gantt_Icon__mdt> ganttIcons = dao.fetchGanttIcons();
            for(FSL_Gantt_Icon__mdt ganttIcon: ganttIcons) {
                String staticImageUrl = retrieveStaticResourceUrl(ganttIcon.Image_Name__c);
                String ganttIconUrl   = constructGanttIconUrl(staticImageUrl);
                ganttIconUrlMap.put(ganttIcon.Icon_Type__c, ganttIconUrl);
            }
            return ganttIconUrlMap;
        }
        
        @testVisible
        private String constructGanttIconUrl( String iconUrl ) {
            String ganttIconUrl = '';
            if(String.IsNotBlank(iconUrl)) {
                ganttIconUrl = removeTrailingUrl(iconUrl);
                ganttIconUrl = ganttIconUrl.substring(ganttIconUrl.indexOf('resource'), ganttIconUrl.length());
                ganttIconUrl = '/' + ganttIconUrl;
            }
            return ganttIconUrl;
        }
    
        @testVisible
        private String retrieveStaticResourceUrl( String resourceName ) {
            return String.isNotBlank(resourceName) 
                   ? PageReference.forResource(resourceName).getUrl() 
                   : '';
        }
    
        @testVisible
        private String removeTrailingUrl( String iconUrl) {
            String url = '';
            if (String.isNotBlank(iconUrl)) {
                url = iconUrl.indexOf('?') > 0 
                      ? iconUrl.subString(0, iconUrl.indexOf('?'))
                      : iconUrl;
            }
            return url;   
        }

        public void saveD3SyncStatusOfServiceAppointmentChildren(Set<Id> workOrderIds) {
            List <Schema.ServiceAppointment> serviceAppointments = dao.fetchServiceAppointmentsForWorkOrders(workOrderIds);
            if ( serviceAppointments != null ) {
                for(Schema.ServiceAppointment sa: serviceAppointments){
                    sa.D3_Sync_Issue__c = true;
                }
                dao.updateRecords(serviceAppointments);
            }
        }

        public void syncStatusBetweenRelatedServiceAppointments( List<ServiceAppointment> serviceAppointments, List<FSL_WO_To_SA_Status_Mapping__mdt> woToSaStatusMapping ) {
            Map<Id, ServiceAppointment> relatedServiceAppointments = loadRelatedServiceAppointments( serviceAppointments );
            Map<String, String> breakdownStatusToTowStatusMap = new Map<String, String>();
            for (FSL_WO_To_SA_Status_Mapping__mdt mapping : woToSaStatusMapping) {
                breakdownStatusToTowStatusMap.put(mapping.Breakdown_Appointment__c, mapping.Tow_Appointment__c);
            }

            for (ServiceAppointment sa : serviceAppointments) {
                Id parentRecordId = sa.getServiceAppointment().ParentRecordId;
                if( relatedServiceAppointments.containsKey( parentRecordId ) ) {
                    sa.syncStatus( relatedServiceAppointments.get( parentRecordId ), breakdownStatusToTowStatusMap );
                }
            }
        }
        
        private Boolean shouldAutoClearCall(Schema.ServiceAppointment sa, String technologyType ) {
            // Only return true for Breakdown SAs, in certain status that itself depends on whether it is a regular
            // or Landline call.
            Boolean autoClear = false;
            if ( sa.isBreakdown__c)  {

                if ( FSL_ServiceAppointment.LANDLINE_TECHNOLOGY_TYPE.equalsIgnoreCase(technologyType)) {
                    autoClear =  FSL_ServiceAppointment.LANDLINE_CALL_AUTO_CLEARABLE_STATUSES.contains(sa.status);
                }
                else if ( ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK.equalsIgnoreCase(technologyType) ) {
                    autoClear = FSL_ServiceAppointment.TOWBOOK_AUTO_CLEARABLE_STATUSES.contains(sa.status);      
                }
                else {
                    autoClear = FSL_ServiceAppointment.AUTO_CLEARABLE_STATUSES.contains(sa.status);      
                }                  
            }
            return autoClear; 
        }

        public Boolean isAutoClearableOnCancel(Schema.ServiceAppointment sa) {
            return shouldAutoClearCall(sa, sa.Servicing_Technology_Type__c);
        }

        // Interface method called from FSL_WorkOrder - processWorkOrderCancelRequest, which handles exceptions
        public void processCancelServiceAppoinments(Map <Id, WorkOrder> idToWorkOrder, Map<Id, List<String>> cancelComments, 
                                                    FSL_CallComments.ICalLCommentsService callCommentsService) {

            Set<id> workOrderIds = idToWorkOrder.keyset();
            List<Schema.ServiceAppointment> candidateSAsForCancel = dao.fetchBreakDownServiceAppointmentsForWorkOrders( workOrderIds );      

            if ( candidateSAsForCancel != null  &&  !candidateSAsForCancel.isEmpty())  {

                for (Schema.ServiceAppointment sa : candidateSAsForCancel) {
                    WorkOrder wo = idToWorkOrder.get(sa.ParentRecordId);

                    // Only breakdown SAs are coandidates for Auto Clear
                    // This function checks for it internally
                    if ( isAutoClearableOnCancel(sa) ) {
                        sa.Resolution_Code__c = FSL_ServiceAppointment.RESOLUTION_CODE_CANCELED_BEFORE_ENROUTE;
                    }
                    else {
                        sa.Status = FSL_ServiceAppointment.CANCELED_STATUS;
                    }
                    sa.Canceled_Timestamp__c = System.now();
                }
                // Commit changes to all the breakdown appointntments and the related appointments that were set to Canceled.
                dao.updateRecords(candidateSAsForCancel);                   
                if ( cancelComments != null && cancelComments.size() > 0 ) {
                    callCommentsService.saveWorkOrderComments(cancelComments);
                }
            }   
        }


        private Map<Id, ServiceAppointment> loadRelatedServiceAppointments( List<ServiceAppointment> serviceAppointments ) {
            Map<Id, ServiceAppointment> relatedServiceAppointments = new Map<Id, ServiceAppointment>();
            Set<Id> parentRecordIds = new Set<Id>();
            Set<Id> excludedServiceAppointmentIds = new Set<Id>();
            for( ServiceAppointment sa : serviceAppointments ) {
                parentRecordIds.add( sa.getServiceAppointment().ParentRecordId );
                excludedServiceAppointmentIds.add( sa.getServiceAppointment().Id );
            }
            List<Schema.ServiceAppointment> temp = dao.fetchServiceAppointmentsForWorkOrders( parentRecordIds, excludedServiceAppointmentIds );
            List<ServiceAppointment> domainTemp = new Factory().createServiceAppointments( temp, new Map<Id, AssignedResource>() );
            for( ServiceAppointment sa : domainTemp ) {
                relatedServiceAppointments.put( sa.getServiceAppointment().ParentRecordId, sa );
            }
            return relatedServiceAppointments;
        }

        // Required Interface Method
        public void updateServiceAppointments(List<Schema.ServiceAppointment> toBeUpdatedSAs) {
            dao.updateRecords(toBeUpdatedSAs);
        }

        public void handleThirdPartyCallDecline(WorkOrder wo, Schema.ServiceAppointment brkDnSA, Schema.ServiceAppointment towSA, String caseSubject) {
            try{
               // sa.FSL__InJeopardy__c= true;
               // sa.FSL__InJeopardyReason__c= 'Facility Decline';
               brkDnSA.Decline_Work_Reason__c = 'Third Party Dispatcher Declined Call';
               // dao.updateRecords( new List<Schema.ServiceAppointment>{sa} );
                FSL_Case.ICaseService caseService = new FSL_Case.Factory().createService();
                caseService.thirdPartyDeclineCase(wo, brkDnSA, towSA, caseSubject);
            }
            catch(Exception e){
                throw new FSL_WorkOrder.UpdateWorkOrderException('Failed during Case Creation ' + e.getStackTraceString());
                    
            }
            
        }
    }

   

    // *********************************************
    // * Domain
    // *********************************************
    public enum ServiceAppointmentType {
        BREAKDOWN,
        TOW
    }

    public abstract class ServiceAppointment {
        protected Schema.ServiceAppointment serviceAppointment;
        protected FSL_AssignedResource.AssignedResource assignedResource;

        public ServiceAppointment( Schema.ServiceAppointment serviceAppointment, FSL_AssignedResource.AssignedResource assignedResource ) {
            this.serviceAppointment = serviceAppointment;
            this.assignedResource = assignedResource;
        }

        public virtual Schema.ServiceAppointment getServiceAppointment() {
            return serviceAppointment;
        }

        public virtual FSL_AssignedResource.AssignedResource getAssignedResource() {
            return assignedResource;
        }

        public abstract ServiceAppointmentType getServiceAppointmentType();
        public abstract void syncStatus( ServiceAppointment relatedAppointment, Map<String, String> breakdownStatusToTowStatusMap );

        public virtual Boolean hasAddressChanged() {
            return serviceAppointment.Address_Change_Counter__c != null 
                && serviceAppointment.Address_Change_Counter__c > 0;
        }

        public virtual String getFullAddress() {
            String full = '';
            full += String.isBlank( serviceAppointment.Street ) ? '' : serviceAppointment.Street + ' ';
            full += String.isBlank( serviceAppointment.City ) ? '' : serviceAppointment.City + ', ';
            full += String.isBlank( serviceAppointment.State ) ? '' : serviceAppointment.State + ' ';
            full += String.isBlank( serviceAppointment.PostalCode ) ? '' : serviceAppointment.PostalCode + ' ';
            full += String.isBlank( serviceAppointment.Country ) ? '' : serviceAppointment.Country;
            return full;
        }
    }

    public class BreakdownServiceAppointment extends ServiceAppointment {
        public BreakdownServiceAppointment( Schema.ServiceAppointment serviceAppointment, FSL_AssignedResource.AssignedResource assignedResource ) {
            super( serviceAppointment, assignedResource );
        }

        public override ServiceAppointmentType getServiceAppointmentType() {
            return ServiceAppointmentType.BREAKDOWN;
        }

        public override void syncStatus( ServiceAppointment relatedAppointment, Map<String, String> breakdownStatusToTowStatusMap ) {
            // Not Implemented at this time, since there is currently only a need for this on the Tow Appointment
        }
    }

    public class TowServiceAppointment extends ServiceAppointment {
        public TowServiceAppointment( Schema.ServiceAppointment serviceAppointment, FSL_AssignedResource.AssignedResource assignedResource ) {
            super( serviceAppointment, assignedResource );
        }

        public override ServiceAppointmentType getServiceAppointmentType() {
            return ServiceAppointmentType.TOW;
        }

        public override void syncStatus( ServiceAppointment relatedAppointment, Map<String, String> breakdownStatusToTowStatusMap ) {
            String breakdownStatus = relatedAppointment.getServiceAppointment().Status;
            String correspondingTowStatus = breakdownStatusToTowStatusMap.get(breakdownStatus);
            // for (FSL_WO_To_SA_Status_Mapping__mdt mapping : woToSaStatusMapping) {
                if (serviceAppointment.Status != correspondingTowStatus && String.isNotBlank(correspondingTowStatus)) {
                    serviceAppointment.Status = correspondingTowStatus;
                }
            // }
        }
    }
}