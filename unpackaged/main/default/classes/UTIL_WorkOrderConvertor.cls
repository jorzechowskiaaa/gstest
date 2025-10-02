public with sharing class UTIL_WorkOrderConvertor {

    public class Configuration {
        @InvocableVariable (required=true)
        public Integer maxRecords ;
    }

    @InvocableMethod
    public static void convertWorkOrders_flow(List<Configuration> configs) {
        Configuration config = configs[0];        
        convertWorkOrders(config.maxRecords);
    }

    public static void convertWorkOrders(Integer maxRecords) {
        FSL_QueryLocatorBatchable delegate = new FSL_QueryLocatorBatchable( new InternalBatchable( maxRecords ) );
        Database.executeBatch(delegate, 100);
    }
    
    private class InternalBatchable implements FSL_QueryLocatorBatchable.IBatchable {

        private Integer maxRecords;

        public InternalBatchable(Integer maxRecords ) {
            this.maxRecords = maxRecords;
        }

        public Database.QueryLocator start( Database.BatchableContext context ) {

            Set<String> statusList = new Set<String> {
                'Scheduled',
                'Dispatched',
                'En Route',
                'On Location',
                'In Tow',
                'Tow Loaded',
                'Tow Complete'
            };
        
            return Database.getQueryLocator( 
                [SELECT
                            Id,
                            Status,
    
                            Canceled_Timestamp__c,
                            Cleared_Timestamp__c,
                            Dispatched_Timestamp__c,
                            Enroute_Timestamp__c,
                            In_Tow_Timestamp__c,
                            On_Location_Timestamp__c,
                            Resolution_Code__c,
                            Scheduled_Timestamp__c,
                            Spotted_Timestamp__c,
                            Tow_Complete_Timestamp__c,
                            Decline_Work_Reason__c,
                            Payment_Required__c,
                            RAP_Verified__c
    
                            FROM WorkOrder
                            WHERE Status IN :statusList
                            LIMIT :this.maxRecords
                ] );
        }
    
        public void execute( Database.BatchableContext context, WorkOrder[] woList) {

            try {
                for (WorkOrder wo : woList) {    
                    wo.Status = 'In Progress';    
                }

                convertServiceAppointment(woList);

    
                update woList;

            } catch (Exception ex) {
                system.debug('kht ' + ex.getMessage());
            }

        }
    
        public void finish( Database.BatchableContext context ) {
            //
        }
    }


    private static void convertServiceAppointment(WorkOrder[] woList) {

        ServiceAppointment[] apptList = new List<ServiceAppointment>();

        for(WorkOrder wo: woList) {

            ServiceAppointment[] apptList2 =  [SELECT
                                                Id,
                                                Status,

                                                Canceled_Timestamp__c,
                                                Cleared_Timestamp__c,
                                                Dispatched_Timestamp__c,
                                                En_Route_Timestamp__c,
                                                In_Tow_Timestamp__c,
                                                On_Location_Timestamp__c,
                                                Resolution_Code__c,
                                                Scheduled_Timestamp__c,
                                                Spotted_Timestamp__c,
                                                Tow_Complete_Timestamp__c,
                                                Decline_Work_Reason__c,
                                                Payment_Required__c,
                                                RAP_Verified__c

                                                FROM ServiceAppointment
                                                WHERE Work_Order__c = :wo.Id];


            for(ServiceAppointment appt: apptList2) {

                appt.Canceled_Timestamp__c = wo.Canceled_Timestamp__c;
                appt.Cleared_Timestamp__c = wo.Cleared_Timestamp__c;
                appt.Dispatched_Timestamp__c = wo.Dispatched_Timestamp__c;
                appt.En_Route_Timestamp__c = wo.Enroute_Timestamp__c;
                appt.In_Tow_Timestamp__c = wo.In_Tow_Timestamp__c;
                appt.On_Location_Timestamp__c = wo.On_Location_Timestamp__c;
                appt.Resolution_Code__c = wo.Resolution_Code__c;
                appt.Scheduled_Timestamp__c = wo.Scheduled_Timestamp__c;
                appt.Spotted_Timestamp__c = wo.Spotted_Timestamp__c;
                appt.Tow_Complete_Timestamp__c = wo.Tow_Complete_Timestamp__c;
                appt.Decline_Work_Reason__c = wo.Decline_Work_Reason__c;
                appt.Payment_Required__c = wo.Payment_Required__c;
                appt.RAP_Verified__c = wo.RAP_Verified__c;

                apptList.add(appt);
                        
            }
        }

        update apptList;

    }

}