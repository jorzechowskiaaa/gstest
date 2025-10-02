/**
 * @description       : Creates Payment records from Allocations and Reimbursements
 * @author            : joshtupas@salesforce.com
 * @group             : 
 * @last modified on  : 06-04-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-13-2024   joshtupas@salesforce.com
 *       06-04-2024   joshtupas@salesforce.com             Added logic to exclude rounding for 'TW' and 'FL' SLIs
 *       06-05-2024   joshtupas@salesforce.com             Fixed typo to exclude rounding for 'TL' instead of 'TW'
**/
global without sharing class AAAFlowInvocable {
    private static BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    @InvocableMethod(label = 'Call Flow Helper')
    global static List<FlowOutput> runFlowInvocable(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();

        if (input != null && input.size() > 0) {
            String flowName = input[0].flowAPIName;

            if (flowName == 'Get_SLI_Prices_On_REST_AutoLaunched') {    
                runGetSLIPricesOnRESTAutoLaunched(input);

                for (Integer i = 0; i < input.size(); i++) {
                    outputList.add(new FlowOutput());
                }
            } else if(flowName == 'Get_SLI_Prices_On_REST_AutoLaunched_insert/update') {
                runGetSLIPricesOnRESTMiniBatch(input);

                for (Integer i = 0; i < input.size(); i++) {
                    outputList.add(new FlowOutput());
                }
            } else if (flowName == 'Taxation_Autolaunched_Flow') {
                outputList = runTaxationAutolaunchedFlow(input);
            } else if (flowName == 'Round Up Units NE') {
                outputList = roundUpSLIUnitsNE(input);
            }
        }

        return outputList;
    }

    public static void runGetSLIPricesOnRESTAutoLaunched(List<FlowInput> input) {
        for (FlowInput flowInput : input) {
            WorkOrder wo = flowInput.wo;
            Boolean callClearCodeLogic = flowInput.callClearCodeLogic;
            List<FSL_Service_Line_Item__c> inputList = removeDupes(flowInput.sliList); 
            Map<String, Object> params = new Map<String, Object>{
                'workOrder' => wo,
                'lstServiceLineItems' => inputList,
                'callClearCodeLogic' => callClearCodeLogic != null ? callClearCodeLogic : true
            };
            Flow.Interview.Get_SLI_Prices_On_REST_AutoLaunched flow = new Flow.Interview.Get_SLI_Prices_On_REST_AutoLaunched(params);
    
            flow.start();
        }
    }

    // this gets ONE SLI record and ONE WO
    public static void runGetSLIPricesOnRESTMiniBatch(List<FlowInput> input) {
        for (FlowInput flowInput : input) {
            if (flowInput.sliList == null && flowInput.sli != null) {
                List<String> mlgList = new List<String>{'OM', 'TW'};
                FSL_Service_Line_Item__c sli = flowInput.sli;
                Boolean isOMTW = mlgList.contains(sli.Product_Code__c);

                if (!sli.Override_Pricing__c) {
                    sli.Tax__c = 0.0;
                }

                if (sli.Calculated_Unit__c == null && sli.Unit__c != null && isOMTW) {
                    sli.Calculated_Unit__c = sli.Unit__c;
                }

                flowInput.sliList = new List<FSL_Service_Line_Item__c>{sli};
            }
        }

        runGetSLIPricesOnRESTAutoLaunched(input);
    }

    public static List<FlowOutput> runTaxationAutolaunchedFlow(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();

        for (FlowInput flowInput : input) {
            List<FSL_Service_Line_Item__c> sliList = flowInput.sliList;

            if (sliList != null && sliList.size() > 0) {
                FlowOutput output = new FlowOutput();
                WorkOrder parentWO = flowInput.wo;
                Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
                List<Taxation_Excluded_SLI_By_Club__mdt> taxExcludeList = new List<Taxation_Excluded_SLI_By_Club__mdt>();
                List<ServiceTerritory> facList = [
                    SELECT Id, State
                    FROM ServiceTerritory
                    WHERE Id = :parentWO.ServiceTerritoryId
                ];
                ServiceTerritory svcTerritory = new ServiceTerritory();
                Map<String, List<String>> taxExcludeMap = new Map<String, List<String>>();

                if (facList != null && facList.size() > 0) {
                    svcTerritory = facList[0];
                }
        
                if (Test.isRunningTest()) {
                    taxExcludeList = AAAFlowInvocableTest.mockTaxExclusionMDT();
                } else {
                    taxExcludeList = [
                        SELECT Id, Product_Code__c, State__c 
                        FROM Taxation_Excluded_SLI_By_Club__mdt 
                        WHERE Club__c =: orgData.Name == 'AAA Northeast' ? 'NE' : 'ACA'
                    ];
                }
        
                for (Taxation_Excluded_SLI_By_Club__mdt taxExcludeMdt : taxExcludeList) {
                    // state can be null to apply to all states
                    String taxState = taxExcludeMdt.State__c;
                    String prodCode = taxExcludeMdt.Product_Code__c;
        
                    if (taxExcludeMap.get(prodCode) == null) {
                        taxExcludeMap.put(prodCode, new List<String>());
                    }
        
                    if (taxState != null) {
                        List<String> stateList = taxExcludeMap.get(prodCode);
        
                        stateList.add(taxState);
                        taxExcludeMap.put(prodCode, stateList);
                    }
                } 
                    
                // product list for SLIs with no IDs b/c Product_Code__c is null
                List<Product2> prodList = [
                    SELECT
                        Id,
                        ProductCode
                    FROM Product2
                    WHERE IsActive = true
                    AND Family = 'Service Item'
                ];
                Map<String, String> prodMap = new Map<String, String>();
                Map<String, FSL_Service_Line_Item__c> mapCompKeyToTaxedSLI = new Map<String, FSL_Service_Line_Item__c>();
        
                for (Product2 prod : prodList) {
                    if (prod != null) {
                        prodMap.put(prod.Id, prod.ProductCode);
                    }
                }
        
                for (FSL_Service_Line_Item__c fsli : sliList) {
                    String prodCode = fsli.Product_Code__c == null ? 
                        prodMap.get(fsli.Product__c) : fsli.Product_Code__c;
                    String woId = fsli.Work_Order__c;
                    String woProdCodeStr = woId + prodCode;
        
                    mapCompKeyToTaxedSLI.put(woProdCodeStr, fsli);
                }
        
                List<FSL_Service_Line_Item__c> lstSendToTaxFlow = new List<FSL_Service_Line_Item__c>();
                List<FSL_Service_Line_Item__c> lstExcludedFromTaxFlow = new List<FSL_Service_Line_Item__c>();
                String svcTerrState = svcTerritory?.State;
                String resCode = parentWO.Resolution_Code__c;
                
                for (FSL_Service_Line_Item__c fsli : sliList) {
                    String prodCode = fsli.Product_Code__c == null ? 
                        prodMap.get(fsli.Product__c) : fsli.Product_Code__c;
                    String woProdCodeStr = fsli.Work_Order__c + prodCode;
                    List<String> excStateList = taxExcludeMap.get(prodCode);
                    Boolean isTaxExcluded = false;
                    Boolean isNJTaxExcluded = svcTerrState == 'NJ' 
                        && (resCode == 'X001' || resCode == 'X002');
                    
                    if (excStateList != null) {
                        isTaxExcluded = excStateList.contains(svcTerrState) 
                            || excStateList.size() == 0 
                            || isNJTaxExcluded;
                    } else {
                        isTaxExcluded = isNJTaxExcluded;
                    }
        
                    if (mapCompKeyToTaxedSLI.get(woProdCodeStr) != null && !isTaxExcluded) {
                        lstSendToTaxFlow.add(fsli);
                    } else if (mapCompKeyToTaxedSLI.get(woProdCodeStr) != null) {
                        lstExcludedFromTaxFlow.add(fsli);
                    }
                }   
                
                Map<String, Object> params = new Map<String, Object>();
        
                params.put('listInputSLI', lstSendToTaxFlow);
                params.put('workOrderId', parentWO.Id);
                
                Flow.Interview.Taxation_Autolaunched_Flow taxationFlow = new Flow.Interview.Taxation_Autolaunched_Flow(params);
                
                //Invoke start method
                taxationFlow.start();
        
                List<FSL_Service_Line_Item__c> servLineItems01 = new List<FSL_Service_Line_Item__c>();
                List<FSL_Service_Line_Item__c> lstOutputSLIs = new List<FSL_Service_Line_Item__c>();
        
                if (boSettings.Club_Code__c == '000') {
                    servLineItems01 = AAAFlowInvocableTest.mockTaxSLIResult((List<FSL_Service_Line_Item__c>) params.get('listInputSLI'));
                } else {
                    servLineItems01 = (List<FSL_Service_Line_Item__c>) taxationFlow.getvariableValue('servLineItems');
                }
        
                if (servLineItems01 != null) {
                    lstOutputSLIs.addAll(servLineItems01);
                } else if (servLineItems01 == null && lstSendToTaxFlow.size() > 0) {
                    // if no taxes are applied, servLineItems01 will be null
                    lstOutputSLIs.addAll(lstSendToTaxFlow);
                }
        
                lstOutputSLIs.addAll(lstExcludedFromTaxFlow);
                output.sliList = lstOutputSLIs;
                outputList.add(output);
            }
        }

        return outputList;
    }

    public static List<FlowOutput> roundUpSLIUnitsNE(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();
        List<String> prodIdList = new List<String>();
        List<Product2> prodList = [
            SELECT Id
            FROM Product2
            WHERE ProductCode IN ('TW', 'OM') //AGB for SSFI-976 2/25/25 decided to inverse, original line: WHERE ProductCode IN ('TL', 'FL') 
        ];
        
        for (Product2 prod : prodList) {
            prodIdList.add(prod.Id);
        }

        for (FlowInput flowInput : input) {
            FlowOutput output = new FlowOutput();
            List<FSL_Service_Line_Item__c> sliList = flowInput.sliList;
    
            if (sliList != null) {
                if (boSettings.Club_Code__c == '240') {
                    for (FSL_Service_Line_Item__c sli : sliList) {
                        Boolean excludeRounding = prodIdList.contains(sli.Product__c);

                        if (excludeRounding) { //AGB for SSFI-976 2/25/25 decided to inverse, original line: if (!excludeRounding) {
                            if (sli.Unit__c != null) {
                                sli.Unit__c = sli.Unit__c.round(System.RoundingMode.UP);
                            }
            
                            if (sli.Calculated_Unit__c != null) {
                                sli.Calculated_Unit__c = sli.Calculated_Unit__c.round(System.RoundingMode.UP);
                            }
                        }
                    }
                }

                output.sliList = sliList;
            }
            
            outputList.add(output);
        }

        return outputList;
    }

    private static List<FSL_Service_Line_Item__c> removeDupes(List<FSL_Service_Line_Item__c> sliList) {
        List<FSL_Service_Line_Item__c> resList = new List<FSL_Service_Line_Item__c>();

        if (sliList != null && sliList.size() > 0) {
            Map<String, FSL_Service_Line_Item__c> sliMap = new Map<String, FSL_Service_Line_Item__c>();
    
            for (FSL_Service_Line_Item__c sli : sliList) {
                String prodId = sli.Product__c;
                FSL_Service_Line_Item__c testSLI = sliMap.get(prodId);
    
                if (testSLI == null) {
                    sliMap.put(prodId, sli);
                } else if (sli.Id != null) {
                    sliMap.put(prodId, sli);
                }
            }
    
            for (String key : sliMap.keySet()) {
                resList.add(sliMap.get(key));
            }
        }

        return resList;
    }

    global class FlowInput {
        @InvocableVariable(label = 'Flow Name') global String flowAPIName;
        @InvocableVariable(label = 'Work Order') global WorkOrder wo;
        @InvocableVariable(label = 'Service Line Item') global FSL_Service_Line_Item__c sli;
        @InvocableVariable(label = 'SLI List') global List<FSL_Service_Line_Item__c> sliList;
        @InvocableVariable(label = 'Call Clear Code Logic') global Boolean callClearCodeLogic;
    }
    
    global class FlowOutput {
        @InvocableVariable(label = 'SLI List') global List<FSL_Service_Line_Item__c> sliList;
    }
}