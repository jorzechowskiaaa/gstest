@RestResource(UrlMapping = '/call/*')
global with sharing class RestApi_PatchCall{


    @HttpPatch
    global static RestResponse_PatchCall patchCall(){
        RestRequest req = RestContext.request;
        RestResponse response = RestContext.response;

        RestApi_PatchCall  restApiPatchCall = new RestApi_PatchCall();

        ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService = new ThirdPartyIntegration.Factory().createService();
        FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLog.Factory().createService();

        return restApiPatchCall.processPatchCallRequest(req, response, thirdPartyIntegrationService, logService);

    }

    @TestVisible
    private RestResponse_PatchCall processPatchCallRequest(RestRequest req, RestResponse response, 
                                                           ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService,
                                                           FSL_ApplicationLog.IApplicationLogService logService ) {

        PatchCallRequest patchCallRequest = null;
        PatchCallResponse  patchCallResponse = new PatchCallResponse(200, 'Success', 'Status Change', null);

        try{
            patchCallRequest = (PatchCallRequest)JSON.deserialize(req.requestBody.toString(), PatchCallRequest.class);
            patchCallResponse = thirdPartyIntegrationService.processThirdPartyRequestToUpdateCall(patchCallRequest);
        } catch (JSONException ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 400;
            patchCallResponse.status = 'Invalid JSON Payload';
            patchCallRequest = new PatchCallRequest();
        } catch (FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 404;
            patchCallResponse.status = 'Did not find the call to be updated';
        } catch (FSL_WorkOrder.InvalidCommonUpdatePayloadException ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 400;
            patchCallResponse.status = ex.getMessage();
        } catch (FSL_WorkOrder.UpdateWorkOrderDMLException ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 500;
            patchCallResponse.status = 'Internal DML Error, while updating the call';
        } catch (FSL_WorkOrder.UpdateWorkOrderException ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 500;
            patchCallResponse.status = 'Internal Error, while  updating the call' +  ex.getMessage();
        } catch (Exception ex){
            patchCallResponse.exceptionThrown = ex;
            patchCallResponse.statusCode = 500;
            patchCallResponse.status = 'Internal Error on updating the call: ' + ex.getMessage();
        }
        response.statusCode = patchCallResponse.statusCode;
        return LogAndConstructResponse(req.requestBody.toString(), patchCallRequest, patchCallResponse, logService);
    }

    @TestVisible
    private RestResponse_PatchCall LogAndConstructResponse(String requestBody, PatchCallRequest patchCallRequest, 
                                                           PatchCallResponse patchCallResponse,  FSL_ApplicationLog.IApplicationLogService logService ) {

        Boolean errorCaught = ( patchCallResponse.exceptionThrown != null);
        String logMessage = patchCallResponse.status;

        RestResponse_PatchCall resPatchCall = null;
        CommonUpdateLog appLog = new CommonUpdateLog();
        if ( errorCaught ) {
            if ( patchCallRequest == null ) {
                patchCallRequest = new PatchCallRequest();
            }
            resPatchCall = RestResponse_PatchCall.constructErrorResponse(patchCallResponse.statusCode, patchCallResponse.status);
            logMessage = patchCallResponse.exceptionThrown.getMessage() + ' at ' + patchCallResponse.exceptionThrown.getLineNumber() + ', Details: ' + patchCallResponse.exceptionThrown.getStackTraceString();
            appLog.logFailure(patchCallRequest, logMessage, patchCallResponse.thirdPartyCallUpdateType, requestBody);
        }
        else {
            resPatchCall =  RestResponse_PatchCall.constructSuccessResponse(logMessage, patchCallResponse.callStatus);
            respatchCall.callInfo.callKey = patchCallRequest.callInfo.callKey;
            appLog.logSuccess(patchCallRequest, logMessage, patchCallResponse.thirdPartyCallUpdateType);
        }

        List<CommonUpdateLog> lstLogs = new List<CommonUpdateLog>();
        lstLogs.add(appLog);
        logService.saveApplicationLogs(lstLogs);

        return resPatchCall;
    }

    

     /********************************************************************************
     * PatchCallResponse Schema Description
    *********************************************************************************/
    public class PatchCallResponse {
        public Integer statusCode;
        public String  status;
        public String thirdPartyCallUpdateType;
        public Exception exceptionThrown = null;
        public string callStatus;

        public PatchCallResponse(Integer statusCode, String status, String thirdPartyCallUpdateType, Exception exceptionThrown) {
            this.statusCode = statusCode;
            this.status = status;
            this.thirdPartyCallUpdateType = thirdPartyCallUpdateType;
            this.exceptionThrown = exceptionThrown;
        }
    }

    /********************************************************************************
     * PatchCallRequest Schema Description
    *********************************************************************************/
    public class PatchCallRequest {
        public RequestHeader requestHeader;
        public MemberContactInfo memberContactInfo;
        public ERSCallInfo callInfo;
        public ServiceDetail requestedService;
        public Vehicle vehicle;
        public Location breakdownLocation;
        public Location towDestination;
        public List<RoadsideAssistanceDetail> roadsideAssistanceDetail = new List<RoadsideAssistanceDetail>();
        public ServiceStatus serviceStatus; 
    }
    public class Address {

        public String streetNumber;
        public String streetAddress;
        public String additionalAddress;
        public String city;
        public String state;
        public String zipCode;
        public String zipPlus4;
        public String foreignCountryCode;
        public String foreignCountryName;
        public String countyCode;
        public String countyName;
        public List<String> crossStreets = null;
        public List<String> displayAddressLines = null;
        
    }
    public Enum Channel_Name{
        ARR, 
        ACG, 
        DRR, 
        IVR, 
        CTI, 
        VERINT, 
        CHATBOT, 
        TOWBOOK
    }

    public class Channel{
        public Channel_Name name;
        public List<KeyValuePair> parameters;
    }

    public class Comment{
        public String text;
        public String visibility;
        public String commentType;
        public String commentDateTime;
        public String commenter;
    }
    public class DriverData {
        public String servicingStationEmployeeName;
        public String servicingStationEmployeeId;
        public String truckId;
        public Facility facility;
        public String dispatchTime;
        public Decimal latitude;
        public Decimal longitude;
    }
    public class ERSCallInfo {
        public String callId;
        public String callDate;
        public String callKey;
        public String createdDateTimeUTC;
        public String status;
    }
    public class Facility {

    }
    public class KeyValuePair{
        public string key;
        public string value;
    }
    public class Location {
        public String code;
        public String name;
        public String latitude;
        public String longitude;
        public String mileMarker;
        public String highway;
        public String landmark;
        public Address address;
        public String instructions;
    }
    public class MemberContactInfo{
        public PersonName name;
        public PhoneNumber[] phoneNumbers;
        public MemberNumber memberNumber;
        public integer yearsAsMember;
        public String joinYear;
        public MembershipBenefitLevelType currentBenefitLevel;
    }
    public class MemberNumber{
        public string binNumber;
        public MembershipId membershipId;
        public string roleCode;
        public string cardCheckDigit;
        public string cardNumber;
    }
    public class MembershipId{
        public string clubCode;
        public string memberNumber;
    }
    public enum MembershipBenefitLevelType{
        BASIC, 
        PLUS, 
        PREMIER
    }
    public Enum OperationType{
        CreateCall, UpdateCall, CancelCall, CallMoverCall, RetrieveCall
    }
    public class Organization{
        public string code;
        public string name;
    }
    public enum OS{
        iOS, 
        Android
    }
    public class PaymentInfo{
        boolean required;
        string paymentType;
        string paymentCode;
    }
    public class PersonName{
        string nameTitle;
        string firstName;
        string middleName;
        string lastName;
        string nameSuffix;
        string formattedName;
    }
    public class PhoneNumber{
        public PhoneUsageType phoneUsageType;
        public string typeDescription;
        public string areaCode;
        public string phonePrefix;
        public string phoneSuffix;
        public string phoneExtension;
        public string displayPhoneNumber;
        public string okToCall;
        public string okToText;
    }
    public enum PhoneUsageType{
        HOME, 
        WORK, 
        MOBILE, 
        ONE_TIME, 
        OTHER, 
        UNKNOWN, 
        CAR, 
        FAX, 
        PAGER
    }
    public class RequestHeader{
        public string id;
        public string dateTimeString;
        public string operationType;
        public Channel channel;
        public string device;
        public string os;
        public Organization sourceOrg;
        public Organization targetOrg;
    }
    public class RoadsideAssistanceDetail {
        public String status;   
        public String reasonCode;
        public DriverData driverData;
        public List<Comment> comments;
        public String resolutionCode;
        public List<ServiceLineItem> ServiceLineItems = new List<ServiceLineItem>();

    }
    public class ServiceLineItem{
        public string service;
        public Integer quantity;
        public Decimal charge;     
    }  
    public Enum HasSpareTire{
        Yes, 
        No, 
        Air_Only
    }
    public Enum LockoutType{
        Locked_in_the_Vehicle, 
        Key_is_broken_or_lost, 
        Key_does_not_turn_in_the_ignition, 
        Key_does_not_nlock_the_door, 
        Keys_locked_in_trunk
    }
    public Enum TypeOfFuel{
        Gasoline, 
        Diesel, 
        Electric
    }
    public Enum ServicePriority {
        Low, Medium, High, Critical, Urgent 
    }
    public class ServiceDetail{
        public String issueType;
        public ServicePriority priority;
        public List<TroubleCode> troubleCodes = null;
        public ServiceTimeConstraints timeConstraints;
        public Integer numberOfPassengers;
        public HasSpareTire hasSparetire;
        public boolean flatBedRequested;
        public boolean flatBedRequired;
        public LockoutType lockouttype;
        public TypeOfFuel typeOfFuel;
        public string timeZoneOffset;
        public string timeZoneId;
        public List<Comment> comments = null;
    }
    public class ServiceTimeConstraints {
        public String earliestStartDateTime;
        public String requiredCompletionByDateTime;
    }
    public Enum CallStatus {
        Spotted,
        Scheduled,
        Dispatched,
        En_Route,
        On_Location,
        In_Tow,
        Tow_Completed,
        Cleared,
        Canceled
    }
    //  Some details about the overall status of the service call
    public class ServiceStatus {
        public Integer waitTimeInMinutes;
        public CallStatus status;
        public String scheduledStartTime;
        public String appointmentTime;
        public String promisedTimeOfArrival;
        public String estimatedTimeOfArrival;
        public String actualTimeOfArrival;
    }
    public class TroubleCode{
        public String type;
        public String code;
        public String description;

    }
    public class Vehicle {
        public String vehicleId;
        public Integer modelYear;
        public String makeName;
        public String modelName;
        public String color;
        public String licenseState;
        public String licenseNumber;
        public VehicleDetail vehicleDetail;
    }
    public class VehicleDetail {
        public String vin;
        public String trimLevel;
        public String bodyType;
        public String typeCategory;
        public String size;
        public String engineCylinders;
        public String engineDisplacement;
        public String engineName;
        public String driveType;
        public Integer truckTonage;
        public String symbol;
        public String evr;
        public Boolean riskType;
        public Boolean grayMarket;
        public Integer trailerLength;
        public String hitchType;
        public String rvClass;
        public Integer rvLength;
        public Integer odometer;
        public String specialEquipmentNeeds;
    }

    // *********************************************
    // * Application Log
    // *********************************************
    public class CommonUpdateLog extends FSL_ApplicationLog.ApplicationLog {
        public CommonUpdateLog() {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'PlatformEvent';
            appLog.DateTime__c = System.now();
            appLog.Api_Name__c = 'PlatformEvent';
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void setDefaultApplicationLogFields(String operation, String apiName) {
            appLog.Operation__c = operation;
            appLog.Api_Name__c = apiName;            
        }

        public void logFailure(PatchCallRequest patchCallRequest, String message, String operation, String originalRequest) {
            appLog.Api_Name__c = 'CommonUpdateCall';
            appLog.Operation__c = operation;
            appLog.Error_Caught__c = true;
            appLog.Error_Message__c = message;
            if ( patchCallRequest != null && patchCallRequest.callInfo != null ) {
                applog.call_Id__c = patchCallRequest.callInfo.callKey;
                appLog.Request_Body__c = JSON.serialize(patchCallRequest); 
            }
            else {
                appLog.Request_Body__c = originalRequest;
            }
            
        }

        public void logSuccess(PatchCallRequest patchCallRequest, String message, String operation) {
            appLog.Api_Name__c = 'CommonUpdateCall';
            appLog.Operation__c = operation;
            appLog.Error_Caught__c = false;
            appLog.Success_Message__c = message;
            applog.call_Id__c = patchCallRequest.callInfo.callKey;
            appLog.Request_Body__c = JSON.serialize(patchCallRequest); 
        }
    }

}