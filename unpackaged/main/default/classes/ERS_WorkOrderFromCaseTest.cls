/**
 * @description       : 
 * @author            : Clement Shiu
 * @group             : 
 * @last modified on  : 08-27-2025
 * @last modified by  : 
  * Modification Log   :
 * ---------------------------------------------------------------------------
 * Developer                   Date                   Description
 * ---------------------------------------------------------------------------
**/
@isTest
public class ERS_WorkOrderFromCaseTest {

    @testSetup
    public static void testSetup(){
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Id Member_RecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        Id RepairShop_RecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_AAR').getRecordTypeId();
        
        Account Member = new Account(FirstName ='TestPersonAcc', LastName = 'ERS**', RecordTypeId = Member_RecTypeId, ACG_Is_Primary_Member_in_Household__c = true,AAA_Membership_Level__c = 'Plus',ACG_Membership_Status__c = 'Active');
        insert Member;
        
        Account repairShop = new Account(Name = 'Test RepairShop', RecordTypeId = RepairShop_RecTypeId, ACG_Primary_Phone_Type__c = (Account.ACG_Primary_Phone_Type__c.getDescribe().getPicklistValues())[0].getLabel());
        insert repairShop;
        
        FSL_Member_Vehicle__c vehicleRec = new FSL_Member_Vehicle__c(Name = '2022 ACURA TLX GREEN',Vehicle_Type__c = 'Car',ACG_Member__c = Member.Id);
        insert vehicleRec;
        
        /*Test data for createWO_TEST method*/
        List<ERS_Case_to_Work_Type_Mapping__mdt> mdtList = [SELECT Id, Work_Type__c FROM ERS_Case_to_Work_Type_Mapping__mdt];
        List<WorkType> lstWorkType = new List<WorkType>();
        for(ERS_Case_to_Work_Type_Mapping__mdt mdtRec : mdtList){
            lstWorkType.add(new WorkType(Name = mdtRec.Work_Type__c, EstimatedDuration = 10.0, DurationType = 'Minutes'));
        }
        if(!lstWorkType.isEmpty()){
            insert lstWorkType; 
        }
        
        Case caseRec = new Case(RecordTypeid = ERS_RecTypeId,Subject = '!@#ERSCase_Fuel#@!',ACG_Service_Type__c = 'Fuel', Vehicle_Fuel_Type__c = 'Gas');
        caseRec.ACG_Driving_Directions__c = 'Driver Directions';
        caseRec.Acting_Agent__c = true;
        caseRec.Acting_Agent_Details__c = 'Acting agent details';
        caseRec.ACG_Pick_up_Point_Comments__c = 'Pick-up point comments';
        caseRec.ACG_Member_Location_Address__c = 'Member Location Address';
        caseRec.ACG_Member_Location_Comments__c = 'Member Location comments';
        caseRec.ACG_Member_present_at_Vehicle__c = true;
        caseRec.ERS_Event_Type__c = (Case.ERS_Event_Type__c.getDescribe().getPicklistValues())[0].getLabel();
        caseRec.AccountId = Member.Id;
        caseRec.Over_Entitlement_Fee_Paid__c = true;
        caseRec.ACG_Case_Contact_Number__c = '1223334444';
        caseRec.Member_Vehicle__c = vehicleRec.Id;
        caseRec.Member_Vehicle_Type__c = (Case.Member_Vehicle_Type__c.getDescribe().getPicklistValues())[0].getLabel();
        caseRec.ACG_Vehicle_Location_Type__c = (Case.ACG_Vehicle_Location_Type__c.getDescribe().getPicklistValues())[0].getLabel();
        caseRec.Vehicle_Geolocation__Latitude__s = 34.0421430591411; 
        caseRec.Vehicle_Geolocation__Longitude__s = -77.89695195296845;
        caseRec.Critical_Call_Reason__c = (Case.Critical_Call_Reason__c.getDescribe().getPicklistValues())[0].getLabel();       //create the other case with Case_Priority_Override_Reason__c
        caseRec.Vehicle_Location_Street__c = 'Vehcile location street';
        caseRec.Vehicle_Location_City__c = 'City';
        caseRec.Vehicle_Location_State__c = 'CA';
        caseRec.Vehicle_Location_Country__c = 'United States';
        caseRec.Vehicle_Location_Postal_Code__c = '01970';
        caseRec.Call_Origin__c ='Call Origin';
        caseRec.ACG_Collision__c =true;
        caseRec.Number_of_passengers__c = 2;
        caseRec.Tow_Request_Reason__c = 'Alternator';
        caseRec.Tow_Request_Miscellaneous_Details__c = 'Tow Request Misc Details';
        caseRec.Flatbed_Required__c = true;
        caseRec.Requested_Destination_Unavailable__c = true;
        caseRec.Contact_at_Drop_off__c = 'Contact at Drop off';
        caseRec.Total_Mileage__c = 100;
        caseRec.Special_Equipment_Selection__c = (Case.Special_Equipment_Selection__c.getDescribe().getPicklistValues())[0].getLabel();
        caseRec.Priority = (Case.Priority.getDescribe().getPicklistValues())[0].getLabel();
        caseRec.Tow_Destination_Street__c = 'Tow dest street';
        caseRec.Tow_Destination_City__c = 'Tow dest city';
        caseRec.Tow_Destination_State__c = 'CA';
        caseRec.Tow_Destination_Country__c = 'United States';
        caseRec.Tow_Destination_Postal_Code__c = '01970';
        caseRec.Tow_Geolocation__Latitude__s = 34.0421430591411;
        caseRec.Tow_Geolocation__Longitude__s = -77.89695195296845;
        caseRec.Repair_Shop__c = repairShop.Id;
         // added for SSFI-1351
        caseRec.ACG_Color__c = 'Blue';
        caseRec.ACG_Year__c = '2022';
        caseRec.ACG_Make__c = 'OTHER';
        caseRec.ACG_Model__c = 'Two door';
        insert caseRec;
        
        Case caseRec_Tow = new Case(RecordTypeid = ERS_RecTypeId,Subject = '!@#ERSCase_Tow#@!', ACG_Service_Type__c = 'Tow');
        caseRec_Tow.Case_Priority_Override__c = true;
        caseRec_Tow.Case_Priority_Override_Reason__c = 'Priority Override Reason';
        insert caseRec_Tow;
        /*End-of Test data*/
        
        /*Test Data for workOrderIntake_TEST */
        Zip_Code__c customSetting = new Zip_Code__c(Name = '28428',Club_Name__c ='AAA Carolinas' ,Club_Code__c = '111' );
        insert customSetting;

        Zip_Code__c customSetting2 = new Zip_Code__c(Name = '27516',Club_Name__c ='AAA Carolinas' ,Club_Code__c = '111' );
        insert customSetting2;
       
        Zip_Code__c customSetting3 = new Zip_Code__c(Name = '28212',Club_Name__c ='AAA Carolinas' ,Club_Code__c = '111' );
        insert customSetting3;

        Zip_Code__c customSetting4 = new Zip_Code__c(Name = '01970',Club_Name__c ='AAA Northeast' ,Club_Code__c = '240' );
        insert customSetting4;
       
        WorkType WT_Rec3 = new WorkType(Name = 'Non-RV Extrication', EstimatedDuration = 10.0, DurationType = 'Minutes');
        insert WT_Rec3;

        List<Membership_Coverage_Metadata__mdt> coverages = [SELECT Id FROM Membership_Coverage_Metadata__mdt ];
        Membership_Coverage_Metadata__mdt settings = new Membership_Coverage_Metadata__mdt();
        settings.State__c = 'CA' ;
        settings.Service_Type__c = 'Fuel' ;
        settings.ACE__c = true ;
        settings.Vehicle_Type__c = 'PS (Passenger Car/Truck);' ;
        settings.Membership_Level__c = 'BASIC'; 

        coverages.add(settings) ; 
        
    }
    
