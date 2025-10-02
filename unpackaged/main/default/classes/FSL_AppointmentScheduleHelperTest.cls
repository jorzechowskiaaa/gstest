/**
 * @File Name          : FSL_AppointmentScheduleHelperTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 03-10-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
 *       12/11/2020   Clement Shiu  ERS-220415 - Optimization helper refractoring
**/
@isTest
public class FSL_AppointmentScheduleHelperTest{
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }    
    
    @isTest
    static void shiftAppAbsResTest(){
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.StartTest();         
        List<WorkOrder> workOrderList = [Select Id, Resolution_Code__c, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
        for(workOrder wo : workOrderList){
            integer x = 2;
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now().addMinutes(x);
                sa.SchedEndTime = System.now().addMinutes(15+x);
                sa.actualstarttime = System.now().addminutes(x);
                sa.PTA__c = System.now().addminutes(300); 
                SAList.add(sa); 
                x = 20;
            }
            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            ARList.add(assignedResource);
        }
        
        update SAList;
        insert ARList;

        List<ResourceAbsence> deltedAbsences = new List<ResourceAbsence>();
        deltedAbsences.add(FSL_DataFactory.createResourceAbsence(ARList[0].ServiceResourceId, system.Now().addMinutes(5), system.Now().addMinutes(15)));
        deltedAbsences.add(FSL_DataFactory.createResourceAbsence(ARList[0].ServiceResourceId, system.Now().addMinutes(-10), system.Now().addMinutes(-1))); 
        
        insert deltedAbsences; 
                
        FSL_OptimizationHelper.shiftAppointments(deltedAbsences);
        System.Test.StopTest();
    }
    @isTest
    static void handleAddressChangeTravelTimeUpdatesTest(){

        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');        	
        Test.startTest(); 	     
        
        List<WorkOrder> workOrderList = [Select Id, Resolution_Code__c, (select id, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder];
  
        
        ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        system.debug('serviceResource 68'+ serviceResource);
        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();
		
        system.debug('workOrderList' +workOrderList);
        for(workOrder wo : workOrderList){
            integer x = 0;
            //System.debug('==sss===>>>>'+wo.ServiceAppointments);
            for(ServiceAppointment sa : wo.ServiceAppointments){
                sa.SchedStartTime = System.now().addMinutes(x);
                sa.SchedEndTime = System.now().addMinutes(15+x);
                sa.actualstarttime = System.now().addminutes(x);
                sa.PTA__c = System.now().addminutes(300); 
                sa.Address_Changed__c = true;
                SAList.add(sa); 
                x = 20;
            }
			
        system.debug('SA ID 83' +wo.ServiceAppointments[0].Id);            
            AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(wo.ServiceAppointments[0].Id, serviceResource.Id);
            ARList.add(assignedResource);
        }
     
        update SAList;
        insert ARList;    
       
        Set<ID> saAptIDs = new Set<ID>{SAList[0].Id, SAList[1].Id};
        Map<AssignedResource, Decimal> newScheduleDelta = new Map<AssignedResource, Decimal>();
        //newScheduleDelta.put(ARList[1], -10.0);
        newScheduleDelta.put(ARList[0], 10.0);
        

        try{
            //Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
            FSL_OptimizationHelper.handleAddressChangeTravelTimeUpdates(saAptIDs, newScheduleDelta);    
        }
        catch(Exception Ex){
             
        }
        Test.StopTest();

    }                  
}