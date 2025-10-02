global without sharing class AAA_AuditRuleProcessor {
    
    private static List<Audit_Rule__c> auditRuleList = new List<Audit_Rule__c>
        ([SELECT Id,Name,Description__c,Active__c,Audit_Comment__c,Club__c,Expression__c,Expression_Type__c,No_of_Actions__c,No_of_Criteria__c FROM Audit_Rule__c where Active__c = true]);
    private static Map<Id, Audit_Rule__c> auditRuleMap = new Map<Id, Audit_Rule__c>(auditRuleList);
    private static Map<Id, Audit_Rule_Critieria__c> auditRuleCriteriaMap = new Map<Id, Audit_Rule_Critieria__c>
        ([SELECT Id,Attribute__c,Audit_Rule__c,Name,Business_Entity__c,Operator__c,Order_No__c,Value__c from Audit_Rule_Critieria__c order by Audit_Rule__c,Order_No__c]);
    private static Map<Id, List<Id>> arcParentMap = new Map<Id, list<Id>>(); //<Audit_Rule__c.id, list<Audit_Rule_Critieria__c.id>>
    private static Map<Id, List<Id>> auditRuleActionMap = new Map<Id, list<Id>>(); //Audit_Rule_Action__c <Audit_Rule__c.id, list<Audit_Actions__c.id>>
    private static Map<Id, Audit_Action__c> auditActionMap = new Map<Id, Audit_Action__c>
		([SELECT Id,Name,Business_Entity__c,Total_Cost__c,Identifying_Attribute__c,Identifying_Attribute_Value__c,Identifying_Value__c,Override_Pricing__c,RecordType.Name,Unit__c,Action__c,Unit_Cost__c from Audit_Action__c]);
    private static List<Product2> productList = new List<Product2>
        ([SELECT Id,IsActive,ProductCode FROM Product2 where IsActive = true order by ProductCode]);
    private static map<String, Id> productMap = new map<String, Id>();
    
    @InvocableMethod(label = 'AuditRuleProcessor')
    global static List<FlowOutput> processAuditRules(List<FlowInput> records) {
        try{
            List<FlowOutput> outputList = new List<FlowOutput>();
            populate_auditRuleActionMap();
            populate_arcParentMap();
            populate_productMap();
            system.debug('PM:'+productMap.toString());
            List<FlowOutput> output = new List<FlowOutput>();
            if (records != null && records.size() > 0) {
                for(FlowInput record: records){
                    system.debug('Rec:'+record.iptObj.id+'-------------------------------------------------------------------------------');
                    FlowOutput singleOutput = new FlowOutput();
                    singleOutput = processSingleRecord(record.iptObj);
                    outputlist.add(singleOutput);
                }
            }
            system.debug('outputList:'+outputList.size());
            return outputList;
        }//end try
        catch (Exception e) {
            throw e;
        }
    }

    private static FlowOutput processSingleRecord(sObject rec){
        try{
            FlowOutput singleFlowOutput = new FlowOutput();
            singleFlowOutput.recordId = rec.get('Id').toString();
            Map<Id,boolean> auditRuleResults = new Map<Id,boolean>();
            for(Audit_Rule__c auditRuleRec:auditRuleList){ //walk through each Audit Rule
                system.debug('AuditRule:'+auditRuleRec.Id+' '+auditRuleRec.Name+' '+auditRuleRec.Description__c);
                Map<decimal,boolean> criteriaResults = new Map<decimal,boolean>();
                List<Id> criteriaList = arcParentMap.get(auditRuleRec.Id);
                for(id criteriaId:criteriaList){ //walk through Criteria for the rec
                    Audit_Rule_Critieria__c critRec = auditRuleCriteriaMap.get(criteriaId);
                    system.debug('Criteria:'+critRec.Id+' Order:'+critRec.Order_No__c+' Test:'+critRec.Business_Entity__c+' - '+critRec.Attribute__c+' '+rec.get(critRec.Attribute__c)+' '+critRec.Operator__c+' '+critRec.Value__c);
                    boolean result = false;
                    if(rec.getSObjectType().toString() != critRec.Business_Entity__c){ //BusinessEntity Test ----------------------------------
                        result = false; 
                        system.debug('Business Object Failure:'+rec.getSObjectType().toString()+' '+critRec.Business_Entity__c);
                    }
                    else{ //evaluate criteria ---------------------------------------------------------
                        result = evalRec(rec,critRec.Attribute__c,critRec.Operator__c,critRec.Value__c);
                        system.debug('Criteria Result:'+result);
                    }
                    criteriaResults.put(critRec.Order_No__c, result);
                } //end for(id criteriaId:criteriaList)
                //system.debug('Results: '+evalCriteria(criteriaResults,auditRuleRec.Expression__c,auditRuleRec.Expression_Type__c));
                system.debug('Criteria Results:'+criteriaResults.toString());
                if(evalCriteria(criteriaResults,auditRuleRec.Expression__c,auditRuleRec.Expression_Type__c)){ //use criteria results to evaluate rule --------------------
                    auditRuleResults.put(auditRuleRec.id,true);
                }
            }//end for(Audit_Rule__c AuditRule:auditRuleList){
            //if that passes, need to use the auditRuleActionMap to get the list of actions and auditActionMap to get each specific action and process for the record.
            system.debug('Starting Actions');
            for(Id key:auditRuleResults.keyset()){
                List<Id> auditRuleActionList = auditRuleActionMap.get(key);
                for(Id araId:auditRuleActionList){
                    Audit_Action__c auditActionRec = auditActionMap.get(araid);
                    processSingleAuditAction(rec,auditActionRec);
                } 
            } ///end for(Id key:auditRuleResults.keyset()){
            return singleFlowOutput;
        }//end try
        catch (Exception e) {
            throw e;
        }
    } //end processSingleRecord(sObject rec)

    private static void processSingleAuditAction(sObject recObj,Audit_Action__c auditActionRec){
        try{
            switch on auditActionRec.Action__c {
                when 'ADD' {
                    SObject obj = Schema.getGlobalDescribe().get(auditActionRec.Business_Entity__c).newSObject();
                    if(auditActionRec.Business_Entity__c == 'FSL_Service_Line_Item__c')
                    {
                        obj.put('Product__c',productMap.get(auditActionRec.Identifying_Value__c));
                        obj.put('Work_Order__c',recObj.get('Id'));
                        obj.put('Unit__c',auditActionRec.Unit__c);
                        insert obj;
                        system.debug('SLI:'+obj.get('Id'));
                    }
                    else
                    {
                        //nothing
                    }
                }
                /* //Not Implemented
				when 'EDIT' {

				}
				when 'DELETE' {

				}
				*/
                when else{
                    //do nothing
                }
            }      
        }//end try
        catch (Exception e) {
            throw e;
        }
    } //end processSingleAuditAction
    
    private static Boolean evalCriteria(Map<decimal,boolean> criteriaResults,String exprStr, String exprType){
        try{
            system.debug('evalCriteria Start');
            if (criteriaResults == null || String.isEmpty(exprType)){
                return false;
            }
            if(String.isEmpty(exprStr) && exprType == 'Custom')
            {
                return false;
            }
            
            switch on exprType {
                when 'AND' {
                    system.debug('evalCriteria AND');
                    for(decimal key:criteriaResults.keyset()){
                        if(criteriaResults.get(key) == false){
                            return false;
                        }
                    }
                    return true;
                }
                when 'OR' {
                    system.debug('evalCriteria OR');
                    for(decimal key:criteriaResults.keyset()){
                        if(criteriaResults.get(key) == true){
                            return true;
                        }
                    }
                    return false;
                }
                when 'Custom' {
                    List<Decimal> kList = new List<Decimal>();
                    List<Decimal> keyList = new List<Decimal>();
                    kList.addAll(criteriaResults.keySet());
                    kList.sort();
                    for(Integer i = kList.size()-1; i>=0; i--) {
                        keyList.add(kList.get(i));
                    }
                    for (Decimal key : keyList) {
                        
                        exprStr = exprStr.replace(String.valueOf(key), String.valueOf(criteriaResults.get(key)));
                    }
                    system.debug('evalCriteria Custom: '+exprStr);
                    Map<String, Object> ns = new Map<String, Object>();
                    ExpressionInterpreter.BooleanExpression b = ExpressionInterpreter.parse(exprStr);
                    boolean result = b.interpret(ns);                 
                    System.debug('ExpressionInterpreter: '+result);
                    return result;
                }
                when else {
                    system.debug('evalCriteria Else');
                    return false;
                }
            } //end switch on exprType
        }//end try
        catch (Exception e) {
            throw e;
        }
    } //end private static Boolean evalCriteria

    
    private static Boolean evalRec(SObject record, String fieldName, String operator, Object value) {
        try{
            if (record == null || String.isEmpty(fieldName) || String.isEmpty(operator)) {
                return false;
            }
            
            Object fieldValue = record.get(fieldName);
            if (fieldValue == null) {
                //return false;
                fieldValue = '';
            }
            
            if(value == null)
            {
                value = '';
            }
            
            switch on operator {
                when '=' {
                    return fieldValue == value; 
                }            
                when '!=' {
                    return fieldValue != value;
                }
                when 'IN' {
                    //return value instanceof List<Object> && ((List<Object>) value).contains(fieldValue);
                    List<String> lstValue = value.toString().split(',');
                    system.debug('IN lstValue:'+lstValue);
                    return lstValue.contains(fieldValue.toString());
                }
                when 'NOT IN' {
                    //return value instanceof List<Object> && !((List<Object>) value).contains(fieldValue);
                    List<String> lstValue = value.toString().split(',');
                    system.debug('Not In lstValue:'+lstValue);
                    return !lstValue.contains(fieldValue.toString());
                }
                /* //not implemented
				when '>' {
					return fieldValue instanceof Decimal && ((Decimal) fieldValue) > (Decimal) value;
				}
				when '<' {
					return fieldValue instanceof Decimal && ((Decimal) fieldValue) < (Decimal) value;
				}
				when '>=' {
					return fieldValue instanceof Decimal && ((Decimal) fieldValue) >= (Decimal) value;
				}
				when '<=' {
					return fieldValue instanceof Decimal && ((Decimal) fieldValue) <= (Decimal) value;
				}
				*/
                when else {
                    return false;
                }
            } //end switch
        }//end try
        catch (Exception e) {
            throw e;
        }
    } //end evalRec(SObject record, String fieldName, String operator, Object value) 
    
    private static void populate_arcParentMap(){
        for(id key:auditRuleCriteriaMap.keyset()){
            Id parentKey = auditRuleCriteriaMap.get(key).Audit_Rule__c;
            list<id> newList = new list<id>();
			if(arcParentMap.containsKey(parentKey)){newList = arcParentMap.get(parentKey);}
            newList.add(key);
            arcParentMap.put(parentKey,newList);            
        } //end for(id key:auditRuleCriteriaMap.keyset())
    } //end populate_arcParentMap
    
    private static void populate_auditRuleActionMap(){
        list<Audit_Rule_Action__c> listARA = new list<Audit_Rule_Action__c>([SELECT Audit_Rule__c, Audit_Actions__c from Audit_Rule_Action__c]);
        for(Audit_Rule_Action__c rec:listARA){
            list<id> newList = new list<id>();
			if(auditRuleActionMap.containsKey(rec.Audit_Rule__c)){newList = auditRuleActionMap.get(rec.Audit_Rule__c);}
            newList.add(rec.Audit_Actions__c);
            auditRuleActionMap.put(rec.Audit_Rule__c,newList);
        } //end for(Audit_Rule_Action__c rec:listARA){
    } //end populate_auditRuleActionMap(){
    
    private static void populate_productMap(){
        for(Product2 prodRec:productList){
            productMap.put(prodRec.ProductCode,prodRec.Id);            
        }
    } //end populate_productMap
    
    global class FlowInput {
        @InvocableVariable(label = 'sObject Input') global sObject iptObj;
    }

    global class FlowOutput {
        @InvocableVariable(label = 'sObject Id') global String recordId;
    }
    
}