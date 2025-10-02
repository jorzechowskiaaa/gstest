/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-09-2022
 * @last modified by  : Clement Shiu
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   06-07-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public class FSL_LastKnownLocationUtilityTest {
    
    @isTest
    static /*testMethod*/ void lastKnownLocationJobTest(){        
        System.Test.startTest();
        
        //Update EndTime to 11:59 pm
        String DayOfWeek = System.Now().format('EEEE');
        List<TimeSlot> tsList = [SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlot WHERE DayOfWeek = :DayOfWeek];
        
        for(TimeSlot ts : tsList){
            ts.EndTime = Time.newInstance(23, 59, 0, 0);          
        }
        update tsList;

        OperatingHours OPHR = [SELECT id FROM OperatingHours where name = '24/7 Eastern'];
        List<ServiceTerritoryMember> stmList = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceTerritoryId, TerritoryType FROM ServiceTerritoryMember]; 
        for(ServiceTerritoryMember stm : stmList){
            stm.OperatingHoursId = OPHR.Id;
        }
        System.Debug('ServiceTerritoryMember - ' + stmList[0]);       

        update stmList;
       

        list<Shift> shifts = new list<Shift>();
        list<ServiceResource> ServiceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 3];
        
        // Update SR with Lat Long info and idle flag
        ServiceResources[0].isActive = True;
        ServiceResources[0].Currently_Scheduled__c = True;
        ServiceResources[0].Idle__c = True;
        ServiceResources[0].LastKnownLatitude = 33.6953762;
        ServiceResources[0].LastKnownLongitude = -117.9100995;
        ServiceResources[0].LastKnownLocationDate = System.now().addMinutes(-15);

        ServiceResources[1].isActive = True;
        ServiceResources[1].Currently_Scheduled__c = True;
        ServiceResources[1].Idle__c = True;
        ServiceResources[1].LastKnownLatitude = 33.6953762;
        ServiceResources[1].LastKnownLongitude = -118.9100995;
        ServiceResources[1].LastKnownLocationDate = System.now().addMinutes(-60);    
        
        ServiceResources[2].isActive = True;
        ServiceResources[2].Currently_Scheduled__c = True;
        ServiceResources[2].Idle__c = True;   
        ServiceResources[1].LastKnownLatitude = 33.6953762;
        ServiceResources[1].LastKnownLongitude = -118.9100995;
        ServiceResources[1].LastKnownLocationDate = System.now().addMinutes(-15);   

        update ServiceResources;

        // Create Shift for SR 0 and 1
        shifts.addAll(FSL_DataFactory.CreateShift(ServiceResources[0].Primary_Service_Territory__c, ServiceResources[0].id));
        shifts.addAll(FSL_DataFactory.CreateShift(ServiceResources[1].Primary_Service_Territory__c, ServiceResources[1].id));
        insert shifts;        

        // Update TimeSlot
        //SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlots WHERE DayOfWeek = :strDay

        // Now create Resource Absence
        FSL_LastKnownLocationUtility.lastKnownLocationJob(ServiceResources);
        System.Test.stopTest();
    }
    
   
    @isTest
    static /*testMethod*/ void testGetIdleResources(){
        System.Test.startTest();
        list<ServiceResource> serviceResources = [select id from serviceResource];

        // Update SR with Lat Long info
        ServiceResources[0].isActive = True;
        ServiceResources[0].Currently_Scheduled__c = True;
        ServiceResources[0].Idle__c = True;
        ServiceResources[0].LastKnownLatitude = 33.6953762;
        ServiceResources[0].LastKnownLongitude = -117.9100995;
        ServiceResources[0].LastKnownLocationDate = System.now().addMinutes(-15);

        ServiceResources[1].isActive = True;
        ServiceResources[1].Currently_Scheduled__c = True;
        ServiceResources[1].Idle__c = False;   

        ServiceResources[2].isActive = True;
        ServiceResources[2].Currently_Scheduled__c = True;
        ServiceResources[2].Idle__c = True;
        ServiceResources[2].LastKnownLatitude = 33.6953762;
        ServiceResources[2].LastKnownLongitude = -118.9100995;
        ServiceResources[2].LastKnownLocationDate = System.now().addMinutes(-60);
        
        update ServiceResources;

        
        List<ServiceResource> idleResources = FSL_LastKnownLocationUtility.getIdleResources(new Set<ID>{serviceResources[0].ID, serviceResources[1].ID, serviceResources[2].ID}, new Set<ID>{serviceResources[1].ID});
        System.assertEquals(1, idleResources.size());
     
        // Comment out those old code here
        //list<OperatingHours> OpHrs = [select id from OperatingHours]; 
        //FSL_LastKnownLocationUtility.addHoursToSet(OpHrs, new set<Id>());

        System.Test.stopTest();
    }
    
    @isTest
    static /*testMethod*/ void SchedulerTest(){
        delete [select id from Technology_Preference__c];

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(False)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');

        FSL_LastKnownLocationSchedule sqrb10 = new FSL_LastKnownLocationSchedule();
        String sch10 = '0 50 * * * ?';
        system.schedule('Every Hour plus min', sch10, sqrb10);
        Test.stopTest();
    }
    
    @isTest
    static /*testMethod*/ void testGetActiveShifts(){
        list<Shift> shifts = new list<Shift>();
        list<ServiceResource> ServiceResources = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHours.TimeZone from serviceresource where ResourceType='T' limit 2];
        for(ServiceResource sr : ServiceResources){
            List<Shift> shiftList = FSL_DataFactory.CreateShift(sr.Primary_Service_Territory__c, sr.id);
            shifts.addAll(shiftList);
            
            Integer currentUserOffset = UserInfo.getTimeZone().getOffset(System.now());
            Integer servTerOpHoutsOffset = Timezone.getTimeZone(sr.Primary_Service_Territory__r.OperatingHours.TimeZone).getOffset(System.now());
            Integer offSetSeconds = (currentUserOffset - servTerOpHoutsOffset) / 1000;

            for (Shift shift : shiftList) {
                shift.StartTime = shift.StartTime.addSeconds(-offSetSeconds);
                shift.EndTime = shift.EndTime.addSeconds(-offSetSeconds);
            }
        }      
        insert shifts;      
        
        System.Test.startTest();
        FSL_LastKnownLocationUtility.ShiftLKL shiftTest = new FSL_LastKnownLocationUtility.ShiftLKL(ServiceResources, new Set<Id>());

        // new ShiftHandler();   
           
        // Set<Shift> shiftSet = shiftTest.getActiveShifts(DateTime.now());         
        Set<Shift> shiftSet = shiftTest.addAllActiveShifts();    

        System.assertEquals(2,shiftSet.size());

        System.Test.stopTest();

    }
    
    @isTest
    static /*testMethod*/ void testGetActiveAppointmentsWithResources(){
        
       
                 FSL_Service_Endpoints__c endpoint = new FSL_Service_Endpoints__c(); //// Added this custom setting as required for makePostCallout method.
        endpoint.Endpoint_URL__c ='org_id=81511&foreign_id=';
        endpoint.client_id__c = '1qe4s3snv71lu6j301urnvblgv';
        endpoint.Client_Secret__c = 'ku4ufh1ig5corgjjbbk1chmbkknk6ke3e9sqj2im2o0p9qlkhr9';
        endpoint.Client_Cert_Name__c = 'ace_fsl_uat';
        endpoint.Timeout__c = 20000;
        endpoint.Named_Credential__c = 'OAuth';
        endpoint.Name='OAuth';
        insert endpoint;
            
        // Create a WorkOrder and assign it to the SR        
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');     
         
        Test.startTest();   
      Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));   
        // Create Shifts Test Data
        list<ServiceResource> serviceResources = createShifts(False);       

        // Update WO Resource
        WorkOrder woTest = [SELECT Id, Service_Resource__c FROM WorkOrder Limit 1 ]; 
        woTest.Service_Resource__c = serviceResources[0].Id;
        update woTest;        

        // First Update the SA Service Resource
        List<WorkOrder> workOrderList = [SELECT Id, (select id, Status, SchedStartTime, SchedEndTime, ActualStartTime, PTA__c FROM ServiceAppointments) FROM WorkOrder];        
        list<ServiceAppointment> SAList = new list<ServiceAppointment>();
        list<AssignedResource> ARList = new list<AssignedResource>();        
        Id SAId;

        for(workOrder wo : workOrderList){
            for(ServiceAppointment sa : wo.ServiceAppointments){  
                SAId = sa.Id;      
                sa.SchedStartTime = System.now();
                sa.SchedEndTime = System.now()+1800;
                sa.ActualStartTime = System.now();
                sa.PTA__c = System.now();        
                SAList.add(sa); 
                
                // Assign it to the 1st SR
                AssignedResource assignedResource = FSL_DataFactory.createAssignedResource(SAId, serviceResources[0].Id);
                // assignedResource.EstimatedTravelTime = 120.00;
                ARList.add(assignedResource);
            }
        }        
        update SAList;   
        // When Assinged Resource is created, the SA will automatically changed to 'Scheduled' Status, so will WO.Status = Scheduled
        insert ARList;      
        System.Test.stopTest();
        
        FSL_LastKnownLocationUtility.ShiftLKL shiftTest = new FSL_LastKnownLocationUtility.ShiftLKL(serviceResources, new Set<Id>());
        DateTime currentDateTime = DateTime.now();

        // Add all the active shifts                
        // shiftTest.addAllActiveShifts(currentDateTime);
        shiftTest.addAllActiveShifts();
         
        //Get Active Appointments             
        Map<Id,List<ServiceAppointment>> activeAppts = shiftTest.getActiveAppointmentsWithResources(currentDateTime);

        System.assertEquals(1,activeAppts.size());

    }

    @isTest
    static /*testMethod*/ void testGetActiveResourcesWithCurrentSchedule(){

        // Create Shifts Test Data
        list<ServiceResource> serviceResources = createShifts(False);        
        
        System.Test.startTest();
        FSL_LastKnownLocationUtility.ShiftLKL shiftTest = new FSL_LastKnownLocationUtility.ShiftLKL(serviceResources, new Set<Id>());
        DateTime currentDateTime = DateTime.now();

        // Add all the active shifts                
        // shiftTest.addAllActiveShifts(currentDateTime);
        shiftTest.addAllActiveShifts();
        
        // new ShiftHandler();      
        Set<Id> activeResourceSet = shiftTest.getActiveResourcesWithCurrentSchedule();        
        System.assertEquals(1,activeResourceSet.size());

        System.Test.stopTest();

    }
    
    @isTest
    static /*testMethod*/ void testGetActiveShiftsResources(){

        
        // Create Shifts Test Data
        list<ServiceResource> serviceResources = createShifts(False);

        System.Test.startTest();
        FSL_LastKnownLocationUtility.ShiftLKL shiftTest = new FSL_LastKnownLocationUtility.ShiftLKL(serviceResources, new Set<Id>());
        DateTime currentDateTime = DateTime.now();

        // Add all the active shifts                
        // shiftTest.addAllActiveShifts(currentDateTime);
        shiftTest.addAllActiveShifts();
        
        // new ShiftHandler();      
        Map<Id,ServiceResource> activeResourceMap = shiftTest.GetActiveShiftsResources();    

        System.assertEquals(2,activeResourceMap.size());

        System.Test.stopTest();

    }

    static list<ServiceResource> createShifts(Boolean setToIdle){

        // Update Service Resource active and on schedule values
        list<ServiceResource> ServiceResources = [SELECT id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHours.TimeZone,Idle__c,LastKnownLatitude, LastKnownLongitude, LastKnownLocationDate,
                                                         ServiceResource.isActive, ServiceResource.Currently_Scheduled__c
                                                  FROM serviceresource WHERE ResourceType='T' limit 2];

        ServiceResources[0].isActive = True;
        ServiceResources[0].Currently_Scheduled__c = True;
        if(setToIdle){
            ServiceResources[0].Idle__c = True;
            ServiceResources[0].LastKnownLatitude = 33.6953762;
            ServiceResources[0].LastKnownLongitude = -117.9100995;
            ServiceResources[0].LastKnownLocationDate = System.now().addMinutes(-15);
        }
        update ServiceResources;
                
        list<Shift> shifts = new list<Shift>();
        for(ServiceResource sr : ServiceResources){
            // shifts.addAll(FSL_DataFactory.CreateShift(sr.Primary_Service_Territory__c, sr.id));

            List<Shift> shiftList = FSL_DataFactory.CreateShift(sr.Primary_Service_Territory__c, sr.id);
            shifts.addAll(shiftList);
            
            Integer currentUserOffset = UserInfo.getTimeZone().getOffset(System.now());
            Integer servTerOpHoutsOffset = Timezone.getTimeZone(sr.Primary_Service_Territory__r.OperatingHours.TimeZone).getOffset(System.now());
            Integer offSetSeconds = (currentUserOffset - servTerOpHoutsOffset) / 1000;

            for (Shift shift : shiftList) {
                shift.StartTime = shift.StartTime.addSeconds(-offSetSeconds);
                shift.EndTime = shift.EndTime.addSeconds(-offSetSeconds);
            }
        }
        insert shifts;
        
        return ServiceResources;
        
    }

    @isTest
    static /*testMethod*/ void testCreateAbsencesFromOptimizationHelper(){

        System.Test.startTest();

        // Set the Stale Time in Min        
        // List<FSL_LKL_Configuration__mdt> lklConfig = FSL_DataFactory.FSL_LKL_Configuration_NonStaleIdleResourceMdt();

        // Create Shifts Test Data
        list<ServiceResource> serviceResources = createShifts(True);
        
        // Get the idle resource id
        Set<ID> idleResources = new Set<ID>();
        idleResources.add(serviceResources[0].Id);

        // Create an Absence with a specific LastKnownLocationDate
        FSL_LastKnownLocationUtility.createAbsences(idleResources, System.now());

        // Since it is a Database.executeBatch call, we are doing code coverage test here
        // List<ResourceAbsence> raList = [SELECT Id FROM ResourceAbsence];
        // System.assertEquals(raList[0].Id, serviceResources[0].Id);

        System.Test.stopTest();
    }

    @isTest
    static /*testMethod*/ void testGetIdleShiftResources(){

        System.Test.startTest();

        // Create Shifts Test Data
        list<ServiceResource> serviceResources = createShifts(True);

        Datetime currentDateTime = DateTime.now();
        FSL_LastKnownLocationUtility.ShiftLKL shiftTest = new FSL_LastKnownLocationUtility.ShiftLKL(serviceResources, new Set<Id>());        
        // shiftTest.addAllActiveShifts(currentDateTime);                
        shiftTest.addAllActiveShifts();                

        // Get the list of Shifts with idle resources         
        List<ServiceResource> idleResources = shiftTest.getIdleShiftResources(currentDateTime, new Map<Id, ServiceResource>());

        System.assertEquals(1,idleResources.size());

        System.Test.stopTest();
    }

    @isTest
    static /*testMethod*/ void testUpdateSROnScheduleFlagForRegOperHrs(){

        list<FSL_Optimization_Settings__c> osettings = [SELECT Id, Run_LKL__c, Run_Shifts__c, Create_ResourceAbsence_In_Trigger__c FROM FSL_Optimization_Settings__c ];
        // Make sure Shifts Flag is turned off
        osettings[0].Run_Shifts__c = false;        
        update osettings;

        OperatingHours OPHR = [SELECT Id, Timezone FROM OperatingHours where name = '24/7 Eastern'];
        //Update EndTime to 11:59 pm
        String DayOfWeek = System.Now().format('EEEE', OPHR.Timezone);
        List<TimeSlot> tsList = [SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlot WHERE DayOfWeek = :DayOfWeek];
         
        for(TimeSlot ts : tsList){
            ts.EndTime = Time.newInstance(23, 59, 0, 0);          
        }
        update tsList;
 
        // OperatingHours OPHR = [SELECT id FROM OperatingHours where name = '24/7 Eastern'];
        List<ServiceTerritoryMember> stmList = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceTerritoryId, TerritoryType FROM ServiceTerritoryMember WHERE TerritoryType = 'P']; 
        for(ServiceTerritoryMember stm : stmList){
            stm.OperatingHoursId = OPHR.Id;
        }
        update stmList;
         
        //list<Shift> shifts = new list<Shift>();
        list<ServiceResource> ServiceResources = [select id, Currently_Scheduled__c FROM serviceresource where ResourceType='T' limit 1];

        // Update SR with Lat Long info
        ServiceResources[0].isActive = True;
        ServiceResources[0].Currently_Scheduled__c = false;
        ServiceResources[0].Idle__c = True;
        ServiceResources[0].LastKnownLatitude = 33.6953762;
        ServiceResources[0].LastKnownLongitude = -117.9100995;
        ServiceResources[0].LastKnownLocationDate = System.now().addMinutes(-15);

        update ServiceResources;

        System.Test.startTest();

        // Run the routine to update the SR's On Schedule Flag
        FSL_LastKnownLocationUtility.updateSROnScheduleFlag(ServiceResources);
        System.Test.stopTest();

        serviceResources = [SELECT Currently_Scheduled__c FROM serviceResource WHERE id =: ServiceResources[0].Id];
        System.assertEquals(true, serviceResources[0].Currently_Scheduled__c);                   
    }

    @isTest
    static /*testMethod*/ void testUpdateSROnScheduleFlagWithShifts(){

        list<FSL_Optimization_Settings__c> osettings = [SELECT Id, Run_LKL__c, Run_Shifts__c, Create_ResourceAbsence_In_Trigger__c FROM FSL_Optimization_Settings__c ];
        // Make sure Shifts Flag is turned on
        osettings[0].Run_Shifts__c = true;        
        update osettings;

        //Update EndTime to 11:59 pm
        String DayOfWeek = System.Now().format('EEEE');
        List<TimeSlot> tsList = [SELECT StartTime, DayOfWeek, EndTime, OperatingHoursId FROM TimeSlot WHERE DayOfWeek = :DayOfWeek];
         
        for(TimeSlot ts : tsList){
            ts.EndTime = Time.newInstance(23, 59, 0, 0);          
        }
        update tsList;
 
        OperatingHours OPHR = [SELECT id FROM OperatingHours where name = '24/7 Eastern'];
        List<ServiceTerritoryMember> stmList = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceTerritoryId, TerritoryType FROM ServiceTerritoryMember WHERE TerritoryType = 'P']; 
        for(ServiceTerritoryMember stm : stmList){
            stm.OperatingHoursId = OPHR.Id;
        }
        update stmList;
         
        // Create Shifts Test Data
        createShifts(True);

        //list<Shift> shifts = new list<Shift>();
        // Update SR 1 to be off Work
        list<ServiceResource> ServiceResources = [select id, Currently_Scheduled__c FROM serviceresource where ResourceType='T' limit 1];
        ServiceResources[0].Currently_Scheduled__c = false;
        update ServiceResources;

        System.Test.startTest();

        // Run the routine to update the SR's On Schedule Flag
        FSL_LastKnownLocationUtility.updateSROnScheduleFlag(ServiceResources);

        System.Test.stopTest();
        
        serviceResources = [SELECT Currently_Scheduled__c FROM serviceResource WHERE id =: ServiceResources[0].Id];
        System.assertEquals(true, serviceResources[0].Currently_Scheduled__c);
           
       
    }

    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }    
}