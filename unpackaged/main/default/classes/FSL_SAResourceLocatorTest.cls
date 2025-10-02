@isTest
Public class FSL_SAResourceLocatorTest{
  static testmethod void FSL_SAResourceLocator(){   
   
    Test.startTest();
    FSL_SAResourceLocator sar= new FSL_SAResourceLocator();
    String sch = '0 0 2 * * ?'; 
    system.schedule('Test Territory Check', sch, sar); 
    Test.stopTest();
   
   } 

  @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
        
    }

}