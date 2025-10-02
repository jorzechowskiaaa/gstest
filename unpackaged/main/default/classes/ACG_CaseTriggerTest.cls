/*
* @description: Test class for ACG_CaseTrigger
* @date: August 16, 2021
* author: Deloitte USI
*/

@isTest
public class ACG_CaseTriggerTest {

    @testSetup
    public static void testSetup(){  
        Id facilityRecordTypeId  = EP.getRecordTypeId(Account.SObjectType, 'Facility');
        ACG_Skip_Automations__c objSkipAutomations = ACG_Skip_Automations__c.getInstance(System.UserInfo.getProfileId());
        objSkipAutomations.ACG_Skip_Trigger__c = false;
        upsert objSkipAutomations;

        /* Test data for updateStatusTest()*/
        Id ERSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.ACG_ERS_CASE_RECORD_TYPE).getRecordTypeId();
        
        /* Test data for populateHouseholdTest()*/
        Id memberRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
        List<Account> members = new List<Account>();    
        Account Member1 = new Account(FirstName='@Member1', LastName='@' ,RecordTypeId = memberRecordtypeId,ACG_Primary_Phone_Type__c = 'Home',ACG_Is_Primary_Member_in_Household__c=true,Proxy_UI__c = 'test001');
        members.add(Member1);
        Account Member2 = new Account(FirstName='@Member2', LastName='@' ,RecordTypeId = memberRecordtypeId,ACG_Primary_Phone_Type__c = 'Home',ACG_Is_Primary_Member_in_Household__c=true,Proxy_UI__c = 'test00122');
        members.add(Member2);
        Account MemberRec = new Account(FirstName='@Member#!', LastName='@' ,RecordTypeId = memberRecordtypeId,ACG_Primary_Phone_Type__c = 'Home',AAA_Membership_Level__c = 'Plus'  ,AAA_200_Miles_Premier_Tow__c = false );
        members.add(MemberRec);
        insert members;
        
        
        Account objFacility1 = ACG_TestDataFactory.createAccounts(facilityRecordTypeId,1,false,false)[0];
        //objFacility1.ACG_Comm_Center__c = 'FL';
        //objFacility1.Facility_ID__c = 'CR567';
        //insert objFacility1;
        List<Case> cases = new List<Case>();  
        Case objCase1 = new Case(Subject = '#Populate House Hold Name#',
                                RecordTypeId = ERSRecordTypeId,
                                Description = '#Populate House Hold Name#' , 
                                AccountId = Member1.Id);
        cases.add(objCase1);
        
        /*Test data for updateCasePriorityTest()*/
        Case objCase = new Case(Subject = '#Update Status Test Record#',
                                RecordTypeId = ERSRecordTypeId,
                                Description = '#Update Status Test Record#' , 
                                Status = 'New');
        cases.add(objCase);

        Case objCase3 = new Case(Subject = '#Update Location Record#',
                                RecordTypeId = ERSRecordTypeId,
                                Description = '#Update Location Record#', 
                                Vehicle_Location_Street__c = 'Test',
                                Vehicle_Location_City__c = 'Test',
                                Tow_Destination_Street__c = 'Test',
                                Status = 'New');
        cases.add(objCase3);

        Case caseRec = new Case(Subject = '#Update Priority-Case#',
                                RecordTypeId = ERSRecordTypeId,
                                Description = '#Update Priority-Case#' , 
                                AccountId = MemberRec.Id);
        cases.add(caseRec);

        // Id callAdjustmentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Call Adjustment').getRecordTypeId();
        
        // Case objCallAdjustment = ACG_TestDataFactory.createcase(callAdjustmentRecordTypeId, 'Pending', 'Chat', FALSE);
        // objCallAdjustment.ACG_Provider_Comments__c = 'Test';
        // cases.add(objCallAdjustment);
        
