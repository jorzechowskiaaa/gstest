/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 03-20-2023
 * @last modified by  : Clement Shiu
**/
public class FSL_Case {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        ICaseService createService();
    }

    public class Factory implements IFactory {
        public ICaseService createService() {
            ICaseDAO dao = createDAO();
            FSL_Group.IFactory groupFactory = new FSL_Group.Factory();
            return new CaseService( dao, groupFactory.createService() );
        }

        private ICaseDAO createDAO() {
            return new CaseDAO();
        }
    }
    
    // *********************************************
    // * DAO
    // *********************************************
    public interface ICaseDAO extends FSL_DAO.DmlInterface {
       List<Case> fetchCasesForWorkOrders( Set<Id> workOrders, String recordType );
       List<Case> fetchCasesForCallMover(Set<Id> CaseIDs);
       
       //List<Group> fetchQueue(String developerName);
    }
    
    public class CaseDAO extends FSL_DAO.DmlBase implements ICaseDAO{
        public List<Case> fetchCasesForWorkOrders( Set<Id> workOrders, String recordType ) {
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get( recordType ).getRecordTypeId();
            List<Case> cslist = [SELECT Id, Status, RecordTypeId, FSL_Work_Order__c 
                                FROM Case 
                                WHERE FSL_Work_Order__c IN :workOrders 
                                AND RecordTypeId = :recordTypeId];
            return cslist;
        }

        public List<Case> fetchCasesForCallMover( Set<Id> CaseIDs ) {
            List<Case> cslist = [SELECT Id,RecordTypeId, createdDate,caseNumber,Club_Name__c,ERS_Event_Type__c,T_Code__C,Pacesetter_Code__c,ACG_Vehicle_Location_Type__c,Appointment_Requested__c,
                                    ACG_Vehicle_Type__c,ACG_Year__c,ACG_Make__c,ACG_Color__c,ACG_Model__c,Vehicle_Fuel_Type__c,Vehicle_Drive_Type__c,
                                    Vehicle_Odometer__c,Vehicle_Trim_Level__c,ACG_VIN__c,Vehicle_Lockout_Reason__c, BSP_Available__c,Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s,
                                    Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,Vehicle_Location_Postal_Code__c,Vehicle_Location_Country__c,Landmark__c,
                                    ACG_Vehicle_Location_Address__c,Enter_Home_during_Lockout__c,Flat_Tire_Status__c,Gross_Weight__c,ACG_Service_Type__c,Special_Equipment_Selection__c,Total_Mileage__c,
                                    ACG_Drivetrain__c,ACG_Case_Contact_Number__c,Call_Origin__c,Number_of_passengers__c,Priority,Member_Location_TZ_Offset__c,
                                    Tow_Request_Reason__c,Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,ACG_Tow_Destination_Address__c,Tow_Destination_Street__c,Tow_Destination_City__c,
                                    Tow_Destination_State__c,Tow_Destination_Postal_Code__c,Flatbed_Required__c,ACG_AAA_Membership__c,Case_Membership_Level__c,ACG_Membership_Status__c,Remaining_Entitlement__c,
                                    Account.ACG_Entitlements_Allotted__c,Account.ACG_Entitlements_Used__c,Account.ACG_ERS_Entitlements__c,Account.Club_Code1__c, Account.Member_Club_Code__c,
                                    Account.Club_Name1__c,Account.Parent_Club_Name__c,Account.FirstName,Account.LastName,Account.Phone,Account.ACG_Primary_Phone_Type__c,Account.ACG_SMS_Opt_In__c,
                                    Account.Phone_Extension__pc,Account.PersonEmail,Account.Email_Type__pc,Account.Membership_Type__pc,Account.ACG_Membership_Type__c,Account.Membership_Expiration_Date__c,Account.ACG_Date_of_Birth__c,
                                    Account.Membership_Since__pc,Account.Membership_Sponsor__pc,Account.Membership_Program__pc,Account.Membership_Code__pc,
                                    Account.Membership_Authorization__pc,Account.Membership_IsLocalClub__pc,Account.Membership_Org__pc,Account.Membership_OrgCode__pc,CDX_Authorization_Code__c,CDX_Authorization_Level__c,
                                    Member_Vehicle__r.Vehicle_Special_Equipment_Needs__c,Member_Vehicle__r.Vehicle_Fuel_Type__c,Member_Vehicle__r.Vehicle_Drive_Type__c,Member_Vehicle__r.Vehicle_Odometer__c,		
                                    Member_Vehicle__r.Vehicle_State__c,Member_Vehicle__r.Vehicle_Tag__c,Member_Vehicle__r.Vehicle_Trim__c,Member_Vehicle__r.Vehicle_VIN__c,Member_Vehicle__r.Duty__c,
                                    ACG_Driving_Directions__c,ACG_Collision__c,ACG_work_type__r.Trouble_Code__C,LastModifiedDate,comments,FSL_Service_Type_Internal__c,Locksmith_Issue__c,Member_Vehicle_Type__c                   
                            FROM    Case
                            WHERE   Id = :CaseIDs];
            return cslist;
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface ICaseService  {
        void openClearQueueFailureCase( Id workOrderId, FSL_WorkOrder.IWorkOrderService workOrderService );
        void openClearQueueProcessingHaltedCase();
        void thirdPartyDeclineCase(WorkOrder wo, ServiceAppointment brkDnSA, ServiceAppointment towSA, String caseSubject);
        Id getrectypeIdbyDeveloperName(String rectypeDeveloperName);
        Case getCallMoverCase(Id caseId);
    }
    
    public class CaseService implements ICaseService {
        private ICaseDAO dao;
        private FSL_Group.IGroupService groupService;

        public CaseService( ICaseDAO dao, FSL_Group.IGroupService groupService ) {
            this.dao = dao;
            this.groupService = groupService;
        }
        public Id getrectypeIdbyDeveloperName(String rectypeDeveloperName){
           return Schema.SObjectType.Case.getRecordTypeInfosbyDeveloperName().get(rectypeDeveloperName).getRecordTypeId();
        }
        public void openClearQueueFailureCase( Id workOrderId, FSL_WorkOrder.IWorkOrderService workOrderService ) {
            System.debug( LoggingLevel.DEBUG, 'FSL_Case.CaseService.openClearQueueFailureCase: Enter - WorkOrderId = [' + workOrderId + ']' );
            try {
                List<Case> cases = dao.fetchCasesForWorkOrders( new Set<Id>{ workOrderId }, 'Clear Queue Failure' );
                WorkOrder w = loadWorkOrder( workOrderId, workOrderService );
                Group g = groupService.getGroupForClearQueueCaseOwnership();
            
                System.debug( LoggingLevel.DEBUG, 'FSL_Case.CaseService.openClearQueueFailureCase: ' + ( cases.isEmpty() ? 'No prior cases, opening a Clear Queue Failure case' : 'Prior cases exist, opening a Manual Service Order case' ) );
                String caseRecordType = ( cases.isEmpty() ? 'Clear Queue Failure' : 'Manual Service Order' );
                Case c = FSL_DataFactory.createCase( caseRecordType );
                c.FSL_Work_Order__c = workOrderId;
                c.FSL_Primary_Service_Territory__c = w.ServiceTerritoryId;
                c.OwnerId = g.Id;
                if( caseRecordType == 'Clear Queue Failure' ) {
                    c.Subject = 'WorkOrder failed to Clear';
                    c.Description = 'The Clear Queue was unable to clear the WorkOrder.' + '\r\n ' + 
                                    'This could be due to a temporary issue.' + '\r\n' + 
                                    'When the issue is resolved, please click Retry in the Feed tab.' + '\r\n' + 
                                    'Note: This case will automatically close when Retry is clicked.';
                }
                else if( caseRecordType == 'Manual Service Order' ) {
                    c.Subject = 'WorkOrder Clear retry failed, manual service order creation required';
                    c.Description = 'The Clear Queue was unable to clear the WorkOrder, and a manual retry failed' + '\r\n ' + 
                                    'A manual service order creation in IRAS may be necessary.';
                }
                dao.insertRecords( new List<Case>{ c } );
            }
            catch( Exception ex ) {
                System.debug( LoggingLevel.ERROR, 'FSL_Case.CaseService.openClearQueueFailureCase: Exception = [' + ex.getMessage() + ']' );
            }
        }
        private WorkOrder loadWorkOrder( Id workOrderId, FSL_WorkOrder.IWorkOrderService workOrderService ) {
            List<WorkOrder> workOrders = workOrderService.getWorkOrdersForClearing( new Set<Id>{ workOrderId } );
            if( workOrders.size() == 0 ) {
                throw new QueryException( 'FSL_Case.CaseService.loadWorkOrder: Failed to query a WorkOrder for Id =[' + workOrderId + ']' );
            }
            return workOrders[0];
        }
        public void openClearQueueProcessingHaltedCase() {
            System.debug( LoggingLevel.DEBUG, 'FSL_Case.CaseService.openClearQueueProcessingHaltedCase: Enter' );
            Group g = groupService.getGroupForClearQueueCaseOwnership();
            Case c = FSL_DataFactory.createCase( 'Clear Queue Processing Halted' );
            c.OwnerId = g.Id;
            c.Subject = 'Clear Queue Processing Halted';
            c.Description = 'The Clear Queue detected a potential outage.' + '\r\n' + 
                            'The processing of the clear queue has been halted.' + '\r\n' + 
                            'Once the outage has been cleared, you can re-enable the processing by updating ' + '\r\n' + 
                            'the Clear Queue Processing record under the FSL Minute Schedule Task (Custom Metadata)' + '\r\n' + 
                            'and setting the End Date/Time field to a date in the future';
            dao.insertRecords( new List<Case>{ c } );
        }
        public void thirdPartyDeclineCase(WorkOrder wo, ServiceAppointment brkDnSA, ServiceAppointment towSA, String caseSubject) {
            Case declineCase = new Case();
            declineCase.Subject = caseSubject;
            declineCase.Origin  ='Automation';
            //declineCase.Type__c ='Facility Declined';
            declineCase.ContactId = wo.ContactId;
            declineCase.RecordTypeId=getrectypeIdbyDeveloperName('Declined_Work');
            declineCase.FSL_Work_Order__c = wo.Id;
            declineCase.FSL_Service_Type__c = brkDnSA.WorktypeId;
            declineCase.FSL_Service_Appointment__c = brkDnSA.Id;
            declineCase.FSL_Vehicle_Description__c =  wo.Vehicle_Profile__c;
            if ( towSA != null ) {
                declineCase.FSL_Service_Appointment_Tow__c = towSA.Id;
            }
            declineCase.FSL_Service_Appointment_Territory__c = brkDnSA.ServiceTerritoryId;
            declineCase.Number_of_passengers__c = wo.Number_Of_Passengers__c;
            declineCase.OwnerId =  groupService.getGroupForQueueName('Reroute_Queue').Id;
            dao.insertRecords( new List<Case>{ declineCase } );
        }
        public Case getCallMoverCase(Id caseId){
            Case cmCase = new Case();

            // Convert ID to Set
            Set<Id> caseIdSet = new Set<Id>();
            caseIdSet.add(caseId);            

            // Call dao
            List<Case> cases = dao.fetchCasesForCallMover(caseIdSet);

            // Convert list back to single Case
            if(!cases.isEmpty()) {
                cmCase = cases.get(0);
            }
            return cmCase;            
        }
    }

    public static Datetime getPTAFromCaseAppointmentAsOrgTime ( Case caseObj ) {
        System.debug ('FSL_Case.getPTAFromCaseAppointmentAsOrgTime ( caseObj )' );
        Datetime dtPresumedMember = dateTimeFromDateAndTime ( caseObj.ACG_Requested_Appointment_Date__c, caseObj.ACG_Requested_Appointment_Time__c );
        Datetime dtOrg = orgTimeFromMemberTime ( dtPresumedMember, caseObj.Member_Location_TZ_Offset__c );
        System.debug (' dtPresumedMember= ' + dtPresumedMember + ' dtOrg=' + dtOrg );
        return dtOrg;
    }
    public static Datetime orgTimeFromMemberTime ( Datetime dtMem, String memberUTCOffset ) {
        System.debug ('FSL_Case.orgTimeFromMemberTime ( ' + dtMem + ', ' + memberUTCOffset );
        Integer hrOffOrg = getOrgTZOffsetHours ();
        Integer hrOffMem = parseUTCOffset ( memberUTCOffset );
        System.debug('Hour Offset for Org: ' + hrOffOrg + '  Hour Offset for Member: ' + hrOffMem );
        //System.debug ( 'dtMem: ' + dtMem );
        Datetime dtOrg = dtMem.addHours ( hrOffOrg - hrOffMem );
        //System.debug ( 'dtOrg: ' + dtOrg );
        return dtOrg;
    }
    public static Datetime memberTimeFromOrgTime ( Datetime dtOrg, String memberUTCOffset ) {
        //System.debug ('FSL_Case.memberTimeFromOrgTime ( ' + dtOrg + ', ' + memberUTCOffset );
        Integer hrOffOrg = getOrgTZOffsetHours ();
        Integer hrOffMem = parseUTCOffset ( memberUTCOffset );
        //System.debug('Hour Offset for Org: ' + hrOffOrg + '  Hour Offset for Member: ' + hrOffMem );
        //System.debug ( '   dtOrg: ' + dtOrg );
        Datetime dtMember = dtOrg.addHours ( hrOffOrg - hrOffMem );
        //System.debug ( 'dtMember: ' + dtMember );
        return dtMember;
    }

    private static DateTime dateTimeFromDateAndTime ( Date date0, String time0 ) {
        DateTime dt0 = null;
        if ( date0 != null ) {
            String[] hrmin = time0.split(':');
            Integer hr = Integer.valueOf ( hrmin[0] );
            // If PM, and after 12pm, add 12 to make 24hour clock.
            // e.g. 1,2,3,4,5,6,7,8,9,10,11 pm
            if ( hrmin[1].endsWith('PM') && hr < 12 )
                hr += 12;
            Integer min = Integer.valueOf ( hrmin[1].substring(0,2) );
            Time tt0 = Time.newInstance ( hr,min,0,0 );
            dt0 = Datetime.newInstance ( date0, tt0 );
        }
        return dt0;
    }
    private static Integer getOrgTZOffsetHours () {
        Datetime orgDtNow = Datetime.now();
        //System.debug ( 'orgDtNow as UTC= ' + JSON.serialize(orgDtNow) );
        TimeZone tz = UserInfo.getTimeZone();
        //System.debug ('Org Timezone name: ' + tz.getDisplayName());
        return ( tz.getOffset ( orgDtNow ) / (60*60*1000) );
    }
    public static Integer parseUTCOffset ( String UTCSVal ) {
        // String of the form 'UTC-6:00' or for HI, 'UTC-10:00'
        //return Integer.valueOf ( UTCSVal.substring(3,5) );
        String[] hr = (UTCSVal.substring ( 3, UTCSVal.Length() )).split(':');
        Integer decPart = Integer.valueOf (hr[0]);
        System.debug ( 'FSL_Case.parseUTCOffset. ' + UTCSVal + ' decPart= >' + decPart + '<' );
        return decPart;
    }
  
}