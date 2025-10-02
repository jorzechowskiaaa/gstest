@isTest
Public class FSL_AppointmentScheduleQueueableTest{

    Static testmethod void ScheduleLandlineComplexCall(){       

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(true)); 

        FSL_DataFactory.createWOIntakeCall('FSL_Landline_ComplexCall');
        Test.stopTest();
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        system.assertEquals('Spotted', wo.status);
    }
    
    Static testmethod void ScheduleRequiredComplexCall(){       
        delete [select id from Technology_Preference__c];

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 

        FSL_DataFactory.createWOIntakeCall('FSL_Required_ComplexCall');
        
        Test.stopTest();
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        System.debug('ScheduleRequiredComplexCall wo.status = ' + wo.status);
        system.assertequals('In Progress', wo.status);
    }
   Static testmethod void ScheduleLightCall(){       
        
        delete [select id from Technology_Preference__c];

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false)); 

        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
		Test.stopTest();
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        System.debug('ScheduleLightCall wo.status = ' + wo.status);
        system.assertEquals('In Progress', wo.status);
    }

    //These tests are useless because passing null to FSL_AppointmentScheduleQueueable causing no action to be taken
    //New tests are now in FSL_ServiceSchedulerTest
    
    // Static testmethod void AppointmentSchedulewithnoPolicy(){       
        
    //     Test.starttest();
    //     FSL_DataFactory.createWOIntakeCall('FSL_UnknowComplexCall');
    //     workorder wo = [select id, status, Service_Resource__c, Latitude, Longitude, (select id from ServiceAppointments) from workorder limit 1];
    //     FSL__Scheduling_Policy__c schedulingPolicy = [select id,name from FSL__Scheduling_Policy__c limit 1];
    //     Test.stoptest();         
        
    //     FSL_AppointmentScheduleQueueable apps2 = new FSL_AppointmentScheduleQueueable(null,wo.ServiceAppointments[0] ,wo.ServiceAppointments[1], null, null);
    //     apps2.execute(null);  
    //     system.debug('apps2 SCHEDULE');        
    // }

    // Static testmethod void AppointmentSchedulewithnoSA(){       
    //     FSL_Application_Log__c applog = new FSL_Application_Log__c();
    //     insert applog;
        
    //     Test.starttest();
    //     FSL_DataFactory.createWOIntakeCall('FSL_UnknowComplexCall');
    //     workorder wo = [select id, status, Service_Resource__c, Latitude, Longitude, (select id from ServiceAppointments) from workorder limit 1];
    //     FSL__Scheduling_Policy__c schedulingPolicy = [select id,name from FSL__Scheduling_Policy__c limit 1];
    //     Test.stoptest();          
        
    //     FSL_AppointmentScheduleQueueable appsEx = new FSL_AppointmentScheduleQueueable(null,wo.ServiceAppointments[0], null, applog, null);
    //     appsEx.scheduleAppointmentID = null;
    //     system.debug('appsEx SCHEDULE');
    //     try{
    //     	appsEx.execute(null);  
    //     }catch(exception e){
    //         system.assertEquals('Attempt to de-reference a null object', e.getMessage());
    //     }        
    // }    

    Static testmethod void AppointmentSchedulewithnoSRComplexCall(){
        delete [select id from Technology_Preference__c];
        list<ServiceResource> SRs = [select id, IsActive from ServiceResource];
        for(ServiceResource sr : SRs){
            sr.IsActive = false;
        }
        update SRs;
        
        Test.starttest();
        FSL_DataFactory.createWOIntakeCall('FSL_ComplexCall');
        Test.stoptest();  
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        system.assertEquals('Spotted', wo.status);                
    }    

    Static testmethod void AppointmentSchedulewithnoSRLightCall(){
        delete [select id from Technology_Preference__c];
        list<ServiceResource> SRs = [select id, IsActive from ServiceResource];
        for(ServiceResource sr : SRs){
            sr.IsActive = false;
        }
        update SRs;
        
        Test.starttest();
        FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        Test.stoptest();   
        workorder wo = [select id, status, Service_Resource__c from workorder limit 1];
        system.assertEquals('Spotted', wo.status);        
    } 
 
    static testmethod void scenario_1(){
        list<FSL__Scheduling_Policy__c> schedulingPolicy = [select id,name from FSL__Scheduling_Policy__c];
        list<string> prioritylist =  new list<string>{'Medium','High','Critical'};
        list<FSL_SLA_ArrivalWindow__c> SLAs = new list<FSL_SLA_ArrivalWindow__c>();
        for(integer i=0;i<prioritylist.size(); i++){
            FSL_SLA_ArrivalWindow__c sla = new FSL_SLA_ArrivalWindow__c();
            sla.LS_SLA__c = 20;
            sla.Retry_Policy__c = SchedulingPolicy[1].id;
            sla.Scheduling_Policy__c = SchedulingPolicy[0].id;
            sla.Tow_SLA__c =  20;
            sla.Priority__c = prioritylist[i];
            SLAs.add(sla);
        }        
        insert SLAs;

        delete [select id from Technology_Preference__c];

        Test.startTest();
        FSL_DataFactory.createWOIntakeCall('FSL_UnknowComplexCall');    
        Test.stopTest();

        WorkOrder wo = [select id,status from WorkOrder limit 1];
        system.assertEquals('Spotted', wo.status);
       
    }
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
    
}