@isTest
public with sharing class ACG_TestDataFactory{   
    /** 
    * ********************************************************
    * This method is test data to create Service Contract
    * ********************************************************
    */    
    public static ServiceContract createServiceContract(Id pricebookId,String ContractName, Boolean doInsert){
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        ServiceContract objContract = new ServiceContract();
        objContract.pricebook2Id = standardPricebook.Id;
        objContract.Name = ContractName;
        if(doInsert){
            insert objContract ;
        }
        return objContract ;
    } 
    /** 
    * ********************************************************
    * This method is test data to create Contract Line Item
    * ********************************************************
    */    
    public static ContractLineItem createContractLineItem(Id pricebookEntryId, Id serviceContractId, Integer quantity, Date startDate, Date endDate,Integer UnitPrice, Boolean doInsert){
        ContractLineItem objCLI = new ContractLineItem();
        objCLI.quantity = quantity;
        objCLI.startDate = startDate;
        objCLI.endDate = endDate;
        objCLI.UnitPrice = UnitPrice;
        objCLI.pricebookEntryId = pricebookEntryId;
        objCLI.serviceContractId = serviceContractId;
        if(doInsert){
            insert objCLI ;
        }
        return objCLI ;
    }        
    /** 
    * ********************************************************
    * This method is test data to create Product
    * ********************************************************
    */    
    public static Product2 createProduct(String name, String productCode, Boolean isActive, Boolean doInsert){
        Product2 objprod = new Product2();
        objprod.name = name;
        objprod.productCode = productCode;
        objprod.isActive = isActive;
        if(doInsert){
            insert objprod ;
        }
        return objprod ;
    }
    /** 
    * ********************************************************
    * This method is test data to create PriceBook Entry
    * ********************************************************
    */    
    public static PricebookEntry createPricebookEntry(Id pricebookId, Id productId, Boolean isActive,Integer UnitPrice, Boolean doInsert){
        PricebookEntry objPBE = new PricebookEntry();
        objPBE.Pricebook2Id = pricebookId;
        objPBE.Product2Id = productId;
        objPBE.UnitPrice = UnitPrice;
        objPBE.isActive = isActive;
        if(doInsert){
            insert objPBE ;
        }
        return objPBE ;
    }
    
    /** 
    * ********************************************************
    * This method is test data to create PriceBook Entry
    * ********************************************************
    */
    public static case createcase(Id RecordTypeId,String Status,String origin,Boolean doInsert){
        Case objCS = new Case();
        objCS.recordtypeId = RecordTypeId; 
        objCS.Origin = origin;
        objCS.Status = status;
        if(doInsert){
            insert objCS ;
        }
        return objCS ;
    }
    
    /** 
    * **************************************************************
    * This method is test data to create Facility Adjustment 
    * **************************************************************
    */
    public static ACG_Facility_Adjustment__c createFA(ID AccountID, Boolean doInsert){
        ACG_Facility_Adjustment__c objFA = new ACG_Facility_Adjustment__c();
        objFA.Account__c = AccountID;
        objFA.ACG_Payment_Amount__c = 400;
        if(doInsert){
            insert objFA ;
        }
        return objFA ;
    }
    
 
  /** 
    * **************************************************************
    * This method is test data to create Facility Adjustment Payment 
    * **************************************************************
    */
    public static ACG_Facility_Adjustment_Payment__c createFAP(Id FAId, Boolean doInsert){
        ACG_Facility_Adjustment_Payment__c objFAP = new ACG_Facility_Adjustment_Payment__c();
        objFAP.ACG_Adjustment_ID__c = FAId;
        if(doInsert){
            insert objFAP ;
        }
        return objFAP ;
    }
     /** 
    * **************************************************************
    * This method is test data to create Account 
    * **************************************************************
    */ 
    public static Account createAccount(Id recordtypeId,String Name, Boolean doInsert){
        Account objAcc = new Account();
        objAcc.Name	 = Name ;
        objAcc.RecordTypeId	= recordtypeId;
        objAcc.ACG_Primary_Phone_Type__c = 'Home';
        if(doInsert){
            insert objAcc ;
        }
        return objAcc ;
    }
    /** 
    * **************************************************************
    * This method is test data to create Contact
    * **************************************************************
    */  
    public static Contact createContact(Id recordtypeId,Boolean doInsert){
        Contact objCon = new Contact();
        objCon.RecordTypeId	= recordtypeId;
        objCon.LastName='ABC';
        if(doInsert){
            insert objCon ;
        }
        return objCon ;
    }
    
    /*
    * @description: method to create accounts for a given recordtypeId
    * @date: Aug 12, 2021
    * @return: List<Account> -> list of accounts created
    * @param1: recordtypeId -> recordtypeId of the account(optional)
    * @param2: count -> count of accounts to be created
    * @param3: isInsert -> to do DML call or not ?
    * @author: Kunal Dixit (kdixit@acg.aaa.com)
    */
    public static List<Account> createAccounts(Id recordtypeId,Integer count, Boolean isInsert,Boolean isPersonAccount){
        Id CUSTOMER_ACCOUNT_RECORDTYPEID = ACG_UtilityClass.CUSTOMER_RECORDTYPE_ID;
        Id MEMBER_ACCOUNT_RECORDTYPEID = ACG_UtilityClass.MEMBER_RECORDTYPE_ID;
        
        List<sObject> lstAccounts = new List<Account>();
       // String sNameField = isPersonAccount ? 'LastName' : 'Name';
        Map<String,Object> mapFieldsToPopulate = new Map<String,Object>();//key -> fieldAPIName, value -> fieldValue
        if(isPersonAccount){
            mapFieldsToPopulate.put('PersonEmail','test@test.com');
            mapFieldsToPopulate.put('BillingStreet','415 Mission Street');
            mapFieldsToPopulate.put('BillingCity','Atlanta');
            mapFieldsToPopulate.put('BillingState','GA');
            //mapFieldsToPopulate.put('BillingCountry','United States');
            mapFieldsToPopulate.put('BillingCountry','United States');
            mapFieldsToPopulate.put('ACG_Primary_Phone_Type__c','Home');
        }
        mapFieldsToPopulate.put('recordTypeId', recordTypeId);
        sObject objAccount;
        for(Integer i = 0; i < count; i++){
            objAccount = new Account();
            objAccount.put(isPersonAccount ? 'LastName' : 'Name','TestAccount'+i);
            for(String thisField : mapFieldsToPopulate.keyset()){
                objAccount.put(thisField,mapFieldsToPopulate.get(thisField));
            }
            lstAccounts.add(objAccount);
        }
        if(isInsert){
            insert lstAccounts;
        }
        return (List<Account>)lstAccounts;
    }
    
    /*
    * @description: method to create an ACR
    * @date: Aug 12, 2021
    * @return: AccountContactRelation record 
    * @param1: accountId 
    * @param2: contactId 
    * @param3: isPrimary -> is Primary member or not ?
    * @param4: isInsert -> to do DML call or not ?
    * @author: Kunal Dixit (kdixit@acg.aaa.com)
    */
    public static AccountContactRelation createAccContactRelation(Id accountId, Id contactId, Boolean isPrimary, Boolean isInsert){
        AccountContactRelation newRelation = new AccountContactRelation(
            accountId = accountId, 
            contactId = contactId, 
            isActive = true
            );
            //Finserv__Primary__c = isPrimary
        if(isInsert){
            insert newRelation;
        }
        return newRelation;
    }
    
    /*
    * @description: method to create facility adjustments
    * @date: Aug 17, 2021
    * @return: List<ACG_Facility_Adjustment__c> -> list of facility adjustments created
    * @param1: accountId -> id of the facility account
    * @param2: count -> count of accounts to be created
    * @param3: isInsert -> to do DML call or not ?
    * @author: Akarsh Jain (ajain@acg.aaa.com)
    */
    public static List<ACG_Facility_Adjustment__c> createFacilityAdjustments(Id accountId, Integer count, Boolean isInsert){
        List<ACG_Facility_Adjustment__c> lstFcAdjustment = new List<ACG_Facility_Adjustment__c>();
        for(Integer i = 0; i < count; i++){
            ACG_Facility_Adjustment__c objFcAdjustment = new ACG_Facility_Adjustment__c();
            //objFcAdjustment.Name = 'FA-' + i;
            objFcAdjustment.Account__c = accountId;
            objFcAdjustment.ACG_Payment_Amount__c = 100;
            objFcAdjustment.ACG_No_of_Payments__c = 1;
            objFcAdjustment.ACG_Status__c = 'New';
            lstFcAdjustment.add(objFcAdjustment);
        }
        if(isInsert){
            insert lstFcAdjustment;
        }
        return lstFcAdjustment;
    }
    
   /*
    * @description: method to create facility adjustments
    * @date: Aug 17, 2021
    * @return: ACG_Facility_Adjustment_Payment__c -> instance of facility adjustments payment created
    * @param1: adjustmentId -> id of the facility adjustment
    * @param2: name -> name of facility adjustments payment
	* @param3: amount -> payment amount
    * @param4: isInsert -> to do DML call or not ?
    * @author: Akarsh Jain (ajain@acg.aaa.com)
    */
    /*public static ACG_Facility_Adjustment_Payment__c createFacilityAdjustmentPayment(Id adjustmentId, Double amount, Boolean isInsert){
        ACG_Facility_Adjustment_Payment__c objFAP = new ACG_Facility_Adjustment_Payment__c();
        objFAP.ACG_Adjustment_ID__c = adjustmentId;
        objFAP.ACG_Payment_Amount__c = amount;
        if(isInsert){
            insert objFAP;
        }
        return objFAP;
    }*/
    
    
    /*public static Reciprocal__c createreciprocal(String recordtypeId, String status,String transactiontype, Boolean isInsert){
        Reciprocal__c objREC = new Reciprocal__c();
        if(!String.isBlank(recordtypeId)){
        	objREC.RecordTypeId	= recordtypeId;
        }
        objREC.Dispute_Code__c ='D0';
        objREC.Transaction__c = transactiontype;
        objREC.Status__c = status;
        if(isInsert){
            insert objREC;
        }
        return objREC;
    }*/
   /*
    * @description: method to create reimbursements
    * @date: Aug 20, 2021
    * @return: ACG_Reimbusrement__c -> instance of reimbursement created
    * @param1: memberId -> id of the member
	* @param2: amount -> status
    * @param3: serviceDate -> date of service
    * @param4: workType -> type of Emergency
    * @param5: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    /*public static ACG_Reimbursement__c createReimbursement(Id memberId, String status, Date serviceDate,String serviceType, Boolean isInsert){
        ACG_Reimbursement__c objReim = new ACG_Reimbursement__c();
        objReim.ACG_Member_Name__c = memberId;
        objReim.ACG_Status__c = status;
        objReim.ACG_Service_Date__c = serviceDate;
        objReim.ACG_Service_Type__c = serviceType;
        if(isInsert){
            insert objReim;
        }
        return objReim;
    }*/
   /*
    * @description: method to create user
    * @date: Aug 20, 2021
    * @return: User -> instance of User created
    * @param1: ProfileId -> profile id
    * @param2: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    public static User createUser(Id ProfileId, Boolean isInsert){
        String orgId = UserInfo.getOrganizationId(); 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); 
        Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName = orgId + dateString+RandomId; 
        User usr = new User();
        usr.firstname = 'ABC'; 
        usr.lastName = 'XYZ'; 
        usr.email = uniqueName + '@test' + orgId + '.org';
        usr.Username = uniqueName + '@test' + orgId + '.org';
        usr.EmailEncodingKey = 'ISO-8859-1'; 
        usr.Alias = uniqueName.substring(18, 23);
        usr.TimeZoneSidKey = 'America/Los_Angeles'; 
        usr.LocaleSidKey = 'en_US'; 
        usr.LanguageLocaleKey = 'en_US';
        usr.ProfileId = ProfileId;
        if(isInsert){
            insert usr;
        }
        return usr;
    }
   /*
    * @description: method to create Reimbursement Payment Category	
    * @date: Aug 20, 2021
    * @return: ACG_Reimbursement_Payment_Category__c -> instance of Reimbursement Payment Category	 created
    * @param1: amount -> approved amount
    * @param2: reimId -> reimbursement
    * @param3: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    /*public static ACG_Reimbursement_Payment_Category__c createReimbursementPaymentCategory(Decimal amount, Id reimbId, Boolean isInsert){
        ACG_Reimbursement_Payment_Category__c objRPC = new ACG_Reimbursement_Payment_Category__c();
        objRPC.ACG_Reimbursement__c = reimbId;
        objRPC.ACG_Approved_Amount__c = amount;
        if(isInsert){
            insert objRPC;
        }
        return objRPC;
    }*/
   /*
    * @description: method to create Reimbursement Payment Category	
    * @date: Aug 20, 2021
    * @return: Group -> instance Group created
    * @param1: groupName -> name of the group
    * @param2: developerName -> API Name of the group
    * @param3: type -> group type
    * @param4: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    public static Group createGroup(String groupName, String developerName, String type, Boolean isInsert){
        Group grp = new Group();
        grp.Name = groupName;
        grp.DeveloperName =  developerName;
        grp.Type = type;
        if(isInsert){
            insert grp;
        }
        return grp;
    }
   /*
    * @description: method to create GroupMember	
    * @date: Aug 20, 2021
    * @return: Group -> instance Group Member created
    * @param1: groupId -> id of the group
    * @param2: usrId -> user's Id
    * @param3: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    public static GroupMember createGroupMember(Id groupId, id usrId, Boolean isInsert){
        GroupMember grpMember = new GroupMember();
        grpMember.GroupId = groupId;
        grpMember.UserOrGroupId =  usrId;
        if(isInsert){
            insert grpMember;
        }
        return grpMember;
    }
   /*
    * @description: method to create Call Adjustment Line Item	
    * @date: Sep 20, 2021
    * @return: ACG_Call_Adjustment_Line_Item__c -> instance Call Adjustment Line Item created
    * @param1: caseId -> id of the case
    * @param2: isApproved -> if CALI is approved or not
    * @param3: isInsert -> to do DML call or not ?
    * @author: Manmeet Kaur (mkaur@acg.aaa.com)
    */
    /*public static ACG_Call_Adjustment_Line_Item__c createCallAdjustmentLineItem(Id caseId, boolean isApproved, Boolean isInsert){
        ACG_Call_Adjustment_Line_Item__c objCALI = new ACG_Call_Adjustment_Line_Item__c();
        objCALI.ACG_Approval__c = isApproved;
        objCALI.ACG_Case__c =  caseId;
        if(isInsert){
            insert objCALI;
        }
        return objCALI;
    }*/
    
    /*
    * @description: method to create WorkOrder	
    * @date: Sep 22, 2021
    * @return: WorkOrder -> instance Call Workorder
    * @param1: facilityId -> id of the facility
    * @param2: memberId -> id of member
    * @param3: isInsert -> to do DML call or not ?
    * @author: Dhruv Javiya 
    */
    public static WorkOrder createWorkOrder(Id facilityId, Id memberId,Id recordTypeId, Boolean isInsert){
        WorkOrder WO = new WorkOrder();
        WO.AccountId = facilityId;
        WO.Member_Account__c = memberId;
        WO.RecordTypeId = recordTypeId;
        if(isInsert){
            insert WO;
        }
        return WO;
    }
    
    /*
    * @description: method to create createAnnouncements	
    * @date: Sep 22, 2021
    * @return: Announcements__c -> instance Call Announcements__c
    * @param1: Name -> name
    * @param2: Message -> message
    * @param3: isInsert -> to do DML call or not ?
    * @author: Dhruv Javiya 
    */
    /*public static Announcements__c createAnnouncements(String Name,String Message, Boolean isInsert){
        Announcements__c Announcements = new Announcements__c();
        Announcements.Name=Name;
        Announcements.Announcement_Description__c=Message;
        Announcements.DRR__c=true;
        Announcements.Status__c='Active';
        Announcements.Approval_Status__c='Approved';
        if(isInsert){
            insert Announcements;
        }
        return Announcements;
    }*/
	
		
    /*	
    * @description: method to create Intgration setting		
    * @date: Nov 11, 2021	
    * @return: Integration_Settings__c -> instance Call Integration_Settings__c	
    * @param1: Name -> name	
    * @param2: Method -> Method	
    * @param3: NamedCredential -> NamedCredential	
    * @param4: Path -> Path	
    * @param5: EndpointURL -> NamedCredential	
    * @param6: isInsert -> to do DML call or not ?	
    * @author: Dhruv Javiya 	
    */	
    public static Integration_Settings__c createIntegrationSetting(String Name,String Method,String NamedCredential,String Path,String EndpointURL, Boolean isInsert){	
        Integration_Settings__c IntegrationSetting = new Integration_Settings__c();	
        IntegrationSetting.name =Name;	
        IntegrationSetting.Method__c=Method;	
		IntegrationSetting.Header_Value__c='[{"key":"client_id","value":"8e039d04fc02429aa188fff0bfcb5277"},{"key":"client_secret","value":"c57aF003FE0f437A864A5A9d413b19B8"},{"key":"Content-Type","value":"application/json"},{"key":"Source","value":"ARR"}]';	
        IntegrationSetting.Named_Credential__c=NamedCredential;	
        IntegrationSetting.Path__c=Path;	
        IntegrationSetting.Enpoint_URL__c=EndpointURL;	
        IntegrationSetting.Request_Timeout__c=120000;	
        if(isInsert){	
            insert IntegrationSetting;	
        }	
        return IntegrationSetting;	
    }
    
    /*
    * @description: method to create ERS Payment	
    * @date: Sep 22, 2021
    * @return: ERS_Payment__c
    * @param1: recordTypeId -> id of the ERS Payment record type
    * @param3: isInsert -> to do DML call or not ?
    * @author: Akarsh Jain 
    */
    public static ERS_Payment__c createERSPayment(Id recordTypeId, Boolean isInsert){
        ERS_Payment__c payment = new ERS_Payment__c();
        payment.RecordTypeId = recordTypeId;
        payment.Status__c = ACG_ConstantsClass.ERS_PAYMENT_STATUS_READY_FOR_PAYMENT_STRING;
        if(isInsert){
            insert payment;
        }
        return payment;
    }
    
    /*public static ERS_Payment__c createChildERSPayment(Id recordTypeId, Boolean isInsert, Id paymentId){
        ERS_Payment__c payment = new ERS_Payment__c();
        payment.RecordTypeId = recordTypeId;
        payment.payment__c = paymentId;
        payment.Status__c = ACG_ConstantsClass.ERS_PAYMENT_STATUS_READY_FOR_PAYMENT_STRING;
        if(isInsert){
            insert payment;
        }
        return payment;
    }*/
    
    /*
    * @description: method to create ERS Payment Line Item	
    * @date: Oct 15, 2021
    * @return: ERS_Payment_Line_Item__c
    * @param1: paymentId -> id of the ERS Payment
    * @param2: productId -> id of the Product
    * @param3: amount -> amount to pay
    * @param3: isInsert -> to do DML call or not ?
    * @author: Akarsh Jain 
    */
    public static ERS_Payment_Line_Item__c createERSPaymentLineItem(Id paymentId, Id productId, Decimal amount, Boolean isInsert){
        ERS_Payment_Line_Item__c paymentLineItem = new ERS_Payment_Line_Item__c();
        paymentLineItem.Payment_ID__c = paymentId;
         paymentLineItem.ACG_Units__c = 1;
        paymentLineItem.ACG_Product__c = productId;
        paymentLineItem.Total_Amount__c = amount;
        if(isInsert){
            insert paymentLineItem;
        }
        return paymentLineItem;
    }
}