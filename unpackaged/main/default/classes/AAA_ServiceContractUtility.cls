/*
``@description: Util class that holds all the logic for Service Contract/Entitlements
  @date: SEP 23, 2021
  @author:Salesforce Services
  @Last Modified: 
  2025-07-18 by John Orzechowski for SSFI-1239, modified createOrGetParentServiceContract method and related items for long tow logic
  2025-09-02 by John Orzechowski for SSFI-1277, commenting out impairment assignments
*/
public inherited sharing class AAA_ServiceContractUtility {
private static final Id MEMBERSC_RECORD_TYPE_ID = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get('Member').getRecordTypeId();	//Member SC
private static final Id HOUSEHOLDSC_RECORD_TYPE_ID = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();	//Household SC
    private static String accountId;
    private static Boolean updatedParentSvcKForLongTow = false;
    
/**********
*@Method Name:getOrCreateMembershipContract
*@Parameters: Customer info
*@Description: Method is to get existing SC or create New SC 
**************/    
    @TestVisible
    public static ContractInformationWrapper getOrCreateMembershipContract(INTMembershipLookupResponse_Wrapper.Customer customer, Datetime callCreateDateTime, Id personAccId) {
        System.Debug('::getOrCreateMembershipContract::info::' + customer);
        List<ServiceContract> allServiceContracts = new List<ServiceContract>();
        ContractInformationWrapper ciWrap = new ContractInformationWrapper();
        ServiceContract memberContract;
        ServiceContract parentMembership ;
        Boolean isCreateMainServiceContract = false;
        Boolean isCreateParentServiceContract = false;
        string membershipType;
        string membership16DigitID;
        string membershipHouseholdID;
        string membershipLevel;
        Date callDate = system.Today();
            accountId = personAccId;
        try{
            membershipType       =  string.isNotBlank(customer.membershipType) ? customer.membershipType : '';
            membership16DigitID  =  string.isNotBlank(customer.membershipId) ? customer.membershipId : ''; 
            if(Label.Club_Name == 'ACA') {
                membershipLevel = ACA_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
            }
            else {
                membershipLevel = NE_CallIntakeUtility.getMembershipLevel(customer.memberLevel?.toUpperCase());
            }
            ContractWrapper contract = new ContractWrapper();
            contract.membershipId = membership16DigitID;
            contract.membershipType = membershipType;
            contract.membershipLevel = membershipLevel;

            //(new List<string> {'MEMBER','RAP'}).contains(membershipType) &&
            if (membership16DigitID.length()>0 ){                
                //Create service contract in case of Member and RAP only
                isCreateMainServiceContract = true;
                system.debug('@@@@membershipType@@@'+membershipType);
                system.debug('@@@@membershipType@@@'+membershipType.contains('Member'));
                // If we have a member then we shall also check for the parent service contract (House hold service contract)
                if(membershipType.containsignorecase('Member')) {
                    isCreateParentServiceContract = true;
                    if(membership16DigitID.length()>=16){
                        membershipHouseholdID = membership16DigitID.mid(6,7);
                    }
                    else {
                        membershipHouseholdID = membership16DigitID;
                    }
                }                
            }
            System.Debug('getOrCreateMembershipContract::isCreateMainServiceContract::' + isCreateMainServiceContract);
            //Get Current Service Contract(Service Contract where MembershipId and Start Date or End Date match
            List<ServiceContract> foundContracts = getContractByMembership16ID(membership16DigitID,customer);
            system.debug('@@@ cancelled member@@@@@'+foundContracts);
            if(foundContracts != null && !foundContracts.isEmpty()){
                System.Debug('getOrCreateMembershipContract:: Found an Existing Contract.');
                //If an existing service memberhip contract found then return the same else we try to create new service membership contract 
                memberContract = foundContracts[0];
                //update the Found Contract with latest information
                memberContract = setMemberContractData(memberContract, customer, membership16DigitID);
                allServiceContracts.add(memberContract);
                parentMembership = createOrGetParentServiceContract(membershipHouseholdID,customer);
                allServiceContracts.add(parentMembership);
            }
            else {
                Boolean createNewContract = false;
                system.debug('@@@ customer.membershipStatus member@@@@@'+customer.membershipStatus);
                ERS_Impairment__c impairment;
                String impairmentId = '';
                if(customer.membershipStatus == AAA_CallIntakeUtils.MEMBER_STATUS_CANCELLED ||
                    customer.entitlement.callsAllowed <= 0) {
                    ciWrap.showImpairment = true;
                    if(customer.entitlement.callsAllowed <= 0) {
                        impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_TYPE_SALVAGED);
                    }
                    else {
                        impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED);
                    }
                    system.debug('@@@ customer.impairment member@@@@@'+impairment);
                    if ( impairment != null ) {
                        impairmentId = impairment.Id;
                    }
                    ciWrap.impairmentType = impairmentId;
                    ciWrap.membershipContract = null;
                }
                // For SSFI-1277 the impairments have been disabled, but keeping checks for setting createNewContract = true when needed
                else if(customer.membershipStatus == AAA_CallIntakeUtils.MEMBER_STATUS_PENDING
                    && customer.expirationDate != null && customer.entitlement.callsAllowed > 0) {
                    system.debug('@@@ create membershipStatus@@@@'+customer.membershipStatus);
                    system.debug('@@@ create expirationDate@@@@'+Date.ValueOf(customer.expirationDate));
                    system.debug('@@@ create expirationDate@@@@'+callDate);
                    //If a member joined in the same year and the call date is within 60 days of joinDate
                    //and member is returned as pending
                    if(customer.memberSinceDate != null && Date.ValueOf(customer.expirationDate) > callDate 
                    && Date.Valueof(customer.memberSinceDate).daysBetween(callDate) <= 60
                    && Date.Valueof(customer.memberSinceDate).daysBetween(callDate) >= 0) {
                       // impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_TYPE_PENDING_NEW_MEMBER);
                    } 
                    else if(customer.memberSinceDate != null && Date.ValueOf(customer.expirationDate) > callDate 
                    && Date.Valueof(customer.memberSinceDate).daysBetween(callDate) > 60) {
                        // impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_TYPE_PENDING_EXISTING_MEMBER);
                        createNewContract = true;
                    } 
                    else if(Date.ValueOf(customer.expirationDate) < callDate && Label.FSL_SourceClubCode == '240') {
                       // impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_UNPAID_GRACE_CALLS);
                        createNewContract = true;
                    } 
                    else if(Date.ValueOf(customer.expirationDate) < callDate) {
                       // impairment = fetchImpairmentByType(ImpairmentsHelper.IMPAIRMENT_TYPE_PENDING_RENEWAL);
                    }
                    ciWrap.showImpairment = true;
                    if ( impairment != null ) {
                        impairmentId = impairment.Id;
                    }
                    ciWrap.impairmentType = impairmentId;
                    ciWrap.membershipContract = null;
                }
                system.debug('@@@ create Contract@@@@'+ciWrap.impairmentType);
                system.debug('@@@ create Contract@@@@'+createNewContract);
                //Create New Contract for Active Members or 
                //Members that get status back as Pending but still has time left on current contract
                if(customer.membershipStatus == AAA_CallIntakeUtils.MEMBER_STATUS_ACTIVE || 
                createNewContract){ 
                    //NO Existing Contract found. Proceeding to create a new one             
                    if(isCreateMainServiceContract) {
                        memberContract = createNewServiceContract(contract, customer, personAccId);
                        System.Debug('::getOrCreateMembershipContract::Main Service Contract::' + memberContract);
                        // Add new service contract to the master list to create
                        allServiceContracts.add(memberContract);
                        System.Debug('::getOrCreateMembershipContract::allServiceContracts.Size()::' + allServiceContracts.Size() + allServiceContracts);
                    }
                    // If its not a RAP then try to associate it to the parent and create parent record (if required).                
                    if(isCreateParentServiceContract) {
                        // Get parent membership details
                        System.Debug('::UpsertWorkOrder:: START CREATING Parent Service Contract::');
                        parentMembership = createOrGetParentServiceContract(membershipHouseholdID,customer);
                        // For the house hold, we shall populate the start and finish from whatever information we have so far.                        
                        // Either we ger request from an associte membership and we create a parent service contract
                        // If we get the primary member call first or at later point, we use the same record of the household membership parent service contract
                        boolean updatedParentConrtact = false;

                        // Added Long tow logic for SSFI-1239 - check updatedParentSvcKForLongTow
                        // We shall upsert parent only if the parent has been created now OR there is an update on the record
                        if(parentMembership?.Id == null || updatedParentConrtact || updatedParentSvcKForLongTow){
                            allServiceContracts.add(parentMembership);
                        }
                    }
                }
            }
            if(!allServiceContracts.isEmpty()) {
                List<FormulaRecalcResult> results = Formula.recalculateFormulas(allServiceContracts);
                upsert allServiceContracts;
                if(parentMembership!=null && memberContract.parentServiceContractId == null){
                    System.Debug('::UpsertWorkOrder::Updating Parent Service Contract on the main contract.');
                    memberContract.parentServiceContractId = parentMembership.ID;
                    system.debug('Member contract===>'+memberContract);
                    upsert memberContract;
                }
                System.Debug('@@@@ ::UpsertWorkOrder::Finished inserting allServiceContracts'+ciWrap.membershipContract);
                ciWrap.membershipContract = memberContract;
                system.debug('@@@@ membership contract @@@@'+ciWrap.membershipContract);
                if(customer.membershipStatus == AAA_CallIntakeUtils.MEMBER_STATUS_CANCELLED) {
                    ciWrap.showImpairment = true;
                    //ciWrap.impairmentType = ImpairmentsHelper.IMPAIRMENT_TYPE_CANCELED;
                }
                //Reassign WO that got created and linked to previous SC as Renewal was in progress
                //Decrementing count on old SC
                Date newStartDate = memberContract.startDate;
                Date newEndDate = memberContract.EndDate;
                    system.debug('AGB: '+newStartDate+' '+newEndDate);
                    if(Test.isRunningTest()){
                        
                        system.debug('AGB - personAccId:'+personAccId);
                        list<WorkOrder> woTestUpdate = new list<WorkOrder>();
                        for(WorkOrder wo : [select id,Reconcile_Entitlement__c,ServiceContractId,servicecontract.AAA_Total_of_Calls_Consumed__c,Member_Account__c,CreatedDate //AGB 5.22.24 SFI-640 - added servicecontract.AAA_Total_of_Calls_Consumed__c
                                            from WorkOrder 
                                           ]){
                                               system.debug('AGB WO:'+wo.Id+' '+wo.Reconcile_Entitlement__c+' '+wo.Member_Account__c+' '+wo.CreatedDate);
                                               wo.Reconcile_Entitlement__c = true;
                                               wo.Member_Account__c = personAccId;
                                               wo.ServiceContractId = memberContract.id;
                                               woTestUpdate.add(wo);
                                           }
                        if(!woTestUpdate.isEmpty())
                        {
                            update woTestUpdate;
                            system.debug('AGB: WO updated');
                        }
                    }
                list<WorkOrder> woList = new list<WorkOrder>();
                list<ServiceContract> oldContractList = new list<ServiceContract>();
                    map<Id, decimal> serviceContractUpdateMap = new map<Id, decimal>(); //AGB 5.22.24 SFI-640
                    for(WorkOrder wo : [select id,Reconcile_Entitlement__c,ServiceContractId,servicecontract.AAA_Total_of_Calls_Consumed__c,Member_Account__c,CreatedDate //AGB 5.22.24 SFI-640 - added servicecontract.AAA_Total_of_Calls_Consumed__c
                                        from WorkOrder 
                                        where Reconcile_Entitlement__c = true 
                                        AND Member_Account__c =: personAccId AND
                                        createdDate <=: newEndDate AND 
                                        createdDate >=: newStartDate
                                        ]) {
                                                if(wo.ServiceContractId != null){
                                                    //oldContractList.add(updateServiceContract(wo.ServiceContractId));
                                                    if(serviceContractUpdateMap.containsKey(wo.ServiceContractId)){ //AGB 5.22.24 SFI-640 - maintain a map of correct values for the SC in case multiple work orders reference the same SC
                                                        serviceContractUpdateMap.put(wo.ServiceContractId, serviceContractUpdateMap.get(wo.ServiceContractId) - 1);
                                                    }
                                                    else{
                                                    	serviceContractUpdateMap.put(wo.ServiceContractId, wo.servicecontract.AAA_Total_of_Calls_Consumed__c - 1);
                                                     }
                                                } //AGB 5.22.24 SFI-640 - null check
                    woList.add(updateWorkOrder(wo,memberContract.Id));
                }
                    if(serviceContractUpdateMap != null && !serviceContractUpdateMap.isEmpty()){ //AGB 5.22.24 SFI-640 - added for service contract update
                        for(String key:serviceContractUpdateMap.keySet()){
                            oldContractList.add(updateServiceContract(key,integer.valueof(serviceContractUpdateMap.get(key))));
                        }    
                    }
                if(woList != null && !woList.isEmpty()) {
                    update woList;
                }
                if(oldContractList != null && !oldContractList.isEmpty()) {
                    update oldContractList;
                }
            } 
        }
        catch(exception exp){system.debug(String.format('Exception type caught::{0},Message::{1}, Cause::{2}, Line Number::{3}, Stack Trace::{4}', new List<object> { exp.getTypeName(), exp.getMessage(),exp.getCause(), exp.getLineNumber(),exp.getStackTraceString()}));throw exp;} 
        return ciWrap;
    }
    

    public static WorkOrder updateWorkOrder(WorkOrder wo, Id scId) {
         wo.ServiceContractId = scId;
         return wo;
    }

    public static ServiceContract updateServiceContract(Id oldSCID, Integer TotalOfCallConsumed) { 
        ServiceContract oldSC = new ServiceContract();
        oldSC.Id = oldSCID;
        if(TotalOfCallConsumed == null){
        	TotalOfCallConsumed = 0;    
   }
        //oldSC.AAA_Total_of_Calls_Consumed__c = oldSC.AAA_Total_of_Calls_Consumed__c - 1;
        oldSC.AAA_Total_of_Calls_Consumed__c = TotalOfCallConsumed;
        return oldSC;
    } //AGB 5.22.24 SFI-640 - removed since oldSC wasn't queried and was returning null pointer issue */
    
