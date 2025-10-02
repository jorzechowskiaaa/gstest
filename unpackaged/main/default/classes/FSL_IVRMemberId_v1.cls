/**
 * @File Name          : FSL_IVRMemberId_v1.cls
 * @Description        : Lookup by membership Id which is DIFFERENT from MemberValidationLookup.
 * @Author             :
 * @Group              :
 * @Last Modified By   : Rajesh Kemisetti
 * @Last Modified On   : 5/1/2020, 2:27:04 PM
 * @Modification Log   :
 * Ver       Date           Author                 Modification
 * 1.0    04/09/2019        Masood Mahmood         Initial Version
**/

@RestResource(UrlMapping = '/calls/searchByMemberId/*')
global with sharing class FSL_IVRMemberId_v1 {

    @HttpPost
    global static List<FSL_ClearJsonWorkOrder> getContact() {
        String webServiceEndpoint = 'searchByMemberId';
        FSL_IVRMemberId_v1.MemberRequestWrapper requestWrapper = new FSL_IVRMemberId_v1.MemberRequestWrapper();
        FSL_ClearJsonWorkOrder.ResponseWrapper respWrap = new FSL_ClearJsonWorkOrder.ResponseWrapper();
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        List<Contact> contacts;
        String memberNo;
        String transactionID;
        FSL_ClearJsonWorkOrder clearJSONwrapper = new FSL_ClearJsonWorkOrder();
        List<FSL_ClearJsonWorkOrder> clearJSONwrapperList = new List<FSL_ClearJsonWorkOrder>();
        String bulkCallIds = '';
        Map<Id, WorkOrder> workOrderMap; 
        Boolean callLog = false;

        try {
            requestWrapper = (FSL_IVRMemberId_v1.MemberRequestWrapper)
                            JSON.deserialize(request.requestBody.toString(), FSL_IVRMemberId_v1.MemberRequestWrapper.class);
            
            transactionID = requestWrapper.transactionID;
            memberNo = requestWrapper.memberId.replaceAll('[^0-9]', '');//just keep the numbers
            contacts = [SELECT Id, Member_Card_Num__c FROM Contact WHERE Member_Card_Num__c = :memberNo];
            if (contacts.size() > 1) {
                clearJSONwrapper.statusDescription = FSL_ApexConstants.IVR_FAILED_RESPONSE_TOO_MANY_MEMBERS + memberNo;
                clearJSONwrapper.statusCode = 400;
                clearJSONwrapper.memberId = memberNo;
                respWrap.statusDescription = clearJSONwrapper.statusDescription;
                respWrap.statusCode = clearJSONwrapper.statusCode; 
                FSL_ApplicationLogCreator.IVRLookupLogger(memberNo, JSON.serializePretty(respWrap), false, bulkCallIds, webServiceEndpoint, '', respWrap.statusDescription);
                callLog = true;
            } else if (contacts.size() < 1) {
                clearJSONwrapper.statusDescription = FSL_ApexConstants.IVR_FAILED_RESPONSE_NO_MEMBER_FOUND + memberNo;
                clearJSONwrapper.statusCode = 404;
                clearJSONwrapper.memberId = memberNo;
                respWrap.statusDescription = clearJSONwrapper.statusDescription;
                respWrap.statusCode = clearJSONwrapper.statusCode;             
                FSL_ApplicationLogCreator.IVRLookupLogger(memberNo, JSON.serializePretty(respWrap), false, bulkCallIds, webServiceEndpoint, '', respWrap.statusDescription);
                callLog = true;
            } else { //Only one member found - Happy path. Continue getting the WO & details if the unique member is found
                workOrderMap = new Map<Id, WorkOrder>([ SELECT Id, Call_Date__c, Call_Id__c, External_Id__c FROM WorkOrder
                                                    WHERE ContactId IN:contacts AND Status NOT IN ('Cleared', 'Canceled')]);
                if (!workOrderMap.isEmpty()) {
                    clearJSONwrapperList = FSL_ToD3Clear.clearedWorkOrders(workOrderMap.keySet(), false, 'IVRLookup');
                    clearJSONwrapper.statusCode = 200;
                    clearJSONwrapper.memberId = memberNo;
                    //nullifyRequestAttributes(clearJSONwrapper);
                    respWrap.statusCode = clearJSONwrapper.statusCode;                        
                    for (WorkOrder workOrder : workOrderMap.values()) {
                        bulkCallIds += workOrder.Call_Id__c + ', ';
                    }                 
                }else{
                    clearJSONwrapper.statusCode = 204;
                    clearJSONwrapper.statusDescription =  'No active workorders found';
                    clearJSONwrapper.memberId = memberNo;
                    respWrap.statusCode = clearJSONwrapper.statusCode;
                    respWrap.statusDescription = clearJSONwrapper.statusDescription;
                }
            }
            clearJSONwrapperList.add(clearJSONwrapper);
            if(callLog == false){
            	FSL_ApplicationLogCreator.IVRLookupLogger(memberNo, JSON.serializePretty(respWrap), false, bulkCallIds, webServiceEndpoint, FSL_ApexConstants.IVR_SUCCESS_RESPONSE + memberNo, '');
            }
        } catch (Exception e) {
            clearJSONwrapper.statusDescription = e.getMessage();
            clearJSONwrapper.statusCode = 500;   
            clearJSONwrapper.memberId = memberNo;
            respWrap.statusDescription = clearJSONwrapper.statusDescription + ' '+e.getStackTraceString() ;
            respWrap.statusCode = clearJSONwrapper.statusCode; 
             clearJSONwrapperList.add(clearJSONwrapper);
            FSL_ApplicationLogCreator.IVRLookupLogger(memberNo, JSON.serializePretty(respWrap), true, bulkCallIds, webServiceEndpoint, '', 'Exception: ' + respWrap.statusDescription);
        }finally{
            // build header for response
            headerBuilder(clearJSONwrapper, transactionID);
        }
        return clearJSONwrapperList;
    }
    
    /*public static void nullifyRequestAttributes(FSL_ClearJsonWorkOrder jsonWorkOrder){
        jsonWorkOrder.version = null;
        jsonWorkOrder.targetSystem = null;
        jsonWorkOrder.sourceSystem = null;
        jsonWorkOrder.subType = null;
        jsonWorkOrder.status = null;
        jsonWorkOrder.sourceSystem = null;
        jsonWorkOrder.requestEventType = null;
        jsonWorkOrder.id = null;
        jsonWorkOrder.createDate = null;
    }*/

    global class MemberRequestWrapper{
        public String transactionId {get;set;}
        public String memberId {get;set;}
    }

    public static FSL_ClearJsonWorkOrder headerBuilder(FSL_ClearJsonWorkOrder jsonWorkOrder, String transactionID){
        FSL_ClearJsonWorkOrder.HeaderWrapper headerWrap = new FSL_ClearJsonWorkOrder.HeaderWrapper();
        headerWrap.id = transactionID;
        headerWrap.type = 'IVR';
        headerWrap.subType = 'MemberID';
        headerWrap.status = 'UNUSED';
        headerWrap.version = '';        
        jsonWorkOrder.header = headerWrap;
        return jsonWorkOrder;
    }    

/*
    global class MemberResponseWrapper {
        public String statusDescription {get;set;}
        public Integer statusCode {get;set;}
        public String subTypeCode {get;set;}
        public String status {get;set;}
        public String version {get;set;}
        public String createDate {get;set;}
        public FSL_ClearJsonWorkOrder.SourceSystem sourceSystem {get;set;}
        public FSL_ClearJsonWorkOrder.SourceSystem targetSystem {get;set;}
        public List<FSL_ClearJsonWorkOrder.Calls> calls {get;set;}
    }
*/

}