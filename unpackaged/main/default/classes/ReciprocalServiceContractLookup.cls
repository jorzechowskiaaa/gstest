global without sharing class ReciprocalServiceContractLookup {
    @InvocableMethod(
        label = 'Reciprocal Service Contract Lookup' 
        description = 'For Reciprocals get service Contract' 
        category = 'Reciprocal'
    )
    global static List<FlowOutput> reciprocalServiceContractInvocable(List<FlowInput> inputList) {
        List<FlowOutput> outputList = new List<FlowOutput>();
        
        // Retrieve batch size from custom label
        Integer batchSize = Integer.valueOf(Label.Batch_Size);

        for (FlowInput input : inputList) {
            FlowOutput output = new FlowOutput();
            String method = input.method;
            List<Reciprocal__c> reciprocals = input.reciprocals;
            Set<Id> recIdSet = new Set<Id>();
            
            try {
                String result = 'Batch job processing';

                if (String.isBlank(method)) {
                    Map<Id, Reciprocal__c> reciprocalsMap = new Map<Id, Reciprocal__c>(reciprocals);
            
                    if (reciprocalsMap.size() > 0) {
                        System.enqueueJob(new ReciprocalServiceContractLkpQueueable(reciprocalsMap));
                    }
                } else if (method == 'allIBRecBatch') {
                    Database.executeBatch(new AAALinkFBAndSvcKBatch(), batchSize);
                } else if (method == 'getNumIBReciprocals') {
                    output.numIBRecs = Database.countQuery(
                        'SELECT COUNT()'+
                        ' FROM Reciprocal__c'+
                        ' WHERE Record_Type_Developer_Name__c = \'Inbound_Payment_Requests\''+
                        ' AND Transaction_Type__c != \'DSP\''+
                        ' AND Is_Link_Batch_Processed__c = false'+
                        ' AND ('+
                            'Service_Contract__c = null'+
                            ' OR Feedback__c = null'+
                        ')'
                    );
                } else if (method == 'queryFirstIBReciprocals') {
                    output.reciprocals = [
                        SELECT 
                            Id, 
                            Name, 
                            Transaction_Type__c, 
                            OwnerId, 
                            Status__c, 
                            Outgoing_Reciprocal__c, 
                            Submitting_Club_Code__c, 
                            Member_ClubCode__c, 
                            Service_Club_Code__c,
                            Long_Tow_Indicator__c,
                            Blended_Rate_Indicator__c,
                            Is_Duplicate__c,
                            Amended_Charges_Indicator__c,
                            Member_ID__c,
                            Member__c,
                            Member_First_Name__c,
                            Member_Last_Name__c,
                            Membership_Type__c,
                            Membership_Expiration_Date__c,
                            Work_Order__c,
                            Service_Call_Date__c,
                            Miles_To_Scene__c, 
                            Service_Call_Tow_Miles__c,
                            Service_Call_ID__c,
                            Service_Facility_ID__c,
                            Problem_Code__c,
                            Processor_ID__c,
                            Total_Dollar_Amount__c,
                            Tax_Amount__c,
                            Cost_Buffer__c,
                            Bonus__c,
                            Error_Buffer__c,
                            Dispute_Code__c,
                            Charge_Entitlements__c,
                            CDX_Authorization_Code__c,
                            Service_Call_Trouble_Code__c,
                            CreatedById,
                            CreatedDate
                        FROM Reciprocal__c
                        WHERE Record_Type_Developer_Name__c = 'Inbound_Payment_Requests'
                        AND Transaction_Type__c != 'DSP'
                        AND Is_Link_Batch_Processed__c = false
                        AND (
                            Service_Contract__c = null
                            OR Feedback__c = null
                        )
                        ORDER BY CreatedDate ASC 
                        LIMIT 50000
                    ];
                } else if (method == 'queryLastIBReciprocals') {
                    output.reciprocals = [
                        SELECT 
                            Id, 
                            Name, 
                            Transaction_Type__c, 
                            OwnerId, 
                            Status__c, 
                            Outgoing_Reciprocal__c, 
                            Submitting_Club_Code__c, 
                            Member_ClubCode__c, 
                            Service_Club_Code__c,
                            Long_Tow_Indicator__c,
                            Blended_Rate_Indicator__c,
                            Is_Duplicate__c,
                            Amended_Charges_Indicator__c,
                            Member_ID__c,
                            Member__c,
                            Member_First_Name__c,
                            Member_Last_Name__c,
                            Membership_Type__c,
                            Membership_Expiration_Date__c,
                            Work_Order__c,
                            Service_Call_Date__c,
                            Miles_To_Scene__c, 
                            Service_Call_Tow_Miles__c,
                            Service_Call_ID__c,
                            Service_Facility_ID__c,
                            Problem_Code__c,
                            Processor_ID__c,
                            Total_Dollar_Amount__c,
                            Tax_Amount__c,
                            Cost_Buffer__c,
                            Bonus__c,
                            Error_Buffer__c,
                            Dispute_Code__c,
                            Charge_Entitlements__c,
                            CDX_Authorization_Code__c,
                            Service_Call_Trouble_Code__c,
                            CreatedById,
                            CreatedDate
                        FROM Reciprocal__c
                        WHERE Record_Type_Developer_Name__c = 'Inbound_Payment_Requests'
                        AND Transaction_Type__c != 'DSP'
                        AND Is_Link_Batch_Processed__c = false
                        AND (
                            Service_Contract__c = null
                            OR Feedback__c = null
                        )
                        ORDER BY CreatedDate DESC 
                        LIMIT 50000
                    ];
                } else if (method == 'selIBRecBatch') {
                    recIdSet = new Map<Id, Reciprocal__c>(reciprocals).keySet();

                    Database.executeBatch(new AAALinkFBAndSvcKBatch(recIdSet), batchSize);
                } else {
                    result = 'Error -- no valid method specified';
                }

                output.result = result;
            } catch (Exception e) {
                output.error = e.getMessage() + '\n\n' + e.getStackTraceString();
            }

            outputList.add(output);
        }

        return outputList;
    }

    global class FlowInput {
        @InvocableVariable(label = 'Method') global String method;
        @InvocableVariable(label = 'Reciprocals') global List<Reciprocal__c> reciprocals;
    }
    
    global class FlowOutput {
        @InvocableVariable(label = 'Result') global String result;
        @InvocableVariable(label = 'Error') global String error;
        @InvocableVariable(label = 'Reciprocals') global List<Reciprocal__c> reciprocals;
        @InvocableVariable(label = 'Number of IB Reciprocals') global Integer numIBRecs;
    }
}