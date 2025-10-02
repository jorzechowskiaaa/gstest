public with sharing class FSL_ServiceResourceTest {
    public FSL_ServiceResourceTest() {}
    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ServiceResource.IFactory {
        public FSL_ServiceResource.IServiceResourceService createService() {
            return new ServiceResourceServiceMock();
        }
    }

    // *********************************************
    // * DAOMock
    // *********************************************
    //private static final Schema.SObjectType SERVICE_RESOURCE_TYPE = Schema.ServiceResource.getSObjectType();
    public class ServiceResourceDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ServiceResource.IServiceResourceDAO {

        public Map<Id, ServiceResource> svcRes;
        public Boolean isSuccess = true;

        public ServiceResourceDAOMock()  {
            super( new Map<Id, ServiceResource>(), Schema.ServiceResource.getSObjectType());
            this.svcRes = (Map<Id, ServiceResource>)super.Records;
        }
        public List<ServiceResource> fetchServiceResource(FSL_ServiceResource.ServiceResourceWrapper servicewrp){
            return null;
        }

        public ServiceResource createServiceResource(FSL_ServiceResource.ServiceResourceWrapper servicewrp) { return null; } 

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ServiceResourceDAOMock' );
            }
        }
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ServiceResourceServiceMock implements FSL_ServiceResource.IServiceResourceService {
        public Boolean throwsException = false;
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ServiceResourceServiceMock' );
            }
        }

        public Integer saveWorkOrderCommentsCallCount = 0;
        public void saveWorkOrderComments(Map<Id, List<String>> comments) {
            ++saveWorkOrderCommentsCallCount;
            throwExceptionIfConfigured();
        }

        public ServiceResource checkAndCreateNewResource(FSL_ServiceResource.ServiceResourceWrapper servicewrp) { return null; }
        public List<ServiceResource> searchServiceResource(FSL_ServiceResource.ServiceResourceWrapper servicewrp) { return null; }      
    }
}