        //Membership_Coverage_Metadata__mdt mdtRec = [SELECT Id,X200_Miles_Coverage__c,Max_Tow_Miles__c,Membership_Level__c,Service_Type__c,Special_Membership__c,State__c,Vehicle_Type__c
        //                                        FROM Membership_Coverage_Metadata__mdt
         //                                       WHERE Max_Tow_Miles__c != NULL
        //                                        LIMIT 1];
        //String VehicleType = (mdtRec.Vehicle_Type__c.split(';'))[0];
        Case caseOverMiles = new Case(Subject = 'Over Miles',
                                      RecordTypeId = ERSRecordTypeId,
                                      Description = 'Over Miles' , 
                                      AccountId = MemberRec.Id,
                                      ACG_Service_Type__c = 'Tow',
                                      Case_Membership_Level__c = 'Basic',
                                      Vehicle_Location_State__c = 'AK',
                                      Member_Vehicle_Type__c = 'BK (Bicycles)');
        cases.add(caseOverMiles);
        insert cases;
        
        //List<ACG_Call_Adjustment_Line_Item__c> callAdjustments = new List<ACG_Call_Adjustment_Line_Item__c>();
/*
        for(integer i =0;i<10;i++){
            ACG_Call_Adjustment_Line_Item__c objCALI = ACG_TestDataFactory.createCallAdjustmentLineItem(objCallAdjustment.Id, true, false);
            callAdjustments.add(objCALI);
        }   
        for(integer i =0;i<10;i++){
            ACG_Call_Adjustment_Line_Item__c objCALI = ACG_TestDataFactory.createCallAdjustmentLineItem(objCallAdjustment.Id, false, false);
            callAdjustments.add(objCALI);
        }
        insert callAdjustments;
        */
      /*Test data for validateCaseStatus()*/
         Id ersADVId=[SELECT Id,Name from Profile WHERE Name='ERS Advocate'].Id;
         User ersUser = new User(LastName = '@Test',
                           FirstName='@ERS',
                           Alias = 'ersT',
                           Email = 'erstestcasestatus@ace.aaa.com',
                           Username = 'erstestcasestatus@ace.aaa.com',
                           ProfileId = ersADVId,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
         insert ersUser;
         
    }
    
    // ERS-230075 - This test is no longer valid, because we commented out the updateCasePriority call in beforeUpdate
    //@isTest
    public static void updateCasePriorityTest(){
        //Case Insert scenario
        Case caseRec = [SELECT Id,ACG_Vehicle_Location_Type__c, ACG_Vehicle_Type__c,Member_Vehicle_Type__c, ERS_Event_Type__c, AccountId,ACG_Service_Type__c, Priority FROM Case WHERE Subject = '#Update Priority-Case#' LIMIT 1]; 
        List<ACG_ERS_Case_Priority_Mapping__mdt> mdtList = [SELECT  ACG_Case_Priority__c,ACG_Case_Priority_Mapping_Status__c,ACG_Case_Record_Type__c,ACG_Club__c,ACG_ERS_Event_Type__c,
                                                                    ACG_Membership_Level__c,ACG_Service_Type__c,ACG_Vehicle_Location_Type__c,ACG_Vehicle_Type__c
                                                            FROM ACG_ERS_Case_Priority_Mapping__mdt
                                                            WHERE   ACG_Case_Priority_Mapping_Status__c = 'Active'
                                                                AND ACG_Case_Record_Type__c = 'ERS'
                                                                AND ACG_Membership_Level__c = 'Plus'
                                                                AND ACG_Club__c = 'All'
                                                                AND ACG_ERS_Event_Type__c = 'All'
                                                                AND ACG_Service_Type__c = 'All'
                                                                AND ACG_Vehicle_Location_Type__c = 'All'
                                                                AND ACG_Vehicle_Type__c = 'All'
                                                           ];
        if(!mdtList.isEmpty()){
            Set<String> setPriority = new Set<String>();
            for(ACG_ERS_Case_Priority_Mapping__mdt mdtRec :mdtList ){
                setPriority.add(mdtRec.ACG_Case_Priority__c);
            }
            String defaultPriority = (String)(Case.Priority.getDescribe().getDefaultValue());
            String priorityToAssign =   setPriority.contains('Critical')? 'Critical': 
                                        setPriority.contains('High')  ? 'High'    :
                                        setPriority.contains('Medium')  ? 'Medium'  :
                                        setPriority.contains('Low')     ? 'Low'     : defaultPriority;
            
            System.assertEquals(priorityToAssign,caseRec.Priority,'Priority was not set to '+priorityToAssign+ 'Priority is: '+ caseRec.Priority);
        }
        //Case update scenario
        caseRec.ACG_Vehicle_Location_Type__c = 'Highway';
        update caseRec;
        List<ACG_ERS_Case_Priority_Mapping__mdt> mdtList2 = [SELECT     ACG_Case_Priority__c,ACG_Case_Priority_Mapping_Status__c,ACG_Case_Record_Type__c,ACG_Club__c,ACG_ERS_Event_Type__c,
                                                                    ACG_Membership_Level__c,ACG_Service_Type__c,ACG_Vehicle_Location_Type__c,ACG_Vehicle_Type__c
                                                            FROM ACG_ERS_Case_Priority_Mapping__mdt
                                                            WHERE   ACG_Case_Priority_Mapping_Status__c = 'Active'
                                                                AND ACG_Case_Record_Type__c = 'ERS'
                                                                AND ACG_Membership_Level__c = 'All'
                                                                AND ACG_Club__c = 'All'
                                                                AND ACG_ERS_Event_Type__c = 'All'
                                                                AND ACG_Service_Type__c = 'All'
                                                                AND ACG_Vehicle_Location_Type__c = 'Highway'
                                                                AND ACG_Vehicle_Type__c = 'All'
                                                           ];
        if(!mdtList2.isEmpty()){
            Set<String> setPriority = new Set<String>();
            for(ACG_ERS_Case_Priority_Mapping__mdt mdtRec :mdtList2 ){
                setPriority.add(mdtRec.ACG_Case_Priority__c);
            }
            String defaultPriority = (String)(Case.Priority.getDescribe().getDefaultValue());
            String priorityToAssign =   setPriority.contains('Critical')? 'Critical': 
                                        setPriority.contains('High')  ? 'High'    :
                                        setPriority.contains('Medium')  ? 'Medium'  :
                                        setPriority.contains('Low')     ? 'Low'     : defaultPriority;
            
            Case updatedCase = [SELECT Id,ACG_Vehicle_Location_Type__c, ACG_Vehicle_Type__c,Member_Vehicle_Type__c, ERS_Event_Type__c, AccountId, ACG_Service_Type__c, Priority FROM Case WHERE Subject = '#Update Priority-Case#' LIMIT 1]; 

            System.assertEquals(priorityToAssign,updatedCase.Priority,'Priority was not set to '+priorityToAssign+ 'Priority is: '+ updatedCase.Priority);
        }
    }

