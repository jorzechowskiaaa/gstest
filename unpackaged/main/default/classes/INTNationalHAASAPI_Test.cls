@isTest 
global class INTNationalHAASAPI_Test {
@testSetup static void setup() {
        List<Integration_Settings__c> lstIntegrationSetting = new List<Integration_Settings__c>();
        lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Haas_CreateAlert_API',
            Method__c='POST',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
         
            Enpoint_URL__c='https://api-uat.national.aaa.com/automotive/services/ci/v1/sdmoalerts', 
            Request_Timeout__c=120000
            
        )); 
               
         lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'Haas_DeleteAlert_API',
            Method__c='DELETE',
            Header_Value__c='[{"key":"Content-Type","value":"application/json"}]',
         
            Enpoint_URL__c='https://api-uat.national.aaa.com/automotive/services/ci/v1/sdmoalerts', 
            Request_Timeout__c=120000
            
        )); 
     lstIntegrationSetting.add(new Integration_Settings__c(
            name = 'National_OAuth_API',
            Method__c='POST',
            Header_Value__c='[{"key":"Content-Type","value":"application/x-www-form-urlencoded"}]',
            Extra_Header_Value__c = 'grant_type=client_credentials&client_id=gtsnrjrm2s22m9n2jffq62m61&client_secret=12llukph30eses4qqa771a16edaqe2rk3k1novc6914piv64c9vc',
            Enpoint_URL__c='https://api-uat.national.aaa.com/common/oauth2/token', 
            Request_Timeout__c=120000
            
        )); 
        insert lstIntegrationSetting;  
  
  
    
}
 @isTest
    public  static /*testmethod*/ void validatecreateHassAlerts() {
        System.Test.startTest();
		//  FSL_DataFactoryUtility.userSetupwithStaticData();
		Test.setMock(HttpCalloutMock.class, new createAlertHttpResponseGenerator());  
          DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
      
        List<ServiceAppointment> saList = createDaoData(startTime, 1800, 'Breakdown');
        
        
        List<id> serviceAppIds = new List<id>(); 
        for (ServiceAppointment serviceApp : saList)
         {
             serviceAppIds.add(serviceApp.id);
         }
       // INTNationalHAASAPI obj = new INTNationalHAASAPI();
        INTNationalHAASAPI.createHAASalert(serviceAppIds);
        Test.stopTest();
    }
    
    @isTest
    public  static /*testmethod*/ void validateDeleteHassAlerts() {
        System.Test.startTest();
		//  FSL_DataFactoryUtility.userSetupwithStaticData();
		Test.setMock(HttpCalloutMock.class, new createAlertHttpResponseGenerator());  
          DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
      
        List<ServiceAppointment> saList = createDaoData(startTime, 1800, 'Breakdown');
        
        
        List<id> serviceAppIds = new List<id>(); 
        for (ServiceAppointment serviceApp : saList)
         {
             serviceAppIds.add(serviceApp.id);
         }
       // INTNationalHAASAPI obj = new INTNationalHAASAPI();
        INTNationalHAASAPI.deleteHAASalert(serviceAppIds);
        Test.stopTest();
    }
    
    @isTest
    public  static /*testmethod*/ void prepareHassAlerts() {
        System.Test.startTest();
		//  FSL_DataFactoryUtility.userSetupwithStaticData();
		Test.setMock(HttpCalloutMock.class, new createAlertHttpResponseGenerator());  
          DateTime nowTime = System.now();
        DateTime startTime = DateTime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0);
      
        List<ServiceAppointment> saList = createDaoData(startTime, 1800, 'Breakdown');
        INTNationalHAASAPI  obj = new INTNationalHAASAPI();
        obj.prepareHAASalert(saList);
        obj.preapareToDeleteHAASalert(saList);
        Test.stopTest();
    }
global class createAlertHttpResponseGenerator implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            try{           
                    HttpResponse res= new HttpResponse();
                res.setBody('{"status" : "Ok"}'); 
                    res.setStatusCode(201);
                    String responseBody = res.getBody(); 
                    return res;
               }catch(Exception ex){
                    System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
               }
                return null;
             }
      }
    
    
    
     private static List<ServiceAppointment> createDaoData(DateTime startTime, Integer duration, String serviceType) {
        Integer recordCount = 5;
        Account accountTest = FSL_DataFactory.createAccount( 'Name Account' );
        insert accountTest;

        Contact contactTest = FSL_DataFactory.createContact( 'Last Name Contact' );
        contactTest.AccountId = accountTest.id;
        contactTest.Membership_Type__c = 'MEMBER' ; 
        insert contactTest;

        WorkOrder wo = FSL_DataFactory.createWorkOrderShell( 'Light Service', contactTest );
        insert wo;

        List<OperatingHours> hours = FSL_DataFactory.createOperatingHours();

        ServiceTerritory st = new ServiceTerritory( Name = 'Service Territory', OperatingHoursId = hours[0].Id, IsActive = true );
        insert st;


            
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        List<AssignedResource> arList = new List<AssignedResource>();
        ServiceAppointment breakdownSa = FSL_DataFactory.createAppointmentShell( 'Breakdown', st.Id, wo.Id, contactTest.Id, startTime, duration, 'Breakdown Appointment' );
//        breakdownSa.actualstarttime = startTime;
//        breakdownSa.actualendtime = startTime.addMinutes(duration);
//        breakdownSa.PTA__c = startTime;
        if('Breakdown'.equals(serviceType)) {
            breakdownSa.FSL_IsLight_Service__c = true;
        }
        breakdownSa.SchedStartTime = startTime;
        breakdownSa.SchedEndTime = startTime.addMinutes( duration );
        breakdownSa.Street = '10 Tower Rd';
         breakdownSa.StateCode = 'MA';
         breakdownSa.State = 'MA';
         breakdownSa.PostalCode = '02713';
         breakdownSa.Longitude  = -70.929843 ;
         breakdownSa.Latitude = 41.421088 ;
         breakdownSa.CountryCode = 'US';
         breakdownSa.Country  = 'United States';
         breakdownSa.City  = 'Gosnold';
        breakdownSa.PTA__c = System.now();
        breakdownSa.Status = 'Dispatched';
        serviceAppointments.add( breakdownSa );
        insert breakdownSa;

        if('Tow'.equals(serviceType)) {

            ServiceAppointment towSa = FSL_DataFactory.createAppointmentShell( breakdownSa, duration );
            towSa.SchedStartTime = startTime;
            towSa.SchedEndTime = startTime.addMinutes( duration );
            towSa.PTA__c = System.now();
            serviceAppointments.add( towSa );
            insert towSa;
            
            breakdownSa.FSL__Related_Service__c = towSa.Id;
            breakdownSA.FSL__Same_Resource__c = true;
            towSa.FSL__Related_Service__c = breakdownSa.Id;
            towSa.FSL__Same_Resource__c = true;
            towSa.Status = 'Dispatched';
            update serviceAppointments;
        }
        // insert serviceAppointments;

     

        //update serviceAppointments;
        return serviceAppointments;
    }
}