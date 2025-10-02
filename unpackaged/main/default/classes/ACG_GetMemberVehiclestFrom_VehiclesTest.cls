/*
* @description: Test class for ACG_GetRecordsFrom_MasterVehicle
* @date: September 28,2021
* author: Deloitte USI
*/

@isTest
public class ACG_GetMemberVehiclestFrom_VehiclesTest {
    // TEST CONSTANTS
    private static String MEMBER_FNAME = 'Joe';
    private static String MEMBER_LNAME = 'Member';
    private static String CUSTOMER_FNAME = 'Mary';
    private static String CUSTOMER_LNAME = 'Customer';
    private static String VEHICLE1_NAME = 'VehicleOne';
    private static String VEHICLE1_TYPE = 'CAR';
    private static STring VEHICLE2_NAME = 'VehicleTwo';
    private static String VEHICLE2_TYPE = '';
    
	@testSetup
    public static void testSetup(){
        //Test data for Member Vehicle
        Id customer_RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId();
        Id memberRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        Account member = new Account(FirstName=MEMBER_FNAME, LastName=MEMBER_LNAME ,RecordTypeId = memberRecordtypeId,ACG_Primary_Phone_Type__c = 'Home',ACG_Is_Primary_Member_in_Household__c = true);
        insert member;
        Account customer = new Account(FirstName=CUSTOMER_FNAME,LastName=CUSTOMER_LNAME,RecordTypeId = customer_RecordTypeId);
        insert customer;
        FSL_Member_Vehicle__c memberVehicle = new FSL_Member_Vehicle__c(Name=VEHICLE1_NAME,ACG_Member__c=member.Id, Vehicle_Type__c = VEHICLE1_TYPE);
        insert memberVehicle;
        FSL_Member_Vehicle__c memberVehicle2 = new FSL_Member_Vehicle__c(Name=VEHICLE2_NAME,ACG_Member__c=customer.Id, Vehicle_Type__c = VEHICLE2_TYPE);
        insert memberVehicle2;
    }
    
    @IsTest
    public static void getMemberVehicles_TEST(){
        FSL_Member_Vehicle__c vehicle1=[SELECT Id,Name From FSL_Member_Vehicle__c WHERE Name=:VEHICLE1_NAME];
        FSL_Member_Vehicle__c vehicle2=[SELECT Id,Name From FSL_Member_Vehicle__c WHERE Name=:VEHICLE2_NAME];
        
        Account member=[SELECT Id FROM Account WHERE FirstName=:MEMBER_FNAME];
        Account customer=[SELECT Id FROM Account WHERE FirstName=:CUSTOMER_FNAME];
        
        // get the list of vehicles associated with the member's id
        // we are expecting the list of vehicles created for the customer in the setup method
        List<FSL_Member_Vehicle__c> vlist1 = ACG_GetMemberVehiclesFrom_Vehicles.getMemberVehicles(member.Id);
        Assert.isNotNull(vlist1, 'Expected null back, got something else');
        
        // get the list of vehicles associated with the customer's id
        // since the method only returns vehicles for users with the customer record type, we expect null back
        List<FSL_Member_Vehicle__c> vlist2 = ACG_GetMemberVehiclesFrom_Vehicles.getMemberVehicles(customer.Id);
        Assert.isNull(vlist2, 'Expected list of vehicles returned');
        // Map<Id,FSL_Member_Vehicle__c> vlist2Map = new Map<Id,FSL_Member_Vehicle__c>(vlist2);
        // Assert.IsTrue(vlist2Map.keyset().contains(vehicle2.Id), 'Expected vehicle 2 in the list of vehicles for the customer');

        // get the list of vehicles if null is passed as the customer's id
        // we expect the method to return null
        List<FSL_Member_Vehicle__c> vlist3 = ACG_GetMemberVehiclesFrom_Vehicles.getMemberVehicles(null);
        Assert.isNull(vlist3, 'Expected null back, got something else');
    }
    
    @istest
    public static void getVehicleType_TEST(){
        //Test Data
        FSL_Member_Vehicle__c vehicle = [SELECT Id, Vehicle_Type__c,Name FROM FSL_Member_Vehicle__c WHERE Name=:VEHICLE1_NAME];
        List<ERS_Case_VehicleType_Mapping__mdt> mdtList = [SELECT Id, Vehicle_Type_Case__c, Vehicle_Type_Master_Vehicle__c
                                                          FROM ERS_Case_VehicleType_Mapping__mdt
                                                          WHERE Vehicle_Type_Master_Vehicle__c = :vehicle.Vehicle_Type__c LIMIT 1];
        //Test Scenario
		if(!mdtList.isEmpty()){
            String strRet = ACG_GetMemberVehiclesFrom_Vehicles.getVehicleType(vehicle.Id);
            System.assertEquals(mdtList[0].Vehicle_Type_Case__c, strRet, 'ERROR');
        }
    }
    
    @IsTest
    static void getVehicleDetails_TEST() {
        String vname = 'TEST VEHICLE';
        String vtype = 'TEST TYPE';
        
        // create a master vehicle
        ACG_Master_Vehicle__c mv = new ACG_Master_Vehicle__c();
        mv.Name = vname;
        mv.Vehicle_Type__c = vtype;
        insert mv;
        
        // get the details of the master vehicle
        String details = ACG_GetMemberVehiclesFrom_Vehicles.getVehicleDetails(mv.Id);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(details);
        String returnedType = (String) m.get('Vehicle_Type__c');
        Assert.areEqual(vtype, returnedType, 'Expected matching vehicle type');
        
        // call the method and raise an exception
        try {
            ACG_GetMemberVehiclesFrom_Vehicles.getVehicleDetails('bogus-id');
        } catch(Exception ex) {
            System.debug(ex.getMessage());
        }
        
    }
	
    @IsTest
    static void getMemberVehicleDetail_TEST() {
        FSL_Member_Vehicle__c vehicle = [SELECT Id, Vehicle_Type__c,Name FROM FSL_Member_Vehicle__c WHERE Name=:VEHICLE1_NAME];
        FSL_Member_Vehicle__c result = ACG_GetMemberVehiclesFrom_Vehicles.getMemberVehicleDetail(vehicle.id);
        Assert.areEqual(vehicle.id, result.id, 'getMemberVehicleDetail_TEST - Expecting matching vehicle');
    }

    @IsTest
    static void mapVehicleType_TEST() {
        String result = ACG_GetMemberVehiclesFrom_Vehicles.mapVehicleType('Car');
        Assert.areEqual(result, 'PS (Passenger Car/Truck)', 'mapVehicleType_TEST - Error');
    }
    
}