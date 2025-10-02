public with sharing class FSL_Mapping {

    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IMap createMap( FSL_ApplicationLog.IApplicationLogService applicationLogService );
    }

    public class Factory implements IFactory {
        public IMap createMap( FSL_ApplicationLog.IApplicationLogService applicationLogService ) {
            return new BingMap( applicationLogService );
        }
    }

    // *********************************************
    // * Generic Mapping Interface
    // *********************************************
    public interface IMap {
        Decimal calculateDistanceInMiles( Double latOrigin, Double longOrigin, Double latDestination, Double longDestination );
    }

    public abstract class AbstractMap {
        private FSL_ApplicationLog.IApplicationLogService applicationLogService;
        @testVisible private FSL_Mapping__mdt config = null;
        protected String apiName;

        public AbstractMap( FSL_ApplicationLog.IApplicationLogService applicationLogService, String apiName ) {
            this.applicationLogService = applicationLogService;
            this.apiName = apiName;
        }

        private void loadMappingConfig() {
            List<FSL_Mapping__mdt> configs = [SELECT API_Key__c 
                                                FROM FSL_Mapping__mdt 
                                                WHERE DeveloperName = :apiName];
            if( configs.size() == 1 ) {
                config = configs[0];
            }
            else {
                throw new DmlException( configs.size() + ' configs found for name ' + apiName );
            }
        }

        protected String getApiKey() {
            if( config == null ) loadMappingConfig();
            return config.API_Key__c;
        }

        protected String performGetCallout( String url ) {
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint( url );
            req.setMethod( 'GET' );
            HttpResponse resp = h.send( req );
            if( resp.getStatusCode() != 200 ) {
                throw new FailedCalloutException( 'Callout returned Status Code [' + resp.getStatusCode() + '] - Status = [' + resp.getStatus() + ']' );
            }
            return resp.getBody();
        }
    }

    // *********************************************
    // * Bing
    // *********************************************
    public class BingMap extends AbstractMap implements IMap {
        public BingMap( FSL_ApplicationLog.IApplicationLogService applicationLogService ) {
            super( applicationLogService, 'Bing' );
        }

        public Decimal calculateDistanceInMiles( Double latOrigin, Double longOrigin, Double latDestination, Double longDestination ) {
            Decimal miles = 0.0;
            MappingApplicationLog log = new MappingApplicationLog( apiName, 'CalculateDistanceInMiles' );
            Datetime startTime = System.now();
            try {
                String response = performDistanceMatrixCallout( latOrigin, longOrigin, latDestination, longDestination, log );
                BingDistanceMatrixResponse bingResponse = parseAndValidateResponse( response );
                miles = bingResponse.resourceSets[0].resources[0].results[0].travelDistance;
                log.logResult( 'Miles calculated: [' + String.valueOf( miles ) + ']', startTime, System.now() );
            }
            catch( FailedCalloutException ex ) {
                log.logFailedCalloutException( ex, startTime, System.now() );
            }
            catch( CalloutException ex ) {
                log.logCalloutException( ex, startTime, System.now() );
            }
            catch( Exception ex ) {
                log.logGenericException( ex, startTime, System.now() );
            }
            finally {
                //applicationLogService.saveApplicationLogs( new List<FSL_ApplicationLog.ApplicationLog>{ log } );
            }
            return miles;
        }

        private String performDistanceMatrixCallout( Double latOrigin, Double longOrigin, Double latDestination, Double longDestination, MappingApplicationLog log ) {
            String url = 'http://dev.virtualearth.net/REST/V1/Routes/DistanceMatrix';
            url += '?distanceUnit=mi';
            url += '&travelMode=driving';
            url += '&origins=' + String.valueOf( latOrigin ) + ',' + String.valueOf( longOrigin );
            url += '&destinations=' + String.valueOf( latDestination ) + ',' + String.valueOf( longDestination );
            log.logRequest( url );
            Datetime startTime = System.now();
            String response = performGetCallout( url + '&key=' + getApiKey() );
            log.logResponse( response, startTime, System.now() );
            return response;
        }

        private BingDistanceMatrixResponse parseAndValidateResponse( String response ) {
            BingDistanceMatrixResponse bingResponse = (BingDistanceMatrixResponse)JSON.deserialize( response, FSL_Mapping.BingDistanceMatrixResponse.class );
            if( bingResponse.statusCode != 200 ) {
                throw new FailedCalloutException( 'Callout Response contains Status Code [' + bingResponse.statusCode + '] - Status Description = [' + bingResponse.statusDescription + ']' );
            }
            return bingResponse;
        }
    }

    // *********************************************
    // * Bing Distance Matrix Payload
    // *********************************************
    public class BingDistanceMatrixResponse {
        public Integer statusCode {get;set;}
        public String statusDescription {get;set;}
        List<BingDistanceMatrixResourceSet> resourceSets {get;set;}
    }

    public class BingDistanceMatrixResourceSet {
        List<BingDistanceMatrixResource> resources {get;set;}
    }

    public class BingDistanceMatrixResource {
        List<BingDistanceMatrixResult> results {get;set;}
    }

    public class BingDistanceMatrixResult {
        public Double travelDistance {get;set;}
    }

    // *********************************************
    // * ApplicationLog
    // *********************************************
    public class MappingApplicationLog extends FSL_ApplicationLog.ApplicationLog {
        public MappingApplicationLog( String apiName, String operationName ) {
            super();
            appLog.API_Name__c = apiName;
            appLog.Operation__c = operationName;
        }

        protected override void setDefaultApplicationLogFields() {
            appLog.DateTime__c = System.now();
            appLog.RecordTypeId = generalRecordTypeId;
            appLog.Error_Caught__c = false;
        }

        public void logRequest( String request ) {
            appLog.Request_Body__c = request;
        }

        public void logResponse( String response, Datetime startTime, Datetime endTime ) {
            appLog.Response_Body__c = response;
            appLog.ServiceTime__c = getProcessTime( startTime, endTime );
        }

        public void logFailedCalloutException( FailedCalloutException ex, Datetime startTime, Datetime endTime ) {
            appLog.Error_Message__c = 'Callout request failed' + '\r\n';
            logException( ex, startTime, endTime );
        }

        public void logCalloutException( CalloutException ex, Datetime startTime, Datetime endTime ) {
            appLog.Error_Message__c = 'Callout exception' + '\r\n';
            logException( ex, startTime, endTime );
        }

        public void logGenericException( Exception ex, Datetime startTime, Datetime endTime ) {
            appLog.Error_Message__c = 'Generic exception' + '\r\n';
            logException( ex, startTime, endTime );
        }

        private void logException( Exception ex, Datetime startTime, Datetime endTime ) {
            appLog.Error_Caught__c = true;
            appendFormattedExceptionToErrorMessage( ex );
            if( appLog.ServiceTime__c == null ) { // Callout was not successful
                appLog.ServiceTime__c = getProcessTime( startTime, endTime );
            }
            else { // Exception while processing the response
                appLog.OutputProcessingTime__c = getProcessTime( startTime, endTime ) - appLog.ServiceTime__c;
            }
        }

        public void logResult( String successMessage, Datetime startTime, Datetime endTime ) {
            appLog.Success_Message__c = successMessage;
            appLog.OutputProcessingTime__c = getProcessTime( startTime, endTime ) - ( appLog.ServiceTime__c != null ? appLog.ServiceTime__c : 0 );
        }
    }

    // *********************************************
    // * Exceptions
    // *********************************************
    public class FailedCalloutException extends Exception {
    }
}