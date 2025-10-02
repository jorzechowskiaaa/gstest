@isTest
public class FSL_SampleTest {
	@isTest
    public static void testMemberLevel(){
       Boolean hasPermission = FeatureManagement.checkPermission('Skip_Sharing');
       system.debug('@@@hasPermission@@@@'+hasPermission);
       system.assertEquals(hasPermission, false);
    }
}