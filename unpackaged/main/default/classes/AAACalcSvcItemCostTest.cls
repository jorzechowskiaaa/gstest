@isTest
public class AAACalcSvcItemCostTest {
    @isTest
    static void calcSvcItemCostTest() {
        WorkOrder wo = AAAFlowInvocableTest.setupTowSLIs('G101', '000');
        List<FSL_Service_Line_Item__c> sliList = [
            SELECT
                Id,
                Product__c,
                Product_Code__c,
                Work_Order__c,
                Cost__c,
                Unit__c,
                Calculated_Unit__c,
                Tax__c,
                Override_Pricing__c,
                Total_Price__c,
                Cleared_Timestamp_TOD_Code__c,
                Requested_Unit__c,
                Requested_Cost__c,
                Charge_to_Account__c,
                Ready_for_Invoicing__c
            FROM FSL_Service_Line_Item__c
            WHERE Work_Order__c = :wo.Id
        ];
        AAACalcSvcItemCost.FlowInput flowInput = new AAACalcSvcItemCost.FlowInput();

        wo = [
            SELECT
                Id,
                Clearing_Code__c,
                BO_Editable_WO_Specific_Membership_Level__c,
                Facility_Contract__c,
                Cleared_Timestamp_TOD_Code__c,
                CaseId,
                Resolution_Code__c,
                ServiceTerritory.State,
            	ServiceTerritory.Is_Fleet__c //AGB added for SSFI-651
            FROM WorkOrder
            WHERE Id = :wo.Id
            LIMIT 1
        ];
        flowInput.sliList = sliList;
        flowInput.wo = wo;

        List<AAACalcSvcItemCost.FlowOutput> flowOutput = AAACalcSvcItemCost.runCalcSvcItemCost(
            new List<AAACalcSvcItemCost.FlowInput>{flowInput}
        );
        List<FSL_Service_Line_Item__c> resSLIList = flowOutput[0].outputList;
        List<Audit_Log__c> resAuditList = flowOutput[0].auditList;
        FSL_Service_Line_Item__c resSLI = resSLIList[0];

        System.assertEquals(resSLI.Ready_for_Invoicing__c, true, 'Failed to price SLI.');
        System.assertEquals(resSLI.Cost__c, 15.0, 'Failed to price SLI.');
        System.assertEquals(resAuditList != null, true, 'Failed to generate Audit Log.');
    }

    public static Clear_Code_Mapping__mdt mockCCMapping() {
        return new Clear_Code_Mapping__mdt(
            Base_Pay_Percent__c = 100
        );
    }
}