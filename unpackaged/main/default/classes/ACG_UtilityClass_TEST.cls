@IsTest
private class ACG_UtilityClass_TEST {

    @IsTest
    static void testGetClubMappingByCommcenter() {
        Map<String, ERS_Club_Mapping__mdt> clubMappings = ACG_UtilityClass.getClubMappingByCommcenter();
        ERS_Club_Mapping__mdt m = clubMappings.get('MN');
        Assert.areEqual('MN', m.Comm_Center__c, 'Expected MN in the club mapping metadata');
    }
    
    @IsTest
    static void testGetClubMappingByCode() {
        Map<String,String> clubMappings = ACG_UtilityClass.getClubMappingByCode();
        Assert.areEqual('Colorado', clubMappings.get('006'));
    }
    
    @IsTest
    static void testGetFieldNameByProductID() {
        Map<String, String> fieldNameMap = ACG_UtilityClass.getFieldNameByProductID();
        Assert.areEqual('Special_Equipment__c', fieldNameMap.get('SE'), 'Expected mapping SE to Special_Equipment__c');
    }
    
    @IsTest
    static void testGetCodeByState() {
        Map<String, String> codeStateMap = ACG_UtilityClass.getCodeByState();
        Assert.areEqual('CA', codeStateMap.get('california'), 'Expected to get a mapping of CA to california');
    }
    
    @IsTest
    static void testGetTimeBand() {
        DateTime dispatchedDateTime = DateTime.parse('10/14/2020, 11:46 AM');
        String band = ACG_UtilityClass.getTimeBand(dispatchedDateTime);
        Assert.areEqual('D3', band, 'Expected D3 as the band');
    }
    
}