/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 04-03-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest 
public with sharing class RestApi_PatchCallTest {
    public RestApi_PatchCallTest() {
    }
    
    private static ThirdPartyIntegrationTest.MockFactory mockFactory;
    private static ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService;
    private static TowbookIntegrationTest.MockTowbookIntegrationService mockDispatcher;
    private static ThirdPartyIntegrationTest.MockThirdPartyIntegrationService mockThirdparty;
    private static FSL_ApplicationLogTest.ApplicationLogServiceMock logService;
    private static RestApi_PatchCall.PatchCallRequest patchCallRequest = null;
    private static FSL_WorkOrderTest.WorkOrderServiceMock mockWorkOrderService;
    
    
    
    private static TowbookIntegrationTest.MockFactory towmockFactory;
    private static ThirdPartyIntegration.IThirdPartyDispatcherService towdispatcherService;
    private static TowbookIntegrationTest.MockTowbookIntegrationService towmockDispatcher;
    private static FSL_ApplicationLogTest.ApplicationLogServiceMock towmockLogService;
    private static ThirdPartyIntegration.IntegrationSupportServicesWrapper towmockIntegrationWrapper;
    private static RestApi_PatchCall.PatchCallRequest towpatchCallRequest = null;
    
    private static TowbookIntegration.TowbookInboundRequest tbkInReq;
    private static TowbookIntegration.TowbookInboundRequest tbkInRequest;
    
    private static String body;
    
    private static void constructRestContext() {
        List<RestApi_PatchCall.KeyValuePair> tempList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        valuePair.key = 'accept';
        valuePair.value = 'accept';
        RestApi_PatchCall.KeyValuePair valuePair1  = new RestApi_PatchCall.KeyValuePair();
        valuePair1.key = 'location';
        valuePair1.value = 'location1';
        RestApi_PatchCall.KeyValuePair valuePair2  = new RestApi_PatchCall.KeyValuePair();
        valuePair2.key = 'imageurl';
        valuePair2.value = 'imageurl1';
        RestApi_PatchCall.KeyValuePair valuePair3  = new RestApi_PatchCall.KeyValuePair();
        valuePair3.key = '1';
        valuePair3.value = '1';
        tempList.add(valuePair);
        tempList.add(valuePair1);
        tempList.add(valuePair2);
        tempList.add(valuePair3);
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = tempList;
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        patchCallRequest.callInfo.status = 'Scheduled';
        // patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        roadAssObj.ServiceLineItems.add(servLiteList);
        roadAssObj.reasonCode='2';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
     private static void constructRestContext1() {
        List<RestApi_PatchCall.KeyValuePair> tempList1 = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        valuePair.key = 'goa';
        valuePair.value = 'goa';
        RestApi_PatchCall.KeyValuePair valuePair1  = new RestApi_PatchCall.KeyValuePair();
        valuePair1.key = 'location';
        valuePair1.value = 'location1';
        RestApi_PatchCall.KeyValuePair valuePair2  = new RestApi_PatchCall.KeyValuePair();
        valuePair2.key = 'imageurl';
        valuePair2.value = 'imageurl1';
        RestApi_PatchCall.KeyValuePair valuePair3  = new RestApi_PatchCall.KeyValuePair();
        valuePair3.key = 'driverEta';
        valuePair3.value = 'driverEta1';
        tempList1.add(valuePair);
        tempList1.add(valuePair1);
        tempList1.add(valuePair2);
        tempList1.add(valuePair3);
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = tempList1;
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        //patchCallRequest.callInfo.status = 'Scheduled';
         patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        roadAssObj.ServiceLineItems.add(servLiteList);
        roadAssObj.reasonCode='2';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
    
    private static void constructRestContextDynamic(string parameterZero) {
        List<RestApi_PatchCall.KeyValuePair> keyValuePairList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        List<string> valuePairList = new List<string>{parameterZero, 'location', 'imageurl', '2'};
            for(string eachStr : valuePairList){
                RestApi_PatchCall.KeyValuePair valuePair123  = new RestApi_PatchCall.KeyValuePair();
                valuePair123.key = eachStr;
                valuePair123.value = eachStr;
                keyValuePairList.add(valuePair123);
            }
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest();
        
        //Prepare RequestHeader
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = keyValuePairList;
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        
        //Prepare CallInfo
        //patchCallRequest.callInfo.status = 'Scheduled';
        //patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        
        
        //Prepare RoadSideAssistanceDetail including Driverdata, comments, facility, servicelineitem
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        roadAssObj.ServiceLineItems.add(servLiteList);
        roadAssObj.reasonCode='2';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
    private static void constructRestContextWithRoadSideNull(string parameterZero , boolean roadSide, boolean serviLi) {
        List<RestApi_PatchCall.KeyValuePair> keyValuePairList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        List<string> valuePairList = new List<string>{parameterZero, 'location', 'imageurl', '3'};
            for(string eachStr : valuePairList){
                RestApi_PatchCall.KeyValuePair valuePair123  = new RestApi_PatchCall.KeyValuePair();
                valuePair123.key = eachStr;
                valuePair123.value = eachStr;
                keyValuePairList.add(valuePair123);
            }
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest();
        
        //Prepare RequestHeader
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = keyValuePairList;
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        
        //Prepare CallInfo
        //patchCallRequest.callInfo.status = 'Scheduled';
        //patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        
        
        //Prepare RoadSideAssistanceDetail including Driverdata, comments, facility, servicelineitem
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        /*if(!serviLi){
roadAssObj.ServiceLineItems = null;
}
else{*/
        roadAssObj.ServiceLineItems.add(servLiteList);
        //}
        roadAssObj.reasonCode='2';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        
        patchCallRequest.roadsideAssistanceDetail = null;
        
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
    private static void constructRestContextWithServLiNull(string parameterZero , boolean roadSide, boolean serviLi) {
        List<RestApi_PatchCall.KeyValuePair> keyValuePairList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        List<string> valuePairList = new List<string>{parameterZero, 'location', 'imageurl', '4'};
            for(string eachStr : valuePairList){
                RestApi_PatchCall.KeyValuePair valuePair123  = new RestApi_PatchCall.KeyValuePair();
                valuePair123.key = eachStr;
                valuePair123.value = eachStr;
                keyValuePairList.add(valuePair123);
            }
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest();
        
        //Prepare RequestHeader
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = keyValuePairList;
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        
        //Prepare CallInfo
        //patchCallRequest.callInfo.status = 'Scheduled';
        //patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        
        
        //Prepare RoadSideAssistanceDetail including Driverdata, comments, facility, servicelineitem
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        /*if(!serviLi){
roadAssObj.ServiceLineItems = null;
}
else{*/
        roadAssObj.ServiceLineItems = null;
        //}
        roadAssObj.reasonCode = '2';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
    private static void constructRestContextWithRSRSNull(string parameterZero , boolean roadSide, boolean serviLi) {
        List<RestApi_PatchCall.KeyValuePair> keyValuePairList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        List<string> valuePairList = new List<string>{parameterZero, 'location', 'imageurl', '5'};
            for(string eachStr : valuePairList){
                RestApi_PatchCall.KeyValuePair valuePair123  = new RestApi_PatchCall.KeyValuePair();
                valuePair123.key = eachStr;
                valuePair123.value = eachStr;
                keyValuePairList.add(valuePair123);
            }
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest();
        
        //Prepare RequestHeader
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = keyValuePairList;
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        
        //Prepare CallInfo
        //patchCallRequest.callInfo.status = 'Scheduled';
        //patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        
        
        //Prepare RoadSideAssistanceDetail including Driverdata, comments, facility, servicelineitem
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        /*if(!serviLi){
roadAssObj.ServiceLineItems = null;
}
else{*/
        roadAssObj.ServiceLineItems = null;
        //}
        roadAssObj.reasonCode = 'abcd';
        roadAssObj.resolutionCode='200';
        roadAssObj.status='test';
        
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    
    private static void constructRestContextRSResolutionCancel(string parameterZero , boolean roadSide, boolean serviLi) {
        List<RestApi_PatchCall.KeyValuePair> keyValuePairList = new List<RestApi_PatchCall.KeyValuePair>();
        RestApi_PatchCall.KeyValuePair valuePair = new RestApi_PatchCall.KeyValuePair();
        List<string> valuePairList = new List<string>{parameterZero, 'location', 'imageurl', '6'};
            for(string eachStr : valuePairList){
                RestApi_PatchCall.KeyValuePair valuePair123  = new RestApi_PatchCall.KeyValuePair();
                valuePair123.key = eachStr;
                valuePair123.value = eachStr;
                keyValuePairList.add(valuePair123);
            }
        patchCallRequest = new RestApi_PatchCall.PatchCallRequest();
        
        //Prepare RequestHeader
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.id='';
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.requestHeader.channel.parameters = keyValuePairList;
        patchCallRequest.requestHeader.sourceOrg = new RestApi_PatchCall.Organization();
        patchCallRequest.requestHeader.sourceOrg.code = 'sourceorgcode';
        patchCallRequest.requestHeader.sourceOrg.name='sourceorgname';
        
        //Prepare CallInfo
        //patchCallRequest.callInfo.status = 'Scheduled';
        //patchCallRequest.CallInfo.status = 'Spotted';
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        
        
        //Prepare RoadSideAssistanceDetail including Driverdata, comments, facility, servicelineitem
        patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
        RestApi_PatchCall.RoadsideAssistanceDetail roadAssObj = new RestApi_PatchCall.RoadsideAssistanceDetail();
        roadAssObj.comments = new List<RestApi_PatchCall.Comment>();
        RestApi_PatchCall.DriverData ddObj = new RestApi_PatchCall.DriverData();
        RestApi_PatchCall.Facility facObj = new RestApi_PatchCall.Facility();
        ddObj.latitude = 1.098786866;
        ddObj.longitude = 5.09878686;
        ddObj.dispatchTime = datetime.now().toString();
        ddObj.facility = facObj;
        ddObj.servicingStationEmployeeName='test';
        ddObj.servicingStationEmployeeId='123456789';
        ddObj.truckId='123456789';
        RestApi_PatchCall.Comment commObj = new RestApi_PatchCall.Comment();
        commObj.commentDateTime = datetime.now().toString();
        commObj.commenter = 'commenter';
        commObj.commentType = 'type';
        commObj.text = 'text';
        commObj.visibility = 'visibility';
        RestApi_PatchCall.ServiceLineItem servLiteList = new RestApi_PatchCall.ServiceLineItem();
        servLiteList.charge = 20.20;
        servLiteList.quantity = 10;
        servLiteList.service = 'service';        
        roadAssObj.comments.add(commObj);
        roadAssObj.driverData = ddObj;
        /*if(!serviLi){
roadAssObj.ServiceLineItems = null;
}
else{*/
        roadAssObj.ServiceLineItems = null;
        //}
        roadAssObj.reasonCode = '2';
        roadAssObj.resolutionCode='';
        roadAssObj.status='test';
        
        patchCallRequest.roadsideAssistanceDetail.add(roadAssObj);
        
        
        body = JSON.serialize(patchCallRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/call';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueof(body);
        
        RestContext.request = req;
        RestContext.response= res;
        
    }
    private static void setupMocks() {
        mockFactory = new ThirdPartyIntegrationTest.MockFactory();
        thirdPartyService = mockFactory.createService();
        mockThirdparty = mockFactory.getMockService();
        logService =  (FSL_ApplicationLogTest.ApplicationLogServiceMock)(new FSL_ApplicationLogTest.FactoryMock().createService());
        system.debug('logService:'+logService);
        towmockFactory = new TowbookIntegrationTest.MockFactory();
        towdispatcherService = towmockFactory.createService();
        towmockDispatcher = towmockFactory.getMockService();
        towmockLogService =  new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        
        towmockIntegrationWrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
        towmockIntegrationWrapper.contactService = new FSL_ContactTest.ContactServiceMock();
        towmockIntegrationWrapper.serviceAppointmentService = new FSL_ServiceAppointmentTest.ServiceAppointmentServiceMock();
        towmockIntegrationWrapper.serviceLineItemService = new FSL_ServiceLineItemTest.ServiceLineItemServiceMock();
        
        mockWorkOrderService = new FSL_WorkOrderTest.WorkOrderServiceMock();
        towmockIntegrationWrapper.workOrderservice = mockWorkOrderService;
        
        
        //Towbookinboundrequest preparation
        
        
        
    }
    
    
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedRsnull() {
        setupMocks();
        System.test.startTest();
        TowbookIntegration towBookObj = new  TowbookIntegration();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContextWithRoadSideNull('accept', true, true);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            try{
                respPatchCall = RestApi_PatchCall.patchCall();
            }      catch (Exception ex) {
                System.assert(false, 'should not reach here because no exception should be thrown');   
            }
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                
                newDispatcher.handleAcceptRequest(null,patchCallRequest,null);
            }      catch (Exception ex) {}
            
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedSLnull() {
        
        setupMocks();
        System.test.startTest();
																																																															  
																	   
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContextWithServLiNull('accept', true, true);
         tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.accept;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            try{
                respPatchCall = RestApi_PatchCall.patchCall();
            }      catch (Exception ex) {
                System.assert(false, 'should not reach here because no exception should be thrown');   
            }
            
            
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
            
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedInNKReqExce1() {
        
        setupMocks();
        System.test.startTest();
        //ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        //registerMockDispatcher(thirdPartyService, dispatcherService);
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContextWithRoadSideNull('', true, true);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            try{
                respPatchCall = RestApi_PatchCall.patchCall();
            }      catch (Exception ex) {
                System.assert(false, 'should not reach here because no exception should be thrown');   
            }
            
      	   // ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
           // TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
           // try{   
                //newDispatcher.sendRefusedPlatformEvent(null,patchCallRequest,'');
           // }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
    }
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedInNKReqExce2() {
        
        setupMocks();
        System.test.startTest();
        //ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        //registerMockDispatcher(thirdPartyService, dispatcherService);
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContextWithRSRSNull('accept', true, false);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            try{
                respPatchCall = RestApi_PatchCall.patchCall();
            }      catch (Exception ex) {
                System.assert(false, 'should not reach here because no exception should be thrown');   
            }
           // ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
           // TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
           // try{   
                //newDispatcher.sendRefusedPlatformEvent(null,patchCallRequest,'');
            //}      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
    }
    
    // Tests the methods of the RestApi_PatchCall class
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturned() {
        
        setupMocks();
        System.test.startTest();
        //ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyService = new ThirdPartyIntegration.ThirdPartyIntegrationService(mockIntegrationWrapper, mockLogService);
        //registerMockDispatcher(thirdPartyService, dispatcherService);
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContext();
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            try{
                respPatchCall = RestApi_PatchCall.patchCall();
            }      catch (Exception ex) {
                System.assert(false, 'should not reach here because no exception should be thrown');   
            }
            //ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            //TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            //try{   
                //newDispatcher.sendRefusedPlatformEvent(null,patchCallRe,'');
            //}      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
    }
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedGoa() {
        
        setupMocks();
        string inputStr = 'goa';
        constructRestContextDynamic(inputStr);
        tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.goa;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
               
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedGoaRSNull() {
        
        setupMocks();
        string inputStr = 'goa';
        constructRestContextRSResolutionCancel(inputStr,true,true);
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();     
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedAccept() {
                 
        /***/
       /* FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        List<Account> accounts = FSL_DataFactory.createAccounts( 2 );
        insert accounts;
        
        List<Contact> contacts = FSL_DataFactory.createContacts( 2 );
        for( Integer i = 0; i < 2; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        Id contactId1 = contacts[0].id;
        Id contactId2 = contacts[1].id;
        WorkOrder workOrder1 = new WorkOrder(  ContactId = contactId1, Status = 'Spotted', 
                                             External_Id__c = '123-456-7890',Call_Id__c = '78901', Call_Date__c = '44441',Servicing_Technology_Type__c = 'TOWBOOK',
                                             Vehicle_Profile__c = 'My Vehicle # 1' );
        WorkOrder workOrder2 = new WorkOrder( ContactId = contactId2, Status = 'Spotted', 
                                             External_Id__c = '123-456-7891',Call_Id__c = '33332', Call_Date__c = '44442',Servicing_Technology_Type__c = 'TOWBOOK',
                                             Vehicle_Profile__c = 'My Vehicle # 12' );
        
        insert workOrder1;
        insert workOrder2;
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId2 };
            
            List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();
        
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;
        
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        
        ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrder1.Id, contactId1, System.now(), 1800, 'Subject1' );
        breakdownSa.ParentRecordId = workOrder1.Id;
        serviceAppointments.add( breakdownSa );
        ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrder2.Id, contactId2, System.now() + 1800, 1800, 'Subject2' );
        towSa.ParentRecordId = workOrder2.Id;
        serviceAppointments.add( towSa );
        
        insert serviceAppointments;
        system.debug('serviceAppointments'+serviceAppointments);
        */
         WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'TOWBOOK';
        wo.External_Id__c = '123-456-7890';
        
        insert wo;
        FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        List<Account> accounts = FSL_DataFactory.createAccounts( 2 );
        insert accounts;
        
        List<Contact> contacts = FSL_DataFactory.createContacts( 2 );
        for( Integer i = 0; i < 2; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        Id contactId1 = contacts[0].id;
        Id contactId2 = contacts[1].id;
      //  WorkOrder workOrder1 = new WorkOrder(  ContactId = contactId1, Status = 'Spotted', 
                                            // External_Id__c = '123-456-7890',Call_Id__c = '78901', Call_Date__c = '44441',Servicing_Technology_Type__c = 'TOWBOOK',
                                            // Vehicle_Profile__c = 'My Vehicle # 1' );
      //  WorkOrder workOrder2 = new WorkOrder( ContactId = contactId2, Status = 'Spotted', 
                                           //  External_Id__c = '123-456-7891',Call_Id__c = '33332', Call_Date__c = '44442',Servicing_Technology_Type__c = 'TOWBOOK',
                                           //  Vehicle_Profile__c = 'My Vehicle # 12' );
        
       // insert workOrder1;
       /// insert workOrder2;
       // dao.workOrders.put( workOrder1.Id, workOrder1 );
       // dao.workOrders.put( workOrder2.Id, workOrder2 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId2 };
            
            List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();
        
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;
        
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        
        ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, wo.Id, contactId1, System.now(), 1800, 'Subject1' );
        breakdownSa.ParentRecordId = wo.Id;
        serviceAppointments.add( breakdownSa );
        ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, wo.Id, contactId2, System.now() + 1800, 1800, 'Subject2' );
        towSa.ParentRecordId = wo.Id;
        serviceAppointments.add( towSa );
        
        insert serviceAppointments;
        system.debug('serviceAppointments'+serviceAppointments);
        /***/
        
        setupMocks();
        string inputStr = 'accept';
        constructRestContextDynamic(inputStr);
         tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.accept;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        //patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = '1';
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        //handleAcceptRequest
        /*
try {
RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
respPatchCall = RestApi_PatchCall.patchCall();
}

catch (Exception ex) {
System.assert(false, 'should not reach here because no exception should be thrown');   
}
*/
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
                try{
                    respPatchCall = RestApi_PatchCall.patchCall();
                }      catch (Exception ex) {
                    System.assert(false, 'should not reach here because no exception should be thrown');   
                }
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
                try{   
                    newDispatcher.handleAcceptRequest(tbkInRequest,patchCallRequest,towmockIntegrationWrapper);
                }      catch (Exception ex) {}
                 
                try{ 
                   
                   // newDispatcher.acceptOffer = false;
                    newDispatcher.handleAcceptRequest(tbkInRequest,null,towmockIntegrationWrapper);
               		}      catch (Exception ex) {}
                 try{   
                    // ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
                       TowbookIntegration.TowbookService newDispatcher1 = new TowbookIntegration.TowbookService(null);
                  //  newDispatcher1.acceptOffer=null;
                    newDispatcher1.handleAcceptRequest(null,null,null);
                   } catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnRefuse() {
        
        setupMocks();
        string inputStr = 'refuse';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            try{   
                newDispatcher.handleRefusedRequest(patchCallRequest,towmockIntegrationWrapper);
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturncancelNew1() {
        
        setupMocks();
        string inputStr = 'cancel';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            try{   
                newDispatcher.handleRefusedRequest(patchCallRequest,towmockIntegrationWrapper);
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
     @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturncompleteNew1() {
        
        setupMocks();
        string inputStr = 'complete';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            try{   
                newDispatcher.handleRefusedRequest(patchCallRequest,towmockIntegrationWrapper);
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnStatusUpdate() {
        
        setupMocks();
        string inputStr = 'statusUpdate';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
         ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
         TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
                      
																																													  
																																												
            try{   
                newDispatcher.handleStatusUpdateRequest(patchCallRequest,towmockIntegrationWrapper);
            }
            catch(Exception ex){}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnComplete() {
        
        setupMocks();
        string inputStr = 'complete';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
           
																																												
            try{   
                newDispatcher.handleCallCompleted(patchCallRequest,towmockIntegrationWrapper);
            }
            catch(Exception ex){}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnCancel() {
        
        setupMocks();
        string inputStr = 'cancel';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.handleCallCancelled(patchCallRequest,towmockIntegrationWrapper);
            }
            catch(Exception ex){}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessRSNullCancel() {
        
        setupMocks();
        string inputStr = 'cancel';
        constructRestContextRSResolutionCancel(inputStr,true,true);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.handleCallCancelled(patchCallRequest,towmockIntegrationWrapper);
            }
            catch(Exception ex){}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseBreadCrumb() {
        
        setupMocks();
        string inputStr = 'breadcrumb';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponsePhoto() {
        
        setupMocks();
        string inputStr = 'photo';
        constructRestContextDynamic(inputStr);
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
    
    @IsTest 
    public static void testRestApi_PatchCall_processPatchCallRequest_InvalidJson_ErrorResponseReturned()  {
        setupMocks();
        constructRestContext();
        RestContext.request.requestBody = Blob.valueOf('{[}');
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.test.stopTest();
        System.assertEquals(0, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(400,respPatchCall.header.statusCode, 'Status code must be set to 400');   
    }
    
    @IsTest 
    public static void testRestApi_PatchCall_processPatchCallRequest_ProcessingException_ErrorResponseReturned()  {
        setupMocks();
        constructRestContext();
        System.test.startTest();
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = null;
        
        mockThirdparty.setException(new FSL_WorkOrder.NoMatchingWorkOrdersToUpdateException('Unable to find Call to Update'));
        respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.assertEquals(404,respPatchCall.header.statusCode, 'Status code must be set to 404 for NoMatchingWorkOrdersToUpdateException');   
        
        mockThirdparty.setException(new FSL_WorkOrder.InvalidCommonUpdatePayloadException('Invalid Payload'));
        respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.assertEquals(400,respPatchCall.header.statusCode, 'Status code must be set to 400 for InvalidCommonUpdatePayloadException');
        
        mockThirdparty.setException(new FSL_WorkOrder.UpdateWorkOrderDMLException('DML Exception'));
        respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.assertEquals(500,respPatchCall.header.statusCode, 'Status code must be set to 500 for UpdateWorkOrderDMLException');
        
        mockThirdparty.setException(new FSL_WorkOrder.UpdateWorkOrderException('Work Order Exception'));
        respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.assertEquals(500,respPatchCall.header.statusCode, 'Status code must be set to 500 for UpdateWorkOrderException');
        
        mockThirdparty.setException(new VanillaException('General Exception'));
        respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        System.assertEquals(500,respPatchCall.header.statusCode, 'Status code must be set to 500 for GeneralException');
        System.test.stopTest();
    }
    
    public class VanillaException extends Exception {
    }
    
    @IsTest 
    public static void testRestApi_PatchCall_LogAndConstructResponse_AllPaths_NoExceptionThrown()  {
        setupMocks();
        constructRestContext();
        System.test.startTest();
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = null;
        
        RestApi_PatchCall.PatchCallResponse patchResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        patchResponse.callStatus = 'Cleared';
        
        Integer logCount = logService.saveApplicationLogsCallCount;
        respPatchCall = patchCallApi.LogAndConstructResponse(body, patchCallRequest, patchResponse, logService);
        System.assertEquals(200,respPatchCall.header.statusCode, 'Status code must be set to 200 for success');
        System.assertEquals('Cleared',respPatchCall.callInfo.status, 'call status should be Cleared');
        System.assertEquals(logCount+1, logService.saveApplicationLogsCallCount, 'There should be one additional log from the test');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        logCount = logService.saveApplicationLogsCallCount;
        patchResponse = new RestApi_PatchCall.PatchCallResponse(400, 'Failure', 'Status Change', new VanillaException('Vanilla Exception'));
        respPatchCall = patchCallApi.LogAndConstructResponse(body, patchCallRequest, patchResponse, logService);
        System.assertEquals(400,respPatchCall.header.statusCode, 'Status code must be set to 400 for failure');
        System.assertEquals(logCount+1, logService.saveApplicationLogsCallCount, 'There should be one log to be saved');
        
        logCount = logService.saveApplicationLogsCallCount;
        patchResponse = new RestApi_PatchCall.PatchCallResponse(400, 'Failure', 'Status Change', new VanillaException('Vanilla Exception'));
        respPatchCall = patchCallApi.LogAndConstructResponse(body, null, patchResponse, logService);
        System.assertEquals(400,respPatchCall.header.statusCode, 'Status code must be set to 400 for failure');
        System.assertEquals(logCount+1, logService.saveApplicationLogsCallCount, 'There should be one log to be saved');
        
        System.test.stopTest();
        
    }
    
    @IsTest 
    public static void testRestApi_PatchCall_CommonUpdateLog_logFailure_Success()  {
        setupMocks();
        constructRestContext();
        System.test.startTest();
        
        try {
            RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
            RestResponse_PatchCall respPatchCall = null;
            
            RestApi_PatchCall.CommonUpdateLog cuLog = new RestApi_PatchCall.CommonUpdateLog();
            cuLog.setDefaultApplicationLogFields('operation', 'apiName');
            
            cuLog.logFailure(patchCallRequest, 'Failure', 'operation', 'originalRequest');
            cuLog.logFailure(null, 'Failure', 'operation', 'originalRequest');
            cuLog.logSuccess(patchCallRequest, 'Success', 'operation');
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');
        }
        System.test.stopTest();
    }
    
    
    /*******************EMI***************/
    
    
    
    /****************************************************************
// Factory Mock
****************************************************************/
    public class MockFactory implements ThirdPartyIntegration.IFactory {
        private MockThirdPartyIntegrationService mockService;  
        public   ThirdPartyIntegration.IThirdPartyIntegrationService createService() {
            mockService = new MockThirdPartyIntegrationService();
            return  mockService;
        }
        public MockThirdPartyIntegrationService getMockService() {
            return mockService;
        }
    }
    
    public class MockThirdPartyIntegrationService extends TestMockHelper implements ThirdPartyIntegration.IThirdPartyIntegrationService {
        
        public RestApi_PatchCall.PatchCallResponse  processThirdPartyRequestToUpdateCall(RestApi_PatchCall.PatchCallRequest patchCallRequest ) {
            return (RestApi_PatchCall.PatchCallResponse)incrementReturnOrThrow('processThirdPartyRequestToUpdateCall');
        }
        public void sendDispatchOfferPlatformEvent(WorkOrder wo) {
            incrementReturnOrThrow('sendDispatchOfferPlatformEvent');
        }
        /**EMI-START**/
          public void sendDispatchUpdatePlatformEvent(WorkOrder wo) {
            incrementReturnOrThrow('sendDispatchUpdatePlatformEvent');
        }
        
        /**EMI_END***/
        public void sendStatusChangePlatformEvents(List<WorkOrder> workorders) {
            incrementReturnOrThrow('sendStatusChangePlatformEvents');
        }
        public void publishPlatformEventsAndLogResults(List<ThirdPartyEvent__e> platformEvents) {
            incrementReturnOrThrow('publishPlatformEventsAndLogResults');
        }
        
        public void registerDispatcherForTechnologyType(String techType, ThirdPartyIntegration.IThirdPartyDispatcherService dispatcherService) {
            incrementReturnOrThrow('registerDispatcherForTechnologyType');
        }
        
        public void registerDispatcherForChannel(String channel, ThirdPartyIntegration.IThirdPartyDispatcherService dispatcherService) {
            incrementReturnOrThrow('registerDispatcherForChannel');
        }
        
        public ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String callKey){
            return (ThirdPartyEvent__e) incrementReturnOrThrow('constructCoreIntegrationPlatformEvent');
        }
        public String constructPlatformEventParametersArrayJSON(List<ThirdPartyIntegration.ThirdPartyPlatformEventParameter> params) {
            return (String) incrementReturnOrThrow('constructPlatformEventParametersArrayJSON');
        }
        public List<FSL_WorkOrder.WorkOrder>  retrieveWorkOrderDetails (WorkOrder wo) {
            return (List<FSL_WorkOrder.WorkOrder>) incrementReturnOrThrow('retrieveWorkOrderDetails');
        }
        public String getWorkOrderJSONUsingRetrieveWOMapping (List<FSL_WorkOrder.WorkOrder> domainWOs) {
            return (String) incrementReturnOrThrow('getWorkOrderJSONUsingRetrieveWOMapping');
        }
        public void logFailureMessage(String message, Exception ex, RestApi_PatchCall.PatchCallRequest patchCallRequest) {
            incrementReturnOrThrow('logFailureMessage');
        }
        public void logSuccessMessage(String message, RestApi_PatchCall.PatchCallRequest patchCallRequest) {
            incrementReturnOrThrow('logSuccessMessage');
        }
        public void logDiagnosticMessage(String message, string callKey) {
            incrementReturnOrThrow('logDiagnosticMessage');
        }
    }
    
    /*********************EMI*************/ 
    
    
    static ThirdPartyIntegration.IntegrationSupportServicesWrapper serviceWrapper = new ThirdPartyIntegration.IntegrationSupportServicesWrapper();
    @isTest
    public static void TestProcessThirdPartyRequestToUpdateCall() {
        TowbookIntegration.Factory TBIF = new TowbookIntegration.Factory();
        TowbookIntegration.TowbookService TBService = (TowbookIntegration.TowbookService)TBIF.createService();
        //RestApi_PatchCall.PatchCallResponse  response =TBService.processThirdPartyRequestToUpdateCall(GetPatchCall(), serviceWrapper);
        
    }
    
    
    private static RestApi_PatchCall.PatchCallResponse constructPatchCallResponse(Boolean error) {
        RestApi_PatchCall.PatchCallResponse patchCallResponse = (error) ? new RestApi_PatchCall.PatchCallResponse(400, 'Failure', 'operation', new VanillaException('Failure')) :
        new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'operation', null);
        return patchCallResponse;
    }
    
    public static RestApi_PatchCall.PatchCallRequest GetPatchCall() {
        RestApi_PatchCall.PatchCallRequest patchCallRequest = new RestApi_PatchCall.PatchCallRequest(); 
        patchCallRequest.requestHeader = new RestApi_PatchCall.RequestHeader();
        patchCallRequest.requestHeader.channel = new RestApi_PatchCall.Channel();
        patchCallRequest.requestHeader.channel.name = RestApi_PatchCall.Channel_Name.TOWBOOK;
        patchCallRequest.requestHeader.channel.parameters = new List<RestApi_PatchCall.KeyValuePair>();
        patchCallRequest.callInfo = new RestApi_PatchCall.ERSCallInfo();
        patchCallRequest.callInfo.callKey = '123-456-7890';
        //body = JSON.serialize(patchCallRequest); 
        return patchCallRequest;
    } 
    
    
    /*******EMI********************/
    
    public ThirdPartyEvent__e constructCoreIntegrationPlatformEvent(String technologyType, String eventType, String externalId) {
        ThirdPartyEvent__e event = new ThirdPartyEvent__e();
        event.Technology_Type__c = technologyType;
        event.EventType__c = eventType;
       // event.External_Id__c = externalId;
        event.CallKey__c = externalId;
        return event;
    }
    private class TestThirdPartyDispatcherService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
        public TestThirdPartyDispatcherService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            super(thirdPartyIntegrationService);
        }
    }
    
    private class TestThirdPartyIntegrationService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
        public TestThirdPartyIntegrationService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            super(thirdPartyIntegrationService);
        }
    }
    
    
    @isTest
    static void testConstructDispatchOfferPlatformEvent() {
        
        
        Integer recordCount = 5;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;
        
        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        List<WorkOrder> workOrders = new List<WorkOrder>();
        
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
            workOrders[i].Call_Id__c = '3333' + i;
            workOrders[i].Call_Date__c = '4444' + i;
            workOrders[i].Status = 'Spotted';
            //workOrders[i].WO_Member_Phone_Number__c = '';
            workOrders[i].Servicing_Technology_Type__c = 'TOWBOOK';
            workOrders[i].Vehicle_Profile__c = 'My Vehicle # ' + i;
        }
        insert workOrders;
        
        
        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();
        
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;
        
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for( Integer i = 0; i < recordCount; ++i ) {
            ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
            breakdownSa.ParentRecordId = workOrders[i].Id;
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
            serviceAppointments.add( breakdownSa );
            ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
            towSa.ParentRecordId = workOrders[i].Id;
            //ERS-230874 Glympse Removal - Part I
            //breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 2;
            serviceAppointments.add( towSa );
        }
        insert serviceAppointments;
        system.debug('workOrders1:'+workOrders);
        workOrder getWorkOrder = [ SELECT Id,External_Id__c,Call_Id__c,Call_Date__c,Status,Servicing_Technology_Type__c,Vehicle_Profile__c,
                                  (SELECT Id, isBreakdown__c, Subject, ServiceTerritory.Facility_Number__c from  ServiceAppointments)
                                  FROM WorkOrder where id =: workOrders[0].id ];
        
        
        
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        //TestThirdPartyIntegrationService thirdPartyService = new TestThirdPartyIntegrationService(mockService);
        
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        try{  
            system.debug('mockFactory'+mockFactory);
              TowbookIntegration.Factory TBIF = new TowbookIntegration.Factory();
        TowbookIntegration.TowbookService TBService = (TowbookIntegration.TowbookService)TBIF.createService();
       
        system.debug('thirdPartyService');
            ThirdPartyEvent__e thdevt = TBService.constructDispatchOfferPlatformEvent(workOrders[0]);
        }catch(Exception e){system.debug('exception::::'+e);}
        
        try{    
            ThirdPartyEvent__e thdexpevt = newDispatcher.constructDispatchedCallExpiredPlatformEvent(getWorkOrder);
        }catch(Exception e){}
        try{    
            ThirdPartyEvent__e thdcanevt =newDispatcher.constructDispatchedCallCancelledPlatformEvent(getWorkOrder);
        }catch(Exception e){}
        try{    
            ThirdPartyEvent__e thdclearevt =newDispatcher.constructCallClearedPlatformEvent(getWorkOrder);
        }catch(Exception e){}
        try{    
            ThirdPartyEvent__e thddisevt =newDispatcher.constructDispatchAcceptedPlatformEvent(workOrders[0]); 
        }catch(Exception e){}
        /**EMI-START**/
		try{    
            ThirdPartyEvent__e thdevt = newDispatcher.constructDispatchUpdatePlatformEvent(workOrders[0]);
        }catch(Exception e){}
		/**EMI_END***/
    }
    
    /* @IsTest
    public static void testWorkOrderService_GetWorkOrdersByCallIdAndCallDate_MultipleCallIdAndCallDatePairs_DomainWorkOrdersCreatednew() {
        FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        WorkOrder workOrder1 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder2 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder3 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 1', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder4 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder5 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder6 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 2', Call_Date__c = 'Call Date 3' );
        WorkOrder workOrder7 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 1' );
        WorkOrder workOrder8 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 2' );
        WorkOrder workOrder9 = new WorkOrder( Id = dao.Builder.getMockId(), Call_Id__c = 'Call Id 3', Call_Date__c = 'Call Date 3' );
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        dao.workOrders.put( workOrder3.Id, workOrder3 );
        dao.workOrders.put( workOrder4.Id, workOrder4 );
        dao.workOrders.put( workOrder5.Id, workOrder5 );
        dao.workOrders.put( workOrder6.Id, workOrder6 );
        dao.workOrders.put( workOrder7.Id, workOrder7 );
        dao.workOrders.put( workOrder8.Id, workOrder8 );
        dao.workOrders.put( workOrder9.Id, workOrder9 );
        Set<String> callIds = new Set<String>{ 'Call Id 1', 'Call Id 3' };
        Set<String> callDates = new Set<String>{ 'Call Date 1', 'Call Date 3' };
        List<FSL_WorkOrder.CallIdAndCallDatePair> criteria = new List<FSL_WorkOrder.CallIdAndCallDatePair>{ new FSL_WorkOrder.CallIdAndCallDatePair(), new FSL_WorkOrder.CallIdAndCallDatePair() };
        criteria[0].callId = 'Call Id 1';
        criteria[0].callDate = 'Call Date 1';
        criteria[1].callId = 'Call Id 3';
        criteria[1].callDate = 'Call Date 3';
     Test.startTest();
         FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();

        List<FSL_WorkOrder.WorkOrder> domainWorkOrders = service.getWorkOrdersByCallIdAndCallDate( criteria, assignedResourceService, feedItemService );
      
        system.debug('domainWorkOrders'+domainWorkOrders);
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        
        
       
       
       
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        workOrder getWorkOrder = [ SELECT Id,External_Id__c,Call_Id__c,Call_Date__c,Status,Servicing_Technology_Type__c,Vehicle_Profile__c,
                                  (SELECT Id, isBreakdown__c, Subject, ServiceTerritory.Facility_Number__c from  ServiceAppointments)
                                  FROM WorkOrder where id =: workOrder1.id ];
        
        try{    
            ThirdPartyEvent__e thdcanevt =newDispatcher.constructDispatchedCallCancelledPlatformEvent(getWorkOrder);
        }catch(Exception e){}
        
        
        
        Test.stopTest();

    }*/
   
    
    public Integer getWorkOrdersByCallIdAndCallDateCallCount = 0;
        public List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDateReturnValue = new List<FSL_WorkOrder.WorkOrder>();
        public List<FSL_WorkOrder.WorkOrder> getWorkOrdersByCallIdAndCallDate( List<FSL_WorkOrder.CallIdAndCallDatePair> criteria, 
                                                                              FSL_AssignedResource.IAssignedResourceService assignedResourceService, 
                                                                              FSL_FeedItem.IFeedItemService feedItemService ) {
            getWorkOrdersByCallIdAndCallDateCallCount++;
           // throwExceptionIfConfigured();
            return getWorkOrdersByCallIdAndCallDateReturnValue;
        }

        public Integer getActiveWorkOrdersByContactIdCallCount = 0;
        public List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactIdReturnValue = new List<FSL_WorkOrder.WorkOrder>();
        public List<FSL_WorkOrder.WorkOrder> getActiveWorkOrdersByContactId( Set<Id> contactIds, 
                                                                            FSL_AssignedResource.IAssignedResourceService assignedResourceService, 
                                                                            FSL_FeedItem.IFeedItemService feedItemService ) {
            getActiveWorkOrdersByContactIdCallCount++;
          //  throwExceptionIfConfigured();
            return getActiveWorkOrdersByContactIdReturnValue;
        }
    @isTest
    static void testConstructDispatchOfferPlatformEvent1() {
        FSL_WorkOrderTest.WorkOrderDAOMock dao = new FSL_WorkOrderTest.WorkOrderDAOMock();
        FSL_WorkOrder.IWorkOrderService service = new FSL_WorkOrder.WorkOrderService( dao );
        //Id contactId1 = dao.Builder.getMockId( Contact.getSObjectType() );
        //Id contactId2 = dao.Builder.getMockId( Contact.getSObjectType() );
        
        List<Account> accounts = FSL_DataFactory.createAccounts( 2 );
        insert accounts;
        
        List<Contact> contacts = FSL_DataFactory.createContacts( 2 );
        for( Integer i = 0; i < 2; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;
        Id contactId1 = contacts[0].id;
        Id contactId2 = contacts[1].id;
        WorkOrder workOrder1 = new WorkOrder(  ContactId = contactId1, Status = 'Spotted', 
                                             External_Id__c = 'ERS-1',Call_Id__c = '33331', Call_Date__c = '44441',Servicing_Technology_Type__c = 'TOWBOOK',
                                             Vehicle_Profile__c = 'My Vehicle # 1' );
        WorkOrder workOrder2 = new WorkOrder( ContactId = contactId2, Status = 'Spotted', 
                                             External_Id__c = 'ERS-2',Call_Id__c = '33332', Call_Date__c = '44442',Servicing_Technology_Type__c = 'TOWBOOK',
                                             Vehicle_Profile__c = 'My Vehicle # 12' );
        
        insert workOrder1;
        insert workOrder2;
        dao.workOrders.put( workOrder1.Id, workOrder1 );
        dao.workOrders.put( workOrder2.Id, workOrder2 );
        Set<Id> contactIds = new Set<Id>{ contactId1, contactId2 };
            
            List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();
        
        ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
        List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
            insert sts;
        
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        
        ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrder1.Id, contactId1, System.now(), 1800, 'Subject1' );
        breakdownSa.ParentRecordId = workOrder1.Id;
        serviceAppointments.add( breakdownSa );
        ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrder2.Id, contactId2, System.now() + 1800, 1800, 'Subject2' );
        towSa.ParentRecordId = workOrder2.Id;
        serviceAppointments.add( towSa );
        
        insert serviceAppointments;
        system.debug('serviceAppointments'+serviceAppointments);
        
        
       
        
        FSL_FeedItemTest.FeedItemServiceMock feedItemService = new FSL_FeedItemTest.FeedItemServiceMock();
        FSL_AssignedResourceTest.AssignedResourceServiceMock assignedResourceService = new FSL_AssignedResourceTest.AssignedResourceServiceMock();
        
        
        
        
        List<FSL_WorkOrder.WorkOrder> domainWorkOrders = service.getActiveWorkOrdersByContactId( contactIds, assignedResourceService, feedItemService );
        system.debug('domainWorkOrders'+domainWorkOrders);
        
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        
        TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
        
        workOrder getWorkOrder = [ SELECT Id,External_Id__c,Call_Id__c,Call_Date__c,Status,Servicing_Technology_Type__c,Vehicle_Profile__c,
                                  (SELECT Id, isBreakdown__c, Subject, ServiceTerritory.Facility_Number__c from  ServiceAppointments)
                                  FROM WorkOrder where id =: workOrder1.id ];
        
      
        try{    
            ThirdPartyEvent__e thdcanevt =newDispatcher.constructDispatchedCallCancelledPlatformEvent(getWorkOrder);
        }catch(Exception e){}
    }
    
    /*  Test.startTest();
        createDaoData(ThirdPartyIntegration.THIRD_PARTY_DISPATCHER_SERVICING_TECHNOLOGY_TYPE_TOWBOOK);

		 ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);      
       // ThirdPartyIntegration.IntegrationSupportServicesWrapper mockIntegrationWrapper = constructMockIntegrationWrapper();
        List<WorkOrder> workOrders = [SELECT Id, External_Id__c, (SELECT Id, isBreakdown__c, Subject FROM ServiceAppointments) FROM WorkOrder];
       // RestApi_PatchCall.PatchCallRequest patchCallRequest = constructPatchCallRequest(workOrders.get(0)?.External_Id__c);
        patchCallRequest.callInfo.status = 'Spotted';

        FSL_ApplicationLogTest.ApplicationLogServiceMock mockLogService =  new FSL_ApplicationLogTest.ApplicationLogServiceMock();
        FSL_WorkOrder.IWorkOrderService workOrderService = new FSL_WorkOrder.Factory().createService();
        List<WorkOrder> listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, towmockIntegrationWrapper);

        patchCallRequest.callInfo.status = 'Scheduled';
        listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, towmockIntegrationWrapper);
        
        patchCallRequest.callInfo.status = 'Dispatched';
        listWO = workOrderService.processThirdPartyWorkOrderUpdateRequest(patchCallRequest, towmockIntegrationWrapper);

        Test.stopTest();*/
    
    

    
    /*
@isTest
static void testconstructDispatchRefusedPlatformEvent() {

WorkOrder wo = new WorkOrder();
wo.Servicing_Technology_Type__c = 'SomeTechnology';
wo.External_Id__c = '123-456-7890';
insert wo;
ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
ThirdPartyEvent__e event = dispatcherService.constructDispatchRefusedPlatformEvent(wo);
}
*/
    
    
    /*
@isTest
static void testconstructDispatchedCallCancelledPlatformEvent() {

//WorkOrder wo = new WorkOrder();
//wo.Servicing_Technology_Type__c = 'SomeTechnology';
//wo.External_Id__c = '123-456-7890';
//insert wo;
//ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
//TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
//ThirdPartyEvent__e event = dispatcherService.constructDispatchedCallCancelledPlatformEvent(wo);

//createDaoData('test');
/* 
Integer recordCount = 5;
List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
insert accounts;

List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
for( Integer i = 0; i < recordCount; ++i ) {
contacts[i].AccountId = accounts[i].Id;
}
insert contacts;
List<WorkOrder> workOrders = new List<WorkOrder>();

for( Integer i = 0; i < recordCount; ++i ) {
workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
workOrders[i].External_Id__c = 'ERS-' + i;
workOrders[i].Call_Id__c = '3333' + i;
workOrders[i].Call_Date__c = '4444' + i;
workOrders[i].Status = 'Spotted';
//workOrders[i].WO_Member_Phone_Number__c = '';
workOrders[i].Servicing_Technology_Type__c = 'TOWBOOK';
workOrders[i].Vehicle_Profile__c = 'My Vehicle # ' + i;
}
insert workOrders;


List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true, Facility_Number__c='123' );
List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
insert sts;

List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
for( Integer i = 0; i < recordCount; ++i ) {
ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
breakdownSa.ParentRecordId = workOrders[i].Id;
//ERS-230874 Glympse Removal - Part I
//breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
serviceAppointments.add( breakdownSa );
ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
towSa.ParentRecordId = workOrders[i].Id;
//ERS-230874 Glympse Removal - Part I
//breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 2;
serviceAppointments.add( towSa );
}
insert serviceAppointments;
system.debug('workOrders1:'+workOrders);
workOrder getWorkOrder = [ SELECT Id,External_Id__c,Call_Id__c,Call_Date__c,Status,Servicing_Technology_Type__c,Vehicle_Profile__c,
(SELECT Id, isBreakdown__c, Subject, ServiceTerritory.Facility_Number__c from  ServiceAppointments)
FROM WorkOrder where id =: workOrders[0].id ];

ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
ThirdPartyEvent__e thdcanevt =newDispatcher.constructDispatchedCallCancelledPlatformEvent(workOrders[0]);
}
*/
    
    /***************************/
    /*
static List<WorkOrder> workOrders = new List<WorkOrder>();
private static void createDaoData(String srvcTechType) {
Integer recordCount = 5;
List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
insert accounts;

List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
for( Integer i = 0; i < recordCount; ++i ) {
contacts[i].AccountId = accounts[i].Id;
}
insert contacts;


for( Integer i = 0; i < recordCount; ++i ) {
workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
workOrders[i].External_Id__c = 'ERS-' + i;
workOrders[i].Call_Id__c = '3333' + i;
workOrders[i].Call_Date__c = '4444' + i;
workOrders[i].Status = 'Spotted';
//workOrders[i].WO_Member_Phone_Number__c = '';
workOrders[i].Servicing_Technology_Type__c = srvcTechType;
workOrders[i].Vehicle_Profile__c = 'My Vehicle # ' + i;
}
insert workOrders;

List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

ServiceTerritory st1 = new ServiceTerritory( Name = 'Service Territory 1', OperatingHoursId = hours[0].Id, IsActive = true );
ServiceTerritory st2 = new ServiceTerritory( Name = 'Service Territory 2', OperatingHoursId = hours[0].Id, IsActive = true );
List<ServiceTerritory> sts = new List<ServiceTerritory> { st1, st2 };
insert sts;

List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
for( Integer i = 0; i < recordCount; ++i ) {
ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st1.Id, workOrders[i].Id, contacts[i].Id, System.now(), 1800, 'Subject' + i );
breakdownSa.ParentRecordId = workOrders[i].Id;
//ERS-230874 Glympse Removal - Part I
//breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 1;
serviceAppointments.add( breakdownSa );
ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( 'Tow', st1.Id, workOrders[i].Id, contacts[i].Id, System.now() + 1800, 1800, 'Subject' + i );
towSa.ParentRecordId = workOrders[i].Id;
//ERS-230874 Glympse Removal - Part I
//breakdownSa.Glympse_EnRoute__Glympse_EnRoute_Task_ID__c = ( i * 2 ) + 2;
serviceAppointments.add( towSa );
}
insert serviceAppointments;
}

*/
    /****************************/
    /*
@isTest
static void testconstructDispatchedCallExpiredPlatformEvent() {
createDaoData('test');

ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);

try{    
ThirdPartyEvent__e thdexpevt = newDispatcher.constructDispatchedCallExpiredPlatformEvent(workOrders[0]);
}catch(Exception e){}

}


*/      
    
    
    @isTest
    static void testconstructGoneOnArrivalApprovalPlatformEvent() {
        
        WorkOrder wo = new WorkOrder();
        wo.Servicing_Technology_Type__c = 'SomeTechnology';
        wo.External_Id__c = '123-456-7890';
        
        insert wo;
        ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
        TestThirdPartyDispatcherService dispatcherService = new TestThirdPartyDispatcherService(mockService);
        ThirdPartyEvent__e event = dispatcherService.constructGoneOnArrivalApprovalPlatformEvent(wo);
    }
            
    private class MockThirdPartyDispatcherService extends ThirdPartyIntegration.ThirdPartyDispatcherServiceBase {
        public MockThirdPartyDispatcherService(ThirdPartyIntegration.IThirdPartyIntegrationService thirdPartyIntegrationService) {
            super(thirdPartyIntegrationService);
        }
        
        
        public override RestApi_PatchCall.PatchCallResponse processThirdPartyRequestToUpdateCall(
            RestApi_PatchCall.PatchCallRequest patchCallRequest, 
            ThirdPartyIntegration.IntegrationSupportServicesWrapper wrapper) {
                Exception exp = null;
                return new RestApi_PatchCall.PatchCallResponse(200, 'Update Call from Third Party Succeeded', 'statusUpdate', exp);
            }
    }
    
    
    @isTest
    static void testSetDefaultApplicationLogFields() {
        
        ThirdPartyIntegration.ThirdPartyIntegrationLog integrationLog = new ThirdPartyIntegration.ThirdPartyIntegrationLog();
        String expectedOperation = 'Test Operation';
        String expectedApiName = 'Test API Name';
        Test.startTest();
        integrationLog.setDefaultApplicationLogFields(expectedOperation, expectedApiName);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testThirdPartyPlatformEventParameter() {
        
        String expectedKey = 'TestKey';
        String expectedValue = 'TestValue';
        ThirdPartyIntegration.ThirdPartyPlatformEventParameter param = new ThirdPartyIntegration.ThirdPartyPlatformEventParameter(expectedKey, expectedValue);
        System.assertEquals(expectedKey, param.key);
        System.assertEquals(expectedValue, param.value);
    }
    
    @isTest
    static void testLogInformationMessage() {
        
        String message = 'Test Message';
        String callKey = 'Test Call Key';
        ThirdPartyIntegration.ThirdPartyIntegrationLog integrationLog = new ThirdPartyIntegration.ThirdPartyIntegrationLog();
        integrationLog.logInformationMessage(message, callKey);
    }
    
    
    /****************EMI_END************/
    
    @isTest
    static void sendRefusedPlatformEventTM() {
        tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
        
        
        
        setupMocks();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        constructRestContext();
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.accept;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        try {
            
            
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            
            System.test.startTest();
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
        System.test.stopTest();
        
    }
    
     @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedbreadcrumb() {
        
        setupMocks();
        string inputStr = 'breadcrumb';
        constructRestContextDynamic(inputStr);
        tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.breadcrumb;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
               
        System.test.stopTest();
        
    }
    
     @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedcancel() {
        
        setupMocks();
        string inputStr = 'cancel';
        constructRestContextDynamic(inputStr);
        tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.cancel;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
        
               
        System.test.stopTest();
        
    }
    
      @IsTest
    public static void testRestApi_PatchCall_processPatchCallRequest_HappyPath_SuccessResponseReturnedphoto() {
        
        setupMocks();
        string inputStr = 'photo';
        constructRestContextDynamic(inputStr);
        tbkInRequest = new TowbookIntegration.TowbookInboundRequest();
          tbkInRequest.id = patchCallRequest.requestHeader.id;
        
        tbkInRequest.type = TowbookIntegration.TBK_REQUEST_TYPE.photo;
        
        
        
        
        tbkInRequest.dispatchId = patchCallRequest.callInfo.callKey;
        tbkInRequest.contractorId = patchCallRequest.requestHeader.sourceOrg.code;
        tbkInRequest.locationId = patchCallRequest.requestHeader.channel.parameters[1].value;
        tbkInRequest.url = patchCallRequest.requestHeader.channel.parameters[2].value;
        
        //
        // Set the ETA on the patchRequest Object iteself
        patchCallRequest.serviceStatus = new RestApi_PatchCall.ServiceStatus();
        patchCallRequest.serviceStatus.estimatedTimeOfArrival = patchCallRequest.requestHeader.channel.parameters[3].value;
        
        tbkInRequest.timestamp = patchCallRequest.requestHeader.dateTimeString;
        
        
        if ( patchCallRequest.roadsideAssistanceDetail == null ) {
            patchCallRequest.roadsideAssistanceDetail = new List<RestApi_PatchCall.RoadsideAssistanceDetail>();
            patchCallRequest.roadsideAssistanceDetail[0] = new RestApi_PatchCall.RoadsideAssistanceDetail();
        }
        
        if (patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems == null ) {
            patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems = new List<RestApi_PatchCall.ServiceLineItem>();
        }
        
        
        if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.refuse) {
            patchCallRequest.CallInfo.status = 'Spotted';
        }
        else if ( tbkInRequest.type == TowbookIntegration.TBK_REQUEST_TYPE.complete) {
            patchCallRequest.CallInfo.status = 'Cleared';
        }
        tbkInRequest.status = patchCallRequest.callInfo.status;
        
        
        
        
        tbkInRequest.reasonId = Integer.valueOf(patchCallRequest.roadsideAssistanceDetail[0].reasonCode);
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        
        tbkInRequest.eta = Integer.valueOf(1);
        
        
        tbkInRequest.comments = patchCallRequest.roadsideAssistanceDetail[0].comments[0].text;
        tbkInRequest.driver = new TowbookIntegration.TowbookDriver();
        tbkInRequest.driver.firstName = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeName;
        tbkInRequest.driver.id = patchCallRequest.roadsideAssistanceDetail[0].driverData.servicingStationEmployeeId;
        tbkInRequest.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        tbkInRequest.driver.latitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.latitude;
        tbkInRequest.driver.longitude = patchCallRequest.roadsideAssistanceDetail[0].driverData.longitude;
        
        tbkInRequest.resolutionCode = patchCallRequest.roadsideAssistanceDetail[0].resolutionCode;
        tbkInRequest.serviceLineItems = patchCallRequest.roadsideAssistanceDetail[0].ServiceLineItems;
        
        
        System.test.startTest();
        RestApi_PatchCall.PatchCallResponse  mockResponse = new RestApi_PatchCall.PatchCallResponse(200, 'Success', 'Status Change', null);
        mockThirdparty.setReturnValue('processThirdPartyRequestToUpdateCall',  mockResponse);
        RestApi_PatchCall patchCallApi = new RestApi_PatchCall();
        RestResponse_PatchCall respPatchCall = patchCallApi.processPatchCallRequest(RestContext.request, RestContext.response, thirdPartyService, logService);
        
        System.assertEquals(1, mockThirdparty.getCallCount('processThirdPartyRequestToUpdateCall'), 'Should be exactly one call into processThirdPartyRequestToUpdateCall');
        System.assertEquals(200,respPatchCall.header.statusCode, 'Success Code must be set as 200');
        
        try {
            RestApi_PatchCall.PatchCallRequest patchCall = new RestApi_PatchCall.PatchCallRequest();
            respPatchCall = RestApi_PatchCall.patchCall();
            ThirdPartyIntegration.IThirdPartyIntegrationService mockService = new MockThirdPartyIntegrationService();
            TowbookIntegration.TowbookService newDispatcher = new TowbookIntegration.TowbookService(mockService);
            try{   
                newDispatcher.sendRefusedPlatformEvent(tbkInRequest,patchCallRequest,'comments');
            }      catch (Exception ex) {}
        }
        catch (Exception ex) {
            System.assert(false, 'should not reach here because no exception should be thrown');   
        }
         System.test.stopTest();
        
    }
  
      /******EMI Start for SSFI-77 dated 01-14-2025***************/
   
    

     /******EMI End for SSFI-77 dated 01-14-2025***************/   
}