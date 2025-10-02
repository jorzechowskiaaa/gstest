@isTest
public inherited sharing class FSL_ApplicationLogTest {
    
    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateService_NotNull() {
        FSL_ApplicationLog.IFactory factory = new FSL_ApplicationLog.Factory();

        Test.startTest();
        FSL_ApplicationLog.IApplicationLogService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }

    // *********************************************
    // * DAO
    // *********************************************
    // Since the configuration is in Custom Metadata, it cannot be inserted by a test (requires deployment)
    // This test is thus for coverage only
    @IsTest
    public static void testApplicationLogDAO_FetchFSLFeatureFlagConfig_CoverageOnly() {

        FSL_ApplicationLog.ApplicationLogDAO dao = new FSL_ApplicationLog.ApplicationLogDAO();

        Test.startTest();
        dao.fetchFSLFeatureFlagConfig('Enable RoutingLogger');
        Test.stopTest();
    }

    // Since the configuration is in Custom Metadata, it cannot be inserted by a test (requires deployment)
    // This test is thus for coverage only
    @IsTest
    public static void testApplicationLogDAO_FetchPiiSettings_CoverageOnly() {

        FSL_ApplicationLog.ApplicationLogDAO dao = new FSL_ApplicationLog.ApplicationLogDAO();

        Test.startTest();
        List<FSL_PII_Setting__mdt> piiSettings = dao.fetchPiiSettings();
        Test.stopTest();
    }

    
    // *********************************************
    // * Service
    // *********************************************
    @isTest
    public static void testApplicationLogService_PurgeOldRecords_DaoReturnsRecords_RecordsDeleted() {
        // Since this method invokes a Batchable, use a 'real' DAO
        FSL_ApplicationLog.IApplicationLogDAO dao = new FSL_ApplicationLog.ApplicationLogDAO();
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService( dao );

        FSL_Application_Log__c log1 = new FSL_Application_Log__c();
        FSL_Application_Log__c log2 = new FSL_Application_Log__c();
        FSL_Application_Log__c log3 = new FSL_Application_Log__c();
        List<FSL_Application_Log__c> logs = new List<FSL_Application_Log__c>{ log1, log2, log3 };
        insert logs;

        Integer daysToRetain = 12;
        Integer maxRecords = 23;
        Date createdDate = System.now().dateGmt().addDays( -daysToRetain );
        Datetime createdDatetime = Datetime.newInstance( createdDate.year(), createdDate.month(), createdDate.day(), 13, 14, 15 );
        Test.setCreatedDate( log1.Id, createdDatetime.addDays( -1 ) );
        Test.setCreatedDate( log2.Id, createdDatetime );
        Test.setCreatedDate( log3.Id, createdDatetime.addDays( 1 ) );
        
        logs = [SELECT Id FROM FSL_Application_Log__c];
        System.assertEquals( 3, logs.size(), 'Arrange: The number of Application Log records is incorrect' );

        Test.startTest();
        service.purgeOldRecords( daysToRetain, maxRecords );
        Test.stopTest();

        logs = [SELECT Id FROM FSL_Application_Log__c];
        System.assertEquals( 2, logs.size(), 'Assert: The number of Application Log records is incorrect' );
    }

    @isTest
    public static void testApplicationLogService_SaveApplicationLogs_MultipleItems_Inserted() {
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService( dao );

        System.assert( dao.applicationLogs.isEmpty(), 'The DAO Mock contains application logs before the test starts' );

        List<FSL_ApplicationLog.ApplicationLog> logs = new List<FSL_ApplicationLog.ApplicationLog>();
        logs.add( new ApplicationLogImplementation() );
        logs.add( new ApplicationLogImplementation() );
        logs.add( new ApplicationLogImplementation() );

        Test.startTest();
        service.saveApplicationLogs( logs );
        Test.stopTest();

        System.assertEquals( logs.size(), dao.applicationLogs.size(), 'The Application Logs were not inserted' );
    }

    @IsTest
    public static void testApplicationLogService_isRoutingChangeLoggingEnabled_DaoReturnsConfig_Returned() {
        FSL_Feature_Flag__mdt expected = new FSL_Feature_Flag__mdt( Enabled__c = true );
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        dao.fslFeatureFlagConfiguration = expected;
        String featureFlagName = 'Enable RoutingLogger';        
        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService(dao);         

        Test.startTest();
        Boolean expectedIsEnabled = true;
        Boolean actualIsEnabled = service.isRoutingChangeLoggingEnabled();
        Test.stopTest();

        System.assertEquals( expectedIsEnabled, actualIsEnabled );
    }

    @IsTest
    public static void testApplicationLogService_GetPiiSettings_DaoReturnsConfigs_Returned() {
        List<FSL_PII_Setting__mdt> expected = new List<FSL_PII_Setting__mdt>();
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        dao.piiSettings = expected;

        FSL_ApplicationLog.IApplicationLogService service = new FSL_ApplicationLog.ApplicationLogService( dao );

        Test.startTest();
        List<FSL_PII_Setting__mdt> actual = service.getPiiSettings();
        Test.stopTest();

        System.assertEquals( expected, actual );
    }

    // *********************************************
    // * Domain
    // *********************************************
    @IsTest
    public static void testApplicationLog_GetApplicationLog_DefaultConstructor_NotNull() {
        FSL_ApplicationLog.ApplicationLog appLog = new ApplicationLogImplementation();
        FSL_Application_Log__c log = appLog.getApplicationLog();
        
        System.assertNotEquals( null, log );
    }

    @IsTest
    public static void testApplicationLog_GetApplicationLog_InjectedInConstructor_SameValue() {
        FSL_Application_Log__c expected = new FSL_Application_Log__c( Operation__c = 'Operation' );
        FSL_ApplicationLog.ApplicationLog appLog = new ApplicationLogImplementation( expected );
        FSL_Application_Log__c actual = appLog.getApplicationLog();

        System.assertEquals( expected, actual );
    }

    @IsTest
    public static void testApplicationLog_AppendFormattedExceptionToErrorMessage_Appended() {
        FSL_Application_Log__c log = new FSL_Application_Log__c();
        ApplicationLogImplementation appLog = new ApplicationLogImplementation( log );

        String initial = 'Initial Error Message';
        log.Error_Message__c = initial;
        Exception ex = new DmlException( 'Exception Message' );

        String expected = initial + 'Exception info' + '\r\n' + 'Message: ' + ex.getMessage() + '\r\n' + 'Cause: ' + ex.getCause() + '\r\n' + 'Stack Trace: ' + ex.getStackTraceString() + '\r\n';
        
        Test.startTest();
        appLog.testAppendFormattedExceptionToErrorMessage( ex );
        Test.stopTest();

        System.assertEquals( expected, appLog.getApplicationLog().Error_Message__c );
    }

    @IsTest
    public static void testApplicationLog_MaskPiiDataInJson_Masked() {
        FSL_Application_Log__c log = new FSL_Application_Log__c();
        ApplicationLogImplementation appLog = new ApplicationLogImplementation( log );

        List<FSL_PII_Setting__mdt> piiSettings = new List<FSL_PII_Setting__mdt>();
        piiSettings.add( new FSL_PII_Setting__mdt( DeveloperName = 'REGEX', Value__c = '(\"Variable\")(\\s*:\\s*)"((\\\\\"|[^\"])*)\"' ) ); // ("Variable")(\s*:\s*)"((\\"|[^"])*)"
        piiSettings.add( new FSL_PII_Setting__mdt( DeveloperName = 'PII_Variables', Value__c = 'MaskedVariable1,MaskedVariable2' ) );

        String jsonInput = '{ ' + 
                            '\"MaskedVariable1\" : \"item to be masked\", ' + 
                            '\"MaskedVariable2\" : \"another item to be masked\", ' + 
                            '\"MaskedVariable3\" : \"Do not let the name fool you, no masking here\" ' + 
                            '\"ListWithoutSpaces\" : [{' + 
                                '\"MaskedVariable1\":\"item to be masked\", ' + 
                                '\"MaskedVariable2\":\"another item to be masked\", ' + 
                                '\"MaskedVariable3\":\"Do not let the name fool you, no masking here\" ' + 
                                '}],' + 
                            '\"ListWithLeadingSpace\" : [{' + 
                                '\"MaskedVariable1\" :\"item to be masked\", ' + 
                                '\"MaskedVariable2\" :\"another item to be masked\", ' + 
                                '\"MaskedVariable3\" :\"Do not let the name fool you, no masking here\" ' + 
                                '}],' + 
                            '\"ListWithTrailingSpace\" : [{' + 
                                '\"MaskedVariable1\": \"item to be masked\", ' + 
                                '\"MaskedVariable2\": \"another item to be masked\", ' + 
                                '\"MaskedVariable3\": \"Do not let the name fool you, no masking here\" ' + 
                                '}]' + 
                            '}';

        String expected = '{ ' + 
                            '\"MaskedVariable1\" : \"*****\", ' + 
                            '\"MaskedVariable2\" : \"*****\", ' + 
                            '\"MaskedVariable3\" : \"Do not let the name fool you, no masking here\" ' + 
                            '\"ListWithoutSpaces\" : [{' + 
                                '\"MaskedVariable1\" : \"*****\", ' + 
                                '\"MaskedVariable2\" : \"*****\", ' + 
                                '\"MaskedVariable3\":\"Do not let the name fool you, no masking here\" ' + 
                                '}],' + 
                            '\"ListWithLeadingSpace\" : [{' + 
                                '\"MaskedVariable1\" : \"*****\", ' + 
                                '\"MaskedVariable2\" : \"*****\", ' + 
                                '\"MaskedVariable3\" :\"Do not let the name fool you, no masking here\" ' + 
                                '}],' + 
                            '\"ListWithTrailingSpace\" : [{' + 
                                '\"MaskedVariable1\" : \"*****\", ' + 
                                '\"MaskedVariable2\" : \"*****\", ' + 
                                '\"MaskedVariable3\": \"Do not let the name fool you, no masking here\" ' + 
                                '}]' + 
                            '}';
        
        Test.startTest();
        String actual = appLog.testMaskPiiDataInJson( jsonInput, piiSettings );
        Test.stopTest();

        System.assertEquals( null, appLog.getApplicationLog().Error_Message__c );
        System.assertEquals( expected, actual );
    }

    @IsTest
    public static void testApplicationLog_LimitLength_Limited() {
        FSL_Application_Log__c log = new FSL_Application_Log__c();
        ApplicationLogImplementation appLog = new ApplicationLogImplementation( log );

        String stringWith100characters = 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890' + 
                    '1234567890';
        String input = '';
        for( Integer i = 0; i <= appLog.MAX_FIELD_LENGTH / 100; i++ ) {
            input += stringWith100characters;
        }

        System.assert( input.length() > appLog.MAX_FIELD_LENGTH, 'Test input is not long enough for testing' );
        
        Test.startTest();
        String trimmed = appLog.testLimitLength( input );
        Test.stopTest();

        System.assertEquals( appLog.MAX_FIELD_LENGTH, trimmed.length(), 'The input was not trimmed' );
    }

    @IsTest
    public static void testApplicationLog_GetProcessTime_NotNull_DifferenceInMilliseconds() {
        Datetime endTime = Datetime.now();
        Datetime startTime = endTime.addMinutes( -12 ).addSeconds( -23 );
        Long expected = endTime.getTime() - startTime.getTime();
        
        testApplicationLog_GetProcessTime( startTime, endTime, expected );
    }

    @IsTest
    public static void testApplicationLog_GetProcessTime_StartTimeNull_Null() {
        Datetime endTime = Datetime.now();
        Datetime startTime = null;
        Long expected = null;
        
        testApplicationLog_GetProcessTime( startTime, endTime, expected );
    }

    @IsTest
    public static void testApplicationLog_GetProcessTime_EndTimeNull_Null() {
        Datetime endTime = null;
        Datetime startTime = Datetime.now();
        Long expected = null;
        
        testApplicationLog_GetProcessTime( startTime, endTime, expected );
    }

    @IsTest
    public static void testApplicationLog_GetProcessTime_StartAndEndTimeNull_Null() {
        Datetime endTime = null;
        Datetime startTime = null;
        Long expected = null;
        
        testApplicationLog_GetProcessTime( startTime, endTime, expected );
    }

    private static void testApplicationLog_GetProcessTime( Datetime startTime, Datetime endTime, Long expected ) {
        FSL_Application_Log__c log = new FSL_Application_Log__c();
        ApplicationLogImplementation appLog = new ApplicationLogImplementation( log );
        
        Test.startTest();
        Long actual = appLog.testGetProcessTime( startTime, endTime );
        Test.stopTest();

        System.assertEquals( expected, actual, 'GetProcessTime did not return the expected value' );
    }

    // *********************************************
    // * FactoryMock
    // *********************************************
    public class FactoryMock implements FSL_ApplicationLog.IFactory {
        public FSL_ApplicationLog.IApplicationLogService createService() {
            return new ApplicationLogServiceMock();
        }
    }

    @IsTest
    public static void testFactoryMock_CreateService_NotNull() {
        FactoryMock factory = new FactoryMock();

        Test.startTest();
        FSL_ApplicationLog.IApplicationLogService service = factory.createService();
        Test.stopTest();

        System.assertNotEquals( null, service );
    }
    
    // *********************************************
    // * DAOMock
    // *********************************************
    private static final Schema.SObjectType APPLICATIONLOG_TYPE = FSL_Application_Log__c.getSObjectType();
    public class ApplicationLogDAOMock extends FSL_DAOTest.DmlBaseMock implements FSL_ApplicationLog.IApplicationLogDAO {
        public Map<Id, FSL_Application_Log__c> applicationLogs;
        public FSL_Feature_Flag__mdt fslFeatureFlagConfiguration = new FSL_Feature_Flag__mdt();
        public List<FSL_PII_Setting__mdt> piiSettings = new List<FSL_PII_Setting__mdt>();
        public Boolean isSuccess = true;
        
        public ApplicationLogDAOMock() {
            super( new Map<Id, FSL_Application_Log__c>(), APPLICATIONLOG_TYPE );
            this.applicationLogs = (Map<Id, FSL_Application_Log__c>)super.Records;
        }

        private void isQueryException() {
            if( !isSuccess ) {
                throw new QueryException( 'Forced Exception from ApplicationLogDAOMock' );
            }
        }

        public List<FSL_Feature_Flag__mdt> fetchFSLFeatureFlagConfig(String featureFlagName) {            
            List<FSL_Feature_Flag__mdt> result = new List<FSL_Feature_Flag__mdt>();
            if( fslFeatureFlagConfiguration != null ) {
                result.add( fslFeatureFlagConfiguration );
            }
            return result;         
        }

        public List<FSL_PII_Setting__mdt> fetchPiiSettings() {
            isQueryException();
            return piiSettings;
        }
    }

    @IsTest
    public static void testApplicationLogDAOMock_FetchFSLFeatureFlagConfig_ConfigReturned() {
        FSL_Feature_Flag__mdt expected = new FSL_Feature_Flag__mdt( Enabled__c = true );
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        dao.fslFeatureFlagConfiguration = expected;
        String featureFlagName = 'Enable RoutingLogger';
        
        Test.startTest();
        List<FSL_Feature_Flag__mdt> actual = dao.fetchFSLFeatureFlagConfig(featureFlagName);
        Test.stopTest();

        System.assertEquals( 1, actual.size() );
        System.assertEquals( expected, actual[0] );
    }

    @IsTest
    public static void testApplicationLogDAOMock_FetchPiiSettings_Success_Returned() {
        List<FSL_PII_Setting__mdt> expected = new List<FSL_PII_Setting__mdt>{ new FSL_PII_Setting__mdt(), new FSL_PII_Setting__mdt() };
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        
        Test.startTest();
        List<FSL_PII_Setting__mdt> defaultValue = dao.fetchPiiSettings();

        dao.piiSettings = expected;
        List<FSL_PII_Setting__mdt> actual = dao.fetchPiiSettings();
        Test.stopTest();

        System.assert( defaultValue.isEmpty() );
        System.assertEquals( expected, actual );
    }

    @IsTest
    public static void testApplicationLogDAOMock_FetchPiiSettings_NotSuccess_ExceptionThrown() {
        ApplicationLogDAOMock dao = new ApplicationLogDAOMock();
        dao.isSuccess = false;
        Exception ex = null;

        Test.startTest();
        try {
            dao.fetchPiiSettings();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class ApplicationLogServiceMock implements FSL_ApplicationLog.IApplicationLogService {
        public Boolean throwsException = false;
        
        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in ApplicationLogServiceMock' );
            }
        }

        public Integer purgeOldRecordsCallCount = 0;
        public void purgeOldRecords( Integer daysToRetain, Integer maxRecords ) {
            purgeOldRecordsCallCount++;
            throwExceptionIfConfigured();
        }

        public Integer saveApplicationLogsCallCount = 0;
        public void saveApplicationLogs( List<FSL_ApplicationLog.ApplicationLog> logs ) {
            saveApplicationLogsCallCount++;
            throwExceptionIfConfigured();
        }
        
        public Integer isRoutingChangeLoggingEnabledCallCount = 0;
        public Boolean isRoutingChangeLoggingEnabledReturnValue = false;
        public Boolean isRoutingChangeLoggingEnabled() {
            isRoutingChangeLoggingEnabledCallCount++;
            throwExceptionIfConfigured();
            return isRoutingChangeLoggingEnabledReturnValue;
        }

        public Integer getPiiSettingsCallCount = 0;
        public List<FSL_PII_Setting__mdt> getPiiSettingsReturnValue = new List<FSL_PII_Setting__mdt>();
        public List<FSL_PII_Setting__mdt> getPiiSettings() {
            getPiiSettingsCallCount++;
            throwExceptionIfConfigured();
            return getPiiSettingsReturnValue;
        }
    }

    @isTest
    public static void testApplicationLogServiceMock_PurgeOldRecords_NoException_CallCountIncremented() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();

        System.assertEquals( 0, service.purgeOldRecordsCallCount );

        Test.startTest();
        service.purgeOldRecords( 123, 456 );
        Test.stopTest();

        System.assertEquals( 1, service.purgeOldRecordsCallCount );
    }

    @isTest
    public static void testApplicationLogServiceMock_PurgeOldRecords_Exception_CallCountIncrementedAndExceptionThrown() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.purgeOldRecordsCallCount );

        Test.startTest();
        try {
            service.purgeOldRecords( 123, 456 );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.purgeOldRecordsCallCount );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testApplicationLogServiceMock_SaveApplicationLogs_NoException_CallCountIncremented() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();

        System.assertEquals( 0, service.saveApplicationLogsCallCount );

        Test.startTest();
        service.saveApplicationLogs( null );
        Test.stopTest();

        System.assertEquals( 1, service.saveApplicationLogsCallCount );
    }

    @isTest
    public static void testApplicationLogServiceMock_SaveApplicationLogs_Exception_CallCountIncrementedAndExceptionThrown() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.saveApplicationLogsCallCount );

        Test.startTest();
        try {
            service.saveApplicationLogs( null );
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.saveApplicationLogsCallCount );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testApplicationLogServiceMock_IsRoutingChangeLoggingEnabled_NoException_CorrectValueReturnedAndCallCountIncremented() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        Boolean expectedDefaultValue = false;
        Boolean expectedUpdatedValue = true;

        System.assertEquals( 0, service.isRoutingChangeLoggingEnabledCallCount );

        Test.startTest();        
        Boolean actualDefaultValue = service.isRoutingChangeLoggingEnabled();
        Integer callCount1 = service.isRoutingChangeLoggingEnabledCallCount;

        service.isRoutingChangeLoggingEnabledReturnValue = expectedUpdatedValue;
        Boolean actualUpdatedValue = service.isRoutingChangeLoggingEnabled();
        Integer callCount2 = service.isRoutingChangeLoggingEnabledCallCount;
        Test.stopTest();

        System.assertEquals( expectedDefaultValue, actualDefaultValue );
        System.assertEquals( expectedUpdatedValue, actualUpdatedValue );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @isTest
    public static void testApplicationLogServiceMock_IsRoutingChangeLoggingEnabled_Exception_CallCountIncrementedAndExceptionThrown() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.isRoutingChangeLoggingEnabledCallCount );

        Test.startTest();
        try {
            service.isRoutingChangeLoggingEnabled();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.isRoutingChangeLoggingEnabledCallCount );
        System.assertNotEquals( null, ex );
    }

    @isTest
    public static void testApplicationLogServiceMock_GetPiiSettings_NoException_CorrectValueReturnedAndCallCountIncremented() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        List<FSL_PII_Setting__mdt> expectedDefaultValue = new List<FSL_PII_Setting__mdt>();
        List<FSL_PII_Setting__mdt> expectedUpdatedValue = new List<FSL_PII_Setting__mdt>{ new FSL_PII_Setting__mdt(), new FSL_PII_Setting__mdt() };

        System.assertEquals( 0, service.getPiiSettingsCallCount );

        Test.startTest();        
        List<FSL_PII_Setting__mdt> actualDefaultValue = service.getPiiSettings();
        Integer callCount1 = service.getPiiSettingsCallCount;

        service.getPiiSettingsReturnValue = expectedUpdatedValue;
        List<FSL_PII_Setting__mdt> actualUpdatedValue = service.getPiiSettings();
        Integer callCount2 = service.getPiiSettingsCallCount;
        Test.stopTest();

        System.assertEquals( expectedDefaultValue, actualDefaultValue );
        System.assertEquals( expectedUpdatedValue, actualUpdatedValue );
        System.assertEquals( 1, callCount1 );
        System.assertEquals( 2, callCount2 );
    }

    @isTest
    public static void testApplicationLogServiceMock_GetPiiSettings_Exception_CallCountIncrementedAndExceptionThrown() {
        ApplicationLogServiceMock service = new ApplicationLogServiceMock();
        service.throwsException = true;
        Exception ex = null;

        System.assertEquals( 0, service.getPiiSettingsCallCount );

        Test.startTest();
        try {
            service.getPiiSettings();
        }
        catch( Exception e ) {
            ex = e;
        }
        Test.stopTest();

        System.assertEquals( 1, service.getPiiSettingsCallCount );
        System.assertNotEquals( null, ex );
    }

    // *********************************************
    // * DomainTestDouble
    // *********************************************
    public class ApplicationLogImplementation extends FSL_ApplicationLog.ApplicationLog {
        public ApplicationLogImplementation() {
            super();
        }

        public ApplicationLogImplementation( FSL_Application_Log__c appLog ) {
            super( appLog );
        }

        protected override void setDefaultApplicationLogFields() {
        }

        public void testAppendFormattedExceptionToErrorMessage( Exception ex ) {
            appendFormattedExceptionToErrorMessage( ex );
        }

        public String testMaskPiiDataInJson( String jsonInput, List<FSL_PII_Setting__mdt> piiSettings ) {
            return maskPiiDataInJson( jsonInput, piiSettings );
        }

        public String testLimitLength( String input ) {
            return limitLength( input );
        }

        public Long testGetProcessTime( Datetime startTime, Datetime endTime ) {
            return getProcessTime( startTime, endTime );
        }
    }
}