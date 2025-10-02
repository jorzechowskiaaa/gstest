/**
 * @description       : Controller that checks whether the current user has permission to access the B2Q App SSFI -1176
 * @author            : Patel Minesh
 * @last modified on  : 08-11-2025
 * @last modified by  : Patel Minesh
**/
public class BatteryTestingController {
    @AuraEnabled(cacheable=true)
    public static Boolean checkBatteryTestingPermission(){
        return FeatureManagement.checkPermission('Battery_Testing');
    }
}