    @isTest
     public static void workOrderIntake_TEST(){
        //Test Data
        Account Member = [SELECT Id FROM Account WHERE FirstName ='TestPersonAcc' AND LastName = 'ERS**' LIMIT 1 ];
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        
        Case objCase = new Case(RecordTypeId = ERS_RecTypeId, Subject = '**WO Intake Test Case**');
        objCase.ACG_Service_Type__c = 'Battery';
        objCase.BSP_Available__c = 'No';
        objCase.AccountId = Member.Id;
        objCase.ACG_Case_Contact_Number__c = '1223334444';
        objCase.Over_Entitlement_Fee_Paid__c = true;
        Test.startTest();
        insert objCase;
                
        ERS_WorkOrderFromCase.WrapperClass wrapper = new ERS_WorkOrderFromCase.WrapperClass();
        
       //Test Scenario 1 (Validate case throws error) 
        try{
            wrapper = ERS_WorkOrderFromCase.workOrderIntake(objCase.Id);
           }catch(Exception e){
                System.assertEquals(true, (e.getMessage()).containsIgnoreCase('Breakdown information is missing'), 'Validate Case method failed'+e.getMessage());
           }     
            
        //Test Scenario 2 (Validate location throws error)
        FSL_Member_Vehicle__c vehicle = [SELECT Id,Vehicle_Year__c,Vehicle_Make__c,Vehicle_Model__c FROM FSL_Member_Vehicle__c WHERE Name = '2022 ACURA TLX GREEN' LIMIT 1];
        objCase.Member_Vehicle__c = vehicle.Id;
        objCase.Member_Vehicle_Type__c = (Case.Member_Vehicle_Type__c.getDescribe().getPicklistValues())[0].getLabel();
        objCase.ACG_Year__c = vehicle.Vehicle_Year__c;
        objCase.ACG_Make__c = vehicle.Vehicle_Make__c;
        objCase.ACG_Model__c = vehicle.Vehicle_Model__c;
        objCase.Appointment_Requested__c = false;
        objCase.ACG_Vehicle_Location_Address__c = '318 Broadway, New York, NY 10007, USA';
        objCase.Vehicle_Location_Street__c = '318 Broadway'; 
        objCase.Vehicle_Location_City__c = 'New York';
        objCase.Vehicle_Location_State__c = 'NY';
        objCase.Vehicle_Location_Country__c = 'United States';
        objCase.Vehicle_Location_Postal_Code__c = '10007';
        objCase.Vehicle_Geolocation__latitude__s = 40.71589804488142; 
        objCase.Vehicle_Geolocation__longitude__s = -74.00459950898437;
        objCase.ACG_Member_present_at_Vehicle__c = true;
        objCase.ACG_Color__c = 'Blue';
        objCase.ACG_Year__c = '2011' ;
        objCase.ACG_Make__c = 'Ford' ;
        objCase.ACG_Model__c = 'F-350' ;
        update objCase;
           
        try{
            Case objCase1 = [SELECT Id,  AccountId,Account.ACG_Membership_Status__c, Account.PersonContactId, Account.RecordType.DeveloperName, ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                                        ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                                        ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c,
                                        Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,
                                        Call_Origin__c, Contact_at_Drop_off__c, Call_Date__c, Case_Priority_Override__c, Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                                        CDX_Phone_Number__c, Case_Membership_Level__c, Critical_Call_Reason__c,Club_Name__c,CreatedDate,Channel__c,
                                        ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,
                                        Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                                        Gross_Weight__c,
                                        Landmark__c,
                                        Member_Household__c, Member_Vehicle__c, Member_Vehicle_Type__c,
                                        Number_of_passengers__c,Non_Active_Dues_Paid__c,
                                        Over_Entitlement_Fee_Paid__c,Override_Reason__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,
                                        Same_Day_Service_Fee_Paid__c,Special_Equipment_Selection__c, Status,
                                        Tow_Destination_Name__c,Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                                        Tow_Geolocation__Latitude__s, Tow_Geolocation__Longitude__s, T_Code__c, Tow_Request_Reason__c, Tow_Request_Miscellaneous_Details__c, Total_Mileage__c,
                                        Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c, Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                                        Vehicle_Geolocation__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c,ACG_Color__c
                                FROM Case 
                                WHERE Id = :objCase.Id];
            wrapper = ERS_WorkOrderFromCase.workOrderIntake(objCase1.Id);
           }catch(Exception e){
                //System.assertEquals(true, (e.getMessage()).containsIgnoreCase('This Member is not broken down in ACG Territory'), 'Validate location method failed '+e.getMessage());
           }
        
        //Test Scenario 3 (Validate membership throws error)
        objCase.ACG_Vehicle_Location_Address__c = '127 Birnamwood Dr, Chapel Hill, NC 27516, USA';
        objCase.Vehicle_Location_Street__c = '127 Birnamwood Drive'; 
        objCase.Vehicle_Location_City__c = 'Chapel Hill';
        objCase.Vehicle_Location_State__c = 'NC';
        objCase.Vehicle_Location_Country__c = 'United States';
        objCase.Vehicle_Location_Postal_Code__c = '27516';
        objCase.Vehicle_Geolocation__latitude__s =35.85980524523532; 
        objCase.Vehicle_Geolocation__longitude__s = -79.19782753203123;
        objCase.Member_Vehicle_Type__c = '4M (ATV)';
        update objCase;
        try{Case objCase2 = [SELECT Id,  AccountId,Account.ACG_Membership_Status__c, Account.PersonContactId, Account.RecordType.DeveloperName, ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                                        ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                                        ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c,
                                        Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,
                                        Call_Origin__c, Contact_at_Drop_off__c, Call_Date__c, Case_Priority_Override__c, Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                                        CDX_Phone_Number__c, Case_Membership_Level__c, Critical_Call_Reason__c,Club_Name__c,CreatedDate,Channel__c,
                                        ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,
                                        Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                                        Gross_Weight__c,
                                        Landmark__c,
                                        Member_Household__c, Member_Vehicle__c, Member_Vehicle_Type__c,
                                        Number_of_passengers__c,Non_Active_Dues_Paid__c,
                                        Over_Entitlement_Fee_Paid__c,Override_Reason__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,
                                        Same_Day_Service_Fee_Paid__c,Special_Equipment_Selection__c, Status,
                                        Tow_Destination_Name__c,Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                                        Tow_Geolocation__Latitude__s, Tow_Geolocation__Longitude__s, T_Code__c, Tow_Request_Reason__c, Tow_Request_Miscellaneous_Details__c, Total_Mileage__c,
                                        Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c, Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                                        Vehicle_Geolocation__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c
                                FROM Case 
                                WHERE Id = :objCase.Id];
            wrapper = ERS_WorkOrderFromCase.workOrderIntake(objCase2.Id);
           }catch(Exception e){
                //System.assertEquals(true, (e.getMessage()).containsIgnoreCase('You are not eligible for this service'), 'Validate Membership method failed'+e.getMessage());
           }

       Test.stopTest();
        
    }
 
