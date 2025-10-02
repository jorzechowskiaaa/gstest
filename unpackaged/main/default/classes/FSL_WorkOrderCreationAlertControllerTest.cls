@isTest
public class FSL_WorkOrderCreationAlertControllerTest {
    
    public static testmethod void checkForAudioEnablementTest(){
        Map<String,Integer> responseMap = FSL_WorkOrderCreationAlertController.checkForAudioEnablement(2,3,4);
        system.debug('responseMap1:'+responseMap);
        system.assertEquals(1, responseMap.get('isCancelCountChanged'));
        system.assertEquals(0, responseMap.get('totalCallCount'));
        responseMap = FSL_WorkOrderCreationAlertController.checkForAudioEnablement(2,1,4);
        system.debug('responseMap2:'+responseMap);
        system.assertEquals(0, responseMap.get('isTotalCountChanged'));
    }
    
    public static testmethod void checkUserPreferencesTestNew(){
        Map<String,String> userPreferenceMap = FSL_WorkOrderCreationAlertController.checkUserPreferences(); 
        system.debug('userPreferenceMap1:'+userPreferenceMap);
        system.assertEquals('false', userPreferenceMap.get('enableAudioAlerts'));
        User u = [select id from USer where alias = 'T_Fleet'];
        system.runas(u){
            userPreferenceMap = FSL_WorkOrderCreationAlertController.checkUserPreferences(); 
            system.debug('userPreferenceMap1:'+userPreferenceMap);
            system.assertEquals('true', userPreferenceMap.get('enableAudioAlerts'));
        }
    }
    private static testmethod void WorkOrdersNotCanceledOrClearedTest() {

        Integer recordCount = 10;
        List<Account> accounts = FSL_DataFactory.createAccounts( recordCount );
        insert accounts;

        List<Contact> contacts = FSL_DataFactory.createContacts( recordCount );
        for( Integer i = 0; i < recordCount; ++i ) {
            contacts[i].AccountId = accounts[i].Id;
        }
        insert contacts;

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for( Integer i = 0; i < recordCount; ++i ) {
            workOrders.add( FSL_DataFactory.createWorkOrderShell( 'Light Service', contacts[i] ) );
            workOrders[i].External_Id__c = 'ERS-' + i;
            workOrders[i].Call_Id__c = '3333' + i;
            workOrders[i].Call_Date__c = '4444' + i;
            workOrders[i].Status = 'Spotted';  
            workOrders[i].Servicing_Technology_Type__c = 'Landline';
            workOrders[i].Vehicle_Profile__c = 'My Vehicle # ' + i;

        }
                                
        // Change about 2 of the status to other than Spotted        
        workOrders[2].status = 'Canceled';
        workOrders[3].status = 'Cleared';
        workOrders[4].status = 'Spotted';
             
                                

    insert workOrders;

    List<WorkOrder> actualwoList = [Select Id from WorkOrder ];
    
    system.assertEquals(10, actualwoList.size(), 'Expected number of workorders should equal to 10 ');

    actualwoList = [Select Id from WorkOrder where ((NOT status IN ('Canceled','Cleared')) )];   
    system.assertEquals(8, actualwoList.size(), 'Expected number of workorders should equal to 8 ');
                                
                         
    Date createdDate = System.now().dateGmt();
    Datetime createdDatetime = Datetime.newInstance( createdDate.year(), createdDate.month(), createdDate.day(), 0, 1, 15 );   
    
    
        Test.setCreatedDate( WorkOrders[4].Id, createdDatetime.addDays( -5 ) );
        Test.setCreatedDate( WorkOrders[5].Id, createdDatetime.addDays( -5 ) );
        Test.setCreatedDate( WorkOrders[6].Id, createdDatetime.addDays( -10 ) );
        Test.setCreatedDate( WorkOrders[7].Id, createdDatetime.addDays( -10 ) );
        Test.setCreatedDate( WorkOrders[8].Id, createdDatetime.addDays( -10) );
        Test.setCreatedDate( WorkOrders[9].Id, createdDatetime.addDays( -10) );


                                    
       // SQL test using these work orders        
        
       actualwoList = FSL_WorkOrderCreationAlertController.fetchAllReadOnlyWorkOrdersNotCanceledOrCleared(2);
       system.assertEquals(2, actualwoList.size(), 'Expected number of workorders should equal to 2 for offset equal to -2 ');

       actualwoList = FSL_WorkOrderCreationAlertController.fetchAllReadOnlyWorkOrdersNotCanceledOrCleared(7);
       system.assertEquals(4, actualwoList.size(), 'Expected number of workorders should equal to 4 for offset equal to -7 ');

       actualwoList = FSL_WorkOrderCreationAlertController.fetchAllReadOnlyWorkOrdersNotCanceledOrCleared(12);
       system.assertEquals(8, actualwoList.size(), 'Expected number of workorders should equal to 8 for offset equal to -12 ');
                 
             
       }   
 
    @testSetup
    public static void dataSetup() {
        FSL_DataFactoryUtility.userdataSetup();
    }   
    
}