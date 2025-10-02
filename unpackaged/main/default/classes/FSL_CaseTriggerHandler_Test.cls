@isTest
private without sharing class FSL_CaseTriggerHandler_Test {
    
                               
    static testmethod void handleUserDeProvisioningRequestTest() {
    
    Test.starttest();
        List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias IN ('T_Fleet','D_Fleet')];
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1]; 
        map<string, string> userResourcesMap = new map<string, string>();
        for(ServiceResource sr : [select id,RelatedRecordId from ServiceResource where RelatedRecordId IN :userList]){
	        userResourcesMap.put(sr.RelatedRecordId, sr.id);
    	}
    
        list<Case> cases = new list<Case>();
        for(User u : [Select id, Name, IsActive, LastLoginDate, EmployeeNumber, 
                                                    profile.Name, IsPortalEnabled, email 
                                               from User 
                                               where IsActive=true and 
                                                    ID IN :userResourcesMap.keySet()])
        {
            Case cs = new case(fsl_user__c = u.id, 
                               recordtypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('User De-Provisioning Request').getRecordTypeId(), 
                               origin='OnDemand',
                               FSL_Service_Resource__c = userResourcesMap.get(u.id)
                              ); 
            cases.add(cs);
           
        }
        insert cases;
        for(case cs : cases){
            cs.fsl_approval_status__c = 'Approved';
            cs.Origin='Automation';
        }
        update cases;
        Test.stoptest();
        list<User> updated_users = [Select id, Name, IsActive, lastname, alias, LastLoginDate, EmployeeNumber, username, 
                                                    profile.Name, IsPortalEnabled, email 
                                               from User 
                                               where ID IN :userResourcesMap.keySet()];
        system.debug('updated_users: '+updated_users);
        system.assertequals(false, updated_users[0].isactive); 
    }
        
    static testmethod void handleUserReactivation() {
        User user = [SELECT id, Name, IsActive, lastname, alias, LastLoginDate, EmployeeNumber, username, 
                                                    profile.Name, IsPortalEnabled, email
                               FROM USER WHERE alias = 'D_Fleet'];
        user.isactive=false;
        update user;
        
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1];         
       	User admin = [select id from user where alias = 'C_Admin'];
        //reactivate the user
        system.runas(admin){
            Case cs = new Case();
            cs.Status = 'New';
            cs.FSL_User__c = user.id;
            cs.FSL_Email__c = user.email;
            cs.FSL_Primary_Service_Territory__c = serterlist[0].id;
            cs.FSL_First_Name__c = 'Test First Name3';
            cs.FSL_Username__c  = user.username;
            cs.FSL_Last_Name__c = user.lastname;
            cs.FSL_Email__c = user.email;
            cs.FSL_Alias__c  = user.alias;  
            cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('User Provisioning Request').getRecordTypeId();
            cs.FSL_Nickname__c = user.alias;
            cs.FSL_Re_Activate__c = true;
            cs.FSL_Contractor__c = true;
            cs.FSL_Profile__c = 'Facility Dispatcher'; 
            try{
                Test.startTest();
            	insert cs;
                Test.stopTest();
            }catch(exception e){
                system.debug('exception');
            }
        }
    }
    
    static testmethod void handleUserProvisioningRequestTest(){
      Test.starttest();
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1];    
        List<Case> CreateCs = FSL_DataFactory.CreateUserProvisionCase(serterlist[0].id);
        
      Test.stoptest();
    }
    
    static testmethod void PortalTesting (){
        
        List<User> userlist= [Select id from user where alias = 'C_Admin'];
       
                 ServiceResource sr = [select id from ServiceResource where ResourceType ='T' LIMIT 1];
        list<ServiceTerritory> serterlist = [select id from ServiceTerritory LIMIT 1];
         List<ServiceTerritoryMember> newSTMList = new List<ServiceTerritoryMember>();
            ServiceTerritoryMember serTerMem = FSL_DataFactory.createServiceTerritoryMember(sr.Id, serterlist[0].Id);
        newSTMList.add(serTerMem);
    }

   @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    } 
    
    
}