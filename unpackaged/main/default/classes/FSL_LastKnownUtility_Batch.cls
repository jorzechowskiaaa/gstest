/**
 * @File Name          : FSL_LastKnownUtility_Batch.cls
 * @Description        : 
 * @Author             : Rajesh Kemisetti
 * @Group              : 
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 4/27/2020, 5:29:34 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/27/2020   Rajesh Kemisetti     Initial Version
**/
global class FSL_LastKnownUtility_Batch implements Database.Batchable<sObject>, Database.Stateful{
    global FSL_LastKnownUtility_Batch(){

    }
    
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if(FSL_Optimization_Settings__c.getOrgDefaults().Run_LKL__c){
            return Database.getQueryLocator([select id from ServiceResource where isActive=true AND RelatedRecord.isActive =true]); 
        }else{
            return Database.getQueryLocator([select id from ServiceResource where name='X@Xom']);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<ServiceResource> scope){
        FSL_LastKnownLocationUtility.lastKnownLocationJob(scope);
    }
    
    global void finish(Database.BatchableContext BC){   

    }
}