    // @isTest
    // public static void validateCaseStatusApprovedTest(){
    //     Id caseId = [SELECT ACG_Case__c FROM ACG_Call_Adjustment_Line_Item__c LIMIT 1][0].ACG_Case__c;
    //     Account accObj = [select Id from Account where RecordTypeId =: ACG_UtilityClass.FACILITY_RECORDTYPE_ID limit 1];
    //     Account memberacc = [select Id from Account where RecordTypeId =: ACG_UtilityClass.MEMBER_RECORDTYPE_ID limit 1];
    //     WorkOrder wo = new WorkOrder();
    //     wo.Member_Account__c = memberacc.Id;
    //     insert wo;
    //     Test.startTest(); 
    //      Case objCase = new Case(Id = caseId, Status = 'Approved',FSL_Work_Order__c = wo.Id ,Facility__c = accObj.Id);  
    //     try{
    //       update objCase;
    //     }catch(Exception ex){
    //         system.debug(ex.getMessage());
    //         system.assert(ex.getMessage().contains(System.Label.Call_Adjustment_Approved));
    //     }
    //     Test.stopTest();
    // }
    // @isTest
    // public static void validateCaseStatusDeniedTest(){
    //     Id caseId = [SELECT ACG_Case__c FROM ACG_Call_Adjustment_Line_Item__c LIMIT 1][0].ACG_Case__c;
    //     Case objCase = new Case(Id = caseId, Status = 'Denied');
    //     Test.startTest(); 
    //     try{
    //         update objCase;
    //     }catch(Exception ex){
    //         system.assert(ex.getMessage().contains(System.Label.Call_Adjustment_Denied));
    //     }
    //     Test.stopTest();
    // }
    // @isTest
    // public static void validateCaseStatusPartiallyApprovedTest(){
    //     List<ACG_Call_Adjustment_Line_Item__c> lstCALI = [SELECT ACG_Approval__c,ACG_Case__c FROM ACG_Call_Adjustment_Line_Item__c];
    //     for(ACG_Call_Adjustment_Line_Item__c objCALI:lstCALI){
    //         objCALI.ACG_Approval__c = true;
    //     }
    //     Account accObj = [select Id from Account where RecordTypeId =: ACG_UtilityClass.FACILITY_RECORDTYPE_ID limit 1];
    //     update lstCALI;
    //     Account memberacc = [select Id from Account where RecordTypeId =: ACG_UtilityClass.MEMBER_RECORDTYPE_ID limit 1];
    //     WorkOrder wo = new WorkOrder();
    //     wo.Member_Account__c = memberacc.Id;
    //     insert wo;
    //     Case objCase = new Case(Id = lstCALI[0].ACG_Case__c, Status = 'Partially Approved',FSL_Work_Order__c = Wo.Id ,Facility__c = accObj.Id);
    //     Test.startTest(); 
    //     try{
    //        update objCase;
    //     }catch(Exception ex){
    //         system.assert(ex.getMessage().contains(System.Label.Call_Adjustment_Partially_Approved));
    //     }
    //     Test.stopTest();
    // }
    
