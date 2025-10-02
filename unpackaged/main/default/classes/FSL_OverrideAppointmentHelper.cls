public without sharing class FSL_OverrideAppointmentHelper{

    public WorkOrder wrkOrder { get; set; }
    public Id overrideUserId = UserInfo.getUserId();
    
    public FSL_OverrideAppointmentHelper(){
        ID saID = ApexPages.currentPage().getParameters().get('id');
        
        
        ServiceAppointment apptWO = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id =: saID];
           System.debug('The service appointment id is :' + apptWO);
   
        wrkOrder = [select Id, Manual_Override_Reason__c, Overridden_By__c FROM WorkOrder WHERE Id =:apptWO.ParentRecordId];
        System.debug('The work order id is : ' + wrkOrder);     
    }

    public PageReference save() {
        System.debug('The wrkOrder is :' + wrkOrder);
        wrkOrder.Overridden_By__c = overrideUserId;
        update wrkOrder;
        return null;
    }
    
}