/**********
* @Method Name:createNewServiceContract
*@Parameters: MembershipInformation info, Member Type, Person Contact for this service contract, Created Date Time for the Call
*@Description: Method to create a new service contract for elgible work orders as per jira story https://salesforce.atlassian.net/browse/PR893288-252
**************/ 
    @TestVisible
    private static ServiceContract createNewServiceContract(ContractWrapper ctrt, INTMembershipLookupResponse_Wrapper.Customer customer, string contactID){
        System.Debug('::createNewServiceContract::info::' + customer);
        System.Debug('::createNewServiceContract::contactID::' + contactID);
        ServiceContract newMemberContract = new ServiceContract();
        string membership16DigitID = null;
        string membershipHouseholdID = null;
        string CONST_RAP    = 'RAP';
        string CONST_MEMBER = 'MEMBER';
        try{
            if(ctrt!=null && String.isNotEmpty(ctrt.membershipID)){
                //Membership 16 Digit ID
                membership16DigitID = ctrt.membershipID;
                //If the memership number is 16 digit then take out the house hold membership ID else consider it as full in case of RAP
                if(membership16DigitID.length() >= 16){
                    membershipHouseholdID = membership16DigitID.mid(6,7);
                }else{
                    //In case of RAP lets use complete value if less than 16 digits
                    membershipHouseholdID = membership16DigitID;
                }
                System.Debug('::createNewServiceContract::membershipHouseholdID::' + membershipHouseholdID);
                if(String.isNotBlank(membership16DigitID)){
                    //In the json payload the 16 digit membership id is membership.id (ISO = 3 / Club Code = 3 / Member Id = 7 / Assoc Member Id = 2 / Check Digit = 1
                    //Example: If membership.id = 4382121353733003, then Household Member ID = 1353733
                    newMemberContract.AAA_ACA_MembershipID__c                   = membershipHouseholdID;                    
                    newMemberContract.AAA_ACA_Membership16ID__c                 = membership16DigitID;
                    newMemberContract.recordTypeId                              = MEMBERSC_RECORD_TYPE_ID;
                    //Set the values if this is RAP
                    if(customer.membershipType.equalsIgnoreCase(CONST_RAP)){
                       newMemberContract = setRAPContractData(newMemberContract,customer);
                    }else{
                        //Set the value for Member Service Contract
                        newMemberContract = setMemberContractData(newMemberContract,customer,newMemberContract.AAA_ACA_Membership16ID__c);                     
                        newMemberContract.AAA_Total_of_Calls_Consumed__c = customer.entitlement.callsUsed != null? customer.entitlement.callsUsed : 0; 
                    }
                    //In case of Membership Service Contract (Root hosuehold contract), this could be blank
                    if(String.isNotBlank(contactID)){
                        newMemberContract.AccountId = contactID;
                    }
                }
                System.Debug('::createNewServiceContract::newMemberContract::' + newMemberContract);             
            }
        }
        catch(exception exp){throw exp;}
        return newMemberContract;
    }
