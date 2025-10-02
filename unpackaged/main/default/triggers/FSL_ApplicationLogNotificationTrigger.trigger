/**
 *  @Descrption     -   This class will serve as the helper for creating appointment
 *                      dependencies for tow work types
 *
 *  *       07/21/2021   Dylan Truong         ERS-224516 - Finetune upsertResourceAbsense Platform Event Log: adding total record count
 */

trigger FSL_ApplicationLogNotificationTrigger on Application_Log_Event__e (after insert) {

    private class ApplicationLog extends FSL_ApplicationLog.ApplicationLog {

        private Application_Log_Event__e logEvent;

        ApplicationLog(Application_Log_Event__e logEvent) {
            super();
            this.logEvent = logEvent;
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
        }

        void build() {
            appLog.API_Name__c = logEvent.API_Name__c;
            appLog.Operation__c = logEvent.Operation__c;

            appLog.Error_Caught__c = logEvent.Error_Caught__c;
            if(logEvent.Error_Caught__c)
                appLog.Error_Message__c = logEvent.Message__c;
            else
                appLog.Success_Message__c = logEvent.Message__c;

            appLog.Request_Body__c = logEvent.Request_Body__c;
            appLog.Response_Body__c = logEvent.Response_Body__c;
            appLog.Call_Id__c = logEvent.Call_Id__c;

            appLog.Total_Record_Count__c = logEvent.Total_Record_Count__c;
 
            try {   
                appLog.Service_Appointment__c = logEvent.Service_Appointment_Id__c == null ? null : Id.valueOf(logEvent.Service_Appointment_Id__c);
                appLog.Work_Order__c =  logEvent.Work_Order_Id__c == null ? null : Id.valueOf(logEvent.Work_Order_Id__c);
            } catch (Exception ex) {

            }
            
        }
    }
    List<ApplicationLog> logs = new List<ApplicationLog>();

    for (Application_Log_Event__e ev : Trigger.new) {

        ApplicationLog log = new ApplicationLog(ev);
        log.build();
        logs.add(log);

    }
    FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.Factory().createService();
    service.saveApplicationLogs(logs);


}