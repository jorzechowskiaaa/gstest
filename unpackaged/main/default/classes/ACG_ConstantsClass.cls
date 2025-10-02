/************************************************************************************
Apex Class Name     : ACG_ConstantsClass
Created Date        : 9th August 2021
Function            : Constant Class 
Author              : Deloitte Consulting 
**************************************************************************************/
public class ACG_ConstantsClass {
    public static final String ProductBR = 'BA';
    public static  Boolean isManager = false;
    public static final String QUEUE_STRING = 'Queue';
    public static final String ACG_ESCALATED_REQUESTS_STRING = 'ACG_Escalated_Requests';
    public static final String TIER_2_ESCALATED_STRING = 'Tier 2 Escalated';
    public static final String BLANK_SUBJECT_STRING = 'Escalation summary is required for case escalation';
    public static final String BLANK_STRING = '';
    public static final String DECISION_APPROVED_STRING = 'Decision Approved';
    public static final String DECISION_SUBMITTED_STRING = 'Decision Submitted';
    public static final String TIER_2_REIMBURSEMENT_SUPPORT_GRP_STRING = 'Tier 2 Member Reimbursement Support';

    // ACG_Facility_Adjustment__c Object
    public static final String ACG_FACILITY_ADJUSTMENT_ADJUSTMENT_TYPE_CREDIT = 'Credit';
    public static final String ACG_FACILITY_ADJUSTMENT_ADJUSTMENT_TYPE_DEBIT = 'Debit';
    public static final String ACG_FACILITY_ADJUSTMENT_STATUS_NEW = 'New';
    public static final String ACG_FACILITY_ADJUSTMENT_STATUS_ACTIVE = 'Active';

    // ACG_Facility_Adjustment_Payment__c Object
    public static final String ACG_FACILITY_ADJUSTMENT_PAYMENT_PAID = 'Paid';
    public static final String ACG_FACILITY_ADJUSTMENT_PAYMENT_STATUS_NEW = 'New';
    public static final String ACG_FACILITY_ADJUSTMENT_PAYMENT_STATUS_READY_FOR_PROCESSING = 'Ready for Processing';


    public static final String ACG_PAYMENT_STATUS_PAYMENT_PROCESSED = 'Payment Processed';

    public static final String ACG_REIMBURSEMENT_STATUS_COMPLETED = 'Completed';
    public static final String COLON_String = ':';
    public static final String YOU_CAN_LOOK_UP_EXCEPTIONCODE_STRING = 'You can look up ExceptionCode';
    public static final String SEMICOLON_STRING = ';';
    
    public static final Set<String> NONABJUSTABLE_PRODUCTS = new Set<String>{'Tow Mileage', 'Enroute Mileage'};
        
    public static final String CASE_PENDING_STATUS = 'Pending';
    public static final String REIMBURSEMENT_DECISION_APPROVED_STRING = 'Approved';
    public static final String REIMBURSEMENT_DECISION_PARTIALLY_APPROVED_STRING = 'Partially Approved';
    public static final String REIMBURSEMENT_STATUS_PAYMENT_PROCESSING_STRING = 'Payment Processing';

    public static final String ERS_PAYMENT_STATUS_READY_FOR_PAYMENT_STRING = 'Ready for Payment';
    
    // ERS Payment Line Item
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_BASIC = 'Basic';
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_PREMIER = 'Premier';
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_PLUS = 'Plus';
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_RV = 'RV';
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_PLUSRV = 'Plus RV';
    public static final String ERS_PAYMENT_LINE_ITEM_MEMBERSHIP_LEVEL_PREMIERRV = 'Premier RV';

    public static final String CASE_APPROVED_STATUS = 'Approved';
    public static final String CASE_DENIED_STATUS = 'Denied';
    public static final String CASE_PARTIALLY_APPROVED_STATUS = 'Partially Approved';
    
    public static final String BASE_RATE_PRODUCT_CODE = 'BA';
    public static final Set<String> MILEAGE_PRODUCT_CODES = new Set<String>{'TW', 'OM'};
        
    public static final String CASE_CLOSED_STATUS = 'Closed';
    
    //Intake Workorder API
    public static final string CASE_CREATION ='CaseCreation';
    public static final string CASE_UPDATE ='CaseUpdate';
    public static final string IMMEDIATE_APPOINTMENT ='ImmediateAppointment';
    public static final string GET_SLOTS ='GetSlots';
    public static final string CANCEL ='Cancel';
    public static final string UPDATE_SERVICE_APPOINTMENT ='Update Service appointment';
    public static final string CALL_MOVER = 'callMover';
    public static final string INVALID_REQUEST ='Invalid Request';
    public static final string WORK_ORDER_STATUS_CANCELED = 'Canceled';
    public static final string MEMBERSHIP_STATUS_CANCELLED = 'Cancelled';
    public static final string SERVER_ERROR ='An internal server error has occured';
    public static final string CASE_STATUS_CANCELED = 'Closed - Customer Canceled';
    public static final string CASE_CANCEL_MSG ='Successfully Canceled Case';
    public static final string DRR_VEHICLE_TYPE = 'PS (Passenger Car/Truck)';
    public static final string CASE_WORK_ORDER_CREATION_STATUS = 'Work Order In Progress';
    
    public static final String CASE_EVENT_TYPE_ACCIDENT_ASSIST ='Accident Assist';
    public static final String CASE_EVENT_TYPE_RAP ='RAP';
    public static final String COMM006 ='006';
    public static final String COMM111 ='111';
    public static final String DEPTID ='COL022';
    public static final String STATECOLORADO ='CO';
    public static final String STATECOLORADONAME ='COLORADO';    
    public static final String COBU = '65000';
    public static final String COBU1 = '66000';
    public static final String CASE_EVENT_TYPE_MEMBER ='MEMBER';
    
