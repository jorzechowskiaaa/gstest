/**
 * @File Name          : FSL_MilestoneTimeCalculatorTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/16/2020, 4:02:45 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
Public class FSL_MilestoneTimeCalculatorTest{


    //  ***    Service Tech Team: Test class body is commented out as target class is retired   ***


    
    // private static User user = new User();
    
    // @testSetup
    // public static void dataSetup() {
    //     FSL_DataFactoryUtility.userSetupwithStaticData();
    // }
    
    // static testmethod void MileStoneTimeCalculatortest(){  

    //     FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        
    //     Test.startTest();

    //     List<WorkOrder> workOrderList = [Select Id, Resolution_Code__c, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
    //     ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
    //     list<ServiceAppointment> SAList = new list<ServiceAppointment>();
    //     list<AssignedResource> ARList = new list<AssignedResource>();
    //     for(workOrder wo : workOrderList){
    //         integer x = 0;
    //         for(ServiceAppointment sa : wo.ServiceAppointments){
    //             sa.SchedStartTime = System.now().addMinutes(x);
    //             sa.SchedEndTime = System.now().addMinutes(15+x);
    //             sa.actualstarttime = System.now().addminutes(x);
    //             sa.PTA__c = System.now().addminutes(300); 
    //             SAList.add(sa); 
    //             x = 20;
    //         }
            
    //         AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
    //         ARList.add(assignedResource);
    //     }
        
    //     update SAList;
    //     insert ARList;
        
    //     list<MilestoneType> mts = [select Id, name from MilestoneTYpe where name IN ('En Route Violation','In Tow Violation', 'Tow Complete Violation')];
	// 	system.debug('mts:'+mts);
    //     list<FSL_Milestone_Time_Trigger__c> mtts = [select Time_Trigger_Minutes__c, name, milestone_name__c from FSL_Milestone_Time_Trigger__c order by milestone_name__c asc];
    //     system.debug('mtts:'+mtts);

    //     workOrderList[0].Status = 'En Route';
    //     update workOrderList[0];

    //     FSL_MilestoneTimeCalculator calculator2 = new FSL_MilestoneTimeCalculator ();
    //     Integer actualTriggerTime = calculator2.calculateMilestoneTriggerTime(workOrderList[0].Id, mts[0].Id);
    //     system.assert(actualTriggerTime>0);
        
    //     workOrderList[0].Status = 'In Tow';
    //     update workOrderList[0]; 

    //     actualTriggerTime = calculator2.calculateMilestoneTriggerTime(workOrderList[0].Id, mts[1].Id);
	// 	system.assert(actualTriggerTime>0);
        
    //     workOrderList[0].Status = 'Tow Complete';
    //     update workOrderList[0]; 

    //     actualTriggerTime = calculator2.calculateMilestoneTriggerTime(workOrderList[0].Id, mts[1].Id);
    //     system.assert(actualTriggerTime>0);
        
    //     workOrderList[0].Resolution_Code__c = 'X002';
    //     update workOrderList[0]; 

        
        
    //     // Create case data.
    //     // Typically, the milestone type is related to the case, 
    //     // but for simplicity, the case is created separately for this test.
    //     // Case c = new Case(priority = 'High');
    //     // insert c;

          

    //     Test.StopTest();     
    // }
}