/****
 * *@Name: FSL_D3SyncLogger
 * *@Description: This class will update D3Sync Issue if D3 Call out is failing
 * *@Date: 02-17-2018
 * *@Version: 1.0
 * * 
 * **/
public class FSL_D3SyncLogger{

    /**********
     * @Method Name:syncIssueLogger
     * @Parameters:(Id WorkorderId)
     * @Description:    This method will update D3_Sync_Issue__c as true on WorkOrder as well ServiceAppointment. 
     *                      
     * **********/
    
    public static void syncIssueLogger(Set<Id> woId){
        try{ 
        List<WorkOrder> woRecs = [select id, D3_Sync_Issue__c from WorkOrder where Id = :woId];
        for (WorkOrder wo : woRecs){
            wo.D3_Sync_Issue__c = true;
        } 
          
        update woRecs;
        
        
        List<ServiceAppointment> saList = [Select id,D3_Sync_Issue__c from ServiceAppointment where ParentRecordId = :woId ];
        for (ServiceAppointment sa : saList){
            sa.D3_Sync_Issue__c = true; 
        }
        update saList;
        }catch(Exception ex) {
            System.debug('Exception in SyncIssueLogger====>'+ex.getMessage());
        }
    }
    
    /**********
     * @Method Name:resetSyncIssueLogger
     * @Parameters:(Id WorkorderId)
     * @Description:    This method will update D3_Sync_Issue__c as false on WorkOrder as well ServiceAppointment. 
     *                      
     * **********/


    public static void resetSyncIssueLogger(Set<Id> woId){
    
        List<WorkOrder> woRecs = [select id, D3_Sync_Issue__c from WorkOrder where Id = :woId];
        for (WorkOrder wo : woRecs){
            wo.D3_Sync_Issue__c = false;
        }
        update woRecs;
        
        List<ServiceAppointment> saList = [Select id,D3_Sync_Issue__c from ServiceAppointment where ParentRecordId = :woId ];
        for (ServiceAppointment sa : saList){
            sa.D3_Sync_Issue__c = false;    
        }
        update saList;
    
    }

    
}