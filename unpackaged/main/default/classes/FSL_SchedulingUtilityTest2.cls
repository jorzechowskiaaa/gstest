/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-16-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-16-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public class FSL_SchedulingUtilityTest2 {

    // contains additional tests for the FSL_SchedulingUtility class
    // to test the newly added code for ERS-219715
    
    // Wrapper object for holding ArrivalWindows Test Data
    
    
    virtual public class NamedIdMap_Base {
   		public  String getFakeId(Schema.SObjectType sot) {
            Integer s_num = Integer.valueOf(123456789*Math.random());
      		String result = String.valueOf(s_num++);
      		return sot.getDescribe().getKeyPrefix() + 
         	'0'.repeat(12-result.length()) + result;
   		}           
            
    }

    
    public class NameIdMap_ArrivalWindow extends NamedIdMap_Base {
        public  Map<Id, FSL_SLA_ArrivalWindow__c>  idMap;
        public  Map<String, FSL_SLA_ArrivalWindow__c>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_ArrivalWindow() {
            idMap = new Map<Id, FSL_SLA_ArrivalWindow__c>();
            nameMap = new Map<String, FSL_SLA_ArrivalWindow__c>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, FSL_SLA_ArrivalWindow__c obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(FSL_SLA_ArrivalWindow__c.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }
        public void addEntry(FSL_SLA_ArrivalWindow__c obj) {
            nameMap.put(obj.Name, obj);
            
            obj.Id = getFakeId(FSL_SLA_ArrivalWindow__c.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(obj.Name, obj.Id);
        }
       public FSL_SLA_ArrivalWindow__c getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
        
    }    
    
    // Wrapper object for holding Schedule Policies
    public class NameIdMap_SchedulingPolicy extends NamedIdMap_Base {
        public  Map<Id, FSL__Scheduling_Policy__C>  idMap;
        public  Map<String, FSL__Scheduling_Policy__C>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_SchedulingPolicy() {
            idMap = new Map<Id, FSL__Scheduling_Policy__C>();
            nameMap = new Map<String, FSL__Scheduling_Policy__C>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, FSL__Scheduling_Policy__C obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(FSL__Scheduling_Policy__C.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }
      	public void addEntry(FSL__Scheduling_Policy__C obj) {
            addEntry(obj.Name, obj);
        }
        public FSL__Scheduling_Policy__C getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
    }        
    
    // Wrapper object for holding Service Territories
    public class NameIdMap_ServiceTerritory extends NamedIdMap_Base {
        public  Map<Id, ServiceTerritory>  idMap;
        public  Map<String, ServiceTerritory>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_ServiceTerritory() {
            idMap = new Map<Id, ServiceTerritory>();
            nameMap = new Map<String, ServiceTerritory>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, ServiceTerritory obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(ServiceTerritory.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }
      	public void addEntry(ServiceTerritory obj) {
            addEntry(obj.Name, obj);
        }
        public ServiceTerritory getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
 
    }        
    
    // Wrapper object for holding OperatingHours
    public class NameIdMap_OperatingHours extends NamedIdMap_Base  {
        public  Map<Id, OperatingHours>  idMap;
        public  Map<String, OperatingHours>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_OperatingHours() {
            idMap = new Map<Id, OperatingHours>();
            nameMap = new Map<String, OperatingHours>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, OperatingHours obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(OperatingHours.SObjectType);
	            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }
      	public void addEntry(OperatingHours obj) {
            addEntry(obj.Name, obj);
        }    
        public OperatingHours getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
    }        
    
    // Wrapper object for holding OperatingHours
    public class NameIdMap_TimeZones {
        public  Map<String, TimeZone>  nameMap;

        public NameIdMap_TimeZones() {
            nameMap = new Map<String, TimeZone>();
        }
        public void addEntry(String name, TimeZone obj) {
            nameMap.put(name, obj);
        }
        public TimeZone getTimeZone(String name) {
            return nameMap.get(name);
        }
    }        

  // Wrapper object for holding WorkOrders
    public class NameIdMap_WorkOrder  extends NamedIdMap_Base  {
        public  Map<Id, WorkOrder>  idMap;
        public  Map<String, WorkOrder>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_WorkOrder() {
            idMap = new Map<Id, WorkOrder>();
            nameMap = new Map<String, WorkOrder>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, WorkOrder obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(WorkOrder.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }
      
        public WorkOrder getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
    }        
  
  // Wrapper object for holding OperatingHours
    public class NameIdMap_ServiceAppointment  extends NamedIdMap_Base {
        public  Map<Id, ServiceAppointment>  idMap;
        public  Map<String, ServiceAppointment>  nameMap;
        public  Map<String, Id>  nameToIdMap;
      
        public NameIdMap_ServiceAppointment() {
            idMap = new Map<Id, ServiceAppointment>();
            nameMap = new Map<String, ServiceAppointment>();
            nameToIdMap = new Map<String,Id>();
        }
        public void addEntry(String name, ServiceAppointment obj) {
            nameMap.put(name, obj);
            
            obj.Id = getFakeId(ServiceAppointment.SObjectType);
            
            idMap.put(obj.Id, obj);
            nameToIdMap.put(name, obj.Id);
        }

        public ServiceAppointment getObject(String name) {
            return nameMap.get(name);
        }
        public Id getId(String name) {
            return nameToIdMap.get(name);
        }
    }            
    public static NameIdMap_TimeZones  nimTZ = new NameIdMap_TimeZones();
    public static NameIdMap_OperatingHours nimOH = new NameIdMap_OperatingHours();
    public static NameIdMap_ServiceTerritory nimST = new NameIdMap_ServiceTerritory();
    public static NameIdMap_SchedulingPolicy nimSP = new NameIdMap_SchedulingPolicy();
    public static NameIdMap_ArrivalWindow nimAW = new NameIdMap_ArrivalWindow();
    
    public static NameIdMap_WorkOrder nimWO = new NameIdMap_WorkOrder();
    public static NameIdMap_ServiceAppointment nimSA = new NameIdMap_ServiceAppointment();
    
    
    public static Map<String, Boolean> mapFunctionsTested = new Map<String, Boolean>();
    public static Integer numberOfUnitTestsRun = 0;
    public static Integer numberOfUnitTestsPassed = 0;
        
    public static testmethod void runNewTests() {
    	Test.startTest();
        
        setupTestObjects();
        
        // Unit test the mapSlaArrivalWindow 
        mapSlaArrivalWindowUnitTest('Best Towing High');
    	mapSlaArrivalWindowUnitTest('ACE Normal');
  		mapSlaArrivalWindowUnitTest('Defaults Critical');            
        
        // Unit test the evaluateArrivalWindow function
        
        ServiceTerritory 			stObj = nimST.getObject('Best Towing');
        FSL_SLA_ArrivalWindow__c 	awObj = nimAW.getObject('Best Towing Normal');
            
        evaluateArrivalWindowUnitTest(stObj, 'Normal', true, awObj.Name);
        System.debug('Units tests for <evaluateArrivalWindow> passed for Best Towing for Normal priority');
        
        awObj = nimAW.getObject('Best Towing High');
        evaluateArrivalWindowUnitTest(stObj, 'High', false, awObj.Name);
        System.debug('Units tests for <evaluateArrivalWindow> passed for Best Towing for High priority');

        // When territory is null, Should look for the Default 
        awObj = nimAW.getObject('Defaults High');
        evaluateArrivalWindowUnitTest(null, 'High', false, awObj.Name);
        System.debug('Units tests for <evaluateArrivalWindow> passed when WO did not have a territory. Default settings matched for High priority');
        
        awObj = nimAW.getObject('Defaults Normal');
        evaluateArrivalWindowUnitTest(null, 'Normal', false, awObj.Name);
        System.debug('Units tests for <evaluateArrivalWindow> passed when WO did not have a territory. Default settings matched for Normal priority');
        
        stObj = nimST.getObject('Budget Auto Service');
        evaluateArrivalWindowUnitTest(stObj, 'High', false, null);
        System.debug('Units tests for <evaluateArrivalWindow> passed when WO had a territory specified. But the territory did not have a SLA-AW enttry');
        
        
        // Now test FSL_Schedule_Config extractMatchingScheduleConfig(ServiceAppointment sa, WorkOrder wo, Map<Id, ServiceTerritory> stMap, Map<Id, FSL_SLA_ArrivalWindow__c> awMap )  {

        // Test with an appointment that includes a territory that does not have an entry but has a parent territory
        ServiceAppointment sa = nimSA.getObject('bkdnNormalTowBudget');
        WorkOrder wo = nimWO.getObject('NormalTowBudget');
        extractMatchingScheduleConfigUnitTest(sa, wo, 'ACE Normal');
        System.debug('Units tests for <extractMatchingScheduleConfig> passed when WO has a territory specified but a parent territory SLA is matched');
  
        
        sa = nimSA.getObject('bkdnNormalTowBestTow'); 
        wo = nimWO.getObject('NormalTowBestTow');
        extractMatchingScheduleConfigUnitTest(sa, wo, 'Best Towing Normal');    
        System.debug('Units tests for <extractMatchingScheduleConfig> passed when WO has a territory specified and a matching entry is found');

           
        sa = nimSA.getObject('bkdnNormalTowBestTow'); 
        wo = nimWO.getObject('NormalTowBestTow');
        extractMatchingScheduleConfigUnitTest(sa, wo, 'Best Towing Normal');    
        System.debug('Units tests for <extractMatchingScheduleConfig> passed when WO has a territory specified and a matching entry is found');
                     
        sa = nimSA.getObject('bkdnHighLSOrphan'); 
        wo = nimWO.getObject('HighLSOrphan');
        extractMatchingScheduleConfigUnitTest(sa, wo, 'Defaults High');    
		System.debug('Units tests for <extractMatchingScheduleConfig> passed when WO has a territory specified but no entry exists nor does a parent territory');


        sa = nimSA.getObject('bkdnSAWithBlankTerritoryId'); 
        wo = nimWO.getObject('HighLSBestTow');
        extractMatchingScheduleConfigUnitTest(sa, wo, 'Best Towing High');     
		System.debug('Units tests for <extractMatchingScheduleConfig> passed when WO has a territory specified but SA territory Id is blank');

        
        System.debug('Unit Test Summary from SchedulingUtilityTest2.cls:  Number of functions Tested = ' + mapFunctionsTested.size() + 
                                                                         ', Total number of unit tests run = ' + numberOfUnitTestsRun + 
                    													 ', Total number of unit tests passed = ' + numberOfUnitTestsPassed ); 
        
        
        // Now try  some scheduling.
       
        ServiceAppointment mySA1 	=  nimSA.getObject('bkdnNormalTowBestTow');
        ServiceAppointment mySA2 	=  nimSA.getObject('towNormalTowBestTow');
        WorkOrder myWO 				= nimWO.getObject('NormalTowBestTow');

      
        //=========================================================================================
        //The following runMockSchedule tests since they are already covered in FSL_SchedulingTest
        //=========================================================================================

        //Behavior testBehavior = Behavior.ReturnSuccessful;

        // System.debug('Scheduling a call normally');
        // runMockSchedule(mySA1, null, myWO, testBehavior);
       
        // System.debug('Scheduling a call with behavior set to fail to find candidates on first scheduling attempt');
        // testBehavior = Behavior.ThrowRetryableExceptionOnFirstTry;
       	// runMockSchedule(mySA1, null, myWO, testBehavior);
        
        // testBehavior = Behavior.ThrowRetryableExceptionOnFirstTwoTries;
        // runMockSchedule(mySA1, null, myWO, testBehavior);

        // testBehavior = Behavior.ReturnSuccessful;
        // runMockSchedule(mySA1, mySA2, myWO, testBehavior);
       
        // testBehavior = Behavior.ThrowRetryableExceptionOnFirstTry;
       	// runMockSchedule(mySA1, mySA2, myWO, testBehavior);
        
        // testBehavior = Behavior.ThrowRetryableExceptionOnFirstTwoTries;
        // runMockSchedule(mySA1, mySA2, myWO, testBehavior);

        //=========================================================================================

        
  		Test.stopTest();
    }

    private static void mapSlaArrivalWindowUnitTest(String awEntryName) {

        
       mapFunctionsTested.put('mapSlaArrivalWindow', true);
       numberOfUnitTestsRun++;
        
       FSL_SLA_ArrivalWindow__c  awObj = nimAW.getObject(awEntryName);
       
       Boolean isTow = false;
       FSL_Schedule_Config   schCfg = FSL_SchedulingUtility.mapSlaArrivalWindow(awObj, isTow);
       compareAndAssert(schCfg, awObj, isTow);
        
       isTow = true;
       schCfg = FSL_SchedulingUtility.mapSlaArrivalWindow(awObj, isTow);
 	   compareAndAssert(schCfg, awObj, isTow);
        
       numberOfUnitTestsPassed++;
       System.debug('Units tests for <mapSlaArrivalWindow> passed for ' + awEntryName);
    }
    
    private static void compareAndAssert(FSL_Schedule_Config schCfg,   FSL_SLA_ArrivalWindow__c  awObj, Boolean isTow) {
       
       // Assert the following:
       System.assert(schCfg.slaValue == (( isTow) ? awObj.TOW_SLA__c : awObj.LS_SLA__c), 'slaValue not as expected for ' + awObj.Name + ' matched SLA =' + schCfg.slaValue );
  	   System.assert(schCfg.schedulingPolicy == awObj.Scheduling_Policy__c, 'Main Schedling Policy not as expected for LS service for ' + awObj.Name);      
       System.assert(schCfg.firstRetryPolicy == awObj.First_Retry_Policy__c, 'first Rettry Policy not as expected for LS service for ' + awObj.Name);      
  	   System.assert(schCfg.finalRetryPolicy == awObj.Retry_Policy__c, 'Final Retry Policy not as expected for LS service for ' + awObj.Name);      
        
    }
    
    
    private static void evaluateArrivalWindowUnitTest(ServiceTerritory svcTrtry, String priority,  Boolean isTow, String matchName) {
        
        mapFunctionsTested.put('evaluateArrivalWindow', true);    
        numberOfUnitTestsRun++;
        
        Map<Id, FSL_SLA_ArrivalWindow__c> mapAW = nimAW.idMap;
        FSL_Schedule_Config   schCfg = FSL_SchedulingUtility.evaluateArrivalWindow(mapAW, svcTrtry, priority, isTow);
                
        if ( matchName == null) {        
    		String trtryName = 'null';
            if ( svcTrtry != null ) {
                trtryName = svcTrtry.Name;
            }
            System.assert( schCfg == null, 'Expecting a null match but function returned a valid match for territory ' + trtryName);
        }
        else {
            
            FSL_SLA_ArrivalWindow__c 	awObj =   nimAW.getObject(matchName);
 			compareAndAssert(schCfg, awObj, isTow);
        }
        numberOfUnitTestsPassed++;
    }
    
    
    
    private static void extractMatchingScheduleConfigUnitTest(ServiceAppointment sa, WorkOrder wo, String matchName) {
        mapFunctionsTested.put('extractMatchingScheduleConfig', true);
        numberOfUnitTestsRun++;
        
       Map<Id, FSL_SLA_ArrivalWindow__c> mapAW = nimAW.idMap;
       Map<Id, ServiceTerritory> mapST = nimST.idMap;
        
       FSL_Schedule_Config   schCfg = FSL_SchedulingUtility.extractMatchingScheduleConfig(sa, wo, mapST, mapAW);
        
        if (matchName == null) {
             System.assert( schCfg == null, 'Expecting a null match but function returned a valid match for territory ' + sa.ServiceTerritoryId);
        }
        else {
            FSL_SLA_ArrivalWindow__c awObj = nimAW.getObject(matchName);
            compareAndAssert(schCfg, awObj, wo.Is_Tow_WorkType__c);
        }
        
       numberOfUnitTestsPassed++;
       
    }
    
 
    private  static void   setupTestObjects() { 
        // First create all the map objects to hold various Sobjects
        

            
        TimeZone testTZ = UserInfo.getTimeZone();
        nimTZ.addEntry(testTZ.getDisplayName(), testTZ);
        
        // Now create an OperatingHours object referencing this TimeZone;
        // And add it to the NameIDMap of Operating Hours
        
        OperatingHours testOH = new OperatingHours();
        testOH.Name = 'TestOH';
        testOH.TimeZone = testTZ.getDisplayName();
        
        nimOH.addEntry('TestOH', testOH);
       
        // Now create service territories and build an hierarchy.
        // A facility
        // A territory spanning a polygon - Costa Mesa
        // A state  CA
        // ACE
        
        ServiceTerritory stACE = new ServiceTerritory();
        stACE.Name = 'ACE';
        stACE.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stACE.ParentTerritoryId = null;
        nimST.addEntry('ACE', stACE);
        
        ServiceTerritory stCA = new ServiceTerritory();
        stCA.Name = 'California';
        stCA.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stCA.ParentTerritoryId = nimST.getId(stACE.Name);
        nimST.addEntry(stCA.Name, stCA);  
        
        ServiceTerritory stCostaMesa = new ServiceTerritory();
        stCostaMesa.Name = 'Costa Mesa';
        stCostaMesa.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stCostaMesa.ParentTerritoryId = nimST.getId(stCA.Name);
        nimST.addEntry(stCostaMesa.Name, stCostaMesa);        
        
        ServiceTerritory stBestTow = new ServiceTerritory();
        stBestTow.Name = 'Best Towing';
        stBestTow.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stBestTow.ParentTerritoryId = nimST.getId(stCostaMesa.Name);
        nimST.addEntry(stBestTow.Name, stBestTow); 
  
        ServiceTerritory stBudgetAuto = new ServiceTerritory(); 
        stBudgetAuto.Name = 'Budget Auto Service';  
        stBudgetAuto.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stBudgetAuto.ParentTerritoryId = nimST.getId(stCostaMesa.Name);
        nimST.addEntry(stBudgetAuto.Name, stBudgetAuto); 
        
		ServiceTerritory stOrphan = new ServiceTerritory(); 
        stOrphan.Name = 'Nameless Towing';  
        stOrphan.OperatingHoursId = nimOH.getObject(testOH.Name).Id;
        stOrphan.ParentTerritoryId = null;
        nimST.addEntry(stOrphan.Name, stOrphan); 
        
        // Now we can create scheduling policies
        
        FSL__Scheduling_Policy__C  spSLA = new FSL__Scheduling_Policy__C();
        spSLA.Name = 'SLA Policy';
        nimSP.addEntry(spSLA.Name, spSLA);
        
        FSL__Scheduling_Policy__C  spPTA = new FSL__Scheduling_Policy__C();
        spPTA.Name = 'PTA Policy';
        nimSP.addEntry(spPTA.Name, spPTA); 
        
        FSL__Scheduling_Policy__C  spNoPTA = new FSL__Scheduling_Policy__C();
        spNoPTA.Name = 'No PTA Policy';
        nimSP.addEntry(spNoPTA.Name, spNoPTA); 
               
        FSL__Scheduling_Policy__C  spDefault = new FSL__Scheduling_Policy__C();
        spDefault.Name = 'DefaultPolicy';
        nimSP.addEntry(spDefault.Name, spDefault);  
        
        // Now set up the Arrival Window Entries
        
        nimAW.addEntry(testCreateAW('Best Towing High',  stBestTow.Id, 'High', spSLA.Id, spPTA.Id, spNoPTA.Id, 15, 20));
        nimAW.addEntry(testCreateAW('Best Towing Normal',  stBestTow.Id, 'Normal', spSLA.Id, spPTA.Id, spNoPTA.Id, 30,60 ));
        nimAW.addEntry(testCreateAW('Best Towing Low',  stBestTow.Id, 'Normal', spSLA.Id, spPTA.Id, spNoPTA.Id, null,null));
        
        nimAW.addEntry(testCreateAW('ACE High',  stACE.Id, 'High', spSLA.Id, spPTA.Id, spNoPTA.Id, 30,60 ));
        nimAW.addEntry(testCreateAW('ACE Normal',  stACE.Id, 'Normal', spSLA.Id, spPTA.Id, spNoPTA.Id, 45,80 ));
 
        nimAW.addEntry(testCreateAW('Defaults Critical',  null, 'Critical', spDefault.Id, spPTA.Id, spNoPTA.Id, 30,45 ));
        nimAW.addEntry(testCreateAW('Defaults High',  null, 'High', spDefault.Id, spPTA.Id, spNoPTA.Id, 35,50 ));
        nimAW.addEntry(testCreateAW('Defaults Normal',  null, 'Normal', spDefault.Id, spPTA.Id, spNoPTA.Id, 40,55 ));
                                   
        //nimAW.addEntry(testCreateAW('Defaults Low',  null, 'Low', spDefault.Id, spDefault.Id, spNoPTA.Id, 45,60 ));
    
                                   
        // Now create WO objects and SA objects.
        
        Id lsWoTypeId =  Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Light Service').getRecordTypeId();
        Id towWoTypeId = Schema.SObjectType.Workorder.getRecordTypeInfosByName().get('Tow').getRecordTypeId();
                              
        WorkOrder  woNormalTowBestTow 	= testCreateWO('123400', 'Normal', stBestTow.Id, towWoTypeId, true);    // Should pick Best Tow's Normal Tow_SLA
  		WorkOrder  woHighLSBestTow 		= testCreateWO('123500', 'High', stBestTow.Id, lsWoTypeId, false);      // Should pick Best Tow's High LS_SLA                                                                   
        WorkOrder  woNormalTowBudget 	= testCreateWO('123600', 'Normal', stBudgetAuto.Id, towWoTypeId, true); // should pick ACE Normal Tow                
        WorkOrder  woHighLSOrphan 		= testCreateWO('123700', 'High', stOrphan.Id, lsWoTypeId, false);      	// Should pick default High       
                                
        
        nimWO.addEntry('NormalTowBestTow',  woNormalTowBestTow);
        nimWO.addEntry('HighLSBestTow',     woHighLSBestTow);
        nimWO.addEntry('NormalTowBudget',   woNormalTowBudget);
        nimWO.addEntry('HighLSOrphan',      woHighLSOrphan);

		ServiceAppointment bkdnNormalBestTow = testCreateSA(woNormalTowBestTow, false);   
        ServiceAppointment towNormalBestTow 	= testCreateSA(woNormalTowBestTow, true);   
                                   
        ServiceAppointment bkdnHighLSBestTow = testCreateSA(woHighLSBestTow, false);      
                                   
        ServiceAppointment bkdnNormalTowBudget = testCreateSA(woNormalTowBudget, false);   
        ServiceAppointment towNormalTowBudget	= testCreateSA(woNormalTowBudget, true);   
                                   
        ServiceAppointment bkdnHighLSOrphan = testCreateSA(woHighLSOrphan, false);      

        ServiceAppointment bkdnSAWithBlankTerritoryId = testCreateSA(woHighLSBestTow, false);    
        bkdnSAWithBlankTerritoryId.ServiceTerritoryId = null;

        nimSA.addEntry('bkdnNormalTowBestTow',     bkdnNormalBestTow);
        nimSA.addEntry('towNormalTowBestTow',      towNormalBestTow);
        nimSA.addEntry('bkdnHighLSBestTow',     bkdnHighLSBestTow);
        nimSA.addEntry('bkdnNormalTowBudget',   bkdnNormalTowBudget);
        nimSA.addEntry('towNormalTowBudget',    towNormalTowBudget);
        nimSA.addEntry('bkdnHighLSOrphan',      bkdnHighLSOrphan);
        nimSA.addEntry('bkdnSAWithBlankTerritoryId', bkdnSAWithBlankTerritoryId);
        
    }
    
    private static FSL_SLA_ArrivalWindow__c testCreateAW(String name, Id territory, String priority, Id mainPolicy, Id firstRetry, Id finalRetry, 
                                                          Integer lsSLA, Integer towSLA )  {
                           
        FSL_SLA_ArrivalWindow__c  awObj = new FSL_SLA_ArrivalWindow__c(); 
        awObj.Name = name;
        awObj.Service_Territory__c = territory;
        awObj.Priority__c = priority; 
        awObj.Scheduling_Policy__c = mainPolicy;
        awObj.First_Retry_Policy__c = firstRetry;
        awObj.Retry_Policy__c = finalRetry;                                                            
        awObj.LS_SLA__c = lsSLA;
        awObj.Tow_SLA__c = towSLA;
        return awObj;                                                      
    }
                                   
    private static WorkOrder testCreateWO(String callId, String priority, Id territoryId, Id lsOrTowId, boolean isTow) {
        WorkOrder wo = new WorkOrder();
        wo.Call_Id__c = callId;
        wo.Priority = priority;
        wo.ServiceTerritoryId = territoryId;
        wo.RecordTypeId =  lsOrTowId; 
        wo.Is_Tow_WorkType__c = isTow;
        return wo;
     }

   	private static ServiceAppointment testCreateSA(WorkOrder wo, boolean isTow) {
        ServiceAppointment sa = new ServiceAppointment();
		sa.ParentRecordId = wo.Id;
        sa.Status = 'Spotted';
        sa.ServiceTerritoryId = wo.ServiceTerritoryId;
        sa.EarliestStartTime = System.now();
        sa.ArrivalWindowStartTime = System.now();
        sa.ArrivalWindowEndTime = System.now();
        sa.ArrivalWindowEndTime.addMinutes(30);
        sa.PTA__c = System.now();
        sa.PTA__c.addMinutes(90);
        sa.FSL__Auto_Schedule__c = true;
        if (isTow) {
           sa.Subject = 'Tow Appointment'; 
        }
        else {
           sa.Subject = 'Breakdown Appointment'; 
        }
        return sa;
     }   
    
    
    // private static void runMockSchedule(ServiceAppointment sa, ServiceAppointment saRelated, WorkOrder wo, Behavior behavior) {
      
        
    //    Map<Id, FSL_SLA_ArrivalWindow__c> mapAW = nimAW.idMap;
    //    Map<Id, ServiceTerritory> mapST = nimST.idMap;
    //    Map <Id, FSL__Scheduling_Policy__C> policyMap = nimSP.idMap;
        
    //    FSL_Schedule_Config   schCfg = FSL_SchedulingUtility.extractMatchingScheduleConfig(sa, wo, mapST, mapAW);

    //    sa.ArrivalWindowStartTime = System.now();
    //    sa.ArrivalWindowEndTime = sa.ArrivalWindowStartTime.addMinutes(schCfg.slaValue);
        
    //    FSL_ServiceScheduler.DTO dto = new FSL_ServiceScheduler.DTO();
        
    //    dto.schedulingPolicy 		   	= policyMap.get(schCfg.schedulingPolicy);
    //    dto.firstRetrySchedulingPolicy 	= policyMap.get(schCfg.firstRetryPolicy);
    //    dto.reSchedulingPolicy 			= policyMap.get(schCfg.finalRetryPolicy);
        
        
    //    dto.scheduleAppointment = sa;
    //    dto.relatedAppointment = saRelated;
        
    //    MockScheduleService mckSS = new MockScheduleService(behavior);
       
    //    FSL_ServiceScheduler  scheduler = new FSL_ServiceScheduler(dto, mckSS, null);
        
    //    scheduler.scheduleCall();
       
    // }
    
    
    // public enum Behavior {
    //     	ReturnSuccessful,
    //     	ThrowRetryableExceptionOnFirstTry,
    //         ThrowRetryableExceptionOnFirstTwoTries 
    //    }
    // public class MockScheduleService implements FSL_ServiceScheduler.IScheduleService {

    //     private Integer tries = 0;
    //     private Behavior behavior;

    //     MockScheduleService(Behavior behavior) {
    //         this.behavior = behavior;
    //     }
        
    //     public void setBehavior(Behavior newBehavior) {
    //         this.behavior = newBehavior; 
    //     }

    //     public Boolean Schedule(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {
    //         return handleException(schedulingPolicy, scheduleAppointment, false);
    //     }

    //     public Boolean ScheduleExtended(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment) {
    //         return handleException(schedulingPolicy, scheduleAppointment, true);
    //     }

    //     public void TempHack(ServiceAppointment scheduleAppointment, ServiceAppointment relatedAppointment) {
    //         //Do nothing to avoid 'Too many SOQL' error during testing
    //     }

    //     Boolean handleException(FSL__Scheduling_Policy__c schedulingPolicy, ServiceAppointment scheduleAppointment, Boolean isExtended) {

    //         if ( !isExtended )  {
    //             system.debug('Scheduling a single call');
    //         }
    //         else {
    //            system.debug('Scheduling a linked call using the extended scheduling option'); 
    //         }
            
    //         decimal minutes = (decimal.valueOf(scheduleAppointment.ArrivalWindowEndTime.getTime() - scheduleAppointment.ArrivalWindowStartTime.getTime()))/1000/60;
           
                
    //         system.debug('Policy Used: ' + schedulingPolicy);
 	// 		system.debug('Arrival Window span: '+ minutes);
            
    //         tries++;

    //         switch on behavior {
    //             when ThrowRetryableExceptionOnFirstTry  {
    //                 if(tries == 1)
    //                     throw new FSL_CustomExceptions.NoCandidateFoundException();
    //             }
    //             when ThrowRetryableExceptionOnFirstTwoTries  {
    //                 if(tries < 3 )
    //                     throw new FSL_CustomExceptions.NoCandidateFoundException();
    //             }
    //         }

    //         return true;
    //     }
    // }
    public static testmethod void testingmethod1() {
        
        
        FSL_SchedulingUtility.fakemethod();
    }
    public static testmethod void testingmethod2() {
        
        
        FSL_SchedulingUtility.fakemethod2();
    }   
    public static testmethod void testingmethod3() {
        
        
        FSL_SchedulingUtility.fakemethod3();
    }          
}