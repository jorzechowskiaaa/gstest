/**
 * @File Name          : FSL_TriggerUtility.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/28/2020, 3:08:09 PM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/3/2020     Rajesh Kemisetti           Initial Version
 * 2.0.  10/17/2023    Laxman Vattam              Added logic to the method isDisabled to skip trigger when 
 * 												  custom permission is assigned to the user
**/
public class FSL_TriggerUtility { 
    /**
    * @description 
    * @author Rajesh Kemisetti | 4/3/2020 
    * @param sObjectType 
    * @return boolean 
    **/
    public static boolean isDisabled(string sObjectType){
        Execute_Trigger__c et = Execute_Trigger__c.getInstance(sObjectType);
        if(FeatureManagement.checkPermission('Skip_Automation_Logic')){
            system.debug('Trigger is disabled:1');
            return true;
        }else if(et!=null){
            system.debug('Trigger is disabled:2');
            return et.Disabled__c; 
        }
        return false;
    }


    /**
    * @description 
    * @author Balaram Naidu | 05/27/2020 
    * @param statusFrom , statusTo
    * @return boolean 
    **/
    public static boolean isStatusTransitionAllowed( String statusFrom, String statusTo, List<FSL.StatusTransition> sts ) {
        Boolean allowed = false;
        if( statusFrom == 'Cleared' ) {
            allowed = false;
        } else if( statusTo == 'Spotted' || statusTo == 'In Progress'  || statusFrom == 'In Progress') {
            allowed = true;
        } else {
            for( FSL.StatusTransition stTran : sts ) {
                if( stTran.FromStatus == statusFrom && stTran.ToStatus == statusTo ) {
                    allowed = true;
                }
            }
        }
        return allowed;
    }
}