    @isTest
     public static void updateWorkOrderValuesTest(){
        Test.startTest(); 
        //Case caseRec = [SELECT Id,FSL_Work_Order__c FROM Case WHERE Description ='#Update Status Test Record#' LIMIT 1];
        Case caseRec = ACG_CaseTriggerTest.getCase('#Update Location Record#');
        WorkOrder obWorkOrder=new WorkOrder(CaseId = caseRec.Id);
        Insert obWorkOrder;
        Id Breakdown_rectype = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Breakdown').getRecordTypeId();
        Id Tow_rectype = Schema.SObjectType.ServiceAppointment.getRecordTypeInfosByDeveloperName().get('Tow').getRecordTypeId();
        ServiceAppointment obServApnt1= new ServiceAppointment(ParentRecordId = obWorkOrder.Id,EarliestStartTime = System.now(),DueDate= system.now(),Work_Order__c=obWorkOrder.Id, RecordTypeId = Breakdown_rectype,subject='Breakdown_Appt');
        Insert obServApnt1;
        ServiceAppointment obServApnt2= new ServiceAppointment(ParentRecordId = obWorkOrder.Id,EarliestStartTime = System.now(),DueDate= system.now(),Work_Order__c=obWorkOrder.Id, RecordTypeId = Tow_rectype,subject='Tow_Appt');
        Insert obServApnt2;
        caseRec.Tow_Destination_City__c = 'New York';
        caseRec.Vehicle_Location_City__c= 'North Carolina';
        Update caseRec;
        Test.stopTest();
        
        WorkOrder workorderRec=[SELECT City,StateCode FROM WorkOrder WHERE CaseId=:caseRec.Id];
        ServiceAppointment servapntRec1=[SELECT City FROM ServiceAppointment WHERE subject='Breakdown_Appt'];
        ServiceAppointment servapntRec2=[SELECT City FROM ServiceAppointment WHERE subject='Tow_Appt'];
        System.debug('workorder='+workorderRec.City);
        system.assertEquals( caseRec.Vehicle_Location_City__c, workorderRec.City);
        system.assertEquals( caseRec.Vehicle_Location_City__c, servapntRec1.City);
        system.assertEquals( caseRec.Tow_Destination_City__c, servapntRec2.City);
    }
    
     @isTest
    public static void updateCaseStatusTest(){
        for(case c : [SELECT Id,Subject FROM Case]){
            System.debug('case name is ' + c.Subject);
        }
         //Case caseRec = [SELECT Id FROM Case WHERE Description ='#Update Status Test Record#' LIMIT 1];
        Case caseRec = ACG_CaseTriggerTest.getCase( '#Update Status Test Record#'); 
         caseRec.Status = 'In Progress';
        // Update caseRec;
         caseRec.ACG_Vehicle_Location_Address__c='Test Address@';
         Test.startTest(); 
         Update caseRec;
         Test.stopTest();
         //caseRec=[SELECT Status FROM Case WHERE Subject ='#Update Status Test Record#'];
         caseRec = ACG_CaseTriggerTest.getCase( '#Update Status Test Record#'); 
         system.assertEquals('In Progress',caseRec.Status);
    }
    
