public inherited sharing class FSL_ApplicationLog {
    // *********************************************
    // * Factory
    // *********************************************
    public interface IFactory {
        IApplicationLogService createService();
    }

    public class Factory implements IFactory {
        public IApplicationLogService createService() {
            IApplicationLogDAO dao = createDAO();
            return new ApplicationLogService( dao );
        }

        private IApplicationLogDAO createDAO() {
            return new ApplicationLogDAO();
        }
    }

    // *********************************************
    // * DAO
    // *********************************************
    public interface IApplicationLogDAO extends FSL_DAO.DmlInterface {
        List<FSL_Feature_Flag__mdt> fetchFSLFeatureFlagConfig(String featureFlagName);
        List<FSL_PII_Setting__mdt> fetchPiiSettings();
    }
    
    public class ApplicationLogDAO extends FSL_DAO.DmlBase implements IApplicationLogDAO {
        public List<FSL_Feature_Flag__mdt> fetchFSLFeatureFlagConfig( String featureFlagName ) {
            return [SELECT Enabled__c
                    FROM   FSL_Feature_Flag__mdt
                    WHERE  MasterLabel = :featureFlagName  
                    LIMIT 1];
        }

        public List<FSL_PII_Setting__mdt> fetchPiiSettings() {
            return [SELECT DeveloperName, value__c 
                    FROM FSL_PII_Setting__mdt];
        }
    }

    // *********************************************
    // * Service
    // *********************************************
    public interface IApplicationLogService {
        void purgeOldRecords( Integer daysToRetain, Integer maxRecords );
        void saveApplicationLogs( List<ApplicationLog> logs );
        Boolean isRoutingChangeLoggingEnabled();
        List<FSL_PII_Setting__mdt> getPiiSettings();
    }

    public class ApplicationLogService implements IApplicationLogService {
        private IApplicationLogDAO dao;
        private Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        private Id platformEventRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('Platform Event').getRecordTypeId();

        public ApplicationLogService( IApplicationLogDAO dao ) {
            this.dao = dao;
        }

        public void purgeOldRecords( Integer daysToRetain, Integer maxRecords ) {
            FSL_QueryLocatorBatchable delegate = new FSL_QueryLocatorBatchable( new PurgeOldRecordBatchable( daysToRetain, maxRecords ) );
            Database.executeBatch( delegate );
        }

        public void saveApplicationLogs( List<ApplicationLog> logs ) {
            List<FSL_Application_Log__c> appLogs = new List<FSL_Application_Log__c>();
            for( ApplicationLog log : logs ) {
                appLogs.add( log.getApplicationLog() );
            }
            if( !appLogs.isEmpty() ) {
                dao.insertRecords( appLogs );
            }
        }
        
        public Boolean isRoutingChangeLoggingEnabled(){
            Boolean isEnabled = false;
            String FSLFeatureName = 'Enable RoutingLogger';

            FSL_Feature_Flag__mdt config = null;
            List<FSL_Feature_Flag__mdt> configs = dao.fetchFSLFeatureFlagConfig(FSLFeatureName);
            if( configs.size() == 1 ) {
                config = configs[0];
                isEnabled = config.Enabled__c;
            }
            
            return isEnabled;
        }

        public List<FSL_PII_Setting__mdt> getPiiSettings() {
            return dao.fetchPiiSettings();
        }
    }

    // *********************************************
    // * Domain
    // *********************************************
    public abstract class ApplicationLog {
        protected FSL_Application_Log__c appLog;
        protected Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        protected Id platformEventRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('Platform Event').getRecordTypeId();
        @testVisible private final Integer MAX_FIELD_LENGTH = 32000;

        public ApplicationLog() {
            appLog = new FSL_Application_Log__c();
            setDefaultApplicationLogFields();
        }

        public ApplicationLog( FSL_Application_Log__c appLog ) {
            this.appLog = appLog;
        }

        public FSL_Application_Log__c getApplicationLog() {
            return appLog;
        }

        public void logUpsertResult( Database.upsertResult upsertResult ) {
            if( !upsertResult.isSuccess() ) {
                appLog.Error_Caught__c = true;
                appLog.Error_Message__c = getErrorMessageForFailedUpsert( upsertResult );
            }
        }

        private String getErrorMessageForFailedUpsert( Database.upsertResult result ) {
            String errorMessage = 'Failed Upsert for Id = [' + result.getId() + ']' + '\r\n';
            Integer errorCount = result.getErrors().size();
            errorMessage += errorCount + ' error(s):' + '\r\n';
            Integer currentError = 1;
            for( Database.Error error : result.getErrors() ) {
                errorMessage += 'Error ' + currentError + ':' + '\r\n';
                errorMessage += getErrorMessage( error );
                currentError++;
            }
            return errorMessage;
        }

        private String getErrorMessage( Database.Error error ) {
            String errorMessage = '';
            errorMessage += 'Status Code = [' + error.getStatusCode() + '] ' + '\r\n';
            errorMessage += 'Fields = [' + error.getFields() + '] ' + '\r\n';
            errorMessage += 'Message = [' + error.getMessage() + ']' + '\r\n';
            return errorMessage;
        }

        protected void appendFormattedExceptionToErrorMessage( Exception ex ) {
            appLog.Error_Message__c += 'Exception info' + '\r\n';
            appLog.Error_Message__c += 'Message: ' + ex.getMessage() + '\r\n';
            appLog.Error_Message__c += 'Cause: ' + ex.getCause() + '\r\n';
            appLog.Error_Message__c += 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';
        }

        protected String maskPiiDataInJson( String jsonInput, List<FSL_PII_Setting__mdt> piiSettings ) {
            String result = jsonInput;
            try {
                String reg_Ex;
                String pii_Variables;
                for( FSL_PII_Setting__mdt piiSetting : piiSettings ) {
                    if( 'REGEX'.equalsignorecase( piiSetting.DeveloperName ) ) {
                        reg_Ex = piiSetting.Value__c;
                    }
                    else if( 'PII_Variables'.equalsignorecase( piiSetting.DeveloperName ) ) {
                        pii_Variables = piiSetting.Value__c;
                    }
                }
                if( jsonInput != null && !String.isEmpty( reg_Ex ) && !String.isEmpty( pii_Variables ) ) {
                    List<String> piiVariables = pii_Variables.split( ',' );
                    for( String variable : piiVariables ) {
                        String rg = reg_Ex.replace( 'Variable', variable );
                        string replace = '\"' + variable + '\" : \"*****\"';
                        result = result.replaceAll( rg, replace );
                    }
                }
            }
            catch( Exception ex ) {
                appLog.Error_Message__c += 'Exception caught while masking PII data: ' + '\r\n';
                appendFormattedExceptionToErrorMessage( ex );
            }
            return result;
        }

        protected String limitLength( String input ) {
            if( !String.isBlank( input ) && input.length() > MAX_FIELD_LENGTH ) {
                input = input.substring( 0, MAX_FIELD_LENGTH );
            }
            return input;
        }

        protected long getProcessTime( DateTime startTime, DateTime endTime ) {
            long processTime;
            if( startTime != null && endTime != null ) {
                processTime = endTime.getTime() - startTime.getTime();
            }
            return processTime;
        }

        protected abstract void setDefaultApplicationLogFields();
    }
  
    // *********************************************
    // * Batchable Implementation
    // *********************************************
    private class PurgeOldRecordBatchable implements FSL_QueryLocatorBatchable.IBatchable {
        private Integer daysToRetain;
        private Integer maxRecords;

        public PurgeOldRecordBatchable( Integer daysToRetain, Integer maxRecords ) {
            this.daysToRetain = daysToRetain;
            this.maxRecords = maxRecords;
        }

        public Database.QueryLocator start( Database.BatchableContext context ) {
            Date createdDate = System.now().dateGmt().addDays( -daysToRetain );
            return Database.getQueryLocator(
                [SELECT CreatedDate, Id 
                FROM FSL_Application_Log__c 
                WHERE CreatedDate < :createdDate
                LIMIT :maxRecords] );
        }
    
        public void execute( Database.BatchableContext context, List<SObject> items ) {
            if( items.size() > 0 ) {
                delete items;
            }
        }
    
        public void finish( Database.BatchableContext context ) {
        }
    }
}