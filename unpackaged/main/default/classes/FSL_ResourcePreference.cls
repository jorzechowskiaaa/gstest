public with sharing class FSL_ResourcePreference {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IResourcePreferenceService createService();
    }

    public class Factory implements IFactory {
        public IResourcePreferenceService createService() {
            IResourcePreferenceDAO dao = createDAO();
            return new ResourcePreferenceService( dao );
        }

        private IResourcePreferenceDAO createDAO() {
            return new ResourcePreferenceDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IResourcePreferenceDAO extends FSL_DAO.DmlInterface {
    }

    public class ResourcePreferenceDAO extends FSL_DAO.DmlBase implements IResourcePreferenceDAO {
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IResourcePreferenceService {
        void deleteOldResourcePreferences( Integer daysToRetain, Integer maxRecords );
    }

    public class ResourcePreferenceService implements IResourcePreferenceService {
        private IResourcePreferenceDAO dao;

        public ResourcePreferenceService( IResourcePreferenceDAO dao ) {
            this.dao = dao;
        }

        public void deleteOldResourcePreferences( Integer daysToRetain, Integer maxRecords ) {
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
                [SELECT Id FROM ResourcePreference WHERE
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