/**********
*@Method Name:setMemberContractData
*@Parameters: memberContract, customer infor
*@Description: Method to prepare contract information from the response for Members
**************/ 
    public static ServiceContract setMemberContractData(ServiceContract newMemberContract, INTMembershipLookupResponse_Wrapper.Customer customer, string membership16DigitID) {
        Date eDate = (customer.expirationDate != null && customer.expirationDate.length() > 0) ? Date.ValueOf(customer.expirationDate) : System.Today().addDays(1);
        Date sDate = (customer.startDate != null && customer.startDate.length() > 0) ? Date.ValueOf(customer.startDate) : eDate.addDays(-30);
        newMemberContract.AAA_ACA_ISO_Code__c                   = (membership16DigitID.length() >= 3) ? membership16DigitID.mid(0,3) :'';
        newMemberContract.AAA_ACA_Club_Code__c                  = (membership16DigitID.length() >= 6) ? membership16DigitID.mid(3,3) :'';
        newMemberContract.AAA_ACA_AssociateID__c                = (membership16DigitID.length() >= 15) ? membership16DigitID.mid(13,2) :'';
        newMemberContract.AAA_ACA_Check_Digit__c                = (membership16DigitID.length() >= 16) ? membership16DigitID.mid(15,1) :'';
        newMemberContract.AAA_ACA_Member_Status__c              = customer.membershipStatus;
        newMemberContract.AAA_ACA_Membership_Coverage_Level__c  = customer.memberLevel;
        newMemberContract.AAA_ACA_Membership_Status__c          = customer.membershipStatus;
        newMemberContract.Name                                  = newMemberContract.AAA_ACA_MembershipID__c + '-' + newMemberContract.AAA_ACA_AssociateID__c;
        newMemberContract.AAA_Total_of_Calls_Allowed__c         = customer.entitlement.callsAllowed; 
        if(customer.entitlement.premierBatteryEntitled != null) {
            newMemberContract.Premier_Battery_Entitled__c           = customer.entitlement.premierBatteryEntitled;
        }
        newMemberContract.EndDate = eDate;
        newMemberContract.startDate = sDate;
        newMemberContract.Cancellation_Date__c = null;
        if(newMemberContract.AAA_ACA_AssociateID__c == '00'){
            newMemberContract.AAA_ACA_Membership_Type__c = 'Primary';
        }else{
            newMemberContract.AAA_ACA_Membership_Type__c = 'Associate';
        }    
        system.debug('@@@@@@ Date@@@'+customer.cancellationDate);
        if(customer.membershipStatus == 'Cancelled' && !string.isBlank(customer.cancellationDate)){
            newMemberContract.Cancellation_Date__c = Date.valueOf(customer.cancellationDate);
        }
        return newMemberContract;               
    }
