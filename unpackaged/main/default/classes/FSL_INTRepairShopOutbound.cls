/**** Apex Class Name    :    FSL_INTRepairShopOutbound
    * Description        :    API class  to inform about Repair Shop to national.
*********************************************************************************/
public without sharing class FSL_INTRepairShopOutbound {
 
    public static final Map<String,Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();
     
    public static Map<String, String> mapStateValueCode = new Map<String, String>();
    public static Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
    public static List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    public static Map<String, String> workOrderData = new Map<String, String>();
    public static final String SOURCE_SF = 'Salesforce';

    @Future (callout=true)
    public static void generateRepairShopRequest(Id CaseId, Id workOrderId){
        workOrderData = getWorkOrderData(workOrderId);
        if(workOrderData.get('callSource') == SOURCE_SF){
            case objcase = fetchcase(caseId);
            Map<string,string> mapofMemebershiplevels = new Map<string,string>();
            for(Membership_Type_Mapping__mdt membeshiptype:[SELECT Id,MasterLabel,Member_Level__c FROM Membership_Type_Mapping__mdt]){
                mapofMemebershiplevels.put(membeshiptype.MasterLabel,membeshiptype.Member_Level__c);
            }
            for(Schema.PicklistEntry f : ple) {
                    mapStateValueCode.put(f.getLabel(), f.getValue());
            }
            
            String[] IdTcodePCC;
            string pacesettercode= objcase.Pacesetter_Code__c;
            string T_Code = objcase.T_Code__c;
            
            if(!Test.isRunningTest()){
                IdTcodePCC =  (ERS_WorkOrderFromCase.getWorkTypeId(objcase)).split('#');
                pacesettercode = IdTcodePCC[2];
                T_Code = IdTcodePCC[1];
            }
            FSL_RepairShopJSONRequest_Wrapper jsonWrapper = new FSL_RepairShopJSONRequest_Wrapper();
            jsonWrapper.id=IntegrationUtil.generateUniqueId();
            jsonWrapper.requestEventType = ACG_ConstantsClass.CREATE;
            jsonWrapper.subType = ACG_ConstantsClass.CREATE;
            jsonWrapper.version = ACG_ConstantsClass.API_VERSION;
            jsonWrapper.status = 'RE';
            
            FSL_RepairShopJSONRequest_Wrapper.sourceSystem sourceSystem = new FSL_RepairShopJSONRequest_Wrapper.sourceSystem();
            FSL_RepairShopJSONRequest_Wrapper.systemOrganization soruceSystemOrg = new FSL_RepairShopJSONRequest_Wrapper.systemOrganization();
            sourceSystem.systemId = Label.FSL_SourceClubCode;
            soruceSystemOrg.code = Label.FSL_SourceClubCode;
            soruceSystemOrg.name = Label.Club_Name;
            sourcesystem.systemOrganization = soruceSystemOrg;
            
            FSL_RepairShopJSONRequest_Wrapper.sourceSystem targetSystem = new FSL_RepairShopJSONRequest_Wrapper.sourceSystem();
            FSL_RepairShopJSONRequest_Wrapper.systemOrganization targetSystemOrg = new FSL_RepairShopJSONRequest_Wrapper.systemOrganization();
            targetSystem.systemId = ACG_ConstantsClass.CI; 
            targetSystemOrg.code = ACG_ConstantsClass.NaTIONAL_CLUBCODE;
            targetSystemOrg.name = ACG_ConstantsClass.CI;
            
            targetSystem.systemOrganization = targetSystemOrg;
            jsonWrapper.SourceSystem =sourcesystem;
            jsonWrapper.targetSystem = targetSystem;
            jsonWrapper.createDate = objcase.createdDate.getTime();
            
            List<FSL_RepairShopJSONRequest_Wrapper.Calls> lstCalls = new List<FSL_RepairShopJSONRequest_Wrapper.Calls>(); 
            FSL_RepairShopJSONRequest_Wrapper.Calls call = new FSL_RepairShopJSONRequest_Wrapper.Calls();
            
            string strDay;
            strDay =objcase.createdDate.day()<10?'0'+String.valueof(objcase.createdDate.day()):String.valueof(objcase.createdDate.day());
            string strMonth;
            strMonth =objcase.createdDate.month()<10?'0'+String.valueof(objcase.createdDate.month()):String.valueof(objcase.createdDate.month());
            String workOrderNumber = workOrderData.get('workOrderNumber');
            call.callKey = Label.FSL_SourceClubCode +'-'+String.valueof(objcase.createdDate.Year())+strMonth+strDay+'-'+workOrderNumber; //objcase.CaseNumber;
            call.callDate =objcase.createdDate.format('yyyy-MM-dd');//EMI-12-30-2024--updated for the year 2025 issue.
            call.callId = workOrderNumber; //objcase.CaseNumber;
            call.requestingSystemCallId = workOrderNumber;
            call.version = ACG_ConstantsClass.API_SUBVERSION;
            FSL_RepairShopJSONRequest_Wrapper.Channel channel = new FSL_RepairShopJSONRequest_Wrapper.Channel();
            channel.channelType = objcase.call_origin__c ==ACG_ConstantsClass.IVR || objcase.call_origin__c == ACG_ConstantsClass.CASE_EVENT_TYPE_RAP
                                ? objcase.call_origin__c : ACG_ConstantsClass.CALL_CENTER;
            channel.org = soruceSystemOrg;
            FSL_RepairShopJSONRequest_Wrapper.Contact contact = new FSL_RepairShopJSONRequest_Wrapper.Contact();
            contact.userId ='';
            contact.contactType = ACG_ConstantsClass.CAPAGENT;
            channel.contact = contact;
            call.channel = channel;
            
            FSL_RepairShopJSONRequest_Wrapper.vehicle vehicle = new FSL_RepairShopJSONRequest_Wrapper.vehicle();
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
            FSL_RepairShopJSONRequest_Wrapper.Customer customer = new FSL_RepairShopJSONRequest_Wrapper.Customer();
            customer.languagePreference =ACG_ConstantsClass.EN;
            FSL_RepairShopJSONRequest_Wrapper.Contact_customer customerContact = new FSL_RepairShopJSONRequest_Wrapper.Contact_customer();
            customerContact.contactType = ACG_ConstantsClass.CAPCUSTOMER;
            customerContact.firstName = objcase.Account.FirstName;
            customerContact.LastName = objcase.Account.LastName;
            List<FSL_RepairShopJSONRequest_Wrapper.Phones> lstphones = new List<FSL_RepairShopJSONRequest_Wrapper.Phones>();
            FSL_RepairShopJSONRequest_Wrapper.Phones phone = new FSL_RepairShopJSONRequest_Wrapper.Phones();
            List<FSL_RepairShopJSONRequest_Wrapper.Emails> lstemails = new List<FSL_RepairShopJSONRequest_Wrapper.Emails>();
            FSL_RepairShopJSONRequest_Wrapper.Emails email = new FSL_RepairShopJSONRequest_Wrapper.Emails();
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
            List<FSL_RepairShopJSONRequest_Wrapper.Memberships> lstMemberships = new List<FSL_RepairShopJSONRequest_Wrapper.Memberships>();
            FSL_RepairShopJSONRequest_Wrapper.Memberships membership = new FSL_RepairShopJSONRequest_Wrapper.Memberships();
            List<FSL_RepairShopJSONRequest_Wrapper.Entitlements> lstEntitlements = new List<FSL_RepairShopJSONRequest_Wrapper.Entitlements>();
            FSL_RepairShopJSONRequest_Wrapper.Entitlements Entitlements = new FSL_RepairShopJSONRequest_Wrapper.Entitlements();
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
            FSL_RepairShopJSONRequest_Wrapper.systemOrganization membershipOrg = new FSL_RepairShopJSONRequest_Wrapper.systemOrganization();
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
            FSL_RepairShopJSONRequest_Wrapper.Service service = new FSL_RepairShopJSONRequest_Wrapper.service();
            service.callType =  objcase.ERS_Event_Type__c ==ACG_ConstantsClass.CASE_EVENT_TYPE_RAP?objcase.ERS_Event_Type__c:ACG_ConstantsClass.MEMBER;
            service.numberOfPassengers = objcase.Number_of_passengers__c!=null?Integer.valueof(objcase.Number_of_passengers__c):null;
            service.duty = objcase.Member_Vehicle__r.Duty__c;
            // New -> Add TimeZone
            /*String tzId;
            List<Double> latLong = new List<Double>();
            latLong.add(objcase.Vehicle_Geolocation__Latitude__s);
            latLong.add(objcase.Vehicle_Geolocation__Longitude__s);
            tzId = INTSADAGeoMapAPI.getTimezoneFromBing ( latLong );
            INTSADAGeoMapAPI.BingResponse rs = (INTSADAGeoMapAPI.BingResponse) JSON.deserialize ( tzId, INTSADAGeoMapAPI.BingResponse.class );
                        if(rs != null && rs.resourceSets.size() > 0) {
                            service.timezoneId = rs.resourceSets.get(0).resources.get(0).timeZone.abbreviation;
                        }
                        if(rs != null && rs.resourceSets.size() > 0) {
                            service.timezoneOffset = rs.resourceSets.get(0).resources.get(0).timeZone.abbreviation
                                                    +  rs.resourceSets.get(0).resources.get(0).timeZone.utcOffset;
                        }  */                      
            service.timezoneId = '';
            service.timezoneOffset = '';
            FSL_RepairShopJSONRequest_Wrapper.Status status = new FSL_RepairShopJSONRequest_Wrapper.Status();
            status.status =ACG_ConstantsClass.SP;
            status.updateCode = ACG_ConstantsClass.SP;
            status.modifiedDate = objcase.LastModifiedDate;
            service.status = status;
            
            List<FSL_RepairShopJSONRequest_Wrapper.TroubleCodes> lsttroublecodes = new List<FSL_RepairShopJSONRequest_Wrapper.TroubleCodes>();
            FSL_RepairShopJSONRequest_Wrapper.TroubleCodes troublecodes = new FSL_RepairShopJSONRequest_Wrapper.TroubleCodes();
            troublecodes.troubleCodeType = ACG_ConstantsClass.PACESETTER;
            troublecodes.code = pacesettercode!=null?pacesettercode:objcase.ACG_work_type__r.Trouble_Code__C;
            troublecodes.description = '';
            if(troublecodes.code!=null)
            lsttroublecodes.add(troublecodes);
            FSL_RepairShopJSONRequest_Wrapper.TroubleCodes troublecodes1 = new FSL_RepairShopJSONRequest_Wrapper.TroubleCodes();
            troublecodes1.troubleCodeType = ACG_ConstantsClass.PROBLEM;
            troublecodes1.code = T_Code!=null?T_Code:objcase.ACG_work_type__r.T_Code__C;
            troublecodes1.description = '';
            if(troublecodes1!=null)
            lsttroublecodes.add(troublecodes1);
            service.troubleCodes = lsttroublecodes;
            List<FSL_RepairShopJSONRequest_Wrapper.ServiceLocations> lstservicelocations = new List<FSL_RepairShopJSONRequest_Wrapper.ServiceLocations>();
            FSL_RepairShopJSONRequest_Wrapper.ServiceLocations breakdownservicelocation = new FSL_RepairShopJSONRequest_Wrapper.ServiceLocations();
            breakdownservicelocation.serviceLocationType=ACG_ConstantsClass.BREAKDOWN;
            FSL_RepairShopJSONRequest_Wrapper.Foi breakdownfoi =  new FSL_RepairShopJSONRequest_Wrapper.Foi();
            breakdownfoi.foiType = ACG_ConstantsClass.ADDRESS;
            FSL_RepairShopJSONRequest_Wrapper.ServiceLocations_Location breakdownlocation = new FSL_RepairShopJSONRequest_Wrapper.ServiceLocations_Location();
            breakdownlocation.latitude = objcase.Vehicle_Geolocation__Latitude__s;
            breakdownlocation.longitude = objcase.Vehicle_Geolocation__Longitude__s;
            FSL_RepairShopJSONRequest_Wrapper.Address breakdownAddress = new FSL_RepairShopJSONRequest_Wrapper.Address();
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
            if(String.isEmpty(objcase.Vehicle_Location_Street__c) && objcase.ACG_Vehicle_Location_Address__c != null){
                breakdownAddress.street = objcase.ACG_Vehicle_Location_Address__c.substringBefore(',');
            }
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
            FSL_RepairShopJSONRequest_Wrapper.ServiceLocations towservicelocation = new FSL_RepairShopJSONRequest_Wrapper.ServiceLocations();
            towservicelocation.serviceLocationType=ACG_ConstantsClass.TOW_DESTINATION;
            FSL_RepairShopJSONRequest_Wrapper.Foi towfoi =  new FSL_RepairShopJSONRequest_Wrapper.Foi();
            if(objcase.Repair_Shop__c != null){
                towfoi.foiType = ACG_ConstantsClass.AAR;
            }else{
                towfoi.foiType = ACG_ConstantsClass.ADDRESS;
            }
            
            towfoi.id = objcase.Repair_Shop__r.Integration_Id__c;
            FSL_RepairShopJSONRequest_Wrapper.ServiceLocations_Location towlocation = new FSL_RepairShopJSONRequest_Wrapper.ServiceLocations_Location();
            towlocation.latitude = objcase.Tow_Geolocation__Latitude__s;
            towlocation.longitude = objcase.Tow_Geolocation__Longitude__s;
            FSL_RepairShopJSONRequest_Wrapper.Address towAddress = new FSL_RepairShopJSONRequest_Wrapper.Address();
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
        
            FSL_RepairShopJSONRequest_Wrapper.Payment payment = new FSL_RepairShopJSONRequest_Wrapper.Payment();
            payment.required = false;
            call.payment = payment;
            lstCalls.add(call);
            jsonWrapper.Calls = lstCalls;
            Response_wrapper resp = new Response_wrapper();
            try{
                //actual callout
                resp = callRepairShopCallout(jsonWrapper);
                //resp.IdTcodePCC = IdTcodePCC;
                //if(resp.isSuccess){
                    system.debug('Successfully Sent Data to National');
                    //objCase.ERS_BypassStatusValidationforFlow__c = true;
                    //objcase.status = ACG_ConstantsClass.NATIONAL_CLOSED_STATUS;
                    //objcase.comments ='Status:'+resp.description +'\r\ncallKey:'+resp.callkey;
                //} else{
                    //Group gr=[select Id,Name from Group where Type =:ACG_ConstantsClass.QUEUE_STRING AND DeveloperNAME = :ACG_ConstantsClass.VIOLATION_HANDLERS];
                    //objcase.comments = 'Status:'+resp.description;
                    //objcase.OwnerId=gr.Id;
                //}
                //if(objcase!=null){
                    //update objcase;
                //}
            } catch (Exception e){
                String message = e.getStackTraceString()+e.getCause()+e.getLineNumber()+e.getMessage();
                FSL_ApplicationLogCreator.integrationLog (String.valueof(jsonWrapper),String.valueof(resp),'National Repair Shop Outbound API - Excepion API','National Repair Shop',true,message,null);
            }
            //return resp;
        }
    } 
    
    public static Response_wrapper callRepairShopCallout(FSL_RepairShopJSONRequest_Wrapper jsonWrapper){
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
            system.debug('**** jsonWrapper' + jsonWrapper);
            requestbody = JSON.serialize(jsonWrapper);
            OAuthobjSetting = mapIntSettings.get('POSTNational_OAuth_API');
            body = OAuthobjSetting.Extra_Header_Value__c;
            OAuthobjSetting.Extra_Header_Value__c =null;
            oauthobjRequest = IntegrationUtil.prepareRequest(OAuthobjSetting);
            oauthobjRequest.setbody(body);
            oauthobjResponse = IntegrationUtil.makeCallout(oauthobjRequest);
            system.debug('**** oauthobjResponse' + oauthobjResponse.getBody());
            if(oauthobjResponse.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS){
                Map<string,object> mapofObjects = (Map<string,object>)JSON.deserializeUntyped(oauthobjResponse.getBody());
                objSetting = mapIntSettings.get('POSTRepairShop_Outbound_API');
                objRequest = IntegrationUtil.prepareRequest(objSetting,jsonWrapper,true);
                objRequest.setHeader('Authorization','Bearer '+mapofObjects.get('access_token'));
                
                objResponse = IntegrationUtil.makeCallout(objRequest);
                system.debug('**** objResponse' + objResponse.getBody());
                system.debug('**** objResponseStatusCode' + objResponse.getStatusCode() + ACG_ConstantsClass.STATUS_CODE_SUCCESS);
            if(objResponse.getStatusCode()==ACG_ConstantsClass.STATUS_CODE_SUCCESS){
                resp = (Response_wrapper)JSON.deserialize(objResponse.getBody(), Response_wrapper.class);
               //Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               //resp.description = (string)results.get('statusDescription');
               //Map<string,object> responepayload = (Map<String, Object>)results.get('responsePayload');
               //resp.callKey =(string)responepayload.get('callKey');
               FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Repair Shop Outbound API - Success','National Repair Shop',false,'',null);
            } else {
               //Map<string,object> results =  (Map<String, Object>)JSON.deserializeUntyped(objResponse.getBody());
               //resp.description = (string)results.get('description');
                resp = (Response_wrapper)JSON.deserialize(objResponse.getBody(), Response_wrapper.class);
                FSL_ApplicationLogCreator.integrationLog(objRequest.getBody(),objResponse.getBody(),'National Repair Shop Outbound API - Error','National Repair Shop',true,Label.ACG_APIErrorMessage +' : '+objResponse.getStatusCode()+' '+objResponse.getStatus(),null);
            }
            }else {
               
               FSL_ApplicationLogCreator.integrationLog(oauthobjRequest.getBody(),oauthobjResponse.getBody(),'National Repair Shop Outbound API - Authorization Error','National Repair Shop',true,Label.ACG_APIErrorMessage +' : '+oauthobjResponse.getStatusCode()+' '+oauthobjResponse.getStatus(),null);
            }
       }
       catch(Exception e){
            String message = e.getStackTraceString()+e.getCause()+e.getLineNumber()+e.getMessage();
            FSL_ApplicationLogCreator.integrationLog (objRequest.getBody(),objResponse.getBody(),'National Repair Shop Outbound API - Exception','National Repair Shop',true,message,null);
        }
      return resp;  
    }
    
    public static case fetchcase(Id CaseId){
        case Objcase = [select id,createdDate,Which_service_is_the_member_requesting__c,FSL_Service_Type_Internal__c,Locksmith_Issue__c, caseNumber,ACG_Vehicle_Location_Type__c,ACG_Make__c,ACG_Year__c,ACG_Color__c,ACG_Model__c,Appointment_Requested__c,
                        Member_Vehicle__r.Vehicle_Fuel_Type__c,Member_Vehicle__r.Vehicle_Drive_Type__c,BSP_Available__c,Club_Name__c,Enter_Home_during_Lockout__c,Flat_Tire_Status__c,
                        Member_Vehicle__r.Vehicle_Odometer__c,Member_Vehicle__r.Vehicle_Type__c,Member_Vehicle__r.Vehicle_Special_Equipment_Needs__c, Gross_Weight__c,Vehicle_Lockout_Reason__c,
                        Member_Vehicle__r.Vehicle_State__c, Member_Vehicle__r.Vehicle_Tag__c,ACG_Service_Type__c,Special_Equipment_Selection__c,Total_Mileage__c,
                        Member_Vehicle__r.Vehicle_Trim__c,Member_Vehicle__r.Vehicle_VIN__c,Account.FirstName,Account.Club_Code1__c,ACG_Drivetrain__c,Vehicle_Fuel_Type__c,Tow_Request_Reason__c,
                        Account.LastName,Account.phone,Account.ACG_SMS_Opt_In__c,Account.ACG_Primary_Phone_Type__c,Account.Phone_Extension__pc,
                        Account.PersonEmail,Account.Email_Type__pc,Account.ACG_AAA_Membership__c,Account.Membership_Type__pc,Account.ACG_Membership_Type__c,
                        Account.AAA_Membership_Level__c,Account.Membership_Expiration_Date__c,Account.ACG_Date_of_Birth__c,Repair_Shop__r.Integration_Id__c,
                        Account.Membership_Since__pc,Account.Membership_Sponsor__pc,Account.Membership_Program__pc,Account.Membership_Code__pc,
                        Account.Membership_Authorization__pc,Account.Membership_IsLocalClub__pc,Account.ACG_Membership_Status__c,Account.ACG_Club__c,Account.ACG_Club_Name__c,
                        Account.Membership_Org__pc,Account.Membership_Org_Phone__pc,Account.Membership_OrgCode__pc,ACG_Case_Contact_Number__c,
                        Account.ACG_Entitlements_Allotted__c,Account.ACG_Entitlements_Used__c,Account.ACG_ERS_Entitlements__c,Account.Club_Name1__c,ACG_SMS_Opt_In__c,
                        Call_Origin__c,Number_of_passengers__c,Member_Vehicle__r.Duty__c,Vehicle_Geolocation__Latitude__s,ACG_work_type__r.T_Code__C,ACG_work_type__r.Trouble_Code__C,
                        Vehicle_Geolocation__Longitude__s,ACG_Vehicle_Location_Address__c,Vehicle_Location_Street__c,Vehicle_Location_City__c,Vehicle_Location_State__c,
                        Vehicle_Location_Postal_Code__c,ACG_Driving_Directions__c,Tow_Geolocation__Latitude__s,Tow_Geolocation__Longitude__s,ERS_Event_Type__c,Account.Member_Club_Code__c,
                        ACG_Tow_Destination_Address__c,Tow_Destination_Street__c,Tow_Destination_City__c,Tow_Destination_State__c,Pacesetter_Code__c,T_Code__c,Account.Parent_Club_Name__c,
                        Tow_Destination_Postal_Code__c,ACG_Collision__c,Flatbed_Required__c,LastModifiedDate,Member_Vehicle_Type__c from case where id=:CaseId];
        return Objcase;
    }

    private static Map<String, String> getWorkOrderData(String workOrderId){
            List<WorkOrder> wo = [select Id,WorkOrderNumber,Call_Source__c from WorkOrder where Id=:workOrderId];
            if(wo.size() > 0){
                workOrderData.put('workOrderNumber',wo[0].WorkOrderNumber);
                workOrderData.put('callSource',wo[0].Call_Source__c);
            }
            return workOrderData;
    }
    
    public class Response_wrapper_old{
        public Boolean isSuccess;
        public String CallKey;
        public String description;
        public string[] IdTcodePCC;
    }
    //{"statusCode":200,"description":"Success","data":{"statusCode":200,"code":"E200","message":"success"}}
    public class Response_wrapper{
        public Boolean isSuccess; //True 
        public String statusCode; //200
        public String description; //Success
        public ResponseStructure data;
    }
    
    public class ResponseStructure{
        public String statusCode; //200
        public String code; //E200
        public String message; //success
    }
    
}