@isTest
public class FSL_AudioPreferencesTriggerHandlerTest {
    
    static testmethod void CreateAndUpdateAudioprefRec(){
        
       system.Test.startTest(); 
     
         List<User> userList = [SELECT id, firstName, lastName 
                 FROM USER WHERE alias ='C_Admin'];
        List<User> dispatchUserList = [SELECT id, firstName, lastName 
                 FROM USER WHERE alias ='D_Fleet'];
        System.runAs(userList[0]) {
            list<FSL_Audio_Preferences__c> apref = [select id,User__c from FSL_Audio_Preferences__c LIMIT 1];
             apref[0].User__c = userList[0].id;
             update apref[0];      
            system.debug('------username---------'+apref[0]);
            FSL_Audio_Preferences__c newAup = apref[0];
             newAup.User__c = dispatchUserList[0].id;
             map<id,FSL_Audio_Preferences__c> audnewmap = new map<id,FSL_Audio_Preferences__c>();
             audnewmap.put(newAup.id,newAup);
             
             map<id,FSL_Audio_Preferences__c> audoldmap = new map<id,FSL_Audio_Preferences__c>();
             audoldmap.put(apref[0].id,apref[0]);
             apref[0].Time_Interval_In_Seconds__c = 12;
             update apref[0];
             //FSL_AudioPreferencesTriggerHandler.createAndDeleteUserShareRecords(apref,audnewmap,audoldmap);
        }
         
         
         system.Test.stopTest();   
    } 
    
  
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   
    

}