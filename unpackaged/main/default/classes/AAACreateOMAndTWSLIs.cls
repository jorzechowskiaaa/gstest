global without sharing class AAACreateOMAndTWSLIs {
    private static BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    @InvocableMethod(label = 'Create OM and TW SLIs')
    global static List<FlowOutput> runCreateOMAndTWSLIs(List<FlowInput> input) {
        try {
            List<FlowOutput> outputList = new List<FlowOutput>();
            List<FSL_Service_Line_Item__c> slisToUpdate = new List<FSL_Service_Line_Item__c>();
    
            if (input != null && input.size() > 0) {
                for (FlowInput flowInput : input) {
                    FlowOutput output = new FlowOutput();
                    WorkOrder wo = flowInput.workOrder;
                    ServiceAppointment slrem;
                    ServiceAppointment slrtw;
                    String fromFac = 'From Service Territory';
                    String fromDriver = 'From Driver Location';
                    String mileageType = wo.Facility_Calculated_Mileage_Type__c;
                    String clubCode = boSettings.Club_Code__c;
                    String resCode = wo.Resolution_Code__c != null ? wo.Resolution_Code__c : '';
                    Boolean calcTowEnabled = wo.Facility_Calculated_Tow_Mileage__c;
                    Boolean recalMileage = flowInput.recalMileage != null && flowInput.recalMileage;
                    Boolean isCC = wo.Clearing_Code__c != null ? wo.Clearing_Code__c.equals('CC') : false;
                    Boolean excludeTW = clubCode == '240' 
                        && (
                            isCC 
                            || resCode.startsWith('G') 
                            || resCode.startsWith('R')
                            || resCode.startsWith('X')
                        );
                    List<String> fromOptions = new List<String>{fromFac, fromDriver};
                    List<ServiceAppointment> saList = new List<ServiceAppointment>();
                    List<String> prodCodeList = new List<String>();
        
                    if (Test.isRunningTest()) {
                        saList = AAACreateOMAndTWSLIsTest.mockServiceAppointments(wo.Id);
                    } else {
                        saList = [
                            SELECT
                                Id,
                                SLR_En_Route_Miles__c,
                                SLR_Tow_Miles__c,
                                Subject
                            FROM ServiceAppointment
                            WHERE Work_Order__c = :wo.Id
                        ];
                    }
        
                    for (ServiceAppointment sa : saList) {
                        if (sa.Subject == 'Breakdown Appointment' && slrem == null) {
                            slrem = sa;
                        }
        
                        if (sa.Subject == 'Tow Appointment' && slrtw == null) {
                            slrtw = sa;
                        }
        
                        if (slrem != null && slrtw != null) {
                            break;
                        }
                    }
    
                    if (fromOptions.contains(mileageType)) {
                        prodCodeList.add('OM');
                    }
        
                    // PR893288-4938 
                    if (
                        wo.Record_Type_Dev_Name__c == 'Tow' 
                        && !excludeTW 
                        && calcTowEnabled 
                        && String.isNotEmpty(wo.Resolution_Code__c)
                    ) {
                        prodCodeList.add('TW');
                    }
        
                    List<Product2> prod2List = [
                        SELECT
                            Id,
                            Family,
                            IsActive,
                            Name,
                            ProductCode
                        FROM Product2
                        WHERE ProductCode IN :prodCodeList
                    ];
                    List<Integration_Settings__c> googleAPISettings = [
                        SELECT
                            Id,
                            API_Key__c,
                            Enpoint_URL__c,
                            Extra_Header_Value__c,
                            Header_Value__c,
                            Method__c,
                            Named_Credential__c,
                            Path__c,
                            Request_Timeout__c
                        FROM Integration_Settings__c
                        WHERE Name = 'Google_Directions_API'
                    ];
                    Object latBreakObj = wo.Breakdown_Location__Latitude__s;
                    Object longBreakObj = wo.Breakdown_Location__Longitude__s;
                    Object latObj = wo.Latitude;
                    Object longObj = wo.Longitude;
                    String breakdownLat;
                    String breakdownLong;
                    String ogString;
                    String destString;
                    String finalEM;
                    String finalTW;
                    Integration_Settings__c googleAPI = new Integration_Settings__c();
    
                    if (latBreakObj != null) {
                        if (latBreakObj instanceof String) {
                            breakdownLat = (String) latBreakObj;
                        } else {
                            breakdownLat = String.valueOf(latBreakObj);
                        }
                    } else {
                        if (latObj instanceof String) {
                            breakdownLat = (String) latObj;
                        } else {
                            breakdownLat = String.valueOf(latObj);
                        }
                    }
    
                    if (longBreakObj != null) {
                        if (longBreakObj instanceof String) {
                            breakdownLong = (String) longBreakObj;
                        } else {
                            breakdownLong = String.valueOf(longBreakObj);
                        }
                    } else {
                        if (longObj instanceof String) {
                            breakdownLong = (String) longObj;
                        } else {
                            breakdownLong = String.valueOf(longObj);
                        }
                    }
        
                    if (googleAPISettings.size() > 0) {
                        googleAPI = googleAPISettings[0];
                    }
        
                    if (mileageType == fromDriver) {
                        List<Service_Appointment_Status_Location__c> saLocations = new List<Service_Appointment_Status_Location__c>();
        
                        if (Test.isRunningTest()) {
                            saLocations = AAACreateOMAndTWSLIsTest.mockSALocations(wo.Id);
                        } else if (slrem != null) {
                            saLocations = [
                                SELECT
                                    Id,
                                    End_States__c,
                                    From_Latitude__c,
                                    From_Longitude__c,
                                    Service_Appointment__c,
                                    To_Latitude__c,
                                    To_Longitude__c,
                                    Work_Order__c
                                FROM Service_Appointment_Status_Location__c
                                WHERE Work_Order__c = :wo.Id
                                AND Service_Appointment__c = :slrem.Id
                            ];
                        }
        
                        if (saLocations.size() > 0) {
                            Service_Appointment_Status_Location__c saLocation = saLocations[0];
        
                            ogString = saLocation.From_Latitude__c + '%2C' + saLocation.From_Longitude__c;
                            destString = breakdownLat + '%2C' + breakdownLong;
                        }
                    } else if (mileageType == fromFac) {
                        ogString = wo.Facility_Latitude__c + '%2C' + wo.Facility_Longitude__c;
                        destString = breakdownLat + '%2C' + breakdownLong;
                    }
        
                    finalEM = getMileage(new List<String>{ogString, destString}, googleAPI);
        
                    if (wo.Record_Type_Dev_Name__c == 'Tow') {
                        Object towLatObj = wo.Tow_Location__Latitude__s;
                        Object towLongObj = wo.Tow_Location__Longitude__s;
                        Object backupLatObj = wo.Tow_Latitude__c;
                        Object backupLongObj = wo.Tow_Longitude__c;
                        String towLat;
                        String towLong;
    
                        if (towLatObj != null) {
                            if (towLatObj instanceof String) {
                                towLat = (String) towLatObj;
                            } else {
                                towLat = String.valueOf(towLatObj);
                            }
                        } else {
                            if (backupLatObj instanceof String) {
                                towLat = (String) backupLatObj;
                            } else {
                                towLat = String.valueOf(backupLatObj);
                            }
                        }
    
                        if (towLongObj != null) {
                            if (towLongObj instanceof String) {
                                towLong = (String) towLongObj;
                            } else {
                                towLong = String.valueOf(towLongObj);
                            }
                        } else {
                            if (backupLongObj instanceof String) {
                                towLong = (String) backupLongObj;
                            } else {
                                towLong = String.valueOf(backupLongObj);
                            }
                        }
        
                        finalTW = getMileage(
                            new List<String>{
                                breakdownLat + '%2C' + breakdownLong, 
                                towLat + '%2C' + towLong
                            }, 
                            googleAPI
                        );
                    }
        
                    List<FSL_Service_Line_Item__c> sliOutputList = new List<FSL_Service_Line_Item__c>();
                    List<FSL_Service_Line_Item__c> sliList = new List<FSL_Service_Line_Item__c>();
                    Map<String, FSL_Service_Line_Item__c> sliMap = new Map<String, FSL_Service_Line_Item__c>();
    
                    if (recalMileage) {
                        sliList = [
                            SELECT
                                Id,
                                Unit__c,
                                Work_Order__c,
                                Product_Code__c
                            FROM FSL_Service_Line_Item__c
                            WHERE Work_Order__c = :wo.Id
                            AND Product_Code__c IN :prodCodeList
                        ];
    
                        if (sliList.size() > 0) {
                            for (FSL_Service_Line_Item__c sli : sliList) {
                                if (sli != null && String.isNotBlank(sli.Product_Code__c)) {
                                    sliMap.put(sli.Product_Code__c, sli);
                                }
                            }
                        }
                    }
        
                    for (Product2 prod2 : prod2List) {
                        Decimal twUnits;
                        Decimal emUnits;
                        String prodCode = prod2.ProductCode;
        
                        if (finalTW != null) {
                            twUnits = Decimal.valueOf(finalTW.replace(',', ''));
                        }
        
                        if (finalEM != null) {
                            emUnits = Decimal.valueOf(finalEM.replace(',', ''));
                        }
        
                        Decimal units = prodCode == 'TW' ? twUnits : emUnits;
    
                        if (recalMileage) {
                            FSL_Service_Line_Item__c sli = sliMap.get(prodCode);
    
                            if (sli != null) {
                                sli.Unit__c = units == null ? 0.0 : units;
                                sli.Ready_for_Invoicing__c = false;
                                slisToUpdate.add(sli);
                            }
                        } else {
                            sliOutputList.add(
                                new FSL_Service_Line_Item__c(
                                    Work_Order__c = wo.Id,
                                    Product__c = prod2.Id,
                                    Unit__c = units,
                                    Calculated_Unit__c = units
                                )
                            );
                        }
                    }
    
                    if (!recalMileage) {
                        output.outputList = sliOutputList;
                    }
    
                    outputList.add(output);
                }
            }
    
            if (slisToUpdate.size() > 0) {
                update slisToUpdate;
            }
    
            return outputList;
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

            insert new FSL_Application_Log__c(
                Operation__c = 'AAACreateOMAndTWSLIs',
                Error_Message__c = errMsg
            );
            
            throw e;
        }
    }

    private static String getMileage(List<String> params, Integration_Settings__c googleAPI) {
        String ogString = params[0];
        String destString = params[1];
        String httpPath = googleAPI.Enpoint_URL__c + 'origin=' + ogString + '&destination=' + destString + '&key=' + googleAPI.API_Key__c+'&units=IMPERIAL';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String result;
        String finalResult;

        req.setEndpoint(httpPath);
        req.setMethod('GET');

        HttpResponse res = http.send(req);
        Map<String, Object> resObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> routesList = (List<Object>) resObj.get('routes');

        if (routesList != null && routesList.size() > 0) {
            Map<String, Object> routes = (Map<String, Object>) routesList[0];
            List<Object> legsList = (List<Object>) routes.get('legs');
            Map<String, Object> legs = (Map<String, Object>) legsList[0];
            Map<String, Object> distance = (Map<String, Object>) legs.get('distance');
            String units = (String) distance.get('text');
           	
            // PR893288-4923
            String unitOfMeasure = units.split(' ')[1];
            String strUnit = units.split(' ')[0].contains(',') ? 
                units.split(' ')[0].remove(',') : units.split(' ')[0];
            Decimal decUnit = Decimal.valueOf(strUnit);
            Decimal roundedUnit = boSettings.Club_Code__c == '240' ? 
                decUnit.round(System.RoundingMode.UP) : decUnit;
			
            // PR893288-4923
            result = String.valueOf(roundedUnit);
            
            // PR893288-4923
            if (
                decUnit != null 
                && (
                    (unitOfMeasure == 'ft' && decUnit < 5280.00) 
                    || (unitOfMeasure == 'mi' && decUnit < 1.00)
                )
            ) {
                finalResult = String.valueOf(0);
            }
        }
	
        return finalResult == null ? result : finalResult;
    }

    global class FlowInput {
        @InvocableVariable(label = 'Work Order') global WorkOrder workOrder;
        @InvocableVariable(label = 'Re-cal Mileage') global Boolean recalMileage;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'SLI Output') global List<FSL_Service_Line_Item__c> outputList;
    }
}