public with sharing class FSL_Group {
    
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IGroupService createService();
    }

    public class Factory implements IFactory {
        public IGroupService createService() {
            IGroupDAO dao = createDAO();
            return new GroupService( dao );
        }

        private IGroupDAO createDAO() {
            return new GroupDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IGroupDAO extends FSL_DAO.DmlInterface {
        List<Group> fetchGroup( String groupType, String developerName );
    }

    public class GroupDAO extends FSL_DAO.DmlBase implements IGroupDAO {
        public List<Group> fetchGroup( String groupType, String developerName ) {
            List<Group> groups = 
                [SELECT Id, Name, DeveloperName, Email, Type 
                FROM Group 
                WHERE Type = :groupType 
                AND DeveloperName = :developerName];
            return groups;
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IGroupService {
        Group getGroupForClearQueueCaseOwnership();
        Group getGroupForLandLineCallCanceled();
        Group getGroupForQueueName(string queuename);
    }

    public class GroupService implements IGroupService {
        private IGroupDAO dao;

        public GroupService( IGroupDAO dao ) {
            this.dao = dao;
        }

        public Group getGroupForClearQueueCaseOwnership() {
            List<Group> groups = dao.fetchGroup( 'Queue', 'Clear_Queue' );
            if( groups.size() == 0 ) {
                System.debug( LoggingLevel.ERROR, 'FSL_Group.GroupService.getGroupForClearQueueCaseOwnership: Failed to query a Group!' );
                throw new QueryException( 'FSL_Group.GroupService.getGroupForClearQueueCaseOwnership: Failed to query a Group!' );
            }
            else if( groups.size() > 1 ) {
                System.debug( LoggingLevel.WARN, 'FSL_Group.GroupService.getGroupForClearQueueCaseOwnership: Multiple groups fetched. Using first item only' );
            }
            return groups[0];
        }


        public Group getGroupForLandLineCallCanceled() {
            List<Group> groups = dao.fetchGroup( 'Queue', 'Non_Technology_Queue' );
            if( groups.size() == 0 ) {
                System.debug( LoggingLevel.ERROR, 'FSL_Group.GroupService.getGroupForLandLineCallCanceled: Failed to query a Group!' );
                throw new QueryException( 'FSL_Group.GroupService.getGroupForLandLineCallCanceled: Failed to query a Group!' );
            }
            else if( groups.size() > 1 ) {
                System.debug( LoggingLevel.WARN, 'FSL_Group.GroupService.getGroupForLandLineCallCanceled: Multiple groups fetched. Using first item only' );
            }
            return groups[0];
        }

        public Group getGroupForQueueName(string queuename) {
            List<Group> groups = dao.fetchGroup( 'Queue', queuename );
            if( groups.size() == 0 ) {
                throw new QueryException( 'FSL_Group.GroupService.getGroupForQueueName: Failed to query a Group!' );
            }
            else if( groups.size() > 1 ) {
                System.debug( LoggingLevel.WARN, 'FSL_Group.GroupService.getGroupForQueueName: Multiple groups fetched. Using first item only' );
            }
            return groups[0];
        }
        

    }
}