/**********
* @Method Name:setRAPContractData
*@Parameters: memberContract, customer infor
*@Description: Method to prepare contract information from the response for RAP
**************/ 
    public static ServiceContract setRAPContractData(ServiceContract newMemberContract, INTMembershipLookupResponse_Wrapper.Customer customer) {
        system.debug('@@@customer Exn Date@@@'+customer.expirationDate);
        string CONST_RAP    = 'RAP';
        Date eDate = (customer.expirationDate != null && customer.expirationDate.length() > 0) ? Date.ValueOf(customer.expirationDate) : System.Today().addDays(1);
        Date sDate = (customer.startDate != null && customer.startDate.length() > 0) ? Date.ValueOf(customer.startDate) : eDate.addDays(-1);
        newMemberContract.AAA_ACA_Membership_Type__c            = customer.membershipType;
        newMemberContract.Name                                  = newMemberContract.AAA_ACA_Membership16ID__c + '-' + CONST_RAP;
        newMemberContract.AAA_ACA_RAP_ID__c                     = newMemberContract.AAA_ACA_MembershipID__c;
        newMemberContract.AAA_ACA_RAP_Program__c                = customer.program;
        newMemberContract.AAA_ACA_RAP_Sponsor__c                = customer.sponsor;                             
        newMemberContract.StartDate                             = sDate;
        newMemberContract.EndDate                               = eDate;
        newMemberContract.AAA_Total_of_Calls_Allowed__c         = customer.entitlement.callsAllowed;
        newMemberContract.Premier_Battery_Entitled__c	        = customer.entitlement.premierBatteryEntitled;   
        return newMemberContract;               
    }
    
