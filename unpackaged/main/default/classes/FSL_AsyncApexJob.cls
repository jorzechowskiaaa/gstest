public with sharing class FSL_AsyncApexJob {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IAsyncApexJobService createService();
    }

    public class Factory implements IFactory {
        public IAsyncApexJobService createService() {
            return new AsyncApexJobService( createDao() );
        }

        private IAsyncApexJobDAO createDao() {
            return new AsyncApexJobDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IAsyncApexJobDAO extends FSL_DAO.DmlInterface {
        List<AsyncApexJob> fetchJobs( Set<Id> ids );
    }
    
    public class AsyncApexJobDAO extends FSL_DAO.DmlBase implements IAsyncApexJobDAO {
        public List<AsyncApexJob> fetchJobs( Set<Id> ids ) {
            return 
                [SELECT ApexClassId, CompletedDate, CreatedById, CreatedDate, ExtendedStatus, Id, JobItemsProcessed, JobType, 
                        LastProcessed, LastProcessedOffset, MethodName, NumberOfErrors, ParentJobId, Status, TotalJobItems 
                FROM AsyncApexJob
                WHERE Id IN :ids];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IAsyncApexJobService {
        AsyncApexJob getJob( Id jobId );
    }

    public class AsyncApexJobService implements IAsyncApexJobService {
        private IAsyncApexJobDAO dao;

        public AsyncApexJobService( IAsyncApexJobDAO dao ) {
            this.dao = dao;
        }

        public AsyncApexJob getJob( Id jobId ) {
            AsyncApexJob job = null;
            List<AsyncApexJob> jobs = dao.fetchJobs( new Set<Id>{ jobId } );
            if( !jobs.isEmpty() ) job = jobs[0];
            return job;
        }
    }
}