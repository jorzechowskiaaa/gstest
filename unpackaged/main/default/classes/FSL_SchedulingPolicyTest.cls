/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 07-28-2021
 * @last modified by  : Clement Shiu
**/
@isTest
public with sharing class FSL_SchedulingPolicyTest {
    public FSL_SchedulingPolicyTest() {

    }

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_SchedulingPolicy.IFactory factory = new FSL_SchedulingPolicy.Factory();

        Test.startTest();
        FSL_SchedulingPolicy.ISchedulingPolicyService service = factory.createService();
        
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    @IsTest
    public static void testSchedulingPolicyDAO_fetchSchedulingPolicy_CorrectRecordsReturned() {       
        
        FSL_SchedulingPolicy.ISchedulingPolicyDAO dao =  new FSL_SchedulingPolicy.SchedulingPolicyDAO();                        
        String SchedPolicyName = 'Automated Reroute Policy';
        FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);        
        insert schedPolicy;

        Test.startTest();       
        List<FSL__Scheduling_Policy__c> schedPolicies = dao.fetchSchedulingPolicy(SchedPolicyName);
        Test.stopTest();

        System.assertEquals( 1, schedPolicies.size() );       
    }

    private static FSL__Scheduling_Policy__c createPolicy(string policyName) {
        if(policyName == null)
            return null;

        FSL__Scheduling_Policy__c p = new FSL__Scheduling_Policy__c();     
        p.Name = policyName;        

        return p;
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_SchedulingPolicy.IFactory {
        public FSL_SchedulingPolicy.ISchedulingPolicyService createService() {
            return new SchedulingPolicyeMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FSL_SchedulingPolicy.IFactory factory = new FactoryMock();

        Test.startTest();
        FSL_SchedulingPolicy.ISchedulingPolicyService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class SchedulingPolicyeMock implements FSL_SchedulingPolicy.ISchedulingPolicyService {
        
        public FSL__Scheduling_Policy__c getSchedulingPolicy(string SchedPolicyName){
            FSL__Scheduling_Policy__c schedPolicy = createPolicy(SchedPolicyName);   
            return schedPolicy;
        }
    }
}