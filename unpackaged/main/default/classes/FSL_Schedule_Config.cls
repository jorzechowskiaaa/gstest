/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-10-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-09-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/

public class FSL_Schedule_Config {

    public Id schedulingPolicy{get; set;}
    public Id firstRetryPolicy{get; set;}
    public Id finalRetryPolicy{get; set;}

    public Integer slaValue{get; set;}


    public FSL_Schedule_Config() {
        schedulingPolicy = null;
        firstRetryPolicy = null;
        finalRetryPolicy = null;
        slaValue = 0;
    }

    public FSL_Schedule_Config(FSL_Schedule_Config srcScheduleConfig, Id defPolicyId) {

        schedulingPolicy = defPolicyId;
        firstRetryPolicy = null;
        finalRetryPolicy = null;

        if ( srcScheduleConfig != null) {
            slaValue = srcScheduleConfig.slaValue;
        }
 
    }
}