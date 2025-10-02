global without sharing class AAAWorkOrderClearCodeLogicInvokable {
    @InvocableMethod(label = 'Call Clear Code Logic')
    global static List<FlowOutput> runClearCodeLogic(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();

        if (input != null && input.size() > 0) {
            BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
            
            for (FlowInput flowInput : input) {
                FlowOutput output = new FlowOutput();
                WorkOrder wo = flowInput.workOrder;
                List<FSL_Service_Line_Item__c> sliList = flowInput.sliList;
                Boolean woIsUpdated = false;

                if (boSettings.Club_Code__c == '212' || boSettings.Club_Code__c == 'TTT') {
                    List<FSL_TroubleCode__c> troubleCodeLists = [
                        SELECT Id, Code__c 
                        FROM FSL_TroubleCode__c 
                        WHERE Work_Order__c =: wo.Id
                    ];
                    ServiceTerritory svcTerritory = [
                        SELECT Id, Facility_Number__c 
                        FROM ServiceTerritory 
                        WHERE Id =: wo.ServiceTerritoryId
                        LIMIT 1
                    ]; 
                    Boolean troubleCodeStartWithSix = false;
                    Boolean troubleCodeNotInOneEight = true;
                    Boolean troubleCodeCheckWhenSLIIsBA = false;
                    List<String> troubleCodeListOneEight = new List<String>{'1', '8'};
                    List<String> troubleCodeListSLIIsBA = new List<String>{'0', '1', '1V', '5', '7', '7A', '7B', '7C', '7H', '7L'};
                    List<String> facListOHB = new List<String>{'OHB01', 'OHB02', 'OHB03', '0HB04'};
                    List<String> clearingCodeBA = new List<String>{'2G', '2T', 'BN', 'SD', 'SF'};
        
                    for (FSL_TroubleCode__c currTroubleCode : troubleCodeLists) {
                        String troubleCode = currTroubleCode.Code__c;
        
                        if (troubleCode?.startsWith('6')) {
                            troubleCodeStartWithSix = true;  
                        }
        
                        if (troubleCodeListOneEight.contains(troubleCode)) {
                            troubleCodeNotInOneEight = false;
                        }
        
                        if (troubleCodeListSLIIsBA.contains(troubleCode)) {
                            troubleCodeCheckWhenSLIIsBA = true;
                        }
                    } 
                    
                    if (wo.Clearing_Code__c != 'XX') {
                        for (FSL_Service_Line_Item__c currSLI : sliList) {
                            if (
                                String.isNotBlank(wo.Resolution_Code__c)
                                && wo.Resolution_Code__c.startsWith('G') 
                                && currSLI.Product_Code__c == 'TW' 
                                && troubleCodeStartWithSix
                            ) {
                                currSLI.Unit__c = 0;
                                currSLI.Cost__c = 0;
                                currSLI.Override_Pricing__c = true;

                                if (boSettings.Club_Code__c == '212') {
                                    wo.Clearing_Code__c = '2G';
                                } else if (Test.isRunningTest()) {
                                    wo.Clearing_Code__c = 'XX';
                                }

                                woIsUpdated = true;
                            } else if (
                                troubleCodeStartWithSix 
                                && currSLI.Product_Code__c == 'WN' 
                                && svcTerritory.Facility_Number__c != 'TUL'
                                && !svcTerritory.Facility_Number__c?.endsWith('N')
                                && (
                                    (wo.In_Tow_Timestamp__c?.second() - wo.On_Location_Timestamp__c?.second()) < 30 
                                )
                            ) {
                                currSLI.Unit__c = 0; 
                                currSLI.Cost__c = 0;
                                currSLI.Override_Pricing__c = true;
                            } else if (!troubleCodeStartWithSix && currSLI.Product_Code__c == 'MX') {
                                currSLI.Cost__c = 0;
                                currSLI.Override_Pricing__c = true;    
                            } else if (
                                !troubleCodeStartWithSix 
                                && troubleCodeNotInOneEight
                                && !facListOHB.contains(svcTerritory.Facility_Number__c)
                                && (
                                    currSLI.Product_Code__c == 'MA' 
                                    || currSLI.Product_Code__c == 'PP'
                                )
                            ) {
                                currSLI.Unit__c = 0;
                                currSLI.Cost__c = 0;
                                currSLI.Unit_Price__c = 0;
                                currSLI.Override_Pricing__c = true; 
                            } else if (
                                currSLI.Product_Code__c == 'BA' 
                                && troubleCodeCheckWhenSLIIsBA == true 
                                && wo.Resolution_Code__c?.startsWith('N') 
                                && (
                                    clearingCodeBA.contains(wo.Clearing_Code__c)
                                    || boSettings.Club_Code__c == 'TTT'
                                )
                                && wo.On_Location_Timestamp__c != null 
                                && wo.In_Tow_Timestamp__c == null
                            ) {
                                wo.Clearing_Code__c = 'NG';
                                woIsUpdated = true;
                            } else if (
                                troubleCodeStartWithSix 
                                && wo.Resolution_Code__c?.startsWith('N') 
                                && wo.On_Location_Timestamp__c != null 
                                && wo.In_Tow_Timestamp__c != null 
                                && wo.Clearing_Code__c == 'BN'
                            ) {
                                // wo.Clearing_Code__c = '2T';   
                            }      
                        }                        
                    }
                } else if (boSettings.Club_Code__c == '240') {
                    List<String> resCodeCancelTow = new List<String>{'X001', 'X002', 'R199', 'R007', 'R006', 'R003', 'R002', 'R001'};
                    
                    for (FSL_Service_Line_Item__c currSLI : sliList) {
                        Boolean isWOTypeTow = wo.Record_Type_Dev_Name__c == 'Tow';
                        Boolean isTowCancelled = isWOTypeTow && resCodeCancelTow.contains(wo.Resolution_Code__c);
        
                        if (isTowCancelled && currSLI.Product_Code__c == 'TW') {
                            currSLI.Cost__c = null;
                            currSLI.Unit__c = null;
                            currSLI.Calculated_Unit__c = null;
                            currSLI.Override_Pricing__c = true;
                        }
                    }
                }
    
                output.workOrder = wo;
                output.outputList = sliList;
                output.woIsUpdated = woIsUpdated;
                outputList.add(output);
            }
        }

        return outputList;
    }
    
    global class FlowInput {
        @InvocableVariable(label = 'Work Order') global WorkOrder workOrder;
        @InvocableVariable(label = 'SLI List') global List<FSL_Service_Line_Item__c> sliList;
    }
    
    global class FlowOutput {
        @InvocableVariable(label = 'WO Output') global WorkOrder workOrder;
        @InvocableVariable(label = 'SLI Output') global List<FSL_Service_Line_Item__c> outputList;
        @InvocableVariable(label = 'WO Clearing Code Updated') global Boolean woIsUpdated;
    }
}
// comment for deploy diff