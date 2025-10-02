/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 12-01-2022
 * @last modified by  : Clement Shiu
**/
@isTest
public class FSL_GlympseToFSLRequestTest{

    //ERS-230874 Glympse Removal - Part I 
    /* ----------------------------------------------------------------------------------------
    static testMethod void GlympseCallIn(){         
        delete [select id from Technology_Preference__c];   
        Glympse_EnRoute__Glympse_EnRoute_Phase__c phase = new Glympse_EnRoute__Glympse_EnRoute_Phase__c
                        (Name = 'En Route',
                         Glympse_EnRoute__Status__c= 'En Route', 
                         Glympse_EnRoute__Phase__c= 'live',
                         Glympse_EnRoute__Notify__c= true
                        );
        Glympse_EnRoute__Glympse_EnRoute_Phase__c phase1 = new Glympse_EnRoute__Glympse_EnRoute_Phase__c
                        (Name = 'On Location',
                         Glympse_EnRoute__Status__c= 'On Location', 
                         Glympse_EnRoute__Phase__c= 'arrived',
                         Glympse_EnRoute__Notify__c= true
                        );        
        insert phase; 
        insert phase1; 
        System.Test.StartTest();  
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.StopTest();  

        WorkOrder wo = [Select Id, (select id,Glympse_EnRoute__Glympse_EnRoute_Task_ID__c,status, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder LIMIT 1];
        
        wo.ServiceAppointments[0].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = 67452461;
        wo.ServiceAppointments[0].status='En Route';
        update wo.ServiceAppointments;
                
        
        string json = '{ "operations":{"phase":"arrived","task_id":67452461}, "task":{ "assigned_time":1544133916678, "description":"Order 647288022", "hierarchy":[30217], "start_time":1544133155033, "destination":{ "lat":38.1108631, "lng":-85.6400668, "name":"6516 FIRETHORN WAY" }, "org_id":79540, "session_id":394626, "due_time":0, "version":2, "agent_id":403934, "last_modified":1544133916964, "created_time":1544133154756, "operation_id":61077747, "foreign_id":"647288022", "_id":66381839, "completed":false, "metadata":[ { "n":"placed_time", "pid":2152, "v":"1544054400000" }, { "n":"order_id", "pid":2152, "v":"647288022" } ] }, "event":{ "phase_name":"arrived", "task_id":"67452461", "timestamp":1544135002836, "org_id":79540, "agent_id":403934, "type":"task_phase_changed", "notify":true } }';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/GlympseStatus/';        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(json);        
        RestContext.request = req;
        RestContext.response= res;        
        FSL_GlympseToFSLRequest.updateStatus();

        json = '{ "operations":{"phase":"arrived","task_id":674524612}, "task":{ "assigned_time":1544133916678, "description":"Order 647288022", "hierarchy":[30217], "start_time":1544133155033, "destination":{ "lat":38.1108631, "lng":-85.6400668, "name":"6516 FIRETHORN WAY" }, "org_id":79540, "session_id":394626, "due_time":0, "version":2, "agent_id":403934, "last_modified":1544133916964, "created_time":1544133154756, "operation_id":61077747, "foreign_id":"647288022", "_id":66381839, "completed":false, "metadata":[ { "n":"placed_time", "pid":2152, "v":"1544054400000" }, { "n":"order_id", "pid":2152, "v":"647288022" } ] }, "event":{ "phase_name":"arrived", "task_id":"67452461", "timestamp":1544135002836, "org_id":79540, "agent_id":403934, "type":"task_phase_changed", "notify":true } }';        
        req.requestBody = Blob.valueof(json);        
        RestContext.request = req;
        FSL_GlympseToFSLRequest.updateStatus();
        
        json = '{ "operations":{"phase":"live","task_id":67452461}, "task":{ "assigned_time":1544133916678, "description":"Order 647288022", "hierarchy":[30217], "start_time":1544133155033, "destination":{ "lat":38.1108631, "lng":-85.6400668, "name":"6516 FIRETHORN WAY" }, "org_id":79540, "session_id":394626, "due_time":0, "version":2, "agent_id":403934, "last_modified":1544133916964, "created_time":1544133154756, "operation_id":61077747, "foreign_id":"647288022", "_id":66381839, "completed":false, "metadata":[ { "n":"placed_time", "pid":2152, "v":"1544054400000" }, { "n":"order_id", "pid":2152, "v":"647288022" } ] }, "event":{ "phase_name":"arrived", "task_id":"67452461", "timestamp":1544135002836, "org_id":79540, "agent_id":403934, "type":"task_phase_changed", "notify":true } }';        
        req.requestBody = Blob.valueof(json);        
        RestContext.request = req;
        FSL_GlympseToFSLRequest.updateStatus();
        
        json = '{ "operations":{"phase":"live","task_id":674524612}, "task":{ "assigned_time":1544133916678, "description":"Order 647288022", "hierarchy":[30217], "start_time":1544133155033, "destination":{ "lat":38.1108631, "lng":-85.6400668, "name":"6516 FIRETHORN WAY" }, "org_id":79540, "session_id":394626, "due_time":0, "version":2, "agent_id":403934, "last_modified":1544133916964, "created_time":1544133154756, "operation_id":61077747, "foreign_id":"647288022", "_id":66381839, "completed":false, "metadata":[ { "n":"placed_time", "pid":2152, "v":"1544054400000" }, { "n":"order_id", "pid":2152, "v":"647288022" } ] }, "event":{ "phase_name":"arrived", "task_id":"67452461", "timestamp":1544135002836, "org_id":79540, "agent_id":403934, "type":"task_phase_changed", "notify":true } }';        
        req.requestBody = Blob.valueof(json);        
        RestContext.request = req;        
        FSL_GlympseToFSLRequest.updateStatus();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();        
    }
    ----------------------------------------------*/
    
}