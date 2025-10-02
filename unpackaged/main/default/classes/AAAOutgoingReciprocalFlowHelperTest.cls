@isTest
class AAAOutgoingReciprocalFlowHelperTest {
    @isTest
    static void outgoingReciprocalFlowHelperTest() {
        RecordType outboundRecType = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Outbound_Payment_Requests' 
            AND SobjectType = 'Reciprocal__c'
            LIMIT 1
        ];
        AAAOutgoingReciprocalFlowHelper.FlowInput flowInput = new AAAOutgoingReciprocalFlowHelper.FlowInput();

        flowInput.invc = new Invoice__c(
            Type__c = 'Reciprocals',
            Reciprocal_Sync_Ready__c = true,
            Status__c = 'Ready for Processing'
        );
        flowInput.wo = new WorkOrder(
            BO_Editable_WO_Specific_Membership_Level__c = 'test',
            CreatedDate = (Datetime) System.today()
        );
        flowInput.contact = new Contact(
            Membership_Level__c = 'Premier',
            FirstName = 'test',
            LastName = 'test',
            Member_Card_Num__c = '0123456789',
            Membership_Expiration_Date__c = null
        );
        flowInput.boSettings = new BackOffice_Settings__c(
            Club_Code__c = '240',
            RECIPSCFAC__c = false,
            PAY_FAC_BONUS_FOR_ADJ__c = true,
            RECIPSTYPE__c = 'P',
            RECIPSCFIX__c = 3.0
        );
        flowInput.iliList = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(
                Cost__c = 45.32,
                Tax__c = 1.01,
                Quantity__c = 3.0,
                Charge_to_Account__c = 'E',
                Code__c = '2C'
            ),
            new Invoice_Line_Item__c(
                Cost__c = 333.32,
                Tax__c = 10.01,
                Quantity__c = 200.0,
                Charge_to_Account__c = 'P',
                Code__c = 'OM'
            ),
            new Invoice_Line_Item__c(
                Cost__c = 450.32,
                Tax__c = 1.44,
                Quantity__c = 145.0,
                Charge_to_Account__c = 'B',
                Code__c = 'TW'
            )
        };
        flowInput.recTypeId = outboundRecType.Id;
        flowInput.authCode = 'test';
        flowInput.recTCode = 'T6';

        List<AAAOutgoingReciprocalFlowHelper.FlowOutput> outputList = AAAOutgoingReciprocalFlowHelper.runOutgoingReciprocalFlowHelper(new List<AAAOutgoingReciprocalFlowHelper.FlowInput>{flowInput});
        AAAOutgoingReciprocalFlowHelper.FlowOutput output = outputList[0];

        System.assertEquals(output.hasInvcToUpdate, true, 'Failed to update Invoice.');
        System.assertEquals(output.invc.Reciprocal_Sync_Ready__c, false, 'Failed to update Invoice.');
        System.assertEquals(output.hasRecToInsert, true, 'Failed to insert Reciprocal.');
        System.assertEquals(output.recToInsert.Status__c, 'New', 'Failed to insert Reciprocal.');
    }
}