@isTest     
Public class FSL_CreateNewShiftControllerTest{
    
    static testmethod void CreateShiftTest(){
       
          list<ServiceResource> Sres= [select id, Primary_Service_Territory__c, Primary_Service_Territory__r.OperatingHoursId from serviceresource where ResourceType='T' limit 2];
          PageReference pageRef = Page.FSL_CreateNewShift;
          pageRef.getParameters().put('id',Sres[0].id);
           Test.setCurrentPage(pageRef);
          
        Test.starttest();
        try{
          FSL_CreateNewShiftController sht = new FSL_CreateNewShiftController();
          sht.saveShift();
         
        }catch(exception ex){
            
        }
        Test.stoptest(); 
        
        }

  @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   
}