// Last Modified: 2025-07-29 John Orzechowski for SSFI-1277, commenting out several impairment types

public class ImpairmentsHelper {

    
    public static final String IMPAIRMENT_TYPE_CANCELED = 'CANCELLED';
    public static final String IMPAIRMENT_TYPE_CANCELED_CDX = 'CANCELLED (CDX)';
    public static final String IMPAIRMENT_TYPE_ERS_ABUSER = 'ERS ABUSER (CDX)';
    public static final String IMPAIRMENT_TYPE_ERS_ABUSER_RVMC = 'ERS ABUSER (RV/MC)';
    public static final String IMPAIRMENT_TYPE_CAPRE = 'CA PRE-PAYMENT';
    public static final String IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD = 'UNPAID - 30 DAYS GRACE PERIOD';
    public static final String IMPAIRMENT_UNPAID_GRACE_CALLS = 'UNPAID - GRACE PERIOD - CALLS LEFT';
    public static final String IMPAIRMENT_UNPAID_GRACE_NO_CALLS = 'UNPAID - GRACE PERIOD - NO CALLS LEFT';
    
   
    public static final String IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS = 'EXPIRED - OVER 30 DAYS';
    public static final String IMPAIRMENT_TYPE_SAME_DAY_SERVICE = 'SAME DAY SERVICE';
    public static final String IMPAIRMENT_TYPE_SERVICE_CHARGE = 'SERVICE CHARGE';
    public static final String IMPAIRMENT_TYPE_ACTIVE_NO_CALLS = 'ACTIVE - NO CALLS LEFT';
    public static final String IMPAIRMENT_TYPE_PENDING_NEW_MEMBER = 'PENDING - NEW MEMBER';
    public static final String IMPAIRMENT_TYPE_PENDING_EXISTING_MEMBER = 'PENDING - EXISTING MEMBER';
    public static final String IMPAIRMENT_TYPE_PENDING_RENEWAL = 'PENDING - RENEWAL';
    public static final string IMPAIRMENT_TYPE_SALVAGED = 'SALVAGED';
    public static final String IMPAIRMENT_TYPE_LAST_DAY_SERVICE = 'LAST DAY SERVICE';
    public static final String IMPAIRMENT_TYPE_EVERYDAY_SERVICE = 'EVERY DAY SERVICE';
   
    public static final String ACE_CLUB_CODE_FOR_CAPRE_CHECK = '004';
    public static final String ACMO_CLUB_CODE = '065';
    // FOR CDX
    public static final String MV_CUSTOM_PROPERTY_NAME_CANCELED = 'Cancelled';


    public ImpairmentsHelper() {
    }

    @AuraEnabled
    public static void createFeedRecord(String recordId){
        new Factory().createService().createImpairmentResolutionFeedComment(recordId);
    }

    @AuraEnabled(cacheable=true)
    public static AccountContractWrapper getEntitlementDetailsbyCaseId(String caseId){
        AccountContractWrapper acw = new AccountContractWrapper();
        Case cs = [SELECT Id, Account.CDX_Authorization_Code__c, Account.CDX_Authorization_Level__c, Account.Membership_Status__pc,Account.Membership_Expiration_Date__c,
                                Account.Membership_IsLocalClub__pc, ServiceContract.EndDate, ServiceContract.AAA_Total_of_Calls_Allowed__c, 
                                ServiceContract.AAA_Total_of_Calls_Consumed__c, ServiceContract.AAA_Total_of_Calls_Remaining__c,ServiceContract.AAA_Total_of_Reciprocals__c,ServiceContract.AAA_ACA_Membership_Type__c FROM Case WHERE Id = :caseId];
             acw.contractEndDate = (cs.Account.Membership_Expiration_Date__c != null) ? Date.valueOf(cs.Account.Membership_Expiration_Date__c).month() + '/' + Date.valueOf(cs.Account.Membership_Expiration_Date__c).day() +'/'+ Date.valueOf(cs.Account.Membership_Expiration_Date__c).year() : '';
             if(cs.ServiceContract != null) {       
                    acw.callsAllowed = String.valueOf(cs.ServiceContract.AAA_Total_of_Calls_Allowed__c);
                    acw.callsRemaining = String.valueOf(cs.ServiceContract.AAA_Total_of_Calls_Allowed__c - cs.ServiceContract.AAA_Total_of_Calls_Consumed__c - cs.ServiceContract.AAA_Total_of_Reciprocals__c);
                    acw.contractEndDate = (cs.ServiceContract.EndDate != null) ? Date.valueOf(cs.ServiceContract.EndDate).month() + '/' + Date.valueOf(cs.ServiceContract.EndDate).day() +'/'+ Date.valueOf(cs.ServiceContract.EndDate).year() : '';
            	 	acw.membershipType = String.valueof(cs.ServiceContract.AAA_ACA_Membership_Type__c);
             }
                    acw.status = cs.Account.Membership_Status__pc;
                    acw.isLocalClub = cs.Account.Membership_IsLocalClub__pc;          
                    acw.authCode = cs.Account.CDX_Authorization_Code__c;
                    acw.authLevel = cs.Account.CDX_Authorization_Level__c;
        return acw;
    }