    public static final String STATUSVAL = 'Ready for Payment';
	public static final String TDAY = 'Tuesday';
	public static final String THDAY = 'Thursday';
    public static final String STATUSVALP = 'Payment Processed';
    public static final String PDFName = 'NONA Pay Statements-';
    
    
    //Transaction Types
    public static final String TRANSACTION_TYPE_PAY ='PAY';
    public static final String TRANSACTION_TYPE_ACP ='ACP';
    public static final String TRANSACTION_TYPE_ERR ='ERR';
    public static final String TRANSACTION_TYPE_DSP ='DSP';
    
    //Reciprocal Status
    public static final String STRING_STATUS ='Status';
    public static final String RECIPROCAL_STATUS_NEW ='New';
    public static final String RECIPROCAL_STATUS_APPROVED ='Approved';
    public static final String RECIPROCAL_STATUS_DISPUTED ='Disputed';
    public static final String RECIPROCAL_STATUS_REBILLED ='Rebilled';

    // Reciprocal Problem Codes
    public static final String RECIPROCAL_PROBLEM_CODE_P0 = 'P0 - Multiple reasons';
    public static final String RECIPROCAL_PROBLEM_CODE_P1 = 'P1 - Total charges are either less than $5 or greater than $500';
    public static final String RECIPROCAL_PROBLEM_CODE_P2 = 'P2 - Classic Member with Plus/RV/Premier charges';
    public static final String RECIPROCAL_PROBLEM_CODE_P4 = 'P4 - Multiple records for same member/same day';
    public static final String RECIPROCAL_PROBLEM_CODE_P5 = 'P5 - Overentitlements';
    public static final String RECIPROCAL_PROBLEM_CODE_P6 = 'P6 - Name does not match member ID';
    public static final String RECIPROCAL_PROBLEM_CODE_P8 = 'P8 - Invalid Member ID';
    public static final String RECIPROCAL_PROBLEM_CODE_P9 = 'P9 - Service Date is after expiration date';
    public static final String RECIPROCAL_PROBLEM_CODE_PC = 'PC - Authorization code missing from reciprocal record.';
    public static final String RECIPROCAL_PROBLEM_CODE_PD = 'PD - Authorization code missing from local call record.';
    public static final String RECIPROCAL_PROBLEM_CODE_PE = 'PE - Servicing club does not match authorization record.';
    public static final String RECIPROCAL_PROBLEM_CODE_PF = 'PF - Member ID does not match authorization record.';
    public static final String RECIPROCAL_PROBLEM_CODE_PG = 'PG - Member club does not match authorization record.';
    public static final String RECIPROCAL_PROBLEM_CODE_PH = 'PH - Feedback record does not exist.';

    // Reciprocal Membership type
    public static final string RECIPROCAL_MEMBERSHIP_TYPE_BASIC = 'BAS';
    
    //CTI Flow
    public static final string ERS_ADVOCATE_FLOW = 'ERS Advocate Flow';
    public static final string ERS_DISPATCH_FLOW = 'ERS Dispatch Flow';
    public static final string TRAVEL_FLOW = 'Travel Flow';
    public static final string INSURANCE_FLOW = 'Insurance Flow';
    public static final string MEMBERSHIP_FLOW = 'Membership Flow';
    
    public static final String ERS_PAYMENT_STATUS_PAUSED = 'Paused';
    
    public static final String QUEUE_ACCIDENT_ASSIST_PAYMENTS = 'Accident_Assist_Payments';
    public static final String WO_CALL_TYPE_ACCIDENT_ASSIST = 'Accident Assist';
    public static final String WO_STATUS_CLEARED = 'Cleared';
    
    //Ledger Account Map
    public static final Map<String, String> mapLedgerAccount = new map<String, String>{
        'B' => 'BAS',
        'J' => 'BAS',
            'P' => 'PLS',
            'E' => 'PRM',
            'R' => 'PLR',
            'V' => 'PRR'
            };
                
    public static final String COST_BUFFER_BONUS = 'BON';
    
    public static final String FSL_CONTRACTOR_DISPATCHER_ACCESS = 'FSL Contractor Dispatcher Access';
    public static final String CALL_ADJUSTMENT = 'Call Adjustment';
    public static final String CALL_PAYMENT = 'Call';
  // Account
  public static final String FLEET = 'FLT';
     public static final String PSP = 'PSP';
     public static final String CON = 'CON';
     public static final String PRP = 'PRP';
    public static final String AUX = 'AUX';
     public static final String BCN = 'BCN';
    public static final String BAC = 'BAC';
     public static final String BACBACKUP = 'BAC  Backup Contractor';
     public static final String PSPRURAL= 'PSPRURAL  Rural PSP Facility';
     public static final String BCNBONUS = 'BCN  Bonus Contractor';
     public static final String NONA = 'NONA  Non-Contracted Facilities';
    
