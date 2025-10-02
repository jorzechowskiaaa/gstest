@isTest

private class UpdateCMDTest {

    private static testMethod void updateCMDTestOne() {
        Test.startTest();
    
               
        UpdateCMD.flowInput f = new UpdateCMD.flowInput();
        List<Default_State_PTA__mdt> mdt = [Select DeveloperName, State__c, PTA__c, Service_Type__c from Default_State_PTA__mdt limit 5];
        f.data = mdt;
        List<UpdateCMD.flowInput> fi = new List<UpdateCMD.flowInput>();
        fi.add(f);
        
        UpdateCMD.updateMetadata(fi);
        
          
        Test.stopTest();      
       
    }
    private static testMethod void updateCMDTestTwo() {
        Test.startTest();
    
               
        UpdateCMD.flowInput f = new UpdateCMD.flowInput();
        List<Default_State_PTA__mdt> mdt = [Select Label, State__c, PTA__c, Service_Type__c from Default_State_PTA__mdt limit 5];
        f.data = mdt;
        List<UpdateCMD.flowInput> fi = new List<UpdateCMD.flowInput>();
        fi.add(f);
        
        UpdateCMD.updateMetadata(fi);
              
        Test.stopTest();      
       
    }
     private static testMethod void updateCMDTestThree() {
        Test.startTest();
        
        UpdateCMD.flowInput f = new UpdateCMD.flowInput();
        List<Default_State_PTA__mdt> mdt = [Select State__c, PTA__c, Service_Type__c, Label from Default_State_PTA__mdt limit 5];
        Integer i = 1;
        List<Default_State_PTA__mdt> mdtNewRecords = new  List<Default_State_PTA__mdt>();
         
         for (Default_State_PTA__mdt m: mdt) {
             m.Label = 'Name ' + i; 
             mdtNewRecords.add(m);
         }
        f.data = mdtNewRecords;
        List<UpdateCMD.flowInput> fi = new List<UpdateCMD.flowInput>();
        fi.add(f);
        
        UpdateCMD.updateMetadata(fi);
              
        Test.stopTest();      
       
    }
}