public with sharing class FSL_AssignedResource {
    
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IAssignedResourceService createService();
        FSL_AssignedResource.AssignedResource createAssignedResource( Schema.AssignedResource assignedResource );
    }

    public class Factory implements IFactory {
        public IAssignedResourceService createService() {
            IAssignedResourceDAO dao = createDAO();
            return new AssignedResourceService( dao );
        }

        private IAssignedResourceDAO createDAO() {
            return new AssignedResourceDAO();
        }

        public FSL_AssignedResource.AssignedResource createAssignedResource( Schema.AssignedResource assignedResource ) {
            return new AssignedResource( assignedResource );
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IAssignedResourceDAO extends FSL_DAO.DmlInterface {
        List<Schema.AssignedResource> fetchAssignedResourcesForServiceAppointments( List<ServiceAppointment> serviceAppointments );
    }

    public class AssignedResourceDAO extends FSL_DAO.DmlBase implements IAssignedResourceDAO {
        public List<Schema.AssignedResource> fetchAssignedResourcesForServiceAppointments( List<ServiceAppointment> serviceAppointments ) {
            return ( [SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.Name,ServiceResource.LocationId, 
                        ServiceResource.Vehicle__r.Truck_ID__c, ServiceResource.Location.Longitude, ServiceResource.Location.Latitude,
                        ServiceResource.Location.VIN__c, ServiceResource.Driver_Id__c
                    FROM AssignedResource 
                    WHERE ServiceAppointmentId IN :serviceAppointments] );
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IAssignedResourceService {
        Map<Id, Schema.AssignedResource> getServiceAppointmentIdToAssignedResourceMap( List<WorkOrder> workOrders );
    }

    public class AssignedResourceService implements IAssignedResourceService {
        private IAssignedResourceDAO dao;

        public AssignedResourceService( IAssignedResourceDAO dao ) {
            this.dao = dao;
        }

        public Map<Id, Schema.AssignedResource> getServiceAppointmentIdToAssignedResourceMap( List<WorkOrder> workOrders ) {
            Map<Id, Schema.AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, Schema.AssignedResource>();

            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            for( WorkOrder wo : workOrders ) {
                serviceAppointments.addAll( wo.ServiceAppointments );
            }
            
            List<Schema.AssignedResource> assignedResources = dao.fetchAssignedResourcesForServiceAppointments( serviceAppointments );
            for( ServiceAppointment sa : serviceAppointments ) {
                serviceAppointmentIdToAssignedResourceMap.put( sa.Id, getAssignedResources( sa, assignedResources ) );
            }

            return serviceAppointmentIdToAssignedResourceMap;
        }

        private Schema.AssignedResource getAssignedResources( ServiceAppointment sa, List<Schema.AssignedResource> assignedResources ) {
            Schema.AssignedResource assignedResource = new Schema.AssignedResource();
            for( Schema.AssignedResource ar : AssignedResources ) {
                if( ar.ServiceAppointmentId == sa.Id ) {
                    assignedResource = ar;
                    break;
                }
            }
            return assignedResource;
        }
    }

    // *********************************************
    // * Domain
    // *********************************************
    public virtual class AssignedResource {
        private Schema.AssignedResource assignedResource;

        public AssignedResource( Schema.AssignedResource assignedResource ) {
            this.assignedResource = assignedResource;
        }

        public virtual Schema.AssignedResource getAssignedResource() {
            return assignedResource;
        }

        // TODO: Create Domain object for Service Resource and inject into the c'tor
        public virtual ServiceResource getServiceResource() {
            ServiceResource serviceResource = null;
            if( assignedResource != null ) {
                serviceResource = assignedResource.ServiceResource;
            }
            return serviceResource;
        }
    }
}