    // Integration - AXIS Trip Intake Constants
    public static final String STATUS_CODE_200 = '200';
    public static final String WEB = 'Web';
    public static final String AGENT = 'Agent';
    public static final String CA = 'CA';
    public static final String BAD_REQUEST = 'Bad Request';
    public static final String STATUS_CODE = '400';
    public static final String ERROR_MESSAGE = 'Invalid Request Body';
    public static final String SUCCESS = 'Success';
    public static final String FAILURE = 'Failure';
    public static final String ERROR_MESSAGE_NO_TRAVELER = 'No traveler record exist on Trip';
    public static final String TRIPINTAKE = 'TripIntake';
    public static final String TRIPINTAKEAPI = 'TripIntakeAPI';
    public static final String TRIP = 'trip';
    public static final String TRIP_NUMBER = 'number';
    public static final String STAGE_NAME = 'Closed Won';
    public static final String TRAVEL_OPPORTUNITY = 'Travel Opportunity';
    public static final String ACG_TRAVEL_OPPORTUNITY = 'ACG_Travel_Opportunity';
    public static final String ACCOUNT = 'Account';
    public static final String CUSTOMER = 'Customer';
    public static final String CANCELLED_FLAG_Y = 'Y';
    public static final String UC = 'UC';
    public static final String UNCONFIRMED = 'unconfirmed';
    public static final String VO = 'VO';
    public static final String VOIDED_TICKET = 'voided ticket';
    public static final String AP = 'AP';
    public static final String ADJUSTMENT_PENDING = 'adjustment pending';
    public static final String CANCELED = 'canceled';
     public static final String EE = 'EE';
    public static final String EVEN_EXCHANGE = 'even exchange';
     public static final String C = 'C';
    public static final String CONFIRMED = 'confirmed';
     public static final String E = 'E';
    public static final String IN_ERROR = 'in error';
     public static final String O = 'O';
    public static final String OPTION = 'option';
     public static final String OB = 'OB';
     public static final String P = 'P';
    public static final String FULLY_PAID = 'fully paid';
     public static final String Q = 'Q';
    public static final String QUOTED = 'quoted';
     public static final String R = 'R';
    public static final String REFUNDED = 'refunded';
     public static final String U = 'U';
    public static final String UNINVOICED = 'uninvoiced';
    public static final String OE = 'OE';
    public static final String OPTION_EXPIRED = 'option expired';
    public static final String NP = 'NP';
    public static final String NOT_PRICED = 'not priced';
    public static final String PI = 'PI';
    public static final String PARTIALLY_INVOICED = 'partially invoiced';
    public static final String RD = 'RD';
    public static final String REFUND_DUE = 'refund due';
    public static final String ACM = 'ACM';
    public static final String AIR_CREDIT_MEMO = 'air credit memo';
    public static final String ADM = 'ADM';
    public static final String AIR_DEBIT_MEMO = 'air debit memo';
    public static final String AIR = 'AIR';
    public static final String AIRLINE_TICKET = 'airline ticket - arc';
    public static final String AIROPT = 'AIROPT';
    public static final String AIR_OPTIONS = 'air options';
    public static final String ASF = 'ASF';
    public static final String AUTOMATED_SERVICE_FEE = 'automated service fee';
    public static final String CAR = 'CAR';
    public static final String CAR_RESERVATION = 'car reservation';
    public static final String CARPP = 'CARPP';
    public static final String CAR_RESERVATION_PREPAID = 'car reservation prepaid';
    public static final String CONS = 'CONS';
    public static final String CONSOLIDATOR = 'consolidator';
    public static final String CRU = 'CRU';
    public static final String CRUISE = 'cruise';
    public static final String GCRU = 'GCRU';
    public static final String GROUP_CRUISE = 'group cruise';
    public static final String GTUR = 'GTUR';
    public static final String GROUP_TOUR = 'group tour';
    public static final String HTL = 'HTL';
    public static final String HOTEL_RESERVATIONS = 'hotel reservations';
    public static final String HTLPP = 'HTLPP';
    public static final String HOTEL_RESERVATIONS_PREPAID = 'hotel reservations prepaid';
    public static final String INS = 'INS';
    public static final String INSURANCE = 'insurance';
    public static final String MCO = 'MCO';
    public static final String AUTOMATED_MCO = 'automated mco';
    public static final String MSF = 'MSF';
    public static final String CORPORATE_SERVICE_FEE = 'corporate service fee';
    public static final String MISC = 'MISC';
    public static final String MISCELLANEOUS_SALES = 'miscellaneous sales';
    public static final String NONARC = 'NONARC';
    public static final String NON_ARC_AIR = 'non-arc air';
    public static final String NONRAIL = 'NONRAIL';
    public static final String NON_ARC_RAIL = 'non-arc rail';
    public static final String QTOUR = 'QTOUR';
    public static final String QUICK_TOUR = 'quick tour';
    public static final String RAIL = 'rail';
    public static final String RCM = 'RCM';
    public static final String RAIL_CREDIT_MEMO = 'rail credit memo';
    public static final String RDM = 'RDM';
    public static final String RAIL_DEBIT_MEMO = 'rail debit memo';
    public static final String TRAVINS = 'TRAVINS';
    public static final String ALLIANZ_GLOBAL_ASSISTANCE = 'allianz global assistance';
    public static final String TUR = 'TUR';
    public static final String TOUR = 'tour'; 
    public static final String HOTEL = 'Hotel'; 
    public static final String MISCELLANEOUS = 'Miscellaneous'; 
    public static final String ACG_CUSTOMER = 'ACG_Customer'; 
    