    @isTest
    public static void createWO_TEST(){
        //Test Data
        Id LightService_RecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Light_Service').getRecordTypeId();
        Id Tow_RecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId();
        
        WorkType WT_Rec = new WorkType(Name = 'Battery Test', EstimatedDuration = 10.0, DurationType = 'Minutes');
        insert WT_Rec;
        
        Test.startTest();
        //Test Scenario 1 (Light Service WO)
        Case case_LS = [SELECT Id, 
                            AccountId,Account.ACG_Membership_Status__c, Account.PersonContactId, Account.RecordType.DeveloperName, ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                            ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                            ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c,
                            Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,
                        Call_Origin__c,Contact_at_Drop_off__c,Call_Date__c,Case_Priority_Override__c,Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                            CDX_Phone_Number__c, Case_Membership_Level__c, Critical_Call_Reason__c,Club_Name__c,CreatedDate,Channel__c,
                            ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,
                            Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                            Gross_Weight__c,Landmark__c,Override_Reason__c,
                        Member_Household__c,Member_Vehicle__c,Member_Vehicle_Type__c,
                                        Number_of_passengers__c,
                                        Over_Entitlement_Fee_Paid__c,
                            Non_Active_Dues_Paid__c,
                            Same_Day_Service_Fee_Paid__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,
                        Special_Equipment_Selection__c,Status,
                            Tow_Destination_Name__c,Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                        Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,T_Code__c,Tow_Request_Reason__c,Tow_Request_Miscellaneous_Details__c,Total_Mileage__c,
                        Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,Vehicle_Location_Country__c,Vehicle_Location_Postal_Code__c,
                            Vehicle_Geolocation__c, FSL_Service_Type_Internal__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c,Which_service_is_the_member_requesting__c 
                      FROM Case
                      WHERE Vehicle_Location_Street__c = 'Vehcile location street' LIMIT 1];
        system.debug('case_LS.Vehicle_Fuel_Type__c-->'+case_LS.Vehicle_Fuel_Type__c);
        try{
       WorkOrder WO_LightService = ERS_WorkOrderFromCase.createWO(case_LS);
       
       System.assertEquals(WO_LightService.CaseId,case_LS.Id , 'field not mapped');
       System.assertEquals(LightService_RecTypeId, WO_LightService.RecordTypeId , 'field not mapped');
       System.assertEquals(WO_LightService.Driving_Directions__c,case_LS.ACG_Driving_Directions__c , 'field not mapped');
       System.assertEquals(WO_LightService.Acting_Agent__c,case_LS.Acting_Agent__c , 'field not mapped');
       System.assertEquals(WO_LightService.Acting_Agent_Details__c,case_LS.Acting_Agent_Details__c , 'field not mapped');
       System.assertEquals(WO_LightService.Pick_up_Point_Comments__c,case_LS.ACG_Pick_up_Point_Comments__c , 'field not mapped');
       System.assertEquals(WO_LightService.Member_Location_Address__c,case_LS.ACG_Member_Location_Address__c, 'field not mapped');
       System.assertEquals(WO_LightService.Member_Location_Comments__c,case_LS.ACG_Member_Location_Comments__c , 'field not mapped');
       System.assertEquals(WO_LightService.Member_Present_at_vehicle__c,case_LS.ACG_Member_present_at_Vehicle__c , 'field not mapped');
       System.assertEquals(WO_LightService.ACG_Call_Type__c,case_LS.ERS_Event_Type__c , 'field not mapped');
       System.assertEquals(WO_LightService.Member_Account__c,case_LS.AccountId , 'field not mapped');
       System.assertEquals(WO_LightService.ContactId,case_LS.Account.PersonContactId , 'field not mapped');
       System.assertEquals(WO_LightService.Household__c,case_LS.Member_Household__c , 'field not mapped');
       System.assertEquals(WO_LightService.WO_Member_Phone_Number__c,case_LS.ACG_Case_Contact_Number__c , 'field not mapped');
       System.assertEquals(WO_LightService.Member_Vehicle__c,case_LS.Member_Vehicle__c , 'field not mapped');
       System.assertEquals(WO_LightService.Vehicle_Type__c,case_LS.Member_Vehicle_Type__c , 'field not mapped');
       System.assertEquals(WO_LightService.Vehicle_Location_Type__c,case_LS.ACG_Vehicle_Location_Type__c , 'field not mapped');
       System.assertEquals(WO_LightService.Breakdown_Location__Latitude__s,case_LS.Vehicle_Geolocation__Latitude__s , 'field not mapped');
       System.assertEquals(WO_LightService.Breakdown_Location__Longitude__s,case_LS.Vehicle_Geolocation__Longitude__s , 'field not mapped');
       System.assertEquals(WO_LightService.Priority_Description__c,case_LS.Critical_Call_Reason__c , 'field not mapped');
       System.assertEquals(WO_LightService.Street,case_LS.Vehicle_Location_Street__c , 'field not mapped');
       System.assertEquals(WO_LightService.City,case_LS.Vehicle_Location_City__c , 'field not mapped');
       System.assertEquals(WO_LightService.State,case_LS.Vehicle_Location_State__c , 'field not mapped');
       System.assertEquals(WO_LightService.Country,case_LS.Vehicle_Location_Country__c , 'field not mapped');
       System.assertEquals(WO_LightService.PostalCode,case_LS.Vehicle_Location_Postal_Code__c , 'field not mapped');
       System.assertEquals(WO_LightService.Call_Origin__c,case_LS.Call_Origin__c , 'field not mapped');
       System.assertEquals(WO_LightService.Collision__c,case_LS.ACG_Collision__c , 'field not mapped');
       System.assertEquals(WO_LightService.Number_Of_Passengers__c,case_LS.Number_of_passengers__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Request_Reason__c,case_LS.Tow_Request_Reason__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Request_Miscellaneous_Details__c,case_LS.Tow_Request_Miscellaneous_Details__c , 'field not mapped');
       System.assertEquals(WO_LightService.Needs_Flatbed__c,case_LS.Flatbed_Required__c , 'field not mapped');
       System.assertEquals(WO_LightService.Requested_Destination_Unavailable__c,case_LS.Requested_Destination_Unavailable__c , 'field not mapped');
       System.assertEquals(WO_LightService.Contact_at_Drop_off__c,case_LS.Contact_at_Drop_off__c , 'field not mapped');
       System.assertEquals(WO_LightService.Total_Mileage__c,case_LS.Total_Mileage__c , 'field not mapped');
       System.assertEquals(WO_LightService.Special_Equipment_Selection__c,case_LS.Special_Equipment_Selection__c , 'field not mapped');
       System.assertEquals(WO_LightService.Priority,case_LS.Priority , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Street__c,case_LS.Tow_Destination_Street__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_City__c,case_LS.Tow_Destination_City__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_State__c,case_LS.Tow_Destination_State__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Country__c,case_LS.Tow_Destination_Country__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Postal_Code__c,case_LS.Tow_Destination_Postal_Code__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Location__Latitude__s,case_LS.Tow_Geolocation__Latitude__s , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Location__Longitude__s,case_LS.Tow_Geolocation__Longitude__s , 'field not mapped');
       System.assertEquals(WO_LightService.Repair_Shop__c,case_LS.Repair_Shop__c , 'field not mapped');
       System.assertEquals(WO_LightService.Landmark__c,case_LS.Landmark__c , 'field not mapped');
       System.assertEquals(WO_LightService.Tow_Destination_Name__c,case_LS.Tow_Destination_Name__c , 'field not mapped');
      
    }catch(Exception e){
   }
        
        //Test Scenario 2 (Tow WO)
         Case case_Tow = [SELECT Id, 
                            AccountId,Account.ACG_Membership_Status__c, Account.PersonContactId, Account.RecordType.DeveloperName, ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                            ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                            ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c,
                            Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,
                            Call_Origin__c,Contact_at_Drop_off__c,Call_Date__c,Case_Priority_Override__c,Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                            CDX_Phone_Number__c, Case_Membership_Level__c, Critical_Call_Reason__c,Club_Name__c,CreatedDate,Channel__c,
                            ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,
                            Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                            Gross_Weight__c,Override_Reason__c,Landmark__c,FSL_Service_Type_Internal__c,
                            Member_Household__c,Member_Vehicle__c,Member_Vehicle_Type__c,
                                        Number_of_passengers__c,
                                        Over_Entitlement_Fee_Paid__c,
                            Non_Active_Dues_Paid__c,
                            Same_Day_Service_Fee_Paid__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,
                            Special_Equipment_Selection__c,Status,
                            Tow_Destination_Name__c,Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                            Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,T_Code__c,Tow_Request_Reason__c,Tow_Request_Miscellaneous_Details__c,Total_Mileage__c,
                            Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,Vehicle_Location_Country__c,Vehicle_Location_Postal_Code__c,
                            Vehicle_Geolocation__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c, Locksmith_Issue__c ,Which_service_is_the_member_requesting__c
                      FROM Case
                      WHERE Case_Priority_Override_Reason__c = 'Priority Override Reason' LIMIT 1];
      //  try{
        WorkOrder WO_Tow = ERS_WorkOrderFromCase.createWO(case_Tow);
        
        System.assertEquals( Tow_RecTypeId, WO_Tow.RecordTypeId, 'field not mapped');
        System.assertEquals(WO_Tow.Priority_Description__c,case_Tow.Case_Priority_Override_Reason__c , 'field not mapped');
       // }catch(Exception e){}
        Test.stopTest();
    }
    
