/****
 * *@Name: FSL_LastKnownLocationSchedule
 * *@Description: Scheduled class is to create Service Absense records to get Last know location of Resource 
 * *@Date: 02-01-2018
 * *@Version: 1.0
 * * 
 * **/
public class FSL_LastKnownLocationSchedule implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        List<ServiceResource> serviceResourceIds = new List<ServiceResource>();
        if( FSL_Optimization_Settings__c.getOrgDefaults().Run_LKL__c ) {
            serviceResourceIds = [SELECT Id 
                                FROM ServiceResource 
                                WHERE isActive = true 
                                AND RelatedRecord.isActive = true];
        }
        else {
            serviceResourceIds = [SELECT Id 
                                FROM ServiceResource 
                                WHERE name='X@Xom'];
        }
        FSL_LastKnownLocationUtility.lastKnownLocationJob( serviceResourceIds );
    }
}