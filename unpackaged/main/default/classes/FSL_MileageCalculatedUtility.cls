/**
 * @File Name          : FSL_MileageCalculatedUtility.cls
 * @Description        : 
 * @Author             : Dylan Truong
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 09/20/2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    09/20/2021   Dylan Truong          ERS-223670 :Updates to Mileage and ER Calculation
*  1.0    10/25/2021   Dylan Truong          ERS-226141 :Reimplement Calculate Mileage by Using Bing Webservice instead built in DISTANCE Function
**/

global class FSL_MileageCalculatedUtility {

    @InvocableMethod
    public static void calculateMileageFromFlow(List<CalculateMileage> theSource) {
        if(!System.isFuture() && !System.isBatch()) { //AGB SSFI 179/180 7/31/24
        	updateOrCreateServiceLineItem(theSource[0].originLatitude, theSource[0].originLongitude, 
                                        theSource[0].destinationLatitude, theSource[0].destinationLongitude, 
                                        theSource[0].workOrderId, theSource[0].productCode);
        }
    }

    @future (callout = true)
    public static void updateOrCreateServiceLineItem( String originLatitude, String originLongitude, String destinationLatitude, String destinationLongitude, Id workOrderId, String productCode) {
        
        CalculateMileage  calMileage = createCalculateMileage(originLatitude, originLongitude, destinationLatitude, destinationLongitude, workOrderId, productCode);
        CalculateMileageService calService = new CalculateMileageService(calMileage);
        calService.calculateDistance();
    } 

    private static CalculateMileage createCalculateMileage(String originLatitude, String originLongitude, String destinationLatitude, String destinationLongitude, Id workOrderId, String productCode) {
        CalculateMileage calMileage = new CalculateMileage();
        calMileage.originLatitude = originLatitude;
        calMileage.originLongitude = originLongitude;
        calMileage.destinationLatitude = destinationLatitude;
        calMileage.destinationLongitude = destinationLongitude;
        calMileage.workOrderId = workOrderId;
        calMileage.productCode = productCode;
        return calMileage;
    }

    public class CalculateMileage {
        @InvocableVariable (required=true)
        public String originLatitude ;
        
        @InvocableVariable (required=true)
        public String originLongitude ;
        
        @InvocableVariable (required=true)
        public String destinationLatitude;

        @InvocableVariable (required=true)
        public String destinationLongitude;

        @InvocableVariable (required = true)
        public Id workOrderId; 
        
        @InvocableVariable (required = true)
        public String productCode; 
    }

    public class CalculateMileageService {

        private CalculateMileage calMileage; 
     
        @testVisible private FSL_Mapping.IMap distanceService;

        public CalculateMileageService (CalculateMileage calMileage) {
            this.calMileage = calMileage;
            if ( distanceService == null ) {
                FSL_ApplicationLog.IApplicationLogService appLogService = new FSL_ApplicationLog.Factory().createService();
                distanceService  = (new FSL_Mapping.Factory().createMap(appLogService));
            }
        }

        public void calculateDistance() {
            try {
                //createApplicationLogException('This is product code ' + calMileage.productCode);
                Decimal distance = calculateDistanceInMile();
                Map<String,Object> inputParams = new Map<String,Object>();
                inputParams.put('WorkOrderId', calMileage.workOrderId);
                inputParams.put('Quantity', distance);
                inputParams.put('ProductCode', calMileage.productCode);
                Flow.Interview.Update_Or_Insert_Service_Line_Item sliFlow = new Flow.Interview.Update_Or_Insert_Service_Line_Item(inputParams);
                sliFlow.start();
            } catch (Exception e) {
                createApplicationLogException( e.getStackTraceString() + e.getMessage());
            }
        }

        @testVisible
        private Decimal calculateDistanceInMile() {
            Decimal mileage = 0;
            if (String.isNotBlank(calMileage.originLatitude) && String.isNotBlank(calMileage.originLongitude) && String.isNotBlank(calMileage.destinationLatitude) 
                && String.isNotBlank(calMileage.destinationLongitude)) {
                    mileage = distanceService.calculateDistanceInMiles(double.valueOf(calMileage.originLatitude),double.valueOf(calMileage.originLongitude), 
                                                                    double.valueOf(calMileage.destinationLatitude), double.valueOf(calMileage.destinationLongitude));
            }
            
            return mileage;
        }

        private void createApplicationLogException(String message) {
            CalculatedMileageApplicationLog appLog = new CalculatedMileageApplicationLog();
            appLog.createAppLog(message);
            saveApplicationLogsWithPlatformEvent(new ApplicationLogPlatformEventService(), appLog);
        }

        private void saveApplicationLogsWithPlatformEvent(ApplicationLogPlatformEventService eventService, CalculatedMileageApplicationLog appLog ) {
            List<Application_Log_Event__e> eventMessages = new List<Application_Log_Event__e>();
            Application_Log_Event__e eventMessage = createApplicationLogEventMessage(appLog);
            eventMessages.add(eventMessage);
            eventService.publishEvents(eventMessages);
        }

        private Application_Log_Event__e createApplicationLogEventMessage(CalculatedMileageApplicationLog appLog) {
            FSL_Application_Log__c log = appLog.getApplicationLog();
            Application_Log_Event__e appLogEvent = new Application_Log_Event__e();
            appLogEvent.Operation__c = log.Operation__c;
            appLogEvent.Error_Caught__c = log.Error_Caught__c;
            appLogEvent.Message__c = log.Error_Message__c;
            appLogEvent.RecordTypeId__c = log.RecordTypeId;
            appLogEvent.Total_Record_Count__c = log.Total_Record_Count__c;
            return appLogEvent;
        }
    }

    private class CalculatedMileageApplicationLog extends FSL_ApplicationLog.ApplicationLog {

        public CalculatedMileageApplicationLog () {
            super();
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.Operation__c = 'CalculatedMileage';
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        public void createAppLog(String message) {
            appLog.Error_Message__c = message;
            appLog.Error_Caught__c = true;
        }

    }

    private abstract class EventSubscriber {
        protected virtual void publishEvents(List<sObject> eventMessages) {
               EventBus.publish(eventMessages); 
        }
    }

    private class ApplicationLogPlatformEventService extends EventSubscriber {
        public ApplicationLogPlatformEventService() {
            super();
        }
    }
}