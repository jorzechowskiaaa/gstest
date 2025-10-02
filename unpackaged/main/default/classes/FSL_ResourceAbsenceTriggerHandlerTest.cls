@isTest
public class FSL_ResourceAbsenceTriggerHandlerTest {
     static testMethod void handleDeletionTest(){  
        List<User> userList = [SELECT id, firstName, lastName 
                                     FROM USER WHERE alias='C_Admin'];
        List<ResourceAbsence> Ralist = FSL_DataFactory.CreateResourceAbsences('LKL');  
        //Ralist[0].End= system.today()+2;
        Ralist[0].End= system.Now().addMinutes(40); // Changes this code as per current requirnment
        
         update Ralist;
        
       // Ralist[0].End= system.today()+5;
       Ralist[0].End=  system.Now().addMinutes(55);// Changes this code as per current requirnment
        
        update Ralist;
        system.debug('==========listprint'+Ralist.size());
        Map<ID,ResourceAbsence> ramap = new map<ID,ResourceAbsence>();
       
        ramap.put(Ralist[0].id,Ralist[0]);
        system.debug('-----------------mapprint'+ramap.values());
       System.assertEquals(Ralist[0].FSL__GanttLabel__c,'LKL');
        System.Test.StartTest();
         try {
            FSL_ResourceAbsenceTriggerHandler.handleDeletion(Ralist);
           }
         catch(Exception Ex) {
            
         }  
       System.Test.StopTest();
       
     }
    
    
    static testMethod void checkAbsenceForOverlapsTest(){ 
        List<ResourceAbsence> Ralist = FSL_DataFactory.CreateResourceAbsences('LKL');  
        Ralist[0].FSL__GanttLabel__c = 'Test LKL';
      //Ralist[0].End = System.now()+4;
     	Ralist[0].End = system.Now().addMinutes(55);
        update Ralist;
        system.debug('==========listprint'+Ralist.size());
        Map<ID,ResourceAbsence> ramap = new map<ID,ResourceAbsence>();
        ramap.put(Ralist[0].id,Ralist[0]);
        system.debug('-----------------mapprint'+ramap.values());
        
      System.assertEquals(Ralist[0].FSL__GanttLabel__c,'Test LKL');
         
         System.Test.StartTest();
         try {
            FSL_ResourceAbsenceTriggerHandler.checkAbsenceForOverlaps(Ralist);        
         }
         catch(Exception Ex) {
            
         }  
       System.Test.Stoptest();
    
    } 
    
    
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
 
}