    public Class AccountContractWrapper{
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String callsAllowed;
        @AuraEnabled
        public String callsRemaining;
        @AuraEnabled
        public String contractEndDate;
        @AuraEnabled
        public String authCode;
        @AuraEnabled
        public String authLevel;
        @AuraEnabled
        public Boolean isLocalClub;
        @AuraEnabled
        public String membershipType;
    }

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IImpairmentsService createService();
    }

    public class Factory implements IFactory {
        public IImpairmentsService createService() {
            IImpairmentsDAO dao = createDAO();
            FSL_ApplicationLog.IApplicationLogService logService = new FSL_ApplicationLog.Factory().createService();
            return new ImpairmentsService( dao, logService);
        }

        private IImpairmentsDAO createDAO() {
            return new ImpairmentsDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IImpairmentsDAO {
        ERS_Impairment__c fetchImpairmentByType(String impType);
        ERS_Impairment__c fetchImpairmentById(String impId);

        Case fetchCaseWithImpairmentsInfo(String caseId);
        void insertFeedItem(Id caseId, String body);
    }

    public class ImpairmentsDAO implements IImpairmentsDAO{
        public ERS_Impairment__c fetchImpairmentByType(String impType) {
            ERS_Impairment__c impairment = null;
            List<ERS_Impairment__c> impairments = [Select Id, Name, Instructions__c, Payment_Required__c, 
                                                  Payment_Collected_Comment__c, COD_Comment__c,
                                                  Cancel_Service_Comment__c, Override_Comment__c
                                                  FROM ERS_Impairment__c 
                                                  WHERE Name = :impType];
            if ( impairments.size() > 0 ) {
                impairment = impairments[0];
            }
            return impairment;
            
        }

        public ERS_Impairment__c fetchImpairmentById(String impId) {
            ERS_Impairment__c impairment = null;
            List<ERS_Impairment__c> impairments = [Select Id, Name, Instructions__c, Payment_Required__c, 
                                                  Payment_Collected_Comment__c, COD_Comment__c,
                                                  Cancel_Service_Comment__c, Override_Comment__c
                                                  FROM ERS_Impairment__c 
                                                  WHERE Id = :impId];
            if ( impairments.size() > 0 ) {
                impairment = impairments[0];
            }
            return impairment;
        }

        public Case fetchCaseWithImpairmentsInfo(String caseId) {
            Case matchingCase = null;
            List<Case> ersCases = [Select Id, Status, Impairment__c, Case_Cancel_Comments__c, Case_Cancel_Reason__c,
                                    Impairment_Payment_Collected__c,  Impairment_COD_Payment__c, Impairment_Comments__c, 
                                    Impairment_Supervisor_Override__c, Impairment_Override_Reason__c,Reconcile_Entitlement__c 
                                    FROM Case 
                                    WHERE Id = :caseId];       
            if ( ersCases.size() > 0 )  {
                matchingCase =  ersCases[0];
            }
            return matchingCase;
        }

        public void insertFeedItem(Id caseId, String body) {
            FeedItem feedRec = new FeedItem();
            feedRec.ParentId = caseId;
            feedRec.Visibility = 'AllUsers';
            feedRec.Body = body;
            insert feedRec;
        }
    }
    
    // *********************************************
    // * Service
    // *********************************************
    public interface IImpairmentsService {
         String checkAndExtractMembershipImpairment(FSL_LightningCustomerWrapper customerWrapper);
         String extractMembershipImpairmentForLocal(INTMembershipLookupResponse_Wrapper.Customer customer, AAA_ServiceContractUtility.ContractInformationWrapper memberContract);
         void createImpairmentResolutionFeedComment(String caseId);
    }

    public class ImpairmentsService implements IImpairmentsService {

        private IImpairmentsDAO dao;
        private FSL_ApplicationLog.IApplicationLogService logService;
        public ImpairmentsService(IImpairmentsDAO dao, FSL_ApplicationLog.IApplicationLogService logService) {
            this.dao = dao;
            this.logService = logService;
        }

        public String extractMembershipImpairmentForLocal(INTMembershipLookupResponse_Wrapper.Customer customer, AAA_ServiceContractUtility.ContractInformationWrapper memberContract) {
            String impairmentId = '';
            String impType = categorizeImpairmentForLocal(customer,memberContract);
            impairmentId = getImpairmentRecordIdFromType(impType);
            return impairmentId;
        }


        public String checkAndExtractMembershipImpairment(FSL_LightningCustomerWrapper customerWrapper) {
            String impairmentId = '';
            if ( Integer.valueOf(customerWrapper.statusCode) != 200 || 
                                 customerWrapper?.membership == null || 
                                 customerWrapper?.membership?.entitlements[0] == null || 
                                 customerWrapper?.membership?.isLocalClub == null) {
                return impairmentId;
            }
            if(customerWrapper?.membership?.isLocalClub == false) {
                String impType = categorizeImpairmentCDX(customerWrapper);
                impairmentId = getImpairmentRecordIdFromType(impType);
            }
            return impairmentId;
        }

        private String getImpairmentRecordIdFromType(String impType) {
            String impairmentId = '';
            if ( !String.isBlank(impType) ) {
                ERS_Impairment__c impairment = dao.fetchImpairmentByType(impType);
                if ( impairment != null ) {
                    impairmentId = impairment.Id;
                }
            }
            return impairmentId;           
        }

        private string categorizeImpairmentForLocal( INTMembershipLookupResponse_Wrapper.Customer customer, AAA_ServiceContractUtility.ContractInformationWrapper memberContractWrap) {
            String impType = '';
            Date callDate = system.Today();
            system.debug('impairement ** ' + customer);
            system.debug('memberlevel **' + customer.memberLevel);
          //  system.debug('impairement11 ** ' +  customer.entitlement.sameDayService);
            system.debug('impairement1 ** ' + memberContractWrap);
            system.debug('impairement12 ** ' + memberContractWrap.membershipContract.AAA_ACA_Member_Status__c);
            if( customer.memberLevel != null && customer.memberLevel == 'EVERYDAY')
            {
                impType  = IMPAIRMENT_TYPE_EVERYDAY_SERVICE;
            }
            else if(memberContractWrap.membershipContract != null && memberContractWrap.membershipContract.AAA_Total_of_Calls_Allowed__c > 0) {
                if(memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c <= 0) {
                    impType = IMPAIRMENT_TYPE_ACTIVE_NO_CALLS;
                }
                else if(memberContractWrap.membershipContract.AAA_ACA_Member_Status__c == AAA_CallIntakeUtils.MEMBER_STATUS_ACTIVE
                && customer.entitlement.sameDayService == false) {
                    impType = IMPAIRMENT_TYPE_SAME_DAY_SERVICE;
                }
                else if(memberContractWrap.membershipContract.AAA_ACA_Member_Status__c == AAA_CallIntakeUtils.MEMBER_STATUS_PENDING) {
                    //If there is a contract found in salesforce but expirationDate is in the past
                    //Check for Grace period and handle logic accordingly
                    //FOR NE
                    system.debug('@@@ pending @@@@'+memberContractWrap.membershipContract.EndDate);
                    system.debug('@@@ pending @@@@'+memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c);
                    /* commented for SSFI-1277
                    if(memberContractWrap.membershipContract.EndDate < callDate &&
                     memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c > 0 &&
                        Label.FSL_SourceClubCode == '240') {
                        system.debug('@@@ pending Imp grace @@@@');
                        impType = ImpairmentsHelper.IMPAIRMENT_UNPAID_GRACE_CALLS;
                    } */ 
                    if(memberContractWrap.membershipContract.EndDate < callDate &&
                    memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c <= 0 &&
                        Label.FSL_SourceClubCode == '240') {
                        impType = ImpairmentsHelper.IMPAIRMENT_UNPAID_GRACE_NO_CALLS;
                    }
                    /* else if(memberContractWrap.membershipContract.EndDate < callDate &&
                    memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c >= 0 &&
                        Label.FSL_SourceClubCode == '212' &&
                        memberContractWrap.membershipContract.EndDate.daysBetween(callDate) <= 30) {
                        impType = ImpairmentsHelper.IMPAIRMENT_UNPAID_GRACE_CALLS;
                    } */ 
                    else if(memberContractWrap.membershipContract.EndDate < callDate &&
                    memberContractWrap.membershipContract.AAA_Total_of_Calls_Remaining__c >= 0 &&
                        Label.FSL_SourceClubCode == '212' &&
                        memberContractWrap.membershipContract.EndDate.daysBetween(callDate) > 30) {
                        impType = ImpairmentsHelper.IMPAIRMENT_UNPAID_GRACE_NO_CALLS;
                    }
                    /* -- commented out for SSFI-1277
                    else if(customer.expirationDate != null && Date.Valueof(customer.expirationDate) > callDate) {
                        system.debug('@@@@ Imp Helper @@@'+impType);
                        impType = ImpairmentsHelper.IMPAIRMENT_TYPE_PENDING_EXISTING_MEMBER;
                    } 
                    else if(customer.expirationDate != null && Date.Valueof(customer.expirationDate) == callDate){
                        impType = ImpairmentsHelper.IMPAIRMENT_TYPE_LAST_DAY_SERVICE;
                    } */ 
                    else {
                        system.debug('@@@ pending renewal @@@@');
                    //    impType = IMPAIRMENT_TYPE_PENDING_RENEWAL;
                    }
                }
                else if(memberContractWrap.membershipContract.AAA_ACA_Member_Status__c == IMPAIRMENT_TYPE_CANCELED) {
                    impType = IMPAIRMENT_TYPE_CANCELED;
                }
            }
            else if(memberContractWrap.membershipContract != null && memberContractWrap.membershipContract.AAA_Total_of_Calls_Allowed__c <= 0) {
                impType = IMPAIRMENT_TYPE_SALVAGED;
            }
            else if(customer.membershipStatus == IMPAIRMENT_TYPE_CANCELED) {
                impType = IMPAIRMENT_TYPE_CANCELED;
            }
            system.debug('@@@@ Imp Helper @@@'+impType);
            return impType;
        }

        // private String categorizeImpairmentACE(FSL_LightningCustomerWrapper customerWrapper) {

        //     String impType = '';

        //     Boolean isSvcCharge = false;
        //     Boolean isACE = false;
        //     Boolean isACMO = false;
        //     Boolean isCanceled = false;
        //     Boolean inArrears = false;
        //     Boolean inRenewal = false;
        //     Boolean unpaid = false;

        //     FSL_LightningMembershipWrapper membership = customerWrapper?.membership;
        //     FSL_LightningEntitlementWrapper  entitlement = customerWrapper?.membership?.entitlements[0];

    
        //     // Process the impairment types, where there is an explict indicator of the impairment
        //     if ( entitlement?.serviceChargeIndicator || entitlement?.callsRemaining <= 0 ) {
        //          isSvcCharge = true;
        //     }

        //     isACE = isClubACECA(membership?.originalMemberId) || isClubACECA(membership?.id);

        //     isACMO = isClubACMO(membership?.originalMemberId) || isClubACMO(membership?.id);
        //     // Process the impairment types, where there is an explict indicator of the impairment

        //     if ( entitlement.sameDayService ) {
        //         impType = isACE ? ((entitlement.CAPREeligible) ? IMPAIRMENT_TYPE_CAPRE: '') :  IMPAIRMENT_TYPE_SAME_DAY_SERVICE;
        //     }


        //     isCanceled = !String.IsBlank(membership?.cancelCode);

        //     inArrears = membership.inArrears.equalsIgnoreCase('Y');
        //     inRenewal = !String.IsBlank(membership?.inRenewal);

        //     Integer expiredCutoff = 95;
        //     if ( isACMO ) {
        //         expiredCutoff = 60;
        //     }
    
        //     if  (inArrears || inRenewal  ) {
        //         Integer numDaysPastExpiration = getDaysPastExpiration(membership.renewalExpirationDate);

        //         if ( numDaysPastExpiration < 0) {
        //         }
        //         else if (numDaysPastExpiration <= 30) {
        //             impType =  IMPAIRMENT_TYPE_UNPAID_GRACE_PERIOD;
        //         }
        //         else if ( numDaysPastExpiration <=  expiredCutoff ) {
        //             impType = IMPAIRMENT_TYPE_EXPIRED_31_95_DAYS;
        //         }
        //         else {
        //             impType = IMPAIRMENT_TYPE_CANCELED;
        //         }

        //     } else if (isCanceled) {
        //         impType = IMPAIRMENT_TYPE_CANCELED;
        //     }
            
        //     if (isSvcCharge && !isCanceled) {
        //         impType = IMPAIRMENT_TYPE_SERVICE_CHARGE;
        //     }
            
        //     return impType;
        // }

        private String categorizeImpairmentCDX(FSL_LightningCustomerWrapper customerWrapper) {

            String impType = '';

            if ( customerWrapper.membership.authorizationLevel == null ||
                  customerWrapper.membership.authorizationLevel.equalsIgnoreCase('C') ||
                  customerWrapper.membership.memberStatus == 'Cancelled' ||
                  String.IsBlank(customerWrapper.membership.authorizationCode)) {
                  impType = IMPAIRMENT_TYPE_CANCELED_CDX;
            }
            else if ( customerWrapper?.customProperties != null  ) {
                for(FSL_CustomPropertiesWrapper custprop : customerWrapper.customProperties) {
                    if ( custprop.name != null && custprop.name.equals(MV_CUSTOM_PROPERTY_NAME_CANCELED) ) {
                        impType = IMPAIRMENT_TYPE_CANCELED_CDX;
                        break;
                    }
                }
            }
            
            if ( customerWrapper.membership.ersAbuser?.equalsIgnoreCase('Y') ) {
                impType = IMPAIRMENT_TYPE_ERS_ABUSER;
            }
            return impType;
        }      
        
       @testVisible
        private Boolean isClubACECA(String memberId) {
             
            String clubFragment = '';
            if (!String.isBlank(memberId) && memberId.length() == 16) {
                clubFragment = memberId.substring(3,6);
            }
            return (clubFragment.equals(ACE_CLUB_CODE_FOR_CAPRE_CHECK));
        }
        
        @testVisible
        private Boolean isClubACMO(String memberId) {
             
            String clubFragment = '';
            if (!String.isBlank(memberId) && memberId.length() == 16) {
                clubFragment = memberId.substring(3,6);
            }
            return (clubFragment.equals(ACMO_CLUB_CODE));
        }

        public  void createImpairmentResolutionFeedComment(String caseId){
            // ERS-231457 change code to add a feed comment appropriate to the impairment Resolution.
            String feedComment = 'Case Feed Comment';
            Case ersCase = dao.fetchCaseWithImpairmentsInfo(caseId);
            if ( ersCase != null ) {
                Id impId = ersCase.Impairment__c;
                ERS_Impairment__c impairment = dao.fetchImpairmentById(impId);
                if (impairment != null ) {

                    if ( ersCase.Status == 'Canceled') {
                        feedComment = impairment.Cancel_Service_Comment__c;
                    }
                    else if ( ersCase.Impairment_Payment_Collected__c ) {
                        feedComment = impairment.Payment_Collected_Comment__c;
                    }
                    else if ( ersCase.Impairment_COD_Payment__c ) {
                        feedComment = impairment.COD_Comment__c;
                    }
                    else if ( ersCase.Impairment_Supervisor_Override__c ) {
                        feedComment = impairment.Override_Comment__c + ' '+ersCase.Impairment_Comments__c + ' Override reason : ' + ersCase.Impairment_Override_Reason__c;
                    }
                    dao.insertFeedItem(caseId, feedComment);
                }
            }
        }

        @testVisible
        private Integer getDaysPastExpiration(String renewalExpirationDate) {
            Date nextTermExpiration;
            Integer daysPastExpiration = -1;
            try {
                nextTermExpiration  =  Date.parse(renewalExpirationDate);
                nextTermExpiration = nextTermExpiration.addYears(-1);
                Date thisDay = Date.today();
                daysPastExpiration = 0 - thisDay.daysBetween(nextTermExpiration);
            }
            catch (exception ex) {
                // In this case just let the return value be -1
            }
            return daysPastExpiration;
        }
    }
 
}

//    If either in Arrers with VALD or NONR but