public with sharing class DefaultStatePTA {

    @AuraEnabled
    public static Integer getDefaultStatePTA ( String state, String serviceType ){

        Decimal ptaMinutes = 0;

        try {
            List<Default_State_PTA__mdt> pta = [SELECT PTA__c, State__c, Service_Type__c FROM Default_State_PTA__mdt WHERE State__c =: state and Service_Type__c =: serviceType LIMIT 1];
            if ( pta != null && pta.size() > 0 ) {
                //System.debug('from SOQL --->'+pta[0].PTA__c);
                ptaMinutes = pta[0].PTA__c;
            }
        } catch ( Exception e ) {
            String ErrMsg = 'Table for meta data could not be queried. ' +'\n' +String.valueOf(e)+'. \n'+e.getStackTraceString()+(e.getCause() != NULL ?'. \n'+String.valueof(e.getCause()):'');
            throw (Exception) (new AuraHandledException(ErrMsg));
        }
        //System.debug ('return defaultPTA--->'+defaultPTA);
        System.debug ( 'DefaultStatePTA.getDefaultStatePTA (' + state + ',' + serviceType + ')= ' + ptaMinutes );
        return ptaMinutes.intValue();
    }

    public static String getPtaAsStandardUTC ( String state, String serviceType ) {

        DateTime ptaDateTime = getPTADateTime ( state, serviceType );
        //Standard format is yyyy-MM-ddTHH:mm:ss.sssZ (e.g. '2022-03-30T21:37:58.012Z')
        String ptaAsUTC = JSON.serialize (ptaDateTime);
        System.debug ('ptaAsUTC= ' + ptaAsUTC );
        return ptaAsUTC;
    }

    @AuraEnabled
    public static DateTime getPTADateTime ( String state, String serviceType ) {

        Integer ptaMinutes = getDefaultStatePTA ( state, serviceType );
        DateTime serviceStartTime = DateTime.now();
        Long millSec = serviceStartTime.getTime() + ( ptaMinutes*60*1000 );
        DateTime ptaDateTime = DateTime.newInstance ( millSec );
        return ptaDateTime;
    }

    public static String getPtaAsHourMin ( String state, String serviceType ) {

        DateTime ptaDateTime = getPTADateTime ( state, serviceType );
        String fmt = 'HH:mm';
        String ptaAsHourMin = formatTime ( ptaDateTime, fmt );
        System.debug ('ptaAsHourMin ' + ptaAsHourMin );
        return ptaAsHourMin;
    }

    private static String formatTime ( DateTime dt, String fmt ) {
        return dt.format ( fmt );
    }
    // private static String formatTime ( DateTime dt, String fmt, String tz ) {
    //     return dt.format ( fmt, tz );
    // }

}