    // Integration - Referral Opportunity Creation Constants
    public static final String POST_CREATE_OPPORTUNITY_API = 'POSTCreateOpportunity_API';
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String APPLICATION_JSON = 'application/json';
    public static final String INT_OPPORTUNITY_CREATION_API = 'INTOpportunityCreationAPI';
    public static final String CREATE_OPPORTUNITY = 'createOpportunity';
    public static final String ERRORCODE = 'errorCode: ';
    public static final String MESSAGE = 'message: ';
    public static final String SEMICOLON = ';';
    public static final String NOT_SYNCING_INVALID_ID = 'Not syncing because any of the record Id may not exist in CMC';
    public static final String PIPE_SYMBOL = '|';
    public static final String REFERRAL_ACCOUNT_DOESNOT_EXIST = 'ReferralAccountDoesNotExist';
    public static final String INVALID_ID = 'invalid Id';
    public static final String NEWLINE_ACCOUNT_ID = '\nAccount Id:';
    public static final String USER = 'User';
    public static final String REFERRAL_USER_DOESNOT_EXIST = 'ReferralUserDoesNotExist';
    public static final String NEWLINE_USER_ID = '\nUser Id:';
    public static final String CONTACT = 'Contact';
    public static final String REFERRAL_CONTACT_DOESNOT_EXIST = 'ReferralContactDoesNotExist';
    public static final String NEWLINE_CONTACT_ID = '\nContact Id:';
    public static final String AAA_LOCATION_C = 'AAA_Location__c';
    public static final String REFERRAL_AAALOCATION_DOESNOT_EXIST = 'ReferralAAAlocationDoesNotExist';
    public static final String NEWLINE_AAA_LOCATION_ID = '\nAAA location Id:';
    public static final String CAR_CARE_VISIT_C = 'Car_Care_Visit__c';
    public static final String REFERRAL_CARCARE_VISIT_DOESNOT_EXIST = 'ReferralCarCareVisitDoesNotExist';
    public static final String NEWLINE_CAR_CARE_VISIT_ID = '\nCar Care Visit Id:';
    public static final String ASSIGN_BY_ROUND_ROBIN_C = 'Assign_by_Round_Robin__c';
    public static final String DAYS_AVAILABLE_FOR_REFERAL_C = 'Days_Available_For_Referal__c';
    public static final String START_TIME_C = 'Start_Time__c';
    public static final String END_TIME_C = 'End_Time__c';
    public static final String PRIMARY_CONTACT_FOR_OPPORTUNITY_C = 'Primary_Contact_for_Opportunity__c';
    public static final String REFERRAL_NOTES_C = 'Referral_Notes__c';
    public static final String ROUND_ROBIN_ASSIGNMENT_GROUP_C = 'Round_Robin_Assignment_Group__c';
    public static final String CLOSEDATE = 'CloseDate';
    public static final String ACCOUNTID = 'AccountId';
    public static final String LEADSOURCE = 'LeadSource';
    public static final String NAME = 'Name';
    public static final String OWNERID = 'OwnerId';
    public static final String RECORDTYPE = 'RecordTypeId';
    public static final String STAGENAME = 'StageName';
    public static final String OPP_TYPE = 'Type';
    public static final String CAR_BUYING_REFERRAL_FEE_C = 'Car_Buying_Referral_Fee__c';
    public static final String REFERRED_FROM_BUSINESS_LINE_C = 'Referred_From_Business_Line__c';
    public static final String REFERRED_TO_LINE_OF_BUSINESS_C = 'Referred_To_Line_Of_Business__c';
    public static final String CAR_CARE_APPT_CONFIRMATION_LINK_C = 'Car_Care_Appt_Confirmation_Link__c';
    public static final String CAR_CARE_APPOINTMENT_STATUS_C = 'Car_Care_Appointment_Status__c';
    public static final String CAR_CARE_SERVICES_INTERESTED_IN_C = 'Car_Care_Services_Interested_In__c';
    public static final String LATEST_CAR_CARE_VISIT_C = 'Latest_Car_Care_Visit__c';
    public static final String SALESFORCE_SUPPORT = 'Salesforce Support';
    public static final String RECORDTYPE_SOQL = 'select+Id+from+RecordType+where+Name+=+';
    public static final String SOBJECT_TYPE = '+and+SobjectType+=+';
    public static final String OPPORTUNITY = 'Opportunity';
    public static final String SINGLE_QUOTE = '\'';
    
    // Integration - Standard GET API Constants
    public static final String GET_STANDARDRECORD_API = 'GETStandardRecord_API';
    public static final String SLASH = '/';
    public static final String INTSTANDARDGETAPI = 'INTStandardGetAPI';
    public static final String GETRECORDBYID = 'getRecordById';

    //Integration - Membership Lookup
    public static final String MEMBERSHIPLOOKUP = 'MembershipLookup';
    public static final String MEMBERSHIPLOOKUPAPI = 'MembershipLookupAPI';
    public static final String GETMEMBERSHIP_LOOKUP_API = 'GETMembership_Lookup_API';
    
    //Integration - Membership Lookup
    public static final String NatioanlRBP = 'NatioanlRBP';
    public static final String NatioanlRBPAPI = 'NatioanlRBPAPI';

    //Integration - National Close Call 
    public static final String POSTNATIOANLRBP_API = 'POSTNationalRBP_API';
    public static final String POSTNATIOANLOAUTH_API = 'POSTNational_OAuth_API';
    public static final String CLOSE_CALL_OPERATION = 'National Close Call';

    //Integration - Medallia Lookup
    public static final String ERSMedallia = 'ERSMedallia';
    public static final String ERSMedalliaAPI = 'ERSMedalliaAPI';
    public static final String POSTERSMEDALLIA_API = 'POSTERSMedallia_API';
    public static final String LANGUAGE_English = 'English';
    public static final String EMAIL_SIGNATURE_TITLE = 'AVP- Automotive Services';
    public static final String EMAIL_SIGNATURE_REGION = 'Region 1';
    public static final String FACILITY_TYPE_BICYCLE = 'Bicycle';
    public static final String MRI_SCORE = 'MRI (675-724)';
    public static final String FACILITY_TYPE_HOME_LOCKOUT = 'Home Lockout';
    public static final String CALL_ORIGIN_ACG_DRR = 'ACG DRR';
    public static final String CALL_ORIGIN_DRR = 'DRR';
    public static final String CALL_ORIGIN_IVR = 'IVR';
    public static final String ANI = 'ANI';
    public static final String CALL_RECEIVING_AGENT_ID_SAIVR = 'SAIVR';
    public static final String CALL_ORIGIN_MEMBER = 'MEMBER';
    public static final String CALL_ORIGIN_RAP = 'RAP';
    public static final String CALL_ORIGIN_ARR = 'ARR';
    public static final String TENURE_LESS_THAN_1_YEAR = 'Less than 1 year';
    public static final String TENURE_1_3_YEAR = '1 - 3 year';
    public static final String TENURE_3_5_YEAR = '3 - 5 year';
    public static final String TENURE_5_10_YEAR = '5 - 10 year';
    public static final String TENURE_MORE_THAN_10_YEAR = 'More than 10 year';
    public static final String ACG_CALL_TYPE_MEMBER = 'Member';
    public static final String RESOLUTION_CODE_X001 = 'X001';
    public static final String RESOLUTION_CODE_X002 = 'X002';
    public static final String EDI_VALUE = '3';
    public static final String CONTACT_METHOD_CALL_CENTER = 'Call Center';
    public static final String SERVICE_INITIATION_METHOD_CALL_CENTER = 'Call Center';    
    public static final String CONTACT_METHOD_ERS_ONLINE = 'ERS Online';
    public static final String SERVICE_INITIATION_METHOD_CALL_ERS_ONLINE = 'ERS Online';    
    public static final String CONTACT_METHOD_SMART_ACTION = 'Smart Action';
    public static final String SERVICE_INITIATION_METHOD_SMART_ACTION = 'Smart Action';
    public static final String CALL_RECEIVING_AGENT_ID_RSO = 'RSO';

    
    //Integration - Recent Service Provider 
    public static final String RECENTSERVICEPROVIDERSAPI = 'RecentServiceProvidersAPI';
    public static final String RECENTSERVICEPROVIDERS = 'RecentServiceProviders';
    public static final String INVALID_INPUT_FORMAT = 'INVALID_INPUT_FORMAT';
    public static final String INVALID_REQUEST_BODY = 'INVALID REQUEST BODY';
    public static final String INVALID_INPUT_DATA = 'INVALID_INPUT_DATA';
    public static final String MEMBERSHIP_FACILITY_REQUIRED = 'MembershipNumber and FacilityIds must be required';
    
