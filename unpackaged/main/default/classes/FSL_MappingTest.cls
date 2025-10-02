@IsTest
public with sharing class FSL_MappingTest {

    // *********************************************
    // * Factory
    // *********************************************
    @IsTest
    public static void testFactory_CreateMap_NotNull() {
        FSL_Mapping.IFactory factory = new FSL_Mapping.Factory();

        Test.startTest();
        FSL_Mapping.IMap m = factory.createMap( null );
        Test.stopTest();

        System.assertNotEquals( null, m );
    }

    // *********************************************
    // * Bing
    // *********************************************
    @IsTest
    public static void testBingMap_CalculateDistanceInMiles_CalloutSuccessful_MilesCalculated() {
        String response = 
        '{' + 
            '"authenticationResultCode": "ValidCredentials",' + 
            '"brandLogoUri": "http://dev.virtualearth.net/Branding/logo_powered_by.png",' + 
            '"copyright": "Copyright © 2021 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.",' + 
            '"resourceSets": [' + 
            '{' + 
                    '"estimatedTotal": 1,' + 
                    '"resources": [' + 
                        '{' + 
                            '"__type": "DistanceMatrix:http://schemas.microsoft.com/search/local/ws/rest/v1",' + 
                            '"destinations": [' + 
                                '{' + 
                                    '"latitude": 32.715685218572617,' + 
                                    '"longitude": -117.16172486543655' + 
                                '}' + 
                            '],' + 
                            '"origins": [' + 
                                '{' + 
                                    '"latitude": 37.779160067439079,' + 
                                    '"longitude": -122.42004945874214' + 
                                '}' + 
                            '],' + 
                            '"results": [' + 
                                '{' + 
                                    '"destinationIndex": 0,' + 
                                    '"originIndex": 0,' + 
                                    '"totalWalkDuration": 0,' + 
                                    '"travelDistance": 501.3975,' + 
                                    '"travelDuration": 422.5667' + 
                                '}' + 
                            ']' + 
                        '}' + 
                    ']' + 
                '}' + 
            '],' + 
            '"statusCode": 200,' + 
            '"statusDescription": "OK",' + 
            '"traceId": "37bd8edea1e54860ab145bc27b24b302|CH000010A5|0.0.0.0|CH000014C3"' + 
        '}';
        
        FSL_Mapping.IMap bingMap = new FSL_Mapping.BingMap( new FSL_ApplicationLogTest.ApplicationLogServiceMock() );
        ((FSL_Mapping.AbstractMap)bingMap).config = new FSL_Mapping__mdt( API_Key__c = 'API_Key' );
        Double latOrigin = 123.45;
        Double longOrigin = 456.78;
        Double latDestination = 789.12;
        Double longDestination = 147.25;
        Double expected = 501.3975;

        System.Test.setMock( HttpCalloutMock.class, new BingMapDistanceMatrixCalloutMock( response, 'OK', 200 ) );

        Test.startTest();
        Decimal actual = bingMap.calculateDistanceInMiles( latOrigin, longOrigin, latDestination, longDestination );
        Test.stopTest();

        System.assertEquals( expected, actual.doubleValue() );
    }

    @IsTest
    public static void testBingMap_CalculateDistanceInMiles_Failed_Zero() {
        String response = 
        '{' + 
            '"authenticationResultCode": "ValidCredentials",' + 
            '"brandLogoUri": "http://dev.virtualearth.net/Branding/logo_powered_by.png",' + 
            '"copyright": "Copyright © 2021 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.",' + 
            '"resourceSets": [' + 
            '{' + 
                    '"estimatedTotal": 1,' + 
                    '"resources": [' + 
                        '{' + 
                            '"__type": "DistanceMatrix:http://schemas.microsoft.com/search/local/ws/rest/v1",' + 
                            '"destinations": [' + 
                                '{' + 
                                    '"latitude": 32.715685218572617,' + 
                                    '"longitude": -117.16172486543655' + 
                                '}' + 
                            '],' + 
                            '"origins": [' + 
                                '{' + 
                                    '"latitude": 37.779160067439079,' + 
                                    '"longitude": -122.42004945874214' + 
                                '}' + 
                            '],' + 
                            '"results": [' + 
                                '{' + 
                                    '"destinationIndex": 0,' + 
                                    '"originIndex": 0,' + 
                                    '"totalWalkDuration": 0,' + 
                                    '"travelDistance": 501.3975,' + 
                                    '"travelDuration": 422.5667' + 
                                '}' + 
                            ']' + 
                        '}' + 
                    ']' + 
                '}' + 
            '],' + 
            '"statusCode": 500,' + 
            '"statusDescription": "Internal Server Error",' + 
            '"traceId": "37bd8edea1e54860ab145bc27b24b302|CH000010A5|0.0.0.0|CH000014C3"' + 
        '}';
        
        FSL_Mapping.IMap bingMap = new FSL_Mapping.BingMap( new FSL_ApplicationLogTest.ApplicationLogServiceMock() );
        ((FSL_Mapping.AbstractMap)bingMap).config = new FSL_Mapping__mdt( API_Key__c = 'API_Key' );
        Double latOrigin = 123.45;
        Double longOrigin = 456.78;
        Double latDestination = 789.12;
        Double longDestination = 147.25;
        Double expected = 0.0;

        System.Test.setMock( HttpCalloutMock.class, new BingMapDistanceMatrixCalloutMock( response, 'Internal Server Error', 500 ) );

        Test.startTest();
        Decimal actual = bingMap.calculateDistanceInMiles( latOrigin, longOrigin, latDestination, longDestination );
        Test.stopTest();

        System.assertEquals( expected, actual.doubleValue() );
    }

    public class BingMapDistanceMatrixCalloutMock implements HttpCalloutMock {
        private String response;
        private String status;
        private Integer statusCode;
        
        public BingMapDistanceMatrixCalloutMock( String response, String status, Integer statusCode ) {
            this.response = response;
            this.status = status;
            this.statusCode = statusCode;
        }

        public HttpResponse respond( HttpRequest req ) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode( statusCode );
            resp.setStatus( status );
            resp.setBody( response );
            return resp;
        }
    }
    
    // *********************************************
    // * ApplicationLog
    // *********************************************
    @IsTest
    public static void testMappingApplicationLog_Constructor_DefaultFieldsSet() {
        String apiName = 'API Name';
        String operation = 'Operation';
        Id generalRecordTypeId = Schema.SObjectType.FSL_Application_Log__c.getRecordTypeInfosByName().get('General').getRecordTypeId();

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( apiName, operation );
        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( apiName, appLog.API_Name__c );
        System.assertEquals( operation, appLog.Operation__c );
        System.assertEquals( generalRecordTypeId, appLog.RecordTypeId );
        System.assertEquals( false, appLog.Error_Caught__c );
        System.assertNotEquals( null, appLog.DateTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogRequest_FieldsSet() {
        String request = 'Request';

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.logRequest( request );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( request, appLog.Request_Body__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogResponse_FieldsSet() {
        String response = 'Response';
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long serviceTime = endTime.getTime() - startTime.getTime();

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.logResponse( response, startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( response, appLog.Response_Body__c );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogFailedCalloutException_ServiceTimeNotSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long serviceTime = endTime.getTime() - startTime.getTime();

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.logFailedCalloutException( new FSL_Mapping.FailedCalloutException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Callout request failed' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( null, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogFailedCalloutException_ServiceTimeSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long outputProcessingTime = endTime.getTime() - startTime.getTime();
        Long serviceTime = outputProcessingTime - 12;

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.getApplicationLog().ServiceTime__c = serviceTime;
        log.logFailedCalloutException( new FSL_Mapping.FailedCalloutException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Callout request failed' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( outputProcessingTime - serviceTime, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogCalloutException_ServiceTimeNotSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long serviceTime = endTime.getTime() - startTime.getTime();

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.logCalloutException( new CalloutException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Callout exception' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( null, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogCalloutException_ServiceTimeSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long outputProcessingTime = endTime.getTime() - startTime.getTime();
        Long serviceTime = outputProcessingTime - 12;

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.getApplicationLog().ServiceTime__c = serviceTime;
        log.logCalloutException( new CalloutException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Callout exception' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( outputProcessingTime - serviceTime, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogGenericException_ServiceTimeNotSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long serviceTime = endTime.getTime() - startTime.getTime();

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.logGenericException( new DmlException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Generic exception' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( null, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogGenericException_ServiceTimeSet_FieldsSet() {
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long outputProcessingTime = endTime.getTime() - startTime.getTime();
        Long serviceTime = outputProcessingTime - 12;

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.getApplicationLog().ServiceTime__c = serviceTime;
        log.logGenericException( new DmlException(), startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( true, appLog.Error_Caught__c );
        System.assert( appLog.Error_Message__c.startsWith( 'Generic exception' ) );
        System.assertEquals( serviceTime, appLog.ServiceTime__c );
        System.assertEquals( outputProcessingTime - serviceTime, appLog.OutputProcessingTime__c );
    }

    @IsTest
    public static void testMappingApplicationLog_LogResult_FieldsSet() {
        String successMessage = 'Success';
        Datetime startTime = system.now().addMinutes( -2 );
        Datetime endTime = system.now().addMinutes( -1 );
        Long outputProcessingTime = endTime.getTime() - startTime.getTime();
        Long serviceTime = outputProcessingTime - 12;

        FSL_Mapping.MappingApplicationLog log = new FSL_Mapping.MappingApplicationLog( null, null );
        log.getApplicationLog().ServiceTime__c = serviceTime;
        log.logResult( successMessage, startTime, endTime );

        FSL_Application_Log__c appLog = log.getApplicationLog();

        System.assertEquals( successMessage, appLog.Success_Message__c );
        System.assertEquals( outputProcessingTime - serviceTime, appLog.OutputProcessingTime__c );
    }

    // *********************************************
    // * ServiceMock
    // *********************************************
    public class MappingServiceMock implements FSL_Mapping.IMap  {
        public Boolean throwsException = false;

        private void throwExceptionIfConfigured() {
            if( throwsException ) {
                throw new QueryException( 'Forced exception in MappingServiceMock' );
            }
        }

        public Integer getCalculateDistanceInMilesCallCount = 0;

        public Decimal calculateDistanceInMiles( Double latOrigin, Double longOrigin, Double latDestination, Double longDestination ) {
            getCalculateDistanceInMilesCallCount++;
            throwExceptionIfConfigured();
            return 1.0; 
        }        
    }
}