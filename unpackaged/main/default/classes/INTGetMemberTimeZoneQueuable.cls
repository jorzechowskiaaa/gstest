/*
     * @description: To call Google API from Case Trigger
     * @date: Mar 28, 2024 
     * @author: Salesforce Services
*/ 

public class INTGetMemberTimeZoneQueuable implements Queueable {
    private List<String> caseIds;

    public INTGetMemberTimeZoneQueuable(List<String> caseIds){
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
        if(!Test.isRunningTest()){
            ACG_CaseTriggerService.getTimezoneFromMemberLocation(caseIds);
        }    
    }
}