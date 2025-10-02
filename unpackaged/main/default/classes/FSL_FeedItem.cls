public without sharing class FSL_FeedItem {

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IFeedItemService createService();
    }

    public class Factory implements IFactory {
        public IFeedItemService createService() {
            IFeedItemDAO dao = createDAO();
            return new FeedItemService( dao );
        }

        private IFeedItemDAO createDAO() {
            return new FeedItemDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IFeedItemDAO extends FSL_DAO.DmlInterface {
        List<FeedItem> fetchFeedItemsForWorkOrders( Set<Id> workOrderIds );
    }

    public without sharing class FeedItemDAO extends FSL_DAO.DmlBase implements IFeedItemDAO {
        public List<FeedItem> fetchFeedItemsForWorkOrders( Set<Id> workOrderIds ) {
            List<FeedItem> feedItems = ( [SELECT Id, InsertedBy.Name, LastModifiedDate, ParentId, Type, Body 
                                            FROM FeedItem 
                                            WHERE ParentId IN :workOrderIds 
                                            AND Type = 'TextPost'] );
            return feedItems;
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IFeedItemService {
        Map<Id, List<FeedItem>> getWorkOrderIdToFeedItemsMap( Set<Id> workOrderIds );
    }

    public class FeedItemService implements IFeedItemService {
        private IFeedItemDAO dao;

        public FeedItemService( IFeedItemDAO dao ) {
            this.dao = dao;
        }

        public Map<Id, List<FeedItem>> getWorkOrderIdToFeedItemsMap( Set<Id> workOrderIds ) {
            Map<Id, List<FeedItem>> workOrderIdToFeedItemsMap = new Map<Id, List<FeedItem>>();
            List<FeedItem> feedItems = dao.fetchFeedItemsForWorkOrders( workOrderIds );

            for( FeedItem f : feedItems ) {
                if( workOrderIdToFeedItemsMap.containsKey( f.parentId ) ) {
                    workOrderIdToFeedItemsMap.get( f.parentId ).add( f );
                } else {
                    workOrderIdToFeedItemsMap.put( f.parentId, new List<FeedItem>{ f } );
                }
            }

            return workOrderIdToFeedItemsMap;
        }
    }
}