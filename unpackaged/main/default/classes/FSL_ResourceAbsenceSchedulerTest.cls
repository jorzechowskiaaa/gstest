@isTest
Public class FSL_ResourceAbsenceSchedulerTest{
 
    static testmethod void FSL_ResourceAbsence() 
    {
        Test.startTest();
        
             FSL_ResourceAbsenceScheduler fras= new FSL_ResourceAbsenceScheduler();
             String sch = '0 0 2 * * ?'; 
             system.schedule('Test Territory Check', sch, fras); 
             Test.stopTest();
       
    } 
 }