global class AAAOmniUtilityRemoteActionClass implements omnistudio.VlocityOpenInterface2 {
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        Boolean result = true;

        try {
            if (methodName.equals('getFilteredProductsByFacSLIs')) {
                getFilteredProductsByFacSLIs(input, output);
            }
        } catch(Exception e) {
            result = false;
            System.debug(e);
        }
        
        return result;
    }

    public void getFilteredProductsByFacSLIs(Map<String,Object> input, Map<String,Object> output) {
        String facId = (String) input.get('ServiceTerritoryId');
        String queryStr = '%' + (String) input.get('ProductName') + '%';
        List<Product2> prod2List = [
            SELECT Id, Name, ProductCode
            FROM Product2 
            WHERE Id NOT IN (
                SELECT Product__c 
                FROM Facility_Service_Item__c 
                WHERE Facility__c = :facId
            )
            AND IsActive = true
            AND Family != 'Trouble Code'
            AND Name LIKE :queryStr
            ORDER BY Name ASC
            LIMIT 20
        ];
        List<Map<String, Object>> respList = new List<Map<String, Object>>();

        for (Product2 prod2 : prod2List) {
            Map<String, Object> obj = new Map<String, Object>();

            obj.put('ProductId', prod2.Id);
            obj.put('ProductCode', prod2.ProductCode);
            obj.put('ProductName', prod2.Name);

            respList.add(obj);
        }

        output.put('Products', respList);
    }
}