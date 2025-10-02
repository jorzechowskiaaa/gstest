/**** Apex Class Name    :    INTNationalRBPAPI
    * Description        :    This class is used to make callouts to National for RAP close
    * Modification Log   :    JUN 18 2024 
    * Test Class Name    :    INTNationalRBPAPI_Test
    * ---------------------------------------------------------------------------
    * Developer                   Date                   Description
    * ---------------------------------------------------------------------------
    * Dhruv Javiya               OCT 29 2021             Created
    * Josh Tupas                 JUN 18 2024             PR893288-4453
*********************************************************************************/
public without sharing class INTNationalRBPAPI {
    // Get Configuration
    public static Map<String, Integration_Settings__c> mapIntSettings = IntegrationUtil.getIntegrationSettings();
    
    public static Map<String, Object> sendToStatusToRBP(INTNationalRBPAPIRequest_Wrapper req, Integration_Settings__c currIntegrStg) {
        INTNationalRBPAPIResponse_Wrapper objWrapper = new INTNationalRBPAPIResponse_Wrapper();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Map<String, Object> accTokenMap = new Map<String, Object>();
        Integration_Settings__c objSetting;
        String accessToken;
        String url;

        try {
            String callKey = req.callKey;  

            accTokenMap = getAccessTokenFromNational();
            accessToken = (String) accTokenMap.get('accToken');

            if (accessToken == null || callKey == null) {
                return null;
            } 

            // Get Metadata Configuration
            objSetting = currIntegrStg;

            if (objSetting == null) {
                objSetting = [
                    SELECT
                        Id, 
                        Enpoint_URL__c, 
                        Method__c, 
                        Header_Value__c, 
                        Named_Credential__c
                    FROM Integration_Settings__c
                    WHERE Method__c = 'POST'
                    AND Name = 'NationalRBP_API'
                ];
            }
            
            // set paramter
            if (objSetting.Enpoint_URL__c != null) {
                url = objSetting.Enpoint_URL__c;
                url += '/' + callKey;
            }

            String reqBody = JSON.serialize(req, true);
            
            // Replace Systems with system
            reqBody = reqBody.replaceAll('systems', 'system'); 

            request.setEndpoint(url);
            request.setMethod(objSetting.Method__c);
            request.setHeader(ACG_ConstantsClass.TRANSACTION_ID, IntegrationUtil.generateuniqueId());
            request.setHeader('Authorization', 'Bearer ' + accessToken); 
            request.setHeader('Content-Type', 'application/json'); 
            request.setTimeout(30000);
            request.setBody(reqBody);
            
            response = IntegrationUtil.makecallout(request);        
        } catch (Exception e) {
            throw e; 
        } 

        return new Map<String, Object>{
            'req' => request,
            'resp' => response,
            'oAuthReq' => accTokenMap.get('oAuthReq'),
            'oAuthRes' => accTokenMap.get('oAuthRes'),
            'integrStg' => objSetting
        };
    }  

    public static Map<String, Object> createrbprquest(Set<Id> WOId) {
        List<INTNationalRBPAPIRequest_Wrapper> lstrbprequest = new List<INTNationalRBPAPIRequest_Wrapper>();
        Map<Id, List<WorkOrderHistory>> WorkOrderWiseHistory = new Map<Id, List<WorkOrderHistory>>();
        Map<String, Object> resMap = new Map<String, Object>();
        Map<Id, List<FeedItem>> WorkOrderWiseFeeds = new Map<Id, List<FeedItem>>();
        List<FeedItem> fiList = [
            SELECT 
                Id,
                Visibility,
                InsertedBy.Name,
                LastModifiedDate,
                ParentId,
                Type,
                Body 
            FROM FeedItem 
            WHERE ParentId = :WOId 
            AND TYPE = :ACG_ConstantsClass.TEXT_POST
        ];

        for (FeedItem feedItems : fiList) {
            if (!WorkOrderWiseFeeds.containsKey(feedItems.ParentId)) {
                WorkOrderWiseFeeds.put(feedItems.ParentId,new List<FeedItem>());
            }

            WorkOrderWiseFeeds.get(feedItems.ParentId).add(feedItems);
        }

        Map<String, String> unitMap = new Map<String, String>(); 
        List<AggregateResult> unitOFMeasureForProduct = [     
            SELECT  
               Product__r.ProductCode,
               Unit_of_Measure__c , 
               count(id) 
            FROM Rate_Line_Item__c 
            where Unit_of_Measure__c != '' 
            group by Product__r.ProductCode,Unit_of_Measure__c
        ];
        for(AggregateResult aggResult : unitOFMeasureForProduct)
        {
            unitMap.put(String.valueOf(aggResult.get('ProductCode')), String.valueOf(aggResult.get('Unit_of_Measure__c')));           
        }
        List<WorkOrder> woList = [
            SELECT 
                Id,
                Call_Id__c,
                WorkOrderNumber,
                Member_Account__r.PersonEmail,
                Program_Description__c,
                Call_Date__c,
                RAP_Case_Number__c,
                Member_Account__r.Member_Club_Code__c,
                Member_Account__r.club_code__c,
                Member_Account__r.Email_Type__pc,
                Member_Account__r.Phone_Extension__pc,
                Member_Account__r.Phone,
                Member_Account__r.PersonMobilePhone,
                Member_Account__r.Fax,
                Member_Account__r.Phone_Type__pc,
                Member_Account__r.PersonHomePhone,
                Member_Account__r.LastName,
                Member_Account__r.FirstName,
                Member_Account__r.PersonTitle,
                Member_Account__r.Type__pc,
                Member_Account__r.Type,
                Wait_Time__c,
                Pta__c,
                InitialETA_Legacy__c,
                External_ID__c,
                ServiceTerritory.Timezone__c,
                Canceled_Timestamp__c,
                Cleared_Timestamp__c,
                Dispatched_Timestamp__c,
                Enroute_Timestamp__c,
                In_Tow_Timestamp__c,
                On_Location_Timestamp__c,
                Spotted_Timestamp__c, 
                (
                    SELECT 
                        Id,
                        Quantity,
                        UnitPrice,
                        TotalPrice,
                        PriceBookEntry.Product2.Service_Type__c,
                        PriceBookEntry.Product2.ProductCode,
                        WorkType.Name 
                    FROM WorkOrderLineItems
                ), 
                (
                    SELECT 
                        Id,
                        Product_Code__c,
                        Trouble_Code__c,
                        Unit__c,
                        Total_Price__c,
                        Charge_to_Account__c
                    FROM Service_Line_Items__r 
                    WHERE Product_Code__c != null
                    AND Trouble_Code__c != null
                )
            FROM WorkOrder 
            WHERE Id = :WOId
        ];

        for (WorkOrder wo : woList) {
            INTNationalRBPAPIRequest_Wrapper req = new INTNationalRBPAPIRequest_Wrapper();
            String mbrClubCode = wo.Member_Account__r.Club_Code__c;
            Date currDate = Date.today();
            Integer currYear = currDate.year();
            Integer currMonth = currDate.month();
            Integer currDay = currDate.day();

            req.providedService = new List<INTNationalRBPAPIRequest_Wrapper.providedService>();
            req.callKey = mbrClubCode + '-';
            req.callKey += wo.Call_Date__c?.replace('-', '') ?? ('' + currYear + currMonth + currDay);
            req.callKey += '-0-' + wo.RAP_Case_Number__c;
            req.cdmCallKey = wo.External_ID__c;

            for (FSL_Service_Line_Item__c eachSLI : wo.Service_Line_Items__r) {
                String tCode = eachSLI.Trouble_Code__c;
                
                if (tCode != '9A') {
                    req.providedService.add(prepSLIForRBP(new Map<String, Object>{
                        'sli' => eachSLI,
                        'unitMap' => unitMap,
                        'tCode' => tCode
                    })); 
                }
            }   
            
            req.status = new List<INTNationalRBPAPIRequest_Wrapper.Status>();
            
            Map<String, String> statusMap = new Map<String, String>{
                'Spotted_Timestamp__c' => 'SP',
                'Dispatched_Timestamp__c' => 'DI',
                'Enroute_Timestamp__c' => 'ER',
                'On_Location_Timestamp__c' => 'OL',
                'In_Tow_Timestamp__c' => 'TW',
                'Cleared_Timestamp__c' => 'CL',
                'Canceled_Timestamp__c' => 'CA'
            };

            for (String timestampField : statusMap.keySet()) {
                INTNationalRBPAPIRequest_Wrapper.Status status = new INTNationalRBPAPIRequest_Wrapper.Status();
                Datetime woDTField = (Datetime) wo.get(timestampField);
                String dtFormat = 'yyyy-MM-dd HH:mm:ss';
                String facTimeZone = wo.ServiceTerritory?.Timezone__c;

                if (woDTField != null && facTimeZone != null) {
                    String modifiedDate = woDTField.format(dtFormat, facTimeZone);

                    status.status = statusMap.get(timestampField);
                    status.modifiedDate = modifiedDate.replace(' ', 'T') + 'Z'; 
                    req.status.add(status);
                }
            }

            //populateCommentsOnCallData
            req.comments = new List<INTNationalRBPAPIRequest_Wrapper.comment>();

            if (WorkOrderWiseFeeds.containsKey(wo.Id)) {
                for (FeedItem feed : WorkOrderWiseFeeds.get(wo.Id)) {
                    INTNationalRBPAPIRequest_Wrapper.comment comment = new INTNationalRBPAPIRequest_Wrapper.comment();
                    String gmtString = String.valueofGMT(feed.LastModifiedDate);

                    if (String.isNotBlank(gmtString)) {            
                        DateTime dt = convertToGMT(feed.LastModifiedDate);    

                        comment.commentDate = String.valueofGMT(dt).replace(' ', 'T') + 'Z';
                    }

                    comment.commentType = ACG_ConstantsClass.NORMAL;
                    comment.visibility = feed.Visibility == ACG_ConstantsClass.ALLUSERS ? 
                        ACG_ConstantsClass.EXTERNAL : ACG_ConstantsClass.INTERNAL;
                    comment.text = feed.Body.stripHtmlTags();
                    
                    comment.systems = new INTNationalRBPAPIRequest_Wrapper.SystemClass();
                    comment.systems.systemId = '';
                    comment.systems.systemOrganization = new INTNationalRBPAPIRequest_Wrapper.SystemOrganziation();
                    comment.systems.systemOrganization.name = ACG_ConstantsClass.SALESFORCE;
                    comment.systems.systemOrganization.code = ACG_ConstantsClass.SYSTEM_ORG_CODE;
                    
                    comment.contact = new INTNationalRBPAPIRequest_Wrapper.Contact();
                    comment.contact.contactType = wo.Member_Account__r.Type != null ? 
                        wo.Member_Account__r.Type.ToUpperCase() : ACG_ConstantsClass.CAPCUSTOMER; 
                    comment.contact.firstName = wo.Member_Account__r.FirstName;
                    comment.contact.middleName = '';
                    comment.contact.lastName = wo.Member_Account__r.LastName;
                    comment.contact.suffix = '';
                    
                    comment.contact.phones= new List<INTNationalRBPAPIRequest_Wrapper.Phone>();
                    
                    if (wo.Member_Account__r.Phone != null) {
                        INTNationalRBPAPIRequest_Wrapper.Phone phone = new INTNationalRBPAPIRequest_Wrapper.Phone();
                        phone.phoneType = ACG_ConstantsClass.CELLULAR;
                        phone.phoneNumber = wo.Member_Account__r.Phone;
                        comment.contact.phones.add(phone);
                    }
                    if (wo.Member_Account__r.PersonHomePhone != null) {
                        INTNationalRBPAPIRequest_Wrapper.Phone phone = new INTNationalRBPAPIRequest_Wrapper.Phone();
                        phone.phoneType = ACG_ConstantsClass.HOME;
                        phone.phoneNumber = wo.Member_Account__r.PersonHomePhone;
                        comment.contact.phones.add(phone);
                    }
                    if (wo.Member_Account__r.PersonMobilePhone != null) {
                        INTNationalRBPAPIRequest_Wrapper.Phone phone = new INTNationalRBPAPIRequest_Wrapper.Phone();
                        phone.phoneType = ACG_ConstantsClass.BUSINESS;
                        phone.phoneNumber = wo.Member_Account__r.PersonMobilePhone;
                        comment.contact.phones.add(phone);
                    }
                    if (wo.Member_Account__r.Fax != null) {
                        INTNationalRBPAPIRequest_Wrapper.Phone phone = new INTNationalRBPAPIRequest_Wrapper.Phone();
                        phone.phoneType = ACG_ConstantsClass.FAX;
                        phone.phoneNumber = wo.Member_Account__r.Fax;
                        comment.contact.phones.add(phone);
                    }
                    
                    comment.contact.emails = new List<INTNationalRBPAPIRequest_Wrapper.email>();

                    if (wo.Member_Account__r.PersonEmail != null) {
                        String emailType = wo.Member_Account__r.Email_Type__pc;
                        INTNationalRBPAPIRequest_Wrapper.email email = new INTNationalRBPAPIRequest_Wrapper.email();
                        email.emailType = emailType != null ? emailType.toUpperCase() : ACG_ConstantsClass.PERSONAL;
                        email.address = wo.Member_Account__r.PersonEmail;
                        email.optIn = false;
                        comment.contact.emails.add(email);
                    }
                    
                    req.comments.add(comment);
                }
            }

            lstrbprequest.add(req);
            resMap.put('lstRBPReq', lstrbprequest);

            List<Map<String, Object>> tempList = (List<Map<String, Object>>) resMap.get('woWithReqList');
            Map<String, Object> rbpDataMap = new Map<String, Object>{
                'woId' => wo.Id,
                'req' => req
            };

            if (tempList == null) {
                tempList = new List<Map<String, Object>>{rbpDataMap};
            } else {
                tempList.add(rbpDataMap);
            }

            resMap.put('woWithReqList', tempList);
        }

        return resMap;
    }

    private static Map<String, Object> getAccessTokenFromNational() {
        if (Test.isRunningTest()) {
            return new Map<String, Object>{
                'accToken' => '1234'
            };
        }

        HttpRequest  oauthobjRequest = new HttpRequest();
        HttpResponse oauthobjResponse = new HttpResponse();

        try {
            // Integration_Settings__c oAuthobjSetting = mapIntSettings.get(ACG_ConstantsClass.POSTNATIOANLOAUTH_API);
            Integration_Settings__c oAuthobjSetting = [
                SELECT 
                    Id, 
                    Name,
                    Enpoint_URL__c,
                    Method__c,
                    Header_Value__c,
                    Extra_Header_Value__c,
                    Named_Credential__c,
                    Request_Timeout__c, 
                    Path__c,
                    API_Key__c,
                    locationbias__c
                FROM Integration_Settings__c
                WHERE Method__c = 'POST'
                AND Name = 'National_OAuth_API'
            ];
            String body = oAuthobjSetting.Extra_Header_Value__c;

            oAuthobjSetting.Extra_Header_Value__c = null;
            oauthobjRequest = IntegrationUtil.prepareRequest(oAuthobjSetting);
            oauthobjRequest.setbody(body);
            oauthobjResponse = IntegrationUtil.makeCallout(oauthobjRequest);
    
            if (oauthobjResponse.getStatusCode() == 200) {
                Map<String, Object> mapofObjects = (Map<String, Object>) JSON.deserializeUntyped(oauthobjResponse.getBody());
                
                return new Map<String, Object>{
                    'oAuthReq' => oauthobjRequest.getBody(),
                    'oAuthRes' => JSON.serializePretty(JSON.deserializeUntyped(oauthobjResponse.getBody())),
                    'accToken' => (String) mapofObjects.get('access_token')
                };
            }
        } catch (Exception e) {
            handleException(e);
        }

        return null;
    }

    public static DateTime convertToGMT(DateTime dt) { 
        if (dt != null) {
            return DateTime.newInstanceGmt(
                dt.yearGMT(), 
                dt.monthGMT(), 
                dt.dayGMT(), 
                dt.hourGMT(), 
                dt.minuteGMT(), 
                dt.secondGMT()
            );
        }

        return null;
    } 

    public static INTNationalRBPAPIRequest_Wrapper.providedService prepSLIForRBP(Map<String, Object> paramMap) {
        INTNationalRBPAPIRequest_Wrapper.providedService providedService = new INTNationalRBPAPIRequest_Wrapper.providedService();
        Map<String, String> unitMap = (Map<String, String>) paramMap.get('unitMap');
        FSL_Service_Line_Item__c eachSLI = (FSL_Service_Line_Item__c) paramMap.get('sli');
        String tCode = (String) paramMap.get('tCode');
        String pCode = eachSLI.Product_Code__c;
        String sliUnits = unitMap.get(pCode);
        String sliPrice;

        if (eachSLI.Total_Price__c != null) {
            sliPrice = String.valueOf(eachSLI.Total_Price__c);
            sliPrice = sliPrice.replace('.', '');
        } else {
            sliPrice = '0000000';
        }

        if (sliUnits != null) {
            sliUnits = sliUnits.split('-')[0];
        } else {
            sliUnits = '';
        }

        providedService.providedServiceType = tCode;
        providedService.service = pCode;
        providedService.unit = sliUnits;
        providedService.quantity = Integer.valueOf(eachSLI.Unit__c);
        providedService.charge = new INTNationalRBPAPIRequest_Wrapper.charge();
        providedService.charge.chargeType = eachSLI.Charge_to_Account__c;

        while (sliPrice.length() < 7) {
            sliPrice = '0' + sliPrice;
        }

        providedService.charge.amount = sliPrice;

        return providedService;
    }

    private static void handleException(Exception e) {
        String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

        System.debug(JSON.serializePretty(new Map<String, Object>{
            'operation' => 'ERS_GrabRAPReadyWorkOrdersBatch',
            'error' => errMsg
        }));

        throw e;
    }
}