public class FSL_PartialLookupWrapper {
    @AuraEnabled
    public List<FSL_MemberDetailsWrapper> members{get;set;} 
    @AuraEnabled
    public String status {get;set;}
    @AuraEnabled
    public String message {get;set;}

}