    //Integration - ERS Entitlement Service 
    public static final String MEMBERSHIP_INFORMAION_NOT_FOUND = 'Membership Information not Found';
    public static final String WORKORDER_VehicleType='STREET MOTORCYCLE';
    public static final String TroubleCode_Type='PROBLEM';
    public static final String MotorCycle_N='N';
    public static final String MotorCycle_Y='Y';

    public static final String WORKORDER_RECORDTYPE_TOW = 'Tow';

    //Integration - Advisories API
    public static final String CITY = 'City';
    public static final String CITY_REQUIRED = 'City Parameter is missing in request';
    public static final String ADVISORIESAPI = 'AdvisoriesAPI';
    public static final String ADVISORIES = 'Advisories';
    public static final String ANNOUNCEMENTS_STATUS = 'Active';
    public static final String ANNOUNCEMENTS_APPROVAL_STATUS = 'Approved';

    //Integration - Vehicle Master API
    public static final String VEHICLEMASTERAPI = 'VehicleMasterAPI';
    public static final String VEHICLEMASTER = 'VehicleMaster';

    
    //Integration - Axis Launch
    public static final String SALESFORCE = 'Salesforce';
    public static final String POST_AXIS_LAUNCH_API = 'POSTAXISlaunch_API';
    public static final String AXISLAUNCH = 'axisLaunch';
    public static final String AXISLAUNCHAPI = 'INTAxisLaunchAPI';
    
    //Integration - Address Validation
    public static final String VALIDATEADDRESS = 'validateAddress';
    public static final String ADDRESSVALIDATIONAPI = 'INTAddressValidationAPI';
    public static final String POST_ADDRESS_VALIDATION_API = 'POSTAddress_Validation_API';
    
    //Integration - UpsertCustomerInPOC
    public static final String UPSERTCUSTOMER = 'upsertCustomer';
    public static final String UPSERTCUSTOMERAPI = 'INTUpsertCustomerInPOCAPI';
    public static final String POST_UPSERT_CUSTOMER_POC_API = 'POSTUpsertCustomerinPOC_API';
    public static final String TRAN_ID = 'tranId';
    public static final String TRANSACTION_ID = 'transactionId';
    public static final String RESPONSE_HEADERS = 'responseHeaders';
    public static final String TRAN_STATUS_DESCRIPTION = 'tranStatusDescription';
    public static final String ERROR = 'error';
    public static final String OK ='OK';
    public static final string NOT_FOUND = 'Not Found';
    public static final string ZERO = '0';
    public static final string ONE = '1';
    public static final string NINE = '-9';
    public static final string X = 'X';
    public static final string TEXT_POST ='TextPost';
    //Integration - Call Mover Outbound
    public static final string API_VERSION = '0.1';
    public static final string API_SUBVERSION = '0.0.1';
    public static final string CREATE = 'CREATE';
    public static final string ACG_CLUBCODE = '014';
    public static final string ACG = 'ACG';
    public static final string NaTIONAL_CLUBCODE = '311';
    public static final string CI = 'CI';
    public static final string EN = 'EN';
    public static final string CAPCUSTOMER = 'CUSTOMER';
    public static final string PERSONAL = 'PERSONAL';
    public static final string SP = 'SP';
    public static final string PACESETTER = 'PACESETTER';
    public static final string PROBLEM = 'PROBLEM';
    public static final string BREAKDOWN = 'BREAKDOWN';
    public static final string ADDRESS = 'ADDRESS'; 
    public static final string PHYSICAL = 'PHYSICAL';
    public static final string TOW_DESTINATION = 'TOW_DESTINATION';
    public static final string US = 'US';
    public static final string MEMBER = 'MEMBER';
    public static final string MEM = 'MEM';
    public static final string CLASSIC = 'Classic';
    public static final string N_A = 'N/A';
    public static final string ZEROS = '00';
    public static final string YEAR2000 = '2000';
    public static final string TWENTY = '20';
    public static final string NINETEEN = '19';
    public static final string AAA_AUTO_SOUTH_CLUB = 'AAA Auto Club South';
    public static final string IVR = 'IVR';
    public static final string HOME = 'HOME';
    public static final string WORK = 'Work';
    public static final string BUSINESS = 'BUSINESS';
    public static final string MOBILE = 'Mobile';
    public static final string CELLULAR = 'CELLULAR';
    public static final string S_HOME = 'Home';
    public static final string CAPAGENT = 'AGENT';
    public static final string CALL_CENTER = 'CALL_CENTER';
    public static final string FAX = 'Fax';
    public static final string SYSTEM_ORG_CODE ='14';
    public static final string SPOTTED ='Spotted';
    public static final string SCHEDULED ='Scheduled';
     public static final string DISPATCHED ='Dispatched';
      public static final string DISPATCH ='Dispatch';
    public static final string MEMBERID='MemberID';
    public static final string SA_TIME_DEPENCY='Start After Finish';
    public static final string MINUTES='Minutes';
    public static final string NAN='NaN';
    public static final string LOCKOUT='Lockout';
    public static final string NO_LAT_LONG='No Lat/Long';
    public static final string BLENDED_POLICY='Blended Policy';
    public static final string LANDLINE='Landline';
    public static final string IMMEDIATELY_FOLLOW='Immediately Follow';
    public static final string EDS='EDS';
    public static final string CALL_MOVE='CALL_MOVE';
    public static final string CALL_CREATE='CallCreate';
    public static final string REQUIRED='Required';
    public static final string COUNTRY_US='United States';
    public static final string USA='USA';
    public static final string NA='NA';
    public static final string BREAKDOWN_LOCATION='BREAKDOWN_LOCATION';
    public static final string APPOINTMENT_ASSISTANT='Appointment Assistant';
    public static final string BREAKDOWN_APPOINTMENT='Breakdown Appointment';
    public static final string TOW_APPOINTMENT='Tow Appointment';
    public static final string TEST_APPOINTMENT_NEGATIVE='Test Appointment Negative';
    public static final List<String> WO_CLEAR_CANCEL_STATUS=new List<String>{'Cleared','Canceled'};
    public static final string COLORADO = 'Colorado';
    public static final string CAROLINA = 'Carolina';
    public static final string ERROR_CODE405 = '405'; 
    public static final string PRIORITY_HIGH='High';
    public static final string SEARCH_ANI='searchByANI';
    public static final string IVR_LOOKUP='IVRLookup';
    public static final string SEARCH_MEMID='searchByMemberId';
    public static final List<String> IVR_WOSTATUS=new List<String>{'Spotted', 'Scheduled','Dispatched','En Route'};
    public static final string NATIONAL_CLOSED_STATUS = 'Closed - National Territory';
    
