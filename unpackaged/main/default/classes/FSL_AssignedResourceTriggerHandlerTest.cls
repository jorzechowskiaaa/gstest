/**
 * @File Name          : FSL_AssignedResourceTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 11-09-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_AssignedResourceTriggerHandlerTest {

    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }

    //@isTest
    static /*testMethod*/ void arUpdateDeleteTest() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');

        System.Test.StartTest();

        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder limit 3];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(ServiceAppointment sa:[select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointment]){
            sa.SchedStartTime = System.now();
            sa.SchedEndTime = System.now()+1800;
            sa.actualstarttime = System.now();
            sa.PTA__c = System.now();
            SAList.add(sa); 
        }
        update SAList;
        for(workOrder wo : workOrderList){
          /*  wo.ServiceAppointments[0].SchedStartTime = System.now();
            wo.ServiceAppointments[0].SchedEndTime = System.now()+1800;
            wo.ServiceAppointments[0].actualstarttime = System.now();
            wo.ServiceAppointments[0].PTA__c = System.now();
            SAList.add(wo.ServiceAppointments[0]); */
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResources[0].Id);
            assignedResource.EstimatedTravelTime = 10.00;
            ARList.add(assignedResource);
        }
       // updateUser( serviceResources[0].ID,true);
       // update SAList;
        insert ARList;
        
		// ServiceResource sr=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        // FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(new List<ServiceResource>{sr});
        // ServiceResource sr2=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        // system.assertEquals(sr2.idle__c,false);
        // sr2.idle__c=true;
       	// update sr2;
        // FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(new List<ServiceResource>{sr2});
        //  sr2.idle__c=true;
       	// update sr2;
        // Map<Id,AssignedResource> ARMap=new Map<Id,AssignedResource>([Select id,ServiceResource.Idle__c,ServiceResource.RelatedRecord.Isactive from AssignedResource]);
        // FSL_IdleResourceUtility.removeIdleIndicatorOnAssignedResources(ARMap);
        // ServiceResource sr3=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        // system.assertEquals(sr3.idle__c,false);
        ARList[0].ServiceResourceId = serviceResources[1].ID;
        update ARList;

        SAList[0].status='Spotted';
        update SAList[0];
        System.Test.StopTest();
    } 
    
    @isTest
    static /*testMethod*/ void arUpdateInActiveTest() {
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');

        System.Test.StartTest();

        List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder limit 3];
        list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(ServiceAppointment sa:[select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointment]){
            sa.SchedStartTime = System.now();
            sa.SchedEndTime = System.now()+1800;
            sa.actualstarttime = System.now();
            sa.PTA__c = System.now();
            SAList.add(sa); 
        }
        update SAList;
        for(workOrder wo : workOrderList){
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResources[0].Id);
            assignedResource.EstimatedTravelTime = 10.00;
            ARList.add(assignedResource);
        }
        insert ARList;
        //  ServiceResource sr=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        //  FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(new List<ServiceResource>{sr});
        //  ServiceResource sr2=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        //  system.assertEquals(sr2.idle__c,false);
        //  sr2.idle__c=true;
        //  update sr2;
        //  FSL_IdleResourceUtility.evaluateIdleIndicatorOnResources(new List<ServiceResource>{sr2});
        //  sr2.idle__c=true;
        //  update sr2;
        //  Map<Id,AssignedResource> ARMap=new Map<Id,AssignedResource>([Select id,ServiceResource.Idle__c,ServiceResource.RelatedRecord.Isactive from AssignedResource]);
        //  updateUser( serviceResources[0].ID,false);
        //  System.Test.StopTest();
        //  FSL_IdleResourceUtility.removeIdleIndicatorOnAssignedResources(ARMap);
        //  ServiceResource sr3=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        //  system.assertEquals(sr3.idle__c,true);
    }
    
    // static testMethod void arUpdateRowLockTest(){
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
    //     FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     System.Test.StartTest();
    //     List<WorkOrder> workOrderList = [Select Id, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder limit 3];
    //     list<ServiceResource> serviceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' ];
    //     list<ServiceAppointment> SAList = new list<ServiceAppointment>();
    //     list<AssignedResource> ARList = new list<AssignedResource>();
    //     for(ServiceAppointment sa:[select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointment]){
    //         sa.SchedStartTime = System.now();
    //         sa.SchedEndTime = System.now()+1800;
    //         sa.actualstarttime = System.now();
    //         sa.PTA__c = System.now();
    //         SAList.add(sa); 
    //     }
    //     update SAList;
    //     for(workOrder wo : workOrderList){
    //         AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResources[0].Id);
    //         assignedResource.EstimatedTravelTime = 10.00;
    //         ARList.add(assignedResource);
    //     }
    //     insert ARList;
        // ServiceResource sr=[select id,idle__c,RelatedRecord.Isactive from serviceresource where id =: serviceResources[0].Id];
        // FSL_IdleResourceUtility.runRowLock=true;
        // FSL_IdleResourceUtility.updateServiceResources(new List<ServiceResource>{sr});
        // FSL_IdleResourceUtility.runRowLock=false;
    //     System.Test.StopTest();
    // }

    @future
    public static void updateUser(Id resourceId,Boolean isactive) {
        User user=[select id,isactive from user where id in (select RelatedRecordId from ServiceResource where id=:resourceId) Limit 1];
        user.isactive=isactive;
        update user;
    }
}