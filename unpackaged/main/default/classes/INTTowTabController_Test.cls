@isTest
global class INTTowTabController_Test{
    
    global class AddressHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{
                if(req.getEndpoint()=='https://maps.googleapis.com/maps/api/distancematrix/json?'){
                    system.debug('if');
                    HttpResponse res= new HttpResponse();
                    //res.getMethod('GET');
                    res.setBody('[{"title":"1313 Disneyland Dr, Anaheim, CA 92802, USA","description":"1313 Disneyland Dr, Anaheim, CA 92802, USA","location":{"Latitude":"33.81539590000001","Longitude":-117.9263991}}]');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
                    
                }else{
                    HttpResponse res= new HttpResponse();
                    res.setBody('INTDistanceMatrixAPIResponseWrapper:[destination_addresses=(28 HI-11, Hilo, HI 96720, USA), origin_addresses=(28 HI-11, Hilo, HI 96720, USA), rows=(Rows:[elements=(Elements:[distance=Distance:[text=1 ft, value=0], duration=Distance:[text=1 min, value=0], status=OK])]), status=OK]');
                    res.setStatusCode(200);
                    String responseBody = res.getBody(); 
                    return res;
                    
                
                }
            }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
            }
                return null;
             }
        }
    
    @isTest
    public static void testGetAarMprDetails(){
        Integer recordCount = 2;
        /*List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;*/
        List<Account> accList = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Approved Garage').getRecordTypeId();
        Account acc1 = new Account();
        acc1.recordTypeId = recordTypeId;
        acc1.Name = 'test1';
        acc1.Approved_Garage_Type__c = 'AAR';
        acc1.Information__c = 'Mon: 9AM-5PM;Tue: 8AM-6PM';
        accList.add(acc1);
        
        Account acc2 = new Account();
        acc2.recordTypeId = recordTypeId;
        acc2.Name = 'test2';
        acc2.Approved_Garage_Type__c = 'MPR';
        acc2.Service_Vehicle_Make__c = 'BMW';
        acc2.Information__c = 'Mon: 9AM-5PM;Tue: 8AM-6PM';
        accList.add(acc2);
        
        insert accList;
        
         List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accList[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
        }
        insert workOrders;
        
         List<Case> cases = new List<Case>();
        for( WorkOrder workOrder : workOrders ) {
            Case c1 = FSL_DataFactory.createCase( 'ERS Case' );
            c1.ACG_Service_Type__c = 'Tow';
            c1.ACG_Vehicle_Location_Address__c = '3333 Fairview Rd, Costa Mesa, CA 92626, USA';
            c1.Member_Vehicle_Type__c = 'PS (Passenger Car/Truck)';
            c1.Status = 'In Progress';
            cases.add( c1 );
            
            Case c2 = FSL_DataFactory.createCase( 'ERS Case' );
            c2.ACG_Vehicle_Location_Address__c = '3333 Fairview Rd, Costa Mesa, CA 92626, USA';
            c2.ACG_Service_Type__c = 'Tow';
            c2.Member_Vehicle_Type__c = 'R1 (RV < 23 feet)';
            c1.Status = 'In Progress';
            cases.add( c2 );

        }
        insert cases;
        
        List<Approved_Garage_Type_Mapping__c> lstApprovedGarageSetting = new List<Approved_Garage_Type_Mapping__c>();
        
        lstApprovedGarageSetting.add(new Approved_Garage_Type_Mapping__c(
            Name = 'Scenario1',
            Approved_Garage_Type__c = 'AAR;ADR;AAG;COR',
            Ignore_Make__c =true,
            Service_Type__c ='Flat Tire or Tow',
            Ignore_Type__c = true,
            Tow_Service_Reason__c = 'Accident; Alternator; Belt; Brakes Broken Windshield; Fuel Pump; Fuel Type of Diesel; Fuel Type of Electric; Hose; No Spare Tires; Overheat; Stalled While Driving; Starter; Transmission',
            Vehicle_Type__c = 'R1 (RV < 23 feet);R2 (RV 24-32 feet);R3 (RV > 33 feet)',
             Limit_search_result__c = '15'
        ));
        lstApprovedGarageSetting.add(new Approved_Garage_Type_Mapping__c(
            Name = 'Scenario2',
            Approved_Garage_Type__c = 'MPR;AAB',
            Ignore_Make__c =true,
            Ignore_Type__c = true,
            Service_Type__c ='Flat Tire or Tow',
            Tow_Service_Reason__c = 'Collison',
            Vehicle_Type__c = 'ALL',
             Limit_search_result__c = '15'
        ));
        insert lstApprovedGarageSetting;
        
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'GETDistance_Matrix_API',
            Method__c='GET',
            Enpoint_URL__c='htt',
            API_Key__c = 'AIzaSyDrqDOs4dvUGh74BkgI2DLz1_QWzrnXEcc'
        ));
        insert lstIntegrationSetting;
        
        System.assertEquals('MPR', accList[1].Approved_Garage_Type__c);
        INTTowTabController.getAarMprDetails(cases[1].Id,'36.7642024','-108.2395278','No Spare Tires');
        //INTTowTabController.getAarMprDetails(cases[2].Id,'36.7642024','-108.2395278','No Spare Tires');
        
        INTTowTabController.getAARBasedOnSelectedAddress(accList[0].Id);
        System.assertEquals('test1', accList[0].Name);
        
        INTTowTabController.updateCaseTowData(cases[1].Id, accList[0].Id);
        
        INTTowTabController.getCaseDetails(cases[1].Id);
        
        //INTTowTabController.getDistanceInMilesUsingAPI('19.72235304','-155.0643886','19.72235304','-155.0643886');
        INTTowTabController.updateCaseBasedonTowAddressValue(cases[0].Id,'13933 Poway Rd, Poway, CA 92064, USA','13933 Poway Rd','Poway','CA','92064','USA','19.72235304','-155.0643886','Poway');
        
    }
}