    //Integration - Status codes
	public static final integer ERROR_CODE500 = 500; 
    public static final integer ERROR_CODE400 = 400; 
    public static final integer ERROR_CODE404 = 404; 
    public static final integer STATUS_CODE_SUCCESS = 200;
    public static final integer STATUS_CODE_201_SUCCESS = 201;
    public static final integer ERROR_CODE204 = 204; 
    public static final integer SUCCESS_CODE204 = 204; 
	public static final string  STATUS_CODE404 = '404'; 
    public static final string  SUCCESS_200 = '200 Success'; 
    public static final string  NOTFOUND_404 = '404 NotFound'; 
    
    // ERS Payment Type
    public static final String ERSPAYMENT_EVENT_TYPE_ACCIDENT_ASSIST = 'Accident Assist';
    public static final String ERSPAYMENT_EVENT_TYPE_RAP = 'RAP';

    public static final String WORK_TYPE_LOCKSMITH = 'Locksmith';
    public static final Set<String> WORK_TYPE_HEAVY_DUTY = new Set<String>{'RV Tire Change', 'RV Tire Change Appointment', 'RV Extrication', 'RV Extrication Appointment', 'RV Tow', 'RV Tow Appointment'};
    public static final Set<String> WORK_TYPE_MEDIUM_DUTY = new Set<String>{'Large Vehicle Tow', 'Large Vehicle Tow Appointment'};
    public static final String WORK_TYPE_ACCIDENT = 'Accident';

    public static final String FACILITYID_STARTWITH50 = '50';
    public static final String FACILITYID_STARTWITH51 = '51';

    public static final String RESOLUTION_CODE_R199 = 'R199';
    public static final String RESOLUTION_CODE_R007 = 'R007';

    public static final Decimal TOTAL_AMOUNT_0_01 = 0.01;
    public static final Decimal TOTAL_AMOUNT_60 = 60;

    // ERS Payment Comm Center
    public static final String ERSPAYMENT_COMM_CENTER_PR = 'PR';
    public static final String ERSPAYMENT_COMM_CENTER_MI = 'MI';
    public static final String ERSPAYMENT_COMM_CENTER_IL = 'IL';
    public static final String ERSPAYMENT_COMM_CENTER_IN = 'IN';
    public static final String ERSPAYMENT_COMM_CENTER_WI = 'WI';
    public static final String ERSPAYMENT_COMM_CENTER_IA = 'IA';
    public static final String ERSPAYMENT_COMM_CENTER_MN = 'MN';
    public static final String ERSPAYMENT_COMM_CENTER_ND = 'ND';
    public static final String ERSPAYMENT_COMM_CENTER_NE = 'NE';
    public static final String ERSPAYMENT_COMM_CENTER_CO = '006';
    public static final String ERSPAYMENT_COMM_CENTER_CMC = '111';
    public static final String ERSPAYMENT_COMM_CENTER_FL = 'FL';
    public static final String ERSPAYMENT_COMM_CENTER_GA = 'GA';
    public static final String ERSPAYMENT_COMM_CENTER_TN = 'TN';