    @isTest
         public static void populateCaseMembership(){
         Set<Id> caseIds = new Set<Id>();
         List<Case> caseRec = new List<Case>([SELECT Id FROM Case  LIMIT 2]);
             for(Case cs: caseRec){
                 caseIds.add(cs.Id);
             }
         List<Account> accRec = new List<Account>([SELECT Id From Account LIMIT 2]);
         accRec[0].AAA_Membership_Level__c = 'Plus RV';
         accRec[1].AAA_Membership_Level__c = 'Premier';
               Update accRec;
         Test.startTest(); 
         caseRec[0].AccountId = accRec[0].Id;
         caseRec[1].AccountId = accRec[1].Id;
               Update caseRec;
         accRec[1].AAA_Membership_Level__c = 'Premier RV';  
               Update accRec;
         caseRec[1].AccountId = accRec[1].Id;  
               Update caseRec;             
         Test.stopTest();
        /* List<Case> caseResult = new List<Case>([SELECT Id,Case_Membership_Level__c FROM Case WHERE AccountId =: caseIds limit 3]);
         system.assertEquals('Basic',caseResult[0].Case_Membership_Level__c);
         system.assertEquals('Plus',caseResult[1].Case_Membership_Level__c);
         system.assertEquals('Plus RV',caseResult[2].Case_Membership_Level__c);*/
    }
    
   //@isTest
    public static void validateCaseStatusTest_StatusUpdate()
    {
        //Test Data Record
        User caseUser=[SELECT Id From User WHERE  Alias = 'ersT' AND Email = 'erstestcasestatus@ace.aaa.com'];
        Id memberRecordtypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Member').getRecordTypeId();
       // System.runAs(caseUser){ 
         Account ersAccount = new Account(FirstName='@Test1', LastName='@' ,RecordTypeId = memberRecordtypeId1,ACG_Primary_Phone_Type__c = 'Home');
         insert ersAccount;
         Case ersCase=new Case(Subject ='#Update Status for Case#',Status ='In Progress', AccountId = ersAccount.Id);
         insert ersCase;
         
        Case caseRec=[SELECT Id FROM Case WHERE Subject ='#Update Status for Case#' LIMIT 1];
        //Update the Case status
        Try{
            caseRec.Status='Spotted';
            Update caseRec;
        }
        Catch(Exception e) 
        {   String errMsg = e.getMessage();
            System.assertEquals(true, errMsg.containsIgnoreCase(Label.ERS_CASE_STATUS_VALIDATION_MSG));
        }
     // } 
    }
     @isTest
    public static void validateCaseStatusTest_StatusCanceled()
    {
        User caseUser=[SELECT Id From User WHERE  Alias = 'ersT' AND Email = 'erstestcasestatus@ace.aaa.com'];
         System.runAs(caseUser){ 
         Case ersCase=new Case(Subject ='#Work Order is Created, you can not cancel the case#',Status ='In Progress', Description = '#Work Order is Created, you can not cancel the case#');
         insert ersCase;
         WorkOrder ersWorkOrder= new WorkOrder(Subject='#Update status#'); 
         insert ersWorkOrder;
         //Case caseRec=[SELECT Id,FSL_Work_Order__c,Status FROM Case WHERE Description ='#Work Order is Created, you can not cancel the case#' LIMIT 1];
        Case caseRec = ACG_CaseTriggerTest.getCase('#Work Order is Created, you can not cancel the case#'); 
           //Update the Case status
        Try{
            caseRec.FSL_Work_Order__c=ersWorkOrder.id;
            caseRec.Status='Canceled';
            Update caseRec;
        }
        Catch(Exception e) 
        {   String errMsg = e.getMessage();
            System.assertEquals(true, errMsg.containsIgnoreCase('Once a Work Order is created, you can only cancel the Case via canceling the Work Order.'));
        }
         }
    }
    //@isTest
    public static void updateOverMilesTest(){
        Case objCase = [SELECT Id FROM Case WHERE Subject = 'Over Miles' LIMIT 1];
        objCase.Total_Mileage__c = 300;
        test.startTest();
        update objCase;
        test.stopTest();
        objCase = [SELECT Over_Miles__c FROM Case WHERE Subject = 'Over Miles' LIMIT 1];
        system.assertNotEquals(Null,objCase.Over_Miles__c);
    }
    
