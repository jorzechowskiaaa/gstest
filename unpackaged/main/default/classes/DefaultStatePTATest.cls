@isTest
private class DefaultStatePTATest {
    
    @isTest
    static void getDSPTA_Test() {
        // get one record for testing purposes
        Default_State_PTA__mdt validRec = [SELECT PTA__c, State__c, Service_Type__c FROM Default_State_PTA__mdt LIMIT 1];
        String state = validRec.State__c;
        String serviceType = validRec.Service_Type__c;
        
        Test.startTest();
        
        // test 1 : valid entries
        Assert.AreEqual(DefaultStatePTA.getDefaultStatePTA(state, serviceType),validRec.PTA__c,'DefaultStatePTA valid');
        // test 2 : invalid service type
        Assert.AreEqual(DefaultStatePTA.getDefaultStatePTA(state,'Gibberish'),0,'DefaultStatePTA invalid ServiceType');
        // test 3 : invalid state
        Assert.AreEqual(DefaultStatePTA.getDefaultStatePTA('ZX',serviceType),0,'DefaultStatePTA invalid State');
        
        // For the system time tests
        Integer transitMinutes = DefaultStatePTA.getDefaultStatePTA ( state, serviceType);
        DateTime testTime = DateTime.newInstance ( DateTime.now().getTime() + (transitMinutes * 60 * 1000) );
        
        // Test return of normal DT
        Assert.AreEqual( DefaultStatePTA.getPTADateTime(state, serviceType), testTime, 'DefaultStatePTA invalid datetime');
        testTime = DateTime.newInstance ( DateTime.now().getTime() + (transitMinutes * 60 * 1000) );
        
        // Test UTC representation
        //Standard format is yyyy-MM-ddTHH:mm:ss.sssZ (e.g. '2022-03-30T21:37:58.012Z')
        String ptaAsUTC1 = JSON.serialize (testTime);
        String ptaAsUTC2 = DefaultStatePTA.getPtaAsStandardUTC ( state, serviceType );
        Assert.AreEqual( ptaAsUTC1.substring(0,19), ptaAsUTC2.substring(0,19) );
        
        String fmt = 'HH:mm';
        String hhmm = DateTime.newInstance ( DateTime.now().getTime() + (transitMinutes * 60 * 1000) ).format (fmt);
        Assert.AreEqual( hhmm, DefaultStatePTA.getPtaAsHourMin ( state, serviceType ) );
        
        Test.stopTest();
    }
}