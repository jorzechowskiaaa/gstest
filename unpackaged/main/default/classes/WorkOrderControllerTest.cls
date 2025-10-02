@isTest
public class WorkOrderControllerTest {
@testSetup
    public static void testSetup(){
       
       
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
         //WorkOrder woRecord = new WorkOrder();
        //insert woRecord;
        // Case caseRecord = new Case(FSL_Work_Order__c = woRecord.id);
        //insert caseRecord;

        Integer recordCount = 1;
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
        }
        insert workOrders;
                
        Case caseRec = FSL_DataFactory.createCase( 'Clear Queue Failure' );
        caseRec.FSL_Work_Order__c = workOrders[0].Id;
        insert caseRec;        
        
    }
    @isTest
    public static void getWorkOrderDetailsTest()
    {
        WorkOrder woRecord = [SELECT id from WorkOrder];
        Case caseRec = [SELECT id,FSL_Work_Order__c from Case limit 1];
        LIST<WorkOrder> woRecs =  WorkOrderFeedController.getWorkOrderDetails(caseRec.id);
        System.assertEquals(1, woRecs.size(), 'work order list size is not correct');
    }
}