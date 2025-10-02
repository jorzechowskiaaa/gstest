/**
 * @File Name          : FSL_SLA_ViolationTest.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/16/2020, 4:05:17 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/16/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_SLA_ViolationTest{
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    // Static testmethod void SLAViolation(){
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    //      FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
    //       list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
    //                                       (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
    //                                              Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
    //                                              FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
    //                                               SchedEndTime, actualstarttime,PostalCode,Country,FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
    //                                        from ServiceAppointments
    //                                        order by recordtype.name asc) 
    //                                       from Workorder];  
        
        
    //     list<ServiceAppointment> salist = [select id,FSL__InJeopardy__c, parentrecordid, RecordTypeId, SchedStartTime,SchedEndTime, actualstarttime,FSL__InJeopardyReason__c, PTA__c from ServiceAppointment];
        
       
    //     ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        
    //     /*workOrders[0].ServiceAppointments[0].SchedStartTime = System.now();
    //     workOrders[0].ServiceAppointments[0].SchedEndTime = System.now()+1800;
    //     workOrders[0].ServiceAppointments[0].actualstarttime = System.now();
    //     workOrders[0].ServiceAppointments[0].PTA__c = System.now();
    //     update workOrders[0].ServiceAppointments[0];*/
        
    //     salist[0].SchedStartTime = System.now();
    //     salist[0].SchedEndTime = System.now()+1800;
    //     salist[0].actualstarttime = System.now();
    //     salist[0].PTA__c = System.now();
        
    //     System.test.startTest();

    //     salist[0].FSL__InJeopardyReason__c  = null;
    //     update salist[0]; 

    //     salist[0].FSL__InJeopardyReason__c  = 'No Response';
    //     update salist[0];

    //     salist[0].FSL__InJeopardyReason__c  = 'No Lat/Long'; 
    //     update salist[0];
        
    //     AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(workOrders[0].ServiceAppointments[0].Id, serviceResource.Id);
    //     insert assignedResourceBreakdown;        
        
    //     FSL_SLA_Violation.missingPTAByMinutes(salist);        
    //     system.debug('salist1:'+salist);
    //     System.assert(!salist[0].FSL__InJeopardy__c, 'No Lat/Long');
    //     FSL_SLA_Violation.clearJeopardy(salist);
        
    //     list<ServiceAppointment> updatedSaList = new list<ServiceAppointment>();
    //     salist[0].PTA__c = system.now() + 60; 
    //     updatedSaList.add(salist[0]);  
    //     FSL_SLA_Violation.missingPTAByMinutes(updatedSaList); 
    //     system.debug('salist2:'+salist);
    //     System.assert(!salist[0].FSL__InJeopardy__c);
    //     FSL_SLA_Violation.clearJeopardy(updatedSaList);  
        
    //     System.test.stopTest();
        
    // }  
    
    // @isTest
    // static /*testmethod*/ void SLAViolation_Callout_Success(){
    //     Test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    //     FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     list<ServiceAppointment> salist = [select id,FSL__InJeopardy__c, parentrecordid, RecordTypeId, SchedStartTime,SchedEndTime, actualstarttime,FSL__InJeopardyReason__c, PTA__c from ServiceAppointment];
    //     ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        
    //     salist[0].SchedStartTime = System.now();
    //     salist[0].SchedEndTime = System.now()+1800;
    //     salist[0].actualstarttime = System.now();
    //     salist[0].PTA__c = System.now();
    //     update salist[0]; 
            
    //     AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(salist[0].Id, serviceResource.Id);
    //     insert assignedResourceBreakdown;        
        
    //     // FSL_SLA_Violation.missingPTAByMinutes(salist);
    //     system.debug('salist3:'+salist);
    //     System.assert(!salist[0].FSL__InJeopardy__c, 'No Lat/Long');

    //     // Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true));  
    //     // FSL_SLA_Violation.WOJeopardyAPI(new list<Id>{salist[0].parentrecordid}, false, 'Jeopardy');
        
    //     // FSL_SLA_Violation.WOJeopardyAPI(new list<Id>{salist[0].parentrecordid}, false, 'Warning'); 
        
    //     Test.stopTest();
    // }
    
    // @isTest
    // static /*testmethod*/ void SLAViolation_Callout_Failure(){
        
    //     System.test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    //      FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
    //     list<ServiceAppointment> salist = [select id,FSL__InJeopardy__c, parentrecordid, RecordTypeId, SchedStartTime,SchedEndTime, actualstarttime,FSL__InJeopardyReason__c, PTA__c from ServiceAppointment];
    //     ServiceResource serviceResource = [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 1];
        
    //     salist[0].SchedStartTime = System.now();
    //     salist[0].SchedEndTime = System.now()+1800;
    //     salist[0].actualstarttime = System.now();
    //     salist[0].PTA__c = System.now();
    //     update salist[0]; 
            
    //     AssignedResource assignedResourceBreakdown = FSL_DataFactory.createAssignedResource(salist[0].Id, serviceResource.Id);
    //     insert assignedResourceBreakdown;        
        
    //     // FSL_SLA_Violation.missingPTAByMinutes(salist);
    //     system.debug('salist4:'+salist);
    //     System.assert(!salist[0].FSL__InJeopardy__c, 'No Lat/Long');
        
    //     Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
    //     // FSL_SLA_Violation.WOJeopardyAPI(new list<Id>{salist[0].parentrecordid}, true, 'Jeopardy');
        
    //     System.test.stopTest();
    // }    

    @isTest
    static /*testmethod*/ void createSLAViolHistoryForWarningTest(){
        
        System.test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));  
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        // list<WorkOrder> workOrders = [select Recordtype.Name,Street,city,State,latitude, longitude, status, Resolution_Code__c, 
        //                                   (select id, Status, FSL__Pinned__c, ParentRecordid,FSL__InternalSLRGeolocation__Latitude__s,
        //                                          Street, City, State, FSL__InternalSLRGeolocation__Longitude__s, FSL__Emergency__c,
        //                                          FSL__Schedule_over_lower_priority_appointment__c, Service_Resource__c, SchedStartTime,
        //                                           SchedEndTime, actualstarttime,PostalCode,Country,FSL_IsLight_Service__c, serviceterritoryid, appointmentnumber
        //                                    from ServiceAppointments
        //                                    order by recordtype.name asc) 
        //                                   from Workorder];  
        // Map<Id,String> warningMaps = new Map<Id,String>();
        // warningMaps.put(workOrders[0].id,'value');
        // FSL_SLA_Violation.createSLAViolHistoryForWarning(warningMaps,'testvalue');

        List<ServiceAppointment> saList = [
            SELECT FSL__InJeopardyReason__c, Work_Order__r.Service_Resource__c, Work_Order__r.ServiceTerritoryId
            FROM ServiceAppointment
        ];
        FSL_SLA_Violation.createSLAViolHistoryForWarning(saList);
        System.assert([SELECT Id FROM FSL_SLA_Violation_History__c].size() > 0);
    }

    // @IsTest
    // public static void testWoJeopardyApiApplicationLog_Constructor_DefaultFieldsSetAsExpected() {
    //     FSL_SLA_Violation.WoJeopardyApiApplicationLog log = new FSL_SLA_Violation.WoJeopardyApiApplicationLog();
    //     Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();

    //     FSL_Application_Log__c appLog = log.getApplicationLog();
    //     System.assertEquals( 'WOJeopardyAPI', appLog.Operation__c );
    //     System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
    // }

    /*@IsTest
    public static void testWoJeopardyApiApplicationLog_LogFailedCalloutResult_FieldsSetAsExpected() {
        FSL_SLA_Violation.WoJeopardyApiApplicationLog log = new FSL_SLA_Violation.WoJeopardyApiApplicationLog();
        log.logFailedCalloutResult( body, response );

        FSL_Application_Log__c appLog = log.getApplicationLog();
        System.assertEquals( 'WOJeopardyAPI', appLog.Operation__c );
        System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
    }

    @IsTest
    public static void testWoJeopardyApiApplicationLog_LogCalloutException_FieldsSetAsExpected() {
        FSL_SLA_Violation.WoJeopardyApiApplicationLog log = new FSL_SLA_Violation.WoJeopardyApiApplicationLog();
        
        FSL_Application_Log__c appLog = log.getApplicationLog();
        System.assertEquals( 'WOJeopardyAPI', appLog.Operation__c );
        System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
    }

    @IsTest
    public static void testWoJeopardyApiApplicationLog_LogException_FieldsSetAsExpected() {
        FSL_SLA_Violation.WoJeopardyApiApplicationLog log = new FSL_SLA_Violation.WoJeopardyApiApplicationLog();
        
        FSL_Application_Log__c appLog = log.getApplicationLog();
        System.assertEquals( 'WOJeopardyAPI', appLog.Operation__c );
        System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
    }*/
}