    @isTest
    public static void updateCDXInfo_Test(){
        //Test Data
        List<Club_Name_Mappings__mdt> clubDetails = [SELECT Club_Code__c,Club_Name__c FROM Club_Name_Mappings__mdt WHERE Club_Code__c = '006' LIMIT 1];
        Account acc = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId());
        acc.FirstName = 'Test';
        acc.LastName = 'Person Customer';
        acc.CDX_Authorization_Code__c = '123456789';
        acc.CDX_Authorization_Level__c = 'B';
        acc.CDX_Authorization_Message__c = 'Auth Message';
        acc.AAA_Membership_Level__c = 'Plus';
        acc.CDX_Membership_Status__c = 'Active';
        acc.CDX_Motorcycle_Coverage__c = true;
        acc.BillingStreet = '6924 WILLOW LN';
        acc.BillingCity = 'BROOKLYN CENTER';
        acc.BillingStateCode = NULL;
        acc.BillingCountryCode = 'US';
        acc.BillingPostalCode = '55430';
        acc.ACG_Joined_AAA__c = Date.newInstance(2015, 1, 1);
        acc.Membership_Expiration_Date__c = Date.newInstance(2016, 1, 1);
        acc.ACG_Alternate_Phone__c = '1223334444';
        acc.ACG_Club__c = clubDetails[0].Club_Code__c;
        acc.ACG_Club_Name__c = clubDetails[0].Club_Name__c;
        insert acc;

        Test.startTest();
        Case cs = new Case(RecordTypeId = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId());
        insert cs;
        
        //Test Scenario (When Member is removed, fields get populated)
        cs.AccountId = acc.Id;
        update cs;
        Case updatedCase = [SELECT Id,CDX_Authorization_Code__c,CDX_Phone_Number__c FROM Case WHERE Id =: cs.Id LIMIT 1];
        System.assertEquals(true, String.isNotBlank(updatedCase.CDX_Authorization_Code__c), 'Auth Code not populated');
        system.assertEquals(true, String.isNotBlank(updatedCase.CDX_Phone_Number__c), 'Phone field  not updated');
        
