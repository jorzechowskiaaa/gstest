/**
* @File Name          : FSL_ResourceOptimizationUtilityTest.cls
* @Description        : 
* @Author             : Rajesh Kemisetti
* @Group              : 
* @Last Modified By   : Clement Shiu
* @Last Modified On   : 11-09-2021
* @Modification Log   : 
* Ver       Date            Author                  Modification
* 1.0    4/6/2020    Rajesh Kemisetti     Initial Version
*        11/25/2020  Clement Shiu - ERS-220022 Check to see if Optimization is Already Running before Attempting to run Again  
**/
@isTest
public class FSL_ResourceOptimizationUtilityTest {
    static ServiceResource serviceResource;
    static FSL__Scheduling_Policy__c schedulingPolicy;
    static FSL_Application_Log__c appLog = new FSL_Application_Log__c();
    
        
    static testmethod void resourceOptimizationUtilityTest(){
        FSL_ResourceOptimizationUtility resOpt = new FSL_ResourceOptimizationUtility();
        FSL_ResourceOptimizationUtility resOpt1 = new FSL_ResourceOptimizationUtility(Datetime.newInstance(2019, 5, 28, 1, 6, 8), 2);
    }
    
  static testmethod void optimizeScheduleGapsTest(){
                
        serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1];
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');

        System.Test.startTest();
        list<ServiceAppointment> salist = [select id, PTA__c, appointmentnumber, Service_Resource__c, actualstarttime, SchedStartTime, SchedEndTime, ParentRecordId,ETA__c, work_order__c,status,recordtype.name,ServiceTerritoryid  from ServiceAppointment];
        list<AssignedResource> ARs = new list<AssignedResource>();
        for(ServiceAppointment sa : salist){
            sa.SchedStartTime = System.now();
            sa.SchedEndTime = System.now()+1800;
            sa.actualstarttime = System.now();
            sa.PTA__c = System.now();
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(sa.Id, serviceResource.Id);
            ARs.add(assignedResource);
        }
        update salist;
        insert ARs;
        insert appLog;
        
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        
        FSL_ResourceOptimizationUtility resOpt = new FSL_ResourceOptimizationUtility();
        resOpt.optimizeScheduleGaps(serviceResource.Id, schedulingPolicy.Id);
        resOpt.optimizeScheduleGaps(serviceResource.Id, null);
        resOpt.optimizeScheduleOverlaps(serviceResource.id, appLog.id);
        
        FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper serApptWrapper = new FSL_ResourceOptimizationUtility.ServiceAppointmentWrapper(salist[0], 2, 4);
        List<resourceAbsence> RAList = new List<resourceAbsence>();
        RAList.addAll(FSL_DataFactory.CreateResourceAbsences('LKL')); 
        
        FSL_OptimizationHelper.bulkFixOverlaps(RAList);
        FSL_OptimizationHelper.bulkFixOverlaps(salist);       
        FSL_OptimizationHelper.didCallCreateOverlap(serApptWrapper, salist[0], RAList[0]);
        FSL_OptimizationHelper.didCallCreateOverlap(serApptWrapper, null, RAList[0]);
        List<Id> lstTId = new List<Id>();
        for(ServiceTerritory serTer: [select id from ServiceTerritory limit 2]){
            lstTId.add(serTer.Id);
        }        
        
        FSL_ResourceOptimizationUtility.callInDay(lstTId);
        FSL_OptimizationHelper.callInDayWithPrimarySeconderyTerritories(lstTId, appLog.id);
        
