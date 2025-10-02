/**** Apex Class Name    :    INTEntitlementGETAPI
    * Description        :    This class is used to return the entitlement details, member vehicles, and ongoing service appointments using membership id.   
    * Modification Log   :
    * Test Class Name    :    INTEntitlementGETAPITest
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Sravani Kancharla           Sep 03 2021             Created
    * Raja Sandeep Angara		  Feb 07 2022			  updated ApptBookingInfoUrl
*********************************************************************************/

@RestResource(urlMapping='/Entitlements/*')
global with sharing class INTEntitlementGETAPI {
    public static String membershipId;
    public static String accountId;
    public static String mockString;
    
    @HttpGet
    global static INTEntitlementGETAPIResWrapper getEntitlements() {
        INTEntitlementGETAPIResWrapper resp = new INTEntitlementGETAPIResWrapper();
        RestRequest request = RestContext.request;
        try{
            membershipId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
            System.debug('membershipId ' +membershipId);
            List<INTEntitlementGETAPIResWrapper.Entitlements> entitRes = INTEntitlementGETAPI.entitlementBuilder();
            
            resp.membershipId           = membershipId;
            resp.accountId              = accountId;
            resp.entitlements           = entitRes;
            resp.statusCode             = ACG_ConstantsClass.STATUS_CODE_200;
            resp.statusDescription      = ACG_ConstantsClass.SUCCESS;
            FSL_ApplicationLogCreator.integrationLog (membershipId,JSON.serialize(resp),'INTENTITLEMENTS API','INTENTITLEMENTS',false,null,null);
            //List<INTEntitlementGETAPIResWrapper.MemberVehicles> memVehRes = INTEntitlementGETAPI.memberVehiclesBuilder();
            //List<INTEntitlementGETAPIResWrapper.ServiceAppointments> servapptRes = INTEntitlementGETAPI.serviceApptBuilder();
            //resp.memberVehicles         = memVehRes;
            //resp.serviceAppointments    = servapptRes;
        }
        catch(Exception e){
            resp.statusCode =ACG_ConstantsClass.STATUS_CODE;
            resp.statusDescription = System.label.INTENT_MEMNOTFOUND;
	        String ErrorMessage = e.getStackTraceString()+'Line Number:'+e.getLineNumber()+''+e.getMessage();
			FSL_ApplicationLogCreator.integrationLog (membershipId,JSON.serialize(resp),'INTENTITLEMENTS API','INTENTITLEMENTS',true,ErrorMessage,null);        }
        return resp;
    }

     /*
     * Method name            : entitlementBuilder
     * Description            : This method is used to return the entitlement deails of a membership id
     * @return Object         : returns the entitlement response wrapper 
    */

    public static List<INTEntitlementGETAPIResWrapper.Entitlements> entitlementBuilder(){
        INTMembershipLookupResponse_Wrapper response;
        if(Test.isRunningTest()){
            response = (INTMembershipLookupResponse_Wrapper) JSON.deserialize(mockString, INTMembershipLookupResponse_Wrapper.class);
        }else{
            response = INTMembershipLookupAPI.getMemberlookup(membershipId);
        }
        if(response.STATUS_CODE == 200){
            INTMembershipLookupResponse_Wrapper.Customer customer = response.customers.customer[0];
            if(customer.isLocalClub == true ){ //&& (customer.membershipStatus == 'Active' || customer.membershipStatus == 'A')
                return getContractDetails(customer);                            // Local club Members
            }else{
                return getEntitlementDetailsFromLookup(customer);       // Out club Members
            } 
        }else{
            return null;
        }     
    }

    @testVisible
    private static void mockResponse(String response){
        mockString = response;
    }

    public static List<INTEntitlementGETAPIResWrapper.Entitlements> getEntitlementDetailsFromLookup(INTMembershipLookupResponse_Wrapper.Customer customer){
        List<INTEntitlementGETAPIResWrapper.Entitlements> entitlements = new List<INTEntitlementGETAPIResWrapper.Entitlements>();
        INTEntitlementGETAPIResWrapper.Entitlements entit = new INTEntitlementGETAPIResWrapper.Entitlements();
            entit.entitlementsAllotted          = String.valueOf(customer.entitlement.callsAllowed);
            entit.entitlementsUsed              = String.valueOf(customer.entitlement.callsUsed);
            entit.entitlementsRemaining         = String.valueOf(customer.entitlement.callsRemaining);
            entit.membershipId                  = customer.membershipId;
            entit.membershipType                = customer.membershipType;
            entit.membershipStatus              = customer.membershipStatus;
            entit.startDate                     = customer.startDate;
            entit.expirationDate                = customer.expirationDate;
            entitlements.add(entit);
        return entitlements;
    }

    public static List<INTEntitlementGETAPIResWrapper.Entitlements> getContractDetails(INTMembershipLookupResponse_Wrapper.Customer customer){
        List<INTEntitlementGETAPIResWrapper.Entitlements> entitlements = new List<INTEntitlementGETAPIResWrapper.Entitlements>();
        Date eDate = (customer.expirationDate != null && customer.expirationDate.length() > 0) ? Date.ValueOf(customer.expirationDate) : System.Today().addDays(1);
        Date sDate = (customer.startDate != null && customer.startDate.length() > 0) ? Date.ValueOf(customer.startDate) : eDate.addDays(-10);

        List<ServiceContract> contracts = [SELECT Id, AccountId, AAA_ACA_Membership_Status__c, AAA_ACA_Membership16ID__c, 
                                            AAA_ACA_Membership_Type__c, StartDate, EndDate, AAA_Total_of_Calls_Allowed__c, 
                                            AAA_Total_of_Calls_Consumed__c, AAA_Total_of_Calls_Remaining__c 
                                            FROM ServiceContract 
                                            WHERE AAA_ACA_Membership16ID__c = :membershipId 
                                            AND (EndDate =: eDate OR StartDate =: sDate)];

        INTEntitlementGETAPIResWrapper.Entitlements entit = new INTEntitlementGETAPIResWrapper.Entitlements();
        entit.membershipId                  = customer.membershipId;        // contract.AAA_ACA_Membership16ID__c;
        entit.membershipType                = customer.membershipType;      // contract.AAA_ACA_Membership_Type__c;
        entit.membershipStatus              = customer.membershipStatus;    // contract.AAA_ACA_Membership_Status__c;
        entit.startDate                     = customer.startDate;           // String.valueOf(contract.StartDate);
        entit.expirationDate                = customer.expirationDate;      // String.valueOf(contract.EndDate);
        if(!contracts.isEmpty()){
            accountId = contracts[0].AccountId != null ? contracts[0].AccountId : '';
            for(ServiceContract contract : contracts){
                entit.id = contract.Id;
                entit.entitlementsAllotted          = String.valueOf(contract.AAA_Total_of_Calls_Allowed__c);
                entit.entitlementsUsed              = String.valueOf(contract.AAA_Total_of_Calls_Consumed__c);
                entit.entitlementsRemaining         = String.valueOf(contract.AAA_Total_of_Calls_Remaining__c);  
            }
        }
        entitlements.add(entit);
        return entitlements;
    }
    
    
    /*public static INTEntitlementGETAPIResWrapper.Entitlements entitlementBuilder(){
        INTEntitlementGETAPIResWrapper.Entitlements entit = new INTEntitlementGETAPIResWrapper.Entitlements();
        String memberNumber15Degit = membershipId.subString(0,15)+'%';
        Account accountInfo =  [SELECT ACG_Entitlements_Allotted__c,ACG_Entitlements_Used__c,ACG_AAA_Membership__c FROM Account WHERE (ACG_AAA_Membership__c =:membershipId OR ACG_AAA_Membership__c like : memberNumber15Degit)];
        accountId = accountInfo.Id;
        updateMembershipDetails(membershipId,accountId);
        entit.id = accountInfo.Id;
        entit.entitlementsAllotted = String.valueOf(accountInfo.ACG_Entitlements_Allotted__c);
        entit.entitlementsUsed = String.valueOf(accountInfo.ACG_Entitlements_Used__c);
        entit.membershipId = accountInfo.ACG_AAA_Membership__c; 
        return entit;      
    }*/
    
     /*
     * Method name            : memberVehiclesBuilder
     * Description            : This method is used to return the member vehicle deails of an account id
     * @return Object         : returns the member vehicles response wrapper 
    */
    
     /*public static List<INTEntitlementGETAPIResWrapper.MemberVehicles> memberVehiclesBuilder(){
        List<INTEntitlementGETAPIResWrapper.MemberVehicles> membervehlist = new List<INTEntitlementGETAPIResWrapper.MemberVehicles>();
        for(FSL_Member_Vehicle__c memveh : [SELECT Vehicle_Make__c,Vehicle_Model__c,Vehicle_Year__c,Vehicle_Color__c FROM FSL_Member_Vehicle__c WHERE ACG_Member__c = :accountId]){
            INTEntitlementGETAPIResWrapper.MemberVehicles memberveh = new INTEntitlementGETAPIResWrapper.MemberVehicles();
            memberveh.id = memveh.Id;
            memberveh.vehicleMake = memveh.Vehicle_Make__c;
            memberveh.vehicleModel = memveh.Vehicle_Model__c;
            memberveh.vehicleYear = memveh.Vehicle_Year__c; 
            memberveh.vehicleColor = memveh.Vehicle_Color__c; 
            membervehlist.add(memberveh);
        }
        return membervehlist;    
    }*/
     /*
     * Method name            : serviceApptBuilder
     * Description            : This method is used to return the service appointment deails of an account id
     * @return Object         : returns the service appointment response wrapper 
    */ 
    
    /*public static List<INTEntitlementGETAPIResWrapper.ServiceAppointments> serviceApptBuilder(){
        List<INTEntitlementGETAPIResWrapper.ServiceAppointments> serapptlist = new List<INTEntitlementGETAPIResWrapper.ServiceAppointments>();
        //10-07-2021: Modified SOQL to include Service Type and Work Order Vehicle details as part of enhancement from DRR team Sharan Parikh; 02-07-2022: Added ApptBookingInfoUrl field in SOQL as per confirmation from Claire and Phani
        for(ServiceAppointment serappt : [SELECT Appointment_Assistant_URL__c, ApptBookingInfoUrl, Status, Work_Order__r.Service_Type__c,Work_Order__r.Case_Service_Type__c, Work_Order__r.Member_Vehicle__c, Work_Order__r.Member_Vehicle__r.Vehicle_Make__c, Work_Order__r.Member_Vehicle__r.Vehicle_Model__c, Work_Order__r.Member_Vehicle__r.Vehicle_Year__c, Work_Order__r.Member_Vehicle__r.Vehicle_Color__c,
                                          Work_Order__r.Case.Vehicle_Lockout_Reason__c,Work_Order__r.Case.Flat_Tire_Status__c,Work_Order__r.Case.Vehicle_Fuel_Type__c FROM ServiceAppointment WHERE Work_Order__r.Is_Draft_Work_Order__c = false and Work_Order__r.Member_Account__c = :accountId and Status NOT IN :ACG_ConstantsClass.WO_CLEAR_CANCEL_STATUS]){
            INTEntitlementGETAPIResWrapper.ServiceAppointments servappt = new INTEntitlementGETAPIResWrapper.ServiceAppointments();
            INTEntitlementGETAPIResWrapper.MemberVehicles saMemberVehicle = new INTEntitlementGETAPIResWrapper.MemberVehicles();//10-07-2021: added as part of enhancement from DRR team Sharan Parikh
            if(serappt.Status != ACG_ConstantsClass.SPOTTED){
            servappt.id = serappt.Id;
            }
            servappt.appointmentAssistantURL = serappt.ApptBookingInfoUrl;//02-07-2022: as confirmed by Claire and Phani over email, commenting serappt.Appointment_Assistant_URL__c;
            //10-07-2021: added below code as part of enhancement from DRR team Sharan Parikh
            servappt.serviceType = serappt.Work_Order__r.Case_Service_Type__c;//serappt.Work_Order__r.Service_Type__c; // 11-11-2021: changed field based on discussion with DRR team Yadav Surbhi 
            
            // 12-11-2021 : added new field mapping as part of enhancement from DRR Team 
            servappt.hasSpareTire=serappt.Work_Order__r.Case.Flat_Tire_Status__c;
            servappt.lockedOutType=serappt.Work_Order__r.Case.Vehicle_Lockout_Reason__c;
            servappt.typeOfFuel=serappt.Work_Order__r.Case.Vehicle_Fuel_Type__c;
                                              
            saMemberVehicle.id = serappt.Work_Order__r.Member_Vehicle__c;
            saMemberVehicle.vehicleMake = serappt.Work_Order__r.Member_Vehicle__r.Vehicle_Make__c;
            saMemberVehicle.vehicleModel = serappt.Work_Order__r.Member_Vehicle__r.Vehicle_Model__c;
            saMemberVehicle.vehicleYear = serappt.Work_Order__r.Member_Vehicle__r.Vehicle_Year__c; 
            saMemberVehicle.vehicleColor = serappt.Work_Order__r.Member_Vehicle__r.Vehicle_Color__c;
            servappt.memberVehicle = saMemberVehicle;
            serapptlist.add(servappt);
        }
        return serapptlist;    
    }*/
}