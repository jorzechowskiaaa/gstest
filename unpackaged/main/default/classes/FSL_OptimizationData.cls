public inherited sharing class FSL_OptimizationData {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IOptimizationDataService createService();
    }

    public class Factory implements IFactory {
        public IOptimizationDataService createService() {
            IOptimizationDataDAO dao = createDAO();
            return new OptimizationDataService( dao );
        }

        private IOptimizationDataDAO createDAO() {
            return new OptimizationDataDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IOptimizationDataDAO extends FSL_DAO.DmlInterface {
        List<FSL__Optimization_Data__c> getOptimizationDataForId( Set<Id> ids );
    }
    
    public class OptimizationDataDAO extends FSL_DAO.DmlBase implements IOptimizationDataDAO {
        public List<FSL__Optimization_Data__c> getOptimizationDataForId( Set<Id> ids ) {
            return [SELECT Id 
                    FROM FSL__Optimization_Data__c 
                    WHERE Id IN :ids];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IOptimizationDataService {
        void deleteOptimizationData( Set<Id> ids );
    }

    public class OptimizationDataService implements IOptimizationDataService {
        private IOptimizationDataDAO dao;

        public OptimizationDataService( IOptimizationDataDAO dao ) {
            this.dao = dao;
        }

        public void deleteOptimizationData( Set<Id> ids ) {
            List<FSL__Optimization_Data__c> datas = dao.getOptimizationDataForId( ids );
            if( datas.size() > 0 ) {
                dao.deleteRecords( datas );
            }
        }
    }
}