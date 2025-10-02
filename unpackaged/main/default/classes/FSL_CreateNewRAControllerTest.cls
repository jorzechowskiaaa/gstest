@isTest     
Public class FSL_CreateNewRAControllerTest{
 static User user = new User();
    static testmethod void CreateResourceAbscence(){
     List<User> userList = [SELECT id, firstName, lastName 
                               FROM USER WHERE alias='C_Admin'];
  
     List<Schema.Location> location = [select id from Location];
     List<ResourceAbsence> Ralist = FSL_DataFactory.CreateResourceAbsences('LKL');
     List<ServiceResource> Sres = [select id from ServiceResource];
      
     PageReference pageRef = Page.FSL_CreateNewResourceAbsence;
     pageRef.getParameters().put('id',Sres [0].id);
     Test.setCurrentPage(pageRef);
      
     FSL_CreateNewResourceAbsenseController cra= new FSL_CreateNewResourceAbsenseController();
         cra.useCurrentLocatin =true;
         cra.saveAbsence();
     System.assertEquals('LKL', Ralist[0].FSL__GanttLabel__c);
        
    }
    
  @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }
 
    

}