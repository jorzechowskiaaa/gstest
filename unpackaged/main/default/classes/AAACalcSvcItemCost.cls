/**
 * @description       : Pricing engine that calculates cost for SLIs based on RLIs in Service Contract
 * @author            : joshtupas@salesforce.com
 * @group             : 
 * @last modified on  : 05-28-2024
 * @last modified by  : Josh Tupas
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-25-2024   joshtupas@salesforce.com             Refactored pricing engine IP to Apex class
 *       05-22-2024   joshtupas@salesforce.com             Added null check when processing a WO that does not have a Resolution code
 *       05-28-2024   joshtupas@salesforce.com             Added null check when processing a WO that does not have a Clearing code
**/
global without sharing class AAACalcSvcItemCost {
    private static BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();

    @InvocableMethod(label = 'Price SLIs')
    global static List<FlowOutput> runCalcSvcItemCost(List<FlowInput> flowInput) {
        try {
            List<FlowOutput> outputList = new List<FlowOutput>();
    
            if (flowInput != null && flowInput.size() > 0) {
                for (FlowInput input : flowInput) {
                    List<FSL_Service_Line_Item__c> sliList = input.sliList;
    
                    if (sliList != null && sliList.size() > 0) {
                        FlowOutput output = new FlowOutput();
                        WorkOrder wo = [
                        SELECT Id, Call_Date__c, Clearing_Code__c, BO_Editable_WO_Specific_Membership_Level__c, 
                               Cleared_Timestamp_TOD_Code__c, Facility_Contract__c, CaseId,Resolution_Code__c,ServiceTerritory.Is_Fleet__c //AGB added ServiceTerritory.Is_Fleet__c for SSFI-651
                        FROM WorkOrder
                        WHERE Id = :input.wo.Id
                    ];
                        List<Id> prodIdList = new List<Id>();
                        String username = UserInfo.getUserName();
                        // String todCode = wo.Cleared_Timestamp_TOD_Code__c;
                        Clear_Code_Mapping__mdt ccMapMdt = new Clear_Code_Mapping__mdt();
    
                        if (Test.isRunningTest()) {
                            ccMapMdt = AAACalcSvcItemCostTest.mockCCMapping();
                        } else if (String.isNotBlank(wo.Clearing_Code__c)) {
                            List<Clear_Code_Mapping__mdt> ccMapMdtList = [
                                SELECT Id, Base_Pay_Percent__c,Fleet_Base_Pay_Percent__c //AGB added Fleet_Base_Pay_Percent__c for SSFI-651
                                FROM Clear_Code_Mapping__mdt
                                WHERE Label = :wo.Clearing_Code__c
                            ];
    
                            ccMapMdt = ccMapMdtList.size() > 0 ? ccMapMdtList[0] : null;
                        }
            
                        for (FSL_Service_Line_Item__c sli : sliList) {
                            prodIdList.add(sli.Product__c);
                        }
                        
                        Date callDate;
                        if (wo.Call_Date__c != null) {
                            callDate = Date.valueOf(wo.Call_Date__c); // Ensure Call_Date__c is in 'yyyy-MM-dd' format
                        }
            
                        List<Rate_Line_Item__c> rliList = [
                            SELECT
                            Id,
                            RecordTypeId,
                            Calculation_Type__c,
                            Charge_to_Account__c,
                            Contract__c,
                            End_Date__c,
                            Fixed_Amount__c,
                            Max_Data_Range__c,
                            Min_Data_Range__c,
                            Product_Code__c,
                            Product__c,
                            Service_Type_Picklist__c,
                            Start_Date__c,
                            Time_of_Day_Code__c,
                            Unit_of_Measure__c,
                            Uses_Time_of_Day__c
                            FROM Rate_Line_Item__c
                            WHERE Service_Type_Picklist__c = :wo.BO_Editable_WO_Specific_Membership_Level__c
                            AND Product__c IN :prodIdList
                            AND Start_Date__c <= :callDate  // Use the converted callDate in the filter
                            AND End_Date__c >= :callDate    // Check if callDate is within the range
                            AND Contract__c = :wo.Facility_Contract__c
                            ORDER BY Min_Data_Range__c
                        ];

            
                        // --------------------------
                        // ----LoopServiceItems------
                        List<Map<String, Object>> LoopServiceItems = new List<Map<String, Object>>();
                        // ----LoopServiceItems------
            
                        Map<String, Object> FiltedRateListFalse = new Map<String, Object>();
                        Map<String, Object> FilteredRateListTrue = new Map<String, Object>();
                        
                        for (FSL_Service_Line_Item__c sli : sliList) {
                            List<Rate_Line_Item__c> RateLineItem;
                            Decimal Quantity;
                            String TODCode;
                            String ProductKey;
                            Decimal RequestedUnit;
                            Decimal RequestedCost;
                            Decimal Unit;
                            Decimal Cost;
            
                            // ----FiltRateItem------
                            List<Map<String, Object>> mergedRateList = new List<Map<String, Object>>();
                            // ----FiltRateItem------
            
                            // ----FiltedRateListFalse------
                            List<Map<String, Object>> finalResult1 = new List<Map<String, Object>>();
                            // ----FiltedRateListFalse------
                            
                            // ----FilteredRateListTrue------
                            List<Map<String, Object>> finalResult2 = new List<Map<String, Object>>();
                            // ----FilteredRateListTrue------
            
                            RateLineItem = rliList;
                            Quantity = sli.Unit__c;
                            TODCode = wo.Cleared_Timestamp_TOD_Code__c;
                            ProductKey = sli.Product__c;
                            RequestedUnit = sli.Requested_Unit__c;
                            RequestedCost = sli.Requested_Cost__c;
                            Unit = sli.Unit__c;
                            Cost = sli.Cost__c;
            
                            // ----FiltRateItem------
                            for (Rate_Line_Item__c rli : RateLineItem) {
                                Map<String, Object> obj = new Map<String, Object>{
                                    'ProductKey' => ProductKey,
                                    'TODCode' => TODCode,
                                    'Unit' => Unit,
                                    'Product__c' => ProductKey,
                                    'Quantity' => Quantity,
                                    'RequestedCost' => RequestedCost,
                                    'RequestedUnit' => RequestedUnit,
                                    'Calculation_Type__c' => rli.Calculation_Type__c,
                                    'Charge_to_Account__c' => rli.Charge_to_Account__c,
                                    'Contract__c' => rli.Contract__c,
                                    'End_Date__c' => rli.End_Date__c,
                                    'Fixed_Amount__c' => rli.Fixed_Amount__c,
                                    'Id' => rli.Id,
                                    'Max_Data_Range__c' => rli.Max_Data_Range__c,
                                    'Min_Data_Range__c' => rli.Min_Data_Range__c,
                                    'Product__c' => rli.Product__c,
                                    'productCode' => rli.Product_Code__c,
                                    'RecordTypeId' => rli.RecordTypeId,
                                    // 'Service_Type__c' => rli.Service_Type__c,
                                    'Time_of_Day_Code__c' => rli.Time_of_Day_Code__c,
                                    // 'Trouble_Code_Indicator__c' => rli.Trouble_Code_Indicator__c,
                                    'Unit_of_Measure__c' => rli.Unit_of_Measure__c,
                                    'Uses_Time_of_Day__c' => rli.Uses_Time_of_Day__c
                                };
            
                                mergedRateList.add(obj);
                            }
                            // ----FiltRateItem------
            
                            // ----FiltedRateListFalse------
                            for (Map<String, Object> obj : mergedRateList) {
                                Boolean prodIdMatches = obj.get('ProductKey') == obj.get('Product__c');
                                Boolean usesTOD = (Boolean) obj.get('Uses_Time_of_Day__c');
                                Boolean todMatches = usesTOD && 
                                    obj.get('TODCode') == obj.get('Time_of_Day_Code__c');
            
                                if (prodIdMatches && (!usesTOD || todMatches)) {
                                    finalResult1.add(obj);   
                                }
                            }
            
                            FiltedRateListFalse.put('finalResult', finalResult1);
                            // ----FiltedRateListFalse------
            
                            // ----FilteredRateListTrue------
                            for (Map<String, Object> obj : mergedRateList) {
                                Boolean prodIdMatches = obj.get('ProductKey') == obj.get('Product__c');
                                Boolean usesTOD = (Boolean) obj.get('Uses_Time_of_Day__c');
            
                                if (prodIdMatches && usesTOD) {
                                    finalResult2.add(obj);   
                                }
                            }
            
                            FilteredRateListTrue.put('finalResult', finalResult2);
                            // ----FilteredRateListTrue------
            
                            // ----IPCalculateEachServItemCost------
                            Map<String, Object> IPCalculateEachServItemCost = new Map<String, Object>();
                            List<Map<String, Object>> finalResultFalse = (List<Map<String, Object>>) FiltedRateListFalse.get('finalResult');
                            Map<String, Object> calcResult = new Map<String, Object>();
            
                            if (finalResultFalse.size() == 0) {
                                List<Map<String, Object>> finalResult = (List<Map<String, Object>>) FilteredRateListTrue.get('finalResult');
            
                                calcResult = calcEachSLICost((List<Map<String, Object>>) FilteredRateListTrue.get('finalResult'));
                            } else {
                                calcResult = calcEachSLICost(finalResultFalse);
                            }
            
                            LoopServiceItems.add(calcResult);
                            // ----IPCalculateEachServItemCost------
                        }
            
                        // ----UpdateBaseRateWithTroubleCode------
                        String ContractId = wo.Facility_Contract__c;
                        String workOrderId = wo.Id;
                        List<Map<String, Object>> ServItemList = LoopServiceItems;
                        Decimal basePayPercent = ccMapMdt?.Base_Pay_Percent__c;
                        
                        //AGB Code here
                        if(wo.ServiceTerritory.Is_Fleet__c && ccMapMdt?.Fleet_Base_Pay_Percent__c <> null){
                            system.debug('Fleet Base Pay Percent Used: '+ccMapMdt?.Fleet_Base_Pay_Percent__c);
                            basePayPercent = ccMapMdt?.Fleet_Base_Pay_Percent__c;
                        }
            
                        Decimal costCount = 0;
                        String updateTroubleCodeLog = '';
                        String troubleCodeLog = '';
                        List<FSL_TroubleCode__c> tcList = [
                            SELECT
                                Id,
                                Code__c,
                                Type__c
                            FROM FSL_TroubleCode__c
                            WHERE Type__c = 'PROBLEM'
                            AND Work_Order__c = :wo.Id
                        ];
                        List<String> tcStrList = new List<String>();
            
                        for (FSL_TroubleCode__c tc : tcList) {
                            tcStrList.add(tc.Code__c);
                        }
            
                        List<Rate_Line_Item__c> rliWithTCList = [
                            SELECT
                                Id,
                                Contract__c,
                                End_Date__c,
                                Fixed_Amount__c,
                                Product_Code__c,
                                Product_Name__c,
                                Product__c,
                                Start_Date__c,
                                Time_of_Day_Code__c
                            FROM Rate_Line_Item__c
                            WHERE Service_Type_Picklist__c = 'Premier'
                            AND Contract__c = :ContractId
                            AND Product_Code__c IN :tcStrList
                        ];
            
                        for (Rate_Line_Item__c rliWithTC : rliWithTCList) {
                            costCount = costCount + rliWithTC.Fixed_Amount__c;
                            updateTroubleCodeLog = updateTroubleCodeLog + ' ' + rliWithTC.Product_Name__c + ':  $' + rliWithTC.Fixed_Amount__c + ', ';
                        }
            
                        List<Map<String, Object>> LoopBlock2 = new List<Map<String, Object>>();
            
                        for (Map<String, Object> servItem : ServItemList) {
                            Map<String, Object> resObj = new Map<String, Object>();
                            Decimal updatedValue;
                            String updateAuditLog;
                            Decimal total = costCount + (Decimal) servItem.get('CostValue');
            
                            if (servItem.get('productCode') == 'BA') {
                                updatedValue = costCount + (Decimal) servItem.get('CostValue');
                                updateAuditLog = 'Service Line Item BA value of $' + servItem.get('CostValue') + ' + ' + updateTroubleCodeLog + ' = $' + total;
                            } else {
                                updatedValue = (Decimal) servItem.get('CostValue');
                            }
            
                            if (servItem.get('productCode') == 'BA' && basePayPercent != null) {
                                updatedValue = updatedValue * basePayPercent / 100;
                            }
                            
                            resObj.put('UpdatedCostValue', updatedValue);
                            resObj.put('ProductCode', servItem.get('productCode'));
                            resObj.put('ProductKey', servItem.get('ProductKey'));
                            resObj.put('ServiceId', servItem.get('ServiceId'));
                            resObj.put('RequestedUnit', servItem.get('RequestedUnit'));
                            resObj.put('RequestedCost', servItem.get('RequestedCost'));
                            resObj.put('Unit', servItem.get('RequestedUnit'));
                            resObj.put('Cost', updatedValue);
                            resObj.put('updateAuditLog', updateAuditLog);
                            resObj.put('workOrderId', wo.Id);
                            resObj.put('ChargeToAccount', servItem.get('ChargeToAccount'));
                            resObj.put('RequestedForInvoice', servItem.get('RequestedForInvoice'));
                            LoopBlock2.add(resObj);
                        }
                        // ----UpdateBaseRateWithTroubleCode------
                        
                        // ----MergeOriginListAndUpdateList------
                        List<Map<String, Object>> MergeOriginListAndUpdateList = new List<Map<String, Object>>();
                        Map<String, Object> sliMap = new Map<String, Object>();
            
                        for (FSL_Service_Line_Item__c sli : sliList) {
                            String prodId = sli.Product__c;
                            String serializedSLI = JSON.serialize(sli);
                            Map<String, Object> deserializedSLI = (Map<String, Object> ) JSON.deserializeUntyped(serializedSLI);
            
                            if (sliMap.get(prodId) == null) {
                                sliMap.put(prodId, deserializedSLI);
                            }
                        }
            
                        for (Map<String, Object> servItem : LoopBlock2) {
                            String prodId = (String) servItem.get('ProductKey');
            
                            if (sliMap.get(prodId) == null) {
                                sliMap.put(prodId, servItem);
            
                                MergeOriginListAndUpdateList.add(servItem);
                            } else {
                                Map<String, Object> servLineItem = (Map<String, Object>) sliMap.get(prodId);
            
                                servLineItem.put('UpdatedCostValue', servItem.get('UpdatedCostValue'));
                                servLineItem.put('ProductCode', servItem.get('ProductCode'));
                                servLineItem.put('ProductKey', servItem.get('ProductKey'));
                                servLineItem.put('ServiceId', servItem.get('ServiceId'));
                                servLineItem.put('RequestedUnit', servItem.get('RequestedUnit'));
                                servLineItem.put('RequestedCost', servItem.get('RequestedCost'));
                                servLineItem.put('Unit', servItem.get('Unit'));
                                servLineItem.put('Cost', servItem.get('Cost'));
                                servLineItem.put('updateAuditLog', servItem.get('updateAuditLog'));
                                servLineItem.put('workOrderId', servItem.get('workOrderId'));
                                servLineItem.put('ChargeToAccount', servItem.get('ChargeToAccount'));
                                servLineItem.put('RequestedForInvoice', servItem.get('RequestedForInvoice'));
            
                                MergeOriginListAndUpdateList.add(servLineItem);
                            }
                        }
                        // ----MergeOriginListAndUpdateList------
                        
                        // ----MultipleUpdateAutidLog------
                        List<Audit_Log__c> auditLogsToInsert = new List<Audit_Log__c>();
            
                        for (Map<String, Object> auditObj : MergeOriginListAndUpdateList) {
                            String CaseId = wo.CaseId;
                            String Status;
                            String Description = 'Product Code: ' + (String) auditObj.get('ProductCode') + 
                                ',  Approval Status: ' + Status + 
                                ',  Requested Unit: ' + (String) auditObj.get('RequestedUnit') != null ? (String) auditObj.get('RequestedUnit') : 'None' + 
                                ',  Unit: ' + (String) auditObj.get('Old_Unit_Value__c') +
                                ', Requested Cost: ' + (String) auditObj.get('RequestedCost') != null ? (String) auditObj.get('RequestedCost') : 'None' +
                                ',  Cost: ' + (String) auditObj.get('Cost') != null ? (String) auditObj.get('Cost') : 'None' +
                                '   User: ' + username + 
                                ',   Reason: ' + (String) auditObj.get('Reason_for_Decision__c') + (String) auditObj.get('updateAuditLog') != null ? ',  ' + (String) auditObj.get('updateAuditLog') : '.';
            
                            auditLogsToInsert.add(
                                new Audit_Log__c(
                                    Case__c = CaseId,
                                    Details__c = Description,
                                    Work_Order__c = wo.Id
                                )
                            );
                        }
                        // ----MultipleUpdateAutidLog------
                        // --------------------------
                        
                        Map<String, Object> costMap = new Map<String, Object>();
            
                        for (Map<String, Object> pricedObj : LoopBlock2) {
                            String prodKey = (String) pricedObj.get('ProductKey');
            
                            if (costMap.get(prodKey) == null) {
                                costMap.put(prodKey, pricedObj);
                            }
                        }
    
                        for (FSL_Service_Line_Item__c fsli : sliList) {
                            Map<String, Object> pricedObj = (Map<String, Object>) costMap.get(fsli.Product__c);
                            String resCode = wo.Resolution_Code__c;
                            String clearCode = wo.Clearing_Code__c;
                            Boolean isCC = clearCode != null && clearCode.equals('CC');
                            Boolean doNotPriceTW = wo.Resolution_Code__c != null 
                                && boSettings.Club_Code__c == '240'
                                && fsli.Product_Code__c == 'TW'
                                && (
                                    isCC || resCode?.startsWith('G') 
                                    || resCode?.startsWith('R')
                                    || resCode?.startsWith('X')
                                );
    
                            if (pricedObj != null && !doNotPriceTW) {
                                Boolean rdyForInvc = (Boolean) pricedObj.get('RequestedForInvoice');
    
                                fsli.Charge_to_Account__c = (String) pricedObj.get('ChargeToAccount');
                                fsli.Ready_for_Invoicing__c = rdyForInvc == true;
                                fsli.Cost__c = (Decimal) pricedObj.get('Cost');
                            } else if (!fsli.Override_Pricing__c) {
                                fsli.Cost__c = 0.0;
                            }
                        }
            
                        output.outputList = sliList;
                        output.auditList = auditLogsToInsert;
                        outputList.add(output);
                    }
                }
            }
    
            return outputList;
        } catch (Exception e) {
            String errMsg = e.getMessage() + '\n\n' + e.getStackTraceString();

            insert new FSL_Application_Log__c(
                Operation__c = 'AAACalcSvcItemCost',
                Error_Message__c = errMsg
            );
            
            throw e;
        }
    }

    private static Map<String, Object> calcEachSLICost(
        List<Map<String, Object>> finalResult
    ) {
        Decimal currCost = 0;

        if (finalResult != null && finalResult.size() > 0) {
            Boolean keepgoing = true;
            Decimal quantity = finalResult[0].get('Quantity') != null ?
                (Decimal) finalResult[0].get('Quantity') : 0;
    
            for (Map<String, Object> rate : finalResult) {
                Decimal remainingQuantity;
                Decimal ressss;
                Decimal activeQuantity;
    
                if (rate.get('Min_Data_Range__c') == 0) {
                    remainingQuantity = (Decimal) rate.get('Max_Data_Range__c');
                } else {
                    remainingQuantity = (Decimal) rate.get('Max_Data_Range__c') - (Decimal) rate.get('Min_Data_Range__c') + 1;
                }
    
                if (rate.get('Min_Data_Range__c') == 0) {
                    ressss = quantity - (Decimal) rate.get('Max_Data_Range__c');
                }
    
                if (rate.get('Min_Data_Range__c') != 0) {
                    ressss = (Decimal) quantity - remainingQuantity;
                }
    
                if ((quantity - remainingQuantity) > 0 && keepgoing) {
                    activeQuantity = remainingQuantity * 1;
                }
    
                if ((quantity - remainingQuantity) <= 0 && keepgoing) {
                    activeQuantity = quantity;
                }
    
                if (rate.get('Calculation_Type__c') == 'Unit' && keepgoing) {
                    currCost = currCost + (activeQuantity * (Decimal) rate.get('Fixed_Amount__c'));
                }
    
                if (rate.get('Calculation_Type__c') == 'Banded' && keepgoing) {
                    currCost = currCost + (Decimal) rate.get('Fixed_Amount__c');
                }
    
                if ((quantity - remainingQuantity) <= 0 && keepgoing) {
                    keepgoing = false;
                }
    
                if ((quantity - remainingQuantity) > 0 && keepgoing) {
                    quantity = ressss * 1;
                }
            }
    
            return new Map<String, Object>{
                'CostValue' => currCost,
                'productCode' => finalResult[0].get('productCode'),
                'ProductKey' => finalResult[0].get('ProductKey'),
                'ServiceId' => finalResult[0].get('ServiceId'),
                'RequestedCost' => finalResult[0].get('RequestedCost'),
                'Unit' => finalResult[0].get('Unit'),
                'Cost' => finalResult[0].get('Cost'),
                'ChargeToAccount' => finalResult[0].get('Charge_to_Account__c'),
                'RequestedForInvoice' => true,
                'TotCostValue' => ''
            };
        }

        return new Map<String, Object>{
            'CostValue' => currCost,
            'productCode' => null,
            'ProductKey' => null,
            'ServiceId' => null,
            'RequestedCost' => null,
            'Unit' => null,
            'Cost' => null,
            'ChargeToAccount' => null,
            'RequestedForInvoice' => null,
            'TotCostValue' => ''
        };
    }

    global class FlowInput {
        @InvocableVariable(label = 'Work Order') global WorkOrder wo;
        @InvocableVariable(label = 'SLI List Input') global List<FSL_Service_Line_Item__c> sliList;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'SLI List Output') global List<FSL_Service_Line_Item__c> outputList;
        @InvocableVariable(label = 'Audit Logs Output') global List<Audit_Log__c> auditList;
    }
}