/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 08-05-2021
 * @last modified by  : Clement Shiu
**/
public class FSL_SchedulingPolicy {   

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ISchedulingPolicyService createService();        
    }

    public class Factory implements IFactory {
        public ISchedulingPolicyService createService() {
            ISchedulingPolicyDAO dao = createDAO();
             return new SchedulingPolicyService( dao );
        }

        private ISchedulingPolicyDAO createDAO() {
             return new SchedulingPolicyDAO();
        }
    }
     
    // *********************************************
    // * DAO
    // *********************************************
    public interface ISchedulingPolicyDAO extends FSL_DAO.DmlInterface {         
        List<FSL__Scheduling_Policy__c> fetchSchedulingPolicy( String masterLabel );
    }

    public class SchedulingPolicyDAO extends FSL_DAO.DmlBase implements ISchedulingPolicyDAO {        

        public List<FSL__Scheduling_Policy__c> fetchSchedulingPolicy( String SchedPolicyName ) {
        return [SELECT Id, Name 
                FROM FSL__Scheduling_Policy__c 
                WHERE Name = :SchedPolicyName];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface ISchedulingPolicyService {        
        FSL__Scheduling_Policy__c getSchedulingPolicy(string SchedPolicyName);       
    }

    public class SchedulingPolicyService implements ISchedulingPolicyService {
        private ISchedulingPolicyDAO dao;          
        public SchedulingPolicyService( ISchedulingPolicyDAO dao ) {
            this.dao = dao;
        }
               
        // Get the Scheduling Policy for the Specific Policy Name
        public FSL__Scheduling_Policy__c getSchedulingPolicy(string SchedPolicyName){

            FSL__Scheduling_Policy__c schedPolicy = null;
             
            List<FSL__Scheduling_Policy__c> SPList = dao.fetchSchedulingPolicy(SchedPolicyName);
            if(!SPList.isEmpty() ) schedPolicy = SPList[0];

            return schedPolicy;
        }       
    }

}