        System.Test.stopTest();
    }
    
    public  static testmethod void callRSOTest(){
        Datetime horizonStart;
        Datetime horizonEnd;
        List<ResourceAbsence> Ralist = FSL_DataFactory.CreateResourceAbsences('LKL');       
        serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        schedulingPolicy = [select id from FSL__Scheduling_Policy__c limit 1];
        insert appLog;
        FSL_ResourceOptimizationUtility.callRSO(serviceResource.id, schedulingPolicy.Id, horizonStart, horizonEnd, true, true, 25, new Set<ID>(), new Set<ID> (), 30, appLog.Id);        
    }

    // ERS-220022 Check to see if Optimization is Already Running before Attempting to run Again      
    public  static testmethod void removeSerTerWithPendingOptimizationTest(){
     
        // Insert a list of Service Territories into the FSL__Territory_Optimization_Request__c table
        // Call IDO with a list of ST containing one of the pending IDO ST
        Test.startTest();

        // Retrieve 3 Service Territories 
        List<ServiceTerritory> serviceTerritories = [SELECT id FROM ServiceTerritory Limit 3];  

        // create OR
        List<FSL__Optimization_Request__c> optRequests = new List<FSL__Optimization_Request__c>();
        // Create the first OR
        FSL__Optimization_Request__c optRequest1 = new FSL__Optimization_Request__c();
        optRequest1.FSL__Status__c = 'In Progress';
        optRequest1.FSL__Type__c = 'In Day Optimization';
        optRequests.add(optRequest1);

        // Create the Second OR
        FSL__Optimization_Request__c optRequest2 = new FSL__Optimization_Request__c();
        optRequest2.FSL__Status__c = 'In Progress';
        optRequest2.FSL__Type__c = 'In Day Optimization';
        optRequests.add(optRequest2);

         // Create the Third OR
         FSL__Optimization_Request__c optRequest3 = new FSL__Optimization_Request__c();
         optRequest3.FSL__Status__c = 'Open';
         optRequest3.FSL__Type__c = 'In Day Optimization';
         optRequests.add(optRequest3); 

        insert optRequests;
                                     
        // Create 3 FSL__Territory_Optimization_Request__c
        List<FSL__Territory_Optimization_Request__c> terOpt3 = new List<FSL__Territory_Optimization_Request__c>();
        List<FSL__Territory_Optimization_Request__c> terOpt2 = new List<FSL__Territory_Optimization_Request__c>();
        
        // FSL__Optimization_Request__r.FSL__Status__c NOT IN ('Failed','Completed','Completed First Optimization Day') AND FSL__Optimization_Request__r.FSL__Type__c='In Day Optimization' AND createddate = LAST_N_DAYS:2];

        for (ServiceTerritory st : serviceTerritories) {
            FSL__Territory_Optimization_Request__c terOptTemp = new FSL__Territory_Optimization_Request__c();
            terOptTemp.FSL__ServiceTerritory__c = st.Id;            
            
            switch on terOpt3.size() {
                when 0 {
                    terOptTemp.FSL__Optimization_Request__c = optRequest1.Id;
                    terOpt2.add(terOptTemp);   
                }	
                when 1 {
                    terOptTemp.FSL__Optimization_Request__c = optRequest2.Id;
                    terOpt2.add(terOptTemp);   
                }
                when 2 {
                    terOptTemp.FSL__Optimization_Request__c = optRequest3.Id;
                }           
                when else {
                    // Do not do anything                    
                }     
            }                        
            terOpt3.add(terOptTemp);      
        }

        // Initially, insert only 2 records into the FSL__Optimization_Request__c table
        insert terOpt2;

        // Make sure we have 2 records here
        system.assertEquals(2, terOpt2.size(), 'Failed to created 2 Territory Optimization Records');
        system.assertEquals(3, terOpt3.size(), 'Failed to created 3 Territory Optimization Records');

        // Prepare the list of Territory Ids to be optimized - 3 entries        
        List<String> terIdsFullList = new List<String>();        
        for(FSL__Territory_Optimization_Request__c optReq: terOpt3){                 
            terIdsFullList.add(optReq.FSL__ServiceTerritory__c);
        }      
        
        // Make sure we have 3 records that are sending to be optimized
        system.assertEquals(3, terIdsFullList.size());       

        // Now call the actual function that we are trying to unit test
        List<Id> filteredTIds  = FSL_ResourceOptimizationUtility.removeSerTerWithPendingOptimization(terIdsFullList);
        
        // Make sure we have 1 records that are going to be optimized, since 2 records are already in the table
        system.assertEquals(1, filteredTIds.size());             

        Test.stopTest();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
}