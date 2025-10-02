/**
 * @File Name          : FSL_UserDeactivationScheduler.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 11/7/2019, 3:54:36 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    11/7/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public without sharing class FSL_UserDeactivationScheduler implements Schedulable{
	public void execute(SchedulableContext sc) {
		try 
        {
            Integer scope = Integer.valueOf(Label.FSL_DeActivation_BatchSize);
			Database.executeBatch(new FSL_UserDeProvisionBatch(), scope);
		} catch (Exception e){
			System.debug(e.getStackTraceString());
		}
    }
}