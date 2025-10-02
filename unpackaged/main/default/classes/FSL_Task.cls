public with sharing class FSL_Task {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ITaskService createService();
    }

    public class Factory implements IFactory {
        public ITaskService createService() {
            ITaskDAO dao = createDAO();
            return new TaskService( dao );
        }

        private ITaskDAO createDAO() {
            return new TaskDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface ITaskDAO extends FSL_DAO.DmlInterface {
    }

    public class TaskDAO extends FSL_DAO.DmlBase implements ITaskDAO {
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface ITaskService {
        void deleteOldTasks( Integer daysToRetain, Integer maxRecords );
    }

    public class TaskService implements ITaskService {
        private ITaskDAO dao;

        public TaskService( ITaskDAO dao ) {
            this.dao = dao;
        }

        public void deleteOldTasks( Integer daysToRetain, Integer maxRecords ) {
            FSL_QueryLocatorBatchable delegate = new FSL_QueryLocatorBatchable( new PurgeOldRecordBatchable( daysToRetain, maxRecords ) );
            Database.executeBatch( delegate );
        }
    }
  
    // *********************************************
    // * Batchable Implementation
    // *********************************************
    private class PurgeOldRecordBatchable implements FSL_QueryLocatorBatchable.IBatchable {
        private Integer daysToRetain;
        private Integer maxRecords;

        public PurgeOldRecordBatchable( Integer daysToRetain, Integer maxRecords ) {
            this.daysToRetain = daysToRetain;
            this.maxRecords = maxRecords;
        }

        public Database.QueryLocator start( Database.BatchableContext context ) {
            Date createdDate = System.now().dateGmt().addDays( -daysToRetain );
            return Database.getQueryLocator(
                [SELECT Id FROM Task WHERE
                CreatedDate < :createdDate
                LIMIT :maxRecords] );
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            if( items.size() > 0 ) {
                delete items;
            }
        }
    
        public void finish( Database.BatchableContext context ) {
        }
    }
}