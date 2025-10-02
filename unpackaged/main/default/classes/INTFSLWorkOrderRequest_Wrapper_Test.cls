@isTest
public class INTFSLWorkOrderRequest_Wrapper_Test {
	@isTest
    static void test1(){
        Test.startTest();
        List<INTFSLWorkOrderRequest_Wrapper> jsonParserList = new List<INTFSLWorkOrderRequest_Wrapper>();    
        string body = '{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}';
        jsonParserList  =  INTFSLWorkOrderRequest_Wrapper.parse(body);
        Test.stopTest();
        system.assertEquals(1,jsonParserList.size()); 
    }
   	@isTest
    static void test2(){
        Test.startTest();
        List<INTFSLWorkOrderRequest_Wrapper> jsonParserList = new List<INTFSLWorkOrderRequest_Wrapper>();    
        string body = '[{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}},{\"memberNumber\":4299941234757815,\"pacesetterCode\":\"\",\"IssueType\":\"Flat Tire\",\"policy\":\"\",\"priority\":\"Normal\",\"OperationType\":\"CaseCreation\",\"channel\":\"IVR\",\"callType\":\"IVR\",\"callId\":\"40004\",\"callStatus\":\"\",\"CaseId\":\"\",\"hasSpareTire\":\"Has Spares\",\"lockedOutType\":\"\",\"typeOfFuel\":\"\",\"numberOfPassengers\":1,\"userId\":\"SAIVR\",\"SlotStartDateTime\":\"\",\"SlotEndDateTime\":\"\",\"WorkorderID\":\"\",\"comments\":[],\"contactInformation\":{\"firstName\":\"THOMAS1\",\"lastName\":\"CARDELLA1\",\"telephoneNumber\":\"6129105371\",\"smsOptIn\":true,\"callBackType\":\"TX\",\"callBackMinutes\":30}}]';
        jsonParserList  =  INTFSLWorkOrderRequest_Wrapper.parse(body);
        Test.stopTest();
        system.assertEquals(2,jsonParserList.size()); 
    }
}