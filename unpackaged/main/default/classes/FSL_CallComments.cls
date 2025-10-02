public with sharing class FSL_CallComments {

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ICallCommentsService createService();
    }

    public class Factory implements IFactory {
        public ICallCommentsService createService() {
            ICallCommentsDAO dao = createDAO();
            return new CalLCommentsService( dao );
        }

        private ICallCommentsDAO createDAO() {
            return new CallCommentsDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface ICallCommentsDAO extends FSL_DAO.DmlInterface {

    }

    public class CallCommentsDAO extends FSL_DAO.DmlBase implements  ICallCommentsDAO {

    }

    // *********************************************
    // * Service
    // *********************************************
    public interface ICallCommentsService {
        void saveWorkOrderComments(Map<Id, List<String>> workOrderComments);
    }

    public class CallCommentsService implements ICallCommentsService {

        private ICallCommentsDAO dao;

        public CallCommentsService( ICallCommentsDAO dao ) {
            this.dao = dao;
        }

        public void saveWorkOrderComments(Map<Id, List<String>> workOrderComments) {

            List<FSL_Call_Comments__c> allComments = new List<FSL_Call_Comments__c> ();
            List<String> comments;
            for ( Id woId : workOrderComments.keySet()) {
                comments = workOrderComments.get(woId);
                for ( String comment : comments) {
                    allComments.add (new FSL_Call_Comments__c(FSL_Work_Order__c = woId,  FSL_Comment__c = comment));
                }
            }
            dao.insertRecords(allComments);
        }
    }

}