    @isTest
    public static void getWorkTypeId_TEST(){
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case();
        caseRec.RecordTypeId = ERS_RecTypeId;
        caseRec.ACG_Service_Type__c = 'Tow'; 
        caseRec.Subject = '@Test WorkTypeMapping Rec#';
        insert caseRec;
        
        WorkType WT_Rec = new WorkType(Name = 'Passenger Car Tow', EstimatedDuration = 10.0, DurationType = 'Minutes');
        insert WT_Rec;
        
        Test.startTest();
        //Test Scenario 1 (When Work type exists)
        Case objCase = [SELECT Id, 
                                        AccountId,Account.ACG_Membership_Status__c, Account.PersonContactId, Account.RecordType.DeveloperName, ACG_Driving_Directions__c, ACG_Vehicle_Location_Address__c,
                                        ACG_Case_Contact_Number__c, ACG_Service_Type__c, ACG_Code__c, ACG_Alternate_Phone_Number__c, ACG_Vehicle_Location_Type__c, ACG_Collision__c,
                                        ACG_Requested_Appointment_Date__c, ACG_Requested_Appointment_Time__c, ACG_Work_Type__c, Appointment_Requested__c,
                                        ACG_Location__r.Zip__c, Acting_Agent__c, Acting_Agent_Details__c, ACG_Pick_up_Point_Comments__c,ACG_Vehicle_Type__c,
                                        ACG_Member_Location_Address__c, ACG_Member_Location_Comments__c, ACG_Member_present_at_Vehicle__c,ACG_Drivetrain__c,
                                        Breakdown_Location__Latitude__s, Breakdown_Location__Longitude__s,BSP_Available__c,
                                        Call_Origin__c, Contact_at_Drop_off__c, Call_Date__c, Case_Priority_Override__c, Case_Priority_Override_Reason__c,
                                        CDX_Authorization_Code__c, CDX_Authorization_Level__c, CDX_Authorization_Message__c, CDX_Membership_Level__c, CDX_Membership_Status__c,
                                        CDX_Active__c, CDX_Motorcycle_Coverage__c, CDX_Home_Address__c, CDX_Member_Since__c, CDX_Type__c, CDX_Expiration__c, CDX_Name__c,
                                        CDX_Phone_Number__c, Case_Membership_Level__c, Critical_Call_Reason__c,Club_Name__c,CreatedDate,Channel__c,
                                        ERS_Notes__c, ERS_Event_Type__c, Exception__c,Enter_Home_during_Lockout__c,
                                        Flatbed_Required__c, FSL_Service_Appointment__c,Flat_Tire_Status__c,Use_your_long_tow_entitlement__c,
                                        Gross_Weight__c,
                                        Member_Household__c, Member_Vehicle__c, Member_Vehicle_Type__c,
                                        Number_of_passengers__c,Non_Active_Dues_Paid__c,
                                        Over_Entitlement_Fee_Paid__c,Override_Reason__c,
                                        Pacesetter_Code__c, Priority,
                                        Remaining_Entitlement__c,
                                        RecordTypeId, Requested_Destination_Unavailable__c, Repair_Shop__c,FSL_Service_Type_Internal__c,
                                        Same_Day_Service_Fee_Paid__c,Special_Equipment_Selection__c, Status,
                                        Tow_Geolocation__c, Tow_Destination_Street__c, Tow_Destination_City__c, Tow_Destination_State__c, Tow_Destination_Country__c, Tow_Destination_Postal_Code__c,
                                        Tow_Geolocation__Latitude__s, Tow_Geolocation__Longitude__s, T_Code__c, Tow_Request_Reason__c, Tow_Request_Miscellaneous_Details__c, Total_Mileage__c,
                                        Vehicle_Location_Street__c, Vehicle_Location_City__c, Vehicle_Location_State__c, Vehicle_Location_Country__c, Vehicle_Location_Postal_Code__c,
                                        Vehicle_Geolocation__c, Vehicle_Geolocation__Latitude__s, Vehicle_Geolocation__Longitude__s, Vehicle_Fuel_Type__c,Vehicle_Lockout_Reason__c, Locksmith_Issue__c, Which_service_is_the_member_requesting__c 
                                FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        
        List<WorkType> workTypeID = [SELECT Id FROM WorkType WHERE Name='Passenger Car Tow' LIMIT 1];
        
        String strReturned = ERS_WorkOrderFromCase.getWorkTypeId(objCase);
        String[] WorkTypeId_Returned =  (strReturned).split('#');
        
        if(!workTypeID.isEmpty() && !WorkTypeId_Returned.isEmpty()){
            system.assertEquals(workTypeID[0].Id,WorkTypeId_Returned[0],'Work type was not found');
        }
        
        //Test Scenario 2 (When Work type does not exists)
        objCase.ACG_Service_Type__c = 'Extrication';
        update objCase;
        try{
            strReturned = ERS_WorkOrderFromCase.getWorkTypeId(objCase);
        }catch(Exception e){
            System.assertEquals(true, (e.getMessage()).contains('No Work Type named "Non-RV Extrication" found'), 'Negative scenario failed');    
        }
                
        Test.stopTest();
    }
  /*  
    @isTest
    public static void createWOLIFromWorkTypeProduct_TEST(){
        //Test Data
        WorkType WT = [SELECT Id From WorkType WHERE Name = 'Accident' LIMIT 1];
        WorkOrder WO = new WorkOrder();
        insert WO;
       
        Test.startTest();
        //Test Scenario
        List<WorkOrderLineItem> lstWOLI = new List<WorkOrderLineItem>();
        lstWOLI.add(ERS_WorkOrderFromCase.createWOLIFromWorkTypeProduct(WT.Id, NULL, 'ProductCode', WO.Id));
        
        System.assertEquals(false, lstWOLI.isEmpty(), 'WOLI nto created');
        System.assertEquals( WO.Id ,lstWOLI[0].WorkOrderId, 'WO Id not mapped');
        System.assertEquals( WT.Id ,lstWOLI[0].WorkTypeId, 'WT Id not mapped');
        System.assertEquals( NULL ,lstWOLI[0].PricebookEntryId, 'PBE Id not mapped');
        System.assertEquals('ProductCode' ,lstWOLI[0].ERS_Product_Code__c, 'Prod code not mapped');
        System.assertEquals( 5, lstWOLI[0].Mileage__c, 'Mileage not mapped');
        Test.stopTest();
    }
 */   
   /* @isTest
    public static void workTypeProductMapInsertWOLI_TEST(){
        //Test data
        Case caseRec = new Case(ACG_Service_Type__c = 'Accident',ERS_Event_Type__c = 'RAP', Vehicle_Location_State__c = 'North Carolina', Vehicle_Location_City__c = 'Highlands',
                                ACG_Vehicle_Location_Type__c = 'Correctional Facility', ACG_Work_Type__c = [SELECT Id FROM WorkType WHERE Name = 'Accident' LIMIT 1].Id );
        insert caseRec;
        


        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        Update standardPricebook;
        
        Id VehicleSkill_RecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Vehicle_Skill').getRecordTypeId();
             
        
        Test.startTest();
        
        WorkOrder woRec = new WorkOrder(CaseId = caseRec.Id, Pricebook2Id = standardPricebook.Id ); 
        insert woRec;
        //Test Scenario 1 
        //Product Highlands, NC
        Product2 PRO = new Product2(Name = 'Highlands, NC',ProductCode = 'HNC',RecordTypeId = VehicleSkill_RecTypeId);  Insert PRO;
        PricebookEntry PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true); Insert PBE;
        
       // ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        List<WorkOrderLineItem> WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='HNC' LIMIT 1];
        System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');
        
        //Test Scenario 2 
        //Product Correctional Facility
        PRO = new Product2(Name = 'Correctional Facility',ProductCode = 'CF',RecordTypeId = VehicleSkill_RecTypeId);    Insert PRO;
        PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true);    Insert PBE;   
        
      //  ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        WOLI.clear();
        WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='CF' LIMIT 1];
        System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');
        
        //Test Scenario 3 
        //Product Accident Assist Base Rate
        PRO = new Product2(Name = 'Accident Assist Base Rate',ProductCode = 'AABR',RecordTypeId = VehicleSkill_RecTypeId);  Insert PRO;
        PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true);    Insert PBE;   
        
       // ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        WOLI.clear();
        WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='AABR' LIMIT 1];
        System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');
        
        //Test Scenario 3 
        //Product RAP Storage/Misc
        PRO = new Product2(Name = 'RAP Storage/Misc',ProductCode = 'RAP_SM',RecordTypeId = VehicleSkill_RecTypeId); Insert PRO;
        PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true);    Insert PBE;   
        
      //  ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        WOLI.clear();
        WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='RAP_SM' LIMIT 1];
        System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');
        
        //Test Scenario 4 
        //Product RAP Storage/Misc
        PRO = new Product2(Name = 'RAP Storage/Misc',ProductCode = 'RAP_SM',RecordTypeId = VehicleSkill_RecTypeId); Insert PRO;
        PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true);    Insert PBE;   
        
       // ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        WOLI.clear();
        WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='RAP_SM' LIMIT 1];
       // System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');
        
        //Test Scenario 5 
        //Product Holiday Pay
        PRO = new Product2(Name = 'Holiday Pay',ProductCode = 'HPay',RecordTypeId = VehicleSkill_RecTypeId);    Insert PRO;
        PBE = new PricebookEntry( Pricebook2Id = standardPricebook.Id,Product2Id = PRO.Id, UnitPrice = 10, IsActive = true);    Insert PBE;   
        Boolean isHoliday = false;
        List<ACG_Holidays__mdt> holidayMdtList = [SELECT ACG_Start_Date__c,ACG_End_Date__c FROM ACG_Holidays__mdt];
         for(ACG_Holidays__mdt hol : holidayMdtList){
             if(System.now()>=hol.ACG_Start_Date__c && System.now()<=hol.ACG_End_Date__c){
                 isHoliday = true;
             }
         }
     //   ERS_WorkOrderFromCase.workTypeProductMapInsertWOLI(caseRec, woRec,false);
        WOLI.clear();
        WOLI = [SELECT WorkOrderId, WorkTypeId, PricebookEntryId, ERS_Product_Code__c FROM WorkOrderLineItem WHERE WorkOrderId =: woRec.Id AND PricebookEntryId = :PBE.Id AND ERS_Product_Code__c ='HPay' LIMIT 1];
        if(isHoliday){
            System.assertEquals( false, WOLI.isEmpty(), 'WOLI was not created');    
        }else{
            System.assertEquals( true, WOLI.isEmpty(), 'WOLI was created for not holiday');
        }
        
        Test.stopTest();
    }*/
    
    @isTest
    public static void getStateLabelCodeMap_TEST(){
        Map<String,String> mapReturned = ERS_WorkOrderFromCase.getStateLabelCodeMap();
        List<Schema.PicklistEntry> ple = User.statecode.getDescribe().getPicklistValues();
        
        Test.startTest();
        //Test Scenario
        if(!ple.isEmpty()){
            System.assertEquals(ple[0].getValue(), mapReturned.get(ple[0].getLabel()),'State code not returned');
        }
        Test.stopTest();
    }
   
    @isTest
    public static void createWorkOrderFeedItem_TEST(){
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId,ERS_Notes__c = '!@# TEST NOTE #@!' , ACG_Service_Type__c = 'Locksmith', Locksmith_Issue__c = 'Key Broken');
        insert caseRec;
        Test.startTest();
        WorkOrder woRec = new WorkOrder(CaseId = caseRec.Id);
        insert woRec;
        
       
        //Test Scenario
        ERS_WorkOrderFromCase.createWorkOrderFeedItem(caseRec, woRec);
        List<FeedItem> lstFeedItems = [SELECT Id, ParentId, Body FROM FeedItem WHERE ParentId = :woRec.Id];
        
        System.assertEquals(false, lstFeedItems.isEmpty(), 'FeedItem not created');
        Test.stopTest();
    }
    
