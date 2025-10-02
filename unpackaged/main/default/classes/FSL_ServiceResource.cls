public with sharing class FSL_ServiceResource {
    public FSL_ServiceResource() {

    }
     // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IServiceResourceService createService();
        
    }
    public class Factory implements IFactory {
        public IServiceResourceService createService() {
            IServiceResourceDAO dao = createDAO();
            return new ServiceResourceService(dao);
        }

        private IServiceResourceDAO createDAO() {
            return new ServiceResourceDAO();
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IServiceResourceService {
        ServiceResource checkAndCreateNewResource(ServiceResourceWrapper servicewrp);
        List<ServiceResource> searchServiceResource(ServiceResourceWrapper servicewrp);
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IServiceResourceDAO extends FSL_DAO.DmlInterface {
        List<ServiceResource> fetchServiceResource(ServiceResourceWrapper servicewrp);
        ServiceResource createServiceResource(ServiceResourceWrapper servicewrp);
    }

    public class ServiceResourceDAO extends FSL_DAO.DmlBase implements IServiceResourceDAO {
        public List<ServiceResource> fetchServiceResource(ServiceResourceWrapper servicewrp) {
            return [Select Id From ServiceResource Where Name=:servicewrp.Name AND External_ID__c=:servicewrp.thirdpartydriverId];
        }
        public ServiceResource createServiceResource(ServiceResourceWrapper servicewrp) {
            ServiceResource resource=new ServiceResource();
            resource.Name=servicewrp.Name;
            resource.LastKnownLongitude=servicewrp.longitude;
            resource.LastKnownLatitude=servicewrp.latitude;
            resource.External_ID__c=servicewrp.thirdpartydriverId;
            resource.Primary_Service_Territory__c=servicewrp.facilityId;
            insert resource;
            return resource;
         }
    }


    // *********************************************
    // * Service
    // *********************************************
    public class ServiceResourceService implements IServiceResourceService {
        private IServiceResourceDAO dao;

        public ServiceResourceService(IServiceResourceDAO dao ) {
            this.dao = dao;
        }
        public List<ServiceResource> searchServiceResource(ServiceResourceWrapper servicewrp){
            return dao.fetchServiceResource(servicewrp);
        }
        public ServiceResource checkAndCreateNewResource(ServiceResourceWrapper servicewrp) {
                List<ServiceResource> resources=searchServiceResource(servicewrp);
                if(!resources.isEmpty()){
                    return resources[0];
                }
                return dao.createServiceResource(servicewrp);  
        }
    }
    public class ServiceResourceWrapper {
       public string thirdpartydriverId;
       public string driverId;
       public string Name;
       public Decimal latitude;
       public Decimal longitude;
       public string facilityId;
       public ServiceResourceWrapper(){

       }
       public ServiceResourceWrapper(string thirdpartydriverId,string Name ,Decimal latitude,Decimal longitude,string facilityId){
        this.thirdpartydriverId=thirdpartydriverId;
        this.Name=Name;
        this.latitude=latitude;
        this.longitude=longitude;
        this.facilityId=facilityId;
       }
    }

}