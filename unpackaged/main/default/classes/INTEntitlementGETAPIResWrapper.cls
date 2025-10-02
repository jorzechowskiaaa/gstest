/**** Apex Class Name    :    INTEntitlementGETAPIResWrapper
* Description        :    This class is used to prepare response for entitlement get api call   
* Modification Log   :
* Test Class Name    :    INTEntitlementGETAPITest
* ---------------------------------------------------------------------------
* Developer                   Date                   Description
* ---------------------------------------------------------------------------
* Sravani Kancharla          Sep 03 2021             Created
*********************************************************************************/

global class INTEntitlementGETAPIResWrapper {
    public String statusCode{get;set;}
    public String statusDescription{get;set;}
    public String membershipId{get;set;}
    public String accountId{get;set;}
    public List<Entitlements> entitlements;
    public List<MemberVehicles> memberVehicles{get;set;}
    public List<ServiceAppointments> serviceAppointments{get;set;}

    public class Entitlements{
        public String id{get;set;}
        public String entitlementsAllotted{get;set;}
        public String entitlementsUsed{get;set;}
        public String membershipId{get;set;}
        public String entitlementsRemaining{get;set;}
        public String membershipType{get;set;}
        public String membershipStatus{get;set;}
        public String startDate{get;set;}
        public String expirationDate{get;set;}   
    }
    public class MemberVehicles{
        public String id{get;set;}
        public String vehicleMake{get;set;}
        public String vehicleModel{get;set;}
        public String vehicleYear{get;set;}
        public String vehicleColor{get;set;}
    }
    public class ServiceAppointments{
        public String id{get;set;}
        public String appointmentAssistantURL{get;set;}
        public String serviceType{get;set;}
        public MemberVehicles memberVehicle{get;set;}
        public string hasSpareTire{get;set;}
        public string lockedOutType{get;set;}
        public string typeOfFuel{get;set;}
    }  

}