    // Call type ERS Payment Queue
    public static final String QUEUE_AUDIT = 'Audit';
    public static final String QUEUE_ACCIDENT_ASSIST = 'Accident_Assist';
    public static final String QUEUE_OPC = 'OPC';
    public static final String QUEUE_REIMBURSEMENT_INBOUND_EMAIL = 'Reimbursement_Inbound_Email';
    public static final String QUEUE_REIMBURSEMENT_TIER_2 = 'Reimbursement_Tier_2';
    public static final String QUEUE_PUERTO_RICO_AUDIT = 'Puerto_Rico_Audit';
    public static final String QUEUE_NONA_INBOUND_INVOICE_EMAIL = 'Nona_Inbound_Invoice_Email';
    public static final String QUEUE_ACCIDENT_CALL_AUDITS = 'Accident_Call_Audits';
    public static final String QUEUE_MD_QUEUE = 'MD_Queue';
    public static final String QUEUE_GA_50_51_QUEUE = 'GA_50_51_Queue';
    public static final String QUEUE_RAP_QUEUE = 'RAP_Queue';
    public static final String QUEUE_RECIPROCAL_QUEUE = 'Reciprocal_Queue';
    public static final String QUEUE_MI_MEMBER_MISUSE = 'MI_Member_Misuse';
    public static final String QUEUE_MI_MARKET_HIGH_DOLLAR = 'MI_Market_High_Dollar';
    public static final String QUEUE_MI_MARKET_LOCKSMITH = 'MI_Market_Locksmith';
    public static final String QUEUE_MI_HEAVY_DUTY = 'MI_Heavy_Duty';
    public static final String QUEUE_MI_MEDIUM_DUTY = 'MI_Medium_Duty';
    public static final String QUEUE_IL_IN_MEMBER_MISUSE = 'IL_IN_Member_Misuse';
    public static final String QUEUE_IL_IN_MARKET_HIGH_DOLLAR = 'IL_IN_Market_High_Dollar';
    public static final String QUEUE_IL_IN_MARKET_LOCKSMITH = 'IL_IN_Market_Locksmith';
    public static final String QUEUE_IL_IN_HEAVY_DUTY = 'IL_IN_Heavy_Duty';
    public static final String QUEUE_IL_IN_MEDIUM_DUTY = 'IL_IN_Medium_Duty';
    public static final String QUEUE_WI_MEMBER_MISUSE = 'WI_Member_Misuse';
    public static final String QUEUE_WI_MARKET_HIGH_DOLLAR = 'WI_Market_High_Dollar';
    public static final String QUEUE_WI_MARKET_LOCKSMITH = 'WI_Market_Locksmith';
    public static final String QUEUE_WI_HEAVY_DUTY = 'WI_Heavy_Duty';
    public static final String QUEUE_WI_MEDIUM_DUTY = 'WI_Medium_Duty';
    public static final String QUEUE_IA_MEMBER_MISUSE = 'IA_Member_Misuse';
    public static final String QUEUE_IA_MARKET_HIGH_DOLLAR = 'IA_Market_High_Dollar';
    public static final String QUEUE_IA_MARKET_LOCKSMITH = 'IA_Market_Locksmith';
    public static final String QUEUE_IA_HEAVY_DUTY = 'IA_Heavy_Duty';
    public static final String QUEUE_IA_MEDIUM_DUTY = 'IA_Medium_Duty';
    public static final String QUEUE_MN_MEMBER_MISUSE = 'MN_Member_Misuse';
    public static final String QUEUE_MN_MARKET_HIGH_DOLLAR = 'MN_Market_High_Dollar';
    public static final String QUEUE_MN_MARKET_LOCKSMITH = 'MN_Market_Locksmith';
    public static final String QUEUE_MN_HEAVY_DUTY = 'MN_Heavy_Duty';
    public static final String QUEUE_MN_MEDIUM_DUTY = 'MN_Medium_Duty';
    public static final String QUEUE_ND_MEMBER_MISUSE = 'ND_Member_Misuse';
    public static final String QUEUE_ND_MARKET_HIGH_DOLLAR = 'ND_Market_High_Dollar';
    public static final String QUEUE_ND_MARKET_LOCKSMITH = 'ND_Market_Locksmith';
    public static final String QUEUE_ND_HEAVY_DUTY = 'ND_Heavy_Duty';
    public static final String QUEUE_ND_MEDIUM_DUTY = 'ND_Medium_Duty';
    public static final String QUEUE_NE_MEMBER_MISUSE = 'NE_Member_Misuse';
    public static final String QUEUE_NE_MARKET_HIGH_DOLLAR = 'NE_Market_High_Dollar';
    public static final String QUEUE_NE_MARKET_LOCKSMITH = 'NE_Market_Locksmith';
    public static final String QUEUE_NE_HEAVY_DUTY = 'NE_Heavy_Duty';
    public static final String QUEUE_NE_MEDIUM_DUTY = 'NE_Medium_Duty';
    public static final String QUEUE_CO_MEMBER_MISUSE = 'CO_Member_Misuse';
    public static final String QUEUE_CO_MARKET_HIGH_DOLLAR = 'CO_Market_High_Dollar';
    public static final String QUEUE_CO_MARKET_LOCKSMITH = 'CO_Market_Locksmith';
    public static final String QUEUE_CO_HEAVY_DUTY = 'CO_Heavy_Duty';
    public static final String QUEUE_CO_MEDIUM_DUTY = 'CO_Medium_Duty';
    public static final String QUEUE_CMC_MEMBER_MISUSE = 'CMC_Member_Misuse';
    public static final String QUEUE_CMC_MARKET_HIGH_DOLLAR = 'CMC_Market_High_Dollar';
    public static final String QUEUE_CMC_MARKET_LOCKSMITH = 'CMC_Market_Locksmith';
    public static final String QUEUE_CMC_HEAVY_DUTY = 'CMC_Heavy_Duty';
    public static final String QUEUE_CMC_MEDIUM_DUTY = 'CMC_Medium_Duty';
    public static final String QUEUE_FL_MEMBER_MISUSE = 'FL_Member_Misuse';
    public static final String QUEUE_FL_MARKET_HIGH_DOLLAR = 'FL_Market_High_Dollar';
    public static final String QUEUE_FL_MARKET_LOCKSMITH = 'FL_Market_Locksmith';
    public static final String QUEUE_FL_HEAVY_DUTY = 'FL_Heavy_Duty';
    public static final String QUEUE_FL_MEDIUM_DUTY = 'FL_Medium_Duty';
    public static final String QUEUE_GA_MEMBER_MISUSE = 'GA_Member_Misuse';
    public static final String QUEUE_GA_MARKET_HIGH_DOLLAR = 'GA_Market_High_Dollar';
    public static final String QUEUE_GA_MARKET_LOCKSMITH = 'GA_Market_Locksmith';
    public static final String QUEUE_GA_HEAVY_DUTY = 'GA_Heavy_Duty';
    public static final String QUEUE_GA_MEDIUM_DUTY = 'GA_Medium_Duty';
    public static final String QUEUE_TN_MEMBER_MISUSE = 'TN_Member_Misuse';
    public static final String QUEUE_TN_MARKET_HIGH_DOLLAR = 'TN_Market_High_Dollar';
    public static final String QUEUE_TN_MARKET_LOCKSMITH = 'TN_Market_Locksmith';
    public static final String QUEUE_TN_HEAVY_DUTY = 'TN_Heavy_Duty';
    public static final String QUEUE_TN_MEDIUM_DUTY = 'TN_Medium_Duty';

