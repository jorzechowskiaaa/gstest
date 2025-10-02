/*
* @File Name   : FSL_GetSiteURL
* @Description : Generates FSL site url with FSL name space.Can be used to generate other site urls. Used in Get Candidates Aura Component.
* @Modification Log
------------------------------------------------------------------------------------------------------------------------
Ver     Date           Author               Modification
---     ----           ------               ------------
*   1.0     4/17/2020    Phani Kolanuvada         Created
	
*/
public class FSL_GetSiteURL {
    
    @AuraEnabled
    public static String getVisualforceFSLDomain(){
        return getMyDomain() + '--fsl.' + getInstance() + '.visual.force.com';
    }

    public static String getLightningDomain(){
        return getMyDomain() + '.lightning.force.com';
    }

    public static String getMyDomain(){
        return URL.getOrgDomainUrl().getHost().split('\\.')[0].toLowerCase();
    }

    private static String instance = '';
    public static String getInstance(){
        if(String.isBlank(instance)){
            instance = [SELECT InstanceName FROM Organization LIMIT 1].InstanceName.toLowerCase();
        }
        return instance;
    }


}