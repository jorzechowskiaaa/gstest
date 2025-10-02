global without sharing class AAAOutgoingReciprocalFlowHelper {
    @InvocableMethod(label = 'Batch Outgoing Reciprocal Flow Helper')
    global static List<FlowOutput> runOutgoingReciprocalFlowHelper(List<FlowInput> input) {
        List<FlowOutput> outputList = new List<FlowOutput>();

        for (FlowInput flowInput : input) {
            FlowOutput output = new FlowOutput();
            Reciprocal__c recToUpdate = new Reciprocal__c();
            Reciprocal__c recToInsert = new Reciprocal__c();
            Invoice__c invcToUpdate = new Invoice__c();
            BackOffice_Settings__c boSettings = flowInput.boSettings;
            Invoice__c invc = flowInput.invc;
            WorkOrder wo = flowInput.wo;
            Contact contact = flowInput.contact;
            ServiceTerritory fac = flowInput.fac;
            Reciprocal__c rec = flowInput.rec;
            List<Invoice_Line_Item__c> iliList = flowInput.iliList;
            Boolean isRecAdj = invc.Type__c == 'Reciprocal Adjustments';
            String outRecipRecTypeId = flowInput.recTypeId;
            String svcCallTCode = flowInput.recTCode;
            String authCode = flowInput.authCode;
            String clubCode = boSettings.Club_Code__c;
            String amendedCharge = isRecAdj ? 'A' : '';
            Decimal totalDollarAmt = 0.0;
            Decimal totalTaxAmt = 0.0;
            Decimal omQty = 0.0;
            Decimal towQty = 0.0;
            Decimal bCost = 0.0;
            Decimal eCost = 0.0;
            Decimal pCost = 0.0;
            Decimal rCost = 0.0;
            Decimal bonusCost = 0.0;

            if (iliList != null && iliList.size() > 0) {
                for (Invoice_Line_Item__c ili : iliList) {
                    String chargeAcct = ili.Charge_to_Account__c;
                    Decimal iliCost = ili.Cost__c;
    
                    if (iliCost != null) {
                        totalDollarAmt += iliCost;
    
                        if (chargeAcct == 'O' && !isRecAdj) {
                            bCost += iliCost;
                        }
                        if (chargeAcct == 'B') {
                            bCost += iliCost;
                        }
                        if (chargeAcct == 'E') {
                            eCost += iliCost;
                        }
                        if (chargeAcct == 'P') {
                            pCost += iliCost;
                        }
                        if (chargeAcct == 'R') {
                            rCost += iliCost;
                        }
                    }
                    if (ili.Tax__c != null) {
                        totalTaxAmt += ili.Tax__c;
                    }
                    if (ili.Code__c == 'OM' && ili.Quantity__c != null) {
                        omQty = ili.Quantity__c;
                    }
                    if (ili.Code__c == 'TW' && ili.Quantity__c != null) {
                        towQty = ili.Quantity__c;
                    }
                }
            }

            totalDollarAmt += totalTaxAmt;
            
            if (!isRecAdj) {
                if (boSettings.RECIPSCFAC__c == false && boSettings.PAY_FAC_BONUS_FOR_ADJ__c == true) {
                    if (boSettings.RECIPSTYPE__c == 'F') {
                        bonusCost = boSettings.RECIPSCFIX__c;
                    } else if (boSettings.RECIPSTYPE__c == 'P') {
                        bonusCost = (totalDollarAmt * boSettings.RECIPSCFIX__c) / 100.0;
                    }
                } else if (boSettings.RECIPSCFAC__c == true && boSettings.PAY_RECIP_SURCHAGE_FOR_ADJ__c == true) {
                    bonusCost = fac?.Reciprocal_Bonus__c;
                }
            }

            totalDollarAmt += bonusCost;

            Integer totalDollarAmtX100 = Integer.valueOf(totalDollarAmt * 100);
            Integer bCostX100 = Integer.valueOf(bCost * 100);
            Integer pCostX100 = Integer.valueOf(pCost * 100);
            Integer eCostX100 = Integer.valueOf(eCost * 100);
            Integer rCostX100 = Integer.valueOf(rCost * 100);
            Integer bonusCostX100 = Integer.valueOf(bonusCost * 100);
            Integer totalDollarNum0s = 6 - String.valueOf(totalDollarAmtX100).length();
            Integer bCostNum0s = 5 - String.valueOf(bCostX100).length();
            Integer pCostNum0s = 5 - String.valueOf(pCostX100).length();
            Integer eCostNum0s = 5 - String.valueOf(eCostX100).length();
            Integer rCostNum0s = 5 - String.valueOf(rCostX100).length();
            Integer bonusCostNum0s = 5 - String.valueOf(bonusCostX100).length();
            
            AAAReciprocalCostCalUtility.CostInput recCostCalInput = new AAAReciprocalCostCalUtility.CostInput();
            recCostCalInput.lstAmounts = new List<Integer>{
                totalDollarAmtX100,
                bCostX100,
                pCostX100,
                eCostX100,
                rCostX100,
                bonusCostX100
            };
            recCostCalInput.lstLeadingZeroes = new List<Integer>{
                totalDollarNum0s,
                bCostNum0s,
                pCostNum0s,
                eCostNum0s,
                rCostNum0s,
                bonusCostNum0s
            };

            List<AAAReciprocalCostCalUtility.CostOutput> recCostCalOutput = AAAReciprocalCostCalUtility.runIntegrationServiceInvocable(new List<AAAReciprocalCostCalUtility.CostInput>{recCostCalInput});
            List<String> modAmtStrList = (List<String>) recCostCalOutput[0].output;
            String finalTotalDollarAmt;
            String finalTotalBCost;
            String finalTotalPCost;
            String finalTotalECost;
            String finalTotalRCost;
            String finalTotalBonusCost;

            for (Integer i = 0; i < modAmtStrList.size(); i++) {
                String result = modAmtStrList[i];

                if (i == 0) {
                    finalTotalDollarAmt = result;
                } else if (i == 1) {
                    finalTotalBCost = result;
                } else if (i == 2) {
                    finalTotalPCost = result;
                } else if (i == 3) {
                    finalTotalECost = result;
                } else if (i == 4) {
                    finalTotalRCost = result;
                } else if (i == 5) {
                    finalTotalBonusCost = result;
                }
            }

            Boolean isLongTow = svcCallTCode == 'T6' && towQty > 100
                && contact.Membership_Level__c == 'Premier';
            String costBuffer = 
                'BAS/' + finalTotalBCost + 
                '/:PLS/' + finalTotalPCost + 
                '/:PRM/' + finalTotalECost + 
                '/:PLR/' + finalTotalRCost + 
                '/:BON/' + finalTotalBonusCost;

            if (rec != null) {
                rec.Cost_Buffer__c = costBuffer;
                rec.Long_Tow_Indicator__c = isLongTow;
                rec.Service_Call_Tow_Miles__c = towQty;
                rec.Miles_To_Scene__c = omQty;
                rec.Total_Dollar_Amount__c = totalDollarAmt;
                rec.Tax_Amount__c = totalTaxAmt;

                if (isRecAdj) {
                    rec.Amended_Charges_Indicator__c = amendedCharge;
                }

                output.recToUpdate = rec;
                output.hasRecToUpdate = true;
            } else {
                List<String> clubStationPrograms = new List<String>{
                    '212', '050', '298', '299', '311', '400', '750',
                    '798', '850', '951', '997', '998', '999', '785'
                };
                Map<String, String> mbrTypeMap = new Map<String, String>{
                    'Basic' => 'BAS',
                    'Plus' => 'PLUS',
                    'Premier' => 'PREM',
                    'Premier RV' => 'PRRV'
                };
                
                String mbrType = mbrTypeMap.get(wo.BO_Editable_WO_Specific_Membership_Level__c);
                String progDesc = wo.Program_Description__c;
                Boolean isACACSProgram = clubCode == '212' && clubStationPrograms.contains(progDesc);

                if (clubCode == '240' || !isACACSProgram) {
                    Datetime svcCallDate = wo.CreatedDate;

                    output.recToInsert = new Reciprocal__c(
                        Transaction__c = 'PAY',
                        Transaction_Type__c = 'PAY',
                        Submitting_Club_Code__c = clubCode,
                        Service_Club_Code__c = clubCode,
                        Service_Call_Date__c = svcCallDate?.date(),
                        Service_Call_ID__c = wo.WorkOrderNumber,
                        Service_Call_Trouble_Code__c = svcCallTCode,
                        Work_Order__c = invc.Work_Order__c,
                        Member__c = wo.Member_Account__c,
                        Member_ID__c = contact.Member_Card_Num__c,
                        Member_First_Name__c = contact.FirstName,
                        Member_Last_Name__c = contact.LastName,
                        Long_Tow_Indicator__c = isLongTow,
                        Service_Call_Tow_Miles__c = towQty,
                        Miles_To_Scene__c = omQty,
                        Service_Facility_ID__c = fac?.Facility_Number__c,
                        Cost_Buffer__c = costBuffer,
                        RecordTypeId = outRecipRecTypeId,
                        CDX_Authorization_Code__c = authCode,
                        Membership_Expiration_Date__c = contact.Membership_Expiration_Date__c,
                        Total_Dollar_Amount__c = totalDollarAmt,
                        Tax_Amount__c = totalTaxAmt,
                        Membership_Type__c = mbrType,
                        Amended_Charges_Indicator__c = amendedCharge,
                        Member_ClubCode__c = progDesc,
                        Status__c = 'New',
                        Processor_ID__c = wo.Comm_Ctr__c,
                        Charge_Entitlements__c = amendedCharge != 'A'
                    );
                    output.hasRecToInsert = true;
                }
            }

            invc.Reciprocal_Sync_Ready__c = false;
            output.invc = invc;
            output.hasInvcToUpdate = true;

            outputList.add(output);
        }

        return outputList;
    }

    global class FlowInput {
        @InvocableVariable(label = 'Invoice') global Invoice__c invc;
        @InvocableVariable(label = 'Work Order') global WorkOrder wo;
        @InvocableVariable(label = 'Contact') global Contact contact;
        @InvocableVariable(label = 'Service Territory') global ServiceTerritory fac;
        @InvocableVariable(label = 'Existing Reciprocal') global Reciprocal__c rec;
        @InvocableVariable(label = 'Back Office Settings') global BackOffice_Settings__c boSettings;
        @InvocableVariable(label = 'Invoice Line Items') global List<Invoice_Line_Item__c> iliList;
        @InvocableVariable(label = 'Record Type Id') global String recTypeId;
        @InvocableVariable(label = 'Authorization Code') global String authCode;
        @InvocableVariable(label = 'Reciprocal Trouble Code') global String recTCode;
    }
    
    global class FlowOutput {
        @InvocableVariable(label = 'Has Reciprocal To Insert') global Boolean hasRecToInsert;
        @InvocableVariable(label = 'Reciprocal To Insert') global Reciprocal__c recToInsert;
        @InvocableVariable(label = 'Has Reciprocal To Update') global Boolean hasRecToUpdate;
        @InvocableVariable(label = 'Reciprocal To Update') global Reciprocal__c recToUpdate;
        @InvocableVariable(label = 'Has Invoice To Update') global Boolean hasInvcToUpdate;
        @InvocableVariable(label = 'Invoice To Update') global Invoice__c invc;
    }
}