    public static final Set<String> ALL_QUEUE_ERSPAYMENT_CALL = new Set<String>{'Accident_Assist', 'OPC', 'Audit', 'Reimbursement_Inbound_Email', 'Reimbursement_Tier_2', 'Puerto_Rico_Audit', 'Nona_Inbound_Invoice_Email', 'Accident_Call_Audits', 'MD_Queue', 'GA_50_51_Queue', 'RAP_Queue', 'Reciprocal_Queue', 'MI_Member_Misuse', 'MI_Market_High_Dollar', 'MI_Market_Locksmith', 'MI_Heavy_Duty', 'MI_Medium_Duty', 'IL_IN_Member_Misuse', 'IL_IN_Market_High_Dollar', 'IL_IN_Market_Locksmith', 'IL_IN_Heavy_Duty', 'IL_IN_Medium_Duty', 'WI_Member_Misuse', 'WI_Market_High_Dollar', 'WI_Market_Locksmith', 'WI_Heavy_Duty', 'WI_Medium_Duty', 'IA_Member_Misuse', 'IA_Market_High_Dollar', 'IA_Market_Locksmith', 'IA_Heavy_Duty', 'IA_Medium_Duty', 'MN_Member_Misuse', 'MN_Market_High_Dollar', 'MN_Market_Locksmith', 'MN_Heavy_Duty', 'MN_Medium_Duty', 'ND_Member_Misuse', 'ND_Market_High_Dollar', 'ND_Market_Locksmith', 'ND_Heavy_Duty', 'ND_Medium_Duty', 'NE_Member_Misuse', 'NE_Market_High_Dollar', 'NE_Market_Locksmith', 'NE_Heavy_Duty', 'NE_Medium_Duty', 'CO_Member_Misuse', 'CO_Market_High_Dollar', 'CO_Market_Locksmith', 'CO_Heavy_Duty', 'CO_Medium_Duty', 'CMC_Member_Misuse', 'CMC_Market_High_Dollar', 'CMC_Market_Locksmith', 'CMC_Heavy_Duty', 'CMC_Medium_Duty', 'FL_Member_Misuse', 'FL_Market_High_Dollar', 'FL_Market_Locksmith', 'FL_Heavy_Duty', 'FL_Medium_Duty', 'GA_Member_Misuse', 'GA_Market_High_Dollar', 'GA_Market_Locksmith', 'GA_Heavy_Duty', 'GA_Medium_Duty', 'TN_Member_Misuse', 'TN_Market_High_Dollar', 'TN_Market_Locksmith', 'TN_Heavy_Duty', 'TN_Medium_Duty'};
    
    // Contract Line Item
    public static final String CONTRACT_LINE_ITEM_MEMBERSHIP_LEVEL_BASIC = 'Basic';
    public static final String CONTRACT_LINE_ITEM_TIME_BAND = 'D3';

    //Integration - Status codes
    public static final string GET_STANDARDSOQL_API = 'GETStandardSOQL_API';
    public static final string INTSTANDARDSOQLAPI = 'INTStandardSOQLQueryAPI';
    public static final string GETRECORDBYSOQL = 'getRecordBySOQL';

    public static final Set<String> VEHICLE_SKILL_TYPE = new Set<String>{'BA w/ EX', 'Battery Service', 'Flatbed w/ BA', 'Flatbed w/ BA MC no EX', 'LC FB w/ BA', 'LC WL w/ BA', 'LC WL w/ BA DL', 'MC FB w/ BA', 'WL w/ BA', 'WL w/ BA DL'};

    public static final Set<String> BATTERY_TECHNICIAN = new Set<String>{'Battery Technician','Battery Replacement'};
        
    public static final String EPREMIER = 'E';
    public static final String VPREMIERRV = 'V';
    public static final String BCLASSIC = 'B';
    public static final String JBASIC = 'J';
    public static final String PPLUS = 'P';
    public static final String RRV = 'R';
    public static final String OOTHER = 'O';
	public static final String OTHER = 'OTHER';
    // Reimbursement
    public static final String REIMBURSEMENT_REASON_CODE_01 = '01';
    public static final String REIMBURSEMENT_REASON_CODE_02 = '02';
    public static final String REIMBURSEMENT_REASON_CODE_CF = 'CF';
    
    //AARCORGEOJSONGenerator
    public static final string REPAIR_SHOPS='Repair Shops';
    public static final string AAR = 'AAR';
    public static final string ACG_AAR = 'ACG_AAR';
    public static final string COR = 'COR';
    public static final string MONDAY = 'Monday';
    public static final string TUESDAY = 'Tuesday'; 
    public static final string WEDNESDAY = 'Wednesday';
    public static final string THURSDAY = 'Thursday';
    public static final string FRIDAY = 'Friday';
    public static final string SATURDAY = 'Saturday';
    public static final string SUNDAY = 'Sunday';
    
    public static final String BREAKDOWN_STR = 'Breakdown';
    public static final String NONA_PAYMENTS_QUEUE_DEV_NAME_STR = 'NONA_Payments';
    public static final String ATC_STR = 'ATC';
    public static final String RAP_STR = 'RAP';
    
    public static final string RE ='RE';
    public static final string NORMAL ='NORMAL';
    public static final string ALLUSERS = 'AllUsers';
    public static final string INTERNAL = 'INTERNAL';
    public static final string EXTERNAL = 'EXTERNAL';
    public static final string VIOLATION_HANDLERS='FSL_Violation_Handlers';
    public Static Final String SLOTS_SUCCESS_MESSAGE = 'Successfully retrieved slots';
    public Static Final String CLEAR_PENDING = 'Clear Pending';
    public static final String APPROVED_REIMBURSEMENTS_QUEUE_API_NAME_STRING = 'Approved_Reimbursements_Queue';
    public static final String FACILITY_RECORDTYPE_DEVELOPERNAME = 'Facility';
    public static final String TOW_STRING = 'TOW';
    public static final String LONG_TOW_STRING = 'LONG TOW';
    public static final String ENROUTE_STRING = 'ENROUTE';
    public static final String CAA_RAP = 'CAA RAP';
    public static final String RAP_MANUAL = 'RAP Manual';
}