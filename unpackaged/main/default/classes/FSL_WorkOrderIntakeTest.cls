/**
* @File Name          : FSL_WorkOrderIntakeTest.cls
* @Description        : 
* @Author             : Rajesh Kemisetti 
* @Group              : 
* @Last Modified By   : Clement Shiu
* @Last Modified On   : 11-08-2021
* @Modification Log   : 
* Ver       Date            Modifier                    Modification
* 1.0    09/29/2020        Dylan Truong                 ERS-219581 FSLTimeout Call add woLookup
* 1.1    11/08/2021        Clement Shiu                 ERS-226369 Comment out the ServiceTerritoryId assignment since it was auto assigned by the Managed Package already.
* 1.2    06-08-2023        VarunSharma@salesforce.com   Changes for person account, service contract and handling of the empty values for expiration date and member since. (https://salesforce.atlassian.net/browse/PR893288-252/238/242/249)
**/
@isTest
public class FSL_WorkOrderIntakeTest {
    @testSetup
    public static void dataSetForCon() {
        FSL_DataFactoryUtility.userSetupwithStaticData();
    }
    
    static testMethod void WorkOrderResponseNegative(){
        System.Test.StartTest();
        FSL_DataFactory.createWOIntakeCall('FSL_NegativeCall');
        System.Test.StopTest();          
    } 
    static testMethod void WorkOrderResponseWOLookUpFalseTrue()
    {
        system.Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse resFalse = FSL_DataFactory.createWOIntakeCall('FSL_Light_Call_WOLookup_False');
        System.debug('Return Work Order Number : ' + resFalse.workOrderNumber);
        FSL_WorkOrderResponse resTrue = FSL_DataFactory.createWOIntakeCall('FSL_Light_Call_WOLookup_True');
        System.debug('True Work Order Number : '  + resTrue.WorkOrderNumber);
        System.assertEquals(resFalse.workOrderNumber, resTrue.WorkOrderNumber);
        System.Test.stopTest();
    }
    
    static testMethod void WorkOrderLookup()
    {
        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Light_Call_WOLookup_False');
        System.debug('Return Work Order Number : ' + res.workOrderNumber);
        List<WorkOrder> wo = FSL_WorkOrderIntake.workOrderLookUp('315652');
        System.debug('Work Order Number : '  + wo[0].WorkOrderNumber);
        System.assertEquals(res.workOrderNumber, wo[0].WorkOrderNumber);
        System.Test.StopTest();
    }
    