/**********
* @Method Name:createOrGetParentServiceContract
*@Parameters: membershipHouseholdID represents the 7-13 digits of the 16 Digit membership ID
*@Description: Method to create a new Parent service contract for elgible work orders as per jira story https://salesforce.atlassian.net/browse/PR893288-252
**************/ 
    private static ServiceContract createOrGetParentServiceContract(string membershipHouseholdID, INTMembershipLookupResponse_Wrapper.Customer customer){
        string CONST_MEMBER = 'Member';        
        ServiceContract parentMemberContract;
        try{
            if(String.isNotBlank(membershipHouseholdID)) {
                Date peDate = (customer.primaryExpirationDate != null && customer.primaryExpirationDate.length() > 0) ? Date.ValueOf(customer.primaryExpirationDate) : System.Today().addDays(1);
                Date psDate = (customer.primaryStartDate != null && customer.primaryStartDate.length() > 0) ? Date.ValueOf(customer.primaryStartDate) : peDate.addDays(-30);
                List<ServiceContract> foundContracts = getContractByMembershipID(membershipHouseholdID, CONST_MEMBER,customer);
                if(foundContracts.isEmpty()){
                    System.Debug('::createOrGetParentServiceContract:: NO Parent Contract Found. Need to create a new one.');
                    parentMemberContract = new ServiceContract();
                    parentMemberContract.Name                        = membershipHouseholdID;
                    parentMemberContract.AAA_ACA_Membership_Type__c  = CONST_MEMBER;
                    parentMemberContract.AAA_ACA_MembershipID__c     = membershipHouseholdID;   
                    // parentMemberContract.AAA_Long_Tow_Allowed__c = customer.entitlement.longTowAllowed;

                    // long tow logic for SSFI-1239
                    parentMemberContract.AAA_Long_Tow_Allowed__c     =  (customer.memberLevel == 'Premier' || customer?.memberLevel == 'Premier RV' ) ? True : False;   

                    //ACA specific fix and will be/ need to be commented out for NE as it is not applicable
                    parentMemberContract.AAA_Total_of_Calls_Allowed__c   = customer.entitlement.callsAllowed;
                    parentMemberContract.recordTypeId               = HOUSEHOLDSC_RECORD_TYPE_ID;
                    parentMemberContract.startDate = psDate;
                    parentMemberContract.EndDate = peDate;
                    if(peDate < psDate) {
                        parentMemberContract.startDate = Date.valueOf(customer.startDate);
                        parentMemberContract.EndDate = Date.valueOf(customer.expirationDate);
                    }
                    system.debug('@@@@parent@@@'+parentMemberContract);
                    //parentMemberContract.AAA_Same_Day_Service__c = customer.entitlement.sameDayService;
                }else{
                    System.Debug('::createOrGetParentServiceContract:: Found an Existing Parent Service Contract::');
                    parentMemberContract = foundContracts[0];
                    //ACA specific fix and will be/ need to be commented out for NE as it is not applicable
                    parentMemberContract.AAA_Total_of_Calls_Allowed__c =  customer.entitlement.callsAllowed;

                    // Long tow logic for SSFI-1239
                    if( parentMemberContract.AAA_Long_Tow_Allowed__c == False && (customer.memberLevel == 'Premier' || customer.memberLevel == 'Premier RV') ) {
                        parentMemberContract.AAA_Long_Tow_Allowed__c = True;
                        updatedParentSvcKForLongTow = True; 
                    }

                    UpdateStartEndDateOnContract(parentMemberContract,psDate,peDate);
                    system.debug('@@@@parent2@@@'+parentMemberContract);
                }
            } 
            System.Debug('::createOrGetParentServiceContract:: Parent Service Contract::' + parentMemberContract);
        }
        catch(exception exp){throw exp;} 
        return parentMemberContract;
    }
    
    private static void UpdateStartEndDateOnContract(ServiceContract newMemberContract, Date startDate, Date expirationDate){
        try{
            //If expiration Date or StartDate is not null in the D3 Payload, set the value from the payload
            newMemberContract.EndDate = expirationDate != null ? expirationDate : System.Today();
            newMemberContract.startDate = startDate != null ? startDate : System.Today();
        }
        catch(exception exp){throw exp;}
    }
