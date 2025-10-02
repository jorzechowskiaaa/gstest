public inherited sharing class ACG_UtilityClass {
    
    public static final Id CUSTOMER_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId();
    public static final Id MEMBER_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
    //public static final Id HOUSEHOLD_ACCOUNT_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
    public static final Id FACILITY_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
	public static final Id REPAIRSHOP_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_AAR').getRecordTypeId();
    
    
    /*public static final Id CASE_CALL_ADJUSTMENT_RECORDTYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_Call_Adjustment').getRecordTypeId();
    public static final Id ERS_PAYMENT_CALL_RECORDTYPE_ID = Schema.SObjectType.ERS_Payment__c.getRecordTypeInfosByDeveloperName().get('Call_Payment').getRecordTypeId();
    public static final Id ERS_PAYMENT_CALL_ADJUSTMENT_RECORDTYPE_ID = Schema.SObjectType.ERS_Payment__c.getRecordTypeInfosByDeveloperName().get('Call_Adjustment').getRecordTypeId();
	public static final Id ERS_PAYMENT_FACILITY_ADJUSTMENT_RECORDTYPE_ID = Schema.SObjectType.ERS_Payment__c.getRecordTypeInfosByDeveloperName().get('Facility_Adjustment').getRecordTypeId();
    public static final Id ERS_PAYMENT_REIMBURSEMENT_RECORDTYPE_ID = Schema.SObjectType.ERS_Payment__c.getRecordTypeInfosByDeveloperName().get('Reimbursement_Payment').getRecordTypeId();*/
    
    public static final Id RECIPROCAL_FEEDBACK_RECORDTYPE_ID = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Feedback').getRecordTypeId();
    public static final Id RECIPROCAL_INBOUND_RECORDTYPE_ID = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Inbound_Payment_Requests').getRecordTypeId();
    public static final Id RECIPROCAL_OUTBOUND_RECORDTYPE_ID = Schema.SObjectType.Reciprocal__c.getRecordTypeInfosByDeveloperName().get('Outbound_Payment_Requests').getRecordTypeId();
    
    public static Map<String, ERS_Club_Mapping__mdt> getClubMappingByCommcenter(){
        Map<String, ERS_Club_Mapping__mdt> mapClubMapping = new Map<String, ERS_Club_Mapping__mdt>();
        for(ERS_Club_Mapping__mdt cm : [SELECT Comm_Center__c, 
                                        Club_Code__c, 
                                        Club_Name__c,
                                        Dispatcher_Code__c
                                        FROM ERS_Club_Mapping__mdt where Comm_Center__c != null]){
                                            mapClubMapping.put(cm.Comm_Center__c, cm);
                                        }
        return mapClubMapping;
    }
    
    public static Map<String, String> getClubMappingByCode(){
        Map<String, String> mapClubNameByCode = new Map<String, String>();
        for(ERS_Club_Mapping__mdt cm : [SELECT Club_Code__c, 
                                        Club_Name__c
                                        FROM ERS_Club_Mapping__mdt where Club_Code__c != null  ]){
                                            mapClubNameByCode.put(cm.Club_Code__c, cm.Club_Name__c);
                                        }
        return mapClubNameByCode;
    }
    
    public static Map<String, String> getFieldNameByProductID(){
        Map<String, String> mapFieldNameByProductID = new Map<String, String>();
        for(mapFieldNamebyProductId__mdt cm : [SELECT  Product_Id__c,
                                               Field_Name__c
                                               FROM mapFieldNamebyProductId__mdt where Product_Id__c != null]){
                                                   mapFieldNameByProductID.put(cm.Product_Id__c, cm.Field_Name__c);
                                               }
        return mapFieldNameByProductID;
    }
    
    public static Map<String, String> getCodeByState(){
        Map<String, String> mapCodeByState = new Map<String, String>();
        for(State_Code_Mapping__mdt sc : [SELECT State__c,
                                          Code__c
                                          FROM State_Code_Mapping__mdt where State__c != null]){
                                              mapCodeByState.put(sc.State__c.toLowerCase(), sc.Code__c);
                                          }
        return mapCodeByState;
    }
    
    public static String getTimeBand(DateTime dispatchedDateTime){
        String timeBandLabel = '';
        for(Time_Of_Day_Mapping__mdt timeBand : [SELECT Id, 
                                                 MasterLabel, 
                                                 Start_Time__c, 
                                                 End_Time__c 
                                                 FROM Time_Of_Day_Mapping__mdt where MasterLabel != null]){
                                                     Time startTime = time.newInstance(Integer.valueOf(timeBand.Start_Time__c.split(':')[0]),Integer.valueOf(timeBand.Start_Time__c.split(':')[1]),0,0);
                                                     Time endTime = time.newInstance(Integer.valueOf(timeBand.End_Time__c.split(':')[0]),Integer.valueOf(timeBand.End_Time__c.split(':')[1]),0,0);
                                                     if(startTime <= dispatchedDateTime.time() && endTime > dispatchedDateTime.time()){
                                                         timeBandLabel = timeBand.MasterLabel;
                                                         break;
                                                     }
                                                 }
        return timeBandLabel;
    }
}