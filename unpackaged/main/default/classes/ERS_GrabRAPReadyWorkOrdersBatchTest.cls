@isTest
public class ERS_GrabRAPReadyWorkOrdersBatchTest {
    public static Organization orgData = [SELECT Id, Name FROM Organization LIMIT 1];
    public static Boolean isNEOrg = orgData.Name == 'AAA Northeast';

    private class MockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String reqEndpoint = req.getEndpoint();
            String bodyJSONStr = '';
            String clubCode = BackOffice_Settings__c.getOrgDefaults().Club_Code__c;
            String callIdKey = '';
            Integer statusCode = 500;

            if (
                reqEndpoint.contains(
                    'https://api-qa.national.aaa.com/automotive/services/sf/v1/requests/close/'
                )
            ) {
                List<String> epList = reqEndpoint.split('/');

                callIdKey = epList[epList.size() - 1];
            }

            res.setHeader('Content-Type', 'application/json');

            if (reqEndpoint == 'testurl') {
                bodyJSONStr = '{"access_token":"test1234"}';
            } else if (
                reqEndpoint.contains(
                    'https://api-qa.national.aaa.com/automotive/services/sf/v1/requests/close/' + callIdKey
                )
            ) {
                if (clubCode == 'TST') {
                    statusCode = ACG_ConstantsClass.STATUS_CODE_SUCCESS;
                } else {
                    statusCode = 500;
                }

                bodyJSONStr = '{}';
            }

            res.setBody(bodyJSONStr);
            res.setStatusCode(statusCode);

            return res;
        }
    }

    public static void setup(Map<String, Object> params) {
        insert new BackOffice_Settings__c(
            Club_Code__c = (String) params.get('clubCode')
        );

        insert new Integration_Settings__c(
            Name = 'NationalRBP_API',
            Method__c = 'POST',
            Enpoint_URL__c = 'https://api-qa.national.aaa.com/automotive/services/sf/v1/requests/close',     
            Header_Value__c = '[{"key":"Content-Type","value":"application/json"}]'

        );
        
        ACG_TestDataFactory.createIntegrationSetting(
            'NatioanlRBP_API', 
            'POST', 
            'callout:NatioanlRBP_API', 
            '/callClear', 
            'http://acg-ers-ulra-rbpcallclear-api-dev.us-e1.cloudhub.io/callClear', 
            true
        );

        Account testAcct = new Account(
            Club_Code__c = '123',
            Name = 'Test Account'
        );
        insert testAcct;
        
        Case testCase = new Case();
        insert testCase;
        
        insert new List<WorkOrder>{
            new WorkOrder(
                Audit_Flag__c = true,
                RAP_Verified__c = false,
                CaseId = testCase.Id,
                Member_Account__c = testAcct.Id,
                RAP_Case_Number__c = '123454',
                Call_Type__c = 'RAP',
                RAP_Status__c = 'RAP Cleared',
                External_ID__c = '240-20240612-02546258'
            ),
            new WorkOrder(
                Audit_Flag__c = true,
                RAP_Verified__c = true,
                CaseId = testCase.Id,
                Member_Account__c = testAcct.Id,
                RAP_Case_Number__c = '123454',
                Call_Type__c = 'RAP'
            ),
            new WorkOrder(
                Audit_Flag__c = true,
                Call_Type__c = 'NOT RAP'
            )
        };
    }
    
    @isTest
    public static void badRespTest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());

        setup(
            new Map<String, Object>{
                'clubCode' => isNEOrg ? '240' : '212'
            }
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new ERS_GrabRAPReadyWorkOrdersBatch());
        Test.stopTest();
        
        List<AsyncApexJob> jobResults = [
            SELECT 
                Id, 
                JobType, 
                ApexClassId, 
                Status, 
                JobItemsProcessed, 
                TotalJobItems 
            FROM AsyncApexJob 
            WHERE JobType = 'BatchApex'
        ];

        System.assertEquals(1, jobResults[0].JobItemsProcessed, 'Failed to process batch.');
        System.assertNotEquals(null, jobId, 'Failed to process batch.');
    }

    @isTest
    public static void goodRespTest() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());

        setup(
            new Map<String, Object>{
                'clubCode' => 'TST'
            }
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new ERS_GrabRAPReadyWorkOrdersBatch());
        Test.stopTest();

        List<WorkOrder> woList = [
            SELECT Id, Call_Type__c, RAP_Verified__c
            FROM WorkOrder
            WHERE Call_Type__c = 'RAP'
        ];

        Boolean allRAPVerified = true;

        for (WorkOrder wo : woList) {
            if (!wo.RAP_Verified__c) {
                allRAPVerified = false;
                break;
            }
        }

        System.assertEquals(true, allRAPVerified, 'Failed to verify RAP calls.');
    }

    private static void checkAppLogs() {
        List<FSL_Application_Log__c> appLogList = [
            SELECT Id, Operation__c, CreatedDate, Error_Message__c 
            FROM FSL_Application_Log__c 
            WHERE Operation__c NOT IN (
                null, 'WOStatusUpdateLog', 'getAddressFromSADA', 'ValidateMembership', 'Update', 'Scheduling', 'WOSClearLog', 'updateSyncStatus', 'Clear', 'CallCreate', 'INTDistanceMatrix', 'WOCreateEventLog', 'ETALog', 'Delayed Copy to Clear Queue', 'Inbound Update/Cancel', 'CalculatedMileage', 'Status Change', 'Complete', 'statusUpdate:On Location', 'ThirdPartyIntegration', 'statusUpdate:En Route', 'statusUpdate:Dispatched', 'accept', 'accepted', 'dispatch', 'cancelled', 'CallCommentMerge', 'CaseCreation', 'getAutosuggestResponse', 'ERSAuthorize', 'IntakeWorkOrderAPI', 'National Repair Shop', 'SADAGeoJSON', 'statusUpdate:Tow Complete', 'statusUpdate:In Tow', 'National Call Mover', 'getTimezoneFromMemberLocation', 'getLatLongFromGoogle', 'INTERSFeedbackInbound', 'ERS Feedback Inbound', 'cleared', 'RetrieveWorkOrders', 'Clear Queue'
            ) 
            ORDER BY CreatedDate DESC LIMIT 50
        ];

        System.debug('checkAppLogs:');
        System.debug(JSON.serializePretty(appLogList));
    }
}