    static testMethod void WorkOrderResponseWOLookUpWithoutLookupValue()
    {
        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        System.debug('Return Work Order Number : ' + res.workOrderNumber);
        List<WorkOrder> wo = FSL_WorkOrderIntake.workOrderLookUp('315652');
        System.debug('Work Order Number : '  + wo[0].WorkOrderNumber);
        System.assertEquals(res.workOrderNumber, wo[0].WorkOrderNumber);
        System.Test.StopTest();
    } 
    static testMethod void WorkTypeAccidentFirst()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_First');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        WorkType expectedWorkType = [SELECT Id, Name FROM WorkType WHERE Name = 'Accident Assist - First Tow' LIMIT 1];
        WorkType actualWorkType = [SELECT Id, Name FROM WorkType WHERE Id = :wo.WorkTypeId LIMIT 1];
        System.assertEquals(wo.WorkTypeId, expectedWorkType.Id, 'WorkType does not match - Expected = [' + expectedWorkType.Name + '] - Actual = [' + actualWorkType.Name + ']');
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentSecond()
    {
        
        
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_Second');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - Second Tow' LIMIT 1].Id;
        System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentContinuation()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_Continuation');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - Continuation Tow' LIMIT 1].Id;
        System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentRVFirst()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_RV_First');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        WorkType expectedWorkType = [SELECT Id, Name FROM WorkType WHERE Name = 'Accident Assist - RV First Tow' LIMIT 1];
        WorkType actualWorkType = [SELECT Id, Name FROM WorkType WHERE Id = :wo.WorkTypeId LIMIT 1];
        System.assertEquals(wo.WorkTypeId, expectedWorkType.Id, 'WorkType does not match - Expected = [' + expectedWorkType.Name + '] - Actual = [' + actualWorkType.Name + ']');
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentRVSecond()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_RV_Second');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - RV Second Tow' LIMIT 1].Id;
        System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentRVContinuation()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_RV_Continuation');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - RV Continuation Tow' LIMIT 1].Id;
        System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentMVFirst()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_MV_First');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        WorkType expectedWorkType = [SELECT Id, Name FROM WorkType WHERE Name = 'Accident Assist - MC First Tow' LIMIT 1];
        WorkType actualWorkType = [SELECT Id, Name FROM WorkType WHERE Id = :wo.WorkTypeId LIMIT 1];
    	//System.assertEquals(wo.WorkTypeId, expectedWorkType.Id, 'WorkType does not match - Expected = [' + expectedWorkType.Name + '] - Actual = [' + actualWorkType.Name + ']');
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentMVSecond()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_MV_Second');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - MC Second Tow' LIMIT 1].Id;
      	//System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
    static testMethod void WorkTypeAccidentMVContinuation()
    {
        System.Test.StartTest();            
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_Accident_MV_Continuation');
        workorder wo = [select id, workordernumber, worktypeid from workorder where workordernumber =: res.workordernumber];
        System.debug('Return Work Type Id Number : ' + wo.worktypeid);
        Id wtid =[select id from worktype where name ='Accident Assist - MC Continuation Tow' LIMIT 1].Id;
     	//System.assertEquals(wo.WorkTypeId, wtid);
        System.Test.StopTest();
    }
    
 /*   static testMethod void serviceLineItemCheck()
    {
        System.Test.StartTest();         
        list<Product2> products = FSL_DataFactory.createProducts();         
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_CalcMile_Service_Line_Item');
        
        workorder wo = [select id, workordernumber, worktypeid,D3_Tow_Mileage__c from workorder where workordernumber =: res.workordernumber];
        system.debug('wo + 182 ' + wo);
        FSL_Calculated_Mileage_Line_Item__c cmli = [select id, Unit__c, Product__c,Product__r.Name from FSL_Calculated_Mileage_Line_Item__c where Work_Order__c =: wo.Id];
        FSL_Service_Line_Item__c sli = [select id, Unit__c, Product__c,Product__r.Name from FSL_Service_Line_Item__c where Work_Order__c =: wo.Id];
        System.assertEquals(18,wo.D3_Tow_Mileage__c);
        System.assertEquals(wo.D3_Tow_Mileage__c,cmli.Unit__c);
        System.assertEquals('CT - Calculated Tow',cmli.Product__r.Name);
        System.assertEquals(wo.D3_Tow_Mileage__c,sli.Unit__c);
        System.assertEquals('TW - TOW MILEAGE',sli.Product__r.Name);
        System.Test.StopTest();
    }*/
    
    static testMethod void WorOrderServiceTerritoryIdCheck()
    {
        System.Test.StartTest();   
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_LightCall');
        
        list<WorkOrder> WOs = [SELECT id,ServiceTerritoryId, (SELECT ServiceTerritoryId FROM serviceappointments) FROM WorkOrder];        
        System.assertEquals(WOs[0].ServiceTerritoryId, WOs[0].serviceappointments[0].ServiceTerritoryId);
        
        System.Test.StopTest();
    }
    
    static testMethod void WorkOrderNullFacitlityId()
    {
        System.debug('$$Kumar## WorkOrderNullFacitlityId: ');
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.facility.id = null;
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        System.Test.StopTest();
        WorkOrder wo = [SELECT Account.Facility_ID__c FROM WorkOrder where WorkOrderNumber = :resp.workOrderNumber][0];

        System.assertEquals(String.isNotBlank(wo.Account.Facility_ID__c), true);
    }
    
    @isTest
    static void workOrderInvalidWaittimeShouldNotThrowNumberOutsideValidRangeException() {
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.status.waitTime = 1062810407;
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        System.Test.StopTest();
        
        List<WorkOrder> wo = [SELECT Id, Wait_Time__c FROM WorkOrder where WorkOrderNumber = :resp.workOrderNumber];
        List<FSL_WorkOrder_Configuration__mdt> woConfigs = [SELECT MasterLabel,  Default_Wait_Time__c FROM FSL_WorkOrder_Configuration__mdt
                                                            WHERE MasterLabel = 'ACE Default WorkOrder Configuration' LIMIT 1];
        List<FSL_Application_Log__c> applicationLogs = [SELECT Id, Error_Caught__c FROM FSL_Application_Log__c WHERE Operation__c = 'ValidateWaitTime'];
        System.assertEquals(1, wo.size(), 'Work Order Intake receiving an invalid Wait Time should not throw NUMBER_OUTSIDE_VALID_RANGE exception' );
        System.assertEquals(woConfigs[0].Default_Wait_Time__c, wo[0].Wait_Time__c, 'Work Order Wait Time should be equal to WorkOrder Configuration Default Wait Time' );
        System.assertEquals(1, applicationLogs.size(), 'Work Order Intake receiving an invalid Wait Time should generate a successful log entry' );
        System.assertEquals(false, applicationLogs[0].Error_Caught__c, 'Work Order Intake receiving an invalid Wait Time should generate a successful log entry with Error Caught value of false' );
    }     
    
    @isTest
    static void workOrderIntakeWithFacilityIdButNoLatLongShouldAssignFacilityId() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        System.Test.StartTest();
        WorkOrder wo1 = new WorkOrder();
        wo1.Breakdown_Location__Latitude__s = null;
        wo1.Breakdown_Location__Longitude__s = null;
        Id ServiceTerritoryId = FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility(jsonWorkOrder, wo1, jsonWorkOrder.calls[0].service.facility.id);
        System.Test.StopTest();
        
        List<ServiceTerritory> st = [select Facility_Number__c FROM ServiceTerritory WHERE Id = :ServiceTerritoryId];
        System.assertEquals('9121', st[0].Facility_Number__c, 'Service Territory assigned in FSL_LightCall should be the one assigned to work order');
    }
    
    @isTest
    static void workOrderIntakeWithFacilityIdRequiredShouldAssignFacilityId_Success() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.facility.preferenceType = 'Required';
        jsonWorkOrder.calls[0].service.facility.id = '9198';
        
        System.Test.StartTest();
        WorkOrder wo1 = new WorkOrder();
        Id ServiceTerritoryId = FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility(jsonWorkOrder, wo1, jsonWorkOrder.calls[0].service.facility.id);
        System.Test.StopTest();
        
        List<ServiceTerritory> st = [select Facility_Number__c FROM ServiceTerritory WHERE Id = :ServiceTerritoryId];
        System.assertEquals(jsonWorkOrder.calls[0].service.facility.id, st[0].Facility_Number__c, 'Required Service Territory should be the one assigned to Work Order');
    }    
    
    @isTest
    static void workOrderIntakeWithFacilityIdAndLatLongShouldAssignFacilityIdFromPolygon() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.facility.id = null;
        
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        System.Test.StopTest();
        
        List<WorkOrder> wo = [SELECT Id, ServiceTerritoryId FROM WorkOrder where WorkOrderNumber = :resp.workOrderNumber];
        List<ServiceTerritory> st = [select Facility_Number__c FROM ServiceTerritory WHERE Id = :wo[0].ServiceTerritoryId];

        System.assertEquals(1, wo.size(), 'Work Order Intake with no Lat/Long creates the Work Order' );
        System.assertEquals(true, String.isNotBlank(st[0].Facility_Number__c), 'Service Territory should be assigned by Polygon to Work Order');
    }    
    
    @isTest
    static void workOrderIntakeWithoutFacilityIdNoLatLongShouldAssignNullToFacilityId() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.facility.id = null;
        
        System.Test.StartTest();
        WorkOrder wo1 = new WorkOrder();
        wo1.Breakdown_Location__Latitude__s = null;
        wo1.Breakdown_Location__Longitude__s = null;
        Id ServiceTerritoryId = FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility(jsonWorkOrder, wo1, jsonWorkOrder.calls[0].service.facility.id);
        System.Test.StopTest();
        
        List<ServiceTerritory> st = [select Facility_Number__c FROM ServiceTerritory WHERE Id = :ServiceTerritoryId];
        System.assertEquals(st.size(), 0, 'Missing Service Territory Id without Lat/Long should return Null for Service Territory Id');
    }        
    
    @isTest
    static void workOrderIntakeWithFacilityIdLatLongWithNoPolygonShouldReturnExsitingFacilityId() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        List<OperatingHours> operatingHours = [SELECT Id FROM OperatingHours WHERE Name = '24/7 Pacific'];
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = operatingHours[0].Id, IsActive = true, Facility_Number__c = '1111' );
        insert st1;
        
        jsonWorkOrder.calls[0].service.facility.id = '1111';
        
        System.Test.StartTest();
        WorkOrder wo1 = new WorkOrder();
        wo1.Breakdown_Location__Latitude__s = 33.12316;
        wo1.Breakdown_Location__Longitude__s = -117.0934317;
        Id ServiceTerritoryId = FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility(jsonWorkOrder, wo1, jsonWorkOrder.calls[0].service.facility.id);
        System.Test.StopTest();
        
        List<ServiceTerritory> st = [select Facility_Number__c FROM ServiceTerritory WHERE Id = :ServiceTerritoryId];
        System.assertEquals(jsonWorkOrder.calls[0].service.facility.id, st[0].Facility_Number__c, 'Missing Polygon for Lat/Long should return 1111 for Service Territory Id');
    }        
    
    @isTest
    static void workOrderIntakeWithFacilityIdLatLongWithNoPolygonOrServiceTerritoryShouldReturnNullFacilityId() {
        
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_LightCall'];
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        
        jsonWorkOrder.calls[0].service.facility.id = '1111';
        
        System.Test.StartTest();
        WorkOrder wo1 = new WorkOrder();
        wo1.Breakdown_Location__Latitude__s = 33.12316;
        wo1.Breakdown_Location__Longitude__s = -117.0934317;        
        Id ServiceTerritoryId = FSL_WorkOrderIntake.getTerritoryIdFromIntakeFacility(jsonWorkOrder, wo1, jsonWorkOrder.calls[0].service.facility.id);
        System.Test.StopTest();
        
        System.assertEquals(null, ServiceTerritoryId, 'Missing Service Territory should return null for Service Territory Id');
    }  
    
    static testMethod void WorkOrdertowBook()
    {
        StaticResource sr = [select id, body from StaticResource where name = 'FSL_TowBook_Call'];
        
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(sr.body.toString(), FSL_JSonParserWorkOrder.class);
        System.debug('jsonWorkOrder initially' + jsonWorkOrder);
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        List<OperatingHours> operatingHours = [SELECT Id FROM OperatingHours WHERE Name = '24/7 Pacific'];
        List<ServiceTerritory> str=[Select Id From ServiceTerritory];
        system.debug('exisitng already str='+str);
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = operatingHours[0].Id, IsActive = true, Facility_Number__c = '11101' );
        insert st1;
        System.debug('serviceTerritoryID test='+st1.Id);
        Technology_Preference__c tp = new Technology_Preference__c(
            SERVICE_TERRITORY__C = st1.id,
            DAYS_APPLIED__C = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
            END_TIME__C = Time.newInstance(23,59,59,0),
            START_TIME__C = Time.newInstance(0,0,0,0),
            TECHNOLOGY_TYPE__C = ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK 
        );
        insert tp;
        
        jsonWorkOrder.calls[0].service.facility.id = '11101';
        string jsonStr = Json.serializePretty(jsonWorkOrder, true);
        System.debug('jsonStr'+jsonStr);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonStr);
        
        RestContext.request = req;
        RestContext.response= res;
        
        System.Test.StartTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        System.Test.StopTest();
        System.debug('Inside test class resp' + resp);
        
        //WorkOrder wo = [SELECT Account.Facility_ID__c FROM WorkOrder where WorkOrderNumber = :resp.workOrderNumber];
        List<WorkOrder> wo = [SELECT Id, Wait_Time__c,Servicing_Technology_Type__c,EntitlementId FROM WorkOrder where Servicing_Technology_Type__c = :ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK ];
        System.debug('wo list from the output' + wo);
        System.assert(wo[0].Servicing_Technology_Type__c ==ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK );
        System.assert(wo[0].EntitlementId == null );
        
        wo[0].Status='Canceled';
        update wo;
        List<FSL_Application_Log__c> applogs=[Select Id from FSL_Application_Log__c Where Api_Name__c = 'ThirdPartyIntegration'];
        //System.assertEquals(2, applogs.size());
    }  
    
    static testMethod void TestWorkOrderParseAndCreateWithD3AARIdValueSet ()
    {
        system.debug('###### Soham ####### ');
        String testJson6 = '{"id":"cf27aecc-0aa3-4660-878f-ec2922402b01","requestEventType":"CREATE","subType":"CREATE","status":"UNUSED","version":"1.0.0","sourceSystem":{"systemId":"AAAD3Test","systemOrganziation":{"name":"AAA","code":"014"}},"targetSystem":{"systemId":"SLTest","systemOrganziation":{"name":"Salesforce","code":"014"}},"createDate":63784270683053,"calls":[{"callKey":"004-20220330-285615","callDate":"2022-03-30","callId":285615,"woLookup":false,"version":"1","channel":{"channelType":"CALL_CENTER","org":{"name":"","code":"004"},"contact":{"userId":"E105578","contactType":"AGENT"},"location":{"latitude":33.341891,"longitude":-118.32696,"address":{"addressType":"PHYSICAL","full":"256 CATALINA AVE, AVALON CA, 90704","street":"256 CATALINA AVE","crossStreet":"","crossStreet2":"","city":"AVALON","county":"LOS ANGELES","state":"CA","postalCode":"90704","country":"UNITED STATES"},"landmark":"RSP PRODUCTION TEST","highway":"","mileMarker":"","grid":"","zone":"","locationCode":""}},"customer":{"memberships":[{"membershipType":"","authorizationCode":"","authorizationLevel":"","isLocalClub":true,"org":{"name":"","code":"004"},"id":"NEED MBR INFO","originalMemberId":"NEED MBR INFO","expirationDate":"2023-03-30","memberLevel":"BASIC","memberSince":"2021","entitlements":[{"serviceChargeIndicator":false,"longTowAllowed":true}]}],"contact":{"contactType":"CUSTOMER","firstName":"","lastName":"XYZ","phones":[{"phoneType":"","phoneNumber":"","phoneExtension":"","order":1,"preferred":true,"smsOptIn":false}]}},"vehicle":{"vehicleType":"PS","year":2009,"make":"ACURA","model":"1.6 EL","color":"BEIGE"},"service":{"callType":"MEMBER","timezoneId":"America/Los_Angeles","timezoneOffset":"UTC-07:00","status":{"status":"SP","modifiedDate":"2022-03-30T20:57:58Z[UTC]","pta":"2022-03-30T21:37:58Z[UTC]","waitTime":40},"appointmentTime":"2018-09-15T10:05:51Z[UTC]","facility":{"foiType":"ERS","location":{},"id":"169999","name":"ULRA ACSC TEST STATION","preferenceType":"Required"},"troubleCodes":[{"troubleCodeType":"PACESETTER","code":"T280","description":"Engine Overheat"},{"troubleCodeType":"PROBLEM","code":"6","description":"TOW"}],"serviceLocations":[{"serviceLocationType":"BREAKDOWN","foi":{"foiType":"ADDRESS","location":{"latitude":33.341891,"longitude":-118.32696,"address":{"addressType":"PHYSICAL","full":"256 CATALINA AVE, AVALON CA, 90704","street":"256 CATALINA AVE","streetNumber":"256","streetDirection":"S","streetName":"CATALINA AVE","crossStreet":"","crossStreet2":"","city":"AVALON","county":"LOS ANGELES","state":"CA","postalCode":"90704","country":"UNITED STATES"},"landmark":"RSP PRODUCTION TEST","highway":"","mileMarker":"","grid":"","zone":"","locationCode":""}},"driverDirections":""},{"serviceLocationType":"TOW_DESTINATION","foi":{"foiType":"AAR","location":{"latitude":33.649454,"longitude":-117.931481,"address":{"addressType":"PHYSICAL","full":"2066 PLACENTIA AVE., COSTA MESA CA, 92627","street":"2066 PLACENTIA AVE.","streetNumber":"2066","streetDirection":"","streetName":"PLACENTIA AVE.","crossStreet":"","city":"COSTA MESA","county":"ORANGE","state":"CA","postalCode":"92627","country":"UNITED STATES"},"landmark":"FITZGERALDS AUTO CARE CENTER (402596)"},"id":"402596","name":"FITZGERALDS AUTO CARE CENTER (402596)","contacts":[{"contactType":"TOWDEST","firstName":"TEST TEST TEST","lastName":" ","phones":[{"phoneType":"BUSINESS","phoneNumber":"9495488877","phoneExtension":"","order":1,"preferred":true,"smsOptIn":false}]}]},"dropBoxInfo":"","secureLot":false}],"collision":false,"redFlag":false,"priorityCode":"","legacyPriorityCode":" ","numberOfPassengers":0,"needsFlatbed":false,"flatbedRequested":false,"duty":""},"payment":{"required":false,"paymentType":"","codes":"100001000B0XX20"},"comments":[{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:54:29Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|INITIATED: 03/30/2022 20:54 (UTC)|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:54:35Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"**DUMMY SERVICE ORDER - NO SERVICE NEEDED**"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"S999999","contactType":"SYSTEM"},"commentDate":"2022-03-30T20:56:00Z[UTC]","commentType":"AUDIT","visibility":"EXTERNAL","text":"|LOCATION ADDRESS CHANGED FROM DUMP STREET TO 256 CATALINA AVE (DUE TO GEOCODING USING THE SERVICE LOCATION DIALOG) BY Y015.|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"S999999","contactType":"SYSTEM"},"commentDate":"2022-03-30T20:56:00Z[UTC]","commentType":"AUDIT","visibility":"EXTERNAL","text":"|SERVICE LOCATION GEOCODING METHOD: GPS.|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:56:04Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|ASSIGNED: 03/30/2022 20:56 (UTC)|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:56:04Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|SERVICE PROVIDER ASSIGNED BY LAT/LONG - ++PRI/AUX-160101/|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"S999999","contactType":"SYSTEM"},"commentDate":"2022-03-30T20:57:49Z[UTC]","commentType":"AUDIT","visibility":"EXTERNAL","text":"|SERVICE ORDER MANUALLY-ASSIGNED TO CSP 169999 BY Y015. PREVIOUSLY-ASSIGNED CSP: 160101.|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:56Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|Member Location Coordinates:<LC=33.3418910:-118.3269600>|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:56Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|Tow Destination Coordinates:<TC=33.6494540:-117.9314810>|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:58Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"|RECEIVED: 03/30/2022 20:57 (UTC)|"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:58Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"**PACESETTER SERVICE CODE: T280 Engine Overheat**"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:58Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"**TOW DESTINATION CONTACT PHONE: (949)548-8877 Bus**"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:58Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"**TOW DESTINATION: LOC:FITZGERALDS AUTO CARE CENTER (402596) STREET:2066 PLACENTIA AVE. CITY:COSTA MESA **"},{"system":{"systemId":"AAAD3Test","systemOrganziation":{"name":"","code":"004"}},"contact":{"userId":"E105578","contactType":"AGENT"},"commentDate":"2022-03-30T20:57:58Z[UTC]","commentType":"NORMAL","visibility":"EXTERNAL","text":"**TOW DEST CONTACT NAME: TEST TEST TEST**"}]}]}';
        String toUse = testJson6;
        
        System.debug('------------- TIMESTAMP ----- : ' + Datetime.now());
        
        FSL_JSonParserWorkOrder jsonWorkOrder = (FSL_JSonParserWorkOrder)Json.deserialize(toUse, FSL_JSonParserWorkOrder.class);
        WorkOrder myWorkOrder = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        
        System.debug( ' Value for D3AARID= ' + myWorkOrder.D3_AAR_Id__c );
        System.assertEquals ( '402596', myWorkOrder.D3_AAR_Id__c, 'AAR ID did not match' );
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(toUse);
        RestContext.request = req;
        RestContext.response= res;
        
        System.Test.StartTest();
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        System.debug( ' From Workorder resp workorder number= ' + JSON.serialize(resp)  );
        
        // System.assertNotEquals ( null, resp.workOrderNumber, 'workorder number= ' + resp.workOrderNumber );
        
        myWorkOrder = [SELECT Id FROM WorkOrder where WorkOrderNumber = :resp.workOrderNumber];
        System.debug( ' From Workorders woId= ' + myWorkOrder.Id );
        Set <Id> woIds = new Set<Id>();
        woIds.add(myWorkOrder.Id);
        
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
        List<WorkOrder> woList = workOrderService.getWorkOrdersForClearing ( woIds );
        myWorkOrder = woList.get(0);
        System.debug ( ' FirstWo.Id, number= ' + myWorkOrder.Id + ', ' + myWorkOrder.WorkOrderNumber );
        // Next step it to call the clear work order with saved woID FSL_D3Clear. Want to exercise the query.
        
        FSL_ToD3Clear.IFactory toD3ClearFactory = new FSL_ToD3Clear.Factory();
        FSL_ToD3Clear.IToD3Clear d3Clear = toD3ClearFactory.createToD3Clear();
        Map<Id, Boolean> whichOnes = d3Clear.clearWorkOrders( woIds );
        
        FSL_WorkOrderD3JsonWrapper wrapper = new FSL_WorkOrderD3JsonWrapper();
        Map<Id,AssignedResource> serviceAppointmentIdToAssignedResourceMap = new Map<Id, AssignedResource>();
        Map<Id,List<FeedItem>> workOrderIdToFeedItemsMap = new Map<Id, List<FeedItem>>();
        String serviceName = '';
        
        String expected1 = 'ADDRESS';
        String expected2 = 'AAR';
        String expectedId = '402596';
        
        FSL_ClearJsonWorkOrder clearJsonWorkOrder = wrapper.Wrap( myWorkOrder, serviceAppointmentIdToAssignedResourceMap, workOrderIdToFeedItemsMap, serviceName );
        System.debug ( ' Returned json AARId= ' +  clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.id );
        
        System.assertEquals( expected1, clearJsonWorkOrder.calls[0].service.serviceLocations[0].foi.foiType );
        System.assertEquals( expected2, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.foiType );
        System.assertEquals( expectedId, clearJsonWorkOrder.calls[0].service.serviceLocations[1].foi.id );
        
        System.Test.StopTest();
    }
    
    //Start - Varun Test Cases Class
    
    static void workOrderWithPrimaryMemberServiceContract(){
        string payload = '{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-120001","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "'+Label.FSL_SourceClubCode+'"},"id": "4382122694719004","originalMemberId": "4382122694719004","expirationDate": "2023-08-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719004","contactType": "CUSTOMER","title": "MR","suffix": "Jr","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "RAP","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        
        FSL_JSonParserWorkOrder jsonWorkOrder   = (FSL_JSonParserWorkOrder)Json.deserialize(payload, FSL_JSonParserWorkOrder.class);
        WorkOrder myWorkOrder                   = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;
        
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        List<ServiceContract> contracts = [select ID,Name from ServiceContract];
        
    }
    
    static string getMemberD3Payload(){
        string payload = '{"id": "aab19adb-d529-4dd6-8ef4-256f0bc38064","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1681760225202,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230417-110011","callDate": "2023-04-17","callId": 101109,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"}},      "customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "'+Label.FSL_SourceClubCode+'"},"id": "4382122694719024","originalMemberId": "4382122694719024","expirationDate": "2023-03-01","memberLevel": "BASIC","memberSince": "2013","memberStatus": "A","entitlements": [{"associates": 3,"callsAllowed": 5,"callsRemaining": 4,"callsUsed": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]          }],"contact": {"customerId": "4382122694719024","contactType": "CUSTOMER","title": "MR","suffix": "Jr","firstName": "MICHAEL","lastName": "MILLS","phones": [{"phoneType": "HOME","phoneNumber": "5123642443","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "bjpmills@yahoo.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2005,"make": "DODGE","model": "NEON","color": "Blue","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-04-17T19:37:00.269274Z[UTC]","pta": "2023-04-17T20:37Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET,BOWLING GREEN,OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE,L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"},{"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.69893,"longitude": -83.65429,"address": {"addressType": "PHYSICAL","full": "5225 MONROE ST ,TOLEDO ,OH 43623 ","street": "MONROE ST","streetNumber": "5225","streetDirection": "","streetName": "MONROE ST","crossStreet": "OH-51 S","city": "TOLEDO","state": "OH","postalCode": "43623"},"landmark": "Target","highway": "","grid": "NW743A","locationCode": "FS"}},"mileageCalculated": 26.7}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "ARLEWICKE","contactType": "AGENT"},"commentDate": "2023-04-17T19:37Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        return payload;
    }
    static void workOrderWithAssociateMemberServiceContract(){
        string payload = getMemberD3Payload();
        
        FSL_JSonParserWorkOrder jsonWorkOrder   = (FSL_JSonParserWorkOrder)Json.deserialize(payload, FSL_JSonParserWorkOrder.class);
        WorkOrder myWorkOrder                   = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
    }
    
    static string getRAPD3Payload(){
        string payload = '{"id": "3200d145-3aa4-4e28-a9d6-258811e63855","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "240","systemOrganization": {"name": "NE","code": "240"}},"targetSystem": {"systemId": "Beacon","systemOrganization": {"name": "Beacon","code": "240"}},"createDate": 1671026340380,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "240-20221214-99071","membershipNumber":"6202400000235007","callDate": "2022-12-14","callId": 90071,"requestingSystemCallId": "41520209","version": "0.0.1","channel": {"channelType": "RAP","org": {"name": "UNKNOWN","code": "240"},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "RAP","isLocalClub": false,"org": {"name": "UNKNOWN","code": "240"},"id": "41520209","originalMemberId": "41520209","memberLevel": "Plus","memberSince": "","entitlements": [{"associates": 0,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}],"sponsor": "00000044","program": "00000149","programMaxMileage": "99999","goodwill": "N","dealerName": "unit#","dispatchCenter": "00000366"}],"contact": {"customerId": "41520209","contactType": "CUSTOMER","firstName": "SARAH","lastName": "HOLTS","phones": [{"phoneType": "CELLULAR","phoneNumber": "6314949399","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "sarah@gmail.com"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2018,"make": "Toyota","model": "Corolla","color": "Metal","vin": "2T1BR30E95C483769","tag": "M53G46","state": "FL","fuelType": "GAS","specialEquipmentNeeds": "Flatbed Required","condition": "Flatbed required"},"service": {"callType": "RAP","timezoneId": "America/New_York","timezoneOffset": "UTC-05:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2022-12-14T13:58:55.512016Z[UTC]","pta": "2022-12-14T15:03Z[UTC]","waitTime": 65},"facility": {"foiType": "ERS","location": {"latitude": 37.24169,"longitude": -80.4182,"address": {"addressType": "PHYSICAL","full": "1208 N. MAIN STREET,  BLACKSBURG, VA 24060","street": "1208 N. MAIN STREET","city": "BLACKSBURG","state": "VA","postalCode": "24060"}},"id": "VA238","name": "CAMPUS AUTOMOTIVE, INC.","contacts": [{"userId": "JOHNNY SELF MGR. (540) 605-6006","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L101","description": "Flat Tire w/spare"},{"troubleCodeType": "PROBLEM","code": "1","description": "Flat tire with spare"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 37.2072633,"longitude": -80.4027437,"address": {"addressType": "PHYSICAL","full": "201   S HILL DR DR , BLACKSBURG , VA ","street": " S HILL DR DR","streetNumber": "201 ","streetDirection": "","streetName": " S HILL DR DR","city": "BLACKSBURG","state": "VA"},"landmark": "GATE CODE IS 123 ","highway": "","grid": "2111"}},"mileageCalculated": 3,"driverDirections": "RAP"},{"serviceLocationType": "TOW_DESTINATION","foi": {"foiType": "ADDRESS","location": {"address": {"addressType": "PHYSICAL","full": ", Blacksburg , VA ","streetDirection": "","city": "Blacksburg","state": "VA"}},"name": "NA"},"mileageCalculated": 0,"secureLot": false}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": true,"flatbedRequested": true,"duty": "M"},"payment": {"required": false,"responsible": "S"},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: TEST Call, do not dispatch - TOW CALL"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Test comment 2"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Channel: Digital"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Flatbed required"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Problem sub type: FLATBED REQUIRED."},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Problem sub type: Flatbed Required."},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Note:Customer Needs a Ride!!"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Note:Please drop customer at 1000 AAA Dr, Heathrow, FL"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP: Survey link:https://int-experigocommunities.cs21.force.com/s/toyota?id=04667916"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "RAP Breakdown Loc: 201 S Hill Dr"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Note : Supplied VIN is invalid and not blank- [Unable to access RAP Central Server to validate VIN]"},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Note: Unverified odometer from RAP is 12344."},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "[Status timestamp override] "},{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "RAP_SRVR","contactType": "AGENT"},"commentDate": "2022-12-14T13:58:51Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "[Status timestamp override] "}]}]}';
        return payload;
    }

    static void workOrderWithRAPServiceContract(){
        string payload = getRAPD3Payload();

        FSL_JSonParserWorkOrder jsonWorkOrder   = (FSL_JSonParserWorkOrder)Json.deserialize(payload, FSL_JSonParserWorkOrder.class);
        WorkOrder myWorkOrder                   = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;    
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
    }

    static void testMemberTypeWorkOrder(){
        string payload = getRAPD3Payload();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        FSL_JSonParserWorkOrder jsonWorkOrder   = (FSL_JSonParserWorkOrder)Json.deserialize(payload, FSL_JSonParserWorkOrder.class);
        WorkOrder myWorkOrder                   = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;    
        Test.startTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();
        Test.stopTest();
    }

    // Service Contracts functionality is moved to AA_ServiceContract_Utility class
   

     
    @isTest
    static void workOrder_MemberPrimaryServiceContractFirstTime(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        workOrderWithPrimaryMemberServiceContract();
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='6202404941373216']; //2694719
        
        FSL_WorkOrderIntake.getContractByMembership16ID('6202404941373216');// //4382122694719004
        
        System.Debug('workOrderWithMemberServiceContractFirstTime::Test Assert for Service Contract::' + contracts.size());
        //Assert.areEqual(contracts.size(), 2);
    }
    
    @isTest
    static void workOrder_MemberServiceContractSecondTime(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        workOrderWithPrimaryMemberServiceContract();
        workOrderWithPrimaryMemberServiceContract();
        
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='6202404941373216'];
        System.Debug('workOrderWithMemberServiceContractSecondTime::Test Assert for Service Contract::' + contracts.size());
        System.assertEquals(0, contracts.size(), 'Contracts created should be 0');
        //Assert.areEqual(contracts.size(), 2);
    }
    
    @isTest
    static void workOrder_MemberAssociateServiceContractFirstTime(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        workOrderWithAssociateMemberServiceContract();
       // List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='2694719'];
        List<ServiceContract> contracts = [select ID,Name from ServiceContract];
        System.Debug('workOrderWithMemberServiceContractFirstTime::Test Assert for Service Contract::' + contracts.size());
        System.assertEquals(0, contracts.size(), 'Contracts created should be 0');
        //Assert.areEqual(contracts.size(), 2);
    }
    
    @isTest
    static void workOrder_RAPServiceContractFirstTime(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        workOrderWithRAPServiceContract();        
        
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='41520209'];
        System.Debug('workOrderWithRAPServiceContractSecondTime::Test Assert for Service Contract::' + contracts.size());
       // System.assertEquals(0, contracts.size(), 'Contracts created should be 0');
       //Assert.areEqual(contracts.size(), 1);
    }
    
    @isTest
    static void workOrder_RAPServiceContractSecondTime(){
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        insert new Account(
            FirstName = 'Olivia',
            LastName = 'Bedard',
            Phone = '1234567890',
            Member_Card_Num__pc = '6202404941373216',
            Member_ID__c = '463606023'
        );
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        insert new ServiceContract (
            AAA_ACA_Member_Status__c = 'Active',
            AccountId = acc.Id,
            AAA_ACA_MembershipID__c = '463606023',
            AAA_ACA_Membership16ID__c = '6202404941373216', 
            AAA_ACA_Club_Code__c = '240',
            Name = '236360602-00',
            StartDate = Date.parse('01/30/2024'),
            EndDate = Date.parse('01/30/2025')
        );
        workOrderWithRAPServiceContract();
       // workOrderWithRAPServiceContract();
        
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='41520209'];
        System.Debug('workOrderWithRAPServiceContractSecondTime::Test Assert for Service Contract::' + contracts.size());
        // System.assertEquals('200', result.statusCode, 'The statusCode should be 200 for a successful operation.');
      //  System.assertEquals(0, contracts.size(), 'Contracts created should be 0');
    }
 
    @isTest
    static void workOrder_nullExpirationDateCheck_nullMemberSince(){        
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "'+Label.FSL_SourceClubCode+'"},"id": "4382121351011003","originalMemberId": "4382121351011003","expirationDate": "","memberLevel": "Plus","memberSince": "","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011003","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;   
        
        HttpCalloutMock mock = new Util_ManageAccessTokensTest.MockAccessTokenGenerator(); 
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest(); 
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
        Test.stopTest();
        // External_Id__c=212-20230417-110011
       List<WorkOrder> workOrders = [SELECT Id, External_ID__c FROM WorkOrder WHERE External_ID__c = '212-20230417-110011'];

        //List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract where AAA_ACA_Membership16ID__c ='4382121351011003' LIMIT 1];
        //System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
        //System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);
        //Assert.areEqual(contracts[0].StartDate, contracts[0].EndDate);
    }

    @isTest
    static void test_createOrGetParentServiceContract(){

        Test.setMock(HttpCalloutMock.class, new MockResponse());
        //workOrderWithAssociateMemberServiceContract();
        String memberHouseholdId = 'HH1234';
        FSL_WorkOrderIntake.createOrGetParentServiceContract(memberHouseholdId);
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='HH1234'];
        Assert.areEqual(contracts.size(), 0);
    }

    @isTest
    static void test_getContractByMembershipID(){

        Test.setMock(HttpCalloutMock.class, new MockResponse());
        //workOrderWithAssociateMemberServiceContract();
        String memberId = 'MM1234';
        FSL_WorkOrderIntake.getContractByMembershipID(memberId,'MEMBER');
        List<ServiceContract> contracts = [select ID,Name from ServiceContract where AAA_ACA_MembershipID__c='HH1234'];
        Assert.areEqual(contracts.size(), 0);
    }

    @isTest
    static void  testCreateWOCase() { 
       
      Account acc = new Account(Name = 'Test Account');
      insert acc;
      
      Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
      insert con;
            
      string callKey = '123';
      Case cs = FSL_WorkOrderIntake.createWOCase(acc.Id, con.Id, callKey);
      
      System.assertEquals('New Case for D3 WorkOrder Intake for CallKey : '+callKey, cs.Subject);
      System.assertEquals('D3', cs.call_Source__c);
      System.assertEquals('New', cs.Status);
     // System.assertNotEquals(null, cs.ServiceContractId);
 
    }
    //isServiceConrtactUpdateRequired(ServiceContract oldMemberContract, ServiceContract newMemberContract)
    //FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
   //   FSL_Account.IAccountService service = accountFactory.createService();          
    //  FSL_Account.MembershipInformation info = parser.parse( jsonParser.calls[0] );
   //   List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );
  
        @isTest static void testCreateNewServiceContract() {
            // Setup test data
            FSL_Account.IFactory accountFactory = new FSL_Account.Factory();
            FSL_Account.MembershipInformation info = new FSL_Account.MembershipInformation();
            FSL_Account.MembershipInformationParser parser = accountFactory.createMembershipInformationParser();
            FSL_Account.IAccountService service = accountFactory.createService();
                        
         //   FSL_Account.MembershipInformation info = parser.parse( jsonParser.calls[0] );
            List<Account> accounts = service.getOrCreateMemberPersonAccounts( new List<FSL_Account.MembershipInformation>{ info } );
            
            
            
            
            
            // Populate `info` with test data
            
            WorkOrder workOrder = new WorkOrder();
            // Setup WorkOrder test data
            
          //  Datetime callCreateDateTime = Datetime.now();
            
         //   Test.startTest();
            // Call the method under test
        //    ServiceContract resultContract = FSL_WorkOrderIntake.getOrCreateMembershipContract(info, workOrder, callCreateDateTime);
         //   Test.stopTest();
            
            // Perform assertions to verify behavior
          //  System.assertNotEquals(null, resultContract, 'The contract should not be null.');
            // Add more assertions here
        }

                              
 
    @isTest
    static void workOrder_nullExpirationDateCheck_NotNullMemberSince(){        
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382121351011003","originalMemberId": "4382121351011003","expirationDate": "","memberLevel": "Plus","memberSince": "2015","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011003","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder(); 
 
        List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract LIMIT 1];
     //   List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract where AAA_ACA_Membership16ID__c ='4382121351011003' LIMIT 1];
        //System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
       // System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);
        //System.assertNotEquals(null, resultContract, 'The contract should not be null.');
       // Assert.areEqual(contracts[0].StartDate, contracts[0].EndDate);
    }

    /*@isTest
    static void WorkOrderResponseWOLookCatch()
    {
        // Insert required test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        WorkOrder wo = new WorkOrder(AccountId = acc.Id, Status = 'Open');
        insert wo;
        
        // Add more data setup here based on what's required by createWOIntakeCall
        
        System.Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FSL_WOJeopardy_MockResponseGenerator(false));
        FSL_WorkOrderResponse res = FSL_DataFactory.createWOIntakeCall('FSL_LightCallException');
        System.Test.StopTest();
    }*/
 