/**********
* @Method Name:getContractByMembership16ID
*@Parameters: 16 Digit membership ID
*@Description: Retrieves existing Contract with 16 Digit membership ID and startDate search
*@Modified: Added AAA_Long_Tow_Allowed__c to query for SSFI-1239
**************/ 
    @TestVisible    
    private static List<ServiceContract> getContractByMembership16ID(string membershipNumber, INTMembershipLookupResponse_Wrapper.Customer customer){
        List<ServiceContract> memberContract ;
        try{
            Date eDate = (customer.expirationDate != null && customer.expirationDate.length() > 0) ? Date.ValueOf(customer.expirationDate) : System.Today().addDays(1);
            Date sDate = (customer.startDate != null && customer.startDate.length() > 0) ? Date.ValueOf(customer.startDate) : eDate.addDays(-10);
            System.Debug('::getContractByMembership16ID::membershipNumber::' + membershipNumber);
            if(String.isNotBlank(membershipNumber) && membershipNumber != null){
                memberContract = [Select Id, AAA_ACA_Membership_Type__c,AAA_ACA_Membership16ID__c, 
                StartDate, EndDate, AAA_ACA_Member_Status__c, AAA_ACA_MembershipID__c,parentServiceContractId,
                AAA_ACA_Membership_Status__c, AAA_ACA_Membership_Coverage_Level__c,
                AAA_Total_of_Calls_Allowed__c,AAA_Total_of_Calls_Remaining__c,AAA_Total_of_Calls_Consumed__c,AAA_Total_of_Reciprocals__c,AAA_Long_Tow_Allowed__c   
                from ServiceContract where 
                        AccountId =:accountId 
                        AND AAA_ACA_Membership16ID__c =: membershipNumber
                    AND (EndDate =: eDate OR StartDate =: sDate)
                ];           
            } 
            System.Debug('::getContractByMembership16ID::memberContract::' + memberContract?.Size() + ' , ' + memberContract);
        }
        catch(exception exp){throw exp;}
        return memberContract;
    }
        
