@isTest
public class AAA_AuditRuleProcessorTest {

    @testSetup static void setup() {
        //products
        List<Product2> productList = new List<Product2>{
            new Product2(IsActive = true, ProductCode = 'CT',Name = 'RAP - TIRE CHANGE'),
            new Product2(IsActive = true, ProductCode = 'GN',Name = 'RAP - GONE ON ARRIVAL'),
            new Product2(IsActive = true, ProductCode = 'XX',Name = 'RAP - CANCEL WITHOUT PAYMENT')
        };
        insert productList;
        //([SELECT Id,IsActive,ProductCode FROM Product2 where IsActive = true order by ProductCode]);
        //Audit Rules
        List<Audit_Rule__c> auditRuleList = new List<Audit_Rule__c>{
        	new Audit_Rule__c(Active__c = true, Expression_Type__c = 'Custom', Description__c = '1',Expression__c = '(1 and 2) and not 3'),
            new Audit_Rule__c(Active__c = true, Expression_Type__c = 'OR', Description__c = '2'),
            new Audit_Rule__c(Active__c = true, Expression_Type__c = 'AND', Description__c = '3')
        };
        insert auditRuleList;
        //Audit Criteria
        List<Audit_Rule_Critieria__c> auditRuleCriteriaList = new List<Audit_Rule_Critieria__c>();
        List<Audit_Action__c> auditActionList = new List<Audit_Action__c>();
        for(Audit_Rule__c arRec:auditRuleList)
        {
            Audit_Rule_Critieria__c newARC = new Audit_Rule_Critieria__c();
            newARC.Order_No__c = 1;
            newARC.Business_Entity__c = 'WorkOrder';
            newARC.Attribute__c = 'Resolution_Code__c';
            newARC.Operator__c = '=';
            /* */
            Audit_Action__c newAA = new Audit_Action__c();
            newAA.Action__c='ADD';
            newAA.Business_Entity__c = 'FSL_Service_Line_Item__c';
            newAA.Identifying_Attribute__c = 'Product__r.ProductCode';
			//newAA.RecordType
            switch on arRec.Description__c{
                when '1' {
                    newARC.Audit_Rule__c=arRec.id;
                	newARC.Value__c='G101'; //SLI - RAP TIRE CHANGE
                    auditRuleCriteriaList.add(newARC);
                    newAA.Identifying_Value__c='CT';
                    newAA.Name='1';
                    auditActionList.add(newAA);
                    
                    Audit_Rule_Critieria__c new2ARC = new Audit_Rule_Critieria__c();
                    new2ARC.Order_No__c = 2;
                    new2ARC.Business_Entity__c = 'WorkOrder';
                    new2ARC.Attribute__c = 'Call_Type__c';
                    new2ARC.Operator__c = 'IN';
                    new2ARC.Audit_Rule__c=arRec.id;
                	new2ARC.Value__c='RAP,MEMBER'; //SLI - RAP TIRE CHANGE
                    auditRuleCriteriaList.add(new2ARC);
                    
                    Audit_Rule_Critieria__c new3ARC = new Audit_Rule_Critieria__c();
                    new3ARC.Order_No__c = 3;
                    new3ARC.Business_Entity__c = 'WorkOrder';
                    new3ARC.Attribute__c = 'Call_Type__c';
                    new3ARC.Operator__c = 'NOT IN';
                    new3ARC.Audit_Rule__c=arRec.id;
                	new3ARC.Value__c='RAP, TESTVAL'; //SLI - RAP TIRE CHANGE
                    auditRuleCriteriaList.add(new3ARC);
                }
                when '2' {
                    newARC.Audit_Rule__c=arRec.id;
                    newARC.Value__c='X002'; //SLI - RAP - GONE ON ARRIVAL
                    auditRuleCriteriaList.add(newARC);
                    newAA.Identifying_Value__c='GN';
                    newAA.Name='2';
                    auditActionList.add(newAA);
                }
                when '3' {
                    newARC.Audit_Rule__c=arRec.id;
                    newARC.Value__c='X001'; //SLI - RAP - CANCEL WITHOUT PAYMENT
                    auditRuleCriteriaList.add(newARC);
                    newAA.Identifying_Value__c='XX';
                    newAA.Name='3';
                    auditActionList.add(newAA);
				}
                when else{}
            }
        }
        insert auditRuleCriteriaList;
        insert auditActionList;
        //Audit Rule Actions
		List<Audit_Rule_Action__c> auditRuleActionList = new List<Audit_Rule_Action__c>();
        for(Audit_Rule__c arRec:auditRuleList)
        {
            for(Audit_Action__c aaRec:auditActionList)
            {
                if(arRec.Description__c ==  aaRec.Name){
                    Audit_Rule_Action__c araRec = new Audit_Rule_Action__c();
                    araRec.Audit_Rule__c = arRec.Id;
					araRec.Audit_Actions__c = aaRec.Id;
                    auditRuleActionList.add(araRec);
                }
            }
        }
        insert auditRuleActionList;
    }
    
    @isTest
    static void AuditRuleProcessorTest1(){  
        List<AAA_AuditRuleProcessor.FlowInput> flowList = new List<AAA_AuditRuleProcessor.FlowInput>();
        List<SObject> items = new List<SObject>{
            new WorkOrder(Resolution_Code__c = 'G101', Call_Type__c = 'RAP'),
            new WorkOrder(Resolution_Code__c = 'X002'),
            new WorkOrder(Resolution_Code__c = 'X001')
        };
        insert items;
        for(sObject a:items)
        {
            AAA_AuditRuleProcessor.FlowInput flowInput = new AAA_AuditRuleProcessor.FlowInput();
            flowInput.iptObj = a;
            flowList.add(flowInput);
        }
        //flowInput.iptObj=items;
        test.startTest();
        List<AAA_AuditRuleProcessor.FlowOutput> resList = AAA_AuditRuleProcessor.processAuditRules(flowList);
        Test.stopTest();
        System.assertEquals(3, reslist.size());
    }
    
}