/*
   
     @isTest
    static void workOrder_NotNullExpirationDateCheck_NullMemberSince(){                
        string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382121351011013","originalMemberId": "4382121351011013","expirationDate": "2025-06-06","memberLevel": "PLUS","memberSince": "","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011013","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        // FSL_JSonParserWorkOrder jsonWorkOrder   = (FSL_JSonParserWorkOrder)Json.deserialize(payload, FSL_JSonParserWorkOrder.class);
        // WorkOrder myWorkOrder                   = FSL_WorkOrderIntake.createWorkOrder(jsonWorkOrder);
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        Test.startTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
        Test.stopTest();
        List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract where AAA_ACA_Membership16ID__c ='4382121351011013' LIMIT 1];
        System.Debug('workOrder_nullExpirationDateCheck::contracts.Size()::'  + contracts.Size());
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);
        //Assert.areEqual(contracts[0].StartDate, contracts[0].EndDate);
    }

    @isTest
    static void workOrder_NotNullExpirationDate_NotNullMemberSince_ExpLTMS(){     
        Test.setMock(HttpCalloutMock.class, new MockResponse());           
       string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382121351011033","originalMemberId": "4382121351011033","expirationDate": "2025-06-06","memberLevel": "PLUS","memberSince": "2030","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011033","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
       Test.setMock(HttpCalloutMock.class, new MockResponse());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        Test.startTest();
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
        Test.stopTest();
        List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract where AAA_ACA_Membership16ID__c ='4382121351011033' LIMIT 1];
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);
        //Assert.areEqual(contracts[0].StartDate, contracts[0].EndDate);
    }

    @isTest
    static void workOrder_NotNullExpirationDate_NotNullMemberSince_ExpGTMS(){  
        Test.setMock(HttpCalloutMock.class, new MockResponse());              
         string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382121351011043","originalMemberId": "4382121351011043","expirationDate": "2025-06-06","memberLevel": "PLUS","memberSince": "2015","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011043","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
         Test.setMock(HttpCalloutMock.class, new MockResponse());
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
 
        List<ServiceContract> contracts = [select StartDate, EndDate from ServiceContract where AAA_ACA_Membership16ID__c ='4382121351011043' LIMIT 1];
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);
        //Assert.IsTrue(contracts[0].StartDate < contracts[0].EndDate);
    }

    @isTest
    static void workOrder_nullExpirationDateCheck_nullMemberSinceUpdateCheck(){        
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        // This will set the values for start and ene on the primary and the house hold service contract.
        workOrder_nullExpirationDateCheck_nullMemberSince();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        //Lets update the primary membership start and end and it shall reflect on the parent also.
        string payload = '{"id": "90c3107e-235f-45c2-956c-24f96cf87467","requestEventType": "CREATE","subType": "CREATE","version": "0.1","sourceSystem": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"targetSystem": {"systemId": "Salesforce","systemOrganization": {"name": "Salesforce","code": "212"}},"createDate": 1685650610166,"responseURL": "lxmtld2kuat02.aaacorp.com/d3adapter/callback","calls": [{"callKey": "212-20230601-101100","callDate": "2023-06-01","callId": 101100,"version": "0.0.1","channel": {"channelType": "CALL_CENTER","org": {"name": "ACA","code": "212"},"contact": {"userId": "JFORTNEY","contactType": "AGENT"}},"customer": {"memberships": [{"membershipType": "MEMBER","isLocalClub": true,"org": {"name": "*******AAA Club Alliance","code": "212"},"id": "4382121351011003","originalMemberId": "4382121351011003","expirationDate": "2025-06-06","memberLevel": "PLUS","memberSince": "2016","memberStatus": "A","entitlements": [{"associates": 4,"callsAllowed": 50,"callsRemaining": 39,"callsUsed": 10,"chargeableCalls": 1,"currentCalls": 1,"onlineGarageMember": false,"longTowAllowed": false}]}],"contact": {"customerId": "4382121351011003","contactType": "CUSTOMER","firstName": "JAMES101100","lastName": "FORTNEY101100","phones": [{"phoneType": "HOME","phoneNumber": "8562189757","preferred": true,"smsOptIn": false}],"emails": [{"emailType": "PERSONAL","address": "jfortney101100@verizon.net"}]},"languagePreference": "ENGLISH"},"vehicle": {"vehicleType": "PS","year": 2022,"make": "HONDA","model": "ACCORD","color": "SILVER","driveType": "2WD","fuelType": "GAS"},"service": {"callType": "MEMBER","timezoneId": "America/New_York","timezoneOffset": "UTC-04:00","status": {"status": "SP","updateCode": "SP","modifiedDate": "2023-06-01T20:16:49.338408Z[UTC]","pta": "2023-06-01T21:16:49Z[UTC]","waitTime": 60},"facility": {"foiType": "ERS","location": {"latitude": 41.38449,"longitude": -83.65047,"address": {"addressType": "PHYSICAL","full": "921 N. MAIN STREET, BOWLING GREEN, OH 43402","street": "921 N. MAIN STREET","city": "BOWLING GREEN","state": "OH","postalCode": "43402"}},"id": "OHN02","name": "FRANKS AUTOMOTIVE, L.L.C.","contacts": [{"userId": "Wendy-Driver","contactType": "FACILITY","phones": []}]},"troubleCodes": [{"troubleCodeType": "PACESETTER","code": "L402","description": "Out of Gasoline"}, {"troubleCodeType": "PROBLEM","code": "5","description": "FUEL DELIVERY"}],"serviceLocations": [{"serviceLocationType": "BREAKDOWN","foi": {"foiType": "ADDRESS","location": {"latitude": 41.6965,"longitude": -83.57649,"address": {"addressType": "PHYSICAL","full": "4305 BIRCHALL RD , TOLEDO , OH 43612 ","street": "BIRCHALL RD","streetNumber": "4305","streetDirection": "","streetName": "BIRCHALL RD","crossStreet": "ROYALTON RD","city": "TOLEDO","state": "OH","postalCode": "43612"},"highway": "","grid": "NW709D","locationCode": "FS"}}}],"collision": false,"redFlag": false,"numberOfPassengers": 0,"needsFlatbed": false,"flatbedRequested": false},"payment": {"required": false},"comments": [{"system": {"systemId": "212","systemOrganization": {"name": "ACA","code": "212"}},"contact": {"userId": "JFORTNEY","contactType": "AGENT"},"commentDate": "2023-06-01T20:16:49Z[UTC]","commentType": "NORMAL","visibility": "EXTERNAL","text": "Triage selection: L402 Out of Gasoline"}]}]}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProcessWorkOrderIntake/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(payload);
        RestContext.request = req;
        RestContext.response= res;       
        
        FSL_WorkOrderResponse resp =  FSL_WorkOrderIntake.UpsertWorkOrder();        
 
        //First record will be parent and second will be the primary membership
        List<ServiceContract> contracts = [select ID,Name, StartDate, EndDate, AAA_ACA_MembershipID__c, AAA_ACA_Membership16ID__c from ServiceContract 
                                            where (AAA_ACA_MembershipID__c ='1351011' and AAA_ACA_Membership16ID__c = null ) or (AAA_ACA_Membership16ID__c ='4382121351011003') order by Name];
        
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].StartDate::'  + contracts[0].StartDate);
        System.Debug('workOrder_nullExpirationDateCheck::contracts[0].EndDate::'    + contracts[0].EndDate);

        System.Debug('workOrder_nullExpirationDateCheck::contracts[1].StartDate::'  + contracts[1].StartDate);
        System.Debug('workOrder_nullExpirationDateCheck::contracts[1].EndDate::'    + contracts[1].EndDate);

        /*Assert.areEqual(contracts[0].StartDate  , Date.newInstance(2016,6,6));
        Assert.areEqual(contracts[0].EndDate    , Date.newInstance(2025,6,6));

        Assert.areEqual(contracts[1].StartDate  , Date.newInstance(2016,6,6));
        Assert.areEqual(contracts[1].EndDate    , Date.newInstance(2025,6,6));
    }*/


    //End - Varun Test Cases Class
   
    private class MockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String reqEndpoint = req.getEndpoint();
            String bodyJSONStr = '';
            res.setHeader('Content-Type', 'application/json');

            if (reqEndpoint == 'testurl') {   // Util_ManageAccessTokens::callOAuth
                bodyJSONStr = '{"access_token":"test1234"}';
            } else if (reqEndpoint.contains('testSearch')) {    // FSL_ValidateMembershipNumber::invokeCallout
                bodyJSONStr = '{"statusCode":200,"statusDescription":"Success","customer":{"languagePreference":null,"contact":{"contactType":"CUSTOMER","title":null,"firstName":"Test","middleName":"","lastName":"Test","suffix":"","phones":[{"phoneType":"MOBILE","phoneNumber":"9785552168","preferred":true,"smsOptIn":false},{"phoneType":"WORK","phoneNumber":"9785555404","preferred":false,"smsOptIn":false,"phoneExtension":""}],"emails":[{"emailType":"PERSONAL","address":null}]},"memberships":[{"dispatchCenter":"","dealerName":"","dealerPhone":"","goodwill":"","membershipType":"Associate Member","sponsor":"","authorizationCode":"","authorizationLevel":"","org":{"name":"","code":"240"},"memberLevel":"Basic","isLocalClub":true,"memberStatus":"Active","program":null,"programName":"","programPhone":"","programMaxMileage":"","memberBirthday":"1990-01-01","memberSince":"2017","memberSinceDate":"2017-07-06","originalMemberId":"6202404941373216","id":"6202404941373216","expirationDate":"2023-07-15","startDate":"2022-07-16","primaryMemberExpirationDate":"2023-04-01","primaryMemberStartDate":"2022-07-16","riders":"","ersAbuser":"","badCheck":"Active","motorcycleIndicator":"","cdxMessage":"","primaryValid":"","primaryPaid":"","cancelCode":null,"cancelType":"","cancellationDate":"","inArrears":"","inRenewal":"","totalPastDue":null,"totalAmountApplied":null,"totalAmountDue":null,"renewalExpirationDate":"","membershipPaidThroughDate":"2023-07-15","billPlan":"","emsMessage":"","entitlements":[{"serviceChargeIndicator":false,"associates":null,"chargeableCalls":null,"currentCalls":null,"callsAllowed":"4","callsRemaining":null,"callsUsed":null,"onlineGarageMember":false,"longTowAllowed":false,"longTowKilometers":null,"longTowMiles":null,"rentalDays":null,"homeLockoutEntitled":false,"carRentalEntitled":false,"RVUsage":false,"CAPREeligible":false,"sameDayService":null,"joinFeeEndDate":"","joinFeePerCallFlag":"","joinFeeNumberOfDays":null,"joinFeeAmount":null,"serviceChargeAmount":null,"unpaidCardFeeAmount":null}]}],"customProperties":[{"name":"In Renewal","value":"Membership is in renewal, please attempt to collect payment in MRM. If no payment is made, the member may be billed a service charge fee for their service today."},{"name":"Home Lockout Entitled","value":""},{"name":"Car Rental Entitled","value":""},{"name":"RV Usage","value":""},{"name":"Same Day Service","value":""},{"name":"CAPRE","value":""}],"impairments":[{"name":"In Renewal","message":""}],"foi":{"foiType":"ADDRESS","location":{"latitude":null,"longitude":null,"address":{"addressType":"PHYSICAL","full":"2914341 MAIN STTEMPLETON, MA 01468USA","street":"2914341 MAIN ST","streetNumber":"","line2":null,"streetDirection":"","streetName":"2914341 MAIN ST","city":"TEMPLETON","state":"MA","postalCode":"01468","country":"USA"}}}}}';
            }

            res.setBody(bodyJSONStr);
            res.setStatusCode(200);

            return res;
        }
    }
    
    /***EMI Start******For SSFI-487**/
    
    @isTest
    static void testServiceContractUpdateRequiredTrue() {
        // Create old and new service contracts with different values to trigger updates
        ServiceContract oldContract = new ServiceContract(
            AAA_ACA_Membership_Type__c = 'Type A',
            StartDate = Date.newInstance(2023, 1, 1),
            EndDate = Date.newInstance(2023, 12, 31),
            AAA_ACA_Member_Status__c = 'Active',
            AAA_ACA_Membership_Status__c = 'Valid',
            AAA_ACA_Membership_Coverage_Level__c = 'Standard'
        );

        ServiceContract newContract = new ServiceContract(
            AAA_ACA_Membership_Type__c = 'Type B',  // Different
            StartDate = Date.newInstance(2024, 1, 1),  // Different
            EndDate = Date.newInstance(2024, 12, 31),  // Different
            AAA_ACA_Member_Status__c = 'Inactive',  // Different
            AAA_ACA_Membership_Status__c = 'Expired',  // Different
            AAA_ACA_Membership_Coverage_Level__c = 'Premium'  // Different
        );

        // Assert that the method returns true as the values are different
        Boolean result = FSL_WorkOrderIntake.isServiceConrtactUpdateRequired(oldContract, newContract);
        System.assertEquals(true, result, 'Expected update to be required.');
    }

    @isTest
    static void testServiceContractUpdateRequiredFalse() {
        // Create old and new service contracts with identical values
        ServiceContract oldContract = new ServiceContract(
            AAA_ACA_Membership_Type__c = 'Type A',
            StartDate = Date.newInstance(2023, 1, 1),
            EndDate = Date.newInstance(2023, 12, 31),
            AAA_ACA_Member_Status__c = 'Active',
            AAA_ACA_Membership_Status__c = 'Valid',
            AAA_ACA_Membership_Coverage_Level__c = 'Standard'
        );

        ServiceContract newContract = new ServiceContract(
            AAA_ACA_Membership_Type__c = 'Type A',
            StartDate = Date.newInstance(2023, 1, 1),
            EndDate = Date.newInstance(2023, 12, 31),
            AAA_ACA_Member_Status__c = 'Active',
            AAA_ACA_Membership_Status__c = 'Valid',
            AAA_ACA_Membership_Coverage_Level__c = 'Standard'
        );

        // Assert that the method returns false as the values are the same
        Boolean result = FSL_WorkOrderIntake.isServiceConrtactUpdateRequired(oldContract, newContract);
        System.assertEquals(false, result, 'Expected update to not be required.');
    }

    @isTest
    static void testNullContracts() {
        // Test with null contracts to ensure method handles null safely
        Boolean result = FSL_WorkOrderIntake.isServiceConrtactUpdateRequired(null, null);
        System.assertEquals(false, result, 'Expected no update to be required with null contracts.');

        // One contract null, the other not
        ServiceContract oldContract = new ServiceContract(
            AAA_ACA_Membership_Type__c = 'Type A'
        );

        result = FSL_WorkOrderIntake.isServiceConrtactUpdateRequired(oldContract, null);
        System.assertEquals(false, result, 'Expected no update to be required with one null contract.');
    }

	

    @isTest
    static void testExpirationDateNull() {
        // Create a ServiceContract instance
        ServiceContract newContract = new ServiceContract();

        // Call the method with expirationDate as null
        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '2024', null);

        // Assert that both StartDate and EndDate are set to today's date
        System.assertEquals(Date.today(), newContract.StartDate, 'StartDate should be today.');
        System.assertEquals(Date.today(), newContract.EndDate, 'EndDate should be today.');
    }

    @isTest
    static void testValidMemberSinceAndExpirationDate() {
        // Create a ServiceContract instance
        ServiceContract newContract = new ServiceContract();

        // Call the method with valid expiration date and memberSince value
        Date expirationDate = Date.newInstance(2024, 12, 31);
        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '2020', expirationDate);

        // Assert that the StartDate is correctly calculated
        System.assertEquals(Date.newInstance(2020, 12, 31), newContract.StartDate, 'StartDate should be calculated correctly.');
        System.assertEquals(expirationDate, newContract.EndDate, 'EndDate should match the provided expiration date.');
    }

    @isTest
    static void testInvalidMemberSince() {
        // Create a ServiceContract instance
        ServiceContract newContract = new ServiceContract();

        // Call the method with an invalid memberSince value
        Date expirationDate = Date.newInstance(2024, 12, 31);
        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '1800', expirationDate);

        // Assert that StartDate is set to EndDate due to invalid memberSince
        System.assertEquals(expirationDate, newContract.StartDate, 'StartDate should be set to EndDate for invalid memberSince.');
        System.assertEquals(expirationDate, newContract.EndDate, 'EndDate should match the provided expiration date.');
    }

    @isTest
    static void testMemberSinceExceedsEndDate() {
        // Create a ServiceContract instance
        ServiceContract newContract = new ServiceContract();

        // Call the method with memberSince year greater than expiration date's year
        Date expirationDate = Date.newInstance(2024, 12, 31);
        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '2025', expirationDate);

        // Assert that StartDate is set to EndDate since the calculated start date is beyond the end date
        System.assertEquals(expirationDate, newContract.StartDate, 'StartDate should be set to EndDate if calculated date exceeds EndDate.');
        System.assertEquals(expirationDate, newContract.EndDate, 'EndDate should match the provided expiration date.');
    }

    @isTest
    static void testBlankOrInvalidMemberSinceString() {
        // Create a ServiceContract instance
        ServiceContract newContract = new ServiceContract();

        // Call the method with blank and invalid memberSince values
        Date expirationDate = Date.newInstance(2024, 12, 31);

        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '', expirationDate);
        System.assertEquals(expirationDate, newContract.StartDate, 'StartDate should be set to EndDate for blank memberSince.');

        FSL_WorkOrderIntake.UpdateStartEndDateOnContract(newContract, '00', expirationDate);
        System.assertEquals(expirationDate, newContract.StartDate, 'StartDate should be set to EndDate for memberSince as 00.');
    }

    
    /***EMI End****For SSFI-487**/
    
}