/**********
* @Method Name:getContractByMembership16ID
*@Parameters: hosueHoldMembershipID represents the 7-13 digits of the 16 Digit membership ID
*@Description: Retrieves existing house hold membership with hosueHoldMembershipID search
*@Modified: Added AAA_Long_Tow_Allowed__c to query for SSFI-1239
**************/ 
    @TestVisible
    private static List<ServiceContract> getContractByMembershipID(string hosueHoldMembershipID, string memberType,INTMembershipLookupResponse_Wrapper.Customer customer){
        List<ServiceContract> memberContract;
        try{
            Date eDate = (customer.primaryExpirationDate != null && customer.primaryExpirationDate.length() > 0) ? Date.ValueOf(customer.primaryExpirationDate) : System.Today().addDays(1);
            Date sDate = (customer.primaryStartDate != null && customer.primaryStartDate.length() > 0) ? Date.ValueOf(customer.primaryStartDate) : eDate.addDays(-10);
            System.Debug('::getContractByMembershipID::hosueHoldMembershipID::' + hosueHoldMembershipID + ' ,memberType::' + memberType);            
            if(String.isNotBlank(hosueHoldMembershipID)){
                memberContract = [Select Id, AAA_ACA_Membership_Type__c,AAA_ACA_Membership16ID__c, AAA_ACA_MembershipID__c,
                StartDate, EndDate,AAA_Long_Tow_Consumed__c,AAA_Long_Tow_Allowed__c from ServiceContract 
                where AAA_ACA_MembershipID__c =:hosueHoldMembershipID 
                and AAA_ACA_Membership_Type__c= :memberType 
                and (EndDate =: eDate OR StartDate =: sDate)];            
            }
        }
        catch(exception exp){throw exp;}
        return memberContract;
    }

    public static ERS_Impairment__c fetchImpairmentByType(String impType) {
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
    
/**********
* @Method Name:updateLongTowConsumed
* @Parameters: contract Id and longTowConsumed
* @Description: Updates the contract with Long Tow Consumed. This is triggered after workorder gets updated with Long Tow
**************/   
    public static Boolean updateLongTowConsumed(String contractId, Boolean longTowConsumed){
        ServiceContract sc = new ServiceContract();
        sc.Id = contractId;
        sc.AAA_Long_Tow_Consumed__c = longTowConsumed;
        Database.SaveResult sr = Database.update(sc, false);
        return sr.isSuccess();
    }

    public class ContractInformationWrapper {
        public ServiceContract membershipContract;
        public string impairmentType;
        public boolean showImpairment;
    }
    
    public class ContractWrapper {
        @AuraEnabled
        public String membershipLevel;
        @AuraEnabled
        public String membershipType;
        @AuraEnabled
        public String membershipId;
    }
}