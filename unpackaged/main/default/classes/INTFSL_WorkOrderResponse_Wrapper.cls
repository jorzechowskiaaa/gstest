/**** Apex Class Name    :    INTFSL_WorkOrderResponse_Wrapper
    * Description        :    This  is wrapper class for  for Intake Work Order API  
    * Modification Log   :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri               Sep 2 2021             Created
*********************************************************************************/
global without sharing class INTFSL_WorkOrderResponse_Wrapper {
    public HEADER header;
    public String statusCode{get;set;}
    public String statusDescription{get;set;}
    public string workOrderNumber{get;set;}  
    public string WorkOrderId{get;set;}
    public string CaseId{get;set;}
    public string genesysConversationId{get;set;}
    public String callDate{get;set;}
    public String callId{get;set;}
    public String externalId{get;set;}
    public String timezone{get;set;}
    public Integer PtaMinutes{get;set;}
    public string PtaLocal{get;set;}
    public string PtaUTC{get;set;}
    public List<slotDetails> ListOfSlots{get;set;}
    public class slotDetails{
       public String startTime{get;set;}
       public String finishTime{get;set;}
    }
    public class HEADER{
        public string id{get;set;}
        public string type{get;set;}
    }
}