        //Test Scenario (When Member is removed, fields get cleared)
        cs.AccountId = NULL;
        update cs;
        updatedCase = [SELECT Id,CDX_Authorization_Code__c,CDX_Phone_Number__c FROM Case WHERE Id =: cs.Id LIMIT 1];
        System.assertEquals(false, String.isNotBlank(updatedCase.CDX_Authorization_Code__c), 'Auth Code not populated');
        system.assertEquals(false, String.isNotBlank(updatedCase.CDX_Phone_Number__c), 'Phone field  not updated');
        Test.stopTest();
    }
    
    @isTest
    public static void generateEncryptedIdTest(){
        //Test Data
        Test.startTest();
        Id ERS_RecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId();
        Case cs = new Case(RecordTypeId = ERS_RecType);
        insert cs;

        //Test Scenario
        List<Case> lstCase = new List<Case>();
        lstCase.add(cs);
        ACG_CaseTriggerService.generateEncryptedId(lstCase);
        String encryptedId = [SELECT Id, Encrypted_Case_Id__c FROM Case WHERE Id =:lstCase[0].Id LIMIT 1].Encrypted_Case_Id__c; 
        Test.stopTest();
        system.assertEquals(true, String.isNotBlank(encryptedId), 'Return empty string');
        
    }
    
     @isTest
    public static void updateSMSOptIn_test(){
        //Test Data
        List<Club_Name_Mappings__mdt> clubDetails = [SELECT Club_Code__c,Club_Name__c FROM Club_Name_Mappings__mdt WHERE Club_Code__c = '006' LIMIT 1];
        Account acc = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACG_Customer').getRecordTypeId());
        acc.FirstName = 'Test';
        acc.LastName = 'Person Customer';
        acc.CDX_Authorization_Code__c = '123456789';
        acc.CDX_Authorization_Level__c = 'B';
        acc.CDX_Authorization_Message__c = 'Auth Message';
        acc.AAA_Membership_Level__c = 'Basic';
        acc.CDX_Membership_Status__c = 'Active';
        acc.CDX_Motorcycle_Coverage__c = true;
        acc.BillingStreet = '6924 WILLOW LN';
        acc.BillingCity = 'BROOKLYN CENTER';
        acc.BillingStateCode = NULL;
        acc.BillingCountryCode = 'US';
        acc.BillingPostalCode = '55430';
        acc.ACG_Joined_AAA__c = Date.newInstance(2015, 1, 1);
        acc.Membership_Expiration_Date__c = Date.newInstance(2016, 1, 1);
        acc.ACG_Alternate_Phone_Type__c =  'Mobile';
        acc.ACG_Alternate_Phone__c =  '1223334444';
        acc.ACG_Primary_Phone_Type__c = 'Mobile';
        acc.Phone = '1234321123';
        acc.ACG_Secondary_Phone_Type__c = 'Mobile';
        acc.PersonHomePhone = '2224321123';
        acc.ACG_Club__c = clubDetails[0].Club_Code__c;
        acc.ACG_Club_Name__c = clubDetails[0].Club_Name__c;
        insert acc;
        
        list<Case> caseRecList = new list<Case>();
        Test.startTest();
        Case cs1 = new Case(RecordTypeId = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId());
        cs1.AccountId = acc.Id;
        cs1.ACG_Case_Contact_Number__c = '1223334444';
        caseRecList.add(cs1);
        //insert cs1;
        
        
        Case cs2 = new Case(RecordTypeId = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId());
        cs2.AccountId = acc.Id;
        cs2.ACG_Case_Contact_Number__c = '1234321123';
        caseRecList.add(cs2);
        //insert cs2;
        
        Case cs3 = new Case(RecordTypeId = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('ACG_ERS').getRecordTypeId());
        cs3.AccountId = acc.Id;
        cs3.ACG_Case_Contact_Number__c = '2224321123';
        caseRecList.add(cs3);
        //insert cs3;
        insert caseRecList;
        Test.stopTest();
    }

    public static Case getCase( String Subject){
        for(Case c : [SELECT ID , Description,FSL_Work_Order__c,Status FROM CASE]){
            if(c.Description?.contains(Subject)) return c;
        }
        return null ;
    }

    @isTest
    public static void updateCasePriorityTest1(){
        Case caseRec = ACG_CaseTriggerTest.getCase( '#Update Status Test Record#'); 
        caseRec.Bypass_Priority_Update__c =true;
        caseRec.Priority = 'High';
        update caseRec;
        Test.startTest();
        ACG_CaseTriggerService.updatePriorityToCritical(new List<Case>{caseRec});
        Test.stopTest();
    }

    @isTest
    public static void notifyRepairShopUpdateTest(){
        Case caseRec = ACG_CaseTriggerTest.getCase( '#Update Status Test Record#'); 
        Test.startTest();
        ACG_CaseTriggerService.notifyRepairShopUpdate(new List<Case>{caseRec});
        Test.stopTest();
    }

    @isTest
    public static void getTimezoneFromMemberLocationTest(){
        Case caseRec = ACG_CaseTriggerTest.getCase( '#Update Status Test Record#'); 
        caseRec.Vehicle_Geolocation__Latitude__s = 20.34;
        caseRec.Vehicle_Geolocation__Longitude__s = -70.34;
        update caseRec;
        Test.startTest();
        List<String> caseIds = new List<String>{caseRec.Id};
        ACG_CaseTriggerService.getTimezoneFromMemberLocation(caseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void updateAllotedMilesTest() {
        List<Case> lstCases = [SELECT Id, FSL_Work_Order__c,ERS_BypassStatusValidationforFlow__c, ACG_Service_Type__c, Case_Membership_Level__c, AccountId, Allotted_Mileage__c, Vehicle_Location_State__c, Total_Mileage__c, Over_Miles__c, ERS_Event_Type__c, Status FROM Case];
        Map<Id,Case> mapOldCases = new Map<Id,Case>();
        for (case c: lstCases) {
            mapOldCases.put(c.Id, c);
        }
        Test.startTest();
        ACG_CaseTriggerService.updateAllotedMiles(lstCases, mapOldCases);
        ACG_CaseTriggerService.updateOverMiles(lstCases,mapOldCases);
        ACG_CaseTriggerService.populateFields(lstCases);
        ACG_CaseTriggerService.validateCaseStatus(lstCases[0]);
        Test.stopTest();
    }
} //171