public inherited sharing class FSL_OptimizationRequest {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IOptimizationRequestService createService();
    }

    public class Factory implements IFactory {
        public IOptimizationRequestService createService() {
            IOptimizationRequestDAO dao = createDAO();
            FSL_OptimizationData.IFactory optimizationDataFactory = new FSL_OptimizationData.Factory();
            return new OptimizationRequestService( dao, optimizationDataFactory.createService() );
        }

        private IOptimizationRequestDAO createDAO() {
            return new OptimizationRequestDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IOptimizationRequestDAO extends FSL_DAO.DmlInterface {
        List<FSL__Optimization_Request__c> getOptimizationRequestsOlderThanProvidedDate( Date createdDate );
    }
    
    public class OptimizationRequestDAO extends FSL_DAO.DmlBase implements IOptimizationRequestDAO {
        public List<FSL__Optimization_Request__c> getOptimizationRequestsOlderThanProvidedDate( Date createdDate ) {
            return [SELECT CreatedDate, FSL__Optimization_Data__c, Id 
                    FROM FSL__Optimization_Request__c 
                    WHERE CreatedDate < :createdDate
                    ORDER BY CreatedDate
                    LIMIT 10000];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IOptimizationRequestService {
        void onDelete( List<FSL__Optimization_Request__c> deletedRecords );
        void purgeOldRecords( Integer daysToRetain, Integer maxRecords );
    }

    public class OptimizationRequestService implements IOptimizationRequestService {
        private IOptimizationRequestDAO dao;
        private FSL_OptimizationData.IOptimizationDataService optimizationDataService;

        public OptimizationRequestService( IOptimizationRequestDAO dao, FSL_OptimizationData.IOptimizationDataService optimizationDataService ) {
            this.dao = dao;
            this.optimizationDataService = optimizationDataService;
        }

        public void onDelete( List<FSL__Optimization_Request__c> deletedRecords ) {
            deleteRelatedRecords( deletedRecords );
        }

        private void deleteRelatedRecords( List<FSL__Optimization_Request__c> deletedRecords ) {
            Set<Id> optimizationDataIds = new Set<Id>();
            for( FSL__Optimization_Request__c request : deletedRecords ) {
                if( request.FSL__Optimization_Data__c != null ) {
                    optimizationDataIds.add( request.FSL__Optimization_Data__c );
                }
            }
            if( optimizationDataIds.size() > 0 ) {
                optimizationDataService.deleteOptimizationData( optimizationDataIds );
            }
        }     

        public void purgeOldRecords( Integer daysToRetain, Integer maxRecords ) {
            FSL_QueryLocatorBatchable delegate = new FSL_QueryLocatorBatchable( new PurgeOldRecordBatchable( daysToRetain, maxRecords ) );
            Database.executeBatch(delegate);
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
            Date createdDate = Date.today().addDays( -daysToRetain );
            return Database.getQueryLocator( 
                [SELECT CreatedDate, FSL__Optimization_Data__c, Id 
                FROM FSL__Optimization_Request__c 
                WHERE CreatedDate < :createdDate
                ORDER BY CreatedDate
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