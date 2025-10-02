/**
 * @File Name          : FSL_GlympseMileageToFSL_Test.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Clement Shiu
 * @Last Modified On   : 12-01-2022
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/13/2020   Rajesh Kemisetti     Initial Version
**/
@isTest
public class FSL_GlympseMileageToFSL_Test{

    //ERS-230874 Glympse Removal - Part I
    /* -------------------------
    static testMethod void GlympseCallIn() {         
        delete [select id from Technology_Preference__c];   
        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.StopTest();  
        WorkOrder wo = [Select Id, (select id,Glympse_EnRoute__Glympse_EnRoute_Task_ID__c,status, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder LIMIT 1];
        
        wo.ServiceAppointments[0].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = 67452461;
        wo.ServiceAppointments[0].status='En Route';
        update wo.ServiceAppointments;
        
        string json = '{"username": "test@aaa.com.aaaeyrie", "task_foreign_id": "SA-22182", "task_id": 67452461, "distance_travelled_by_phase": {"live_2": 4452.0, "complete": 0, "arrived_3": 0, "arrived_4": 0, "complete_5": 0, "eta_0": 0, "eta_1": 41.0}}';
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Glympse/Mileage/';        
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(json);        
        RestContext.request = request;
        FSL_GlympseMileageToFSL.updateMileage();

        json = '{"username": "test@aaa.com.aaaeyrie", "task_foreign_id": "SA-22182", "task_id": 67452461, "distance_travelled_by_phase": {"live_2": 4452.0, "complete": 0, "arrived_3": 0, "arrived_4": 0, "complete_5": 0, "eta_0": 0, "eta_1": 41.0}';
        request.requestBody = Blob.valueof(json);        
        RestContext.request = request;
        FSL_GlympseMileageToFSL.updateMileage();
    }

    static testMethod void GlympseCallIn_TaskIdNotFound() {         
        delete [select id from Technology_Preference__c];   

        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.Test.StopTest();

        WorkOrder wo = [Select Id, (select id,Glympse_EnRoute__Glympse_EnRoute_Task_ID__c,status, SchedStartTime, SchedEndTime, actualstarttime, PTA__c from ServiceAppointments) from WorkOrder LIMIT 1];
        
        wo.ServiceAppointments[0].Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = 67452460;
        wo.ServiceAppointments[0].status='En Route';
        update wo.ServiceAppointments;
                
        string json = '{"username": "test@aaa.com.aaaeyrie", "task_foreign_id": "SA-22182", "task_id": 67452461, "distance_travelled_by_phase": {"live_2": 4452.0, "complete": 0, "arrived_3": 0, "arrived_4": 0, "complete_5": 0, "eta_0": 0, "eta_1": 41.0}}';
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Glympse/Mileage/';        
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(json);        
        RestContext.request = request;
        FSL_GlympseMileageToFSL.updateMileage();

        json = '{"username": "test@aaa.com.aaaeyrie", "task_foreign_id": "SA-22182", "task_id": 67452461, "distance_travelled_by_phase": {"live_2": 4452.0, "complete": 0, "arrived_3": 0, "arrived_4": 0, "complete_5": 0, "eta_0": 0, "eta_1": 41.0}';
        request.requestBody = Blob.valueof(json);        
        RestContext.request = request;
        FSL_GlympseMileageToFSL.updateMileage();
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();        
    }
    
    -----------------*/
}