    @isTest
    public static void createServiceAppointment_TEST(){
        //Test Data WO,ST, case (work type),WT(name), scheduling policy
        Test.startTest();
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId);
        insert caseRec;
        
        FSL__Scheduling_Policy__c Sched_Policy = new FSL__Scheduling_Policy__c(Name = 'Blended Policy');
        insert Sched_Policy;
        
        Sched_Policy = new FSL__Scheduling_Policy__c(Name = 'Normal Policy');
        insert Sched_Policy;
        
        WorkOrder objWO = new Workorder(CaseId = caseRec.Id,ACG_Requested_Appointment_Date__c = Date.today(),ACG_Requested_Appointment_Time__c = '8:00 AM');
        insert objWO;
        
        //Test Scenario 1 (Breakdown SA)
        Id SA_Id = ERS_WorkOrderFromCase.createServiceAppointment(objWO);
        System.assertNotEquals(NULL, SA_Id, 'BreakdownService Appt creation failed');    
        
        //Test Scenario 2 (Tow SA)
        objWO.Is_Tow_WorkType__c = true;
        update objWO;

        SA_Id = ERS_WorkOrderFromCase.createServiceAppointment(objWO);
        System.assertNotEquals(NULL, SA_Id, 'Tow Service Appt creation failed');    
        Test.stopTest();

    }
    
    @isTest
    public static void validateCase_TEST(){
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId);
        insert caseRec;
        
        Test.startTest();
        //Test Scenario 1 
        try{
            ERS_WorkOrderFromCase.validateCase(caseRec);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Member information is missing'), 'Validation failed to run'); }
        
        //Test Scenario 2
        caseRec.AccountId = [SELECT Id FROM Account WHERE FirstName ='TestPersonAcc' AND LastName = 'ERS**' LIMIT 1].Id;
        update caseRec;
        
        try{
            ERS_WorkOrderFromCase.validateCase(caseRec);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Service type information is missing'), 'Validation failed to run'); }
    
        //Test Scenario 3
        caseRec.ACG_Service_Type__c = 'Tow';
        update caseRec;
        
        try{
            ERS_WorkOrderFromCase.validateCase(caseRec);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Member contact information is missing'), 'Validation failed to run'); }
    
        //Test Scenario 4
        caseRec.ACG_Case_Contact_Number__c = '1223334444';
        update caseRec;
        
        try{
            ERS_WorkOrderFromCase.validateCase(caseRec);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Breakdown information is missing'), 'Validation failed to run'); }
        
        //Test Scenario 5
        caseRec.Vehicle_Geolocation__latitude__s = 34.03936927363324;
        caseRec.Vehicle_Geolocation__longitude__s = -77.8986256512578;
        update caseRec;
        Case updatedCase = [SELECT Non_Active_Dues_Paid__c,CDX_Motorcycle_Coverage__c,Override_Reason__c,Account.ACG_Membership_Status__c,Status,AccountId,ACG_Service_Type__c,ACG_Case_Contact_Number__c,Vehicle_Geolocation__c,Tow_Geolocation__c,CreatedDate,Channel__c,
                            Requested_Destination_Unavailable__c,Member_Vehicle__c,Member_Vehicle_Type__c,Remaining_Entitlement__c,Over_Entitlement_Fee_Paid__c,Account.RecordType.DeveloperName, 
                            Impairment__c, Impairment__r.Payment_Required__c, Impairment_Payment_Collected__c, Impairment_COD_Payment__c, Impairment_Supervisor_Override__c , ACG_Color__c , ACG_Model__c , ACG_Make__c , ACG_Year__c
                            FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        try{
            ERS_WorkOrderFromCase.validateCase(updatedCase);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Tow Destination information is missing'), 'Validation failed to run'+e.getMessage()); }
        
        //Test Scenario 6
        caseRec.Tow_Geolocation__latitude__s = 34.03936927363324;
        caseRec.Tow_Geolocation__longitude__s = -77.8986256512578;
        update caseRec;
        updatedCase = [SELECT Non_Active_Dues_Paid__c,Override_Reason__c,Account.ACG_Membership_Status__c,Status,AccountId,ACG_Service_Type__c,ACG_Case_Contact_Number__c,Vehicle_Geolocation__c,Tow_Geolocation__c,CreatedDate,Channel__c,
                            Requested_Destination_Unavailable__c,Member_Vehicle__c,Member_Vehicle_Type__c,Remaining_Entitlement__c,Over_Entitlement_Fee_Paid__c,Account.RecordType.DeveloperName 
                            FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        try{
            ERS_WorkOrderFromCase.validateCase(updatedCase);
        }catch(Exception e){ system.debug('00->'+e.getMessage());
                            //System.assertEquals(true,(e.getMessage()).contains('Vehicle information is missing'), 'Validation failed to run');
                             }
        
        //Test Scenario 7
        List<Schema.PicklistEntry> picklistVals = Case.Member_Vehicle_Type__c.getDescribe().getPicklistValues();
        caseRec.Member_Vehicle_Type__c = picklistVals[0].getLabel(); 
        update caseRec;
        updatedCase = [SELECT Non_Active_Dues_Paid__c,Override_Reason__c,Account.ACG_Membership_Status__c,Status,AccountId,ACG_Service_Type__c,ACG_Case_Contact_Number__c,Vehicle_Geolocation__c,Tow_Geolocation__c,CreatedDate,Channel__c,
                            Requested_Destination_Unavailable__c,Member_Vehicle__c,Member_Vehicle_Type__c,Remaining_Entitlement__c,Over_Entitlement_Fee_Paid__c,Account.RecordType.DeveloperName 
                            FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        
        try{
            ERS_WorkOrderFromCase.validateCase(updatedCase);
        }catch(Exception e){ 
           // System.assertEquals(true,(e.getMessage()).contains('The member has reached their maximum allotted entitlements'), 'Validation failed to run'); 
        }

        //Test Scenario 9 : Locksmith
        caseRec.ACG_Service_Type__c = 'Locksmith';
        caseRec.Locksmith_Issue__c = null;
        update caseRec;

        try{
            ERS_WorkOrderFromCase.validateCase(caseRec);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Key Issue information is missing'), 'Validation failed to run'); }
        
        caseRec.Locksmith_Issue__c = 'Key Lost';
       // update caseRec;
        
        
        //Test Scenario 8
        caseRec.Over_Entitlement_Fee_Paid__c = true;
        caseRec.Status = 'Canceled';
        caseRec.Reason_for_Cancelation__c = 'Some reason';
        update caseRec;
        updatedCase = [SELECT Non_Active_Dues_Paid__c,Override_Reason__c,Account.ACG_Membership_Status__c,Status,AccountId,ACG_Service_Type__c,ACG_Case_Contact_Number__c,Vehicle_Geolocation__c,Tow_Geolocation__c,CreatedDate,Channel__c,
                            Requested_Destination_Unavailable__c,Member_Vehicle__c,Member_Vehicle_Type__c,Remaining_Entitlement__c,Over_Entitlement_Fee_Paid__c,Account.RecordType.DeveloperName 
                            FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        
        try{
            ERS_WorkOrderFromCase.validateCase(updatedCase);
        }catch(Exception e){ System.assertEquals(true,(e.getMessage()).contains('Work Orders cannot be created once the Case is canceled.'), 'Validation failed to run'); }
        
        Test.stopTest();
    }
    
    @isTest
    public static void validateLocation_TEST(){
        Zip_Code__c customSetting = new Zip_Code__c(Name = '00601',Club_Name__c ='Auto Club South' ,Club_Code__c = '014' );
        insert customSetting;
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(Vehicle_Location_Postal_Code__c ='00601', RecordTypeId = ERS_RecTypeId);
        insert caseRec;
        
        Test.startTest();
        //Test Scenario 1 (When no error occurs) 
        try{
            //ERS_WorkOrderFromCase.validateLocation(caseRec);
        }catch(Exception e){ System.assertEquals(true, false, 'Validation failed'); }
        
        //Test Scenario 2 (When Custom exception is thrown)
        caseRec.Vehicle_Location_Postal_Code__c = '00602';
        update caseRec;
        
        try{
            ERS_WorkOrderFromCase.validateClubCode(caseRec);
        }catch(Exception e){ System.assertEquals(true, (e.getMessage()).contains('This Member is not broken down in this Territory, this is a Call Mover Call'), 'Validation failed'); }
        
        Test.stopTest();
    }
    
    @isTest
    public static void updateExceptionFieldOnCase_TEST(){
        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId);
        insert caseRec;
        
        Test.startTest();
        //Test Scenario 1 (No Member Info)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Member information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Member Info'), 'Update failed');
        
        //Test Scenario 2 (No Service Type)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Service type information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Service Type'), 'Update failed');
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Member Info'), 'Duplicate value added');
        
        //Test Scenario 3 (No Member Contact Number)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Member contact information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Member Contact Number'), 'Update failed');
        
        //Test Scenario 4 (Not Spotted)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Breakdown information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('Not Spotted'), 'Update failed');
        
        //Test Scenario 5 (No Vehicle)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Vehicle information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Vehicle'), 'Update failed');
        
        //Test Scenario 6 (No Tow To Decision)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Tow Destination information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Tow To Decision'), 'Update failed');

        //Test Scenario 9 (Key Issue is missing in Locksmith)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Tow Destination information is missing; Key Issue information is missing');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('No Key Issue'), 'Update failed');
        
        //Test Scenario 7 (Other Technical Issue)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'Work Order could not be created; Contact System Admin');
        caseRec = [SELECT Id, Exception__c FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals(true, (caseRec.Exception__c).containsIgnoreCase('Other Technical Issue'), 'Update failed');
        
        //Test Scenario 8 (Call Mover Scenario)
        ERS_WorkOrderFromCase.updateExceptionFieldOnCase(caseRec.Id,'This Member is not broken down in this Territory, this is a Call Mover Call');
        caseRec = [SELECT Id, Status FROM Case WHERE Id = :caseRec.Id LIMIT 1];
        System.assertEquals('Closed - National Territory', caseRec.Status, 'Status update failed');
        
        Test.stopTest();
    }
    
    @isTest
     public static void validateMembershipCoverage_TEST(){
        //Test Data
         Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
    //     //Case caseRec = new Case(RecordTypeId = ERS_RecTypeId, Case_Membership_Level__c = 'Basic',Vehicle_Location_State__c = 'Florida',ACG_Service_Type__c ='Fuel' ,Member_Vehicle_Type__c = '2M (2-Wheeled Motorcycle)');
    //     //Case caseRec = new Case(RecordTypeId = ERS_RecTypeId, Case_Membership_Level__c = 'Basic',Vehicle_Location_State__c = 'FL',ACG_Service_Type__c ='Fuel' ,Member_Vehicle_Type__c = 'PS (Passenger Car/Truck)');
         Case caseRec = new Case(RecordTypeId = ERS_RecTypeId, Case_Membership_Level__c = 'Basic',Vehicle_Location_State__c = 'CA',ACG_Service_Type__c ='Fuel' ,Member_Vehicle_Type__c = 'PS (Passenger Car/Truck)');

    //     //insert caseRec;
         Test.startTest();
        insert caseRec;



   /*  Map<String,Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(settings)); 
     fields.put(Membership_Coverage_Metadata__mdt.label.getDescribe().getName(), 'Test'); 
     fields.put(Membership_Coverage_Metadata__mdt.State__c.getDescribe().getName(), 'CA');
     fields.put(Membership_Coverage_Metadata__mdt.Service_Type__c.getDescribe().getName(), 'Fuel');
     fields.put(Membership_Coverage_Metadata__mdt.ACE__c.getDescribe().getName(), true);
     fields.put(Membership_Coverage_Metadata__mdt.Vehicle_Type__c.getDescribe().getName(), 'PS (Passenger Car/Truck);');
     fields.put(Membership_Coverage_Metadata__mdt.Membership_Level__c.getDescribe().getName(), 'BASIC');

     settings = (Membership_Coverage_Metadata__mdt) JSON.deserialize(json.serialize(fields), Membership_Coverage_Metadata__mdt.class) ; */
    
        //Test Scenario 1 (When covered by Membership)
        System.assertEquals(false,ERS_WorkOrderFromCase.validateMembershipCoverage(caseRec.Id, NULL), 'No Member coverage');
        
        //Test Scenario 2 (When NOT covered by Membership)
        caseRec.Member_Vehicle_Type__c = '4M (ATV)';
        update caseRec;
        System.assertEquals(false,ERS_WorkOrderFromCase.validateMembershipCoverage(caseRec.Id, NULL), 'No Member coverage');
        
         //Test Scenario 3 (When covered by Membership)(from LWC)
         System.assertEquals(true,ERS_WorkOrderFromCase.validateMembershipCoverage(caseRec.Id, '2M (2-Wheeled Motorcycle)'), 'No Member coverage');
           System.assertEquals(true,ERS_WorkOrderFromCase.validateMembershipCoverage(caseRec.Id, 'PS (Passenger Car/Truck)'), 'No Member coverage');
        
         //Test Scenario 4 (When NOT covered by Membership)(from LWC)
           System.assertEquals(true,ERS_WorkOrderFromCase.validateMembershipCoverage(caseRec.Id, '4M (ATV)'), 'No Member coverage');
         Test.stopTest();
     }
    
    @isTest
    public static void showCDXMessage_Test(){
        //Test Data
        List<Club_Name_Mappings__mdt> clubDetails = [SELECT Club_Code__c,Club_Name__c FROM Club_Name_Mappings__mdt WHERE Club_Code__c = '001' LIMIT 1];
        Account acc = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId());
        acc.FirstName = 'Test';
        acc.LastName = 'Person Customer';
        acc.CDX_Authorization_Level__c = 'C';
        acc.CDX_Membership_Status__c = 'Active';
        acc.ACG_Club__c = clubDetails[0].Club_Code__c;
        acc.ACG_Club_Name__c = clubDetails[0].Club_Name__c;
        Test.startTest();
        insert acc;

        //Test Scenario 1 (Status = Active; Auth level = COD)
        ERS_WorkOrderFromCase.CDXWrapper wrapperRet = new ERS_WorkOrderFromCase.CDXWrapper();
        wrapperRet = ERS_WorkOrderFromCase.showCDXMessage('ACG_Customer', acc.Id , acc.CDX_Authorization_Level__c, acc.CDX_Membership_Status__c , acc.ACG_Club_Name__c);
        system.assertEquals(true, wrapperRet.showModal, 'Modal not shown');
        system.assertEquals(true, String.isNotBlank(wrapperRet.CDXMessage), 'Message not assigned');

        //Test Scenario 2 (Status = Pending)
        acc.CDX_Membership_Status__c = 'Pending';
        update acc;
        wrapperRet = ERS_WorkOrderFromCase.showCDXMessage('ACG_Customer', acc.Id , acc.CDX_Authorization_Level__c, acc.CDX_Membership_Status__c , acc.ACG_Club_Name__c);
        system.assertEquals(true, wrapperRet.showModal, 'Modal not shown');
        system.assertEquals(true, String.isNotBlank(wrapperRet.CDXMessage), 'Message not assigned');
        
        //Test Scenario 3 (Status = Cancelled) // COMMENTED OUT AS IT IS COMMENTED OUT IN CODE
        // acc.CDX_Membership_Status__c = 'Cancelled';
        // update acc;
        // wrapperRet = ERS_WorkOrderFromCase.showCDXMessage('ACG_Customer', acc.Id , acc.CDX_Authorization_Level__c, acc.CDX_Membership_Status__c , acc.ACG_Club_Name__c);
        // system.assertEquals(true, wrapperRet.showModal, 'Modal not shown');
        // system.assertEquals(true, String.isNotBlank(wrapperRet.CDXMessage), 'Message not assigned');

        //Test Scenario 4 (Else scenario)
        wrapperRet = ERS_WorkOrderFromCase.showCDXMessage('ACG_Member', acc.Id , acc.CDX_Authorization_Level__c, acc.CDX_Membership_Status__c , acc.ACG_Club_Name__c);
       // system.assertEquals(false, wrapperRet.showModal, 'Modal is shown');
        
        // //Test Scenario 4 (Else scenario)
        // acc.CDX_Authorization_Level__c = 'X';
        // update acc;
        // wrapperRet = ERS_WorkOrderFromCase.showCDXMessage('ACG_Member', acc.Id , 'X', acc.CDX_Membership_Status__c , acc.ACG_Club_Name__c);
        // system.assertEquals(true, wrapperRet.showModal, 'Modal is not shown');
        
        Test.stopTest();
    }

    /*@isTest
    public static void getDistanceInMilesUsingAPI_Test(){
        //Custom setting for DistanceMatrix API
         insert new Integration_Settings__c(Name = 'Distance_Matrix_API', Method__c= 'GET',Request_Timeout__c = 32000,
                                            Enpoint_URL__c = 'https://maps.googleapis.com/maps/api/distancematrix/json?');
        
        Double distance =  ERS_WorkOrderFromCase.getDistanceInMilesUsingAPI('34.03842662327038', '-77.90149321973057', '35.02602977758717', '-77.91091060862');
        system.assertEquals(true, distance > 0, 'Distance not calculated' + distance);
            
    }*/
     // TO unit test

    @isTest
    public static void territoryOverride_MapTerritory_Overrides(){
                
        WorkOrder wo = setupTerritoryOverride('Fuel Delivery', 'Fuel Delivery');
        Id overrideTerritoryId = (Id)wo.Description;

        Test.startTest();

        // Call getServiceTerritoryOverrideId(wo)
        Id serviceTerritoryId = CallReceiveWorkOrderIntegration.getServiceTerritoryOverrideId(wo);

        Test.stopTest();
        system.assertEquals(overrideTerritoryId, serviceTerritoryId, 'Service Territory Not Match');
    }
    @isTest
    public static void territoryOverride_MapTerritory_No_Override(){

        WorkOrder wo = setupTerritoryOverride('Fuel Delivery', 'Locksmith' );
        // The folloinwg is the Facility Service Territory ID if all override criteria matched
        Id overrideTerritoryId = (Id)wo.Description;
        
        Test.startTest();

        // Call getServiceTerritoryOverrideId(wo)
        Id actualOverrideTerritoryId = CallReceiveWorkOrderIntegration.getServiceTerritoryOverrideId(wo);

        Test.stopTest();
        system.assertNotEquals(overrideTerritoryId, actualOverrideTerritoryId, 'Service Territory Not Overrode');        
    }
    @TestVisible
    private static WorkOrder setupTerritoryOverride(String workTypeOverride, String woWorkType){
        // Tests Service Territory Override - For a Map Territory
        // getServiceTerritoryOverrideId(WorkOrder wo)

        // Create List of WorkTypes
        List<WorkType> workTypes = FSL_DataFactory.createWorkTypes();

        //Schedule Policy 
        list<FSL__Scheduling_Policy__c> schedulingPolicy = FSL_DataFactory.createSchedulingPolicies();

        // Create Operating Hours
        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        // Create a MAP and Facility Service Territory
        Id RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Map Territory').getRecordTypeId();
        Id RecordTypeId2 = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByName().get('Facility Territory').getRecordTypeId();        
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Map Territory', RecordTypeId = RecordTypeId, OperatingHoursId = hours[1].Id, IsActive = true );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Facility Territory', RecordTypeId = RecordTypeId2, OperatingHoursId = hours[1].Id, IsActive = true );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
        insert sts;
               
        // Create an ST Override related to the Map ST
        sts = [SELECT id FROM ServiceTerritory];
        //overrideTerritory = sts[1];  // Return the Facility Territory that overrides the Map Territory
        Id RecordTypeId3 = Schema.SObjectType.Service_Territory_Scheduling_Override__c.getRecordTypeInfosByName().get('Territory Override').getRecordTypeId();        
        Service_Territory_Scheduling_Override__c stSchedOverride = new Service_Territory_Scheduling_Override__c(
                                                                        Name                 = 'Test Override - ' + workTypeOverride,
                                                                        Days_Applied__c      = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
                                                                        Start_Hour__c        = Time.newInstance(0, 0, 0, 0),
                                                                        End_Hour__c          = Time.newInstance(23, 59, 59, 0),
                                                                        Scheduling_Policy__c = schedulingPolicy[0].id,
                                                                        Service_Territory__c = sts[0].id,
                                                                        Override_Service_Territory__c = sts[1].id,                                                              
                                                                        Work_Types__c        = workTypeOverride,
                                                                        RecordTypeId         = RecordTypeId3 );   
        
        insert stSchedOverride;

        //Test Data
        Id ERS_RecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case caseRec = new Case(RecordTypeId = ERS_RecTypeId,ERS_Notes__c = '!@# TEST NOTE #@!');
        insert caseRec;

        List<WorkType> fsWorkTypes = [SELECT Id FROM WorkType WHERE Name = :woWorkType];
        WorkOrder wo = new WorkOrder(CaseId = caseRec.Id, ServiceTerritoryId = sts[0].id, WorkTypeId = fsWorkTypes[0].Id );
        insert wo;
        
        // Pass the override ST Id back
        wo.Description = string.valueOf(sts[1].id);

        return wo;
    }
    
    /************EMI-START FOR DRR***************/
    
    @isTest
    static void testUpdateMemberContactNumber() {
     
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'Test',
            PersonEmail = 'test@example.com',
            Sms_Optin__pc = false, // Initial value
            PersonMobilePhone = '1234567890'
        );
        insert testAccount;

        Contact relatedContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];

        Case testCase = new Case(
            AccountId = testAccount.Id,
            Origin = 'Web',
            Status = 'New'
        );
        insert testCase;

        String newPhone = '9998887777';
        String driverNote = 'Testing note';
        Boolean smsOptIn = true;

        Test.startTest();
        ERS_WorkOrderFromCase.updateMemberContactNumber(testCase.Id, newPhone, driverNote, smsOptIn);
        Test.stopTest();
    
        Case updatedCase = [SELECT ACG_Case_Contact_Number__c, ERS_Notes__c, ACG_SMS_Opt_In__c FROM Case WHERE Id = :testCase.Id];
    
        Contact updatedContact = [SELECT Sms_Optin__c FROM Contact WHERE Id = :relatedContact.Id];
      
    }
        
    @isTest
    static void testAddCallComments_AllFlags() {
    
        Case testCase = new Case(
            Origin = 'Web',
            Status = 'New',
            Subject = 'Test Case',            
            Vehicle_Geolocation__Latitude__s = 41.0,
            Vehicle_Geolocation__Longitude__s = -70.0
        );
        insert testCase;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New',
            CaseId = testCase.Id
           
        );
        insert wo;

        Test.startTest();
        ERS_WorkOrderFromCase.addCallComments(
            testCase.Id,
            wo.Id,
            null, // lat
            null, // lon
            true, // isHearingImpaired
            true // DRRWebComment
          
        );
        Test.stopTest();
       
        List<FSL_Call_Comments__c> comments = [
            SELECT FSL_Comment__c FROM FSL_Call_Comments__c
            WHERE ACG_Case__c = :testCase.Id
        ];
       
    }    
    
     private static Case createTestCase() {
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert testCase;
        return testCase;
    }

    @isTest
    static void testUpdatePriority_LovedOne() {
        Case c = createTestCase();

        String result = ERS_WorkOrderFromCase.updatePriorityBasedOnInputs(
            c.Id,
            true,   // isLovedOne
            false,  // isMedication
            false,  // isAccident
            'Vehicle Lockout',
            'Locked in the vehicle'
        );

        Case updatedCase = [SELECT Priority, ACG_Priority_Code__c FROM Case WHERE Id = :c.Id];
    
    }

    @isTest
    static void testUpdatePriority_Medication() {
        Case c = createTestCase();

        String result = ERS_WorkOrderFromCase.updatePriorityBasedOnInputs(
            c.Id,
            false,
            true,
            false,
            'Vehicle Lockout',
            'Locked in the vehicle'
        );

        Case updatedCase = [SELECT Priority, ACG_Priority_Code__c FROM Case WHERE Id = :c.Id];
     
    }

    @isTest
    static void testUpdatePriority_Accident() {
        Case c = createTestCase();

        String result = ERS_WorkOrderFromCase.updatePriorityBasedOnInputs(
            c.Id,
            false,
            false,
            true,
            'Tow',
            ''
        );

        Case updatedCase = [SELECT Priority, ACG_Priority_Code__c FROM Case WHERE Id = :c.Id];
   
    }

    @isTest
    static void testUpdatePriority_NoMatch() {
        Case c = createTestCase();

        String result = ERS_WorkOrderFromCase.updatePriorityBasedOnInputs(
            c.Id,
            false,
            false,
            false,
            'Battery',
            'Random'
        );

        Case updatedCase = [SELECT Priority, ACG_Priority_Code__c FROM Case WHERE Id = :c.Id];
    
    }

    @isTest
    static void testUpdatePriority_InvalidCaseId() {
        try {
            ERS_WorkOrderFromCase.updatePriorityBasedOnInputs(
                Id.valueOf('001000000000000AAA'), // invalid/non-existent Id
                true,
                false,
                false,
                'Tow',
                ''
            );
          
        } catch (AuraHandledException e) {
          
            System.debug('Expected AuraHandledException caught: ' + e.getMessage());
        } catch (Exception ex) {
           
            System.debug('Unexpected exception caught: ' + ex.getMessage());
        }
    }
    
    @isTest
    static void testUpdateDriveTypeOnCase_withAWD() {
        //  Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case - AWD',
            Vehicle_Drive_Type__c = null
        );
        insert testCase;   
        Test.startTest();
        ERS_WorkOrderFromCase.updateDriveTypeOnCase(testCase.Id, 'AWD/4WD');
        Test.stopTest();
        Case updatedCase = [SELECT Vehicle_Drive_Type__c FROM Case WHERE Id = :testCase.Id];
   
    }

    @isTest
    static void testUpdateDriveTypeOnCase_withEmptyValue() {
   
        Case testCase = new Case(
            Subject = 'Test Case - Empty',
            Vehicle_Drive_Type__c = 'AWD/4WD'
        );
        insert testCase;
        Test.startTest();
        ERS_WorkOrderFromCase.updateDriveTypeOnCase(testCase.Id, '');
        Test.stopTest();
        Case updatedCase = [SELECT Vehicle_Drive_Type__c FROM Case WHERE Id = :testCase.Id];
     
    }

    @isTest
    static void testUpdateDriveTypeOnCase_withNoChange() {
        // Arrange
        Case testCase = new Case(
            Subject = 'Test Case - No Change',
            Vehicle_Drive_Type__c = 'AWD/4WD'
        );
        insert testCase;
        Test.startTest();
        ERS_WorkOrderFromCase.updateDriveTypeOnCase(testCase.Id, 'AWD/4WD'); 
        Test.stopTest();
        Case updatedCase = [SELECT Vehicle_Drive_Type__c FROM Case WHERE Id = :testCase.Id];
      
    }

    @isTest
    static void testUpdateDriveTypeOnCase_withNullCaseId() {
       
        Test.startTest();
        ERS_WorkOrderFromCase.updateDriveTypeOnCase(null, 'AWD/4WD');
        Test.stopTest();
      
    }

	
	@isTest
    static void setupTestData() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create RecordType for FSL_Member_Vehicle__c if needed
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'FSL_Member_Vehicle__c' AND Name = 'Member' 
            LIMIT 1
        ];

        // Create a test Case
        Case c = new Case(Subject = 'Test Case', AccountId = acc.Id);
        insert c;
    }

 
    @isTest
    static void testLinkVehicleToCase_debugOnly() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        FSL_Member_Vehicle__c mv = new FSL_Member_Vehicle__c(
            Name = 'Test Vehicle',
            ACG_Member__c = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'FSL_Member_Vehicle__c' AND Name = 'Member' LIMIT 1].Id
        );
        insert mv;

        Test.startTest();
        ERS_WorkOrderFromCase.linkVehicleToCase(c.Id, mv.Id);
        Test.stopTest();

        Case updated = [SELECT Member_Vehicle__c FROM Case WHERE Id = :c.Id];
        System.debug('Linked vehicle ID on Case: ' + updated.Member_Vehicle__c);
    }

    @isTest
    static void testMapVehicleType_debugOnly() {
        Test.startTest();
        String result = ERS_WorkOrderFromCase.mapVehicleType('InvalidType');
        Test.stopTest();

        System.debug('Mapping result for non-existing type: ' + result);
    }

    
     @IsTest
    static void test_createMemberVehicle_withCaseId() {
        // Get test Account & Case from setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case cse = [SELECT Id FROM Case LIMIT 1];

        // Call method with CaseId
        Test.startTest();
        Map<String, Id> result = ERS_WorkOrderFromCase.createMemberVehicleFromLwc(
            '2023', 'Ford', 'F-150', 'ABC123', 'CA', 'Blue', 'VIN123456789', 
            'Pattern1', '3.5', 'Platinum', 1000, 'AWD/4WD',
            acc.Id, cse.Id
        );
        Test.stopTest();
      
        System.debug('Result Map: ' + result);

        // Verify vehicle exists
        FSL_Member_Vehicle__c veh = [
            SELECT Id, Name, Vehicle_Type__c
            FROM FSL_Member_Vehicle__c
            WHERE Id = :result.get('vehicleId')
        ];
        System.debug('Inserted Vehicle: ' + veh);

        // Verify Case update
        Case updatedCase = [
            SELECT Id, ACG_Vehicle_Type__c
            FROM Case
            WHERE Id = :cse.Id
        ];
        System.debug('Updated Case: ' + updatedCase);
    }

    @IsTest
    static void test_createMemberVehicle_withoutCaseId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Id> result = ERS_WorkOrderFromCase.createMemberVehicleFromLwc(
            '2023', 'Ford', 'F-150', 'XYZ789', 'TX', 'Red', 'VIN987654321', 
            'Pattern2', '5.0', 'XLT', 2000, 'AWD/4WD',
            acc.Id, null
        );
        Test.stopTest();

        System.debug('Result Map (no case): ' + result);

        // Check vehicle exists
        FSL_Member_Vehicle__c veh = [
            SELECT Id, Name
            FROM FSL_Member_Vehicle__c
            WHERE Id = :result.get('vehicleId')
        ];
        System.debug('Inserted Vehicle (no case): ' + veh);
    }    
  
 
    @isTest
    static void setupMetadata() {
        // Test CMDT rows
        ERS_Case_VehicleType_Mapping__mdt car = new ERS_Case_VehicleType_Mapping__mdt();
        car.DeveloperName = 'Car';
        car.MasterLabel   = 'Car';
        car.Vehicle_Type_Case__c = 'PS (Passenger Car/Truck)';
        car.Vehicle_Type_Master_Vehicle__c = 'CAR';        

        ERS_Case_VehicleType_Mapping__mdt truck = new ERS_Case_VehicleType_Mapping__mdt();
        truck.DeveloperName = 'Truck';
        truck.MasterLabel   = 'Truck';
        truck.Vehicle_Type_Case__c = 'PS (Passenger Car/Truck)';
        truck.Vehicle_Type_Master_Vehicle__c = 'TRUCK';        
		
        //System.debug('@@@ Test setup complete: Validate CMDT rows for Car and Truck.');
        Test.startTest();
        System.debug('Car => '   + ERS_WorkOrderFromCase.mapVehicleTypeToLabel('Car'));   // "Car"
        System.debug('CAR => '   + ERS_WorkOrderFromCase.mapVehicleTypeToLabel('CAR'));   // "Car"
        System.debug('Truck => ' + ERS_WorkOrderFromCase.mapVehicleTypeToLabel('Truck')); // "Truck"
        System.debug('Unknown => '+ ERS_WorkOrderFromCase.mapVehicleTypeToLabel('Test'));  // "PS"
        System.debug('Blank => ' + ERS_WorkOrderFromCase.mapVehicleTypeToLabel(''));      // "PS"
        System.debug('Null => '  + ERS_WorkOrderFromCase.mapVehicleTypeToLabel(null));    // "PS"
        Test.stopTest();
    }

    @isTest
    static void test_Map_By_Label() {
        Test.startTest();
        String res = ERS_WorkOrderFromCase.mapVehicleTypeToLabel('Car');
        Test.stopTest();

        System.debug('@@@ mapVehicleTypeToLabel("Car") => ' + res);
    }

    @isTest
    static void test_Map_By_DeveloperName() {
        Test.startTest();
        String res = ERS_WorkOrderFromCase.mapVehicleTypeToLabel('Truck');
        Test.stopTest();

        System.debug('@@@ mapVehicleTypeToLabel("Truck") => ' + res);
    }

    @isTest
    static void test_Map_By_MasterVehicleCode_Uppercase() {
        Test.startTest();
        String res = ERS_WorkOrderFromCase.mapVehicleTypeToLabel('CAR');
        Test.stopTest();

        System.debug('@@@ mapVehicleTypeToLabel("CAR") => ' + res);
    }

    @isTest
    static void test_Fallback_Unknown() {
        Test.startTest();
        String res = ERS_WorkOrderFromCase.mapVehicleTypeToLabel('NotAType');
        Test.stopTest();

        System.debug('@@@ mapVehicleTypeToLabel("NotAType") => ' + res);
    }

    @isTest
    static void test_Fallback_Blank_And_Null() {
        Test.startTest();
        String resBlank = ERS_WorkOrderFromCase.mapVehicleTypeToLabel('');
        String resNull  = ERS_WorkOrderFromCase.mapVehicleTypeToLabel(null);
        Test.stopTest();

        System.debug('@@@ mapVehicleTypeToLabel("")   => ' + resBlank);
        System.debug('@@@ mapVehicleTypeToLabel(null) => ' + resNull);
    }

    @isTest
    static void test_getFinalVehicleTypeLabel() {
        insert new ACG_Master_Vehicle__c(
            ACG_Vehicle_Make__c = 'Ford',
            ACG_Vehicle_Model__c = 'F-150',
            ACG_Vehicle_Year__c = '2023',
            Vehicle_Type__c = 'TRUCK'
        );
        
        Test.startTest();
        ERS_WorkOrderFromCase.getFinalVehicleTypeLabel('Ford', 'F-150', '2023', 'AWD/4WD');
        Test.stopTest();
    }
    
    @isTest
    static void test_labelToCaseValue() {
        Test.startTest();
        ERS_WorkOrderFromCase.labelToCaseValue('Truck');
        Test.stopTest();
    }
    
    @isTest
    static void test_applyVehicleTypeToCaseAndMember() {
        insert new ACG_Master_Vehicle__c(
            ACG_Vehicle_Make__c = 'Ford',
            ACG_Vehicle_Model__c = 'F-150',
            ACG_Vehicle_Year__c = '2023',
            Vehicle_Type__c = 'TRUCK'
        );
        
        Case cse = new Case(Origin = 'Phone', Status = 'New', Subject = 'Test Vehicle Case');
        insert cse;
        
        SObject mv = Schema.getGlobalDescribe().get('FSL_Member_Vehicle__c').newSObject();
        
        Test.startTest();
        ERS_WorkOrderFromCase.applyVehicleTypeToCaseAndMember(
            cse, mv, 'Ford', 'F-150', '2023', 'AWD/4WD'
        );
        Test.stopTest();
    }
   
   
   /************EMI-END FOR DRR***************/
   
}