/**
 * @File Name          : FSL_UserDeProvisionBatchTest.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 03-10-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    11/11/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
private without sharing class FSL_UserDeProvisionBatchTest {
    
    static testMethod void userDeProvision_DispatcherTest()  {

        string userstring = '';
        for(User u : [select id from user where alias IN ('D_Fleet','T_Fleet')]){
            userstring += '\'' + u.id + '\',';
        }
        userstring = userstring.lastIndexOf(',') > 0 ? '(' + userstring.substring(0,userstring.lastIndexOf(',')) + ')' : userstring ;
        
		Test.startTest();
        
        string querystring = 'select id, Name, Email, lastlogindate, EmployeeNumber, profile.Name from User where IsActive=true and ID IN '+userstring;
        system.debug('querystring'+querystring);
		Database.executeBatch(new FSL_UserDeProvisionBatch(querystring), 200);
        
		Test.stopTest();

    }
    
    static testMethod void userDeProvision_Technician_Test1()  {

        Test.startTest();
        FSL_UserDeactivationScheduler obj = new FSL_UserDeactivationScheduler();   
        Test.stopTest();

        String chron = '0 0 23 * * ?';        
        String jobid = System.schedule('testScheduledApex', chron, obj);
        
        CronTrigger ct = [Select id , CronExpression from CronTrigger where id = :jobId];
        System.assertEquals(chron,ct.CronExpression); 
        		
    }
    
    static testMethod void userDeProvision_Technician_Test2()  {


       
        string userstring = '';
        for(User u : [select id from user where alias IN ('T_Fleet','D_Fleet')]){
            userstring += '\'' + u.id + '\',';
        }
        userstring = userstring.lastIndexOf(',') > 0 ? '(' + userstring.substring(0,userstring.lastIndexOf(',')) + ')' : userstring ;
        
		Test.startTest();
        
        string querystring = 'select id, Name, Email, lastlogindate, EmployeeNumber, profile.Name from User where IsActive=true and ID IN '+userstring;
        system.debug('querystring'+querystring);
		Database.executeBatch(new FSL_UserDeProvisionBatch(querystring), 200);
        
		Test.stopTest();

    } 
/* Abhinav
    @IsTest
    static void userDeProvision_NoQuery()  {


        FSL_Deactivate_Profile__mdt club_Dispatcher = new FSL_Deactivate_Profile__mdt(Label = 'FSL Club Dispatcher' ,Profile__c = 'FSL Club Dispatchers',DeveloperName='FSL_Club_Dispatcher' ); 
        //insert club_Dispatcher ; 
        
		Test.startTest();
        
		Database.executeBatch(new FSL_UserDeProvisionBatch(), 200);
        
		Test.stopTest();

    }  
*/
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    } 

}