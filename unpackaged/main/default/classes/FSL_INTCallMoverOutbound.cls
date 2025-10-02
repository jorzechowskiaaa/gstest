/**** Apex Class Name    :    FSL_INTCallMoverOutbound
    * Description        :    API class  to transfer the call to national for out of ACG territory location
    * Modification Log   :
    * Test Class Name    :    
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Venkat Kommuri              Oct 18 2021             Created
*********************************************************************************/
public without sharing class FSL_INTCallMoverOutbound {
   
    public static final Map<String,Integration_Settings__c> mapIntSettings = 
                                                         IntegrationUtil.getIntegrationSettings();
    public static Map<String, String> mapStateValueCode = new Map<String, String>();
    public static Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
    public static List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    public static final String SOURCE_SF = 'Salesforce';

    Public static Response_wrapper generateCallMoverRequest(Id CaseId){
        case objcase = fetchcase(caseId);
        Response_wrapper resp = new Response_wrapper();
        if(objcase.Call_Source__c == SOURCE_SF){
            Map<string,string> mapofMemebershiplevels = new Map<string,string>();
            for(Membership_Type_Mapping__mdt membeshiptype:[select id,MasterLabel,Member_Level__c from Membership_Type_Mapping__mdt]){
                    mapofMemebershiplevels.put(membeshiptype.MasterLabel,membeshiptype.Member_Level__c);
            }
            for(Schema.PicklistEntry f : ple) {
                    mapStateValueCode.put(f.getLabel(), f.getValue());
            }
            
            String[] IdTcodePCC;
            string pacesettercode= objcase.Pacesetter_Code__c;
            string T_Code = objcase.T_Code__c;
            //if(objcase.Pacesetter_Code__c==null || objcase.T_Code__c==null){
            If(!Test.isRunningTest()){
                IdTcodePCC =  (ERS_WorkOrderFromCase.getWorkTypeId(objcase)).split('#');
                pacesettercode = IdTcodePCC[2];
                T_Code = IdTcodePCC[1];
            }
            FSL_CallMoverJSONRequest_Wrapper jsonWrapper = new FSL_CallMoverJSONRequest_Wrapper();
            jsonWrapper.id=IntegrationUtil.generateUniqueId();
            jsonWrapper.requestEventType = ACG_ConstantsClass.CREATE;
            jsonWrapper.subType = ACG_ConstantsClass.CREATE;
            jsonWrapper.version = ACG_ConstantsClass.API_VERSION;
            FSL_CallMoverJSONRequest_Wrapper.sourceSystem sourceSystem = new FSL_CallMoverJSONRequest_Wrapper.sourceSystem();
            FSL_CallMoverJSONRequest_Wrapper.systemOrganization soruceSystemOrg = new FSL_CallMoverJSONRequest_Wrapper.systemOrganization();
            sourceSystem.systemId = Label.FSL_SourceClubCode; //ACG_ConstantsClass.ACG_CLUBCODE;
            soruceSystemOrg.code = Label.FSL_SourceClubCode; //ACG_ConstantsClass.ACG_CLUBCODE;
            soruceSystemOrg.name = Label.Club_Name; //ACG_ConstantsClass.ACG;
            sourcesystem.systemOrganization = soruceSystemOrg;
            FSL_CallMoverJSONRequest_Wrapper.sourceSystem targetSystem = new FSL_CallMoverJSONRequest_Wrapper.sourceSystem();
            FSL_CallMoverJSONRequest_Wrapper.systemOrganization targetSystemOrg = new FSL_CallMoverJSONRequest_Wrapper.systemOrganization();
            targetSystem.systemId = ACG_ConstantsClass.CI; 
            targetSystemOrg.code = ACG_ConstantsClass.NaTIONAL_CLUBCODE;
            targetSystemOrg.name = ACG_ConstantsClass.CI;
            targetSystem.systemOrganization = targetSystemOrg;
            jsonWrapper.SourceSystem =sourcesystem;
            jsonWrapper.targetSystem = targetSystem;
            jsonWrapper.createDate = objcase.createdDate.getTime();
            List<FSL_CallMoverJSONRequest_Wrapper.Calls> lstCalls = new List<FSL_CallMoverJSONRequest_Wrapper.Calls>(); 
            FSL_CallMoverJSONRequest_Wrapper.Calls call = new FSL_CallMoverJSONRequest_Wrapper.Calls();
            string strDay;
            strDay =objcase.createdDate.day()<10?'0'+String.valueof(objcase.createdDate.day()):String.valueof(objcase.createdDate.day());
            string strMonth;
            strMonth =objcase.createdDate.month()<10?'0'+String.valueof(objcase.createdDate.month()):String.valueof(objcase.createdDate.month());
            call.callKey = Label.FSL_SourceClubCode+'-'+String.valueof(objcase.createdDate.Year())+strMonth+strDay+'-'+objcase.CaseNumber;
            call.callDate =objcase.createdDate.format('yyyy-MM-dd');//EMI-12-30-2024------updated for 2025 issue
            call.callId = objcase.CaseNumber;
            call.requestingSystemCallId = objcase.caseNumber;
            call.version = ACG_ConstantsClass.API_SUBVERSION;
            FSL_CallMoverJSONRequest_Wrapper.Channel channel = new FSL_CallMoverJSONRequest_Wrapper.Channel();
            channel.channelType = objcase.call_origin__c ==ACG_ConstantsClass.IVR || objcase.call_origin__c == ACG_ConstantsClass.CASE_EVENT_TYPE_RAP
                                ? objcase.call_origin__c : ACG_ConstantsClass.CALL_CENTER;
            channel.org = soruceSystemOrg;
            FSL_CallMoverJSONRequest_Wrapper.Contact contact = new FSL_CallMoverJSONRequest_Wrapper.Contact();
            contact.userId ='';
            contact.contactType = ACG_ConstantsClass.CAPAGENT;
            channel.contact = contact;
            call.channel = channel;
            FSL_CallMoverJSONRequest_Wrapper.vehicle vehicle = new FSL_CallMoverJSONRequest_Wrapper.vehicle();
            vehicle.make = objcase.ACG_Make__c;
            vehicle.year = objcase.ACG_Year__c!=null?objcase.ACG_Year__c!=ACG_ConstantsClass.OTHER?Integer.Valueof(objcase.ACG_Year__c):null:null;
            vehicle.color = objcase.ACG_Color__c;
            vehicle.model = objcase.ACG_Model__c;
            vehicle.fuelType = objcase.Member_Vehicle__r.Vehicle_Fuel_Type__c;
            vehicle.driveType = objcase.Member_Vehicle__r.Vehicle_Drive_Type__c;
            vehicle.odometer = Integer.Valueof(objcase.Member_Vehicle__r.Vehicle_Odometer__c);
            vehicle.vehicleType = objcase.Member_Vehicle_Type__c!=null?objcase.Member_Vehicle_Type__c.substring(0,2):null;
            vehicle.trim = objcase.Member_Vehicle__r.Vehicle_Trim__c;
            vehicle.vin = objcase.Member_Vehicle__r.Vehicle_VIN__c;
            vehicle.tag = objcase.Member_Vehicle__r.Vehicle_Tag__c;
            vehicle.state = objcase.Member_Vehicle__r.Vehicle_State__c;
            vehicle.specialEquipmentNeeds = objcase.Member_Vehicle__r.Vehicle_Special_Equipment_Needs__c;
            call.vehicle = vehicle;
            FSL_CallMoverJSONRequest_Wrapper.Customer customer = new FSL_CallMoverJSONRequest_Wrapper.Customer();
            customer.languagePreference =ACG_ConstantsClass.EN;
            FSL_CallMoverJSONRequest_Wrapper.Contact_customer customerContact = new FSL_CallMoverJSONRequest_Wrapper.Contact_customer();
            customerContact.contactType = ACG_ConstantsClass.CAPCUSTOMER;
            customerContact.firstName = objcase.Account.FirstName;
            customerContact.LastName = objcase.Account.LastName;
            List<FSL_CallMoverJSONRequest_Wrapper.Phones> lstphones = new List<FSL_CallMoverJSONRequest_Wrapper.Phones>();
            FSL_CallMoverJSONRequest_Wrapper.Phones phone = new FSL_CallMoverJSONRequest_Wrapper.Phones();
            List<FSL_CallMoverJSONRequest_Wrapper.Emails> lstemails = new List<FSL_CallMoverJSONRequest_Wrapper.Emails>();
            FSL_CallMoverJSONRequest_Wrapper.Emails email = new FSL_CallMoverJSONRequest_Wrapper.Emails();
            phone.phoneNumber = objcase.ACG_Case_Contact_Number__c;
            phone.smsOptIn = objcase.ACG_SMS_Opt_In__c;
            phone.phoneType = objcase.Account.ACG_Primary_Phone_Type__c==ACG_ConstantsClass.S_HOME?ACG_ConstantsClass.HOME
                            :objcase.Account.ACG_Primary_Phone_Type__c==ACG_ConstantsClass.WORK?ACG_ConstantsClass.BUSINESS
                            :objcase.Account.ACG_Primary_Phone_Type__c==ACG_ConstantsClass.MOBILE?ACG_ConstantsClass.CELLULAR:null;
            lstphones.add(phone);
            customerContact.phones =lstphones;
            email.address = objcase.Account.PersonEmail;
            email.emailType =ACG_ConstantsClass.PERSONAL;
            lstemails.add(email);
            customerContact.emails=lstemails;
            customer.contact = customerContact;
            List<FSL_CallMoverJSONRequest_Wrapper.Memberships> lstMemberships = new List<FSL_CallMoverJSONRequest_Wrapper.Memberships>();
            FSL_CallMoverJSONRequest_Wrapper.Memberships membership = new FSL_CallMoverJSONRequest_Wrapper.Memberships();
            List<FSL_CallMoverJSONRequest_Wrapper.Entitlements> lstEntitlements = new List<FSL_CallMoverJSONRequest_Wrapper.Entitlements>();
            FSL_CallMoverJSONRequest_Wrapper.Entitlements Entitlements = new FSL_CallMoverJSONRequest_Wrapper.Entitlements();
            membership.id = objcase.Account.ACG_AAA_Membership__c;
            membership.originalMemberId = objcase.Account.ACG_AAA_Membership__c;
            membership.membershipType =objcase.Account.ACG_Membership_Type__c;
            membership.memberLevel = mapofMemebershiplevels.get(objcase.Account.AAA_Membership_Level__c);
            membership.expirationDate = String.valueof(objcase.Account.Membership_Expiration_Date__c);
            membership.memberBirthday = String.valueof(objcase.Account.ACG_Date_of_Birth__c);
            membership.memberSince = objcase.Account.Membership_Since__pc;
            membership.sponsor = objcase.Account.Membership_Sponsor__pc; 
            membership.program = objcase.Account.Membership_Program__pc;
            membership.authorizationCode = objcase.Account.Membership_Code__pc;
            membership.authorizationLevel = objcase.Account.Membership_Authorization__pc;
            membership.isLocalClub = objcase.Account.Membership_IsLocalClub__pc;
            membership.memberStatus = objcase.Account.ACG_Membership_Status__c!=null?objcase.Account.ACG_Membership_Status__c.substring(0,1):null;
            membership.programName = objcase.Account.Membership_Org__pc;
            membership.programPhone = objcase.Account.Membership_Org_Phone__pc; 
            FSL_CallMoverJSONRequest_Wrapper.systemOrganization membershipOrg = new FSL_CallMoverJSONRequest_Wrapper.systemOrganization();
            membershipOrg.code = objcase.Account.ACG_Club__c; //Member_Club_Code__c
            membershipOrg.name = objcase.Account.ACG_Club_Name__c; //Parent_Club_Name__c
            membership.org = membershipOrg;
            Entitlements.associates = null;
            Entitlements.callsAllowed  = objcase.Account.ACG_Entitlements_Allotted__c!=null?Integer.valueof(objcase.Account.ACG_Entitlements_Allotted__c):null;
            Entitlements.callsUsed = objcase.Account.ACG_Entitlements_Used__c!=null?Integer.valueof(objcase.Account.ACG_Entitlements_Used__c):null;
            Integer EntitlementsAlloted = objcase.Account.ACG_Entitlements_Allotted__c!=null?Integer.valueof(objcase.Account.ACG_Entitlements_Allotted__c):0;
            Integer EntitlementsUsed =  objcase.Account.ACG_Entitlements_Used__c!=null?Integer.valueof(objcase.Account.ACG_Entitlements_Used__c):0;
            Entitlements.callsRemaining = EntitlementsAlloted - EntitlementsUsed;
            lstEntitlements.add(Entitlements);
            membership.entitlements = lstEntitlements;
            lstMemberships.add(membership);
            customer.memberships = lstMemberships;
            call.customer =customer;
            FSL_CallMoverJSONRequest_Wrapper.Service service = new FSL_CallMoverJSONRequest_Wrapper.service();
            service.callType =  objcase.ERS_Event_Type__c ==ACG_ConstantsClass.CASE_EVENT_TYPE_RAP?objcase.ERS_Event_Type__c:ACG_ConstantsClass.MEMBER;
            service.numberOfPassengers = objcase.Number_of_passengers__c!=null?Integer.valueof(objcase.Number_of_passengers__c):null;
            service.duty = objcase.Member_Vehicle__r.Duty__c;
            service.timezoneId='';
            service.timezoneOffset = '';
            FSL_CallMoverJSONRequest_Wrapper.Status status = new FSL_CallMoverJSONRequest_Wrapper.Status();
            status.status =ACG_ConstantsClass.SP;
            status.updateCode = ACG_ConstantsClass.SP;
            status.modifiedDate = objcase.LastModifiedDate;
            service.status = status;
            List<FSL_CallMoverJSONRequest_Wrapper.TroubleCodes> lsttroublecodes = new List<FSL_CallMoverJSONRequest_Wrapper.TroubleCodes>();
            FSL_CallMoverJSONRequest_Wrapper.TroubleCodes troublecodes = new FSL_CallMoverJSONRequest_Wrapper.TroubleCodes();
            troublecodes.troubleCodeType = ACG_ConstantsClass.PACESETTER;
            troublecodes.code = pacesettercode!=null?pacesettercode:objcase.ACG_work_type__r.Trouble_Code__C;
            troublecodes.description = '';
            if(troublecodes.code!=null)
            lsttroublecodes.add(troublecodes);
            FSL_CallMoverJSONRequest_Wrapper.TroubleCodes troublecodes1 = new FSL_CallMoverJSONRequest_Wrapper.TroubleCodes();
            troublecodes1.troubleCodeType = ACG_ConstantsClass.PROBLEM;
            troublecodes1.code = T_Code!=null?T_Code:objcase.ACG_work_type__r.T_Code__C;
            troublecodes1.description = '';
            if(troublecodes1!=null)
            lsttroublecodes.add(troublecodes1);
            service.troubleCodes = lsttroublecodes;
            List<FSL_CallMoverJSONRequest_Wrapper.ServiceLocations> lstservicelocations = new List<FSL_CallMoverJSONRequest_Wrapper.ServiceLocations>();
            FSL_CallMoverJSONRequest_Wrapper.ServiceLocations breakdownservicelocation = new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations();
            breakdownservicelocation.serviceLocationType=ACG_ConstantsClass.BREAKDOWN;
            FSL_CallMoverJSONRequest_Wrapper.Foi breakdownfoi =  new FSL_CallMoverJSONRequest_Wrapper.Foi();
            breakdownfoi.foiType = ACG_ConstantsClass.ADDRESS;
            FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location breakdownlocation = new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location();
            breakdownlocation.latitude = objcase.Vehicle_Geolocation__Latitude__s;
            breakdownlocation.longitude = objcase.Vehicle_Geolocation__Longitude__s;
            FSL_CallMoverJSONRequest_Wrapper.Address breakdownAddress = new FSL_CallMoverJSONRequest_Wrapper.Address();
            breakdownAddress.addressType = ACG_ConstantsClass.PHYSICAL;
            string streetval=' ';
            //Added to split the address and update streetnumber
            list<string> fulladd= new list<string>();
            if(objcase.Vehicle_Location_Street__c!=null && objcase.Vehicle_Location_Street__c!=''){
            fulladd = objcase.Vehicle_Location_Street__c.split(' ');
            }
            if(fulladd.size()>0 && fulladd[0].isNumeric()  && fulladd[0]!=null){
                breakdownAddress.streetNumber=fulladd[0];
                for(Integer i=1;i<=fulladd.size()-1;i++){
                    streetval=streetval+fulladd[i]+' ';
                    }
                    breakdownAddress.streetName= streetval;
            
            }
            else{
            breakdownAddress.streetName= objcase.Vehicle_Location_Street__c;
            }
            breakdownAddress.street =objcase.Vehicle_Location_Street__c;
            breakdownAddress.city = objcase.Vehicle_Location_City__c;
            breakdownAddress.state =mapStateValueCode.get(objcase.Vehicle_Location_State__c);
            breakdownAddress.postalCode =objcase.Vehicle_Location_Postal_Code__c;
            breakdownAddress.country = ACG_ConstantsClass.US;
            breakdownlocation.address = breakdownAddress;
            breakdownfoi.location = breakdownlocation;
            breakdownservicelocation.foi = breakdownfoi;
            breakdownservicelocation.driverDirections = objcase.ACG_Driving_Directions__c;
            lstservicelocations.add(breakdownservicelocation);
            if(objcase.Tow_Geolocation__Latitude__s!=null && objcase.Tow_Geolocation__Longitude__s!=null){
            FSL_CallMoverJSONRequest_Wrapper.ServiceLocations towservicelocation = new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations();
            towservicelocation.serviceLocationType=ACG_ConstantsClass.TOW_DESTINATION;
            FSL_CallMoverJSONRequest_Wrapper.Foi towfoi =  new FSL_CallMoverJSONRequest_Wrapper.Foi();
            towfoi.foiType = ACG_ConstantsClass.ADDRESS;
            FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location towlocation = new FSL_CallMoverJSONRequest_Wrapper.ServiceLocations_Location();
            towlocation.latitude = objcase.Tow_Geolocation__Latitude__s;
            towlocation.longitude = objcase.Tow_Geolocation__Longitude__s;
            FSL_CallMoverJSONRequest_Wrapper.Address towAddress = new FSL_CallMoverJSONRequest_Wrapper.Address();
            towAddress.addressType = ACG_ConstantsClass.PHYSICAL;
            towAddress.street =objcase.Tow_Destination_Street__c;
            string towstreetval=' ';
            //Added to split the address and update streetnumber
            list<string> towfulladd= new list<string>();
            if(objcase.Tow_Destination_Street__c!=null && objcase.Tow_Destination_Street__c!=''){
            towfulladd = objcase.Tow_Destination_Street__c.split(' ');
            }
            if(towfulladd.size()>0 && towfulladd[0].isNumeric()  && towfulladd[0]!=null){
                towAddress.streetNumber=towfulladd[0];
                for(Integer i=1;i<=towfulladd.size()-1;i++){
                    towstreetval=towstreetval+towfulladd[i]+' ';
                    }
                    towAddress.streetName= towstreetval;
            }
            else{
            towAddress.streetName= objcase.Tow_Destination_Street__c;
            }
            towAddress.city = objcase.Tow_Destination_City__c;
            towAddress.state =mapStateValueCode.get(objcase.Tow_Destination_State__c);
            towAddress.postalCode =objcase.Tow_Destination_Postal_Code__c;
            towAddress.country = ACG_ConstantsClass.US;
            towlocation.address = towAddress;
            towfoi.location = towlocation;
            towservicelocation.foi = towfoi;
            towservicelocation.driverDirections = objcase.ACG_Driving_Directions__c;
            lstservicelocations.add(towservicelocation);
            }
            service.serviceLocations = lstservicelocations;
            service.collision = objcase.ACG_Collision__c;
            service.needsFlatbed = objcase.Flatbed_Required__c;
            call.service = service;
            FSL_CallMoverJSONRequest_Wrapper.Payment payment = new FSL_CallMoverJSONRequest_Wrapper.Payment();
            payment.required = false;
            call.payment = payment;
            lstCalls.add(call);
            jsonWrapper.Calls = lstCalls;
            
            try{
                resp=callMoverCallout(jsonWrapper);
                resp.IdTcodePCC = IdTcodePCC;
                if(resp.isSuccess){
                    objCase.ERS_BypassStatusValidationforFlow__c = true;
                    objcase.status = ACG_ConstantsClass.NATIONAL_CLOSED_STATUS;
                    objcase.comments ='Status:'+resp.description +'\r\ncallKey:'+resp.callkey;
                } else{
                    Group gr=[select Id,Name from Group where Type =:ACG_ConstantsClass.QUEUE_STRING AND DeveloperNAME = :ACG_ConstantsClass.VIOLATION_HANDLERS];
                    objcase.comments = 'Status:'+resp.description;
                    objcase.OwnerId=gr.Id;
                }
                if(objcase!=null){
                    update objcase;
                }
            } catch (Exception e){
                String message = e.getStackTraceString()+e.getCause()+e.getLineNumber()+e.getMessage();
                FSL_ApplicationLogCreator.integrationLog (String.valueof(jsonWrapper),String.valueof(resp),'National Call Mover Outbound API','National Call Mover',true,message,null);
            }
        }
        return resp;
    } 
    
    public static Response_wrapper callMoverCallout(FSL_CallMoverJSONRequest_Wrapper jsonWrapper){
        string requestbody;
        string body;
        HttpRequest  objRequest = new HttpRequest();
        HttpResponse objResponse = new HttpResponse();
        HttpRequest  oauthobjRequest = new HttpRequest();
        HttpResponse oauthobjResponse = new HttpResponse();
        Integration_Settings__c objSetting=new Integration_Settings__c();
        Integration_Settings__c OAuthobjSetting=new Integration_Settings__c();
        Boolean isSuccess = false;
        Response_wrapper resp= new Response_wrapper();
        resp.isSuccess=false;
        try{
            requestbody = JSON.serialize(jsonWrapper);
            OAuthobjSetting = mapIntSettings.get('POSTNational_OAuth_API');
            body = OAuthobjSetting.Extra_Header_Value__c;
            OAuthobjSetting.Extra_Header_Value__c =null;
            oauthobjRequest = IntegrationUtil.prepareRequest(OAuthobjSetting);
            oauthobjRequest.setbody(body);
            oauthobjResponse = IntegrationUtil.makeCallout(oauthobjRequest);
            if(oauthobjResponse.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS){
            Map<string,object> mapofObjects = (Map<string,object>)JSON.deserializeUntyped(oauthobjResponse.getBody());
            objSetting = mapIntSettings.get('POSTCallMover_Outbound_API');
            objRequest = IntegrationUtil.prepareRequest(objSetting,jsonWrapper,true);
            objRequest.setHeader('Authorization','Bearer '+mapofObjects.get('access_token'));
            objResponse = IntegrationUtil.makeCallout(objRequest);
            if(objResponse.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS){
               resp.isSuccess = true;
               Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               resp.description = (string)results.get('statusDescription');
               Map<string,object> responepayload = (Map<String, Object>)results.get('responsePayload');
               resp.callKey =(string)responepayload.get('callKey');
               FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Call Mover Outbound API','National Call Mover',false,'',null);
            } else {
               Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               resp.description = (string)results.get('description');
               FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Call Mover Outbound API','National Call Mover',true,Label.ACG_APIErrorMessage +' : '+objResponse.getStatusCode()+' '+objResponse.getStatus(),null);
            }
            }else {
               FSL_ApplicationLogCreator.integrationLog(oauthobjRequest.getBody(),oauthobjResponse.getBody(),'National Call Mover Outbound API','National Call Mover',true,Label.ACG_APIErrorMessage +' : '+oauthobjResponse.getStatusCode()+' '+oauthobjResponse.getStatus(),null);
            }
       }
       catch(Exception e){
            String message = e.getStackTraceString()+e.getCause()+e.getLineNumber()+e.getMessage();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'National Call Mover Outbound API','National Call Mover',true,message,null);
        }
      return resp;  
    }
    
    public static case fetchcase(Id CaseId){
        case Objcase = [select id,createdDate,caseNumber,ACG_Vehicle_Location_Type__c,ACG_Make__c,ACG_Year__c,ACG_Color__c,ACG_Model__c,Appointment_Requested__c,
                        Member_Vehicle__r.Vehicle_Fuel_Type__c,Member_Vehicle__r.Vehicle_Drive_Type__c,BSP_Available__c,Club_Name__c,Enter_Home_during_Lockout__c,Flat_Tire_Status__c,
                        Member_Vehicle__r.Vehicle_Odometer__c,Member_Vehicle__r.Vehicle_Type__c,Member_Vehicle__r.Vehicle_Special_Equipment_Needs__c, Gross_Weight__c,Vehicle_Lockout_Reason__c,
                        Member_Vehicle__r.Vehicle_State__c, Member_Vehicle__r.Vehicle_Tag__c,ACG_Service_Type__c,Special_Equipment_Selection__c,Total_Mileage__c,
                        Member_Vehicle__r.Vehicle_Trim__c,Member_Vehicle__r.Vehicle_VIN__c,Account.FirstName,Account.Club_Code1__c,ACG_Drivetrain__c,Vehicle_Fuel_Type__c,Tow_Request_Reason__c,
                        Account.LastName,Account.phone,Account.ACG_SMS_Opt_In__c,Account.ACG_Primary_Phone_Type__c,Account.Phone_Extension__pc,
                        Account.PersonEmail,Account.Email_Type__pc,Account.ACG_AAA_Membership__c,Account.Membership_Type__pc,Account.ACG_Membership_Type__c,
                        Account.AAA_Membership_Level__c,Account.Membership_Expiration_Date__c,Account.ACG_Date_of_Birth__c,
                        Account.Membership_Since__pc,Account.Membership_Sponsor__pc,Account.Membership_Program__pc,Account.Membership_Code__pc,
                        Account.Membership_Authorization__pc,Account.Membership_IsLocalClub__pc,Account.ACG_Membership_Status__c,
                        Account.Membership_Org__pc,Account.Membership_Org_Phone__pc,Account.Membership_OrgCode__pc,ACG_Case_Contact_Number__c,
                        Account.ACG_Entitlements_Allotted__c,Account.ACG_Entitlements_Used__c,Account.ACG_ERS_Entitlements__c,Account.Club_Name1__c,ACG_SMS_Opt_In__c,
                        Call_Origin__c,Number_of_passengers__c,Member_Vehicle__r.Duty__c,Vehicle_Geolocation__Latitude__s,ACG_work_type__r.T_Code__C,ACG_work_type__r.Trouble_Code__C,
                        Vehicle_Geolocation__Longitude__s,ACG_Vehicle_Location_Address__c,Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,
                        Vehicle_Location_Postal_Code__c,ACG_Driving_Directions__c,Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,ERS_Event_Type__c,Account.Member_Club_Code__c,
                        ACG_Tow_Destination_Address__c,Tow_Destination_Street__c,Tow_Destination_City__c,Tow_Destination_State__c,Pacesetter_Code__c,T_Code__c,Account.Parent_Club_Name__c,
                        Tow_Destination_Postal_Code__c,ACG_Collision__c,Flatbed_Required__c,LastModifiedDate,Member_Vehicle_Type__c,Which_service_is_the_member_requesting__c,
                        FSL_Service_Type_Internal__c,Locksmith_Issue__c,Call_Source__c,Account.ACG_Club__c, Account.ACG_Club_Name__c from case where id=:CaseId];
        return Objcase;
    }
    
    public class Response_wrapper{
        public Boolean isSuccess;
        public String CallKey;
        public String description;
        public string[] IdTcodePCC;
    }
}