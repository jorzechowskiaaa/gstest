/*
     * @description: To call RSP API from Case Trigger
     * @date: Mar 08, 2024 
     * @author: Salesforce Services
*/ 
    
public class INTRSPQueuable implements Queueable {
    private String caseID;
    private String woID;

    public INTRSPQueuable(String caseID, String woID){
        this.caseID = caseID;
        this.woID = woID;
    }

    public void execute(QueueableContext context) {
        if(!Test.isRunningTest()){
            FSL_INTRepairShopOutbound.generateRepairShopRequest(this.caseID,this.woID);
        }    
    }
}