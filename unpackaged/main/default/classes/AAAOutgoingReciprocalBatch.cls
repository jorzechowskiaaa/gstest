public class AAAOutgoingReciprocalBatch implements Database.Batchable<SObject>, Schedulable {
    public String query;
    private BackOffice_Settings__c boSettings = BackOffice_Settings__c.getOrgDefaults();
    private RecordType outboundRecType = [
        SELECT Id 
        FROM RecordType 
        WHERE DeveloperName = 'Outbound_Payment_Requests' 
        AND SobjectType = 'Reciprocal__c'
        LIMIT 1
    ];
    private Map<String, String> recTCodeMdtMap = labelToTCodeMap([
        SELECT Id, T_Code__c, Label
        FROM Local_to_Reciprocal_T_Code_Mapping__mdt
    ]);
	private Map<String, String> codeRecMap = servCodeMap([ //AGB added for SSFI-591 
        SELECT Id, Cost_Type__c, Label
        FROM Cost_Buffer_Reciprocal_Service_Code__mdt
    ]); //End AGB added for SSFI-591 

    public Database.QueryLocator start(Database.BatchableContext bc) {
        query =
            'SELECT Id' +
            ' FROM Statement__c' +
            ' WHERE Id IN (' +
                'SELECT Statement__c' +
                ' FROM Invoice__c' +
                ' WHERE Type__c IN (\'Reciprocal Adjustments\', \'Reciprocals\')' +
                ' AND Reciprocal_Sync_Ready__c = true' +
                ' AND Status__c = \'Ready for Processing\'' +
            ')';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Statement__c> scope) {
        String clubCode = boSettings.Club_Code__c;
        List<Reciprocal__c> recUpdateList = new List<Reciprocal__c>();
        List<Reciprocal__c> recInsertList = new List<Reciprocal__c>();
        List<Invoice__c> invcUpdateList = new List<Invoice__c>();
        List<Invoice__c> totalInvcList = new List<Invoice__c>();
        List<Feedback__c> totalFBList = new List<Feedback__c>();
        List<Reciprocal__c> totalRecList = new List<Reciprocal__c>();
        List<FSL_TroubleCode__c> totalTCodeList = new List<FSL_TroubleCode__c>();
        List<Invoice_Line_Item__c> totalILIList = new List<Invoice_Line_Item__c>();
        List<String> noPayClearCodeList = new List<String>{'CC', 'XX'};
        List<String> stmtIdList = new List<String>();
        List<String> invcIdList = new List<String>();
        Set<String> facNumSet = new Set<String>();
        Set<Id> woIdSet = new Set<Id>();
        Map<String, Feedback__c> totalFBMap = new Map<String, Feedback__c>();
        Map<String, List<Invoice__c>> totalInvcMap = new Map<String, List<Invoice__c>>();
        Map<String, Reciprocal__c> totalRecMap = new Map<String, Reciprocal__c>();
        Map<String, String> totalTCodeMap = new Map<String, String>();
        Map<String, List<Invoice_Line_Item__c>> totalILIMap = new Map<String, List<Invoice_Line_Item__c>>();
        Map<String, Reciprocal__c> recUpdateMap = new Map<String, Reciprocal__c>();
        

        for (Statement__c stmt : scope) {
            stmtIdList.add(stmt.Id);
        }

        totalInvcList = [
            SELECT
                Id,
                Type__c,
                Reciprocal_Sync_Ready__c,
                Work_Order__c,
                Work_Order__r.CreatedDate,
                Work_Order__r.WorkOrderNumber,
                Work_Order__r.Member_Account__c,
                Work_Order__r.BO_Editable_WO_Specific_Membership_Level__c,
                Work_Order__r.Amended_Charges_Indicator__c,
                Work_Order__r.Program_Description__c, //club code
                Work_Order__r.Comm_Ctr__c,
                Work_Order__r.Clearing_Code__c,
                Work_Order__r.Resolution_Code__c,
                Work_Order__r.Contact.Membership_Level__c,
                Work_Order__r.Contact.Member_Card_Num__c,
                Work_Order__r.Contact.Membership_Expiration_Date__c,
                Work_Order__r.Contact.FirstName,
                Work_Order__r.Contact.LastName,
                Service_Territory__r.Reciprocal_Bonus__c,
                Service_Territory__r.Facility_Number__c,
                Statement__c
            FROM Invoice__c
            WHERE Type__c IN ('Reciprocals', 'Reciprocal Adjustments')
            AND Reciprocal_Sync_Ready__c = true
            AND Status__c = 'Ready for Processing'
            AND (Work_Order__r.Program_Description__c = '240' OR (Work_Order__r.Clearing_Code__c != 'CC' AND Work_Order__r.Resolution_Code__c != 'X001' AND Work_Order__r.Call_Type__c != 'RAP'))  //AGB 3/27/2025 for SSFI-424
            AND Statement__c IN :stmtIdList
        ];

        for (Invoice__c invc : totalInvcList) {
            Id woId = invc.Work_Order__c;
            String facNum = invc.Service_Territory__r?.Facility_Number__c;

            invcIdList.add(invc.Id);

            if (woId != null) {
                woIdSet.add(woId);
            }
            if (facNum != null) {
                facNumSet.add(facNum);
            }
        }

        if (clubCode == '212') {
            totalILIList = [
                SELECT
                    Id,
                    Cost__c,
                    Tax__c,
                    Quantity__c,
                    Code__c,
                    Charge_to_Account__c,
                    Invoice__c
                FROM Invoice_Line_Item__c
                WHERE Invoice__c IN :invcIdList
                AND Pay_Reciprocal__c = true
            ];
        } else {
            totalILIList = [
                SELECT
                    Id,
                    Cost__c,
                    Tax__c,
                    Quantity__c,
                    Code__c,
                    Charge_to_Account__c,
                    Invoice__c
                FROM Invoice_Line_Item__c
                WHERE Invoice__c IN :invcIdList
            ];
        }

        totalFBList = [
            SELECT Id, Authorization_Code__c, Work_Order__c
            FROM Feedback__c
            WHERE Work_Order__c IN :woIdSet
            ORDER BY CreatedDate DESC
        ];
        totalTCodeList = [
            SELECT Id, Code__c, Work_Order__c
            FROM FSL_TroubleCode__c
            WHERE Work_Order__c IN :woIdSet
            AND Type__c = 'PROBLEM'
        ];
        totalRecList = [
            SELECT 
                Id,
                Cost_Buffer__c,
                Member_Last_Name__c,
                Long_Tow_Indicator__c,
                Service_Call_Tow_Miles__c,
                Miles_To_Scene__c,
                Total_Dollar_Amount__c,
                Tax_Amount__c,
                Amended_Charges_Indicator__c,
                Invoice__c
            FROM Reciprocal__c
            WHERE Invoice__c IN :invcIdList
            AND Status__c = 'New'
            AND Record_Type_Developer_Name__c = 'Outbound_Payment_Requests'
            AND Dispute_Code__c IN (null, '')
        ];

        for (Invoice__c invc : totalInvcList) {
            String stmtId = invc.Statement__c;

            if (totalInvcMap.get(stmtId) == null) {
                totalInvcMap.put(stmtId, new List<Invoice__c>{invc});
            } else {
                List<Invoice__c> tempList = totalInvcMap.get(stmtId);

                tempList.add(invc);
                totalInvcMap.put(stmtId, tempList);
            }
        }

        for (Invoice_Line_Item__c ili : totalILIList) {
            String invcId = ili.Invoice__c;

            if (totalILIMap.get(invcId) == null) {
                totalILIMap.put(invcId, new List<Invoice_Line_Item__c>{ili});
            } else {
                List<Invoice_Line_Item__c> tempList = totalILIMap.get(invcId);

                tempList.add(ili);
                totalILIMap.put(invcId, tempList);
            }
        }

        for (Feedback__c fb : totalFBList) {
            String woId = fb.Work_Order__c;

            if (totalFBMap.get(woId) == null) {
                totalFBMap.put(woId, fb);
            }
        }

        for (FSL_TroubleCode__c tCode : totalTCodeList) {
            String woId = tCode.Work_Order__c;

            if (totalTCodeMap.get(woId) == null) {
                totalTCodeMap.put(woId, tCode.Code__c);
            }
        }

        for (Reciprocal__c rec : totalRecList) {
            String invcId = rec.Invoice__c;

            if (rec.Amended_Charges_Indicator__c == 'A') {
                invcId += 'A';
            }

            if (totalRecMap.get(invcId) == null) {
                totalRecMap.put(invcId, rec);
            }
        }

        for (Statement__c stmt : scope) {
            List<Invoice__c> invcList = totalInvcMap.get(stmt.Id);
			if(invcList != null)
            {
 	           for (Invoice__c invc : invcList) {
                WorkOrder wo = invc.Work_Order__r;

                if (wo != null) {
                    Contact contact = wo.Contact;
                    Feedback__c feedback = totalFBMap.get(wo.Id);
                    ServiceTerritory fac = invc.Service_Territory__r;
                    Boolean isRecAdj = invc.Type__c == 'Reciprocal Adjustments';
                    Boolean noBonus = isRecAdj || noPayClearCodeList.contains(wo.Clearing_Code__c);
                    String resCode = wo.Resolution_Code__c;
                    String tCode = totalTCodeMap.get(wo.Id);
                    String svcCallTCode = recTCodeMdtMap.get(tCode);
                    String authCode = feedback?.Authorization_Code__c;
                    String amendedCharge = isRecAdj ? 'A' : '';
                    Reciprocal__c rec = totalRecMap.get(invc.Id + amendedCharge);
                    List<Invoice_Line_Item__c> iliList = totalILIMap.get(invc.Id);
                    Decimal totalDollarAmt = 0.0;
                    Decimal totalTaxAmt = 0.0;
                    Decimal omQty = 0.0;
                    Decimal towQty = 0.0;
                    Decimal bCost = 0.0;
                    Decimal eCost = 0.0;
                    Decimal pCost = 0.0;
                    Decimal rCost = 0.0;
                    Decimal bonusCost = 0.0;
                    String basCostComment = ''; //AGB added for SSFI-591
                    String plsCostcomment = ''; //AGB added for SSFI-591
                    String prmCostComment = ''; //AGB added for SSFI-591
                    String plrCostComment = ''; //AGB added for SSFI-591

                    if (iliList != null && iliList.size() > 0) {
                        for (Invoice_Line_Item__c ili : iliList) {
                            String chargeAcct = ili.Charge_to_Account__c;
                            Decimal iliCost = ili.Cost__c;
                            system.debug('!!!:'+ili.Charge_to_Account__c+'!'+ili.Cost__c);
            
                            if (iliCost != null) {
                                totalDollarAmt += iliCost;
            
                                if (chargeAcct == 'O' && !noPayClearCodeList.contains(wo.Clearing_Code__c)) {  //AGB SSFI-332 changed from && !noBonus 
                                    bCost += iliCost;
                                    if(codeRecMap.containsKey(ili.Code__c)){
                                        basCostComment += iliCost+' '+ili.Code__c+' ';
                                    }
                                }
                                if (chargeAcct == 'B') {
                                    bCost += iliCost;
                                    if(codeRecMap.containsKey(ili.Code__c)){
                                        basCostComment += iliCost+' '+ili.Code__c+' ';
                                    }                                    
                                }
                                if (chargeAcct == 'E') {
                                    eCost += iliCost;
                                    if(codeRecMap.containsKey(ili.Code__c)){
                                        prmCostComment += iliCost+' '+ili.Code__c+' '; //???
                                    }                                    
                                }
                                if (chargeAcct == 'P') {
                                    pCost += iliCost;
                                    if(codeRecMap.containsKey(ili.Code__c)){
                                        plsCostComment += iliCost+' '+ili.Code__c+' '; //???
                                    }                                    
                                }
                                if (chargeAcct == 'R') {
                                    rCost += iliCost;
                                    if(codeRecMap.containsKey(ili.Code__c)){
                                        plrCostComment += iliCost+' '+ili.Code__c+' '; //???
                                    }                                       
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
                            /* AGB added for SSFI-591 Add checks for codes here to build additional items
                            if(codeRecMap.get(ili.Code__c) != null)
                            {
                                String codeType = codeRecMap.get(ili.Code__c);
                                switch on codeType{
                                    when 'OTHER'{
                                        basCostComment += ' '+iliCost+' '+ili.Code__c;
                                    }
                                    when 'PLUS'{
                                        plsCostcomment += ' '+iliCost+' '+ili.Code__c;
                                    }
                                    when 'PREMIER'{
                                        prmCostComment += ' '+iliCost+' '+ili.Code__c;
                                    }
                                    when else{
                                        system.debug('!!!Code was not found for '+ili.Code__c+' '+codeType);
                                    }
                                }
                            }                            
                            //End AGB added for SSFI-591 Add checks for codes here to build additional items */
                        }
                    }

                    totalDollarAmt += totalTaxAmt;
            
                    if (!noBonus) {
                        if (boSettings.RECIPSCFAC__c == false && boSettings.PAY_FAC_BONUS_FOR_ADJ__c == true) {
                            if (boSettings.RECIPSTYPE__c == 'F') {
                                bonusCost = boSettings.RECIPSCFIX__c;
                            } else if (boSettings.RECIPSTYPE__c == 'P') {
                                bonusCost = (totalDollarAmt * boSettings.RECIPSCFIX__c) / 100.0;
                            }
                        } else if (boSettings.RECIPSCFAC__c == true && boSettings.PAY_RECIP_SURCHAGE_FOR_ADJ__c == true) {
                            bonusCost = fac.Reciprocal_Bonus__c;
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
                        && contact?.Membership_Level__c == 'Premier';
                    String costBuffer = 
                        'BAS/' + finalTotalBCost +'/'+ basCostComment +
                        ':PLS/' + finalTotalPCost +'/'+ plsCostcomment +
                        ':PRM/' + finalTotalECost +'/'+ prmCostComment +
                        ':PLR/' + finalTotalRCost +'/'+ plrCostComment +
                        ':BON/' + finalTotalBonusCost;

                    system.debug('costBuffer: '+costBuffer);
                    
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
        
                        recUpdateMap.put(rec.Id, rec);
                    } else {
                        List<String> clubStationPrograms = new List<String>{
                            '212', '050', '298', '299', '311', '400', '750',
                            '798', '850', '951', '997', '998', '999', '785'
                        };
                        Map<String, String> mbrTypeMap = new Map<String, String>{
                            'Basic' => 'BAS',
                            'Plus' => 'PLUS',
                            'Premier' => 'PREM',
                            'Premier RV' => 'PRRV',
                            'Plus RV' => 'PLRV'
                        };

                        String mbrType = mbrTypeMap.get(wo.BO_Editable_WO_Specific_Membership_Level__c);
                        String progDesc = wo.Program_Description__c;
                        Boolean isACACSProgram = clubCode == '212' && clubStationPrograms.contains(progDesc);
        
                        if (clubCode == '240' || !isACACSProgram) {
                            Datetime svcCallDate = wo.CreatedDate;
                            Boolean chargeEntitlement = amendedCharge != 'A'
                                && !resCode.startsWith('X') 
                                && !resCode.startsWith('R');

                            recInsertList.add(
                                new Reciprocal__c(
                                    Transaction__c = 'PAY',
                                    Transaction_Type__c = 'PAY',
                                    Submitting_Club_Code__c = clubCode,
                                    Service_Club_Code__c = clubCode,
                                    Service_Call_Date__c = svcCallDate?.date(),
                                    Service_Call_ID__c = wo.WorkOrderNumber,
                                    Service_Call_Trouble_Code__c = svcCallTCode,
                                    Work_Order__c = invc.Work_Order__c,
                                    Member__c = wo.Member_Account__c,
                                    Member_ID__c = contact?.Member_Card_Num__c,
                                    Member_First_Name__c = contact?.FirstName,
                                    Member_Last_Name__c = contact?.LastName,
                                    Long_Tow_Indicator__c = isLongTow,
                                    Service_Call_Tow_Miles__c = towQty,
                                    Miles_To_Scene__c = omQty,
                                    Service_Facility_ID__c = fac?.Facility_Number__c,
                                    Cost_Buffer__c = costBuffer,
                                    RecordTypeId = outboundRecType.Id,
                                    CDX_Authorization_Code__c = authCode,
                                    Membership_Expiration_Date__c = contact?.Membership_Expiration_Date__c,
                                    Total_Dollar_Amount__c = totalDollarAmt,
                                    Tax_Amount__c = totalTaxAmt,
                                    Membership_Type__c = mbrType,
                                    Amended_Charges_Indicator__c = amendedCharge,
                                    Member_ClubCode__c = progDesc,
                                    Status__c = 'New',
                                    Processor_ID__c = wo.Comm_Ctr__c,
                                    Charge_Entitlements__c = chargeEntitlement,
                                    Invoice__c = invc.Id
                                )
                            );
                        }
                    }

                    invc.Reciprocal_Sync_Ready__c = false;
                    invcUpdateList.add(invc);
                }
            }
            }
        }

        if (recUpdateMap.keySet().size() > 0) {
            for (String key : recUpdateMap.keySet()) {
                recUpdateList.add(recUpdateMap.get(key));
            }

            update recUpdateList;
        }

        if (recInsertList.size() > 0) {
            insert recInsertList;
        }

        if (invcUpdateList.size() > 0) {
            update invcUpdateList;
        }
    }

    private Map<String, String> labelToTCodeMap(List<Local_to_Reciprocal_T_Code_Mapping__mdt> query) {
        Map<String, String> resMap = new Map<String, String>();

        for (Local_to_Reciprocal_T_Code_Mapping__mdt mdt : query) {
            if (resMap.get(mdt.Label) == null) {
                resMap.put(mdt.Label, mdt.T_Code__c);
            }
        }

        return resMap;
    }
    
    private Map<String, String> servCodeMap(List<Cost_Buffer_Reciprocal_Service_Code__mdt> query) { //AGB added for SSFI-591
        Map<String, String> resMap = new Map<String, String>();

        for (Cost_Buffer_Reciprocal_Service_Code__mdt mdt : query) {
            if (resMap.get(mdt.Label) == null) {
                resMap.put(mdt.Label, mdt.Cost_Type__c);
            }
        }

        return resMap;
    } //end AGB added for SSFI-591

    public void finish(Database.BatchableContext bc) {
        // finished batch logic
        System.debug('Finished outgoing reciprocal batch');
    }

    public void execute(SchedulableContext ctx) {
        AAAOutgoingReciprocalBatch batch = new AAAOutgoingReciprocalBatch();

        Database.executeBatch(batch, 30);
    }
}